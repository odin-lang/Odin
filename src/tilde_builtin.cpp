gb_internal cgValue cg_builtin_len(cgProcedure *p, cgValue value) {
	Type *t = base_type(value.type);

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
			{
				GB_ASSERT(value.kind == cgValue_Addr);
				cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
				cgValue len_ptr = cg_emit_struct_ep(p, ptr, 1);
				return cg_emit_load(p, len_ptr);
			}
		case Basic_cstring:
			GB_PANIC("TODO(bill): len(cstring)");
			break;
		}
		break;
	case Type_Array:
		return cg_const_int(p, t_int, t->Array.count);
	case Type_EnumeratedArray:
		return cg_const_int(p, t_int, t->EnumeratedArray.count);
	case Type_Slice:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue len_ptr = cg_emit_struct_ep(p, ptr, 1);
			return cg_emit_load(p, len_ptr);
		}
	case Type_DynamicArray:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue len_ptr = cg_emit_struct_ep(p, ptr, 1);
			return cg_emit_load(p, len_ptr);
		}
	case Type_Map:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue len_ptr = cg_emit_struct_ep(p, ptr, 1);
			return cg_emit_conv(p, cg_emit_load(p, len_ptr), t_int);
		}
	case Type_Struct:
		GB_ASSERT(is_type_soa_struct(t));
		break;
	case Type_RelativeSlice:
		break;
	}

	GB_PANIC("TODO(bill): cg_builtin_len %s", type_to_string(t));
	return {};
}

gb_internal cgValue cg_builtin_cap(cgProcedure *p, cgValue value) {
	Type *t = base_type(value.type);

	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_string:
			{
				GB_ASSERT(value.kind == cgValue_Addr);
				cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
				cgValue len_ptr = cg_emit_struct_ep(p, ptr, 1);
				return cg_emit_load(p, len_ptr);
			}
		case Basic_cstring:
			GB_PANIC("TODO(bill): cap(cstring)");
			break;
		}
		break;
	case Type_Array:
		return cg_const_int(p, t_int, t->Array.count);
	case Type_EnumeratedArray:
		return cg_const_int(p, t_int, t->EnumeratedArray.count);
	case Type_Slice:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue len_ptr = cg_emit_struct_ep(p, ptr, 1);
			return cg_emit_load(p, len_ptr);
		}
	case Type_DynamicArray:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue len_ptr = cg_emit_struct_ep(p, ptr, 2);
			return cg_emit_load(p, len_ptr);
		}
	case Type_Map:
		{
			TB_DataType dt_uintptr = cg_data_type(t_uintptr);
			TB_Node *zero = tb_inst_uint(p->func, dt_uintptr, 0);
			TB_Node *one  = tb_inst_uint(p->func, dt_uintptr, 0);
			TB_Node *mask = tb_inst_uint(p->func, dt_uintptr, MAP_CACHE_LINE_SIZE-1);

			TB_Node *data = cg_emit_struct_ev(p, value, 0).node;
			TB_Node *log2_cap = tb_inst_and(p->func, data, mask);
			TB_Node *cap = tb_inst_shl(p->func, one, log2_cap, cast(TB_ArithmeticBehavior)0);
			TB_Node *cmp = tb_inst_cmp_eq(p->func, data, zero);

			cgValue res = cg_value(tb_inst_select(p->func, cmp, zero, cap), t_uintptr);
			return cg_emit_conv(p, res, t_int);
		}
	case Type_Struct:
		GB_ASSERT(is_type_soa_struct(t));
		break;
	case Type_RelativeSlice:
		break;
	}

	GB_PANIC("TODO(bill): cg_builtin_cap %s", type_to_string(t));
	return {};
}


