#include <math.h>

// TODO(bill): Big numbers
// IMPORTANT TODO(bill): This needs to be completely fixed!!!!!!!!

typedef struct AstNode AstNode;

typedef enum ExactValueKind {
	ExactValue_Invalid,

	ExactValue_Bool,
	ExactValue_String,
	ExactValue_Integer,
	ExactValue_Float,
	ExactValue_Pointer,
	ExactValue_Compound, // TODO(bill): Is this good enough?

	ExactValue_Count,
} ExactValueKind;

typedef struct ExactValue {
	ExactValueKind kind;
	union {
		bool      value_bool;
		String   value_string;
		i64      value_integer; // NOTE(bill): This must be an integer and not a pointer
		f64      value_float;
		i64      value_pointer;
		AstNode *value_compound;
	};
} ExactValue;

HashKey hash_exact_value(ExactValue v) {
	return hashing_proc(&v, gb_size_of(ExactValue));
}


ExactValue make_exact_value_compound(AstNode *node) {
	ExactValue result = {ExactValue_Compound};
	result.value_compound = node;
	return result;
}

ExactValue make_exact_value_bool(bool b) {
	ExactValue result = {ExactValue_Bool};
	result.value_bool = (b != 0);
	return result;
}

ExactValue make_exact_value_string(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	ExactValue result = {ExactValue_String};
	result.value_string = string;
	return result;
}

ExactValue make_exact_value_integer(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	ExactValue result = {ExactValue_Integer};
	i32 base = 10;
	if (string.text[0] == '0') {
		switch (string.text[1]) {
		case 'b': base = 2;  break;
		case 'o': base = 8;  break;
		case 'd': base = 10; break;
		case 'x': base = 16; break;
		}
	}

	result.value_integer = gb_str_to_i64(cast(char *)string.text, NULL, base);

	return result;
}

ExactValue make_exact_value_integer(i64 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = i;
	return result;
}

ExactValue make_exact_value_float(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	ExactValue result = {ExactValue_Float};
	result.value_float = gb_str_to_f64(cast(char *)string.text, NULL);
	return result;
}

ExactValue make_exact_value_float(f64 f) {
	ExactValue result = {ExactValue_Float};
	result.value_float = f;
	return result;
}

ExactValue make_exact_value_pointer(i64 ptr) {
	ExactValue result = {ExactValue_Pointer};
	result.value_pointer = ptr;
	return result;
}

ExactValue make_exact_value_from_basic_literal(Token token) {
	switch (token.kind) {
	case Token_String:  return make_exact_value_string(token.string);
	case Token_Integer: return make_exact_value_integer(token.string);
	case Token_Float:   return make_exact_value_float(token.string);
	case Token_Rune: {
		Rune r = GB_RUNE_INVALID;
		gb_utf8_decode(token.string.text, token.string.len, &r);
		// gb_printf("%.*s rune: %d\n", LIT(token.string), r);
		return make_exact_value_integer(r);
	}
	default:
		GB_PANIC("Invalid token for basic literal");
		break;
	}

	ExactValue result = {ExactValue_Invalid};
	return result;
}

