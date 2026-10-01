// -internal-global-entity-graph: per-entity self time of global declaration checking,
// plus statistics of the dependency graph between global entities (DeclInfo::deps)

struct GlobalEntityTime {
	u64  ticks;
	bool in_global_loop;
};

struct GlobalEntityTimingFrame {
	u64  start;
	u64  saved_child_ticks;
	bool active;
};

enum GlobalImportStagePart {
	GlobalImportStage_CollectFileDecls,
	GlobalImportStage_Imports,
	GlobalImportStage_TypeAliases,
	GlobalImportStage_ForeignBlocks,
	GlobalImportStage_DelayedExprs,

	GlobalImportStage_COUNT,
};

gb_global char const *global_import_stage_names[GlobalImportStage_COUNT] = {
	"collect file decls ('when')",
	"delayed imports",
	"type alias correction",
	"foreign blocks",
	"delayed expressions (#assert etc.)",
};

gb_global u64 global_import_stage_ticks[GlobalImportStage_COUNT];

gb_internal u64 global_import_stage_begin(void) {
	return build_context.internal_global_entity_graph ? time_stamp_time_now() : 0;
}

gb_internal void global_import_stage_end(GlobalImportStagePart part, u64 start) {
	if (build_context.internal_global_entity_graph) {
		global_import_stage_ticks[part] += time_stamp_time_now() - start;
	}
}

gb_global BlockingMutex global_entity_time_mutex;
gb_global PtrMap<Entity *, GlobalEntityTime> global_entity_times;
gb_thread_local u64 global_entity_child_ticks;

gb_internal GlobalEntityTimingFrame global_entity_timing_begin(Entity *e) {
	GlobalEntityTimingFrame f = {};
	if (!build_context.internal_global_entity_graph) {
		return f;
	}
	if (e->scope == nullptr || (e->scope->flags & ScopeFlag_File) == 0) {
		return f;
	}
	f.active = true;
	f.saved_child_ticks = global_entity_child_ticks;
	global_entity_child_ticks = 0;
	f.start = time_stamp_time_now();
	return f;
}

gb_internal void global_entity_timing_end(GlobalEntityTimingFrame const &f, Entity *e) {
	if (!f.active) {
		return;
	}
	u64 total = time_stamp_time_now() - f.start;
	u64 self  = total - gb_min(total, global_entity_child_ticks);
	global_entity_child_ticks = f.saved_child_ticks + total;

	bool in_global_loop = in_single_threaded_checker_stage.load(std::memory_order_relaxed);

	MUTEX_GUARD(&global_entity_time_mutex);
	GlobalEntityTime *found = map_get(&global_entity_times, e);
	if (found) {
		found->ticks += self;
	} else {
		map_set(&global_entity_times, e, GlobalEntityTime{self, in_global_loop});
	}
}


// Iterative Tarjan; components are numbered so that every edge v->w has comp(w) <= comp(v)
gb_internal i32 global_graph_scc(i32 node_count, Array<i32> const &offsets, Array<i32> const &targets, Array<i32> *comp_of_) {
	struct Frame {
		i32 v;
		i32 pos;
	};

	auto index    = array_make<i32>(heap_allocator(), node_count);
	auto low      = array_make<i32>(heap_allocator(), node_count);
	auto on_stack = array_make<bool>(heap_allocator(), node_count);
	auto stack    = array_make<i32>(heap_allocator(), 0, node_count);
	auto frames   = array_make<Frame>(heap_allocator(), 0, 64);
	defer (array_free(&index));
	defer (array_free(&low));
	defer (array_free(&on_stack));
	defer (array_free(&stack));
	defer (array_free(&frames));

	Array<i32> &comp_of = *comp_of_;
	for (i32 v = 0; v < node_count; v++) {
		index[v]    = -1;
		low[v]      = 0;
		on_stack[v] = false;
		comp_of[v]  = -1;
	}

	i32 counter = 0;
	i32 comp_count = 0;
	for (i32 root = 0; root < node_count; root++) {
		if (index[root] >= 0) {
			continue;
		}
		index[root] = low[root] = counter++;
		array_add(&stack, root);
		on_stack[root] = true;
		array_add(&frames, Frame{root, 0});

		while (frames.count > 0) {
			Frame *top = &frames[frames.count-1];
			i32 v = top->v;
			if (offsets[v] + top->pos < offsets[v+1]) {
				i32 w = targets[offsets[v] + top->pos];
				top->pos += 1;
				if (index[w] < 0) {
					index[w] = low[w] = counter++;
					array_add(&stack, w);
					on_stack[w] = true;
					array_add(&frames, Frame{w, 0});
				} else if (on_stack[w]) {
					low[v] = gb_min(low[v], index[w]);
				}
				continue;
			}

			if (low[v] == index[v]) {
				for (;;) {
					i32 w = array_pop(&stack);
					on_stack[w] = false;
					comp_of[w] = comp_count;
					if (w == v) {
						break;
					}
				}
				comp_count += 1;
			}
			array_pop(&frames);
			if (frames.count > 0) {
				i32 u = frames[frames.count-1].v;
				low[u] = gb_min(low[u], low[v]);
			}
		}
	}
	return comp_count;
}

