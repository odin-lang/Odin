#include "tilde.hpp"


gb_global Slice<TB_Arena> global_tb_arenas;

gb_internal TB_Arena *cg_arena(void) {
	return &global_tb_arenas[current_thread_index()];
}

gb_internal void cg_global_arena_init(void) {
	global_tb_arenas = slice_make<TB_Arena>(permanent_allocator(), global_thread_pool.threads.count);
	for_array(i, global_tb_arenas) {
		tb_arena_create(&global_tb_arenas[i], 2ull<<20);
	}
}

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
			return TB_TYPE_INTN(cast(u16)gb_min(8*sz, 64));

		case Basic_f16: return TB_TYPE_F16;
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
			return TB_TYPE_INTN(cast(u16)gb_min(8*sz, 64));

		case Basic_f16le: return TB_TYPE_F16;
		case Basic_f32le: return TB_TYPE_F32;
		case Basic_f64le: return TB_TYPE_F64;

		case Basic_f16be: return TB_TYPE_F16;
		case Basic_f32be: return TB_TYPE_F32;
		case Basic_f64be: return TB_TYPE_F64;
		}
		break;

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

gb_internal cgValue cg_lvalue_addr_to_value(cgValue v) {
	if (v.kind == cgValue_Value) {
		GB_ASSERT(is_type_pointer(v.type));
		GB_ASSERT(v.node->dt.type == TB_PTR);
	} else {
		GB_ASSERT(v.kind == cgValue_Addr);
		GB_ASSERT(v.node->dt.type == TB_PTR);
		v.kind = cgValue_Value;
		v.type = alloc_type_pointer(v.type);
	}
	return v;
}

gb_internal cgValue cg_value_multi(cgValueMulti *multi, Type *type) {
	GB_ASSERT(type->kind == Type_Tuple);
	GB_ASSERT(multi != nullptr);
	GB_ASSERT(type->Tuple.variables.count > 1);
	GB_ASSERT(multi->values.count == type->Tuple.variables.count);
	cgValue v = {};
	v.kind = cgValue_Multi;
	v.type = type;
	v.multi = multi;
	return v;
}

gb_internal cgValue cg_value_multi(Slice<cgValue> const &values, Type *type) {
	cgValueMulti *multi = gb_alloc_item(permanent_allocator(), cgValueMulti);
	multi->values = values;
	return cg_value_multi(multi, type);
}


gb_internal cgValue cg_value_multi2(cgValue const &x, cgValue const &y, Type *type) {
	GB_ASSERT(type->kind == Type_Tuple);
	GB_ASSERT(type->Tuple.variables.count == 2);
	cgValueMulti *multi = gb_alloc_item(permanent_allocator(), cgValueMulti);
	multi->values = slice_make<cgValue>(permanent_allocator(), 2);
	multi->values[0] = x;
	multi->values[1] = y;
	return cg_value_multi(multi, type);
}


