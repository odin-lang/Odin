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
		gb_printf_err("NOT FOUND lb_type_info_index:\n\t%s\n\t@ index %td\n\tmax count: %u\nFound:\n", type_to_string(type), index, set->count);
		for (auto const &entry : *set) {
			isize type_info_index = entry.key;
			gb_printf_err("\t%s\n", type_to_string(info->type_info_types[type_info_index]));
		}
		GB_PANIC("NOT FOUND");
	}
	return -1;
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
	case Type_RelativeMultiPointer: kind = Typeid_Relative_Multi_Pointer; break;
	case Type_SoaPointer:      kind = Typeid_SoaPointer;       break;
	}

	return kind;
}

gb_internal lbValue lb_typeid(lbModule *m, Type *type) {
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);

	u64 id = cast(u64)lb_type_info_index(m->info, type);
	GB_ASSERT(id >= 0);

	u64 kind = lb_typeid_kind(m, type, id);
	u64 named = is_type_named(type) && type->kind != Type_Basic;
	u64 special = 0;
	u64 reserved = 0;

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
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);

	isize index = lb_type_info_index(m->info, type);
	GB_ASSERT(index >= 0);

	lbValue data = lb_global_type_info_data_ptr(m);
	return lb_emit_array_epi(m, data, index);
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

// enum {LB_USE_GIANT_PACKED_STRUCT = LB_USE_NEW_PASS_SYSTEM};
enum {LB_USE_GIANT_PACKED_STRUCT = 0};

gb_internal LLVMTypeRef lb_setup_type_info_data_internal_type(lbModule *m, isize max_type_info_count) {
	if (!LB_USE_GIANT_PACKED_STRUCT) {
		Type *t = alloc_type_array(t_type_info, max_type_info_count);
		return lb_type(m, t);
	}
	CheckerInfo *info = m->gen->info;

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
	if (build_context.int_size == 8) {
		stypes[3] = lb_type(m, t_i32); // padding
		stypes[4] = lb_type(m, tibt->Struct.fields[3]->type);
		variant_index = 5;
	} else {
		stypes[3] = lb_type(m, tibt->Struct.fields[3]->type);
		variant_index = 4;
	}

	LLVMTypeRef modified_types[32] = {};
	GB_ASSERT(gb_count_of(modified_types) >= ut->Union.variants.count);
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


		if (t->kind == Type_Named) {
			element_types[entry_index] = modified_types[0];
		} else {
			i64 variant_index = lb_typeid_kind(m, t);
			element_types[entry_index] = modified_types[variant_index];
		}

		GB_ASSERT(element_types[entry_index] != nullptr);
	}

	for_array(i, entries_handled) {
		GB_ASSERT(entries_handled[i]);
	}

	return LLVMStructType(element_types, cast(unsigned)max_type_info_count, true);
}

