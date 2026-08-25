struct AsmBlock {
	i32        first; // instruction index
	i32        last;

	Array<i32> succs;

	u16              in_defs;
	u16              out_defs;

	u16              in_flags;
	u16              out_flags;

	u16              live_in_regs;
	u16              live_out_regs;

	PtrSet<Entity *> in_params;
	PtrSet<Entity *> out_params;

	bool             reachable;
};

struct AsmInstructionFacts {
	AstAsmInstruction *node;
	String             name;

	u16 gen_flags; // flag bits this instruction defines
	u16 gen_regs;
	u16 read_regs;

	Array<Entity *> gen_params;
	Array<Entity *> read_params;

	bool is_control;
	bool is_conditional;
	bool is_terminal;

	Entity *branch_target;
	i32     block_id;
};

struct AsmCfg {
	// Union of registers implicitly clobbered by matched forms (for redundant-#clobber hints).
	u16 implicit_clobbered_regs;
	u16 explicitly_produced_regs;
	u16 stale_outputs;

	bool saw_any_instructions; // NOTE(bill): An empty diverging body cannot diverge.

	// NOTE(bill): Related to #align_stack
	// any call/branch (CONTROL) or memory effect that could require the stack
	// to be realigned. If none occurred, #align_stack is redundant.
	bool saw_call_or_mem;

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
};