gb_internal cgValue cg_builtin_raw_data(cgProcedure *p, cgValue const &value) {
	Type *t = base_type(value.type);
	cgValue res = {};
	switch (t->kind) {
	case Type_Slice:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue data_ptr = cg_emit_struct_ep(p, ptr, 0);
			res = cg_emit_load(p, data_ptr);
			GB_ASSERT(is_type_multi_pointer(res.type));
		}
		break;
	case Type_DynamicArray:
		{
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue data_ptr = cg_emit_struct_ep(p, ptr, 0);
			res = cg_emit_load(p, data_ptr);
		}
		break;
	case Type_Basic:
		if (t->Basic.kind == Basic_string) {
			GB_ASSERT(value.kind == cgValue_Addr);
			cgValue ptr = cg_value(value.node, alloc_type_pointer(value.type));
			cgValue data_ptr = cg_emit_struct_ep(p, ptr, 0);
			res = cg_emit_load(p, data_ptr);
		} else if (t->Basic.kind == Basic_cstring) {
			res = cg_emit_conv(p, value, t_u8_multi_ptr);
		}
		break;
	case Type_Pointer:
		GB_ASSERT(is_type_array_like(t->Pointer.elem));
		GB_ASSERT(value.kind == cgValue_Value);
		res = cg_value(value.node, alloc_type_multi_pointer(base_array_type(t->Pointer.elem)));
		break;
	case Type_MultiPointer:

		GB_PANIC("TODO(bill) %s", type_to_string(value.type));
		// res = cg_emit_conv(p, value, tv.type);
		break;
	}
	GB_ASSERT(res.node != nullptr);
	return res;
}

gb_internal cgValue cg_builtin_min(cgProcedure *p, Type *t, cgValue x, cgValue y) {
	x = cg_emit_conv(p, x, t);
	y = cg_emit_conv(p, y, t);
	return cg_emit_select(p, cg_emit_comp(p, Token_Lt, x, y), x, y);
}
gb_internal cgValue cg_builtin_max(cgProcedure *p, Type *t, cgValue x, cgValue y) {
	x = cg_emit_conv(p, x, t);
	y = cg_emit_conv(p, y, t);
	return cg_emit_select(p, cg_emit_comp(p, Token_Gt, x, y), x, y);
}

gb_internal cgValue cg_builtin_abs(cgProcedure *p, cgValue const &x) {
	if (is_type_unsigned(x.type)) {
		return x;
	}

	if (is_type_quaternion(x.type)) {
		GB_PANIC("TODO(bill): abs quaternion");
	} else if (is_type_complex(x.type)) {
		GB_PANIC("TODO(bill): abs complex");
	}

	TB_DataType dt = cg_data_type(x.type);
	GB_ASSERT(!TB_IS_VOID_TYPE(dt));
	TB_Node *zero = nullptr;
	if (dt.type == TB_FLOAT) {
		if (dt.data == 32) {
			zero = tb_inst_float32(p->func, 0);
		} else if (dt.data == 64) {
			zero = tb_inst_float64(p->func, 0);
		}
	} else {
		zero = tb_inst_uint(p->func, dt, 0);
	}
	GB_ASSERT(zero != nullptr);

	cgValue cond = cg_emit_comp(p, Token_Lt, x, cg_value(zero, x.type));
	cgValue neg = cg_emit_unary_arith(p, Token_Sub, x, x.type);
	return cg_emit_select(p, cond, neg, x);
}

gb_internal cgValue cg_builtin_clamp(cgProcedure *p, Type *t, cgValue const &x, cgValue const &min, cgValue const &max) {
	cgValue z = x;
	z = cg_builtin_max(p, t, z, min);
	z = cg_builtin_min(p, t, z, max);
	return z;
}



gb_internal cgValue cg_builtin_mem_zero(cgProcedure *p, cgValue const &ptr, cgValue const &len) {
	GB_ASSERT(ptr.kind == cgValue_Value);
	GB_ASSERT(len.kind == cgValue_Value);
	tb_inst_memzero(p->func, ptr.node, len.node, 1, false);
	return ptr;
}

