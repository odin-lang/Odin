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
			error(operand->expr,
				  "Cannot assign built-in procedure `%s` in %.*s",
				  expr_str,
				  LIT(context_name));

			operand->mode = Addressing_Invalid;

			gb_string_free(expr_str);
		}


		if (operand->mode == Addressing_Overload) {
			if (e->type == nullptr) {
				error(operand->expr, "Cannot determine type from overloaded procedure `%.*s`", LIT(operand->overload_entities[0]->token.string));
			} else {
				check_assignment(c, operand, e->type, str_lit("variable assignment"));
				if (operand->mode != Addressing_Type) {
					return operand->type;
				}
			}
		}

		if (e->type == nullptr) {
			e->type = t_invalid;
		}
		return nullptr;
	}



	if (e->type == nullptr) {

		// NOTE(bill): Use the type of the operand
		Type *t = operand->type;
		if (is_type_untyped(t)) {
			if (t == t_invalid || is_type_untyped_nil(t)) {
				error(e->token, "Invalid use of untyped nil in %.*s", LIT(context_name));
				e->type = t_invalid;
				return nullptr;
			}
			if (t == t_invalid || is_type_untyped_undef(t)) {
				error(e->token, "Invalid use of --- in %.*s", LIT(context_name));
				e->type = t_invalid;
				return nullptr;
			}
			t = default_type(t);
		}
		if (is_type_polymorphic(t)) {
			gbString str = type_to_string(t);
			defer (gb_string_free(str));
			error(e->token, "Invalid use of a polymorphic type `%s` in %.*s", str, LIT(context_name));
			e->type = t_invalid;
			return nullptr;
		}
		if (is_type_bit_field_value(t)) {
			t = default_bit_field_value_type(t);
		}
		GB_ASSERT(is_type_typed(t));
		e->type = t;
	}

	e->parent_proc_decl = c->context.curr_proc_decl;

	check_assignment(c, operand, e->type, context_name);
	if (operand->mode == Addressing_Invalid) {
		return nullptr;
	}

	return e->type;
}

void check_init_variables(Checker *c, Entity **lhs, isize lhs_count, Array<AstNode *> inits, String context_name) {
	if ((lhs == nullptr || lhs_count == 0) && inits.count == 0) {
		return;
	}


	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
	// an extra allocation
	Array<Operand> operands = {};
	array_init(&operands, c->tmp_allocator, 2*lhs_count);
	check_unpack_arguments(c, lhs_count, &operands, inits, true);

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
		error(lhs[0]->token, "Assignment count mismatch `%td` = `%td`", lhs_count, rhs_count);
	}
}

