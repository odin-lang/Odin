
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

gb_internal u64 lb_typeid_kind(lbModule *m, Type *type, u64 id=0) {
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);

	if (id == 0) {
		id = cast(u64)lb_type_info_index(m->info, type);
	}

	u64 kind = Typeid_Invalid;

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

		if (bt->Basic.kind == Basic_typeid) kind = Typeid_Type_Id;
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
	case Type_SoaPointer:      kind = Typeid_SoaPointer;       break;
	case Type_BitField:        kind = Typeid_Bit_Field;        break;
	}

	return kind;
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


gb_internal lbValue lb_type_info_member_types_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	GB_ASSERT(m == &m->gen->default_module);
	if (offset_) *offset_ = lb_global_type_info_member_types_index;
	lbValue offset = lb_const_array_epi(m, lb_global_type_info_member_types.addr, lb_global_type_info_member_types_index);
	lb_global_type_info_member_types_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_names_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	GB_ASSERT(m == &m->gen->default_module);
	if (offset_) *offset_ = lb_global_type_info_member_names_index;
	lbValue offset = lb_const_array_epi(m, lb_global_type_info_member_names.addr, lb_global_type_info_member_names_index);
	lb_global_type_info_member_names_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_offsets_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	GB_ASSERT(m == &m->gen->default_module);
	if (offset_) *offset_ = lb_global_type_info_member_offsets_index;
	lbValue offset = lb_const_array_epi(m, lb_global_type_info_member_offsets.addr, lb_global_type_info_member_offsets_index);
	lb_global_type_info_member_offsets_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_usings_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	GB_ASSERT(m == &m->gen->default_module);
	if (offset_) *offset_ = lb_global_type_info_member_usings_index;
	lbValue offset = lb_const_array_epi(m, lb_global_type_info_member_usings.addr, lb_global_type_info_member_usings_index);
	lb_global_type_info_member_usings_index += cast(i32)count;
	return offset;
}
gb_internal lbValue lb_type_info_member_tags_offset(lbModule *m, isize count, i64 *offset_=nullptr) {
	GB_ASSERT(m == &m->gen->default_module);
	if (offset_) *offset_ = lb_global_type_info_member_tags_index;
	lbValue offset = lb_const_array_epi(m, lb_global_type_info_member_tags.addr, lb_global_type_info_member_tags_index);
	lb_global_type_info_member_tags_index += cast(i32)count;
	return offset;
}

gb_internal LLVMTypeRef *lb_setup_modified_types_for_type_info(lbModule *m, isize max_type_info_count) {
	LLVMTypeRef *element_types = gb_alloc_array(heap_allocator(), LLVMTypeRef, max_type_info_count);
	defer (gb_free(heap_allocator(), element_types));

	auto entries_handled = slice_make<bool>(heap_allocator(), max_type_info_count);
	defer (gb_free(heap_allocator(), entries_handled.data));
	entries_handled[0] = true;

	element_types[0] = lb_type(m, t_type_info);

	Type *tibt = base_type(t_type_info);
	GB_ASSERT(tibt->kind == Type_Struct);
	Type *ut = base_type(tibt->Struct.fields[tibt->Struct.fields.count-1]->type);
	GB_ASSERT(ut->kind == Type_Union);

	GB_ASSERT(tibt->Struct.fields.count == 5);
	LLVMTypeRef stypes[6] = {};
	stypes[0] = lb_type(m, tibt->Struct.fields[0]->type);
	stypes[1] = lb_type(m, tibt->Struct.fields[1]->type);
	stypes[2] = lb_type(m, tibt->Struct.fields[2]->type);
	isize variant_index = 0;
	if (build_context.ptr_size == 8) {
		stypes[3] = lb_type(m, t_i32); // padding
		stypes[4] = lb_type(m, tibt->Struct.fields[3]->type);
		variant_index = 5;
	} else {
		stypes[3] = lb_type(m, tibt->Struct.fields[3]->type);
		variant_index = 4;
	}

	LLVMTypeRef *modified_types = gb_alloc_array(heap_allocator(), LLVMTypeRef, Typeid__COUNT);
	GB_ASSERT(Typeid__COUNT == ut->Union.variants.count);
	modified_types[0] = element_types[0];

	i64 tag_offset = ut->Union.variant_block_size;
	LLVMTypeRef tag = lb_type(m, union_tag_type(ut));

	for_array(i, ut->Union.variants) {
		Type *t = ut->Union.variants[i];
		LLVMTypeRef padding = llvm_array_type(lb_type(m, t_u8), tag_offset-type_size_of(t));

		LLVMTypeRef vtypes[3] = {};
		vtypes[0] = lb_type(m, t);
		vtypes[1] = padding;
		vtypes[2] = tag;
		LLVMTypeRef variant_type = LLVMStructType(vtypes, gb_count_of(vtypes), true);

		stypes[variant_index] = variant_type;
		LLVMTypeRef modified_type = LLVMStructType(stypes, cast(unsigned)(variant_index+1), false);

		modified_types[i] = modified_type;
	}

	for (isize i = 0; i < Typeid__COUNT; i++) {
		GB_ASSERT_MSG(modified_types[i] != nullptr, "%td", ut->Union.variants.count);
	}

	return modified_types;
}

