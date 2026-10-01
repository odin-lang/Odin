// Global entities are checked in groups: the strongly connected components of a dependency graph built
// from syntax, in dependency order. A group only names entities of its own or of finished groups, which
// `-internal-check-global-edges` verifies

struct GlobalGroup {
	i32  start; // into `GlobalGroupGraph::members`
	i32  count;
	bool done;
};

struct GlobalGroupGraph {
	Array<Entity *>       nodes;
	PtrMap<Entity *, i32> node_of;
	Array<i32>            offsets; // node -> the nodes it names, as `targets[offsets[v]..offsets[v+1]]`
	Array<i32>            targets;
	Array<i32>            group_of;
	Array<GlobalGroup>    groups;  // every dependency of a group has a lower index
	Array<i32>            members; // nodes, by group, in source order

	bool   active;
	i32    current_group;
	Entity *current_entity;
	isize  missing_edges;
};

gb_global GlobalGroupGraph global_groups;

struct GlobalGraphWalk {
	Scope *scope;
	Array<Entity *> *refs;
};

gb_internal void global_graph_walk(GlobalGraphWalk *w, Ast *node);

gb_internal void global_graph_walk_slice(GlobalGraphWalk *w, Slice<Ast *> const &nodes) {
	for (Ast *node : nodes) {
		global_graph_walk(w, node);
	}
}

gb_internal void global_graph_add_ref(GlobalGraphWalk *w, Entity *e) {
	if (e != nullptr) {
		array_add(w->refs, e);
	}
}