void check_init_constant(Checker *c, Entity *e, Operand *operand) {
	if (operand->mode == Addressing_Invalid ||
		operand->type == t_invalid ||
		e->type == t_invalid) {
		if (e->type == nullptr) {
			e->type = t_invalid;
		}
		return;
	}

	if (operand->mode != Addressing_Constant) {
		// TODO(bill): better error
		gbString str = expr_to_string(operand->expr);
		error(operand->expr, "`%s` is not a constant", str);
		gb_string_free(str);
		if (e->type == nullptr) {
			e->type = t_invalid;
		}
		return;
	}
	if (!is_type_constant_type(operand->type)) {
		gbString type_str = type_to_string(operand->type);
		error(operand->expr, "Invalid constant type: `%s`", type_str);
		gb_string_free(type_str);
		if (e->type == nullptr) {
			e->type = t_invalid;
		}
		return;
	}

	if (e->type == nullptr) { // NOTE(bill): type inference
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
	GB_ASSERT(e->type == nullptr);
	String name = e->token.string;
	Type *named = make_type_named(c->allocator, name, nullptr, e);
	named->Named.type_name = e;
	if (def != nullptr && def->kind == Type_Named) {
		def->Named.base = named;
	}
	e->type = named;

	// gb_printf_err("%.*s %p\n", LIT(e->token.string), e);

	Type *bt = check_type(c, type_expr, named);
	named->Named.base = base_type(bt);
	if (named->Named.base == t_invalid) {
		// gb_printf("check_type_decl: %s\n", type_to_string(named));
	}
}

void check_const_decl(Checker *c, Entity *e, AstNode *type_expr, AstNode *init, Type *named_type) {
	GB_ASSERT(e->type == nullptr);
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
			error(type_expr, "Invalid constant type `%s`", str);
			gb_string_free(str);
			e->type = t_invalid;
			return;
		}
		e->type = t;
	}

	Operand operand = {};

	if (init != nullptr) {
		Entity *entity = nullptr;
		if (init->kind == AstNode_Ident) {
			entity = check_ident(c, &operand, init, nullptr, e->type, true);
		} else if (init->kind == AstNode_SelectorExpr) {
			entity = check_selector(c, &operand, init, e->type);
		} else {
			check_expr_or_type(c, &operand, init, e->type);
		}

		switch (operand.mode) {
		case Addressing_Type: {
			e->kind = Entity_TypeName;

			DeclInfo *d = c->context.decl;
			if (d->type_expr != nullptr) {
				error(e->token, "A type declaration cannot have an type parameter");
			}
			d->type_expr = d->init_expr;
			check_type_decl(c, e, d->type_expr, named_type);
			return;
		} break;

	// NOTE(bill): Check to see if the expression it to be aliases
		case Addressing_Builtin:
			if (e->type != nullptr) {
				error(type_expr, "A constant alias of a built-in procedure may not have a type initializer");
			}
			e->kind = Entity_Builtin;
			e->Builtin.id = operand.builtin_id;
			e->type = t_invalid;
			return;

		case Addressing_Overload:
			e->kind = Entity_Alias;
			e->Alias.base = operand.overload_entities[0];
			e->type = t_invalid;
			return;
		}

		if (entity != nullptr) {
			switch (entity->kind) {
			case Entity_Alias:
				e->kind = Entity_Alias;
				e->type = entity->type;
				e->Alias.base = entity->Alias.base;
				return;
			case Entity_Procedure:
				e->kind = Entity_Alias;
				e->type = entity->type;
				e->Alias.base = entity;
				return;
			case Entity_ImportName:
				e->kind = Entity_ImportName;
				e->type = entity->type;
				e->ImportName.path  = entity->ImportName.path;
				e->ImportName.name  = entity->ImportName.path;
				e->ImportName.scope = entity->ImportName.scope;
				e->ImportName.used  = false;
				return;
			case Entity_LibraryName:
				e->kind = Entity_LibraryName;
				e->type = entity->type;
				e->LibraryName.path  = entity->LibraryName.path;
				e->LibraryName.name  = entity->LibraryName.path;
				e->LibraryName.used  = false;
				return;
			}
		}
	}

	if (init != nullptr) {
		check_expr_or_type(c, &operand, init, e->type);
	}

	check_init_constant(c, e, &operand);

	if (operand.mode == Addressing_Invalid ||
		base_type(operand.type) == t_invalid) {
		gbString str = expr_to_string(init);
		error(e->token, "Invalid declaration type `%s`", str);
		gb_string_free(str);
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
		Type *x = core_type(a->params->Tuple.variables[i]->type);
		Type *y = core_type(b->params->Tuple.variables[i]->type);
		if (is_type_pointer(x) && is_type_pointer(y)) {
			continue;
		}

		if (is_type_integer(x) && is_type_integer(y)) {
			GB_ASSERT(x->kind == Type_Basic);
			GB_ASSERT(y->kind == Type_Basic);
			if (x->Basic.size == y->Basic.size) {
				continue;
			}
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

		if (is_type_integer(x) && is_type_integer(y)) {
			GB_ASSERT(x->kind == Type_Basic);
			GB_ASSERT(y->kind == Type_Basic);
			if (x->Basic.size == y->Basic.size) {
				continue;
			}
		}

		if (!are_types_identical(x, y)) {
			return false;
		}
	}

	return true;
}

void init_entity_foreign_library(Checker *c, Entity *e) {
	AstNode *ident = nullptr;
	Entity **foreign_library = nullptr;

	switch (e->kind) {
	case Entity_Procedure:
		ident = e->Procedure.foreign_library_ident;
		foreign_library = &e->Procedure.foreign_library;
		break;
	case Entity_Variable:
		ident = e->Variable.foreign_library_ident;
		foreign_library = &e->Variable.foreign_library;
		break;
	default:
		return;
	}

	if (ident == nullptr) {
		error(e->token, "foreign entiies must declare which library they are from");
	} else if (ident->kind != AstNode_Ident) {
		error(ident, "foreign library names must be an identifier");
	} else {
		String name = ident->Ident.token.string;
		Entity *found = scope_lookup_entity(c->context.scope, name);
		if (found == nullptr) {
			if (is_blank_ident(name)) {
				error(ident, "`_` cannot be used as a value type");
			} else {
				error(ident, "Undeclared name: %.*s", LIT(name));
			}
		} else if (found->kind != Entity_LibraryName) {
			error(ident, "`%.*s` cannot be used as a library name", LIT(name));
		} else {
			// TODO(bill): Extra stuff to do with library names?
			*foreign_library = found;
			add_entity_use(c, ident, found);
		}
	}
}

