// Global declarations: 'when's and 'foreign' blocks resolved on demand in `check_import_entities`, then the
// global entities checked in groups of a dependency graph, plus what `-internal-global-entity-graph` reports

// Timing for -internal-global-entity-graph: the self time of each global entity, and the parts of
// `check_import_entities`

struct GlobalEntityTime {
	u64  ticks;
	bool in_global_loop;
};

enum GlobalImportStagePart {
	GlobalImportStage_Imports,
	GlobalImportStage_Placeholders,
	GlobalImportStage_DeclSources,
	GlobalImportStage_TypeAliases,
	GlobalImportStage_DelayedExprs,

	GlobalImportStage_COUNT,
};

gb_global char const *global_import_stage_names[GlobalImportStage_COUNT] = {
	"imports",
	"'when' and 'foreign' placeholders",
	"resolve 'when' and 'foreign' blocks",
	"type alias correction",
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

	f.saved_child_ticks = global_entity_child_ticks;
	global_entity_child_ticks = 0;

	f.active = true;
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


// Global 'when's and 'foreign' blocks: every name one may declare is a placeholder in its scope, and the
// first lookup of a placeholder resolves them, so the order of files and declarations does not matter

struct GlobalDeclSource {
	Ast *             node; // WhenStmt or ForeignBlockDecl
	AstFile *         file;
	GlobalDeclSource *parent;
	bool              in_else; // within the else branch of `parent`
	bool              reachable;
	bool              reported_cycle;
	EntityState       state;
	ForeignContext    foreign_context; // of a resolved 'foreign' block
};

struct GlobalDeclSourceFrame {
	GlobalDeclSource *source;
	InternedString    needs; // the placeholder being resolved for it
};

gb_global Array<GlobalDeclSource *>    global_decl_sources;
gb_global Array<GlobalDeclSourceFrame> global_decl_source_stack;
gb_global Array<Scope *>               global_placeholder_scopes;
gb_global CheckerContext               global_decl_source_export_ctx;
gb_global UntypedExprInfoMap           global_decl_source_export_untyped;

enum : u8 {
	PlaceholderScope_File = 1<<0,
	PlaceholderScope_Pkg  = 1<<1,
};

// -1 when 'private' has a value that is not a string literal
gb_internal i32 syntactic_visibility(Array<Ast *> const &attributes) {
	for (Ast *attr : attributes) {
		if (attr->kind != Ast_Attribute) {
			continue;
		}
		for (Ast *elem : attr->Attribute.elems) {
			if (elem->kind == Ast_Ident && elem->Ident.token.string == "private") {
				return EntityVisiblity_PrivateToPackage;
			}
			if (elem->kind == Ast_FieldValue &&
			    elem->FieldValue.field->kind == Ast_Ident &&
			    elem->FieldValue.field->Ident.token.string == "private") {
				Ast *value = elem->FieldValue.value;
				if (value != nullptr && value->tav.value.kind == ExactValue_String) {
					return value->tav.value.value_string == "file" ? EntityVisiblity_PrivateToFile : EntityVisiblity_PrivateToPackage;
				}
				return -1;
			}
		}
	}
	return EntityVisiblity_Public;
}

gb_internal bool has_syntactic_attribute(Array<Ast *> const &attributes, String const &name) {
	for (Ast *attr : attributes) {
		if (attr->kind != Ast_Attribute) {
			continue;
		}
		for (Ast *elem : attr->Attribute.elems) {
			Ast *field = elem->kind == Ast_FieldValue ? elem->FieldValue.field : elem;
			if (field->kind == Ast_Ident && field->Ident.token.string == name) {
				return true;
			}
		}
	}
	return false;
}

gb_internal void add_placeholder(Scope *s, InternedString name, GlobalDeclSource *src) {
	if (name.value == 0 || name.is_blank()) {
		return;
	}
	if (s->placeholders == nullptr) {
		s->placeholders = permanent_alloc_item<PtrMap<u64, GlobalDeclSource *>>();
		map_init(s->placeholders);
		array_add(&global_placeholder_scopes, s);
	}
	u64 key = name.value;
	for (auto *e = multi_map_find_first(s->placeholders, key); e != nullptr; e = multi_map_find_next(s->placeholders, e)) {
		if (e->value == src) {
			return;
		}
	}
	multi_map_insert(s->placeholders, key, src);
}

gb_internal void add_placeholders(AstFile *f, u8 scopes, InternedString name, GlobalDeclSource *src) {
	if (scopes & PlaceholderScope_File) {
		add_placeholder(f->scope, name, src);
	}
	if (scopes & PlaceholderScope_Pkg) {
		add_placeholder(f->pkg->scope, name, src);
	}
}

gb_internal GlobalDeclSource *add_global_decl_source(Ast *node, AstFile *f, GlobalDeclSource *parent, bool in_else) {
	GlobalDeclSource *src = permanent_alloc_item<GlobalDeclSource>();
	src->node      = node;
	src->file      = f;
	src->parent    = parent;
	src->in_else   = in_else;
	src->reachable = true;
	src->state     = EntityState_Unresolved;
	array_add(&global_decl_sources, src);
	return src;
}

gb_internal void scan_global_decl_sources(AstFile *f, Slice<Ast *> const &stmts, GlobalDeclSource *owner, bool in_else, i32 foreign_visibility);

gb_internal void scan_global_when_stmt(AstFile *f, Ast *node, GlobalDeclSource *parent, bool in_else, i32 foreign_visibility) {
	ast_node(ws, WhenStmt, node);
	GlobalDeclSource *src = add_global_decl_source(node, f, parent, in_else);
	if (ws->body != nullptr && ws->body->kind == Ast_BlockStmt) {
		scan_global_decl_sources(f, ws->body->BlockStmt.stmts, src, false, foreign_visibility);
	}
	if (ws->else_stmt != nullptr) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			scan_global_decl_sources(f, ws->else_stmt->BlockStmt.stmts, src, true, foreign_visibility);
			break;
		case Ast_WhenStmt:
			scan_global_when_stmt(f, ws->else_stmt, src, true, foreign_visibility);
			break;
		}
	}
}