// NOTE: names bound within the expression (parameters, fields, '$T') are also looked up globally, which at
// worst adds an edge; only procedure bodies are skipped, as they are checked after this stage
gb_internal void global_graph_walk(GlobalGraphWalk *w, Ast *node) {
	if (node == nullptr) {
		return;
	}
	switch (node->kind) {
	case Ast_Ident:
		global_graph_add_ref(w, scope_lookup(w->scope, node->Ident.interned, node->Ident.hash));
		break;

	case Ast_SelectorExpr: {
		Ast *expr     = node->SelectorExpr.expr;
		Ast *selector = node->SelectorExpr.selector;
		if (expr != nullptr && expr->kind == Ast_Ident) {
			Entity *e = scope_lookup(w->scope, expr->Ident.interned, expr->Ident.hash);
			if (e != nullptr && e->kind == Entity_ImportName && selector != nullptr && selector->kind == Ast_Ident) {
				global_graph_add_ref(w, scope_lookup_current(e->ImportName.scope, selector->Ident.interned, selector->Ident.hash));
			} else {
				global_graph_add_ref(w, e);
			}
		} else {
			global_graph_walk(w, expr);
		}
	} break;

	case Ast_PolyType:
		global_graph_walk(w, node->PolyType.specialization);
		break;
	case Ast_Ellipsis:
		global_graph_walk(w, node->Ellipsis.expr);
		break;
	case Ast_ProcGroup:
		global_graph_walk_slice(w, node->ProcGroup.args);
		break;
	case Ast_AsmGroup:
		global_graph_walk_slice(w, node->AsmGroup.args);
		break;
	case Ast_ProcLit:
		global_graph_walk(w, node->ProcLit.type);
		global_graph_walk_slice(w, node->ProcLit.where_clauses);
		break;
	case Ast_CompoundLit:
		global_graph_walk(w, node->CompoundLit.type);
		global_graph_walk_slice(w, node->CompoundLit.elems);
		global_graph_walk(w, node->CompoundLit.tag);
		break;
	case Ast_TagExpr:
		global_graph_walk(w, node->TagExpr.expr);
		break;
	case Ast_UnaryExpr:
		global_graph_walk(w, node->UnaryExpr.expr);
		break;
	case Ast_BinaryExpr:
		global_graph_walk(w, node->BinaryExpr.left);
		global_graph_walk(w, node->BinaryExpr.right);
		break;
	case Ast_ParenExpr:
		global_graph_walk(w, node->ParenExpr.expr);
		break;
	case Ast_SelectorCallExpr:
		global_graph_walk(w, node->SelectorCallExpr.expr);
		global_graph_walk(w, node->SelectorCallExpr.call);
		break;
	case Ast_IndexExpr:
		global_graph_walk(w, node->IndexExpr.expr);
		global_graph_walk(w, node->IndexExpr.index);
		break;
	case Ast_MatrixIndexExpr:
		global_graph_walk(w, node->MatrixIndexExpr.expr);
		global_graph_walk(w, node->MatrixIndexExpr.row_index);
		global_graph_walk(w, node->MatrixIndexExpr.column_index);
		break;
	case Ast_DerefExpr:
		global_graph_walk(w, node->DerefExpr.expr);
		break;
	case Ast_SliceExpr:
		global_graph_walk(w, node->SliceExpr.expr);
		global_graph_walk(w, node->SliceExpr.low);
		global_graph_walk(w, node->SliceExpr.high);
		break;
	case Ast_CallExpr:
		global_graph_walk(w, node->CallExpr.proc);
		global_graph_walk_slice(w, node->CallExpr.args);
		break;
	case Ast_FieldValue:
		global_graph_walk(w, node->FieldValue.field);
		global_graph_walk(w, node->FieldValue.value);
		break;
	case Ast_EnumFieldValue:
		global_graph_walk(w, node->EnumFieldValue.value);
		break;
	case Ast_TernaryIfExpr:
		global_graph_walk(w, node->TernaryIfExpr.x);
		global_graph_walk(w, node->TernaryIfExpr.cond);
		global_graph_walk(w, node->TernaryIfExpr.y);
		break;
	case Ast_TernaryWhenExpr:
		global_graph_walk(w, node->TernaryWhenExpr.x);
		global_graph_walk(w, node->TernaryWhenExpr.cond);
		global_graph_walk(w, node->TernaryWhenExpr.y);
		break;
	case Ast_OrElseExpr:
		global_graph_walk(w, node->OrElseExpr.x);
		global_graph_walk(w, node->OrElseExpr.y);
		break;
	case Ast_OrReturnExpr:
		global_graph_walk(w, node->OrReturnExpr.expr);
		break;
	case Ast_OrBranchExpr:
		global_graph_walk(w, node->OrBranchExpr.expr);
		break;
	case Ast_TypeAssertion:
		global_graph_walk(w, node->TypeAssertion.expr);
		global_graph_walk(w, node->TypeAssertion.type);
		break;
	case Ast_TypeCast:
		global_graph_walk(w, node->TypeCast.type);
		global_graph_walk(w, node->TypeCast.expr);
		break;
	case Ast_AutoCast:
		global_graph_walk(w, node->AutoCast.expr);
		break;

	case Ast_Field:
		global_graph_walk(w, node->Field.type);
		global_graph_walk(w, node->Field.default_value);
		break;
	case Ast_BitFieldField:
		global_graph_walk(w, node->BitFieldField.type);
		global_graph_walk(w, node->BitFieldField.bit_size);
		break;
	case Ast_FieldList:
		global_graph_walk_slice(w, node->FieldList.list);
		break;

	case Ast_TypeidType:
		global_graph_walk(w, node->TypeidType.specialization);
		break;
	case Ast_HelperType:
		global_graph_walk(w, node->HelperType.type);
		break;
	case Ast_DistinctType:
		global_graph_walk(w, node->DistinctType.type);
		break;
	case Ast_ProcType:
		global_graph_walk(w, node->ProcType.params);
		global_graph_walk(w, node->ProcType.results);
		break;
	case Ast_RelativeType:
		global_graph_walk(w, node->RelativeType.tag);
		global_graph_walk(w, node->RelativeType.type);
		break;
	case Ast_PointerType:
		global_graph_walk(w, node->PointerType.type);
		global_graph_walk(w, node->PointerType.tag);
		break;
	case Ast_MultiPointerType:
		global_graph_walk(w, node->MultiPointerType.type);
		break;
	case Ast_ArrayType:
		global_graph_walk(w, node->ArrayType.count);
		global_graph_walk(w, node->ArrayType.elem);
		global_graph_walk(w, node->ArrayType.tag);
		break;
	case Ast_DynamicArrayType:
		global_graph_walk(w, node->DynamicArrayType.elem);
		global_graph_walk(w, node->DynamicArrayType.tag);
		break;
	case Ast_FixedCapacityDynamicArrayType:
		global_graph_walk(w, node->FixedCapacityDynamicArrayType.elem);
		global_graph_walk(w, node->FixedCapacityDynamicArrayType.capacity);
		global_graph_walk(w, node->FixedCapacityDynamicArrayType.tag);
		break;
	case Ast_StructType:
		global_graph_walk_slice(w, node->StructType.fields);
		global_graph_walk(w, node->StructType.polymorphic_params);
		global_graph_walk(w, node->StructType.align);
		global_graph_walk(w, node->StructType.min_field_align);
		global_graph_walk(w, node->StructType.max_field_align);
		global_graph_walk_slice(w, node->StructType.where_clauses);
		break;
	case Ast_UnionType:
		global_graph_walk_slice(w, node->UnionType.variants);
		global_graph_walk(w, node->UnionType.polymorphic_params);
		global_graph_walk_slice(w, node->UnionType.where_clauses);
		break;
	case Ast_EnumType:
		global_graph_walk(w, node->EnumType.base_type);
		for (Ast *field : node->EnumType.fields) {
			if (field->kind == Ast_EnumFieldValue) {
				global_graph_walk(w, field->EnumFieldValue.value);
			}
		}
		break;
	case Ast_BitSetType:
		global_graph_walk(w, node->BitSetType.elem);
		global_graph_walk(w, node->BitSetType.underlying);
		break;
	case Ast_BitFieldType:
		global_graph_walk(w, node->BitFieldType.backing_type);
		global_graph_walk_slice(w, node->BitFieldType.fields);
		break;
	case Ast_MapType:
		global_graph_walk(w, node->MapType.count);
		global_graph_walk(w, node->MapType.key);
		global_graph_walk(w, node->MapType.value);
		break;
	case Ast_MatrixType:
		global_graph_walk(w, node->MatrixType.row_count);
		global_graph_walk(w, node->MatrixType.column_count);
		global_graph_walk(w, node->MatrixType.elem);
		break;

	case Ast_AsmTemplate:
		global_graph_walk(w, node->AsmTemplate.signature);
		global_graph_walk_slice(w, node->AsmTemplate.specs);
		global_graph_walk_slice(w, node->AsmTemplate.clobbers);
		global_graph_walk_slice(w, node->AsmTemplate.instructions);
		break;
	case Ast_AsmSpec:
		global_graph_walk(w, node->AsmSpec.type);
		global_graph_walk(w, node->AsmSpec.value);
		for (Ast *d : node->AsmSpec.directives) {
			global_graph_walk(w, d);
		}
		break;
	case Ast_AsmClobber:
		global_graph_walk(w, node->AsmClobber.value);
		break;
	case Ast_AsmInstruction:
		global_graph_walk_slice(w, node->AsmInstruction.operands);
		break;
	case Ast_AsmMemoryTerm:
		global_graph_walk(w, node->AsmMemoryTerm.operand);
		global_graph_walk(w, node->AsmMemoryTerm.scale);
		break;
	case Ast_AsmMemoryOperand:
		global_graph_walk(w, node->AsmMemoryOperand.segment_override);
		global_graph_walk_slice(w, node->AsmMemoryOperand.terms);
		global_graph_walk(w, node->AsmMemoryOperand.type);
		break;
	case Ast_AsmRegisterGroup:
		for (Ast *r : node->AsmRegisterGroup.registers) {
			global_graph_walk(w, r);
		}
		global_graph_walk(w, node->AsmRegisterGroup.type);
		break;
	case Ast_AsmDirective:
		global_graph_walk_slice(w, node->AsmDirective.operands);
		break;
	}
}

