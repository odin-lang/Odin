gb_internal cgValue cg_flatten_value(cgProcedure *p, cgValue value) {
	if (value.kind == cgValue_Symbol) {
		GB_ASSERT(is_type_internally_pointer_like(value.type));
		value = cg_value(tb_inst_get_symbol_address(p->func, value.symbol), value.type);
	}
	return value;
}

gb_internal cgContextData *cg_push_context_onto_stack(cgProcedure *p, cgAddr ctx) {
	ctx.kind = cgAddr_Context;
	cgContextData *cd = array_add_and_get(&p->context_stack);
	cd->ctx = ctx;
	cd->scope_index = p->scope_index;
	return cd;
}

gb_internal cgAddr cg_find_or_generate_context_ptr(cgProcedure *p) {
	if (p->context_stack.count > 0) {
		return p->context_stack[p->context_stack.count-1].ctx;
	}

	Type *pt = base_type(p->type);
	GB_ASSERT(pt->kind == Type_Proc);
	GB_ASSERT(pt->Proc.calling_convention != ProcCC_Odin);

	cgAddr c = cg_add_local(p, t_context, nullptr, true);
	tb_node_append_attrib(c.addr.node, tb_function_attrib_variable(p->func, -1, "context", cg_debug_type(p->module, t_context)));
	c.kind = cgAddr_Context;
	// lb_emit_init_context(p, c);
	cg_push_context_onto_stack(p, c);
	// lb_add_debug_context_variable(p, c);

	return c;
}

gb_internal cgValue cg_find_value_from_entity(cgModule *m, Entity *e) {
	e = strip_entity_wrapping(e);
	GB_ASSERT(e != nullptr);

	GB_ASSERT(e->token.string != "_");

	if (e->kind == Entity_Procedure) {
		return cg_find_procedure_value_from_entity(m, e);
	}

	cgValue *found = nullptr;
	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);
	if (found) {
		return *found;
	}

	GB_PANIC("\n\tError in: %s, missing value '%.*s'\n", token_pos_to_string(e->token.pos), LIT(e->token.string));
	return {};
}

gb_internal cgAddr cg_build_addr_from_entity(cgProcedure *p, Entity *e, Ast *expr) {
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_Constant) {
		Type *t = default_type(type_of_expr(expr));
		cgValue v = cg_const_value(p, t, e->Constant.value);
		GB_PANIC("TODO(bill): cg_add_global_generated");
		// return cg_add_global_generated(p->module, t, v);
		return {};
	}

	cgAddr *local_found = map_get(&p->variable_map, e);
	if (local_found) {
		return *local_found;
	}

	cgValue v = {};

	cgModule *m = p->module;

	rw_mutex_lock(&m->values_mutex);
	cgValue *found = map_get(&m->values, e);
	rw_mutex_unlock(&m->values_mutex);
	if (found) {
		v = *found;
	} else if (e->kind == Entity_Variable && e->flags & EntityFlag_Using) {
		GB_PANIC("TODO(bill): cg_get_using_variable");
		// NOTE(bill): Calculate the using variable every time
		// v = cg_get_using_variable(p, e);
	} else if (e->flags & EntityFlag_SoaPtrField) {
		GB_PANIC("TODO(bill): cg_get_soa_variable_addr");
		// return cg_get_soa_variable_addr(p, e);
	}


	if (v.node == nullptr) {
		cgValue v = cg_find_value_from_entity(m, e);
		v = cg_flatten_value(p, v);
		return cg_addr(v);
	}

	return cg_addr(v);
}

gb_internal cgValue cg_typeid(cgModule *m, Type *t) {
	GB_ASSERT("TODO(bill): cg_typeid");
	return {};
}


gb_internal cgValue cg_correct_endianness(cgProcedure *p, cgValue value) {
	Type *src = core_type(value.type);
	GB_ASSERT(is_type_integer(src) || is_type_float(src));
	if (is_type_different_to_arch_endianness(src)) {
		GB_PANIC("TODO(bill): cg_correct_endianness");
		// Type *platform_src_type = integer_endian_type_to_platform_type(src);
		// value = cg_emit_byte_swap(p, value, platform_src_type);
	}
	return value;
}

gb_internal cgValue cg_emit_conv(cgProcedure *p, cgValue value, Type *type) {
	// TODO(bill): cg_emit_conv
	return value;
}

