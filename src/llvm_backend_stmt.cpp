lbCopyElisionHint lb_set_copy_elision_hint(lbProcedure *p, lbAddr const &addr, Ast *ast) {
	lbCopyElisionHint prev = p->copy_elision_hint;
	p->copy_elision_hint.used = false;
	p->copy_elision_hint.ptr = {};
	p->copy_elision_hint.ast = nullptr;
	#if 0
	if (addr.kind == lbAddr_Default && addr.addr.value != nullptr) {
		p->copy_elision_hint.ptr = lb_addr_get_ptr(p, addr);
		p->copy_elision_hint.ast = unparen_expr(ast);
	}
	#endif
	return prev;
}

void lb_reset_copy_elision_hint(lbProcedure *p, lbCopyElisionHint prev_hint) {
	p->copy_elision_hint = prev_hint;
}


lbValue lb_consume_copy_elision_hint(lbProcedure *p) {
	lbValue return_ptr = p->copy_elision_hint.ptr;
	p->copy_elision_hint.used = true;
	p->copy_elision_hint.ptr = {};
	p->copy_elision_hint.ast = nullptr;
	return return_ptr;
}


void lb_build_constant_value_decl(lbProcedure *p, AstValueDecl *vd) {
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

		lb_set_nested_type_name_ir_mangled_name(e, p);
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
					lb_build_nested_proc(p, &d->proc_lit->ProcLit, e);
				}
			} else {
				lb_build_nested_proc(p, pl, e);
			}
		} else {

			// FFI - Foreign function interace
			String original_name = e->token.string;
			String name = original_name;

			if (e->Procedure.is_foreign) {
				lb_add_foreign_library_path(p->module, e->Procedure.foreign_library);
			}

			if (e->Procedure.link_name.len > 0) {
				name = e->Procedure.link_name;
			}

			lbValue *prev_value = string_map_get(&p->module->members, name);
			if (prev_value != nullptr) {
				// NOTE(bill): Don't do mutliple declarations in the IR
				return;
			}

			e->Procedure.link_name = name;

			lbProcedure *nested_proc = lb_create_procedure(p->module, e);

			lbValue value = {};
			value.value = nested_proc->value;
			value.type = nested_proc->type;

			array_add(&p->module->procedures_to_generate, nested_proc);
			array_add(&p->children, nested_proc);
			string_map_set(&p->module->members, name, value);
		}
	}
}


void lb_build_stmt_list(lbProcedure *p, Slice<Ast *> const &stmts) {
	for_array(i, stmts) {
		Ast *stmt = stmts[i];
		switch (stmt->kind) {
		case_ast_node(vd, ValueDecl, stmt);
			lb_build_constant_value_decl(p, vd);
		case_end;
		case_ast_node(fb, ForeignBlockDecl, stmt);
			ast_node(block, BlockStmt, fb->body);
			lb_build_stmt_list(p, block->stmts);
		case_end;
		}
	}
	for_array(i, stmts) {
		lb_build_stmt(p, stmts[i]);
	}
}



lbBranchBlocks lb_lookup_branch_blocks(lbProcedure *p, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_node(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for_array(i, p->branch_blocks) {
		lbBranchBlocks *b = &p->branch_blocks[i];
		if (b->label == e->Label.node) {
			return *b;
		}
	}

	GB_PANIC("Unreachable");
	lbBranchBlocks empty = {};
	return empty;
}


lbTargetList *lb_push_target_list(lbProcedure *p, Ast *label, lbBlock *break_, lbBlock *continue_, lbBlock *fallthrough_) {
	lbTargetList *tl = gb_alloc_item(permanent_allocator(), lbTargetList);
	tl->prev = p->target_list;
	tl->break_ = break_;
	tl->continue_ = continue_;
	tl->fallthrough_ = fallthrough_;
	p->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == Ast_Label);

		for_array(i, p->branch_blocks) {
			lbBranchBlocks *b = &p->branch_blocks[i];
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

void lb_pop_target_list(lbProcedure *p) {
	p->target_list = p->target_list->prev;
}

void lb_open_scope(lbProcedure *p, Scope *s) {
	lbModule *m = p->module;
	if (m->debug_builder) {
		LLVMMetadataRef curr_metadata = lb_get_llvm_metadata(m, s);
		if (s != nullptr && s->node != nullptr && curr_metadata == nullptr) {
			Token token = ast_token(s->node);
			unsigned line = cast(unsigned)token.pos.line;
			unsigned column = cast(unsigned)token.pos.column;

			LLVMMetadataRef file = nullptr;
			AstFile *ast_file = s->node->file();
			if (ast_file != nullptr) {
				file = lb_get_llvm_metadata(m, ast_file);
			}
			LLVMMetadataRef scope = nullptr;
			if (p->scope_stack.count > 0) {
				scope = lb_get_llvm_metadata(m, p->scope_stack[p->scope_stack.count-1]);
			}
			if (scope == nullptr) {
				scope = lb_get_llvm_metadata(m, p);
			}
			GB_ASSERT_MSG(scope != nullptr, "%.*s", LIT(p->name));

			if (m->debug_builder) {
				LLVMMetadataRef res = LLVMDIBuilderCreateLexicalBlock(m->debug_builder, scope,
					file, line, column
				);
				lb_set_llvm_metadata(m, s, res);
			}
		}
	}

	p->scope_index += 1;
	array_add(&p->scope_stack, s);

}

void lb_close_scope(lbProcedure *p, lbDeferExitKind kind, lbBlock *block, bool pop_stack=true) {
	lb_emit_defer_stmts(p, kind, block);
	GB_ASSERT(p->scope_index > 0);

	// NOTE(bill): Remove `context`s made in that scope
	while (p->context_stack.count > 0) {
		lbContextData *ctx = &p->context_stack[p->context_stack.count-1];
		if (ctx->scope_index >= p->scope_index) {
			array_pop(&p->context_stack);
		} else {
			break;
		}

	}

	p->scope_index -= 1;
	array_pop(&p->scope_stack);
}

void lb_build_when_stmt(lbProcedure *p, AstWhenStmt *ws) {
	TypeAndValue tv = type_and_value_of_expr(ws->cond);
	GB_ASSERT(is_type_boolean(tv.type));
	GB_ASSERT(tv.value.kind == ExactValue_Bool);
	if (tv.value.value_bool) {
		lb_build_stmt_list(p, ws->body->BlockStmt.stmts);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			lb_build_stmt_list(p, ws->else_stmt->BlockStmt.stmts);
			break;
		case Ast_WhenStmt:
			lb_build_when_stmt(p, &ws->else_stmt->WhenStmt);
			break;
		default:
			GB_PANIC("Invalid 'else' statement in 'when' statement");
			break;
		}
	}
}



void lb_build_range_indexed(lbProcedure *p, lbValue expr, Type *val_type, lbValue count_ptr,
                            lbValue *val_, lbValue *idx_, lbBlock **loop_, lbBlock **done_) {
	lbModule *m = p->module;

	lbValue count = {};
	Type *expr_type = base_type(type_deref(expr.type));
	switch (expr_type->kind) {
	case Type_Array:
		count = lb_const_int(m, t_int, expr_type->Array.count);
		break;
	}

	lbValue val = {};
	lbValue idx = {};
	lbBlock *loop = nullptr;
	lbBlock *done = nullptr;
	lbBlock *body = nullptr;


	lbAddr index = lb_add_local_generated(p, t_int, false);
	lb_addr_store(p, index, lb_const_int(m, t_int, cast(u64)-1));

	loop = lb_create_block(p, "for.index.loop");
	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	lbValue incr = lb_emit_arith(p, Token_Add, lb_addr_load(p, index), lb_const_int(m, t_int, 1), t_int);
	lb_addr_store(p, index, incr);

	body = lb_create_block(p, "for.index.body");
	done = lb_create_block(p, "for.index.done");
	if (count.value == nullptr) {
		GB_ASSERT(count_ptr.value != nullptr);
		count = lb_emit_load(p, count_ptr);
	}
	lbValue cond = lb_emit_comp(p, Token_Lt, incr, count);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);

	idx = lb_addr_load(p, index);
	switch (expr_type->kind) {
	case Type_Array: {
		if (val_type != nullptr) {
			val = lb_emit_load(p, lb_emit_array_ep(p, expr, idx));
		}
		break;
	}
	case Type_EnumeratedArray: {
		if (val_type != nullptr) {
			val = lb_emit_load(p, lb_emit_array_ep(p, expr, idx));
			// NOTE(bill): Override the idx value for the enumeration
			Type *index_type = expr_type->EnumeratedArray.index;
			if (compare_exact_values(Token_NotEq, *expr_type->EnumeratedArray.min_value, exact_value_u64(0))) {
				idx = lb_emit_arith(p, Token_Add, idx, lb_const_value(m, index_type, *expr_type->EnumeratedArray.min_value), index_type);
			}
		}
		break;
	}
	case Type_Slice: {
		if (val_type != nullptr) {
			lbValue elem = lb_slice_elem(p, expr);
			val = lb_emit_load(p, lb_emit_ptr_offset(p, elem, idx));
		}
		break;
	}
	case Type_DynamicArray: {
		if (val_type != nullptr) {
			lbValue elem = lb_emit_struct_ep(p, expr, 0);
			elem = lb_emit_load(p, elem);
			val = lb_emit_load(p, lb_emit_ptr_offset(p, elem, idx));
		}
		break;
	}
	case Type_Map: {
		lbValue entries = lb_map_entries_ptr(p, expr);
		lbValue elem = lb_emit_struct_ep(p, entries, 0);
		elem = lb_emit_load(p, elem);
		lbValue entry = lb_emit_ptr_offset(p, elem, idx);		
		idx = lb_emit_load(p, lb_emit_struct_ep(p, entry, 2));
		val = lb_emit_load(p, lb_emit_struct_ep(p, entry, 3));

		break;
	}
	case Type_Struct: {
		GB_ASSERT(is_type_soa_struct(expr_type));
		break;
	}

	default:
		GB_PANIC("Cannot do range_indexed of %s", type_to_string(expr_type));
		break;
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}


void lb_build_range_string(lbProcedure *p, lbValue expr, Type *val_type,
                            lbValue *val_, lbValue *idx_, lbBlock **loop_, lbBlock **done_) {
	lbModule *m = p->module;
	lbValue count = lb_const_int(m, t_int, 0);
	Type *expr_type = base_type(expr.type);
	switch (expr_type->kind) {
	case Type_Basic:
		count = lb_string_len(p, expr);
		break;
	default:
		GB_PANIC("Cannot do range_string of %s", type_to_string(expr_type));
		break;
	}

	lbValue val = {};
	lbValue idx = {};
	lbBlock *loop = nullptr;
	lbBlock *done = nullptr;
	lbBlock *body = nullptr;


	lbAddr offset_ = lb_add_local_generated(p, t_int, false);
	lb_addr_store(p, offset_, lb_const_int(m, t_int, 0));

	loop = lb_create_block(p, "for.string.loop");
	lb_emit_jump(p, loop);
	lb_start_block(p, loop);



	body = lb_create_block(p, "for.string.body");
	done = lb_create_block(p, "for.string.done");

	lbValue offset = lb_addr_load(p, offset_);
	lbValue cond = lb_emit_comp(p, Token_Lt, offset, count);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);


	lbValue str_elem = lb_emit_ptr_offset(p, lb_string_elem(p, expr), offset);
	lbValue str_len  = lb_emit_arith(p, Token_Sub, count, offset, t_int);
	auto args = array_make<lbValue>(permanent_allocator(), 1);
	args[0] = lb_emit_string(p, str_elem, str_len);
	lbValue rune_and_len = lb_emit_runtime_call(p, "string_decode_rune", args);
	lbValue len  = lb_emit_struct_ev(p, rune_and_len, 1);
	lb_addr_store(p, offset_, lb_emit_arith(p, Token_Add, offset, len, t_int));


	idx = offset;
	if (val_type != nullptr) {
		val = lb_emit_struct_ev(p, rune_and_len, 0);
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}


void lb_build_range_interval(lbProcedure *p, AstBinaryExpr *node,
                             AstRangeStmt *rs, Scope *scope) {
	bool ADD_EXTRA_WRAPPING_CHECK = true;

	lbModule *m = p->module;

	lb_open_scope(p, scope);

	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (rs->vals.count > 0 && rs->vals[0] != nullptr && !is_blank_ident(rs->vals[0])) {
		val0_type = type_of_expr(rs->vals[0]);
	}
	if (rs->vals.count > 1 && rs->vals[1] != nullptr && !is_blank_ident(rs->vals[1])) {
		val1_type = type_of_expr(rs->vals[1]);
	}

	TokenKind op = Token_Lt;
	switch (node->op.kind) {
	case Token_Ellipsis:  op = Token_LtEq; break;
	case Token_RangeFull: op = Token_LtEq; break;
	case Token_RangeHalf: op = Token_Lt;  break;
	default: GB_PANIC("Invalid interval operator"); break;
	}

	lbValue lower = lb_build_expr(p, node->left);
	lbValue upper = {}; // initialized each time in the loop

	lbAddr value;
	if (val0_type != nullptr) {
		Entity *e = entity_of_node(rs->vals[0]);
		value = lb_add_local(p, val0_type, e, false);
	} else {
		value = lb_add_local_generated(p, lower.type, false);
	}
	lb_addr_store(p, value, lower);

	lbAddr index;
	if (val1_type != nullptr) {
		Entity *e = entity_of_node(rs->vals[1]);
		index = lb_add_local(p, val1_type, e, false);
	} else {
		index = lb_add_local_generated(p, t_int, false);
	}
	lb_addr_store(p, index, lb_const_int(m, t_int, 0));

	lbBlock *loop = lb_create_block(p, "for.interval.loop");
	lbBlock *body = lb_create_block(p, "for.interval.body");
	lbBlock *done = lb_create_block(p, "for.interval.done");

	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	upper = lb_build_expr(p, node->right);
	lbValue curr_value = lb_addr_load(p, value);
	lbValue cond = lb_emit_comp(p, op, curr_value, upper);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);

	lbValue val = lb_addr_load(p, value);
	lbValue idx = lb_addr_load(p, index);
	if (val0_type) lb_store_range_stmt_val(p, rs->vals[0], val);
	if (val1_type) lb_store_range_stmt_val(p, rs->vals[1], idx);

	{
		// NOTE: this check block will most likely be optimized out, and is here
		// to make this code easier to read
		lbBlock *check = nullptr;
		lbBlock *post = lb_create_block(p, "for.interval.post");

		lbBlock *continue_block = post;

		if (ADD_EXTRA_WRAPPING_CHECK &&
		    op == Token_LtEq) {
			check = lb_create_block(p, "for.interval.check");
			continue_block = check;
		}

		lb_push_target_list(p, rs->label, done, continue_block, nullptr);

		lb_build_stmt(p, rs->body);

		lb_close_scope(p, lbDeferExit_Default, nullptr);
		lb_pop_target_list(p);

		if (check != nullptr) {
			lb_emit_jump(p, check);
			lb_start_block(p, check);

			lbValue check_cond = lb_emit_comp(p, Token_NotEq, curr_value, upper);
			lb_emit_if(p, check_cond, post, done);
		} else {
			lb_emit_jump(p, post);
		}

		lb_start_block(p, post);
		lb_emit_increment(p, value.addr);
		lb_emit_increment(p, index.addr);
		lb_emit_jump(p, loop);
	}

	lb_start_block(p, done);
}

