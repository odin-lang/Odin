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
	case Type_MultiPointer:
		GB_PANIC("TODO(bill) %s", type_to_string(value.type));
		// res = cg_emit_conv(p, value, tv.type);
		break;
	}
	GB_ASSERT(res.node != nullptr);
	return res;
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


	}


	GB_PANIC("TODO(bill): builtin procs %d %.*s", id, LIT(builtin_name));
	return {};
}

