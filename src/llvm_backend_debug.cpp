gb_internal LLVMMetadataRef lb_get_llvm_metadata(lbModule *m, void *key) {
	if (key == nullptr) {
		return nullptr;
	}
	mutex_lock(&m->debug_values_mutex);
	auto found = map_get(&m->debug_values, key);
	mutex_unlock(&m->debug_values_mutex);
	if (found) {
		return *found;
	}
	return nullptr;
}
gb_internal void lb_set_llvm_metadata(lbModule *m, void *key, LLVMMetadataRef value) {
	if (key != nullptr) {
		mutex_lock(&m->debug_values_mutex);
		map_set(&m->debug_values, key, value);
		mutex_unlock(&m->debug_values_mutex);
	}
}


gb_internal LLVMMetadataRef lb_get_current_debug_scope(lbProcedure *p) {
	GB_ASSERT_MSG(p->debug_info != nullptr, "missing debug information for %.*s", LIT(p->name));

	for (isize i = p->scope_stack.count-1; i >= 0; i--) {
		Scope *s = p->scope_stack[i];
		LLVMMetadataRef md = lb_get_llvm_metadata(p->module, s);
		if (md) {
			return md;
		}
	}
	return p->debug_info;
}

gb_internal LLVMMetadataRef lb_debug_location_from_token_pos(lbProcedure *p, TokenPos pos) {
	LLVMMetadataRef scope = lb_get_current_debug_scope(p);
	GB_ASSERT_MSG(scope != nullptr, "%.*s", LIT(p->name));
	return LLVMDIBuilderCreateDebugLocation(p->module->ctx, cast(unsigned)pos.line, cast(unsigned)pos.column, scope, nullptr);
}
gb_internal LLVMMetadataRef lb_debug_location_from_ast(lbProcedure *p, Ast *node) {
	GB_ASSERT(node != nullptr);
	return lb_debug_location_from_token_pos(p, ast_token(node).pos);
}
gb_internal LLVMMetadataRef lb_debug_end_location_from_ast(lbProcedure *p, Ast *node) {
	GB_ASSERT(node != nullptr);
	return lb_debug_location_from_token_pos(p, ast_end_token(node).pos);
}

gb_internal void lb_debug_file_line(lbModule *m, Ast *node, LLVMMetadataRef *file, unsigned *line) {
	if (*file == nullptr) {
		if (node) {
			*file = lb_get_llvm_metadata(m, node->file());
			*line = cast(unsigned)ast_token(node).pos.line;
		}
	}
}

gb_internal LLVMMetadataRef lb_debug_type_internal_proc(lbModule *m, Type *type) {
	i64 size = type_size_of(type); // Check size
	gb_unused(size);

	GB_ASSERT(type != t_invalid);

	/* unsigned const ptr_size = cast(unsigned)build_context.ptr_size;
	unsigned const ptr_bits = cast(unsigned)(8*build_context.ptr_size); */

	GB_ASSERT(type->kind == Type_Proc);
	unsigned parameter_count = 1;
	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind == Entity_Variable) {
			parameter_count += 1;
		}
	}
	LLVMMetadataRef *parameters = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, parameter_count);

	unsigned param_index = 0;
	if (type->Proc.result_count == 0) {
		parameters[param_index++] = nullptr;
	} else {
		parameters[param_index++] = lb_debug_type(m, type->Proc.results);
	}

	LLVMMetadataRef file = nullptr;

	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			continue;
		}
		parameters[param_index] = lb_debug_type(m, e->type);
		param_index += 1;
	}

	LLVMDIFlags flags = LLVMDIFlagZero;
	if (type->Proc.diverging) {
		flags = LLVMDIFlagNoReturn;
	}

	return LLVMDIBuilderCreateSubroutineType(m->debug_builder, file, parameters, parameter_count, flags);
}

gb_internal LLVMMetadataRef lb_debug_struct_field(lbModule *m, String const &name, Type *type, u64 offset_in_bits) {
	unsigned field_line = 1;
	LLVMDIFlags field_flags = LLVMDIFlagZero;

	AstPackage *pkg = m->info->runtime_package;
	GB_ASSERT(pkg->files.count != 0);
	LLVMMetadataRef file = lb_get_llvm_metadata(m, pkg->files[0]);
	LLVMMetadataRef scope = file;

	return LLVMDIBuilderCreateMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, field_line,
		8*cast(u64)type_size_of(type), 8*cast(u32)type_align_of(type), offset_in_bits,
		field_flags, lb_debug_type(m, type)
	);
}
gb_internal LLVMMetadataRef lb_debug_basic_struct(lbModule *m, String const &name, u64 size_in_bits, u32 align_in_bits, LLVMMetadataRef *elements, unsigned element_count) {
	AstPackage *pkg = m->info->runtime_package;
	GB_ASSERT(pkg->files.count != 0);
	LLVMMetadataRef file = lb_get_llvm_metadata(m, pkg->files[0]);
	LLVMMetadataRef scope = file;

	return LLVMDIBuilderCreateStructType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, 1, size_in_bits, align_in_bits, LLVMDIFlagZero, nullptr, elements, element_count, 0, nullptr, "", 0);
}

