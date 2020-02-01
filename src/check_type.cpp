
void populate_using_array_index(CheckerContext *ctx, Ast *node, AstField *field, Type *t, String name, i32 idx) {
	t = base_type(t);
	GB_ASSERT(t->kind == Type_Array);
	Entity *e = scope_lookup_current(ctx->scope, name);
	if (e != nullptr) {
		gbString str = nullptr;
		defer (gb_string_free(str));
		if (node != nullptr) {
			str = expr_to_string(node);
		}
		if (str != nullptr) {
			error(e->token, "'%.*s' is already declared in '%s'", LIT(name), str);
		} else {
			error(e->token, "'%.*s' is already declared", LIT(name));
		}
	} else {
		Token tok = make_token_ident(name);
		if (field->names.count > 0) {
			tok.pos = ast_token(field->names[0]).pos;
		} else {
			tok.pos = ast_token(field->type).pos;
		}
		Entity *f = alloc_entity_array_elem(nullptr, tok, t->Array.elem, idx);
		add_entity(ctx->checker, ctx->scope, nullptr, f);
	}
}

void populate_using_entity_scope(CheckerContext *ctx, Ast *node, AstField *field, Type *t) {
	if (t == nullptr) {
		return;
	}
	t = base_type(type_deref(t));
	gbString str = nullptr;
	defer (gb_string_free(str));
	if (node != nullptr) {
		str = expr_to_string(node);
	}

	if (t->kind == Type_Struct) {
		for_array(i, t->Struct.fields) {
			Entity *f = t->Struct.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			String name = f->token.string;
			Entity *e = scope_lookup_current(ctx->scope, name);
			if (e != nullptr && name != "_") {
				// TODO(bill): Better type error
				if (str != nullptr) {
					error(e->token, "'%.*s' is already declared in '%s'", LIT(name), str);
				} else {
					error(e->token, "'%.*s' is already declared", LIT(name));
				}
			} else {
				add_entity(ctx->checker, ctx->scope, nullptr, f);
				if (f->flags & EntityFlag_Using) {
					populate_using_entity_scope(ctx, node, field, f->type);
				}
			}
		}
	} else if (t->kind == Type_BitField) {
		for_array(i, t->BitField.fields) {
			Entity *f = t->BitField.fields[i];
			String name = f->token.string;
			Entity *e = scope_lookup_current(ctx->scope, name);
			if ((e != nullptr && name != "_") && (e != f)) {
				// TODO(bill): Better type error
				if (str != nullptr) {
					error(e->token, "'%.*s' is already declared in '%s'", LIT(name), str);
				} else {
					error(e->token, "'%.*s' is already declared", LIT(name));
				}
			} else {
				add_entity(ctx->checker, ctx->scope, nullptr, f);
			}
		}
	} else if (t->kind == Type_Array && t->Array.count <= 4) {
		Entity *e = nullptr;
		String name = {};
		i32 idx = 0;
		switch (t->Array.count) {
		case 4:
			populate_using_array_index(ctx, node, field, t, str_lit("w"), 3);
			populate_using_array_index(ctx, node, field, t, str_lit("a"), 3);
			/*fallthrough*/
		case 3:
			populate_using_array_index(ctx, node, field, t, str_lit("z"), 2);
			populate_using_array_index(ctx, node, field, t, str_lit("b"), 2);
			/*fallthrough*/
		case 2:
			populate_using_array_index(ctx, node, field, t, str_lit("y"), 1);
			populate_using_array_index(ctx, node, field, t, str_lit("g"), 1);
			/*fallthrough*/
		case 1:
			populate_using_array_index(ctx, node, field, t, str_lit("x"), 0);
			populate_using_array_index(ctx, node, field, t, str_lit("r"), 0);
			/*fallthrough*/
		default:
			break;
		}
	}
}

bool does_field_type_allow_using(Type *t) {
	t = base_type(t);
	if (is_type_struct(t)) {
		return true;
	} else if (is_type_raw_union(t)) {
		return true;
	} else if (is_type_bit_field(t)) {
		return true;
	} else if (is_type_array(t)) {
		return t->Array.count <= 4;
	}
	return false;
}

