void     check_expr                     (Checker *c, Operand *operand, AstNode *expression);
void     check_multi_expr               (Checker *c, Operand *operand, AstNode *expression);
void     check_expr_or_type             (Checker *c, Operand *operand, AstNode *expression);
ExprKind check_expr_base                (Checker *c, Operand *operand, AstNode *expression, Type *type_hint);
void     check_expr_with_type_hint      (Checker *c, Operand *o, AstNode *e, Type *t);
Type *   check_type                     (Checker *c, AstNode *expression, Type *named_type = NULL);
void     check_type_decl                (Checker *c, Entity *e, AstNode *type_expr, Type *def);
Entity * check_selector                 (Checker *c, Operand *operand, AstNode *node, Type *type_hint);
void     check_not_tuple                (Checker *c, Operand *operand);
void     convert_to_typed               (Checker *c, Operand *operand, Type *target_type, i32 level);
gbString expr_to_string                 (AstNode *expression);
void     check_entity_decl              (Checker *c, Entity *e, DeclInfo *decl, Type *named_type);
void     check_const_decl               (Checker *c, Entity *e, AstNode *type_expr, AstNode *init_expr, Type *named_type);
void     check_proc_body                (Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body);
void     update_expr_type               (Checker *c, AstNode *e, Type *type, bool final);
bool     check_is_terminating           (AstNode *node);
bool     check_has_break                (AstNode *stmt, bool implicit);
void     check_stmt                     (Checker *c, AstNode *node, u32 flags);
void     check_stmt_list                (Checker *c, Array<AstNode *> stmts, u32 flags);
void     check_init_constant            (Checker *c, Entity *e, Operand *operand);
bool     check_representable_as_constant(Checker *c, ExactValue in_value, Type *type, ExactValue *out_value);
Type *   check_call_arguments           (Checker *c, Operand *operand, Type *proc_type, AstNode *call);


void error_operand_not_expression(Operand *o) {
	if (o->mode == Addressing_Type) {
		gbString err = expr_to_string(o->expr);
		error(o->expr, "`%s` is not an expression but a type", err);
		gb_string_free(err);
		o->mode = Addressing_Invalid;
	}
}

void error_operand_no_value(Operand *o) {
	if (o->mode == Addressing_NoValue) {
		gbString err = expr_to_string(o->expr);
		error(o->expr, "`%s` used as value", err);
		gb_string_free(err);
		o->mode = Addressing_Invalid;
	}
}


void check_scope_decls(Checker *c, Array<AstNode *> nodes, isize reserve_size) {
	Scope *s = c->context.scope;
	GB_ASSERT(!s->is_file);

	check_collect_entities(c, nodes, false);

	for_array(i, s->elements.entries) {
		Entity *e = s->elements.entries[i].value;
		switch (e->kind) {
		case Entity_Constant:
		case Entity_TypeName:
		case Entity_Procedure:
			break;
		default:
			continue;
		}
		DeclInfo *d = decl_info_of_entity(&c->info, e);
		if (d != NULL) {
			check_entity_decl(c, e, d, NULL);
		}
	}

	for_array(i, s->elements.entries) {
		Entity *e = s->elements.entries[i].value;
		if (e->kind != Entity_Procedure) {
			continue;
		}
		check_procedure_overloading(c, e);
	}
}


bool check_is_assignable_to_using_subtype(Type *src, Type *dst) {
	bool src_is_ptr = false;
	Type *prev_src = src;
	src = type_deref(src);
	src_is_ptr = src != prev_src;
	src = base_type(src);

	if (!is_type_struct(src) && !is_type_union(src)) {
		return false;
	}

	for (isize i = 0; i < src->Record.field_count; i++) {
		Entity *f = src->Record.fields[i];
		if (f->kind != Entity_Variable || (f->flags&EntityFlag_Using) == 0) {
			continue;
		}

		if (are_types_identical(f->type, dst)) {
			return true;
		}
		if (src_is_ptr && is_type_pointer(dst)) {
			if (are_types_identical(f->type, type_deref(dst))) {
				return true;
			}
		}
		bool ok = check_is_assignable_to_using_subtype(f->type, dst);
		if (ok) {
			return true;
		}
	}

	return false;
}


// IMPORTANT TODO(bill): figure out the exact distance rules
// -1 is not convertable
// 0 is exact
// >0 is convertable

i64 check_distance_between_types(Checker *c, Operand *operand, Type *type) {
	if (operand->mode == Addressing_Invalid ||
	    type == t_invalid) {
		return 0;
	}

	if (operand->mode == Addressing_Builtin) {
		return -1;
	}

	Type *s = operand->type;

	if (are_types_identical(s, type)) {
		return 0;
	}

	Type *src = base_type(s);
	Type *dst = base_type(type);

	if (is_type_untyped_nil(src)) {
		if (type_has_nil(dst)) {
			return 1;
		}
		return -1;
	}
	if (is_type_untyped(src)) {
		if (is_type_any(dst)) {
			// NOTE(bill): Anything can cast to `Any`
			add_type_info_type(c, s);
			return 10;
		}
		if (dst->kind == Type_Basic) {
			if (operand->mode == Addressing_Constant) {
				if (check_representable_as_constant(c, operand->value, dst, NULL)) {
					if (is_type_typed(dst) && src->kind == Type_Basic) {
						switch (src->Basic.kind) {
						case Basic_UntypedInteger:
							if (is_type_integer(dst) || is_type_rune(dst)) {
								return 1;
							}
							break;
						case Basic_UntypedFloat:
							if (is_type_float(dst)) {
								return 1;
							}
							break;
						case Basic_UntypedComplex:
							if (is_type_complex(dst)) {
								return 1;
							}
							break;
						}
					}
					return 2;
				}
				return -1;
			}
			if (src->kind == Type_Basic && src->Basic.kind == Basic_UntypedBool) {
				if (is_type_boolean(dst)) {
					if (is_type_typed(type)) {
						return 2;
					}
					return 1;
				}
				return -1;
			}
		}
	}

	if (are_types_identical(dst, src) && (!is_type_named(dst) || !is_type_named(src))) {
		return 1;
	}


	if (is_type_bit_field_value(operand->type) && is_type_integer(type)) {
		Type *bfv = base_type(operand->type);
		i32 bits = bfv->BitFieldValue.bits;
		i32 size = next_pow2((bits+7)/8);
		i32 dst_size = type_size_of(c->allocator, type);
		i32 diff = gb_abs(dst_size - size);
		// TODO(bill): figure out a decent rule here
		return 1;
	}


	if (check_is_assignable_to_using_subtype(operand->type, type)) {
		return 4;
	}

	// ^T <- rawptr
#if 0
	// TODO(bill): Should C-style (not C++) pointer cast be allowed?
	if (is_type_pointer(dst) && is_type_rawptr(src)) {
	    return true;
	}
#endif
#if 1


	// TODO(bill): Should I allow this implicit conversion at all?!
	// rawptr <- ^T
	if (are_types_identical(type, t_rawptr) && is_type_pointer(src)) {
	    return 5;
	}
#endif

	if (is_type_union(dst)) {
		for (isize i = 0; i < dst->Record.variant_count; i++) {
			Entity *f = dst->Record.variants[i];
			if (are_types_identical(f->type, s)) {
				return 1;
			}
		}
	}

	if (is_type_proc(dst)) {
		if (are_types_identical(src, dst)) {
			return 3;
		}
	}

	if (is_type_vector(dst)) {
		Type *elem = base_vector_type(dst);
		i64 distance = check_distance_between_types(c, operand, elem);
		if (distance >= 0) {
			return distance + 5;
		}
	}


	if (is_type_any(dst)) {
		// NOTE(bill): Anything can cast to `Any`
		add_type_info_type(c, s);
		return 10;
	}



	return -1;
}


i64 assign_score_function(i64 distance) {
	// TODO(bill): A decent score function
	return gb_max(1000000 - distance*distance, 0);
}


bool check_is_assignable_to_with_score(Checker *c, Operand *operand, Type *type, i64 *score_) {
	i64 score = 0;
	i64 distance = check_distance_between_types(c, operand, type);
	bool ok = distance >= 0;
	if (ok) {
		score = assign_score_function(distance);
	}
	if (score_) *score_ = score;
	return ok;
}


bool check_is_assignable_to(Checker *c, Operand *operand, Type *type) {
	i64 score = 0;
	return check_is_assignable_to_with_score(c, operand, type, &score);
}


// NOTE(bill): `content_name` is for debugging and error messages
void check_assignment(Checker *c, Operand *operand, Type *type, String context_name) {
	check_not_tuple(c, operand);
	if (operand->mode == Addressing_Invalid) {
		return;
	}

	if (is_type_untyped(operand->type)) {
		Type *target_type = type;
		if (type == NULL || is_type_any(type)) {
			if (type == NULL && is_type_untyped_nil(operand->type)) {
				error(operand->expr, "Use of untyped nil in %.*s", LIT(context_name));
				operand->mode = Addressing_Invalid;
				return;
			}
			target_type = default_type(operand->type);
			if (type != NULL && !is_type_any(type)) {
				GB_ASSERT_MSG(is_type_typed(target_type), "%s", type_to_string(type));
			}
			add_type_info_type(c, type);
			add_type_info_type(c, target_type);
		}

		if (target_type != NULL && is_type_vector(target_type)) {
			// NOTE(bill): continue to below
		} else {
			convert_to_typed(c, operand, target_type, 0);
			if (operand->mode == Addressing_Invalid) {
				return;
			}
		}
	}

	if (type == NULL) {
		return;
	}

	if (!check_is_assignable_to(c, operand, type)) {
		gbString type_str    = type_to_string(type);
		gbString op_type_str = type_to_string(operand->type);
		gbString expr_str    = expr_to_string(operand->expr);

		if (operand->mode == Addressing_Builtin) {
			// TODO(bill): is this a good enough error message?
			// TODO(bill): Actually allow built in procedures to be passed around and thus be created on use
			error(operand->expr,
			           "Cannot assign built-in procedure `%s` in %.*s",
			           expr_str,
			           LIT(context_name));
		} else {
			// TODO(bill): is this a good enough error message?
			error(operand->expr,
			           "Cannot assign value `%s` of type `%s` to `%s` in %.*s",
			           expr_str,
			           op_type_str,
			           type_str,
			           LIT(context_name));
		}
		operand->mode = Addressing_Invalid;

		gb_string_free(expr_str);
		gb_string_free(op_type_str);
		gb_string_free(type_str);
		return;
	}
}


void populate_using_entity_map(Checker *c, AstNode *node, Type *t, Map<Entity *> *entity_map) {
	t = base_type(type_deref(t));
	gbString str = NULL;
	if (node != NULL) {
		expr_to_string(node);
	}

	if (t->kind == Type_Record) {
		for (isize i = 0; i < t->Record.field_count; i++) {
			Entity *f = t->Record.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			String name = f->token.string;
			HashKey key = hash_string(name);
			Entity **found = map_get(entity_map, key);
			if (found != NULL) {
				Entity *e = *found;
				// TODO(bill): Better type error
				if (str != NULL) {
					error(e->token, "`%.*s` is already declared in `%s`", LIT(name), str);
				} else {
					error(e->token, "`%.*s` is already declared`", LIT(name));
				}
			} else {
				map_set(entity_map, key, f);
				add_entity(c, c->context.scope, NULL, f);
				if (f->flags & EntityFlag_Using) {
					populate_using_entity_map(c, node, f->type, entity_map);
				}
			}
		}
	}

	gb_string_free(str);
}


// Returns filled field_count
isize check_fields(Checker *c, AstNode *node, Array<AstNode *> decls,
                   Entity **fields, isize field_count,
                   String context) {
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);

	Map<Entity *> entity_map = {};
	map_init_with_reserve(&entity_map, c->tmp_allocator, 2*field_count);

	Entity *using_index_expr = NULL;

	if (node != NULL) {
		GB_ASSERT(node->kind != AstNode_UnionType);
	}

	isize field_index = 0;
	for_array(decl_index, decls) {
		AstNode *decl = decls[decl_index];
		if (decl->kind != AstNode_Field) {
			continue;
		}
		ast_node(f, Field, decl);

		Type *type = check_type(c, f->type);
		bool is_using = (f->flags&FieldFlag_using) != 0;

		if (is_using) {
			if (f->names.count > 1) {
				error(f->names[0], "Cannot apply `using` to more than one of the same type");
				is_using = false;
			}
		}

		for_array(name_index, f->names) {
			AstNode *name = f->names[name_index];
			if (!ast_node_expect(name, AstNode_Ident)) {
				continue;
			}

			Token name_token = name->Ident;

			Entity *e = make_entity_field(c->allocator, c->context.scope, name_token, type, is_using, cast(i32)field_index);
			e->identifier = name;
			if (name_token.string == "_") {
				fields[field_index++] = e;
			} else if (name_token.string == "__tag") {
				error(name, "`__tag` is a reserved identifier for fields");
			} else {
				HashKey key = hash_string(name_token.string);
				Entity **found = map_get(&entity_map, key);
				if (found != NULL) {
					Entity *e = *found;
					// NOTE(bill): Scope checking already checks the declaration but in many cases, this can happen so why not?
					// This may be a little janky but it's not really that much of a problem
					error(name_token, "`%.*s` is already declared in this type", LIT(name_token.string));
					error(e->token,   "\tpreviously declared");
				} else {
					map_set(&entity_map, key, e);
					fields[field_index++] = e;
					add_entity(c, c->context.scope, name, e);
				}
				add_entity_use(c, name, e);
			}
		}


		if (is_using) {
			Type *t = base_type(type_deref(type));
			if (!is_type_struct(t) && !is_type_raw_union(t) && !is_type_bit_field(t) &&
			    f->names.count >= 1 &&
			    f->names[0]->kind == AstNode_Ident) {
				Token name_token = f->names[0]->Ident;
				if (is_type_indexable(t)) {
					bool ok = true;
					for_array(emi, entity_map.entries) {
						Entity *e = entity_map.entries[emi].value;
						if (e->kind == Entity_Variable && e->flags & EntityFlag_Using) {
							if (is_type_indexable(e->type)) {
								if (e->identifier != f->names[0]) {
									ok = false;
									using_index_expr = e;
									break;
								}
							}
						}
					}
					if (ok) {
						using_index_expr = fields[field_index-1];
					} else {
						fields[field_index-1]->flags &= ~EntityFlag_Using;
						error(name_token, "Previous `using` for an index expression `%.*s`", LIT(name_token.string));
					}
				} else {
					gbString type_str = type_to_string(type);
					error(name_token, "`using` cannot be applied to the field `%.*s` of type `%s`", LIT(name_token.string), type_str);
					gb_string_free(type_str);
					continue;
				}
			}

			populate_using_entity_map(c, node, type, &entity_map);
		}
	}

	gb_temp_arena_memory_end(tmp);

	return field_index;
}


// TODO(bill): Cleanup struct field reordering
// TODO(bill): Inline sorting procedure?
gb_global gbAllocator   __checker_allocator = {};

GB_COMPARE_PROC(cmp_reorder_struct_fields) {
	// Rule:
	// `using` over non-`using`
	// Biggest to smallest alignment
	// if same alignment: biggest to smallest size
	// if same size: order by source order
	Entity *x = *(Entity **)a;
	Entity *y = *(Entity **)b;
	GB_ASSERT(x != NULL);
	GB_ASSERT(y != NULL);
	GB_ASSERT(x->kind == Entity_Variable);
	GB_ASSERT(y->kind == Entity_Variable);
	bool xu = (x->flags & EntityFlag_Using) != 0;
	bool yu = (y->flags & EntityFlag_Using) != 0;
	i64 xa = type_align_of(__checker_allocator, x->type);
	i64 ya = type_align_of(__checker_allocator, y->type);
	i64 xs = type_size_of(__checker_allocator, x->type);
	i64 ys = type_size_of(__checker_allocator, y->type);

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

Entity *make_names_field_for_record(Checker *c, Scope *scope) {
	Entity *e = make_entity_field(c->allocator, scope,
		make_token_ident(str_lit("names")), t_string_slice, false, 0);
	e->Variable.is_immutable = true;
	e->flags |= EntityFlag_TypeField;
	return e;
}

void check_struct_type(Checker *c, Type *struct_type, AstNode *node) {
	GB_ASSERT(is_type_struct(struct_type));
	ast_node(st, StructType, node);

	isize field_count = 0;
	for_array(field_index, st->fields) {
	AstNode *field = st->fields[field_index];
		switch (field->kind) {
		case_ast_node(f, Field, field);
			field_count += f->names.count;
		case_end;
		}
	}

	Entity **fields = gb_alloc_array(c->allocator, Entity *, field_count);

	field_count = check_fields(c, node, st->fields, fields, field_count, str_lit("struct"));

	struct_type->Record.is_packed           = st->is_packed;
	struct_type->Record.is_ordered          = st->is_ordered;
	struct_type->Record.fields              = fields;
	struct_type->Record.fields_in_src_order = fields;
	struct_type->Record.field_count         = field_count;
	struct_type->Record.names = make_names_field_for_record(c, c->context.scope);

	type_set_offsets(c->allocator, struct_type);


	if (!struct_type->failure && !st->is_packed && !st->is_ordered) {
		struct_type->failure = false;
		struct_type->Record.are_offsets_set = false;
		struct_type->Record.offsets = NULL;
		// NOTE(bill): Reorder fields for reduced size/performance

		Entity **reordered_fields = gb_alloc_array(c->allocator, Entity *, field_count);
		for (isize i = 0; i < field_count; i++) {
			reordered_fields[i] = struct_type->Record.fields_in_src_order[i];
		}

		// NOTE(bill): Hacky thing
		// TODO(bill): Probably make an inline sorting procedure rather than use global variables
		__checker_allocator = c->allocator;
		// NOTE(bill): compound literal order must match source not layout
		gb_sort_array(reordered_fields, field_count, cmp_reorder_struct_fields);

		for (isize i = 0; i < field_count; i++) {
			reordered_fields[i]->Variable.field_index = i;
		}

		struct_type->Record.fields = reordered_fields;
	}

	type_set_offsets(c->allocator, struct_type);


	if (st->align != NULL) {
		if (st->is_packed) {
			syntax_error(st->align, "`#align` cannot be applied with `#packed`");
			return;
		}

		Operand o = {};
		check_expr(c, &o, st->align);
		if (o.mode != Addressing_Constant) {
			if (o.mode != Addressing_Invalid) {
				error(st->align, "#align must be a constant");
			}
			return;
		}

		Type *type = base_type(o.type);
		if (is_type_untyped(type) || is_type_integer(type)) {
			if (o.value.kind == ExactValue_Integer) {
				i64 align = i128_to_i64(o.value.value_integer);
				if (align < 1 || !gb_is_power_of_two(align)) {
					error(st->align, "#align must be a power of 2, got %lld", align);
					return;
				}

				// NOTE(bill): Success!!!
				i64 custom_align = gb_clamp(align, 1, build_context.max_align);
				if (custom_align < align) {
					warning(st->align, "Custom alignment has been clamped to %lld from %lld", align, custom_align);
				}
				struct_type->Record.custom_align = custom_align;
				return;
			}
		}

		error(st->align, "#align must be an integer");
		return;
	}


}
void check_union_type(Checker *c, Type *named_type, Type *union_type, AstNode *node) {
	GB_ASSERT(is_type_union(union_type));
	ast_node(ut, UnionType, node);

	isize variant_count = ut->variants.count+1;
	isize field_count = 0;
	for_array(i, ut->fields) {
		AstNode *field = ut->fields[i];
		if (field->kind == AstNode_Field) {
			ast_node(f, Field, field);
			field_count += f->names.count;
		}
	}

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);

	Map<Entity *> entity_map = {}; // Key: String
	map_init_with_reserve(&entity_map, c->tmp_allocator, 2*variant_count);

	Entity *using_index_expr = NULL;

	Entity **variants = gb_alloc_array(c->allocator, Entity *, variant_count);
	Entity **fields = gb_alloc_array(c->allocator, Entity *, field_count);

	isize variant_index = 0;
	variants[variant_index++] = make_entity_type_name(c->allocator, c->context.scope, empty_token, NULL);

	field_count = check_fields(c, NULL, ut->fields, fields, field_count, str_lit("union"));

	for (isize i = 0; i < field_count; i++) {
		Entity *f = fields[i];
		String name = f->token.string;
		map_set(&entity_map, hash_string(name), f);
	}

	union_type->Record.fields              = fields;
	union_type->Record.fields_in_src_order = fields;
	union_type->Record.field_count         = field_count;
	union_type->Record.are_offsets_set     = false;
	union_type->Record.is_ordered          = true;
	{
		Entity *__tag = make_entity_field(c->allocator, NULL, make_token_ident(str_lit("__tag")), t_int, false, -1);
		union_type->Record.union__tag = __tag;
	}

	for_array(i, ut->variants) {
		AstNode *variant = ut->variants[i];
		if (variant->kind != AstNode_UnionField) {
			continue;
		}
		ast_node(f, UnionField, variant);
		Token name_token = f->name->Ident;

		Type *base_type = make_type_struct(c->allocator);
		{
			ast_node(fl, FieldList, f->list);

			// NOTE(bill): Copy the contents for the common fields for now
			Array<AstNode *> list = {};
			array_init_count(&list, c->allocator, ut->fields.count+fl->list.count);
			gb_memmove_array(list.data, ut->fields.data, ut->fields.count);
			gb_memmove_array(list.data+ut->fields.count, fl->list.data, fl->list.count);

			isize list_count = 0;
			for_array(j, list) {
				ast_node(f, Field, list[j]);
				list_count += f->names.count;
			}


			Token token = name_token;
			token.kind = Token_struct;
			AstNode *dummy_struct = ast_struct_type(c->curr_ast_file, token, list, list_count, false, true, NULL);

			check_open_scope(c, dummy_struct);
			Entity **fields = gb_alloc_array(c->allocator, Entity *, list_count);
			isize field_count = check_fields(c, dummy_struct, list, fields, list_count, str_lit("variant"));
			base_type->Record.is_packed           = false;
			base_type->Record.is_ordered          = true;
			base_type->Record.fields              = fields;
			base_type->Record.fields_in_src_order = fields;
			base_type->Record.field_count         = field_count;
			base_type->Record.names = make_names_field_for_record(c, c->context.scope);
			base_type->Record.node = dummy_struct;
			base_type->Record.variant_parent = named_type != NULL ? named_type : union_type;
			base_type->Record.variant_index = variant_index;


			type_set_offsets(c->allocator, base_type);

			check_close_scope(c);
		}

		Type *type = make_type_named(c->allocator, name_token.string, base_type, NULL);
		Entity *e = make_entity_type_name(c->allocator, c->context.scope, name_token, type);
		type->Named.type_name = e;
		add_entity(c, c->context.scope, f->name, e);

		if (name_token.string == "_") {
			error(name_token, "`_` cannot be used a union subtype");
			continue;
		}

		HashKey key = hash_string(name_token.string);
		if (map_get(&entity_map, key) != NULL) {
			// NOTE(bill): Scope checking already checks the declaration
			error(name_token, "`%.*s` is already declared in this union", LIT(name_token.string));
		} else {
			map_set(&entity_map, key, e);
			variants[variant_index++] = e;
		}
		add_entity_use(c, f->name, e);
	}

	type_set_offsets(c->allocator, union_type);

	gb_temp_arena_memory_end(tmp);

	union_type->Record.variants      = variants;
	union_type->Record.variant_count = variant_index;
}

void check_raw_union_type(Checker *c, Type *union_type, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_RawUnionType);
	GB_ASSERT(is_type_raw_union(union_type));
	ast_node(ut, RawUnionType, node);

	isize field_count = 0;
	for_array(field_index, ut->fields) {
		AstNode *field = ut->fields[field_index];
		switch (field->kind) {
		case_ast_node(f, Field, field);
			field_count += f->names.count;
		case_end;
		}
	}

	Entity **fields = gb_alloc_array(c->allocator, Entity *, field_count);

	field_count = check_fields(c, node, ut->fields, fields, field_count, str_lit("raw_union"));

	union_type->Record.fields = fields;
	union_type->Record.field_count = field_count;
	union_type->Record.names = make_names_field_for_record(c, c->context.scope);
}