gb_internal LLVMMetadataRef lb_debug_struct(lbModule *m, Type *type, Type *bt, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	GB_ASSERT(bt->kind == Type_Struct);

	lb_debug_file_line(m, bt->Struct.node, &file, &line);

	unsigned tag = DW_TAG_structure_type;
	if (is_type_raw_union(bt)) {
		tag = DW_TAG_union_type;
	}

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
		m->debug_builder, tag,
		cast(char const *)name.text, cast(size_t)name.len,
		scope, file, line, 0, size_in_bits, align_in_bits, LLVMDIFlagZero, "", 0
	);

	lb_set_llvm_metadata(m, type, temp_forward_decl);

	type_set_offsets(bt);

	unsigned element_count = cast(unsigned)(bt->Struct.fields.count);
	LLVMMetadataRef *elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);

	LLVMMetadataRef member_scope = lb_get_llvm_metadata(m, bt->Struct.scope);

	for_array(j, bt->Struct.fields) {
		Entity *f = bt->Struct.fields[j];
		String fname = f->token.string;

		unsigned field_line = 0;
		LLVMDIFlags field_flags = LLVMDIFlagZero;
		GB_ASSERT(bt->Struct.offsets != nullptr);
		u64 offset_in_bits = 8*cast(u64)bt->Struct.offsets[j];

		elements[j] = LLVMDIBuilderCreateMemberType(
			m->debug_builder,
			member_scope,
			cast(char const *)fname.text, cast(size_t)fname.len,
			file, field_line,
			8*cast(u64)type_size_of(f->type), 8*cast(u32)type_align_of(f->type),
			offset_in_bits,
			field_flags,
			lb_debug_type(m, f->type)
		);
	}

	LLVMMetadataRef final_decl = nullptr;
	if (tag == DW_TAG_union_type) {
		 final_decl = LLVMDIBuilderCreateUnionType(
			m->debug_builder, scope,
			cast(char const*)name.text, cast(size_t)name.len,
			file, line,
			size_in_bits, align_in_bits,
			LLVMDIFlagZero,
			elements, element_count,
			0,
			"", 0
		);
	} else {
		 final_decl = LLVMDIBuilderCreateStructType(
			m->debug_builder, scope,
			cast(char const *)name.text, cast(size_t)name.len,
			file, line,
			size_in_bits, align_in_bits,
			LLVMDIFlagZero,
			nullptr,
			elements, element_count,
			0,
			nullptr,
			"", 0
		);
	}

	LLVMMetadataReplaceAllUsesWith(temp_forward_decl, final_decl);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_slice(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_Slice);

	unsigned const ptr_bits = cast(unsigned)(8*build_context.ptr_size);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
		m->debug_builder, DW_TAG_structure_type,
		cast(char const *)name.text, cast(size_t)name.len,
		scope, file, line, 0, size_in_bits, align_in_bits, LLVMDIFlagZero, "", 0
	);

	lb_set_llvm_metadata(m, type, temp_forward_decl);

	unsigned element_count = 2;
	LLVMMetadataRef elements[2];

	// LLVMMetadataRef member_scope = lb_get_llvm_metadata(m, bt->Slice.scope);
	LLVMMetadataRef member_scope = nullptr;

	Type *elem_type = alloc_type_pointer(bt->Slice.elem);
	elements[0] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"data", 4,
		file, line,
		8*cast(u64)type_size_of(elem_type), 8*cast(u32)type_align_of(elem_type),
		0,
		LLVMDIFlagZero, lb_debug_type(m, elem_type)
	);

	elements[1] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"len", 3,
		file, line,
		8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
		ptr_bits,
		LLVMDIFlagZero, lb_debug_type(m, t_int)
	);

	LLVMMetadataRef final_decl = LLVMDIBuilderCreateStructType(
		m->debug_builder, scope,
		cast(char const *)name.text, cast(size_t)name.len,
		file, line,
		size_in_bits, align_in_bits,
		LLVMDIFlagZero,
		nullptr,
		elements, element_count,
		0,
		nullptr,
		"", 0
	);

	LLVMMetadataReplaceAllUsesWith(temp_forward_decl, final_decl);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_dynamic_array(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_DynamicArray);

	unsigned const ptr_bits = cast(unsigned)(8*build_context.ptr_size);
	unsigned const int_bits = cast(unsigned)(8*build_context.int_size);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
		m->debug_builder, DW_TAG_structure_type,
		cast(char const *)name.text, cast(size_t)name.len,
		scope, file, line, 0, size_in_bits, align_in_bits, LLVMDIFlagZero, "", 0
	);

	lb_set_llvm_metadata(m, type, temp_forward_decl);

	unsigned element_count = 4;
	LLVMMetadataRef elements[4];

	// LLVMMetadataRef member_scope = lb_get_llvm_metadata(m, bt->DynamicArray.scope);
	LLVMMetadataRef member_scope = nullptr;

	Type *elem_type = alloc_type_pointer(bt->DynamicArray.elem);
	elements[0] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"data", 4,
		file, line,
		8*cast(u64)type_size_of(elem_type), 8*cast(u32)type_align_of(elem_type),
		0,
		LLVMDIFlagZero, lb_debug_type(m, elem_type)
	);

	elements[1] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"len", 3,
		file, line,
		8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
		ptr_bits,
		LLVMDIFlagZero, lb_debug_type(m, t_int)
	);

	elements[2] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"cap", 3,
		file, line,
		8*cast(u64)type_size_of(t_int), 8*cast(u32)type_align_of(t_int),
		ptr_bits+int_bits,
		LLVMDIFlagZero, lb_debug_type(m, t_int)
	);

	elements[3] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"allocator", 9,
		file, line,
		8*cast(u64)type_size_of(t_allocator), 8*cast(u32)type_align_of(t_allocator),
		ptr_bits+int_bits+int_bits,
		LLVMDIFlagZero, lb_debug_type(m, t_allocator)
	);

	LLVMMetadataRef final_decl = LLVMDIBuilderCreateStructType(
		m->debug_builder, scope,
		cast(char const *)name.text, cast(size_t)name.len,
		file, line,
		size_in_bits, align_in_bits,
		LLVMDIFlagZero,
		nullptr,
		elements, element_count,
		0,
		nullptr,
		"", 0
	);

	LLVMMetadataReplaceAllUsesWith(temp_forward_decl, final_decl);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_union(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_Union);

	lb_debug_file_line(m, bt->Union.node, &file, &line);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
		m->debug_builder, DW_TAG_union_type,
		cast(char const *)name.text, cast(size_t)name.len,
		scope, file, line, 0, size_in_bits, align_in_bits, LLVMDIFlagZero, "", 0
	);

	lb_set_llvm_metadata(m, type, temp_forward_decl);

	isize index_offset = 1;
	if (is_type_union_maybe_pointer(bt)) {
		index_offset = 0;
	}

	LLVMMetadataRef member_scope = lb_get_llvm_metadata(m, bt->Union.scope);
	unsigned element_count = cast(unsigned)bt->Union.variants.count;
	if (index_offset > 0) {
		element_count += 1;
	}

	LLVMMetadataRef *elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);

	if (index_offset > 0) {
		Type *tag_type = union_tag_type(bt);
		u64 offset_in_bits = 8*cast(u64)bt->Union.variant_block_size;

		elements[0] = LLVMDIBuilderCreateMemberType(
			m->debug_builder, member_scope,
			"tag", 3,
			file, line,
			8*cast(u64)type_size_of(tag_type), 8*cast(u32)type_align_of(tag_type),
			offset_in_bits,
			LLVMDIFlagZero, lb_debug_type(m, tag_type)
		);
	}

	for_array(j, bt->Union.variants) {
		Type *variant = bt->Union.variants[j];

		unsigned field_index = cast(unsigned)(index_offset+j);

		char name[16] = {};
		gb_snprintf(name, gb_size_of(name), "v%u", field_index);
		isize name_len = gb_strlen(name);

		elements[field_index] = LLVMDIBuilderCreateMemberType(
			m->debug_builder, member_scope,
			name, name_len,
			file, line,
			8*cast(u64)type_size_of(variant), 8*cast(u32)type_align_of(variant),
			0,
			LLVMDIFlagZero, lb_debug_type(m, variant)
		);
	}

	LLVMMetadataRef final_decl = LLVMDIBuilderCreateUnionType(
		m->debug_builder,
		scope,
		cast(char const *)name.text, cast(size_t)name.len,
		file, line,
		size_in_bits, align_in_bits,
		LLVMDIFlagZero,
		elements,
		element_count,
		0,
		"", 0
	);

	LLVMMetadataReplaceAllUsesWith(temp_forward_decl, final_decl);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_bitset(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_BitSet);

	lb_debug_file_line(m, bt->BitSet.node, &file, &line);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef bit_set_field_type = lb_debug_type(m, t_bool);

	unsigned element_count = 0;
	LLVMMetadataRef *elements = nullptr;

	Type *elem = base_type(bt->BitSet.elem);
	if (elem->kind == Type_Enum) {
		element_count = cast(unsigned)elem->Enum.fields.count;
		elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);

		for_array(i, elem->Enum.fields) {
			Entity *f = elem->Enum.fields[i];
			GB_ASSERT(f->kind == Entity_Constant);
			i64 val = exact_value_to_i64(f->Constant.value);
			String field_name = f->token.string;
			u64 offset_in_bits = cast(u64)(val - bt->BitSet.lower);
			elements[i] = LLVMDIBuilderCreateBitFieldMemberType(
				m->debug_builder,
				scope,
				cast(char const *)field_name.text, field_name.len,
			 	file, line,
			 	1,
			 	offset_in_bits,
			 	0,
			 	LLVMDIFlagZero,
			 	bit_set_field_type
			);
		}
	} else {
		char name[32] = {};

		GB_ASSERT(is_type_integer(elem));
		i64 count = bt->BitSet.upper - bt->BitSet.lower + 1;
		GB_ASSERT(0 <= count);

		element_count = cast(unsigned)count;
		elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);

		for (unsigned i = 0; i < element_count; i++) {
			u64 offset_in_bits = i;
			i64 val = bt->BitSet.lower + cast(i64)i;
			gb_snprintf(name, gb_count_of(name), "%lld", cast(long long)val);
			elements[i] = LLVMDIBuilderCreateBitFieldMemberType(
				m->debug_builder,
				scope,
				name, gb_strlen(name),
				file, line,
				1,
				offset_in_bits,
				0,
				LLVMDIFlagZero,
				bit_set_field_type
			);
		}
	}

	LLVMMetadataRef final_decl = LLVMDIBuilderCreateUnionType(
		m->debug_builder,
		scope,
		cast(char const *)name.text, cast(size_t)name.len,
		file, line,
		size_in_bits, align_in_bits,
		LLVMDIFlagZero,
		elements,
		element_count,
		0,
		"", 0
	);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_enum(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_Enum);

	lb_debug_file_line(m, bt->Enum.node, &file, &line);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	unsigned element_count = cast(unsigned)bt->Enum.fields.count;
	LLVMMetadataRef *elements = gb_alloc_array(temporary_allocator(), LLVMMetadataRef, element_count);

	Type *bt_enum = base_enum_type(bt);
	LLVMBool is_unsigned = is_type_unsigned(bt_enum);
	for (unsigned i = 0; i < element_count; i++) {
		Entity *f = bt->Enum.fields[i];
		GB_ASSERT(f->kind == Entity_Constant);
		String enum_name = f->token.string;
		i64 value = exact_value_to_i64(f->Constant.value);
		elements[i] = LLVMDIBuilderCreateEnumerator(m->debug_builder, cast(char const *)enum_name.text, cast(size_t)enum_name.len, value, is_unsigned);
	}

	LLVMMetadataRef class_type = lb_debug_type(m, bt_enum);
	LLVMMetadataRef final_decl = LLVMDIBuilderCreateEnumerationType(
		m->debug_builder,
		scope,
		cast(char const *)name.text, cast(size_t)name.len,
		file, line,
		size_in_bits, align_in_bits,
		elements, element_count,
		class_type
	);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_type_basic_type(lbModule *m, String const &name, u64 size_in_bits, LLVMDWARFTypeEncoding encoding, LLVMDIFlags flags = LLVMDIFlagZero) {
	LLVMMetadataRef basic_type = LLVMDIBuilderCreateBasicType(m->debug_builder, cast(char const *)name.text, name.len, size_in_bits, encoding, flags);
#if 1
	LLVMMetadataRef final_decl = LLVMDIBuilderCreateTypedef(m->debug_builder, basic_type, cast(char const *)name.text, name.len, nullptr, 0, nullptr, cast(u32)size_in_bits);
	return final_decl;
#else
	return basic_type;
#endif
}

