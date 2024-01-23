gb_internal cgValue cg_flatten_value(cgProcedure *p, cgValue value) {
	GB_ASSERT(value.kind != cgValue_Multi);
	if (value.kind == cgValue_Symbol) {
		GB_ASSERT(is_type_internally_pointer_like(value.type));
		return cg_value(tb_inst_get_symbol_address(p->func, value.symbol), value.type);
	} else if (value.kind == cgValue_Addr) {
		// TODO(bill): Is this a good idea?
		// this converts an lvalue to an rvalue if trivially possible
		TB_DataType dt = cg_data_type(value.type);
		if (!TB_IS_VOID_TYPE(dt)) {
			TB_CharUnits align = cast(TB_CharUnits)type_align_of(value.type);
			return cg_value(tb_inst_load(p->func, dt, value.node, align, false), value.type);
		}
	}
	return value;
}

gb_internal cgValue cg_emit_select(cgProcedure *p, cgValue const &cond, cgValue const &x, cgValue const &y) {
	GB_ASSERT(x.kind == y.kind);
	GB_ASSERT(cond.kind == cgValue_Value);
	cgValue res = x;
	res.node = tb_inst_select(p->func, cond.node, x.node, y.node);
	return res;
}


gb_internal bool cg_is_expr_untyped_const(Ast *expr) {
	auto const &tv = type_and_value_of_expr(expr);
	if (is_type_untyped(tv.type)) {
		return tv.value.kind != ExactValue_Invalid;
	}
	return false;
}
gb_internal cgValue cg_expr_untyped_const_to_typed(cgProcedure *p, Ast *expr, Type *t) {
	GB_ASSERT(is_type_typed(t));
	auto const &tv = type_and_value_of_expr(expr);
	return cg_const_value(p, t, tv.value);
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
	tb_function_attrib_variable(p->func, c.addr.node, nullptr, -1, "context", cg_debug_type(p->module, t_context));
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

gb_internal cgValue cg_get_using_variable(cgProcedure *p, Entity *e) {
	GB_ASSERT(e->kind == Entity_Variable && e->flags & EntityFlag_Using);
	String name = e->token.string;
	Entity *parent = e->using_parent;
	Selection sel = lookup_field(parent->type, name, false);
	GB_ASSERT(sel.entity != nullptr);
	cgValue *pv = map_get(&p->module->values, parent);

	cgValue v = {};

	if (pv == nullptr && parent->flags & EntityFlag_SoaPtrField) {
		// NOTE(bill): using SOA value (probably from for-in statement)
		GB_PANIC("TODO(bill): cg_get_soa_variable_addr");
		// cgAddr parent_addr = cg_get_soa_variable_addr(p, parent);
		// v = cg_addr_get_ptr(p, parent_addr);
	} else if (pv != nullptr) {
		v = *pv;
	} else {
		GB_ASSERT_MSG(e->using_expr != nullptr, "%.*s %.*s", LIT(e->token.string), LIT(name));
		v = cg_build_addr_ptr(p, e->using_expr);
	}
	GB_ASSERT(v.node != nullptr);
	GB_ASSERT_MSG(parent->type == type_deref(v.type), "%s %s", type_to_string(parent->type), type_to_string(v.type));
	cgValue ptr = cg_emit_deep_field_gep(p, v, sel);
	// if (parent->scope) {
	// 	if ((parent->scope->flags & (ScopeFlag_File|ScopeFlag_Pkg)) == 0) {
	// 		cg_add_debug_local_variable(p, ptr.value, e->type, e->token);
	// 	}
	// } else {
	// 	cg_add_debug_local_variable(p, ptr.value, e->type, e->token);
	// }
	return ptr;
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
		// NOTE(bill): Calculate the using variable every time
		v = cg_get_using_variable(p, e);
	} else if (e->flags & EntityFlag_SoaPtrField) {
		return map_must_get(&p->soa_values_map, e);
	}


	if (v.node == nullptr) {
		cgValue v = cg_find_value_from_entity(m, e);
		v = cg_flatten_value(p, v);
		return cg_addr(v);
	}

	return cg_addr(v);
}

gb_internal cgValue cg_emit_union_tag_ptr(cgProcedure *p, cgValue const &parent_ptr) {
	Type *t = parent_ptr.type;
	Type *ut = base_type(type_deref(t));
	GB_ASSERT_MSG(is_type_pointer(t), "%s", type_to_string(t));
	GB_ASSERT_MSG(ut->kind == Type_Union, "%s", type_to_string(t));

	GB_ASSERT(!is_type_union_maybe_pointer_original_alignment(ut));
	GB_ASSERT(!is_type_union_maybe_pointer(ut));
	GB_ASSERT(type_size_of(ut) > 0);

	Type *tag_type = union_tag_type(ut);
	i64 tag_offset = ut->Union.variant_block_size;

	GB_ASSERT(parent_ptr.kind == cgValue_Value);
	TB_Node *ptr = parent_ptr.node;
	TB_Node *tag_ptr = tb_inst_member_access(p->func, ptr, tag_offset);
	return cg_value(tag_ptr, alloc_type_pointer(tag_type));
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

gb_internal cgValue cg_emit_transmute(cgProcedure *p, cgValue value, Type *type) {
	GB_ASSERT(type_size_of(value.type) == type_size_of(type));

	value = cg_flatten_value(p, value);

	if (are_types_identical(value.type, type)) {
		return value;
	}
	if (are_types_identical(core_type(value.type), core_type(type))) {
		value.type = type;
		return value;
	}

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
		GB_ASSERT_MSG(!TB_IS_VOID_TYPE(dt), "%d %s -> %s", dt.type, type_to_string(value.type), type_to_string(type));
		value.type = type;
		if (value.node->dt.raw != dt.raw) {
			switch (value.node->dt.type) {
			case TB_INT:
				switch (value.node->dt.type) {
				case TB_INT:
					break;
				case TB_FLOAT:
					value.node = tb_inst_bitcast(p->func, value.node, dt);
					break;
				case TB_PTR:
					value.node = tb_inst_int2ptr(p->func, value.node);
					break;
				}
				break;
			case TB_FLOAT:
				switch (value.node->dt.type) {
				case TB_INT:
					value.node = tb_inst_bitcast(p->func, value.node, dt);
					break;
				case TB_FLOAT:
					break;
				case TB_PTR:
					value.node = tb_inst_bitcast(p->func, value.node, TB_TYPE_INTPTR);
					value.node = tb_inst_int2ptr(p->func, value.node);
					break;
				}
				break;
			case TB_PTR:
				switch (value.node->dt.type) {
				case TB_INT:
					value.node = tb_inst_ptr2int(p->func, value.node, dt);
					break;
				case TB_FLOAT:
					value.node = tb_inst_ptr2int(p->func, value.node, TB_TYPE_INTPTR);
					value.node = tb_inst_bitcast(p->func, value.node, dt);
					break;
				case TB_PTR:
					break;
				}
				break;
			}
		}
		return value;
	case cgValue_Addr:
		value.type = type;
		return value;
	case cgValue_Symbol:
		GB_PANIC("should be handled above");
		break;
	case cgValue_Multi:
		GB_PANIC("cannot transmute multiple values at once");
		break;
	}
	return value;

}
gb_internal cgValue cg_emit_byte_swap(cgProcedure *p, cgValue value, Type *end_type) {
	GB_ASSERT(type_size_of(value.type) == type_size_of(end_type));

	if (type_size_of(value.type) < 2) {
		return value;
	}

	if (is_type_float(value.type)) {
		i64 sz = type_size_of(value.type);
		Type *integer_type = nullptr;
		switch (sz) {
		case 2: integer_type = t_u16; break;
		case 4: integer_type = t_u32; break;
		case 8: integer_type = t_u64; break;
		}
		GB_ASSERT(integer_type != nullptr);
		value = cg_emit_transmute(p, value, integer_type);
	}

	GB_ASSERT(value.kind == cgValue_Value);

	// TODO(bill): bswap
	// value.node = tb_inst_bswap(p->func, value.node);
	return cg_emit_transmute(p, value, end_type);
}

gb_internal cgValue cg_emit_comp_records(cgProcedure *p, TokenKind op_kind, cgValue left, cgValue right, Type *type) {
	GB_ASSERT((is_type_struct(type) || is_type_union(type)) && is_type_comparable(type));
	cgValue left_ptr  = cg_address_from_load_or_generate_local(p, left);
	cgValue right_ptr = cg_address_from_load_or_generate_local(p, right);
	cgValue res = {};
	if (type_size_of(type) == 0) {
		switch (op_kind) {
		case Token_CmpEq:
			return cg_const_bool(p, t_bool, true);
		case Token_NotEq:
			return cg_const_bool(p, t_bool, false);
		}
		GB_PANIC("invalid operator");
	}
	TEMPORARY_ALLOCATOR_GUARD();
	if (is_type_simple_compare(type)) {
		// TODO(bill): Test to see if this is actually faster!!!!
		auto args = slice_make<cgValue>(temporary_allocator(), 3);
		args[0] = cg_emit_conv(p, left_ptr, t_rawptr);
		args[1] = cg_emit_conv(p, right_ptr, t_rawptr);
		args[2] = cg_const_int(p, t_int, type_size_of(type));
		res = cg_emit_runtime_call(p, "memory_equal", args);
	} else {
		cgProcedure *equal_proc = cg_equal_proc_for_type(p->module, type);
		cgValue value = cg_value(tb_inst_get_symbol_address(p->func, equal_proc->symbol), equal_proc->type);
		auto args = slice_make<cgValue>(temporary_allocator(), 2);
		args[0] = cg_emit_conv(p, left_ptr, t_rawptr);
		args[1] = cg_emit_conv(p, right_ptr, t_rawptr);
		res = cg_emit_call(p, value, args);
	}
	if (op_kind == Token_NotEq) {
		res = cg_emit_unary_arith(p, Token_Not, res, res.type);
	}
	return res;
}