gb_internal void lb_setup_type_info_data_giant_array(lbModule *m, i64 global_type_info_data_entity_count) { // NOTE(bill): Setup type_info data
	auto const &ADD_GLOBAL_TYPE_INFO_ENTRY = [](lbModule *m, LLVMTypeRef type, isize index) -> LLVMValueRef {
		char name[64] = {};
		gb_snprintf(name, 63, "__$ti-%lld", cast(long long)index);
		LLVMValueRef g = LLVMAddGlobal(m->mod, type, name);
		lb_make_global_private_const(g);
		return g;
	};

	CheckerInfo *info = m->info;

	// Useful types
	Entity *type_info_flags_entity = find_core_entity(info->checker, str_lit("Type_Info_Flags"));
	Type *t_type_info_flags = type_info_flags_entity->type;
	gb_unused(t_type_info_flags);

	Type *ut = base_type(t_type_info);
	GB_ASSERT(ut->kind == Type_Struct);
	ut = base_type(ut->Struct.fields[ut->Struct.fields.count-1]->type);
	GB_ASSERT(ut->kind == Type_Union);

	auto entries_handled = slice_make<bool>(heap_allocator(), cast(isize)global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), entries_handled.data));
	entries_handled[0] = true;

	LLVMValueRef *giant_const_values = gb_alloc_array(heap_allocator(), LLVMValueRef, global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), giant_const_values));

	// zero value is just zero data
	giant_const_values[0] = ADD_GLOBAL_TYPE_INFO_ENTRY(m, lb_type(m, t_type_info), 0);
	LLVMSetInitializer(giant_const_values[0], LLVMConstNull(lb_type(m, t_type_info)));


	LLVMTypeRef *modified_types = lb_setup_modified_types_for_type_info(m, global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), modified_types));
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


		LLVMTypeRef stype = nullptr;
		if (t->kind == Type_Named) {
			stype = modified_types[0];
		} else {
			stype = modified_types[lb_typeid_kind(m, t)];
		}
		giant_const_values[entry_index] = ADD_GLOBAL_TYPE_INFO_ENTRY(m, stype, entry_index);
	}
	for (isize i = 1; i < global_type_info_data_entity_count; i++) {
		entries_handled[i] = false;
	}


	LLVMValueRef *small_const_values = gb_alloc_array(heap_allocator(), LLVMValueRef, 6);
	defer (gb_free(heap_allocator(), small_const_values));

	#define type_info_allocate_values(name) \
		LLVMValueRef *name##_values = gb_alloc_array(heap_allocator(), LLVMValueRef, type_deref(name.addr.type)->Array.count); \
		defer (gb_free(heap_allocator(), name##_values));                                                                      \
		defer ({                                                                                                               \
			Type *at = type_deref(name.addr.type);                                                                         \
			LLVMTypeRef elem = lb_type(m, at->Array.elem);                                                                 \
			for (i64 i = 0; i < at->Array.count; i++) {                                                                    \
				if ((name##_values)[i] == nullptr) {                                                                   \
					(name##_values)[i] = LLVMConstNull(elem);                                                      \
				}                                                                                                      \
			}                                                                                                              \
			LLVMSetInitializer(name.addr.value, llvm_const_array(elem, name##_values, at->Array.count));                   \
		})

	type_info_allocate_values(lb_global_type_info_member_types);
	type_info_allocate_values(lb_global_type_info_member_names);
	type_info_allocate_values(lb_global_type_info_member_offsets);
	type_info_allocate_values(lb_global_type_info_member_usings);
	type_info_allocate_values(lb_global_type_info_member_tags);


	auto const get_type_info_ptr = [&](lbModule *m, Type *type) -> LLVMValueRef {
		type = default_type(type);

		isize index = lb_type_info_index(m->info, type);
		GB_ASSERT(index >= 0);

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


		LLVMTypeRef stype = nullptr;
		if (t->kind == Type_Named) {
			stype = modified_types[0];
		} else {
			stype = modified_types[lb_typeid_kind(m, t)];
		}

		i64 size = type_size_of(t);
		i64 align = type_align_of(t);
		u32 flags = type_info_flags_of_type(t);
		lbValue id = lb_typeid(m, t);
		GB_ASSERT_MSG(align != 0, "%lld %s", align, type_to_string(t));

		lbValue type_info_flags = lb_const_int(m, t_type_info_flags, flags);

		for (isize i = 0; i < 6; i++) {
			small_const_values[i] = nullptr;
		}

		small_const_values[0] = LLVMConstInt(lb_type(m, t_int), size, true);
		small_const_values[1] = LLVMConstInt(lb_type(m, t_int), align, true);
		small_const_values[2] = type_info_flags.value;

		unsigned variant_index = 0;
		if (build_context.ptr_size == 8) {
			small_const_values[3] = LLVMConstNull(LLVMStructGetTypeAtIndex(stype, 3));
			small_const_values[4] = id.value;
			variant_index = 5;
		} else {
			small_const_values[3] = id.value;
			variant_index = 4;
		}

		LLVMTypeRef full_variant_type = LLVMStructGetTypeAtIndex(stype, variant_index);
		unsigned full_variant_elem_count = LLVMCountStructElementTypes(full_variant_type);
		if (full_variant_elem_count != 2) {
			GB_ASSERT_MSG(LLVMCountStructElementTypes(full_variant_type) == 3, "%lld %s", entry_index, type_to_string(t)); // blob, padding, tag
		}

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
				if (decl->entity && decl->entity->kind == Entity_Procedure) {
					proc_name = decl->entity->token.string;
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

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

					variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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
				tag_type = t_type_info_string;
				break;

			case Basic_cstring:
				{
					tag_type = t_type_info_string;
					LLVMValueRef vals[1] = {
						lb_const_bool(m, t_bool, true).value,
					};

					variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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


			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_MultiPointer: {
			tag_type = t_type_info_multi_pointer;

			LLVMValueRef vals[1] = {
				get_type_info_ptr(m, t->MultiPointer.elem),
			};

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_SoaPointer: {
			tag_type = t_type_info_soa_pointer;

			LLVMValueRef vals[1] = {
				get_type_info_ptr(m, t->SoaPointer.elem),
			};

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_DynamicArray: {
			tag_type = t_type_info_dynamic_array;

			LLVMValueRef vals[2] = {
				get_type_info_ptr(m, t->DynamicArray.elem),
				lb_const_int(m, t_int, type_size_of(t->DynamicArray.elem)).value,
			};

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			break;
		}
		case Type_Slice: {
			tag_type = t_type_info_slice;

			LLVMValueRef vals[2] = {
				get_type_info_ptr(m, t->Slice.elem),
				lb_const_int(m, t_int, type_size_of(t->Slice.elem)).value,
			};

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

				lb_global_type_info_member_types_values[type_offset+i] = get_type_info_ptr(m, f->type);
				if (f->token.string.len > 0) {
					lb_global_type_info_member_names_values[name_offset+i] = lb_const_string(m, f->token.string).value;
				}
			}

			lbValue count = lb_const_int(m, t_int, t->Tuple.variables.count);

			LLVMValueRef types_slice = llvm_const_slice(m, memory_types, count);
			LLVMValueRef names_slice = llvm_const_slice(m, memory_names, count);

			LLVMValueRef vals[2] = {
				types_slice,
				names_slice,
			};

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

					vals[1] = llvm_const_slice(m, lbValue{name_array.value,  alloc_type_pointer(t_string)},               v_count);
					vals[2] = llvm_const_slice(m, lbValue{value_array.value, alloc_type_pointer(t_type_info_enum_value)}, v_count);
				} else {
					vals[1] = LLVMConstNull(lb_type(m, base_type(t_type_info_enum)->Struct.fields[1]->type));
					vals[2] = LLVMConstNull(lb_type(m, base_type(t_type_info_enum)->Struct.fields[2]->type));
				}


				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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
					lb_global_type_info_member_types_values[variant_offset+variant_index] = get_type_info_ptr(m, vt);
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
						vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag_type, i)));
					}
				}

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			}

			break;
		}

		case Type_Struct: {
			tag_type = t_type_info_struct;

			LLVMValueRef vals[11] = {};

			{
				u8 flags = 0;
				if (t->Struct.is_packed)    flags |= 1<<0;
				if (t->Struct.is_raw_union) flags |= 1<<1;
				if (t->Struct.is_no_copy)   flags |= 1<<2;
				if (t->Struct.custom_align) flags |= 1<<3;

				vals[6] = lb_const_int(m, t_u8, flags).value;
				if (is_type_comparable(t) && !is_type_simple_compare(t)) {
					vals[10] = lb_equal_proc_for_type(m, t).value;
				}


				if (t->Struct.soa_kind != StructSoa_None) {
					Type *kind_type = get_struct_field_type(tag_type, 7);

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

				lbValue memory_types   = lb_type_info_member_types_offset  (m, count, &types_offset);
				lbValue memory_names   = lb_type_info_member_names_offset  (m, count, &names_offset);
				lbValue memory_offsets = lb_type_info_member_offsets_offset(m, count, &offsets_offset);
				lbValue memory_usings  = lb_type_info_member_usings_offset (m, count, &usings_offset);
				lbValue memory_tags    = lb_type_info_member_tags_offset   (m, count, &tags_offset);

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


					lb_global_type_info_member_types_values[types_offset+source_index]     = get_type_info_ptr(m, f->type);
					lb_global_type_info_member_offsets_values[offsets_offset+source_index] = lb_const_int(m, t_uintptr, foffset).value;
					lb_global_type_info_member_usings_values[usings_offset+source_index]   = lb_const_bool(m, t_bool, (f->flags&EntityFlag_Using) != 0).value;

					if (f->token.string.len > 0) {
						lb_global_type_info_member_names_values[names_offset+source_index] = lb_const_string(m, f->token.string).value;
					}

					if (t->Struct.tags != nullptr) {
						String tag_string = t->Struct.tags[source_index];
						if (tag_string.len > 0) {
							lb_global_type_info_member_tags_values[tags_offset+source_index] = lb_const_string(m, tag_string).value;
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
					vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag_type, i)));
				}
			}

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

			variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			break;
		}

		case Type_BitSet:
			{
				tag_type = t_type_info_bit_set;

				GB_ASSERT(is_type_typed(t->BitSet.elem));


				LLVMValueRef vals[4] = {
					get_type_info_ptr(m, t->BitSet.elem),
					LLVMConstNull(lb_type(m, t_type_info_ptr)),
					lb_const_int(m, t_i64, t->BitSet.lower).value,
					lb_const_int(m, t_i64, t->BitSet.upper).value,
				};
				if (t->BitSet.underlying != nullptr) {
					vals[1] = get_type_info_ptr(m, t->BitSet.underlying);
				}

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_SimdVector:
			{
				tag_type = t_type_info_simd_vector;

				LLVMValueRef vals[3] = {};

				vals[0] = get_type_info_ptr(m, t->SimdVector.elem);
				vals[1] = lb_const_int(m, t_int, type_size_of(t->SimdVector.elem)).value;
				vals[2] = lb_const_int(m, t_int, t->SimdVector.count).value;

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
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
					lbValue memory_names       = lb_type_info_member_names_offset  (m, count, &names_offset);
					lbValue memory_types       = lb_type_info_member_types_offset  (m, count, &types_offset);
					lbValue memory_bit_sizes   = lb_type_info_member_offsets_offset(m, count, &bit_sizes_offset);
					lbValue memory_bit_offsets = lb_type_info_member_offsets_offset(m, count, &bit_offsets_offset);
					lbValue memory_tags        = lb_type_info_member_tags_offset   (m, count, &tags_offset);

					u64 bit_offset = 0;
					for (isize source_index = 0; source_index < count; source_index++) {
						Entity *f = t->BitField.fields[source_index];
						u64 bit_size = cast(u64)t->BitField.bit_sizes[source_index];

						lbValue index = lb_const_int(m, t_int, source_index);
						if (f->token.string.len > 0) {
							lb_global_type_info_member_names_values[names_offset+source_index] = lb_const_string(m, f->token.string).value;
						}

						lb_global_type_info_member_types_values[types_offset+source_index] = get_type_info_ptr(m, f->type);

						lb_global_type_info_member_offsets_values[bit_sizes_offset+source_index] = lb_const_int(m, t_uintptr, bit_size).value;
						lb_global_type_info_member_offsets_values[bit_offsets_offset+source_index] = lb_const_int(m, t_uintptr, bit_offset).value;

						if (t->BitField.tags) {
							String tag = t->BitField.tags[source_index];
							if (tag.len > 0) {
								lb_global_type_info_member_tags_values[tags_offset+source_index] = lb_const_string(m, tag).value;
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
						vals[i]  = LLVMConstNull(lb_type(m, get_struct_field_type(tag_type, i)));
					}
				}

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
				break;
			}
		}



		i64 tag_index = 0;
		if (tag_type != nullptr) {
			tag_index = union_variant_index(ut, tag_type);
		}
		GB_ASSERT(tag_index <= Typeid__COUNT);

		LLVMValueRef full_variant_values[3] = {};

		if (full_variant_elem_count == 2) {
			if (variant_value == nullptr) {
				full_variant_values[0] = LLVMConstNull(LLVMStructGetTypeAtIndex(full_variant_type, 0));
				full_variant_values[1] = LLVMConstInt(LLVMStructGetTypeAtIndex(full_variant_type, 1), tag_index, false);
			} else {
				full_variant_values[0] = variant_value;
				full_variant_values[1] = LLVMConstInt(LLVMStructGetTypeAtIndex(full_variant_type, 1), tag_index, false);
			}
		} else {
			if (variant_value == nullptr) {
				variant_value = LLVMConstNull(LLVMStructGetTypeAtIndex(full_variant_type, 0));
			} else {
				GB_ASSERT_MSG(LLVMStructGetTypeAtIndex(full_variant_type, 0) == LLVMTypeOf(variant_value),
					"\n%s -> %s\n%s vs %s\n",
					type_to_string(t), LLVMPrintValueToString(variant_value),
					LLVMPrintTypeToString(LLVMStructGetTypeAtIndex(full_variant_type, 0)), LLVMPrintTypeToString(LLVMTypeOf(variant_value))
				);
			}

			full_variant_values[0] = variant_value;
			full_variant_values[1] = LLVMConstNull(LLVMStructGetTypeAtIndex(full_variant_type, 1));
			full_variant_values[2] = LLVMConstInt(LLVMStructGetTypeAtIndex(full_variant_type, 2), tag_index, false);
		}
		LLVMValueRef full_variant_value = LLVMConstNamedStruct(full_variant_type, full_variant_values, full_variant_elem_count);

		small_const_values[variant_index] = full_variant_value;

		LLVMSetInitializer(giant_const_values[entry_index], LLVMConstNamedStruct(stype, small_const_values, variant_index+1));
	}
	for (isize i = 0; i < global_type_info_data_entity_count; i++) {
		auto *ptr = &giant_const_values[i];
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
}


gb_internal void lb_setup_type_info_data(lbModule *m) { // NOTE(bill): Setup type_info data
	if (build_context.no_rtti) {
		return;
	}


	i64 global_type_info_data_entity_count = 0;

	// NOTE(bill): Set the type_table slice with the global backing array
	lbValue global_type_table = lb_find_runtime_value(m, str_lit("type_table"));
	Type *type = base_type(lb_global_type_info_data_entity->type);
	GB_ASSERT(type->kind == Type_Array);
	global_type_info_data_entity_count = type->Array.count;

	if (true) {
		lb_setup_type_info_data_giant_array(m, global_type_info_data_entity_count);
	}

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