void check_struct_fields(CheckerContext *ctx, Ast *node, Array<Entity *> *fields, Array<String> *tags, Array<Ast *> const &params,
                         isize init_field_capacity, Type *struct_type, String context) {
	*fields = array_make<Entity *>(heap_allocator(), 0, init_field_capacity);
	*tags   = array_make<String>(heap_allocator(), 0, init_field_capacity);

	GB_ASSERT(node->kind == Ast_StructType);
	GB_ASSERT(struct_type->kind == Type_Struct);

	isize variable_count = 0;
	for_array(i, params) {
		Ast *field = params[i];
		if (ast_node_expect(field, Ast_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}

	i32 field_src_index = 0;
	for_array(i, params) {
		Ast *param = params[i];
		if (param->kind != Ast_Field) {
			continue;
		}
		ast_node(p, Field, param);
		Ast *type_expr = p->type;
		Type *type = nullptr;
		bool detemine_type_from_operand = false;


		if (type_expr != nullptr) {
			type = check_type_expr(ctx, type_expr, nullptr);
			if (is_type_polymorphic(type)) {
				struct_type->Struct.is_polymorphic = true;
				type = nullptr;
			}
		}
		if (type == nullptr) {
			error(params[i], "Invalid parameter type");
			type = t_invalid;
		}
		if (is_type_untyped(type)) {
			if (is_type_untyped_undef(type)) {
				error(params[i], "Cannot determine parameter type from ---");
			} else {
				error(params[i], "Cannot determine parameter type from a nil");
			}
			type = t_invalid;
		}

		bool is_using = (p->flags&FieldFlag_using) != 0;

		for_array(j, p->names) {
			Ast *name = p->names[j];
			if (!ast_node_expect(name, Ast_Ident)) {
				continue;
			}

			Token name_token = name->Ident.token;

			Entity *field = alloc_entity_field(ctx->scope, name_token, type, is_using, field_src_index);
			add_entity(ctx->checker, ctx->scope, name, field);
			array_add(fields, field);
			array_add(tags, p->tag.string);

			field_src_index += 1;
		}


		if (is_using && p->names.count > 0) {
			Type *first_type = (*fields)[fields->count-1]->type;
			Type *t = base_type(type_deref(first_type));

			if (!does_field_type_allow_using(t) &&
			    p->names.count >= 1 &&
			    p->names[0]->kind == Ast_Ident) {
				Token name_token = p->names[0]->Ident.token;
				gbString type_str = type_to_string(first_type);
				error(name_token, "'using' cannot be applied to the field '%.*s' of type '%s'", LIT(name_token.string), type_str);
				gb_string_free(type_str);
				continue;
			}

			populate_using_entity_scope(ctx, node, p, type);
		}
	}
}


Entity *make_names_field_for_struct(CheckerContext *ctx, Scope *scope) {
	Entity *e = alloc_entity_field(scope, make_token_ident(str_lit("names")), t_string_slice, false, 0);
	e->flags |= EntityFlag_TypeField;
	e->flags |= EntityFlag_Value;
	return e;
}

bool check_custom_align(CheckerContext *ctx, Ast *node, i64 *align_) {
	GB_ASSERT(align_ != nullptr);
	Operand o = {};
	check_expr(ctx, &o, node);
	if (o.mode != Addressing_Constant) {
		if (o.mode != Addressing_Invalid) {
			error(node, "#align must be a constant");
		}
		return false;
	}

	Type *type = base_type(o.type);
	if (is_type_untyped(type) || is_type_integer(type)) {
		if (o.value.kind == ExactValue_Integer) {
			BigInt v = o.value.value_integer;
			if (v.len > 1) {
				gbAllocator a = heap_allocator();
				String str = big_int_to_string(a, &v);
				error(node, "#align too large, %.*s", LIT(str));
				gb_free(a, str.text);
				return false;
			}
			i64 align = big_int_to_i64(&v);
			if (align < 1 || !gb_is_power_of_two(cast(isize)align)) {
				error(node, "#align must be a power of 2, got %lld", align);
				return false;
			}

			// NOTE(bill): Success!!!
			i64 custom_align = gb_clamp(align, 1, build_context.max_align);
			if (custom_align < align) {
				warning(node, "Custom alignment has been clamped to %lld from %lld", align, custom_align);
			}
			*align_ = custom_align;
			return true;
		}
	}

	error(node, "#align must be an integer");
	return false;
}


Entity *find_polymorphic_record_entity(CheckerContext *ctx, Type *original_type, isize param_count, Array<Operand> const &ordered_operands, bool *failure) {
	auto *found_gen_types = map_get(&ctx->checker->info.gen_types, hash_pointer(original_type));
	if (found_gen_types != nullptr) {
		for_array(i, *found_gen_types) {
			Entity *e = (*found_gen_types)[i];
			Type *t = base_type(e->type);
			TypeTuple *tuple = get_record_polymorphic_params(t);
			GB_ASSERT(param_count == tuple->variables.count);

			bool skip = false;

			for (isize j = 0; j < param_count; j++) {
				Entity *p = tuple->variables[j];
				Operand o = ordered_operands[j];
				Entity *oe = entity_of_node(o.expr);
				if (p == oe) {
					// NOTE(bill): This is the same type, make sure that it will be be same thing and use that
					// Saves on a lot of checking too below
					continue;
				}

				if (p->kind == Entity_TypeName) {
					if (is_type_polymorphic(o.type)) {
						// NOTE(bill): Do not add polymorphic version to the gen_types
						skip = true;
						break;
					}
					if (!are_types_identical(o.type, p->type)) {
						skip = true;
						break;
					}
				} else if (p->kind == Entity_Constant) {
					if (!compare_exact_values(Token_CmpEq, o.value, p->Constant.value)) {
						skip = true;
						break;
					}
					if (!are_types_identical(o.type, p->type)) {
						skip = true;
						break;
					}
				} else {
					GB_PANIC("Unknown entity kind");
				}
			}
			if (!skip) {
				return e;
			}
		}
	}
	return nullptr;
}


void add_polymorphic_record_entity(CheckerContext *ctx, Ast *node, Type *named_type, Type *original_type) {
	GB_ASSERT(is_type_named(named_type));
	gbAllocator a = heap_allocator();
	Scope *s = ctx->scope->parent;

	Entity *e = nullptr;
	{
		Token token = ast_token(node);
		token.kind = Token_String;
		token.string = named_type->Named.name;

		Ast *node = ast_ident(nullptr, token);

		e = alloc_entity_type_name(s, token, named_type);
		e->state = EntityState_Resolved;
		e->file = ctx->file;
		e->pkg = ctx->pkg;
		add_entity_use(ctx, node, e);
	}

	named_type->Named.type_name = e;

	auto *found_gen_types = map_get(&ctx->checker->info.gen_types, hash_pointer(original_type));
	if (found_gen_types) {
		array_add(found_gen_types, e);
	} else {
		auto array = array_make<Entity *>(heap_allocator());
		array_add(&array, e);
		map_set(&ctx->checker->info.gen_types, hash_pointer(original_type), array);
	}
}

void check_struct_type(CheckerContext *ctx, Type *struct_type, Ast *node, Array<Operand> *poly_operands, Type *named_type, Type *original_type_for_poly) {
	GB_ASSERT(is_type_struct(struct_type));
	ast_node(st, StructType, node);

	String context = str_lit("struct");

	isize min_field_count = 0;
	for_array(field_index, st->fields) {
	Ast *field = st->fields[field_index];
		switch (field->kind) {
		case_ast_node(f, ValueDecl, field);
			min_field_count += f->names.count;
		case_end;
		case_ast_node(f, Field, field);
			min_field_count += f->names.count;
		case_end;
		}
	}
	struct_type->Struct.names = make_names_field_for_struct(ctx, ctx->scope);

	scope_reserve(ctx->scope, min_field_count);

	if (st->is_raw_union && min_field_count > 1) {
		struct_type->Struct.is_raw_union = true;
		context = str_lit("struct #raw_union");
	}

	// NOTE(bill): Yes I know it's a non-const reference, what you gonna do?
	bool &is_polymorphic = struct_type->Struct.is_polymorphic;

	Type *polymorphic_params = nullptr;
	bool can_check_fields    = true;
	bool is_poly_specialized = false;

	if (st->polymorphic_params != nullptr) {
		ast_node(field_list, FieldList, st->polymorphic_params);
		Array<Ast *> params = field_list->list;
		if (params.count != 0) {
			isize variable_count = 0;
			for_array(i, params) {
				Ast *field = params[i];
				if (ast_node_expect(field, Ast_Field)) {
					ast_node(f, Field, field);
					variable_count += gb_max(f->names.count, 1);
				}
			}

			auto entities = array_make<Entity *>(ctx->allocator, 0, variable_count);

			for_array(i, params) {
				Ast *param = params[i];
				if (param->kind != Ast_Field) {
					continue;
				}
				ast_node(p, Field, param);
				Ast *type_expr = p->type;
				Type *type = nullptr;
				bool is_type_param = false;
				bool is_type_polymorphic_type = false;
				if (type_expr == nullptr) {
					error(param, "Expected a type for this parameter");
					continue;
				}
				if (type_expr->kind == Ast_Ellipsis) {
					type_expr = type_expr->Ellipsis.expr;
					error(param, "A polymorphic parameter cannot be variadic");
				}
				if (type_expr->kind == Ast_TypeidType) {
					is_type_param = true;
					Type *specialization = nullptr;
					if (type_expr->TypeidType.specialization != nullptr) {
						Ast *s = type_expr->TypeidType.specialization;
						specialization = check_type(ctx, s);
					}
					type = alloc_type_generic(ctx->scope, 0, str_lit(""), specialization);
				} else {
					type = check_type(ctx, type_expr);
					if (is_type_polymorphic(type)) {
						is_type_polymorphic_type = true;
					}
				}

				if (type == nullptr) {
					error(params[i], "Invalid parameter type");
					type = t_invalid;
				}
				if (is_type_untyped(type)) {
					if (is_type_untyped_undef(type)) {
						error(params[i], "Cannot determine parameter type from ---");
					} else {
						error(params[i], "Cannot determine parameter type from a nil");
					}
					type = t_invalid;
				}

				if (is_type_polymorphic_type) {
					gbString str = type_to_string(type);
					error(params[i], "Parameter types cannot be polymorphic, got %s", str);
					gb_string_free(str);
					type = t_invalid;
				}

				if (!is_type_param && !is_type_constant_type(type)) {
					gbString str = type_to_string(type);
					error(params[i], "A parameter must be a valid constant type, got %s", str);
					gb_string_free(str);
				}

				Scope *scope = ctx->scope;
				for_array(j, p->names) {
					Ast *name = p->names[j];
					if (!ast_node_expect(name, Ast_Ident)) {
						continue;
					}
					Entity *e = nullptr;

					Token token = name->Ident.token;

					if (poly_operands != nullptr) {
						Operand operand = (*poly_operands)[entities.count];
						if (is_type_param) {
							if (is_type_polymorphic(base_type(operand.type))) {
								is_polymorphic = true;
								can_check_fields = false;
							}
							e = alloc_entity_type_name(scope, token, operand.type);
							e->TypeName.is_type_alias = true;
						} else {
							if (is_type_polymorphic(base_type(operand.type))) {
								is_polymorphic = true;
								can_check_fields = false;
							}
							e = alloc_entity_constant(scope, token, operand.type, operand.value);
						}
					} else {
						if (is_type_param) {
							e = alloc_entity_type_name(scope, token, type);
							e->TypeName.is_type_alias = true;
						} else {
							e = alloc_entity_constant(scope, token, type, empty_exact_value);
						}
					}

					e->state = EntityState_Resolved;
					add_entity(ctx->checker, scope, name, e);
					array_add(&entities, e);
				}
			}

			if (entities.count > 0) {
				Type *tuple = alloc_type_tuple();
				tuple->Tuple.variables = entities;
				polymorphic_params = tuple;
			}
		}

		if (original_type_for_poly != nullptr) {
			GB_ASSERT(named_type != nullptr);
			add_polymorphic_record_entity(ctx, node, named_type, original_type_for_poly);
		}
	}

	if (!is_polymorphic) {
		is_polymorphic = polymorphic_params != nullptr && poly_operands == nullptr;
	}
	if (poly_operands != nullptr) {
		is_poly_specialized = true;
		for (isize i = 0; i < poly_operands->count; i++) {
			Operand o = (*poly_operands)[i];
			if (is_type_polymorphic(o.type)) {
				is_poly_specialized = false;
				break;
			}
			if (struct_type == o.type) {
				// NOTE(bill): Cycle
				is_poly_specialized = false;
				break;
			}
		}
	}

	struct_type->Struct.scope                   = ctx->scope;
	struct_type->Struct.is_packed               = st->is_packed;
	struct_type->Struct.polymorphic_params      = polymorphic_params;
	struct_type->Struct.is_poly_specialized     = is_poly_specialized;

	if (!is_polymorphic) {
		if (st->where_clauses.count > 0 && st->polymorphic_params == nullptr) {
			error(st->where_clauses[0], "'where' clauses can only be used on structures with polymorphic parameters");
		} else {
			bool where_clause_ok = evaluate_where_clauses(ctx, ctx->scope, &st->where_clauses, true);
		}
		check_struct_fields(ctx, node, &struct_type->Struct.fields, &struct_type->Struct.tags, st->fields, min_field_count, struct_type, context);
	}

	if (st->align != nullptr) {
		if (st->is_packed) {
			syntax_error(st->align, "'#align' cannot be applied with '#packed'");
			return;
		}
		i64 custom_align = 1;
		if (check_custom_align(ctx, st->align, &custom_align)) {
			struct_type->Struct.custom_align = custom_align;
		}
	}
}
void check_union_type(CheckerContext *ctx, Type *union_type, Ast *node, Array<Operand> *poly_operands, Type *named_type, Type *original_type_for_poly) {
	GB_ASSERT(is_type_union(union_type));
	ast_node(ut, UnionType, node);

	isize variant_count = ut->variants.count;

	Entity *using_index_expr = nullptr;

	auto variants = array_make<Type *>(ctx->allocator, 0, variant_count);

	union_type->Union.scope = ctx->scope;

	Type *polymorphic_params     = nullptr;
	bool is_polymorphic          = false;
	bool can_check_fields        = true;
	bool is_poly_specialized     = false;

	if (ut->polymorphic_params != nullptr) {
		ast_node(field_list, FieldList, ut->polymorphic_params);
		Array<Ast *> params = field_list->list;
		if (params.count != 0) {
			isize variable_count = 0;
			for_array(i, params) {
				Ast *field = params[i];
				if (ast_node_expect(field, Ast_Field)) {
					ast_node(f, Field, field);
					variable_count += gb_max(f->names.count, 1);
				}
			}

			auto entities = array_make<Entity *>(ctx->allocator, 0, variable_count);

			for_array(i, params) {
				Ast *param = params[i];
				if (param->kind != Ast_Field) {
					continue;
				}
				ast_node(p, Field, param);
				Ast *type_expr = p->type;
				Type *type = nullptr;
				bool is_type_param = false;
				bool is_type_polymorphic_type = false;
				if (type_expr == nullptr) {
					error(param, "Expected a type for this parameter");
					continue;
				}
				if (type_expr->kind == Ast_Ellipsis) {
					type_expr = type_expr->Ellipsis.expr;
					error(param, "A polymorphic parameter cannot be variadic");
				}
				if (type_expr->kind == Ast_TypeidType) {
					is_type_param = true;
					Type *specialization = nullptr;
					if (type_expr->TypeidType.specialization != nullptr) {
						Ast *s = type_expr->TypeidType.specialization;
						specialization = check_type(ctx, s);
					}
					type = alloc_type_generic(ctx->scope, 0, str_lit(""), specialization);
				} else {
					type = check_type(ctx, type_expr);
					if (is_type_polymorphic(type)) {
						is_type_polymorphic_type = true;
					}
				}

				if (type == nullptr) {
					error(params[i], "Invalid parameter type");
					type = t_invalid;
				}
				if (is_type_untyped(type)) {
					if (is_type_untyped_undef(type)) {
						error(params[i], "Cannot determine parameter type from ---");
					} else {
						error(params[i], "Cannot determine parameter type from a nil");
					}
					type = t_invalid;
				}

				if (is_type_polymorphic_type) {
					gbString str = type_to_string(type);
					error(params[i], "Parameter types cannot be polymorphic, got %s", str);
					gb_string_free(str);
					type = t_invalid;
				}

				if (!is_type_param && !is_type_constant_type(type)) {
					gbString str = type_to_string(type);
					error(params[i], "A parameter must be a valid constant type, got %s", str);
					gb_string_free(str);
				}

				Scope *scope = ctx->scope;
				for_array(j, p->names) {
					Ast *name = p->names[j];
					if (!ast_node_expect(name, Ast_Ident)) {
						continue;
					}
					Entity *e = nullptr;

					Token token = name->Ident.token;

					if (poly_operands != nullptr) {
						Operand operand = (*poly_operands)[entities.count];
						if (is_type_param) {
							GB_ASSERT(operand.mode == Addressing_Type ||
							          operand.mode == Addressing_Invalid);
							if (is_type_polymorphic(base_type(operand.type))) {
								is_polymorphic = true;
								can_check_fields = false;
							}
							e = alloc_entity_type_name(scope, token, operand.type);
							e->TypeName.is_type_alias = true;
						} else {
							// GB_ASSERT(operand.mode == Addressing_Constant);
							e = alloc_entity_constant(scope, token, operand.type, operand.value);
						}
					} else {
						if (is_type_param) {
							e = alloc_entity_type_name(scope, token, type);
							e->TypeName.is_type_alias = true;
						} else {
							e = alloc_entity_constant(scope, token, type, empty_exact_value);
						}
					}

					e->state = EntityState_Resolved;
					add_entity(ctx->checker, scope, name, e);
					array_add(&entities, e);
				}
			}

			if (entities.count > 0) {
				Type *tuple = alloc_type_tuple();
				tuple->Tuple.variables = entities;
				polymorphic_params = tuple;
			}
		}

		if (original_type_for_poly != nullptr) {
			GB_ASSERT(named_type != nullptr);
			add_polymorphic_record_entity(ctx, node, named_type, original_type_for_poly);
		}
	}

	if (!is_polymorphic) {
		is_polymorphic = polymorphic_params != nullptr && poly_operands == nullptr;
	}
	if (poly_operands != nullptr) {
		is_poly_specialized = true;
		for (isize i = 0; i < poly_operands->count; i++) {
			Operand o = (*poly_operands)[i];
			if (is_type_polymorphic(o.type)) {
				is_poly_specialized = false;
				break;
			}
			if (union_type == o.type) {
				// NOTE(bill): Cycle
				is_poly_specialized = false;
				break;
			}
		}
	}

	union_type->Union.scope                   = ctx->scope;
	union_type->Union.polymorphic_params      = polymorphic_params;
	union_type->Union.is_polymorphic          = is_polymorphic;
	union_type->Union.is_poly_specialized     = is_poly_specialized;

	if (ut->where_clauses.count > 0 && ut->polymorphic_params == nullptr) {
		error(ut->where_clauses[0], "'where' clauses can only be used on unions with polymorphic parameters");
	} else {
		bool where_clause_ok = evaluate_where_clauses(ctx, ctx->scope, &ut->where_clauses, true);
	}


	for_array(i, ut->variants) {
		Ast *node = ut->variants[i];
		Type *t = check_type_expr(ctx, node, nullptr);
		if (t != nullptr && t != t_invalid) {
			bool ok = true;
			t = default_type(t);
			if (is_type_untyped(t) || is_type_empty_union(t)) {
				ok = false;
				gbString str = type_to_string(t);
				error(node, "Invalid variant type in union '%s'", str);
				gb_string_free(str);
			} else {
				for_array(j, variants) {
					if (are_types_identical(t, variants[j])) {
						ok = false;
						gbString str = type_to_string(t);
						error(node, "Duplicate variant type '%s'", str);
						gb_string_free(str);
						break;
					}
				}
			}
			if (ok) {
				array_add(&variants, t);
			}
		}
	}

	union_type->Union.variants = variants;
	union_type->Union.no_nil = ut->no_nil;
	union_type->Union.maybe = ut->maybe;
	if (union_type->Union.no_nil) {
		if (variants.count < 2) {
			error(ut->align, "A union with #no_nil must have at least 2 variants");
		}
	}
	if (union_type->Union.maybe) {
		if (variants.count != 1) {
			error(ut->align, "A union with #maybe must have at 1 variant, got %lld", cast(long long)variants.count);
		}
	}

	if (ut->align != nullptr) {
		i64 custom_align = 1;
		if (check_custom_align(ctx, ut->align, &custom_align)) {
			if (variants.count == 0) {
				error(ut->align, "An empty union cannot have a custom alignment");
			} else {
				union_type->Union.custom_align = custom_align;
			}
		}
	}
}

void check_enum_type(CheckerContext *ctx, Type *enum_type, Type *named_type, Ast *node) {
	ast_node(et, EnumType, node);
	GB_ASSERT(is_type_enum(enum_type));

	Type *base_type = t_int;
	if (et->base_type != nullptr) {
		base_type = check_type(ctx, et->base_type);
	}

	if (base_type == nullptr || !is_type_integer(base_type)) {
		error(node, "Base type for enumeration must be an integer");
		return;
	}
	if (is_type_enum(base_type)) {
		error(node, "Base type for enumeration cannot be another enumeration");
		return;
	}

	if (is_type_integer_128bit(base_type)) {
		error(node, "Base type for enumeration cannot be a 128-bit integer");
		return;
	}

	// NOTE(bill): Must be up here for the 'check_init_constant' system
	enum_type->Enum.base_type = base_type;
	enum_type->Enum.scope = ctx->scope;

	auto fields = array_make<Entity *>(ctx->allocator, 0, et->fields.count);

	Type *constant_type = enum_type;
	if (named_type != nullptr) {
		constant_type = named_type;
	}

	ExactValue iota = exact_value_i64(-1);
	ExactValue min_value = exact_value_i64(0);
	ExactValue max_value = exact_value_i64(0);
	isize min_value_index = 0;
	isize max_value_index = 0;
	bool min_value_set = false;
	bool max_value_set = false;

	scope_reserve(ctx->scope, et->fields.count);

	for_array(i, et->fields) {
		Ast *field = et->fields[i];
		Ast *ident = nullptr;
		Ast *init = nullptr;
		if (field->kind == Ast_FieldValue) {
			ast_node(fv, FieldValue, field);
			if (fv->field == nullptr || fv->field->kind != Ast_Ident) {
				error(field, "An enum field's name must be an identifier");
				continue;
			}
			ident = fv->field;
			init = fv->value;
		} else if (field->kind == Ast_Ident) {
			ident = field;
		} else {
			error(field, "An enum field's name must be an identifier");
			continue;
		}
		String name = ident->Ident.token.string;

		if (init != nullptr) {
			Operand o = {};
			check_expr(ctx, &o, init);
			if (o.mode != Addressing_Constant) {
				error(init, "Enumeration value must be a constant");
				o.mode = Addressing_Invalid;
			}
			if (o.mode != Addressing_Invalid) {
				check_assignment(ctx, &o, constant_type, str_lit("enumeration"));
			}
			if (o.mode != Addressing_Invalid) {
				iota = o.value;
			} else {
				iota = exact_binary_operator_value(Token_Add, iota, exact_value_i64(1));
			}
		} else {
			iota = exact_binary_operator_value(Token_Add, iota, exact_value_i64(1));
		}


		// NOTE(bill): Skip blank identifiers
		if (is_blank_ident(name)) {
			continue;
		} else if (name == "names") {
			error(field, "'names' is a reserved identifier for enumerations");
			continue;
		}

		if (min_value_set) {
			if (compare_exact_values(Token_Gt, min_value, iota)) {
				min_value_index = i;
				min_value = iota;
			}
		} else {
			min_value_index = i;
			min_value = iota;
			min_value_set = true;
		}
		if (max_value_set) {
			if (compare_exact_values(Token_Lt, max_value, iota)) {
				max_value_index = i;
				max_value = iota;
			}
		} else {
			max_value_index = i;
			max_value = iota;
			max_value_set = true;
		}

		Entity *e = alloc_entity_constant(ctx->scope, ident->Ident.token, constant_type, iota);
		e->identifier = ident;
		e->flags |= EntityFlag_Visited;
		e->state = EntityState_Resolved;

		if (scope_lookup_current(ctx->scope, name) != nullptr) {
			error(ident, "'%.*s' is already declared in this enumeration", LIT(name));
		} else {
			add_entity(ctx->checker, ctx->scope, nullptr, e);
			array_add(&fields, e);
			// TODO(bill): Should I add a use for the enum value?
			add_entity_use(ctx, field, e);
		}
	}
	GB_ASSERT(fields.count <= et->fields.count);


	enum_type->Enum.fields = fields;
	enum_type->Enum.names = make_names_field_for_struct(ctx, ctx->scope);
	enum_type->Enum.min_value = min_value;
	enum_type->Enum.max_value = max_value;

	enum_type->Enum.min_value_index = min_value_index;
	enum_type->Enum.max_value_index = max_value_index;
}


void check_bit_field_type(CheckerContext *ctx, Type *bit_field_type, Ast *node) {
	ast_node(bft, BitFieldType, node);
	GB_ASSERT(is_type_bit_field(bit_field_type));

	auto fields  = array_make<Entity*>(ctx->allocator, 0, bft->fields.count);
	auto sizes   = array_make<u32>    (ctx->allocator, 0, bft->fields.count);
	auto offsets = array_make<u32>    (ctx->allocator, 0, bft->fields.count);

	scope_reserve(ctx->scope, bft->fields.count);

	u32 curr_offset = 0;
	for_array(i, bft->fields) {
		Ast *field = bft->fields[i];
		GB_ASSERT(field->kind == Ast_FieldValue);
		Ast *ident = field->FieldValue.field;
		Ast *value = field->FieldValue.value;

		if (ident->kind != Ast_Ident) {
			error(field, "A bit field value's name must be an identifier");
			continue;
		}
		String name = ident->Ident.token.string;

		Operand o = {};
		check_expr(ctx, &o, value);
		if (o.mode != Addressing_Constant) {
			error(value, "Bit field bit size must be a constant");
			continue;
		}
		ExactValue v = exact_value_to_integer(o.value);
		if (v.kind != ExactValue_Integer) {
			error(value, "Bit field bit size must be a constant integer");
			continue;
		}
		i64 bits_ = big_int_to_i64(&v.value_integer); // TODO(bill): what if the integer is huge?
		if (bits_ < 0 || bits_ > 64) {
			error(value, "Bit field's bit size must be within the range 1...64, got %lld", cast(long long)bits_);
			continue;
		}
		u32 bits = cast(u32)bits_;

		Type *value_type = alloc_type_bit_field_value(bits);
		Entity *e = alloc_entity_variable(bit_field_type->BitField.scope, ident->Ident.token, value_type);
		e->identifier = ident;
		e->flags |= EntityFlag_BitFieldValue;

		if (!is_blank_ident(name) &&
		    scope_lookup_current(ctx->scope, name) != nullptr) {
			error(ident, "'%.*s' is already declared in this bit field", LIT(name));
		} else {
			add_entity(ctx->checker, ctx->scope, nullptr, e);
			// TODO(bill): Should this entity be "used"?
			add_entity_use(ctx, field, e);

			array_add(&fields,  e);
			array_add(&offsets, curr_offset);
			array_add(&sizes,   bits);

			curr_offset += bits;
		}
	}
	GB_ASSERT(fields.count <= bft->fields.count);

	bit_field_type->BitField.fields      = fields;
	bit_field_type->BitField.sizes       = sizes;
	bit_field_type->BitField.offsets     = offsets;

	if (bft->align != nullptr) {
		i64 custom_align = 1;
		if (check_custom_align(ctx, bft->align, &custom_align)) {
			bit_field_type->BitField.custom_align = custom_align;
		}
	}
}

bool is_type_valid_bit_set_range(Type *t) {
	if (is_type_integer(t)) {
		return true;
	}
	if (is_type_rune(t)) {
		return true;
	}
	return false;
}

void check_bit_set_type(CheckerContext *c, Type *type, Type *named_type, Ast *node) {
	ast_node(bs, BitSetType, node);
	GB_ASSERT(type->kind == Type_BitSet);

	i64 const DEFAULT_BITS = cast(i64)(8*build_context.word_size);
	i64 const MAX_BITS = 128;

	Ast *base = unparen_expr(bs->elem);
	if (is_ast_range(base)) {
		ast_node(be, BinaryExpr, base);
		Operand lhs = {};
		Operand rhs = {};
		check_expr(c, &lhs, be->left);
		check_expr(c, &rhs, be->right);
		if (lhs.mode == Addressing_Invalid || rhs.mode == Addressing_Invalid) {
			return;
		}
		convert_to_typed(c, &lhs, rhs.type);
		if (lhs.mode == Addressing_Invalid) {
			return;
		}
		convert_to_typed(c, &rhs, lhs.type);
		if (rhs.mode == Addressing_Invalid) {
			return;
		}
		if (!are_types_identical(lhs.type, rhs.type)) {
			if (lhs.type != t_invalid &&
			    rhs.type != t_invalid) {
				gbString xt = type_to_string(lhs.type);
				gbString yt = type_to_string(rhs.type);
				gbString expr_str = expr_to_string(bs->elem);
				error(bs->elem, "Mismatched types in range '%s' : '%s' vs '%s'", expr_str, xt, yt);
				gb_string_free(expr_str);
				gb_string_free(yt);
				gb_string_free(xt);
			}
			return;
		}

		if (!is_type_valid_bit_set_range(lhs.type)) {
			gbString str = type_to_string(lhs.type);
			error(bs->elem, "'%s' is invalid for an interval expression, expected an integer or rune", str);
			gb_string_free(str);
			return;
		}

		if (lhs.mode != Addressing_Constant || rhs.mode != Addressing_Constant) {
			error(bs->elem, "Intervals must be constant values");
			return;
		}

		ExactValue iv = exact_value_to_integer(lhs.value);
		ExactValue jv = exact_value_to_integer(rhs.value);
		GB_ASSERT(iv.kind == ExactValue_Integer);
		GB_ASSERT(jv.kind == ExactValue_Integer);

		BigInt i = iv.value_integer;
		BigInt j = jv.value_integer;
		if (big_int_cmp(&i, &j) > 0) {
			gbAllocator a = heap_allocator();
			String si = big_int_to_string(a, &i);
			String sj = big_int_to_string(a, &j);
			error(bs->elem, "Lower interval bound larger than upper bound, %.*s .. %.*s", LIT(si), LIT(sj));
			gb_free(a, si.text);
			gb_free(a, sj.text);
			return;
		}

		Type *t = default_type(lhs.type);
		if (bs->underlying != nullptr) {
			Type *u = check_type(c, bs->underlying);
			if (!is_type_integer(u)) {
				gbString ts = type_to_string(u);
				error(bs->underlying, "Expected an underlying integer for the bit set, got %s", ts);
				gb_string_free(ts);
				return;
			}
			type->BitSet.underlying = u;
		}

		if (!check_representable_as_constant(c, iv, t, nullptr)) {
			gbAllocator a = heap_allocator();
			String s = big_int_to_string(a, &i);
			gbString ts = type_to_string(t);
			error(bs->elem, "%.*s is not representable by %s", LIT(s), ts);
			gb_string_free(ts);
			gb_free(a, s.text);
			return;
		}
		if (!check_representable_as_constant(c, iv, t, nullptr)) {
			gbAllocator a = heap_allocator();
			String s = big_int_to_string(a, &j);
			gbString ts = type_to_string(t);
			error(bs->elem, "%.*s is not representable by %s", LIT(s), ts);
			gb_string_free(ts);
			gb_free(a, s.text);
			return;
		}
		i64 lower = big_int_to_i64(&i);
		i64 upper = big_int_to_i64(&j);

		i64 bits = MAX_BITS;
		if (type->BitSet.underlying != nullptr) {
			bits = 8*type_size_of(type->BitSet.underlying);
		}

		switch (be->op.kind) {
		case Token_Ellipsis:
			if (upper - lower >= bits) {
				error(bs->elem, "bit_set range is greater than %lld bits, %lld bits are required", bits, (upper-lower+1));
			}
			break;
		case Token_RangeHalf:
			if (upper - lower > bits) {
				error(bs->elem, "bit_set range is greater than %lld bits, %lld bits are required", bits, (upper-lower));
			}
			upper -= 1;
			break;
		}
		type->BitSet.elem  = t;
		type->BitSet.lower = lower;
		type->BitSet.upper = upper;
	} else {
		Type *elem = check_type_expr(c, bs->elem, nullptr);

		#if 1
		if (named_type != nullptr && named_type->kind == Type_Named &&
		    elem->kind == Type_Enum) {
			// NOTE(bill): Anonymous enumeration

			String prefix = named_type->Named.name;
			String enum_name = concatenate_strings(heap_allocator(), prefix, str_lit(".enum"));

			Token token = make_token_ident(enum_name);

			Entity *e = alloc_entity_type_name(nullptr, token, nullptr, EntityState_Resolved);
			Type *named = alloc_type_named(enum_name, elem, e);
			e->type = named;
			e->TypeName.is_type_alias = true;
			elem = named;
		}
		#endif

		type->BitSet.elem = elem;
		if (!is_type_valid_bit_set_elem(elem)) {
			error(bs->elem, "Expected an enum type for a bit_set");
		} else {
			Type *et = base_type(elem);
			if (et->kind == Type_Enum) {
				if (!is_type_integer(et->Enum.base_type)) {
					error(bs->elem, "Enum type for bit_set must be an integer");
					return;
				}
				i64 lower = 0;
				i64 upper = 0;

				for_array(i, et->Enum.fields) {
					Entity *e = et->Enum.fields[i];
					if (e->kind != Entity_Constant) {
						continue;
					}
					ExactValue value = exact_value_to_integer(e->Constant.value);
					GB_ASSERT(value.kind == ExactValue_Integer);
					// NOTE(bill): enum types should be able to store i64 values
					i64 x = big_int_to_i64(&value.value_integer);
					lower = gb_min(lower, x);
					upper = gb_max(upper, x);
				}

				GB_ASSERT(lower <= upper);

				i64 bits = MAX_BITS;
				if (bs->underlying != nullptr) {
					Type *u = check_type(c, bs->underlying);
					if (!is_type_integer(u)) {
						gbString ts = type_to_string(u);
						error(bs->underlying, "Expected an underlying integer for the bit set, got %s", ts);
						gb_string_free(ts);
						return;
					}
					type->BitSet.underlying = u;
					bits = 8*type_size_of(u);
				}

				if (upper - lower >= MAX_BITS) {
					error(bs->elem, "bit_set range is greater than %lld bits, %lld bits are required", MAX_BITS, (upper-lower+1));
				}

				type->BitSet.lower = lower;
				type->BitSet.upper = upper;
			}
		}
	}
}


bool check_type_specialization_to(CheckerContext *ctx, Type *specialization, Type *type, bool compound, bool modify_type) {
	if (type == nullptr ||
	    type == t_invalid) {
		return true;
	}

	Type *t = base_type(type);
	Type *s = base_type(specialization);
	if (t->kind != s->kind) {
		return false;
	}

	if (is_type_untyped(t)) {
		Operand o = {Addressing_Value};
		o.type = default_type(type);
		bool can_convert = check_cast_internal(ctx, &o, specialization);
		return can_convert;
	} else if (t->kind == Type_Struct) {
		if (t->Struct.polymorphic_parent == specialization) {
			return true;
		}

		if (t->Struct.polymorphic_parent == s->Struct.polymorphic_parent &&
		    s->Struct.polymorphic_params != nullptr &&
		    t->Struct.polymorphic_params != nullptr) {

			TypeTuple *s_tuple = &s->Struct.polymorphic_params->Tuple;
			TypeTuple *t_tuple = &t->Struct.polymorphic_params->Tuple;
			GB_ASSERT(t_tuple->variables.count == s_tuple->variables.count);
			for_array(i, s_tuple->variables) {
				Entity *s_e = s_tuple->variables[i];
				Entity *t_e = t_tuple->variables[i];
				Type *st = s_e->type;
				Type *tt = t_e->type;

				// NOTE(bill, 2018-12-14): This is needed to override polymorphic named constants in types
				if (st->kind == Type_Generic && t_e->kind == Entity_Constant) {
					Entity *e = scope_lookup(st->Generic.scope, st->Generic.name);
					GB_ASSERT(e != nullptr);
					if (modify_type) {
						e->kind = Entity_Constant;
						e->Constant.value = t_e->Constant.value;
						e->type = t_e->type;
					}
				} else {
					bool ok = is_polymorphic_type_assignable(ctx, st, tt, true, modify_type);
				}
			}

			if (modify_type) {
				// NOTE(bill): This is needed in order to change the actual type but still have the types defined within it
				gb_memmove(specialization, type, gb_size_of(Type));
			}

			return true;
		}
	} else if (t->kind == Type_Union) {
		if (t->Union.polymorphic_parent == specialization) {
			return true;
		}

		if (t->Union.polymorphic_parent == s->Union.polymorphic_parent &&
		    s->Union.polymorphic_params != nullptr &&
		    t->Union.polymorphic_params != nullptr) {

			TypeTuple *s_tuple = &s->Union.polymorphic_params->Tuple;
			TypeTuple *t_tuple = &t->Union.polymorphic_params->Tuple;
			GB_ASSERT(t_tuple->variables.count == s_tuple->variables.count);
			for_array(i, s_tuple->variables) {
				Entity *s_e = s_tuple->variables[i];
				Entity *t_e = t_tuple->variables[i];
				Type *st = s_e->type;
				Type *tt = t_e->type;

				// NOTE(bill, 2018-12-14): This is needed to override polymorphic named constants in types
				if (st->kind == Type_Generic && t_e->kind == Entity_Constant) {
					Entity *e = scope_lookup(st->Generic.scope, st->Generic.name);
					GB_ASSERT(e != nullptr);
					if (modify_type) {
						e->kind = Entity_Constant;
						e->Constant.value = t_e->Constant.value;
						e->type = t_e->type;
					}
				} else {
					bool ok = is_polymorphic_type_assignable(ctx, st, tt, true, modify_type);
				}
			}

			if (modify_type) {
				// NOTE(bill): This is needed in order to change the actual type but still have the types defined within it
				gb_memmove(specialization, type, gb_size_of(Type));
			}

			return true;
		}
	}

	if (specialization->kind == Type_Named &&
	    type->kind != Type_Named) {
		return false;
	}
	if (is_polymorphic_type_assignable(ctx, base_type(specialization), base_type(type), compound, modify_type)) {
		return true;
	}

	return false;
}


Type *determine_type_from_polymorphic(CheckerContext *ctx, Type *poly_type, Operand operand) {
	bool modify_type = !ctx->no_polymorphic_errors;
	bool show_error = modify_type && !ctx->hide_polymorphic_errors;
	if (!is_operand_value(operand)) {
		if (show_error) {
			error(operand.expr, "Cannot determine polymorphic type from parameter");
		}
		return t_invalid;
	}

	if (is_polymorphic_type_assignable(ctx, poly_type, operand.type, false, modify_type)) {
		if (show_error) {
			set_procedure_abi_types(ctx->allocator, poly_type);
		}
		return poly_type;
	}
	if (show_error) {
		gbString pts = type_to_string(poly_type);
		gbString ots = type_to_string(operand.type);
		defer (gb_string_free(pts));
		defer (gb_string_free(ots));
		error(operand.expr, "Cannot determine polymorphic type from parameter: '%s' to '%s'", ots, pts);
	}
	return t_invalid;
}

bool is_expr_from_a_parameter(CheckerContext *ctx, Ast *expr) {
	if (expr == nullptr) {
		return false;
	}
	expr = unparen_expr(expr);
	if (expr->kind == Ast_SelectorExpr) {
		Ast *lhs = expr->SelectorExpr.expr;
		return is_expr_from_a_parameter(ctx, lhs);
	} else if (expr->kind == Ast_Ident) {
		Operand x= {};
		Entity *e = check_ident(ctx, &x, expr, nullptr, nullptr, false);
		if (e->flags & EntityFlag_Param) {
			return true;
		}
	}
	return false;
}


ParameterValue handle_parameter_value(CheckerContext *ctx, Type *in_type, Type **out_type_, Ast *expr, bool allow_caller_location) {
	ParameterValue param_value = {};
	if (expr == nullptr) {
		return param_value;
	}
	Operand o = {};

	if (allow_caller_location &&
	    expr->kind == Ast_BasicDirective &&
	    expr->BasicDirective.name == "caller_location") {
		init_core_source_code_location(ctx->checker);
		param_value.kind = ParameterValue_Location;
		o.type = t_source_code_location;
	} else {
		if (in_type) {
			check_expr_with_type_hint(ctx, &o, expr, in_type);
		} else {
			check_expr(ctx, &o, expr);
		}

		if (is_operand_nil(o)) {
			param_value.kind = ParameterValue_Nil;
		} else if (o.mode != Addressing_Constant) {
			if (expr->kind == Ast_ProcLit) {
				param_value.kind = ParameterValue_Constant;
				param_value.value = exact_value_procedure(expr);
			} else {
				Entity *e = nullptr;
				// if (o.mode == Addressing_Value && is_type_proc(o.type)) {
				if (o.mode == Addressing_Value || o.mode == Addressing_Variable) {
					Operand x = {};
					if (expr->kind == Ast_Ident) {
						e = check_ident(ctx, &x, expr, nullptr, nullptr, false);
					} else if (expr->kind == Ast_SelectorExpr) {
						e = check_selector(ctx, &x, expr, nullptr);
					}
				}

				if (e != nullptr) {
					if (e->kind == Entity_Procedure) {
						param_value.kind = ParameterValue_Constant;
						param_value.value = exact_value_procedure(e->identifier);
						add_entity_use(ctx, e->identifier, e);
					} else {
						if (e->flags & EntityFlag_Param) {
							error(expr, "Default parameter cannot be another parameter");
						} else {
							if (is_expr_from_a_parameter(ctx, expr)) {
								error(expr, "Default parameter cannot be another parameter");
							} else {
								param_value.kind = ParameterValue_Value;
								param_value.ast_value = expr;
								add_entity_use(ctx, e->identifier, e);
							}
						}
					}
				} else if (allow_caller_location && o.mode == Addressing_Context) {
					param_value.kind = ParameterValue_Value;
					param_value.ast_value = expr;
				} else {
					error(expr, "Default parameter must be a constant");
				}
			}
		} else {
			if (o.value.kind != ExactValue_Invalid) {
				param_value.kind = ParameterValue_Constant;
				param_value.value = o.value;
			} else {
				error(o.expr, "Invalid constant parameter");
			}
		}
	}

	if (in_type) {
		check_assignment(ctx, &o, in_type, str_lit("parameter value"));
	}

	if (out_type_) *out_type_ = default_type(o.type);

	return param_value;
}


Type *check_get_params(CheckerContext *ctx, Scope *scope, Ast *_params, bool *is_variadic_, isize *variadic_index_, bool *success_, isize *specialization_count_, Array<Operand> *operands) {
	if (_params == nullptr) {
		return nullptr;
	}

	bool allow_polymorphic_types = ctx->allow_polymorphic_types;

	bool success = true;
	ast_node(field_list, FieldList, _params);
	Array<Ast *> params = field_list->list;

	if (params.count == 0) {
		if (success_) *success_ = success;
		return nullptr;
	}



	isize variable_count = 0;
	for_array(i, params) {
		Ast *field = params[i];
		if (ast_node_expect(field, Ast_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}
	isize min_variable_count = variable_count;
	for (isize i = params.count-1; i >= 0; i--) {
		Ast *field = params[i];
		if (field->kind == Ast_Field) {
			ast_node(f, Field, field);
			if (f->default_value == nullptr)  {
				break;
			}
			min_variable_count--;
		}
	}


	bool is_variadic = false;
	isize variadic_index = -1;
	bool is_c_vararg = false;
	auto variables = array_make<Entity *>(ctx->allocator, 0, variable_count);
	for_array(i, params) {
		Ast *param = params[i];
		if (param->kind != Ast_Field) {
			continue;
		}
		ast_node(p, Field, param);
		Ast *type_expr = unparen_expr(p->type);
		Type *type = nullptr;
		Ast *default_value = unparen_expr(p->default_value);
		ParameterValue param_value = {};

		bool is_type_param = false;
		bool is_type_polymorphic_type = false;
		bool detemine_type_from_operand = false;
		Type *specialization = nullptr;

		bool is_using = (p->flags&FieldFlag_using) != 0;

		if (type_expr == nullptr) {
			param_value = handle_parameter_value(ctx, nullptr, &type, default_value, true);
		} else {
			if (type_expr->kind == Ast_Ellipsis) {
				type_expr = type_expr->Ellipsis.expr;
				is_variadic = true;
				variadic_index = variables.count;
				if (p->names.count != 1) {
					error(param, "Invalid AST: Invalid variadic parameter with multiple names");
					success = false;
				}
			}
			if (type_expr->kind == Ast_TypeidType)  {
				ast_node(tt, TypeidType, type_expr);
				if (tt->specialization) {
					specialization = check_type(ctx, tt->specialization);
					if (specialization == t_invalid){
						specialization = nullptr;
					}

					if (operands != nullptr) {
						detemine_type_from_operand = true;
						type = t_invalid;
					} else {
						type = alloc_type_generic(ctx->scope, 0, str_lit(""), specialization);
					}
				} else {
					type = t_typeid;
				}
			} else {
				bool prev = ctx->allow_polymorphic_types;
				if (operands != nullptr) {
					ctx->allow_polymorphic_types = true;
				}
				type = check_type(ctx, type_expr);

				ctx->allow_polymorphic_types = prev;

				if (is_type_polymorphic(type)) {
					is_type_polymorphic_type = true;
				}
			}

			if (default_value != nullptr) {
				if (type_expr != nullptr && type_expr->kind == Ast_TypeidType) {
					error(type_expr, "A type parameter may not have a default value");
				} else {
					param_value = handle_parameter_value(ctx, type, nullptr, default_value, true);
				}
			}
		}
		if (type == nullptr) {
			error(param, "Invalid parameter type");
			type = t_invalid;
		}
		if (is_type_untyped(type)) {
			if (is_type_untyped_undef(type)) {
				error(param, "Cannot determine parameter type from ---");
			} else {
				error(param, "Cannot determine parameter type from a nil");
			}
			type = t_invalid;
		}
		if (is_type_empty_union(type)) {
			gbString str = type_to_string(type);
			error(param, "Invalid use of an empty union '%s'", str);
			gb_string_free(str);
			type = t_invalid;
		}


		if (p->flags&FieldFlag_c_vararg) {
			if (p->type == nullptr ||
			    p->type->kind != Ast_Ellipsis) {
				error(param, "'#c_vararg' can only be applied to variadic type fields");
				p->flags &= ~FieldFlag_c_vararg; // Remove the flag
			} else {
				is_c_vararg = true;
			}
		}

		for_array(j, p->names) {
			Ast *name = p->names[j];

			bool is_poly_name = false;

			switch (name->kind) {
			case Ast_Ident:
				break;
			case Ast_PolyType:
				GB_ASSERT(name->PolyType.specialization == nullptr);
				is_poly_name = true;
				name = name->PolyType.type;
				break;
			}
			if (!ast_node_expect(name, Ast_Ident)) {
				continue;
			}

			if (is_poly_name) {
				if (type_expr != nullptr && type_expr->kind == Ast_TypeidType) {
					is_type_param = true;
				} else {
					if (param_value.kind != ParameterValue_Invalid)  {
						error(default_value, "Constant parameters cannot have a default value");
						param_value.kind = ParameterValue_Invalid;
					}
				}
			}

			Entity *param = nullptr;
			if (is_type_param) {
				if (operands != nullptr) {
					Operand o = (*operands)[variables.count];
					if (o.mode == Addressing_Type) {
						type = o.type;
					} else {
						if (!ctx->no_polymorphic_errors) {
							error(o.expr, "Expected a type to assign to the type parameter");
						}
						success = false;
						type = t_invalid;
					}
					if (is_type_polymorphic(type)) {
						gbString str = type_to_string(type);
						error(o.expr, "Cannot pass polymorphic type as a parameter, got '%s'", str);
						gb_string_free(str);
						success = false;
						type = t_invalid;
					}
					if (is_type_untyped(default_type(type))) {
						gbString str = type_to_string(type);
						error(o.expr, "Cannot determine type from the parameter, got '%s'", str);
						gb_string_free(str);
						success = false;
						type = t_invalid;
					}
					bool modify_type = !ctx->no_polymorphic_errors;

					if (specialization != nullptr && !check_type_specialization_to(ctx, specialization, type, false, modify_type)) {
						if (!ctx->no_polymorphic_errors) {
							gbString t = type_to_string(type);
							gbString s = type_to_string(specialization);
							error(o.expr, "Cannot convert type '%s' to the specialization '%s'", t, s);
							gb_string_free(s);
							gb_string_free(t);
						}
						success = false;
						type = t_invalid;
					}
				}

				if (p->flags&FieldFlag_auto_cast) {
					error(name, "'auto_cast' can only be applied to variable fields");
					p->flags &= ~FieldFlag_auto_cast;
				}

				param = alloc_entity_type_name(scope, name->Ident.token, type, EntityState_Resolved);
				param->TypeName.is_type_alias = true;
			} else {
				ExactValue poly_const = {};

				if (operands != nullptr && variables.count < operands->count) {

					Operand op = (*operands)[variables.count];
					if (op.expr == nullptr) {
						// NOTE(bill): 2019-03-30
						// This is just to add the error message to determine_type_from_polymorphic which
						// depends on valid position information
						op.expr = _params;
					}
					if (is_type_polymorphic_type) {
						type = determine_type_from_polymorphic(ctx, type, op);
						if (type == t_invalid) {
							success = false;
						} else if (!ctx->no_polymorphic_errors) {
							// NOTE(bill): The type should be determined now and thus, no need to determine the type any more
							is_type_polymorphic_type = false;
						}
					}
					if (is_poly_name) {
						if (op.mode == Addressing_Constant) {
							poly_const = op.value;
						} else {
							error(op.expr, "Expected a constant value for this polymorphic name parameter");
							success = false;
						}
					}
					if (is_type_untyped(default_type(type))) {
						gbString str = type_to_string(type);
						error(op.expr, "Cannot determine type from the parameter, got '%s'", str);
						gb_string_free(str);
						success = false;
						type = t_invalid;
					}
				}

				if (p->flags&FieldFlag_no_alias) {
					if (!is_type_pointer(type)) {
						error(name, "'#no_alias' can only be applied to fields of pointer type");
						p->flags &= ~FieldFlag_no_alias; // Remove the flag
					}
				}
				if (is_poly_name) {
					if (p->flags&FieldFlag_no_alias) {
						error(name, "'#no_alias' can only be applied to non constant values");
						p->flags &= ~FieldFlag_no_alias; // Remove the flag
					}
					if (p->flags&FieldFlag_auto_cast) {
						error(name, "'auto_cast' can only be applied to variable fields");
						p->flags &= ~FieldFlag_auto_cast;
					}

					if (!is_type_constant_type(type) && !is_type_polymorphic(type)) {
						gbString str = type_to_string(type);
						error(params[i], "A parameter must be a valid constant type, got %s", str);
						gb_string_free(str);
					}

					param = alloc_entity_const_param(scope, name->Ident.token, type, poly_const, is_type_polymorphic(type));
				} else {
					param = alloc_entity_param(scope, name->Ident.token, type, is_using, true);
					param->Variable.param_value = param_value;
				}
			}
			if (p->flags&FieldFlag_no_alias) {
				param->flags |= EntityFlag_NoAlias;
			}
			if (p->flags&FieldFlag_auto_cast) {
				param->flags |= EntityFlag_AutoCast;
			}
			param->state = EntityState_Resolved; // NOTE(bill): This should have be resolved whilst determining it

			add_entity(ctx->checker, scope, name, param);
			if (is_using) {
				add_entity_use(ctx, name, param);
			}
			array_add(&variables, param);
		}
	}


	if (is_variadic) {
		GB_ASSERT(variadic_index >= 0);
	}

	if (is_variadic) {
		GB_ASSERT(params.count > 0);
		// NOTE(bill): Change last variadic parameter to be a slice
		// Custom Calling convention for variadic parameters
		Entity *end = variables[variadic_index];
		end->type = alloc_type_slice(end->type);
		end->flags |= EntityFlag_Ellipsis;
		if (is_c_vararg) {
			end->flags |= EntityFlag_CVarArg;
		}
	}

	isize specialization_count = 0;
	if (scope != nullptr) {
		for_array(i, scope->elements.entries) {
			Entity *e = scope->elements.entries[i].value;
			if (e->kind == Entity_TypeName) {
				Type *t = e->type;
				if (t->kind == Type_Generic &&
				    t->Generic.specialized != nullptr) {
					specialization_count += 1;
				}
			}
		}
	}

	Type *tuple = alloc_type_tuple();
	tuple->Tuple.variables = variables;

	if (success_) *success_ = success;
	if (specialization_count_) *specialization_count_ = specialization_count;
	if (is_variadic_) *is_variadic_ = is_variadic;
	if (variadic_index_) *variadic_index_ = variadic_index;

	return tuple;
}

Type *check_get_results(CheckerContext *ctx, Scope *scope, Ast *_results) {
	if (_results == nullptr) {
		return nullptr;
	}
	ast_node(field_list, FieldList, _results);
	Array<Ast *> results = field_list->list;

	if (results.count == 0) {
		return nullptr;
	}
	Type *tuple = alloc_type_tuple();

	isize variable_count = 0;
	for_array(i, results) {
		Ast *field = results[i];
		if (ast_node_expect(field, Ast_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}

	auto variables = array_make<Entity *>(ctx->allocator, 0, variable_count);
	for_array(i, results) {
		ast_node(field, Field, results[i]);
		Ast *default_value = unparen_expr(field->default_value);
		ParameterValue param_value = {};

		Type *type = nullptr;
		if (field->type == nullptr) {
			param_value = handle_parameter_value(ctx, nullptr, &type, default_value, false);
		} else {
			type = check_type(ctx, field->type);

			if (default_value != nullptr) {
				param_value = handle_parameter_value(ctx, type, nullptr, default_value, false);
			}
		}

		if (type == nullptr) {
			error(results[i], "Invalid parameter type");
			type = t_invalid;
		}
		if (is_type_untyped(type)) {
			error(results[i], "Cannot determine parameter type from a nil");
			type = t_invalid;
		}


		if (field->names.count == 0) {
			Token token = ast_token(field->type);
			token.string = str_lit("");
			Entity *param = alloc_entity_param(scope, token, type, false, false);
			param->Variable.param_value = param_value;
			array_add(&variables, param);
		} else {
			for_array(j, field->names) {
				Token token = ast_token(results[i]);
				if (field->type != nullptr) {
					token = ast_token(field->type);
				}
				token.string = str_lit("");

				Ast *name = field->names[j];
				if (name->kind != Ast_Ident) {
					error(name, "Expected an identifer for as the field name");
				} else {
					token = name->Ident.token;
				}

				if (is_blank_ident(token))  {
					error(name, "Result value cannot be a blank identifer `_`");
				}

				Entity *param = alloc_entity_param(scope, token, type, false, false);
				param->flags |= EntityFlag_Result;
				param->Variable.param_value = param_value;
				array_add(&variables, param);
				add_entity(ctx->checker, scope, name, param);
				// NOTE(bill): Removes `declared but not used` when using -vet
				add_entity_use(ctx, name, param);
			}
		}
	}

	for_array(i, variables) {
		String x = variables[i]->token.string;
		if (x.len == 0 || is_blank_ident(x)) {
			continue;
		}
		for (isize j = i+1; j < variables.count; j++) {
			String y = variables[j]->token.string;
			if (y.len == 0 || is_blank_ident(y)) {
				continue;
			}
			if (x == y) {
				error(variables[j]->token, "Duplicate return value name '%.*s'", LIT(y));
			}
		}
	}

	tuple->Tuple.variables = variables;

	return tuple;
}

Array<Type *> systemv_distribute_struct_fields(Type *t) {
	Type *bt = core_type(t);


	isize distributed_cap = 1;
	if (bt->kind == Type_Struct) {
		distributed_cap = bt->Struct.fields.count;
	}
	auto distributed = array_make<Type *>(heap_allocator(), 0, distributed_cap);

	i64 sz = type_size_of(bt);
	switch (bt->kind) {
	case Type_Basic:
		switch (bt->Basic.kind){
		case Basic_complex64:
			array_add(&distributed, t_f32);
			array_add(&distributed, t_f32);
			break;
		case Basic_complex128:
			array_add(&distributed, t_f64);
			array_add(&distributed, t_f64);
			break;
		case Basic_quaternion128:
			array_add(&distributed, t_f32);
			array_add(&distributed, t_f32);
			array_add(&distributed, t_f32);
			array_add(&distributed, t_f32);
			break;
		case Basic_quaternion256:
			goto DEFAULT;
		case Basic_string:
			array_add(&distributed, t_u8_ptr);
			array_add(&distributed, t_int);
			break;
		case Basic_any:
			GB_ASSERT(type_size_of(t_uintptr) == type_size_of(t_typeid));
			array_add(&distributed, t_rawptr);
			array_add(&distributed, t_uintptr);
			break;

		case Basic_u128:
		case Basic_i128:
			if (build_context.ODIN_OS == "windows") {
				array_add(&distributed, alloc_type_simd_vector(2, t_u64));
			} else {
				array_add(&distributed, bt);
			}
			break;

		default:
			goto DEFAULT;
		}
		break;

	case Type_Struct:
		if (bt->Struct.is_raw_union) {
			goto DEFAULT;
		} else {
			// IMPORTANT TOOD(bill): handle #packed structs correctly
			// IMPORTANT TODO(bill): handle #align structs correctly
			for_array(field_index, bt->Struct.fields) {
				Entity *f = bt->Struct.fields[field_index];
				auto nested = systemv_distribute_struct_fields(f->type);
				array_add_elems(&distributed, nested.data, nested.count);
				array_free(&nested);
			}
		}
		break;

	case Type_Array:
		for (i64 i = 0; i < bt->Array.count; i++) {
			array_add(&distributed, bt->Array.elem);
		}
		break;

	case Type_BitSet:
		array_add(&distributed, bit_set_to_int(bt));
		break;

	case Type_Tuple:
		GB_PANIC("Invalid struct field type");
		break;

	case Type_Slice:
		array_add(&distributed, t_rawptr);
		array_add(&distributed, t_int);
		break;

	case Type_Union:
	case Type_DynamicArray:
	case Type_Map:
	case Type_BitField: // TODO(bill): Ignore?
		// NOTE(bill, 2019-10-10): Odin specific, don't worry about C calling convention yet
		goto DEFAULT;

	case Type_Pointer:
	case Type_Proc:
	case Type_SimdVector: // TODO(bill): Is this correct logic?
	default:
	DEFAULT:;
		if (sz > 0) {
			array_add(&distributed, bt);
		}
		break;
	}

	return distributed;
}

Type *struct_type_from_systemv_distribute_struct_fields(Type *abi_type) {
	GB_ASSERT(is_type_tuple(abi_type));
	Type *final_type = alloc_type_struct();
	final_type->Struct.fields = abi_type->Tuple.variables;
	return final_type;
}


Type *handle_single_distributed_type_parameter(Array<Type *> const &types, bool packed, isize *offset) {
	GB_ASSERT(types.count > 0);

	if (types.count == 1) {
		if (offset) *offset = 1;

		i64 sz = type_size_of(types[0]);

		if (is_type_float(types[0])) {
			return types[0];
		}
		switch (sz) {
		case 0:
			GB_PANIC("Zero sized type found!");
		case 1: return t_u8;
		case 2: return t_u16;
		case 4: return t_u32;
		case 8: return t_u64;
		default:
			return types[0];
		}
	} else if (types.count >= 2) {
	    if (types[0] == t_f32 && types[1] == t_f32) {
	    	if (offset) *offset = 2;
			return alloc_type_simd_vector(2, t_f32);
		} else if (type_size_of(types[0]) == 8) {
	    	if (offset) *offset = 1;
			return types[0];
		}

		i64 total_size = 0;
		isize i = 0;
		if (packed) {
			for (; i < types.count && total_size < 8; i += 1) {
				Type *t = types[i];
				i64 s = type_size_of(t);
				total_size += s;
			}
		} else {
			for (; i < types.count && total_size < 8; i += 1) {
				Type *t = types[i];
				i64 s = gb_max(type_size_of(t), 0);
				i64 a = gb_max(type_align_of(t), 1);
				isize ts = align_formula(total_size, a);
				if (ts >= 8) {
					break;
				}
				total_size = ts + s;
			}
		}
		if (offset) *offset = i;
		switch (total_size) {
		case 1: return t_u8;
		case 2: return t_u16;
		case 4: return t_u32;
		case 8: return t_u64;
		}
		return t_u64;
	}

	return nullptr;
}

Type *handle_struct_system_v_amd64_abi_type(Type *t) {
	if (type_size_of(t) > 16) {
		return alloc_type_pointer(t);
	}
	Type *original_type = t;
	Type *bt = core_type(t);
	t = base_type(t);
	i64 size = type_size_of(bt);

	switch (t->kind) {
	case Type_Slice:
	case Type_Struct:
		break;

	case Type_Basic:
		switch (bt->Basic.kind) {
		case Basic_string:
		case Basic_any:
		case Basic_complex64:
		case Basic_complex128:
		case Basic_quaternion128:
			break;
		default:
			return original_type;
		}
		break;

	default:
		return original_type;
	}

	bool is_packed = false;
	if (is_type_struct(bt)) {
		is_packed = bt->Struct.is_packed;
	}

	if (is_type_raw_union(bt)) {
		// TODO(bill): Handle raw union correctly for
		return t;
	} else {
		auto field_types = systemv_distribute_struct_fields(bt);
		defer (array_free(&field_types));

		GB_ASSERT(field_types.count <= 16);

		Type *final_type = nullptr;

		if (field_types.count == 0) {
			final_type = t;
		} else if (field_types.count == 1) {
			final_type = field_types[0];
		} else {
			if (size <= 8) {
				isize offset = 0;
				final_type = handle_single_distributed_type_parameter(field_types, is_packed, &offset);
			} else {
				isize offset = 0;
				isize next_offset = 0;
				Type *two_types[2] = {};

				two_types[0] = handle_single_distributed_type_parameter(field_types, is_packed, &offset);
				auto remaining = array_slice(field_types, offset, field_types.count);
				two_types[1] = handle_single_distributed_type_parameter(remaining, is_packed, &next_offset);
				GB_ASSERT(offset + next_offset == field_types.count);

				auto variables = array_make<Entity *>(heap_allocator(), 2);
				variables[0] = alloc_entity_param(nullptr, empty_token, two_types[0], false, false);
				variables[1] = alloc_entity_param(nullptr, empty_token, two_types[1], false, false);
				final_type = alloc_type_tuple();
				final_type->Tuple.variables = variables;
				if (t->kind == Type_Struct) {
					// NOTE(bill): Make this packed
					final_type->Tuple.is_packed = t->Struct.is_packed;
				}
			}
		}


		GB_ASSERT(final_type != nullptr);
		i64 ftsz = type_size_of(final_type);
		i64 otsz = type_size_of(original_type);
		if (ftsz != otsz) {
			// TODO(bill): Handle this case which will be caused by #packed most likely
			switch (otsz) {
			case 1:
			case 2:
			case 4:
			case 8:
				GB_PANIC("Incorrectly handled case for handle_struct_system_v_amd64_abi_type, %s %lld vs %s %lld", type_to_string(final_type), ftsz, type_to_string(original_type), otsz);
			}
		}

		return final_type;
	}
}

Type *type_to_abi_compat_param_type(gbAllocator a, Type *original_type, ProcCallingConvention cc) {
	Type *new_type = original_type;

	if (is_type_boolean(original_type)) {
		Type *t = core_type(base_type(new_type));
		if (t == t_bool) {
			return t_llvm_bool;
		}
		return new_type;
	}

	if (cc == ProcCC_None) {
		return new_type;
	}

	if (build_context.ODIN_ARCH == "386") {
		return new_type;
	}

	if (is_type_simd_vector(original_type)) {
		return new_type;
	}
	if (build_context.ODIN_ARCH == "amd64") {
		if (is_type_integer_128bit(original_type)) {
			if (build_context.ODIN_OS == "windows") {
				return alloc_type_simd_vector(2, t_u64);
			} else {
				return original_type;
			}
		}
	}

	if (build_context.ODIN_OS == "windows") {
		// NOTE(bill): Changing the passing parameter value type is to match C's ABI
		// IMPORTANT TODO(bill): This only matches the ABI on MSVC at the moment
		// SEE: https://msdn.microsoft.com/en-us/library/zthk2dkh.aspx


		Type *bt = core_type(original_type);
		switch (bt->kind) {
		// Okay to pass by value (usually)
		// Especially the only Odin types
		case Type_Basic: {
			i64 sz = bt->Basic.size;
			// if (sz > 8 && build_context.word_size < 8) {
			if (sz > 8) {
				new_type = alloc_type_pointer(original_type);
			}
			break;
		}
		case Type_Pointer: break;
		case Type_Proc:    break; // NOTE(bill): Just a pointer

		// Odin specific
		case Type_Slice:
		case Type_Array:
		case Type_DynamicArray:
		case Type_Map:
		case Type_Union:
		// Could be in C too
		case Type_Struct:
		{
			i64 align = type_align_of(original_type);
			i64 size  = type_size_of(original_type);

			switch (8*size) {
			case 8:  new_type = t_u8;  break;
			case 16: new_type = t_u16; break;
			case 32: new_type = t_u32; break;
			case 64: new_type = t_u64; break;
			default:
				new_type = alloc_type_pointer(original_type);
				break;
			}

			break;
		}
		}
	} else if (build_context.ODIN_OS == "linux" ||
	           build_context.ODIN_OS == "darwin") {
		Type *bt = core_type(original_type);
		switch (bt->kind) {
		// Okay to pass by value (usually)
		// Especially the only Odin types
		case Type_Basic: {
			i64 sz = bt->Basic.size;
			// if (sz > 8 && build_context.word_size < 8) {
			if (sz > 8) {
				new_type = alloc_type_pointer(original_type);
			}

			break;
		}
		case Type_Pointer: break;
		case Type_Proc:    break; // NOTE(bill): Just a pointer

		default: {
			i64 size = type_size_of(original_type);
			if (size > 16) {
				new_type = alloc_type_pointer(original_type);
			} else if (build_context.ODIN_ARCH == "amd64") {
				// NOTE(bill): System V AMD64 ABI
				new_type = handle_struct_system_v_amd64_abi_type(bt);
				if (are_types_identical(core_type(original_type), new_type)) {
					new_type = original_type;
				}
				return new_type;
			}

			break;
		}
		}
	} else {
		// IMPORTANT TODO(bill): figure out the ABI settings for Linux, OSX etc. for
		// their architectures
	}

	return new_type;
}

Type *reduce_tuple_to_single_type(Type *original_type) {
	if (original_type != nullptr) {
		Type *t = core_type(original_type);
		if (t->kind == Type_Tuple && t->Tuple.variables.count == 1) {
			return t->Tuple.variables[0]->type;
		}
	}
	return original_type;
}

Type *type_to_abi_compat_result_type(gbAllocator a, Type *original_type, ProcCallingConvention cc) {
	Type *new_type = original_type;
	if (new_type == nullptr) {
		return nullptr;
	}
	GB_ASSERT(is_type_tuple(original_type));

	Type *single_type = reduce_tuple_to_single_type(original_type);

	if (is_type_simd_vector(single_type)) {
		return new_type;
	}

	if (build_context.ODIN_OS == "windows") {
		if (build_context.ODIN_ARCH == "amd64") {
			if (is_type_integer_128bit(single_type)) {
				if (cc == ProcCC_None) {
					return original_type;
				} else {
					return alloc_type_simd_vector(2, t_u64);
				}
			}
		}

		Type *bt = core_type(reduce_tuple_to_single_type(original_type));
		// NOTE(bill): This is just reversed engineered from LLVM IR output
		switch (bt->kind) {
		// Okay to pass by value
		// Especially the only Odin types
		case Type_Pointer: break;
		case Type_Proc:    break; // NOTE(bill): Just a pointer
		case Type_Basic:   break;


		default: {
			i64 align = type_align_of(original_type);
			i64 size  = type_size_of(original_type);
			switch (8*size) {
#if 1
			case 8:  new_type = t_u8;  break;
			case 16: new_type = t_u16; break;
			case 32: new_type = t_u32; break;
			case 64: new_type = t_u64; break;
#endif
			}

			break;
		}
		}
	} else if (build_context.ODIN_OS == "linux" || build_context.ODIN_OS == "darwin") {
		if (build_context.ODIN_ARCH == "amd64") {

		}
	} else {
		// IMPORTANT TODO(bill): figure out the ABI settings for Linux, OSX etc. for
		// their architectures
	}

	if (is_type_integer_128bit(single_type)) {
		if (build_context.word_size == 8) {
			return original_type;
		}
	}


	if (new_type != original_type) {
		Type *tuple = alloc_type_tuple();
		auto variables = array_make<Entity *>(a, 0, 1);
		array_add(&variables, alloc_entity_param(original_type->Tuple.variables[0]->scope, empty_token, new_type, false, false));
		tuple->Tuple.variables = variables;
		new_type = tuple;
	}

	new_type->cached_size = -1;
	new_type->cached_align = -1;
	return new_type;
}

bool abi_compat_return_by_pointer(gbAllocator a, ProcCallingConvention cc, Type *abi_return_type) {
	if (abi_return_type == nullptr) {
		return false;
	}
	if (cc == ProcCC_None) {
		return false;
	}

	Type *single_type = reduce_tuple_to_single_type(abi_return_type);

	if (is_type_simd_vector(single_type)) {
		return false;
	}

	if (build_context.word_size == 8) {
		if (is_type_integer_128bit(single_type)) {
			return false;
		}
	}

	if (build_context.ODIN_OS == "windows") {
		i64 size = 8*type_size_of(abi_return_type);
		switch (size) {
		case 0:
		case 8:
		case 16:
		case 32:
		case 64:
			return false;
		default:
			return true;
		}
	} else {
		if (is_type_integer_128bit(single_type)) {
			return build_context.word_size < 8;
		}
	}



	return false;
}

void set_procedure_abi_types(gbAllocator allocator, Type *type) {
	type = base_type(type);
	if (type->kind != Type_Proc) {
		return;
	}

	if (type->Proc.abi_types_set) {
		return;
	}

	type->Proc.abi_compat_params = array_make<Type *>(allocator, cast(isize)type->Proc.param_count);
	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind == Entity_Variable) {
			Type *original_type = e->type;
			Type *new_type = type_to_abi_compat_param_type(allocator, original_type, type->Proc.calling_convention);
			type->Proc.abi_compat_params[i] = new_type;
			switch (type->Proc.calling_convention) {
			case ProcCC_Odin:
			case ProcCC_Contextless:
				if (is_type_pointer(new_type) & !is_type_pointer(e->type)) {
					e->flags |= EntityFlag_ImplicitReference;
				}
				break;
			}
		}
	}

	for (i32 i = 0; i < type->Proc.param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind == Entity_Variable) {
			set_procedure_abi_types(allocator, e->type);
		}
	}
	for (i32 i = 0; i < type->Proc.result_count; i++) {
		Entity *e = type->Proc.results->Tuple.variables[i];
		if (e->kind == Entity_Variable) {
			set_procedure_abi_types(allocator, e->type);
		}
	}

	// NOTE(bill): The types are the same
	type->Proc.abi_compat_result_type = type_to_abi_compat_result_type(allocator, type->Proc.results, type->Proc.calling_convention);
	type->Proc.return_by_pointer = abi_compat_return_by_pointer(allocator, type->Proc.calling_convention, type->Proc.abi_compat_result_type);

	type->Proc.abi_types_set = true;
}

// NOTE(bill): 'operands' is for generating non generic procedure type
bool check_procedure_type(CheckerContext *ctx, Type *type, Ast *proc_type_node, Array<Operand> *operands) {
	ast_node(pt, ProcType, proc_type_node);

	if (ctx->polymorphic_scope == nullptr && ctx->allow_polymorphic_types) {
		ctx->polymorphic_scope = ctx->scope;
	}

	CheckerContext c_ = *ctx;
	CheckerContext *c = &c_;

	c->curr_proc_sig = type;
	c->in_proc_sig = true;

	bool variadic = false;
	isize variadic_index = -1;
	bool success = true;
	isize specialization_count = 0;
	Type *params  = check_get_params(c, c->scope, pt->params, &variadic, &variadic_index, &success, &specialization_count, operands);
	Type *results = check_get_results(c, c->scope, pt->results);


	isize param_count = 0;
	isize result_count = 0;
	if (params)  param_count  = params ->Tuple.variables.count;
	if (results) result_count = results->Tuple.variables.count;

	if (param_count > 0) {
		for_array(i, params->Tuple.variables) {
			Entity *param = params->Tuple.variables[i];
			if (param->kind == Entity_Variable) {
				ParameterValue pv = param->Variable.param_value;
				if (pv.kind == ParameterValue_Constant &&
				    pv.value.kind == ExactValue_Procedure) {
					type->Proc.has_proc_default_values = true;
					break;
				}
			}
		}
	}

	if (result_count > 0) {
		Entity *first = results->Tuple.variables[0];
		type->Proc.has_named_results = first->token.string != "";
	}


	ProcCallingConvention cc = pt->calling_convention;
	if (cc == ProcCC_ForeignBlockDefault) {
		cc = ProcCC_CDecl;
		if (c->foreign_context.default_cc > 0) {
			cc = c->foreign_context.default_cc;
		}
	}
	GB_ASSERT(cc > 0);

	type->Proc.node                 = proc_type_node;
	type->Proc.scope                = c->scope;
	type->Proc.params               = params;
	type->Proc.param_count          = cast(i32)param_count;
	type->Proc.results              = results;
	type->Proc.result_count         = cast(i32)result_count;
	type->Proc.variadic             = variadic;
	type->Proc.variadic_index       = cast(i32)variadic_index;
	type->Proc.calling_convention   = cc;
	type->Proc.is_polymorphic       = pt->generic;
	type->Proc.specialization_count = specialization_count;
	type->Proc.diverging            = pt->diverging;
	type->Proc.tags                 = pt->tags;

	if (param_count > 0) {
		Entity *end = params->Tuple.variables[param_count-1];
		if (end->flags&EntityFlag_CVarArg) {
			if (cc == ProcCC_StdCall || cc == ProcCC_CDecl) {
				type->Proc.c_vararg = true;
			} else {
				error(end->token, "Calling convention does not support #c_vararg");
			}
		}
	}


	bool is_polymorphic = false;
	for (isize i = 0; i < param_count; i++) {
		Entity *e = params->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			is_polymorphic = true;
			break;
		} else if (is_type_polymorphic(e->type)) {
			is_polymorphic = true;
			break;
		}
	}
	for (isize i = 0; i < result_count; i++) {
		Entity *e = results->Tuple.variables[i];
		if (e->kind != Entity_Variable) {
			is_polymorphic = true;
			break;
		} else if (is_type_polymorphic(e->type)) {
			is_polymorphic = true;
			break;
		}
	}
	type->Proc.is_polymorphic = is_polymorphic;

	return success;
}


i64 check_array_count(CheckerContext *ctx, Operand *o, Ast *e) {
	if (e == nullptr) {
		return 0;
	}
	if (e->kind == Ast_UnaryExpr &&
	    e->UnaryExpr.op.kind == Token_Question) {
		return -1;
	}

	check_expr_or_type(ctx, o, e);
	if (o->mode == Addressing_Type && o->type->kind == Type_Generic) {
		if (ctx->allow_polymorphic_types) {
			if (o->type->Generic.specialized) {
				o->type->Generic.specialized = nullptr;
				error(o->expr, "Polymorphic array length cannot have a specialization");
			}
			return 0;
		}
	}
	if (o->mode == Addressing_Type) {
		if (is_type_enum(o->type)) {
			return -1;
		}
	}

	if (o->mode != Addressing_Constant) {
		if (o->mode != Addressing_Invalid) {
			o->mode = Addressing_Invalid;
			error(e, "Array count must be a constant");
		}
		return 0;
	}
	Type *type = core_type(o->type);
	if (is_type_untyped(type) || is_type_integer(type)) {
		if (o->value.kind == ExactValue_Integer) {
			BigInt count = o->value.value_integer;
			if (o->value.value_integer.neg) {
				gbAllocator a = heap_allocator();
				String str = big_int_to_string(a, &count);
				error(e, "Invalid negative array count, %.*s", LIT(str));
				gb_free(a, str.text);
				return 0;
			}
			switch (count.len) {
			case 0: return 0;
			case 1: return count.d.word;
			}
			gbAllocator a = heap_allocator();
			String str = big_int_to_string(a, &count);
			error(e, "Array count too large, %.*s", LIT(str));
			gb_free(a, str.text);
			return 0;
		}
	}

	error(e, "Array count must be an integer");
	return 0;
}

Type *make_optional_ok_type(Type *value) {
	// LEAK TODO(bill): probably don't reallocate everything here and reuse the same one for the same type if possible
	gbAllocator a = heap_allocator();
	bool typed = true;
	Type *t = alloc_type_tuple();
	array_init(&t->Tuple.variables, a, 0, 2);
	array_add (&t->Tuple.variables, alloc_entity_field(nullptr, blank_token, value,  false, 0));
	array_add (&t->Tuple.variables, alloc_entity_field(nullptr, blank_token, typed ? t_bool : t_untyped_bool, false, 1));
	return t;
}

void init_map_entry_type(Type *type) {
	GB_ASSERT(type->kind == Type_Map);
	if (type->Map.entry_type != nullptr) return;

	// NOTE(bill): The preload types may have not been set yet
	GB_ASSERT(t_map_key != nullptr);
	gbAllocator a = heap_allocator();
	Type *entry_type = alloc_type_struct();

	/*
	struct {
		hash:  __MapKey;
		next:  int;
		key:   Key;
		value: Value;
	}
	*/
	Ast *dummy_node = alloc_ast_node(nullptr, Ast_Invalid);
	Scope *s = create_scope(builtin_pkg->scope, a);

	auto fields = array_make<Entity *>(a, 0, 3);
	array_add(&fields, alloc_entity_field(s, make_token_ident(str_lit("key")),   t_map_key,       false, 0, EntityState_Resolved));
	array_add(&fields, alloc_entity_field(s, make_token_ident(str_lit("next")),  t_int,           false, 1, EntityState_Resolved));
	array_add(&fields, alloc_entity_field(s, make_token_ident(str_lit("value")), type->Map.value, false, 2, EntityState_Resolved));


	entry_type->Struct.fields = fields;

	// type_set_offsets(a, entry_type);
	type->Map.entry_type = entry_type;
}

void init_map_internal_types(Type *type) {
	GB_ASSERT(type->kind == Type_Map);
	init_map_entry_type(type);
	if (type->Map.internal_type != nullptr) return;
	if (type->Map.generated_struct_type != nullptr) return;

	Type *key   = type->Map.key;
	Type *value = type->Map.value;
	GB_ASSERT(key != nullptr);
	GB_ASSERT(value != nullptr);

	Type *generated_struct_type = alloc_type_struct();

	/*
	struct {
		hashes:  []int;
		entries: [dynamic]EntryType;
	}
	*/
	gbAllocator a = heap_allocator();
	Ast *dummy_node = alloc_ast_node(nullptr, Ast_Invalid);
	Scope *s = create_scope(builtin_pkg->scope, a);

	Type *hashes_type  = alloc_type_slice(t_int);
	Type *entries_type = alloc_type_dynamic_array(type->Map.entry_type);


	auto fields = array_make<Entity *>(a, 0, 2);
	array_add(&fields, alloc_entity_field(s, make_token_ident(str_lit("hashes")),  hashes_type,  false, 0, EntityState_Resolved));
	array_add(&fields, alloc_entity_field(s, make_token_ident(str_lit("entries")), entries_type, false, 1, EntityState_Resolved));

	generated_struct_type->Struct.fields = fields;

	type_set_offsets(generated_struct_type);
	type->Map.generated_struct_type = generated_struct_type;
	type->Map.internal_type         = generated_struct_type;
	type->Map.lookup_result_type    = make_optional_ok_type(value);
}

void check_map_type(CheckerContext *ctx, Type *type, Ast *node) {
	GB_ASSERT(type->kind == Type_Map);
	ast_node(mt, MapType, node);

	Type *key   = check_type(ctx, mt->key);
	Type *value = check_type(ctx, mt->value);

	if (!is_type_valid_for_keys(key)) {
		if (is_type_boolean(key)) {
			error(node, "A boolean cannot be used as a key for a map, use an array instead for this case");
		} else {
			gbString str = type_to_string(key);
			error(node, "Invalid type of a key for a map, got '%s'", str);
			gb_string_free(str);
		}
	}

	type->Map.key   = key;
	type->Map.value = value;

	if (is_type_string(key)) {
		add_package_dependency(ctx, "runtime", "default_hash_string");
	}


	init_core_map_type(ctx->checker);
	init_map_internal_types(type);

	// error(node, "'map' types are not yet implemented");
}

Type *make_soa_struct_fixed(CheckerContext *ctx, Ast *array_typ_expr, Ast *elem_expr, Type *elem, i64 count, Type *generic_type) {
	Type *bt_elem = base_type(elem);

	if (!is_type_struct(elem) && !is_type_raw_union(elem) && !(is_type_array(elem) && bt_elem->Array.count <= 4)) {
		gbString str = type_to_string(elem);
		error(elem_expr, "Invalid type for an #soa array, expected a struct or array of length 4 or below, got '%s'", str);
		gb_string_free(str);
		return alloc_type_array(elem, count, generic_type);
	}

	Type *soa_struct = nullptr;
	Scope *scope = nullptr;

	if (is_type_array(elem)) {
		Type *old_array = base_type(elem);
		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), old_array->Array.count);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), old_array->Array.count);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Fixed;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = count;

		scope = create_scope(ctx->scope, ctx->allocator);
		soa_struct->Struct.scope = scope;

		String params_xyzw[4] = {
			str_lit("x"),
			str_lit("y"),
			str_lit("z"),
			str_lit("w")
		};

		for (i64 i = 0; i < old_array->Array.count; i++) {
			Type *array_type = alloc_type_array(old_array->Array.elem, count);
			Token token = {};
			token.string = params_xyzw[i];

			Entity *new_field = alloc_entity_field(scope, token, array_type, false, cast(i32)i);
			soa_struct->Struct.fields[i] = new_field;
			add_entity(ctx->checker, scope, nullptr, new_field);
			add_entity_use(ctx, nullptr, new_field);
		}

	} else {
		GB_ASSERT(is_type_struct(elem));

		Type *old_struct = base_type(elem);
		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), old_struct->Struct.fields.count);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), old_struct->Struct.tags.count);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Fixed;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = count;

		scope = create_scope(old_struct->Struct.scope->parent, ctx->allocator);
		soa_struct->Struct.scope = scope;

		for_array(i, old_struct->Struct.fields) {
			Entity *old_field = old_struct->Struct.fields[i];
			if (old_field->kind == Entity_Variable) {
				Type *array_type = alloc_type_array(old_field->type, count);
				Entity *new_field = alloc_entity_field(scope, old_field->token, array_type, false, old_field->Variable.field_src_index);
				soa_struct->Struct.fields[i] = new_field;
				add_entity(ctx->checker, scope, nullptr, new_field);
				add_entity_use(ctx, nullptr, new_field);
			} else {
				soa_struct->Struct.fields[i] = old_field;
			}

			soa_struct->Struct.tags[i] = old_struct->Struct.tags[i];
		}
	}

	Token token = {};
	token.string = str_lit("Base_Type");
	Entity *base_type_entity = alloc_entity_type_name(scope, token, elem, EntityState_Resolved);
	add_entity(ctx->checker, scope, nullptr, base_type_entity);

	add_type_info_type(ctx, soa_struct);

	return soa_struct;
}

