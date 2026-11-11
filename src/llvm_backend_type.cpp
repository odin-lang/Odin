
gb_internal void lb_set_odin_rtti_section(LLVMValueRef value) {
	if (build_context.metrics.os != TargetOs_darwin) {
		LLVMSetSection(value, ".odinti");
	}
}

gb_internal isize lb_type_info_index(CheckerInfo *info, TypeInfoPair pair, bool err_on_not_found=true) {
	isize index = type_info_index(info, pair, err_on_not_found);
	if (index >= 0) {
		return index;
	}
	if (err_on_not_found) {
		gb_printf_err("NOT FOUND lb_type_info_index:\n\t%s\n\t@ index %td\n\tmax count: %u\nFound:\n", type_to_string(pair.type), index, info->min_dep_type_info_index_map.count);
		for (auto const &entry : info->min_dep_type_info_index_map) {
			isize type_info_index = entry.key;
			gb_printf_err("\t%s\n", type_to_string(info->type_info_types_hash_map[type_info_index].type));
		}
		GB_PANIC("NOT FOUND");
	}
	return -1;
}

gb_internal isize lb_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found=true) {
	return lb_type_info_index(info, {type, type_hash_canonical_type(type)}, err_on_not_found);
}

gb_internal Type *lb_type_info_record_type(Type *t) {
	switch (t->kind) {
	case Type_Named: return t_type_info_named;

	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_bool:
		case Basic_b8:
		case Basic_b16:
		case Basic_b32:
		case Basic_b64:
			return t_type_info_boolean;

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
		case Basic_uintptr:
			return t_type_info_integer;

		case Basic_rune:
			return t_type_info_rune;

		case Basic_f16:
		case Basic_f32:
		case Basic_f64:
		case Basic_f16le:
		case Basic_f32le:
		case Basic_f64le:
		case Basic_f16be:
		case Basic_f32be:
		case Basic_f64be:
			return t_type_info_float;

		case Basic_complex32:
		case Basic_complex64:
		case Basic_complex128:
			return t_type_info_complex;

		case Basic_quaternion64:
		case Basic_quaternion128:
		case Basic_quaternion256:
			return t_type_info_quaternion;

		case Basic_rawptr:
			return t_type_info_pointer;

		case Basic_string:
		case Basic_cstring:
		case Basic_string16:
		case Basic_cstring16:
			return t_type_info_string;

		case Basic_any:
			return t_type_info_any;

		case Basic_typeid:
			return t_type_info_typeid;
		}
		return nullptr;

	case Type_Pointer:                   return t_type_info_pointer;
	case Type_MultiPointer:              return t_type_info_multi_pointer;
	case Type_SoaPointer:                return t_type_info_soa_pointer;
	case Type_Array:                     return t_type_info_array;
	case Type_EnumeratedArray:           return t_type_info_enumerated_array;
	case Type_DynamicArray:              return t_type_info_dynamic_array;
	case Type_FixedCapacityDynamicArray: return t_type_info_fixed_capacity_dynamic_array;
	case Type_Slice:                     return t_type_info_slice;
	case Type_Proc:                      return t_type_info_procedure;
	case Type_Tuple:                     return t_type_info_parameters;
	case Type_Enum:                      return t_type_info_enum;
	case Type_Union:                     return t_type_info_union;
	case Type_Struct:                    return t_type_info_struct;
	case Type_Map:                       return t_type_info_map;
	case Type_BitSet:                    return t_type_info_bit_set;
	case Type_SimdVector:                return t_type_info_simd_vector;
	case Type_Matrix:                    return t_type_info_matrix;
	case Type_BitField:                  return t_type_info_bit_field;
	}
	return nullptr;
}

gb_internal lbValue lb_typeid(lbModule *m, Type *type) {
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);

	u64 data = type_hash_canonical_type(type);
	GB_ASSERT(data != 0);

	lbValue res = {};
	res.value = LLVMConstInt(lb_type(m, t_typeid), data, false);
	res.type = t_typeid;
	return res;
}

gb_internal lbValue lb_type_info(lbProcedure *p, Type *type) {
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);
	lbModule *m = p->module;

	isize index = lb_type_info_index(m->info, type);
	GB_ASSERT(index >= 0);

	lbValue global = lb_global_type_info_data_ptr(m);

	lbValue ptr = lb_emit_array_epi(p, global, index);
	return lb_emit_load(p, ptr);
}

gb_internal LLVMTypeRef lb_get_procedure_raw_type(lbModule *m, Type *type) {
	return lb_type_internal_for_procedures_raw(m, type);
}

gb_internal lbValue lb_const_array_epi(lbModule *m, lbValue value, isize index) {
	GB_ASSERT(is_type_pointer(value.type));
	Type *type = type_deref(value.type);

	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(m, t_int), 0, false),
		LLVMConstInt(lb_type(m, t_int), cast(unsigned long long)index, false),
	};
	LLVMTypeRef llvm_type = lb_type(m, type);
	lbValue res = {};
	Type *ptr = base_array_type(type);
	res.type = alloc_type_pointer(ptr);
	GB_ASSERT(LLVMIsConstant(value.value));
	res.value = LLVMConstGEP2(llvm_type, value.value, indices, gb_count_of(indices));
	return res;
}


