bool check_is_terminating(AstNode *node);
void check_stmt          (Checker *c, AstNode *node, u32 flags);
void check_stmt_list     (Checker *c, AstNodeArray stmts, u32 flags);

// NOTE(bill): `content_name` is for debugging and error messages
Type *check_init_variable(Checker *c, Entity *e, Operand *operand, String context_name) {
	if (operand->mode == Addressing_Invalid ||
	    operand->type == t_invalid ||
	    e->type == t_invalid) {

		if (operand->mode == Addressing_Builtin) {
			gbString expr_str = expr_to_string(operand->expr);

			// TODO(bill): is this a good enough error message?
			error_node(operand->expr,
			      "Cannot assign builtin procedure `%s` in %.*s",
			      expr_str,
			      LIT(context_name));

			operand->mode = Addressing_Invalid;

			gb_string_free(expr_str);
		}


		if (e->type == NULL) {
			e->type = t_invalid;
		}
		return NULL;
	}

	if (e->type == NULL) {
		// NOTE(bill): Use the type of the operand
		Type *t = operand->type;
		if (is_type_untyped(t)) {
			if (t == t_invalid || is_type_untyped_nil(t)) {
				error(e->token, "Use of untyped nil in %.*s", LIT(context_name));
				e->type = t_invalid;
				return NULL;
			}
			t = default_type(t);
		}
		e->type = t;
	}

	check_assignment(c, operand, e->type, context_name);
	if (operand->mode == Addressing_Invalid) {
		return NULL;
	}

	return e->type;
}

void check_init_variables(Checker *c, Entity **lhs, isize lhs_count, AstNodeArray inits, String context_name) {
	if ((lhs == NULL || lhs_count == 0) && inits.count == 0) {
		return;
	}

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);

	// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
	// an extra allocation
	Array(Operand) operands;
	array_init_reserve(&operands, c->tmp_allocator, 2*lhs_count);

	for_array(i, inits) {
		AstNode *rhs = inits.e[i];
		Operand o = {0};
		check_multi_expr(c, &o, rhs);
		if (o.type->kind != Type_Tuple) {
			array_add(&operands, o);
		} else {
			TypeTuple *tuple = &o.type->Tuple;
			for (isize j = 0; j < tuple->variable_count; j++) {
				o.type = tuple->variables[j]->type;
				array_add(&operands, o);
			}
		}
	}

	isize rhs_count = operands.count;
	for_array(i, operands) {
		if (operands.e[i].mode == Addressing_Invalid) {
			rhs_count--;
		}
	}


	isize max = gb_min(lhs_count, rhs_count);
	for (isize i = 0; i < max; i++) {
		check_init_variable(c, lhs[i], &operands.e[i], context_name);
	}

	if (rhs_count > 0 && lhs_count != rhs_count) {
		error(lhs[0]->token, "Assignment count mismatch `%td` := `%td`", lhs_count, rhs_count);
	}

	gb_temp_arena_memory_end(tmp);
}


void check_var_decl_node(Checker *c, AstNode *node) {
	ast_node(vd, VarDecl, node);
	isize entity_count = vd->names.count;
	isize entity_index = 0;
	Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);

	for_array(i, vd->names) {
		AstNode *name = vd->names.e[i];
		Entity *entity = NULL;
		if (name->kind == AstNode_Ident) {
			Token token = name->Ident;
			String str = token.string;
			Entity *found = NULL;
			// NOTE(bill): Ignore assignments to `_`
			if (str_ne(str, str_lit("_"))) {
				found = current_scope_lookup_entity(c->context.scope, str);
			}
			if (found == NULL) {
				entity = make_entity_variable(c->allocator, c->context.scope, token, NULL);
				add_entity_definition(&c->info, name, entity);
			} else {
				TokenPos pos = found->token.pos;
				error(token,
				      "Redeclaration of `%.*s` in this scope\n"
				      "\tat %.*s(%td:%td)",
				      LIT(str), LIT(pos.file), pos.line, pos.column);
				entity = found;
			}
		} else {
			error_node(name, "A variable declaration must be an identifier");
		}
		if (entity == NULL) {
			entity = make_entity_dummy_variable(c->allocator, c->global_scope, ast_node_token(name));
		}
		entities[entity_index++] = entity;
	}

	Type *init_type = NULL;
	if (vd->type) {
		init_type = check_type_extra(c, vd->type, NULL);
		if (init_type == NULL) {
			init_type = t_invalid;
		}
	}

	for (isize i = 0; i < entity_count; i++) {
		Entity *e = entities[i];
		GB_ASSERT(e != NULL);
		if (e->flags & EntityFlag_Visited) {
			e->type = t_invalid;
			continue;
		}
		e->flags |= EntityFlag_Visited;

		if (e->type == NULL)
			e->type = init_type;
	}

	check_init_variables(c, entities, entity_count, vd->values, str_lit("variable declaration"));

	for_array(i, vd->names) {
		if (entities[i] != NULL) {
			add_entity(c, c->context.scope, vd->names.e[i], entities[i]);
		}
	}

}