gb_internal cgValue cg_emit_transmute(cgProcedure *p, cgValue value, Type *type) {
	GB_ASSERT(type_size_of(value.type) == type_size_of(type));

	value = cg_flatten_value(p, value);

	i64 src_align = type_align_of(value.type);
	i64 dst_align = type_align_of(type);

	if (dst_align > src_align) {
		cgAddr local = cg_add_local(p, type, nullptr, false);
		cgValue dst = local.addr;
		dst.type = alloc_type_pointer(value.type);
		cg_emit_store(p, dst, value);
		return cg_addr_load(p, local);
	}

	TB_DataType dt = cg_data_type(type);
	switch (value.kind) {
	case cgValue_Value:
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
		value.type = type;
		value.node = tb_inst_bitcast(p->func, value.node, dt);
		return value;
	case cgValue_Addr:
		value.type = type;
		return value;
	case cgValue_Symbol:
		GB_PANIC("should be handled above");
		break;
	}
	return value;

}


gb_internal cgAddr cg_build_addr_slice_expr(cgProcedure *p, Ast *expr) {
	ast_node(se, SliceExpr, expr);

	cgValue low  = cg_const_int(p, t_int, 0);
	cgValue high = {};

	if (se->low  != nullptr) {
		low = cg_correct_endianness(p, cg_build_expr(p, se->low));
	}
	if (se->high != nullptr) {
		high = cg_correct_endianness(p, cg_build_expr(p, se->high));
	}

	bool no_indices = se->low == nullptr && se->high == nullptr;
	gb_unused(no_indices);

	cgAddr addr = cg_build_addr(p, se->expr);
	cgValue base = cg_addr_load(p, addr);
	Type *type = base_type(base.type);

	if (is_type_pointer(type)) {
		type = base_type(type_deref(type));
		addr = cg_addr(base);
		base = cg_addr_load(p, addr);
	}

	switch (type->kind) {
	case Type_Slice: {
		// Type *slice_type = type;
		// cgValue len = cg_slice_len(p, base);
		// if (high.value == nullptr) high = len;

		// if (!no_indices) {
		// 	cg_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		// }

		// cgValue elem    = cg_emit_ptr_offset(p, cg_slice_elem(p, base), low);
		// cgValue new_len = cg_emit_arith(p, Token_Sub, high, low, t_int);

		// cgAddr slice = cg_add_local_generated(p, slice_type, false);
		// cg_fill_slice(p, slice, elem, new_len);
		// return slice;
		GB_PANIC("cg_build_addr_slice_expr Type_Slice");
		break;
	}

	case Type_RelativeSlice:
		GB_PANIC("TODO(bill): Type_RelativeSlice should be handled above already on the cg_addr_load");
		break;

	case Type_DynamicArray: {
		// Type *elem_type = type->DynamicArray.elem;
		// Type *slice_type = alloc_type_slice(elem_type);

		// lbValue len = lb_dynamic_array_len(p, base);
		// if (high.value == nullptr) high = len;

		// if (!no_indices) {
		// 	lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		// }

		// lbValue elem    = lb_emit_ptr_offset(p, lb_dynamic_array_elem(p, base), low);
		// lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		// lbAddr slice = lb_add_local_generated(p, slice_type, false);
		// lb_fill_slice(p, slice, elem, new_len);
		// return slice;
		GB_PANIC("cg_build_addr_slice_expr Type_DynamicArray");
		break;
	}

	case Type_MultiPointer: {
		// lbAddr res = lb_add_local_generated(p, type_of_expr(expr), false);
		// if (se->high == nullptr) {
		// 	lbValue offset = base;
		// 	LLVMValueRef indices[1] = {low.value};
		// 	offset.value = LLVMBuildGEP2(p->builder, lb_type(p->module, offset.type->MultiPointer.elem), offset.value, indices, 1, "");
		// 	lb_addr_store(p, res, offset);
		// } else {
		// 	low = lb_emit_conv(p, low, t_int);
		// 	high = lb_emit_conv(p, high, t_int);

		// 	lb_emit_multi_pointer_slice_bounds_check(p, se->open, low, high);

		// 	LLVMValueRef indices[1] = {low.value};
		// 	LLVMValueRef ptr = LLVMBuildGEP2(p->builder, lb_type(p->module, base.type->MultiPointer.elem), base.value, indices, 1, "");
		// 	LLVMValueRef len = LLVMBuildSub(p->builder, high.value, low.value, "");

		// 	LLVMValueRef gep0 = lb_emit_struct_ep(p, res.addr, 0).value;
		// 	LLVMValueRef gep1 = lb_emit_struct_ep(p, res.addr, 1).value;
		// 	LLVMBuildStore(p->builder, ptr, gep0);
		// 	LLVMBuildStore(p->builder, len, gep1);
		// }
		// return res;
		GB_PANIC("cg_build_addr_slice_expr Type_MultiPointer");
		break;
	}

	case Type_Array: {
		// Type *slice_type = alloc_type_slice(type->Array.elem);
		// lbValue len = lb_const_int(p->module, t_int, type->Array.count);

		// if (high.value == nullptr) high = len;

		// bool low_const  = type_and_value_of_expr(se->low).mode  == Addressing_Constant;
		// bool high_const = type_and_value_of_expr(se->high).mode == Addressing_Constant;

		// if (!low_const || !high_const) {
		// 	if (!no_indices) {
		// 		lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		// 	}
		// }
		// lbValue elem    = lb_emit_ptr_offset(p, lb_array_elem(p, lb_addr_get_ptr(p, addr)), low);
		// lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		// lbAddr slice = lb_add_local_generated(p, slice_type, false);
		// lb_fill_slice(p, slice, elem, new_len);
		// return slice;
		GB_PANIC("cg_build_addr_slice_expr Type_Array");
		break;
	}

	case Type_Basic: {
		// GB_ASSERT(type == t_string);
		// lbValue len = lb_string_len(p, base);
		// if (high.value == nullptr) high = len;

		// if (!no_indices) {
		// 	lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		// }

		// lbValue elem    = lb_emit_ptr_offset(p, lb_string_elem(p, base), low);
		// lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);

		// lbAddr str = lb_add_local_generated(p, t_string, false);
		// lb_fill_string(p, str, elem, new_len);
		// return str;
		GB_PANIC("cg_build_addr_slice_expr Type_Basic");
		break;
	}


	case Type_Struct:
		// if (is_type_soa_struct(type)) {
		// 	lbValue len = lb_soa_struct_len(p, lb_addr_get_ptr(p, addr));
		// 	if (high.value == nullptr) high = len;

		// 	if (!no_indices) {
		// 		lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		// 	}
		// 	#if 1

		// 	lbAddr dst = lb_add_local_generated(p, type_of_expr(expr), true);
		// 	if (type->Struct.soa_kind == StructSoa_Fixed) {
		// 		i32 field_count = cast(i32)type->Struct.fields.count;
		// 		for (i32 i = 0; i < field_count; i++) {
		// 			lbValue field_dst = lb_emit_struct_ep(p, dst.addr, i);
		// 			lbValue field_src = lb_emit_struct_ep(p, lb_addr_get_ptr(p, addr), i);
		// 			field_src = lb_emit_array_ep(p, field_src, low);
		// 			lb_emit_store(p, field_dst, field_src);
		// 		}

		// 		lbValue len_dst = lb_emit_struct_ep(p, dst.addr, field_count);
		// 		lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
		// 		lb_emit_store(p, len_dst, new_len);
		// 	} else if (type->Struct.soa_kind == StructSoa_Slice) {
		// 		if (no_indices) {
		// 			lb_addr_store(p, dst, base);
		// 		} else {
		// 			i32 field_count = cast(i32)type->Struct.fields.count - 1;
		// 			for (i32 i = 0; i < field_count; i++) {
		// 				lbValue field_dst = lb_emit_struct_ep(p, dst.addr, i);
		// 				lbValue field_src = lb_emit_struct_ev(p, base, i);
		// 				field_src = lb_emit_ptr_offset(p, field_src, low);
		// 				lb_emit_store(p, field_dst, field_src);
		// 			}


		// 			lbValue len_dst = lb_emit_struct_ep(p, dst.addr, field_count);
		// 			lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
		// 			lb_emit_store(p, len_dst, new_len);
		// 		}
		// 	} else if (type->Struct.soa_kind == StructSoa_Dynamic) {
		// 		i32 field_count = cast(i32)type->Struct.fields.count - 3;
		// 		for (i32 i = 0; i < field_count; i++) {
		// 			lbValue field_dst = lb_emit_struct_ep(p, dst.addr, i);
		// 			lbValue field_src = lb_emit_struct_ev(p, base, i);
		// 			field_src = lb_emit_ptr_offset(p, field_src, low);
		// 			lb_emit_store(p, field_dst, field_src);
		// 		}


		// 		lbValue len_dst = lb_emit_struct_ep(p, dst.addr, field_count);
		// 		lbValue new_len = lb_emit_arith(p, Token_Sub, high, low, t_int);
		// 		lb_emit_store(p, len_dst, new_len);
		// 	}

		// 	return dst;
		// 	#endif
		// }
		GB_PANIC("cg_build_addr_slice_expr Type_Struct");
		break;

	}

	GB_PANIC("Unknown slicable type");
	return {};
}