gb_internal void global_graph_walk_entity(GlobalGraphWalk *w, Entity *e, DeclInfo *d) {
	w->scope = d->scope;
	global_graph_walk(w, d->type_expr);
	global_graph_walk(w, d->init_expr);
	for (Ast *attr : d->attributes) {
		if (attr->kind != Ast_Attribute) {
			continue;
		}
		for (Ast *elem : attr->Attribute.elems) {
			if (elem->kind == Ast_FieldValue) {
				global_graph_walk(w, elem->FieldValue.value);
			}
		}
	}
	if (e->kind == Entity_Procedure) {
		global_graph_walk(w, e->Procedure.foreign_library_ident);
	} else if (e->kind == Entity_Variable) {
		global_graph_walk(w, e->Variable.foreign_library_ident);
	}
}

gb_internal bool is_global_graph_node(Entity *e) {
	if (e->state == EntityState_Resolved) {
		return false;
	}
	DeclInfo *d = e->decl_info;
	if (d == nullptr || e->scope == nullptr || d->scope != e->scope || (e->scope->flags & ScopeFlag_File) == 0) {
		return false;
	}
	switch (e->kind) {
	case Entity_Constant:
	case Entity_TypeName:
	case Entity_Variable:
	case Entity_Procedure:
	case Entity_ProcGroup:
	case Entity_AsmTemplate:
		return true;
	}
	return false;
}