void check_init_constant(Checker *c, Entity *e, Operand *operand) {
	if (operand->mode == Addressing_Invalid ||
	    operand->type == t_invalid ||
	    e->type == t_invalid) {
		if (e->type == NULL) {
			e->type = t_invalid;
		}
		return;
	}

	if (operand->mode != Addressing_Constant) {
		// TODO(bill): better error
		gbString str = expr_to_string(operand->expr);
		error_node(operand->expr, "`%s` is not a constant", str);
		gb_string_free(str);
		if (e->type == NULL) {
			e->type = t_invalid;
		}
		return;
	}
	if (!is_type_constant_type(operand->type)) {
		gbString type_str = type_to_string(operand->type);
		error_node(operand->expr, "Invalid constant type: `%s`", type_str);
		gb_string_free(type_str);
		if (e->type == NULL) {
			e->type = t_invalid;
		}
		return;
	}

	if (e->type == NULL) { // NOTE(bill): type inference
		e->type = operand->type;
	}

	check_assignment(c, operand, e->type, str_lit("constant declaration"));
	if (operand->mode == Addressing_Invalid) {
		return;
	}

	e->Constant.value = operand->value;
}

void check_type_decl(Checker *c, Entity *e, AstNode *type_expr, Type *def) {
	GB_ASSERT(e->type == NULL);
	Type *named = make_type_named(c->allocator, e->token.string, NULL, e);
	named->Named.type_name = e;
	if (def != NULL && def->kind == Type_Named) {
		def->Named.base = named;
	}
	e->type = named;

	// gb_printf_err("%.*s %p\n", LIT(e->token.string), e);

	Type *bt = check_type_extra(c, type_expr, named);
	named->Named.base = base_type(bt);
	if (named->Named.base == t_invalid) {
		// gb_printf("check_type_decl: %s\n", type_to_string(named));
	}
}

void check_const_decl(Checker *c, Entity *e, AstNode *type_expr, AstNode *init, Type *named_type) {
	GB_ASSERT(e->type == NULL);
	GB_ASSERT(e->kind == Entity_Constant);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	GB_ASSERT(c->context.iota.kind == ExactValue_Invalid);
	c->context.iota = e->Constant.value;
	e->Constant.value = (ExactValue){0};

	if (type_expr) {
		Type *t = check_type(c, type_expr);
		if (!is_type_constant_type(t)) {
			gbString str = type_to_string(t);
			error_node(type_expr, "Invalid constant type `%s`", str);
			gb_string_free(str);
			e->type = t_invalid;
			c->context.iota = (ExactValue){0};
			return;
		}
		e->type = t;
	}

	Operand operand = {0};
	if (init != NULL) {
		check_expr(c, &operand, init);
	}

	check_init_constant(c, e, &operand);
	c->context.iota = (ExactValue){0};
}



bool are_signatures_similar_enough(Type *a_, Type *b_) {
	GB_ASSERT(a_->kind == Type_Proc);
	GB_ASSERT(b_->kind == Type_Proc);
	TypeProc *a = &a_->Proc;
	TypeProc *b = &b_->Proc;

	if (a->param_count != b->param_count) {
		return false;
	}
	if (a->result_count != b->result_count) {
		return false;
	}
	for (isize i = 0; i < a->param_count; i++) {
		Type *x = base_type(a->params->Tuple.variables[i]->type);
		Type *y = base_type(b->params->Tuple.variables[i]->type);
		if (is_type_pointer(x) && is_type_pointer(y)) {
			continue;
		}

		if (!are_types_identical(x, y)) {
			return false;
		}
	}
	for (isize i = 0; i < a->result_count; i++) {
		Type *x = base_type(a->results->Tuple.variables[i]->type);
		Type *y = base_type(b->results->Tuple.variables[i]->type);
		if (is_type_pointer(x) && is_type_pointer(y)) {
			continue;
		}

		if (!are_types_identical(x, y)) {
			return false;
		}
	}

	return true;
}

