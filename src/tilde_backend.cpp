#include "tilde_backend.hpp"

// returns TB_TYPE_VOID if not trivially possible
gb_internal TB_DataType cg_data_type(Type *t) {
	GB_ASSERT(t != nullptr);
	t = core_type(t);
	i64 sz = type_size_of(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_bool:
		case Basic_b8:
		case Basic_b16:
		case Basic_b32:
		case Basic_b64:

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

		case Basic_rune:

		case Basic_int:
		case Basic_uint:
		case Basic_uintptr:
		case Basic_typeid:
			return TB_TYPE_INTN(cast(u16)(8*sz));

		case Basic_f16: return TB_TYPE_I16;
		case Basic_f32: return TB_TYPE_F32;
		case Basic_f64: return TB_TYPE_F64;

		case Basic_rawptr:  return TB_TYPE_PTR;
		case Basic_cstring: return TB_TYPE_PTR;


		// Endian Specific Types
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
			return TB_TYPE_INTN(cast(u16)(8*sz));

		case Basic_f16le: return TB_TYPE_I16;
		case Basic_f32le: return TB_TYPE_F32;
		case Basic_f64le: return TB_TYPE_F64;

		case Basic_f16be: return TB_TYPE_I16;
		case Basic_f32be: return TB_TYPE_F32;
		case Basic_f64be: return TB_TYPE_F64;
		}

	case Type_Pointer:
	case Type_MultiPointer:
	case Type_Proc:
		return TB_TYPE_PTR;

	case Type_BitSet:
		return cg_data_type(bit_set_to_int(t));

	case Type_RelativePointer:
		return cg_data_type(t->RelativePointer.base_integer);
	}

	// unknown
	return {};
}


gb_internal cgValue cg_value(TB_Global *g, Type *type) {
	return cg_value((TB_Symbol *)g, type);
}
gb_internal cgValue cg_value(TB_External *e, Type *type) {
	return cg_value((TB_Symbol *)e, type);
}
gb_internal cgValue cg_value(TB_Function *f, Type *type) {
	return cg_value((TB_Symbol *)f, type);
}
gb_internal cgValue cg_value(TB_Symbol *s, Type *type) {
	cgValue v = {};
	v.kind = cgValue_Symbol;
	v.type = type;
	v.symbol = s;
	return v;
}
gb_internal cgValue cg_value(TB_Node *node, Type *type) {
	cgValue v = {};
	v.kind = cgValue_Value;
	v.type = type;
	v.node = node;
	return v;
}
gb_internal cgValue cg_lvalue_addr(TB_Node *node, Type *type) {
	GB_ASSERT(node->dt.type == TB_PTR);
	cgValue v = {};
	v.kind = cgValue_Addr;
	v.type = type;
	v.node = node;
	return v;
}

gb_internal cgAddr cg_addr(cgValue const &value) {
	cgAddr addr = {};
	addr.kind = cgAddr_Default;
	addr.addr = value;
	if (addr.addr.kind == cgValue_Addr) {
		GB_ASSERT(addr.addr.node != nullptr);
		addr.addr.kind = cgValue_Value;
		addr.addr.type = alloc_type_pointer(addr.addr.type);
	}
	return addr;
}


gb_internal void cg_add_entity(cgModule *m, Entity *e, cgValue const &val) {
	if (e) {
		rw_mutex_lock(&m->values_mutex);
		map_set(&m->values, e, val);
		rw_mutex_unlock(&m->values_mutex);
	}
}

gb_internal void cg_add_member(cgModule *m, String const &name, cgValue const &val) {
	if (name.len > 0) {
		rw_mutex_lock(&m->values_mutex);
		string_map_set(&m->members, name, val);
		rw_mutex_unlock(&m->values_mutex);
	}
}

gb_internal void cg_add_procedure_value(cgModule *m, cgProcedure *p) {
	rw_mutex_lock(&m->values_mutex);
	if (p->entity != nullptr) {
		map_set(&m->procedure_values, p->func, p->entity);
	}
	string_map_set(&m->procedures, p->name, p);
	rw_mutex_unlock(&m->values_mutex);

}