void lb_build_range_enum(lbProcedure *p, Type *enum_type, Type *val_type, lbValue *val_, lbValue *idx_, lbBlock **loop_, lbBlock **done_) {
	lbModule *m = p->module;

	Type *t = enum_type;
	GB_ASSERT(is_type_enum(t));
	t = base_type(t);
	Type *core_elem = core_type(t);
	GB_ASSERT(t->kind == Type_Enum);
	i64 enum_count = t->Enum.fields.count;
	lbValue max_count = lb_const_int(m, t_int, enum_count);

	lbValue ti          = lb_type_info(m, t);
	lbValue variant     = lb_emit_struct_ep(p, ti, 4);
	lbValue eti_ptr     = lb_emit_conv(p, variant, t_type_info_enum_ptr);
	lbValue values      = lb_emit_load(p, lb_emit_struct_ep(p, eti_ptr, 2));
	lbValue values_data = lb_slice_elem(p, values);

	lbAddr offset_ = lb_add_local_generated(p, t_int, false);
	lb_addr_store(p, offset_, lb_const_int(m, t_int, 0));

	lbBlock *loop = lb_create_block(p, "for.enum.loop");
	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	lbBlock *body = lb_create_block(p, "for.enum.body");
	lbBlock *done = lb_create_block(p, "for.enum.done");

	lbValue offset = lb_addr_load(p, offset_);
	lbValue cond = lb_emit_comp(p, Token_Lt, offset, max_count);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);

	lbValue val_ptr = lb_emit_ptr_offset(p, values_data, offset);
	lb_emit_increment(p, offset_.addr);

	lbValue val = {};
	if (val_type != nullptr) {
		GB_ASSERT(are_types_identical(enum_type, val_type));

		if (is_type_integer(core_elem)) {
			lbValue i = lb_emit_load(p, lb_emit_conv(p, val_ptr, t_i64_ptr));
			val = lb_emit_conv(p, i, t);
		} else {
			GB_PANIC("TODO(bill): enum core type %s", type_to_string(core_elem));
		}
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = offset;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}

void lb_build_range_tuple(lbProcedure *p, Ast *expr, Type *val0_type, Type *val1_type,
                          lbValue *val0_, lbValue *val1_, lbBlock **loop_, lbBlock **done_) {
	lbBlock *loop = lb_create_block(p, "for.tuple.loop");
	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	lbBlock *body = lb_create_block(p, "for.tuple.body");
	lbBlock *done = lb_create_block(p, "for.tuple.done");

	lbValue tuple_value = lb_build_expr(p, expr);
	Type *tuple = tuple_value.type;
	GB_ASSERT(tuple->kind == Type_Tuple);
	i32 tuple_count = cast(i32)tuple->Tuple.variables.count;
	i32 cond_index = tuple_count-1;

	lbValue cond = lb_emit_struct_ev(p, tuple_value, cond_index);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);


	if (val0_) *val0_ = lb_emit_struct_ev(p, tuple_value, 0);
	if (val1_) *val1_ = lb_emit_struct_ev(p, tuple_value, 1);
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}

