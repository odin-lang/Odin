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
	} else if (is_type_integer(type) || is_type_boolean(type) || is_type_bit_set(type) || is_type_typeid(type)) {
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

gb_internal TB_Global *cg_global_const_string(cgModule *m, String const &str, Type *type, TB_Global *global, i64 offset);
gb_internal void cg_write_int_at_ptr(void *dst, i64 i, Type *original_type);

gb_internal void cg_global_source_code_location_const(cgModule *m, String const &proc_name, TokenPos pos, TB_Global *global, i64 offset) {
	// Source_Code_Location :: struct {
	// 	file_path:    string,
	// 	line, column: i32,
	// 	procedure:    string,
	// }

	i64 file_path_offset = type_offset_of(t_source_code_location, 0);
	i64 line_offset      = type_offset_of(t_source_code_location, 1);
	i64 column_offset    = type_offset_of(t_source_code_location, 2);
	i64 procedure_offset = type_offset_of(t_source_code_location, 3);

	String file_path = get_file_path_string(pos.file_id);
	if (file_path.len != 0) {
		cg_global_const_string(m, file_path, t_string, global, offset+file_path_offset);
	}

	void *line_ptr   = tb_global_add_region(m->mod, global, offset+line_offset,   4);
	void *column_ptr = tb_global_add_region(m->mod, global, offset+column_offset, 4);
	cg_write_int_at_ptr(line_ptr,   pos.line,   t_i32);
	cg_write_int_at_ptr(column_ptr, pos.column, t_i32);

	if (proc_name.len != 0) {
		cg_global_const_string(m, proc_name, t_string, global, offset+procedure_offset);
	}
}


gb_internal cgValue cg_emit_source_code_location_as_global(cgProcedure *p, String const &proc_name, TokenPos pos) {
	cgModule *m = p->module;
	char name[32] = {};
	gb_snprintf(name, 31, "scl$%u", 1+m->const_nil_guid.fetch_add(1));

	TB_Global *global = tb_global_create(m->mod, -1, name, cg_debug_type(m, t_source_code_location), TB_LINKAGE_PRIVATE);
	tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, type_size_of(t_source_code_location), type_align_of(t_source_code_location), 6);

	cg_global_source_code_location_const(m, proc_name, pos, global, 0);

	TB_Node *ptr = tb_inst_get_symbol_address(p->func, cast(TB_Symbol *)global);
	return cg_lvalue_addr(ptr, t_source_code_location);
}

gb_internal cgValue cg_emit_source_code_location_as_global(cgProcedure *p, Ast *node) {
	String proc_name = p->name;
	TokenPos pos = ast_token(node).pos;
	return cg_emit_source_code_location_as_global(p, proc_name, pos);
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

gb_internal TB_Global *cg_global_const_string(cgModule *m, String const &str, Type *type, TB_Global *global, i64 offset) {
	GB_ASSERT(is_type_string(type));

	char name[32] = {};
	gb_snprintf(name, 31, "csb$%u", 1+m->const_nil_guid.fetch_add(1));
	TB_Global *str_global = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
	i64 size = str.len+1;
	tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), str_global, size, 1, 1);
	u8 *data = cast(u8 *)tb_global_add_region(m->mod, str_global, 0, size);
	gb_memcopy(data, str.text, str.len);
	data[str.len] = 0;

	if (is_type_cstring(type)) {
		if (global) {
			tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)str_global);
		}
		return str_global;
	}

	if (global == nullptr) {
		gb_snprintf(name, 31, "cstr$%u", 1+m->const_nil_guid.fetch_add(1));
		global = tb_global_create(m->mod, -1, name, cg_debug_type(m, type), TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), global, type_size_of(type), type_align_of(type), 2);
	}

	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)str_global);
	void *len_ptr = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, str.len, t_int);

	return global;
}

gb_internal bool cg_elem_type_can_be_constant(Type *t) {
	t = base_type(t);
	if (t == t_invalid) {
		return false;
	}
	if (is_type_dynamic_array(t) || is_type_map(t)) {
		return false;
	}
	return true;
}


