bool check_is_terminating(Ast *node);
void check_stmt          (CheckerContext *ctx, Ast *node, u32 flags);

// NOTE(bill): 'content_name' is for debugging and error messages
Type *check_init_variable(CheckerContext *ctx, Entity *e, Operand *operand, String context_name) {
	if (operand->mode == Addressing_Invalid ||
		operand->type == t_invalid ||
		e->type == t_invalid) {

		if (operand->mode == Addressing_Builtin) {
			gbString expr_str = expr_to_string(operand->expr);

			// TODO(bill): is this a good enough error message?
			// TODO(bill): Actually allow built in procedures to be passed around and thus be created on use
			error(operand->expr,
				  "Cannot assign built-in procedure '%s' in %.*s",
				  expr_str,
				  LIT(context_name));

			operand->mode = Addressing_Invalid;

			gb_string_free(expr_str);
		}


		if (operand->mode == Addressing_ProcGroup) {
			if (e->type == nullptr) {
				error(operand->expr, "Cannot determine type from overloaded procedure '%.*s'", LIT(operand->proc_group->token.string));
			} else {
				check_assignment(ctx, operand, e->type, str_lit("variable assignment"));
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

	if (operand->mode == Addressing_Type) {
		if (e->type != nullptr && is_type_typeid(e->type)) {
			add_type_info_type(ctx, operand->type);
			add_type_and_value(ctx->info, operand->expr, Addressing_Value, e->type, exact_value_typeid(operand->type));
			return e->type;
		} else {
			gbString t = type_to_string(operand->type);
			defer (gb_string_free(t));
			error(operand->expr, "Cannot assign a type '%s' to variable '%.*s'", t, LIT(e->token.string));
			if (e->type == nullptr) {
				error_line("\tThe type of the variable '%.*s' cannot be inferred as a type does not have a type\n", LIT(e->token.string));
			}
			e->type = operand->type;
			return nullptr;
		}
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
			error(e->token, "Invalid use of a polymorphic type '%s' in %.*s", str, LIT(context_name));
			e->type = t_invalid;
			return nullptr;
		} else if (is_type_empty_union(t)) {
			gbString str = type_to_string(t);
			defer (gb_string_free(str));
			error(e->token, "An empty union '%s' cannot be instantiated in %.*s", str, LIT(context_name));
			e->type = t_invalid;
			return nullptr;
		}
		if (is_type_bit_field_value(t)) {
			t = default_bit_field_value_type(t);
		}
		GB_ASSERT(is_type_typed(t));
		e->type = t;
	}

	e->parent_proc_decl = ctx->curr_proc_decl;

	check_assignment(ctx, operand, e->type, context_name);
	if (operand->mode == Addressing_Invalid) {
		return nullptr;
	}

	return e->type;
}

void check_init_variables(CheckerContext *ctx, Entity **lhs, isize lhs_count, Array<Ast *> const &inits, String context_name) {
	if ((lhs == nullptr || lhs_count == 0) && inits.count == 0) {
		return;
	}


	// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
	// an extra allocation
	auto operands = array_make<Operand>(ctx->allocator, 0, 2*lhs_count);
	defer (array_free(&operands));
	check_unpack_arguments(ctx, lhs, lhs_count, &operands, inits, true, false);

	isize rhs_count = operands.count;
	for_array(i, operands) {
		if (operands[i].mode == Addressing_Invalid) {
			// TODO(bill): Should I ignore invalid parameters?
			// rhs_count--;
		}
	}

	isize max = gb_min(lhs_count, rhs_count);
	for (isize i = 0; i < max; i++) {
		Entity *e = lhs[i];
		DeclInfo *d = decl_info_of_entity(e);
		Operand *o = &operands[i];
		check_init_variable(ctx, e, o, context_name);
		if (d != nullptr) {
			d->init_expr = o->expr;
		}
	}
	if (rhs_count > 0 && lhs_count != rhs_count) {
		error(lhs[0]->token, "Assignment count mismatch '%td' = '%td'", lhs_count, rhs_count);
	}
}

void check_init_constant(CheckerContext *ctx, Entity *e, Operand *operand) {
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
		error(operand->expr, "'%s' is not a constant", str);
		gb_string_free(str);
		if (e->type == nullptr) {
			e->type = t_invalid;
		}
		return;
	}

#if 0
	if (!is_type_constant_type(operand->type)) {
		gbString type_str = type_to_string(operand->type);
		error(operand->expr, "Invalid constant type: '%s'", type_str);
		gb_string_free(type_str);
		if (e->type == nullptr) {
			e->type = t_invalid;
		}
		return;
	}
#endif

	if (e->type == nullptr) { // NOTE(bill): type inference
		e->type = operand->type;
	}

	check_assignment(ctx, operand, e->type, str_lit("constant declaration"));
	if (operand->mode == Addressing_Invalid) {
		return;
	}

	e->parent_proc_decl = ctx->curr_proc_decl;

	e->Constant.value = operand->value;
}


bool is_type_distinct(Ast *node) {
	for (;;) {
		if (node == nullptr) {
			return false;
		}
		if (node->kind == Ast_ParenExpr) {
			node = node->ParenExpr.expr;
		} else if (node->kind == Ast_HelperType) {
			node = node->HelperType.type;
		} else {
			break;
		}
	}

	switch (node->kind) {
	case Ast_DistinctType:
		return true;

	case Ast_StructType:
	case Ast_UnionType:
	case Ast_EnumType:
	case Ast_BitFieldType:
	case Ast_ProcType:
		return true;

	case Ast_PointerType:
	case Ast_ArrayType:
	case Ast_DynamicArrayType:
	case Ast_MapType:
		return false;

	case Ast_OpaqueType:
		return true;
	}
	return false;
}

Ast *remove_type_alias_clutter(Ast *node) {
	for (;;) {
		if (node == nullptr) {
			return nullptr;
		}
		if (node->kind == Ast_ParenExpr) {
			node = node->ParenExpr.expr;
		} else if (node->kind == Ast_DistinctType) {
			node = node->DistinctType.type;
		} else {
			return node;
		}
	}
}

isize total_attribute_count(DeclInfo *decl) {
	isize attribute_count = 0;
	for_array(i, decl->attributes) {
		Ast *attr = decl->attributes[i];
		if (attr->kind != Ast_Attribute) continue;
		attribute_count += attr->Attribute.elems.count;
	}
	return attribute_count;
}


void check_type_decl(CheckerContext *ctx, Entity *e, Ast *init_expr, Type *def) {
	GB_ASSERT(e->type == nullptr);

	DeclInfo *decl = decl_info_of_entity(e);
	if (decl != nullptr) {
		check_decl_attributes(ctx, decl->attributes, const_decl_attribute, nullptr);
	}

	bool is_distinct = is_type_distinct(init_expr);
	Ast *te = remove_type_alias_clutter(init_expr);
	e->type = t_invalid;
	String name = e->token.string;
	Type *named = alloc_type_named(name, nullptr, e);
	if (def != nullptr && def->kind == Type_Named) {
		def->Named.base = named;
	}
	e->type = named;

	check_type_path_push(ctx, e);
	Type *bt = check_type_expr(ctx, te, named);
	check_type_path_pop(ctx);

	named->Named.base = base_type(bt);

	if (is_distinct && is_type_typeid(e->type)) {
		error(init_expr, "'distinct' cannot be applied to 'typeid'");
		is_distinct = false;
	}
	if (!is_distinct) {
		e->type = bt;
		named->Named.base = bt;
		e->TypeName.is_type_alias = true;
	}


	if (decl->type_expr != nullptr) {
		Type *t = check_type(ctx, decl->type_expr);
		if (t != nullptr && !is_type_typeid(t)) {
			Operand operand = {};
			operand.mode = Addressing_Type;
			operand.type = e->type;
			operand.expr = init_expr;
			check_assignment(ctx, &operand, t, str_lit("constant declaration"));
		}
	}


	// using decl
	if (decl->is_using) {
		// NOTE(bill): Must be an enum declaration
		if (te->kind == Ast_EnumType) {
			Scope *parent = e->scope;
			if (parent->flags&ScopeFlag_File) {
				// NOTE(bill): Use package scope
				parent = parent->parent;
			}

			Type *t = base_type(e->type);
			if (t->kind == Type_Enum) {
				for_array(i, t->Enum.fields) {
					Entity *f = t->Enum.fields[i];
					if (f->kind != Entity_Constant) {
						continue;
					}
					String name = f->token.string;
					if (is_blank_ident(name)) {
						continue;
					}
					add_entity(ctx->checker, parent, nullptr, f);
				}
			}
		}
	}
}


void override_entity_in_scope(Entity *original_entity, Entity *new_entity) {
	// NOTE(bill): The original_entity's scope may not be same scope that it was inserted into
	// e.g. file entity inserted into its package scope
	String original_name = original_entity->token.string;
	Scope *found_scope = nullptr;
	Entity *found_entity = nullptr;
	scope_lookup_parent(original_entity->scope, original_name, &found_scope, &found_entity);

	// IMPORTANT TODO(bill)
	// Date: 2018-09-29
	// This assert fails on `using import` if the name of the alias is the same. What should be the expected behaviour?
	// Namespace collision or override? Overridding is the current behaviour
	//
	//     using import "foo"
	//     bar :: foo.bar;

	// GB_ASSERT_MSG(found_entity == original_entity, "%.*s == %.*s", LIT(found_entity->token.string), LIT(new_entity->token.string));

	map_set(&found_scope->elements, hash_string(original_name), new_entity);
}



void check_const_decl(CheckerContext *ctx, Entity *e, Ast *type_expr, Ast *init, Type *named_type) {
	GB_ASSERT(e->type == nullptr);
	GB_ASSERT(e->kind == Entity_Constant);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	if (type_expr) {
		Type *t = check_type(ctx, type_expr);
		if (!is_type_constant_type(t) && !is_type_proc(t)) {
			gbString str = type_to_string(t);
			error(type_expr, "Invalid constant type '%s'", str);
			gb_string_free(str);
			e->type = t_invalid;
			return;
		}
		e->type = t;
	}

	Operand operand = {};

	if (init != nullptr) {
		Entity *entity = nullptr;
		if (init->kind == Ast_Ident) {
			entity = check_ident(ctx, &operand, init, nullptr, e->type, true);
		} else if (init->kind == Ast_SelectorExpr) {
			entity = check_selector(ctx, &operand, init, e->type);
		} else {
			check_expr_or_type(ctx, &operand, init, e->type);
		}

		switch (operand.mode) {
		case Addressing_Type: {
			if (e->type != nullptr && !is_type_typeid(e->type)) {
				check_assignment(ctx, &operand, e->type, str_lit("constant declaration"));
			}

			e->kind = Entity_TypeName;
			e->type = nullptr;

			check_type_decl(ctx, e, ctx->decl->init_expr, named_type);
			return;
		}

		// NOTE(bill): Check to see if the expression it to be aliases
		case Addressing_Builtin:
			if (e->type != nullptr) {
				error(type_expr, "A constant alias of a built-in procedure may not have a type initializer");
			}
			e->kind = Entity_Builtin;
			e->Builtin.id = operand.builtin_id;
			e->type = t_invalid;
			return;

		case Addressing_ProcGroup:
			GB_ASSERT(operand.proc_group != nullptr);
			GB_ASSERT(operand.proc_group->kind == Entity_ProcGroup);
			override_entity_in_scope(e, operand.proc_group);
			return;
		}

		if (entity != nullptr) {
			if (e->type != nullptr) {
				Operand x = {};
				x.type = entity->type;
				x.mode = Addressing_Variable;
				if (!check_is_assignable_to(ctx, &x, e->type)) {
					gbString expr_str = expr_to_string(init);
					gbString op_type_str = type_to_string(entity->type);
					gbString type_str = type_to_string(e->type);
					error(e->token,
					      "Cannot assign '%s' of type '%s' to '%s'",
					      expr_str,
					      op_type_str,
					      type_str);

					gb_string_free(type_str);
					gb_string_free(op_type_str);
					gb_string_free(expr_str);
				}
			}

			// NOTE(bill): Override aliased entity
			switch (entity->kind) {
			case Entity_ProcGroup:
			case Entity_Procedure:
			case Entity_LibraryName:
			case Entity_ImportName:
				{
					override_entity_in_scope(e, entity);

					DeclInfo *decl = decl_info_of_entity(e);
					if (decl != nullptr) {
						if (decl->attributes.count > 0) {
							error(decl->attributes[0], "Constant alias declarations cannot have attributes");
						}
					}

					return;
				}
			}
		}
	}

	check_init_constant(ctx, e, &operand);

	if (operand.mode == Addressing_Invalid ||
		base_type(operand.type) == t_invalid) {
		gbString str = expr_to_string(init);
		error(e->token, "Invalid declaration type '%s'", str);
		gb_string_free(str);
	}


	DeclInfo *decl = decl_info_of_entity(e);
	if (decl != nullptr) {
		check_decl_attributes(ctx, decl->attributes, const_decl_attribute, nullptr);
	}
}


typedef bool TypeCheckSig(Type *t);
bool sig_compare(TypeCheckSig *a, Type *x, Type *y) {
	return (a(x) && a(y));
}
bool sig_compare(TypeCheckSig *a, TypeCheckSig *b, Type *x, Type *y) {
	if (a == b) {
		return sig_compare(a, x, y);
	}
	return ((a(x) && b(y)) || (b(x) && a(y)));
}

bool signature_parameter_similar_enough(Type *x, Type *y) {
	if (sig_compare(is_type_pointer, x, y)) {
		return true;
	}

	if (sig_compare(is_type_integer, x, y)) {
		GB_ASSERT(x->kind == Type_Basic);
		GB_ASSERT(y->kind == Type_Basic);
		i64 sx = type_size_of(x);
		i64 sy = type_size_of(y);
		if (sx == sy) return true;
	}

	if (sig_compare(is_type_integer, is_type_boolean, x, y)) {
		GB_ASSERT(x->kind == Type_Basic);
		GB_ASSERT(y->kind == Type_Basic);
		i64 sx = type_size_of(x);
		i64 sy = type_size_of(y);
		if (sx == sy) return true;
	}
	if (sig_compare(is_type_cstring, is_type_u8_ptr, x, y)) {
		return true;
	}

	if (sig_compare(is_type_uintptr, is_type_rawptr, x, y)) {
		return true;
	}

	return are_types_identical(x, y);
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
		if (!signature_parameter_similar_enough(x, y)) {
			return false;
		}
	}
	for (isize i = 0; i < a->result_count; i++) {
		Type *x = base_type(a->results->Tuple.variables[i]->type);
		Type *y = base_type(b->results->Tuple.variables[i]->type);
		if (!signature_parameter_similar_enough(x, y)) {
			return false;
		}
	}

	return true;
}

