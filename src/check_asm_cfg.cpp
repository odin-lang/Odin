// check_asm_cfg.cpp

enum {
	ASM_WIDTH_REG_COUNT = 16
};

// Sub-register width tracking
// 0 means "this instruction does not read/write that named register"
struct AsmRegW {
	u8 e[ASM_WIDTH_REG_COUNT];
};

gb_internal u8 asm_reg_def_width_after(u8 prev, u8 w) {
	bool x86 = build_context.metrics.arch == TargetArch_amd64 ||
	           build_context.metrics.arch == TargetArch_i386; // TODO(bill): actually support x86 32-bit :P
	if (x86 && w == 32) {
		return 64;
	}
	return gb_max(prev, w);
}

gb_internal i32 asm_reg_index_from_bit(u16 bit) {
	for (i32 i = 0; i < ASM_WIDTH_REG_COUNT; i++) {
		if (bit == cast(u16)(1u << i)) {
			return i;
		}
	}
	return -1;
}

template <typename AsmCtx>
gb_internal u16 asm_stack_pointer_bit(AsmCtx *asm_ctx) {
	switch (build_context.metrics.arch) {
	case TargetArch_amd64:
		return asm_ctx->clobber_bit_for_reg_name(str_lit("rsp"));
	case TargetArch_arm64:
	case TargetArch_riscv64:
		return asm_ctx->clobber_bit_for_reg_name(str_lit("sp"));
	default:
		return 0;
	}
}

struct AsmBlock {
	i32        first; // instruction index
	i32        last;
	Array<i32> succs;
	bool       reachable;
};

struct AsmInstructionFacts {
	AstAsmInstruction *node;
	String             name;

	u16 gen_flags; // flag bits this instruction defines
	u16 read_flags;
	u16 gen_regs;
	u16 read_regs;

	// Sub-register widths, indexed by reg bit-index.
	AsmRegW read_reg_w;
	AsmRegW gen_reg_w;

	Array<Entity *> gen_params;
	Array<Entity *> read_params;

	bool is_control;
	bool is_terminal;
	bool is_call;
	bool calls_out; // a call to code outside of the template, rather than to one of its labels

	// NOTE(bill): a call, return, or jump out of the template hands every register to code which may read it
	bool reads_every_register;

	Entity *branch_target;
};

gb_internal u16 asm_full_kill_mask(AsmInstructionFacts *f) {
	u16 full = cast(u16)(build_context.metrics.ptr_size*8);
	u16 kill = 0;
	for (u16 bit = 1; bit != 0; bit <<= 1) {
		if ((f->gen_regs & bit) == 0) {
			continue;
		}
		i32 idx = asm_reg_index_from_bit(bit);
		u8  w = 0;
		if (idx >= 0) {
			w = f->gen_reg_w.e[idx];
		}
		if (w == 0 || asm_reg_def_width_after(0, w) >= full) {
			kill |= bit;
		}
	}
	return kill;
}

struct AsmCfg {
	bool saw_any_instructions; // NOTE(bill): An empty diverging body cannot diverge.

	// NOTE(bill): Related to #align_stack, the first instruction which pushes, calls, or writes the stack pointer.
	// If there is none, #align_stack is redundant.
	Ast *       stack_use_node;
	char const *stack_use;

	bool calls_out; // a call to code outside of the template, which may write any register

	// Purity test
	bool        can_be_pure;
	char const *impure_reason;
	Ast *       impure_reason_node;

	Array<AstAsmInstruction *> insts; // program-order (only for fact-carrying instrs)
	Array<AsmBlock>            blocks;

	PtrMap<Entity *, i32> entity_to_index;
	Array<u16>            decl_pin_bit;
	u64                   universe_pm;
};

gb_internal void asm_cfg_init(AsmCfg *cfg) {
	map_init(&cfg->entity_to_index);
	cfg->decl_pin_bit.allocator = heap_allocator();
	cfg->can_be_pure = true;
}