gb_internal void scan_global_decl_sources(AstFile *f, Slice<Ast *> const &stmts, GlobalDeclSource *owner, bool in_else, i32 foreign_visibility) {
	// NOTE(bill): `owner == nullptr` is the file scope itself, whose other declarations are already collected
	for (Ast *decl : stmts) {
		switch (decl->kind) {
		case_ast_node(vd, ValueDecl, decl);
			if (owner == nullptr) {
				break;
			}
			i32 visibility = syntactic_visibility(vd->attributes);
			if (visibility == EntityVisiblity_Public) {
				visibility = foreign_visibility;
			}
			if (visibility == EntityVisiblity_Public && (f->flags & AstFile_IsPrivateFile)) {
				visibility = EntityVisiblity_PrivateToFile;
			}
			u8 scopes = PlaceholderScope_Pkg;
			if (visibility == EntityVisiblity_PrivateToFile) {
				scopes = PlaceholderScope_File;
			} else if (visibility < 0) {
				scopes = PlaceholderScope_File|PlaceholderScope_Pkg;
			}
			for (Ast *name : vd->names) {
				if (name->kind == Ast_Ident) {
					add_placeholders(f, scopes, name->Ident.interned, owner);
				}
			}
		case_end;

		case_ast_node(fl, ForeignImportDecl, decl);
			if (owner == nullptr) {
				break;
			}
			String library_name = fl->library_name.string;
			if (library_name.len == 0 && fl->fullpaths.count != 0) {
				library_name = path_to_entity_name(fl->library_name.string, fl->fullpaths[0]);
			}
			if (library_name.len != 0) {
				u8 scopes = has_syntactic_attribute(fl->attributes, str_lit("export")) ? PlaceholderScope_Pkg : PlaceholderScope_File;
				add_placeholders(f, scopes, string_interner_insert(library_name), owner);
			}
		case_end;

		case_ast_node(fb, ForeignBlockDecl, decl);
			GlobalDeclSource *src = add_global_decl_source(decl, f, owner, in_else);
			if (fb->body != nullptr && fb->body->kind == Ast_BlockStmt) {
				scan_global_decl_sources(f, fb->body->BlockStmt.stmts, src, false, syntactic_visibility(fb->attributes));
			}
		case_end;

		case_ast_node(ws, WhenStmt, decl);
			scan_global_when_stmt(f, decl, owner, in_else, foreign_visibility);
		case_end;

		case_ast_node(es, ExprStmt, decl);
			if (owner == nullptr && es->expr->kind == Ast_CallExpr &&
			    es->expr->CallExpr.proc->kind == Ast_BasicDirective &&
			    (decl->state_flags & StateFlag_BeenHandled) == 0) {
				decl->state_flags |= StateFlag_BeenHandled;
				array_add(&f->delayed_decls_queues[AstDelayQueue_Expr], es->expr);
			}
		case_end;
		}
	}
}

