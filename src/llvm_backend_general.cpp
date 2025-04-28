gb_internal void lb_add_debug_local_variable(lbProcedure *p, LLVMValueRef ptr, Type *type, Token const &token);
gb_internal LLVMValueRef llvm_const_string_internal(lbModule *m, Type *t, LLVMValueRef data, LLVMValueRef len);

gb_global Entity *lb_global_type_info_data_entity   = {};
gb_global lbAddr lb_global_type_info_member_types   = {};
gb_global lbAddr lb_global_type_info_member_names   = {};
gb_global lbAddr lb_global_type_info_member_offsets = {};
gb_global lbAddr lb_global_type_info_member_usings  = {};
gb_global lbAddr lb_global_type_info_member_tags    = {};

gb_global isize lb_global_type_info_data_index           = 0;
gb_global isize lb_global_type_info_member_types_index   = 0;
gb_global isize lb_global_type_info_member_names_index   = 0;
gb_global isize lb_global_type_info_member_offsets_index = 0;
gb_global isize lb_global_type_info_member_usings_index  = 0;
gb_global isize lb_global_type_info_member_tags_index    = 0;

gb_internal void lb_init_module(lbModule *m, Checker *c) {
	m->info = &c->info;


	String name = build_context.build_paths[BuildPath_Output].name;
	gbString module_name = gb_string_make(heap_allocator(), "");
	module_name = gb_string_append_length(module_name, name.text, name.len);

	if (!USE_SEPARATE_MODULES) {
		// ignore suffixes
	} else if (m->file) {
		if (gb_string_length(module_name)) {
			module_name = gb_string_appendc(module_name, "-");
		}
		if (m->pkg) {
			module_name = gb_string_append_length(module_name, m->pkg->name.text, m->pkg->name.len);
			module_name = gb_string_appendc(module_name, "-");
		}
		String filename = filename_from_path(m->file->filename);
		module_name = gb_string_append_length(module_name, filename.text, filename.len);
	} else if (m->pkg) {
		if (gb_string_length(module_name)) {
			module_name = gb_string_appendc(module_name, "-");
		}
		module_name = gb_string_append_length(module_name, m->pkg->name.text, m->pkg->name.len);
	} else {
		if (gb_string_length(module_name)) {
			module_name = gb_string_appendc(module_name, "-");
		}
		module_name = gb_string_appendc(module_name, "builtin");
	}

	m->module_name = module_name;
	m->ctx = LLVMContextCreate();
	m->mod = LLVMModuleCreateWithNameInContext(m->module_name, m->ctx);
	// m->debug_builder = nullptr;
	if (build_context.ODIN_DEBUG) {
		enum {DEBUG_METADATA_VERSION = 3};

		LLVMMetadataRef debug_ref = LLVMValueAsMetadata(LLVMConstInt(LLVMInt32TypeInContext(m->ctx), DEBUG_METADATA_VERSION, true));
		LLVMAddModuleFlag(m->mod, LLVMModuleFlagBehaviorWarning, "Debug Info Version", 18, debug_ref);

		switch (build_context.metrics.os) {
		case TargetOs_windows:
			LLVMAddModuleFlag(m->mod,
				LLVMModuleFlagBehaviorWarning,
				"CodeView", 8,
				LLVMValueAsMetadata(LLVMConstInt(LLVMInt32TypeInContext(m->ctx), 1, true)));
			break;

		case TargetOs_darwin:
			// NOTE(bill): Darwin only supports DWARF2 (that I know of)
			LLVMAddModuleFlag(m->mod,
				LLVMModuleFlagBehaviorWarning,
				"Dwarf Version", 13,
				LLVMValueAsMetadata(LLVMConstInt(LLVMInt32TypeInContext(m->ctx), 2, true)));
			break;
		}
		m->debug_builder = LLVMCreateDIBuilder(m->mod);
	}

	gbAllocator a = heap_allocator();
	map_init(&m->types);
	map_init(&m->func_raw_types);
	map_init(&m->struct_field_remapping);
	map_init(&m->values);
	map_init(&m->soa_values);
	string_map_init(&m->members);
	string_map_init(&m->procedures);
	string_map_init(&m->const_strings);
	map_init(&m->function_type_map);
	string_map_init(&m->gen_procs);
	if (USE_SEPARATE_MODULES) {
		array_init(&m->procedures_to_generate, a, 0, 1<<10);
		map_init(&m->procedure_values,               1<<11);
	} else {
		array_init(&m->procedures_to_generate, a, 0, c->info.all_procedures.count);
		map_init(&m->procedure_values,               c->info.all_procedures.count*2);
	}
	array_init(&m->global_procedures_to_create, a, 0, 1024);
	array_init(&m->global_types_to_create, a, 0, 1024);
	array_init(&m->missing_procedures_to_check, a, 0, 16);
	map_init(&m->debug_values);

	string_map_init(&m->objc_classes);
	string_map_init(&m->objc_selectors);
	string_map_init(&m->objc_ivars);

	map_init(&m->map_info_map, 0);
	map_init(&m->map_cell_info_map, 0);
	map_init(&m->exact_value_compound_literal_addr_map, 1024);

	array_init(&m->pad_types, heap_allocator());


	m->const_dummy_builder = LLVMCreateBuilderInContext(m->ctx);

}

gb_internal bool lb_init_generator(lbGenerator *gen, Checker *c) {
	if (global_error_collector.count != 0) {
		return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}

	String init_fullpath = c->parser->init_fullpath;
	linker_data_init(gen, &c->info, init_fullpath);

	#if defined(GB_SYSTEM_OSX) && (LLVM_VERSION_MAJOR < 14)
	linker_enable_system_library_linking(gen);
	#endif

	gen->info = &c->info;

	map_init(&gen->modules, gen->info->packages.count*2);
	map_init(&gen->modules_through_ctx, gen->info->packages.count*2);
	map_init(&gen->anonymous_proc_lits, 1024);

	if (USE_SEPARATE_MODULES) {
		bool module_per_file = build_context.module_per_file && build_context.optimization_level <= 0;
		for (auto const &entry : gen->info->packages) {
			AstPackage *pkg = entry.value;
			auto m = gb_alloc_item(permanent_allocator(), lbModule);
			m->pkg = pkg;
			m->gen = gen;
			map_set(&gen->modules, cast(void *)pkg, m);
			lb_init_module(m, c);
			if (!module_per_file) {
				continue;
			}
			// NOTE(bill): Probably per file is not a good idea, so leave this for later
			for (AstFile *file : pkg->files) {
				auto m = gb_alloc_item(permanent_allocator(), lbModule);
				m->file = file;
				m->pkg = pkg;
				m->gen = gen;
				map_set(&gen->modules, cast(void *)file, m);
				lb_init_module(m, c);
			}
		}
	}

	gen->default_module.gen = gen;
	map_set(&gen->modules, cast(void *)1, &gen->default_module);
	lb_init_module(&gen->default_module, c);

	for (auto const &entry : gen->modules) {
		lbModule *m = entry.value;
		LLVMContextRef ctx = LLVMGetModuleContext(m->mod);
		map_set(&gen->modules_through_ctx, ctx, m);
	}

	mpsc_init(&gen->entities_to_correct_linkage, heap_allocator());
	mpsc_init(&gen->objc_selectors, heap_allocator());
	mpsc_init(&gen->objc_classes, heap_allocator());
	mpsc_init(&gen->objc_ivars, heap_allocator());

	return true;
}



gb_internal lbValue lb_global_type_info_data_ptr(lbModule *m) {
	lbValue v = lb_find_value_from_entity(m, lb_global_type_info_data_entity);
	return v;
}


struct lbLoopData {
	lbAddr idx_addr;
	lbValue idx;
	lbBlock *body;
	lbBlock *done;
	lbBlock *loop;
};

struct lbCompoundLitElemTempData {
	Ast *   expr;
	lbValue value;
	i64     elem_index;
	i64     elem_length;
	lbValue gep;
};


gb_internal lbLoopData lb_loop_start(lbProcedure *p, isize count, Type *index_type=t_i32) {
	lbLoopData data = {};

	lbValue max = lb_const_int(p->module, t_int, count);

	data.idx_addr = lb_add_local_generated(p, index_type, true);

	data.body = lb_create_block(p, "loop.body");
	data.done = lb_create_block(p, "loop.done");
	data.loop = lb_create_block(p, "loop.loop");

	lb_emit_jump(p, data.loop);
	lb_start_block(p, data.loop);

	data.idx = lb_addr_load(p, data.idx_addr);

	lbValue cond = lb_emit_comp(p, Token_Lt, data.idx, max);
	lb_emit_if(p, cond, data.body, data.done);
	lb_start_block(p, data.body);

	return data;
}

gb_internal void lb_loop_end(lbProcedure *p, lbLoopData const &data) {
	if (data.idx_addr.addr.value != nullptr) {
		lb_emit_increment(p, data.idx_addr.addr);
		lb_emit_jump(p, data.loop);
		lb_start_block(p, data.done);
	}
}


gb_internal void lb_make_global_private_const(LLVMValueRef global_data) {
	LLVMSetLinkage(global_data, LLVMLinkerPrivateLinkage);
	// LLVMSetUnnamedAddress(global_data, LLVMGlobalUnnamedAddr);
	LLVMSetGlobalConstant(global_data, true);
}
gb_internal void lb_make_global_private_const(lbAddr const &addr) {
	lb_make_global_private_const(addr.addr.value);
}



// This emits a GEP at 0, index
gb_internal lbValue lb_emit_epi(lbProcedure *p, lbValue const &value, isize index) {
	GB_ASSERT(is_type_pointer(value.type));
	Type *type = type_deref(value.type);

	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(p->module, t_int), 0, false),
		LLVMConstInt(lb_type(p->module, t_int), cast(unsigned long long)index, false),
	};
	LLVMTypeRef llvm_type = lb_type(p->module, type);
	lbValue res = {};
	Type *ptr = base_array_type(type);
	res.type = alloc_type_pointer(ptr);
	if (LLVMIsConstant(value.value)) {
		res.value = LLVMConstGEP2(llvm_type, value.value, indices, gb_count_of(indices));
	} else {
		res.value = LLVMBuildGEP2(p->builder, llvm_type, value.value, indices, gb_count_of(indices), "");
	}
	return res;
}
// This emits a GEP at 0, index
gb_internal lbValue lb_emit_epi(lbModule *m, lbValue const &value, isize index) {
	GB_ASSERT(is_type_pointer(value.type));
	GB_ASSERT(LLVMIsConstant(value.value));
	Type *type = type_deref(value.type);

	LLVMValueRef indices[2] = {
		LLVMConstInt(lb_type(m, t_int), 0, false),
		LLVMConstInt(lb_type(m, t_int), cast(unsigned long long)index, false),
	};
	lbValue res = {};
	Type *ptr = base_array_type(type);
	res.type = alloc_type_pointer(ptr);
	res.value = LLVMConstGEP2(lb_type(m, type), value.value, indices, gb_count_of(indices));
	return res;
}



gb_internal LLVMValueRef llvm_zero(lbModule *m) {
	return LLVMConstInt(lb_type(m, t_int), 0, false);
}

gb_internal LLVMValueRef llvm_alloca(lbProcedure *p, LLVMTypeRef llvm_type, isize alignment, char const *name) {
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);

	LLVMValueRef val = LLVMBuildAlloca(p->builder, llvm_type, name);
	LLVMSetAlignment(val, cast(unsigned int)alignment);

	LLVMPositionBuilderAtEnd(p->builder, p->curr_block->block);

	return val;
}

gb_internal lbValue lb_zero(lbModule *m, Type *t) {
	lbValue v = {};
	v.value = LLVMConstInt(lb_type(m, t), 0, false);
	v.type = t;
	return v;
}
gb_internal LLVMValueRef llvm_const_extract_value(lbModule *m, LLVMValueRef agg, unsigned index) {
	LLVMValueRef res = agg;
	GB_ASSERT(LLVMIsConstant(res));
	res = LLVMBuildExtractValue(m->const_dummy_builder, res, index, "");
	GB_ASSERT(LLVMIsConstant(res));
	return res;
}

gb_internal LLVMValueRef llvm_const_extract_value(lbModule *m, LLVMValueRef agg, unsigned *indices, isize count) {
	// return LLVMConstExtractValue(value, indices, count);
	LLVMValueRef res = agg;
	GB_ASSERT(LLVMIsConstant(res));
	for (isize i = 0; i < count; i++) {
		res = LLVMBuildExtractValue(m->const_dummy_builder, res, indices[i], "");
		GB_ASSERT(LLVMIsConstant(res));
	}
	return res;
}

gb_internal LLVMValueRef llvm_const_insert_value(lbModule *m, LLVMValueRef agg, LLVMValueRef val, unsigned index) {
	GB_ASSERT(LLVMIsConstant(agg));
	GB_ASSERT(LLVMIsConstant(val));

	LLVMValueRef extracted_value = val;
	LLVMValueRef nested = llvm_const_extract_value(m, agg, index);
	GB_ASSERT(LLVMIsConstant(nested));
	extracted_value = LLVMBuildInsertValue(m->const_dummy_builder, nested, extracted_value, index, "");
	GB_ASSERT(LLVMIsConstant(extracted_value));
	return extracted_value;
}


gb_internal LLVMValueRef llvm_const_insert_value(lbModule *m, LLVMValueRef agg, LLVMValueRef val, unsigned *indices, isize count) {
	GB_ASSERT(LLVMIsConstant(agg));
	GB_ASSERT(LLVMIsConstant(val));
	GB_ASSERT(count > 0);

	LLVMValueRef extracted_value = val;
	for (isize i = count-1; i >= 0; i--) {
		LLVMValueRef nested = llvm_const_extract_value(m, agg, indices, i);
		GB_ASSERT(LLVMIsConstant(nested));
		extracted_value = LLVMBuildInsertValue(m->const_dummy_builder, nested, extracted_value, indices[i], "");
	}
	GB_ASSERT(LLVMIsConstant(extracted_value));
	return extracted_value;
}




gb_internal LLVMValueRef llvm_cstring(lbModule *m, String const &str) {
	lbValue v = lb_find_or_add_entity_string(m, str, false);
	unsigned indices[1] = {0};
	return llvm_const_extract_value(m, v.value, indices, gb_count_of(indices));
}

gb_internal bool lb_is_instr_terminating(LLVMValueRef instr) {
	if (instr != nullptr) {
		LLVMOpcode op = LLVMGetInstructionOpcode(instr);
		switch (op) {
		case LLVMRet:
		case LLVMBr:
		case LLVMSwitch:
		case LLVMIndirectBr:
		case LLVMInvoke:
		case LLVMUnreachable:
		case LLVMCallBr:
			return true;
		}
	}
	return false;
}

gb_internal lbModule *lb_module_of_expr(lbGenerator *gen, Ast *expr) {
	GB_ASSERT(expr != nullptr);
	lbModule **found = nullptr;
	AstFile *file = expr->file();
	if (file) {
		found = map_get(&gen->modules, cast(void *)file);
		if (found) {
			return *found;
		}

		if (file->pkg) {
			found = map_get(&gen->modules, cast(void *)file->pkg);
			if (found) {
				return *found;
			}
		}
	}

	return &gen->default_module;
}

