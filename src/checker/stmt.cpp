// Statements and Declarations

enum StmtFlag : u32 {
	Stmt_BreakAllowed       = GB_BIT(0),
	Stmt_ContinueAllowed    = GB_BIT(1),
	Stmt_FallthroughAllowed = GB_BIT(2), // TODO(bill): fallthrough
};


void check_stmt(Checker *c, AstNode *node, u32 flags);
void check_proc_decl(Checker *c, Entity *e, DeclInfo *d);

void check_stmt_list(Checker *c, AstNodeArray stmts, u32 flags) {
	if (stmts.count == 0) {
		return;
	}

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	struct Delay {
		Entity *e;
		DeclInfo *d;
	};
	Array<Delay> delayed_const; array_init(&delayed_const, c->tmp_allocator, stmts.count);
	Array<Delay> delayed_type;  array_init(&delayed_type,  c->tmp_allocator, stmts.count);

	for_array(i, stmts) {
		AstNode *node = stmts[i];
		switch (node->kind) {
		case_ast_node(cd, ConstDecl, node);
			for_array(i, cd->values) {
				AstNode *name = cd->names[i];
				AstNode *value = cd->values[i];
				ExactValue v = {ExactValue_Invalid};

				Entity *e = make_entity_constant(c->allocator, c->context.scope, name->Ident, NULL, v);
				e->identifier = name;

				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->type_expr = cd->type;
				d->init_expr = value;

				add_entity_and_decl_info(c, name, e, d);

				Delay delay = {e, d};
				array_add(&delayed_const, delay);
			}

			isize lhs_count = cd->names.count;
			isize rhs_count = cd->values.count;

			if (rhs_count == 0 && cd->type == NULL) {
				error(ast_node_token(node), "Missing type or initial expression");
			} else if (lhs_count < rhs_count) {
				error(ast_node_token(node), "Extra initial expression");
			}
		case_end;

		case_ast_node(td, TypeDecl, node);
			Entity *e = make_entity_type_name(c->allocator, c->context.scope, td->name->Ident, NULL);
			e->identifier = td->name;

			DeclInfo *d = make_declaration_info(c->allocator, e->scope);
			d->type_expr = td->type;

			add_entity_and_decl_info(c, td->name, e, d);

			Delay delay = {e, d};
			array_add(&delayed_type, delay);
		case_end;
		}
	}

	for_array(i, delayed_type) {
		check_entity_decl(c, delayed_type[i].e, delayed_type[i].d, NULL);
	}
	for_array(i, delayed_const) {
		check_entity_decl(c, delayed_const[i].e, delayed_const[i].d, NULL);
	}

	b32 ft_ok = (flags & Stmt_FallthroughAllowed) != 0;
	u32 f = flags & (~Stmt_FallthroughAllowed);

	for_array(i, stmts) {
		AstNode *n = stmts[i];
		if (n->kind == AstNode_EmptyStmt) {
			continue;
		}
		u32 new_flags = f;
		if (ft_ok && i+1 == stmts.count) {
			new_flags |= Stmt_FallthroughAllowed;
		}
		check_stmt(c, n, new_flags);
	}
}

b32 check_is_terminating(AstNode *node);
b32 check_has_break(AstNode *stmt, b32 implicit);

b32 check_is_terminating_list(AstNodeArray stmts) {

	// Iterate backwards
	for (isize n = stmts.count-1; n >= 0; n--) {
		AstNode *stmt = stmts[n];
		if (stmt->kind != AstNode_EmptyStmt) {
			return check_is_terminating(stmt);
		}
	}

	return false;
}

b32 check_has_break_list(AstNodeArray stmts, b32 implicit) {
	for_array(i, stmts) {
		AstNode *stmt = stmts[i];
		if (check_has_break(stmt, implicit)) {
			return true;
		}
	}
	return false;
}


