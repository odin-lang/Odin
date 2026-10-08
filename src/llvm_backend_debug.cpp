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

#if LLVM_VERSION_MAJOR >= 22
// NOTE(bill): with the source's checksum, a debugger can tell when the file it shows is not the one that was compiled.
// MD5 is the only kind a DWARF 5 line table holds, and it holds none unless every file has one.
gb_internal String lb_debug_file_checksum(AstFile *f) {
	String *checksum = f->debug_checksum.load();
	if (checksum == nullptr) {
		u8 digest[16] = {};
		md5(f->tokenizer.start, f->tokenizer.end - f->tokenizer.start, digest);

		u8 *hex = gb_alloc_array(permanent_allocator(), u8, 32);
		for (isize i = 0; i < 16; i++) {
			hex[2*i+0] = "0123456789abcdef"[digest[i] >> 4];
			hex[2*i+1] = "0123456789abcdef"[digest[i] & 15];
		}

		String *s = permanent_alloc_item<String>();
		*s = make_string(hex, 32);
		if (f->debug_checksum.compare_exchange_strong(checksum, s)) {
			checksum = s;
		}
	}
	return *checksum;
}

gb_internal WORKER_TASK_PROC(lb_debug_file_checksum_worker_proc) {
	lb_debug_file_checksum(cast(AstFile *)data);
	return 0;
}
#endif

gb_internal LLVMMetadataRef lb_get_file_metadata(lbModule *m, AstFile *f) {
	if (f == nullptr || m->debug_builder == nullptr) {
		return nullptr;
	}
	MUTEX_GUARD(&m->debug_values_mutex);
	LLVMMetadataRef res = lb_get_llvm_metadata(m, f);
	if (res == nullptr) {
	#if LLVM_VERSION_MAJOR >= 22
		String checksum = lb_debug_file_checksum(f);
		res = LLVMDIBuilderCreateFileWithChecksum(m->debug_builder,
			cast(char const *)f->filename.text, f->filename.len,
			cast(char const *)f->directory.text, f->directory.len,
			CSK_MD5, cast(char const *)checksum.text, checksum.len,
			nullptr, 0);
	#else
		res = LLVMDIBuilderCreateFile(m->debug_builder,
			cast(char const *)f->filename.text, f->filename.len,
			cast(char const *)f->directory.text, f->directory.len);
	#endif
		lb_set_llvm_metadata(m, f, res);
	}
	return res;
}

gb_internal void lb_add_raddbg_string(lbModule *m, String const &str) {
	mpsc_enqueue(&m->gen->raddebug_section_strings, copy_string(permanent_allocator(), str));
}

gb_internal void lb_add_raddbg_string(lbModule *m, char const *cstr) {
	mpsc_enqueue(&m->gen->raddebug_section_strings, copy_string(permanent_allocator(), make_string_c(cstr)));
}

gb_internal void lb_add_raddbg_string(lbModule *m, char const *a, char const *b) {
	String str = concatenate_strings(permanent_allocator(), make_string_c(a), make_string_c(b));
	mpsc_enqueue(&m->gen->raddebug_section_strings, str);
}

gb_internal void lb_add_raddbg_string(lbModule *m, char const *a, char const *b, char const *c) {
	String str = concatenate3_strings(permanent_allocator(), make_string_c(a), make_string_c(b), make_string_c(c));
	mpsc_enqueue(&m->gen->raddebug_section_strings, str);
}

gb_internal void lb_add_raddbg_generated_view(lbModule *m, String const &type_name, gbString expr) {
	// NOTE(bill): a RAD Debugger type view of one type, for what a generic view cannot match

	if (string_contains_char(type_name, '"') || string_contains_char(type_name, '\\')) {
		// it cannot be quoted in the section
		return;
	}
	gbString s = gb_string_make(heap_allocator(), "type_view: {type: \"");
	defer (gb_string_free(s));
	s = gb_string_append_length(s, type_name.text, type_name.len);
	s = gb_string_appendc(s, "\", expr: \"");
	s = gb_string_append_length(s, expr, gb_string_length(expr));
	s = gb_string_appendc(s, "\"}");
	mpsc_enqueue(&m->gen->raddebug_generated_views, copy_string(permanent_allocator(), make_string(cast(u8 *)s, gb_string_length(s))));
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

// NOTE(bill): not for an anonymous type, as identical ones are interchangeable, and which one is used
// (e.g. by a polymorphic instance) depends on the checking order
gb_internal void lb_debug_file_line(lbModule *m, Type *type, Ast *node, LLVMMetadataRef *file, unsigned *line) {
	if (*file == nullptr && type->kind == Type_Named) {
		if (node) {
			*file = lb_get_file_metadata(m, node->file());
			*line = cast(unsigned)ast_token(node).pos.line;
		}
	}
}

gb_internal LLVMMetadataRef lb_debug_procedure_parameters(lbModule *m, Type *type) {
	if (type->kind == Type_Tuple && type->Tuple.variables.count == 1) {
		return lb_debug_procedure_parameters(m, type->Tuple.variables[0]->type);
	}
	return lb_debug_type(m, type);
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

	auto parameters = array_make<LLVMMetadataRef>(permanent_allocator(), 0, type->Proc.param_count+type->Proc.result_count+2);

	array_add(&parameters, cast(LLVMMetadataRef)nullptr);

	bool return_is_tuple = false;
	if (type->Proc.result_count != 0) {
		Type *single_ret = reduce_tuple_to_single_type(type->Proc.results);
		if (is_type_tuple(single_ret) && is_calling_convention_odin(type->Proc.calling_convention)) {
			LLVMTypeRef actual = lb_type_internal_for_procedures_raw(m, type);
			actual = LLVMGetReturnType(actual);
			if (actual == nullptr) {
				// results were passed as a single pointer
				parameters[0] = lb_debug_procedure_parameters(m, single_ret);
			} else {
				LLVMTypeRef possible = lb_type(m, type->Proc.results);
				if (possible == actual) {
					// results were returned directly
					parameters[0] = lb_debug_procedure_parameters(m, single_ret);
				} else {
					// resulsts were returned separately
					return_is_tuple = true;
				}
			}
		} else {
			parameters[0] = lb_debug_procedure_parameters(m, single_ret);
		}
	}

	LLVMMetadataRef file = nullptr;

	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			continue;
		}
		array_add(&parameters, lb_debug_procedure_parameters(m, e->type));
	}


	if (return_is_tuple) {
		Type *results = type->Proc.results;
		GB_ASSERT(results != nullptr && results->kind == Type_Tuple);
		isize count = results->Tuple.variables.count;
		parameters[0] = lb_debug_procedure_parameters(m, results->Tuple.variables[count-1]->type);
		for (isize i = 0; i < count-1; i++) {
			array_add(&parameters, lb_debug_procedure_parameters(m, results->Tuple.variables[i]->type));
		}
	}

	if (type->Proc.calling_convention == ProcCC_Odin) {
		array_add(&parameters, lb_debug_type(m, t_context_ptr));
	}

	LLVMDIFlags flags = LLVMDIFlagZero;
	if (type->Proc.diverging) {
		flags = LLVMDIFlagNoReturn;
	}

	return LLVMDIBuilderCreateSubroutineType(m->debug_builder, file, parameters.data, cast(unsigned)parameters.count, flags);
}

