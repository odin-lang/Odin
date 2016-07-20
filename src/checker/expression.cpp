void           check_assignment        (Checker *c, Operand *operand, Type *type, String context_name);
b32            check_is_assignable_to  (Checker *c, Operand *operand, Type *type);
void           check_expression        (Checker *c, Operand *operand, AstNode *expression);
void           check_multi_expression  (Checker *c, Operand *operand, AstNode *expression);
void           check_expression_or_type(Checker *c, Operand *operand, AstNode *expression);
ExpressionKind check_expression_base   (Checker *c, Operand *operand, AstNode *expression, Type *type_hint = NULL);
Type *         check_type              (Checker *c, AstNode *expression, Type *named_type = NULL);
void           check_selector          (Checker *c, Operand *operand, AstNode *node);
void           check_not_tuple         (Checker *c, Operand *operand);
void           convert_to_typed        (Checker *c, Operand *operand, Type *target_type);
gbString       expression_to_string    (AstNode *expression);
void           check_entity_declaration(Checker *c, Entity *e, Type *named_type);


void check_struct_type(Checker *c, Type *struct_type, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_StructType);
	GB_ASSERT(struct_type->kind == Type_Structure);
	auto *st = &node->struct_type;
	if (st->field_count == 0) {
		checker_err(c, ast_node_token(node), "Empty struct{} definition");
		return;
	}

	Map<Entity *> entity_map = {};
	map_init(&entity_map, gb_heap_allocator());
	defer (map_destroy(&entity_map));

	isize field_count = 0;
	for (AstNode *field = st->field_list; field != NULL; field = field->next) {
		for (AstNode *name = field->field.name_list; name != NULL; name = name->next) {
			GB_ASSERT(name->kind == AstNode_Identifier);
			field_count++;
		}
	}

	Entity **fields = gb_alloc_array(c->allocator, Entity *, st->field_count);
	isize field_index = 0;
	for (AstNode *field = st->field_list; field != NULL; field = field->next) {
		Type *type = check_type(c, field->field.type_expression);
		for (AstNode *name = field->field.name_list; name != NULL; name = name->next) {
			GB_ASSERT(name->kind == AstNode_Identifier);
			Token name_token = name->identifier.token;
			// TODO(bill): is the curr_scope correct?
			Entity *e = make_entity_field(c->allocator, c->curr_scope, name_token, type);
			u64 key = hash_string(name_token.string);
			if (map_get(&entity_map, key)) {
				// TODO(bill): Scope checking already checks the declaration
				checker_err(c, name_token, "`%.*s` is already declared in this structure", LIT(name_token.string));
			} else {
				map_set(&entity_map, key, e);
				fields[field_index++] = e;
			}
			add_entity_use(c, name, e);
		}
	}
	struct_type->structure.fields = fields;
	struct_type->structure.field_count = field_count;
}

Type *check_get_params(Checker *c, Scope *scope, AstNode *field_list, isize field_count) {
	if (field_list == NULL || field_count == 0)
		return NULL;

	Type *tuple = make_type_tuple(c->allocator);

	Entity **variables = gb_alloc_array(c->allocator, Entity *, field_count);
	isize variable_index = 0;
	for (AstNode *field = field_list; field != NULL; field = field->next) {
		GB_ASSERT(field->kind == AstNode_Field);
		AstNode *type_expression = field->field.type_expression;
		if (type_expression) {
			Type *type = check_type(c, type_expression);
			for (AstNode *name = field->field.name_list; name != NULL; name = name->next) {
				if (name->kind == AstNode_Identifier) {
					Entity *param = make_entity_param(c->allocator, scope, name->identifier.token, type);
					add_entity(c, scope, name, param);
					variables[variable_index++] = param;
				} else {
					checker_err(c, ast_node_token(name),
					                    "Invalid parameter (invalid AST)");
				}
			}
		}
	}
	tuple->tuple.variables = variables;
	tuple->tuple.variable_count = field_count;

	return tuple;
}

Type *check_get_results(Checker *c, Scope *scope, AstNode *list, isize list_count) {
	if (list == NULL)
		return NULL;
	Type *tuple = make_type_tuple(c->allocator);

	Entity **variables = gb_alloc_array(c->allocator, Entity *, list_count);
	isize variable_index = 0;
	for (AstNode *item = list; item != NULL; item = item->next) {
		Type *type = check_type(c, item);
		Token token = ast_node_token(item);
		token.string = make_string(""); // NOTE(bill): results are not named
		// TODO(bill): Should I have named results?
		Entity *param = make_entity_param(c->allocator, scope, token, type);
		// NOTE(bill): No need to record
		variables[variable_index++] = param;

		if (get_base_type(type)->kind == Type_Array) {
			// TODO(bill): Should I allow array's to returned?
			checker_err(c, token, "You cannot return an array from a procedure");
		}
	}
	tuple->tuple.variables = variables;
	tuple->tuple.variable_count = list_count;

	return tuple;
}


void check_procedure_type(Checker *c, Type *type, AstNode *proc_type_node) {
	isize param_count = proc_type_node->procedure_type.param_count;
	isize result_count = proc_type_node->procedure_type.result_count;

	// gb_printf("%td -> %td\n", param_count, result_count);

	Type *params  = check_get_params(c, c->curr_scope, proc_type_node->procedure_type.param_list,   param_count);
	Type *results = check_get_results(c, c->curr_scope, proc_type_node->procedure_type.results_list, result_count);

	type->procedure.scope         = c->curr_scope;
	type->procedure.params        = params;
	type->procedure.params_count  = proc_type_node->procedure_type.param_count;
	type->procedure.results       = results;
	type->procedure.results_count = proc_type_node->procedure_type.result_count;
}


void check_identifier(Checker *c, Operand *o, AstNode *n, Type *named_type) {
	GB_ASSERT(n->kind == AstNode_Identifier);
	o->mode = Addressing_Invalid;
	o->expression = n;
	Entity *e = NULL;
	scope_lookup_parent_entity(c->curr_scope, n->identifier.token.string, NULL, &e);
	if (e == NULL) {
		checker_err(c, n->identifier.token,
		            "Undeclared type or identifier `%.*s`", LIT(n->identifier.token.string));
		return;
	}
	add_entity_use(c, n, e);

	check_entity_declaration(c, e, named_type);

	if (e->type == NULL) {
		GB_PANIC("Compiler error: How did this happen? type: %s; identifier: %.*s\n", type_to_string(e->type), LIT(n->identifier.token.string));
		return;
	}

	switch (e->kind) {
	case Entity_Constant:
		add_declaration_dependency(c, e);
		if (e->type == &basic_types[Basic_Invalid])
			return;
		o->value = e->constant.value;
		GB_ASSERT(o->value.kind != ExactValue_Invalid);
		o->mode = Addressing_Constant;
		break;

	case Entity_Variable:
		add_declaration_dependency(c, e);
		e->variable.used = true;
		if (e->type == &basic_types[Basic_Invalid])
			return;
		o->mode = Addressing_Variable;
		break;

	case Entity_TypeName:
		o->mode = Addressing_Type;
		break;

	case Entity_Procedure:
		add_declaration_dependency(c, e);
		o->mode = Addressing_Value;
		break;

	case Entity_Builtin:
		o->builtin_id = e->builtin.id;
		o->mode = Addressing_Builtin;
		break;

	default:
		GB_PANIC("Compiler error: Unknown EntityKind");
		break;
	}

	o->type = e->type;
}

