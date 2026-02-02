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
		{
			if (t->Struct.soa_kind == StructSoa_Fixed) {
				return cg_const_int(p, t_int, t->Struct.soa_count);
			}

			GB_ASSERT(t->Struct.soa_kind == StructSoa_Slice ||
			          t->Struct.soa_kind == StructSoa_Dynamic);

			isize n = 0;
			Type *elem = base_type(t->Struct.soa_elem);
			if (elem->kind == Type_Struct) {
				n = cast(isize)elem->Struct.fields.count;
			} else if (elem->kind == Type_Array) {
				n = cast(isize)elem->Array.count;
			} else {
				GB_PANIC("Unreachable");
			}

			return cg_emit_struct_ev(p, value, n);
		}
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
	tb_inst_memzero(p->func, ptr.node, len.node, 1);
	return ptr;
}

gb_internal cgValue cg_builtin_mem_copy(cgProcedure *p, cgValue const &dst, cgValue const &src, cgValue const &len) {
	GB_ASSERT(dst.kind == cgValue_Value);
	GB_ASSERT(src.kind == cgValue_Value);
	GB_ASSERT(len.kind == cgValue_Value);
	// TODO(bill): This needs to be memmove
	tb_inst_memcpy(p->func, dst.node, src.node, len.node, 1);
	return dst;
}

gb_internal cgValue cg_builtin_mem_copy_non_overlapping(cgProcedure *p, cgValue const &dst, cgValue const &src, cgValue const &len) {
	GB_ASSERT(dst.kind == cgValue_Value);
	GB_ASSERT(src.kind == cgValue_Value);
	GB_ASSERT(len.kind == cgValue_Value);
	tb_inst_memcpy(p->func, dst.node, src.node, len.node, 1);
	return dst;
}

gb_internal TB_Symbol *cg_builtin_map_cell_info_symbol(cgModule *m, Type *type) {
	MUTEX_GUARD(&m->map_info_mutex);
	TB_Symbol **found = map_get(&m->map_cell_info_map, type);
	if (found) {
		return *found;
	}
	i64 size = 0, len = 0;
	map_cell_size_and_len(type, &size, &len);

	TB_Global *global = tb_global_create(m->mod, 0, "", cg_debug_type(m, t_map_cell_info), TB_LINKAGE_PRIVATE);
	tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, type_size_of(t_map_cell_info), type_align_of(t_map_cell_info), 4);

	i64 ptr_size = build_context.ptr_size;
	void *size_of_type      = tb_global_add_region(m->mod, global, 0*ptr_size, ptr_size);
	void *align_of_type     = tb_global_add_region(m->mod, global, 1*ptr_size, ptr_size);
	void *size_of_cell      = tb_global_add_region(m->mod, global, 2*ptr_size, ptr_size);
	void *elements_per_cell = tb_global_add_region(m->mod, global, 3*ptr_size, ptr_size);

	cg_write_uint_at_ptr(size_of_type,      type_size_of(type),  t_uintptr);
	cg_write_uint_at_ptr(align_of_type,     type_align_of(type), t_uintptr);
	cg_write_uint_at_ptr(size_of_cell,      size,                t_uintptr);
	cg_write_uint_at_ptr(elements_per_cell, len,                 t_uintptr);

	map_set(&m->map_cell_info_map, type, cast(TB_Symbol *)global);

	return cast(TB_Symbol *)global;
}


gb_internal cgValue cg_builtin_map_cell_info(cgProcedure *p, Type *type) {
	type = core_type(type);
	TB_Symbol *symbol = cg_builtin_map_cell_info_symbol(p->module, type);
	TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
	return cg_value(node, t_map_cell_info_ptr);
}