void check_proc_decl(Checker *c, Entity *e, DeclInfo *d) {
	GB_ASSERT(e->type == nullptr);
	if (d->proc_lit->kind != AstNode_ProcLit) {
		// TOOD(bill): Better error message
		error(d->proc_lit, "Expected a procedure to check");
		return;
	}

	Type *proc_type = e->type;
	if (d->gen_proc_type != nullptr) {
		proc_type = d->gen_proc_type;
	} else {
		proc_type = make_type_proc(c->allocator, e->scope, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
	}
	e->type = proc_type;
	ast_node(pl, ProcLit, d->proc_lit);

	check_open_scope(c, pl->type);
	defer (check_close_scope(c));




	auto prev_context = c->context;
	c->context.allow_polymorphic_types = true;
	check_procedure_type(c, proc_type, pl->type);
	c->context = prev_context;

	TypeProc *pt = &proc_type->Proc;

	bool is_foreign         = (pl->tags & ProcTag_foreign)   != 0;
	bool is_link_name       = (pl->tags & ProcTag_link_name) != 0;
	bool is_export          = (pl->tags & ProcTag_export)    != 0;
	bool is_inline          = (pl->tags & ProcTag_inline)    != 0;
	bool is_no_inline       = (pl->tags & ProcTag_no_inline) != 0;
	bool is_require_results = (pl->tags & ProcTag_require_results) != 0;



	if (d->scope->is_file && e->token.string == "main") {
		if (pt->param_count != 0 ||
		    pt->result_count != 0) {
			gbString str = type_to_string(proc_type);
			error(e->token, "Procedure type of `main` was expected to be `proc()`, got %s", str);
			gb_string_free(str);
		}
		if (pt->calling_convention != ProcCC_Odin &&
		    pt->calling_convention != ProcCC_Contextless) {
			error(e->token, "Procedure `main` cannot have a custom calling convention");
		}
		pt->calling_convention = ProcCC_Contextless;
	}

	if (is_inline && is_no_inline) {
		error(pl->type, "You cannot apply both `inline` and `no_inline` to a procedure");
	}

	if (is_foreign && is_export) {
		error(pl->type, "A foreign procedure cannot have an `export` tag");
	}

	if (pt->is_polymorphic) {
		if (pl->body == nullptr) {
			error(e->token, "Polymorphic procedures must have a body");
		}

		if (is_foreign) {
			error(e->token, "A foreign procedure cannot be a polymorphic");
			return;
		}
	}

	if (pl->body != nullptr) {
		if (is_foreign) {
			error(pl->body, "A foreign procedure cannot have a body");
		}
		if (proc_type->Proc.c_vararg) {
			error(pl->body, "A procedure with a `#c_vararg` field cannot have a body and must be foreign");
		}

		d->scope = c->context.scope;

		GB_ASSERT(pl->body->kind == AstNode_BlockStmt);
		if (!pt->is_polymorphic) {
			check_procedure_later(c, c->curr_ast_file, e->token, d, proc_type, pl->body, pl->tags);
		}
	} else if (!is_foreign) {
		error(e->token, "Only a foreign procedure cannot have a body");
	}

	if (pt->result_count == 0 && is_require_results) {
		error(pl->type, "`#require_results` is not needed on a procedure with no results");
	} else {
		pt->require_results = is_require_results;
	}



	if (is_foreign) {
		String name = e->token.string;
		if (pl->link_name.len > 0) {
			name = pl->link_name;
		}
		e->Procedure.is_foreign = true;
		e->Procedure.link_name = name;

		init_entity_foreign_library(c, e);


		auto *fp = &c->info.foreigns;
		HashKey key = hash_string(name);
		Entity **found = map_get(fp, key);
		if (found) {
			Entity *f = *found;
			TokenPos pos = f->token.pos;
			Type *this_type = base_type(e->type);
			Type *other_type = base_type(f->type);
			if (is_type_proc(this_type) && is_type_proc(other_type)) {
				if (!are_signatures_similar_enough(this_type, other_type)) {
					error(d->proc_lit,
					      "Redeclaration of foreign procedure `%.*s` with different type signatures\n"
					      "\tat %.*s(%td:%td)",
					      LIT(name), LIT(pos.file), pos.line, pos.column);
				}
			} else if (!are_types_identical(this_type, other_type)) {
				error(d->proc_lit,
				      "Foreign entity `%.*s` previously declared elsewhere with a different type\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name), LIT(pos.file), pos.line, pos.column);
			}
		} else {
			map_set(fp, key, e);
		}
	} else {
		String name = e->token.string;
		if (is_link_name) {
			name = pl->link_name;
		}

		if (is_link_name || is_export) {
			auto *fp = &c->info.foreigns;

			e->Procedure.link_name = name;

			HashKey key = hash_string(name);
			Entity **found = map_get(fp, key);
			if (found) {
				Entity *f = *found;
				TokenPos pos = f->token.pos;
				// TODO(bill): Better error message?
				error(d->proc_lit,
				      "Non unique linking name for procedure `%.*s`\n"
				      "\tother at %.*s(%td:%td)",
				      LIT(name), LIT(pos.file), pos.line, pos.column);
			} else {
				map_set(fp, key, e);
			}
		}
	}
}

void check_var_decl(Checker *c, Entity *e, Entity **entities, isize entity_count, AstNode *type_expr, AstNode *init_expr) {
	GB_ASSERT(e->type == nullptr);
	GB_ASSERT(e->kind == Entity_Variable);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	String context_name = str_lit("variable declaration");

	if (type_expr != nullptr) {
		e->type = check_type(c, type_expr);
	}
	if (e->type != nullptr && is_type_polymorphic(base_type(e->type))) {
		gbString str = type_to_string(e->type);
		defer (gb_string_free(str));
		error(e->token, "Invalid use of a polymorphic type `%s` in %.*s", str, LIT(context_name));
		e->type = t_invalid;
	}


	if (e->Variable.is_foreign) {
		if (init_expr != nullptr) {
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

	if (init_expr == nullptr) {
		if (type_expr == nullptr) {
			e->type = t_invalid;
		}
		return;
	}

	if (entities == nullptr || entity_count == 1) {
		GB_ASSERT(entities == nullptr || entities[0] == e);
		Operand operand = {};
		check_expr(c, &operand, init_expr);
		check_init_variable(c, e, &operand, context_name);
	}

	if (type_expr != nullptr) {
		for (isize i = 0; i < entity_count; i++) {
			entities[i]->type = e->type;
		}
	}


	Array<AstNode *> inits;
	array_init(&inits, c->allocator, 1);
	array_add(&inits, init_expr);
	check_init_variables(c, entities, entity_count, inits, context_name);
}

void check_entity_decl(Checker *c, Entity *e, DeclInfo *d, Type *named_type) {
	if (e->type != nullptr) {
		return;
	}

	if (d == nullptr) {
		d = decl_info_of_entity(&c->info, e);
		if (d == nullptr) {
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
	case Entity_Procedure:
		check_proc_decl(c, e, d);
		break;
	}

	c->context = prev;
}



void check_proc_body(Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	if (body == nullptr) {
		return;
	}
	GB_ASSERT(body->kind == AstNode_BlockStmt);

	String proc_name = {};
	if (token.kind == Token_Ident) {
		proc_name = token.string;
	} else {
		// TODO(bill): Better name
		proc_name = str_lit("(anonymous-procedure)");
	}

	CheckerContext old_context = c->context;
	defer (c->context = old_context);

	c->context.scope = decl->scope;
	c->context.decl = decl;
	c->context.proc_name = proc_name;
	c->context.curr_proc_decl = decl;

	GB_ASSERT(type->kind == Type_Proc);
	if (type->Proc.param_count > 0) {
		TypeTuple *params = &type->Proc.params->Tuple;
		for_array(i, params->variables) {
			Entity *e = params->variables[i];
			if (e->kind != Entity_Variable) {
				continue;
			}
			if (!(e->flags & EntityFlag_Using)) {
				continue;
			}
			bool is_immutable = e->Variable.is_immutable;
			String name = e->token.string;
			Type *t = base_type(type_deref(e->type));
			if (is_type_struct(t) || is_type_raw_union(t)) {
				Scope *scope = scope_of_node(&c->info, t->Record.node);
				GB_ASSERT(scope != nullptr);
				for_array(i, scope->elements.entries) {
					Entity *f = scope->elements.entries[i].value;
					if (f->kind == Entity_Variable) {
						Entity *uvar = make_entity_using_variable(c->allocator, e, f->token, f->type);
						uvar->Variable.is_immutable = is_immutable;
						Entity *prev = scope_insert_entity(c->context.scope, uvar);
						if (prev != nullptr) {
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

	if (decl->parent != nullptr) {
		// NOTE(bill): Add the dependencies from the procedure literal (lambda)
		for_array(i, decl->deps.entries) {
			HashKey key = decl->deps.entries[i].key;
			Entity *e = cast(Entity *)key.ptr;
			map_set(&decl->parent->deps, key, true);
		}
	}
}



