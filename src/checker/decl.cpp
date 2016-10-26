b32 check_is_terminating(AstNode *node);
void check_stmt         (Checker *c, AstNode *node, u32 flags);
void check_stmt_list    (Checker *c, AstNodeArray stmts, u32 flags);
void check_type_decl    (Checker *c, Entity *e, AstNode *type_expr, Type *def, CycleChecker *cycle_checker);
void check_const_decl   (Checker *c, Entity *e, AstNode *type_expr, AstNode *init_expr);
void check_proc_decl    (Checker *c, Entity *e, DeclInfo *d);
void check_var_decl     (Checker *c, Entity *e, Entity **entities, isize entity_count, AstNode *type_expr, AstNode *init_expr);

// NOTE(bill): `content_name` is for debugging and error messages
Type *check_init_variable(Checker *c, Entity *e, Operand *operand, String context_name) {
	PROF_PROC();

	if (operand->mode == Addressing_Invalid ||
	    operand->type == t_invalid ||
	    e->type == t_invalid) {

		if (operand->mode == Addressing_Builtin) {
			gbString expr_str = expr_to_string(operand->expr);
			defer (gb_string_free(expr_str));

			// TODO(bill): is this a good enough error message?
			error(ast_node_token(operand->expr),
			      "Cannot assign builtin procedure `%s` in %.*s",
			      expr_str,
			      LIT(context_name));

			operand->mode = Addressing_Invalid;
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
	PROF_PROC();

	if ((lhs == NULL || lhs_count == 0) && inits.count == 0) {
		return;
	}

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
	// an extra allocation
	Array<Operand> operands;
	array_init(&operands, c->tmp_allocator, 2*lhs_count);

	for_array(i, inits) {
		AstNode *rhs = inits[i];
		Operand o = {};
		check_multi_expr(c, &o, rhs);
		if (o.type->kind != Type_Tuple) {
			array_add(&operands, o);
		} else {
			auto *tuple = &o.type->Tuple;
			for (isize j = 0; j < tuple->variable_count; j++) {
				o.type = tuple->variables[j]->type;
				array_add(&operands, o);
			}
		}
	}

	isize rhs_count = operands.count;
	for_array(i, operands) {
		if (operands[i].mode == Addressing_Invalid) {
			rhs_count--;
		}
	}


	isize max = gb_min(lhs_count, rhs_count);
	for (isize i = 0; i < max; i++) {
		check_init_variable(c, lhs[i], &operands[i], context_name);
	}

	if (rhs_count > 0 && lhs_count != rhs_count) {
		error(lhs[0]->token, "Assignment count mismatch `%td` := `%td`", lhs_count, rhs_count);
	}
}



void check_entity_decl(Checker *c, Entity *e, DeclInfo *d, Type *named_type, CycleChecker *cycle_checker) {
	PROF_PROC();

	if (e->type != NULL) {
		return;
	}

	if (d == NULL) {
		DeclInfo **found = map_get(&c->info.entities, hash_pointer(e));
		if (found) {
			d = *found;
		} else {
			e->type = t_invalid;
			set_base_type(named_type, t_invalid);
			return;
			// GB_PANIC("`%.*s` should been declared!", LIT(e->token.string));
		}
	}

	if (e->kind == Entity_Procedure) {
		check_proc_decl(c, e, d);
		return;
	}
	auto prev = c->context;
	c->context.scope = d->scope;
	c->context.decl  = d;
	defer (c->context = prev);

	switch (e->kind) {
	case Entity_Constant:
		check_const_decl(c, e, d->type_expr, d->init_expr);
		break;
	case Entity_Variable:
		check_var_decl(c, e, d->entities, d->entity_count, d->type_expr, d->init_expr);
		break;
	case Entity_TypeName:
		check_type_decl(c, e, d->type_expr, named_type, cycle_checker);
		break;
	}
}



void check_var_decl_node(Checker *c, AstNode *node) {
	PROF_PROC();

	ast_node(vd, VarDecl, node);
	isize entity_count = vd->names.count;
	isize entity_index = 0;
	Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);

	for_array(i, vd->names) {
		AstNode *name = vd->names[i];
		Entity *entity = NULL;
		if (name->kind == AstNode_Ident) {
			Token token = name->Ident;
			String str = token.string;
			Entity *found = NULL;
			// NOTE(bill): Ignore assignments to `_`
			if (str != make_string("_")) {
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
			error(ast_node_token(name), "A variable declaration must be an identifier");
		}
		if (entity == NULL) {
			entity = make_entity_dummy_variable(c->allocator, c->global_scope, ast_node_token(name));
		}
		entities[entity_index++] = entity;
	}

	Type *init_type = NULL;
	if (vd->type) {
		init_type = check_type(c, vd->type, NULL);
		if (init_type == NULL)
			init_type = t_invalid;
	}

	for (isize i = 0; i < entity_count; i++) {
		Entity *e = entities[i];
		GB_ASSERT(e != NULL);
		if (e->Variable.visited) {
			e->type = t_invalid;
			continue;
		}
		e->Variable.visited = true;

		if (e->type == NULL)
			e->type = init_type;
	}

	check_init_variables(c, entities, entity_count, vd->values, make_string("variable declaration"));

	for_array(i, vd->names) {
		if (entities[i] != NULL) {
			add_entity(c, c->context.scope, vd->names[i], entities[i]);
		}
	}

}



void check_init_constant(Checker *c, Entity *e, Operand *operand) {
	PROF_PROC();

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
		error(ast_node_token(operand->expr),
		      "`%.*s` is not a constant", LIT(ast_node_token(operand->expr).string));
		if (e->type == NULL) {
			e->type = t_invalid;
		}
		return;
	}
	// if (!is_type_constant_type(operand->type)) {
	// 	gbString type_str = type_to_string(operand->type);
	// 	defer (gb_string_free(type_str));
	// 	error(ast_node_token(operand->expr),
	// 	      "Invalid constant type: `%s`", type_str);
	// 	if (e->type == NULL) {
	// 		e->type = t_invalid;
	// 	}
	// 	return;
	// }

	if (e->type == NULL) { // NOTE(bill): type inference
		e->type = operand->type;
	}

	check_assignment(c, operand, e->type, make_string("constant declaration"));
	if (operand->mode == Addressing_Invalid) {
		return;
	}

	e->Constant.value = operand->value;
}


void check_const_decl(Checker *c, Entity *e, AstNode *type_expr, AstNode *init_expr) {
	PROF_PROC();

	GB_ASSERT(e->type == NULL);

	if (e->Variable.visited) {
		e->type = t_invalid;
		return;
	}
	e->Variable.visited = true;

	if (type_expr) {
		Type *t = check_type(c, type_expr);
		// if (!is_type_constant_type(t)) {
		// 	gbString str = type_to_string(t);
		// 	defer (gb_string_free(str));
		// 	error(ast_node_token(type_expr),
		// 	      "Invalid constant type `%s`", str);
		// 	e->type = t_invalid;
		// 	return;
		// }
		e->type = t;
	}

	Operand operand = {};
	if (init_expr) {
		check_expr(c, &operand, init_expr);
	}
	check_init_constant(c, e, &operand);
}

void check_type_decl(Checker *c, Entity *e, AstNode *type_expr, Type *def, CycleChecker *cycle_checker) {
	PROF_PROC();

	GB_ASSERT(e->type == NULL);
	Type *named = make_type_named(c->allocator, e->token.string, NULL, e);
	named->Named.type_name = e;
	if (def != NULL && def->kind == Type_Named) {
		def->Named.base = named;
	}
	e->type = named;

	CycleChecker local_cycle_checker = {};
	if (cycle_checker == NULL) {
		cycle_checker = &local_cycle_checker;
	}
	defer (cycle_checker_destroy(&local_cycle_checker));

	Type *bt = check_type(c, type_expr, named, cycle_checker_add(cycle_checker, e));
	named->Named.base = bt;
	named->Named.base = base_type(named->Named.base);
	if (named->Named.base == t_invalid) {
		gb_printf("check_type_decl: %s\n", type_to_string(named));
	}
}


b32 are_signatures_similar_enough(Type *a_, Type *b_) {
	GB_ASSERT(a_->kind == Type_Proc);
	GB_ASSERT(b_->kind == Type_Proc);
	auto *a = &a_->Proc;
	auto *b = &b_->Proc;

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
	PROF_PROC();

	GB_ASSERT(e->type == NULL);

	Type *proc_type = make_type_proc(c->allocator, e->scope, NULL, 0, NULL, 0, false);
	e->type = proc_type;
	ast_node(pd, ProcDecl, d->proc_decl);
	check_open_scope(c, pd->type);
	defer (check_close_scope(c));
	check_procedure_type(c, proc_type, pd->type);

	b32 is_foreign      = (pd->tags & ProcTag_foreign)   != 0;
	b32 is_link_name    = (pd->tags & ProcTag_link_name) != 0;
	b32 is_inline       = (pd->tags & ProcTag_inline)    != 0;
	b32 is_no_inline    = (pd->tags & ProcTag_no_inline) != 0;

	if ((d->scope->is_file || d->scope->is_global) &&
	    e->token.string == "main") {
		if (proc_type != NULL) {
			auto *pt = &proc_type->Proc;
			if (pt->param_count != 0 ||
			    pt->result_count) {
				gbString str = type_to_string(proc_type);
				defer (gb_string_free(str));

				error(e->token,
				      "Procedure type of `main` was expected to be `proc()`, got %s", str);
			}
		}
	}

	if (is_inline && is_no_inline) {
		error(ast_node_token(pd->type),
		      "You cannot apply both `inline` and `no_inline` to a procedure");
	}

	if (is_foreign && is_link_name) {
		error(ast_node_token(pd->type),
		      "You cannot apply both `foreign` and `link_name` to a procedure");
	}

	if (pd->body != NULL) {
		if (is_foreign) {
			error(ast_node_token(pd->body),
			      "A procedure tagged as `#foreign` cannot have a body");
		}

		d->scope = c->context.scope;

		GB_ASSERT(pd->body->kind == AstNode_BlockStmt);
		check_procedure_later(c, c->curr_ast_file, e->token, d, proc_type, pd->body, pd->tags);
	}

	if (is_foreign) {
		auto *fp = &c->info.foreign_procs;
		auto *proc_decl = &d->proc_decl->ProcDecl;
		String name = proc_decl->name->Ident.string;
		if (proc_decl->foreign_name.len > 0) {
			name = proc_decl->foreign_name;
		}
		HashKey key = hash_string(name);
		auto *found = map_get(fp, key);
		if (found) {
			Entity *f = *found;
			TokenPos pos = f->token.pos;
			Type *this_type = base_type(e->type);
			Type *other_type = base_type(f->type);
			if (!are_signatures_similar_enough(this_type, other_type)) {
				error(ast_node_token(d->proc_decl),
				      "Redeclaration of #foreign procedure `%.*s` with different type signatures\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name), LIT(pos.file), pos.line, pos.column);
			}
		} else {
			map_set(fp, key, e);
		}
	} else if (is_link_name) {
		auto *fp = &c->info.foreign_procs;
		auto *proc_decl = &d->proc_decl->ProcDecl;
		String name = proc_decl->link_name;

		HashKey key = hash_string(name);
		auto *found = map_get(fp, key);
		if (found) {
			Entity *f = *found;
			TokenPos pos = f->token.pos;
			error(ast_node_token(d->proc_decl),
			      "Non unique #link_name for procedure `%.*s`\n"
			      "\tother at %.*s(%td:%td)",
			      LIT(name), LIT(pos.file), pos.line, pos.column);
		} else {
			map_set(fp, key, e);
		}
	}
}

void check_var_decl(Checker *c, Entity *e, Entity **entities, isize entity_count, AstNode *type_expr, AstNode *init_expr) {
	PROF_PROC();

	GB_ASSERT(e->type == NULL);
	GB_ASSERT(e->kind == Entity_Variable);

	if (e->Variable.visited) {
		e->type = t_invalid;
		return;
	}
	e->Variable.visited = true;

	if (type_expr != NULL)
		e->type = check_type(c, type_expr, NULL);

	if (init_expr == NULL) {
		if (type_expr == NULL)
			e->type = t_invalid;
		return;
	}

	if (entities == NULL || entity_count == 1) {
		GB_ASSERT(entities == NULL || entities[0] == e);
		Operand operand = {};
		check_expr(c, &operand, init_expr);
		check_init_variable(c, e, &operand, make_string("variable declaration"));
	}

	if (type_expr != NULL) {
		for (isize i = 0; i < entity_count; i++)
			entities[i]->type = e->type;
	}

	AstNodeArray inits;
	array_init(&inits, c->allocator, 1);
	array_add(&inits, init_expr);
	check_init_variables(c, entities, entity_count, inits, make_string("variable declaration"));
}

void check_proc_body(Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	GB_ASSERT(body->kind == AstNode_BlockStmt);

	CheckerContext old_context = c->context;
	c->context.scope = decl->scope;
	c->context.decl = decl;
	defer (c->context = old_context);


	GB_ASSERT(type->kind == Type_Proc);
	if (type->Proc.param_count > 0) {
		auto *params = &type->Proc.params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			GB_ASSERT(e->kind == Entity_Variable);
			if (!e->Variable.anonymous) {
				continue;
			}
			String name = e->token.string;
			Type *t = base_type(type_deref(e->type));
			if (is_type_struct(t) || is_type_raw_union(t)) {
				Scope **found = map_get(&c->info.scopes, hash_pointer(t->Record.node));
				GB_ASSERT(found != NULL);
				for_array(i, (*found)->elements.entries) {
					Entity *f = (*found)->elements.entries[i].value;
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
}