i64 check_array_count(Checker *c, AstNode *e) {
	if (e) {
		Operand o = {};
		check_expression(c, &o, e);
		if (o.mode != Addressing_Constant) {
			if (o.mode != Addressing_Invalid) {
				checker_err(c, ast_node_token(e), "Array count must be a constant");
			}
			return 0;
		}
		if (is_type_untyped(o.type) || is_type_integer(o.type)) {
			if (o.value.kind == ExactValue_Integer) {
				i64 count = o.value.value_integer;
				if (count >= 0)
					return count;
				checker_err(c, ast_node_token(e), "Invalid array count");
				return 0;
			}
		}

		checker_err(c, ast_node_token(e), "Array count must be an integer");
	}
	return 0;
}

Type *check_type_expression_extra(Checker *c, AstNode *e, Type *named_type) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	switch (e->kind) {
	case AstNode_Identifier: {
		Operand o = {};
		check_identifier(c, &o, e, named_type);
		switch (o.mode) {
		case Addressing_Type: {
			Type *t = o.type;
			set_base_type(named_type, t);
			return t;
		} break;

		case Addressing_Invalid:
			break;

		case Addressing_NoValue:
			err_str = expression_to_string(e);
			checker_err(c, ast_node_token(e), "`%s` used as a type", err_str);
			break;
		default:
			err_str = expression_to_string(e);
			checker_err(c, ast_node_token(e), "`%s` used as a type when not a type", err_str);
			break;
		}
	} break;

	case AstNode_ParenExpression:
		return check_type(c, e->paren_expression.expression, named_type);

	case AstNode_ArrayType:
		if (e->array_type.count != NULL) {
			Type *t = make_type_array(c->allocator,
			                          check_type(c, e->array_type.element),
			                          check_array_count(c, e->array_type.count));
			set_base_type(named_type, t);
			return t;
		} else {
			Type *t = make_type_slice(c->allocator, check_type(c, e->array_type.element));
			set_base_type(named_type, t);
			return t;
		}
		break;

	case AstNode_StructType: {
		Type *t = make_type_structure(c->allocator);
		set_base_type(named_type, t);
		check_struct_type(c, t, e);
		return t;
	} break;

	case AstNode_PointerType: {
		Type *t = make_type_pointer(c->allocator, check_type(c, e->pointer_type.type_expression));
		set_base_type(named_type, t);
		return t;
	} break;

	case AstNode_ProcedureType: {
		Type *t = alloc_type(c->allocator, Type_Procedure);
		set_base_type(named_type, t);
		check_open_scope(c, e);
		check_procedure_type(c, t, e);
		check_close_scope(c);
		return t;
	} break;

	default:
		err_str = expression_to_string(e);
		checker_err(c, ast_node_token(e), "`%s` is not a type", err_str);
		break;
	}

	Type *t = &basic_types[Basic_Invalid];
	set_base_type(named_type, t);
	return t;
}


Type *check_type(Checker *c, AstNode *e, Type *named_type) {
	ExactValue null_value = {ExactValue_Invalid};
	Type *type = NULL;
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	switch (e->kind) {
	case AstNode_Identifier: {
		Operand operand = {};
		check_identifier(c, &operand, e, named_type);
		switch (operand.mode) {
		case Addressing_Type: {
			type = operand.type;
			set_base_type(named_type, type);
			goto end;
		} break;

		case Addressing_Invalid:
			break;

		case Addressing_NoValue:
			err_str = expression_to_string(e);
			checker_err(c, ast_node_token(e), "`%s` used as a type", err_str);
			break;
		default:
			err_str = expression_to_string(e);
			checker_err(c, ast_node_token(e), "`%s` used as a type when not a type", err_str);
			break;
		}
	} break;

	case AstNode_SelectorExpression: {
		Operand o = {};
		check_selector(c, &o, e);

		if (o.mode == Addressing_Type) {
			set_base_type(type, o.type);
			return o.type;
		}
	} break;

	case AstNode_ParenExpression:
		return check_type(c, e->paren_expression.expression, named_type);

	case AstNode_ArrayType: {
		if (e->array_type.count != NULL) {
			type = make_type_array(c->allocator,
			                       check_type(c, e->array_type.element),
			                       check_array_count(c, e->array_type.count));
			set_base_type(named_type, type);
		} else {
			type = make_type_slice(c->allocator, check_type(c, e->array_type.element));
			set_base_type(named_type, type);
		}
		goto end;
	} break;

	case AstNode_StructType: {
		type = make_type_structure(c->allocator);
		set_base_type(named_type, type);
		check_struct_type(c, type, e);
		goto end;
	} break;

	case AstNode_PointerType: {
		type = make_type_pointer(c->allocator, check_type(c, e->pointer_type.type_expression));
		set_base_type(named_type, type);
		goto end;
	} break;

	case AstNode_ProcedureType: {
		type = alloc_type(c->allocator, Type_Procedure);
		set_base_type(named_type, type);
		check_procedure_type(c, type, e);
		goto end;
	} break;

	default:
		err_str = expression_to_string(e);
		checker_err(c, ast_node_token(e), "`%s` is not a type", err_str);
		break;
	}

	type = &basic_types[Basic_Invalid];
	set_base_type(named_type, type);

end:
	GB_ASSERT(is_type_typed(type));
	add_type_and_value(c, e, Addressing_Type, type, null_value);
	return type;
}


