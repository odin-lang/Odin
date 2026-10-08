// Driver for the x64 debug backend.
//
// Runs after the LLVM backend has collected the procedures to generate and
// before it builds any bodies. Every procedure compiled here is only declared
// on the LLVM side.

#include "x64_backend.hpp"
#include "x64_encode.cpp"
#include "x64_abi.cpp"
#include "x64_gen.cpp"
#include "x64_const.cpp"
#include "x64_gen_expr.cpp"
#include "x64_gen_stmt.cpp"
#include "x64_gen_procs.cpp"
#include "x64_lower.cpp"
#include "x64_type_info.cpp"
#include "x64_globals.cpp"
#include "x64_elf.cpp"

gb_global xbModule *xb_module = nullptr;
gb_global f64 xb_time_build = 0;
gb_global f64 xb_time_lower = 0;
gb_global f64 xb_time_write = 0;

gb_internal void lb_add_foreign_library_path(lbModule *m, Entity *e);

gb_internal bool xb_is_enabled(void) {
	return build_context.backend == Backend_X64;
}

gb_internal bool xb_handles(Entity *e) {
	if (xb_module == nullptr) return false;
	return ptr_set_exists(&xb_module->handled, e);
}

gb_internal bool xb_owns_startup(void) {
	return xb_module != nullptr && xb_module->owns_startup;
}

gb_internal bool xb_owns_test_main(void) {
	return xb_module != nullptr && xb_module->owns_test_main;
}

gb_internal bool xb_owns_type_info(void) {
	return xb_module != nullptr && xb_module->owns_type_info;
}

gb_internal String xb_entity_name(xbModule *m, Entity *e) {
	return lb_get_entity_name(&m->gen->default_module, e);
}


gb_internal void xb_stat_fail(xbModule *m, char const *reason) {
	String key = make_string_c(reason);
	isize *found = string_map_get(&m->stats.fail_reasons, key);
	if (found) {
		*found += 1;
	} else {
		string_map_set(&m->stats.fail_reasons, key, cast(isize)1);
	}
}

// Whether the procedure is something this backend should try at all.
gb_internal bool xb_proc_is_candidate(Entity *e) {
	if (e->kind != Entity_Procedure) return false;
	if (e->Procedure.is_foreign) return false;
	if (e->Procedure.is_objc_impl_or_import) return false;
	if (e->flags & EntityFlag_Disabled) return false;
	DeclInfo *d = e->decl_info;
	if (d == nullptr || d->proc_lit == nullptr) return false;
	if (d->proc_lit->ProcLit.body == nullptr) return false;
	if (is_type_polymorphic(e->type) && !base_type(e->type)->Proc.is_poly_specialized) return false;
	if ((e->flags & EntityFlag_ProcBodyChecked) == 0) return false;
	return true;
}

// Builds the IR of one procedure. Nothing is emitted yet.
gb_internal xbProc *xb_new_proc(xbModule *m, String name, Type *type) {
	xbProc *p = xb_alloc_item<xbProc>();
	p->m = m;
	p->type = type;
	p->name = name;
	p->vregs = array_make<xbType>(xb_allocator(), 0, 256);
	array_add(&p->vregs, xbType_None); // vreg 0 is invalid
	p->blocks = array_make<xbBlock *>(xb_allocator(), 0, 32);
	p->order = array_make<xbBlock *>(xb_allocator(), 0, 32);
	p->locals = array_make<xbLocal>(xb_allocator(), 0, 32);
	p->calls = array_make<xbCall>(xb_allocator(), 0, 32);
	p->params_in = array_make<xbParamIn>(xb_allocator(), 0, 8);
	p->context_stack = array_make<xbContextEntry>(xb_allocator(), 0, 4);
	p->defers = array_make<xbDefer>(xb_allocator(), 0, 4);
	p->branch_blocks = array_make<xbBranchBlocks>(xb_allocator(), 0, 0);
	p->debug_vars = array_make<xbDebugVar>(xb_allocator(), 0, 16);
	map_init(&p->vars);
	p->file_id = -1;
	return p;
}

