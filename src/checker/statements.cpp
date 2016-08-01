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
	case AstNode_ReturnStmt:
		return true;

	case AstNode_BlockStmt:
		return check_is_terminating_list(c, node->block_stmt.list);

	case AstNode_ExprStmt:
		return check_is_terminating(c, node->expr_stmt.expr);

	case AstNode_IfStmt:
		if (node->if_stmt.else_stmt != NULL) {
			if (check_is_terminating(c, node->if_stmt.body) &&
			    check_is_terminating(c, node->if_stmt.else_stmt)) {
			    return true;
		    }
		}
		break;

	case AstNode_ForStmt:
		if (node->for_stmt.cond == NULL) {
			return true;
		}
		break;
	}

	return false;
}


b32 check_is_assignable_to(Checker *c, Operand *operand, Type *type) {
	if (operand->mode == Addressing_Invalid ||
	    type == &basic_types[Basic_Invalid]) {
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
				return sb->basic.kind == Basic_UntypedBool && is_type_boolean(tb);
			break;
		case Type_Pointer:
			return sb->basic.kind == Basic_UntypedPointer;
		}
	}

	if (are_types_identical(sb, tb) && (!is_type_named(sb) || !is_type_named(tb)))
		return true;

	if (is_type_pointer(sb) && is_type_rawptr(tb))
	    return true;

	if (is_type_rawptr(sb) && is_type_pointer(tb))
	    return true;

	if (sb->kind == Type_Array && tb->kind == Type_Array) {
		if (are_types_identical(sb->array.element, tb->array.element)) {
			return sb->array.count == tb->array.count;
		}
	}

	if (sb->kind == Type_Slice && tb->kind == Type_Slice) {
		if (are_types_identical(sb->slice.element, tb->slice.element)) {
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
	    op_a->type == &basic_types[Basic_Invalid]) {
		return NULL;
	}

	AstNode *node = unparen_expr(lhs);

	// NOTE(bill): Ignore assignments to `_`
	if (node->kind == AstNode_Ident &&
	    are_strings_equal(node->ident.token.string, make_string("_"))) {
    	add_entity_definition(&c->info, node, NULL);
    	check_assignment(c, op_a, NULL, make_string("assignment to `_` identifier"));
    	if (op_a->mode == Addressing_Invalid)
    		return NULL;
    	return op_a->type;
    }

	Entity *e = NULL;
	b32 used = false;
	if (node->kind == AstNode_Ident) {
		e = scope_lookup_entity(c->context.scope, node->ident.token.string);
		if (e != NULL && e->kind == Entity_Variable) {
			used = e->variable.used; // TODO(bill): Make backup just in case
		}
	}


	Operand op_b = {Addressing_Invalid};
	check_expr(c, &op_b, lhs);
	if (e) e->variable.used = used;

	if (op_b.mode == Addressing_Invalid ||
	    op_b.type == &basic_types[Basic_Invalid]) {
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
			check_expr(c, &op_c, op_b.expr->selector_expr.expr);
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
	    operand->type == &basic_types[Basic_Invalid] ||
	    e->type == &basic_types[Basic_Invalid]) {
		if (e->type == NULL)
			e->type = &basic_types[Basic_Invalid];
		return NULL;
	}

	if (e->type == NULL) {
		// NOTE(bill): Use the type of the operand
		Type *t = operand->type;
		if (is_type_untyped(t)) {
			if (t == &basic_types[Basic_Invalid]) {
				error(&c->error_collector, e->token, "Use of untyped thing in %.*s", LIT(context_name));
				e->type = &basic_types[Basic_Invalid];
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

	isize i = 0;
	AstNode *rhs = init_list;
	for (;
	     i < lhs_count && i < init_count && rhs != NULL;
	     i++, rhs = rhs->next) {
		Operand operand = {};
		check_multi_expr(c, &operand, rhs);
		if (operand.type->kind != Type_Tuple) {
			check_init_variable(c, lhs[i], &operand, context_name);
		} else {
			auto *tuple = &operand.type->tuple;
			for (isize j = 0;
			     j < tuple->variable_count && i < lhs_count && i < init_count;
			     j++, i++) {
				Type *type = tuple->variables[j]->type;
				operand.type = type;
				check_init_variable(c, lhs[i], &operand, context_name);
			}
		}
	}

	if (i < lhs_count && lhs[i]->type == NULL) {
		error(&c->error_collector, lhs[i]->token, "Too few values on the right hand side of the declaration");
	} else if (rhs != NULL) {
		error(&c->error_collector, ast_node_token(rhs), "Too many values on the right hand side of the declaration");
	}
}

void check_init_constant(Checker *c, Entity *e, Operand *operand) {
	if (operand->mode == Addressing_Invalid ||
	    operand->type == &basic_types[Basic_Invalid] ||
	    e->type == &basic_types[Basic_Invalid]) {
		if (e->type == NULL)
			e->type = &basic_types[Basic_Invalid];
		return;
	}

	if (operand->mode != Addressing_Constant) {
		// TODO(bill): better error
		error(&c->error_collector, ast_node_token(operand->expr),
		      "`%.*s` is not a constant", LIT(ast_node_token(operand->expr).string));
		if (e->type == NULL)
			e->type = &basic_types[Basic_Invalid];
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

	e->constant.value = operand->value;
}


void check_const_decl(Checker *c, Entity *e, AstNode *type_expr, AstNode *init_expr) {
	GB_ASSERT(e->type == NULL);

	if (e->variable.visited) {
		e->type = &basic_types[Basic_Invalid];
		return;
	}
	e->variable.visited = true;

	if (type_expr) {
		Type *t = check_type(c, type_expr);
		if (!is_type_constant_type(t)) {
			gbString str = type_to_string(t);
			defer (gb_string_free(str));
			error(&c->error_collector, ast_node_token(type_expr),
			      "Invalid constant type `%s`", str);
			e->type = &basic_types[Basic_Invalid];
			return;
		}
		e->type = t;
	}

	Operand operand = {Addressing_Invalid};
	if (init_expr)
		check_expr(c, &operand, init_expr);
	check_init_constant(c, e, &operand);
}

void check_type_decl(Checker *c, Entity *e, AstNode *type_expr, Type *named_type) {
	GB_ASSERT(e->type == NULL);
	Type *named = make_type_named(c->allocator, e->token.string, NULL, e);
	named->named.type_name = e;
	set_base_type(named_type, named);
	e->type = named;

	check_type(c, type_expr, named);

	set_base_type(named, get_base_type(get_base_type(named)));
}

void check_alias_decl(Checker *c, Entity *e, AstNode *type_expr, Type *alias_type) {
	GB_ASSERT(e->type == NULL);
	Type *named = make_type_alias(c->allocator, e->token.string, NULL, e);
	named->alias.alias_name = e;
	set_base_type(alias_type, named);
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
	check_stmt_list(c, body->block_stmt.list, 0);
	if (type->procedure.result_count > 0) {
		if (!check_is_terminating(c, body)) {
			error(&c->error_collector, body->block_stmt.close, "Missing return statement at the end of the procedure");
		}
	}
	pop_procedure(c);

	c->context = old_context;
}

void check_proc_decl(Checker *c, Entity *e, DeclInfo *d, b32 check_body_later) {
	GB_ASSERT(e->type == NULL);

	Type *proc_type = make_type_procedure(c->allocator, e->parent, NULL, 0, NULL, 0);
	e->type = proc_type;
	auto *pd = &d->proc_decl->proc_decl;

#if 1
	Scope *original_curr_scope = c->context.scope;
	c->context.scope = c->global_scope;
	check_open_scope(c, pd->type);
#endif
	check_procedure_type(c, proc_type, pd->type);
	b32 is_foreign   = false;
	b32 is_inline    = false;
	b32 is_no_inline = false;
	for (AstNode *tag = pd->tag_list; tag != NULL; tag = tag->next) {
		GB_ASSERT(tag->kind == AstNode_TagExpr);

		String tag_name = tag->tag_expr.name.string;
		if (are_strings_equal(tag_name, make_string("foreign"))) {
			is_foreign = true;
		} else if (are_strings_equal(tag_name, make_string("inline"))) {
			is_inline = true;
		} else if (are_strings_equal(tag_name, make_string("no_inline"))) {
			is_no_inline = true;
		} else {
			error(&c->error_collector, ast_node_token(tag), "Unknown procedure tag");
		}
		// TODO(bill): Other tags
	}

	if (is_inline && is_no_inline) {
		error(&c->error_collector, ast_node_token(pd->tag_list),
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

#if 1
	check_close_scope(c);
	c->context.scope = original_curr_scope;
#endif

}

void check_var_decl(Checker *c, Entity *e, Entity **entities, isize entity_count, AstNode *type_expr, AstNode *init_expr) {
	GB_ASSERT(e->type == NULL);
	GB_ASSERT(e->kind == Entity_Variable);

	if (e->variable.visited) {
		e->type = &basic_types[Basic_Invalid];
		return;
	}
	e->variable.visited = true;

	if (type_expr != NULL)
		e->type = check_type(c, type_expr, NULL);

	if (init_expr == NULL) {
		if (type_expr == NULL)
			e->type = &basic_types[Basic_Invalid];
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
	case Entity_AliasName:
		check_alias_decl(c, e, d->type_expr, named_type);
		break;
	case Entity_Procedure:
		check_proc_decl(c, e, d, true);
		break;
	}

}




void check_stmt(Checker *c, AstNode *node, u32 flags) {
	switch (node->kind) {
	case AstNode_EmptyStmt: break;
	case AstNode_BadStmt:   break;
	case AstNode_BadDecl: break;

	case AstNode_ExprStmt: {
		Operand operand = {Addressing_Invalid};
		ExpressionKind kind = check_expr_base(c, &operand, node->expr_stmt.expr);
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
	} break;

	case AstNode_TagStmt:
		// TODO(bill): Tag Statements
		error(&c->error_collector, ast_node_token(node), "Tag statements are not supported yet");
		check_stmt(c, node->tag_stmt.stmt, flags);
		break;

	case AstNode_IncDecStmt: {
		Token op = {};
		auto *s = &node->inc_dec_stmt;
		op = s->op;
		switch (s->op.kind) {
		case Token_Increment:
			op.kind = Token_Add;
			op.string.len = 1;
			break;
		case Token_Decrement:
			op.kind = Token_Sub;
			op.string.len = 1;
			break;
		default:
			error(&c->error_collector, s->op, "Unknown inc/dec operation %.*s", LIT(s->op.string));
			return;
		}

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, s->expr);
		if (operand.mode == Addressing_Invalid)
			return;
		if (!is_type_numeric(operand.type)) {
			error(&c->error_collector, s->op, "Non numeric type");
			return;
		}

		AstNode basic_lit = {AstNode_BasicLit};
		basic_lit.basic_lit = s->op;
		basic_lit.basic_lit.kind = Token_Integer;
		basic_lit.basic_lit.string = make_string("1");

		AstNode be = {AstNode_BinaryExpr};
		be.binary_expr.op = op;
		be.binary_expr.left = s->expr;;
		be.binary_expr.right = &basic_lit;
		check_binary_expr(c, &operand, &be);

	} break;

	case AstNode_AssignStmt:
		switch (node->assign_stmt.op.kind) {
		case Token_Eq: {
			// a, b, c = 1, 2, 3;  // Multisided
			if (node->assign_stmt.lhs_count == 0) {
				error(&c->error_collector, node->assign_stmt.op, "Missing lhs in assignment statement");
				return;
			}

			Operand operand = {};
			AstNode *lhs = node->assign_stmt.lhs_list;
			AstNode *rhs = node->assign_stmt.rhs_list;
			isize i = 0;
			for (;
			     lhs != NULL && rhs != NULL;
			     lhs = lhs->next, rhs = rhs->next) {
				check_multi_expr(c, &operand, rhs);
				if (operand.type->kind != Type_Tuple) {
					check_assignment_variable(c, &operand, lhs);
					i++;
				} else {
					auto *tuple = &operand.type->tuple;
					for (isize j = 0;
					     j < tuple->variable_count && lhs != NULL;
					     j++, i++, lhs = lhs->next) {
						// TODO(bill): More error checking
						operand.type = tuple->variables[j]->type;
						check_assignment_variable(c, &operand, lhs);
					}
					if (lhs == NULL)
						break;
				}
			}

			if (i < node->assign_stmt.lhs_count && i < node->assign_stmt.rhs_count) {
				if (lhs == NULL)
					error(&c->error_collector, ast_node_token(lhs), "Too few values on the right hand side of the declaration");
			} else if (rhs != NULL) {
				error(&c->error_collector, ast_node_token(rhs), "Too many values on the right hand side of the declaration");
			}
		} break;

		default: {
			// a += 1; // Single-sided
			Token op = node->assign_stmt.op;
			if (node->assign_stmt.lhs_count != 1 ||
			    node->assign_stmt.rhs_count != 1) {
				error(&c->error_collector, op, "Assignment operation `%.*s` requires single-valued expressions", LIT(op.string));
				return;
			}
			if (!gb_is_between(op.kind, Token__AssignOpBegin+1, Token__AssignOpEnd-1)) {
				error(&c->error_collector, op, "Unknown Assignment operation `%.*s`", LIT(op.string));
				return;
			}
			// TODO(bill): Check if valid assignment operator
			Operand operand = {Addressing_Invalid};
			AstNode be = {AstNode_BinaryExpr};
			be.binary_expr.op    = op;
			 // NOTE(bill): Only use the first one will be used
			be.binary_expr.left  = node->assign_stmt.lhs_list;
			be.binary_expr.right = node->assign_stmt.rhs_list;

			check_binary_expr(c, &operand, &be);
			if (operand.mode == Addressing_Invalid)
				return;
			// NOTE(bill): Only use the first one will be used
			check_assignment_variable(c, &operand, node->assign_stmt.lhs_list);
		} break;
		}
		break;

	case AstNode_BlockStmt:
		check_open_scope(c, node);
		check_stmt_list(c, node->block_stmt.list, flags);
		check_close_scope(c);
		break;

	case AstNode_IfStmt: {
		check_open_scope(c, node);
		defer (check_close_scope(c));
		auto *is = &node->if_stmt;

		if (is->init != NULL)
			check_stmt(c, is->init, 0);

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, node->if_stmt.cond);
		if (operand.mode != Addressing_Invalid &&
		    !is_type_boolean(operand.type)) {
			error(&c->error_collector, ast_node_token(node->if_stmt.cond),
			            "Non-boolean condition in `if` statement");
		}

		check_stmt(c, node->if_stmt.body, flags);

		if (node->if_stmt.else_stmt) {
			switch (node->if_stmt.else_stmt->kind) {
			case AstNode_IfStmt:
			case AstNode_BlockStmt:
				check_stmt(c, node->if_stmt.else_stmt, flags);
				break;
			default:
				error(&c->error_collector, ast_node_token(node->if_stmt.else_stmt),
				            "Invalid `else` statement in `if` statement");
				break;
			}
		}
	} break;

	case AstNode_ReturnStmt: {
		auto *rs = &node->return_stmt;
		GB_ASSERT(gb_array_count(c->procedure_stack) > 0);

		if (c->in_defer) {
			error(&c->error_collector, rs->token, "You cannot `return` within a defer statement");
			// TODO(bill): Should I break here?
			break;
		}

		Type *proc_type = c->procedure_stack[gb_array_count(c->procedure_stack)-1];
		isize result_count = 0;
		if (proc_type->procedure.results)
			result_count = proc_type->procedure.results->tuple.variable_count;
		if (result_count != rs->result_count) {
			error(&c->error_collector, rs->token, "Expected %td return %s, got %td",
			            result_count,
			            (result_count != 1 ? "values" : "value"),
			            rs->result_count);
		} else if (result_count > 0) {
			auto *tuple = &proc_type->procedure.results->tuple;
			check_init_variables(c, tuple->variables, tuple->variable_count,
			                     rs->result_list, rs->result_count, make_string("return statement"));
		}
	} break;

	case AstNode_ForStmt: {
		flags |= Statement_BreakAllowed | Statement_ContinueAllowed;
		check_open_scope(c, node);
		defer (check_close_scope(c));

		if (node->for_stmt.init != NULL)
			check_stmt(c, node->for_stmt.init, 0);
		if (node->for_stmt.cond) {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, node->for_stmt.cond);
			if (operand.mode != Addressing_Invalid &&
			    !is_type_boolean(operand.type)) {
				error(&c->error_collector, ast_node_token(node->for_stmt.cond),
				      "Non-boolean condition in `for` statement");
			}
		}
		if (node->for_stmt.end != NULL)
			check_stmt(c, node->for_stmt.end, 0);
		check_stmt(c, node->for_stmt.body, flags);
	} break;

	case AstNode_DeferStmt: {
		auto *ds = &node->defer_stmt;
		if (is_ast_node_decl(ds->stmt)) {
			error(&c->error_collector, ds->token, "You cannot defer a declaration");
		} else {
			b32 out_in_defer = c->in_defer;
			c->in_defer = true;
			check_stmt(c, ds->stmt, 0);
			c->in_defer = out_in_defer;
		}
	} break;

	case AstNode_BranchStmt: {
		Token token = node->branch_stmt.token;
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
	} break;


// Declarations
	case AstNode_VarDecl: {
		auto *vd = &node->var_decl;
		isize entity_count = vd->name_count;
		isize entity_index = 0;
		Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);
		switch (vd->kind) {
		case Declaration_Mutable: {
			Entity **new_entities = gb_alloc_array(c->allocator, Entity *, entity_count);
			isize new_entity_count = 0;

			for (AstNode *name = vd->name_list; name != NULL; name = name->next) {
				Entity *entity = NULL;
				Token token = name->ident.token;
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
					init_type = &basic_types[Basic_Invalid];
			}

			for (isize i = 0; i < entity_count; i++) {
				Entity *e = entities[i];
				GB_ASSERT(e != NULL);
				if (e->variable.visited) {
					e->type = &basic_types[Basic_Invalid];
					continue;
				}
				e->variable.visited = true;

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
				Entity *e = make_entity_constant(c->allocator, c->context.scope, name->ident.token, NULL, v);
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
	} break;

	case AstNode_ProcDecl: {
		auto *pd = &node->proc_decl;
		Entity *e = make_entity_procedure(c->allocator, c->context.scope, pd->name->ident.token, NULL);
		add_entity(c, c->context.scope, pd->name, e);

		DeclInfo decl = {};
		init_declaration_info(&decl, e->parent);
		decl.proc_decl = node;
		check_proc_decl(c, e, &decl, false);
		destroy_declaration_info(&decl);
	} break;

	case AstNode_TypeDecl: {
		auto *td = &node->type_decl;
		AstNode *name = td->name;
		Entity *e = make_entity_type_name(c->allocator, c->context.scope, name->ident.token, NULL);
		add_entity(c, c->context.scope, name, e);
		check_type_decl(c, e, td->type, NULL);
	} break;

	case AstNode_AliasDecl: {
		auto *ad = &node->alias_decl;
		AstNode *name = ad->name;
		Entity *e = make_entity_alias_name(c->allocator, c->context.scope, name->ident.token, NULL);
		add_entity(c, c->context.scope, name, e);
		check_alias_decl(c, e, ad->type, NULL);
	} break;
	}
}
