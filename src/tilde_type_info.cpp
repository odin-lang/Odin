gb_internal void cg_global_const_type_info_ptr(cgModule *m, Type *type, TB_Global *global, i64 offset) {
	GB_ASSERT(type != nullptr);
	TB_Symbol *type_table_array = cg_find_symbol_from_entity(m, cg_global_type_info_data_entity);


	i64 index_in_bytes = cast(i64)cg_type_info_index(m->info, type);
	index_in_bytes *= type_size_of(t_type_info);

	void *ti_ptr_ptr = tb_global_add_region(m->mod, global, offset, build_context.ptr_size);
	// NOTE(bill): define the byte offset for the pointer
	cg_write_int_at_ptr(ti_ptr_ptr, index_in_bytes, t_uintptr);

	// NOTE(bill): this will add to the byte offset set previously
	tb_global_add_symbol_reloc(m->mod, global, offset, type_table_array);
}

gb_internal cgValue cg_global_type_info_data_ptr(cgProcedure *p) {
	cgValue v = cg_find_value_from_entity(p->module, cg_global_type_info_data_entity);
	return cg_flatten_value(p, v);
}

gb_internal isize cg_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found) {
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
		GB_PANIC("NOT FOUND lb_type_info_index '%s' @ index %td", type_to_string(type), index);
	}
	return -1;
}

gb_internal cgValue cg_type_info(cgProcedure *p, Type *type) {
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);

	isize index = cg_type_info_index(p->module->info, type);
	GB_ASSERT(index >= 0);

	cgValue data = cg_global_type_info_data_ptr(p);
	return cg_emit_array_epi(p, data, index);
}


gb_internal u64 cg_typeid_as_u64(cgModule *m, Type *type) {
	GB_ASSERT(!build_context.no_rtti);

	type = default_type(type);

	u64 id = cast(u64)cg_type_info_index(m->info, type);
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
	case Type_Pointer:              kind = Typeid_Pointer;                break;
	case Type_MultiPointer:         kind = Typeid_Multi_Pointer;          break;
	case Type_Array:                kind = Typeid_Array;                  break;
	case Type_Matrix:               kind = Typeid_Matrix;                 break;
	case Type_EnumeratedArray:      kind = Typeid_Enumerated_Array;       break;
	case Type_Slice:                kind = Typeid_Slice;                  break;
	case Type_DynamicArray:         kind = Typeid_Dynamic_Array;          break;
	case Type_Map:                  kind = Typeid_Map;                    break;
	case Type_Struct:               kind = Typeid_Struct;                 break;
	case Type_Enum:                 kind = Typeid_Enum;                   break;
	case Type_Union:                kind = Typeid_Union;                  break;
	case Type_Tuple:                kind = Typeid_Tuple;                  break;
	case Type_Proc:                 kind = Typeid_Procedure;              break;
	case Type_BitSet:               kind = Typeid_Bit_Set;                break;
	case Type_SimdVector:           kind = Typeid_Simd_Vector;            break;
	case Type_RelativePointer:      kind = Typeid_Relative_Pointer;       break;
	case Type_RelativeMultiPointer: kind = Typeid_Relative_Multi_Pointer; break;
	case Type_SoaPointer:           kind = Typeid_SoaPointer;             break;
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

	return data;
}

gb_internal cgValue cg_typeid(cgProcedure *p, Type *t) {
	u64 x = cg_typeid_as_u64(p->module, t);
	return cg_value(tb_inst_uint(p->func, cg_data_type(t_typeid), x), t_typeid);
}




gb_internal void cg_set_type_info_member_types(cgModule *m, TB_Global *global, isize offset, isize count, void *userdata, Type *(*type_proc)(isize index, void *userdata)) {
	if (count == 0) {
		return;
	}

	void *data_ptr = tb_global_add_region(m->mod, global, offset+0, build_context.ptr_size);
	i64 offset_in_bytes = cg_global_type_info_member_types.index * type_size_of(cg_global_type_info_member_types.elem_type);
	cg_global_type_info_member_types.index += count;

	cg_write_int_at_ptr(data_ptr, offset_in_bytes, t_uintptr);
	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)cg_global_type_info_member_types.global);

	for (isize i = 0; i < count; i++) {
		i64 elem_size = type_size_of(cg_global_type_info_member_types.elem_type);
		Type *type = type_proc(i, userdata);
		i64 offset_for_elem = offset_in_bytes + i*elem_size;
		cg_global_const_type_info_ptr(m, type, cg_global_type_info_member_types.global, offset_for_elem);
	}

	void *len_ptr  = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, count, t_int);
}