void lb_build_range_stmt_struct_soa(lbProcedure *p, AstRangeStmt *rs, Scope *scope) {
	Ast *expr = unparen_expr(rs->expr);
	TypeAndValue tav = type_and_value_of_expr(expr);

	lbBlock *loop = nullptr;
	lbBlock *body = nullptr;
	lbBlock *done = nullptr;

	lb_open_scope(p, scope);


	Type *val_types[2] = {};
	if (rs->vals.count > 0 && rs->vals[0] != nullptr && !is_blank_ident(rs->vals[0])) {
		val_types[0] = type_of_expr(rs->vals[0]);
	}
	if (rs->vals.count > 1 && rs->vals[1] != nullptr && !is_blank_ident(rs->vals[1])) {
		val_types[1] = type_of_expr(rs->vals[1]);
	}



	lbAddr array = lb_build_addr(p, expr);
	if (is_type_pointer(lb_addr_type(array))) {
		array = lb_addr(lb_addr_load(p, array));
	}
	lbValue count = lb_soa_struct_len(p, lb_addr_load(p, array));


	lbAddr index = lb_add_local_generated(p, t_int, false);
	lb_addr_store(p, index, lb_const_int(p->module, t_int, cast(u64)-1));

	loop = lb_create_block(p, "for.soa.loop");
	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	lbValue incr = lb_emit_arith(p, Token_Add, lb_addr_load(p, index), lb_const_int(p->module, t_int, 1), t_int);
	lb_addr_store(p, index, incr);

	body = lb_create_block(p, "for.soa.body");
	done = lb_create_block(p, "for.soa.done");

	lbValue cond = lb_emit_comp(p, Token_Lt, incr, count);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);


	if (val_types[0]) {
		Entity *e = entity_of_node(rs->vals[0]);
		if (e != nullptr) {
			lbAddr soa_val = lb_addr_soa_variable(array.addr, lb_addr_load(p, index), nullptr);
			map_set(&p->module->soa_values, e, soa_val);
		}
	}
	if (val_types[1]) {
		lb_store_range_stmt_val(p, rs->vals[1], lb_addr_load(p, index));
	}


	lb_push_target_list(p, rs->label, done, loop, nullptr);

	lb_build_stmt(p, rs->body);

	lb_close_scope(p, lbDeferExit_Default, nullptr);
	lb_pop_target_list(p);
	lb_emit_jump(p, loop);
	lb_start_block(p, done);

}

void lb_build_range_stmt(lbProcedure *p, AstRangeStmt *rs, Scope *scope) {
	Ast *expr = unparen_expr(rs->expr);

	if (is_ast_range(expr)) {
		lb_build_range_interval(p, &expr->BinaryExpr, rs, scope);
		return;
	}

	Type *expr_type = type_of_expr(expr);
	if (expr_type != nullptr) {
		Type *et = base_type(type_deref(expr_type));
	 	if (is_type_soa_struct(et)) {
			lb_build_range_stmt_struct_soa(p, rs, scope);
			return;
		}
	}

	lb_open_scope(p, scope);

	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (rs->vals.count > 0 && rs->vals[0] != nullptr && !is_blank_ident(rs->vals[0])) {
		val0_type = type_of_expr(rs->vals[0]);
	}
	if (rs->vals.count > 1 && rs->vals[1] != nullptr && !is_blank_ident(rs->vals[1])) {
		val1_type = type_of_expr(rs->vals[1]);
	}

	if (val0_type != nullptr) {
		Entity *e = entity_of_node(rs->vals[0]);
		lb_add_local(p, e->type, e, true);
	}
	if (val1_type != nullptr) {
		Entity *e = entity_of_node(rs->vals[1]);
		lb_add_local(p, e->type, e, true);
	}

	lbValue val = {};
	lbValue key = {};
	lbBlock *loop = nullptr;
	lbBlock *done = nullptr;
	bool is_map = false;
	TypeAndValue tav = type_and_value_of_expr(expr);

	if (tav.mode == Addressing_Type) {
		lb_build_range_enum(p, type_deref(tav.type), val0_type, &val, &key, &loop, &done);
	} else {
		Type *expr_type = type_of_expr(expr);
		Type *et = base_type(type_deref(expr_type));
		switch (et->kind) {
		case Type_Map: {
			is_map = true;
			lbValue map = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(map.type))) {
				map = lb_emit_load(p, map);
			}
			lbValue entries_ptr = lb_map_entries_ptr(p, map);
			lbValue count_ptr = lb_emit_struct_ep(p, entries_ptr, 1);
			lb_build_range_indexed(p, map, val1_type, count_ptr, &val, &key, &loop, &done);
			break;
		}
		case Type_Array: {
			lbValue array = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = lb_emit_load(p, array);
			}
			lbAddr count_ptr = lb_add_local_generated(p, t_int, false);
			lb_addr_store(p, count_ptr, lb_const_int(p->module, t_int, et->Array.count));
			lb_build_range_indexed(p, array, val0_type, count_ptr.addr, &val, &key, &loop, &done);
			break;
		}
		case Type_EnumeratedArray: {
			lbValue array = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = lb_emit_load(p, array);
			}
			lbAddr count_ptr = lb_add_local_generated(p, t_int, false);
			lb_addr_store(p, count_ptr, lb_const_int(p->module, t_int, et->EnumeratedArray.count));
			lb_build_range_indexed(p, array, val0_type, count_ptr.addr, &val, &key, &loop, &done);
			break;
		}
		case Type_DynamicArray: {
			lbValue count_ptr = {};
			lbValue array = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = lb_emit_load(p, array);
			}
			count_ptr = lb_emit_struct_ep(p, array, 1);
			lb_build_range_indexed(p, array, val0_type, count_ptr, &val, &key, &loop, &done);
			break;
		}
		case Type_Slice: {
			lbValue count_ptr = {};
			lbValue slice = lb_build_expr(p, expr);
			if (is_type_pointer(slice.type)) {
				count_ptr = lb_emit_struct_ep(p, slice, 1);
				slice = lb_emit_load(p, slice);
			} else {
				count_ptr = lb_add_local_generated(p, t_int, false).addr;
				lb_emit_store(p, count_ptr, lb_slice_len(p, slice));
			}
			lb_build_range_indexed(p, slice, val0_type, count_ptr, &val, &key, &loop, &done);
			break;
		}
		case Type_Basic: {
			lbValue string = lb_build_expr(p, expr);
			if (is_type_pointer(string.type)) {
				string = lb_emit_load(p, string);
			}
			if (is_type_untyped(expr_type)) {
				lbAddr s = lb_add_local_generated(p, default_type(string.type), false);
				lb_addr_store(p, s, string);
				string = lb_addr_load(p, s);
			}
			Type *t = base_type(string.type);
			GB_ASSERT(!is_type_cstring(t));
			lb_build_range_string(p, string, val0_type, &val, &key, &loop, &done);
			break;
		}
		case Type_Tuple:
			lb_build_range_tuple(p, expr, val0_type, val1_type, &val, &key, &loop, &done);
			break;
		default:
			GB_PANIC("Cannot range over %s", type_to_string(expr_type));
			break;
		}
	}


	if (is_map) {
		if (val0_type) lb_store_range_stmt_val(p, rs->vals[0], key);
		if (val1_type) lb_store_range_stmt_val(p, rs->vals[1], val);
	} else {
		if (val0_type) lb_store_range_stmt_val(p, rs->vals[0], val);
		if (val1_type) lb_store_range_stmt_val(p, rs->vals[1], key);
	}

	lb_push_target_list(p, rs->label, done, loop, nullptr);

	lb_build_stmt(p, rs->body);

	lb_close_scope(p, lbDeferExit_Default, nullptr);
	lb_pop_target_list(p);
	lb_emit_jump(p, loop);
	lb_start_block(p, done);
}

