void           check_assignment        (Checker *c, Operand *operand, Type *type, String context_name);
b32            check_is_assignable_to  (Checker *c, Operand *operand, Type *type);
void           check_expr              (Checker *c, Operand *operand, AstNode *expression);
void           check_multi_expr        (Checker *c, Operand *operand, AstNode *expression);
void           check_expr_or_type      (Checker *c, Operand *operand, AstNode *expression);
ExpressionKind check_expr_base         (Checker *c, Operand *operand, AstNode *expression, Type *type_hint = NULL);
Type *         check_type              (Checker *c, AstNode *expression, Type *named_type = NULL);
void           check_selector          (Checker *c, Operand *operand, AstNode *node);
void           check_not_tuple         (Checker *c, Operand *operand);
void           convert_to_typed        (Checker *c, Operand *operand, Type *target_type);
gbString       expr_to_string          (AstNode *expression);
void           check_entity_decl       (Checker *c, Entity *e, DeclInfo *decl, Type *named_type);
void           check_proc_body         (Checker *c, Token token, DeclInfo *decl, Type *type, AstNode *body);
void           update_expr_type        (Checker *c, AstNode *e, Type *type, b32 final);


void check_struct_type(Checker *c, Type *struct_type, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_StructType);
	GB_ASSERT(struct_type->kind == Type_Structure);
	ast_node(st, StructType, node);

	Map<Entity *> entity_map = {};
	map_init(&entity_map, gb_heap_allocator());
	defer (map_destroy(&entity_map));

	isize field_count = 0;
	for (AstNode *field = st->field_list; field != NULL; field = field->next) {
		for (AstNode *name = field->Field.name_list; name != NULL; name = name->next) {
			GB_ASSERT(name->kind == AstNode_Ident);
			field_count++;
		}
	}

	Entity **fields = gb_alloc_array(c->allocator, Entity *, st->field_count);
	isize field_index = 0;
	for (AstNode *field = st->field_list; field != NULL; field = field->next) {
		ast_node(f, Field, field);
		Type *type = check_type(c, f->type);
		for (AstNode *name = f->name_list; name != NULL; name = name->next) {
			ast_node(i, Ident, name);
			Token name_token = i->token;
			// TODO(bill): is the curr_scope correct?
			Entity *e = make_entity_field(c->allocator, c->context.scope, name_token, type);
			HashKey key = hash_string(name_token.string);
			if (map_get(&entity_map, key)) {
				// TODO(bill): Scope checking already checks the declaration
				error(&c->error_collector, name_token, "`%.*s` is already declared in this structure", LIT(name_token.string));
			} else {
				map_set(&entity_map, key, e);
				fields[field_index++] = e;
			}
			add_entity_use(&c->info, name, e);
		}
	}
	struct_type->structure.fields = fields;
	struct_type->structure.field_count = field_count;
	struct_type->structure.is_packed = st->is_packed;
}

