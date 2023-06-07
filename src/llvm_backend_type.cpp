gb_internal isize lb_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found=true) {
	auto *set = &info->minimum_dependency_type_info_set;
	isize index = type_info_index(info, type, err_on_not_found);
	if (index >= 0) {
		auto *found = map_get(set, index);
		if (found) {
			GB_ASSERT(*found >= 0);
			return *found + 1;
		}
	}
	if (err_on_not_found) {
		GB_PANIC("NOT FOUND lb_type_info_index %s @ index %td", type_to_string(type), index);
	}
	return -1;
}

gb_internal lbValue lb_typeid(lbModule *m, Type *type) {
	GB_ASSERT(!build_context.disallow_rtti);

	type = default_type(type);

	u64 id = cast(u64)lb_type_info_index(m->info, type);
	GB_ASSERT(id >= 0);

	u64 kind = Typeid_Invalid;
	u64 named = is_type_named(type) && type->kind != Type_Basic;
	u64 special = 0;
	u64 reserved = 0;

	Type *bt = base_type(type);
	TypeKind tk = bt->kind;
	switch (tk) {
	case Type_Basic: {
		u32 flags = bt->Basic.flags;
		if (flags & BasicFlag_Boolean)  kind = Typeid_Boolean;
		if (flags & BasicFlag_Integer)  kind = Typeid_Integer;
		if (flags & BasicFlag_Unsigned) kind = Typeid_Integer;
		if (flags & BasicFlag_Float)    kind = Typeid_Float;
		if (flags & BasicFlag_Complex)  kind = Typeid_Complex;
		if (flags & BasicFlag_Pointer)  kind = Typeid_Pointer;
		if (flags & BasicFlag_String)   kind = Typeid_String;
		if (flags & BasicFlag_Rune)     kind = Typeid_Rune;
	} break;
	case Type_Pointer:         kind = Typeid_Pointer;          break;
	case Type_MultiPointer:    kind = Typeid_Multi_Pointer;    break;
	case Type_Array:           kind = Typeid_Array;            break;
	case Type_Matrix:          kind = Typeid_Matrix;           break;
	case Type_EnumeratedArray: kind = Typeid_Enumerated_Array; break;
	case Type_Slice:           kind = Typeid_Slice;            break;
	case Type_DynamicArray:    kind = Typeid_Dynamic_Array;    break;
	case Type_Map:             kind = Typeid_Map;              break;
	case Type_Struct:          kind = Typeid_Struct;           break;
	case Type_Enum:            kind = Typeid_Enum;             break;
	case Type_Union:           kind = Typeid_Union;            break;
	case Type_Tuple:           kind = Typeid_Tuple;            break;
	case Type_Proc:            kind = Typeid_Procedure;        break;
	case Type_BitSet:          kind = Typeid_Bit_Set;          break;
	case Type_SimdVector:      kind = Typeid_Simd_Vector;      break;
	case Type_RelativePointer: kind = Typeid_Relative_Pointer; break;
	case Type_RelativeSlice:   kind = Typeid_Relative_Slice;   break;
	case Type_SoaPointer:      kind = Typeid_SoaPointer;       break;
	}

	if (is_type_cstring(type)) {
		special = 1;
	} else if (is_type_integer(type) && !is_type_unsigned(type)) {
		special = 1;
	}

	u64 data = 0;
	if (build_context.ptr_size == 4) {
		GB_ASSERT(id <= (1u<<24u));
		data |= (id       &~ (1u<<24)) << 0u;  // index
		data |= (kind     &~ (1u<<5))  << 24u; // kind
		data |= (named    &~ (1u<<1))  << 29u; // named
		data |= (special  &~ (1u<<1))  << 30u; // special
		data |= (reserved &~ (1u<<1))  << 31u; // reserved
	} else {
		GB_ASSERT(build_context.ptr_size == 8);
		GB_ASSERT(id <= (1ull<<56u));
		data |= (id       &~ (1ull<<56)) << 0ul;  // index
		data |= (kind     &~ (1ull<<5))  << 56ull; // kind
		data |= (named    &~ (1ull<<1))  << 61ull; // named
		data |= (special  &~ (1ull<<1))  << 62ull; // special
		data |= (reserved &~ (1ull<<1))  << 63ull; // reserved
	}

	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, t_typeid), data, false);
	res.type = t_typeid;
	return res;
}