gb_internal cgValue cg_builtin_map_info(cgProcedure *p, Type *map_type) {
	map_type = base_type(map_type);
	GB_ASSERT(map_type->kind == Type_Map);

	cgModule *m = p->module;
	MUTEX_GUARD(&m->map_info_mutex);
	TB_Global *global = nullptr;
	TB_Symbol **found = map_get(&m->map_info_map, map_type);
	if (found) {
		global = cast(TB_Global *)*found;
	} else {
		global = tb_global_create(m->mod, 0, "", cg_debug_type(m, t_map_info), TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, type_size_of(t_map_info), type_align_of(t_map_info), 4);

		TB_Symbol *key_cell_info   = cg_builtin_map_cell_info_symbol(m, map_type->Map.key);
		TB_Symbol *value_cell_info = cg_builtin_map_cell_info_symbol(m, map_type->Map.value);
		cgProcedure *key_hasher    = cg_hasher_proc_for_type(p->module, map_type->Map.key);
		cgProcedure *key_equal     = cg_equal_proc_for_type (p->module, map_type->Map.key);

		tb_global_add_symbol_reloc(p->module->mod, global, 0*build_context.ptr_size, key_cell_info);
		tb_global_add_symbol_reloc(p->module->mod, global, 1*build_context.ptr_size, value_cell_info);
		tb_global_add_symbol_reloc(p->module->mod, global, 2*build_context.ptr_size, key_hasher->symbol);
		tb_global_add_symbol_reloc(p->module->mod, global, 3*build_context.ptr_size, key_equal->symbol);

		map_set(&m->map_info_map, map_type, cast(TB_Symbol *)global);
	}

	GB_ASSERT(global != nullptr);
	TB_Node *node = tb_inst_get_symbol_address(p->func, cast(TB_Symbol *)global);
	return cg_value(node, t_map_info_ptr);
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

			DeclInfo *ppd = e->parent_proc_decl.load(std::memory_order_relaxed);
			if (ppd != nullptr && ppd->entity != nullptr) {
				procedure = ppd->entity->token.string;
			} else {
				procedure = str_lit("");
			}
			pos = e->token.pos;

		}
		return cg_emit_source_code_location_as_global(p, procedure, pos);
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

	case BuiltinProc_type_info_of:
		{
			Ast *arg = ce->args[0];
			TypeAndValue tav = type_and_value_of_expr(arg);
			if (tav.mode == Addressing_Type) {
				Type *t = default_type(type_of_expr(arg));
				return cg_type_info(p, t);
			}
			GB_ASSERT(is_type_typeid(tav.type));

			auto args = slice_make<cgValue>(permanent_allocator(), 1);
			args[0] = cg_build_expr(p, arg);
			return cg_emit_runtime_call(p, "__type_info_of", args);
		}


	case BuiltinProc_type_equal_proc:
		return cg_equal_proc_value_for_type(p, ce->args[0]->tav.type);

	case BuiltinProc_type_hasher_proc:
		return cg_hasher_proc_value_for_type(p, ce->args[0]->tav.type);

	case BuiltinProc_type_map_cell_info:
		return cg_builtin_map_cell_info(p, ce->args[0]->tav.type);
	case BuiltinProc_type_map_info:
		return cg_builtin_map_info(p, ce->args[0]->tav.type);

	case BuiltinProc_expect:
		{
			Type *t = default_type(expr->tav.type);
			cgValue x = cg_emit_conv(p, cg_build_expr(p, ce->args[0]), t);
			cgValue y = cg_emit_conv(p, cg_build_expr(p, ce->args[1]), t);
			gb_unused(y);
			return x;
		}

	case BuiltinProc_count_leading_zeros:
		{
			cgValue n = cg_build_expr(p, ce->args[0]);
			n = cg_emit_conv(p, n, default_type(expr->tav.type));
			GB_ASSERT(n.kind == cgValue_Value);
			TB_Node *val = tb_inst_clz(p->func, n.node);
			val = tb_inst_zxt(p->func, val, cg_data_type(n.type));
			return cg_value(val, n.type);
		}


	case BuiltinProc_count_trailing_zeros:
		{
			cgValue n = cg_build_expr(p, ce->args[0]);
			n = cg_emit_conv(p, n, default_type(expr->tav.type));
			GB_ASSERT(n.kind == cgValue_Value);
			TB_Node *val = tb_inst_ctz(p->func, n.node);
			val = tb_inst_zxt(p->func, val, cg_data_type(n.type));
			return cg_value(val, n.type);
		}

	case BuiltinProc_count_ones:
		{
			cgValue n = cg_build_expr(p, ce->args[0]);
			n = cg_emit_conv(p, n, default_type(expr->tav.type));
			GB_ASSERT(n.kind == cgValue_Value);
			TB_Node *val = tb_inst_popcount(p->func, n.node);
			val = tb_inst_zxt(p->func, val, cg_data_type(n.type));
			return cg_value(val, n.type);
		}

	case BuiltinProc_count_zeros:
		{
			cgValue n = cg_build_expr(p, ce->args[0]);
			n = cg_emit_conv(p, n, default_type(expr->tav.type));
			GB_ASSERT(n.kind == cgValue_Value);
			TB_DataType dt = cg_data_type(n.type);
			TB_Node *ones = tb_inst_popcount(p->func, n.node);
			ones = tb_inst_zxt(p->func, ones, dt);

			cgValue size = cg_const_int(p, n.type, 8*type_size_of(n.type));
			return cg_emit_arith(p, Token_Sub, size, cg_value(ones, n.type), n.type);
		}

	}


	GB_PANIC("TODO(bill): builtin procs %d %.*s", id, LIT(builtin_name));
	return {};
}