gb_internal LLVMMetadataRef lb_debug_struct_field(lbModule *m, String const &name, Type *type, u64 offset_in_bits) {
	unsigned field_line = 1;
	LLVMDIFlags field_flags = LLVMDIFlagZero;

	AstPackage *pkg = m->info->runtime_package;
	GB_ASSERT(pkg->files.count != 0);
	LLVMMetadataRef file = lb_get_file_metadata(m, pkg->files[0]);
	LLVMMetadataRef scope = file;

	return LLVMDIBuilderCreateMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, field_line,
		8*cast(u64)type_size_of(type), 8*cast(u32)type_align_of(type), offset_in_bits,
		field_flags, lb_debug_type(m, type)
	);
}
gb_internal LLVMMetadataRef lb_debug_basic_struct(lbModule *m, String const &name, u64 size_in_bits, u32 align_in_bits, LLVMMetadataRef *elements, unsigned element_count) {
	AstPackage *pkg = m->info->runtime_package;
	GB_ASSERT(pkg->files.count != 0);
	LLVMMetadataRef file = lb_get_file_metadata(m, pkg->files[0]);
	LLVMMetadataRef scope = file;

	return LLVMDIBuilderCreateStructType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, 1, size_in_bits, align_in_bits, LLVMDIFlagZero, nullptr, elements, element_count, 0, nullptr, cast(char const *)name.text, name.len);
}

// NOTE: only a named type can contain itself, so only it needs a placeholder for its members to refer to
gb_internal LLVMMetadataRef lb_debug_placeholder(lbModule *m, Type *type, unsigned tag, String const &name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line, u64 size_in_bits, u32 align_in_bits) {
	if (type->kind != Type_Named) {
		return nullptr;
	}
	LLVMMetadataRef temp_forward_decl = LLVMDIBuilderCreateReplaceableCompositeType(
		m->debug_builder, tag,
		cast(char const *)name.text, cast(size_t)name.len,
		scope, file, line, 0, size_in_bits, align_in_bits, LLVMDIFlagZero, cast(char const *)name.text, cast(size_t)name.len
	);
	lb_set_llvm_metadata(m, type, temp_forward_decl);
	return temp_forward_decl;
}

gb_internal LLVMMetadataRef lb_debug_replace_placeholder(lbModule *m, Type *type, LLVMMetadataRef temp_forward_decl, LLVMMetadataRef final_decl) {
	if (temp_forward_decl != nullptr) {
		LLVMMetadataReplaceAllUsesWith(temp_forward_decl, final_decl);
	}
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_struct(lbModule *m, Type *type, Type *bt, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	GB_ASSERT(bt->kind == Type_Struct);

	lb_debug_file_line(m, type, bt->Struct.node, &file, &line);

	unsigned tag = DW_TAG_structure_type;
	if (is_type_raw_union(bt)) {
		tag = DW_TAG_union_type;
	}

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = lb_debug_placeholder(m, type, tag, name, scope, file, line, size_in_bits, align_in_bits);

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
			cast(char const *)name.text, cast(size_t)name.len
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
			cast(char const *)name.text, cast(size_t)name.len
		);
	}

	if (build_context.metrics.os == TargetOs_windows && (bt->Struct.soa_kind == StructSoa_Slice || bt->Struct.soa_kind == StructSoa_Dynamic)) {
		// NOTE(bill): the RAD Debugger then shows each field of a #soa slice or dynamic array as an array of its length
		isize field_count = bt->Struct.fields.count - 1;
		if (bt->Struct.soa_kind == StructSoa_Dynamic) {
			field_count = bt->Struct.fields.count - 3;
		}
		gbString expr = gb_string_make(heap_allocator(), "rows($");
		defer (gb_string_free(expr));
		for_array(j, bt->Struct.fields) {
			String fname = bt->Struct.fields[j]->token.string;
			if (j >= field_count) {
				expr = gb_string_append_fmt(expr, ", %.*s", LIT(fname));
			} else if (!is_blank_ident(fname)) {
				expr = gb_string_append_fmt(expr, ", array(%.*s, __$len)", LIT(fname));
			}
		}
		expr = gb_string_appendc(expr, ")");
		lb_add_raddbg_generated_view(m, name, expr);
	}

	return lb_debug_replace_placeholder(m, type, temp_forward_decl, final_decl);
}

gb_internal LLVMMetadataRef lb_debug_slice(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_Slice);

	unsigned const ptr_bits = cast(unsigned)(8*build_context.ptr_size);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = lb_debug_placeholder(m, type, DW_TAG_structure_type, name, scope, file, line, size_in_bits, align_in_bits);

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
		cast(char const *)name.text, cast(size_t)name.len
	);

	return lb_debug_replace_placeholder(m, type, temp_forward_decl, final_decl);
}

gb_internal LLVMMetadataRef lb_debug_dynamic_array(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_DynamicArray);

	unsigned const ptr_bits = cast(unsigned)(8*build_context.ptr_size);
	unsigned const int_bits = cast(unsigned)(8*build_context.int_size);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = lb_debug_placeholder(m, type, DW_TAG_structure_type, name, scope, file, line, size_in_bits, align_in_bits);

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
		cast(char const *)name.text, cast(size_t)name.len
	);

	return lb_debug_replace_placeholder(m, type, temp_forward_decl, final_decl);
}