gb_internal lbModule *lb_module_of_entity(lbGenerator *gen, Entity *e) {
	GB_ASSERT(e != nullptr);
	lbModule **found = nullptr;
	if (e->kind == Entity_Procedure &&
	    e->decl_info &&
	    e->decl_info->code_gen_module) {
		return e->decl_info->code_gen_module;
	}
	if (e->file) {
		found = map_get(&gen->modules, cast(void *)e->file);
		if (found) {
			GB_ASSERT(*found != nullptr);
			return *found;
		}
	}
	if (e->pkg) {
		found = map_get(&gen->modules, cast(void *)e->pkg);
		if (found) {
			GB_ASSERT(*found != nullptr);
			return *found;
		}
	}
	return &gen->default_module;
}

gb_internal lbAddr lb_addr(lbValue addr) {
	lbAddr v = {lbAddr_Default, addr};
	return v;
}


gb_internal lbAddr lb_addr_map(lbValue addr, lbValue map_key, Type *map_type, Type *map_result) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *mt = type_deref(addr.type);
	GB_ASSERT(is_type_map(mt));

	lbAddr v = {lbAddr_Map, addr};
	v.map.key    = map_key;
	v.map.type   = map_type;
	v.map.result = map_result;
	return v;
}


gb_internal lbAddr lb_addr_soa_variable(lbValue addr, lbValue index, Ast *index_expr) {
	lbAddr v = {lbAddr_SoaVariable, addr};
	v.soa.index = index;
	v.soa.index_expr = index_expr;
	return v;
}

gb_internal lbAddr lb_addr_swizzle(lbValue addr, Type *array_type, u8 swizzle_count, u8 swizzle_indices[4]) {
	GB_ASSERT(is_type_array(array_type) || is_type_simd_vector(array_type));
	GB_ASSERT(1 < swizzle_count && swizzle_count <= 4);
	lbAddr v = {lbAddr_Swizzle, addr};
	v.swizzle.type = array_type;
	v.swizzle.count = swizzle_count;
	gb_memmove(v.swizzle.indices, swizzle_indices, swizzle_count);
	return v;
}

gb_internal lbAddr lb_addr_swizzle_large(lbValue addr, Type *array_type, Slice<i32> const &swizzle_indices) {
	GB_ASSERT_MSG(is_type_array(array_type), "%s", type_to_string(array_type));
	lbAddr v = {lbAddr_SwizzleLarge, addr};
	v.swizzle_large.type = array_type;
	v.swizzle_large.indices = swizzle_indices;
	return v;
}

gb_internal lbAddr lb_addr_bit_field(lbValue addr, Type *type, i64 bit_offset, i64 bit_size) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *mt = type_deref(addr.type);
	GB_ASSERT_MSG(is_type_bit_field(mt), "%s", type_to_string(mt));

	lbAddr v = {lbAddr_BitField, addr};
	v.bitfield.type       = type;
	v.bitfield.bit_offset = bit_offset;
	v.bitfield.bit_size   = bit_size;
	return v;
}


gb_internal Type *lb_addr_type(lbAddr const &addr) {
	if (addr.addr.value == nullptr) {
		return nullptr;
	}
	switch (addr.kind) {
	case lbAddr_Map:
		{
			Type *t = base_type(addr.map.type);
			GB_ASSERT(is_type_map(t));
			return t->Map.value;
		}
	case lbAddr_Swizzle:
		return addr.swizzle.type;
	case lbAddr_SwizzleLarge:
		return addr.swizzle_large.type;
	case lbAddr_Context:
		if (addr.ctx.sel.index.count > 0) {
			Type *t = t_context;
			for_array(i, addr.ctx.sel.index) {
				GB_ASSERT(is_type_struct(t));
				t = base_type(t)->Struct.fields[addr.ctx.sel.index[i]]->type;
			}
			return t;
		}
		break;
	}
	return type_deref(addr.addr.type);
}

gb_internal lbValue lb_make_soa_pointer(lbProcedure *p, Type *type, lbValue const &addr, lbValue const &index) {
	lbAddr v = lb_add_local_generated(p, type, false);
	lbValue ptr = lb_emit_struct_ep(p, v.addr, 0);
	lbValue idx = lb_emit_struct_ep(p, v.addr, 1);
	lb_emit_store(p, ptr, addr);
	lb_emit_store(p, idx, lb_emit_conv(p, index, t_int));

	return lb_addr_load(p, v);
}

gb_internal lbValue lb_addr_get_ptr(lbProcedure *p, lbAddr const &addr) {
	if (addr.addr.value == nullptr) {
		GB_PANIC("Illegal addr -> nullptr");
		return {};
	}

	switch (addr.kind) {
	case lbAddr_Map:
		return lb_internal_dynamic_map_get_ptr(p, addr.addr, addr.map.key);

	case lbAddr_SoaVariable:
		{
			Type *soa_ptr_type = alloc_type_soa_pointer(lb_addr_type(addr));
			return lb_address_from_load_or_generate_local(p, lb_make_soa_pointer(p, soa_ptr_type, addr.addr, addr.soa.index));
			// TODO(bill): FIX THIS HACK
			// return lb_address_from_load(p, lb_addr_load(p, addr));
		}

	case lbAddr_Context:
		GB_PANIC("lbAddr_Context should be handled elsewhere");
		break;

	case lbAddr_Swizzle:
	case lbAddr_SwizzleLarge:
		// TOOD(bill): is this good enough logic?
		break;
	}

	return addr.addr;
}


gb_internal lbValue lb_build_addr_ptr(lbProcedure *p, Ast *expr) {
	lbAddr addr = lb_build_addr(p, expr);
	return lb_addr_get_ptr(p, addr);
}

gb_internal void lb_set_file_line_col(lbProcedure *p, Array<lbValue> arr, TokenPos pos) {
	String file = get_file_path_string(pos.file_id);
	i32 line    = pos.line;
	i32 col     = pos.column;

	if (build_context.obfuscate_source_code_locations) {
		file = obfuscate_string(file, "F");
		line = obfuscate_i32(line);
		col  = obfuscate_i32(col);
	}

	arr[0] = lb_find_or_add_entity_string(p->module, file, false);
	arr[1] = lb_const_int(p->module, t_i32, line);
	arr[2] = lb_const_int(p->module, t_i32, col);
}

gb_internal void lb_emit_bounds_check(lbProcedure *p, Token token, lbValue index, lbValue len) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((p->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	TEMPORARY_ALLOCATOR_GUARD();

	index = lb_emit_conv(p, index, t_int);
	len = lb_emit_conv(p, len, t_int);

	auto args = array_make<lbValue>(temporary_allocator(), 5);
	lb_set_file_line_col(p, args, token.pos);
	args[3] = index;
	args[4] = len;

	lb_emit_runtime_call(p, "bounds_check_error", args);
}

gb_internal void lb_emit_matrix_bounds_check(lbProcedure *p, Token token, lbValue row_index, lbValue column_index, lbValue row_count, lbValue column_count) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((p->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	TEMPORARY_ALLOCATOR_GUARD();

	row_index = lb_emit_conv(p, row_index, t_int);
	column_index = lb_emit_conv(p, column_index, t_int);
	row_count = lb_emit_conv(p, row_count, t_int);
	column_count = lb_emit_conv(p, column_count, t_int);

	auto args = array_make<lbValue>(temporary_allocator(), 7);
	lb_set_file_line_col(p, args, token.pos);
	args[3] = row_index;
	args[4] = column_index;
	args[5] = row_count;
	args[6] = column_count;

	lb_emit_runtime_call(p, "matrix_bounds_check_error", args);
}


gb_internal void lb_emit_multi_pointer_slice_bounds_check(lbProcedure *p, Token token, lbValue low, lbValue high) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((p->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	low = lb_emit_conv(p, low, t_int);
	high = lb_emit_conv(p, high, t_int);

	auto args = array_make<lbValue>(permanent_allocator(), 5);
	lb_set_file_line_col(p, args, token.pos);
	args[3] = low;
	args[4] = high;

	lb_emit_runtime_call(p, "multi_pointer_slice_expr_error", args);
}

gb_internal void lb_emit_slice_bounds_check(lbProcedure *p, Token token, lbValue low, lbValue high, lbValue len, bool lower_value_used) {
	if (build_context.no_bounds_check) {
		return;
	}
	if ((p->state_flags & StateFlag_no_bounds_check) != 0) {
		return;
	}

	high = lb_emit_conv(p, high, t_int);

	if (!lower_value_used) {
		auto args = array_make<lbValue>(permanent_allocator(), 5);
		lb_set_file_line_col(p, args, token.pos);
		args[3] = high;
		args[4] = len;

		lb_emit_runtime_call(p, "slice_expr_error_hi", args);
	} else {
		// No need to convert unless used
		low  = lb_emit_conv(p, low, t_int);

		auto args = array_make<lbValue>(permanent_allocator(), 6);
		lb_set_file_line_col(p, args, token.pos);
		args[3] = low;
		args[4] = high;
		args[5] = len;

		lb_emit_runtime_call(p, "slice_expr_error_lo_hi", args);
	}
}

gb_internal unsigned lb_try_get_alignment(LLVMValueRef addr_ptr, unsigned default_alignment) {
	if (LLVMIsAGlobalValue(addr_ptr) || LLVMIsAAllocaInst(addr_ptr) || LLVMIsALoadInst(addr_ptr)) {
		return LLVMGetAlignment(addr_ptr);
	}
	return default_alignment;
}

gb_internal bool lb_try_update_alignment(LLVMValueRef addr_ptr, unsigned alignment) {
	if (LLVMIsAGlobalValue(addr_ptr) || LLVMIsAAllocaInst(addr_ptr) || LLVMIsALoadInst(addr_ptr)) {
		if (LLVMGetAlignment(addr_ptr) < alignment) {
			if (LLVMIsAAllocaInst(addr_ptr)) {
				LLVMSetAlignment(addr_ptr, alignment);
			} else if (LLVMIsAGlobalValue(addr_ptr) && LLVMGetLinkage(addr_ptr) != LLVMExternalLinkage) {
				// NOTE(laytan): setting alignment of an external global just changes the alignment we expect it to be.
				LLVMSetAlignment(addr_ptr, alignment);
			}
		}
		return LLVMGetAlignment(addr_ptr) >= alignment;
	}
	return false;
}

gb_internal bool lb_try_update_alignment(lbValue ptr, unsigned alignment) {
	return lb_try_update_alignment(ptr.value, alignment);
}

gb_internal bool lb_can_try_to_inline_array_arith(Type *t) {
	return type_size_of(t) <= build_context.max_simd_align;
}

gb_internal bool lb_try_vector_cast(lbModule *m, lbValue ptr, LLVMTypeRef *vector_type_) {
	Type *array_type = base_type(type_deref(ptr.type));
	GB_ASSERT(is_type_array_like(array_type));
	i64 count = get_array_type_count(array_type);
	Type *elem_type = base_array_type(array_type);

	// TODO(bill): Determine what is the correct limit for doing vector arithmetic
	if (lb_can_try_to_inline_array_arith(array_type) &&
	    is_type_valid_vector_elem(elem_type)) {
		// Try to treat it like a vector if possible
		bool possible = false;
		LLVMTypeRef vector_type = LLVMVectorType(lb_type(m, elem_type), cast(unsigned)count);
		unsigned vector_alignment = cast(unsigned)lb_alignof(vector_type);

		LLVMValueRef addr_ptr = ptr.value;
		if (LLVMIsAAllocaInst(addr_ptr) || LLVMIsAGlobalValue(addr_ptr)) {
			possible = lb_try_update_alignment(addr_ptr, vector_alignment);
		} else if (LLVMIsALoadInst(addr_ptr)) {
			unsigned alignment = LLVMGetAlignment(addr_ptr);
			possible = alignment >= vector_alignment;
		}

		// NOTE: Due to alignment requirements, if the pointer is not correctly aligned
		// then it cannot be treated as a vector
		if (possible) {
			if (vector_type_) *vector_type_ =vector_type;
			return true;
		}
	}
	return false;
}

gb_internal LLVMValueRef OdinLLVMBuildLoad(lbProcedure *p, LLVMTypeRef type, LLVMValueRef value) {
	LLVMValueRef result = LLVMBuildLoad2(p->builder, type, value, "");

	// If it is not an instruction it isn't a GEP, so we don't need to track alignment in the metadata,
	// which is not possible anyway (only LLVM instructions can have metadata).
	if (LLVMIsAInstruction(value)) {
		u64 is_packed = lb_get_metadata_custom_u64(p->module, value, ODIN_METADATA_IS_PACKED);
		if (is_packed != 0) {
			LLVMSetAlignment(result, 1);
		}
		u64 align = LLVMGetAlignment(result);
		u64 align_min = lb_get_metadata_custom_u64(p->module, value, ODIN_METADATA_MIN_ALIGN);
		u64 align_max = lb_get_metadata_custom_u64(p->module, value, ODIN_METADATA_MAX_ALIGN);
		if (align_min != 0 && align < align_min) {
			align = align_min;
		}
		if (align_max != 0 && align > align_max) {
			align = align_max;
		}
		GB_ASSERT(align <= UINT_MAX);
		LLVMSetAlignment(result, (unsigned int)align);
	}

	return result;
}

gb_internal LLVMValueRef OdinLLVMBuildLoadAligned(lbProcedure *p, LLVMTypeRef type, LLVMValueRef value, i64 alignment) {
	LLVMValueRef result = LLVMBuildLoad2(p->builder, type, value, "");

	LLVMSetAlignment(result, cast(unsigned)alignment);

	if (LLVMIsAInstruction(value)) {
		u64 is_packed = lb_get_metadata_custom_u64(p->module, value, ODIN_METADATA_IS_PACKED);
		if (is_packed != 0) {
			LLVMSetAlignment(result, 1);
		}
	}

	return result;
}

gb_internal void lb_addr_store(lbProcedure *p, lbAddr addr, lbValue value) {
	if (addr.addr.value == nullptr) {
		return;
	}
	GB_ASSERT(value.type != nullptr);
	if (is_type_untyped_uninit(value.type)) {
		Type *t = lb_addr_type(addr);
		value.type = t;
		value.value = LLVMGetUndef(lb_type(p->module, t));
	} else if (is_type_untyped_nil(value.type)) {
		Type *t = lb_addr_type(addr);
		value.type = t;
		value.value = LLVMConstNull(lb_type(p->module, t));
	}

	if (addr.kind == lbAddr_BitField) {
		lbValue dst = addr.addr;
		if (is_type_endian_big(addr.bitfield.type)) {
			i64 shift_amount = 8*type_size_of(value.type) - addr.bitfield.bit_size;
			lbValue shifted_value = value;
			shifted_value.value = LLVMBuildLShr(p->builder,
				shifted_value.value,
				LLVMConstInt(LLVMTypeOf(shifted_value.value), shift_amount, false), "");

			lbValue src = lb_address_from_load_or_generate_local(p, shifted_value);

			auto args = array_make<lbValue>(temporary_allocator(), 4);
			args[0] = dst;
			args[1] = src;
			args[2] = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_offset);
			args[3] = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_size);
			lb_emit_runtime_call(p, "__write_bits", args);
		} else if ((addr.bitfield.bit_offset % 8) == 0 &&
		           (addr.bitfield.bit_size   % 8) == 0) {
			lbValue src = lb_address_from_load_or_generate_local(p, value);

			lbValue byte_offset = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_offset/8);
			lbValue byte_size = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_size/8);
			lbValue dst_offset = lb_emit_conv(p, dst, t_u8_ptr);
			dst_offset = lb_emit_ptr_offset(p, dst_offset, byte_offset);
			lb_mem_copy_non_overlapping(p, dst_offset, src, byte_size);
		} else {
			lbValue src = lb_address_from_load_or_generate_local(p, value);

			auto args = array_make<lbValue>(temporary_allocator(), 4);
			args[0] = dst;
			args[1] = src;
			args[2] = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_offset);
			args[3] = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_size);
			lb_emit_runtime_call(p, "__write_bits", args);
		}
		return;
	} else if (addr.kind == lbAddr_Map) {
		lb_internal_dynamic_map_set(p, addr.addr, addr.map.type, addr.map.key, value, p->curr_stmt);
		return;
	} else if (addr.kind == lbAddr_Context) {
		lbAddr old_addr = lb_find_or_generate_context_ptr(p);


		// IMPORTANT NOTE(bill, 2021-04-22): reuse unused 'context' variables to minimize stack usage
		// This has to be done manually since the optimizer cannot determine when this is possible
		bool create_new = true;
		for_array(i, p->context_stack) {
			lbContextData *ctx_data = &p->context_stack[i];
			if (ctx_data->ctx.addr.value == old_addr.addr.value) {
				if (ctx_data->uses > 0) {
					create_new = true;
				} else if (p->scope_index > ctx_data->scope_index) {
					create_new = true;
				} else {
					// gb_printf_err("%.*s (curr:%td) (ctx:%td) (uses:%td)\n", LIT(p->name), p->scope_index, ctx_data->scope_index, ctx_data->uses);
					create_new = false;
				}
				break;
			}
		}

		lbValue next = {};
		if (create_new) {
			lbValue old = lb_addr_load(p, old_addr);
			lbAddr next_addr = lb_add_local_generated(p, t_context, true);
			lb_addr_store(p, next_addr, old);
			lb_push_context_onto_stack(p, next_addr);
			next = next_addr.addr;
		} else {
			next = old_addr.addr;
		}

		if (addr.ctx.sel.index.count > 0) {
			lbValue lhs = lb_emit_deep_field_gep(p, next, addr.ctx.sel);
			lbValue rhs = lb_emit_conv(p, value, type_deref(lhs.type));
			lb_emit_store(p, lhs, rhs);
		} else {
			lbValue lhs = next;
			lbValue rhs = lb_emit_conv(p, value, lb_addr_type(addr));
			lb_emit_store(p, lhs, rhs);
		}

		return;
	} else if (addr.kind == lbAddr_SoaVariable) {
		Type *t = type_deref(addr.addr.type);
		t = base_type(t);
		GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
		Type *elem_type = t->Struct.soa_elem;
		value = lb_emit_conv(p, value, elem_type);
		elem_type = base_type(elem_type);

		lbValue index = addr.soa.index;
		if (!lb_is_const(index) || t->Struct.soa_kind != StructSoa_Fixed) {
			Type *t = base_type(type_deref(addr.addr.type));
			GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
			lbValue len = lb_soa_struct_len(p, addr.addr);
			if (addr.soa.index_expr != nullptr) {
				lb_emit_bounds_check(p, ast_token(addr.soa.index_expr), index, len);
			}
		}

		isize field_count = 0;

		switch (elem_type->kind) {
		case Type_Struct:
			field_count = elem_type->Struct.fields.count;
			break;
		case Type_Array:
			field_count = cast(isize)elem_type->Array.count;
			break;
		}
		for (isize i = 0; i < field_count; i++) {
			lbValue dst = lb_emit_struct_ep(p, addr.addr, cast(i32)i);
			lbValue src = lb_emit_struct_ev(p, value, cast(i32)i);
			if (t->Struct.soa_kind == StructSoa_Fixed) {
				dst = lb_emit_array_ep(p, dst, index);
				lb_emit_store(p, dst, src);
			} else {
				lbValue field = lb_emit_load(p, dst);
				dst = lb_emit_ptr_offset(p, field, index);
				lb_emit_store(p, dst, src);
			}
		}
		return;
	} else if (addr.kind == lbAddr_Swizzle) {
		GB_ASSERT(addr.swizzle.count <= 4);

		GB_ASSERT(value.value != nullptr);
		value = lb_emit_conv(p, value, lb_addr_type(addr));

		lbValue dst = lb_addr_get_ptr(p, addr);
		lbValue src = lb_address_from_load_or_generate_local(p, value);
		{
			lbValue src_ptrs[4] = {};
			lbValue src_loads[4] = {};
			lbValue dst_ptrs[4] = {};

			for (u8 i = 0; i < addr.swizzle.count; i++) {
				src_ptrs[i] = lb_emit_array_epi(p, src, i);
			}
			for (u8 i = 0; i < addr.swizzle.count; i++) {
				dst_ptrs[i] = lb_emit_array_epi(p, dst, addr.swizzle.indices[i]);
			}
			for (u8 i = 0; i < addr.swizzle.count; i++) {
				src_loads[i] = lb_emit_load(p, src_ptrs[i]);
			}

			for (u8 i = 0; i < addr.swizzle.count; i++) {
				lb_emit_store(p, dst_ptrs[i], src_loads[i]);
			}
		}
		return;
	} else if (addr.kind == lbAddr_SwizzleLarge) {
		GB_ASSERT(value.value != nullptr);
		value = lb_emit_conv(p, value, lb_addr_type(addr));

		lbValue dst = lb_addr_get_ptr(p, addr);
		lbValue src = lb_address_from_load_or_generate_local(p, value);
		for_array(i, addr.swizzle_large.indices) {
			lbValue src_ptr = lb_emit_array_epi(p, src, i);
			lbValue dst_ptr = lb_emit_array_epi(p, dst, addr.swizzle_large.indices[i]);
			lbValue src_load = lb_emit_load(p, src_ptr);
			lb_emit_store(p, dst_ptr, src_load);
		}
		return;
	}

	GB_ASSERT(value.value != nullptr);
	value = lb_emit_conv(p, value, lb_addr_type(addr));

	lb_emit_store(p, addr.addr, value);
}