gb_internal lbValue lb_type_info(lbModule *m, Type *type) {
	GB_ASSERT(!build_context.disallow_rtti);

	type = default_type(type);

	isize index = lb_type_info_index(m->info, type);
	GB_ASSERT(index >= 0);

	lbValue data = lb_global_type_info_data_ptr(m);
	return lb_emit_array_epi(m, data, index);
}

gb_internal LLVMTypeRef lb_get_procedure_raw_type(lbModule *m, Type *type) {
	return lb_type_internal_for_procedures_raw(m, type);
}


gb_internal lbValue lb_type_info_member_types_offset(lbProcedure *p, isize count) {
	GB_ASSERT(p->module == &p->module->gen->default_module);
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_types.addr, lb_global_type_info_member_types_index);
	lb_global_type_info_member_types_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_names_offset(lbProcedure *p, isize count) {
	GB_ASSERT(p->module == &p->module->gen->default_module);
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_names.addr, lb_global_type_info_member_names_index);
	lb_global_type_info_member_names_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_offsets_offset(lbProcedure *p, isize count) {
	GB_ASSERT(p->module == &p->module->gen->default_module);
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_offsets.addr, lb_global_type_info_member_offsets_index);
	lb_global_type_info_member_offsets_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_usings_offset(lbProcedure *p, isize count) {
	GB_ASSERT(p->module == &p->module->gen->default_module);
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_usings.addr, lb_global_type_info_member_usings_index);
	lb_global_type_info_member_usings_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_tags_offset(lbProcedure *p, isize count) {
	GB_ASSERT(p->module == &p->module->gen->default_module);
	lbValue offset = lb_emit_array_epi(p, lb_global_type_info_member_tags.addr, lb_global_type_info_member_tags_index);
	lb_global_type_info_member_tags_index += cast(i32)count;
	return offset;
}


