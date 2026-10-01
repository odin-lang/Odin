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

struct GlobalDeclSourceName {
	InternedString name;
	Scope *        scope;
	Ast *          decl;    // ValueDecl or ForeignImportDecl
	bool           in_else; // within the else branch of a 'when'
};

struct GlobalWhenCycle;

struct GlobalDeclSource {
	Ast *             node; // WhenStmt or ForeignBlockDecl
	AstFile *         file;
	GlobalDeclSource *parent;
	bool              in_else;
	bool              reachable;
	bool              reported_cycle;
	EntityState       state;
	ForeignContext    foreign_context;

	Array<GlobalDeclSourceName> names;
	GlobalWhenCycle * cycle;
	i32               cycle_index;
	bool              predetermined;
	bool              predetermined_cond;
};

// A possible cycle between global 'when's, found from syntax; the branches are chosen by trying every
// combination, see `search_global_when_cycle`
struct GlobalWhenCycle {
	Array<GlobalDeclSource *> sources; // in source order
	PtrSet<Ast *>             decls;   // declarations in the cycle, whose checking depends on the choice
	bool                      searched;
};

// One condition evaluated for one choice of branches: lookups see the declarations of the chosen
// branches, and scratch copies of the declarations in `cycle->decls`
struct GlobalWhenTrial {
	GlobalWhenCycle *               cycle;
	u32                             mask;      // bit i: `cycle->sources[i]` takes its first branch
	u32                             reachable;
	u32                             used;      // sources whose chosen branch a lookup found
	isize                           real_depth; // within the check of an entity outside the trial
	bool                            unsupported;
	bool                            broken;    // that entity reached the cycle, which the graph missed
	PtrMap<Ast *, Array<Entity *> *> decl_entities;
	PtrSet<Entity *>                scratch;
};

gb_global isize global_when_cycle_count;
gb_global isize global_when_cycle_sources;
gb_global isize global_when_trial_count;

gb_internal void find_global_when_cycles(void);
gb_internal void search_global_when_cycle(GlobalWhenCycle *cycle);

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

