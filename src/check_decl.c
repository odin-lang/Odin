bool check_is_terminating(AstNode *node);
void check_stmt          (Checker *c, AstNode *node, u32 flags);

// NOTE(bill): `content_name` is for debugging and error messages
Type *check_init_variable(Checker *c, Entity *e, Operand *operand, String context_name) {
	if (operand->mode == Addressing_Invalid ||
		operand->type == t_invalid ||
		e->type == t_invalid) {

		if (operand->mode == Addressing_Builtin) {
			gbString expr_str = expr_to_string(operand->expr);

			// TODO(bill): is this a good enough error message?
			// TODO(bill): Actually allow built in procedures to be passed around and thus be created on use
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
		GB_ASSERT(is_type_typed(t));
		e->type = t;
	}

	e->parent_proc_decl = c->context.curr_proc_decl;

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
	ArrayOperand operands = {0};
	array_init_reserve(&operands, c->tmp_allocator, 2*lhs_count);
	check_unpack_arguments(c, lhs_count, &operands, inits, true);

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
		error(lhs[0]->token, "Assignment count mismatch `%td` = `%td`", lhs_count, rhs_count);
	}

	gb_temp_arena_memory_end(tmp);
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

	e->parent_proc_decl = c->context.curr_proc_decl;

	e->Constant.value = operand->value;
}