Type *check_get_params(Checker *c, Scope *scope, AstNode *field_list, isize field_count) {
	if (field_list == NULL || field_count == 0)
		return NULL;

	Type *tuple = make_type_tuple(c->allocator);

	Entity **variables = gb_alloc_array(c->allocator, Entity *, field_count);
	isize variable_index = 0;
	for (AstNode *field = field_list; field != NULL; field = field->next) {
		ast_node(f, Field, field);
		AstNode *type_expr = f->type;
		if (type_expr) {
			Type *type = check_type(c, type_expr);
			for (AstNode *name = f->name_list; name != NULL; name = name->next) {
				if (name->kind == AstNode_Ident) {
					ast_node(i, Ident, name);
					Entity *param = make_entity_param(c->allocator, scope, i->token, type);
					add_entity(c, scope, name, param);
					variables[variable_index++] = param;
				} else {
					error(&c->error_collector, ast_node_token(name), "Invalid parameter (invalid AST)");
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
	}
	tuple->tuple.variables = variables;
	tuple->tuple.variable_count = list_count;

	return tuple;
}


void check_procedure_type(Checker *c, Type *type, AstNode *proc_type_node) {
	ast_node(pt, ProcType, proc_type_node);

	isize param_count = pt->param_count;
	isize result_count = pt->result_count;

	// gb_printf("%td -> %td\n", param_count, result_count);

	Type *params  = check_get_params(c, c->context.scope, pt->param_list,   param_count);
	Type *results = check_get_results(c, c->context.scope, pt->result_list, result_count);

	type->proc.scope        = c->context.scope;
	type->proc.params       = params;
	type->proc.param_count  = pt->param_count;
	type->proc.results      = results;
	type->proc.result_count = pt->result_count;
}


void check_identifier(Checker *c, Operand *o, AstNode *n, Type *named_type) {
	GB_ASSERT(n->kind == AstNode_Ident);
	o->mode = Addressing_Invalid;
	o->expr = n;
	ast_node(i, Ident, n);
	Entity *e = scope_lookup_entity(c->context.scope, i->token.string);
	if (e == NULL) {
		error(&c->error_collector, i->token,
		    "Undeclared type or identifier `%.*s`", LIT(i->token.string));
		return;
	}
	add_entity_use(&c->info, n, e);

	if (e->type == NULL) {
		auto *found = map_get(&c->info.entities, hash_pointer(e));
		if (found != NULL) {
			check_entity_decl(c, e, *found, named_type);
		} else {
			GB_PANIC("Internal Compiler Error: DeclInfo not found!");
		}
	}

	if (e->type == NULL) {
		GB_PANIC("Compiler error: How did this happen? type: %s; identifier: %.*s\n", type_to_string(e->type), LIT(i->token.string));
		return;
	}

	switch (e->kind) {
	case Entity_Constant:
		add_declaration_dependency(c, e);
		if (e->type == t_invalid)
			return;
		o->value = e->constant.value;
		GB_ASSERT(o->value.kind != ExactValue_Invalid);
		o->mode = Addressing_Constant;
		break;

	case Entity_Variable:
		add_declaration_dependency(c, e);
		e->variable.used = true;
		if (e->type == t_invalid)
			return;
		o->mode = Addressing_Variable;
		break;

	case Entity_TypeName:
	case Entity_AliasName:
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
		check_expr(c, &o, e);
		if (o.mode != Addressing_Constant) {
			if (o.mode != Addressing_Invalid) {
				error(&c->error_collector, ast_node_token(e), "Array count must be a constant");
			}
			return 0;
		}
		if (is_type_untyped(o.type) || is_type_integer(o.type)) {
			if (o.value.kind == ExactValue_Integer) {
				i64 count = o.value.value_integer;
				if (count >= 0)
					return count;
				error(&c->error_collector, ast_node_token(e), "Invalid array count");
				return 0;
			}
		}

		error(&c->error_collector, ast_node_token(e), "Array count must be an integer");
	}
	return 0;
}

Type *check_type_expr_extra(Checker *c, AstNode *e, Type *named_type) {
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	switch (e->kind) {
	case_ast_node(i, Ident, e);
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
			err_str = expr_to_string(e);
			error(&c->error_collector, ast_node_token(e), "`%s` used as a type", err_str);
			break;
		default:
			err_str = expr_to_string(e);
			error(&c->error_collector, ast_node_token(e), "`%s` used as a type when not a type", err_str);
			break;
		}
	case_end;

	case_ast_node(pe, ParenExpr, e);
		return check_type(c, pe->expr, named_type);
	case_end;


	case_ast_node(at, ArrayType, e);
		if (at->count != NULL) {
			Type *t = make_type_array(c->allocator,
			                          check_type(c, at->elem),
			                          check_array_count(c, at->count));
			set_base_type(named_type, t);
			return t;
		} else {
			Type *t = make_type_slice(c->allocator, check_type(c, at->elem));
			set_base_type(named_type, t);
			return t;
		}
	case_end;

	case_ast_node(vt, VectorType, e);
		Type *elem = check_type(c, vt->elem);
		Type *be = get_base_type(elem);
		if (!is_type_vector(be) &&
			!(is_type_boolean(be) || is_type_numeric(be))) {
			err_str = type_to_string(elem);
			error(&c->error_collector, ast_node_token(vt->elem), "Vector element type must be a boolean, numerical, or vector. Got `%s`", err_str);
			break;
		} else {
			i64 count = check_array_count(c, vt->count);
			Type *t = make_type_vector(c->allocator, elem, count);
			set_base_type(named_type, t);
			return t;
		}
	case_end;

	case_ast_node(st, StructType, e);
		Type *t = make_type_structure(c->allocator);
		set_base_type(named_type, t);
		check_struct_type(c, t, e);
		return t;
	case_end;

	case_ast_node(pt, PointerType, e);
		Type *t = make_type_pointer(c->allocator, check_type(c, pt->type));
		set_base_type(named_type, t);
		return t;
	case_end;

	case_ast_node(pt, ProcType, e);
		Type *t = alloc_type(c->allocator, Type_Proc);
		set_base_type(named_type, t);
		check_open_scope(c, e);
		check_procedure_type(c, t, e);
		check_close_scope(c);
		return t;
	case_end;

	default:
		err_str = expr_to_string(e);
		error(&c->error_collector, ast_node_token(e), "`%s` is not a type", err_str);
		break;
	}

	Type *t = t_invalid;
	set_base_type(named_type, t);
	return t;
}


Type *check_type(Checker *c, AstNode *e, Type *named_type) {
	ExactValue null_value = {ExactValue_Invalid};
	Type *type = NULL;
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	switch (e->kind) {
	case_ast_node(i, Ident, e);
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
			err_str = expr_to_string(e);
			error(&c->error_collector, ast_node_token(e), "`%s` used as a type", err_str);
			break;
		default:
			err_str = expr_to_string(e);
			error(&c->error_collector, ast_node_token(e), "`%s` used as a type when not a type", err_str);
			break;
		}
	case_end;

	case_ast_node(se, SelectorExpr, e);
		Operand o = {};
		check_selector(c, &o, e);

		if (o.mode == Addressing_Type) {
			set_base_type(type, o.type);
			return o.type;
		}
	case_end;

	case_ast_node(pe, ParenExpr, e);
		return check_type(c, pe->expr, named_type);
	case_end;

	case_ast_node(at, ArrayType, e);
		if (at->count != NULL) {
			type = make_type_array(c->allocator,
			                       check_type(c, at->elem),
			                       check_array_count(c, at->count));
			set_base_type(named_type, type);
		} else {
			type = make_type_slice(c->allocator, check_type(c, at->elem));
			set_base_type(named_type, type);
		}
		goto end;
	case_end;


	case_ast_node(vt, VectorType, e);
		Type *elem = check_type(c, vt->elem);
		Type *be = get_base_type(elem);
		i64 count = check_array_count(c, vt->count);
		if (!is_type_boolean(be) && !is_type_numeric(be)) {
			err_str = type_to_string(elem);
			error(&c->error_collector, ast_node_token(vt->elem), "Vector element type must be numerical or a boolean. Got `%s`", err_str);
		}
		type = make_type_vector(c->allocator, elem, count);
		set_base_type(named_type, type);
		goto end;
	case_end;

	case_ast_node(st, StructType, e);
		type = make_type_structure(c->allocator);
		set_base_type(named_type, type);
		check_struct_type(c, type, e);
		goto end;
	case_end;

	case_ast_node(pt, PointerType, e);
		type = make_type_pointer(c->allocator, check_type(c, pt->type));
		set_base_type(named_type, type);
		goto end;
	case_end;

	case_ast_node(pt, ProcType, e);
		type = alloc_type(c->allocator, Type_Proc);
		set_base_type(named_type, type);
		check_procedure_type(c, type, e);
		goto end;
	case_end;

	default:
		err_str = expr_to_string(e);
		error(&c->error_collector, ast_node_token(e), "`%s` is not a type", err_str);
		break;
	}

	type = t_invalid;
	set_base_type(named_type, type);

end:
	GB_ASSERT(is_type_typed(type));
	add_type_and_value(&c->info, e, Addressing_Type, type, null_value);
	return type;
}


b32 check_unary_op(Checker *c, Operand *o, Token op) {
	// TODO(bill): Handle errors correctly
	Type *type = get_base_type(base_vector_type(get_base_type(o->type)));
	gbString str = NULL;
	defer (gb_string_free(str));
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
		if (!is_type_numeric(type)) {
			str = expr_to_string(o->expr);
			error(&c->error_collector, op, "Operator `%.*s` is not allowed with `%s`", LIT(op.string), str);
		}
		break;

	case Token_Xor:
		if (!is_type_integer(type)) {
			error(&c->error_collector, op, "Operator `%.*s` is only allowed with integers", LIT(op.string));
		}
		break;

	case Token_Not:
		if (!is_type_boolean(type)) {
			str = expr_to_string(o->expr);
			error(&c->error_collector, op, "Operator `%.*s` is only allowed on boolean expression", LIT(op.string));
		}
		break;

	default:
		error(&c->error_collector, op, "Unknown operator `%.*s`", LIT(op.string));
		return false;
	}

	return true;
}

