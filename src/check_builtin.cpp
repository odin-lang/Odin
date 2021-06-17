typedef bool (BuiltinTypeIsProc)(Type *t);

BuiltinTypeIsProc *builtin_type_is_procs[BuiltinProc__type_simple_boolean_end - BuiltinProc__type_simple_boolean_begin] = {
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

	is_type_named,
	is_type_pointer,
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

	is_type_polymorphic_record_specialized,
	is_type_polymorphic_record_unspecialized,

	type_has_nil,
};



bool check_builtin_procedure(CheckerContext *c, Operand *operand, Ast *call, i32 id, Type *type_hint) {
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
	case BuiltinProc_type_info_of:
	case BuiltinProc_typeid_of:
	case BuiltinProc_len:
	case BuiltinProc_min:
	case BuiltinProc_max:
		// NOTE(bill): The first arg may be a Type, this will be checked case by case
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

	String builtin_name = builtin_procs[id].name;


	if (ce->args.count > 0) {
		if (ce->args[0]->kind == Ast_FieldValue) {
			if (id != BuiltinProc_soa_zip) {
				error(call, "'field = value' calling is not allowed on built-in procedures");
				return false;
			}
		}
	}

	switch (id) {
	default:
		GB_PANIC("Implement built-in procedure: %.*s", LIT(builtin_name));
		break;

	case BuiltinProc_DIRECTIVE: {
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
			if (ce->args.count != 1) {
				error(ce->args[0], "'#load' expects 1 argument, got %td", ce->args.count);
				return false;
			}

			Ast *arg = ce->args[0];
			Operand o = {};
			check_expr(c, &o, arg);
			if (o.mode != Addressing_Constant) {
				error(arg, "'#load' expected a constant string argument");
				return false;
			}

			if (!is_type_string(o.type)) {
				gbString str = type_to_string(o.type);
				error(arg, "'#load' expected a constant string, got %s", str);
				gb_string_free(str);
				return false;
			}

			gbAllocator a = heap_allocator();

			GB_ASSERT(o.value.kind == ExactValue_String);
			String base_dir = dir_from_path(get_file_path_string(bd->token.pos.file_id));
			String original_string = o.value.value_string;


			gbMutex *ignore_mutex = nullptr;
			String path = {};
			bool ok = determine_path_from_string(ignore_mutex, call, base_dir, original_string, &path);

			char *c_str = alloc_cstring(a, path);
			defer (gb_free(a, c_str));


			gbFile f = {};
			gbFileError file_err = gb_file_open(&f, c_str);
			defer (gb_file_close(&f));

			switch (file_err) {
			default:
			case gbFileError_Invalid:
				error(ce->proc, "Failed to `#load` file: %s; invalid file or cannot be found", c_str);
				return false;
			case gbFileError_NotExists:
				error(ce->proc, "Failed to `#load` file: %s; file cannot be found", c_str);
				return false;
			case gbFileError_Permission:
				error(ce->proc, "Failed to `#load` file: %s; file permissions problem", c_str);
				return false;
			case gbFileError_None:
				// Okay
				break;
			}

			String result = {};
			isize file_size = cast(isize)gb_file_size(&f);
			if (file_size > 0) {
				u8 *data = cast(u8 *)gb_alloc(a, file_size+1);
				gb_file_read_at(&f, data, file_size, 0);
				data[file_size] = '\0';
				result.text = data;
				result.len = file_size;
			}

			operand->type = t_u8_slice;
			operand->mode = Addressing_Constant;
			operand->value = exact_value_string(result);

		} else if (name == "assert") {
			if (ce->args.count != 1) {
				error(call, "'#assert' expects 1 argument, got %td", ce->args.count);
				return false;
			}
			if (!is_type_boolean(operand->type) || operand->mode != Addressing_Constant) {
				gbString str = expr_to_string(ce->args[0]);
				error(call, "'%s' is not a constant boolean", str);
				gb_string_free(str);
				return false;
			}
			if (!operand->value.value_bool) {
				gbString arg = expr_to_string(ce->args[0]);
				error(call, "Compile time assertion: %s", arg);
				if (c->proc_name != "") {
					gbString str = type_to_string(c->curr_proc_sig);
					error_line("\tCalled within '%.*s' :: %s\n", LIT(c->proc_name), str);
					gb_string_free(str);
				}
				gb_string_free(arg);
			}

			operand->type = t_untyped_bool;
			operand->mode = Addressing_Constant;
		} else if (name == "panic") {
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
			operand->type = t_untyped_bool;
			operand->mode = Addressing_Constant;
			operand->value = exact_value_bool(false);

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
			GB_PANIC("Unhandled #%.*s", LIT(name));
		}

		break;
	}

	case BuiltinProc_len:
		check_expr_or_type(c, operand, ce->args[0]);
		if (operand->mode == Addressing_Invalid) {
			return false;
		}
		/* fallthrough */

	case BuiltinProc_cap:
	{
		// len :: proc(Type) -> int
		// cap :: proc(Type) -> int

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
		} else if (operand->mode == Addressing_Type && is_type_enum(op_type) && id == BuiltinProc_len) {
			Type *bt = base_type(op_type);
			mode  = Addressing_Constant;
			value = exact_value_i64(bt->Enum.fields.count);
			type  = t_untyped_integer;
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
		// offset_of :: proc(Type, field) -> uintptr
		Operand op = {};
		Type *bt = check_type(c, ce->args[0]);
		Type *type = base_type(bt);
		if (type == nullptr || type == t_invalid) {
			error(ce->args[0], "Expected a type for 'offset_of'");
			return false;
		}

		Ast *field_arg = unparen_expr(ce->args[1]);
		if (field_arg == nullptr ||
		    field_arg->kind != Ast_Ident) {
			error(field_arg, "Expected an identifier for field argument");
			return false;
		}
		if (is_type_array(type)) {
			error(field_arg, "Invalid type for 'offset_of'");
			return false;
		}


		ast_node(arg, Ident, field_arg);
		Selection sel = lookup_field(type, arg->token.string, operand->mode == Addressing_Type);
		if (sel.entity == nullptr) {
			gbString type_str = type_to_string(bt);
			error(ce->args[0],
			      "'%s' has no field named '%.*s'", type_str, LIT(arg->token.string));
			gb_string_free(type_str);
			return false;
		}
		if (sel.indirect) {
			gbString type_str = type_to_string(bt);
			error(ce->args[0],
			      "Field '%.*s' is embedded via a pointer in '%s'", LIT(arg->token.string), type_str);
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
				error(ce->args[0], "Invalid argument for 'type_info_of', unspecialized polymorphic type");
			} else {
				error(ce->args[0], "Invalid argument for 'type_info_of'");
			}
			return false;
		}
		t = default_type(t);

		add_type_info_type(c, t);

		if (is_operand_value(o) && is_type_typeid(t)) {
			add_package_dependency(c, "runtime", "__type_info_of");
		} else if (o.mode != Addressing_Type) {
			error(expr, "Expected a type or typeid for 'type_info_of'");
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

		// NOTE(bill): The type information may not be setup yet
		init_core_type_info(c->checker);
		Ast *expr = ce->args[0];
		Operand o = {};
		check_expr_or_type(c, &o, expr);
		if (o.mode == Addressing_Invalid) {
			return false;
		}
		Type *t = o.type;
		if (t == nullptr || t == t_invalid || is_type_asm_proc(o.type) || is_type_polymorphic(operand->type)) {
			error(ce->args[0], "Invalid argument for 'typeid_of'");
			return false;
		}
		t = default_type(t);

		add_type_info_type(c, t);

		if (o.mode != Addressing_Type) {
			error(expr, "Expected a type for 'typeid_of'");
			return false;
		}

		operand->mode = Addressing_Value;
		operand->type = t_typeid;
		operand->value = exact_value_typeid(t);
		break;
	}

	case BuiltinProc_swizzle: {
		// swizzle :: proc(v: [N]T, ..int) -> [M]T
		Type *type = base_type(operand->type);
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

			if (op.value.value_integer.neg) {
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

		if (arg_count < max_count) {
			operand->type = alloc_type_array(elem_type, arg_count);
		}
		operand->mode = Addressing_Value;

		if (type_hint != nullptr && check_is_castable_to(c, operand, type_hint)) {
			operand->type = type_hint;
		}

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
		// quaternion :: proc(real, imag, jmag, kmag: float_type) -> complex_type
		Operand x = *operand;
		Operand y = {};
		Operand z = {};
		Operand w = {};

		// NOTE(bill): Invalid will be the default till fixed
		operand->type = t_invalid;
		operand->mode = Addressing_Invalid;

		check_expr(c, &y, ce->args[1]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		check_expr(c, &z, ce->args[2]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}
		check_expr(c, &w, ce->args[3]);
		if (y.mode == Addressing_Invalid) {
			return false;
		}

		convert_to_typed(c, &x, y.type); if (x.mode == Addressing_Invalid) return false;
		convert_to_typed(c, &y, x.type); if (y.mode == Addressing_Invalid) return false;
		convert_to_typed(c, &z, x.type); if (z.mode == Addressing_Invalid) return false;
		convert_to_typed(c, &w, x.type); if (w.mode == Addressing_Invalid) return false;
		if (x.mode == Addressing_Constant &&
		    y.mode == Addressing_Constant &&
		    z.mode == Addressing_Constant &&
		    w.mode == Addressing_Constant) {
			if (is_type_numeric(x.type) && exact_value_imag(x.value).value_float == 0) {
				x.type = t_untyped_float;
			}
			if (is_type_numeric(y.type) && exact_value_imag(y.value).value_float == 0) {
				y.type = t_untyped_float;
			}
			if (is_type_numeric(z.type) && exact_value_imag(z.value).value_float == 0) {
				z.type = t_untyped_float;
			}
			if (is_type_numeric(w.type) && exact_value_imag(w.value).value_float == 0) {
				w.type = t_untyped_float;
			}
		}

		if (!(are_types_identical(x.type, y.type) && are_types_identical(x.type, z.type) && are_types_identical(x.type, w.type))) {
			gbString tx = type_to_string(x.type);
			gbString ty = type_to_string(y.type);
			gbString tz = type_to_string(z.type);
			gbString tw = type_to_string(w.type);
			error(call, "Mismatched types to 'quaternion', '%s' vs '%s' vs '%s' vs '%s'", tx, ty, tz, tw);
			gb_string_free(tw);
			gb_string_free(tz);
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

		if (x.mode == Addressing_Constant && y.mode == Addressing_Constant && z.mode == Addressing_Constant && w.mode == Addressing_Constant) {
			f64 r = exact_value_to_float(x.value).value_float;
			f64 i = exact_value_to_float(y.value).value_float;
			f64 j = exact_value_to_float(z.value).value_float;
			f64 k = exact_value_to_float(w.value).value_float;
			operand->value = exact_value_quaternion(r, i, j, k);
			operand->mode = Addressing_Constant;
		} else {
			operand->mode = Addressing_Value;
		}

		BasicKind kind = core_type(x.type)->Basic.kind;
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
		if (is_type_complex(x->type)) {
			if (x->mode == Addressing_Constant) {
				ExactValue v = exact_value_to_complex(x->value);
				f64 r = v.value_complex->real;
				f64 i = -v.value_complex->imag;
				x->value = exact_value_complex(r, i);
				x->mode = Addressing_Constant;
			} else {
				x->mode = Addressing_Value;
			}
		} else if (is_type_quaternion(x->type)) {
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
		} else {
			gbString s = type_to_string(x->type);
			error(call, "Expected a complex or quaternion, got '%s'", s);
			gb_string_free(s);
			return false;
		}

		break;
	}

	case BuiltinProc_expand_to_tuple: {
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
			array_init(&tuple->Tuple.variables, a, variable_count);
			// TODO(bill): Should I copy each of the entities or is this good enough?
			gb_memmove_array(tuple->Tuple.variables.data, type->Struct.fields.data, variable_count);
		} else if (is_type_array(type)) {
			isize variable_count = type->Array.count;
			array_init(&tuple->Tuple.variables, a, variable_count);
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
				operand->value = type->Enum.min_value;
				return true;
			} else if (is_type_enumerated_array(type)) {
				Type *bt = base_type(type);
				GB_ASSERT(bt->kind == Type_EnumeratedArray);
				operand->mode  = Addressing_Constant;
				operand->type  = bt->EnumeratedArray.index;
				operand->value = bt->EnumeratedArray.min_value;
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
				operand->value = type->Enum.max_value;
				return true;
			} else if (is_type_enumerated_array(type)) {
				Type *bt = base_type(type);
				GB_ASSERT(bt->kind == Type_EnumeratedArray);
				operand->mode  = Addressing_Constant;
				operand->type  = bt->EnumeratedArray.index;
				operand->value = bt->EnumeratedArray.max_value;
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
				operand->value.value_integer.neg = false;
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

		if (is_type_complex(operand->type)) {
			operand->type = base_complex_elem_type(operand->type);
		}
		GB_ASSERT(!is_type_complex(operand->type));

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
					if (a->mode == Addressing_Invalid) { return false; }
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
		auto types = array_make<Type *>(temporary_allocator(), 0, ce->args.count);
		auto names = array_make<String>(temporary_allocator(), 0, ce->args.count);

		bool first_is_field_value = (ce->args[0]->kind == Ast_FieldValue);

		bool fail = false;
		for_array(i, ce->args) {
			Ast *arg = ce->args[i];
			bool mix = false;
			if (first_is_field_value) {
				mix = arg->kind != Ast_FieldValue;
			} else {
				mix = arg->kind == Ast_FieldValue;
			}
			if (mix) {
				error(arg, "Mixture of 'field = value' and value elements in the procedure call 'soa_zip' is not allowed");
				fail = true;
				break;
			}
		}
		StringSet name_set = {};
		string_set_init(&name_set, temporary_allocator(), 2*ce->args.count);

		for_array(i, ce->args) {
			String name = {};
			Ast *arg = ce->args[i];
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


			if (string_set_exists(&name_set, name)) {
				error(op.expr, "Field argument name '%.*s' already exists", LIT(name));
			} else {
				array_add(&types, arg_type->Slice.elem);
				array_add(&names, name);

				string_set_add(&name_set, name);
			}
		}




		Ast *dummy_node_struct = alloc_ast_node(nullptr, Ast_Invalid);
		Ast *dummy_node_soa = alloc_ast_node(nullptr, Ast_Invalid);
		Scope *s = create_scope(builtin_pkg->scope);

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
			elem->Struct.fields = fields;
			elem->Struct.tags = array_make<String>(permanent_allocator(), fields.count);
			elem->Struct.node = dummy_node_struct;
			type_set_offsets(elem);
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
			error(call, "'soa_unzip' expects an #soa slice");
			return false;
		}
		Type *t = base_type(x.type);
		if (!is_type_soa_struct(t) || t->Struct.soa_kind != StructSoa_Slice) {
			gbString s = type_to_string(x.type);
			error(call, "'soa_unzip' expects an #soa slice, got %s", s);
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


	case BuiltinProc_simd_vector: {
		Operand x = {};
		Operand y = {};
		x = *operand;
		if (!is_type_integer(x.type) || x.mode != Addressing_Constant) {
			error(call, "Expected a constant integer for 'intrinsics.simd_vector'");
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}
		if (x.value.value_integer.neg) {
			error(call, "Negative vector element length");
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}
		i64 count = big_int_to_i64(&x.value.value_integer);

		check_expr_or_type(c, &y, ce->args[1]);
		if (y.mode != Addressing_Type) {
			error(call, "Expected a type 'intrinsics.simd_vector'");
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}
		Type *elem = y.type;
		if (!is_type_valid_vector_elem(elem)) {
			gbString str = type_to_string(elem);
			error(call, "Invalid element type for 'intrinsics.simd_vector', expected an integer or float with no specific endianness, got '%s'", str);
			gb_string_free(str);
			operand->mode = Addressing_Type;
			operand->type = t_invalid;
			return false;
		}

		operand->mode = Addressing_Type;
		operand->type = alloc_type_simd_vector(count, elem);
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
		if (x.value.value_integer.neg) {
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
			soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), old_array->Array.count);
			soa_struct->Struct.tags = array_make<String>(heap_allocator(), old_array->Array.count);
			soa_struct->Struct.node = operand->expr;
			soa_struct->Struct.soa_kind = StructSoa_Fixed;
			soa_struct->Struct.soa_elem = elem;
			soa_struct->Struct.soa_count = count;

			scope = create_scope(c->scope);
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
				add_entity(c->checker, scope, nullptr, new_field);
				add_entity_use(c, nullptr, new_field);
			}

		} else {
			GB_ASSERT(is_type_struct(elem));

			Type *old_struct = base_type(elem);
			soa_struct = alloc_type_struct();
			soa_struct->Struct.fields = array_make<Entity *>(heap_allocator(), old_struct->Struct.fields.count);
			soa_struct->Struct.tags = array_make<String>(heap_allocator(), old_struct->Struct.tags.count);
			soa_struct->Struct.node = operand->expr;
			soa_struct->Struct.soa_kind = StructSoa_Fixed;
			soa_struct->Struct.soa_elem = elem;
			soa_struct->Struct.soa_count = count;

			scope = create_scope(old_struct->Struct.scope->parent);
			soa_struct->Struct.scope = scope;

			for_array(i, old_struct->Struct.fields) {
				Entity *old_field = old_struct->Struct.fields[i];
				if (old_field->kind == Entity_Variable) {
					Type *array_type = alloc_type_array(old_field->type, count);
					Entity *new_field = alloc_entity_field(scope, old_field->token, array_type, false, old_field->Variable.field_src_index);
					soa_struct->Struct.fields[i] = new_field;
					add_entity(c->checker, scope, nullptr, new_field);
				} else {
					soa_struct->Struct.fields[i] = old_field;
				}

				soa_struct->Struct.tags[i] = old_struct->Struct.tags[i];
			}
		}

		Token token = {};
		token.string = str_lit("Base_Type");
		Entity *base_type_entity = alloc_entity_type_name(scope, token, elem, EntityState_Resolved);
		add_entity(c->checker, scope, nullptr, base_type_entity);

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

			operand->type = t_u8_ptr;
			operand->mode = Addressing_Value;
			break;
		}


	case BuiltinProc_cpu_relax:
		operand->mode = Addressing_NoValue;
		break;

	case BuiltinProc_trap:
	case BuiltinProc_debug_trap:
		operand->mode = Addressing_NoValue;
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

			if (!is_type_integer_like(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Values passed to '%.*s' must be an integer-like type (integer, boolean, enum, bit_set), got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
			} else if (x.type == t_llvm_bool) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Invalid type passed to '%.*s', got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
			}

			operand->mode = Addressing_Value;
			operand->type = default_type(x.type);
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
				error(x.expr, "Values passed to '%.*s' must be an integer-like type (integer, boolean, enum, bit_set) or float, got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
			} else if (x.type == t_llvm_bool) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Invalid type passed to '%.*s', got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
			}
			i64 sz = type_size_of(x.type);
			if (sz < 2) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Type passed to '%.*s' must be at least 2 bytes, got %s with size of %lld", LIT(builtin_procs[id].name), xts, sz);
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
			convert_to_typed(c, &y, x.type);
			convert_to_typed(c, &x, y.type);
			if (is_type_untyped(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected a typed integer for '%.*s', got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
				return false;
			}
			if (!is_type_integer(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected an integer for '%.*s', got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
				return false;
			}
			Type *ct = core_type(x.type);
			if (is_type_different_to_arch_endianness(ct)) {
				GB_ASSERT(ct->kind == Type_Basic);
				if (ct->Basic.flags & (BasicFlag_EndianLittle|BasicFlag_EndianBig)) {
					gbString xts = type_to_string(x.type);
					error(x.expr, "Expected an integer which does not specify the explicit endianness for '%.*s', got %s", LIT(builtin_procs[id].name), xts);
					gb_string_free(xts);
					return false;
				}
			}

			operand->mode = Addressing_OptionalOk;
			operand->type = default_type(x.type);
		}
		break;

	case BuiltinProc_sqrt:
		{
			Operand x = {};
			check_expr(c, &x, ce->args[0]);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (!is_type_float(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected a floating point value for '%.*s', got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
				return false;
			}

			if (x.mode == Addressing_Constant) {
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


			if (!is_type_pointer(dst.type)) {
				gbString str = type_to_string(dst.type);
				error(dst.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_pointer(src.type)) {
				gbString str = type_to_string(src.type);
				error(src.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_integer(len.type)) {
				gbString str = type_to_string(len.type);
				error(len.expr, "Expected an integer value for the number of bytes for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}

			if (len.mode == Addressing_Constant) {
				i64 n = exact_value_to_i64(len.value);
				if (n < 0) {
					gbString str = expr_to_string(len.expr);
					error(len.expr, "Expected a non-negative integer value for the number of bytes for '%.*s', got %s", LIT(builtin_procs[id].name), str);
					gb_string_free(str);
				}
			}
		}
		break;

	case BuiltinProc_mem_zero:
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


			if (!is_type_pointer(ptr.type)) {
				gbString str = type_to_string(ptr.type);
				error(ptr.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_integer(len.type)) {
				gbString str = type_to_string(len.type);
				error(len.expr, "Expected an integer value for the number of bytes for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}

			if (len.mode == Addressing_Constant) {
				i64 n = exact_value_to_i64(len.value);
				if (n < 0) {
					gbString str = expr_to_string(len.expr);
					error(len.expr, "Expected a non-negative integer value for the number of bytes for '%.*s', got %s", LIT(builtin_procs[id].name), str);
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

			if (!is_type_pointer(ptr.type)) {
				gbString str = type_to_string(ptr.type);
				error(ptr.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (are_types_identical(core_type(ptr.type), t_rawptr)) {
				gbString str = type_to_string(ptr.type);
				error(ptr.expr, "Expected a dereferenceable pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (!is_type_integer(offset.type)) {
				gbString str = type_to_string(offset.type);
				error(offset.expr, "Expected an integer value for the offset parameter for '%.*s', got %s", LIT(builtin_procs[id].name), str);
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

			if (!is_type_pointer(ptr0.type)) {
				gbString str = type_to_string(ptr0.type);
				error(ptr0.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (are_types_identical(core_type(ptr0.type), t_rawptr)) {
				gbString str = type_to_string(ptr0.type);
				error(ptr0.expr, "Expected a dereferenceable pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}

			if (!is_type_pointer(ptr1.type)) {
				gbString str = type_to_string(ptr1.type);
				error(ptr1.expr, "Expected a pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}
			if (are_types_identical(core_type(ptr1.type), t_rawptr)) {
				gbString str = type_to_string(ptr1.type);
				error(ptr1.expr, "Expected a dereferenceable pointer value for '%.*s', got %s", LIT(builtin_procs[id].name), str);
				gb_string_free(str);
				return false;
			}

			if (!are_types_identical(ptr0.type, ptr1.type)) {
				gbString xts = type_to_string(ptr0.type);
				gbString yts = type_to_string(ptr1.type);
				error(ptr0.expr, "Mismatched types for '%.*s', %s vs %s", LIT(builtin_procs[id].name), xts, yts);
				gb_string_free(yts);
				gb_string_free(xts);
				return false;
			}

		}
		break;


	case BuiltinProc_atomic_fence:
	case BuiltinProc_atomic_fence_acq:
	case BuiltinProc_atomic_fence_rel:
	case BuiltinProc_atomic_fence_acqrel:
		operand->mode = Addressing_NoValue;
		break;

	case BuiltinProc_volatile_store:
		/*fallthrough*/
	case BuiltinProc_atomic_store:
	case BuiltinProc_atomic_store_rel:
	case BuiltinProc_atomic_store_relaxed:
	case BuiltinProc_atomic_store_unordered:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			Operand x = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_assignment(c, &x, elem, builtin_name);

			operand->type = nullptr;
			operand->mode = Addressing_NoValue;
			break;
		}

	case BuiltinProc_volatile_load:
		/*fallthrough*/
	case BuiltinProc_atomic_load:
	case BuiltinProc_atomic_load_acq:
	case BuiltinProc_atomic_load_relaxed:
	case BuiltinProc_atomic_load_unordered:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			operand->type = elem;
			operand->mode = Addressing_Value;
			break;
		}

	case BuiltinProc_atomic_add:
	case BuiltinProc_atomic_add_acq:
	case BuiltinProc_atomic_add_rel:
	case BuiltinProc_atomic_add_acqrel:
	case BuiltinProc_atomic_add_relaxed:
	case BuiltinProc_atomic_sub:
	case BuiltinProc_atomic_sub_acq:
	case BuiltinProc_atomic_sub_rel:
	case BuiltinProc_atomic_sub_acqrel:
	case BuiltinProc_atomic_sub_relaxed:
	case BuiltinProc_atomic_and:
	case BuiltinProc_atomic_and_acq:
	case BuiltinProc_atomic_and_rel:
	case BuiltinProc_atomic_and_acqrel:
	case BuiltinProc_atomic_and_relaxed:
	case BuiltinProc_atomic_nand:
	case BuiltinProc_atomic_nand_acq:
	case BuiltinProc_atomic_nand_rel:
	case BuiltinProc_atomic_nand_acqrel:
	case BuiltinProc_atomic_nand_relaxed:
	case BuiltinProc_atomic_or:
	case BuiltinProc_atomic_or_acq:
	case BuiltinProc_atomic_or_rel:
	case BuiltinProc_atomic_or_acqrel:
	case BuiltinProc_atomic_or_relaxed:
	case BuiltinProc_atomic_xor:
	case BuiltinProc_atomic_xor_acq:
	case BuiltinProc_atomic_xor_rel:
	case BuiltinProc_atomic_xor_acqrel:
	case BuiltinProc_atomic_xor_relaxed:
	case BuiltinProc_atomic_xchg:
	case BuiltinProc_atomic_xchg_acq:
	case BuiltinProc_atomic_xchg_rel:
	case BuiltinProc_atomic_xchg_acqrel:
	case BuiltinProc_atomic_xchg_relaxed:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			Operand x = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_assignment(c, &x, elem, builtin_name);

			operand->type = elem;
			operand->mode = Addressing_Value;
			break;
		}

	case BuiltinProc_atomic_cxchg:
	case BuiltinProc_atomic_cxchg_acq:
	case BuiltinProc_atomic_cxchg_rel:
	case BuiltinProc_atomic_cxchg_acqrel:
	case BuiltinProc_atomic_cxchg_relaxed:
	case BuiltinProc_atomic_cxchg_failrelaxed:
	case BuiltinProc_atomic_cxchg_failacq:
	case BuiltinProc_atomic_cxchg_acq_failrelaxed:
	case BuiltinProc_atomic_cxchg_acqrel_failrelaxed:

	case BuiltinProc_atomic_cxchgweak:
	case BuiltinProc_atomic_cxchgweak_acq:
	case BuiltinProc_atomic_cxchgweak_rel:
	case BuiltinProc_atomic_cxchgweak_acqrel:
	case BuiltinProc_atomic_cxchgweak_relaxed:
	case BuiltinProc_atomic_cxchgweak_failrelaxed:
	case BuiltinProc_atomic_cxchgweak_failacq:
	case BuiltinProc_atomic_cxchgweak_acq_failrelaxed:
	case BuiltinProc_atomic_cxchgweak_acqrel_failrelaxed:
		{
			Type *elem = nullptr;
			if (!is_type_normal_pointer(operand->type, &elem)) {
				error(operand->expr, "Expected a pointer for '%.*s'", LIT(builtin_name));
				return false;
			}
			Operand x = {};
			Operand y = {};
			check_expr_with_type_hint(c, &x, ce->args[1], elem);
			check_expr_with_type_hint(c, &y, ce->args[2], elem);
			check_assignment(c, &x, elem, builtin_name);
			check_assignment(c, &y, elem, builtin_name);

			operand->mode = Addressing_OptionalOk;
			operand->type = elem;
			break;
		}
		break;

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
			convert_to_typed(c, &y, x.type);
			if (x.mode == Addressing_Invalid) {
				return false;
			}
			if (!are_types_identical(x.type, y.type)) {
				gbString xts = type_to_string(x.type);
				gbString yts = type_to_string(y.type);
				error(x.expr, "Mismatched types for '%.*s', %s vs %s", LIT(builtin_procs[id].name), xts, yts);
				gb_string_free(yts);
				gb_string_free(xts);
				return false;
			}

			if (!is_type_integer(x.type) || is_type_untyped(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Expected an integer type for '%.*s', got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
				return false;
			}

			check_expr(c, &z, ce->args[2]);
			if (z.mode == Addressing_Invalid) {
				return false;
			}
			if (z.mode != Addressing_Constant || !is_type_integer(z.type)) {
				error(z.expr, "Expected a constant integer for the scale in '%.*s'", LIT(builtin_procs[id].name));
				return false;
			}
			i64 n = exact_value_to_i64(z.value);
			if (n <= 0) {
				error(z.expr, "Scale parameter in '%.*s' must be positive, got %lld", LIT(builtin_procs[id].name), n);
				return false;
			}
			i64 sz = 8*type_size_of(x.type);
			if (n > sz) {
				error(z.expr, "Scale parameter in '%.*s' is larger than the base integer bit width, got %lld, expected a maximum of %lld", LIT(builtin_procs[id].name), n, sz);
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
			convert_to_typed(c, &y, x.type);
			convert_to_typed(c, &x, y.type);
			if (!are_types_identical(x.type, y.type)) {
				gbString xts = type_to_string(x.type);
				gbString yts = type_to_string(y.type);
				error(x.expr, "Mismatched types for '%.*s', %s vs %s", LIT(builtin_procs[id].name), xts, yts);
				gb_string_free(yts);
				gb_string_free(xts);
				*operand = x; // minimize error propagation
				return true;
			}

			if (!is_type_integer_like(x.type)) {
				gbString xts = type_to_string(x.type);
				error(x.expr, "Values passed to '%.*s' must be an integer-like type (integer, boolean, enum, bit_set), got %s", LIT(builtin_procs[id].name), xts);
				gb_string_free(xts);
				*operand = x;
				return true;
			}

			if (y.mode != Addressing_Constant) {
				error(y.expr, "Second argument to '%.*s' must be constant as it is the expected value", LIT(builtin_procs[id].name));
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
				case Basic_complex64:  operand->type = t_f32; break;
				case Basic_complex128: operand->type = t_f64; break;
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
	case BuiltinProc_type_is_named:
	case BuiltinProc_type_is_pointer:
	case BuiltinProc_type_is_array:
	case BuiltinProc_type_is_slice:
	case BuiltinProc_type_is_dynamic_array:
	case BuiltinProc_type_is_map:
	case BuiltinProc_type_is_struct:
	case BuiltinProc_type_is_union:
	case BuiltinProc_type_is_enum:
	case BuiltinProc_type_is_proc:
	case BuiltinProc_type_is_bit_field:
	case BuiltinProc_type_is_bit_field_value:
	case BuiltinProc_type_is_bit_set:
	case BuiltinProc_type_is_simd_vector:
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

			for_array(i, u->Union.variants) {
				Type *vt = u->Union.variants[i];
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
			if (op.mode != Addressing_Constant && !is_type_integer(op.type)) {
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
					param = bt->Proc.params->Tuple.variables[index];
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
			if (op.mode != Addressing_Constant && !is_type_integer(op.type)) {
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
					param = bt->Proc.results->Tuple.variables[index];
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
			if (op.mode != Addressing_Constant && !is_type_integer(op.type)) {
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
				gbString type_str = type_to_string(bt);
				error(ce->args[0],
				      "'%s' has no field named '%.*s'", type_str, LIT(field_name));
				gb_string_free(type_str);
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
	}

	return true;
}