void check_proc_decl(Checker *c, Entity *e, DeclInfo *d) {
	GB_ASSERT(e->type == NULL);

	Type *proc_type = make_type_proc(c->allocator, e->scope, NULL, 0, NULL, 0, false);
	e->type = proc_type;
	ast_node(pd, ProcDecl, d->proc_decl);

	check_open_scope(c, pd->type);
	check_procedure_type(c, proc_type, pd->type);

	bool is_foreign      = (pd->tags & ProcTag_foreign)   != 0;
	bool is_link_name    = (pd->tags & ProcTag_link_name) != 0;
	bool is_export       = (pd->tags & ProcTag_export)    != 0;
	bool is_inline       = (pd->tags & ProcTag_inline)    != 0;
	bool is_no_inline    = (pd->tags & ProcTag_no_inline) != 0;

	if ((d->scope->is_file || d->scope->is_global) &&
	    str_eq(e->token.string, str_lit("main"))) {
		if (proc_type != NULL) {
			TypeProc *pt = &proc_type->Proc;
			if (pt->param_count != 0 ||
			    pt->result_count != 0) {
				gbString str = type_to_string(proc_type);
				error(e->token, "Procedure type of `main` was expected to be `proc()`, got %s", str);
				gb_string_free(str);
			}
		}
	}

	if (is_inline && is_no_inline) {
		error_node(pd->type, "You cannot apply both `inline` and `no_inline` to a procedure");
	}

	if (is_foreign && is_link_name) {
		error_node(pd->type, "You cannot apply both `foreign` and `link_name` to a procedure");
	} else if (is_foreign && is_export) {
		error_node(pd->type, "You cannot apply both `foreign` and `export` to a procedure");
	}


	if (pd->body != NULL) {
		if (is_foreign) {
			error_node(pd->body, "A procedure tagged as `#foreign` cannot have a body");
		}

		d->scope = c->context.scope;

		GB_ASSERT(pd->body->kind == AstNode_BlockStmt);
		check_procedure_later(c, c->curr_ast_file, e->token, d, proc_type, pd->body, pd->tags);
	}

	if (is_foreign) {
		MapEntity *fp = &c->info.foreign_procs;
		AstNodeProcDecl *proc_decl = &d->proc_decl->ProcDecl;
		String name = proc_decl->name->Ident.string;
		if (proc_decl->foreign_name.len > 0) {
			name = proc_decl->foreign_name;
		}

		e->Procedure.is_foreign = true;
		e->Procedure.foreign_name = name;

		HashKey key = hash_string(name);
		Entity **found = map_entity_get(fp, key);
		if (found) {
			Entity *f = *found;
			TokenPos pos = f->token.pos;
			Type *this_type = base_type(e->type);
			Type *other_type = base_type(f->type);
			if (!are_signatures_similar_enough(this_type, other_type)) {
				error_node(d->proc_decl,
				           "Redeclaration of #foreign procedure `%.*s` with different type signatures\n"
				           "\tat %.*s(%td:%td)",
				           LIT(name), LIT(pos.file), pos.line, pos.column);
			}
		} else {
			map_entity_set(fp, key, e);
		}
	} else {
		String name = e->token.string;
		if (is_link_name) {
			AstNodeProcDecl *proc_decl = &d->proc_decl->ProcDecl;
			name = proc_decl->link_name;
		}

		if (is_link_name || is_export) {
			MapEntity *fp = &c->info.foreign_procs;

			e->Procedure.link_name = name;

			HashKey key = hash_string(name);
			Entity **found = map_entity_get(fp, key);
			if (found) {
				Entity *f = *found;
				TokenPos pos = f->token.pos;
				// TODO(bill): Better error message?
				error_node(d->proc_decl,
				           "Non unique linking name for procedure `%.*s`\n"
				           "\tother at %.*s(%td:%td)",
				           LIT(name), LIT(pos.file), pos.line, pos.column);
			} else {
				map_entity_set(fp, key, e);
			}
		}
	}

	check_close_scope(c);
}