Type *make_soa_struct_slice(CheckerContext *ctx, Ast *array_typ_expr, Ast *elem_expr, Type *elem) {
	Type *bt_elem = base_type(elem);


	bool is_polymorphic = is_type_polymorphic(elem);

	if (!is_polymorphic && !is_type_struct(elem) && !is_type_raw_union(elem) && !(is_type_array(elem) && bt_elem->Array.count <= 4)) {
		GB_ASSERT(elem_expr != nullptr);

		gbString str = type_to_string(elem);
		error(elem_expr, "Invalid type for an #soa array, expected a struct or array of length 4 or below, got '%s'", str);
		gb_string_free(str);
		return alloc_type_slice(elem);
	}

	Type *soa_struct = nullptr;
	Scope *scope = nullptr;

	isize field_count = 0;

	if (is_polymorphic) {
		field_count = 0;

		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), field_count+1);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), field_count+1);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Slice;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = 0;
		soa_struct->Struct.is_polymorphic = true;

		scope = create_scope(ctx->scope, ctx->allocator);
		soa_struct->Struct.scope = scope;
	} else if (is_type_array(elem)) {
		Type *old_array = base_type(elem);
		field_count = old_array->Array.count;

		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), field_count+1);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), field_count+1);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Slice;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = 0;

		scope = create_scope(ctx->scope, ctx->allocator);
		soa_struct->Struct.scope = scope;

		String params_xyzw[4] = {
			str_lit("x"),
			str_lit("y"),
			str_lit("z"),
			str_lit("w")
		};

		for (i64 i = 0; i < field_count; i++) {
			Type *array_type = alloc_type_pointer(old_array->Array.elem);
			Token token = {};
			token.string = params_xyzw[i];

			Entity *new_field = alloc_entity_field(scope, token, array_type, false, cast(i32)i);
			new_field->flags |= EntityFlag_SoaPtrField;
			soa_struct->Struct.fields[i] = new_field;
			add_entity(ctx->checker, scope, nullptr, new_field);
			add_entity_use(ctx, nullptr, new_field);
		}

	} else {
		GB_ASSERT(is_type_struct(elem));

		Type *old_struct = base_type(elem);
		field_count = old_struct->Struct.fields.count;

		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), field_count+1);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), old_struct->Struct.tags.count+1);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Slice;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = 0;

		scope = create_scope(old_struct->Struct.scope->parent, ctx->allocator);
		soa_struct->Struct.scope = scope;

		for_array(i, old_struct->Struct.fields) {
			Entity *old_field = old_struct->Struct.fields[i];
			if (old_field->kind == Entity_Variable) {
				Type *array_type = alloc_type_pointer(old_field->type);
				Entity *new_field = alloc_entity_field(scope, old_field->token, array_type, false, old_field->Variable.field_src_index);
				new_field->flags |= EntityFlag_SoaPtrField;
				soa_struct->Struct.fields[i] = new_field;
				add_entity(ctx->checker, scope, nullptr, new_field);
				add_entity_use(ctx, nullptr, new_field);
			} else {
				soa_struct->Struct.fields[i] = old_field;
			}

			soa_struct->Struct.tags[i] = old_struct->Struct.tags[i];
		}

	}
	Entity *len_field = alloc_entity_field(scope, empty_token, t_int, false, cast(i32)field_count);
	soa_struct->Struct.fields[field_count] = len_field;
	add_entity(ctx->checker, scope, nullptr, len_field);
	add_entity_use(ctx, nullptr, len_field);

	Token token = {};
	token.string = str_lit("Base_Type");
	Entity *base_type_entity = alloc_entity_type_name(scope, token, elem, EntityState_Resolved);
	add_entity(ctx->checker, scope, nullptr, base_type_entity);

	add_type_info_type(ctx, soa_struct);

	return soa_struct;
}


