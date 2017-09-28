void check_stmt_list(Checker *c, Array<AstNode *> stmts, u32 flags) {
	if (stmts.count == 0) {
		return;
	}

	if (flags&Stmt_CheckScopeDecls) {
		check_scope_decls(c, stmts, cast(isize)(1.2*stmts.count));
	}

	bool ft_ok = (flags & Stmt_FallthroughAllowed) != 0;
	flags &= ~Stmt_FallthroughAllowed;

	isize max = stmts.count;
	for (isize i = stmts.count-1; i >= 0; i--) {
		if (stmts[i]->kind != AstNode_EmptyStmt) {
			break;
		}
		max--;
	}
	for (isize i = 0; i < max; i++) {
		AstNode *n = stmts[i];
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
				error(n, "Statements after this `return` are never executed");
				break;

			case AstNode_BranchStmt:
				error(n, "Statements after this `%.*s` are never executed", LIT(n->BranchStmt.token.string));
				break;
			}
		}

		check_stmt(c, n, new_flags);
	}

}

bool check_is_terminating_list(Array<AstNode *> stmts) {
	// Iterate backwards
	for (isize n = stmts.count-1; n >= 0; n--) {
		AstNode *stmt = stmts[n];
		if (stmt->kind != AstNode_EmptyStmt) {
			return check_is_terminating(stmt);
		}
	}

	return false;
}