b32 check_has_break(AstNode *stmt, b32 implicit) {
	switch (stmt->kind) {
	case AstNode_BranchStmt:
		if (stmt->BranchStmt.token.kind == Token_break) {
			return implicit;
		}
		break;
	case AstNode_BlockStmt:
		return check_has_break_list(stmt->BlockStmt.stmts, implicit);

	case AstNode_IfStmt:
		if (check_has_break(stmt->IfStmt.body, implicit) ||
		    (stmt->IfStmt.else_stmt != NULL && check_has_break(stmt->IfStmt.else_stmt, implicit))) {
			return true;
		}
		break;

	case AstNode_CaseClause:
		return check_has_break_list(stmt->CaseClause.stmts, implicit);
	}

	return false;
}



// NOTE(bill): The last expression has to be a `return` statement
// TODO(bill): This is a mild hack and should be probably handled properly
// TODO(bill): Warn/err against code after `return` that it won't be executed
b32 check_is_terminating(AstNode *node) {
	switch (node->kind) {
	case_ast_node(rs, ReturnStmt, node);
		return true;
	case_end;

	case_ast_node(bs, BlockStmt, node);
		return check_is_terminating_list(bs->stmts);
	case_end;

	case_ast_node(es, ExprStmt, node);
		return check_is_terminating(es->expr);
	case_end;

	case_ast_node(is, IfStmt, node);
		if (is->else_stmt != NULL) {
			if (check_is_terminating(is->body) &&
			    check_is_terminating(is->else_stmt)) {
			    return true;
		    }
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		if (fs->cond == NULL && !check_has_break(fs->body, true)) {
			return true;
		}
	case_end;

	case_ast_node(ms, MatchStmt, node);
		b32 has_default = false;
		for_array(i, ms->body->BlockStmt.stmts) {
			AstNode *clause = ms->body->BlockStmt.stmts[i];
			ast_node(cc, CaseClause, clause);
			if (cc->list.count == 0) {
				has_default = true;
			}
			if (!check_is_terminating_list(cc->stmts) ||
			    check_has_break_list(cc->stmts, true)) {
				return false;
			}
		}
		return has_default;
	case_end;

	case_ast_node(ms, TypeMatchStmt, node);
		b32 has_default = false;
		for_array(i, ms->body->BlockStmt.stmts) {
			AstNode *clause = ms->body->BlockStmt.stmts[i];
			ast_node(cc, CaseClause, clause);
			if (cc->list.count == 0) {
				has_default = true;
			}
			if (!check_is_terminating_list(cc->stmts) ||
			    check_has_break_list(cc->stmts, true)) {
				return false;
			}
		}
		return has_default;
	case_end;

	case_ast_node(pa, PushAllocator, node);
		return check_is_terminating(pa->body);
	case_end;
	case_ast_node(pc, PushContext, node);
		return check_is_terminating(pc->body);
	case_end;
	}

	return false;
}

Type *check_assignment_variable(Checker *c, Operand *op_a, AstNode *lhs) {
	if (op_a->mode == Addressing_Invalid ||
	    op_a->type == t_invalid) {
		return NULL;
	}

	AstNode *node = unparen_expr(lhs);

	// NOTE(bill): Ignore assignments to `_`
	if (node->kind == AstNode_Ident &&
	    node->Ident.string == "_") {
		add_entity_definition(&c->info, node, NULL);
		check_assignment(c, op_a, NULL, make_string("assignment to `_` identifier"));
		if (op_a->mode == Addressing_Invalid)
			return NULL;
		return op_a->type;
	}

	Entity *e = NULL;
	b32 used = false;
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		e = scope_lookup_entity(c->context.scope, i->string);
		if (e != NULL && e->kind == Entity_Variable) {
			used = e->Variable.used; // TODO(bill): Make backup just in case
		}
	}


	Operand op_b = {Addressing_Invalid};
	check_expr(c, &op_b, lhs);
	if (e) e->Variable.used = used;

	if (op_b.mode == Addressing_Invalid ||
	    op_b.type == t_invalid) {
		return NULL;
	}

	switch (op_b.mode) {
	case Addressing_Variable:
		break;
	case Addressing_Invalid:
		return NULL;
	default: {
		if (op_b.expr->kind == AstNode_SelectorExpr) {
			// NOTE(bill): Extra error checks
			Operand op_c = {Addressing_Invalid};
			ast_node(se, SelectorExpr, op_b.expr);
			check_expr(c, &op_c, se->expr);
		}

		gbString str = expr_to_string(op_b.expr);
		defer (gb_string_free(str));
		error(ast_node_token(op_b.expr), "Cannot assign to `%s`", str);
	} break;
	}

	check_assignment(c, op_a, op_b.type, make_string("assignment"));
	if (op_a->mode == Addressing_Invalid)
		return NULL;

	return op_a->type;
}

