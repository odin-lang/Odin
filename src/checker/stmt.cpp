// Statements and Declarations

enum StatementFlag : u32 {
	Statement_BreakAllowed       = GB_BIT(0),
	Statement_ContinueAllowed    = GB_BIT(1),
	// Statement_FallthroughAllowed = GB_BIT(2), // TODO(bill): fallthrough
};

void check_stmt(Checker *c, AstNode *node, u32 flags);

void check_stmt_list(Checker *c, AstNode *node, u32 flags) {
	for (; node != NULL; node = node->next) {
		if (node->kind != AstNode_EmptyStmt) {
			check_stmt(c, node, flags);
		}
	}
}

b32 check_is_terminating(Checker *c, AstNode *node);

b32 check_is_terminating_list(Checker *c, AstNode *list) {
	// Get to end of list
	for (; list != NULL; list = list->next) {
		if (list->next == NULL)
			break;
	}

	// Iterate backwards
	for (AstNode *n = list; n != NULL; n = n->prev) {
		if (n->kind != AstNode_EmptyStmt)
			return check_is_terminating(c, n);
	}

	return false;
}

// NOTE(bill): The last expression has to be a `return` statement
// TODO(bill): This is a mild hack and should be probably handled properly
// TODO(bill): Warn/err against code after `return` that it won't be executed
b32 check_is_terminating(Checker *c, AstNode *node) {
	switch (node->kind) {
	case_ast_node(rs, ReturnStmt, node);
		return true;
	case_end;

	case_ast_node(bs, BlockStmt, node);
		return check_is_terminating_list(c, bs->list);
	case_end;

	case_ast_node(es, ExprStmt, node);
		return check_is_terminating(c, es->expr);
	case_end;

	case_ast_node(is, IfStmt, node);
		if (is->else_stmt != NULL) {
			if (check_is_terminating(c, is->body) &&
			    check_is_terminating(c, is->else_stmt)) {
			    return true;
		    }
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		if (fs->cond == NULL) {
			return true;
		}
	case_end;
	}

	return false;
}


b32 check_is_assignable_to(Checker *c, Operand *operand, Type *type) {
	if (operand->mode == Addressing_Invalid ||
	    type == t_invalid) {
		return true;
	}

	Type *s = operand->type;

	if (are_types_identical(s, type))
		return true;

	Type *sb = get_base_type(s);
	Type *tb = get_base_type(type);

	if (is_type_untyped(sb)) {
		switch (tb->kind) {
		case Type_Basic:
			if (operand->mode == Addressing_Constant)
				return check_value_is_expressible(c, operand->value, tb, NULL);
			if (sb->kind == Type_Basic)
				return sb->Basic.kind == Basic_UntypedBool && is_type_boolean(tb);
			break;
		case Type_Pointer:
			return sb->Basic.kind == Basic_UntypedPointer;
		}
	}

	if (are_types_identical(sb, tb) && (!is_type_named(sb) || !is_type_named(tb)))
		return true;

	if (is_type_pointer(sb) && is_type_rawptr(tb))
	    return true;

	if (is_type_rawptr(sb) && is_type_pointer(tb))
	    return true;

	if (sb->kind == Type_Array && tb->kind == Type_Array) {
		if (are_types_identical(sb->Array.elem, tb->Array.elem)) {
			return sb->Array.count == tb->Array.count;
		}
	}

	if (sb->kind == Type_Slice && tb->kind == Type_Slice) {
		if (are_types_identical(sb->Slice.elem, tb->Slice.elem)) {
			return true;
		}
	}


	return false;

}


// NOTE(bill): `content_name` is for debugging
// TODO(bill): Maybe allow assignment to tuples?
void check_assignment(Checker *c, Operand *operand, Type *type, String context_name) {
	check_not_tuple(c, operand);
	if (operand->mode == Addressing_Invalid)
		return;

	if (is_type_untyped(operand->type)) {
		Type *target_type = type;

		if (type == NULL)
			target_type = default_type(operand->type);
		convert_to_typed(c, operand, target_type);
		if (operand->mode == Addressing_Invalid)
			return;
	}

	if (type != NULL) {
		if (!check_is_assignable_to(c, operand, type)) {
			gbString type_string = type_to_string(type);
			gbString op_type_string = type_to_string(operand->type);
			gbString expr_str = expr_to_string(operand->expr);
			defer (gb_string_free(type_string));
			defer (gb_string_free(op_type_string));
			defer (gb_string_free(expr_str));


			// TODO(bill): is this a good enough error message?
			error(&c->error_collector, ast_node_token(operand->expr),
			      "Cannot assign value `%s` of type `%s` to `%s` in %.*s",
			      expr_str,
			      op_type_string,
			      type_string,
			      LIT(context_name));

			operand->mode = Addressing_Invalid;
		}
	}
}


Type *check_assignment_variable(Checker *c, Operand *op_a, AstNode *lhs) {
	if (op_a->mode == Addressing_Invalid ||
	    op_a->type == t_invalid) {
		return NULL;
	}

	AstNode *node = unparen_expr(lhs);

	// NOTE(bill): Ignore assignments to `_`
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		if (are_strings_equal(i->token.string, make_string("_"))) {
			add_entity_definition(&c->info, node, NULL);
			check_assignment(c, op_a, NULL, make_string("assignment to `_` identifier"));
			if (op_a->mode == Addressing_Invalid)
				return NULL;
			return op_a->type;
		}
	}

	Entity *e = NULL;
	b32 used = false;
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		e = scope_lookup_entity(c, c->context.scope, i->token.string);
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
		error(&c->error_collector, ast_node_token(op_b.expr), "Cannot assign to `%s`", str);
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
		if (e->type == NULL)
			e->type = t_invalid;
		return NULL;
	}

	if (e->type == NULL) {
		// NOTE(bill): Use the type of the operand
		Type *t = operand->type;
		if (is_type_untyped(t)) {
			if (t == t_invalid) {
				error(&c->error_collector, e->token, "Use of untyped thing in %.*s", LIT(context_name));
				e->type = t_invalid;
				return NULL;
			}
			t = default_type(t);
		}
		e->type = t;
	}

	check_assignment(c, operand, e->type, context_name);
	if (operand->mode == Addressing_Invalid)
		return NULL;

	return e->type;
}