b32 check_binary_op(Checker *c, Operand *o, Token op) {
	// TODO(bill): Handle errors correctly
	Type *type = get_base_type(base_vector_type(o->type));
	switch (op.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Mul:
	case Token_Quo:

	case Token_AddEq:
	case Token_SubEq:
	case Token_MulEq:
	case Token_QuoEq:
		if (!is_type_numeric(type)) {
			error(&c->error_collector, op, "Operator `%.*s` is only allowed with numeric expressions", LIT(op.string));
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
		if (!is_type_integer(type)) {
			error(&c->error_collector, op, "Operator `%.*s` is only allowed with integers", LIT(op.string));
			return false;
		}
		break;

	case Token_CmpAnd:
	case Token_CmpOr:

	case Token_CmpAndEq:
	case Token_CmpOrEq:
		if (!is_type_boolean(type)) {
			error(&c->error_collector, op, "Operator `%.*s` is only allowed with boolean expressions", LIT(op.string));
			return false;
		}
		break;

	default:
		error(&c->error_collector, op, "Unknown operator `%.*s`", LIT(op.string));
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
		gbString a = expr_to_string(o->expr);
		gbString b = type_to_string(type);
		defer (gb_string_free(a));
		defer (gb_string_free(b));
		if (is_type_numeric(o->type) && is_type_numeric(type)) {
			if (!is_type_integer(o->type) && is_type_integer(type)) {
				error(&c->error_collector, ast_node_token(o->expr), "`%s` truncated to `%s`", a, b);
			} else {
				error(&c->error_collector, ast_node_token(o->expr), "`%s` overflows `%s`", a, b);
			}
		} else {
			error(&c->error_collector, ast_node_token(o->expr), "Cannot convert `%s` to `%s`", a, b);
		}

		o->mode = Addressing_Invalid;
	}
}

b32 check_is_expr_vector_index(Checker *c, AstNode *expr) {
	// HACK(bill): Handle this correctly. Maybe with a custom AddressingMode
	expr = unparen_expr(expr);
	if (expr->kind == AstNode_IndexExpr) {
		ast_node(ie, IndexExpr, expr);
		Type *t = type_of_expr(&c->info, ie->expr);
		if (t != NULL) {
			return is_type_vector(get_base_type(t));
		}
	}
	return false;
}

void check_unary_expr(Checker *c, Operand *o, Token op, AstNode *node) {
	if (op.kind == Token_Pointer) { // Pointer address
		if (o->mode != Addressing_Variable ||
		    check_is_expr_vector_index(c, o->expr)) {
			ast_node(ue, UnaryExpr, node);
			gbString str = expr_to_string(ue->expr);
			defer (gb_string_free(str));
			error(&c->error_collector, op, "Cannot take the pointer address of `%s`", str);
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
				o->expr = node;
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
		error(&c->error_collector, op, "Cannot compare expression, %s", err_str);
		return;
	}

	if (x->mode == Addressing_Constant &&
	    y->mode == Addressing_Constant) {
		x->value = make_exact_value_bool(compare_exact_values(op, x->value, y->value));
	} else {
		x->mode = Addressing_Value;

		update_expr_type(c, x->expr, default_type(x->type), true);
		update_expr_type(c, y->expr, default_type(y->type), true);
	}

	if (is_type_vector(get_base_type(y->type))) {
		x->type = make_type_vector(c->allocator, t_bool, get_base_type(y->type)->vector.count);
	} else {
		x->type = t_untyped_bool;
	}
}

void check_shift(Checker *c, Operand *x, Operand *y, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	ast_node(be, BinaryExpr, node);


	ExactValue x_val = {};
	if (x->mode == Addressing_Constant) {
		x_val = exact_value_to_integer(x->value);
	}

	b32 x_is_untyped = is_type_untyped(x->type);
	if (!(is_type_integer(x->type) || (x_is_untyped && x_val.kind == ExactValue_Integer))) {
		gbString err_str = expr_to_string(x->expr);
		defer (gb_string_free(err_str));
		error(&c->error_collector, ast_node_token(node),
		      "Shifted operand `%s` must be an integer", err_str);
		x->mode = Addressing_Invalid;
		return;
	}

	if (is_type_unsigned(y->type)) {

	} else if (is_type_untyped(y->type)) {
		convert_to_typed(c, y, t_untyped_integer);
		if (y->mode == Addressing_Invalid) {
			x->mode = Addressing_Invalid;
			return;
		}
	} else {
		gbString err_str = expr_to_string(y->expr);
		defer (gb_string_free(err_str));
		error(&c->error_collector, ast_node_token(node),
		      "Shift amount `%s` must be an unsigned integer", err_str);
		x->mode = Addressing_Invalid;
		return;
	}


	if (x->mode == Addressing_Constant) {
		if (y->mode == Addressing_Constant) {
			ExactValue y_val = exact_value_to_integer(y->value);
			if (y_val.kind != ExactValue_Integer) {
				gbString err_str = expr_to_string(y->expr);
				defer (gb_string_free(err_str));
				error(&c->error_collector, ast_node_token(node),
				      "Shift amount `%s` must be an unsigned integer", err_str);
				x->mode = Addressing_Invalid;
				return;
			}

			u64 amount = cast(u64)y_val.value_integer;
			if (amount > 1074) {
				gbString err_str = expr_to_string(y->expr);
				defer (gb_string_free(err_str));
				error(&c->error_collector, ast_node_token(node),
				      "Shift amount too large: `%s`", err_str);
				x->mode = Addressing_Invalid;
				return;
			}

			if (!is_type_integer(x->type)) {
				// NOTE(bill): It could be an untyped float but still representable
				// as an integer
				x->type = t_untyped_integer;
			}

			x->value = exact_value_shift(be->op, x_val, make_exact_value_integer(amount));

			if (is_type_typed(x->type)) {
				check_is_expressible(c, x, get_base_type(x->type));
			}
			return;
		}

		if (x_is_untyped) {
			ExpressionInfo *info = map_get(&c->info.untyped, hash_pointer(x->expr));
			if (info != NULL) {
				info->is_lhs = true;
			}
			x->mode = Addressing_Value;
			return;
		}
	}

	if (y->mode == Addressing_Constant && y->value.value_integer < 0) {
		gbString err_str = expr_to_string(y->expr);
		defer (gb_string_free(err_str));
		error(&c->error_collector, ast_node_token(node),
		      "Shift amount cannot be negative: `%s`", err_str);
	}

	x->mode = Addressing_Value;
}

b32 check_castable_to(Checker *c, Operand *operand, Type *y) {
	if (check_is_assignable_to(c, operand, y))
		return true;

	Type *x = operand->type;
	Type *xb = get_base_type(x);
	Type *yb = get_base_type(y);
	if (are_types_identical(xb, yb))
		return true;


	// Cast between booleans and integers
	if (is_type_boolean(x) || is_type_integer(x)) {
		if (is_type_boolean(y) || is_type_integer(y))
			return true;
	}

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

	// // untyped integers -> pointers
	// if (is_type_untyped(xb) && is_type_integer(xb)) {
	// 	if (is_type_pointer(yb))
	// 		return true;
	// }

	// (u)int <-> pointer
	if (is_type_pointer(xb) || (is_type_int_or_uint(xb) && !is_type_untyped(xb))) {
		if (is_type_pointer(yb))
			return true;
	}
	if (is_type_pointer(xb)) {
		if (is_type_pointer(yb) || (is_type_int_or_uint(yb) && !is_type_untyped(yb)))
			return true;
	}

	// []byte/[]u8 <-> string
	if (is_type_u8_slice(xb) && is_type_string(yb)) {
		return true;
	}
	if (is_type_string(xb) && is_type_u8_slice(yb)) {
		return true;
	}

	return false;
}

void check_binary_expr(Checker *c, Operand *x, AstNode *node) {
	GB_ASSERT(node->kind == AstNode_BinaryExpr);
	Operand y_ = {}, *y = &y_;
	gbString err_str = NULL;
	defer (gb_string_free(err_str));


	ast_node(be, BinaryExpr, node);

	if (be->op.kind == Token_as) {
		check_expr(c, x, be->left);
		Type *type = check_type(c, be->right);
		if (x->mode == Addressing_Invalid)
			return;

		b32 is_const_expr = x->mode == Addressing_Constant;
		b32 can_convert = false;

		if (is_const_expr && is_type_constant_type(type)) {
			Type *base_type = get_base_type(type);
			if (base_type->kind == Type_Basic) {
				if (check_value_is_expressible(c, x->value, base_type, &x->value)) {
					can_convert = true;
				}
			}
		} else if (check_castable_to(c, x, type)) {
			x->mode = Addressing_Value;
			can_convert = true;
		}

		if (!can_convert) {
			gbString expr_str = expr_to_string(x->expr);
			gbString type_str = type_to_string(type);
			defer (gb_string_free(expr_str));
			defer (gb_string_free(type_str));
			error(&c->error_collector, ast_node_token(x->expr), "Cannot cast `%s` to `%s`", expr_str, type_str);

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
		return;
	} else if (be->op.kind == Token_transmute) {
		check_expr(c, x, be->left);
		Type *type = check_type(c, be->right);
		if (x->mode == Addressing_Invalid)
			return;

		if (x->mode == Addressing_Constant) {
			gbString expr_str = expr_to_string(x->expr);
			defer (gb_string_free(expr_str));
			error(&c->error_collector, ast_node_token(x->expr), "Cannot transmute constant expression: `%s`", expr_str);
			x->mode = Addressing_Invalid;
			return;
		}

		if (is_type_untyped(x->type)) {
			gbString expr_str = expr_to_string(x->expr);
			defer (gb_string_free(expr_str));
			error(&c->error_collector, ast_node_token(x->expr), "Cannot transmute untyped expression: `%s`", expr_str);
			x->mode = Addressing_Invalid;
			return;
		}

		i64 otz = type_size_of(c->sizes, c->allocator, x->type);
		i64 ttz = type_size_of(c->sizes, c->allocator, type);
		if (otz != ttz) {
			gbString expr_str = expr_to_string(x->expr);
			gbString type_str = type_to_string(type);
			defer (gb_string_free(expr_str));
			defer (gb_string_free(type_str));
			error(&c->error_collector, ast_node_token(x->expr), "Cannot transmute `%s` to `%s`, %lld vs %lld bytes", expr_str, type_str, otz, ttz);
			x->mode = Addressing_Invalid;
			return;
		}

		x->type = type;

		return;
	}

	check_expr(c, x, be->left);
	check_expr(c, y, be->right);
	if (x->mode == Addressing_Invalid) {
		return;
	}
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		x->expr = y->expr;
		return;
	}

	if (token_is_shift(be->op)) {
		check_shift(c, x, y, node);
		return;
	}

	convert_to_typed(c, x, y->type);
	if (x->mode == Addressing_Invalid) return;
	convert_to_typed(c, y, x->type);
	if (y->mode == Addressing_Invalid) {
		x->mode = Addressing_Invalid;
		return;
	}

	Token op = be->op;
	if (token_is_comparison(op)) {
		check_comparison(c, x, y, op);
		return;
	}

	if (!are_types_identical(x->type, y->type)) {
		if (x->type != t_invalid &&
		    y->type  != t_invalid) {
			gbString xt = type_to_string(x->type);
			gbString yt = type_to_string(y->type);
			defer (gb_string_free(xt));
			defer (gb_string_free(yt));
			err_str = expr_to_string(x->expr);
			error(&c->error_collector, op, "Mismatched types in binary expression `%s` : `%s` vs `%s`", err_str, xt, yt);
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
				error(&c->error_collector, ast_node_token(y->expr), "Division by zero not allowed");
				x->mode = Addressing_Invalid;
				return;
			}
		}
	}

	if (x->mode == Addressing_Constant &&
	    y->mode == Addressing_Constant) {
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
				x->expr = node;
			check_is_expressible(c, x, type);
		}
		return;
	}

	x->mode = Addressing_Value;
}