b32 check_unary_op(Checker *c, Operand *o, Token op) {
	// TODO(bill): Handle errors correctly
	gbString str = NULL;
	defer (gb_string_free(str));
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
		if (!is_type_numeric(o->type)) {
			str = expression_to_string(o->expression);
			checker_err(c, op, "Operator `%.*s` is not allowed with `%s`", LIT(op.string), str);
		}
		break;

	case Token_Xor:
		if (!is_type_integer(o->type)) {
			checker_err(c, op, "Operator `%.*s` is only allowed with integers", LIT(op.string));
		}
		break;

	case Token_Not:
		if (!is_type_boolean(o->type)) {
			str = expression_to_string(o->expression);
			checker_err(c, op, "Operator `%.*s` is only allowed on boolean expression", LIT(op.string));
		}
		break;

	default:
		checker_err(c, op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;
}

b32 check_binary_op(Checker *c, Operand *o, Token op) {
	// TODO(bill): Handle errors correctly
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:

	case Token_AddEq:
	case Token_SubEq:
	case Token_MulEq:
	case Token_QuoEq:
		if (!is_type_numeric(o->type)) {
			checker_err(c, op, "Operator `%.*s` is only allowed with numeric expressions", LIT(op.string));
			return false;
		}
		break;

	case Token_Mod:
	case Token_And:
	case Token_Or:
	case Token_Xor:
	case Token_AndNot:

	case Token_ModEq:
	case Token_AndEq:
	case Token_OrEq:
	case Token_XorEq:
	case Token_AndNotEq:
		if (!is_type_integer(o->type)) {
			checker_err(c, op, "Operator `%.*s` is only allowed with integers", LIT(op.string));
			return false;
		}
		break;

	case Token_CmpAnd:
	case Token_CmpOr:

	case Token_CmpAndEq:
	case Token_CmpOrEq:
		if (!is_type_boolean(o->type)) {
			checker_err(c, op, "Operator `%.*s` is only allowed with boolean expressions", LIT(op.string));
			return false;
		}
		break;

	default:
		checker_err(c, op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;

}
b32 check_value_is_expressible(Checker *c, ExactValue in_value, Type *type, ExactValue *out_value) {
	if (in_value.kind == ExactValue_Invalid)
		return true;

	if (is_type_boolean(type)) {
		return in_value.kind == ExactValue_Bool;
	} else if (is_type_string(type)) {
		return in_value.kind == ExactValue_String;
	} else if (is_type_integer(type)) {
		if (in_value.kind != ExactValue_Integer)
			return false;
		if (out_value) *out_value = in_value;
		i64 i = in_value.value_integer;
		i64 s = 8*type_size_of(c->sizes, c->allocator, type);
		u64 umax = ~0ull;
		if (s < 64) {
			umax = (1ull << s) - 1ull;
		}
		i64 imax = (1ll << (s-1ll));


		switch (type->basic.kind) {
		case Basic_i8:
		case Basic_i16:
		case Basic_i32:
		case Basic_i64:
		case Basic_int:
			return gb_is_between(i, -imax, imax-1);

		case Basic_u8:
		case Basic_u16:
		case Basic_u32:
		case Basic_u64:
		case Basic_uint:
			return !(i < 0 || cast(u64)i > umax);

		case Basic_UntypedInteger:
			return true;

		default: GB_PANIC("Compiler error: Unknown integer type!"); break;
		}
	} else if (is_type_float(type)) {
		ExactValue v = exact_value_to_float(in_value);
		if (v.kind != ExactValue_Float)
			return false;

		switch (type->basic.kind) {
		case Basic_f32:
			if (out_value) *out_value = v;
			return true;

		case Basic_f64:
			if (out_value) *out_value = v;
			return true;

		case Basic_UntypedFloat:
			return true;
		}
	} else if (is_type_pointer(type)) {
		if (in_value.kind == ExactValue_Pointer)
			return true;
		if (in_value.kind == ExactValue_Integer)
			return true;
		if (out_value) *out_value = in_value;
	}

	return false;
}

void check_is_expressible(Checker *c, Operand *o, Type *type) {
	GB_ASSERT(type->kind == Type_Basic);
	GB_ASSERT(o->mode == Addressing_Constant);
	if (!check_value_is_expressible(c, o->value, type, &o->value)) {
		gbString a = type_to_string(o->type);
		gbString b = type_to_string(type);
		defer (gb_string_free(a));
		defer (gb_string_free(b));
		if (is_type_numeric(o->type) && is_type_numeric(type)) {
			if (!is_type_integer(o->type) && is_type_integer(type)) {
				checker_err(c, ast_node_token(o->expression), "`%s` truncated to `%s`", a, b);
			} else {
				checker_err(c, ast_node_token(o->expression), "`%s` overflows to `%s`", a, b);
			}
		} else {
			checker_err(c, ast_node_token(o->expression), "Cannot convert `%s` to `%s`", a, b);
		}

		o->mode = Addressing_Invalid;
	}
}


void check_unary_expression(Checker *c, Operand *o, Token op, AstNode *node) {
	if (op.kind == Token_Pointer) { // Pointer address
		if (o->mode != Addressing_Variable) {
			gbString str = expression_to_string(node->unary_expression.operand);
			defer (gb_string_free(str));
			checker_err(c, op, "Cannot take the pointer address of `%s`", str);
			o->mode = Addressing_Invalid;
			return;
		}
		o->mode = Addressing_Value;
		o->type = make_type_pointer(c->allocator, o->type);
		return;
	}

	if (!check_unary_op(c, o, op)) {
		o->mode = Addressing_Invalid;
		return;
	}

	if (o->mode == Addressing_Constant) {
		Type *type = get_base_type(o->type);
		GB_ASSERT(type->kind == Type_Basic);
		i32 precision = 0;
		if (is_type_unsigned(type))
			precision = cast(i32)(8 * type_size_of(c->sizes, c->allocator, type));
		o->value = exact_unary_operator_value(op, o->value, precision);

		if (is_type_typed(type)) {
			if (node != NULL)
				o->expression = node;
			check_is_expressible(c, o, type);
		}
		return;
	}

	o->mode = Addressing_Value;
}

void check_comparison(Checker *c, Operand *x, Operand *y, Token op) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	if (check_is_assignable_to(c, x, y->type) ||
	    check_is_assignable_to(c, y, x->type)) {
		b32 defined = false;
		switch (op.kind) {
		case Token_CmpEq:
		case Token_NotEq:
			defined = is_type_comparable(x->type);
			break;
		case Token_Lt:
		case Token_Gt:
		case Token_LtEq:
		case Token_GtEq: {
			defined = is_type_ordered(x->type);
		} break;
		}

		if (!defined) {
			gbString type_string = type_to_string(x->type);
			err_str = gb_string_make(gb_heap_allocator(),
			                         gb_bprintf("operator `%.*s` not defined for type `%s`", LIT(op.string), type_string));
			gb_string_free(type_string);
		}
	} else {
		gbString xt = type_to_string(x->type);
		gbString yt = type_to_string(y->type);
		defer(gb_string_free(xt));
		defer(gb_string_free(yt));
		err_str = gb_string_make(gb_heap_allocator(),
		                         gb_bprintf("mismatched types `%s` and `%s`", xt, yt));
	}

	if (err_str) {
		checker_err(c, op, "Cannot compare expression, %s", err_str);
		return;
	}

	if (x->mode == Addressing_Constant &&
	    y->mode == Addressing_Constant) {
		x->value = make_exact_value_bool(compare_exact_values(op, x->value, y->value));
	} else {
		// TODO(bill): What should I do?
	}

	x->type = &basic_types[Basic_UntypedBool];
}

void check_binary_expression(Checker *c, Operand *x, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpression);
	Operand y_ = {}, *y = &y_;
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	check_expression(c, x, node->binary_expression.left);
	check_expression(c, y, node->binary_expression.right);
	if (x->mode == Addressing_Invalid) return;
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		x->expression = y->expression;
		return;
	}

	convert_to_typed(c, x, y->type);
	if (x->mode == Addressing_Invalid) return;
	convert_to_typed(c, y, x->type);
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		return;
	}

	Token op = node->binary_expression.op;
	if (token_is_comparison(op)) {
		check_comparison(c, x, y, op);
		return;
	}

	if (!are_types_identical(x->type, y->type)) {
		if (x->type != &basic_types[Basic_Invalid] &&
		    y->type  != &basic_types[Basic_Invalid]) {
			gbString xt = type_to_string(x->type);
			gbString yt = type_to_string(y->type);
			defer (gb_string_free(xt));
			defer (gb_string_free(yt));
			err_str = expression_to_string(x->expression);
			checker_err(c, op, "Mismatched types in binary expression `%s` : `%s` vs `%s`", err_str, xt, yt);
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
	case Token_QuoEq:
	case Token_ModEq:
		if ((x->mode == Addressing_Constant || is_type_integer(x->type)) &&
		    y->mode == Addressing_Constant) {
			b32 fail = false;
			switch (y->value.kind) {
			case ExactValue_Integer:
				if (y->value.value_integer == 0)
					fail = true;
				break;
			case ExactValue_Float:
				if (y->value.value_float == 0.0)
					fail = true;
				break;
			}

			if (fail) {
				checker_err(c, ast_node_token(y->expression), "Division by zero not allowed");
				x->mode = Addressing_Invalid;
				return;
			}
		}
	}

	if (x->mode == Addressing_Constant &&
	    y->mode  == Addressing_Constant) {
		ExactValue a = x->value;
		ExactValue b = y->value;

		Type *type = get_base_type(x->type);
		GB_ASSERT(type->kind == Type_Basic);
		if (op.kind == Token_Quo && is_type_integer(type)) {
			op.kind = Token_QuoEq; // NOTE(bill): Hack to get division of integers
		}
		x->value = exact_binary_operator_value(op, a, b);
		if (is_type_typed(type)) {
			if (node != NULL)
				x->expression = node;
			check_is_expressible(c, x, type);
		}
		return;
	}

	x->mode = Addressing_Value;
}