Type *make_soa_struct_dynamic_array(CheckerContext *ctx, Ast *array_typ_expr, Ast *elem_expr, Type *elem) {
	Type *bt_elem = base_type(elem);

	bool is_polymorphic = is_type_polymorphic(elem);

	if (!is_polymorphic && !is_type_struct(elem) && !is_type_raw_union(elem) && !(is_type_array(elem) && bt_elem->Array.count <= 4)) {
		GB_ASSERT(elem_expr != nullptr);

		gbString str = type_to_string(elem);
		error(elem_expr, "Invalid type for an #soa array, expected a struct or array of length 4 or below, got '%s'", str);
		gb_string_free(str);
		return alloc_type_dynamic_array(elem);
	}

	Type *soa_struct = nullptr;
	Scope *scope = nullptr;

	isize field_count = 0;

	if (is_polymorphic) {
		field_count = 0;

		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), field_count+3);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), field_count+3);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Dynamic;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = 0;
		soa_struct->Struct.is_polymorphic = true;

		scope = create_scope(ctx->scope, ctx->allocator);
		soa_struct->Struct.scope = scope;
	} else if (is_type_array(elem)) {
		Type *old_array = base_type(elem);
		field_count = old_array->Array.count;

		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), field_count+3);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), field_count+3);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Dynamic;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = 0;

		scope = create_scope(ctx->scope, ctx->allocator);
		soa_struct->Struct.scope = scope;

		String params_xyzw[4] = {
			str_lit("x"),
			str_lit("y"),
			str_lit("z"),
			str_lit("w")
		};

		for (i64 i = 0; i < field_count; i++) {
			Type *array_type = alloc_type_pointer(old_array->Array.elem);
			Token token = {};
			token.string = params_xyzw[i];

			Entity *new_field = alloc_entity_field(scope, token, array_type, false, cast(i32)i);
			new_field->flags |= EntityFlag_SoaPtrField;
			soa_struct->Struct.fields[i] = new_field;
			add_entity(ctx->checker, scope, nullptr, new_field);
			add_entity_use(ctx, nullptr, new_field);
		}
	} else {
		GB_ASSERT(is_type_struct(elem));

		Type *old_struct = base_type(elem);
		field_count = old_struct->Struct.fields.count;

		soa_struct = alloc_type_struct();
		soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), field_count+3);
		soa_struct->Struct.tags = array_make<String>(heap_allocator(), old_struct->Struct.tags.count+3);
		soa_struct->Struct.node = array_typ_expr;
		soa_struct->Struct.soa_kind = StructSoa_Dynamic;
		soa_struct->Struct.soa_elem = elem;
		soa_struct->Struct.soa_count = 0;

		scope = create_scope(old_struct->Struct.scope->parent, ctx->allocator);
		soa_struct->Struct.scope = scope;

		for_array(i, old_struct->Struct.fields) {
			Entity *old_field = old_struct->Struct.fields[i];
			if (old_field->kind == Entity_Variable) {
				Type *array_type = alloc_type_pointer(old_field->type);
				Entity *new_field = alloc_entity_field(scope, old_field->token, array_type, false, old_field->Variable.field_src_index);
				new_field->flags |= EntityFlag_SoaPtrField;
				soa_struct->Struct.fields[i] = new_field;
				add_entity(ctx->checker, scope, nullptr, new_field);
				add_entity_use(ctx, nullptr, new_field);
			} else {
				soa_struct->Struct.fields[i] = old_field;
			}

			soa_struct->Struct.tags[i] = old_struct->Struct.tags[i];
		}
	}

	Entity *len_field = alloc_entity_field(scope, empty_token, t_int, false, cast(i32)field_count);
	soa_struct->Struct.fields[field_count+0] = len_field;
	add_entity(ctx->checker, scope, nullptr, len_field);
	add_entity_use(ctx, nullptr, len_field);

	Entity *cap_field = alloc_entity_field(scope, empty_token, t_int, false, cast(i32)field_count);
	soa_struct->Struct.fields[field_count+1] = cap_field;
	add_entity(ctx->checker, scope, nullptr, cap_field);
	add_entity_use(ctx, nullptr, cap_field);

	Token token = {};
	token.string = str_lit("allocator");
	Entity *allocator_field = alloc_entity_field(scope, token, t_allocator, false, cast(i32)field_count);
	soa_struct->Struct.fields[field_count+2] = allocator_field;
	add_entity(ctx->checker, scope, nullptr, allocator_field);
	add_entity_use(ctx, nullptr, allocator_field);

	token.string = str_lit("Base_Type");
	Entity *base_type_entity = alloc_entity_type_name(scope, token, elem, EntityState_Resolved);
	add_entity(ctx->checker, scope, nullptr, base_type_entity);

	add_type_info_type(ctx, soa_struct);

	return soa_struct;
}