ExactValue exact_value_to_integer(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return v;
	case ExactValue_Float: {
		i64 i = cast(i64)v.value_float;
		f64 f = cast(f64)i;
		if (f == v.value_float) {
			return make_exact_value_integer(i);
		}
	} break;

	case ExactValue_Pointer:
		return make_exact_value_integer(cast(i64)cast(intptr)v.value_pointer);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_to_float(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return make_exact_value_float(cast(i64)v.value_integer);
	case ExactValue_Float:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}


ExactValue exact_unary_operator_value(Token op, ExactValue v, i32 precision) {
	switch (op.kind) {
	case Token_Add:	{
		switch (v.kind) {
		case ExactValue_Invalid:
		case ExactValue_Integer:
		case ExactValue_Float:
			return v;
		}
	} break;

	case Token_Sub:	{
		switch (v.kind) {
		case ExactValue_Invalid:
			return v;
		case ExactValue_Integer: {
			ExactValue i = v;
			i.value_integer = -i.value_integer;
			return i;
		}
		case ExactValue_Float: {
			ExactValue i = v;
			i.value_float = -i.value_float;
			return i;
		}
		}
	} break;

	case Token_Xor: {
		i64 i = 0;
		switch (v.kind) {
		case ExactValue_Invalid:
			return v;
		case ExactValue_Integer:
			i = v.value_integer;
			i = ~i;
			break;
		default:
			goto failure;
		}

		// NOTE(bill): unsigned integers will be negative and will need to be
		// limited to the types precision
		if (precision > 0)
			i &= ~((~0ll)<<precision);

		return make_exact_value_integer(i);
	} break;

	case Token_Not: {
		switch (v.kind) {
		case ExactValue_Invalid: return v;
		case ExactValue_Bool:
			return make_exact_value_bool(!v.value_bool);
		}
	} break;
	}

failure:
	GB_PANIC("Invalid unary operation, %.*s", LIT(token_strings[op.kind]));

	ExactValue error_value = {};
	return error_value;
}

// NOTE(bill): Make sure things are evaluated in correct order
i32 exact_value_order(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Invalid:
		return 0;
	case ExactValue_Bool:
	case ExactValue_String:
		return 1;
	case ExactValue_Integer:
		return 2;
	case ExactValue_Float:
		return 3;
	case ExactValue_Pointer:
		return 4;

	default:
		GB_PANIC("How'd you get here? Invalid Value.kind");
		return -1;
	}
}

void match_exact_values(ExactValue *x, ExactValue *y) {
	if (exact_value_order(*y) < exact_value_order(*x)) {
		match_exact_values(y, x);
		return;
	}

	switch (x->kind) {
	case ExactValue_Invalid:
		*y = *x;
		return;

	case ExactValue_Bool:
	case ExactValue_String:
		return;

	case ExactValue_Integer:
		switch (y->kind) {
		case ExactValue_Integer:
			return;
		case ExactValue_Float:
			// TODO(bill): Is this good enough?
			*x = make_exact_value_float(cast(f64)x->value_integer);
			return;
		}
		break;

	case ExactValue_Float:
		if (y->kind == ExactValue_Float)
			return;
		break;
	}

	compiler_error("How'd you get here? Invalid ExactValueKind");
}

// TODO(bill): Allow for pointer arithmetic? Or are pointer slices good enough?
ExactValue exact_binary_operator_value(Token op, ExactValue x, ExactValue y) {
	match_exact_values(&x, &y);

	switch (x.kind) {
	case ExactValue_Invalid:
		return x;

	case ExactValue_Bool:
		switch (op.kind) {
		case Token_CmpAnd: return make_exact_value_bool(x.value_bool && y.value_bool);
		case Token_CmpOr:  return make_exact_value_bool(x.value_bool || y.value_bool);
		case Token_And:    return make_exact_value_bool(x.value_bool & y.value_bool);
		case Token_Or:     return make_exact_value_bool(x.value_bool | y.value_bool);
		default: goto error;
		}
		break;

	case ExactValue_Integer: {
		i64 a = x.value_integer;
		i64 b = y.value_integer;
		i64 c = 0;
		switch (op.kind) {
		case Token_Add:    c = a + b;  break;
		case Token_Sub:    c = a - b;  break;
		case Token_Mul:    c = a * b;  break;
		case Token_Quo:    return make_exact_value_float(fmod(cast(f64)a, cast(f64)b));
		case Token_QuoEq:  c = a / b;  break; // NOTE(bill): Integer division
		case Token_Mod:    c = a % b;  break;
		case Token_And:    c = a & b;  break;
		case Token_Or:     c = a | b;  break;
		case Token_Xor:    c = a ^ b;  break;
		case Token_AndNot: c = a&(~b); break;
		case Token_Shl:    c = a << b; break;
		case Token_Shr:    c = a >> b; break;
		default: goto error;
		}
		return make_exact_value_integer(c);
	} break;

	case ExactValue_Float: {
		f64 a = x.value_float;
		f64 b = y.value_float;
		switch (op.kind) {
		case Token_Add: return make_exact_value_float(a + b);
		case Token_Sub: return make_exact_value_float(a - b);
		case Token_Mul: return make_exact_value_float(a * b);
		case Token_Quo: return make_exact_value_float(a / b);
		default: goto error;
		}
	} break;
	}

error:
	ExactValue error_value = {};
	// gb_printf_err("Invalid binary operation: %s\n", token_kind_to_string(op.kind));
	return error_value;
}

