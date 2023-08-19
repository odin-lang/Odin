gb_internal TB_DebugType *cg_debug_type_internal(cgModule *m, Type *type);
gb_internal TB_DebugType *cg_debug_type(cgModule *m, Type *type) {
	type = reduce_tuple_to_single_type(type);

	mutex_lock(&m->debug_type_mutex);
	defer (mutex_unlock(&m->debug_type_mutex));
	TB_DebugType **found = map_get(&m->debug_type_map, type);
	if (found) {
		return *found;
	}

	TB_DebugType *res = cg_debug_type_internal(m, type);
	map_set(&m->debug_type_map, type, res);
	return res;
}

gb_internal TB_DebugType *cg_debug_type_for_proc(cgModule *m, Type *type) {
	GB_ASSERT(is_type_proc(type));
	TB_DebugType **func_found = nullptr;
	TB_DebugType *func_ptr = cg_debug_type(m, type);
	GB_ASSERT(func_ptr != nullptr);

	mutex_lock(&m->debug_type_mutex);
	func_found = map_get(&m->proc_debug_type_map, type);
	mutex_unlock(&m->debug_type_mutex);
	GB_ASSERT(func_found != nullptr);
	return *func_found;
}


gb_internal TB_DebugType *cg_debug_type_internal_record(cgModule *m, Type *type, String const &record_name) {
	Type *bt = base_type(type);
	switch (bt->kind) {
	case Type_Struct:
		{
			type_set_offsets(bt);

			TB_DebugType *record = nullptr;
			if (bt->Struct.is_raw_union) {
				record = tb_debug_create_union(m->mod, record_name.len, cast(char const *)record_name.text);
			} else {
				record = tb_debug_create_struct(m->mod, record_name.len, cast(char const *)record_name.text);
			}
			if (record_name.len != 0) {
				map_set(&m->debug_type_map, type, record);
			}

			TB_DebugType **fields = tb_debug_record_begin(m->mod, record, bt->Struct.fields.count);
			for_array(i, bt->Struct.fields) {
				Entity *e = bt->Struct.fields[i];
				Type *type = e->type;
				if (is_type_proc(type)) {
					type = t_rawptr;
				}
				TB_DebugType *field_type = cg_debug_type(m, type);
				String        name       = e->token.string;
				TB_CharUnits  offset     = cast(TB_CharUnits)bt->Struct.offsets[i];
				if (name.len == 0) {
					name = str_lit("_");
				}

				fields[i] = tb_debug_create_field(m->mod, field_type, name.len, cast(char const *)name.text, offset);
			}
			tb_debug_record_end(
				record,
				cast(TB_CharUnits)type_size_of(type),
				cast(TB_CharUnits)type_align_of(type)
			);
			return record;
		}
		break;

	case Type_Tuple:
		{
			GB_ASSERT(record_name.len == 0);
			type_set_offsets(bt);

			TB_DebugType *record = tb_debug_create_struct(m->mod, 0, "");
			isize record_count = 0;
			for (Entity *e : bt->Tuple.variables) {
				if (e->kind == Entity_Variable) {
					record_count += 1;
				}
			}
			TB_DebugType **fields = tb_debug_record_begin(m->mod, record, record_count);
			for_array(i, bt->Tuple.variables) {
				Entity *e = bt->Tuple.variables[i];
				if (e->kind != Entity_Variable) {
					continue;
				}
				Type *type = e->type;
				if (is_type_proc(type)) {
					type = t_rawptr;
				}
				TB_DebugType *field_type = cg_debug_type(m, type);
				String        name       = e->token.string;
				TB_CharUnits  offset     = cast(TB_CharUnits)bt->Tuple.offsets[i];
				if (name.len == 0) {
					name = str_lit("_");
				}

				fields[i] = tb_debug_create_field(m->mod, field_type, name.len, cast(char const *)name.text, offset);
			}
			tb_debug_record_end(
				record,
				cast(TB_CharUnits)type_size_of(type),
				cast(TB_CharUnits)type_align_of(type)
			);
			return record;
		}
		break;
	case Type_Union:
		{
			TB_DebugType *record = tb_debug_create_struct(m->mod, record_name.len, cast(char const *)record_name.text);
			if (record_name.len != 0) {
				map_set(&m->debug_type_map, type, record);
			}

			i64 variant_count = bt->Union.variants.count;
			if (is_type_union_maybe_pointer(bt)) {
				// NO TAG
				GB_ASSERT(variant_count == 1);
				TB_DebugType **fields = tb_debug_record_begin(m->mod, record, variant_count);
				TB_DebugType *variant_type = cg_debug_type(m, bt->Union.variants[0]);
				fields[0] = tb_debug_create_field(m->mod, variant_type, -1, "v0", 0);
				tb_debug_record_end(
					record,
					cast(TB_CharUnits)type_size_of(type),
					cast(TB_CharUnits)type_align_of(type)
				);
			} else {
				TB_DebugType **fields = tb_debug_record_begin(m->mod, record, variant_count+1);
				for_array(i, bt->Union.variants) {
					Type *v = bt->Union.variants[i];
					TB_DebugType *variant_type = cg_debug_type(m, v);
					char name[32] = {};
					u32 v_index = cast(u32)i;
					if (bt->Union.kind != UnionType_no_nil) {
						v_index += 1;
					}
					gb_snprintf(name, 31, "v%u", v_index);
					fields[i] = tb_debug_create_field(m->mod, variant_type, -1, name, 0);
				}

				TB_DebugType *tag_type = cg_debug_type(m, union_tag_type(bt));
				fields[variant_count] = tb_debug_create_field(m->mod, tag_type, -1, "tag", cast(TB_CharUnits)bt->Union.variant_block_size);

			}
			tb_debug_record_end(
				record,
				cast(TB_CharUnits)type_size_of(type),
				cast(TB_CharUnits)type_align_of(type)
			);
			return record;
		}
		break;
	}
	return nullptr;
}


