// Driver for the fast backend (`-backend:fast`).
//
// Runs after the LLVM backend has collected the procedures to generate and
// before it builds any bodies. Every procedure compiled here is only declared
// on the LLVM side.

#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable: 4611) // bailing out longjmps past destructors on purpose, the arenas own everything
#pragma warning(disable: 4702) // `return {};` after XB_UNSUPPORTED, which longjmps
#pragma warning(disable: 4201) // xbShadowOp's nameless struct in its union
#endif

#include "xb_backend.hpp"
#include "x64_encode.cpp"
#include "x64_abi.cpp"
#include "xb_gen.cpp"
#include "xb_const.cpp"
#include "xb_gen_expr.cpp"
#include "x64_asm.cpp"
#include "xb_gen_stmt.cpp"
#include "xb_gen_procs.cpp"
#include "xb_simd.cpp"
#include "xb_analysis.cpp"
#include "x64_lower.cpp"
#include "x64_win64.cpp"
#include "xb_type_info.cpp"
#include "xb_globals.cpp"
#include "xb_objc.cpp"
#include "xb_dwarf.cpp"
#include "x64_elf.cpp"
#include "x64_coff.cpp"
#include "a64_abi.cpp"
#include "a64_encode.cpp"
#include "a64_lower.cpp"
#include "xb_macho.cpp"

gb_global xbModule *xb_module = nullptr;
gb_global f64 xb_time_build = 0;
gb_global f64 xb_time_lower = 0;
gb_global f64 xb_time_write = 0;
gb_global f64 xb_time_globals = 0;
gb_global f64 xb_time_procs = 0;
gb_global f64 xb_time_extra = 0;
gb_global f64 xb_time_total = 0;

// procedures lowered together; more keeps the threads busier, fewer keeps less IR in memory
enum : isize { XB_LOWER_BATCH = 1024 };

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

// always printed: what fell back to LLVM, where, and why
gb_internal void xb_log_fallback(xbModule *m, char const *what, String name, TokenPos fallback_pos, char const *reason) {
	TokenPos pos = m->fail_pos.line > 0 ? m->fail_pos : fallback_pos;
	m->fail_pos = {};
	String file = pos.file_id > 0 ? get_file_path_string(pos.file_id) : str_lit("");
	if (file.len > 0) {
		gb_printf_err("%.*s(%d:%d) fast backend: %s %.*s falls back to LLVM: %s\n", LIT(file), pos.line, pos.column, what, LIT(name), reason ? reason : "unknown");
	} else {
		gb_printf_err("fast backend: %s %.*s falls back to LLVM: %s\n", what, LIT(name), reason ? reason : "unknown");
	}
}

// A shadow's name for an entity's symbol: only the real module decides the name, see below.
gb_internal String xb_shadow_entity_name(xbModule *m, Entity *e) {
	if (xb_shadow_logs(m) && !xb_shadow_seen(m, xbShadowOp_EntityName, cast(u64)cast(uintptr)e)) {
		xb_shadow_log(m, xbShadowOp_EntityName)->ptr = e;
	}
	if (String *cached = map_get(&m->entity_names, e)) return *cached;
	char buf[32] = {};
	gb_snprintf(buf, gb_size_of(buf), "\x01%016llx", cast(unsigned long long)cast(uintptr)e);
	String name = copy_string(permanent_allocator(), make_string_c(buf));
	map_set(&m->entity_names, e, name);
	return name;
}

// The entity whose shadow name this is, or nullptr.
gb_internal Entity *xb_shadow_name_entity(String name) {
	if (name.len != 17 || name[0] != 1) return nullptr;
	u64 v = 0;
	for (isize i = 1; i < name.len; i++) {
		u8 c = name[i];
		v = v*16 + (c <= '9' ? c - '0' : c - 'a' + 10);
	}
	return cast(Entity *)cast(uintptr)v;
}

