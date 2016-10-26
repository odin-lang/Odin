void    ssa_emit_jump           (ssaProcedure *proc, ssaBlock *block);
void    ssa_build_stmt          (ssaProcedure *proc, AstNode *s);
ssaAddr ssa_build_addr          (ssaProcedure *proc, AstNode *expr);
void    ssa_build_proc          (ssaValue *value, ssaProcedure *parent);
void    ssa_gen_global_type_name(ssaModule *m, Entity *e, String name);




void ssa_push_target_list(ssaProcedure *proc, ssaBlock *break_, ssaBlock *continue_, ssaBlock *fallthrough_) {
	ssaTargetList *tl = gb_alloc_item(proc->module->allocator, ssaTargetList);
	tl->prev          = proc->target_list;
	tl->break_        = break_;
	tl->continue_     = continue_;
	tl->fallthrough_  = fallthrough_;
	proc->target_list = tl;
}

void ssa_pop_target_list(ssaProcedure *proc) {
	proc->target_list = proc->target_list->prev;
}


void ssa_mangle_sub_type_name(ssaModule *m, Entity *field, String parent) {
	if (field->kind != Entity_TypeName) {
		return;
	}
	String cn = field->token.string;

	isize len = parent.len + 1 + cn.len;
	String child = {NULL, len};
	child.text = gb_alloc_array(m->allocator, u8, len);

	isize i = 0;
	gb_memmove(child.text+i, parent.text, parent.len);
	i += parent.len;
	child.text[i++] = '.';
	gb_memmove(child.text+i, cn.text, cn.len);

	map_set(&m->type_names, hash_pointer(field->type), child);
	ssa_gen_global_type_name(m, field, child);
}

void ssa_gen_global_type_name(ssaModule *m, Entity *e, String name) {
	ssaValue *t = ssa_make_value_type_name(m->allocator, name, e->type);
	ssa_module_add_value(m, e, t);
	map_set(&m->members, hash_string(name), t);

	Type *bt = base_type(e->type);
	if (bt->kind == Type_Record) {
		auto *s = &bt->Record;
		for (isize j = 0; j < s->other_field_count; j++) {
			ssa_mangle_sub_type_name(m, s->other_fields[j], name);
		}
	}

	if (is_type_union(bt)) {
		auto *s = &bt->Record;
		// NOTE(bill): Zeroth entry is null (for `match type` stmts)
		for (isize j = 1; j < s->field_count; j++) {
			ssa_mangle_sub_type_name(m, s->fields[j], name);
		}
	}
}




void ssa_build_defer_stmt(ssaProcedure *proc, ssaDefer d) {
	ssaBlock *b = ssa_add_block(proc, NULL, "defer");
	// NOTE(bill): The prev block may defer injection before it's terminator
	ssaInstr *last_instr = ssa_get_last_instr(proc->curr_block);
	if (last_instr == NULL || !ssa_is_instr_terminating(last_instr)) {
		ssa_emit_jump(proc, b);
	}
	proc->curr_block = b;
	ssa_emit_comment(proc, make_string("defer"));
	if (d.kind == ssaDefer_Node) {
		ssa_build_stmt(proc, d.stmt);
	} else if (d.kind == ssaDefer_Instr) {
		// NOTE(bill): Need to make a new copy
		ssaValue *instr = cast(ssaValue *)gb_alloc_copy(proc->module->allocator, d.instr, gb_size_of(ssaValue));
		ssa_emit(proc, instr);
	}
}



ssaValue *ssa_find_global_variable(ssaProcedure *proc, String name) {
	ssaValue **value = map_get(&proc->module->members, hash_string(name));
	GB_ASSERT_MSG(value != NULL, "Unable to find global variable `%.*s`", LIT(name));
	return *value;
}

ssaValue *ssa_find_implicit_value_backing(ssaProcedure *proc, ImplicitValueId id) {
	Entity *e = proc->module->info->implicit_values[id];
	GB_ASSERT(e->kind == Entity_ImplicitValue);
	Entity *backing = e->ImplicitValue.backing;
	ssaValue **value = map_get(&proc->module->values, hash_pointer(backing));
	GB_ASSERT_MSG(value != NULL, "Unable to find implicit value backing `%.*s`", LIT(backing->token.string));
	return *value;
}



