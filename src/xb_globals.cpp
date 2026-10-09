gb_internal bool lb_global_variable_has_constant_init(Entity *e, DeclInfo *decl);
gb_internal void xb_stat_fail(xbModule *m, char const *reason);
gb_internal void xb_family_init(xbFamily *family, DeclInfo *root_decl);
gb_internal void xb_family_destroy(xbFamily *family);
gb_internal bool xb_family_build(xbModule *m, xbFamily *family, Entity *root, char const **reason);
gb_internal void xb_family_lower(xbModule *m, xbFamily *family, Entity *root);
gb_internal bool xb_compile_proc(xbModule *m, Entity *e, char const **reason);

// Global variables: storage and constant data, for the same set of globals LLVM creates.
// Globals with a non-constant initializer start zeroed, the startup code fills them in.

gb_internal i64 xb_section_reserve(xbModule *m, xbSection sec, i64 size, i64 align) {
	m->section_align[sec] = gb_max(m->section_align[sec], align);
	i64 at = 0;
	if (sec == xbSection_Bss || sec == xbSection_TBss) {
		at = align_formula(m->nobits_size[sec], align);
		m->nobits_size[sec] = at + size;
	} else {
		Array<u8> *data = &m->sections[sec];
		while (data->count % align != 0) array_add(data, cast(u8)0);
		at = data->count;
		array_resize(data, at + size);
		gb_zero_size(data->data + at, size);
	}
	if (xb_shadow_logs(m)) {
		xbShadowOp *op = xb_shadow_log(m, xbShadowOp_Reserve);
		op->sec = sec;
		op->a = at;
		op->b = size;
		op->c = align;
	}
	return at;
}

// Defines one global; false leaves it to LLVM.
gb_internal bool xb_define_global(xbModule *m, Entity *e, DeclInfo *decl, char const **reason) {
	if (e->Variable.link_section.len > 0) {
		*reason = "global in a custom section";
		return false;
	}
	bool tls = e->Variable.thread_local_model.len != 0;
	ExactValue value = {};
	if (decl->init_expr != nullptr && lb_global_variable_has_constant_init(e, decl)) {
		value = type_and_value_of_expr(decl->init_expr).value;
	}
	i64 size = type_size_of(e->type);
	i64 align = gb_max(gb_max(type_align_of(e->type), cast(i64)e->Variable.custom_align), cast(i64)1);
	if (i64 realign = lb_tls_realign(e)) {
		size += realign - 16;
		align = 16;
	}

	xbSection sec = tls ? xbSection_TBss : xbSection_Bss;
	xbConstBuf b = {};
	defer (array_free(&b.bytes));
	defer (array_free(&b.relocs));
	if (value.kind != ExactValue_Invalid) {
		b.m = m;
		b.writable = true;
		b.proc_lits = true;
		b.bytes = array_make<u8>(heap_allocator(), size, size);
		gb_zero_size(b.bytes.data, size);
		b.relocs = array_make<xbReloc>(heap_allocator(), 0, 4);
		if (!xb_cb_write(&b, e->type, value, 0)) {
			*reason = b.fail;
			return false;
		}
		sec = tls ? xbSection_TData : xbSection_Data;
	}

	i64 at = xb_section_reserve(m, sec, size, align);
	if (b.bytes.count > 0) {
		gb_memmove(m->sections[sec].data + at, b.bytes.data, size);
		for (xbReloc r : b.relocs) {
			r.section = sec;
			r.offset += at;
			array_add(&m->relocs, r);
		}
	}

	i32 sym = xb_symbol(m, xb_entity_name(m, e));
	xbSymbol *s = &m->symbols[sym];
	s->section = sec;
	s->offset = at;
	s->size = size;
	// weak like LLVM's, so each package's object may carry a copy
	s->flags |= xbSymbolFlag_Global;
	// hidden like LLVM's, so a shared object may reach it directly
	if (!e->Variable.is_export) s->flags |= xbSymbolFlag_Weak | xbSymbolFlag_Hidden;
	else s->flags |= xbSymbolFlag_Export;
	if (tls) s->flags |= xbSymbolFlag_TLS;
	s->realign = lb_tls_realign(e);

	if (build_context.ODIN_DEBUG && !is_blank_ident(e->token.string)) {
		xbGlobalDebug g = {};
		// named like LLVM's: `pkg::name`, or the link name of an exported one
		g.name = s->name;
		if (!e->Variable.is_export && (e->flags & EntityFlag_CustomLinkName) == 0 && e->file != nullptr) {
			gbString name = lb_debug_append_name_prefix(gb_string_make(heap_allocator(), ""), e->file, e);
			name = gb_string_append_length(name, e->token.string.text, e->token.string.len);
			g.name = copy_string(permanent_allocator(), make_string(cast(u8 *)name, gb_string_length(name)));
			gb_string_free(name);
		}
		g.type = e->type;
		g.sym = sym;
		g.file_id = xb_file_id(m, e->token.pos.file_id);
		g.line = e->token.pos.line;
		array_add(&m->global_debug, g);
	}
	return true;
}

