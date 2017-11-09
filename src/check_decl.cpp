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
		} else if (is_type_empty_union(t)) {
			gbString str = type_to_string(t);
			defer (gb_string_free(str));
			error(e->token, "An empty union `%s` cannot be instantiated in %.*s", str, LIT(context_name));
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
	check_unpack_arguments(c, lhs, lhs_count, &operands, inits, true);

	isize rhs_count = operands.count;
	for_array(i, operands) {
		if (operands[i].mode == Addressing_Invalid) {
			rhs_count--;
		}
	}

	isize max = gb_min(lhs_count, rhs_count);
	for (isize i = 0; i < max; i++) {
		Entity *e = lhs[i];
		DeclInfo *d = decl_info_of_entity(&c->info, e);
		Operand *o = &operands[i];
		check_init_variable(c, e, o, context_name);
		if (d != nullptr) {
			d->init_expr = o->expr;
		}
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

AstNode *remove_type_alias(AstNode *node) {
	for (;;) {
		if (node == nullptr) {
			return nullptr;
		}
		if (node->kind == AstNode_ParenExpr) {
			node = node->ParenExpr.expr;
		} else if (node->kind == AstNode_AliasType) {
			node = node->AliasType.type;
		} else {
			return node;
		}
	}
}

void check_type_decl(Checker *c, Entity *e, AstNode *type_expr, Type *def, bool is_alias) {
	GB_ASSERT(e->type == nullptr);

	DeclInfo *decl = decl_info_of_entity(&c->info, e);
	if (decl != nullptr && decl->attributes.count > 0) {
		error(decl->attributes[0], "Attributes are not allowed on type declarations");
	}

	AstNode *te = remove_type_alias(type_expr);
	e->type = t_invalid;
	String name = e->token.string;
	Type *named = make_type_named(c->allocator, name, nullptr, e);
	named->Named.type_name = e;
	if (def != nullptr && def->kind == Type_Named) {
		def->Named.base = named;
	}
	e->type = named;

	Type *bt = check_type(c, te, named);
	named->Named.base = base_type(bt);
	if (is_alias) {
		if (is_type_named(bt)) {
			e->type = bt;
			e->TypeName.is_type_alias = true;
		} else {
			gbString str = type_to_string(bt);
			error(type_expr, "Type alias declaration with a non-named type `%s`", str);
			gb_string_free(str);
		}
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
			check_type_decl(c, e, d->type_expr, named_type, false);
			return;
		}

	// NOTE(bill): Check to see if the expression it to be aliases
	#if 1
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
	#endif
		}
	#if 1
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
	#endif
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


	DeclInfo *decl = decl_info_of_entity(&c->info, e);
	if (decl != nullptr && decl->attributes.count > 0) {
		error(decl->attributes[0], "Attributes are not allowed on constant value declarations");
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
			i64 sx = type_size_of(heap_allocator(), x);
			i64 sy = type_size_of(heap_allocator(), y);
			if (sx == sy) continue;
		}

		if (!are_types_identical(x, y)) return false;
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
			i64 sx = type_size_of(heap_allocator(), x);
			i64 sy = type_size_of(heap_allocator(), y);
			if (sx == sy) continue;
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

String handle_link_name(Checker *c, Token token, String link_name, String link_prefix) {
	if (link_prefix.len > 0) {
		if (link_name.len > 0) {
			error(token, "`link_name` and `link_prefix` cannot be used together");
		} else {
			isize len = link_prefix.len + token.string.len;
			u8 *name = gb_alloc_array(c->allocator, u8, len+1);
			gb_memmove(name, &link_prefix[0], link_prefix.len);
			gb_memmove(name+link_prefix.len, &token.string[0], token.string.len);
			name[len] = 0;

			link_name = make_string(name, len);
		}
	}
	return link_name;
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

	bool is_foreign         = e->Procedure.is_foreign;
	bool is_export          = e->Procedure.is_export;
	bool is_require_results = (pl->tags & ProcTag_require_results) != 0;

	AttributeContext ac = make_attribute_context(e->Procedure.link_prefix);

	if (d != nullptr) {
		check_decl_attributes(c, d->attributes, proc_decl_attribute, &ac);
	}


	ac.link_name = handle_link_name(c, e->token, ac.link_name, ac.link_prefix);

	if (d->scope->file != nullptr && e->token.string == "main") {
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
		if (d->scope->is_init) {
			if (c->info.entry_point != nullptr) {
				error(e->token, "Redeclaration of the entry pointer procedure `main`");
			} else {
				c->info.entry_point = e;
			}
		}
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
		if (e->Procedure.is_export) {
			error(e->token, "Foreign export procedures must have a body");
		} else {
			error(e->token, "Only a foreign procedure cannot have a body");
		}
	}

	if (pt->result_count == 0 && is_require_results) {
		error(pl->type, "`#require_results` is not needed on a procedure with no results");
	} else {
		pt->require_results = is_require_results;
	}

	if (ac.link_name.len > 0) {
		e->Procedure.link_name = ac.link_name;
	}

	if (is_foreign) {
		String name = e->token.string;
		if (e->Procedure.link_name.len > 0) {
			name = e->Procedure.link_name;
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
		} else if (name == "main") {
			error(d->proc_lit, "The link name `main` is reserved for internal use");
		} else {
			map_set(fp, key, e);
		}
	} else {
		String name = e->token.string;
		if (e->Procedure.link_name.len > 0) {
			name = e->Procedure.link_name;
		}
		if (e->Procedure.link_name.len > 0 || is_export) {
			auto *fp = &c->info.foreigns;
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
			} else if (name == "main") {
				error(d->proc_lit, "The link name `main` is reserved for internal use");
			} else {
				map_set(fp, key, e);
			}
		}
	}
}

void check_var_decl(Checker *c, Entity *e, Entity **entities, isize entity_count, AstNode *type_expr, Array<AstNode *> init_expr_list) {
	GB_ASSERT(e->type == nullptr);
	GB_ASSERT(e->kind == Entity_Variable);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	AttributeContext ac = make_attribute_context(e->Variable.link_prefix);
	ac.init_expr_list_count = init_expr_list.count;

	DeclInfo *decl = decl_info_of_entity(&c->info, e);
	if (decl != nullptr) {
		check_decl_attributes(c, decl->attributes, var_decl_attribute, &ac);
	}

	ac.link_name = handle_link_name(c, e->token, ac.link_name, ac.link_prefix);
	e->Variable.thread_local_model = ac.thread_local_model;

	String context_name = str_lit("variable declaration");

	if (type_expr != nullptr) {
		e->type = check_type(c, type_expr);
	}
	if (e->type != nullptr) {
		if (is_type_polymorphic(base_type(e->type))) {
			gbString str = type_to_string(e->type);
			defer (gb_string_free(str));
			error(e->token, "Invalid use of a polymorphic type `%s` in %.*s", str, LIT(context_name));
			e->type = t_invalid;
		} else if (is_type_empty_union(e->type)) {
			gbString str = type_to_string(e->type);
			defer (gb_string_free(str));
			error(e->token, "An empty union `%s` cannot be instantiated in %.*s", str, LIT(context_name));
			e->type = t_invalid;
		}
	}


	if (e->Variable.is_foreign) {
		if (init_expr_list.count > 0) {
			error(e->token, "A foreign variable declaration cannot have a default value");
		}
		init_entity_foreign_library(c, e);
	}
	if (ac.link_name.len > 0) {
		e->Variable.link_name = ac.link_name;
	}

	if (e->Variable.is_foreign || e->Variable.is_export) {
		String name = e->token.string;
		if (e->Variable.link_name.len > 0) {
			name = e->Variable.link_name;
		}
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

	if (init_expr_list.count == 0) {
		if (type_expr == nullptr) {
			e->type = t_invalid;
		}
		return;
	}

	if (type_expr != nullptr) {
		for (isize i = 0; i < entity_count; i++) {
			entities[i]->type = e->type;
		}
	}

	check_init_variables(c, entities, entity_count, init_expr_list, context_name);
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
		check_var_decl(c, e, d->entities, d->entity_count, d->type_expr, d->init_expr_list);
		break;
	case Entity_Constant:
		check_const_decl(c, e, d->type_expr, d->init_expr, named_type);
		break;
	case Entity_TypeName: {
		bool is_alias = unparen_expr(d->type_expr)->kind == AstNode_AliasType;
		check_type_decl(c, e, d->type_expr, named_type, is_alias);
		break;
	}
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
			if (t->kind == Type_Struct) {
				Scope *scope = t->Struct.scope;
				if (scope == nullptr) {
					scope = scope_of_node(&c->info, t->Struct.node);
				}
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
				error(e->token, "`using` can only be applied to variables of type struct");
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
			Entity *e = decl->deps.entries[i].ptr;
			ptr_set_add(&decl->parent->deps, e);
		}
	}
}