void lb_build_unroll_range_stmt(lbProcedure *p, AstUnrollRangeStmt *rs, Scope *scope) {
	lbModule *m = p->module;

	lb_open_scope(p, scope); // Open scope here

	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (rs->val0 != nullptr && !is_blank_ident(rs->val0)) {
		val0_type = type_of_expr(rs->val0);
	}
	if (rs->val1 != nullptr && !is_blank_ident(rs->val1)) {
		val1_type = type_of_expr(rs->val1);
	}

	if (val0_type != nullptr) {
		Entity *e = entity_of_node(rs->val0);
		lb_add_local(p, e->type, e, true);
	}
	if (val1_type != nullptr) {
		Entity *e = entity_of_node(rs->val1);
		lb_add_local(p, e->type, e, true);
	}

	lbValue val = {};
	lbValue key = {};
	Ast *expr = unparen_expr(rs->expr);

	TypeAndValue tav = type_and_value_of_expr(expr);

	if (is_ast_range(expr)) {

		lbAddr val0_addr = {};
		lbAddr val1_addr = {};
		if (val0_type) val0_addr = lb_build_addr(p, rs->val0);
		if (val1_type) val1_addr = lb_build_addr(p, rs->val1);

		TokenKind op = expr->BinaryExpr.op.kind;
		Ast *start_expr = expr->BinaryExpr.left;
		Ast *end_expr   = expr->BinaryExpr.right;
		GB_ASSERT(start_expr->tav.mode == Addressing_Constant);
		GB_ASSERT(end_expr->tav.mode == Addressing_Constant);

		ExactValue start = start_expr->tav.value;
		ExactValue end   = end_expr->tav.value;
		if (op != Token_RangeHalf) { // .. [start, end] (or ..=)
			ExactValue index = exact_value_i64(0);
			for (ExactValue val = start;
			     compare_exact_values(Token_LtEq, val, end);
			     val = exact_value_increment_one(val), index = exact_value_increment_one(index)) {

				if (val0_type) lb_addr_store(p, val0_addr, lb_const_value(m, val0_type, val));
				if (val1_type) lb_addr_store(p, val1_addr, lb_const_value(m, val1_type, index));

				lb_build_stmt(p, rs->body);
			}
		} else { // ..< [start, end)
			ExactValue index = exact_value_i64(0);
			for (ExactValue val = start;
			     compare_exact_values(Token_Lt, val, end);
			     val = exact_value_increment_one(val), index = exact_value_increment_one(index)) {

				if (val0_type) lb_addr_store(p, val0_addr, lb_const_value(m, val0_type, val));
				if (val1_type) lb_addr_store(p, val1_addr, lb_const_value(m, val1_type, index));

				lb_build_stmt(p, rs->body);
			}
		}


	} else if (tav.mode == Addressing_Type) {
		GB_ASSERT(is_type_enum(type_deref(tav.type)));
		Type *et = type_deref(tav.type);
		Type *bet = base_type(et);

		lbAddr val0_addr = {};
		lbAddr val1_addr = {};
		if (val0_type) val0_addr = lb_build_addr(p, rs->val0);
		if (val1_type) val1_addr = lb_build_addr(p, rs->val1);

		for_array(i, bet->Enum.fields) {
			Entity *field = bet->Enum.fields[i];
			GB_ASSERT(field->kind == Entity_Constant);
			if (val0_type) lb_addr_store(p, val0_addr, lb_const_value(m, val0_type, field->Constant.value));
			if (val1_type) lb_addr_store(p, val1_addr, lb_const_value(m, val1_type, exact_value_i64(i)));

			lb_build_stmt(p, rs->body);
		}
	} else {
		lbAddr val0_addr = {};
		lbAddr val1_addr = {};
		if (val0_type) val0_addr = lb_build_addr(p, rs->val0);
		if (val1_type) val1_addr = lb_build_addr(p, rs->val1);

		GB_ASSERT(expr->tav.mode == Addressing_Constant);

		Type *t = base_type(expr->tav.type);


		switch (t->kind) {
		case Type_Basic:
			GB_ASSERT(is_type_string(t));
			{
				ExactValue value = expr->tav.value;
				GB_ASSERT(value.kind == ExactValue_String);
				String str = value.value_string;
				Rune codepoint = 0;
				isize offset = 0;
				do {
					isize width = utf8_decode(str.text+offset, str.len-offset, &codepoint);
					if (val0_type) lb_addr_store(p, val0_addr, lb_const_value(m, val0_type, exact_value_i64(codepoint)));
					if (val1_type) lb_addr_store(p, val1_addr, lb_const_value(m, val1_type, exact_value_i64(offset)));
					lb_build_stmt(p, rs->body);

					offset += width;
				} while (offset < str.len);
			}
			break;
		case Type_Array:
			if (t->Array.count > 0) {
				lbValue val = lb_build_expr(p, expr);
				lbValue val_addr = lb_address_from_load_or_generate_local(p, val);

				for (i64 i = 0; i < t->Array.count; i++) {
					if (val0_type) {
						// NOTE(bill): Due to weird legacy issues in LLVM, this needs to be an i32
						lbValue elem = lb_emit_array_epi(p, val_addr, cast(i32)i);
						lb_addr_store(p, val0_addr, lb_emit_load(p, elem));
					}
					if (val1_type) lb_addr_store(p, val1_addr, lb_const_value(m, val1_type, exact_value_i64(i)));

					lb_build_stmt(p, rs->body);
				}

			}
			break;
		case Type_EnumeratedArray:
			if (t->EnumeratedArray.count > 0) {
				lbValue val = lb_build_expr(p, expr);
				lbValue val_addr = lb_address_from_load_or_generate_local(p, val);

				for (i64 i = 0; i < t->EnumeratedArray.count; i++) {
					if (val0_type) {
						// NOTE(bill): Due to weird legacy issues in LLVM, this needs to be an i32
						lbValue elem = lb_emit_array_epi(p, val_addr, cast(i32)i);
						lb_addr_store(p, val0_addr, lb_emit_load(p, elem));
					}
					if (val1_type) {
						ExactValue idx = exact_value_add(exact_value_i64(i), *t->EnumeratedArray.min_value);
						lb_addr_store(p, val1_addr, lb_const_value(m, val1_type, idx));
					}

					lb_build_stmt(p, rs->body);
				}

			}
			break;
		default:
			GB_PANIC("Invalid '#unroll for' type");
			break;
		}
	}


	lb_close_scope(p, lbDeferExit_Default, nullptr);
}

bool lb_switch_stmt_can_be_trivial_jump_table(AstSwitchStmt *ss, bool *default_found_) {
	if (ss->tag == nullptr) {
		return false;
	}
	bool is_typeid = false;
	TypeAndValue tv = type_and_value_of_expr(ss->tag);
	if (is_type_integer(core_type(tv.type))) {
		// okay
	} else if (is_type_typeid(tv.type)) {
		// okay
		is_typeid = true;
	} else {
		return false;
	}

	ast_node(body, BlockStmt, ss->body);
	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		if (cc->list.count == 0) {
			if (default_found_) *default_found_ = true;
			continue;
		}

		for_array(j, cc->list) {
			Ast *expr = unparen_expr(cc->list[j]);
			if (is_ast_range(expr)) {
				return false;
			}
			if (expr->tav.mode == Addressing_Type) {
				GB_ASSERT(is_typeid);
				continue;
			}
			tv = type_and_value_of_expr(expr);
			if (tv.mode != Addressing_Constant) {
				return false;
			}
			if (!is_type_integer(core_type(tv.type))) {
				return false;
			}
		}

	}

	return true;
}


void lb_build_switch_stmt(lbProcedure *p, AstSwitchStmt *ss, Scope *scope) {
	lb_open_scope(p, scope);

	if (ss->init != nullptr) {
		lb_build_stmt(p, ss->init);
	}
	lbValue tag = lb_const_bool(p->module, t_llvm_bool, true);
	if (ss->tag != nullptr) {
		tag = lb_build_expr(p, ss->tag);
	}
	lbBlock *done = lb_create_block(p, "switch.done"); // NOTE(bill): Append later

	ast_node(body, BlockStmt, ss->body);

	isize case_count = body->stmts.count;
	Slice<Ast *> default_stmts = {};
	lbBlock *default_fall = nullptr;
	lbBlock *default_block = nullptr;
	lbBlock *fall = nullptr;

	bool default_found = false;
	bool is_trivial = lb_switch_stmt_can_be_trivial_jump_table(ss, &default_found);

	auto body_blocks = slice_make<lbBlock *>(permanent_allocator(), body->stmts.count);
	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		body_blocks[i] = lb_create_block(p, cc->list.count == 0 ? "switch.default.body" : "switch.case.body");
		if (cc->list.count == 0) {
			default_block = body_blocks[i];
		}
	}


	LLVMValueRef switch_instr = nullptr;
	if (is_trivial) {
		isize num_cases = 0;
		for_array(i, body->stmts) {
			Ast *clause = body->stmts[i];
			ast_node(cc, CaseClause, clause);
			num_cases += cc->list.count;
		}

		LLVMBasicBlockRef end_block = done->block;
		if (default_block) {
			end_block = default_block->block;
		}

		switch_instr = LLVMBuildSwitch(p->builder, tag.value, end_block, cast(unsigned)num_cases);
	}


	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);

		lbBlock *body = body_blocks[i];
		fall = done;
		if (i+1 < case_count) {
			fall = body_blocks[i+1];
		}

		if (cc->list.count == 0) {
			// default case
			default_stmts = cc->stmts;
			default_fall  = fall;
			if (switch_instr == nullptr) {
				default_block = body;
			} else {
				GB_ASSERT(default_block != nullptr);
			}
			continue;
		}

		lbBlock *next_cond = nullptr;
		for_array(j, cc->list) {
			Ast *expr = unparen_expr(cc->list[j]);

			if (switch_instr != nullptr) {
				lbValue on_val = {};
				if (expr->tav.mode == Addressing_Type) {
					GB_ASSERT(is_type_typeid(tag.type));
					lbValue e = lb_typeid(p->module, expr->tav.type);
					on_val = lb_emit_conv(p, e, tag.type);
				} else {
					GB_ASSERT(expr->tav.mode == Addressing_Constant);
					GB_ASSERT(!is_ast_range(expr));

					on_val = lb_build_expr(p, expr);
					on_val = lb_emit_conv(p, on_val, tag.type);
				}

				GB_ASSERT(LLVMIsConstant(on_val.value));
				LLVMAddCase(switch_instr, on_val.value, body->block);
				continue;
			}

			next_cond = lb_create_block(p, "switch.case.next");

			lbValue cond = {};
			if (is_ast_range(expr)) {
				ast_node(ie, BinaryExpr, expr);
				TokenKind op = Token_Invalid;
				switch (ie->op.kind) {
				case Token_Ellipsis:  op = Token_LtEq; break;
				case Token_RangeFull: op = Token_LtEq; break;
				case Token_RangeHalf: op = Token_Lt;   break;
				default: GB_PANIC("Invalid interval operator"); break;
				}
				lbValue lhs = lb_build_expr(p, ie->left);
				lbValue rhs = lb_build_expr(p, ie->right);

				lbValue cond_lhs = lb_emit_comp(p, Token_LtEq, lhs, tag);
				lbValue cond_rhs = lb_emit_comp(p, op, tag, rhs);
				cond = lb_emit_arith(p, Token_And, cond_lhs, cond_rhs, t_bool);
			} else {
				if (expr->tav.mode == Addressing_Type) {
					GB_ASSERT(is_type_typeid(tag.type));
					lbValue e = lb_typeid(p->module, expr->tav.type);
					e = lb_emit_conv(p, e, tag.type);
					cond = lb_emit_comp(p, Token_CmpEq, tag, e);
				} else {
					cond = lb_emit_comp(p, Token_CmpEq, tag, lb_build_expr(p, expr));
				}
			}

			lb_emit_if(p, cond, body, next_cond);
			lb_start_block(p, next_cond);
		}
		lb_start_block(p, body);

		lb_push_target_list(p, ss->label, done, nullptr, fall);
		lb_open_scope(p, body->scope);
		lb_build_stmt_list(p, cc->stmts);
		lb_close_scope(p, lbDeferExit_Default, body);
		lb_pop_target_list(p);

		lb_emit_jump(p, done);
		if (switch_instr == nullptr) {
			lb_start_block(p, next_cond);
		}
	}

	if (default_block != nullptr) {
		if (switch_instr == nullptr) {
			lb_emit_jump(p, default_block);
		}
		lb_start_block(p, default_block);

		lb_push_target_list(p, ss->label, done, nullptr, default_fall);
		lb_open_scope(p, default_block->scope);
		lb_build_stmt_list(p, default_stmts);
		lb_close_scope(p, lbDeferExit_Default, default_block);
		lb_pop_target_list(p);
	}

	lb_emit_jump(p, done);
	lb_start_block(p, done);
	lb_close_scope(p, lbDeferExit_Default, done);
}