// Integer-like constants as DWARF variables, like lb_add_debug_info_for_global_constant_from_entity.
gb_internal void xb_add_debug_constant(xbModule *m, Entity *e) {
	if (e == nullptr || e->kind != Entity_Constant || is_blank_ident(e->token)) return;
	ExactValue const &value = e->Constant.value;
	if (value.kind != ExactValue_Integer && value.kind != ExactValue_Bool) return;
	Type *t = e->type;
	if (!is_type_integer(t) && !is_type_rune(t) && !is_type_boolean(t) && !is_type_enum(t) && !is_type_pointer(t)) return;
	if ((value.kind == ExactValue_Bool) != is_type_boolean(t)) return;

	xbGlobalDebug g = {};
	g.sym = -1;
	if (value.kind == ExactValue_Bool) {
		g.value = value.value_bool;
		g.type = default_type(t);
	} else {
		bool neg = big_int_is_neg(&value.value_integer);
		g.value = neg ? exact_value_to_i64(value) : cast(i64)exact_value_to_u64(value);
		g.type = is_type_rune(t) ? t_rune : is_type_untyped(t) ? (neg ? t_i64 : t_u64) : default_type(t);
	}
	g.name = e->token.string;
	if (e->pkg && e->pkg->name.len > 0) {
		gbString s = string_canonical_entity_name(permanent_allocator(), e);
		g.name = make_string(cast(u8 const *)s, gb_string_length(s));
	}
	array_add(&m->global_debug, g);
	// the main package's and the builtin constants also go by their plain name
	if ((e->pkg && e->pkg->kind == Package_Init) || (e->scope && (e->scope->flags & ScopeFlag_Global))) {
		g.name = e->token.string;
		array_add(&m->global_debug, g);
	}
}

// LLVM leaves them to this backend.
gb_internal void xb_add_debug_constants(xbModule *m) {
	if (!build_context.ODIN_DEBUG) return;
	for (Entity *e : m->info->entities) {
		if (e->kind != Entity_Constant) continue;
		if ((e->scope->flags & ScopeFlag_File) == 0) continue;
		xb_add_debug_constant(m, e);
	}
	for (auto const &entry : builtin_pkg->scope->elements) {
		xb_add_debug_constant(m, entry.value);
	}
}

gb_internal void xb_define_globals(xbModule *m) {
	CheckerInfo *info = m->info;
	// `type_table` comes with the type info data
	Entity *type_table = scope_lookup_current(info->runtime_package->scope, string_interner_insert(str_lit("type_table")));
	for (DeclInfo *d : info->variable_init_order) {
		Entity *e = d->entity;
		if ((e->scope->flags & ScopeFlag_File) == 0) continue;
		if (e->min_dep_count.load(std::memory_order_relaxed) == 0) continue;
		DeclInfo *decl = decl_info_of_entity(e);
		if (decl == nullptr) continue;
		if (e->Variable.is_foreign) {
			xb_note_foreign_library(m, e->Variable.foreign_library);
			continue;
		}
		if (e == type_table) continue;

		m->stats.globals_total += 1;
		char const *reason = nullptr;
		if (xb_define_global(m, e, decl, &reason)) {
			m->stats.globals_defined += 1;
			ptr_set_add(&m->handled, e);
		} else {
			xb_stat_fail(m, reason ? reason : "global");
			xb_log_fallback(m, "global", xb_entity_name(m, e), e->token.pos, reason);
		}
	}
}