gb_internal void asm_cfg_destroy(AsmCfg *cfg) {
	for (auto &block : cfg->blocks) {
		array_free(&block.succs);
	}
	array_free(&cfg->blocks);
	array_free(&cfg->insts);
	map_destroy(&cfg->entity_to_index);
	array_free(&cfg->decl_pin_bit);
}

gb_internal i32 asm_cfg_label_block_index(Entity *entity) {
	if (entity != nullptr && entity->kind == Entity_Label) {
		return entity->Label.asm_block_index;
	}
	return -1;
}
gb_internal void asm_cfg_label_block_index_set(Entity *entity, i32 index) {
	if (entity != nullptr && entity->kind == Entity_Label) {
		GB_ASSERT(entity->Label.asm_block_index < 0);
		entity->Label.asm_block_index = index;
	}
}

// The physical-register bit a decl is pinned to. A width-view carries no pin of
// its own; it inherits its source decl's pin. Returns 0 for unpinned decls.
template <typename AsmCtx>
gb_internal u16 asm_decl_resolve_pin_bit(AsmCtx *asm_ctx, Array<AsmTemplateEntityDecl> const &decls, i32 di) {
	if (di < 0) {
		return 0;
	}
	auto const &ed = decls[di];
	String pin = ed.pin;
	if (pin.len == 0 && ed.view_of >= 0) {
		pin = decls[ed.view_of].pin;
	}
	return asm_ctx->clobber_bit_for_reg_name(pin);
}

template <typename AsmCtx>
gb_internal u16 asm_decl_resolve_flag_bit(AsmCtx *asm_ctx, AsmTemplateEntityDecl const &ed) {
	if (ed.pin_flag.len == 0) {
		return 0;
	}
	auto flags = asm_ctx->flag_from_name(ed.pin_flag);
	return cast(u16)flags;
}

template <typename AsmCtx>
gb_internal void asm_cfg_populate_decls(AsmCtx *asm_ctx, AsmCfg *cfg, Entity *entity) {
	auto const &decls = entity->AsmTemplate.decls;
	cfg->universe_pm = 0;
	if (decls.count > 64) {
		// NOTE(bill): check_asm_cfg_analyse will err on this since this is exceed the maximum number of declarations
		return;
	}
	array_resize(&cfg->decl_pin_bit, decls.count);
	for_array(i, decls) {
		auto const &ed = decls[i];
		cfg->decl_pin_bit[i] = asm_decl_resolve_pin_bit(asm_ctx, decls, cast(i32)i);
		if (ed.view_of >= 0) {
			// NOTE(bill): A view shares its source's lattice bit, as it is not an independent value.
			map_set(&cfg->entity_to_index, ed.entity, ed.view_of);
		} else {
			map_set(&cfg->entity_to_index, ed.entity, cast(i32)i);
			cfg->universe_pm |= cast(u64)1 << i;
		}
	}
}