void check_type_decl(Checker *c, Entity *e, AstNode *type_expr, Type *def) {
	GB_ASSERT(e->type == NULL);
	String name = e->token.string;
	Type *named = make_type_named(c->allocator, name, NULL, e);
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

	if (type_expr) {
		Type *t = check_type(c, type_expr);
		if (!is_type_constant_type(t)) {
			gbString str = type_to_string(t);
			error_node(type_expr, "Invalid constant type `%s`", str);
			gb_string_free(str);
			e->type = t_invalid;
			return;
		}
		e->type = t;
	}

	Operand operand = {0};
	if (init != NULL) {
		check_expr_or_type(c, &operand, init);
	}
	if (operand.mode == Addressing_Type) {
		e->kind = Entity_TypeName;

		DeclInfo *d = c->context.decl;
		d->type_expr = d->init_expr;
		check_type_decl(c, e, d->type_expr, named_type);
		return;
	}

	check_init_constant(c, e, &operand);

	if (operand.mode == Addressing_Invalid ||
		base_type(operand.type) == t_invalid) {
		error(e->token, "Invalid declaration type");
	}
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

void check_proc_lit(Checker *c, Entity *e, DeclInfo *d) {
	GB_ASSERT(e->type == NULL);
	if (d->proc_lit->kind != AstNode_ProcLit) {
		// TOOD(bill): Better error message
		error_node(d->proc_lit, "Expected a procedure to check");
		return;
	}

	Type *proc_type = make_type_proc(c->allocator, e->scope, NULL, 0, NULL, 0, false, ProcCC_Odin);
	e->type = proc_type;
	ast_node(pd, ProcLit, d->proc_lit);

	check_open_scope(c, pd->type);
	check_procedure_type(c, proc_type, pd->type);

	bool is_foreign         = (pd->tags & ProcTag_foreign)   != 0;
	bool is_link_name       = (pd->tags & ProcTag_link_name) != 0;
	bool is_export          = (pd->tags & ProcTag_export)    != 0;
	bool is_inline          = (pd->tags & ProcTag_inline)    != 0;
	bool is_no_inline       = (pd->tags & ProcTag_no_inline) != 0;
	bool is_require_results = (pd->tags & ProcTag_require_results) != 0;


	if (d->scope->is_file && str_eq(e->token.string, str_lit("main"))) {
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


	if (proc_type != NULL && is_type_proc(proc_type)) {
		TypeProc *tp = &proc_type->Proc;
		if (tp->result_count == 0 && is_require_results) {
			error_node(pd->type, "`#require_results` is not needed on a procedure with no results");
		} else {
			tp->require_results = is_require_results;
		}
	}

	if (is_foreign) {
		MapEntity *fp = &c->info.foreigns;
		String name = e->token.string;
		if (pd->foreign_name.len > 0) {
			name = pd->foreign_name;
		}

		AstNode *foreign_library = d->proc_lit->ProcLit.foreign_library;
		if (foreign_library == NULL) {
			error(e->token, "#foreign procedures must declare which library they are from");
		} else if (foreign_library->kind != AstNode_Ident) {
			error_node(foreign_library, "#foreign library names must be an identifier");
		} else {
			String name = foreign_library->Ident.string;
			Entity *found = scope_lookup_entity(c->context.scope, name);
			if (found == NULL) {
				if (str_eq(name, str_lit("_"))) {
					error_node(foreign_library, "`_` cannot be used as a value type");
				} else {
					error_node(foreign_library, "Undeclared name: %.*s", LIT(name));
				}
			} else if (found->kind != Entity_LibraryName) {
				error_node(foreign_library, "`_` cannot be used as a library name");
			} else {
				// TODO(bill): Extra stuff to do with library names?
				e->Procedure.foreign_library = found;
				add_entity_use(c, foreign_library, found);
			}
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
				error_node(d->proc_lit,
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
			name = pd->link_name;
		}

		if (is_link_name || is_export) {
			MapEntity *fp = &c->info.foreigns;

			e->Procedure.link_name = name;

			HashKey key = hash_string(name);
			Entity **found = map_entity_get(fp, key);
			if (found) {
				Entity *f = *found;
				TokenPos pos = f->token.pos;
				// TODO(bill): Better error message?
				error_node(d->proc_lit,
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


void check_alias_decl(Checker *c, Entity *e, AstNode *expr, Type *named_type) {
	GB_ASSERT(e->type == NULL);
	GB_ASSERT(e->kind == Entity_Alias);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;
	e->type = t_invalid;

	expr = unparen_expr(expr);

	if (expr->kind == AstNode_Alias) {
		error_node(expr, "#alias of an #alias is not allowed");
		return;
	}

	Operand operand = {0};
	check_expr_or_type(c, &operand, expr);
	if (operand.mode != Addressing_Type) {
		error_node(expr, "#alias declarations only allow types");
		return;
	}
	e->kind = Entity_TypeName;
	e->TypeName.is_type_alias = true;
	e->type = NULL;

	DeclInfo *d = c->context.decl;
	d->type_expr = expr;
	check_type_decl(c, e, d->type_expr, named_type);


	// Operand o = {0};
	// Entity *f = NULL;
	// if (expr->kind == AstNode_Ident) {
	// 	f = check_ident(c, &o, expr, NULL, NULL, true);
	// } else if (expr->kind == AstNode_SelectorExpr) {
	// 	f = check_selector(c, &o, expr, NULL);
	// } else {
	// 	check_expr_or_type(c, &o, expr);
	// }
	// if (o.mode == Addressing_Invalid) {
	// 	return;
	// }
	// switch (o.mode) {
	// case Addressing_Type:
	// 	e->type = o.type;
	// 	// e->kind = Entity_TypeName;
	// 	// e->TypeName.is_type_alias = true;
	// 	e->Alias.kind     = EntityAlias_Type;
	// 	e->Alias.original = f;
	// 	break;
	// default:
	// 	error_node(expr, "#alias declarations only allow types");
	// 	e->kind = Entity_Invalid;
	// 	e->type = t_invalid;
	// 	break;
	// }
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

	e->parent_proc_decl = c->context.curr_proc_decl;

	switch (e->kind) {
	case Entity_Variable:
		check_var_decl(c, e, d->entities, d->entity_count, d->type_expr, d->init_expr);
		break;
	case Entity_Constant:
		check_const_decl(c, e, d->type_expr, d->init_expr, named_type);
		break;
	case Entity_TypeName:
		check_type_decl(c, e, d->type_expr, named_type);
		break;
	case Entity_Alias:
		check_alias_decl(c, e, d->init_expr, named_type);
		break;
	case Entity_Procedure:
		check_proc_lit(c, e, d);
		break;
	}

	c->context = prev;
}



void check_proc_body(Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	GB_ASSERT(body->kind == AstNode_BlockStmt);

	String proc_name = {0};
	if (token.kind == Token_Ident) {
		proc_name = token.string;
	} else {
		// TODO(bill): Better name
		proc_name = str_lit("(anonymous-procedure)");
	}

	CheckerContext old_context = c->context;
	c->context.scope = decl->scope;
	c->context.decl = decl;
	c->context.proc_name = proc_name;
	c->context.curr_proc_decl = decl;

	GB_ASSERT(type->kind == Type_Proc);
	if (type->Proc.param_count > 0) {
		TypeTuple *params = &type->Proc.params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			GB_ASSERT(e->kind == Entity_Variable);
			if (!(e->flags & EntityFlag_Using)) {
				continue;
			}
			bool is_immutable = e->Variable.is_immutable;
			String name = e->token.string;
			Type *t = base_type(type_deref(e->type));
			if (is_type_struct(t) || is_type_raw_union(t)) {
				Scope **found = map_scope_get(&c->info.scopes, hash_pointer(t->Record.node));
				GB_ASSERT(found != NULL);
				for_array(i, (*found)->elements.entries) {
					Entity *f = (*found)->elements.entries.e[i].value;
					if (f->kind == Entity_Variable) {
						Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
						uvar->Variable.is_immutable = is_immutable;
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
		check_stmt_list(c, bs->stmts, Stmt_CheckScopeDecls);
		if (type->Proc.result_count > 0) {
			if (!check_is_terminating(body)) {
				if (token.kind == Token_Ident) {
					error(bs->close, "Missing return statement at the end of the procedure `%.*s`", LIT(token.string));
				} else {
					error(bs->close, "Missing return statement at the end of the procedure");
				}
			}
		}
	}
	pop_procedure(c);


	check_scope_usage(c, c->context.scope);
	c->context = old_context;

	if (decl->parent != NULL) {
		// NOTE(bill): Add the dependencies from the procedure literal (lambda)
		for_array(i, decl->deps.entries) {
			HashKey key = decl->deps.entries.e[i].key;
			Entity *e = cast(Entity *)key.ptr;
			map_bool_set(&decl->parent->deps, key, true);
		}
	}
}