gb_internal i32 global_graph_add_node(GlobalGroupGraph *g, Entity *e) {
	i32 *found = map_get(&g->node_of, e);
	if (found != nullptr) {
		return *found;
	}
	i32 v = cast(i32)g->nodes.count;
	map_set(&g->node_of, e, v);
	array_add(&g->nodes, e);
	return v;
}

gb_internal u64 global_group_random(u64 *state) {
	*state = *state*6364136223846793005ull + 1442695040888963407ull;
	return *state >> 33;
}

// The nodes `[lo, hi)` walked on one thread; a name that is not a node yet is kept as an entity in `refs`
struct GlobalGraphWalkChunk {
	GlobalGroupGraph *g;
	i32               lo, hi;
	Array<i32>        targets;
	Array<i32>        target_ends; // per node
	Array<Entity *>   refs;
	Array<i32>        ref_ends;    // per node
};

gb_internal WORKER_TASK_PROC(global_graph_walk_worker) {
	GlobalGraphWalkChunk *chunk = cast(GlobalGraphWalkChunk *)data;
	GlobalGroupGraph *g = chunk->g;

	auto refs = array_make<Entity *>(heap_allocator(), 0, 64);
	defer (array_free(&refs));
	GlobalGraphWalk w = {};
	w.refs = &refs;
	for (i32 v = chunk->lo; v < chunk->hi; v++) {
		Entity *e = g->nodes[v];
		array_clear(&refs);
		global_graph_walk_entity(&w, e, e->decl_info);
		for (Entity *r : refs) {
			i32 *found = map_get(&g->node_of, r);
			if (found != nullptr) {
				array_add(&chunk->targets, *found);
			} else if (r->flags & EntityFlag_Lazy) {
				array_add(&chunk->refs, r);
			}
		}
		array_add(&chunk->target_ends, cast(i32)chunk->targets.count);
		array_add(&chunk->ref_ends,    cast(i32)chunk->refs.count);
	}
	return 0;
}