void check_init_variables(Checker *c, Entity **lhs, isize lhs_count, AstNode *init_list, isize init_count, String context_name) {
	if ((lhs == NULL || lhs_count == 0) && init_count == 0)
		return;

	// TODO(bill): Do not use heap allocation here if I can help it
	gbArray(Operand) operands;
	gb_array_init(operands, gb_heap_allocator());
	defer (gb_array_free(operands));

	for (AstNode *rhs = init_list; rhs != NULL; rhs = rhs->next) {
		Operand o = {};
		check_multi_expr(c, &o, rhs);
		if (o.type->kind != Type_Tuple) {
			gb_array_append(operands, o);
		} else {
			auto *tuple = &o.type->Tuple;
			for (isize j = 0; j < tuple->variable_count; j++) {
				o.type = tuple->variables[j]->type;
				gb_array_append(operands, o);
			}
		}
	}

	isize rhs_count = gb_array_count(operands);

	isize max = gb_min(lhs_count, rhs_count);
	for (isize i = 0; i < max; i++) {
		check_init_variable(c, lhs[i], &operands[i], context_name);
	}

	if (rhs_count > 0 && lhs_count != rhs_count) {
		error(&c->error_collector, lhs[0]->token, "Assignment count mismatch `%td` := `%td`", lhs_count, rhs_count);
	}
}

void check_init_constant(Checker *c, Entity *e, Operand *operand) {
	if (operand->mode == Addressing_Invalid ||
	    operand->type == t_invalid ||
	    e->type == t_invalid) {
		if (e->type == NULL)
			e->type = t_invalid;
		return;
	}

	if (operand->mode != Addressing_Constant) {
		// TODO(bill): better error
		error(&c->error_collector, ast_node_token(operand->expr),
		      "`%.*s` is not a constant", LIT(ast_node_token(operand->expr).string));
		if (e->type == NULL)
			e->type = t_invalid;
		return;
	}
	if (!is_type_constant_type(operand->type)) {
		// NOTE(bill): no need to free string as it's panicking
		GB_PANIC("Compiler error: Type `%s` not constant!!!", type_to_string(operand->type));
	}

	if (e->type == NULL) // NOTE(bill): type inference
		e->type = operand->type;

	check_assignment(c, operand, e->type, make_string("constant declaration"));
	if (operand->mode == Addressing_Invalid)
		return;

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
		if (!is_type_constant_type(t)) {
			gbString str = type_to_string(t);
			defer (gb_string_free(str));
			error(&c->error_collector, ast_node_token(type_expr),
			      "Invalid constant type `%s`", str);
			e->type = t_invalid;
			return;
		}
		e->type = t;
	}

	Operand operand = {};
	if (init_expr)
		check_expr(c, &operand, init_expr);
	check_init_constant(c, e, &operand);
}