////////////////////////////////////////////////////////////////
// Startup and cleanup
////////////////////////////////////////////////////////////////

gb_internal bool xb_global_needs_init(Entity *e, DeclInfo *decl) {
	return decl->init_expr != nullptr && !lb_global_variable_has_constant_init(e, decl);
}

// A port of lb_init_global_var, for the globals in init order, then the @(init) procedures.
gb_internal void xb_startup_body(xbProc *p) {
	CheckerInfo *info = p->m->info;
	if (build_context.metrics.os == TargetOs_darwin) {
		// the Objective-C setup comes first, as in lb_create_startup_runtime
		Type *pt = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_CDecl);
		i32 sym = xb_symbol(p->m, str_lit("__$init_objc_names"));
		p->m->symbols[sym].flags |= xbSymbolFlag_Func;
		xbValue f = xb_value_reg(pt, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)sym)));
		xb_emit_call_internal(p, f, sym, {});
	}
	for (DeclInfo *d : info->variable_init_order) {
		Entity *e = d->entity;
		if ((e->scope->flags & ScopeFlag_File) == 0) continue;
		if (e->min_dep_count.load(std::memory_order_relaxed) == 0) continue;
		DeclInfo *decl = decl_info_of_entity(e);
		if (decl == nullptr || !xb_global_needs_init(e, decl)) continue;

		Ast *init_expr = decl->init_expr;
		xbValue v = xb_build_expr(p, init_expr);
		if (is_type_untyped_nil(v.type)) continue;
		if (is_type_tuple(v.type)) XB_UNSUPPORTED(p, "tuple global initializer");
		xbMem g = xb_global_mem(p, e);
		Type *t = e->type;
		if (is_type_any(t) && !is_type_any(v.type) && init_expr->tav.mode != Addressing_Variable) {
			// the value gets its own global for the `any` to point at
			Type *vt = default_type(v.type);
			xbMem s = xb_static_storage(p, vt);
			xb_store_value(p, s, xb_emit_conv(p, v, vt));
			xb_store(p, xbType_I64, g, xb_lea(p, s));
			xb_store_value(p, xb_mem_offset(g, 8), xb_typeid_value(p, vt));
		} else {
			xb_store_value(p, g, xb_emit_conv(p, v, t));
		}
	}
	for (Entity *e : info->init_procedures) {
		xbValue f = xb_proc_value_from_entity(p, e);
		xb_emit_call(p, f, {}, nullptr);
	}
}

gb_internal void xb_cleanup_body(xbProc *p) {
	for (Entity *e : p->m->info->fini_procedures) {
		xbValue f = xb_proc_value_from_entity(p, e);
		xb_emit_call(p, f, {}, nullptr);
	}
}

// One of the runtime's startup procedures, a procedure without parameters.
gb_internal bool xb_build_runtime_proc(xbModule *m, String name, void (*body)(xbProc *), char const **reason, ProcCallingConvention cc=ProcCC_Odin) {
	xbFamily family = {};
	xb_family_init(&family, nullptr);
	defer (xb_family_destroy(&family));

	Type *pt = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, cc);
	xbProc *p = xb_new_proc(m, name, pt);
	p->family = &family;
	p->is_startup = true;
	jmp_buf bail;
	p->bail = &bail;
	if (setjmp(bail) != 0) {
		*reason = p->fail_reason;
		return false;
	}
	p->abi = xb_get_abi(p, pt);
	p->sym = xb_symbol(m, name);
	xb_begin_proc(p);
	body(p);
	xb_end_proc(p);
	array_add(&family.procs, p);

	if (!xb_family_build(m, &family, nullptr, reason)) {
		return false;
	}
	// hidden, so a shared library calls its own
	m->symbols[p->sym].flags = xbSymbolFlag_Global | xbSymbolFlag_Func | xbSymbolFlag_Weak | xbSymbolFlag_Hidden;
	xb_family_lower(m, &family, nullptr);
	return true;
}

