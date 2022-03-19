void me_build_nested_proc(meProcedure *p, AstProcLit *pd, Entity *e);

void me_build_constant_value_decl(meProcedure *p, AstValueDecl *vd) {
	if (vd == nullptr || vd->is_mutable) {
		return;
	}

	auto *min_dep_set = &p->module->info->minimum_dependency_set;

	static i32 global_guid = 0;

	for_array(i, vd->names) {
		Ast *ident = vd->names[i];
		GB_ASSERT(ident->kind == Ast_Ident);
		Entity *e = entity_of_node(ident);
		GB_ASSERT(e != nullptr);
		if (e->kind != Entity_TypeName) {
			continue;
		}

		bool polymorphic_struct = false;
		if (e->type != nullptr && e->kind == Entity_TypeName) {
			Type *bt = base_type(e->type);
			if (bt->kind == Type_Struct) {
				polymorphic_struct = bt->Struct.is_polymorphic;
			}
		}

		if (!polymorphic_struct && !ptr_set_exists(min_dep_set, e)) {
			continue;
		}

		if (e->TypeName.ir_mangled_name.len != 0) {
			// NOTE(bill): Already set
			continue;
		}

		me_set_nested_type_name_ir_mangled_name(e, p);
	}

	for_array(i, vd->names) {
		Ast *ident = vd->names[i];
		GB_ASSERT(ident->kind == Ast_Ident);
		Entity *e = entity_of_node(ident);
		GB_ASSERT(e != nullptr);
		if (e->kind != Entity_Procedure) {
			continue;
		}
		GB_ASSERT (vd->values[i] != nullptr);

		Ast *value = unparen_expr(vd->values[i]);
		if (value->kind != Ast_ProcLit) {
			continue; // It's an alias
		}

		CheckerInfo *info = p->module->info;
		DeclInfo *decl = decl_info_of_entity(e);
		ast_node(pl, ProcLit, decl->proc_lit);
		if (pl->body != nullptr) {
			auto *found = map_get(&info->gen_procs, ident);
			if (found) {
				auto procs = *found;
				for_array(i, procs) {
					Entity *e = procs[i];
					if (!ptr_set_exists(min_dep_set, e)) {
						continue;
					}
					DeclInfo *d = decl_info_of_entity(e);
					me_build_nested_proc(p, &d->proc_lit->ProcLit, e);
				}
			} else {
				me_build_nested_proc(p, pl, e);
			}
		} else {

			// FFI - Foreign function interace
			String original_name = e->token.string;
			String name = original_name;

			if (e->Procedure.is_foreign) {
				me_add_foreign_library_path(p->module, e->Procedure.foreign_library);
			}

			if (e->Procedure.link_name.len > 0) {
				name = e->Procedure.link_name;
			}

			meValue *prev_value = string_map_get(&p->module->members, name);
			if (prev_value != nullptr) {
				// NOTE(bill): Don't do mutliple declarations in the IR
				return;
			}

			e->Procedure.link_name = name;

			meProcedure *nested_proc = me_procedure_create(p->module, e);

			meValue value = me_value(nested_proc);

			array_add(&p->module->procedures_to_generate, nested_proc);
			array_add(&p->children, nested_proc);
			string_map_set(&p->module->members, name, value);
		}
	}
}

void me_build_defer_stmt(meProcedure *p, meDefer const &d) {
	if (p->curr_block == nullptr) {
		return;
	}
	// NOTE(bill): The prev block may defer injection before it's terminator
	meInstruction *last_instr = me_last_instruction(p->curr_block);
	if (last_instr != nullptr && last_instr->op == meOp_Return) {
		// NOTE(bill): ReturnStmt defer stuff will be handled previously
		return;
	}

	isize prev_context_stack_count = p->context_stack.count;
	GB_ASSERT(prev_context_stack_count <= p->context_stack.capacity);
	defer (p->context_stack.count = prev_context_stack_count);
	p->context_stack.count = d.context_stack_count;

	meBlock *b = me_block_create(p, "defer");
	if (last_instr == nullptr || !me_is_instruction_terminator(last_instr->op)) {
		me_emit_jump(p, b);
	}

	me_block_start(p, b);
	if (d.kind == meDefer_Node) {
		me_build_stmt(p, d.stmt);
	} else if (d.kind == meDefer_Proc) {
		me_emit_call(p, d.proc.deferred, slice_from_array(d.proc.result_as_args));
	}
}

void me_emit_defer_stmts(meProcedure *p, meDeferExitKind kind, meBlock *block) {
	isize count = p->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		meDefer const &d = p->defer_stmts[i];

		if (kind == meDeferExit_Default) {
			if (p->scope_index == d.scope_index &&
			    d.scope_index > 0) { // TODO(bill): Which is correct: > 0 or > 1?
				me_build_defer_stmt(p, d);
				array_pop(&p->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == meDeferExit_Return) {
			me_build_defer_stmt(p, d);
		} else if (kind == meDeferExit_Branch) {
			GB_ASSERT(block != nullptr);
			isize lower_limit = block->scope_index;
			if (lower_limit < d.scope_index) {
				me_build_defer_stmt(p, d);
			}
		}
	}
}




meBranchBlocks me_lookup_branch_blocks(meProcedure *p, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_node(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for_array(i, p->branch_blocks) {
		meBranchBlocks *b = &p->branch_blocks[i];
		if (b->label == e->Label.node) {
			return *b;
		}
	}

	GB_PANIC("Unreachable");
	meBranchBlocks empty = {};
	return empty;
}


meTargetList *me_target_list_push(meProcedure *p, Ast *label, meBlock *break_, meBlock *continue_, meBlock *fallthrough_) {
	meTargetList *tl = gb_alloc_item(permanent_allocator(), meTargetList);
	tl->prev = p->target_list;
	tl->break_ = break_;
	tl->continue_ = continue_;
	tl->fallthrough_ = fallthrough_;
	p->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == Ast_Label);

		for_array(i, p->branch_blocks) {
			meBranchBlocks *b = &p->branch_blocks[i];
			GB_ASSERT(b->label != nullptr && label != nullptr);
			GB_ASSERT(b->label->kind == Ast_Label);
			if (b->label == label) {
				b->break_    = break_;
				b->continue_ = continue_;
				return tl;
			}
		}

		GB_PANIC("Unreachable");
	}

	return tl;
}