gb_internal cgValue cg_emit_comp(cgProcedure *p, TokenKind op_kind, cgValue left, cgValue right) {
	GB_ASSERT(gb_is_between(op_kind, Token__ComparisonBegin+1, Token__ComparisonEnd-1));

	Type *a = core_type(left.type);
	Type *b = core_type(right.type);

	cgValue nil_check = {};
	if (is_type_array_like(left.type) || is_type_array_like(right.type)) {
		// don't do `nil` check if it is array-like
	} else if (is_type_untyped_nil(left.type)) {
		nil_check = cg_emit_comp_against_nil(p, op_kind, right);
	} else if (is_type_untyped_nil(right.type)) {
		nil_check = cg_emit_comp_against_nil(p, op_kind, left);
	}
	if (nil_check.node != nullptr) {
		return nil_check;
	}

	if (are_types_identical(a, b)) {
		// NOTE(bill): No need for a conversion
	} /*else if (cg_is_const(left) || cg_is_const_nil(left)) {
		left = cg_emit_conv(p, left, right.type);
	} else if (cg_is_const(right) || cg_is_const_nil(right)) {
		right = cg_emit_conv(p, right, left.type);
	}*/ else {
		Type *lt = left.type;
		Type *rt = right.type;

		lt = left.type;
		rt = right.type;
		i64 ls = type_size_of(lt);
		i64 rs = type_size_of(rt);

		// NOTE(bill): Quick heuristic, larger types are usually the target type
		if (ls < rs) {
			left = cg_emit_conv(p, left, rt);
		} else if (ls > rs) {
			right = cg_emit_conv(p, right, lt);
		} else {
			if (is_type_union(rt)) {
				left = cg_emit_conv(p, left, rt);
			} else {
				right = cg_emit_conv(p, right, lt);
			}
		}
	}

	a = core_type(left.type);
	b = core_type(right.type);
	left  = cg_flatten_value(p, left);
	right = cg_flatten_value(p, right);


	if (is_type_matrix(a) && (op_kind == Token_CmpEq || op_kind == Token_NotEq)) {
		GB_PANIC("TODO(bill): cg_emit_comp matrix");
		// Type *tl = base_type(a);
		// lbValue lhs = lb_address_from_load_or_generate_local(p, left);
		// lbValue rhs = lb_address_from_load_or_generate_local(p, right);


		// // TODO(bill): Test to see if this is actually faster!!!!
		// auto args = array_make<lbValue>(permanent_allocator(), 3);
		// args[0] = lb_emit_conv(p, lhs, t_rawptr);
		// args[1] = lb_emit_conv(p, rhs, t_rawptr);
		// args[2] = lb_const_int(p->module, t_int, type_size_of(tl));
		// lbValue val = lb_emit_runtime_call(p, "memory_compare", args);
		// lbValue res = lb_emit_comp(p, op_kind, val, lb_const_nil(p->module, val.type));
		// return lb_emit_conv(p, res, t_bool);
	}
	if (is_type_array_like(a)) {
		GB_PANIC("TODO(bill): cg_emit_comp is_type_array_like");
		// Type *tl = base_type(a);
		// lbValue lhs = lb_address_from_load_or_generate_local(p, left);
		// lbValue rhs = lb_address_from_load_or_generate_local(p, right);


		// TokenKind cmp_op = Token_And;
		// lbValue res = lb_const_bool(p->module, t_bool, true);
		// if (op_kind == Token_NotEq) {
		// 	res = lb_const_bool(p->module, t_bool, false);
		// 	cmp_op = Token_Or;
		// } else if (op_kind == Token_CmpEq) {
		// 	res = lb_const_bool(p->module, t_bool, true);
		// 	cmp_op = Token_And;
		// }

		// bool inline_array_arith = lb_can_try_to_inline_array_arith(tl);
		// i32 count = 0;
		// switch (tl->kind) {
		// case Type_Array:           count = cast(i32)tl->Array.count;           break;
		// case Type_EnumeratedArray: count = cast(i32)tl->EnumeratedArray.count; break;
		// }

		// if (inline_array_arith) {
		// 	// inline
		// 	lbAddr val = lb_add_local_generated(p, t_bool, false);
		// 	lb_addr_store(p, val, res);
		// 	for (i32 i = 0; i < count; i++) {
		// 		lbValue x = lb_emit_load(p, lb_emit_array_epi(p, lhs, i));
		// 		lbValue y = lb_emit_load(p, lb_emit_array_epi(p, rhs, i));
		// 		lbValue cmp = lb_emit_comp(p, op_kind, x, y);
		// 		lbValue new_res = lb_emit_arith(p, cmp_op, lb_addr_load(p, val), cmp, t_bool);
		// 		lb_addr_store(p, val, lb_emit_conv(p, new_res, t_bool));
		// 	}

		// 	return lb_addr_load(p, val);
		// } else {
		// 	if (is_type_simple_compare(tl) && (op_kind == Token_CmpEq || op_kind == Token_NotEq)) {
		// 		// TODO(bill): Test to see if this is actually faster!!!!
		// 		auto args = array_make<lbValue>(permanent_allocator(), 3);
		// 		args[0] = lb_emit_conv(p, lhs, t_rawptr);
		// 		args[1] = lb_emit_conv(p, rhs, t_rawptr);
		// 		args[2] = lb_const_int(p->module, t_int, type_size_of(tl));
		// 		lbValue val = lb_emit_runtime_call(p, "memory_compare", args);
		// 		lbValue res = lb_emit_comp(p, op_kind, val, lb_const_nil(p->module, val.type));
		// 		return lb_emit_conv(p, res, t_bool);
		// 	} else {
		// 		lbAddr val = lb_add_local_generated(p, t_bool, false);
		// 		lb_addr_store(p, val, res);
		// 		auto loop_data = lb_loop_start(p, count, t_i32);
		// 		{
		// 			lbValue i = loop_data.idx;
		// 			lbValue x = lb_emit_load(p, lb_emit_array_ep(p, lhs, i));
		// 			lbValue y = lb_emit_load(p, lb_emit_array_ep(p, rhs, i));
		// 			lbValue cmp = lb_emit_comp(p, op_kind, x, y);
		// 			lbValue new_res = lb_emit_arith(p, cmp_op, lb_addr_load(p, val), cmp, t_bool);
		// 			lb_addr_store(p, val, lb_emit_conv(p, new_res, t_bool));
		// 		}
		// 		lb_loop_end(p, loop_data);

		// 		return lb_addr_load(p, val);
		// 	}
		// }
	}

	if ((is_type_struct(a) || is_type_union(a)) && is_type_comparable(a)) {
		return cg_emit_comp_records(p, op_kind, left, right, a);
	}

	if ((is_type_struct(b) || is_type_union(b)) && is_type_comparable(b)) {
		return cg_emit_comp_records(p, op_kind, left, right, b);
	}

	if (is_type_string(a)) {
		if (is_type_cstring(a)) {
			left  = cg_emit_conv(p, left, t_string);
			right = cg_emit_conv(p, right, t_string);
		}

		char const *runtime_procedure = nullptr;
		switch (op_kind) {
		case Token_CmpEq: runtime_procedure = "string_eq"; break;
		case Token_NotEq: runtime_procedure = "string_ne"; break;
		case Token_Lt:    runtime_procedure = "string_lt"; break;
		case Token_Gt:    runtime_procedure = "string_gt"; break;
		case Token_LtEq:  runtime_procedure = "string_le"; break;
		case Token_GtEq:  runtime_procedure = "string_gt"; break;
		}
		GB_ASSERT(runtime_procedure != nullptr);

		auto args = slice_make<cgValue>(permanent_allocator(), 2);
		args[0] = left;
		args[1] = right;
		return cg_emit_runtime_call(p, runtime_procedure, args);
	}

	if (is_type_complex(a)) {
		char const *runtime_procedure = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 32:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "complex32_eq"; break;
			case Token_NotEq: runtime_procedure = "complex32_ne"; break;
			}
			break;
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "complex64_eq"; break;
			case Token_NotEq: runtime_procedure = "complex64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "complex128_eq"; break;
			case Token_NotEq: runtime_procedure = "complex128_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_procedure != nullptr);

		GB_PANIC("TODO(bill): cg_emit_runtime_call");
		// auto args = array_make<lbValue>(permanent_allocator(), 2);
		// args[0] = left;
		// args[1] = right;
		// return lb_emit_runtime_call(p, runtime_procedure, args);
	}

	if (is_type_quaternion(a)) {
		char const *runtime_procedure = "";
		i64 sz = 8*type_size_of(a);
		switch (sz) {
		case 64:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "quaternion64_eq"; break;
			case Token_NotEq: runtime_procedure = "quaternion64_ne"; break;
			}
			break;
		case 128:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "quaternion128_eq"; break;
			case Token_NotEq: runtime_procedure = "quaternion128_ne"; break;
			}
			break;
		case 256:
			switch (op_kind) {
			case Token_CmpEq: runtime_procedure = "quaternion256_eq"; break;
			case Token_NotEq: runtime_procedure = "quaternion256_ne"; break;
			}
			break;
		}
		GB_ASSERT(runtime_procedure != nullptr);

		GB_PANIC("TODO(bill): cg_emit_runtime_call");
		// auto args = array_make<lbValue>(permanent_allocator(), 2);
		// args[0] = left;
		// args[1] = right;
		// return lb_emit_runtime_call(p, runtime_procedure, args);
	}

	if (is_type_bit_set(a)) {
		switch (op_kind) {
		case Token_Lt:
		case Token_LtEq:
		case Token_Gt:
		case Token_GtEq:
			{
				Type *it = bit_set_to_int(a);
				cgValue lhs = cg_emit_transmute(p, left, it);
				cgValue rhs = cg_emit_transmute(p, right, it);
				cgValue res = cg_emit_arith(p, Token_And, lhs, rhs, it);
				GB_ASSERT(lhs.kind == cgValue_Value);
				GB_ASSERT(rhs.kind == cgValue_Value);
				GB_ASSERT(res.kind == cgValue_Value);

				if (op_kind == Token_Lt || op_kind == Token_LtEq) {
					// (lhs & rhs) == lhs
					res = cg_value(tb_inst_cmp_eq(p->func, res.node, lhs.node), t_bool);
				} else if (op_kind == Token_Gt || op_kind == Token_GtEq) {
					// (lhs & rhs) == rhs
					res = cg_value(tb_inst_cmp_eq(p->func, res.node, rhs.node), t_bool);
				}

				// NOTE(bill): Strict subsets
				if (op_kind == Token_Lt || op_kind == Token_Gt) {
					// res &~ (lhs == rhs)
					cgValue eq = cg_value(tb_inst_cmp_eq(p->func, lhs.node, rhs.node), t_bool);
					res = cg_emit_arith(p, Token_AndNot, res, eq, t_bool);
				}
				return res;
			}

		case Token_CmpEq:
			GB_ASSERT(left.kind  == cgValue_Value);
			GB_ASSERT(right.kind == cgValue_Value);
			return cg_value(tb_inst_cmp_eq(p->func, left.node, right.node), t_bool);
		case Token_NotEq:
			GB_ASSERT(left.kind  == cgValue_Value);
			GB_ASSERT(right.kind == cgValue_Value);
			return cg_value(tb_inst_cmp_ne(p->func, left.node, right.node), t_bool);
		}
	}

	if (op_kind != Token_CmpEq && op_kind != Token_NotEq) {
		Type *t = left.type;
		if (is_type_integer(t) && is_type_different_to_arch_endianness(t)) {
			Type *platform_type = integer_endian_type_to_platform_type(t);
			cgValue x = cg_emit_byte_swap(p, left, platform_type);
			cgValue y = cg_emit_byte_swap(p, right, platform_type);
			left = x;
			right = y;
		} else if (is_type_float(t) && is_type_different_to_arch_endianness(t)) {
			Type *platform_type = integer_endian_type_to_platform_type(t);
			cgValue x = cg_emit_conv(p, left, platform_type);
			cgValue y = cg_emit_conv(p, right, platform_type);
			left = x;
			right = y;
		}
	}

	a = core_type(left.type);
	b = core_type(right.type);


	if (is_type_integer(a) ||
	    is_type_boolean(a) ||
	    is_type_pointer(a) ||
	    is_type_multi_pointer(a) ||
	    is_type_proc(a) ||
	    is_type_enum(a) ||
	    is_type_typeid(a)) {
	    	TB_Node *lhs = left.node;
		TB_Node *rhs = right.node;
		TB_Node *res = nullptr;

		bool is_signed = is_type_integer(left.type) && !is_type_unsigned(left.type);
		switch (op_kind) {
		case Token_CmpEq: res = tb_inst_cmp_eq(p->func, lhs, rhs); break;
		case Token_NotEq: res = tb_inst_cmp_ne(p->func, lhs, rhs); break;
		case Token_Gt:    res = tb_inst_cmp_igt(p->func, lhs, rhs, is_signed); break;
		case Token_GtEq:  res = tb_inst_cmp_ige(p->func, lhs, rhs, is_signed); break;
		case Token_Lt:    res = tb_inst_cmp_ilt(p->func, lhs, rhs, is_signed); break;
		case Token_LtEq:  res = tb_inst_cmp_ile(p->func, lhs, rhs, is_signed); break;
		}

		GB_ASSERT(res != nullptr);
		return cg_value(res, t_bool);
	} else if (is_type_float(a)) {
	    	TB_Node *lhs = left.node;
		TB_Node *rhs = right.node;
		TB_Node *res = nullptr;
		switch (op_kind) {
		case Token_CmpEq: res = tb_inst_cmp_eq(p->func, lhs, rhs);  break;
		case Token_NotEq: res = tb_inst_cmp_ne(p->func, lhs, rhs);  break;
		case Token_Gt:    res = tb_inst_cmp_fgt(p->func, lhs, rhs); break;
		case Token_GtEq:  res = tb_inst_cmp_fge(p->func, lhs, rhs); break;
		case Token_Lt:    res = tb_inst_cmp_flt(p->func, lhs, rhs); break;
		case Token_LtEq:  res = tb_inst_cmp_fle(p->func, lhs, rhs); break;
		}
		GB_ASSERT(res != nullptr);
		return cg_value(res, t_bool);
	} else if (is_type_simd_vector(a)) {
		GB_PANIC("TODO(bill): #simd vector");
		// LLVMValueRef mask = nullptr;
		// Type *elem = base_array_type(a);
		// if (is_type_float(elem)) {
		// 	LLVMRealPredicate pred = {};
		// 	switch (op_kind) {
		// 	case Token_CmpEq: pred = LLVMRealOEQ; break;
		// 	case Token_NotEq: pred = LLVMRealONE; break;
		// 	}
		// 	mask = LLVMBuildFCmp(p->builder, pred, left.value, right.value, "");
		// } else {
		// 	LLVMIntPredicate pred = {};
		// 	switch (op_kind) {
		// 	case Token_CmpEq: pred = LLVMIntEQ; break;
		// 	case Token_NotEq: pred = LLVMIntNE; break;
		// 	}
		// 	mask = LLVMBuildICmp(p->builder, pred, left.value, right.value, "");
		// }
		// GB_ASSERT_MSG(mask != nullptr, "Unhandled comparison kind %s (%s) %.*s %s (%s)", type_to_string(left.type), type_to_string(base_type(left.type)), LIT(token_strings[op_kind]), type_to_string(right.type), type_to_string(base_type(right.type)));

		// /* NOTE(bill, 2022-05-28):
		// 	Thanks to Per Vognsen, sign extending <N x i1> to
		// 	a vector of the same width as the input vector, bit casting to an integer,
		// 	and then comparing against zero is the better option
		// 	See: https://lists.llvm.org/pipermail/llvm-dev/2012-September/053046.html

		// 	// Example assuming 128-bit vector

		// 	%1 = <4 x float> ...
		// 	%2 = <4 x float> ...
		// 	%3 = fcmp oeq <4 x float> %1, %2
		// 	%4 = sext <4 x i1> %3 to <4 x i32>
		// 	%5 = bitcast <4 x i32> %4 to i128
		// 	%6 = icmp ne i128 %5, 0
		// 	br i1 %6, label %true1, label %false2

		// 	This will result in 1 cmpps + 1 ptest + 1 br
		// 	(even without SSE4.1, contrary to what the mail list states, because of pmovmskb)

		// */

		// unsigned count = cast(unsigned)get_array_type_count(a);
		// unsigned elem_sz = cast(unsigned)(type_size_of(elem)*8);
		// LLVMTypeRef mask_type = LLVMVectorType(LLVMIntTypeInContext(p->module->ctx, elem_sz), count);
		// mask = LLVMBuildSExtOrBitCast(p->builder, mask, mask_type, "");

		// LLVMTypeRef mask_int_type = LLVMIntTypeInContext(p->module->ctx, cast(unsigned)(8*type_size_of(a)));
		// LLVMValueRef mask_int = LLVMBuildBitCast(p->builder, mask, mask_int_type, "");
		// res.value = LLVMBuildICmp(p->builder, LLVMIntNE, mask_int, LLVMConstNull(LLVMTypeOf(mask_int)), "");
		// return res;
	}

	GB_PANIC("Unhandled comparison kind %s (%s) %.*s %s (%s)", type_to_string(left.type), type_to_string(base_type(left.type)), LIT(token_strings[op_kind]), type_to_string(right.type), type_to_string(base_type(right.type)));
	return {};
}

gb_internal cgValue cg_emit_comp_against_nil(cgProcedure *p, TokenKind op_kind, cgValue x) {
	GB_ASSERT(op_kind == Token_CmpEq || op_kind == Token_NotEq);
	x = cg_flatten_value(p, x);
	cgValue res = {};
	Type *t = x.type;

	TB_DataType dt = cg_data_type(t);

	Type *bt = base_type(t);
	TypeKind type_kind = bt->kind;

	switch (type_kind) {
	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_rawptr:
		case Basic_cstring:
			GB_ASSERT(x.kind == cgValue_Value);
			if (op_kind == Token_CmpEq) {
				return cg_value(tb_inst_cmp_eq(p->func, x.node, tb_inst_uint(p->func, dt, 0)), t_bool);
			} else if (op_kind == Token_NotEq) {
				return cg_value(tb_inst_cmp_ne(p->func, x.node, tb_inst_uint(p->func, dt, 0)), t_bool);
			}
			break;
		case Basic_any:
			{
				GB_ASSERT(x.kind == cgValue_Addr);
				// // TODO(bill): is this correct behaviour for nil comparison for any?
				cgValue data = cg_emit_struct_ev(p, x, 0);
				cgValue id   = cg_emit_struct_ev(p, x, 1);

				if (op_kind == Token_CmpEq) {
					TB_Node *a = tb_inst_cmp_eq(p->func, data.node, tb_inst_uint(p->func, data.node->dt, 0));
					TB_Node *b = tb_inst_cmp_eq(p->func, id.node,   tb_inst_uint(p->func, id.node->dt,   0));
					TB_Node *c = tb_inst_or(p->func, a, b);
					return cg_value(c, t_bool);
				} else if (op_kind == Token_NotEq) {
					TB_Node *a = tb_inst_cmp_ne(p->func, data.node, tb_inst_uint(p->func, data.node->dt, 0));
					TB_Node *b = tb_inst_cmp_ne(p->func, id.node,   tb_inst_uint(p->func, id.node->dt,   0));
					TB_Node *c = tb_inst_and(p->func, a, b);
					return cg_value(c, t_bool);
				}
			}
			break;
		case Basic_typeid:
			cgValue invalid_typeid = cg_const_value(p, t_typeid, exact_value_i64(0));
			return cg_emit_comp(p, op_kind, x, invalid_typeid);
		}
		break;

	case Type_Enum:
	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc:
	case Type_BitSet:
		GB_ASSERT(x.kind == cgValue_Value);
		if (op_kind == Token_CmpEq) {
			return cg_value(tb_inst_cmp_eq(p->func, x.node, tb_inst_uint(p->func, dt, 0)), t_bool);
		} else if (op_kind == Token_NotEq) {
			return cg_value(tb_inst_cmp_ne(p->func, x.node, tb_inst_uint(p->func, dt, 0)), t_bool);
		}
		break;

	case Type_Slice:
	case Type_DynamicArray:
	case Type_Map:
		{
			// NOTE(bill): all of their data "pointer-like" fields are at the 0-index
			cgValue data = cg_emit_struct_ev(p, x, 0);
			if (op_kind == Token_CmpEq) {
				TB_Node *a = tb_inst_cmp_eq(p->func, data.node, tb_inst_uint(p->func, data.node->dt, 0));
				return cg_value(a, t_bool);
			} else if (op_kind == Token_NotEq) {
				TB_Node *a = tb_inst_cmp_ne(p->func, data.node, tb_inst_uint(p->func, data.node->dt, 0));
				return cg_value(a, t_bool);
			}
		}
		break;

	case Type_Union:
		{
			if (type_size_of(t) == 0) {
				return cg_const_bool(p, t_bool, op_kind == Token_CmpEq);
			} else if (is_type_union_maybe_pointer(t)) {
				cgValue tag = cg_emit_transmute(p, x, t_rawptr);
				return cg_emit_comp_against_nil(p, op_kind, tag);
			} else {
				GB_ASSERT("TODO(bill): cg_emit_union_tag_value");
				// cgValue tag = cg_emit_union_tag_value(p, x);
				// return cg_emit_comp(p, op_kind, tag, cg_zero(p->module, tag.type));
			}
		}
		break;
	case Type_Struct:
		GB_PANIC("TODO(bill): cg_emit_struct_ev");
		// if (is_type_soa_struct(t)) {
		// 	Type *bt = base_type(t);
		// 	if (bt->Struct.soa_kind == StructSoa_Slice) {
		// 		LLVMValueRef the_value = {};
		// 		if (bt->Struct.fields.count == 0) {
		// 			cgValue len = cg_soa_struct_len(p, x);
		// 			the_value = len.value;
		// 		} else {
		// 			cgValue first_field = cg_emit_struct_ev(p, x, 0);
		// 			the_value = first_field.value;
		// 		}
		// 		if (op_kind == Token_CmpEq) {
		// 			res.value = LLVMBuildIsNull(p->builder, the_value, "");
		// 			return res;
		// 		} else if (op_kind == Token_NotEq) {
		// 			res.value = LLVMBuildIsNotNull(p->builder, the_value, "");
		// 			return res;
		// 		}
		// 	} else if (bt->Struct.soa_kind == StructSoa_Dynamic) {
		// 		LLVMValueRef the_value = {};
		// 		if (bt->Struct.fields.count == 0) {
		// 			cgValue cap = cg_soa_struct_cap(p, x);
		// 			the_value = cap.value;
		// 		} else {
		// 			cgValue first_field = cg_emit_struct_ev(p, x, 0);
		// 			the_value = first_field.value;
		// 		}
		// 		if (op_kind == Token_CmpEq) {
		// 			res.value = LLVMBuildIsNull(p->builder, the_value, "");
		// 			return res;
		// 		} else if (op_kind == Token_NotEq) {
		// 			res.value = LLVMBuildIsNotNull(p->builder, the_value, "");
		// 			return res;
		// 		}
		// 	}
		// } else if (is_type_struct(t) && type_has_nil(t)) {
		// 	auto args = array_make<cgValue>(permanent_allocator(), 2);
		// 	cgValue lhs = cg_address_from_load_or_generate_local(p, x);
		// 	args[0] = cg_emit_conv(p, lhs, t_rawptr);
		// 	args[1] = cg_const_int(p->module, t_int, type_size_of(t));
		// 	cgValue val = cg_emit_runtime_call(p, "memory_compare_zero", args);
		// 	cgValue res = cg_emit_comp(p, op_kind, val, cg_const_int(p->module, t_int, 0));
		// 	return res;
		// }
		break;
	}
	GB_PANIC("Unknown handled type: %s -> %s", type_to_string(t), type_to_string(bt));
	return {};
}