void lb_store_type_case_implicit(lbProcedure *p, Ast *clause, lbValue value) {
	Entity *e = implicit_entity_of_node(clause);
	GB_ASSERT(e != nullptr);
	if (e->flags & EntityFlag_Value) {
		// by value
		GB_ASSERT(are_types_identical(e->type, value.type));
		lbAddr x = lb_add_local(p, e->type, e, false);
		lb_addr_store(p, x, value);
	} else {
		// by reference
		GB_ASSERT(are_types_identical(e->type, type_deref(value.type)));
		lb_add_entity(p->module, e, value);
	}
}

lbAddr lb_store_range_stmt_val(lbProcedure *p, Ast *stmt_val, lbValue value) {
	Entity *e = entity_of_node(stmt_val);
	if (e == nullptr) {
		return {};
	}

	if ((e->flags & EntityFlag_Value) == 0) {
		if (LLVMIsALoadInst(value.value)) {
			lbValue ptr = lb_address_from_load_or_generate_local(p, value);
			lb_add_entity(p->module, e, ptr);
			return lb_addr(ptr);
		}
	}

	// by value
	lbAddr addr = lb_add_local(p, e->type, e, false);
	lb_addr_store(p, addr, value);
	return addr;
}

void lb_type_case_body(lbProcedure *p, Ast *label, Ast *clause, lbBlock *body, lbBlock *done) {
	ast_node(cc, CaseClause, clause);

	lb_push_target_list(p, label, done, nullptr, nullptr);
	lb_build_stmt_list(p, cc->stmts);
	lb_close_scope(p, lbDeferExit_Default, body);
	lb_pop_target_list(p);

	lb_emit_jump(p, done);
}

void lb_build_type_switch_stmt(lbProcedure *p, AstTypeSwitchStmt *ss) {
	lbModule *m = p->module;
	lb_open_scope(p, ss->scope);

	ast_node(as, AssignStmt, ss->tag);
	GB_ASSERT(as->lhs.count == 1);
	GB_ASSERT(as->rhs.count == 1);

	lbValue parent = lb_build_expr(p, as->rhs[0]);
	bool is_parent_ptr = is_type_pointer(parent.type);

	TypeSwitchKind switch_kind = check_valid_type_switch_type(parent.type);
	GB_ASSERT(switch_kind != TypeSwitch_Invalid);

	lbValue parent_value = parent;

	lbValue parent_ptr = parent;
	if (!is_parent_ptr) {
		parent_ptr = lb_address_from_load_or_generate_local(p, parent);
	}

	lbValue tag = {};
	lbValue union_data = {};
	if (switch_kind == TypeSwitch_Union) {
		union_data = lb_emit_conv(p, parent_ptr, t_rawptr);
		if (is_type_union_maybe_pointer(type_deref(parent_ptr.type))) {
			tag = lb_emit_conv(p, lb_emit_comp_against_nil(p, Token_NotEq, union_data), t_int);
		} else {
			lbValue tag_ptr = lb_emit_union_tag_ptr(p, parent_ptr);
			tag = lb_emit_load(p, tag_ptr);
		}
	} else if (switch_kind == TypeSwitch_Any) {
		tag = lb_emit_load(p, lb_emit_struct_ep(p, parent_ptr, 1));
	} else {
		GB_PANIC("Unknown switch kind");
	}

	ast_node(body, BlockStmt, ss->body);

	lbBlock *done = lb_create_block(p, "typeswitch.done");
	lbBlock *else_block = done;
	lbBlock *default_block = nullptr;
	isize num_cases = 0;

	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);
		num_cases += cc->list.count;
		if (cc->list.count == 0) {
			GB_ASSERT(default_block == nullptr);
			default_block = lb_create_block(p, "typeswitch.default.body");
			else_block = default_block;
		}
	}

	GB_ASSERT(tag.value != nullptr);
	LLVMValueRef switch_instr = LLVMBuildSwitch(p->builder, tag.value, else_block->block, cast(unsigned)num_cases);

	for_array(i, body->stmts) {
		Ast *clause = body->stmts[i];
		ast_node(cc, CaseClause, clause);
		lb_open_scope(p, cc->scope);
		if (cc->list.count == 0) {
			lb_start_block(p, default_block);
			lb_store_type_case_implicit(p, clause, parent_value);
			lb_type_case_body(p, ss->label, clause, p->curr_block, done);
			continue;
		}

		lbBlock *body = lb_create_block(p, "typeswitch.body");
		if (p->debug_info != nullptr) {
			LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_ast(p, clause));
		}
		Type *case_type = nullptr;
		for_array(type_index, cc->list) {
			case_type = type_of_expr(cc->list[type_index]);
			lbValue on_val = {};
			if (switch_kind == TypeSwitch_Union) {
				Type *ut = base_type(type_deref(parent.type));
				on_val = lb_const_union_tag(m, ut, case_type);

			} else if (switch_kind == TypeSwitch_Any) {
				on_val = lb_typeid(m, case_type);
			}
			GB_ASSERT(on_val.value != nullptr);
			LLVMAddCase(switch_instr, on_val.value, body->block);
		}

		Entity *case_entity = implicit_entity_of_node(clause);

		lbValue value = parent_value;

		lb_start_block(p, body);

		bool by_reference = (case_entity->flags & EntityFlag_Value) == 0;

		if (cc->list.count == 1) {
			lbValue data = {};
			if (switch_kind == TypeSwitch_Union) {
				data = union_data;
			} else if (switch_kind == TypeSwitch_Any) {
				data = lb_emit_load(p, lb_emit_struct_ep(p, parent_ptr, 0));
			}

			Type *ct = case_entity->type;
			Type *ct_ptr = alloc_type_pointer(ct);

			value = lb_emit_conv(p, data, ct_ptr);
			if (!by_reference) {
				value = lb_emit_load(p, value);
			}
		}

		lb_store_type_case_implicit(p, clause, value);
		lb_type_case_body(p, ss->label, clause, body, done);
	}

	lb_emit_jump(p, done);
	lb_start_block(p, done);
	lb_close_scope(p, lbDeferExit_Default, done);
}