void update_expression_type(Checker *c, AstNode *e, Type *type) {
	ExpressionInfo *found = map_get(&c->untyped, hash_pointer(e));
	if (!found)
		return;

	switch (e->kind) {
	case AstNode_UnaryExpression:
		if (found->value.kind != ExactValue_Invalid)
			break;
		update_expression_type(c, e->unary_expression.operand, type);
		break;

	case AstNode_BinaryExpression:
		if (found->value.kind != ExactValue_Invalid)
			break;
		if (!token_is_comparison(e->binary_expression.op)) {
			update_expression_type(c, e->binary_expression.left,  type);
			update_expression_type(c, e->binary_expression.right, type);
		}
	}

	if (is_type_untyped(type)) {
		found->type = get_base_type(type);
	} else {
		found->type = type;
	}
}

void update_expression_value(Checker *c, AstNode *e, ExactValue value) {
	ExpressionInfo *found = map_get(&c->untyped, hash_pointer(e));
	if (found)
		found->value = value;
}

void convert_untyped_error(Checker *c, Operand *operand, Type *target_type) {
	gbString expr_str = expression_to_string(operand->expression);
	gbString type_str = type_to_string(target_type);
	char *extra_text = "";
	defer (gb_string_free(expr_str));
	defer (gb_string_free(type_str));

	if (operand->mode == Addressing_Constant) {
		if (operand->value.value_integer == 0) {
			// NOTE(bill): Doesn't matter what the type is as it's still zero in the union
			extra_text = " - Did you want `null`?";
		}
	}
	checker_err(c, ast_node_token(operand->expression), "Cannot convert `%s` to `%s`%s", expr_str, type_str, extra_text);

	operand->mode = Addressing_Invalid;
}

