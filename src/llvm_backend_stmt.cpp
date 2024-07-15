gb_internal void lb_build_constant_value_decl(lbProcedure *p, AstValueDecl *vd) {
	if (vd == nullptr || vd->is_mutable) {
		return;
	}

	auto *min_dep_set = &p->module->info->minimum_dependency_set;

	static i32 global_guid = 0;

	for (Ast *ident : vd->names) {
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

		lb_set_nested_type_name_ir_mangled_name(e, p, p->module);
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

		DeclInfo *decl = decl_info_of_entity(e);
		ast_node(pl, ProcLit, decl->proc_lit);
		if (pl->body != nullptr) {
			GenProcsData *gpd = e->Procedure.gen_procs;
			if (gpd) {
				rw_mutex_shared_lock(&gpd->mutex);
				for (Entity *e : gpd->procs) {
					if (!ptr_set_exists(min_dep_set, e)) {
						continue;
					}
					DeclInfo *d = decl_info_of_entity(e);
					lb_build_nested_proc(p, &d->proc_lit->ProcLit, e);
				}
				rw_mutex_shared_unlock(&gpd->mutex);
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


gb_internal void lb_build_stmt_list(lbProcedure *p, Slice<Ast *> const &stmts) {
	for (Ast *stmt : stmts) {
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
	for (Ast *stmt : stmts) {
		lb_build_stmt(p, stmt);
	}
}



gb_internal lbBranchBlocks lb_lookup_branch_blocks(lbProcedure *p, Ast *ident) {
	GB_ASSERT(ident->kind == Ast_Ident);
	Entity *e = entity_of_node(ident);
	GB_ASSERT(e->kind == Entity_Label);
	for (lbBranchBlocks const &b : p->branch_blocks) {
		if (b.label == e->Label.node) {
			return b;
		}
	}

	GB_PANIC("Unreachable");
	lbBranchBlocks empty = {};
	return empty;
}


gb_internal lbTargetList *lb_push_target_list(lbProcedure *p, Ast *label, lbBlock *break_, lbBlock *continue_, lbBlock *fallthrough_) {
	lbTargetList *tl = gb_alloc_item(permanent_allocator(), lbTargetList);
	tl->prev = p->target_list;
	tl->break_ = break_;
	tl->continue_ = continue_;
	tl->fallthrough_ = fallthrough_;
	p->target_list = tl;

	if (label != nullptr) { // Set label blocks
		GB_ASSERT(label->kind == Ast_Label);

		for (lbBranchBlocks &b : p->branch_blocks) {
			GB_ASSERT(b.label != nullptr && label != nullptr);
			GB_ASSERT(b.label->kind == Ast_Label);
			if (b.label == label) {
				b.break_    = break_;
				b.continue_ = continue_;
				return tl;
			}
		}

		GB_PANIC("Unreachable");
	}

	return tl;
}

gb_internal void lb_pop_target_list(lbProcedure *p) {
	p->target_list = p->target_list->prev;
}

gb_internal void lb_open_scope(lbProcedure *p, Scope *s) {
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

gb_internal void lb_close_scope(lbProcedure *p, lbDeferExitKind kind, lbBlock *block, bool pop_stack=true) {
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

gb_internal void lb_build_when_stmt(lbProcedure *p, AstWhenStmt *ws) {
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



gb_internal void lb_build_range_indexed(lbProcedure *p, lbValue expr, Type *val_type, lbValue count_ptr,
                                        lbValue *val_, lbValue *idx_, lbBlock **loop_, lbBlock **done_,
                                        bool is_reverse) {
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

	loop = lb_create_block(p, "for.index.loop");
	body = lb_create_block(p, "for.index.body");
	done = lb_create_block(p, "for.index.done");

	lbAddr index = lb_add_local_generated(p, t_int, false);

	if (!is_reverse) {
		/*
			for x, i in array {
				...
			}

			i := -1
			for {
				i += 1
				if !(i < len(array)) {
					break
				}
				#no_bounds_check x := array[i]
				...
			}
		*/

		lb_addr_store(p, index, lb_const_int(m, t_int, cast(u64)-1));

		lb_emit_jump(p, loop);
		lb_start_block(p, loop);

		lbValue incr = lb_emit_arith(p, Token_Add, lb_addr_load(p, index), lb_const_int(m, t_int, 1), t_int);
		lb_addr_store(p, index, incr);

		if (count.value == nullptr) {
			GB_ASSERT(count_ptr.value != nullptr);
			count = lb_emit_load(p, count_ptr);
		}
		lbValue cond = lb_emit_comp(p, Token_Lt, incr, count);
		lb_emit_if(p, cond, body, done);
	} else {
		// NOTE(bill): REVERSED LOGIC
		/*
			#reverse for x, i in array {
				...
			}

			i := len(array)
			for {
				i -= 1
				if i < 0 {
					break
				}
				#no_bounds_check x := array[i]
				...
			}
		*/

		if (count.value == nullptr) {
			GB_ASSERT(count_ptr.value != nullptr);
			count = lb_emit_load(p, count_ptr);
		}
		count = lb_emit_conv(p, count, t_int);
		lb_addr_store(p, index, count);

		lb_emit_jump(p, loop);
		lb_start_block(p, loop);

		lbValue incr = lb_emit_arith(p, Token_Sub, lb_addr_load(p, index), lb_const_int(m, t_int, 1), t_int);
		lb_addr_store(p, index, incr);

		lbValue anti_cond = lb_emit_comp(p, Token_Lt, incr, lb_const_int(m, t_int, 0));
		lb_emit_if(p, anti_cond, done, body);
	}

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

gb_internal lbValue lb_map_cell_index_static(lbProcedure *p, Type *type, lbValue cells_ptr, lbValue index) {
	i64 size, len;
	i64 elem_sz = type_size_of(type);
	map_cell_size_and_len(type, &size, &len);

	index = lb_emit_conv(p, index, t_uintptr);

	if (size == len*elem_sz) {
		lbValue elems_ptr = lb_emit_conv(p, cells_ptr, alloc_type_pointer(type));
		return lb_emit_ptr_offset(p, elems_ptr, index);
	}

	lbValue cell_index = {};
	lbValue data_index = {};

	lbValue size_const = lb_const_int(p->module, t_uintptr, size);
	lbValue len_const = lb_const_int(p->module, t_uintptr, len);

	if (is_power_of_two(len)) {
		u64 log2_len = floor_log2(cast(u64)len);
		cell_index = log2_len == 0 ? index : lb_emit_arith(p, Token_Shr, index, lb_const_int(p->module, t_uintptr, log2_len), t_uintptr);
		data_index = lb_emit_arith(p, Token_And, index, lb_const_int(p->module, t_uintptr, len-1), t_uintptr);
	} else {
		cell_index = lb_emit_arith(p, Token_Quo, index, len_const, t_uintptr);
		data_index = lb_emit_arith(p, Token_Mod, index, len_const, t_uintptr);
	}

	lbValue elems_ptr = lb_emit_conv(p, cells_ptr, t_uintptr);
	lbValue cell_offset = lb_emit_arith(p, Token_Mul, size_const, cell_index, t_uintptr);
	elems_ptr = lb_emit_arith(p, Token_Add, elems_ptr, cell_offset, t_uintptr);

	elems_ptr = lb_emit_conv(p, elems_ptr, alloc_type_pointer(type));

	return lb_emit_ptr_offset(p, elems_ptr, data_index);
}

gb_internal lbValue lb_map_hash_is_valid(lbProcedure *p, lbValue hash) {
	// N :: size_of(uintptr)*8 - 1
	// (hash != 0) & (hash>>N == 0)

	u64 top_bit_index = cast(u64)(type_size_of(t_uintptr)*8 - 1);
	lbValue shift_amount = lb_const_int(p->module, t_uintptr, top_bit_index);
	lbValue zero = lb_const_int(p->module, t_uintptr, 0);

	lbValue not_empty = lb_emit_comp(p, Token_NotEq, hash, zero);

	lbValue not_deleted = lb_emit_arith(p, Token_Shr, hash, shift_amount, t_uintptr);
	not_deleted = lb_emit_comp(p, Token_CmpEq, not_deleted, zero);

	return lb_emit_arith(p, Token_And, not_deleted, not_empty, t_uintptr);
}

gb_internal void lb_build_range_map(lbProcedure *p, lbValue expr, Type *val_type,
                                    lbValue *val_, lbValue *key_, lbBlock **loop_, lbBlock **done_) {
	lbModule *m = p->module;

	Type *type = base_type(type_deref(expr.type));
	GB_ASSERT(type->kind == Type_Map);

	lbValue idx = {};
	lbBlock *loop = nullptr;
	lbBlock *done = nullptr;
	lbBlock *body = nullptr;
	lbBlock *hash_check = nullptr;


	lbAddr index = lb_add_local_generated(p, t_int, false);
	lb_addr_store(p, index, lb_const_int(m, t_int, cast(u64)-1));

	loop = lb_create_block(p, "for.index.loop");
	lb_emit_jump(p, loop);
	lb_start_block(p, loop);

	lbValue incr = lb_emit_arith(p, Token_Add, lb_addr_load(p, index), lb_const_int(m, t_int, 1), t_int);
	lb_addr_store(p, index, incr);

	hash_check = lb_create_block(p, "for.index.hash_check");
	body = lb_create_block(p, "for.index.body");
	done = lb_create_block(p, "for.index.done");

	lbValue map_value = lb_emit_load(p, expr);
	lbValue capacity = lb_map_cap(p, map_value);
	lbValue cond = lb_emit_comp(p, Token_Lt, incr, capacity);
	lb_emit_if(p, cond, hash_check, done);
	lb_start_block(p, hash_check);

	idx = lb_addr_load(p, index);

	lbValue ks = lb_map_data_uintptr(p, map_value);
	lbValue vs = lb_emit_conv(p, lb_map_cell_index_static(p, type->Map.key, ks, capacity), alloc_type_pointer(type->Map.value));
	lbValue hs = lb_emit_conv(p, lb_map_cell_index_static(p, type->Map.value, vs, capacity), alloc_type_pointer(t_uintptr));

	// NOTE(bill): no need to use lb_map_cell_index_static for that hashes
	// since it will always be packed without padding into the cells
	lbValue hash = lb_emit_load(p, lb_emit_ptr_offset(p, hs, idx));

	lbValue hash_cond = lb_map_hash_is_valid(p, hash);
	lb_emit_if(p, hash_cond, body, loop);
	lb_start_block(p, body);


	lbValue key_ptr = lb_map_cell_index_static(p, type->Map.key, ks, idx);
	lbValue val_ptr = lb_map_cell_index_static(p, type->Map.value, vs, idx);
	lbValue key = lb_emit_load(p, key_ptr);
	lbValue val = lb_emit_load(p, val_ptr);

	if (val_)  *val_  = val;
	if (key_)  *key_  = key;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}



gb_internal void lb_build_range_string(lbProcedure *p, lbValue expr, Type *val_type,
                                       lbValue *val_, lbValue *idx_, lbBlock **loop_, lbBlock **done_,
                                       bool is_reverse) {
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

	loop = lb_create_block(p, "for.string.loop");
	body = lb_create_block(p, "for.string.body");
	done = lb_create_block(p, "for.string.done");

	lbAddr offset_ = lb_add_local_generated(p, t_int, false);
	lbValue offset = {};
	lbValue cond = {};

	if (!is_reverse) {
		/*
			for c, offset in str {
				...
			}

			offset := 0
			for offset < len(str) {
				c, _w := string_decode_rune(str[offset:])
				...
				offset += _w
			}
		*/
		lb_addr_store(p, offset_, lb_const_int(m, t_int, 0));

		lb_emit_jump(p, loop);
		lb_start_block(p, loop);


		offset = lb_addr_load(p, offset_);
		cond = lb_emit_comp(p, Token_Lt, offset, count);
	} else {
		// NOTE(bill): REVERSED LOGIC
		/*
			#reverse for c, offset in str {
				...
			}

			offset := len(str)
			for offset > 0 {
				c, _w := string_decode_last_rune(str[:offset])
				offset -= _w
				...
			}
		*/
		lb_addr_store(p, offset_, count);

		lb_emit_jump(p, loop);
		lb_start_block(p, loop);

		offset = lb_addr_load(p, offset_);
		cond = lb_emit_comp(p, Token_Gt, offset, lb_const_int(m, t_int, 0));
	}
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);


	lbValue rune_and_len = {};
	if (!is_reverse) {
		lbValue str_elem = lb_emit_ptr_offset(p, lb_string_elem(p, expr), offset);
		lbValue str_len  = lb_emit_arith(p, Token_Sub, count, offset, t_int);
		auto args = array_make<lbValue>(permanent_allocator(), 1);
		args[0] = lb_emit_string(p, str_elem, str_len);

		rune_and_len = lb_emit_runtime_call(p, "string_decode_rune", args);
		lbValue len  = lb_emit_struct_ev(p, rune_and_len, 1);
		lb_addr_store(p, offset_, lb_emit_arith(p, Token_Add, offset, len, t_int));

		idx = offset;
	} else {
		// NOTE(bill): REVERSED LOGIC
		lbValue str_elem = lb_string_elem(p, expr);
		lbValue str_len  = offset;
		auto args = array_make<lbValue>(permanent_allocator(), 1);
		args[0] = lb_emit_string(p, str_elem, str_len);

		rune_and_len = lb_emit_runtime_call(p, "string_decode_last_rune", args);
		lbValue len  = lb_emit_struct_ev(p, rune_and_len, 1);
		lb_addr_store(p, offset_, lb_emit_arith(p, Token_Sub, offset, len, t_int));

		idx = lb_addr_load(p, offset_);
	}


	if (val_type != nullptr) {
		val = lb_emit_struct_ev(p, rune_and_len, 0);
	}

	if (val_)  *val_  = val;
	if (idx_)  *idx_  = idx;
	if (loop_) *loop_ = loop;
	if (done_) *done_ = done;
}


gb_internal Ast *lb_strip_and_prefix(Ast *ident) {
	if (ident != nullptr) {
		if (ident->kind == Ast_UnaryExpr && ident->UnaryExpr.op.kind == Token_And) {
			ident = ident->UnaryExpr.expr;
		}
		GB_ASSERT(ident->kind == Ast_Ident);
	}
	return ident;
}



gb_internal void lb_build_range_interval(lbProcedure *p, AstBinaryExpr *node,
                                         AstRangeStmt *rs, Scope *scope) {
	bool ADD_EXTRA_WRAPPING_CHECK = true;

	lbModule *m = p->module;

	lb_open_scope(p, scope);

	Ast *val0 = rs->vals.count > 0 ? lb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? lb_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val0_type = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val1_type = type_of_expr(val1);
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
		Entity *e = entity_of_node(val0);
		value = lb_add_local(p, val0_type, e, false);
	} else {
		value = lb_add_local_generated(p, lower.type, false);
	}
	lb_addr_store(p, value, lower);

	lbAddr index;
	if (val1_type != nullptr) {
		Entity *e = entity_of_node(val1);
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
	if (val0_type) lb_store_range_stmt_val(p, val0, val);
	if (val1_type) lb_store_range_stmt_val(p, val1, idx);

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

gb_internal lbValue lb_enum_values_slice(lbProcedure *p, Type *enum_type, i64 *enum_count_) {
	Type *t = enum_type;
	GB_ASSERT(is_type_enum(t));
	t = base_type(t);
	GB_ASSERT(t->kind == Type_Enum);
	i64 enum_count = t->Enum.fields.count;

	if (enum_count_) *enum_count_ = enum_count;

	lbValue ti       = lb_type_info(p, t);
	lbValue variant  = lb_emit_struct_ep(p, ti, 4);
	lbValue eti_ptr  = lb_emit_conv(p, variant, t_type_info_enum_ptr);
	lbValue values   = lb_emit_load(p, lb_emit_struct_ep(p, eti_ptr, 2));
	return values;
}

gb_internal void lb_build_range_enum(lbProcedure *p, Type *enum_type, Type *val_type, lbValue *val_, lbValue *idx_, lbBlock **loop_, lbBlock **done_) {
	lbModule *m = p->module;

	Type *t = enum_type;
	GB_ASSERT(is_type_enum(t));
	t = base_type(t);
	Type *core_elem = core_type(t);
	i64 enum_count = 0;

	lbValue values      = lb_enum_values_slice(p, enum_type, &enum_count);
	lbValue values_data = lb_slice_elem(p, values);
	lbValue max_count   = lb_const_int(m, t_int, enum_count);

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

gb_internal void lb_build_range_tuple(lbProcedure *p, AstRangeStmt *rs, Scope *scope) {
	Ast *expr = unparen_expr(rs->expr);

	Type *expr_type = type_of_expr(expr);
	Type *et = base_type(type_deref(expr_type));
	GB_ASSERT(et->kind == Type_Tuple);

	i32 value_count = cast(i32)et->Tuple.variables.count;

	lbValue *values = gb_alloc_array(permanent_allocator(), lbValue, value_count);

	lb_open_scope(p, scope);

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

	lbValue cond = lb_emit_tuple_ev(p, tuple_value, cond_index);
	lb_emit_if(p, cond, body, done);
	lb_start_block(p, body);

	for (i32 i = 0; i < value_count; i++) {
		values[i] = lb_emit_tuple_ev(p, tuple_value, i);
	}

	GB_ASSERT(rs->vals.count <= value_count);
	for (isize i = 0; i < rs->vals.count; i++) {
		Ast *val = rs->vals[i];
		if (val != nullptr) {
			lb_store_range_stmt_val(p, val, values[i]);
		}
	}

	lb_push_target_list(p, rs->label, done, loop, nullptr);

	lb_build_stmt(p, rs->body);

	lb_close_scope(p, lbDeferExit_Default, nullptr);
	lb_pop_target_list(p);
	lb_emit_jump(p, loop);
	lb_start_block(p, done);
}

gb_internal void lb_build_range_stmt_struct_soa(lbProcedure *p, AstRangeStmt *rs, Scope *scope) {
	Ast *expr = unparen_expr(rs->expr);
	TypeAndValue tav = type_and_value_of_expr(expr);

	lbBlock *loop = nullptr;
	lbBlock *body = nullptr;
	lbBlock *done = nullptr;

	bool is_reverse = rs->reverse;

	lb_open_scope(p, scope);


	Ast *val0 = rs->vals.count > 0 ? lb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? lb_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val_types[2] = {};
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val_types[0] = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val_types[1] = type_of_expr(val1);
	}



	lbAddr array = lb_build_addr(p, expr);
	if (is_type_pointer(lb_addr_type(array))) {
		array = lb_addr(lb_addr_load(p, array));
	}
	lbValue count = lb_soa_struct_len(p, lb_addr_load(p, array));


	lbAddr index = lb_add_local_generated(p, t_int, false);

	if (!is_reverse) {
		/*
			for x, i in array {
				...
			}

			i := -1
			for {
				i += 1
				if !(i < len(array)) {
					break
				}
				x := array[i] // but #soa-ified
				...
			}
		*/

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
	} else {
		// NOTE(bill): REVERSED LOGIC
		/*
			#reverse for x, i in array {
				...
			}

			i := len(array)
			for {
				i -= 1
				if i < 0 {
					break
				}
				#no_bounds_check x := array[i] // but #soa-ified
				...
			}
		*/
		lb_addr_store(p, index, count);

		loop = lb_create_block(p, "for.soa.loop");
		lb_emit_jump(p, loop);
		lb_start_block(p, loop);

		lbValue incr = lb_emit_arith(p, Token_Sub, lb_addr_load(p, index), lb_const_int(p->module, t_int, 1), t_int);
		lb_addr_store(p, index, incr);

		body = lb_create_block(p, "for.soa.body");
		done = lb_create_block(p, "for.soa.done");

		lbValue cond = lb_emit_comp(p, Token_Lt, incr, lb_const_int(p->module, t_int, 0));
		lb_emit_if(p, cond, done, body);
	}
	lb_start_block(p, body);


	if (val_types[0]) {
		Entity *e = entity_of_node(val0);
		if (e != nullptr) {
			lbAddr soa_val = lb_addr_soa_variable(array.addr, lb_addr_load(p, index), nullptr);
			map_set(&p->module->soa_values, e, soa_val);
		}
	}
	if (val_types[1]) {
		lb_store_range_stmt_val(p, val1, lb_addr_load(p, index));
	}


	lb_push_target_list(p, rs->label, done, loop, nullptr);

	lb_build_stmt(p, rs->body);

	lb_close_scope(p, lbDeferExit_Default, nullptr);
	lb_pop_target_list(p);
	lb_emit_jump(p, loop);
	lb_start_block(p, done);

}

gb_internal void lb_build_range_stmt(lbProcedure *p, AstRangeStmt *rs, Scope *scope) {
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

	TypeAndValue tav = type_and_value_of_expr(expr);
	if (tav.mode != Addressing_Type) {
		Type *expr_type = type_of_expr(expr);
		Type *et = base_type(type_deref(expr_type));
		if (et->kind == Type_Tuple) {
			lb_build_range_tuple(p, rs, scope);
			return;
		}
	}


	lb_open_scope(p, scope);

	Ast *val0 = rs->vals.count > 0 ? lb_strip_and_prefix(rs->vals[0]) : nullptr;
	Ast *val1 = rs->vals.count > 1 ? lb_strip_and_prefix(rs->vals[1]) : nullptr;
	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val0_type = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val1_type = type_of_expr(val1);
	}

	lbValue val = {};
	lbValue key = {};
	lbBlock *loop = nullptr;
	lbBlock *done = nullptr;
	bool is_map = false;

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
			lb_build_range_map(p, map, val1_type, &val, &key, &loop, &done);
			break;
		}
		case Type_Array: {
			lbValue array = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = lb_emit_load(p, array);
			}
			lbAddr count_ptr = lb_add_local_generated(p, t_int, false);
			lb_addr_store(p, count_ptr, lb_const_int(p->module, t_int, et->Array.count));
			lb_build_range_indexed(p, array, val0_type, count_ptr.addr, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_EnumeratedArray: {
			lbValue array = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = lb_emit_load(p, array);
			}
			lbAddr count_ptr = lb_add_local_generated(p, t_int, false);
			lb_addr_store(p, count_ptr, lb_const_int(p->module, t_int, et->EnumeratedArray.count));
			lb_build_range_indexed(p, array, val0_type, count_ptr.addr, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_DynamicArray: {
			lbValue count_ptr = {};
			lbValue array = lb_build_addr_ptr(p, expr);
			if (is_type_pointer(type_deref(array.type))) {
				array = lb_emit_load(p, array);
			}
			count_ptr = lb_emit_struct_ep(p, array, 1);
			lb_build_range_indexed(p, array, val0_type, count_ptr, &val, &key, &loop, &done, rs->reverse);
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
			lb_build_range_indexed(p, slice, val0_type, count_ptr, &val, &key, &loop, &done, rs->reverse);
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
			lb_build_range_string(p, string, val0_type, &val, &key, &loop, &done, rs->reverse);
			break;
		}
		case Type_Tuple:
			GB_PANIC("Should be handled already");

		case Type_BitSet: {
			lbModule *m = p->module;

			lbValue the_set = lb_build_expr(p, expr);
			if (is_type_pointer(type_deref(the_set.type))) {
				the_set = lb_emit_load(p, the_set);
			}

			Type *elem = et->BitSet.elem;
			if (is_type_enum(elem)) {
				i64 enum_count = 0;
				lbValue values      = lb_enum_values_slice(p, elem, &enum_count);
				lbValue values_data = lb_slice_elem(p, values);
				lbValue max_count   = lb_const_int(m, t_int, enum_count);

				lbAddr offset_ = lb_add_local_generated(p, t_int, false);
				lb_addr_store(p, offset_, lb_const_int(m, t_int, 0));

				loop = lb_create_block(p, "for.bit_set.enum.loop");
				lb_emit_jump(p, loop);
				lb_start_block(p, loop);

				lbBlock *body_check = lb_create_block(p, "for.bit_set.enum.body-check");
				lbBlock *body = lb_create_block(p, "for.bit_set.enum.body");
				done = lb_create_block(p, "for.bit_set.enum.done");

				lbValue offset = lb_addr_load(p, offset_);
				lbValue cond = lb_emit_comp(p, Token_Lt, offset, max_count);
				lb_emit_if(p, cond, body_check, done);
				lb_start_block(p, body_check);

				lbValue val_ptr = lb_emit_ptr_offset(p, values_data, offset);
				lb_emit_increment(p, offset_.addr);
				val = lb_emit_load(p, val_ptr);
				val = lb_emit_conv(p, val, elem);

				lbValue check = lb_build_binary_in(p, val, the_set, Token_in);
				lb_emit_if(p, check, body, loop);
				lb_start_block(p, body);
			} else {
				lbAddr offset_ = lb_add_local_generated(p, t_int, false);
				lb_addr_store(p, offset_, lb_const_int(m, t_int, et->BitSet.lower));

				lbValue max_count = lb_const_int(m, t_int, et->BitSet.upper);

				loop = lb_create_block(p, "for.bit_set.range.loop");
				lb_emit_jump(p, loop);
				lb_start_block(p, loop);

				lbBlock *body_check = lb_create_block(p, "for.bit_set.range.body-check");
				lbBlock *body = lb_create_block(p, "for.bit_set.range.body");
				done = lb_create_block(p, "for.bit_set.range.done");

				lbValue offset = lb_addr_load(p, offset_);
				lbValue cond = lb_emit_comp(p, Token_LtEq, offset, max_count);
				lb_emit_if(p, cond, body_check, done);
				lb_start_block(p, body_check);

				val = lb_emit_conv(p, offset, elem);
				lb_emit_increment(p, offset_.addr);

				lbValue check = lb_build_binary_in(p, val, the_set, Token_in);
				lb_emit_if(p, check, body, loop);
				lb_start_block(p, body);
			}
			break;
		}
		default:
			GB_PANIC("Cannot range over %s", type_to_string(expr_type));
			break;
		}
	}


	if (is_map) {
		if (val0_type) lb_store_range_stmt_val(p, val0, key);
		if (val1_type) lb_store_range_stmt_val(p, val1, val);
	} else {
		if (val0_type) lb_store_range_stmt_val(p, val0, val);
		if (val1_type) lb_store_range_stmt_val(p, val1, key);
	}

	lb_push_target_list(p, rs->label, done, loop, nullptr);

	lb_build_stmt(p, rs->body);

	lb_close_scope(p, lbDeferExit_Default, nullptr);
	lb_pop_target_list(p);
	lb_emit_jump(p, loop);
	lb_start_block(p, done);
}

gb_internal void lb_build_unroll_range_stmt(lbProcedure *p, AstUnrollRangeStmt *rs, Scope *scope) {
	lbModule *m = p->module;

	lb_open_scope(p, scope); // Open scope here

	Ast *val0 = lb_strip_and_prefix(rs->val0);
	Ast *val1 = lb_strip_and_prefix(rs->val1);
	Type *val0_type = nullptr;
	Type *val1_type = nullptr;
	if (val0 != nullptr && !is_blank_ident(val0)) {
		val0_type = type_of_expr(val0);
	}
	if (val1 != nullptr && !is_blank_ident(val1)) {
		val1_type = type_of_expr(val1);
	}

	if (val0_type != nullptr) {
		Entity *e = entity_of_node(val0);
		lb_add_local(p, e->type, e, true);
	}
	if (val1_type != nullptr) {
		Entity *e = entity_of_node(val1);
		lb_add_local(p, e->type, e, true);
	}

	lbValue val = {};
	lbValue key = {};
	Ast *expr = unparen_expr(rs->expr);

	TypeAndValue tav = type_and_value_of_expr(expr);

	if (is_ast_range(expr)) {

		lbAddr val0_addr = {};
		lbAddr val1_addr = {};
		if (val0_type) val0_addr = lb_build_addr(p, val0);
		if (val1_type) val1_addr = lb_build_addr(p, val1);

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
		if (val0_type) val0_addr = lb_build_addr(p, val0);
		if (val1_type) val1_addr = lb_build_addr(p, val1);

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
		if (val0_type) val0_addr = lb_build_addr(p, val0);
		if (val1_type) val1_addr = lb_build_addr(p, val1);

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

gb_internal bool lb_switch_stmt_can_be_trivial_jump_table(AstSwitchStmt *ss, bool *default_found_) {
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
	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);

		if (cc->list.count == 0) {
			if (default_found_) *default_found_ = true;
			continue;
		}

		for (Ast *expr : cc->list) {
			expr = unparen_expr(expr);
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


gb_internal void lb_build_switch_stmt(lbProcedure *p, AstSwitchStmt *ss, Scope *scope) {
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
		for (Ast *clause : body->stmts) {
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
		for (Ast *expr : cc->list) {
			expr = unparen_expr(expr);

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

gb_internal void lb_store_type_case_implicit(lbProcedure *p, Ast *clause, lbValue value, bool is_default_case) {
	Entity *e = implicit_entity_of_node(clause);
	GB_ASSERT(e != nullptr);
	if (e->flags & EntityFlag_Value) {
		// by value
		GB_ASSERT(are_types_identical(e->type, value.type));
		lbAddr x = lb_add_local(p, e->type, e, false);
		lb_addr_store(p, x, value);
	} else {
		if (!is_default_case) {
			Type *clause_type = e->type;
			GB_ASSERT_MSG(are_types_identical(type_deref(clause_type), type_deref(value.type)), "%s %s", type_to_string(clause_type), type_to_string(value.type));
		}
		lb_add_entity(p->module, e, value);
	}
}

gb_internal lbAddr lb_store_range_stmt_val(lbProcedure *p, Ast *stmt_val, lbValue value) {
	Entity *e = entity_of_node(stmt_val);
	if (e == nullptr) {
		return {};
	}

	if ((e->flags & EntityFlag_Value) == 0) {
		if (LLVMIsALoadInst(value.value)) {
			lbValue ptr = lb_address_from_load_or_generate_local(p, value);
			lb_add_entity(p->module, e, ptr);
			lb_add_debug_local_variable(p, ptr.value, e->type, e->token);
			return lb_addr(ptr);
		}
	}

	// by value
	lbAddr addr = lb_add_local(p, e->type, e, false);
	lb_addr_store(p, addr, value);
	return addr;
}

gb_internal void lb_type_case_body(lbProcedure *p, Ast *label, Ast *clause, lbBlock *body, lbBlock *done) {
	ast_node(cc, CaseClause, clause);

	lb_push_target_list(p, label, done, nullptr, nullptr);
	lb_build_stmt_list(p, cc->stmts);
	lb_close_scope(p, lbDeferExit_Default, body);
	lb_pop_target_list(p);

	lb_emit_jump(p, done);
}

gb_internal void lb_build_type_switch_stmt(lbProcedure *p, AstTypeSwitchStmt *ss) {
	lbModule *m = p->module;
	lb_open_scope(p, ss->scope);

	ast_node(as, AssignStmt, ss->tag);
	GB_ASSERT(as->lhs.count == 1);
	GB_ASSERT(as->rhs.count == 1);

	lbValue parent = lb_build_expr(p, as->rhs[0]);
	bool is_parent_ptr = is_type_pointer(parent.type);
	Type *parent_base_type = type_deref(parent.type);

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
		Type *union_type = type_deref(parent_ptr.type);
		if (is_type_union_maybe_pointer(union_type)) {
			tag = lb_emit_conv(p, lb_emit_comp_against_nil(p, Token_NotEq, union_data), t_int);
		} else if (union_tag_size(union_type) == 0) {
			tag = {}; // there is no tag for a zero sized union
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

	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);
		num_cases += cc->list.count;
		if (cc->list.count == 0) {
			GB_ASSERT(default_block == nullptr);
			default_block = lb_create_block(p, "typeswitch.default.body");
			else_block = default_block;
		}
	}


	LLVMValueRef switch_instr = nullptr;
	if (type_size_of(parent_base_type) == 0) {
		GB_ASSERT(tag.value == nullptr);
		switch_instr = LLVMBuildSwitch(p->builder, lb_const_bool(p->module, t_llvm_bool, false).value, else_block->block, cast(unsigned)num_cases);
	} else {
		GB_ASSERT(tag.value != nullptr);
		switch_instr = LLVMBuildSwitch(p->builder, tag.value, else_block->block, cast(unsigned)num_cases);
	}

	bool all_by_reference = false;
	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);
		if (cc->list.count != 1) {
			continue;
		}
		Entity *case_entity = implicit_entity_of_node(clause);
		all_by_reference |= (case_entity->flags & EntityFlag_Value) == 0;
		break;
	}

	// NOTE(bill, 2023-02-17): In the case of a pass by value, the value does need to be copied
	// to prevent errors such as these:
	//
	//	switch v in some_union {
	//	case i32:
	//		fmt.println(v) // 'i32'
	//		some_union = f32(123)
	//		fmt.println(v) // if `v` is an implicit reference, then the data is now completely corrupted
	//	case f32:
	//		fmt.println(v)
	//	}
	//
	lbAddr backing_data = {};
	if (!all_by_reference) {
		bool variants_found = false;
		i64 max_size = 0;
		i64 max_align = 1;
		for (Ast *clause : body->stmts) {
			ast_node(cc, CaseClause, clause);
			if (cc->list.count != 1) {
				continue;
			}
			Entity *case_entity = implicit_entity_of_node(clause);
			if (!is_type_untyped_nil(case_entity->type)) {
				max_size = gb_max(max_size, type_size_of(case_entity->type));
				max_align = gb_max(max_align, type_align_of(case_entity->type));
				variants_found = true;
			}
		}
		if (variants_found) {
			Type *t = alloc_type_array(t_u8, max_size);
			backing_data = lb_add_local(p, t, nullptr, false, true);
			GB_ASSERT(lb_try_update_alignment(backing_data.addr, cast(unsigned)max_align));
		}
	}
	lbValue backing_ptr = backing_data.addr;

	for (Ast *clause : body->stmts) {
		ast_node(cc, CaseClause, clause);

		Entity *case_entity = implicit_entity_of_node(clause);
		lb_open_scope(p, cc->scope);

		if (cc->list.count == 0) {
			lb_start_block(p, default_block);
			if (case_entity->flags & EntityFlag_Value) {
				lb_store_type_case_implicit(p, clause, parent_value, true);
			} else {
				lb_store_type_case_implicit(p, clause, parent_ptr, true);
			}
			lb_type_case_body(p, ss->label, clause, p->curr_block, done);
			continue;
		}

		lbBlock *body = lb_create_block(p, "typeswitch.body");
		if (p->debug_info != nullptr) {
			LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_ast(p, clause));
		}

		bool saw_nil = false;
		for (Ast *type_expr : cc->list) {
			Type *case_type = type_of_expr(type_expr);
			lbValue on_val = {};
			if (switch_kind == TypeSwitch_Union) {
				Type *ut = base_type(type_deref(parent.type));
				on_val = lb_const_union_tag(m, ut, case_type);

			} else if (switch_kind == TypeSwitch_Any) {
				if (is_type_untyped_nil(case_type)) {
					saw_nil = true;
					on_val = lb_const_nil(m, t_typeid);
				} else {
					on_val = lb_typeid(m, case_type);
				}
			}
			GB_ASSERT(on_val.value != nullptr);
			LLVMAddCase(switch_instr, on_val.value, body->block);
		}


		lb_start_block(p, body);

		bool by_reference = (case_entity->flags & EntityFlag_Value) == 0;

		if (cc->list.count == 1 && !saw_nil) {
			lbValue data = {};
			if (switch_kind == TypeSwitch_Union) {
				data = union_data;
			} else if (switch_kind == TypeSwitch_Any) {
				data = lb_emit_load(p, lb_emit_struct_ep(p, parent_ptr, 0));
			}
			GB_ASSERT(is_type_pointer(data.type));

			Type *ct = case_entity->type;
			Type *ct_ptr = alloc_type_pointer(ct);

			lbValue ptr = {};

			if (backing_data.addr.value) { // by value
				GB_ASSERT(!by_reference);
				// make a copy of the case value
				lb_mem_copy_non_overlapping(p,
				                            backing_ptr, // dst
				                            data,        // src
				                            lb_const_int(p->module, t_int, type_size_of(case_entity->type)));
				ptr = lb_emit_conv(p, backing_ptr, ct_ptr);

			} else { // by reference
				GB_ASSERT(by_reference);
				ptr = lb_emit_conv(p, data, ct_ptr);
			}
			GB_ASSERT(are_types_identical(case_entity->type, type_deref(ptr.type)));
			lb_add_entity(p->module, case_entity, ptr);
			lb_add_debug_local_variable(p, ptr.value, case_entity->type, case_entity->token);
		} else {
			lb_store_type_case_implicit(p, clause, parent_value, false);
		}

		lb_type_case_body(p, ss->label, clause, body, done);
	}

	lb_emit_jump(p, done);
	lb_start_block(p, done);
	lb_close_scope(p, lbDeferExit_Default, done);
}


gb_internal void lb_build_static_variables(lbProcedure *p, AstValueDecl *vd) {
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
		}
		if (e->Variable.is_rodata) {
			LLVMSetGlobalConstant(global, true);
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
gb_internal isize lb_append_tuple_values(lbProcedure *p, Array<lbValue> *dst_values, lbValue src_value) {
	isize init_count = dst_values->count;
	Type *t = src_value.type;
	if (t->kind == Type_Tuple) {
		lbTupleFix *tf = map_get(&p->tuple_fix_map, src_value.value);
		if (tf) {
			for (lbValue const &value : tf->values) {
				array_add(dst_values, value);
			}
		} else {
			for_array(i, t->Tuple.variables) {
				lbValue v = lb_emit_tuple_ev(p, src_value, cast(i32)i);
				array_add(dst_values, v);
			}
		}
	} else {
		array_add(dst_values, src_value);
	}
	return dst_values->count - init_count;
}


gb_internal void lb_build_assignment(lbProcedure *p, Array<lbAddr> &lvals, Slice<Ast *> const &values) {
	if (values.count == 0) {
		return;
	}

	auto inits = array_make<lbValue>(permanent_allocator(), 0, lvals.count);

	for (Ast *rhs : values) {
		lbValue init = lb_build_expr(p, rhs);
		lb_append_tuple_values(p, &inits, init);
	}

	bool prev_in_assignment = p->in_multi_assignment;

	isize lval_count = 0;
	for (lbAddr const &lval : lvals) {
		if (lval.addr.value != nullptr) {
			// check if it is not a blank identifier
			lval_count += 1;
		}
	}
	p->in_multi_assignment = lval_count > 1;

	GB_ASSERT(lvals.count == inits.count);
	for_array(i, inits) {
		lbAddr lval = lvals[i];
		lbValue init = inits[i];
		lb_addr_store(p, lval, init);
	}

	p->in_multi_assignment = prev_in_assignment;
}

gb_internal void lb_build_return_stmt_internal(lbProcedure *p, lbValue res) {
	lbFunctionType *ft = lb_get_function_type(p->module, p->type);
	bool return_by_pointer = ft->ret.kind == lbArg_Indirect;
	bool split_returns = ft->multiple_return_original_type != nullptr;

	if (split_returns) {
		GB_ASSERT(res.value == nullptr || !is_type_tuple(res.type));
	}

	if (return_by_pointer) {
		if (res.value != nullptr) {
			LLVMValueRef res_val = res.value;
			i64 sz = type_size_of(res.type);
			if (LLVMIsALoadInst(res_val) && sz > build_context.int_size) {
				lbValue ptr = lb_address_from_load_or_generate_local(p, res);
				lb_mem_copy_non_overlapping(p, p->return_ptr.addr, ptr, lb_const_int(p->module, t_int, sz));
			} else {
				LLVMBuildStore(p->builder, res_val, p->return_ptr.addr.value);
			}
		} else {
			LLVMBuildStore(p->builder, LLVMConstNull(p->abi_function_type->ret.type), p->return_ptr.addr.value);
		}

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);

		// Check for terminator in the defer stmts
		LLVMValueRef instr = LLVMGetLastInstruction(p->curr_block->block);
		if (!lb_is_instr_terminating(instr)) {
			LLVMBuildRetVoid(p->builder);
		}
	} else {
		LLVMValueRef ret_val = res.value;
		LLVMTypeRef ret_type = p->abi_function_type->ret.type;
		if (LLVMTypeRef cast_type = p->abi_function_type->ret.cast_type) {
			ret_type = cast_type;
		}

		if (LLVMGetTypeKind(ret_type) == LLVMStructTypeKind) {
			LLVMTypeRef src_type = LLVMTypeOf(ret_val);

			if (p->temp_callee_return_struct_memory == nullptr) {
				i64 max_align = gb_max(lb_alignof(ret_type), lb_alignof(src_type));
				p->temp_callee_return_struct_memory = llvm_alloca(p, ret_type, max_align);
			}
			// reuse the temp return value memory where possible
			LLVMValueRef ptr = p->temp_callee_return_struct_memory;
			LLVMValueRef nptr = LLVMBuildPointerCast(p->builder, ptr, LLVMPointerType(src_type, 0), "");
			LLVMBuildStore(p->builder, ret_val, nptr);
			ret_val = LLVMBuildLoad2(p->builder, ret_type, ptr, "");
		} else {
			ret_val = OdinLLVMBuildTransmute(p, ret_val, ret_type);
		}

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);

		// Check for terminator in the defer stmts
		LLVMValueRef instr = LLVMGetLastInstruction(p->curr_block->block);
		if (!lb_is_instr_terminating(instr)) {
			LLVMBuildRet(p->builder, ret_val);
		}
	}
}
gb_internal void lb_build_return_stmt(lbProcedure *p, Slice<Ast *> const &return_results) {
	lb_ensure_abi_function_type(p->module, p);

	lbValue res = {};

	TypeTuple *tuple  = &p->type->Proc.results->Tuple;
	isize return_count = p->type->Proc.result_count;
	isize res_count = return_results.count;

	lbFunctionType *ft = lb_get_function_type(p->module, p->type);
	bool return_by_pointer = ft->ret.kind == lbArg_Indirect;

	if (return_count == 0) {
		// No return values

		lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
		
		// Check for terminator in the defer stmts
		LLVMValueRef instr = LLVMGetLastInstruction(p->curr_block->block);
		if (!lb_is_instr_terminating(instr)) {
			LLVMBuildRetVoid(p->builder);
		}
		return;
	} else if (return_count == 1) {
		Entity *e = tuple->variables[0];
		if (res_count == 0) {
			rw_mutex_shared_lock(&p->module->values_mutex);
			lbValue found = map_must_get(&p->module->values, e);
			rw_mutex_shared_unlock(&p->module->values_mutex);
			res = lb_emit_load(p, found);
		} else {
			res = lb_build_expr(p, return_results[0]);
			res = lb_emit_conv(p, res, e->type);
		}
		if (p->type->Proc.has_named_results) {
			// NOTE(bill): store the named values before returning
			if (e->token.string != "") {
				rw_mutex_shared_lock(&p->module->values_mutex);
				lbValue found = map_must_get(&p->module->values, e);
				rw_mutex_shared_unlock(&p->module->values_mutex);
				lb_emit_store(p, found, lb_emit_conv(p, res, e->type));
			}
		}

	} else {
		auto results = array_make<lbValue>(permanent_allocator(), 0, return_count);

		if (res_count != 0) {
			for (isize res_index = 0; res_index < res_count; res_index++) {
				lbValue res = lb_build_expr(p, return_results[res_index]);
				lb_append_tuple_values(p, &results, res);
			}
		} else {
			for (isize res_index = 0; res_index < return_count; res_index++) {
				Entity *e = tuple->variables[res_index];
				rw_mutex_shared_lock(&p->module->values_mutex);
				lbValue found = map_must_get(&p->module->values, e);
				rw_mutex_shared_unlock(&p->module->values_mutex);
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
				rw_mutex_shared_lock(&p->module->values_mutex);
				named_results[i] = map_must_get(&p->module->values, e);
				rw_mutex_shared_unlock(&p->module->values_mutex);
				values[i] = lb_emit_conv(p, results[i], e->type);
			}

			for_array(i, named_results) {
				lb_emit_store(p, named_results[i], values[i]);
			}
		}

		bool split_returns = ft->multiple_return_original_type != nullptr;
		if (split_returns) {
			auto result_values = slice_make<lbValue>(temporary_allocator(), results.count);
			auto result_eps = slice_make<lbValue>(temporary_allocator(), results.count-1);

			for_array(i, results) {
				result_values[i] = lb_emit_conv(p, results[i], tuple->variables[i]->type);
			}

			isize param_offset = return_by_pointer ? 1 : 0;
			param_offset += ft->original_arg_count;
			for_array(i, result_eps) {
				lbValue result_ep = {};
				result_ep.value = LLVMGetParam(p->value, cast(unsigned)(param_offset+i));
				result_ep.type = alloc_type_pointer(tuple->variables[i]->type);
				result_eps[i] = result_ep;
			}
			for_array(i, result_eps) {
				lb_emit_store(p, result_eps[i], result_values[i]);
			}
			if (return_by_pointer) {
				GB_ASSERT(result_values.count-1 == result_eps.count);
				lb_addr_store(p, p->return_ptr, result_values[result_values.count-1]);

				lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
				LLVMBuildRetVoid(p->builder);
				return;
			} else {
				return lb_build_return_stmt_internal(p, result_values[result_values.count-1]);
			}

		} else {
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
			for_array(i, result_eps) {
				lb_emit_store(p, result_eps[i], result_values[i]);
			}

			if (return_by_pointer) {
				lb_emit_defer_stmts(p, lbDeferExit_Return, nullptr);
				LLVMBuildRetVoid(p->builder);
				return;
			}

			res = lb_emit_load(p, res);
		}
	}
	lb_build_return_stmt_internal(p, res);
}

gb_internal void lb_build_if_stmt(lbProcedure *p, Ast *node) {
	ast_node(is, IfStmt, node);
	lb_open_scope(p, is->scope); // Scope #1
	defer (lb_close_scope(p, lbDeferExit_Default, nullptr));

	lbBlock *then = lb_create_block(p, "if.then");
	lbBlock *done = lb_create_block(p, "if.done");
	lbBlock *else_ = done;
	if (is->else_stmt != nullptr) {
		else_ = lb_create_block(p, "if.else");
	}
	if (is->label != nullptr) {
		lbTargetList *tl = lb_push_target_list(p, is->label, done, nullptr, nullptr);
		tl->is_block = true;
	}
	if (is->init != nullptr) {
		lbBlock *init = lb_create_block(p, "if.init");
		lb_emit_jump(p, init);
		lb_start_block(p, init);

		lb_build_stmt(p, is->init);
	}

	lbValue cond = lb_build_cond(p, is->cond, then, else_);
	// Note `cond.value` only set for non-and/or conditions and const negs so that the `LLVMIsConstant()`
	// and `LLVMConstIntGetZExtValue()` calls below will be valid and `LLVMInstructionEraseFromParent()`
	// will target the correct (& only) branch statement


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

gb_internal void lb_build_for_stmt(lbProcedure *p, Ast *node) {
	ast_node(fs, ForStmt, node);

	lb_open_scope(p, fs->scope); // Open Scope here
	if (p->debug_info != nullptr) {
		LLVMSetCurrentDebugLocation2(p->builder, lb_debug_location_from_ast(p, node));
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

	lb_push_target_list(p, fs->label, done, post, nullptr);

	if (fs->init != nullptr) {
	#if 1
		lbBlock *init = lb_create_block(p, "for.init");
		lb_emit_jump(p, init);
		lb_start_block(p, init);
	#endif
		lb_build_stmt(p, fs->init);
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

gb_internal void lb_build_assign_stmt_array(lbProcedure *p, TokenKind op, lbAddr const &lhs, lbValue const &value) {
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
		for (i32 index : lhs.swizzle_large.indices) {
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
gb_internal void lb_build_assign_stmt(lbProcedure *p, AstAssignStmt *as) {
	if (as->op.kind == Token_Eq) {
		auto lvals = array_make<lbAddr>(permanent_allocator(), 0, as->lhs.count);

		for (Ast *lhs : as->lhs) {
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


gb_internal void lb_build_stmt(lbProcedure *p, Ast *node) {
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
			for (Ast *name : vd->names) {
				if (!is_blank_ident(name)) {
					GB_ASSERT(name->kind == Ast_Ident);
					Entity *e = entity_of_node(name);
					TokenPos pos = ast_token(name).pos;
					GB_ASSERT_MSG(e != nullptr, "\n%s missing entity for %.*s", token_pos_to_string(pos), LIT(name->Ident.token.string));
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

		TEMPORARY_ALLOCATOR_GUARD();

		auto const &values = vd->values;
		if (values.count == 0) {
			auto lvals = slice_make<lbAddr>(temporary_allocator(), vd->names.count);
			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				if (!is_blank_ident(name)) {
					Entity *e = entity_of_node(name);
					// bool zero_init = true; // Always do it
					bool zero_init = values.count == 0;
					lvals[i] = lb_add_local(p, e->type, e, zero_init);
				}
			}
		} else {
			auto lvals_preused = slice_make<bool>(temporary_allocator(), vd->names.count);
			auto lvals = slice_make<lbAddr>(temporary_allocator(), vd->names.count);
			auto inits = array_make<lbValue>(temporary_allocator(), 0, lvals.count);

			isize lval_index = 0;
			for (Ast *rhs : values) {
				rhs = unparen_expr(rhs);
				lbValue init = lb_build_expr(p, rhs);

				if (rhs->kind == Ast_CompoundLit) {
					// NOTE(bill, 2023-02-17): lb_const_value might produce a stack local variable for the
					// compound literal, so reusing that variable should minimize the stack wastage
					lbAddr *comp_lit_addr = map_get(&p->module->exact_value_compound_literal_addr_map, rhs);
					if (comp_lit_addr) {
						if (Entity *e = entity_of_node(vd->names[lval_index])) {
							lbValue val = comp_lit_addr->addr;
							lb_add_entity(p->module, e, val);
							lb_add_debug_local_variable(p, val.value, e->type, e->token);
							lvals_preused[lval_index] = true;
							lvals[lval_index] = *comp_lit_addr;
						}
					}
				}

				lval_index += lb_append_tuple_values(p, &inits, init);
			}
			GB_ASSERT(lval_index == lvals.count);


			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				if (!is_blank_ident(name) && !lvals_preused[i]) {
					Entity *e = entity_of_node(name);
					bool zero_init = values.count == 0;
					lvals[i] = lb_add_local(p, e->type, e, zero_init);
				}
			}

			GB_ASSERT(lvals.count == inits.count);
			for_array(i, inits) {
				lbAddr lval = lvals[i];
				lbValue init = inits[i];
				lb_addr_store(p, lval, init);
			}
		}
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




gb_internal void lb_build_defer_stmt(lbProcedure *p, lbDefer const &d) {
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

gb_internal void lb_emit_defer_stmts(lbProcedure *p, lbDeferExitKind kind, lbBlock *block) {
	isize count = p->defer_stmts.count;
	isize i = count;
	while (i --> 0) {
		lbDefer const &d = p->defer_stmts[i];

		if (kind == lbDeferExit_Default) {
			if (p->scope_index == d.scope_index &&
			    d.scope_index > 0) {
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

gb_internal void lb_add_defer_node(lbProcedure *p, isize scope_index, Ast *stmt) {
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

gb_internal void lb_add_defer_proc(lbProcedure *p, isize scope_index, lbValue deferred, Array<lbValue> const &result_as_args) {
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