gb_internal LLVMMetadataRef lb_debug_type_internal(lbModule *m, Type *type) {
	i64 size = type_size_of(type); // Check size
	gb_unused(size);

	GB_ASSERT(type != t_invalid);

	/* unsigned const ptr_size = cast(unsigned)build_context.ptr_size; */
	unsigned const int_bits  = cast(unsigned)(8*build_context.int_size);
	unsigned const ptr_bits = cast(unsigned)(8*build_context.ptr_size);

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_llvm_bool: return lb_debug_type_basic_type(m, str_lit("llvm bool"),  1, LLVMDWARFTypeEncoding_Boolean);
		case Basic_bool:      return lb_debug_type_basic_type(m, str_lit("bool"),       8, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b8:        return lb_debug_type_basic_type(m, str_lit("b8"),         8, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b16:       return lb_debug_type_basic_type(m, str_lit("b16"),       16, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b32:       return lb_debug_type_basic_type(m, str_lit("b32"),       32, LLVMDWARFTypeEncoding_Boolean);
		case Basic_b64:       return lb_debug_type_basic_type(m, str_lit("b64"),       64, LLVMDWARFTypeEncoding_Boolean);

		case Basic_i8:   return lb_debug_type_basic_type(m, str_lit("i8"),     8, LLVMDWARFTypeEncoding_Signed);
		case Basic_u8:   return lb_debug_type_basic_type(m, str_lit("u8"),     8, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i16:  return lb_debug_type_basic_type(m, str_lit("i16"),   16, LLVMDWARFTypeEncoding_Signed);
		case Basic_u16:  return lb_debug_type_basic_type(m, str_lit("u16"),   16, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i32:  return lb_debug_type_basic_type(m, str_lit("i32"),   32, LLVMDWARFTypeEncoding_Signed);
		case Basic_u32:  return lb_debug_type_basic_type(m, str_lit("u32"),   32, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i64:  return lb_debug_type_basic_type(m, str_lit("i64"),   64, LLVMDWARFTypeEncoding_Signed);
		case Basic_u64:  return lb_debug_type_basic_type(m, str_lit("u64"),   64, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_i128: return lb_debug_type_basic_type(m, str_lit("i128"), 128, LLVMDWARFTypeEncoding_Signed);
		case Basic_u128: return lb_debug_type_basic_type(m, str_lit("u128"), 128, LLVMDWARFTypeEncoding_Unsigned);

		case Basic_rune: return lb_debug_type_basic_type(m, str_lit("rune"), 32, LLVMDWARFTypeEncoding_Utf);


		case Basic_f16: return lb_debug_type_basic_type(m, str_lit("f16"), 16, LLVMDWARFTypeEncoding_Float);
		case Basic_f32: return lb_debug_type_basic_type(m, str_lit("f32"), 32, LLVMDWARFTypeEncoding_Float);
		case Basic_f64: return lb_debug_type_basic_type(m, str_lit("f64"), 64, LLVMDWARFTypeEncoding_Float);

		case Basic_int:  return lb_debug_type_basic_type(m,    str_lit("int"),     int_bits, LLVMDWARFTypeEncoding_Signed);
		case Basic_uint: return lb_debug_type_basic_type(m,    str_lit("uint"),    int_bits, LLVMDWARFTypeEncoding_Unsigned);
		case Basic_uintptr: return lb_debug_type_basic_type(m, str_lit("uintptr"), ptr_bits, LLVMDWARFTypeEncoding_Unsigned);

		case Basic_typeid:
			return lb_debug_type_basic_type(m, str_lit("typeid"), ptr_bits, LLVMDWARFTypeEncoding_Unsigned);

		// Endian Specific Types
		case Basic_i16le:  return lb_debug_type_basic_type(m, str_lit("i16le"),  16,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u16le:  return lb_debug_type_basic_type(m, str_lit("u16le"),  16,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);
		case Basic_i32le:  return lb_debug_type_basic_type(m, str_lit("i32le"),  32,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u32le:  return lb_debug_type_basic_type(m, str_lit("u32le"),  32,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);
		case Basic_i64le:  return lb_debug_type_basic_type(m, str_lit("i64le"),  64,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u64le:  return lb_debug_type_basic_type(m, str_lit("u64le"),  64,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);
		case Basic_i128le: return lb_debug_type_basic_type(m, str_lit("i128le"), 128, LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagLittleEndian);
		case Basic_u128le: return lb_debug_type_basic_type(m, str_lit("u128le"), 128, LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagLittleEndian);

		case Basic_f16le: return lb_debug_type_basic_type(m,  str_lit("f16le"),   16, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f32le: return lb_debug_type_basic_type(m,  str_lit("f32le"),   32, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f64le: return lb_debug_type_basic_type(m,  str_lit("f64le"),   64, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);

		case Basic_i16be:  return lb_debug_type_basic_type(m, str_lit("i16be"),  16,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u16be:  return lb_debug_type_basic_type(m, str_lit("u16be"),  16,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);
		case Basic_i32be:  return lb_debug_type_basic_type(m, str_lit("i32be"),  32,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u32be:  return lb_debug_type_basic_type(m, str_lit("u32be"),  32,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);
		case Basic_i64be:  return lb_debug_type_basic_type(m, str_lit("i64be"),  64,  LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u64be:  return lb_debug_type_basic_type(m, str_lit("u64be"),  64,  LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);
		case Basic_i128be: return lb_debug_type_basic_type(m, str_lit("i128be"), 128, LLVMDWARFTypeEncoding_Signed,   LLVMDIFlagBigEndian);
		case Basic_u128be: return lb_debug_type_basic_type(m, str_lit("u128be"), 128, LLVMDWARFTypeEncoding_Unsigned, LLVMDIFlagBigEndian);

		case Basic_f16be: return lb_debug_type_basic_type(m,  str_lit("f16be"),   16, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f32be: return lb_debug_type_basic_type(m,  str_lit("f32be"),   32, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);
		case Basic_f64be: return lb_debug_type_basic_type(m,  str_lit("f64be"),   64, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagLittleEndian);

		case Basic_complex32:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f16, 0*16);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f16, 1*16);
				return lb_debug_basic_struct(m, str_lit("complex32"), 64, 32, elements, gb_count_of(elements));
			}
		case Basic_complex64:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f32, 0*32);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f32, 2*32);
				return lb_debug_basic_struct(m, str_lit("complex64"), 64, 32, elements, gb_count_of(elements));
			}
		case Basic_complex128:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f64, 0*64);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f64, 1*64);
				return lb_debug_basic_struct(m, str_lit("complex128"), 128, 64, elements, gb_count_of(elements));
			}

		case Basic_quaternion64:
			{
				LLVMMetadataRef elements[4] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("imag"), t_f16, 0*16);
				elements[1] = lb_debug_struct_field(m, str_lit("jmag"), t_f16, 1*16);
				elements[2] = lb_debug_struct_field(m, str_lit("kmag"), t_f16, 2*16);
				elements[3] = lb_debug_struct_field(m, str_lit("real"), t_f16, 3*16);
				return lb_debug_basic_struct(m, str_lit("quaternion64"), 128, 32, elements, gb_count_of(elements));
			}
		case Basic_quaternion128:
			{
				LLVMMetadataRef elements[4] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("imag"), t_f32, 0*32);
				elements[1] = lb_debug_struct_field(m, str_lit("jmag"), t_f32, 1*32);
				elements[2] = lb_debug_struct_field(m, str_lit("kmag"), t_f32, 2*32);
				elements[3] = lb_debug_struct_field(m, str_lit("real"), t_f32, 3*32);
				return lb_debug_basic_struct(m, str_lit("quaternion128"), 128, 32, elements, gb_count_of(elements));
			}
		case Basic_quaternion256:
			{
				LLVMMetadataRef elements[4] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("imag"), t_f64, 0*64);
				elements[1] = lb_debug_struct_field(m, str_lit("jmag"), t_f64, 1*64);
				elements[2] = lb_debug_struct_field(m, str_lit("kmag"), t_f64, 2*64);
				elements[3] = lb_debug_struct_field(m, str_lit("real"), t_f64, 3*64);
				return lb_debug_basic_struct(m, str_lit("quaternion256"), 256, 32, elements, gb_count_of(elements));
			}



		case Basic_rawptr:
			{
				LLVMMetadataRef void_type = lb_debug_type_basic_type(m, str_lit("void"), 8, LLVMDWARFTypeEncoding_Unsigned);
				return LLVMDIBuilderCreatePointerType(m->debug_builder, void_type, ptr_bits, ptr_bits, LLVMDWARFTypeEncoding_Address, "rawptr", 6);
			}
		case Basic_string:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("data"), t_u8_ptr, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("len"),  t_int, int_bits);
				return lb_debug_basic_struct(m, str_lit("string"), 2*int_bits, int_bits, elements, gb_count_of(elements));
			}
		case Basic_cstring:
			{
				LLVMMetadataRef char_type = lb_debug_type_basic_type(m, str_lit("char"), 8, LLVMDWARFTypeEncoding_Unsigned);
				return LLVMDIBuilderCreatePointerType(m->debug_builder, char_type, ptr_bits, ptr_bits, 0, "cstring", 7);
			}
		case Basic_any:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("data"), t_rawptr, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("id"),   t_typeid, ptr_bits);
				return lb_debug_basic_struct(m, str_lit("any"), 2*ptr_bits, ptr_bits, elements, gb_count_of(elements));
			}

		// Untyped types
		case Basic_UntypedBool:       GB_PANIC("Basic_UntypedBool");       break;
		case Basic_UntypedInteger:    GB_PANIC("Basic_UntypedInteger");    break;
		case Basic_UntypedFloat:      GB_PANIC("Basic_UntypedFloat");      break;
		case Basic_UntypedComplex:    GB_PANIC("Basic_UntypedComplex");    break;
		case Basic_UntypedQuaternion: GB_PANIC("Basic_UntypedQuaternion"); break;
		case Basic_UntypedString:     GB_PANIC("Basic_UntypedString");     break;
		case Basic_UntypedRune:       GB_PANIC("Basic_UntypedRune");       break;
		case Basic_UntypedNil:        GB_PANIC("Basic_UntypedNil");        break;
		case Basic_UntypedUninit:     GB_PANIC("Basic_UntypedUninit");     break;

		default: GB_PANIC("Basic Unhandled"); break;
		}
		break;

	case Type_Named:
		GB_PANIC("Type_Named should be handled in lb_debug_type separately");

	case Type_SoaPointer:
		return LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, type->SoaPointer.elem), int_bits, int_bits, 0, nullptr, 0);
	case Type_Pointer:
		return LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, type->Pointer.elem), ptr_bits, ptr_bits, 0, nullptr, 0);
	case Type_MultiPointer:
		return LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, type->MultiPointer.elem), ptr_bits, ptr_bits, 0, nullptr, 0);

	case Type_Array: {
		LLVMMetadataRef subscripts[1] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
			0ll,
			type->Array.count
		);

		return LLVMDIBuilderCreateArrayType(m->debug_builder,
			8*cast(uint64_t)type_size_of(type),
			8*cast(unsigned)type_align_of(type),
			lb_debug_type(m, type->Array.elem),
			subscripts, gb_count_of(subscripts));
	}

	case Type_EnumeratedArray: {
		LLVMMetadataRef subscripts[1] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
			0ll,
			type->EnumeratedArray.count
		);

		LLVMMetadataRef array_type = LLVMDIBuilderCreateArrayType(m->debug_builder,
			8*cast(uint64_t)type_size_of(type),
			8*cast(unsigned)type_align_of(type),
			lb_debug_type(m, type->EnumeratedArray.elem),
			subscripts, gb_count_of(subscripts));
		gbString name = type_to_string(type, temporary_allocator());
		return LLVMDIBuilderCreateTypedef(m->debug_builder, array_type, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
	}

	case Type_Map: {
		init_map_internal_debug_types(type);
		Type *bt = base_type(type->Map.debug_metadata_type);
		GB_ASSERT(bt->kind == Type_Struct);

		return lb_debug_struct(m, type, bt, make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);
	}

	case Type_Struct:       return lb_debug_struct(       m, type, type, make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);
	case Type_Slice:        return lb_debug_slice(        m, type,       make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);
	case Type_DynamicArray: return lb_debug_dynamic_array(m, type,       make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);
	case Type_Union:        return lb_debug_union(        m, type,       make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);
	case Type_BitSet:       return lb_debug_bitset(       m, type,       make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);
	case Type_Enum:         return lb_debug_enum(         m, type,       make_string_c(type_to_string(type, temporary_allocator())), nullptr, nullptr, 0);

	case Type_Tuple:
		if (type->Tuple.variables.count == 1) {
			return lb_debug_type(m, type->Tuple.variables[0]->type);
		} else {
			type_set_offsets(type);
			LLVMMetadataRef parent_scope = nullptr;
			LLVMMetadataRef scope = nullptr;
			LLVMMetadataRef file = nullptr;
			unsigned line = 0;
			u64 size_in_bits = 8*cast(u64)type_size_of(type);
			u32 align_in_bits = 8*cast(u32)type_align_of(type);
			LLVMDIFlags flags = LLVMDIFlagZero;

			unsigned element_count = cast(unsigned)type->Tuple.variables.count;
			LLVMMetadataRef *elements = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, element_count);

			for (unsigned i = 0; i < element_count; i++) {
				Entity *f = type->Tuple.variables[i];
				GB_ASSERT(f->kind == Entity_Variable);
				String name = f->token.string;
				unsigned field_line = 0;
				LLVMDIFlags field_flags = LLVMDIFlagZero;
				u64 offset_in_bits = 8*cast(u64)type->Tuple.offsets[i];
				elements[i] = LLVMDIBuilderCreateMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, field_line,
					8*cast(u64)type_size_of(f->type), 8*cast(u32)type_align_of(f->type), offset_in_bits,
					field_flags, lb_debug_type(m, f->type)
				);
			}


			return LLVMDIBuilderCreateStructType(m->debug_builder, parent_scope, "", 0, file, line,
				size_in_bits, align_in_bits, flags,
				nullptr, elements, element_count, 0, nullptr,
				"", 0
			);
		}

	case Type_Proc:
		{
			LLVMMetadataRef proc_underlying_type = lb_debug_type_internal_proc(m, type);
			LLVMMetadataRef pointer_type = LLVMDIBuilderCreatePointerType(m->debug_builder, proc_underlying_type, ptr_bits, ptr_bits, 0, nullptr, 0);
			gbString name = type_to_string(type, temporary_allocator());
			return LLVMDIBuilderCreateTypedef(m->debug_builder, pointer_type, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
		}
		break;

	case Type_SimdVector:
		{
			LLVMMetadataRef elem = lb_debug_type(m, type->SimdVector.elem);
			LLVMMetadataRef subscripts[1] = {};
			subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
				0ll,
				type->SimdVector.count
			);
			return LLVMDIBuilderCreateVectorType(
				m->debug_builder,
				8*cast(unsigned)type_size_of(type), 8*cast(unsigned)type_align_of(type),
				elem, subscripts, gb_count_of(subscripts));
		}

	case Type_RelativePointer: {
		LLVMMetadataRef base_integer = lb_debug_type(m, type->RelativePointer.base_integer);
		gbString name = type_to_string(type, temporary_allocator());
		return LLVMDIBuilderCreateTypedef(m->debug_builder, base_integer, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
	}
	case Type_RelativeMultiPointer: {
		LLVMMetadataRef base_integer = lb_debug_type(m, type->RelativeMultiPointer.base_integer);
		gbString name = type_to_string(type, temporary_allocator());
		return LLVMDIBuilderCreateTypedef(m->debug_builder, base_integer, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
	}

	case Type_Matrix: {
		LLVMMetadataRef subscripts[1] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder,
			0ll,
			matrix_type_total_internal_elems(type)
		);

		return LLVMDIBuilderCreateArrayType(m->debug_builder,
			8*cast(uint64_t)type_size_of(type),
			8*cast(unsigned)type_align_of(type),
			lb_debug_type(m, type->Matrix.elem),
			subscripts, gb_count_of(subscripts));
	}

	case Type_BitField: {
		LLVMMetadataRef parent_scope = nullptr;
		LLVMMetadataRef scope = nullptr;
		LLVMMetadataRef file = nullptr;
		unsigned line = 0;
		u64 size_in_bits = 8*cast(u64)type_size_of(type);
		u32 align_in_bits = 8*cast(u32)type_align_of(type);
		LLVMDIFlags flags = LLVMDIFlagZero;

		unsigned element_count = cast(unsigned)type->BitField.fields.count;
		LLVMMetadataRef *elements = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, element_count);

		u64 offset_in_bits = 0;
		for (unsigned i = 0; i < element_count; i++) {
			Entity *f = type->BitField.fields[i];
			u8 bit_size = type->BitField.bit_sizes[i];
			GB_ASSERT(f->kind == Entity_Variable);
			String name = f->token.string;
			unsigned field_line = 0;
			LLVMDIFlags field_flags = LLVMDIFlagZero;
			elements[i] = LLVMDIBuilderCreateBitFieldMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, field_line,
				bit_size, offset_in_bits, offset_in_bits,
				field_flags, lb_debug_type(m, f->type)
			);

			offset_in_bits += bit_size;
		}


		return LLVMDIBuilderCreateStructType(m->debug_builder, parent_scope, "", 0, file, line,
			size_in_bits, align_in_bits, flags,
			nullptr, elements, element_count, 0, nullptr,
			"", 0
		);
	}
	}

	GB_PANIC("Invalid type %s", type_to_string(type));
	return nullptr;
}