void convert_to_typed(Checker *c, Operand *operand, Type *target_type) {
	GB_ASSERT_NOT_NULL(target_type);
	if (operand->mode == Addressing_Invalid ||
	    is_type_typed(operand->type) ||
	    target_type == &basic_types[Basic_Invalid]) {
		return;
	}

	if (is_type_untyped(target_type)) {
		Type *x = operand->type;
		Type *y = target_type;
		if (is_type_numeric(x) && is_type_numeric(y)) {
			if (x < y) {
				operand->type = target_type;
				update_expression_type(c, operand->expression, target_type);
			}
		} else if (x != y) {
			convert_untyped_error(c, operand, target_type);
		}
		return;
	}

	Type *t = get_base_type(target_type);
	switch (t->kind) {
	case Type_Basic:
		if (operand->mode == Addressing_Constant) {
			check_is_expressible(c, operand, t);
			if (operand->mode == Addressing_Invalid) {
				return;
			}
			update_expression_value(c, operand->expression, operand->value);
		} else {
			// TODO(bill): Is this really needed?
			switch (operand->type->basic.kind) {
			case Basic_UntypedBool:
				if (!is_type_boolean(target_type)) {
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;
			case Basic_UntypedInteger:
			case Basic_UntypedFloat:
			case Basic_UntypedRune:
				if (!is_type_numeric(target_type)) {
					convert_untyped_error(c, operand, target_type);
					return;
				}
				break;
			}
		}
		break;
	case Type_Pointer:
		switch (operand->type->basic.kind) {
		case Basic_UntypedPointer:
			target_type = &basic_types[Basic_UntypedPointer];
			break;
		default:
			convert_untyped_error(c, operand, target_type);
			return;
		}

		break;
	default:
		convert_untyped_error(c, operand, target_type);
		return;
	}

	operand->type = target_type;
}

b32 check_index_value(Checker *c, AstNode *index_value, i64 max_count, i64 *value) {
	Operand operand = {Addressing_Invalid};
	check_expression(c, &operand, index_value);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	convert_to_typed(c, &operand, &basic_types[Basic_int]);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	if (!is_type_integer(operand.type)) {
		gbString expr_str = expression_to_string(operand.expression);
		checker_err(c, ast_node_token(operand.expression),
		            "Index `%s` must be an integer", expr_str);
		gb_string_free(expr_str);
		if (value) *value = 0;
		return false;
	}

	if (operand.mode == Addressing_Constant) {
		if (max_count >= 0) { // NOTE(bill): Do array bound checking
			i64 i = exact_value_to_integer(operand.value).value_integer;
			if (i < 0) {
				gbString expr_str = expression_to_string(operand.expression);
				checker_err(c, ast_node_token(operand.expression),
				            "Index `%s` cannot be a negative value", expr_str);
				gb_string_free(expr_str);
				if (value) *value = 0;
				return false;
			}

			if (value) *value = i;

			if (i >= max_count) {
				gbString expr_str = expression_to_string(operand.expression);
				checker_err(c, ast_node_token(operand.expression),
				            "Index `%s` is out of bounds range [0, %lld)", expr_str, max_count);
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

Entity *lookup_field(Type *type, AstNode *field_node, isize *index = NULL) {
	GB_ASSERT(field_node->kind == AstNode_Identifier);
	type = get_base_type(type);
	if (type->kind == Type_Pointer)
		type = get_base_type(type->pointer.element);

	String field_str = field_node->identifier.token.string;
	switch (type->kind) {
	case Type_Structure:
		for (isize i = 0; i < type->structure.field_count; i++) {
			Entity *f = type->structure.fields[i];
			GB_ASSERT(f->kind == Entity_Variable && f->variable.is_field);
			String str = f->token.string;
			if (are_strings_equal(field_str, str)) {
				if (index) *index = i;
				return f;
			}
		}
		break;
	// TODO(bill): Other types and extra "hidden" fields (e.g. introspection stuff)
	// TODO(bill): Allow for access of field through index? e.g. `x.3` will get member of index 3
	// Or is this only suitable if tuples are first-class?
	}

	return NULL;
}

void check_selector(Checker *c, Operand *operand, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_SelectorExpression);

	AstNode *op_expr  = node->selector_expression.operand;
	AstNode *selector = node->selector_expression.selector;
	if (selector) {
		Entity *entity = lookup_field(operand->type, selector);
		if (entity == NULL) {
			gbString op_str  = expression_to_string(op_expr);
			gbString sel_str = expression_to_string(selector);
			defer (gb_string_free(op_str));
			defer (gb_string_free(sel_str));
			checker_err(c, ast_node_token(op_expr), "`%s` has no field `%s`", op_str, sel_str);
			operand->mode = Addressing_Invalid;
			operand->expression = node;
			return;
		}
		add_entity_use(c, selector, entity);

		operand->type = entity->type;
		operand->expression = node;
		if (operand->mode != Addressing_Variable)
			operand->mode = Addressing_Value;
	} else {
		operand->mode = Addressing_Invalid;
		operand->expression = node;
	}

}

b32 check_builtin_procedure(Checker *c, Operand *operand, AstNode *call, i32 id) {
	GB_ASSERT(call->kind == AstNode_CallExpression);
	auto *ce = &call->call_expression;
	BuiltinProcedure *bp = &builtin_procedures[id];
	{
		char *err = NULL;
		if (ce->arg_list_count < bp->arg_count)
			err = "Too few";
		if (ce->arg_list_count > bp->arg_count && !bp->variadic)
			err = "Too many";
		if (err) {
			checker_err(c, ce->close, "`%s` arguments for `%.*s`, expected %td, got %td",
			            err, LIT(call->call_expression.proc->identifier.token.string),
			            bp->arg_count, ce->arg_list_count);
			return false;
		}
	}

	switch (id) {
	case BuiltinProcedure_size_of:
	case BuiltinProcedure_align_of:
	case BuiltinProcedure_offset_of:
		// NOTE(bill): The first arg is a Type, this will be checked case by case
		break;
	default:
		check_multi_expression(c, operand, ce->arg_list);
	}

	switch (id) {
	case BuiltinProcedure_size_of: {
		// size_of :: proc(Type)
		Type *type = check_type(c, ce->arg_list);
		if (!type) {
			checker_err(c, ast_node_token(ce->arg_list), "Expected a type for `size_of`");
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_size_of(c->sizes, c->allocator, type));
		operand->type = &basic_types[Basic_int];

	} break;

	case BuiltinProcedure_size_of_val:
		// size_of_val :: proc(val)
		check_assignment(c, operand, NULL, make_string("argument of `size_of`"));
		if (operand->mode == Addressing_Invalid)
			return false;

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_size_of(c->sizes, c->allocator, operand->type));
		operand->type = &basic_types[Basic_int];
		break;

	case BuiltinProcedure_align_of: {
		// align_of :: proc(Type)
		Type *type = check_type(c, ce->arg_list);
		if (!type) {
			checker_err(c, ast_node_token(ce->arg_list), "Expected a type for `align_of`");
			return false;
		}
		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_align_of(c->sizes, c->allocator, type));
		operand->type = &basic_types[Basic_int];
	} break;

	case BuiltinProcedure_align_of_val:
		// align_of_val :: proc(val)
		check_assignment(c, operand, NULL, make_string("argument of `align_of`"));
		if (operand->mode == Addressing_Invalid)
			return false;

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_align_of(c->sizes, c->allocator, operand->type));
		operand->type = &basic_types[Basic_int];
		break;

	case BuiltinProcedure_offset_of: {
		// offset_val :: proc(Type, field)
		Type *type = get_base_type(check_type(c, ce->arg_list));
		AstNode *field_arg = unparen_expression(ce->arg_list->next);
		if (type) {
			if (type->kind != Type_Structure) {
				checker_err(c, ast_node_token(ce->arg_list), "Expected a structure type for `offset_of`");
				return false;
			}
			if (field_arg == NULL ||
			    field_arg->kind != AstNode_Identifier) {
				checker_err(c, ast_node_token(field_arg), "Expected an identifier for field argument");
				return false;
			}
		}

		isize index = 0;
		Entity *entity = lookup_field(type, field_arg, &index);
		if (entity == NULL) {
			gbString type_str = type_to_string(type);
			checker_err(c, ast_node_token(ce->arg_list),
			                    "`%s` has no field named `%.*s`", type_str, LIT(field_arg->identifier.token.string));
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_offset_of(c->sizes, c->allocator, type, index));
		operand->type  = &basic_types[Basic_int];
	} break;

	case BuiltinProcedure_offset_of_val: {
		// offset_val :: proc(val)
		AstNode *arg = unparen_expression(ce->arg_list);
		if (arg->kind != AstNode_SelectorExpression) {
			gbString str = expression_to_string(arg);
			checker_err(c, ast_node_token(arg), "`%s` is not a selector expression", str);
			return false;
		}
		auto *s = &arg->selector_expression;

		check_expression(c, operand, s->operand);
		if (operand->mode == Addressing_Invalid)
			return false;

		Type *type = operand->type;
		if (get_base_type(type)->kind == Type_Pointer) {
			Type *p = get_base_type(type);
			if (get_base_type(p)->kind == Type_Structure)
				type = p->pointer.element;
		}

		isize index = 0;
		Entity *entity = lookup_field(type, s->selector, &index);
		if (entity == NULL) {
			gbString type_str = type_to_string(type);
			checker_err(c, ast_node_token(arg),
			            "`%s` has no field named `%.*s`", type_str, LIT(s->selector->identifier.token.string));
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_offset_of(c->sizes, c->allocator, type, index));
		operand->type  = &basic_types[Basic_int];
	} break;

	case BuiltinProcedure_static_assert:
		// static_assert :: proc(cond: bool)
		// TODO(bill): Should `static_assert` and `assert` be unified?

		if (operand->mode != Addressing_Constant ||
		    !is_type_boolean(operand->type)) {
			gbString str = expression_to_string(ce->arg_list);
			defer (gb_string_free(str));
			checker_err(c, ast_node_token(call),
			            "`%s` is not a constant boolean", str);
			return false;
		}
		if (!operand->value.value_bool) {
			gbString str = expression_to_string(ce->arg_list);
			defer (gb_string_free(str));
			checker_err(c, ast_node_token(call),
			            "Static assertion: `%s`", str);
			return true;
		}
		break;

	// TODO(bill): Should these be procedures and are their names appropriate?
	case BuiltinProcedure_len:
	case BuiltinProcedure_cap: {
		Type *t = get_base_type(operand->type);

		AddressingMode mode = Addressing_Invalid;
		ExactValue value = {};

		switch (t->kind) {
		case Type_Basic:
			if (id == BuiltinProcedure_len) {
				if (is_type_string(t)) {
					if (operand->mode == Addressing_Constant) {
						mode = Addressing_Constant;
						value = make_exact_value_integer(operand->value.value_string.len);
					} else {
						mode = Addressing_Value;
					}
				}
			}
			break;

		case Type_Array:
			mode = Addressing_Constant;
			value = make_exact_value_integer(t->array.count);
			break;

		case Type_Slice:
			mode = Addressing_Value;
			break;
		}

		if (mode == Addressing_Invalid) {
			gbString str = expression_to_string(operand->expression);
			checker_err(c, ast_node_token(operand->expression),
			            "Invalid expression `%s` for `%.*s`",
			            str, LIT(bp->name));
			gb_string_free(str);
			return false;
		}

		operand->mode = mode;
		operand->type = &basic_types[Basic_int];
		operand->value = value;

	} break;

	// TODO(bill): copy() pointer version?
	case BuiltinProcedure_copy: {
		// copy :: proc(x, y: []Type) -> int
		Type *dest_type = NULL, *src_type = NULL;

		Type *d = get_base_type(operand->type);
		if (d->kind == Type_Slice)
			dest_type = d->slice.element;

		Operand op = {};
		check_expression(c, &op, ce->arg_list->next);
		if (op.mode == Addressing_Invalid)
			return false;
		Type *s = get_base_type(op.type);
		if (s->kind == Type_Slice)
			src_type = s->slice.element;

		if (dest_type == NULL || src_type == NULL) {
			checker_err(c, ast_node_token(call), "`copy` only expects slices as arguments");
			return false;
		}

		if (!are_types_identical(dest_type, src_type)) {
			gbString d_arg = expression_to_string(ce->arg_list);
			gbString s_arg = expression_to_string(ce->arg_list->next);
			gbString d_str = type_to_string(dest_type);
			gbString s_str = type_to_string(src_type);
			defer (gb_string_free(d_arg));
			defer (gb_string_free(s_arg));
			defer (gb_string_free(d_str));
			defer (gb_string_free(s_str));
			checker_err(c, ast_node_token(call),
			            "Arguments to `copy`, %s, %s, have different element types: %s vs %s",
			            d_arg, s_arg, d_str, s_str);
			return false;
		}

		operand->type = &basic_types[Basic_int]; // Returns number of elements copied
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProcedure_copy_bytes: {
		// copy_bytes :: proc(dest, source: rawptr, byte_count: int)
		Type *dest_type = NULL, *src_type = NULL;

		Type *d = get_base_type(operand->type);
		if (is_type_pointer(d))
			dest_type = d;

		Operand op = {};
		check_expression(c, &op, ce->arg_list->next);
		if (op.mode == Addressing_Invalid)
			return false;
		Type *s = get_base_type(op.type);
		if (is_type_pointer(s))
			src_type = s;

		if (dest_type == NULL || src_type == NULL) {
			checker_err(c, ast_node_token(call), "`copy_bytes` only expects pointers for the destintation and source");
			return false;
		}

		check_expression(c, &op, ce->arg_list->next->next);
		if (op.mode == Addressing_Invalid)
			return false;

		convert_to_typed(c, &op, &basic_types[Basic_int]);
		if (op.mode == Addressing_Invalid ||
		    op.type->kind != Type_Basic ||
		    op.type->basic.kind != Basic_int) {
			gbString str = type_to_string(op.type);
			defer (gb_string_free(str));
			checker_err(c, ast_node_token(call), "`copy_bytes` 3rd argument must be of type `int`, a `%s` was given", str);
			return false;
		}

		if (op.mode == Addressing_Constant) {
			if (exact_value_to_integer(op.value).value_integer <= 0) {
				checker_err(c, ast_node_token(call), "You cannot copy a zero or negative amount of bytes with `copy_bytes`");
				return false;
			}
		}

		operand->type = NULL;
		operand->mode = Addressing_NoValue;
	} break;


	case BuiltinProcedure_print:
	case BuiltinProcedure_println: {
		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next) {
			// TOOD(bill): `check_assignment` doesn't allow tuples at the moment, should it?
			// Or should we destruct the tuple and use each element?
			check_assignment(c, operand, NULL, make_string("argument"));
			if (operand->mode == Addressing_Invalid)
				return false;
		}
	} break;
	}

	return true;
}


void check_call_arguments(Checker *c, Operand *operand, Type *proc_type, AstNode *call) {
	GB_ASSERT(call->kind == AstNode_CallExpression);
	GB_ASSERT(proc_type->kind == Type_Procedure);
	auto *ce = &call->call_expression;
	isize error_code = 0;
	isize param_index = 0;
	isize param_count = 0;

	if (proc_type->procedure.params)
		param_count = proc_type->procedure.params->tuple.variable_count;

 	if (ce->arg_list_count == 0 && param_count == 0)
		return;

	if (ce->arg_list_count > param_count) {
		error_code = +1;
	} else {
		Entity **sig_params = proc_type->procedure.params->tuple.variables;
		AstNode *call_arg = ce->arg_list;
		for (; call_arg != NULL; call_arg = call_arg->next) {
			check_multi_expression(c, operand, call_arg);
			if (operand->mode == Addressing_Invalid)
				continue;
			if (operand->type->kind != Type_Tuple) {
				check_not_tuple(c, operand);
				check_assignment(c, operand, sig_params[param_index]->type, make_string("argument"));
				param_index++;
			} else {
				auto *tuple = &operand->type->tuple;
				isize i = 0;
				for (;
				     i < tuple->variable_count && param_index < param_count;
				     i++, param_index++) {
					Entity *e = tuple->variables[i];
					operand->type = e->type;
					operand->mode = Addressing_Value;
					check_not_tuple(c, operand);
					check_assignment(c, operand, sig_params[param_index]->type, make_string("argument"));
				}

				if (i < tuple->variable_count && param_index == param_count) {
					error_code = +1;
					break;
				}
			}

			if (param_index >= param_count)
				break;
		}


		if (param_index < param_count) {
			error_code = -1;
		} else if (call_arg != NULL && call_arg->next != NULL) {
			error_code = +1;
		}
	}

	if (error_code != 0) {
		char *err_fmt = "";
		if (error_code < 0) {
			err_fmt = "Too few arguments for `%s`, expected %td arguments";
		} else {
			err_fmt = "Too many arguments for `%s`, expected %td arguments";
		}

		gbString proc_str = expression_to_string(ce->proc);
		checker_err(c, ast_node_token(call), err_fmt, proc_str, param_count);
		gb_string_free(proc_str);

		operand->mode = Addressing_Invalid;
	}
}


ExpressionKind check_call_expression(Checker *c, Operand *operand, AstNode *call) {
	GB_ASSERT(call->kind == AstNode_CallExpression);
	auto *ce = &call->call_expression;
	check_expression_or_type(c, operand, ce->proc);

	if (operand->mode == Addressing_Invalid) {
		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next)
			check_expression_base(c, operand, arg);
		operand->mode = Addressing_Invalid;
		operand->expression = call;
		return Expression_Statement;
	}

	if (operand->mode == Addressing_Builtin) {
		i32 id = operand->builtin_id;
		if (!check_builtin_procedure(c, operand, call, id))
			operand->mode = Addressing_Invalid;
		operand->expression = call;
		return builtin_procedures[id].kind;
	}

	Type *proc_type = get_base_type(operand->type);
	if (proc_type == NULL || proc_type->kind != Type_Procedure) {
		AstNode *e = operand->expression;
		gbString str = expression_to_string(e);
		defer (gb_string_free(str));
		checker_err(c, ast_node_token(e), "Cannot call a non-procedure: `%s`", str);

		operand->mode = Addressing_Invalid;
		operand->expression = call;

		return Expression_Statement;
	}


	check_call_arguments(c, operand, proc_type, call);

	auto *proc = &proc_type->procedure;
	if (proc->results_count == 0) {
		operand->mode = Addressing_NoValue;
	} else if (proc->results_count == 1) {
		operand->mode = Addressing_Value;
		operand->type = proc->results->tuple.variables[0]->type;
	} else {
		operand->mode = Addressing_Value;
		operand->type = proc->results;
	}

	operand->expression = call;
	return Expression_Statement;
}