gb_internal bool is_global_decl_source_in_when(GlobalDeclSource *src) {
	for (; src != nullptr; src = src->parent) {
		if (src->node->kind == Ast_WhenStmt) {
			return true;
		}
	}
	return false;
}

gb_internal Slice<Ast *> global_decl_source_taken_stmts(GlobalDeclSource *src) {
	if (src->node->kind == Ast_ForeignBlockDecl) {
		Ast *body = src->node->ForeignBlockDecl.body;
		if (body != nullptr && body->kind == Ast_BlockStmt) {
			return body->BlockStmt.stmts;
		}
		return {};
	}
	ast_node(ws, WhenStmt, src->node);
	if (ws->determined_cond) {
		if (ws->body != nullptr && ws->body->kind == Ast_BlockStmt) {
			return ws->body->BlockStmt.stmts;
		}
	} else if (ws->else_stmt != nullptr && ws->else_stmt->kind == Ast_BlockStmt) {
		return ws->else_stmt->BlockStmt.stmts;
	}
	return {};
}

gb_internal void collect_global_decl_source_stmts(CheckerContext *ctx, Slice<Ast *> const &stmts) {
	AstFile *f = ctx->file;
	for (Ast *decl : stmts) {
		if (decl->kind == Ast_ValueDecl) {
			check_collect_value_decl(ctx, decl);
		}
	}
	check_export_entities_in_pkg(&global_decl_source_export_ctx, f->pkg, &global_decl_source_export_untyped);

	// NOTE(bill): after the value declarations, as their attributes are evaluated
	for (Ast *decl : stmts) {
		switch (decl->kind) {
		case_ast_node(fl, ForeignImportDecl, decl);
			check_add_foreign_import_decl(ctx, decl);
		case_end;

		case_ast_node(es, ExprStmt, decl);
			if (es->expr->kind == Ast_CallExpr && es->expr->CallExpr.proc->kind == Ast_BasicDirective &&
			    (decl->state_flags & StateFlag_BeenHandled) == 0) {
				decl->state_flags |= StateFlag_BeenHandled;
				array_add(&f->delayed_decls_queues[AstDelayQueue_Expr], es->expr);
			}
		case_end;
		}
	}
}

gb_internal Token global_decl_source_token(GlobalDeclSource *src) {
	if (src->node->kind == Ast_WhenStmt) {
		return src->node->WhenStmt.token;
	}
	return src->node->ForeignBlockDecl.token;
}