gb_internal String xb_entity_name(xbModule *m, Entity *e) {
	if (m->real != nullptr) return xb_shadow_entity_name(m, e);
	String *cached = map_get(&m->entity_names, e);
	if (cached) return *cached;
	String name = lb_get_entity_name(&m->gen->default_module, e);
	if (e->kind == Entity_Procedure && !e->Procedure.is_foreign && !e->Procedure.is_export) {
		Entity **owner = string_map_get(&m->name_owners, name);
		if (owner == nullptr) {
			string_map_set(&m->name_owners, name, e);
		} else if ((*owner)->token.pos.file_id != e->token.pos.file_id) {
			// file-private procedures of the same name in one package get the same name from LLVM
			String file = filename_without_directory(get_file_path_string(e->token.pos.file_id));
			gbString s = gb_string_make_length(permanent_allocator(), name.text, name.len);
			s = gb_string_append_fmt(s, "$%.*s", LIT(file));
			name = make_string(cast(u8 *)s, gb_string_length(s));
		}
	}
	map_set(&m->entity_names, e, name);
	return name;
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
	if (e->flags & EntityFlag_Disabled) return false;
	DeclInfo *d = e->decl_info;
	if (d == nullptr || d->proc_lit == nullptr) return false;
	if (d->proc_lit->ProcLit.body == nullptr) return false;
	if (is_type_polymorphic(e->type) && !base_type(e->type)->Proc.is_poly_specialized) return false;
	if ((e->flags & EntityFlag_ProcBodyChecked) == 0) return false;
	return true;
}

struct xbCandidateCheck {
	Entity *e;
	bool    ok;
};

gb_internal void xb_candidate_checks(xbCandidateCheck *checks, isize count) {
	for (isize i = 0; i < count; i++) checks[i].ok = xb_proc_is_candidate(checks[i].e);
}

// Builds the IR of one procedure. Nothing is emitted yet.
gb_internal xbProc *xb_new_proc(xbModule *m, String name, Type *type) {
	xbProc *p = xb_alloc_item<xbProc>();
	p->va_save_local = -1;
	p->m = m;
	p->type = type;
	p->name = name;
	p->vregs = array_make<xbType>(xb_allocator(), 0, 256);
	array_add(&p->vregs, xbType_None); // vreg 0 is invalid
	p->vinfo = array_make<xbVregInfo>(xb_allocator(), 0, 256);
	xbVregInfo none = {0, ~0ull, false};
	array_add(&p->vinfo, none);
	p->blocks = array_make<xbBlock *>(xb_allocator(), 0, 32);
	p->order = array_make<xbBlock *>(xb_allocator(), 0, 32);
	p->locals = array_make<xbLocal>(xb_allocator(), 0, 32);
	p->calls = array_make<xbCall>(xb_allocator(), 0, 32);
	p->asms = array_make<xbAsmBlock>(xb_allocator(), 0, 0);
	p->params_in = array_make<xbParamIn>(xb_allocator(), 0, 8);
	p->context_stack = array_make<xbContextEntry>(xb_allocator(), 0, 4);
	p->defers = array_make<xbDefer>(xb_allocator(), 0, 4);
	p->branch_blocks = array_make<xbBranchBlocks>(xb_allocator(), 0, 0);
	p->selector_cache = array_make<xbSelectorCache>(xb_allocator(), 0, 0);
	p->debug_vars = array_make<xbDebugVar>(xb_allocator(), 0, 16);
	p->debug_scope_parent = array_make<i32>(xb_allocator(), 0, 8);
	p->inline_sites = array_make<xbInlineSite>(xb_allocator(), 0, 0);
	array_add(&p->debug_scope_parent, -1);
	map_init(&p->vars);
	p->file_id = -1;
	m->fail_pos = {};
	return p;
}

// A naked body has no frame, so it may only hold asm calls on constants, constant declarations,
// traps and bare returns, like what the LLVM backend accepts. Returns why not, or nullptr.
gb_internal char const *xb_naked_stmt_reason(Ast *node, bool has_results) {
	if (node == nullptr) return nullptr;
	switch (node->kind) {
	case Ast_EmptyStmt:
		return nullptr;
	case Ast_BlockStmt:
		for (Ast *s : node->BlockStmt.stmts) {
			if (char const *r = xb_naked_stmt_reason(s, has_results)) return r;
		}
		return nullptr;
	case Ast_WhenStmt: {
		char const *r = xb_naked_stmt_reason(node->WhenStmt.body, has_results);
		return r ? r : xb_naked_stmt_reason(node->WhenStmt.else_stmt, has_results);
	}
	case Ast_ValueDecl:
		if (node->ValueDecl.is_mutable) return "naked procedure: variable";
		return nullptr;
	case Ast_ReturnStmt:
		if (has_results) return "naked procedure: return with results";
		return nullptr;
	case Ast_ExprStmt: {
		Ast *call = unparen_expr(node->ExprStmt.expr);
		if (call->kind != Ast_CallExpr) break;
		Entity *pe = entity_of_node(unparen_expr(call->CallExpr.proc));
		if (pe == nullptr) break;
		if (pe->kind == Entity_Builtin) {
			switch (pe->Builtin.id) {
			case BuiltinProc_trap:
			case BuiltinProc_debug_trap:
			case BuiltinProc_unreachable:
				return nullptr;
			}
			break;
		}
		if (pe->kind != Entity_AsmTemplate) break;
		for (Ast *arg : call->CallExpr.args) {
			if (arg->kind == Ast_FieldValue) arg = arg->FieldValue.value;
			if (type_and_value_of_expr(arg).mode != Addressing_Constant) return "naked procedure: asm operand";
		}
		return nullptr;
	}
	}
	return xb_asm_reason("naked procedure:", ast_strings[node->kind]);
}