gb_internal void cg_set_type_info_member_names(cgModule *m, TB_Global *global, isize offset, isize count, void *userdata, String (*name_proc)(isize index, void *userdata)) {
	if (count == 0) {
		return;
	}
	void *data_ptr = tb_global_add_region(m->mod, global, offset+0, build_context.ptr_size);
	i64 offset_in_bytes = cg_global_type_info_member_names.index * type_size_of(cg_global_type_info_member_names.elem_type);
	cg_global_type_info_member_names.index += count;

	cg_write_int_at_ptr(data_ptr, offset_in_bytes, t_uintptr);
	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)cg_global_type_info_member_names.global);

	for (isize i = 0; i < count; i++) {
		i64 elem_size = type_size_of(cg_global_type_info_member_names.elem_type);
		String name = name_proc(i, userdata);
		i64 offset_for_elem = offset_in_bytes + i*elem_size;
		cg_global_const_string(m, name, cg_global_type_info_member_names.elem_type, cg_global_type_info_member_names.global, offset_for_elem);

	}

	void *len_ptr  = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, count, t_int);
}


gb_internal void cg_set_type_info_member_offsets(cgModule *m, TB_Global *global, isize offset, isize count, void *userdata, i64 (*offset_proc)(isize index, void *userdata)) {
	if (count == 0) {
		return;
	}
	void *data_ptr = tb_global_add_region(m->mod, global, offset+0, build_context.ptr_size);
	i64 offset_in_bytes = cg_global_type_info_member_offsets.index * type_size_of(cg_global_type_info_member_offsets.elem_type);
	cg_global_type_info_member_offsets.index += count;

	cg_write_int_at_ptr(data_ptr, offset_in_bytes, t_uintptr);
	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)cg_global_type_info_member_offsets.global);

	for (isize i = 0; i < count; i++) {
		i64 elem_size = type_size_of(cg_global_type_info_member_offsets.elem_type);
		i64 the_offset = offset_proc(i, userdata);
		i64 offset_for_elem = offset_in_bytes + i*elem_size;

		void *offset_ptr = tb_global_add_region(m->mod, cg_global_type_info_member_offsets.global, offset_for_elem, elem_size);
		cg_write_uint_at_ptr(offset_ptr, the_offset, t_uintptr);
	}

	void *len_ptr  = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, count, t_int);
}

gb_internal void cg_set_type_info_member_usings(cgModule *m, TB_Global *global, isize offset, isize count, void *userdata, bool (*usings_proc)(isize index, void *userdata)) {
	if (count == 0) {
		return;
	}
	void *data_ptr = tb_global_add_region(m->mod, global, offset+0, build_context.ptr_size);
	i64 offset_in_bytes = cg_global_type_info_member_usings.index * type_size_of(cg_global_type_info_member_usings.elem_type);
	cg_global_type_info_member_usings.index += count;

	cg_write_int_at_ptr(data_ptr, offset_in_bytes, t_uintptr);
	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)cg_global_type_info_member_usings.global);

	for (isize i = 0; i < count; i++) {
		i64 elem_size = type_size_of(cg_global_type_info_member_usings.elem_type);
		GB_ASSERT(elem_size == 1);
		bool the_usings = usings_proc(i, userdata);
		i64 offset_for_elem = offset_in_bytes + i*elem_size;

		bool *usings_ptr = cast(bool *)tb_global_add_region(m->mod, cg_global_type_info_member_usings.global, offset_for_elem, 1);
		*usings_ptr = the_usings;
	}

	void *len_ptr  = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, count, t_int);
}



gb_internal void cg_set_type_info_member_tags(cgModule *m, TB_Global *global, isize offset, isize count, void *userdata, String (*tag_proc)(isize index, void *userdata)) {
	if (count == 0) {
		return;
	}
	void *data_ptr = tb_global_add_region(m->mod, global, offset+0, build_context.ptr_size);
	i64 offset_in_bytes = cg_global_type_info_member_tags.index * type_size_of(cg_global_type_info_member_tags.elem_type);
	cg_global_type_info_member_tags.index += count;

	cg_write_int_at_ptr(data_ptr, offset_in_bytes, t_uintptr);
	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)cg_global_type_info_member_tags.global);

	for (isize i = 0; i < count; i++) {
		i64 elem_size = type_size_of(cg_global_type_info_member_tags.elem_type);
		String tag = tag_proc(i, userdata);
		i64 offset_for_elem = offset_in_bytes + i*elem_size;
		cg_global_const_string(m, tag, cg_global_type_info_member_tags.elem_type, cg_global_type_info_member_tags.global, offset_for_elem);

	}

	void *len_ptr  = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, count, t_int);
}