void lb_build_static_variables(lbProcedure *p, AstValueDecl *vd) {
	for_array(i, vd->names) {
		lbValue value = {};
		if (vd->values.count > 0) {
			GB_ASSERT(vd->names.count == vd->values.count);
			Ast *ast_value = vd->values[i];
			GB_ASSERT(ast_value->tav.mode == Addressing_Constant ||
			          ast_value->tav.mode == Addressing_Invalid);

			bool allow_local = false;
			value = lb_const_value(p->module, ast_value->tav.type, ast_value->tav.value, allow_local);
		}

		Ast *ident = vd->names[i];
		GB_ASSERT(!is_blank_ident(ident));
		Entity *e = entity_of_node(ident);
		GB_ASSERT(e->flags & EntityFlag_Static);
		String name = e->token.string;

		String mangled_name = {};
		{
			gbString str = gb_string_make_length(permanent_allocator(), p->name.text, p->name.len);
			str = gb_string_appendc(str, "-");
			str = gb_string_append_fmt(str, ".%.*s-%llu", LIT(name), cast(long long)e->id);
			mangled_name.text = cast(u8 *)str;
			mangled_name.len = gb_string_length(str);
		}

		char *c_name = alloc_cstring(permanent_allocator(), mangled_name);

		LLVMValueRef global = LLVMAddGlobal(p->module->mod, lb_type(p->module, e->type), c_name);
		LLVMSetInitializer(global, LLVMConstNull(lb_type(p->module, e->type)));
		if (value.value != nullptr) {
			LLVMSetInitializer(global, value.value);
		} else {
		}
		if (e->Variable.thread_local_model != "") {
			LLVMSetThreadLocal(global, true);

			String m = e->Variable.thread_local_model;
			LLVMThreadLocalMode mode = LLVMGeneralDynamicTLSModel;
			if (m == "default") {
				mode = LLVMGeneralDynamicTLSModel;
			} else if (m == "localdynamic") {
				mode = LLVMLocalDynamicTLSModel;
			} else if (m == "initialexec") {
				mode = LLVMInitialExecTLSModel;
			} else if (m == "localexec") {
				mode = LLVMLocalExecTLSModel;
			} else {
				GB_PANIC("Unhandled thread local mode %.*s", LIT(m));
			}
			LLVMSetThreadLocalMode(global, mode);
		} else {
			LLVMSetLinkage(global, LLVMInternalLinkage);
		}


		lbValue global_val = {global, alloc_type_pointer(e->type)};
		lb_add_entity(p->module, e, global_val);
		lb_add_member(p->module, mangled_name, global_val);
	}
}


void lb_build_assignment(lbProcedure *p, Array<lbAddr> &lvals, Slice<Ast *> const &values) {
	if (values.count == 0) {
		return;
	}

	auto inits = array_make<lbValue>(permanent_allocator(), 0, lvals.count);

	for_array(i, values) {
		Ast *rhs = values[i];
		if (is_type_tuple(type_of_expr(rhs))) {
			lbValue init = lb_build_expr(p, rhs);
			Type *t = init.type;
			GB_ASSERT(t->kind == Type_Tuple);
			for_array(i, t->Tuple.variables) {
				lbValue v = lb_emit_struct_ev(p, init, cast(i32)i);
				array_add(&inits, v);
			}
		} else {
			auto prev_hint = lb_set_copy_elision_hint(p, lvals[inits.count], rhs);
			lbValue init = lb_build_expr(p, rhs);
			if (p->copy_elision_hint.used) {
				lvals[inits.count] = {}; // zero lval
			}
			lb_reset_copy_elision_hint(p, prev_hint);
			array_add(&inits, init);
		}
	}

	GB_ASSERT(lvals.count == inits.count);
	for_array(i, inits) {
		lbAddr lval = lvals[i];
		lbValue init = inits[i];
		lb_addr_store(p, lval, init);
	}
}

void lb_build_return_stmt_internal(lbProcedure *p, lbValue const &res) {
	lbFunctionType *ft = lb_get_function_type(p->module, p, p->type);
	bool return_by_pointer = ft->ret.kind == lbArg_Indirect;

	if (return_by_pointer) {
		if (res.value != nullptr) {
			LLVMValueRef res_val = res.value;
			i64 sz = type_size_of(res.type);
			if (LLVMIsALoadInst(res_val) && sz > build_context.word_size) {
				lbValue ptr = lb_address_from_load_or_generate_local(p, res);
				lb_mem_copy_non_overlapping(p, p->return_ptr.addr, ptr, lb_const_int(p->module, t_int, sz));
			} else {
				LLVMBuildStore(p->builder, res_val, p->return_ptr.addr.value);
			}
		} else {
			LLVMBuildStore(p->builder, LLVMConstNull(p->abi_function_type->ret.type), p->return_ptr.addr.value);
		}

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);

		LLVMBuildRetVoid(p->builder);
	} else {
		LLVMValueRef ret_val = res.value;
		ret_val = OdinLLVMBuildTransmute(p, ret_val, p->abi_function_type->ret.type);
		if (p->abi_function_type->ret.cast_type != nullptr) {
			ret_val = OdinLLVMBuildTransmute(p, ret_val, p->abi_function_type->ret.cast_type);
		}

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
		LLVMBuildRet(p->builder, ret_val);
	}
}
void lb_build_return_stmt(lbProcedure *p, Slice<Ast *> const &return_results) {
	lb_ensure_abi_function_type(p->module, p);

	lbValue res = {};

	TypeTuple *tuple  = &p->type->Proc.results->Tuple;
	isize return_count = p->type->Proc.result_count;
	isize res_count = return_results.count;

	lbFunctionType *ft = lb_get_function_type(p->module, p, p->type);
	bool return_by_pointer = ft->ret.kind == lbArg_Indirect;

	if (return_count == 0) {
		// No return values

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);

		LLVMBuildRetVoid(p->builder);
		return;
	} else if (return_count == 1) {
		Entity *e = tuple->variables[0];
		if (res_count == 0) {
			lbValue found = map_must_get(&p->module->values, e);
			res = lb_emit_load(p, found);
		} else {
			res = lb_build_expr(p, return_results[0]);
			res = lb_emit_conv(p, res, e->type);
		}
		if (p->type->Proc.has_named_results) {
			// NOTE(bill): store the named values before returning
			if (e->token.string != "") {
				lbValue found = map_must_get(&p->module->values, e);
				lb_emit_store(p, found, lb_emit_conv(p, res, e->type));
			}
		}

	} else {
		auto results = array_make<lbValue>(permanent_allocator(), 0, return_count);

		if (res_count != 0) {
			for (isize res_index = 0; res_index < res_count; res_index++) {
				lbValue res = lb_build_expr(p, return_results[res_index]);
				Type *t = res.type;
				if (t->kind == Type_Tuple) {
					for_array(i, t->Tuple.variables) {
						lbValue v = lb_emit_struct_ev(p, res, cast(i32)i);
						array_add(&results, v);
					}
				} else {
					array_add(&results, res);
				}
			}
		} else {
			for (isize res_index = 0; res_index < return_count; res_index++) {
				Entity *e = tuple->variables[res_index];
				lbValue found = map_must_get(&p->module->values, e);
				lbValue res = lb_emit_load(p, found);
				array_add(&results, res);
			}
		}

		GB_ASSERT(results.count == return_count);

		if (p->type->Proc.has_named_results) {
			auto named_results = slice_make<lbValue>(temporary_allocator(), results.count);
			auto values = slice_make<lbValue>(temporary_allocator(), results.count);

			// NOTE(bill): store the named values before returning
			for_array(i, p->type->Proc.results->Tuple.variables) {
				Entity *e = p->type->Proc.results->Tuple.variables[i];
				if (e->kind != Entity_Variable) {
					continue;
				}

				if (e->token.string == "") {
					continue;
				}
				named_results[i] = map_must_get(&p->module->values, e);
				values[i] = lb_emit_conv(p, results[i], e->type);
			}

			for_array(i, named_results) {
				lb_emit_store(p, named_results[i], values[i]);
			}
		}

		Type *ret_type = p->type->Proc.results;

		// NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		if (return_by_pointer) {
			res = p->return_ptr.addr;
		} else {
			res = lb_add_local_generated(p, ret_type, false).addr;
		}

		auto result_values = slice_make<lbValue>(temporary_allocator(), results.count);
		auto result_eps = slice_make<lbValue>(temporary_allocator(), results.count);

		for_array(i, results) {
			result_values[i] = lb_emit_conv(p, results[i], tuple->variables[i]->type);
		}
		for_array(i, results) {
			result_eps[i] = lb_emit_struct_ep(p, res, cast(i32)i);
		}
		for_array(i, result_values) {
			lb_emit_store(p, result_eps[i], result_values[i]);
		}

		if (return_by_pointer) {
			lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
			LLVMBuildRetVoid(p->builder);
			return;
		}

		res = lb_emit_load(p, res);
	}
	lb_build_return_stmt_internal(p, res);
}