gb_internal void lb_setup_type_info_data_giant_packed_struct(lbModule *m, i64 global_type_info_data_entity_count, lbProcedure *p) { // NOTE(bill): Setup type_info data
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

	LLVMValueRef giant_struct = lb_global_type_info_data_ptr(m).value;
	LLVMTypeRef giant_struct_type = LLVMGlobalGetValueType(giant_struct);
	GB_ASSERT(LLVMGetTypeKind(giant_struct_type) == LLVMStructTypeKind);

	LLVMValueRef *giant_const_values = gb_alloc_array(heap_allocator(), LLVMValueRef, global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), giant_const_values));

	giant_const_values[0] = LLVMConstNull(LLVMStructGetTypeAtIndex(giant_struct_type, 0));

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
			LLVMSetInitializer(name.addr.value, llvm_const_array(elem, name##_values, at->Array.count));                    \
		})

	type_info_allocate_values(lb_global_type_info_member_types);
	type_info_allocate_values(lb_global_type_info_member_names);
	type_info_allocate_values(lb_global_type_info_member_offsets);
	type_info_allocate_values(lb_global_type_info_member_usings);
	type_info_allocate_values(lb_global_type_info_member_tags);


	i64 const type_info_struct_size = type_size_of(t_type_info);
	LLVMTypeRef llvm_u8 = lb_type(m, t_u8);
	LLVMTypeRef llvm_int = lb_type(m, t_int);
	// LLVMTypeRef llvm_type_info_ptr = lb_type(m, t_type_info_ptr);

	auto const get_type_info_ptr = [&](lbModule *m, Type *type) -> LLVMValueRef {
		type = default_type(type);

		isize index = lb_type_info_index(m->info, type);
		GB_ASSERT(index >= 0);

		u64 offset = cast(u64)(index * type_info_struct_size);

		LLVMValueRef indices[1] = {
			LLVMConstInt(llvm_int, offset, false)
		};

		// LLVMValueRef ptr = LLVMConstInBoundsGEP2(llvm_u8, giant_struct, indices, gb_count_of(indices));
		LLVMValueRef ptr = LLVMConstGEP2(llvm_u8, giant_struct, indices, gb_count_of(indices));
		return ptr;
		// return LLVMConstPointerCast(ptr, llvm_type_info_ptr);
	};

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


		LLVMTypeRef stype = LLVMStructGetTypeAtIndex(giant_struct_type, cast(unsigned)entry_index);

		i64 size = type_size_of(t);
		i64 align = type_align_of(t);
		u32 flags = type_info_flags_of_type(t);
		lbValue id = lb_typeid(m, t);
		GB_ASSERT_MSG(align != 0, "%lld %s", align, type_to_string(t));

		lbValue type_info_flags = lb_const_int(m, t_type_info_flags, flags);

		small_const_values[0] = LLVMConstInt(lb_type(m, t_int), size, true);
		small_const_values[1] = LLVMConstInt(lb_type(m, t_int), align, true);
		small_const_values[2] = type_info_flags.value;

		unsigned variant_index = 0;
		if (build_context.int_size == 8) {
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

			lbValue loc = lb_const_source_code_location_const(m, proc_name, pos);

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
					Type *kind_type = get_struct_field_type(tag_type, 10);

					lbValue soa_kind = lb_const_value(m, kind_type, exact_value_i64(t->Struct.soa_kind));
					LLVMValueRef soa_type = get_type_info_ptr(m, t->Struct.soa_elem);
					lbValue soa_len = lb_const_int(m, t_int, t->Struct.soa_count);

					vals[10] = soa_kind.value;
					vals[11] = soa_type;
					vals[12] = soa_len.value;
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
						GB_ASSERT(t->Struct.offsets != nullptr);
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

				lbValue cv = lb_const_int(m, t_int, count);
				vals[0] = llvm_const_slice(m, memory_types,   cv);
				vals[1] = llvm_const_slice(m, memory_names,   cv);
				vals[2] = llvm_const_slice(m, memory_offsets, cv);
				vals[3] = llvm_const_slice(m, memory_usings,  cv);
				vals[4] = llvm_const_slice(m, memory_tags,    cv);
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
			init_map_internal_types(t);

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

		case Type_RelativePointer:
			{
				tag_type = t_type_info_relative_pointer;
				LLVMValueRef vals[2] = {
					get_type_info_ptr(m, t->RelativePointer.pointer_type),
					get_type_info_ptr(m, t->RelativePointer.base_integer),
				};

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_RelativeMultiPointer:
			{
				tag_type = t_type_info_relative_multi_pointer;
				LLVMValueRef vals[2] = {
					get_type_info_ptr(m, t->RelativeMultiPointer.pointer_type),
					get_type_info_ptr(m, t->RelativeMultiPointer.base_integer),
				};

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			}
			break;

		case Type_Matrix:
			{
				tag_type = t_type_info_matrix;
				i64 ez = type_size_of(t->Matrix.elem);

				LLVMValueRef vals[5] = {
					get_type_info_ptr(m, t->Matrix.elem),
					lb_const_int(m, t_int, ez).value,
					lb_const_int(m, t_int, matrix_type_stride_in_elems(t)).value,
					lb_const_int(m, t_int, t->Matrix.row_count).value,
					lb_const_int(m, t_int, t->Matrix.column_count).value,
				};

				variant_value = llvm_const_named_struct(m, tag_type, vals, gb_count_of(vals));
			}
			break;
		}



		i64 tag_index = 0;
		if (tag_type != nullptr) {
			tag_index = union_variant_index(ut, tag_type);
		}

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

		giant_const_values[entry_index] = LLVMConstNamedStruct(stype, small_const_values, variant_index+1);
	}

	LLVMValueRef giant_const = LLVMConstNamedStruct(giant_struct_type, giant_const_values, cast(unsigned)global_type_info_data_entity_count);
	LLVMSetInitializer(giant_struct, giant_const);
}


