gb_internal bool cg_is_expr_constant_zero(Ast *expr) {
	GB_ASSERT(expr != nullptr);
	auto v = exact_value_to_integer(expr->tav.value);
	if (v.kind == ExactValue_Integer) {
		return big_int_cmp_zero(&v.value_integer) == 0;
	}
	return false;
}

gb_internal cgValue cg_const_nil(cgModule *m, cgProcedure *p, Type *type) {
	Type *original_type = type;
	type = core_type(type);
	i64 size = type_size_of(type);
	i64 align = type_align_of(type);
	TB_DataType dt = cg_data_type(type);
	if (TB_IS_VOID_TYPE(dt)) {
		char name[32] = {};
		gb_snprintf(name, 31, "cnil$%u", 1+m->const_nil_guid.fetch_add(1));
		TB_Global *global = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, size, align, 0);

		TB_Symbol *symbol = cast(TB_Symbol *)global;
		if (p) {
			TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
			return cg_lvalue_addr(node, type);
		} else {
			GB_PANIC("TODO(bill): cg_const_nil");
		}
	}

	if (is_type_internally_pointer_like(type)) {
		return cg_value(tb_inst_uint(p->func, dt, 0), type);
	} else if (is_type_integer(type) || is_type_boolean(type) || is_type_bit_set(type)) {
		return cg_value(tb_inst_uint(p->func, dt, 0), type);
	} else if (is_type_float(type)) {
		switch (size) {
		case 2:
			return cg_value(tb_inst_uint(p->func, dt, 0), type);
		case 4:
			return cg_value(tb_inst_float32(p->func, 0), type);
		case 8:
			return cg_value(tb_inst_float64(p->func, 0), type);
		}
	}
	GB_PANIC("TODO(bill): cg_const_nil %s", type_to_string(original_type));
	return {};
}

gb_internal cgValue cg_const_nil(cgProcedure *p, Type *type) {
	return cg_const_nil(p->module, p, type);
}

gb_internal cgValue cg_const_value(cgModule *m, cgProcedure *p, Type *type, ExactValue const &value, bool allow_local = true) {
	TB_Node *node = nullptr;

	bool is_local = allow_local && p != nullptr;
	gb_unused(is_local);

	TB_DataType dt = cg_data_type(type);

	switch (value.kind) {
	case ExactValue_Invalid:
		return cg_const_nil(p, type);

	case ExactValue_Typeid:
		return cg_typeid(m, value.value_typeid);

	case ExactValue_Procedure:
		{
			Ast *expr = unparen_expr(value.value_procedure);
			Entity *e = entity_of_node(expr);
			if (e != nullptr) {
				cgValue found = cg_find_procedure_value_from_entity(m, e);
				GB_ASSERT(are_types_identical(type, found.type));
				return found;
			}
			GB_PANIC("TODO(bill): cg_const_value ExactValue_Procedure");
		}
		break;
	}

	GB_ASSERT(!TB_IS_VOID_TYPE(dt));

	switch (value.kind) {
	case ExactValue_Bool:
		return cg_value(tb_inst_uint(p->func, dt, value.value_bool), type);

	case ExactValue_Integer:
		// GB_ASSERT(dt.raw != TB_TYPE_I128.raw);
		if (is_type_unsigned(type)) {
			u64 i = exact_value_to_u64(value);
			return cg_value(tb_inst_uint(p->func, dt, i), type);
		} else {
			i64 i = exact_value_to_i64(value);
			return cg_value(tb_inst_sint(p->func, dt, i), type);
		}
		break;

	case ExactValue_Float:
		GB_ASSERT(dt.raw != TB_TYPE_F16.raw);
		GB_ASSERT(!is_type_different_to_arch_endianness(type));
		{
			f64 f = exact_value_to_f64(value);
			if (type_size_of(type) == 8) {
				return cg_value(tb_inst_float64(p->func, f), type);
			} else {
				return cg_value(tb_inst_float32(p->func, cast(f32)f), type);
			}
		}
		break;
	}


	GB_ASSERT(node != nullptr);
	return cg_value(node, type);
}

gb_internal cgValue cg_const_value(cgProcedure *p, Type *type, ExactValue const &value) {
	GB_ASSERT(p != nullptr);
	return cg_const_value(p->module, p, type, value);
}

gb_internal cgValue cg_const_int(cgProcedure *p, Type *type, i64 i) {
	return cg_const_value(p, type, exact_value_i64(i));
}