gb_internal isize cg_type_info_index(CheckerInfo *info, Type *type, bool err_on_not_found=true) {
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

gb_internal void cg_create_global_variables(cgModule *m) {
	if (build_context.no_rtti) {
		return;
	}

	CheckerInfo *info = m->info;
	{ // Add type info data
		isize max_type_info_count = info->minimum_dependency_type_info_set.count+1;
		// gb_printf_err("max_type_info_count: %td\n", max_type_info_count);
		Type *t = alloc_type_array(t_type_info, max_type_info_count);

		TB_Global *g = tb_global_create(m->mod, -1, CG_TYPE_INFO_DATA_NAME, nullptr, TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, max_type_info_count);

		cgValue value = cg_value(g, alloc_type_pointer(t));
		cg_global_type_info_data_entity = alloc_entity_variable(nullptr, make_token_ident(CG_TYPE_INFO_DATA_NAME), t, EntityState_Resolved);
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
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
				cg_global_type_info_member_types = cg_addr(cg_value(g, alloc_type_pointer(t)));

			}
			{
				char const *name = CG_TYPE_INFO_NAMES_NAME;
				Type *t = alloc_type_array(t_string, count);
				TB_Global *g = tb_global_create(m->mod, -1, name, nullptr, TB_LINKAGE_PRIVATE);
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
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
				tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), g, type_size_of(t), 16, count);
				cg_global_type_info_member_tags = cg_addr(cg_value(g, alloc_type_pointer(t)));
			}
		}
	}
}

cgModule *cg_module_create(Checker *c) {
	cgModule *m = gb_alloc_item(permanent_allocator(), cgModule);

	m->checker = c;
	m->info = &c->info;


	TB_FeatureSet feature_set = {};
	bool is_jit = false;
	m->mod = tb_module_create(TB_ARCH_X86_64, TB_SYSTEM_WINDOWS, &feature_set, is_jit);
	tb_module_set_tls_index(m->mod, 10, "_tls_index");

	map_init(&m->values);
	array_init(&m->procedures_to_generate, heap_allocator());

	map_init(&m->file_id_map);


	for_array(id, global_files) {
		if (AstFile *f = global_files[id]) {
			char const *path = alloc_cstring(permanent_allocator(), f->fullpath);
			map_set(&m->file_id_map, cast(uintptr)id, tb_file_create(m->mod, path));
		}
	}

	return m;
}

void cg_module_destroy(cgModule *m) {
	map_destroy(&m->values);
	array_free(&m->procedures_to_generate);
	map_destroy(&m->file_id_map);

	tb_module_destroy(m->mod);
}

gb_internal String cg_set_nested_type_name_ir_mangled_name(Entity *e, cgProcedure *p) {
	// NOTE(bill, 2020-03-08): A polymorphic procedure may take a nested type declaration
	// and as a result, the declaration does not have time to determine what it should be

	GB_ASSERT(e != nullptr && e->kind == Entity_TypeName);
	if (e->TypeName.ir_mangled_name.len != 0)  {
		return e->TypeName.ir_mangled_name;
	}
	GB_ASSERT((e->scope->flags & ScopeFlag_File) == 0);

	if (p == nullptr) {
		Entity *proc = nullptr;
		if (e->parent_proc_decl != nullptr) {
			proc = e->parent_proc_decl->entity;
		} else {
			Scope *scope = e->scope;
			while (scope != nullptr && (scope->flags & ScopeFlag_Proc) == 0) {
				scope = scope->parent;
			}
			GB_ASSERT(scope != nullptr);
			GB_ASSERT(scope->flags & ScopeFlag_Proc);
			proc = scope->procedure_entity;
		}
		GB_ASSERT(proc->kind == Entity_Procedure);
		if (proc->cg_procedure != nullptr) {
			p = proc->cg_procedure;
		}
	}

	// NOTE(bill): Generate a new name
	// parent_proc.name-guid
	String ts_name = e->token.string;

	if (p != nullptr) {
		isize name_len = p->name.len + 1 + ts_name.len + 1 + 10 + 1;
		char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
		u32 guid = 1+p->module->nested_type_name_guid.fetch_add(1);
		name_len = gb_snprintf(name_text, name_len, "%.*s" ABI_PKG_NAME_SEPARATOR "%.*s-%u", LIT(p->name), LIT(ts_name), guid);

		String name = make_string(cast(u8 *)name_text, name_len-1);
		e->TypeName.ir_mangled_name = name;
		return name;
	} else {
		// NOTE(bill): a nested type be required before its parameter procedure exists. Just give it a temp name for now
		isize name_len = 9 + 1 + ts_name.len + 1 + 10 + 1;
		char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
		static std::atomic<u32> guid;
		name_len = gb_snprintf(name_text, name_len, "_internal" ABI_PKG_NAME_SEPARATOR "%.*s-%u", LIT(ts_name), 1+guid.fetch_add(1));

		String name = make_string(cast(u8 *)name_text, name_len-1);
		e->TypeName.ir_mangled_name = name;
		return name;
	}
}

