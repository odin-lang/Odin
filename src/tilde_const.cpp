gb_internal bool cg_is_expr_constant_zero(Ast *expr) {
	GB_ASSERT(expr != nullptr);
	auto v = exact_value_to_integer(expr->tav.value);
	if (v.kind == ExactValue_Integer) {
		return big_int_cmp_zero(&v.value_integer) == 0;
	}
	return false;
}

gb_internal cgValue cg_const_nil(cgModule *m, cgProcedure *p, Type *type) {
	GB_ASSERT(m != nullptr);
	Type *original_type = type;
	type = core_type(type);
	i64 size = type_size_of(type);
	i64 align = type_align_of(type);
	TB_DataType dt = cg_data_type(type);
	if (TB_IS_VOID_TYPE(dt)) {
		char name[32] = {};
		gb_snprintf(name, 31, "cnil$%u", 1+m->const_nil_guid.fetch_add(1));
		TB_Global *global = tb_global_create(m->mod, -1, name, cg_debug_type(m, type), TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, size, align, 0);

		TB_Symbol *symbol = cast(TB_Symbol *)global;
		if (p) {
			TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
			return cg_lvalue_addr(node, type);
		} else {
			return cg_value(symbol, type);
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

gb_internal TB_Global *cg_global_const_cstring(cgModule *m, String const &str, Type *type) {
	char name[32] = {};
	gb_snprintf(name, 31, "csb$%u", 1+m->const_nil_guid.fetch_add(1));
	TB_Global *global = tb_global_create(m->mod, -1, name, cg_debug_type(m, type), TB_LINKAGE_PRIVATE);
	i64 size = str.len+1;
	tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, size, 1, 1);
	u8 *data = cast(u8 *)tb_global_add_region(m->mod, global, 0, size+1);
	gb_memcopy(data, str.text, str.len);
	data[str.len] = 0;
	return global;

}

gb_internal void cg_write_big_int_at_ptr(void *dst, BigInt const *a, Type *original_type) {
	GB_ASSERT(build_context.endian_kind == TargetEndian_Little);
	size_t sz = cast(size_t)type_size_of(original_type);
	if (big_int_is_zero(a)) {
		gb_memset(dst, 0, sz);
		return;
	}
	u64 rop64[4] = {}; // 2 u64 is the maximum we will ever need, so doubling it will be fine :P
	u8 *rop = cast(u8 *)rop64;

	size_t max_count = 0;
	size_t written = 0;
	size_t size = 1;
	size_t nails = 0;
	mp_endian endian = MP_LITTLE_ENDIAN;

	max_count = mp_pack_count(a, nails, size);
	if (sz < max_count) {
		debug_print_big_int(a);
		gb_printf_err("%s -> %tu\n", type_to_string(original_type), sz);;
	}
	GB_ASSERT_MSG(sz >= max_count, "max_count: %tu, sz: %tu, written: %tu, type %s", max_count, sz, written, type_to_string(original_type));
	GB_ASSERT(gb_size_of(rop64) >= sz);

	mp_err err = mp_pack(rop, sz, &written,
	                     MP_LSB_FIRST,
	                     size, endian, nails,
	                     a);
	GB_ASSERT(err == MP_OKAY);

	if (!is_type_endian_little(original_type)) {
		for (size_t i = 0; i < sz/2; i++) {
			u8 tmp = rop[i];
			rop[i] = rop[sz-1-i];
			rop[sz-1-i] = tmp;
		}
	}

	gb_memcopy(dst, rop, sz);
	return;
}


gb_internal void cg_write_int_at_ptr(void *dst, i64 i, Type *original_type) {
	ExactValue v = exact_value_i64(i);
	cg_write_big_int_at_ptr(dst, &v.value_integer, original_type);
}
gb_internal void cg_write_uint_at_ptr(void *dst, u64 i, Type *original_type) {
	ExactValue v = exact_value_u64(i);
	cg_write_big_int_at_ptr(dst, &v.value_integer, original_type);
}

gb_internal TB_Global *cg_global_const_string(cgModule *m, String const &str, Type *type) {
	if (is_type_cstring(type)) {
		return cg_global_const_cstring(m, str, type);
	}
	GB_ASSERT(is_type_string(type));

	char name[32] = {};
	gb_snprintf(name, 31, "csl$%u", 1+m->const_nil_guid.fetch_add(1));
	TB_Global *global = tb_global_create(m->mod, -1, name, cg_debug_type(m, type), TB_LINKAGE_PRIVATE);


	i64 size = type_size_of(type);
	i64 align = type_align_of(type);
	tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, size, align, 2);

	tb_global_add_symbol_reloc(m->mod, global, 0, cast(TB_Symbol *)cg_global_const_cstring(m, str, t_cstring));

	void *len_ptr = tb_global_add_region(m->mod, global, build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, str.len, t_int);

	return global;
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
		return cg_typeid(p, value.value_typeid);

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

	Type *original_type = type;

	switch (value.kind) {
	case ExactValue_Bool:
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
		return cg_value(tb_inst_uint(p->func, dt, value.value_bool), type);

	case ExactValue_Integer:
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
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
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
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

	case ExactValue_String:
		{
			TB_Symbol *symbol = cast(TB_Symbol *)cg_global_const_string(m, value.value_string, type);
			if (p) {
				TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
				return cg_lvalue_addr(node, type);
			} else {
				return cg_value(symbol, type);
			}
		}

	case ExactValue_Pointer:
		return cg_value(tb_inst_uint(p->func, dt, exact_value_to_u64(value)), type);

	case ExactValue_Compound:
		if (is_type_struct(type)) {
			ast_node(cl, CompoundLit, value.value_compound);

			if (cl->elems.count == 0) {
				return cg_const_nil(m, p, original_type);
			}

			Type *bt = base_type(type);
			if (bt->Struct.is_raw_union) {
				return cg_const_nil(m, p, original_type);
			}

			TEMPORARY_ALLOCATOR_GUARD();

			isize value_count = bt->Struct.fields.count;
			cgValue * values  = gb_alloc_array(temporary_allocator(), cgValue, value_count);
			bool *   visited  = gb_alloc_array(temporary_allocator(), bool,    value_count);


			char name[32] = {};
			gb_snprintf(name, 31, "complit$%u", 1+m->const_nil_guid.fetch_add(1));
			TB_Global *global = tb_global_create(m->mod, -1, name, cg_debug_type(m, original_type), TB_LINKAGE_PRIVATE);
			i64 size = type_size_of(original_type);
			i64 align = type_align_of(original_type);

			// READ ONLY?
			TB_ModuleSection *section = tb_module_get_rdata(m->mod);
			tb_global_set_storage(m->mod, section, global, size, align, value_count);

			if (cl->elems[0]->kind == Ast_FieldValue) {
				// isize elem_count = cl->elems.count;
				// for (isize i = 0; i < elem_count; i++) {
				// 	ast_node(fv, FieldValue, cl->elems[i]);
				// 	String name = fv->field->Ident.token.string;

				// 	TypeAndValue tav = fv->value->tav;
				// 	GB_ASSERT(tav.mode != Addressing_Invalid);

				// 	Selection sel = lookup_field(type, name, false);
				// 	GB_ASSERT(!sel.indirect);

				// 	Entity *f = type->Struct.fields[sel.index[0]];
				// 	i32 index = field_remapping[f->Variable.field_index];
				// 	if (elem_type_can_be_constant(f->type)) {
				// 		if (sel.index.count == 1) {
				// 			values[index] = lb_const_value(m, f->type, tav.value, allow_local).value;
				// 			visited[index] = true;
				// 		} else {
				// 			if (!visited[index]) {
				// 				values[index] = lb_const_value(m, f->type, {}, false).value;
				// 				visited[index] = true;
				// 			}
				// 			unsigned idx_list_len = cast(unsigned)sel.index.count-1;
				// 			unsigned *idx_list = gb_alloc_array(temporary_allocator(), unsigned, idx_list_len);

				// 			if (lb_is_nested_possibly_constant(type, sel, fv->value)) {
				// 				bool is_constant = true;
				// 				Type *cv_type = f->type;
				// 				for (isize j = 1; j < sel.index.count; j++) {
				// 					i32 index = sel.index[j];
				// 					Type *cvt = base_type(cv_type);

				// 					if (cvt->kind == Type_Struct) {
				// 						if (cvt->Struct.is_raw_union) {
				// 							// sanity check which should have been caught by `lb_is_nested_possibly_constant`
				// 							is_constant = false;
				// 							break;
				// 						}
				// 						cv_type = cvt->Struct.fields[index]->type;

				// 						if (is_type_struct(cvt)) {
				// 							auto cv_field_remapping = lb_get_struct_remapping(m, cvt);
				// 							unsigned remapped_index = cast(unsigned)cv_field_remapping[index];
				// 							idx_list[j-1] = remapped_index;
				// 						} else {
				// 							idx_list[j-1] = cast(unsigned)index;
				// 						}
				// 					} else if (cvt->kind == Type_Array) {
				// 						cv_type = cvt->Array.elem;

				// 						idx_list[j-1] = cast(unsigned)index;
				// 					} else {
				// 						GB_PANIC("UNKNOWN TYPE: %s", type_to_string(cv_type));
				// 					}
				// 				}
				// 				if (is_constant) {
				// 					LLVMValueRef elem_value = lb_const_value(m, tav.type, tav.value, allow_local).value;
				// 					GB_ASSERT(LLVMIsConstant(elem_value));
				// 					values[index] = LLVMConstInsertValue(values[index], elem_value, idx_list, idx_list_len);
				// 				}
				// 			}
				// 		}
				// 	}
				// }
			} else {
				for_array(i, cl->elems) {
					i64 field_index = i;
					Ast *elem = cl->elems[i];
					TypeAndValue tav = elem->tav;
					Entity *f = bt->Struct.fields[field_index];
					if (!elem_type_can_be_constant(f->type)) {
						continue;
					}

					i64 offset = bt->Struct.offsets[field_index];
					i64 size = type_size_of(f->type);


					ExactValue value = {};
					if (tav.mode != Addressing_Invalid) {
						value = tav.value;
					}

					GB_ASSERT(is_type_endian_little(f->type));
					GB_ASSERT(!is_type_different_to_arch_endianness(type));


					if (value.kind != ExactValue_Invalid) {
						switch (value.kind) {
						case ExactValue_Bool:
							{
								bool *res = cast(bool *)tb_global_add_region(m->mod, global, offset, size);
								*res = !!value.value_bool;
							}
							break;

						case ExactValue_Integer:
							{
								void *res = tb_global_add_region(m->mod, global, offset, size);
								cg_write_big_int_at_ptr(res, &value.value_integer, f->type);
							}
							break;

						case ExactValue_Float:
							{
								f64 f = exact_value_to_f64(value);
								void *res = tb_global_add_region(m->mod, global, offset, size);
								switch (size) {
								case 2: *(u16 *)res = f32_to_f16(cast(f32)f); break;
								case 4: *(f32 *)res = cast(f32)f;             break;
								case 8: *(f64 *)res = cast(f64)f;             break;
								}
							}
							break;

						case ExactValue_Pointer:
							{
								void *res = tb_global_add_region(m->mod, global, offset, size);
								*(u64 *)res = exact_value_to_u64(value);
							}
							break;

						case ExactValue_String:
							{
								TB_Symbol *symbol = cast(TB_Symbol *)cg_global_const_string(m, value.value_string, f->type);
								tb_global_add_symbol_reloc(m->mod, global, offset, symbol);
							}
							break;

						case ExactValue_Typeid:
							{
								void *dst = tb_global_add_region(m->mod, global, offset, size);
								u64 id = cg_typeid_as_u64(m, value.value_typeid);
								cg_write_uint_at_ptr(dst, id, t_typeid);
							}
							break;

						case ExactValue_Procedure:
							GB_PANIC("TODO(bill): nested procedure values/literals\n");
							break;
						case ExactValue_Compound:
							GB_PANIC("TODO(bill): nested compound literals\n");
							break;

						case ExactValue_Complex:
							GB_PANIC("TODO(bill): nested complex literals\n");
							break;
						case ExactValue_Quaternion:
							GB_PANIC("TODO(bill): nested quaternions literals\n");
							break;
						default:
							GB_PANIC("%s", type_to_string(f->type));
							break;
						}
						visited[i] = true;
						continue;
					}

					values[i]  = cg_const_value(m, p, f->type, value, allow_local);
					visited[i] = true;
				}
			}

			TB_Symbol *symbol = cast(TB_Symbol *)global;
			if (p) {
				TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
				return cg_lvalue_addr(node, type);
			} else {
				return cg_value(symbol, type);
			}

		} else {
			GB_PANIC("TODO(bill): constant compound literal for %s", type_to_string(type));
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
gb_internal cgValue cg_const_bool(cgProcedure *p, Type *type, bool v) {
	return cg_value(tb_inst_bool(p->func, v), type);
}