gb_internal LLVMMetadataRef lb_debug_fixed_capacity_dynamic_array(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_FixedCapacityDynamicArray);

	unsigned const int_bits = cast(unsigned)(8*build_context.int_size);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = lb_debug_placeholder(m, type, DW_TAG_structure_type, name, scope, file, line, size_in_bits, align_in_bits);

	unsigned element_count = 2;
	LLVMMetadataRef elements[2];

	// LLVMMetadataRef member_scope = lb_get_llvm_metadata(m, bt->DynamicArray.scope);
	LLVMMetadataRef member_scope = nullptr;

	Type *elem_type = alloc_type_array(bt->FixedCapacityDynamicArray.elem, bt->FixedCapacityDynamicArray.capacity);
	elements[0] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"data", 4,
		file, line,
		8*cast(u64)type_size_of(elem_type), 8*cast(u32)type_align_of(elem_type),
		0,
		LLVMDIFlagZero, lb_debug_type(m, elem_type)
	);

	i64 len_offset_in_bits = 8*type_offset_of(bt, 1);

	elements[1] = LLVMDIBuilderCreateMemberType(
		m->debug_builder, member_scope,
		"len", 3,
		file, line,
		int_bits, int_bits,
		len_offset_in_bits,
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
		cast(char const *)name.text, cast(size_t)name.len
	);

	return lb_debug_replace_placeholder(m, type, temp_forward_decl, final_decl);
}


gb_internal LLVMMetadataRef lb_debug_union(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_Union);

	lb_debug_file_line(m, type, bt->Union.node, &file, &line);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	LLVMMetadataRef temp_forward_decl = lb_debug_placeholder(m, type, DW_TAG_union_type, name, scope, file, line, size_in_bits, align_in_bits);

	isize index_offset = 1;
	isize variant_offset = 1;
	if (is_type_union_maybe_pointer(bt)) {
		index_offset = 0;
		variant_offset = 0;
	} else if (bt->Union.kind == UnionType_no_nil) {
		variant_offset = 0;
	}

	LLVMMetadataRef member_scope = lb_get_llvm_metadata(m, bt->Union.scope);
	unsigned element_count = cast(unsigned)bt->Union.variants.count;
	if (index_offset > 0) {
		GB_ASSERT(index_offset == 1);
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

		char name[32] = {};
		gb_snprintf(name, gb_size_of(name), "v%td", variant_offset+j);
		isize name_len = gb_strlen(name);

		elements[index_offset+j] = LLVMDIBuilderCreateMemberType(
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
		cast(char const *)name.text, cast(size_t)name.len
	);

	if (build_context.metrics.os == TargetOs_windows && index_offset > 0) {
		// NOTE(bill): the RAD Debugger then shows the variant the tag picks
		gbString expr = gb_string_make(heap_allocator(), "");
		defer (gb_string_free(expr));
		for_array(j, bt->Union.variants) {
			expr = gb_string_append_fmt(expr, "tag == %td ? v%td : ", variant_offset+j, variant_offset+j);
		}
		expr = gb_string_appendc(expr, "$");
		lb_add_raddbg_generated_view(m, name, expr);
	}

	return lb_debug_replace_placeholder(m, type, temp_forward_decl, final_decl);
}

// NOTE(bill): DWARF debuggers show a flag enum as `A | C`, but the RAD Debugger only names a value that is exactly one enumerator.
// CodeView keeps the union of one-bit members.
gb_internal bool lb_debug_bit_set_is_flag_enum(Type *bt) {
	return build_context.metrics.os != TargetOs_windows && base_type(bt->BitSet.elem)->kind == Type_Enum && type_size_of(bt) <= 8;
}

gb_internal LLVMMetadataRef lb_debug_bitset(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_BitSet);

	lb_debug_file_line(m, type, bt->BitSet.node, &file, &line);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	if (lb_debug_bit_set_is_flag_enum(bt)) {
		Type *elem = base_type(bt->BitSet.elem);
		auto enumerators = array_make<LLVMMetadataRef>(temporary_allocator(), 0, elem->Enum.fields.count);
		u64 bits = 0;
		for (Entity *f : elem->Enum.fields) {
			i64 val = exact_value_to_i64(f->Constant.value);
			if (val < bt->BitSet.lower || bt->BitSet.upper < val) {
				continue;
			}
			u64 flag = 1ull << cast(u64)(val - bt->BitSet.lower);
			if (bits & flag) {
				// an alias of an earlier field, as debuggers only show disjoint values as flags
				continue;
			}
			bits |= flag;
			String field_name = f->token.string;
			array_add(&enumerators, LLVMDIBuilderCreateEnumerator(m->debug_builder,
				cast(char const *)field_name.text, cast(size_t)field_name.len, cast(i64)flag, true
			));
		}
		LLVMMetadataRef final_decl = LLVMDIBuilderCreateEnumerationType(m->debug_builder, scope,
			cast(char const *)name.text, cast(size_t)name.len, file, line, size_in_bits, align_in_bits,
			enumerators.data, cast(unsigned)enumerators.count, lb_debug_type(m, bit_set_to_int(bt))
		);
		lb_set_llvm_metadata(m, type, final_decl);
		return final_decl;
	}

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
		cast(char const *)name.text, cast(size_t)name.len
	);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_bitfield(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_BitField);

	lb_debug_file_line(m, type, bt->BitField.node, &file, &line);

	u64 size_in_bits = 8*type_size_of(bt);
	u32 align_in_bits = 8*cast(u32)type_align_of(bt);

	unsigned element_count = cast(unsigned)bt->BitField.fields.count;
	LLVMMetadataRef *elements = gb_alloc_array(permanent_allocator(), LLVMMetadataRef, element_count);

	u64 offset_in_bits = 0;
	for (unsigned i = 0; i < element_count; i++) {
		Entity *f = bt->BitField.fields[i];
		u8 bit_size = bt->BitField.bit_sizes[i];
		GB_ASSERT(f->kind == Entity_Variable);
		String name = f->token.string;
		elements[i] = LLVMDIBuilderCreateBitFieldMemberType(m->debug_builder, scope, cast(char const *)name.text, name.len, file, line,
		                                                    bit_size, offset_in_bits, 0,
		                                                    LLVMDIFlagZero, lb_debug_type(m, f->type)
		);
		offset_in_bits += bit_size;
	}

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
		cast(char const *)name.text, cast(size_t)name.len
	);
	lb_set_llvm_metadata(m, type, final_decl);
	return final_decl;
}