gb_internal void lb_setup_type_info_data(lbProcedure *p) { // NOTE(bill): Setup type_info data
	if (build_context.disallow_rtti) {
		return;
	}

	lbModule *m = p->module;
	CheckerInfo *info = m->info;
	
	i64 global_type_info_data_entity_count = 0;
	{
		// NOTE(bill): Set the type_table slice with the global backing array
		lbValue global_type_table = lb_find_runtime_value(m, str_lit("type_table"));
		Type *type = base_type(lb_global_type_info_data_entity->type);
		GB_ASSERT(is_type_array(type));
		global_type_info_data_entity_count = type->Array.count;

		LLVMValueRef indices[2] = {llvm_zero(m), llvm_zero(m)};
		LLVMValueRef data = LLVMConstInBoundsGEP2(lb_type(m, lb_global_type_info_data_entity->type), lb_global_type_info_data_ptr(m).value, indices, gb_count_of(indices));
		LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), type->Array.count, true);
		Type *t = type_deref(global_type_table.type);
		GB_ASSERT(is_type_slice(t));
		LLVMValueRef slice = llvm_const_slice_internal(m, data, len);

		LLVMSetInitializer(global_type_table.value, slice);
	}


	// Useful types
	Entity *type_info_flags_entity = find_core_entity(info->checker, str_lit("Type_Info_Flags"));
	Type *t_type_info_flags = type_info_flags_entity->type;

	
	auto entries_handled = slice_make<bool>(heap_allocator(), cast(isize)global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), entries_handled.data));
	entries_handled[0] = true;
	
	for_array(type_info_type_index, info->type_info_types) {
		Type *t = info->type_info_types[type_info_type_index];
		if (t == nullptr || t == t_invalid) {
			continue;
		}

		isize entry_index = lb_type_info_index(info, t, false);
		if (entry_index <= 0) {
			continue;
		}

		if (entries_handled[entry_index]) {
			continue;
		}
		entries_handled[entry_index] = true;

		lbValue global_data_ptr = lb_global_type_info_data_ptr(m);
		lbValue tag = {};
		lbValue ti_ptr = lb_emit_array_epi(p, global_data_ptr, cast(i32)entry_index);
		
		i64 size = type_size_of(t);
		i64 align = type_align_of(t);
		u32 flags = type_info_flags_of_type(t);
		lbValue id = lb_typeid(m, t);
		GB_ASSERT_MSG(align != 0, "%lld %s", align, type_to_string(t));
		
		lbValue type_info_flags = lb_const_int(p->module, t_type_info_flags, flags);
		
		lbValue size_ptr  = lb_emit_struct_ep(p, ti_ptr, 0);
		lbValue align_ptr = lb_emit_struct_ep(p, ti_ptr, 1);
		lbValue flags_ptr = lb_emit_struct_ep(p, ti_ptr, 2);
		lbValue id_ptr    = lb_emit_struct_ep(p, ti_ptr, 3);
				
		lb_emit_store(p, size_ptr,  lb_const_int(m, t_int, size));
		lb_emit_store(p, align_ptr, lb_const_int(m, t_int, align));
		lb_emit_store(p, flags_ptr, type_info_flags);
		lb_emit_store(p, id_ptr,    id);
		
		lbValue variant_ptr = lb_emit_struct_ep(p, ti_ptr, 4);

		switch (t->kind) {
		case Type_Named: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_named_ptr);

			LLVMValueRef pkg_name = nullptr;
			if (t->Named.type_name->pkg) {
				pkg_name = lb_const_string(m, t->Named.type_name->pkg->name).value;
			} else {
				pkg_name = LLVMConstNull(lb_type(m, t_string));
			}

			String proc_name = {};
			if (t->Named.type_name->parent_proc_decl) {
				DeclInfo *decl = t->Named.type_name->parent_proc_decl;
				if (decl->entity && decl->entity->kind == Entity_Procedure) {
					proc_name = decl->entity->token.string;
				}
			}
			TokenPos pos = t->Named.type_name->token.pos;

			lbValue loc = lb_emit_source_code_location_const(p, proc_name, pos);

			LLVMValueRef vals[4] = {
				lb_const_string(p->module, t->Named.type_name->token.string).value,
				lb_type_info(m, t->Named.base).value,
				pkg_name,
				loc.value
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}

		case Type_Basic:
			switch (t->Basic.kind) {
			case Basic_bool:
			case Basic_b8:
			case Basic_b16:
			case Basic_b32:
			case Basic_b64:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_boolean_ptr);
				break;

			case Basic_i8:
			case Basic_u8:
			case Basic_i16:
			case Basic_u16:
			case Basic_i32:
			case Basic_u32:
			case Basic_i64:
			case Basic_u64:
			case Basic_i128:
			case Basic_u128:

			case Basic_i16le:
			case Basic_u16le:
			case Basic_i32le:
			case Basic_u32le:
			case Basic_i64le:
			case Basic_u64le:
			case Basic_i128le:
			case Basic_u128le:
			case Basic_i16be:
			case Basic_u16be:
			case Basic_i32be:
			case Basic_u32be:
			case Basic_i64be:
			case Basic_u64be:
			case Basic_i128be:
			case Basic_u128be:

			case Basic_int:
			case Basic_uint:
			case Basic_uintptr: {
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_integer_ptr);

				lbValue is_signed = lb_const_bool(m, t_bool, (t->Basic.flags & BasicFlag_Unsigned) == 0);
				// NOTE(bill): This is matches the runtime layout
				u8 endianness_value = 0;
				if (t->Basic.flags & BasicFlag_EndianLittle) {
					endianness_value = 1;
				} else if (t->Basic.flags & BasicFlag_EndianBig) {
					endianness_value = 2;
				}
				lbValue endianness = lb_const_int(m, t_u8, endianness_value);

				LLVMValueRef vals[2] = {
					is_signed.value,
					endianness.value,
				};

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
				break;
			}

			case Basic_rune:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_rune_ptr);
				break;

			case Basic_f16:
			case Basic_f32:
			case Basic_f64:
			case Basic_f16le:
			case Basic_f32le:
			case Basic_f64le:
			case Basic_f16be:
			case Basic_f32be:
			case Basic_f64be:
				{
					tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_float_ptr);

					// NOTE(bill): This is matches the runtime layout
					u8 endianness_value = 0;
					if (t->Basic.flags & BasicFlag_EndianLittle) {
						endianness_value = 1;
					} else if (t->Basic.flags & BasicFlag_EndianBig) {
						endianness_value = 2;
					}
					lbValue endianness = lb_const_int(m, t_u8, endianness_value);

					LLVMValueRef vals[1] = {
						endianness.value,
					};

					lbValue res = {};
					res.type = type_deref(tag.type);
					res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
					lb_emit_store(p, tag, res);
				}
				break;

			case Basic_complex32:
			case Basic_complex64:
			case Basic_complex128:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_complex_ptr);
				break;

			case Basic_quaternion64:
			case Basic_quaternion128:
			case Basic_quaternion256:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_quaternion_ptr);
				break;

			case Basic_rawptr:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_pointer_ptr);
				break;

			case Basic_string:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_string_ptr);
				break;

			case Basic_cstring:
				{
					tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_string_ptr);
					LLVMValueRef vals[1] = {
						lb_const_bool(m, t_bool, true).value,
					};

					lbValue res = {};
					res.type = type_deref(tag.type);
					res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
					lb_emit_store(p, tag, res);
				}
				break;

			case Basic_any:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_any_ptr);
				break;

			case Basic_typeid:
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_typeid_ptr);
				break;
			}
			break;

		case Type_Pointer: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_pointer_ptr);
			lbValue gep = lb_type_info(m, t->Pointer.elem);

			LLVMValueRef vals[1] = {
				gep.value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_MultiPointer: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_multi_pointer_ptr);
			lbValue gep = lb_type_info(m, t->MultiPointer.elem);

			LLVMValueRef vals[1] = {
				gep.value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_SoaPointer: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_soa_pointer_ptr);
			lbValue gep = lb_type_info(m, t->SoaPointer.elem);

			LLVMValueRef vals[1] = {
				gep.value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_Array: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_array_ptr);
			i64 ez = type_size_of(t->Array.elem);

			LLVMValueRef vals[3] = {
				lb_type_info(m, t->Array.elem).value,
				lb_const_int(m, t_int, ez).value,
				lb_const_int(m, t_int, t->Array.count).value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_EnumeratedArray: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_enumerated_array_ptr);

			LLVMValueRef vals[7] = {
				lb_type_info(m, t->EnumeratedArray.elem).value,
				lb_type_info(m, t->EnumeratedArray.index).value,
				lb_const_int(m, t_int, type_size_of(t->EnumeratedArray.elem)).value,
				lb_const_int(m, t_int, t->EnumeratedArray.count).value,

				// Unions
				LLVMConstNull(lb_type(m, t_type_info_enum_value)),
				LLVMConstNull(lb_type(m, t_type_info_enum_value)),

				lb_const_bool(m, t_bool, t->EnumeratedArray.is_sparse).value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);

			// NOTE(bill): Union assignment
			lbValue min_value = lb_emit_struct_ep(p, tag, 4);
			lbValue max_value = lb_emit_struct_ep(p, tag, 5);

			lbValue min_v = lb_const_value(m, t_i64, *t->EnumeratedArray.min_value);
			lbValue max_v = lb_const_value(m, t_i64, *t->EnumeratedArray.max_value);

			lb_emit_store(p, min_value, min_v);
			lb_emit_store(p, max_value, max_v);
			break;
		}
		case Type_DynamicArray: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_dynamic_array_ptr);

			LLVMValueRef vals[2] = {
				lb_type_info(m, t->DynamicArray.elem).value,
				lb_const_int(m, t_int, type_size_of(t->DynamicArray.elem)).value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_Slice: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_slice_ptr);

			LLVMValueRef vals[2] = {
				lb_type_info(m, t->Slice.elem).value,
				lb_const_int(m, t_int, type_size_of(t->Slice.elem)).value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_Proc: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_procedure_ptr);

			LLVMValueRef params = LLVMConstNull(lb_type(m, t_type_info_ptr));
			LLVMValueRef results = LLVMConstNull(lb_type(m, t_type_info_ptr));
			if (t->Proc.params != nullptr) {
				params = lb_type_info(m, t->Proc.params).value;
			}
			if (t->Proc.results != nullptr) {
				results = lb_type_info(m, t->Proc.results).value;
			}

			LLVMValueRef vals[4] = {
				params,
				results,
				lb_const_bool(m, t_bool, t->Proc.variadic).value,
				lb_const_int(m, t_u8, t->Proc.calling_convention).value,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}
		case Type_Tuple: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_parameters_ptr);

			lbValue memory_types = lb_type_info_member_types_offset(p, t->Tuple.variables.count);
			lbValue memory_names = lb_type_info_member_names_offset(p, t->Tuple.variables.count);


			for_array(i, t->Tuple.variables) {
				// NOTE(bill): offset is not used for tuples
				Entity *f = t->Tuple.variables[i];

				lbValue index     = lb_const_int(m, t_int, i);
				lbValue type_info = lb_emit_ptr_offset(p, memory_types, index);

				// TODO(bill): Make this constant if possible, 'lb_const_store' does not work
				lb_emit_store(p, type_info, lb_type_info(m, f->type));
				if (f->token.string.len > 0) {
					lbValue name = lb_emit_ptr_offset(p, memory_names, index);
					lb_emit_store(p, name, lb_const_string(m, f->token.string));
				}
			}

			lbValue count = lb_const_int(m, t_int, t->Tuple.variables.count);

			LLVMValueRef types_slice = llvm_const_slice(m, memory_types, count);
			LLVMValueRef names_slice = llvm_const_slice(m, memory_names, count);

			LLVMValueRef vals[2] = {
				types_slice,
				names_slice,
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);

			break;
		}

		case Type_Enum:
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_enum_ptr);

			{
				GB_ASSERT(t->Enum.base_type != nullptr);
				// GB_ASSERT_MSG(type_size_of(t_type_info_enum_value) == 16, "%lld == 16", cast(long long)type_size_of(t_type_info_enum_value));


				LLVMValueRef vals[3] = {};
				vals[0] = lb_type_info(m, t->Enum.base_type).value;
				if (t->Enum.fields.count > 0) {
					auto fields = t->Enum.fields;
					lbValue name_array  = lb_generate_global_array(m, t_string, fields.count,
					                                        str_lit("$enum_names"), cast(i64)entry_index);
					lbValue value_array = lb_generate_global_array(m, t_type_info_enum_value, fields.count,
					                                        str_lit("$enum_values"), cast(i64)entry_index);


					LLVMValueRef *name_values = gb_alloc_array(temporary_allocator(), LLVMValueRef, fields.count);
					LLVMValueRef *value_values = gb_alloc_array(temporary_allocator(), LLVMValueRef, fields.count);

					GB_ASSERT(is_type_integer(t->Enum.base_type));

					for_array(i, fields) {
						name_values[i] = lb_const_string(m, fields[i]->token.string).value;
						value_values[i] = lb_const_value(m, t_i64, fields[i]->Constant.value).value;
					}

					LLVMValueRef name_init  = llvm_const_array(lb_type(m, t_string),               name_values,  cast(unsigned)fields.count);
					LLVMValueRef value_init = llvm_const_array(lb_type(m, t_type_info_enum_value), value_values, cast(unsigned)fields.count);
					LLVMSetInitializer(name_array.value,  name_init);
					LLVMSetInitializer(value_array.value, value_init);
					LLVMSetGlobalConstant(name_array.value, true);
					LLVMSetGlobalConstant(value_array.value, true);

					lbValue v_count = lb_const_int(m, t_int, fields.count);

					vals[1] = llvm_const_slice(m, lb_array_elem(p, name_array), v_count);
					vals[2] = llvm_const_slice(m, lb_array_elem(p, value_array), v_count);
				} else {
					vals[1] = LLVMConstNull(lb_type(m, base_type(t_type_info_enum)->Struct.fields[1]->type));
					vals[2] = LLVMConstNull(lb_type(m, base_type(t_type_info_enum)->Struct.fields[2]->type));
				}


				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}
			break;

		case Type_Union: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_union_ptr);

			{
				LLVMValueRef vals[7] = {};

				isize variant_count = gb_max(0, t->Union.variants.count);
				lbValue memory_types = lb_type_info_member_types_offset(p, variant_count);

				// NOTE(bill): Zeroth is nil so ignore it
				for (isize variant_index = 0; variant_index < variant_count; variant_index++) {
					Type *vt = t->Union.variants[variant_index];
					lbValue tip = lb_type_info(m, vt);

					lbValue index     = lb_const_int(m, t_int, variant_index);
					lbValue type_info = lb_emit_ptr_offset(p, memory_types, index);
					lb_emit_store(p, type_info, lb_type_info(m, vt));
				}

				lbValue count = lb_const_int(m, t_int, variant_count);
				vals[0] = llvm_const_slice(m, memory_types, count);

				i64 tag_size   = union_tag_size(t);
				i64 tag_offset = align_formula(t->Union.variant_block_size, tag_size);

				if (tag_size > 0) {
					vals[1] = lb_const_int(m, t_uintptr, tag_offset).value;
					vals[2] = lb_type_info(m, union_tag_type(t)).value;
				} else {
					vals[1] = lb_const_int(m, t_uintptr, 0).value;
					vals[2] = LLVMConstNull(lb_type(m, t_type_info_ptr));
				}

				if (is_type_comparable(t) && !is_type_simple_compare(t)) {
					vals[3] = lb_equal_proc_for_type(m, t).value;
				}

				vals[4] = lb_const_bool(m, t_bool, t->Union.custom_align != 0).value;
				vals[5] = lb_const_bool(m, t_bool, t->Union.kind == UnionType_no_nil).value;
				vals[6] = lb_const_bool(m, t_bool, t->Union.kind == UnionType_shared_nil).value;

				for (isize i = 0; i < gb_count_of(vals); i++) {
					if (vals[i] == nullptr) {
						vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag.type, i)));
					}
				}

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}

			break;
		}

		case Type_Struct: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_struct_ptr);

			LLVMValueRef vals[13] = {};


			{
				lbValue is_packed       = lb_const_bool(m, t_bool, t->Struct.is_packed);
				lbValue is_raw_union    = lb_const_bool(m, t_bool, t->Struct.is_raw_union);
				lbValue is_no_copy      = lb_const_bool(m, t_bool, t->Struct.is_no_copy);
				lbValue is_custom_align = lb_const_bool(m, t_bool, t->Struct.custom_align != 0);
				vals[5] = is_packed.value;
				vals[6] = is_raw_union.value;
				vals[7] = is_no_copy.value;
				vals[8] = is_custom_align.value;
				if (is_type_comparable(t) && !is_type_simple_compare(t)) {
					vals[9] = lb_equal_proc_for_type(m, t).value;
				}


				if (t->Struct.soa_kind != StructSoa_None) {
					lbValue kind = lb_emit_struct_ep(p, tag, 10);
					Type *kind_type = type_deref(kind.type);

					lbValue soa_kind = lb_const_value(m, kind_type, exact_value_i64(t->Struct.soa_kind));
					lbValue soa_type = lb_type_info(m, t->Struct.soa_elem);
					lbValue soa_len = lb_const_int(m, t_int, t->Struct.soa_count);

					vals[10] = soa_kind.value;
					vals[11] = soa_type.value;
					vals[12] = soa_len.value;
				}
			}
			
			isize count = t->Struct.fields.count;
			if (count > 0) {
				lbValue memory_types   = lb_type_info_member_types_offset  (p, count);
				lbValue memory_names   = lb_type_info_member_names_offset  (p, count);
				lbValue memory_offsets = lb_type_info_member_offsets_offset(p, count);
				lbValue memory_usings  = lb_type_info_member_usings_offset (p, count);
				lbValue memory_tags    = lb_type_info_member_tags_offset   (p, count);

				type_set_offsets(t); // NOTE(bill): Just incase the offsets have not been set yet
				for (isize source_index = 0; source_index < count; source_index++) {
					// TODO(bill): Order fields in source order not layout order
					Entity *f = t->Struct.fields[source_index];
					lbValue tip = lb_type_info(m, f->type);
					i64 foffset = 0;
					if (!t->Struct.is_raw_union) {
						GB_ASSERT(t->Struct.offsets != nullptr);
						GB_ASSERT(0 <= f->Variable.field_index && f->Variable.field_index < count);
						foffset = t->Struct.offsets[source_index];
					}
					GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);

					lbValue index     = lb_const_int(m, t_int, source_index);
					lbValue type_info = lb_emit_ptr_offset(p, memory_types,   index);
					lbValue offset    = lb_emit_ptr_offset(p, memory_offsets, index);
					lbValue is_using  = lb_emit_ptr_offset(p, memory_usings,  index);

					lb_emit_store(p, type_info, lb_type_info(m, f->type));
					if (f->token.string.len > 0) {
						lbValue name = lb_emit_ptr_offset(p, memory_names,   index);
						lb_emit_store(p, name, lb_const_string(m, f->token.string));
					}
					lb_emit_store(p, offset, lb_const_int(m, t_uintptr, foffset));
					lb_emit_store(p, is_using, lb_const_bool(m, t_bool, (f->flags&EntityFlag_Using) != 0));

					if (t->Struct.tags != nullptr) {
						String tag_string = t->Struct.tags[source_index];
						if (tag_string.len > 0) {
							lbValue tag_ptr = lb_emit_ptr_offset(p, memory_tags, index);
							lb_emit_store(p, tag_ptr, lb_const_string(m, tag_string));
						}
					}

				}

				lbValue cv = lb_const_int(m, t_int, count);
				vals[0] = llvm_const_slice(m, memory_types,   cv);
				vals[1] = llvm_const_slice(m, memory_names,   cv);
				vals[2] = llvm_const_slice(m, memory_offsets, cv);
				vals[3] = llvm_const_slice(m, memory_usings,  cv);
				vals[4] = llvm_const_slice(m, memory_tags,    cv);
			}
			for (isize i = 0; i < gb_count_of(vals); i++) {
				if (vals[i] == nullptr) {
					vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag.type, i)));
				}
			}
			
			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);

			break;
		}

		case Type_Map: {
			tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_map_ptr);
			init_map_internal_types(t);

			LLVMValueRef vals[3] = {
				lb_type_info(m, t->Map.key).value,
				lb_type_info(m, t->Map.value).value,
				lb_gen_map_info_ptr(p->module, t).value
			};

			lbValue res = {};
			res.type = type_deref(tag.type);
			res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
			lb_emit_store(p, tag, res);
			break;
		}

		case Type_BitSet:
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_bit_set_ptr);

				GB_ASSERT(is_type_typed(t->BitSet.elem));


				LLVMValueRef vals[4] = {
					lb_type_info(m, t->BitSet.elem).value,
					LLVMConstNull(lb_type(m, t_type_info_ptr)),
					lb_const_int(m, t_i64, t->BitSet.lower).value,
					lb_const_int(m, t_i64, t->BitSet.upper).value,
				};
				if (t->BitSet.underlying != nullptr) {
					vals[1] =lb_type_info(m, t->BitSet.underlying).value;
				}

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}
			break;

		case Type_SimdVector:
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_simd_vector_ptr);

				LLVMValueRef vals[3] = {};

				vals[0] = lb_type_info(m, t->SimdVector.elem).value;
				vals[1] = lb_const_int(m, t_int, type_size_of(t->SimdVector.elem)).value;
				vals[2] = lb_const_int(m, t_int, t->SimdVector.count).value;

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}
			break;

		case Type_RelativePointer:
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_relative_pointer_ptr);
				LLVMValueRef vals[2] = {
					lb_type_info(m, t->RelativePointer.pointer_type).value,
					lb_type_info(m, t->RelativePointer.base_integer).value,
				};

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}
			break;
		case Type_RelativeSlice:
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_relative_slice_ptr);
				LLVMValueRef vals[2] = {
					lb_type_info(m, t->RelativeSlice.slice_type).value,
					lb_type_info(m, t->RelativeSlice.base_integer).value,
				};

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}
			break;
		case Type_Matrix: 
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_matrix_ptr);
				i64 ez = type_size_of(t->Matrix.elem);

				LLVMValueRef vals[5] = {
					lb_type_info(m, t->Matrix.elem).value,
					lb_const_int(m, t_int, ez).value,
					lb_const_int(m, t_int, matrix_type_stride_in_elems(t)).value,
					lb_const_int(m, t_int, t->Matrix.row_count).value,
					lb_const_int(m, t_int, t->Matrix.column_count).value,
				};

				lbValue res = {};
				res.type = type_deref(tag.type);
				res.value = llvm_const_named_struct(m, res.type, vals, gb_count_of(vals));
				lb_emit_store(p, tag, res);
			}
			break;
		}


		if (tag.value != nullptr) {
			Type *tag_type = type_deref(tag.type);
			GB_ASSERT(is_type_named(tag_type));
			// lb_emit_store_union_variant(p, variant_ptr, lb_emit_load(p, tag), tag_type);
			lb_emit_store_union_variant_tag(p, variant_ptr, tag_type);
		} else {
			if (t != t_llvm_bool) {
				GB_PANIC("Unhandled Type_Info variant: %s", type_to_string(t));
			}
		}
	}
	
	for_array(i, entries_handled) {
		if (!entries_handled[i]) {
			GB_PANIC("UNHANDLED ENTRY %td (%td)", i, entries_handled.count);
		}
	}
}
