typedef bool (BuiltinTypeIsProc)(Type *t);

gb_global BuiltinTypeIsProc *builtin_type_is_procs[BuiltinProc__type_simple_boolean_end - BuiltinProc__type_simple_boolean_begin] = {
	nullptr, // BuiltinProc__type_simple_boolean_begin

	is_type_boolean,
	is_type_integer,
	is_type_rune,
	is_type_float,
	is_type_complex,
	is_type_quaternion,
	is_type_string,
	is_type_typeid,
	is_type_any,
	is_type_endian_platform,
	is_type_endian_little,
	is_type_endian_big,
	is_type_unsigned,
	is_type_numeric,
	is_type_ordered,
	is_type_ordered_numeric,
	is_type_indexable,
	is_type_sliceable,
	is_type_comparable,
	is_type_simple_compare,
	is_type_dereferenceable,
	is_type_valid_for_keys,
	is_type_valid_for_matrix_elems,

	is_type_named,
	is_type_pointer,
	is_type_multi_pointer,
	is_type_array,
	is_type_enumerated_array,
	is_type_slice,
	is_type_dynamic_array,

	is_type_map,
	is_type_struct,
	is_type_union,
	is_type_enum,
	is_type_proc,
	is_type_bit_set,
	is_type_simd_vector,
	is_type_matrix,

	is_type_polymorphic_record_specialized,
	is_type_polymorphic_record_unspecialized,

	type_has_nil,
};


gb_internal void check_or_else_right_type(CheckerContext *c, Ast *expr, String const &name, Type *right_type) {
	if (right_type == nullptr) {
		return;
	}
	if (!is_type_boolean(right_type) && !type_has_nil(right_type)) {
		gbString str = type_to_string(right_type);
		error(expr, "'%.*s' expects an \"optional ok\" like value, or an n-valued expression where the last value is either a boolean or can be compared against 'nil', got %s", LIT(name), str);
		gb_string_free(str);
	}
}

gb_internal void check_or_else_split_types(CheckerContext *c, Operand *x, String const &name, Type **left_type_, Type **right_type_) {
	Type *left_type = nullptr;
	Type *right_type = nullptr;
	if (x->type->kind == Type_Tuple) {
		auto const &vars = x->type->Tuple.variables;
		auto lhs = slice(vars, 0, vars.count-1);
		auto rhs = vars[vars.count-1];
		if (lhs.count == 1) {
			left_type = lhs[0]->type;
		} else if (lhs.count != 0) {
			left_type = alloc_type_tuple();
			left_type->Tuple.variables = lhs;
		}

		right_type = rhs->type;
	} else {
		check_promote_optional_ok(c, x, &left_type, &right_type);
	}

	if (left_type_)  *left_type_  = left_type;
	if (right_type_) *right_type_ = right_type;

	check_or_else_right_type(c, x->expr, name, right_type);
}


gb_internal void check_or_else_expr_no_value_error(CheckerContext *c, String const &name, Operand const &x, Type *type_hint) {
	ERROR_BLOCK();
	gbString t = type_to_string(x.type);
	error(x.expr, "'%.*s' does not return a value, value is of type %s", LIT(name), t);
	if (is_type_union(type_deref(x.type))) {
		Type *bsrc = base_type(type_deref(x.type));
		gbString th = nullptr;
		if (type_hint != nullptr) {
			GB_ASSERT(bsrc->kind == Type_Union);
			for (Type *vt : bsrc->Union.variants) {
				if (are_types_identical(vt, type_hint)) {
					th = type_to_string(type_hint);
					break;
				}
			}
		}
		gbString expr_str = expr_to_string(x.expr);
		if (th != nullptr) {
			error_line("\tSuggestion: was a type assertion such as %s.(%s) or %s.? wanted?\n", expr_str, th, expr_str);
		} else {
			error_line("\tSuggestion: was a type assertion such as %s.(T) or %s.? wanted?\n", expr_str, expr_str);
		}
		gb_string_free(th);
		gb_string_free(expr_str);
	}
	gb_string_free(t);
}


gb_internal void check_or_return_split_types(CheckerContext *c, Operand *x, String const &name, Type **left_type_, Type **right_type_) {
	Type *left_type = nullptr;
	Type *right_type = nullptr;
	if (x->type->kind == Type_Tuple) {
		auto const &vars = x->type->Tuple.variables;
		auto lhs = slice(vars, 0, vars.count-1);
		auto rhs = vars[vars.count-1];
		if (lhs.count == 1) {
			left_type = lhs[0]->type;
		} else if (lhs.count != 0) {
			left_type = alloc_type_tuple();
			left_type->Tuple.variables = lhs;
		}

		right_type = rhs->type;
	} else {
		check_promote_optional_ok(c, x, &left_type, &right_type);
	}

	if (left_type_)  *left_type_  = left_type;
	if (right_type_) *right_type_ = right_type;

	check_or_else_right_type(c, x->expr, name, right_type);
}


gb_internal bool does_require_msgSend_stret(Type *return_type) {
	if (return_type == nullptr) {
		return false;
	}
	if (build_context.metrics.arch == TargetArch_i386 || build_context.metrics.arch == TargetArch_amd64) {
		i64 struct_limit = type_size_of(t_uintptr) << 1;
		return type_size_of(return_type) > struct_limit;
	}
	if (build_context.metrics.arch == TargetArch_arm64) {
		return false;
	}

	// if (build_context.metrics.arch == TargetArch_arm32) {
	// 	i64 struct_limit = type_size_of(t_uintptr);
	// 	// NOTE(bill): This is technically wrong
	// 	return is_type_struct(return_type) && !is_type_raw_union(return_type) && type_size_of(return_type) > struct_limit;
	// }
	GB_PANIC("unsupported architecture");
	return false;
}

gb_internal ObjcMsgKind get_objc_proc_kind(Type *return_type) {
	if (return_type == nullptr) {
		return ObjcMsg_normal;
	}

	if (build_context.metrics.arch == TargetArch_i386 || build_context.metrics.arch == TargetArch_amd64) {
		if (is_type_float(return_type)) {
			return ObjcMsg_fpret;
		}
		if (build_context.metrics.arch == TargetArch_amd64) {
			if (is_type_complex(return_type)) {
				// URL: https://github.com/opensource-apple/objc4/blob/cd5e62a5597ea7a31dccef089317abb3a661c154/runtime/message.h#L143-L159
				return ObjcMsg_fpret;
			}
		}
	}
	if (build_context.metrics.arch != TargetArch_arm64) {
		if (does_require_msgSend_stret(return_type)) {
			return ObjcMsg_stret;
		}
	}
	return ObjcMsg_normal;
}

gb_internal void add_objc_proc_type(CheckerContext *c, Ast *call, Type *return_type, Slice<Type *> param_types) {
	ObjcMsgKind kind = get_objc_proc_kind(return_type);

	Scope *scope = create_scope(c->info, nullptr);

	// NOTE(bill, 2022-02-08): the backend's ABI handling should handle this correctly, I hope
	Type *params = alloc_type_tuple();
	{
		auto variables = array_make<Entity *>(permanent_allocator(), 0, param_types.count);

		for (Type *type : param_types) {
			Entity *param = alloc_entity_param(scope, blank_token, type, false, true);
			array_add(&variables, param);
		}
		params->Tuple.variables = slice_from_array(variables);
	}

	Type *results = alloc_type_tuple();
	if (return_type) {
		auto variables = array_make<Entity *>(permanent_allocator(), 1);
		results->Tuple.variables = slice_from_array(variables);
		Entity *param = alloc_entity_param(scope, blank_token, return_type, false, true);
		results->Tuple.variables[0] = param;
	}


	ObjcMsgData data = {};
	data.kind = kind;
	data.proc_type = alloc_type_proc(scope, params, param_types.count, results, results->Tuple.variables.count, false, ProcCC_CDecl);

	mutex_lock(&c->info->objc_types_mutex);
	map_set(&c->info->objc_msgSend_types, call, data);
	mutex_unlock(&c->info->objc_types_mutex);

	try_to_add_package_dependency(c, "runtime", "objc_msgSend");
	try_to_add_package_dependency(c, "runtime", "objc_msgSend_fpret");
	try_to_add_package_dependency(c, "runtime", "objc_msgSend_fp2ret");
	try_to_add_package_dependency(c, "runtime", "objc_msgSend_stret");
}

gb_internal bool is_constant_string(CheckerContext *c, String const &builtin_name, Ast *expr, String *name_) {
	Operand op = {};
	check_expr(c, &op, expr);
	if (op.mode == Addressing_Constant && op.value.kind == ExactValue_String) {
		if (name_) *name_ = op.value.value_string;
		return true;
	}
	gbString e = expr_to_string(op.expr);
	gbString t = type_to_string(op.type);
	error(op.expr, "'%.*s' expected a constant string value, got %s of type %s", LIT(builtin_name), e, t);
	gb_string_free(t);
	gb_string_free(e);
	return false;
}