gb_internal LLVMMetadataRef lb_debug_enum(lbModule *m, Type *type, String name, LLVMMetadataRef scope, LLVMMetadataRef file, unsigned line) {
	Type *bt = base_type(type);
	GB_ASSERT(bt->kind == Type_Enum);

	lb_debug_file_line(m, type, bt->Enum.node, &file, &line);

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
	if ((flags & LLVMDIFlagBigEndian) && build_context.metrics.os == TargetOs_windows) {
		// NOTE: CodeView has no endianness and drops the names of basic types and typedefs, so a big endian type is
		// an empty enum of its bits, which keeps its name for a view to swap the bytes
		if (encoding == LLVMDWARFTypeEncoding_Float) {
			encoding = LLVMDWARFTypeEncoding_Unsigned;
		}
		LLVMMetadataRef bits = LLVMDIBuilderCreateBasicType(m->debug_builder, cast(char const *)name.text, name.len, size_in_bits, encoding, LLVMDIFlagZero);
		return LLVMDIBuilderCreateEnumerationType(m->debug_builder, nullptr, cast(char const *)name.text, name.len, nullptr, 0, size_in_bits, cast(u32)size_in_bits, nullptr, 0, bits);
	}
	LLVMMetadataRef basic_type = LLVMDIBuilderCreateBasicType(m->debug_builder, cast(char const *)name.text, name.len, size_in_bits, encoding, flags);
#if 1
	LLVMMetadataRef final_decl = LLVMDIBuilderCreateTypedef(m->debug_builder, basic_type, cast(char const *)name.text, name.len, nullptr, 0, nullptr, cast(u32)size_in_bits);
	return final_decl;
#else
	return basic_type;
#endif
}

struct lbDebugNamedType {
	String name;
	Type * type;
};

gb_internal GB_COMPARE_PROC(lb_debug_named_type_cmp) {
	lbDebugNamedType const *x = cast(lbDebugNamedType const *)a;
	lbDebugNamedType const *y = cast(lbDebugNamedType const *)b;
	return string_compare(x->name, y->name);
}