gb_internal void asm_cfg_destroy(AsmCfg *cfg) {
	for (auto &block : cfg->blocks) {
		array_free(&block.succs);
		ptr_set_destroy(&block.in_params);
		ptr_set_destroy(&block.out_params);
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
gb_internal bool asm_cfg_label_block_index_set(Entity *entity, i32 index) {
	if (entity != nullptr && entity->kind == Entity_Label) {
		GB_ASSERT(entity->Label.asm_block_index < 0);
		entity->Label.asm_block_index = index;
	}
	return false;
}

// The physical-register bit a decl is pinned to. A width-view carries no pin of
// its own; it inherits its source decl's pin. Returns 0 for unpinned decls.
template <typename AsmCtx>
gb_internal u16 asm_decl_resolve_pin_bit(AsmCtx *asm_ctx, Array<AsmTemplateEntityDecl> const &decls, i32 di) {
	if (di < 0 || di >= cast(i32)decls.count) {
		return 0;
	}
	auto const &ed = decls[di];
	if (ed.pin.len != 0) {
		return asm_ctx->clobber_bit_for_reg_name(ed.pin);
	}
	if (ed.view_of >= 0 && ed.view_of < cast(i32)decls.count) {
		String src_pin = decls[ed.view_of].pin;
		if (src_pin.len != 0) {
			return asm_ctx->clobber_bit_for_reg_name(src_pin);
		}
	}
	return 0;
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
		Entity *e = decls[i].entity;
		cfg->decl_pin_bit[i] = asm_decl_resolve_pin_bit(asm_ctx, decls, cast(i32)i);
		if (e != nullptr) {
			if (decls[i].view_of >= 0) {
				// NOTE(bill): A view shares its source's lattice bit, as it is not an independent value.
				i32 src_i = decls[i].view_of;
				Entity *src_e = decls[src_i].entity;
				if (src_e != nullptr) {
					map_set(&cfg->entity_to_index, e, src_i);
				}
				// NOTE(bill): No need to set a universe bit for the view as the source already has one
			} else {
				map_set(&cfg->entity_to_index, e, cast(i32)i);
				cfg->universe_pm |= (cast(u64)1 << i);
			}
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

		i32 bi = cast(i32)cfg->blocks.count - 1;
		i32 ii = cast(i32)cfg->insts.count;
		array_add(&cfg->insts, instr);
		cfg->blocks[bi].last = ii;

		if (facts != nullptr) {
			facts->block_id = bi;
			if (facts->is_control) {
				need_leader = true;
			}
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
				if (0 <= t && t < cast(i32)cfg->blocks.count) {
					branch_succ = t;
				}
				// For `t == blocks.count`, this implies a jump to the implicit end, and is handled as "leaves" below
			}
			// e.g. jmp/ret/hlt (and, conservatively, call) do not fall through in this model.
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
			i32 bi = stack[stack.count-1];
			stack.count -= 1;
			for (i32 s : cfg->blocks[bi].succs) {
				if (s >= 0 && s < cast(i32)cfg->blocks.count && !cfg->blocks[s].reachable) {
					cfg->blocks[s].reachable = true;
					array_add(&stack, s);
				}
			}
		}
	}
}

gb_internal bool check_asm_cfg_block_leaves(AsmCfg *cfg, i32 bi) {
	AsmBlock const      *b    = &cfg->blocks[bi];
	AstAsmInstruction   *last = cfg->insts[b->last];
	AsmInstructionFacts *lf   = last->facts;

	if (lf != nullptr && lf->branch_target != nullptr) {
		i32 t = asm_cfg_label_block_index(lf->branch_target);
		if (t >= 0 && t >= cast(i32)cfg->blocks.count) {
			return true; // 'jmp .end' — falls into the implicit return
		}
	}
	bool terminal = (lf != nullptr) && lf->is_terminal;
	if (!terminal && (bi+1 >= cast(i32)cfg->blocks.count)) {
		return true; // straight-line/conditional-tail with nothing after it
	}
	return false;
}

template <typename AsmCtx>
gb_internal void check_asm_cfg_report_undef_reg(AsmCtx *asm_ctx, AsmCfg *cfg, Entity *tmpl_entity,
                                                AstAsmInstruction *instr, String name, u16 bit) {
	char const *rname = asm_ctx->clobber_reg_bit_name(bit);
	String      owner = {};
	char const *role  = nullptr;

	auto const &decls = tmpl_entity->AsmTemplate.decls;
	for_array(i, decls) {
		auto const &ed = decls[i];
		if (ed.entity == nullptr || cfg->decl_pin_bit[i] != bit) {
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
		      "'%.*s' implicitly reads %%%s, which is bound to the %s parameter '%.*s', "
		      "but nothing writes %%%s on all paths reaching here; write to it (e.g. into '%.*s') first",
		      LIT(name), rname, role, LIT(owner), rname, LIT(owner));
	} else {
		error(instr->name,
		      "'%.*s' implicitly reads %%%s, but nothing in this template produces a value for it "
		      "on all paths reaching here; pin an input to %%%s, or write %%%s first",
		      LIT(name), rname, rname, rname);
	}
}

template <typename AsmCtx>
gb_internal void check_asm_cfg_analyse(AsmCtx *asm_ctx, AsmCfg *cfg, CheckerContext *ctx, Entity *entity) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto const &decls     = entity->AsmTemplate.decls;
	bool        diverging = entity->type->Proc.diverging;

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
	u16 const REG_TOP  = asm_ctx->CLOBBER_REGS_NAMED;
	u16 const FLAG_TOP = cast(u16)~cast(u16)0;

	u64 const universe_pm = cfg->universe_pm;
	auto bit_of = [&](Entity *e) -> u64 {
		i32 *ix = map_get(&cfg->entity_to_index, e);
		return ix ? (cast(u64)1 << *ix) : cast(u64)0;
	};

	// NOTE(bill): entry seed intiailization which mirrors the linear seeding of defined_regs
	u16 seed_regs = 0;
	u64 seed_pm   = 0;
	for_array(i, decls) {
		auto const &ed = decls[i];
		u16 pin_bit = cfg->decl_pin_bit[i];
		if (ed.no_init) {
			seed_pm |= bit_of(ed.entity);
			seed_regs |= pin_bit;
		}
		switch (ed.param_group) {
		case AsmTemplateEntityDeclParamGroup_Input:
			seed_pm |= bit_of(ed.entity);
			seed_regs |= pin_bit;
			break;
		case AsmTemplateEntityDeclParamGroup_Output:
			if (ed.tie >= 0) {
				seed_pm |= bit_of(ed.entity);
			}
			break;
		}
	}

	isize const n = cfg->blocks.count;

	auto in_regs   = slice_make<u16>(heap_allocator(), n); defer (slice_free(&in_regs,   heap_allocator()));
	auto out_regs  = slice_make<u16>(heap_allocator(), n); defer (slice_free(&out_regs,  heap_allocator()));
	auto gen_regs  = slice_make<u16>(heap_allocator(), n); defer (slice_free(&gen_regs,  heap_allocator()));
	auto in_flags  = slice_make<u16>(heap_allocator(), n); defer (slice_free(&in_flags,  heap_allocator()));
	auto out_flags = slice_make<u16>(heap_allocator(), n); defer (slice_free(&out_flags, heap_allocator()));
	auto gen_flags = slice_make<u16>(heap_allocator(), n); defer (slice_free(&gen_flags, heap_allocator()));
	auto in_pm     = slice_make<u64>(heap_allocator(), n); defer (slice_free(&in_pm,     heap_allocator()));
	auto out_pm    = slice_make<u64>(heap_allocator(), n); defer (slice_free(&out_pm,    heap_allocator()));
	auto gen_pm    = slice_make<u64>(heap_allocator(), n); defer (slice_free(&gen_pm,    heap_allocator()));

	// predecessors, restricted to reachable blocks
	auto preds = slice_make<Array<i32>>(heap_allocator(), n);
	for_array(i, preds) {
		preds[i].allocator = heap_allocator();
	}
	defer ({
		for_array(i, preds) {
			array_free(&preds[i]);
		}
		slice_free(&preds, heap_allocator());
	});
	for_array(bi, cfg->blocks) {
		AsmBlock *block = &cfg->blocks[bi];
		if (!block->reachable) {
			continue;
		}
		for (i32 s : block->succs) {
			if (0 <= s && s < cast(i32)n &&
			    cfg->blocks[s].reachable) {
				array_add(&preds[s], cast(i32)bi);
			}
		}
	}

	for_array(bi, cfg->blocks) {
		u16 gr = 0;
		u16 gf = 0;
		u64 gp = 0;
		AsmBlock const &b = cfg->blocks[bi];
		for (i32 ii = b.first; ii <= b.last; ii++) {
			AsmInstructionFacts *f = cfg->insts[ii]->facts;
			if (f == nullptr) {
				continue;
			}
			gr |= f->gen_regs;
			gf |= f->gen_flags;
			for (Entity *pe : f->gen_params) {
				gp |= bit_of(pe);
			}
		}
		gen_regs[bi]  = gr;
		gen_flags[bi] = gf;
		gen_pm[bi]    = gp;
	}

	// NOTE(bill): initialize the blocks
	// entry is from the seeds and every other reachable block from TOP (intersection)
	for_array(bi, cfg->blocks) {
		if (!cfg->blocks[bi].reachable) {
			continue;
		}
		if (bi == 0) {
			in_regs[bi]  = seed_regs;
			in_pm[bi]    = seed_pm;
			in_flags[bi] = 0; // no flag is defined at the template entry point
		} else {
			in_regs[bi]  = REG_TOP;
			in_pm[bi]    = universe_pm;
			in_flags[bi] = FLAG_TOP;
		}
		out_regs[bi]  = in_regs[bi]  | gen_regs[bi];
		out_pm[bi]    = in_pm[bi]    | gen_pm[bi];
		out_flags[bi] = in_flags[bi] | gen_flags[bi];
	}

	// forward must-analysis: in = AND(preds.out); out = in | gen. Iterate to fixpoint.
	bool changed = true;
	while (changed) {
		changed = false;
		for_array(bi, cfg->blocks) {
			if (!cfg->blocks[bi].reachable) {
				continue;
			}

			u16 nin_r = seed_regs;
			u16 nin_f = 0;
			u64 nin_p = seed_pm;
			if (bi != 0) {
				nin_r = REG_TOP;
				nin_f = FLAG_TOP;
				nin_p = universe_pm;
				for (i32 p : preds[bi]) {
					nin_r &= out_regs[p];
					nin_r &= out_flags[p];
					nin_p &= out_pm[p];
				}
			}
			u16 nout_r = nin_r | gen_regs[bi];
			u64 nout_p = nin_p | gen_pm[bi];
			u16 nout_f = nin_f | gen_flags[bi];

			if (nin_r  != in_regs[bi]  ||
			    nin_p  != in_pm[bi]    ||
			    nin_f  != in_flags[bi] ||
			    nout_r != out_regs[bi] ||
			    nout_p != out_pm[bi]   ||
			    nout_f != out_flags[bi]) {
				in_regs[bi]   = nin_r;
				in_pm[bi]     = nin_p;
				in_flags[bi]  = nin_f;
				out_regs[bi]  = nout_r;
				out_pm[bi]    = nout_p;
				out_flags[bi] = nout_f;
				changed = true;
			}
		}
	}

	// NOTE(bill): publish the register masks and materialise the parameter sets onto the blocks
	for_array(bi, cfg->blocks) {
		AsmBlock *b = &cfg->blocks[bi];
		b->in_defs   = in_regs[bi];
		b->out_defs  = out_regs[bi];
		b->in_flags  = in_flags[bi];
		b->out_flags = out_flags[bi];
		if (!b->reachable) {
			continue;
		}
		for_array(i, decls) {
			Entity *e = decls[i].entity;
			if (e == nullptr) {
				continue;
			}
			if (((in_pm[bi]  >> i) & 1) != 0) {
				ptr_set_add(&b->in_params,  e);
			}
			if (((out_pm[bi] >> i) & 1) != 0) {
				ptr_set_add(&b->out_params, e);
			}
		}
	}
	{
		auto block_is_targeted = slice_make<bool>(heap_allocator(), cfg->blocks.count);
		defer (slice_free(&block_is_targeted, heap_allocator()));

		for_array(bi, cfg->blocks) {
			AstAsmInstruction   *last = cfg->insts[cfg->blocks[bi].last];
			AsmInstructionFacts *lf   = last->facts;
			if (lf != nullptr && lf->branch_target != nullptr) {
				i32 t = asm_cfg_label_block_index(lf->branch_target);
				if (0 <= t && t < cast(i32)cfg->blocks.count) {
					block_is_targeted[t] = true;
				}
			}
		}

		// NOTE(bill): unreachable code
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

		u16 reported_regs = 0;

		for_array(bi, cfg->blocks) {
			AsmBlock const &b = cfg->blocks[bi];
			if (!b.reachable) {
				continue;
			}

			u16 run_regs = in_regs[bi];
			u64 run_pm   = in_pm[bi];

			for (i32 ii = b.first; ii <= b.last; ii++) {
				AstAsmInstruction   *instr = cfg->insts[ii];
				AsmInstructionFacts *f     = instr->facts;
				if (f == nullptr) {
					continue;
				}

				u16 undef = f->read_regs & REG_TOP & ~run_regs & ~reported_regs;
				for (u16 bit = 1; bit != 0; bit <<= 1) {
					if ((undef & bit) == 0) {
						continue;
					}
					check_asm_cfg_report_undef_reg(asm_ctx, cfg, entity, instr, f->name, bit);
					reported_regs |= bit;
				}

				for (Entity *pe : f->read_params) {
					i32 *ix = map_get(&cfg->entity_to_index, pe);
					if (ix == nullptr) {
						continue;
					}
					if (((run_pm >> *ix) & 1) == 0 && !ptr_set_exists(&reported_params, pe)) {
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
				}

				run_regs |= f->gen_regs;
				for (Entity *pe : f->gen_params) {
					run_pm |= bit_of(pe);
				}
			}
		}
	}

	{ // NOTE(bill): Collect the template's return points reachable blocks that leave via the end
		u16  exit_regs  = REG_TOP;
		u64  exit_pm    = universe_pm;
		u16  exit_flags = FLAG_TOP;
		bool any_exit  = false;
		for_array(bi, cfg->blocks) {
			if (!cfg->blocks[bi].reachable) {
				continue;
			}
			if (!check_asm_cfg_block_leaves(cfg, cast(i32)bi)) {
				continue;
			}
			any_exit  = true;
			exit_regs  &= out_regs[bi];
			exit_pm    &= out_pm[bi];
			exit_flags &= out_flags[bi];
		}

		// NOTE(bill): Outputs must be assigned on every path that returns
		if (any_exit && !diverging) {
			for_array(i, decls) {
				auto const &ed = decls[i];
				if (ed.param_group != AsmTemplateEntityDeclParamGroup_Output) {
					continue;
				}
				if (ed.tie >= 0 || ed.no_init) {
					continue;
				}

				bool written = false;
				u16 flag_bit = asm_decl_resolve_flag_bit(asm_ctx, ed);
				u16 reg_bit  = cfg->decl_pin_bit[i];
				if (flag_bit != 0) {
					// Flag-pinned output: defined iff the pinned flag is set on every returning path.
					written = (exit_flags & flag_bit) != 0;
				} else if (reg_bit != 0) {
					written = (exit_regs & reg_bit) != 0;
				} else {
					written = (exit_pm & bit_of(ed.entity)) != 0;
 				}
				if (!written) {
					error(ed.entity->token,
					      "'asm' output parameter '%.*s' is not assigned on all paths through this template; "
					      "its value is undefined",
					      LIT(ed.entity->token.string));
				}
			}
		}
	}

	if (diverging) { // No reachable path may return / fall off the end
		bool any_leak = false;
		for_array(bi, cfg->blocks) {
			if (cfg->blocks[bi].reachable && check_asm_cfg_block_leaves(cfg, cast(i32)bi)) {
				any_leak = true;
				break;
			}
		}
		if (any_leak) {
			error(entity->token,
			      "This 'asm' template is declared diverging (-> !) but a reachable path can fall through the end; "
			      "end every path with an unconditional jump, return, or halt");
		}
	} else {
		// Not declared diverging: no reachable block leaves => control never returns
		bool any_exit = false;
		for_array(bi, cfg->blocks) {
			auto const &block = cfg->blocks[bi];
			if (block.reachable && check_asm_cfg_block_leaves(cfg, cast(i32)bi)) {
				any_exit = true;
				break;
			}
		}
		if (!any_exit) {
			// Distinguish an unconditional self-loop (jmp to own block, no other exit edge)
			// from the general no-returning-path case.
			i32 self_loop_bi = -1;
			for_array(bi, cfg->blocks) {
				AsmBlock const &b = cfg->blocks[bi];
				if (!b.reachable) {
					continue;
				}
				bool loops_to_self = false;
				for (i32 s : b.succs) {
					if (s == cast(i32)bi) {
						loops_to_self = true;
						break;
					}
				}
				if (loops_to_self && b.succs.count == 1) {
					self_loop_bi = cast(i32)bi;
					break;
				}
			}

			if (self_loop_bi >= 0) {
				AstAsmInstruction *first = cfg->insts[cfg->blocks[self_loop_bi].first];
				error(first->name,
				      "This asm instruction forms an unconditional self-loop and can never exit; "
				      "if the template is meant never to return, declare it diverging (-> !)");
			} else {
				error(entity->token,
				      "This 'asm' template has no reachable path that returns or falls through the end; "
				      "if this is intended, declare it diverging (-> !)");
			}
		}
 	}
}

// Backward liveness: a value is live at a point if some path from there reads it before overwriting it.
// Dual of the forward definite-assignment pass.
// Used to find dead writes (a definition never read before being overwritten or before template exit).
//
// NOTE(bill): only set `emit_dead_writes` to be true when all instructions are "good".
template <typename AsmCtx>
gb_internal bool check_asm_cfg_liveness(AsmCtx *asm_ctx, AsmCfg *cfg, Entity *entity, bool emit_dead_writes) {
	isize const n = cfg->blocks.count;
	if (n == 0) {
		return false;
	}

	u16 const REG_TOP = asm_ctx->CLOBBER_REGS_NAMED;

	u16 exit_live = 0;
	u16 output_regs = 0;
	for_array(i, entity->AsmTemplate.decls) {
		auto const &ed = entity->AsmTemplate.decls[i];
		if (ed.param_group == AsmTemplateEntityDeclParamGroup_Output) {
			exit_live   |= cfg->decl_pin_bit[i]; // pinned/view-inherited output reg, if any
			output_regs |= cfg->decl_pin_bit[i];
		}
	}
	for (String const &reg : entity->AsmTemplate.clobber_registers_set) {
		exit_live |= asm_ctx->clobber_bit_for_reg_name(reg);
	}

	auto live_in  = slice_make<u16>(heap_allocator(), n); defer (slice_free(&live_in,  heap_allocator()));
	auto live_out = slice_make<u16>(heap_allocator(), n); defer (slice_free(&live_out, heap_allocator()));

	bool changed = true;
	while (changed) {
		changed = false;
		// Iterate in reverse for faster convergence
		for (isize bi = n - 1; bi >= 0; bi--) {
			if (!cfg->blocks[bi].reachable) {
				continue;
			}
			AsmBlock const &b = cfg->blocks[bi];

			// live_out = union of successors' live_in, plus exit_live if this block leaves.
			u16 lo = 0;
			for (i32 s : b.succs) {
				if (0 <= s && s < cast(i32)n && cfg->blocks[s].reachable) {
					lo |= live_in[s];
				}
			}
			if (check_asm_cfg_block_leaves(cfg, cast(i32)bi)) {
				lo |= exit_live;
			}

			u16 live = lo;
			for (i32 ii = b.last; ii >= b.first; ii--) {
				AsmInstructionFacts *f = cfg->insts[ii]->facts;
				if (f == nullptr) {
					continue;
				}
				live = (live & ~f->gen_regs) | (f->read_regs & REG_TOP);
			}

			if (lo != live_out[bi] || live != live_in[bi]) {
				live_out[bi] = lo;
				live_in[bi]  = live;
				changed = true;
			}
		}
	}

	for_array(bi, cfg->blocks) {
		cfg->blocks[bi].live_in_regs  = live_in[bi];
		cfg->blocks[bi].live_out_regs = live_out[bi];
	}

	if (!emit_dead_writes) {
		// Lattice has been computed but no diagnostic until the read facts are validated
		return false;
	}

	// Dead-write detection: walk each block forward, tracking live-out per instruction.
	// A written reg that is not live immediately after the write (and not re-read in
	// this same instruction) is dead.
	for_array(bi, cfg->blocks) {
		AsmBlock const &b = cfg->blocks[bi];
		if (!b.reachable) {
			continue;
		}
		// recompute per-instruction live-out by replaying the transfer from block live_out
		// (cheap: block is short). Build an array of live-after-each-instruction.
		u16 live = live_out[bi];
		if (check_asm_cfg_block_leaves(cfg, cast(i32)bi)) {
			live |= exit_live; // already folded above, but harmless
		}
		for (i32 ii = b.last; ii >= b.first; ii--) {
			AsmInstructionFacts *f = cfg->insts[ii]->facts;
			if (f == nullptr) {
				continue;
			}
			u16 live_after = live;
			// A register this instruction writes but that is not live afterward,
			// and that it does not itself read (self-use like `xor r,r` or `add r,x`),
			// is a dead write.
			u16 dead = f->gen_regs & ~live_after & ~f->read_regs;
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
			live = (live & ~f->gen_regs) | (f->read_regs & REG_TOP);
		}
	}

	return true;
}