gb_internal void add_placeholders(AstFile *f, u8 scopes, InternedString name, GlobalDeclSource *src, Ast *decl, bool in_else) {
	if (name.value == 0 || name.is_blank()) {
		return;
	}
	if (src->names.allocator.proc == nullptr) {
		array_init(&src->names, heap_allocator());
	}
	if (scopes & PlaceholderScope_File) {
		add_placeholder(f->scope, name, src);
		array_add(&src->names, GlobalDeclSourceName{name, f->scope, decl, in_else});
	}
	if (scopes & PlaceholderScope_Pkg) {
		add_placeholder(f->pkg->scope, name, src);
		array_add(&src->names, GlobalDeclSourceName{name, f->pkg->scope, decl, in_else});
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
					add_placeholders(f, scopes, name->Ident.interned, owner, decl, in_else);
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
				add_placeholders(f, scopes, string_interner_insert(library_name), owner, decl, in_else);
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

gb_internal void resolve_global_decl_source(GlobalDeclSource *src, InternedString needed);

gb_internal void resolve_global_decl_source_internal(GlobalDeclSource *src, InternedString needed) {
	if (src->state == EntityState_InProgress) {
		report_global_decl_source_cycle(src, needed);
		return;
	}
	if (src->cycle != nullptr && !src->cycle->searched) {
		search_global_when_cycle(src->cycle);
		if (src->state == EntityState_Resolved) {
			return;
		}
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
		if (src->predetermined) {
			ws->is_cond_determined = true;
			ws->determined_cond = src->predetermined_cond;
		} else {
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
		}
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

	// NOTE(bill): resolved before its declarations are collected, which evaluates the attributes of 'foreign import's
	src->state = EntityState_Resolved;
	array_pop(&global_decl_source_stack);

	collect_global_decl_source_stmts(&ctx, global_decl_source_taken_stmts(src));

	add_untyped_expressions(ctx.info, &untyped);
	map_destroy(&untyped);
	destroy_checker_context(&ctx);
}

gb_internal void resolve_global_decl_source(GlobalDeclSource *src, InternedString needed) {
	if (src->state == EntityState_Resolved) {
		return;
	}
	GlobalWhenTrial *trial = global_when_trial;
	i32 mute_depth = global_error_mute_depth;
	global_when_trial = nullptr;
	global_error_mute_depth = 0;
	resolve_global_decl_source_internal(src, needed);
	global_when_trial = trial;
	global_error_mute_depth = mute_depth;
}

gb_internal Entity *force_scope_placeholders(Scope *s, InternedString name, u32 hash) {
	PtrMap<u64, GlobalDeclSource *> *m = s->placeholders;
	bool forced = false;
	for (auto *e = multi_map_find_first(m, cast(u64)name.value); e != nullptr; e = multi_map_find_next(m, e)) {
		GlobalDeclSource *src = e->value;
		if (global_when_trial != nullptr && src->cycle == global_when_trial->cycle) {
			// NOTE: the trial's lookup decides what these declare
			continue;
		}
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
	find_global_when_cycles();
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

gb_internal void global_graph_csr(i32 node_count, Array<i32> const &edge_from, Array<i32> const &edge_to, Array<i32> *offsets, Array<i32> *targets) {
	array_init(offsets, heap_allocator(), node_count+1);
	array_init(targets, heap_allocator(), edge_to.count);
	for (i32 v = 0; v <= node_count; v++) {
		(*offsets)[v] = 0;
	}
	for (i32 from : edge_from) {
		(*offsets)[from+1] += 1;
	}
	for (i32 v = 0; v < node_count; v++) {
		(*offsets)[v+1] += (*offsets)[v];
	}
	auto fill = array_clone(heap_allocator(), *offsets);
	defer (array_free(&fill));
	for (isize i = 0; i < edge_from.count; i++) {
		(*targets)[fill[edge_from[i]]++] = edge_to[i];
	}
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

struct GlobalPlaceholderHit {
	Scope *        scope;
	InternedString name;
};

struct GlobalGraphWalk {
	Scope *scope;
	Array<Entity *> *refs;
	Array<GlobalPlaceholderHit> *hits; // set: before any 'when' is resolved, a lookup passing a placeholder records it
};

gb_internal Entity *global_graph_lookup(GlobalGraphWalk *w, Scope *s, Ast *ident, bool parents) {
	InternedString name = ident->Ident.interned;
	u32 hash = ident->Ident.hash;
	if (w->hits == nullptr) {
		return parents ? scope_lookup(s, name, hash) : scope_lookup_current(s, name, hash);
	}
	for (; s != nullptr; s = s->parent) {
		Entity *e = scope_map_get(&s->elements, name, hash);
		if (e != nullptr) {
			return e;
		}
		if (s->placeholders != nullptr && multi_map_find_first(s->placeholders, cast(u64)name.value) != nullptr) {
			array_add(w->hits, GlobalPlaceholderHit{s, name});
		}
		if (!parents) {
			break;
		}
	}
	return nullptr;
}

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
		global_graph_add_ref(w, global_graph_lookup(w, w->scope, node, true));
		break;

	case Ast_SelectorExpr: {
		Ast *expr     = node->SelectorExpr.expr;
		Ast *selector = node->SelectorExpr.selector;
		if (expr != nullptr && expr->kind == Ast_Ident) {
			Entity *e = global_graph_lookup(w, w->scope, expr, true);
			if (e != nullptr && e->kind == Entity_ImportName && selector != nullptr && selector->kind == Ast_Ident) {
				global_graph_add_ref(w, global_graph_lookup(w, e->ImportName.scope, selector, false));
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

gb_internal void global_graph_walk_attribute_values(GlobalGraphWalk *w, Array<Ast *> const &attributes) {
	for (Ast *attr : attributes) {
		if (attr->kind != Ast_Attribute) {
			continue;
		}
		for (Ast *elem : attr->Attribute.elems) {
			if (elem->kind == Ast_FieldValue) {
				global_graph_walk(w, elem->FieldValue.value);
			}
		}
	}
}

gb_internal void global_graph_walk_entity(GlobalGraphWalk *w, Entity *e, DeclInfo *d) {
	w->scope = d->scope;
	global_graph_walk(w, d->type_expr);
	global_graph_walk(w, d->init_expr);
	global_graph_walk_attribute_values(w, d->attributes);
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
	global_graph_csr(node_count, edge_from, edge_to, &g->offsets, &g->targets);

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


// NOTE(bill, 2026-10-01)
//
// Cycles of global 'when's: a 'when' whose condition may need what its own branch declares,
// directly or through other 'when's. Found from syntax before anything is resolved: the nodes
// are the 'when's and 'foreign' blocks, the declarations in their branches, and the global
// entities their conditions reach.
//
// Each cycle is decided by trying every choice of its branches; exactly one choice must be consistent

enum GlobalWhenNodeKind : u8 {
	GlobalWhenNode_Source,
	GlobalWhenNode_Decl,
	GlobalWhenNode_Entity,
};

struct GlobalWhenNode {
	GlobalWhenNodeKind kind;
	GlobalDeclSource * source; // of a source or a declaration
	Ast *              decl;
	Entity *           entity;
};

gb_internal void find_global_when_cycles(void) {
	auto nodes     = array_make<GlobalWhenNode>      (heap_allocator(), 0, global_decl_sources.count);
	auto edge_from = array_make<i32>                 (heap_allocator(), 0, global_decl_sources.count);
	auto edge_to   = array_make<i32>                 (heap_allocator(), 0, global_decl_sources.count);
	auto refs      = array_make<Entity *>            (heap_allocator(), 0, 64);
	auto hits      = array_make<GlobalPlaceholderHit>(heap_allocator(), 0, 16);
	defer (array_free(&nodes));
	defer (array_free(&edge_from));
	defer (array_free(&edge_to));
	defer (array_free(&refs));
	defer (array_free(&hits));

	PtrMap<void *, i32> node_of = {};
	map_init(&node_of, 2*global_decl_sources.count);
	defer (map_destroy(&node_of));

	auto add_node = [&](void *key, GlobalWhenNode const &node) -> i32 {
		i32 *found = map_get(&node_of, key);
		if (found != nullptr) {
			return *found;
		}
		i32 v = cast(i32)nodes.count;
		map_set(&node_of, key, v);
		array_add(&nodes, node);
		return v;
	};
	auto add_edge = [&](i32 from, i32 to) {
		array_add(&edge_from, from);
		array_add(&edge_to, to);
	};

	for (GlobalDeclSource *src : global_decl_sources) {
		add_node(src, GlobalWhenNode{GlobalWhenNode_Source, src});
	}

	GlobalGraphWalk w = {};
	w.refs = &refs;
	w.hits = &hits;
	for (i32 v = 0; v < nodes.count; v++) {
		GlobalWhenNode node = nodes[v];
		array_clear(&refs);
		array_clear(&hits);
		switch (node.kind) {
		case GlobalWhenNode_Source:
			w.scope = node.source->file->scope;
			if (node.source->node->kind == Ast_WhenStmt) {
				global_graph_walk(&w, node.source->node->WhenStmt.cond);
			} else {
				global_graph_walk_attribute_values(&w, node.source->node->ForeignBlockDecl.attributes);
			}
			if (node.source->parent != nullptr) {
				add_edge(v, *map_get(&node_of, cast(void *)node.source->parent));
			}
			break;
		case GlobalWhenNode_Decl:
			w.scope = node.source->file->scope;
			if (node.decl->kind == Ast_ValueDecl) {
				global_graph_walk(&w, node.decl->ValueDecl.type);
				global_graph_walk_slice(&w, node.decl->ValueDecl.values);
				global_graph_walk_attribute_values(&w, node.decl->ValueDecl.attributes);
			} else if (node.decl->kind == Ast_ForeignImportDecl) {
				global_graph_walk_attribute_values(&w, node.decl->ForeignImportDecl.attributes);
			}
			add_edge(v, *map_get(&node_of, cast(void *)node.source));
			break;
		case GlobalWhenNode_Entity:
			global_graph_walk_entity(&w, node.entity, node.entity->decl_info);
			break;
		}

		for (Entity *e : refs) {
			if (e->decl_info != nullptr && e->scope != nullptr && (e->scope->flags & ScopeFlag_File) != 0) {
				add_edge(v, add_node(e, GlobalWhenNode{GlobalWhenNode_Entity, nullptr, nullptr, e}));
			}
		}

		// NOTE(bill):: a name that may be declared by a 'when' depends on its declarations there, and on that 'when'
		for (GlobalPlaceholderHit const &hit : hits) {
			PtrMap<u64, GlobalDeclSource *> *m = hit.scope->placeholders;
			for (auto *entry = multi_map_find_first(m, cast(u64)hit.name.value); entry != nullptr; entry = multi_map_find_next(m, entry)) {
				GlobalDeclSource *src = entry->value;
				for (GlobalDeclSourceName const &n : src->names) {
					if (n.name == hit.name && n.scope == hit.scope) {
						add_edge(v, add_node(n.decl, GlobalWhenNode{GlobalWhenNode_Decl, src, n.decl}));
					}
				}
			}
		}
	}

	i32 node_count = cast(i32)nodes.count;
	Array<i32> offsets = {};
	Array<i32> targets = {};
	defer (array_free(&offsets));
	defer (array_free(&targets));

	global_graph_csr(node_count, edge_from, edge_to, &offsets, &targets);
	auto comp_of = array_make<i32>(heap_allocator(), node_count);
	defer (array_free(&comp_of));

	i32 comp_count = global_graph_scc(node_count, offsets, targets, &comp_of);

	auto comp_size  = array_make<i32>              (heap_allocator(), comp_count);
	auto comp_cycle = array_make<GlobalWhenCycle *>(heap_allocator(), comp_count);
	defer (array_free(&comp_size));
	defer (array_free(&comp_cycle));

	for (i32 ci = 0; ci < comp_count; ci++) {
		comp_size[ci] = 0;
		comp_cycle[ci] = nullptr;
	}
	for (i32 v = 0; v < node_count; v++) {
		comp_size[comp_of[v]] += 1;
	}
	auto is_cyclic = [&](i32 v) -> bool {
		if (comp_size[comp_of[v]] > 1) {
			return true;
		}
		for (i32 i = offsets[v]; i < offsets[v+1]; i++) {
			if (targets[i] == v) {
				return true;
			}
		}
		return false;
	};

	// NOTE: sources are the first nodes, in source order
	for (i32 v = 0; v < global_decl_sources.count; v++) {
		if (!is_cyclic(v)) {
			continue;
		}
		GlobalWhenCycle *&cycle = comp_cycle[comp_of[v]];
		if (cycle == nullptr) {
			cycle = permanent_alloc_item<GlobalWhenCycle>();
			array_init(&cycle->sources, heap_allocator());
			ptr_set_init(&cycle->decls);
			global_when_cycle_count += 1;
		}
		GlobalDeclSource *src = nodes[v].source;
		src->cycle = cycle;
		src->cycle_index = cast(i32)cycle->sources.count;
		array_add(&cycle->sources, src);
		global_when_cycle_sources += 1;
	}
	for (i32 v = 0; v < node_count; v++) {
		GlobalWhenCycle *cycle = comp_cycle[comp_of[v]];
		if (cycle == nullptr) {
			continue;
		}
		if (nodes[v].kind == GlobalWhenNode_Decl) {
			ptr_set_add(&cycle->decls, nodes[v].decl);
		} else if (nodes[v].kind == GlobalWhenNode_Entity && nodes[v].entity->decl_info->decl_node != nullptr) {
			ptr_set_add(&cycle->decls, nodes[v].entity->decl_info->decl_node);
		}
	}
}

gb_internal ForeignContext global_decl_source_foreign_context(GlobalDeclSource *src) {
	for (GlobalDeclSource *p = src; p != nullptr; p = p->parent) {
		if (p->node->kind == Ast_ForeignBlockDecl) {
			return p->foreign_context;
		}
	}
	return {};
}

// Scratch entities for a declaration, made as `check_collect_value_decl` would but put nowhere
gb_internal Entity *global_when_trial_entity(GlobalWhenTrial *t, Ast *decl, AstFile *file, ForeignContext const &foreign_context, InternedString name) {
	Array<Entity *> **found = map_get(&t->decl_entities, decl);
	Array<Entity *> *entities = found ? *found : nullptr;
	if (entities == nullptr) {
		entities = gb_alloc_item(heap_allocator(), Array<Entity *>);
		array_init(entities, heap_allocator());
		map_set(&t->decl_entities, decl, entities);
		if (decl->kind != Ast_ValueDecl) {
			t->unsupported = true;
			return nullptr;
		}
		CheckerContext ctx = {};
		init_checker_context(&ctx, global_checker_ptr.load(std::memory_order_relaxed));
		UntypedExprInfoMap untyped = {};
		reset_checker_context(&ctx, file, &untyped);
		ctx.decl = make_decl_info(file->scope, nullptr); // not a child of the package's
		ctx.foreign_context = foreign_context;
		ctx.trial_entities = entities;
		Ast *clone = clone_ast(decl);
		clone->state_flags &= ~StateFlag_BeenHandled;
		check_collect_value_decl(&ctx, clone);
		map_destroy(&untyped);
		destroy_checker_context(&ctx);
		for (Entity *e : *entities) {
			ptr_set_add(&t->scratch, e);
		}
	}
	for (Entity *e : *entities) {
		if (entity_interned_name(e) == name) {
			return e;
		}
	}
	t->unsupported = true;
	return nullptr;
}

// Every scope lookup during a trial: `found` is what the scope itself holds
gb_internal Entity *global_when_trial_lookup(Scope *s, InternedString name, u32 hash, Entity *found) {
	GlobalWhenTrial *t = global_when_trial;
	GlobalWhenCycle *cycle = t->cycle;
	if (found != nullptr) {
		DeclInfo *d = found->decl_info;
		if (d == nullptr || d->decl_node == nullptr || !ptr_set_exists(&cycle->decls, d->decl_node) || ptr_set_exists(&t->scratch, found)) {
			return found;
		}
		if (t->real_depth > 0) {
			t->broken = true;
			return found;
		}
		if ((found->kind == Entity_Procedure && found->Procedure.is_foreign) ||
		    (found->kind == Entity_Variable  && found->Variable.is_foreign)) {
			t->unsupported = true;
			return found;
		}
		Entity *copy = global_when_trial_entity(t, d->decl_node, found->file, {}, name);
		return copy != nullptr ? copy : found;
	}
	if (s->placeholders == nullptr) {
		return nullptr;
	}
	PtrMap<u64, GlobalDeclSource *> *m = s->placeholders;
	for (auto *entry = multi_map_find_first(m, cast(u64)name.value);
	     entry != nullptr;
	     entry = multi_map_find_next(m, entry)) {
		GlobalDeclSource *src = entry->value;
		if (src->cycle != cycle) {
			continue;
		}
		if (t->real_depth > 0) {
			t->broken = true;
			return nullptr;
		}
		u32 bit = 1u << src->cycle_index;
		if ((t->reachable & bit) == 0) {
			continue;
		}
		bool in_else = (t->mask & bit) == 0;
		for (GlobalDeclSourceName const &n : src->names) {
			if (n.name == name && n.scope == s && n.in_else == in_else) {
				// NOTE(bill): the branches around it are needed too
				for (GlobalDeclSource *p = src; p != nullptr && p->cycle == cycle; p = p->parent) {
					t->used |= 1u << p->cycle_index;
				}
				return global_when_trial_entity(t, n.decl, src->file, global_decl_source_foreign_context(src), name);
			}
		}
	}
	return nullptr;
}

// An entity outside the trial is checked for real, with errors shown; a scratch procedure is not checked,
// as its body would be queued
gb_internal bool global_when_trial_begin_entity(Entity *e, GlobalWhenTrialEntityScope *scope) {
	GlobalWhenTrial *t = global_when_trial;
	*scope = {};
	if (ptr_set_exists(&t->scratch, e)) {
		if (e->kind == Entity_Procedure || e->kind == Entity_AsmTemplate) {
			t->unsupported = true;
			e->type = t_invalid;
			e->state = EntityState_Resolved;
			return false;
		}
		return true;
	}
	scope->trial = t;
	scope->mute_depth = global_error_mute_depth;
	global_error_mute_depth = 0;
	t->real_depth += 1;
	return true;
}

gb_internal void global_when_trial_end_entity(GlobalWhenTrialEntityScope *scope) {
	if (scope->trial != nullptr) {
		scope->trial->real_depth -= 1;
		global_error_mute_depth = scope->mute_depth;
	}
}

enum GlobalWhenFailureKind : u8 {
	GlobalWhenFailure_None,
	GlobalWhenFailure_Invalid,   // Cannot be evaluated
	GlobalWhenFailure_Disagrees, // Picks the other branch
	GlobalWhenFailure_OwnBranch, // A chosen branch is needed to decide its own condition
};

struct GlobalWhenTrialResult {
	GlobalWhenFailureKind failure;
	i32  source;
	bool value;
	bool unsupported;
	bool broken;
};

gb_internal GlobalWhenTrialResult try_global_when_choice(GlobalWhenCycle *cycle, u32 mask, u32 reachable) {
	GlobalWhenTrialResult res = {};
	i32 k = cast(i32)cycle->sources.count;
	u32 used[32] = {};

	for (i32 i = 0; i < k; i++) {
		if ((reachable & (1u<<i)) == 0) {
			continue;
		}
		GlobalDeclSource *src = cycle->sources[i];
		ast_node(ws, WhenStmt, src->node);

		GlobalWhenTrial t = {};
		t.cycle     = cycle;
		t.mask      = mask;
		t.reachable = reachable;

		map_init(&t.decl_entities);
		defer ({
			for (auto const &entry : t.decl_entities) {
				array_free(entry.value);
				gb_free(heap_allocator(), entry.value);
			}
			map_destroy(&t.decl_entities);
		});

		ptr_set_init(&t.scratch);
		defer (ptr_set_destroy(&t.scratch));

		CheckerContext ctx = {};
		init_checker_context(&ctx, global_checker_ptr.load(std::memory_order_relaxed));
		defer (destroy_checker_context(&ctx));

		UntypedExprInfoMap untyped = {};
		defer (map_destroy(&untyped));


		reset_checker_context(&ctx, src->file, &untyped);
		// so no dependency is recorded
		ctx.decl = make_decl_info(src->file->scope, nullptr);
		ctx.foreign_context = global_decl_source_foreign_context(src);

		GlobalWhenTrial *prev = global_when_trial;
		global_when_trial = &t;

		Ast *cond = clone_ast(ws->cond);
		i64 muted = error_mute_count();
		begin_error_mute();

		Operand o = {};
		check_expr(&ctx, &o, cond);
		end_error_mute();
		global_when_trial = prev;
		global_when_trial_count += 1;

		bool ok = error_mute_count() == muted && o.mode == Addressing_Constant && o.value.kind == ExactValue_Bool;
		used[i] = t.used;
		res.unsupported = t.unsupported;
		res.broken = t.broken;

		if (res.unsupported || res.broken) {
			return res;
		}
		if (!ok || o.value.value_bool != ((mask & (1u<<i)) != 0)) {
			res.failure = ok ? GlobalWhenFailure_Disagrees : GlobalWhenFailure_Invalid;
			res.source = i;
			res.value = ok && o.value.value_bool;
			return res;
		}
	}

	// NOTE: the chosen branches must be decidable in some order, each from earlier ones
	u32 decided = 0;
	for (;;) {
		bool progress = false;
		for (i32 i = 0; i < k; i++) {
			u32 bit = 1u << i;
			if ((reachable & bit) && (decided & bit) == 0 && (used[i] & ~decided) == 0) {
				decided |= bit;
				progress = true;
			}
		}
		if (!progress) {
			break;
		}
	}
	if (decided != reachable) {
		res.failure = GlobalWhenFailure_OwnBranch;
	}
	return res;
}

gb_internal u32 global_when_cycle_reachable(GlobalWhenCycle *cycle, u32 mask, u32 unreachable) {
	u32 reachable = 0;
	for (i32 i = 0; i < cycle->sources.count; i++) {
		GlobalDeclSource *src = cycle->sources[i];
		GlobalDeclSource *p = src->parent;
		bool r = (unreachable & (1u<<i)) == 0;
		// NOTE(bill): a parent outside the cycle has no parent in it and its parents come first in source order
		if (r && p != nullptr && p->cycle == cycle) {
			u32 pb = 1u << p->cycle_index;
			r = (reachable & pb) != 0;
			if (p->node->kind == Ast_WhenStmt) {
				r = r && ((mask & pb) != 0) != src->in_else;
			}
		}
		if (r) {
			reachable |= 1u << i;
		}
	}
	return reachable;
}

gb_internal gbString global_when_choice_string(gbString s, GlobalWhenCycle *cycle, u32 mask, u32 reachable) {
	for (i32 i = 0; i < cycle->sources.count; i++) {
		u32 bit = 1u << i;
		s = gb_string_append_fmt(s, "%s%s", i > 0 ? ", " : "", (reachable & bit) == 0 ? "unreachable" : (mask & bit) ? "taken" : "not taken");
	}
	return s;
}

gb_internal void error_line_global_when_sources(GlobalWhenCycle *cycle) {
	for (GlobalDeclSource *src : cycle->sources) {
		gbString cond = expr_to_string(src->node->WhenStmt.cond);
		error_line("\t'when' at %s: %s\n", token_pos_to_string(src->node->WhenStmt.token.pos), cond);
		gb_string_free(cond);
	}
}

gb_internal void commit_global_when_cycle(GlobalWhenCycle *cycle, u32 mask, bool check_conditions) {
	for (GlobalDeclSource *src : cycle->sources) {
		src->predetermined = true;
		src->predetermined_cond = (mask & (1u << src->cycle_index)) != 0;
	}
	for (GlobalDeclSource *src : cycle->sources) {
		resolve_global_decl_source(src, {});
	}
	if (!check_conditions) {
		return;
	}
	// NOTE: for real, now that every chosen branch is collected, which must give the same values
	for (GlobalDeclSource *src : cycle->sources) {
		if (!src->reachable) {
			continue;
		}
		ast_node(ws, WhenStmt, src->node);

		CheckerContext ctx = {};
		init_checker_context(&ctx, global_checker_ptr.load(std::memory_order_relaxed));
		defer (destroy_checker_context(&ctx));

		UntypedExprInfoMap untyped = {};
		reset_checker_context(&ctx, src->file, &untyped);
		defer (map_destroy(&untyped));

		ctx.foreign_context = global_decl_source_foreign_context(src);

		Operand o = {};
		check_expr(&ctx, &o, ws->cond);
		if (o.mode != Addressing_Constant || o.value.kind != ExactValue_Bool || o.value.value_bool != ws->determined_cond) {
			error(ws->token, "Internal compiler error: this global 'when' changed its branch after its cycle was decided");
		}
		add_untyped_expressions(ctx.info, &untyped);
	}
}

gb_internal void search_global_when_cycle(GlobalWhenCycle *cycle) {
	cycle->searched = true;
	i32 k = cast(i32)cycle->sources.count;
	for (GlobalDeclSource *src : cycle->sources) {
		if (src->node->kind != Ast_WhenStmt) {
			// NOTE(bill): resolved on demand where a cycle is reported as such
			return;
		}
	}
	Token token = cycle->sources[0]->node->WhenStmt.token;

	i32 const MAX_SOURCES = 8; // 2^8 == 256 combinations
	if (k > MAX_SOURCES) {
		ERROR_BLOCK();
		error(token, "Too many combinations of global 'when' branches: %d 'when's depend on each other, which gives 2^%d combinations, more than %d",
		      k, k, 1 << MAX_SOURCES);
		error_line_global_when_sources(cycle);
		return;
	}

	// The parents outside the cycle are decided for real first
	u32 unreachable = 0;
	for (GlobalDeclSource *src : cycle->sources) {
		GlobalDeclSource *p = src->parent;
		if (p == nullptr || p->cycle == cycle) {
			continue;
		}
		resolve_global_decl_source(p, {});
		bool r = p->state == EntityState_Resolved && p->reachable;
		if (p->node->kind == Ast_WhenStmt) {
			r = r && p->node->WhenStmt.determined_cond != src->in_else;
		}
		if (!r) {
			unreachable |= 1u << src->cycle_index;
		}
	}

	auto consistent = array_make<u32>(heap_allocator());
	auto failures   = array_make<GlobalWhenTrialResult>(heap_allocator());
	auto failed     = array_make<u32>(heap_allocator());
	defer (array_free(&consistent));
	defer (array_free(&failures));
	defer (array_free(&failed));

	for (u32 mask = 0; mask < (1u << k); mask++) {
		u32 reachable = global_when_cycle_reachable(cycle, mask, unreachable);
		if (mask & ~reachable) {
			// An unreachable 'when' is only counted as not taken
			continue;
		}
		GlobalWhenTrialResult result = try_global_when_choice(cycle, mask, reachable);
		if (result.broken) {
			error(token, "Internal compiler error: deciding this cycle of global 'when's checked a declaration that depends on it");
			return;
		}
		if (result.unsupported) {
			// Needs a procedure or library declared in the cycle, so it is resolved on demand instead
			return;
		}
		if (result.failure == GlobalWhenFailure_None) {
			array_add(&consistent, mask);
		} else {
			array_add(&failures, result);
			array_add(&failed, mask);
		}
	}

	if (consistent.count == 1) {
		commit_global_when_cycle(cycle, consistent[0], true);
		return;
	}

	ERROR_BLOCK();
	if (consistent.count == 0) {
		error(token, "Contradictory global 'when' conditions: no choice of their branches is consistent");
		error_line_global_when_sources(cycle);
		for (isize i = 0; i < failed.count && i < 16; i++) {
			GlobalWhenTrialResult const &r = failures[i];

			u32 reachable = global_when_cycle_reachable(cycle, failed[i], unreachable);

			gbString s = global_when_choice_string(gb_string_make(heap_allocator(), ""), cycle, failed[i], reachable);
			defer (gb_string_free(s));

			TokenPos pos = cycle->sources[r.source]->node->WhenStmt.token.pos;
			switch (r.failure) {
			case GlobalWhenFailure_Invalid:
				error_line("\t[%s]: the 'when' at %s cannot be evaluated\n", s, token_pos_to_string(pos));
				break;
			case GlobalWhenFailure_Disagrees:
				error_line("\t[%s]: the 'when' at %s evaluates to %s\n", s, token_pos_to_string(pos), r.value ? "true" : "false");
				break;
			case GlobalWhenFailure_OwnBranch:
				error_line("\t[%s]: a taken branch is needed to decide its own condition\n", s);
				break;
			}
		}
		commit_global_when_cycle(cycle, 0, false);
	} else {
		error(token, "Ambiguous global 'when' conditions: %td choices of their branches are consistent", consistent.count);
		error_line_global_when_sources(cycle);
		for (isize i = 0; i < consistent.count; i++) {
			u32 reachable = global_when_cycle_reachable(cycle, consistent[i], unreachable);
			gbString s = global_when_choice_string(gb_string_make(heap_allocator(), ""), cycle, consistent[i], reachable);
			defer (gb_string_free(s));

			error_line("\tchoice %td: %s\n", i+1, s);
		}
		commit_global_when_cycle(cycle, consistent[0], false);
	}
}


// `-internal-global-entity-graph`
// The groups weighted by the measured self time of their entities

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

	u64   total_ticks = 0;
	u64   when_ticks  = 0;
	isize untimed     = 0;
	i32   largest     = -1;
	isize cyclic      = 0;

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

	// NOTE(bill): every dependency of a group has a lower index
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

	gb_printf_err("  'when' cycles: %td (%td 'when's), %td conditions tried\n", global_when_cycle_count, global_when_cycle_sources, global_when_trial_count);
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
