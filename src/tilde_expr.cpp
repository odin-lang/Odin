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

gb_internal cgValue cg_typeid(cgProcedure *p, Type *t) {
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

	value.node = tb_inst_bswap(p->func, value.node);
	return cg_emit_transmute(p, value, end_type);
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
		GB_PANIC("TODO(bill): cg_compare_records");
		// return cg_compare_records(p, op_kind, left, right, a);
	}

	if ((is_type_struct(b) || is_type_union(b)) && is_type_comparable(b)) {
		GB_PANIC("TODO(bill): cg_compare_records");
		// return cg_compare_records(p, op_kind, left, right, b);
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

		GB_PANIC("TODO(bill): cg_emit_runtime_call");
		// auto args = array_make<lbValue>(permanent_allocator(), 2);
		// args[0] = left;
		// args[1] = right;
		// return cg_emit_runtime_call(p, runtime_procedure, args);
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
		case Token_LtEq:  res = tb_inst_cmp_ige(p->func, lhs, rhs, is_signed); break;
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
		case Token_LtEq:  res = tb_inst_cmp_fge(p->func, lhs, rhs); break;
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
				GB_PANIC("TODO(bill): cg_emit_struct_ev");
				// // TODO(bill): is this correct behaviour for nil comparison for any?
				// cgValue data = cg_emit_struct_ev(p, x, 0);
				// cgValue ti   = cg_emit_struct_ev(p, x, 1);
				// if (op_kind == Token_CmpEq) {
				// 	LLVMValueRef a =  LLVMBuildIsNull(p->builder, data.value, "");
				// 	LLVMValueRef b =  LLVMBuildIsNull(p->builder, ti.value, "");
				// 	res.value = LLVMBuildOr(p->builder, a, b, "");
				// 	return res;
				// } else if (op_kind == Token_NotEq) {
				// 	LLVMValueRef a =  LLVMBuildIsNotNull(p->builder, data.value, "");
				// 	LLVMValueRef b =  LLVMBuildIsNotNull(p->builder, ti.value, "");
				// 	res.value = LLVMBuildAnd(p->builder, a, b, "");
				// 	return res;
				// }
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
		{
			GB_PANIC("TODO(bill): cg_emit_struct_ev");
			// cgValue data = cg_emit_struct_ev(p, x, 0);
			// if (op_kind == Token_CmpEq) {
			// 	res.value = LLVMBuildIsNull(p->builder, data.value, "");
			// 	return res;
			// } else if (op_kind == Token_NotEq) {
			// 	res.value = LLVMBuildIsNotNull(p->builder, data.value, "");
			// 	return res;
			// }
		}
		break;

	case Type_DynamicArray:
		{
			GB_PANIC("TODO(bill): cg_emit_struct_ev");
			// cgValue data = cg_emit_struct_ev(p, x, 0);
			// if (op_kind == Token_CmpEq) {
			// 	res.value = LLVMBuildIsNull(p->builder, data.value, "");
			// 	return res;
			// } else if (op_kind == Token_NotEq) {
			// 	res.value = LLVMBuildIsNotNull(p->builder, data.value, "");
			// 	return res;
			// }
		}
		break;

	case Type_Map:
		{
			GB_PANIC("TODO(bill): cg_emit_struct_ev");
			// cgValue data_ptr = cg_emit_struct_ev(p, x, 0);

			// if (op_kind == Token_CmpEq) {
			// 	res.value = LLVMBuildIsNull(p->builder, data_ptr.value, "");
			// 	return res;
			// } else {
			// 	res.value = LLVMBuildIsNotNull(p->builder, data_ptr.value, "");
			// 	return res;
			// }
		}
		break;

	case Type_Union:
		{
			GB_PANIC("TODO(bill): cg_emit_struct_ev");
			// if (type_size_of(t) == 0) {
			// 	if (op_kind == Token_CmpEq) {
			// 		return cg_const_bool(p->module, t_bool, true);
			// 	} else if (op_kind == Token_NotEq) {
			// 		return cg_const_bool(p->module, t_bool, false);
			// 	}
			// } else if (is_type_union_maybe_pointer(t)) {
			// 	cgValue tag = cg_emit_transmute(p, x, t_rawptr);
			// 	return cg_emit_comp_against_nil(p, op_kind, tag);
			// } else {
			// 	cgValue tag = cg_emit_union_tag_value(p, x);
			// 	return cg_emit_comp(p, op_kind, tag, cg_zero(p->module, tag.type));
			// }
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
		GB_PANIC("TODO(bill): cstring_to_string call");
		// TEMPORARY_ALLOCATOR_GUARD();
		// lbValue c = lb_emit_conv(p, value, t_cstring);
		// auto args = array_make<lbValue>(temporary_allocator(), 1);
		// args[0] = c;
		// lbValue s = lb_emit_runtime_call(p, "cstring_to_string", args);
		// return lb_emit_conv(p, s, dst);
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
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
	}
	if (is_type_multi_pointer(src) && is_type_pointer(dst)) {
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
	}
	if (is_type_pointer(src) && is_type_multi_pointer(dst)) {
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
	}
	if (is_type_multi_pointer(src) && is_type_multi_pointer(dst)) {
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
	}

	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
	}

	// pointer -> proc
	if (is_type_pointer(src) && is_type_proc(dst)) {
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
	}
	// proc -> pointer
	if (is_type_proc(src) && is_type_pointer(dst)) {
		return cg_value(tb_inst_bitcast(p->func, value.node, dt), t);
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
		GB_PANIC("TODO(bill): ? -> any");
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
		GB_PANIC("TODO(bill): comparisons");
		// if (is_type_untyped_nil(be->right->tav.type)) {
		// 	// `x == nil` or `x != nil`
		// 	cgValue left = cg_build_expr(p, be->left);
		// 	cgValue cmp = cg_emit_comp_against_nil(p, be->op.kind, left);
		// 	Type *type = default_type(tv.type);
		// 	return cg_emit_conv(p, cmp, type);
		// } else if (is_type_untyped_nil(be->left->tav.type)) {
		// 	// `nil == x` or `nil != x`
		// 	cgValue right = cg_build_expr(p, be->right);
		// 	cgValue cmp = cg_emit_comp_against_nil(p, be->op.kind, right);
		// 	Type *type = default_type(tv.type);
		// 	return cg_emit_conv(p, cmp, type);
		// } else if (cg_is_empty_string_constant(be->right)) {
		// 	// `x == ""` or `x != ""`
		// 	cgValue s = cg_build_expr(p, be->left);
		// 	s = cg_emit_conv(p, s, t_string);
		// 	cgValue len = cg_string_len(p, s);
		// 	cgValue cmp = cg_emit_comp(p, be->op.kind, len, cg_const_int(p->module, t_int, 0));
		// 	Type *type = default_type(tv.type);
		// 	return cg_emit_conv(p, cmp, type);
		// } else if (cg_is_empty_string_constant(be->left)) {
		// 	// `"" == x` or `"" != x`
		// 	cgValue s = cg_build_expr(p, be->right);
		// 	s = cg_emit_conv(p, s, t_string);
		// 	cgValue len = cg_string_len(p, s);
		// 	cgValue cmp = cg_emit_comp(p, be->op.kind, len, cg_const_int(p->module, t_int, 0));
		// 	Type *type = default_type(tv.type);
		// 	return cg_emit_conv(p, cmp, type);
		// }
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
		GB_PANIC("TODO(bill): cg_emit_logical_binary_expr");
		// return cg_emit_logical_binary_expr(p, be->op.kind, be->left, be->right, tv.type);

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
					GB_PANIC("TODO(bill): in/not_in for maps");
					// cgValue map_ptr = cg_address_from_load_or_generate_local(p, right);
					// cgValue key = left;
					// cgValue ptr = cg_internal_dynamic_map_get_ptr(p, map_ptr, key);
					// if (be->op.kind == Token_in) {
					// 	return cg_emit_conv(p, cg_emit_comp_against_nil(p, Token_NotEq, ptr), t_bool);
					// } else {
					// 	return cg_emit_conv(p, cg_emit_comp_against_nil(p, Token_CmpEq, ptr), t_bool);
					// }
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

	GB_ASSERT(v.kind == cgValue_Value);
	tb_inst_if(p->func, v.node, true_block, false_block);

	return v;
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
			GB_PANIC("TODO(bill): cg_build_unary_and");
			// return cg_build_unary_and(p, expr);
		}
		cgValue v = cg_build_expr(p, ue->expr);
		return cg_emit_unary_arith(p, ue->op.kind, v, type);
	case_end;
	case_ast_node(be, BinaryExpr, expr);
		return cg_build_binary_expr(p, expr);
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

	}

	TokenPos token_pos = ast_token(expr).pos;
	GB_PANIC("Unexpected address expression\n"
	         "\tAst: %.*s @ "
	         "%s\n",
	         LIT(ast_strings[expr->kind]),
	         token_pos_to_string(token_pos));


	return {};
}