bool check_has_break_list(Array<AstNode *> stmts, bool implicit) {
	for_array(i, stmts) {
		AstNode *stmt = stmts[i];
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
		    (stmt->IfStmt.else_stmt != nullptr && check_has_break(stmt->IfStmt.else_stmt, implicit))) {
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
		if (is->else_stmt != nullptr) {
			if (check_is_terminating(is->body) &&
			    check_is_terminating(is->else_stmt)) {
			    return true;
		    }
		}
	case_end;

	case_ast_node(ws, WhenStmt, node);
		if (ws->else_stmt != nullptr) {
			if (check_is_terminating(ws->body) &&
			    check_is_terminating(ws->else_stmt)) {
			    return true;
		    }
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		if (fs->cond == nullptr && !check_has_break(fs->body, true)) {
			return check_is_terminating(fs->body);
		}
	case_end;

	case_ast_node(rs, RangeStmt, node);
		return false;
	case_end;

	case_ast_node(ms, MatchStmt, node);
		bool has_default = false;
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
		bool has_default = false;
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

Type *check_assignment_variable(Checker *c, Operand *rhs, AstNode *lhs_node) {
	if (rhs->mode == Addressing_Invalid ||
	    (rhs->type == t_invalid && rhs->mode != Addressing_Overload)) {
		return nullptr;
	}

	AstNode *node = unparen_expr(lhs_node);

	// NOTE(bill): Ignore assignments to `_`
	if (is_blank_ident(node)) {
		add_entity_definition(&c->info, node, nullptr);
		check_assignment(c, rhs, nullptr, str_lit("assignment to `_` identifier"));
		if (rhs->mode == Addressing_Invalid) {
			return nullptr;
		}
		return rhs->type;
	}

	Entity *e = nullptr;
	bool used = false;
	Operand lhs = {Addressing_Invalid};


	check_expr(c, &lhs, lhs_node);
	if (lhs.mode == Addressing_Invalid ||
	    lhs.type == t_invalid) {
		return nullptr;
	}

	if (rhs->mode == Addressing_Overload) {
		isize overload_count = rhs->overload_count;
		Entity **procs = rhs->overload_entities;
		GB_ASSERT(procs != nullptr && overload_count > 0);

		// NOTE(bill): These should be done
		for (isize i = 0; i < overload_count; i++) {
			Type *t = base_type(procs[i]->type);
			if (t == t_invalid) {
				continue;
			}
			Operand x = {};
			x.mode = Addressing_Value;
			x.type = t;
			if (check_is_assignable_to(c, &x, lhs.type)) {
				e = procs[i];
				add_entity_use(c, rhs->expr, e);
				break;
			}
		}

		if (e != nullptr) {
			// HACK TODO(bill): Should the entities be freed as it's technically a leak
			rhs->mode = Addressing_Value;
			rhs->type = e->type;
			rhs->overload_count = 0;
			rhs->overload_entities = nullptr;
		}
	} else {
		if (node->kind == AstNode_Ident) {
			ast_node(i, Ident, node);
			e = scope_lookup_entity(c->context.scope, i->token.string);
			if (e != nullptr && e->kind == Entity_Variable) {
				used = (e->flags & EntityFlag_Used) != 0; // TODO(bill): Make backup just in case
			}
		}

	}

	if (e != nullptr && used) {
		e->flags |= EntityFlag_Used;
	}

	Type *assignment_type = lhs.type;
	switch (lhs.mode) {
	case Addressing_Invalid:
		return nullptr;

	case Addressing_Variable: {
		if (is_type_bit_field_value(lhs.type)) {
			Type *lt = base_type(lhs.type);
			i64 lhs_bits = lt->BitFieldValue.bits;
			if (rhs->mode == Addressing_Constant) {
				ExactValue v = exact_value_to_integer(rhs->value);
				if (v.kind == ExactValue_Integer) {
					i128 i = v.value_integer;
					u128 u = *cast(u128 *)&i;
					u128 umax = U128_NEG_ONE;
					if (lhs_bits < 128) {
						umax = u128_sub(u128_shl(U128_ONE, cast(u32)lhs_bits), U128_ONE);
					}
					i128 imax = i128_shl(I128_ONE, cast(u32)lhs_bits-1);

					bool ok = false;
					ok = !(u128_lt(u, U128_ZERO) || u128_gt(u, umax));

					if (ok) {
						return rhs->type;
					}
				}
			} else if (is_type_integer(rhs->type)) {
				// TODO(bill): Any other checks?
				return rhs->type;
			}
			gbString lhs_expr = expr_to_string(lhs.expr);
			gbString rhs_expr = expr_to_string(rhs->expr);
			error(rhs->expr, "Cannot assign `%s` to bit field `%s`", rhs_expr, lhs_expr);
			gb_string_free(rhs_expr);
			gb_string_free(lhs_expr);
			return nullptr;
		}
		break;
	}

	case Addressing_MapIndex: {
		AstNode *ln = unparen_expr(lhs_node);
		if (ln->kind == AstNode_IndexExpr) {
			AstNode *x = ln->IndexExpr.expr;
			TypeAndValue tav = type_and_value_of_expr(&c->info, x);
			GB_ASSERT(tav.mode != Addressing_Invalid);
			if (tav.mode != Addressing_Variable) {
				if (!is_type_pointer(tav.type)) {
					gbString str = expr_to_string(lhs.expr);
					error(lhs.expr, "Cannot assign to the value of a map `%s`", str);
					gb_string_free(str);
					return nullptr;
				}
			}
		}
	} break;

	default: {
		if (lhs.expr->kind == AstNode_SelectorExpr) {
			// NOTE(bill): Extra error checks
			Operand op_c = {Addressing_Invalid};
			ast_node(se, SelectorExpr, lhs.expr);
			check_expr(c, &op_c, se->expr);
			if (op_c.mode == Addressing_MapIndex) {
				gbString str = expr_to_string(lhs.expr);
				error(lhs.expr, "Cannot assign to struct field `%s` in map", str);
				gb_string_free(str);
				return nullptr;
			}
		}

		gbString str = expr_to_string(lhs.expr);
		if (lhs.mode == Addressing_Immutable) {
			error(lhs.expr, "Cannot assign to an immutable: `%s`", str);
		} else {
			error(lhs.expr, "Cannot assign to `%s`", str);
		}
		gb_string_free(str);
	} break;
	}

	check_assignment(c, rhs, assignment_type, str_lit("assignment"));
	if (rhs->mode == Addressing_Invalid) {
		return nullptr;
	}

	return rhs->type;
}

enum MatchTypeKind {
	MatchType_Invalid,
	MatchType_Union,
	MatchType_Any,
};

MatchTypeKind check_valid_type_match_type(Type *type) {
	type = type_deref(type);
	if (is_type_union(type)) {
		return MatchType_Union;
	}
	if (is_type_any(type)) {
		return MatchType_Any;
	}
	return MatchType_Invalid;
}

void check_stmt_internal(Checker *c, AstNode *node, u32 flags);
void check_stmt(Checker *c, AstNode *node, u32 flags) {
	u32 prev_stmt_state_flags = c->context.stmt_state_flags;

	if (node->stmt_state_flags != 0) {
		u32 in = node->stmt_state_flags;
		u32 out = c->context.stmt_state_flags;

		if (in & StmtStateFlag_no_bounds_check) {
			out |= StmtStateFlag_no_bounds_check;
			out &= ~StmtStateFlag_bounds_check;
		} else {
		// if (in & StmtStateFlag_bounds_check) {
			out |= StmtStateFlag_bounds_check;
			out &= ~StmtStateFlag_no_bounds_check;
		}

		c->context.stmt_state_flags = out;
	}

	check_stmt_internal(c, node, flags);

	c->context.stmt_state_flags = prev_stmt_state_flags;
}



struct TypeAndToken {
	Type *type;
	Token token;
};

void check_when_stmt(Checker *c, AstNodeWhenStmt *ws, u32 flags) {
	flags &= ~Stmt_CheckScopeDecls;
	Operand operand = {Addressing_Invalid};
	check_expr(c, &operand, ws->cond);
	if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
		error(ws->cond, "Non-constant boolean `when` condition");
		return;
	}
	if (ws->body == nullptr || ws->body->kind != AstNode_BlockStmt) {
		error(ws->cond, "Invalid body for `when` statement");
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
			error(ws->else_stmt, "Invalid `else` statement in `when` statement");
			break;
		}
	}
}

void check_label(Checker *c, AstNode *label) {
	if (label == nullptr) {
		return;
	}
	ast_node(l, Label, label);
	if (l->name->kind != AstNode_Ident) {
		error(l->name, "A label's name must be an identifier");
		return;
	}
	String name = l->name->Ident.token.string;
	if (is_blank_ident(name)) {
		error(l->name, "A label's name cannot be a blank identifier");
		return;
	}


	if (c->proc_stack.count == 0) {
		error(l->name, "A label is only allowed within a procedure");
		return;
	}
	GB_ASSERT(c->context.decl != nullptr);

	bool ok = true;
	for_array(i, c->context.decl->labels) {
		BlockLabel bl = c->context.decl->labels[i];
		if (bl.name == name) {
			error(label, "Duplicate label with the name `%.*s`", LIT(name));
			ok = false;
			break;
		}
	}

	Entity *e = make_entity_label(c->allocator, c->context.scope, l->name->Ident.token, t_invalid, label);
	add_entity(c, c->context.scope, l->name, e);
	e->parent_proc_decl = c->context.curr_proc_decl;

	if (ok) {
		BlockLabel bl = {name, label};
		array_add(&c->context.decl->labels, bl);
	}
}

// Returns `true` for `continue`, `false` for `return`
bool check_using_stmt_entity(Checker *c, AstNodeUsingStmt *us, AstNode *expr, bool is_selector, Entity *e) {
	if (e == nullptr) {
		error(us->token, "`using` applied to an unknown entity");
		return true;
	}

	add_entity_use(c, expr, e);

	switch (e->kind) {
	case Entity_TypeName: {
		Type *t = base_type(e->type);
		if (t->kind == Type_Enum) {
			for (isize i = 0; i < t->Enum.field_count; i++) {
				Entity *f = t->Enum.fields[i];
				Entity *found = scope_insert_entity(c->context.scope, f);
				if (found != nullptr) {
					gbString expr_str = expr_to_string(expr);
					error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(found->token.string));
					gb_string_free(expr_str);
					return false;
				}
				f->using_parent = e;
			}
		} else {
			error(us->token, "`using` can be only applied to enum type entities");
		}
	} break;

	case Entity_ImportName: {
		Scope *scope = e->ImportName.scope;
		for_array(i, scope->elements.entries) {
			Entity *decl = scope->elements.entries[i].value;
			Entity *found = scope_insert_entity(c->context.scope, decl);
			if (found != nullptr) {
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
				return false;
			}
		}
	} break;

	case Entity_Variable: {
		Type *t = base_type(type_deref(e->type));
		if (is_type_struct(t) || is_type_raw_union(t) || is_type_union(t)) {
			// TODO(bill): Make it work for unions too
			Scope *found = scope_of_node(&c->info, t->Struct.node);
			for_array(i, found->elements.entries) {
				Entity *f = found->elements.entries[i].value;
				if (f->kind == Entity_Variable) {
					Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
					// if (is_selector) {
						uvar->using_expr = expr;
					// }
					Entity *prev = scope_insert_entity(c->context.scope, uvar);
					if (prev != nullptr) {
						gbString expr_str = expr_to_string(expr);
						error(us->token, "Namespace collision while `using` `%s` of: %.*s", expr_str, LIT(prev->token.string));
						gb_string_free(expr_str);
						return false;
					}
				}
			}
		} else {
			error(us->token, "`using` can only be applied to variables of type struct or raw_union");
			return false;
		}
	} break;

	case Entity_Constant:
		error(us->token, "`using` cannot be applied to a constant");
		break;

	case Entity_Procedure:
	case Entity_Builtin:
		error(us->token, "`using` cannot be applied to a procedure");
		break;

	case Entity_Nil:
		error(us->token, "`using` cannot be applied to `nil`");
		break;

	case Entity_Label:
		error(us->token, "`using` cannot be applied to a label");
		break;

	case Entity_Invalid:
		error(us->token, "`using` cannot be applied to an invalid entity");
		break;

	default:
		GB_PANIC("TODO(bill): `using` other expressions?");
	}

	return true;
}