gb_internal xbProc *xb_build_proc(xbModule *m, Entity *e, xbFamily *family, char const **reason) {
	xbProc *p = xb_new_proc(m, xb_entity_name(m, e), e->type);
	p->family = family;
	p->entity = e;
	p->decl = e->decl_info;
	p->body = p->decl->proc_lit->ProcLit.body;

	jmp_buf bail;
	p->bail = &bail;
	if (setjmp(bail) != 0) {
		*reason = p->fail_reason;
		return nullptr;
	}

	Type *pt = base_type(e->type);
	if (pt->Proc.calling_convention == ProcCC_Naked) XB_UNSUPPORTED(p, "naked procedure");
	if (e->Procedure.link_section.len != 0) XB_UNSUPPORTED(p, "link section");
	if (e->Procedure.has_instrumentation && m->info->instrumentation_enter_entity != nullptr) XB_UNSUPPORTED(p, "instrumentation");
	if (e->Procedure.uses_branch_location) XB_UNSUPPORTED(p, "branch location");
	if (build_context.sanitizer_flags != 0) XB_UNSUPPORTED(p, "sanitizers");
	if (e->flags & EntityFlag_CustomLinkage_Internal) XB_UNSUPPORTED(p, "internal linkage");

	p->abi = xb_get_abi(p, e->type);
	p->sym = xb_symbol(m, p->name);

	xb_begin_proc(p);
	xb_build_stmt(p, p->body);
	xb_end_proc(p);
	return p;
}

gb_internal void xb_family_cleanup(xbFamily *family) {
	for (xbProc *fp : family->procs) {
		map_destroy(&fp->vars);
	}
	array_free(&family->procs);
	xb_arena_reset();
}

gb_internal void xb_family_init(xbFamily *family, DeclInfo *root_decl) {
	family->root_decl = root_decl;
	family->queue = array_make<Entity *>(heap_allocator(), 0, 4);
	family->procs = array_make<xbProc *>(heap_allocator(), 0, 4);
	ptr_set_init(&family->seen);
	ptr_set_init(&family->roots);
	ptr_set_init(&family->on_demand);
	if (root_decl) ptr_set_add(&family->roots, root_decl);
}

gb_internal void xb_family_destroy(xbFamily *family) {
	ptr_set_destroy(&family->roots);
	ptr_set_destroy(&family->on_demand);
	array_free(&family->queue);
	ptr_set_destroy(&family->seen);
	xb_family_cleanup(family);
}

// Builds every queued procedure of the family; `root` is the one that must not exist yet.
gb_internal bool xb_family_build(xbModule *m, xbFamily *family, Entity *root, char const **reason) {
	for (isize i = 0; i < family->queue.count; i++) {
		Entity *fe = family->queue[i];
		String name = xb_entity_name(m, fe);
		i32 *existing = string_map_get(&m->symbol_map, name);
		if (existing && m->symbols[*existing].section != xbSection_Undef) {
			if (fe == root) {
				*reason = "duplicate symbol";
				return false;
			}
			continue; // an anonymous procedure another family already compiled
		}
		f64 t0 = gb_time_now();
		xbProc *p = xb_build_proc(m, fe, family, reason);
		xb_time_build += gb_time_now() - t0;
		if (p == nullptr) {
			if (fe != root && m->verbose) {
				gb_printf_err("xb:   nested %.*s failed: %s\n", LIT(name), *reason);
			}
			return false;
		}
		array_add(&family->procs, p);
	}
	return true;
}