ssaValue *ssa_build_single_expr(ssaProcedure *proc, AstNode *expr, TypeAndValue *tv) {
	expr = unparen_expr(expr);
	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		GB_PANIC("Non-constant basic literal");
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = *map_get(&proc->module->info->uses, hash_pointer(expr));
		if (e->kind == Entity_Builtin) {
			Token token = ast_node_token(expr);
			GB_PANIC("TODO(bill): ssa_build_single_expr Entity_Builtin `%.*s`\n"
			         "\t at %.*s(%td:%td)", LIT(builtin_procs[e->Builtin.id].name),
			         LIT(token.pos.file), token.pos.line, token.pos.column);
			return NULL;
		} else if (e->kind == Entity_Nil) {
			return ssa_make_value_nil(proc->module->allocator, tv->type);
		} else if (e->kind == Entity_ImplicitValue) {
			return ssa_emit_load(proc, ssa_find_implicit_value_backing(proc, e->ImplicitValue.id));
		}

		auto *found = map_get(&proc->module->values, hash_pointer(e));
		if (found) {
			ssaValue *v = *found;
			if (v->kind == ssaValue_Proc) {
				return v;
			}
			// if (e->kind == Entity_Variable && e->Variable.param) {
				// return v;
			// }
			return ssa_emit_load(proc, v);
		}
		return NULL;
	case_end;

	case_ast_node(re, RunExpr, expr);
		// TODO(bill): Run Expression
		return ssa_build_single_expr(proc, re->expr, tv);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return ssa_addr_load(proc, ssa_build_addr(proc, expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue *tav = map_get(&proc->module->info->types, hash_pointer(expr));
		GB_ASSERT(tav != NULL);
		return ssa_addr_load(proc, ssa_build_addr(proc, expr));
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer:
			return ssa_emit_ptr_offset(proc, ssa_build_addr(proc, ue->expr).addr, v_zero); // Make a copy of the pointer

		case Token_Maybe:
			return ssa_emit_conv(proc, ssa_build_expr(proc, ue->expr), type_of_expr(proc->module->info, expr));

		case Token_Add:
			return ssa_build_expr(proc, ue->expr);

		case Token_Sub: // NOTE(bill): -`x` == 0 - `x`
			return ssa_emit_arith(proc, ue->op.kind, v_zero, ssa_build_expr(proc, ue->expr), tv->type);

		case Token_Not:   // Boolean not
		case Token_Xor: { // Bitwise not
			// NOTE(bill): "not" `x` == `x` "xor" `-1`
			ssaValue *left = ssa_build_expr(proc, ue->expr);
			ssaValue *right = ssa_add_module_constant(proc->module, tv->type, make_exact_value_integer(-1));
			return ssa_emit_arith(proc, ue->op.kind,
			                      left, right,
			                      tv->type);
		} break;
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		switch (be->op.kind) {
		case Token_Add:
		case Token_Sub:
		case Token_Mul:
		case Token_Quo:
		case Token_Mod:
		case Token_And:
		case Token_Or:
		case Token_Xor:
		case Token_AndNot:
		case Token_Shl:
		case Token_Shr:
			return ssa_emit_arith(proc, be->op.kind,
			                      ssa_build_expr(proc, be->left),
			                      ssa_build_expr(proc, be->right),
			                      tv->type);


		case Token_CmpEq:
		case Token_NotEq:
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq: {
			ssaValue *left  = ssa_build_expr(proc, be->left);
			ssaValue *right = ssa_build_expr(proc, be->right);

			ssaValue *cmp = ssa_emit_comp(proc, be->op.kind, left, right);
			return ssa_emit_conv(proc, cmp, default_type(tv->type));
		} break;

		case Token_CmpAnd:
		case Token_CmpOr:
			return ssa_emit_logical_binary_expr(proc, expr);

		case Token_as:
			ssa_emit_comment(proc, make_string("cast - as"));
			return ssa_emit_conv(proc, ssa_build_expr(proc, be->left), tv->type);

		case Token_transmute:
			ssa_emit_comment(proc, make_string("cast - transmute"));
			return ssa_emit_transmute(proc, ssa_build_expr(proc, be->left), tv->type);

		case Token_down_cast:
			ssa_emit_comment(proc, make_string("cast - down_cast"));
			return ssa_emit_down_cast(proc, ssa_build_expr(proc, be->left), tv->type);

		case Token_union_cast:
			ssa_emit_comment(proc, make_string("cast - union_cast"));
			return ssa_emit_union_cast(proc, ssa_build_expr(proc, be->left), tv->type);

		default:
			GB_PANIC("Invalid binary expression");
			break;
		}
	case_end;

	case_ast_node(pl, ProcLit, expr);
		// NOTE(bill): Generate a new name
		// parent$count
		isize name_len = proc->name.len + 1 + 8 + 1;
		u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
		name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s$%d", LIT(proc->name), cast(i32)proc->children.count);
		String name = make_string(name_text, name_len-1);

		Type *type = type_of_expr(proc->module->info, expr);
		ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
		                                           proc->module, NULL, type, pl->type, pl->body, name);

		value->Proc.tags = pl->tags;

		array_add(&proc->children, &value->Proc);
		ssa_build_proc(value, proc);

		return value;
	case_end;


	case_ast_node(cl, CompoundLit, expr);
		ssa_emit_comment(proc, make_string("CompoundLit"));
		Type *type = type_of_expr(proc->module->info, expr);
		Type *bt = base_type(type);
		ssaValue *v = ssa_add_local_generated(proc, type);

		Type *et = NULL;
		switch (bt->kind) {
		case Type_Vector: et = bt->Vector.elem; break;
		case Type_Array:  et = bt->Array.elem;  break;
		case Type_Slice:  et = bt->Slice.elem;  break;
		}

		auto is_elem_const = [](ssaModule *m, AstNode *elem, Type *elem_type) -> b32 {
			if (base_type(elem_type) == t_any) {
				return false;
			}
			if (elem->kind == AstNode_FieldValue) {
				elem = elem->FieldValue.value;
			}
			TypeAndValue *tav = type_and_value_of_expression(m->info, elem);
			GB_ASSERT(tav != NULL);
			return tav->value.kind != ExactValue_Invalid;
		};

		switch (bt->kind) {
		default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

		case Type_Vector: {
			ssaValue *result = ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr));
			for_array(index, cl->elems) {
				AstNode *elem = cl->elems[index];
				if (is_elem_const(proc->module, elem, et)) {
					continue;
				}
				ssaValue *field_elem = ssa_build_expr(proc, elem);
				Type *t = ssa_type(field_elem);
				GB_ASSERT(t->kind != Type_Tuple);
				ssaValue *ev = ssa_emit_conv(proc, field_elem, et);
				ssaValue *i = ssa_make_const_int(proc->module->allocator, index);
				result = ssa_emit(proc, ssa_make_instr_insert_element(proc, result, ev, i));
			}

			if (cl->elems.count == 1 && bt->Vector.count > 1) {
				isize index_count = bt->Vector.count;
				i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
				for (isize i = 0; i < index_count; i++) {
					indices[i] = 0;
				}
				ssaValue *sv = ssa_emit(proc, ssa_make_instr_vector_shuffle(proc, result, indices, index_count));
				ssa_emit_store(proc, v, sv);
				return ssa_emit_load(proc, v);
			}
			return result;
		} break;

		case Type_Record: {
			GB_ASSERT(is_type_struct(bt));
			auto *st = &bt->Record;
			if (cl->elems.count > 0) {
				ssa_emit_store(proc, v, ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				for_array(field_index, cl->elems) {
					AstNode *elem = cl->elems[field_index];

					ssaValue *field_expr = NULL;
					Entity *field = NULL;
					isize index = field_index;

					if (elem->kind == AstNode_FieldValue) {
						ast_node(fv, FieldValue, elem);
						Selection sel = lookup_field(proc->module->allocator, bt, fv->field->Ident.string, false);
						index = sel.index[0];
						elem = fv->value;
					} else {
						TypeAndValue *tav = type_and_value_of_expression(proc->module->info, elem);
						Selection sel = lookup_field(proc->module->allocator, bt, st->fields_in_src_order[field_index]->token.string, false);
						index = sel.index[0];
					}

					field = st->fields[index];
					if (is_elem_const(proc->module, elem, field->type)) {
						continue;
					}

					field_expr = ssa_build_expr(proc, elem);

					GB_ASSERT(ssa_type(field_expr)->kind != Type_Tuple);



					Type *ft = field->type;
					ssaValue *fv = ssa_emit_conv(proc, field_expr, ft);
					ssaValue *gep = ssa_emit_struct_ep(proc, v, index);
					ssa_emit_store(proc, gep, fv);
				}
			}
		} break;
		case Type_Array: {
			if (cl->elems.count > 0) {
				ssa_emit_store(proc, v, ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr)));
				for_array(i, cl->elems) {
					AstNode *elem = cl->elems[i];
					if (is_elem_const(proc->module, elem, et)) {
						continue;
					}
					ssaValue *field_expr = ssa_build_expr(proc, elem);
					Type *t = ssa_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					ssaValue *ev = ssa_emit_conv(proc, field_expr, et);
					ssaValue *gep = ssa_emit_array_ep(proc, v, i);
					ssa_emit_store(proc, gep, ev);
				}
			}
		} break;
		case Type_Slice: {
			if (cl->elems.count > 0) {
				Type *elem_type = bt->Slice.elem;
				Type *elem_ptr_type = make_type_pointer(proc->module->allocator, elem_type);
				Type *elem_ptr_ptr_type = make_type_pointer(proc->module->allocator, elem_ptr_type);
				Type *t_int_ptr = make_type_pointer(proc->module->allocator, t_int);
				ssaValue *slice = ssa_add_module_constant(proc->module, type, make_exact_value_compound(expr));
				GB_ASSERT(slice->kind == ssaValue_ConstantSlice);

				ssaValue *data = ssa_emit_array_ep(proc, slice->ConstantSlice.backing_array, v_zero32);

				for_array(i, cl->elems) {
					AstNode *elem = cl->elems[i];
					if (is_elem_const(proc->module, elem, et)) {
						continue;
					}

					ssaValue *field_expr = ssa_build_expr(proc, elem);
					Type *t = ssa_type(field_expr);
					GB_ASSERT(t->kind != Type_Tuple);
					ssaValue *ev = ssa_emit_conv(proc, field_expr, elem_type);
					ssaValue *offset = ssa_emit_ptr_offset(proc, data, ssa_make_const_int(proc->module->allocator, i));
					ssa_emit_store(proc, offset, ev);
				}

				ssaValue *gep0 = ssa_emit_struct_ep(proc, v, 0);
				ssaValue *gep1 = ssa_emit_struct_ep(proc, v, 1);
				ssaValue *gep2 = ssa_emit_struct_ep(proc, v, 1);

				ssa_emit_store(proc, gep0, data);
				ssa_emit_store(proc, gep1, ssa_make_const_int(proc->module->allocator, slice->ConstantSlice.count));
				ssa_emit_store(proc, gep2, ssa_make_const_int(proc->module->allocator, slice->ConstantSlice.count));
			}
		} break;
		}

		return ssa_emit_load(proc, v);
	case_end;


	case_ast_node(ce, CallExpr, expr);
		AstNode *p = unparen_expr(ce->proc);
		if (p->kind == AstNode_Ident) {
			Entity **found = map_get(&proc->module->info->uses, hash_pointer(p));
			if (found && (*found)->kind == Entity_Builtin) {
				Entity *e = *found;
				switch (e->Builtin.id) {
				case BuiltinProc_type_info: {
					Type *t = default_type(type_of_expr(proc->module->info, ce->args[0]));
					return ssa_type_info(proc, t);
				} break;
				case BuiltinProc_type_info_of_val: {
					Type *t = default_type(type_of_expr(proc->module->info, ce->args[0]));
					return ssa_type_info(proc, t);
				} break;

				case BuiltinProc_new: {
					ssa_emit_comment(proc, make_string("new"));
					// new :: proc(Type) -> ^Type
					gbAllocator allocator = proc->module->allocator;

					Type *type = type_of_expr(proc->module->info, ce->args[0]);
					Type *ptr_type = make_type_pointer(allocator, type);

					i64 s = type_size_of(proc->module->sizes, allocator, type);
					i64 a = type_align_of(proc->module->sizes, allocator, type);

					ssaValue **args = gb_alloc_array(allocator, ssaValue *, 2);
					args[0] = ssa_make_const_int(allocator, s);
					args[1] = ssa_make_const_int(allocator, a);
					ssaValue *call = ssa_emit_global_call(proc, "alloc_align", args, 2);
					ssaValue *v = ssa_emit_conv(proc, call, ptr_type);
					return v;
				} break;

				case BuiltinProc_new_slice: {
					ssa_emit_comment(proc, make_string("new_slice"));
					// new_slice :: proc(Type, len: int[, cap: int]) -> ^Type
					gbAllocator allocator = proc->module->allocator;

					Type *type = type_of_expr(proc->module->info, ce->args[0]);
					Type *ptr_type = make_type_pointer(allocator, type);
					Type *slice_type = make_type_slice(allocator, type);

					i64 s = type_size_of(proc->module->sizes, allocator, type);
					i64 a = type_align_of(proc->module->sizes, allocator, type);

					ssaValue *elem_size  = ssa_make_const_int(allocator, s);
					ssaValue *elem_align = ssa_make_const_int(allocator, a);

					ssaValue *len = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args[1]), t_int);
					ssaValue *cap = len;
					if (ce->args.count == 3) {
						cap = ssa_emit_conv(proc, ssa_build_expr(proc, ce->args[2]), t_int);
					}

					ssa_emit_slice_bounds_check(proc, ast_node_token(ce->args[1]), v_zero, len, cap, false);

					ssaValue *slice_size = ssa_emit_arith(proc, Token_Mul, elem_size, cap, t_int);

					ssaValue **args = gb_alloc_array(allocator, ssaValue *, 2);
					args[0] = slice_size;
					args[1] = elem_align;
					ssaValue *call = ssa_emit_global_call(proc, "alloc_align", args, 2);

					ssaValue *ptr = ssa_emit_conv(proc, call, ptr_type, true);
					ssaValue *slice = ssa_add_local_generated(proc, slice_type);

					ssaValue *gep0 = ssa_emit_struct_ep(proc, slice, 0);
					ssaValue *gep1 = ssa_emit_struct_ep(proc, slice, 1);
					ssaValue *gep2 = ssa_emit_struct_ep(proc, slice, 2);
					ssa_emit_store(proc, gep0, ptr);
					ssa_emit_store(proc, gep1, len);
					ssa_emit_store(proc, gep2, cap);
					return ssa_emit_load(proc, slice);
				} break;

				case BuiltinProc_assert: {
					ssa_emit_comment(proc, make_string("assert"));
					ssaValue *cond = ssa_build_expr(proc, ce->args[0]);
					GB_ASSERT(is_type_boolean(ssa_type(cond)));

					cond = ssa_emit_comp(proc, Token_CmpEq, cond, v_false);
					ssaBlock *err  = ssa_add_block(proc, NULL, "builtin.assert.err");
					ssaBlock *done = ssa_add_block(proc, NULL, "builtin.assert.done");

					ssa_emit_if(proc, cond, err, done);
					proc->curr_block = err;

					// TODO(bill): Cleanup allocations here
					Token token = ast_node_token(ce->args[0]);
					TokenPos pos = token.pos;
					gbString expr = expr_to_string(ce->args[0]);
					defer (gb_string_free(expr));
					isize expr_len = gb_string_length(expr);
					String expr_str = {};
					expr_str.text = cast(u8 *)gb_alloc_copy_align(proc->module->allocator, expr, expr_len, 1);
					expr_str.len = expr_len;

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 4);
					args[0] = ssa_make_const_string(proc->module->allocator, pos.file);
					args[1] = ssa_make_const_int(proc->module->allocator, pos.line);
					args[2] = ssa_make_const_int(proc->module->allocator, pos.column);
					args[3] = ssa_make_const_string(proc->module->allocator, expr_str);
					ssa_emit_global_call(proc, "__assert", args, 4);

					ssa_emit_jump(proc, done);
					proc->curr_block = done;

					return NULL;
				} break;

				case BuiltinProc_panic: {
					ssa_emit_comment(proc, make_string("panic"));
					ssaValue *msg = ssa_build_expr(proc, ce->args[0]);
					GB_ASSERT(is_type_string(ssa_type(msg)));

					Token token = ast_node_token(ce->args[0]);
					TokenPos pos = token.pos;

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 4);
					args[0] = ssa_make_const_string(proc->module->allocator, pos.file);
					args[1] = ssa_make_const_int(proc->module->allocator, pos.line);
					args[2] = ssa_make_const_int(proc->module->allocator, pos.column);
					args[3] = msg;
					ssa_emit_global_call(proc, "__assert", args, 4);

					return NULL;
				} break;


				case BuiltinProc_copy: {
					ssa_emit_comment(proc, make_string("copy"));
					// copy :: proc(dst, src: []Type) -> int
					AstNode *dst_node = ce->args[0];
					AstNode *src_node = ce->args[1];
					ssaValue *dst_slice = ssa_build_expr(proc, dst_node);
					ssaValue *src_slice = ssa_build_expr(proc, src_node);
					Type *slice_type = base_type(ssa_type(dst_slice));
					GB_ASSERT(slice_type->kind == Type_Slice);
					Type *elem_type = slice_type->Slice.elem;
					i64 size_of_elem = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);


					ssaValue *dst = ssa_emit_conv(proc, ssa_slice_elem(proc, dst_slice), t_rawptr, true);
					ssaValue *src = ssa_emit_conv(proc, ssa_slice_elem(proc, src_slice), t_rawptr, true);

					ssaValue *len_dst = ssa_slice_len(proc, dst_slice);
					ssaValue *len_src = ssa_slice_len(proc, src_slice);

					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, len_dst, len_src);
					ssaValue *len = ssa_emit_select(proc, cond, len_dst, len_src);

					ssaValue *elem_size = ssa_make_const_int(proc->module->allocator, size_of_elem);
					ssaValue *byte_count = ssa_emit_arith(proc, Token_Mul, len, elem_size, t_int);

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 3);
					args[0] = dst;
					args[1] = src;
					args[2] = byte_count;

					ssa_emit_global_call(proc, "__mem_copy", args, 3);

					return len;
				} break;
				case BuiltinProc_append: {
					ssa_emit_comment(proc, make_string("append"));
					// append :: proc(s: ^[]Type, item: Type) -> bool
					AstNode *sptr_node = ce->args[0];
					AstNode *item_node = ce->args[1];
					ssaValue *slice_ptr = ssa_build_expr(proc, sptr_node);
					ssaValue *slice = ssa_emit_load(proc, slice_ptr);

					ssaValue *elem = ssa_slice_elem(proc, slice);
					ssaValue *len  = ssa_slice_len(proc,  slice);
					ssaValue *cap  = ssa_slice_cap(proc,  slice);

					Type *elem_type = type_deref(ssa_type(elem));

					ssaValue *item_value = ssa_build_expr(proc, item_node);
					item_value = ssa_emit_conv(proc, item_value, elem_type, true);

					ssaValue *item = ssa_add_local_generated(proc, elem_type);
					ssa_emit_store(proc, item, item_value);


					// NOTE(bill): Check if can append is possible
					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, len, cap);
					ssaBlock *able = ssa_add_block(proc, NULL, "builtin.append.able");
					ssaBlock *done = ssa_add_block(proc, NULL, "builtin.append.done");

					ssa_emit_if(proc, cond, able, done);
					proc->curr_block = able;

					// Add new slice item
					i64 item_size = type_size_of(proc->module->sizes, proc->module->allocator, elem_type);
					ssaValue *byte_count = ssa_make_const_int(proc->module->allocator, item_size);

					ssaValue *offset = ssa_emit_ptr_offset(proc, elem, len);
					offset = ssa_emit_conv(proc, offset, t_rawptr, true);

					item = ssa_emit_ptr_offset(proc, item, v_zero);
					item = ssa_emit_conv(proc, item, t_rawptr, true);

					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 3);
					args[0] = offset;
					args[1] = item;
					args[2] = byte_count;

					ssa_emit_global_call(proc, "__mem_copy", args, 3);

					// Increment slice length
					ssaValue *new_len = ssa_emit_arith(proc, Token_Add, len, v_one, t_int);
					ssaValue *gep = ssa_emit_struct_ep(proc, slice_ptr, 1);
					ssa_emit_store(proc, gep, new_len);

					ssa_emit_jump(proc, done);
					proc->curr_block = done;

					return ssa_emit_conv(proc, cond, t_bool, true);
				} break;

				case BuiltinProc_swizzle: {
					ssa_emit_comment(proc, make_string("swizzle"));
					ssaValue *vector = ssa_build_expr(proc, ce->args[0]);
					isize index_count = ce->args.count-1;
					if (index_count == 0) {
						return vector;
					}

					i32 *indices = gb_alloc_array(proc->module->allocator, i32, index_count);
					isize index = 0;
					for_array(i, ce->args) {
						if (i == 0) continue;
						TypeAndValue *tv = type_and_value_of_expression(proc->module->info, ce->args[i]);
						GB_ASSERT(is_type_integer(tv->type));
						GB_ASSERT(tv->value.kind == ExactValue_Integer);
						indices[index++] = cast(i32)tv->value.value_integer;
					}

					return ssa_emit(proc, ssa_make_instr_vector_shuffle(proc, vector, indices, index_count));

				} break;

