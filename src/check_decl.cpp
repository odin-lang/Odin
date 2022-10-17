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

	if (e->kind == Entity_Variable) {
		e->Variable.init_expr = operand->expr;
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
				error_line("\tThe type of the variable '%.*s' cannot be inferred as a type does not have a default type\n", LIT(e->token.string));
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
		if (is_type_asm_proc(t)) {
			error(e->token, "Invalid use of inline asm in %.*s", LIT(context_name));
			e->type = t_invalid;
			return nullptr;
		} else if (is_type_polymorphic(t)) {
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

void check_init_variables(CheckerContext *ctx, Entity **lhs, isize lhs_count, Slice<Ast *> const &inits, String context_name) {
	if ((lhs == nullptr || lhs_count == 0) && inits.count == 0) {
		return;
	}


	// NOTE(bill): If there is a bad syntax error, rhs > lhs which would mean there would need to be
	// an extra allocation
	auto operands = array_make<Operand>(temporary_allocator(), 0, 2*lhs_count);
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

	if (e->type == nullptr) { // NOTE(bill): type inference
		e->type = operand->type;
	}

	check_assignment(ctx, operand, e->type, str_lit("constant declaration"));
	if (operand->mode == Addressing_Invalid) {
		return;
	}

	if (is_type_proc(e->type)) {
		error(e->token, "Illegal declaration of a constant procedure value");
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
	case Ast_ProcType:
		return true;

	case Ast_PointerType:
	case Ast_ArrayType:
	case Ast_DynamicArrayType:
	case Ast_MapType:
		return false;
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

Type *clone_enum_type(CheckerContext *ctx, Type *original_enum_type, Type *named_type) {
	// NOTE(bill, 2022-02-05): Stupid edge case for `distinct` declarations
	//
	//         X :: enum {A, B, C}
	//         Y :: distinct X
	//
	// To make Y be just like X, it will need to copy the elements of X and change their type
	// so that they match Y rather than X.
	GB_ASSERT(original_enum_type != nullptr);
	GB_ASSERT(named_type != nullptr);
	GB_ASSERT(original_enum_type->kind == Type_Enum);
	GB_ASSERT(named_type->kind == Type_Named);

	Scope *parent = original_enum_type->Enum.scope->parent;
	Scope *scope = create_scope(nullptr, parent);


	Type *et = alloc_type_enum();
	et->Enum.base_type = original_enum_type->Enum.base_type;
	et->Enum.min_value = original_enum_type->Enum.min_value;
	et->Enum.max_value = original_enum_type->Enum.max_value;
	et->Enum.min_value_index = original_enum_type->Enum.min_value_index;
	et->Enum.max_value_index = original_enum_type->Enum.max_value_index;
	et->Enum.scope = scope;

	auto fields = array_make<Entity *>(permanent_allocator(), original_enum_type->Enum.fields.count);
	for_array(i, fields) {
		Entity *old = original_enum_type->Enum.fields[i];

		Entity *e = alloc_entity_constant(scope, old->token, named_type, old->Constant.value);
		e->file = old->file;
		e->identifier = clone_ast(old->identifier);
		e->flags |= EntityFlag_Visited;
		e->state = EntityState_Resolved;
		e->Constant.flags = old->Constant.flags;
		e->Constant.docs = old->Constant.docs;
		e->Constant.comment = old->Constant.comment;

		fields[i] = e;
		add_entity(ctx, scope, nullptr, e);
		add_entity_use(ctx, e->identifier, e);
	}
	et->Enum.fields = fields;
	return et;
}

void check_type_decl(CheckerContext *ctx, Entity *e, Ast *init_expr, Type *def) {
	GB_ASSERT(e->type == nullptr);

	DeclInfo *decl = decl_info_of_entity(e);

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

	Type *base = base_type(bt);
	if (is_distinct && bt->kind == Type_Named && base->kind == Type_Enum) {
		base = clone_enum_type(ctx, base, named);
	}
	named->Named.base = base;

	if (is_distinct) {
		if (is_type_typeid(e->type)) {
			error(init_expr, "'distinct' cannot be applied to 'typeid'");
			is_distinct = false;
		} else if (is_type_any(e->type)) {
			error(init_expr, "'distinct' cannot be applied to 'any'");
			is_distinct = false;
		} else if (is_type_simd_vector(e->type) || is_type_soa_pointer(e->type)) {
			gbString str = type_to_string(e->type);
			error(init_expr, "'distinct' cannot be applied to '%s'", str);
			gb_string_free(str);
			is_distinct = false;
		}
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

	if (decl != nullptr) {
		AttributeContext ac = {};
		check_decl_attributes(ctx, decl->attributes, type_decl_attribute, &ac);
		if (e->kind == Entity_TypeName && ac.objc_class != "") {
			e->TypeName.objc_class_name = ac.objc_class;

			if (type_size_of(e->type) > 0) {
				error(e->token, "@(objc_class) marked type must be of zero size");
			}
		}
	}


	// using decl
	if (decl->is_using) {
		warning(init_expr, "'using' an enum declaration is not allowed, prefer using implicit selector expressions e.g. '.A'");
		#if 1
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
					add_entity(ctx, parent, nullptr, f);
				}
			}
		}
		#endif
	}
}


void override_entity_in_scope(Entity *original_entity, Entity *new_entity) {
	// NOTE(bill): The original_entity's scope may not be same scope that it was inserted into
	// e.g. file entity inserted into its package scope
	String original_name = original_entity->token.string;
	Scope *found_scope = nullptr;
	Entity *found_entity = nullptr;
	scope_lookup_parent(original_entity->scope, original_name, &found_scope, &found_entity);
	if (found_scope == nullptr) {
		return;
	}
	mutex_lock(&found_scope->mutex);
	defer (mutex_unlock(&found_scope->mutex));

	// IMPORTANT NOTE(bill, 2021-04-10): Overriding behaviour was flawed in that the
	// original entity was still used check checked, but the checking was only
	// relying on "constant" data such as the Entity.type and Entity.Constant.value
	//
	// Therefore two things can be done: the type can be assigned to state that it
	// has been "evaluated" and the variant data can be copied across

	string_map_set(&found_scope->elements, original_name, new_entity);

	original_entity->flags |= EntityFlag_Overridden;
	original_entity->type = new_entity->type;
	original_entity->aliased_of = new_entity;

	Ast *empty_ident = nullptr;
	original_entity->identifier.compare_exchange_strong(empty_ident, new_entity->identifier);

	if (original_entity->identifier.load() != nullptr &&
	    original_entity->identifier.load()->kind == Ast_Ident) {
		original_entity->identifier.load()->Ident.entity = new_entity;
	}

	// IMPORTANT NOTE(bill, 2021-04-10): copy only the variants
	// This is most likely NEVER required, but it does not at all hurt to keep
	isize offset = cast(u8 *)&original_entity->Dummy.start - cast(u8 *)original_entity;
	isize size = gb_size_of(*original_entity) - offset;
	gb_memmove(cast(u8 *)original_entity, cast(u8 *)new_entity, size);
}



void check_const_decl(CheckerContext *ctx, Entity *e, Ast *type_expr, Ast *init, Type *named_type) {
	GB_ASSERT(e->type == nullptr);
	GB_ASSERT(e->kind == Entity_Constant);
	init = unparen_expr(init);

	if (e->flags & EntityFlag_Visited) {
		e->type = t_invalid;
		return;
	}
	e->flags |= EntityFlag_Visited;

	if (type_expr) {
		e->type = check_type(ctx, type_expr);
		if (are_types_identical(e->type, t_typeid)) {
			e->type = nullptr;
			e->kind = Entity_TypeName;
			check_type_decl(ctx, e, init, named_type);
			return;
		}
	}

	Operand operand = {};

	if (init != nullptr) {
		Entity *entity = check_entity_from_ident_or_selector(ctx, init, false);
		if (entity != nullptr && entity->kind == Entity_TypeName) {
			// @TypeAliasingProblem
			// NOTE(bill, 2022-02-03): This is used to solve the problem caused by type aliases
			// being "confused" as constants
			//
			//         A :: B
			//         C :: proc "c" (^A)
			//         B :: struct {x: C}
			//
			//     A gets evaluated first, and then checks B.
			//     B then checks C.
			//     C then tries to check A which is unresolved but thought to be a constant.
			//     Therefore within C's check, A errs as "not a type".
			//
			// This is because a const declaration may or may not be a type and this cannot
			// be determined from a syntactical standpoint.
			// This check allows the compiler to override the entity to be checked as a type.
			//
			// There is no problem if B is prefixed with the `#type` helper enforcing at
			// both a syntax and semantic level that B must be a type.
			//
			//         A :: #type B
			//
			// This approach is not fool proof and can fail in case such as:
			//
			//         X :: type_of(x)
			//         X :: Foo(int).Type
			//
			// Since even these kind of declarations may cause weird checking cycles.
			// For the time being, these are going to be treated as an unfortunate error
			// until there is a proper delaying system to try declaration again if they
			// have failed.

			e->kind = Entity_TypeName;
			check_type_decl(ctx, e, init, named_type);
			return;
		}
		entity = nullptr;
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

			if (entity != nullptr && entity->type != nullptr &&
			    is_type_polymorphic_record_unspecialized(entity->type)) {
				DeclInfo *decl = decl_info_of_entity(e);
				if (decl != nullptr) {
					if (decl->attributes.count > 0) {
						error(decl->attributes[0], "Constant alias declarations cannot have attributes");
					}
				}

				override_entity_in_scope(e, entity);
				return;
			}
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
			// NOTE(bill, 2020-06-10): It is better to just clone the contents than overriding the entity in the scope
			// Thank goodness I made entities a tagged union to allow for this implace patching
			e->kind = Entity_ProcGroup;
			e->ProcGroup.entities = array_clone(heap_allocator(), operand.proc_group->ProcGroup.entities);
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
					DeclInfo *decl = decl_info_of_entity(e);
					if (decl != nullptr) {
						if (decl->attributes.count > 0) {
							error(decl->attributes[0], "Constant alias declarations cannot have attributes");
						}
					}

					override_entity_in_scope(e, entity);
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
	x = core_type(x);
	y = core_type(y);
	return (a(x) && a(y));
}
bool sig_compare(TypeCheckSig *a, TypeCheckSig *b, Type *x, Type *y) {
	x = core_type(x);
	y = core_type(y);
	if (a == b) {
		return sig_compare(a, x, y);
	}
	return ((a(x) && b(y)) || (b(x) && a(y)));
}

bool signature_parameter_similar_enough(Type *x, Type *y) {
	if (sig_compare(is_type_pointer, x, y)) {
		return true;
	}
	if (sig_compare(is_type_multi_pointer, x, y)) {
		return true;
	}
	if (sig_compare(is_type_proc, x, y)) {
		return true;
	}

	if (sig_compare(is_type_integer, x, y)) {
		GB_ASSERT(core_type(x)->kind == Type_Basic);
		GB_ASSERT(core_type(y)->kind == Type_Basic);
		i64 sx = type_size_of(x);
		i64 sy = type_size_of(y);
		if (sx == sy) return true;
	}

	if (sig_compare(is_type_integer, is_type_boolean, x, y)) {
		GB_ASSERT(core_type(x)->kind == Type_Basic);
		GB_ASSERT(core_type(y)->kind == Type_Basic);
		i64 sx = type_size_of(x);
		i64 sy = type_size_of(y);
		if (sx == sy) return true;
	}
	if (sig_compare(is_type_cstring, is_type_u8_ptr, x, y)) {
		return true;
	}
	if (sig_compare(is_type_cstring, is_type_u8_multi_ptr, x, y)) {
		return true;
	}

	if (sig_compare(is_type_uintptr, is_type_rawptr, x, y)) {
		return true;
	}

	if (sig_compare(is_type_proc, is_type_pointer, x, y)) {
		return true;
	}
	if (sig_compare(is_type_pointer, is_type_multi_pointer, x, y)) {
		return true;
	}
	if (sig_compare(is_type_proc, is_type_multi_pointer, x, y)) {
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

Entity *init_entity_foreign_library(CheckerContext *ctx, Entity *e) {
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
		return nullptr;
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
			return found;
		}
	}
	return nullptr;
}

String handle_link_name(CheckerContext *ctx, Token token, String link_name, String link_prefix) {
	if (link_prefix.len > 0) {
		if (link_name.len > 0) {
			error(token, "'link_name' and 'link_prefix' cannot be used together");
		} else {
			isize len = link_prefix.len + token.string.len;
			u8 *name = gb_alloc_array(permanent_allocator(), u8, len+1);
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
		proc_type = alloc_type_proc(e->scope, nullptr, 0, nullptr, 0, false, default_calling_convention());
	}
	e->type = proc_type;
	ast_node(pl, ProcLit, d->proc_lit);

	check_open_scope(ctx, pl->type);
	defer (check_close_scope(ctx));
	ctx->scope->procedure_entity = e;

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

	if (ac.test) {
		e->flags |= EntityFlag_Test;
	}
	if (ac.init) {
		e->flags |= EntityFlag_Init;
	}
	if (ac.set_cold) {
		e->flags |= EntityFlag_Cold;
	}
	e->Procedure.optimization_mode = cast(ProcedureOptimizationMode)ac.optimization_mode;

	if (ac.objc_name.len || ac.objc_is_class_method || ac.objc_type) {
		if (ac.objc_name.len == 0 && ac.objc_is_class_method) {
			error(e->token, "@(objc_name) is required with @(objc_is_class_method)");
		} else if (ac.objc_type == nullptr) {
			error(e->token, "@(objc_name) requires that @(objc_type) to be set");
		} else if (ac.objc_name.len == 0 && ac.objc_type) {
			error(e->token, "@(objc_name) is required with @(objc_type)");
		} else {
			Type *t = ac.objc_type;
			if (t->kind == Type_Named) {
				Entity *tn = t->Named.type_name;

				GB_ASSERT(tn->kind == Entity_TypeName);

				if (tn->scope != e->scope) {
					error(e->token, "@(objc_name) attribute may only be applied to procedures and types within the same scope");
				} else {
					mutex_lock(&global_type_name_objc_metadata_mutex);
					defer (mutex_unlock(&global_type_name_objc_metadata_mutex));

					if (!tn->TypeName.objc_metadata) {
						tn->TypeName.objc_metadata = create_type_name_obj_c_metadata();
					}
					auto *md = tn->TypeName.objc_metadata;
					mutex_lock(md->mutex);
					defer (mutex_unlock(md->mutex));

					if (!ac.objc_is_class_method) {
						bool ok = true;
						for (TypeNameObjCMetadataEntry const &entry : md->value_entries) {
							if (entry.name == ac.objc_name) {
								error(e->token, "Previous declaration of @(objc_name=\"%.*s\")", LIT(ac.objc_name));
								ok = false;
								break;
							}
						}
						if (ok) {
							array_add(&md->value_entries, TypeNameObjCMetadataEntry{ac.objc_name, e});
						}
					} else {
						bool ok = true;
						for (TypeNameObjCMetadataEntry const &entry : md->type_entries) {
							if (entry.name == ac.objc_name) {
								error(e->token, "Previous declaration of @(objc_name=\"%.*s\")", LIT(ac.objc_name));
								ok = false;
								break;
							}
						}
						if (ok) {
							array_add(&md->type_entries, TypeNameObjCMetadataEntry{ac.objc_name, e});
						}
					}
				}
			}
		}
	}

	if (ac.require_target_feature.len != 0 && ac.enable_target_feature.len != 0) {
		error(e->token, "Attributes @(require_target_feature=...) and @(enable_target_feature=...) cannot be used together");
	} else if (ac.require_target_feature.len != 0) {
		if (check_target_feature_is_enabled(e->token.pos, ac.require_target_feature)) {
			e->Procedure.target_feature = ac.require_target_feature;
		} else {
			e->Procedure.target_feature_disabled = true;
		}
	} else if (ac.enable_target_feature.len != 0) {
		enable_target_feature(e->token.pos, ac.enable_target_feature);
		e->Procedure.target_feature = ac.enable_target_feature;
	}

	switch (e->Procedure.optimization_mode) {
	case ProcedureOptimizationMode_None:
	case ProcedureOptimizationMode_Minimal:
		if (pl->inlining == ProcInlining_inline) {
			error(e->token, "#force_inline cannot be used in conjunction with the attribute 'optimization_mode' with neither \"none\" nor \"minimal\"");
		}
		break;
	}

	e->Procedure.is_export = ac.is_export;
	e->deprecated_message = ac.deprecated_message;
	e->warning_message = ac.warning_message;
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

	bool is_foreign = e->Procedure.is_foreign;
	bool is_export  = e->Procedure.is_export;
	
	if (ac.linkage.len != 0) {
		     if (ac.linkage == "internal")  { e->flags |= EntityFlag_CustomLinkage_Internal; }
		else if (ac.linkage == "strong")    { e->flags |= EntityFlag_CustomLinkage_Strong;   }
		else if (ac.linkage == "weak")      { e->flags |= EntityFlag_CustomLinkage_Weak;     }
		else if (ac.linkage == "link_once") { e->flags |= EntityFlag_CustomLinkage_LinkOnce; }
		
		if (is_foreign && (e->flags & EntityFlag_CustomLinkage_Internal)) {
			error(e->token, "A foreign procedure may not have an \"internal\" linkage");
		}
	}

	if (ac.require_declaration) {
		e->flags |= EntityFlag_Require;
	}


	if (e->pkg != nullptr && e->token.string == "main") {
		if (e->pkg->kind != Package_Runtime) {
			if (pt->param_count != 0 ||
			    pt->result_count != 0) {
				gbString str = type_to_string(proc_type);
				error(e->token, "Procedure type of 'main' was expected to be 'proc()', got %s", str);
				gb_string_free(str);
			}
			if (pt->calling_convention != default_calling_convention()) {
				error(e->token, "Procedure 'main' cannot have a custom calling convention");
			}
			pt->calling_convention = default_calling_convention();
			if (e->pkg->kind == Package_Init) {
				if (ctx->info->entry_point != nullptr) {
					error(e->token, "Redeclaration of the entry pointer procedure 'main'");
				} else {
					ctx->info->entry_point = e;
				}
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
			check_procedure_later(ctx, ctx->file, e->token, d, proc_type, pl->body, pl->tags);
		}
	} else if (!is_foreign) {
		if (e->Procedure.is_export) {
			error(e->token, "Foreign export procedures must have a body");
		} else {
			error(e->token, "Only a foreign procedure cannot have a body");
		}
	}

	if (ac.require_results) {
		if (pt->result_count == 0) {
			error(pl->type, "'require_results' is not needed on a procedure with no results");
		} else {
			pt->require_results = true;
		}
	}

	if (ac.link_name.len > 0) {
		e->Procedure.link_name = ac.link_name;
	}

	if (ac.deferred_procedure.entity != nullptr) {
		e->Procedure.deferred_procedure = ac.deferred_procedure;
		mpmc_enqueue(&ctx->checker->procs_with_deferred_to_check, e);
	}

	if (is_foreign) {
		String name = e->token.string;
		if (e->Procedure.link_name.len > 0) {
			name = e->Procedure.link_name;
		}
		Entity *foreign_library = init_entity_foreign_library(ctx, e);
		
		if (is_arch_wasm() && foreign_library != nullptr) {
			String module_name = str_lit("env");
			GB_ASSERT (foreign_library->kind == Entity_LibraryName);
			if (foreign_library->LibraryName.paths.count != 1) {
				error(foreign_library->token, "'foreign import' for '%.*s' architecture may only have one path, got %td",
				      LIT(target_arch_names[build_context.metrics.arch]), foreign_library->LibraryName.paths.count);
			}

			if (foreign_library->LibraryName.paths.count >= 1) {
				module_name = foreign_library->LibraryName.paths[0];
			}
			name = concatenate3_strings(permanent_allocator(), module_name, WASM_MODULE_NAME_SEPARATOR, name);
		}
		
		e->Procedure.is_foreign = true;
		e->Procedure.link_name = name;

		mutex_lock(&ctx->info->foreign_mutex);

		auto *fp = &ctx->info->foreigns;
		StringHashKey key = string_hash_string(name);
		Entity **found = string_map_get(fp, key);
		if (found) {
			Entity *f = *found;
			TokenPos pos = f->token.pos;
			Type *this_type = base_type(e->type);
			Type *other_type = base_type(f->type);
			if (is_type_proc(this_type) && is_type_proc(other_type)) {
				if (!are_signatures_similar_enough(this_type, other_type)) {
					error(d->proc_lit,
					      "Redeclaration of foreign procedure '%.*s' with different type signatures\n"
					      "\tat %s",
					      LIT(name), token_pos_to_string(pos));
				}
			} else if (!are_types_identical(this_type, other_type)) {
				error(d->proc_lit,
				      "Foreign entity '%.*s' previously declared elsewhere with a different type\n"
				      "\tat %s",
				      LIT(name), token_pos_to_string(pos));
			}
		} else if (name == "main") {
			error(d->proc_lit, "The link name 'main' is reserved for internal use");
		} else {
			string_map_set(fp, key, e);
		}

		mutex_unlock(&ctx->info->foreign_mutex);
	} else {
		String name = e->token.string;
		if (e->Procedure.link_name.len > 0) {
			name = e->Procedure.link_name;
		}
		if (e->Procedure.link_name.len > 0 || is_export) {
			mutex_lock(&ctx->info->foreign_mutex);

			auto *fp = &ctx->info->foreigns;
			StringHashKey key = string_hash_string(name);
			Entity **found = string_map_get(fp, key);
			if (found) {
				Entity *f = *found;
				TokenPos pos = f->token.pos;
				// TODO(bill): Better error message?
				error(d->proc_lit,
				      "Non unique linking name for procedure '%.*s'\n"
				      "\tother at %s",
				      LIT(name), token_pos_to_string(pos));
			} else if (name == "main") {
				if (d->entity->pkg->kind != Package_Runtime) {
					error(d->proc_lit, "The link name 'main' is reserved for internal use");
				}
			} else {
				string_map_set(fp, key, e);
			}

			mutex_unlock(&ctx->info->foreign_mutex);
		}
	}
	
	if (e->Procedure.link_name.len > 0 ) {
		e->flags |= EntityFlag_CustomLinkName;
	}
}

void check_global_variable_decl(CheckerContext *ctx, Entity *&e, Ast *type_expr, Ast *init_expr) {
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

	if (ac.require_declaration) {
		e->flags |= EntityFlag_Require;
		mpmc_enqueue(&ctx->info->required_global_variable_queue, e);
	}


	e->Variable.thread_local_model = ac.thread_local_model;
	e->Variable.is_export = ac.is_export;
	e->flags &= ~EntityFlag_Static;
	if (ac.is_static) {
		error(e->token, "@(static) is not supported for global variables, nor required");
	}
	ac.link_name = handle_link_name(ctx, e->token, ac.link_name, ac.link_prefix);

	if (is_arch_wasm() && e->Variable.thread_local_model.len != 0) {
		e->Variable.thread_local_model.len = 0;
		// NOTE(bill): ignore this message for the time begin
		// error(e->token, "@(thread_local) is not supported for this target platform");
	}

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
		if (is_arch_wasm()) {
			error(e->token, "A foreign variable declaration are not allowed for the '%.*s' architecture", LIT(target_arch_names[build_context.metrics.arch]));
		}
	}
	if (ac.link_name.len > 0) {
		e->Variable.link_name = ac.link_name;
	}
	if (ac.link_section.len > 0) {
		e->Variable.link_section = ac.link_section;
	}

	if (e->Variable.is_foreign || e->Variable.is_export) {
		String name = e->token.string;
		if (e->Variable.link_name.len > 0) {
			name = e->Variable.link_name;
		}

		auto *fp = &ctx->info->foreigns;
		StringHashKey key = string_hash_string(name);
		Entity **found = string_map_get(fp, key);
		if (found) {
			Entity *f = *found;
			TokenPos pos = f->token.pos;
			Type *this_type = base_type(e->type);
			Type *other_type = base_type(f->type);
			if (!are_types_identical(this_type, other_type)) {
				error(e->token,
				      "Foreign entity '%.*s' previously declared elsewhere with a different type\n"
				      "\tat %s",
				      LIT(name), token_pos_to_string(pos));
			}
		} else {
			string_map_set(fp, key, e);
		}
	}
	
	if (e->Variable.link_name.len > 0) {
		e->flags |= EntityFlag_CustomLinkName;
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

	check_rtti_type_disallowed(e->token, e->type, "A variable declaration is using a type, %s, which has been disallowed");
}

void check_proc_group_decl(CheckerContext *ctx, Entity *&pg_entity, DeclInfo *d) {
	GB_ASSERT(pg_entity->kind == Entity_ProcGroup);
	auto *pge = &pg_entity->ProcGroup;
	String proc_group_name = pg_entity->token.string;

	ast_node(pg, ProcGroup, d->init_expr);

	pge->entities = array_make<Entity*>(permanent_allocator(), 0, pg->args.count);

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

		if (ptr_set_update(&entity_set, e)) {
			error(arg, "Previous use of `%.*s` in procedure group", LIT(e->token.string));
			continue;
		}
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
				error(p->token, "Overloaded procedure '%.*s' has the same type as another procedure in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				is_invalid = true;
				break;
			// case ProcOverload_CallingConvention:
				// error(p->token, "Overloaded procedure '%.*s' has the same type as another procedure in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				// is_invalid = true;
				// break;
			case ProcOverload_ParamVariadic:
				error(p->token, "Overloaded procedure '%.*s' has the same type as another procedure in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
				is_invalid = true;
				break;
			case ProcOverload_ResultCount:
			case ProcOverload_ResultTypes:
				error(p->token, "Overloaded procedure '%.*s' has the same parameters but different results in the procedure group '%.*s'", LIT(name), LIT(proc_group_name));
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
				error_line("\tprevious procedure at %s\n", token_pos_to_string(pos));
				q->type = t_invalid;
			}
		}
	}

}

void check_entity_decl(CheckerContext *ctx, Entity *e, DeclInfo *d, Type *named_type) {
	if (e->state == EntityState_Resolved)  {
		return;
	}
	if (e->flags & EntityFlag_Lazy) {
		mutex_lock(&ctx->info->lazy_mutex);
	}

	String name = e->token.string;

	if (e->type != nullptr || e->state != EntityState_Unresolved) {
		error(e->token, "Illegal declaration cycle of `%.*s`", LIT(name));
	} else {
		GB_ASSERT(e->state == EntityState_Unresolved);
		if (d == nullptr) {
			d = decl_info_of_entity(e);
			if (d == nullptr) {
				// TODO(bill): Err here?
				e->type = t_invalid;
				e->state = EntityState_Resolved;
				set_base_type(named_type, t_invalid);
				goto end;
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

	}
end:;
	// NOTE(bill): Add it to the list of checked entities
	if (e->flags & EntityFlag_Lazy) {
		array_add(&ctx->info->entities, e);
		mutex_unlock(&ctx->info->lazy_mutex);
	}
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

	GB_ASSERT(type->kind == Type_Proc);

	ctx->scope = decl->scope;
	ctx->decl = decl;
	ctx->proc_name = proc_name;
	ctx->curr_proc_decl = decl;
	ctx->curr_proc_sig  = type;
	ctx->curr_proc_calling_convention = type->Proc.calling_convention;

	if (ctx->pkg->name != "runtime") {
		switch (type->Proc.calling_convention) {
		case ProcCC_None:
			error(body, "Procedures with the calling convention \"none\" are not allowed a body");
			break;
		}
	}

	ast_node(bs, BlockStmt, body);

	Array<ProcUsingVar> using_entities = {};
	using_entities.allocator = heap_allocator();
	defer (array_free(&using_entities));

	{
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
				if (is_blank_ident(e->token)) {
                    error(e->token, "'using' a procedure parameter requires a non blank identifier");
					break;
				}

				bool is_value = (e->flags & EntityFlag_Value) != 0 && !is_type_pointer(e->type);
				String name = e->token.string;
				Type *t = base_type(type_deref(e->type));
				if (t->kind == Type_Struct) {
					Scope *scope = t->Struct.scope;
					GB_ASSERT(scope != nullptr);
					MUTEX_GUARD_BLOCK(scope->mutex) for_array(i, scope->elements.entries) {
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

	MUTEX_GUARD_BLOCK(ctx->scope->mutex) for_array(i, using_entities) {
		Entity *e = using_entities[i].e;
		Entity *uvar = using_entities[i].uvar;
		Entity *prev = scope_insert(ctx->scope, uvar, false);
		if (prev != nullptr) {
			error(e->token, "Namespace collision while 'using' procedure argument '%.*s' of: %.*s", LIT(e->token.string), LIT(prev->token.string));
			error_line("%.*s != %.*s\n", LIT(uvar->token.string), LIT(prev->token.string));
			break;
		}
	}


	bool where_clause_ok = evaluate_where_clauses(ctx, nullptr, decl->scope, &decl->proc_lit->ProcLit.where_clauses, !decl->where_clauses_evaluated);
	if (!where_clause_ok) {
		// NOTE(bill, 2019-08-31): Don't check the body as the where clauses failed
		return;
	}

	check_open_scope(ctx, body);
	{
		for_array(i, using_entities) {
			Entity *uvar = using_entities[i].uvar;
			Entity *prev = scope_insert(ctx->scope, uvar);
			gb_unused(prev);
			// NOTE(bill): Don't err here
		}

		check_stmt_list(ctx, bs->stmts, Stmt_CheckScopeDecls);

		for_array(i, bs->stmts) {
			Ast *stmt = bs->stmts[i];
			if (stmt->kind == Ast_ValueDecl) {
				ast_node(vd, ValueDecl, stmt);
				for_array(j, vd->names) {
					Ast *name = vd->names[j];
					if (!is_blank_ident(name)) {
						if (name->kind == Ast_Ident) {
							GB_ASSERT(name->Ident.entity != nullptr);
						}
					}
				}
			}
		}

		if (type->Proc.result_count > 0) {
			if (!check_is_terminating(body, str_lit(""))) {
				if (token.kind == Token_Ident) {
					error(bs->close, "Missing return statement at the end of the procedure '%.*s'", LIT(token.string));
				} else {
					// NOTE(bill): Anonymous procedure (lambda)
					error(bs->close, "Missing return statement at the end of the procedure");
				}
			}
		} else if (type->Proc.diverging) {
			if (!check_is_terminating(body, str_lit(""))) {
				if (token.kind == Token_Ident) {
					error(bs->close, "Missing diverging call at the end of the procedure '%.*s'", LIT(token.string));
				} else {
					// NOTE(bill): Anonymous procedure (lambda)
					error(bs->close, "Missing diverging call at the end of the procedure");
				}
			}
		}
	}
	check_close_scope(ctx);

	check_scope_usage(ctx->checker, ctx->scope);

	if (decl->parent != nullptr) {
		Scope *ps = decl->parent->scope;
		if (ps->flags & (ScopeFlag_File & ScopeFlag_Pkg & ScopeFlag_Global)) {
			return;
		} else {
			mutex_lock(&ctx->info->deps_mutex);

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

			mutex_unlock(&ctx->info->deps_mutex);
		}
	}
}