gb_internal bool lb_type_info_has_tags(Type *t) {
	String *tags = nullptr;
	isize   count = 0;
	switch (t->kind) {
	case Type_Struct:
		tags  = t->Struct.tags;
		count = t->Struct.fields.count;
		break;
	case Type_BitField:
		tags  = t->BitField.tags;
		count = t->BitField.fields.count;
		break;
	}
	if (tags == nullptr) {
		return false;
	}
	for (isize i = 0; i < count; i++) {
		if (tags[i].len > 0) {
			return true;
		}
	}
	return false;
}

gb_internal bool lb_type_info_struct_has_usings(Type *t) {
	GB_ASSERT(t->kind == Type_Struct);
	for (Entity *f : t->Struct.fields) {
		if (f->flags & EntityFlag_Using) {
			return true;
		}
	}
	return false;
}

gb_internal bool lb_type_info_enum_values_are_indices(Type *t) {
	GB_ASSERT(t->kind == Type_Enum);
	for_array(i, t->Enum.fields) {
		if (exact_value_to_i64(t->Enum.fields[i]->Constant.value) != i) {
			return false;
		}
	}
	return true;
}

gb_internal lbValue lb_type_info_member_offset(lbModule *m, lbAddr const &buffer, isize *index, isize count, i64 *offset_) {
	GB_ASSERT_MSG(*index + count <= type_deref(buffer.addr.type)->Array.count, "%td + %td > %lld", *index, count, cast(long long)type_deref(buffer.addr.type)->Array.count);
	if (offset_) *offset_ = *index;
	lbValue offset = lb_const_array_epi(m, buffer.addr, *index);
	*index += count;
	return offset;
}
gb_internal lbValue lb_type_info_member_types_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	return lb_type_info_member_offset(m, members->types, &members->types_index, count, offset_);
}
gb_internal lbValue lb_type_info_member_names_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	return lb_type_info_member_offset(m, members->names, &members->names_index, count, offset_);
}
gb_internal lbValue lb_type_info_member_offsets_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	return lb_type_info_member_offset(m, members->offsets, &members->offsets_index, count, offset_);
}
gb_internal lbValue lb_type_info_member_usings_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	return lb_type_info_member_offset(m, members->usings, &members->usings_index, count, offset_);
}
gb_internal lbValue lb_type_info_member_tags_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	return lb_type_info_member_offset(m, members->tags, &members->tags_index, count, offset_);
}

gb_internal lbValue lb_type_info_member_empty_usings(lbModule *m, isize count) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	GB_ASSERT(count <= members->empty_usings_count);
	return lb_const_array_epi(m, members->usings.addr, 0);
}
gb_internal lbValue lb_type_info_member_empty_tags(lbModule *m, isize count) {
	lbTypeInfoMembers *members = m->type_info_members;
	GB_ASSERT(members != nullptr);
	GB_ASSERT(count <= members->empty_tags_count);
	return lb_const_array_epi(m, members->tags.addr, 0);
}