gb_internal bool lb_is_type_proc_recursive(Type *t) {
	for (;;) {
		if (t == nullptr) {
			return false;
		}
		switch (t->kind) {
		case Type_Named:
			t = t->Named.base;
			break;
		case Type_Pointer:
			t = t->Pointer.elem;
			break;
		case Type_Proc:
			return true;
		default:
			return false;
		}
	}
}

gb_internal void lb_emit_store(lbProcedure *p, lbValue ptr, lbValue value) {
	GB_ASSERT(value.value != nullptr);

	if (LLVMIsUndef(value.value)) {
		return;
	}

	Type *a = type_deref(ptr.type, true);
	if (LLVMIsNull(value.value)) {
		LLVMTypeRef src_t = llvm_addr_type(p->module, ptr);
		if (is_type_proc(a)) {
			LLVMTypeRef rawptr_type = lb_type(p->module, t_rawptr);
			LLVMTypeRef rawptr_ptr_type = LLVMPointerType(rawptr_type, 0);
			LLVMBuildStore(p->builder, LLVMConstNull(rawptr_type), LLVMBuildBitCast(p->builder, ptr.value, rawptr_ptr_type, ""));
		} else if (is_type_bit_set(a)) {
			lb_mem_zero_ptr(p, ptr.value, a, 1);
		} else if (lb_sizeof(src_t) <= lb_max_zero_init_size()) {
			LLVMBuildStore(p->builder, LLVMConstNull(src_t), ptr.value);
		} else {
			lb_mem_zero_ptr(p, ptr.value, a, 1);
		}
		return;
	}
	if (is_type_boolean(a)) {
		// NOTE(bill): There are multiple sized booleans, thus force a conversion (if necessarily)
		value = lb_emit_conv(p, value, a);
	}
	Type *ca = core_type(a);
	if (ca->kind == Type_Basic) {
		GB_ASSERT_MSG(are_types_identical(ca, core_type(value.type)), "%s != %s", type_to_string(a), type_to_string(value.type));
	}

	enum {MAX_STORE_SIZE = 64};

	if (lb_sizeof(LLVMTypeOf(value.value)) > MAX_STORE_SIZE) {
		if (!p->in_multi_assignment && LLVMIsALoadInst(value.value)) {
			LLVMValueRef dst_ptr = ptr.value;
			LLVMValueRef src_ptr_original = LLVMGetOperand(value.value, 0);
			LLVMValueRef src_ptr = LLVMBuildPointerCast(p->builder, src_ptr_original, LLVMTypeOf(dst_ptr), "");

			LLVMBuildMemMove(p->builder,
			                 dst_ptr, lb_try_get_alignment(dst_ptr, 1),
			                 src_ptr, lb_try_get_alignment(src_ptr_original, 1),
			                 LLVMConstInt(LLVMInt64TypeInContext(p->module->ctx), lb_sizeof(LLVMTypeOf(value.value)), false));
			return;
		} else if (LLVMIsConstant(value.value)) {
			lbAddr addr = lb_add_global_generated_from_procedure(p, value.type, value);
			lb_make_global_private_const(addr);

			LLVMValueRef dst_ptr = ptr.value;
			LLVMValueRef src_ptr = addr.addr.value;
			src_ptr = LLVMBuildPointerCast(p->builder, src_ptr, LLVMTypeOf(dst_ptr), "");

			LLVMBuildMemMove(p->builder,
			                 dst_ptr, lb_try_get_alignment(dst_ptr, 1),
			                 src_ptr, lb_try_get_alignment(src_ptr, 1),
			                 LLVMConstInt(LLVMInt64TypeInContext(p->module->ctx), lb_sizeof(LLVMTypeOf(value.value)), false));
			return;
		}
	}

	LLVMValueRef instr = nullptr;
	if (lb_is_type_proc_recursive(a)) {
		// NOTE(bill, 2020-11-11): Because of certain LLVM rules, a procedure value may be
		// stored as regular pointer with no procedure information

 		LLVMTypeRef rawptr_type = lb_type(p->module, t_rawptr);
 		LLVMTypeRef rawptr_ptr_type = LLVMPointerType(rawptr_type, 0);
		instr = LLVMBuildStore(p->builder,
		                       LLVMBuildPointerCast(p->builder, value.value, rawptr_type, ""),
		                       LLVMBuildPointerCast(p->builder, ptr.value, rawptr_ptr_type, ""));
	} else {
		Type *ca = core_type(a);
		if (ca->kind == Type_Basic || ca->kind == Type_Proc) {
			GB_ASSERT_MSG(are_types_identical(ca, core_type(value.type)), "%s != %s", type_to_string(a), type_to_string(value.type));
		} else {
			GB_ASSERT_MSG(are_types_identical(a, value.type), "%s != %s", type_to_string(a), type_to_string(value.type));
		}

		instr = LLVMBuildStore(p->builder, value.value, ptr.value);
	}
	// LLVMSetVolatile(instr, p->in_multi_assignment);
}

gb_internal LLVMTypeRef llvm_addr_type(lbModule *module, lbValue addr_val) {
	return lb_type(module, type_deref(addr_val.type));
}

gb_internal lbValue lb_emit_load(lbProcedure *p, lbValue value) {
	GB_ASSERT(value.value != nullptr);
	if (is_type_multi_pointer(value.type)) {
		Type *vt = base_type(value.type);
		GB_ASSERT(vt->kind == Type_MultiPointer);
		Type *t = vt->MultiPointer.elem;
		LLVMValueRef v = OdinLLVMBuildLoad(p, lb_type(p->module, t), value.value);
		return lbValue{v, t};
	} else if (is_type_soa_pointer(value.type)) {
		lbValue ptr = lb_emit_struct_ev(p, value, 0);
		lbValue idx = lb_emit_struct_ev(p, value, 1);
		lbAddr addr = lb_addr_soa_variable(ptr, idx, nullptr);
		return lb_addr_load(p, addr);
	}

	GB_ASSERT_MSG(is_type_pointer(value.type), "%s", type_to_string(value.type));
	Type *t = type_deref(value.type);
	LLVMValueRef v = OdinLLVMBuildLoad(p, lb_type(p->module, t), value.value);

	return lbValue{v, t};
}