void me_target_list_pop(meProcedure *p) {
	p->target_list = p->target_list->prev;
}

void me_scope_open(meProcedure *p, Scope *s) {
	p->scope_index += 1;
	array_add(&p->scope_stack, s);

}

void me_scope_close(meProcedure *p, meDeferExitKind kind, meBlock *block, bool pop_stack=true) {
	me_emit_defer_stmts(p, kind, block);
	GB_ASSERT(p->scope_index > 0);

	// NOTE(bill): Remove `context`s made in that scope
	while (p->context_stack.count > 0) {
		meContextData *ctx = &p->context_stack[p->context_stack.count-1];
		if (ctx->scope_index >= p->scope_index) {
			array_pop(&p->context_stack);
		} else {
			break;
		}

	}

	p->scope_index -= 1;
	array_pop(&p->scope_stack);
}

void me_build_stmt_list(meProcedure *p, Slice<Ast *> const &stmts) {
	for_array(i, stmts) {
		Ast *stmt = stmts[i];
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			// me_build_constant_value_decl(p, vd);
		case_end;
		case_ast_node(fb, ForeignBlockDecl, stmt);
			ast_node(block, BlockStmt, fb->body);
			me_build_stmt_list(p, block->stmts);
		case_end;
		}
	}
	for_array(i, stmts) {
		me_build_stmt(p, stmts[i]);
	}
}

void me_build_when_stmt(meProcedure *p, AstWhenStmt *ws) {
	TypeAndValue tv = type_and_value_of_expr(ws->cond);
	GB_ASSERT(is_type_boolean(tv.type));
	GB_ASSERT(tv.value.kind == ExactValue_Bool);
	if (tv.value.value_bool) {
		me_build_stmt_list(p, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			me_build_stmt_list(p, ws->else_stmt->BlockStmt.stmts);
			break;
		case Ast_WhenStmt:
			me_build_when_stmt(p, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid 'else' statement in 'when' statement");
			break;
		}
	}
}



void me_build_stmt(meProcedure *p, Ast *node) {
	Ast *prev_stmt = p->curr_stmt;
	defer (p->curr_stmt = prev_stmt);
	p->curr_stmt = node;

	if (me_is_last_instruction_terminator(p->curr_block)) {
		return;
	}

	u16 prev_state_flags = p->state_flags;
	defer (p->state_flags = prev_state_flags);

	if (node->state_flags != 0) {
		u16 in = node->state_flags;
		u16 out = p->state_flags;

		if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		} else if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		}
		if (in & StateFlag_no_type_assert) {
			out |= StateFlag_no_type_assert;
			out &= ~StateFlag_type_assert;
		} else if (in & StateFlag_type_assert) {
			out |= StateFlag_type_assert;
			out &= ~StateFlag_no_type_assert;
		}

		p->state_flags = out;
	}

	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		me_build_when_stmt(p, ws);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		meBlock *done = nullptr;
		if (bs->label != nullptr) {
			done = me_block_create(p, "block.done");
			meTargetList *tl = me_target_list_push(p, bs->label, done, nullptr, nullptr);
			tl->is_block = true;
		}

		me_scope_open(p, bs->scope);
		me_build_stmt_list(p, bs->stmts);
		me_scope_close(p, meDeferExit_Default, nullptr);

		if (done != nullptr) {
			me_emit_jump(p, done);
			me_block_start(p, done);
		}

		if (bs->label != nullptr) {
			me_target_list_pop(p);
		}
	case_end;

	case_ast_node(bs, BranchStmt, node);
		meBlock *block = nullptr;

		if (bs->label != nullptr) {
			meBranchBlocks bb = me_lookup_branch_blocks(p, bs->label);
			switch (bs->token.kind) {
			case Token_break:    block = bb.break_;    break;
			case Token_continue: block = bb.continue_; break;
			case Token_fallthrough:
				GB_PANIC("fallthrough cannot have a label");
				break;
			}
		} else {
			for (meTargetList *t = p->target_list; t != nullptr && block == nullptr; t = t->prev) {
				if (t->is_block) {
					continue;
				}

				switch (bs->token.kind) {
				case Token_break:       block = t->break_;       break;
				case Token_continue:    block = t->continue_;    break;
				case Token_fallthrough: block = t->fallthrough_; break;
				}
			}
		}
		if (block != nullptr) {
			me_emit_defer_stmts(p, meDeferExit_Branch, block);
		}
		me_emit_jump(p, block);
		me_block_start(p, me_block_create(p, "unreachable"));
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			return;
		}

		// TODO: ValueDecl

	case_end;
	}
}