gb_inline ExactValue exact_value_add(ExactValue x, ExactValue y) { Token op = {Token_Add};        return exact_binary_operator_value(op, x, y); }
gb_inline ExactValue exact_value_sub(ExactValue x, ExactValue y) { Token op = {Token_Sub};        return exact_binary_operator_value(op, x, y); }
gb_inline ExactValue exact_value_mul(ExactValue x, ExactValue y) { Token op = {Token_Mul};        return exact_binary_operator_value(op, x, y); }
gb_inline ExactValue exact_value_quo(ExactValue x, ExactValue y) { Token op = {Token_Quo};        return exact_binary_operator_value(op, x, y); }
gb_inline ExactValue exact_value_shift(Token op, ExactValue x, ExactValue y) { return exact_binary_operator_value(op, x, y); }


i32 cmp_f64(f64 a, f64 b) {
	return (a > b) - (a < b);
}

bool compare_exact_values(Token op, ExactValue x, ExactValue y) {
	match_exact_values(&x, &y);

	switch (x.kind) {
	case ExactValue_Invalid:
		return false;

	case ExactValue_Bool:
		switch (op.kind) {
		case Token_CmpEq: return x.value_bool == y.value_bool;
		case Token_NotEq: return x.value_bool != y.value_bool;
		}
		break;

	case ExactValue_Integer: {
		i64 a = x.value_integer;
		i64 b = y.value_integer;
		switch (op.kind) {
		case Token_CmpEq: return a == b;
		case Token_NotEq: return a != b;
		case Token_Lt:    return a <  b;
		case Token_LtEq:  return a <= b;
		case Token_Gt:    return a >  b;
		case Token_GtEq:  return a >= b;
		}
	} break;

	case ExactValue_Float: {
		f64 a = x.value_float;
		f64 b = y.value_float;
		switch (op.kind) {
		case Token_CmpEq: return cmp_f64(a, b) == 0;
		case Token_NotEq: return cmp_f64(a, b) != 0;
		case Token_Lt:    return cmp_f64(a, b) <  0;
		case Token_LtEq:  return cmp_f64(a, b) <= 0;
		case Token_Gt:    return cmp_f64(a, b) >  0;
		case Token_GtEq:  return cmp_f64(a, b) >= 0;
		}
	} break;

	case ExactValue_String: {
		String a = x.value_string;
		String b = y.value_string;
		isize len = gb_min(a.len, b.len);
		// TODO(bill): gb_memcompare is used because the strings are UTF-8
		switch (op.kind) {
		case Token_CmpEq: return gb_memcompare(a.text, b.text, len) == 0;
		case Token_NotEq: return gb_memcompare(a.text, b.text, len) != 0;
		case Token_Lt:    return gb_memcompare(a.text, b.text, len) <  0;
		case Token_LtEq:  return gb_memcompare(a.text, b.text, len) <= 0;
		case Token_Gt:    return gb_memcompare(a.text, b.text, len) >  0;
		case Token_GtEq:  return gb_memcompare(a.text, b.text, len) >= 0;
		}
	} break;
	}

	GB_PANIC("Invalid comparison");
	return false;
}