gb_internal bool cg_is_elem_const(Ast *elem, Type *elem_type) {
	if (!cg_elem_type_can_be_constant(elem_type)) {
		return false;
	}
	if (elem->kind == Ast_FieldValue) {
		elem = elem->FieldValue.value;
	}
	TypeAndValue tav = type_and_value_of_expr(elem);
	GB_ASSERT_MSG(tav.mode != Addressing_Invalid, "%s %s", expr_to_string(elem), type_to_string(tav.type));
	return tav.value.kind != ExactValue_Invalid;
}

gb_internal bool cg_is_nested_possibly_constant(Type *ft, Selection const &sel, Ast *elem) {
	GB_ASSERT(!sel.indirect);
	for (i32 index : sel.index) {
		Type *bt = base_type(ft);
		switch (bt->kind) {
		case Type_Struct:
			// if (bt->Struct.is_raw_union) {
				// return false;
			// }
			ft = bt->Struct.fields[index]->type;
			break;
		case Type_Array:
			ft = bt->Array.elem;
			break;
		default:
			return false;
		}
	}
	return cg_is_elem_const(elem, ft);
}

gb_internal i64 cg_global_const_calculate_region_count_from_basic_type(Type *type) {
	type = core_type(type);

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_string:  // ^u8 + int
		case Basic_any:     // rawptr + typeid
			return 2;
		}
		return 1;
	case Type_Pointer:
	case Type_MultiPointer:
		return 2; // allows for offsets
	case Type_Proc:
		return 1;
	case Type_Slice:
		return 3; // alows for offsets
	case Type_DynamicArray:
		return 5;
	case Type_Map:
		return 4;

	case Type_Enum:
	case Type_BitSet:
		return 1;

	case Type_RelativePointer:
	case Type_RelativeMultiPointer:
		return 2; // allows for offsets

	case Type_Matrix:
		return 1;

	case Type_Array:
		{
			Type *elem = type->Array.elem;
			i64 count = cg_global_const_calculate_region_count_from_basic_type(elem);
			return count*type->Array.count;
		}
	case Type_EnumeratedArray:
		{
			Type *elem = type->EnumeratedArray.elem;
			i64 count = cg_global_const_calculate_region_count_from_basic_type(elem);
			return count*type->EnumeratedArray.count;
		}

	case Type_Struct:
		if (type->Struct.is_raw_union) {
			i64 max_count = 0;
			for (Entity *f : type->Struct.fields) {
				i64 count = cg_global_const_calculate_region_count_from_basic_type(f->type);
				max_count = gb_max(count, max_count);
			}
			return max_count;
		} else {
			i64 max_count = 0;
			for (Entity *f : type->Struct.fields) {
				max_count += cg_global_const_calculate_region_count_from_basic_type(f->type);
			}
			return max_count;
		}
		break;
	case Type_Union:
		{
			i64 max_count = 0;
			for (Type *t : type->Union.variants) {
				i64 count = cg_global_const_calculate_region_count_from_basic_type(t);
				max_count = gb_max(count, max_count);
			}
			return max_count+1;
		}
		break;

	default:
		GB_PANIC("TODO(bill): %s", type_to_string(type));
		break;
	}
	return -1;
}
gb_internal isize cg_global_const_calculate_region_count(ExactValue const &value, Type *type) {
	Type *bt = base_type(type);
	if (is_type_array(type) && value.kind == ExactValue_String && !is_type_u8(core_array_type(type))) {
		if (is_type_rune_array(type)) {
			return 1;
		}

		Type *et = base_array_type(type);
		i64 base_count = 2;
		if (is_type_cstring(et)) {
			base_count = 1;
		}
		return base_count * bt->Array.count;
	} else if (is_type_u8_array(type) && value.kind == ExactValue_String) {
		return 1;
	} else if (is_type_array(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_String &&
		value.kind != ExactValue_Compound) {
		Type *elem = type->Array.elem;

		i64 base_count = cg_global_const_calculate_region_count(value, elem);
		return base_count * type->Array.count;
	} else if (is_type_matrix(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_Compound) {
		return 1;
	} else if (is_type_simd_vector(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_Compound) {
		return 1;
	}

	isize count = 0;
	switch (value.kind) {
	case ExactValue_Invalid:
		return 0;
	case ExactValue_Bool:
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Typeid:
	case ExactValue_Complex:
	case ExactValue_Quaternion:
		return 1;
	case ExactValue_Pointer:
		return 2;

	case ExactValue_Procedure:
		return 1;

	case ExactValue_String:
		if (is_type_string(type)) {
			return 3;
		} else if (is_type_cstring(type) || is_type_array_like(type)) {
			return 2;
		}
		return 3;

	case ExactValue_Compound: {
		ast_node(cl, CompoundLit, value.value_compound);
		Type *bt = base_type(type);
		switch (bt->kind) {
		case Type_Struct:
			if (cl->elems[0]->kind == Ast_FieldValue) {
				for (isize i = 0; i < cl->elems.count; i++) {
					ast_node(fv, FieldValue, cl->elems[i]);
					String name = fv->field->Ident.token.string;

					Selection sel = lookup_field(type, name, false);
					GB_ASSERT(!sel.indirect);

					Entity *f = bt->Struct.fields[sel.index[0]];

					if (!cg_elem_type_can_be_constant(f->type)) {
						continue;
					}

					if (sel.index.count == 1) {
						count += cg_global_const_calculate_region_count(fv->value->tav.value, f->type);
					} else {
						count += 1; // just in case
						if (cg_is_nested_possibly_constant(type, sel, fv->value)) {
							Type *cv_type = sel.entity->type;
							count += cg_global_const_calculate_region_count(fv->value->tav.value, cv_type);
						}
					}
				}
			} else {
				for_array(i, cl->elems) {
					i64 field_index = i;
					Ast *elem = cl->elems[i];
					TypeAndValue tav = elem->tav;
					Entity *f = bt->Struct.fields[field_index];
					if (!cg_elem_type_can_be_constant(f->type)) {
						continue;
					}

					ExactValue value = {};
					if (tav.mode != Addressing_Invalid) {
						value = tav.value;
					}
					count += cg_global_const_calculate_region_count(value, type);
				}
			}
			break;
		case Type_Array:
		case Type_EnumeratedArray:
		case Type_SimdVector: {
			Type *et = base_array_type(bt);
			if (!cg_elem_type_can_be_constant(et)) {
				break;
			}
			for (Ast *elem : cl->elems) {
				if (elem->kind == Ast_FieldValue) {
					ast_node(fv, FieldValue, elem);
					ExactValue const &value = elem->FieldValue.value->tav.value;
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

						for (i64 i = lo; i < hi; i++) {
							count += cg_global_const_calculate_region_count(value, et);
						}
					} else {
						count += cg_global_const_calculate_region_count(value, et);
					}
				} else {
					ExactValue const &value = elem->tav.value;
					count += cg_global_const_calculate_region_count(value, et);
				}
			}
		} break;

		case Type_BitSet:
			return 1;
		case Type_Matrix:
			return 1;

		case Type_Slice:
			return 3;

		default:
			GB_PANIC("TODO(bill): %s", type_to_string(type));
			break;
		}
	}break;
	}
	return count;
}

gb_internal TB_Global *cg_global_const_comp_literal(cgModule *m, Type *type, ExactValue const &value, TB_Global *global, i64 base_offset);

gb_internal bool cg_global_const_add_region(cgModule *m, ExactValue const &value, Type *type, TB_Global *global, i64 offset) {
	GB_ASSERT(is_type_endian_little(type));
	GB_ASSERT(!is_type_different_to_arch_endianness(type));

	GB_ASSERT(global != nullptr);

	Type *bt = base_type(type);
	i64 size = type_size_of(type);
	if (value.kind == ExactValue_Invalid) {
		return false;
	}
	if (is_type_array(type) && value.kind == ExactValue_String && !is_type_u8(core_array_type(type))) {
		if (is_type_rune_array(type)) {
			i64 count = type->Array.count;
			Rune rune;
			isize rune_offset = 0;
			isize width = 1;
			String s = value.value_string;

			Rune *runes = cast(Rune *)tb_global_add_region(m->mod, global, offset, count*4);

			for (i64 i = 0; i < count && rune_offset < s.len; i++) {
				width = utf8_decode(s.text+rune_offset, s.len-rune_offset, &rune);
				runes[i] = rune;
				rune_offset += width;

			}
			GB_ASSERT(offset == s.len);
			return true;
		}
		Type *et = bt->Array.elem;
		i64 elem_size = type_size_of(et);

		for (i64 i = 0; i < bt->Array.count; i++) {
			cg_global_const_add_region(m, value, et, global, offset+(i * elem_size));
		}
		return true;
	} else if (is_type_u8_array(type) && value.kind == ExactValue_String) {
		u8 *dst = cast(u8 *)tb_global_add_region(m->mod, global, offset, size);
		gb_memcopy(dst, value.value_string.text, gb_min(value.value_string.len, size));
		return true;
	} else if (is_type_array(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_String &&
		value.kind != ExactValue_Compound) {

		Type *et = bt->Array.elem;
		i64 elem_size = type_size_of(et);

		for (i64 i = 0; i < bt->Array.count; i++) {
			cg_global_const_add_region(m, value, et, global, offset+(i * elem_size));
		}

		return true;
	} else if (is_type_matrix(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_Compound) {
		GB_PANIC("TODO(bill): matrices");

		i64 row = bt->Matrix.row_count;
		i64 column = bt->Matrix.column_count;
		GB_ASSERT(row == column);

		Type *elem = bt->Matrix.elem;

		i64 elem_size = type_size_of(elem);
		gb_unused(elem_size);

		// 1 region in memory, not many

		return true;
	} else if (is_type_simd_vector(type) &&
		value.kind != ExactValue_Invalid &&
		value.kind != ExactValue_Compound) {

		GB_PANIC("TODO(bill): #simd vectors");

		Type *et = type->SimdVector.elem;
		i64 elem_size = type_size_of(et);
		gb_unused(elem_size);

		// 1 region in memory, not many

		return true;
	}


	switch (value.kind) {
	case ExactValue_Bool:
		{
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
			bool *res = cast(bool *)tb_global_add_region(m->mod, global, offset, size);
			*res = !!value.value_bool;
		}
		break;

	case ExactValue_Integer:
		{
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
			void *res = tb_global_add_region(m->mod, global, offset, size);
			cg_write_big_int_at_ptr(res, &value.value_integer, type);
		}
		break;

	case ExactValue_Float:
		{
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
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
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
			void *res = tb_global_add_region(m->mod, global, offset, size);
			*(u64 *)res = exact_value_to_u64(value);
		}
		break;

	case ExactValue_String:
		if (is_type_array_like(type)) {
			GB_ASSERT(global != nullptr);
			void *data = tb_global_add_region(m->mod, global, offset, size);
			gb_memcopy(data, value.value_string.text, gb_min(value.value_string.len, size));
		} else {
			cg_global_const_string(m, value.value_string, type, global, offset);
		}
		break;

	case ExactValue_Typeid:
		{
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
			void *dst = tb_global_add_region(m->mod, global, offset, size);
			u64 id = cg_typeid_as_u64(m, value.value_typeid);
			cg_write_uint_at_ptr(dst, id, t_typeid);
		}
		break;

	case ExactValue_Compound:
		{
			TB_Global *out_global = cg_global_const_comp_literal(m, type, value, global, offset);
			GB_ASSERT(out_global == global);
		}
		break;

	case ExactValue_Procedure:
		GB_PANIC("TODO(bill): nested procedure values/literals\n");
		break;
	case ExactValue_Complex:
		{
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
			Complex128 c = {};
			if (value.value_complex) {
				c = *value.value_complex;
			}
			void *res = tb_global_add_region(m->mod, global, offset, size);
			switch (size) {
			case 4:
				((u16 *)res)[0] = f32_to_f16(cast(f32)c.real);
				((u16 *)res)[1] = f32_to_f16(cast(f32)c.imag);
				break;
			case 8:
				((f32 *)res)[0] = cast(f32)c.real;
				((f32 *)res)[1] = cast(f32)c.imag;
				break;
			case 16:
				((f64 *)res)[0] = cast(f64)c.real;
				((f64 *)res)[1] = cast(f64)c.imag;
				break;
			}
		}
		break;
	case ExactValue_Quaternion:
		{
			GB_ASSERT_MSG(!is_type_array_like(bt), "%s", type_to_string(type));
			// @QuaternionLayout
			Quaternion256 q = {};
			if (value.value_quaternion) {
				q = *value.value_quaternion;
			}
			void *res = tb_global_add_region(m->mod, global, offset, size);
			switch (size) {
			case 8:
				((u16 *)res)[0] = f32_to_f16(cast(f32)q.imag);
				((u16 *)res)[1] = f32_to_f16(cast(f32)q.jmag);
				((u16 *)res)[2] = f32_to_f16(cast(f32)q.kmag);
				((u16 *)res)[3] = f32_to_f16(cast(f32)q.real);
				break;
			case 16:
				((f32 *)res)[0] = cast(f32)q.imag;
				((f32 *)res)[1] = cast(f32)q.jmag;
				((f32 *)res)[2] = cast(f32)q.kmag;
				((f32 *)res)[3] = cast(f32)q.real;
				break;
			case 32:
				((f64 *)res)[0] = cast(f64)q.imag;
				((f64 *)res)[1] = cast(f64)q.jmag;
				((f64 *)res)[2] = cast(f64)q.kmag;
				((f64 *)res)[3] = cast(f64)q.real;
				break;
			}
		}
		break;
	default:
		GB_PANIC("%s", type_to_string(type));
		break;
	}
	return true;
}


gb_internal TB_Global *cg_global_const_comp_literal(cgModule *m, Type *original_type, ExactValue const &value, TB_Global *global, i64 base_offset) {
	GB_ASSERT(value.kind == ExactValue_Compound);
	Ast *value_compound = value.value_compound;
	ast_node(cl, CompoundLit, value_compound);

	TEMPORARY_ALLOCATOR_GUARD();

	if (global == nullptr) {
		char name[32] = {};
		gb_snprintf(name, 31, "complit$%u", 1+m->const_nil_guid.fetch_add(1));
		global = tb_global_create(m->mod, -1, name, cg_debug_type(m, original_type), TB_LINKAGE_PRIVATE);
		i64 size = type_size_of(original_type);
		i64 align = type_align_of(original_type);

		// READ ONLY?
		TB_ModuleSectionHandle section = 0;
		if (is_type_string(original_type) || is_type_cstring(original_type)) {
			section = tb_module_get_rdata(m->mod);
		} else {
			section = tb_module_get_data(m->mod);
		}

		if (cl->elems.count == 0) {
			tb_global_set_storage(m->mod, section, global, size, align, 0);
			return global;
		}


		isize global_region_count = cg_global_const_calculate_region_count(value, original_type);
		tb_global_set_storage(m->mod, section, global, size, align, global_region_count);
	}

	if (cl->elems.count == 0) {
		return global;
	}


	Type *bt = base_type(original_type);
	i64 bt_size = type_size_of(bt);

	switch (bt->kind) {
	case Type_Struct:
		if (cl->elems[0]->kind == Ast_FieldValue) {
			isize elem_count = cl->elems.count;
			for (isize i = 0; i < elem_count; i++) {
				ast_node(fv, FieldValue, cl->elems[i]);
				String name = fv->field->Ident.token.string;

				TypeAndValue tav = fv->value->tav;
				GB_ASSERT(tav.mode != Addressing_Invalid);
				ExactValue value = tav.value;

				Selection sel = lookup_field(bt, name, false);
				GB_ASSERT(!sel.indirect);

				if (!cg_is_nested_possibly_constant(bt, sel, fv->value)) {
					continue;
				}

				i64 offset = type_offset_of_from_selection(bt, sel);
				cg_global_const_add_region(m, value, sel.entity->type, global, base_offset+offset);
			}
		} else {
			for_array(i, cl->elems) {
				i64 field_index = i;
				Ast *elem = cl->elems[i];
				TypeAndValue tav = elem->tav;
				Entity *f = bt->Struct.fields[field_index];
				if (!cg_elem_type_can_be_constant(f->type)) {
					continue;
				}

				i64 offset = bt->Struct.offsets[field_index];

				ExactValue value = {};
				if (tav.mode != Addressing_Invalid) {
					value = tav.value;
				}
				cg_global_const_add_region(m, value, f->type, global, base_offset+offset);
			}
		}
		return global;

	case Type_Array:
	case Type_EnumeratedArray:
	case Type_SimdVector:
		if (cl->elems[0]->kind == Ast_FieldValue) {
			Type *et = base_array_type(bt);
			i64 elem_size = type_size_of(et);
			for (Ast *elem : cl->elems) {
				ast_node(fv, FieldValue, elem);

				ExactValue const &value = fv->value->tav.value;

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

					for (i64 i = lo; i < hi; i++) {
						i64 offset = i * elem_size;
						cg_global_const_add_region(m, value, et, global, base_offset+offset);
					}
				} else {
					TypeAndValue index_tav = fv->field->tav;
					GB_ASSERT(index_tav.mode == Addressing_Constant);
					i64 i = exact_value_to_i64(index_tav.value);
					i64 offset = i * elem_size;
					cg_global_const_add_region(m, value, et, global, base_offset+offset);
				}
			}
		} else {
			Type *et = base_array_type(bt);
			i64 elem_size = type_size_of(et);
			i64 offset = 0;
			for (Ast *elem : cl->elems) {
				ExactValue const &value = elem->tav.value;
				cg_global_const_add_region(m, value, et, global, base_offset+offset);
				offset += elem_size;
			}
		}

		return global;

	case Type_BitSet:
		if (bt_size > 0) {
			BigInt bits = {};
			BigInt one = {};
			big_int_from_u64(&one, 1);

			for_array(i, cl->elems) {
				Ast *e = cl->elems[i];
				GB_ASSERT(e->kind != Ast_FieldValue);

				TypeAndValue tav = e->tav;
				if (tav.mode != Addressing_Constant) {
					continue;
				}
				GB_ASSERT(tav.value.kind == ExactValue_Integer);
				i64 v = big_int_to_i64(&tav.value.value_integer);
				i64 lower = bt->BitSet.lower;
				u64 index = cast(u64)(v-lower);
				BigInt bit = {};
				big_int_from_u64(&bit, index);
				big_int_shl(&bit, &one, &bit);
				big_int_or(&bits, &bits, &bit);
			}

			void *dst = tb_global_add_region(m->mod, global, base_offset, bt_size);
			cg_write_big_int_at_ptr(dst, &bits, original_type);
		}
		return global;

	case Type_Matrix:
		GB_PANIC("TODO(bill): constant compound literal for %s", type_to_string(original_type));
		break;

	case Type_Slice:
		{
			i64 count = gb_max(cl->elems.count, cl->max_count);
			Type *elem = bt->Slice.elem;
			Type *t = alloc_type_array(elem, count);
			TB_Global *backing_array = cg_global_const_comp_literal(m, t, value, nullptr, 0);

			tb_global_add_symbol_reloc(m->mod, global, base_offset+0, cast(TB_Symbol *)backing_array);

			void *len_ptr = tb_global_add_region(m->mod, global, base_offset+build_context.int_size, build_context.int_size);
			cg_write_int_at_ptr(len_ptr, count, t_int);
		}
		return global;
	}

	GB_PANIC("TODO(bill): constant compound literal for %s", type_to_string(original_type));
	return nullptr;
}


gb_internal cgValue cg_const_value(cgProcedure *p, Type *type, ExactValue const &value) {
	GB_ASSERT(p != nullptr);
	TB_Node *node = nullptr;

	if (is_type_untyped(type)) {
		// TODO(bill): THIS IS A COMPLETE HACK, WHY DOES THIS NOT A TYPE?
		GB_ASSERT(type->kind == Type_Basic);
		switch (type->Basic.kind) {
		case Basic_UntypedBool:
			type = t_bool;
			break;
		case Basic_UntypedInteger:
			type = t_i64;
			break;
		case Basic_UntypedFloat:
			type = t_f64;
			break;
		case Basic_UntypedComplex:
			type = t_complex128;
			break;
		case Basic_UntypedQuaternion:
			type = t_quaternion256;
			break;
		case Basic_UntypedString:
			type = t_string;
			break;
		case Basic_UntypedRune:
			type = t_rune;
			break;
		case Basic_UntypedNil:
		case Basic_UntypedUninit:
			return cg_value(cast(TB_Node *)nullptr, type);
		}
	}
	TB_DataType dt = cg_data_type(type);

	switch (value.kind) {
	case ExactValue_Invalid:
		return cg_const_nil(p, type);

	case ExactValue_Typeid:
		return cg_typeid(p, value.value_typeid);

	case ExactValue_Procedure:
		{
			Ast *expr = unparen_expr(value.value_procedure);
			if (expr->kind == Ast_ProcLit) {
				cgProcedure *anon = cg_procedure_generate_anonymous(p->module, expr, p);
				TB_Node *ptr = tb_inst_get_symbol_address(p->func, anon->symbol);
				GB_ASSERT(are_types_identical(type, anon->type));
				return cg_value(ptr, type);
			}

			Entity *e = entity_of_node(expr);
			if (e != nullptr) {
				TB_Symbol *found = cg_find_symbol_from_entity(p->module, e);
				GB_ASSERT_MSG(found != nullptr, "could not find '%.*s'", LIT(e->token.string));
				TB_Node *ptr = tb_inst_get_symbol_address(p->func, found);
				GB_ASSERT(type != nullptr);
				GB_ASSERT(are_types_identical(type, e->type));
				return cg_value(ptr, type);
			}

			GB_PANIC("TODO(bill): cg_const_value ExactValue_Procedure %s", expr_to_string(expr));
		}
		break;
	}

	switch (value.kind) {
	case ExactValue_Bool:
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
		return cg_value(tb_inst_uint(p->func, dt, value.value_bool), type);

	case ExactValue_Integer:
		GB_ASSERT(!TB_IS_VOID_TYPE(dt));
		// GB_ASSERT(dt.raw != TB_TYPE_I128.raw);
		if (is_type_unsigned(type)) {
			u64 i = 0;
			if (value.kind == ExactValue_Integer && value.value_integer.sign) {
				i = exact_value_to_i64(value);
			} else {
				i = exact_value_to_u64(value);
			}
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
			GB_ASSERT(is_type_string(type));
			cgModule *m = p->module;

			String str = value.value_string;

			char name[32] = {};
			gb_snprintf(name, 31, "csb$%u", 1+m->const_nil_guid.fetch_add(1));
			TB_Global *cstr_global = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);

			i64 size = str.len+1;
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), cstr_global, size, 1, 1);
			u8 *data = cast(u8 *)tb_global_add_region(m->mod, cstr_global, 0, size);
			gb_memcopy(data, str.text, str.len);
			data[str.len] = 0;

			if (is_type_cstring(type)) {
				cgValue s = cg_value(cstr_global, type);
				return cg_flatten_value(p, s);
			}

			gb_snprintf(name, 31, "str$%u", 1+m->const_nil_guid.fetch_add(1));
			TB_Global *str_global = tb_global_create(m->mod, -1, name, cg_debug_type(m, type), TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), str_global, type_size_of(type), type_align_of(type), 2);

			tb_global_add_symbol_reloc(m->mod, str_global, 0, cast(TB_Symbol *)cstr_global);
			void *len_ptr = tb_global_add_region(m->mod, str_global, build_context.int_size, build_context.int_size);
			cg_write_int_at_ptr(len_ptr, str.len, t_int);

			TB_Node *s = tb_inst_get_symbol_address(p->func, cast(TB_Symbol *)str_global);
			return cg_lvalue_addr(s, type);

		}

	case ExactValue_Pointer:
		return cg_value(tb_inst_uint(p->func, dt, exact_value_to_u64(value)), type);

	case ExactValue_Compound:
		{
			TB_Symbol *symbol = cast(TB_Symbol *)cg_global_const_comp_literal(p->module, type, value, nullptr, 0);
			TB_Node *node = tb_inst_get_symbol_address(p->func, symbol);
			return cg_lvalue_addr(node, type);
		}
		break;
	}


	GB_ASSERT(node != nullptr);
	return cg_value(node, type);
}

gb_internal cgValue cg_const_int(cgProcedure *p, Type *type, i64 i) {
	return cg_const_value(p, type, exact_value_i64(i));
}
gb_internal cgValue cg_const_bool(cgProcedure *p, Type *type, bool v) {
	return cg_value(tb_inst_bool(p->func, v), type);
}

gb_internal cgValue cg_const_string(cgProcedure *p, Type *type, String const &str) {
	return cg_const_value(p, type, exact_value_string(str));
}

gb_internal cgValue cg_const_union_tag(cgProcedure *p, Type *u, Type *v) {
	return cg_const_value(p, union_tag_type(u), exact_value_i64(union_variant_index(u, v)));
}