// What the naked body built into must need no frame either.
gb_internal void xb_check_naked(xbProc *p) {
	for (xbAsmBlock const &blk : p->asms) {
		if (blk.inputs.count != 0 || blk.outputs.count != 0) XB_UNSUPPORTED(p, "naked procedure: asm operand");
	}
	if (p->locals.count != 0) XB_UNSUPPORTED(p, "naked procedure: stack slot");
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			switch (in.op) {
			case xbOp_Nop:
			case xbOp_Loc:
			case xbOp_Scope:
			case xbOp_Jump:
			case xbOp_Unreachable:
			case xbOp_Trap:
			case xbOp_DebugTrap:
			case xbOp_Asm:
				continue;
			case xbOp_Ret:
				if (p->calls[cast(isize)in.imm].args.count != 0) XB_UNSUPPORTED(p, "naked procedure: return with results");
				continue;
			}
			XB_UNSUPPORTED(p, "naked procedure: stack slot");
		}
	}
}

gb_internal xbProc *xb_build_proc(xbModule *m, Entity *e, xbFamily *family, char const **reason) {
	xbProc *p = xb_new_proc(m, xb_entity_name(m, e), e->type);
	p->family = family;
	p->entity = e;
	p->decl = e->decl_info;
	p->body = p->decl->proc_lit->ProcLit.body;

	isize shadow_depth = xb_shadow_depth(m);
	jmp_buf bail;
	p->bail = &bail;
	if (setjmp(bail) != 0) {
		xb_shadow_unwind(m, shadow_depth);
		*reason = p->fail_reason;
		return nullptr;
	}

	Type *pt = base_type(e->type);
	if (pt->Proc.calling_convention == ProcCC_Naked) {
		if (!xb_asm_target_ok()) XB_UNSUPPORTED(p, "naked procedure");
		p->naked = true;
		if (char const *r = xb_naked_stmt_reason(p->body, pt->Proc.result_count != 0)) XB_UNSUPPORTED(p, r);
	}
	if (e->Procedure.link_section.len != 0) XB_UNSUPPORTED(p, "link section");
	if (e->Procedure.has_instrumentation && m->info->instrumentation_enter_entity != nullptr) XB_UNSUPPORTED(p, "instrumentation");
	if (build_context.sanitizer_flags != 0) XB_UNSUPPORTED(p, "sanitizers");
	if (e->flags & EntityFlag_CustomLinkage_Internal) XB_UNSUPPORTED(p, "internal linkage");

	p->abi = xb_get_abi(p, e->type);
	p->sym = xb_symbol(m, p->name);

	xb_begin_proc(p);
	xb_build_stmt(p, p->body);
	xb_end_proc(p);
	if (p->naked) xb_check_naked(p);
	return p;
}

gb_internal void xb_family_cleanup(xbFamily *family) {
	for (xbProc *fp : family->procs) {
		map_destroy(&fp->vars);
	}
	array_free(&family->procs);
}

gb_internal void xb_family_init(xbFamily *family, DeclInfo *root_decl) {
	family->root_decl = root_decl;
	family->queue = array_make<Entity *>(heap_allocator(), 0, 4);
	family->procs = array_make<xbProc *>(heap_allocator(), 0, 4);
	ptr_set_init(&family->seen);
	ptr_set_init(&family->roots);
	ptr_set_init(&family->on_demand);
	map_init(&family->statics);
	if (root_decl) ptr_set_add(&family->roots, root_decl);
}

gb_internal void xb_family_destroy(xbFamily *family) {
	ptr_set_destroy(&family->roots);
	ptr_set_destroy(&family->on_demand);
	map_destroy(&family->statics);
	array_free(&family->queue);
	ptr_set_destroy(&family->seen);
	xb_family_cleanup(family);
}