gb_internal cgValue cg_builtin_mem_copy(cgProcedure *p, cgValue const &dst, cgValue const &src, cgValue const &len) {
	GB_ASSERT(dst.kind == cgValue_Value);
	GB_ASSERT(src.kind == cgValue_Value);
	GB_ASSERT(len.kind == cgValue_Value);
	// TODO(bill): This needs to be memmove
	tb_inst_memcpy(p->func, dst.node, src.node, len.node, 1, false);
	return dst;
}

gb_internal cgValue cg_builtin_mem_copy_non_overlapping(cgProcedure *p, cgValue const &dst, cgValue const &src, cgValue const &len) {
	GB_ASSERT(dst.kind == cgValue_Value);
	GB_ASSERT(src.kind == cgValue_Value);
	GB_ASSERT(len.kind == cgValue_Value);
	tb_inst_memcpy(p->func, dst.node, src.node, len.node, 1, false);
	return dst;
}



gb_internal cgValue cg_build_builtin(cgProcedure *p, BuiltinProcId id, Ast *expr) {
	ast_node(ce, CallExpr, expr);

	if (BuiltinProc__simd_begin < id && id < BuiltinProc__simd_end) {
		GB_PANIC("TODO(bill): cg_build_builtin_simd_proc");
		// return cg_build_builtin_simd_proc(p, expr, tv, id);
	}

	String builtin_name = builtin_procs[id].name;

	switch (id) {
	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name.string;
		GB_ASSERT(name == "location");
		String procedure = p->entity->token.string;
		TokenPos pos = ast_token(ce->proc).pos;
		if (ce->args.count > 0) {
			Ast *ident = unselector_expr(ce->args[0]);
			GB_ASSERT(ident->kind == Ast_Ident);
			Entity *e = entity_of_node(ident);
			GB_ASSERT(e != nullptr);

			if (e->parent_proc_decl != nullptr && e->parent_proc_decl->entity != nullptr) {
				procedure = e->parent_proc_decl->entity->token.string;
			} else {
				procedure = str_lit("");
			}
			pos = e->token.pos;

		}
		GB_PANIC("TODO(bill): cg_emit_source_code_location_as_global");
		// return cg_emit_source_code_location_as_global(p, procedure, pos);
	} break;

	case BuiltinProc_len: {
		cgValue v = cg_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = cg_emit_load(p, v);
			t = type_deref(t);
		}
		return cg_builtin_len(p, v);
	}

	case BuiltinProc_cap: {
		cgValue v = cg_build_expr(p, ce->args[0]);
		Type *t = base_type(v.type);
		if (is_type_pointer(t)) {
			// IMPORTANT TODO(bill): Should there be a nil pointer check?
			v = cg_emit_load(p, v);
			t = type_deref(t);
		}
		return cg_builtin_cap(p, v);
	}

	case BuiltinProc_raw_data:
		{
			cgValue v = cg_build_expr(p, ce->args[0]);
			return cg_builtin_raw_data(p, v);
		}

	case BuiltinProc_min:
		if (ce->args.count == 2) {
			Type *t = type_of_expr(expr);
			cgValue x = cg_build_expr(p, ce->args[0]);
			cgValue y = cg_build_expr(p, ce->args[1]);
			return cg_builtin_min(p, t, x, y);
		} else {
			Type *t = type_of_expr(expr);
			cgValue x = cg_build_expr(p, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				cgValue y = cg_build_expr(p, ce->args[i]);
				x = cg_builtin_min(p, t, x, y);
			}
			return x;
		}
		break;
	case BuiltinProc_max:
		if (ce->args.count == 2) {
			Type *t = type_of_expr(expr);
			cgValue x = cg_build_expr(p, ce->args[0]);
			cgValue y = cg_build_expr(p, ce->args[1]);
			return cg_builtin_max(p, t, x, y);
		} else {
			Type *t = type_of_expr(expr);
			cgValue x = cg_build_expr(p, ce->args[0]);
			for (isize i = 1; i < ce->args.count; i++) {
				cgValue y = cg_build_expr(p, ce->args[i]);
				x = cg_builtin_max(p, t, x, y);
			}
			return x;
		}
		break;

	case BuiltinProc_abs:
		{
			cgValue x = cg_build_expr(p, ce->args[0]);
			return cg_builtin_abs(p, x);
		}

	case BuiltinProc_clamp:
		{
			cgValue x   = cg_build_expr(p, ce->args[0]);
			cgValue min = cg_build_expr(p, ce->args[1]);
			cgValue max = cg_build_expr(p, ce->args[2]);
			return cg_builtin_clamp(p, type_of_expr(expr), x, min, max);
		}

	case BuiltinProc_debug_trap:
		tb_inst_debugbreak(p->func);
		return {};
	case BuiltinProc_trap:
		tb_inst_trap(p->func);
		return {};

	case BuiltinProc_mem_zero:
		{
			cgValue ptr = cg_build_expr(p, ce->args[0]);
			cgValue len = cg_build_expr(p, ce->args[1]);
			return cg_builtin_mem_zero(p, ptr, len);
		}

	case BuiltinProc_mem_copy:
		{
			cgValue dst = cg_build_expr(p, ce->args[0]);
			cgValue src = cg_build_expr(p, ce->args[1]);
			cgValue len = cg_build_expr(p, ce->args[2]);
			return cg_builtin_mem_copy(p, dst, src, len);
		}

	case BuiltinProc_mem_copy_non_overlapping:
		{
			cgValue dst = cg_build_expr(p, ce->args[0]);
			cgValue src = cg_build_expr(p, ce->args[1]);
			cgValue len = cg_build_expr(p, ce->args[2]);
			return cg_builtin_mem_copy_non_overlapping(p, dst, src, len);
		}


	case BuiltinProc_overflow_add:
		{
			Type *res_type = type_of_expr(expr);
			GB_ASSERT(res_type->kind == Type_Tuple);
			GB_ASSERT(res_type->Tuple.variables.count == 2);
			// TODO(bill): do a proper overflow add
			Type *type = res_type->Tuple.variables[0]->type;
			Type *ok_type = res_type->Tuple.variables[1]->type;
			cgValue x = cg_build_expr(p, ce->args[0]);
			cgValue y = cg_build_expr(p, ce->args[1]);
			x = cg_emit_conv(p, x, type);
			y = cg_emit_conv(p, y, type);
			cgValue res = cg_emit_arith(p, Token_Add, x, y, type);
			cgValue ok  = cg_const_int(p, ok_type, false);

			return cg_value_multi2(res, ok, res_type);
		}


	case BuiltinProc_ptr_offset:
		{
			cgValue ptr = cg_build_expr(p, ce->args[0]);
			cgValue len = cg_build_expr(p, ce->args[1]);
			len = cg_emit_conv(p, len, t_int);
			return cg_emit_ptr_offset(p, ptr, len);
		}
	case BuiltinProc_ptr_sub:
		{
			Type *elem0 = type_deref(type_of_expr(ce->args[0]));
			Type *elem1 = type_deref(type_of_expr(ce->args[1]));
			GB_ASSERT(are_types_identical(elem0, elem1));
			Type *elem = elem0;

			cgValue ptr0 = cg_emit_conv(p, cg_build_expr(p, ce->args[0]), t_uintptr);
			cgValue ptr1 = cg_emit_conv(p, cg_build_expr(p, ce->args[1]), t_uintptr);

			cgValue diff = cg_emit_arith(p, Token_Sub, ptr0, ptr1, t_uintptr);
			diff = cg_emit_conv(p, diff, t_int);
			return cg_emit_arith(p, Token_Quo, diff, cg_const_int(p, t_int, type_size_of(elem)), t_int);
		}

	}


	GB_PANIC("TODO(bill): builtin procs %d %.*s", id, LIT(builtin_name));
	return {};
}