gb_internal cgValue cg_build_expr_internal(cgProcedure *p, Ast *expr);
gb_internal cgValue cg_build_expr(cgProcedure *p, Ast *expr) {
	u16 prev_state_flags = p->state_flags;
	defer (p->state_flags = prev_state_flags);

	if (expr->state_flags != 0) {
		u16 in = expr->state_flags;
		u16 out = p->state_flags;

		if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		} else if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		}

		if (in & StateFlag_type_assert) {
			out |= StateFlag_type_assert;
			out &= ~StateFlag_no_type_assert;
		} else if (in & StateFlag_no_type_assert) {
			out |= StateFlag_no_type_assert;
			out &= ~StateFlag_type_assert;
		}

		p->state_flags = out;
	}


	// IMPORTANT NOTE(bill):
	// Selector Call Expressions (foo->bar(...))
	// must only evaluate `foo` once as it gets transformed into
	// `foo.bar(foo, ...)`
	// And if `foo` is a procedure call or something more complex, storing the value
	// once is a very good idea
	// If a stored value is found, it must be removed from the cache
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// cgValue *pp = map_get(&p->selector_values, expr);
		// if (pp != nullptr) {
		// 	cgValue res = *pp;
		// 	map_remove(&p->selector_values, expr);
		// 	return res;
		// }
		// cgAddr *pa = map_get(&p->selector_addr, expr);
		// if (pa != nullptr) {
		// 	cgAddr res = *pa;
		// 	map_remove(&p->selector_addr, expr);
		// 	return cg_addr_load(p, res);
		// }
	}

	cgValue res = cg_build_expr_internal(p, expr);
	if (res.kind == cgValue_Symbol) {
		GB_ASSERT(is_type_internally_pointer_like(res.type));
		res = cg_value(tb_inst_get_symbol_address(p->func, res.symbol), res.type);
	}

	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// map_set(&p->selector_values, expr, res);
	}
	return res;
}