bool check_type_internal(CheckerContext *ctx, Ast *e, Type **type, Type *named_type) {
	GB_ASSERT_NOT_NULL(type);
	if (e == nullptr) {
		*type = t_invalid;
		return true;
	}

	switch (e->kind) {
	case_ast_node(i, Ident, e);
		Operand o = {};
		Entity *entity = check_ident(ctx, &o, e, named_type, nullptr, false);

		gbString err_str = nullptr;
		defer (gb_string_free(err_str));

		switch (o.mode) {
		case Addressing_Invalid:
			break;
		case Addressing_Type: {
			*type = o.type;
			if (!ctx->in_polymorphic_specialization) {
				Type *t = base_type(o.type);
				if (t != nullptr && is_type_polymorphic_record_unspecialized(t)) {
					err_str = expr_to_string(e);
					error(e, "Invalid use of a non-specialized polymorphic type '%s'", err_str);
					return true;
				}
			}

			// if (ctx->type_level == 0 && entity->state == EntityState_InProgress) {
			// 	error(entity->token, "Illegal declaration cycle of `%.*s`", LIT(entity->token.string));
			// 	for_array(j, *ctx->type_path) {
			// 		Entity *k = (*ctx->type_path)[j];
			// 		error(k->token, "\t%.*s refers to", LIT(k->token.string));
			// 	}
			// 	error(entity->token, "\t%.*s", LIT(entity->token.string));
			// 	*type = t_invalid;
			// }
			return true;
		}

		case Addressing_NoValue:
			err_str = expr_to_string(e);
			error(e, "'%s' used as a type", err_str);
			break;

		default:
			err_str = expr_to_string(e);
			error(e, "'%s' used as a type when not a type", err_str);
			break;
		}
	case_end;

	case_ast_node(ht, HelperType, e);
		return check_type_internal(ctx, ht->type, type, named_type);
	case_end;

	case_ast_node(dt, DistinctType, e);
		error(e, "Invalid use of a distinct type");
		// NOTE(bill): Treat it as a HelperType to remove errors
		return check_type_internal(ctx, dt->type, type, named_type);
	case_end;

	case_ast_node(tt, TypeidType, e);
		e->tav.mode = Addressing_Type;
		e->tav.type = t_typeid;
		*type = t_typeid;
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(pt, PolyType, e);
		Ast *ident = pt->type;
		if (ident->kind != Ast_Ident) {
			error(ident, "Expected an identifier after the $");
			*type = t_invalid;
			return false;
		}

		Token token = ident->Ident.token;
		Type *specific = nullptr;
		if (pt->specialization != nullptr) {
			CheckerContext c = *ctx;
			c.in_polymorphic_specialization = true;

			Ast *s = pt->specialization;
			specific = check_type(&c, s);
		}
		Type *t = alloc_type_generic(ctx->scope, 0, token.string, specific);
		if (ctx->allow_polymorphic_types) {
			Scope *ps = ctx->polymorphic_scope;
			Scope *s = ctx->scope;
			Scope *entity_scope = s;
			if (ps != nullptr && ps != s) {
				// TODO(bill): Is this check needed?
				// GB_ASSERT_MSG(is_scope_an_ancestor(ps, s) >= 0);
				entity_scope = ps;
			}
			Entity *e = alloc_entity_type_name(entity_scope, token, t);
			t->Generic.entity = e;
			e->TypeName.is_type_alias = true;
			e->state = EntityState_Resolved;
			add_entity(ctx->checker, ps, ident, e);
			add_entity(ctx->checker, s, ident, e);
		} else {
			error(ident, "Invalid use of a polymorphic parameter '$%.*s'", LIT(token.string));
			*type = t_invalid;
			return false;
		}
		*type = t;
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(se, SelectorExpr, e);
		Operand o = {};
		check_selector(ctx, &o, e, nullptr);

		gbString err_str;
		switch (o.mode) {
		case Addressing_Invalid:
			break;
		case Addressing_Type:
			GB_ASSERT(o.type != nullptr);
			*type = o.type;
			return true;
		case Addressing_NoValue:
			err_str = expr_to_string(e);
			error(e, "'%s' used as a type", err_str);
			gb_string_free(err_str);
			break;
		default:
			err_str = expr_to_string(e);
			error(e, "'%s' is not a type", err_str);
			gb_string_free(err_str);
			break;
		}
	case_end;

	case_ast_node(pe, ParenExpr, e);
		*type = check_type_expr(ctx, pe->expr, named_type);
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(ue, UnaryExpr, e);
		switch (ue->op.kind) {
		case Token_Pointer:
			*type = alloc_type_pointer(check_type(ctx, ue->expr));
			set_base_type(named_type, *type);
			return true;
		}
	case_end;

	case_ast_node(pt, PointerType, e);
		*type = alloc_type_pointer(check_type(ctx, pt->type));
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(ot, OpaqueType, e);
		Type *elem = strip_opaque_type(check_type_expr(ctx, ot->type, nullptr));
		*type = alloc_type_opaque(elem);
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(at, ArrayType, e);
		if (at->count != nullptr) {
			Operand o = {};
			i64 count = check_array_count(ctx, &o, at->count);
			Type *generic_type = nullptr;

			Type *elem = check_type_expr(ctx, at->elem, nullptr);

			if (o.mode == Addressing_Type && o.type->kind == Type_Generic) {
				generic_type = o.type;
			} else if (o.mode == Addressing_Type && is_type_enum(o.type)) {
				Type *index = o.type;
				Type *bt = base_type(index);
				GB_ASSERT(bt->kind == Type_Enum);

				Type *t = alloc_type_enumerated_array(elem, index, bt->Enum.min_value, bt->Enum.max_value, Token_Invalid);

				bool is_partial = false;
				if (at->tag != nullptr) {
					GB_ASSERT(at->tag->kind == Ast_BasicDirective);
					String name = at->tag->BasicDirective.name;
					if (name == "partial") {
						is_partial = true;
					} else {
						error(at->tag, "Invalid tag applied to an enumerated array, got #%.*s", LIT(name));
					}
				}

				if (!is_partial && t->EnumeratedArray.count > bt->Enum.fields.count) {
					error(e, "Non-contiguous enumeration used as an index in an enumerated array");
					long long ea_count   = cast(long long)t->EnumeratedArray.count;
					long long enum_count = cast(long long)t->Enum.fields.count;
					error_line("\tenumerated array length: %lld\n", ea_count);
					error_line("\tenum field count: %lld\n", enum_count);
					error_line("\tSuggestion: prepend #partial to the enumerated array to allow for non-named elements\n");
					if (2*enum_count < ea_count) {
						error_line("\tWarning: the number of named elements is much smaller than the length of the array, are you sure this is what you want?\n");
						error_line("\t         this warning will be removed if #partial is applied\n");
					}
				}

				*type = t;

				goto array_end;
			}

			if (count < 0) {
				error(at->count, "? can only be used in conjuction with compound literals");
				count = 0;
			}


			if (at->tag != nullptr) {
				GB_ASSERT(at->tag->kind == Ast_BasicDirective);
				String name = at->tag->BasicDirective.name;
				if (name == "soa") {
					*type = make_soa_struct_fixed(ctx, e, at->elem, elem, count, generic_type);
				} else if (name == "simd") {
					if (!is_type_valid_vector_elem(elem)) {
						gbString str = type_to_string(elem);
						error(at->elem, "Invalid element type for 'intrinsics.simd_vector', expected an integer or float with no specific endianness, got '%s'", str);
						gb_string_free(str);
						*type = alloc_type_array(elem, count, generic_type);
						goto array_end;
					}

					*type = alloc_type_simd_vector(count, elem);
				} else {
					error(at->tag, "Invalid tag applied to array, got #%.*s", LIT(name));
					*type = alloc_type_array(elem, count, generic_type);
				}
			} else {
				*type = alloc_type_array(elem, count, generic_type);
			}
		} else {
			Type *elem = check_type(ctx, at->elem);

			if (at->tag != nullptr) {
				GB_ASSERT(at->tag->kind == Ast_BasicDirective);
				String name = at->tag->BasicDirective.name;
				if (name == "soa") {
					*type = make_soa_struct_slice(ctx, e, at->elem, elem);
				} else {
					error(at->tag, "Invalid tag applied to array, got #%.*s", LIT(name));
					*type = alloc_type_slice(elem);
				}
			} else {
				*type = alloc_type_slice(elem);
			}
		}
	array_end:
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(dat, DynamicArrayType, e);
		Type *elem = check_type(ctx, dat->elem);
		if (dat->tag != nullptr) {
			GB_ASSERT(dat->tag->kind == Ast_BasicDirective);
			String name = dat->tag->BasicDirective.name;
			if (name == "soa") {
				*type = make_soa_struct_dynamic_array(ctx, e, dat->elem, elem);
			} else {
				error(dat->tag, "Invalid tag applied to dynamic array, got #%.*s", LIT(name));
				*type = alloc_type_dynamic_array(elem);
			}
		} else {
			*type = alloc_type_dynamic_array(elem);
		}
		set_base_type(named_type, *type);
		return true;
	case_end;

	case_ast_node(st, StructType, e);
		CheckerContext c = *ctx;
		c.in_polymorphic_specialization = false;
		c.type_level += 1;

		*type = alloc_type_struct();
		set_base_type(named_type, *type);
		check_open_scope(&c, e);
		check_struct_type(&c, *type, e, nullptr, named_type);
		check_close_scope(&c);
		(*type)->Struct.node = e;
		return true;
	case_end;

	case_ast_node(ut, UnionType, e);
		CheckerContext c = *ctx;
		c.in_polymorphic_specialization = false;
		c.type_level += 1;

		*type = alloc_type_union();
		set_base_type(named_type, *type);
		check_open_scope(&c, e);
		check_union_type(&c, *type, e, nullptr, named_type);
		check_close_scope(&c);
		(*type)->Union.node = e;
		return true;
	case_end;

	case_ast_node(et, EnumType, e);
		bool ips = ctx->in_polymorphic_specialization;
		defer (ctx->in_polymorphic_specialization = ips);
		ctx->in_polymorphic_specialization = false;
		ctx->in_enum_type = true;

		*type = alloc_type_enum();
		set_base_type(named_type, *type);
		check_open_scope(ctx, e);
		check_enum_type(ctx, *type, named_type, e);
		check_close_scope(ctx);
		(*type)->Enum.node = e;

		ctx->in_enum_type = false;
		return true;
	case_end;

	case_ast_node(et, BitFieldType, e);
		*type = alloc_type_bit_field();
		set_base_type(named_type, *type);
		check_open_scope(ctx, e);
		check_bit_field_type(ctx, *type, e);
		check_close_scope(ctx);
		return true;
	case_end;

	case_ast_node(bs, BitSetType, e);
		*type = alloc_type_bit_set();
		set_base_type(named_type, *type);
		check_bit_set_type(ctx, *type, named_type, e);
		return true;
	case_end;


	case_ast_node(pt, ProcType, e);
		bool ips = ctx->in_polymorphic_specialization;
		defer (ctx->in_polymorphic_specialization = ips);
		ctx->in_polymorphic_specialization = false;

		*type = alloc_type(Type_Proc);
		set_base_type(named_type, *type);
		check_open_scope(ctx, e);
		check_procedure_type(ctx, *type, e);
		check_close_scope(ctx);
		return true;
	case_end;

	case_ast_node(mt, MapType, e);
		bool ips = ctx->in_polymorphic_specialization;
		defer (ctx->in_polymorphic_specialization = ips);
		ctx->in_polymorphic_specialization = false;

		*type = alloc_type(Type_Map);
		set_base_type(named_type, *type);
		check_map_type(ctx, *type, e);
		return true;
	case_end;

	case_ast_node(ce, CallExpr, e);
		Operand o = {};
		check_expr_or_type(ctx, &o, e);
		if (o.mode == Addressing_Type) {
			*type = o.type;
			set_base_type(named_type, *type);
			return true;
		}
	case_end;

	case_ast_node(te, TernaryExpr, e);
		Operand o = {};
		check_expr_or_type(ctx, &o, e);
		if (o.mode == Addressing_Type) {
			*type = o.type;
			set_base_type(named_type, *type);
			return true;
		}
	case_end;
	}

	*type = t_invalid;
	return false;
}

