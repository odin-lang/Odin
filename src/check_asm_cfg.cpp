struct AsmBlock {
	i32 first,       last;
	Array<i32>       succs;
	u16              in_defs;
	u16              out_defs;
	PtrSet<Entity *> in_params;
	PtrSet<Entity *> out_params;
	bool             reachable;
};

struct AsmInstructionFacts {
	AstAsmInstruction *node;
	String             name;

	u16 gen_regs;
	u16 read_regs;

	Array<Entity *> gen_params;
	Array<Entity *> read_params;

	bool is_control;
	bool is_conditional;
	bool is_terminal;

	Entity *branch_target;
	i32 block_id;
};


struct AsmMnemonicAccumulator {
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

	PtrMap<AstAsmInstruction *, AsmInstructionFacts> instruction_facts;
};

struct AsmCfg {
	Array<AstAsmInstruction *> insts;       // program-order (only for fact-carrying instrs)
	Array<AsmBlock>            blocks;
	PtrMap<Entity *, i32>      label_block; // key: Entity_Label*
};

gb_internal void asm_cfg_destroy(AsmCfg *cfg) {
	for (auto &block : cfg->blocks) {
		array_free(&block.succs);
		ptr_set_destroy(&block.in_params);
		ptr_set_destroy(&block.out_params);
	}
	array_free(&cfg->blocks);
	array_free(&cfg->insts);
	map_destroy(&cfg->label_block);
}