void check_var_decl(Checker *c, Entity *e, Entity **entities, isize entity_count, AstNode *type_expr, AstNode *init_expr) {
	GB_ASSERT(e->type == NULL);
	GB_ASSERT(e->kind == Entity_Variable);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	if (type_expr != NULL) {
		e->type = check_type_extra(c, type_expr, NULL);
	}

	if (init_expr == NULL) {
		if (type_expr == NULL) {
			e->type = t_invalid;
		}
		return;
	}

	if (entities == NULL || entity_count == 1) {
		GB_ASSERT(entities == NULL || entities[0] == e);
		Operand operand = {0};
		check_expr(c, &operand, init_expr);
		check_init_variable(c, e, &operand, str_lit("variable declaration"));
	}

	if (type_expr != NULL) {
		for (isize i = 0; i < entity_count; i++) {
			entities[i]->type = e->type;
		}
	}

	AstNodeArray inits;
	array_init_reserve(&inits, c->allocator, 1);
	array_add(&inits, init_expr);
	check_init_variables(c, entities, entity_count, inits, str_lit("variable declaration"));
}


void check_entity_decl(Checker *c, Entity *e, DeclInfo *d, Type *named_type) {
	if (e->type != NULL) {
		return;
	}

	if (d == NULL) {
		DeclInfo **found = map_decl_info_get(&c->info.entities, hash_pointer(e));
		if (found) {
			d = *found;
		} else {
			// TODO(bill): Err here?
			e->type = t_invalid;
			set_base_type(named_type, t_invalid);
			return;
			// GB_PANIC("`%.*s` should been declared!", LIT(e->token.string));
		}
	}

	CheckerContext prev = c->context;
	c->context.scope = d->scope;
	c->context.decl  = d;

	switch (e->kind) {
	case Entity_Constant:
		check_const_decl(c, e, d->type_expr, d->init_expr, named_type);
		break;
	case Entity_Variable:
		check_var_decl(c, e, d->entities, d->entity_count, d->type_expr, d->init_expr);
		break;
	case Entity_TypeName:
		check_type_decl(c, e, d->type_expr, named_type);
		break;
	case Entity_Procedure:
		check_proc_decl(c, e, d);
		break;
	}

	c->context = prev;
}



void check_proc_body(Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	GB_ASSERT(body->kind == AstNode_BlockStmt);

	CheckerContext old_context = c->context;
	c->context.scope = decl->scope;
	c->context.decl = decl;

	GB_ASSERT(type->kind == Type_Proc);
	if (type->Proc.param_count > 0) {
		TypeTuple *params = &type->Proc.params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			GB_ASSERT(e->kind == Entity_Variable);
			if (!(e->flags & EntityFlag_Anonymous)) {
				continue;
			}
			String name = e->token.string;
			Type *t = base_type(type_deref(e->type));
			if (is_type_struct(t) || is_type_raw_union(t)) {
				Scope **found = map_scope_get(&c->info.scopes, hash_pointer(t->Record.node));
				GB_ASSERT(found != NULL);
				for_array(i, (*found)->elements.entries) {
					Entity *f = (*found)->elements.entries.e[i].value;
					if (f->kind == Entity_Variable) {
						Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
						Entity *prev = scope_insert_entity(c->context.scope, uvar);
						if (prev != NULL) {
							error(e->token, "Namespace collision while `using` `%.*s` of: %.*s", LIT(name), LIT(prev->token.string));
							break;
						}
					}
				}
			} else {
				error(e->token, "`using` can only be applied to variables of type struct or raw_union");
				break;
			}
		}
	}

	push_procedure(c, type);
	{
		ast_node(bs, BlockStmt, body);
		// TODO(bill): Check declarations first (except mutable variable declarations)
		check_stmt_list(c, bs->stmts, 0);
		if (type->Proc.result_count > 0) {
			if (!check_is_terminating(body)) {
				error(bs->close, "Missing return statement at the end of the procedure");
			}
		}
	}
	pop_procedure(c);


	check_scope_usage(c, c->context.scope);

	c->context = old_context;
}



