void check_stmt_list(CheckerContext *ctx, Array<Ast *> const &stmts, u32 flags) {
	if (stmts.count == 0) {
		return;
	}

	if (flags&Stmt_CheckScopeDecls) {
		check_scope_decls(ctx, stmts, cast(isize)(1.2*stmts.count));
	}

	bool ft_ok = (flags & Stmt_FallthroughAllowed) != 0;
	flags &= ~Stmt_FallthroughAllowed;

	isize max = stmts.count;
	for (isize i = stmts.count-1; i >= 0; i--) {
		if (stmts[i]->kind != Ast_EmptyStmt) {
			break;
		}
		max--;
	}
	for (isize i = 0; i < max; i++) {
		Ast *n = stmts[i];
		if (n->kind == Ast_EmptyStmt) {
			continue;
		}
		u32 new_flags = flags;
		if (ft_ok && i+1 == max) {
			new_flags |= Stmt_FallthroughAllowed;
		}

		if (i+1 < max) {
			switch (n->kind) {
			case Ast_ReturnStmt:
				error(n, "Statements after this 'return' are never execu");
				break;

			case Ast_BranchStmt:
				error(n, "Statements after this '%.*s' are never executed", LIT(n->BranchStmt.token.string));
				break;
			}
		}

		check_stmt(ctx, n, new_flags);
	}
}

bool check_is_terminating_list(Array<Ast *> const &stmts) {
	// Iterate backwards
	for (isize n = stmts.count-1; n >= 0; n--) {
		Ast *stmt = stmts[n];
		if (stmt->kind != Ast_EmptyStmt) {
			return check_is_terminating(stmt);
		}
	}

	return false;
}

bool check_has_break_list(Array<Ast *> const &stmts, bool implicit) {
	for_array(i, stmts) {
		Ast *stmt = stmts[i];
		if (check_has_break(stmt, implicit)) {
			return true;
		}
	}
	return false;
}


bool check_has_break(Ast *stmt, bool implicit) {
	switch (stmt->kind) {
	case Ast_BranchStmt:
		if (stmt->BranchStmt.token.kind == Token_break) {
			return implicit;
		}
		break;
	case Ast_BlockStmt:
		return check_has_break_list(stmt->BlockStmt.stmts, implicit);

	case Ast_IfStmt:
		if (check_has_break(stmt->IfStmt.body, implicit) ||
		    (stmt->IfStmt.else_stmt != nullptr && check_has_break(stmt->IfStmt.else_stmt, implicit))) {
			return true;
		}
		break;

	case Ast_CaseClause:
		return check_has_break_list(stmt->CaseClause.stmts, implicit);
	}

	return false;
}



// NOTE(bill): The last expression has to be a 'return' statement
// TODO(bill): This is a mild hack and should be probably handled properly
bool check_is_terminating(Ast *node) {
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

	case_ast_node(rs, InlineRangeStmt, node);
		return false;
	case_end;

	case_ast_node(rs, RangeStmt, node);
		return false;
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		bool has_default = false;
		for_array(i, ss->body->BlockStmt.stmts) {
			Ast *clause = ss->body->BlockStmt.stmts[i];
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

	case_ast_node(ss, TypeSwitchStmt, node);
		bool has_default = false;
		for_array(i, ss->body->BlockStmt.stmts) {
			Ast *clause = ss->body->BlockStmt.stmts[i];
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
	}

	return false;
}




Type *check_assignment_variable(CheckerContext *ctx, Operand *lhs, Operand *rhs) {
	if (rhs->mode == Addressing_Invalid) {
		return nullptr;
	}
	if (rhs->type == t_invalid &&
	    rhs->mode != Addressing_ProcGroup &&
	    rhs->mode != Addressing_Builtin) {
		return nullptr;
	}

	Ast *node = unparen_expr(lhs->expr);

	// NOTE(bill): Ignore assignments to '_'
	if (is_blank_ident(node)) {
		check_assignment(ctx, rhs, nullptr, str_lit("assignment to '_' identifier"));
		if (rhs->mode == Addressing_Invalid) {
			return nullptr;
		}
		return rhs->type;
	}

	Entity *e = nullptr;
	bool used = false;

	if (lhs->mode == Addressing_Invalid ||
	    (lhs->type == t_invalid &&
	     lhs->mode != Addressing_ProcGroup &&
	     lhs->mode != Addressing_Builtin)) {
		return nullptr;
	}

	if (rhs->mode == Addressing_ProcGroup) {
		Array<Entity *> procs = proc_group_entities(ctx, *rhs);
		GB_ASSERT(procs.count > 0);

		// NOTE(bill): These should be done
		for_array(i, procs) {
			Type *t = base_type(procs[i]->type);
			if (t == t_invalid) {
				continue;
			}
			Operand x = {};
			x.mode = Addressing_Value;
			x.type = t;
			if (check_is_assignable_to(ctx, &x, lhs->type)) {
				e = procs[i];
				add_entity_use(ctx, rhs->expr, e);
				break;
			}
		}

		if (e != nullptr) {
			// HACK TODO(bill): Should the entities be freed as it's technically a leak
			rhs->mode = Addressing_Value;
			rhs->type = e->type;
			rhs->proc_group = nullptr;
		}
	} else {
		if (node->kind == Ast_Ident) {
			ast_node(i, Ident, node);
			e = scope_lookup(ctx->scope, i->token.string);
			if (e != nullptr && e->kind == Entity_Variable) {
				used = (e->flags & EntityFlag_Used) != 0; // TODO(bill): Make backup just in case
			}
		}

	}

	if (e != nullptr && used) {
		e->flags |= EntityFlag_Used;
	}

	Type *assignment_type = lhs->type;
	switch (lhs->mode) {
	case Addressing_Invalid:
		return nullptr;

	case Addressing_Variable:
		if (is_type_bit_field_value(lhs->type)) {
			Type *res = check_assignment_bit_field(ctx, rhs, lhs->type);
			if (res == nullptr) {
				gbString lhs_expr = expr_to_string(lhs->expr);
				gbString rhs_expr = expr_to_string(rhs->expr);
				error(rhs->expr, "Cannot assign '%s' to bit field '%s'", rhs_expr, lhs_expr);
				gb_string_free(rhs_expr);
				gb_string_free(lhs_expr);
			}
			return res;
		}
		break;

	case Addressing_MapIndex: {
		Ast *ln = unparen_expr(lhs->expr);
		if (ln->kind == Ast_IndexExpr) {
			Ast *x = ln->IndexExpr.expr;
			TypeAndValue tav = x->tav;
			GB_ASSERT(tav.mode != Addressing_Invalid);
			if (tav.mode != Addressing_Variable) {
				if (!is_type_pointer(tav.type)) {
					gbString str = expr_to_string(lhs->expr);
					error(lhs->expr, "Cannot assign to the value of a map '%s'", str);
					gb_string_free(str);
					return nullptr;
				}
			}
		}

		break;
	}

	case Addressing_Context: {
		break;
	}

	case Addressing_SoaVariable:
		break;

	default: {
		if (lhs->expr->kind == Ast_SelectorExpr) {
			// NOTE(bill): Extra error checks
			Operand op_c = {Addressing_Invalid};
			ast_node(se, SelectorExpr, lhs->expr);
			check_expr(ctx, &op_c, se->expr);
			if (op_c.mode == Addressing_MapIndex) {
				gbString str = expr_to_string(lhs->expr);
				error(lhs->expr, "Cannot assign to struct field '%s' in map", str);
				gb_string_free(str);
				return nullptr;
			}
		}

		Entity *e = entity_of_ident(lhs->expr);

		gbString str = expr_to_string(lhs->expr);
		if (e != nullptr && e->flags & EntityFlag_Param) {
			error(lhs->expr, "Cannot assign to '%s' which is a procedure parameter", str);
		} else {
			error(lhs->expr, "Cannot assign to '%s'", str);
		}
		gb_string_free(str);

		break;
	}
	}

	check_assignment(ctx, rhs, assignment_type, str_lit("assignment"));
	if (rhs->mode == Addressing_Invalid) {
		return nullptr;
	}

	return rhs->type;
}


void check_stmt_internal(CheckerContext *ctx, Ast *node, u32 flags);
void check_stmt(CheckerContext *ctx, Ast *node, u32 flags) {
	u32 prev_state_flags = ctx->state_flags;

	if (node->state_flags != 0) {
		u32 in = node->state_flags;
		u32 out = ctx->state_flags;

		if (in & StateFlag_no_bounds_check) {
			out |= StateFlag_no_bounds_check;
			out &= ~StateFlag_bounds_check;
		} else if (in & StateFlag_bounds_check) {
			out |= StateFlag_bounds_check;
			out &= ~StateFlag_no_bounds_check;
		}

		ctx->state_flags = out;
	}

	check_stmt_internal(ctx, node, flags);

	ctx->state_flags = prev_state_flags;
}


void check_when_stmt(CheckerContext *ctx, AstWhenStmt *ws, u32 flags) {
	Operand operand = {Addressing_Invalid};
	check_expr(ctx, &operand, ws->cond);
	if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
		error(ws->cond, "Non-constant boolean 'when' condition");
		return;
	}
	if (ws->body == nullptr || ws->body->kind != Ast_BlockStmt) {
		error(ws->cond, "Invalid body for 'when' statement");
		return;
	}
	if (operand.value.kind == ExactValue_Bool &&
	    operand.value.value_bool) {
		check_stmt_list(ctx, ws->body->BlockStmt.stmts, flags);
	} else if (ws->else_stmt) {
		switch (ws->else_stmt->kind) {
		case Ast_BlockStmt:
			check_stmt_list(ctx, ws->else_stmt->BlockStmt.stmts, flags);
			break;
		case Ast_WhenStmt:
			check_when_stmt(ctx, &ws->else_stmt->WhenStmt, flags);
			break;
		default:
			error(ws->else_stmt, "Invalid 'else' statement in 'when' statement");
			break;
		}
	}
}