// NOTE(bill): `content_name` is for debugging
Type *check_init_variable(Checker *c, Entity *e, Operand *operand, String context_name) {
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
			if (!e->Variable.anonymous)
				continue;
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
	ast_node(bs, BlockStmt, body);
	// TODO(bill): Check declarations first (except mutable variable declarations)
	check_stmt_list(c, bs->stmts, 0);
	if (type->Proc.result_count > 0) {
		if (!check_is_terminating(body)) {
			error(bs->close, "Missing return statement at the end of the procedure");
		}
	}
	pop_procedure(c);


	check_scope_usage(c, c->context.scope);
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



void check_entity_decl(Checker *c, Entity *e, DeclInfo *d, Type *named_type, CycleChecker *cycle_checker) {
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



void check_stmt(Checker *c, AstNode *node, u32 flags) {
	u32 prev_stmt_state_flags = c->context.stmt_state_flags;
	defer (c->context.stmt_state_flags = prev_stmt_state_flags);

	if (node->stmt_state_flags != 0) {
		u32 in = node->stmt_state_flags;
		u32 out = c->context.stmt_state_flags;
		defer (c->context.stmt_state_flags = out);

		if (in & StmtStateFlag_bounds_check) {
			out |= StmtStateFlag_bounds_check;
			out &= ~StmtStateFlag_no_bounds_check;
		} else if (in & StmtStateFlag_no_bounds_check) {
			out |= StmtStateFlag_no_bounds_check;
			out &= ~StmtStateFlag_bounds_check;
		}
	}


	u32 mod_flags = flags & (~Stmt_FallthroughAllowed);
	switch (node->kind) {
	case_ast_node(_, EmptyStmt, node); case_end;
	case_ast_node(_, BadStmt,   node); case_end;
	case_ast_node(_, BadDecl,   node); case_end;

	case_ast_node(es, ExprStmt, node)
		Operand operand = {Addressing_Invalid};
		ExprKind kind = check_expr_base(c, &operand, es->expr);
		switch (operand.mode) {
		case Addressing_Type:
			error(ast_node_token(node), "Is not an expression");
			break;
		case Addressing_NoValue:
			return;
		default: {
			gbString expr_str = expr_to_string(operand.expr);
			defer (gb_string_free(expr_str));
			if (kind == Expr_Stmt) {
				return;
			}
			if (operand.expr->kind == AstNode_CallExpr) {
				return;
			}

			error(ast_node_token(node), "Expression is not used: `%s`", expr_str);
		} break;
		}
	case_end;

	case_ast_node(ts, TagStmt, node);
		// TODO(bill): Tag Statements
		error(ast_node_token(node), "Tag statements are not supported yet");
		check_stmt(c, ts->stmt, flags);
	case_end;

	case_ast_node(ids, IncDecStmt, node);
		Token op = ids->op;
		switch (ids->op.kind) {
		case Token_Increment:
			op.kind = Token_Add;
			op.string.len = 1;
			break;
		case Token_Decrement:
			op.kind = Token_Sub;
			op.string.len = 1;
			break;
		default:
			error(ids->op, "Unknown inc/dec operation %.*s", LIT(ids->op.string));
			return;
		}

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, ids->expr);
		if (operand.mode == Addressing_Invalid)
			return;
		if (!is_type_numeric(operand.type)) {
			error(ids->op, "Non numeric type");
			return;
		}

		AstNode basic_lit = {AstNode_BasicLit};
		ast_node(bl, BasicLit, &basic_lit);
		*bl = ids->op;
		bl->kind = Token_Integer;
		bl->string = make_string("1");

		AstNode binary_expr = {AstNode_BinaryExpr};
		ast_node(be, BinaryExpr, &binary_expr);
		be->op = op;
		be->left = ids->expr;
		be->right = &basic_lit;
		check_binary_expr(c, &operand, &binary_expr);
	case_end;

	case_ast_node(as, AssignStmt, node);
		switch (as->op.kind) {
		case Token_Eq: {
			// a, b, c = 1, 2, 3;  // Multisided
			if (as->lhs.count == 0) {
				error(as->op, "Missing lhs in assignment statement");
				return;
			}

			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
			// an extra allocation
			Array<Operand> operands;
			array_init(&operands, c->tmp_allocator, 2 * as->lhs.count);

			for_array(i, as->rhs) {
				AstNode *rhs = as->rhs[i];
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

			isize lhs_count = as->lhs.count;
			isize rhs_count = operands.count;

			isize operand_index = 0;
			for_array(i, as->lhs) {
				AstNode *lhs = as->lhs[i];
				check_assignment_variable(c, &operands[i], lhs);
			}
			if (lhs_count != rhs_count) {
				error(ast_node_token(as->lhs[0]), "Assignment count mismatch `%td` = `%td`", lhs_count, rhs_count);
			}
		} break;

		default: {
			// a += 1; // Single-sided
			Token op = as->op;
			if (as->lhs.count != 1 || as->rhs.count != 1) {
				error(op, "Assignment operation `%.*s` requires single-valued expressions", LIT(op.string));
				return;
			}
			if (!gb_is_between(op.kind, Token__AssignOpBegin+1, Token__AssignOpEnd-1)) {
				error(op, "Unknown Assignment operation `%.*s`", LIT(op.string));
				return;
			}
			// TODO(bill): Check if valid assignment operator
			Operand operand = {Addressing_Invalid};
			AstNode binary_expr = {AstNode_BinaryExpr};
			ast_node(be, BinaryExpr, &binary_expr);
			be->op    = op;
			 // NOTE(bill): Only use the first one will be used
			be->left  = as->lhs[0];
			be->right = as->rhs[0];

			check_binary_expr(c, &operand, &binary_expr);
			if (operand.mode == Addressing_Invalid)
				return;
			// NOTE(bill): Only use the first one will be used
			check_assignment_variable(c, &operand, as->lhs[0]);
		} break;
		}
	case_end;

	case_ast_node(bs, BlockStmt, node);
		check_open_scope(c, node);
		check_stmt_list(c, bs->stmts, mod_flags);
		check_close_scope(c);
	case_end;

	case_ast_node(is, IfStmt, node);
		check_open_scope(c, node);
		defer (check_close_scope(c));

		if (is->init != NULL)
			check_stmt(c, is->init, 0);

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, is->cond);
		if (operand.mode != Addressing_Invalid &&
		    !is_type_boolean(operand.type)) {
			error(ast_node_token(is->cond),
			            "Non-boolean condition in `if` statement");
		}

		check_stmt(c, is->body, mod_flags);

		if (is->else_stmt) {
			switch (is->else_stmt->kind) {
			case AstNode_IfStmt:
			case AstNode_BlockStmt:
				check_stmt(c, is->else_stmt, mod_flags);
				break;
			default:
				error(ast_node_token(is->else_stmt),
				            "Invalid `else` statement in `if` statement");
				break;
			}
		}
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		GB_ASSERT(c->proc_stack.count > 0);

		if (c->in_defer) {
			error(rs->token, "You cannot `return` within a defer statement");
			// TODO(bill): Should I break here?
			break;
		}


		Type *proc_type = c->proc_stack[c->proc_stack.count-1];
		isize result_count = 0;
		if (proc_type->Proc.results) {
			result_count = proc_type->Proc.results->Tuple.variable_count;
		}

		if (result_count > 0) {
			Entity **variables = NULL;
			if (proc_type->Proc.results != NULL) {
				auto *tuple = &proc_type->Proc.results->Tuple;
				variables = tuple->variables;
			}
			if (rs->results.count == 0) {
				error(ast_node_token(node), "Expected %td return values, got 0", result_count);
			} else {
				check_init_variables(c, variables, result_count,
				                     rs->results, make_string("return statement"));
			}
		} else if (rs->results.count > 0) {
			error(ast_node_token(rs->results[0]), "No return values expected");
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;
		check_open_scope(c, node);
		defer (check_close_scope(c));

		if (fs->init != NULL)
			check_stmt(c, fs->init, 0);
		if (fs->cond) {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, fs->cond);
			if (operand.mode != Addressing_Invalid &&
			    !is_type_boolean(operand.type)) {
				error(ast_node_token(fs->cond),
				      "Non-boolean condition in `for` statement");
			}
		}
		if (fs->post != NULL)
			check_stmt(c, fs->post, 0);
		check_stmt(c, fs->body, new_flags);
	case_end;

	case_ast_node(ms, MatchStmt, node);
		Operand x = {};

		mod_flags |= Stmt_BreakAllowed;
		check_open_scope(c, node);
		defer (check_close_scope(c));

		if (ms->init != NULL) {
			check_stmt(c, ms->init, 0);
		}
		if (ms->tag != NULL) {
			check_expr(c, &x, ms->tag);
			check_assignment(c, &x, NULL, make_string("match expression"));
		} else {
			x.mode  = Addressing_Constant;
			x.type  = t_bool;
			x.value = make_exact_value_bool(true);

			Token token = {};
			token.pos = ast_node_token(ms->body).pos;
			token.string = make_string("true");
			x.expr  = make_ident(c->curr_ast_file, token);
		}

		// NOTE(bill): Check for multiple defaults
		AstNode *first_default = NULL;
		ast_node(bs, BlockStmt, ms->body);
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			AstNode *default_stmt = NULL;
			if (stmt->kind == AstNode_CaseClause) {
				ast_node(cc, CaseClause, stmt);
				if (cc->list.count == 0) {
					default_stmt = stmt;
				}
			} else {
				error(ast_node_token(stmt), "Invalid AST - expected case clause");
			}

			if (default_stmt != NULL) {
				if (first_default != NULL) {
					TokenPos pos = ast_node_token(first_default).pos;
					error(ast_node_token(stmt),
					      "multiple `default` clauses\n"
					      "\tfirst at %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
				} else {
					first_default = default_stmt;
				}
			}
		}


		struct TypeAndToken {
			Type *type;
			Token token;
		};

		Map<TypeAndToken> seen = {}; // Multimap
		map_init(&seen, gb_heap_allocator());
		defer (map_destroy(&seen));
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			if (stmt->kind != AstNode_CaseClause) {
				// NOTE(bill): error handled by above multiple default checker
				continue;
			}
			ast_node(cc, CaseClause, stmt);


			for_array(j, cc->list) {
				AstNode *expr = cc->list[j];
				Operand y = {};
				Operand z = {};
				Token eq = {Token_CmpEq};

				check_expr(c, &y, expr);
				if (x.mode == Addressing_Invalid ||
				    y.mode == Addressing_Invalid) {
					continue;
				}
				convert_to_typed(c, &y, x.type);
				if (y.mode == Addressing_Invalid) {
					continue;
				}

				z = y;
				check_comparison(c, &z, &x, eq);
				if (z.mode == Addressing_Invalid) {
					continue;
				}
				if (y.mode != Addressing_Constant) {
					continue;
				}

				if (y.value.kind != ExactValue_Invalid) {
					HashKey key = hash_exact_value(y.value);
					auto *found = map_get(&seen, key);
					if (found != NULL) {
						gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
						defer (gb_temp_arena_memory_end(tmp));

						isize count = multi_map_count(&seen, key);
						TypeAndToken *taps = gb_alloc_array(c->tmp_allocator, TypeAndToken, count);

						multi_map_get_all(&seen, key, taps);
						b32 continue_outer = false;

						for (isize i = 0; i < count; i++) {
							TypeAndToken tap = taps[i];
							if (are_types_identical(y.type, tap.type)) {
								TokenPos pos = tap.token.pos;
								gbString expr_str = expr_to_string(y.expr);
								error(ast_node_token(y.expr),
								      "Duplicate case `%s`\n"
								      "\tprevious case at %.*s(%td:%td)",
								      expr_str,
								      LIT(pos.file), pos.line, pos.column);
								gb_string_free(expr_str);
								continue_outer = true;
								break;
							}
						}

						if (continue_outer) {
							continue;
						}
					}
					TypeAndToken tap = {y.type, ast_node_token(y.expr)};
					multi_map_insert(&seen, key, tap);
				}
			}

			check_open_scope(c, stmt);
			u32 ft_flags = mod_flags;
			if (i+1 < bs->stmts.count) {
				ft_flags |= Stmt_FallthroughAllowed;
			}
			check_stmt_list(c, cc->stmts, ft_flags);
			check_close_scope(c);
		}
	case_end;

	case_ast_node(ms, TypeMatchStmt, node);
		Operand x = {};

		mod_flags |= Stmt_BreakAllowed;
		check_open_scope(c, node);
		defer (check_close_scope(c));


		check_expr(c, &x, ms->tag);
		check_assignment(c, &x, NULL, make_string("type match expression"));
		if (!is_type_pointer(x.type) || !is_type_union(type_deref(x.type))) {
			gbString str = type_to_string(x.type);
			defer (gb_string_free(str));
			error(ast_node_token(x.expr),
			      "Expected a pointer to a union for this type match expression, got `%s`", str);
			break;
		}
		Type *base_union = base_type(type_deref(x.type));


		// NOTE(bill): Check for multiple defaults
		AstNode *first_default = NULL;
		ast_node(bs, BlockStmt, ms->body);
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			AstNode *default_stmt = NULL;
			if (stmt->kind == AstNode_CaseClause) {
				ast_node(cc, CaseClause, stmt);
				if (cc->list.count == 0) {
					default_stmt = stmt;
				}
			} else {
				error(ast_node_token(stmt), "Invalid AST - expected case clause");
			}

			if (default_stmt != NULL) {
				if (first_default != NULL) {
					TokenPos pos = ast_node_token(first_default).pos;
					error(ast_node_token(stmt),
					      "multiple `default` clauses\n"
					      "\tfirst at %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
				} else {
					first_default = default_stmt;
				}
			}
		}

		if (ms->var->kind != AstNode_Ident) {
			break;
		}


		Map<b32> seen = {};
		map_init(&seen, gb_heap_allocator());
		defer (map_destroy(&seen));


		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			if (stmt->kind != AstNode_CaseClause) {
				// NOTE(bill): error handled by above multiple default checker
				continue;
			}
			ast_node(cc, CaseClause, stmt);

			AstNode *type_expr = cc->list.count > 0 ? cc->list[0] : NULL;
			Type *tag_type = NULL;
			if (type_expr != NULL) { // Otherwise it's a default expression
				Operand y = {};
				check_expr_or_type(c, &y, type_expr);
				b32 tag_type_found = false;
				for (isize i = 0; i < base_union->Record.field_count; i++) {
					Entity *f = base_union->Record.fields[i];
					if (are_types_identical(f->type, y.type)) {
						tag_type_found = true;
						break;
					}
				}
				if (!tag_type_found) {
					gbString type_str = type_to_string(y.type);
					defer (gb_string_free(type_str));
					error(ast_node_token(y.expr),
					      "Unknown tag type, got `%s`", type_str);
					continue;
				}
				tag_type = y.type;

				HashKey key = hash_pointer(y.type);
				auto *found = map_get(&seen, key);
				if (found) {
					TokenPos pos = cc->token.pos;
					gbString expr_str = expr_to_string(y.expr);
					error(ast_node_token(y.expr),
					      "Duplicate type case `%s`\n"
					      "\tprevious type case at %.*s(%td:%td)",
					      expr_str,
					      LIT(pos.file), pos.line, pos.column);
					gb_string_free(expr_str);
					break;
				}
				map_set(&seen, key, cast(b32)true);

			}

			check_open_scope(c, stmt);
			if (tag_type != NULL) {
				// NOTE(bill): Dummy type
				Type *tag_ptr_type = make_type_pointer(c->allocator, tag_type);
				Entity *tag_var = make_entity_variable(c->allocator, c->context.scope, ms->var->Ident, tag_ptr_type);
				tag_var->Variable.used = true;
				add_entity(c, c->context.scope, ms->var, tag_var);
				add_entity_use(c, ms->var, tag_var);
			}
			check_stmt_list(c, cc->stmts, mod_flags);
			check_close_scope(c);
		}
	case_end;


	case_ast_node(ds, DeferStmt, node);
		if (is_ast_node_decl(ds->stmt)) {
			error(ds->token, "You cannot defer a declaration");
		} else {
			b32 out_in_defer = c->in_defer;
			c->in_defer = true;
			check_stmt(c, ds->stmt, 0);
			c->in_defer = out_in_defer;
		}
	case_end;

	case_ast_node(bs, BranchStmt, node);
		Token token = bs->token;
		switch (token.kind) {
		case Token_break:
			if ((flags & Stmt_BreakAllowed) == 0)
				error(token, "`break` only allowed in `for` or `match` statements");
			break;
		case Token_continue:
			if ((flags & Stmt_ContinueAllowed) == 0)
				error(token, "`continue` only allowed in `for` statements");
			break;
		case Token_fallthrough:
			if ((flags & Stmt_FallthroughAllowed) == 0)
				error(token, "`fallthrough` statement in illegal position");
			break;
		default:
			error(token, "Invalid AST: Branch Statement `%.*s`", LIT(token.string));
			break;
		}
	case_end;

	case_ast_node(us, UsingStmt, node);
		switch (us->node->kind) {
		case_ast_node(es, ExprStmt, us->node);
			// TODO(bill): Allow for just a LHS expression list rather than this silly code
			Entity *e = NULL;

			b32 is_selector = false;
			AstNode *expr = unparen_expr(es->expr);
			if (expr->kind == AstNode_Ident) {
				String name = expr->Ident.string;
				e = scope_lookup_entity(c->context.scope, name);
			} else if (expr->kind == AstNode_SelectorExpr) {
				Operand o = {};
				check_expr_base(c, &o, expr->SelectorExpr.expr);
				e = check_selector(c, &o, expr);
				is_selector = true;
			}

			if (e == NULL) {
				error(us->token, "`using` applied to an unknown entity");
				return;
			}

			gbString expr_str = expr_to_string(expr);
			defer (gb_string_free(expr_str));

			switch (e->kind) {
			case Entity_TypeName: {
				Type *t = base_type(e->type);
				if (is_type_struct(t) || is_type_enum(t)) {
					for (isize i = 0; i < t->Record.other_field_count; i++) {
						Entity *f = t->Record.other_fields[i];
						Entity *found = scope_insert_entity(c->context.scope, f);
						if (found != NULL) {
							error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(found->token.string));
							return;
						}
						f->using_parent = e;
					}
				} else if (is_type_union(t)) {
					for (isize i = 0; i < t->Record.field_count; i++) {
						Entity *f = t->Record.fields[i];
						Entity *found = scope_insert_entity(c->context.scope, f);
						if (found != NULL) {
							error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(found->token.string));
							return;
						}
						f->using_parent = e;
					}
					for (isize i = 0; i < t->Record.other_field_count; i++) {
						Entity *f = t->Record.other_fields[i];
						Entity *found = scope_insert_entity(c->context.scope, f);
						if (found != NULL) {
							error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(found->token.string));
							return;
						}
						f->using_parent = e;
					}
				}
			} break;

			case Entity_ImportName: {
				Scope *scope = e->ImportName.scope;
				for_array(i, scope->elements.entries) {
					Entity *decl = scope->elements.entries[i].value;
					Entity *found = scope_insert_entity(c->context.scope, decl);
					if (found != NULL) {
						error(us->token,
						      "Namespace collision while `using` `%s` of: %.*s\n"
						      "\tat %.*s(%td:%td)\n"
						      "\tat %.*s(%td:%td)",
						      expr_str, LIT(found->token.string),
						      LIT(found->token.pos.file), found->token.pos.line, found->token.pos.column,
						      LIT(decl->token.pos.file), decl->token.pos.line, decl->token.pos.column
						      );
						return;
					}
				}
			} break;

			case Entity_Constant:
				error(us->token, "`using` cannot be applied to a constant");
				break;

			case Entity_Procedure:
			case Entity_Builtin:
				error(us->token, "`using` cannot be applied to a procedure");
				break;

			case Entity_Variable: {
				Type *t = base_type(type_deref(e->type));
				if (is_type_struct(t) || is_type_raw_union(t)) {
					Scope **found = map_get(&c->info.scopes, hash_pointer(t->Record.node));
					GB_ASSERT(found != NULL);
					for_array(i, (*found)->elements.entries) {
						Entity *f = (*found)->elements.entries[i].value;
						if (f->kind == Entity_Variable) {
							Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
							if (is_selector) {
								uvar->using_expr = expr;
							}
							Entity *prev = scope_insert_entity(c->context.scope, uvar);
							if (prev != NULL) {
								error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(prev->token.string));
								return;
							}
						}
					}
				} else {
					error(us->token, "`using` can only be applied to variables of type struct or raw_union");
					return;
				}
			} break;

			default:
				GB_PANIC("TODO(bill): using other expressions?");
			}
		case_end;

		case_ast_node(vd, VarDecl, us->node);
			if (vd->names.count > 1 && vd->type != NULL) {
				error(us->token, "`using` can only be applied to one variable of the same type");
			}
			check_var_decl_node(c, us->node);

			for_array(name_index, vd->names) {
				AstNode *item = vd->names[name_index];
				ast_node(i, Ident, item);
				String name = i->string;
				Entity *e = scope_lookup_entity(c->context.scope, name);
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
								error(us->token, "Namespace collision while `using` `%.*s` of: %.*s", LIT(name), LIT(prev->token.string));
								return;
							}
						}
					}
				} else {
					error(us->token, "`using` can only be applied to variables of type struct or raw_union");
					return;
				}
			}
		case_end;


		default:
			error(us->token, "Invalid AST: Using Statement");
			break;
		}
	case_end;



	case_ast_node(pa, PushAllocator, node);
		Operand op = {};
		check_expr(c, &op, pa->expr);
		check_assignment(c, &op, t_allocator, make_string("argument to push_allocator"));
		check_stmt(c, pa->body, mod_flags);
	case_end;


	case_ast_node(pa, PushContext, node);
		Operand op = {};
		check_expr(c, &op, pa->expr);
		check_assignment(c, &op, t_context, make_string("argument to push_context"));
		check_stmt(c, pa->body, mod_flags);
	case_end;






	case_ast_node(vd, VarDecl, node);
		check_var_decl_node(c, node);
	case_end;

	case_ast_node(cd, ConstDecl, node);
		// NOTE(bill): Handled elsewhere
	case_end;

	case_ast_node(td, TypeDecl, node);
		// NOTE(bill): Handled elsewhere
	case_end;

	case_ast_node(pd, ProcDecl, node);
		// NOTE(bill): This must be handled here so it has access to the parent scope stuff
		// e.g. using
		Entity *e = make_entity_procedure(c->allocator, c->context.scope, pd->name->Ident, NULL);
		e->identifier = pd->name;

		DeclInfo *d = make_declaration_info(c->allocator, e->scope);
		d->proc_decl = node;

		add_entity_and_decl_info(c, pd->name, e, d);
		check_entity_decl(c, e, d, NULL);
	case_end;


	}
}