gb_internal void report_global_decl_source_cycle(GlobalDeclSource *src, InternedString needed) {
	if (src->reported_cycle) {
		return;
	}
	src->reported_cycle = true;

	isize start = 0;
	for (isize i = global_decl_source_stack.count-1; i >= 0; i--) {
		if (global_decl_source_stack[i].source == src) {
			start = i;
			break;
		}
	}

	ERROR_BLOCK();
	Token token = global_decl_source_token(src);
	error(token, "Cyclic dependency between global '%.*s' declarations", LIT(token.string));
	for (isize i = start; i < global_decl_source_stack.count; i++) {
		Token t = global_decl_source_token(global_decl_source_stack[i].source);
		InternedString name = i+1 < global_decl_source_stack.count ? global_decl_source_stack[i].needs : needed;
		error_line("\t'%.*s' at %s needs '%s', which may be declared by\n", LIT(t.string), token_pos_to_string(t.pos), name.cstring());
	}
	error_line("\t'%.*s' at %s\n", LIT(token.string), token_pos_to_string(token.pos));
}

gb_internal void resolve_global_decl_source(GlobalDeclSource *src, InternedString needed) {
	if (src->state == EntityState_Resolved) {
		return;
	}
	if (src->state == EntityState_InProgress) {
		report_global_decl_source_cycle(src, needed);
		return;
	}

	GlobalDeclSource *foreign_block = nullptr;
	if (src->parent != nullptr) {
		GlobalDeclSource *parent = src->parent;
		resolve_global_decl_source(parent, needed);
		if (parent->state != EntityState_Resolved) {
			return;
		}
		bool reachable = parent->reachable;
		if (parent->node->kind == Ast_WhenStmt) {
			reachable = reachable && parent->node->WhenStmt.determined_cond != src->in_else;
		}
		if (!reachable) {
			src->reachable = false;
			src->state = EntityState_Resolved;
			return;
		}
		for (GlobalDeclSource *p = parent; p != nullptr; p = p->parent) {
			if (p->node->kind == Ast_ForeignBlockDecl) {
				foreign_block = p;
				break;
			}
		}
	}

	src->state = EntityState_InProgress;
	array_add(&global_decl_source_stack, GlobalDeclSourceFrame{src, {}});

	CheckerContext ctx = {};
	init_checker_context(&ctx, global_checker_ptr.load(std::memory_order_relaxed));
	UntypedExprInfoMap untyped = {};
	reset_checker_context(&ctx, src->file, &untyped);
	if (foreign_block != nullptr) {
		ctx.foreign_context = foreign_block->foreign_context;
	}

	if (src->node->kind == Ast_WhenStmt) {
		ast_node(ws, WhenStmt, src->node);
		Operand operand = {Addressing_Invalid};
		check_expr(&ctx, &operand, ws->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error(ws->cond, "Non-boolean condition in 'when' statement");
		}
		if (operand.mode != Addressing_Constant) {
			error(ws->cond, "Non-constant condition in 'when' statement");
		}
		ws->is_cond_determined = true;
		ws->determined_cond = operand.value.kind == ExactValue_Bool && operand.value.value_bool;
		if (ws->body == nullptr || ws->body->kind != Ast_BlockStmt) {
			error(ws->cond, "Invalid body for 'when' statement");
		} else if (ws->else_stmt != nullptr && ws->else_stmt->kind != Ast_BlockStmt && ws->else_stmt->kind != Ast_WhenStmt) {
			error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
		}
	} else {
		ast_node(fb, ForeignBlockDecl, src->node);
		if (fb->foreign_library->kind == Ast_Ident) {
			ctx.foreign_context.curr_library = fb->foreign_library;
		} else {
			error(fb->foreign_library, "Foreign block name must be an identifier or 'export'");
			ctx.foreign_context.curr_library = nullptr;
		}
		check_decl_attributes(&ctx, fb->attributes, foreign_block_decl_attribute, nullptr);
		src->foreign_context = ctx.foreign_context;
	}

	// NOTE: resolved before its declarations are collected, which evaluates the attributes of 'foreign import's
	src->state = EntityState_Resolved;
	array_pop(&global_decl_source_stack);

	collect_global_decl_source_stmts(&ctx, global_decl_source_taken_stmts(src));

	add_untyped_expressions(ctx.info, &untyped);
	map_destroy(&untyped);
	destroy_checker_context(&ctx);
}