#if 0
				case BuiltinProc_ptr_offset: {
					ssa_emit_comment(proc, make_string("ptr_offset"));
					ssaValue *ptr = ssa_build_expr(proc, ce->args[0]);
					ssaValue *offset = ssa_build_expr(proc, ce->args[1]);
					return ssa_emit_ptr_offset(proc, ptr, offset);
				} break;

				case BuiltinProc_ptr_sub: {
					ssa_emit_comment(proc, make_string("ptr_sub"));
					ssaValue *ptr_a = ssa_build_expr(proc, ce->args[0]);
					ssaValue *ptr_b = ssa_build_expr(proc, ce->args[1]);
					Type *ptr_type = base_type(ssa_type(ptr_a));
					GB_ASSERT(ptr_type->kind == Type_Pointer);
					isize elem_size = type_size_of(proc->module->sizes, proc->module->allocator, ptr_type->Pointer.elem);

					ssaValue *v = ssa_emit_arith(proc, Token_Sub, ptr_a, ptr_b, t_int);
					if (elem_size > 1) {
						ssaValue *ez = ssa_make_const_int(proc->module->allocator, elem_size);
						v = ssa_emit_arith(proc, Token_Quo, v, ez, t_int);
					}

					return v;
				} break;
#endif

				case BuiltinProc_slice_ptr: {
					ssa_emit_comment(proc, make_string("slice_ptr"));
					ssaValue *ptr = ssa_build_expr(proc, ce->args[0]);
					ssaValue *len = ssa_build_expr(proc, ce->args[1]);
					ssaValue *cap = len;

					len = ssa_emit_conv(proc, len, t_int, true);

					if (ce->args.count == 3) {
						cap = ssa_build_expr(proc, ce->args[2]);
						cap = ssa_emit_conv(proc, cap, t_int, true);
					}


					Type *slice_type = make_type_slice(proc->module->allocator, type_deref(ssa_type(ptr)));
					ssaValue *slice = ssa_add_local_generated(proc, slice_type);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 0), ptr);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 1), len);
					ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 2), cap);
					return ssa_emit_load(proc, slice);
				} break;

				case BuiltinProc_min: {
					ssa_emit_comment(proc, make_string("min"));
					ssaValue *x = ssa_build_expr(proc, ce->args[0]);
					ssaValue *y = ssa_build_expr(proc, ce->args[1]);
					Type *t = base_type(ssa_type(x));
					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, x, y);
					return ssa_emit_select(proc, cond, x, y);
				} break;

				case BuiltinProc_max: {
					ssa_emit_comment(proc, make_string("max"));
					ssaValue *x = ssa_build_expr(proc, ce->args[0]);
					ssaValue *y = ssa_build_expr(proc, ce->args[1]);
					Type *t = base_type(ssa_type(x));
					ssaValue *cond = ssa_emit_comp(proc, Token_Gt, x, y);
					return ssa_emit_select(proc, cond, x, y);
				} break;

				case BuiltinProc_abs: {
					ssa_emit_comment(proc, make_string("abs"));

					ssaValue *x = ssa_build_expr(proc, ce->args[0]);
					Type *t = ssa_type(x);

					ssaValue *neg_x = ssa_emit_arith(proc, Token_Sub, v_zero, x, t);
					ssaValue *cond = ssa_emit_comp(proc, Token_Lt, x, v_zero);
					return ssa_emit_select(proc, cond, neg_x, x);
				} break;

				case BuiltinProc_enum_to_string: {
					ssa_emit_comment(proc, make_string("enum_to_string"));
					ssaValue *x = ssa_build_expr(proc, ce->args[0]);
					Type *t = ssa_type(x);
					ssaValue *ti = ssa_type_info(proc, t);


					ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, 2);
					args[0] = ti;
					args[1] = ssa_emit_conv(proc, x, t_i64);
					return ssa_emit_global_call(proc, "__enum_to_string", args, 2);
				} break;
				}
			}
		}


		// NOTE(bill): Regular call
		ssaValue *value = ssa_build_expr(proc, ce->proc);
		Type *proc_type_ = base_type(ssa_type(value));
		GB_ASSERT(proc_type_->kind == Type_Proc);
		auto *type = &proc_type_->Proc;

		isize arg_index = 0;

		isize arg_count = 0;
		for_array(i, ce->args) {
			AstNode *a = ce->args[i];
			Type *at = base_type(type_of_expr(proc->module->info, a));
			if (at->kind == Type_Tuple) {
				arg_count += at->Tuple.variable_count;
			} else {
				arg_count++;
			}
		}
		ssaValue **args = gb_alloc_array(proc->module->allocator, ssaValue *, arg_count);
		b32 variadic = proc_type_->Proc.variadic;
		b32 vari_expand = ce->ellipsis.pos.line != 0;

		for_array(i, ce->args) {
			ssaValue *a = ssa_build_expr(proc, ce->args[i]);
			Type *at = ssa_type(a);
			if (at->kind == Type_Tuple) {
				for (isize i = 0; i < at->Tuple.variable_count; i++) {
					Entity *e = at->Tuple.variables[i];
					ssaValue *v = ssa_emit_struct_ev(proc, a, i);
					args[arg_index++] = v;
				}
			} else {
				args[arg_index++] = a;
			}
		}

		auto *pt = &type->params->Tuple;

		if (variadic) {
			isize i = 0;
			for (; i < type->param_count-1; i++) {
				args[i] = ssa_emit_conv(proc, args[i], pt->variables[i]->type, true);
			}
			if (!vari_expand) {
				Type *variadic_type = pt->variables[i]->type;
				GB_ASSERT(is_type_slice(variadic_type));
				variadic_type = base_type(variadic_type)->Slice.elem;
				for (; i < arg_count; i++) {
					args[i] = ssa_emit_conv(proc, args[i], variadic_type, true);
				}
			}
		} else {
			for (isize i = 0; i < arg_count; i++) {
				args[i] = ssa_emit_conv(proc, args[i], pt->variables[i]->type, true);
			}
		}

		if (variadic && !vari_expand) {
			ssa_emit_comment(proc, make_string("variadic call argument generation"));
			gbAllocator allocator = proc->module->allocator;
			Type *slice_type = pt->variables[type->param_count-1]->type;
			Type *elem_type  = base_type(slice_type)->Slice.elem;
			ssaValue *slice = ssa_add_local_generated(proc, slice_type);
			isize slice_len = arg_count+1 - type->param_count;

			if (slice_len > 0) {
				ssaValue *base_array = ssa_add_local_generated(proc, make_type_array(allocator, elem_type, slice_len));

				for (isize i = type->param_count-1, j = 0; i < arg_count; i++, j++) {
					ssaValue *addr = ssa_emit_array_ep(proc, base_array, j);
					ssa_emit_store(proc, addr, args[i]);
				}

				ssaValue *base_elem  = ssa_emit_array_ep(proc, base_array, 0);
				ssaValue *slice_elem = ssa_emit_struct_ep(proc, slice,      0);
				ssa_emit_store(proc, slice_elem, base_elem);
				ssaValue *len = ssa_make_const_int(allocator, slice_len);
				ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 1), len);
				ssa_emit_store(proc, ssa_emit_struct_ep(proc, slice, 2), len);
			}

			if (args[0]->kind == ssaValue_Constant) {
				auto *c = &args[0]->Constant;
				gb_printf_err("%s %d\n", type_to_string(c->type), c->value.kind);
			}

			arg_count = type->param_count;
			args[arg_count-1] = ssa_emit_load(proc, slice);
		}

		return ssa_emit_call(proc, value, args, arg_count);
	case_end;

	case_ast_node(de, DemaybeExpr, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return ssa_emit_load(proc, ssa_build_addr(proc, expr).addr);
	case_end;
	}

	GB_PANIC("Unexpected expression: %.*s", LIT(ast_node_strings[expr->kind]));
	return NULL;
}