void init_entity_foreign_library(CheckerContext *ctx, Entity *e) {
	Ast *ident = nullptr;
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
	} else if (ident->kind != Ast_Ident) {
		error(ident, "foreign library names must be an identifier");
	} else {
		String name = ident->Ident.token.string;
		Entity *found = scope_lookup(ctx->scope, name);
		if (found == nullptr) {
			if (is_blank_ident(name)) {
				// NOTE(bill): link against nothing
			} else {
				error(ident, "Undeclared name: %.*s", LIT(name));
			}
		} else if (found->kind != Entity_LibraryName) {
			error(ident, "'%.*s' cannot be used as a library name", LIT(name));
		} else {
			// TODO(bill): Extra stuff to do with library names?
			*foreign_library = found;
			found->flags |= EntityFlag_Used;
			add_entity_use(ctx, ident, found);
		}
	}
}

String handle_link_name(CheckerContext *ctx, Token token, String link_name, String link_prefix) {
	if (link_prefix.len > 0) {
		if (link_name.len > 0) {
			error(token, "'link_name' and 'link_prefix' cannot be used together");
		} else {
			isize len = link_prefix.len + token.string.len;
			u8 *name = gb_alloc_array(ctx->allocator, u8, len+1);
			gb_memmove(name, &link_prefix[0], link_prefix.len);
			gb_memmove(name+link_prefix.len, &token.string[0], token.string.len);
			name[len] = 0;

			link_name = make_string(name, len);
		}
	}
	return link_name;
}