void check_type_decl(Checker *c, Entity *e, AstNode *type_expr, Type *named_type) {
	GB_ASSERT(e->type == NULL);
	Type *named = make_type_named(c->allocator, e->token.string, NULL, e);
	named->Named.type_name = e;
	set_base_type(named_type, named);
	e->type = named;

	check_type(c, type_expr, named);

	set_base_type(named, get_base_type(get_base_type(named)));
}

void check_proc_body(Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	GB_ASSERT(body->kind == AstNode_BlockStmt);

	CheckerContext old_context = c->context;
	c->context.scope = decl->scope;
	c->context.decl = decl;

	push_procedure(c, type);
	ast_node(bs, BlockStmt, body);
	// TODO(bill): Check declarations first (except mutable variable declarations)
	check_stmt_list(c, bs->list, 0);
	if (type->Proc.result_count > 0) {
		if (!check_is_terminating(c, body)) {
			error(&c->error_collector, bs->close, "Missing return statement at the end of the procedure");
		}
	}
	pop_procedure(c);

	c->context = old_context;
}

void check_proc_decl(Checker *c, Entity *e, DeclInfo *d, b32 check_body_later) {
	GB_ASSERT(e->type == NULL);

	Type *proc_type = make_type_proc(c->allocator, e->scope, NULL, 0, NULL, 0);
	e->type = proc_type;
	ast_node(pd, ProcDecl, d->proc_decl);

	check_open_scope(c, pd->type);
	defer ({
		check_close_scope(c);
	});


	check_procedure_type(c, proc_type, pd->type);
	b32 is_foreign   = (pd->tags & ProcTag_foreign)   != 0;
	b32 is_inline    = (pd->tags & ProcTag_inline)    != 0;
	b32 is_no_inline = (pd->tags & ProcTag_no_inline) != 0;



	if (d->scope == c->global_scope &&
	    are_strings_equal(e->token.string, make_string("main"))) {
		if (proc_type != NULL) {
			auto *pt = &proc_type->Proc;
			if (pt->param_count != 0 ||
			    pt->result_count) {
				gbString str = type_to_string(proc_type);
				defer (gb_string_free(str));

				error(&c->error_collector, e->token,
				      "Procedure type of `main` was expected to be `proc()`, got %s", str);
			}
		}
	}

	if (is_inline && is_no_inline) {
		error(&c->error_collector, ast_node_token(pd->type),
		      "You cannot apply both `inline` and `no_inline` to a procedure");
	}

	if (pd->body != NULL) {
		if (is_foreign) {
			error(&c->error_collector, ast_node_token(pd->body),
			      "A procedure tagged as `#foreign` cannot have a body");
		}

		d->scope = c->context.scope;

		GB_ASSERT(pd->body->kind == AstNode_BlockStmt);
		if (check_body_later) {
			check_procedure_later(c, c->curr_ast_file, e->token, d, proc_type, pd->body);
		} else {
			check_proc_body(c, e->token, d, proc_type, pd->body);
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

	check_init_variables(c, entities, entity_count, init_expr, 1, make_string("variable declaration"));
}



void check_entity_decl(Checker *c, Entity *e, DeclInfo *d, Type *named_type) {
	if (e->type != NULL)
		return;
	switch (e->kind) {
	case Entity_Constant:
		c->context.decl = d;
		check_const_decl(c, e, d->type_expr, d->init_expr);
		break;
	case Entity_Variable:
		c->context.decl = d;
		check_var_decl(c, e, d->entities, d->entity_count, d->type_expr, d->init_expr);
		break;
	case Entity_TypeName:
		check_type_decl(c, e, d->type_expr, named_type);
		break;
	case Entity_Procedure:
		check_proc_decl(c, e, d, true);
		break;
	}

}




void check_stmt(Checker *c, AstNode *node, u32 flags) {
	switch (node->kind) {
	case_ast_node(_, EmptyStmt, node); case_end;
	case_ast_node(_, BadStmt,   node); case_end;
	case_ast_node(_, BadDecl,   node); case_end;

	case_ast_node(es, ExprStmt, node)
		Operand operand = {Addressing_Invalid};
		ExpressionKind kind = check_expr_base(c, &operand, es->expr);
		switch (operand.mode) {
		case Addressing_Type:
			error(&c->error_collector, ast_node_token(node), "Is not an expression");
			break;
		default:
			if (kind == Expression_Statement)
				return;
			error(&c->error_collector, ast_node_token(node), "Expression is not used");
			break;
		}
	case_end;

	case_ast_node(ts, TagStmt, node);
		// TODO(bill): Tag Statements
		error(&c->error_collector, ast_node_token(node), "Tag statements are not supported yet");
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
			error(&c->error_collector, ids->op, "Unknown inc/dec operation %.*s", LIT(ids->op.string));
			return;
		}

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, ids->expr);
		if (operand.mode == Addressing_Invalid)
			return;
		if (!is_type_numeric(operand.type)) {
			error(&c->error_collector, ids->op, "Non numeric type");
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
			if (as->lhs_count == 0) {
				error(&c->error_collector, as->op, "Missing lhs in assignment statement");
				return;
			}

			// TODO(bill): Do not use heap allocation here if I can help it
			gbArray(Operand) operands;
			gb_array_init(operands, gb_heap_allocator());
			defer (gb_array_free(operands));

			for (AstNode *rhs = as->rhs_list; rhs != NULL; rhs = rhs->next) {
				Operand o = {};
				check_multi_expr(c, &o, rhs);
				if (o.type->kind != Type_Tuple) {
					gb_array_append(operands, o);
				} else {
					auto *tuple = &o.type->Tuple;
					for (isize j = 0; j < tuple->variable_count; j++) {
						o.type = tuple->variables[j]->type;
						gb_array_append(operands, o);
					}
				}
			}

			isize lhs_count = as->lhs_count;
			isize rhs_count = gb_array_count(operands);

			isize operand_index = 0;
			for (AstNode *lhs = as->lhs_list;
			     lhs != NULL;
			     lhs = lhs->next, operand_index++) {
				check_assignment_variable(c, &operands[operand_index], lhs);

			}
			if (lhs_count != rhs_count) {
				error(&c->error_collector, ast_node_token(as->lhs_list), "Assignment count mismatch `%td` = `%td`", lhs_count, rhs_count);
			}
		} break;

		default: {
			// a += 1; // Single-sided
			Token op = as->op;
			if (as->lhs_count != 1 || as->rhs_count != 1) {
				error(&c->error_collector, op, "Assignment operation `%.*s` requires single-valued expressions", LIT(op.string));
				return;
			}
			if (!gb_is_between(op.kind, Token__AssignOpBegin+1, Token__AssignOpEnd-1)) {
				error(&c->error_collector, op, "Unknown Assignment operation `%.*s`", LIT(op.string));
				return;
			}
			// TODO(bill): Check if valid assignment operator
			Operand operand = {Addressing_Invalid};
			AstNode binary_expr = {AstNode_BinaryExpr};
			ast_node(be, BinaryExpr, &binary_expr);
			be->op    = op;
			 // NOTE(bill): Only use the first one will be used
			be->left  = as->lhs_list;
			be->right = as->rhs_list;

			check_binary_expr(c, &operand, &binary_expr);
			if (operand.mode == Addressing_Invalid)
				return;
			// NOTE(bill): Only use the first one will be used
			check_assignment_variable(c, &operand, as->lhs_list);
		} break;
		}
	case_end;

	case_ast_node(bs, BlockStmt, node);
		check_open_scope(c, node);
		check_stmt_list(c, bs->list, flags);
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
			error(&c->error_collector, ast_node_token(is->cond),
			            "Non-boolean condition in `if` statement");
		}

		check_stmt(c, is->body, flags);

		if (is->else_stmt) {
			switch (is->else_stmt->kind) {
			case AstNode_IfStmt:
			case AstNode_BlockStmt:
				check_stmt(c, is->else_stmt, flags);
				break;
			default:
				error(&c->error_collector, ast_node_token(is->else_stmt),
				            "Invalid `else` statement in `if` statement");
				break;
			}
		}
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		GB_ASSERT(gb_array_count(c->proc_stack) > 0);

		if (c->in_defer) {
			error(&c->error_collector, rs->token, "You cannot `return` within a defer statement");
			// TODO(bill): Should I break here?
			break;
		}

		Type *proc_type = c->proc_stack[gb_array_count(c->proc_stack)-1];
		isize result_count = 0;
		if (proc_type->Proc.results)
			result_count = proc_type->Proc.results->Tuple.variable_count;
		if (result_count != rs->result_count) {
			error(&c->error_collector, rs->token, "Expected %td return %s, got %td",
			      result_count,
			      (result_count != 1 ? "values" : "value"),
			      rs->result_count);
		} else if (result_count > 0) {
			auto *tuple = &proc_type->Proc.results->Tuple;
			check_init_variables(c, tuple->variables, tuple->variable_count,
			                     rs->result_list, rs->result_count, make_string("return statement"));
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		check_open_scope(c, node);
		defer (check_close_scope(c));

		if (fs->init != NULL)
			check_stmt(c, fs->init, 0);
		if (fs->cond) {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, fs->cond);
			if (operand.mode != Addressing_Invalid &&
			    !is_type_boolean(operand.type)) {
				error(&c->error_collector, ast_node_token(fs->cond),
				      "Non-boolean condition in `for` statement");
			}
		}
		if (fs->post != NULL)
			check_stmt(c, fs->post, 0);
		check_stmt(c, fs->body, flags | Statement_BreakAllowed | Statement_ContinueAllowed);
	case_end;

	case_ast_node(ds, DeferStmt, node);
		if (is_ast_node_decl(ds->stmt)) {
			error(&c->error_collector, ds->token, "You cannot defer a declaration");
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
			if ((flags & Statement_BreakAllowed) == 0)
				error(&c->error_collector, token, "`break` only allowed in `for` statement");
			break;
		case Token_continue:
			if ((flags & Statement_ContinueAllowed) == 0)
				error(&c->error_collector, token, "`continue` only allowed in `for` statement");
			break;
		default:
			error(&c->error_collector, token, "Invalid AST: Branch Statement `%.*s`", LIT(token.string));
			break;
		}
	case_end;

	case_ast_node(vd, VarDecl, node);
		isize entity_count = vd->name_count;
		isize entity_index = 0;
		Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);
		switch (vd->kind) {
		case Declaration_Mutable: {
			Entity **new_entities = gb_alloc_array(c->allocator, Entity *, entity_count);
			isize new_entity_count = 0;

			for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
				Entity *entity = NULL;
				Token token = name->Ident.token;
				if (name->kind == AstNode_Ident) {
					String str = token.string;
					Entity *found = NULL;
					// NOTE(bill): Ignore assignments to `_`
					b32 can_be_ignored = are_strings_equal(str, make_string("_"));
					if (!can_be_ignored) {
						found = current_scope_lookup_entity(c->context.scope, str);
					}
					if (found == NULL) {
						entity = make_entity_variable(c->allocator, c->context.scope, token, NULL);
						if (!can_be_ignored) {
							new_entities[new_entity_count++] = entity;
						}
						add_entity_definition(&c->info, name, entity);
					} else {
						entity = found;
					}
				} else {
					error(&c->error_collector, token, "A variable declaration must be an identifier");
				}
				if (entity == NULL)
					entity = make_entity_dummy_variable(c->allocator, c->global_scope, token);
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

			check_init_variables(c, entities, entity_count, vd->value_list, vd->value_count, make_string("variable declaration"));

			AstNode *name = vd->name_list;
			for (isize i = 0; i < new_entity_count; i++, name = name->next) {
				add_entity(c, c->context.scope, name, new_entities[i]);
			}

		} break;

		case Declaration_Immutable: {
			for (AstNode *name = vd->name_list, *value = vd->value_list;
			     name != NULL && value != NULL;
			     name = name->next, value = value->next) {
				GB_ASSERT(name->kind == AstNode_Ident);
				ExactValue v = {ExactValue_Invalid};
				ast_node(i, Ident, name);
				Entity *e = make_entity_constant(c->allocator, c->context.scope, i->token, NULL, v);
				entities[entity_index++] = e;
				check_const_decl(c, e, vd->type, value);
			}

			isize lhs_count = vd->name_count;
			isize rhs_count = vd->value_count;

			// TODO(bill): Better error messages or is this good enough?
			if (rhs_count == 0 && vd->type == NULL) {
				error(&c->error_collector, ast_node_token(node), "Missing type or initial expression");
			} else if (lhs_count < rhs_count) {
				error(&c->error_collector, ast_node_token(node), "Extra initial expression");
			}

			AstNode *name = vd->name_list;
			for (isize i = 0; i < entity_count; i++, name = name->next) {
				add_entity(c, c->context.scope, name, entities[i]);
			}
		} break;

		default:
			error(&c->error_collector, ast_node_token(node), "Unknown variable declaration kind. Probably an invalid AST.");
			return;
		}
	case_end;

	case_ast_node(pd, ProcDecl, node);
		ast_node(name, Ident, pd->name);
		Entity *e = make_entity_procedure(c->allocator, c->context.scope, name->token, NULL);
		add_entity(c, c->context.scope, pd->name, e);

		DeclInfo decl = {};
		init_declaration_info(&decl, e->scope);
		decl.proc_decl = node;
		check_proc_decl(c, e, &decl, false);
		destroy_declaration_info(&decl);
	case_end;

	case_ast_node(td, TypeDecl, node);
		ast_node(name, Ident, td->name);
		Entity *e = make_entity_type_name(c->allocator, c->context.scope, name->token, NULL);
		add_entity(c, c->context.scope, td->name, e);
		check_type_decl(c, e, td->type, NULL);
	case_end;
	}
}
