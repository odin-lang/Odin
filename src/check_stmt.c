void check_stmt_list(Checker *c, AstNodeArray stmts, u32 flags) {
	if (stmts.count == 0) {
		return;
	}

	check_scope_decls(c, stmts, 1.2*stmts.count);

	bool ft_ok = (flags & Stmt_FallthroughAllowed) != 0;
	flags &= ~Stmt_FallthroughAllowed;

	isize max = stmts.count;
	for (isize i = stmts.count-1; i >= 0; i--) {
		if (stmts.e[i]->kind != AstNode_EmptyStmt) {
			break;
		}
		max--;
	}
	for (isize i = 0; i < max; i++) {
		AstNode *n = stmts.e[i];
		if (n->kind == AstNode_EmptyStmt) {
			continue;
		}
		u32 new_flags = flags;
		if (ft_ok && i+1 == max) {
			new_flags |= Stmt_FallthroughAllowed;
		}

		if (i+1 < max) {
			switch (n->kind) {
			case AstNode_ReturnStmt:
				error_node(n, "Statements after this `return` are never executed");
				break;
			case AstNode_ExprStmt:
				if (n->ExprStmt.expr->kind == AstNode_GiveExpr) {
					error_node(n, "A `give` must be the last statement in a block");
				}
				break;
			}
		}

		check_stmt(c, n, new_flags);
	}

}

bool check_is_terminating_list(AstNodeArray stmts) {
	// Iterate backwards
	for (isize n = stmts.count-1; n >= 0; n--) {
		AstNode *stmt = stmts.e[n];
		if (stmt->kind != AstNode_EmptyStmt) {
			return check_is_terminating(stmt);
		}
	}

	return false;
}

bool check_has_break_list(AstNodeArray stmts, bool implicit) {
	for_array(i, stmts) {
		AstNode *stmt = stmts.e[i];
		if (check_has_break(stmt, implicit)) {
			return true;
		}
	}
	return false;
}