void check_proc_decl(CheckerContext *ctx, Entity *e, DeclInfo *d) {
	GB_ASSERT(e->type == nullptr);
	if (d->proc_lit->kind != Ast_ProcLit) {
		// TOOD(bill): Better error message
		error(d->proc_lit, "Expected a procedure to check");
		return;
	}

	Type *proc_type = e->type;
	if (d->gen_proc_type != nullptr) {
		proc_type = d->gen_proc_type;
	} else {
		proc_type = alloc_type_proc(e->scope, nullptr, 0, nullptr, 0, false, ProcCC_Odin);
	}
	e->type = proc_type;
	ast_node(pl, ProcLit, d->proc_lit);

	check_open_scope(ctx, pl->type);
	defer (check_close_scope(ctx));

	Type *decl_type = nullptr;

	if (d->type_expr != nullptr) {
		decl_type = check_type(ctx, d->type_expr);
		if (!is_type_proc(decl_type)) {
			gbString str = type_to_string(decl_type);
			error(d->type_expr, "Expected a procedure type, got '%s'", str);
			gb_string_free(str);
		}
	}


	auto tmp_ctx = *ctx;
	tmp_ctx.allow_polymorphic_types = true;
	if (decl_type != nullptr) {
		tmp_ctx.type_hint = decl_type;
	}
	check_procedure_type(&tmp_ctx, proc_type, pl->type);

	if (decl_type != nullptr) {
		Operand x = {};
		x.type = e->type;
		x.mode = Addressing_Variable;
		if (!check_is_assignable_to(ctx, &x, decl_type)) {
			gbString expr_str = expr_to_string(d->proc_lit);
			gbString op_type_str = type_to_string(e->type);
			gbString type_str = type_to_string(decl_type);
			error(e->token,
			      "Cannot assign '%s' of type '%s' to '%s'",
			      expr_str,
			      op_type_str,
			      type_str);

			gb_string_free(type_str);
			gb_string_free(op_type_str);
			gb_string_free(expr_str);
		}
	}

	TypeProc *pt = &proc_type->Proc;
	AttributeContext ac = make_attribute_context(e->Procedure.link_prefix);

	if (d != nullptr) {
		check_decl_attributes(ctx, d->attributes, proc_decl_attribute, &ac);
	}

	e->Procedure.is_export = ac.is_export;
	e->deprecated_message = ac.deprecated_message;
	ac.link_name = handle_link_name(ctx, e->token, ac.link_name, ac.link_prefix);
	if (ac.has_disabled_proc) {
		if (ac.disabled_proc) {
			e->flags |= EntityFlag_Disabled;
		}
		Type *t = base_type(e->type);
		GB_ASSERT(t->kind == Type_Proc);
		if (t->Proc.result_count != 0) {
			error(e->token, "Procedure with the 'disabled' attribute may not have any return values");
		}
	}

	bool is_foreign         = e->Procedure.is_foreign;
	bool is_export          = e->Procedure.is_export;

	if (e->pkg != nullptr && e->token.string == "main") {
		if (pt->param_count != 0 ||
		    pt->result_count != 0) {
			gbString str = type_to_string(proc_type);
			error(e->token, "Procedure type of 'main' was expected to be 'proc()', got %s", str);
			gb_string_free(str);
		}
		if (pt->calling_convention != ProcCC_Odin &&
		    pt->calling_convention != ProcCC_Contextless) {
			error(e->token, "Procedure 'main' cannot have a custom calling convention");
		}
		pt->calling_convention = ProcCC_Contextless;
		if (e->pkg->kind == Package_Init) {
			if (ctx->info->entry_point != nullptr) {
				error(e->token, "Redeclaration of the entry pointer procedure 'main'");
			} else {
				ctx->info->entry_point = e;
			}
		}
	}

	if (is_foreign && is_export) {
		error(pl->type, "A foreign procedure cannot have an 'export' tag");
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
			error(pl->body, "A procedure with a '#c_vararg' field cannot have a body and must be foreign");
		}

		d->scope = ctx->scope;

		GB_ASSERT(pl->body->kind == Ast_BlockStmt);
		if (!pt->is_polymorphic) {
			check_procedure_later(ctx->checker, ctx->file, e->token, d, proc_type, pl->body, pl->tags);
		}
	} else if (!is_foreign) {
		if (e->Procedure.is_export) {
			error(e->token, "Foreign export procedures must have a body");
		} else {
			error(e->token, "Only a foreign procedure cannot have a body");
		}
	}

	if (pt->result_count == 0 && ac.require_results) {
		error(pl->type, "'require_results' is not needed on a procedure with no results");
	} else {
		pt->require_results = ac.require_results;
	}

	if (ac.link_name.len > 0) {
		e->Procedure.link_name = ac.link_name;
	}

	if (ac.deferred_procedure.entity != nullptr) {
		e->Procedure.deferred_procedure = ac.deferred_procedure;
		array_add(&ctx->checker->procs_with_deferred_to_check, e);
	}

	if (is_foreign) {
		String name = e->token.string;
		if (e->Procedure.link_name.len > 0) {
			name = e->Procedure.link_name;
		}
		e->Procedure.is_foreign = true;
		e->Procedure.link_name = name;

		init_entity_foreign_library(ctx, e);

		auto *fp = &ctx->info->foreigns;
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
					      "Redeclaration of foreign procedure '%.*s' with different type signatures\n"
					      "\tat %.*s(%td:%td)",
					      LIT(name), LIT(pos.file), pos.line, pos.column);
				}
			} else if (!are_types_identical(this_type, other_type)) {
				error(d->proc_lit,
				      "Foreign entity '%.*s' previously declared elsewhere with a different type\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name), LIT(pos.file), pos.line, pos.column);
			}
		} else if (name == "main") {
			error(d->proc_lit, "The link name 'main' is reserved for internal use");
		} else {
			map_set(fp, key, e);
		}
	} else {
		String name = e->token.string;
		if (e->Procedure.link_name.len > 0) {
			name = e->Procedure.link_name;
		}
		if (e->Procedure.link_name.len > 0 || is_export) {
			auto *fp = &ctx->info->foreigns;
			HashKey key = hash_string(name);
			Entity **found = map_get(fp, key);
			if (found) {
				Entity *f = *found;
				TokenPos pos = f->token.pos;
				// TODO(bill): Better error message?
				error(d->proc_lit,
				      "Non unique linking name for procedure '%.*s'\n"
				      "\tother at %.*s(%td:%td)",
				      LIT(name), LIT(pos.file), pos.line, pos.column);
			} else if (name == "main") {
				error(d->proc_lit, "The link name 'main' is reserved for internal use");
			} else {
				map_set(fp, key, e);
			}
		}
	}
}

