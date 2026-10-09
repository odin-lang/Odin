// Building procedure families on the thread pool. Each family is built into a shadow module,
// whose changes the main thread replays into the real module in the serial order, see
// xbShadowOpKind.

// The tables of a module. A shadow starts small: it holds one family.
gb_internal void xb_module_init_tables(xbModule *m) {
	bool shadow = m->real != nullptr;
	m->symbols = array_make<xbSymbol>(heap_allocator(), 0, shadow ? 64 : 4096);
	string_map_init(&m->symbol_map);
	for (isize i = 0; i < xbSection_COUNT; i++) {
		isize cap = shadow ? 0 : i == xbSection_Text ? 1<<20 : 1<<14;
		m->sections[i] = array_make<u8>(heap_allocator(), 0, cap);
	}
	m->relocs = array_make<xbReloc>(heap_allocator(), 0, shadow ? 0 : 1<<14);
	m->proc_debug = array_make<xbProcDebug>(heap_allocator(), 0, shadow ? 0 : 1024);
	m->global_debug = array_make<xbGlobalDebug>(heap_allocator(), 0, shadow ? 0 : 256);
	m->lines = array_make<xbLineEntry>(heap_allocator(), 0, shadow ? 0 : 1<<14);
	m->files = array_make<String>(heap_allocator(), 0, shadow ? 8 : 64);
	map_init(&m->file_ids);
	ptr_set_init(&m->handled);
	ptr_set_init(&m->defined_procs);
	map_init(&m->entity_names);
	string_map_init(&m->name_owners);
	ptr_set_init(&m->foreign_libs_set);
	m->foreign_libs = array_make<Entity *>(heap_allocator(), 0, shadow ? 0 : 16);
	map_init(&m->inline_statics);
	m->lower_jobs = array_make<xbLowerJob>(heap_allocator(), 0, shadow ? 0 : XB_LOWER_BATCH);
	m->lower_busy = array_make<xbLowerJob>(heap_allocator(), 0, shadow ? 0 : XB_LOWER_BATCH);
	m->lower_sym_flags = array_make<u8>(heap_allocator(), 0, shadow ? 0 : 4096);
	map_init(&m->equal_procs);
	map_init(&m->hasher_procs);
	map_init(&m->map_infos);
	map_init(&m->map_cell_infos);
	string_map_init(&m->string_lits);
	string_map_init(&m->stats.fail_reasons);
	for (isize i = 0; i < xbObjc_COUNT; i++) {
		m->objc_globals[i] = array_make<xbObjcGlobal>(heap_allocator(), 0, shadow ? 0 : 16);
		string_map_init(&m->objc_global_map[i]);
	}
	m->shadow_log = array_make<xbShadowOp>(heap_allocator(), 0, shadow ? 256 : 0);
	m->shadow_open = array_make<isize>(heap_allocator(), 0, shadow ? 16 : 0);
	map_init(&m->shadow_seen);
}

// Empties a replayed shadow for another family, keeping its memory.
gb_internal void xb_shadow_reset(xbModule *m) {
	array_clear(&m->shadow_log);
	array_clear(&m->shadow_open);
	map_clear(&m->shadow_seen);
	m->shadow_quiet = 0;
	m->shadow_serial = false;
	array_clear(&m->symbols);
	string_map_clear(&m->symbol_map);
	for (isize i = 0; i < xbSection_COUNT; i++) {
		array_clear(&m->sections[i]);
		m->nobits_size[i] = 0;
		m->section_align[i] = 0;
	}
	array_clear(&m->relocs);
	array_clear(&m->proc_debug);
	array_clear(&m->global_debug);
	array_clear(&m->lines);
	array_clear(&m->files);
	map_clear(&m->file_ids);
	m->x64_move_helper = 0;
	m->x64_set_helper = 0;
	map_clear(&m->equal_procs);
	map_clear(&m->hasher_procs);
	map_clear(&m->map_infos);
	map_clear(&m->map_cell_infos);
	array_clear(&m->lower_jobs);
	array_clear(&m->lower_busy);
	array_clear(&m->lower_sym_flags);
	m->lower_queued = 0;
	m->lower_done = 0;
	ptr_set_clear(&m->handled);
	ptr_set_clear(&m->defined_procs);
	map_clear(&m->entity_names);
	string_map_clear(&m->name_owners);
	map_clear(&m->inline_statics);
	string_map_clear(&m->string_lits);
	StringMap<isize> fail_reasons = m->stats.fail_reasons;
	string_map_clear(&fail_reasons);
	m->stats = {};
	m->stats.fail_reasons = fail_reasons;
	m->fail_pos = {};
	ptr_set_clear(&m->foreign_libs_set);
	array_clear(&m->foreign_libs);
	for (isize i = 0; i < xbObjc_COUNT; i++) {
		array_clear(&m->objc_globals[i]);
		string_map_clear(&m->objc_global_map[i]);
	}
	m->objc_block_count = 0;
}