void check_label(CheckerContext *ctx, Ast *label, Ast *parent) {
	if (label == nullptr) {
		return;
	}
	ast_node(l, Label, label);
	if (l->name->kind != Ast_Ident) {
		error(l->name, "A label's name must be an identifier");
		return;
	}
	String name = l->name->Ident.token.string;
	if (is_blank_ident(name)) {
		error(l->name, "A label's name cannot be a blank identifier");
		return;
	}


	if (ctx->curr_proc_decl == nullptr) {
		error(l->name, "A label is only allowed within a procedure");
		return;
	}
	GB_ASSERT(ctx->decl != nullptr);

	bool ok = true;
	for_array(i, ctx->decl->labels) {
		BlockLabel bl = ctx->decl->labels[i];
		if (bl.name == name) {
			error(label, "Duplicate label with the name '%.*s'", LIT(name));
			ok = false;
			break;
		}
	}

	Entity *e = alloc_entity_label(ctx->scope, l->name->Ident.token, t_invalid, label, parent);
	add_entity(ctx->checker, ctx->scope, l->name, e);
	e->parent_proc_decl = ctx->curr_proc_decl;

	if (ok) {
		BlockLabel bl = {name, label};
		array_add(&ctx->decl->labels, bl);
	}
}

// Returns 'true' for 'continue', 'false' for 'return'
bool check_using_stmt_entity(CheckerContext *ctx, AstUsingStmt *us, Ast *expr, bool is_selector, Entity *e) {
	if (e == nullptr) {
		error(us->token, "'using' applied to an unknown entity");
		return true;
	}

	add_entity_use(ctx, expr, e);

	switch (e->kind) {
	case Entity_TypeName: {
		Type *t = base_type(e->type);
		if (t->kind == Type_Enum) {
			for_array(i, t->Enum.fields) {
				Entity *f = t->Enum.fields[i];
				if (!is_entity_exported(f)) continue;

				Entity *found = scope_insert(ctx->scope, f);
				if (found != nullptr) {
					gbString expr_str = expr_to_string(expr);
					error(us->token, "Namespace collision while 'using' '%s' of: %.*s", expr_str, LIT(found->token.string));
					gb_string_free(expr_str);
					return false;
				}
				f->using_parent = e;
			}
		} else {
			error(us->token, "'using' can be only applied to enum type entities");
		}

		break;
	}

	case Entity_ImportName: {
		Scope *scope = e->ImportName.scope;
		for_array(i, scope->elements.entries) {
			String name = scope->elements.entries[i].key.string;
			Entity *decl = scope->elements.entries[i].value;
			if (!is_entity_exported(decl)) continue;

			Entity *found = scope_insert_with_name(ctx->scope, name, decl);
			if (found != nullptr) {
				gbString expr_str = expr_to_string(expr);
				error(us->token,
				      "Namespace collision while 'using' '%s' of: %.*s\n"
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

		break;
	}

	case Entity_Variable: {
		Type *t = base_type(type_deref(e->type));
		if (t->kind == Type_Struct) {
			// TODO(bill): Make it work for unions too
			Scope *found = scope_of_node(t->Struct.node);
			for_array(i, found->elements.entries) {
				Entity *f = found->elements.entries[i].value;
				if (f->kind == Entity_Variable) {
					Entity *uvar = alloc_entity_using_variable(e, f->token, f->type, expr);
					Entity *prev = scope_insert(ctx->scope, uvar);
					if (prev != nullptr) {
						gbString expr_str = expr_to_string(expr);
						error(us->token, "Namespace collision while using '%s' of: '%.*s'", expr_str, LIT(prev->token.string));
						gb_string_free(expr_str);
						return false;
					}
				}
			}
		} else {
			error(us->token, "'using' can only be applied to variables of type 'struct'");
			return false;
		}

		break;
	}

	case Entity_Constant:
		error(us->token, "'using' cannot be applied to a constant");
		break;

	case Entity_Procedure:
	case Entity_ProcGroup:
	case Entity_Builtin:
		error(us->token, "'using' cannot be applied to a procedure");
		break;

	case Entity_Nil:
		error(us->token, "'using' cannot be applied to 'nil'");
		break;

	case Entity_Label:
		error(us->token, "'using' cannot be applied to a label");
		break;

	case Entity_Invalid:
		error(us->token, "'using' cannot be applied to an invalid entity");
		break;

	default:
		GB_PANIC("TODO(bill): 'using' other expressions?");
	}

	return true;
}


struct TypeAndToken {
	Type *type;
	Token token;
};


void add_constant_switch_case(CheckerContext *ctx, Map<TypeAndToken> *seen, Operand operand, bool use_expr = true) {
	if (operand.mode != Addressing_Constant) {
		return;
	}
	if (operand.value.kind == ExactValue_Invalid) {
		return;
	}
	HashKey key = hash_exact_value(operand.value);
	TypeAndToken *found = map_get(seen, key);
	if (found != nullptr) {
		isize count = multi_map_count(seen, key);
		TypeAndToken *taps = gb_alloc_array(ctx->allocator, TypeAndToken, count);
		defer (gb_free(ctx->allocator, taps));

		multi_map_get_all(seen, key, taps);
		for (isize i = 0; i < count; i++) {
			TypeAndToken tap = taps[i];
			if (!are_types_identical(operand.type, tap.type)) {
				continue;
			}

			TokenPos pos = tap.token.pos;
			if (use_expr) {
				gbString expr_str = expr_to_string(operand.expr);
				error(operand.expr,
				      "Duplicate case '%s'\n"
				      "\tprevious case at %.*s(%td:%td)",
				      expr_str,
				      LIT(pos.file), pos.line, pos.column);
				gb_string_free(expr_str);
			} else {
				error(operand.expr,
				      "Duplicate case found with previous case at %.*s(%td:%td)",
				      LIT(pos.file), pos.line, pos.column);
			}
			return;
		}
	}

	TypeAndToken tap = {operand.type, ast_token(operand.expr)};
	multi_map_insert(seen, key, tap);
}

void check_inline_range_stmt(CheckerContext *ctx, Ast *node, u32 mod_flags) {
	ast_node(irs, InlineRangeStmt, node);
	check_open_scope(ctx, node);

	Type *val0 = nullptr;
	Type *val1 = nullptr;
	Entity *entities[2] = {};
	isize entity_count = 0;

	Ast *expr = unparen_expr(irs->expr);

	ExactValue inline_for_depth = exact_value_i64(0);

	if (is_ast_range(expr)) {
		ast_node(ie, BinaryExpr, expr);
		Operand x = {};
		Operand y = {};

		bool ok = check_range(ctx, expr, &x, &y, &inline_for_depth);
		if (!ok) {
			goto skip_expr;
		}

		val0 = x.type;
		val1 = t_int;
	} else {
		Operand operand = {Addressing_Invalid};
		check_expr_or_type(ctx, &operand, irs->expr);

		if (operand.mode == Addressing_Type) {
			if (!is_type_enum(operand.type)) {
				gbString t = type_to_string(operand.type);
				error(operand.expr, "Cannot iterate over the type '%s'", t);
				gb_string_free(t);
				goto skip_expr;
			} else {
				val0 = operand.type;
				val1 = t_int;
				add_type_info_type(ctx, operand.type);

				Type *bt = base_type(operand.type);
				inline_for_depth = exact_value_i64(bt->Enum.fields.count);
				goto skip_expr;
			}
		} else if (operand.mode != Addressing_Invalid) {
			Type *t = base_type(operand.type);
			switch (t->kind) {
			case Type_Basic:
				if (is_type_string(t) && t->Basic.kind != Basic_cstring) {
					val0 = t_rune;
					val1 = t_int;
					inline_for_depth = exact_value_i64(operand.value.value_string.len);
				}
				break;
			case Type_Array:
				val0 = t->Array.elem;
				val1 = t_int;
				inline_for_depth = exact_value_i64(t->Array.count);
				break;
			case Type_EnumeratedArray:
				val0 = t->EnumeratedArray.elem;
				val1 = t->EnumeratedArray.index;
				inline_for_depth = exact_value_i64(t->EnumeratedArray.count);
				break;
			}
		}

		if (val0 == nullptr) {
			gbString s = expr_to_string(operand.expr);
			gbString t = type_to_string(operand.type);
			error(operand.expr, "Cannot iterate over '%s' of type '%s' in an 'inline for' statement", s, t);
			gb_string_free(t);
			gb_string_free(s);
		} else if (operand.mode != Addressing_Constant) {
			error(operand.expr, "An 'inline for' expression must be known at compile time");
		}
	}

	skip_expr:; // NOTE(zhiayang): again, declaring a variable immediately after a label... weird.

	Ast * lhs[2] = {irs->val0, irs->val1};
	Type *rhs[2] = {val0, val1};

	for (isize i = 0; i < 2; i++) {
		if (lhs[i] == nullptr) {
			continue;
		}
		Ast * name = lhs[i];
		Type *type = rhs[i];

		Entity *entity = nullptr;
		if (name->kind == Ast_Ident) {
			Token token = name->Ident.token;
			String str = token.string;
			Entity *found = nullptr;

			if (!is_blank_ident(str)) {
				found = scope_lookup_current(ctx->scope, str);
			}
			if (found == nullptr) {
				entity = alloc_entity_variable(ctx->scope, token, type, EntityState_Resolved);
				entity->flags |= EntityFlag_Value;
				add_entity_definition(&ctx->checker->info, name, entity);
			} else {
				TokenPos pos = found->token.pos;
				error(token,
				      "Redeclaration of '%.*s' in this scope\n"
				      "\tat %.*s(%td:%td)",
				      LIT(str), LIT(pos.file), pos.line, pos.column);
				entity = found;
			}
		} else {
			error(name, "A variable declaration must be an identifier");
		}

		if (entity == nullptr) {
			entity = alloc_entity_dummy_variable(builtin_pkg->scope, ast_token(name));
		}

		entities[entity_count++] = entity;

		if (type == nullptr) {
			entity->type = t_invalid;
			entity->flags |= EntityFlag_Used;
		}
	}

	for (isize i = 0; i < entity_count; i++) {
		add_entity(ctx->checker, ctx->scope, entities[i]->identifier, entities[i]);
	}


	// NOTE(bill): Minimize the amount of nesting of an 'inline for'
	i64 prev_inline_for_depth = ctx->inline_for_depth;
	defer (ctx->inline_for_depth = prev_inline_for_depth);
	{
		i64 v = exact_value_to_i64(inline_for_depth);
		if (v <= 0) {
			// Do nothing
		} else {
			ctx->inline_for_depth = gb_max(ctx->inline_for_depth, 1) * v;
		}

		if (ctx->inline_for_depth >= MAX_INLINE_FOR_DEPTH && prev_inline_for_depth < MAX_INLINE_FOR_DEPTH) {
			if (prev_inline_for_depth > 0) {
				error(node, "Nested 'inline for' loop cannot be inlined as it exceeds the maximum inline for depth (%lld levels >= %lld maximum levels)", v, MAX_INLINE_FOR_DEPTH);
			} else {
				error(node, "'inline for' loop cannot be inlined as it exceeds the maximum inline for depth (%lld levels >= %lld maximum levels)", v, MAX_INLINE_FOR_DEPTH);
			}
			error_line("\tUse a normal 'for' loop instead by removing the 'inline' prefix\n");
			ctx->inline_for_depth = MAX_INLINE_FOR_DEPTH;
		}
	}

	check_stmt(ctx, irs->body, mod_flags);


	check_close_scope(ctx);
}

void check_switch_stmt(CheckerContext *ctx, Ast *node, u32 mod_flags) {
	ast_node(ss, SwitchStmt, node);

	Operand x = {};

	mod_flags |= Stmt_BreakAllowed | Stmt_FallthroughAllowed;
	check_open_scope(ctx, node);
	defer (check_close_scope(ctx));

	check_label(ctx, ss->label, node); // TODO(bill): What should the label's "scope" be?

	if (ss->init != nullptr) {
		check_stmt(ctx, ss->init, 0);
	}
	if (ss->tag != nullptr) {
		check_expr(ctx, &x, ss->tag);
		check_assignment(ctx, &x, nullptr, str_lit("switch expression"));
	} else {
		x.mode  = Addressing_Constant;
		x.type  = t_bool;
		x.value = exact_value_bool(true);

		Token token  = {};
		token.pos    = ast_token(ss->body).pos;
		token.string = str_lit("true");

		x.expr = gb_alloc_item(ctx->allocator, Ast);
		x.expr->kind = Ast_Ident;
		x.expr->Ident.token = token;
	}

	// NOTE(bill): Check for multiple defaults
	Ast *first_default = nullptr;
	ast_node(bs, BlockStmt, ss->body);
	for_array(i, bs->stmts) {
		Ast *stmt = bs->stmts[i];
		Ast *default_stmt = nullptr;
		if (stmt->kind == Ast_CaseClause) {
			ast_node(cc, CaseClause, stmt);
			if (cc->list.count == 0) {
				default_stmt = stmt;
			}
		} else {
			error(stmt, "Invalid AST - expected case clause");
		}

		if (default_stmt != nullptr) {
			if (first_default != nullptr) {
				TokenPos pos = ast_token(first_default).pos;
				error(stmt,
				           "multiple default clauses\n"
				           "\tfirst at %.*s(%td:%td)",
				           LIT(pos.file), pos.line, pos.column);
			} else {
				first_default = default_stmt;
			}
		}
	}

	bool is_partial = ss->partial;

	if (is_partial) {
		if (!is_type_enum(x.type)) {
			error(x.expr, "#partial switch statement can be only used with an enum type");
		}
	}

	Map<TypeAndToken> seen = {}; // NOTE(bill): Multimap, Key: ExactValue
	map_init(&seen, heap_allocator());
	defer (map_destroy(&seen));

	for_array(stmt_index, bs->stmts) {
		Ast *stmt = bs->stmts[stmt_index];
		if (stmt->kind != Ast_CaseClause) {
			// NOTE(bill): error handled by above multiple default checker
			continue;
		}
		ast_node(cc, CaseClause, stmt);

		for_array(j, cc->list) {
			Ast *expr = unparen_expr(cc->list[j]);

			if (is_ast_range(expr)) {
				ast_node(be, BinaryExpr, expr);
				Operand lhs = {};
				Operand rhs = {};
				check_expr_with_type_hint(ctx, &lhs, be->left, x.type);
				if (x.mode == Addressing_Invalid) {
					continue;
				}
				if (lhs.mode == Addressing_Invalid) {
					continue;
				}
				check_expr_with_type_hint(ctx, &rhs, be->right, x.type);
				if (rhs.mode == Addressing_Invalid) {
					continue;
				}

				if (!is_type_ordered(x.type)) {
					gbString str = type_to_string(x.type);
					error(expr, "Unordered type '%s', is invalid for an interval expression", str);
					gb_string_free(str);
					continue;
				}

				TokenKind upper_op = Token_Invalid;
				switch (be->op.kind) {
				case Token_Ellipsis:  upper_op = Token_GtEq; break;
				case Token_RangeHalf: upper_op = Token_Gt;   break;
				default: GB_PANIC("Invalid range operator"); break;
				}


				Operand a = lhs;
				Operand b = rhs;
				check_comparison(ctx, &a, &x, Token_LtEq);
				if (a.mode == Addressing_Invalid) {
					continue;
				}

				check_comparison(ctx, &b, &x, upper_op);
				if (b.mode == Addressing_Invalid) {
					continue;
				}

				Operand a1 = lhs;
				Operand b1 = rhs;
				check_comparison(ctx, &a1, &b1, Token_LtEq);

				add_constant_switch_case(ctx, &seen, lhs);
				if (upper_op == Token_GtEq) {
					add_constant_switch_case(ctx, &seen, rhs);
				}

				if (is_type_string(x.type)) {
					// NOTE(bill): Force dependency for strings here
					add_package_dependency(ctx, "runtime", "string_le");
					add_package_dependency(ctx, "runtime", "string_lt");
				}

			} else {
				Operand y = {};
				if (is_type_typeid(x.type)) {
					check_expr_or_type(ctx, &y, expr, x.type);
				} else {
					check_expr_with_type_hint(ctx, &y, expr, x.type);
				}

				if (x.mode == Addressing_Invalid ||
				    y.mode == Addressing_Invalid) {
					continue;
				}

				if (y.mode == Addressing_Type) {
					Type *t = y.type;
					if (t == nullptr || t == t_invalid || is_type_polymorphic(t)) {
						error(y.expr, "Invalid type for case clause");
						continue;
					}
					t = default_type(t);
					add_type_info_type(ctx, t);
				} else {
					convert_to_typed(ctx, &y, x.type);
					if (y.mode == Addressing_Invalid) {
						continue;
					}

					// NOTE(bill): the ordering here matters
					Operand z = y;
					check_comparison(ctx, &z, &x, Token_CmpEq);
					if (z.mode == Addressing_Invalid) {
						continue;
					}
					if (y.mode != Addressing_Constant) {
						continue;
					}

					add_constant_switch_case(ctx, &seen, y);
				}
			}
		}

		check_open_scope(ctx, stmt);
		check_stmt_list(ctx, cc->stmts, mod_flags);
		check_close_scope(ctx);
	}

	if (!is_partial && is_type_enum(x.type)) {
		Type *et = base_type(x.type);
		GB_ASSERT(is_type_enum(et));
		auto fields = et->Enum.fields;

		auto unhandled = array_make<Entity *>(ctx->allocator, 0, fields.count);
		defer (array_free(&unhandled));

		for_array(i, fields) {
			Entity *f = fields[i];
			if (f->kind != Entity_Constant) {
				continue;
			}
			ExactValue v = f->Constant.value;
			HashKey key = hash_exact_value(v);
			auto found = map_get(&seen, key);
			if (!found) {
				array_add(&unhandled, f);
			}
		}

		if (unhandled.count > 0) {
			begin_error_block();
			defer (begin_error_block());

			if (unhandled.count == 1) {
				error_no_newline(node, "Unhandled switch case: %.*s", LIT(unhandled[0]->token.string));
			} else {
				error_no_newline(node, "Unhandled switch cases: ");
				for_array(i, unhandled) {
					Entity *f = unhandled[i];
					error_line("\t%.*s\n", LIT(f->token.string));
				}
			}
			error_line("\n");

			error_line("\tSuggestion: Was '#partial switch' wanted? This replaces the previous '#complete switch'.\n");
		}
	}
}


enum TypeSwitchKind {
	TypeSwitch_Invalid,
	TypeSwitch_Union,
	TypeSwitch_Any,
};

TypeSwitchKind check_valid_type_switch_type(Type *type) {
	type = type_deref(type);
	if (is_type_union(type)) {
		return TypeSwitch_Union;
	}
	if (is_type_any(type)) {
		return TypeSwitch_Any;
	}
	return TypeSwitch_Invalid;
}

void check_type_switch_stmt(CheckerContext *ctx, Ast *node, u32 mod_flags) {
	ast_node(ss, TypeSwitchStmt, node);
	Operand x = {};

	mod_flags |= Stmt_BreakAllowed;
	check_open_scope(ctx, node);
	defer (check_close_scope(ctx));

	check_label(ctx, ss->label, node); // TODO(bill): What should the label's "scope" be?

	if (ss->tag->kind != Ast_AssignStmt) {
		error(ss->tag, "Expected an 'in' assignment for this type switch statement");
		return;
	}

	ast_node(as, AssignStmt, ss->tag);
	Token as_token = ast_token(ss->tag);
	if (as->lhs.count != 1) {
		syntax_error(as_token, "Expected 1 name before 'in'");
		return;
	}
	if (as->rhs.count != 1) {
		syntax_error(as_token, "Expected 1 expression after 'in'");
		return;
	}
	Ast *lhs = as->lhs[0];
	Ast *rhs = as->rhs[0];

	check_expr(ctx, &x, rhs);
	check_assignment(ctx, &x, nullptr, str_lit("type switch expression"));
	add_type_info_type(ctx, x.type);

	TypeSwitchKind switch_kind = check_valid_type_switch_type(x.type);
	if (switch_kind == TypeSwitch_Invalid) {
		gbString str = type_to_string(x.type);
		error(x.expr, "Invalid type for this type switch expression, got '%s'", str);
		gb_string_free(str);
		return;
	}

	bool is_partial = ss->partial;
	if (is_partial) {
		if (switch_kind != TypeSwitch_Union) {
			error(node, "#partial switch statement may only be used with a union");
		}
	}

	bool is_ptr = is_type_pointer(x.type);

	// NOTE(bill): Check for multiple defaults
	Ast *first_default = nullptr;
	ast_node(bs, BlockStmt, ss->body);
	for_array(i, bs->stmts) {
		Ast *stmt = bs->stmts[i];
		Ast *default_stmt = nullptr;
		if (stmt->kind == Ast_CaseClause) {
			ast_node(cc, CaseClause, stmt);
			if (cc->list.count == 0) {
				default_stmt = stmt;
			}
		} else {
			error(stmt, "Invalid AST - expected case clause");
		}

		if (default_stmt != nullptr) {
			if (first_default != nullptr) {
				TokenPos pos = ast_token(first_default).pos;
				error(stmt,
				      "Multiple default clauses\n"
				      "\tfirst at %.*s(%td:%td)",
				      LIT(pos.file), pos.line, pos.column);
			} else {
				first_default = default_stmt;
			}
		}
	}

	if (lhs->kind != Ast_Ident) {
		error(rhs, "Expected an identifier, got '%.*s'", LIT(ast_strings[rhs->kind]));
		return;
	}

	PtrSet<Type *> seen = {};
	ptr_set_init(&seen, heap_allocator());
	defer (ptr_set_destroy(&seen));

	for_array(i, bs->stmts) {
		Ast *stmt = bs->stmts[i];
		if (stmt->kind != Ast_CaseClause) {
			// NOTE(bill): error handled by above multiple default checker
			continue;
		}
		ast_node(cc, CaseClause, stmt);

		// TODO(bill): Make robust
		Type *bt = base_type(type_deref(x.type));

		Type *case_type = nullptr;
		for_array(type_index, cc->list) {
			Ast *type_expr = cc->list[type_index];
			if (type_expr != nullptr) { // Otherwise it's a default expression
				Operand y = {};
				check_expr_or_type(ctx, &y, type_expr);

				if (switch_kind == TypeSwitch_Union) {
					GB_ASSERT(is_type_union(bt));
					bool tag_type_found = false;
					for_array(j, bt->Union.variants) {
						Type *vt = bt->Union.variants[j];
						if (are_types_identical(vt, y.type)) {
							tag_type_found = true;
							break;
						}
					}
					if (!tag_type_found) {
						gbString type_str = type_to_string(y.type);
						error(y.expr, "Unknown variant type, got '%s'", type_str);
						gb_string_free(type_str);
						continue;
					}
					case_type = y.type;
					add_type_info_type(ctx, y.type);
				} else if (switch_kind == TypeSwitch_Any) {
					case_type = y.type;
					add_type_info_type(ctx, y.type);
				} else {
					GB_PANIC("Unknown type to type switch statement");
				}

				if (type_ptr_set_exists(&seen, y.type)) {
					TokenPos pos = cc->token.pos;
					gbString expr_str = expr_to_string(y.expr);
					error(y.expr,
					           "Duplicate type case '%s'\n"
					           "\tprevious type case at %.*s(%td:%td)",
					           expr_str,
					           LIT(pos.file), pos.line, pos.column);
					gb_string_free(expr_str);
					break;
				}
				ptr_set_add(&seen, y.type);
			}
		}

		if (is_ptr &&
		    cc->list.count == 1 &&
		    case_type != nullptr) {
			case_type = alloc_type_pointer(case_type);
		}

		if (cc->list.count > 1) {
			case_type = nullptr;
		}
		if (case_type == nullptr) {
			case_type = x.type;
		}
		add_type_info_type(ctx, case_type);

		check_open_scope(ctx, stmt);
		{
			Entity *tag_var = alloc_entity_variable(ctx->scope, lhs->Ident.token, case_type, EntityState_Resolved);
			tag_var->flags |= EntityFlag_Used;
			tag_var->flags |= EntityFlag_Value;
			add_entity(ctx->checker, ctx->scope, lhs, tag_var);
			add_entity_use(ctx, lhs, tag_var);
			add_implicit_entity(ctx, stmt, tag_var);
		}
		check_stmt_list(ctx, cc->stmts, mod_flags);
		check_close_scope(ctx);
	}

	if (!is_partial && is_type_union(type_deref(x.type))) {
		Type *ut = base_type(type_deref(x.type));
		GB_ASSERT(is_type_union(ut));
		auto variants = ut->Union.variants;

		auto unhandled = array_make<Type *>(ctx->allocator, 0, variants.count);
		defer (array_free(&unhandled));

		for_array(i, variants) {
			Type *t = variants[i];
			if (!type_ptr_set_exists(&seen, t)) {
				array_add(&unhandled, t);
			}
		}

		if (unhandled.count > 0) {
			if (unhandled.count == 1) {
				gbString s = type_to_string(unhandled[0]);
				error_no_newline(node, "Unhandled switch case: %s", s);
				gb_string_free(s);
			} else {
				error_no_newline(node, "Unhandled switch cases:\n");
				for_array(i, unhandled) {
					Type *t = unhandled[i];
					gbString s = type_to_string(t);
					error_line("\t%s\n", s);
					gb_string_free(s);
				}
			}
			error_line("\n");
			error_line("\tSuggestion: Was '#partial switch' wanted? This replaces the previous '#complete switch'.\n");
		}
	}
}

void check_stmt_internal(CheckerContext *ctx, Ast *node, u32 flags) {
	u32 mod_flags = flags & (~Stmt_FallthroughAllowed);
	switch (node->kind) {
	case_ast_node(_, EmptyStmt, node); case_end;
	case_ast_node(_, BadStmt,   node); case_end;
	case_ast_node(_, BadDecl,   node); case_end;

	case_ast_node(es, ExprStmt, node)
		Operand operand = {Addressing_Invalid};
		ExprKind kind = check_expr_base(ctx, &operand, es->expr, nullptr);
		switch (operand.mode) {
		case Addressing_Type: {
			gbString str = type_to_string(operand.type);
			error(node, "'%s' is not an expression", str);
			gb_string_free(str);

			break;
		}
		case Addressing_NoValue:
			return;
		default: {
			if (kind == Expr_Stmt) {
				return;
			}
			if (operand.expr->kind == Ast_CallExpr) {
				AstCallExpr *ce = &operand.expr->CallExpr;
				Type *t = type_of_expr(ce->proc);
				if (is_type_proc(t)) {
					if (t->Proc.require_results) {
						gbString expr_str = expr_to_string(ce->proc);
						error(node, "'%s' requires that its results must be handled", expr_str);
						gb_string_free(expr_str);
					}
				}
				return;
			}
			gbString expr_str = expr_to_string(operand.expr);
			error(node, "Expression is not used: '%s'", expr_str);
			gb_string_free(expr_str);

			break;
		}
		}
	case_end;

	case_ast_node(ts, TagStmt, node);
		// TODO(bill): Tag Statements
		error(node, "Tag statements are not supported yet");
		check_stmt(ctx, ts->stmt, flags);
	case_end;

	case_ast_node(as, AssignStmt, node);
		switch (as->op.kind) {
		case Token_Eq: {
			// a, b, c = 1, 2, 3;  // Multisided

			isize lhs_count = as->lhs.count;
			if (lhs_count == 0) {
				error(as->op, "Missing lhs in assignment statement");
				return;
			}

			// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
			// an extra allocation
			auto lhs_operands = array_make<Operand>(ctx->allocator, lhs_count);
			auto rhs_operands = array_make<Operand>(ctx->allocator, 0, 2*lhs_count);
			defer (array_free(&lhs_operands));
			defer (array_free(&rhs_operands));

			for_array(i, as->lhs) {
				if (is_blank_ident(as->lhs[i])) {
					Operand *o = &lhs_operands[i];
					o->expr = as->lhs[i];
					o->mode = Addressing_Value;
				} else {
					check_expr(ctx, &lhs_operands[i], as->lhs[i]);
				}
			}

			check_assignment_arguments(ctx, lhs_operands, &rhs_operands, as->rhs);

			isize rhs_count = rhs_operands.count;
			for_array(i, rhs_operands) {
				if (rhs_operands[i].mode == Addressing_Invalid) {
					// TODO(bill): Should I ignore invalid parameters?
					// rhs_count--;
				}
			}

			isize max = gb_min(lhs_count, rhs_count);
			for (isize i = 0; i < max; i++) {
				check_assignment_variable(ctx, &lhs_operands[i], &rhs_operands[i]);
			}
			if (lhs_count != rhs_count) {
				error(as->lhs[0], "Assignment count mismatch '%td' = '%td'", lhs_count, rhs_count);
			}
			break;
		}

		default: {
			// a += 1; // Single-sided
			Token op = as->op;
			if (as->lhs.count != 1 || as->rhs.count != 1) {
				error(op, "Assignment operation '%.*s' requires single-valued expressions", LIT(op.string));
				return;
			}
			if (!gb_is_between(op.kind, Token__AssignOpBegin+1, Token__AssignOpEnd-1)) {
				error(op, "Unknown Assignment operation '%.*s'", LIT(op.string));
				return;
			}
			Operand lhs = {Addressing_Invalid};
			Operand rhs = {Addressing_Invalid};
			Ast binary_expr = {Ast_BinaryExpr};
			ast_node(be, BinaryExpr, &binary_expr);
			be->op = op;
			be->op.kind = cast(TokenKind)(cast(i32)be->op.kind - (Token_AddEq - Token_Add));
			 // NOTE(bill): Only use the first one will be used
			be->left  = as->lhs[0];
			be->right = as->rhs[0];

			check_expr(ctx, &lhs, as->lhs[0]);
			check_binary_expr(ctx, &rhs, &binary_expr, nullptr, true);
			if (rhs.mode == Addressing_Invalid) {
				return;
			}
			// NOTE(bill): Only use the first one will be used
			check_assignment_variable(ctx, &lhs, &rhs);

			break;
		}
		}
	case_end;

	case_ast_node(bs, BlockStmt, node);
		check_open_scope(ctx, node);
		check_label(ctx, bs->label, node);

		check_stmt_list(ctx, bs->stmts, flags);
		check_close_scope(ctx);
	case_end;

	case_ast_node(is, IfStmt, node);
		check_open_scope(ctx, node);

		check_label(ctx, is->label, node);

		if (is->init != nullptr) {
			check_stmt(ctx, is->init, 0);
		}

		Operand operand = {Addressing_Invalid};
		check_expr(ctx, &operand, is->cond);
		if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
			error(is->cond, "Non-boolean condition in 'if' statement");
		}

		check_stmt(ctx, is->body, mod_flags);

		if (is->else_stmt != nullptr) {
			switch (is->else_stmt->kind) {
			case Ast_IfStmt:
			case Ast_BlockStmt:
				check_stmt(ctx, is->else_stmt, mod_flags);
				break;
			default:
				error(is->else_stmt, "Invalid 'else' statement in 'if' statement");
				break;
			}
		}

		check_close_scope(ctx);
	case_end;

	case_ast_node(ws, WhenStmt, node);
		check_when_stmt(ctx, ws, flags);
	case_end;

	case_ast_node(rs, ReturnStmt, node);
		GB_ASSERT(ctx->curr_proc_sig != nullptr);

		if (ctx->in_defer) {
			error(rs->token, "You cannot 'return' within a defer statement");
			break;
		}

		Type *proc_type = ctx->curr_proc_sig;
		GB_ASSERT(proc_type != nullptr);
		GB_ASSERT(proc_type->kind == Type_Proc);

		TypeProc *pt = &proc_type->Proc;
		if (pt->diverging) {
			error(rs->token, "Diverging procedures may not return");
			break;
		}

		Entity **result_entities = nullptr;
		isize result_count = 0;
		bool has_named_results = pt->has_named_results;
		if (pt->results) {
			result_entities = proc_type->Proc.results->Tuple.variables.data;
			result_count = proc_type->Proc.results->Tuple.variables.count;
		}

		auto operands = array_make<Operand>(heap_allocator(), 0, 2*rs->results.count);
		defer (array_free(&operands));

		check_unpack_arguments(ctx, result_entities, result_count, &operands, rs->results, true, false);

		if (result_count == 0 && rs->results.count > 0) {
			error(rs->results[0], "No return values expected");
		} else if (has_named_results && operands.count == 0) {
			// Okay
		} else if (operands.count != result_count) {
			error(node, "Expected %td return values, got %td", result_count, operands.count);
		} else {
			isize max_count = rs->results.count;
			for (isize i = 0; i < max_count; i++) {
				Entity *e = pt->results->Tuple.variables[i];
				check_assignment(ctx, &operands[i], e->type, str_lit("return statement"));
			}
		}
	case_end;

	case_ast_node(fs, ForStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;

		check_open_scope(ctx, node);
		check_label(ctx, fs->label, node); // TODO(bill): What should the label's "scope" be?

		if (fs->init != nullptr) {
			check_stmt(ctx, fs->init, 0);
		}
		if (fs->cond != nullptr) {
			Operand o = {Addressing_Invalid};
			check_expr(ctx, &o, fs->cond);
			if (o.mode != Addressing_Invalid && !is_type_boolean(o.type)) {
				error(fs->cond, "Non-boolean condition in 'for' statement");
			}
		}
		if (fs->post != nullptr) {
			check_stmt(ctx, fs->post, 0);

			if (fs->post->kind != Ast_AssignStmt) {
				error(fs->post, "'for' statement post statement must be a simple statement");
			}
		}
		check_stmt(ctx, fs->body, new_flags);

		check_close_scope(ctx);
	case_end;


	case_ast_node(rs, RangeStmt, node);
		u32 new_flags = mod_flags | Stmt_BreakAllowed | Stmt_ContinueAllowed;

		check_open_scope(ctx, node);
		check_label(ctx, rs->label, node);

		Type *val0 = nullptr;
		Type *val1 = nullptr;
		Entity *entities[2] = {};
		isize entity_count = 0;
		bool is_map = false;

		Ast *expr = unparen_expr(rs->expr);


		if (is_ast_range(expr)) {
			ast_node(ie, BinaryExpr, expr);
			Operand x = {};
			Operand y = {};

			bool ok = check_range(ctx, expr, &x, &y, nullptr);
			if (!ok) {
				goto skip_expr_range_stmt;
			}
			val0 = x.type;
			val1 = t_int;
		} else {
			Operand operand = {Addressing_Invalid};
			check_expr_base(ctx, &operand, expr, nullptr);
			error_operand_no_value(&operand);

			if (operand.mode == Addressing_Type) {
				if (!is_type_enum(operand.type)) {
					gbString t = type_to_string(operand.type);
					error(operand.expr, "Cannot iterate over the type '%s'", t);
					gb_string_free(t);
					goto skip_expr_range_stmt;
				} else {
					val0 = operand.type;
					val1 = t_int;
					add_type_info_type(ctx, operand.type);
					goto skip_expr_range_stmt;
				}
			} else if (operand.mode != Addressing_Invalid) {
				bool is_ptr = is_type_pointer(operand.type);
				Type *t = base_type(type_deref(operand.type));
				switch (t->kind) {
				case Type_Basic:
					if (is_type_string(t) && t->Basic.kind != Basic_cstring) {
						val0 = t_rune;
						val1 = t_int;
						add_package_dependency(ctx, "runtime", "string_decode_rune");
					}
					break;

				case Type_EnumeratedArray:
					val0 = t->EnumeratedArray.elem;
					val1 = t->EnumeratedArray.index;
					break;

				case Type_Array:
					val0 = t->Array.elem;
					val1 = t_int;
					break;

				case Type_DynamicArray:
					val0 = t->DynamicArray.elem;
					val1 = t_int;
					break;

				case Type_Slice:
					val0 = t->Slice.elem;
					val1 = t_int;
					break;

				case Type_Map:
					is_map = true;
					val0 = t->Map.key;
					val1 = t->Map.value;
					break;

				case Type_Tuple:
					if (false) {
						check_not_tuple(ctx, &operand);
					} else {
						isize count = t->Tuple.variables.count;
						if (count < 1 || count > 3) {
							check_not_tuple(ctx, &operand);
							error_line("\tMultiple return valued parameters in a range statement are limited to a maximum of 2 usable values with a trailing boolean for the conditional\n");
							break;
						}
						Type *cond_type = t->Tuple.variables[count-1]->type;
						if (!is_type_boolean(cond_type)) {
							gbString s = type_to_string(cond_type);
							error(operand.expr, "The final type of %td-valued tuple must be a boolean, got %s", count, s);
							gb_string_free(s);
							break;
						}

						if (count > 1) val0 = t->Tuple.variables[0]->type;
						if (count > 2) val1 = t->Tuple.variables[1]->type;

						if (rs->val1 != nullptr && count < 3) {
							gbString s = type_to_string(t);
							error(operand.expr, "Expected a 3-value tuple on the rhs, got (%s)", s);
							gb_string_free(s);
							break;
						}

						if (rs->val0 != nullptr && count < 2) {
							gbString s = type_to_string(t);
							error(operand.expr, "Expected at least a 2-values tuple on the rhs, got (%s)", s);
							gb_string_free(s);
							break;
						}

					}
					break;

				}
			}

			if (val0 == nullptr) {
				gbString s = expr_to_string(operand.expr);
				gbString t = type_to_string(operand.type);
				error(operand.expr, "Cannot iterate over '%s' of type '%s'", s, t);
				gb_string_free(t);
				gb_string_free(s);
			}
		}

		skip_expr_range_stmt:; // NOTE(zhiayang): again, declaring a variable immediately after a label... weird.

		Ast * lhs[2] = {rs->val0, rs->val1};
		Type *rhs[2] = {val0, val1};

		for (isize i = 0; i < 2; i++) {
			if (lhs[i] == nullptr) {
				continue;
			}
			Ast * name = lhs[i];
			Type *type = rhs[i];

			Entity *entity = nullptr;
			if (name->kind == Ast_Ident) {
				Token token = name->Ident.token;
				String str = token.string;
				Entity *found = nullptr;

				if (!is_blank_ident(str)) {
					found = scope_lookup_current(ctx->scope, str);
				}
				if (found == nullptr) {
					entity = alloc_entity_variable(ctx->scope, token, type, EntityState_Resolved);
					entity->flags |= EntityFlag_Value;
					add_entity_definition(&ctx->checker->info, name, entity);
				} else {
					TokenPos pos = found->token.pos;
					error(token,
					      "Redeclaration of '%.*s' in this scope\n"
					      "\tat %.*s(%td:%td)",
					      LIT(str), LIT(pos.file), pos.line, pos.column);
					entity = found;
				}
			} else {
				error(name, "A variable declaration must be an identifier");
			}

			if (entity == nullptr) {
				entity = alloc_entity_dummy_variable(builtin_pkg->scope, ast_token(name));
			}

			entities[entity_count++] = entity;

			if (type == nullptr) {
				entity->type = t_invalid;
				entity->flags |= EntityFlag_Used;
			}
		}

		for (isize i = 0; i < entity_count; i++) {
			Entity *e = entities[i];
			DeclInfo *d = decl_info_of_entity(e);
			GB_ASSERT(d == nullptr);
			add_entity(ctx->checker, ctx->scope, e->identifier, e);
			d = make_decl_info(ctx->allocator, ctx->scope, ctx->decl);
			add_entity_and_decl_info(ctx, e->identifier, e, d);
		}

		check_stmt(ctx, rs->body, new_flags);

		check_close_scope(ctx);
	case_end;

	case_ast_node(irs, InlineRangeStmt, node);
		check_inline_range_stmt(ctx, node, mod_flags);
	case_end;

	case_ast_node(ss, SwitchStmt, node);
		check_switch_stmt(ctx, node, mod_flags);
	case_end;

	case_ast_node(ss, TypeSwitchStmt, node);
		check_type_switch_stmt(ctx, node, mod_flags);
	case_end;


	case_ast_node(ds, DeferStmt, node);
		if (is_ast_decl(ds->stmt)) {
			error(ds->token, "You cannot defer a declaration");
		} else {
			bool out_in_defer = ctx->in_defer;
			ctx->in_defer = true;
			check_stmt(ctx, ds->stmt, 0);
			ctx->in_defer = out_in_defer;
		}
	case_end;

	case_ast_node(bs, BranchStmt, node);
		Token token = bs->token;
		switch (token.kind) {
		case Token_break:
			if ((flags & Stmt_BreakAllowed) == 0 && bs->label == nullptr) {
				error(token, "'break' only allowed in loops or 'switch' statements");
			}
			break;
		case Token_continue:
			if ((flags & Stmt_ContinueAllowed) == 0 && bs->label == nullptr) {
				error(token, "'continue' only allowed in loops");
			}
			break;
		case Token_fallthrough:
			if ((flags & Stmt_FallthroughAllowed) == 0) {
				error(token, "'fallthrough' statement in illegal position, expected at the end of a 'case' block");
			} else if (bs->label != nullptr) {
				error(token, "'fallthrough' cannot have a label");
			}
			break;
		default:
			error(token, "Invalid AST: Branch Statement '%.*s'", LIT(token.string));
			break;
		}

		if (bs->label != nullptr) {
			if (bs->label->kind != Ast_Ident) {
				error(bs->label, "A branch statement's label name must be an identifier");
				return;
			}
			Ast *ident = bs->label;
			String name = ident->Ident.token.string;
			Operand o = {};
			Entity *e = check_ident(ctx, &o, ident, nullptr, nullptr, false);
			if (e == nullptr) {
				error(ident, "Undeclared label name: %.*s", LIT(name));
				return;
			}
			add_entity_use(ctx, ident, e);
			if (e->kind != Entity_Label) {
				error(ident, "'%.*s' is not a label", LIT(name));
				return;
			}
			Ast *parent = e->Label.parent;
			GB_ASSERT(parent != nullptr);
			switch (parent->kind) {
			case Ast_BlockStmt:
			case Ast_IfStmt:
			case Ast_SwitchStmt:
				if (token.kind != Token_break) {
					error(bs->label, "Label '%.*s' can only be used with 'break'", LIT(e->token.string));
				}
				break;
			case Ast_RangeStmt:
			case Ast_ForStmt:
				if ((token.kind != Token_break) && (token.kind != Token_continue)) {
					error(bs->label, "Label '%.*s' can only be used with 'break' and 'continue'", LIT(e->token.string));
				}
				break;

			}
		}

	case_end;

	case_ast_node(us, UsingStmt, node);
		if (us->list.count == 0) {
			error(us->token, "Empty 'using' list");
			return;
		}
		for_array(i, us->list) {
			Ast *expr = unparen_expr(us->list[0]);
			Entity *e = nullptr;

			bool is_selector = false;
			Operand o = {};
			switch (expr->kind) {
			case Ast_Ident:
				e = check_ident(ctx, &o, expr, nullptr, nullptr, true);
				break;
			case Ast_SelectorExpr:
				e = check_selector(ctx, &o, expr, nullptr);
				is_selector = true;
				break;
			case Ast_Implicit:
				error(us->token, "'using' applied to an implicit value");
				continue;
			default:
				error(us->token, "'using' can only be applied to an entity, got %.*s", LIT(ast_strings[expr->kind]));
				continue;
			}

			if (!check_using_stmt_entity(ctx, us, expr, is_selector, e)) {
				return;
			}
		}
	case_end;

	case_ast_node(fb, ForeignBlockDecl, node);
		Ast *foreign_library = fb->foreign_library;
		CheckerContext c = *ctx;
		if (foreign_library->kind != Ast_Ident) {
			error(foreign_library, "foreign library name must be an identifier");
		} else {
			c.foreign_context.curr_library = foreign_library;
			c.foreign_context.default_cc = ProcCC_CDecl;
		}

		check_decl_attributes(&c, fb->attributes, foreign_block_decl_attribute, nullptr);

		ast_node(block, BlockStmt, fb->body);
		for_array(i, block->stmts) {
			Ast *decl = block->stmts[i];
			if (decl->kind == Ast_ValueDecl && decl->ValueDecl.is_mutable) {
				check_stmt(&c, decl, flags);
			}
		}
	case_end;

	case_ast_node(vd, ValueDecl, node);
		if (vd->is_mutable) {
			Entity **entities = gb_alloc_array(ctx->allocator, Entity *, vd->names.count);
			isize entity_count = 0;

			isize new_name_count = 0;
			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				Entity *entity = nullptr;
				if (name->kind != Ast_Ident) {
					error(name, "A variable declaration must be an identifier");
				} else {
					Token token = name->Ident.token;
					String str = token.string;
					Entity *found = nullptr;
					// NOTE(bill): Ignore assignments to '_'
					if (!is_blank_ident(str)) {
						found = scope_lookup_current(ctx->scope, str);
						new_name_count += 1;
					}
					if (found == nullptr) {
						entity = alloc_entity_variable(ctx->scope, token, nullptr);
						entity->identifier = name;

						Ast *fl = ctx->foreign_context.curr_library;
						if (fl != nullptr) {
							GB_ASSERT(fl->kind == Ast_Ident);
							entity->Variable.is_foreign = true;
							entity->Variable.foreign_library_ident = fl;
						}
					} else {
						TokenPos pos = found->token.pos;
						error(token,
						      "Redeclaration of '%.*s' in this scope\n"
						      "\tat %.*s(%td:%td)",
						      LIT(str), LIT(pos.file), pos.line, pos.column);
						entity = found;
					}
				}
				if (entity == nullptr) {
					entity = alloc_entity_dummy_variable(builtin_pkg->scope, ast_token(name));
				}
				entity->parent_proc_decl = ctx->curr_proc_decl;
				entities[entity_count++] = entity;
			}

			if (new_name_count == 0) {
				error(node, "No new declarations on the lhs");
			}

			Type *init_type = nullptr;
			if (vd->type != nullptr) {
				init_type = check_type(ctx, vd->type);
				if (init_type == nullptr) {
					init_type = t_invalid;
				} else if (is_type_polymorphic(base_type(init_type))) {
					gbString str = type_to_string(init_type);
					error(vd->type, "Invalid use of a polymorphic type '%s' in variable declaration", str);
					gb_string_free(str);
					init_type = t_invalid;
				}
			}


			// TODO NOTE(bill): This technically checks things multple times
			AttributeContext ac = make_attribute_context(ctx->foreign_context.link_prefix);
			check_decl_attributes(ctx, vd->attributes, var_decl_attribute, &ac);

			for (isize i = 0; i < entity_count; i++) {
				Entity *e = entities[i];
				GB_ASSERT(e != nullptr);
				if (e->flags & EntityFlag_Visited) {
					e->type = t_invalid;
					continue;
				}
				e->flags |= EntityFlag_Visited;

				e->state = EntityState_InProgress;
				if (e->type == nullptr) {
					e->type = init_type;
					e->state = EntityState_Resolved;
				}
				ac.link_name = handle_link_name(ctx, e->token, ac.link_name, ac.link_prefix);
				e->Variable.thread_local_model = ac.thread_local_model;

				if (ac.link_name.len > 0) {
					e->Variable.link_name = ac.link_name;
				}

				e->flags &= ~EntityFlag_Static;
				if (ac.is_static) {
					String name = e->token.string;
					if (name == "_") {
						error(e->token, "The 'static' attribute is not allowed to be applied to '_'");
					} else {
						e->flags |= EntityFlag_Static;
					}
				}
				if (ac.thread_local_model != "") {
					String name = e->token.string;
					if (name == "_") {
						error(e->token, "The 'thread_local' attribute is not allowed to be applied to '_'");
					} else {
						e->flags |= EntityFlag_Static;
					}
					e->Variable.thread_local_model = ac.thread_local_model;
				}

				if (ac.is_static && ac.thread_local_model != "") {
					error(e->token, "The 'static' attribute is not needed if 'thread_local' is applied");
				}
			}

			check_arity_match(ctx, vd);
			check_init_variables(ctx, entities, entity_count, vd->values, str_lit("variable declaration"));

			for (isize i = 0; i < entity_count; i++) {
				Entity *e = entities[i];

				if (e->Variable.is_foreign) {
					if (vd->values.count > 0) {
						error(e->token, "A foreign variable declaration cannot have a default value");
					}

					String name = e->token.string;
					if (e->Variable.link_name.len > 0) {
						name = e->Variable.link_name;
					}

					if (vd->values.count > 0) {
						error(e->token, "A foreign variable declaration cannot have a default value");
					}
					init_entity_foreign_library(ctx, e);

					auto *fp = &ctx->checker->info.foreigns;
					HashKey key = hash_string(name);
					Entity **found = map_get(fp, key);
					if (found) {
						Entity *f = *found;
						TokenPos pos = f->token.pos;
						Type *this_type = base_type(e->type);
						Type *other_type = base_type(f->type);
						if (!are_types_identical(this_type, other_type)) {
							error(e->token,
							      "Foreign entity '%.*s' previously declared elsewhere with a different type\n"
							      "\tat %.*s(%td:%td)",
							      LIT(name), LIT(pos.file), pos.line, pos.column);
						}
					} else {
						map_set(fp, key, e);
					}
				} else if (e->flags & EntityFlag_Static) {
					if (vd->values.count > 0) {
						if (entity_count != vd->values.count) {
							error(e->token, "A static variable declaration with a default value must be constant");
						} else {
							Ast *value = vd->values[i];
							if (value->tav.mode != Addressing_Constant) {
								error(e->token, "A static variable declaration with a default value must be constant");
							}
						}
					}
				}
				add_entity(ctx->checker, ctx->scope, e->identifier, e);
			}

			if (vd->is_using != 0) {
				Token token = ast_token(node);
				if (vd->type != nullptr && entity_count > 1) {
					error(token, "'using' can only be applied to one variable of the same type");
					// TODO(bill): Should a 'continue' happen here?
				}

				for (isize entity_index = 0; entity_index < 1; entity_index++) {
					Entity *e = entities[entity_index];
					if (e == nullptr) {
						continue;
					}
					if (e->kind != Entity_Variable) {
						continue;
					}
					String name = e->token.string;
					Type *t = base_type(type_deref(e->type));

					if (is_blank_ident(name)) {
						error(token, "'using' cannot be applied variable declared as '_'");
					} else if (is_type_struct(t) || is_type_raw_union(t)) {
						Scope *scope = scope_of_node(t->Struct.node);
						for_array(i, scope->elements.entries) {
							Entity *f = scope->elements.entries[i].value;
							if (f->kind == Entity_Variable) {
								Entity *uvar = alloc_entity_using_variable(e, f->token, f->type, nullptr);
								uvar->flags |= (e->flags & EntityFlag_Value);
								Entity *prev = scope_insert(ctx->scope, uvar);
								if (prev != nullptr) {
									error(token, "Namespace collision while 'using' '%.*s' of: %.*s", LIT(name), LIT(prev->token.string));
									return;
								}
							}
						}

						add_entity_use(ctx, nullptr, e);
					} else {
						// NOTE(bill): skip the rest to remove extra errors
						error(token, "'using' can only be applied to variables of type struct or raw_union");
						return;
					}
				}
			}

		} else {
			// constant value declaration
			// NOTE(bill): Check `_` declarations
			for_array(i, vd->names) {
				Ast *name = vd->names[i];
				if (is_blank_ident(name)) {
					Entity *e = name->Ident.entity;
					DeclInfo *d = decl_info_of_entity(e);
					if (d != nullptr) {
						check_entity_decl(ctx, e, d, nullptr);
					}
				}
			}

		}
	case_end;
	}
}