gb_internal Entity *force_scope_placeholders(Scope *s, InternedString name, u32 hash) {
	PtrMap<u64, GlobalDeclSource *> *m = s->placeholders;
	bool forced = false;
	for (auto *e = multi_map_find_first(m, cast(u64)name.value); e != nullptr; e = multi_map_find_next(m, e)) {
		GlobalDeclSource *src = e->value;
		if (src->state != EntityState_Resolved) {
			if (global_decl_source_stack.count > 0) {
				global_decl_source_stack[global_decl_source_stack.count-1].needs = name;
			}
			resolve_global_decl_source(src, name);
			forced = true;
		}
	}
	if (!forced) {
		return nullptr;
	}
	rw_mutex_shared_lock(&s->mutex);
	Entity *found = scope_map_get(&s->elements, name, hash);
	rw_mutex_shared_unlock(&s->mutex);
	return found;
}

gb_internal void check_vet_when_shadowing_entity(Entity *e) {
	if (e == nullptr || e->scope == nullptr || (e->scope->flags & ScopeFlag_File) == 0) {
		return;
	}
	InternedString name = entity_interned_name(e);
	u32 hash = e->interned_name_hash.load(std::memory_order_relaxed);
	Scope *outer = e->scope->parent;
	if (scope_map_get(&e->scope->elements, name, hash) != e) {
		outer = outer->parent; // in the package scope
	}
	if (outer == nullptr) {
		return;
	}
	Entity *shadowed = scope_lookup(outer, name, hash);
	if (shadowed == nullptr || shadowed == e) {
		return;
	}
	if (shadowed->scope == builtin_pkg->scope) {
		error(e->token, "Declaration of '%.*s' within a global 'when' shadows the builtin '%.*s'", LIT(e->token.string), LIT(e->token.string));
	} else {
		error(e->token, "Declaration of '%.*s' within a global 'when' shadows the declaration at %s", LIT(e->token.string), token_pos_to_string(shadowed->token.pos));
	}
}

gb_internal void check_vet_when_shadowing(void) {
	for (GlobalDeclSource *src : global_decl_sources) {
		if (!src->reachable || src->state != EntityState_Resolved) {
			continue;
		}
		if ((ast_file_vet_flags(src->file) & VetFlag_WhenShadowing) == 0 || !is_global_decl_source_in_when(src)) {
			continue;
		}
		for (Ast *decl : global_decl_source_taken_stmts(src)) {
			if (decl->kind == Ast_ValueDecl) {
				for (Ast *name : decl->ValueDecl.names) {
					if (name->kind == Ast_Ident) {
						check_vet_when_shadowing_entity(name->Ident.entity.load());
					}
				}
			} else if (decl->kind == Ast_ForeignImportDecl) {
				Token token = decl->ForeignImportDecl.library_name;
				InternedString name = string_interner_insert(token.string);
				for (Scope *s = src->file->scope; s != nullptr && s != builtin_pkg->scope; s = s->parent) {
					Entity *e = scope_map_get(&s->elements, name, name.hash());
					if (e != nullptr && e->kind == Entity_LibraryName && e->LibraryName.decl == decl) {
						check_vet_when_shadowing_entity(e);
						break;
					}
				}
			}
		}
	}
}