gb_internal LLVMMetadataRef lb_get_base_scope_metadata(lbModule *m, Scope *scope) {
	LLVMMetadataRef found = nullptr;
	for (;;) {
		if (scope == nullptr) {
			return nullptr;
		}
		if (scope->flags & ScopeFlag_Proc) {
			found = lb_get_llvm_metadata(m, scope->procedure_entity);
			if (found) {
				return found;
			}
		}
		if (scope->flags & ScopeFlag_File) {
			found = lb_get_llvm_metadata(m, scope->file);
			if (found) {
				return found;
			}
		}
		scope = scope->parent;
	}
}

gb_internal LLVMMetadataRef lb_debug_type(lbModule *m, Type *type) {
	GB_ASSERT(type != nullptr);
	LLVMMetadataRef found = lb_get_llvm_metadata(m, type);
	if (found != nullptr) {
		return found;
	}

	MUTEX_GUARD(&m->debug_values_mutex);

	if (type->kind == Type_Named) {
		LLVMMetadataRef file = nullptr;
		unsigned line = 0;
		LLVMMetadataRef scope = nullptr;

		if (type->Named.type_name != nullptr) {
			Entity *e = type->Named.type_name;
			scope = lb_get_base_scope_metadata(m, e->scope);
			if (scope != nullptr) {
				file = LLVMDIScopeGetFile(scope);
			}
			line = cast(unsigned)e->token.pos.line;
		}

		String name = type->Named.name;
		if (type->Named.type_name && type->Named.type_name->pkg && type->Named.type_name->pkg->name.len != 0) {
			name = concatenate3_strings(temporary_allocator(), type->Named.type_name->pkg->name, str_lit("."), type->Named.name);
		}

		Type *bt = base_type(type->Named.base);

		switch (bt->kind) {
		default: {
			u32 align_in_bits = 8*cast(u32)type_align_of(type);
			LLVMMetadataRef debug_bt = lb_debug_type(m, bt);
			LLVMMetadataRef final_decl = LLVMDIBuilderCreateTypedef(
				m->debug_builder,
				debug_bt,
				cast(char const *)name.text, cast(size_t)name.len,
				file, line, scope, align_in_bits
			);
			lb_set_llvm_metadata(m, type, final_decl);
			return final_decl;
		}

		case Type_Map: {
			init_map_internal_debug_types(bt);
			bt = base_type(bt->Map.debug_metadata_type);
			GB_ASSERT(bt->kind == Type_Struct);
			return lb_debug_struct(m, type, bt, name, scope, file, line);
		}

		case Type_Struct:       return lb_debug_struct(m, type, base_type(type), name, scope, file, line);
		case Type_Slice:        return lb_debug_slice(m, type, name, scope, file, line);
		case Type_DynamicArray: return lb_debug_dynamic_array(m, type, name, scope, file, line);
		case Type_Union:        return lb_debug_union(m, type, name, scope, file, line);
		case Type_BitSet:       return lb_debug_bitset(m, type, name, scope, file, line);
		case Type_Enum:         return lb_debug_enum(m, type, name, scope, file, line);
		}
	}

	LLVMMetadataRef dt = lb_debug_type_internal(m, type);
	lb_set_llvm_metadata(m, type, dt);
	return dt;
}