ssaValue *ssa_build_expr(ssaProcedure *proc, AstNode *expr) {
	expr = unparen_expr(expr);

	TypeAndValue *tv = map_get(&proc->module->info->types, hash_pointer(expr));
	GB_ASSERT_NOT_NULL(tv);

	if (tv->value.kind != ExactValue_Invalid) {
		return ssa_add_module_constant(proc->module, tv->type, tv->value);
	}

	ssaValue *value = NULL;
	if (tv->mode == Addressing_Variable) {
		value = ssa_addr_load(proc, ssa_build_addr(proc, expr));
	} else {
		value = ssa_build_single_expr(proc, expr, tv);
	}

	return value;
}

ssaValue *ssa_add_using_variable(ssaProcedure *proc, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->Variable.anonymous);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(proc->module->allocator, parent->type, name, false);
	GB_ASSERT(sel.entity != NULL);
	ssaValue **pv = map_get(&proc->module->values, hash_pointer(parent));
	ssaValue *v = NULL;
	if (pv != NULL) {
		v = *pv;
	} else {
		v = ssa_build_addr(proc, e->using_expr).addr;
	}
	GB_ASSERT(v != NULL);
	ssaValue *var = ssa_emit_deep_field_gep(proc, parent->type, v, sel);
	map_set(&proc->module->values, hash_pointer(e), var);
	return var;
}

