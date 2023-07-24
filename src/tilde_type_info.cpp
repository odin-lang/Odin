gb_internal void cg_global_const_type_info_ptr(cgModule *m, TB_Global *type_info_array, Type *type, TB_Global *global, i64 offset) {
	i64 index_in_bytes = cast(i64)cg_type_info_index(m->info, type);
	index_in_bytes *= type_size_of(t_type_info);

	void *ti_ptr_ptr = tb_global_add_region(m->mod, global, offset, build_context.ptr_size);
	// NOTE(bill): define the byte offset for the pointer
	cg_write_int_at_ptr(ti_ptr_ptr, index_in_bytes, t_uintptr);

	// NOTE(bill): this will add to the byte offset set previously
	tb_global_add_symbol_reloc(m->mod, global, offset, cast(TB_Symbol *)type_info_array);
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
			}
		}

		if (count > 0) {
			{
				char const *name = CG_TYPE_INFO_TYPES_NAME;
				Type *t = alloc_type_array(t_type_info_ptr, count);
				TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count*2);
				cg_global_type_info_member_types = cg_addr(cg_value(g, alloc_type_pointer(t)));
			}
			{
				char const *name = CG_TYPE_INFO_NAMES_NAME;
				Type *t = alloc_type_array(t_string, count);
				TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count*2);
				cg_global_type_info_member_names = cg_addr(cg_value(g, alloc_type_pointer(t)));
			}
			{
				char const *name = CG_TYPE_INFO_OFFSETS_NAME;
				Type *t = alloc_type_array(t_uintptr, count);
				TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
				cg_global_type_info_member_offsets = cg_addr(cg_value(g, alloc_type_pointer(t)));
			}

			{
				char const *name = CG_TYPE_INFO_USINGS_NAME;
				Type *t = alloc_type_array(t_bool, count);
				TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
				cg_global_type_info_member_usings = cg_addr(cg_value(g, alloc_type_pointer(t)));
			}

			{
				char const *name = CG_TYPE_INFO_TAGS_NAME;
				Type *t = alloc_type_array(t_string, count);
				TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count*2);
				cg_global_type_info_member_tags = cg_addr(cg_value(g, alloc_type_pointer(t)));
			}
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

		void *size_ptr  = tb_global_add_region(m->mod,  global, offset+size_offset, build_context.int_size);
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

			if (t->Named.type_name->pkg) {
				i64 pkg_offset = type_offset_of(tag_type, 2);
				String pkg_name = t->Named.type_name->pkg->name;
				cg_global_const_string(m, pkg_name, t_string, global, offset+pkg_offset);
			}

			String proc_name = {};
			if (t->Named.type_name->parent_proc_decl) {
				DeclInfo *decl = t->Named.type_name->parent_proc_decl;
				if (decl->entity && decl->entity->kind == Entity_Procedure) {
					i64 name_offset = type_offset_of(tag_type, 0);
					proc_name = decl->entity->token.string;
					cg_global_const_string(m, proc_name, t_string, global, offset+name_offset);
				}
			}

			i64 loc_offset = type_offset_of(tag_type, 3);
			TokenPos pos = t->Named.type_name->token.pos;
			cg_global_source_code_location_const(m, proc_name, pos, global, offset+loc_offset);

			i64 base_offset = type_offset_of(tag_type, 1);
			cg_global_const_type_info_ptr(m, type_table_array, t->Named.base, global, offset+base_offset);
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
				{
					tag_type = t_type_info_string;
					bool *b = cast(bool *)tb_global_add_region(m->mod, global, offset+0, 1);
					*b = true;
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
		}

		if (tag_type != nullptr) {
			i64 union_index = union_variant_index(type_info_union, tag_type);
			GB_ASSERT(union_index != 0);
			void *tag_ptr = tb_global_add_region(m->mod, global, offset+union_tag_offset, union_tag_type_size);
			cg_write_int_at_ptr(tag_ptr, union_index, ti_union_tag_type);
		}

	}
}