gb_internal void lb_add_debug_local_variable(lbProcedure *p, LLVMValueRef ptr, Type *type, Token const &token) {
	if (p->debug_info == nullptr) {
		return;
	}
	if (type == nullptr) {
		return;
	}
	if (type == t_invalid) {
		return;
	}
	if (p->body == nullptr) {
		return;
	}

	lbModule *m = p->module;
	String const &name = token.string;
	if (name == "" || name == "_") {
		return;
	}

	if (lb_get_llvm_metadata(m, ptr) != nullptr) {
		// Already been set
		return;
	}

	AstFile *file = p->body->file();

	LLVMMetadataRef llvm_scope = lb_get_current_debug_scope(p);
	LLVMMetadataRef llvm_file = lb_get_llvm_metadata(m, file);
	GB_ASSERT(llvm_scope != nullptr);
	if (llvm_file == nullptr) {
		llvm_file = LLVMDIScopeGetFile(llvm_scope);
	}

	if (llvm_file == nullptr) {
		return;
	}

	unsigned alignment_in_bits = cast(unsigned)(8*type_align_of(type));

	LLVMDIFlags flags = LLVMDIFlagZero;
	LLVMBool always_preserve = build_context.optimization_level == 0;

	LLVMMetadataRef debug_type = lb_debug_type(m, type);

	LLVMMetadataRef var_info = LLVMDIBuilderCreateAutoVariable(
		m->debug_builder, llvm_scope,
		cast(char const *)name.text, cast(size_t)name.len,
		llvm_file, token.pos.line,
		debug_type,
		always_preserve, flags, alignment_in_bits
	);

	LLVMValueRef storage = ptr;
	LLVMBasicBlockRef block = p->curr_block->block;
	LLVMMetadataRef llvm_debug_loc = lb_debug_location_from_token_pos(p, token.pos);
	LLVMMetadataRef llvm_expr = LLVMDIBuilderCreateExpression(m->debug_builder, nullptr, 0);
	lb_set_llvm_metadata(m, ptr, llvm_expr);
	LLVMDIBuilderInsertDeclareAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block);
}