gb_internal cgAddr cg_addr(cgValue const &value) {
	GB_ASSERT(value.kind != cgValue_Multi);
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

gb_internal cgAddr cg_addr_map(cgValue addr, cgValue map_key, Type *map_type, Type *map_result) {
	GB_ASSERT(is_type_pointer(addr.type));
	Type *mt = type_deref(addr.type);
	GB_ASSERT(is_type_map(mt));

	cgAddr v = {cgAddr_Map, addr};
	v.map.key    = map_key;
	v.map.type   = map_type;
	v.map.result = map_result;
	return v;
}

gb_internal cgAddr cg_addr_soa_variable(cgValue addr, cgValue index, Ast *index_expr) {
	cgAddr v = {cgAddr_SoaVariable, addr};
	v.soa.index = index;
	v.soa.index_expr = index_expr;
	return v;
}



gb_internal void cg_set_debug_pos_from_node(cgProcedure *p, Ast *node) {
	if (node) {
		TokenPos pos = ast_token(node).pos;
		TB_SourceFile **file = map_get(&p->module->file_id_map, cast(uintptr)pos.file_id);
		if (file) {
			tb_inst_location(p->func, *file, pos.line, pos.column);
		}
	}
}

gb_internal void cg_add_symbol(cgModule *m, Entity *e, TB_Symbol *symbol) {
	if (e) {
		rw_mutex_lock(&m->values_mutex);
		map_set(&m->symbols, e, symbol);
		rw_mutex_unlock(&m->values_mutex);
	}
}

gb_internal void cg_add_entity(cgModule *m, Entity *e, cgValue const &val) {
	if (e) {
		rw_mutex_lock(&m->values_mutex);
		GB_ASSERT(val.node != nullptr);
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
		if (p->symbol != nullptr) {
			map_set(&m->symbols, p->entity, p->symbol);
		}
	}
	string_map_set(&m->procedures, p->name, p);
	rw_mutex_unlock(&m->values_mutex);

}

gb_internal TB_Symbol *cg_find_symbol_from_entity(cgModule *m, Entity *e) {
	GB_ASSERT(e != nullptr);

	rw_mutex_lock(&m->values_mutex);
	TB_Symbol **found = map_get(&m->symbols, e);
	if (found) {
		rw_mutex_unlock(&m->values_mutex);
		return *found;
	}

	String link_name = cg_get_entity_name(m, e);
	cgProcedure **proc_found = string_map_get(&m->procedures, link_name);
	if (proc_found) {
		TB_Symbol *symbol = (*proc_found)->symbol;
		map_set(&m->symbols, e, symbol);
		rw_mutex_unlock(&m->values_mutex);
		return symbol;
	}
	rw_mutex_unlock(&m->values_mutex);

	if (e->kind == Entity_Procedure) {
		debugf("[Tilde] try to generate procedure %.*s as it was not in the minimum_dependency_set", LIT(e->token.string));
		// IMPORTANT TODO(bill): This is an utter bodge, try and fix this shit
		cgProcedure *p = cg_procedure_create(m, e);
		if (p != nullptr) {
			GB_ASSERT(p->symbol != nullptr);
			cg_add_procedure_to_queue(p);
			return p->symbol;
		}
	}


	GB_PANIC("could not find entity's symbol %.*s", LIT(e->token.string));
	return nullptr;
}


struct cgGlobalVariable {
	cgValue var;
	cgValue init;
	DeclInfo *decl;
	bool is_initialized;
};

// Returns already_has_entry_point
gb_internal bool cg_global_variables_create(cgModule *m, Array<cgGlobalVariable> *global_variables) {
	isize global_variable_max_count = 0;
	bool already_has_entry_point = false;

	for (Entity *e : m->info->entities) {
		String name = e->token.string;

		if (e->kind == Entity_Variable) {
			global_variable_max_count++;
		} else if (e->kind == Entity_Procedure) {
			if ((e->scope->flags&ScopeFlag_Init) && name == "main") {
				GB_ASSERT(e == m->info->entry_point);
			}
			if (build_context.command_kind == Command_test &&
			    (e->Procedure.is_export || e->Procedure.link_name.len > 0)) {
				String link_name = e->Procedure.link_name;
				if (e->pkg->kind == Package_Runtime) {
					if (link_name == "main"           ||
					    link_name == "DllMain"        ||
					    link_name == "WinMain"        ||
					    link_name == "wWinMain"       ||
					    link_name == "mainCRTStartup" ||
					    link_name == "_start") {
						already_has_entry_point = true;
					}
				}
			}
		}
	}
	*global_variables = array_make<cgGlobalVariable>(permanent_allocator(), 0, global_variable_max_count);

	auto *min_dep_set = &m->info->minimum_dependency_set;

	for (DeclInfo *d : m->info->variable_init_order) {
		Entity *e = d->entity;

		if ((e->scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		if (!ptr_set_exists(min_dep_set, e)) {
			continue;
		}

		DeclInfo *decl = decl_info_of_entity(e);
		if (decl == nullptr) {
			continue;
		}
		GB_ASSERT(e->kind == Entity_Variable);

		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;

		String name = cg_get_entity_name(m, e);

		TB_Linkage linkage = TB_LINKAGE_PRIVATE;

		if (is_foreign) {
			linkage = TB_LINKAGE_PUBLIC;
			// lb_add_foreign_library_path(m, e->Variable.foreign_library);
			// lb_set_wasm_import_attributes(g.value, e, name);
		} else if (is_export) {
			linkage = TB_LINKAGE_PUBLIC;
		}
		// lb_set_linkage_from_entity_flags(m, g.value, e->flags);

		TB_DebugType *debug_type = cg_debug_type(m, e->type);
		TB_Global *global = tb_global_create(m->mod, name.len, cast(char const *)name.text, debug_type, linkage);
		cgValue g = cg_value(global, alloc_type_pointer(e->type));

		TB_ModuleSectionHandle section = tb_module_get_data(m->mod);

		if (e->Variable.thread_local_model != "") {
			section = tb_module_get_tls(m->mod);
		}
		if (e->Variable.link_section.len > 0) {
			// TODO(bill): custom module sections
			// LLVMSetSection(g.value, alloc_cstring(permanent_allocator(), e->Variable.link_section));
		}


		cgGlobalVariable var = {};
		var.var = g;
		var.decl = decl;

		if (decl->init_expr != nullptr) {
			TypeAndValue tav = type_and_value_of_expr(decl->init_expr);

			isize max_regions = cg_global_const_calculate_region_count(tav.value, e->type);
			tb_global_set_storage(m->mod, section, global, type_size_of(e->type), type_align_of(e->type), max_regions);

			if (tav.mode == Addressing_Constant &&
			    tav.value.kind != ExactValue_Invalid) {
				cg_global_const_add_region(m, tav.value, e->type, global, 0);
				var.is_initialized = true;
			}
			if (!var.is_initialized && is_type_untyped_nil(tav.type)) {
				var.is_initialized = true;
			}
		} else {
			var.is_initialized = true;
			// TODO(bill): is this even needed;
			i64 max_regions = cg_global_const_calculate_region_count_from_basic_type(e->type);
			tb_global_set_storage(m->mod, section, global, type_size_of(e->type), type_align_of(e->type), max_regions);
		}

		array_add(global_variables, var);

		cg_add_symbol(m, e, cast(TB_Symbol *)global);
		cg_add_entity(m, e, g);
		cg_add_member(m, name, g);
	}

	cg_setup_type_info_data(m);

	return already_has_entry_point;
}

gb_internal void cg_global_variables_initialize(cgProcedure *p, Array<cgGlobalVariable> *global_variables) {
	for (cgGlobalVariable &var : *global_variables) {
		if (var.is_initialized) {
			continue;
		}
		cgValue src = cg_build_expr(p, var.decl->init_expr);
		cgValue dst = cg_flatten_value(p, var.var);
		cg_emit_store(p, dst, src);
	}
}


gb_internal cgModule *cg_module_create(Checker *c) {
	cgModule *m = gb_alloc_item(permanent_allocator(), cgModule);

	m->checker = c;
	m->info = &c->info;


	TB_FeatureSet feature_set = {};
	bool is_jit = false;
	m->mod = tb_module_create(TB_ARCH_X86_64, TB_SYSTEM_WINDOWS, &feature_set, is_jit);
	tb_module_set_tls_index(m->mod, 10, "_tls_index");

	map_init(&m->values);
	map_init(&m->symbols);
	map_init(&m->file_id_map);
	map_init(&m->debug_type_map);
	map_init(&m->proc_debug_type_map);
	map_init(&m->proc_proto_map);
	map_init(&m->anonymous_proc_lits_map);
	map_init(&m->equal_procs);
	map_init(&m->hasher_procs);
	map_init(&m->map_get_procs);
	map_init(&m->map_set_procs);
	map_init(&m->map_info_map);
	map_init(&m->map_cell_info_map);

	array_init(&m->single_threaded_procedure_queue, heap_allocator());


	for_array(id, global_files) {
		if (AstFile *f = global_files[id]) {
			char const *path = alloc_cstring(temporary_allocator(), f->fullpath);
			TB_SourceFile *file = tb_get_source_file(m->mod, path);
			map_set(&m->file_id_map, cast(uintptr)id, file);
		}
	}

	return m;
}

gb_internal void cg_module_destroy(cgModule *m) {
	map_destroy(&m->values);
	map_destroy(&m->symbols);
	map_destroy(&m->file_id_map);
	map_destroy(&m->debug_type_map);
	map_destroy(&m->proc_debug_type_map);
	map_destroy(&m->proc_proto_map);
	map_destroy(&m->anonymous_proc_lits_map);
	map_destroy(&m->equal_procs);
	map_destroy(&m->hasher_procs);
	map_destroy(&m->map_get_procs);
	map_destroy(&m->map_set_procs);
	map_destroy(&m->map_info_map);
	map_destroy(&m->map_cell_info_map);

	array_free(&m->single_threaded_procedure_queue);

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

gb_internal String cg_get_entity_name(cgModule *m, Entity *e) {
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

#include "tilde_const.cpp"
#include "tilde_debug.cpp"
#include "tilde_expr.cpp"
#include "tilde_builtin.cpp"
#include "tilde_type_info.cpp"
#include "tilde_proc.cpp"
#include "tilde_stmt.cpp"


gb_internal String cg_filepath_obj_for_module(cgModule *m, bool use_assembly) {
	String path = concatenate3_strings(permanent_allocator(),
		build_context.build_paths[BuildPath_Output].basename,
		STR_LIT("/"),
		build_context.build_paths[BuildPath_Output].name
	);

	// if (m->file) {
	// 	char buf[32] = {};
	// 	isize n = gb_snprintf(buf, gb_size_of(buf), "-%u", m->file->id);
	// 	String suffix = make_string((u8 *)buf, n-1);
	// 	path = concatenate_strings(permanent_allocator(), path, suffix);
	// } else if (m->pkg) {
	// 	path = concatenate3_strings(permanent_allocator(), path, STR_LIT("-"), m->pkg->name);
	// }

	String ext = {};

	if (use_assembly) {
		ext = STR_LIT(".S");
	} else {
		if (is_arch_wasm()) {
			ext = STR_LIT(".wasm.o");
		} else {
			switch (build_context.metrics.os) {
			case TargetOs_windows:
				ext = STR_LIT(".obj");
				break;
			default:
			case TargetOs_darwin:
			case TargetOs_linux:
			case TargetOs_essence:
				ext = STR_LIT(".o");
				break;

			case TargetOs_freestanding:
				switch (build_context.metrics.abi) {
				default:
				case TargetABI_Default:
				case TargetABI_SysV:
					ext = STR_LIT(".o");
					break;
				case TargetABI_Win64:
					ext = STR_LIT(".obj");
					break;
				}
				break;
			}
		}
	}

	return concatenate_strings(permanent_allocator(), path, ext);
}


gb_internal WORKER_TASK_PROC(cg_procedure_generate_worker_proc) {
	cgProcedure *p = cast(cgProcedure *)data;
	cg_procedure_generate(p);
	return 0;
}

gb_internal void cg_add_procedure_to_queue(cgProcedure *p) {
	if (p == nullptr) {
		return;
	}
	cgModule *m = p->module;
	if (m->do_threading) {
		thread_pool_add_task(cg_procedure_generate_worker_proc, p);
	} else {
		array_add(&m->single_threaded_procedure_queue, p);
	}
}

gb_internal bool cg_generate_code(Checker *c, LinkerData *linker_data) {
	TIME_SECTION("Tilde Module Initializtion");

	CheckerInfo *info = &c->info;

	linker_data_init(linker_data, info, c->parser->init_fullpath);

	#if defined(GB_SYSTEM_OSX)
		linker_enable_system_library_linking(linker_data);
	#endif

	cg_global_arena_init();

	cgModule *m = cg_module_create(c);
	defer (cg_module_destroy(m));

	m->do_threading = false;

	TIME_SECTION("Tilde Global Variables");

	Array<cgGlobalVariable> global_variables = {};
	bool already_has_entry_point = cg_global_variables_create(m, &global_variables);
	gb_unused(already_has_entry_point);

	if (true) {
		Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
		cgProcedure *p = cg_procedure_create_dummy(m, str_lit(CG_STARTUP_RUNTIME_PROC_NAME), proc_type);
		p->is_startup = true;
		cg_startup_runtime_proc = p;
	}

	if (true) {
		Type *proc_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
		cgProcedure *p = cg_procedure_create_dummy(m, str_lit(CG_CLEANUP_RUNTIME_PROC_NAME), proc_type);
		p->is_startup = true;
		cg_cleanup_runtime_proc = p;
	}

	auto *min_dep_set = &info->minimum_dependency_set;

	Array<cgProcedure *> procedures_to_generate = {};
	array_init(&procedures_to_generate, heap_allocator());
	defer (array_free(&procedures_to_generate));

	for (Entity *e : info->entities) {
		String name  = e->token.string;
		Scope *scope = e->scope;

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
			array_add(&procedures_to_generate, p);
		}
	}
	for (cgProcedure *p : procedures_to_generate) {
		cg_add_procedure_to_queue(p);
	}

	if (!m->do_threading) {
		for (isize i = 0; i < m->single_threaded_procedure_queue.count; i++) {
			cgProcedure *p = m->single_threaded_procedure_queue[i];
			cg_procedure_generate(p);
		}
	}

	thread_pool_wait();

	{
		cgProcedure *p = cg_startup_runtime_proc;
		cg_procedure_begin(p);
		cg_global_variables_initialize(p, &global_variables);
		tb_inst_ret(p->func, 0, nullptr);
		cg_procedure_end(p);
	}
	{
		cgProcedure *p = cg_cleanup_runtime_proc;
		cg_procedure_begin(p);
		tb_inst_ret(p->func, 0, nullptr);
		cg_procedure_end(p);
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
		case TargetOs_haiku:
			debug_format = TB_DEBUGFMT_DWARF;
			break;
		}
	}
	TB_ExportBuffer export_buffer = tb_module_object_export(m->mod, debug_format);
	defer (tb_export_buffer_free(export_buffer));

	String filepath_obj = cg_filepath_obj_for_module(m, false);
	array_add(&linker_data->output_object_paths, filepath_obj);
	GB_ASSERT(tb_export_buffer_to_file(export_buffer, cast(char const *)filepath_obj.text));

	return true;
}

#undef ABI_PKG_NAME_SEPARATOR