bool check_has_break(AstNode *stmt, bool implicit) {
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
bool check_is_terminating(AstNode *node) {
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

	case_ast_node(ws, WhenStmt, node);
		if (ws->else_stmt != NULL) {
			if (check_is_terminating(ws->body) &&
			    check_is_terminating(ws->else_stmt)) {
			    return true;
		    }
		}
	case_end;

	case_ast_node(ws, WhileStmt, node);
		if (ws->cond != NULL && !check_has_break(ws->body, true)) {
			return check_is_terminating(ws->body);
		}
	case_end;

	case_ast_node(rs, ForStmt, node);
		if (!check_has_break(rs->body, true)) {
			return check_is_terminating(rs->body);
		}
	case_end;

	case_ast_node(ms, MatchStmt, node);
		bool has_default = false;
		for_array(i, ms->body->BlockStmt.stmts) {
			AstNode *clause = ms->body->BlockStmt.stmts.e[i];
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
		bool has_default = false;
		for_array(i, ms->body->BlockStmt.stmts) {
			AstNode *clause = ms->body->BlockStmt.stmts.e[i];
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
	    str_eq(node->Ident.string, str_lit("_"))) {
		add_entity_definition(&c->info, node, NULL);
		check_assignment(c, op_a, NULL, str_lit("assignment to `_` identifier"));
		if (op_a->mode == Addressing_Invalid)
			return NULL;
		return op_a->type;
	}

	Entity *e = NULL;
	bool used = false;
	if (node->kind == AstNode_Ident) {
		ast_node(i, Ident, node);
		e = scope_lookup_entity(c->context.scope, i->string);
		if (e != NULL && e->kind == Entity_Variable) {
			used = (e->flags & EntityFlag_Used) != 0; // TODO(bill): Make backup just in case
		}
	}


	Operand op_b = {Addressing_Invalid};
	check_expr(c, &op_b, lhs);
	if (e) {
		e->flags |= EntityFlag_Used*used;
	}

	if (op_b.mode == Addressing_Invalid ||
	    op_b.type == t_invalid) {
		return NULL;
	}

	switch (op_b.mode) {
	case Addressing_Invalid:
		return NULL;
	case Addressing_Variable:
		break;
	default: {
		if (op_b.expr->kind == AstNode_SelectorExpr) {
			// NOTE(bill): Extra error checks
			Operand op_c = {Addressing_Invalid};
			ast_node(se, SelectorExpr, op_b.expr);
			check_expr(c, &op_c, se->expr);
		}

		gbString str = expr_to_string(op_b.expr);
		switch (op_b.mode) {
		case Addressing_Value:
			error_node(op_b.expr, "Cannot assign to `%s`", str);
			break;
		default:
			error_node(op_b.expr, "Cannot assign to `%s`", str);
			break;
		}
		gb_string_free(str);
	} break;
	}

	check_assignment(c, op_a, op_b.type, str_lit("assignment"));
	if (op_a->mode == Addressing_Invalid) {
		return NULL;
	}

	return op_a->type;
}

bool check_valid_type_match_type(Type *type, bool *is_union_ptr, bool *is_any) {
	if (is_type_pointer(type)) {
		*is_union_ptr = is_type_union(type_deref(type));
		return *is_union_ptr;
	}
	if (is_type_any(type)) {
		*is_any = true;
		return *is_any;
	}
	return false;
}

void check_stmt_internal(Checker *c, AstNode *node, u32 flags);
void check_stmt(Checker *c, AstNode *node, u32 flags) {
	u32 prev_stmt_state_flags = c->context.stmt_state_flags;

	if (node->stmt_state_flags != 0) {
		u32 in = node->stmt_state_flags;
		u32 out = c->context.stmt_state_flags;

		if (in & StmtStateFlag_bounds_check) {
			out |= StmtStateFlag_bounds_check;
			out &= ~StmtStateFlag_no_bounds_check;
		} else if (in & StmtStateFlag_no_bounds_check) {
			out |= StmtStateFlag_no_bounds_check;
			out &= ~StmtStateFlag_bounds_check;
		}

		c->context.stmt_state_flags = out;
	}

	check_stmt_internal(c, node, flags);

	c->context.stmt_state_flags = prev_stmt_state_flags;
}



typedef struct TypeAndToken {
	Type *type;
	Token token;
} TypeAndToken;

#define MAP_TYPE TypeAndToken
#define MAP_PROC map_type_and_token_
#define MAP_NAME MapTypeAndToken
#include "map.c"

void check_when_stmt(Checker *c, AstNodeWhenStmt *ws, u32 flags) {
	Operand operand = {Addressing_Invalid};
	check_expr(c, &operand, ws->cond);
	if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
		error_node(ws->cond, "Non-constant boolean `when` condition");
		return;
	}
	if (ws->body == NULL || ws->body->kind != AstNode_BlockStmt) {
		error_node(ws->cond, "Invalid body for `when` statement");
		return;
	}
	if (operand.value.kind == ExactValue_Bool &&
	    operand.value.value_bool) {
		check_stmt_list(c, ws->body->BlockStmt.stmts, flags);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case AstNode_BlockStmt:
			check_stmt_list(c, ws->else_stmt->BlockStmt.stmts, flags);
			break;
		case AstNode_WhenStmt:
			check_when_stmt(c, &ws->else_stmt->WhenStmt, flags);
			break;
		default:
			error_node(ws->else_stmt, "Invalid `else` statement in `when` statement");
			break;
		}
	}
}