gb_internal lbValue lb_addr_load(lbProcedure *p, lbAddr const &addr) {
	GB_ASSERT(addr.addr.value != nullptr);

	if (addr.kind == lbAddr_BitField) {
		Type *ct = core_type(addr.bitfield.type);
		bool do_mask = false;
		if (is_type_unsigned(ct) || is_type_boolean(ct)) {
			// Mask
			if (addr.bitfield.bit_size != 8*type_size_of(ct)) {
				do_mask = true;
			}
		}

		i64 total_bitfield_bit_size = 8*type_size_of(lb_addr_type(addr));
		i64 dst_byte_size = type_size_of(addr.bitfield.type);
		lbAddr dst = lb_add_local_generated(p, addr.bitfield.type, true);
		lbValue src = addr.addr;

		lbValue bit_offset  = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_offset);
		lbValue bit_size    = lb_const_int(p->module, t_uintptr, addr.bitfield.bit_size);
		lbValue byte_offset = lb_const_int(p->module, t_uintptr, (addr.bitfield.bit_offset+7)/8);
		lbValue byte_size   = lb_const_int(p->module, t_uintptr, (addr.bitfield.bit_size+7)/8);

		GB_ASSERT(type_size_of(addr.bitfield.type) >= ((addr.bitfield.bit_size+7)/8));

		lbValue r = {};
		if (is_type_endian_big(addr.bitfield.type)) {
			auto args = array_make<lbValue>(temporary_allocator(), 4);
			args[0] = dst.addr;
			args[1] = src;
			args[2] = bit_offset;
			args[3] = bit_size;
			lb_emit_runtime_call(p, "__read_bits", args);

			LLVMValueRef shift_amount = LLVMConstInt(
				lb_type(p->module, lb_addr_type(dst)),
				8*dst_byte_size - addr.bitfield.bit_size,
				false
			);
			r = lb_addr_load(p, dst);
			r.value = LLVMBuildShl(p->builder, r.value, shift_amount, "");
		} else if ((addr.bitfield.bit_offset % 8) == 0) {
			do_mask = 8*dst_byte_size != addr.bitfield.bit_size;

			lbValue copy_size = byte_size;
			lbValue src_offset = lb_emit_conv(p, src, t_u8_ptr);
			src_offset = lb_emit_ptr_offset(p, src_offset, byte_offset);
			if (addr.bitfield.bit_offset + 8*dst_byte_size <= total_bitfield_bit_size) {
				copy_size = lb_const_int(p->module, t_uintptr, dst_byte_size);
			}
			lb_mem_copy_non_overlapping(p, dst.addr, src_offset, copy_size, false);
			r = lb_addr_load(p, dst);
		} else {
			auto args = array_make<lbValue>(temporary_allocator(), 4);
			args[0] = dst.addr;
			args[1] = src;
			args[2] = bit_offset;
			args[3] = bit_size;
			lb_emit_runtime_call(p, "__read_bits", args);
			r = lb_addr_load(p, dst);
		}

		Type *t = addr.bitfield.type;

		if (do_mask) {
			GB_ASSERT(addr.bitfield.bit_size <= 8*type_size_of(ct));

			lbValue mask = lb_const_int(p->module, t, (1ull<<cast(u64)addr.bitfield.bit_size)-1);
			r = lb_emit_arith(p, Token_And, r, mask, t);
		}

		if (!is_type_unsigned(ct) && !is_type_boolean(ct)) {
			// Sign extension
			// m := 1<<(bit_size-1)
			// r = (r XOR m) - m
			lbValue m = lb_const_int(p->module, t, 1ull<<(addr.bitfield.bit_size-1));
			r = lb_emit_arith(p, Token_Xor, r, m, t);
			r = lb_emit_arith(p, Token_Sub, r, m, t);
		}

		return r;
	} else if (addr.kind == lbAddr_Map) {
		Type *map_type = base_type(type_deref(addr.addr.type));
		GB_ASSERT(map_type->kind == Type_Map);
		lbAddr v = lb_add_local_generated(p, map_type->Map.lookup_result_type, true);

		lbValue ptr = lb_internal_dynamic_map_get_ptr(p, addr.addr, addr.map.key);
		lbValue ok = lb_emit_conv(p, lb_emit_comp_against_nil(p, Token_NotEq, ptr), t_bool);
		lb_emit_store(p, lb_emit_struct_ep(p, v.addr, 1), ok);

		lbBlock *then = lb_create_block(p, "map.get.then");
		lbBlock *done = lb_create_block(p, "map.get.done");
		lb_emit_if(p, ok, then, done);
		lb_start_block(p, then);
		{
			// TODO(bill): mem copy it instead?
			lbValue gep0 = lb_emit_struct_ep(p, v.addr, 0);
			lbValue value = lb_emit_conv(p, ptr, gep0.type);
			lb_emit_store(p, gep0, lb_emit_load(p, value));
		}
		lb_emit_jump(p, done);
		lb_start_block(p, done);


		if (is_type_tuple(addr.map.result)) {
			return lb_addr_load(p, v);
		} else {
			lbValue single = lb_emit_struct_ep(p, v.addr, 0);
			return lb_emit_load(p, single);
		}
	} else if (addr.kind == lbAddr_Context) {
		lbValue a = addr.addr;
		for_array(i, p->context_stack) {
			lbContextData *ctx_data = &p->context_stack[i];
			if (ctx_data->ctx.addr.value == a.value) {
				ctx_data->uses += 1;
				break;
			}
		}
		a.value = LLVMBuildPointerCast(p->builder, a.value, lb_type(p->module, t_context_ptr), "");

		if (addr.ctx.sel.index.count > 0) {
			lbValue b = lb_emit_deep_field_gep(p, a, addr.ctx.sel);
			return lb_emit_load(p, b);
		} else {
			return lb_emit_load(p, a);
		}
	} else if (addr.kind == lbAddr_SoaVariable) {
		Type *t = type_deref(addr.addr.type);
		t = base_type(t);
		GB_ASSERT(t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None);
		Type *elem = t->Struct.soa_elem;

		lbValue len = {};
		if (t->Struct.soa_kind == StructSoa_Fixed) {
			len = lb_const_int(p->module, t_int, t->Struct.soa_count);
		} else {
			lbValue v = lb_emit_load(p, addr.addr);
			len = lb_soa_struct_len(p, v);
		}

		lbAddr res = lb_add_local_generated(p, elem, true);

		if (addr.soa.index_expr != nullptr && (!lb_is_const(addr.soa.index) || t->Struct.soa_kind != StructSoa_Fixed)) {
			lb_emit_bounds_check(p, ast_token(addr.soa.index_expr), addr.soa.index, len);
		}

		if (t->Struct.soa_kind == StructSoa_Fixed) {
			for_array(i, t->Struct.fields) {
				Entity *field = t->Struct.fields[i];
				Type *base_type = field->type;
				GB_ASSERT(base_type->kind == Type_Array);

				lbValue dst = lb_emit_struct_ep(p, res.addr, cast(i32)i);
				lbValue src_ptr = lb_emit_struct_ep(p, addr.addr, cast(i32)i);
				src_ptr = lb_emit_array_ep(p, src_ptr, addr.soa.index);
				lbValue src = lb_emit_load(p, src_ptr);
				lb_emit_store(p, dst, src);
			}
		} else {
			isize field_count = t->Struct.fields.count;
			if (t->Struct.soa_kind == StructSoa_Slice) {
				field_count -= 1;
			} else if (t->Struct.soa_kind == StructSoa_Dynamic) {
				field_count -= 3;
			}
			for (isize i = 0; i < field_count; i++) {
				Entity *field = t->Struct.fields[i];
				Type *base_type = field->type;
				GB_ASSERT(base_type->kind == Type_MultiPointer);

				lbValue dst = lb_emit_struct_ep(p, res.addr, cast(i32)i);
				lbValue src_ptr = lb_emit_struct_ep(p, addr.addr, cast(i32)i);
				lbValue src = lb_emit_load(p, src_ptr);
				src = lb_emit_ptr_offset(p, src, addr.soa.index);
				src = lb_emit_load(p, src);
				lb_emit_store(p, dst, src);
			}
		}

		return lb_addr_load(p, res);
	} else if (addr.kind == lbAddr_Swizzle) {
		Type *array_type = base_type(addr.swizzle.type);
		if (array_type->kind == Type_SimdVector) {
			lbValue vec = lb_emit_load(p, addr.addr);
			u8 index_count = addr.swizzle.count;
			if (index_count == 0) {
				return vec;
			}

			unsigned mask_len = cast(unsigned)index_count;
			LLVMValueRef *mask_elems = gb_alloc_array(permanent_allocator(), LLVMValueRef, index_count);
			for (isize i = 0; i < index_count; i++) {
				mask_elems[i] = LLVMConstInt(lb_type(p->module, t_u32), addr.swizzle.indices[i], false);
			}

			LLVMValueRef mask = LLVMConstVector(mask_elems, mask_len);

			LLVMValueRef v1 = vec.value;
			LLVMValueRef v2 = vec.value;

			lbValue res = {};
			res.type = addr.swizzle.type;
			res.value = LLVMBuildShuffleVector(p->builder, v1, v2, mask, "");
			return res;
		}

		GB_ASSERT(array_type->kind == Type_Array);

		unsigned res_align = cast(unsigned)type_align_of(addr.swizzle.type);

		static u8 const ordered_indices[4] = {0, 1, 2, 3};
		if (gb_memcompare(ordered_indices, addr.swizzle.indices, addr.swizzle.count) == 0) {
			if (lb_try_update_alignment(addr.addr, res_align)) {
				Type *pt = alloc_type_pointer(addr.swizzle.type);
				lbValue res = {};
				res.value = LLVMBuildPointerCast(p->builder, addr.addr.value, lb_type(p->module, pt), "");
				res.type = pt;
				return lb_emit_load(p, res);
			}
		}

		lbAddr res = lb_add_local_generated(p, addr.swizzle.type, false);
		lbValue ptr = lb_addr_get_ptr(p, res);
		GB_ASSERT(is_type_pointer(ptr.type));

		LLVMTypeRef vector_type = nullptr;
		if (lb_try_vector_cast(p->module, addr.addr, &vector_type)) {
			LLVMValueRef vp = LLVMBuildPointerCast(p->builder, addr.addr.value, LLVMPointerType(vector_type, 0), "");
			LLVMValueRef v = OdinLLVMBuildLoad(p, vector_type, vp);
			LLVMValueRef scalars[4] = {};
			for (u8 i = 0; i < addr.swizzle.count; i++) {
				scalars[i] = LLVMConstInt(lb_type(p->module, t_u32), addr.swizzle.indices[i], false);
			}
			LLVMValueRef mask = LLVMConstVector(scalars, addr.swizzle.count);
			LLVMValueRef sv = llvm_basic_shuffle(p, v, mask);

			LLVMSetAlignment(res.addr.value, cast(unsigned)lb_alignof(LLVMTypeOf(sv)));

			LLVMValueRef dst = LLVMBuildPointerCast(p->builder, ptr.value, LLVMPointerType(LLVMTypeOf(sv), 0), "");
			LLVMBuildStore(p->builder, sv, dst);
		} else {
			for (u8 i = 0; i < addr.swizzle.count; i++) {
				u8 index = addr.swizzle.indices[i];
				lbValue dst = lb_emit_array_epi(p, ptr, i);
				lbValue src = lb_emit_array_epi(p, addr.addr, index);
				lb_emit_store(p, dst, lb_emit_load(p, src));
			}
		}
		return lb_addr_load(p, res);
	}  else if (addr.kind == lbAddr_SwizzleLarge) {
		Type *array_type = base_type(addr.swizzle_large.type);
		GB_ASSERT(array_type->kind == Type_Array);

		unsigned res_align = cast(unsigned)type_align_of(addr.swizzle_large.type);
		gb_unused(res_align);

		lbAddr res = lb_add_local_generated(p, addr.swizzle_large.type, false);
		lbValue ptr = lb_addr_get_ptr(p, res);
		GB_ASSERT(is_type_pointer(ptr.type));

		for_array(i, addr.swizzle_large.indices) {
			i32 index = addr.swizzle_large.indices[i];
			lbValue dst = lb_emit_array_epi(p, ptr, i);
			lbValue src = lb_emit_array_epi(p, addr.addr, index);
			lb_emit_store(p, dst, lb_emit_load(p, src));
		}

		return lb_addr_load(p, res);
	}

	if (is_type_proc(addr.addr.type)) {
		return addr.addr;
	}
	return lb_emit_load(p, addr.addr);
}

gb_internal lbValue lb_const_union_tag(lbModule *m, Type *u, Type *v) {
	return lb_const_value(m, union_tag_type(u), exact_value_i64(union_variant_index(u, v)));
}

gb_internal lbValue lb_emit_union_tag_ptr(lbProcedure *p, lbValue u) {
	Type *t = u.type;
	GB_ASSERT_MSG(is_type_pointer(t) &&
	              is_type_union(type_deref(t)), "%s", type_to_string(t));
	Type *ut = type_deref(t);

	GB_ASSERT(!is_type_union_maybe_pointer_original_alignment(ut));
	GB_ASSERT(!is_type_union_maybe_pointer(ut));
	GB_ASSERT(type_size_of(ut) > 0);

	Type *tag_type = union_tag_type(ut);

	LLVMTypeRef uvt = llvm_addr_type(p->module, u);
	unsigned element_count = LLVMCountStructElementTypes(uvt);
	GB_ASSERT_MSG(element_count >= 2, "element_count=%u (%s) != (%s)", element_count, type_to_string(ut), LLVMPrintTypeToString(uvt));

	lbValue tag_ptr = {};
	tag_ptr.value = LLVMBuildStructGEP2(p->builder, uvt, u.value, 1, "");
	tag_ptr.type = alloc_type_pointer(tag_type);
	return tag_ptr;
}

gb_internal lbValue lb_emit_union_tag_value(lbProcedure *p, lbValue u) {
	lbValue ptr = lb_address_from_load_or_generate_local(p, u);
	lbValue tag_ptr = lb_emit_union_tag_ptr(p, ptr);
	return lb_emit_load(p, tag_ptr);
}


gb_internal void lb_emit_store_union_variant_tag(lbProcedure *p, lbValue parent, Type *variant_type) {
	Type *t = type_deref(parent.type);
	GB_ASSERT(is_type_union(t));

	if (is_type_union_maybe_pointer(t) || type_size_of(t) == 0) {
		// No tag needed!
	} else {
		lbValue tag_ptr = lb_emit_union_tag_ptr(p, parent);
		lb_emit_store(p, tag_ptr, lb_const_union_tag(p->module, t, variant_type));
	}
}

gb_internal void lb_emit_store_union_variant(lbProcedure *p, lbValue parent, lbValue variant, Type *variant_type) {
	Type *pt = base_type(type_deref(parent.type));
	GB_ASSERT(pt->kind == Type_Union);
	if (pt->Union.kind == UnionType_shared_nil) {
		GB_ASSERT(type_size_of(variant_type));

		lbBlock *if_nil     = lb_create_block(p, "shared_nil.if_nil");
		lbBlock *if_not_nil = lb_create_block(p, "shared_nil.if_not_nil");
		lbBlock *done       = lb_create_block(p, "shared_nil.done");

		lbValue cond_is_nil = lb_emit_comp_against_nil(p, Token_CmpEq, variant);
		lb_emit_if(p, cond_is_nil, if_nil, if_not_nil);

		lb_start_block(p, if_nil);
		lb_emit_store(p, parent, lb_const_nil(p->module, type_deref(parent.type)));
		lb_emit_jump(p, done);

		lb_start_block(p, if_not_nil);
		lbValue underlying = lb_emit_conv(p, parent, alloc_type_pointer(variant_type));
		lb_emit_store(p, underlying, variant);
		lb_emit_store_union_variant_tag(p, parent, variant_type);
		lb_emit_jump(p, done);

		lb_start_block(p, done);


	} else {
		if (type_size_of(variant_type) == 0) {
			unsigned alignment = 1;
			lb_mem_zero_ptr_internal(p, parent.value, pt->Union.variant_block_size, alignment, false);
		} else {
			lbValue underlying = lb_emit_conv(p, parent, alloc_type_pointer(variant_type));
			lb_emit_store(p, underlying, variant);
		}
		lb_emit_store_union_variant_tag(p, parent, variant_type);
	}
}


gb_internal void lb_clone_struct_type(LLVMTypeRef dst, LLVMTypeRef src) {
	TEMPORARY_ALLOCATOR_GUARD();
	unsigned field_count = LLVMCountStructElementTypes(src);
	LLVMTypeRef *fields = gb_alloc_array(temporary_allocator(), LLVMTypeRef, field_count);
	LLVMGetStructElementTypes(src, fields);
	LLVMStructSetBody(dst, fields, field_count, LLVMIsPackedStruct(src));
}

gb_internal String lb_get_entity_name(lbModule *m, Entity *e) {
	GB_ASSERT(m != nullptr);
	GB_ASSERT(e != nullptr);
	if (e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len != 0) {
		return e->Procedure.link_name;
	}

	if (e->pkg == nullptr) {
		return e->token.string;
	}

	gbString w = string_canonical_entity_name(heap_allocator(), e);
	defer (gb_string_free(w));

	String name = copy_string(permanent_allocator(), make_string(cast(u8 const *)w, gb_string_length(w)));

	if (e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;
	} else if (e->kind == Entity_Procedure) {
		e->Procedure.link_name = name;
	} else if (e->kind == Entity_Variable) {
		e->Variable.link_name = name;
	}

	return name;
}