b32 check_castable_to(Checker *c, Operand *operand, Type *y) {
	if (check_is_assignable_to(c, operand, y))
		return true;

	Type *x = operand->type;
	Type *xb = get_base_type(x);
	Type *yb = get_base_type(y);
	if (are_types_identical(xb, yb))
		return true;

	// Cast between numbers
	if (is_type_integer(x) || is_type_float(x)) {
		if (is_type_integer(y) || is_type_float(y))
			return true;
	}

	// Cast between pointers
	if (is_type_pointer(x)) {
		if (is_type_pointer(y))
			return true;
	}

	// untyped integers -> pointers
	if (is_type_untyped(xb) && is_type_integer(xb)) {
		if (is_type_pointer(yb))
			return true;
	}

	// (u)int <-> pointer
	if (is_type_pointer(xb) || is_type_int_or_uint(xb)) {
		if (is_type_pointer(yb))
			return true;
	}
	if (is_type_pointer(xb)) {
		if (is_type_pointer(yb) || is_type_int_or_uint(yb))
			return true;
	}

	return false;
}

void check_cast_expression(Checker *c, Operand *operand, Type *type) {
	b32 is_const_expr = operand->mode == Addressing_Constant;
	b32 can_convert = false;

	if (is_const_expr && is_type_constant_type(type)) {
		Type *t = get_base_type(type);
		if (t->kind == Type_Basic) {
			if (check_value_is_expressible(c, operand->value, t, &operand->value)) {
				can_convert = true;
			}
		}
	} else if (check_castable_to(c, operand, type)) {
		operand->mode = Addressing_Value;
		can_convert = true;
	}

	if (!can_convert) {
		gbString expr_str = expression_to_string(operand->expression);
		gbString type_str = type_to_string(type);
		defer (gb_string_free(expr_str));
		defer (gb_string_free(type_str));
		checker_err(c, ast_node_token(operand->expression), "Cannot cast `%s` to `%s`", expr_str, type_str);

		operand->mode = Addressing_Invalid;
		return;
	}

	operand->type = type;
}