gb_internal void cg_set_type_info_member_enum_values(cgModule *m, TB_Global *global, isize offset, isize count, void *userdata, i64 (*value_proc)(isize index, void *userdata)) {
	if (count == 0) {
		return;
	}
	void *data_ptr = tb_global_add_region(m->mod, global, offset+0, build_context.ptr_size);
	i64 offset_in_bytes = cg_global_type_info_member_enum_values.index * type_size_of(cg_global_type_info_member_enum_values.elem_type);
	cg_global_type_info_member_enum_values.index += count;

	cg_write_int_at_ptr(data_ptr, offset_in_bytes, t_uintptr);
	tb_global_add_symbol_reloc(m->mod, global, offset+0, cast(TB_Symbol *)cg_global_type_info_member_enum_values.global);

	for (isize i = 0; i < count; i++) {
		i64 elem_size = type_size_of(cg_global_type_info_member_enum_values.elem_type);
		GB_ASSERT(elem_size == 8);
		i64 the_value = value_proc(i, userdata);
		i64 offset_for_elem = offset_in_bytes + i*elem_size;

		void *offset_ptr = tb_global_add_region(m->mod, cg_global_type_info_member_enum_values.global, offset_for_elem, elem_size);
		cg_write_uint_at_ptr(offset_ptr, the_value, cg_global_type_info_member_enum_values.elem_type);
	}

	void *len_ptr  = tb_global_add_region(m->mod, global, offset+build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, count, t_int);
}