gb_internal void check_asm_cfg_build(Ast *at_node, AsmMnemonicAccumulator *acc, AsmCfg *cfg) {
	ast_node(at, AsmTemplate, at_node);

	cfg->insts.allocator  = heap_allocator();
	cfg->blocks.allocator = heap_allocator();
	map_init(&cfg->label_block);

	bool need_leader = true;


	// Build basic blocks over the template body. A leader is: the first instruction, any
	// instruction preceded by a label, and any instruction following a control transfer.
	for (Ast *node : at->instructions) {
		if (node->kind == Ast_AsmLabelDecl) {
			// Every label between two instructions names the block the *next* instruction
			// opens; consecutive labels share it. A trailing label maps to blocks.count.
			Entity *le = node->AsmLabelDecl.name->Ident.entity;
			if (le != nullptr) {
				map_set(&cfg->label_block, le, cast(i32)cfg->blocks.count);
			}
			need_leader = true;
			continue;
		}
		if (node->kind != Ast_AsmInstruction) {
			continue; // directives are straight-line filler; no CFG effect
		}

		AstAsmInstruction   *instr = &node->AsmInstruction;
		AsmInstructionFacts *facts = map_get(&acc->instruction_facts, instr);
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
				need_leader = true; // the fall-through after a branch starts a new block
			}
		}
	}

	for_array(bi, cfg->blocks) { // Calculate the edges for the blocks
		AsmBlock *b = &cfg->blocks[bi];

		AstAsmInstruction   *last = cfg->insts[b->last];
		AsmInstructionFacts *lf   = map_get(&acc->instruction_facts, last);

		i32  branch_succ = -1;
		bool fallthrough = true;

		if (lf != nullptr && lf->is_control) {
			if (lf->branch_target != nullptr) {
				i32 *t = map_get(&cfg->label_block, lf->branch_target);
				if (t != nullptr && *t < cast(i32)cfg->blocks.count) {
					branch_succ = *t; // in-range internal target ('jmp .l' / 'jz .l')
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

gb_internal bool check_asm_cfg_block_leaves(AsmCfg *cfg, AsmMnemonicAccumulator *acc, i32 bi) {
	AsmBlock const      *b    = &cfg->blocks[bi];
	AstAsmInstruction   *last = cfg->insts[b->last];
	AsmInstructionFacts *lf   = map_get(&acc->instruction_facts, last);

	if (lf != nullptr && lf->branch_target != nullptr) {
		i32 *t = map_get(&cfg->label_block, lf->branch_target);
		if (t != nullptr && *t >= cast(i32)cfg->blocks.count) {
			return true; // 'jmp .end' — falls into the implicit return
		}
	}
	bool terminal = (lf != nullptr) && lf->is_terminal;
	if (!terminal && bi > cast(i32)cfg->blocks.count) {
		return true; // straight-line / conditional tail with nothing after it
	}
	return false;
}

template <typename AsmCtx>
gb_internal void check_asm_cfg_report_undef_reg(AsmCtx *asm_ctx, Entity *tmpl_entity,
                                                AstAsmInstruction *instr, String name, u16 bit) {
	char const *rname = asm_ctx->clobber_reg_bit_name(bit);
	String      owner = {};
	char const *role  = nullptr;
	for (auto const &ed : tmpl_entity->AsmTemplate.decls) {
		if (ed.pin.len == 0 || ed.entity == nullptr) {
			continue;
		}
		if (asm_ctx->clobber_bit_for_reg_name(ed.pin) != bit) {
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
gb_internal void check_asm_cfg_analyse(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *entity, AsmCfg *cfg,
                                       AsmMnemonicAccumulator *acc) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto const &decls     = entity->AsmTemplate.decls;
	bool        diverging = entity->type->Proc.diverging;

	if (cfg->blocks.count == 0) {
		// With an empty body, the CFG cannot really do nothing
		if (diverging && !acc->saw_any_instructions) {
			error(entity->token, "This asm template is declared as diverging (-> !) but its body is empty and cannot diverge");
		}
		return;
	}

	if (decls.count > 64) {
		error(entity->token, "'asm' templates cannot have more than 64 total parameter declarations, got %td", decls.count);
		return;
	}
	u16 const REG_TOP = asm_ctx->CLOBBER_REGS_NAMED;

	PtrMap<Entity *, i32> entity_to_index = {};
	map_init(&entity_to_index);
	defer (map_destroy(&entity_to_index));
	u64 universe_pm = 0;
	for_array(i, decls) {
		if (decls[i].entity != nullptr) {
			map_set(&entity_to_index, decls[i].entity, cast(i32)i);
			universe_pm |= (cast(u64)1 << i);
		}
	}
	auto bit_of = [&](Entity *e) -> u64 {
		i32 *ix = map_get(&entity_to_index, e);
		return ix ? (cast(u64)1 << *ix) : cast(u64)0;
	};

	// NOTE(bill): entry seed intiailization which mirrors the linear seeding of defined_regs
	u16 seed_regs = 0;
	u64 seed_pm   = 0;
	for (auto const &ed : decls) {
		if (ed.no_init) {
			seed_pm |= bit_of(ed.entity);
			if (ed.pin.len != 0) {
				seed_regs |= asm_ctx->clobber_bit_for_reg_name(ed.pin);
			}
		}
		switch (ed.param_group) {
		case AsmTemplateEntityDeclParamGroup_Input:
			seed_pm |= bit_of(ed.entity);
			if (ed.pin.len != 0) {
				seed_regs |= asm_ctx->clobber_bit_for_reg_name(ed.pin);
			}
			break;
		case AsmTemplateEntityDeclParamGroup_Output:
			// NOTE(bill): input provides the value
			if (ed.tie >= 0) {
				seed_pm |= bit_of(ed.entity);
			}
			break;
		}
	}

	isize const n = cfg->blocks.count;

	auto in_regs  = slice_make<u16>(heap_allocator(), n); defer (slice_free(&in_regs,  heap_allocator()));
	auto out_regs = slice_make<u16>(heap_allocator(), n); defer (slice_free(&out_regs, heap_allocator()));
	auto gen_regs = slice_make<u16>(heap_allocator(), n); defer (slice_free(&gen_regs, heap_allocator()));
	auto in_pm    = slice_make<u64>(heap_allocator(), n); defer (slice_free(&in_pm,    heap_allocator()));
	auto out_pm   = slice_make<u64>(heap_allocator(), n); defer (slice_free(&out_pm,   heap_allocator()));
	auto gen_pm   = slice_make<u64>(heap_allocator(), n); defer (slice_free(&gen_pm,   heap_allocator()));

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
		u64 gp = 0;
		AsmBlock const &b = cfg->blocks[bi];
		for (i32 ii = b.first; ii <= b.last; ii++) {
			AsmInstructionFacts *f = map_get(&acc->instruction_facts, cfg->insts[ii]);
			if (f == nullptr) {
				continue;
			}
			gr |= f->gen_regs;
			for (Entity *pe : f->gen_params) {
				gp |= bit_of(pe);
			}
		}
		gen_regs[bi] = gr;
		gen_pm[bi]   = gp;
	}

	// NOTE(bill): initialize the blocks
	// entry is from the seeds and every other reachable block from TOP (intersection)
	for_array(bi, cfg->blocks) {
		if (!cfg->blocks[bi].reachable) {
			continue;
		}
		if (bi == 0) {
			in_regs[bi] = seed_regs;
			in_pm[bi]   = seed_pm;
		} else {
			in_regs[bi] = REG_TOP;
			in_pm[bi]   = universe_pm;
		}
		out_regs[bi] = in_regs[bi] | gen_regs[bi];
		out_pm[bi]   = in_pm[bi]   | gen_pm[bi];
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
			u64 nin_p = seed_pm;
			if (bi != 0) {
				nin_r = REG_TOP;
				nin_p = universe_pm;
				for (i32 p : preds[bi]) {
					 nin_r &= out_regs[p];
					 nin_p &= out_pm[p];
				}
			}
			u16 nout_r = nin_r | gen_regs[bi];
			u64 nout_p = nin_p | gen_pm[bi];

			if (nin_r  != in_regs[bi]  ||
			    nin_p  != in_pm[bi]    ||
			    nout_r != out_regs[bi] ||
			    nout_p != out_pm[bi]) {
				in_regs[bi]  = nin_r;
				in_pm[bi]    = nin_p;
				out_regs[bi] = nout_r;
				out_pm[bi]   = nout_p;
				changed = true;
			}
		}
	}

	// NOTE(bill): publish the register masks and materialise the parameter sets onto the blocks
	for_array(bi, cfg->blocks) {
		AsmBlock *b = &cfg->blocks[bi];
		b->in_defs  = in_regs[bi];
		b->out_defs = out_regs[bi];
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

	// NOTE(bill): unreachable code
	for (AsmBlock &block : cfg->blocks) {
		if (block.reachable) {
			continue;
		}
		AstAsmInstruction *first = cfg->insts[block.first];
		if (block.first == block.last) {
			warning(first->name, "The asm instruction is unreachable within this block");
		} else {
			warning(first->name, "The asm instructions are unreachable within this block");
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
				AsmInstructionFacts *f     = map_get(&acc->instruction_facts, instr);
				if (f == nullptr) {
					continue;
				}

				u16 undef = f->read_regs & REG_TOP & ~run_regs & ~reported_regs;
				for (u16 bit = 1; bit != 0; bit <<= 1) {
					if ((undef & bit) == 0) {
						continue;
					}
					check_asm_cfg_report_undef_reg(asm_ctx, entity, instr, f->name, bit);
					reported_regs |= bit;
				}

				for (Entity *pe : f->read_params) {
					i32 *ix = map_get(&entity_to_index, pe);
					if (ix == nullptr) {
						continue;
					}
					if (((run_pm >> *ix) & 1) == 0 && !ptr_set_exists(&reported_params, pe)) {
						Ast *loc = instr->name;
						for (Ast *op : instr->operands) {
							if (entity_of_node(op) == pe) { loc = op; break; }
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
		u16  exit_regs = REG_TOP;
		u64  exit_pm   = universe_pm;
		bool any_exit  = false;
		for_array(bi, cfg->blocks) {
			if (!cfg->blocks[bi].reachable) {
				continue;
			}
			if (!check_asm_cfg_block_leaves(cfg, acc, cast(i32)bi)) {
				continue;
			}
			any_exit  = true;
			exit_regs &= out_regs[bi];
			exit_pm   &= out_pm[bi];
		}

		// NOTE(bill): Outputs must be assigned on every path that returns
		if (any_exit && !diverging) {
			for (auto const &ed : decls) {
				if (ed.param_group != AsmTemplateEntityDeclParamGroup_Output) {
					continue;
				}
				if (ed.tie >= 0 || ed.no_init) {
					continue;
				}

				bool written;
				if (ed.pin.len != 0) {
					u16 bit = asm_ctx->clobber_bit_for_reg_name(ed.pin);
					written = (bit != 0) && (exit_regs & bit) != 0;
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
			if (cfg->blocks[bi].reachable && check_asm_cfg_block_leaves(cfg, acc, cast(i32)bi)) {
				any_leak = true;
				break;
			}
		}
		if (any_leak) {
			error(entity->token,
			      "This asm template is declared diverging (-> !) but a reachable path can fall through the end; "
			      "end every path with an unconditional jump, return, or halt");
		}
	}
}