ExpressionKind check__expression_base(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExpressionKind kind = Expression_Statement;

	o->mode = Addressing_Invalid;
	o->type = &basic_types[Basic_Invalid];

	switch (node->kind) {
	case AstNode_BadExpression:
		goto error;

	case AstNode_Identifier:
		check_identifier(c, o, node, type_hint);
		break;
	case AstNode_BasicLiteral: {
		BasicKind basic_kind = Basic_Invalid;
		Token lit = node->basic_literal;
		switch (lit.kind) {
		case Token_Integer: basic_kind = Basic_UntypedInteger; break;
		case Token_Float:   basic_kind = Basic_UntypedFloat;   break;
		case Token_String:  basic_kind = Basic_UntypedString;  break;
		case Token_Rune:    basic_kind = Basic_UntypedRune;    break;
		default:            GB_PANIC("Unknown literal");       break;
		}
		o->mode  = Addressing_Constant;
		o->type  = &basic_types[basic_kind];
		o->value = make_exact_value_from_basic_literal(lit);
	} break;

	case AstNode_ParenExpression:
		kind = check_expression_base(c, o, node->paren_expression.expression, type_hint);
		o->expression = node;
		break;

	case AstNode_TagExpression:
		// TODO(bill): Tag expressions
		checker_err(c, ast_node_token(node), "Tag expressions are not supported yet");
		kind = check_expression_base(c, o, node->tag_expression.expression, type_hint);
		o->expression = node;
		break;

	case AstNode_UnaryExpression:
		check_expression(c, o, node->unary_expression.operand);
		if (o->mode == Addressing_Invalid)
			goto error;
		check_unary_expression(c, o, node->unary_expression.op, node);
		if (o->mode == Addressing_Invalid)
			goto error;
		break;

	case AstNode_BinaryExpression:
		check_binary_expression(c, o, node);
		if (o->mode == Addressing_Invalid)
			goto error;
		break;


	case AstNode_SelectorExpression:
		check_expression_base(c, o, node->selector_expression.operand);
		check_selector(c, o, node);
		break;

	case AstNode_IndexExpression: {
		check_expression(c, o, node->index_expression.expression);
		if (o->mode == Addressing_Invalid)
			goto error;

		b32 valid = false;
		i64 max_count = -1;
		Type *t = get_base_type(o->type);
		switch (t->kind) {
		case Type_Basic:
			if (is_type_string(t)) {
				valid = true;
				if (o->mode == Addressing_Constant) {
					max_count = o->value.value_string.len;
				}
				o->mode = Addressing_Value;
				o->type = &basic_types[Basic_u8];
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->array.count;
			if (o->mode != Addressing_Variable)
				o->mode = Addressing_Value;
			o->type = t->array.element;
			break;

		case Type_Slice:
			valid = true;
			o->type = t->slice.element;
			o->mode = Addressing_Variable;
			break;

		case Type_Pointer:
			valid = true;
			o->mode = Addressing_Variable;
			o->type = get_base_type(t->pointer.element);
			break;
		}

		if (!valid) {
			gbString str = expression_to_string(o->expression);
			checker_err(c, ast_node_token(o->expression), "Cannot index `%s`", str);
			gb_string_free(str);
			goto error;
		}

		if (node->index_expression.value == NULL) {
			gbString str = expression_to_string(o->expression);
			checker_err(c, ast_node_token(o->expression), "Missing index for `%s`", str);
			gb_string_free(str);
			goto error;
		}

		check_index_value(c, node->index_expression.value, max_count, NULL);
	} break;


	case AstNode_SliceExpression: {
		auto *se = &node->slice_expression;
		check_expression(c, o, se->expression);
		if (o->mode == Addressing_Invalid)
			goto error;

		b32 valid = false;
		i64 max_count = -1;
		Type *t = get_base_type(o->type);
		switch (t->kind) {
		case Type_Basic:
			if (is_type_string(t)) {
				valid = true;
				if (o->mode == Addressing_Constant) {
					max_count = o->value.value_string.len;
				}
				o->mode = Addressing_Value;
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->array.count;
			if (o->mode != Addressing_Variable) {
				gbString str = expression_to_string(node);
				checker_err(c, ast_node_token(node), "Cannot slice array `%s`, value is not addressable", str);
				gb_string_free(str);
				goto error;
			}
			o->type = make_type_slice(c->allocator, t->array.element);
			o->mode = Addressing_Value;
			break;

		case Type_Slice:
			valid = true;
			o->mode = Addressing_Value;
			break;

		case Type_Pointer:
			valid = true;
			o->type = make_type_slice(c->allocator, get_base_type(t->pointer.element));
			o->mode = Addressing_Value;
			break;
		}

		if (!valid) {
			gbString str = expression_to_string(o->expression);
			checker_err(c, ast_node_token(o->expression), "Cannot slice `%s`", str);
			gb_string_free(str);
			goto error;
		}

		i64 indices[3] = {};
		AstNode *nodes[3] = {se->low, se->high, se->max};
		for (isize i = 0; i < gb_count_of(nodes); i++) {
			i64 index = max_count;
			if (nodes[i] != NULL) {
				i64 capacity = -1;
				if (max_count >= 0)
					capacity = max_count;
				i64 j = 0;
				if (check_index_value(c, nodes[i], capacity, &j)) {
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
					checker_err(c, se->close, "Invalid slice indices: [%td > %td]", a, b);
				}
			}
		}

	} break;

	case AstNode_CastExpression: {
		Type *cast_type = check_type(c, node->cast_expression.type_expression);
		check_expression_or_type(c, o, node->cast_expression.operand);
		if (o->mode != Addressing_Invalid)
			check_cast_expression(c, o, cast_type);

	} break;

	case AstNode_CallExpression:
		return check_call_expression(c, o, node);

	case AstNode_DereferenceExpression:
		check_expression_or_type(c, o, node->dereference_expression.operand);
		if (o->mode == Addressing_Invalid) {
			goto error;
		} else {
			Type *t = get_base_type(o->type);
			if (t->kind == Type_Pointer) {
				o->mode = Addressing_Variable;
				o->type = t->pointer.element;
 			} else {
 				gbString str = expression_to_string(o->expression);
 				checker_err(c, ast_node_token(o->expression), "Cannot dereference `%s`", str);
 				gb_string_free(str);
 				goto error;
 			}
		}
		break;

	case AstNode_ProcedureType:
	case AstNode_PointerType:
	case AstNode_ArrayType:
	case AstNode_StructType:
		o->mode = Addressing_Type;
		o->type = check_type(c, node);
		break;
	}

	kind = Expression_Expression;
	o->expression = node;
	return kind;

error:
	o->mode = Addressing_Invalid;
	o->expression = node;
	return kind;
}

ExpressionKind check_expression_base(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExpressionKind kind = check__expression_base(c, o, node, type_hint);
	Type *type = NULL;
	ExactValue value = {ExactValue_Invalid};
	switch (o->mode) {
	case Addressing_Invalid:
		type = &basic_types[Basic_Invalid];
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

	if (type != NULL) {
		if (is_type_untyped(type)) {
			add_untyped(c, node, false, o->mode, type, value);
		} else {
			add_type_and_value(c, node, o->mode, type, value);
		}
	}
	return kind;
}


void check_multi_expression(Checker *c, Operand *o, AstNode *e) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	check_expression_base(c, o, e);
	switch (o->mode) {
	default:
		return; // NOTE(bill): Valid

	case Addressing_NoValue:
		err_str = expression_to_string(e);
		checker_err(c, ast_node_token(e), "`%s` used as value", err_str);
		break;
	case Addressing_Type:
		err_str = expression_to_string(e);
		checker_err(c, ast_node_token(e), "`%s` is not an expression", err_str);
		break;
	}
	o->mode = Addressing_Invalid;
}

// TODO(bill): Should I remove this entirely?
void check_not_tuple(Checker *c, Operand *o) {
	if (o->mode == Addressing_Value) {
		// NOTE(bill): Tuples are not first class thus never named
		if (o->type->kind == Type_Tuple) {
			isize count = o->type->tuple.variable_count;
			GB_ASSERT(count != 1);
			checker_err(c, ast_node_token(o->expression),
			            "%td-valued tuple found where single value expected", count);
			o->mode = Addressing_Invalid;
		}
	}
}

void check_expression(Checker *c, Operand *o, AstNode *e) {
	check_multi_expression(c, o, e);
	check_not_tuple(c, o);
}


void check_expression_or_type(Checker *c, Operand *o, AstNode *e) {
	check_expression_base(c, o, e);
	check_not_tuple(c, o);
	if (o->mode == Addressing_NoValue) {
		AstNode *e = o->expression;
		gbString str = expression_to_string(e);
		defer (gb_string_free(str));
		checker_err(c, ast_node_token(e),
		            "`%s` used as value or type", str);
		o->mode = Addressing_Invalid;
	}
}


gbString write_expression_to_string(gbString str, AstNode *node);

gbString write_field_list_to_string(gbString str, AstNode *field_list, char *sep) {
	isize i = 0;
	for (AstNode *field = field_list; field != NULL; field = field->next) {
		GB_ASSERT(field->kind == AstNode_Field);
		if (i > 0)
			str = gb_string_appendc(str, sep);

		isize j = 0;
		for (AstNode *name = field->field.name_list; name != NULL; name = name->next) {
			if (j > 0)
				str = gb_string_appendc(str, ", ");
			str = write_expression_to_string(str, name);
			j++;
		}

		str = gb_string_appendc(str, ": ");
		str = write_expression_to_string(str, field->field.type_expression);

		i++;
	}
	return str;
}

gbString string_append_token(gbString str, Token token) {
	return gb_string_append_length(str, token.string.text, token.string.len);
}


gbString write_expression_to_string(gbString str, AstNode *node) {
	if (node == NULL)
		return str;

	switch (node->kind) {
	default:
		str = gb_string_appendc(str, "(bad expression)");
		break;

	case AstNode_Identifier:
		str = string_append_token(str, node->identifier.token);
		break;

	case AstNode_BasicLiteral:
		str = string_append_token(str, node->basic_literal);
		break;

	case AstNode_TagExpression:
		str = gb_string_appendc(str, "#");
		str = string_append_token(str, node->tag_expression.name);
		str = write_expression_to_string(str, node->tag_expression.expression);
		break;

	case AstNode_UnaryExpression:
		str = string_append_token(str, node->unary_expression.op);
		str = write_expression_to_string(str, node->unary_expression.operand);
		break;

	case AstNode_BinaryExpression:
		str = write_expression_to_string(str, node->binary_expression.left);
		str = gb_string_appendc(str, " ");
		str = string_append_token(str, node->binary_expression.op);
		str = gb_string_appendc(str, " ");
		str = write_expression_to_string(str, node->binary_expression.right);
		break;

	case AstNode_ParenExpression:
		str = gb_string_appendc(str, "(");
		str = write_expression_to_string(str, node->paren_expression.expression);
		str = gb_string_appendc(str, ")");
		break;

	case AstNode_SelectorExpression:
		str = write_expression_to_string(str, node->selector_expression.operand);
		str = gb_string_appendc(str, ".");
		str = write_expression_to_string(str, node->selector_expression.selector);
		break;

	case AstNode_IndexExpression:
		str = write_expression_to_string(str, node->index_expression.expression);
		str = gb_string_appendc(str, "[");
		str = write_expression_to_string(str, node->index_expression.value);
		str = gb_string_appendc(str, "]");
		break;

	case AstNode_SliceExpression:
		str = write_expression_to_string(str, node->slice_expression.expression);
		str = gb_string_appendc(str, "[");
		str = write_expression_to_string(str, node->slice_expression.low);
		str = gb_string_appendc(str, ":");
		str = write_expression_to_string(str, node->slice_expression.high);
		if (node->slice_expression.triple_indexed) {
			str = gb_string_appendc(str, ":");
			str = write_expression_to_string(str, node->slice_expression.max);
		}
		str = gb_string_appendc(str, "]");
		break;


	case AstNode_CastExpression:
		str = gb_string_appendc(str, "cast(");
		str = write_expression_to_string(str, node->cast_expression.type_expression);
		str = gb_string_appendc(str, ")");
		str = write_expression_to_string(str, node->cast_expression.operand);
		break;


	case AstNode_PointerType:
		str = gb_string_appendc(str, "^");
		str = write_expression_to_string(str, node->pointer_type.type_expression);
		break;
	case AstNode_ArrayType:
		str = gb_string_appendc(str, "[");
		str = write_expression_to_string(str, node->array_type.count);
		str = gb_string_appendc(str, "]");
		str = write_expression_to_string(str, node->array_type.element);
		break;


	case AstNode_CallExpression: {
		str = write_expression_to_string(str, node->call_expression.proc);
		str = gb_string_appendc(str, "(");
		isize i = 0;
		for (AstNode *arg = node->call_expression.arg_list; arg != NULL; arg = arg->next) {
			if (i > 0) gb_string_appendc(str, ", ");
			str = write_expression_to_string(str, arg);
			i++;
		}
		str = gb_string_appendc(str, ")");
	} break;

	case AstNode_ProcedureType:
		str = gb_string_appendc(str, "proc(");
		str = write_field_list_to_string(str, node->procedure_type.param_list, ", ");
		str = gb_string_appendc(str, ")");

		break;
	case AstNode_StructType:
		str = gb_string_appendc(str, "struct{");
		str = gb_string_appendc(str, "}");
		break;

	}

	return str;
}

gbString expression_to_string(AstNode *expression) {
	return write_expression_to_string(gb_string_make(gb_heap_allocator(), ""), expression);
}