gb_internal void build_global_groups(Checker *c, GlobalGroupGraph *g) {
	array_init(&g->nodes, heap_allocator(), 0, c->info.entities.count);
	map_init(&g->node_of, c->info.entities.count);
	for (Entity *e : c->info.entities) {
		if ((e->flags & EntityFlag_Lazy) == 0 && is_global_graph_node(e)) {
			global_graph_add_node(g, e);
		}
	}

	// NOTE: walked in parallel, as nothing writes to the scopes now
	i32 const CHUNK_SIZE = 64;
	i32 initial_count = cast(i32)g->nodes.count;
	auto chunks = array_make<GlobalGraphWalkChunk>(heap_allocator(), (initial_count + CHUNK_SIZE-1)/CHUNK_SIZE);
	defer (array_free(&chunks));
	for (isize i = 0; i < chunks.count; i++) {
		GlobalGraphWalkChunk *chunk = &chunks[i];
		*chunk = {};
		chunk->g  = g;
		chunk->lo = cast(i32)(i*CHUNK_SIZE);
		chunk->hi = gb_min(chunk->lo + CHUNK_SIZE, initial_count);
		array_init(&chunk->targets,     heap_allocator(), 0, 4*CHUNK_SIZE);
		array_init(&chunk->target_ends, heap_allocator(), 0, CHUNK_SIZE);
		array_init(&chunk->refs,        heap_allocator(), 0);
		array_init(&chunk->ref_ends,    heap_allocator(), 0, CHUNK_SIZE);
		thread_pool_add_task(global_graph_walk_worker, chunk);
	}
	thread_pool_wait();

	auto edge_from = array_make<i32>(heap_allocator(), 0, 4*g->nodes.count);
	auto edge_to   = array_make<i32>(heap_allocator(), 0, 4*g->nodes.count);
	auto refs      = array_make<Entity *>(heap_allocator(), 0, 64);
	defer (array_free(&edge_from));
	defer (array_free(&edge_to));
	defer (array_free(&refs));

	auto add_ref = [&](i32 v, Entity *r) {
		i32 *found = map_get(&g->node_of, r);
		if (found != nullptr) {
			array_add(&edge_from, v);
			array_add(&edge_to, *found);
		} else if ((r->flags & EntityFlag_Lazy) && is_global_graph_node(r)) {
			// NOTE: a lazy entity becomes a node once a node names it
			array_add(&edge_from, v);
			array_add(&edge_to, global_graph_add_node(g, r));
		}
	};

	GlobalGraphWalk w = {};
	w.refs = &refs;
	i32 first_of_decl = -1;
	for (i32 v = 0; v < g->nodes.count; v++) {
		Entity *e = g->nodes[v];
		DeclInfo *d = e->decl_info;

		// NOTE: entities sharing one declaration share its AST, e.g. `a, b: struct{x: int}`, so they share a group;
		// in source order they are adjacent, and lazy ones are only checked under `lazy_mutex`
		if (first_of_decl >= 0 && d->decl_node != nullptr && g->nodes[first_of_decl]->decl_info->decl_node == d->decl_node) {
			array_add(&edge_from, v);
			array_add(&edge_to,   first_of_decl);
			array_add(&edge_from, first_of_decl);
			array_add(&edge_to,   v);
		} else {
			first_of_decl = v;
		}

		if (v < initial_count) {
			GlobalGraphWalkChunk *chunk = &chunks[v / CHUNK_SIZE];
			i32 k = v - chunk->lo;
			for (i32 i = k > 0 ? chunk->target_ends[k-1] : 0; i < chunk->target_ends[k]; i++) {
				array_add(&edge_from, v);
				array_add(&edge_to, chunk->targets[i]);
			}
			for (i32 i = k > 0 ? chunk->ref_ends[k-1] : 0; i < chunk->ref_ends[k]; i++) {
				add_ref(v, chunk->refs[i]);
			}
		} else {
			array_clear(&refs);
			global_graph_walk_entity(&w, e, d);
			for (Entity *r : refs) {
				add_ref(v, r);
			}
		}
	}
	for (GlobalGraphWalkChunk &chunk : chunks) {
		array_free(&chunk.targets);
		array_free(&chunk.target_ends);
		array_free(&chunk.refs);
		array_free(&chunk.ref_ends);
	}

	i32 node_count = cast(i32)g->nodes.count;
	array_init(&g->offsets, heap_allocator(), node_count+1);
	array_init(&g->targets, heap_allocator(), edge_to.count);
	for (i32 v = 0; v <= node_count; v++) {
		g->offsets[v] = 0;
	}
	for (i32 from : edge_from) {
		g->offsets[from+1] += 1;
	}
	for (i32 v = 0; v < node_count; v++) {
		g->offsets[v+1] += g->offsets[v];
	}
	{
		auto fill = array_clone(heap_allocator(), g->offsets);
		defer (array_free(&fill));
		for (isize i = 0; i < edge_from.count; i++) {
			g->targets[fill[edge_from[i]]++] = edge_to[i];
		}
	}

	array_init(&g->group_of, heap_allocator(), node_count);
	i32 group_count = global_graph_scc(node_count, g->offsets, g->targets, &g->group_of);

	array_init(&g->groups,  heap_allocator(), group_count);
	array_init(&g->members, heap_allocator(), node_count);
	for (i32 gi = 0; gi < group_count; gi++) {
		g->groups[gi] = {};
	}
	for (i32 v = 0; v < node_count; v++) {
		g->groups[g->group_of[v]].count += 1;
	}
	i32 start = 0;
	for (i32 gi = 0; gi < group_count; gi++) {
		g->groups[gi].start = start;
		start += g->groups[gi].count;
		g->groups[gi].count = 0;
	}
	// NOTE: in source order, as `c->info.entities` is sorted; lazy nodes come last, but are not checked here
	for (i32 v = 0; v < node_count; v++) {
		GlobalGroup *group = &g->groups[g->group_of[v]];
		g->members[group->start + group->count++] = v;
	}
}

gb_internal void global_group_print_entity(Entity *e) {
	if (e == nullptr) {
		gb_printf_err("?");
		return;
	}
	global_graph_print_entity(e);
}

