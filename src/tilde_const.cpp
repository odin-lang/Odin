gb_internal cgValue cg_const_nil(cgProcedure *p, Type *type) {
	Type *original_type = type;
	type = core_type(type);
	i64 size = type_size_of(type);
	i64 align = type_align_of(type);
	TB_DataType dt = cg_data_type(type);
	if (TB_IS_VOID_TYPE(dt)) {
		TB_Module *m = p->module->mod;
		char name[32] = {};
		gb_snprintf(name, 31, "cnil$%u", 1+p->module->const_nil_guid.fetch_add(1));
		TB_Global *global = tb_global_create(m, name, nullptr, TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m, tb_module_get_rdata(m), global, size, align, 0);

		TB_Symbol *symbol = cast(TB_Symbol *)global;
		TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
		return cg_lvalue_addr(node, type);
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

gb_internal cgValue cg_const_value(cgModule *m, cgProcedure *p, Type *type, ExactValue const &value) {
	TB_Node *node = nullptr;

	if (value.kind == ExactValue_Invalid) {
		return cg_const_nil(p, type);
	}

	return cg_value(node, type);
}

gb_internal cgValue cg_const_value(cgProcedure *p, Type *type, ExactValue const &value) {
	GB_ASSERT(p != nullptr);
	return cg_const_value(p->module, p, type, value);
}