gb_internal void xb_build_startup(xbModule *m) {
	char const *reason = nullptr;
	// cleanup first: if the startup fails, LLVM's weak copy of the cleanup is the same
	if (!xb_build_runtime_proc(m, str_lit("__$cleanup_runtime"), xb_cleanup_body, &reason)) {
		xb_stat_fail(m, reason ? reason : "cleanup");
		xb_log_fallback(m, "runtime procedure", str_lit("__$cleanup_runtime"), {}, reason);
		return;
	}
	if (!xb_build_runtime_proc(m, str_lit("__$startup_runtime"), xb_startup_body, &reason)) {
		xb_stat_fail(m, reason ? reason : "startup");
		xb_log_fallback(m, "runtime procedure", str_lit("__$startup_runtime"), {}, reason);
		return;
	}
	m->owns_startup = true;
}

////////////////////////////////////////////////////////////////
// The test runner's main, a port of lb_create_main_procedure for `odin test`
////////////////////////////////////////////////////////////////

gb_global Entity *xb_main_params[2];

gb_internal void xb_test_main_body(xbProc *p) {
	xbModule *m = p->m;
	CheckerInfo *info = m->info;

	// runtime.args__ = argv[:argc]
	xbVar *argc = map_get(&p->vars, xb_main_params[0]);
	xbVar *argv = map_get(&p->vars, xb_main_params[1]);
	GB_ASSERT(argc && argv && !argc->indirect && !argv->indirect);
	u32 count = xb_int_resize(p, xb_load(p, xbType_I32, argc->mem), xbType_I32, xbType_I64, true);
	u32 data = xb_load(p, xbType_I64, argv->mem);
	xbMem args = xb_global_mem(p, xb_lookup_runtime_entity(m, "args__"));
	xb_store(p, xbType_I64, args, data);
	xb_store(p, xbType_I64, xb_mem_offset(args, 8), count);

	Type *startup_type = alloc_type_proc(nullptr, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
	i32 startup = xb_symbol(m, str_lit("__$startup_runtime"));
	m->symbols[startup].flags |= xbSymbolFlag_Func;
	xb_emit_call(p, xb_value_reg(startup_type, xb_lea(p, xb_mem(xbMem_Sym, cast(u32)startup))), {}, nullptr);

	// the tests, as constant data
	Type *t_internal_test = find_type_in_pkg(info, str_lit("testing"), str_lit("Internal_Test"));
	Type *it = base_type(t_internal_test);
	isize n = info->testing_procedures.count;
	i64 stride = type_size_of(it);
	i32 tests = -1;
	if (n > 0) {
		xbBlob blob = xb_blob_make(m, stride*n);
		for (isize i = 0; i < n; i++) {
			Entity *tp = info->testing_procedures[i];
			i64 at = i*stride;
			String pkg_name = tp->pkg ? tp->pkg->name : String{};
			if (pkg_name.len > 0 && !xb_cb_write(&blob.b, t_string, exact_value_string(pkg_name), at + type_offset_of(it, 0))) {
				XB_UNSUPPORTED(p, "test name");
			}
			if (!xb_cb_write(&blob.b, t_string, exact_value_string(tp->token.string), at + type_offset_of(it, 1))) {
				XB_UNSUPPORTED(p, "test name");
			}
			i32 sym = xb_symbol(m, xb_entity_name(m, tp));
			m->symbols[sym].flags |= xbSymbolFlag_Func;
			xb_blob_ptr(&blob, at + type_offset_of(it, 2), sym);
		}
		tests = xb_blob_finish(m, &blob, type_align_of(it));
	}
	Type *slice_type = alloc_type_slice(t_internal_test);
	u32 tests_ptr = tests >= 0 ? xb_lea(p, xb_mem(xbMem_Sym, cast(u32)tests)) : xb_iconst(p, xbType_I64, 0);
	xbValue all_tests = xb_make_slice_value(p, slice_type, tests_ptr, xb_iconst(p, xbType_I64, n));

	Entity *runner = find_entity_in_pkg(info, str_lit("testing"), str_lit("runner"));
	xbValue run_args[1] = {all_tests};
	xbValue ok = xb_emit_call(p, xb_proc_value_from_entity(p, runner), xb_args(run_args, 1), nullptr);

	Entity *exit_entity = xb_lookup_runtime_entity(m, "exit");
	u32 code = xb_select(p, xbType_I64, xb_to_bool_reg(p, ok), xb_iconst(p, xbType_I64, 0), xb_iconst(p, xbType_I64, 1));
	xbValue exit_args[1] = {xb_value_reg(t_int, code)};
	xb_emit_call(p, xb_proc_value_from_entity(p, exit_entity), xb_args(exit_args, 1), nullptr);
}

gb_internal void xb_build_test_main(xbModule *m) {
	if (build_context.command_kind != Command_test) return;
	if (xb_is_win64() && (build_context.no_crt || build_context.build_mode == BuildMode_DynamicLibrary)) {
		// LLVM's has another name and signature there
		xb_stat_fail(m, "test main without the crt");
		return;
	}
	// the runtime may bring its own entry point
	for (Entity *e : m->info->entities) {
		if (e->kind != Entity_Procedure || e->pkg == nullptr || e->pkg->kind != Package_Runtime) continue;
		if (!e->Procedure.is_export && e->Procedure.link_name.len == 0) continue;
		String ln = e->Procedure.link_name;
		if (ln == "main" || ln == "_main" || ln == "DllMain" || ln == "WinMain" ||
		    ln == "wWinMain" || ln == "mainCRTStartup" || ln == "_start") {
			m->test_main_not_needed = true;
			return;
		}
	}

	Type *params = alloc_type_tuple();
	Type *results = alloc_type_tuple();
	slice_init(&params->Tuple.variables, permanent_allocator(), 2);
	xb_main_params[0] = alloc_entity_param(nullptr, make_token_ident("argc"), t_i32, false, true);
	xb_main_params[1] = alloc_entity_param(nullptr, make_token_ident("argv"), alloc_type_pointer(t_cstring), false, true);
	params->Tuple.variables[0] = xb_main_params[0];
	params->Tuple.variables[1] = xb_main_params[1];
	slice_init(&results->Tuple.variables, permanent_allocator(), 1);
	results->Tuple.variables[0] = alloc_entity_param(nullptr, blank_token, t_i32, false, true);
	Type *pt = alloc_type_proc(nullptr, params, 2, results, 1, false, ProcCC_CDecl);

	xbFamily family = {};
	xb_family_init(&family, nullptr);
	defer (xb_family_destroy(&family));

	char const *reason = nullptr;
	xbProc *p = xb_new_proc(m, str_lit("main"), pt);
	p->family = &family;
	jmp_buf bail;
	p->bail = &bail;
	if (setjmp(bail) != 0) {
		reason = p->fail_reason;
	} else {
		p->abi = xb_get_abi(p, pt);
		p->sym = xb_symbol(m, p->name);
		xb_begin_proc(p);
		xb_test_main_body(p);
		xb_end_proc(p);
		array_add(&family.procs, p);
		if (xb_family_build(m, &family, nullptr, &reason)) {
			m->symbols[p->sym].flags = xbSymbolFlag_Global | xbSymbolFlag_Func;
			xb_family_lower(m, &family, nullptr);
			m->owns_test_main = true;
			return;
		}
	}
	xb_stat_fail(m, reason ? reason : "test main");
	xb_log_fallback(m, "procedure", str_lit("main (test runner)"), {}, reason);
}