ssaAddr ssa_build_addr(ssaProcedure *proc, AstNode *expr) {
	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		if (ssa_is_blank_ident(expr)) {
			ssaAddr val = {};
			return val;
		}

		Entity *e = entity_of_ident(proc->module->info, expr);
		TypeAndValue *tv = map_get(&proc->module->info->types, hash_pointer(expr));

		GB_ASSERT(e->kind != Entity_Constant);

		ssaValue *v = NULL;
		ssaValue **found = map_get(&proc->module->values, hash_pointer(e));
		if (found) {
			v = *found;
		} else if (e->kind == Entity_Variable && e->Variable.anonymous) {
			v = ssa_add_using_variable(proc, e);
		} else if (e->kind == Entity_ImplicitValue) {
			// TODO(bill): Should a copy be made?
			v = ssa_find_implicit_value_backing(proc, e->ImplicitValue.id);
		}

		if (v == NULL) {
			GB_PANIC("Unknown value: %s, entity: %p %.*s\n", expr_to_string(expr), e, LIT(entity_strings[e->kind]));
		}

		return ssa_make_addr(v, expr);
	case_end;

	case_ast_node(pe, ParenExpr, expr);
		return ssa_build_addr(proc, unparen_expr(expr));
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		ssa_emit_comment(proc, make_string("SelectorExpr"));
		String selector = unparen_expr(se->selector)->Ident.string;
		Type *type = base_type(type_of_expr(proc->module->info, se->expr));

		if (type == t_invalid) {
			// NOTE(bill): Imports
			Entity *imp = entity_of_ident(proc->module->info, se->expr);
			if (imp != NULL) {
				GB_ASSERT(imp->kind == Entity_ImportName);
			}
			return ssa_build_addr(proc, unparen_expr(se->selector));
		} else {
			Selection sel = lookup_field(proc->module->allocator, type, selector, false);
			GB_ASSERT(sel.entity != NULL);

			ssaValue *a = ssa_build_addr(proc, se->expr).addr;
			a = ssa_emit_deep_field_gep(proc, type, a, sel);
			return ssa_make_addr(a, expr);
		}
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		switch (ue->op.kind) {
		case Token_Pointer: {
			return ssa_build_addr(proc, ue->expr);
		}
		default:
			GB_PANIC("Invalid unary expression for ssa_build_addr");
		}
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		switch (be->op.kind) {
		case Token_as: {
			ssa_emit_comment(proc, make_string("Cast - as"));
			// NOTE(bill): Needed for dereference of pointer conversion
			Type *type = type_of_expr(proc->module->info, expr);
			ssaValue *v = ssa_add_local_generated(proc, type);
			ssa_emit_store(proc, v, ssa_emit_conv(proc, ssa_build_expr(proc, be->left), type));
			return ssa_make_addr(v, expr);
		}
		case Token_transmute: {
			ssa_emit_comment(proc, make_string("Cast - transmute"));
			// NOTE(bill): Needed for dereference of pointer conversion
			Type *type = type_of_expr(proc->module->info, expr);
			ssaValue *v = ssa_add_local_generated(proc, type);
			ssa_emit_store(proc, v, ssa_emit_transmute(proc, ssa_build_expr(proc, be->left), type));
			return ssa_make_addr(v, expr);
		}
		default:
			GB_PANIC("Invalid binary expression for ssa_build_addr: %.*s\n", LIT(be->op.string));
			break;
		}
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		ssa_emit_comment(proc, make_string("IndexExpr"));
		Type *t = base_type(type_of_expr(proc->module->info, ie->expr));
		gbAllocator a = proc->module->allocator;


		b32 deref = is_type_pointer(t);
		t = type_deref(t);

		ssaValue *using_addr = NULL;
		if (!is_type_indexable(t)) {
			// Using index expression
			Entity *using_field = find_using_index_expr(t);
			if (using_field != NULL) {
				Selection sel = lookup_field(a, t, using_field->token.string, false);
				ssaValue *e = ssa_build_addr(proc, ie->expr).addr;
				using_addr = ssa_emit_deep_field_gep(proc, t, e, sel);

				t = using_field->type;
			}
		}


		switch (t->kind) {
		case Type_Vector: {
			ssaValue *vector = NULL;
			if (using_addr != NULL) {
				vector = using_addr;
			} else {
				vector = ssa_build_addr(proc, ie->expr).addr;
				if (deref) {
					vector = ssa_emit_load(proc, vector);
				}
			}
			ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssaValue *len = ssa_make_const_int(a, t->Vector.count);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			return ssa_make_addr_vector(vector, index, expr);
		} break;

		case Type_Array: {
			ssaValue *array = NULL;
			if (using_addr != NULL) {
				array = using_addr;
			} else {
				array = ssa_build_addr(proc, ie->expr).addr;
				if (deref) {
					array = ssa_emit_load(proc, array);
				}
			}
			ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssaValue *elem = ssa_emit_array_ep(proc, array, index);
			ssaValue *len = ssa_make_const_int(a, t->Vector.count);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			return ssa_make_addr(elem, expr);
		} break;

		case Type_Slice: {
			ssaValue *slice = NULL;
			if (using_addr != NULL) {
				slice = ssa_emit_load(proc, using_addr);
			} else {
				slice = ssa_build_expr(proc, ie->expr);
				if (deref) {
					slice = ssa_emit_load(proc, slice);
				}
			}
			ssaValue *elem = ssa_slice_elem(proc, slice);
			ssaValue *len = ssa_slice_len(proc, slice);
			ssaValue *index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);
			ssaValue *v = ssa_emit_ptr_offset(proc, elem, index);
			return ssa_make_addr(v, expr);

		} break;

		case Type_Basic: { // Basic_string
			TypeAndValue *tv = map_get(&proc->module->info->types, hash_pointer(ie->expr));
			ssaValue *str;
			ssaValue *elem;
			ssaValue *len;
			ssaValue *index;

			if (using_addr != NULL) {
				str = ssa_emit_load(proc, using_addr);
			} else {
				str = ssa_build_expr(proc, ie->expr);
				if (deref) {
					str = ssa_emit_load(proc, str);
				}
			}
			elem = ssa_string_elem(proc, str);
			len = ssa_string_len(proc, str);

			index = ssa_emit_conv(proc, ssa_build_expr(proc, ie->index), t_int);
			ssa_emit_bounds_check(proc, ast_node_token(ie->index), index, len);

			return ssa_make_addr(ssa_emit_ptr_offset(proc, elem, index), expr);
		} break;
		}
	case_end;

	case_ast_node(se, SliceExpr, expr);
		ssa_emit_comment(proc, make_string("SliceExpr"));
		gbAllocator a = proc->module->allocator;
		ssaValue *low  = v_zero;
		ssaValue *high = NULL;
		ssaValue *max  = NULL;

		if (se->low  != NULL)    low  = ssa_build_expr(proc, se->low);
		if (se->high != NULL)    high = ssa_build_expr(proc, se->high);
		if (se->triple_indexed)  max  = ssa_build_expr(proc, se->max);
		ssaValue *addr = ssa_build_addr(proc, se->expr).addr;
		ssaValue *base = ssa_emit_load(proc, addr);
		Type *type = base_type(ssa_type(base));

		if (is_type_pointer(type)) {
			type = type_deref(type);
			addr = base;
			base = ssa_emit_load(proc, base);
		}

		// TODO(bill): Cleanup like mad!

		switch (type->kind) {
		case Type_Slice: {
			Type *slice_type = type;

			if (high == NULL) high = ssa_slice_len(proc, base);
			if (max == NULL)  max  = ssa_slice_cap(proc, base);
			GB_ASSERT(max != NULL);

			ssa_emit_slice_bounds_check(proc, se->open, low, high, max, false);

			ssaValue *elem = ssa_slice_elem(proc, base);
			ssaValue *len  = ssa_emit_arith(proc, Token_Sub, high, low, t_int);
			ssaValue *cap  = ssa_emit_arith(proc, Token_Sub, max,  low, t_int);
			ssaValue *slice = ssa_add_local_generated(proc, slice_type);

			ssaValue *gep0 = ssa_emit_struct_ep(proc, slice, 0);
			ssaValue *gep1 = ssa_emit_struct_ep(proc, slice, 1);
			ssaValue *gep2 = ssa_emit_struct_ep(proc, slice, 2);
			ssa_emit_store(proc, gep0, elem);
			ssa_emit_store(proc, gep1, len);
			ssa_emit_store(proc, gep2, cap);

			return ssa_make_addr(slice, expr);
		}

		case Type_Array: {
			Type *slice_type = make_type_slice(a, type->Array.elem);

			if (high == NULL) high = ssa_array_len(proc, base);
			if (max == NULL)  max  = ssa_array_cap(proc, base);
			GB_ASSERT(max != NULL);

			ssa_emit_slice_bounds_check(proc, se->open, low, high, max, false);

			ssaValue *elem = ssa_array_elem(proc, addr);
			ssaValue *len  = ssa_emit_arith(proc, Token_Sub, high, low, t_int);
			ssaValue *cap  = ssa_emit_arith(proc, Token_Sub, max,  low, t_int);
			ssaValue *slice = ssa_add_local_generated(proc, slice_type);

			ssaValue *gep0 = ssa_emit_struct_ep(proc, slice, 0);
			ssaValue *gep1 = ssa_emit_struct_ep(proc, slice, 1);
			ssaValue *gep2 = ssa_emit_struct_ep(proc, slice, 2);
			ssa_emit_store(proc, gep0, elem);
			ssa_emit_store(proc, gep1, len);
			ssa_emit_store(proc, gep2, cap);

			return ssa_make_addr(slice, expr);
		}

		case Type_Basic: {
			GB_ASSERT(type == t_string);
			if (high == NULL) {
				high = ssa_string_len(proc, base);
			}

			ssa_emit_slice_bounds_check(proc, se->open, low, high, high, true);

			ssaValue *elem, *len;
			len = ssa_emit_arith(proc, Token_Sub, high, low, t_int);

			elem = ssa_string_elem(proc, base);
			elem = ssa_emit_ptr_offset(proc, elem, low);

			ssaValue *str = ssa_add_local_generated(proc, t_string);
			ssaValue *gep0 = ssa_emit_struct_ep(proc, str, 0);
			ssaValue *gep1 = ssa_emit_struct_ep(proc, str, 1);
			ssa_emit_store(proc, gep0, elem);
			ssa_emit_store(proc, gep1, len);

			return ssa_make_addr(str, expr);
		} break;
		}

		GB_PANIC("Unknown slicable type");
	case_end;

	case_ast_node(de, DerefExpr, expr);
		// TODO(bill): Is a ptr copy needed?
		ssaValue *addr = ssa_build_expr(proc, de->expr);
		addr = ssa_emit_ptr_offset(proc, addr, v_zero);
		return ssa_make_addr(addr, expr);
	case_end;

	case_ast_node(de, DemaybeExpr, expr);
		ssa_emit_comment(proc, make_string("DemaybeExpr"));
		ssaValue *maybe = ssa_build_expr(proc, de->expr);
		Type *t = default_type(type_of_expr(proc->module->info, expr));
		GB_ASSERT(is_type_tuple(t));

		ssaValue *result = ssa_add_local_generated(proc, t);
		ssa_emit_store(proc, result, maybe);

		return ssa_make_addr(result, expr);
	case_end;

	case_ast_node(ce, CallExpr, expr);
		ssaValue *e = ssa_build_expr(proc, expr);
		ssaValue *v = ssa_add_local_generated(proc, ssa_type(e));
		ssa_emit_store(proc, v, e);
		return ssa_make_addr(v, expr);
	case_end;
	}

	TokenPos token_pos = ast_node_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAstNode: %.*s @ "
	         "%.*s(%td:%td)\n",
	         LIT(ast_node_strings[expr->kind]),
	         LIT(token_pos.file), token_pos.line, token_pos.column);


	return ssa_make_addr(NULL, NULL);
}