gb_internal TB_DebugType *cg_debug_type_internal(cgModule *m, Type *type) {
	if (type == nullptr) {
		return tb_debug_get_void(m->mod);
	}
	Type *original_type = type;
	if (type->kind == Type_Named) {
		String name = type->Named.name;
		TB_DebugType *res = cg_debug_type_internal_record(m, type, name);
		if (res) {
			return res;
		}
		type = base_type(type->Named.base);
	}

	TB_CharUnits int_size = cast(TB_CharUnits)build_context.int_size;
	TB_CharUnits ptr_size = cast(TB_CharUnits)build_context.ptr_size;
	TB_CharUnits size  = cast(TB_CharUnits)type_size_of(type);
	TB_CharUnits align = cast(TB_CharUnits)type_align_of(type);
	int bits = cast(int)(8*size);
	bool is_signed = is_type_integer(core_type(type)) && !is_type_unsigned(core_type(type));

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_bool:          return tb_debug_get_bool(m->mod);
		case Basic_b8:            return tb_debug_get_bool(m->mod);
		case Basic_b16:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_b32:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_b64:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i8:            return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u8:            return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i16:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u16:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i32:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u32:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i64:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u64:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i128:          return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u128:          return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_rune:          return tb_debug_get_integer(m->mod, is_signed, bits);

		case Basic_f16:           return tb_debug_get_integer(m->mod, false, bits);
		case Basic_f32:           return tb_debug_get_float(m->mod,   TB_FLT_32);
		case Basic_f64:           return tb_debug_get_float(m->mod,   TB_FLT_64);

		case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
			{
				String name = basic_types[type->Basic.kind].Basic.name;
				TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
				Type *et = base_complex_elem_type(type);
				TB_CharUnits elem_size = cast(TB_CharUnits)type_size_of(et);
				TB_DebugType *elem = cg_debug_type(m, et);

				TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 2);
				fields[0] = tb_debug_create_field(m->mod, elem, -1, "real", 0*elem_size);
				fields[1] = tb_debug_create_field(m->mod, elem, -1, "imag", 1*elem_size);

				tb_debug_record_end(record, size, align);
				return record;
			}
		case Basic_quaternion64:
		case Basic_quaternion128:
		case Basic_quaternion256:
			{
				String name = basic_types[type->Basic.kind].Basic.name;
				TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
				Type *et = base_complex_elem_type(type);
				TB_CharUnits elem_size = cast(TB_CharUnits)type_size_of(et);
				TB_DebugType *elem = cg_debug_type(m, et);

				// @QuaternionLayout
				TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 4);
				fields[0] = tb_debug_create_field(m->mod, elem, -1, "imag", 0*elem_size);
				fields[1] = tb_debug_create_field(m->mod, elem, -1, "jmag", 1*elem_size);
				fields[2] = tb_debug_create_field(m->mod, elem, -1, "kmag", 2*elem_size);
				fields[3] = tb_debug_create_field(m->mod, elem, -1, "real", 3*elem_size);

				tb_debug_record_end(record, size, align);
				return record;
			}

		case Basic_int:           return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_uint:          return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_uintptr:       return tb_debug_get_integer(m->mod, is_signed, bits);

		case Basic_rawptr:
			return tb_debug_create_ptr(m->mod, tb_debug_get_void(m->mod));
		case Basic_string:
			{
				String name = basic_types[type->Basic.kind].Basic.name;
				TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
				// @QuaternionLayout
				TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 2);
				fields[0] = tb_debug_create_field(m->mod, cg_debug_type(m, t_u8_ptr), -1, "data", 0*int_size);
				fields[1] = tb_debug_create_field(m->mod, cg_debug_type(m, t_int),    -1, "len",  1*int_size);

				tb_debug_record_end(record, size, align);
				return record;
			}
		case Basic_cstring:
			return tb_debug_create_ptr(m->mod, tb_debug_get_integer(m->mod, false, 8));

		case Basic_any:
			{
				String name = basic_types[type->Basic.kind].Basic.name;
				TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
				// @QuaternionLayout
				TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 2);
				fields[0] = tb_debug_create_field(m->mod, cg_debug_type(m, t_rawptr), -1, "data", 0*ptr_size);
				fields[1] = tb_debug_create_field(m->mod, cg_debug_type(m, t_typeid), -1, "id",   1*ptr_size);

				tb_debug_record_end(record, size, align);
				return record;
			}
		case Basic_typeid: return tb_debug_get_integer(m->mod, false, bits);

		case Basic_i16le:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u16le:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i32le:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u32le:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i64le:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u64le:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i128le:        return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u128le:        return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i16be:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u16be:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i32be:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u32be:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i64be:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u64be:         return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_i128be:        return tb_debug_get_integer(m->mod, is_signed, bits);
		case Basic_u128be:        return tb_debug_get_integer(m->mod, is_signed, bits);

		case Basic_f16le:         return tb_debug_get_integer(m->mod, false, bits);
		case Basic_f32le:         return tb_debug_get_float(m->mod,   TB_FLT_32);
		case Basic_f64le:         return tb_debug_get_float(m->mod,   TB_FLT_64);
		case Basic_f16be:         return tb_debug_get_integer(m->mod, false, bits);
		case Basic_f32be:         return tb_debug_get_float(m->mod,   TB_FLT_32);
		case Basic_f64be:         return tb_debug_get_float(m->mod,   TB_FLT_64);
		}
		break;
	case Type_Generic:
		GB_PANIC("SHOULD NEVER HIT");
		break;
	case Type_Pointer:
		return tb_debug_create_ptr(m->mod, cg_debug_type(m, type->Pointer.elem));
	case Type_MultiPointer:
		return tb_debug_create_ptr(m->mod, cg_debug_type(m, type->MultiPointer.elem));
	case Type_Array:
		return tb_debug_create_array(m->mod, cg_debug_type(m, type->Array.elem), type->Array.count);
	case Type_EnumeratedArray:
		return tb_debug_create_array(m->mod, cg_debug_type(m, type->EnumeratedArray.elem), type->EnumeratedArray.count);
	case Type_Slice:
		{
			String name = {};
			TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
			TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 2);
			fields[0] = tb_debug_create_field(m->mod, cg_debug_type(m, alloc_type_pointer(type->Slice.elem)), -1, "data", 0*int_size);
			fields[1] = tb_debug_create_field(m->mod, cg_debug_type(m, t_int),    -1, "len",  1*int_size);

			tb_debug_record_end(record, size, align);
			return record;
		}
	case Type_DynamicArray:
		{
			String name = {};
			TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
			TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 4);
			fields[0] = tb_debug_create_field(m->mod, cg_debug_type(m, alloc_type_pointer(type->Slice.elem)), -1, "data", 0*int_size);
			fields[1] = tb_debug_create_field(m->mod, cg_debug_type(m, t_int),       -1, "len",        1*int_size);
			fields[2] = tb_debug_create_field(m->mod, cg_debug_type(m, t_int),       -1, "cap",        2*int_size);
			fields[3] = tb_debug_create_field(m->mod, cg_debug_type(m, t_allocator), -1, "allocator",  3*int_size);

			tb_debug_record_end(record, size, align);
			return record;
		}
	case Type_Map:
		return cg_debug_type(m, t_raw_map);

	case Type_Struct:
	case Type_Tuple:
	case Type_Union:
		return cg_debug_type_internal_record(m, type, {});

	case Type_Enum:
		return tb_debug_get_integer(m->mod, is_signed, bits);

	case Type_Proc:
		{
			TypeProc *pt = &type->Proc;
			isize param_count  = 0;
			isize return_count = 0;

			bool is_odin_cc = is_calling_convention_odin(pt->calling_convention);

			if (pt->params) for (Entity *e : pt->params->Tuple.variables) {
				if (e->kind == Entity_Variable) {
					param_count += 1;
				}
			}

			if (pt->result_count > 0) {
				if (is_odin_cc) {
					// Split returns
					param_count += pt->result_count-1;
					return_count = 1;
				} else {
					return_count = 1;
				}
			}

			if (pt->calling_convention == ProcCC_Odin) {
				// `context` ptr
				param_count += 1;
			}

			TB_CallingConv tb_cc = TB_CDECL;
			if (pt->calling_convention == ProcCC_StdCall) {
				tb_cc = TB_STDCALL;
			}
			TB_DebugType *func = tb_debug_create_func(m->mod, tb_cc, param_count, return_count, pt->c_vararg);

			map_set(&m->proc_debug_type_map, original_type, func);
			map_set(&m->proc_debug_type_map, type, func);

			TB_DebugType *func_ptr = tb_debug_create_ptr(m->mod, func);
			map_set(&m->debug_type_map, original_type, func_ptr);
			map_set(&m->debug_type_map, type, func_ptr);

			TB_DebugType **params = tb_debug_func_params(func);
			TB_DebugType **returns = tb_debug_func_returns(func);

			isize param_index = 0;
			isize return_index = 0;
			if (pt->params) for (Entity *e : pt->params->Tuple.variables) {
				if (e->kind == Entity_Variable) {
					Type *type = e->type;
					if (is_type_proc(type)) {
						type = t_rawptr;
					}
					String name = e->token.string;
					if (name.len == 0) {
						name = str_lit("_");
					}
					params[param_index++] = tb_debug_create_field(m->mod, cg_debug_type(m, type), name.len, cast(char const *)name.text, 0);
				}
			}

			if (pt->result_count) {
				GB_ASSERT(pt->results);
				if (is_odin_cc) {
					// Split Returns
					for (isize i = 0; i < pt->results->Tuple.variables.count-1; i++) {
						Entity *e = pt->results->Tuple.variables[i];
						GB_ASSERT(e->kind == Entity_Variable);
						Type *type = e->type;
						if (is_type_proc(e->type)) {
							type = t_rawptr;
						}
						type = alloc_type_pointer(type);

						String name = e->token.string;
						if (name.len == 0) {
							name = str_lit("_");
						}
						params[param_index++] = tb_debug_create_field(m->mod, cg_debug_type(m, type), name.len, cast(char const *)name.text, 0);
					}

					Type *last_type = pt->results->Tuple.variables[pt->results->Tuple.variables.count-1]->type;
					if (is_type_proc(last_type)) {
						last_type = t_rawptr;
					}
					returns[return_index++] = cg_debug_type(m, last_type);
				} else {
					returns[return_index++] = cg_debug_type(m, pt->results);
				}
			}

			if (pt->calling_convention == ProcCC_Odin) {
				Type *type = t_context_ptr;
				String name = str_lit("__.context_ptr");
				params[param_index++] = tb_debug_create_field(m->mod, cg_debug_type(m, type), name.len, cast(char const *)name.text, 0);
			}

			GB_ASSERT_MSG(param_index  == param_count,  "%td vs %td for %s", param_index,  param_count, type_to_string(type));
			GB_ASSERT_MSG(return_index == return_count, "%td vs %td for %s", return_index, return_count, type_to_string(type));

			return func_ptr;
		}
		break;
	case Type_BitSet:
		return cg_debug_type(m, bit_set_to_int(type));
	case Type_SimdVector:
		return tb_debug_create_array(m->mod, cg_debug_type(m, type->SimdVector.elem), type->SimdVector.count);
	case Type_RelativePointer:
		return cg_debug_type(m, type->RelativePointer.base_integer);
	case Type_RelativeMultiPointer:
		return cg_debug_type(m, type->RelativeMultiPointer.base_integer);
	case Type_Matrix:
		{
			i64 count = matrix_type_total_internal_elems(type);
			return tb_debug_create_array(m->mod, cg_debug_type(m, type->Matrix.elem), count);
		}
	case Type_SoaPointer:
		{
			String name = {};
			TB_DebugType *record = tb_debug_create_struct(m->mod, name.len, cast(char const *)name.text);
			TB_DebugType **fields = tb_debug_record_begin(m->mod, record, 2);
			fields[0] = tb_debug_create_field(m->mod, cg_debug_type(m, alloc_type_pointer(type->SoaPointer.elem)), -1, "ptr", 0*int_size);
			fields[1] = tb_debug_create_field(m->mod, cg_debug_type(m, t_int), -1, "offset",  1*int_size);

			tb_debug_record_end(record, size, align);
			return record;
		}
	}

	// TODO(bill): cg_debug_type
	return tb_debug_get_void(m->mod);
}