void update_expr_type(Checker *c, AstNode *e, Type *type, b32 final) {
	HashKey key = hash_pointer(e);
	ExpressionInfo *found = map_get(&c->info.untyped, key);
	if (found == NULL)
		return;

	switch (e->kind) {
	case_ast_node(ue, UnaryExpr, e);
		if (found->value.kind != ExactValue_Invalid)
			break;
		update_expr_type(c, ue->expr, type, final);
	case_end;

	case_ast_node(be, BinaryExpr, e);
		if (found->value.kind != ExactValue_Invalid)
			break;
		if (!token_is_comparison(be->op)) {
			if (token_is_shift(be->op)) {
				update_expr_type(c, be->left,  type, final);
			} else {
				update_expr_type(c, be->left,  type, final);
				update_expr_type(c, be->right, type, final);
			}
		}
	case_end;
	}

	if (!final && is_type_untyped(type)) {
		found->type = get_base_type(type);
		map_set(&c->info.untyped, key, *found);
	} else {
		ExpressionInfo old = *found;
		map_remove(&c->info.untyped, key);

		if (old.is_lhs && !is_type_integer(type)) {
			gbString expr_str = expr_to_string(e);
			gbString type_str = type_to_string(type);
			defer (gb_string_free(expr_str));
			defer (gb_string_free(type_str));
			error(&c->error_collector, ast_node_token(e), "Shifted operand %s must be an integer, got %s", expr_str, type_str);
			return;
		}

		add_type_and_value(&c->info, e, found->mode, type, found->value);
	}
}

void update_expr_value(Checker *c, AstNode *e, ExactValue value) {
	ExpressionInfo *found = map_get(&c->info.untyped, hash_pointer(e));
	if (found)
		found->value = value;
}

void convert_untyped_error(Checker *c, Operand *operand, Type *target_type) {
	gbString expr_str = expr_to_string(operand->expr);
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
	error(&c->error_collector, ast_node_token(operand->expr), "Cannot convert `%s` to `%s`%s", expr_str, type_str, extra_text);

	operand->mode = Addressing_Invalid;
}