gb_internal LLVMTypeRef lb_type_internal_for_procedures_raw(lbModule *m, Type *type) {
	Type *original_type = type;
	type = base_type(original_type);
	GB_ASSERT(type->kind == Type_Proc);

	mutex_lock(&m->func_raw_types_mutex);
	defer (mutex_unlock(&m->func_raw_types_mutex));

	LLVMTypeRef *found = map_get(&m->func_raw_types, type);
	if (found) {
		return *found;
	}

	unsigned param_count = 0;

	if (type->Proc.param_count != 0) {
		GB_ASSERT(type->Proc.params->kind == Type_Tuple);
		for_array(i, type->Proc.params->Tuple.variables) {
			Entity *e = type->Proc.params->Tuple.variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}
			if (e->flags & EntityFlag_CVarArg) {
				continue;
			}
			param_count += 1;
		}
	}
	m->internal_type_level += 1;
	defer (m->internal_type_level -= 1);

	bool return_is_tuple = false;
	LLVMTypeRef ret = nullptr;
	LLVMTypeRef *params = gb_alloc_array(permanent_allocator(), LLVMTypeRef, param_count);
	bool *params_by_ptr = gb_alloc_array(permanent_allocator(), bool, param_count);
	if (type->Proc.result_count != 0) {
		Type *single_ret = reduce_tuple_to_single_type(type->Proc.results);
		if (is_type_proc(single_ret)) {
			single_ret = t_rawptr;
		}
		ret = lb_type(m, single_ret);
		if (is_type_tuple(single_ret)) {
			return_is_tuple = true;
		}
		if (is_type_boolean(single_ret) &&
		    is_calling_convention_none(type->Proc.calling_convention) &&
		    type_size_of(single_ret) <= 1) {
			ret = LLVMInt1TypeInContext(m->ctx);
		}
	}

	unsigned param_index = 0;
	if (type->Proc.param_count != 0) {
		GB_ASSERT(type->Proc.params->kind == Type_Tuple);
		for_array(i, type->Proc.params->Tuple.variables) {
			Entity *e = type->Proc.params->Tuple.variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}
			if (e->flags & EntityFlag_CVarArg) {
				continue;
			}
			Type *e_type = reduce_tuple_to_single_type(e->type);

			bool param_is_by_ptr = false;
			LLVMTypeRef param_type = nullptr;
			if (e->flags & EntityFlag_ByPtr) {
				// it will become a pointer afterwards by making it indirect
				param_type = lb_type(m, e_type);
				param_is_by_ptr = true;
			} else if (is_type_boolean(e_type) &&
			    type_size_of(e_type) <= 1) {
				param_type = LLVMInt1TypeInContext(m->ctx);
			} else {
				if (is_type_proc(e_type)) {
					param_type = lb_type(m, t_rawptr);
				} else {
					param_type = lb_type(m, e_type);
				}
			}

			params_by_ptr[param_index] = param_is_by_ptr;
			params[param_index++] = param_type;
		}
	}
	GB_ASSERT(param_index == param_count);
	lbFunctionType *ft = lb_get_abi_info(m, params, param_count, ret, ret != nullptr, return_is_tuple, type->Proc.calling_convention, type);
	{
		for_array(j, ft->args) {
			auto arg = ft->args[j];
			GB_ASSERT_MSG(LLVMGetTypeContext(arg.type) == ft->ctx,
			              "\n\t%s %td/%td"
			              "\n\tArgTypeCtx: %p\n\tCurrentCtx: %p\n\tGlobalCtx:  %p",
			              LLVMPrintTypeToString(arg.type),
			              j, ft->args.count,
			              LLVMGetTypeContext(arg.type), ft->ctx, LLVMGetGlobalContext());
		}
		GB_ASSERT_MSG(LLVMGetTypeContext(ft->ret.type) == ft->ctx,
		              "\n\t%s"
		              "\n\tRetTypeCtx: %p\n\tCurrentCtx: %p\n\tGlobalCtx:  %p",
		              LLVMPrintTypeToString(ft->ret.type),
		              LLVMGetTypeContext(ft->ret.type), ft->ctx, LLVMGetGlobalContext());
	}
	for (unsigned i = 0; i < param_count; i++) {
		if (params_by_ptr[i]) {
			// NOTE(bill): The parameter needs to be passed "indirectly", override it
			ft->args[i].kind = lbArg_Indirect;
			ft->args[i].attribute = nullptr;
			ft->args[i].align_attribute = nullptr;
			ft->args[i].byval_alignment = 0;
			ft->args[i].is_byval = false;
		}
	}

	map_set(&m->function_type_map, type, ft);
	LLVMTypeRef new_abi_fn_type = lb_function_type_to_llvm_raw(ft, type->Proc.c_vararg);

	GB_ASSERT_MSG(LLVMGetTypeContext(new_abi_fn_type) == m->ctx,
	              "\n\tFuncTypeCtx: %p\n\tCurrentCtx:  %p\n\tGlobalCtx:   %p",
	              LLVMGetTypeContext(new_abi_fn_type), m->ctx, LLVMGetGlobalContext());

	map_set(&m->func_raw_types, type, new_abi_fn_type);

	return new_abi_fn_type;

}
gb_internal LLVMTypeRef lb_type_internal(lbModule *m, Type *type) {
	LLVMContextRef ctx = m->ctx;
	i64 size = type_size_of(type); // Check size
	gb_unused(size);

	GB_ASSERT(type != t_invalid);

	bool bigger_int = build_context.ptr_size != build_context.int_size;

	switch (type->kind) {
	case Type_Basic:
		switch (type->Basic.kind) {
		case Basic_llvm_bool: return LLVMInt1TypeInContext(ctx);
		case Basic_bool:      return LLVMInt8TypeInContext(ctx);
		case Basic_b8:        return LLVMInt8TypeInContext(ctx);
		case Basic_b16:       return LLVMInt16TypeInContext(ctx);
		case Basic_b32:       return LLVMInt32TypeInContext(ctx);
		case Basic_b64:       return LLVMInt64TypeInContext(ctx);

		case Basic_i8:   return LLVMInt8TypeInContext(ctx);
		case Basic_u8:   return LLVMInt8TypeInContext(ctx);
		case Basic_i16:  return LLVMInt16TypeInContext(ctx);
		case Basic_u16:  return LLVMInt16TypeInContext(ctx);
		case Basic_i32:  return LLVMInt32TypeInContext(ctx);
		case Basic_u32:  return LLVMInt32TypeInContext(ctx);
		case Basic_i64:  return LLVMInt64TypeInContext(ctx);
		case Basic_u64:  return LLVMInt64TypeInContext(ctx);
		case Basic_i128: return LLVMInt128TypeInContext(ctx);
		case Basic_u128: return LLVMInt128TypeInContext(ctx);

		case Basic_rune: return LLVMInt32TypeInContext(ctx);


		case Basic_f16: return LLVMHalfTypeInContext(ctx);
		case Basic_f32: return LLVMFloatTypeInContext(ctx);
		case Basic_f64: return LLVMDoubleTypeInContext(ctx);

		case Basic_f16le: return LLVMHalfTypeInContext(ctx);
		case Basic_f32le: return LLVMFloatTypeInContext(ctx);
		case Basic_f64le: return LLVMDoubleTypeInContext(ctx);

		case Basic_f16be: return LLVMHalfTypeInContext(ctx);
		case Basic_f32be: return LLVMFloatTypeInContext(ctx);
		case Basic_f64be: return LLVMDoubleTypeInContext(ctx);

		case Basic_complex32:
			{
				char const *name = "..complex32";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				LLVMTypeRef fields[2] = {
					lb_type(m, t_f16),
					lb_type(m, t_f16),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}
		case Basic_complex64:
			{
				char const *name = "..complex64";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				LLVMTypeRef fields[2] = {
					lb_type(m, t_f32),
					lb_type(m, t_f32),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}
		case Basic_complex128:
			{
				char const *name = "..complex128";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				LLVMTypeRef fields[2] = {
					lb_type(m, t_f64),
					lb_type(m, t_f64),
				};
				LLVMStructSetBody(type, fields, 2, false);
				return type;
			}

		case Basic_quaternion64:
			{
				char const *name = "..quaternion64";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				LLVMTypeRef fields[4] = {
					lb_type(m, t_f16),
					lb_type(m, t_f16),
					lb_type(m, t_f16),
					lb_type(m, t_f16),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}
		case Basic_quaternion128:
			{
				char const *name = "..quaternion128";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				LLVMTypeRef fields[4] = {
					lb_type(m, t_f32),
					lb_type(m, t_f32),
					lb_type(m, t_f32),
					lb_type(m, t_f32),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}
		case Basic_quaternion256:
			{
				char const *name = "..quaternion256";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				LLVMTypeRef fields[4] = {
					lb_type(m, t_f64),
					lb_type(m, t_f64),
					lb_type(m, t_f64),
					lb_type(m, t_f64),
				};
				LLVMStructSetBody(type, fields, 4, false);
				return type;
			}

		case Basic_int:  return LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.int_size);
		case Basic_uint: return LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.int_size);

		case Basic_uintptr: return LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.ptr_size);

		case Basic_rawptr: return LLVMPointerType(LLVMInt8TypeInContext(ctx), 0);
		case Basic_string:
			{
				char const *name = "..string";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);

				if (build_context.metrics.ptr_size < build_context.metrics.int_size) {
					GB_ASSERT(build_context.metrics.ptr_size == 4);
					GB_ASSERT(build_context.metrics.int_size == 8);
					LLVMTypeRef fields[3] = {
						LLVMPointerType(lb_type(m, t_u8), 0),
						lb_type(m, t_i32),
						lb_type(m, t_int),
					};
					LLVMStructSetBody(type, fields, 3, false);
				} else {
					LLVMTypeRef fields[2] = {
						LLVMPointerType(lb_type(m, t_u8), 0),
						lb_type(m, t_int),
					};
					LLVMStructSetBody(type, fields, 2, false);
				}
				return type;
			}
		case Basic_cstring: return LLVMPointerType(LLVMInt8TypeInContext(ctx), 0);
		case Basic_any:
			{
				char const *name = "..any";
				LLVMTypeRef type = LLVMGetTypeByName(m->mod, name);
				if (type != nullptr) {
					return type;
				}
				type = LLVMStructCreateNamed(ctx, name);
				if (build_context.ptr_size == 4) {
					LLVMTypeRef fields[3] = {
						lb_type(m, t_rawptr),
						lb_type_padding_filler(m, build_context.ptr_size, build_context.ptr_size), // padding
						lb_type(m, t_typeid),
					};
					LLVMStructSetBody(type, fields, 3, false);
				} else {
					LLVMTypeRef fields[2] = {
						lb_type(m, t_rawptr),
						lb_type(m, t_typeid),
					};
					LLVMStructSetBody(type, fields, 2, false);
				}
				return type;
			}

		case Basic_typeid: return LLVMIntTypeInContext(m->ctx, 64);

		// Endian Specific Types
		case Basic_i16le:  return LLVMInt16TypeInContext(ctx);
		case Basic_u16le:  return LLVMInt16TypeInContext(ctx);
		case Basic_i32le:  return LLVMInt32TypeInContext(ctx);
		case Basic_u32le:  return LLVMInt32TypeInContext(ctx);
		case Basic_i64le:  return LLVMInt64TypeInContext(ctx);
		case Basic_u64le:  return LLVMInt64TypeInContext(ctx);
		case Basic_i128le: return LLVMInt128TypeInContext(ctx);
		case Basic_u128le: return LLVMInt128TypeInContext(ctx);

		case Basic_i16be:  return LLVMInt16TypeInContext(ctx);
		case Basic_u16be:  return LLVMInt16TypeInContext(ctx);
		case Basic_i32be:  return LLVMInt32TypeInContext(ctx);
		case Basic_u32be:  return LLVMInt32TypeInContext(ctx);
		case Basic_i64be:  return LLVMInt64TypeInContext(ctx);
		case Basic_u64be:  return LLVMInt64TypeInContext(ctx);
		case Basic_i128be: return LLVMInt128TypeInContext(ctx);
		case Basic_u128be: return LLVMInt128TypeInContext(ctx);

		// Untyped types
		case Basic_UntypedBool:       GB_PANIC("Basic_UntypedBool"); break;
		case Basic_UntypedInteger:    GB_PANIC("Basic_UntypedInteger"); break;
		case Basic_UntypedFloat:      GB_PANIC("Basic_UntypedFloat"); break;
		case Basic_UntypedComplex:    GB_PANIC("Basic_UntypedComplex"); break;
		case Basic_UntypedQuaternion: GB_PANIC("Basic_UntypedQuaternion"); break;
		case Basic_UntypedString:     GB_PANIC("Basic_UntypedString"); break;
		case Basic_UntypedRune:       GB_PANIC("Basic_UntypedRune"); break;
		case Basic_UntypedNil:        GB_PANIC("Basic_UntypedNil"); break;
		case Basic_UntypedUninit:     GB_PANIC("Basic_UntypedUninit"); break;
		}
		break;
	case Type_Named:
		{
			Type *base = base_type(type->Named.base);

			switch (base->kind) {
			case Type_Basic:
				return lb_type_internal(m, base);

			case Type_Named:
			case Type_Generic:
				GB_PANIC("INVALID TYPE");
				break;

			case Type_Pointer:
			case Type_Array:
			case Type_EnumeratedArray:
			case Type_Slice:
			case Type_DynamicArray:
			case Type_Map:
			case Type_Enum:
			case Type_BitSet:
			case Type_SimdVector:
				return lb_type_internal(m, base);

			case Type_Proc:
				// TODO(bill): Deal with this correctly. Can this be named?
				return lb_type_internal(m, base);

			case Type_Tuple:
				return lb_type_internal(m, base);
			}

			LLVMTypeRef *found = map_get(&m->types, base);
			if (found) {
				LLVMTypeKind kind = LLVMGetTypeKind(*found);
				if (kind == LLVMStructTypeKind) {
					char const *name = alloc_cstring(permanent_allocator(), lb_get_entity_name(m, type->Named.type_name));
					LLVMTypeRef llvm_type = LLVMGetTypeByName(m->mod, name);
					if (llvm_type != nullptr) {
						return llvm_type;
					}
					llvm_type = LLVMStructCreateNamed(ctx, name);
					LLVMTypeRef found_val = *found;
					map_set(&m->types, type, llvm_type);
					lb_clone_struct_type(llvm_type, found_val);
					return llvm_type;
				}
			}

			switch (base->kind) {
			case Type_Struct:
			case Type_Union:
				{
					char const *name = alloc_cstring(permanent_allocator(), lb_get_entity_name(m, type->Named.type_name));
					LLVMTypeRef llvm_type = LLVMGetTypeByName(m->mod, name);
					if (llvm_type != nullptr) {
						return llvm_type;
					}
					llvm_type = LLVMStructCreateNamed(ctx, name);
					map_set(&m->types, type, llvm_type);
					lb_clone_struct_type(llvm_type, lb_type(m, base));

					if (base->kind == Type_Struct) {
						map_set(&m->struct_field_remapping, cast(void *)llvm_type, lb_get_struct_remapping(m, base));
						map_set(&m->struct_field_remapping, cast(void *)type, lb_get_struct_remapping(m, base));
					}

					return llvm_type;
				}
			}


			return lb_type_internal(m, base);
		}

	case Type_Pointer:
		return LLVMPointerType(lb_type(m, type->Pointer.elem), 0);

	case Type_MultiPointer:
		return LLVMPointerType(lb_type(m, type->Pointer.elem), 0);

	case Type_Array: {
		m->internal_type_level += 1;
		LLVMTypeRef t = llvm_array_type(lb_type(m, type->Array.elem), type->Array.count);
		m->internal_type_level -= 1;
		return t;
	}

	case Type_EnumeratedArray: {
		m->internal_type_level += 1;
		LLVMTypeRef t = llvm_array_type(lb_type(m, type->EnumeratedArray.elem), type->EnumeratedArray.count);
		m->internal_type_level -= 1;
		return t;
	}

	case Type_Slice:
		{
			if (bigger_int) {
				LLVMTypeRef fields[3] = {
					LLVMPointerType(lb_type(m, type->Slice.elem), 0), // data
					lb_type_padding_filler(m, build_context.ptr_size, build_context.ptr_size), // padding
					lb_type(m, t_int), // len
				};
				return LLVMStructTypeInContext(ctx, fields, gb_count_of(fields), false);
			} else {
				LLVMTypeRef fields[2] = {
					LLVMPointerType(lb_type(m, type->Slice.elem), 0), // data
					lb_type(m, t_int), // len
				};
				return LLVMStructTypeInContext(ctx, fields, gb_count_of(fields), false);
			}
		}
		break;

	case Type_DynamicArray:
		{
			if (bigger_int) {
				LLVMTypeRef fields[5] = {
					LLVMPointerType(lb_type(m, type->DynamicArray.elem), 0), // data
					lb_type_padding_filler(m, build_context.ptr_size, build_context.ptr_size), // padding
					lb_type(m, t_int), // len
					lb_type(m, t_int), // cap
					lb_type(m, t_allocator), // allocator
				};
				return LLVMStructTypeInContext(ctx, fields, gb_count_of(fields), false);
			} else {
				LLVMTypeRef fields[4] = {
					LLVMPointerType(lb_type(m, type->DynamicArray.elem), 0), // data
					lb_type(m, t_int), // len
					lb_type(m, t_int), // cap
					lb_type(m, t_allocator), // allocator
				};
				return LLVMStructTypeInContext(ctx, fields, gb_count_of(fields), false);
			}
		}
		break;

	case Type_Map:
		init_map_internal_debug_types(type);
		GB_ASSERT(t_raw_map != nullptr);
		return lb_type_internal(m, t_raw_map);

	case Type_Struct:
		{
			type_set_offsets(type);

			i64 full_type_size = type_size_of(type);
			i64 full_type_align = type_align_of(type);
			GB_ASSERT(full_type_size % full_type_align == 0);

			if (type->Struct.is_raw_union) {

				lbStructFieldRemapping field_remapping = {};
				slice_init(&field_remapping, permanent_allocator(), 1);

				LLVMTypeRef fields[1] = {};
				fields[0] = lb_type_padding_filler(m, full_type_size, full_type_align);
				field_remapping[0] = 0;

				LLVMTypeRef struct_type = LLVMStructTypeInContext(ctx, fields, gb_count_of(fields), false);
				map_set(&m->struct_field_remapping, cast(void *)struct_type, field_remapping);
				map_set(&m->struct_field_remapping, cast(void *)type, field_remapping);
				return struct_type;
			}

			lbStructFieldRemapping field_remapping = {};
			slice_init(&field_remapping, permanent_allocator(), type->Struct.fields.count);

			m->internal_type_level += 1;
			defer (m->internal_type_level -= 1);

			auto fields = array_make<LLVMTypeRef>(temporary_allocator(), 0, type->Struct.fields.count*2 + 2);
			if (are_struct_fields_reordered(type)) {
				// NOTE(bill, 2021-10-02): Minor hack to enforce `llvm_const_named_struct` usage correctly
				LLVMTypeRef padding_type = lb_type_padding_filler(m, 0, type_align_of(type));
				array_add(&fields, padding_type);
			}

			i64 prev_offset = 0;
			bool requires_packing = type->Struct.is_packed;
			for (i32 field_index : struct_fields_index_by_increasing_offset(temporary_allocator(), type)) {
				Entity *field = type->Struct.fields[field_index];
				i64 offset = type->Struct.offsets[field_index];
				GB_ASSERT(offset >= prev_offset);

				i64 padding = offset - prev_offset;
				if (padding != 0) {
					LLVMTypeRef padding_type = lb_type_padding_filler(m, padding, type_align_of(field->type));
					array_add(&fields, padding_type);
				}

				field_remapping[field_index] = cast(i32)fields.count;

				Type *field_type = field->type;
				if (is_type_proc(field_type)) {
					// NOTE(bill, 2022-11-23): Prevent type cycle declaration (e.g. vtable) of procedures
					// because LLVM is dumb with procedure types
					field_type = t_rawptr;
				}

				// max_field_align might misalign items in a way that requires packing
				// so check the alignment of all fields to see if packing is required.
				requires_packing = requires_packing || ((offset % type_align_of(field_type)) != 0);

				array_add(&fields, lb_type(m, field_type));

				prev_offset = offset + type_size_of(field->type);
			}

			i64 end_padding = full_type_size-prev_offset;
			if (end_padding > 0) {
				array_add(&fields, lb_type_padding_filler(m, end_padding, 1));
			}

			for_array(i, fields) {
				GB_ASSERT(fields[i] != nullptr);
			}

			LLVMTypeRef struct_type = LLVMStructTypeInContext(ctx, fields.data, cast(unsigned)fields.count, requires_packing);
			map_set(&m->struct_field_remapping, cast(void *)struct_type, field_remapping);
			map_set(&m->struct_field_remapping, cast(void *)type, field_remapping);
			#if 0
			GB_ASSERT_MSG(lb_sizeof(struct_type) == full_type_size,
			              "(%lld) %s vs (%lld) %s",
			              cast(long long)lb_sizeof(struct_type), LLVMPrintTypeToString(struct_type),
			              cast(long long)full_type_size, type_to_string(type));
			#endif
			return struct_type;
		}
		break;

	case Type_Union:
		if (type->Union.variants.count == 0) {
			return LLVMStructTypeInContext(ctx, nullptr, 0, false);
		} else {
			// NOTE(bill): The zero size array is used to fix the alignment used in a structure as
			// LLVM takes the first element's alignment as the entire alignment (like C)
			i64 align = type_align_of(type);
			i64 size = type_size_of(type);
			gb_unused(size);

			if (is_type_union_maybe_pointer_original_alignment(type)) {
				LLVMTypeRef fields[] = {lb_type(m, type->Union.variants[0])};
				return LLVMStructTypeInContext(ctx, fields, gb_count_of(fields), false);
			}

			unsigned block_size = cast(unsigned)type->Union.variant_block_size;

			auto fields = array_make<LLVMTypeRef>(temporary_allocator(), 0, 3);
			if (is_type_union_maybe_pointer(type)) {
				LLVMTypeRef variant = lb_type(m, type->Union.variants[0]);
				array_add(&fields, variant);
			} else {
				LLVMTypeRef block_type = nullptr;

				bool all_pointers = align == build_context.ptr_size;
				for (isize i = 0; all_pointers && i < type->Union.variants.count; i++) {
					Type *t = type->Union.variants[i];
					if (!is_type_internally_pointer_like(t)) {
						all_pointers = false;
					}
				}
				if (all_pointers) {
					block_type = lb_type(m, t_rawptr);
				} else {
					block_type = lb_type_padding_filler(m, block_size, align);
				}

				LLVMTypeRef tag_type = lb_type(m, union_tag_type(type));
				array_add(&fields, block_type);
				array_add(&fields, tag_type);
				i64 used_size = lb_sizeof(block_type) + lb_sizeof(tag_type);
				i64 padding = size - used_size;
				if (padding > 0) {
					LLVMTypeRef padding_type = lb_type_padding_filler(m, padding, align);
					array_add(&fields, padding_type);
				}
			}
			
			return LLVMStructTypeInContext(ctx, fields.data, cast(unsigned)fields.count, false);
		}
		break;

	case Type_Enum:
		return lb_type(m, base_enum_type(type));

	case Type_Tuple:
		if (type->Tuple.variables.count == 1) {
			return lb_type(m, type->Tuple.variables[0]->type);
		} else {
			m->internal_type_level += 1;
			defer (m->internal_type_level -= 1);
			
			unsigned field_count = cast(unsigned)(type->Tuple.variables.count);
			LLVMTypeRef *fields = gb_alloc_array(temporary_allocator(), LLVMTypeRef, field_count);

			for_array(i, type->Tuple.variables) {
				Entity *field = type->Tuple.variables[i];

				LLVMTypeRef param_type = nullptr;
				param_type = lb_type(m, field->type);

				fields[i] = param_type;
			}

			return LLVMStructTypeInContext(ctx, fields, field_count, type->Tuple.is_packed);
		}

	case Type_Proc:
		{
			LLVMTypeRef proc_raw_type = lb_type_internal_for_procedures_raw(m, type);
			gb_unused(proc_raw_type);
			return LLVMPointerType(LLVMIntTypeInContext(m->ctx, 8), 0);
		}
		break;
	case Type_BitSet:
		{
			Type *ut = bit_set_to_int(type);
			return lb_type(m, ut);
		}

	case Type_SimdVector:
		return LLVMVectorType(lb_type(m, type->SimdVector.elem), cast(unsigned)type->SimdVector.count);
		
	case Type_Matrix:
		{
			i64 size = type_size_of(type);
			i64 elem_size = type_size_of(type->Matrix.elem);
			GB_ASSERT(elem_size > 0);
			i64 elem_count = size/elem_size;
			GB_ASSERT_MSG(elem_count > 0, "%s", type_to_string(type));
			
			m->internal_type_level -= 1;
			
			LLVMTypeRef elem = lb_type(m, type->Matrix.elem);
			LLVMTypeRef t = llvm_array_type(elem, elem_count);
			
			m->internal_type_level += 1;
			return t;
		}

	case Type_SoaPointer:
		{
			unsigned field_count = 2;
			if (bigger_int) {
				field_count = 3;
			}
			LLVMTypeRef *fields = gb_alloc_array(permanent_allocator(), LLVMTypeRef, field_count);
			fields[0] = LLVMPointerType(lb_type(m, type->Pointer.elem), 0);
			if (bigger_int) {
				fields[1] = lb_type_padding_filler(m, build_context.ptr_size, build_context.ptr_size);
				fields[2] = LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.int_size);
			} else {
				fields[1] = LLVMIntTypeInContext(ctx, 8*cast(unsigned)build_context.int_size);
			}
			return LLVMStructTypeInContext(ctx, fields, field_count, false);
		}

	case Type_BitField:
		return lb_type_internal(m, type->BitField.backing_type);
	}

	GB_PANIC("Invalid type %s", type_to_string(type));
	return LLVMInt32TypeInContext(ctx);
}