gb_internal void lb_add_debug_param_variable(lbProcedure *p, LLVMValueRef ptr, Type *type, Token const &token, unsigned arg_number, lbBlock *block) {
	if (p->debug_info == nullptr) {
		return;
	}
	if (type == nullptr) {
		return;
	}
	if (type == t_invalid) {
		return;
	}
	if (p->body == nullptr) {
		return;
	}

	lbModule *m = p->module;
	String const &name = token.string;
	if (name == "" || name == "_") {
		return;
	}

	if (lb_get_llvm_metadata(m, ptr) != nullptr) {
		// Already been set
		return;
	}


	AstFile *file = p->body->file();

	LLVMMetadataRef llvm_scope = lb_get_current_debug_scope(p);
	LLVMMetadataRef llvm_file = lb_get_llvm_metadata(m, file);
	GB_ASSERT(llvm_scope != nullptr);
	if (llvm_file == nullptr) {
		llvm_file = LLVMDIScopeGetFile(llvm_scope);
	}

	if (llvm_file == nullptr) {
		return;
	}

	LLVMDIFlags flags = LLVMDIFlagZero;
	LLVMBool always_preserve = build_context.optimization_level == 0;

	LLVMMetadataRef debug_type = lb_debug_type(m, type);

	LLVMMetadataRef var_info = LLVMDIBuilderCreateParameterVariable(
		m->debug_builder, llvm_scope,
		cast(char const *)name.text, cast(size_t)name.len,
		arg_number,
		llvm_file, token.pos.line,
		debug_type,
		always_preserve, flags
	);

	LLVMValueRef storage = ptr;
	LLVMMetadataRef llvm_debug_loc = lb_debug_location_from_token_pos(p, token.pos);
	LLVMMetadataRef llvm_expr = LLVMDIBuilderCreateExpression(m->debug_builder, nullptr, 0);
	lb_set_llvm_metadata(m, ptr, llvm_expr);

	// NOTE(bill, 2022-02-01): For parameter values, you must insert them at the end of the decl block
	// The reason is that if the parameter is at index 0 and a pointer, there is not such things as an
	// instruction "before" it.
	LLVMDIBuilderInsertDeclareAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block->block);
}