gb_internal cgValue cg_emit_conv(cgProcedure *p, cgValue value, Type *t) {
	t = reduce_tuple_to_single_type(t);

	value = cg_flatten_value(p, value);

	Type *src_type = value.type;
	if (are_types_identical(t, src_type)) {
		return value;
	}

	if (is_type_untyped_uninit(src_type)) {
		// return cg_const_undef(m, t);
		return cg_const_nil(p, t);
	}
	if (is_type_untyped_nil(src_type)) {
		return cg_const_nil(p, t);
	}

	Type *src = core_type(src_type);
	Type *dst = core_type(t);
	GB_ASSERT(src != nullptr);
	GB_ASSERT(dst != nullptr);

	if (are_types_identical(src, dst)) {
		return cg_emit_transmute(p, value, t);
	}

	TB_DataType st = cg_data_type(src);
	if (value.kind == cgValue_Value && !TB_IS_VOID_TYPE(value.node->dt)) {
		st = value.node->dt;
	}
	TB_DataType dt = cg_data_type(t);

	if (is_type_integer(src) && is_type_integer(dst)) {
		GB_ASSERT(src->kind == Type_Basic &&
		          dst->kind == Type_Basic);
		GB_ASSERT(value.kind == cgValue_Value);

		i64 sz = type_size_of(default_type(src));
		i64 dz = type_size_of(default_type(dst));

		if (sz == dz) {
			if (dz > 1 && !types_have_same_internal_endian(src, dst)) {
				return cg_emit_byte_swap(p, value, t);
			}
			value.type = t;
			return value;
		}

		if (sz > 1 && is_type_different_to_arch_endianness(src)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			value = cg_emit_byte_swap(p, value, platform_src_type);
		}

		TB_Node* (*op)(TB_Function* f, TB_Node* src, TB_DataType dt) = tb_inst_trunc;

		if (dz < sz) {
			op = tb_inst_trunc;
		} else if (dz == sz) {
			op = tb_inst_bitcast;
		} else if (dz > sz) {
			op = is_type_unsigned(src) ? tb_inst_zxt : tb_inst_sxt; // zero extent
		}

		if (dz > 1 && is_type_different_to_arch_endianness(dst)) {
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);

			cgValue res = cg_value(op(p->func, value.node, cg_data_type(platform_dst_type)), platform_dst_type);
			return cg_emit_byte_swap(p, res, t);
		} else {
			return cg_value(op(p->func, value.node, dt), t);
		}
	}

	// boolean -> boolean/integer
	if (is_type_boolean(src) && (is_type_boolean(dst) || is_type_integer(dst))) {
		TB_Node *v = tb_inst_cmp_ne(p->func, value.node, tb_inst_uint(p->func, st, 0));
		return cg_value(tb_inst_zxt(p->func, v, dt), t);
	}

	// integer -> boolean
	if (is_type_integer(src) && is_type_boolean(dst)) {
		TB_Node *v = tb_inst_cmp_ne(p->func, value.node, tb_inst_uint(p->func, st, 0));
		return cg_value(tb_inst_zxt(p->func, v, dt), t);
	}

	if (is_type_cstring(src) && is_type_u8_ptr(dst)) {
		return cg_emit_transmute(p, value, dst);
	}
	if (is_type_u8_ptr(src) && is_type_cstring(dst)) {
		return cg_emit_transmute(p, value, dst);
	}
	if (is_type_cstring(src) && is_type_u8_multi_ptr(dst)) {
		return cg_emit_transmute(p, value, dst);
	}
	if (is_type_u8_multi_ptr(src) && is_type_cstring(dst)) {
		return cg_emit_transmute(p, value, dst);
	}
	if (is_type_cstring(src) && is_type_rawptr(dst)) {
		return cg_emit_transmute(p, value, dst);
	}
	if (is_type_rawptr(src) && is_type_cstring(dst)) {
		return cg_emit_transmute(p, value, dst);
	}


	if (are_types_identical(src, t_cstring) && are_types_identical(dst, t_string)) {
		TEMPORARY_ALLOCATOR_GUARD();
		cgValue c = cg_emit_conv(p, value, t_cstring);
		auto args = slice_make<cgValue>(temporary_allocator(), 1);
		args[0] = c;
		cgValue s = cg_emit_runtime_call(p, "cstring_to_string", args);
		return cg_emit_conv(p, s, dst);
	}

	// float -> float
	if (is_type_float(src) && is_type_float(dst)) {
		i64 sz = type_size_of(src);
		i64 dz = type_size_of(dst);

		if (sz == 2 || dz == 2) {
			GB_PANIC("TODO(bill): f16 conversions");
		}


		if (dz == sz) {
			if (types_have_same_internal_endian(src, dst)) {
				return cg_value(value.node, t);
			} else {
				return cg_emit_byte_swap(p, value, t);
			}
		}

		if (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			cgValue res = {};
			res = cg_emit_conv(p, value, platform_src_type);
			res = cg_emit_conv(p, res, platform_dst_type);
			if (is_type_different_to_arch_endianness(dst)) {
				res = cg_emit_byte_swap(p, res, t);
			}
			return cg_emit_conv(p, res, t);
		}


		if (dz >= sz) {
			return cg_value(tb_inst_fpxt(p->func, value.node, dt), t);
		}
		return cg_value(tb_inst_trunc(p->func, value.node, dt), t);
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		GB_PANIC("TODO(bill): complex -> complex");
	}

	if (is_type_quaternion(src) && is_type_quaternion(dst)) {
		// @QuaternionLayout
		GB_PANIC("TODO(bill): quaternion -> quaternion");
	}
	if (is_type_integer(src) && is_type_complex(dst)) {
		GB_PANIC("TODO(bill): int -> complex");
	}
	if (is_type_float(src) && is_type_complex(dst)) {
		GB_PANIC("TODO(bill): float -> complex");
	}
	if (is_type_integer(src) && is_type_quaternion(dst)) {
		GB_PANIC("TODO(bill): int -> quaternion");
	}
	if (is_type_float(src) && is_type_quaternion(dst)) {
		GB_PANIC("TODO(bill): float -> quaternion");
	}
	if (is_type_complex(src) && is_type_quaternion(dst)) {
		GB_PANIC("TODO(bill): complex -> quaternion");
	}


	// float <-> integer
	if (is_type_float(src) && is_type_integer(dst)) {
		if (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			cgValue res = {};
			res = cg_emit_conv(p, value, platform_src_type);
			res = cg_emit_conv(p, res, platform_dst_type);
			return cg_emit_conv(p, res, t);
		}

		// if (is_type_integer_128bit(dst)) {
		// 	TEMPORARY_ALLOCATOR_GUARD();

		// 	auto args = array_make<lbValue>(temporary_allocator(), 1);
		// 	args[0] = value;
		// 	char const *call = "fixunsdfdi";
		// 	if (is_type_unsigned(dst)) {
		// 		call = "fixunsdfti";
		// 	}
		// 	lbValue res_i128 = lb_emit_runtime_call(p, call, args);
		// 	return lb_emit_conv(p, res_i128, t);
		// }

		bool is_signed = !is_type_unsigned(dst);
		return cg_value(tb_inst_float2int(p->func, value.node, dt, is_signed), t);
	}
	if (is_type_integer(src) && is_type_float(dst)) {
		if (is_type_different_to_arch_endianness(src) || is_type_different_to_arch_endianness(dst)) {
			Type *platform_src_type = integer_endian_type_to_platform_type(src);
			Type *platform_dst_type = integer_endian_type_to_platform_type(dst);
			cgValue res = {};
			res = cg_emit_conv(p, value, platform_src_type);
			res = cg_emit_conv(p, res, platform_dst_type);
			if (is_type_different_to_arch_endianness(dst)) {
				res = cg_emit_byte_swap(p, res, t);
			}
			return cg_emit_conv(p, res, t);
		}

		// if (is_type_integer_128bit(src)) {
		// 	TEMPORARY_ALLOCATOR_GUARD();

		// 	auto args = array_make<lbValue>(temporary_allocator(), 1);
		// 	args[0] = value;
		// 	char const *call = "floattidf";
		// 	if (is_type_unsigned(src)) {
		// 		call = "floattidf_unsigned";
		// 	}
		// 	lbValue res_f64 = lb_emit_runtime_call(p, call, args);
		// 	return lb_emit_conv(p, res_f64, t);
		// }

		bool is_signed = !is_type_unsigned(dst);
		return cg_value(tb_inst_int2float(p->func, value.node, dt, is_signed), t);
	}

	if (is_type_simd_vector(dst)) {
		GB_PANIC("TODO(bill): ? -> #simd vector");
	}


	// Pointer <-> uintptr
	if (is_type_pointer(src) && is_type_uintptr(dst)) {
		return cg_value(tb_inst_ptr2int(p->func, value.node, dt), t);
	}
	if (is_type_uintptr(src) && is_type_pointer(dst)) {
		return cg_value(tb_inst_int2ptr(p->func, value.node), t);
	}
	if (is_type_multi_pointer(src) && is_type_uintptr(dst)) {
		return cg_value(tb_inst_ptr2int(p->func, value.node, dt), t);
	}
	if (is_type_uintptr(src) && is_type_multi_pointer(dst)) {
		return cg_value(tb_inst_int2ptr(p->func, value.node), t);
	}

	if (is_type_union(dst)) {
		GB_PANIC("TODO(bill): ? -> union");
	}

	// NOTE(bill): This has to be done before 'Pointer <-> Pointer' as it's
	// subtype polymorphism casting
	if (check_is_assignable_to_using_subtype(src_type, t)) {
		GB_PANIC("TODO(bill): ? -> subtyping");
	}

	// Pointer <-> Pointer
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		return cg_value(value.node, t);
	}
	if (is_type_multi_pointer(src) && is_type_pointer(dst)) {
		return cg_value(value.node, t);
	}
	if (is_type_pointer(src) && is_type_multi_pointer(dst)) {
		return cg_value(value.node, t);
	}
	if (is_type_multi_pointer(src) && is_type_multi_pointer(dst)) {
		return cg_value(value.node, t);
	}

	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return cg_value(value.node, t);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		return cg_value(value.node, t);
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		return cg_value(value.node, t);
	}

	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		return cg_emit_transmute(p, value, t);
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		return cg_emit_transmute(p, value, t);
	}

	if (is_type_matrix(dst) && !is_type_matrix(src)) {
		GB_PANIC("TODO(bill): !matrix -> matrix");
	}

	if (is_type_matrix(dst) && is_type_matrix(src)) {
		GB_PANIC("TODO(bill): matrix -> matrix");
	}

	if (is_type_any(dst)) {
		if (is_type_untyped_nil(src) ||
		    is_type_untyped_uninit(src)) {
			return cg_const_nil(p, t);
		}

		cgAddr result = cg_add_local(p, t, nullptr, false);

		Type *st = default_type(src_type);

		cgValue data = cg_address_from_load_or_generate_local(p, value);
		GB_ASSERT(is_type_pointer(data.type));
		GB_ASSERT(is_type_typed(st));

		data = cg_emit_conv(p, data, t_rawptr);
		if (p->name == "main@main") {
			GB_PANIC("HERE %s %llu", type_to_string(st), cg_typeid_as_u64(p->module, value.type));
		}

		cgValue id = cg_typeid(p, st);
		cgValue data_ptr = cg_emit_struct_ep(p, result.addr, 0);
		cgValue id_ptr   = cg_emit_struct_ep(p, result.addr, 1);

		cg_emit_store(p, data_ptr, data);
		cg_emit_store(p, id_ptr,   id);

		return cg_addr_load(p, result);
	}

	i64 src_sz = type_size_of(src);
	i64 dst_sz = type_size_of(dst);

	if (src_sz == dst_sz) {
		// bit_set <-> integer
		if (is_type_integer(src) && is_type_bit_set(dst)) {
			cgValue v = cg_emit_conv(p, value, bit_set_to_int(dst));
			return cg_emit_transmute(p, v, t);
		}
		if (is_type_bit_set(src) && is_type_integer(dst)) {
			cgValue bs = cg_emit_transmute(p, value, bit_set_to_int(src));
			return cg_emit_conv(p, bs, dst);
		}

		// typeid <-> integer
		if (is_type_integer(src) && is_type_typeid(dst)) {
			return cg_emit_transmute(p, value, dst);
		}
		if (is_type_typeid(src) && is_type_integer(dst)) {
			return cg_emit_transmute(p, value, dst);
		}
	}


	if (is_type_untyped(src)) {
		if (is_type_string(src) && is_type_string(dst)) {
			cgAddr result = cg_add_local(p, t, nullptr, false);
			cg_addr_store(p, result, value);
			return cg_addr_load(p, result);
		}
	}


	gb_printf_err("%.*s\n", LIT(p->name));
	gb_printf_err("cg_emit_conv: src -> dst\n");
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src_type), type_to_string(t));
	gb_printf_err("Not Identical %s != %s\n", type_to_string(src), type_to_string(dst));
	gb_printf_err("Not Identical %p != %p\n", src_type, t);
	gb_printf_err("Not Identical %p != %p\n", src, dst);


	GB_PANIC("Invalid type conversion: '%s' to '%s' for procedure '%.*s'",
	         type_to_string(src_type), type_to_string(t),
	         LIT(p->name));

	return {};
}