// Placeholders for every file, then every source resolved in package, file and source order, which
// only matters for which errors are reported
gb_internal void resolve_global_decl_sources(Checker *c, Array<ImportGraphNode *> const &package_order) {
	array_init(&global_decl_sources,       heap_allocator());
	array_init(&global_decl_source_stack,  heap_allocator());
	array_init(&global_placeholder_scopes, heap_allocator());
	init_checker_context(&global_decl_source_export_ctx, c);
	defer (destroy_checker_context(&global_decl_source_export_ctx));

	u64 stage_start = global_import_stage_begin();
	for (ImportGraphNode *node : package_order) {
		for (AstFile *f : node->pkg->files) {
			scan_global_decl_sources(f, f->decls, nullptr, false, EntityVisiblity_Public);
		}
	}
	global_import_stage_end(GlobalImportStage_Placeholders, stage_start);

	stage_start = global_import_stage_begin();
	for (GlobalDeclSource *src : global_decl_sources) {
		resolve_global_decl_source(src, {});
	}
	GB_ASSERT(global_decl_source_stack.count == 0);

	for (Scope *s : global_placeholder_scopes) {
		map_destroy(s->placeholders);
		s->placeholders = nullptr;
	}
	array_clear(&global_placeholder_scopes);

	check_vet_when_shadowing();
	global_import_stage_end(GlobalImportStage_DeclSources, stage_start);

	map_destroy(&global_decl_source_export_untyped);
}


// Global entities are checked in groups: the strongly connected components of a dependency graph built
// from syntax, in dependency order. A group only names entities of its own or of finished groups, which
// `-internal-check-global-edges` verifies

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