gb_internal cgValue cg_build_expr_internal(cgProcedure *p, Ast *expr) {
	cgModule *m = p->module;

	expr = unparen_expr(expr);

	TokenPos expr_pos = ast_token(expr).pos;
	TypeAndValue tv = type_and_value_of_expr(expr);
	Type *type = type_of_expr(expr);
	GB_ASSERT_MSG(tv.mode != Addressing_Invalid, "invalid expression '%s' (tv.mode = %d, tv.type = %s) @ %s\n Current Proc: %.*s : %s", expr_to_string(expr), tv.mode, type_to_string(tv.type), token_pos_to_string(expr_pos), LIT(p->name), type_to_string(p->type));

	if (tv.value.kind != ExactValue_Invalid) {
		// NOTE(bill): The commented out code below is just for debug purposes only
		// if (is_type_untyped(type)) {
		// 	gb_printf_err("%s %s : %s @ %p\n", token_pos_to_string(expr_pos), expr_to_string(expr), type_to_string(expr->tav.type), expr);
		// 	GB_PANIC("%s\n", type_to_string(tv.type));
		// }

		// NOTE(bill): Short on constant values
		return cg_const_value(p, type, tv.value);
	} else if (tv.mode == Addressing_Type) {
		// NOTE(bill, 2023-01-16): is this correct? I hope so at least
		return cg_typeid(m, tv.type);
	}

	switch (expr->kind) {
	case_ast_node(bl, BasicLit, expr);
		TokenPos pos = bl->token.pos;
		GB_PANIC("Non-constant basic literal %s - %.*s", token_pos_to_string(pos), LIT(token_strings[bl->token.kind]));
	case_end;

	case_ast_node(bd, BasicDirective, expr);
		TokenPos pos = bd->token.pos;
		GB_PANIC("Non-constant basic literal %s - %.*s", token_pos_to_string(pos), LIT(bd->name.string));
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *e = entity_from_expr(expr);
		e = strip_entity_wrapping(e);

		GB_ASSERT_MSG(e != nullptr, "%s in %.*s %p", expr_to_string(expr), LIT(p->name), expr);

		if (e->kind == Entity_Builtin) {
			Token token = ast_token(expr);
			GB_PANIC("TODO(bill): lb_build_expr Entity_Builtin '%.*s'\n"
			         "\t at %s", LIT(builtin_procs[e->Builtin.id].name),
			         token_pos_to_string(token.pos));
			return {};
		} else if (e->kind == Entity_Nil) {
			GB_PANIC("TODO: cg_find_ident nil");
			// TODO(bill): is this correct?
			return cg_value(cast(TB_Node *)nullptr, e->type);
		}
		GB_ASSERT(e->kind != Entity_ProcGroup);

		cgAddr *addr = map_get(&p->variable_map, e);
		if (addr) {
			return cg_addr_load(p, *addr);
		}
		// return cg_find_ident(p, m, e, expr);
		GB_PANIC("TODO: cg_find_ident");
		return {};
	case_end;

	case_ast_node(i, Implicit, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(u, Uninit, expr);
		if (is_type_untyped(type)) {
			return cg_value(cast(TB_Node *)nullptr, t_untyped_uninit);
		}
		return cg_value(tb_inst_poison(p->func), type);
	case_end;

	case_ast_node(de, DerefExpr, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;


	case_ast_node(se, SelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode != Addressing_Invalid);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(ise, ImplicitSelectorExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(expr);
		GB_ASSERT(tav.mode == Addressing_Constant);

		return cg_const_value(p, type, tv.value);
	case_end;


	case_ast_node(se, SelectorCallExpr, expr);
		GB_ASSERT(se->modified_call);
		return cg_build_call_expr(p, se->call);
	case_end;

	case_ast_node(i, CallExpr, expr);
		return cg_build_call_expr(p, expr);
	case_end;


	case_ast_node(te, TernaryIfExpr, expr);
		GB_PANIC("TODO(bill): TernaryIfExpr");
	case_end;

	case_ast_node(te, TernaryWhenExpr, expr);
		TypeAndValue tav = type_and_value_of_expr(te->cond);
		GB_ASSERT(tav.mode == Addressing_Constant);
		GB_ASSERT(tav.value.kind == ExactValue_Bool);
		if (tav.value.value_bool) {
			return cg_build_expr(p, te->x);
		} else {
			return cg_build_expr(p, te->y);
		}
	case_end;

	case_ast_node(tc, TypeCast, expr);
		cgValue e = cg_build_expr(p, tc->expr);
		switch (tc->token.kind) {
		case Token_cast:
			return cg_emit_conv(p, e, type);
		case Token_transmute:
			return cg_emit_transmute(p, e, type);
		}
		GB_PANIC("Invalid AST TypeCast");
	case_end;

	case_ast_node(ac, AutoCast, expr);
		cgValue value = cg_build_expr(p, ac->expr);
		return cg_emit_conv(p, value, type);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		if (is_type_slice(type_of_expr(se->expr))) {
			// NOTE(bill): Quick optimization
			if (se->high == nullptr &&
			    (se->low == nullptr || cg_is_expr_constant_zero(se->low))) {
				return cg_build_expr(p, se->expr);
			}
		}
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;
	}
	GB_PANIC("TODO(bill): cg_build_expr_internal %.*s", LIT(ast_strings[expr->kind]));
	return {};

}


gb_internal cgAddr cg_build_addr_internal(cgProcedure *p, Ast *expr);
gb_internal cgAddr cg_build_addr(cgProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);

	// IMPORTANT NOTE(bill):
	// Selector Call Expressions (foo->bar(...))
	// must only evaluate `foo` once as it gets transformed into
	// `foo.bar(foo, ...)`
	// And if `foo` is a procedure call or something more complex, storing the value
	// once is a very good idea
	// If a stored value is found, it must be removed from the cache
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// lbAddr *pp = map_get(&p->selector_addr, expr);
		// if (pp != nullptr) {
		// 	lbAddr res = *pp;
		// 	map_remove(&p->selector_addr, expr);
		// 	return res;
		// }
	}
	cgAddr addr = cg_build_addr_internal(p, expr);
	if (expr->state_flags & StateFlag_SelectorCallExpr) {
		// map_set(&p->selector_addr, expr, addr);
	}
	return addr;
}


gb_internal cgAddr cg_build_addr_internal(cgProcedure *p, Ast *expr) {
	switch (expr->kind) {
	case_ast_node(i, Implicit, expr);
		cgAddr v = {};
		switch (i->kind) {
		case Token_context:
			v = cg_find_or_generate_context_ptr(p);
			break;
		}

		GB_ASSERT(v.addr.node != nullptr);
		return v;
	case_end;

	case_ast_node(i, Ident, expr);
		if (is_blank_ident(expr)) {
			cgAddr val = {};
			return val;
		}
		String name = i->token.string;
		Entity *e = entity_of_node(expr);
		return cg_build_addr_from_entity(p, e, expr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return cg_build_addr_slice_expr(p, expr);
	case_end;
	}

	TokenPos token_pos = ast_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAst: %.*s @ "
	         "%s\n",
	         LIT(ast_strings[expr->kind]),
	         token_pos_to_string(token_pos));


	return {};
}