gb_internal cgValue cg_emit_arith(cgProcedure *p, TokenKind op, cgValue lhs, cgValue rhs, Type *type) {
	if (is_type_array_like(lhs.type) || is_type_array_like(rhs.type)) {
		GB_PANIC("TODO(bill): cg_emit_arith_array");
	} else if (is_type_matrix(lhs.type) || is_type_matrix(rhs.type)) {
		GB_PANIC("TODO(bill): cg_emit_arith_matrix");
	} else if (is_type_complex(type)) {
		GB_PANIC("TODO(bill): cg_emit_arith complex");
	} else if (is_type_quaternion(type)) {
		GB_PANIC("TODO(bill): cg_emit_arith quaternion");
	}

	lhs = cg_flatten_value(p, cg_emit_conv(p, lhs, type));
	rhs = cg_flatten_value(p, cg_emit_conv(p, rhs, type));
	GB_ASSERT(lhs.kind == cgValue_Value);
	GB_ASSERT(rhs.kind == cgValue_Value);

	if (is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		switch (op) {
		case Token_AndNot:
		case Token_And:
		case Token_Or:
		case Token_Xor:
			goto handle_op;
		}

		Type *platform_type = integer_endian_type_to_platform_type(type);
		cgValue x = cg_emit_byte_swap(p, lhs, integer_endian_type_to_platform_type(lhs.type));
		cgValue y = cg_emit_byte_swap(p, rhs, integer_endian_type_to_platform_type(rhs.type));

		cgValue res = cg_emit_arith(p, op, x, y, platform_type);

		return cg_emit_byte_swap(p, res, type);
	}

	if (is_type_float(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		cgValue x = cg_emit_conv(p, lhs, integer_endian_type_to_platform_type(lhs.type));
		cgValue y = cg_emit_conv(p, rhs, integer_endian_type_to_platform_type(rhs.type));

		cgValue res = cg_emit_arith(p, op, x, y, platform_type);

		return cg_emit_byte_swap(p, res, type);
	}

handle_op:;

	// NOTE(bill): Bit Set Aliases for + and -
	if (is_type_bit_set(type)) {
		switch (op) {
		case Token_Add: op = Token_Or;     break;
		case Token_Sub: op = Token_AndNot; break;
		}
	}

	TB_ArithmeticBehavior arith_behavior = cast(TB_ArithmeticBehavior)0;

	Type *integral_type = type;
	if (is_type_simd_vector(integral_type)) {
		GB_PANIC("TODO(bill): cg_emit_arith #simd vector");
		// integral_type = core_array_type(integral_type);
	}

	switch (op) {
	case Token_Add:
		if (is_type_float(integral_type)) {
			return cg_value(tb_inst_fadd(p->func, lhs.node, rhs.node), type);
		}
		return cg_value(tb_inst_add(p->func, lhs.node, rhs.node, arith_behavior), type);
	case Token_Sub:
		if (is_type_float(integral_type)) {
			return cg_value(tb_inst_fsub(p->func, lhs.node, rhs.node), type);
		}
		return cg_value(tb_inst_sub(p->func, lhs.node, rhs.node, arith_behavior), type);
	case Token_Mul:
		if (is_type_float(integral_type)) {
			return cg_value(tb_inst_fmul(p->func, lhs.node, rhs.node), type);
		}
		return cg_value(tb_inst_mul(p->func, lhs.node, rhs.node, arith_behavior), type);
	case Token_Quo:
		if (is_type_float(integral_type)) {
			return cg_value(tb_inst_fdiv(p->func, lhs.node, rhs.node), type);
		}
		return cg_value(tb_inst_div(p->func, lhs.node, rhs.node, !is_type_unsigned(integral_type)), type);
	case Token_Mod:
		if (is_type_float(integral_type)) {
			GB_PANIC("TODO(bill): float %% float");
		}
		return cg_value(tb_inst_mod(p->func, lhs.node, rhs.node, !is_type_unsigned(integral_type)), type);
	case Token_ModMod:
		if (is_type_unsigned(integral_type)) {
			return cg_value(tb_inst_mod(p->func, lhs.node, rhs.node, false), type);
		} else {
			TB_Node *a = tb_inst_mod(p->func, lhs.node, rhs.node, true);
			TB_Node *b = tb_inst_add(p->func, a, rhs.node, arith_behavior);
			TB_Node *c = tb_inst_mod(p->func, b, rhs.node, true);
			return cg_value(c, type);
		}

	case Token_And:
		return cg_value(tb_inst_and(p->func, lhs.node, rhs.node), type);
	case Token_Or:
		return cg_value(tb_inst_or(p->func, lhs.node, rhs.node), type);
	case Token_Xor:
		return cg_value(tb_inst_xor(p->func, lhs.node, rhs.node), type);
	case Token_Shl:
		{
			rhs = cg_emit_conv(p, rhs, lhs.type);
			TB_DataType dt = cg_data_type(lhs.type);
			TB_Node *lhsval = lhs.node;
			TB_Node *bits = rhs.node;

			TB_Node *bit_size = tb_inst_uint(p->func, dt, 8*type_size_of(lhs.type));
			TB_Node *zero = tb_inst_uint(p->func, dt, 0);

			TB_Node *width_test = tb_inst_cmp_ilt(p->func, bits, bit_size, false);

			TB_Node *res = tb_inst_shl(p->func, lhsval, bits, arith_behavior);
			res = tb_inst_select(p->func, width_test, res, zero);
			return cg_value(res, type);
		}
	case Token_Shr:
		{
			rhs = cg_emit_conv(p, rhs, lhs.type);
			TB_DataType dt = cg_data_type(lhs.type);
			TB_Node *lhsval = lhs.node;
			TB_Node *bits = rhs.node;

			TB_Node *bit_size = tb_inst_uint(p->func, dt, 8*type_size_of(lhs.type));
			TB_Node *zero = tb_inst_uint(p->func, dt, 0);

			TB_Node *width_test = tb_inst_cmp_ilt(p->func, bits, bit_size, false);

			TB_Node *res = nullptr;

			if (is_type_unsigned(integral_type)) {
				res = tb_inst_shr(p->func, lhsval, bits);
			} else {
				res = tb_inst_sar(p->func, lhsval, bits);
			}


			res = tb_inst_select(p->func, width_test, res, zero);
			return cg_value(res, type);
		}
	case Token_AndNot:
		return cg_value(tb_inst_and(p->func, lhs.node, tb_inst_not(p->func, rhs.node)), type);
	}

	GB_PANIC("unhandled operator of cg_emit_arith");

	return {};
}


gb_internal void cg_fill_slice(cgProcedure *p, cgAddr const &slice, cgValue data, cgValue len) {
	cgValue slice_ptr = cg_addr_get_ptr(p, slice);
	cgValue data_ptr = cg_emit_struct_ep(p, slice_ptr, 0);
	cgValue len_ptr  = cg_emit_struct_ep(p, slice_ptr, 1);

	data = cg_emit_conv(p, data, type_deref(data_ptr.type));
	len = cg_emit_conv(p, len, t_int);
	cg_emit_store(p, data_ptr, data);
	cg_emit_store(p, len_ptr,  len);
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
	case Type_Basic:
	case Type_Slice: {
		if (type->kind == Type_Basic) {
			GB_ASSERT(type->Basic.kind == Basic_string);
		}

		Type *slice_type = type;
		if (high.node == nullptr) {
			cgValue len = cg_builtin_len(p, base);
			high = len;
		}

		if (!no_indices) {
			// cg_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		}

		cgValue elem    = cg_emit_ptr_offset(p, cg_builtin_raw_data(p, base), low);
		cgValue new_len = cg_emit_arith(p, Token_Sub, high, low, t_int);

		cgAddr slice = cg_add_local(p, slice_type, nullptr, true);
		cg_fill_slice(p, slice, elem, new_len);
		return slice;
	}

	case Type_RelativeMultiPointer:
		GB_PANIC("TODO(bill): Type_RelativeMultiPointer should be handled above already on the cg_addr_load");
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
		Type *res_type = type_of_expr(expr);
		if (se->high == nullptr) {
			cgAddr res = cg_add_local(p, res_type, nullptr, false);
			GB_ASSERT(base.kind == cgValue_Value);
			GB_ASSERT(low.kind == cgValue_Value);

			i64 stride = type_size_of(type->MultiPointer.elem);
			cgValue offset = cg_value(tb_inst_array_access(p->func, base.node, low.node, stride), base.type);
			cg_addr_store(p, res, offset);
			return res;
		} else {
			cgAddr res = cg_add_local(p, res_type, nullptr, true);
			low  = cg_emit_conv(p, low,  t_int);
			high = cg_emit_conv(p, high, t_int);

			// cg_emit_multi_pointer_slice_bounds_check(p, se->open, low, high);

			i64 stride = type_size_of(type->MultiPointer.elem);
			TB_Node *offset = tb_inst_array_access(p->func, base.node, low.node, stride);
			TB_Node *len = tb_inst_sub(p->func, high.node, low.node, cast(TB_ArithmeticBehavior)0);

			TB_Node *data_ptr = tb_inst_member_access(p->func, res.addr.node, type_offset_of(res_type, 0));
			TB_Node *len_ptr  = tb_inst_member_access(p->func, res.addr.node, type_offset_of(res_type, 1));

			tb_inst_store(p->func, TB_TYPE_PTR, data_ptr, offset, cast(TB_CharUnits)build_context.ptr_size, false);
			tb_inst_store(p->func, TB_TYPE_INT, len_ptr,  len,    cast(TB_CharUnits)build_context.int_size, false);
			return res;
		}
	}

	case Type_Array: {
		Type *slice_type = type_of_expr(expr);
		GB_ASSERT(is_type_slice(slice_type));
		cgValue len = cg_const_int(p, t_int, type->Array.count);
		if (high.node == nullptr) high = len;

		// bool low_const  = type_and_value_of_expr(se->low).mode  == Addressing_Constant;
		// bool high_const = type_and_value_of_expr(se->high).mode == Addressing_Constant;
		// if (!low_const || !high_const) {
		// 	if (!no_indices) {
		// 		lb_emit_slice_bounds_check(p, se->open, low, high, len, se->low != nullptr);
		// 	}
		// }
		cgValue elem    = cg_emit_ptr_offset(p, cg_builtin_raw_data(p, cg_addr_get_ptr(p, addr)), low);
		cgValue new_len = cg_emit_arith(p, Token_Sub, high, low, t_int);

		cgAddr slice = cg_add_local(p, slice_type, nullptr, true);
		cg_fill_slice(p, slice, elem, new_len);
		return slice;
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

gb_internal cgValue cg_emit_unary_arith(cgProcedure *p, TokenKind op, cgValue x, Type *type) {
	switch (op) {
	case Token_Add:
		return x;
	case Token_Not: // Boolean not
	case Token_Xor: // Bitwise not
	case Token_Sub: // Number negation
		break;
	case Token_Pointer:
		GB_PANIC("This should be handled elsewhere");
		break;
	}

	x = cg_flatten_value(p, x);

	if (is_type_array_like(x.type)) {
		GB_PANIC("TODO(bill): cg_emit_unary_arith is_type_array_like");
		// // IMPORTANT TODO(bill): This is very wasteful with regards to stack memory
		// Type *tl = base_type(x.type);
		// cgValue val = cg_address_from_load_or_generate_local(p, x);
		// GB_ASSERT(is_type_array_like(type));
		// Type *elem_type = base_array_type(type);

		// // NOTE(bill): Doesn't need to be zero because it will be initialized in the loops
		// cgAddr res_addr = cg_add_local(p, type, nullptr, false);
		// cgValue res = cg_addr_get_ptr(p, res_addr);

		// bool inline_array_arith = cg_can_try_to_inline_array_arith(type);

		// i32 count = cast(i32)get_array_type_count(tl);

		// LLVMTypeRef vector_type = nullptr;
		// if (op != Token_Not && cg_try_vector_cast(p->module, val, &vector_type)) {
		// 	LLVMValueRef vp = LLVMBuildPointerCast(p->builder, val.value, LLVMPointerType(vector_type, 0), "");
		// 	LLVMValueRef v = LLVMBuildLoad2(p->builder, vector_type, vp, "");

		// 	LLVMValueRef opv = nullptr;
		// 	switch (op) {
		// 	case Token_Xor:
		// 		opv = LLVMBuildNot(p->builder, v, "");
		// 		break;
		// 	case Token_Sub:
		// 		if (is_type_float(elem_type)) {
		// 			opv = LLVMBuildFNeg(p->builder, v, "");
		// 		} else {
		// 			opv = LLVMBuildNeg(p->builder, v, "");
		// 		}
		// 		break;
		// 	}

		// 	if (opv != nullptr) {
		// 		LLVMSetAlignment(res.value, cast(unsigned)cg_alignof(vector_type));
		// 		LLVMValueRef res_ptr = LLVMBuildPointerCast(p->builder, res.value, LLVMPointerType(vector_type, 0), "");
		// 		LLVMBuildStore(p->builder, opv, res_ptr);
		// 		return cg_emit_conv(p, cg_emit_load(p, res), type);
		// 	}
		// }

		// if (inline_array_arith) {
		// 	// inline
		// 	for (i32 i = 0; i < count; i++) {
		// 		cgValue e = cg_emit_load(p, cg_emit_array_epi(p, val, i));
		// 		cgValue z = cg_emit_unary_arith(p, op, e, elem_type);
		// 		cg_emit_store(p, cg_emit_array_epi(p, res, i), z);
		// 	}
		// } else {
		// 	auto loop_data = cg_loop_start(p, count, t_i32);

		// 	cgValue e = cg_emit_load(p, cg_emit_array_ep(p, val, loop_data.idx));
		// 	cgValue z = cg_emit_unary_arith(p, op, e, elem_type);
		// 	cg_emit_store(p, cg_emit_array_ep(p, res, loop_data.idx), z);

		// 	cg_loop_end(p, loop_data);
		// }
		// return cg_emit_load(p, res);
	}

	if (op == Token_Xor) {
		GB_ASSERT(x.kind == cgValue_Value);
		cgValue cmp = cg_value(tb_inst_not(p->func, x.node), x.type);
		return cg_emit_conv(p, cmp, type);
	}

	if (op == Token_Not) {
		TB_Node *zero = cg_const_nil(p, x.type).node;
		cgValue cmp = cg_value(tb_inst_cmp_ne(p->func, x.node, zero), x.type);
		return cg_emit_conv(p, cmp, type);
	}

	if (op == Token_Sub && is_type_integer(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		cgValue v = cg_emit_byte_swap(p, x, platform_type);

		cgValue res = cg_value(tb_inst_neg(p->func, v.node), platform_type);
		return cg_emit_byte_swap(p, res, type);
	}

	if (op == Token_Sub && is_type_float(type) && is_type_different_to_arch_endianness(type)) {
		Type *platform_type = integer_endian_type_to_platform_type(type);
		cgValue v = cg_emit_byte_swap(p, x, platform_type);

		cgValue res = cg_value(tb_inst_neg(p->func, v.node), platform_type);
		return cg_emit_byte_swap(p, res, type);
	}

	cgValue res = {};

	if (op == Token_Sub) { // Number negation
		if (is_type_integer(x.type)) {
			res = cg_value(tb_inst_neg(p->func, x.node), x.type);
		} else if (is_type_float(x.type)) {
			res = cg_value(tb_inst_neg(p->func, x.node), x.type);
		} else if (is_type_complex(x.type)) {
			GB_PANIC("TODO(bill): neg complex");
			// LLVMValueRef v0 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 0, ""), "");
			// LLVMValueRef v1 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 1, ""), "");

			// cgAddr addr = cg_add_local_generated(p, x.type, false);
			// LLVMTypeRef type = llvm_addr_type(p->module, addr.addr);
			// LLVMBuildStore(p->builder, v0, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 0, ""));
			// LLVMBuildStore(p->builder, v1, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 1, ""));
			// return cg_addr_load(p, addr);

		} else if (is_type_quaternion(x.type)) {
			GB_PANIC("TODO(bill): neg quaternion");
			// LLVMValueRef v0 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 0, ""), "");
			// LLVMValueRef v1 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 1, ""), "");
			// LLVMValueRef v2 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 2, ""), "");
			// LLVMValueRef v3 = LLVMBuildFNeg(p->builder, LLVMBuildExtractValue(p->builder, x.value, 3, ""), "");

			// cgAddr addr = cg_add_local_generated(p, x.type, false);
			// LLVMTypeRef type = llvm_addr_type(p->module, addr.addr);
			// LLVMBuildStore(p->builder, v0, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 0, ""));
			// LLVMBuildStore(p->builder, v1, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 1, ""));
			// LLVMBuildStore(p->builder, v2, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 2, ""));
			// LLVMBuildStore(p->builder, v3, LLVMBuildStructGEP2(p->builder, type, addr.addr.value, 3, ""));
			// return cg_addr_load(p, addr);
		} else if (is_type_simd_vector(x.type)) {
			GB_PANIC("TODO(bill): neg simd");
			// Type *elem = base_array_type(x.type);
			// if (is_type_float(elem)) {
			// 	res.value = LLVMBuildFNeg(p->builder, x.value, "");
			// } else {
			// 	res.value = LLVMBuildNeg(p->builder, x.value, "");
			// }
		} else if (is_type_matrix(x.type)) {
			GB_PANIC("TODO(bill): neg matrix");
			// cgValue zero = {};
			// zero.value = LLVMConstNull(cg_type(p->module, type));
			// zero.type = type;
			// return cg_emit_arith_matrix(p, Token_Sub, zero, x, type, true);
		} else {
			GB_PANIC("Unhandled type %s", type_to_string(x.type));
		}
		res.type = x.type;
		return res;
	}

	return res;
}

gb_internal void cg_emit_if(cgProcedure *p, cgValue const &cond, TB_Node *true_region, TB_Node *false_region) {
	GB_ASSERT(cond.kind == cgValue_Value);
	tb_inst_if(p->func, cond.node, true_region, false_region);
}


struct cgLoopData {
	cgAddr  index_addr;
	cgValue index;
	TB_Node *body;
	TB_Node *done;
	TB_Node *loop;
};

gb_internal cgLoopData cg_loop_start(cgProcedure *p, isize count, Type *index_type) {
	cgLoopData data = {};

	cgValue max = cg_const_int(p, index_type, count);

	data.index_addr = cg_add_local(p, index_type, nullptr, true);

	data.body = cg_control_region(p, "loop_body");
	data.done = cg_control_region(p, "loop_done");
	data.loop = cg_control_region(p, "loop_loop");

	cg_emit_goto(p, data.loop);
	tb_inst_set_control(p->func, data.loop);

	data.index = cg_addr_load(p, data.index_addr);

	cgValue cond = cg_emit_comp(p, Token_Lt, data.index, max);
	cg_emit_if(p, cond, data.body, data.done);
	tb_inst_set_control(p->func, data.body);

	return data;
}

gb_internal void cg_loop_end(cgProcedure *p, cgLoopData const &data) {
	if (data.index_addr.addr.node != nullptr) {
		cg_emit_increment(p, data.index_addr.addr);
		cg_emit_goto(p, data.loop);
		tb_inst_set_control(p->func, data.done);
	}
}



gb_internal void cg_build_try_lhs_rhs(cgProcedure *p, Ast *arg, Type *final_type, cgValue *lhs_, cgValue *rhs_) {
	cgValue lhs = {};
	cgValue rhs = {};

	cgValue value = cg_build_expr(p, arg);
	if (value.kind == cgValue_Multi) {
		auto const &values = value.multi->values;
		if (values.count == 2) {
			lhs = values[0];
			rhs = values[1];
		} else {
			rhs = values[values.count-1];
			if (values.count > 1) {
				lhs = cg_value_multi(slice(values, 0, values.count-1), final_type);
			}
		}
	} else {
		rhs = value;
	}

	GB_ASSERT(rhs.node != nullptr);

	if (lhs_) *lhs_ = lhs;
	if (rhs_) *rhs_ = rhs;
}

gb_internal cgValue cg_emit_try_has_value(cgProcedure *p, cgValue rhs) {
	cgValue has_value = {};
	if (is_type_boolean(rhs.type)) {
		has_value = rhs;
	} else {
		GB_ASSERT_MSG(type_has_nil(rhs.type), "%s", type_to_string(rhs.type));
		has_value = cg_emit_comp_against_nil(p, Token_CmpEq, rhs);
	}
	GB_ASSERT(has_value.node != nullptr);
	return has_value;
}

gb_internal cgValue cg_build_or_return(cgProcedure *p, Ast *arg, Type *final_type) {
	cgValue lhs = {};
	cgValue rhs = {};
	cg_build_try_lhs_rhs(p, arg, final_type, &lhs, &rhs);

	TB_Node *return_region   = cg_control_region(p, "or_return_return");
	TB_Node *continue_region = cg_control_region(p, "or_return_continue");

	cgValue cond = cg_emit_try_has_value(p, rhs);
	cg_emit_if(p, cond, continue_region, return_region);
	tb_inst_set_control(p->func, return_region);
	{
		Type *proc_type = base_type(p->type);
		Type *results = proc_type->Proc.results;
		GB_ASSERT(results != nullptr && results->kind == Type_Tuple);
		TypeTuple *tuple = &results->Tuple;

		GB_ASSERT(tuple->variables.count != 0);

		Entity *end_entity = tuple->variables[tuple->variables.count-1];
		rhs = cg_emit_conv(p, rhs, end_entity->type);
		if (p->type->Proc.has_named_results) {
			GB_ASSERT(end_entity->token.string.len != 0);

			// NOTE(bill): store the named values before returning
			cgAddr found = map_must_get(&p->variable_map, end_entity);
			cg_addr_store(p, found, rhs);

			cg_build_return_stmt(p, {});
		} else {
			GB_ASSERT(tuple->variables.count == 1);
			Slice<cgValue> results = {};
			results.data = &rhs;
			results.count = 1;;
			cg_build_return_stmt_internal(p, results);
		}
	}
	tb_inst_set_control(p->func, continue_region);
	if (final_type != nullptr && !is_type_tuple(final_type)) {
		return cg_emit_conv(p, lhs, final_type);
	}
	return {};
}

gb_internal cgValue cg_build_or_else(cgProcedure *p, Ast *arg, Ast *else_expr, Type *final_type) {
	if (arg->state_flags & StateFlag_DirectiveWasFalse) {
		return cg_build_expr(p, else_expr);
	}

	cgValue lhs = {};
	cgValue rhs = {};
	cg_build_try_lhs_rhs(p, arg, final_type, &lhs, &rhs);

	GB_ASSERT(else_expr != nullptr);

	if (is_diverging_expr(else_expr)) {
		TB_Node *then  = cg_control_region(p, "or_else_then");
		TB_Node *else_ = cg_control_region(p, "or_else_else");

		cg_emit_if(p, cg_emit_try_has_value(p, rhs), then, else_);
		// NOTE(bill): else block needs to be straight afterwards to make sure that the actual value is used
		// from the then block
		tb_inst_set_control(p->func, else_);

		cg_build_expr(p, else_expr);

		tb_inst_set_control(p->func, then);
		return cg_emit_conv(p, lhs, final_type);
	} else {
		TB_Node *incoming_values[2] = {};
		TB_Node *incoming_regions[2] = {};

		TB_Node *then  = cg_control_region(p, "or_else_then");
		TB_Node *done  = cg_control_region(p, "or_else_done"); // NOTE(bill): Append later
		TB_Node *else_ = cg_control_region(p, "or_else_else");

		cg_emit_if(p, cg_emit_try_has_value(p, rhs), then, else_);
		tb_inst_set_control(p->func, then);

		cgValue x = cg_emit_conv(p, lhs, final_type);
		incoming_values[0] = x.node;
		incoming_regions[0] = tb_inst_get_control(p->func);

		tb_inst_goto(p->func, done);
		tb_inst_set_control(p->func, else_);

		cgValue y = cg_emit_conv(p, cg_build_expr(p, else_expr), final_type);
		incoming_values[1] = y.node;
		incoming_regions[1] = tb_inst_get_control(p->func);

		tb_inst_goto(p->func, done);
		tb_inst_set_control(p->func, done);

		GB_ASSERT(x.kind == y.kind);
		GB_ASSERT(incoming_values[0]->dt.raw == incoming_values[1]->dt.raw);
		cgValue res = {};
		res.kind = x.kind;
		res.type = final_type;

		res.node = tb_inst_incomplete_phi(p->func, incoming_values[0]->dt, done, 2);
		tb_inst_add_phi_operand(p->func, res.node, incoming_regions[0], incoming_values[0]);
		tb_inst_add_phi_operand(p->func, res.node, incoming_regions[1], incoming_values[1]);
		return res;
	}
}


gb_internal isize cg_control_region_pred_count(TB_Node *region) {
	GB_ASSERT(region->type == TB_REGION);
	GB_ASSERT(region->input_count > 0);
	return region->input_count;
}

gb_internal cgValue cg_build_logical_binary_expr(cgProcedure *p, TokenKind op, Ast *left, Ast *right, Type *final_type) {
	TB_Node *rhs  = cg_control_region(p, "logical_cmp_rhs");
	TB_Node *done = cg_control_region(p, "logical_cmp_done");

	cgValue short_circuit = {};
	if (op == Token_CmpAnd) {
		cg_build_cond(p, left, rhs, done);
		short_circuit = cg_const_bool(p, t_bool, false);
	} else if (op == Token_CmpOr) {
		cg_build_cond(p, left, done, rhs);
		short_circuit = cg_const_bool(p, t_bool, true);
	}

	if (rhs->input_count == 0) {
		tb_inst_set_control(p->func, done);
		return cg_emit_conv(p, short_circuit, final_type);
	}

	if (done->input_count == 0) {
		tb_inst_set_control(p->func, rhs);
		return cg_build_expr(p, right);
	}

	tb_inst_set_control(p->func, rhs);
	cgValue edge = cg_build_expr(p, right);
	TB_Node *edge_region = tb_inst_get_control(p->func);

	tb_inst_goto(p->func, done);
	tb_inst_set_control(p->func, done);

	TB_DataType dt = edge.node->dt;
	TB_Node *phi = tb_inst_incomplete_phi(p->func, dt, done, done->input_count);
	for (size_t i = 0; i < done->input_count; i++) {
		TB_Node *val = short_circuit.node;
		TB_Node *region = done->inputs[i];
		if (region == edge_region) {
			val = edge.node;
		}
		tb_inst_add_phi_operand(p->func, phi, region, val);
	}
	return cg_emit_conv(p, cg_value(phi, t_bool), final_type);
}



gb_internal cgValue cg_build_binary_expr(cgProcedure *p, Ast *expr) {
	ast_node(be, BinaryExpr, expr);

	TypeAndValue tv = type_and_value_of_expr(expr);

	if (is_type_matrix(be->left->tav.type) || is_type_matrix(be->right->tav.type)) {
		cgValue left = cg_build_expr(p, be->left);
		cgValue right = cg_build_expr(p, be->right);
		GB_PANIC("TODO(bill): cg_emit_arith_matrix");
		// return cg_emit_arith_matrix(p, be->op.kind, left, right, default_type(tv.type), false);
	}


	switch (be->op.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
	case Token_AndNot: {
		Type *type = default_type(tv.type);
		cgValue left = cg_build_expr(p, be->left);
		cgValue right = cg_build_expr(p, be->right);
		return cg_emit_arith(p, be->op.kind, left, right, type);
	}

	case Token_Shl:
	case Token_Shr: {
		cgValue left, right;
		Type *type = default_type(tv.type);
		left = cg_build_expr(p, be->left);

		if (cg_is_expr_untyped_const(be->right)) {
			// NOTE(bill): RHS shift operands can still be untyped
			// Just bypass the standard cg_build_expr
			right = cg_expr_untyped_const_to_typed(p, be->right, type);
		} else {
			right = cg_build_expr(p, be->right);
		}
		return cg_emit_arith(p, be->op.kind, left, right, type);
	}

	case Token_CmpEq:
	case Token_NotEq:
		if (is_type_untyped_nil(be->right->tav.type)) {
			// `x == nil` or `x != nil`
			cgValue left = cg_build_expr(p, be->left);
			cgValue cmp = cg_emit_comp_against_nil(p, be->op.kind, left);
			Type *type = default_type(tv.type);
			return cg_emit_conv(p, cmp, type);
		} else if (is_type_untyped_nil(be->left->tav.type)) {
			// `nil == x` or `nil != x`
			cgValue right = cg_build_expr(p, be->right);
			cgValue cmp = cg_emit_comp_against_nil(p, be->op.kind, right);
			Type *type = default_type(tv.type);
			return cg_emit_conv(p, cmp, type);
		}/* else if (cg_is_empty_string_constant(be->right)) {
			// `x == ""` or `x != ""`
			cgValue s = cg_build_expr(p, be->left);
			s = cg_emit_conv(p, s, t_string);
			cgValue len = cg_string_len(p, s);
			cgValue cmp = cg_emit_comp(p, be->op.kind, len, cg_const_int(p->module, t_int, 0));
			Type *type = default_type(tv.type);
			return cg_emit_conv(p, cmp, type);
		} else if (cg_is_empty_string_constant(be->left)) {
			// `"" == x` or `"" != x`
			cgValue s = cg_build_expr(p, be->right);
			s = cg_emit_conv(p, s, t_string);
			cgValue len = cg_string_len(p, s);
			cgValue cmp = cg_emit_comp(p, be->op.kind, len, cg_const_int(p->module, t_int, 0));
			Type *type = default_type(tv.type);
			return cg_emit_conv(p, cmp, type);
		}*/
		/*fallthrough*/
	case Token_Lt:
	case Token_LtEq:
	case Token_Gt:
	case Token_GtEq:
		{
			cgValue left = {};
			cgValue right = {};

			if (be->left->tav.mode == Addressing_Type) {
				left = cg_typeid(p, be->left->tav.type);
			}
			if (be->right->tav.mode == Addressing_Type) {
				right = cg_typeid(p, be->right->tav.type);
			}
			if (left.node == nullptr)  left  = cg_build_expr(p, be->left);
			if (right.node == nullptr) right = cg_build_expr(p, be->right);
			cgValue cmp = cg_emit_comp(p, be->op.kind, left, right);
			Type *type = default_type(tv.type);
			return cg_emit_conv(p, cmp, type);
		}

	case Token_CmpAnd:
	case Token_CmpOr:
		return cg_build_logical_binary_expr(p, be->op.kind, be->left, be->right, tv.type);

	case Token_in:
	case Token_not_in:
		{
			cgValue left = cg_build_expr(p, be->left);
			cgValue right = cg_build_expr(p, be->right);
			Type *rt = base_type(right.type);
			if (is_type_pointer(rt)) {
				right = cg_emit_load(p, right);
				rt = base_type(type_deref(rt));
			}

			switch (rt->kind) {
			case Type_Map:
				{
					cgValue map_ptr = cg_address_from_load_or_generate_local(p, right);
					cgValue key = left;
					cgValue ptr = cg_internal_dynamic_map_get_ptr(p, map_ptr, key);
					if (be->op.kind == Token_in) {
						return cg_emit_conv(p, cg_emit_comp_against_nil(p, Token_NotEq, ptr), t_bool);
					} else {
						return cg_emit_conv(p, cg_emit_comp_against_nil(p, Token_CmpEq, ptr), t_bool);
					}
				}
				break;
			case Type_BitSet:
				{
					Type *key_type = rt->BitSet.elem;
					GB_ASSERT(are_types_identical(left.type, key_type));

					Type *it = bit_set_to_int(rt);
					left = cg_emit_conv(p, left, it);
					if (is_type_different_to_arch_endianness(it)) {
						left = cg_emit_byte_swap(p, left, integer_endian_type_to_platform_type(it));
					}

					cgValue lower = cg_const_value(p, left.type, exact_value_i64(rt->BitSet.lower));
					cgValue key = cg_emit_arith(p, Token_Sub, left, lower, left.type);
					cgValue bit = cg_emit_arith(p, Token_Shl, cg_const_int(p, left.type, 1), key, left.type);
					bit = cg_emit_conv(p, bit, it);

					cgValue old_value = cg_emit_transmute(p, right, it);
					cgValue new_value = cg_emit_arith(p, Token_And, old_value, bit, it);

					GB_PANIC("TODO(bill): cg_emit_comp");
					// TokenKind op = (be->op.kind == Token_in) ? Token_NotEq : Token_CmpEq;
					// return cg_emit_conv(p, cg_emit_comp(p, op, new_value, cg_const_int(p, new_value.type, 0)), t_bool);
				}
				break;
			default:
				GB_PANIC("Invalid 'in' type");
			}
			break;
		}
		break;
	default:
		GB_PANIC("Invalid binary expression");
		break;
	}
	return {};
}

gb_internal cgValue cg_build_cond(cgProcedure *p, Ast *cond, TB_Node *true_block, TB_Node *false_block) {
	cond = unparen_expr(cond);

	GB_ASSERT(cond != nullptr);
	GB_ASSERT(true_block  != nullptr);
	GB_ASSERT(false_block != nullptr);

	// Use to signal not to do compile time short circuit for consts
	cgValue no_comptime_short_circuit = {};

	switch (cond->kind) {
	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			cgValue cond_val = cg_build_cond(p, ue->expr, false_block, true_block);
			return cond_val;
			// if (cond_val.value && LLVMIsConstant(cond_val.value)) {
			// 	return cg_const_bool(p->module, cond_val.type, LLVMConstIntGetZExtValue(cond_val.value) == 0);
			// }
			// return no_comptime_short_circuit;
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			TB_Node *block = cg_control_region(p, "cmp_and");
			cg_build_cond(p, be->left, block, false_block);
			tb_inst_set_control(p->func, block);
			cg_build_cond(p, be->right, true_block, false_block);
			return no_comptime_short_circuit;
		} else if (be->op.kind == Token_CmpOr) {
			TB_Node *block = cg_control_region(p, "cmp_or");
			cg_build_cond(p, be->left, true_block, block);
			tb_inst_set_control(p->func, block);
			cg_build_cond(p, be->right, true_block, false_block);
			return no_comptime_short_circuit;
		}
	case_end;
	}

	cgValue v = {};
	if (cg_is_expr_untyped_const(cond)) {
		v = cg_expr_untyped_const_to_typed(p, cond, t_bool);
	} else {
		v = cg_build_expr(p, cond);
	}
	cg_emit_if(p, v, true_block, false_block);
	return v;
}

gb_internal cgValue cg_build_expr_internal(cgProcedure *p, Ast *expr);
gb_internal cgValue cg_build_expr(cgProcedure *p, Ast *expr) {
	cg_set_debug_pos_from_node(p, expr);

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


gb_internal cgValue cg_find_ident(cgProcedure *p, Entity *e, Ast *expr) {
	cgAddr *found_addr = map_get(&p->variable_map, e);
	if (found_addr) {
		return cg_addr_load(p, *found_addr);
	}

	cgValue *found = nullptr;
	rw_mutex_shared_lock(&p->module->values_mutex);
	found = map_get(&p->module->values, e);
	rw_mutex_shared_unlock(&p->module->values_mutex);

	if (found) {

		auto v = *found;
		// NOTE(bill): This is because pointers are already pointers in LLVM
		if (is_type_proc(v.type)) {
			return v;
		}
		return cg_emit_load(p, v);
	} else if (e != nullptr && e->kind == Entity_Variable) {
		return cg_addr_load(p, cg_build_addr(p, expr));
	}

	if (e->kind == Entity_Procedure) {
		return cg_find_procedure_value_from_entity(p->module, e);
	}

	String pkg = {};
	if (e->pkg) {
		pkg = e->pkg->name;
	}
	gb_printf_err("Error in: %s\n", token_pos_to_string(ast_token(expr).pos));
	GB_PANIC("nullptr value for expression from identifier: %.*s.%.*s (%p) : %s @ %p", LIT(pkg), LIT(e->token.string), e, type_to_string(e->type), expr);
	return {};
}

cgAddr cg_build_addr_compound_lit(cgProcedure *p, Ast *expr) {
	struct cgCompoundLitElemTempData {
		Ast *   expr;
		cgValue value;
		i64     elem_index;
		i64     elem_length;
		cgValue gep;
	};


	auto const &populate = [](cgProcedure *p, Slice<Ast *> const &elems, Array<cgCompoundLitElemTempData> *temp_data, Type *compound_type) {
		Type *bt = base_type(compound_type);
		Type *et = nullptr;
		switch (bt->kind) {
		case Type_Array:           et = bt->Array.elem;           break;
		case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
		case Type_Slice:           et = bt->Slice.elem;           break;
		case Type_BitSet:          et = bt->BitSet.elem;          break;
		case Type_DynamicArray:    et = bt->DynamicArray.elem;    break;
		case Type_SimdVector:      et = bt->SimdVector.elem;      break;
		case Type_Matrix:          et = bt->Matrix.elem;          break;
		}
		GB_ASSERT(et != nullptr);


		// NOTE(bill): Separate value, gep, store into their own chunks
		for_array(i, elems) {
			Ast *elem = elems[i];
			if (elem->kind == Ast_FieldValue) {
				ast_node(fv, FieldValue, elem);
				if (is_ast_range(fv->field)) {
					ast_node(ie, BinaryExpr, fv->field);
					TypeAndValue lo_tav = ie->left->tav;
					TypeAndValue hi_tav = ie->right->tav;
					GB_ASSERT(lo_tav.mode == Addressing_Constant);
					GB_ASSERT(hi_tav.mode == Addressing_Constant);

					TokenKind op = ie->op.kind;
					i64 lo = exact_value_to_i64(lo_tav.value);
					i64 hi = exact_value_to_i64(hi_tav.value);
					if (op != Token_RangeHalf) {
						hi += 1;
					}

					cgValue value = cg_emit_conv(p, cg_build_expr(p, fv->value), et);

					GB_ASSERT((hi-lo) > 0);

					if (bt->kind == Type_Matrix) {
						GB_PANIC("TODO(bill): Type_Matrix");
						// for (i64 k = lo; k < hi; k++) {
						// 	cgCompoundLitElemTempData data = {};
						// 	data.value = value;

						// 	data.elem_index = matrix_row_major_index_to_offset(bt, k);
						// 	array_add(temp_data, data);
						// }
					} else {
						enum {MAX_ELEMENT_AMOUNT = 32};
						if ((hi-lo) <= MAX_ELEMENT_AMOUNT) {
							for (i64 k = lo; k < hi; k++) {
								cgCompoundLitElemTempData data = {};
								data.value = value;
								data.elem_index = k;
								array_add(temp_data, data);
							}
						} else {
							cgCompoundLitElemTempData data = {};
							data.value = value;
							data.elem_index = lo;
							data.elem_length = hi-lo;
							array_add(temp_data, data);
						}
					}
				} else {
					auto tav = fv->field->tav;
					GB_ASSERT(tav.mode == Addressing_Constant);
					i64 index = exact_value_to_i64(tav.value);

					cgValue value = cg_emit_conv(p, cg_build_expr(p, fv->value), et);
					GB_ASSERT(!is_type_tuple(value.type));

					cgCompoundLitElemTempData data = {};
					data.value = value;
					data.expr = fv->value;
					if (bt->kind == Type_Matrix) {
						GB_PANIC("TODO(bill): Type_Matrix");
						// data.elem_index = matrix_row_major_index_to_offset(bt, index);
					} else {
						data.elem_index = index;
					}
					array_add(temp_data, data);
				}

			} else {
				// if (bt->kind != Type_DynamicArray && lb_is_elem_const(elem, et)) {
					// continue;
				// }

				cgValue field_expr = cg_build_expr(p, elem);
				GB_ASSERT(!is_type_tuple(field_expr.type));

				cgValue ev = cg_emit_conv(p, field_expr, et);

				cgCompoundLitElemTempData data = {};
				data.value = ev;
				if (bt->kind == Type_Matrix) {
						GB_PANIC("TODO(bill): Type_Matrix");
					// data.elem_index = matrix_row_major_index_to_offset(bt, i);
				} else {
					data.elem_index = i;
				}
				array_add(temp_data, data);
			}
		}
	};

	auto const &assign_array = [](cgProcedure *p, Array<cgCompoundLitElemTempData> const &temp_data) {
		for (auto const &td : temp_data) if (td.value.node != nullptr) {
			if (td.elem_length > 0) {
				GB_PANIC("TODO(bill): range");
				// auto loop_data = cg_loop_start(p, cast(isize)td.elem_length, t_i32);
				// {
				// 	cgValue dst = td.gep;
				// 	dst = cg_emit_ptr_offset(p, dst, loop_data.idx);
				// 	cg_emit_store(p, dst, td.value);
				// }
				// cg_loop_end(p, loop_data);
			} else {
				cg_emit_store(p, td.gep, td.value);
			}
		}
	};



	ast_node(cl, CompoundLit, expr);

	Type *type = type_of_expr(expr);
	Type *bt = base_type(type);

	cgAddr v = {};
	if (p->is_startup) {
		v = cg_add_global(p, type, nullptr);
	} else {
		v = cg_add_local(p, type, nullptr, true);
	}

	if (cl->elems.count == 0) {
		// No need to create it
		return v;
	}

	TEMPORARY_ALLOCATOR_GUARD();

	Type *et = nullptr;
	switch (bt->kind) {
	case Type_Array:           et = bt->Array.elem;           break;
	case Type_EnumeratedArray: et = bt->EnumeratedArray.elem; break;
	case Type_Slice:           et = bt->Slice.elem;           break;
	case Type_BitSet:          et = bt->BitSet.elem;          break;
	case Type_SimdVector:      et = bt->SimdVector.elem;      break;
	case Type_Matrix:          et = bt->Matrix.elem;          break;
	}

	String proc_name = {};
	if (p->entity) {
		proc_name = p->entity->token.string;
	}
	TokenPos pos = ast_token(expr).pos;


	switch (bt->kind) {
	default: GB_PANIC("Unknown CompoundLit type: %s", type_to_string(type)); break;

	case Type_Struct: {
		TypeStruct *st = &bt->Struct;
		cgValue comp_lit_ptr = cg_addr_get_ptr(p, v);

		for_array(field_index, cl->elems) {
			Ast *elem = cl->elems[field_index];

			cgValue field_expr = {};
			Entity *field = nullptr;
			isize index = field_index;

			if (elem->kind == Ast_FieldValue) {
				ast_node(fv, FieldValue, elem);
				String name = fv->field->Ident.token.string;
				Selection sel = lookup_field(bt, name, false);
				GB_ASSERT(!sel.indirect);

				elem = fv->value;
				if (sel.index.count > 1) {
					cgValue dst = cg_emit_deep_field_gep(p, comp_lit_ptr, sel);
					field_expr = cg_build_expr(p, elem);
					field_expr = cg_emit_conv(p, field_expr, sel.entity->type);
					cg_emit_store(p, dst, field_expr);
					continue;
				}

				index = sel.index[0];
			} else {
				Selection sel = lookup_field_from_index(bt, st->fields[field_index]->Variable.field_index);
				GB_ASSERT(sel.index.count == 1);
				GB_ASSERT(!sel.indirect);
				index = sel.index[0];
			}

			field = st->fields[index];
			Type *ft = field->type;

			field_expr = cg_build_expr(p, elem);

			cgValue gep = {};
			if (st->is_raw_union) {
				gep = cg_emit_conv(p, comp_lit_ptr, alloc_type_pointer(ft));
			} else {
				gep = cg_emit_struct_ep(p, comp_lit_ptr, cast(i32)index);
			}

			Type *fet = field_expr.type;
			GB_ASSERT(fet->kind != Type_Tuple);

			// HACK TODO(bill): THIS IS A MASSIVE HACK!!!!
			if (is_type_union(ft) && !are_types_identical(fet, ft) && !is_type_untyped(fet)) {
				GB_ASSERT_MSG(union_variant_index(ft, fet) >= 0, "%s", type_to_string(fet));

				GB_PANIC("TODO(bill): cg_emit_store_union_variant");
				// cg_emit_store_union_variant(p, gep, field_expr, fet);
			} else {
				cgValue fv = cg_emit_conv(p, field_expr, ft);
				cg_emit_store(p, gep, fv);
			}
		}
		return v;
	}

	case Type_Map: {
		GB_ASSERT(!build_context.no_dynamic_literals);
		GB_PANIC("TODO(bill): map literals");

		// cgValue err = cg_dynamic_map_reserve(p, v.addr, 2*cl->elems.count, pos);
		// gb_unused(err);

		// for (Ast *elem : cl->elems) {
		// 	ast_node(fv, FieldValue, elem);

		// 	cgValue key   = cg_build_expr(p, fv->field);
		// 	cgValue value = cg_build_expr(p, fv->value);
		// 	cg_internal_dynamic_map_set(p, v.addr, type, key, value, elem);
		// }
		break;
	}

	case Type_Array: {
		auto temp_data = array_make<cgCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

		populate(p, cl->elems, &temp_data, type);

		cgValue dst_ptr = cg_addr_get_ptr(p, v);
		for_array(i, temp_data) {
			i32 index = cast(i32)(temp_data[i].elem_index);
			temp_data[i].gep = cg_emit_array_epi(p, dst_ptr, index);
		}

		assign_array(p, temp_data);
		break;
	}
	case Type_EnumeratedArray: {
		auto temp_data = array_make<cgCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

		populate(p, cl->elems, &temp_data, type);

		cgValue dst_ptr = cg_addr_get_ptr(p, v);
		i64 index_offset = exact_value_to_i64(*bt->EnumeratedArray.min_value);
		for_array(i, temp_data) {
			i32 index = cast(i32)(temp_data[i].elem_index - index_offset);
			temp_data[i].gep = cg_emit_array_epi(p, dst_ptr, index);
		}

		assign_array(p, temp_data);
		break;
	}
	case Type_Slice: {
		isize count = gb_max(cl->elems.count, cl->max_count);

		TB_CharUnits backing_size = cast(TB_CharUnits)(type_size_of(bt->Slice.elem) * count);
		TB_CharUnits align = cast(TB_CharUnits)type_align_of(bt->Slice.elem);

		TB_Node *backing = nullptr;
		if (p->is_startup) {
			TB_Global *global = tb_global_create(p->module->mod, 0, "", nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(p->module->mod, tb_module_get_data(p->module->mod), global, backing_size, align, 0);
			backing = tb_inst_get_symbol_address(p->func, cast(TB_Symbol *)global);
		} else {
			backing = tb_inst_local(p->func, backing_size, align);
		}

		cgValue data = cg_value(backing, alloc_type_multi_pointer(bt->Slice.elem));

		auto temp_data = array_make<cgCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);
		populate(p, cl->elems, &temp_data, type);


		for_array(i, temp_data) {
			temp_data[i].gep = cg_emit_ptr_offset(p, data, cg_const_int(p, t_int, temp_data[i].elem_index));
		}

		assign_array(p, temp_data);
		cg_fill_slice(p, v, data, cg_const_int(p, t_int, count));
		return v;
	}

	case Type_DynamicArray: {
		GB_ASSERT(!build_context.no_dynamic_literals);

		Type *et = bt->DynamicArray.elem;
		cgValue size  = cg_const_int(p, t_int, type_size_of(et));
		cgValue align = cg_const_int(p, t_int, type_align_of(et));

		i64 item_count = gb_max(cl->max_count, cl->elems.count);
		{

			auto args = slice_make<cgValue>(temporary_allocator(), 5);
			args[0] = cg_emit_conv(p, cg_addr_get_ptr(p, v), t_rawptr);
			args[1] = size;
			args[2] = align;
			args[3] = cg_const_int(p, t_int, item_count);
			args[4] = cg_emit_source_code_location_as_global(p, proc_name, pos);
			cg_emit_runtime_call(p, "__dynamic_array_reserve", args);
		}

		Type *array_type = alloc_type_array(et, item_count);
		cgAddr items_addr = cg_add_local(p, array_type, nullptr, true);
		cgValue items = cg_addr_get_ptr(p, items_addr);

		auto temp_data = array_make<cgCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);
		populate(p, cl->elems, &temp_data, type);

		for_array(i, temp_data) {
			temp_data[i].gep = cg_emit_array_epi(p, items, temp_data[i].elem_index);
		}
		assign_array(p, temp_data);

		{
			auto args = slice_make<cgValue>(temporary_allocator(), 6);
			args[0] = cg_emit_conv(p, v.addr, t_rawptr);
			args[1] = size;
			args[2] = align;
			args[3] = cg_emit_conv(p, items, t_rawptr);
			args[4] = cg_const_int(p, t_int, item_count);
			args[5] = cg_emit_source_code_location_as_global(p, proc_name, pos);
			cg_emit_runtime_call(p, "__dynamic_array_append", args);
		}
		break;
	}

	case Type_Basic: {
		GB_ASSERT(is_type_any(bt));
		String field_names[2] = {
			str_lit("data"),
			str_lit("id"),
		};
		Type *field_types[2] = {
			t_rawptr,
			t_typeid,
		};

		for_array(field_index, cl->elems) {
			Ast *elem = cl->elems[field_index];

			cgValue field_expr = {};
			isize index = field_index;

			if (elem->kind == Ast_FieldValue) {
				ast_node(fv, FieldValue, elem);
				Selection sel = lookup_field(bt, fv->field->Ident.token.string, false);
				index = sel.index[0];
				elem = fv->value;
			} else {
				TypeAndValue tav = type_and_value_of_expr(elem);
				Selection sel = lookup_field(bt, field_names[field_index], false);
				index = sel.index[0];
			}

			field_expr = cg_build_expr(p, elem);

			GB_ASSERT(field_expr.type->kind != Type_Tuple);

			Type *ft = field_types[index];
			cgValue fv = cg_emit_conv(p, field_expr, ft);
			cgValue gep = cg_emit_struct_ep(p, cg_addr_get_ptr(p, v), index);
			cg_emit_store(p, gep, fv);
		}
		break;
	}

	case Type_BitSet: {
		i64 sz = type_size_of(type);
		if (sz == 0) {
			return v;
		}
		cgValue lower = cg_const_value(p, t_int, exact_value_i64(bt->BitSet.lower));
		Type *it = bit_set_to_int(bt);
		cgValue one = cg_const_value(p, it, exact_value_i64(1));
		for (Ast *elem : cl->elems) {
			GB_ASSERT(elem->kind != Ast_FieldValue);

			cgValue expr = cg_build_expr(p, elem);
			GB_ASSERT(expr.type->kind != Type_Tuple);

			cgValue e = cg_emit_conv(p, expr, it);
			e = cg_emit_arith(p, Token_Sub, e, lower, it);
			e = cg_emit_arith(p, Token_Shl, one, e, it);

			cgValue old_value = cg_emit_transmute(p, cg_addr_load(p, v), it);
			cgValue new_value = cg_emit_arith(p, Token_Or, old_value, e, it);
			new_value = cg_emit_transmute(p, new_value, type);
			cg_addr_store(p, v, new_value);
		}
		return v;
	}

	case Type_Matrix: {
		auto temp_data = array_make<cgCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

		populate(p, cl->elems, &temp_data, type);

		cgValue dst_ptr = cg_addr_get_ptr(p, v);
		for_array(i, temp_data) {
			temp_data[i].gep = cg_emit_array_epi(p, dst_ptr, temp_data[i].elem_index);
		}

		assign_array(p, temp_data);
		break;
	}

	case Type_SimdVector: {
		// auto temp_data = array_make<cgCompoundLitElemTempData>(temporary_allocator(), 0, cl->elems.count);

		// populate(p, cl->elems, &temp_data, type);

		// // TODO(bill): reduce the need for individual `insertelement` if a `shufflevector`
		// // might be a better option
		// for (auto const &td : temp_data) if (td.value.node != nullptr) {
		// 	if (td.elem_length > 0) {
		// 		for (i64 k = 0; k < td.elem_length; k++) {
		// 			LLVMValueRef index = cg_const_int(p->module, t_u32, td.elem_index + k).value;
		// 			vector_value.value = LLVMBuildInsertElement(p->builder, vector_value.value, td.value.value, index, "");
		// 		}
		// 	} else {
		// 		LLVMValueRef index = cg_const_int(p->module, t_u32, td.elem_index).value;
		// 		vector_value.value = LLVMBuildInsertElement(p->builder, vector_value.value, td.value.value, index, "");

		// 	}
		// }
		break;
	}
	}

	return v;
}

gb_internal cgValue cg_make_soa_pointer(cgProcedure *p, Type *type, cgValue const &addr, cgValue const &index) {
	cgAddr v = cg_add_local(p, type, nullptr, true);
	cgValue ptr = cg_emit_struct_ep(p, v.addr, 0);
	cgValue idx = cg_emit_struct_ep(p, v.addr, 1);
	cg_emit_store(p, ptr, addr);
	cg_emit_store(p, idx, cg_emit_conv(p, index, t_int));

	return cg_addr_load(p, v);
}

gb_internal cgValue cg_build_unary_and(cgProcedure *p, Ast *expr) {
	ast_node(ue, UnaryExpr, expr);
	auto tv = type_and_value_of_expr(expr);


	Ast *ue_expr = unparen_expr(ue->expr);
	if (ue_expr->kind == Ast_IndexExpr && tv.mode == Addressing_OptionalOkPtr && is_type_tuple(tv.type)) {
		GB_PANIC("TODO(bill): &m[k]");
		// Type *tuple = tv.type;

		// Type *map_type = type_of_expr(ue_expr->IndexExpr.expr);
		// Type *ot = base_type(map_type);
		// Type *t = base_type(type_deref(ot));
		// bool deref = t != ot;
		// GB_ASSERT(t->kind == Type_Map);
		// ast_node(ie, IndexExpr, ue_expr);

		// cgValue map_val = cg_build_addr_ptr(p, ie->expr);
		// if (deref) {
		// 	map_val = cg_emit_load(p, map_val);
		// }

		// cgValue key = lb_build_expr(p, ie->index);
		// key = lb_emit_conv(p, key, t->Map.key);

		// lbAddr addr = lb_addr_map(map_val, key, t, alloc_type_pointer(t->Map.value));
		// lbValue ptr = lb_addr_get_ptr(p, addr);

		// lbValue ok = lb_emit_comp_against_nil(p, Token_NotEq, ptr);
		// ok = lb_emit_conv(p, ok, tuple->Tuple.variables[1]->type);

		// lbAddr res = lb_add_local_generated(p, tuple, false);
		// lbValue gep0 = lb_emit_struct_ep(p, res.addr, 0);
		// lbValue gep1 = lb_emit_struct_ep(p, res.addr, 1);
		// lb_emit_store(p, gep0, ptr);
		// lb_emit_store(p, gep1, ok);
		// return lb_addr_load(p, res);

	} else if (is_type_soa_pointer(tv.type)) {
		ast_node(ie, IndexExpr, ue_expr);
		cgValue addr = cg_build_addr_ptr(p, ie->expr);
		cgValue index = cg_build_expr(p, ie->index);

		if (!build_context.no_bounds_check) {
			// TODO(bill): soa bounds checking
		}

		return cg_make_soa_pointer(p, tv.type, addr, index);
	} else if (ue_expr->kind == Ast_CompoundLit) {
		cgAddr addr = cg_build_addr_compound_lit(p, expr);
		return addr.addr;
	} else if (ue_expr->kind == Ast_TypeAssertion) {
		GB_PANIC("TODO(bill): &v.(T)");
		// if (is_type_tuple(tv.type)) {
		// 	Type *tuple = tv.type;
		// 	Type *ptr_type = tuple->Tuple.variables[0]->type;
		// 	Type *ok_type = tuple->Tuple.variables[1]->type;

		// 	ast_node(ta, TypeAssertion, ue_expr);
		// 	TokenPos pos = ast_token(expr).pos;
		// 	Type *type = type_of_expr(ue_expr);
		// 	GB_ASSERT(!is_type_tuple(type));

		// 	lbValue e = lb_build_expr(p, ta->expr);
		// 	Type *t = type_deref(e.type);
		// 	if (is_type_union(t)) {
		// 		lbValue v = e;
		// 		if (!is_type_pointer(v.type)) {
		// 			v = lb_address_from_load_or_generate_local(p, v);
		// 		}
		// 		Type *src_type = type_deref(v.type);
		// 		Type *dst_type = type;

		// 		lbValue src_tag = {};
		// 		lbValue dst_tag = {};
		// 		if (is_type_union_maybe_pointer(src_type)) {
		// 			src_tag = lb_emit_comp_against_nil(p, Token_NotEq, v);
		// 			dst_tag = lb_const_bool(p->module, t_bool, true);
		// 		} else {
		// 			src_tag = lb_emit_load(p, lb_emit_union_tag_ptr(p, v));
		// 			dst_tag = lb_const_union_tag(p->module, src_type, dst_type);
		// 		}

		// 		lbValue ok = lb_emit_comp(p, Token_CmpEq, src_tag, dst_tag);

		// 		lbValue data_ptr = lb_emit_conv(p, v, ptr_type);
		// 		lbAddr res = lb_add_local_generated(p, tuple, true);
		// 		lbValue gep0 = lb_emit_struct_ep(p, res.addr, 0);
		// 		lbValue gep1 = lb_emit_struct_ep(p, res.addr, 1);
		// 		lb_emit_store(p, gep0, lb_emit_select(p, ok, data_ptr, lb_const_nil(p->module, ptr_type)));
		// 		lb_emit_store(p, gep1, lb_emit_conv(p, ok, ok_type));
		// 		return lb_addr_load(p, res);
		// 	} else if (is_type_any(t)) {
		// 		lbValue v = e;
		// 		if (is_type_pointer(v.type)) {
		// 			v = lb_emit_load(p, v);
		// 		}

		// 		lbValue data_ptr = lb_emit_conv(p, lb_emit_struct_ev(p, v, 0), ptr_type);
		// 		lbValue any_id = lb_emit_struct_ev(p, v, 1);
		// 		lbValue id = lb_typeid(p->module, type);

		// 		lbValue ok = lb_emit_comp(p, Token_CmpEq, any_id, id);

		// 		lbAddr res = lb_add_local_generated(p, tuple, false);
		// 		lbValue gep0 = lb_emit_struct_ep(p, res.addr, 0);
		// 		lbValue gep1 = lb_emit_struct_ep(p, res.addr, 1);
		// 		lb_emit_store(p, gep0, lb_emit_select(p, ok, data_ptr, lb_const_nil(p->module, ptr_type)));
		// 		lb_emit_store(p, gep1, lb_emit_conv(p, ok, ok_type));
		// 		return lb_addr_load(p, res);
		// 	} else {
		// 		GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
		// 	}

		// } else {
		// 	GB_ASSERT(is_type_pointer(tv.type));

		// 	ast_node(ta, TypeAssertion, ue_expr);
		// 	TokenPos pos = ast_token(expr).pos;
		// 	Type *type = type_of_expr(ue_expr);
		// 	GB_ASSERT(!is_type_tuple(type));

		// 	lbValue e = lb_build_expr(p, ta->expr);
		// 	Type *t = type_deref(e.type);
		// 	if (is_type_union(t)) {
		// 		lbValue v = e;
		// 		if (!is_type_pointer(v.type)) {
		// 			v = lb_address_from_load_or_generate_local(p, v);
		// 		}
		// 		Type *src_type = type_deref(v.type);
		// 		Type *dst_type = type;


		// 		if ((p->state_flags & StateFlag_no_type_assert) == 0) {
		// 			lbValue src_tag = {};
		// 			lbValue dst_tag = {};
		// 			if (is_type_union_maybe_pointer(src_type)) {
		// 				src_tag = lb_emit_comp_against_nil(p, Token_NotEq, v);
		// 				dst_tag = lb_const_bool(p->module, t_bool, true);
		// 			} else {
		// 				src_tag = lb_emit_load(p, lb_emit_union_tag_ptr(p, v));
		// 				dst_tag = lb_const_union_tag(p->module, src_type, dst_type);
		// 			}


		// 			isize arg_count = 6;
		// 			if (build_context.no_rtti) {
		// 				arg_count = 4;
		// 			}

		// 			lbValue ok = lb_emit_comp(p, Token_CmpEq, src_tag, dst_tag);
		// 			auto args = array_make<lbValue>(permanent_allocator(), arg_count);
		// 			args[0] = ok;

		// 			args[1] = lb_find_or_add_entity_string(p->module, get_file_path_string(pos.file_id));
		// 			args[2] = lb_const_int(p->module, t_i32, pos.line);
		// 			args[3] = lb_const_int(p->module, t_i32, pos.column);

		// 			if (!build_context.no_rtti) {
		// 				args[4] = lb_typeid(p->module, src_type);
		// 				args[5] = lb_typeid(p->module, dst_type);
		// 			}
		// 			lb_emit_runtime_call(p, "type_assertion_check", args);
		// 		}

		// 		lbValue data_ptr = v;
		// 		return lb_emit_conv(p, data_ptr, tv.type);
		// 	} else if (is_type_any(t)) {
		// 		lbValue v = e;
		// 		if (is_type_pointer(v.type)) {
		// 			v = lb_emit_load(p, v);
		// 		}
		// 		lbValue data_ptr = lb_emit_struct_ev(p, v, 0);
		// 		if ((p->state_flags & StateFlag_no_type_assert) == 0) {
		// 			GB_ASSERT(!build_context.no_rtti);

		// 			lbValue any_id = lb_emit_struct_ev(p, v, 1);

		// 			lbValue id = lb_typeid(p->module, type);
		// 			lbValue ok = lb_emit_comp(p, Token_CmpEq, any_id, id);
		// 			auto args = array_make<lbValue>(permanent_allocator(), 6);
		// 			args[0] = ok;

		// 			args[1] = lb_find_or_add_entity_string(p->module, get_file_path_string(pos.file_id));
		// 			args[2] = lb_const_int(p->module, t_i32, pos.line);
		// 			args[3] = lb_const_int(p->module, t_i32, pos.column);

		// 			args[4] = any_id;
		// 			args[5] = id;
		// 			lb_emit_runtime_call(p, "type_assertion_check", args);
		// 		}

		// 		return lb_emit_conv(p, data_ptr, tv.type);
		// 	} else {
		// 		GB_PANIC("TODO(bill): type assertion %s", type_to_string(type));
		// 	}
		// }
	}

	return cg_build_addr_ptr(p, ue->expr);
}

gb_internal cgValue cg_emit_cast_union(cgProcedure *p, cgValue value, Type *type, TokenPos pos) {
	Type *src_type = value.type;
	bool is_ptr = is_type_pointer(src_type);

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}


	if (is_ptr) {
		value = cg_emit_load(p, value);
	}
	Type *src = base_type(type_deref(src_type));
	GB_ASSERT_MSG(is_type_union(src), "%s", type_to_string(src_type));
	Type *dst = tuple->Tuple.variables[0]->type;

	cgValue value_  = cg_address_from_load_or_generate_local(p, value);

	if ((p->state_flags & StateFlag_no_type_assert) != 0 && !is_tuple) {
		// just do a bit cast of the data at the front
		cgValue ptr = cg_emit_conv(p, value_, alloc_type_pointer(type));
		return cg_emit_load(p, ptr);
	}


	cgValue tag = {};
	cgValue dst_tag = {};
	cgValue cond = {};
	cgValue data = {};

	cgValue gep0 = cg_add_local(p, tuple->Tuple.variables[0]->type, nullptr, true).addr;
	cgValue gep1 = cg_add_local(p, tuple->Tuple.variables[1]->type, nullptr, true).addr;

	if (is_type_union_maybe_pointer(src)) {
		data = cg_emit_load(p, cg_emit_conv(p, value_, gep0.type));
	} else {
		tag     = cg_emit_load(p, cg_emit_union_tag_ptr(p, value_));
		dst_tag = cg_const_union_tag(p, src, dst);
	}

	TB_Node *ok_block  = cg_control_region(p, "union_cast_ok");
	TB_Node *end_block = cg_control_region(p, "union_cast_end");

	if (data.node != nullptr) {
		GB_ASSERT(is_type_union_maybe_pointer(src));
		cond = cg_emit_comp_against_nil(p, Token_NotEq, data);
	} else {
		cond = cg_emit_comp(p, Token_CmpEq, tag, dst_tag);
	}

	cg_emit_if(p, cond, ok_block, end_block);
	tb_inst_set_control(p->func, ok_block);

	if (data.node == nullptr) {
		data = cg_emit_load(p, cg_emit_conv(p, value_, gep0.type));
	}
	cg_emit_store(p, gep0, data);
	cg_emit_store(p, gep1, cg_const_bool(p, t_bool, true));

	cg_emit_goto(p, end_block);
	tb_inst_set_control(p->func, end_block);

	if (!is_tuple) {
		GB_ASSERT((p->state_flags & StateFlag_no_type_assert) == 0);
		// NOTE(bill): Panic on invalid conversion
		Type *dst_type = tuple->Tuple.variables[0]->type;

		isize arg_count = 7;
		if (build_context.no_rtti) {
			arg_count = 4;
		}

		cgValue ok = cg_emit_load(p, gep1);
		auto args = slice_make<cgValue>(permanent_allocator(), arg_count);
		args[0] = ok;

		args[1] = cg_const_string(p, t_string, get_file_path_string(pos.file_id));
		args[2] = cg_const_int(p, t_i32, pos.line);
		args[3] = cg_const_int(p, t_i32, pos.column);

		if (!build_context.no_rtti) {
			args[4] = cg_typeid(p, src_type);
			args[5] = cg_typeid(p, dst_type);
			args[6] = cg_emit_conv(p, value_, t_rawptr);
		}
		cg_emit_runtime_call(p, "type_assertion_check2", args);

		return cg_emit_load(p, gep0);
	}

	return cg_value_multi2(cg_emit_load(p, gep0), cg_emit_load(p, gep1), tuple);
}

gb_internal cgValue cg_emit_cast_any(cgProcedure *p, cgValue value, Type *type, TokenPos pos) {
	Type *src_type = value.type;

	if (is_type_pointer(src_type)) {
		value = cg_emit_load(p, value);
	}

	bool is_tuple = true;
	Type *tuple = type;
	if (type->kind != Type_Tuple) {
		is_tuple = false;
		tuple = make_optional_ok_type(type);
	}
	Type *dst_type = tuple->Tuple.variables[0]->type;

	if ((p->state_flags & StateFlag_no_type_assert) != 0 && !is_tuple) {
		// just do a bit cast of the data at the front
		cgValue ptr = cg_emit_struct_ev(p, value, 0);
		ptr = cg_emit_conv(p, ptr, alloc_type_pointer(type));
		return cg_emit_load(p, ptr);
	}

	cgValue dst_typeid = cg_typeid(p, dst_type);
	cgValue any_typeid = cg_emit_struct_ev(p, value, 1);


	TB_Node *ok_block = cg_control_region(p, "any_cast_ok");
	TB_Node *end_block = cg_control_region(p, "any_cast_end");
	cgValue cond = cg_emit_comp(p, Token_CmpEq, any_typeid, dst_typeid);
	cg_emit_if(p, cond, ok_block, end_block);
	tb_inst_set_control(p->func, ok_block);

	cgValue gep0 = cg_add_local(p, tuple->Tuple.variables[0]->type, nullptr, true).addr;
	cgValue gep1 = cg_add_local(p, tuple->Tuple.variables[1]->type, nullptr, true).addr;

	cgValue any_data = cg_emit_struct_ev(p, value, 0);
	cgValue ptr = cg_emit_conv(p, any_data, alloc_type_pointer(dst_type));
	cg_emit_store(p, gep0, cg_emit_load(p, ptr));
	cg_emit_store(p, gep1, cg_const_bool(p, t_bool, true));

	cg_emit_goto(p, end_block);
	tb_inst_set_control(p->func, end_block);

	if (!is_tuple) {
		// NOTE(bill): Panic on invalid conversion
		cgValue ok = cg_emit_load(p, gep1);

		isize arg_count = 7;
		if (build_context.no_rtti) {
			arg_count = 4;
		}
		auto args = slice_make<cgValue>(permanent_allocator(), arg_count);
		args[0] = ok;

		args[1] = cg_const_string(p, t_string, get_file_path_string(pos.file_id));
		args[2] = cg_const_int(p, t_i32, pos.line);
		args[3] = cg_const_int(p, t_i32, pos.column);

		if (!build_context.no_rtti) {
			args[4] = any_typeid;
			args[5] = dst_typeid;
			args[6] = cg_emit_struct_ev(p, value, 0);
		}
		cg_emit_runtime_call(p, "type_assertion_check2", args);

		return cg_emit_load(p, gep0);
	}

	return cg_value_multi2(cg_emit_load(p, gep0), cg_emit_load(p, gep1), tuple);
}


gb_internal cgValue cg_build_type_assertion(cgProcedure *p, Ast *expr, Type *type) {
	ast_node(ta, TypeAssertion, expr);

	TokenPos pos = ast_token(expr).pos;
	cgValue e = cg_build_expr(p, ta->expr);
	Type *t = type_deref(e.type);

	if (is_type_union(t)) {
		return cg_emit_cast_union(p, e, type, pos);
	} else if (is_type_any(t)) {
		return cg_emit_cast_any(p, e, type, pos);
	}
	GB_PANIC("TODO(bill): type assertion %s", type_to_string(e.type));
	return {};
}


gb_internal cgValue cg_build_expr_internal(cgProcedure *p, Ast *expr) {
	expr = unparen_expr(expr);

	TokenPos expr_pos = ast_token(expr).pos;
	TypeAndValue tv = type_and_value_of_expr(expr);
	Type *type = type_of_expr(expr);
	GB_ASSERT_MSG(tv.mode != Addressing_Invalid, "invalid expression '%s' (tv.mode = %d, tv.type = %s) @ %s\n Current Proc: %.*s : %s", expr_to_string(expr), tv.mode, type_to_string(tv.type), token_pos_to_string(expr_pos), LIT(p->name), type_to_string(p->type));

	if (tv.value.kind != ExactValue_Invalid &&
	    expr->kind != Ast_CompoundLit) {
		// NOTE(bill): The commented out code below is just for debug purposes only
		// if (is_type_untyped(type)) {
		// 	gb_printf_err("%s %s : %s @ %p\n", token_pos_to_string(expr_pos), expr_to_string(expr), type_to_string(expr->tav.type), expr);
		// 	GB_PANIC("%s\n", type_to_string(tv.type));
		// }
		// NOTE(bill): Short on constant values
		return cg_const_value(p, type, tv.value);
	} else if (tv.mode == Addressing_Type) {
		// NOTE(bill, 2023-01-16): is this correct? I hope so at least
		return cg_typeid(p, tv.type);
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
			// TODO(bill): is this correct?
			return cg_value(cast(TB_Node *)nullptr, e->type);
		}
		GB_ASSERT(e->kind != Entity_ProcGroup);

		cgAddr *addr = map_get(&p->variable_map, e);
		if (addr) {
			return cg_addr_load(p, *addr);
		}
		return cg_find_ident(p, e, expr);
	case_end;

	case_ast_node(i, Implicit, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(u, Uninit, expr);
		if (is_type_untyped(type)) {
			return cg_value(cast(TB_Node *)nullptr, t_untyped_uninit);
		}
		return cg_value(tb_inst_poison(p->func, cg_data_type(type)), type);
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

	case_ast_node(cl, CompoundLit, expr);
		cgAddr addr = cg_build_addr_compound_lit(p, expr);
		return cg_addr_load(p, addr);
	case_end;


	case_ast_node(te, TernaryIfExpr, expr);
		cgValue incoming_values[2] = {};
		TB_Node *incoming_regions[2] = {};

		TB_Node *then  = cg_control_region(p, "if_then");
		TB_Node *done  = cg_control_region(p, "if_done");
		TB_Node *else_ = cg_control_region(p, "if_else");

		cg_build_cond(p, te->cond, then, else_);
		tb_inst_set_control(p->func, then);

		Type *type = default_type(type_of_expr(expr));

		incoming_values [0] = cg_emit_conv(p, cg_build_expr(p, te->x), type);
		incoming_regions[0] = tb_inst_get_control(p->func);

		cg_emit_goto(p, done);
		tb_inst_set_control(p->func, else_);

		incoming_values [1] = cg_emit_conv(p, cg_build_expr(p, te->y), type);
		incoming_regions[1] = tb_inst_get_control(p->func);

		cg_emit_goto(p, done);
		tb_inst_set_control(p->func, done);

		GB_ASSERT(incoming_values[0].kind == cgValue_Value ||
		          incoming_values[0].kind == cgValue_Addr);
		GB_ASSERT(incoming_values[0].kind == incoming_values[1].kind);

		cgValue res = {};
		res.kind = incoming_values[0].kind;
		res.type = type;
		TB_DataType dt = cg_data_type(type);
		if (res.kind == cgValue_Addr) {
			dt = TB_TYPE_PTR;
		}
		res.node = tb_inst_incomplete_phi(p->func, dt, done, 2);
		tb_inst_add_phi_operand(p->func, res.node, incoming_regions[0], incoming_values[0].node);
		tb_inst_add_phi_operand(p->func, res.node, incoming_regions[1], incoming_values[1].node);
		return res;
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

	case_ast_node(ie, IndexExpr, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(ie, MatrixIndexExpr, expr);
		return cg_addr_load(p, cg_build_addr(p, expr));
	case_end;

	case_ast_node(ue, UnaryExpr, expr);
		if (ue->op.kind == Token_And) {
			return cg_build_unary_and(p, expr);
		}
		cgValue v = cg_build_expr(p, ue->expr);
		return cg_emit_unary_arith(p, ue->op.kind, v, type);
	case_end;
	case_ast_node(be, BinaryExpr, expr);
		return cg_build_binary_expr(p, expr);
	case_end;

	case_ast_node(oe, OrReturnExpr, expr);
		return cg_build_or_return(p, oe->expr, tv.type);
	case_end;

	case_ast_node(oe, OrElseExpr, expr);
		return cg_build_or_else(p, oe->x, oe->y, tv.type);
	case_end;

	case_ast_node(ta, TypeAssertion, expr);
		return cg_build_type_assertion(p, expr, tv.type);
	case_end;

	case_ast_node(pl, ProcLit, expr);
		cgProcedure *anon = cg_procedure_generate_anonymous(p->module, expr, p);
		GB_ASSERT(anon != nullptr);
		GB_ASSERT(anon->symbol != nullptr);
		return cg_value(tb_inst_get_symbol_address(p->func, anon->symbol), type);
	case_end;

	}
	TokenPos token_pos = ast_token(expr).pos;
	GB_PANIC("Unexpected expression\n"
	         "\tAst: %.*s @ "
	         "%s\n",
	         LIT(ast_strings[expr->kind]),
	         token_pos_to_string(token_pos));

	return {};
}


gb_internal cgValue cg_map_data_uintptr(cgProcedure *p, cgValue value) {
	GB_ASSERT(is_type_map(value.type) || are_types_identical(value.type, t_raw_map));
	cgValue data = cg_emit_struct_ev(p, value, 0);
	u64 mask_value = 0;
	if (build_context.ptr_size == 4) {
		mask_value = 0xfffffffful & ~(MAP_CACHE_LINE_SIZE-1);
	} else {
		mask_value = 0xffffffffffffffffull & ~(MAP_CACHE_LINE_SIZE-1);
	}
	cgValue mask = cg_const_int(p, t_uintptr, mask_value);
	return cg_emit_arith(p, Token_And, data, mask, t_uintptr);
}

gb_internal cgValue cg_gen_map_key_hash(cgProcedure *p, cgValue const &map_ptr, cgValue key, cgValue *key_ptr_) {
	TEMPORARY_ALLOCATOR_GUARD();

	cgValue key_ptr = cg_address_from_load_or_generate_local(p, key);
	key_ptr = cg_emit_conv(p, key_ptr, t_rawptr);

	if (key_ptr_) *key_ptr_ = key_ptr;

	Type* key_type = base_type(type_deref(map_ptr.type))->Map.key;

	cgValue hasher = cg_hasher_proc_value_for_type(p, key_type);

	Slice<cgValue> args = {};
	args = slice_make<cgValue>(temporary_allocator(), 1);
	args[0] = cg_map_data_uintptr(p, cg_emit_load(p, map_ptr));
	cgValue seed = cg_emit_runtime_call(p, "map_seed_from_map_data", args);

	args = slice_make<cgValue>(temporary_allocator(), 2);
	args[0] = key_ptr;
	args[1] = seed;
	return cg_emit_call(p, hasher, args);
}

gb_internal cgValue cg_internal_dynamic_map_get_ptr(cgProcedure *p, cgValue const &map_ptr, cgValue const &key) {
	TEMPORARY_ALLOCATOR_GUARD();

	Type *map_type = base_type(type_deref(map_ptr.type));
	GB_ASSERT(map_type->kind == Type_Map);

	cgValue ptr = {};
	cgValue key_ptr = {};
	cgValue hash = cg_gen_map_key_hash(p, map_ptr, key, &key_ptr);

	auto args = slice_make<cgValue>(temporary_allocator(), 4);
	args[0] = cg_emit_transmute(p, map_ptr, t_raw_map_ptr);
	args[1] = cg_builtin_map_info(p, map_type);
	args[2] = hash;
	args[3] = key_ptr;

	ptr = cg_emit_runtime_call(p, "__dynamic_map_get", args);

	return cg_emit_conv(p, ptr, alloc_type_pointer(map_type->Map.value));
}


gb_internal void cg_internal_dynamic_map_set(cgProcedure *p, cgValue const &map_ptr, Type *map_type,
                                             cgValue const &map_key, cgValue const &map_value, Ast *node) {
	TEMPORARY_ALLOCATOR_GUARD();

	map_type = base_type(map_type);
	GB_ASSERT(map_type->kind == Type_Map);

	cgValue key_ptr = {};
	cgValue hash = cg_gen_map_key_hash(p, map_ptr, map_key, &key_ptr);

	cgValue v = cg_emit_conv(p, map_value, map_type->Map.value);
	cgValue value_ptr = cg_address_from_load_or_generate_local(p, v);

	auto args = slice_make<cgValue>(temporary_allocator(), 6);
	args[0] = cg_emit_conv(p, map_ptr, t_raw_map_ptr);
	args[1] = cg_builtin_map_info(p, map_type);
	args[2] = hash;
	args[3] = cg_emit_conv(p, key_ptr, t_rawptr);
	args[4] = cg_emit_conv(p, value_ptr, t_rawptr);
	args[5] = cg_emit_source_code_location_as_global(p, node);
	cg_emit_runtime_call(p, "__dynamic_map_set", args);
}




gb_internal cgValue cg_build_addr_ptr(cgProcedure *p, Ast *expr) {
	cgAddr addr = cg_build_addr(p, expr);
	return cg_addr_get_ptr(p, addr);
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

gb_internal cgAddr cg_build_addr_index_expr(cgProcedure *p, Ast *expr) {
	ast_node(ie, IndexExpr, expr);

	Type *t = base_type(type_of_expr(ie->expr));

	bool deref = is_type_pointer(t);
	t = base_type(type_deref(t));
	if (is_type_soa_struct(t)) {
		cgValue val = cg_build_addr_ptr(p, ie->expr);
		if (deref) {
			val = cg_emit_load(p, val);
		}

		cgValue index = cg_build_expr(p, ie->index);
		return cg_addr_soa_variable(val, index, ie->index);
	}

	if (ie->expr->tav.mode == Addressing_SoaVariable) {
		GB_PANIC("TODO(bill): #soa");
		// // SOA Structures for slices/dynamic arrays
		// GB_ASSERT(is_type_pointer(type_of_expr(ie->expr)));

		// lbValue field = lb_build_expr(p, ie->expr);
		// lbValue index = lb_build_expr(p, ie->index);


		// if (!build_context.no_bounds_check) {
		// 	// TODO HACK(bill): Clean up this hack to get the length for bounds checking
		// 	// GB_ASSERT(LLVMIsALoadInst(field.value));

		// 	// lbValue a = {};
		// 	// a.value = LLVMGetOperand(field.value, 0);
		// 	// a.type = alloc_type_pointer(field.type);

		// 	// irInstr *b = &a->Instr;
		// 	// GB_ASSERT(b->kind == irInstr_StructElementPtr);
		// 	// lbValue base_struct = b->StructElementPtr.address;

		// 	// GB_ASSERT(is_type_soa_struct(type_deref(ir_type(base_struct))));
		// 	// lbValue len = ir_soa_struct_len(p, base_struct);
		// 	// lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		// }
		// lbValue val = lb_emit_ptr_offset(p, field, index);
		// return lb_addr(val);
	}

	GB_ASSERT_MSG(is_type_indexable(t), "%s %s", type_to_string(t), expr_to_string(expr));

	if (is_type_map(t)) {
		cgAddr map_addr = cg_build_addr(p, ie->expr);
		cgValue key = cg_build_expr(p, ie->index);
		key = cg_emit_conv(p, key, t->Map.key);

		Type *result_type = type_of_expr(expr);
		cgValue map_ptr = cg_addr_get_ptr(p, map_addr);
		if (is_type_pointer(type_deref(map_ptr.type))) {
			map_ptr = cg_emit_load(p, map_ptr);
		}
		return cg_addr_map(map_ptr, key, t, result_type);
	}

	switch (t->kind) {
	case Type_Array: {
		cgValue array = {};
		array = cg_build_addr_ptr(p, ie->expr);
		if (deref) {
			array = cg_emit_load(p, array);
		}
		cgValue index = cg_build_expr(p, ie->index);
		index = cg_emit_conv(p, index, t_int);
		cgValue elem = cg_emit_array_ep(p, array, index);

		auto index_tv = type_and_value_of_expr(ie->index);
		if (index_tv.mode != Addressing_Constant) {
			// cgValue len = cg_const_int(p->module, t_int, t->Array.count);
			// cg_emit_bounds_check(p, ast_token(ie->index), index, len);
		}
		return cg_addr(elem);
	}

	case Type_EnumeratedArray: {
		cgValue array = {};
		array = cg_build_addr_ptr(p, ie->expr);
		if (deref) {
			array = cg_emit_load(p, array);
		}

		Type *index_type = t->EnumeratedArray.index;

		auto index_tv = type_and_value_of_expr(ie->index);

		cgValue index = {};
		if (compare_exact_values(Token_NotEq, *t->EnumeratedArray.min_value, exact_value_i64(0))) {
			if (index_tv.mode == Addressing_Constant) {
				ExactValue idx = exact_value_sub(index_tv.value, *t->EnumeratedArray.min_value);
				index = cg_const_value(p, index_type, idx);
			} else {
				index = cg_emit_arith(p, Token_Sub,
				                      cg_build_expr(p, ie->index),
				                      cg_const_value(p, index_type, *t->EnumeratedArray.min_value),
				                      index_type);
				index = cg_emit_conv(p, index, t_int);
			}
		} else {
			index = cg_emit_conv(p, cg_build_expr(p, ie->index), t_int);
		}

		cgValue elem = cg_emit_array_ep(p, array, index);

		if (index_tv.mode != Addressing_Constant) {
			// cgValue len = cg_const_int(p->module, t_int, t->EnumeratedArray.count);
			// cg_emit_bounds_check(p, ast_token(ie->index), index, len);
		}
		return cg_addr(elem);
	}

	case Type_Slice: {
		cgValue slice = {};
		slice = cg_build_expr(p, ie->expr);
		if (deref) {
			slice = cg_emit_load(p, slice);
		}
		cgValue elem = cg_builtin_raw_data(p, slice);
		cgValue index = cg_emit_conv(p, cg_build_expr(p, ie->index), t_int);
		// cgValue len = cg_builtin_len(p, slice);
		// cg_emit_bounds_check(p, ast_token(ie->index), index, len);
		cgValue v = cg_emit_ptr_offset(p, elem, index);
		v.type = alloc_type_pointer(type_deref(v.type, true));
		return cg_addr(v);
	}

	case Type_MultiPointer: {
		cgValue multi_ptr = {};
		multi_ptr = cg_build_expr(p, ie->expr);
		if (deref) {
			multi_ptr = cg_emit_load(p, multi_ptr);
		}
		cgValue index = cg_build_expr(p, ie->index);
		index = cg_emit_conv(p, index, t_int);

		cgValue v = cg_emit_ptr_offset(p, multi_ptr, index);
		v.type = alloc_type_pointer(type_deref(v.type, true));
		return cg_addr(v);
	}

	case Type_RelativeMultiPointer: {
		cgValue multi_ptr = {};
		multi_ptr = cg_build_expr(p, ie->expr);
		if (deref) {
			multi_ptr = cg_emit_load(p, multi_ptr);
		}
		cgValue index = cg_build_expr(p, ie->index);
		index = cg_emit_conv(p, index, t_int);

		cgValue v = cg_emit_ptr_offset(p, multi_ptr, index);
		v.type = alloc_type_pointer(type_deref(v.type, true));
		return cg_addr(v);
	}

	case Type_DynamicArray: {
		cgValue dynamic_array = {};
		dynamic_array = cg_build_expr(p, ie->expr);
		if (deref) {
			dynamic_array = cg_emit_load(p, dynamic_array);
		}
		cgValue elem = cg_builtin_raw_data(p, dynamic_array);
		cgValue index = cg_emit_conv(p, cg_build_expr(p, ie->index), t_int);
		// cgValue len = cg_dynamic_array_len(p, dynamic_array);
		// cg_emit_bounds_check(p, ast_token(ie->index), index, len);
		cgValue v = cg_emit_ptr_offset(p, elem, index);
		v.type = alloc_type_pointer(type_deref(v.type, true));
		return cg_addr(v);
	}

	case Type_Matrix: {
		GB_PANIC("TODO(bill): matrix");
		// lbValue matrix = {};
		// matrix = lb_build_addr_ptr(p, ie->expr);
		// if (deref) {
		// 	matrix = lb_emit_load(p, matrix);
		// }
		// lbValue index = lb_build_expr(p, ie->index);
		// index = lb_emit_conv(p, index, t_int);
		// lbValue elem = lb_emit_matrix_ep(p, matrix, lb_const_int(p->module, t_int, 0), index);
		// elem = lb_emit_conv(p, elem, alloc_type_pointer(type_of_expr(expr)));

		// auto index_tv = type_and_value_of_expr(ie->index);
		// if (index_tv.mode != Addressing_Constant) {
		// 	lbValue len = lb_const_int(p->module, t_int, t->Matrix.column_count);
		// 	lb_emit_bounds_check(p, ast_token(ie->index), index, len);
		// }
		// return lb_addr(elem);
	}


	case Type_Basic: { // Basic_string
		cgValue str;
		cgValue elem;
		cgValue len;
		cgValue index;

		str = cg_build_expr(p, ie->expr);
		if (deref) {
			str = cg_emit_load(p, str);
		}
		elem = cg_builtin_raw_data(p, str);
		len = cg_builtin_len(p, str);

		index = cg_emit_conv(p, cg_build_expr(p, ie->index), t_int);
		// cg_emit_bounds_check(p, ast_token(ie->index), index, len);

		cgValue v = cg_emit_ptr_offset(p, elem, index);
		v.type = alloc_type_pointer(type_deref(v.type, true));
		return cg_addr(v);
	}
	}
	return {};
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

	case_ast_node(de, DerefExpr, expr);
		Type *t = type_of_expr(de->expr);
		if (is_type_relative_pointer(t)) {
			cgAddr addr = cg_build_addr(p, de->expr);
			addr.relative.deref = true;
			return addr;
		} else if (is_type_soa_pointer(t)) {
			cgValue value = cg_build_expr(p, de->expr);
			cgValue ptr = cg_emit_struct_ev(p, value, 0);
			cgValue idx = cg_emit_struct_ev(p, value, 1);
			return cg_addr_soa_variable(ptr, idx, nullptr);
		}
		cgValue addr = cg_build_expr(p, de->expr);
		return cg_addr(addr);
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return cg_build_addr_index_expr(p, expr);
	case_end;

	case_ast_node(se, SliceExpr, expr);
		return cg_build_addr_slice_expr(p, expr);
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		Ast *sel_node = unparen_expr(se->selector);
		if (sel_node->kind != Ast_Ident) {
			GB_PANIC("Unsupported selector expression");
		}
		String selector = sel_node->Ident.token.string;
		TypeAndValue tav = type_and_value_of_expr(se->expr);

		if (tav.mode == Addressing_Invalid) {
			// NOTE(bill): Imports
			Entity *imp = entity_of_node(se->expr);
			if (imp != nullptr) {
				GB_ASSERT(imp->kind == Entity_ImportName);
			}
			return cg_build_addr(p, unparen_expr(se->selector));
		}


		Type *type = base_type(tav.type);
		if (tav.mode == Addressing_Type) { // Addressing_Type
			Selection sel = lookup_field(tav.type, selector, true);
			if (sel.pseudo_field) {
				GB_ASSERT(sel.entity->kind == Entity_Procedure);
				return cg_addr(cg_find_value_from_entity(p->module, sel.entity));
			}
			GB_PANIC("Unreachable %.*s", LIT(selector));
		}

		if (se->swizzle_count > 0) {
			Type *array_type = base_type(type_deref(tav.type));
			GB_ASSERT(array_type->kind == Type_Array);
			u8 swizzle_count = se->swizzle_count;
			u8 swizzle_indices_raw = se->swizzle_indices;
			u8 swizzle_indices[4] = {};
			for (u8 i = 0; i < swizzle_count; i++) {
				u8 index = swizzle_indices_raw>>(i*2) & 3;
				swizzle_indices[i] = index;
			}
			cgValue a = {};
			if (is_type_pointer(tav.type)) {
				a = cg_build_expr(p, se->expr);
			} else {
				cgAddr addr = cg_build_addr(p, se->expr);
				a = cg_addr_get_ptr(p, addr);
			}

			GB_ASSERT(is_type_array(expr->tav.type));
			GB_PANIC("TODO(bill): cg_addr_swizzle");
			// return cg_addr_swizzle(a, expr->tav.type, swizzle_count, swizzle_indices);
		}

		Selection sel = lookup_field(type, selector, false);
		GB_ASSERT(sel.entity != nullptr);
		if (sel.pseudo_field) {
			GB_ASSERT(sel.entity->kind == Entity_Procedure);
			Entity *e = entity_of_node(sel_node);
			return cg_addr(cg_find_value_from_entity(p->module, e));
		}

		{
			cgAddr addr = cg_build_addr(p, se->expr);
			if (addr.kind == cgAddr_Map) {
				cgValue v = cg_addr_load(p, addr);
				cgValue a = cg_address_from_load_or_generate_local(p, v);
				a = cg_emit_deep_field_gep(p, a, sel);
				return cg_addr(a);
			} else if (addr.kind == cgAddr_Context) {
				GB_ASSERT(sel.index.count > 0);
				if (addr.ctx.sel.index.count >= 0) {
					sel = selection_combine(addr.ctx.sel, sel);
				}
				addr.ctx.sel = sel;
				addr.kind = cgAddr_Context;
				return addr;
			} else if (addr.kind == cgAddr_SoaVariable) {
				cgValue index = addr.soa.index;
				i64 first_index = sel.index[0];
				Selection sub_sel = sel;
				sub_sel.index.data += 1;
				sub_sel.index.count -= 1;

				cgValue arr = cg_emit_struct_ep(p, addr.addr, first_index);

				Type *t = base_type(type_deref(addr.addr.type));
				GB_ASSERT(is_type_soa_struct(t));

				// TODO(bill): bounds checking for soa variable
				// if (addr.soa.index_expr != nullptr && (!cg_is_const(addr.soa.index) || t->Struct.soa_kind != StructSoa_Fixed)) {
				// 	cgValue len = cg_soa_struct_len(p, addr.addr);
				// 	cg_emit_bounds_check(p, ast_token(addr.soa.index_expr), addr.soa.index, len);
				// }

				cgValue item = {};

				if (t->Struct.soa_kind == StructSoa_Fixed) {
					item = cg_emit_array_ep(p, arr, index);
				} else {
					item = cg_emit_ptr_offset(p, cg_emit_load(p, arr), index);
				}
				if (sub_sel.index.count > 0) {
					item = cg_emit_deep_field_gep(p, item, sub_sel);
				}
				item.type = alloc_type_pointer(type_deref(item.type, true));
				return cg_addr(item);
			} else if (addr.kind == cgAddr_Swizzle) {
				GB_ASSERT(sel.index.count > 0);
				// NOTE(bill): just patch the index in place
				sel.index[0] = addr.swizzle.indices[sel.index[0]];
			} else if (addr.kind == cgAddr_SwizzleLarge) {
				GB_ASSERT(sel.index.count > 0);
				// NOTE(bill): just patch the index in place
				sel.index[0] = addr.swizzle.indices[sel.index[0]];
			}

			cgValue a = cg_addr_get_ptr(p, addr);
			a = cg_emit_deep_field_gep(p, a, sel);
			return cg_addr(a);
		}
	case_end;

	case_ast_node(ce, CallExpr, expr);
		cgValue res = cg_build_expr(p, expr);
		switch (res.kind) {
		case cgValue_Value:
			return cg_addr(cg_address_from_load_or_generate_local(p, res));
		case cgValue_Addr:
			return cg_addr(res);
		case cgValue_Multi:
			GB_PANIC("cannot address a multi-valued expression");
			break;
		}
	case_end;

	case_ast_node(cl, CompoundLit, expr);
		return cg_build_addr_compound_lit(p, expr);
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