void convert_to_typed(Checker *c, Operand *operand, Type *target_type) {
	GB_ASSERT_NOT_NULL(target_type);
	if (operand->mode == Addressing_Invalid ||
	    is_type_typed(operand->type) ||
	    target_type == t_invalid) {
		return;
	}

	if (is_type_untyped(target_type)) {
		Type *x = operand->type;
		Type *y = target_type;
		if (is_type_numeric(x) && is_type_numeric(y)) {
			if (x < y) {
				operand->type = target_type;
				update_expr_type(c, operand->expr, target_type, false);
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
			update_expr_value(c, operand->expr, operand->value);
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
			target_type = t_untyped_pointer;
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
	check_expr(c, &operand, index_value);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	convert_to_typed(c, &operand, t_int);
	if (operand.mode == Addressing_Invalid) {
		if (value) *value = 0;
		return false;
	}

	if (!is_type_integer(operand.type)) {
		gbString expr_str = expr_to_string(operand.expr);
		error(&c->error_collector, ast_node_token(operand.expr),
		            "Index `%s` must be an integer", expr_str);
		gb_string_free(expr_str);
		if (value) *value = 0;
		return false;
	}

	if (operand.mode == Addressing_Constant) {
		if (max_count >= 0) { // NOTE(bill): Do array bound checking
			i64 i = exact_value_to_integer(operand.value).value_integer;
			if (i < 0) {
				gbString expr_str = expr_to_string(operand.expr);
				error(&c->error_collector, ast_node_token(operand.expr),
				            "Index `%s` cannot be a negative value", expr_str);
				gb_string_free(expr_str);
				if (value) *value = 0;
				return false;
			}

			if (value) *value = i;

			if (i >= max_count) {
				gbString expr_str = expr_to_string(operand.expr);
				error(&c->error_collector, ast_node_token(operand.expr),
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
	GB_ASSERT(type != NULL);
	GB_ASSERT(field_node->kind == AstNode_Ident);
	type = get_base_type(type);
	if (type->kind == Type_Pointer)
		type = get_base_type(type->pointer.elem);

	ast_node(i, Ident, field_node);
	String field_str = i->token.string;
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
	GB_ASSERT(node->kind == AstNode_SelectorExpr);

	ast_node(se, SelectorExpr, node);
	AstNode *op_expr  = se->expr;
	AstNode *selector = se->selector;
	if (selector) {
		Entity *entity = lookup_field(operand->type, selector);
		if (entity == NULL) {
			gbString op_str  = expr_to_string(op_expr);
			gbString sel_str = expr_to_string(selector);
			defer (gb_string_free(op_str));
			defer (gb_string_free(sel_str));
			error(&c->error_collector, ast_node_token(op_expr), "`%s` has no field `%s`", op_str, sel_str);
			operand->mode = Addressing_Invalid;
			operand->expr = node;
			return;
		}
		add_entity_use(&c->info, selector, entity);

		operand->type = entity->type;
		operand->expr = node;
		if (operand->mode != Addressing_Variable)
			operand->mode = Addressing_Value;
	} else {
		operand->mode = Addressing_Invalid;
		operand->expr = node;
	}

}

b32 check_builtin_procedure(Checker *c, Operand *operand, AstNode *call, i32 id) {
	GB_ASSERT(call->kind == AstNode_CallExpr);
	ast_node(ce, CallExpr, call);
	BuiltinProc *bp = &builtin_procs[id];
	{
		char *err = NULL;
		if (ce->arg_list_count < bp->arg_count)
			err = "Too few";
		if (ce->arg_list_count > bp->arg_count && !bp->variadic)
			err = "Too many";
		if (err) {
			ast_node(proc, Ident, ce->proc);
			error(&c->error_collector, ce->close, "`%s` arguments for `%.*s`, expected %td, got %td",
			      err, LIT(proc->token.string),
			      bp->arg_count, ce->arg_list_count);
			return false;
		}
	}

	switch (id) {
	case BuiltinProc_size_of:
	case BuiltinProc_align_of:
	case BuiltinProc_offset_of:
		// NOTE(bill): The first arg is a Type, this will be checked case by case
		break;
	default:
		check_multi_expr(c, operand, ce->arg_list);
	}

	switch (id) {
	case BuiltinProc_size_of: {
		// size_of :: proc(Type)
		Type *type = check_type(c, ce->arg_list);
		if (!type) {
			error(&c->error_collector, ast_node_token(ce->arg_list), "Expected a type for `size_of`");
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_size_of(c->sizes, c->allocator, type));
		operand->type = t_int;

	} break;

	case BuiltinProc_size_of_val:
		// size_of_val :: proc(val)
		check_assignment(c, operand, NULL, make_string("argument of `size_of`"));
		if (operand->mode == Addressing_Invalid)
			return false;

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_size_of(c->sizes, c->allocator, operand->type));
		operand->type = t_int;
		break;

	case BuiltinProc_align_of: {
		// align_of :: proc(Type)
		Type *type = check_type(c, ce->arg_list);
		if (!type) {
			error(&c->error_collector, ast_node_token(ce->arg_list), "Expected a type for `align_of`");
			return false;
		}
		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_align_of(c->sizes, c->allocator, type));
		operand->type = t_int;
	} break;

	case BuiltinProc_align_of_val:
		// align_of_val :: proc(val)
		check_assignment(c, operand, NULL, make_string("argument of `align_of`"));
		if (operand->mode == Addressing_Invalid)
			return false;

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_align_of(c->sizes, c->allocator, operand->type));
		operand->type = t_int;
		break;

	case BuiltinProc_offset_of: {
		// offset_val :: proc(Type, field)
		Type *type = get_base_type(check_type(c, ce->arg_list));
		AstNode *field_arg = unparen_expr(ce->arg_list->next);
		if (type) {
			if (type->kind != Type_Structure) {
				error(&c->error_collector, ast_node_token(ce->arg_list), "Expected a structure type for `offset_of`");
				return false;
			}
			if (field_arg == NULL ||
			    field_arg->kind != AstNode_Ident) {
				error(&c->error_collector, ast_node_token(field_arg), "Expected an identifier for field argument");
				return false;
			}
		}

		isize index = 0;
		Entity *entity = lookup_field(type, field_arg, &index);
		if (entity == NULL) {
			ast_node(arg, Ident, field_arg);
			gbString type_str = type_to_string(type);
			error(&c->error_collector, ast_node_token(ce->arg_list),
			      "`%s` has no field named `%.*s`", type_str, LIT(arg->token.string));
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_offset_of(c->sizes, c->allocator, type, index));
		operand->type  = t_int;
	} break;

	case BuiltinProc_offset_of_val: {
		// offset_val :: proc(val)
		AstNode *arg = unparen_expr(ce->arg_list);
		if (arg->kind != AstNode_SelectorExpr) {
			gbString str = expr_to_string(arg);
			error(&c->error_collector, ast_node_token(arg), "`%s` is not a selector expression", str);
			return false;
		}
		ast_node(s, SelectorExpr, arg);

		check_expr(c, operand, s->expr);
		if (operand->mode == Addressing_Invalid)
			return false;

		Type *type = operand->type;
		if (get_base_type(type)->kind == Type_Pointer) {
			Type *p = get_base_type(type);
			if (get_base_type(p)->kind == Type_Structure)
				type = p->pointer.elem;
		}

		isize index = 0;
		Entity *entity = lookup_field(type, s->selector, &index);
		if (entity == NULL) {
			ast_node(i, Ident, s->selector);
			gbString type_str = type_to_string(type);
			error(&c->error_collector, ast_node_token(arg),
			      "`%s` has no field named `%.*s`", type_str, LIT(i->token.string));
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = make_exact_value_integer(type_offset_of(c->sizes, c->allocator, type, index));
		operand->type  = t_int;
	} break;

	case BuiltinProc_static_assert:
		// static_assert :: proc(cond: bool)
		// TODO(bill): Should `static_assert` and `assert` be unified?

		if (operand->mode != Addressing_Constant ||
		    !is_type_boolean(operand->type)) {
			gbString str = expr_to_string(ce->arg_list);
			defer (gb_string_free(str));
			error(&c->error_collector, ast_node_token(call),
			      "`%s` is not a constant boolean", str);
			return false;
		}
		if (!operand->value.value_bool) {
			gbString str = expr_to_string(ce->arg_list);
			defer (gb_string_free(str));
			error(&c->error_collector, ast_node_token(call),
			      "Static assertion: `%s`", str);
			return true;
		}
		break;

	// TODO(bill): Should these be procedures and are their names appropriate?
	case BuiltinProc_len:
	case BuiltinProc_cap: {
		Type *t = get_base_type(operand->type);

		AddressingMode mode = Addressing_Invalid;
		ExactValue value = {};

		switch (t->kind) {
		case Type_Basic:
			if (id == BuiltinProc_len) {
				if (is_type_string(t)) {
					if (operand->mode == Addressing_Constant) {
						mode = Addressing_Constant;
						value = make_exact_value_integer(operand->value.value_string);
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

		case Type_Vector:
			mode = Addressing_Constant;
			value = make_exact_value_integer(t->vector.count);
			break;

		case Type_Slice:
			mode = Addressing_Value;
			break;
		}

		if (mode == Addressing_Invalid) {
			gbString str = expr_to_string(operand->expr);
			error(&c->error_collector, ast_node_token(operand->expr),
			      "Invalid expression `%s` for `%.*s`",
			      str, LIT(bp->name));
			gb_string_free(str);
			return false;
		}

		operand->mode = mode;
		operand->type = t_int;
		operand->value = value;

	} break;

	case BuiltinProc_copy: {
		// copy :: proc(x, y: []Type) -> int
		Type *dest_type = NULL, *src_type = NULL;

		Type *d = get_base_type(operand->type);
		if (d->kind == Type_Slice)
			dest_type = d->slice.elem;

		Operand op = {};
		check_expr(c, &op, ce->arg_list->next);
		if (op.mode == Addressing_Invalid)
			return false;
		Type *s = get_base_type(op.type);
		if (s->kind == Type_Slice)
			src_type = s->slice.elem;

		if (dest_type == NULL || src_type == NULL) {
			error(&c->error_collector, ast_node_token(call), "`copy` only expects slices as arguments");
			return false;
		}

		if (!are_types_identical(dest_type, src_type)) {
			gbString d_arg = expr_to_string(ce->arg_list);
			gbString s_arg = expr_to_string(ce->arg_list->next);
			gbString d_str = type_to_string(dest_type);
			gbString s_str = type_to_string(src_type);
			defer (gb_string_free(d_arg));
			defer (gb_string_free(s_arg));
			defer (gb_string_free(d_str));
			defer (gb_string_free(s_str));
			error(&c->error_collector, ast_node_token(call),
			      "Arguments to `copy`, %s, %s, have different elem types: %s vs %s",
			      d_arg, s_arg, d_str, s_str);
			return false;
		}

		operand->type = t_int; // Returns number of elems copied
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_append: {
		// append :: proc(x : ^[]Type, y : Type) -> bool
		Type *x_type = NULL, *y_type = NULL;
		x_type = get_base_type(operand->type);

		Operand op = {};
		check_expr(c, &op, ce->arg_list->next);
		if (op.mode == Addressing_Invalid)
			return false;
		y_type = get_base_type(op.type);

		if (!(is_type_pointer(x_type) && is_type_slice(x_type->pointer.elem))) {
			error(&c->error_collector, ast_node_token(call), "First argument to `append` must be a pointer to a slice");
			return false;
		}

		Type *elem_type = x_type->pointer.elem->slice.elem;
		if (!check_is_assignable_to(c, &op, elem_type)) {
			gbString d_arg = expr_to_string(ce->arg_list);
			gbString s_arg = expr_to_string(ce->arg_list->next);
			gbString d_str = type_to_string(elem_type);
			gbString s_str = type_to_string(y_type);
			defer (gb_string_free(d_arg));
			defer (gb_string_free(s_arg));
			defer (gb_string_free(d_str));
			defer (gb_string_free(s_str));
			error(&c->error_collector, ast_node_token(call),
			      "Arguments to `append`, %s, %s, have different element types: %s vs %s",
			      d_arg, s_arg, d_str, s_str);
			return false;
		}

		operand->type = t_bool; // Returns if it was successful
		operand->mode = Addressing_Value;
	} break;

	case BuiltinProc_print:
	case BuiltinProc_println: {
		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next) {
			// TOOD(bill): `check_assignment` doesn't allow tuples at the moment, should it?
			// Or should we destruct the tuple and use each elem?
			check_assignment(c, operand, NULL, make_string("argument"));
			if (operand->mode == Addressing_Invalid)
				return false;
		}
	} break;
	}

	return true;
}


void check_call_arguments(Checker *c, Operand *operand, Type *proc_type, AstNode *call) {
	GB_ASSERT(call->kind == AstNode_CallExpr);
	GB_ASSERT(proc_type->kind == Type_Proc);
	ast_node(ce, CallExpr, call);
	isize error_code = 0;
	isize param_index = 0;
	isize param_count = 0;

	if (proc_type->proc.params)
		param_count = proc_type->proc.params->tuple.variable_count;

 	if (ce->arg_list_count == 0 && param_count == 0)
		return;

	if (ce->arg_list_count > param_count) {
		error_code = +1;
	} else {
		Entity **sig_params = proc_type->proc.params->tuple.variables;
		AstNode *call_arg = ce->arg_list;
		for (; call_arg != NULL; call_arg = call_arg->next) {
			check_multi_expr(c, operand, call_arg);
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

		gbString proc_str = expr_to_string(ce->proc);
		error(&c->error_collector, ast_node_token(call), err_fmt, proc_str, param_count);
		gb_string_free(proc_str);

		operand->mode = Addressing_Invalid;
	}
}


ExpressionKind check_call_expr(Checker *c, Operand *operand, AstNode *call) {
	GB_ASSERT(call->kind == AstNode_CallExpr);
	ast_node(ce, CallExpr, call);
	check_expr_or_type(c, operand, ce->proc);

	if (operand->mode == Addressing_Invalid) {
		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next)
			check_expr_base(c, operand, arg);
		operand->mode = Addressing_Invalid;
		operand->expr = call;
		return Expression_Statement;
	}


	if (operand->mode == Addressing_Builtin) {
		i32 id = operand->builtin_id;
		if (!check_builtin_procedure(c, operand, call, id))
			operand->mode = Addressing_Invalid;
		operand->expr = call;
		return builtin_procs[id].kind;
	}

	Type *proc_type = get_base_type(operand->type);
	if (proc_type == NULL || proc_type->kind != Type_Proc) {
		AstNode *e = operand->expr;
		gbString str = expr_to_string(e);
		defer (gb_string_free(str));
		error(&c->error_collector, ast_node_token(e), "Cannot call a non-procedure: `%s`", str);

		operand->mode = Addressing_Invalid;
		operand->expr = call;

		return Expression_Statement;
	}

	check_call_arguments(c, operand, proc_type, call);

	auto *proc = &proc_type->proc;
	if (proc->result_count == 0) {
		operand->mode = Addressing_NoValue;
	} else if (proc->result_count == 1) {
		operand->mode = Addressing_Value;
		operand->type = proc->results->tuple.variables[0]->type;
	} else {
		operand->mode = Addressing_Value;
		operand->type = proc->results;
	}

	operand->expr = call;
	return Expression_Statement;
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
		defer (gb_string_free(str));
		error(&c->error_collector, ast_node_token(e), "`%s` %s", str, err_str);
		o->mode = Addressing_Invalid;
	}
}

ExpressionKind check__expr_base(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExpressionKind kind = Expression_Statement;

	o->mode = Addressing_Invalid;
	o->type = t_invalid;

	switch (node->kind) {
	case_ast_node(be, BadExpr, node)
		goto error;
	case_end;

	case_ast_node(i, Ident, node);
		check_identifier(c, o, node, type_hint);
	case_end;

	case_ast_node(bl, BasicLit, node);
		Type *t = t_invalid;
		switch (bl->kind) {
		case Token_Integer: t = t_untyped_integer; break;
		case Token_Float:   t = t_untyped_float;   break;
		case Token_String:  t = t_untyped_string;  break;
		case Token_Rune:    t = t_untyped_rune;    break;
		default:            GB_PANIC("Unknown literal"); break;
		}
		o->mode  = Addressing_Constant;
		o->type  = t;
		o->value = make_exact_value_from_basic_literal(*bl);
	case_end;

	case_ast_node(pl, ProcLit, node);
		auto curr_context = c->context;
		c->context.scope = c->global_scope;
		check_open_scope(c, pl->type);
		c->context.decl = make_declaration_info(c->allocator, c->context.scope);
		defer ({
			check_close_scope(c);
			c->context = curr_context;
		});
		Type *proc_type = check_type(c, pl->type);
		if (proc_type != NULL) {
			check_proc_body(c, empty_token, c->context.decl, proc_type, pl->body);
			o->mode = Addressing_Value;
			o->type = proc_type;
		} else {
			gbString str = expr_to_string(node);
			error(&c->error_collector, ast_node_token(node), "Invalid procedure literal `%s`", str);
			gb_string_free(str);
			goto error;
		}
	case_end;

	case_ast_node(cl, CompoundLit, node);
		Type *type = type_hint;
		b32 ellipsis_array = false;
		if (cl->type != NULL) {
			type = NULL;

			// [..]Type
			if (cl->type->kind == AstNode_ArrayType && cl->type->ArrayType.count != NULL) {
				if (cl->type->ArrayType.count->kind == AstNode_Ellipsis) {
					type = make_type_array(c->allocator, check_type(c, cl->type->ArrayType.elem), -1);
					ellipsis_array = true;
				}
			}

			if (type == NULL) {
				type = check_type(c, cl->type);
			}
		}

		if (type == NULL) {
			error(&c->error_collector, ast_node_token(node), "Missing type in compound literal");
			goto error;
		}

		Type *t = get_base_type(type);
		switch (t->kind) {
		case Type_Structure: {
			if (cl->elem_count == 0)
				break; // NOTE(bill): No need to init
			{ // Checker values
				AstNode *elem = cl->elem_list;
				isize field_count = t->structure.field_count;
				isize index = 0;
				for (;
				     elem != NULL;
				     elem = elem->next, index++) {
					Entity *field = t->structure.fields[index];

					check_expr(c, o, elem);
					if (index >= field_count) {
						error(&c->error_collector, ast_node_token(o->expr), "Too many values in structure literal, expected %td", field_count);
						break;
					}
					check_assignment(c, o, field->type, make_string("structure literal"));
				}
				if (cl->elem_count < field_count) {
					error(&c->error_collector, cl->close, "Too few values in structure literal, expected %td, got %td", field_count, cl->elem_count);
				}
			}

		} break;

		case Type_Slice:
		case Type_Array:
		case Type_Vector:
		{
			Type *elem_type = NULL;
			String context_name = {};
			if (t->kind == Type_Slice) {
				elem_type = t->slice.elem;
				context_name = make_string("slice literal");
			} else if (t->kind == Type_Vector) {
				elem_type = t->vector.elem;
				context_name = make_string("vector literal");
			} else {
				elem_type = t->array.elem;
				context_name = make_string("array literal");
			}


			i64 index = 0;
			i64 max = 0;
			for (AstNode *elem = cl->elem_list; elem != NULL; elem = elem->next, index++) {
				AstNode *e = elem;
				if (t->kind == Type_Array &&
				    t->array.count >= 0 &&
				    index >= t->array.count) {
					error(&c->error_collector, ast_node_token(elem), "Index %lld is out of bounds (>= %lld)", index, t->array.count);
				}

				Operand o = {};
				check_expr_with_type_hint(c, &o, e, elem_type);
				check_assignment(c, &o, elem_type, context_name);
			}
			if (max < index)
				max = index;

			if (t->kind == Type_Array && ellipsis_array) {
				t->array.count = max;
			}
		} break;

		default: {
			gbString str = type_to_string(t);
			error(&c->error_collector, ast_node_token(node), "Invalid compound literal type `%s`", str);
			gb_string_free(str);
			goto error;
		} break;
		}

		o->mode = Addressing_Value;
		o->type = type;
	case_end;

	case_ast_node(pe, ParenExpr, node);
		kind = check_expr_base(c, o, pe->expr, type_hint);
		o->expr = node;
	case_end;


	case_ast_node(te, TagExpr, node);
		// TODO(bill): Tag expressions
		error(&c->error_collector, ast_node_token(node), "Tag expressions are not supported yet");
		kind = check_expr_base(c, o, te->expr, type_hint);
		o->expr = node;
	case_end;


	case_ast_node(ue, UnaryExpr, node);
		check_expr(c, o, ue->expr);
		if (o->mode == Addressing_Invalid)
			goto error;
		check_unary_expr(c, o, ue->op, node);
		if (o->mode == Addressing_Invalid)
			goto error;
	case_end;


	case_ast_node(be, BinaryExpr, node);
		check_binary_expr(c, o, node);
		if (o->mode == Addressing_Invalid)
			goto error;
	case_end;



	case_ast_node(se, SelectorExpr, node);
		check_expr_base(c, o, se->expr);
		check_selector(c, o, node);
	case_end;


	case_ast_node(ie, IndexExpr, node);
		check_expr(c, o, ie->expr);
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
				if (o->mode != Addressing_Variable)
					o->mode = Addressing_Value;
				o->type = t_u8;
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->array.count;
			if (o->mode != Addressing_Variable)
				o->mode = Addressing_Value;
			o->type = t->array.elem;
			break;

		case Type_Vector:
			valid = true;
			max_count = t->vector.count;
			if (o->mode != Addressing_Variable)
				o->mode = Addressing_Value;
			o->type = t->vector.elem;
			break;


		case Type_Slice:
			valid = true;
			o->type = t->slice.elem;
			o->mode = Addressing_Variable;
			break;

		case Type_Pointer:
			valid = true;
			o->mode = Addressing_Variable;
			o->type = get_base_type(t->pointer.elem);
			break;
		}

		if (!valid) {
			gbString str = expr_to_string(o->expr);
			error(&c->error_collector, ast_node_token(o->expr), "Cannot index `%s`", str);
			gb_string_free(str);
			goto error;
		}

		if (ie->index == NULL) {
			gbString str = expr_to_string(o->expr);
			error(&c->error_collector, ast_node_token(o->expr), "Missing index for `%s`", str);
			gb_string_free(str);
			goto error;
		}

		check_index_value(c, ie->index, max_count, NULL);
	case_end;



	case_ast_node(se, SliceExpr, node);
		check_expr(c, o, se->expr);
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
				o->type = t_string;
				o->mode = Addressing_Value;
			}
			break;

		case Type_Array:
			valid = true;
			max_count = t->array.count;
			if (o->mode != Addressing_Variable) {
				gbString str = expr_to_string(node);
				error(&c->error_collector, ast_node_token(node), "Cannot slice array `%s`, value is not addressable", str);
				gb_string_free(str);
				goto error;
			}
			o->type = make_type_slice(c->allocator, t->array.elem);
			o->mode = Addressing_Value;
			break;

		case Type_Slice:
			valid = true;
			o->mode = Addressing_Value;
			break;

		case Type_Pointer:
			valid = true;
			o->type = make_type_slice(c->allocator, get_base_type(t->pointer.elem));
			o->mode = Addressing_Value;
			break;
		}

		if (!valid) {
			gbString str = expr_to_string(o->expr);
			error(&c->error_collector, ast_node_token(o->expr), "Cannot slice `%s`", str);
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
					error(&c->error_collector, se->close, "Invalid slice indices: [%td > %td]", a, b);
				}
			}
		}

	case_end;


	case_ast_node(ce, CallExpr, node);
		return check_call_expr(c, o, node);
	case_end;

	case_ast_node(de, DerefExpr, node);
		check_expr_or_type(c, o, de->expr);
		if (o->mode == Addressing_Invalid) {
			goto error;
		} else {
			Type *t = get_base_type(o->type);
			if (t->kind == Type_Pointer) {
				o->mode = Addressing_Variable;
				o->type = t->pointer.elem;
 			} else {
 				gbString str = expr_to_string(o->expr);
 				error(&c->error_collector, ast_node_token(o->expr), "Cannot dereference `%s`", str);
 				gb_string_free(str);
 				goto error;
 			}
		}
	case_end;

	case AstNode_ProcType:
	case AstNode_PointerType:
	case AstNode_ArrayType:
	case AstNode_VectorType:
	case AstNode_StructType:
		o->mode = Addressing_Type;
		o->type = check_type(c, node);
		break;
	}

	kind = Expression_Expression;
	o->expr = node;
	return kind;

error:
	o->mode = Addressing_Invalid;
	o->expr = node;
	return kind;
}

ExpressionKind check_expr_base(Checker *c, Operand *o, AstNode *node, Type *type_hint) {
	ExpressionKind kind = check__expr_base(c, o, node, type_hint);
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
	gbString err_str = NULL;
	defer (gb_string_free(err_str));

	check_expr_base(c, o, e);
	switch (o->mode) {
	default:
		return; // NOTE(bill): Valid

	case Addressing_NoValue:
		err_str = expr_to_string(e);
		error(&c->error_collector, ast_node_token(e), "`%s` used as value", err_str);
		break;
	case Addressing_Type:
		err_str = expr_to_string(e);
		error(&c->error_collector, ast_node_token(e), "`%s` is not an expression", err_str);
		break;
	}
	o->mode = Addressing_Invalid;
}

void check_not_tuple(Checker *c, Operand *o) {
	if (o->mode == Addressing_Value) {
		// NOTE(bill): Tuples are not first class thus never named
		if (o->type->kind == Type_Tuple) {
			isize count = o->type->tuple.variable_count;
			GB_ASSERT(count != 1);
			error(&c->error_collector, ast_node_token(o->expr),
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
	check_expr_base(c, o, e);
	check_not_tuple(c, o);
	if (o->mode == Addressing_NoValue) {
		AstNode *e = o->expr;
		gbString str = expr_to_string(e);
		defer (gb_string_free(str));
		error(&c->error_collector, ast_node_token(e),
		      "`%s` used as value or type", str);
		o->mode = Addressing_Invalid;
	}
}


gbString write_expr_to_string(gbString str, AstNode *node);

gbString write_field_list_to_string(gbString str, AstNode *field_list, char *sep) {
	isize i = 0;
	for (AstNode *field = field_list; field != NULL; field = field->next) {
		ast_node(f, Field, field);
		if (i > 0)
			str = gb_string_appendc(str, sep);

		isize j = 0;
		for (AstNode *name = f->name_list; name != NULL; name = name->next) {
			if (j > 0)
				str = gb_string_appendc(str, ", ");
			str = write_expr_to_string(str, name);
			j++;
		}

		str = gb_string_appendc(str, ": ");
		str = write_expr_to_string(str, f->type);

		i++;
	}
	return str;
}

gbString string_append_token(gbString str, Token token) {
	if (token.string.len > 0)
		return gb_string_append_length(str, token.string.text, token.string.len);
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
		str = string_append_token(str, i->token);
	case_end;

	case_ast_node(bl, BasicLit, node);
		str = string_append_token(str, *bl);
	case_end;

	case_ast_node(pl, ProcLit, node);
		str = write_expr_to_string(str, pl->type);
	case_end;

	case_ast_node(cl, CompoundLit, node);
		str = gb_string_appendc(str, "(");
		str = write_expr_to_string(str, cl->type);
		str = gb_string_appendc(str, " lit)");
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
		str = gb_string_appendc(str, ":");
		str = write_expr_to_string(str, se->high);
		if (se->triple_indexed) {
			str = gb_string_appendc(str, ":");
			str = write_expr_to_string(str, se->max);
		}
		str = gb_string_appendc(str, "]");
	case_end;

	case_ast_node(e, Ellipsis, node);
		str = gb_string_appendc(str, "..");
	case_end;

	case_ast_node(pt, PointerType, node);
		str = gb_string_appendc(str, "^");
		str = write_expr_to_string(str, pt->type);
	case_end;

	case_ast_node(at, ArrayType, node);
		str = gb_string_appendc(str, "[");
		str = write_expr_to_string(str, at->count);
		str = gb_string_appendc(str, "]");
		str = write_expr_to_string(str, at->elem);
	case_end;

	case_ast_node(vt, VectorType, node);
		str = gb_string_appendc(str, "{");
		str = write_expr_to_string(str, vt->count);
		str = gb_string_appendc(str, "}");
		str = write_expr_to_string(str, vt->elem);
	case_end;

	case_ast_node(ce, CallExpr, node);
		str = write_expr_to_string(str, ce->proc);
		str = gb_string_appendc(str, "(");
		isize i = 0;
		for (AstNode *arg = ce->arg_list; arg != NULL; arg = arg->next) {
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = write_expr_to_string(str, arg);
			i++;
		}
		str = gb_string_appendc(str, ")");
	case_end;

	case_ast_node(pt, ProcType, node);
		str = gb_string_appendc(str, "proc(");
		str = write_field_list_to_string(str, pt->param_list, ", ");
		str = gb_string_appendc(str, ")");
	case_end;

	case_ast_node(st, StructType, node);
		str = gb_string_appendc(str, "struct{");
		str = write_field_list_to_string(str, st->field_list, ", ");
		str = gb_string_appendc(str, "}");
	case_end;

	}

	return str;
}

gbString expr_to_string(AstNode *expression) {
	return write_expr_to_string(gb_string_make(gb_heap_allocator(), ""), expression);
}
