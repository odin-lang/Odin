void           check_assignment        (Checker *c, Operand *operand, Type *type, String context_name);
void           check_expression        (Checker *c, Operand *operand, AstNode *expression);
void           check_multi_expression  (Checker *c, Operand *operand, AstNode *expression);
void           check_expression_or_type(Checker *c, Operand *operand, AstNode *expression);
ExpressionKind check_expression_base   (Checker *c, Operand *operand, AstNode *expression, Type *type_hint = NULL);
Type *         check_type              (Checker *c, AstNode *expression, Type *named_type = NULL);
void           check_selector          (Checker *c, Operand *operand, AstNode *node);
void           check_not_tuple         (Checker *c, Operand *operand);
void           convert_to_typed        (Checker *c, Operand *operand, Type *target_type);
gbString       expression_to_string    (AstNode *expression);


void check_struct_type(Checker *c, Type *struct_type, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_StructType);
	GB_ASSERT(struct_type->kind == Type_Structure);
	auto *st = &node->struct_type;
	if (st->field_count == 0) {
		print_checker_error(c, ast_node_token(node), "Empty struct{} definition");
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

	Entity **fields = gb_alloc_array(gb_arena_allocator(&c->entity_arena),
	                                 Entity *, st->field_count);
	isize field_index = 0;
	for (AstNode *field = st->field_list; field != NULL; field = field->next) {
		Type *type = check_type(c, field->field.type_expression);
		for (AstNode *name = field->field.name_list; name != NULL; name = name->next) {
			GB_ASSERT(name->kind == AstNode_Identifier);
			Token name_token = name->identifier.token;
			// TODO(bill): is the curr_scope correct?
			Entity *e = make_entity_field(c, c->curr_scope, name_token, type);
			u64 key = hash_string(name_token.string);
			if (map_get(&entity_map, key)) {
				// TODO(bill): Scope checking already checks the declaration
				print_checker_error(c, name_token, "`%.*s` is already declared in this structure", LIT(name_token.string));
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

	Type *tuple = make_type_tuple();

	Entity **variables = gb_alloc_array(gb_arena_allocator(&c->entity_arena),
	                                    Entity *, field_count);
	isize variable_index = 0;
	for (AstNode *field = field_list; field != NULL; field = field->next) {
		GB_ASSERT(field->kind == AstNode_Field);
		AstNode *type_expression = field->field.type_expression;
		if (type_expression) {
			Type *type = check_type(c, type_expression);
			for (AstNode *name = field->field.name_list; name != NULL; name = name->next) {
				GB_ASSERT(name->kind == AstNode_Identifier);
				Entity *param = make_entity_param(c, scope, name->identifier.token, type);
				add_entity(c, scope, name, param);
				variables[variable_index++] = param;
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
	Type *tuple = make_type_tuple();

	Entity **variables = gb_alloc_array(gb_arena_allocator(&c->entity_arena),
	                                    Entity *, list_count);
	isize variable_index = 0;
	for (AstNode *item = list; item != NULL; item = item->next) {
		Type *type = check_type(c, item);
		Token token = ast_node_token(item);
		token.string = make_string(""); // NOTE(bill): results are not named
		// TODO(bill): Should I have named results?
		Entity *param = make_entity_param(c, scope, token, type);
		// NOTE(bill): No need to record
		variables[variable_index++] = param;
	}
	tuple->tuple.variables = variables;
	tuple->tuple.variable_count = list_count;

	return tuple;
}


void check_procedure_type(Checker *c, Type *type, AstNode *proc_type_node) {
	isize param_count = 0;
	isize result_count = 0;

	// NOTE(bill): Each field can store multiple items
	for (AstNode *field = proc_type_node->procedure_type.param_list;
	     field != NULL;
	     field = field->next) {
		param_count += field->field.name_list_count;
	}

	for (AstNode *item = proc_type_node->procedure_type.results_list;
	     item != NULL;
	     item = item->next) {
		result_count++;
	}

	Type *params  = check_get_params (c, c->curr_scope, proc_type_node->procedure_type.param_list, param_count);
	Type *results = check_get_results(c, c->curr_scope, proc_type_node->procedure_type.results_list, result_count);

	type->procedure.scope = c->curr_scope;
	type->procedure.params = params;
	type->procedure.params_count = proc_type_node->procedure_type.param_count;
	type->procedure.results = results;
	type->procedure.results_count = proc_type_node->procedure_type.result_count;
}

void check_identifier(Checker *c, Operand *operand, AstNode *n, Type *named_type) {
	GB_ASSERT(n->kind == AstNode_Identifier);
	operand->mode = Addressing_Invalid;
	operand->expression = n;
	Entity *e = NULL;
	scope_lookup_parent_entity(c->curr_scope, n->identifier.token.string, NULL, &e);
	if (e == NULL) {
		print_checker_error(c, n->identifier.token,
		                    "Undeclared type/identifier: %.*s", LIT(n->identifier.token.string));
		return;
	}
	add_entity_use(c, n, e);

	Type *type = e->type;
	GB_ASSERT(type != NULL);

	switch (e->kind) {
	case Entity_Constant:
		if (type == &basic_types[Basic_Invalid])
			return;
		operand->value = e->constant.value;
		GB_ASSERT(operand->value.kind != Value_Invalid);
		operand->mode = Addressing_Constant;
		break;

	case Entity_Variable:
		e->variable.used = true;
		if (type == &basic_types[Basic_Invalid])
			return;
		operand->mode = Addressing_Variable;
		break;

	case Entity_TypeName:
		operand->mode = Addressing_Type;
		break;

	case Entity_Procedure:
		operand->mode = Addressing_Value;
		break;

	case Entity_Builtin:
		operand->builtin_id = e->builtin.id;
		operand->mode = Addressing_Builtin;
		break;

	default:
		GB_PANIC("Unknown EntityKind");
		break;
	}

	operand->type = type;
}

i64 check_array_count(Checker *c, AstNode *expression) {
	if (expression) {
		Operand operand = {};
		check_expression(c, &operand, expression);
		if (operand.mode != Addressing_Constant) {
			if (operand.mode != Addressing_Invalid) {
				print_checker_error(c, ast_node_token(expression), "Array count must be a constant");
			}
			return 0;
		}
		if (is_type_untyped(operand.type) || is_type_integer(operand.type)) {
			if (operand.value.kind == Value_Integer) {
				i64 count = operand.value.value_integer;
				if (count >= 0)
					return count;
				print_checker_error(c, ast_node_token(expression), "Invalid array count");
				return 0;
			}
		}

		print_checker_error(c, ast_node_token(expression), "Array count must be an integer");
	}
	return 0;
}

Type *check_type_expression_extra(Checker *c, AstNode *expression, Type *named_type) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	switch (expression->kind) {
	case AstNode_Identifier: {
		Operand operand = {};
		check_identifier(c, &operand, expression, named_type);
		switch (operand.mode) {
		case Addressing_Type: {
			Type *t = operand.type;
			set_base_type(named_type, t);
			return t;
		} break;

		case Addressing_Invalid:
			break;

		case Addressing_NoValue:
			err_str = expression_to_string(expression);
			print_checker_error(c, ast_node_token(expression), "`%s` used as a type", err_str);
			break;
		default:
			err_str = expression_to_string(expression);
			print_checker_error(c, ast_node_token(expression), "`%s` used as a type when not a type", err_str);
			break;
		}
	} break;

	case AstNode_ParenExpression:
		return check_type(c, expression->paren_expression.expression, named_type);

	case AstNode_ArrayType:
		if (expression->array_type.count != NULL) {
			Type *t = make_type_array(check_type(c, expression->array_type.element),
			                          check_array_count(c, expression->array_type.count));
			set_base_type(named_type, t);
			return t;
		} else {
			print_checker_error(c, ast_node_token(expression), "Empty array size");
			return NULL;
		}
		break;

	case AstNode_StructType: {
		Type *t = make_type_structure();
		set_base_type(named_type, t);
		check_struct_type(c, t, expression);
		return t;
	} break;

	case AstNode_PointerType: {
		Type *t = make_type_pointer(check_type(c, expression->pointer_type.type_expression));
		set_base_type(named_type, t);
		return t;
	} break;

	case AstNode_ProcedureType: {
		Type *t = alloc_type(Type_Procedure);
		set_base_type(named_type, t);
		check_open_scope(c, expression);
		check_procedure_type(c, t, expression);
		check_close_scope(c);
		return t;
	} break;

	default:
		err_str = expression_to_string(expression);
		print_checker_error(c, ast_node_token(expression), "`%s` is not a type", err_str);
		break;
	}

	Type *t = &basic_types[Basic_Invalid];
	set_base_type(named_type, t);
	return t;
}


Type *check_type(Checker *c, AstNode *expression, Type *named_type) {
	Value null_value = {Value_Invalid};
	Type *type = NULL;
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	switch (expression->kind) {
	case AstNode_Identifier: {
		Operand operand = {};
		check_identifier(c, &operand, expression, named_type);
		switch (operand.mode) {
		case Addressing_Type: {
			type = operand.type;
			set_base_type(named_type, type);
			goto end;
		} break;

		case Addressing_Invalid:
			break;

		case Addressing_NoValue:
			err_str = expression_to_string(expression);
			print_checker_error(c, ast_node_token(expression), "`%s` used as a type", err_str);
			break;
		default:
			err_str = expression_to_string(expression);
			print_checker_error(c, ast_node_token(expression), "`%s` used as a type when not a type", err_str);
			break;
		}
	} break;

	case AstNode_SelectorExpression: {
		Operand operand = {};
		check_selector(c, &operand, expression);

		if (operand.mode == Addressing_Type) {
			set_base_type(type, operand.type);
			return operand.type;
		}
	} break;

	case AstNode_ParenExpression:
		return check_type(c, expression->paren_expression.expression, named_type);

	case AstNode_ArrayType:
		type = make_type_array(check_type(c, expression->array_type.element),
		                       check_array_count(c, expression->array_type.count));
		set_base_type(named_type, type);
		goto end;
		break;

	case AstNode_StructType: {
		type = make_type_structure();
		set_base_type(named_type, type);
		check_struct_type(c, type, expression);
		goto end;
	} break;

	case AstNode_PointerType: {
		type = make_type_pointer(check_type(c, expression->pointer_type.type_expression));
		set_base_type(named_type, type);
		goto end;
	} break;

	case AstNode_ProcedureType: {
		type = alloc_type(Type_Procedure);
		set_base_type(named_type, type);
		check_procedure_type(c, type, expression);
		goto end;
	} break;

	default:
		err_str = expression_to_string(expression);
		print_checker_error(c, ast_node_token(expression), "`%s` is not a type", err_str);
		break;
	}

	type = &basic_types[Basic_Invalid];
	set_base_type(named_type, type);

end:
	GB_ASSERT(is_type_typed(type));
	add_type_and_value(c, expression, Addressing_Type, type, null_value);
	return type;
}


b32 check_unary_op(Checker *c, Operand *operand, Token op) {
	// TODO(bill): Handle errors correctly
	gbString str = NULL;
	defer (gb_string_free(str));
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
		if (!is_type_numeric(operand->type)) {
			str = expression_to_string(operand->expression);
			print_checker_error(c, op, "Operator `%.*s` is not allowed with `%s`", LIT(op.string), str);
		}
		break;

	case Token_Xor:
		if (!is_type_integer(operand->type)) {
			print_checker_error(c, op, "Operator `%.*s` is only allowed with integers", LIT(op.string));
		}
		break;

	case Token_Not:
		if (!is_type_boolean(operand->type)) {
			str = expression_to_string(operand->expression);
			print_checker_error(c, op, "Operator `%.*s` is only allowed on boolean expression", LIT(op.string));
		}
		break;

	default:
		print_checker_error(c, op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;
}

b32 check_binary_op(Checker *c, Operand *operand, Token op) {
	// TODO(bill): Handle errors correctly
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:
		if (!is_type_numeric(operand->type)) {
			print_checker_error(c, op, "Operator `%.*s` is only allowed with numeric expressions", LIT(op.string));
		}
		break;

	case Token_Mod:
	case Token_Or:
	case Token_Xor:
	case Token_AndNot:
		if (!is_type_integer(operand->type)) {
			print_checker_error(c, op, "Operand `%.*s` is only allowed with integers", LIT(op.string));
		}
		break;

	case Token_CmpAnd:
	case Token_CmpOr:
		if (!is_type_boolean(operand->type)) {
			print_checker_error(c, op, "Operator `%.*s` is only allowed with boolean expressions", LIT(op.string));
		}
		break;

	case Token_AddEq:
	case Token_SubEq:
	case Token_MulEq:
	case Token_QuoEq:
	case Token_ModEq:
	case Token_AndEq:
	case Token_OrEq:
	case Token_XorEq:
	case Token_AndNotEq:
	case Token_CmpAndEq:
	case Token_CmpOrEq:
		// TODO(bill): is this okay?
		return true;


	default:
		print_checker_error(c, op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;

}
b32 check_value_is_expressible(Checker *c, Value in_value, Type *type, Value *out_value) {
	if (in_value.kind == Value_Invalid)
		return true;

	if (is_type_boolean(type)) {
		return in_value.kind == Value_Bool;
	} else if (is_type_string(type)) {
		return in_value.kind == Value_String;
	} else if (is_type_integer(type)) {
		if (in_value.kind != Value_Integer)
			return false;
		if (out_value) *out_value = in_value;
		i64 i = in_value.value_integer;
		i64 s = 8*type_size_of(c->sizes, gb_arena_allocator(&c->entity_arena), type);
		u64 umax = ~0ull;
		if (s < 64)
			umax = (1ull << s) - 1ull;
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

		default: GB_PANIC("Unknown integer type!"); break;
		}
	} else if (is_type_float(type)) {
		Value v = value_to_float(in_value);
		if (v.kind != Value_Float)
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
		if (in_value.kind == Value_Pointer)
			return true;
		if (in_value.kind == Value_Integer)
			return true;
		if (out_value) *out_value = in_value;
	}

	return false;
}

void check_is_expressible(Checker *c, Operand *operand, Type *type) {
	GB_ASSERT(type->kind == Type_Basic);
	GB_ASSERT(operand->mode == Addressing_Constant);
	if (!check_value_is_expressible(c, operand->value, type, &operand->value)) {
		gbString a = type_to_string(operand->type);
		gbString b = type_to_string(type);
		defer (gb_string_free(a));
		defer (gb_string_free(b));
		if (is_type_numeric(operand->type) && is_type_numeric(type)) {
			if (!is_type_integer(operand->type) && is_type_integer(type)) {
				print_checker_error(c, ast_node_token(operand->expression), "`%s` truncated to `%s`", a, b);
			} else {
				print_checker_error(c, ast_node_token(operand->expression), "`%s` overflows to `%s`", a, b);
			}
		} else {
			print_checker_error(c, ast_node_token(operand->expression), "Cannot convert `%s` to `%s`", a, b);
		}

		operand->mode = Addressing_Invalid;
	}
}


void check_unary_expression(Checker *c, Operand *operand, Token op, AstNode *node) {
	if (op.kind == Token_Pointer) { // Pointer address
		if (operand->mode != Addressing_Variable) {
			gbString str = expression_to_string(node->unary_expression.operand);
			defer (gb_string_free(str));
			print_checker_error(c, op, "Cannot take the pointer address of `%s`", str);
			operand->mode = Addressing_Invalid;
			return;
		}
		operand->mode = Addressing_Value;
		operand->type = make_type_pointer(operand->type);
		return;
	}

	if (!check_unary_op(c, operand, op)) {
		operand->mode = Addressing_Invalid;
		return;
	}

	if (operand->mode == Addressing_Constant) {
		Type *type = get_base_type(operand->type);
		GB_ASSERT(type->kind == Type_Basic);
		i32 precision = 0;
		if (is_type_unsigned(type))
			precision = cast(i32)(8 * type_size_of(c->sizes, gb_arena_allocator(&c->entity_arena), type));
		operand->value = unary_operator_value(op, operand->value, precision);

		if (is_type_typed(type)) {
			if (node != NULL)
				operand->expression = node;
			check_is_expressible(c, operand, type);
		}
		return;
	}

	operand->mode = Addressing_Value;
}

b32 check_assignable_to(Checker *c, Operand *operand, Type *type);

void check_comparison(Checker *c, Operand *x, Operand *y, Token op) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	if (check_assignable_to(c, x, y->type) ||
	    check_assignable_to(c, y, x->type)) {
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
		print_checker_error(c, op, "Cannot compare expression, %s", err_str);
		return;
	}

	if (x->mode == Addressing_Constant &&
	    y->mode == Addressing_Constant) {
		x->value = make_value_bool(compare_values(op, x->value, y->value));
	} else {
		// TODO(bill): What should I do?
	}

	x->type = &basic_types[Basic_UntypedBool];
}

void check_binary_expression(Checker *c, Operand *x, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpression);
	Operand y = {};
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	check_expression(c, x, node->binary_expression.left);
	check_expression(c, &y, node->binary_expression.right);
	if (x->mode == Addressing_Invalid) return;
	if (y.mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		x->expression = y.expression;
		return;
	}

	convert_to_typed(c, x, y.type);
	if (x->mode == Addressing_Invalid) return;
	convert_to_typed(c, &y, x->type);
	if (y.mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		return;
	}

	Token op = node->binary_expression.op;
	if (token_is_comparison(op)) {
		check_comparison(c, x, &y, op);
		return;
	}

	if (!are_types_identical(x->type, y.type)) {
		if (x->type != &basic_types[Basic_Invalid] &&
		    y.type  != &basic_types[Basic_Invalid]) {
			gbString xt = type_to_string(x->type);
			gbString yt = type_to_string(y.type);
			defer (gb_string_free(xt));
			defer (gb_string_free(yt));
			err_str = expression_to_string(x->expression);
			print_checker_error(c, op, "Mismatched types in binary expression `%s` : `%s` vs `%s`", err_str, xt, yt);
		}
		x->mode = Addressing_Invalid;
		return;
	}

	if (!check_binary_op(c, x, op)) {
		x->mode = Addressing_Invalid;
		return;
	}

	if ((op.kind == Token_Quo || op.kind == Token_Mod) &&
	    (x->mode == Addressing_Constant || is_type_integer(x->type)) &&
	    y.mode == Addressing_Constant) {
		b32 fail = false;
		switch (y.value.kind) {
		case Value_Integer:
			if (y.value.value_integer == 0)
				fail = true;
			break;
		case Value_Float:
			if (y.value.value_float == 0.0)
				fail = true;
			break;
		}

		if (fail) {
			print_checker_error(c, ast_node_token(y.expression),
			                    "Division by zero not allowed");
			x->mode = Addressing_Invalid;
			return;
		}
	}

	if (x->mode == Addressing_Constant &&
	    y.mode  == Addressing_Constant) {
		Value a = x->value;
		Value b = y.value;

		Type *type = get_base_type(x->type);
		GB_ASSERT(type->kind == Type_Basic);
		if (op.kind == Token_Quo && is_type_integer(type)) {
			op.kind = Token_QuoEq; // NOTE(bill): Hack to get division of integers
		}
		x->value = binary_operator_value(op, a, b);
		if (is_type_typed(type)) {
			if (node != NULL)
				x->expression = node;
			check_is_expressible(c, x, type);
		}
		return;
	}

	x->mode = Addressing_Value;
}


void update_expression_type(Checker *c, AstNode *expression, Type *type, b32 final) {
	ExpressionInfo *found = map_get(&c->untyped, hash_pointer(expression));
	if (!found)
		return;

	switch (expression->kind) {
	case AstNode_UnaryExpression:
		if (found->value.kind != Value_Invalid)
			break;
		update_expression_type(c, expression->unary_expression.operand, type, final);
		break;

	case AstNode_BinaryExpression:
		if (found->value.kind != Value_Invalid)
			break;
		if (!token_is_comparison(expression->binary_expression.op)) {
			update_expression_type(c, expression->binary_expression.left,  type, final);
			update_expression_type(c, expression->binary_expression.right, type, final);
		}
	}

	if (!final && is_type_untyped(type)) {
		found->type = get_base_type(type);
	} else {
		found->type = type;
	}
}

void update_expression_value(Checker *c, AstNode *expression, Value value) {
	ExpressionInfo *found = map_get(&c->untyped, hash_pointer(expression));
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
			// NOTE(bill): Doesn't matter what the type is as it's still zero
			extra_text = " - Did you want `null`?";
		}
	}
	print_checker_error(c, ast_node_token(operand->expression), "Cannot convert `%s` to `%s`%s", expr_str, type_str, extra_text);

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
				update_expression_type(c, operand->expression, target_type, false);
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

b32 check_index_value(Checker *c, AstNode *index_value, i64 max_count, b32 bound_checks) {
	Operand operand = {Addressing_Invalid};
	check_expression(c, &operand, index_value);
	if (operand.mode == Addressing_Invalid)
		return false;

	convert_to_typed(c, &operand, &basic_types[Basic_int]);
	if (operand.mode == Addressing_Invalid)
		return false;

	if (!is_type_integer(operand.type)) {
		gbString expr_str = expression_to_string(operand.expression);
		print_checker_error(c, ast_node_token(operand.expression),
		                    "Index `%s` must be an integer", expr_str);
		gb_string_free(expr_str);
		return false;
	}

	if (operand.mode == Addressing_Constant) {
		if (bound_checks && max_count > 0) { // NOTE(bill): Do array bound checking
			i64 i = value_to_integer(operand.value).value_integer;
			if (i < 0) {
				gbString expr_str = expression_to_string(operand.expression);
				print_checker_error(c, ast_node_token(operand.expression),
				                    "Index `%s` cannot be a negative value", expr_str);
				gb_string_free(expr_str);
				return false;
			}

			if (i >= max_count) {
				gbString expr_str = expression_to_string(operand.expression);
				print_checker_error(c, ast_node_token(operand.expression),
				                    "Index `%s` is out of bounds range [0, %lld)", expr_str, max_count);
				gb_string_free(expr_str);
				return false;
			}
		}
	}

	// NOTE(bill): It's alright :D
	return true;
}

Entity *lookup_field(Type *type, AstNode *field_node, isize *index = NULL) {
	GB_ASSERT(field_node->kind == AstNode_Identifier);
	type = get_base_type(type);
	if (type->kind == Type_Pointer)
		type = get_base_type(type->pointer.element);

	String field_str = field_node->identifier.token.string;
	if (type->kind == Type_Structure) {
		for (isize i = 0; i < type->structure.field_count; i++) {
			Entity *f = type->structure.fields[i];
			GB_ASSERT(f->kind == Entity_Variable && f->variable.is_field);
			String str = f->token.string;
			if (are_strings_equal(field_str, str)) {
				if (index) *index = i;
				return f;
			}
		}
	} else {
		// TODO(bill): Array.count
		// TODO(bill): Array.elements
		// TODO(bill): Or should these be functions?
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
			print_checker_error(c, ast_node_token(op_expr), "`%s` has no field `%s`",
			                    op_str, sel_str);
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
			gbString call_str = expression_to_string(call);
			defer (gb_string_free(call_str));
			print_checker_error(c, ce->close, "`%s` arguments for `%s`, expected %td, got %td",
			                    err, call_str, bp->arg_count, ce->arg_list_count);
			return false;
		}
	}

	switch (id) {
	case BuiltinProcedure_size_of:
	case BuiltinProcedure_align_of:
	case BuiltinProcedure_offset_of:
		break;
	default:
		check_multi_expression(c, operand, ce->arg_list);
	}

	gbAllocator allocator = gb_arena_allocator(&c->entity_arena);

	switch (id) {
	case BuiltinProcedure_size_of: {
		Type *type = check_type(c, ce->arg_list);
		if (!type) {
			print_checker_error(c, ast_node_token(ce->arg_list), "Expected a type for `size_of`");
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_value_integer(type_size_of(c->sizes, allocator, type));
		operand->type = &basic_types[Basic_int];

	} break;

	case BuiltinProcedure_size_of_val:
		check_assignment(c, operand, NULL, make_string("argument of `size_of`"));
		if (operand->mode == Addressing_Invalid)
			return false;

		operand->mode = Addressing_Constant;
		operand->value = make_value_integer(type_size_of(c->sizes, allocator, operand->type));
		operand->type = &basic_types[Basic_int];
		break;

	case BuiltinProcedure_align_of: {
		Type *type = check_type(c, ce->arg_list);
		if (!type) {
			print_checker_error(c, ast_node_token(ce->arg_list), "Expected a type for `align_of`");
			return false;
		}
		operand->mode = Addressing_Constant;
		operand->value = make_value_integer(type_align_of(c->sizes, allocator, type));
		operand->type = &basic_types[Basic_int];
	} break;

	case BuiltinProcedure_align_of_val:
		check_assignment(c, operand, NULL, make_string("argument of `align_of`"));
		if (operand->mode == Addressing_Invalid)
			return false;

		operand->mode = Addressing_Constant;
		operand->value = make_value_integer(type_align_of(c->sizes, allocator, operand->type));
		operand->type = &basic_types[Basic_int];
		break;

	case BuiltinProcedure_offset_of: {
		Type *type = get_base_type(check_type(c, ce->arg_list));
		AstNode *field_arg = unparen_expression(ce->arg_list->next);
		if (type) {
			if (type->kind != Type_Structure) {
				print_checker_error(c, ast_node_token(ce->arg_list), "Expected a structure type for `offset_of`");
				return false;
			}
			if (field_arg->kind != AstNode_Identifier) {
				print_checker_error(c, ast_node_token(field_arg), "Expected an identifier for field argument");
				return false;
			}
		}

		isize index = 0;
		Entity *entity = lookup_field(type, field_arg, &index);
		if (entity == NULL) {
			gbString type_str = type_to_string(type);
			print_checker_error(c, ast_node_token(ce->arg_list),
			                    "`%s` has no field named `%s`", type_str, LIT(field_arg->identifier.token.string));
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_value_integer(type_offset_of(c->sizes, allocator, type, index));
		operand->type  = &basic_types[Basic_int];
	} break;

	case BuiltinProcedure_offset_of_val: {
		AstNode *arg = unparen_expression(ce->arg_list);
		if (arg->kind != AstNode_SelectorExpression) {
			gbString str = expression_to_string(arg);
			print_checker_error(c, ast_node_token(arg), "`%s` is not a selector expression", str);
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
			print_checker_error(c, ast_node_token(arg),
			                    "`%s` has no field named `%s`", type_str, LIT(s->selector->identifier.token.string));
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_value_integer(type_offset_of(c->sizes, allocator, type, index));
		operand->type  = &basic_types[Basic_int];
	} break;

	case BuiltinProcedure_static_assert:
		if (operand->mode != Addressing_Constant ||
		    !is_type_boolean(operand->type)) {
			gbString str = expression_to_string(ce->arg_list);
			defer (gb_string_free(str));
			print_checker_error(c, ast_node_token(call),
			                    "`%s` is not a constant boolean", str);
			return false;
		}
		if (!operand->value.value_bool) {
			gbString str = expression_to_string(ce->arg_list);
			defer (gb_string_free(str));
			print_checker_error(c, ast_node_token(call),
			                    "Static assertion: `%s`", str);
			return true;
		}
		break;

	case BuiltinProcedure_print:
	case BuiltinProcedure_println: {
		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next) {
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
	isize param_count = 0;
	if (proc_type->procedure.params)
		param_count = proc_type->procedure.params->tuple.variable_count;

 	if (ce->arg_list_count == 0 && param_count == 0)
		return;

	isize error_code = 0;

	if (ce->arg_list_count > param_count) {
		error_code = +1;
	} else {
		Entity **sig_params = proc_type->procedure.params->tuple.variables;
		isize param_index = 0;
		AstNode *call_arg = ce->arg_list;
		for (;
		     call_arg != NULL && param_index < param_count;
		     call_arg = call_arg->next) {
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

			if (param_index < param_count)
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
		if (error_code < 0)
			err_fmt = "Too few arguments for `%s`, expected %td arguments";
		else
			err_fmt = "Too many arguments for `%s`, expected %td arguments";

		gbString proc_str = expression_to_string(ce->proc);
		print_checker_error(c, ast_node_token(call), err_fmt, proc_str, param_count);
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
		print_checker_error(c, ast_node_token(e),
		                    "Cannot call a non-procedure: `%s`", str);

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
	if (check_assignable_to(c, operand, y))
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
	b32 const_expr = operand->mode == Addressing_Constant;
	b32 can_convert = false;

	if (const_expr && is_type_constant_type(type)) {
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
		print_checker_error(c, ast_node_token(operand->expression),
		                    "Cannot cast `%s` to `%s`", expr_str, type_str);

		operand->mode = Addressing_Invalid;
		return;
	}

	operand->type = type;
}



ExpressionKind check_expression_base(Checker *c, Operand *operand, AstNode *expression, Type *type_hint) {
	ExpressionKind kind = Expression_Statement;

	operand->mode = Addressing_Invalid;
	operand->type = &basic_types[Basic_Invalid];

	switch (expression->kind) {
	case AstNode_BadExpression:
		goto error;

	case AstNode_Identifier:
		check_identifier(c, operand, expression, type_hint);
		break;
	case AstNode_BasicLiteral: {
		BasicKind kind = Basic_Invalid;
		Token lit = expression->basic_literal;
		switch (lit.kind) {
		case Token_Integer: kind = Basic_UntypedInteger; break;
		case Token_Float:   kind = Basic_UntypedFloat;   break;
		case Token_String:  kind = Basic_UntypedString;  break;
		case Token_Rune:    kind = Basic_UntypedRune;    break;
		default:            GB_PANIC("Unknown literal"); break;
		}
		operand->mode  = Addressing_Constant;
		operand->type  = &basic_types[kind];
		operand->value = make_value_from_basic_literal(lit);
	} break;

	case AstNode_ParenExpression:
		kind = check_expression_base(c, operand, expression->paren_expression.expression);
		operand->expression = expression;
		break;

	case AstNode_UnaryExpression:
		check_expression(c, operand, expression->unary_expression.operand);
		if (operand->mode == Addressing_Invalid)
			goto error;
		check_unary_expression(c, operand, expression->unary_expression.op, expression);
		if (operand->mode == Addressing_Invalid)
			goto error;
		break;

	case AstNode_BinaryExpression:
		check_binary_expression(c, operand, expression);
		if (operand->mode == Addressing_Invalid)
			goto error;
		break;


	case AstNode_SelectorExpression:
		check_expression_base(c, operand, expression->selector_expression.operand);
		check_selector(c, operand, expression);
		break;

	case AstNode_IndexExpression: {
		check_expression(c, operand, expression->index_expression.expression);
		if (operand->mode == Addressing_Invalid)
			goto error;

		b32 valid = false;
		b32 bound_checks = false;
		i64 max_count = 0;
		Type *t = get_base_type(operand->type);
		switch (t->kind) {
		case Type_Basic:
			if (is_type_string(t)) {
				valid = true;
				if (operand->mode == Addressing_Constant) {
					max_count = operand->value.value_string.len;
					bound_checks = true;
				}
				operand->mode = Addressing_Value;
				operand->type = &basic_types[Basic_u8];
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->array.count;
			bound_checks = max_count > 0;
			if (operand->mode != Addressing_Variable)
				operand->mode = Addressing_Value;
			operand->type = t->array.element;
			break;

		case Type_Pointer:
			valid = true;
			bound_checks = false;
			max_count = 0;
			operand->mode = Addressing_Variable;
			operand->type = get_base_type(t->pointer.element);
			break;
		}

		if (!valid) {
			gbString str = expression_to_string(operand->expression);
			print_checker_error(c, ast_node_token(operand->expression),
			                    "Cannot index `%s`", str);
			gb_string_free(str);
			goto error;
		}

		if (expression->index_expression.value == NULL) {
			gbString str = expression_to_string(operand->expression);
			print_checker_error(c, ast_node_token(operand->expression),
			                    "Missing index for `%s`", str);
			gb_string_free(str);
			goto error;
		}

		check_index_value(c, expression->index_expression.value, max_count, bound_checks);
	} break;

	case AstNode_CastExpression: {
		Type *cast_type = check_type(c, expression->cast_expression.type_expression);
		check_expression_or_type(c, operand, expression->cast_expression.operand);
		if (operand->mode != Addressing_Invalid)
			check_cast_expression(c, operand, cast_type);

	} break;

	case AstNode_CallExpression:
		return check_call_expression(c, operand, expression);

	case AstNode_DereferenceExpression:
		check_expression_or_type(c, operand, expression->dereference_expression.operand);
		if (operand->mode == Addressing_Invalid) {
			goto error;
		} else {
			Type *t = get_base_type(operand->type);
			if (t->kind == Type_Pointer) {
				operand->mode = Addressing_Variable;
				operand->type = t->pointer.element;
 			} else {
 				gbString str = expression_to_string(operand->expression);
 				print_checker_error(c, ast_node_token(operand->expression),
 				                    "Cannot dereference `%s`", str);
 				gb_string_free(str);
 				goto error;
 			}
		}
		break;

	case AstNode_ProcedureType:
	case AstNode_PointerType:
	case AstNode_ArrayType:
	case AstNode_StructType:
		operand->mode = Addressing_Type;
		operand->type = check_type(c, expression);
		break;
	}

	kind = Expression_Expression;
	operand->expression = expression;
	goto after_error;

error:
	operand->mode = Addressing_Invalid;
	operand->expression = expression;
	goto after_error;

after_error:
	Type *type = NULL;
	Value value = {Value_Invalid};
	switch (operand->mode) {
	case Addressing_Invalid:
		type = &basic_types[Basic_Invalid];
		break;
	case Addressing_NoValue:
		type = NULL;
		break;
	case Addressing_Constant:
		type = operand->type;
		value = operand->value;
		break;
	default:
		type = operand->type;
		break;
	}

	if (type) {
		if (is_type_untyped(type)) {
			add_untyped(c, expression, false, operand->mode, type, value);
		} else {
			add_type_and_value(c, expression, operand->mode, type, value);
		}
	}
	return kind;
}

void check_multi_expression(Checker *c, Operand *operand, AstNode *expression) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	check_expression_base(c, operand, expression);
	switch (operand->mode) {
	default:
		return; // NOTE(bill): Valid

	case Addressing_NoValue:
		err_str = expression_to_string(expression);
		print_checker_error(c, ast_node_token(expression), "`%s` used as value", err_str);
		break;
	case Addressing_Type:
		err_str = expression_to_string(expression);
		print_checker_error(c, ast_node_token(expression), "`%s` is not an expression", err_str);
		break;
	}
	operand->mode = Addressing_Invalid;
}

// NOTE(bill): Just a santity checker
// TODO(bill): Remove this entirely
void check_not_tuple(Checker *c, Operand *operand) {
	if (operand->mode == Addressing_Value) {
		// NOTE(bill): Tuples are not first class thus never named
		if (operand->type->kind == Type_Tuple) {
			isize count = operand->type->tuple.variable_count;
			GB_ASSERT(count != 1);
			print_checker_error(c, ast_node_token(operand->expression),
			                    gb_bprintf("%td-valued tuple found where single value expected", count));
			operand->mode = Addressing_Invalid;
		}
	}
}

void check_expression(Checker *c, Operand *operand, AstNode *expression) {
	check_multi_expression(c, operand, expression);
	check_not_tuple(c, operand);
}


void check_expression_or_type(Checker *c, Operand *operand, AstNode *expression) {
	check_expression_base(c, operand, expression);
	check_not_tuple(c, operand);
	if (operand->mode == Addressing_NoValue) {
		AstNode *e = operand->expression;
		gbString str = expression_to_string(e);
		defer (gb_string_free(str));
		print_checker_error(c, ast_node_token(e),
		                    "`%s` used as value or type", str);
		operand->mode = Addressing_Invalid;
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

	case AstNode_CastExpression:
		str = gb_string_appendc(str, "cast(");
		str = write_expression_to_string(str, node->cast_expression.type_expression);
		str = gb_string_appendc(str, ")");
		str = write_expression_to_string(str, node->cast_expression.operand);
		break;


	case AstNode_PointerType:
		str = gb_string_appendc(str, "*");
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