Type *check_type(CheckerContext *ctx, Ast *e) {
	CheckerContext c = *ctx;
	c.type_path = new_checker_type_path();
	defer (destroy_checker_type_path(c.type_path));

	return check_type_expr(&c, e, nullptr);
}

Type *check_type_expr(CheckerContext *ctx, Ast *e, Type *named_type) {
	Type *type = nullptr;
	bool ok = check_type_internal(ctx, e, &type, named_type);

	if (!ok) {
		gbString err_str = expr_to_string(e);
		error(e, "'%s' is not a type", err_str);
		gb_string_free(err_str);
		type = t_invalid;
	}

	if (type == nullptr) {
		type = t_invalid;
	}

	if (type->kind == Type_Named &&
	    type->Named.base == nullptr) {
		// IMPORTANT TODO(bill): Is this a serious error?!
		#if 0
		error(e, "Invalid type definition of '%.*s'", LIT(type->Named.name));
		#endif
		type->Named.base = t_invalid;
	}

	if (is_type_polymorphic(type)) {
		type->flags |= TypeFlag_Polymorphic;
	} else if (is_type_polymorphic(type, true)) {
		type->flags |= TypeFlag_PolySpecialized;
	}

	#if 0
	if (!ctx->allow_polymorphic_types && is_type_polymorphic(type)) {
		gbString str = type_to_string(type);
		error(e, "Invalid use of a polymorphic type '%s'", str);
		gb_string_free(str);
		type = t_invalid;
	}
	#endif

	if (is_type_typed(type)) {
		add_type_and_value(&ctx->checker->info, e, Addressing_Type, type, empty_exact_value);
	} else {
		gbString name = type_to_string(type);
		error(e, "Invalid type definition of %s", name);
		gb_string_free(name);
		type = t_invalid;
	}
	set_base_type(named_type, type);

	return type;
}