gb_internal xbModule *xb_shadow_make(xbModule *real) {
	xbModule *m = cast(xbModule *)gb_alloc(heap_allocator(), gb_size_of(xbModule));
	gb_zero_item(m);
	m->info = real->info;
	m->gen = real->gen;
	m->real = real;
	m->limit = -1;
	xb_module_init_tables(m);
	return m;
}

// Frees what a shadow holds once it is replayed. The IR it built lives on until it is lowered.
gb_internal void xb_shadow_destroy(xbModule *m) {
	array_free(&m->symbols);
	string_map_destroy(&m->symbol_map);
	for (isize i = 0; i < xbSection_COUNT; i++) array_free(&m->sections[i]);
	array_free(&m->relocs);
	array_free(&m->proc_debug);
	array_free(&m->global_debug);
	array_free(&m->lines);
	array_free(&m->files);
	map_destroy(&m->file_ids);
	map_destroy(&m->entity_names);
	string_map_destroy(&m->name_owners);
	array_free(&m->foreign_libs);
	map_destroy(&m->inline_statics);
	array_free(&m->lower_jobs);
	array_free(&m->lower_busy);
	array_free(&m->lower_sym_flags);
	map_destroy(&m->equal_procs);
	map_destroy(&m->hasher_procs);
	map_destroy(&m->map_infos);
	map_destroy(&m->map_cell_infos);
	string_map_destroy(&m->string_lits);
	string_map_destroy(&m->stats.fail_reasons);
	for (isize i = 0; i < xbObjc_COUNT; i++) {
		array_free(&m->objc_globals[i]);
		string_map_destroy(&m->objc_global_map[i]);
	}
	array_free(&m->shadow_log);
	array_free(&m->shadow_open);
	map_destroy(&m->shadow_seen);
	gb_free(heap_allocator(), m);
}

////////////////////////////////////////////////////////////////
// Building
////////////////////////////////////////////////////////////////

// The IR of a window's families, an arena per thread. It lives until all of it is lowered.
struct xbWindowArenas {
	i64            last_job; // the module's lower_queued once the window is replayed, -1 before
	Slice<xbArena> per_thread;
};

gb_global Array<xbWindowArenas *> xb_windows_live; // oldest first
gb_global Array<xbWindowArenas *> xb_windows_free;

gb_internal xbWindowArenas *xb_window_arenas_get(xbModule *m) {
	if (xb_windows_live.allocator.proc == nullptr) {
		xb_windows_live = array_make<xbWindowArenas *>(heap_allocator(), 0, 8);
		xb_windows_free = array_make<xbWindowArenas *>(heap_allocator(), 0, 8);
	}
	isize done = 0;
	while (done < xb_windows_live.count) {
		i64 last = xb_windows_live[done]->last_job;
		if (last < 0 || last > m->lower_done) break;
		array_add(&xb_windows_free, xb_windows_live[done]);
		done += 1;
	}
	for (isize i = done; i < xb_windows_live.count; i++) {
		xb_windows_live[i - done] = xb_windows_live[i];
	}
	xb_windows_live.count -= done;

	xbWindowArenas *w = nullptr;
	if (xb_windows_free.count > 0) {
		w = array_pop(&xb_windows_free);
	} else {
		w = gb_alloc_item(heap_allocator(), xbWindowArenas);
		w->per_thread = slice_make<xbArena>(heap_allocator(), global_thread_pool.threads.count);
		// a thread may build only a few families of a window
		for (xbArena &a : w->per_thread) a.chunk_size = 256<<10;
	}
	for (xbArena &a : w->per_thread) {
		a.curr = 0;
		a.used = 0;
	}
	w->last_job = -1;
	array_add(&xb_windows_live, w);
	return w;
}