template <typename AsmCtx>
gb_internal void check_asm_cfg_build(AsmCtx *asm_ctx, AsmCfg *cfg, Ast *at_node, Entity *entity) {
	ast_node(at, AsmTemplate, at_node);

	asm_cfg_populate_decls(asm_ctx, cfg, entity);

	cfg->insts.allocator  = heap_allocator();
	cfg->blocks.allocator = heap_allocator();

	bool need_leader = true;

	// Build basic blocks over the template body. A leader is: the first instruction, any
	// instruction preceded by a label, and any instruction following a control transfer.
	for (Ast *node : at->instructions) {
		if (node->kind == Ast_AsmLabelDecl) {
			// Every label between two instructions names the block the *next* instruction
			// opens; consecutive labels share it. A trailing label maps to blocks.count.
			Entity *le = node->AsmLabelDecl.name->Ident.entity;
			if (le != nullptr) {
				asm_cfg_label_block_index_set(le, cast(i32)cfg->blocks.count);
			}
			need_leader = true;
			continue;
		}
		if (node->kind != Ast_AsmInstruction) {
			continue; // directives are straight-line filler; no CFG effect
		}

		AstAsmInstruction   *instr = &node->AsmInstruction;
		AsmInstructionFacts *facts = instr->facts;
		// Prefixes and pseudo-macro ops (li/la) carry no facts and never branch.

		if (need_leader || cfg->blocks.count == 0) {
			AsmBlock b = {};
			b.first = cast(i32)cfg->insts.count;
			b.last  = cast(i32)cfg->insts.count;
			b.succs.allocator = heap_allocator();
			array_add(&cfg->blocks, b);
			need_leader = false;
		}

		cfg->blocks[cfg->blocks.count-1].last = cast(i32)cfg->insts.count;
		array_add(&cfg->insts, instr);

		if (facts != nullptr && facts->is_control) {
			need_leader = true;
		}
	}

	for_array(bi, cfg->blocks) { // Calculate the edges for the blocks
		AsmBlock *b = &cfg->blocks[bi];

		AstAsmInstruction   *last = cfg->insts[b->last];
		AsmInstructionFacts *lf   = last->facts;

		i32  branch_succ = -1;
		bool fallthrough = true;

		if (lf != nullptr && lf->is_control) {
			if (lf->branch_target != nullptr) {
				i32 t = asm_cfg_label_block_index(lf->branch_target);
				if (t < cast(i32)cfg->blocks.count) {
					branch_succ = t;
				}
				// For `t == blocks.count`, this implies a jump to the implicit end, and is handled as "leaves" below
			}
			// e.g. jmp/ret/hlt, and a call to a diverging procedure, do not fall through
			if (lf->is_terminal) {
				fallthrough = false;
			}
		}

		if (branch_succ >= 0) {
			array_add(&b->succs, branch_succ);
		}
		if (fallthrough) {
			i32 next = cast(i32)bi + 1;
			if (next < cast(i32)cfg->blocks.count) {
				array_add(&b->succs, next);
			}
		}
	}

	if (cfg->blocks.count != 0) { // Reachability determination
		Array<i32> stack = {};
		stack.allocator = heap_allocator();
		defer (array_free(&stack));

		cfg->blocks[0].reachable = true;
		array_add(&stack, cast(i32)0);
		while (stack.count > 0) {
			i32 bi = array_pop(&stack);
			for (i32 s : cfg->blocks[bi].succs) {
				if (!cfg->blocks[s].reachable) {
					cfg->blocks[s].reachable = true;
					array_add(&stack, s);
				}
			}
		}
	}
}

gb_internal bool check_asm_cfg_block_leaves(AsmCfg *cfg, i32 bi) {
	AsmInstructionFacts *lf = cfg->insts[cfg->blocks[bi].last]->facts;

	if (lf != nullptr && lf->branch_target != nullptr &&
	    asm_cfg_label_block_index(lf->branch_target) >= cast(i32)cfg->blocks.count) {
		return true; // 'jmp .end' — falls into the implicit return
	}
	bool terminal = (lf != nullptr) && lf->is_terminal;
	return !terminal && bi+1 >= cast(i32)cfg->blocks.count; // straight-line/conditional-tail with nothing after it
}