gb_internal void lb_add_debug_context_variable(lbProcedure *p, lbAddr const &ctx) {
	if (!p->debug_info || !p->body) {
		return;
	}
	LLVMMetadataRef loc = LLVMGetCurrentDebugLocation2(p->builder);
	if (!loc) {
		return;
	}
	TokenPos pos = {};

	pos.file_id = p->body->file_id;
	pos.line = LLVMDILocationGetLine(loc);
	pos.column = LLVMDILocationGetColumn(loc);

	Token token = {};
	token.kind = Token_context;
	token.string = str_lit("context");
	token.pos = pos;

	LLVMValueRef ptr = ctx.addr.value;
	while (LLVMIsABitCastInst(ptr)) {
		ptr = LLVMGetOperand(ptr, 0);
	}

	lb_add_debug_local_variable(p, ptr, t_context, token);
}


gb_internal String debug_info_mangle_constant_name(Entity *e, gbAllocator const &allocator, bool *did_allocate_) {
	String name = e->token.string;
	if (e->pkg && e->pkg->name.len > 0) {
		// NOTE(bill): C++ NONSENSE FOR DEBUG SHITE!
		name = concatenate3_strings(allocator, e->pkg->name, str_lit("::"), name);
		if (did_allocate_) *did_allocate_ = true;
	}
	return name;
}