struct GlobalGraphComp {
	i32  start; // into the member order array
	i32  count;
	u64  ticks;
	u64  path_ticks; // heaviest dependency chain ending at this component, inclusive
	i32  path_len;
	i32  path_prev;
	bool has_self_edge;
};

struct GlobalGraphSortItem {
	u64 key;
	i32 id;
};

gb_internal GB_COMPARE_PROC(global_graph_sort_item_desc) {
	GlobalGraphSortItem const *x = cast(GlobalGraphSortItem const *)a;
	GlobalGraphSortItem const *y = cast(GlobalGraphSortItem const *)b;
	if (x->key != y->key) {
		return x->key > y->key ? -1 : +1;
	}
	return i32_cmp(x->id, y->id);
}

// Fills `comps` (indexed by component) and `order` (node indices grouped by component)
gb_internal void global_graph_condense(i32 node_count, Array<i32> const &offsets, Array<i32> const &targets, Array<u64> const &node_ticks,
                                       Array<i32> const &comp_of, i32 comp_count, Array<GlobalGraphComp> *comps_, Array<i32> *order_) {
	Array<GlobalGraphComp> &comps = *comps_;
	Array<i32> &order = *order_;
	for (i32 i = 0; i < comp_count; i++) {
		comps[i] = {};
		comps[i].path_prev = -1;
	}
	for (i32 v = 0; v < node_count; v++) {
		GlobalGraphComp *g = &comps[comp_of[v]];
		g->count += 1;
		g->ticks += node_ticks[v];
	}
	i32 start = 0;
	for (i32 i = 0; i < comp_count; i++) {
		comps[i].start = start;
		start += comps[i].count;
		comps[i].count = 0;
	}
	for (i32 v = 0; v < node_count; v++) {
		GlobalGraphComp *g = &comps[comp_of[v]];
		order[g->start + g->count] = v;
		g->count += 1;
	}

	for (i32 ci = 0; ci < comp_count; ci++) {
		GlobalGraphComp *g = &comps[ci];
		u64 best_ticks = 0;
		i32 best_len = 0;
		i32 best_prev = -1;
		for (i32 k = 0; k < g->count; k++) {
			i32 v = order[g->start + k];
			for (i32 e = offsets[v]; e < offsets[v+1]; e++) {
				i32 w = targets[e];
				if (w == v) {
					g->has_self_edge = true;
				}
				i32 cw = comp_of[w];
				if (cw == ci) {
					continue;
				}
				GB_ASSERT(cw < ci);
				GlobalGraphComp *d = &comps[cw];
				if (best_prev < 0 || d->path_ticks > best_ticks) {
					best_ticks = d->path_ticks;
					best_prev  = cw;
				}
				best_len = gb_max(best_len, d->path_len);
			}
		}
		g->path_ticks = g->ticks + best_ticks;
		g->path_len   = 1 + best_len;
		g->path_prev  = best_prev;
	}
}

gb_internal f64 global_graph_ms(u64 ticks, u64 freq) {
	return 1000.0 * cast(f64)ticks / cast(f64)freq;
}

gb_internal void global_graph_print_entity(Entity *e) {
	String pkg  = e->pkg  ? e->pkg->name : str_lit("?");
	String file = e->file ? filename_without_directory(e->file->fullpath) : str_lit("?");
	gb_printf_err("%.*s.%.*s (%.*s:%d)", LIT(pkg), LIT(e->token.string), LIT(file), e->token.pos.line);
}

gb_internal void global_graph_print_comp(Array<Entity *> const &nodes, Array<i32> const &order, GlobalGraphComp const *g, u64 ticks, u64 freq, isize max_names) {
	gb_printf_err("    %10.3f ms %7d entities  ", global_graph_ms(ticks, freq), g->count);
	for (i32 k = 0; k < g->count && k < max_names; k++) {
		if (k > 0) {
			gb_printf_err(", ");
		}
		global_graph_print_entity(nodes[order[g->start + k]]);
	}
	if (g->count > max_names) {
		gb_printf_err(", ...");
	}
	gb_printf_err("\n");
}