gb_internal void lb_setup_type_info_data_giant_array(lbModule *m, i64 global_type_info_data_entity_count) { // NOTE(bill): Setup type_info data
	auto const &ADD_GLOBAL_TYPE_INFO_ENTRY = [](lbModule *m, LLVMTypeRef type, isize index) -> LLVMValueRef {
		char name[64] = {};
		gb_snprintf(name, 63, "__$ti-%lld", cast(long long)index);
		LLVMValueRef g = LLVMAddGlobal(m->mod, type, name);
		if (m->gen->type_info_modules.count > 1) {
			LLVMSetLinkage(g, LLVMExternalLinkage);
			LLVMSetVisibility(g, LLVMHiddenVisibility);
			LLVMSetGlobalConstant(g, true);
		} else {
			lb_make_global_private_const(g);
		}
		LLVMSetAlignment(g, cast(unsigned)type_align_of(t_type_info));
		lb_set_odin_rtti_section(g);
		return g;
	};
	auto const &DECLARE_GLOBAL_TYPE_INFO_ENTRY = [](lbModule *m, LLVMTypeRef type, isize index) -> LLVMValueRef {
		char name[64] = {};
		gb_snprintf(name, 63, "__$ti-%lld", cast(long long)index);
		LLVMValueRef g = LLVMAddGlobal(m->mod, type, name);
		LLVMSetLinkage(g, LLVMExternalLinkage);
		LLVMSetVisibility(g, LLVMHiddenVisibility);
		LLVMSetGlobalConstant(g, true);
		LLVMSetAlignment(g, cast(unsigned)type_align_of(t_type_info));
		return g;
	};

	CheckerInfo *info = m->info;

	lbTypeInfoMembers *members = m->type_info_members;
	bool is_default_module = m == &m->gen->default_module;
	isize part_count = m->gen->type_info_modules.count;
	auto const owns = [&](isize entry_index) -> bool {
		return members != nullptr && entry_index % part_count == m->type_info_part;
	};

	// Useful types
	Entity *type_info_flags_entity = find_core_entity(info->checker, str_lit("Type_Info_Flags"));
	Type *t_type_info_flags = type_info_flags_entity->type;
	gb_unused(t_type_info_flags);

	GB_ASSERT(t_type_info_variant != nullptr);

	auto entries_handled = slice_make<bool>(heap_allocator(), cast(isize)global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), entries_handled.data));
	entries_handled[0] = true;

	LLVMValueRef *giant_const_values = gb_alloc_array(heap_allocator(), LLVMValueRef, global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), giant_const_values));

	if (owns(0)) {
		giant_const_values[0] = ADD_GLOBAL_TYPE_INFO_ENTRY(m, lb_type(m, t_type_info), 0);
		LLVMSetInitializer(giant_const_values[0], LLVMConstNull(lb_type(m, t_type_info)));
	} else if (is_default_module) {
		giant_const_values[0] = DECLARE_GLOBAL_TYPE_INFO_ENTRY(m, lb_type(m, t_type_info), 0);
	}


	auto const entry_type = [&](Type *t) -> LLVMTypeRef {
		Type *rec = lb_type_info_record_type(t);
		return lb_type(m, rec ? rec : t_type_info);
	};
	for_array(type_info_type_index, info->type_info_types_hash_map) {
		auto const &tt = info->type_info_types_hash_map[type_info_type_index];
		Type *t = tt.type;
		if (t == nullptr || t == t_invalid) {
			continue;
		}

		isize entry_index = lb_type_info_index(info, tt, false);
		if (entry_index <= 0) {
			continue;
		}

		if (entries_handled[entry_index]) {
			continue;
		}
		entries_handled[entry_index] = true;


		if (owns(entry_index)) {
			giant_const_values[entry_index] = ADD_GLOBAL_TYPE_INFO_ENTRY(m, entry_type(t), entry_index);
		} else if (is_default_module) {
			giant_const_values[entry_index] = DECLARE_GLOBAL_TYPE_INFO_ENTRY(m, entry_type(t), entry_index);
		}
	}
	for (isize i = 1; i < global_type_info_data_entity_count; i++) {
		entries_handled[i] = false;
	}


	#define type_info_allocate_values(field) \
		LLVMValueRef *member_##field##_values = nullptr;                                                                         \
		if (members != nullptr) {                                                                                              \
			member_##field##_values = gb_alloc_array(heap_allocator(), LLVMValueRef, type_deref(members->field.addr.type)->Array.count); \
		}                                                                                                                      \
		defer ({                                                                                                               \
			if (members != nullptr) {                                                                                      \
				Type *at = type_deref(members->field.addr.type);                                                       \
				LLVMTypeRef elem = lb_type(m, at->Array.elem);                                                         \
				for (i64 i = 0; i < at->Array.count; i++) {                                                            \
					if ((member_##field##_values)[i] == nullptr) {                                                 \
						(member_##field##_values)[i] = LLVMConstNull(elem);                                    \
					}                                                                                              \
				}                                                                                                      \
				LLVMSetInitializer(members->field.addr.value, llvm_const_array(m, elem, member_##field##_values, at->Array.count)); \
				gb_free(heap_allocator(), member_##field##_values);                                                    \
			}                                                                                                              \
		})

	type_info_allocate_values(types);
	type_info_allocate_values(names);
	type_info_allocate_values(offsets);
	type_info_allocate_values(usings);
	type_info_allocate_values(tags);


	auto const get_type_info_ptr = [&](lbModule *m, Type *type) -> LLVMValueRef {
		type = default_type(type);

		isize index = lb_type_info_index(m->info, type);
		GB_ASSERT(index >= 0);

		if (giant_const_values[index] == nullptr) {
			giant_const_values[index] = DECLARE_GLOBAL_TYPE_INFO_ENTRY(m, entry_type(info->type_info_types_hash_map[index].type), index);
		}
		return giant_const_values[index];
	};

	for_array(type_info_type_index, info->type_info_types_hash_map) {
		Type *t = info->type_info_types_hash_map[type_info_type_index].type;
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
		if (!owns(entry_index)) {
			continue;
		}

		Type *rec = lb_type_info_record_type(t);

		i64 size = type_size_of(t);
		i64 align = type_align_of(t);
		u32 flags = type_info_flags_of_type(t);
		lbValue id = lb_typeid(m, t);
		GB_ASSERT_MSG(align != 0, "%lld %s", align, type_to_string(t));

		lbValue type_info_flags = lb_const_int(m, t_type_info_flags, flags);

		LLVMValueRef header = nullptr;
		{
			LLVMTypeRef variant_type = lb_type(m, t_type_info_variant);
			LLVMValueRef variant = LLVMConstNull(variant_type);
			if (rec != nullptr) {
				i64 tag_index = union_variant_index_checked(t_type_info_variant, alloc_type_pointer(rec));
				GB_ASSERT(0 < tag_index && tag_index <= Typeid__COUNT);

				unsigned variant_elem_count = LLVMCountStructElementTypes(variant_type);
				GB_ASSERT(variant_elem_count >= 2);
				LLVMValueRef *variant_values = gb_alloc_array(temporary_allocator(), LLVMValueRef, variant_elem_count);
				for (unsigned i = 0; i < variant_elem_count; i++) {
					variant_values[i] = LLVMConstNull(LLVMStructGetTypeAtIndex(variant_type, i));
				}
				variant_values[0] = giant_const_values[entry_index];
				variant_values[1] = LLVMConstInt(LLVMStructGetTypeAtIndex(variant_type, 1), tag_index, false);
				variant = LLVMConstNamedStruct(variant_type, variant_values, variant_elem_count);
			}

			LLVMValueRef header_values[5] = {
				LLVMConstInt(lb_type(m, t_int), size, true),
				LLVMConstInt(lb_type(m, t_int), align, true),
				type_info_flags.value,
				id.value,
				variant,
			};
			header = llvm_const_named_struct(m, t_type_info, header_values, gb_count_of(header_values));
		}

		auto const make_record = [&](Type *record_type, LLVMValueRef *vals, isize val_count) -> LLVMValueRef {
			Type *bt = base_type(record_type);
			GB_ASSERT(bt->kind == Type_Struct);
			isize field_count = bt->Struct.fields.count;
			GB_ASSERT(val_count+1 <= field_count);

			LLVMValueRef *values = gb_alloc_array(temporary_allocator(), LLVMValueRef, field_count);
			values[0] = header;
			for (isize i = 0; i < val_count; i++) {
				values[i+1] = vals[i];
			}
			for (isize i = 1; i < field_count; i++) {
				if (values[i] == nullptr) {
					values[i] = LLVMConstNull(lb_type(m, bt->Struct.fields[i]->type));
				}
			}
			return llvm_const_named_struct(m, record_type, values, field_count);
		};

		LLVMValueRef variant_value = nullptr;
		Type *tag_type = nullptr;

		switch (t->kind) {
		case Type_Named: {
			tag_type = t_type_info_named;

			LLVMValueRef pkg_name = nullptr;
			if (t->Named.type_name->pkg) {
				pkg_name = lb_const_string(m, t->Named.type_name->pkg->name).value;
			} else {
				pkg_name = LLVMConstNull(lb_type(m, t_string));
			}

			String proc_name = {};
			if (t->Named.type_name->parent_proc_decl) {
				DeclInfo *decl = t->Named.type_name->parent_proc_decl;
				Entity *e = decl->entity.load();
				if (e && e->kind == Entity_Procedure) {
					proc_name = e->token.string;
				}
			}
			TokenPos pos = t->Named.type_name->token.pos;

			lbValue loc = lb_const_source_code_location_as_global_ptr(m, proc_name, pos);

			LLVMValueRef vals[4] = {
				lb_const_string(m, t->Named.type_name->token.string).value,
				get_type_info_ptr(m, t->Named.base),
				pkg_name,
				loc.value
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}

		case Type_Basic:
			switch (t->Basic.kind) {
			case Basic_bool:
			case Basic_b8:
			case Basic_b16:
			case Basic_b32:
			case Basic_b64:
				tag_type = t_type_info_boolean;
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
				tag_type = t_type_info_integer;

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

				variant_value = make_record(tag_type, vals, gb_count_of(vals));
				break;
			}

			case Basic_rune:
				tag_type = t_type_info_rune;
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
					tag_type = t_type_info_float;

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

					variant_value = make_record(tag_type, vals, gb_count_of(vals));
				}
				break;

			case Basic_complex32:
			case Basic_complex64:
			case Basic_complex128:
				tag_type = t_type_info_complex;
				break;

			case Basic_quaternion64:
			case Basic_quaternion128:
			case Basic_quaternion256:
				tag_type = t_type_info_quaternion;
				break;

			case Basic_rawptr:
				tag_type = t_type_info_pointer;
				break;

			case Basic_string:
				{
					tag_type = t_type_info_string;
					LLVMValueRef vals[2] = {
						lb_const_bool(m, t_bool, false).value,
						lb_const_int(m, t_type_info_string_encoding_kind, 0).value,
					};

					variant_value = make_record(tag_type, vals, gb_count_of(vals));
				}
				break;

			case Basic_cstring:
				{
					tag_type = t_type_info_string;
					LLVMValueRef vals[2] = {
						lb_const_bool(m, t_bool, true).value,
						lb_const_int(m, t_type_info_string_encoding_kind, 0).value,
					};

					variant_value = make_record(tag_type, vals, gb_count_of(vals));
				}
				break;

			case Basic_string16:
				{
					tag_type = t_type_info_string;
					LLVMValueRef vals[2] = {
						lb_const_bool(m, t_bool, false).value,
						lb_const_int(m, t_type_info_string_encoding_kind, 1).value,
					};

					variant_value = make_record(tag_type, vals, gb_count_of(vals));
				}
				break;


			case Basic_cstring16:
				{
					tag_type = t_type_info_string;
					LLVMValueRef vals[2] = {
						lb_const_bool(m, t_bool, true).value,
						lb_const_int(m, t_type_info_string_encoding_kind, 1).value,
					};

					variant_value = make_record(tag_type, vals, gb_count_of(vals));
				}
				break;

			case Basic_any:
				tag_type = t_type_info_any;
				break;

			case Basic_typeid:
				tag_type = t_type_info_typeid;
				break;
			}
			break;

		case Type_Pointer: {
			tag_type = t_type_info_pointer;
			LLVMValueRef vals[1] = {
				get_type_info_ptr(m, t->Pointer.elem),
			};


			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_MultiPointer: {
			tag_type = t_type_info_multi_pointer;

			LLVMValueRef vals[1] = {
				get_type_info_ptr(m, t->MultiPointer.elem),
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_SoaPointer: {
			tag_type = t_type_info_soa_pointer;

			LLVMValueRef vals[1] = {
				get_type_info_ptr(m, t->SoaPointer.elem),
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_Array: {
			tag_type = t_type_info_array;
			i64 ez = type_size_of(t->Array.elem);

			LLVMValueRef vals[3] = {
				get_type_info_ptr(m, t->Array.elem),
				lb_const_int(m, t_int, ez).value,
				lb_const_int(m, t_int, t->Array.count).value,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_EnumeratedArray: {
			tag_type = t_type_info_enumerated_array;

			LLVMValueRef vals[7] = {
				get_type_info_ptr(m, t->EnumeratedArray.elem),
				get_type_info_ptr(m, t->EnumeratedArray.index),
				lb_const_int(m, t_int, type_size_of(t->EnumeratedArray.elem)).value,
				lb_const_int(m, t_int, t->EnumeratedArray.count).value,

				// Unions
				lb_const_value(m, t_type_info_enum_value, *t->EnumeratedArray.min_value).value,
				lb_const_value(m, t_type_info_enum_value, *t->EnumeratedArray.max_value).value,

				lb_const_bool(m, t_bool, t->EnumeratedArray.is_sparse).value,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_DynamicArray: {
			tag_type = t_type_info_dynamic_array;

			LLVMValueRef vals[2] = {
				get_type_info_ptr(m, t->DynamicArray.elem),
				lb_const_int(m, t_int, type_size_of(t->DynamicArray.elem)).value,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_FixedCapacityDynamicArray: {
			tag_type = t_type_info_fixed_capacity_dynamic_array;

			i64 len_offset = type_offset_of(t, 1);

			LLVMValueRef vals[4] = {
				get_type_info_ptr(m, t->FixedCapacityDynamicArray.elem),
				lb_const_int(m, t_int, type_size_of(t->FixedCapacityDynamicArray.elem)).value,
				lb_const_int(m, t_int, t->FixedCapacityDynamicArray.capacity).value,
				lb_const_int(m, t_uintptr, len_offset).value,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_Slice: {
			tag_type = t_type_info_slice;

			LLVMValueRef vals[2] = {
				get_type_info_ptr(m, t->Slice.elem),
				lb_const_int(m, t_int, type_size_of(t->Slice.elem)).value,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_Proc: {
			tag_type = t_type_info_procedure;

			LLVMValueRef params = LLVMConstNull(lb_type(m, t_type_info_ptr));
			LLVMValueRef results = LLVMConstNull(lb_type(m, t_type_info_ptr));
			if (t->Proc.params != nullptr) {
				params = get_type_info_ptr(m, t->Proc.params);
			}
			if (t->Proc.results != nullptr) {
				results = get_type_info_ptr(m, t->Proc.results);
			}

			LLVMValueRef vals[4] = {
				params,
				results,
				lb_const_bool(m, t_bool, t->Proc.variadic).value,
				lb_const_int(m, t_u8, t->Proc.calling_convention).value,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_Tuple: {
			tag_type = t_type_info_parameters;
			i64 type_offset = 0;
			i64 name_offset = 0;
			lbValue memory_types = lb_type_info_member_types_offset(m, t->Tuple.variables.count, &type_offset);
			lbValue memory_names = lb_type_info_member_names_offset(m, t->Tuple.variables.count, &name_offset);

			for_array(i, t->Tuple.variables) {
				// NOTE(bill): offset is not used for tuples
				Entity *f = t->Tuple.variables[i];

				lbValue index     = lb_const_int(m, t_int, i);
				lbValue type_info = lb_const_ptr_offset(m, memory_types, index);

				member_types_values[type_offset+i] = get_type_info_ptr(m, f->type);
				if (f->token.string.len > 0) {
					member_names_values[name_offset+i] = lb_const_string(m, f->token.string).value;
				}
			}

			lbValue count = lb_const_int(m, t_int, t->Tuple.variables.count);

			LLVMValueRef types_slice = llvm_const_slice(m, memory_types, count);
			LLVMValueRef names_slice = llvm_const_slice(m, memory_names, count);

			LLVMValueRef vals[2] = {
				types_slice,
				names_slice,
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}

		case Type_Enum:
			tag_type = t_type_info_enum;

			{
				GB_ASSERT(t->Enum.base_type != nullptr);
				// GB_ASSERT_MSG(type_size_of(t_type_info_enum_value) == 16, "%lld == 16", cast(long long)type_size_of(t_type_info_enum_value));


				LLVMValueRef vals[3] = {};
				vals[0] = get_type_info_ptr(m, t->Enum.base_type);
				if (t->Enum.fields.count > 0) {
					auto fields = t->Enum.fields;
					lbValue name_array  = lb_generate_global_array(m, t_string, fields.count,
					                                        str_lit("$enum_names"), cast(i64)entry_index);

					LLVMValueRef *name_values = gb_alloc_array(temporary_allocator(), LLVMValueRef, fields.count);

					GB_ASSERT(is_type_integer(t->Enum.base_type));

					for_array(i, fields) {
						name_values[i] = lb_const_string(m, fields[i]->token.string).value;
					}

					LLVMValueRef name_init  = llvm_const_array(m, lb_type(m, t_string), name_values, cast(unsigned)fields.count);
					LLVMSetInitializer(name_array.value, name_init);
					LLVMSetGlobalConstant(name_array.value, true);
					lb_set_odin_rtti_section(name_array.value);

					lbValue value_ptr = {};
					if (lb_type_info_enum_values_are_indices(t)) {
						GB_ASSERT(fields.count <= members->enum_indices_count);
						value_ptr = lb_const_array_epi(m, members->enum_indices.addr, 0);
					} else {
						lbValue value_array = lb_generate_global_array(m, t_type_info_enum_value, fields.count,
						                                        str_lit("$enum_values"), cast(i64)entry_index);

						LLVMValueRef *value_values = gb_alloc_array(temporary_allocator(), LLVMValueRef, fields.count);
						for_array(i, fields) {
							value_values[i] = lb_const_value(m, t_i64, fields[i]->Constant.value).value;
						}

						LLVMValueRef value_init = llvm_const_array(m, lb_type(m, t_type_info_enum_value), value_values, cast(unsigned)fields.count);
						LLVMSetInitializer(value_array.value, value_init);
						LLVMSetGlobalConstant(value_array.value, true);
						lb_set_odin_rtti_section(value_array.value);

						value_ptr = lbValue{value_array.value, alloc_type_pointer(t_type_info_enum_value)};
					}

					lbValue v_count = lb_const_int(m, t_int, fields.count);

					vals[1] = llvm_const_slice(m, lbValue{name_array.value, alloc_type_pointer(t_string)}, v_count);
					vals[2] = llvm_const_slice(m, value_ptr, v_count);
				} else {
					vals[1] = LLVMConstNull(lb_type(m, base_type(t_type_info_enum)->Struct.fields[2]->type));
					vals[2] = LLVMConstNull(lb_type(m, base_type(t_type_info_enum)->Struct.fields[3]->type));
				}


				variant_value = make_record(tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_Union: {
			tag_type = t_type_info_union;

			{
				LLVMValueRef vals[7] = {};

				isize variant_count = gb_max(0, t->Union.variants.count);
				i64 variant_offset = 0;
				lbValue memory_types = lb_type_info_member_types_offset(m, variant_count, &variant_offset);

				for (isize variant_index = 0; variant_index < variant_count; variant_index++) {
					Type *vt = t->Union.variants[variant_index];
					member_types_values[variant_offset+variant_index] = get_type_info_ptr(m, vt);
				}

				lbValue count = lb_const_int(m, t_int, variant_count);
				vals[0] = llvm_const_slice(m, memory_types, count);

				i64 tag_size = union_tag_size(t);
				if (tag_size > 0) {
					i64 tag_offset = align_formula(t->Union.variant_block_size, tag_size);
					vals[1] = lb_const_int(m, t_uintptr, tag_offset).value;
					vals[2] = get_type_info_ptr(m, union_tag_type(t));
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
						vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag_type, i+1)));
					}
				}

				variant_value = make_record(tag_type, vals, gb_count_of(vals));
			}

			break;
		}

		case Type_Struct: {
			tag_type = t_type_info_struct;

			LLVMValueRef vals[11] = {};

			{
				u8 flags = 0;
				if (t->Struct.is_packed)      flags |= 1<<0;
				if (t->Struct.is_raw_union)   flags |= 1<<1;
				if (t->Struct.is_all_or_none) flags |= 1<<2;
				if (t->Struct.custom_align)   flags |= 1<<3;

				vals[6] = lb_const_int(m, t_u8, flags).value;
				if (is_type_comparable(t) && !is_type_simple_compare(t)) {
					vals[10] = lb_equal_proc_for_type(m, t).value;
				}


				if (t->Struct.soa_kind != StructSoa_None) {
					Type *kind_type = get_struct_field_type(tag_type, 8);

					lbValue soa_kind = lb_const_value(m, kind_type, exact_value_i64(t->Struct.soa_kind));
					LLVMValueRef soa_type = get_type_info_ptr(m, t->Struct.soa_elem);
					lbValue soa_len = lb_const_int(m, t_i32, t->Struct.soa_count);

					vals[7] = soa_kind.value;
					vals[8] = soa_len.value;
					vals[9] = soa_type;
				}
			}

			isize count = t->Struct.fields.count;
			if (count > 0) {
				i64 types_offset   = 0;
				i64 names_offset   = 0;
				i64 offsets_offset = 0;
				i64 usings_offset  = 0;
				i64 tags_offset    = 0;

				bool has_usings = lb_type_info_struct_has_usings(t);
				bool has_tags   = lb_type_info_has_tags(t);

				lbValue memory_types   = lb_type_info_member_types_offset  (m, count, &types_offset);
				lbValue memory_names   = lb_type_info_member_names_offset  (m, count, &names_offset);
				lbValue memory_offsets = lb_type_info_member_offsets_offset(m, count, &offsets_offset);
				lbValue memory_usings  = {};
				lbValue memory_tags    = {};
				if (has_usings) {
					memory_usings = lb_type_info_member_usings_offset(m, count, &usings_offset);
				} else {
					memory_usings = lb_type_info_member_empty_usings(m, count);
				}
				if (has_tags) {
					memory_tags = lb_type_info_member_tags_offset(m, count, &tags_offset);
				} else {
					memory_tags = lb_type_info_member_empty_tags(m, count);
				}

				type_set_offsets(t); // NOTE(bill): Just incase the offsets have not been set yet
				for (isize source_index = 0; source_index < count; source_index++) {
					Entity *f = t->Struct.fields[source_index];
					i64 foffset = 0;
					if (!t->Struct.is_raw_union) {
						GB_ASSERT_MSG(t->Struct.offsets != nullptr, "%s", type_to_string(t));
						GB_ASSERT(0 <= f->Variable.field_index && f->Variable.field_index < count);
						foffset = t->Struct.offsets[source_index];
					}
					GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);


					member_types_values[types_offset+source_index]     = get_type_info_ptr(m, f->type);
					member_offsets_values[offsets_offset+source_index] = lb_const_int(m, t_uintptr, foffset).value;
					if (has_usings) {
						member_usings_values[usings_offset+source_index] = lb_const_bool(m, t_bool, (f->flags&EntityFlag_Using) != 0).value;
					}

					if (f->token.string.len > 0) {
						member_names_values[names_offset+source_index] = lb_const_string(m, f->token.string).value;
					}

					if (has_tags) {
						String tag_string = t->Struct.tags[source_index];
						if (tag_string.len > 0) {
							member_tags_values[tags_offset+source_index] = lb_const_string(m, tag_string).value;
						}
					}

				}

				lbValue cv = lb_const_int(m, t_i32, count);
				vals[0] = memory_types.value;
				vals[1] = memory_names.value;
				vals[2] = memory_offsets.value;
				vals[3] = memory_usings.value;
				vals[4] = memory_tags.value;
				vals[5] = cv.value;
			}
			for (isize i = 0; i < gb_count_of(vals); i++) {
				if (vals[i] == nullptr) {
					vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag_type, i+1)));
				}
			}

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}

		case Type_Map: {
			tag_type = t_type_info_map;
			init_map_internal_debug_types(t);

			LLVMValueRef vals[3] = {
				get_type_info_ptr(m, t->Map.key),
				get_type_info_ptr(m, t->Map.value),
				lb_gen_map_info_ptr(m, t).value
			};

			variant_value = make_record(tag_type, vals, gb_count_of(vals));
			break;
		}

		case Type_BitSet:
			{
				tag_type = t_type_info_bit_set;

				GB_ASSERT(is_type_typed(t->BitSet.elem));


				LLVMValueRef vals[5] = {
					get_type_info_ptr(m, t->BitSet.elem),          // ^Type_Info
					nullptr,                                       // ^Type_Info
					nullptr,                                       // bool
					lb_const_int(m, t_i64, t->BitSet.lower).value, // i64
					lb_const_int(m, t_i64, t->BitSet.upper).value, // i64
				};
				Type *underlying = nullptr;
				bool explicit_underlying = false;
				if (t->BitSet.underlying != nullptr) {
					underlying = t->BitSet.underlying;
					explicit_underlying = true;
					vals[1] = get_type_info_ptr(m, t->BitSet.underlying);
					vals[2] = lb_const_bool(m, t_bool, true).value;
				} else {
					underlying = bit_set_to_int(t);
				}
				vals[1] = get_type_info_ptr(m, underlying);
				vals[2] = lb_const_bool(m, t_bool, explicit_underlying).value;

				variant_value = make_record(tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_SimdVector:
			{
				tag_type = t_type_info_simd_vector;

				LLVMValueRef vals[3] = {};

				vals[0] = get_type_info_ptr(m, t->SimdVector.elem);
				vals[1] = lb_const_int(m, t_int, type_size_of(t->SimdVector.elem)).value;
				vals[2] = lb_const_int(m, t_int, t->SimdVector.count).value;

				variant_value = make_record(tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_Matrix:
			{
				tag_type = t_type_info_matrix;
				i64 ez = type_size_of(t->Matrix.elem);

				LLVMValueRef vals[6] = {
					get_type_info_ptr(m, t->Matrix.elem),
					lb_const_int(m, t_int, ez).value,
					lb_const_int(m, t_int, matrix_type_stride_in_elems(t)).value,
					lb_const_int(m, t_int, t->Matrix.row_count).value,
					lb_const_int(m, t_int, t->Matrix.column_count).value,
					lb_const_int(m, t_u8,  cast(u8)t->Matrix.is_row_major).value,
				};

				variant_value = make_record(tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_BitField:
			{
				tag_type = t_type_info_bit_field;

				LLVMValueRef vals[7] = {};
				vals[0] = get_type_info_ptr(m, t->BitField.backing_type);
				isize count = t->BitField.fields.count;
				if (count > 0) {
					i64 names_offset       = 0;
					i64 types_offset       = 0;
					i64 bit_sizes_offset   = 0;
					i64 bit_offsets_offset = 0;
					i64 tags_offset        = 0;
					bool has_tags = lb_type_info_has_tags(t);

					lbValue memory_names       = lb_type_info_member_names_offset  (m, count, &names_offset);
					lbValue memory_types       = lb_type_info_member_types_offset  (m, count, &types_offset);
					lbValue memory_bit_sizes   = lb_type_info_member_offsets_offset(m, count, &bit_sizes_offset);
					lbValue memory_bit_offsets = lb_type_info_member_offsets_offset(m, count, &bit_offsets_offset);
					lbValue memory_tags        = {};
					if (has_tags) {
						memory_tags = lb_type_info_member_tags_offset(m, count, &tags_offset);
					} else {
						memory_tags = lb_type_info_member_empty_tags(m, count);
					}

					u64 bit_offset = 0;
					for (isize source_index = 0; source_index < count; source_index++) {
						Entity *f = t->BitField.fields[source_index];
						u64 bit_size = cast(u64)t->BitField.bit_sizes[source_index];

						lbValue index = lb_const_int(m, t_int, source_index);
						if (f->token.string.len > 0) {
							member_names_values[names_offset+source_index] = lb_const_string(m, f->token.string).value;
						}

						member_types_values[types_offset+source_index] = get_type_info_ptr(m, f->type);

						member_offsets_values[bit_sizes_offset+source_index] = lb_const_int(m, t_uintptr, bit_size).value;
						member_offsets_values[bit_offsets_offset+source_index] = lb_const_int(m, t_uintptr, bit_offset).value;

						if (has_tags) {
							String tag = t->BitField.tags[source_index];
							if (tag.len > 0) {
								member_tags_values[tags_offset+source_index] = lb_const_string(m, tag).value;
							}
						}

						bit_offset += bit_size;
					}

					lbValue cv = lb_const_int(m, t_int, count);
					vals[1] =  memory_names.value;
					vals[2] =  memory_types.value;
					vals[3] =  memory_bit_sizes.value;
					vals[4] =  memory_bit_offsets.value;
					vals[5] =  memory_tags.value;
					vals[6] =  cv.value;
				}


				for (isize i = 0; i < gb_count_of(vals); i++) {
					if (vals[i] == nullptr) {
						vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag_type, i+1)));
					}
				}

				variant_value = make_record(tag_type, vals, gb_count_of(vals));
				break;
			}
		}



		GB_ASSERT_MSG(tag_type == rec, "%s: %s vs %s", type_to_string(t), type_to_string(tag_type), type_to_string(rec));

		LLVMValueRef record = variant_value;
		if (record == nullptr) {
			if (rec != nullptr) {
				record = make_record(rec, nullptr, 0);
			} else {
				record = header;
			}
		}

		LLVMValueRef g = giant_const_values[entry_index];
		GB_ASSERT_MSG(LLVMTypeOf(record) == LLVMGlobalGetValueType(g),
			"\n%s\n%s vs %s\n",
			type_to_string(t),
			LLVMPrintTypeToString(LLVMTypeOf(record)),
			LLVMPrintTypeToString(LLVMGlobalGetValueType(g))
		);
		LLVMSetInitializer(g, record);
	}
	if (!is_default_module) {
		return;
	}
	GB_ASSERT(giant_const_values[0] != nullptr);
	for (isize i = 0; i < global_type_info_data_entity_count; i++) {
		auto *ptr = &giant_const_values[i];
		GB_ASSERT_MSG(*ptr != nullptr || info->type_info_types_hash_map[i].hash == 0, "type info slot %td is occupied but has no entry", i);
		if (*ptr != nullptr) {
			*ptr = LLVMConstPointerCast(*ptr, lb_type(m, t_type_info_ptr));
		} else {
			*ptr = LLVMConstNull(lb_type(m, t_type_info_ptr));
		}
	}


	LLVMValueRef giant_const = LLVMConstArray(lb_type(m, t_type_info_ptr), giant_const_values, cast(unsigned)global_type_info_data_entity_count);
	LLVMValueRef giant_array = lb_global_type_info_data_ptr(m).value;
	LLVMSetInitializer(giant_array, giant_const);
	lb_make_global_private_const(giant_array);
	lb_set_odin_rtti_section(giant_array);
}


gb_internal void lb_setup_type_info_data(lbModule *m) { // NOTE(bill): Setup type_info data
	if (build_context.no_rtti) {
		return;
	}


	i64 global_type_info_data_entity_count = 0;

	Type *type = base_type(lb_global_type_info_data_entity->type);
	GB_ASSERT(type->kind == Type_Array);
	global_type_info_data_entity_count = type->Array.count;

	if (true) {
		lb_setup_type_info_data_giant_array(m, global_type_info_data_entity_count);
	}
	if (m != &m->gen->default_module) {
		return;
	}

	// NOTE(bill): Set the type_table slice with the global backing array
	lbValue global_type_table = lb_find_runtime_value(m, str_lit("type_table"));
	LLVMValueRef data = lb_global_type_info_data_ptr(m).value;
	data = LLVMConstPointerCast(data, lb_type(m, alloc_type_pointer(type->Array.elem)));
	LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), type->Array.count, true);
	Type *t = type_deref(global_type_table.type);
	GB_ASSERT(is_type_slice(t));
	LLVMValueRef slice = llvm_const_slice_internal(m, data, len);

	LLVMSetInitializer(global_type_table.value, slice);

	// force it to be constant
	LLVMSetGlobalConstant(global_type_table.value, true);
}