void lb_build_if_stmt(lbProcedure *p, Ast *node) {
	ast_node(is, IfStmt, node);
	lb_open_scope(p, is->scope); // Scope #1
	defer (lb_close_scope(p, lbDeferExit_Default, nullptr));

	if (is->init != nullptr) {
		// TODO(bill): Should this have a separate block to begin with?
	#if 1
		lbBlock *init = lb_create_block(p, "if.init");
		lb_emit_jump(p, init);
		lb_start_block(p, init);
	#endif
		lb_build_stmt(p, is->init);
	}
	lbBlock *then = lb_create_block(p, "if.then");
	lbBlock *done = lb_create_block(p, "if.done");
	lbBlock *else_ = done;
	if (is->else_stmt != nullptr) {
		else_ = lb_create_block(p, "if.else");
	}

	lbValue cond = lb_build_cond(p, is->cond, then, else_);
	// Note `cond.value` only set for non-and/or conditions and const negs so that the `LLVMIsConstant()`
	// and `LLVMConstIntGetZExtValue()` calls below will be valid and `LLVMInstructionEraseFromParent()`
	// will target the correct (& only) branch statement

	if (is->label != nullptr) {
		lbTargetList *tl = lb_push_target_list(p, is->label, done, nullptr, nullptr);
		tl->is_block = true;
	}

	if (cond.value && LLVMIsConstant(cond.value)) {
		// NOTE(bill): Do a compile time short circuit for when the condition is constantly known.
		// This done manually rather than relying on the SSA passes because sometimes the SSA passes
		// miss some even if they are constantly known, especially with few optimization passes.

		bool const_cond = LLVMConstIntGetZExtValue(cond.value) != 0;

		LLVMValueRef if_instr = LLVMGetLastInstruction(p->curr_block->block);
		GB_ASSERT(LLVMGetInstructionOpcode(if_instr) == LLVMBr);
		GB_ASSERT(LLVMIsConditional(if_instr));
		LLVMInstructionEraseFromParent(if_instr);


		if (const_cond) {
			lb_emit_jump(p, then);
			lb_start_block(p, then);

			lb_build_stmt(p, is->body);
			lb_emit_jump(p, done);
		} else {
			if (is->else_stmt != nullptr) {
				lb_emit_jump(p, else_);
				lb_start_block(p, else_);

				lb_open_scope(p, scope_of_node(is->else_stmt));
				lb_build_stmt(p, is->else_stmt);
				lb_close_scope(p, lbDeferExit_Default, nullptr);
			}
			lb_emit_jump(p, done);

		}
	} else {
		lb_start_block(p, then);

		lb_build_stmt(p, is->body);

		lb_emit_jump(p, done);

		if (is->else_stmt != nullptr) {
			lb_start_block(p, else_);

			lb_open_scope(p, scope_of_node(is->else_stmt));
			lb_build_stmt(p, is->else_stmt);
			lb_close_scope(p, lbDeferExit_Default, nullptr);

			lb_emit_jump(p, done);
		}
	}

	if (is->label != nullptr) {
		lb_pop_target_list(p);
	}

	lb_start_block(p, done);
}

void lb_build_for_stmt(lbProcedure *p, Ast *node) {
	ast_node(fs, ForStmt, node);

	lb_open_scope(p, fs->scope); // Open Scope here
	if (p->debug_info != nullptr) {
		LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_ast(p, node));
	}

	if (fs->init != nullptr) {
	#if 1
		lbBlock *init = lb_create_block(p, "for.init");
		lb_emit_jump(p, init);
		lb_start_block(p, init);
	#endif
		lb_build_stmt(p, fs->init);
	}
	lbBlock *body = lb_create_block(p, "for.body");
	lbBlock *done = lb_create_block(p, "for.done"); // NOTE(bill): Append later
	lbBlock *loop = body;
	if (fs->cond != nullptr) {
		loop = lb_create_block(p, "for.loop");
	}
	lbBlock *post = loop;
	if (fs->post != nullptr) {
		post = lb_create_block(p, "for.post");
	}

	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	if (loop != body) {
		// right now the condition (all expressions) will not set it's debug location, so we will do it here
		if (p->debug_info != nullptr) {
			LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_ast(p, fs->cond));
		}
		lb_build_cond(p, fs->cond, body, done);
		lb_start_block(p, body);
	}

	lb_push_target_list(p, fs->label, done, post, nullptr);

	lb_build_stmt(p, fs->body);

	lb_pop_target_list(p);

	if (p->debug_info != nullptr) {
		LLVMSetCurrentDebugLocation2(p->builder, lb_debug_end_location_from_ast(p, fs->body));
	}
	lb_emit_jump(p, post);

	if (fs->post != nullptr) {
		lb_start_block(p, post);
		lb_build_stmt(p, fs->post);
		lb_emit_jump(p, loop);
	}

	lb_start_block(p, done);
	lb_close_scope(p, lbDeferExit_Default, nullptr);
}

void lb_build_assign_stmt_array(lbProcedure *p, TokenKind op, lbAddr const &lhs, lbValue const &value) {
	GB_ASSERT(op != Token_Eq);

	Type *lhs_type = lb_addr_type(lhs);
	Type *array_type = base_type(lhs_type);
	GB_ASSERT(is_type_array_like(array_type));
	i64 count = get_array_type_count(array_type);
	Type *elem_type = base_array_type(array_type);

	lbValue rhs = lb_emit_conv(p, value, lhs_type);

	bool inline_array_arith = lb_can_try_to_inline_array_arith(array_type);


	if (lhs.kind == lbAddr_Swizzle) {
		GB_ASSERT(is_type_array(lhs_type));

		struct ValueAndIndex {
			lbValue value;
			u8      index;
		};

		bool indices_handled[4] = {};
		i32 indices[4] = {};
		i32 index_count = 0;
		for (u8 i = 0; i < lhs.swizzle.count; i++) {
			u8 index = lhs.swizzle.indices[i];
			if (indices_handled[index]) {
				continue;
			}
			indices[index_count++] = index;
		}

		lbValue lhs_ptrs[4] = {};
		lbValue x_loads[4]  = {};
		lbValue y_loads[4]  = {};
		lbValue ops[4]      = {};

		for (i32 i = 0; i < index_count; i++) {
			lhs_ptrs[i] = lb_emit_array_epi(p, lhs.addr, indices[i]);
		}
		for (i32 i = 0; i < index_count; i++) {
			x_loads[i] = lb_emit_load(p, lhs_ptrs[i]);
		}
		for (i32 i = 0; i < index_count; i++) {
			y_loads[i].value = LLVMBuildExtractValue(p->builder, rhs.value, i, "");
			y_loads[i].type = elem_type;
		}
		for (i32 i = 0; i < index_count; i++) {
			ops[i] = lb_emit_arith(p, op, x_loads[i], y_loads[i], elem_type);
		}
		for (i32 i = 0; i < index_count; i++) {
			lb_emit_store(p, lhs_ptrs[i], ops[i]);
		}
		return;
	} else if (lhs.kind == lbAddr_SwizzleLarge) {
		GB_ASSERT(is_type_array(lhs_type));

		struct ValueAndIndex {
			lbValue value;
			u32     index;
		};

		Type *bt = base_type(lhs_type);
		GB_ASSERT(bt->kind == Type_Array);

		auto indices_handled = slice_make<bool>(temporary_allocator(), bt->Array.count);
		auto indices = slice_make<i32>(temporary_allocator(), bt->Array.count);
		i32 index_count = 0;
		for_array(i, lhs.swizzle_large.indices) {
			i32 index = lhs.swizzle_large.indices[i];
			if (indices_handled[index]) {
				continue;
			}
			indices[index_count++] = index;
		}

		lbValue lhs_ptrs[4] = {};
		lbValue x_loads[4]  = {};
		lbValue y_loads[4]  = {};
		lbValue ops[4]      = {};

		for (i32 i = 0; i < index_count; i++) {
			lhs_ptrs[i] = lb_emit_array_epi(p, lhs.addr, indices[i]);
		}
		for (i32 i = 0; i < index_count; i++) {
			x_loads[i] = lb_emit_load(p, lhs_ptrs[i]);
		}
		for (i32 i = 0; i < index_count; i++) {
			y_loads[i].value = LLVMBuildExtractValue(p->builder, rhs.value, i, "");
			y_loads[i].type = elem_type;
		}
		for (i32 i = 0; i < index_count; i++) {
			ops[i] = lb_emit_arith(p, op, x_loads[i], y_loads[i], elem_type);
		}
		for (i32 i = 0; i < index_count; i++) {
			lb_emit_store(p, lhs_ptrs[i], ops[i]);
		}
		return;
	}


	lbValue x = lb_addr_get_ptr(p, lhs);
	if (inline_array_arith) {
		unsigned n = cast(unsigned)count;

		auto lhs_ptrs = slice_make<lbValue>(temporary_allocator(), n);
		auto x_loads  = slice_make<lbValue>(temporary_allocator(), n);
		auto y_loads  = slice_make<lbValue>(temporary_allocator(), n);
		auto ops      = slice_make<lbValue>(temporary_allocator(), n);

		for (unsigned i = 0; i < n; i++) {
			lhs_ptrs[i] = lb_emit_array_epi(p, x, i);
		}
		for (unsigned i = 0; i < n; i++) {
			x_loads[i] = lb_emit_load(p, lhs_ptrs[i]);
		}
		for (unsigned i = 0; i < n; i++) {
			y_loads[i].value = LLVMBuildExtractValue(p->builder, rhs.value, i, "");
			y_loads[i].type = elem_type;
		}
		for (unsigned i = 0; i < n; i++) {
			ops[i] = lb_emit_arith(p, op, x_loads[i], y_loads[i], elem_type);
		}
		for (unsigned i = 0; i < n; i++) {
			lb_emit_store(p, lhs_ptrs[i], ops[i]);
		}
	} else {
		lbValue y = lb_address_from_load_or_generate_local(p, rhs);

		auto loop_data = lb_loop_start(p, cast(isize)count, t_i32);

		lbValue a_ptr = lb_emit_array_ep(p, x, loop_data.idx);
		lbValue b_ptr = lb_emit_array_ep(p, y, loop_data.idx);

		lbValue a = lb_emit_load(p, a_ptr);
		lbValue b = lb_emit_load(p, b_ptr);
		lbValue c = lb_emit_arith(p, op, a, b, elem_type);
		lb_emit_store(p, a_ptr, c);

		lb_loop_end(p, loop_data);
	}
}
void lb_build_assign_stmt(lbProcedure *p, AstAssignStmt *as) {
	if (as->op.kind == Token_Eq) {
		auto lvals = array_make<lbAddr>(permanent_allocator(), 0, as->lhs.count);

		for_array(i, as->lhs) {
			Ast *lhs = as->lhs[i];
			lbAddr lval = {};
			if (!is_blank_ident(lhs)) {
				lval = lb_build_addr(p, lhs);
			}
			array_add(&lvals, lval);
		}
		lb_build_assignment(p, lvals, as->rhs);
		return;
	}
	GB_ASSERT(as->lhs.count == 1);
	GB_ASSERT(as->rhs.count == 1);
	// NOTE(bill): Only 1 += 1 is allowed, no tuples
	// +=, -=, etc
	i32 op_ = cast(i32)as->op.kind;
	op_ += Token_Add - Token_AddEq; // Convert += to +
	TokenKind op = cast(TokenKind)op_;
	if (op == Token_CmpAnd || op == Token_CmpOr) {
		Type *type = as->lhs[0]->tav.type;
		lbValue new_value = lb_emit_logical_binary_expr(p, op, as->lhs[0], as->rhs[0], type);

		lbAddr lhs = lb_build_addr(p, as->lhs[0]);
		lb_addr_store(p, lhs, new_value);
	} else {
		lbAddr lhs = lb_build_addr(p, as->lhs[0]);
		lbValue value = lb_build_expr(p, as->rhs[0]);
		Type *lhs_type = lb_addr_type(lhs);

		// NOTE(bill): Allow for the weird edge case of:
		// array *= matrix
		if (op == Token_Mul && is_type_matrix(value.type) && is_type_array(lhs_type)) {
			lbValue old_value = lb_addr_load(p, lhs);
			Type *type = old_value.type;
			lbValue new_value = lb_emit_vector_mul_matrix(p, old_value, value, type);
			lb_addr_store(p, lhs, new_value);
			return;
		}

		if (is_type_array(lhs_type)) {
			lb_build_assign_stmt_array(p, op, lhs, value);
			return;
		} else {
			lbValue old_value = lb_addr_load(p, lhs);
			Type *type = old_value.type;

			lbValue change = lb_emit_conv(p, value, type);
			lbValue new_value = lb_emit_arith(p, op, old_value, change, type);
			lb_addr_store(p, lhs, new_value);
		}
	}
}