template <typename AsmCtx>
gb_internal void check_asm_cfg_report_undef_reg(AsmCtx *asm_ctx, AsmCfg *cfg, Entity *tmpl_entity,
                                                AstAsmInstruction *instr, String name, u16 bit) {
	char const *rname = asm_ctx->clobber_reg_bit_name(bit);
	char const *reads = "implicitly reads";
	String      owner = {};
	char const *role  = nullptr;

	for (Ast *op : instr->operands) {
		if (op->kind != Ast_AsmRegister) {
			continue;
		}
		if (asm_ctx->clobber_bit_for_reg_name(op->AsmRegister.name.string) == bit) {
			reads = "reads";
			break;
		}
	}

	auto const &decls = tmpl_entity->AsmTemplate.decls;
	for_array(i, decls) {
		auto const &ed = decls[i];
		if (cfg->decl_pin_bit[i] != bit) {
			continue;
		}
		if (ed.param_group == AsmTemplateEntityDeclParamGroup_Output && ed.tie < 0) {
			owner = ed.entity->token.string;
			role  = "output";
			break;
		}
		if (ed.param_group == AsmTemplateEntityDeclParamGroup_Scratch && ed.view_of < 0) {
			owner = ed.entity->token.string;
			role  = "scratch";
			break;
		}
	}
	if (role != nullptr) {
		error(instr->name,
		      "'%.*s' %s %%%s, which is bound to the %s parameter '%.*s', "
		      "but nothing writes %%%s on all paths reaching here; write to it (e.g. into '%.*s') first",
		      LIT(name), reads, rname, role, LIT(owner), rname, LIT(owner));
	} else {
		error(instr->name,
		      "'%.*s' %s %%%s, but nothing in this template produces a value for it "
		      "on all paths reaching here; pin an input to %%%s, write %%%s first, "
		      "or add '#preserve %%%s' if this template saves and restores it",
		      LIT(name), reads, rname, rname, rname, rname);
	}
}

// NOTE(bill): what is defined on every path to a point: the named registers and how many of their low bits,
// the status flags, and the parameters (a bit per declaration, see `entity_to_index`)
struct AsmDefs {
	u16     regs;
	u16     flags;
	u64     params;
	AsmRegW widths;
};

gb_internal bool asm_defs_equal(AsmDefs const &a, AsmDefs const &b) {
	return a.regs   == b.regs   &&
	       a.flags  == b.flags  &&
	       a.params == b.params &&
	       gb_memcompare(&a.widths, &b.widths, gb_size_of(AsmRegW)) == 0;
}

gb_internal void asm_defs_meet(AsmDefs *a, AsmDefs const &b) {
	a->regs   &= b.regs;
	a->flags  &= b.flags;
	a->params &= b.params;
	for (i32 idx = 0; idx < ASM_WIDTH_REG_COUNT; idx++) {
		a->widths.e[idx] = gb_min(a->widths.e[idx], b.widths.e[idx]);
	}
}

gb_internal u64 asm_cfg_param_bit(AsmCfg *cfg, Entity *e) {
	i32 *ix = map_get(&cfg->entity_to_index, e);
	return ix ? (cast(u64)1 << *ix) : 0;
}

gb_internal void asm_defs_apply(AsmCfg *cfg, AsmDefs *d, AsmInstructionFacts *f) {
	d->regs  |= f->gen_regs;
	d->flags |= f->gen_flags;
	for (Entity *pe : f->gen_params) {
		d->params |= asm_cfg_param_bit(cfg, pe);
	}
	for (i32 idx = 0; idx < ASM_WIDTH_REG_COUNT; idx++) {
		u8 w = f->gen_reg_w.e[idx];
		if (w != 0) {
			d->widths.e[idx] = asm_reg_def_width_after(d->widths.e[idx], w);
		}
	}
}

gb_internal AsmDefs asm_cfg_block_out(AsmCfg *cfg, AsmBlock const &b, AsmDefs defs) {
	for (i32 ii = b.first; ii <= b.last; ii++) {
		if (AsmInstructionFacts *f = cfg->insts[ii]->facts) {
			asm_defs_apply(cfg, &defs, f);
		}
	}
	return defs;
}