void ssa_build_assign_op(ssaProcedure *proc, ssaAddr lhs, ssaValue *value, TokenKind op) {
	ssaValue *old_value = ssa_addr_load(proc, lhs);
	Type *type = ssa_type(old_value);

	ssaValue *change = value;
	if (is_type_pointer(type) && is_type_integer(ssa_type(value))) {
		change = ssa_emit_conv(proc, value, default_type(ssa_type(value)));
	} else {
		change = ssa_emit_conv(proc, value, type);
	}
	ssaValue *new_value = ssa_emit_arith(proc, op, old_value, change, type);
	ssa_addr_store(proc, lhs, new_value);
}

void ssa_build_cond(ssaProcedure *proc, AstNode *cond, ssaBlock *true_block, ssaBlock *false_block) {
	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		ssa_build_cond(proc, pe->expr, true_block, false_block);
		return;
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			ssa_build_cond(proc, ue->expr, false_block, true_block);
			return;
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			ssaBlock *block = ssa_add_block(proc, NULL, "cmp.and");
			ssa_build_cond(proc, be->left, block, false_block);
			proc->curr_block = block;
			ssa_build_cond(proc, be->right, true_block, false_block);
			return;
		} else if (be->op.kind == Token_CmpOr) {
			ssaBlock *block = ssa_add_block(proc, NULL, "cmp.or");
			ssa_build_cond(proc, be->left, true_block, block);
			proc->curr_block = block;
			ssa_build_cond(proc, be->right, true_block, false_block);
			return;
		}
	case_end;
	}

	ssaValue *expr = ssa_build_expr(proc, cond);
	expr = ssa_emit_conv(proc, expr, t_bool);
	ssa_emit_if(proc, expr, true_block, false_block);
}




void ssa_build_stmt_list(ssaProcedure *proc, AstNodeArray stmts) {
	for_array(i, stmts) {
		ssa_build_stmt(proc, stmts[i]);
	}
}