struct xbShadowJob {
	Entity *          e;
	isize             candidate; // its index in the candidates
	xbWindowArenas *  arenas;
	xbModule *        sh;
	bool              ok;
	char const *      reason;
};

// Runs on the thread pool. It writes only the shadows it makes, and its thread's arena.
gb_internal void xb_shadow_build_jobs(xbShadowJob *jobs, isize count) {
	xbArena *saved = xb_arena_cur;
	for (isize i = 0; i < count; i++) {
		xbShadowJob *job = &jobs[i];
		xb_arena_cur = &job->arenas->per_thread[current_thread_index()];
		if (job->sh != nullptr) {
			xb_shadow_reset(job->sh);
		} else {
			job->sh = xb_shadow_make(xb_module);
		}
		job->reason = nullptr;
		job->ok = xb_compile_proc(job->sh, job->e, &job->reason);
	}
	xb_arena_cur = saved;
}

enum : isize { XB_SHADOW_WINDOW = 256 };

// Marks the window's jobs replayed: its arenas are free once what it queued is lowered.
gb_internal void xb_shadow_window_done(xbModule *m, Array<xbShadowJob> *jobs) {
	if (jobs->count > 0) jobs->data[0].arenas->last_job = m->lower_queued;
	array_clear(jobs);
}

gb_global ThreadPoolChunks<xbShadowJob> xb_shadow_tasks;

// Replayed shadows, which the next windows reuse. Only the main thread touches the list.
gb_global Array<xbModule *> xb_shadows_free;

// Starts building the next window of families, from candidate `from` on, into `jobs`.
gb_internal void xb_shadow_window_start(xbModule *m, Array<xbShadowJob> *jobs, Array<xbCandidateCheck> const &candidates, isize from, isize size) {
	if (xb_shadows_free.allocator.proc == nullptr) {
		xb_shadows_free = array_make<xbModule *>(heap_allocator(), 0, 2*XB_SHADOW_WINDOW);
	}
	array_clear(jobs);
	xbWindowArenas *arenas = xb_window_arenas_get(m);
	for (isize j = from; j < candidates.count && jobs->count < size; j++) {
		if (!candidates[j].ok) continue;
		xbShadowJob job = {};
		job.e = candidates[j].e;
		job.candidate = j;
		job.arenas = arenas;
		job.sh = xb_shadows_free.count > 0 ? array_pop(&xb_shadows_free) : nullptr;
		array_add(jobs, job);
	}
	if (jobs->count > 0) {
		thread_pool_start_chunks(&xb_shadow_tasks, jobs->data, jobs->count, 1, xb_shadow_build_jobs);
	}
}

gb_internal void xb_shadow_window_wait(Array<xbShadowJob> *jobs) {
	if (jobs->count == 0) return;
	f64 t0 = gb_time_now();
	thread_pool_wait_chunks(&xb_shadow_tasks);
	xb_time_build += gb_time_now() - t0;
}

////////////////////////////////////////////////////////////////
// Replaying
////////////////////////////////////////////////////////////////

enum xbReplayResult {
	xbReplay_Ok,
	xbReplay_Failed,
	xbReplay_Serial, // the main thread builds the family: the shadow's build differs from a serial one
};

// Data the shadow placed, at `at` in its section, and where the real module has it.
struct xbReplayItem {
	i64 at;
	i64 size;
	i64 real_at;
};