gb_internal String cg_mangle_name(cgModule *m, Entity *e) {
	String name = e->token.string;

	AstPackage *pkg = e->pkg;
	GB_ASSERT_MSG(pkg != nullptr, "Missing package for '%.*s'", LIT(name));
	String pkgn = pkg->name;
	GB_ASSERT(!rune_is_digit(pkgn[0]));
	if (pkgn == "llvm") {
		GB_PANIC("llvm. entities are not allowed with the tilde backend");
	}

	isize max_len = pkgn.len + 1 + name.len + 1;
	bool require_suffix_id = is_type_polymorphic(e->type, true);

	if ((e->scope->flags & (ScopeFlag_File | ScopeFlag_Pkg)) == 0) {
		require_suffix_id = true;
	} else if (is_blank_ident(e->token)) {
		require_suffix_id = true;
	}if (e->flags & EntityFlag_NotExported) {
		require_suffix_id = true;
	}

	if (require_suffix_id) {
		max_len += 21;
	}

	char *new_name = gb_alloc_array(permanent_allocator(), char, max_len);
	isize new_name_len = gb_snprintf(
		new_name, max_len,
		"%.*s" ABI_PKG_NAME_SEPARATOR "%.*s", LIT(pkgn), LIT(name)
	);
	if (require_suffix_id) {
		char *str = new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)e->id);
		new_name_len += extra-1;
	}

	String mangled_name = make_string((u8 const *)new_name, new_name_len-1);
	return mangled_name;
}

String cg_get_entity_name(cgModule *m, Entity *e) {
	if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	}
	GB_ASSERT(e != nullptr);

	if (e->pkg == nullptr) {
		return e->token.string;
	}

	if (e->kind == Entity_TypeName && (e->scope->flags & ScopeFlag_File) == 0) {
		return cg_set_nested_type_name_ir_mangled_name(e, nullptr);
	}

	String name = {};

	bool no_name_mangle = false;

	if (e->kind == Entity_Variable) {
		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		no_name_mangle = e->Variable.link_name.len > 0 || is_foreign || is_export;
		if (e->Variable.link_name.len > 0) {
			return e->Variable.link_name;
		}
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		return e->Procedure.link_name;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		no_name_mangle = true;
	}

	if (!no_name_mangle) {
		name = cg_mangle_name(m, e);
	}
	if (name.len == 0) {
		name = e->token.string;
	}

	if (e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;
	} else if (e->kind == Entity_Procedure) {
		e->Procedure.link_name = name;
	}

	return name;
}


struct cgGlobalVariable {
	cgValue var;
	cgValue init;
	DeclInfo *decl;
	bool is_initialized;
};

#include "tilde_const.cpp"
#include "tilde_expr.cpp"
#include "tilde_proc.cpp"
#include "tilde_stmt.cpp"