gb_internal void xb_family_lower(xbModule *m, xbFamily *family, Entity *root) {
	for (xbProc *p : family->procs) {
		Entity *pe = p->entity;
		xbSymbol *s = &m->symbols[p->sym];
		if (pe != nullptr) {
			if (s->section != xbSection_Undef) continue;
			s->flags = xbSymbolFlag_Global | xbSymbolFlag_Func;
			if (!pe->Procedure.is_export) {
				s->flags |= xbSymbolFlag_Hidden;
			}
			if (pe->flags & (EntityFlag_CustomLinkage_Weak|EntityFlag_CustomLinkage_LinkOnce)) {
				s->flags |= xbSymbolFlag_Weak;
			}
			if (pe != root) {
				// LLVM may make its own copy, e.g. of an anonymous procedure for a default parameter
				s->flags |= xbSymbolFlag_Weak;
			}
			if (ptr_set_exists(&family->on_demand, pe)) {
				s->flags |= xbSymbolFlag_Hidden;
			}
		}
		f64 t0 = gb_time_now();
		xb_lower_proc(p);
		xb_time_lower += gb_time_now() - t0;
	}
}

// Compiles a procedure with everything nested in it, or nothing at all.
gb_internal bool xb_compile_proc(xbModule *m, Entity *e, char const **reason) {
	xbFamily family = {};
	xb_family_init(&family, e->decl_info);
	defer (xb_family_destroy(&family));

	xb_family_add(&family, e);
	if (!xb_family_build(m, &family, e, reason)) {
		return false;
	}
	xb_family_lower(m, &family, e);
	return true;
}

gb_internal String xb_object_path(lbGenerator *gen) {
	String dir = temporary_directory(permanent_allocator());
	if (dir.len == 0) {
		dir = build_context.build_paths[BuildPath_Output].basename;
	}
	gbString path = gb_string_make_length(heap_allocator(), dir.text, dir.len);
	path = gb_string_append_fmt(path, "/odin-x64-%p.o", gen);
	return make_string(cast(u8 *)path, gb_string_length(path));
}