gb_internal LLVMTypeRef lb_type(lbModule *m, Type *type) {
	type = default_type(type);

	mutex_lock(&m->types_mutex);
	defer (mutex_unlock(&m->types_mutex));

	LLVMTypeRef *found = map_get(&m->types, type);
	if (found) {
		return *found;
	}

	LLVMTypeRef llvm_type = nullptr;

	m->internal_type_level += 1;
	llvm_type = lb_type_internal(m, type);
	m->internal_type_level -= 1;
	if (m->internal_type_level == 0) {
		map_set(&m->types, type, llvm_type);
	}
	return llvm_type;
}

gb_internal lbFunctionType *lb_get_function_type(lbModule *m, Type *pt) {
	lbFunctionType **ft_found = nullptr;
	ft_found = map_get(&m->function_type_map, pt);
	if (!ft_found) {
		LLVMTypeRef llvm_proc_type = lb_type(m, pt);
		gb_unused(llvm_proc_type);
		ft_found = map_get(&m->function_type_map, pt);
	}
	GB_ASSERT(ft_found != nullptr);

	return *ft_found;
}

gb_internal void lb_ensure_abi_function_type(lbModule *m, lbProcedure *p) {
	if (p->abi_function_type != nullptr) {
		return;
	}
	lbFunctionType **ft_found = map_get(&m->function_type_map, p->type);
	if (ft_found == nullptr) {
		LLVMTypeRef llvm_proc_type = lb_type(p->module, p->type);
		gb_unused(llvm_proc_type);
		ft_found = map_get(&m->function_type_map, p->type);
	}
	GB_ASSERT(ft_found != nullptr);
	p->abi_function_type = *ft_found;
	GB_ASSERT(p->abi_function_type != nullptr);
}

gb_internal void lb_add_entity(lbModule *m, Entity *e, lbValue val) {
	if (e != nullptr) {
		rw_mutex_lock(&m->values_mutex);
		map_set(&m->values, e, val);
		rw_mutex_unlock(&m->values_mutex);
	}
}
gb_internal void lb_add_member(lbModule *m, String const &name, lbValue val) {
	if (name.len > 0) {
		rw_mutex_lock(&m->values_mutex);
		string_map_set(&m->members, name, val);
		rw_mutex_unlock(&m->values_mutex);
	}
}
gb_internal void lb_add_procedure_value(lbModule *m, lbProcedure *p) {
	rw_mutex_lock(&m->values_mutex);
	if (p->entity != nullptr) {
		map_set(&m->procedure_values, p->value, p->entity);
	}
	string_map_set(&m->procedures, p->name, p);
	rw_mutex_unlock(&m->values_mutex);
}



gb_internal LLVMAttributeRef lb_create_enum_attribute_with_type(LLVMContextRef ctx, char const *name, LLVMTypeRef type) {
	unsigned kind = 0;
	String s = make_string_c(name);

	#if ODIN_LLVM_MINIMUM_VERSION_12
		kind = LLVMGetEnumAttributeKindForName(name, s.len);
		GB_ASSERT_MSG(kind != 0, "unknown attribute: %s", name);
		return LLVMCreateTypeAttribute(ctx, kind, type);
	#else
		// NOTE(2021-02-25, bill); All this attributes require a type associated with them
		// and the current LLVM C API does not expose this functionality yet.
		// It is better to ignore the attributes for the time being
		if (s == "byval") {
			// return nullptr;
		} else if (s == "byref") {
			return nullptr;
		} else if (s == "preallocated") {
			return nullptr;
		} else if (s == "sret") {
			// return nullptr;
		}
		

		kind = LLVMGetEnumAttributeKindForName(name, s.len);
		GB_ASSERT_MSG(kind != 0, "unknown attribute: %s", name);
		return LLVMCreateEnumAttribute(ctx, kind, 0);
	#endif	
}