template <typename AsmCtx>
gb_internal void check_asm_cfg_analyse(AsmCtx *asm_ctx, AsmCfg *cfg, Entity *entity) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;
	auto const &decls     = ate->decls;
	bool        diverging = ate->proc_type->Proc.diverging;

	if (cfg->blocks.count == 0) {
		// With an empty body, the CFG cannot really do nothing
		if (diverging && !cfg->saw_any_instructions) {
			error(entity->token, "This 'asm' template is declared as diverging (-> !) but its body is empty and cannot diverge");
		}
		return;
	}

	if (decls.count > 64) {
		error(entity->token, "'asm' templates cannot have more than 64 total parameter declarations, got %td", decls.count);
		return;
	}
	u16 const REG_TOP = asm_ctx->CLOBBER_REGS_NAMED;
	u8  const full    = cast(u8)(build_context.metrics.ptr_size * 8);

	// NOTE(bill): the identity of the meet, which every block but the entry starts from
	AsmDefs top = {};
	top.regs   = REG_TOP;
	top.flags  = cast(u16)~cast(u16)0;
	top.params = cfg->universe_pm;
	gb_memset(&top.widths, 0xff, gb_size_of(top.widths));

	// NOTE(bill): an input is defined on entry, as are the stack pointer and the #preserve registers; no flag is
	AsmDefs entry = {};
	for_array(i, decls) {
		auto const &ed = decls[i];
		if (ed.no_init || ed.param_group == AsmTemplateEntityDeclParamGroup_Input) {
			entry.params |= asm_cfg_param_bit(cfg, ed.entity);
			entry.regs   |= cfg->decl_pin_bit[i];

			i32 wi = asm_reg_index_from_bit(cfg->decl_pin_bit[i]);
			if (wi >= 0) {
				i32 tw = gb_min(cast(i32)(type_size_of(ed.entity->type) * 8), 255);
				entry.widths.e[wi] = gb_max(entry.widths.e[wi], cast(u8)tw);
			}
		} else if (ed.param_group == AsmTemplateEntityDeclParamGroup_Output && ed.tie >= 0) {
			entry.params |= asm_cfg_param_bit(cfg, ed.entity);
		}
	}
	u16 preserve_bits = asm_stack_pointer_bit(asm_ctx);
	for (String const &reg : ate->preserve_registers_set) {
		preserve_bits |= asm_ctx->clobber_bit_for_reg_name(reg);
	}
	entry.regs |= preserve_bits;
	for (i32 idx = 0; idx < ASM_WIDTH_REG_COUNT; idx++) {
		if (preserve_bits & (1u << idx)) {
			entry.widths.e[idx] = gb_max(entry.widths.e[idx], full);
		}
	}

	isize const n = cfg->blocks.count;

	// predecessors, restricted to reachable blocks
	auto preds = slice_make<Array<i32>>(heap_allocator(), n);
	defer ({
		for_array(i, preds) {
			array_free(&preds[i]);
		}
		slice_free(&preds, heap_allocator());
	});
	for_array(bi, cfg->blocks) {
		preds[bi].allocator = heap_allocator();
	}
	for_array(bi, cfg->blocks) {
		if (cfg->blocks[bi].reachable) {
			for (i32 s : cfg->blocks[bi].succs) {
				array_add(&preds[s], cast(i32)bi);
			}
		}
	}

	auto in  = slice_make<AsmDefs>(heap_allocator(), n); defer (slice_free(&in,  heap_allocator()));
	auto out = slice_make<AsmDefs>(heap_allocator(), n); defer (slice_free(&out, heap_allocator()));
	for_array(bi, cfg->blocks) {
		in [bi] = bi == 0 ? entry : top;
		out[bi] = asm_cfg_block_out(cfg, cfg->blocks[bi], in[bi]);
	}

	// NOTE(bill): forward must-analysis: a block's `in` is the meet of its predecessors' `out`, iterated to a fixpoint
	for (bool changed = true; changed; /**/) {
		changed = false;
		for_array(bi, cfg->blocks) {
			if (bi == 0 || !cfg->blocks[bi].reachable) {
				continue;
			}
			AsmDefs defs = top;
			for (i32 p : preds[bi]) {
				asm_defs_meet(&defs, out[p]);
			}
			if (asm_defs_equal(defs, in[bi])) {
				continue;
			}
			in [bi] = defs;
			out[bi] = asm_cfg_block_out(cfg, cfg->blocks[bi], defs);
			changed = true;
		}
	}

	{ // NOTE(bill): unreachable code
		auto block_is_targeted = slice_make<bool>(heap_allocator(), cfg->blocks.count);
		defer (slice_free(&block_is_targeted, heap_allocator()));

		for_array(bi, cfg->blocks) {
			AsmInstructionFacts *lf = cfg->insts[cfg->blocks[bi].last]->facts;
			if (lf != nullptr && lf->branch_target != nullptr) {
				i32 t = asm_cfg_label_block_index(lf->branch_target);
				if (t < cast(i32)cfg->blocks.count) { // a jump to the implicit end targets no block
					block_is_targeted[t] = true;
				}
			}
		}

		for_array(bi, cfg->blocks) {
			AsmBlock const &block = cfg->blocks[bi];
			if (block.reachable) {
				continue;
			}
			AstAsmInstruction *first = cfg->insts[block.first];
			char const *plural = (block.first == block.last) ? "instruction is" : "instructions are";
			if (block_is_targeted[bi]) {
				warning(first->name, "The asm %s unreachable: this block is only reached from code that is itself unreachable", plural);
			} else {
				warning(first->name, "The asm %s unreachable: no branch targets it and control cannot fall through from above (e.g. it follows an unconditional jump, return, or halt)", plural);
			}
		}
	}

	{ // NOTE(bill): read-before-write, definite-assignment across the whole CFG
		PtrSet<Entity *> reported_params = {};
		defer (ptr_set_destroy(&reported_params));

		u16 reported_regs  = 0;
		u16 reported_flags = 0;

		for_array(bi, cfg->blocks) {
			AsmBlock const &b = cfg->blocks[bi];
			if (!b.reachable) {
				continue;
			}

			AsmDefs run = in[bi];
			for (i32 ii = b.first; ii <= b.last; ii++) {
				AstAsmInstruction   *instr = cfg->insts[ii];
				AsmInstructionFacts *f     = instr->facts;
				if (f == nullptr) {
					continue;
				}

				u16 undef = f->read_regs & REG_TOP & ~run.regs & ~reported_regs;
				for (u16 bit = 1; bit != 0; bit <<= 1) {
					if ((undef & bit) == 0) {
						continue;
					}
					reported_regs |= bit;
					check_asm_cfg_report_undef_reg(asm_ctx, cfg, entity, instr, f->name, bit);
				}

				bool is_status_snapshot = instr->valid_form_index >= 0 &&
				                          asm_ctx->clobber_forms(instr->mnemonic)[instr->valid_form_index].is_status_snapshot();

				u16 undef_flags = f->read_flags & ~run.flags & ~reported_flags;
				if (!is_status_snapshot && undef_flags != 0) {
					reported_flags |= undef_flags;

					gbString flag_strs = gb_string_make(heap_allocator(), "");
					defer (gb_string_free(flag_strs));

					isize count = 0;
					for (u16 bit = 1; bit != 0; bit <<= 1) {
						if (bit & undef_flags) {
							if (count++ > 0) {
								flag_strs = gb_string_appendc(flag_strs, ", ");
							}
							flag_strs = gb_string_appendc(flag_strs, "%flags.");
							flag_strs = gb_string_appendc(flag_strs, asm_ctx->clobber_flag_bit_name(bit));
						}
					}

					error(instr->name,
					      "'%.*s' reads %s (%s) that is not set on all paths reaching here; "
					      "a flag-setting instruction (e.g. 'cmp', 'test') must precede it on every path",
					      LIT(f->name), count > 1 ? "status flags" : "a status flag", flag_strs);
				}

				// Sub-register width
				for (i32 w_idx = 0; w_idx < ASM_WIDTH_REG_COUNT; w_idx++) {
					u8  rw  = f->read_reg_w.e[w_idx];
					u16 bit = cast(u16)(1u << w_idx);
					if (rw == 0 || (reported_regs & bit) != 0 || run.widths.e[w_idx] >= rw) {
						continue;
					}
					reported_regs |= bit;
					error(instr->name,
					      "'%.*s' reads %s at %u-bit width but only its low %u bits are defined on all paths here; "
					      "write the full register first (e.g. zero-extend, or a full-width or 32-bit-zeroing write)",
					      LIT(f->name), asm_ctx->clobber_reg_bit_name(bit), cast(unsigned)rw, cast(unsigned)run.widths.e[w_idx]);
				}

				for (Entity *pe : f->read_params) {
					i32 *ix = map_get(&cfg->entity_to_index, pe);
					if (ix == nullptr || ((run.params >> *ix) & 1) != 0 || ptr_set_exists(&reported_params, pe)) {
						continue;
					}
					Ast *loc = instr->name;
					for (Ast *op : instr->operands) {
						if (entity_of_node(op) == pe) {
							loc = op;
							break;
						}
					}
					error(loc, "'%.*s' reads '%.*s' before it is assigned; its initial value is undefined", LIT(f->name), LIT(pe->token.string));
					ptr_set_add(&reported_params, pe);
				}

				asm_defs_apply(cfg, &run, f);
			}
		}
	}

	AsmDefs exit     = top; // what is defined on every path that leaves the template
	bool    any_exit = false;
	for_array(bi, cfg->blocks) {
		if (cfg->blocks[bi].reachable && check_asm_cfg_block_leaves(cfg, cast(i32)bi)) {
			asm_defs_meet(&exit, out[bi]);
			any_exit = true;
		}
	}

	if (diverging) {
		if (any_exit) {
			error(entity->token,
			      "This 'asm' template is declared diverging (-> !) but a reachable path can fall through the end; "
			      "end every path with an unconditional jump, return, halt, or call to a diverging (-> !) procedure");
		}
		return;
	}

	if (!any_exit) {
		// Distinguish an unconditional self-loop (jmp to own block, no other exit edge)
		// from the general no-returning-path case.
		for_array(bi, cfg->blocks) {
			AsmBlock const &b = cfg->blocks[bi];
			if (b.reachable && b.succs.count == 1 && b.succs[0] == cast(i32)bi) {
				error(cfg->insts[b.first]->name,
				      "This asm instruction forms an unconditional self-loop and can never exit; "
				      "if the template is meant never to return, declare it diverging (-> !)");
				return;
			}
		}
		error(entity->token,
		      "This 'asm' template has no reachable path that returns or falls through the end; "
		      "if this is intended, declare it diverging (-> !)");
		return;
	}

	// NOTE(bill): Outputs must be assigned on every path that returns
	for_array(i, decls) {
		auto const &ed = decls[i];
		if (ed.param_group != AsmTemplateEntityDeclParamGroup_Output || ed.tie >= 0 || ed.no_init) {
			continue;
		}

		bool written  = false;
		u16  flag_bit = asm_decl_resolve_flag_bit(asm_ctx, ed);
		u16  reg_bit  = cfg->decl_pin_bit[i];
		if (flag_bit != 0) {
			// Flag-pinned output: defined iff the pinned flag is set on every returning path.
			written = (exit.flags & flag_bit) != 0;
		} else if (reg_bit != 0) {
			written = (exit.regs & reg_bit) != 0;
		} else {
			written = (exit.params & asm_cfg_param_bit(cfg, ed.entity)) != 0;
		}
		if (!written) {
			error(ed.entity->token,
			      "'asm' output parameter '%.*s' is not assigned on all paths through this template; "
			      "its value is undefined",
			      LIT(ed.entity->token.string));
		}
	}
}