gb_internal void add_debug_info_global_variable_expr(lbModule *m, String const &name, LLVMMetadataRef dtype, LLVMMetadataRef expr) {
	LLVMMetadataRef scope = nullptr;
	LLVMMetadataRef file = nullptr;
	unsigned line = 0;

	LLVMMetadataRef decl = nullptr;

	LLVMDIBuilderCreateGlobalVariableExpression(
		m->debug_builder, scope,
		cast(char const *)name.text, cast(size_t)name.len,
		"", 0, // Linkage
		file, line, dtype,
		false, // local to unit
		expr, decl, 8/*AlignInBits*/);
}

gb_internal void add_debug_info_for_global_constant_internal_i64(lbModule *m, Entity *e, LLVMMetadataRef dtype, i64 v) {
	LLVMMetadataRef expr = LLVMDIBuilderCreateConstantValueExpression(m->debug_builder, v);

	TEMPORARY_ALLOCATOR_GUARD();
	String name = debug_info_mangle_constant_name(e, temporary_allocator(), nullptr);

	add_debug_info_global_variable_expr(m, name, dtype, expr);
	if ((e->pkg && e->pkg->kind == Package_Init) ||
	    (e->scope && (e->scope->flags & ScopeFlag_Global))) {
		add_debug_info_global_variable_expr(m, e->token.string, dtype, expr);
	}
}

gb_internal void add_debug_info_for_global_constant_from_entity(lbGenerator *gen, Entity *e) {
	if (e == nullptr || e->kind != Entity_Constant) {
		return;
	}
	if (is_blank_ident(e->token)) {
		return;
	}
	lbModule *m = &gen->default_module;
	if (USE_SEPARATE_MODULES) {
		m = lb_module_of_entity(gen, e);
	}

	if (is_type_integer(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = nullptr;
			i64 v = 0;
			bool is_signed = false;
			if (big_int_is_neg(&value.value_integer)) {
				v = exact_value_to_i64(value);
				is_signed = true;
			} else {
				v = cast(i64)exact_value_to_u64(value);
			}
			if (is_type_untyped(e->type)) {
				dtype = lb_debug_type(m, is_signed ? t_i64 : t_u64);
			} else {
				dtype = lb_debug_type(m, e->type);
			}

			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_rune(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, t_rune);
			i64 v = exact_value_to_i64(value);
			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_boolean(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Bool) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = cast(i64)value.value_bool;

			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_enum(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = 0;
			if (big_int_is_neg(&value.value_integer)) {
				v = exact_value_to_i64(value);
			} else {
				v = cast(i64)exact_value_to_u64(value);
			}

			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_pointer(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = cast(i64)exact_value_to_u64(value);
			add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	}
}