gb_internal LLVMAttributeRef lb_create_enum_attribute(LLVMContextRef ctx, char const *name, u64 value) {
	String s = make_string_c(name);

	// NOTE(2021-02-25, bill); All this attributes require a type associated with them
	// and the current LLVM C API does not expose this functionality yet.
	// It is better to ignore the attributes for the time being
	if (s == "byval") {
		GB_PANIC("lb_create_enum_attribute_with_type should be used for %s", name);
	} else if (s == "byref") {
		GB_PANIC("lb_create_enum_attribute_with_type should be used for %s", name);
	} else if (s == "preallocated") {
		GB_PANIC("lb_create_enum_attribute_with_type should be used for %s", name);
	} else if (s == "sret") {
		GB_PANIC("lb_create_enum_attribute_with_type should be used for %s", name);
	}

	unsigned kind = LLVMGetEnumAttributeKindForName(name, s.len);
	GB_ASSERT_MSG(kind != 0, "unknown attribute: %s", name);
	return LLVMCreateEnumAttribute(ctx, kind, value);
}

gb_internal LLVMAttributeRef lb_create_string_attribute(LLVMContextRef ctx, String const &key, String const &value) {
	LLVMAttributeRef attr = LLVMCreateStringAttribute(
		ctx,
		cast(char const *)key.text,   cast(unsigned)key.len,
		cast(char const *)value.text, cast(unsigned)value.len);
	return attr;
}


gb_internal void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name, u64 value) {
	LLVMAttributeRef attr = lb_create_enum_attribute(p->module->ctx, name, value);
	GB_ASSERT(attr != nullptr);
	LLVMAddAttributeAtIndex(p->value, cast(unsigned)index, attr);
}

gb_internal void lb_add_proc_attribute_at_index(lbProcedure *p, isize index, char const *name) {
	lb_add_proc_attribute_at_index(p, index, name, 0);
}

gb_internal void lb_add_attribute_to_proc(lbModule *m, LLVMValueRef proc_value, char const *name, u64 value=0) {
	LLVMAddAttributeAtIndex(proc_value, LLVMAttributeIndex_FunctionIndex, lb_create_enum_attribute(m->ctx, name, value));
}

gb_internal bool lb_proc_has_attribute(lbModule *m, LLVMValueRef proc_value, char const *name) {
	LLVMAttributeRef ref = LLVMGetEnumAttributeAtIndex(proc_value, LLVMAttributeIndex_FunctionIndex, LLVMGetEnumAttributeKindForName(name, gb_strlen(name)));
	return ref != nullptr;
}

gb_internal void lb_add_attribute_to_proc_with_string(lbModule *m, LLVMValueRef proc_value, String const &name, String const &value) {
	LLVMAttributeRef attr = lb_create_string_attribute(m->ctx, name, value);
	LLVMAddAttributeAtIndex(proc_value, LLVMAttributeIndex_FunctionIndex, attr);
}



gb_internal void lb_add_edge(lbBlock *from, lbBlock *to) {
	LLVMValueRef instr = LLVMGetLastInstruction(from->block);
	if (instr == nullptr || !LLVMIsATerminatorInst(instr)) {
		array_add(&from->succs, to);
		array_add(&to->preds, from);
	}
}


gb_internal lbBlock *lb_create_block(lbProcedure *p, char const *name, bool append) {
	lbBlock *b = gb_alloc_item(permanent_allocator(), lbBlock);
	b->block = LLVMCreateBasicBlockInContext(p->module->ctx, name);
	b->appended = false;
	if (append) {
		b->appended = true;
		LLVMAppendExistingBasicBlock(p->value, b->block);
	}

	b->scope = p->curr_scope;
	b->scope_index = p->scope_index;

	b->preds.allocator = heap_allocator();
	b->succs.allocator = heap_allocator();

	array_add(&p->blocks, b);

	return b;
}

gb_internal void lb_emit_jump(lbProcedure *p, lbBlock *target_block) {
	if (p->curr_block == nullptr) {
		return;
	}
	LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
	if (last_instr != nullptr && LLVMIsATerminatorInst(last_instr)) {
		return;
	}

	lb_add_edge(p->curr_block, target_block);
	LLVMBuildBr(p->builder, target_block->block);
	p->curr_block = nullptr;
}

gb_internal void lb_emit_if(lbProcedure *p, lbValue cond, lbBlock *true_block, lbBlock *false_block) {
	lbBlock *b = p->curr_block;
	if (b == nullptr) {
		return;
	}
	LLVMValueRef last_instr = LLVMGetLastInstruction(p->curr_block->block);
	if (last_instr != nullptr && LLVMIsATerminatorInst(last_instr)) {
		return;
	}

	lb_add_edge(b, true_block);
	lb_add_edge(b, false_block);

	LLVMValueRef cv = cond.value;
	cv = LLVMBuildTruncOrBitCast(p->builder, cv, lb_type(p->module, t_llvm_bool), "");
	LLVMBuildCondBr(p->builder, cv, true_block->block, false_block->block);
}


gb_internal gb_inline LLVMTypeRef OdinLLVMGetInternalElementType(LLVMTypeRef type) {
	return LLVMGetElementType(type);
}
gb_internal LLVMTypeRef OdinLLVMGetArrayElementType(LLVMTypeRef type) {
	GB_ASSERT(lb_is_type_kind(type, LLVMArrayTypeKind));
	return OdinLLVMGetInternalElementType(type);
}
gb_internal LLVMTypeRef OdinLLVMGetVectorElementType(LLVMTypeRef type) {
	GB_ASSERT(lb_is_type_kind(type, LLVMVectorTypeKind));
	return OdinLLVMGetInternalElementType(type);
}


gb_internal LLVMValueRef OdinLLVMBuildTransmute(lbProcedure *p, LLVMValueRef val, LLVMTypeRef dst_type) {
	LLVMContextRef ctx = p->module->ctx;
	LLVMTypeRef src_type = LLVMTypeOf(val);

	if (src_type == dst_type) {
		return val;
	}

	i64 src_size = lb_sizeof(src_type);
	i64 dst_size = lb_sizeof(dst_type);
	i64 src_align = lb_alignof(src_type);
	i64 dst_align = lb_alignof(dst_type);
	if (LLVMIsALoadInst(val)) {
		src_align = gb_min(src_align, LLVMGetAlignment(val));
	}

	LLVMTypeKind src_kind = LLVMGetTypeKind(src_type);
	LLVMTypeKind dst_kind = LLVMGetTypeKind(dst_type);

	if (dst_type == LLVMInt1TypeInContext(ctx)) {
		GB_ASSERT(lb_is_type_kind(src_type, LLVMIntegerTypeKind));
		return LLVMBuildICmp(p->builder, LLVMIntNE, val, LLVMConstNull(src_type), "");
	} else if (src_type == LLVMInt1TypeInContext(ctx)) {
		GB_ASSERT(lb_is_type_kind(src_type, LLVMIntegerTypeKind));
		return LLVMBuildZExtOrBitCast(p->builder, val, dst_type, "");
	}

	if (src_size != dst_size) {
		if ((lb_is_type_kind(src_type, LLVMVectorTypeKind) ^ lb_is_type_kind(dst_type, LLVMVectorTypeKind))) {
			// Okay
		} else {
			goto general_end;
		}
	}


	if (src_kind == dst_kind) {
		if (src_kind == LLVMPointerTypeKind) {
			return LLVMBuildPointerCast(p->builder, val, dst_type, "");
		} else if (src_kind == LLVMArrayTypeKind) {
			// ignore
		} else if (src_kind != LLVMStructTypeKind) {
			return LLVMBuildBitCast(p->builder, val, dst_type, "");
		}
	} else {
		if (src_kind == LLVMPointerTypeKind && dst_kind == LLVMIntegerTypeKind) {
			return LLVMBuildPtrToInt(p->builder, val, dst_type, "");
		} else if (src_kind == LLVMIntegerTypeKind && dst_kind == LLVMPointerTypeKind) {
			return LLVMBuildIntToPtr(p->builder, val, dst_type, "");
		}
	}

general_end:;
	// make the alignment big if necessary
	if (LLVMIsALoadInst(val) && src_align < dst_align) {
		LLVMValueRef val_ptr = LLVMGetOperand(val, 0);
		if (LLVMGetInstructionOpcode(val_ptr) == LLVMAlloca) {
			src_align = gb_max(LLVMGetAlignment(val_ptr), dst_align);
			LLVMSetAlignment(val_ptr, cast(unsigned)src_align);
		}
	}

	src_size = align_formula(src_size, src_align);
	dst_size = align_formula(dst_size, dst_align);

	if (LLVMIsALoadInst(val) && (src_size >= dst_size && src_align >= dst_align)) {
		LLVMValueRef val_ptr = LLVMGetOperand(val, 0);
		val_ptr = LLVMBuildPointerCast(p->builder, val_ptr, LLVMPointerType(dst_type, 0), "");
		LLVMValueRef loaded_val = OdinLLVMBuildLoad(p, dst_type, val_ptr);

		// LLVMSetAlignment(loaded_val, gb_min(src_align, dst_align));

		return loaded_val;
	} else {
		GB_ASSERT(p->decl_block != p->curr_block);

		i64 max_align = gb_max(lb_alignof(src_type), lb_alignof(dst_type));
		max_align = gb_max(max_align, 16);

		LLVMValueRef ptr = llvm_alloca(p, dst_type, max_align);

		LLVMValueRef nptr = LLVMBuildPointerCast(p->builder, ptr, LLVMPointerType(src_type, 0), "");
		LLVMBuildStore(p->builder, val, nptr);

		return OdinLLVMBuildLoad(p, dst_type, ptr);
	}
}



gb_internal LLVMValueRef lb_find_or_add_entity_string_ptr(lbModule *m, String const &str, bool custom_link_section) {
	StringHashKey key = {};
	LLVMValueRef *found = nullptr;

	if (!custom_link_section) {
		key = string_hash_string(str);
		found = string_map_get(&m->const_strings, key);
	}
	if (found != nullptr) {
		return *found;
	} else {
		LLVMValueRef indices[2] = {llvm_zero(m), llvm_zero(m)};
		LLVMValueRef data = LLVMConstStringInContext(m->ctx,
			cast(char const *)str.text,
			cast(unsigned)str.len,
			false);


		u32 id = m->global_array_index.fetch_add(1);
		gbString name = gb_string_make(temporary_allocator(), "csbs$");
		name = gb_string_appendc(name, m->module_name);
		name = gb_string_append_fmt(name, "$%x", id);

		LLVMTypeRef type = LLVMTypeOf(data);
		LLVMValueRef global_data = LLVMAddGlobal(m->mod, type, name);
		LLVMSetInitializer(global_data, data);
		lb_make_global_private_const(global_data);
		LLVMSetAlignment(global_data, 1);

		LLVMValueRef ptr = LLVMConstInBoundsGEP2(type, global_data, indices, 2);
		if (!custom_link_section) {
			string_map_set(&m->const_strings, key, ptr);
		}
		return ptr;
	}
}

gb_internal lbValue lb_find_or_add_entity_string(lbModule *m, String const &str, bool custom_link_section) {
	LLVMValueRef ptr = nullptr;
	if (str.len != 0) {
		ptr = lb_find_or_add_entity_string_ptr(m, str, custom_link_section);
	} else {
		ptr = LLVMConstNull(lb_type(m, t_u8_ptr));
	}
	LLVMValueRef str_len = LLVMConstInt(lb_type(m, t_int), str.len, true);

	lbValue res = {};
	res.value = llvm_const_string_internal(m, t_string, ptr, str_len);
	res.type = t_string;
	return res;
}

gb_internal lbValue lb_find_or_add_entity_string_byte_slice_with_type(lbModule *m, String const &str, Type *slice_type) {
	GB_ASSERT(is_type_slice(slice_type));
	LLVMValueRef indices[2] = {llvm_zero(m), llvm_zero(m)};
	LLVMValueRef data = LLVMConstStringInContext(m->ctx,
		cast(char const *)str.text,
		cast(unsigned)str.len,
		false);


	u32 id = m->global_array_index.fetch_add(1);
	gbString name = gb_string_make(temporary_allocator(), "csba$");
	name = gb_string_appendc(name, m->module_name);
	name = gb_string_append_fmt(name, "$%x", id);

	LLVMTypeRef type = LLVMTypeOf(data);
	LLVMValueRef global_data = LLVMAddGlobal(m->mod, type, name);
	LLVMSetInitializer(global_data, data);
	lb_make_global_private_const(global_data);
	LLVMSetAlignment(global_data, 1);

	i64 data_len = str.len;
	LLVMValueRef ptr = nullptr;
	if (data_len != 0) {
		ptr = LLVMConstInBoundsGEP2(type, global_data, indices, 2);
	} else {
		ptr = LLVMConstNull(lb_type(m, t_u8_ptr));
	}
	if (!is_type_u8_slice(slice_type)) {
		Type *bt = base_type(slice_type);
		Type *elem = bt->Slice.elem;
		i64 sz = type_size_of(elem);
		GB_ASSERT(sz > 0);
		ptr = LLVMConstPointerCast(ptr, lb_type(m, alloc_type_pointer(elem)));
		data_len /= sz;
	}

	LLVMValueRef len = LLVMConstInt(lb_type(m, t_int), data_len, true);
	LLVMValueRef values[2] = {ptr, len};

	lbValue res = {};
	res.value = llvm_const_named_struct(m, slice_type, values, 2);
	res.type = slice_type;
	return res;
}



gb_internal lbValue lb_find_ident(lbProcedure *p, lbModule *m, Entity *e, Ast *expr) {
	if (e->flags & EntityFlag_Param) {
		// NOTE(bill): Bypass the stack copied variable for
		// direct parameters as there is no need for the direct load
		auto *found = map_get(&p->direct_parameters, e);
		if (found) {
			return *found;
		}
	}

	lbValue *found = nullptr;
	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);

	if (found) {

		auto v = *found;
		// NOTE(bill): This is because pointers are already pointers in LLVM
		if (is_type_proc(v.type)) {
			return v;
		}
		return lb_emit_load(p, v);
	} else if (e != nullptr && e->kind == Entity_Variable) {
		return lb_addr_load(p, lb_build_addr(p, expr));
	}

	if (e->kind == Entity_Procedure) {
		return lb_find_procedure_value_from_entity(m, e);
	}
	if (USE_SEPARATE_MODULES) {
		lbModule *other_module = lb_module_of_entity(m->gen, e);
		if (other_module != m) {
			String name = lb_get_entity_name(other_module, e);

			lb_set_entity_from_other_modules_linkage_correctly(other_module, e, name);

			lbValue g = {};
			g.value = LLVMAddGlobal(m->mod, lb_type(m, e->type), alloc_cstring(permanent_allocator(), name));
			g.type = alloc_type_pointer(e->type);
			LLVMSetLinkage(g.value, LLVMExternalLinkage);

			lb_add_entity(m, e, g);
			lb_add_member(m, name, g);
			return lb_emit_load(p, g);
		}
	}

	String pkg = {};
	if (e->pkg) {
		pkg = e->pkg->name;
	}
	gb_printf_err("Error in: %s\n", token_pos_to_string(ast_token(expr).pos));
	GB_PANIC("nullptr value for expression from identifier: %.*s.%.*s (%p) : %s @ %p", LIT(pkg), LIT(e->token.string), e, type_to_string(e->type), expr);
	return {};
}