// Called when `e` starts being checked: it must be in the current group or a finished one
gb_internal void global_group_check_edge(CheckerContext *ctx, Entity *e) {
	GlobalGroupGraph *g = &global_groups;
	if (!g->active) {
		return;
	}
	i32 *v = map_get(&g->node_of, e);
	if (v == nullptr) {
		if (!is_global_graph_node(e)) {
			return;
		}
	} else {
		i32 gi = g->group_of[*v];
		if (gi == g->current_group || g->groups[gi].done) {
			return;
		}
	}

	g->missing_edges += 1;
	if (build_context.internal_check_global_edges) {
		Entity *by = ctx->decl ? ctx->decl->entity.load() : nullptr;
		gb_printf_err("Missing global dependency: ");
		global_group_print_entity(by);
		gb_printf_err(" needs ");
		global_group_print_entity(e);
		gb_printf_err(v == nullptr ? ", which is not in the graph" : "");
		if (g->current_entity != by) {
			gb_printf_err(", while checking ");
			global_group_print_entity(g->current_entity);
		}
		gb_printf_err("\n");
	}
}

// NOTE: members in a fixed order, as which member of a cycle is entered first can decide whether it checks,
// e.g. an enum whose values are `union_variant_index`es of a union with pointers back to it
gb_internal void check_global_group(Checker *c, GlobalGroupGraph *g, i32 gi) {
	GlobalGroup *group = &g->groups[gi];
	i32 *members = g->members.data + group->start;

	g->current_group = gi;
	for (i32 k = 0; k < group->count; k++) {
		Entity *e = g->nodes[members[k]];
		if (e->flags & EntityFlag_Lazy) {
			// NOTE: only checked when something uses it; the group orders it after what it names
			continue;
		}
		g->current_entity = e;
		GlobalEntityTimingFrame timing_frame = global_entity_timing_begin(e);
		check_single_global_entity(c, e, e->decl_info);
		if (e->type != nullptr && is_type_typed(e->type)) {
			for (Type *t = nullptr; mpsc_dequeue(&c->soa_types_to_complete, &t); /**/) {
				complete_soa_type(c, t, false);
			}

			(void)type_size_of(e->type);
			(void)type_align_of(e->type);
		}
		global_entity_timing_end(timing_frame, e);
	}
	group->done = true;
	g->current_group = -1;
	g->current_entity = nullptr;
}

// Groups in dependency order; with `-internal-shuffle-global-entities`, a random one of the groups whose
// dependencies are done, as a parallel checker might
gb_internal void check_global_groups(Checker *c, GlobalGroupGraph *g) {
	i32 group_count = cast(i32)g->groups.count;
	u64 seed = build_context.internal_shuffle_global_entities;
	if (seed == 0) {
		for (i32 gi = 0; gi < group_count; gi++) {
			check_global_group(c, g, gi);
		}
		return;
	}

	auto dependents = array_make<Array<i32> >(heap_allocator(), group_count);
	auto dep_count  = array_make<i32>        (heap_allocator(), group_count);
	auto seen       = array_make<i32>        (heap_allocator(), group_count);
	auto ready      = array_make<i32>        (heap_allocator(), 0, group_count);
	defer ({
		for (auto &d : dependents) {
			array_free(&d);
		}
		array_free(&dependents);
	});
	defer (array_free(&dep_count));
	defer (array_free(&seen));
	defer (array_free(&ready));

	for (i32 gi = 0; gi < group_count; gi++) {
		dep_count[gi] = 0;
		dependents[gi] = {};
		seen[gi] = -1;
	}
	for (i32 gi = 0; gi < group_count; gi++) {
		GlobalGroup const &group = g->groups[gi];
		for (i32 k = 0; k < group.count; k++) {
			i32 v = g->members[group.start + k];
			for (i32 i = g->offsets[v]; i < g->offsets[v+1]; i++) {
				i32 dep = g->group_of[g->targets[i]];
				if (dep != gi && seen[dep] != gi) {
					seen[dep] = gi;
					dep_count[gi] += 1;
					if (dependents[dep].allocator.proc == nullptr) {
						array_init(&dependents[dep], heap_allocator());
					}
					array_add(&dependents[dep], gi);
				}
			}
		}
		if (dep_count[gi] == 0) {
			array_add(&ready, gi);
		}
	}

	u64 state = seed;
	isize checked = 0;
	while (ready.count > 0) {
		isize i = cast(isize)(global_group_random(&state) % cast(u64)ready.count);
		i32 gi = ready[i];
		ready[i] = ready[ready.count-1];
		array_pop(&ready);

		check_global_group(c, g, gi);
		checked += 1;
		for (i32 next : dependents[gi]) {
			if (--dep_count[next] == 0) {
				array_add(&ready, next);
			}
		}
	}
	GB_ASSERT(checked == group_count);
}