// NOTE(bill): `typeid` is an enum of every type in the type table, named by its canonical name.
// Meaning that a debugger shows which type a `typeid` is.
gb_internal LLVMMetadataRef lb_debug_typeid_enum(lbModule *m) {
	auto types = array_make<lbDebugNamedType>(heap_allocator(), 0, m->info->type_info_types_hash_map.count);
	defer (array_free(&types));
	for (TypeInfoPair const &tt : m->info->type_info_types_hash_map) {
		if (tt.type != nullptr && tt.type != t_invalid) {
			array_add(&types, lbDebugNamedType{type_to_canonical_string(temporary_allocator(), tt.type), tt.type});
		}
	}
	array_sort(types, lb_debug_named_type_cmp);

	auto enumerators = array_make<LLVMMetadataRef>(heap_allocator(), 0, types.count);
	defer (array_free(&enumerators));
	for (lbDebugNamedType const &t : types) {
		array_add(&enumerators, LLVMDIBuilderCreateEnumerator(m->debug_builder,
			cast(char const *)t.name.text, cast(size_t)t.name.len,
			cast(i64)type_hash_canonical_type(t.type), true
		));
	}
	String name = str_lit("typeid");
	return LLVMDIBuilderCreateEnumerationType(m->debug_builder, nullptr,
		cast(char const *)name.text, cast(size_t)name.len, nullptr, 0, 64, 64,
		enumerators.data, cast(unsigned)enumerators.count, lb_debug_type(m, t_u64)
	);
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
			if (build_context.no_rtti) {
				return lb_debug_type_basic_type(m, str_lit("typeid"), 64, LLVMDWARFTypeEncoding_Unsigned);
			}
			return lb_debug_typeid_enum(m);

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

		case Basic_f16be: return lb_debug_type_basic_type(m,  str_lit("f16be"),   16, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagBigEndian);
		case Basic_f32be: return lb_debug_type_basic_type(m,  str_lit("f32be"),   32, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagBigEndian);
		case Basic_f64be: return lb_debug_type_basic_type(m,  str_lit("f64be"),   64, LLVMDWARFTypeEncoding_Float,    LLVMDIFlagBigEndian);

		case Basic_complex32:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f16, 0*16);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f16, 1*16);
				return lb_debug_basic_struct(m, str_lit("complex32"), 32, 16, elements, gb_count_of(elements));
			}
		case Basic_complex64:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("real"), t_f32, 0*32);
				elements[1] = lb_debug_struct_field(m, str_lit("imag"), t_f32, 1*32);
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
				return lb_debug_basic_struct(m, str_lit("quaternion64"), 64, 16, elements, gb_count_of(elements));
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
				return lb_debug_basic_struct(m, str_lit("quaternion256"), 256, 64, elements, gb_count_of(elements));
			}



		case Basic_rawptr:
			{
				LLVMMetadataRef void_type = lb_debug_type_basic_type(m, str_lit("void"), 8, LLVMDWARFTypeEncoding_Unsigned);
				return LLVMDIBuilderCreatePointerType(m->debug_builder, void_type, ptr_bits, ptr_bits, LLVMDWARFTypeEncoding_Address, "rawptr", 6);
			}
		case Basic_string:
			{
				// NOTE(bill): size_of(^u8) <= size_of(int)

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

		case Basic_string16:
			{
				// NOTE(bill): size_of(^u16) <= size_of(int)
				// The data is `^wchar_t`, as `cstring16` is, so that debuggers show it as text
				LLVMMetadataRef char_type = lb_debug_type_basic_type(m, str_lit("wchar_t"), 16, LLVMDWARFTypeEncoding_Unsigned);
				LLVMMetadataRef file = lb_get_file_metadata(m, m->info->runtime_package->files[0]);

				LLVMMetadataRef elements[2] = {};
				elements[0] = LLVMDIBuilderCreateMemberType(m->debug_builder, file, "data", 4, file, 1, ptr_bits, ptr_bits, 0, LLVMDIFlagZero,
					LLVMDIBuilderCreatePointerType(m->debug_builder, char_type, ptr_bits, ptr_bits, 0, nullptr, 0)
				);
				elements[1] = lb_debug_struct_field(m, str_lit("len"),  t_int, int_bits);
				return lb_debug_basic_struct(m, str_lit("string16"), 2*int_bits, int_bits, elements, gb_count_of(elements));
			}
		case Basic_cstring16:
			{
				LLVMMetadataRef char_type = lb_debug_type_basic_type(m, str_lit("wchar_t"), 16, LLVMDWARFTypeEncoding_Unsigned);
				return LLVMDIBuilderCreatePointerType(m->debug_builder, char_type, ptr_bits, ptr_bits, 0, "cstring16", 7);
			}

		case Basic_any:
			{
				LLVMMetadataRef elements[2] = {};
				elements[0] = lb_debug_struct_field(m, str_lit("data"), t_rawptr, 0);
				elements[1] = lb_debug_struct_field(m, str_lit("id"),   t_typeid, 64); // typeid is always 64 bits in size and 64 bits in alignment
				return lb_debug_basic_struct(m, str_lit("any"), 128, 64, elements, gb_count_of(elements));
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
		// TODO(bill): This is technically incorrect and needs fixing
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
		gbString name = temp_canonical_string(type);
		return LLVMDIBuilderCreateTypedef(m->debug_builder, array_type, name, gb_string_length(name), nullptr, 0, nullptr, cast(u32)(8*type_align_of(type)));
	}

	case Type_Map: {
		init_map_internal_debug_types(type);
		Type *bt = base_type(type->Map.debug_metadata_type);
		GB_ASSERT(bt->kind == Type_Struct);

		return lb_debug_struct(m, type, bt, type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	}

	case Type_Struct:       return lb_debug_struct(       m, type, type, type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_Slice:        return lb_debug_slice(        m, type,       type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_DynamicArray: return lb_debug_dynamic_array(m, type,       type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_Union:        return lb_debug_union(        m, type,       type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_BitSet:       return lb_debug_bitset(       m, type,       type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_Enum:         return lb_debug_enum(         m, type,       type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_BitField:     return lb_debug_bitfield(     m, type,       type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);
	case Type_FixedCapacityDynamicArray: return lb_debug_fixed_capacity_dynamic_array(m, type, type_to_canonical_string(temporary_allocator(), type), nullptr, nullptr, 0);

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
			gbString name = temp_canonical_string(type);
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

	case Type_Matrix: {
	#if 0
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
	#else
		LLVMMetadataRef subscripts[2] = {};
		subscripts[0] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder, 0ll, type->Matrix.row_count);
		subscripts[1] = LLVMDIBuilderGetOrCreateSubrange(m->debug_builder, 0ll, type->Matrix.column_count);

		LLVMMetadataRef scope = nullptr;
		LLVMMetadataRef array_type = nullptr;

		uint64_t size_in_bits = 8*cast(uint64_t)(type_size_of(type));
		unsigned align_in_bits = 8*cast(unsigned)(type_align_of(type));

		if (type->Matrix.is_row_major) {
			LLVMMetadataRef base = LLVMDIBuilderCreateArrayType(m->debug_builder,
				8*cast(uint64_t)(type_size_of(type->Matrix.elem) * type->Matrix.column_count),
				8*cast(unsigned)type_align_of(type->Matrix.elem),
				lb_debug_type(m, type->Matrix.elem),
				subscripts+1, 1);
			array_type = LLVMDIBuilderCreateArrayType(m->debug_builder,
				size_in_bits,
				align_in_bits,
				base,
				subscripts+0, 1);
		} else {
			LLVMMetadataRef base = LLVMDIBuilderCreateArrayType(m->debug_builder,
				8*cast(uint64_t)(type_size_of(type->Matrix.elem) * type->Matrix.row_count),
				8*cast(unsigned)type_align_of(type->Matrix.elem),
				lb_debug_type(m, type->Matrix.elem),
				subscripts+0, 1);
			array_type = LLVMDIBuilderCreateArrayType(m->debug_builder,
				size_in_bits,
				align_in_bits,
				base,
				subscripts+1, 1);
		}

		LLVMMetadataRef elements[1] = {};
		elements[0] = LLVMDIBuilderCreateMemberType(m->debug_builder, scope,
			"data", 4,
			nullptr, 0,
			size_in_bits, align_in_bits, 0, LLVMDIFlagZero,
			array_type
		);

		gbString name = temp_canonical_string(type);

		LLVMMetadataRef final_decl = LLVMDIBuilderCreateStructType(
			m->debug_builder, scope,
			name, gb_string_length(name),
			nullptr, 0,
			size_in_bits, align_in_bits,
			LLVMDIFlagZero,
			nullptr,
			elements, 1,
			0,
			nullptr,
			name, gb_string_length(name)
		);

		return final_decl;
	#endif
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
			found = lb_get_file_metadata(m, scope->file);
			if (found) {
				return found;
			}
		}
		scope = scope->parent;
	}
}

gb_internal LLVMMetadataRef lb_debug_type(lbModule *m, Type *type) {
	GB_ASSERT(type != nullptr);

	MUTEX_GUARD(&m->debug_values_mutex);

	LLVMMetadataRef found = lb_get_llvm_metadata(m, type);
	if (found != nullptr) {
		// NOTE: CodeView can only refer back to a type through a forward reference to a record, so a loop made only of
		// procedure, pointer and array types, as in `Bar :: proc(p: ^Bar)`, is cut to `rawptr` where it closes
		if (type->kind == Type_Named && build_context.metrics.os == TargetOs_windows) {
			for (isize i = m->debug_type_frames.count-1; i >= 0; i--) {
				lbDebugTypeFrame const &frame = m->debug_type_frames[i];
				if (frame.is_record) {
					break;
				}
				if (frame.type == type) {
					lbDebugTypeFrame *top = &m->debug_type_frames[m->debug_type_frames.count-1];
					top->lowest_cut = gb_min(top->lowest_cut, i);
					return lb_debug_type(m, t_rawptr);
				}
			}
		}
		return found;
	}

	bool is_record = false;
	Type *record_bt = base_type(type);
	switch (record_bt->kind) {
	case Type_Struct:
	case Type_Union:
	case Type_Slice:
	case Type_DynamicArray:
	case Type_FixedCapacityDynamicArray:
	case Type_Map:
	case Type_BitSet:
	case Type_BitField:
	case Type_Enum:
	case Type_Matrix:
		is_record = true;
		break;
	case Type_Tuple:
		is_record = record_bt->Tuple.variables.count != 1;
		break;
	case Type_Basic:
		// NOTE(bill): the `typeid` debug-info enum is as mahussive as the type table
		// This means we defined once like the record/any types or else its `id` differs between the module defining `typeid` and the rest
		if (type->kind == Type_Basic) {
			switch (type->Basic.kind) {
			case Basic_typeid: is_record = !build_context.no_rtti; break;
			case Basic_any:    is_record = true;                   break;
			}
		}
		break;
	}

	Array<lbModule *> const &types_modules = m->gen->debug_types_modules;
	String record_name = {};
	lbModule *owner = nullptr;
	if (is_record && types_modules.count != 0 && record_bt->kind != Type_Tuple) {
		record_name = type_to_canonical_string(temporary_allocator(), type);
		owner = types_modules[string_hash(record_name) % types_modules.count];
	}
	if (owner != nullptr && owner != m) {
		// NOTE(bill): The record is defined once in its debug types module and only forward declared here.
		// Enums are matched by name, as the C API cannot give an enumeration an identifier.
		unsigned tag = DW_TAG_structure_type;
		switch (record_bt->kind) {
		case Type_Struct:
			if (is_type_raw_union(record_bt)) {
				tag = DW_TAG_union_type;
			}
			break;
		case Type_Union:
			tag = DW_TAG_union_type;
			break;
		case Type_BitSet:
			tag = DW_TAG_union_type;
			if (lb_debug_bit_set_is_flag_enum(record_bt)) {
				tag = DW_TAG_enumeration_type;
			}
			break;
		case Type_Enum:
			tag = DW_TAG_enumeration_type;
			break;
		case Type_Basic:
			if (record_bt->Basic.kind == Basic_typeid) {
				tag = DW_TAG_enumeration_type;
			}
			break;
		}

		String name = record_name;
		String identifier = name;
		if (tag == DW_TAG_enumeration_type) {
			identifier = {};
		}

		LLVMMetadataRef scope = nullptr;
		if (type->kind == Type_Named && type->Named.type_name != nullptr) {
			scope = lb_get_file_metadata(m, type->Named.type_name->file);
		}

		LLVMMetadataRef forward_decl = LLVMDIBuilderCreateForwardDecl(
			m->debug_builder, tag,
			cast(char const *)name.text, cast(size_t)name.len,
			scope, scope, 0, 0, 0, 0,
			cast(char const *)identifier.text, cast(size_t)identifier.len
		);
		lb_set_llvm_metadata(m, type, forward_decl);
		mpsc_enqueue(&owner->debug_homed_types, type);
		return forward_decl;
	}

	isize frame_index = m->debug_type_frames.count;
	array_add(&m->debug_type_frames, lbDebugTypeFrame{type, is_record, frame_index});
	defer ({
		lbDebugTypeFrame frame = array_pop(&m->debug_type_frames);
		if (frame.lowest_cut < frame_index) {
			// NOTE: holds a cut back to a type still being lowered, so it only stands for that loop and is not kept
			map_remove(&m->debug_values, cast(void *)type);
			lbDebugTypeFrame *parent = &m->debug_type_frames[m->debug_type_frames.count-1];
			parent->lowest_cut = gb_min(parent->lowest_cut, frame.lowest_cut);
		}
	});

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

		String name = type_to_canonical_string(temporary_allocator(), type);

		Type *bt = base_type(type->Named.base);

		switch (bt->kind) {
		default: {
			u32 align_in_bits = 8*cast(u32)type_align_of(type);
			// NOTE: only a type whose base is not basic can be reached again while lowering its base, as in `Bar :: proc(p: ^Bar)`
			LLVMMetadataRef temp_forward_decl = nullptr;
			if (bt->kind != Type_Basic) {
				temp_forward_decl = lb_debug_placeholder(m, type, DW_TAG_typedef, name, scope, file, line, 8*cast(u64)type_size_of(type), align_in_bits);
			}
			LLVMMetadataRef debug_bt = lb_debug_type(m, bt);
			LLVMMetadataRef final_decl = LLVMDIBuilderCreateTypedef(
				m->debug_builder,
				debug_bt,
				cast(char const *)name.text, cast(size_t)name.len,
				file, line, scope, align_in_bits
			);
			return lb_debug_replace_placeholder(m, type, temp_forward_decl, final_decl);
		}

		case Type_Map: {
			init_map_internal_debug_types(bt);
			bt = base_type(bt->Map.debug_metadata_type);
			GB_ASSERT(bt->kind == Type_Struct);
			return lb_debug_struct(m, type, bt, name, scope, file, line);
		}

		case Type_Struct:       return lb_debug_struct(m, type, bt, name, scope, file, line);
		case Type_Slice:        return lb_debug_slice(m, type, name, scope, file, line);
		case Type_DynamicArray: return lb_debug_dynamic_array(m, type, name, scope, file, line);
		case Type_Union:        return lb_debug_union(m, type, name, scope, file, line);
		case Type_BitSet:       return lb_debug_bitset(m, type, name, scope, file, line);
		case Type_Enum:         return lb_debug_enum(m, type, name, scope, file, line);
		case Type_BitField:     return lb_debug_bitfield(m, type, name, scope, file, line);
		}
	}

	LLVMMetadataRef dt = lb_debug_type_internal(m, type);
	lb_set_llvm_metadata(m, type, dt);
	return dt;
}

// A variable whose address is not a stack slot of its own (an argument, or an element or a pointer it refers to)
// would have its location tracked with `DBG_VALUE`s through every block of the procedure,
// so it is described through a stack slot holding that address instead
gb_internal LLVMValueRef lb_debug_storage(lbProcedure *p, LLVMValueRef storage, LLVMMetadataRef *expr) {
	bool is_argument = LLVMIsAArgument(storage) != nullptr;
	if (!is_argument && (!LLVMIsAInstruction(storage) || LLVMIsAAllocaInst(storage))) {
		return storage;
	}
	LLVMBasicBlockRef insert_block = LLVMGetInsertBlock(p->builder);
	LLVMValueRef slot = llvm_alloca(p, LLVMTypeOf(storage), build_context.ptr_size, "");
	LLVMPositionBuilderAtEnd(p->builder, is_argument ? p->decl_block->block : insert_block);
	LLVMBuildStore(p->builder, storage, slot);
	LLVMPositionBuilderAtEnd(p->builder, insert_block);

	uint64_t deref = 0x06; // DW_OP_deref
	*expr = LLVMDIBuilderCreateExpression(p->module->debug_builder, &deref, 1);
	return slot;
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
	LLVMMetadataRef llvm_file = lb_get_file_metadata(m, file);
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
	storage = lb_debug_storage(p, storage, &llvm_expr);

#if LLVM_VERSION_MAJOR <= 18
	LLVMDIBuilderInsertDeclareAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block);
#else
	LLVMDIBuilderInsertDeclareRecordAtEnd(m->debug_builder, storage, var_info, llvm_expr, llvm_debug_loc, block);
#endif
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
	LLVMMetadataRef llvm_file = lb_get_file_metadata(m, file);
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
	storage = lb_debug_storage(p, storage, &llvm_expr);

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

gb_internal void lb_add_debug_info_static_variable(lbProcedure *p, Entity *e, LLVMValueRef global) {
	if (p->debug_info == nullptr) {
		return;
	}
	LLVMMetadataRef global_variable_metadata = LLVMDIBuilderCreateGlobalVariableExpression(
		p->module->debug_builder, p->debug_info,
		cast(char const *)e->token.string.text, cast(size_t)e->token.string.len,
		"", 0, // linkage
		lb_get_file_metadata(p->module, e->file), cast(unsigned)e->token.pos.line,
		lb_debug_type(p->module, e->type),
		true, // local to unit
		LLVMDIBuilderCreateExpression(p->module->debug_builder, nullptr, 0),
		nullptr,
		cast(u32)(8*type_align_of(e->type))
	);
	LLVMGlobalSetMetadata(global, 0, global_variable_metadata);
}

// `pkg::`, or `pkg::[file.odin]::` for what only its own file can see
gb_internal gbString lb_debug_append_name_prefix(gbString s, AstFile *file, Entity *e) {
	AstPackage *pkg = file->pkg;
	s = gb_string_append_length(s, pkg->name.text, pkg->name.len);
	s = gb_string_appendc(s, "::");
	if (e == nullptr || scope_lookup_current(pkg->scope, entity_interned_name(e)) != e) {
		String file_name = filename_without_directory(file->fullpath);
		s = gb_string_append_fmt(s, "[%.*s]::", LIT(file_name));
	}
	return s;
}

// NOTE(bill): the name a user types for a procedure: `pkg::name`, `pkg::outer::inner`, or `pkg::outer::proc@42` for a literal.
// Every instance of a polymorphic procedure shares its name; if they ever need telling apart,
// the template style `pkg::name<T>` is the option, once each debugger is checked with it.
gb_internal gbString lb_debug_append_proc_name(gbString s, DeclInfo *decl) {
	Entity *e = decl->entity.load();
	bool is_literal = e == nullptr || e->Procedure.is_anonymous;
	if (DeclInfo *enclosing = lb_enclosing_proc_decl(decl)) {
		s = lb_debug_append_proc_name(s, enclosing);
		s = gb_string_appendc(s, "::");
	} else {
		Entity *named = nullptr;
		if (!is_literal) {
			named = e;
			if (decl->para_poly_original != nullptr) {
				named = decl->para_poly_original;
			}
		}
		s = lb_debug_append_name_prefix(s, decl->proc_lit->file(), named);
	}
	if (is_literal) {
		s = gb_string_append_fmt(s, "proc@%d", ast_token(decl->proc_lit).pos.line);
	} else {
		s = gb_string_append_length(s, e->token.string.text, e->token.string.len);
	}
	return s;
}

gb_internal String lb_debug_info_mangle_constant_name(Entity *e, gbAllocator const &allocator, bool *did_allocate_) {
	String name = e->token.string;
	if (e->pkg && e->pkg->name.len > 0) {
		gbString s = string_canonical_entity_name(allocator, e);
		name = make_string(cast(u8 const *)s, gb_string_length(s));
		if (did_allocate_) *did_allocate_ = true;
	}
	return name;
}

gb_internal void lb_add_debug_info_global_variable_expr(lbModule *m, String const &name, LLVMMetadataRef dtype, LLVMMetadataRef expr) {
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

gb_internal void lb_add_debug_info_for_global_constant_internal_i64(lbModule *m, Entity *e, LLVMMetadataRef dtype, i64 v) {
	LLVMMetadataRef expr = LLVMDIBuilderCreateConstantValueExpression(m->debug_builder, v);

	TEMPORARY_ALLOCATOR_GUARD();
	String name = lb_debug_info_mangle_constant_name(e, temporary_allocator(), nullptr);

	lb_add_debug_info_global_variable_expr(m, name, dtype, expr);
	if ((e->pkg && e->pkg->kind == Package_Init) ||
	    (e->scope && (e->scope->flags & ScopeFlag_Global))) {
		lb_add_debug_info_global_variable_expr(m, e->token.string, dtype, expr);
	}
}

gb_internal void lb_add_debug_info_for_global_constant_from_entity(lbGenerator *gen, Entity *e) {
	if (e == nullptr || e->kind != Entity_Constant) {
		return;
	}
	if (is_blank_ident(e->token)) {
		return;
	}
	lbModule *m = &gen->default_module;
	if (USE_SEPARATE_MODULES) {
		m = lb_module_of_entity(gen, e, m);
	}
	GB_ASSERT(m != nullptr);

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

			lb_add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_rune(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, t_rune);
			i64 v = exact_value_to_i64(value);
			lb_add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_boolean(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Bool) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = cast(i64)value.value_bool;

			lb_add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
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

			lb_add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	} else if (is_type_pointer(e->type)) {
		ExactValue const &value = e->Constant.value;
		if (value.kind == ExactValue_Integer) {
			LLVMMetadataRef dtype = lb_debug_type(m, default_type(e->type));
			i64 v = cast(i64)exact_value_to_u64(value);
			lb_add_debug_info_for_global_constant_internal_i64(m, e, dtype, v);
		}
	}
}

gb_internal void lb_add_debug_label(lbProcedure *p, Ast *label, lbBlock *target) {
// NOTE(tf2spi): LLVM-C DILabel API used only existed for major versions 20+
#if LLVM_VERSION_MAJOR >= 20
	if (p == nullptr || p->debug_info == nullptr) {
		return;
	}
	if (target == nullptr || label == nullptr || label->kind != Ast_Label) {
		return;
	}
	Token label_token = label->Label.token;
	if (is_blank_ident(label_token.string)) {
		return;
	}
	lbModule *m = p->module;
	if (m == nullptr) {
		return;
	}

	AstFile *file = label->file();
	LLVMMetadataRef llvm_file = lb_get_file_metadata(m, file);
	if (llvm_file == nullptr) {
		debugf("llvm file not found for label\n");
		return;
	}
	LLVMMetadataRef llvm_scope = p->debug_info;
	if(llvm_scope == nullptr) {
		debugf("llvm scope not found for label\n");
		return;
	}
	LLVMMetadataRef llvm_debug_loc = lb_debug_location_from_token_pos(p, label_token.pos);
	LLVMBasicBlockRef llvm_block = target->block;
	if (llvm_block == nullptr || llvm_debug_loc == nullptr) {
		return;
	}
	LLVMMetadataRef llvm_label = LLVMDIBuilderCreateLabel(
		m->debug_builder,
		llvm_scope,
		(const char *)label_token.string.text,
		(size_t)label_token.string.len,
		llvm_file,
		label_token.pos.line,

		// NOTE(tf2spi): Defaults to false in LLVM API, but I'd rather not take chances
		//               Always preserve the label no matter what when debugging
		true
	);
	GB_ASSERT(llvm_label != nullptr);
	(void)LLVMDIBuilderInsertLabelAtEnd(
		m->debug_builder,
		llvm_label,
		llvm_debug_loc,
		llvm_block
	);
#endif
}

struct lbDebugTypesPart {
	lbModule *m;
	isize     pending; // how many of the queued types this round defines
	StringSet seen;
	Array<lbDebugNamedType> homed;
};

gb_internal WORKER_TASK_PROC(lb_debug_define_homed_types_worker_proc) {
	lbDebugTypesPart *part = cast(lbDebugTypesPart *)data;
	lbModule *m = part->m;

	// NOTE(bill): Defined in name order
	// The output does not depend on the order the types were queued in.
	isize first = part->homed.count;
	for (isize i = 0; i < part->pending; i++) {
		Type *type = nullptr;
		bool ok = mpsc_dequeue(&m->debug_homed_types, &type);
		GB_ASSERT(ok);
		String name = type_to_canonical_string(permanent_allocator(), type);
		if (!string_set_update(&part->seen, name)) {
			array_add(&part->homed, lbDebugNamedType{name, type});
		}
	}
	gb_sort_array(part->homed.data+first, part->homed.count-first, lb_debug_named_type_cmp);
	for (isize i = first; i < part->homed.count; i++) {
		lb_debug_type(m, part->homed[i].type);
	}
	return 0;
}

gb_internal WORKER_TASK_PROC(lb_debug_types_anchor_worker_proc) {
	lbDebugTypesPart *part = cast(lbDebugTypesPart *)data;
	lbModule *m = part->m;
	if (part->homed.count == 0) {
		return 0;
	}
	array_sort(part->homed, lb_debug_named_type_cmp);

	char anchor_name[32] = {};
	isize anchor_name_len = gb_snprintf(anchor_name, gb_size_of(anchor_name), "__$debug_types$%d", m->split_part) - 1;
	LLVMMetadataRef file = lb_get_file_metadata(m, m->info->runtime_package->files[0]);
	u32 ptr_bits = 8*cast(u32)build_context.ptr_size;

	auto members = array_make<LLVMMetadataRef>(heap_allocator(), 0, part->homed.count);
	defer (array_free(&members));
	for (lbDebugNamedType const &h : part->homed) {
		LLVMMetadataRef pointer = LLVMDIBuilderCreatePointerType(m->debug_builder, lb_debug_type(m, h.type), ptr_bits, ptr_bits, 0, nullptr, 0);
		array_add(&members, LLVMDIBuilderCreateMemberType(m->debug_builder, file,
			cast(char const *)h.name.text, h.name.len, file, 0,
			ptr_bits, ptr_bits, 0, LLVMDIFlagZero, pointer
		));
	}
	LLVMMetadataRef anchor_type = LLVMDIBuilderCreateUnionType(m->debug_builder, file,
		anchor_name, anchor_name_len, file, 0, ptr_bits, ptr_bits, LLVMDIFlagZero,
		members.data, cast(unsigned)members.count, 0,
		anchor_name, anchor_name_len
	);

	LLVMTypeRef ptr_type = LLVMPointerTypeInContext(m->ctx, 0);
	LLVMValueRef global = LLVMAddGlobal(m->mod, ptr_type, anchor_name);
	LLVMSetInitializer(global, LLVMConstNull(ptr_type));
	LLVMSetLinkage(global, LLVMInternalLinkage);
	lb_append_to_used(m, global);

	LLVMMetadataRef global_expr = LLVMDIBuilderCreateGlobalVariableExpression(m->debug_builder, file,
		anchor_name, anchor_name_len, "", 0, file, 0, anchor_type, true,
		LLVMDIBuilderCreateExpression(m->debug_builder, nullptr, 0), nullptr, ptr_bits
	);
	LLVMGlobalSetMetadata(global, 0, global_expr);
	return 0;
}

gb_internal void lb_debug_generate_types_modules(lbGenerator *gen, bool do_threading) {
	auto parts = array_make<lbDebugTypesPart>(heap_allocator(), gen->debug_types_modules.count);
	defer (array_free(&parts));
	for_array(i, parts) {
		parts[i].m = gen->debug_types_modules[i];
		string_set_init(&parts[i].seen);
		array_init(&parts[i].homed, heap_allocator());
	}

	for (;;) {
		bool any = false;
		for (lbDebugTypesPart &part : parts) {
			part.pending = part.m->debug_homed_types.count.load();
			any |= part.pending != 0;
		}
		if (!any) {
			break;
		}
		for (lbDebugTypesPart &part : parts) {
			if (part.pending == 0) {
				continue;
			}
			if (do_threading) {
				thread_pool_add_task(lb_debug_define_homed_types_worker_proc, &part);
			} else {
				lb_debug_define_homed_types_worker_proc(&part);
			}
		}
		thread_pool_wait();
	}

	for (lbDebugTypesPart &part : parts) {
		if (do_threading) {
			thread_pool_add_task(lb_debug_types_anchor_worker_proc, &part);
		} else {
			lb_debug_types_anchor_worker_proc(&part);
		}
	}
	thread_pool_wait();

	for (lbDebugTypesPart &part : parts) {
		string_set_destroy(&part.seen);
		array_free(&part.homed);
	}
}