void check_global_variable_decl(CheckerContext *ctx, Entity *e, Ast *type_expr, Ast *init_expr) {
	GB_ASSERT(e->type == nullptr);
	GB_ASSERT(e->kind == Entity_Variable);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	AttributeContext ac = make_attribute_context(e->Variable.link_prefix);
	ac.init_expr_list_count = init_expr != nullptr ? 1 : 0;

	DeclInfo *decl = decl_info_of_entity(e);
	GB_ASSERT(decl == ctx->decl);
	if (decl != nullptr) {
		check_decl_attributes(ctx, decl->attributes, var_decl_attribute, &ac);
	}

	e->Variable.thread_local_model = ac.thread_local_model;
	e->Variable.is_export = ac.is_export;
	if (ac.is_static) {
		e->flags |= EntityFlag_Static;
	} else {
		e->flags &= ~EntityFlag_Static;
	}
	ac.link_name = handle_link_name(ctx, e->token, ac.link_name, ac.link_prefix);

	String context_name = str_lit("variable declaration");

	if (type_expr != nullptr) {
		e->type = check_type(ctx, type_expr);
	}
	if (e->type != nullptr) {
		if (is_type_polymorphic(base_type(e->type))) {
			gbString str = type_to_string(e->type);
			defer (gb_string_free(str));
			error(e->token, "Invalid use of a polymorphic type '%s' in %.*s", str, LIT(context_name));
			e->type = t_invalid;
		} else if (is_type_empty_union(e->type)) {
			gbString str = type_to_string(e->type);
			defer (gb_string_free(str));
			error(e->token, "An empty union '%s' cannot be instantiated in %.*s", str, LIT(context_name));
			e->type = t_invalid;
		}
	}


	if (e->Variable.is_foreign) {
		if (init_expr != nullptr) {
			error(e->token, "A foreign variable declaration cannot have a default value");
		}
		init_entity_foreign_library(ctx, e);
	}
	if (ac.link_name.len > 0) {
		e->Variable.link_name = ac.link_name;
	}

	if (e->Variable.is_foreign || e->Variable.is_export) {
		String name = e->token.string;
		if (e->Variable.link_name.len > 0) {
			name = e->Variable.link_name;
		}

		auto *fp = &ctx->info->foreigns;
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
	}

	if (init_expr == nullptr) {
		if (type_expr == nullptr) {
			e->type = t_invalid;
		}
		return;
	}

	Operand o = {};
	check_expr_with_type_hint(ctx, &o, init_expr, e->type);
	check_init_variable(ctx, e, &o, str_lit("variable declaration"));
}