void lb_build_stmt(lbProcedure *p, Ast *node) {
	Ast *prev_stmt = p->curr_stmt;
	defer (p->curr_stmt = prev_stmt);
	p->curr_stmt = node;

	if (p->curr_block != nullptr) {
		LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
		if (lb_is_instr_terminating(last_instr)) {
			return;
		}
	}

	if (p->debug_info != nullptr) {
		LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_ast(p, node));
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
		lb_build_when_stmt(p, ws);
	case_end;


	case_ast_node(bs, BlockStmt, node);
		lbBlock *done = nullptr;
		if (bs->label != nullptr) {
			done = lb_create_block(p, "block.done");
			lbTargetList *tl = lb_push_target_list(p, bs->label, done, nullptr, nullptr);
			tl->is_block = true;
		}

		lb_open_scope(p, bs->scope);
		lb_build_stmt_list(p, bs->stmts);
		lb_close_scope(p, lbDeferExit_Default, nullptr);

		if (done != nullptr) {
			lb_emit_jump(p, done);
			lb_start_block(p, done);
		}

		if (bs->label != nullptr) {
			lb_pop_target_list(p);
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			return;
		}

		bool is_static = false;
		if (vd->names.count > 0) {
			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				if (!is_blank_ident(name)) {
					Entity *e = entity_of_node(name);
					TokenPos pos = ast_token(name).pos;
					GB_ASSERT_MSG(e != nullptr, "%s", token_pos_to_string(pos));
					if (e->flags & EntityFlag_Static) {
						// NOTE(bill): If one of the entities is static, they all are
						is_static = true;
						break;
					}
				}
			}
		}

		if (is_static) {
			lb_build_static_variables(p, vd);
			return;
		}

		auto lvals = array_make<lbAddr>(permanent_allocator(), 0, vd->names.count);

		for_array(i, vd->names) {
			Ast *name = vd->names[i];
			lbAddr lval = {};
			if (!is_blank_ident(name)) {
				Entity *e = entity_of_node(name);
				// bool zero_init = true; // Always do it
				bool zero_init = vd->values.count == 0;
				lval = lb_add_local(p, e->type, e, zero_init);
			}
			array_add(&lvals, lval);
		}
		lb_build_assignment(p, lvals, vd->values);
	case_end;

	case_ast_node(as, AssignStmt, node);
		lb_build_assign_stmt(p, as);
	case_end;

	case_ast_node(es, ExprStmt, node);
		lb_build_expr(p, es->expr);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		lb_add_defer_node(p, p->scope_index, ds->stmt);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		lb_build_return_stmt(p, rs->results);
	case_end;

	case_ast_node(is, IfStmt, node);
		lb_build_if_stmt(p, node);
	case_end;

	case_ast_node(fs, ForStmt, node);
		lb_build_for_stmt(p, node);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		lb_build_range_stmt(p, rs, rs->scope);
	case_end;

	case_ast_node(rs, UnrollRangeStmt, node);
		lb_build_unroll_range_stmt(p, rs, rs->scope);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		lb_build_switch_stmt(p, ss, ss->scope);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		lb_build_type_switch_stmt(p, ss);
	case_end;

	case_ast_node(bs, BranchStmt, node);
		lbBlock *block = nullptr;

		if (bs->label != nullptr) {
			lbBranchBlocks bb = lb_lookup_branch_blocks(p, bs->label);
			switch (bs->token.kind) {
			case Token_break:    block = bb.break_;    break;
			case Token_continue: block = bb.continue_; break;
			case Token_fallthrough:
				GB_PANIC("fallthrough cannot have a label");
				break;
			}
		} else {
			for (lbTargetList *t = p->target_list; t != nullptr && block == nullptr; t = t->prev) {
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
			lb_emit_defer_stmts(p, lbDeferExit_Branch, block);
		}
		lb_emit_jump(p, block);
		lb_start_block(p, lb_create_block(p, "unreachable"));
	case_end;
	}
}




void lb_build_defer_stmt(lbProcedure *p, lbDefer const &d) {
	if (p->curr_block == nullptr) {
		return;
	}
	// NOTE(bill): The prev block may defer injection before it's terminator
	LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
	if (last_instr != nullptr && LLVMIsAReturnInst(last_instr)) {
		// NOTE(bill): ReturnStmt defer stuff will be handled previously
		return;
	}

	isize prev_context_stack_count = p->context_stack.count;
	GB_ASSERT(prev_context_stack_count <= p->context_stack.capacity);
	defer (p->context_stack.count = prev_context_stack_count);
	p->context_stack.count = d.context_stack_count;

	lbBlock *b = lb_create_block(p, "defer");
	if (last_instr == nullptr || !LLVMIsATerminatorInst(last_instr)) {
		lb_emit_jump(p, b);
	}

	lb_start_block(p, b);
	if (d.kind == lbDefer_Node) {
		lb_build_stmt(p, d.stmt);
	} else if (d.kind == lbDefer_Proc) {
		lb_emit_call(p, d.proc.deferred, d.proc.result_as_args);
	}
}

void lb_emit_defer_stmts(lbProcedure *p, lbDeferExitKind kind, lbBlock *block) {
	isize count = p->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		lbDefer const &d = p->defer_stmts[i];

		if (kind == lbDeferExit_Default) {
			if (p->scope_index == d.scope_index &&
			    d.scope_index > 0) { // TODO(bill): Which is correct: > 0 or > 1?
				lb_build_defer_stmt(p, d);
				array_pop(&p->defer_stmts);
				continue;
			} else {
				break;
			}
		} else if (kind == lbDeferExit_Return) {
			lb_build_defer_stmt(p, d);
		} else if (kind == lbDeferExit_Branch) {
			GB_ASSERT(block != nullptr);
			isize lower_limit = block->scope_index;
			if (lower_limit < d.scope_index) {
				lb_build_defer_stmt(p, d);
			}
		}
	}
}

void lb_add_defer_node(lbProcedure *p, isize scope_index, Ast *stmt) {
	Type *pt = base_type(p->type);
	GB_ASSERT(pt->kind == Type_Proc);
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		GB_ASSERT(p->context_stack.count != 0);
	}

	lbDefer *d = array_add_and_get(&p->defer_stmts);
	d->kind = lbDefer_Node;
	d->scope_index = scope_index;
	d->context_stack_count = p->context_stack.count;
	d->block = p->curr_block;
	d->stmt = stmt;
}

void lb_add_defer_proc(lbProcedure *p, isize scope_index, lbValue deferred, Array<lbValue> const &result_as_args) {
	Type *pt = base_type(p->type);
	GB_ASSERT(pt->kind == Type_Proc);
	if (pt->Proc.calling_convention == ProcCC_Odin) {
		GB_ASSERT(p->context_stack.count != 0);
	}

	lbDefer *d = array_add_and_get(&p->defer_stmts);
	d->kind = lbDefer_Proc;
	d->scope_index = p->scope_index;
	d->block = p->curr_block;
	d->context_stack_count = p->context_stack.count;
	d->proc.deferred = deferred;
	d->proc.result_as_args = result_as_args;
}