gb_internal bool cg_generate_code(Checker *c) {
	TIME_SECTION("Tilde Module Initializtion");

	CheckerInfo *info = &c->info;
	gb_unused(info);

	cgModule *m = cg_module_create(c);
	defer (cg_module_destroy(m));

	TIME_SECTION("Tilde Global Variables");

	cg_create_global_variables(m);

	// isize global_variable_max_count = 0;
	// bool already_has_entry_point = false;

	// for (Entity *e : info->entities) {
	// 	String name = e->token.string;

	// 	if (e->kind == Entity_Variable) {
	// 		global_variable_max_count++;
	// 	} else if (e->kind == Entity_Procedure) {
	// 		if ((e->scope->flags&ScopeFlag_Init) && name == "main") {
	// 			GB_ASSERT(e == info->entry_point);
	// 		}
	// 		if (build_context.command_kind == Command_test &&
	// 		    (e->Procedure.is_export || e->Procedure.link_name.len > 0)) {
	// 			String link_name = e->Procedure.link_name;
	// 			if (e->pkg->kind == Package_Runtime) {
	// 				if (link_name == "main"           ||
	// 				    link_name == "DllMain"        ||
	// 				    link_name == "WinMain"        ||
	// 				    link_name == "wWinMain"       ||
	// 				    link_name == "mainCRTStartup" ||
	// 				    link_name == "_start") {
	// 					already_has_entry_point = true;
	// 				}
	// 			}
	// 		}
	// 	}
	// }
	// auto global_variables = array_make<cgGlobalVariable>(permanent_allocator(), 0, global_variable_max_count);

	if (true) {
		Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
		cgProcedure *p = cg_procedure_create_dummy(m, str_lit(CG_STARTUP_RUNTIME_PROC_NAME), proc_type);
		p->is_startup = true;

		cg_procedure_begin(p);
		cg_procedure_end(p);
	}

	if (true) {
		Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
		cgProcedure *p = cg_procedure_create_dummy(m, str_lit(CG_CLEANUP_RUNTIME_PROC_NAME), proc_type);
		p->is_startup = true;

		cg_procedure_begin(p);
		cg_procedure_end(p);
	}

	auto *min_dep_set = &info->minimum_dependency_set;

	for (Entity *e : info->entities) {
		String  name  = e->token.string;
		Scope * scope = e->scope;

		if ((scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		Scope *package_scope = scope->parent;
		GB_ASSERT(package_scope->flags & ScopeFlag_Pkg);

		if (e->kind != Entity_Procedure) {
			continue;
		}

		if (!ptr_set_exists(min_dep_set, e)) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}
		if (cgProcedure *p = cg_procedure_create(m, e)) {
			array_add(&m->procedures_to_generate, p);
		}
	}


	for (isize i = 0; i < m->procedures_to_generate.count; i++) {
		cg_procedure_generate(m->procedures_to_generate[i]);
	}

	TB_DebugFormat debug_format = TB_DEBUGFMT_NONE;
	if (build_context.ODIN_DEBUG) {
		switch (build_context.metrics.os) {
		case TargetOs_windows:
			debug_format = TB_DEBUGFMT_CODEVIEW;
			break;
		case TargetOs_darwin:
		case TargetOs_linux:
		case TargetOs_essence:
		case TargetOs_freebsd:
		case TargetOs_openbsd:
			debug_format = TB_DEBUGFMT_DWARF;
			break;
		}
	}
	TB_ExportBuffer export_buffer = tb_module_object_export(m->mod, debug_format);
	defer (tb_export_buffer_free(export_buffer));

	char const *path = "W:/Odin/tilde_main.obj";
	GB_ASSERT(tb_export_buffer_to_file(export_buffer, path));


	////////////////////////////////////////////////////////////////////////////////////


	// TB_Arena *arena = tb_default_arena();

	// TB_Global *str = nullptr;
	// {
	// 	TB_Global *str_data = nullptr;
	// 	{
	// 		str_data = tb_global_create(m->mod, "csb$1", nullptr, TB_LINKAGE_PRIVATE);
	// 		tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), str_data, 8, 1, 1);
	// 		void *region = tb_global_add_region(m->mod, str_data, 0, 8);
	// 		memcpy(region, "Hellope\x00", 8);
	// 	}

	// 	str = tb_global_create(m->mod, "global$str", nullptr, TB_LINKAGE_PRIVATE);
	// 	tb_global_set_storage(m->mod, tb_module_get_rdata(m->mod), str, 16, 8, 2);
	// 	tb_global_add_symbol_reloc(m->mod, str, 0, cast(TB_Symbol *)str_data);
	// 	void *len = tb_global_add_region(m->mod, str, 8, 8);
	// 	*cast(i64 *)len = 7;
	// }

	// {
	// 	TB_PrototypeParam printf_ret = {TB_TYPE_I32};
	// 	TB_PrototypeParam printf_params = {TB_TYPE_PTR};
	// 	TB_FunctionPrototype *printf_proto = tb_prototype_create(m->mod, TB_STDCALL, 1, &printf_params, 1, &printf_ret, true);
	// 	TB_External *printf_proc = tb_extern_create(m->mod, "printf", TB_EXTERNAL_SO_LOCAL);

	// 	TB_PrototypeParam main_ret = {TB_TYPE_I32};
	// 	TB_FunctionPrototype *main_proto = tb_prototype_create(m->mod, TB_STDCALL, 0, nullptr, 1, &main_ret, false);
	// 	TB_Function *         p = tb_function_create(m->mod, "main", TB_LINKAGE_PUBLIC, TB_COMDAT_NONE);
	// 	tb_function_set_prototype(p, main_proto, arena);


	// 	auto str_ptr          = tb_inst_get_symbol_address(p, cast(TB_Symbol *)str);
	// 	auto str_data_ptr_ptr = tb_inst_member_access(p, str_ptr, 0);
	// 	auto str_data_ptr     = tb_inst_load(p, TB_TYPE_PTR, str_data_ptr_ptr, 1, false);
	// 	auto str_len_ptr      = tb_inst_member_access(p, str_ptr, 8);
	// 	auto str_len          = tb_inst_load(p, TB_TYPE_I64, str_len_ptr, 8, false);


	// 	TB_Node *params[4] = {};
	// 	params[0] = tb_inst_cstring(p, "%.*s %s!\n");
	// 	params[1] = tb_inst_trunc(p, str_len, TB_TYPE_I32);
	// 	params[2] = str_data_ptr;
	// 	params[3] = tb_inst_cstring(p, "World");
	// 	TB_MultiOutput output = tb_inst_call(p, printf_proto, tb_inst_get_symbol_address(p, cast(TB_Symbol *)printf_proc), gb_count_of(params), params);
	// 	gb_unused(output);
	// 	TB_Node *printf_return_value = output.single;

	// 	TB_Node *zero = tb_inst_uint(p, TB_TYPE_I32, 0);
	// 	TB_Node *one  = tb_inst_uint(p, TB_TYPE_I32, 1);

	// 	TB_Node *prev_case = tb_inst_get_control(p);

	// 	TB_Node *true_case  = tb_inst_region(p);
	// 	TB_Node *false_case = tb_inst_region(p);

	// 	TB_Node *cond = tb_inst_cmp_igt(p, printf_return_value, zero, true);
	// 	tb_inst_if(p, cond, true_case, false_case);

	// 	tb_inst_set_control(p, true_case);
	// 	tb_inst_ret(p, 1, &zero);

	// 	tb_inst_set_control(p, false_case);
	// 	tb_inst_ret(p, 1, &one);

	// 	tb_inst_set_control(p, prev_case);


	// 	tb_module_compile_function(m->mod, p, TB_ISEL_FAST);

	// 	tb_function_print(p, tb_default_print_callback, stdout);


	// 	TB_DebugFormat debug_format = TB_DEBUGFMT_NONE;
	// 	TB_ExportBuffer export_buffer = tb_module_object_export(m->mod, debug_format);
	// 	defer (tb_export_buffer_free(export_buffer));

	// 	char const *path = "W:/Odin/tilde_main.obj";
	// 	GB_ASSERT(tb_export_buffer_to_file(export_buffer, path));
	// }
	return true;
}

#undef ABI_PKG_NAME_SEPARATOR