gb_internal void destroy_global_groups(GlobalGroupGraph *g) {
	array_free(&g->nodes);
	map_destroy(&g->node_of);
	array_free(&g->offsets);
	array_free(&g->targets);
	array_free(&g->group_of);
	array_free(&g->groups);
	array_free(&g->members);
}

// -internal-global-entity-graph: the graph the groups come from, weighted by the measured self times
gb_internal void print_global_groups(GlobalGroupGraph *g) {
	u64 const freq = time_stamp__freq();
	i32 group_count = cast(i32)g->groups.count;

	auto ticks = array_make<u64>(heap_allocator(), group_count);
	auto path  = array_make<u64>(heap_allocator(), group_count);
	auto seen  = array_make<i32>(heap_allocator(), group_count);
	defer (array_free(&ticks));
	defer (array_free(&path));
	defer (array_free(&seen));

	u64   total   = 0;
	i32   largest = 0;
	isize cyclic  = 0;
	mutex_lock(&global_entity_time_mutex);
	for (i32 gi = 0; gi < group_count; gi++) {
		GlobalGroup const &group = g->groups[gi];
		ticks[gi] = 0;
		seen[gi] = -1;
		for (i32 k = 0; k < group.count; k++) {
			GlobalEntityTime *t = map_get(&global_entity_times, g->nodes[g->members[group.start + k]]);
			ticks[gi] += t ? t->ticks : 0;
		}
		total += ticks[gi];
		largest = gb_max(largest, group.count);
		cyclic += group.count > 1;
	}
	mutex_unlock(&global_entity_time_mutex);

	u64 critical = 0;
	for (i32 gi = 0; gi < group_count; gi++) {
		GlobalGroup const &group = g->groups[gi];
		u64 longest = 0;
		for (i32 k = 0; k < group.count; k++) {
			i32 v = g->members[group.start + k];
			for (i32 i = g->offsets[v]; i < g->offsets[v+1]; i++) {
				i32 dep = g->group_of[g->targets[i]];
				if (dep != gi && seen[dep] != gi) {
					seen[dep] = gi;
					longest = gb_max(longest, path[dep]);
				}
			}
		}
		path[gi] = ticks[gi] + longest;
		critical = gb_max(critical, path[gi]);
	}

	f64 total_ms = global_graph_ms(total, freq);
	f64 critical_ms = global_graph_ms(critical, freq);
	gb_printf_err("Global groups (syntactic graph, as scheduled)\n");
	gb_printf_err("  nodes: %td, edges: %td, groups: %d (%td with a cycle), largest has %d entities\n",
	              g->nodes.count, g->targets.count, group_count, cyclic, largest);
	gb_printf_err("  critical path: %.3f ms of %.3f ms -> at most %.2fx speedup\n",
	              critical_ms, total_ms, critical_ms > 0 ? total_ms/critical_ms : 0.0);
	gb_printf_err("  missing edges: %td\n", g->missing_edges);
}

gb_internal void check_all_global_entities(Checker *c) {
	in_single_threaded_checker_stage.store(true, std::memory_order_relaxed);

	// NOTE(bill): the runtime types the checker looks up by name rather than through a declaration
	init_preload(c);
	{
		u32 hash = 0;
		InternedString name = string_interner_insert(str_lit("Load_Directory_File"), 0, &hash);
		if (scope_lookup_current(c->info.runtime_package->scope, name, hash) != nullptr) {
			init_core_load_directory_file(c);
		}
	}

	TIME_SECTION("check all global entities - build groups");
	GlobalGroupGraph *g = &global_groups;
	build_global_groups(c, g);

	TIME_SECTION("check all global entities - check groups");
	g->active = true;
	g->current_group = -1;
	check_global_groups(c, g);
	g->active = false;

	if (build_context.internal_check_global_edges && g->missing_edges > 0) {
		gb_printf_err("%td missing global dependencies\n", g->missing_edges);
		gb_exit(1);
	}

	in_single_threaded_checker_stage.store(false, std::memory_order_relaxed);
}