void check_stmt_internal(Checker *c, AstNode *node, u32 flags) {
	u32 mod_flags = flags & (~Stmt_FallthroughAllowed);
	switch (node->kind) {
	case_ast_node(_, EmptyStmt, node); case_end;
	case_ast_node(_, BadStmt,   node); case_end;
	case_ast_node(_, BadDecl,   node); case_end;

	case_ast_node(es, ExprStmt, node)
		Operand operand = {Addressing_Invalid};
		ExprKind kind = check_expr_base(c, &operand, es->expr, nullptr);
		switch (operand.mode) {
		case Addressing_Type: {
			gbString str = type_to_string(operand.type);
			error(node, "`%s` is not an expression", str);
			gb_string_free(str);
		} break;
		case Addressing_NoValue:
			return;
		default: {
			if (kind == Expr_Stmt) {
				return;
			}
			if (operand.expr->kind == AstNode_CallExpr) {
				AstNodeCallExpr *ce = &operand.expr->CallExpr;
				Type *t = type_of_expr(&c->info, ce->proc);
				if (is_type_proc(t)) {
					if (t->Proc.require_results) {
						gbString expr_str = expr_to_string(ce->proc);
						error(node, "`%s` requires that its results must be handled", expr_str);
						gb_string_free(expr_str);
					}
				}
				return;
			}
			gbString expr_str = expr_to_string(operand.expr);
			error(node, "Expression is not used: `%s`", expr_str);
			gb_string_free(expr_str);
		} break;
		}
	case_end;

	case_ast_node(ts, TagStmt, node);
		// TODO(bill): Tag Statements
		error(node, "Tag statements are not supported yet");
		check_stmt(c, ts->stmt, flags);
	case_end;

	#if 0
	case_ast_node(s, IncDecStmt, node);
		TokenKind op = s->op.kind;
		switch (op) {
		case Token_Inc: op = Token_Add; break;
		case Token_Dec: op = Token_Sub; break;
		default:
			error(node, "Invalid inc/dec operation");
			return;
		}

		Operand x = {};
		check_expr(c, &x, s->expr);
		if (x.mode == Addressing_Invalid) {
			return;
		}
		if (!is_type_integer(x.type) && !is_type_float(x.type)) {
			gbString e = expr_to_string(s->expr);
			gbString t = type_to_string(x.type);
			error(node, "%s%.*s used on non-numeric type %s", e, LIT(s->op.string), t);
			gb_string_free(t);
			gb_string_free(e);
			return;
		}
		AstNode *left = s->expr;
		AstNode *right = gb_alloc_item(c->allocator, AstNode);
		right->kind = AstNode_BasicLit;
		right->BasicLit.pos = s->op.pos;
		right->BasicLit.kind = Token_Integer;
		right->BasicLit.string = str_lit("1");

		AstNode *be = gb_alloc_item(c->allocator, AstNode);
		be->kind = AstNode_BinaryExpr;
		be->BinaryExpr.op = s->op;
		be->BinaryExpr.op.kind = op;
		be->BinaryExpr.left = left;
		be->BinaryExpr.right = right;
		check_binary_expr(c, &x, be);
		if (x.mode == Addressing_Invalid) {
			return;
		}
		check_assignment_variable(c, &x, left);
	case_end;
	#endif

	case_ast_node(as, AssignStmt, node);
		switch (as->op.kind) {
		case Token_Eq: {
			// a, b, c = 1, 2, 3;  // Multisided

			isize lhs_count = as->lhs.count;
			if (lhs_count == 0) {
				error(as->op, "Missing lhs in assignment statement");
				return;
			}

			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
			defer (gb_temp_arena_memory_end(tmp));

			// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
			// an extra allocation
			Array<Operand> operands = {};
			array_init(&operands, c->tmp_allocator, 2 * lhs_count);
			check_unpack_arguments(c, nullptr, lhs_count, &operands, as->rhs, true);

			isize rhs_count = operands.count;
			for_array(i, operands) {
				if (operands[i].mode == Addressing_Invalid) {
					rhs_count--;
				}
			}

			isize max = gb_min(lhs_count, rhs_count);
			for (isize i = 0; i < max; i++) {
				check_assignment_variable(c, &operands[i], as->lhs[i]);
			}
			if (lhs_count != rhs_count) {
				error(as->lhs[0], "Assignment count mismatch `%td` = `%td`", lhs_count, rhs_count);
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
			Operand operand = {Addressing_Invalid};
			AstNode binary_expr = {AstNode_BinaryExpr};
			ast_node(be, BinaryExpr, &binary_expr);
			be->op = op;
			be->op.kind = cast(TokenKind)(cast(i32)be->op.kind - (Token_AddEq - Token_Add));
			 // NOTE(bill): Only use the first one will be used
			be->left  = as->lhs[0];
			be->right = as->rhs[0];

			check_binary_expr(c, &operand, &binary_expr);
			if (operand.mode == Addressing_Invalid) {
				return;
			}
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

		if (is->init != nullptr) {
			check_stmt(c, is->init, 0);
		}

		Operand operand = {Addressing_Invalid};
		check_expr(c, &operand, is->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error(is->cond, "Non-boolean condition in `if` statement");
		}

		check_stmt(c, is->body, mod_flags);

		if (is->else_stmt != nullptr) {
			switch (is->else_stmt->kind) {
			case AstNode_IfStmt:
			case AstNode_BlockStmt:
				check_stmt(c, is->else_stmt, mod_flags);
				break;
			default:
				error(is->else_stmt, "Invalid `else` statement in `if` statement");
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

		if (c->context.in_defer) {
			error(rs->token, "You cannot `return` within a defer statement");
			break;
		}

		bool first_is_field_value = false;
		if (rs->results.count > 0) {
			bool fail = false;
			first_is_field_value = (rs->results[0]->kind == AstNode_FieldValue);
			for_array(i, rs->results) {
				AstNode *arg = rs->results[i];
				bool mix = false;
				if (first_is_field_value) {
					mix = arg->kind != AstNode_FieldValue;
				} else {
					mix = arg->kind == AstNode_FieldValue;
				}
				if (mix) {
					error(arg, "Mixture of `field = value` and value elements in a procedure all is not allowed");
					fail = true;
				}
			}

			if (fail) {
				return;
			}
		}


		Type *proc_type = c->proc_stack[c->proc_stack.count-1];
		TypeProc *pt = &proc_type->Proc;
		isize result_count = 0;
		if (pt->results) {
			result_count = proc_type->Proc.results->Tuple.variables.count;
		}


		isize result_count_excluding_defaults = result_count;
		for (isize i = result_count-1; i >= 0; i--) {
			Entity *e = pt->results->Tuple.variables[i];
			if (e->kind == Entity_TypeName) {
				break;
			}

			GB_ASSERT(e->kind == Entity_Variable);
			if (e->Variable.default_value.kind != ExactValue_Invalid ||
			    e->Variable.default_is_nil) {
				result_count_excluding_defaults--;
				continue;
			}
			break;
		}

		Array<Operand> operands = {};
		defer (array_free(&operands));

		if (first_is_field_value) {
			array_init_count(&operands, heap_allocator(), rs->results.count);
			for_array(i, rs->results) {
				AstNode *arg = rs->results[i];
				ast_node(fv, FieldValue, arg);
				check_expr(c, &operands[i], fv->value);
			}
		} else {
			array_init(&operands, heap_allocator(), 2*rs->results.count);
			check_unpack_arguments(c, nullptr, -1, &operands, rs->results, false);
		}


		if (first_is_field_value) {
			bool *visited = gb_alloc_array(c->allocator, bool, result_count);

			for_array(i, rs->results) {
				AstNode *arg = rs->results[i];
				ast_node(fv, FieldValue, arg);
				if (fv->field->kind != AstNode_Ident) {
					gbString expr_str = expr_to_string(fv->field);
					error(arg, "Invalid parameter name `%s` in return statement", expr_str);
					gb_string_free(expr_str);
					continue;
				}
				String name = fv->field->Ident.token.string;
				isize index = lookup_procedure_result(pt, name);
				if (index < 0) {
					error(arg, "No result named `%.*s` for this procedure type", LIT(name));
					continue;
				}
				if (visited[index]) {
					error(arg, "Duplicate result `%.*s` in return statement", LIT(name));
					continue;
				}

				visited[index] = true;
				Operand *o = &operands[i];
				Entity *e = pt->results->Tuple.variables[index];
				check_assignment(c, &operands[i], e->type, str_lit("return statement"));
			}

			for (isize i = 0; i < result_count; i++) {
				if (!visited[i]) {
					Entity *e = pt->results->Tuple.variables[i];
					if (is_blank_ident(e->token)) {
						continue;
					}
					GB_ASSERT(e->kind == Entity_Variable);
					if (e->Variable.default_value.kind != ExactValue_Invalid) {
						continue;
					}

					if (e->Variable.default_is_nil) {
						continue;
					}

					gbString str = type_to_string(e->type);
					error(node, "Return value `%.*s` of type `%s` is missing in return statement",
					      LIT(e->token.string), str);
					gb_string_free(str);
				}
			}

		} else if (result_count == 0 && rs->results.count > 0) {
			error(rs->results[0], "No return values expected");
		} else if (operands.count > result_count) {
			if (result_count_excluding_defaults < result_count) {
				error(node, "Expected a maximum of %td return values, got %td", result_count, operands.count);
			} else {
				error(node, "Expected %td return values, got %td", result_count, operands.count);
			}
		} else if (operands.count < result_count_excluding_defaults) {
			if (result_count_excluding_defaults < result_count) {
				error(node, "Expected a minimum of %td return values, got %td", result_count_excluding_defaults, operands.count);
			} else {
				error(node, "Expected %td return values, got %td", result_count_excluding_defaults, operands.count);
			}
		} else {
			isize max_count = rs->results.count;
			for (isize i = 0; i < max_count; i++) {
				Entity *e = pt->results->Tuple.variables[i];
				check_assignment(c, &operands[i], e->type, str_lit("return statement"));
			}
		}

	case_end;

	case_ast_node(fs, ForStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;

		check_open_scope(c, node);
		check_label(c, fs->label); // TODO(bill): What should the label's "scope" be?

		if (fs->init != nullptr) {
			check_stmt(c, fs->init, 0);
		}
		if (fs->cond != nullptr) {
			Operand o = {Addressing_Invalid};
			check_expr(c, &o, fs->cond);
			if (o.mode != Addressing_Invalid && !is_type_boolean(o.type)) {
				error(fs->cond, "Non-boolean condition in `for` statement");
			}
		}
		if (fs->post != nullptr) {
			check_stmt(c, fs->post, 0);

			if (fs->post->kind != AstNode_AssignStmt &&
			    fs->post->kind != AstNode_IncDecStmt) {
				error(fs->post, "`for` statement post statement must be a simple statement");
			}
		}
		check_stmt(c, fs->body, new_flags);

		check_close_scope(c);
	case_end;

	case_ast_node(rs, RangeStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;

		check_open_scope(c, node);
		check_label(c, rs->label);

		Type *val = nullptr;
		Type *idx = nullptr;
		Entity *entities[2] = {};
		isize entity_count = 0;

		AstNode *expr = unparen_expr(rs->expr);


		if (is_ast_node_a_range(expr)) {
			ast_node(ie, BinaryExpr, expr);
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

				TokenKind op = Token_Lt;
				switch (ie->op.kind) {
				case Token_Ellipsis:   op = Token_LtEq; break;
				case Token_HalfClosed: op = Token_Lt; break;
				default: error(ie->op, "Invalid range operator"); break;
				}
				bool ok = compare_exact_values(op, a, b);
				if (!ok) {
					// TODO(bill): Better error message
					error(ie->op, "Invalid interval range");
					goto skip_expr;
				}
			}

			if (x.mode != Addressing_Constant) {
				x.value = empty_exact_value;
			}
			if (y.mode != Addressing_Constant) {
				y.value = empty_exact_value;
			}


			add_type_and_value(&c->info, ie->left,  x.mode, x.type, x.value);
			add_type_and_value(&c->info, ie->right, y.mode, y.type, y.value);
			val = type;
			idx = t_int;
		} else {
			Operand operand = {Addressing_Invalid};
			check_expr_or_type(c, &operand, rs->expr);

			if (operand.mode == Addressing_Type) {
				if (!is_type_enum(operand.type)) {
					gbString t = type_to_string(operand.type);
					error(operand.expr, "Cannot iterate over the type `%s`", t);
					gb_string_free(t);
					goto skip_expr;
				} else {
					val = operand.type;
					idx = t_int;
					add_type_info_type(c, operand.type);
					goto skip_expr;
				}
			} else if (operand.mode != Addressing_Invalid) {
				bool is_ptr = is_type_pointer(operand.type);
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

				case Type_DynamicArray:
					val = t->DynamicArray.elem;
					idx = t_int;
					break;

				case Type_Slice:
					val = t->Slice.elem;
					idx = t_int;
					break;

				case Type_Vector:
					val = t->Vector.elem;
					idx = t_int;
					break;

				case Type_Map:
					val = t->Map.value;
					idx = t->Map.key;
					break;
				}
			}

			if (val == nullptr) {
				gbString s = expr_to_string(operand.expr);
				gbString t = type_to_string(operand.type);
				error(operand.expr, "Cannot iterate over `%s` of type `%s`", s, t);
				gb_string_free(t);
				gb_string_free(s);
			}
		}

	skip_expr:; // NOTE(zhiayang): again, declaring a variable immediately after a label... weird.
		AstNode *lhs[2] = {rs->value, rs->index};
		Type *   rhs[2] = {val, idx};

		for (isize i = 0; i < 2; i++) {
			if (lhs[i] == nullptr) {
				continue;
			}
			AstNode *name = lhs[i];
			Type *   type = rhs[i];

			Entity *entity = nullptr;
			if (name->kind == AstNode_Ident) {
				Token token = name->Ident.token;
				String str = token.string;
				Entity *found = nullptr;

				if (!is_blank_ident(str)) {
					found = current_scope_lookup_entity(c->context.scope, str);
				}
				if (found == nullptr) {
					bool is_immutable = true;
					entity = make_entity_variable(c->allocator, c->context.scope, token, type, is_immutable);
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
				error(name, "A variable declaration must be an identifier");
			}

			if (entity == nullptr) {
				entity = make_entity_dummy_variable(c->allocator, c->global_scope, ast_node_token(name));
			}

			entities[entity_count++] = entity;

			if (type == nullptr) {
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
		Operand x = {};

		mod_flags |= Stmt_BreakAllowed;
		check_open_scope(c, node);
		check_label(c, ms->label); // TODO(bill): What should the label's "scope" be?

		if (ms->init != nullptr) {
			check_stmt(c, ms->init, 0);
		}
		if (ms->tag != nullptr) {
			check_expr(c, &x, ms->tag);
			check_assignment(c, &x, nullptr, str_lit("match expression"));
		} else {
			x.mode  = Addressing_Constant;
			x.type  = t_bool;
			x.value = exact_value_bool(true);

			Token token  = {};
			token.pos    = ast_node_token(ms->body).pos;
			token.string = str_lit("true");
			x.expr       = ast_ident(c->curr_ast_file, token);
		}
		if (is_type_vector(x.type)) {
			gbString str = type_to_string(x.type);
			error(x.expr, "Invalid match expression type: %s", str);
			gb_string_free(str);
			break;
		}


		// NOTE(bill): Check for multiple defaults
		AstNode *first_default = nullptr;
		ast_node(bs, BlockStmt, ms->body);
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			AstNode *default_stmt = nullptr;
			if (stmt->kind == AstNode_CaseClause) {
				ast_node(cc, CaseClause, stmt);
				if (cc->list.count == 0) {
					default_stmt = stmt;
				}
			} else {
				error(stmt, "Invalid AST - expected case clause");
			}

			if (default_stmt != nullptr) {
				if (first_default != nullptr) {
					TokenPos pos = ast_node_token(first_default).pos;
					error(stmt,
					           "multiple `default` clauses\n"
					           "\tfirst at %.*s(%td:%td)",
					           LIT(pos.file), pos.line, pos.column);
				} else {
					first_default = default_stmt;
				}
			}
		}

		Map<TypeAndToken> seen = {}; // NOTE(bill): Multimap
		map_init(&seen, heap_allocator());

		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			if (stmt->kind != AstNode_CaseClause) {
				// NOTE(bill): error handled by above multiple default checker
				continue;
			}
			ast_node(cc, CaseClause, stmt);

			for_array(j, cc->list) {
				AstNode *expr = unparen_expr(cc->list[j]);

				if (is_ast_node_a_range(expr)) {
					ast_node(ie, BinaryExpr, expr);
					Operand lhs = {};
					Operand rhs = {};
					check_expr(c, &lhs, ie->left);
					if (x.mode == Addressing_Invalid) {
						continue;
					}
					if (lhs.mode == Addressing_Invalid) {
						continue;
					}
					check_expr(c, &rhs, ie->right);
					if (rhs.mode == Addressing_Invalid) {
						continue;
					}

					if (!is_type_ordered(x.type)) {
						gbString str = type_to_string(x.type);
						error(x.expr, "Unordered type `%s`, is invalid for an interval expression", str);
						gb_string_free(str);
						continue;
					}


					TokenKind op = Token_Invalid;

					Operand a = lhs;
					Operand b = rhs;
					check_comparison(c, &a, &x, Token_LtEq);
					if (a.mode == Addressing_Invalid) {
						continue;
					}
					switch (ie->op.kind) {
					case Token_Ellipsis:   op = Token_GtEq; break;
					case Token_HalfClosed: op = Token_Gt;   break;
					default: error(ie->op, "Invalid interval operator"); continue;
					}

					check_comparison(c, &b, &x, op);
					if (b.mode == Addressing_Invalid) {
						continue;
					}

					switch (ie->op.kind) {
					case Token_Ellipsis:   op = Token_LtEq; break;
					case Token_HalfClosed: op = Token_Lt;   break;
					default: error(ie->op, "Invalid interval operator"); continue;
					}

					Operand a1 = lhs;
					Operand b1 = rhs;
					check_comparison(c, &a1, &b1, op);
				} else {
					Operand y = {};
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
						TypeAndToken *found = map_get(&seen, key);
						if (found != nullptr) {
							gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
							defer (gb_temp_arena_memory_end(tmp));

							isize count = multi_map_count(&seen, key);
							TypeAndToken *taps = gb_alloc_array(c->tmp_allocator, TypeAndToken, count);

							multi_map_get_all(&seen, key, taps);
							bool continue_outer = false;

							for (isize i = 0; i < count; i++) {
								TypeAndToken tap = taps[i];
								if (are_types_identical(y.type, tap.type)) {
									TokenPos pos = tap.token.pos;
									gbString expr_str = expr_to_string(y.expr);
									error(y.expr,
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
			}

			check_open_scope(c, stmt);
			u32 ft_flags = mod_flags;
			if (i+1 < bs->stmts.count) {
				ft_flags |= Stmt_FallthroughAllowed;
			}
			check_stmt_list(c, cc->stmts, ft_flags);
			check_close_scope(c);
		}

		map_destroy(&seen);

		check_close_scope(c);
	case_end;

	case_ast_node(ms, TypeMatchStmt, node);
		Operand x = {};

		mod_flags |= Stmt_BreakAllowed;
		check_open_scope(c, node);
		check_label(c, ms->label); // TODO(bill): What should the label's "scope" be?

		MatchTypeKind match_type_kind = MatchType_Invalid;

		if (ms->tag->kind != AstNode_AssignStmt) {
			error(ms->tag, "Expected an `in` assignment for this type match statement");
			break;
		}

		ast_node(as, AssignStmt, ms->tag);
		Token as_token = ast_node_token(ms->tag);
		if (as->lhs.count != 1) {
			syntax_error(as_token, "Expected 1 name before `in`");
			break;
		}
		if (as->rhs.count != 1) {
			syntax_error(as_token, "Expected 1 expression after `in`");
			break;
		}
		AstNode *lhs = as->lhs[0];
		AstNode *rhs = as->rhs[0];

		check_expr(c, &x, rhs);
		check_assignment(c, &x, nullptr, str_lit("type match expression"));
		match_type_kind = check_valid_type_match_type(x.type);
		if (check_valid_type_match_type(x.type) == MatchType_Invalid) {
			gbString str = type_to_string(x.type);
			error(x.expr, "Invalid type for this type match expression, got `%s`", str);
			gb_string_free(str);
			break;
		}

		bool is_ptr = is_type_pointer(x.type);

		// NOTE(bill): Check for multiple defaults
		AstNode *first_default = nullptr;
		ast_node(bs, BlockStmt, ms->body);
		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			AstNode *default_stmt = nullptr;
			if (stmt->kind == AstNode_CaseClause) {
				ast_node(cc, CaseClause, stmt);
				if (cc->list.count == 0) {
					default_stmt = stmt;
				}
			} else {
				error(stmt, "Invalid AST - expected case clause");
			}

			if (default_stmt != nullptr) {
				if (first_default != nullptr) {
					TokenPos pos = ast_node_token(first_default).pos;
					error(stmt,
					           "Multiple `default` clauses\n"
					           "\tfirst at %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
				} else {
					first_default = default_stmt;
				}
			}
		}


		if (lhs->kind != AstNode_Ident) {
			error(rhs, "Expected an identifier, got `%.*s`", LIT(ast_node_strings[rhs->kind]));
			break;
		}


		Map<bool> seen = {}; // Multimap
		map_init(&seen, heap_allocator());

		for_array(i, bs->stmts) {
			AstNode *stmt = bs->stmts[i];
			if (stmt->kind != AstNode_CaseClause) {
				// NOTE(bill): error handled by above multiple default checker
				continue;
			}
			ast_node(cc, CaseClause, stmt);

			// TODO(bill): Make robust
			Type *bt = base_type(type_deref(x.type));

			Type *case_type = nullptr;
			for_array(type_index, cc->list) {
				AstNode *type_expr = cc->list[type_index];
				if (type_expr != nullptr) { // Otherwise it's a default expression
					Operand y = {};
					check_expr_or_type(c, &y, type_expr);

					if (match_type_kind == MatchType_Union) {
						GB_ASSERT(is_type_union(bt));
						bool tag_type_found = false;
						for_array(i, bt->Union.variants) {
							Type *vt = bt->Union.variants[i];
							if (are_types_identical(vt, y.type)) {
								tag_type_found = true;
								break;
							}
						}
						if (!tag_type_found) {
							gbString type_str = type_to_string(y.type);
							error(y.expr, "Unknown tag type, got `%s`", type_str);
							gb_string_free(type_str);
							continue;
						}
						case_type = y.type;
					} else if (match_type_kind == MatchType_Any) {
						case_type = y.type;
					} else {
						GB_PANIC("Unknown type to type match statement");
					}

					HashKey key = hash_type(y.type);
					bool *found = map_get(&seen, key);
					if (found) {
						TokenPos pos = cc->token.pos;
						gbString expr_str = expr_to_string(y.expr);
						error(y.expr,
						           "Duplicate type case `%s`\n"
						           "\tprevious type case at %.*s(%td:%td)",
						           expr_str,
						           LIT(pos.file), pos.line, pos.column);
						gb_string_free(expr_str);
						break;
					}
					map_set(&seen, key, cast(bool)true);
				}
			}

			if (is_ptr &&
			    !is_type_any(type_deref(x.type)) &&
			    cc->list.count == 1 &&
			    case_type != nullptr) {
				case_type = make_type_pointer(c->allocator, case_type);
			}

			if (cc->list.count > 1) {
				case_type = nullptr;
			}
			if (case_type == nullptr) {
				case_type = x.type;
			}
			add_type_info_type(c, case_type);

			check_open_scope(c, stmt);
			{
				Entity *tag_var = make_entity_variable(c->allocator, c->context.scope, lhs->Ident.token, case_type, false);
				tag_var->flags |= EntityFlag_Used;
				tag_var->flags |= EntityFlag_Value;
				add_entity(c, c->context.scope, lhs, tag_var);
				add_entity_use(c, lhs, tag_var);
				add_implicit_entity(c, stmt, tag_var);
			}
			check_stmt_list(c, cc->stmts, mod_flags);
			check_close_scope(c);
		}
		map_destroy(&seen);

		check_close_scope(c);
	case_end;


	case_ast_node(ds, DeferStmt, node);
		if (is_ast_node_decl(ds->stmt)) {
			error(ds->token, "You cannot defer a declaration");
		} else {
			bool out_in_defer = c->context.in_defer;
			c->context.in_defer = true;
			check_stmt(c, ds->stmt, 0);
			c->context.in_defer = out_in_defer;
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

		if (bs->label != nullptr) {
			if (bs->label->kind != AstNode_Ident) {
				error(bs->label, "A branch statement's label name must be an identifier");
				return;
			}
			AstNode *ident = bs->label;
			String name = ident->Ident.token.string;
			Operand o = {};
			Entity *e = check_ident(c, &o, ident, nullptr, nullptr, false);
			if (e == nullptr) {
				error(ident, "Undeclared label name: %.*s", LIT(name));
				return;
			}
			add_entity_use(c, ident, e);
			if (e->kind != Entity_Label) {
				error(ident, "`%.*s` is not a label", LIT(name));
				return;
			}
		}

	case_end;

	case_ast_node(us, UsingStmt, node);
		if (us->list.count == 0) {
			error(us->token, "Empty `using` list");
			return;
		}
		for_array(i, us->list) {
			AstNode *expr = unparen_expr(us->list[0]);
			Entity *e = nullptr;

			bool is_selector = false;
			Operand o = {};
			switch (expr->kind) {
			case AstNode_Ident:
				e = check_ident(c, &o, expr, nullptr, nullptr, true);
				break;
			case AstNode_SelectorExpr:
				e = check_selector(c, &o, expr, nullptr);
				is_selector = true;
				break;
			case AstNode_Implicit:
				error(us->token, "`using` applied to an implicit value");
				continue;
			default:
				error(us->token, "`using` can only be applied to an entity, got %.*s", LIT(ast_node_strings[expr->kind]));
				continue;
			}

			if (!check_using_stmt_entity(c, us, expr, is_selector, e)) {
				return;
			}
		}
	case_end;


	case_ast_node(pa, PushAllocator, node);
		Operand op = {};
		check_expr(c, &op, pa->expr);
		check_assignment(c, &op, t_allocator, str_lit("argument to push_allocator"));
		check_stmt(c, pa->body, mod_flags);
	case_end;


	case_ast_node(pa, PushContext, node);
		Operand op = {};
		check_expr(c, &op, pa->expr);
		check_assignment(c, &op, t_context, str_lit("argument to push_context"));
		check_stmt(c, pa->body, mod_flags);
	case_end;

	case_ast_node(fb, ForeignBlockDecl, node);
		AstNode *foreign_library = fb->foreign_library;
		bool ok = true;
		if (foreign_library->kind != AstNode_Ident) {
			error(foreign_library, "foreign library name must be an identifier");
			ok = false;
		}

		CheckerContext prev_context = c->context;
		if (ok) {
			c->context.curr_foreign_library = foreign_library;
		}

		for_array(i, fb->decls) {
			AstNode *decl = fb->decls[i];
			if (decl->kind == AstNode_ValueDecl && decl->ValueDecl.is_mutable) {
				check_stmt(c, decl, flags);
			}
		}

		c->context = prev_context;
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (!vd->is_mutable) {
			break;
		}
		Entity **entities = gb_alloc_array(c->allocator, Entity *, vd->names.count);
		isize entity_count = 0;

		if (vd->flags & VarDeclFlag_thread_local) {
			vd->flags &= ~VarDeclFlag_thread_local;
			error(node, "`thread_local` may only be applied to a variable declaration");
		}

		for_array(i, vd->names) {
			AstNode *name = vd->names[i];
			Entity *entity = nullptr;
			if (name->kind != AstNode_Ident) {
				error(name, "A variable declaration must be an identifier");
			} else {
				Token token = name->Ident.token;
				String str = token.string;
				Entity *found = nullptr;
				// NOTE(bill): Ignore assignments to `_`
				if (!is_blank_ident(str)) {
					found = current_scope_lookup_entity(c->context.scope, str);
				}
				if (found == nullptr) {
					entity = make_entity_variable(c->allocator, c->context.scope, token, nullptr, false);
					entity->identifier = name;

					AstNode *fl = c->context.curr_foreign_library;
					if (fl != nullptr) {
						GB_ASSERT(fl->kind == AstNode_Ident);
						entity->Variable.is_foreign = true;
						entity->Variable.foreign_library_ident = fl;
					}
				} else {
					TokenPos pos = found->token.pos;
					error(token,
					      "Redeclaration of `%.*s` in this scope\n"
					      "\tat %.*s(%td:%td)",
					      LIT(str), LIT(pos.file), pos.line, pos.column);
					entity = found;
				}
			}
			if (entity == nullptr) {
				entity = make_entity_dummy_variable(c->allocator, c->global_scope, ast_node_token(name));
			}
			entity->parent_proc_decl = c->context.curr_proc_decl;
			entities[entity_count++] = entity;
		}

		Type *init_type = nullptr;
		if (vd->type != nullptr) {
			init_type = check_type(c, vd->type, nullptr);
			if (init_type == nullptr) {
				init_type = t_invalid;
			} else if (is_type_polymorphic(base_type(init_type))) {
				gbString str = type_to_string(init_type);
				error(vd->type, "Invalid use of a polymorphic type `%s` in variable declaration", str);
				gb_string_free(str);
				init_type = t_invalid;
			} else if (is_type_empty_union(init_type)) {
				gbString str = type_to_string(init_type);
				error(vd->type, "An empty union `%s` cannot be instantiated in variable declaration", str);
				gb_string_free(str);
				init_type = t_invalid;
			}
		}

		for (isize i = 0; i < entity_count; i++) {
			Entity *e = entities[i];
			GB_ASSERT(e != nullptr);
			if (e->flags & EntityFlag_Visited) {
				e->type = t_invalid;
				continue;
			}
			e->flags |= EntityFlag_Visited;

			if (e->type == nullptr) {
				e->type = init_type;
			}
		}

		check_arity_match(c, vd);
		check_init_variables(c, entities, entity_count, vd->values, str_lit("variable declaration"));

		for (isize i = 0; i < entity_count; i++) {
			Entity *e = entities[i];
			if (e->Variable.is_foreign) {
				if (vd->values.count > 0) {
					error(e->token, "A foreign variable declaration cannot have a default value");
				}
				init_entity_foreign_library(c, e);

				String name = e->token.string;
				auto *fp = &c->info.foreigns;
				HashKey key = hash_string(name);
				Entity **found = map_get(fp, key);
				if (found) {
					Entity *f = *found;
					TokenPos pos = f->token.pos;
					Type *this_type = base_type(e->type);
					Type *other_type = base_type(f->type);
					if (!are_types_identical(this_type, other_type)) {
						error(e->token,
						      "Foreign entity `%.*s` previously declared elsewhere with a different type\n"
						      "\tat %.*s(%td:%td)",
						      LIT(name), LIT(pos.file), pos.line, pos.column);
					}
				} else {
					map_set(fp, key, e);
				}
			}
			add_entity(c, c->context.scope, e->identifier, e);
		}

		if ((vd->flags & VarDeclFlag_using) != 0) {
			Token token = ast_node_token(node);
			if (vd->type != nullptr && entity_count > 1) {
				error(token, "`using` can only be applied to one variable of the same type");
				// TODO(bill): Should a `continue` happen here?
			}

			for (isize entity_index = 0; entity_index < entity_count; entity_index++) {
				Entity *e = entities[entity_index];
				if (e == nullptr) {
					continue;
				}
				if (e->kind != Entity_Variable) {
					continue;
				}
				bool is_immutable = e->Variable.is_immutable;
				String name = e->token.string;
				Type *t = base_type(type_deref(e->type));

				if (is_type_struct(t) || is_type_raw_union(t)) {
					Scope *scope = scope_of_node(&c->info, t->Struct.node);
					for_array(i, scope->elements.entries) {
						Entity *f = scope->elements.entries[i].value;
						if (f->kind == Entity_Variable) {
							Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
							uvar->Variable.is_immutable = is_immutable;
							Entity *prev = scope_insert_entity(c->context.scope, uvar);
							if (prev != nullptr) {
								error(token, "Namespace collision while `using` `%.*s` of: %.*s", LIT(name), LIT(prev->token.string));
								return;
							}
						}
					}
				} else {
					// NOTE(bill): skip the rest to remove extra errors
					error(token, "`using` can only be applied to variables of type struct or raw_union");
					return;
				}
			}
		}
	case_end;
	}
}