void check_enum_type(Checker *c, Type *enum_type, Type *named_type, AstNode *node) {
	ast_node(et, EnumType, node);
	GB_ASSERT(is_type_enum(enum_type));

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);

	Type *base_type = t_int;
	if (et->base_type != NULL) {
		base_type = check_type(c, et->base_type);
	}

	if (base_type == NULL || !(is_type_integer(base_type) || is_type_float(base_type))) {
		error(node, "Base type for enumeration must be numeric");
		return;
	}
	if (is_type_enum(base_type)) {
		error(node, "Base type for enumeration cannot be another enumeration");
		return;
	}

	// NOTE(bill): Must be up here for the `check_init_constant` system
	enum_type->Record.enum_base_type = base_type;

	Map<Entity *> entity_map = {}; // Key: String
	map_init_with_reserve(&entity_map, c->tmp_allocator, 2*(et->fields.count));

	Entity **fields = gb_alloc_array(c->allocator, Entity *, et->fields.count);
	isize field_count = 0;

	Type *constant_type = enum_type;
	if (named_type != NULL) {
		constant_type = named_type;
	}

	ExactValue iota = exact_value_i64(-1);
	ExactValue min_value = exact_value_i64(0);
	ExactValue max_value = exact_value_i64(0);

	for_array(i, et->fields) {
		AstNode *field = et->fields[i];
		AstNode *ident = NULL;
		AstNode *init = NULL;
		if (field->kind == AstNode_FieldValue) {
			ast_node(fv, FieldValue, field);
			if (fv->field == NULL || fv->field->kind != AstNode_Ident) {
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
		String name = ident->Ident.string;

		if (init != NULL) {
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
		if (name == "_") {
			continue;
		} else if (name == "count") {
			error(field, "`count` is a reserved identifier for enumerations");
			continue;
		} else if (name == "min_value") {
			error(field, "`min_value` is a reserved identifier for enumerations");
			continue;
		} else if (name == "max_value") {
			error(field, "`max_value` is a reserved identifier for enumerations");
			continue;
		} else if (name == "names") {
			error(field, "`names` is a reserved identifier for enumerations");
			continue;
		}/*  else if (name == "base_type") {
			error(field, "`base_type` is a reserved identifier for enumerations");
			continue;
		} */

		if (compare_exact_values(Token_Gt, min_value, iota)) {
			min_value = iota;
		}
		if (compare_exact_values(Token_Lt, max_value, iota)) {
			max_value = iota;
		}

		Entity *e = make_entity_constant(c->allocator, c->context.scope, ident->Ident, constant_type, iota);
		e->identifier = ident;
		e->flags |= EntityFlag_Visited;

		HashKey key = hash_string(name);
		if (map_get(&entity_map, key) != NULL) {
			error(ident, "`%.*s` is already declared in this enumeration", LIT(name));
		} else {
			map_set(&entity_map, key, e);
			add_entity(c, c->context.scope, NULL, e);
			fields[field_count++] = e;
			add_entity_use(c, field, e);
		}
	}
	GB_ASSERT(field_count <= et->fields.count);
	gb_temp_arena_memory_end(tmp);


	enum_type->Record.fields = fields;
	enum_type->Record.field_count = field_count;

	enum_type->Record.enum_count = make_entity_constant(c->allocator, c->context.scope,
		make_token_ident(str_lit("count")), t_int, exact_value_i64(field_count));
	enum_type->Record.enum_min_value = make_entity_constant(c->allocator, c->context.scope,
		make_token_ident(str_lit("min_value")), constant_type, min_value);
	enum_type->Record.enum_max_value = make_entity_constant(c->allocator, c->context.scope,
		make_token_ident(str_lit("max_value")), constant_type, max_value);

	enum_type->Record.names = make_names_field_for_record(c, c->context.scope);
}


void check_bit_field_type(Checker *c, Type *bit_field_type, Type *named_type, AstNode *node) {
	ast_node(bft, BitFieldType, node);
	GB_ASSERT(is_type_bit_field(bit_field_type));

	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);


	Map<Entity *> entity_map = {}; // Key: String
	map_init_with_reserve(&entity_map, c->tmp_allocator, 2*(bft->fields.count));

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
		String name = ident->Ident.string;

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

		Type *value_type = make_type_bit_field_value(c->allocator, bits);
		Entity *e = make_entity_variable(c->allocator, bit_field_type->BitField.scope, ident->Ident, value_type, false);
		e->identifier = ident;
		e->flags |= EntityFlag_BitFieldValue;

		HashKey key = hash_string(name);
		if (name != "_" &&
		    map_get(&entity_map, key) != NULL) {
			error(ident, "`%.*s` is already declared in this bit field", LIT(name));
		} else {
			map_set(&entity_map, key, e);
			add_entity(c, c->context.scope, NULL, e);
			add_entity_use(c, field, e);

			fields [field_count] = e;
			offsets[field_count] = curr_offset;
			sizes  [field_count] = bits;
			field_count++;

			curr_offset += bits;
		}
	}
	GB_ASSERT(field_count <= bft->fields.count);
	gb_temp_arena_memory_end(tmp);

	bit_field_type->BitField.fields      = fields;
	bit_field_type->BitField.field_count = field_count;
	bit_field_type->BitField.sizes       = sizes;
	bit_field_type->BitField.offsets     = offsets;


	if (bft->align != NULL) {
		Operand o = {};
		check_expr(c, &o, bft->align);
		if (o.mode != Addressing_Constant) {
			if (o.mode != Addressing_Invalid) {
				error(bft->align, "#align must be a constant");
			}
			return;
		}

		Type *type = base_type(o.type);
		if (is_type_untyped(type) || is_type_integer(type)) {
			if (o.value.kind == ExactValue_Integer) {
				i64 align = i128_to_i64(o.value.value_integer);
				if (align < 1 || !gb_is_power_of_two(align)) {
					error(bft->align, "#align must be a power of 2, got %lld", align);
					return;
				}

				// NOTE(bill): Success!!!
				i64 custom_align = gb_clamp(align, 1, build_context.max_align);
				if (custom_align < align) {
					warning(bft->align, "Custom alignment has been clamped to %lld from %lld", align, custom_align);
				}
				bit_field_type->BitField.custom_align = custom_align;
				return;
			}
		}

		error(bft->align, "#align must be an integer");
		return;
	}
}




Type *check_get_params(Checker *c, Scope *scope, AstNode *_params, bool *is_variadic_) {
	if (_params == NULL) {
		return NULL;
	}
	ast_node(field_list, FieldList, _params);
	Array<AstNode *> params = field_list->list;

	if (params.count == 0) {
		return NULL;
	}

	isize variable_count = 0;
	for_array(i, params) {
		AstNode *field = params[i];
		if (ast_node_expect(field, AstNode_Field)) {
			ast_node(f, Field, field);
			variable_count += gb_max(f->names.count, 1);
		}
	}

	bool is_variadic = false;
	bool is_c_vararg = false;
	Entity **variables = gb_alloc_array(c->allocator, Entity *, variable_count);
	isize variable_index = 0;
	for_array(i, params) {
		AstNode *param = params[i];
		if (param->kind != AstNode_Field) {
			continue;
		}
		ast_node(p, Field, param);
		AstNode *type_expr = p->type;
		Type *type = NULL;
		AstNode *default_value = unparen_expr(p->default_value);
		ExactValue value = {};
		bool default_is_nil = false;
		bool default_is_location = false;

		if (type_expr == NULL) {
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
					error(default_value, "Default parameter must be a constant");
				} else {
					value = o.value;
				}

				type = default_type(o.type);
			}
		} else {
			if (type_expr->kind == AstNode_Ellipsis) {
				type_expr = type_expr->Ellipsis.expr;
				if (i+1 == params.count) {
					is_variadic = true;
				} else {
					error(param, "Invalid AST: Invalid variadic parameter");
				}
			}
			if (type_expr->kind == AstNode_HelperType) {
				type = make_type_generic(c->allocator, 0);
			} else {
				type = check_type(c, type_expr);
			}

			if (default_value != NULL) {
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
						error(default_value, "Default parameter must be a constant");
					} else {
						value = o.value;
					}
				}

				check_is_assignable_to(c, &o, type);
			}

		}
		if (type == NULL) {
			error(params[i], "Invalid parameter type");
			type = t_invalid;
		}
		if (is_type_untyped(type)) {
			error(params[i], "Cannot determine parameter type from a nil");
			type = t_invalid;
		}

		if (p->flags&FieldFlag_no_alias) {
			if (!is_type_pointer(type)) {
				error(params[i], "`#no_alias` can only be applied to fields of pointer type");
				p->flags &= ~FieldFlag_no_alias; // Remove the flag
			}
		}
		if (p->flags&FieldFlag_c_vararg) {
			if (p->type == NULL ||
			    p->type->kind != AstNode_Ellipsis) {
				error(params[i], "`#c_vararg` can only be applied to variadic type fields");
				p->flags &= ~FieldFlag_c_vararg; // Remove the flag
			} else {
				is_c_vararg = true;
			}
		}

		for_array(j, p->names) {
			AstNode *name = p->names[j];
			if (ast_node_expect(name, AstNode_Ident)) {
				Entity *param = NULL;
				if (type->kind == Type_Generic) {
					param = make_entity_type_name(c->allocator, scope, name->Ident, type);
				} else {
					param = make_entity_param(c->allocator, scope, name->Ident, type,
					                          (p->flags&FieldFlag_using) != 0, false);
					param->Variable.default_value = value;
					param->Variable.default_is_nil = default_is_nil;
					param->Variable.default_is_location = default_is_location;
				}
				if (p->flags&FieldFlag_no_alias) {
					param->flags |= EntityFlag_NoAlias;
				}

				add_entity(c, scope, name, param);
				variables[variable_index++] = param;
			}
		}
	}

	variable_count = variable_index;

	if (is_variadic) {
		GB_ASSERT(params.count > 0);
		// NOTE(bill): Change last variadic parameter to be a slice
		// Custom Calling convention for variadic parameters
		Entity *end = variables[variable_count-1];
		end->type = make_type_slice(c->allocator, end->type);
		end->flags |= EntityFlag_Ellipsis;
		if (is_c_vararg) {
			end->flags |= EntityFlag_CVarArg;
		}
	}

	Type *tuple = make_type_tuple(c->allocator);
	tuple->Tuple.variables = variables;
	tuple->Tuple.variable_count = variable_count;

	if (is_variadic_) *is_variadic_ = is_variadic;

	return tuple;
}

Type *check_get_results(Checker *c, Scope *scope, AstNode *_results) {
	if (_results == NULL) {
		return NULL;
	}
	ast_node(field_list, FieldList, _results);
	Array<AstNode *> results = field_list->list;

	if (results.count == 0) {
		return NULL;
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

	Entity **variables = gb_alloc_array(c->allocator, Entity *, variable_count);
	isize variable_index = 0;
	for_array(i, results) {
		ast_node(field, Field, results[i]);
		AstNode *default_value = unparen_expr(field->default_value);
		ExactValue value = {};
		bool default_is_nil = false;

		Type *type = NULL;
		if (field->type == NULL) {
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

			if (default_value != NULL) {
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

		if (type == NULL) {
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
			variables[variable_index++] = param;
		} else {
			for_array(j, field->names) {
				Token token = ast_node_token(results[i]);
				if (field->type != NULL) {
					token = ast_node_token(field->type);
				}
				token.string = str_lit("");

				AstNode *name = field->names[j];
				if (name->kind != AstNode_Ident) {
					error(name, "Expected an identifer for as the field name");
				} else {
					token = name->Ident;
				}

				Entity *param = make_entity_param(c->allocator, scope, token, type, false, false);
				param->Variable.default_value = value;
				param->Variable.default_is_nil = default_is_nil;
				variables[variable_index++] = param;
			}
		}
	}

	for (isize i = 0; i < variable_index; i++) {
		String x = variables[i]->token.string;
		if (x.len == 0 || x == "_") {
			continue;
		}
		for (isize j = i+1; j < variable_index; j++) {
			String y = variables[j]->token.string;
			if (y.len == 0 || y == "_") {
				continue;
			}
			if (x == y) {
				error(variables[j]->token, "Duplicate return value name `%.*s`", LIT(y));
			}
		}
	}

	tuple->Tuple.variables = variables;
	tuple->Tuple.variable_count = variable_index;

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
			if (sz > 8 && build_context.word_size < 8) {
				new_type = make_type_pointer(a, original_type);
			}
		} break;
		case Type_Pointer: break;
		case Type_Proc:    break; // NOTE(bill): Just a pointer

		// Odin only types
		case Type_Slice:
		case Type_DynamicArray:
		case Type_Map:
			break;

		// Odin specific
		case Type_Array:
		case Type_Vector:
		// Could be in C too
		case Type_Record: {
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
		} break;
		}
	} else if (build_context.ODIN_OS == "linux" ||
	           build_context.ODIN_OS == "osx") {
		Type *bt = core_type(original_type);
		switch (bt->kind) {
		// Okay to pass by value (usually)
		// Especially the only Odin types
		case Type_Basic: {
			i64 sz = bt->Basic.size;
			if (sz > 8 && build_context.word_size < 8) {
				new_type = make_type_pointer(a, original_type);
			}
		} break;
		case Type_Pointer: break;
		case Type_Proc:    break; // NOTE(bill): Just a pointer

		// Odin only types
		case Type_Slice:
		case Type_DynamicArray:
		case Type_Map:
			break;

		// Odin specific
		case Type_Array:
		case Type_Vector:
		// Could be in C too
		case Type_Record: {
			i64 align = type_align_of(a, original_type);
			i64 size  = type_size_of(a, original_type);
			if (8*size > 16) {
				new_type = make_type_pointer(a, original_type);
			}
		} break;
		}
	} else {
		// IMPORTANT TODO(bill): figure out the ABI settings for Linux, OSX etc. for
		// their architectures
	}

	return new_type;
}

Type *reduce_tuple_to_single_type(Type *original_type) {
	if (original_type != NULL) {
		Type *t = core_type(original_type);
		if (t->kind == Type_Tuple && t->Tuple.variable_count == 1) {
			return t->Tuple.variables[0]->type;
		}
	}
	return original_type;
}

Type *type_to_abi_compat_result_type(gbAllocator a, Type *original_type) {
	Type *new_type = original_type;
	if (new_type == NULL) {
		return NULL;
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
		} break;
		}
	} else if (build_context.ODIN_OS == "linux") {

	} else {
		// IMPORTANT TODO(bill): figure out the ABI settings for Linux, OSX etc. for
		// their architectures
	}

	if (new_type != original_type) {
		Type *tuple = make_type_tuple(a);
		tuple->Tuple.variable_count = 1;
		tuple->Tuple.variables = gb_alloc_array(a, Entity *, 1);
		tuple->Tuple.variables[0] = make_entity_param(a, original_type->Tuple.variables[0]->scope, empty_token, new_type, false, false);
		new_type = tuple;
	}


	// return reduce_tuple_to_single_type(new_type);
	return new_type;
}