struct xbReplay {
	xbModule *m;  // the real module
	xbModule *sh;
	Array<i32> syms;  // the shadow's symbols in the real module, -1 until known
	Array<i32> files; // the shadow's file ids in the real module
	Array<xbReplayItem> items[xbSection_COUNT];
};

gb_internal i32 xb_replay_sym(xbReplay *r, i64 sym) {
	i32 s = r->syms[sym];
	GB_ASSERT_MSG(s >= 0, "fast backend: shadow symbol %.*s has no real symbol", LIT(r->sh->symbols[sym].name));
	return s;
}

// The real offset of data the shadow placed at `at`.
gb_internal i64 xb_replay_offset(xbReplay *r, xbSection sec, i64 at) {
	Array<xbReplayItem> const &items = r->items[sec];
	isize lo = 0, hi = items.count;
	while (lo < hi) {
		isize mid = (lo + hi) / 2;
		if (items[mid].at <= at) lo = mid + 1; else hi = mid;
	}
	GB_ASSERT_MSG(lo > 0, "fast backend: shadow data at %lld was not replayed", cast(long long)at);
	xbReplayItem const &it = items[lo-1];
	GB_ASSERT(at <= it.at + it.size);
	return it.real_at + (at - it.at);
}

gb_internal String xb_replay_name(xbReplay *r, String name) {
	if (Entity *e = xb_shadow_name_entity(name)) return xb_entity_name(r->m, e);
	return name;
}

// Whether the real module has the entity's procedure, without naming it.
gb_internal bool xb_replay_entity_defined(xbModule *m, Entity *e) {
	String *name = map_get(&m->entity_names, e);
	if (name == nullptr) return false;
	i32 *sym = xb_symbol_find(m, *name);
	return sym != nullptr && m->symbols[*sym].section != xbSection_Undef;
}

// Whether a serial build would not do the segment here, because it was done before.
gb_internal bool xb_replay_skips(xbModule *m, xbShadowOp const &op) {
	switch (op.aux) {
	case xbShadowSeg_Proc:
	case xbShadowSeg_FamilyLower:
	case xbShadowSeg_DataProcLit:
		return xb_replay_entity_defined(m, cast(Entity *)op.ptr);
	case xbShadowSeg_Gen: {
		i32 *v = map_get(xb_gen_cache(m, cast(xbGenCache)op.aux2), cast(Type *)op.ptr);
		return v != nullptr && *v >= 0;
	}
	case xbShadowSeg_InlineStatic:
		return map_get(&m->inline_statics, cast(Entity *)op.ptr) != nullptr;
	}
	return false;
}

// Whether the replay can make the changes of a serial build. A segment the shadow did and the
// real module did before only gets skipped when the shadow's build went on just as a serial one
// would: not when it failed in the segment, nor when the segment left different IR.
// The shadow's own changes cannot decide that, it did not have them before the segment.
gb_internal bool xb_replay_possible(xbModule *m, xbModule *sh) {
	if (sh->shadow_serial) return false;
	for (xbShadowOp const &op : sh->shadow_log) {
		if (op.kind != xbShadowOp_Begin) continue;
		bool failed = sh->shadow_log[op.c].a != 0;
		if (op.aux == xbShadowSeg_InlineStatic && xb_replay_skips(m, op)) return false;
		if (failed && xb_replay_skips(m, op)) return false;
		if (op.aux == xbShadowSeg_Gen && !failed) {
			// it failed before: a serial build fails where the shadow went on
			i32 *v = map_get(xb_gen_cache(m, cast(xbGenCache)op.aux2), cast(Type *)op.ptr);
			if (v != nullptr && *v == -2) return false;
		}
	}
	return true;
}