gb_internal void cg_setup_type_info_data(cgModule *m) {
	if (build_context.no_rtti) {
		return;
	}

	CheckerInfo *info = m->info;
	{ // Add type info data
		isize max_type_info_count = info->minimum_dependency_type_info_set.count+1;
		// gb_printf_err("max_type_info_count: %td\n", max_type_info_count);
		Type *t = alloc_type_array(t_type_info, max_type_info_count);

		i64 max_objects = cast(i64)max_type_info_count * cg_global_const_calculate_region_count_from_basic_type(t_type_info);

		TB_Global *g = tb_global_create(m->mod, -1, CG_TYPE_INFO_DATA_NAME, nullptr, TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, max_objects);

		cgValue value = cg_value(g, alloc_type_pointer(t));
		cg_global_type_info_data_entity = alloc_entity_variable(nullptr, make_token_ident(CG_TYPE_INFO_DATA_NAME), t, EntityState_Resolved);
		cg_add_symbol(m, cg_global_type_info_data_entity, cast(TB_Symbol *)g);
		cg_add_entity(m, cg_global_type_info_data_entity, value);
	}

	{ // Type info member buffer
		// NOTE(bill): Removes need for heap allocation by making it global memory
		isize count = 0;
		isize enum_count = 0;

		for (Type *t : m->info->type_info_types) {
			isize index = cg_type_info_index(m->info, t, false);
			if (index < 0) {
				continue;
			}

			switch (t->kind) {
			case Type_Union:
				count += t->Union.variants.count;
				break;
			case Type_Struct:
				count += t->Struct.fields.count;
				break;
			case Type_Tuple:
				count += t->Tuple.variables.count;
				break;
			case Type_Enum:
				enum_count += t->Enum.fields.count;
				break;
			}
		}

		if (count > 0) {
			char const *name = CG_TYPE_INFO_TYPES_NAME;
			Type *t = alloc_type_array(t_type_info_ptr, count);
			TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count*3);
			cg_global_type_info_member_types = GlobalTypeInfoData{g, t, t_type_info_ptr, 0};
		}
		if (count > 0 || enum_count > 0) {
			char const *name = CG_TYPE_INFO_NAMES_NAME;
			Type *t = alloc_type_array(t_string, (enum_count+count));
			TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, (enum_count+count)*3);
			cg_global_type_info_member_names = GlobalTypeInfoData{g, t, t_string, 0};
		}
		if (count > 0) {
			char const *name = CG_TYPE_INFO_OFFSETS_NAME;
			Type *t = alloc_type_array(t_uintptr, count);
			TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
			cg_global_type_info_member_offsets = GlobalTypeInfoData{g, t, t_uintptr, 0};
		}

		if (count > 0) {
			char const *name = CG_TYPE_INFO_USINGS_NAME;
			Type *t = alloc_type_array(t_bool, count);
			TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
			cg_global_type_info_member_usings = GlobalTypeInfoData{g, t, t_bool, 0};
		}

		if (count > 0) {
			char const *name = CG_TYPE_INFO_TAGS_NAME;
			Type *t = alloc_type_array(t_string, count);
			TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count*3);
			cg_global_type_info_member_tags = GlobalTypeInfoData{g, t, t_string, 0};
		}

		if (enum_count > 0) {
			char const *name = CG_TYPE_INFO_ENUM_VALUES_NAME;
			Type *t = alloc_type_array(t_i64, enum_count);
			TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, enum_count);
			cg_global_type_info_member_enum_values = GlobalTypeInfoData{g, t, t_i64, 0};
		}
	}
	gb_unused(info);


	i64 global_type_info_data_entity_count = 0;

	// NOTE(bill): Set the type_table slice with the global backing array
	TB_Global *type_table_slice = cast(TB_Global *)cg_find_symbol_from_entity(m, scope_lookup_current(m->info->runtime_package->scope, str_lit("type_table")));
	GB_ASSERT(type_table_slice != nullptr);

	TB_Global *type_table_array = cast(TB_Global *)cg_find_symbol_from_entity(m, cg_global_type_info_data_entity);
	GB_ASSERT(type_table_array != nullptr);

	Type *type = base_type(cg_global_type_info_data_entity->type);
	GB_ASSERT(is_type_array(type));
	global_type_info_data_entity_count = type->Array.count;

	tb_global_add_symbol_reloc(m->mod, type_table_slice, 0, cast(TB_Symbol *)type_table_array);

	void *len_ptr = tb_global_add_region(m->mod, type_table_slice, build_context.int_size, build_context.int_size);
	cg_write_int_at_ptr(len_ptr, type->Array.count, t_int);

	// Useful types
	Entity *type_info_flags_entity = find_core_entity(info->checker, str_lit("Type_Info_Flags"));
	Type *t_type_info_flags = type_info_flags_entity->type;
	GB_ASSERT(type_size_of(t_type_info_flags) == 4);

	auto entries_handled = slice_make<bool>(heap_allocator(), cast(isize)global_type_info_data_entity_count);
	defer (gb_free(heap_allocator(), entries_handled.data));
	entries_handled[0] = true;


	i64 type_info_size = type_size_of(t_type_info);
	i64 size_offset    = type_offset_of(t_type_info, 0);
	i64 align_offset   = type_offset_of(t_type_info, 1);
	i64 flags_offset   = type_offset_of(t_type_info, 2);
	i64 id_offset      = type_offset_of(t_type_info, 3);
	i64 variant_offset = type_offset_of(t_type_info, 4);

	Type *type_info_union = base_type(t_type_info)->Struct.fields[4]->type;
	GB_ASSERT(type_info_union->kind == Type_Union);

	i64 union_tag_offset    = type_info_union->Union.variant_block_size;
	Type *ti_union_tag_type = union_tag_type(type_info_union);
	u64 union_tag_type_size = type_size_of(ti_union_tag_type);

	auto const &set_bool = [](cgModule *m, TB_Global *global, i64 offset, bool value) {
		bool *ptr = cast(bool *)tb_global_add_region(m->mod, global, offset, 1);
		*ptr = value;
	};


	for_array(type_info_type_index, info->type_info_types) {
		Type *t = info->type_info_types[type_info_type_index];
		if (t == nullptr || t == t_invalid) {
			continue;
		}

		isize entry_index = cg_type_info_index(info, t, false);
		if (entry_index <= 0) {
			continue;
		}

		if (entries_handled[entry_index]) {
			continue;
		}
		entries_handled[entry_index] = true;

		TB_Global *global = type_table_array;

		i64 offset = entry_index * type_info_size;

		i64 size  = type_size_of(t);
		i64 align = type_align_of(t);
		u32 flags = type_info_flags_of_type(t);
		u64 id    = cg_typeid_as_u64(m, t);

		void *size_ptr  = tb_global_add_region(m->mod, global, offset+size_offset,  build_context.int_size);
		void *align_ptr = tb_global_add_region(m->mod, global, offset+align_offset, build_context.int_size);
		void *flags_ptr = tb_global_add_region(m->mod, global, offset+flags_offset, 4);
		void *id_ptr    = tb_global_add_region(m->mod, global, offset+id_offset,    build_context.ptr_size);
		cg_write_int_at_ptr (size_ptr,  size,  t_int);
		cg_write_int_at_ptr (align_ptr, align, t_int);
		cg_write_int_at_ptr (flags_ptr, flags, t_u32);
		cg_write_uint_at_ptr(id_ptr,    id,    t_typeid);


		// add data to the offset to make it easier to deal with later on
		offset += variant_offset;

		Type *tag_type = nullptr;

		switch (t->kind) {
		case Type_Named: {
			// Type_Info_Named :: struct {
			// 	name: string,
			// 	base: ^Type_Info,
			// 	pkg:  string,
			// 	loc:  Source_Code_Location,
			// }
			tag_type = t_type_info_named;

			i64 name_offset = type_offset_of(tag_type, 0);
			String name = t->Named.type_name->token.string;
			cg_global_const_string(m, name, t_string, global, offset+name_offset);

			i64 base_offset = type_offset_of(tag_type, 1);
			cg_global_const_type_info_ptr(m, t->Named.base, global, offset+base_offset);

			if (t->Named.type_name->pkg) {
				i64 pkg_offset = type_offset_of(tag_type, 2);
				String pkg_name = t->Named.type_name->pkg->name;
				cg_global_const_string(m, pkg_name, t_string, global, offset+pkg_offset);
			}

			String proc_name = {};
			if (DeclInfo *decl = t->Named.type_name->parent_proc_decl.load(std::memory_order_relaxed)) {
				if (decl->entity && decl->entity->kind == Entity_Procedure) {
					i64 name_offset = type_offset_of(tag_type, 0);
					proc_name = decl->entity->token.string;
					cg_global_const_string(m, proc_name, t_string, global, offset+name_offset);
				}
			}

			i64 loc_offset = type_offset_of(tag_type, 3);
			TokenPos pos = t->Named.type_name->token.pos;
			cg_global_source_code_location_const(m, proc_name, pos, global, offset+loc_offset);

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

				bool is_signed = (t->Basic.flags & BasicFlag_Unsigned) == 0;
				// NOTE(bill): This is matches the runtime layout
				u8 endianness_value = 0;
				if (t->Basic.flags & BasicFlag_EndianLittle) {
					endianness_value = 1;
				} else if (t->Basic.flags & BasicFlag_EndianBig) {
					endianness_value = 2;
				}
				u8 *signed_ptr     = cast(u8 *)tb_global_add_region(m->mod, global, offset+0, 1);
				u8 *endianness_ptr = cast(u8 *)tb_global_add_region(m->mod, global, offset+1, 1);
				*signed_ptr     = is_signed;
				*endianness_ptr = endianness_value;
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

					// // NOTE(bill): This is matches the runtime layout
					u8 endianness_value = 0;
					if (t->Basic.flags & BasicFlag_EndianLittle) {
						endianness_value = 1;
					} else if (t->Basic.flags & BasicFlag_EndianBig) {
						endianness_value = 2;
					}

					u8 *ptr = cast(u8 *)tb_global_add_region(m->mod, global, offset+0, 1);
					*ptr = endianness_value;
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
				tag_type = t_type_info_string;
				set_bool(m, global, offset+0, true);
				break;

			case Basic_any:
				tag_type = t_type_info_any;
				break;

			case Basic_typeid:
				tag_type = t_type_info_typeid;
				break;
			}
			break;

		case Type_Pointer:
			tag_type = t_type_info_pointer;
			cg_global_const_type_info_ptr(m, t->Pointer.elem, global, offset+0);
			break;
		case Type_MultiPointer:
			tag_type = t_type_info_multi_pointer;
			cg_global_const_type_info_ptr(m, t->MultiPointer.elem, global, offset+0);
			break;
		case Type_SoaPointer:
			tag_type = t_type_info_soa_pointer;
			cg_global_const_type_info_ptr(m, t->SoaPointer.elem, global, offset+0);
			break;

		case Type_Array:
			{
				tag_type = t_type_info_array;

				cg_global_const_type_info_ptr(m, t->Array.elem, global, offset+0);
				void *elem_size_ptr = tb_global_add_region(m->mod, global, offset+1*build_context.int_size, build_context.int_size);
				void *count_ptr     = tb_global_add_region(m->mod, global, offset+2*build_context.int_size, build_context.int_size);

				cg_write_int_at_ptr(elem_size_ptr, type_size_of(t->Array.elem), t_int);
				cg_write_int_at_ptr(count_ptr,     t->Array.count,              t_int);
			}
			break;

		case Type_EnumeratedArray:
			{
				tag_type = t_type_info_enumerated_array;

				i64 elem_offset      = type_offset_of(tag_type, 0);
				i64 index_offset     = type_offset_of(tag_type, 1);
				i64 elem_size_offset = type_offset_of(tag_type, 2);
				i64 count_offset     = type_offset_of(tag_type, 3);
				i64 min_value_offset = type_offset_of(tag_type, 4);
				i64 max_value_offset = type_offset_of(tag_type, 5);
				i64 is_sparse_offset = type_offset_of(tag_type, 6);

				cg_global_const_type_info_ptr(m, t->EnumeratedArray.elem,  global, offset+elem_offset);
				cg_global_const_type_info_ptr(m, t->EnumeratedArray.index, global, offset+index_offset);

				void *elem_size_ptr = tb_global_add_region(m->mod, global, offset+elem_size_offset, build_context.int_size);
				void *count_ptr     = tb_global_add_region(m->mod, global, offset+count_offset,     build_context.int_size);

				void *min_value_ptr = tb_global_add_region(m->mod, global, offset+min_value_offset, type_size_of(t_type_info_enum_value));
				void *max_value_ptr = tb_global_add_region(m->mod, global, offset+max_value_offset, type_size_of(t_type_info_enum_value));

				cg_write_int_at_ptr(elem_size_ptr, type_size_of(t->EnumeratedArray.elem), t_int);
				cg_write_int_at_ptr(count_ptr,     t->EnumeratedArray.count,              t_int);

				cg_write_int_at_ptr(min_value_ptr, exact_value_to_i64(*t->EnumeratedArray.min_value), t_type_info_enum_value);
				cg_write_int_at_ptr(max_value_ptr, exact_value_to_i64(*t->EnumeratedArray.max_value), t_type_info_enum_value);
				set_bool(m, global, offset+is_sparse_offset, t->EnumeratedArray.is_sparse);
			}
			break;

		case Type_DynamicArray:
			{
				tag_type = t_type_info_dynamic_array;

				cg_global_const_type_info_ptr(m, t->DynamicArray.elem, global, offset+0);
				void *elem_size_ptr = tb_global_add_region(m->mod, global, offset+1*build_context.int_size, build_context.int_size);
				cg_write_int_at_ptr(elem_size_ptr, type_size_of(t->DynamicArray.elem), t_int);
			}
			break;
		case Type_Slice:
			{
				tag_type = t_type_info_slice;

				cg_global_const_type_info_ptr(m, t->Slice.elem, global, offset+0);
				void *elem_size_ptr = tb_global_add_region(m->mod, global, offset+1*build_context.int_size, build_context.int_size);
				cg_write_int_at_ptr(elem_size_ptr, type_size_of(t->Slice.elem), t_int);
			}
			break;

		case Type_Proc:
			{
				tag_type = t_type_info_procedure;

				i64 params_offset     = type_offset_of(tag_type, 0);
				i64 results_offset    = type_offset_of(tag_type, 1);
				i64 variadic_offset   = type_offset_of(tag_type, 2);
				i64 convention_offset = type_offset_of(tag_type, 3);

				if (t->Proc.params) {
					cg_global_const_type_info_ptr(m, t->Proc.params, global, offset+params_offset);
				}
				if (t->Proc.results) {
					cg_global_const_type_info_ptr(m, t->Proc.results, global, offset+results_offset);
				}

				set_bool(m, global, offset+variadic_offset, t->Proc.variadic);

				u8 *convention_ptr = cast(u8 *)tb_global_add_region(m->mod, global, offset+convention_offset, 1);
				*convention_ptr = cast(u8)t->Proc.calling_convention;
			}
			break;

		case Type_Tuple:
			{
				tag_type = t_type_info_parameters;

				i64 types_offset = type_offset_of(tag_type, 0);
				i64 names_offset = type_offset_of(tag_type, 1);

				i64 count = t->Tuple.variables.count;

				cg_set_type_info_member_types(m, global, offset+types_offset, count, t, [](isize i, void *userdata) -> Type * {
					Type *t = cast(Type *)userdata;
					return t->Tuple.variables[i]->type;
				});

				cg_set_type_info_member_names(m, global, offset+names_offset, count, t, [](isize i, void *userdata) -> String {
					Type *t = cast(Type *)userdata;
					return t->Tuple.variables[i]->token.string;
				});
			}
			break;

		case Type_Enum:
			{
				tag_type = t_type_info_enum;

				i64 base_offset   = type_offset_of(tag_type, 0);
				i64 names_offset  = type_offset_of(tag_type, 1);
				i64 values_offset = type_offset_of(tag_type, 2);

				cg_global_const_type_info_ptr(m, t->Enum.base_type, global, offset+base_offset);

				i64 count = t->Enum.fields.count;

				cg_set_type_info_member_names(m, global, offset+names_offset, count, t, [](isize i, void *userdata) -> String {
					Type *t = cast(Type *)userdata;
					return t->Enum.fields[i]->token.string;
				});

				cg_set_type_info_member_enum_values(m, global, offset+values_offset, count, t, [](isize i, void *userdata) -> i64 {
					Type *t = cast(Type *)userdata;
					Entity *e = t->Enum.fields[i];
					GB_ASSERT(e->kind == Entity_Constant);
					return exact_value_to_i64(e->Constant.value);
				});
			}
			break;
		case Type_Struct:
			{
				tag_type = t_type_info_struct;

				i64 types_offset         = type_offset_of(tag_type, 0);
				i64 names_offset         = type_offset_of(tag_type, 1);
				i64 offsets_offset       = type_offset_of(tag_type, 2);
				i64 usings_offset        = type_offset_of(tag_type, 3);
				i64 tags_offset          = type_offset_of(tag_type, 4);

				i64 is_packed_offset     = type_offset_of(tag_type, 5);
				i64 is_raw_union_offset  = type_offset_of(tag_type, 6);
				i64 custom_align_offset  = type_offset_of(tag_type, 7);

				i64 equal_offset         = type_offset_of(tag_type, 8);

				i64 soa_kind_offset      = type_offset_of(tag_type, 9);
				i64 soa_base_type_offset = type_offset_of(tag_type, 10);
				i64 soa_len_offset       = type_offset_of(tag_type, 11);

				// TODO(bill): equal proc stuff
				gb_unused(equal_offset);

				i64 count = t->Struct.fields.count;

				cg_set_type_info_member_types(m, global, offset+types_offset, count, t, [](isize i, void *userdata) -> Type * {
					Type *t = cast(Type *)userdata;
					return t->Struct.fields[i]->type;
				});

				cg_set_type_info_member_names(m, global, offset+names_offset, count, t, [](isize i, void *userdata) -> String {
					Type *t = cast(Type *)userdata;
					return t->Struct.fields[i]->token.string;
				});

				cg_set_type_info_member_offsets(m, global, offset+offsets_offset, count, t, [](isize i, void *userdata) -> i64 {
					Type *t = cast(Type *)userdata;
					return t->Struct.offsets[i];
				});

				cg_set_type_info_member_usings(m, global, offset+usings_offset, count, t, [](isize i, void *userdata) -> bool {
					Type *t = cast(Type *)userdata;
					return (t->Struct.fields[i]->flags & EntityFlag_Using) != 0;
				});

				cg_set_type_info_member_tags(m, global, offset+tags_offset, count, t, [](isize i, void *userdata) -> String {
					Type *t = cast(Type *)userdata;
					return t->Struct.tags[i];
				});


				set_bool(m, global, offset+is_packed_offset,    t->Struct.is_packed);
				set_bool(m, global, offset+is_raw_union_offset, t->Struct.is_raw_union);
				set_bool(m, global, offset+custom_align_offset, t->Struct.custom_align != 0);

				if (t->Struct.soa_kind != StructSoa_None) {
					u8 *kind_ptr = cast(u8 *)tb_global_add_region(m->mod, global, offset+soa_kind_offset, 1);
					*kind_ptr = cast(u8)t->Struct.soa_kind;

					cg_global_const_type_info_ptr(m, t->Struct.soa_elem, global, offset+soa_base_type_offset);

					void *soa_len_ptr = tb_global_add_region(m->mod, global, offset+soa_len_offset, build_context.int_size);
					cg_write_int_at_ptr(soa_len_ptr, t->Struct.soa_count, t_int);
				}
			}
			break;
		case Type_Union:
			{
				tag_type = t_type_info_union;

				i64 variants_offset      = type_offset_of(tag_type, 0);
				i64 tag_offset_offset    = type_offset_of(tag_type, 1);
				i64 tag_type_offset      = type_offset_of(tag_type, 2);

				i64 equal_offset         = type_offset_of(tag_type, 3);

				i64 custom_align_offset  = type_offset_of(tag_type, 4);
				i64 no_nil_offset        = type_offset_of(tag_type, 5);
				i64 shared_nil_offset    = type_offset_of(tag_type, 6);

				// TODO(bill): equal procs
				gb_unused(equal_offset);

				i64 count = t->Union.variants.count;

				cg_set_type_info_member_types(m, global, offset+variants_offset, count, t, [](isize i, void *userdata) -> Type * {
					Type *t = cast(Type *)userdata;
					return t->Union.variants[i];
				});

				void *tag_offset_ptr = tb_global_add_region(m->mod, global, offset+tag_offset_offset, build_context.ptr_size);
				cg_write_uint_at_ptr(tag_offset_ptr, t->Union.variant_block_size, t_uintptr);

				cg_global_const_type_info_ptr(m, union_tag_type(t), global, offset+tag_type_offset);

				set_bool(m, global, offset+custom_align_offset, t->Union.custom_align != 0);
				set_bool(m, global, offset+no_nil_offset, t->Union.kind == UnionType_no_nil);
				set_bool(m, global, offset+shared_nil_offset, t->Union.kind == UnionType_shared_nil);
			}
			break;
		case Type_Map:
			{
				tag_type = t_type_info_map;

				i64 key_offset      = type_offset_of(tag_type, 0);
				i64 value_offset    = type_offset_of(tag_type, 1);
				i64 map_info_offset = type_offset_of(tag_type, 2);

				// TODO(bill): map info
				gb_unused(map_info_offset);

				cg_global_const_type_info_ptr(m, t->Map.key,   global, offset+key_offset);
				cg_global_const_type_info_ptr(m, t->Map.value, global, offset+value_offset);

			}
			break;
		case Type_BitSet:
			{
				tag_type = t_type_info_bit_set;

				i64 elem_offset       = type_offset_of(tag_type, 0);
				i64 underlying_offset = type_offset_of(tag_type, 1);
				i64 lower_offset      = type_offset_of(tag_type, 2);
				i64 upper_offset      = type_offset_of(tag_type, 3);

				cg_global_const_type_info_ptr(m, t->BitSet.elem, global, offset+elem_offset);
				if (t->BitSet.underlying) {
					cg_global_const_type_info_ptr(m, t->BitSet.underlying, global, offset+underlying_offset);
				}

				void *lower_ptr = tb_global_add_region(m->mod, global, offset+lower_offset, 8);
				void *upper_ptr = tb_global_add_region(m->mod, global, offset+upper_offset, 8);

				cg_write_int_at_ptr(lower_ptr, t->BitSet.lower, t_i64);
				cg_write_int_at_ptr(upper_ptr, t->BitSet.upper, t_i64);
			}
			break;
		case Type_SimdVector:
			{
				tag_type = t_type_info_simd_vector;

				i64 elem_offset      = type_offset_of(tag_type, 0);
				i64 elem_size_offset = type_offset_of(tag_type, 1);
				i64 count_offset     = type_offset_of(tag_type, 2);

				cg_global_const_type_info_ptr(m, t->SimdVector.elem, global, offset+elem_offset);

				void *elem_size_ptr = tb_global_add_region(m->mod, global, offset+elem_size_offset, build_context.int_size);
				void *count_ptr     = tb_global_add_region(m->mod, global, offset+count_offset,     build_context.int_size);

				cg_write_int_at_ptr(elem_size_ptr, type_size_of(t->SimdVector.elem), t_int);
				cg_write_int_at_ptr(count_ptr,     t->SimdVector.count,              t_int);
			}
			break;

		case Type_RelativePointer:
			{
				tag_type = t_type_info_relative_pointer;

				i64 pointer_offset      = type_offset_of(tag_type, 0);
				i64 base_integer_offset = type_offset_of(tag_type, 1);

				cg_global_const_type_info_ptr(m, t->RelativePointer.pointer_type, global, offset+pointer_offset);
				cg_global_const_type_info_ptr(m, t->RelativePointer.base_integer, global, offset+base_integer_offset);
			}
			break;
		case Type_RelativeMultiPointer:
			{
				tag_type = t_type_info_relative_multi_pointer;

				i64 pointer_offset      = type_offset_of(tag_type, 0);
				i64 base_integer_offset = type_offset_of(tag_type, 1);

				cg_global_const_type_info_ptr(m, t->RelativePointer.pointer_type, global, offset+pointer_offset);
				cg_global_const_type_info_ptr(m, t->RelativePointer.base_integer, global, offset+base_integer_offset);
			}
			break;
		case Type_Matrix:
			{
				tag_type = t_type_info_matrix;

				i64 elem_offset         = type_offset_of(tag_type, 0);
				i64 elem_size_offset    = type_offset_of(tag_type, 1);
				i64 elem_stride_offset  = type_offset_of(tag_type, 2);
				i64 row_count_offset    = type_offset_of(tag_type, 3);
				i64 column_count_offset = type_offset_of(tag_type, 4);

				cg_global_const_type_info_ptr(m, t->Matrix.elem, global, offset+elem_offset);

				void *elem_size_ptr    = tb_global_add_region(m->mod, global, offset+elem_size_offset,    build_context.int_size);
				void *elem_stride_ptr  = tb_global_add_region(m->mod, global, offset+elem_stride_offset,  build_context.int_size);
				void *row_count_ptr    = tb_global_add_region(m->mod, global, offset+row_count_offset,    build_context.int_size);
				void *column_count_ptr = tb_global_add_region(m->mod, global, offset+column_count_offset, build_context.int_size);

				cg_write_int_at_ptr(elem_size_ptr,    type_size_of(t->Matrix.elem),   t_int);
				cg_write_int_at_ptr(elem_stride_ptr,  matrix_type_stride_in_elems(t), t_int);
				cg_write_int_at_ptr(row_count_ptr,    t->Matrix.row_count,            t_int);
				cg_write_int_at_ptr(column_count_ptr, t->Matrix.column_count,         t_int);

			}
			break;
		}

		if (tag_type != nullptr) {
			i64 union_index = union_variant_index(type_info_union, tag_type);
			GB_ASSERT(union_index != 0);
			void *tag_ptr = tb_global_add_region(m->mod, global, offset+union_tag_offset, union_tag_type_size);
			cg_write_int_at_ptr(tag_ptr, union_index, ti_union_tag_type);
		}

	}
}