void ssa_build_stmt(ssaProcedure *proc, AstNode *node) {
	u32 prev_stmt_state_flags = proc->module->stmt_state_flags;
	defer (proc->module->stmt_state_flags = prev_stmt_state_flags);

	if (node->stmt_state_flags != 0) {
		u32 in = node->stmt_state_flags;
		u32 out = proc->module->stmt_state_flags;
		defer (proc->module->stmt_state_flags = out);

		if (in & StmtStateFlag_bounds_check) {
			out |= StmtStateFlag_bounds_check;
			out &= ~StmtStateFlag_no_bounds_check;
		} else if (in & StmtStateFlag_no_bounds_check) {
			out |= StmtStateFlag_no_bounds_check;
			out &= ~StmtStateFlag_bounds_check;
		}
	}


	switch (node->kind) {
	case_ast_node(bs, EmptyStmt, node);
	case_end;

	case_ast_node(us, UsingStmt, node);
		AstNode *decl = unparen_expr(us->node);
		if (decl->kind == AstNode_VarDecl) {
			ssa_build_stmt(proc, decl);
		}
	case_end;

	case_ast_node(vd, VarDecl, node);
		ssaModule *m = proc->module;
		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);
		defer (gb_temp_arena_memory_end(tmp));

		if (vd->values.count == 0) { // declared and zero-initialized
			for_array(i, vd->names) {
				AstNode *name = vd->names[i];
				if (!ssa_is_blank_ident(name)) {
					ssa_add_local_for_identifier(proc, name, true);
				}
			}
		} else { // Tuple(s)
			Array<ssaAddr>  lvals;
			Array<ssaValue *> inits;
			array_init(&lvals, m->tmp_allocator, vd->names.count);
			array_init(&inits, m->tmp_allocator, vd->names.count);

			for_array(i, vd->names) {
				AstNode *name = vd->names[i];
				ssaAddr lval = ssa_make_addr(NULL, NULL);
				if (!ssa_is_blank_ident(name)) {
					ssa_add_local_for_identifier(proc, name, false);
					lval = ssa_build_addr(proc, name);
				}

				array_add(&lvals, lval);
			}

			for_array(i, vd->values) {
				ssaValue *init = ssa_build_expr(proc, vd->values[i]);
				Type *t = ssa_type(init);
				if (t->kind == Type_Tuple) {
					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						Entity *e = t->Tuple.variables[i];
						ssaValue *v = ssa_emit_struct_ev(proc, init, i);
						array_add(&inits, v);
					}
				} else {
					array_add(&inits, init);
				}
			}


			for_array(i, inits) {
				ssaValue *v = ssa_emit_conv(proc, inits[i], ssa_addr_type(lvals[i]));
				ssa_addr_store(proc, lvals[i], v);
			}
		}
	case_end;

	case_ast_node(pd, ProcDecl, node);
		if (pd->body != NULL) {
			auto *info = proc->module->info;

			Entity **found = map_get(&info->definitions, hash_pointer(pd->name));
			GB_ASSERT_MSG(found != NULL, "Unable to find: %.*s", LIT(pd->name->Ident.string));
			Entity *e = *found;

			// NOTE(bill): Generate a new name
			// parent.name-guid
			String original_name = pd->name->Ident.string;
			String pd_name = original_name;
			if (pd->link_name.len > 0) {
				pd_name = pd->link_name;
			}

			isize name_len = proc->name.len + 1 + pd_name.len + 1 + 10 + 1;
			u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
			i32 guid = cast(i32)proc->children.count;
			name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(pd_name), guid);
			String name = make_string(name_text, name_len-1);


			ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
			                                           proc->module, e, e->type, pd->type, pd->body, name);

			value->Proc.tags = pd->tags;
			value->Proc.parent = proc;

			ssa_module_add_value(proc->module, e, value);
			array_add(&proc->children, &value->Proc);
			array_add(&proc->module->procs, value);
		} else {
			auto *info = proc->module->info;

			Entity **found = map_get(&info->definitions, hash_pointer(pd->name));
			GB_ASSERT_MSG(found != NULL, "Unable to find: %.*s", LIT(pd->name->Ident.string));
			Entity *e = *found;

			// FFI - Foreign function interace
			String original_name = pd->name->Ident.string;
			String name = original_name;
			if (pd->foreign_name.len > 0) {
				name = pd->foreign_name;
			}

			ssaValue *value = ssa_make_value_procedure(proc->module->allocator,
			                                           proc->module, e, e->type, pd->type, pd->body, name);

			value->Proc.tags = pd->tags;

			ssa_module_add_value(proc->module, e, value);
			ssa_build_proc(value, proc);

			if (value->Proc.tags & ProcTag_foreign) {
				HashKey key = hash_string(name);
				auto *prev_value = map_get(&proc->module->members, key);
				if (prev_value == NULL) {
					// NOTE(bill): Don't do mutliple declarations in the IR
					map_set(&proc->module->members, key, value);
				}
			} else {
				array_add(&proc->children, &value->Proc);
			}
		}
	case_end;

	case_ast_node(td, TypeDecl, node);

		// NOTE(bill): Generate a new name
		// parent_proc.name-guid
		String td_name = td->name->Ident.string;
		isize name_len = proc->name.len + 1 + td_name.len + 1 + 10 + 1;
		u8 *name_text = gb_alloc_array(proc->module->allocator, u8, name_len);
		i32 guid = cast(i32)proc->module->members.entries.count;
		name_len = gb_snprintf(cast(char *)name_text, name_len, "%.*s.%.*s-%d", LIT(proc->name), LIT(td_name), guid);
		String name = make_string(name_text, name_len-1);

		Entity **found = map_get(&proc->module->info->definitions, hash_pointer(td->name));
		GB_ASSERT(found != NULL);
		Entity *e = *found;
		ssaValue *value = ssa_make_value_type_name(proc->module->allocator,
		                                           name, e->type);
		map_set(&proc->module->type_names, hash_pointer(e->type), name);
		ssa_gen_global_type_name(proc->module, e, name);
	case_end;

	case_ast_node(ids, IncDecStmt, node);
		ssa_emit_comment(proc, make_string("IncDecStmt"));
		TokenKind op = ids->op.kind;
		if (op == Token_Increment) {
			op = Token_Add;
		} else if (op == Token_Decrement) {
			op = Token_Sub;
		}
		ssaAddr lval = ssa_build_addr(proc, ids->expr);
		ssaValue *one = ssa_emit_conv(proc, v_one, ssa_addr_type(lval));
		ssa_build_assign_op(proc, lval, one, op);

	case_end;

	case_ast_node(as, AssignStmt, node);
		ssa_emit_comment(proc, make_string("AssignStmt"));

		ssaModule *m = proc->module;
		gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&m->tmp_arena);
		defer (gb_temp_arena_memory_end(tmp));

		switch (as->op.kind) {
		case Token_Eq: {
			Array<ssaAddr> lvals;
			array_init(&lvals, m->tmp_allocator);

			for_array(i, as->lhs) {
				AstNode *lhs = as->lhs[i];
				ssaAddr lval = {};
				if (!ssa_is_blank_ident(lhs)) {
					lval = ssa_build_addr(proc, lhs);
				}
				array_add(&lvals, lval);
			}

			if (as->lhs.count == as->rhs.count) {
				if (as->lhs.count == 1) {
					AstNode *rhs = as->rhs[0];
					ssaValue *init = ssa_build_expr(proc, rhs);
					ssa_addr_store(proc, lvals[0], init);
				} else {
					Array<ssaValue *> inits;
					array_init(&inits, m->tmp_allocator, lvals.count);

					for_array(i, as->rhs) {
						ssaValue *init = ssa_build_expr(proc, as->rhs[i]);
						array_add(&inits, init);
					}

					for_array(i, inits) {
						ssa_addr_store(proc, lvals[i], inits[i]);
					}
				}
			} else {
				Array<ssaValue *> inits;
				array_init(&inits, m->tmp_allocator, lvals.count);

				for_array(i, as->rhs) {
					ssaValue *init = ssa_build_expr(proc, as->rhs[i]);
					Type *t = ssa_type(init);
					// TODO(bill): refactor for code reuse as this is repeated a bit
					if (t->kind == Type_Tuple) {
						for (isize i = 0; i < t->Tuple.variable_count; i++) {
							Entity *e = t->Tuple.variables[i];
							ssaValue *v = ssa_emit_struct_ev(proc, init, i);
							array_add(&inits, v);
						}
					} else {
						array_add(&inits, init);
					}
				}

				for_array(i, inits) {
					ssa_addr_store(proc, lvals[i], inits[i]);
				}
			}

		} break;

		default: {
			// NOTE(bill): Only 1 += 1 is allowed, no tuples
			// +=, -=, etc
			i32 op = cast(i32)as->op.kind;
			op += Token_Add - Token_AddEq; // Convert += to +
			ssaAddr lhs = ssa_build_addr(proc, as->lhs[0]);
			ssaValue *value = ssa_build_expr(proc, as->rhs[0]);
			ssa_build_assign_op(proc, lhs, value, cast(TokenKind)op);
		} break;
		}
	case_end;

	case_ast_node(es, ExprStmt, node);
		// NOTE(bill): No need to use return value
		ssa_build_expr(proc, es->expr);
	case_end;

	case_ast_node(bs, BlockStmt, node);
		ssa_open_scope(proc);
		ssa_build_stmt_list(proc, bs->stmts);
		ssa_close_scope(proc, ssaDeferExit_Default, NULL);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		ssa_emit_comment(proc, make_string("DeferStmt"));
		isize scope_index = proc->scope_index;
		if (ds->stmt->kind == AstNode_BlockStmt) {
			scope_index--;
		}
		ssa_add_defer_node(proc, scope_index, ds->stmt);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		ssa_emit_comment(proc, make_string("ReturnStmt"));
		ssaValue *v = NULL;
		auto *return_type_tuple  = &proc->type->Proc.results->Tuple;
		isize return_count = proc->type->Proc.result_count;
		if (return_count == 0) {
			// No return values
		} else if (return_count == 1) {
			Entity *e = return_type_tuple->variables[0];
			v = ssa_emit_conv(proc, ssa_build_expr(proc, rs->results[0]), e->type);
		} else {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&proc->module->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			Array<ssaValue *> results;
			array_init(&results, proc->module->tmp_allocator, return_count);

			for_array(res_index, rs->results) {
				ssaValue *res = ssa_build_expr(proc, rs->results[res_index]);
				Type *t = ssa_type(res);
				if (t->kind == Type_Tuple) {
					for (isize i = 0; i < t->Tuple.variable_count; i++) {
						Entity *e = t->Tuple.variables[i];
						ssaValue *v = ssa_emit_struct_ev(proc, res, i);
						array_add(&results, v);
					}
				} else {
					array_add(&results, res);
				}
			}

			Type *ret_type = proc->type->Proc.results;
			v = ssa_add_local_generated(proc, ret_type);
			for_array(i, results) {
				Entity *e = return_type_tuple->variables[i];
				ssaValue *res = ssa_emit_conv(proc, results[i], e->type);
				ssaValue *field = ssa_emit_struct_ep(proc, v, i);
				ssa_emit_store(proc, field, res);
			}

			v = ssa_emit_load(proc, v);

		}
		ssa_emit_return(proc, v);

	case_end;

	case_ast_node(is, IfStmt, node);
		ssa_emit_comment(proc, make_string("IfStmt"));
		if (is->init != NULL) {
			ssaBlock *init = ssa_add_block(proc, node, "if.init");
			ssa_emit_jump(proc, init);
			proc->curr_block = init;
			ssa_build_stmt(proc, is->init);
		}
		ssaBlock *then = ssa_add_block(proc, node, "if.then");
		ssaBlock *done = ssa_add_block(proc, node, "if.done"); // NOTE(bill): Append later
		ssaBlock *else_ = done;
		if (is->else_stmt != NULL) {
			else_ = ssa_add_block(proc, is->else_stmt, "if.else");
		}

		ssa_build_cond(proc, is->cond, then, else_);
		proc->curr_block = then;

		ssa_open_scope(proc);
		ssa_build_stmt(proc, is->body);
		ssa_close_scope(proc, ssaDeferExit_Default, NULL);

		ssa_emit_jump(proc, done);

		if (is->else_stmt != NULL) {
			proc->curr_block = else_;

			ssa_open_scope(proc);
			ssa_build_stmt(proc, is->else_stmt);
			ssa_close_scope(proc, ssaDeferExit_Default, NULL);

			ssa_emit_jump(proc, done);
		}
		proc->curr_block = done;
	case_end;

	case_ast_node(fs, ForStmt, node);
		ssa_emit_comment(proc, make_string("ForStmt"));
		if (fs->init != NULL) {
			ssaBlock *init = ssa_add_block(proc, node, "for.init");
			ssa_emit_jump(proc, init);
			proc->curr_block = init;
			ssa_build_stmt(proc, fs->init);
		}
		ssaBlock *body = ssa_add_block(proc, node, "for.body");
		ssaBlock *done = ssa_add_block(proc, node, "for.done"); // NOTE(bill): Append later

		ssaBlock *loop = body;

		if (fs->cond != NULL) {
			loop = ssa_add_block(proc, node, "for.loop");
		}
		ssaBlock *cont = loop;
		if (fs->post != NULL) {
			cont = ssa_add_block(proc, node, "for.post");

		}
		ssa_emit_jump(proc, loop);
		proc->curr_block = loop;
		if (loop != body) {
			ssa_build_cond(proc, fs->cond, body, done);
			proc->curr_block = body;
		}

		ssa_push_target_list(proc, done, cont, NULL);

		ssa_open_scope(proc);
		ssa_build_stmt(proc, fs->body);
		ssa_close_scope(proc, ssaDeferExit_Default, NULL);

		ssa_pop_target_list(proc);
		ssa_emit_jump(proc, cont);

		if (fs->post != NULL) {
			proc->curr_block = cont;
			ssa_build_stmt(proc, fs->post);
			ssa_emit_jump(proc, loop);
		}


		proc->curr_block = done;

	case_end;

	case_ast_node(ms, MatchStmt, node);
		ssa_emit_comment(proc, make_string("MatchStmt"));
		if (ms->init != NULL) {
			ssa_build_stmt(proc, ms->init);
		}
		ssaValue *tag = v_true;
		if (ms->tag != NULL) {
			tag = ssa_build_expr(proc, ms->tag);
		}
		ssaBlock *done = ssa_add_block(proc, node, "match.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ms->body);

		AstNodeArray default_stmts = {};
		ssaBlock *default_fall = NULL;
		ssaBlock *default_block = NULL;

		ssaBlock *fall = NULL;
		b32 append_fall = false;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts[i];
			ssaBlock *body = fall;

			ast_node(cc, CaseClause, clause);

			if (body == NULL) {
				if (cc->list.count == 0) {
					body = ssa_add_block(proc, clause, "match.dflt.body");
				} else {
					body = ssa_add_block(proc, clause, "match.case.body");
				}
			}
			if (append_fall && body == fall) {
				append_fall = false;
			}

			fall = done;
			if (i+1 < case_count) {
				append_fall = true;
				fall = ssa_add_block(proc, clause, "match.fall.body");
			}

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_fall  = fall;
				default_block = body;
				continue;
			}

			ssaBlock *next_cond = NULL;
			for_array(j, cc->list) {
				AstNode *expr = cc->list[j];
				next_cond = ssa_add_block(proc, clause, "match.case.next");

				ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag, ssa_build_expr(proc, expr));
				ssa_emit_if(proc, cond, body, next_cond);
				proc->curr_block = next_cond;
			}
			proc->curr_block = body;

			ssa_push_target_list(proc, done, NULL, fall);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, cc->stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, body);
			ssa_pop_target_list(proc);

			ssa_emit_jump(proc, done);
			proc->curr_block = next_cond;
		}

		if (default_block != NULL) {
			ssa_emit_jump(proc, default_block);
			proc->curr_block = default_block;

			ssa_push_target_list(proc, done, NULL, default_fall);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, default_stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, default_block);
			ssa_pop_target_list(proc);
		}

		ssa_emit_jump(proc, done);
		proc->curr_block = done;
	case_end;


	case_ast_node(ms, TypeMatchStmt, node);
		ssa_emit_comment(proc, make_string("TypeMatchStmt"));
		gbAllocator allocator = proc->module->allocator;

		ssaValue *parent = ssa_build_expr(proc, ms->tag);
		Type *union_type = type_deref(ssa_type(parent));
		GB_ASSERT(is_type_union(union_type));

		ssa_emit_comment(proc, make_string("get union's tag"));
		ssaValue *tag_index = ssa_emit_struct_ep(proc, parent, 1);
		tag_index = ssa_emit_load(proc, tag_index);

		ssaValue *data = ssa_emit_conv(proc, parent, t_rawptr);

		ssaBlock *start_block = ssa_add_block(proc, node, "type-match.case.first");
		ssa_emit_jump(proc, start_block);
		proc->curr_block = start_block;

		ssaBlock *done = ssa_add_block(proc, node, "type-match.done"); // NOTE(bill): Append later

		ast_node(body, BlockStmt, ms->body);


		String tag_var_name = ms->var->Ident.string;

		AstNodeArray default_stmts = {};
		ssaBlock *default_block = NULL;

		isize case_count = body->stmts.count;
		for_array(i, body->stmts) {
			AstNode *clause = body->stmts[i];
			ast_node(cc, CaseClause, clause);

			if (cc->list.count == 0) {
				// default case
				default_stmts = cc->stmts;
				default_block = ssa_add_block(proc, clause, "type-match.dflt.body");
				continue;
			}


			ssaBlock *body = ssa_add_block(proc, clause, "type-match.case.body");

			Scope *scope = *map_get(&proc->module->info->scopes, hash_pointer(clause));
			Entity *tag_var_entity = current_scope_lookup_entity(scope, tag_var_name);
			GB_ASSERT_MSG(tag_var_entity != NULL, "%.*s", LIT(tag_var_name));
			ssaValue *tag_var = ssa_add_local(proc, tag_var_entity);
			ssaValue *data_ptr = ssa_emit_conv(proc, data, tag_var_entity->type);
			ssa_emit_store(proc, tag_var, data_ptr);



			Type *bt = type_deref(tag_var_entity->type);
			ssaValue *index = NULL;
			Type *ut = base_type(union_type);
			GB_ASSERT(ut->Record.kind == TypeRecord_Union);
			for (isize field_index = 1; field_index < ut->Record.field_count; field_index++) {
				Entity *f = base_type(union_type)->Record.fields[field_index];
				if (are_types_identical(f->type, bt)) {
					index = ssa_make_const_int(allocator, field_index);
					break;
				}
			}
			GB_ASSERT(index != NULL);

			ssaBlock *next_cond = ssa_add_block(proc, clause, "type-match.case.next");
			ssaValue *cond = ssa_emit_comp(proc, Token_CmpEq, tag_index, index);
			ssa_emit_if(proc, cond, body, next_cond);
			proc->curr_block = next_cond;

			proc->curr_block = body;

			ssa_push_target_list(proc, done, NULL, NULL);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, cc->stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, body);
			ssa_pop_target_list(proc);

			ssa_emit_jump(proc, done);
			proc->curr_block = next_cond;
		}

		if (default_block != NULL) {
			ssa_emit_jump(proc, default_block);
			proc->curr_block = default_block;

			ssa_push_target_list(proc, done, NULL, NULL);
			ssa_open_scope(proc);
			ssa_build_stmt_list(proc, default_stmts);
			ssa_close_scope(proc, ssaDeferExit_Default, default_block);
			ssa_pop_target_list(proc);
		}

		ssa_emit_jump(proc, done);
		proc->curr_block = done;
	case_end;

	case_ast_node(bs, BranchStmt, node);
		ssaBlock *block = NULL;
		switch (bs->token.kind) {
		case Token_break:
			for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->break_;
			}
			break;
		case Token_continue:
			for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->continue_;
			}
			break;
		case Token_fallthrough:
			for (ssaTargetList *t = proc->target_list; t != NULL && block == NULL; t = t->prev) {
				block = t->fallthrough_;
			}
			break;
		}
		if (block != NULL) {
			ssa_emit_defer_stmts(proc, ssaDeferExit_Branch, block);
		}
		switch (bs->token.kind) {
		case Token_break:       ssa_emit_comment(proc, make_string("break"));       break;
		case Token_continue:    ssa_emit_comment(proc, make_string("continue"));    break;
		case Token_fallthrough: ssa_emit_comment(proc, make_string("fallthrough")); break;
		}
		ssa_emit_jump(proc, block);
		ssa_emit_unreachable(proc);
	case_end;



	case_ast_node(pa, PushAllocator, node);
		ssa_emit_comment(proc, make_string("PushAllocator"));
		ssa_open_scope(proc);
		defer (ssa_close_scope(proc, ssaDeferExit_Default, NULL));

		ssaValue *context_ptr = ssa_find_implicit_value_backing(proc, ImplicitValue_context);
		ssaValue *prev_context = ssa_add_local_generated(proc, t_context);
		ssa_emit_store(proc, prev_context, ssa_emit_load(proc, context_ptr));

		ssa_add_defer_instr(proc, proc->scope_index, ssa_make_instr_store(proc, context_ptr, ssa_emit_load(proc, prev_context)));

		ssaValue *gep = ssa_emit_struct_ep(proc, context_ptr, 1);
		ssa_emit_store(proc, gep, ssa_build_expr(proc, pa->expr));

		ssa_build_stmt(proc, pa->body);

	case_end;


	case_ast_node(pa, PushContext, node);
		ssa_emit_comment(proc, make_string("PushContext"));
		ssa_open_scope(proc);
		defer (ssa_close_scope(proc, ssaDeferExit_Default, NULL));

		ssaValue *context_ptr = ssa_find_implicit_value_backing(proc, ImplicitValue_context);
		ssaValue *prev_context = ssa_add_local_generated(proc, t_context);
		ssa_emit_store(proc, prev_context, ssa_emit_load(proc, context_ptr));

		ssa_add_defer_instr(proc, proc->scope_index, ssa_make_instr_store(proc, context_ptr, ssa_emit_load(proc, prev_context)));

		ssa_emit_store(proc, context_ptr, ssa_build_expr(proc, pa->expr));

		ssa_build_stmt(proc, pa->body);
	case_end;


	}
}