void check_stmt_internal(Checker *c, AstNode *node, u32 flags) {
	u32 mod_flags = flags & (~Stmt_FallthroughAllowed);
	switch (node->kind) {
	case_ast_node(_, EmptyStmt, node); case_end;
	case_ast_node(_, BadStmt,   node); case_end;
	case_ast_node(_, BadDecl,   node); case_end;

	case_ast_node(es, ExprStmt, node)
		Operand operand = {Addressing_Invalid};
		ExprKind kind = check_expr_base(c, &operand, es->expr, NULL);
		switch (operand.mode) {
		case Addressing_Type:
			error_node(node, "Is not an expression");
			break;
		case Addressing_NoValue:
			return;
		default: {
			if (kind == Expr_Stmt) {
				return;
			}
			if (operand.expr->kind == AstNode_CallExpr) {
				return;
			}
			if (operand.expr->kind == AstNode_GiveExpr) {
				if ((flags&Stmt_GiveAllowed) != 0) {
					return;
				}
				error_node(node, "Illegal use of `give`");
			}
			gbString expr_str = expr_to_string(operand.expr);
			error_node(node, "Expression is not used: `%s`", expr_str);
			gb_string_free(expr_str);
		} break;
		}
	case_end;

	case_ast_node(ts, TagStmt, node);
		// TODO(bill): Tag Statements
		error_node(node, "Tag statements are not supported yet");
		check_stmt(c, ts->stmt, flags);
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

			// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
			// an extra allocation
			Array(Operand) operands;
			array_init_reserve(&operands, c->tmp_allocator, 2 * as->lhs.count);

			for_array(i, as->rhs) {
				AstNode *rhs = as->rhs.e[i];
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

			isize lhs_count = as->lhs.count;
			isize rhs_count = operands.count;

			isize operand_count = gb_min(as->lhs.count, operands.count);
			for (isize i = 0; i < operand_count; i++) {
				AstNode *lhs = as->lhs.e[i];
				check_assignment_variable(c, &operands.e[i], lhs);
			}
			if (lhs_count != rhs_count) {
				error_node(as->lhs.e[0], "Assignment count mismatch `%td` = `%td`", lhs_count, rhs_count);
			}

			gb_temp_arena_memory_end(tmp);
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
			be->op = op;
			be->op.kind = cast(TokenKind)(cast(i32)be->op.kind - (Token_AddEq - Token_Add));
			 // NOTE(bill): Only use the first one will be used
			be->left  = as->lhs.e[0];
			be->right = as->rhs.e[0];

			check_binary_expr(c, &operand, &binary_expr);
			if (operand.mode == Addressing_Invalid) {
				return;
			}
			// NOTE(bill): Only use the first one will be used
			check_assignment_variable(c, &operand, as->lhs.e[0]);
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

		if (is->init != NULL) {
			check_stmt(c, is->init, 0);
		}

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, is->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error_node(is->cond, "Non-boolean condition in `if` statement");
		}

		check_stmt(c, is->body, mod_flags);

		if (is->else_stmt != NULL) {
			switch (is->else_stmt->kind) {
			case AstNode_IfStmt:
			case AstNode_BlockStmt:
				check_stmt(c, is->else_stmt, mod_flags);
				break;
			default:
				error_node(is->else_stmt, "Invalid `else` statement in `if` statement");
				break;
			}
		}

		check_close_scope(c);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		check_when_stmt(c, ws, flags);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		GB_ASSERT(c->proc_stack.count > 0);

		if (c->in_defer) {
			error(rs->token, "You cannot `return` within a defer statement");
			// TODO(bill): Should I break here?
			break;
		}


		Type *proc_type = c->proc_stack.e[c->proc_stack.count-1];
		isize result_count = 0;
		if (proc_type->Proc.results) {
			result_count = proc_type->Proc.results->Tuple.variable_count;
		}

		if (result_count > 0) {
			Entity **variables = NULL;
			if (proc_type->Proc.results != NULL) {
				TypeTuple *tuple = &proc_type->Proc.results->Tuple;
				variables = tuple->variables;
			}
			if (rs->results.count == 0) {
				error_node(node, "Expected %td return values, got 0", result_count);
			} else {
				check_init_variables(c, variables, result_count,
				                     rs->results, str_lit("return statement"));
			}
		} else if (rs->results.count > 0) {
			error_node(rs->results.e[0], "No return values expected");
		}
	case_end;

	case_ast_node(ws, WhileStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;
		check_open_scope(c, node);

		if (ws->init != NULL) {
			check_stmt(c, ws->init, 0);
		}
		if (ws->cond) {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, ws->cond);
			if (operand.mode != Addressing_Invalid &&
			    !is_type_boolean(operand.type)) {
				error_node(ws->cond, "Non-boolean condition in `while` statement");
			}
		}
		check_stmt(c, ws->body, new_flags);

		check_close_scope(c);
	case_end;

	case_ast_node(rs, ForStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;
		check_open_scope(c, node);

		Type *val = NULL;
		Type *idx = NULL;
		Entity *entities[2] = {0};
		isize entity_count = 0;


		if (rs->expr != NULL && rs->expr->kind == AstNode_IntervalExpr) {
			ast_node(ie, IntervalExpr, rs->expr);
			Operand x = {Addressing_Invalid};
			Operand y = {Addressing_Invalid};

			check_expr(c, &x, ie->left);
			if (x.mode == Addressing_Invalid) {
				goto skip_expr;
			}
			check_expr(c, &y, ie->right);
			if (y.mode == Addressing_Invalid) {
				goto skip_expr;
			}

			convert_to_typed(c, &x, y.type, 0);
			if (x.mode == Addressing_Invalid) {
				goto skip_expr;
			}
			convert_to_typed(c, &y, x.type, 0);
			if (y.mode == Addressing_Invalid) {
				goto skip_expr;
			}

			convert_to_typed(c, &x, default_type(y.type), 0);
			if (x.mode == Addressing_Invalid) {
				goto skip_expr;
			}
			convert_to_typed(c, &y, default_type(x.type), 0);
			if (y.mode == Addressing_Invalid) {
				goto skip_expr;
			}

			if (!are_types_identical(x.type, y.type)) {
				if (x.type != t_invalid &&
				    y.type != t_invalid) {
					gbString xt = type_to_string(x.type);
					gbString yt = type_to_string(y.type);
					gbString expr_str = expr_to_string(x.expr);
					error(ie->op, "Mismatched types in interval expression `%s` : `%s` vs `%s`", expr_str, xt, yt);
					gb_string_free(expr_str);
					gb_string_free(yt);
					gb_string_free(xt);
				}
				goto skip_expr;
			}

			Type *type = x.type;
			if (!is_type_integer(type) && !is_type_float(type) && !is_type_pointer(type)) {
				error(ie->op, "Only numerical and pointer types are allowed within interval expressions");
				goto skip_expr;
			}

			if (x.mode == Addressing_Constant &&
			    y.mode == Addressing_Constant) {
				ExactValue a = x.value;
				ExactValue b = y.value;

				GB_ASSERT(are_types_identical(x.type, y.type));

				bool ok = compare_exact_values(Token_Lt, a, b);
				if (!ok) {
					// TODO(bill): Better error message
					error(ie->op, "Invalid interval range");
					goto skip_expr;
				}
			}

			add_type_and_value(&c->info, ie->left,  x.mode, x.type, x.value);
			add_type_and_value(&c->info, ie->right, y.mode, y.type, y.value);
			val = type;
			idx = t_int;
		} else {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, rs->expr);

			if (operand.mode != Addressing_Invalid) {
				Type *t = base_type(type_deref(operand.type));
				switch (t->kind) {
				case Type_Basic:
					if (is_type_string(t)) {
						val = t_rune;
						idx = t_int;
					}
					break;
				case Type_Array:
					val = t->Array.elem;
					idx = t_int;
					break;
				case Type_Slice:
					val = t->Array.elem;
					idx = t_int;
					break;
				}
			}

			if (val == NULL) {
				gbString s = expr_to_string(operand.expr);
				gbString t = type_to_string(operand.type);
				error_node(operand.expr, "Cannot iterate over `%s` of type `%s`", s, t);
				gb_string_free(t);
				gb_string_free(s);
			}
		}

	skip_expr:
		AstNode *lhs[2] = {rs->value, rs->index};
		Type *   rhs[2] = {val, idx};

		for (isize i = 0; i < 2; i++) {
			if (lhs[i] == NULL) {
				continue;
			}
			AstNode *name = lhs[i];
			Type *   type = rhs[i];

			Entity *entity = NULL;
			if (name->kind == AstNode_Ident) {
				Token token = name->Ident;
				String str = token.string;
				Entity *found = NULL;

				if (str_ne(str, str_lit("_"))) {
					found = current_scope_lookup_entity(c->context.scope, str);
				}
				if (found == NULL) {
					entity = make_entity_variable(c->allocator, c->context.scope, token, type);
					entity->Variable.is_immutable = true;
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

			entities[entity_count++] = entity;

			if (type == NULL) {
				entity->type = t_invalid;
				entity->flags |= EntityFlag_Used;
			}
		}

		for (isize i = 0; i < entity_count; i++) {
			add_entity(c, c->context.scope, entities[i]->identifier, entities[i]);
		}

		check_stmt(c, rs->body, new_flags);

		check_close_scope(c);
	case_end;

	case_ast_node(ms, MatchStmt, node);
		Operand x = {0};

		mod_flags |= Stmt_BreakAllowed;
		check_open_scope(c, node);

		if (ms->init != NULL) {
			check_stmt(c, ms->init, 0);
		}
		if (ms->tag != NULL) {
			check_expr(c, &x, ms->tag);
			check_assignment(c, &x, NULL, str_lit("match expression"));
		} else {
			x.mode  = Addressing_Constant;
			x.type  = t_bool;
			x.value = make_exact_value_bool(true);

			Token token = {0};
			token.pos = ast_node_token(ms->body).pos;
			token.string = str_lit("true");
			x.expr  = make_ident(c->curr_ast_file, token);
		}

		// NOTE(bill): Check for multiple defaults
		AstNode *first_default = NULL;
		ast_node(bs, BlockStmt, ms->body);
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts.e[i];
			AstNode *default_stmt = NULL;
			if (stmt->kind == AstNode_CaseClause) {
				ast_node(cc, CaseClause, stmt);
				if (cc->list.count == 0) {
					default_stmt = stmt;
				}
			} else {
				error_node(stmt, "Invalid AST - expected case clause");
			}

			if (default_stmt != NULL) {
				if (first_default != NULL) {
					TokenPos pos = ast_node_token(first_default).pos;
					error_node(stmt,
					           "multiple `default` clauses\n"
					           "\tfirst at %.*s(%td:%td)",
					           LIT(pos.file), pos.line, pos.column);
				} else {
					first_default = default_stmt;
				}
			}
		}

		MapTypeAndToken seen = {0}; // NOTE(bill): Multimap
		map_type_and_token_init(&seen, heap_allocator());

		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts.e[i];
			if (stmt->kind != AstNode_CaseClause) {
				// NOTE(bill): error handled by above multiple default checker
				continue;
			}
			ast_node(cc, CaseClause, stmt);


			for_array(j, cc->list) {
				AstNode *expr = cc->list.e[j];
				Operand y = {0};

				check_expr(c, &y, expr);
				if (x.mode == Addressing_Invalid ||
				    y.mode == Addressing_Invalid) {
					continue;
				}

				convert_to_typed(c, &y, x.type, 0);
				if (y.mode == Addressing_Invalid) {
					continue;
				}

				// NOTE(bill): the ordering here matters
				Operand z = y;
				check_comparison(c, &z, &x, Token_CmpEq);
				if (z.mode == Addressing_Invalid) {
					continue;
				}
				if (y.mode != Addressing_Constant) {
					continue;
				}


				if (y.value.kind != ExactValue_Invalid) {
					HashKey key = hash_exact_value(y.value);
					TypeAndToken *found = map_type_and_token_get(&seen, key);
					if (found != NULL) {
						gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
						isize count = map_type_and_token_multi_count(&seen, key);
						TypeAndToken *taps = gb_alloc_array(c->tmp_allocator, TypeAndToken, count);

						map_type_and_token_multi_get_all(&seen, key, taps);
						bool continue_outer = false;

						for (isize i = 0; i < count; i++) {
							TypeAndToken tap = taps[i];
							if (are_types_identical(y.type, tap.type)) {
								TokenPos pos = tap.token.pos;
								gbString expr_str = expr_to_string(y.expr);
								error_node(y.expr,
								           "Duplicate case `%s`\n"
								           "\tprevious case at %.*s(%td:%td)",
								           expr_str,
								           LIT(pos.file), pos.line, pos.column);
								gb_string_free(expr_str);
								continue_outer = true;
								break;
							}
						}

						gb_temp_arena_memory_end(tmp);

						if (continue_outer) {
							continue;
						}
					}
					TypeAndToken tap = {y.type, ast_node_token(y.expr)};
					map_type_and_token_multi_insert(&seen, key, tap);
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

		map_type_and_token_destroy(&seen);

		check_close_scope(c);
	case_end;

	case_ast_node(ms, TypeMatchStmt, node);
		Operand x = {0};

		mod_flags |= Stmt_BreakAllowed;
		check_open_scope(c, node);

		bool is_union_ptr = false;
		bool is_any = false;

		check_expr(c, &x, ms->tag);
		check_assignment(c, &x, NULL, str_lit("type match expression"));
		if (!check_valid_type_match_type(x.type, &is_union_ptr, &is_any)) {
			gbString str = type_to_string(x.type);
			error_node(x.expr,
			           "Invalid type for this type match expression, got `%s`", str);
			gb_string_free(str);
			break;
		}


		// NOTE(bill): Check for multiple defaults
		AstNode *first_default = NULL;
		ast_node(bs, BlockStmt, ms->body);
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts.e[i];
			AstNode *default_stmt = NULL;
			if (stmt->kind == AstNode_CaseClause) {
				ast_node(cc, CaseClause, stmt);
				if (cc->list.count == 0) {
					default_stmt = stmt;
				}
			} else {
				error_node(stmt, "Invalid AST - expected case clause");
			}

			if (default_stmt != NULL) {
				if (first_default != NULL) {
					TokenPos pos = ast_node_token(first_default).pos;
					error_node(stmt,
					           "Multiple `default` clauses\n"
					           "\tfirst at %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
				} else {
					first_default = default_stmt;
				}
			}
		}

		if (ms->var->kind != AstNode_Ident) {
			break;
		}


		MapBool seen = {0};
		map_bool_init(&seen, heap_allocator());

		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts.e[i];
			if (stmt->kind != AstNode_CaseClause) {
				// NOTE(bill): error handled by above multiple default checker
				continue;
			}
			ast_node(cc, CaseClause, stmt);

			// TODO(bill): Make robust
			Type *bt = base_type(type_deref(x.type));


			AstNode *type_expr = cc->list.count > 0 ? cc->list.e[0] : NULL;
			Type *case_type = NULL;
			if (type_expr != NULL) { // Otherwise it's a default expression
				Operand y = {0};
				check_expr_or_type(c, &y, type_expr);

				if (is_union_ptr) {
					GB_ASSERT(is_type_union(bt));
					bool tag_type_found = false;
					for (isize i = 0; i < bt->Record.field_count; i++) {
						Entity *f = bt->Record.fields[i];
						if (are_types_identical(f->type, y.type)) {
							tag_type_found = true;
							break;
						}
					}
					if (!tag_type_found) {
						gbString type_str = type_to_string(y.type);
						error_node(y.expr,
						           "Unknown tag type, got `%s`", type_str);
						gb_string_free(type_str);
						continue;
					}
					case_type = y.type;
				} else if (is_any) {
					case_type = y.type;
				} else {
					GB_PANIC("Unknown type to type match statement");
				}

				HashKey key = hash_pointer(y.type);
				bool *found = map_bool_get(&seen, key);
				if (found) {
					TokenPos pos = cc->token.pos;
					gbString expr_str = expr_to_string(y.expr);
					error_node(y.expr,
					           "Duplicate type case `%s`\n"
					           "\tprevious type case at %.*s(%td:%td)",
					           expr_str,
					           LIT(pos.file), pos.line, pos.column);
					gb_string_free(expr_str);
					break;
				}
				map_bool_set(&seen, key, cast(bool)true);
			}

			check_open_scope(c, stmt);
			if (case_type != NULL) {
				add_type_info_type(c, case_type);

				// NOTE(bill): Dummy type
				Type *tt = case_type;
				if (is_union_ptr) {
					tt = make_type_pointer(c->allocator, case_type);
					add_type_info_type(c, tt);
				}
				Entity *tag_var = make_entity_variable(c->allocator, c->context.scope, ms->var->Ident, tt);
				tag_var->flags |= EntityFlag_Used;
				tag_var->Variable.is_immutable = true;
				add_entity(c, c->context.scope, ms->var, tag_var);
				add_entity_use(c, ms->var, tag_var);
			}
			check_stmt_list(c, cc->stmts, mod_flags);
			check_close_scope(c);
		}
		map_bool_destroy(&seen);

		check_close_scope(c);
	case_end;


	case_ast_node(ds, DeferStmt, node);
		if (is_ast_node_decl(ds->stmt)) {
			error(ds->token, "You cannot defer a declaration");
		} else {
			bool out_in_defer = c->in_defer;
			c->in_defer = true;
			check_stmt(c, ds->stmt, 0);
			c->in_defer = out_in_defer;
		}
	case_end;

	case_ast_node(bs, BranchStmt, node);
		Token token = bs->token;
		switch (token.kind) {
		case Token_break:
			if ((flags & Stmt_BreakAllowed) == 0) {
				error(token, "`break` only allowed in loops or `match` statements");
			}
			break;
		case Token_continue:
			if ((flags & Stmt_ContinueAllowed) == 0) {
				error(token, "`continue` only allowed in loops");
			}
			break;
		case Token_fallthrough:
			if ((flags & Stmt_FallthroughAllowed) == 0) {
				error(token, "`fallthrough` statement in illegal position");
			}
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

			bool is_selector = false;
			AstNode *expr = unparen_expr(es->expr);
			if (expr->kind == AstNode_Ident) {
				String name = expr->Ident.string;
				e = scope_lookup_entity(c->context.scope, name);
			} else if (expr->kind == AstNode_SelectorExpr) {
				Operand o = {0};
				e = check_selector(c, &o, expr);
				is_selector = true;
			}

			if (e == NULL) {
				error(us->token, "`using` applied to an unknown entity");
				return;
			}

			switch (e->kind) {
			case Entity_TypeName: {
				Type *t = base_type(e->type);
				if (is_type_union(t)) {
					for (isize i = 0; i < t->Record.field_count; i++) {
						Entity *f = t->Record.fields[i];
						Entity *found = scope_insert_entity(c->context.scope, f);
						if (found != NULL) {
							gbString expr_str = expr_to_string(expr);
							error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(found->token.string));
							gb_string_free(expr_str);
							return;
						}
						f->using_parent = e;
					}
				} else if (is_type_enum(t)) {
					for (isize i = 0; i < t->Record.field_count; i++) {
						Entity *f = t->Record.fields[i];
						Entity *found = scope_insert_entity(c->context.scope, f);
						if (found != NULL) {
							gbString expr_str = expr_to_string(expr);
							error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(found->token.string));
							gb_string_free(expr_str);
							return;
						}
						f->using_parent = e;
					}

				} else {
					error(us->token, "`using` can be only applied to `union` or `enum` type entities");
				}
			} break;

			case Entity_ImportName: {
				Scope *scope = e->ImportName.scope;
				for_array(i, scope->elements.entries) {
					Entity *decl = scope->elements.entries.e[i].value;
					Entity *found = scope_insert_entity(c->context.scope, decl);
					if (found != NULL) {
						gbString expr_str = expr_to_string(expr);
						error(us->token,
						      "Namespace collision while `using` `%s` of: %.*s\n"
						      "\tat %.*s(%td:%td)\n"
						      "\tat %.*s(%td:%td)",
						      expr_str, LIT(found->token.string),
						      LIT(found->token.pos.file), found->token.pos.line, found->token.pos.column,
						      LIT(decl->token.pos.file), decl->token.pos.line, decl->token.pos.column
						      );
						gb_string_free(expr_str);
						return;
					}
				}
			} break;

			case Entity_Variable: {
				Type *t = base_type(type_deref(e->type));
				if (is_type_struct(t) || is_type_raw_union(t)) {
					Scope **found = map_scope_get(&c->info.scopes, hash_pointer(t->Record.node));
					GB_ASSERT(found != NULL);
					for_array(i, (*found)->elements.entries) {
						Entity *f = (*found)->elements.entries.e[i].value;
						if (f->kind == Entity_Variable) {
							Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
							if (is_selector) {
								uvar->using_expr = expr;
							}
							Entity *prev = scope_insert_entity(c->context.scope, uvar);
							if (prev != NULL) {
								gbString expr_str = expr_to_string(expr);
								error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(prev->token.string));
								gb_string_free(expr_str);
								return;
							}
						}
					}
				} else {
					error(us->token, "`using` can only be applied to variables of type struct or raw_union");
					return;
				}
			} break;

			case Entity_Constant:
				error(us->token, "`using` cannot be applied to a constant");
				break;

			case Entity_Procedure:
			case Entity_Builtin:
				error(us->token, "`using` cannot be applied to a procedure");
				break;

			case Entity_ImplicitValue:
				error(us->token, "`using` cannot be applied to an implicit value");
				break;

			case Entity_Nil:
				error(us->token, "`using` cannot be applied to `nil`");
				break;

			case Entity_Invalid:
				error(us->token, "`using` cannot be applied to an invalid entity");
				break;

			default:
				GB_PANIC("TODO(bill): `using` other expressions?");
			}
		case_end;

		case_ast_node(vd, ValueDecl, us->node);
			if (!vd->is_var) {
				error_node(us->node, "`using` can only be applied to a variable declaration");
				return;
			}

			if (vd->names.count > 1 && vd->type != NULL) {
				error(us->token, "`using` can only be applied to one variable of the same type");
			}

			check_var_decl_node(c, vd);

			for_array(name_index, vd->names) {
				AstNode *item = vd->names.e[name_index];
				if (item->kind != AstNode_Ident) {
					// TODO(bill): Handle error here???
					continue;
				}
				ast_node(i, Ident, item);
				String name = i->string;
				Entity *e = scope_lookup_entity(c->context.scope, name);
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
		Operand op = {0};
		check_expr(c, &op, pa->expr);
		check_assignment(c, &op, t_allocator, str_lit("argument to push_allocator"));
		check_stmt(c, pa->body, mod_flags);
	case_end;


	case_ast_node(pa, PushContext, node);
		Operand op = {0};
		check_expr(c, &op, pa->expr);
		check_assignment(c, &op, t_context, str_lit("argument to push_context"));
		check_stmt(c, pa->body, mod_flags);
	case_end;


	case_ast_node(vd, ValueDecl, node);
		if (vd->is_var) {
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
			check_arity_match(c, vd);

			check_init_variables(c, entities, entity_count, vd->values, str_lit("variable declaration"));

			for_array(i, vd->names) {
				if (entities[i] != NULL) {
					add_entity(c, c->context.scope, vd->names.e[i], entities[i]);
				}
			}
		} else {
			// NOTE(bill): Handled elsewhere
		}
	case_end;
	}
}
