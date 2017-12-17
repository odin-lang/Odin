
void populate_using_entity_map(Checker *c, AstNode *node, Type *t, Map<Entity *> *entity_map) {
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
			HashKey key = hash_string(name);
			Entity **found = map_get(entity_map, key);
			if (found != nullptr && name != "_") {
				Entity *e = *found;
				// TODO(bill): Better type error
				if (str != nullptr) {
					error(e->token, "'%.*s' is already declared in '%s'", LIT(name), str);
				} else {
					error(e->token, "'%.*s' is already declared", LIT(name));
				}
			} else {
				map_set(entity_map, key, f);
				add_entity(c, c->context.scope, nullptr, f);
				if (f->flags & EntityFlag_Using) {
					populate_using_entity_map(c, node, f->type, entity_map);
				}
			}
		}
	}

}

// Returns filled field_count
Array<Entity *> check_struct_fields(Checker *c, AstNode *node, Array<AstNode *> params,
                                    isize init_field_capacity, Type *named_type, String context) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	Array<Entity *> fields = {};
	array_init(&fields, heap_allocator(), init_field_capacity);

	Map<Entity *> entity_map = {};
	map_init(&entity_map, c->tmp_allocator, 2*init_field_capacity);


	GB_ASSERT(node->kind == AstNode_StructType);

	isize variable_count = 0;
	for_array(i, params) {
		AstNode *field = params[i];
		if (ast_node_expect(field, AstNode_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}

	i32 field_src_index = 0;
	for_array(i, params) {
		AstNode *param = params[i];
		if (param->kind != AstNode_Field) {
			continue;
		}
		ast_node(p, Field, param);
		AstNode *type_expr = p->type;
		Type *type = nullptr;
		AstNode *default_value = unparen_expr(p->default_value);
		ExactValue value = {};
		bool default_is_nil = false;
		bool detemine_type_from_operand = false;


		if (type_expr == nullptr) {
			Operand o = {};
			check_expr_or_type(c, &o, default_value);
			if (is_operand_nil(o)) {
				default_is_nil = true;
			} else if (o.mode != Addressing_Constant) {
				if (default_value->kind == AstNode_ProcLit) {
					if (named_type != nullptr) {
						value = exact_value_procedure(default_value);
					} else {
						error(default_value, "A procedure literal cannot be a default value in an anonymous structure");
					}
				} else {
					Entity *e = nullptr;
					if (o.mode == Addressing_Value && is_type_proc(o.type)) {
						Operand x = {};
						if (default_value->kind == AstNode_Ident) {
							e = check_ident(c, &x, default_value, nullptr, nullptr, false);
						} else if (default_value->kind == AstNode_SelectorExpr) {
							e = check_selector(c, &x, default_value, nullptr);
						}
					}

					if (e != nullptr && e->kind == Entity_Procedure) {
						value = exact_value_procedure(e->identifier);
						add_entity_use(c, e->identifier, e);
					} else {
						error(default_value, "Default parameter must be a constant");
					}
				}
			} else {
				value = o.value;
			}

			type = default_type(o.type);
		} else {
			if (type_expr->kind == AstNode_Ident && type_expr->Ident.token.string == "Element") {
				gb_printf_err("Element\n");
			}

			type = check_type(c, type_expr);

			if (default_value != nullptr) {
				Operand o = {};
				check_expr_with_type_hint(c, &o, default_value, type);

				if (is_operand_nil(o)) {
					default_is_nil = true;
				} else if (o.mode != Addressing_Constant) {
					if (default_value->kind == AstNode_ProcLit) {
						if (named_type != nullptr) {
							value = exact_value_procedure(default_value);
						} else {
							error(default_value, "A procedure literal cannot be a default value in an anonymous structure");
						}
					} else {
						Entity *e = nullptr;
						if (o.mode == Addressing_Value && is_type_proc(o.type)) {
							Operand x = {};
							if (default_value->kind == AstNode_Ident) {
								e = check_ident(c, &x, default_value, nullptr, nullptr, false);
							} else if (default_value->kind == AstNode_SelectorExpr) {
								e = check_selector(c, &x, default_value, nullptr);
							}
						}

						if (e != nullptr && e->kind == Entity_Procedure) {
							value = exact_value_procedure(e->identifier);
							add_entity_use(c, e->identifier, e);
						} else {
							error(default_value, "Default parameter must be a constant");
						}
					}
				} else {
					value = o.value;
				}

				check_is_assignable_to(c, &o, type);
			}

			if (is_type_polymorphic(type)) {
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
			AstNode *name = p->names[j];
			if (!ast_node_expect(name, AstNode_Ident)) {
				continue;
			}

			Token name_token = name->Ident.token;

			Entity *field = nullptr;
			field = make_entity_field(c->allocator, c->context.scope, name_token, type, is_using, field_src_index);
			field->Variable.default_value = value;
			field->Variable.default_is_nil = default_is_nil;

			add_entity(c, c->context.scope, name, field);
			array_add(&fields, field);

			field_src_index += 1;
		}


		if (is_using && p->names.count > 0) {
			Type *first_type = fields[fields.count-1]->type;
			Type *t = base_type(type_deref(first_type));

			if (!is_type_struct(t) && !is_type_raw_union(t) && !is_type_bit_field(t) &&
			    p->names.count >= 1 &&
			    p->names[0]->kind == AstNode_Ident) {
				Token name_token = p->names[0]->Ident.token;
				gbString type_str = type_to_string(first_type);
				error(name_token, "'using' cannot be applied to the field '%.*s' of type '%s'", LIT(name_token.string), type_str);
				gb_string_free(type_str);
				continue;
			}

			populate_using_entity_map(c, node, type, &entity_map);
		}
	}

	return fields;
}


// TODO(bill): Cleanup struct field reordering
// TODO(bill): Inline sorting procedure?
GB_COMPARE_PROC(cmp_reorder_struct_fields) {
	// Rule:
	// 'using' over non-'using'
	// Biggest to smallest alignment
	// if same alignment: biggest to smallest size
	// if same size: order by source order
	Entity *x = *(Entity **)a;
	Entity *y = *(Entity **)b;
	GB_ASSERT(x != nullptr);
	GB_ASSERT(y != nullptr);
	GB_ASSERT(x->kind == Entity_Variable);
	GB_ASSERT(y->kind == Entity_Variable);
	bool xu = (x->flags & EntityFlag_Using) != 0;
	bool yu = (y->flags & EntityFlag_Using) != 0;
	i64 xa = type_align_of(heap_allocator(), x->type);
	i64 ya = type_align_of(heap_allocator(), y->type);
	i64 xs = type_size_of(heap_allocator(), x->type);
	i64 ys = type_size_of(heap_allocator(), y->type);

	if (xu != yu) {
		return xu ? -1 : +1;
	}

	if (xa != ya) {
		return xa > ya ? -1 : xa < ya;
	}
	if (xs != ys) {
		return xs > ys ? -1 : xs < ys;
	}
	i32 diff = x->Variable.field_index - y->Variable.field_index;
	return diff < 0 ? -1 : diff > 0;
}

Entity *make_names_field_for_struct(Checker *c, Scope *scope) {
	Entity *e = make_entity_field(c->allocator, scope,
		make_token_ident(str_lit("names")), t_string_slice, false, 0);
	e->Variable.is_immutable = true;
	e->flags |= EntityFlag_TypeField;
	return e;
}

bool check_custom_align(Checker *c, AstNode *node, i64 *align_) {
	GB_ASSERT(align_ != nullptr);
	Operand o = {};
	check_expr(c, &o, node);
	if (o.mode != Addressing_Constant) {
		if (o.mode != Addressing_Invalid) {
			error(node, "#align must be a constant");
		}
		return false;
	}

	Type *type = base_type(o.type);
	if (is_type_untyped(type) || is_type_integer(type)) {
		if (o.value.kind == ExactValue_Integer) {
			i64 align = i128_to_i64(o.value.value_integer);
			if (align < 1 || !gb_is_power_of_two(align)) {
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


Entity *find_polymorphic_struct_entity(Checker *c, Type *original_type, isize param_count, Array<Operand> ordered_operands) {
	gb_mutex_lock(&c->mutex);
	defer (gb_mutex_unlock(&c->mutex));

	auto *found_gen_types = map_get(&c->info.gen_types, hash_pointer(original_type));
	if (found_gen_types != nullptr) {
		for_array(i, *found_gen_types) {
			Entity *e = (*found_gen_types)[i];
			Type *t = base_type(e->type);
			TypeTuple *tuple = &t->Struct.polymorphic_params->Tuple;
			bool ok = true;
			GB_ASSERT(param_count == tuple->variables.count);
			for (isize j = 0; j < param_count; j++) {
				Entity *p = tuple->variables[j];
				Operand o = ordered_operands[j];
				if (p->kind == Entity_TypeName) {
					if (is_type_polymorphic(o.type)) {
						// NOTE(bill): Do not add polymorphic version to the gen_types
						ok = false;
					}
					if (!are_types_identical(o.type, p->type)) {
						ok = false;
					}
				} else if (p->kind == Entity_Constant) {
					if (!are_types_identical(o.type, p->type)) {
						ok = false;
					}
					if (!compare_exact_values(Token_CmpEq, o.value, p->Constant.value)) {
						ok = false;
					}
				} else {
					GB_PANIC("Unknown entity kind");
				}
			}
			if (ok) {
				return e;
			}
		}
	}
	return nullptr;
}


void add_polymorphic_struct_entity(Checker *c, AstNode *node, Type *named_type, Type *original_type) {
	GB_ASSERT(is_type_named(named_type));
	gbAllocator a = heap_allocator();
	Scope *s = c->context.scope->parent;

	Entity *e = nullptr;
	{
		Token token = ast_node_token(node);
		token.kind = Token_String;
		token.string = named_type->Named.name;

		AstNode *node = gb_alloc_item(a, AstNode);
		node->kind = AstNode_Ident;
		node->Ident.token = token;

		e = make_entity_type_name(a, s, token, named_type);
		add_entity_use(c, node, e);
	}

	named_type->Named.type_name = e;

	auto *found_gen_types = map_get(&c->info.gen_types, hash_pointer(original_type));
	if (found_gen_types) {
		array_add(found_gen_types, e);
	} else {
		Array<Entity *> array = {};
		array_init(&array, heap_allocator());
		array_add(&array, e);
		map_set(&c->info.gen_types, hash_pointer(original_type), array);
	}
}

void check_struct_type(Checker *c, Type *struct_type, AstNode *node, Array<Operand> *poly_operands, Type *named_type, Type *original_type_for_poly) {
	GB_ASSERT(is_type_struct(struct_type));
	ast_node(st, StructType, node);

	String context = str_lit("struct");

	isize min_field_count = 0;
	for_array(field_index, st->fields) {
	AstNode *field = st->fields[field_index];
		switch (field->kind) {
		case_ast_node(f, ValueDecl, field);
			min_field_count += f->names.count;
		case_end;
		}
	}
	struct_type->Struct.names = make_names_field_for_struct(c, c->context.scope);

	if (st->is_raw_union) {
		struct_type->Struct.is_raw_union = true;
		context = str_lit("struct #raw_union");
	}

	Type *polymorphic_params     = nullptr;
	bool is_polymorphic          = false;
	bool can_check_fields        = true;
	bool is_poly_specialized     = false;

	if (st->polymorphic_params != nullptr) {
		ast_node(field_list, FieldList, st->polymorphic_params);
		Array<AstNode *> params = field_list->list;
		if (params.count != 0) {
			isize variable_count = 0;
			for_array(i, params) {
				AstNode *field = params[i];
				if (ast_node_expect(field, AstNode_Field)) {
					ast_node(f, Field, field);
					variable_count += gb_max(f->names.count, 1);
				}
			}

			Array<Entity *> entities = {};
			array_init(&entities, c->allocator, variable_count);

			for_array(i, params) {
				AstNode *param = params[i];
				if (param->kind != AstNode_Field) {
					continue;
				}
				ast_node(p, Field, param);
				AstNode *type_expr = p->type;
				Type *type = nullptr;
				bool is_type_param = false;
				bool is_type_polymorphic_type = false;
				if (type_expr == nullptr) {
					error(param, "Expected a type for this parameter");
					continue;
				}
				if (type_expr->kind == AstNode_Ellipsis) {
					type_expr = type_expr->Ellipsis.expr;
					error(param, "A polymorphic parameter cannot be variadic");
				}
				if (type_expr->kind == AstNode_TypeType) {
					is_type_param = true;
					Type *specialization = nullptr;
					if (type_expr->TypeType.specialization != nullptr) {
						AstNode *s = type_expr->TypeType.specialization;
						specialization = check_type(c, s);
						if (false && !is_type_polymorphic_struct(specialization)) {
							gbString str = type_to_string(specialization);
							defer (gb_string_free(str));
							error(s, "Expected a polymorphic struct, got %s", str);
							specialization = nullptr;
						}
					}
					type = make_type_generic(c->allocator, c->context.scope, 0, str_lit(""), specialization);
				} else {
					type = check_type(c, type_expr);
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

				Scope *scope = c->context.scope;
				for_array(j, p->names) {
					AstNode *name = p->names[j];
					if (!ast_node_expect(name, AstNode_Ident)) {
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
							e = make_entity_type_name(c->allocator, scope, token, operand.type);
							e->TypeName.is_type_alias = true;
						} else {
							GB_ASSERT(operand.mode == Addressing_Constant);
							e = make_entity_constant(c->allocator, scope, token, operand.type, operand.value);
						}
					} else {
						if (is_type_param) {
							e = make_entity_type_name(c->allocator, scope, token, type);
							e->TypeName.is_type_alias = true;
						} else {
							e = make_entity_constant(c->allocator, scope, token, type, empty_exact_value);
						}
					}

					add_entity(c, scope, name, e);
					array_add(&entities, e);
				}
			}

			if (entities.count > 0) {
				Type *tuple = make_type_tuple(c->allocator);
				tuple->Tuple.variables = entities;
				polymorphic_params = tuple;
			}
		}

		if (original_type_for_poly != nullptr) {
			GB_ASSERT(named_type != nullptr);
			add_polymorphic_struct_entity(c, node, named_type, original_type_for_poly);
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
		}
	}

	struct_type->Struct.scope                   = c->context.scope;
	struct_type->Struct.is_packed               = st->is_packed;
	struct_type->Struct.polymorphic_params      = polymorphic_params;
	struct_type->Struct.is_polymorphic          = is_polymorphic;
	struct_type->Struct.is_poly_specialized     = is_poly_specialized;

	Array<Entity *> fields = {};

	if (!is_polymorphic) {
		fields = check_struct_fields(c, node, st->fields, min_field_count, named_type, context);
	}

	struct_type->Struct.fields              = fields;
	struct_type->Struct.fields_in_src_order = fields;

	for_array(i, fields) {
		Entity *f = fields[i];
		if (f->kind == Entity_Variable) {
			if (f->Variable.default_value.kind == ExactValue_Procedure) {
				struct_type->Struct.has_proc_default_values = true;
				break;
			}
		}
	}


#if 0
	// TODO(bill): Move this to the appropriate place
	if (!struct_type->Struct.is_raw_union) {
		type_set_offsets(c->allocator, struct_type);

		if (!struct_type->failure && !st->is_packed && !st->is_ordered) {
			struct_type->failure = false;
			struct_type->Struct.are_offsets_set = false;
			struct_type->Struct.are_offsets_being_processed = false;
			gb_zero_item(&struct_type->Struct.offsets);
			// NOTE(bill): Reorder fields for reduced size/performance

			Array<Entity *> reordered_fields = {};
			array_init_count(&reordered_fields, c->allocator, fields.count);
			for_array(i, reordered_fields) {
				reordered_fields[i] = struct_type->Struct.fields_in_src_order[i];
			}

			// NOTE(bill): Hacky thing
			// TODO(bill): Probably make an inline sorting procedure rather than use global variables
			// NOTE(bill): compound literal order must match source not layout
			gb_sort_array(reordered_fields.data, fields.count, cmp_reorder_struct_fields);

			for_array(i, fields) {
				reordered_fields[i]->Variable.field_index = cast(i32)i;
			}

			struct_type->Struct.fields = reordered_fields;
		}

		type_set_offsets(c->allocator, struct_type);
	}
#endif

	if (st->align != nullptr) {
		if (st->is_packed) {
			syntax_error(st->align, "'#align' cannot be applied with '#packed'");
			return;
		}
		i64 custom_align = 1;
		if (check_custom_align(c, st->align, &custom_align)) {
			struct_type->Struct.custom_align = custom_align;
		}
	}
}
void check_union_type(Checker *c, Type *union_type, AstNode *node) {
	GB_ASSERT(is_type_union(union_type));
	ast_node(ut, UnionType, node);

	isize variant_count = ut->variants.count;

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	Entity *using_index_expr = nullptr;

	Array<Type *> variants = {};
	array_init(&variants, c->allocator, variant_count);

	union_type->Union.scope = c->context.scope;

	for_array(i, ut->variants) {
		AstNode *node = ut->variants[i];
		Type *t = check_type(c, node);
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

	if (ut->align != nullptr) {
		i64 custom_align = 1;
		if (check_custom_align(c, ut->align, &custom_align)) {
			if (variants.count == 0) {
				error(ut->align, "An empty union cannot have a custom alignment");
			} else {
				union_type->Union.custom_align = custom_align;
			}
		}
	}
}

void check_enum_type(Checker *c, Type *enum_type, Type *named_type, AstNode *node) {
	ast_node(et, EnumType, node);
	GB_ASSERT(is_type_enum(enum_type));

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	Type *base_type = t_int;
	if (et->base_type != nullptr) {
		base_type = check_type(c, et->base_type);
	}

	if (base_type == nullptr || !(is_type_integer(base_type) || is_type_float(base_type))) {
		error(node, "Base type for enumeration must be numeric");
		return;
	}
	if (is_type_enum(base_type)) {
		error(node, "Base type for enumeration cannot be another enumeration");
		return;
	}

	// NOTE(bill): Must be up here for the 'check_init_constant' system
	enum_type->Enum.base_type = base_type;
	enum_type->Enum.scope = c->context.scope;

	Map<Entity *> entity_map = {}; // Key: String
	map_init(&entity_map, c->tmp_allocator, 2*(et->fields.count));

	Array<Entity *> fields = {};
	array_init(&fields, c->allocator, et->fields.count);

	Type *constant_type = enum_type;
	if (named_type != nullptr) {
		constant_type = named_type;
	}

	ExactValue iota = exact_value_i64(-1);
	ExactValue min_value = exact_value_i64(0);
	ExactValue max_value = exact_value_i64(0);

	for_array(i, et->fields) {
		AstNode *field = et->fields[i];
		AstNode *ident = nullptr;
		AstNode *init = nullptr;
		if (field->kind == AstNode_FieldValue) {
			ast_node(fv, FieldValue, field);
			if (fv->field == nullptr || fv->field->kind != AstNode_Ident) {
				error(field, "An enum field's name must be an identifier");
				continue;
			}
			ident = fv->field;
			init = fv->value;
		} else if (field->kind == AstNode_Ident) {
			ident = field;
		} else {
			error(field, "An enum field's name must be an identifier");
			continue;
		}
		String name = ident->Ident.token.string;

		if (init != nullptr) {
			Operand o = {};
			check_expr(c, &o, init);
			if (o.mode != Addressing_Constant) {
				error(init, "Enumeration value must be a constant");
				o.mode = Addressing_Invalid;
			}
			if (o.mode != Addressing_Invalid) {
				check_assignment(c, &o, constant_type, str_lit("enumeration"));
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
		} else if (name == "count") {
			error(field, "'count' is a reserved identifier for enumerations");
			continue;
		} else if (name == "min_value") {
			error(field, "'min_value' is a reserved identifier for enumerations");
			continue;
		} else if (name == "max_value") {
			error(field, "'max_value' is a reserved identifier for enumerations");
			continue;
		} else if (name == "names") {
			error(field, "'names' is a reserved identifier for enumerations");
			continue;
		}/*  else if (name == "base_type") {
			error(field, "'base_type' is a reserved identifier for enumerations");
			continue;
		} */

		if (compare_exact_values(Token_Gt, min_value, iota)) {
			min_value = iota;
		}
		if (compare_exact_values(Token_Lt, max_value, iota)) {
			max_value = iota;
		}

		Entity *e = make_entity_constant(c->allocator, c->context.scope, ident->Ident.token, constant_type, iota);
		e->identifier = ident;
		e->flags |= EntityFlag_Visited;

		HashKey key = hash_string(name);
		if (map_get(&entity_map, key) != nullptr) {
			error(ident, "'%.*s' is already declared in this enumeration", LIT(name));
		} else {
			map_set(&entity_map, key, e);
			add_entity(c, c->context.scope, nullptr, e);
			array_add(&fields, e);
			add_entity_use(c, field, e);
		}
	}
	GB_ASSERT(fields.count <= et->fields.count);


	enum_type->Enum.fields      = fields.data;
	enum_type->Enum.field_count = cast(i32)fields.count;

	enum_type->Enum.count = make_entity_constant(c->allocator, c->context.scope,
		make_token_ident(str_lit("count")), t_int, exact_value_i64(fields.count));
	enum_type->Enum.min_value = make_entity_constant(c->allocator, c->context.scope,
		make_token_ident(str_lit("min_value")), constant_type, min_value);
	enum_type->Enum.max_value = make_entity_constant(c->allocator, c->context.scope,
		make_token_ident(str_lit("max_value")), constant_type, max_value);

	enum_type->Enum.names = make_names_field_for_struct(c, c->context.scope);
}


void check_bit_field_type(Checker *c, Type *bit_field_type, AstNode *node) {
	ast_node(bft, BitFieldType, node);
	GB_ASSERT(is_type_bit_field(bit_field_type));

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	defer (gb_temp_arena_memory_end(tmp));

	Map<Entity *> entity_map = {}; // Key: String
	map_init(&entity_map, c->tmp_allocator, 2*(bft->fields.count));

	isize field_count = 0;
	Entity **fields  = gb_alloc_array(c->allocator, Entity *, bft->fields.count);
	u32 *    sizes   = gb_alloc_array(c->allocator, u32,      bft->fields.count);
	u32 *    offsets = gb_alloc_array(c->allocator, u32,      bft->fields.count);

	u32 curr_offset = 0;
	for_array(i, bft->fields) {
		AstNode *field = bft->fields[i];
		GB_ASSERT(field->kind == AstNode_FieldValue);
		AstNode *ident = field->FieldValue.field;
		AstNode *value = field->FieldValue.value;

		if (ident->kind != AstNode_Ident) {
			error(field, "A bit field value's name must be an identifier");
			continue;
		}
		String name = ident->Ident.token.string;

		Operand o = {};
		check_expr(c, &o, value);
		if (o.mode != Addressing_Constant) {
			error(value, "Bit field bit size must be a constant");
			continue;
		}
		ExactValue v = exact_value_to_integer(o.value);
		if (v.kind != ExactValue_Integer) {
			error(value, "Bit field bit size must be a constant integer");
			continue;
		}
		i64 bits = i128_to_i64(v.value_integer);
		if (bits < 0 || bits > 128) {
			error(value, "Bit field's bit size must be within the range 1..<128, got %lld", cast(long long)bits);
			continue;
		}

		Type *value_type = make_type_bit_field_value(c->allocator, cast(i32)bits);
		Entity *e = make_entity_variable(c->allocator, bit_field_type->BitField.scope, ident->Ident.token, value_type, false);
		e->identifier = ident;
		e->flags |= EntityFlag_BitFieldValue;

		HashKey key = hash_string(name);
		if (!is_blank_ident(name) &&
		    map_get(&entity_map, key) != nullptr) {
			error(ident, "'%.*s' is already declared in this bit field", LIT(name));
		} else {
			map_set(&entity_map, key, e);
			add_entity(c, c->context.scope, nullptr, e);
			add_entity_use(c, field, e);

			fields [field_count] = e;
			offsets[field_count] = curr_offset;
			sizes  [field_count] = cast(i32)bits;
			field_count++;

			curr_offset += cast(i32)bits;
		}
	}
	GB_ASSERT(field_count <= bft->fields.count);

	bit_field_type->BitField.fields      = fields;
	bit_field_type->BitField.field_count = cast(i32)field_count;
	bit_field_type->BitField.sizes       = sizes;
	bit_field_type->BitField.offsets     = offsets;


	if (bft->align != nullptr) {
		i64 custom_align = 1;
		if (check_custom_align(c, bft->align, &custom_align)) {
			bit_field_type->BitField.custom_align = custom_align;
		}
	}
}


bool check_type_specialization_to(Checker *c, Type *specialization, Type *type, bool compound, bool modify_type) {
	if (type == nullptr ||
	    type == t_invalid) {
		return true;
	}

	Type *t = base_type(type);
	Type *s = base_type(specialization);
	if (t->kind != s->kind) {
		return false;
	}
	// gb_printf_err("#1 %s %s\n", type_to_string(type), type_to_string(specialization));
	if (t->kind == Type_Struct) {
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
				bool ok = is_polymorphic_type_assignable(c, st, tt, true, modify_type);
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
	if (is_polymorphic_type_assignable(c, base_type(specialization), base_type(type), compound, modify_type)) {
		return true;
	}

	return false;
}


Type *determine_type_from_polymorphic(Checker *c, Type *poly_type, Operand operand) {
	bool modify_type = !c->context.no_polymorphic_errors;
	if (!is_operand_value(operand)) {
		if (modify_type) {
			error(operand.expr, "Cannot determine polymorphic type from parameter");
		}
		return t_invalid;
	}
	if (is_polymorphic_type_assignable(c, poly_type, operand.type, false, modify_type)) {
		return poly_type;
	}
	if (modify_type) {
		gbString pts = type_to_string(poly_type);
		gbString ots = type_to_string(operand.type);
		defer (gb_string_free(pts));
		defer (gb_string_free(ots));
		error(operand.expr, "Cannot determine polymorphic type from parameter: '%s' to '%s'", ots, pts);
	}
	return t_invalid;
}


Type *check_get_params(Checker *c, Scope *scope, AstNode *_params, bool *is_variadic_, isize *variadic_index_, bool *success_, isize *specialization_count_, Array<Operand> *operands) {
	if (_params == nullptr) {
		return nullptr;
	}

	bool allow_polymorphic_types = c->context.allow_polymorphic_types;

	bool success = true;
	ast_node(field_list, FieldList, _params);
	Array<AstNode *> params = field_list->list;

	if (params.count == 0) {
		if (success_) *success_ = success;
		return nullptr;
	}



	isize variable_count = 0;
	for_array(i, params) {
		AstNode *field = params[i];
		if (ast_node_expect(field, AstNode_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}
	isize min_variable_count = variable_count;
	for (isize i = params.count-1; i >= 0; i--) {
		AstNode *field = params[i];
		if (field->kind == AstNode_Field) {
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
	Array<Entity *> variables = {};
	array_init(&variables, c->allocator, variable_count);
	for_array(i, params) {
		AstNode *param = params[i];
		if (param->kind != AstNode_Field) {
			continue;
		}
		ast_node(p, Field, param);
		AstNode *type_expr = p->type;
		Type *type = nullptr;
		AstNode *default_value = unparen_expr(p->default_value);
		ExactValue value = {};
		bool default_is_nil = false;
		bool default_is_location = false;
		bool is_type_param = false;
		bool is_type_polymorphic_type = false;
		bool detemine_type_from_operand = false;
		Type *specialization = nullptr;

		bool is_using = (p->flags&FieldFlag_using) != 0;

		if (type_expr == nullptr) {
			if (default_value->kind == AstNode_BasicDirective &&
			    default_value->BasicDirective.name == "caller_location") {
				init_preload(c);
				default_is_location = true;
				type = t_source_code_location;
			} else {
				Operand o = {};
				check_expr_or_type(c, &o, default_value);
				if (is_operand_nil(o)) {
					default_is_nil = true;
				} else if (o.mode != Addressing_Constant) {
					if (default_value->kind == AstNode_ProcLit) {
						value = exact_value_procedure(default_value);
					} else {
						Entity *e = nullptr;
						if (o.mode == Addressing_Value && is_type_proc(o.type)) {
							Operand x = {};
							if (default_value->kind == AstNode_Ident) {
								e = check_ident(c, &x, default_value, nullptr, nullptr, false);
							} else if (default_value->kind == AstNode_SelectorExpr) {
								e = check_selector(c, &x, default_value, nullptr);
							}
						}

						if (e != nullptr && e->kind == Entity_Procedure) {
							value = exact_value_procedure(e->identifier);
							add_entity_use(c, e->identifier, e);
						} else {
							error(default_value, "Default parameter must be a constant");
							continue;
						}
					}
				} else {
					value = o.value;
				}

				type = default_type(o.type);
			}
		} else {
			if (type_expr->kind == AstNode_Ellipsis) {
				type_expr = type_expr->Ellipsis.expr;
				#if 1
					is_variadic = true;
					variadic_index = variables.count;
					if (p->names.count != 1) {
						error(param, "Invalid AST: Invalid variadic parameter with multiple names");
						success = false;
					}
				#else
				if (i+1 == params.count) {
					is_variadic = true;
				} else {
					error(param, "Invalid AST: Invalid variadic parameter");
					success = false;
				}
				#endif
			}
			if (type_expr->kind == AstNode_TypeType) {
				ast_node(tt, TypeType, type_expr);
				is_type_param = true;
				specialization = check_type(c, tt->specialization);
				if (specialization == t_invalid){
					specialization = nullptr;
				}
				// if (specialization) {
				// 	if (!is_type_polymorphic(specialization)) {
				// 		gbString str = type_to_string(specialization);
				// 		error(tt->specialization, "Type specialization requires a polymorphic type, got %s", str);
				// 		gb_string_free(str);
				// 	}
				// }

				if (operands != nullptr) {
					detemine_type_from_operand = true;
					type = t_invalid;
				} else {
					type = make_type_generic(c->allocator, c->context.scope, 0, str_lit(""), specialization);
				}
			} else {
				bool prev = c->context.allow_polymorphic_types;
				if (operands != nullptr) {
					c->context.allow_polymorphic_types = true;
				}
				type = check_type(c, type_expr);

				c->context.allow_polymorphic_types = prev;

				if (is_type_polymorphic(type)) {
					is_type_polymorphic_type = true;
				}
			}

			if (default_value != nullptr) {
				if (type_expr->kind == AstNode_TypeType) {
					error(default_value, "A type parameter may not have a default value");
					continue;
				} else {
					Operand o = {};
					if (default_value->kind == AstNode_BasicDirective &&
					    default_value->BasicDirective.name == "caller_location") {
						init_preload(c);
						default_is_location = true;
						o.type = t_source_code_location;
						o.mode = Addressing_Value;
					} else {
						check_expr_with_type_hint(c, &o, default_value, type);

						if (is_operand_nil(o)) {
							default_is_nil = true;
						} else if (o.mode != Addressing_Constant) {
							if (default_value->kind == AstNode_ProcLit) {
								value = exact_value_procedure(default_value);
							} else {
								Entity *e = nullptr;
								if (o.mode == Addressing_Value && is_type_proc(o.type)) {
									Operand x = {};
									if (default_value->kind == AstNode_Ident) {
										e = check_ident(c, &x, default_value, nullptr, nullptr, false);
									} else if (default_value->kind == AstNode_SelectorExpr) {
										e = check_selector(c, &x, default_value, nullptr);
									}
								}

								if (e != nullptr && e->kind == Entity_Procedure) {
									value = exact_value_procedure(e->identifier);
									add_entity_use(c, e->identifier, e);
								} else {
									error(default_value, "Default parameter must be a constant");
								}
							}
						} else {
							value = o.value;
						}
					}

					check_is_assignable_to(c, &o, type);
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
			    p->type->kind != AstNode_Ellipsis) {
				error(param, "'#c_vararg' can only be applied to variadic type fields");
				p->flags &= ~FieldFlag_c_vararg; // Remove the flag
			} else {
				is_c_vararg = true;
			}
		}

		for_array(j, p->names) {
			AstNode *name = p->names[j];
			if (!ast_node_expect(name, AstNode_Ident)) {
				continue;
			}

			Entity *param = nullptr;
			if (is_type_param) {
				if (operands != nullptr) {
					Operand o = (*operands)[variables.count];
					if (o.mode == Addressing_Type) {
						type = o.type;
					} else {
						if (!c->context.no_polymorphic_errors) {
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
					bool modify_type = !c->context.no_polymorphic_errors;

					if (specialization != nullptr && !check_type_specialization_to(c, specialization, type, false, modify_type)) {
						if (!c->context.no_polymorphic_errors) {
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
				param = make_entity_type_name(c->allocator, scope, name->Ident.token, type);
				param->TypeName.is_type_alias = true;
			} else {
				if (operands != nullptr && variables.count < operands->count) {
					if (is_type_polymorphic_type) {
						Operand op = (*operands)[variables.count];
						type = determine_type_from_polymorphic(c, type, op);
						if (type == t_invalid) {
							success = false;
						} else if (!c->context.no_polymorphic_errors) {
							// NOTE(bill): The type should be determined now and thus, no need to determine the type any more
							is_type_polymorphic_type = false;
						}
					}
				}

				if (p->flags&FieldFlag_no_alias) {
					if (!is_type_pointer(type)) {
						error(name, "'#no_alias' can only be applied to fields of pointer type");
						p->flags &= ~FieldFlag_no_alias; // Remove the flag
					}
				}

				param = make_entity_param(c->allocator, scope, name->Ident.token, type, is_using, false);
				param->Variable.default_value = value;
				param->Variable.default_is_nil = default_is_nil;
				param->Variable.default_is_location = default_is_location;
			}
			if (p->flags&FieldFlag_no_alias) {
				param->flags |= EntityFlag_NoAlias;
			}

			add_entity(c, scope, name, param);
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
		end->type = make_type_slice(c->allocator, end->type);
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

	Type *tuple = make_type_tuple(c->allocator);
	tuple->Tuple.variables = variables;

	if (success_) *success_ = success;
	if (specialization_count_) *specialization_count_ = specialization_count;
	if (is_variadic_) *is_variadic_ = is_variadic;
	if (variadic_index_) *variadic_index_ = variadic_index;

	return tuple;
}

Type *check_get_results(Checker *c, Scope *scope, AstNode *_results) {
	if (_results == nullptr) {
		return nullptr;
	}
	ast_node(field_list, FieldList, _results);
	Array<AstNode *> results = field_list->list;

	if (results.count == 0) {
		return nullptr;
	}
	Type *tuple = make_type_tuple(c->allocator);

	isize variable_count = 0;
	for_array(i, results) {
		AstNode *field = results[i];
		if (ast_node_expect(field, AstNode_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}

	Array<Entity *> variables = {};
	array_init(&variables, c->allocator, variable_count);
	for_array(i, results) {
		ast_node(field, Field, results[i]);
		AstNode *default_value = unparen_expr(field->default_value);
		ExactValue value = {};
		bool default_is_nil = false;

		Type *type = nullptr;
		if (field->type == nullptr) {
			Operand o = {};
			check_expr(c, &o, default_value);
			if (is_operand_nil(o)) {
				default_is_nil = true;
			} else if (o.mode != Addressing_Constant) {
				error(default_value, "Default parameter must be a constant");
			} else {
				value = o.value;
			}

			type = default_type(o.type);
		} else {
			type = check_type(c, field->type);

			if (default_value != nullptr) {
				Operand o = {};
				check_expr_with_type_hint(c, &o, default_value, type);

				if (is_operand_nil(o)) {
					default_is_nil = true;
				} else if (o.mode != Addressing_Constant) {
					error(default_value, "Default parameter must be a constant");
				} else {
					value = o.value;
				}
				check_is_assignable_to(c, &o, type);
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
			Token token = ast_node_token(field->type);
			token.string = str_lit("");
			Entity *param = make_entity_param(c->allocator, scope, token, type, false, false);
			param->Variable.default_value = value;
			param->Variable.default_is_nil = default_is_nil;
			array_add(&variables, param);
		} else {
			for_array(j, field->names) {
				Token token = ast_node_token(results[i]);
				if (field->type != nullptr) {
					token = ast_node_token(field->type);
				}
				token.string = str_lit("");

				AstNode *name = field->names[j];
				if (name->kind != AstNode_Ident) {
					error(name, "Expected an identifer for as the field name");
				} else {
					token = name->Ident.token;
				}

				Entity *param = make_entity_param(c->allocator, scope, token, type, false, false);
				param->Variable.default_value = value;
				param->Variable.default_is_nil = default_is_nil;
				array_add(&variables, param);
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

Type *type_to_abi_compat_param_type(gbAllocator a, Type *original_type) {
	Type *new_type = original_type;

	if (build_context.ODIN_ARCH == "x86") {
		return new_type;
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
				new_type = make_type_pointer(a, original_type);
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
			i64 align = type_align_of(a, original_type);
			i64 size  = type_size_of(a, original_type);
			switch (8*size) {
			case 8:  new_type = t_u8;  break;
			case 16: new_type = t_u16; break;
			case 32: new_type = t_u32; break;
			case 64: new_type = t_u64; break;
			default:
				new_type = make_type_pointer(a, original_type);
				break;
			}

			break;
		}
		}
	} else if (build_context.ODIN_OS == "linux" ||
	           build_context.ODIN_OS == "osx") {
		Type *bt = core_type(original_type);
		switch (bt->kind) {
		// Okay to pass by value (usually)
		// Especially the only Odin types
		case Type_Basic: {
			i64 sz = bt->Basic.size;
			// if (sz > 8 && build_context.word_size < 8) {
			if (sz > 8) {
				new_type = make_type_pointer(a, original_type);
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
		case Type_Struct: {
			i64 align = type_align_of(a, original_type);
			i64 size  = type_size_of(a, original_type);
			if (8*size > 16) {
				new_type = make_type_pointer(a, original_type);
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

Type *type_to_abi_compat_result_type(gbAllocator a, Type *original_type) {
	Type *new_type = original_type;
	if (new_type == nullptr) {
		return nullptr;
	}
	GB_ASSERT(is_type_tuple(original_type));



	if (build_context.ODIN_OS == "windows") {
		Type *bt = core_type(reduce_tuple_to_single_type(original_type));
		// NOTE(bill): This is just reversed engineered from LLVM IR output
		switch (bt->kind) {
		// Okay to pass by value
		// Especially the only Odin types
		case Type_Pointer: break;
		case Type_Proc:    break; // NOTE(bill): Just a pointer
		case Type_Basic:   break;


		default: {
			i64 align = type_align_of(a, original_type);
			i64 size  = type_size_of(a, original_type);
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
	} else if (build_context.ODIN_OS == "linux") {

	} else {
		// IMPORTANT TODO(bill): figure out the ABI settings for Linux, OSX etc. for
		// their architectures
	}

	if (new_type != original_type) {
		Type *tuple = make_type_tuple(a);
		Array<Entity *> variables = {};
		array_init(&variables, a, 1);
		array_add(&variables, make_entity_param(a, original_type->Tuple.variables[0]->scope, empty_token, new_type, false, false));
		tuple->Tuple.variables = variables;
		new_type = tuple;
	}


	// return reduce_tuple_to_single_type(new_type);
	return new_type;
}

bool abi_compat_return_by_value(gbAllocator a, ProcCallingConvention cc, Type *abi_return_type) {
	if (abi_return_type == nullptr) {
		return false;
	}
	switch (cc) {
	case ProcCC_Odin:
	case ProcCC_Contextless:
		return false;
	}


	if (build_context.ODIN_OS == "windows") {
		i64 size = 8*type_size_of(a, abi_return_type);
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
	}
	return false;
}

// NOTE(bill): 'operands' is for generating non generic procedure type
bool check_procedure_type(Checker *c, Type *type, AstNode *proc_type_node, Array<Operand> *operands) {
	ast_node(pt, ProcType, proc_type_node);

	if (c->context.polymorphic_scope == nullptr && c->context.allow_polymorphic_types) {
		c->context.polymorphic_scope = c->context.scope;
	}

	bool variadic = false;
	isize variadic_index = -1;
	bool success = true;
	isize specialization_count = 0;
	Type *params  = check_get_params(c, c->context.scope, pt->params, &variadic, &variadic_index, &success, &specialization_count, operands);
	Type *results = check_get_results(c, c->context.scope, pt->results);


	isize param_count = 0;
	isize result_count = 0;
	if (params)  param_count  = params ->Tuple.variables.count;
	if (results) result_count = results->Tuple.variables.count;

	if (param_count > 0) {
		for_array(i, params->Tuple.variables) {
			Entity *param = params->Tuple.variables[i];
			if (param->kind == Entity_Variable && param->Variable.default_value.kind == ExactValue_Procedure) {
				type->Proc.has_proc_default_values = true;
				break;
			}
		}
	}

	ProcCallingConvention cc = pt->calling_convention;
	if (cc == ProcCC_ForeignBlockDefault) {
		cc = ProcCC_CDecl;
		if (c->context.foreign_context.default_cc > 0) {
			cc = c->context.foreign_context.default_cc;
		}
	}
	GB_ASSERT(cc > 0);

	type->Proc.node                 = proc_type_node;
	type->Proc.scope                = c->context.scope;
	type->Proc.params               = params;
	type->Proc.param_count          = cast(i32)param_count;
	type->Proc.results              = results;
	type->Proc.result_count         = cast(i32)result_count;
	type->Proc.variadic             = variadic;
	type->Proc.variadic_index       = variadic_index;
	type->Proc.calling_convention   = cc;
	type->Proc.is_polymorphic       = pt->generic;
	type->Proc.specialization_count = specialization_count;

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
	type->Proc.is_polymorphic = is_polymorphic;


	type->Proc.abi_compat_params = gb_alloc_array(c->allocator, Type *, param_count);
	for (isize i = 0; i < param_count; i++) {
		Entity *e = type->Proc.params->Tuple.variables[i];
		if (e->kind == Entity_Variable) {
			Type *original_type = e->type;
			Type *new_type = type_to_abi_compat_param_type(c->allocator, original_type);
			type->Proc.abi_compat_params[i] = new_type;
		}
	}

	// NOTE(bill): The types are the same
	type->Proc.abi_compat_result_type = type_to_abi_compat_result_type(c->allocator, type->Proc.results);
	type->Proc.return_by_pointer = abi_compat_return_by_value(c->allocator, pt->calling_convention, type->Proc.abi_compat_result_type);

	return success;
}


i64 check_array_count(Checker *c, Operand *o, AstNode *e) {
	if (e == nullptr) {
		return 0;
	}
	if (e->kind == AstNode_UnaryExpr &&
	    e->UnaryExpr.op.kind == Token_Ellipsis) {
		return -1;
	}

	check_expr_or_type(c, o, e);
	if (o->mode == Addressing_Type && o->type->kind == Type_Generic) {
		if (c->context.allow_polymorphic_types) {
			if (o->type->Generic.specialized) {
				o->type->Generic.specialized = nullptr;
				error(o->expr, "Polymorphic array length cannot have a specialization");
			}
			return 0;
		}
	}
	if (o->mode != Addressing_Constant) {
		if (o->mode != Addressing_Invalid) {
			o->mode = Addressing_Invalid;
			error(e, "Array count must be a constant");
		}
		return 0;
	}
	Type *type = base_type(o->type);
	if (is_type_untyped(type) || is_type_integer(type)) {
		if (o->value.kind == ExactValue_Integer) {
			i64 count = i128_to_i64(o->value.value_integer);
			if (count >= 0) {
				return count;
			}
			error(e, "Invalid negative array count %lld", cast(long long)count);
			return 0;
		}
	}

	error(e, "Array count must be an integer");
	return 0;
}

Type *make_optional_ok_type(gbAllocator a, Type *value) {
	bool typed = true;
	Type *t = make_type_tuple(a);
	array_init(&t->Tuple.variables, a, 2);
	array_add (&t->Tuple.variables, make_entity_field(a, nullptr, blank_token, value,  false, 0));
	array_add (&t->Tuple.variables, make_entity_field(a, nullptr, blank_token, typed ? t_bool : t_untyped_bool, false, 1));
	return t;
}

void generate_map_entry_type(gbAllocator a, Type *type) {
	GB_ASSERT(type->kind == Type_Map);
	if (type->Map.entry_type != nullptr) return;

	// NOTE(bill): The preload types may have not been set yet
	GB_ASSERT(t_map_key != nullptr);

	Type *entry_type = make_type_struct(a);

	/*
	struct {
		hash:  __MapKey;
		next:  int;
		key:   Key;
		value: Value;
	}
	*/
	AstNode *dummy_node = gb_alloc_item(a, AstNode);
	dummy_node->kind = AstNode_Invalid;
	Scope *s = create_scope(universal_scope, a);

	isize field_count = 3;
	Array<Entity *> fields = {};
	array_init(&fields, a, 3);
	array_add(&fields, make_entity_field(a, s, make_token_ident(str_lit("key")),   t_map_key,       false, 0));
	array_add(&fields, make_entity_field(a, s, make_token_ident(str_lit("next")),  t_int,           false, 1));
	array_add(&fields, make_entity_field(a, s, make_token_ident(str_lit("value")), type->Map.value, false, 2));


	entry_type->Struct.fields              = fields;
	entry_type->Struct.fields_in_src_order = fields;

	// type_set_offsets(a, entry_type);
	type->Map.entry_type = entry_type;
}

void generate_map_internal_types(gbAllocator a, Type *type) {
	GB_ASSERT(type->kind == Type_Map);
	generate_map_entry_type(a, type);
	if (type->Map.generated_struct_type != nullptr) return;
	Type *key   = type->Map.key;
	Type *value = type->Map.value;
	GB_ASSERT(key != nullptr);
	GB_ASSERT(value != nullptr);

	Type *generated_struct_type = make_type_struct(a);

	/*
	struct {
		hashes:  [dynamic]int;
		entries: [dynamic]EntryType;
	}
	*/
	AstNode *dummy_node = gb_alloc_item(a, AstNode);
	dummy_node->kind = AstNode_Invalid;
	Scope *s = create_scope(universal_scope, a);

	Type *hashes_type  = make_type_dynamic_array(a, t_int);
	Type *entries_type = make_type_dynamic_array(a, type->Map.entry_type);


	Array<Entity *> fields = {};
	array_init(&fields, a, 2);
	array_add(&fields, make_entity_field(a, s, make_token_ident(str_lit("hashes")),  hashes_type,  false, 0));
	array_add(&fields, make_entity_field(a, s, make_token_ident(str_lit("entries")), entries_type, false, 1));

	generated_struct_type->Struct.fields              = fields;
	generated_struct_type->Struct.fields_in_src_order = fields;

	type_set_offsets(a, generated_struct_type);
	type->Map.generated_struct_type = generated_struct_type;
	type->Map.internal_type         = make_type_pointer(a, generated_struct_type);
	type->Map.lookup_result_type    = make_optional_ok_type(a, value);
}

void check_map_type(Checker *c, Type *type, AstNode *node) {
	GB_ASSERT(type->kind == Type_Map);
	ast_node(mt, MapType, node);

	Type *key   = check_type(c, mt->key);
	Type *value = check_type(c, mt->value);

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


	init_preload(c);
	generate_map_internal_types(c->allocator, type);

	// error(node, "'map' types are not yet implemented");
}

bool check_type_internal(Checker *c, AstNode *e, Type **type, Type *named_type) {
	GB_ASSERT_NOT_NULL(type);
	if (e == nullptr) {
		*type = t_invalid;
		return true;
	}

	switch (e->kind) {
	case_ast_node(i, Ident, e);

		Operand o = {};
		check_ident(c, &o, e, named_type, nullptr, false);

		gbString err_str;
		switch (o.mode) {
		case Addressing_Invalid:
			break;
		case Addressing_Type:
			*type = o.type;
			return true;

		case Addressing_NoValue:
			err_str = expr_to_string(e);
			error(e, "'%s' used as a type", err_str);
			gb_string_free(err_str);
			break;

		default:
			err_str = expr_to_string(e);
			error(e, "'%s' used as a type when not a type", err_str);
			gb_string_free(err_str);
			break;
		}
	case_end;

	case_ast_node(ht, HelperType, e);
		return check_type_internal(c, ht->type, type, named_type);
	case_end;

	case_ast_node(at, AliasType, e);
		error(e, "Invalid use of '#alias'");
		// NOTE(bill): Treat it as a HelperType to remove errors
		return check_type_internal(c, at->type, type, named_type);
	case_end;

	case_ast_node(pt, PolyType, e);
		AstNode *ident = pt->type;
		if (ident->kind != AstNode_Ident) {
			error(ident, "Expected an identifier after the $");
			*type = t_invalid;
			return false;
		}

		Token token = ident->Ident.token;
		Type *specific = nullptr;
		if (pt->specialization != nullptr) {
			AstNode *s = pt->specialization;
			specific = check_type(c, s);
			if (false && !is_type_polymorphic_struct(specific)) {
				gbString str = type_to_string(specific);
				error(s, "Expected a polymorphic struct, got %s", str);
				gb_string_free(str);
				specific = nullptr;
			}
		}
		Type *t = make_type_generic(c->allocator, c->context.scope, 0, token.string, specific);
		if (c->context.allow_polymorphic_types) {
			Scope *ps = c->context.polymorphic_scope;
			Scope *s = c->context.scope;
			Scope *entity_scope = s;
			if (ps != nullptr && ps != s) {
				GB_ASSERT(is_scope_an_ancestor(ps, s) >= 0);
				entity_scope = ps;
			}
			Entity *e = make_entity_type_name(c->allocator, entity_scope, token, t);
			e->TypeName.is_type_alias = true;
			add_entity(c, ps, ident, e);
			add_entity(c, s, ident, e);
		} else {
			error(ident, "Invalid use of a polymorphic parameter '$%.*s'", LIT(token.string));
			*type = t_invalid;
			return false;
		}
		*type = t;
		return true;
	case_end;

	case_ast_node(se, SelectorExpr, e);
		Operand o = {};
		check_selector(c, &o, e, nullptr);

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
		*type = check_type(c, pe->expr, named_type);
		return true;
	case_end;

	case_ast_node(ue, UnaryExpr, e);
		if (ue->op.kind == Token_Pointer) {
			*type = make_type_pointer(c->allocator, check_type(c, ue->expr));
			return true;
		} /* else if (ue->op.kind == Token_Maybe) {
			*type = make_type_maybe(c->allocator, check_type(c, ue->expr));
			return true;
		} */
	case_end;

	case_ast_node(pt, PointerType, e);
		*type = make_type_pointer(c->allocator, check_type(c, pt->type));
		return true;
	case_end;

	case_ast_node(at, ArrayType, e);
		if (at->count != nullptr) {
			Operand o = {};
			i64 count = check_array_count(c, &o, at->count);
			Type *generic_type = nullptr;
			if (o.mode == Addressing_Type && o.type->kind == Type_Generic) {
				generic_type = o.type;
			}
			if (count < 0) {
				error(at->count, "... can only be used in conjuction with compound literals");
				count = 0;
			}
			Type *elem = check_type(c, at->elem, nullptr);
			*type = make_type_array(c->allocator, elem, count, generic_type);
		} else {
			Type *elem = check_type(c, at->elem);
			*type = make_type_slice(c->allocator, elem);
		}
		return true;
	case_end;

	case_ast_node(dat, DynamicArrayType, e);
		Type *elem = check_type(c, dat->elem);
		*type = make_type_dynamic_array(c->allocator, elem);
		return true;
	case_end;

	case_ast_node(st, StructType, e);
		*type = make_type_struct(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_struct_type(c, *type, e, nullptr, named_type);
		check_close_scope(c);
		(*type)->Struct.node = e;
		return true;
	case_end;

	case_ast_node(ut, UnionType, e);
		*type = make_type_union(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_union_type(c, *type, e);
		check_close_scope(c);
		(*type)->Union.node = e;
		return true;
	case_end;

	case_ast_node(et, EnumType, e);
		*type = make_type_enum(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_enum_type(c, *type, named_type, e);
		check_close_scope(c);
		(*type)->Enum.node = e;
		return true;
	case_end;

	case_ast_node(et, BitFieldType, e);
		*type = make_type_bit_field(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_bit_field_type(c, *type, e);
		check_close_scope(c);
		return true;
	case_end;

	case_ast_node(pt, ProcType, e);
		*type = alloc_type(c->allocator, Type_Proc);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_procedure_type(c, *type, e);
		check_close_scope(c);
		return true;
	case_end;

	case_ast_node(mt, MapType, e);
		*type = alloc_type(c->allocator, Type_Map);
		set_base_type(named_type, *type);
		check_map_type(c, *type, e);
		return true;
	case_end;

	case_ast_node(ce, CallExpr, e);
		Operand o = {};
		check_expr_or_type(c, &o, e);
		if (o.mode == Addressing_Type) {
			*type = o.type;
			return true;
		}
	case_end;

	case_ast_node(te, TernaryExpr, e);
		Operand o = {};
		check_expr_or_type(c, &o, e);
		if (o.mode == Addressing_Type) {
			*type = o.type;
			return true;
		}
	case_end;
	}

	*type = t_invalid;
	return false;
}



Type *check_type(Checker *c, AstNode *e, Type *named_type) {
	Type *type = nullptr;
	bool ok = check_type_internal(c, e, &type, named_type);

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

	#if 0
	if (!c->context.allow_polymorphic_types && is_type_polymorphic(type)) {
		gbString str = type_to_string(type);
		error(e, "Invalid use of a polymorphic type '%s'", str);
		gb_string_free(str);
		type = t_invalid;
	}
	#endif

	if (is_type_typed(type)) {
		add_type_and_value(&c->info, e, Addressing_Type, type, empty_exact_value);
	} else {
		gbString name = type_to_string(type);
		error(e, "Invalid type definition of %s", name);
		gb_string_free(name);
		type = t_invalid;
	}
	set_base_type(named_type, type);

	return type;
}