bool abi_compat_return_by_value(gbAllocator a, ProcCallingConvention cc, Type *abi_return_type) {
	if (abi_return_type == NULL) {
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

void check_procedure_type(Checker *c, Type *type, AstNode *proc_type_node) {
	ast_node(pt, ProcType, proc_type_node);

	bool variadic = false;
	Type *params  = check_get_params(c, c->context.scope, pt->params, &variadic);
	Type *results = check_get_results(c, c->context.scope, pt->results);

	isize param_count = 0;
	isize result_count = 0;
	if (params)  param_count  = params ->Tuple.variable_count;
	if (results) result_count = results->Tuple.variable_count;

	type->Proc.scope              = c->context.scope;
	type->Proc.params             = params;
	type->Proc.param_count        = param_count;
	type->Proc.results            = results;
	type->Proc.result_count       = result_count;
	type->Proc.variadic           = variadic;
	type->Proc.calling_convention = pt->calling_convention;
	type->Proc.is_generic         = pt->generic;

	if (param_count > 0) {
		Entity *end = params->Tuple.variables[param_count-1];
		if (end->flags&EntityFlag_CVarArg) {
			if (pt->calling_convention == ProcCC_Odin) {
				error(end->token, "Odin calling convention does not support #c_vararg");
			} else if (pt->calling_convention == ProcCC_Contextless) {
				error(end->token, "Odin's contextless calling convention does not support #c_vararg");
			} else if (pt->calling_convention == ProcCC_Fast) {
				error(end->token, "Fast calling convention does not support #c_vararg");
			} else {
				type->Proc.c_vararg = true;
			}
		}
	}


	bool is_generic = false;
	for (isize i = 0; i < param_count; i++) {
		Entity *e = params->Tuple.variables[i];
		if (e->type->kind == Type_Generic) {
			is_generic = true;
		}
	}
	GB_ASSERT(type->Proc.is_generic == is_generic);


	type->Proc.abi_compat_params = gb_alloc_array(c->allocator, Type *, param_count);
	for (isize i = 0; i < param_count; i++) {
		Type *original_type = type->Proc.params->Tuple.variables[i]->type;
		Type *new_type = type_to_abi_compat_param_type(c->allocator, original_type);
		type->Proc.abi_compat_params[i] = new_type;
	}

	// NOTE(bill): The types are the same
	type->Proc.abi_compat_result_type = type_to_abi_compat_result_type(c->allocator, type->Proc.results);
	type->Proc.return_by_pointer = abi_compat_return_by_value(c->allocator, pt->calling_convention, type->Proc.abi_compat_result_type);
}


Entity *check_ident(Checker *c, Operand *o, AstNode *n, Type *named_type, Type *type_hint, bool allow_import_name) {
	GB_ASSERT(n->kind == AstNode_Ident);
	o->mode = Addressing_Invalid;
	o->expr = n;
	String name = n->Ident.string;

	Entity *e = scope_lookup_entity(c->context.scope, name);
	if (e == NULL) {
		if (name == "_") {
			error(n->Ident, "`_` cannot be used as a value type");
		} else {
			error(n->Ident, "Undeclared name: %.*s", LIT(name));
		}
		o->type = t_invalid;
		o->mode = Addressing_Invalid;
		if (named_type != NULL) {
			set_base_type(named_type, t_invalid);
		}
		return NULL;
	}
	if (e->parent_proc_decl != NULL &&
	    e->parent_proc_decl != c->context.curr_proc_decl) {
		if (e->kind == Entity_Variable) {
			error(n->Ident, "Nested procedures do not capture its parent's variables: %.*s", LIT(name));
			return NULL;
		} else if (e->kind == Entity_Label) {
			error(n->Ident, "Nested procedures do not capture its parent's labels: %.*s", LIT(name));
			return NULL;
		}
	}

	bool is_overloaded = false;
	isize overload_count = 0;
	HashKey key = hash_string(name);

	if (e->kind == Entity_Procedure) {
		// NOTE(bill): Overloads are only allowed with the same scope
		Scope *s = e->scope;
		overload_count = multi_map_count(&s->elements, key);
		if (overload_count > 1) {
			is_overloaded = true;
		}
	}

	if (is_overloaded) {
		Scope *s = e->scope;
		bool skip = false;

		Entity **procs = gb_alloc_array(heap_allocator(), Entity *, overload_count);
		multi_map_get_all(&s->elements, key, procs);
		if (type_hint != NULL) {
			gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
			// NOTE(bill): These should be done
			for (isize i = 0; i < overload_count; i++) {
				Type *t = base_type(procs[i]->type);
				if (t == t_invalid) {
					continue;
				}
				Operand x = {};
				x.mode = Addressing_Value;
				x.type = t;
				if (check_is_assignable_to(c, &x, type_hint)) {
					e = procs[i];
					add_entity_use(c, n, e);
					skip = true;
					break;
				}
			}
			gb_temp_arena_memory_end(tmp);

		}

		if (!skip) {
			o->mode              = Addressing_Overload;
			o->type              = t_invalid;
			o->overload_count    = overload_count;
			o->overload_entities = procs;
			return NULL;
		}
		gb_free(heap_allocator(), procs);
	}

	add_entity_use(c, n, e);
	check_entity_decl(c, e, NULL, named_type);


	if (e->type == NULL) {
		compiler_error("How did this happen? type: %s; identifier: %.*s\n", type_to_string(e->type), LIT(name));
		// return NULL;
	}

	e->flags |= EntityFlag_Used;

	Type *type = e->type;
	switch (e->kind) {
	case Entity_Constant:
		if (type == t_invalid) {
			o->type = t_invalid;
			return e;
		}
		o->value = e->Constant.value;
		if (o->value.kind == ExactValue_Invalid) {
			return e;
		}
		o->mode = Addressing_Constant;
		break;

	case Entity_Variable:
		e->flags |= EntityFlag_Used;
		if (type == t_invalid) {
			o->type = t_invalid;
			return e;
		}
		o->mode = Addressing_Variable;
		if (e->flags & EntityFlag_Value) {
			o->mode = Addressing_Value;
		}
		if (e->Variable.is_immutable) {
			o->mode = Addressing_Immutable;
		}
		break;

	case Entity_Procedure:
		o->mode = Addressing_Value;
		break;

	case Entity_Builtin:
		o->builtin_id = cast(BuiltinProcId)e->Builtin.id;
		o->mode = Addressing_Builtin;
		break;

	case Entity_TypeName:
		o->mode = Addressing_Type;
		break;

	case Entity_ImportName:
		if (!allow_import_name) {
			error(n, "Use of import `%.*s` not in selector", LIT(name));
		}
		return e;
	case Entity_LibraryName:
		error(n, "Use of library `%.*s` not in foreign block", LIT(name));
		return e;

	case Entity_Label:
		o->mode = Addressing_NoValue;
		break;

	case Entity_Nil:
		o->mode = Addressing_Value;
		break;

	default:
		compiler_error("Unknown EntityKind %.*s", LIT(entity_strings[e->kind]));
		break;
	}

	o->type = type;
	return e;
}

i64 check_array_or_map_count(Checker *c, AstNode *e, bool is_map) {
	if (e == NULL) {
		return 0;
	}
	Operand o = {};
	if (e->kind == AstNode_UnaryExpr &&
	    e->UnaryExpr.op.kind == Token_Ellipsis) {
		return -1;
	}

	check_expr(c, &o, e);
	if (o.mode != Addressing_Constant) {
		if (o.mode != Addressing_Invalid) {
			if (is_map) {
				error(e, "Fixed map count must be a constant");
			} else {
				error(e, "Array count must be a constant");
			}
		}
		return 0;
	}
	Type *type = base_type(o.type);
	if (is_type_untyped(type) || is_type_integer(type)) {
		if (o.value.kind == ExactValue_Integer) {
			i64 count = i128_to_i64(o.value.value_integer);
			if (is_map) {
				if (count > 0) {
					return count;
				}
				error(e, "Invalid fixed map count");
			} else {
				if (count >= 0) {
					return count;
				}
				error(e, "Invalid array count");
			}
			return 0;
		}
	}

	if (is_map) {
		error(e, "Fixed map count must be an integer");
	} else {
		error(e, "Array count must be an integer");
	}
	return 0;
}

Type *make_optional_ok_type(gbAllocator a, Type *value) {
	bool typed = true;
	Type *t = make_type_tuple(a);
	t->Tuple.variables = gb_alloc_array(a, Entity *, 2);
	t->Tuple.variable_count = 2;
	t->Tuple.variables[0] = make_entity_field(a, NULL, blank_token, value,  false, 0);
	t->Tuple.variables[1] = make_entity_field(a, NULL, blank_token, typed ? t_bool : t_untyped_bool, false, 1);
	return t;
}

void check_map_type(Checker *c, Type *type, AstNode *node) {
	GB_ASSERT(type->kind == Type_Map);
	ast_node(mt, MapType, node);

	i64 count   = check_array_or_map_count(c, mt->count, true);
	Type *key   = check_type(c, mt->key);
	Type *value = check_type(c, mt->value);

	if (!is_type_valid_for_keys(key)) {
		if (is_type_boolean(key)) {
			error(node, "A boolean cannot be used as a key for a map");
		} else {
			gbString str = type_to_string(key);
			error(node, "Invalid type of a key for a map, got `%s`", str);
			gb_string_free(str);
		}
	}

	if (count > 0) {
		count = 0;
		error(node, "Fixed map types are not yet implemented");
	}

	type->Map.count = count;
	type->Map.key   = key;
	type->Map.value = value;

	gbAllocator a = c->allocator;

	{
		// NOTE(bill): The preload types may have not been set yet
		init_preload(c);
		GB_ASSERT(t_map_key != NULL);

		Type *entry_type = make_type_struct(a);

		/*
		struct {
			hash:  Map_Key,
			next:  int,
			key:   Key_Type,
			value: Value_Type,
		}
		*/
		AstNode *dummy_node = gb_alloc_item(a, AstNode);
		dummy_node->kind = AstNode_Invalid;
		check_open_scope(c, dummy_node);

		isize field_count = 3;
		Entity **fields = gb_alloc_array(a, Entity *, field_count);
		fields[0] = make_entity_field(a, c->context.scope, make_token_ident(str_lit("key")),   t_map_key, false, 0);
		fields[1] = make_entity_field(a, c->context.scope, make_token_ident(str_lit("next")),  t_int,     false, 1);
		fields[2] = make_entity_field(a, c->context.scope, make_token_ident(str_lit("value")), value,     false, 2);

		check_close_scope(c);

		entry_type->Record.fields              = fields;
		entry_type->Record.fields_in_src_order = fields;
		entry_type->Record.field_count         = field_count;

		type_set_offsets(a, entry_type);
		type->Map.entry_type = entry_type;
	}

	{
		Type *generated_struct_type = make_type_struct(a);

		/*
		struct {
			hashes:  [dynamic]int,
			entries; [dynamic]Entry_Type,
		}
		*/
		AstNode *dummy_node = gb_alloc_item(a, AstNode);
		dummy_node->kind = AstNode_Invalid;
		check_open_scope(c, dummy_node);

		Type *hashes_type  = make_type_dynamic_array(a, t_int);
		Type *entries_type = make_type_dynamic_array(a, type->Map.entry_type);

		isize field_count = 2;
		Entity **fields = gb_alloc_array(a, Entity *, field_count);
		fields[0] = make_entity_field(a, c->context.scope, make_token_ident(str_lit("hashes")),  hashes_type,  false, 0);
		fields[1] = make_entity_field(a, c->context.scope, make_token_ident(str_lit("entries")), entries_type, false, 1);

		check_close_scope(c);

		generated_struct_type->Record.fields              = fields;
		generated_struct_type->Record.fields_in_src_order = fields;
		generated_struct_type->Record.field_count         = field_count;

		type_set_offsets(a, generated_struct_type);
		type->Map.generated_struct_type = generated_struct_type;
	}

	type->Map.lookup_result_type = make_optional_ok_type(a, value);

	// error(node, "`map` types are not yet implemented");
}

bool check_type_internal(Checker *c, AstNode *e, Type **type, Type *named_type) {
	GB_ASSERT_NOT_NULL(type);
	if (e == NULL) {
		*type = t_invalid;
		return true;
	}

	switch (e->kind) {
	case_ast_node(i, Ident, e);
		Operand o = {};
		check_ident(c, &o, e, named_type, NULL, false);

		switch (o.mode) {
		case Addressing_Invalid:
			break;
		case Addressing_Type: {
			*type = o.type;
			return true;
		} break;
		case Addressing_NoValue: {
			gbString err_str = expr_to_string(e);
			error(e, "`%s` used as a type", err_str);
			gb_string_free(err_str);
		} break;
		default: {
			gbString err_str = expr_to_string(e);
			error(e, "`%s` used as a type when not a type", err_str);
			gb_string_free(err_str);
		} break;
		}
	case_end;

	case_ast_node(se, SelectorExpr, e);
		Operand o = {};
		check_selector(c, &o, e, NULL);

		switch (o.mode) {
		case Addressing_Invalid:
			break;
		case Addressing_Type:
			GB_ASSERT(o.type != NULL);
			*type = o.type;
			return true;
		case Addressing_NoValue: {
			gbString err_str = expr_to_string(e);
			error(e, "`%s` used as a type", err_str);
			gb_string_free(err_str);
		} break;
		default: {
			gbString err_str = expr_to_string(e);
			error(e, "`%s` is not a type", err_str);
			gb_string_free(err_str);
		} break;
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
		Type *elem = check_type(c, pt->type);
		i64 esz = type_size_of(c->allocator, elem);
		*type = make_type_pointer(c->allocator, elem);
		return true;
	case_end;

	case_ast_node(at, AtomicType, e);
		Type *elem = check_type(c, at->type);
		i64 esz = type_size_of(c->allocator, elem);
		*type = make_type_atomic(c->allocator, elem);
		return true;
	case_end;

	case_ast_node(at, ArrayType, e);
		if (at->count != NULL) {
			Type *elem = check_type(c, at->elem, NULL);
			i64 count = check_array_or_map_count(c, at->count, false);
			if (count < 0) {
				error(at->count, ".. can only be used in conjuction with compound literals");
				count = 0;
			}
#if 0
			i64 esz = type_size_of(c->allocator, elem);
			if (esz == 0) {
				gbString str = type_to_string(elem);
				error(at->elem, "Zero sized element type `%s` is not allowed", str);
				gb_string_free(str);
			}
#endif
			*type = make_type_array(c->allocator, elem, count);
		} else {
			Type *elem = check_type(c, at->elem);
#if 0
			i64 esz = type_size_of(c->allocator, elem);
			if (esz == 0) {
				gbString str = type_to_string(elem);
				error(at->elem, "Zero sized element type `%s` is not allowed", str);
				gb_string_free(str);
			}
#endif
			*type = make_type_slice(c->allocator, elem);
		}
		return true;
	case_end;

	case_ast_node(dat, DynamicArrayType, e);
		Type *elem = check_type(c, dat->elem);
		i64 esz = type_size_of(c->allocator, elem);
#if 0
		if (esz == 0) {
			gbString str = type_to_string(elem);
			error(dat->elem, "Zero sized element type `%s` is not allowed", str);
			gb_string_free(str);
		}
#endif
		*type = make_type_dynamic_array(c->allocator, elem);
		return true;
	case_end;



	case_ast_node(vt, VectorType, e);
		Type *elem = check_type(c, vt->elem);
		Type *be = base_type(elem);
		i64 count = check_array_or_map_count(c, vt->count, false);
		if (is_type_vector(be) || (!is_type_boolean(be) && !is_type_numeric(be))) {
			gbString err_str = type_to_string(elem);
			error(vt->elem, "Vector element type must be numerical or a boolean, got `%s`", err_str);
			gb_string_free(err_str);
		}
		*type = make_type_vector(c->allocator, elem, count);
		return true;
	case_end;

	case_ast_node(st, StructType, e);
		*type = make_type_struct(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_struct_type(c, *type, e);
		check_close_scope(c);
		(*type)->Record.node = e;
		return true;
	case_end;

	case_ast_node(ut, UnionType, e);
		*type = make_type_union(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_union_type(c, named_type, *type, e);
		check_close_scope(c);
		(*type)->Record.node = e;
		return true;
	case_end;

	case_ast_node(rut, RawUnionType, e);
		*type = make_type_raw_union(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_raw_union_type(c, *type, e);
		check_close_scope(c);
		(*type)->Record.node = e;
		return true;
	case_end;

	case_ast_node(et, EnumType, e);
		*type = make_type_enum(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_enum_type(c, *type, named_type, e);
		check_close_scope(c);
		(*type)->Record.node = e;
		return true;
	case_end;

	case_ast_node(et, BitFieldType, e);
		*type = make_type_bit_field(c->allocator);
		set_base_type(named_type, *type);
		check_open_scope(c, e);
		check_bit_field_type(c, *type, named_type, e);
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
	}

	*type = t_invalid;
	return false;
}



Type *check_type(Checker *c, AstNode *e, Type *named_type) {
	Type *type = NULL;
	bool ok = check_type_internal(c, e, &type, named_type);

	if (!ok) {
		gbString err_str = expr_to_string(e);
		error(e, "`%s` is not a type", err_str);
		gb_string_free(err_str);
		type = t_invalid;
	}

	if (type == NULL) {
		type = t_invalid;
	}

	if (type->kind == Type_Named) {
		if (type->Named.base == NULL) {
			gbString name = type_to_string(type);
			error(e, "Invalid type definition of %s", name);
			gb_string_free(name);
			type->Named.base = t_invalid;
		}
	}

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


bool check_unary_op(Checker *c, Operand *o, Token op) {
	if (o->type == NULL) {
		gbString str = expr_to_string(o->expr);
		error(o->expr, "Expression has no value `%s`", str);
		gb_string_free(str);
		return false;
	}
	// TODO(bill): Handle errors correctly
	Type *type = base_type(base_vector_type(o->type));
	gbString str = NULL;
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
		if (!is_type_numeric(type)) {
			str = expr_to_string(o->expr);
			error(op, "Operator `%.*s` is not allowed with `%s`", LIT(op.string), str);
			gb_string_free(str);
		}
		break;

	case Token_Xor:
		if (!is_type_integer(type) && !is_type_boolean(type)) {
			error(op, "Operator `%.*s` is only allowed with integers or booleans", LIT(op.string));
		}
		break;

	case Token_Not:
		if (!is_type_boolean(type)) {
			str = expr_to_string(o->expr);
			error(op, "Operator `%.*s` is only allowed on boolean expression", LIT(op.string));
			gb_string_free(str);
		}
		break;

	default:
		error(op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;
}

bool check_binary_op(Checker *c, Operand *o, Token op) {
	// TODO(bill): Handle errors correctly
	Type *type = base_type(base_vector_type(o->type));
	switch (op.kind) {
	case Token_Sub:
	case Token_SubEq:
		if (!is_type_numeric(type) && !is_type_pointer(type)) {
			error(op, "Operator `%.*s` is only allowed with numeric or pointer expressions", LIT(op.string));
			return false;
		}
		if (is_type_pointer(type)) {
			o->type = t_int;
		}
		if (base_type(type) == t_rawptr) {
			gbString str = type_to_string(type);
			error(o->expr, "Invalid pointer type for pointer arithmetic: `%s`", str);
			gb_string_free(str);
			return false;
		}
		break;

	case Token_Add:
	case Token_Mul:
	case Token_Quo:
	case Token_AddEq:
	case Token_MulEq:
	case Token_QuoEq:
		if (!is_type_numeric(type)) {
			error(op, "Operator `%.*s` is only allowed with numeric expressions", LIT(op.string));
			return false;
		}
		break;

	case Token_And:
	case Token_Or:
	case Token_AndEq:
	case Token_OrEq:
	case Token_Xor:
	case Token_XorEq:
		if (!is_type_integer(type) && !is_type_boolean(type)) {
			error(op, "Operator `%.*s` is only allowed with integers or booleans", LIT(op.string));
			return false;
		}
		break;

	case Token_Mod:
	case Token_ModMod:
	case Token_AndNot:
	case Token_ModEq:
	case Token_ModModEq:
	case Token_AndNotEq:
		if (!is_type_integer(type)) {
			error(op, "Operator `%.*s` is only allowed with integers", LIT(op.string));
			return false;
		}
		break;

	case Token_CmpAnd:
	case Token_CmpOr:
	case Token_CmpAndEq:
	case Token_CmpOrEq:
		if (!is_type_boolean(type)) {
			error(op, "Operator `%.*s` is only allowed with boolean expressions", LIT(op.string));
			return false;
		}
		break;

	default:
		error(op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;

}

bool check_representable_as_constant(Checker *c, ExactValue in_value, Type *type, ExactValue *out_value) {
	if (in_value.kind == ExactValue_Invalid) {
		// NOTE(bill): There's already been an error
		return true;
	}

	type = core_type(type);

	if (is_type_boolean(type)) {
		return in_value.kind == ExactValue_Bool;
	} else if (is_type_string(type)) {
		return in_value.kind == ExactValue_String;
	} else if (is_type_integer(type) || is_type_rune(type)) {
		ExactValue v = exact_value_to_integer(in_value);
		if (v.kind != ExactValue_Integer) {
			return false;
		}
		if (out_value) *out_value = v;


		if (is_type_untyped(type)) {
			return true;
		}

		i128 i = v.value_integer;
		u128 u = *cast(u128 *)&i;
		i64 s = 8*type_size_of(c->allocator, type);
		u128 umax = U128_NEG_ONE;
		if (s < 128) {
			umax = u128_sub(u128_shl(U128_ONE, s), U128_ONE);
		} else {
			// IMPORTANT TODO(bill): I NEED A PROPER BIG NUMBER LIBRARY THAT CAN SUPPORT 128 bit floats
			s = 128;
		}
		i128 imax = i128_shl(I128_ONE, s-1ll);

		switch (type->Basic.kind) {
		case Basic_rune:
		case Basic_i8:
		case Basic_i16:
		case Basic_i32:
		case Basic_i64:
		case Basic_i128:
		case Basic_int:
			return i128_le(i128_neg(imax), i) && i128_le(i, i128_sub(imax, I128_ONE));

		case Basic_u8:
		case Basic_u16:
		case Basic_u32:
		case Basic_u64:
		case Basic_u128:
		case Basic_uint:
			return !(u128_lt(u, U128_ZERO) || u128_gt(u, umax));

		case Basic_UntypedInteger:
			return true;

		default: GB_PANIC("Compiler error: Unknown integer type!"); break;
		}
	} else if (is_type_float(type)) {
		ExactValue v = exact_value_to_float(in_value);
		if (v.kind != ExactValue_Float) {
			return false;
		}
		if (out_value) *out_value = v;


		switch (type->Basic.kind) {
		// case Basic_f16:
		case Basic_f32:
		case Basic_f64:
			return true;

		case Basic_UntypedFloat:
			return true;
		}
	} else if (is_type_complex(type)) {
		ExactValue v = exact_value_to_complex(in_value);
		if (v.kind != ExactValue_Complex) {
			return false;
		}

		switch (type->Basic.kind) {
		case Basic_complex64:
		case Basic_complex128: {
			ExactValue real = exact_value_real(v);
			ExactValue imag = exact_value_imag(v);
			if (real.kind != ExactValue_Invalid &&
			    imag.kind != ExactValue_Invalid) {
				if (out_value) *out_value = exact_binary_operator_value(Token_Add, real, exact_value_make_imag(imag));
				return true;
			}
		} break;
		case Basic_UntypedComplex:
			return true;
		}

		return false;
	}else if (is_type_pointer(type)) {
		if (in_value.kind == ExactValue_Pointer) {
			return true;
		}
		if (in_value.kind == ExactValue_Integer) {
			return false;
			// return true;
		}
		if (out_value) *out_value = in_value;
	}


	return false;
}

void check_is_expressible(Checker *c, Operand *o, Type *type) {
	GB_ASSERT(is_type_constant_type(type));
	GB_ASSERT(o->mode == Addressing_Constant);
	if (!check_representable_as_constant(c, o->value, type, &o->value)) {
		gbString a = expr_to_string(o->expr);
		gbString b = type_to_string(type);
		if (is_type_numeric(o->type) && is_type_numeric(type)) {
			if (!is_type_integer(o->type) && is_type_integer(type)) {
				error(o->expr, "`%s` truncated to `%s`", a, b);
			} else {
				char buf[127] = {};
				String str = {};
				i128 i = o->value.value_integer;
				if (is_type_unsigned(o->type)) {
					str = u128_to_string(*cast(u128 *)&i, buf, gb_size_of(buf));
				} else {
					str = i128_to_string(i, buf, gb_size_of(buf));
				}
				error(o->expr, "`%s = %.*s` overflows `%s`", a, str, b);
			}
		} else {
			error(o->expr, "Cannot convert `%s` to `%s`", a, b);
		}

		gb_string_free(b);
		gb_string_free(a);
		o->mode = Addressing_Invalid;
	}
}

bool check_is_expr_vector_index(Checker *c, AstNode *expr) {
	// HACK(bill): Handle this correctly. Maybe with a custom AddressingMode
	expr = unparen_expr(expr);
	if (expr->kind == AstNode_IndexExpr) {
		ast_node(ie, IndexExpr, expr);
		Type *t = type_deref(type_of_expr(&c->info, ie->expr));
		if (t != NULL) {
			return is_type_vector(t);
		}
	}
	return false;
}

bool check_is_vector_elem(Checker *c, AstNode *expr) {
	// HACK(bill): Handle this correctly. Maybe with a custom AddressingMode
	expr = unparen_expr(expr);
	if (expr->kind == AstNode_SelectorExpr) {
		ast_node(se, SelectorExpr, expr);
		Type *t = type_deref(type_of_expr(&c->info, se->expr));
		if (t != NULL && is_type_vector(t)) {
			return true;
		}
	}
	return false;
}

bool check_is_not_addressable(Checker *c, Operand *o) {
	if (o->mode != Addressing_Variable) {
		return true;
	}
	if (is_type_bit_field_value(o->type)) {
		return true;
	}
	if (check_is_expr_vector_index(c, o->expr)) {
		return true;
	}
	if (check_is_vector_elem(c, o->expr)) {
		return true;
	}

	return false;
}

void check_unary_expr(Checker *c, Operand *o, Token op, AstNode *node) {
	switch (op.kind) {
	case Token_And: { // Pointer address
		if (o->mode == Addressing_Type) {
			o->type = make_type_pointer(c->allocator, o->type);
			return;
		}
		if (check_is_not_addressable(c, o)) {
			if (ast_node_expect(node, AstNode_UnaryExpr)) {
				ast_node(ue, UnaryExpr, node);
				gbString str = expr_to_string(ue->expr);
				error(op, "Cannot take the pointer address of `%s`", str);
				gb_string_free(str);
			}
			o->mode = Addressing_Invalid;
			return;
		}
		o->mode = Addressing_Value;
		o->type = make_type_pointer(c->allocator, o->type);
		return;
	}
	}

	if (!check_unary_op(c, o, op)) {
		o->mode = Addressing_Invalid;
		return;
	}

	if (o->mode == Addressing_Constant && !is_type_vector(o->type)) {
		Type *type = base_type(o->type);
		if (!is_type_constant_type(o->type)) {
			gbString xt = type_to_string(o->type);
			gbString err_str = expr_to_string(node);
			error(op, "Invalid type, `%s`, for constant unary expression `%s`", xt, err_str);
			gb_string_free(err_str);
			gb_string_free(xt);
			o->mode = Addressing_Invalid;
			return;
		}


		i32 precision = 0;
		if (is_type_unsigned(type)) {
			precision = cast(i32)(8 * type_size_of(c->allocator, type));
		}
		o->value = exact_unary_operator_value(op.kind, o->value, precision);

		if (is_type_typed(type)) {
			if (node != NULL) {
				o->expr = node;
			}
			check_is_expressible(c, o, type);
		}
		return;
	}

	o->mode = Addressing_Value;
}

void check_comparison(Checker *c, Operand *x, Operand *y, TokenKind op) {
	if (x->mode == Addressing_Type && y->mode == Addressing_Type) {
		bool comp = are_types_identical(x->type, y->type);
		switch (op) {
		case Token_CmpEq: comp = comp;  break;
		case Token_NotEq: comp = !comp; break;
		}
		x->mode  = Addressing_Constant;
		x->type  = t_untyped_bool;
		x->value = exact_value_bool(comp);
		return;
	}

	gbString err_str = NULL;
	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	if (check_is_assignable_to(c, x, y->type) ||
	    check_is_assignable_to(c, y, x->type)) {
		Type *err_type = x->type;
		bool defined = false;
		switch (op) {
		case Token_CmpEq:
		case Token_NotEq:
			defined = is_type_comparable(x->type) ||
			          (is_operand_nil(*x) && type_has_nil(y->type)) ||
			          (is_operand_nil(*y) && type_has_nil(x->type));
			break;
		case Token_Lt:
		case Token_Gt:
		case Token_LtEq:
		case Token_GtEq: {
			defined = is_type_ordered(x->type);
		} break;
		}

		if (!defined) {
			if (x->type == err_type && is_operand_nil(*x)) {
				err_type = y->type;
			}
			gb_printf_err("%d %d\n", is_operand_nil(*x), type_has_nil(y->type));
			gb_printf_err("%d %d\n", is_operand_nil(*y), type_has_nil(x->type));
			gbString type_string = type_to_string(err_type);
			err_str = gb_string_make(c->tmp_allocator,
			                         gb_bprintf("operator `%.*s` not defined for type `%s`", LIT(token_strings[op]), type_string));
			gb_string_free(type_string);
		}
	} else {
		gbString xt = type_to_string(x->type);
		gbString yt = type_to_string(y->type);
		err_str = gb_string_make(c->tmp_allocator,
		                         gb_bprintf("mismatched types `%s` and `%s`", xt, yt));
		gb_string_free(yt);
		gb_string_free(xt);
	}

	if (err_str != NULL) {
		error(x->expr, "Cannot compare expression, %s", err_str);
		x->type = t_untyped_bool;
	} else {
		if (x->mode == Addressing_Constant &&
		    y->mode == Addressing_Constant) {
			x->value = exact_value_bool(compare_exact_values(op, x->value, y->value));
		} else {
			x->mode = Addressing_Value;


			update_expr_type(c, x->expr, default_type(x->type), true);
			update_expr_type(c, y->expr, default_type(y->type), true);
		}

		if (is_type_vector(base_type(y->type))) {
			x->type = make_type_vector(c->allocator, t_bool, base_type(y->type)->Vector.count);
		} else {
			x->type = t_untyped_bool;
		}
	}

	if (err_str != NULL) {
		gb_string_free(err_str);
	}
	gb_temp_arena_memory_end(tmp);
}

void check_shift(Checker *c, Operand *x, Operand *y, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	ast_node(be, BinaryExpr, node);

	ExactValue x_val = {};
	if (x->mode == Addressing_Constant) {
		x_val = exact_value_to_integer(x->value);
	}

	bool x_is_untyped = is_type_untyped(x->type);
	if (!(is_type_integer(x->type) || (x_is_untyped && x_val.kind == ExactValue_Integer))) {
		gbString err_str = expr_to_string(x->expr);
		error(node, "Shifted operand `%s` must be an integer", err_str);
		gb_string_free(err_str);
		x->mode = Addressing_Invalid;
		return;
	}

	if (is_type_unsigned(y->type)) {

	} else if (is_type_untyped(y->type)) {
		convert_to_typed(c, y, t_untyped_integer, 0);
		if (y->mode == Addressing_Invalid) {
			x->mode = Addressing_Invalid;
			return;
		}
	} else {
		gbString err_str = expr_to_string(y->expr);
		error(node, "Shift amount `%s` must be an unsigned integer", err_str);
		gb_string_free(err_str);
		x->mode = Addressing_Invalid;
		return;
	}


	if (x->mode == Addressing_Constant) {
		if (y->mode == Addressing_Constant) {
			ExactValue y_val = exact_value_to_integer(y->value);
			if (y_val.kind != ExactValue_Integer) {
				gbString err_str = expr_to_string(y->expr);
				error(node, "Shift amount `%s` must be an unsigned integer", err_str);
				gb_string_free(err_str);
				x->mode = Addressing_Invalid;
				return;
			}

			i64 amount = i128_to_i64(y_val.value_integer);
			if (amount > 128) {
				gbString err_str = expr_to_string(y->expr);
				error(node, "Shift amount too large: `%s`", err_str);
				gb_string_free(err_str);
				x->mode = Addressing_Invalid;
				return;
			}

			if (!is_type_integer(x->type)) {
				// NOTE(bill): It could be an untyped float but still representable
				// as an integer
				x->type = t_untyped_integer;
			}

			x->value = exact_value_shift(be->op.kind, x_val, exact_value_i64(amount));

			if (is_type_typed(x->type)) {
				check_is_expressible(c, x, base_type(x->type));
			}
			return;
		}

		TokenPos pos = ast_node_token(x->expr).pos;
		if (x_is_untyped) {
			ExprInfo *info = check_get_expr_info(&c->info, x->expr);
			if (info != NULL) {
				info->is_lhs = true;
			}
			x->mode = Addressing_Value;
			// x->value = x_val;
			return;
		}
	}

	if (y->mode == Addressing_Constant && i128_lt(y->value.value_integer, I128_ZERO)) {
		gbString err_str = expr_to_string(y->expr);
		error(node, "Shift amount cannot be negative: `%s`", err_str);
		gb_string_free(err_str);
	}

	if (!is_type_integer(x->type)) {
		gbString err_str = expr_to_string(y->expr);
		error(node, "Shift operand `%s` must be an integer", err_str);
		gb_string_free(err_str);
		x->mode = Addressing_Invalid;
		return;
	}

	x->mode = Addressing_Value;
}


String check_down_cast_name(Type *dst_, Type *src_) {
	String result = {};
	Type *dst = type_deref(dst_);
	Type *src = type_deref(src_);
	Type *dst_s = base_type(dst);
	GB_ASSERT(is_type_struct(dst_s) || is_type_raw_union(dst_s));
	for (isize i = 0; i < dst_s->Record.field_count; i++) {
		Entity *f = dst_s->Record.fields[i];
		GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);
		if (f->flags & EntityFlag_Using) {
			if (are_types_identical(f->type, src_)) {
				return f->token.string;
			}
			if (are_types_identical(type_deref(f->type), src_)) {
				return f->token.string;
			}

			if (!is_type_pointer(f->type)) {
				result = check_down_cast_name(f->type, src_);
				if (result.len > 0) {
					return result;
				}
			}
		}
	}

	return result;
}

Operand check_ptr_addition(Checker *c, TokenKind op, Operand *ptr, Operand *offset, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	ast_node(be, BinaryExpr, node);
	GB_ASSERT(is_type_pointer(ptr->type));
	GB_ASSERT(is_type_integer(offset->type));
	GB_ASSERT(op == Token_Add || op == Token_Sub);

	Operand operand = {};
	operand.mode = Addressing_Value;
	operand.type = ptr->type;
	operand.expr = node;

	if (base_type(ptr->type) == t_rawptr) {
		gbString str = type_to_string(ptr->type);
		error(node, "Invalid pointer type for pointer arithmetic: `%s`", str);
		gb_string_free(str);
		operand.mode = Addressing_Invalid;
		return operand;
	}

	Type *base_ptr = base_type(ptr->type); GB_ASSERT(base_ptr->kind == Type_Pointer);
	Type *elem = base_ptr->Pointer.elem;
	i64 elem_size = type_size_of(c->allocator, elem);

	if (elem_size <= 0) {
		gbString str = type_to_string(elem);
		error(node, "Size of pointer's element type `%s` is zero and cannot be used for pointer arithmetic", str);
		gb_string_free(str);
		operand.mode = Addressing_Invalid;
		return operand;
	}

	if (ptr->mode == Addressing_Constant && offset->mode == Addressing_Constant) {
		i64 ptr_val = ptr->value.value_pointer;
		i64 offset_val = i128_to_i64(exact_value_to_integer(offset->value).value_integer);
		i64 new_ptr_val = ptr_val;
		if (op == Token_Add) {
			new_ptr_val += elem_size*offset_val;
		} else {
			new_ptr_val -= elem_size*offset_val;
		}
		operand.mode = Addressing_Constant;
		operand.value = exact_value_pointer(new_ptr_val);
	}

	return operand;
}



bool check_is_castable_to(Checker *c, Operand *operand, Type *y) {
	if (check_is_assignable_to(c, operand, y)) {
		return true;
	}

	Type *x = operand->type;
	Type *src = core_type(x);
	Type *dst = core_type(y);
	if (are_types_identical(src, dst)) {
		return true;
	}


	if (dst->kind == Type_Array && src->kind == Type_Array) {
		if (are_types_identical(dst->Array.elem, src->Array.elem)) {
			return dst->Array.count == src->Array.count;
		}
	}

	if (dst->kind == Type_Slice && src->kind == Type_Slice) {
		return are_types_identical(dst->Slice.elem, src->Slice.elem);
	}

	// Cast between booleans and integers
	if (is_type_boolean(src) || is_type_integer(src)) {
		if (is_type_boolean(dst) || is_type_integer(dst)) {
			return true;
		}
	}

	// Cast between numbers
	if (is_type_integer(src) || is_type_float(src)) {
		if (is_type_integer(dst) || is_type_float(dst)) {
			return true;
		}
	}

	if (is_type_integer(src) && is_type_rune(dst)) {
		return true;
	}
	if (is_type_rune(src) && is_type_integer(dst)) {
		return true;
	}

	if (is_type_complex(src) && is_type_complex(dst)) {
		return true;
	}

	if (is_type_bit_field_value(src) && is_type_integer(dst)) {
		return true;
	}

	if (is_type_bit_field_value(src) && is_type_boolean(dst)) {
		return src->BitFieldValue.bits == 1;
	}

	// Cast between pointers
	if (is_type_pointer(src) && is_type_pointer(dst)) {
		Type *s = base_type(type_deref(src));
		if (is_type_union(s)) {
			// NOTE(bill): Should the error be here?!
			// NOTE(bill): This error should suppress the next casting error as it's at the same position
			gbString xs = type_to_string(x);
			gbString ys = type_to_string(y);
			error(operand->expr, "Cannot cast from a union pointer `%s` to `%s`, try using `union_cast` or cast to a `rawptr`", xs, ys);
			gb_string_free(ys);
			gb_string_free(xs);
			return false;
		}
		return true;
	}

	// (u)int <-> rawptr
	if (is_type_int_or_uint(src) && is_type_rawptr(dst)) {
		return true;
	}
	if (is_type_rawptr(src) && is_type_int_or_uint(dst)) {
		return true;
	}

	// []byte/[]u8 <-> string
	if (is_type_u8_slice(src) && is_type_string(dst)) {
		return true;
	}
	if (is_type_string(src) && is_type_u8_slice(dst)) {
		// if (is_type_typed(src)) {
			return true;
		// }
	}

	// proc <-> proc
	if (is_type_proc(src) && is_type_proc(dst)) {
		return true;
	}

	// proc -> rawptr
	if (is_type_proc(src) && is_type_rawptr(dst)) {
		return true;
	}
	// rawptr -> proc
	if (is_type_rawptr(src) && is_type_proc(dst)) {
		return true;
	}

	return false;
}

void check_cast(Checker *c, Operand *x, Type *type) {
	bool is_const_expr = x->mode == Addressing_Constant;
	bool can_convert = false;

	Type *bt = base_type(type);
	if (is_const_expr && is_type_constant_type(bt)) {
		if (core_type(bt)->kind == Type_Basic) {
			if (check_representable_as_constant(c, x->value, bt, &x->value)) {
				can_convert = true;
			} else if (is_type_pointer(type) && check_is_castable_to(c, x, type)) {
				can_convert = true;
			}
		}
	} else if (check_is_castable_to(c, x, type)) {
		if (x->mode != Addressing_Constant) {
			x->mode = Addressing_Value;
		} else if (is_type_slice(type) && is_type_string(x->type)) {
			x->mode = Addressing_Value;
		} else if (!is_type_vector(x->type) && is_type_vector(type)) {
			x->mode = Addressing_Value;
		}
		can_convert = true;
	}

	if (!can_convert) {
		gbString expr_str = expr_to_string(x->expr);
		gbString to_type  = type_to_string(type);
		gbString from_type = type_to_string(x->type);
		error(x->expr, "Cannot cast `%s` as `%s` from `%s`", expr_str, to_type, from_type);
		gb_string_free(from_type);
		gb_string_free(to_type);
		gb_string_free(expr_str);

		x->mode = Addressing_Invalid;
		return;
	}

	if (is_type_untyped(x->type)) {
		Type *final_type = type;
		if (is_const_expr && !is_type_constant_type(type)) {
			final_type = default_type(x->type);
		}
		update_expr_type(c, x->expr, final_type, true);
	}

	x->type = type;
}

bool check_binary_vector_expr(Checker *c, Token op, Operand *x, Operand *y) {
	if (is_type_vector(x->type) && !is_type_vector(y->type)) {
		if (check_is_assignable_to(c, y, x->type)) {
			if (check_binary_op(c, x, op)) {
				return true;
			}
		}
	}
	return false;
}


void check_binary_expr(Checker *c, Operand *x, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	Operand y_ = {}, *y = &y_;

	ast_node(be, BinaryExpr, node);

	Token op = be->op;
	switch (op.kind) {
	case Token_CmpEq:
	case Token_NotEq: {
		// NOTE(bill): Allow comparisons between types
		check_expr_or_type(c, x, be->left);
		check_expr_or_type(c, y, be->right);
		bool xt = x->mode == Addressing_Type;
		bool yt = y->mode == Addressing_Type;
		// If only one is a type, this is an error
		if (xt ^ yt) {
			GB_ASSERT(xt != yt);
			if (xt) error_operand_not_expression(x);
			if (yt) error_operand_not_expression(y);
		}
	} break;

	default:
		check_expr(c, x, be->left);
		check_expr(c, y, be->right);
		break;
	}
	if (x->mode == Addressing_Invalid) {
		return;
	}
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		x->expr = y->expr;
		return;
	}

	if (token_is_shift(op.kind)) {
		check_shift(c, x, y, node);
		return;
	}

	if (op.kind == Token_Add || op.kind == Token_Sub) {
		if (is_type_pointer(x->type) && is_type_integer(y->type)) {
			*x = check_ptr_addition(c, op.kind, x, y, node);
			return;
		} else if (is_type_integer(x->type) && is_type_pointer(y->type)) {
			if (op.kind == Token_Sub) {
				gbString lhs = expr_to_string(x->expr);
				gbString rhs = expr_to_string(y->expr);
				error(node, "Invalid pointer arithmetic, did you mean `%s %.*s %s`?", rhs, LIT(op.string), lhs);
				gb_string_free(rhs);
				gb_string_free(lhs);
				x->mode = Addressing_Invalid;
				return;
			}
			*x = check_ptr_addition(c, op.kind, y, x, node);
			return;
		}
	}


	convert_to_typed(c, x, y->type, 0);
	if (x->mode == Addressing_Invalid) {
		return;
	}
	convert_to_typed(c, y, x->type, 0);
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		return;
	}

	if (token_is_comparison(op.kind)) {
		check_comparison(c, x, y, op.kind);
		return;
	}


	if (check_binary_vector_expr(c, op, x, y)) {
		x->mode = Addressing_Value;
		x->type = x->type;
		return;
	}
	if (check_binary_vector_expr(c, op, y, x)) {
		x->mode = Addressing_Value;
		x->type = y->type;
		return;
	}
	if (!are_types_identical(x->type, y->type)) {
		if (x->type != t_invalid &&
		    y->type != t_invalid) {
			gbString xt = type_to_string(x->type);
			gbString yt = type_to_string(y->type);
			gbString expr_str = expr_to_string(x->expr);
			error(op, "Mismatched types in binary expression `%s` : `%s` vs `%s`", expr_str, xt, yt);
			gb_string_free(expr_str);
			gb_string_free(yt);
			gb_string_free(xt);
		}
		x->mode = Addressing_Invalid;
		return;
	}

	if (!check_binary_op(c, x, op)) {
		x->mode = Addressing_Invalid;
		return;
	}

	switch (op.kind) {
	case Token_Quo:
	case Token_Mod:
	case Token_ModMod:
	case Token_QuoEq:
	case Token_ModEq:
	case Token_ModModEq:
		if ((x->mode == Addressing_Constant || is_type_integer(x->type)) &&
		    y->mode == Addressing_Constant) {
			bool fail = false;
			switch (y->value.kind) {
			case ExactValue_Integer:
				if (i128_eq(y->value.value_integer, I128_ZERO)) {
					fail = true;
				}
				break;
			case ExactValue_Float:
				if (y->value.value_float == 0.0) {
					fail = true;
				}
				break;
			}

			if (fail) {
				error(y->expr, "Division by zero not allowed");
				x->mode = Addressing_Invalid;
				return;
			}
		}
	}

	if (x->mode == Addressing_Constant &&
	    y->mode == Addressing_Constant) {
		ExactValue a = x->value;
		ExactValue b = y->value;

		Type *type = base_type(x->type);
		if (is_type_pointer(type)) {
			GB_ASSERT(op.kind == Token_Sub);
			i64 bytes = a.value_pointer - b.value_pointer;
			i64 diff = bytes/type_size_of(c->allocator, type);
			x->value = exact_value_pointer(diff);
			return;
		}

		if (!is_type_constant_type(type)) {
			gbString xt = type_to_string(x->type);
			gbString err_str = expr_to_string(node);
			error(op, "Invalid type, `%s`, for constant binary expression `%s`", xt, err_str);
			gb_string_free(err_str);
			gb_string_free(xt);
			x->mode = Addressing_Invalid;
			return;
		}

		if (op.kind == Token_Quo && is_type_integer(type)) {
			op.kind = Token_QuoEq; // NOTE(bill): Hack to get division of integers
		}
		x->value = exact_binary_operator_value(op.kind, a, b);
		if (is_type_typed(type)) {
			if (node != NULL) {
				x->expr = node;
			}
			check_is_expressible(c, x, type);
		}
		return;
	}

	x->mode = Addressing_Value;
}


void update_expr_type(Checker *c, AstNode *e, Type *type, bool final) {
	ExprInfo *found = check_get_expr_info(&c->info, e);
	if (found == NULL) {
		return;
	}
	ExprInfo old = *found;

	switch (e->kind) {
	case_ast_node(ue, UnaryExpr, e);
		if (old.value.kind != ExactValue_Invalid) {
			// NOTE(bill): if `e` is constant, the operands will be constant too.
			// They don't need to be updated as they will be updated later and
			// checked at the end of general checking stage.
			break;
		}
		update_expr_type(c, ue->expr, type, final);
	case_end;

	case_ast_node(be, BinaryExpr, e);
		if (old.value.kind != ExactValue_Invalid) {
			// See above note in UnaryExpr case
			break;
		}
		if (token_is_comparison(be->op.kind)) {
			// NOTE(bill): Do nothing as the types are fine
		} else if (token_is_shift(be->op.kind)) {
			update_expr_type(c, be->left,  type, final);
		} else {
			update_expr_type(c, be->left,  type, final);
			update_expr_type(c, be->right, type, final);
		}
	case_end;

	case_ast_node(pe, ParenExpr, e);
		update_expr_type(c, pe->expr, type, final);
	case_end;
	}

	if (!final && is_type_untyped(type)) {
		old.type = base_type(type);
		check_set_expr_info(&c->info, e, old);
		return;
	}

	// We need to remove it and then give it a new one
	check_remove_expr_info(&c->info, e);

	if (old.is_lhs && !is_type_integer(type)) {
		gbString expr_str = expr_to_string(e);
		gbString type_str = type_to_string(type);
		error(e, "Shifted operand %s must be an integer, got %s", expr_str, type_str);
		gb_string_free(type_str);
		gb_string_free(expr_str);
		return;
	}

	add_type_and_value(&c->info, e, old.mode, type, old.value);
}

void update_expr_value(Checker *c, AstNode *e, ExactValue value) {
	ExprInfo *found = check_get_expr_info(&c->info, e);
	if (found) {
		found->value = value;
	}
}

void convert_untyped_error(Checker *c, Operand *operand, Type *target_type) {
	gbString expr_str = expr_to_string(operand->expr);
	gbString type_str = type_to_string(target_type);
	char *extra_text = "";

	if (operand->mode == Addressing_Constant) {
		if (i128_eq(operand->value.value_integer, I128_ZERO)) {
			if (make_string_c(expr_str) != "nil") { // HACK NOTE(bill): Just in case
				// NOTE(bill): Doesn't matter what the type is as it's still zero in the union
				extra_text = " - Did you want `nil`?";
			}
		}
	}
	error(operand->expr, "Cannot convert `%s` to `%s`%s", expr_str, type_str, extra_text);

	gb_string_free(type_str);
	gb_string_free(expr_str);
	operand->mode = Addressing_Invalid;
}

ExactValue convert_exact_value_for_type(ExactValue v, Type *type) {
	Type *t = core_type(type);
	if (is_type_boolean(t)) {
		// v = exact_value_to_boolean(v);
	} else if (is_type_float(t)) {
		v = exact_value_to_float(v);
	} else if (is_type_integer(t)) {
		v = exact_value_to_integer(v);
	} else if (is_type_pointer(t)) {
		v = exact_value_to_integer(v);
	} else if (is_type_complex(t)) {
		v = exact_value_to_complex(v);
	}
	return v;
}

// NOTE(bill): Set initial level to 0
void convert_to_typed(Checker *c, Operand *operand, Type *target_type, i32 level) {
	GB_ASSERT_NOT_NULL(target_type);
	if (operand->mode == Addressing_Invalid ||
	    operand->mode == Addressing_Type ||
	    is_type_typed(operand->type) ||
	    target_type == t_invalid) {
		return;
	}

	if (is_type_untyped(target_type)) {
		GB_ASSERT(operand->type->kind == Type_Basic);
		GB_ASSERT(target_type->kind == Type_Basic);
		BasicKind x_kind = operand->type->Basic.kind;
		BasicKind y_kind = target_type->Basic.kind;
		if (is_type_numeric(operand->type) && is_type_numeric(target_type)) {
			if (x_kind < y_kind) {
				operand->type = target_type;
				update_expr_type(c, operand->expr, target_type, false);
			}
		} else if (x_kind != y_kind) {
			operand->mode = Addressing_Invalid;
			convert_untyped_error(c, operand, target_type);
			return;
		}
		return;
	}

	Type *t = core_type(target_type);
	switch (t->kind) {
	case Type_Basic:
		if (operand->mode == Addressing_Constant) {
			check_is_expressible(c, operand, t);
			if (operand->mode == Addressing_Invalid) {
				return;
			}
			update_expr_value(c, operand->expr, operand->value);
		} else {
			switch (operand->type->Basic.kind) {
			case Basic_UntypedBool:
				if (!is_type_boolean(target_type)) {
					operand->mode = Addressing_Invalid;
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;
			case Basic_UntypedInteger:
			case Basic_UntypedFloat:
			case Basic_UntypedComplex:
			case Basic_UntypedRune:
				if (!is_type_numeric(target_type)) {
					operand->mode = Addressing_Invalid;
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;

			case Basic_UntypedNil:
				if (is_type_any(target_type)) {
					target_type = t_untyped_nil;
				} else if (!type_has_nil(target_type)) {
					operand->mode = Addressing_Invalid;
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;
			}
		}
		break;

	case Type_Vector: {
		Type *elem = base_vector_type(t);
		if (check_is_assignable_to(c, operand, elem)) {
			operand->mode = Addressing_Value;
		} else {
			operand->mode = Addressing_Invalid;
			convert_untyped_error(c, operand, target_type);
			return;
		}
	} break;


	default:
		if (!is_type_untyped_nil(operand->type) || !type_has_nil(target_type)) {
			operand->mode = Addressing_Invalid;
			convert_untyped_error(c, operand, target_type);
			return;
		}
		target_type = t_untyped_nil;
		break;
	}

	operand->type = target_type;
	update_expr_type(c, operand->expr, target_type, true);
}

bool check_index_value(Checker *c, bool open_range, AstNode *index_value, i64 max_count, i64 *value) {
	Operand operand = {Addressing_Invalid};
	check_expr(c, &operand, index_value);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	convert_to_typed(c, &operand, t_int, 0);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	if (!is_type_integer(operand.type)) {
		gbString expr_str = expr_to_string(operand.expr);
		error(operand.expr, "Index `%s` must be an integer", expr_str);
		gb_string_free(expr_str);
		if (value) *value = 0;
		return false;
	}

	if (operand.mode == Addressing_Constant &&
	    (c->context.stmt_state_flags & StmtStateFlag_no_bounds_check) == 0) {
		i64 i = i128_to_i64(exact_value_to_integer(operand.value).value_integer);
		if (i < 0) {
			gbString expr_str = expr_to_string(operand.expr);
			error(operand.expr, "Index `%s` cannot be a negative value", expr_str);
			gb_string_free(expr_str);
			if (value) *value = 0;
			return false;
		}

		if (max_count >= 0) { // NOTE(bill): Do array bound checking
			if (value) *value = i;
			bool out_of_bounds = false;
			if (open_range) {
				out_of_bounds = i >= max_count;
			} else {
				out_of_bounds = i > max_count;
			}
			if (out_of_bounds) {
				gbString expr_str = expr_to_string(operand.expr);
				error(operand.expr, "Index `%s` is out of bounds range 0..<%lld", expr_str, max_count);
				gb_string_free(expr_str);
				return false;
			}


			return true;
		}
	}

	// NOTE(bill): It's alright :D
	if (value) *value = -1;
	return true;
}

isize entity_overload_count(Scope *s, String name) {
	Entity *e = scope_lookup_entity(s, name);
	if (e == NULL) {
		return 0;
	}
	if (e->kind == Entity_Procedure) {
		// NOTE(bill): Overloads are only allowed with the same scope
		return multi_map_count(&s->elements, hash_string(e->token.string));
	}
	return 1;
}

bool check_is_field_exported(Checker *c, Entity *field) {
	if (field == NULL) {
		// NOTE(bill): Just incase
		return true;
	}
	if (field->kind != Entity_Variable) {
		return true;
	}
	Scope *file_scope = field->scope;
	if (file_scope == NULL) {
		return true;
	}
	while (!file_scope->is_file) {
		file_scope = file_scope->parent;
	}
	if (!is_entity_exported(field) && file_scope != c->context.file_scope) {
		return false;
	}
	return true;
}

Entity *check_selector(Checker *c, Operand *operand, AstNode *node, Type *type_hint) {
	ast_node(se, SelectorExpr, node);

	bool check_op_expr = true;
	Entity *expr_entity = NULL;
	Entity *entity = NULL;
	Selection sel = {}; // NOTE(bill): Not used if it's an import name

	operand->expr = node;

	AstNode *op_expr  = se->expr;
	AstNode *selector = unparen_expr(se->selector);
	if (selector == NULL) {
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return NULL;
	}

	if (selector->kind != AstNode_Ident && selector->kind != AstNode_BasicLit) {
	// if (selector->kind != AstNode_Ident) {
		error(selector, "Illegal selector kind: `%.*s`", LIT(ast_node_strings[selector->kind]));
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return NULL;
	}

	if (op_expr->kind == AstNode_Ident) {
		String op_name = op_expr->Ident.string;
		Entity *e = scope_lookup_entity(c->context.scope, op_name);

		add_entity_use(c, op_expr, e);
		expr_entity = e;

		Entity *original_e = e;
		if (e != NULL && e->kind == Entity_ImportName && selector->kind == AstNode_Ident) {
			// IMPORTANT NOTE(bill): This is very sloppy code but it's also very fragile
			// It pretty much needs to be in this order and this way
			// If you can clean this up, please do but be really careful
			String import_name = op_name;
			Scope *import_scope = e->ImportName.scope;
			String entity_name = selector->Ident.string;

			check_op_expr = false;
			entity = scope_lookup_entity(import_scope, entity_name);
			bool is_declared = entity != NULL;
			if (is_declared) {
				if (entity->kind == Entity_Builtin) {
					// NOTE(bill): Builtin's are in the universe scope which is part of every scopes hierarchy
					// This means that we should just ignore the found result through it
					is_declared = false;
				} else if (entity->scope->is_global && !import_scope->is_global) {
					is_declared = false;
				}
			}
			if (!is_declared) {
				error(op_expr, "`%.*s` is not declared by `%.*s`", LIT(entity_name), LIT(import_name));
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return NULL;
			}
			check_entity_decl(c, entity, NULL, NULL);
			GB_ASSERT(entity->type != NULL);

			isize overload_count = entity_overload_count(import_scope, entity_name);
			bool is_overloaded = overload_count > 1;

			bool implicit_is_found = is_entity_implicitly_imported(e, entity);
			bool is_not_exported = !is_entity_exported(entity);
			if (!implicit_is_found) {
				is_not_exported = false;
			} else if (entity->kind == Entity_ImportName) {
				is_not_exported = true;
			}

			if (is_not_exported) {
				gbString sel_str = expr_to_string(selector);
				error(op_expr, "`%s` is not exported by `%.*s`", sel_str, LIT(import_name));
				gb_string_free(sel_str);
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return NULL;
			}

			if (is_overloaded) {
				HashKey key = hash_string(entity_name);
				bool skip = false;

				Entity **procs = gb_alloc_array(heap_allocator(), Entity *, overload_count);
				multi_map_get_all(&import_scope->elements, key, procs);

				for (isize i = 0; i < overload_count; i++) {
					Type *t = base_type(procs[i]->type);
					if (t == t_invalid) {
						continue;
					}

					// NOTE(bill): Check to see if it's imported
					if (map_get(&import_scope->implicit, hash_entity(procs[i]))) {
						gb_swap(Entity *, procs[i], procs[overload_count-1]);
						overload_count--;
						i--; // NOTE(bill): Counteract the post event
						continue;
					}

					Operand x = {};
					x.mode = Addressing_Value;
					x.type = t;
					if (type_hint != NULL) {
						if (check_is_assignable_to(c, &x, type_hint)) {
							entity = procs[i];
							skip = true;
							break;
						}
					}
				}

				if (overload_count > 0 && !skip) {
					operand->mode              = Addressing_Overload;
					operand->type              = t_invalid;
					operand->expr              = node;
					operand->overload_count    = overload_count;
					operand->overload_entities = procs;
					return procs[0];
				}
			}
		}
	}

	if (check_op_expr) {
		check_expr_base(c, operand, op_expr, NULL);
		if (operand->mode == Addressing_Invalid) {
			operand->mode = Addressing_Invalid;
			operand->expr = node;
			return NULL;
		}
	}


	if (entity == NULL && selector->kind == AstNode_Ident) {
		String field_name = selector->Ident.string;
		sel = lookup_field(c->allocator, operand->type, field_name, operand->mode == Addressing_Type);

		if (operand->mode != Addressing_Type && !check_is_field_exported(c, sel.entity)) {
			error(op_expr, "`%.*s` is an unexported field", LIT(field_name));
			operand->mode = Addressing_Invalid;
			operand->expr = node;
			return NULL;
		}
		entity = sel.entity;

		// NOTE(bill): Add type info needed for fields like `names`
		if (entity != NULL && (entity->flags&EntityFlag_TypeField)) {
			add_type_info_type(c, operand->type);
		}
	}
	if (entity == NULL && selector->kind == AstNode_BasicLit) {
		if (is_type_struct(operand->type) || is_type_tuple(operand->type)) {
			Type *type = base_type(operand->type);
			Operand o = {};
			check_expr(c, &o, selector);
			if (o.mode != Addressing_Constant ||
			    !is_type_integer(o.type)) {
				error(op_expr, "Indexed based selectors must be a constant integer %s");
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return NULL;
			}
			i64 index = i128_to_i64(o.value.value_integer);
			if (index < 0) {
				error(o.expr, "Index %lld cannot be a negative value", index);
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return NULL;
			}

			i64 max_count = 0;
			switch (type->kind) {
			case Type_Record: max_count = type->Record.field_count;   break;
			case Type_Tuple:  max_count = type->Tuple.variable_count; break;
			}

			if (index >= max_count) {
				error(o.expr, "Index %lld is out of bounds range 0..<%lld", index, max_count);
				operand->mode = Addressing_Invalid;
				operand->expr = node;
				return NULL;
			}

			sel = lookup_field_from_index(heap_allocator(), type, index);
			entity = sel.entity;

			GB_ASSERT(entity != NULL);

		} else {
			error(op_expr, "Indexed based selectors may only be used on structs or tuples");
			operand->mode = Addressing_Invalid;
			operand->expr = node;
			return NULL;
		}
	}

	if (entity == NULL &&
	    operand->type != NULL && is_type_untyped(operand->type) && is_type_string(operand->type)) {
		String s = operand->value.value_string;
		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(s.len);
		operand->type = t_untyped_integer;
		return NULL;
	}

	if (entity == NULL) {
		gbString op_str   = expr_to_string(op_expr);
		gbString type_str = type_to_string(operand->type);
		gbString sel_str  = expr_to_string(selector);
		error(op_expr, "`%s` of type `%s` has no field `%s`", op_str, type_str, sel_str);
		gb_string_free(sel_str);
		gb_string_free(type_str);
		gb_string_free(op_str);
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return NULL;
	}

	if (expr_entity != NULL && expr_entity->kind == Entity_Constant && entity->kind != Entity_Constant) {
		gbString op_str   = expr_to_string(op_expr);
		gbString type_str = type_to_string(operand->type);
		gbString sel_str  = expr_to_string(selector);
		error(op_expr, "Cannot access non-constant field `%s` from `%s`", sel_str, op_str);
		gb_string_free(sel_str);
		gb_string_free(type_str);
		gb_string_free(op_str);
		operand->mode = Addressing_Invalid;
		operand->expr = node;
		return NULL;
	}



	add_entity_use(c, selector, entity);

	switch (entity->kind) {
	case Entity_Constant:
		operand->mode = Addressing_Constant;
		operand->value = entity->Constant.value;
		break;
	case Entity_Variable:
		// TODO(bill): Is this the rule I need?
		if (operand->mode == Addressing_Immutable) {
			// Okay
		} else if (sel.indirect || operand->mode != Addressing_Value) {
			operand->mode = Addressing_Variable;
		} else {
			operand->mode = Addressing_Value;
		}
		break;
	case Entity_TypeName:
		operand->mode = Addressing_Type;
		break;
	case Entity_Procedure:
		operand->mode = Addressing_Value;
		break;
	case Entity_Builtin:
		operand->mode = Addressing_Builtin;
		operand->builtin_id = cast(BuiltinProcId)entity->Builtin.id;
		break;

	// NOTE(bill): These cases should never be hit but are here for sanity reasons
	case Entity_Nil:
		operand->mode = Addressing_Value;
		break;
	}

	operand->type = entity->type;
	operand->expr = node;

	return entity;
}

bool check_builtin_procedure(Checker *c, Operand *operand, AstNode *call, i32 id) {
	GB_ASSERT(call->kind == AstNode_CallExpr);
	ast_node(ce, CallExpr, call);
	BuiltinProc *bp = &builtin_procs[id];
	{
		char *err = NULL;
		if (ce->args.count < bp->arg_count) {
			err = "Too few";
		} else if (ce->args.count > bp->arg_count && !bp->variadic) {
			err = "Too many";
		}

		if (err != NULL) {
			gbString expr = expr_to_string(ce->proc);
			error(ce->close, "%s arguments for `%s`, expected %td, got %td",
			      err, expr,
			      bp->arg_count, ce->args.count);
			gb_string_free(expr);
			return false;
		}
	}

	if (ce->args.count > 0) {
		if (ce->args[0]->kind == AstNode_FieldValue) {
			error(call, "`field = value` calling is not allowed on built-in procedures");
			return false;
		}
	}


	bool vari_expand = (ce->ellipsis.pos.line != 0);
	if (vari_expand && id != BuiltinProc_append) {
		error(ce->ellipsis, "Invalid use of `..` with built-in procedure `append`");
		return false;
	}


	switch (id) {
	case BuiltinProc_new:
	case BuiltinProc_make:
	case BuiltinProc_size_of:
	case BuiltinProc_align_of:
	case BuiltinProc_offset_of:
	case BuiltinProc_type_info:
	case BuiltinProc_transmute:
		// NOTE(bill): The first arg may be a Type, this will be checked case by case
		break;
	default:
		if (ce->args.count > 0) {
			check_multi_expr(c, operand, ce->args[0]);
		}
		break;
	}

	switch (id) {
	default:
		GB_PANIC("Implement built-in procedure: %.*s", LIT(builtin_procs[id].name));
		break;

	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		GB_ASSERT(name == "location");
		if (ce->args.count > 1) {
			error(ce->args[0], "`#location` expects either 0 or 1 arguments, got %td", ce->args.count);
		}
		if (ce->args.count > 0) {
			AstNode *arg = ce->args[0];
			Entity *e = NULL;
			Operand o = {};
			if (arg->kind == AstNode_Ident) {
				e = check_ident(c, &o, arg, NULL, NULL, true);
			} else if (arg->kind == AstNode_SelectorExpr) {
				e = check_selector(c, &o, arg, NULL);
			}
			if (e == NULL) {
				error(ce->args[0], "`#location` expected a valid entity name");
			}
		}


		operand->type = t_source_code_location;
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_len:
	case BuiltinProc_cap: {
		// proc len(Type) -> int
		// proc cap(Type) -> int
		Type *op_type = type_deref(operand->type);
		Type *type = t_int;
		AddressingMode mode = Addressing_Invalid;
		ExactValue value = {};
		if (is_type_string(op_type) && id == BuiltinProc_len) {
			if (operand->mode == Addressing_Constant) {
				mode = Addressing_Constant;
				String str = operand->value.value_string;
				value = exact_value_i64(str.len);
				type = t_untyped_integer;
			} else {
				mode = Addressing_Value;
			}
		} else if (is_type_array(op_type)) {
			Type *at = core_type(op_type);
			mode = Addressing_Constant;
			value = exact_value_i64(at->Array.count);
			type = t_untyped_integer;
		} else if (is_type_vector(op_type) && id == BuiltinProc_len) {
			Type *at = core_type(op_type);
			mode = Addressing_Constant;
			value = exact_value_i64(at->Vector.count);
			type = t_untyped_integer;
		} else if (is_type_slice(op_type)) {
			mode = Addressing_Value;
		} else if (is_type_dynamic_array(op_type)) {
			mode = Addressing_Value;
		} else if (is_type_map(op_type)) {
			mode = Addressing_Value;
		}

		if (mode == Addressing_Invalid) {
			String name = builtin_procs[id].name;
			gbString t = type_to_string(operand->type);
			error(call, "`%.*s` is not supported for `%s`", LIT(name), t);
			return false;
		}

		operand->mode  = mode;
		operand->value = value;
		operand->type  = type;
	} break;

	case BuiltinProc_new: {
		// proc new(Type) -> ^Type
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *type = op.type;
		if ((op.mode != Addressing_Type && type == NULL) || type == t_invalid) {
			error(ce->args[0], "Expected a type for `new`");
			return false;
		}
		operand->mode = Addressing_Value;
		operand->type = make_type_pointer(c->allocator, type);
	} break;
	#if 0
	case BuiltinProc_new_slice: {
		// proc new_slice(Type, len: int) -> []Type
		// proc new_slice(Type, len, cap: int) -> []Type
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *type = op.type;
		if ((op.mode != Addressing_Type && type == NULL) || type == t_invalid) {
			error(ce->args[0], "Expected a type for `new_slice`");
			return false;
		}

		isize arg_count = ce->args.count;
		if (arg_count < 2 || 3 < arg_count) {
			error(ce->args[0], "`new_slice` expects 2 or 3 arguments, found %td", arg_count);
			// NOTE(bill): Return the correct type to reduce errors
		} else {
			// If any are constant
			i64 sizes[2] = {};
			isize size_count = 0;
			for (isize i = 1; i < arg_count; i++) {
				i64 val = 0;
				bool ok = check_index_value(c, ce->args[i], -1, &val);
				if (ok && val >= 0) {
					GB_ASSERT(size_count < gb_count_of(sizes));
					sizes[size_count++] = val;
				}
			}

			if (size_count == 2 && sizes[0] > sizes[1]) {
				error(ce->args[1], "`new_slice` count and capacity are swapped");
				// No need quit
			}
		}

		operand->mode = Addressing_Value;
		operand->type = make_type_slice(c->allocator, type);
	} break;
	#endif
	case BuiltinProc_make: {
		// proc make(Type, len: int) -> Type
		// proc make(Type, len, cap: int) -> Type
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *type = op.type;
		if ((op.mode != Addressing_Type && type == NULL) || type == t_invalid) {
			error(ce->args[0], "Expected a type for `make`");
			return false;
		}

		isize min_args = 0;
		isize max_args = 1;
		if (is_type_slice(type)) {
			min_args = 2;
			max_args = 3;
		} else if (is_type_dynamic_map(type)) {
			min_args = 1;
			max_args = 2;
		} else if (is_type_dynamic_array(type)) {
			min_args = 1;
			max_args = 3;
		} else {
			gbString str = type_to_string(type);
			error(call, "Cannot `make` %s; type must be a slice, map, or dynamic array", str);
			gb_string_free(str);
			return false;
		}

		isize arg_count = ce->args.count;
		if (arg_count < min_args || max_args < arg_count) {
			error(ce->args[0], "`make` expects %td or %d argument, found %td", min_args, max_args, arg_count);
			return false;
		}

		// If any are constant
		i64 sizes[4] = {};
		isize size_count = 0;
		for (isize i = 1; i < arg_count; i++) {
			i64 val = 0;
			bool ok = check_index_value(c, false, ce->args[i], -1, &val);
			if (ok && val >= 0) {
				GB_ASSERT(size_count < gb_count_of(sizes));
				sizes[size_count++] = val;
			}
		}

		if (size_count == 2 && sizes[0] > sizes[1]) {
			error(ce->args[1], "`make` count and capacity are swapped");
			// No need quit
		}

		operand->mode = Addressing_Value;
		operand->type = type;
	} break;

	case BuiltinProc_free: {
		// proc free(^Type)
		// proc free([]Type)
		// proc free(string)
		// proc free(map[K]T)
		Type *type = operand->type;
		bool ok = false;
		if (is_type_pointer(type)) {
			ok = true;
		} else if (is_type_slice(type)) {
			ok = true;
		} else if (is_type_string(type)) {
			ok = true;
		} else if (is_type_dynamic_array(type)) {
			ok = true;
		} else if (is_type_dynamic_map(type)) {
			ok = true;
		}

		if (!ok) {
			gbString type_str = type_to_string(type);
			error(operand->expr, "Invalid type for `free`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}


		operand->mode = Addressing_NoValue;
	} break;


	case BuiltinProc_reserve: {
		// proc reserve([dynamic]Type, count: int) {
		// proc reserve(map[Key]Type, count: int) {
		Type *type = operand->type;
		if (!is_type_dynamic_array(type) && !is_type_dynamic_map(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Expected a dynamic array or dynamic map, got `%s`", str);
			gb_string_free(str);
			return false;
		}

		AstNode *capacity = ce->args[1];
		Operand op = {};
		check_expr(c, &op, capacity);
		if (op.mode == Addressing_Invalid) {
			return false;
		}
		Type *arg_type = base_type(op.type);
		if (!is_type_integer(arg_type)) {
			error(operand->expr, "`reserve` capacities must be an integer");
			return false;
		}

		operand->type = NULL;
		operand->mode = Addressing_NoValue;
	} break;

	case BuiltinProc_clear: {
		Type *type = operand->type;
		bool is_pointer = is_type_pointer(type);
		type = base_type(type_deref(type));
		if (!is_type_dynamic_array(type) && !is_type_map(type) && !is_type_slice(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Invalid type for `clear`, got `%s`", str);
			gb_string_free(str);
			return false;
		}

		operand->type = NULL;
		operand->mode = Addressing_NoValue;
	} break;

	case BuiltinProc_append: {
		// proc append([dynamic]Type, item: ..Type)
		// proc append([]Type, item: ..Type)
		Operand prev_operand = *operand;

		Type *type = operand->type;
		bool is_pointer = is_type_pointer(type);
		type = base_type(type_deref(type));
		if (!is_type_dynamic_array(type) && !is_type_slice(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Expected a slice or dynamic array, got `%s`", str);
			gb_string_free(str);
			return false;
		}

		bool is_addressable = operand->mode == Addressing_Variable;
		if (is_pointer) {
			is_addressable = true;
		}
		if (!is_addressable) {
			error(operand->expr, "`append` can only operate on addressable values");
			return false;
		}

		Type *elem = NULL;
		if (is_type_dynamic_array(type)) {
			elem = type->DynamicArray.elem;
		} else {
			elem = type->Slice.elem;
		}
		Type *slice_elem = make_type_slice(c->allocator, elem);

		Type *proc_type_params = make_type_tuple(c->allocator);
		proc_type_params->Tuple.variables = gb_alloc_array(c->allocator, Entity *, 2);
		proc_type_params->Tuple.variable_count = 2;
		proc_type_params->Tuple.variables[0] = make_entity_param(c->allocator, NULL, blank_token, operand->type, false, false);
		proc_type_params->Tuple.variables[1] = make_entity_param(c->allocator, NULL, blank_token, slice_elem, false, false);
		Type *proc_type = make_type_proc(c->allocator, NULL, proc_type_params, 2, NULL, false, true, ProcCC_Odin);

		check_call_arguments(c, &prev_operand, proc_type, call);

		if (prev_operand.mode == Addressing_Invalid) {
			return false;
		}
		operand->mode = Addressing_Value;
		operand->type = t_int;
	} break;

	case BuiltinProc_delete: {
		// proc delete(map[Key]Value, key: Key)
		Type *type = operand->type;
		if (!is_type_map(type)) {
			gbString str = type_to_string(type);
			error(operand->expr, "Expected a map, got `%s`", str);
			gb_string_free(str);
			return false;
		}

		Type *key = base_type(type)->Map.key;
		Operand x = {Addressing_Invalid};
		AstNode *key_node = ce->args[1];
		Operand op = {};
		check_expr(c, &op, key_node);
		if (op.mode == Addressing_Invalid) {
			return false;
		}

		if (!check_is_assignable_to(c, &op, key)) {
			gbString kt = type_to_string(key);
			gbString ot = type_to_string(op.type);
			error(operand->expr, "Expected a key of type `%s`, got `%s`", key, ot);
			gb_string_free(ot);
			gb_string_free(kt);
			return false;
		}

		operand->mode = Addressing_NoValue;
	} break;


	case BuiltinProc_size_of: {
		// proc size_of(Type or expr) -> untyped int
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == NULL || t == t_invalid) {
			error(ce->args[0], "Invalid argument for `size_of`");
			return false;
		}
		t = default_type(t);

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_size_of(c->allocator, t));
		operand->type = t_untyped_integer;
	} break;

	case BuiltinProc_align_of: {
		// proc align_of(Type or expr) -> untyped int
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == NULL || t == t_invalid) {
			error(ce->args[0], "Invalid argument for `align_of`");
			return false;
		}
		t = default_type(t);

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_align_of(c->allocator, t));
		operand->type = t_untyped_integer;
	} break;


	case BuiltinProc_offset_of: {
		// proc offset_of(Type, field) -> untyped int
		Operand op = {};
		Type *bt = check_type(c, ce->args[0]);
		Type *type = base_type(bt);
		if (type == NULL || type == t_invalid) {
			error(ce->args[0], "Expected a type for `offset_of`");
			return false;
		}

		AstNode *field_arg = unparen_expr(ce->args[1]);
		if (field_arg == NULL ||
		    field_arg->kind != AstNode_Ident) {
			error(field_arg, "Expected an identifier for field argument");
			return false;
		}
		if (is_type_array(type) || is_type_vector(type)) {
			error(field_arg, "Invalid type for `offset_of`");
			return false;
		}


		ast_node(arg, Ident, field_arg);
		Selection sel = lookup_field(c->allocator, type, arg->string, operand->mode == Addressing_Type);
		if (sel.entity == NULL) {
			gbString type_str = type_to_string(bt);
			error(ce->args[0],
			      "`%s` has no field named `%.*s`", type_str, LIT(arg->string));
			gb_string_free(type_str);
			return false;
		}
		if (sel.indirect) {
			gbString type_str = type_to_string(bt);
			error(ce->args[0],
			      "Field `%.*s` is embedded via a pointer in `%s`", LIT(arg->string), type_str);
			gb_string_free(type_str);
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_offset_of_from_selection(c->allocator, type, sel));
		operand->type  = t_untyped_integer;
	} break;


	case BuiltinProc_type_of:
		// proc type_of_val(val: Type) -> type(Type)
		check_assignment(c, operand, NULL, str_lit("argument of `type_of_val`"));
		if (operand->mode == Addressing_Invalid || operand->mode == Addressing_Builtin) {
			return false;
		}
		if (operand->type == NULL || operand->type == t_invalid || is_type_gen_proc(operand->type)) {
			error(operand->expr, "Invalid argument to `type_of_val`");
			return false;
		}
		operand->mode = Addressing_Type;
		break;


	case BuiltinProc_type_info: {
		// proc type_info(Type) -> ^Type_Info
		if (c->context.scope->is_global) {
			compiler_error("`type_info` Cannot be declared within a #shared_global_scope due to how the internals of the compiler works");
		}

		// NOTE(bill): The type information may not be setup yet
		init_preload(c);
		AstNode *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == NULL || t == t_invalid || is_type_gen_proc(operand->type)) {
			error(ce->args[0], "Invalid argument for `type_info`");
			return false;
		}
		t = default_type(t);

		add_type_info_type(c, t);

		operand->mode = Addressing_Value;
		operand->type = t_type_info_ptr;
	} break;

	case BuiltinProc_compile_assert:
		// proc compile_assert(cond: bool) -> bool

		if (!is_type_boolean(operand->type) && operand->mode != Addressing_Constant) {
			gbString str = expr_to_string(ce->args[0]);
			error(call, "`%s` is not a constant boolean", str);
			gb_string_free(str);
			return false;
		}
		if (!operand->value.value_bool) {
			gbString str = expr_to_string(ce->args[0]);
			error(call, "Compile time assertion: `%s`", str);
			gb_string_free(str);
		}

		operand->mode = Addressing_Constant;
		operand->type = t_untyped_bool;
		break;

	case BuiltinProc_copy: {
		// proc copy(x, y: []Type) -> int
		Type *dest_type = NULL, *src_type = NULL;

		Type *d = base_type(operand->type);
		if (d->kind == Type_Slice) {
			dest_type = d->Slice.elem;
		}
		Operand op = {};
		check_expr(c, &op, ce->args[1]);
		if (op.mode == Addressing_Invalid) {
			return false;
		}
		Type *s = base_type(op.type);
		if (s->kind == Type_Slice) {
			src_type = s->Slice.elem;
		}

		if (dest_type == NULL || src_type == NULL) {
			error(call, "`copy` only expects slices as arguments");
			return false;
		}

		if (!are_types_identical(dest_type, src_type)) {
			gbString d_arg = expr_to_string(ce->args[0]);
			gbString s_arg = expr_to_string(ce->args[1]);
			gbString d_str = type_to_string(dest_type);
			gbString s_str = type_to_string(src_type);
			error(call,
			      "Arguments to `copy`, %s, %s, have different elem types: %s vs %s",
			      d_arg, s_arg, d_str, s_str);
			gb_string_free(s_str);
			gb_string_free(d_str);
			gb_string_free(s_arg);
			gb_string_free(d_arg);
			return false;
		}

		operand->type = t_int; // Returns number of elems copied
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_swizzle: {
		// proc swizzle(v: {N}T, T..) -> {M}T
		Type *vector_type = base_type(operand->type);
		if (!is_type_vector(vector_type)) {
			gbString type_str = type_to_string(operand->type);
			error(call,
			      "You can only `swizzle` a vector, got `%s`",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		isize max_count = vector_type->Vector.count;
		i128 max_count128 = i128_from_i64(max_count);
		isize arg_count = 0;
		for_array(i, ce->args) {
			if (i == 0) {
				continue;
			}
			AstNode *arg = ce->args[i];
			Operand op = {};
			check_expr(c, &op, arg);
			if (op.mode == Addressing_Invalid) {
				return false;
			}
			Type *arg_type = base_type(op.type);
			if (!is_type_integer(arg_type) || op.mode != Addressing_Constant) {
				error(op.expr, "Indices to `swizzle` must be constant integers");
				return false;
			}

			if (i128_lt(op.value.value_integer, I128_ZERO)) {
				error(op.expr, "Negative `swizzle` index");
				return false;
			}

			if (i128_le(max_count128, op.value.value_integer)) {
				error(op.expr, "`swizzle` index exceeds vector length");
				return false;
			}

			arg_count++;
		}

		if (arg_count > max_count) {
			error(call, "Too many `swizzle` indices, %td > %td", arg_count, max_count);
			return false;
		}

		Type *elem_type = vector_type->Vector.elem;
		operand->type = make_type_vector(c->allocator, elem_type, arg_count);
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_complex: {
		// proc complex(real, imag: float_type) -> complex_type
		Operand x = *operand;
		Operand y = {};

		// NOTE(bill): Invalid will be the default till fixed
		operand->type = t_invalid;
		operand->mode = Addressing_Invalid;

		check_expr(c, &y, ce->args[1]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}

		convert_to_typed(c, &x, y.type, 0); if (x.mode == Addressing_Invalid) return false;
		convert_to_typed(c, &y, x.type, 0); if (y.mode == Addressing_Invalid) return false;
		if (x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant) {
			if (is_type_numeric(x.type) && exact_value_imag(x.value).value_float == 0) {
				x.type = t_untyped_float;
			}
			if (is_type_numeric(y.type) && exact_value_imag(y.value).value_float == 0) {
				y.type = t_untyped_float;
			}
		}

		if (!are_types_identical(x.type, y.type)) {
			gbString tx = type_to_string(x.type);
			gbString ty = type_to_string(y.type);
			error(call, "Mismatched types to `complex`, `%s` vs `%s`", tx, ty);
			gb_string_free(ty);
			gb_string_free(tx);
			return false;
		}

		if (!is_type_float(x.type)) {
			gbString s = type_to_string(x.type);
			error(call, "Arguments have type `%s`, expected a floating point", s);
			gb_string_free(s);
			return false;
		}

		if (x.mode == Addressing_Constant && y.mode == Addressing_Constant) {
			operand->value = exact_binary_operator_value(Token_Add, x.value, y.value);
			operand->mode = Addressing_Constant;
		} else {
			operand->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x.type)->Basic.kind;
		switch (kind) {
		// case Basic_f16:          operand->type = t_complex32;       break;
		case Basic_f32:          operand->type = t_complex64;       break;
		case Basic_f64:          operand->type = t_complex128;      break;
		case Basic_UntypedFloat: operand->type = t_untyped_complex; break;
		default: GB_PANIC("Invalid type"); break;
		}
	} break;

	case BuiltinProc_real:
	case BuiltinProc_imag: {
		// proc real(x: type) -> float_type
		// proc imag(x: type) -> float_type

		Operand *x = operand;
		if (is_type_untyped(x->type)) {
			if (x->mode == Addressing_Constant) {
				if (is_type_numeric(x->type)) {
					x->type = t_untyped_complex;
				}
			} else {
				convert_to_typed(c, x, t_complex128, 0);
				if (x->mode == Addressing_Invalid) {
					return false;
				}
			}
		}

		if (!is_type_complex(x->type)) {
			gbString s = type_to_string(x->type);
			error(call, "Argument has type `%s`, expected a complex type", s);
			gb_string_free(s);
			return false;
		}

		if (x->mode == Addressing_Constant) {
			switch (id) {
			case BuiltinProc_real: x->value = exact_value_real(x->value); break;
			case BuiltinProc_imag: x->value = exact_value_imag(x->value); break;
			}
		} else {
			x->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x->type)->Basic.kind;
		switch (kind) {
		case Basic_complex64:         x->type = t_f32;           break;
		case Basic_complex128:        x->type = t_f64;           break;
		case Basic_UntypedComplex:    x->type = t_untyped_float; break;
		default: GB_PANIC("Invalid type"); break;
		}
	} break;

	case BuiltinProc_conj: {
		// proc conj(x: type) -> type
		Operand *x = operand;
		if (is_type_complex(x->type)) {
			if (x->mode == Addressing_Constant) {
				ExactValue v = exact_value_to_complex(x->value);
				f64 r = v.value_complex.real;
				f64 i = v.value_complex.imag;
				x->value = exact_value_complex(r, i);
				x->mode = Addressing_Constant;
			} else {
				x->mode = Addressing_Value;
			}
		} else {
			gbString s = type_to_string(x->type);
			error(call, "Expected a complex or quaternion, got `%s`", s);
			gb_string_free(s);
			return false;
		}

	} break;

	case BuiltinProc_slice_ptr: {
		// proc slice_ptr(a: ^T, len: int) -> []T
		// proc slice_ptr(a: ^T, len, cap: int) -> []T
		// ^T cannot be rawptr
		Type *ptr_type = base_type(operand->type);
		if (!is_type_pointer(ptr_type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a pointer to `slice_ptr`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (ptr_type == t_rawptr) {
			error(call, "`rawptr` cannot have pointer arithmetic");
			return false;
		}

		isize arg_count = ce->args.count;
		if (arg_count < 2 || 3 < arg_count) {
			error(ce->args[0], "`slice_ptr` expects 2 or 3 arguments, found %td", arg_count);
			// NOTE(bill): Return the correct type to reduce errors
		} else {
			// If any are constant
			i64 sizes[2] = {};
			isize size_count = 0;
			for (isize i = 1; i < arg_count; i++) {
				i64 val = 0;
				bool ok = check_index_value(c, false, ce->args[i], -1, &val);
				if (ok && val >= 0) {
					GB_ASSERT(size_count < gb_count_of(sizes));
					sizes[size_count++] = val;
				}
			}

			if (size_count == 2 && sizes[0] > sizes[1]) {
				error(ce->args[1], "`slice_ptr` count and capacity are swapped");
				// No need quit
			}
		}
		operand->type = make_type_slice(c->allocator, ptr_type->Pointer.elem);
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_slice_to_bytes: {
		// proc slice_to_bytes(a: []T) -> []u8
		Type *slice_type = base_type(operand->type);
		if (!is_type_slice(slice_type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a slice type, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		operand->type = t_u8_slice;
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_expand_to_tuple: {
		Type *type = base_type(operand->type);
		if (!is_type_struct(type) &
		    !is_type_union(type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a struct or union type, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}
		gbAllocator a = c->allocator;

		Type *tuple = make_type_tuple(a);
		i32 variable_count = type->Record.field_count;
		tuple->Tuple.variables = gb_alloc_array(a, Entity *, variable_count);
		tuple->Tuple.variable_count = variable_count;

		// TODO(bill): Should I copy each of the entities or is this good enough?
		gb_memcopy_array(tuple->Tuple.variables, type->Record.fields, variable_count);

		operand->type = tuple;
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_min: {
		// proc min(a, b: ordered) -> ordered
		Type *type = base_type(operand->type);
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a ordered numeric type to `min`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		AstNode *other_arg = ce->args[1];
		Operand a = *operand;
		Operand b = {};
		check_expr(c, &b, other_arg);
		if (b.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(b.type) || !(is_type_numeric(b.type) || is_type_string(b.type))) {
			gbString type_str = type_to_string(b.type);
			error(call,
			      "Expected a ordered numeric type to `min`, got `%s`",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		if (a.mode == Addressing_Constant &&
		    b.mode == Addressing_Constant) {
			ExactValue x = a.value;
			ExactValue y = b.value;

			operand->mode = Addressing_Constant;
			if (compare_exact_values(Token_Lt, x, y)) {
				operand->value = x;
				operand->type = a.type;
			} else {
				operand->value = y;
				operand->type = b.type;
			}
		} else {
			operand->mode = Addressing_Value;
			operand->type = type;

			convert_to_typed(c, &a, b.type, 0);
			if (a.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &b, a.type, 0);
			if (b.mode == Addressing_Invalid) {
				return false;
			}

			if (!are_types_identical(a.type, b.type)) {
				gbString type_a = type_to_string(a.type);
				gbString type_b = type_to_string(b.type);
				error(call,
				      "Mismatched types to `min`, `%s` vs `%s`",
				      type_a, type_b);
				gb_string_free(type_b);
				gb_string_free(type_a);
				return false;
			}
		}

	} break;

	case BuiltinProc_max: {
		// proc min(a, b: ordered) -> ordered
		Type *type = base_type(operand->type);
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call,
			      "Expected a ordered numeric or string type to `max`, got `%s`",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		AstNode *other_arg = ce->args[1];
		Operand a = *operand;
		Operand b = {};
		check_expr(c, &b, other_arg);
		if (b.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(b.type) || !(is_type_numeric(b.type) || is_type_string(b.type))) {
			gbString type_str = type_to_string(b.type);
			error(call,
			      "Expected a ordered numeric or string type to `max`, got `%s`",
			      type_str);
			gb_string_free(type_str);
			return false;
		}

		if (a.mode == Addressing_Constant &&
		    b.mode == Addressing_Constant) {
			ExactValue x = a.value;
			ExactValue y = b.value;

			operand->mode = Addressing_Constant;
			if (compare_exact_values(Token_Gt, x, y)) {
				operand->value = x;
				operand->type = a.type;
			} else {
				operand->value = y;
				operand->type = b.type;
			}
		} else {
			operand->mode = Addressing_Value;
			operand->type = type;

			convert_to_typed(c, &a, b.type, 0);
			if (a.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &b, a.type, 0);
			if (b.mode == Addressing_Invalid) {
				return false;
			}

			if (!are_types_identical(a.type, b.type)) {
				gbString type_a = type_to_string(a.type);
				gbString type_b = type_to_string(b.type);
				error(call,
				      "Mismatched types to `max`, `%s` vs `%s`",
				      type_a, type_b);
				gb_string_free(type_b);
				gb_string_free(type_a);
				return false;
			}
		}

	} break;

	case BuiltinProc_abs: {
		// proc abs(n: numeric) -> numeric
		if (!is_type_numeric(operand->type) && !is_type_vector(operand->type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a numeric type to `abs`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (operand->mode == Addressing_Constant) {
			switch (operand->value.kind) {
			case ExactValue_Integer:
				operand->value.value_integer = i128_abs(operand->value.value_integer);
				break;
			case ExactValue_Float:
				operand->value.value_float = gb_abs(operand->value.value_float);
				break;
			case ExactValue_Complex: {
				f64 r = operand->value.value_complex.real;
				f64 i = operand->value.value_complex.imag;
				operand->value = exact_value_float(gb_sqrt(r*r + i*i));
			} break;
			default:
				GB_PANIC("Invalid numeric constant");
				break;
			}
		} else {
			operand->mode = Addressing_Value;
		}

		if (is_type_complex(operand->type)) {
			operand->type = base_complex_elem_type(operand->type);
		}
		GB_ASSERT(!is_type_complex(operand->type));
	} break;

	case BuiltinProc_clamp: {
		// proc clamp(a, min, max: ordered) -> ordered
		Type *type = base_type(operand->type);
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a ordered numeric or string type to `clamp`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		AstNode *min_arg = ce->args[1];
		AstNode *max_arg = ce->args[2];
		Operand x = *operand;
		Operand y = {};
		Operand z = {};

		check_expr(c, &y, min_arg);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(y.type) || !(is_type_numeric(y.type) || is_type_string(y.type))) {
			gbString type_str = type_to_string(y.type);
			error(call, "Expected a ordered numeric or string type to `clamp`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		check_expr(c, &z, max_arg);
		if (z.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(z.type) || !(is_type_numeric(z.type) || is_type_string(z.type))) {
			gbString type_str = type_to_string(z.type);
			error(call, "Expected a ordered numeric or string type to `clamp`, got `%s`", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant &&
		    z.mode == Addressing_Constant) {
			ExactValue a = x.value;
			ExactValue b = y.value;
			ExactValue c = z.value;

			operand->mode = Addressing_Constant;
			if (compare_exact_values(Token_Lt, a, b)) {
				operand->value = b;
				operand->type = y.type;
			} else if (compare_exact_values(Token_Gt, a, c)) {
				operand->value = c;
				operand->type = z.type;
			} else {
				operand->value = a;
				operand->type = x.type;
			}
		} else {
			operand->mode = Addressing_Value;
			operand->type = type;

			convert_to_typed(c, &x, y.type, 0);
			if (x.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &y, x.type, 0);
			if (y.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &x, z.type, 0);
			if (x.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &z, x.type, 0);
			if (z.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &y, z.type, 0);
			if (y.mode == Addressing_Invalid) { return false; }
			convert_to_typed(c, &z, y.type, 0);
			if (z.mode == Addressing_Invalid) { return false; }

			if (!are_types_identical(x.type, y.type) || !are_types_identical(x.type, z.type)) {
				gbString type_x = type_to_string(x.type);
				gbString type_y = type_to_string(y.type);
				gbString type_z = type_to_string(z.type);
				error(call,
				      "Mismatched types to `clamp`, `%s`, `%s`, `%s`",
				      type_x, type_y, type_z);
				gb_string_free(type_z);
				gb_string_free(type_y);
				gb_string_free(type_x);
				return false;
			}
		}
	} break;

	case BuiltinProc_transmute: {
		Operand op = {};
		check_expr_or_type(c, &op, ce->args[0]);
		Type *t = op.type;
		if ((op.mode != Addressing_Type && t == NULL) || t == t_invalid) {
			error(ce->args[0], "Expected a type for `transmute`");
			return false;
		}
		AstNode *expr = ce->args[1];
		Operand *o = operand;
		check_expr(c, o, expr);
		if (o->mode == Addressing_Invalid) {
			return false;
		}

		if (o->mode == Addressing_Constant) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "Cannot transmute a constant expression: `%s`", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = expr;
			return false;
		}

		if (is_type_untyped(o->type)) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "Cannot transmute untyped expression: `%s`", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = expr;
			return false;
		}

		i64 srcz = type_size_of(c->allocator, o->type);
		i64 dstz = type_size_of(c->allocator, t);
		if (srcz != dstz) {
			gbString expr_str = expr_to_string(o->expr);
			gbString type_str = type_to_string(t);
			error(o->expr, "Cannot transmute `%s` to `%s`, %lld vs %lld bytes", expr_str, type_str, srcz, dstz);
			gb_string_free(type_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = expr;
			return false;
		}

		o->mode = Addressing_Value;
		o->type = t;
	} break;
	}

	return true;
}

enum CallArgumentError {
	CallArgumentError_None,
	CallArgumentError_WrongTypes,
	CallArgumentError_NonVariadicExpand,
	CallArgumentError_VariadicTuple,
	CallArgumentError_MultipleVariadicExpand,
	CallArgumentError_ArgumentCount,
	CallArgumentError_TooFewArguments,
	CallArgumentError_TooManyArguments,
	CallArgumentError_InvalidFieldValue,
	CallArgumentError_ParameterNotFound,
	CallArgumentError_ParameterMissing,
	CallArgumentError_DuplicateParameter,
	CallArgumentError_GenericProcedureNotSupported,
};

enum CallArgumentErrorMode {
	CallArgumentMode_NoErrors,
	CallArgumentMode_ShowErrors,
};


struct ValidProcAndScore {
	isize index;
	i64   score;
};

int valid_proc_and_score_cmp(void const *a, void const *b) {
	i64 si = (cast(ValidProcAndScore const *)a)->score;
	i64 sj = (cast(ValidProcAndScore const *)b)->score;
	return sj < si ? -1 : sj > si;
}

bool check_unpack_arguments(Checker *c, isize lhs_count, Array<Operand> *operands, Array<AstNode *> rhs, bool allow_ok) {
	bool optional_ok = false;
	for_array(i, rhs) {
		Operand o = {};
		check_expr_base(c, &o, rhs[i], NULL);
		if (o.mode == Addressing_NoValue) {
			error_operand_no_value(&o);
			o.mode = Addressing_Invalid;
		}
		// check_multi_expr(c, &o, rhs[i]);


		if (o.type == NULL || o.type->kind != Type_Tuple) {
			if (allow_ok && lhs_count == 2 && rhs.count == 1 &&
			    (o.mode == Addressing_MapIndex || o.mode == Addressing_OptionalOk)) {
				Type *tuple = make_optional_ok_type(c->allocator, o.type);
				add_type_and_value(&c->info, o.expr, o.mode, tuple, o.value);

				Operand val = o;
				Operand ok = o;
				val.mode = Addressing_Value;
				ok.mode  = Addressing_Value;
				ok.type  = t_bool;
				array_add(operands, val);
				array_add(operands, ok);

				optional_ok = true;
			} else {
				array_add(operands, o);
			}
		} else {
			TypeTuple *tuple = &o.type->Tuple;
			for (isize j = 0; j < tuple->variable_count; j++) {
				o.type = tuple->variables[j]->type;
				array_add(operands, o);
			}
		}
	}

	return optional_ok;
}

#define CALL_ARGUMENT_CHECKER(name) CallArgumentError name(Checker *c, AstNode *call, Type *proc_type, Array<Operand> operands, CallArgumentErrorMode show_error_mode, i64 *score_)
typedef CALL_ARGUMENT_CHECKER(CallArgumentCheckerType);


CALL_ARGUMENT_CHECKER(check_call_arguments_internal) {
	ast_node(ce, CallExpr, call);
	isize param_count = 0;
	isize param_count_excluding_defaults = 0;
	bool variadic = proc_type->Proc.variadic;
	bool vari_expand = (ce->ellipsis.pos.line != 0);
	i64 score = 0;
	bool show_error = show_error_mode == CallArgumentMode_ShowErrors;

	TypeTuple *param_tuple = NULL;

	if (proc_type->Proc.params != NULL) {
		param_tuple = &proc_type->Proc.params->Tuple;

		param_count = param_tuple->variable_count;
		if (variadic) {
			param_count--;
		}
	}

	param_count_excluding_defaults = param_count;
	if (param_tuple != NULL) {
		for (isize i = param_count-1; i >= 0; i--) {
			Entity *e = param_tuple->variables[i];
			if (e->kind == Entity_TypeName) {
				break;
			}

			GB_ASSERT(e->kind == Entity_Variable);
			if (e->Variable.default_value.kind != ExactValue_Invalid ||
			    e->Variable.default_is_nil ||
			    e->Variable.default_is_location) {
				param_count_excluding_defaults--;
				continue;
			}
			break;
		}
	}

	if (vari_expand && !variadic) {
		if (show_error) {
			error(ce->ellipsis,
			      "Cannot use `..` in call to a non-variadic procedure: `%.*s`",
			      LIT(ce->proc->Ident.string));
		}
		if (score_) *score_ = score;
		return CallArgumentError_NonVariadicExpand;
	}
	if (vari_expand && proc_type->Proc.c_vararg) {
		if (show_error) {
			error(ce->ellipsis,
			      "Cannot use `..` in call to a `#c_vararg` variadic procedure: `%.*s`",
			      LIT(ce->proc->Ident.string));
		}
		if (score_) *score_ = score;
		return CallArgumentError_NonVariadicExpand;
	}

	if (operands.count == 0 && param_count_excluding_defaults == 0) {
		if (score_) *score_ = score;
		return CallArgumentError_None;
	}

	i32 error_code = 0;
	if (operands.count < param_count_excluding_defaults) {
		error_code = -1;
	} else if (!variadic && operands.count > param_count) {
		error_code = +1;
	}
	if (error_code != 0) {
		CallArgumentError err = CallArgumentError_TooManyArguments;
		char *err_fmt = "Too many arguments for `%s`, expected %td arguments";
		if (error_code < 0) {
			err = CallArgumentError_TooFewArguments;
			err_fmt = "Too few arguments for `%s`, expected %td arguments";
		}

		if (show_error) {
			gbString proc_str = expr_to_string(ce->proc);
			error(call, err_fmt, proc_str, param_count_excluding_defaults);
			gb_string_free(proc_str);
		}
		if (score_) *score_ = score;
		return err;
	}

	CallArgumentError err = CallArgumentError_None;


	GB_ASSERT(proc_type->Proc.params != NULL);
	Entity **sig_params = param_tuple->variables;
	isize operand_index = 0;
	isize max_operand_count = gb_min(param_count, operands.count);
	for (; operand_index < max_operand_count; operand_index++) {
		Entity *e = sig_params[operand_index];
		Type *t = e->type;
		Operand o = operands[operand_index];
		if (e->kind == Entity_TypeName) {
			GB_ASSERT(proc_type->Proc.is_generic);
			GB_ASSERT(!variadic);
			if (o.mode == Addressing_Invalid) {
				continue;
			} else if (o.mode != Addressing_Type) {
				error(o.expr, "Expected a type for the argument");
			}

			score += assign_score_function(1);
			continue;
		}
		if (variadic) {
			o = operands[operand_index];
		}
		i64 s = 0;
		if (!check_is_assignable_to_with_score(c, &o, t, &s)) {
			if (show_error) {
				check_assignment(c, &o, t, str_lit("argument"));
			}
			err = CallArgumentError_WrongTypes;
		}
		score += s;
	}

	if (variadic) {
		bool variadic_expand = false;
		Type *slice = sig_params[param_count]->type;
		GB_ASSERT(is_type_slice(slice));
		Type *elem = base_type(slice)->Slice.elem;
		Type *t = elem;
		for (; operand_index < operands.count; operand_index++) {
			Operand o = operands[operand_index];
			if (vari_expand) {
				variadic_expand = true;
				t = slice;
				if (operand_index != param_count) {
					if (show_error) {
						error(o.expr, "`..` in a variadic procedure can only have one variadic argument at the end");
					}
					if (score_) *score_ = score;
					return CallArgumentError_MultipleVariadicExpand;
				}
			}
			i64 s = 0;
			if (!check_is_assignable_to_with_score(c, &o, t, &s)) {
				if (show_error) {
					check_assignment(c, &o, t, str_lit("argument"));
				}
				err = CallArgumentError_WrongTypes;
			}
			score += s;
		}
	}

	if (score_) *score_ = score;
	return err;
}

bool is_call_expr_field_value(AstNodeCallExpr *ce) {
	GB_ASSERT(ce != NULL);

	if (ce->args.count == 0) {
		return false;
	}
	return ce->args[0]->kind == AstNode_FieldValue;
}

isize lookup_procedure_parameter(TypeProc *pt, String parameter_name) {
	isize param_count = pt->param_count;
	for (isize i = 0; i < param_count; i++) {
		Entity *e = pt->params->Tuple.variables[i];
		String name = e->token.string;
		if (name == "_") {
			continue;
		}
		if (name == parameter_name) {
			return i;
		}
	}
	return -1;
}
isize lookup_procedure_result(TypeProc *pt, String result_name) {
	isize result_count = pt->result_count;
	for (isize i = 0; i < result_count; i++) {
		Entity *e = pt->results->Tuple.variables[i];
		String name = e->token.string;
		if (name == "_") {
			continue;
		}
		if (name == result_name) {
			return i;
		}
	}
	return -1;
}

CALL_ARGUMENT_CHECKER(check_named_call_arguments) {
	ast_node(ce, CallExpr, call);
	GB_ASSERT(is_type_proc(proc_type));
	TypeProc *pt = &base_type(proc_type)->Proc;

	i64 score = 0;
	bool show_error = show_error_mode == CallArgumentMode_ShowErrors;
	CallArgumentError err = CallArgumentError_None;

	isize param_count = pt->param_count;
	bool *visited = gb_alloc_array(c->allocator, bool, param_count);

	for_array(i, ce->args) {
		AstNode *arg = ce->args[i];
		ast_node(fv, FieldValue, arg);
		if (fv->field->kind != AstNode_Ident) {
			if (show_error) {
				gbString expr_str = expr_to_string(fv->field);
				error(arg, "Invalid parameter name `%s` in procedure call", expr_str);
				gb_string_free(expr_str);
			}
			err = CallArgumentError_InvalidFieldValue;
			continue;
		}
		String name = fv->field->Ident.string;
		isize index = lookup_procedure_parameter(pt, name);
		if (index < 0) {
			if (show_error) {
				error(arg, "No parameter named `%.*s` for this procedure type", LIT(name));
			}
			err = CallArgumentError_ParameterNotFound;
			continue;
		}
		if (visited[index]) {
			if (show_error) {
				error(arg, "Duplicate parameter `%.*s` in procedure call", LIT(name));
			}
			err = CallArgumentError_DuplicateParameter;
			continue;
		}

		visited[index] = true;
		Operand *o = &operands[i];
		Entity *e = pt->params->Tuple.variables[index];

		if (e->kind == Entity_TypeName) {
			GB_ASSERT(pt->is_generic);
			GB_ASSERT(!pt->variadic);
			if (o->mode == Addressing_Invalid) {
				continue;
			} else if (o->mode != Addressing_Type) {
				error(o->expr, "Expected a type for the argument");
			}
			score += assign_score_function(1);
		} else {
			i64 s = 0;
			if (!check_is_assignable_to_with_score(c, o, e->type, &s)) {
				if (show_error) {
					check_assignment(c, o, e->type, str_lit("procedure argument"));
				}
				err = CallArgumentError_WrongTypes;
			}
			score += s;
		}
	}


#if 1
	isize param_count_to_check = param_count;
	if (pt->variadic) {
		param_count_to_check--;
	}
	for (isize i = 0; i < param_count_to_check; i++) {
		if (!visited[i]) {
			Entity *e = pt->params->Tuple.variables[i];
			if (e->token.string == "_") {
				continue;
			}
			GB_ASSERT(e->kind == Entity_Variable);
			if (e->Variable.default_value.kind != ExactValue_Invalid) {
				score += assign_score_function(1);
				continue;
			}

			if (e->Variable.default_is_nil) {
				score += assign_score_function(1);
				continue;
			}

			if (show_error) {
				gbString str = type_to_string(e->type);
				error(call, "Parameter `%.*s` of type `%s` is missing in procedure call",
				      LIT(e->token.string), str);
				gb_string_free(str);
			}
			err = CallArgumentError_ParameterMissing;
		}
	}
#endif

	if (pt->is_generic) {
		if (show_error) {
			error(call, "Generic procedures do not yet support named arguments");
		}
		err = CallArgumentError_GenericProcedureNotSupported;
	}

	if (score_) *score_ = score;

	return err;
}


Type *check_call_arguments(Checker *c, Operand *operand, Type *proc_type, AstNode *call) {
	ast_node(ce, CallExpr, call);

	CallArgumentCheckerType *call_checker = check_call_arguments_internal;
	Array<Operand> operands = {};
	defer (array_free(&operands));

	Type *result_type = t_invalid;

	if (is_call_expr_field_value(ce)) {
		call_checker = check_named_call_arguments;

		array_init_count(&operands, heap_allocator(), ce->args.count);
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			ast_node(fv, FieldValue, arg);
			check_expr_or_type(c, &operands[i], fv->value);
		}

		bool vari_expand = (ce->ellipsis.pos.line != 0);
		if (vari_expand) {
			error(ce->ellipsis, "Invalid use of `..` with `field = value` call`");
		}

	} else {
		array_init(&operands, heap_allocator(), 2*ce->args.count);
		check_unpack_arguments(c, -1, &operands, ce->args, false);
	}

	if (operand->mode == Addressing_Overload) {
		GB_ASSERT(operand->overload_entities != NULL &&
		          operand->overload_count > 0);
		isize              overload_count = operand->overload_count;
		Entity **          procs          = operand->overload_entities;
		ValidProcAndScore *valids         = gb_alloc_array(heap_allocator(), ValidProcAndScore, overload_count);
		isize              valid_count    = 0;

		defer (gb_free(heap_allocator(), procs));
		defer (gb_free(heap_allocator(), valids));

		String name = procs[0]->token.string;

		for (isize i = 0; i < overload_count; i++) {
			Entity *e = procs[i];
			DeclInfo *d = decl_info_of_entity(&c->info, e);
			GB_ASSERT(d != NULL);
			check_entity_decl(c, e, d, NULL);
		}

		for (isize i = 0; i < overload_count; i++) {
			Entity *p = procs[i];
			Type *pt = base_type(p->type);
			if (pt != NULL && is_type_proc(pt)) {
				i64 score = 0;
				CallArgumentError err = call_checker(c, call, pt, operands, CallArgumentMode_NoErrors, &score);
				if (err == CallArgumentError_None) {
					valids[valid_count].index = i;
					valids[valid_count].score = score;
					valid_count++;
				}
			}
		}

		if (valid_count > 1) {
			gb_sort_array(valids, valid_count, valid_proc_and_score_cmp);
			i64 best_score = valids[0].score;
			for (isize i = 0; i < valid_count; i++) {
				if (best_score > valids[i].score) {
					valid_count = i;
					break;
				}
				best_score = valids[i].score;
			}
		}


		if (valid_count == 0) {
			error(operand->expr, "No overloads for `%.*s` that match with the given arguments", LIT(name));
			result_type = t_invalid;
		} else if (valid_count > 1) {
			error(operand->expr, "Ambiguous procedure call `%.*s`, could be:", LIT(name));
			for (isize i = 0; i < valid_count; i++) {
				Entity *proc = procs[valids[i].index];
				TokenPos pos = proc->token.pos;
				gbString pt = type_to_string(proc->type);
				gb_printf_err("\t%.*s of type %s at %.*s(%td:%td) with score %lld\n", LIT(name), pt, LIT(pos.file), pos.line, pos.column, cast(long long)valids[i].score);
				gb_string_free(pt);
			}
			result_type = t_invalid;
		} else {
			AstNode *expr = operand->expr;
			while (expr->kind == AstNode_SelectorExpr) {
				expr = expr->SelectorExpr.selector;
			}
			GB_ASSERT(expr->kind == AstNode_Ident);
			Entity *e = procs[valids[0].index];
			add_entity_use(c, expr, e);
			proc_type = e->type;
			i64 score = 0;
			CallArgumentError err = call_checker(c, call, proc_type, operands, CallArgumentMode_ShowErrors, &score);

			if (proc_type != NULL && is_type_proc(proc_type)) {
				result_type = base_type(proc_type)->Proc.results;
			}
		}
	} else {
		i64 score = 0;
		CallArgumentError err = call_checker(c, call, proc_type, operands, CallArgumentMode_ShowErrors, &score);
		if (proc_type != NULL && is_type_proc(proc_type)) {
			result_type = base_type(proc_type)->Proc.results;
		}
	}

	return result_type;
}


Entity *find_using_index_expr(Type *t) {
	t = base_type(t);
	if (t->kind != Type_Record) {
		return NULL;
	}

	for (isize i = 0; i < t->Record.field_count; i++) {
		Entity *f = t->Record.fields[i];
		if (f->kind == Entity_Variable &&
		    (f->flags & EntityFlag_Field) != 0 &&
		    (f->flags & EntityFlag_Using) != 0) {
			if (is_type_indexable(f->type)) {
				return f;
			}
			Entity *res = find_using_index_expr(f->type);
			if (res != NULL) {
				return res;
			}
		}
	}
	return NULL;
}

ExprKind check_call_expr(Checker *c, Operand *operand, AstNode *call) {
	GB_ASSERT(call->kind == AstNode_CallExpr);
	ast_node(ce, CallExpr, call);
	if (ce->proc != NULL &&
	    ce->proc->kind == AstNode_BasicDirective) {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name;
		GB_ASSERT(name == "location");
		operand->mode = Addressing_Builtin;
		operand->builtin_id = BuiltinProc_DIRECTIVE;
		operand->expr = ce->proc;
		operand->type = t_invalid;
		add_type_and_value(&c->info, ce->proc, operand->mode, operand->type, operand->value);
	} else {
		check_expr_or_type(c, operand, ce->proc);
	}

	if (ce->args.count > 0) {
		bool fail = false;
		bool first_is_field_value = (ce->args[0]->kind == AstNode_FieldValue);
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
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
			operand->mode = Addressing_Invalid;
			operand->expr = call;
			return Expr_Stmt;
		}
	}

	if (operand->mode == Addressing_Invalid) {
		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			if (arg->kind == AstNode_FieldValue) {
				arg = arg->FieldValue.value;
			}
			check_expr_base(c, operand, arg, NULL);
		}
		operand->mode = Addressing_Invalid;
		operand->expr = call;
		return Expr_Stmt;
	}

	if (operand->mode == Addressing_Type) {
		Type *t = operand->type;
		gbString str = type_to_string(t);
		operand->mode = Addressing_Invalid;
		isize arg_count = ce->args.count;
		switch (arg_count) {
		case 0:  error(call, "Missing argument in conversion to `%s`", str);   break;
		default: error(call, "Too many arguments in conversion to `%s`", str); break;
		case 1: {
			AstNode *arg = ce->args[0];
			if (arg->kind == AstNode_FieldValue) {
				error(call, "`field = value` cannot be used in a type conversion");
				arg = arg->FieldValue.value;
				// NOTE(bill): Carry on the cast regardless
			}
			check_expr(c, operand, arg);
			if (operand->mode != Addressing_Invalid) {
				check_cast(c, operand, t);
			}
		} break;
		}

		gb_string_free(str);
		return Expr_Expr;
	}

	if (operand->mode == Addressing_Builtin) {
		i32 id = operand->builtin_id;
		if (!check_builtin_procedure(c, operand, call, id)) {
			operand->mode = Addressing_Invalid;
		}
		operand->expr = call;
		return builtin_procs[id].kind;
	}

	Type *proc_type = base_type(operand->type);
	if (operand->mode != Addressing_Overload) {
		bool valid_type = (proc_type != NULL) && is_type_proc(proc_type);
		bool valid_mode = is_operand_value(*operand);
		if (!valid_type || !valid_mode) {
			AstNode *e = operand->expr;
			gbString str = expr_to_string(e);
			gbString type_str = type_to_string(operand->type);
			error(e, "Cannot call a non-procedure: `%s` of type `%s`", str, type_str);
			gb_string_free(type_str);
			gb_string_free(str);

			operand->mode = Addressing_Invalid;
			operand->expr = call;

			return Expr_Stmt;
		}
	}

	Type *result_type = check_call_arguments(c, operand, proc_type, call);

	gb_zero_item(operand);
	operand->expr = call;

	if (result_type == t_invalid) {
		operand->mode = Addressing_Invalid;
		operand->type = t_invalid;
		return Expr_Stmt;
	}

	Type *pt = base_type(proc_type);
	bool results_are_generic = false;
	if (is_type_proc(pt) && pt->Proc.results != NULL) {
		results_are_generic = is_type_generic(pt->Proc.results);
	}
	if (results_are_generic) {
		operand->mode = Addressing_NoValue;
	} else if (result_type == NULL) {
		operand->mode = Addressing_NoValue;
	} else {
		GB_ASSERT(is_type_tuple(result_type));
		switch (result_type->Tuple.variable_count) {
		case 0:
			operand->mode = Addressing_NoValue;
			break;
		case 1:
			operand->mode = Addressing_Value;
			operand->type = result_type->Tuple.variables[0]->type;
			break;
		default:
			operand->mode = Addressing_Value;
			operand->type = result_type;
			break;
		}
	}

	operand->expr = call;
	return Expr_Expr;
}


ExprKind check_macro_call_expr(Checker *c, Operand *operand, AstNode *call) {
	GB_ASSERT(call->kind == AstNode_MacroCallExpr);
	ast_node(mce, MacroCallExpr, call);

	error(call, "Macro call expressions are not yet supported");
	operand->mode = Addressing_Invalid;
	operand->expr = call;
	return Expr_Stmt;
}

void check_expr_with_type_hint(Checker *c, Operand *o, AstNode *e, Type *t) {
	check_expr_base(c, o, e, t);
	check_not_tuple(c, o);
	char *err_str = NULL;
	switch (o->mode) {
	case Addressing_NoValue:
		err_str = "used as a value";
		break;
	case Addressing_Type:
		err_str = "is not an expression";
		break;
	case Addressing_Builtin:
		err_str = "must be called";
		break;
	}
	if (err_str != NULL) {
		gbString str = expr_to_string(e);
		error(e, "`%s` %s", str, err_str);
		gb_string_free(str);
		o->mode = Addressing_Invalid;
	}
}

void check_set_mode_with_indirection(Operand *o, bool indirection) {
	if (o->mode != Addressing_Immutable) {
		if (indirection) {
			o->mode = Addressing_Variable;
		} else if (o->mode != Addressing_Variable &&
		           o->mode != Addressing_Constant) {
			o->mode = Addressing_Value;
		}
	}
}

bool check_set_index_data(Operand *o, Type *type, bool indirection, i64 *max_count) {
	Type *t = base_type(type_deref(type));

	switch (t->kind) {
	case Type_Basic:
		if (is_type_string(t)) {
			if (o->mode == Addressing_Constant) {
				*max_count = o->value.value_string.len;
			}
			check_set_mode_with_indirection(o, indirection);
			o->type = t_u8;
			return true;
		}
		break;

	case Type_Array:
		*max_count = t->Array.count;
		check_set_mode_with_indirection(o, indirection);
		o->type = t->Array.elem;
		return true;

	case Type_Vector:
		*max_count = t->Vector.count;
		check_set_mode_with_indirection(o, indirection);
		o->type = t->Vector.elem;
		return true;


	case Type_Slice:
		o->type = t->Slice.elem;
		if (o->mode != Addressing_Immutable) {
			o->mode = Addressing_Variable;
		}
		return true;

	case Type_DynamicArray:
		o->type = t->DynamicArray.elem;
		check_set_mode_with_indirection(o, indirection);
		return true;
	}

	return false;
}


ExprKind check_expr_base_internal(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExprKind kind = Expr_Stmt;

	o->mode = Addressing_Invalid;
	o->type = t_invalid;

	switch (node->kind) {
	default:
		return kind;

	case_ast_node(be, BadExpr, node)
		return kind;
	case_end;

	case_ast_node(i, Implicit, node)
		switch (i->kind) {
		case Token_context:
			if (c->context.proc_name.len == 0) {
				error(node, "`context` is only allowed within procedures");
				return kind;
			}

			o->mode = Addressing_Value;
			o->type = t_context;
			break;
		default:
			error(node, "Illegal implicit name `%.*s`", LIT(i->string));
			return kind;
		}
	case_end;

	case_ast_node(i, Ident, node);
		check_ident(c, o, node, NULL, type_hint, false);
	case_end;


	case_ast_node(bl, BasicLit, node);
		Type *t = t_invalid;
		switch (bl->kind) {
		case Token_Integer: t = t_untyped_integer; break;
		case Token_Float:   t = t_untyped_float;   break;
		case Token_String:  t = t_untyped_string;  break;
		case Token_Rune:    t = t_untyped_rune;    break;
		case Token_Imag: {
			String s = bl->string;
			Rune r = s[s.len-1];
			switch (r) {
			case 'i': t = t_untyped_complex; break;
			}
		} break;
		default:            GB_PANIC("Unknown literal"); break;
		}
		o->mode  = Addressing_Constant;
		o->type  = t;
		o->value = exact_value_from_basic_literal(*bl);
	case_end;

	case_ast_node(bd, BasicDirective, node);
		if (bd->name == "file") {
			o->type = t_untyped_string;
			o->value = exact_value_string(bd->token.pos.file);
		} else if (bd->name == "line") {
			o->type = t_untyped_integer;
			o->value = exact_value_i64(bd->token.pos.line);
		} else if (bd->name == "procedure") {
			if (c->proc_stack.count == 0) {
				error(node, "#procedure may only be used within procedures");
				o->type = t_untyped_string;
				o->value = exact_value_string(str_lit(""));
			} else {
				o->type = t_untyped_string;
				o->value = exact_value_string(c->context.proc_name);
			}
		} else if (bd->name == "caller_location") {
			init_preload(c);
			error(node, "#caller_location may only be used as a default argument parameter");
			o->type = t_source_code_location;
			o->mode = Addressing_Value;
		} else {
			GB_PANIC("Unknown basic directive");
		}
		o->mode = Addressing_Constant;
	case_end;

	case_ast_node(pl, ProcLit, node);
		CheckerContext prev_context = c->context;
		DeclInfo *decl = NULL;
		Type *type = alloc_type(c->allocator, Type_Proc);
		check_open_scope(c, pl->type);
		{
			decl = make_declaration_info(c->allocator, c->context.scope, c->context.decl);
			decl->proc_decl = node;
			c->context.decl = decl;

			if (pl->tags != 0) {
				error(node, "A procedure literal cannot have tags");
				pl->tags = 0; // TODO(bill): Should I zero this?!
			}

			check_procedure_type(c, type, pl->type);
			if (!is_type_proc(type)) {
				gbString str = expr_to_string(node);
				error(node, "Invalid procedure literal `%s`", str);
				gb_string_free(str);
				check_close_scope(c);
				return kind;
			}
			check_procedure_later(c, c->curr_ast_file, empty_token, decl, type, pl->body, pl->tags);
		}
		check_close_scope(c);

		c->context = prev_context;

		o->mode = Addressing_Value;
		o->type = type;
	case_end;

	case_ast_node(te, TernaryExpr, node);
		Operand cond = {Addressing_Invalid};
		check_expr(c, &cond, te->cond);
		if (cond.mode != Addressing_Invalid && !is_type_boolean(cond.type)) {
			error(te->cond, "Non-boolean condition in if expression");
		}

		Operand x = {Addressing_Invalid};
		Operand y = {Addressing_Invalid};
		check_expr_with_type_hint(c, &x, te->x, type_hint);

		if (te->y != NULL) {
			check_expr_with_type_hint(c, &y, te->y, type_hint);
		} else {
			error(node, "A ternary expression must have an else clause");
			return kind;
		}

		if (x.type == NULL || x.type == t_invalid ||
		    y.type == NULL || y.type == t_invalid) {
			return kind;
		}

		convert_to_typed(c, &x, y.type, 0);
		if (x.mode == Addressing_Invalid) {
			return kind;
		}
		convert_to_typed(c, &y, x.type, 0);
		if (y.mode == Addressing_Invalid) {
			x.mode = Addressing_Invalid;
			return kind;
		}


		if (!are_types_identical(x.type, y.type)) {
			gbString its = type_to_string(x.type);
			gbString ets = type_to_string(y.type);
			error(node, "Mismatched types in ternary expression, %s vs %s", its, ets);
			gb_string_free(ets);
			gb_string_free(its);
			return kind;
		}

		o->type = x.type;
		o->mode = Addressing_Value;

		if (cond.mode == Addressing_Constant && is_type_boolean(cond.type) &&
		    x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant) {

			o->mode = Addressing_Constant;

			if (cond.value.value_bool) {
				o->value = x.value;
			} else {
				o->value = y.value;
			}
		}

	case_end;

	case_ast_node(cl, CompoundLit, node);
		Type *type = type_hint;
		bool is_to_be_determined_array_count = false;
		bool is_constant = true;
		if (cl->type != NULL) {
			type = NULL;

			// [..]Type
			if (cl->type->kind == AstNode_ArrayType && cl->type->ArrayType.count != NULL) {
				AstNode *count = cl->type->ArrayType.count;
				if (count->kind == AstNode_UnaryExpr &&
				    count->UnaryExpr.op.kind == Token_Ellipsis) {
					type = make_type_array(c->allocator, check_type(c, cl->type->ArrayType.elem), -1);
					is_to_be_determined_array_count = true;
				}
			}

			if (type == NULL) {
				type = check_type(c, cl->type);
			}
		}

		if (type == NULL) {
			error(node, "Missing type in compound literal");
			return kind;
		}

		Type *t = base_type(type);
		switch (t->kind) {
		case Type_Record: {
			if (!is_type_struct(t) && !is_type_union(t)) {
				if (cl->elems.count != 0) {
					gbString type_str = type_to_string(type);
					error(node, "Illegal compound literal type `%s`", type_str);
					gb_string_free(type_str);
				}
				break;
			}
			if (is_type_union(t)) {
				is_constant = false;
			}
			if (cl->elems.count == 0) {
				break; // NOTE(bill): No need to init
			}
			{ // Checker values
				isize field_count = t->Record.field_count;
				if (cl->elems[0]->kind == AstNode_FieldValue) {
					bool *fields_visited = gb_alloc_array(c->allocator, bool, field_count);

					for_array(i, cl->elems) {
						AstNode *elem = cl->elems[i];
						if (elem->kind != AstNode_FieldValue) {
							error(elem, "Mixture of `field = value` and value elements in a structure literal is not allowed");
							continue;
						}
						ast_node(fv, FieldValue, elem);
						if (fv->field->kind != AstNode_Ident) {
							gbString expr_str = expr_to_string(fv->field);
							error(elem, "Invalid field name `%s` in structure literal", expr_str);
							gb_string_free(expr_str);
							continue;
						}
						String name = fv->field->Ident.string;

						Selection sel = lookup_field(c->allocator, type, name, o->mode == Addressing_Type);
						bool is_unknown = sel.entity == NULL;
						if (is_unknown) {
							error(elem, "Unknown field `%.*s` in structure literal", LIT(name));
							continue;
						}
						if (!is_unknown && !check_is_field_exported(c, sel.entity)) {
							error(elem, "Cannot assign to an unexported field `%.*s` in structure literal", LIT(name));
							continue;
						}


						if (sel.index.count > 1) {
							error(elem, "Cannot assign to an anonymous field `%.*s` in a structure literal (at the moment)", LIT(name));
							continue;
						}

						Entity *field = t->Record.fields[sel.index[0]];
						add_entity_use(c, fv->field, field);

						if (fields_visited[sel.index[0]]) {
							error(elem, "Duplicate field `%.*s` in structure literal", LIT(name));
							continue;
						}

						fields_visited[sel.index[0]] = true;
						check_expr(c, o, fv->value);

						if (is_type_any(field->type) || is_type_union(field->type) || is_type_raw_union(field->type)) {
							is_constant = false;
						}
						if (is_constant) {
							is_constant = o->mode == Addressing_Constant;
						}


						check_assignment(c, o, field->type, str_lit("structure literal"));
					}
				} else {
					bool all_fields_are_blank = true;
					for (isize i = 0; i < t->Record.field_count; i++) {
						Entity *field = t->Record.fields_in_src_order[i];
						if (field->token.string != "_") {
							all_fields_are_blank = false;
							break;
						}
					}

					for_array(index, cl->elems) {
						AstNode *elem = cl->elems[index];
						if (elem->kind == AstNode_FieldValue) {
							error(elem, "Mixture of `field = value` and value elements in a structure literal is not allowed");
							continue;
						}
						if (index >= field_count) {
							error(o->expr, "Too many values in structure literal, expected %td", field_count);
							break;
						}

						Entity *field = t->Record.fields_in_src_order[index];
						if (!all_fields_are_blank && field->token.string == "_") {
							// NOTE(bill): Ignore blank identifiers
							continue;
						}
						check_expr(c, o, elem);

						if (!check_is_field_exported(c, field)) {
							gbString t = type_to_string(type);
							error(o->expr, "Implicit assignment to an unexported field `%.*s` in `%s` literal",
							           LIT(field->token.string), t);
							gb_string_free(t);
							continue;
						}

						if (is_type_any(field->type) || is_type_union(field->type) || is_type_raw_union(field->type)) {
							is_constant = false;
						}
						if (is_constant) {
							is_constant = o->mode == Addressing_Constant;
						}

						check_assignment(c, o, field->type, str_lit("structure literal"));
					}
					if (cl->elems.count < field_count) {
						error(cl->close, "Too few values in structure literal, expected %td, got %td", field_count, cl->elems.count);
					}
				}
			}
		} break;

		case Type_Slice:
		case Type_Array:
		case Type_Vector:
		case Type_DynamicArray:
		{
			Type *elem_type = NULL;
			String context_name = {};
			i64 max_type_count = -1;
			if (t->kind == Type_Slice) {
				elem_type = t->Slice.elem;
				context_name = str_lit("slice literal");
			} else if (t->kind == Type_Vector) {
				elem_type = t->Vector.elem;
				context_name = str_lit("vector literal");
				max_type_count = t->Vector.count;
			} else if (t->kind == Type_Array) {
				elem_type = t->Array.elem;
				context_name = str_lit("array literal");
				max_type_count = t->Array.count;
			} else if (t->kind == Type_DynamicArray) {
				elem_type = t->DynamicArray.elem;
				context_name = str_lit("dynamic array literal");
				is_constant = false;
			} else {
				GB_PANIC("unreachable");
			}


			i64 max = 0;
			isize index = 0;
			isize elem_count = cl->elems.count;

			if (is_type_any(base_type(elem_type))) {
				is_constant = false;
			}

			for (; index < elem_count; index++) {
				GB_ASSERT(cl->elems.data != NULL);
				AstNode *e = cl->elems[index];
				if (e == NULL) {
					error(node, "Invalid literal element");
					continue;
				}

				if (e->kind == AstNode_FieldValue) {
					error(e, "`field = value` is only allowed in struct literals");
					continue;
				}

				if (0 <= max_type_count && max_type_count <= index) {
					error(e, "Index %lld is out of bounds (>= %lld) for %.*s", index, max_type_count, LIT(context_name));
				}

				Operand operand = {};
				check_expr_with_type_hint(c, &operand, e, elem_type);
				check_assignment(c, &operand, elem_type, context_name);

				if (is_constant) {
					is_constant = operand.mode == Addressing_Constant;
				}
			}
			if (max < index) {
				max = index;
			}

			if (t->kind == Type_Vector) {
				if (t->Vector.count > 1 && gb_is_between(index, 2, t->Vector.count-1)) {
					error(cl->elems[0], "Expected either 1 (broadcast) or %td elements in vector literal, got %td", t->Vector.count, index);
				}
			}

			if (t->kind == Type_Array && is_to_be_determined_array_count) {
				t->Array.count = max;
			}
		} break;

		case Type_Basic: {
			if (!is_type_any(t)) {
				if (cl->elems.count != 0) {
					error(node, "Illegal compound literal");
				}
				break;
			}
			if (cl->elems.count == 0) {
				break; // NOTE(bill): No need to init
			}
			{ // Checker values
				Type *field_types[2] = {t_rawptr, t_type_info_ptr};
				isize field_count = 2;
				if (cl->elems[0]->kind == AstNode_FieldValue) {
					bool fields_visited[2] = {};

					for_array(i, cl->elems) {
						AstNode *elem = cl->elems[i];
						if (elem->kind != AstNode_FieldValue) {
							error(elem, "Mixture of `field = value` and value elements in a `any` literal is not allowed");
							continue;
						}
						ast_node(fv, FieldValue, elem);
						if (fv->field->kind != AstNode_Ident) {
							gbString expr_str = expr_to_string(fv->field);
							error(elem, "Invalid field name `%s` in `any` literal", expr_str);
							gb_string_free(expr_str);
							continue;
						}
						String name = fv->field->Ident.string;

						Selection sel = lookup_field(c->allocator, type, name, o->mode == Addressing_Type);
						if (sel.entity == NULL) {
							error(elem, "Unknown field `%.*s` in `any` literal", LIT(name));
							continue;
						}

						isize index = sel.index[0];

						if (fields_visited[index]) {
							error(elem, "Duplicate field `%.*s` in `any` literal", LIT(name));
							continue;
						}

						fields_visited[index] = true;
						check_expr(c, o, fv->value);

						// NOTE(bill): `any` literals can never be constant
						is_constant = false;

						check_assignment(c, o, field_types[index], str_lit("`any` literal"));
					}
				} else {
					for_array(index, cl->elems) {
						AstNode *elem = cl->elems[index];
						if (elem->kind == AstNode_FieldValue) {
							error(elem, "Mixture of `field = value` and value elements in a `any` literal is not allowed");
							continue;
						}


						check_expr(c, o, elem);
						if (index >= field_count) {
							error(o->expr, "Too many values in `any` literal, expected %td", field_count);
							break;
						}

						// NOTE(bill): `any` literals can never be constant
						is_constant = false;

						check_assignment(c, o, field_types[index], str_lit("`any` literal"));
					}
					if (cl->elems.count < field_count) {
						error(cl->close, "Too few values in `any` literal, expected %td, got %td", field_count, cl->elems.count);
					}
				}
			}
		} break;

		case Type_Map: {
			if (cl->elems.count == 0) {
				break;
			}
			is_constant = false;
			{ // Checker values
				for_array(i, cl->elems) {
					AstNode *elem = cl->elems[i];
					if (elem->kind != AstNode_FieldValue) {
						error(elem, "Only `field = value` elements are allowed in a map literal");
						continue;
					}
					ast_node(fv, FieldValue, elem);
					check_expr_with_type_hint(c, o, fv->field, t->Map.key);
					check_assignment(c, o, t->Map.key, str_lit("map literal"));
					if (o->mode == Addressing_Invalid) {
						continue;
					}

					check_expr_with_type_hint(c, o, fv->value, t->Map.value);
					check_assignment(c, o, t->Map.value, str_lit("map literal"));
				}
			}
		} break;

		default: {
			gbString str = type_to_string(type);
			error(node, "Invalid compound literal type `%s`", str);
			gb_string_free(str);
			return kind;
		} break;
		}

		if (is_constant) {
			o->mode = Addressing_Constant;
			o->value = exact_value_compound(node);
		} else {
			o->mode = Addressing_Value;
		}
		o->type = type;
	case_end;

	case_ast_node(pe, ParenExpr, node);
		kind = check_expr_base(c, o, pe->expr, type_hint);
		o->expr = node;
	case_end;

	case_ast_node(te, TagExpr, node);
		String name = te->name.string;
		error(node, "Unknown tag expression, #%.*s", LIT(name));
		if (te->expr) {
			kind = check_expr_base(c, o, te->expr, type_hint);
		}
		o->expr = node;
	case_end;

	case_ast_node(re, RunExpr, node);
		// TODO(bill): Tag expressions
		kind = check_expr_base(c, o, re->expr, type_hint);
		o->expr = node;
	case_end;

	case_ast_node(ta, TypeAssertion, node);
		check_expr(c, o, ta->expr);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
		Type *t = check_type(c, ta->type);

		if (o->mode == Addressing_Constant) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "A type assertion cannot be applied to a constant expression: `%s`", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (is_type_untyped(o->type)) {
			gbString expr_str = expr_to_string(o->expr);
			error(o->expr, "A type assertion cannot be applied to an untyped expression: `%s`", expr_str);
			gb_string_free(expr_str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}


		bool src_is_ptr = is_type_pointer(o->type);
		bool dst_is_ptr = is_type_pointer(t);
		Type *src = type_deref(o->type);
		Type *dst = type_deref(t);
		Type *bsrc = base_type(src);
		Type *bdst = base_type(dst);

		if (src_is_ptr != dst_is_ptr) {
			gbString src_type_str = type_to_string(o->type);
			gbString dst_type_str = type_to_string(t);
			error(o->expr, "Invalid type assertion types: `%s` and `%s`", src_type_str, dst_type_str);
			gb_string_free(dst_type_str);
			gb_string_free(src_type_str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (is_type_union(src)) {
			bool ok = false;
			for (isize i = 1; i < bsrc->Record.variant_count; i++) {
				Entity *f = bsrc->Record.variants[i];
				if (are_types_identical(f->type, dst)) {
					ok = true;
					break;
				}
			}

			if (!ok) {
				gbString expr_str = expr_to_string(o->expr);
				gbString dst_type_str = type_to_string(t);
				error(o->expr, "Cannot type assert `%s` to `%s`", expr_str, dst_type_str);
				gb_string_free(dst_type_str);
				gb_string_free(expr_str);
				o->mode = Addressing_Invalid;
				o->expr = node;
				return kind;
			}

			add_type_info_type(c, o->type);
			add_type_info_type(c, t);

			o->type = t;
			o->mode = Addressing_OptionalOk;
		} else if (is_type_any(o->type)) {
			o->type = t;
			o->mode = Addressing_OptionalOk;

			add_type_info_type(c, o->type);
			add_type_info_type(c, t);
		} else {
			error(o->expr, "Type assertions can only operate on unions");
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}
	case_end;

	case_ast_node(ue, UnaryExpr, node);
		check_expr_base(c, o, ue->expr, type_hint);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
		check_unary_expr(c, o, ue->op, node);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
	case_end;


	case_ast_node(be, BinaryExpr, node);
		check_binary_expr(c, o, node);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}
	case_end;



	case_ast_node(se, SelectorExpr, node);
		check_selector(c, o, node, type_hint);
	case_end;


	case_ast_node(ie, IndexExpr, node);
		check_expr(c, o, ie->expr);
		if (o->mode == Addressing_Invalid) {
			o->expr = node;
			return kind;
		}

		Type *t = base_type(type_deref(o->type));
		bool is_ptr = is_type_pointer(o->type);
		bool is_const = o->mode == Addressing_Constant;

		if (is_type_map(t)) {
			Operand key = {};
			check_expr(c, &key, ie->index);
			check_assignment(c, &key, t->Map.key, str_lit("map index"));
			if (key.mode == Addressing_Invalid) {
				o->mode = Addressing_Invalid;
				o->expr = node;
				return kind;
			}
			o->mode = Addressing_MapIndex;
			o->type = t->Map.value;
			o->expr = node;
			return Expr_Expr;
		}

		i64 max_count = -1;
		bool valid = check_set_index_data(o, t, is_ptr, &max_count);

		if (is_const) {
			valid = false;
		}

		if (!valid && (is_type_struct(t) || is_type_raw_union(t))) {
			Entity *found = find_using_index_expr(t);
			if (found != NULL) {
				valid = check_set_index_data(o, found->type, is_type_pointer(found->type), &max_count);
			}
		}

		if (!valid) {
			gbString str = expr_to_string(o->expr);
			if (is_const) {
				error(o->expr, "Cannot index a constant `%s`", str);
			} else {
				error(o->expr, "Cannot index `%s`", str);
			}
			gb_string_free(str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (ie->index == NULL) {
			gbString str = expr_to_string(o->expr);
			error(o->expr, "Missing index for `%s`", str);
			gb_string_free(str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		i64 index = 0;
		bool ok = check_index_value(c, false, ie->index, max_count, &index);

	case_end;



	case_ast_node(se, SliceExpr, node);
		check_expr(c, o, se->expr);
		if (o->mode == Addressing_Invalid) {
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		bool valid = false;
		i64 max_count = -1;
		Type *t = base_type(type_deref(o->type));
		switch (t->kind) {
		case Type_Basic:
			if (is_type_string(t)) {
				if (se->index3) {
					error(node, "3-index slice on a string in not needed");
					o->mode = Addressing_Invalid;
					o->expr = node;
					return kind;
				}
				valid = true;
				if (o->mode == Addressing_Constant) {
					max_count = o->value.value_string.len;
				}
				o->type = t_string;
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->Array.count;
			if (o->mode != Addressing_Variable) {
				gbString str = expr_to_string(node);
				error(node, "Cannot slice array `%s`, value is not addressable", str);
				gb_string_free(str);
				o->mode = Addressing_Invalid;
				o->expr = node;
				return kind;
			}
			o->type = make_type_slice(c->allocator, t->Array.elem);
			break;

		case Type_Slice:
			valid = true;
			break;

		case Type_DynamicArray:
			valid = true;
			o->type = make_type_slice(c->allocator, t->DynamicArray.elem);
			break;
		}

		if (!valid) {
			gbString str = expr_to_string(o->expr);
			error(o->expr, "Cannot slice `%s`", str);
			gb_string_free(str);
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (o->mode != Addressing_Immutable) {
			o->mode = Addressing_Value;
		}

		if (se->low == NULL && se->high != NULL) {
			error(se->interval0, "1st index is required if a 2nd index is specified");
			// It is okay to continue as it will assume the 1st index is zero
		}

		if (se->index3 && (se->high == NULL || se->max == NULL)) {
			error(se->close, "2nd and 3rd indices are required in a 3-index slice");
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}

		if (se->index3 && se->interval0.kind != se->interval1.kind) {
			error(se->close, "The interval separators for in a 3-index slice must be the same");
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		}


		TokenKind interval_kind = se->interval0.kind;

		i64 indices[2] = {};
		AstNode *nodes[3] = {se->low, se->high, se->max};
		for (isize i = 0; i < gb_count_of(nodes); i++) {
			i64 index = max_count;
			if (nodes[i] != NULL) {
				i64 capacity = -1;
				if (max_count >= 0) {
					capacity = max_count;
				}
				i64 j = 0;
				if (check_index_value(c, interval_kind == Token_Ellipsis, nodes[i], capacity, &j)) {
					index = j;
				}
			} else if (i == 0) {
				index = 0;
			}
			indices[i] = index;
		}

		for (isize i = 0; i < gb_count_of(indices); i++) {
			i64 a = indices[i];
			for (isize j = i+1; j < gb_count_of(indices); j++) {
				i64 b = indices[j];
				if (a > b && b >= 0) {
					error(se->close, "Invalid slice indices: [%td > %td]", a, b);
				}
			}
		}

	case_end;


	case_ast_node(ce, CallExpr, node);
		return check_call_expr(c, o, node);
	case_end;

	case_ast_node(ce, MacroCallExpr, node);
		return check_macro_call_expr(c, o, node);
	case_end;

	case_ast_node(de, DerefExpr, node);
		check_expr_or_type(c, o, de->expr);
		if (o->mode == Addressing_Invalid) {
			o->mode = Addressing_Invalid;
			o->expr = node;
			return kind;
		} else {
			Type *t = base_type(o->type);
			if (t->kind == Type_Pointer) {
				if (o->mode != Addressing_Immutable) {
					o->mode = Addressing_Variable;
				}
				o->type = t->Pointer.elem;
 			} else {
 				gbString str = expr_to_string(o->expr);
 				error(o->expr, "Cannot dereference `%s`", str);
 				gb_string_free(str);
 				o->mode = Addressing_Invalid;
 				o->expr = node;
 				return kind;
 			}
		}
	case_end;

	case AstNode_HelperType:
	case AstNode_ProcType:
	case AstNode_PointerType:
	case AstNode_ArrayType:
	case AstNode_DynamicArrayType:
	case AstNode_VectorType:
	case AstNode_StructType:
	case AstNode_UnionType:
	case AstNode_RawUnionType:
	case AstNode_EnumType:
	case AstNode_MapType:
		o->mode = Addressing_Type;
		o->type = check_type(c, node);
		break;
	}

	kind = Expr_Expr;
	o->expr = node;
	return kind;
}

ExprKind check_expr_base(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExprKind kind = check_expr_base_internal(c, o, node, type_hint);
	Type *type = NULL;
	ExactValue value = {ExactValue_Invalid};
	switch (o->mode) {
	case Addressing_Invalid:
		type = t_invalid;
		break;
	case Addressing_NoValue:
		type = NULL;
		break;
	case Addressing_Constant:
		type = o->type;
		value = o->value;
		break;
	default:
		type = o->type;
		break;
	}

	if (type != NULL && is_type_untyped(type)) {
		add_untyped(&c->info, node, false, o->mode, type, value);
	} else {
		add_type_and_value(&c->info, node, o->mode, type, value);
	}
	return kind;
}



void check_multi_expr(Checker *c, Operand *o, AstNode *e) {
	check_expr_base(c, o, e, NULL);
	switch (o->mode) {
	default:
		return; // NOTE(bill): Valid
	case Addressing_NoValue:
		error_operand_no_value(o);
		break;
	case Addressing_Type:
		error_operand_not_expression(o);
		break;
	}
	o->mode = Addressing_Invalid;
}

void check_not_tuple(Checker *c, Operand *o) {
	if (o->mode == Addressing_Value) {
		// NOTE(bill): Tuples are not first class thus never named
		if (o->type->kind == Type_Tuple) {
			isize count = o->type->Tuple.variable_count;
			GB_ASSERT(count != 1);
			error(o->expr,
			      "%td-valued tuple found where single value expected", count);
			o->mode = Addressing_Invalid;
		}
	}
}

void check_expr(Checker *c, Operand *o, AstNode *e) {
	check_multi_expr(c, o, e);
	check_not_tuple(c, o);
}


void check_expr_or_type(Checker *c, Operand *o, AstNode *e) {
	check_expr_base(c, o, e, NULL);
	check_not_tuple(c, o);
	error_operand_no_value(o);
}


gbString write_expr_to_string(gbString str, AstNode *node);

gbString write_record_fields_to_string(gbString str, Array<AstNode *> params) {
	for_array(i, params) {
		if (i > 0) {
			str = gb_string_appendc(str, ", ");
		}
		str = write_expr_to_string(str, params[i]);
	}
	return str;
}

gbString string_append_token(gbString str, Token token) {
	if (token.string.len > 0) {
		return gb_string_append_length(str, &token.string[0], token.string.len);
	}
	return str;
}


gbString write_expr_to_string(gbString str, AstNode *node) {
	if (node == NULL)
		return str;

	if (is_ast_node_stmt(node)) {
		GB_ASSERT("stmt passed to write_expr_to_string");
	}

	switch (node->kind) {
	default:
		str = gb_string_appendc(str, "(BadExpr)");
		break;

	case_ast_node(i, Ident, node);
		str = string_append_token(str, *i);
	case_end;

	case_ast_node(i, Implicit, node);
		str = string_append_token(str, *i);
	case_end;

	case_ast_node(bl, BasicLit, node);
		str = string_append_token(str, *bl);
	case_end;

	case_ast_node(bd, BasicDirective, node);
		str = gb_string_appendc(str, "#");
		str = gb_string_append_length(str, &bd->name[0], bd->name.len);
	case_end;

	case_ast_node(pl, ProcLit, node);
		str = write_expr_to_string(str, pl->type);
	case_end;

	case_ast_node(cl, CompoundLit, node);
		str = write_expr_to_string(str, cl->type);
		str = gb_string_appendc(str, "{");
		for_array(i, cl->elems) {
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, cl->elems[i]);
		}
		str = gb_string_appendc(str, "}");
	case_end;


	case_ast_node(te, TagExpr, node);
		str = gb_string_appendc(str, "#");
		str = string_append_token(str, te->name);
		str = write_expr_to_string(str, te->expr);
	case_end;

	case_ast_node(ue, UnaryExpr, node);
		str = string_append_token(str, ue->op);
		str = write_expr_to_string(str, ue->expr);
	case_end;

	case_ast_node(de, DerefExpr, node);
		str = write_expr_to_string(str, de->expr);
		str = gb_string_appendc(str, "^");
	case_end;

	case_ast_node(be, BinaryExpr, node);
		str = write_expr_to_string(str, be->left);
		str = gb_string_appendc(str, " ");
		str = string_append_token(str, be->op);
		str = gb_string_appendc(str, " ");
		str = write_expr_to_string(str, be->right);
	case_end;

	case_ast_node(pe, ParenExpr, node);
		str = gb_string_appendc(str, "(");
		str = write_expr_to_string(str, pe->expr);
		str = gb_string_appendc(str, ")");
	case_end;

	case_ast_node(se, SelectorExpr, node);
		str = write_expr_to_string(str, se->expr);
		str = gb_string_appendc(str, ".");
		str = write_expr_to_string(str, se->selector);
	case_end;

	case_ast_node(ta, TypeAssertion, node);
		str = write_expr_to_string(str, ta->expr);
		str = gb_string_appendc(str, ".(");
		str = write_expr_to_string(str, ta->type);
		str = gb_string_appendc(str, ")");
	case_end;

	case_ast_node(ie, IndexExpr, node);
		str = write_expr_to_string(str, ie->expr);
		str = gb_string_appendc(str, "[");
		str = write_expr_to_string(str, ie->index);
		str = gb_string_appendc(str, "]");
	case_end;

	case_ast_node(se, SliceExpr, node);
		str = write_expr_to_string(str, se->expr);
		str = gb_string_appendc(str, "[");
		str = write_expr_to_string(str, se->low);
		str = gb_string_appendc(str, "..");
		str = write_expr_to_string(str, se->high);
		if (se->index3) {
			str = gb_string_appendc(str, "..");
			str = write_expr_to_string(str, se->max);
		}
		str = gb_string_appendc(str, "]");
	case_end;

	case_ast_node(e, Ellipsis, node);
		str = gb_string_appendc(str, "..");
	case_end;

	case_ast_node(fv, FieldValue, node);
		str = write_expr_to_string(str, fv->field);
		str = gb_string_appendc(str, " = ");
		str = write_expr_to_string(str, fv->value);
	case_end;

	case_ast_node(pt, PointerType, node);
		str = gb_string_appendc(str, "^");
		str = write_expr_to_string(str, pt->type);
	case_end;

	case_ast_node(at, ArrayType, node);
		str = gb_string_appendc(str, "[");
		if (at->count != NULL &&
		    at->count->kind == AstNode_UnaryExpr &&
		    at->count->UnaryExpr.op.kind == Token_Ellipsis) {
			str = gb_string_appendc(str, "..");
		} else {
			str = write_expr_to_string(str, at->count);
		}
		str = gb_string_appendc(str, "]");
		str = write_expr_to_string(str, at->elem);
	case_end;

	case_ast_node(at, DynamicArrayType, node);
		str = gb_string_appendc(str, "[..]");
		str = write_expr_to_string(str, at->elem);
	case_end;

	case_ast_node(vt, VectorType, node);
		str = gb_string_appendc(str, "[vector ");
		str = write_expr_to_string(str, vt->count);
		str = gb_string_appendc(str, "]");
		str = write_expr_to_string(str, vt->elem);
	case_end;

	case_ast_node(f, Field, node);
		if (f->flags&FieldFlag_using) {
			str = gb_string_appendc(str, "using ");
		}
		if (f->flags&FieldFlag_no_alias) {
			str = gb_string_appendc(str, "#no_alias ");
		}
		if (f->flags&FieldFlag_c_vararg) {
			str = gb_string_appendc(str, "#c_vararg ");
		}

		for_array(i, f->names) {
			AstNode *name = f->names[i];
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, name);
		}
		if (f->names.count > 0) {
			str = gb_string_appendc(str, ": ");
		}
		if (f->flags&FieldFlag_ellipsis) {
			str = gb_string_appendc(str, "..");
		}
		str = write_expr_to_string(str, f->type);
	case_end;

	case_ast_node(f, FieldList, node);
		bool has_name = false;
		for_array(i, f->list) {
			ast_node(field, Field, f->list[i]);
			if (field->names.count > 1) {
				has_name = true;
				break;
			}

			if (field->names.count == 0) {
				continue;
			}
			AstNode *name = field->names[0];
			ast_node(n, Ident, name);
			if (n->string != "_") {
				has_name = true;
				break;
			}
		}


		for_array(i, f->list) {
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			if (has_name) {
				str = write_expr_to_string(str, f->list[i]);
			} else {
				ast_node(field, Field, f->list[i]);

				if (field->flags&FieldFlag_using) {
					str = gb_string_appendc(str, "using ");
				}
				if (field->flags&FieldFlag_no_alias) {
					str = gb_string_appendc(str, "#no_alias ");
				}
				if (field->flags&FieldFlag_c_vararg) {
					str = gb_string_appendc(str, "#c_vararg ");
				}

				str = write_expr_to_string(str, field->type);
			}
		}
	case_end;

	case_ast_node(f, UnionField, node);
		str = write_expr_to_string(str, f->name);
		str = gb_string_appendc(str, "{");
		str = write_expr_to_string(str, f->list);
		str = gb_string_appendc(str, "}");
	case_end;

	case_ast_node(ce, CallExpr, node);
		str = write_expr_to_string(str, ce->proc);
		str = gb_string_appendc(str, "(");

		for_array(i, ce->args) {
			AstNode *arg = ce->args[i];
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, arg);
		}
		str = gb_string_appendc(str, ")");
	case_end;

	case_ast_node(pt, ProcType, node);
		str = gb_string_appendc(str, "proc(");
		str = write_expr_to_string(str, pt->params);
		str = gb_string_appendc(str, ")");
		if (pt->results != NULL) {
			str = gb_string_appendc(str, " -> ");
			str = write_expr_to_string(str, pt->results);
		}

	case_end;

	case_ast_node(st, StructType, node);
		str = gb_string_appendc(str, "struct ");
		if (st->is_packed)  str = gb_string_appendc(str, "#packed ");
		if (st->is_ordered) str = gb_string_appendc(str, "#ordered ");
		str = gb_string_appendc(str, "{");
		str = write_record_fields_to_string(str, st->fields);
		str = gb_string_appendc(str, "}");
	case_end;

	case_ast_node(st, RawUnionType, node);
		str = gb_string_appendc(str, "raw_union ");
		str = gb_string_appendc(str, "{");
		str = write_record_fields_to_string(str, st->fields);
		str = gb_string_appendc(str, "}");
	case_end;

	case_ast_node(st, UnionType, node);
		str = gb_string_appendc(str, "union ");
		str = gb_string_appendc(str, "{");
		str = write_record_fields_to_string(str, st->fields);
		str = gb_string_appendc(str, "}");
	case_end;

	case_ast_node(et, EnumType, node);
		str = gb_string_appendc(str, "enum ");
		if (et->base_type != NULL) {
			str = write_expr_to_string(str, et->base_type);
			str = gb_string_appendc(str, " ");
		}
		str = gb_string_appendc(str, "{");
		for_array(i, et->fields) {
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, et->fields[i]);
		}
		str = gb_string_appendc(str, "}");
	case_end;

	case_ast_node(at, AtomicType, node);
		str = gb_string_appendc(str, "atomic ");
		str = write_expr_to_string(str, at->type);
	case_end;
	}

	return str;
}

gbString expr_to_string(AstNode *expression) {
	return write_expr_to_string(gb_string_make(heap_allocator(), ""), expression);
}