// The real symbols of what a skipped segment made, which the real module has from before.
gb_internal void xb_replay_skip(xbReplay *r, isize begin, isize end) {
	xbModule *m = r->m;
	for (isize i = begin+1; i < end; i++) {
		xbShadowOp const &op = r->sh->shadow_log[i];
		switch (op.kind) {
		case xbShadowOp_CacheSet:
			if (op.a >= 0 && r->syms[op.a] < 0) {
				i32 *v = map_get(xb_gen_cache(m, cast(xbGenCache)op.aux), cast(Type *)op.ptr);
				if (v != nullptr && *v >= 0) r->syms[op.a] = *v;
			}
			break;
		case xbShadowOp_InlineStatic:
			if (r->syms[op.sym] < 0) {
				if (i32 *v = map_get(&m->inline_statics, cast(Entity *)op.ptr)) r->syms[op.sym] = *v;
			}
			break;
		case xbShadowOp_Sym:
			if (r->syms[op.sym] < 0) {
				String name = op.str;
				if (Entity *e = xb_shadow_name_entity(name)) {
					String *real_name = map_get(&m->entity_names, e);
					if (real_name == nullptr) break;
					name = *real_name;
				}
				if (i32 *v = xb_symbol_find(m, name)) r->syms[op.sym] = *v;
			}
			break;
		}
	}
}

// Gives a procedure the shadow built its real symbol and names. The lowering renumbers the
// rest of its IR, off the main thread, see xb_remap_proc.
gb_internal void xb_replay_proc(xbReplay *r, xbProc *p) {
	p->m = r->m;
	p->sym = xb_replay_sym(r, p->sym);
	p->name = xb_replay_name(r, p->name);
	for (xbInlineSite &site : p->inline_sites) {
		site.name = xb_replay_name(r, site.name);
	}
}