gb_internal void xb_generate(lbGenerator *gen) {
	xbModule *m = permanent_alloc_item<xbModule>();
	xb_module = m;
	m->gen = gen;
	m->info = gen->info;
	m->symbols = array_make<xbSymbol>(heap_allocator(), 0, 4096);
	string_map_init(&m->symbol_map);
	for (isize i = 0; i < xbSection_COUNT; i++) {
		m->sections[i] = array_make<u8>(heap_allocator(), 0, i == xbSection_Text ? 1<<20 : 1<<14);
	}
	m->relocs = array_make<xbReloc>(heap_allocator(), 0, 1<<14);
	m->proc_debug = array_make<xbProcDebug>(heap_allocator(), 0, 1024);
	m->lines = array_make<xbLineEntry>(heap_allocator(), 0, 1<<14);
	m->files = array_make<String>(heap_allocator(), 0, 64);
	map_init(&m->file_ids);
	ptr_set_init(&m->handled);
	ptr_set_init(&m->foreign_libs_set);
	m->foreign_libs = array_make<Entity *>(heap_allocator(), 0, 16);
	ptr_set_init(&m->proc_queued);
	m->proc_queue = array_make<Entity *>(heap_allocator(), 0, 1024);
	map_init(&m->abi_cache);
	string_map_init(&m->string_lits);
	string_map_init(&m->stats.fail_reasons);

	m->limit = -1;
	if (char const *s = gb_get_env("ODIN_XB_LIMIT", permanent_allocator())) {
		m->limit = cast(i64)atoll(s);
	}
	char const *only = gb_get_env("ODIN_XB_ONLY", permanent_allocator());
	char const *skip = gb_get_env("ODIN_XB_SKIP", permanent_allocator());
	m->verbose = gb_get_env("ODIN_XB_VERBOSE", permanent_allocator()) != nullptr;

	xb_define_globals(m);

	// every procedure LLVM would generate, in a stable order
	// (the same filter as lb_create_global_procedures_and_types)
	auto candidates = array_make<Entity *>(heap_allocator(), 0, 4096);
	for (Entity *e : m->info->entities) {
		if (e->kind != Entity_Procedure) continue;
		Scope *scope = e->scope;
		if ((scope->flags & ScopeFlag_File) == 0) {
			if ((e->flags & EntityFlag_PolyConstArg) == 0) continue;
		}
		if (e->min_dep_count.load(std::memory_order_relaxed) == 0) continue;
		if (e->Procedure.is_foreign && e->Procedure.is_objc_impl_or_import) continue;
		array_add(&candidates, e);
	}
	array_sort(candidates, llvm_global_entity_cmp);

	for (Entity *e : candidates) {
		if (e->Procedure.is_foreign) {
			xb_note_foreign_library(m, e->Procedure.foreign_library);
		}
		if (!xb_proc_is_candidate(e)) continue;
		m->stats.procs_total += 1;
		if (m->limit >= 0 && m->stats.procs_compiled >= m->limit) {
			xb_stat_fail(m, "limit");
			continue;
		}
		String name = xb_entity_name(m, e);
		if (only && !string_contains_string(name, make_string_c(only))) {
			xb_stat_fail(m, "filtered");
			continue;
		}
		if (skip && string_contains_string(name, make_string_c(skip))) {
			xb_stat_fail(m, "skipped");
			continue;
		}

		char const *reason = nullptr;
		if (xb_compile_proc(m, e, &reason)) {
			m->stats.procs_compiled += 1;
			ptr_set_add(&m->handled, e);
			if (m->verbose) {
				gb_printf_err("xb: compiled %.*s\n", LIT(name));
			}
		} else {
			xb_stat_fail(m, reason ? reason : "unknown");
			if (m->verbose) {
				gb_printf_err("xb: fallback %.*s: %s\n", LIT(name), reason);
			}
		}
	}

	xb_build_startup(m);
	xb_build_type_info(m);
	xb_build_test_main(m);

	m->complete = m->stats.procs_compiled == m->stats.procs_total &&
	              m->stats.globals_defined == m->stats.globals_total &&
	              m->owns_startup &&
	              (m->owns_type_info || build_context.no_rtti) &&
	              (build_context.command_kind != Command_test || m->owns_test_main || m->test_main_not_needed);

	if (m->stats.procs_compiled > 0 || m->stats.globals_defined > 0) {
		m->object_path = xb_object_path(gen);
		f64 t0 = gb_time_now();
		if (!xb_write_object(m, m->object_path)) {
			gb_exit(1);
		}
		xb_time_write += gb_time_now() - t0;
	}

	if (gb_get_env("ODIN_XB_STATS", permanent_allocator()) != nullptr) {
		gb_printf_err("x64 backend: compiled %td of %td procedures\n", m->stats.procs_compiled, m->stats.procs_total);
		gb_printf_err("  globals %td of %td, startup %s, type info %s, test main %s%s\n", m->stats.globals_defined, m->stats.globals_total, m->owns_startup ? "x64" : "llvm", m->owns_type_info ? "x64" : "llvm", m->owns_test_main ? "x64" : "-", m->complete ? ", no LLVM" : "");
		gb_printf_err("  build %.3f ms, lower %.3f ms, write %.3f ms\n", xb_time_build*1000, xb_time_lower*1000, xb_time_write*1000);
		struct Reason { String name; isize count; };
		auto reasons = array_make<Reason>(heap_allocator(), 0, m->stats.fail_reasons.count);
		for (auto const &entry : m->stats.fail_reasons) {
			Reason r = {entry.key, entry.value};
			array_add(&reasons, r);
		}
		for (isize i = 0; i < reasons.count; i++) {
			for (isize j = i+1; j < reasons.count; j++) {
				if (reasons[j].count > reasons[i].count) {
					Reason t = reasons[i]; reasons[i] = reasons[j]; reasons[j] = t;
				}
			}
		}
		for (Reason const &r : reasons) {
			gb_printf_err("  %6td  %.*s\n", r.count, LIT(r.name));
		}
	}
}

gb_internal void xb_add_object(lbGenerator *gen) {
	if (xb_module == nullptr || xb_module->object_path.len == 0) return;
	array_add(&gen->output_object_paths, xb_module->object_path);
	// LLVM never sees what only this backend's procedures use
	for (Entity *lib : xb_module->foreign_libs) {
		lb_add_foreign_library_path(&gen->default_module, lib);
	}
}

gb_internal bool xb_is_complete(void) {
	return xb_module != nullptr && xb_module->complete;
}