gb_internal void lb_setup_type_info_data(lbProcedure *p) { // NOTE(bill): Setup type_info data
	if (build_context.no_rtti) {
		return;
	}

	lbModule *m = p->module;
	CheckerInfo *info = m->info;

	i64 global_type_info_data_entity_count = 0;
	{
		// NOTE(bill): Set the type_table slice with the global backing array
		lbValue global_type_table = lb_find_runtime_value(m, str_lit("type_table"));
		Type *type = base_type(lb_global_type_info_data_entity->type);
		GB_ASSERT(type->kind == Type_Array);
		global_type_info_data_entity_count = type->Array.count;

		LLVMValueRef data = lb_global_type_info_data_ptr(m).value;
		data = LLVMConstPointerCast(data, lb_type(m, alloc_type_pointer(type->Array.elem)));
		LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), type->Array.count, true);
		Type *t = type_deref(global_type_table.type);
		GB_ASSERT(is_type_slice(t));
		LLVMValueRef slice = llvm_const_slice_internal(m, data, len);

		LLVMSetInitializer(global_type_table.value, slice);
	}

	if (LB_USE_GIANT_PACKED_STRUCT) {
		lb_setup_type_info_data_giant_packed_struct(m, global_type_info_data_entity_count, p);
		return;
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

			lbValue memory_types = lb_type_info_member_types_offset(m, t->Tuple.variables.count);
			lbValue memory_names = lb_type_info_member_names_offset(m, t->Tuple.variables.count);


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
				lbValue memory_types = lb_type_info_member_types_offset(m, variant_count);

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

				i64 tag_size = union_tag_size(t);
				if (tag_size > 0) {
					i64 tag_offset = align_formula(t->Union.variant_block_size, tag_size);
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
				lbValue memory_types   = lb_type_info_member_types_offset  (m, count);
				lbValue memory_names   = lb_type_info_member_names_offset  (m, count);
				lbValue memory_offsets = lb_type_info_member_offsets_offset(m, count);
				lbValue memory_usings  = lb_type_info_member_usings_offset (m, count);
				lbValue memory_tags    = lb_type_info_member_tags_offset   (m, count);

				type_set_offsets(t); // NOTE(bill): Just incase the offsets have not been set yet
				for (isize source_index = 0; source_index < count; source_index++) {
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

		case Type_RelativeMultiPointer:
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_relative_multi_pointer_ptr);
				LLVMValueRef vals[2] = {
					lb_type_info(m, t->RelativeMultiPointer.pointer_type).value,
					lb_type_info(m, t->RelativeMultiPointer.base_integer).value,
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

		case Type_BitField:
			{
				tag = lb_const_ptr_cast(m, variant_ptr, t_type_info_bit_field_ptr);
				LLVMValueRef vals[6] = {};

				vals[0] = lb_type_info(m, t->BitField.backing_type).value;
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
							lbValue name_ptr = lb_emit_ptr_offset(p, memory_names, index);
							lb_emit_store(p, name_ptr, lb_const_string(m, f->token.string));
						}
						lbValue type_ptr       = lb_emit_ptr_offset(p, memory_types, index);
						lbValue bit_size_ptr   = lb_emit_ptr_offset(p, memory_bit_sizes, index);
						lbValue bit_offset_ptr = lb_emit_ptr_offset(p, memory_bit_offsets, index);

						lb_emit_store(p, type_ptr,       lb_type_info(m, f->type));
						lb_emit_store(p, bit_size_ptr,   lb_const_int(m, t_uintptr, bit_size));
						lb_emit_store(p, bit_offset_ptr, lb_const_int(m, t_uintptr, bit_offset));

						if (t->BitField.tags) {
							String tag = t->BitField.tags[source_index];
							if (tag.len > 0) {
								lbValue tag_ptr = lb_emit_ptr_offset(p, memory_tags, index);
								lb_emit_store(p, tag_ptr, lb_const_string(m, tag));
							}
						}

						bit_offset += bit_size;
					}

					lbValue cv = lb_const_int(m, t_int, count);
					vals[1] = llvm_const_slice(m, memory_names,       cv);
					vals[2] = llvm_const_slice(m, memory_types,       cv);
					vals[3] = llvm_const_slice(m, memory_bit_sizes,   cv);
					vals[4] = llvm_const_slice(m, memory_bit_offsets, cv);
					vals[5] = llvm_const_slice(m, memory_tags,        cv);
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