gb_internal void global_graph_print_entity(Entity *e) {
	if (e == nullptr) {
		gb_printf_err("?");
		return;
	}
	String pkg  = e->pkg  ? e->pkg->name : str_lit("?");
	String file = e->file ? filename_without_directory(e->file->fullpath) : str_lit("?");
	gb_printf_err("%.*s.%.*s (%.*s:%d)", LIT(pkg), LIT(e->token.string), LIT(file), e->token.pos.line);
}




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
	i32             lo;
	i32             hi;
	Array<i32>      targets;
	Array<i32>      target_ends; // per node
	Array<Entity *> refs;
	Array<i32>      ref_ends;    // per node
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
		global_graph_print_entity(by);
		gb_printf_err(" needs ");
		global_graph_print_entity(e);
		gb_printf_err(v == nullptr ? ", which is not in the graph" : "");
		if (g->current_entity != by) {
			gb_printf_err(", while checking ");
			global_graph_print_entity(g->current_entity);
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


// -internal-global-entity-graph: the groups, weighted by the measured self time of their entities

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

gb_internal f64 global_graph_ms(u64 ticks, u64 freq) {
	return 1000.0 * cast(f64)ticks / cast(f64)freq;
}

gb_internal void print_global_group(GlobalGroupGraph *g, i32 gi, u64 ticks, u64 freq, isize max_names) {
	GlobalGroup const &group = g->groups[gi];
	gb_printf_err("    %10.3f ms %7d entities  ", global_graph_ms(ticks, freq), group.count);
	for (i32 k = 0; k < group.count && k < max_names; k++) {
		if (k > 0) {
			gb_printf_err(", ");
		}
		global_graph_print_entity(g->nodes[g->members[group.start + k]]);
	}
	if (group.count > max_names) {
		gb_printf_err(", ...");
	}
	gb_printf_err("\n");
}

gb_internal void print_global_groups(GlobalGroupGraph *g) {
	u64 const freq = time_stamp__freq();
	i32 group_count = cast(i32)g->groups.count;

	auto ticks = array_make<u64>(heap_allocator(), group_count);
	auto path  = array_make<u64>(heap_allocator(), group_count); // heaviest chain of dependencies ending at a group
	auto len   = array_make<i32>(heap_allocator(), group_count);
	auto prev  = array_make<i32>(heap_allocator(), group_count);
	auto seen  = array_make<i32>(heap_allocator(), group_count);
	defer (array_free(&ticks));
	defer (array_free(&path));
	defer (array_free(&len));
	defer (array_free(&prev));
	defer (array_free(&seen));

	auto pkgs         = array_make<AstPackage *>(heap_allocator(), 0, 64);
	auto pkg_ticks    = array_make<u64>(heap_allocator(), 0, 64);
	auto pkg_entities = array_make<i32>(heap_allocator(), 0, 64);
	PtrMap<AstPackage *, i32> pkg_index = {};
	map_init(&pkg_index);
	defer (array_free(&pkgs));
	defer (array_free(&pkg_ticks));
	defer (array_free(&pkg_entities));
	defer (map_destroy(&pkg_index));

	u64 total_ticks = 0;
	u64 when_ticks = 0;
	isize untimed = 0;
	i32 largest = -1;
	isize cyclic = 0;

	mutex_lock(&global_entity_time_mutex);
	for (auto const &entry : global_entity_times) {
		if (!entry.value.in_global_loop) {
			when_ticks += entry.value.ticks;
		}
	}
	for (i32 gi = 0; gi < group_count; gi++) {
		GlobalGroup const &group = g->groups[gi];
		ticks[gi] = 0;
		for (i32 k = 0; k < group.count; k++) {
			Entity *e = g->nodes[g->members[group.start + k]];
			GlobalEntityTime *t = map_get(&global_entity_times, e);
			untimed += t == nullptr;
			u64 et = t ? t->ticks : 0;
			ticks[gi] += et;

			i32 *p = map_get(&pkg_index, e->pkg);
			if (p == nullptr) {
				map_set(&pkg_index, e->pkg, cast(i32)pkgs.count);
				array_add(&pkgs, e->pkg);
				array_add(&pkg_ticks, et);
				array_add(&pkg_entities, 1);
			} else {
				pkg_ticks[*p] += et;
				pkg_entities[*p] += 1;
			}
		}
		total_ticks += ticks[gi];
		if (largest < 0 || group.count > g->groups[largest].count) {
			largest = gi;
		}
		cyclic += group.count > 1;
	}
	mutex_unlock(&global_entity_time_mutex);

	// NOTE: every dependency of a group has a lower index
	i32 critical = -1;
	for (i32 gi = 0; gi < group_count; gi++) {
		seen[gi] = -1;
	}
	for (i32 gi = 0; gi < group_count; gi++) {
		GlobalGroup const &group = g->groups[gi];
		prev[gi] = -1;
		for (i32 k = 0; k < group.count; k++) {
			i32 v = g->members[group.start + k];
			for (i32 i = g->offsets[v]; i < g->offsets[v+1]; i++) {
				i32 dep = g->group_of[g->targets[i]];
				if (dep != gi && seen[dep] != gi) {
					seen[dep] = gi;
					if (prev[gi] < 0 || path[dep] > path[prev[gi]]) {
						prev[gi] = dep;
					}
				}
			}
		}
		path[gi] = ticks[gi] + (prev[gi] >= 0 ? path[prev[gi]] : 0);
		len[gi]  = 1 + (prev[gi] >= 0 ? len[prev[gi]] : 0);
		if (critical < 0 || path[gi] > path[critical]) {
			critical = gi;
		}
	}

	f64 total_ms = global_graph_ms(total_ticks, freq);
	f64 critical_ms = critical >= 0 ? global_graph_ms(path[critical], freq) : 0;

	gb_printf_err("Global entity groups\n");
	gb_printf_err("  entities: %td (%td not timed), dependency edges: %td, missing edges: %td\n", g->nodes.count, untimed, g->targets.count, g->missing_edges);
	gb_printf_err("  self time: %.3f ms in the groups, %.3f ms during 'when' resolution\n", total_ms, global_graph_ms(when_ticks, freq));
	gb_printf_err("  groups:    %d (%td with a cycle), largest has %d entities\n", group_count, cyclic, largest >= 0 ? g->groups[largest].count : 0);
	gb_printf_err("  critical path: %.3f ms over %d groups -> at most %.2fx speedup\n",
	              critical_ms, critical >= 0 ? len[critical] : 0, critical_ms > 0 ? total_ms/critical_ms : 0.0);

	gb_printf_err("  check_import_entities (sequential, includes entity checks it triggers):\n");
	for (isize i = 0; i < GlobalImportStage_COUNT; i++) {
		gb_printf_err("    %10.3f ms  %s\n", global_graph_ms(global_import_stage_ticks[i], freq), global_import_stage_names[i]);
	}

	{
		i32 const BUCKET_COUNT = 10;
		i32 const   bucket_max     [BUCKET_COUNT] = {1, 2, 4, 8, 16, 64, 256, 1024, 4096, 0x7fffffff};
		char const *bucket_name    [BUCKET_COUNT] = {"1", "2", "3-4", "5-8", "9-16", "17-64", "65-256", "257-1024", "1025-4096", ">4096"};
		isize       bucket_groups  [BUCKET_COUNT] = {};
		isize       bucket_entities[BUCKET_COUNT] = {};
		u64         bucket_ticks   [BUCKET_COUNT] = {};
		for (i32 gi = 0; gi < group_count; gi++) {
			i32 count = g->groups[gi].count;
			for (i32 b = 0; b < BUCKET_COUNT; b++) {
				if (count <= bucket_max[b]) {
					bucket_groups[b] += 1;
					bucket_entities[b] += count;
					bucket_ticks[b] += ticks[gi];
					break;
				}
			}
		}
		gb_printf_err("  group sizes:\n");
		gb_printf_err("    %10s %9s %10s %12s\n", "size", "groups", "entities", "self time");
		for (i32 b = 0; b < BUCKET_COUNT; b++) {
			if (bucket_groups[b] != 0) {
				gb_printf_err("    %10s %9td %10td %9.3f ms\n", bucket_name[b], bucket_groups[b], bucket_entities[b], global_graph_ms(bucket_ticks[b], freq));
			}
		}
	}

	auto items = array_make<GlobalGraphSortItem>(heap_allocator(), 0, gb_max(group_count, cast(i32)pkgs.count));
	defer (array_free(&items));
	isize const TOP = 10;

	for (i32 gi = 0; gi < group_count; gi++) {
		array_add(&items, GlobalGraphSortItem{ticks[gi], gi});
	}
	array_sort(items, global_graph_sort_item_desc);
	gb_printf_err("  slowest groups:\n");
	for (isize i = 0; i < items.count && i < TOP; i++) {
		print_global_group(g, items[i].id, items[i].key, freq, 4);
	}

	array_clear(&items);
	for (i32 gi = 0; gi < group_count; gi++) {
		if (g->groups[gi].count > 1) {
			array_add(&items, GlobalGraphSortItem{cast(u64)g->groups[gi].count, gi});
		}
	}
	array_sort(items, global_graph_sort_item_desc);
	gb_printf_err("  largest groups:\n");
	for (isize i = 0; i < items.count && i < TOP; i++) {
		print_global_group(g, items[i].id, ticks[items[i].id], freq, 4);
	}

	gb_printf_err("  critical path, last group first:\n");
	isize printed = 0;
	for (i32 gi = critical; gi >= 0; gi = prev[gi]) {
		if (printed == 30) {
			gb_printf_err("    ... %d more groups\n", len[gi]);
			break;
		}
		print_global_group(g, gi, ticks[gi], freq, 2);
		printed += 1;
	}

	array_clear(&items);
	for (i32 p = 0; p < pkgs.count; p++) {
		array_add(&items, GlobalGraphSortItem{pkg_ticks[p], p});
	}
	array_sort(items, global_graph_sort_item_desc);
	gb_printf_err("  slowest packages:\n");
	for (isize i = 0; i < items.count && i < TOP; i++) {
		i32 p = items[i].id;
		String name = pkgs[p] ? pkgs[p]->name : str_lit("?");
		gb_printf_err("    %10.3f ms %7d entities  %.*s\n", global_graph_ms(pkg_ticks[p], freq), pkg_entities[p], LIT(name));
	}
}