// Makes the shadow's changes to the real module, skipping what a serial build would not have done.
gb_internal xbReplayResult xb_shadow_replay(xbModule *m, xbModule *sh, char const **reason) {
	if (!xb_replay_possible(m, sh)) return xbReplay_Serial;

	xbReplay r = {};
	r.m = m;
	r.sh = sh;
	// in the main thread's arena: the lowering reads them, see xbRemap
	r.syms = array_make<i32>(xb_allocator(), sh->symbols.count);
	for (i32 &s : r.syms) s = -1;
	r.files = array_make<i32>(xb_allocator(), sh->files.count + 1);
	xbRemap *remap = nullptr;
	for (isize i = 0; i < xbSection_COUNT; i++) {
		r.items[i] = array_make<xbReplayItem>(heap_allocator(), 0, 0);
	}
	defer ({
		for (isize i = 0; i < xbSection_COUNT; i++) array_free(&r.items[i]);
	});

	for (isize i = 0; i < sh->shadow_log.count; i++) {
		xbShadowOp const &op = sh->shadow_log[i];
		switch (op.kind) {
		case xbShadowOp_Begin:
			if (xb_replay_skips(m, op)) {
				Entity *e = cast(Entity *)op.ptr;
				if (op.aux == xbShadowSeg_Proc && op.a && !ptr_set_exists(&m->defined_procs, e)) {
					*reason = "duplicate symbol";
					return xbReplay_Failed;
				}
				xb_replay_skip(&r, i, op.c);
				i = op.c;
			}
			break;
		case xbShadowOp_End:
			break;
		case xbShadowOp_EntityName: {
			// the symbol right after names it just as well
			Entity *e = cast(Entity *)op.ptr;
			if (i+1 < sh->shadow_log.count) {
				xbShadowOp const &next = sh->shadow_log[i+1];
				if (next.kind == xbShadowOp_Sym && xb_shadow_name_entity(next.str) == e) break;
			}
			xb_entity_name(m, e);
			break;
		}
		case xbShadowOp_Sym:
			// a symbol the real module has already gets nothing from another use
			if (r.syms[op.sym] < 0) {
				r.syms[op.sym] = xb_symbol(m, xb_replay_name(&r, op.str));
			}
			break;
		case xbShadowOp_SymAddFlags:
			xb_sym_add_flags(m, xb_replay_sym(&r, op.sym), cast(u8)op.a);
			break;
		case xbShadowOp_SymSetFlags:
			xb_sym_set_flags(m, xb_replay_sym(&r, op.sym), cast(u8)op.a);
			break;
		case xbShadowOp_SymRealign:
			xb_sym_set_realign(m, xb_replay_sym(&r, op.sym), op.a);
			break;
		case xbShadowOp_SymDefine:
			xb_sym_define(m, xb_replay_sym(&r, op.sym), op.sec, xb_replay_offset(&r, op.sec, op.a), op.b);
			break;
		case xbShadowOp_OffsetSym:
			r.syms[op.sym] = xb_offset_symbol(m, cast(char const *)op.str.text, op.sec, xb_replay_offset(&r, op.sec, op.a), op.b, cast(u8)op.c);
			break;
		case xbShadowOp_Append: {
			xbReplayItem it = {op.a, op.b, 0};
			it.real_at = xb_section_append(m, op.sec, sh->sections[op.sec].data + op.a, op.b, op.c);
			array_add(&r.items[op.sec], it);
			break;
		}
		case xbShadowOp_Reserve: {
			xbReplayItem it = {op.a, op.b, 0};
			it.real_at = xb_section_reserve(m, op.sec, op.b, op.c);
			if (op.sec != xbSection_Bss && op.sec != xbSection_TBss) {
				xb_section_write(m, op.sec, it.real_at, sh->sections[op.sec].data + op.a, op.b);
			}
			array_add(&r.items[op.sec], it);
			break;
		}
		case xbShadowOp_Reloc: {
			xbReloc rr = op.reloc;
			rr.offset = xb_replay_offset(&r, rr.section, rr.offset);
			rr.sym = xb_replay_sym(&r, rr.sym);
			xb_module_reloc(m, rr);
			break;
		}
		case xbShadowOp_StringLit:
			if (r.syms[op.sym] < 0) {
				r.syms[op.sym] = xb_string_literal(m, op.str);
			}
			break;
		case xbShadowOp_FileId:
			if (r.files[op.b] == 0) {
				r.files[op.b] = xb_file_id(m, cast(i32)op.a);
			}
			break;
		case xbShadowOp_ForeignLib:
			xb_note_foreign_library(m, cast(Entity *)op.ptr);
			break;
		case xbShadowOp_Lower: {
			xbProc *p = cast(xbProc *)op.ptr;
			xb_replay_proc(&r, p);
			xb_lower_proc(p);
			if (remap == nullptr) {
				remap = xb_alloc_item<xbRemap>();
				remap->syms = {r.syms.data, r.syms.count};
				remap->files = {r.files.data, r.files.count};
			}
			m->lower_jobs[m->lower_jobs.count-1].remap = remap;
			break;
		}
		case xbShadowOp_DefinedProc:
			ptr_set_add(&m->defined_procs, cast(Entity *)op.ptr);
			break;
		case xbShadowOp_CacheSet:
			map_set(xb_gen_cache(m, cast(xbGenCache)op.aux), cast(Type *)op.ptr, op.a >= 0 ? xb_replay_sym(&r, op.a) : cast(i32)op.a);
			break;
		case xbShadowOp_InlineStatic:
			map_set(&m->inline_statics, cast(Entity *)op.ptr, xb_replay_sym(&r, op.sym));
			break;
		case xbShadowOp_CallInlined:
			m->stats.calls_inlined += 1;
			break;
		}
	}
	return xbReplay_Ok;
}

// Compiles the family the job built: replays its shadow, or builds it here when the replay
// cannot make a serial build's changes.
gb_internal bool xb_shadow_compile(xbModule *m, xbShadowJob *job, char const **reason) {
	xbModule *sh = job->sh;
	job->sh = nullptr;
	xbReplayResult res = xb_shadow_replay(m, sh, reason);
	if (res == xbReplay_Ok && !job->ok) {
		*reason = job->reason;
		m->fail_pos = sh->fail_pos;
		res = xbReplay_Failed;
	}
	array_add(&xb_shadows_free, sh);
	if (res == xbReplay_Serial) {
		m->stats.shadow_serial += 1;
		return xb_compile_proc(m, job->e, reason);
	}
	return res == xbReplay_Ok;
}
