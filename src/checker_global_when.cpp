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