// Builds every queued procedure of the family; `root` is the one that must not exist yet.
gb_internal bool xb_family_build(xbModule *m, xbFamily *family, Entity *root, char const **reason) {
	for (isize i = 0; i < family->queue.count; i++) {
		Entity *fe = family->queue[i];
		String name = xb_entity_name(m, fe);
		i32 *existing = xb_symbol_find(m, name);
		if (existing && m->symbols[*existing].section != xbSection_Undef) {
			if (fe == root && !ptr_set_exists(&m->defined_procs, fe)) {
				*reason = "duplicate symbol";
				return false;
			}
			// already compiled with the family of the procedure it is nested in, or another
			// family's copy of an anonymous procedure
			continue;
		}
		f64 t0 = gb_time_now();
		xb_shadow_begin(m, xbShadowSeg_Proc, fe, 0, fe == root);
		xbProc *p = xb_build_proc(m, fe, family, reason);
		xb_shadow_end(m, 0, p == nullptr);
		if (m->real == nullptr) xb_time_build += gb_time_now() - t0;
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

gb_internal void xb_add_defined_proc(xbModule *m, Entity *e) {
	ptr_set_add(&m->defined_procs, e);
	if (xb_shadow_logs(m)) {
		xb_shadow_log(m, xbShadowOp_DefinedProc)->ptr = e;
	}
}

gb_internal void xb_family_lower(xbModule *m, xbFamily *family, Entity *root) {
	for (xbProc *p : family->procs) {
		Entity *pe = p->entity;
		xbSymbol *s = &m->symbols[p->sym];
		if (pe != nullptr) {
			if (s->section != xbSection_Undef) continue;
			// a serial build skipped it if another family built it before
			xb_shadow_begin(m, xbShadowSeg_FamilyLower, pe);
			xb_add_defined_proc(m, pe);
			u8 flags = xbSymbolFlag_Global | xbSymbolFlag_Func;
			if (!pe->Procedure.is_export) {
				flags |= xbSymbolFlag_Hidden;
			} else {
				flags |= xbSymbolFlag_Export;
			}
			if (pe->flags & (EntityFlag_CustomLinkage_Weak|EntityFlag_CustomLinkage_LinkOnce)) {
				flags |= xbSymbolFlag_Weak;
			}
			if (pe != root) {
				// LLVM may make its own copy, e.g. of an anonymous procedure for a default parameter
				flags |= xbSymbolFlag_Weak;
			}
			if (ptr_set_exists(&family->on_demand, pe)) {
				flags |= xbSymbolFlag_Hidden;
			}
			xb_sym_set_flags(m, p->sym, flags);
			xb_lower_proc(p);
			xb_shadow_end(m);
			continue;
		}
		xb_lower_proc(p);
	}
}

// Queues p for lowering. It counts as defined from here on, so it is built only once; its code
// and offset come with xb_lower_flush.
gb_internal void xb_lower_proc(xbProc *p) {
	xbModule *m = p->m;
	if (m->real != nullptr) {
		m->shadow_quiet += 1;
		xb_sym_define(m, p->sym, xbSection_Text, 0, 0);
		xb_sym_add_flags(m, p->sym, xbSymbolFlag_Func);
		m->shadow_quiet -= 1;
		if (xb_shadow_logs(m)) {
			xb_shadow_log(m, xbShadowOp_Lower)->ptr = p;
		}
		return;
	}
	xb_sym_define(m, p->sym, xbSection_Text, 0, 0);
	xb_sym_add_flags(m, p->sym, xbSymbolFlag_Func);
	xbLowerJob job = {};
	job.p = p;
	array_add(&m->lower_jobs, job);
	m->lower_queued += 1;
}

gb_internal i32 xb_remap_sym(xbRemap const *rm, i64 sym) {
	i32 s = rm->syms[sym];
	GB_ASSERT_MSG(s >= 0, "fast backend: shadow symbol %lld has no real symbol", cast(long long)sym);
	return s;
}

gb_internal i32 xb_remap_file(xbRemap const *rm, i32 id) {
	return id > 0 ? rm->files[id] : id;
}

gb_internal void xb_remap_mem(xbRemap const *rm, xbMem *mem) {
	if (mem->kind == xbMem_Sym) mem->base = cast(u32)xb_remap_sym(rm, mem->base);
}

// Renumbers the shadow's symbols and file ids in IR a shadow built. The replay did the rest of
// the procedure, which needs the module.
gb_internal void xb_remap_proc(xbProc *p, xbRemap const *rm) {
	p->file_id = xb_remap_file(rm, p->file_id);
	for (xbBlock *b : p->blocks) {
		for (xbInstr &in : b->instrs) {
			xb_remap_mem(rm, &in.mem);
			if (in.op == xbOp_TlsAddr) in.imm = xb_remap_sym(rm, in.imm);
			if (in.op == xbOp_Loc) in.a = cast(u32)xb_remap_file(rm, cast(i32)in.a);
		}
	}
	for (xbCall &c : p->calls) {
		if (c.target_sym >= 0) c.target_sym = xb_remap_sym(rm, c.target_sym);
		for (xbCallArg &a : c.args) xb_remap_mem(rm, &a.mem);
		for (xbCallRet &ret : c.rets) xb_remap_mem(rm, &ret.dst);
	}
	for (xbParamIn &pi : p->params_in) xb_remap_mem(rm, &pi.dst);
	for (xbDebugVar &v : p->debug_vars) {
		if (v.local < 0) v.sym = xb_remap_sym(rm, v.sym);
		v.file_id = xb_remap_file(rm, v.file_id);
	}
	for (xbInlineSite &site : p->inline_sites) {
		site.decl_file = xb_remap_file(rm, site.decl_file);
		site.call_file = xb_remap_file(rm, site.call_file);
	}
}

// Runs on a worker thread. It reads the module and the procedure's IR, and writes only `out`.
gb_internal void xb_lower_jobs(xbLowerJob *jobs, isize count) {
	for (isize i = 0; i < count; i++) {
		xbLowerJob *job = &jobs[i];
		xbLowerOut *out = &job->out;
		out->text = array_make<u8>(heap_allocator(), 0, 1024);
		out->relocs = array_make<xbReloc>(heap_allocator(), 0, 32);
		out->lines = array_make<xbLineEntry>(heap_allocator(), 0, 32);
		out->pending = array_make<xbPendingSym>(heap_allocator(), 0, 0);
		// the main thread's arena holds the IR of the queued procedures when it runs a job
		xbArenaMark mark = xb_arena_mark();
		if (job->remap) xb_remap_proc(job->p, job->remap);
		xb_cleanup_proc(job->p);
		if (xb_is_arm64()) {
			a64_lower_proc(job->p, out);
		} else {
			x64_lower_proc(job->p, out);
		}
		xb_arena_release(mark);
	}
}

// Appends one lowered procedure to .text, after the symbols it asked for.
gb_internal void xb_append_lowered(xbModule *m, xbLowerOut *out) {
	auto syms = slice_make<i32>(heap_allocator(), out->pending.count);
	// the helpers go right before the first procedure that calls them, memmove's first
	for (i8 helper = 1; helper <= 2; helper++) {
		for (isize i = 0; i < out->pending.count; i++) {
			if (out->pending[i].helper == helper) syms[i] = x64_helper(m, helper == 2);
		}
	}
	for (isize i = 0; i < out->pending.count; i++) {
		xbPendingSym const &ps = out->pending[i];
		if (ps.import_of != 0) {
			String name = concatenate_strings(permanent_allocator(), str_lit("__imp_"), m->symbols[ps.import_of - 1].name);
			syms[i] = xb_symbol(m, name);
		} else if (ps.helper == 0) {
			syms[i] = xb_symbol(m, ps.name);
			m->symbols[syms[i]].flags |= ps.flags;
		}
	}

	Array<u8> *text = &m->sections[xbSection_Text];
	if (xb_is_arm64()) {
		u32 brk = 0xD4200020; // brk #1
		while (text->count % out->align != 0) array_add_elems(text, cast(u8 *)&brk, 4);
	} else {
		m->section_align[xbSection_Text] = gb_max(m->section_align[xbSection_Text], out->align);
		while (text->count % out->align != 0) array_add(text, cast(u8)0xCC);
	}
	i64 base = text->count;
	array_add_elems(text, out->text.data, out->text.count);
	for (xbReloc r : out->relocs) {
		r.offset += base;
		if (r.sym >= XB_PENDING_SYM) r.sym = syms[r.sym - XB_PENDING_SYM];
		array_add(&m->relocs, r);
	}
	xbProcDebug dbg = out->dbg;
	dbg.start += base;
	dbg.end += base;
	dbg.line_entry_start += cast(i32)m->lines.count;
	array_add_elems(&m->lines, out->lines.data, out->lines.count);
	xbSymbol *s = &m->symbols[dbg.sym];
	s->section = xbSection_Text;
	s->offset = dbg.start;
	s->size = dbg.end - dbg.start;
	s->flags |= xbSymbolFlag_Func;
	array_add(&m->proc_debug, dbg);

	slice_free(&syms, heap_allocator());
	array_free(&out->text);
	array_free(&out->relocs);
	array_free(&out->lines);
	array_free(&out->pending);
}

gb_global ThreadPoolChunks<xbLowerJob> xb_lower_tasks;
// the main thread's arenas: one holds the IR of the busy batch, the other the batch being built
gb_global xbArena xb_main_arenas[2];
gb_global isize   xb_main_arena;

// Waits for the busy batch and appends its code in queue order, so the object is the same
// for any thread count.
gb_internal void xb_lower_finish(xbModule *m) {
	if (m->lower_busy.count == 0) return;
	f64 t0 = gb_time_now();
	thread_pool_wait_chunks(&xb_lower_tasks);
	for (xbLowerJob &job : m->lower_busy) {
		xb_append_lowered(m, &job.out);
	}
	m->lower_done += m->lower_busy.count;
	array_clear(&m->lower_busy);
	xb_time_lower += gb_time_now() - t0;
}

// Hands the queued procedures to the thread pool, which lowers them while the main thread
// builds the next batch in its other arena.
gb_internal void xb_lower_start(xbModule *m) {
	xb_lower_finish(m);
	if (m->lower_jobs.count == 0) return;
	f64 t0 = gb_time_now();
	array_resize(&m->lower_sym_flags, m->symbols.count);
	for (isize i = 0; i < m->symbols.count; i++) {
		xbSymbol const &s = m->symbols[i];
		m->lower_sym_flags[i] = s.flags | (s.section == xbSection_Undef ? xbSymbolFlag_Undef : 0);
	}
	Array<xbLowerJob> jobs = m->lower_busy;
	m->lower_busy = m->lower_jobs;
	m->lower_jobs = jobs;
	thread_pool_start_chunks(&xb_lower_tasks, m->lower_busy.data, m->lower_busy.count, 8, xb_lower_jobs);
	// the arena of the batch before, appended above
	xb_main_arena ^= 1;
	xb_arena_cur = &xb_main_arenas[xb_main_arena];
	xb_arena_reset();
	xb_time_lower += gb_time_now() - t0;
}

// Lowers and appends every queued procedure.
gb_internal void xb_lower_flush(xbModule *m) {
	xb_lower_start(m);
	xb_lower_finish(m);
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

// A procedure literal in a global's initializer, compiled on its own. LLVM makes its own
// copy if the global is left to it, so this one is weak.
gb_internal i32 xb_compile_data_proc_lit(xbModule *m, Ast *expr, char const **reason) {
	ast_node(pl, ProcLit, expr);
	if (pl->body == nullptr || lb_enclosing_proc_decl(pl->decl) != nullptr) {
		*reason = "procedure literal in constant data";
		return -1;
	}
	Entity *e = xb_proc_lit_entity(m, expr);
	i32 sym = xb_symbol(m, xb_entity_name(m, e));
	if (m->symbols[sym].section != xbSection_Undef) return sym;

	xbFamily family = {};
	xb_family_init(&family, e->decl_info);
	defer (xb_family_destroy(&family));
	ptr_set_add(&family.on_demand, e);
	xb_family_add(&family, e);
	xb_shadow_begin(m, xbShadowSeg_DataProcLit, e, sym);
	if (!xb_family_build(m, &family, nullptr, reason)) {
		xb_shadow_end(m, 0, true);
		return -1;
	}
	xb_family_lower(m, &family, nullptr);
	xb_shadow_end(m);
	return sym;
}

gb_internal String xb_object_path(lbGenerator *gen) {
	if (build_context.build_mode == BuildMode_Object) {
		// the output itself; LLVM's modules for fallbacks go next to it
		Path out = build_context.build_paths[BuildPath_Output];
		bool is_dir = path_is_directory(out);
		String name = is_dir ? gen->info->init_package->name : out.name;
		String ext = is_dir ? str_lit("obj") : out.ext;
		if (name.len == 0) {
			// `-out:<dir>` leaves the output name empty
			name = gen->info->init_package->name;
		}
		if (ext.len == 0) ext = str_lit("o");
		gbString path = gb_string_make_length(heap_allocator(), out.basename.text, out.basename.len);
		path = gb_string_append_fmt(path, "/%.*s.%.*s", LIT(name), LIT(ext));
		return make_string(cast(u8 *)path, gb_string_length(path));
	}
	String dir = temporary_directory(permanent_allocator());
	if (dir.len == 0) {
		dir = build_context.build_paths[BuildPath_Output].basename;
	}
	gbString path = gb_string_make_length(heap_allocator(), dir.text, dir.len);
	path = gb_string_append_fmt(path, "/odin-x64-%p.%s", gen, xb_is_win64() ? "obj" : "o");
	return make_string(cast(u8 *)path, gb_string_length(path));
}

#include "xb_shadow.cpp"

gb_internal void xb_generate(lbGenerator *gen) {
	f64 t_start = gb_time_now();
	xbModule *m = permanent_alloc_item<xbModule>();
	xb_module = m;
	m->gen = gen;
	m->info = gen->info;
	xb_module_init_tables(m);
	xb_arena_cur = &xb_main_arenas[0];

	m->limit = -1;
	if (char const *s = gb_get_env("ODIN_XB_LIMIT", permanent_allocator())) {
		m->limit = cast(i64)atoll(s);
	}
	char const *only = gb_get_env("ODIN_XB_ONLY", permanent_allocator());
	char const *skip = gb_get_env("ODIN_XB_SKIP", permanent_allocator());
	m->verbose = gb_get_env("ODIN_XB_VERBOSE", permanent_allocator()) != nullptr;

	f64 t_globals = gb_time_now();
	xb_define_globals(m);
	xb_time_globals = gb_time_now() - t_globals;

	f64 t_procs = gb_time_now();

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

	// xb_proc_is_candidate of each, on the thread pool: polymorphic types take long to check
	auto checks = array_make<xbCandidateCheck>(heap_allocator(), candidates.count);
	defer (array_free(&checks));
	for (isize i = 0; i < candidates.count; i++) checks[i].e = candidates[i];
	thread_pool_for_chunks(checks.data, checks.count, 64, xb_candidate_checks);

	// the families are built a window at a time on the thread pool, and replayed in order here
	bool parallel = xb_can_compile_procs() && m->limit < 0 && only == nullptr && skip == nullptr && !m->verbose &&
	                gb_get_env("ODIN_XB_SERIAL", permanent_allocator()) == nullptr;
	auto jobs = array_make<xbShadowJob>(heap_allocator(), 0, XB_SHADOW_WINDOW); // being replayed
	auto next = array_make<xbShadowJob>(heap_allocator(), 0, XB_SHADOW_WINDOW); // being built meanwhile
	defer (array_free(&jobs));
	defer (array_free(&next));
	isize next_job = 0;
	bool building = false;

	for (isize ci = 0; ci < candidates.count; ci++) {
		Entity *e = candidates[ci];
		if (e->Procedure.is_foreign) {
			xb_note_foreign_library(m, e->Procedure.foreign_library);
		}
		if (!checks[ci].ok) continue;
		m->stats.procs_total += 1;
		if (!xb_can_compile_procs()) {
			xb_stat_fail(m, "no code generation for this target yet");
			continue;
		}
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

		if (m->lower_jobs.count >= XB_LOWER_BATCH) {
			xb_lower_start(m);
		}
		char const *reason = nullptr;
		bool ok = false;
		if (parallel) {
			if (next_job == jobs.count) {
				xb_shadow_window_done(m, &jobs);
				// a small first window, so the replay starts early
				if (!building) xb_shadow_window_start(m, &next, checks, ci, 32);
				xb_shadow_window_wait(&next);
				Array<xbShadowJob> t = jobs; jobs = next; next = t;
				next_job = 0;
				// the window after this one is built while this one is replayed
				xb_shadow_window_start(m, &next, checks, jobs[jobs.count-1].candidate + 1, XB_SHADOW_WINDOW);
				building = next.count > 0;
			}
			xbShadowJob *job = &jobs[next_job++];
			GB_ASSERT(job->e == e);
			ok = xb_shadow_compile(m, job, &reason);
		} else {
			ok = xb_compile_proc(m, e, &reason);
		}
		if (ok) {
			m->stats.procs_compiled += 1;
			ptr_set_add(&m->handled, e);
			if (m->verbose) {
				gb_printf_err("xb: compiled %.*s\n", LIT(name));
			}
		} else {
			xb_stat_fail(m, reason ? reason : "unknown");
			xb_log_fallback(m, "procedure", name, e->token.pos, reason);
		}
	}

	xb_shadow_window_done(m, &jobs);
	GB_ASSERT(!building || next.count == 0 || next_job == 0);
	if (building && next_job != 0) xb_shadow_window_wait(&next);
	xb_time_procs = gb_time_now() - t_procs;

	f64 t_extra = gb_time_now();
	if (xb_can_compile_procs()) {
		xb_build_startup(m);
	}
	xb_build_type_info(m);
	if (xb_can_compile_procs()) {
		xb_build_test_main(m);
	}

	m->complete = m->stats.procs_compiled == m->stats.procs_total &&
	              m->stats.globals_defined == m->stats.globals_total &&
	              m->owns_startup &&
	              (m->owns_type_info || build_context.no_rtti) &&
	              (build_context.command_kind != Command_test || m->owns_test_main || m->test_main_not_needed);
	if (build_context.metrics.os == TargetOs_darwin && xb_can_compile_procs()) {
		char const *reason = nullptr;
		if (m->complete && !xb_build_objc_names(m, &reason)) {
			m->complete = false;
			xb_stat_fail(m, reason ? reason : "objc setup");
			xb_log_fallback(m, "runtime procedure", str_lit("__$init_objc_names"), {}, reason);
		}
		if (!m->complete) {
			xb_objc_hand_over(m);
		}
	}

	xb_time_extra = gb_time_now() - t_extra;
	xb_lower_flush(m);

	// for CI: anything left to LLVM is an error, the reasons are printed above
	if (!m->complete && gb_get_env("ODIN_XB_NO_FALLBACK", permanent_allocator()) != nullptr) {
		gb_printf_err("fast backend: ODIN_XB_NO_FALLBACK is set, but %td of %td procedures and %td of %td globals were compiled\n",
		              m->stats.procs_compiled, m->stats.procs_total, m->stats.globals_defined, m->stats.globals_total);
		gb_exit(1);
	}

	if (m->stats.procs_compiled > 0 || m->stats.globals_defined > 0) {
		m->object_path = xb_object_path(gen);
		f64 t0 = gb_time_now();
		bool ok = false;
		if (xb_is_win64()) {
			ok = xb_write_coff(m, m->object_path);
		} else if (xb_is_darwin()) {
			ok = xb_write_macho(m, m->object_path);
		} else {
			ok = xb_write_object(m, m->object_path);
		}
		if (!ok) {
			gb_exit(1);
		}
		xb_time_write += gb_time_now() - t0;
	}

	xb_time_total = gb_time_now() - t_start;

	if (gb_get_env("ODIN_XB_STATS", permanent_allocator()) != nullptr) {
		gb_printf_err("fast backend: compiled %td of %td procedures, inlined %td calls\n", m->stats.procs_compiled, m->stats.procs_total, m->stats.calls_inlined);
		gb_printf_err("  globals %td of %td, startup %s, type info %s, test main %s%s\n", m->stats.globals_defined, m->stats.globals_total, m->owns_startup ? "fast" : "llvm", m->owns_type_info ? "fast" : "llvm", m->owns_test_main ? "fast" : "-", m->complete ? ", no LLVM" : "");
		gb_printf_err("  build %.3f ms, lower %.3f ms, write %.3f ms\n", xb_time_build*1000, xb_time_lower*1000, xb_time_write*1000);
		if (xb_is_win64()) {
			gb_printf_err("  write: unwind %.3f ms, debug info %.3f ms, symbols and relocations %.3f ms, layout and file %.3f ms\n",
			              xb_time_coff_unwind*1000, xb_time_coff_debug*1000, xb_time_coff_symbols*1000, xb_time_coff_file*1000);
		}
		gb_printf_err("  families built on the main thread after all: %td\n", m->stats.shadow_serial);
		gb_printf_err("  globals %.3f ms, procedures %.3f ms, startup and type info %.3f ms, total %.3f ms\n", xb_time_globals*1000, xb_time_procs*1000, xb_time_extra*1000, xb_time_total*1000);
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

gb_internal isize xb_procs_compiled(void) {
	return xb_module != nullptr ? xb_module->stats.procs_compiled : 0;
}

#if defined(_MSC_VER)
#pragma warning(pop)
#endif