gb_internal void print_global_entity_graph(Checker *c) {
	u64 const freq = time_stamp__freq();

	// Nodes
	auto nodes = array_make<Entity *>(heap_allocator(), 0, c->info.entities.count);
	defer (array_free(&nodes));
	PtrMap<Entity *, i32> node_index = {};
	map_init(&node_index, c->info.entities.count);
	defer (map_destroy(&node_index));

	for (Entity *e : c->info.entities) {
		if (e->decl_info == nullptr || e->scope == nullptr || (e->scope->flags & ScopeFlag_File) == 0) {
			continue;
		}
		if (map_get(&node_index, e) != nullptr) {
			continue;
		}
		map_set(&node_index, e, cast(i32)nodes.count);
		array_add(&nodes, e);
	}
	i32 node_count = cast(i32)nodes.count;

	// Edges, from what each declaration actually used while being checked
	auto offsets = array_make<i32>(heap_allocator(), node_count+1);
	auto targets = array_make<i32>(heap_allocator(), 0, node_count*4);
	defer (array_free(&offsets));
	defer (array_free(&targets));
	isize self_edges = 0;
	for (i32 v = 0; v < node_count; v++) {
		offsets[v] = cast(i32)targets.count;
		DeclInfo *d = nodes[v]->decl_info;
		FOR_PTR_SET(dep, d->deps) {
			i32 *w = map_get(&node_index, dep);
			if (w != nullptr) {
				array_add(&targets, *w);
				self_edges += *w == v;
			}
		}
	}
	offsets[node_count] = cast(i32)targets.count;

	// Weights
	auto node_ticks = array_make<u64>(heap_allocator(), node_count);
	defer (array_free(&node_ticks));
	u64 total_ticks = 0;
	u64 when_ticks = 0;
	isize untimed = 0;
	mutex_lock(&global_entity_time_mutex);
	for (i32 v = 0; v < node_count; v++) {
		GlobalEntityTime *t = map_get(&global_entity_times, nodes[v]);
		node_ticks[v] = t ? t->ticks : 0;
		total_ticks += node_ticks[v];
		if (t == nullptr) {
			untimed += 1;
		} else if (!t->in_global_loop) {
			when_ticks += t->ticks;
		}
	}
	mutex_unlock(&global_entity_time_mutex);

	// Entity groups
	auto comp_of = array_make<i32>(heap_allocator(), node_count);
	defer (array_free(&comp_of));
	i32 comp_count = global_graph_scc(node_count, offsets, targets, &comp_of);

	auto comps = array_make<GlobalGraphComp>(heap_allocator(), comp_count);
	auto order = array_make<i32>(heap_allocator(), node_count);
	defer (array_free(&comps));
	defer (array_free(&order));
	global_graph_condense(node_count, offsets, targets, node_ticks, comp_of, comp_count, &comps, &order);

	i32 critical = -1;
	i32 largest = -1;
	isize cyclic_comps = 0;
	for (i32 ci = 0; ci < comp_count; ci++) {
		GlobalGraphComp *g = &comps[ci];
		if (critical < 0 || g->path_ticks > comps[critical].path_ticks) {
			critical = ci;
		}
		if (largest < 0 || g->count > comps[largest].count) {
			largest = ci;
		}
		cyclic_comps += g->count > 1 || g->has_self_edge;
	}

	// Packages, weighted by the entities they own
	PtrMap<AstPackage *, i32> pkg_index = {};
	map_init(&pkg_index, c->info.packages.count);
	defer (map_destroy(&pkg_index));
	auto pkgs = array_make<AstPackage *>(heap_allocator(), 0, c->info.packages.count);
	defer (array_free(&pkgs));
	auto node_pkg = array_make<i32>(heap_allocator(), node_count);
	defer (array_free(&node_pkg));
	for (i32 v = 0; v < node_count; v++) {
		AstPackage *p = nodes[v]->pkg;
		i32 *found = map_get(&pkg_index, p);
		if (found == nullptr) {
			map_set(&pkg_index, p, cast(i32)pkgs.count);
			node_pkg[v] = cast(i32)pkgs.count;
			array_add(&pkgs, p);
		} else {
			node_pkg[v] = *found;
		}
	}
	i32 pkg_count = cast(i32)pkgs.count;

	auto pkg_ticks = array_make<u64>(heap_allocator(), pkg_count);
	auto pkg_entities = array_make<i32>(heap_allocator(), pkg_count);
	defer (array_free(&pkg_ticks));
	defer (array_free(&pkg_entities));
	for (i32 p = 0; p < pkg_count; p++) {
		pkg_ticks[p] = 0;
		pkg_entities[p] = 0;
	}
	for (i32 v = 0; v < node_count; v++) {
		pkg_ticks[node_pkg[v]] += node_ticks[v];
		pkg_entities[node_pkg[v]] += 1;
	}

	auto pkg_offsets = array_make<i32>(heap_allocator(), pkg_count+1);
	auto pkg_targets = array_make<i32>(heap_allocator(), 0, pkg_count*4);
	defer (array_free(&pkg_offsets));
	defer (array_free(&pkg_targets));
	{
		auto pkg_edges = array_make<Array<i32>>(heap_allocator(), pkg_count);
		PtrMap<u64, bool> seen = {};
		map_init(&seen);
		for (i32 p = 0; p < pkg_count; p++) {
			pkg_edges[p] = array_make<i32>(heap_allocator());
		}
		for (i32 v = 0; v < node_count; v++) {
			for (i32 e = offsets[v]; e < offsets[v+1]; e++) {
				i32 pv = node_pkg[v];
				i32 pw = node_pkg[targets[e]];
				if (pv == pw) {
					continue;
				}
				u64 key = (cast(u64)(pv+1) << 32) | cast(u64)(pw+1);
				if (map_get(&seen, key) == nullptr) {
					map_set(&seen, key, true);
					array_add(&pkg_edges[pv], pw);
				}
			}
		}
		for (i32 p = 0; p < pkg_count; p++) {
			pkg_offsets[p] = cast(i32)pkg_targets.count;
			for (i32 w : pkg_edges[p]) {
				array_add(&pkg_targets, w);
			}
			array_free(&pkg_edges[p]);
		}
		pkg_offsets[pkg_count] = cast(i32)pkg_targets.count;
		array_free(&pkg_edges);
		map_destroy(&seen);
	}

	auto pkg_comp_of = array_make<i32>(heap_allocator(), pkg_count);
	defer (array_free(&pkg_comp_of));
	i32 pkg_comp_count = global_graph_scc(pkg_count, pkg_offsets, pkg_targets, &pkg_comp_of);
	auto pkg_comps = array_make<GlobalGraphComp>(heap_allocator(), pkg_comp_count);
	auto pkg_order = array_make<i32>(heap_allocator(), pkg_count);
	defer (array_free(&pkg_comps));
	defer (array_free(&pkg_order));
	global_graph_condense(pkg_count, pkg_offsets, pkg_targets, pkg_ticks, pkg_comp_of, pkg_comp_count, &pkg_comps, &pkg_order);
	u64 pkg_critical_ticks = 0;
	isize pkg_cyclic = 0;
	for (i32 ci = 0; ci < pkg_comp_count; ci++) {
		pkg_critical_ticks = gb_max(pkg_critical_ticks, pkg_comps[ci].path_ticks);
		pkg_cyclic += pkg_comps[ci].count > 1;
	}

	// Report
	f64 total_ms = global_graph_ms(total_ticks, freq);
	f64 critical_ms = critical >= 0 ? global_graph_ms(comps[critical].path_ticks, freq) : 0;
	f64 pkg_critical_ms = global_graph_ms(pkg_critical_ticks, freq);

	gb_printf_err("Global entity graph\n");
	gb_printf_err("  entities:  %td (%td not timed), dependency edges: %td (%td self edges)\n", nodes.count, untimed, targets.count, self_edges);
	gb_printf_err("  self time: %.3f ms total; %.3f ms during 'when' resolution, %.3f ms in the global loop\n",
	              total_ms, global_graph_ms(when_ticks, freq), global_graph_ms(total_ticks - when_ticks, freq));
	gb_printf_err("  groups:    %d (%td with a cycle), largest has %d entities\n",
	              comp_count, cyclic_comps, largest >= 0 ? comps[largest].count : 0);
	gb_printf_err("  critical path (entity groups): %.3f ms over %d groups -> at most %.2fx speedup\n",
	              critical_ms, critical >= 0 ? comps[critical].path_len : 0, critical_ms > 0 ? total_ms/critical_ms : 0.0);
	gb_printf_err("  critical path (packages):      %.3f ms -> at most %.2fx speedup (%d packages, %td package cycles)\n",
	              pkg_critical_ms, pkg_critical_ms > 0 ? total_ms/pkg_critical_ms : 0.0, pkg_count, pkg_cyclic);

	gb_printf_err("  check_import_entities (sequential, includes entity checks it triggers):\n");
	for (isize i = 0; i < GlobalImportStage_COUNT; i++) {
		gb_printf_err("    %10.3f ms  %s\n", global_graph_ms(global_import_stage_ticks[i], freq), global_import_stage_names[i]);
	}

	{
		i32 const BUCKET_COUNT = 10;
		i32 const bucket_max[BUCKET_COUNT] = {1, 2, 4, 8, 16, 64, 256, 1024, 4096, 0x7fffffff};
		char const *bucket_name[BUCKET_COUNT] = {"1", "2", "3-4", "5-8", "9-16", "17-64", "65-256", "257-1024", "1025-4096", ">4096"};
		isize bucket_groups[BUCKET_COUNT] = {};
		isize bucket_entities[BUCKET_COUNT] = {};
		u64   bucket_ticks[BUCKET_COUNT] = {};
		for (i32 ci = 0; ci < comp_count; ci++) {
			GlobalGraphComp *g = &comps[ci];
			for (i32 b = 0; b < BUCKET_COUNT; b++) {
				if (g->count <= bucket_max[b]) {
					bucket_groups[b] += 1;
					bucket_entities[b] += g->count;
					bucket_ticks[b] += g->ticks;
					break;
				}
			}
		}
		gb_printf_err("  group sizes:\n");
		gb_printf_err("    %10s %9s %10s %12s\n", "size", "groups", "entities", "self time");
		for (i32 b = 0; b < BUCKET_COUNT; b++) {
			if (bucket_groups[b] == 0) {
				continue;
			}
			gb_printf_err("    %10s %9td %10td %9.3f ms\n", bucket_name[b], bucket_groups[b], bucket_entities[b], global_graph_ms(bucket_ticks[b], freq));
		}
	}

	auto items = array_make<GlobalGraphSortItem>(heap_allocator(), 0, gb_max(comp_count, pkg_count));
	defer (array_free(&items));

	isize const TOP = 10;
	isize const MAX_NAMES = 4;

	array_clear(&items);
	for (i32 ci = 0; ci < comp_count; ci++) {
		array_add(&items, GlobalGraphSortItem{comps[ci].ticks, ci});
	}
	array_sort(items, global_graph_sort_item_desc);
	gb_printf_err("  slowest groups:\n");
	for (isize i = 0; i < items.count && i < TOP; i++) {
		GlobalGraphComp *g = &comps[items[i].id];
		global_graph_print_comp(nodes, order, g, g->ticks, freq, MAX_NAMES);
	}

	array_clear(&items);
	for (i32 ci = 0; ci < comp_count; ci++) {
		if (comps[ci].count > 1) {
			array_add(&items, GlobalGraphSortItem{cast(u64)comps[ci].count, ci});
		}
	}
	array_sort(items, global_graph_sort_item_desc);
	gb_printf_err("  largest groups:\n");
	for (isize i = 0; i < items.count && i < TOP; i++) {
		GlobalGraphComp *g = &comps[items[i].id];
		global_graph_print_comp(nodes, order, g, g->ticks, freq, MAX_NAMES);
	}

	gb_printf_err("  critical path, last group first:\n");
	{
		isize printed = 0;
		for (i32 ci = critical; ci >= 0; ci = comps[ci].path_prev) {
			if (printed == 30) {
				gb_printf_err("    ... %d more groups\n", comps[ci].path_len);
				break;
			}
			global_graph_print_comp(nodes, order, &comps[ci], comps[ci].ticks, freq, 2);
			printed += 1;
		}
	}

	array_clear(&items);
	for (i32 p = 0; p < pkg_count; p++) {
		array_add(&items, GlobalGraphSortItem{pkg_ticks[p], p});
	}
	array_sort(items, global_graph_sort_item_desc);
	gb_printf_err("  slowest packages:\n");
	for (isize i = 0; i < items.count && i < TOP; i++) {
		i32 p = items[i].id;
		AstPackage *pkg = pkgs[p];
		String name = pkg ? pkg->name : str_lit("?");
		gb_printf_err("    %10.3f ms %7d entities  %.*s\n", global_graph_ms(pkg_ticks[p], freq), pkg_entities[p], LIT(name));
	}
}