void check_proc_group_decl(CheckerContext *ctx, Entity *pg_entity, DeclInfo *d) {
	GB_ASSERT(pg_entity->kind == Entity_ProcGroup);
	auto *pge = &pg_entity->ProcGroup;
	String proc_group_name = pg_entity->token.string;

	ast_node(pg, ProcGroup, d->init_expr);

	pge->entities = array_make<Entity*>(ctx->allocator, 0, pg->args.count);

	// NOTE(bill): This must be set here to prevent cycles in checking if someone
	// places the entity within itself
	pg_entity->type = t_invalid;

	PtrSet<Entity *> entity_set = {};
	ptr_set_init(&entity_set, heap_allocator(), 2*pg->args.count);

	for_array(i, pg->args) {
		Ast *arg = pg->args[i];
		Entity *e = nullptr;
		Operand o = {};
		if (arg->kind == Ast_Ident) {
			e = check_ident(ctx, &o, arg, nullptr, nullptr, true);
		} else if (arg->kind == Ast_SelectorExpr) {
			e = check_selector(ctx, &o, arg, nullptr);
		}
		if (e == nullptr) {
			error(arg, "Expected a valid entity name in procedure group, got %.*s", LIT(ast_strings[arg->kind]));
			continue;
		}
		if (e->kind == Entity_Variable) {
			if (!is_type_proc(e->type)) {
				gbString s = type_to_string(e->type);
				defer (gb_string_free(s));
				error(arg, "Expected a procedure, got %s", s);
				continue;
			}
		} else if (e->kind != Entity_Procedure) {
			error(arg, "Expected a procedure entity");
			continue;
		}

		if (ptr_set_exists(&entity_set, e)) {
			error(arg, "Previous use of `%.*s` in procedure group", LIT(e->token.string));
			continue;
		}
		ptr_set_add(&entity_set, e);
		array_add(&pge->entities, e);
	}

	ptr_set_destroy(&entity_set);

	for_array(j, pge->entities) {
		Entity *p = pge->entities[j];
		if (p->type == t_invalid) {
			// NOTE(bill): This invalid overload has already been handled
			continue;
		}

		String name = p->token.string;

		for (isize k = j+1; k < pge->entities.count; k++) {
			Entity *q = pge->entities[k];
			GB_ASSERT(p != q);

			bool is_invalid = false;

			TokenPos pos = q->token.pos;

			if (q->type == nullptr || q->type == t_invalid) {
				continue;
			}

			begin_error_block();
			defer (end_error_block());

			ProcTypeOverloadKind kind = are_proc_types_overload_safe(p->type, q->type);
			bool both_have_where_clauses = false;
			if (p->decl_info->proc_lit != nullptr && q->decl_info->proc_lit != nullptr) {
				GB_ASSERT(p->decl_info->proc_lit->kind == Ast_ProcLit);
				GB_ASSERT(q->decl_info->proc_lit->kind == Ast_ProcLit);
				auto pl = &p->decl_info->proc_lit->ProcLit;
				auto ql = &q->decl_info->proc_lit->ProcLit;

				// Allow collisions if the procedures both have 'where' clauses and are both polymorphic
				bool pw = pl->where_token.kind != Token_Invalid && is_type_polymorphic(p->type, true);
				bool qw = ql->where_token.kind != Token_Invalid && is_type_polymorphic(q->type, true);
				both_have_where_clauses = pw && qw;
			}

			if (!both_have_where_clauses) switch (kind) {
			case ProcOverload_Identical:
				error(p->token, "Overloaded procedure '%.*s' as the same type as another procedure in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				is_invalid = true;
				break;
			// case ProcOverload_CallingConvention:
				// error(p->token, "Overloaded procedure '%.*s' as the same type as another procedure in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				// is_invalid = true;
				// break;
			case ProcOverload_ParamVariadic:
				error(p->token, "Overloaded procedure '%.*s' as the same type as another procedure in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				is_invalid = true;
				break;
			case ProcOverload_ResultCount:
			case ProcOverload_ResultTypes:
				error(p->token, "Overloaded procedure '%.*s' as the same parameters but different results in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				is_invalid = true;
				break;
			case ProcOverload_Polymorphic:
				#if 0
				error(p->token, "Overloaded procedure '%.*s' has a polymorphic counterpart in the procedure group '%.*s' which is not allowed", LIT(name), LIT(proc_group_name));
				is_invalid = true;
				#endif
				break;
			case ProcOverload_ParamCount:
			case ProcOverload_ParamTypes:
				// This is okay :)
				break;

			}

			if (is_invalid) {
				error_line("\tprevious procedure at %.*s(%td:%td)\n", LIT(pos.file), pos.line, pos.column);
				q->type = t_invalid;
			}
		}
	}

}

void check_entity_decl(CheckerContext *ctx, Entity *e, DeclInfo *d, Type *named_type) {
	if (e->state == EntityState_Resolved)  {
		return;
	}
	String name = e->token.string;

	if (e->type != nullptr || e->state != EntityState_Unresolved) {
		error(e->token, "Illegal declaration cycle of `%.*s`", LIT(name));
		return;
	}

	GB_ASSERT(e->state == EntityState_Unresolved);

#if 0
	char buf[256] = {};
	isize n = gb_snprintf(buf, 256, "%.*s %d", LIT(name), e->kind);
	Timings timings = {};
	timings_init(&timings, make_string(cast(u8 *)buf, n-1), 16);
	defer ({
		timings_print_all(&timings);
		timings_destroy(&timings);
	});
#define TIME_SECTION(str) timings_start_section(&timings, str_lit(str))
#else
#define TIME_SECTION(str)
#endif

	if (d == nullptr) {
		d = decl_info_of_entity(e);
		if (d == nullptr) {
			// TODO(bill): Err here?
			e->type = t_invalid;
			e->state = EntityState_Resolved;
			set_base_type(named_type, t_invalid);
			return;
			// GB_PANIC("'%.*s' should been declared!", LIT(name));
		}
	}

	CheckerContext c = *ctx;
	c.scope = d->scope;
	c.decl  = d;
	c.type_level = 0;

	e->parent_proc_decl = c.curr_proc_decl;
	e->state = EntityState_InProgress;

	switch (e->kind) {
	case Entity_Variable:
		check_global_variable_decl(&c, e, d->type_expr, d->init_expr);
		break;
	case Entity_Constant:
		check_const_decl(&c, e, d->type_expr, d->init_expr, named_type);
		break;
	case Entity_TypeName: {
		check_type_decl(&c, e, d->init_expr, named_type);
		break;
	}
	case Entity_Procedure:
		check_proc_decl(&c, e, d);
		break;
	case Entity_ProcGroup:
		check_proc_group_decl(&c, e, d);
		break;
	}

	e->state = EntityState_Resolved;

#undef TIME_SECTION
}


struct ProcUsingVar {
	Entity *e;
	Entity *uvar;
};


void check_proc_body(CheckerContext *ctx_, Token token, DeclInfo *decl, Type *type, Ast *body) {
	if (body == nullptr) {
		return;
	}
	GB_ASSERT(body->kind == Ast_BlockStmt);

	String proc_name = {};
	if (token.kind == Token_Ident) {
		proc_name = token.string;
	} else {
		// TODO(bill): Better name
		proc_name = str_lit("(anonymous-procedure)");
	}

	CheckerContext new_ctx = *ctx_;
	CheckerContext *ctx = &new_ctx;

	ctx->scope = decl->scope;
	ctx->decl = decl;
	ctx->proc_name = proc_name;
	ctx->curr_proc_decl = decl;
	ctx->curr_proc_sig  = type;

	ast_node(bs, BlockStmt, body);

	Array<ProcUsingVar> using_entities = {};
	using_entities.allocator = heap_allocator();
	defer (array_free(&using_entities));

	{
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
				bool is_value     = (e->flags & EntityFlag_Value) != 0 && !is_type_pointer(e->type);
				String name = e->token.string;
				Type *t = base_type(type_deref(e->type));
				if (t->kind == Type_Struct) {
					Scope *scope = t->Struct.scope;
					if (scope == nullptr) {
						scope = scope_of_node(t->Struct.node);
					}
					GB_ASSERT(scope != nullptr);
					for_array(i, scope->elements.entries) {
						Entity *f = scope->elements.entries[i].value;
						if (f->kind == Entity_Variable) {
							Entity *uvar = alloc_entity_using_variable(e, f->token, f->type, nullptr);
							if (is_value) uvar->flags |= EntityFlag_Value;

							ProcUsingVar puv = {e, uvar};
							array_add(&using_entities, puv);

						}
					}
				} else {
					error(e->token, "'using' can only be applied to variables of type struct");
					break;
				}
			}
		}
	}


	for_array(i, using_entities) {
		Entity *e = using_entities[i].e;
		Entity *uvar = using_entities[i].uvar;
		Entity *prev = scope_insert(ctx->scope, uvar);
		if (prev != nullptr) {
			error(e->token, "Namespace collision while 'using' '%.*s' of: %.*s", LIT(e->token.string), LIT(prev->token.string));
			break;
		}
	}


	bool where_clause_ok = evaluate_where_clauses(ctx, decl->scope, &decl->proc_lit->ProcLit.where_clauses, true);
	if (!where_clause_ok) {
		// NOTE(bill, 2019-08-31): Don't check the body as the where clauses failed
		return;
	}

	check_open_scope(ctx, body);
	{
		for_array(i, using_entities) {
			Entity *e = using_entities[i].e;
			Entity *uvar = using_entities[i].uvar;
			Entity *prev = scope_insert(ctx->scope, uvar);
			// NOTE(bill): Don't err here
		}

		check_stmt_list(ctx, bs->stmts, Stmt_CheckScopeDecls);

		if (type->Proc.result_count > 0) {
			if (!check_is_terminating(body)) {
				if (token.kind == Token_Ident) {
					error(bs->close, "Missing return statement at the end of the procedure '%.*s'", LIT(token.string));
				} else {
					// NOTE(bill): Anonymous procedure (lambda)
					error(bs->close, "Missing return statement at the end of the procedure");
				}
			}
		}
	}
	check_close_scope(ctx);

	check_scope_usage(ctx->checker, ctx->scope);

#if 1
	if (decl->parent != nullptr) {
		Scope *ps = decl->parent->scope;
		if (ps->flags & (ScopeFlag_File & ScopeFlag_Pkg & ScopeFlag_Global)) {
			return;
		} else {
			// NOTE(bill): Add the dependencies from the procedure literal (lambda)
			// But only at the procedure level
			for_array(i, decl->deps.entries) {
				Entity *e = decl->deps.entries[i].ptr;
				ptr_set_add(&decl->parent->deps, e);
			}
			for_array(i, decl->type_info_deps.entries) {
				Type *t = decl->type_info_deps.entries[i].ptr;
				ptr_set_add(&decl->parent->type_info_deps, t);
			}
		}
	}
#endif
}