gb_internal lbValue lb_find_procedure_value_from_entity(lbModule *m, Entity *e) {
	lbGenerator *gen = m->gen;

	GB_ASSERT(is_type_proc(e->type));
	e = strip_entity_wrapping(e);
	GB_ASSERT(e != nullptr);
	GB_ASSERT(e->kind == Entity_Procedure);

	lbValue *found = nullptr;
	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);
	if (found) {
		return *found;
	}

	bool ignore_body = false;

	lbModule *other_module = m;
	if (USE_SEPARATE_MODULES) {
		other_module = lb_module_of_entity(gen, e);
	}
	if (other_module == m) {
		debugf("Missing Procedure (lb_find_procedure_value_from_entity): %.*s module %p\n", LIT(e->token.string), m);
	}
	ignore_body = other_module != m;

	lbProcedure *missing_proc = lb_create_procedure(m, e, ignore_body);
	if (ignore_body) {
		mutex_lock(&gen->anonymous_proc_lits_mutex);
		defer (mutex_unlock(&gen->anonymous_proc_lits_mutex));

		GB_ASSERT(other_module != nullptr);
		rw_mutex_shared_lock(&other_module->values_mutex);
		auto *found = map_get(&other_module->values, e);
		rw_mutex_shared_unlock(&other_module->values_mutex);
		if (found == nullptr) {
			// THIS IS THE RACE CONDITION
			lbProcedure *missing_proc_in_other_module = lb_create_procedure(other_module, e, false);
			array_add(&other_module->missing_procedures_to_check, missing_proc_in_other_module);
		}
	} else {
		array_add(&m->missing_procedures_to_check, missing_proc);
	}

	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);
	if (found) {
		return *found;
	}

	GB_PANIC("Error in: %s, missing procedure %.*s\n", token_pos_to_string(e->token.pos), LIT(e->token.string));
	return {};
}



gb_internal lbValue lb_generate_anonymous_proc_lit(lbModule *m, String const &prefix_name, Ast *expr, lbProcedure *parent) {
	lbGenerator *gen = m->gen;

	mutex_lock(&gen->anonymous_proc_lits_mutex);
	defer (mutex_unlock(&gen->anonymous_proc_lits_mutex));

	TokenPos pos = ast_token(expr).pos;
	lbProcedure **found = map_get(&gen->anonymous_proc_lits, expr);
	if (found) {
		return lb_find_procedure_value_from_entity(m, (*found)->entity);
	}

	ast_node(pl, ProcLit, expr);

	// NOTE(bill): Generate a new name
	// parent$count
	isize name_len = prefix_name.len + 6 + 11;
	char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
	static std::atomic<i32> name_id;
	name_len = gb_snprintf(name_text, name_len, "%.*s$anon-%d", LIT(prefix_name), 1+name_id.fetch_add(1));
	String name = make_string((u8 *)name_text, name_len-1);

	Type *type = type_of_expr(expr);

	GB_ASSERT(pl->decl->entity == nullptr);
	Token token = {};
	token.pos = ast_token(expr).pos;
	token.kind = Token_Ident;
	token.string = name;
	Entity *e = alloc_entity_procedure(nullptr, token, type, pl->tags);
	e->file = expr->file();

	// NOTE(bill): this is to prevent a race condition since these procedure literals can be created anywhere at any time
	pl->decl->code_gen_module = m;
	e->decl_info = pl->decl;
	pl->decl->entity = e;
	e->parent_proc_decl = pl->decl->parent;
	e->Procedure.is_anonymous = true;
	e->flags |= EntityFlag_ProcBodyChecked;

	lbProcedure *p = lb_create_procedure(m, e);
	GB_ASSERT(e->code_gen_module == m);

	lbValue value = {};
	value.value = p->value;
	value.type = p->type;

	map_set(&gen->anonymous_proc_lits, expr, p);
	array_add(&m->procedures_to_generate, p);
	if (parent != nullptr) {
		array_add(&parent->children, p);
	} else {
		string_map_set(&m->members, name, value);
	}
	return value;
}


gb_internal lbAddr lb_add_global_generated_with_name(lbModule *m, Type *type, lbValue value, String name, Entity **entity_) {
	GB_ASSERT(name.len != 0);
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	Scope *scope = nullptr;
	Entity *e = alloc_entity_variable(scope, make_token_ident(name), type);
	lbValue g = {};
	g.type = alloc_type_pointer(type);
	g.value = LLVMAddGlobal(m->mod, lb_type(m, type), alloc_cstring(temporary_allocator(), name));
	if (value.value != nullptr) {
		GB_ASSERT_MSG(LLVMIsConstant(value.value), LLVMPrintValueToString(value.value));
		LLVMSetInitializer(g.value, value.value);
	} else {
		LLVMSetInitializer(g.value, LLVMConstNull(lb_type(m, type)));
	}

	lb_add_entity(m, e, g);
	lb_add_member(m, name, g);

	if (entity_) *entity_ = e;

	return lb_addr(g);
}


gb_internal lbAddr lb_add_global_generated_from_procedure(lbProcedure *p, Type *type, lbValue value) {
	GB_ASSERT(type != nullptr);
	type = default_type(type);

	u32 index = ++p->global_generated_index;

	gbString s = gb_string_make(temporary_allocator(), "ggv$");
	// s = gb_string_appendc(s, p->module->module_name);
	// s = gb_string_appendc(s, "$");
	s = gb_string_append_length(s, p->name.text, p->name.len);
	s = gb_string_append_fmt(s, "$%u", index);

	String name = make_string(cast(u8 const *)s, gb_string_length(s));
	return lb_add_global_generated_with_name(p->module, type, value, name);
}



gb_internal lbValue lb_find_runtime_value(lbModule *m, String const &name) {
	AstPackage *p = m->info->runtime_package;
	Entity *e = scope_lookup_current(p->scope, name);
	return lb_find_value_from_entity(m, e);
}
gb_internal lbValue lb_find_package_value(lbModule *m, String const &pkg, String const &name) {
	Entity *e = find_entity_in_pkg(m->info, pkg, name);
	return lb_find_value_from_entity(m, e);
}

gb_internal lbValue lb_generate_local_array(lbProcedure *p, Type *elem_type, i64 count, bool zero_init) {
	lbAddr addr = lb_add_local_generated(p, alloc_type_array(elem_type, count), zero_init);
	return lb_addr_get_ptr(p, addr);
}


gb_internal lbValue lb_find_value_from_entity(lbModule *m, Entity *e) {
	e = strip_entity_wrapping(e);
	GB_ASSERT(e != nullptr);

	GB_ASSERT(e->token.string != "_");

	if (e->kind == Entity_Procedure) {
		return lb_find_procedure_value_from_entity(m, e);
	}

	lbValue *found = nullptr;
	rw_mutex_shared_lock(&m->values_mutex);
	found = map_get(&m->values, e);
	rw_mutex_shared_unlock(&m->values_mutex);
	if (found) {
		return *found;
	}

	if (USE_SEPARATE_MODULES) {
		lbModule *other_module = lb_module_of_entity(m->gen, e);

		bool is_external = other_module != m;
		if (!is_external) {
			if (e->code_gen_module != nullptr) {
				other_module = e->code_gen_module;
			} else {
				other_module = &m->gen->default_module;
			}
			is_external = other_module != m;
		}

		if (is_external) {
			String name = lb_get_entity_name(other_module, e);

			lbValue g = {};
			g.value = LLVMAddGlobal(m->mod, lb_type(m, e->type), alloc_cstring(permanent_allocator(), name));
			g.type = alloc_type_pointer(e->type);
			lb_add_entity(m, e, g);
			lb_add_member(m, name, g);

			LLVMSetLinkage(g.value, LLVMExternalLinkage);

			lb_set_entity_from_other_modules_linkage_correctly(other_module, e, name);

			if (e->Variable.thread_local_model != "") {
				LLVMSetThreadLocal(g.value, true);

				String m = e->Variable.thread_local_model;
				LLVMThreadLocalMode mode = LLVMGeneralDynamicTLSModel;
				if (m == "default") {
					mode = LLVMGeneralDynamicTLSModel;
				} else if (m == "localdynamic") {
					mode = LLVMLocalDynamicTLSModel;
				} else if (m == "initialexec") {
					mode = LLVMInitialExecTLSModel;
				} else if (m == "localexec") {
					mode = LLVMLocalExecTLSModel;
				} else {
					GB_PANIC("Unhandled thread local mode %.*s", LIT(m));
				}
				LLVMSetThreadLocalMode(g.value, mode);
			}


			return g;
		}
	}

	GB_PANIC("\n\tError in: %s, missing value '%.*s' in module %s\n",
	         token_pos_to_string(e->token.pos), LIT(e->token.string), m->module_name);
	return {};
}

gb_internal lbValue lb_generate_global_array(lbModule *m, Type *elem_type, i64 count, String prefix, i64 id) {
	Token token = {Token_Ident};
	isize name_len = prefix.len + 1 + 20;

	auto suffix_id = cast(unsigned long long)id;
	char *text = gb_alloc_array(permanent_allocator(), char, name_len+1);
	gb_snprintf(text, name_len,
	            "%.*s-%llu", LIT(prefix), suffix_id);
	text[name_len] = 0;

	String s = make_string_c(text);

	Type *t = alloc_type_array(elem_type, count);
	lbValue g = {};
	g.value = LLVMAddGlobal(m->mod, lb_type(m, t), text);
	g.type = alloc_type_pointer(t);
	LLVMSetInitializer(g.value, LLVMConstNull(lb_type(m, t)));
	LLVMSetLinkage(g.value, LLVMPrivateLinkage);
	// LLVMSetUnnamedAddress(g.value, LLVMGlobalUnnamedAddr);
	string_map_set(&m->members, s, g);
	return g;
}



gb_internal lbValue lb_build_cond(lbProcedure *p, Ast *cond, lbBlock *true_block, lbBlock *false_block) {
	GB_ASSERT(cond != nullptr);
	GB_ASSERT(true_block  != nullptr);
	GB_ASSERT(false_block != nullptr);

	// Use to signal not to do compile time short circuit for consts
	lbValue no_comptime_short_circuit = {};

	switch (cond->kind) {
	case_ast_node(pe, ParenExpr, cond);
		return lb_build_cond(p, pe->expr, true_block, false_block);
	case_end;

	case_ast_node(ue, UnaryExpr, cond);
		if (ue->op.kind == Token_Not) {
			lbValue cond_val = lb_build_cond(p, ue->expr, false_block, true_block);
			if (cond_val.value && LLVMIsConstant(cond_val.value)) {
				return lb_const_bool(p->module, cond_val.type, LLVMConstIntGetZExtValue(cond_val.value) == 0);
			}
			return no_comptime_short_circuit;
		}
	case_end;

	case_ast_node(be, BinaryExpr, cond);
		if (be->op.kind == Token_CmpAnd) {
			lbBlock *block = lb_create_block(p, "cmp.and");
			lb_build_cond(p, be->left, block, false_block);
			lb_start_block(p, block);
			lb_build_cond(p, be->right, true_block, false_block);
			return no_comptime_short_circuit;
		} else if (be->op.kind == Token_CmpOr) {
			lbBlock *block = lb_create_block(p, "cmp.or");
			lb_build_cond(p, be->left, true_block, block);
			lb_start_block(p, block);
			lb_build_cond(p, be->right, true_block, false_block);
			return no_comptime_short_circuit;
		}
	case_end;
	}

	lbValue v = {};
	if (lb_is_expr_untyped_const(cond)) {
		v = lb_expr_untyped_const_to_typed(p->module, cond, t_llvm_bool);
	} else {
		v = lb_build_expr(p, cond);
	}

	v = lb_emit_conv(p, v, t_llvm_bool);

	lb_emit_if(p, v, true_block, false_block);

	return v;
}


gb_internal lbAddr lb_add_local(lbProcedure *p, Type *type, Entity *e, bool zero_init, bool force_no_init) {
	GB_ASSERT(p->decl_block != p->curr_block);
	LLVMPositionBuilderAtEnd(p->builder, p->decl_block->block);

	char const *name = "";
	if (e != nullptr && e->token.string.len > 0 && e->token.string != "_") {
		// NOTE(bill): for debugging purposes only
		name = alloc_cstring(permanent_allocator(), e->token.string);
	}

	LLVMTypeRef llvm_type = lb_type(p->module, type);

	unsigned alignment = cast(unsigned)gb_max(type_align_of(type), lb_alignof(llvm_type));
	if (is_type_matrix(type)) {
		alignment *= 2; // NOTE(bill): Just in case
	}

	LLVMValueRef ptr = llvm_alloca(p, llvm_type, alignment, name);

	if (!zero_init && !force_no_init) {
		// If there is any padding of any kind, just zero init regardless of zero_init parameter
		LLVMTypeKind kind = LLVMGetTypeKind(llvm_type);
		if (kind == LLVMArrayTypeKind) {
			kind = LLVMGetTypeKind(lb_type(p->module, core_array_type(type)));
		}

		if (kind == LLVMStructTypeKind) {
			i64 sz = type_size_of(type);
			if (type_size_of_struct_pretend_is_packed(type) != sz) {
				zero_init = true;
			}
		}
	}

	lbValue val = {};
	val.value = ptr;
	val.type = alloc_type_pointer(type);

	if (e != nullptr) {
		lb_add_entity(p->module, e, val);
		lb_add_debug_local_variable(p, ptr, type, e->token);
	}

	if (zero_init) {
		lb_mem_zero_ptr(p, ptr, type, alignment);
	}

	return lb_addr(val);
}

gb_internal lbAddr lb_add_local_generated(lbProcedure *p, Type *type, bool zero_init) {
	return lb_add_local(p, type, nullptr, zero_init);
}

gb_internal lbAddr lb_add_local_generated_temp(lbProcedure *p, Type *type, i64 min_alignment) {
	lbAddr res = lb_add_local(p, type, nullptr, false, true);
	lb_try_update_alignment(res.addr, cast(unsigned)min_alignment);
	return res;
}


gb_internal void lb_set_linkage_from_entity_flags(lbModule *m, LLVMValueRef value, u64 flags) {
	if (flags & EntityFlag_CustomLinkage_Internal) {
		LLVMSetLinkage(value, LLVMInternalLinkage);
	} else if (flags & EntityFlag_CustomLinkage_Strong) {
		LLVMSetLinkage(value, LLVMExternalLinkage);
	} else if (flags & EntityFlag_CustomLinkage_Weak) {
		LLVMSetLinkage(value, LLVMExternalWeakLinkage);
	} else if (flags & EntityFlag_CustomLinkage_LinkOnce) {
		LLVMSetLinkage(value, LLVMLinkOnceAnyLinkage);
	}
}