// NOTE(bill): the registers an instruction reads by name, implicitly, or through a pinned parameter
gb_internal u16 asm_cfg_read_regs(AsmCfg *cfg, AsmInstructionFacts *f) {
	u16 regs = f->read_regs;
	for (Entity *pe : f->read_params) {
		if (i32 *ix = map_get(&cfg->entity_to_index, pe)) {
			regs |= cfg->decl_pin_bit[*ix];
		}
	}
	return regs;
}

gb_internal u16 asm_cfg_live_before(AsmCfg *cfg, AsmInstructionFacts *f, u16 live_after, u16 reg_top) {
	if (f->reads_every_register) {
		return reg_top;
	}
	return (live_after & ~asm_full_kill_mask(f)) | (asm_cfg_read_regs(cfg, f) & reg_top);
}

// Backward liveness: a value is live at a point if some path from there reads it before overwriting it.
// Dual of the forward definite-assignment pass, used to find dead writes: a definition never read before
// being overwritten or before the template exits.
//
// NOTE(bill): only call this when all instructions are "good".
template <typename AsmCtx>
gb_internal void check_asm_cfg_liveness(AsmCtx *asm_ctx, AsmCfg *cfg, Entity *entity) {
	isize const n = cfg->blocks.count;
	if (n == 0) {
		return;
	}

	u16 const REG_TOP = asm_ctx->CLOBBER_REGS_NAMED;

	u16 exit_live   = asm_stack_pointer_bit(asm_ctx);
	u16 output_regs = 0;
	for_array(i, entity->AsmTemplate.decls) {
		if (entity->AsmTemplate.decls[i].param_group == AsmTemplateEntityDeclParamGroup_Output) {
			output_regs |= cfg->decl_pin_bit[i]; // pinned/view-inherited output reg, if any
		}
	}
	exit_live |= output_regs;
	for (String const &reg : entity->AsmTemplate.clobber_registers_set) {
		exit_live |= asm_ctx->clobber_bit_for_reg_name(reg);
	}

	auto live_in  = slice_make<u16>(heap_allocator(), n); defer (slice_free(&live_in,  heap_allocator()));
	auto live_out = slice_make<u16>(heap_allocator(), n); defer (slice_free(&live_out, heap_allocator()));

	for (bool changed = true; changed; /**/) {
		changed = false;
		// Iterate in reverse for faster convergence
		for (isize bi = n - 1; bi >= 0; bi--) {
			AsmBlock const &b = cfg->blocks[bi];
			if (!b.reachable) {
				continue;
			}

			u16 lo = check_asm_cfg_block_leaves(cfg, cast(i32)bi) ? exit_live : 0;
			for (i32 s : b.succs) {
				lo |= live_in[s];
			}

			u16 live = lo;
			for (i32 ii = b.last; ii >= b.first; ii--) {
				if (AsmInstructionFacts *f = cfg->insts[ii]->facts) {
					live = asm_cfg_live_before(cfg, f, live, REG_TOP);
				}
			}

			if (lo != live_out[bi] || live != live_in[bi]) {
				live_out[bi] = lo;
				live_in[bi]  = live;
				changed = true;
			}
		}
	}

	// Dead-write detection: replay each block backwards from its live-out. A register an instruction
	// writes, does not itself read (self-use like `xor r,r` or `add r,x`), and is not live afterward is a dead write.
	for_array(bi, cfg->blocks) {
		AsmBlock const &b = cfg->blocks[bi];
		if (!b.reachable) {
			continue;
		}
		u16 live = live_out[bi];
		for (i32 ii = b.last; ii >= b.first; ii--) {
			AsmInstructionFacts *f = cfg->insts[ii]->facts;
			if (f == nullptr) {
				continue;
			}
			u16 dead = f->reads_every_register ? 0 : asm_full_kill_mask(f) & ~live & ~asm_cfg_read_regs(cfg, f);
			for (u16 bit = 1; bit != 0; bit <<= 1) {
				if ((dead & bit) == 0) {
					continue;
				}
				if ((bit & output_regs) != 0) {
					warning(f->node->name,
					        "'%.*s' writes output register %%%s, but that value is overwritten before the template returns; "
					        "the output's final value does not come from this instruction",
					        LIT(f->name), asm_ctx->clobber_reg_bit_name(bit));
				} else {
					warning(f->node->name,
					        "'%.*s' writes %%%s but its value is never read before being overwritten or the template ends",
					        LIT(f->name), asm_ctx->clobber_reg_bit_name(bit));
				}
			}
			live = asm_cfg_live_before(cfg, f, live, REG_TOP);
		}
	}
}