gb_internal bool check_builtin_objc_procedure(CheckerContext *c, Operand *operand, Ast *call, i32 id, Type *type_hint) {
	String const &builtin_name = builtin_procs[id].name;

	if (build_context.metrics.os != TargetOs_darwin) {
		// allow on doc generation (e.g. Metal stuff)
		if (build_context.command_kind != Command_doc && build_context.command_kind != Command_check) {
			error(call, "'%.*s' only works on darwin", LIT(builtin_name));
		}
	}


	ast_node(ce, CallExpr, call);
	switch (id) {
	default:
		GB_PANIC("Implement objective built-in procedure: %.*s", LIT(builtin_name));
		return false;

	case BuiltinProc_objc_send: {
		Type *return_type = nullptr;

		Operand rt = {};
		check_expr_or_type(c, &rt, ce->args[0]);
		if (rt.mode == Addressing_Type) {
			return_type = rt.type;
		} else if (is_operand_nil(rt)) {
			return_type = nullptr;
		} else {
			gbString e = expr_to_string(rt.expr);
			error(rt.expr, "'%.*s' expected a type or nil to define the return type of the Objective-C call, got %s", LIT(builtin_name), e);
			gb_string_free(e);
			return false;
		}

		operand->type = return_type;
		operand->mode = return_type ? Addressing_Value : Addressing_NoValue;

		String class_name = {};
		String sel_name = {};

		Type *sel_type = t_objc_SEL;
		Operand self = {};
		check_expr_or_type(c, &self, ce->args[1]);
		if (self.mode == Addressing_Type) {
			if (!is_type_objc_object(self.type)) {
				gbString t = type_to_string(self.type);
				error(self.expr, "'%.*s' expected a type or value derived from intrinsics.objc_object, got type %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
			if (!has_type_got_objc_class_attribute(self.type)) {
				gbString t = type_to_string(self.type);
				error(self.expr, "'%.*s' expected a named type with the attribute @(obj_class=<string>) , got type %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}

			sel_type = t_objc_Class;
		} else if (!is_operand_value(self) || !check_is_assignable_to(c, &self, t_objc_id)) {
			gbString e = expr_to_string(self.expr);
			gbString t = type_to_string(self.type);
			error(self.expr, "'%.*s' expected a type or value derived from intrinsics.objc_object, got '%s' of type %s", LIT(builtin_name), e, t);
			gb_string_free(t);
			gb_string_free(e);
			return false;
		} else if (!is_type_pointer(self.type)) {
			gbString e = expr_to_string(self.expr);
			gbString t = type_to_string(self.type);
			error(self.expr, "'%.*s' expected a pointer of a value derived from intrinsics.objc_object, got '%s' of type %s", LIT(builtin_name), e, t);
			gb_string_free(t);
			gb_string_free(e);
			return false;
		} else {
			Type *type = type_deref(self.type);
			if (!(type->kind == Type_Named &&
			      type->Named.type_name != nullptr &&
			      type->Named.type_name->TypeName.objc_class_name != "")) {
				gbString t = type_to_string(type);
				error(self.expr, "'%.*s' expected a named type with the attribute @(obj_class=<string>) , got type %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
		}


		if (!is_constant_string(c, builtin_name, ce->args[2], &sel_name)) {
			return false;
		}

		isize const arg_offset = 1;
		auto param_types = slice_make<Type *>(permanent_allocator(), ce->args.count-arg_offset);
		param_types[0] = t_objc_id;
		param_types[1] = sel_type;

		for (isize i = 2+arg_offset; i < ce->args.count; i++) {
			Operand x = {};
			check_expr(c, &x, ce->args[i]);
			if (is_type_untyped(x.type)) {
				gbString e = expr_to_string(x.expr);
				gbString t = type_to_string(x.type);
				error(x.expr, "'%.*s' expects typed parameters, got %s of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
			}
			param_types[i-arg_offset] = x.type;
		}

		add_objc_proc_type(c, call, return_type, param_types);

		return true;
	} break;

	case BuiltinProc_objc_find_selector: 
	case BuiltinProc_objc_find_class: 
	case BuiltinProc_objc_register_selector: 
	case BuiltinProc_objc_register_class: 
	{
		String sel_name = {};
		if (!is_constant_string(c, builtin_name, ce->args[0], &sel_name)) {
			return false;
		}

		switch (id) {
		case BuiltinProc_objc_find_selector: 
		case BuiltinProc_objc_register_selector: 
			operand->type = t_objc_SEL;
			break;
		case BuiltinProc_objc_find_class: 
		case BuiltinProc_objc_register_class: 
			operand->type = t_objc_Class;
			break;

		}
		operand->mode = Addressing_Value;

		try_to_add_package_dependency(c, "runtime", "objc_lookUpClass");
		try_to_add_package_dependency(c, "runtime", "sel_registerName");
		try_to_add_package_dependency(c, "runtime", "objc_allocateClassPair");
		return true;
	} break;
	}
}

gb_internal bool check_atomic_memory_order_argument(CheckerContext *c, Ast *expr, String const &builtin_name, OdinAtomicMemoryOrder *memory_order_, char const *extra_message = nullptr) {
	Operand x = {};
	check_expr_with_type_hint(c, &x, expr, t_atomic_memory_order);
	if (x.mode == Addressing_Invalid) {
		return false;
	}
	if (!are_types_identical(x.type, t_atomic_memory_order) || x.mode != Addressing_Constant)  {
		gbString str = type_to_string(x.type);
		if (extra_message) {
			error(x.expr, "Expected a constant Atomic_Memory_Order value for the %s of '%.*s', got %s", extra_message, LIT(builtin_name), str);
		} else {
			error(x.expr, "Expected a constant Atomic_Memory_Order value for '%.*s', got %s", LIT(builtin_name), str);
		}
		gb_string_free(str);
		return false;
	}
	i64 value = exact_value_to_i64(x.value);
	if (value < 0 || value >= OdinAtomicMemoryOrder_COUNT) {
		error(x.expr, "Illegal Atomic_Memory_Order value, got %lld", cast(long long)value);
		return false;
	}
	if (memory_order_) {
		*memory_order_ = cast(OdinAtomicMemoryOrder)value;
	}

	return true;

}


gb_internal bool check_builtin_simd_operation(CheckerContext *c, Operand *operand, Ast *call, i32 id, Type *type_hint) {
	ast_node(ce, CallExpr, call);

	String const &builtin_name = builtin_procs[id].name;
	switch (id) {
	// Any numeric
	case BuiltinProc_simd_add:
	case BuiltinProc_simd_sub:
	case BuiltinProc_simd_mul:
	case BuiltinProc_simd_div:
	case BuiltinProc_simd_min:
	case BuiltinProc_simd_max:
		{
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]);                        if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[1], x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type);                       if (y.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(y.type)) {
				error(y.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xs = type_to_string(x.type);
				gbString ys = type_to_string(y.type);
				error(x.expr, "'%.*s' expected 2 arguments of the same type, got '%s' vs '%s'", LIT(builtin_name), xs, ys);
				gb_string_free(ys);
				gb_string_free(xs);
				return false;
			}
			Type *elem = base_array_type(x.type);
			if (!is_type_integer(elem) && !is_type_float(elem)) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a #simd type with an integer or floating point element, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				return false;
			}

			if (id == BuiltinProc_simd_div && is_type_integer(elem)) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' is not supported for integer elements, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				// don't return
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	// Integer only
	case BuiltinProc_simd_add_sat:
	case BuiltinProc_simd_sub_sat:
	case BuiltinProc_simd_bit_and:
	case BuiltinProc_simd_bit_or:
	case BuiltinProc_simd_bit_xor:
	case BuiltinProc_simd_bit_and_not:
		{
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[1], x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(y.type)) {
				error(y.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xs = type_to_string(x.type);
				gbString ys = type_to_string(y.type);
				error(x.expr, "'%.*s' expected 2 arguments of the same type, got '%s' vs '%s'", LIT(builtin_name), xs, ys);
				gb_string_free(ys);
				gb_string_free(xs);
				return false;
			}
			Type *elem = base_array_type(x.type);

			switch (id) {
			case BuiltinProc_simd_add_sat:
			case BuiltinProc_simd_sub_sat:
				if (!is_type_integer(elem)) {
					gbString xs = type_to_string(x.type);
					error(x.expr, "'%.*s' expected a #simd type with an integer element, got '%s'", LIT(builtin_name), xs);
					gb_string_free(xs);
					return false;
				}
				break;
			default:
				if (!is_type_integer(elem) && !is_type_boolean(elem)) {
					gbString xs = type_to_string(x.type);
					error(x.expr, "'%.*s' expected a #simd type with an integer or boolean element, got '%s'", LIT(builtin_name), xs);
					gb_string_free(xs);
					return false;
				}
				break;
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	case BuiltinProc_simd_shl:        // Odin-like
	case BuiltinProc_simd_shr:        // Odin-like
	case BuiltinProc_simd_shl_masked: // C-like
	case BuiltinProc_simd_shr_masked: // C-like
		{
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[1], x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(y.type)) {
				error(y.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			GB_ASSERT(x.type->kind == Type_SimdVector);
			GB_ASSERT(y.type->kind == Type_SimdVector);
			Type *xt = x.type;
			Type *yt = y.type;

			if (xt->SimdVector.count != yt->SimdVector.count) {
				error(x.expr, "'%.*s' mismatched simd vector lengths, got '%lld' vs '%lld'",
				      LIT(builtin_name),
				      cast(long long)xt->SimdVector.count,
				      cast(long long)yt->SimdVector.count);
				return false;
			}
			if (!is_type_integer(base_array_type(x.type))) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a #simd type with an integer element, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				return false;
			}
			if (!is_type_unsigned(base_array_type(y.type))) {
				gbString ys = type_to_string(y.type);
				error(y.expr, "'%.*s' expected a #simd type with an unsigned integer element as the shifting operand, got '%s'", LIT(builtin_name), ys);
				gb_string_free(ys);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	// Unary
	case BuiltinProc_simd_neg:
	case BuiltinProc_simd_abs:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			if (!is_type_integer(elem) && !is_type_float(elem)) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a #simd type with an integer or floating point element, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				return false;
			}
			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	// Return integer masks
	case BuiltinProc_simd_lanes_eq:
	case BuiltinProc_simd_lanes_ne:
	case BuiltinProc_simd_lanes_lt:
	case BuiltinProc_simd_lanes_le:
	case BuiltinProc_simd_lanes_gt:
	case BuiltinProc_simd_lanes_ge:
		{
			// op(#simd[N]T, #simd[N]T) -> #simd[N]V
			// where `V` is an integer, `size_of(T) == size_of(V)`
			// `V` will all 0s if false and all 1s if true (e.g. 0x00 and 0xff for false and true, respectively)

			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[1], x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			switch (id) {
			case BuiltinProc_simd_lanes_eq:
			case BuiltinProc_simd_lanes_ne:
				if (!is_type_integer(elem) && !is_type_float(elem) && !is_type_boolean(elem)) {
					gbString xs = type_to_string(x.type);
					error(x.expr, "'%.*s' expected a #simd type with an integer, floating point, or boolean element, got '%s'", LIT(builtin_name), xs);
					gb_string_free(xs);
					return false;
				}
				break;
			default:
				if (!is_type_integer(elem) && !is_type_float(elem)) {
					gbString xs = type_to_string(x.type);
					error(x.expr, "'%.*s' expected a #simd type with an integer or floating point element, got '%s'", LIT(builtin_name), xs);
					gb_string_free(xs);
					return false;
				}
				break;
			}


			Type *vt = base_type(x.type);
			GB_ASSERT(vt->kind == Type_SimdVector);
			i64 count = vt->SimdVector.count;

			i64 sz = type_size_of(elem);
			Type *new_elem = nullptr;

			switch (sz) {
			case 1: new_elem = t_u8;  break;
			case 2: new_elem = t_u16; break;
			case 4: new_elem = t_u32; break;
			case 8: new_elem = t_u64; break;
			case 16:
				error(x.expr, "'%.*s' not supported 128-bit integer backed simd vector types", LIT(builtin_name));
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = alloc_type_simd_vector(count, new_elem);
			return true;
		}

	case BuiltinProc_simd_extract:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			i64 max_count = x.type->SimdVector.count;
			i64 value = -1;
			if (!check_index_value(c, x.type, false, ce->args[1], max_count, &value)) {
				return false;
			}
			if (max_count < 0) {
				error(ce->args[1], "'%.*s' expected a constant integer index, got '%lld'", LIT(builtin_name), cast(long long)value);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = elem;
			return true;
		}
		break;
	case BuiltinProc_simd_replace:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			i64 max_count = x.type->SimdVector.count;
			i64 value = -1;
			if (!check_index_value(c, x.type, false, ce->args[1], max_count, &value)) {
				return false;
			}
			if (max_count < 0) {
				error(ce->args[1], "'%.*s' expected a constant integer index, got '%lld'", LIT(builtin_name), cast(long long)value);
				return false;
			}

			Operand y = {};
			check_expr_with_type_hint(c, &y, ce->args[2], elem); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, elem); if (y.mode == Addressing_Invalid) return false;
			if (!are_types_identical(y.type, elem)) {
				gbString et = type_to_string(elem);
				gbString yt = type_to_string(y.type);
				error(y.expr, "'%.*s' expected a type of '%s' to insert, got '%s'", LIT(builtin_name), et, yt);
				gb_string_free(yt);
				gb_string_free(et);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}
		break;

	case BuiltinProc_simd_reduce_add_ordered:
	case BuiltinProc_simd_reduce_mul_ordered:
	case BuiltinProc_simd_reduce_min:
	case BuiltinProc_simd_reduce_max:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			if (!is_type_integer(elem) && !is_type_float(elem)) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a #simd type with an integer or floating point element, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = base_array_type(x.type);
			return true;
		}

	case BuiltinProc_simd_reduce_and:
	case BuiltinProc_simd_reduce_or:
	case BuiltinProc_simd_reduce_xor:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			if (!is_type_integer(elem) && !is_type_boolean(elem)) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a #simd type with an integer or boolean element, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = base_array_type(x.type);
			return true;
		}


	case BuiltinProc_simd_shuffle:
		{
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[1], x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(y.type)) {
				error(y.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xs = type_to_string(x.type);
				gbString ys = type_to_string(y.type);
				error(x.expr, "'%.*s' expected 2 arguments of the same type, got '%s' vs '%s'", LIT(builtin_name), xs, ys);
				gb_string_free(ys);
				gb_string_free(xs);
				return false;
			}
			Type *elem = base_array_type(x.type);

			i64 max_count = x.type->SimdVector.count + y.type->SimdVector.count;

			i64 arg_count = 0;
			for_array(i, ce->args) {
				if (i < 2) {
					continue;
				}
				Ast *arg = ce->args[i];
				Operand op = {};
				check_expr(c, &op, arg);
				if (op.mode == Addressing_Invalid) {
					return false;
				}
				Type *arg_type = base_type(op.type);
				if (!is_type_integer(arg_type) || op.mode != Addressing_Constant) {
					error(op.expr, "Indices to '%.*s' must be constant integers", LIT(builtin_name));
					return false;
				}

				if (big_int_is_neg(&op.value.value_integer)) {
					error(op.expr, "Negative '%.*s' index", LIT(builtin_name));
					return false;
				}

				BigInt mc = {};
				big_int_from_i64(&mc, max_count);
				if (big_int_cmp(&mc, &op.value.value_integer) <= 0) {
					error(op.expr, "'%.*s' index exceeds length", LIT(builtin_name));
					return false;
				}

				arg_count++;
			}

			if (arg_count > max_count) {
				error(call, "Too many '%.*s' indices, %td > %td", LIT(builtin_name), arg_count, max_count);
				return false;
			}


			if (!is_power_of_two(arg_count)) {
				error(call, "'%.*s' must have a power of two index arguments, got %lld", LIT(builtin_name), cast(long long)arg_count);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = alloc_type_simd_vector(arg_count, elem);
			return true;
		}

	case BuiltinProc_simd_select:
		{
			Operand cond = {};
			check_expr(c, &cond, ce->args[0]); if (cond.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(cond.type)) {
				error(cond.expr, "'%.*s' expected a simd vector boolean type", LIT(builtin_name));
				return false;
			}
			Type *cond_elem = base_array_type(cond.type);
			if (!is_type_boolean(cond_elem) && !is_type_integer(cond_elem)) {
				gbString cond_str = type_to_string(cond.type);
				error(cond.expr, "'%.*s' expected a simd vector boolean or integer type, got '%s'", LIT(builtin_name), cond_str);
				gb_string_free(cond_str);
				return false;
			}

			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[1]); if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[2], x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(y.type)) {
				error(y.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xs = type_to_string(x.type);
				gbString ys = type_to_string(y.type);
				error(x.expr, "'%.*s' expected 2 results of the same type, got '%s' vs '%s'", LIT(builtin_name), xs, ys);
				gb_string_free(ys);
				gb_string_free(xs);
				return false;
			}

			if (cond.type->SimdVector.count != x.type->SimdVector.count) {
				error(x.expr, "'%.*s' expected condition vector to match the length of the result lengths, got '%lld' vs '%lld'",
				      LIT(builtin_name),
				      cast(long long)cond.type->SimdVector.count,
				      cast(long long)x.type->SimdVector.count);
				return false;
			}


			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	case BuiltinProc_simd_ceil:
	case BuiltinProc_simd_floor:
	case BuiltinProc_simd_trunc:
	case BuiltinProc_simd_nearest:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector boolean type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			if (!is_type_float(elem)) {
				gbString x_str = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a simd vector floating point type, got '%s'", LIT(builtin_name), x_str);
				gb_string_free(x_str);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	case BuiltinProc_simd_lanes_reverse:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			operand->type = x.type;
			operand->mode = Addressing_Value;
			return true;
		}

	case BuiltinProc_simd_lanes_rotate_left:
	case BuiltinProc_simd_lanes_rotate_right:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Operand offset = {};
			check_expr(c, &offset, ce->args[1]); if (offset.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &offset, t_i64);
			if (!is_type_integer(offset.type) || offset.mode != Addressing_Constant) {
				error(offset.expr, "'%.*s' expected a constant integer offset");
				return false;
			}
			check_assignment(c, &offset, t_i64, builtin_name);

			operand->type = x.type;
			operand->mode = Addressing_Value;
			return true;
		}

	case BuiltinProc_simd_clamp:
		{
			Operand x = {};
			Operand y = {};
			Operand z = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &y, ce->args[1], x.type); if (y.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &z, ce->args[2], x.type); if (z.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &z, x.type);
			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(y.type)) {
				error(y.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!is_type_simd_vector(z.type)) {
				error(z.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xs = type_to_string(x.type);
				gbString ys = type_to_string(y.type);
				error(x.expr, "'%.*s' expected 2 arguments of the same type, got '%s' vs '%s'", LIT(builtin_name), xs, ys);
				gb_string_free(ys);
				gb_string_free(xs);
				return false;
			}
			if (!are_types_identical(x.type, z.type)) {
				gbString xs = type_to_string(x.type);
				gbString zs = type_to_string(z.type);
				error(x.expr, "'%.*s' expected 2 arguments of the same type, got '%s' vs '%s'", LIT(builtin_name), xs, zs);
				gb_string_free(zs);
				gb_string_free(xs);
				return false;
			}
			Type *elem = base_array_type(x.type);
			if (!is_type_integer(elem) && !is_type_float(elem)) {
				gbString xs = type_to_string(x.type);
				error(x.expr, "'%.*s' expected a #simd type with an integer or floating point element, got '%s'", LIT(builtin_name), xs);
				gb_string_free(xs);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
			return true;
		}

	case BuiltinProc_simd_to_bits:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;

			if (!is_type_simd_vector(x.type)) {
				error(x.expr, "'%.*s' expected a simd vector type", LIT(builtin_name));
				return false;
			}
			Type *elem = base_array_type(x.type);
			i64 count = get_array_type_count(x.type);
			i64 sz = type_size_of(elem);
			Type *bit_elem = nullptr;
			switch (sz) {
			case 1: bit_elem = t_u8;  break;
			case 2: bit_elem = t_u16; break;
			case 4: bit_elem = t_u32; break;
			case 8: bit_elem = t_u64; break;
			}
			GB_ASSERT(bit_elem != nullptr);

			operand->type = alloc_type_simd_vector(count, bit_elem);
			operand->mode = Addressing_Value;
			return true;
		}

	case BuiltinProc_simd_x86__MM_SHUFFLE:
		{
			Operand x[4] = {};
			for (unsigned i = 0; i < 4; i++) {
				check_expr(c, x+i, ce->args[i]); if (x[i].mode == Addressing_Invalid) return false;
			}

			u32 offsets[4] = {6, 4, 2, 0};
			u32 result = 0;
			for (unsigned i = 0; i < 4; i++) {
				if (!is_type_integer(x[i].type) || x[i].mode != Addressing_Constant) {
					gbString xs = type_to_string(x[i].type);
					error(x[i].expr, "'%.*s' expected a constant integer", LIT(builtin_name), xs);
					gb_string_free(xs);
					return false;
				}
				i64 val = exact_value_to_i64(x[i].value);
				if (val < 0 || val > 3) {
					error(x[i].expr, "'%.*s' expected a constant integer in the range 0..<4, got %lld", LIT(builtin_name), cast(long long)val);
					return false;
				}
				result |= cast(u32)(val) << offsets[i];
			}

			operand->type = t_untyped_integer;
			operand->mode = Addressing_Constant;
			operand->value = exact_value_i64(result);
			return true;
		}
	default:
		GB_PANIC("Unhandled simd intrinsic: %.*s", LIT(builtin_name));
	}

	return false;
}

gb_internal bool cache_load_file_directive(CheckerContext *c, Ast *call, String const &original_string, bool err_on_not_found, LoadFileCache **cache_) {
	ast_node(ce, CallExpr, call);
	ast_node(bd, BasicDirective, ce->proc);
	String builtin_name = bd->name.string;

	String path;
	if (gb_path_is_absolute((char*)original_string.text)) {
		path = original_string;
	} else {
		String base_dir = dir_from_path(get_file_path_string(call->file_id));

		BlockingMutex *ignore_mutex = nullptr;
		bool ok = determine_path_from_string(ignore_mutex, call, base_dir, original_string, &path);
		gb_unused(ok);
	}

	MUTEX_GUARD(&c->info->load_file_mutex);

	gbFileError file_error = gbFileError_None;
	String data = {};

	LoadFileCache **cache_ptr = string_map_get(&c->info->load_file_cache, path);
	LoadFileCache *cache = cache_ptr ? *cache_ptr : nullptr;
	if (cache) {
		file_error = cache->file_error;
		data = cache->data;
	}
	defer ({
		if (cache == nullptr) {
			LoadFileCache *new_cache = gb_alloc_item(permanent_allocator(), LoadFileCache);
			new_cache->path = path;
			new_cache->data = data;
			new_cache->file_error = file_error;
			string_map_init(&new_cache->hashes, 32);
			string_map_set(&c->info->load_file_cache, path, new_cache);
			if (cache_) *cache_ = new_cache;
		} else {
			cache->data = data;
			cache->file_error = file_error;
			if (cache_) *cache_ = cache;
		}
	});

	TEMPORARY_ALLOCATOR_GUARD();
	char *c_str = alloc_cstring(temporary_allocator(), path);

	gbFile f = {};
	if (cache == nullptr) {
		file_error = gb_file_open(&f, c_str);
	}
	defer (gb_file_close(&f));

	switch (file_error) {
	default:
	case gbFileError_Invalid:
		if (err_on_not_found) {
			error(ce->proc, "Failed to `#%.*s` file: %s; invalid file or cannot be found", LIT(builtin_name), c_str);
		}
		call->state_flags |= StateFlag_DirectiveWasFalse;
		return false;
	case gbFileError_NotExists:
		if (err_on_not_found) {
			error(ce->proc, "Failed to `#%.*s` file: %s; file cannot be found", LIT(builtin_name), c_str);
		}
		call->state_flags |= StateFlag_DirectiveWasFalse;
		return false;
	case gbFileError_Permission:
		if (err_on_not_found) {
			error(ce->proc, "Failed to `#%.*s` file: %s; file permissions problem", LIT(builtin_name), c_str);
		}
		call->state_flags |= StateFlag_DirectiveWasFalse;
		return false;
	case gbFileError_None:
		// Okay
		break;
	}

	if (cache == nullptr) {
		isize file_size = cast(isize)gb_file_size(&f);
		if (file_size > 0) {
			u8 *ptr = cast(u8 *)gb_alloc(permanent_allocator(), file_size+1);
			gb_file_read_at(&f, ptr, file_size, 0);
			ptr[file_size] = '\0';
			data.text = ptr;
			data.len = file_size;
		}
	}

	return true;
}


gb_internal bool is_valid_type_for_load(Type *type) {
	if (type == t_invalid) {
		return false;
	} else if (is_type_string(type)) {
		return true;
	} else if (is_type_slice(type) /*|| is_type_array(type) || is_type_enumerated_array(type)*/) {
		Type *elem = nullptr;
		Type *bt = base_type(type);
		if (bt->kind == Type_Slice) {
			elem = bt->Slice.elem;
		} else if (bt->kind == Type_Array) {
			elem = bt->Array.elem;
		} else if (bt->kind == Type_EnumeratedArray) {
			elem = bt->EnumeratedArray.elem;
		}
		GB_ASSERT(elem != nullptr);
		return is_type_load_safe(elem);
	}
	return false;
}

gb_internal bool check_atomic_ptr_argument(Operand *operand, String const &builtin_name, Type *elem) {
	if (!is_type_valid_atomic_type(elem)) {
		error(operand->expr, "Only an integer, floating-point, boolean, or pointer can be used as an atomic for '%.*s'", LIT(builtin_name));
		return false;
	}
	return true;

}

gb_internal LoadDirectiveResult check_load_directive(CheckerContext *c, Operand *operand, Ast *call, Type *type_hint, bool err_on_not_found) {
	ast_node(ce, CallExpr, call);
	ast_node(bd, BasicDirective, ce->proc);
	String name = bd->name.string;
	GB_ASSERT(name == "load");

	if (ce->args.count != 1 && ce->args.count != 2) {
		if (ce->args.count == 0) {
			error(ce->close, "'#%.*s' expects 1 or 2 arguments, got 0", LIT(name));
		} else {
			error(ce->args[0], "'#%.*s' expects 1 or 2 arguments, got %td", LIT(name), ce->args.count);
		}

		return LoadDirective_Error;
	}

	Ast *arg = ce->args[0];
	Operand o = {};
	check_expr(c, &o, arg);
	if (o.mode != Addressing_Constant) {
		error(arg, "'#%.*s' expected a constant string argument", LIT(name));
		return LoadDirective_Error;
	}

	if (!is_type_string(o.type)) {
		gbString str = type_to_string(o.type);
		error(arg, "'#%.*s' expected a constant string, got %s", LIT(name), str);
		gb_string_free(str);
		return LoadDirective_Error;
	}

	GB_ASSERT(o.value.kind == ExactValue_String);

	operand->type = t_u8_slice;
	if (ce->args.count == 1) {
		if (type_hint && is_valid_type_for_load(type_hint)) {
			operand->type = type_hint;
		}
	} else if (ce->args.count == 2) {
		Ast *arg_type = ce->args[1];
		Type *type = check_type(c, arg_type);
		if (type != nullptr) {
			if (is_valid_type_for_load(type)) {
				operand->type = type;
			} else {
				gbString type_str = type_to_string(type);
				error(arg_type, "'#%.*s' invalid type, expected a string, or slice of simple types, got %s", LIT(name), type_str);
				gb_string_free(type_str);
			}
		}
	} else {
		GB_PANIC("unreachable");
	}
	operand->mode = Addressing_Constant;

	LoadFileCache *cache = nullptr;
	if (cache_load_file_directive(c, call, o.value.value_string, err_on_not_found, &cache)) {
		operand->value = exact_value_string(cache->data);
		return LoadDirective_Success;
	}
	return LoadDirective_NotFound;

}

gb_internal int file_cache_sort_cmp(void const *x, void const *y) {
	LoadFileCache const *a = *(LoadFileCache const **)(x);
	LoadFileCache const *b = *(LoadFileCache const **)(y);
	return string_compare(a->path, b->path);
}

gb_internal LoadDirectiveResult check_load_directory_directive(CheckerContext *c, Operand *operand, Ast *call, Type *type_hint, bool err_on_not_found) {
	ast_node(ce, CallExpr, call);
	ast_node(bd, BasicDirective, ce->proc);
	String name = bd->name.string;
	GB_ASSERT(name == "load_directory");

	if (ce->args.count != 1) {
		error(ce->args[0], "'#%.*s' expects 1 argument, got %td", LIT(name), ce->args.count);
		return LoadDirective_Error;
	}

	Ast *arg = ce->args[0];
	Operand o = {};
	check_expr(c, &o, arg);
	if (o.mode != Addressing_Constant) {
		error(arg, "'#%.*s' expected a constant string argument", LIT(name));
		return LoadDirective_Error;
	}

	if (!is_type_string(o.type)) {
		gbString str = type_to_string(o.type);
		error(arg, "'#%.*s' expected a constant string, got %s", LIT(name), str);
		gb_string_free(str);
		return LoadDirective_Error;
	}

	GB_ASSERT(o.value.kind == ExactValue_String);

	init_core_load_directory_file(c->checker);

	operand->type = t_load_directory_file_slice;
	operand->mode = Addressing_Value;


	String original_string = o.value.value_string;
	String path;
	if (gb_path_is_absolute((char*)original_string.text)) {
		path = original_string;
	} else {
		String base_dir = dir_from_path(get_file_path_string(call->file_id));

		BlockingMutex *ignore_mutex = nullptr;
		bool ok = determine_path_from_string(ignore_mutex, call, base_dir, original_string, &path);
		gb_unused(ok);
	}
	MUTEX_GUARD(&c->info->load_directory_mutex);


	gbFileError file_error = gbFileError_None;

	Array<LoadFileCache *> file_caches = {};

	LoadDirectoryCache **cache_ptr = string_map_get(&c->info->load_directory_cache, path);
	LoadDirectoryCache *cache = cache_ptr ? *cache_ptr : nullptr;
	if (cache) {
		file_error = cache->file_error;
	}
	defer ({
		if (cache == nullptr) {
			LoadDirectoryCache *new_cache = gb_alloc_item(permanent_allocator(), LoadDirectoryCache);
			new_cache->path = path;
			new_cache->files = file_caches;
			new_cache->file_error = file_error;
			string_map_set(&c->info->load_directory_cache, path, new_cache);

			map_set(&c->info->load_directory_map, call, new_cache);
		} else {
			cache->file_error = file_error;
		}
	});


	LoadDirectiveResult result = LoadDirective_Success;


	if (cache == nullptr)  {
		Array<FileInfo> list = {};
		ReadDirectoryError rd_err = read_directory(path, &list);
		defer (array_free(&list));

		if (list.count == 1) {
			GB_ASSERT(path != list[0].fullpath);
		}


		switch (rd_err) {
		case ReadDirectory_InvalidPath:
			error(call, "%.*s error - invalid path: %.*s", LIT(name), LIT(original_string));
			return LoadDirective_NotFound;
		case ReadDirectory_NotExists:
			error(call, "%.*s error - path does not exist: %.*s", LIT(name), LIT(original_string));
			return LoadDirective_NotFound;
		case ReadDirectory_Permission:
			error(call, "%.*s error - unknown error whilst reading path, %.*s", LIT(name), LIT(original_string));
			return LoadDirective_Error;
		case ReadDirectory_NotDir:
			error(call, "%.*s error - expected a directory, got a file: %.*s", LIT(name), LIT(original_string));
			return LoadDirective_Error;
		case ReadDirectory_Empty:
			error(call, "%.*s error - empty directory: %.*s", LIT(name), LIT(original_string));
			return LoadDirective_NotFound;
		case ReadDirectory_Unknown:
			error(call, "%.*s error - unknown error whilst reading path %.*s", LIT(name), LIT(original_string));
			return LoadDirective_Error;
		}

		isize files_to_reserve = list.count+1; // always reserve 1

		file_caches = array_make<LoadFileCache *>(heap_allocator(), 0, files_to_reserve);

		for (FileInfo fi : list) {
			LoadFileCache *cache = nullptr;
			if (cache_load_file_directive(c, call, fi.fullpath, err_on_not_found, &cache)) {
				array_add(&file_caches, cache);
			} else {
				result = LoadDirective_Error;
			}
		}

		array_sort(file_caches, file_cache_sort_cmp);

	}

	return result;
}



gb_internal bool check_builtin_procedure_directive(CheckerContext *c, Operand *operand, Ast *call, Type *type_hint) {
	ast_node(ce, CallExpr, call);
	ast_node(bd, BasicDirective, ce->proc);
	String name = bd->name.string;
	if (name == "location") {
		if (ce->args.count > 1) {
			error(ce->args[0], "'#location' expects either 0 or 1 arguments, got %td", ce->args.count);
		}
		if (ce->args.count > 0) {
			Ast *arg = ce->args[0];
			Entity *e = nullptr;
			Operand o = {};
			if (arg->kind == Ast_Ident) {
				e = check_ident(c, &o, arg, nullptr, nullptr, true);
			} else if (arg->kind == Ast_SelectorExpr) {
				e = check_selector(c, &o, arg, nullptr);
			}
			if (e == nullptr) {
				error(ce->args[0], "'#location' expected a valid entity name");
			}
		}

		operand->type = t_source_code_location;
		operand->mode = Addressing_Value;
	} else if (name == "load") {
		return check_load_directive(c, operand, call, type_hint, true) == LoadDirective_Success;
	} else if (name == "load_directory") {
		return check_load_directory_directive(c, operand, call, type_hint, true) == LoadDirective_Success;
	} else if (name == "load_hash") {
		if (ce->args.count != 2) {
			if (ce->args.count == 0) {
				error(ce->close, "'#load_hash' expects 2 argument, got 0");
			} else {
				error(ce->args[0], "'#load_hash' expects 2 argument, got %td", ce->args.count);
			}
			return false;
		}

		Ast *arg0 = ce->args[0];
		Ast *arg1 = ce->args[1];
		Operand o = {};
		check_expr(c, &o, arg0);
		if (o.mode != Addressing_Constant) {
			error(arg0, "'#load_hash' expected a constant string argument");
			return false;
		}

		if (!is_type_string(o.type)) {
			gbString str = type_to_string(o.type);
			error(arg0, "'#load_hash' expected a constant string, got %s", str);
			gb_string_free(str);
			return false;
		}

		Operand o_hash = {};
		check_expr(c, &o_hash, arg1);
		if (o_hash.mode != Addressing_Constant) {
			error(arg1, "'#load_hash' expected a constant string argument");
			return false;
		}

		if (!is_type_string(o_hash.type)) {
			gbString str = type_to_string(o.type);
			error(arg1, "'#load_hash' expected a constant string, got %s", str);
			gb_string_free(str);
			return false;
		}
		gbAllocator a = heap_allocator();

		GB_ASSERT(o.value.kind == ExactValue_String);
		GB_ASSERT(o_hash.value.kind == ExactValue_String);

		String original_string = o.value.value_string;
		String hash_kind = o_hash.value.value_string;

		String supported_hashes[] = {
			str_lit("adler32"),
			str_lit("crc32"),
			str_lit("crc64"),
			str_lit("fnv32"),
			str_lit("fnv64"),
			str_lit("fnv32a"),
			str_lit("fnv64a"),
			str_lit("murmur32"),
			str_lit("murmur64"),
		};

		bool hash_found = false;
		for (isize i = 0; i < gb_count_of(supported_hashes); i++) {
			if (supported_hashes[i] == hash_kind) {
				hash_found = true;
				break;
			}
		}
		if (!hash_found) {
			ERROR_BLOCK();
			error(ce->proc, "Invalid hash kind passed to `#load_hash`, got: %.*s", LIT(hash_kind));
			error_line("\tAvailable hash kinds:\n");
			for (isize i = 0; i < gb_count_of(supported_hashes); i++) {
				error_line("\t%.*s\n", LIT(supported_hashes[i]));
			}
			return false;
		}

		LoadFileCache *cache = nullptr;
		if (cache_load_file_directive(c, call, original_string, true, &cache)) {
			MUTEX_GUARD(&c->info->load_file_mutex);
			// TODO(bill): make these procedures fast :P
			u64 hash_value = 0;
			u64 *hash_value_ptr = string_map_get(&cache->hashes, hash_kind);
			if (hash_value_ptr) {
				hash_value = *hash_value_ptr;
			} else {
				u8 *data = cache->data.text;
				isize file_size = cache->data.len;
				if (hash_kind == "adler32") {
					hash_value = gb_adler32(data, file_size);
				} else if (hash_kind == "crc32") {
					hash_value = gb_crc32(data, file_size);
				} else if (hash_kind == "crc64") {
					hash_value = gb_crc64(data, file_size);
				} else if (hash_kind == "fnv32") {
					hash_value = gb_fnv32(data, file_size);
				} else if (hash_kind == "fnv64") {
					hash_value = gb_fnv64(data, file_size);
				} else if (hash_kind == "fnv32a") {
					hash_value = fnv32a(data, file_size);
				} else if (hash_kind == "fnv64a") {
					hash_value = fnv64a(data, file_size);
				} else if (hash_kind == "murmur32") {
					hash_value = gb_murmur32(data, file_size);
				} else if (hash_kind == "murmur64") {
					hash_value = gb_murmur64(data, file_size);
				} else {
					compiler_error("unhandled hash kind: %.*s", LIT(hash_kind));
				}
				string_map_set(&cache->hashes, hash_kind, hash_value);
			}

			operand->type = t_untyped_integer;
			operand->mode = Addressing_Constant;
			operand->value = exact_value_u64(hash_value);
			return true;
		}
		return false;
	} else if (name == "assert") {
		if (ce->args.count != 1 && ce->args.count != 2) {
			error(call, "'#assert' expects either 1 or 2 arguments, got %td", ce->args.count);
			return false;
		}
		if (!is_type_boolean(operand->type) || operand->mode != Addressing_Constant) {
			gbString str = expr_to_string(ce->args[0]);
			error(call, "'%s' is not a constant boolean", str);
			gb_string_free(str);
			return false;
		}
		if (ce->args.count == 2) {
			Ast *arg = unparen_expr(ce->args[1]);
			if (arg == nullptr || arg->kind != Ast_BasicLit || arg->BasicLit.token.kind != Token_String) {
				gbString str = expr_to_string(arg);
				error(call, "'%s' is not a constant string", str);
				gb_string_free(str);
				return false;
			}
		}

		if (!operand->value.value_bool) {
			ERROR_BLOCK();
			gbString arg1 = expr_to_string(ce->args[0]);
			gbString arg2 = {};

			if (ce->args.count == 1) {
				error(call, "Compile time assertion: %s", arg1);
			} else {
				arg2 = expr_to_string(ce->args[1]);
				error(call, "Compile time assertion: %s (%s)", arg1, arg2);
			}

			if (c->proc_name != "") {
				gbString str = type_to_string(c->curr_proc_sig);
				error_line("\tCalled within '%.*s' :: %s\n", LIT(c->proc_name), str);
				gb_string_free(str);
			}

			gb_string_free(arg1);
			if (ce->args.count == 2) {
				gb_string_free(arg2);
			}
		}

		operand->type = t_untyped_bool;
		operand->mode = Addressing_Constant;
	} else if (name == "panic") {
		ERROR_BLOCK();
		if (ce->args.count != 1) {
			error(call, "'#panic' expects 1 argument, got %td", ce->args.count);
			return false;
		}
		if (!is_type_string(operand->type) && operand->mode != Addressing_Constant) {
			gbString str = expr_to_string(ce->args[0]);
			error(call, "'%s' is not a constant string", str);
			gb_string_free(str);
			return false;
		}
		error(call, "Compile time panic: %.*s", LIT(operand->value.value_string));
		if (c->proc_name != "") {
			gbString str = type_to_string(c->curr_proc_sig);
			error_line("\tCalled within '%.*s' :: %s\n", LIT(c->proc_name), str);
			gb_string_free(str);
		}
		operand->type = t_invalid;
		operand->mode = Addressing_NoValue;
	} else if (name == "defined") {
		if (ce->args.count != 1) {
			error(call, "'#defined' expects 1 argument, got %td", ce->args.count);
			return false;
		}
		Ast *arg = unparen_expr(ce->args[0]);
		if (arg == nullptr || (arg->kind != Ast_Ident && arg->kind != Ast_SelectorExpr)) {
			error(call, "'#defined' expects an identifier or selector expression, got %.*s", LIT(ast_strings[arg->kind]));
			return false;
		}

		if (c->curr_proc_decl == nullptr) {
			error(call, "'#defined' is only allowed within a procedure, prefer the replacement '#config(NAME, default_value)'");
			return false;
		}

		bool is_defined = check_identifier_exists(c->scope, arg);
		// gb_unused(is_defined);
		operand->type = t_untyped_bool;
		operand->mode = Addressing_Constant;
		operand->value = exact_value_bool(is_defined);

	} else if (name == "config") {
		if (ce->args.count != 2) {
			error(call, "'#config' expects 2 argument, got %td", ce->args.count);
			return false;
		}
		Ast *arg = unparen_expr(ce->args[0]);
		if (arg == nullptr || arg->kind != Ast_Ident) {
			error(call, "'#config' expects an identifier, got %.*s", LIT(ast_strings[arg->kind]));
			return false;
		}

		Ast *def_arg = unparen_expr(ce->args[1]);

		Operand def = {};
		check_expr(c, &def, def_arg);
		if (def.mode != Addressing_Constant) {
			error(def_arg, "'#config' default value must be a constant");
			return false;
		}

		String name = arg->Ident.token.string;


		operand->type = def.type;
		operand->mode = def.mode;
		operand->value = def.value;

		Entity *found = scope_lookup_current(config_pkg->scope, name);
		if (found != nullptr) {
			if (found->kind != Entity_Constant) {
				error(arg, "'#config' entity '%.*s' found but expected a constant", LIT(name));
			} else {
				operand->type = found->type;
				operand->mode = Addressing_Constant;
				operand->value = found->Constant.value;
			}
		}
	} else {
		error(call, "Unknown directive call: #%.*s", LIT(name));
	}
	return true;
}

gb_internal bool check_builtin_procedure(CheckerContext *c, Operand *operand, Ast *call, i32 id, Type *type_hint) {
	ast_node(ce, CallExpr, call);
	if (ce->inlining != ProcInlining_none) {
		error(call, "Inlining operators are not allowed on built-in procedures");
	}

	BuiltinProc *bp = &builtin_procs[id];
	{
		char const *err = nullptr;
		if (ce->args.count < bp->arg_count) {
			err = "Too few";
		} else if (ce->args.count > bp->arg_count && !bp->variadic) {
			err = "Too many";
		}

		if (err != nullptr) {
			gbString expr = expr_to_string(ce->proc);
			error(ce->close, "%s arguments for '%s', expected %td, got %td",
			      err, expr,
			      bp->arg_count, ce->args.count);
			gb_string_free(expr);
			return false;
		}
	}

	switch (id) {
	case BuiltinProc_size_of:
	case BuiltinProc_align_of:
	case BuiltinProc_offset_of:
	case BuiltinProc_offset_of_by_string:
	case BuiltinProc_type_info_of:
	case BuiltinProc_typeid_of:
	case BuiltinProc_len:
	case BuiltinProc_cap:
	case BuiltinProc_min:
	case BuiltinProc_max:
	case BuiltinProc_type_is_subtype_of:
	case BuiltinProc_objc_send:
	case BuiltinProc_objc_find_selector: 
	case BuiltinProc_objc_find_class: 
	case BuiltinProc_objc_register_selector: 
	case BuiltinProc_objc_register_class: 
	case BuiltinProc_atomic_type_is_lock_free:
	case BuiltinProc_has_target_feature:
		// NOTE(bill): The first arg may be a Type, this will be checked case by case
		break;

	case BuiltinProc_atomic_thread_fence:
	case BuiltinProc_atomic_signal_fence:
		// NOTE(bill): first type will require a type hint
		break;

	case BuiltinProc_DIRECTIVE: {
		ast_node(bd, BasicDirective, ce->proc);
		String name = bd->name.string;
		if (name == "defined") {
			break;
		}
		if (name == "config") {
			break;
		}
		/*fallthrough*/
	}
	default:
		if (BuiltinProc__type_begin < id && id < BuiltinProc__type_end) {
			check_expr_or_type(c, operand, ce->args[0]);
		} else if (ce->args.count > 0) {
			check_multi_expr(c, operand, ce->args[0]);
		}
		break;
	}

	String const &builtin_name = builtin_procs[id].name;


	if (ce->args.count > 0) {
		if (ce->args[0]->kind == Ast_FieldValue) {
			switch (id) {
			case BuiltinProc_soa_zip:
			case BuiltinProc_quaternion:
				// okay
				break;
			default:
				error(call, "'field = value' calling is not allowed on built-in procedures");
				return false;
			}
		}
	}

	if (BuiltinProc__simd_begin < id && id < BuiltinProc__simd_end) {
		bool ok = check_builtin_simd_operation(c, operand, call, id, type_hint);
		if (!ok) {
			operand->type = t_invalid;
		}
		operand->mode = Addressing_Value;
		operand->value = {};
		operand->expr = call;
		return ok;
	}

	switch (id) {
	default:
		GB_PANIC("Implement built-in procedure: %.*s", LIT(builtin_name));
		break;

	case BuiltinProc_objc_send:
	case BuiltinProc_objc_find_selector: 
	case BuiltinProc_objc_find_class: 
	case BuiltinProc_objc_register_selector: 
	case BuiltinProc_objc_register_class: 
		return check_builtin_objc_procedure(c, operand, call, id, type_hint);

	case BuiltinProc___entry_point:
		operand->mode = Addressing_NoValue;
		operand->type = nullptr;
		mpsc_enqueue(&c->info->intrinsics_entry_point_usage, call);
		break;

	case BuiltinProc_DIRECTIVE:
		return check_builtin_procedure_directive(c, operand, call, type_hint);

	case BuiltinProc_len:
	case BuiltinProc_cap:
	{
		// len :: proc(Type) -> int
		// cap :: proc(Type) -> int
		check_expr_or_type(c, operand, ce->args[0]);
		if (operand->mode == Addressing_Invalid) {
			return false;
		}

		Type *op_type = type_deref(operand->type);
		Type *type = t_int;
		if (type_hint != nullptr) {
			Type *bt = type_hint;
			// bt = base_type(bt);
			if (bt == t_int) {
				type = type_hint;
			} else if (bt == t_uint) {
				type = type_hint;
			}
		}

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
				if (is_type_cstring(op_type)) {
					add_package_dependency(c, "runtime", "cstring_len");
				}
			}
		} else if (is_type_array(op_type)) {
			Type *at = core_type(op_type);
			mode = Addressing_Constant;
			value = exact_value_i64(at->Array.count);
			type = t_untyped_integer;
		} else if (is_type_enumerated_array(op_type) && id == BuiltinProc_len) {
			Type *at = core_type(op_type);
			mode = Addressing_Constant;
			value = exact_value_i64(at->EnumeratedArray.count);
			type = t_untyped_integer;
		} else if (is_type_slice(op_type) && id == BuiltinProc_len) {
			mode = Addressing_Value;
		} else if (is_type_dynamic_array(op_type)) {
			mode = Addressing_Value;
		} else if (is_type_map(op_type)) {
			mode = Addressing_Value;
		} else if (operand->mode == Addressing_Type && is_type_enum(op_type)) {
			Type *bt = base_type(op_type);
			mode = Addressing_Constant;
			type = t_untyped_integer;
			if (id == BuiltinProc_len) {
				value = exact_value_i64(bt->Enum.fields.count);
			} else {
				GB_ASSERT(id == BuiltinProc_cap);
				value = exact_value_sub(*bt->Enum.max_value, *bt->Enum.min_value);
				value = exact_value_increment_one(value);
			}
		} else if (is_type_struct(op_type)) {
			Type *bt = base_type(op_type);
			if (bt->Struct.soa_kind == StructSoa_Fixed) {
				mode  = Addressing_Constant;
				value = exact_value_i64(bt->Struct.soa_count);
				type  = t_untyped_integer;
			} else if ((bt->Struct.soa_kind == StructSoa_Slice && id == BuiltinProc_len) ||
			           bt->Struct.soa_kind == StructSoa_Dynamic) {
				mode = Addressing_Value;
			}
		} else if (is_type_simd_vector(op_type)) {
			Type *bt = base_type(op_type);
			mode  = Addressing_Constant;
			value = exact_value_i64(bt->SimdVector.count);
			type  = t_untyped_integer;
		}
		if (operand->mode == Addressing_Type && mode != Addressing_Constant) {
			mode = Addressing_Invalid;
		}

		if (mode == Addressing_Invalid) {
			gbString t = type_to_string(operand->type);
			error(call, "'%.*s' is not supported for '%s'", LIT(builtin_name), t);
			return false;
		}

		operand->mode  = mode;
		operand->value = value;
		operand->type  = type;

		break;
	}

	case BuiltinProc_size_of: {
		// size_of :: proc(Type or expr) -> untyped int
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid) {
			error(ce->args[0], "Invalid argument for 'size_of'");
			return false;
		}
		t = default_type(t);

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_size_of(t));
		operand->type = t_untyped_integer;

		break;
	}

	case BuiltinProc_align_of: {
		// align_of :: proc(Type or expr) -> untyped int
		Operand o = {};
		check_expr_or_type(c, &o, ce->args[0]);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid) {
			error(ce->args[0], "Invalid argument for 'align_of'");
			return false;
		}
		t = default_type(t);

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_align_of(t));
		operand->type = t_untyped_integer;

		break;
	}


	case BuiltinProc_offset_of: {
		// offset_of :: proc(value.field) -> uintptr
		// offset_of :: proc(Type, field) -> uintptr

		Type *type = nullptr;
		Ast *field_arg = nullptr;

		if (ce->args.count == 1) {
			Ast *arg0 = unparen_expr(ce->args[0]);
			if (arg0->kind != Ast_SelectorExpr) {
				gbString x = expr_to_string(arg0);
				error(ce->args[0], "Invalid expression for '%.*s', '%s' is not a selector expression", LIT(builtin_name), x);
				gb_string_free(x);
				return false;
			}

			ast_node(se, SelectorExpr, arg0);

			Operand x = {};
			check_expr(c, &x, se->expr);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			type = type_deref(x.type);

			Type *bt = base_type(type);
			if (bt == nullptr || bt == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}

			field_arg = unparen_expr(se->selector);
		} else if (ce->args.count == 2) {
			type = check_type(c, ce->args[0]);
			Type *bt = base_type(type);
			if (bt == nullptr || bt == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}

			field_arg = unparen_expr(ce->args[1]);
		} else {
			error(ce->args[0], "Expected either 1 or 2 arguments to '%.*s', in the format of '%.*s(Type, field)', '%.*s(value.field)'", LIT(builtin_name), LIT(builtin_name), LIT(builtin_name));
			return false;
		}
		GB_ASSERT(type != nullptr);
		
		String field_name = {};
		
		if (field_arg == nullptr) {
			error(call, "Expected an identifier for field argument");
			return false;
		}

		if (field_arg->kind == Ast_Ident) {
			field_name = field_arg->Ident.token.string;
		}
		if (field_name.len == 0) {
			error(field_arg, "Expected an identifier for field argument");
			return false;
		}

		
		if (is_type_array(type)) {
			gbString t = type_to_string(type);
			error(field_arg, "Invalid a struct type for '%.*s', got '%s'", LIT(builtin_name), t);
			gb_string_free(t);
			return false;
		}

		Type *bt = base_type(type);
		if (bt->kind == Type_Struct && bt->Struct.scope != nullptr) {
			if (is_type_polymorphic(bt)) {
				gbString t = type_to_string(type);
				error(field_arg, "Cannot use '%.*s' on an unspecialized polymorphic struct type, got '%s'", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			} else if (bt->Struct.fields.count == 0 && bt->Struct.node == nullptr) {
				gbString t = type_to_string(type);
				error(field_arg, "Cannot use '%.*s' on incomplete struct declaration, got '%s'", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
		}
		
		Selection sel = lookup_field(type, field_name, false);
		if (sel.entity == nullptr) {
			ERROR_BLOCK();
			gbString type_str = type_to_string_shorthand(type);
			error(ce->args[0],
			      "'%s' has no field named '%.*s'", type_str, LIT(field_name));
			gb_string_free(type_str);

			Type *bt = base_type(type);
			if (bt->kind == Type_Struct) {
				check_did_you_mean_type(field_name, bt->Struct.fields);
			}
			return false;
		}
		if (sel.indirect) {
			gbString type_str = type_to_string_shorthand(type);
			error(ce->args[0],
			      "Field '%.*s' is embedded via a pointer in '%s'", LIT(field_name), type_str);
			gb_string_free(type_str);
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_offset_of_from_selection(type, sel));
		operand->type  = t_uintptr;
		break;
	}
	
	case BuiltinProc_offset_of_by_string: {
		// offset_of_by_string :: proc(Type, string) -> uintptr

		Type *type = nullptr;
		Ast *field_arg = nullptr;

		if (ce->args.count == 2) {
			type = check_type(c, ce->args[0]);
			Type *bt = base_type(type);
			if (bt == nullptr || bt == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}

			field_arg = unparen_expr(ce->args[1]);
		} else {
			error(ce->args[0], "Expected either 2 arguments to '%.*s', in the format of '%.*s(Type, field)'", LIT(builtin_name), LIT(builtin_name));
			return false;
		}
		GB_ASSERT(type != nullptr);
		
		String field_name = {};
		
		if (field_arg == nullptr) {
			error(call, "Expected a constant (not-empty) string for field argument");
			return false;
		}

		Operand x = {};
		check_expr(c, &x, field_arg);
		if (x.mode == Addressing_Constant && x.value.kind == ExactValue_String) {
			field_name = x.value.value_string;
		}
		if (field_name.len == 0) {
			error(field_arg, "Expected a constant (non-empty) string for field argument");
			return false;
		}

		
		if (is_type_array(type)) {
			gbString t = type_to_string(type);
			error(field_arg, "Invalid a struct type for '%.*s', got '%s'", LIT(builtin_name), t);
			gb_string_free(t);
			return false;
		}
		
		Selection sel = lookup_field(type, field_name, false);
		if (sel.entity == nullptr) {
			ERROR_BLOCK();
			gbString type_str = type_to_string_shorthand(type);
			error(ce->args[0],
			      "'%s' has no field named '%.*s'", type_str, LIT(field_name));
			gb_string_free(type_str);

			Type *bt = base_type(type);
			if (bt->kind == Type_Struct) {
				check_did_you_mean_type(field_name, bt->Struct.fields);
			}
			return false;
		}
		if (sel.indirect) {
			gbString type_str = type_to_string_shorthand(type);
			error(ce->args[0],
			      "Field '%.*s' is embedded via a pointer in '%s'", LIT(field_name), type_str);
			gb_string_free(type_str);
			return false;
		}

		operand->mode = Addressing_Constant;
		operand->value = exact_value_i64(type_offset_of_from_selection(type, sel));
		operand->type  = t_uintptr;
		break;
	}


	case BuiltinProc_type_of: {
		// type_of :: proc(val: Type) -> type(Type)
		Ast *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, expr);

		// check_assignment(c, operand, nullptr, str_lit("argument of 'type_of'"));
		if (o.mode == Addressing_Invalid || o.mode == Addressing_Builtin) {
			return false;
		}
		if (o.type == nullptr || o.type == t_invalid || is_type_asm_proc(o.type)) {
			error(o.expr, "Invalid argument to 'type_of'");
			return false;
		}
		// NOTE(bill): Prevent type cycles for procedure declarations
		if (c->curr_proc_sig == o.type) {
			gbString s = expr_to_string(o.expr);
			error(o.expr, "Invalid cyclic type usage from 'type_of', got '%s'", s);
			gb_string_free(s);
			return false;
		}

		if (is_type_polymorphic(o.type)) {
			error(o.expr, "'type_of' of polymorphic type cannot be determined");
			return false;
		}
		operand->mode = Addressing_Type;
		operand->type = o.type;
		break;
	}

	case BuiltinProc_type_info_of: {
		// type_info_of :: proc(Type) -> ^Type_Info
		if (c->scope->flags&ScopeFlag_Global) {
			compiler_error("'type_info_of' Cannot be declared within the runtime package due to how the internals of the compiler works");
		}
		if (build_context.no_rtti) {
			error(call, "'%.*s' has been disallowed", LIT(builtin_name));
			return false;
		}

		// NOTE(bill): The type information may not be setup yet
		init_core_type_info(c->checker);
		Ast *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, expr);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid || is_type_asm_proc(o.type) || is_type_polymorphic(t)) {
			if (is_type_polymorphic(t)) {
				error(ce->args[0], "Invalid argument for '%.*s', unspecialized polymorphic type", LIT(builtin_name));
			} else {
				error(ce->args[0], "Invalid argument for '%.*s'", LIT(builtin_name));
			}
			return false;
		}
		t = default_type(t);

		add_type_info_type(c, t);
		GB_ASSERT(t_type_info_ptr != nullptr);
		add_type_info_type(c, t_type_info_ptr);

		if (is_operand_value(o) && is_type_typeid(t)) {
			add_package_dependency(c, "runtime", "__type_info_of");
		} else if (o.mode != Addressing_Type) {
			error(expr, "Expected a type or typeid for '%.*s'", LIT(builtin_name));
			return false;
		}

		operand->mode = Addressing_Value;
		operand->type = t_type_info_ptr;
		break;
	}

	case BuiltinProc_typeid_of: {
		// typeid_of :: proc(Type) -> typeid
		if (c->scope->flags&ScopeFlag_Global) {
			compiler_error("'typeid_of' Cannot be declared within the runtime package due to how the internals of the compiler works");
		}
		if (build_context.no_rtti) {
			error(call, "'%.*s' has been disallowed", LIT(builtin_name));
			return false;
		}

		// NOTE(bill): The type information may not be setup yet
		init_core_type_info(c->checker);
		Ast *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, expr);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid || is_type_asm_proc(t) || is_type_polymorphic(t)) {
			error(ce->args[0], "Invalid argument for '%.*s'", LIT(builtin_name));
			return false;
		}
		t = default_type(t);

		add_type_info_type(c, t);

		if (o.mode != Addressing_Type) {
			error(expr, "Expected a type for '%.*s'", LIT(builtin_name));
			return false;
		}

		operand->mode = Addressing_Value;
		operand->type = t_typeid;
		operand->value = exact_value_typeid(t);
		break;
	}

	case BuiltinProc_swizzle: {
		// swizzle :: proc(v: [N]T, ..int) -> [M]T
		Type *original_type = operand->type;
		Type *type = base_type(original_type);
		i64 max_count = 0;
		Type *elem_type = nullptr;

		if (!is_type_array(type) && !is_type_simd_vector(type)) {
			gbString type_str = type_to_string(operand->type);
			error(call,
			      "'swizzle' is only allowed on an array or #simd vector, got '%s'",
			      type_str);
			gb_string_free(type_str);
			return false;
		}
		if (type->kind == Type_Array) {
			max_count = type->Array.count;
			elem_type = type->Array.elem;
		} else if (type->kind == Type_SimdVector) {
			max_count = type->SimdVector.count;
			elem_type = type->SimdVector.elem;
		}

		i64 arg_count = 0;
		for_array(i, ce->args) {
			if (i == 0) {
				continue;
			}
			Ast *arg = ce->args[i];
			Operand op = {};
			check_expr(c, &op, arg);
			if (op.mode == Addressing_Invalid) {
				return false;
			}
			Type *arg_type = base_type(op.type);
			if (!is_type_integer(arg_type) || op.mode != Addressing_Constant) {
				error(op.expr, "Indices to 'swizzle' must be constant integers");
				return false;
			}

			if (big_int_is_neg(&op.value.value_integer)) {
				error(op.expr, "Negative 'swizzle' index");
				return false;
			}

			BigInt mc = {};
			big_int_from_i64(&mc, max_count);
			if (big_int_cmp(&mc, &op.value.value_integer) <= 0) {
				error(op.expr, "'swizzle' index exceeds length");
				return false;
			}

			arg_count++;
		}

		if (arg_count > max_count) {
			error(call, "Too many 'swizzle' indices, %td > %td", arg_count, max_count);
			return false;
		}

		if (type->kind == Type_Array) {
			if (operand->mode == Addressing_Variable) {
				operand->mode = Addressing_SwizzleVariable;
			} else {
				operand->mode = Addressing_SwizzleValue;
			}
		} else {
			operand->mode = Addressing_Value;
		}

		if (is_type_simd_vector(type) && !is_power_of_two(arg_count)) {
			error(call, "'swizzle' with a #simd vector must have a power of two arguments, got %lld", cast(long long)arg_count);
			return false;
		}

		operand->type = determine_swizzle_array_type(original_type, type_hint, arg_count);
		break;
	}

	case BuiltinProc_complex: {
		// complex :: proc(real, imag: float_type) -> complex_type
		Operand x = *operand;
		Operand y = {};

		// NOTE(bill): Invalid will be the default till fixed
		operand->type = t_invalid;
		operand->mode = Addressing_Invalid;

		check_expr(c, &y, ce->args[1]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}

		convert_to_typed(c, &x, y.type); if (x.mode == Addressing_Invalid) return false;
		convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
		if (x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant) {
			x.value = exact_value_to_float(x.value);
		    	y.value = exact_value_to_float(y.value);
			if (is_type_numeric(x.type) && x.value.kind == ExactValue_Float) {
				x.type = t_untyped_float;
			}
			if (is_type_numeric(y.type) && y.value.kind == ExactValue_Float) {
				y.type = t_untyped_float;
			}
		}

		if (!are_types_identical(x.type, y.type)) {
			gbString tx = type_to_string(x.type);
			gbString ty = type_to_string(y.type);
			error(call, "Mismatched types to 'complex', '%s' vs '%s'", tx, ty);
			gb_string_free(ty);
			gb_string_free(tx);
			return false;
		}

		if (!is_type_float(x.type)) {
			gbString s = type_to_string(x.type);
			error(call, "Arguments have type '%s', expected a floating point", s);
			gb_string_free(s);
			return false;
		}
		if (is_type_endian_specific(x.type)) {
			gbString s = type_to_string(x.type);
			error(call, "Arguments with a specified endian are not allow, expected a normal floating point, got '%s'", s);
			gb_string_free(s);
			return false;
		}

		if (x.mode == Addressing_Constant && y.mode == Addressing_Constant) {
			f64 r = exact_value_to_float(x.value).value_float;
			f64 i = exact_value_to_float(y.value).value_float;
			operand->value = exact_value_complex(r, i);
			operand->mode = Addressing_Constant;
		} else {
			operand->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x.type)->Basic.kind;
		switch (kind) {
		case Basic_f16:          operand->type = t_complex32;       break;
		case Basic_f32:          operand->type = t_complex64;       break;
		case Basic_f64:          operand->type = t_complex128;      break;
		case Basic_UntypedFloat: operand->type = t_untyped_complex; break;
		default: GB_PANIC("Invalid type"); break;
		}

		if (type_hint != nullptr && check_is_castable_to(c, operand, type_hint)) {
			operand->type = type_hint;
		}

		break;
	}

	case BuiltinProc_quaternion: {
		bool first_is_field_value = (ce->args[0]->kind == Ast_FieldValue);

		bool fail = false;
		for (Ast *arg : ce->args) {
			bool mix = false;
			if (first_is_field_value) {
				mix = arg->kind != Ast_FieldValue;
			} else {
				mix = arg->kind == Ast_FieldValue;
			}
			if (mix) {
				error(arg, "Mixture of 'field = value' and value elements in the procedure call '%.*s' is not allowed", LIT(builtin_name));
				fail = true;
				break;
			}
		}

		if (fail) {
			operand->type = t_untyped_quaternion;
			operand->mode = Addressing_Constant;
			operand->value = exact_value_quaternion(0.0, 0.0, 0.0, 0.0);
			break;
		}

		// quaternion :: proc(imag, jmag, kmag, real: float_type) -> complex_type
		Operand xyzw[4] = {};

		u32 first_index = 0;

		// NOTE(bill): Invalid will be the default till fixed
		operand->type = t_invalid;
		operand->mode = Addressing_Invalid;

		if (first_is_field_value) {
			u32 fields_set[4] = {}; // 0 unset, 1 xyzw, 2 real/etc

			auto const check_field = [&fields_set, &builtin_name](CheckerContext *c, Operand *o, Ast *arg, i32 *index) -> bool {
				*index = -1;

				ast_node(field, FieldValue, arg);
				String name = {};
				if (field->field->kind == Ast_Ident) {
					name = field->field->Ident.token.string;
				} else {
					error(field->field, "Expected an identifier for field argument");
					return false;
				}

				u32 style = 0;

				if (name == "x") {
					*index = 0; style = 1;
				} else if (name == "y") {
					*index = 1; style = 1;
				} else if (name == "z") {
					*index = 2; style = 1;
				}  else if (name == "w") {
					*index = 3; style = 1;
				} else if (name == "imag") {
					*index = 0; style = 2;
				} else if (name == "jmag") {
					*index = 1; style = 2;
				} else if (name == "kmag") {
					*index = 2; style = 2;
				}  else if (name == "real") {
					*index = 3; style = 2;
				} else {
					error(field->field, "Unknown name for '%.*s', expected (w, x, y, z; or real, imag, jmag, kmag), got '%.*s'", LIT(builtin_name), LIT(name));
					return false;
				}

				if (fields_set[*index]) {
					error(field->field, "Previously assigned field: '%.*s'", LIT(name));
				}
				fields_set[*index] = style;

				check_expr(c, o, field->value);
				return o->mode != Addressing_Invalid;
			};

			Operand *refs[4] = {&xyzw[0], &xyzw[1], &xyzw[2], &xyzw[3]};

			for (i32 i = 0; i < 4; i++) {
				i32 index = -1;
				Operand o = {};
				bool ok = check_field(c, &o, ce->args[i], &index);
				if (!ok || index < 0) {
					return false;
				}
				first_index = cast(u32)index;
				*refs[index] = o;
			}

			for (i32 i = 0; i < 4; i++) {
				GB_ASSERT(fields_set[i]);
			}
			for (i32 i = 1; i < 4; i++) {
				if (fields_set[i] != fields_set[i-1]) {
					error(call, "Mixture of xyzw and real/etc is not allowed with '%.*s'", LIT(builtin_name));
					break;
				}
			}
		} else {
			error(call, "'%.*s' requires that all arguments are named (w, x, y, z; or real, imag, jmag, kmag)", LIT(builtin_name));

			for (i32 i = 0; i < 4; i++) {
				check_expr(c, &xyzw[i], ce->args[i]);
				if (xyzw[i].mode == Addressing_Invalid) {
					return false;
				}
			}
		}


		for (u32 i = 0; i < 4; i++ ){
			u32 j = (i + first_index) % 4;
			if (j == first_index) {
				convert_to_typed(c, &xyzw[j], xyzw[(first_index+1)%4].type); if (xyzw[j].mode == Addressing_Invalid) return false;
			} else {
				convert_to_typed(c, &xyzw[j], xyzw[first_index].type); if (xyzw[j].mode == Addressing_Invalid) return false;
			}
		}
		if (xyzw[0].mode == Addressing_Constant &&
		    xyzw[1].mode == Addressing_Constant &&
		    xyzw[2].mode == Addressing_Constant &&
		    xyzw[3].mode == Addressing_Constant) {
			for (i32 i = 0; i < 4; i++) {
				xyzw[i].value = exact_value_to_float(xyzw[i].value);
			}
			for (i32 i = 0; i < 4; i++) {
				if (is_type_numeric(xyzw[i].type) && xyzw[i].value.kind == ExactValue_Float) {
					xyzw[i].type = t_untyped_float;
				}
			}
		}

		if (!(are_types_identical(xyzw[0].type, xyzw[1].type) &&
		      are_types_identical(xyzw[0].type, xyzw[2].type) &&
		      are_types_identical(xyzw[0].type, xyzw[3].type))) {
			gbString tx = type_to_string(xyzw[0].type);
			gbString ty = type_to_string(xyzw[1].type);
			gbString tz = type_to_string(xyzw[2].type);
			gbString tw = type_to_string(xyzw[3].type);
			error(call, "Mismatched types to 'quaternion', 'x=%s' vs 'y=%s' vs 'z=%s' vs 'w=%s'", tx, ty, tz, tw);
			gb_string_free(tw);
			gb_string_free(tz);
			gb_string_free(ty);
			gb_string_free(tx);
			return false;
		}

		if (!is_type_float(xyzw[0].type)) {
			gbString s = type_to_string(xyzw[0].type);
			error(call, "Arguments have type '%s', expected a floating point", s);
			gb_string_free(s);
			return false;
		}
		if (is_type_endian_specific(xyzw[0].type)) {
			gbString s = type_to_string(xyzw[0].type);
			error(call, "Arguments with a specified endian are not allow, expected a normal floating point, got '%s'", s);
			gb_string_free(s);
			return false;
		}


		operand->mode = Addressing_Value;

		if (xyzw[0].mode == Addressing_Constant &&
		    xyzw[1].mode == Addressing_Constant &&
		    xyzw[2].mode == Addressing_Constant &&
		    xyzw[3].mode == Addressing_Constant) {
			f64 r = exact_value_to_float(xyzw[3].value).value_float;
			f64 i = exact_value_to_float(xyzw[0].value).value_float;
			f64 j = exact_value_to_float(xyzw[1].value).value_float;
			f64 k = exact_value_to_float(xyzw[2].value).value_float;
			operand->value = exact_value_quaternion(r, i, j, k);
			operand->mode = Addressing_Constant;
		}

		BasicKind kind = core_type(xyzw[first_index].type)->Basic.kind;
		switch (kind) {
		case Basic_f16:          operand->type = t_quaternion64;       break;
		case Basic_f32:          operand->type = t_quaternion128;      break;
		case Basic_f64:          operand->type = t_quaternion256;      break;
		case Basic_UntypedFloat: operand->type = t_untyped_quaternion; break;
		default: GB_PANIC("Invalid type"); break;
		}

		if (type_hint != nullptr && check_is_castable_to(c, operand, type_hint)) {
			operand->type = type_hint;
		}

		break;
	}

	case BuiltinProc_real:
	case BuiltinProc_imag: {
		// real :: proc(x: type) -> float_type
		// imag :: proc(x: type) -> float_type

		Operand *x = operand;
		if (is_type_untyped(x->type)) {
			if (x->mode == Addressing_Constant) {
				if (is_type_numeric(x->type)) {
					x->type = t_untyped_complex;
				}
			} else if (is_type_quaternion(x->type)) {
				convert_to_typed(c, x, t_quaternion256);
				if (x->mode == Addressing_Invalid) {
					return false;
				}
			} else{
				convert_to_typed(c, x, t_complex128);
				if (x->mode == Addressing_Invalid) {
					return false;
				}
			}
		}

		if (!is_type_complex(x->type) && !is_type_quaternion(x->type)) {
			gbString s = type_to_string(x->type);
			error(call, "Argument has type '%s', expected a complex or quaternion type", s);
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
		case Basic_complex32:         x->type = t_f16;           break;
		case Basic_complex64:         x->type = t_f32;           break;
		case Basic_complex128:        x->type = t_f64;           break;
		case Basic_quaternion64:      x->type = t_f16;           break;
		case Basic_quaternion128:     x->type = t_f32;           break;
		case Basic_quaternion256:     x->type = t_f64;           break;
		case Basic_UntypedComplex:    x->type = t_untyped_float; break;
		case Basic_UntypedQuaternion: x->type = t_untyped_float; break;
		default: GB_PANIC("Invalid type"); break;
		}

		if (type_hint != nullptr && check_is_castable_to(c, operand, type_hint)) {
			operand->type = type_hint;
		}

		break;
	}

	case BuiltinProc_jmag:
	case BuiltinProc_kmag: {
		// jmag :: proc(x: type) -> float_type
		// kmag :: proc(x: type) -> float_type

		Operand *x = operand;
		if (is_type_untyped(x->type)) {
			if (x->mode == Addressing_Constant) {
				if (is_type_numeric(x->type)) {
					x->type = t_untyped_complex;
				}
			} else{
				convert_to_typed(c, x, t_quaternion256);
				if (x->mode == Addressing_Invalid) {
					return false;
				}
			}
		}

		if (!is_type_quaternion(x->type)) {
			gbString s = type_to_string(x->type);
			error(call, "Argument has type '%s', expected a quaternion type", s);
			gb_string_free(s);
			return false;
		}

		if (x->mode == Addressing_Constant) {
			switch (id) {
			case BuiltinProc_jmag: x->value = exact_value_jmag(x->value); break;
			case BuiltinProc_kmag: x->value = exact_value_kmag(x->value); break;
			}
		} else {
			x->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x->type)->Basic.kind;
		switch (kind) {
		case Basic_quaternion64:      x->type = t_f16;           break;
		case Basic_quaternion128:     x->type = t_f32;           break;
		case Basic_quaternion256:     x->type = t_f64;           break;
		case Basic_UntypedComplex:    x->type = t_untyped_float; break;
		case Basic_UntypedQuaternion: x->type = t_untyped_float; break;
		default: GB_PANIC("Invalid type"); break;
		}

		if (type_hint != nullptr && check_is_castable_to(c, operand, type_hint)) {
			operand->type = type_hint;
		}

		break;
	}

	case BuiltinProc_conj: {
		// conj :: proc(x: type) -> type
		Operand *x = operand;
		Type *t = x->type;
		Type *elem = core_array_type(t);
		
		if (is_type_complex(t)) {
			if (x->mode == Addressing_Constant) {
				ExactValue v = exact_value_to_complex(x->value);
				f64 r = v.value_complex->real;
				f64 i = -v.value_complex->imag;
				x->value = exact_value_complex(r, i);
				x->mode = Addressing_Constant;
			} else {
				x->mode = Addressing_Value;
			}
		} else if (is_type_quaternion(t)) {
			if (x->mode == Addressing_Constant) {
				ExactValue v = exact_value_to_quaternion(x->value);
				f64 r = +v.value_quaternion->real;
				f64 i = -v.value_quaternion->imag;
				f64 j = -v.value_quaternion->jmag;
				f64 k = -v.value_quaternion->kmag;
				x->value = exact_value_quaternion(r, i, j, k);
				x->mode = Addressing_Constant;
			} else {
				x->mode = Addressing_Value;
			}
		} else if (is_type_array_like(t) && (is_type_complex(elem) || is_type_quaternion(elem))) {
			x->mode = Addressing_Value;
		} else if (is_type_matrix(t) && (is_type_complex(elem) || is_type_quaternion(elem))) {
			x->mode = Addressing_Value;
		}else {
			gbString s = type_to_string(x->type);
			error(call, "Expected a complex or quaternion, got '%s'", s);
			gb_string_free(s);
			return false;
		}

		break;
	}

	case BuiltinProc_expand_values: {
		Type *type = base_type(operand->type);
		if (!is_type_struct(type) && !is_type_array(type)) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a struct or array type, got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}
		gbAllocator a = permanent_allocator();

		Type *tuple = alloc_type_tuple();

		if (is_type_struct(type)) {
			isize variable_count = type->Struct.fields.count;
			slice_init(&tuple->Tuple.variables, a, variable_count);
			// NOTE(bill): don't copy the entities, this should be good enough
			gb_memmove_array(tuple->Tuple.variables.data, type->Struct.fields.data, variable_count);
		} else if (is_type_array(type)) {
			isize variable_count = cast(isize)type->Array.count;
			slice_init(&tuple->Tuple.variables, a, variable_count);
			for (isize i = 0; i < variable_count; i++) {
				tuple->Tuple.variables[i] = alloc_entity_array_elem(nullptr, blank_token, type->Array.elem, cast(i32)i);
			}
		}
		operand->type = tuple;
		operand->mode = Addressing_Value;

		if (tuple->Tuple.variables.count == 1) {
			operand->type = tuple->Tuple.variables[0]->type;
		}

		break;
	}

	case BuiltinProc_min: {
		// min :: proc($T: typeid) -> ordered
		// min :: proc(a: ..ordered) -> ordered

		check_multi_expr_or_type(c, operand, ce->args[0]);

		Type *original_type = operand->type;
		Type *type = base_type(operand->type);
		if (operand->mode == Addressing_Type && is_type_enumerated_array(type)) {
			// Okay
		} else if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(original_type);
			error(call, "Expected a ordered numeric type to 'min', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (operand->mode == Addressing_Type) {
			if (ce->args.count != 1) {
				error(call, "If 'min' gets a type, only 1 arguments is allowed, got %td", ce->args.count);
				return false;
			}

			if (is_type_boolean(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				operand->value = exact_value_bool(false);
				return true;
			} else if (is_type_integer(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				if (is_type_unsigned(type)) {
					operand->value = exact_value_u64(0);
					return true;
				} else {
					i64 sz = 8*type_size_of(type);
					ExactValue a = exact_value_i64(1);
					ExactValue b = exact_value_i64(sz-1);
					ExactValue v = exact_binary_operator_value(Token_Shl, a, b);
					v = exact_unary_operator_value(Token_Sub, v, cast(i32)sz, false);
					operand->value = v;
					return true;
				}
			} else if (is_type_float(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				switch (type_size_of(type)) {
				case 2:
					operand->value = exact_value_float(-65504.0f);
					break;
				case 4:
					operand->value = exact_value_float(-3.402823466e+38f);
					break;
				case 8:
					operand->value = exact_value_float(-1.7976931348623158e+308);
					break;
				default:
					GB_PANIC("Unhandled float type");
					break;
				}
				return true;
			} else if (is_type_enum(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				operand->value = *type->Enum.min_value;
				return true;
			} else if (is_type_enumerated_array(type)) {
				Type *bt = base_type(type);
				GB_ASSERT(bt->kind == Type_EnumeratedArray);
				operand->mode  = Addressing_Constant;
				operand->type  = bt->EnumeratedArray.index;
				operand->value = *bt->EnumeratedArray.min_value;
				return true;
			}
			gbString type_str = type_to_string(original_type);
			error(call, "Invalid type for 'min', got %s", type_str);
			gb_string_free(type_str);
			return false;
		}


		bool all_constant = operand->mode == Addressing_Constant;

		auto operands = array_make<Operand>(heap_allocator(), 0, ce->args.count);
		defer (array_free(&operands));

		array_add(&operands, *operand);

		for (isize i = 1; i < ce->args.count; i++) {
			Ast *other_arg = ce->args[i];
			Operand b = {};
			check_expr(c, &b, other_arg);
			if (b.mode == Addressing_Invalid) {
				return false;
			}
			if (!is_type_ordered(b.type) || !(is_type_numeric(b.type) || is_type_string(b.type))) {
				gbString type_str = type_to_string(b.type);
				error(call,
				      "Expected a ordered numeric type to 'min', got '%s'",
				      type_str);
				gb_string_free(type_str);
				return false;
			}
			array_add(&operands, b);

			if (all_constant) {
				all_constant = b.mode == Addressing_Constant;
			}
		}

		if (all_constant) {
			ExactValue value = operands[0].value;
			Type *type = operands[0].type;
			for (isize i = 1; i < operands.count; i++) {
				Operand y = operands[i];
				if (compare_exact_values(Token_Lt, value, y.value)) {
					// okay
				} else {
					value = y.value;
					type = y.type;
				}
			}
			operand->value = value;
			operand->type = type;
		} else {
			operand->mode = Addressing_Value;
			operand->type = original_type;

			for_array(i, operands) {
				Operand *a = &operands[i];
				for_array(j, operands) {
					if (i == j) {
						continue;
					}
					Operand *b = &operands[j];

					convert_to_typed(c, a, b->type);
					if (a->mode == Addressing_Invalid) {
						return false;
					}
					convert_to_typed(c, b, a->type);
					if (b->mode == Addressing_Invalid) {
						return false;
					}
				}
			}

			for (isize i = 0; i < operands.count-1; i++) {
				Operand *a = &operands[i];
				Operand *b = &operands[i+1];

				if (!are_types_identical(a->type, b->type)) {
					gbString type_a = type_to_string(a->type);
					gbString type_b = type_to_string(b->type);
					error(a->expr,
					      "Mismatched types to 'min', '%s' vs '%s'",
					      type_a, type_b);
					gb_string_free(type_b);
					gb_string_free(type_a);
					return false;
				}
			}

			operand->type = operands[0].type;
		}
		break;
	}

	case BuiltinProc_max: {
		// max :: proc($T: typeid) -> ordered
		// max :: proc(a: ..ordered) -> ordered

		check_multi_expr_or_type(c, operand, ce->args[0]);

		Type *original_type = operand->type;
		Type *type = base_type(operand->type);

		if (operand->mode == Addressing_Type && is_type_enumerated_array(type)) {
			// Okay
		} else if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(original_type);
			error(call, "Expected a ordered numeric type to 'max', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (operand->mode == Addressing_Type) {
			if (ce->args.count != 1) {
				error(call, "If 'max' gets a type, only 1 arguments is allowed, got %td", ce->args.count);
				return false;
			}

			if (is_type_boolean(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				operand->value = exact_value_bool(true);
				return true;
			} else if (is_type_integer(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				if (is_type_unsigned(type)) {
					i64 sz = 8*type_size_of(type);
					ExactValue a = exact_value_i64(1);
					ExactValue b = exact_value_i64(sz);
					ExactValue v = exact_binary_operator_value(Token_Shl, a, b);
					v = exact_binary_operator_value(Token_Sub, v, a);
					operand->value = v;
					return true;
				} else {
					i64 sz = 8*type_size_of(type);
					ExactValue a = exact_value_i64(1);
					ExactValue b = exact_value_i64(sz-1);
					ExactValue v = exact_binary_operator_value(Token_Shl, a, b);
					v = exact_binary_operator_value(Token_Sub, v, a);
					operand->value = v;
					return true;
				}
			} else if (is_type_float(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				switch (type_size_of(type)) {
				case 2:
					operand->value = exact_value_float(65504.0f);
					break;
				case 4:
					operand->value = exact_value_float(3.402823466e+38f);
					break;
				case 8:
					operand->value = exact_value_float(1.7976931348623158e+308);
					break;
				default:
					GB_PANIC("Unhandled float type");
					break;
				}
				return true;
			} else if (is_type_enum(type)) {
				operand->mode  = Addressing_Constant;
				operand->type  = original_type;
				operand->value = *type->Enum.max_value;
				return true;
			} else if (is_type_enumerated_array(type)) {
				Type *bt = base_type(type);
				GB_ASSERT(bt->kind == Type_EnumeratedArray);
				operand->mode  = Addressing_Constant;
				operand->type  = bt->EnumeratedArray.index;
				operand->value = *bt->EnumeratedArray.max_value;
				return true;
			}
			gbString type_str = type_to_string(original_type);
			error(call, "Invalid type for 'max', got %s", type_str);
			gb_string_free(type_str);
			return false;
		}

		bool all_constant = operand->mode == Addressing_Constant;

		auto operands = array_make<Operand>(heap_allocator(), 0, ce->args.count);
		defer (array_free(&operands));

		array_add(&operands, *operand);


		for (isize i = 1; i < ce->args.count; i++) {
			Ast *arg = ce->args[i];
			Operand b = {};
			check_expr(c, &b, arg);
			if (b.mode == Addressing_Invalid) {
				return false;
			}
			if (!is_type_ordered(b.type) || !(is_type_numeric(b.type) || is_type_string(b.type))) {
				gbString type_str = type_to_string(b.type);
				error(arg,
				      "Expected a ordered numeric type to 'max', got '%s'",
				      type_str);
				gb_string_free(type_str);
				return false;
			}
			array_add(&operands, b);

			if (all_constant) {
				all_constant = b.mode == Addressing_Constant;
			}
		}

		if (all_constant) {
			ExactValue value = operands[0].value;
			Type *type = operands[0].type;
			for (isize i = 1; i < operands.count; i++) {
				Operand y = operands[i];
				if (compare_exact_values(Token_Gt, value, y.value)) {
					// okay
				} else {
					type  = y.type;
					value = y.value;
				}
			}
			operand->value = value;
			operand->type = type;
		} else {
			operand->mode = Addressing_Value;
			operand->type = original_type;

			for_array(i, operands) {
				Operand *a = &operands[i];
				for_array(j, operands) {
					if (i == j) {
						continue;
					}
					Operand *b = &operands[j];

					convert_to_typed(c, a, b->type);
					if (a->mode == Addressing_Invalid) {
						return false;
					}
					convert_to_typed(c, b, a->type);
					if (b->mode == Addressing_Invalid) {
						return false;
					}
				}
			}

			for (isize i = 0; i < operands.count-1; i++) {
				Operand *a = &operands[i];
				Operand *b = &operands[i+1];

				if (!are_types_identical(a->type, b->type)) {
					gbString type_a = type_to_string(a->type);
					gbString type_b = type_to_string(b->type);
					error(a->expr,
					      "Mismatched types to 'max', '%s' vs '%s'",
					      type_a, type_b);
					gb_string_free(type_b);
					gb_string_free(type_a);
					return false;
				}
			}

			operand->type = operands[0].type;
		}
		break;
	}

	case BuiltinProc_abs: {
		// abs :: proc(n: numeric) -> numeric
		if (!(is_type_numeric(operand->type) && !is_type_array(operand->type))) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a numeric type to 'abs', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		if (operand->mode == Addressing_Constant) {
			switch (operand->value.kind) {
			case ExactValue_Integer:
				mp_abs(&operand->value.value_integer, &operand->value.value_integer);
				break;
			case ExactValue_Float:
				operand->value.value_float = gb_abs(operand->value.value_float);
				break;
			case ExactValue_Complex: {
				f64 r = operand->value.value_complex->real;
				f64 i = operand->value.value_complex->imag;
				operand->value = exact_value_float(gb_sqrt(r*r + i*i));
				break;
			}
			case ExactValue_Quaternion: {
				f64 r = operand->value.value_quaternion->real;
				f64 i = operand->value.value_quaternion->imag;
				f64 j = operand->value.value_quaternion->jmag;
				f64 k = operand->value.value_quaternion->kmag;
				operand->value = exact_value_float(gb_sqrt(r*r + i*i + j*j + k*k));
				break;
			}
			default:
				GB_PANIC("Invalid numeric constant");
				break;
			}
		} else {
			operand->mode = Addressing_Value;

			{
				Type *bt = base_type(operand->type);
				if (are_types_identical(bt, t_complex64))  add_package_dependency(c, "runtime", "abs_complex64");
				if (are_types_identical(bt, t_complex128)) add_package_dependency(c, "runtime", "abs_complex128");
				if (are_types_identical(bt, t_quaternion128)) add_package_dependency(c, "runtime", "abs_quaternion128");
				if (are_types_identical(bt, t_quaternion256)) add_package_dependency(c, "runtime", "abs_quaternion256");
			}
		}

		if (is_type_complex_or_quaternion(operand->type)) {
			operand->type = base_complex_elem_type(operand->type);
		}
		GB_ASSERT(!is_type_complex_or_quaternion(operand->type));

		break;
	}

	case BuiltinProc_clamp: {
		// clamp :: proc(a, min, max: ordered) -> ordered
		Type *type = operand->type;
		if (!is_type_ordered(type) || !(is_type_numeric(type) || is_type_string(type))) {
			gbString type_str = type_to_string(operand->type);
			error(call, "Expected a ordered numeric or string type to 'clamp', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		Ast *min_arg = ce->args[1];
		Ast *max_arg = ce->args[2];
		Operand x = *operand;
		Operand y = {};
		Operand z = {};

		check_expr(c, &y, min_arg);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(y.type) || !(is_type_numeric(y.type) || is_type_string(y.type))) {
			gbString type_str = type_to_string(y.type);
			error(call, "Expected a ordered numeric or string type to 'clamp', got '%s'", type_str);
			gb_string_free(type_str);
			return false;
		}

		check_expr(c, &z, max_arg);
		if (z.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_type_ordered(z.type) || !(is_type_numeric(z.type) || is_type_string(z.type))) {
			gbString type_str = type_to_string(z.type);
			error(call, "Expected a ordered numeric or string type to 'clamp', got '%s'", type_str);
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

			Operand *ops[3] = {&x, &y, &z};
			for (isize i = 0; i < 3; i++) {
				Operand *a = ops[i];
				for (isize j = 0; j < 3; j++) {
					if (i == j) continue;
					Operand *b = ops[j];
					convert_to_typed(c, a, b->type);
					if (a->mode == Addressing_Invalid) return false;
				}
			}

			if (!are_types_identical(x.type, y.type) || !are_types_identical(x.type, z.type)) {
				gbString type_x = type_to_string(x.type);
				gbString type_y = type_to_string(y.type);
				gbString type_z = type_to_string(z.type);
				error(call,
				      "Mismatched types to 'clamp', '%s', '%s', '%s'",
				      type_x, type_y, type_z);
				gb_string_free(type_z);
				gb_string_free(type_y);
				gb_string_free(type_x);
				return false;
			}

			operand->type = ops[0]->type;
		}

		break;
	}

	case BuiltinProc_soa_zip: {
		TEMPORARY_ALLOCATOR_GUARD();
		auto types = array_make<Type *>(temporary_allocator(), 0, ce->args.count);
		auto names = array_make<String>(temporary_allocator(), 0, ce->args.count);

		bool first_is_field_value = (ce->args[0]->kind == Ast_FieldValue);

		bool fail = false;
		for (Ast *arg : ce->args) {
			bool mix = false;
			if (first_is_field_value) {
				mix = arg->kind != Ast_FieldValue;
			} else {
				mix = arg->kind == Ast_FieldValue;
			}
			if (mix) {
				error(arg, "Mixture of 'field = value' and value elements in the procedure call '%.*s' is not allowed", LIT(builtin_name));
				fail = true;
				break;
			}
		}
		StringSet name_set = {};
		string_set_init(&name_set, 2*ce->args.count);

		for (Ast *arg : ce->args) {
			String name = {};
			if (arg->kind == Ast_FieldValue) {
				Ast *ename = arg->FieldValue.field;
				if (!fail && ename->kind != Ast_Ident) {
					error(ename, "Expected an identifier for field argument");
				} else if (ename->kind == Ast_Ident) {
					name = ename->Ident.token.string;
				}
				arg = arg->FieldValue.value;
			}

			Operand op = {};
			check_expr(c, &op, arg);
			if (op.mode == Addressing_Invalid) {
				return false;
			}
			Type *arg_type = base_type(op.type);
			if (!is_type_slice(arg_type)) {
				gbString s = type_to_string(op.type);
				error(op.expr, "Indices to 'soa_zip' must be slices, got %s", s);
				gb_string_free(s);
				return false;
			}
			GB_ASSERT(arg_type->kind == Type_Slice);
			if (name == "_") {
				error(op.expr, "Field argument name '%.*s' is not allowed", LIT(name));
				name = {};
			}
			if (name.len == 0) {
				gbString field_name = gb_string_make(permanent_allocator(), "_");
				field_name = gb_string_append_fmt(field_name, "%td", types.count);
				name = make_string_c(field_name);
			}


			if (string_set_update(&name_set, name)) {
				error(op.expr, "Field argument name '%.*s' already exists", LIT(name));
			} else {
				array_add(&types, arg_type->Slice.elem);
				array_add(&names, name);
			}
		}




		Ast *dummy_node_struct = alloc_ast_node(nullptr, Ast_Invalid);
		Ast *dummy_node_soa = alloc_ast_node(nullptr, Ast_Invalid);
		Scope *s = create_scope(c->info, builtin_pkg->scope);

		auto fields = array_make<Entity *>(permanent_allocator(), 0, types.count);
		for_array(i, types) {
			Type *type = types[i];
			String name = names[i];
			GB_ASSERT(name != "");
			Entity *e = alloc_entity_field(s, make_token_ident(name), type, false, cast(i32)i, EntityState_Resolved);
			array_add(&fields, e);
			scope_insert(s, e);
		}

		Type *elem = nullptr;
		if (type_hint != nullptr && is_type_struct(type_hint)) {
			Type *soa_type = base_type(type_hint);
			if (soa_type->Struct.soa_kind != StructSoa_Slice) {
				goto soa_zip_end;
			}
			Type *soa_elem_type = soa_type->Struct.soa_elem;
			Type *et = base_type(soa_elem_type);
			if (et->kind != Type_Struct) {
				goto soa_zip_end;
			}

			if (et->Struct.fields.count != fields.count) {
				goto soa_zip_end;
			}
			if (!fail && first_is_field_value) {
				for_array(i, names) {
					Selection sel = lookup_field(et, names[i], false);
					if (sel.entity == nullptr) {
						goto soa_zip_end;
					}
					if (sel.index.count != 1) {
						goto soa_zip_end;
					}
					if (!are_types_identical(sel.entity->type, types[i])) {
						goto soa_zip_end;
					}
				}
 			} else {
 				for_array(i, et->Struct.fields) {
 					if (!are_types_identical(et->Struct.fields[i]->type, types[i])) {
 						goto soa_zip_end;
 					}
 				}
 			}

 			elem = soa_elem_type;
		}

		soa_zip_end:;

		if (elem == nullptr) {
			elem = alloc_type_struct();
			elem->Struct.scope = s;
			elem->Struct.fields = slice_from_array(fields);
			elem->Struct.tags = gb_alloc_array(permanent_allocator(), String, fields.count);
			elem->Struct.node = dummy_node_struct;
			type_set_offsets(elem);
			wait_signal_set(&elem->Struct.fields_wait_signal);
		}

		Type *soa_type = make_soa_struct_slice(c, dummy_node_soa, nullptr, elem);
		type_set_offsets(soa_type);

		operand->type = soa_type;
		operand->mode = Addressing_Value;

		break;
	}

	case BuiltinProc_soa_unzip: {
		Operand x = {};
		check_expr(c, &x, ce->args[0]);
		if (x.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_operand_value(x)) {
			error(call, "'%.*s' expects an #soa slice", LIT(builtin_name));
			return false;
		}
		Type *t = base_type(x.type);
		if (!is_type_soa_struct(t) || t->Struct.soa_kind != StructSoa_Slice) {
			gbString s = type_to_string(x.type);
			error(call, "'%.*s' expects an #soa slice, got %s", LIT(builtin_name), s);
			gb_string_free(s);
			return false;
		}
		auto types = slice_make<Type *>(permanent_allocator(), t->Struct.fields.count-1);
		for_array(i, types) {
			Entity *f = t->Struct.fields[i];
			GB_ASSERT(f->type->kind == Type_Pointer);
			types[i] = alloc_type_slice(f->type->Pointer.elem);
		}

		operand->type = alloc_type_tuple_from_field_types(types.data, types.count, false, false);
		operand->mode = Addressing_Value;
		break;
	}
	
	case BuiltinProc_transpose: {
		Operand x = {};
		check_expr(c, &x, ce->args[0]);
		if (x.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_operand_value(x)) {
			error(call, "'%.*s' expects a matrix or array", LIT(builtin_name));
			return false;
		}
		Type *t = base_type(x.type);
		if (!is_type_matrix(t) && !is_type_array(t)) {
			gbString s = type_to_string(x.type);
			error(call, "'%.*s' expects a matrix or array, got %s", LIT(builtin_name), s);
			gb_string_free(s);
			return false;
		}
		
		operand->mode = Addressing_Value;
		if (t->kind == Type_Array) {
			i32 rank = type_math_rank(t);
			// Do nothing
			operand->type = x.type;
			if (rank > 2) {
				gbString s = type_to_string(x.type);
				error(call, "'%.*s' expects a matrix or array with a rank of 2, got %s of rank %d", LIT(builtin_name), s, rank);
				gb_string_free(s);
				return false;
			} else if (rank == 2) {
				Type *inner = base_type(t->Array.elem);
				GB_ASSERT(inner->kind == Type_Array);
				Type *elem = inner->Array.elem;
				Type *array_inner = alloc_type_array(elem, t->Array.count);
				Type *array_outer = alloc_type_array(array_inner, inner->Array.count);
				operand->type = array_outer;

				i64 elements = t->Array.count*inner->Array.count;
				i64 size = type_size_of(operand->type);
				if (!is_type_valid_for_matrix_elems(elem)) {
					gbString s = type_to_string(x.type);
					error(call, "'%.*s' expects a matrix or array with a base element type of an integer, float, or complex number, got %s", LIT(builtin_name), s);
					gb_string_free(s);
				} else if (elements > MATRIX_ELEMENT_COUNT_MAX) {
					gbString s = type_to_string(x.type);
					error(call, "'%.*s' expects a matrix or array with a maximum of %d elements, got %s with %lld elements", LIT(builtin_name), MATRIX_ELEMENT_COUNT_MAX, s, elements);
					gb_string_free(s);
				} else if (elements > MATRIX_ELEMENT_COUNT_MAX) {
					gbString s = type_to_string(x.type);
					error(call, "'%.*s' expects a matrix or array with non-zero elements, got %s", LIT(builtin_name), MATRIX_ELEMENT_COUNT_MAX, s);
					gb_string_free(s);
				} else if (size > MATRIX_ELEMENT_MAX_SIZE) {
					gbString s = type_to_string(x.type);
					error(call, "Too large of a type for '%.*s', got %s of size %lld, maximum size %d", LIT(builtin_name), s, cast(long long)size, MATRIX_ELEMENT_MAX_SIZE);
					gb_string_free(s);
				}
			}
		} else {
			GB_ASSERT(t->kind == Type_Matrix);
			operand->type = alloc_type_matrix(t->Matrix.elem, t->Matrix.column_count, t->Matrix.row_count, nullptr, nullptr, t->Matrix.is_row_major);
		}
		operand->type = check_matrix_type_hint(operand->type, type_hint);
		break;
	}
	
	case BuiltinProc_outer_product: {
		Operand x = {};
		Operand y = {};
		check_expr(c, &x, ce->args[0]);
		if (x.mode == Addressing_Invalid) {
			return false;
		}
		check_expr(c, &y, ce->args[1]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_operand_value(x) || !is_operand_value(y)) {
			error(call, "'%.*s' expects only arrays", LIT(builtin_name));
			return false;
		}
		
		if (!is_type_array(x.type) && !is_type_array(y.type)) {
			gbString s1 = type_to_string(x.type);
			gbString s2 = type_to_string(y.type);
			error(call, "'%.*s' expects only arrays, got %s and %s", LIT(builtin_name), s1, s2);
			gb_string_free(s2);
			gb_string_free(s1);
			return false;
		}
		
		Type *xt = base_type(x.type);
		Type *yt = base_type(y.type);
		GB_ASSERT(xt->kind == Type_Array);
		GB_ASSERT(yt->kind == Type_Array);
		if (!are_types_identical(xt->Array.elem, yt->Array.elem)) {
			gbString s1 = type_to_string(xt->Array.elem);
			gbString s2 = type_to_string(yt->Array.elem);
			error(call, "'%.*s' mismatched element types, got %s vs %s", LIT(builtin_name), s1, s2);
			gb_string_free(s2);
			gb_string_free(s1);
			return false;
		}
		
		Type *elem = xt->Array.elem;
		
		if (!is_type_valid_for_matrix_elems(elem)) {
			gbString s = type_to_string(elem);
			error(call, "Matrix elements types are limited to integers, floats, and complex, got %s", s);
			gb_string_free(s);
		}
		
		if (xt->Array.count == 0 || yt->Array.count == 0) {
			gbString s1 = type_to_string(x.type);
			gbString s2 = type_to_string(y.type);
			error(call, "'%.*s' expects only arrays of non-zero length, got %s and %s", LIT(builtin_name), s1, s2);
			gb_string_free(s2);
			gb_string_free(s1);
			return false;
		}
		
		i64 max_count = xt->Array.count*yt->Array.count;
		if (max_count > MATRIX_ELEMENT_COUNT_MAX) {
			error(call, "Product of the array lengths exceed the maximum matrix element count, got %d, expected a maximum of %d", cast(int)max_count, MATRIX_ELEMENT_COUNT_MAX);
			return false;
		}
		
		operand->mode = Addressing_Value;
		operand->type = alloc_type_matrix(elem, xt->Array.count, yt->Array.count, nullptr, nullptr, false);
		operand->type = check_matrix_type_hint(operand->type, type_hint);
		break;
	}
	
	case BuiltinProc_hadamard_product: {
		Operand x = {};
		Operand y = {};
		check_expr(c, &x, ce->args[0]);
		if (x.mode == Addressing_Invalid) {
			return false;
		}
		check_expr(c, &y, ce->args[1]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_operand_value(x) || !is_operand_value(y)) {
			error(call, "'%.*s' expects a matrix or array types", LIT(builtin_name));
			return false;
		}
		if (!is_type_matrix(x.type) && !is_type_array(y.type)) {
			gbString s1 = type_to_string(x.type);
			gbString s2 = type_to_string(y.type);
			error(call, "'%.*s' expects matrix or array values, got %s and %s", LIT(builtin_name), s1, s2);
			gb_string_free(s2);
			gb_string_free(s1);
			return false;
		}
		
		if (!are_types_identical(x.type, y.type)) {
			gbString s1 = type_to_string(x.type);
			gbString s2 = type_to_string(y.type);
			error(call, "'%.*s' values of the same type, got %s and %s", LIT(builtin_name), s1, s2);
			gb_string_free(s2);
			gb_string_free(s1);
			return false;
		}
		
		Type *elem = core_array_type(x.type);
		if (!is_type_valid_for_matrix_elems(elem)) {
			gbString s = type_to_string(elem);
			error(call, "'%.*s' expects elements to be types are limited to integers, floats, and complex, got %s", LIT(builtin_name), s);
			gb_string_free(s);
		}
		
		operand->mode = Addressing_Value;
		operand->type = x.type;
		operand->type = check_matrix_type_hint(operand->type, type_hint);
		break;
	}
	
	case BuiltinProc_matrix_flatten: {
		Operand x = {};
		check_expr(c, &x, ce->args[0]);
		if (x.mode == Addressing_Invalid) {
			return false;
		}
		if (!is_operand_value(x)) {
			error(call, "'%.*s' expects a matrix or array", LIT(builtin_name));
			return false;
		}
		Type *t = base_type(x.type);
		if (!is_type_matrix(t) && !is_type_array(t)) {
			gbString s = type_to_string(x.type);
			error(call, "'%.*s' expects a matrix or array, got %s", LIT(builtin_name), s);
			gb_string_free(s);
			return false;
		}
		
		operand->mode = Addressing_Value;
		if (is_type_array(t)) {
			// Do nothing
			operand->type = x.type;			
		} else {
			GB_ASSERT(t->kind == Type_Matrix);
			operand->type = alloc_type_array(t->Matrix.elem, t->Matrix.row_count*t->Matrix.column_count);
		}
		operand->type = check_matrix_type_hint(operand->type, type_hint);
		break;
	}
	
	case BuiltinProc_is_package_imported: {
		bool value = false;

		if (!is_type_string(operand->type) && (operand->mode != Addressing_Constant)) {
			error(ce->args[0], "Expected a constant string for '%.*s'", LIT(builtin_name));
		} else if (operand->value.kind == ExactValue_String) {
			String pkg_name = operand->value.value_string;
			for (auto const &entry : c->info->packages) {
				AstPackage *pkg = entry.value;
				if (pkg->name == pkg_name) {
					value = true;
					break;
				}
			}
		}
		
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_bool;
		operand->value = exact_value_bool(value);
		break;
	}

	case BuiltinProc_has_target_feature: {
		String features = str_lit("");

		check_expr_or_type(c, operand, ce->args[0]);

		if (is_type_string(operand->type) && operand->mode == Addressing_Constant) {
			GB_ASSERT(operand->value.kind == ExactValue_String);
			features = operand->value.value_string;
		} else {
			Type *pt = base_type(operand->type);
			if (pt->kind == Type_Proc) {
				if (pt->Proc.require_target_feature.len != 0) {
					GB_ASSERT(pt->Proc.enable_target_feature.len == 0);
					features = pt->Proc.require_target_feature;
				} else if (pt->Proc.enable_target_feature.len != 0) {
					features = pt->Proc.enable_target_feature;
				} else {
					error(ce->args[0], "Expected the procedure type given to '%.*s' to have @(require_target_feature=\"...\") or @(enable_target_feature=\"...\")", LIT(builtin_name));
				}
			} else {
				error(ce->args[0], "Expected a constant string or procedure type for '%.*s'", LIT(builtin_name));
			}
		}

		String invalid;
		if (!check_target_feature_is_valid_globally(features, &invalid)) {
			error(ce->args[0], "Target feature '%.*s' is not a valid target feature", LIT(invalid));
		}

		operand->value = exact_value_bool(check_target_feature_is_enabled(features, nullptr));
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_bool;
		break;
	}

	case BuiltinProc_soa_struct: {
		Operand x = {};
		Operand y = {};
		x = *operand;
		if (!is_type_integer(x.type) || x.mode != Addressing_Constant) {
			error(call, "Expected a constant integer for 'intrinsics.soa_struct'");
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}
		if (big_int_is_neg(&x.value.value_integer)) {
			error(call, "Negative array element length");
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}
		i64 count = big_int_to_i64(&x.value.value_integer);

		check_expr_or_type(c, &y, ce->args[1]);
		if (y.mode != Addressing_Type) {
			error(call, "Expected a type 'intrinsics.soa_struct'");
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}
		Type *elem = y.type;
		Type *bt_elem = base_type(elem);
		if (!is_type_struct(elem) && !is_type_raw_union(elem) && !(is_type_array(elem) && bt_elem->Array.count <= 4)) {
			gbString str = type_to_string(elem);
			error(call, "Invalid type for 'intrinsics.soa_struct', expected a struct or array of length 4 or below, got '%s'", str);
			gb_string_free(str);
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}

		operand->mode = Addressing_Type;
		Type *soa_struct = nullptr;
		Scope *scope = nullptr;

		if (is_type_array(elem)) {
			Type *old_array = base_type(elem);
			soa_struct = alloc_type_struct();
			soa_struct->Struct.fields = slice_make<Entity *>(heap_allocator(), cast(isize)old_array->Array.count);
			soa_struct->Struct.tags = gb_alloc_array(permanent_allocator(), String, cast(isize)old_array->Array.count);
			soa_struct->Struct.node = operand->expr;
			soa_struct->Struct.soa_kind = StructSoa_Fixed;
			soa_struct->Struct.soa_elem = elem;
			soa_struct->Struct.soa_count = cast(i32)count;

			scope = create_scope(c->info, c->scope);
			soa_struct->Struct.scope = scope;

			String params_xyzw[4] = {
				str_lit("x"),
				str_lit("y"),
				str_lit("z"),
				str_lit("w")
			};

			for (isize i = 0; i < cast(isize)old_array->Array.count; i++) {
				Type *array_type = alloc_type_array(old_array->Array.elem, count);
				Token token = {};
				token.string = params_xyzw[i];

				Entity *new_field = alloc_entity_field(scope, token, array_type, false, cast(i32)i);
				soa_struct->Struct.fields[i] = new_field;
				add_entity(c, scope, nullptr, new_field);
				add_entity_use(c, nullptr, new_field);
			}

		} else {
			GB_ASSERT(is_type_struct(elem));

			Type *old_struct = base_type(elem);
			soa_struct = alloc_type_struct();
			soa_struct->Struct.fields = slice_make<Entity *>(heap_allocator(), old_struct->Struct.fields.count);
			soa_struct->Struct.tags = gb_alloc_array(permanent_allocator(), String, old_struct->Struct.fields.count);
			soa_struct->Struct.node = operand->expr;
			soa_struct->Struct.soa_kind = StructSoa_Fixed;
			soa_struct->Struct.soa_elem = elem;
			if (count > I32_MAX) {
				count = I32_MAX;
				error(call, "Array count too large for an #soa struct, got %lld", cast(long long)count);
			}
			soa_struct->Struct.soa_count = cast(i32)count;

			scope = create_scope(c->info, old_struct->Struct.scope->parent);
			soa_struct->Struct.scope = scope;

			for_array(i, old_struct->Struct.fields) {
				Entity *old_field = old_struct->Struct.fields[i];
				if (old_field->kind == Entity_Variable) {
					Type *array_type = alloc_type_array(old_field->type, count);
					Entity *new_field = alloc_entity_field(scope, old_field->token, array_type, false, old_field->Variable.field_index);
					soa_struct->Struct.fields[i] = new_field;
					add_entity(c, scope, nullptr, new_field);
				} else {
					soa_struct->Struct.fields[i] = old_field;
				}

				soa_struct->Struct.tags[i] = old_struct->Struct.tags[i];
			}
		}
		wait_signal_set(&soa_struct->Struct.fields_wait_signal);

		Token token = {};
		token.string = str_lit("Base_Type");
		Entity *base_type_entity = alloc_entity_type_name(scope, token, elem, EntityState_Resolved);
		add_entity(c, scope, nullptr, base_type_entity);

		add_type_info_type(c, soa_struct);

		operand->type = soa_struct;
		break;
	}

	case BuiltinProc_alloca:
		{
			Operand sz = {};
			Operand al = {};

			check_expr(c, &sz, ce->args[0]);
			if (sz.mode == Addressing_Invalid) {
				return false;
			}
			check_expr(c, &al, ce->args[1]);
			if (al.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &sz, t_int); if (sz.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &al, t_int); if (al.mode == Addressing_Invalid) return false;

			if (!is_type_integer(sz.type) || !is_type_integer(al.type)) {
				error(operand->expr, "Both parameters to '%.*s' must integers", LIT(builtin_name));
				return false;
			}

			if (sz.mode == Addressing_Constant) {
				i64 i_sz = exact_value_to_i64(sz.value);
				if (i_sz < 0) {
					error(sz.expr, "Size parameter to '%.*s' must be non-negative, got %lld", LIT(builtin_name), cast(long long)i_sz);
					return false;
				}
			}
			if (al.mode == Addressing_Constant) {
				i64 i_al = exact_value_to_i64(al.value);
				if (i_al < 0) {
					error(al.expr, "Alignment parameter to '%.*s' must be non-negative, got %lld", LIT(builtin_name), cast(long long)i_al);
					return false;
				}

				if (i_al > 1<<29) {
					error(al.expr, "Alignment parameter to '%.*s' must not exceed '1<<29', got %lld", LIT(builtin_name), cast(long long)i_al);
					return false;
				}

				if (!gb_is_power_of_two(cast(isize)i_al) && i_al != 0) {
					error(al.expr, "Alignment parameter to '%.*s' must be a power of 2 or 0, got %lld", LIT(builtin_name), cast(long long)i_al);
					return false;
				}
			} else {
				error(al.expr, "Alignment parameter to '%.*s' must be constant", LIT(builtin_name));
			}

			operand->type = alloc_type_multi_pointer(t_u8);
			operand->mode = Addressing_Value;
			break;
		}


	case BuiltinProc_cpu_relax:
		operand->mode = Addressing_NoValue;
		break;

	case BuiltinProc_unreachable:
	case BuiltinProc_trap:
	case BuiltinProc_debug_trap:
		operand->mode = Addressing_NoValue;
		break;

	case BuiltinProc_raw_data:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (!is_operand_value(x)) {
				gbString s = expr_to_string(x.expr);
				error(call, "'%.*s' expects a string, slice, dynamic array, or pointer to array type, got %s", LIT(builtin_name), s);
				gb_string_free(s);
				return false;
			}
			Type *t = base_type(x.type);

			operand->mode = Addressing_Value;
			operand->type = nullptr;
			switch (t->kind) {
			case Type_Slice:
				operand->type = alloc_type_multi_pointer(t->MultiPointer.elem);
				break;
			case Type_DynamicArray:
				operand->type = alloc_type_multi_pointer(t->DynamicArray.elem);
				break;
			case Type_Basic:
				if (t->Basic.kind == Basic_string) {
					operand->type = alloc_type_multi_pointer(t_u8);
				}
				break;
			case Type_Pointer:
			case Type_MultiPointer:
				{
					Type *base = base_type(type_deref(t, true));
					switch (base->kind) {
					case Type_Array:
					case Type_EnumeratedArray:
					case Type_SimdVector:
						operand->type = alloc_type_multi_pointer(base_array_type(base));
						break;
					case Type_Matrix:
						operand->type = alloc_type_multi_pointer(base->Matrix.elem);
						break;
					}
				}
				break;
			}

			if (operand->type == nullptr) {
				gbString s = type_to_string(x.type);
				error(call, "'%.*s' expects a string, slice, dynamic array, or pointer to array type, got %s", LIT(builtin_name), s);
				gb_string_free(s);
				return false;
			}
		}
		break;

	case BuiltinProc_read_cycle_counter:
		operand->mode = Addressing_Value;
		operand->type = t_i64;
		break;

	case BuiltinProc_count_ones:
	case BuiltinProc_count_zeros:
	case BuiltinProc_count_trailing_zeros:
	case BuiltinProc_count_leading_zeros:
	case BuiltinProc_reverse_bits:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}

			if (is_type_simd_vector(x.type)) {
				Type *elem = base_array_type(x.type);
				if (!is_type_integer_like(elem)) {
					gbString xts = type_to_string(x.type);
					error(x.expr, "#simd values passed to '%.*s' must have an element of an integer-like type (integer, boolean, enum, bit_set), got %s", LIT(builtin_name), xts);
					gb_string_free(xts);
				}
			} else if (!is_type_integer_like(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Values passed to '%.*s' must be an integer-like type (integer, boolean, enum, bit_set), got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
			} else if (x.type == t_llvm_bool) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Invalid type passed to '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
			}

			Type *type = default_type(x.type);
			operand->mode = Addressing_Value;
			operand->type = type;

			if (id == BuiltinProc_reverse_bits) {
				// make runtime only for the time being
			} else if (x.mode == Addressing_Constant && x.value.kind == ExactValue_Integer) {
				convert_to_typed(c, &x, type);
				if (x.mode == Addressing_Invalid) {
					return false;
				}

				ExactValue res = {};

				i64 sz = type_size_of(x.type);
				u64 bit_size = sz*8;
				u64 rop64[4] = {}; // 2 u64 is the maximum we will ever need, so doubling it will ne fine
				u8 *rop = cast(u8 *)rop64;

				size_t max_count = 0;
				size_t written = 0;
				size_t size = 1;
				size_t nails = 0;
				mp_endian endian = MP_LITTLE_ENDIAN;

				max_count = mp_pack_count(&x.value.value_integer, nails, size);
				GB_ASSERT(sz >= cast(i64)max_count);

				mp_err err = mp_pack(rop, max_count, &written, MP_LSB_FIRST, size, endian, nails, &x.value.value_integer);
				GB_ASSERT(err == MP_OKAY);

				if (id != BuiltinProc_reverse_bits) {
					u64 v = 0;
					switch (id) {
					case BuiltinProc_count_ones:
					case BuiltinProc_count_zeros:
						switch (sz) {
						case 1: v = bit_set_count(cast(u32)rop[0]);  break;
						case 2: v = bit_set_count(cast(u32)*(u16 *)rop); break;
						case 4: v = bit_set_count(*(u32 *)rop); break;
						case 8: v = bit_set_count(rop64[0]); break;
						case 16:
							v += bit_set_count(rop64[0]);
							v += bit_set_count(rop64[1]);
							break;
						default: GB_PANIC("Unhandled sized");
						}
						if (id == BuiltinProc_count_zeros) {
							// flip the result
							v = bit_size - v;
						}
						break;
					case BuiltinProc_count_trailing_zeros:
						for (u64 i = 0; i < bit_size; i++) {
							u8 b = cast(u8)(i & 7);
							u8 j = cast(u8)(i >> 3);
							if (rop[j] & (1 << b)) {
								break;
							}
							v += 1;
						}
						break;
					case BuiltinProc_count_leading_zeros:
						for (u64 i = bit_size-1; i < bit_size; i--) {
							u8 b = cast(u8)(i & 7);
							u8 j = cast(u8)(i >> 3);
							if (rop[j] & (1 << b)) {
								break;
							}
							v += 1;
						}
						break;
					}


					res = exact_value_u64(v);
				}

				if (res.kind != ExactValue_Invalid) {
					operand->mode = Addressing_Constant;
					operand->value = res;
				}
			}

		}
		break;

	case BuiltinProc_byte_swap:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}

			if (!is_type_integer_like(x.type) && !is_type_float(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Values passed to '%.*s' must be an integer-like type (integer, boolean, enum, bit_set) or float, got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
			} else if (x.type == t_llvm_bool) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Invalid type passed to '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
			}
			i64 sz = type_size_of(x.type);
			if (sz < 2) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Type passed to '%.*s' must be at least 2 bytes, got %s with size of %lld", LIT(builtin_name), xts, sz);
				gb_string_free(xts);
			}

			operand->mode = Addressing_Value;
			operand->type = default_type(x.type);
		}
		break;

	case BuiltinProc_overflow_add:
	case BuiltinProc_overflow_sub:
	case BuiltinProc_overflow_mul:
		{
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]);
			check_expr(c, &y, ce->args[1]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (y.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &x, y.type);
			if (is_type_untyped(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected a typed integer for '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				return false;
			}
			if (!is_type_integer(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected an integer for '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				return false;
			}
			Type *ct = core_type(x.type);
			if (is_type_different_to_arch_endianness(ct)) {
				GB_ASSERT(ct->kind == Type_Basic);
				if (ct->Basic.flags & (BasicFlag_EndianLittle|BasicFlag_EndianBig)) {
					gbString xts = type_to_string(x.type);
					error(x.expr, "Expected an integer which does not specify the explicit endianness for '%.*s', got %s", LIT(builtin_name), xts);
					gb_string_free(xts);
					return false;
				}
			}

			operand->mode = Addressing_Value;
			operand->type = make_optional_ok_type(default_type(x.type));
		}
		break;

	case BuiltinProc_sqrt:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}

			Type *elem = core_array_type(x.type);
			if (!is_type_float(x.type) && !(is_type_simd_vector(x.type) && is_type_float(elem))) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected a floating point or #simd vector value for '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				return false;
			} else if (is_type_different_to_arch_endianness(elem)) {
				GB_ASSERT(elem->kind == Type_Basic);
				if (elem->Basic.flags & (BasicFlag_EndianLittle|BasicFlag_EndianBig)) {
					gbString xts = type_to_string(x.type);
					error(x.expr, "Expected a float which does not specify the explicit endianness for '%.*s', got %s", LIT(builtin_name), xts);
					gb_string_free(xts);
					return false;
				}
			}
			if (is_type_float(x.type) && x.mode == Addressing_Constant) {
				f64 v = exact_value_to_f64(x.value);

				operand->mode = Addressing_Constant;
				operand->type = x.type;
				operand->value = exact_value_float(gb_sqrt(v));
				break;
			}
			operand->mode = Addressing_Value;
			operand->type = default_type(x.type);
		}
		break;

	case BuiltinProc_fused_mul_add:
		{
			Operand x = {};
			Operand y = {};
			Operand z = {};
			check_expr(c, &x, ce->args[0]); if (x.mode == Addressing_Invalid) return false;
			check_expr(c, &y, ce->args[1]); if (y.mode == Addressing_Invalid) return false;
			check_expr(c, &z, ce->args[2]); if (z.mode == Addressing_Invalid) return false;

			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &x, y.type); if (x.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &z, x.type); if (z.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &x, z.type); if (x.mode == Addressing_Invalid) return false;
			if (is_type_untyped(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected a typed floating point value or #simd vector for '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				return false;
			}

			Type *elem = core_array_type(x.type);
			if (!is_type_float(x.type) && !(is_type_simd_vector(x.type) && is_type_float(elem))) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected a floating point or #simd vector value for '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				return false;
			}
			if (is_type_different_to_arch_endianness(elem)) {
				GB_ASSERT(elem->kind == Type_Basic);
				if (elem->Basic.flags & (BasicFlag_EndianLittle|BasicFlag_EndianBig)) {
					gbString xts = type_to_string(x.type);
					error(x.expr, "Expected a float which does not specify the explicit endianness for '%.*s', got %s", LIT(builtin_name), xts);
					gb_string_free(xts);
					return false;
				}
			}

			if (!are_types_identical(x.type, y.type) || !are_types_identical(y.type, z.type)) {
				gbString xts = type_to_string(x.type);
				gbString yts = type_to_string(y.type);
				gbString zts = type_to_string(z.type);
				error(x.expr, "Mismatched types for '%.*s', got %s vs %s vs %s", LIT(builtin_name), xts, yts, zts);
				gb_string_free(zts);
				gb_string_free(yts);
				gb_string_free(xts);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = default_type(x.type);
		}
		break;

	case BuiltinProc_mem_copy:
	case BuiltinProc_mem_copy_non_overlapping:
		{
			operand->mode = Addressing_NoValue;
			operand->type = t_invalid;

			Operand dst = {};
			Operand src = {};
			Operand len = {};
			check_expr(c, &dst, ce->args[0]);
			check_expr(c, &src, ce->args[1]);
			check_expr(c, &len, ce->args[2]);
			if (dst.mode == Addressing_Invalid) {
				return false;
			}
			if (src.mode == Addressing_Invalid) {
				return false;
			}
			if (len.mode == Addressing_Invalid) {
				return false;
			}


			if (!is_type_pointer(dst.type) && !is_type_multi_pointer(dst.type)) {
				gbString str = type_to_string(dst.type);
				error(dst.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_pointer(src.type) && !is_type_multi_pointer(src.type)) {
				gbString str = type_to_string(src.type);
				error(src.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_integer(len.type)) {
				gbString str = type_to_string(len.type);
				error(len.expr, "Expected an integer value for the number of bytes for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}

			if (len.mode == Addressing_Constant) {
				i64 n = exact_value_to_i64(len.value);
				if (n < 0) {
					gbString str = expr_to_string(len.expr);
					error(len.expr, "Expected a non-negative integer value for the number of bytes for '%.*s', got %s", LIT(builtin_name), str);
					gb_string_free(str);
				}
			}
		}
		break;

	case BuiltinProc_mem_zero:
	case BuiltinProc_mem_zero_volatile:
		{
			operand->mode = Addressing_NoValue;
			operand->type = t_invalid;

			Operand ptr = {};
			Operand len = {};
			check_expr(c, &ptr, ce->args[0]);
			check_expr(c, &len, ce->args[1]);
			if (ptr.mode == Addressing_Invalid) {
				return false;
			}
			if (len.mode == Addressing_Invalid) {
				return false;
			}


			if (!is_type_pointer(ptr.type) && !is_type_multi_pointer(ptr.type)) {
				gbString str = type_to_string(ptr.type);
				error(ptr.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_integer(len.type)) {
				gbString str = type_to_string(len.type);
				error(len.expr, "Expected an integer value for the number of bytes for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}

			if (len.mode == Addressing_Constant) {
				i64 n = exact_value_to_i64(len.value);
				if (n < 0) {
					gbString str = expr_to_string(len.expr);
					error(len.expr, "Expected a non-negative integer value for the number of bytes for '%.*s', got %s", LIT(builtin_name), str);
					gb_string_free(str);
				}
			}
		}
		break;

	case BuiltinProc_ptr_offset:
		{
			Operand ptr = {};
			Operand offset = {};
			check_expr(c, &ptr, ce->args[0]);
			check_expr(c, &offset, ce->args[1]);
			if (ptr.mode == Addressing_Invalid) {
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}
			if (offset.mode == Addressing_Invalid) {
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = ptr.type;

			if (!is_type_pointer(ptr.type)  && !is_type_multi_pointer(ptr.type)) {
				gbString str = type_to_string(ptr.type);
				error(ptr.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (are_types_identical(core_type(ptr.type), t_rawptr)) {
				gbString str = type_to_string(ptr.type);
				error(ptr.expr, "Expected a dereferenceable pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_integer(offset.type)) {
				gbString str = type_to_string(offset.type);
				error(offset.expr, "Expected an integer value for the offset parameter for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
		}
		break;
	case BuiltinProc_ptr_sub:
		{
			operand->mode = Addressing_NoValue;
			operand->type = t_invalid;

			Operand ptr0 = {};
			Operand ptr1 = {};
			check_expr(c, &ptr0, ce->args[0]);
			check_expr(c, &ptr1, ce->args[1]);
			if (ptr0.mode == Addressing_Invalid) {
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}
			if (ptr1.mode == Addressing_Invalid) {
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_int;

			if (!is_type_pointer(ptr0.type) && !is_type_multi_pointer(ptr0.type)) {
				gbString str = type_to_string(ptr0.type);
				error(ptr0.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (are_types_identical(core_type(ptr0.type), t_rawptr)) {
				gbString str = type_to_string(ptr0.type);
				error(ptr0.expr, "Expected a dereferenceable pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}

			if (!is_type_pointer(ptr1.type) && !is_type_multi_pointer(ptr1.type)) {
				gbString str = type_to_string(ptr1.type);
				error(ptr1.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (are_types_identical(core_type(ptr1.type), t_rawptr)) {
				gbString str = type_to_string(ptr1.type);
				error(ptr1.expr, "Expected a dereferenceable pointer value for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}

			if (!are_types_identical(ptr0.type, ptr1.type)) {
				gbString xts = type_to_string(ptr0.type);
				gbString yts = type_to_string(ptr1.type);
				error(ptr0.expr, "Mismatched types for '%.*s', %s vs %s", LIT(builtin_name), xts, yts);
				gb_string_free(yts);
				gb_string_free(xts);
				return false;
			}

			Type *elem = type_deref(ptr0.type);
			if (type_size_of(elem) == 0) {
				gbString str = type_to_string(ptr0.type);
				error(ptr0.expr, "Expected a pointer to a non-zero sized element for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
		}
		break;


	case BuiltinProc_atomic_type_is_lock_free:
		{
			Ast *expr = ce->args[0];
			Operand o = {};
			check_expr_or_type(c, &o, expr);

			if (o.mode == Addressing_Invalid || o.mode == Addressing_Builtin) {
				return false;
			}
			if (o.type == nullptr || o.type == t_invalid || is_type_asm_proc(o.type)) {
				error(o.expr, "Invalid argument to '%.*s'", LIT(builtin_name));
				return false;
			}
			if (is_type_polymorphic(o.type)) {
				error(o.expr, "'%.*s' of polymorphic type cannot be determined", LIT(builtin_name));
				return false;
			}
			if (is_type_untyped(o.type)) {
				error(o.expr, "'%.*s' of untyped type is not allowed", LIT(builtin_name));
				return false;
			}
			Type *t = o.type;
			bool is_lock_free = is_type_lock_free(t);

			operand->mode = Addressing_Constant;
			operand->type = t_untyped_bool;
			operand->value = exact_value_bool(is_lock_free);
			break;
		}

	case BuiltinProc_atomic_thread_fence:
	case BuiltinProc_atomic_signal_fence:
		{
			OdinAtomicMemoryOrder memory_order = {};
			if (!check_atomic_memory_order_argument(c, ce->args[0], builtin_name, &memory_order)) {
				return false;
			}
			switch (memory_order) {
			case OdinAtomicMemoryOrder_acquire:
			case OdinAtomicMemoryOrder_release:
			case OdinAtomicMemoryOrder_acq_rel:
			case OdinAtomicMemoryOrder_seq_cst:
				break;
			default:
				error(ce->args[0], "Illegal memory ordering for '%.*s', got .%s", LIT(builtin_name), OdinAtomicMemoryOrder_strings[memory_order]);
				break;
			}

			operand->mode = Addressing_NoValue;
		}
		break;

	case BuiltinProc_volatile_store:
	case BuiltinProc_unaligned_store:
	case BuiltinProc_non_temporal_store:
	case BuiltinProc_atomic_store:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (id == BuiltinProc_atomic_store && !check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}
			Operand x = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_assignment(c, &x, elem, builtin_name);

			operand->type = nullptr;
			operand->mode = Addressing_NoValue;
			break;
		}

	case BuiltinProc_atomic_store_explicit:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}
			Operand x = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_assignment(c, &x, elem, builtin_name);

			OdinAtomicMemoryOrder memory_order = {};
			if (!check_atomic_memory_order_argument(c, ce->args[2], builtin_name, &memory_order)) {
				return false;
			}
			switch (memory_order) {
			case OdinAtomicMemoryOrder_consume:
			case OdinAtomicMemoryOrder_acquire:
			case OdinAtomicMemoryOrder_acq_rel:
				error(ce->args[2], "Illegal memory order .%s for '%.*s'", OdinAtomicMemoryOrder_strings[memory_order], LIT(builtin_name));
				break;
			}

			operand->type = nullptr;
			operand->mode = Addressing_NoValue;
			break;
		}


	case BuiltinProc_volatile_load:
	case BuiltinProc_unaligned_load:
	case BuiltinProc_non_temporal_load:
	case BuiltinProc_atomic_load:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (id == BuiltinProc_atomic_load && !check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}

			operand->type = elem;
			operand->mode = Addressing_Value;
			break;
		}

	case BuiltinProc_atomic_load_explicit:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}

			OdinAtomicMemoryOrder memory_order = {};
			if (!check_atomic_memory_order_argument(c, ce->args[1], builtin_name, &memory_order)) {
				return false;
			}

			switch (memory_order) {
			case OdinAtomicMemoryOrder_release:
			case OdinAtomicMemoryOrder_acq_rel:
				error(ce->args[1], "Illegal memory order .%s for '%.*s'", OdinAtomicMemoryOrder_strings[memory_order], LIT(builtin_name));
				break;
			}

			operand->type = elem;
			operand->mode = Addressing_Value;
			break;
		}

	case BuiltinProc_atomic_add:
	case BuiltinProc_atomic_sub:
	case BuiltinProc_atomic_and:
	case BuiltinProc_atomic_nand:
	case BuiltinProc_atomic_or:
	case BuiltinProc_atomic_xor:
	case BuiltinProc_atomic_exchange:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}
			Operand x = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_assignment(c, &x, elem, builtin_name);

			Type *t = type_deref(operand->type);
			switch (id) {
			case BuiltinProc_atomic_add:
			case BuiltinProc_atomic_sub:
				if (!is_type_numeric(t)) {
					gbString str = type_to_string(t);
					error(operand->expr, "Expected a numeric type for '%.*s', got %s", LIT(builtin_name), str);
					gb_string_free(str);
				} else if (is_type_different_to_arch_endianness(t)) {
					gbString str = type_to_string(t);
					error(operand->expr, "Expected a numeric type of the same platform endianness for '%.*s', got %s", LIT(builtin_name), str);
					gb_string_free(str);
				}
			}

			operand->type = elem;
			operand->mode = Addressing_Value;
			break;
		}

	case BuiltinProc_atomic_add_explicit:
	case BuiltinProc_atomic_sub_explicit:
	case BuiltinProc_atomic_and_explicit:
	case BuiltinProc_atomic_nand_explicit:
	case BuiltinProc_atomic_or_explicit:
	case BuiltinProc_atomic_xor_explicit:
	case BuiltinProc_atomic_exchange_explicit:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}
			Operand x = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_assignment(c, &x, elem, builtin_name);


			if (!check_atomic_memory_order_argument(c, ce->args[2], builtin_name, nullptr)) {
				return false;
			}

			Type *t = type_deref(operand->type);
			switch (id) {
			case BuiltinProc_atomic_add_explicit:
			case BuiltinProc_atomic_sub_explicit:
				if (!is_type_numeric(t)) {
					gbString str = type_to_string(t);
					error(operand->expr, "Expected a numeric type for '%.*s', got %s", LIT(builtin_name), str);
					gb_string_free(str);
				} else if (is_type_different_to_arch_endianness(t)) {
					gbString str = type_to_string(t);
					error(operand->expr, "Expected a numeric type of the same platform endianness for '%.*s', got %s", LIT(builtin_name), str);
					gb_string_free(str);
				}
				break;
			}

			operand->type = elem;
			operand->mode = Addressing_Value;
			break;
		}

	case BuiltinProc_atomic_compare_exchange_strong:
	case BuiltinProc_atomic_compare_exchange_weak:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}
			Operand x = {};
			Operand y = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_expr_with_type_hint(c, &y, ce->args[2], elem);
			check_assignment(c, &x, elem, builtin_name);
			check_assignment(c, &y, elem, builtin_name);

			Type *t = type_deref(operand->type);
			if (!is_type_comparable(t)) {
				gbString str = type_to_string(t);
				error(operand->expr, "Expected a comparable type for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
			}

			operand->mode = Addressing_OptionalOk;
			operand->type = elem;
			break;
		}

	case BuiltinProc_atomic_compare_exchange_strong_explicit:
	case BuiltinProc_atomic_compare_exchange_weak_explicit:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!check_atomic_ptr_argument(operand, builtin_name, elem)) {
				return false;
			}
			Operand x = {};
			Operand y = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_expr_with_type_hint(c, &y, ce->args[2], elem);
			check_assignment(c, &x, elem, builtin_name);
			check_assignment(c, &y, elem, builtin_name);

			OdinAtomicMemoryOrder success_memory_order = {};
			OdinAtomicMemoryOrder failure_memory_order = {};
			if (!check_atomic_memory_order_argument(c, ce->args[3], builtin_name, &success_memory_order, "success ordering")) {
				return false;
			}
			if (!check_atomic_memory_order_argument(c, ce->args[4], builtin_name, &failure_memory_order, "failure ordering")) {
				return false;
			}

			Type *t = type_deref(operand->type);
			if (!is_type_comparable(t)) {
				gbString str = type_to_string(t);
				error(operand->expr, "Expected a comparable type for '%.*s', got %s", LIT(builtin_name), str);
				gb_string_free(str);
			}

			bool invalid_combination = false;

			switch (success_memory_order) {
			case OdinAtomicMemoryOrder_relaxed:
			case OdinAtomicMemoryOrder_release:
				if (failure_memory_order != OdinAtomicMemoryOrder_relaxed) {
					invalid_combination = true;
				}
				break;
			case OdinAtomicMemoryOrder_consume:
				switch (failure_memory_order) {
				case OdinAtomicMemoryOrder_relaxed:
				case OdinAtomicMemoryOrder_consume:
					break;
				default:
					invalid_combination = true;
					break;
				}
				break;
			case OdinAtomicMemoryOrder_acquire:
			case OdinAtomicMemoryOrder_acq_rel:
				switch (failure_memory_order) {
				case OdinAtomicMemoryOrder_relaxed:
				case OdinAtomicMemoryOrder_consume:
				case OdinAtomicMemoryOrder_acquire:
					break;
				default:
					invalid_combination = true;
					break;
				}
				break;
			case OdinAtomicMemoryOrder_seq_cst:
				switch (failure_memory_order) {
				case OdinAtomicMemoryOrder_relaxed:
				case OdinAtomicMemoryOrder_consume:
				case OdinAtomicMemoryOrder_acquire:
				case OdinAtomicMemoryOrder_seq_cst:
					break;
				default:
					invalid_combination = true;
					break;
				}
				break;
			default:
				invalid_combination = true;
				break;
			}


			if (invalid_combination) {
				error(ce->args[3], "Illegal memory order pairing for '%.*s', success = .%s, failure = .%s",
					LIT(builtin_name),
					OdinAtomicMemoryOrder_strings[success_memory_order],
					OdinAtomicMemoryOrder_strings[failure_memory_order]
				);
			}

			operand->mode = Addressing_OptionalOk;
			operand->type = elem;
			break;
		}

	case BuiltinProc_fixed_point_mul:
	case BuiltinProc_fixed_point_div:
	case BuiltinProc_fixed_point_mul_sat:
	case BuiltinProc_fixed_point_div_sat:
		{
			Operand x = {};
			Operand y = {};
			Operand z = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			check_expr(c, &y, ce->args[1]);
			if (y.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &x, y.type);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xts = type_to_string(x.type);
				gbString yts = type_to_string(y.type);
				error(x.expr, "Mismatched types for '%.*s', %s vs %s", LIT(builtin_name), xts, yts);
				gb_string_free(yts);
				gb_string_free(xts);
				return false;
			}

			if (!is_type_integer(x.type) || is_type_untyped(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected an integer type for '%.*s', got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				return false;
			}

			check_expr(c, &z, ce->args[2]);
			if (z.mode == Addressing_Invalid) {
				return false;
			}
			if (z.mode != Addressing_Constant || !is_type_integer(z.type)) {
				error(z.expr, "Expected a constant integer for the scale in '%.*s'", LIT(builtin_name));
				return false;
			}
			i64 n = exact_value_to_i64(z.value);
			if (n <= 0) {
				error(z.expr, "Scale parameter in '%.*s' must be positive, got %lld", LIT(builtin_name), n);
				return false;
			}
			i64 sz = 8*type_size_of(x.type);
			if (n > sz) {
				error(z.expr, "Scale parameter in '%.*s' is larger than the base integer bit width, got %lld, expected a maximum of %lld", LIT(builtin_name), n, sz);
				return false;
			}

			operand->type = x.type;
			operand->mode = Addressing_Value;
		}
		break;


	case BuiltinProc_expect:
		{
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]);
			check_expr(c, &y, ce->args[1]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (y.mode == Addressing_Invalid) {
				return false;
			}
			convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &x, y.type);
			if (!are_types_identical(x.type, y.type)) {
				gbString xts = type_to_string(x.type);
				gbString yts = type_to_string(y.type);
				error(x.expr, "Mismatched types for '%.*s', %s vs %s", LIT(builtin_name), xts, yts);
				gb_string_free(yts);
				gb_string_free(xts);
				*operand = x; // minimize error propagation
				return true;
			}

			if (!is_type_integer_like(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Values passed to '%.*s' must be an integer-like type (integer, boolean, enum, bit_set), got %s", LIT(builtin_name), xts);
				gb_string_free(xts);
				*operand = x;
				return true;
			}

			if (y.mode != Addressing_Constant) {
				error(y.expr, "Second argument to '%.*s' must be constant as it is the expected value", LIT(builtin_name));
			}

			if (x.mode == Addressing_Constant) {
				// NOTE(bill): just completely ignore this intrinsic entirely
				*operand = x;
				return true;
			}

			operand->mode = Addressing_Value;
			operand->type = x.type;
		}
		break;
		
	case BuiltinProc_prefetch_read_instruction:
	case BuiltinProc_prefetch_read_data:
	case BuiltinProc_prefetch_write_instruction:
	case BuiltinProc_prefetch_write_data:
		{
			operand->mode = Addressing_NoValue;
			operand->type = nullptr;
			
			Operand x = {};
			Operand y = {};
			check_expr(c, &x, ce->args[0]);
			check_expr(c, &y, ce->args[1]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (y.mode == Addressing_Invalid) {
				return false;
			}
			check_assignment(c, &x, t_rawptr, builtin_name);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (y.mode != Addressing_Constant && is_type_integer(y.type)) {
				error(y.expr, "Second argument to '%.*s' representing the locality must be an integer in the range 0..=3", LIT(builtin_name));
				return false;
			}
			i64 locality = exact_value_to_i64(y.value);
			if (!(0 <= locality && locality <= 3)) {
				error(y.expr, "Second argument to '%.*s' representing the locality must be an integer in the range 0..=3", LIT(builtin_name));
				return false;
			}
			
		}
		break;
		
	case BuiltinProc_syscall:
		{
			convert_to_typed(c, operand, t_uintptr);
			if (!is_type_uintptr(operand->type)) {
				gbString t = type_to_string(operand->type);
				error(operand->expr, "Argument 0 must be of type 'uintptr', got %s", t);
				gb_string_free(t);
			}
			for (isize i = 1; i < ce->args.count; i++) {
				Operand x = {};
				check_expr(c, &x, ce->args[i]);
				if (x.mode != Addressing_Invalid) {
					convert_to_typed(c, &x, t_uintptr);	
				}
				convert_to_typed(c, &x, t_uintptr);
				if (!is_type_uintptr(x.type)) {
					gbString t = type_to_string(x.type);
					error(x.expr, "Argument %td must be of type 'uintptr', got %s", i, t);
					gb_string_free(t);
				}
			}
			
			isize max_arg_count = 32;
			
			switch (build_context.metrics.os) {
			case TargetOs_windows:
			case TargetOs_freestanding:
				error(call, "'%.*s' is not supported on this platform (%.*s)", LIT(builtin_name), LIT(target_os_names[build_context.metrics.os]));
				break;
			case TargetOs_darwin:
			case TargetOs_linux:
			case TargetOs_essence:
			case TargetOs_freebsd:
			case TargetOs_openbsd:
			case TargetOs_haiku:
				switch (build_context.metrics.arch) {
				case TargetArch_i386:
				case TargetArch_amd64:
				case TargetArch_arm64:
					max_arg_count = 7;
					break;
				}
				break;
			}
			
			if (ce->args.count > max_arg_count) {
				error(ast_end_token(call), "'%.*s' has a maximum of %td arguments on this platform (%.*s), got %td", LIT(builtin_name), max_arg_count, LIT(target_os_names[build_context.metrics.os]), ce->args.count);
			}
			
			
			
			operand->mode = Addressing_Value;
			operand->type = t_uintptr;
			return true;
		}
		break;


	case BuiltinProc_type_base_type:
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
		} else {
			operand->type = base_type(operand->type);
		}
		operand->mode = Addressing_Type;
		break;
	case BuiltinProc_type_core_type:
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
		} else {
			operand->type = core_type(operand->type);
		}
		operand->mode = Addressing_Type;
		break;
	case BuiltinProc_type_elem_type:
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
		} else {
			Type *bt = base_type(operand->type);
			switch (bt->kind) {
			case Type_Basic:
				switch (bt->Basic.kind) {
				case Basic_complex32:  operand->type = t_f16; break;
				case Basic_complex64:  operand->type = t_f32; break;
				case Basic_complex128: operand->type = t_f64; break;
				case Basic_quaternion64:  operand->type = t_f16; break;
				case Basic_quaternion128: operand->type = t_f32; break;
				case Basic_quaternion256: operand->type = t_f64; break;
				}
				break;
			case Type_Pointer:         operand->type = bt->Pointer.elem;         break;
			case Type_Array:           operand->type = bt->Array.elem;           break;
			case Type_EnumeratedArray: operand->type = bt->EnumeratedArray.elem; break;
			case Type_Slice:           operand->type = bt->Slice.elem;           break;
			case Type_DynamicArray:    operand->type = bt->DynamicArray.elem;    break;
			}
		}
		operand->mode = Addressing_Type;
		break;

	case BuiltinProc_type_convert_variants_to_pointers:
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
		} else {
			Type *bt = base_type(operand->type);
			if (is_type_polymorphic(bt)) {
				// IGNORE polymorphic types
				return true;
			} else if (bt->kind != Type_Union) {
				gbString t = type_to_string(operand->type);
				error(operand->expr, "Expected a union type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);

				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			} else if (bt->Union.is_polymorphic) {
				gbString t = type_to_string(operand->type);
				error(operand->expr, "Expected a non-polymorphic union type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);

				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *new_type = alloc_type_union();
			auto variants = slice_make<Type *>(permanent_allocator(), bt->Union.variants.count);
			for_array(i, bt->Union.variants) {
				variants[i] = alloc_type_pointer(bt->Union.variants[i]);
			}
			new_type->Union.variants = variants;

			// NOTE(bill): Is this even correct?
			new_type->Union.node = operand->expr;
			new_type->Union.scope = bt->Union.scope;

			operand->type = new_type;
		}
		operand->mode = Addressing_Type;
		break;
	case BuiltinProc_type_merge:
		{
			operand->mode = Addressing_Type;
			operand->type = t_invalid;

			Operand x = {};
			Operand y = {};
			check_expr_or_type(c, &x, ce->args[0]);
			check_expr_or_type(c, &y, ce->args[1]);
			if (x.mode != Addressing_Type) {
				error(x.expr, "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (y.mode != Addressing_Type) {
				error(y.expr, "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}

			if (is_type_polymorphic(x.type)) {
				gbString t = type_to_string(x.type);
				error(x.expr, "Expected a non-polymorphic type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
			if (is_type_polymorphic(y.type)) {
				gbString t = type_to_string(y.type);
				error(y.expr, "Expected a non-polymorphic type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
			if (!is_type_union(x.type)) {
				gbString t = type_to_string(x.type);
				error(x.expr, "Expected a union type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
			if (!is_type_union(y.type)) {
				gbString t = type_to_string(y.type);
				error(x.expr, "Expected a union type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}
			Type *ux = base_type(x.type);
			Type *uy = base_type(y.type);
			GB_ASSERT(ux->kind == Type_Union);
			GB_ASSERT(uy->kind == Type_Union);

			i64 custom_align = gb_max(ux->Union.custom_align, uy->Union.custom_align);
			if (ux->Union.kind != uy->Union.kind) {
				error(x.expr, "Union kinds must match, got %s vs %s", union_type_kind_strings[ux->Union.kind], union_type_kind_strings[uy->Union.kind]);
			}

			Type *merged_union = alloc_type_union();

			merged_union->Union.node = call;
			merged_union->Union.scope = create_scope(c->info, c->scope);
			merged_union->Union.kind = ux->Union.kind;
			merged_union->Union.custom_align = custom_align;

			auto variants = array_make<Type *>(permanent_allocator(), 0, ux->Union.variants.count+uy->Union.variants.count);
			for (Type *t : ux->Union.variants) {
				array_add(&variants, t);
			}
			for (Type *t : uy->Union.variants) {
				bool ok = true;
				for (Type *other_t : ux->Union.variants) {
					if (are_types_identical(other_t, t)) {
						ok = false;
						break;
					}
				}
				if (ok) {
					array_add(&variants, t);
				}

			}
			merged_union->Union.variants = slice_from_array(variants);

			operand->mode = Addressing_Type;
			operand->type = merged_union;
		}
		break;


	case BuiltinProc_type_is_boolean:
	case BuiltinProc_type_is_integer:
	case BuiltinProc_type_is_rune:
	case BuiltinProc_type_is_float:
	case BuiltinProc_type_is_complex:
	case BuiltinProc_type_is_quaternion:
	case BuiltinProc_type_is_string:
	case BuiltinProc_type_is_typeid:
	case BuiltinProc_type_is_any:
	case BuiltinProc_type_is_endian_platform:
	case BuiltinProc_type_is_endian_little:
	case BuiltinProc_type_is_endian_big:
	case BuiltinProc_type_is_unsigned:
	case BuiltinProc_type_is_numeric:
	case BuiltinProc_type_is_ordered:
	case BuiltinProc_type_is_ordered_numeric:
	case BuiltinProc_type_is_indexable:
	case BuiltinProc_type_is_sliceable:
	case BuiltinProc_type_is_comparable:
	case BuiltinProc_type_is_simple_compare:
	case BuiltinProc_type_is_dereferenceable:
	case BuiltinProc_type_is_valid_map_key:
	case BuiltinProc_type_is_valid_matrix_elements:
	case BuiltinProc_type_is_named:
	case BuiltinProc_type_is_pointer:
	case BuiltinProc_type_is_multi_pointer:
	case BuiltinProc_type_is_array:
	case BuiltinProc_type_is_enumerated_array:
	case BuiltinProc_type_is_slice:
	case BuiltinProc_type_is_dynamic_array:
	case BuiltinProc_type_is_map:
	case BuiltinProc_type_is_struct:
	case BuiltinProc_type_is_union:
	case BuiltinProc_type_is_enum:
	case BuiltinProc_type_is_proc:
	case BuiltinProc_type_is_bit_set:
	case BuiltinProc_type_is_simd_vector:
	case BuiltinProc_type_is_matrix:
	case BuiltinProc_type_is_specialized_polymorphic_record:
	case BuiltinProc_type_is_unspecialized_polymorphic_record:
	case BuiltinProc_type_has_nil:
		GB_ASSERT(BuiltinProc__type_simple_boolean_begin < id && id < BuiltinProc__type_simple_boolean_end);

		operand->value = exact_value_bool(false);
		if (operand->mode != Addressing_Type) {
			gbString str = expr_to_string(ce->args[0]);
			error(operand->expr, "Expected a type for '%.*s', got '%s'", LIT(builtin_name), str);
			gb_string_free(str);
		} else {
			i32 i = id - cast(i32)BuiltinProc__type_simple_boolean_begin;
			auto procedure = builtin_type_is_procs[i];
			GB_ASSERT_MSG(procedure != nullptr, "%.*s", LIT(builtin_name));
			bool ok = procedure(operand->type);
			operand->value = exact_value_bool(ok);
		}
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_bool;
		break;

	case BuiltinProc_type_has_field:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			Operand x = {};
			check_expr(c, &x, ce->args[1]);

			if (!is_type_string(x.type) || x.mode != Addressing_Constant || x.value.kind != ExactValue_String) {
				error(ce->args[1], "Expected a const string for field argument");
				return false;
			}

			String field_name = x.value.value_string;

			Selection sel = lookup_field(type, field_name, false);
			operand->mode = Addressing_Constant;
			operand->value = exact_value_bool(sel.index.count != 0);
			operand->type = t_untyped_bool;

			break;
		}
		break;
	case BuiltinProc_type_field_type:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			Operand x = {};
			check_expr(c, &x, ce->args[1]);

			if (!is_type_string(x.type) || x.mode != Addressing_Constant || x.value.kind != ExactValue_String) {
				error(ce->args[1], "Expected a const string for field argument");
				return false;
			}

			String field_name = x.value.value_string;

			Selection sel = lookup_field(type, field_name, false);
			if (sel.index.count == 0) {
				gbString t = type_to_string(type);
				error(ce->args[1], "'%.*s' is not a field of type %s", LIT(field_name), t);
				gb_string_free(t);
				return false;
			}
			operand->mode = Addressing_Type;
			operand->type = sel.entity->type;
			break;
		}
		break;

	case BuiltinProc_type_is_specialization_of:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}
			Type *t = operand->type;
			Type *s = nullptr;

			bool prev_ips = c->in_polymorphic_specialization;
			c->in_polymorphic_specialization = true;
			s = check_type(c, ce->args[1]);
			c->in_polymorphic_specialization = prev_ips;

			if (s == t_invalid) {
				error(ce->args[1], "Invalid specialization type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			operand->mode = Addressing_Constant;
			operand->type = t_untyped_bool;
			operand->value = exact_value_bool(check_type_specialization_to(c, s, t, false, false));

		}
		break;

	case BuiltinProc_type_is_variant_of:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}


			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *v = check_type(c, ce->args[1]);

			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);

			bool is_variant = false;

			for (Type *vt : u->Union.variants) {
				if (are_types_identical(v, vt)) {
					is_variant = true;
					break;
				}
			}

			operand->mode = Addressing_Constant;
			operand->type = t_untyped_bool;
			operand->value = exact_value_bool(is_variant);
		}
		break;

	case BuiltinProc_type_union_tag_type:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);
			
			operand->mode = Addressing_Type;
			operand->type = union_tag_type(u);
		}
		break;

	case BuiltinProc_type_union_tag_offset:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);
			
			// NOTE(jakubtomsu): forces calculation of variant_block_size
			type_size_of(u);
			i64 tag_offset = u->Union.variant_block_size;
			GB_ASSERT(tag_offset > 0);
			
			operand->mode = Addressing_Constant;
			operand->type = t_untyped_integer;
			operand->value = exact_value_i64(tag_offset);
		}
		break;

	case BuiltinProc_type_union_base_tag_value:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);
			
			operand->mode = Addressing_Constant;
			operand->type = t_untyped_integer;
			operand->value = exact_value_i64(u->Union.kind == UnionType_no_nil ? 0 : 1);
		} break;

	case BuiltinProc_type_bit_set_elem_type:
		{

			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *bs = operand->type;

			if (!is_type_bit_set(bs)) {
				error(operand->expr, "Expected a bit_set type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			bs = base_type(bs);
			GB_ASSERT(bs->kind == Type_BitSet);

			operand->mode = Addressing_Type;
			operand->type = bs->BitSet.elem;
		} break;

	case BuiltinProc_type_bit_set_underlying_type:
		{

			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *bs = operand->type;

			if (!is_type_bit_set(bs)) {
				error(operand->expr, "Expected a bit_set type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			bs = base_type(bs);
			GB_ASSERT(bs->kind == Type_BitSet);

			operand->mode = Addressing_Type;
			operand->type = bit_set_to_int(bs);
		} break;

	case BuiltinProc_type_union_variant_count:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);
			
			operand->mode = Addressing_Constant;
			operand->type = t_untyped_integer;
			operand->value = exact_value_i64(u->Union.variants.count);
		} break;

	case BuiltinProc_type_variant_type_of:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);
			Operand x = {};
			check_expr_or_type(c, &x, ce->args[1]);
			if (!is_type_integer(x.type) || x.mode != Addressing_Constant) {
				error(call, "Expected a constant integer for '%.*s", LIT(builtin_name));
				operand->mode = Addressing_Type;
				operand->type = t_invalid;
				return false;
			}
			
			i64 index = big_int_to_i64(&x.value.value_integer);
			if (index < 0 || index >= u->Union.variants.count) {
				error(call, "Variant tag out of bounds index for '%.*s", LIT(builtin_name));
				operand->mode = Addressing_Type;
				operand->type = t_invalid;
				return false;
			}

			operand->mode = Addressing_Type;
			operand->type = u->Union.variants[index];
		}
		break;
	
	case BuiltinProc_type_variant_index_of:
		{
			if (operand->mode != Addressing_Type) {
				error(operand->expr, "Expected a type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *u = operand->type;

			if (!is_type_union(u)) {
				error(operand->expr, "Expected a union type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}

			Type *v = check_type(c, ce->args[1]);
			u = base_type(u);
			GB_ASSERT(u->kind == Type_Union);

			i64 index = -1;			
			for_array(i, u->Union.variants) {
				Type *vt = u->Union.variants[i];
				if (union_variant_index_types_equal(v, vt)) {
					index = i64(i);
					break;
				}
			}
			
			if (index < 0) {
				error(operand->expr, "Expected a variant type for '%.*s'", LIT(builtin_name));
				operand->mode = Addressing_Invalid;
				operand->type = t_invalid;
				return false;
			}
			
			operand->mode = Addressing_Constant;
			operand->type = t_untyped_integer;
			operand->value = exact_value_i64(index);
		}
		break;

	case BuiltinProc_type_struct_field_count:
		operand->value = exact_value_i64(0);
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a struct type for '%.*s'", LIT(builtin_name));
		} else if (!is_type_struct(operand->type)) {
			error(operand->expr, "Expected a struct type for '%.*s'", LIT(builtin_name));
		} else {
			Type *bt = base_type(operand->type);
			operand->value = exact_value_i64(bt->Struct.fields.count);
		}
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_integer;
		break;

	case BuiltinProc_type_proc_parameter_count:
		operand->value = exact_value_i64(0);
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a procedure type for '%.*s'", LIT(builtin_name));
		} else if (!is_type_proc(operand->type)) {
			error(operand->expr, "Expected a procedure type for '%.*s'", LIT(builtin_name));
		} else {
			Type *bt = base_type(operand->type);
			operand->value = exact_value_i64(bt->Proc.param_count);
		}
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_integer;
		break;
	case BuiltinProc_type_proc_return_count:
		operand->value = exact_value_i64(0);
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a procedure type for '%.*s'", LIT(builtin_name));
		} else if (!is_type_proc(operand->type)) {
			error(operand->expr, "Expected a procedure type for '%.*s'", LIT(builtin_name));
		} else {
			Type *bt = base_type(operand->type);
			operand->value = exact_value_i64(bt->Proc.result_count);
		}
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_integer;
		break;

	case BuiltinProc_type_proc_parameter_type:
		if (operand->mode != Addressing_Type || !is_type_proc(operand->type)) {
			error(operand->expr, "Expected a procedure type for '%.*s'", LIT(builtin_name));
			return false;
		} else {
			if (is_type_polymorphic(operand->type)) {
				error(operand->expr, "Expected a non-polymorphic procedure type for '%.*s'", LIT(builtin_name));
				return false;
			}

			Operand op = {};
			check_expr(c, &op, ce->args[1]);
			if (op.mode != Addressing_Constant || !is_type_integer(op.type)) {
				error(op.expr, "Expected a constant integer for the index of procedure parameter value");
				return false;
			}

			i64 index = exact_value_to_i64(op.value);
			if (index < 0) {
				error(op.expr, "Expected a non-negative integer for the index of procedure parameter value, got %lld", cast(long long)index);
				return false;
			}

			Entity *param = nullptr;
			i64 count = 0;

			Type *bt = base_type(operand->type);
			if (bt->kind == Type_Proc) {
				count = bt->Proc.param_count;
				if (index < count) {
					param = bt->Proc.params->Tuple.variables[cast(isize)index];
				}
			}

			if (index >= count) {
				error(op.expr, "Index of procedure parameter value out of bounds, expected 0..<%lld, got %lld", cast(long long)count, cast(long long)index);
				return false;
			}
			GB_ASSERT(param != nullptr);
			switch (param->kind) {
			case Entity_Constant:
				operand->mode = Addressing_Constant;
				operand->type = param->type;
				operand->value = param->Constant.value;
				break;
			case Entity_TypeName:
			case Entity_Variable:
				operand->mode = Addressing_Type;
				operand->type = param->type;
				break;
			default:
				GB_PANIC("Unhandled procedure entity type %d", param->kind);
				break;
			}

		}

		break;

	case BuiltinProc_type_proc_return_type:
		if (operand->mode != Addressing_Type || !is_type_proc(operand->type)) {
			error(operand->expr, "Expected a procedure type for '%.*s'", LIT(builtin_name));
			return false;
		} else {
			if (is_type_polymorphic(operand->type)) {
				error(operand->expr, "Expected a non-polymorphic procedure type for '%.*s'", LIT(builtin_name));
				return false;
			}

			Operand op = {};
			check_expr(c, &op, ce->args[1]);
			if (op.mode != Addressing_Constant || !is_type_integer(op.type)) {
				error(op.expr, "Expected a constant integer for the index of procedure parameter value");
				return false;
			}

			i64 index = exact_value_to_i64(op.value);
			if (index < 0) {
				error(op.expr, "Expected a non-negative integer for the index of procedure parameter value, got %lld", cast(long long)index);
				return false;
			}

			Entity *param = nullptr;
			i64 count = 0;

			Type *bt = base_type(operand->type);
			if (bt->kind == Type_Proc) {
				count = bt->Proc.result_count;
				if (index < count) {
					param = bt->Proc.results->Tuple.variables[cast(isize)index];
				}
			}

			if (index >= count) {
				error(op.expr, "Index of procedure parameter value out of bounds, expected 0..<%lld, got %lld", cast(long long)count, cast(long long)index);
				return false;
			}
			GB_ASSERT(param != nullptr);
			switch (param->kind) {
			case Entity_Constant:
				operand->mode = Addressing_Constant;
				operand->type = param->type;
				operand->value = param->Constant.value;
				break;
			case Entity_TypeName:
			case Entity_Variable:
				operand->mode = Addressing_Type;
				operand->type = param->type;
				break;
			default:
				GB_PANIC("Unhandled procedure entity type %d", param->kind);
				break;
			}

		}

		break;

	case BuiltinProc_type_polymorphic_record_parameter_count:
		operand->value = exact_value_i64(0);
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a record type for '%.*s'", LIT(builtin_name));
		} else {
			Type *bt = base_type(operand->type);
			if (bt->kind == Type_Struct) {
				if (bt->Struct.polymorphic_params != nullptr) {
					operand->value = exact_value_i64(bt->Struct.polymorphic_params->Tuple.variables.count);
				}
			} else if (bt->kind == Type_Union) {
				if (bt->Union.polymorphic_params != nullptr) {
					operand->value = exact_value_i64(bt->Union.polymorphic_params->Tuple.variables.count);
				}
			} else {
				error(operand->expr, "Expected a record type for '%.*s'", LIT(builtin_name));
			}
		}
		operand->mode = Addressing_Constant;
		operand->type = t_untyped_integer;
		break;
	case BuiltinProc_type_polymorphic_record_parameter_value:
		if (operand->mode != Addressing_Type) {
			error(operand->expr, "Expected a record type for '%.*s'", LIT(builtin_name));
			return false;
		} else if (!is_type_polymorphic_record_specialized(operand->type)) {
			error(operand->expr, "Expected a specialized polymorphic record type for '%.*s'", LIT(builtin_name));
			return false;
		} else {
			Operand op = {};
			check_expr(c, &op, ce->args[1]);
			if (op.mode != Addressing_Constant || !is_type_integer(op.type)) {
				error(op.expr, "Expected a constant integer for the index of record parameter value");
				return false;
			}

			i64 index = exact_value_to_i64(op.value);
			if (index < 0) {
				error(op.expr, "Expected a non-negative integer for the index of record parameter value, got %lld", cast(long long)index);
				return false;
			}

			Entity *param = nullptr;
			i64 count = 0;

			Type *bt = base_type(operand->type);
			if (bt->kind == Type_Struct) {
				if (bt->Struct.polymorphic_params != nullptr) {
					count = bt->Struct.polymorphic_params->Tuple.variables.count;
					if (index < count) {
						param = bt->Struct.polymorphic_params->Tuple.variables[cast(isize)index];
					}
				}
			} else if (bt->kind == Type_Union) {
				if (bt->Union.polymorphic_params != nullptr) {
					count = bt->Union.polymorphic_params->Tuple.variables.count;
					if (index < count) {
						param = bt->Union.polymorphic_params->Tuple.variables[cast(isize)index];
					}
				}
			} else {
				error(operand->expr, "Expected a specialized polymorphic record type for '%.*s'", LIT(builtin_name));
				return false;
			}

			if (index >= count) {
				error(op.expr, "Index of record parameter value out of bounds, expected 0..<%lld, got %lld", cast(long long)count, cast(long long)index);
				return false;
			}
			GB_ASSERT(param != nullptr);
			switch (param->kind) {
			case Entity_Constant:
				operand->mode = Addressing_Constant;
				operand->type = param->type;
				operand->value = param->Constant.value;
				break;
			case Entity_TypeName:
				operand->mode = Addressing_Type;
				operand->type = param->type;
				break;
			default:
				GB_PANIC("Unhandled polymorphic record type");
				break;
			}

		}

		break;

	case BuiltinProc_type_is_subtype_of:
		{
			Operand op_src = {};
			Operand op_dst = {};

			check_expr_or_type(c, &op_src, ce->args[0]);
			if (op_src.mode != Addressing_Type) {
				gbString e = expr_to_string(op_src.expr);
				error(op_src.expr, "'%.*s' expects a type, got %s", LIT(builtin_name), e);
				gb_string_free(e);
				return false;
			}
			check_expr_or_type(c, &op_dst, ce->args[1]);
			if (op_dst.mode != Addressing_Type) {
				gbString e = expr_to_string(op_dst.expr);
				error(op_dst.expr, "'%.*s' expects a type, got %s", LIT(builtin_name), e);
				gb_string_free(e);
				return false;
			}

			operand->value = exact_value_bool(is_type_subtype_of_and_allow_polymorphic(op_src.type, op_dst.type));
			operand->mode = Addressing_Constant;
			operand->type = t_untyped_bool;
		} break;

	case BuiltinProc_type_field_index_of:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			Operand x = {};
			check_expr(c, &x, ce->args[1]);

			if (!is_type_string(x.type) || x.mode != Addressing_Constant || x.value.kind != ExactValue_String) {
				error(ce->args[1], "Expected a const string for field argument");
				return false;
			}

			String field_name = x.value.value_string;

			Selection sel = lookup_field(type, field_name, false);
			if (sel.entity == nullptr) {
				ERROR_BLOCK();
				gbString type_str = type_to_string(bt);
				error(ce->args[0],
				      "'%s' has no field named '%.*s'", type_str, LIT(field_name));
				gb_string_free(type_str);

				if (bt->kind == Type_Struct) {
					check_did_you_mean_type(field_name, bt->Struct.fields);
				}
				return false;
			}
			if (sel.indirect) {
				gbString type_str = type_to_string(bt);
				error(ce->args[0],
				      "Field '%.*s' is embedded via a pointer in '%s'", LIT(field_name), type_str);
				gb_string_free(type_str);
				return false;
			}

			operand->mode = Addressing_Constant;
			operand->value = exact_value_u64(sel.index[0]);
			operand->type = t_uintptr;
			break;
		}
		break;

	case BuiltinProc_type_bit_set_backing_type:
		{
			Operand op = {};
			Type *type = check_type(c, ce->args[0]);
			Type *bt = base_type(type);
			if (bt == nullptr || bt == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (bt->kind != Type_BitSet) {
				gbString s = type_to_string(type);
				error(ce->args[0], "Expected a bit_set type for '%.*s', got %s", LIT(builtin_name), s);
				return false;
			}

			operand->mode = Addressing_Type;
			operand->type = bit_set_to_int(bt);
			break;
		}

	case BuiltinProc_type_equal_proc:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!is_type_comparable(type)) {
				gbString t = type_to_string(type);
				error(ce->args[0], "Expected a comparable type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_equal_proc;
			break;
		}

	case BuiltinProc_type_hasher_proc:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!is_type_valid_for_keys(type)) {
				gbString t = type_to_string(type);
				error(ce->args[0], "Expected a valid type for map keys for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}

			add_map_key_type_dependencies(c, type);

			operand->mode = Addressing_Value;
			operand->type = t_hasher_proc;
			break;
		}

	case BuiltinProc_type_map_info:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}
			if (!is_type_map(type)) {
				gbString t = type_to_string(type);
				error(ce->args[0], "Expected a map type for '%.*s', got %s", LIT(builtin_name), t);
				gb_string_free(t);
				return false;
			}

			add_map_key_type_dependencies(c, type);

			operand->mode = Addressing_Value;
			operand->type = t_map_info_ptr;
			break;
		}
	case BuiltinProc_type_map_cell_info:
		{
			Operand op = {};
			Type *bt = check_type(c, ce->args[0]);
			Type *type = base_type(bt);
			if (type == nullptr || type == t_invalid) {
				error(ce->args[0], "Expected a type for '%.*s'", LIT(builtin_name));
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_map_cell_info_ptr;
			break;
		}

	case BuiltinProc_constant_utf16_cstring:
		{
			String value = {};
			if (!is_constant_string(c, builtin_name, ce->args[0], &value)) {
				return false;
			}
			operand->mode = Addressing_Value;
			operand->type = alloc_type_multi_pointer(t_u16);
			operand->value = {};
			break;
		}


	case BuiltinProc_wasm_memory_grow:
		{
			if (!is_arch_wasm()) {
				error(call, "'%.*s' is only allowed on wasm targets", LIT(builtin_name));
				return false;
			}

			Operand index = {};
			Operand delta = {};
			check_expr(c, &index, ce->args[0]); if (index.mode == Addressing_Invalid) return false;
			check_expr(c, &delta, ce->args[1]); if (delta.mode == Addressing_Invalid) return false;

			convert_to_typed(c, &index, t_uintptr); if (index.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &delta, t_uintptr); if (delta.mode == Addressing_Invalid) return false;

			if (!is_operand_value(index) || !check_is_assignable_to(c, &index, t_uintptr)) {
				gbString e = expr_to_string(index.expr);
				gbString t = type_to_string(index.type);
				error(index.expr, "'%.*s' expected a uintptr for the memory index, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			if (!is_operand_value(delta) || !check_is_assignable_to(c, &delta, t_uintptr)) {
				gbString e = expr_to_string(delta.expr);
				gbString t = type_to_string(delta.type);
				error(delta.expr, "'%.*s' expected a uintptr for the memory delta, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_int;
			operand->value = {};
			break;
		}
		break;
	case BuiltinProc_wasm_memory_size:
		{
			if (!is_arch_wasm()) {
				error(call, "'%.*s' is only allowed on wasm targets", LIT(builtin_name));
				return false;
			}

			Operand index = {};
			check_expr(c, &index, ce->args[0]); if (index.mode == Addressing_Invalid) return false;

			convert_to_typed(c, &index, t_uintptr); if (index.mode == Addressing_Invalid) return false;

			if (!is_operand_value(index) || !check_is_assignable_to(c, &index, t_uintptr)) {
				gbString e = expr_to_string(index.expr);
				gbString t = type_to_string(index.type);
				error(index.expr, "'%.*s' expected a uintptr for the memory index, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_int;
			operand->value = {};
			break;
		}
		break;

	case BuiltinProc_wasm_memory_atomic_wait32:
		{
			if (!is_arch_wasm()) {
				error(call, "'%.*s' is only allowed on wasm targets", LIT(builtin_name));
				return false;
			}

			if (!check_target_feature_is_enabled(str_lit("atomics"), nullptr)) {
				error(call, "'%.*s' requires target feature 'atomics' to be enabled, enable it with -target-features:\"atomics\" or choose a different -microarch", LIT(builtin_name));
				return false;
			}

			Operand ptr = {};
			Operand expected = {};
			Operand timeout = {};
			check_expr(c, &ptr,      ce->args[0]); if (ptr.mode == Addressing_Invalid) return false;
			check_expr(c, &expected, ce->args[1]); if (expected.mode == Addressing_Invalid) return false;
			check_expr(c, &timeout,  ce->args[2]); if (timeout.mode == Addressing_Invalid) return false;

			Type *t_u32_ptr = alloc_type_pointer(t_u32);
			convert_to_typed(c, &ptr, t_u32_ptr);  if (ptr.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &expected, t_u32); if (expected.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &timeout, t_i64);  if (timeout.mode == Addressing_Invalid) return false;

			if (!is_operand_value(ptr) || !check_is_assignable_to(c, &ptr, t_u32_ptr)) {
				gbString e = expr_to_string(ptr.expr);
				gbString t = type_to_string(ptr.type);
				error(ptr.expr, "'%.*s' expected ^u32 for the memory pointer, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			if (!is_operand_value(expected) || !check_is_assignable_to(c, &expected, t_u32)) {
				gbString e = expr_to_string(expected.expr);
				gbString t = type_to_string(expected.type);
				error(expected.expr, "'%.*s' expected u32 for the 'expected' value, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			if (!is_operand_value(timeout) || !check_is_assignable_to(c, &timeout, t_i64)) {
				gbString e = expr_to_string(timeout.expr);
				gbString t = type_to_string(timeout.type);
				error(timeout.expr, "'%.*s' expected i64 for the timeout, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_u32;
			operand->value = {};
			break;
		}
		break;
	case BuiltinProc_wasm_memory_atomic_notify32:
		{
			if (!is_arch_wasm()) {
				error(call, "'%.*s' is only allowed on wasm targets", LIT(builtin_name));
				return false;
			}

			if (!check_target_feature_is_enabled(str_lit("atomics"), nullptr)) {
				error(call, "'%.*s' requires target feature 'atomics' to be enabled, enable it with -target-features:\"atomics\" or choose a different -microarch", LIT(builtin_name));
				return false;
			}

			Operand ptr = {};
			Operand waiters = {};
			check_expr(c, &ptr,     ce->args[0]); if (ptr.mode == Addressing_Invalid) return false;
			check_expr(c, &waiters, ce->args[1]); if (waiters.mode == Addressing_Invalid) return false;

			Type *t_u32_ptr = alloc_type_pointer(t_u32);
			convert_to_typed(c, &ptr, t_u32_ptr); if (ptr.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &waiters, t_u32); if (waiters.mode == Addressing_Invalid) return false;

			if (!is_operand_value(ptr) || !check_is_assignable_to(c, &ptr, t_u32_ptr)) {
				gbString e = expr_to_string(ptr.expr);
				gbString t = type_to_string(ptr.type);
				error(ptr.expr, "'%.*s' expected ^u32 for the memory pointer, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			if (!is_operand_value(waiters) || !check_is_assignable_to(c, &waiters, t_u32)) {
				gbString e = expr_to_string(waiters.expr);
				gbString t = type_to_string(waiters.type);
				error(waiters.expr, "'%.*s' expected u32 for the 'waiters' value, got '%s' of type %s", LIT(builtin_name), e, t);
				gb_string_free(t);
				gb_string_free(e);
				return false;
			}

			operand->mode = Addressing_Value;
			operand->type = t_u32;
			operand->value = {};
			break;
		}
		break;

	case BuiltinProc_x86_cpuid:
		{
			if (!is_arch_x86()) {
				error(call, "'%.*s' is only allowed on x86 targets (i386, amd64)", LIT(builtin_name));
				return false;
			}

			Operand ax = {};
			Operand cx = {};

			check_expr_with_type_hint(c, &ax, ce->args[0], t_u32); if (ax.mode == Addressing_Invalid) return false;
			check_expr_with_type_hint(c, &cx, ce->args[1], t_u32); if (cx.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &ax, t_u32); if (ax.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &cx, t_u32); if (cx.mode == Addressing_Invalid) return false;
			if (!are_types_identical(ax.type, t_u32)) {
				gbString str = type_to_string(ax.type);
				error(ax.expr, "'%.*s' expected a u32, got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			if (!are_types_identical(cx.type, t_u32)) {
				gbString str = type_to_string(cx.type);
				error(cx.expr, "'%.*s' expected a u32, got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}
			Type *types[4] = {t_u32, t_u32, t_u32, t_u32}; // eax ebc ecx edx
			operand->type = alloc_type_tuple_from_field_types(types, gb_count_of(types), false, false);
			operand->mode = Addressing_Value;
			operand->value = {};
			return true;
		}
		break;
	case BuiltinProc_x86_xgetbv:
		{
			if (!is_arch_x86()) {
				error(call, "'%.*s' is only allowed on x86 targets (i386, amd64)", LIT(builtin_name));
				return false;
			}

			Operand cx = {};
			check_expr_with_type_hint(c, &cx, ce->args[0], t_u32); if (cx.mode == Addressing_Invalid) return false;
			convert_to_typed(c, &cx, t_u32); if (cx.mode == Addressing_Invalid) return false;
			if (!are_types_identical(cx.type, t_u32)) {
				gbString str = type_to_string(cx.type);
				error(cx.expr, "'%.*s' expected a u32, got %s", LIT(builtin_name), str);
				gb_string_free(str);
				return false;
			}

			Type *types[2] = {t_u32, t_u32};
			operand->type = alloc_type_tuple_from_field_types(types, gb_count_of(types), false, false);
			operand->mode = Addressing_Value;
			operand->value = {};
			return true;
		}
		break;

	case BuiltinProc_valgrind_client_request:
		{
			// NOTE(bill): Check it but make it a no-op for non x86 (i386, amd64) targets

			enum {ARG_COUNT = 7};
			GB_ASSERT(builtin_procs[BuiltinProc_valgrind_client_request].arg_count == ARG_COUNT);

			Operand operands[ARG_COUNT] = {};
			for (isize i = 0; i < ARG_COUNT; i++) {
				Operand *op = &operands[i];
				check_expr_with_type_hint(c, op, ce->args[i], t_uintptr);
				if (op->mode == Addressing_Invalid) {
					return false;
				}
				convert_to_typed(c, op, t_uintptr);
				if (op->mode == Addressing_Invalid) {
					return false;
				}
				if (!are_types_identical(op->type, t_uintptr)) {
					gbString str = type_to_string(op->type);
					error(op->expr, "'%.*s' expected a uintptr, got %s", LIT(builtin_name), str);
					gb_string_free(str);
					return false;
				}
			}

			operand->type = t_uintptr;
			operand->mode = Addressing_Value;
			operand->value = {};
			return true;
		}

	}

	return true;
}
