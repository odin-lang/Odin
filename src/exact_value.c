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
		bool     value_bool;
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


ExactValue exact_value_compound(AstNode *node) {
	ExactValue result = {ExactValue_Compound};
	result.value_compound = node;
	return result;
}

ExactValue exact_value_bool(bool b) {
	ExactValue result = {ExactValue_Bool};
	result.value_bool = (b != 0);
	return result;
}

ExactValue exact_value_string(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	ExactValue result = {ExactValue_String};
	result.value_string = string;
	return result;
}

ExactValue exact_value_integer(i64 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = i;
	return result;
}

ExactValue exact_value_float(f64 f) {
	ExactValue result = {ExactValue_Float};
	result.value_float = f;
	return result;
}

ExactValue exact_value_pointer(i64 ptr) {
	ExactValue result = {ExactValue_Pointer};
	result.value_pointer = ptr;
	return result;
}


ExactValue exact_value_integer_from_string(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	i32 base = 10;
	bool has_prefix = false;
	if (string.len > 2 && string.text[0] == '0') {
		switch (string.text[1]) {
		case 'b': base = 2;  has_prefix = true; break;
		case 'o': base = 8;  has_prefix = true; break;
		case 'd': base = 10; has_prefix = true; break;
		case 'x': base = 16; has_prefix = true; break;
		}
	}

	u8 *text = string.text;
	isize len = string.len;
	if (has_prefix) {
		text += 2;
		len -= 2;
	}

	i64 result = 0;
	for (isize i = 0; i < len; i++) {
		Rune r = cast(Rune)text[i];
		if (r == '_') {
			continue;
		}
		i64 v = 0;
		if (gb_char_is_digit(r)) {
			v = r - '0';
		} else if (gb_char_is_hex_digit(r)) {
			v = gb_hex_digit_to_int(r);
		} else {
			break;
		}

		result *= base;
		result += v;
	}


	return exact_value_integer(result);
}



ExactValue exact_value_float_from_string(String string) {
	isize i = 0;
	u8 *str = string.text;
	isize len = string.len;

	f64 sign = 1.0;
	if (str[i] == '-') {
		sign = -1.0;
		i++;
	} else if (*str == '+') {
		i++;
	}

	f64 value = 0.0;
	for (; i < len; i++) {
		Rune r = cast(Rune)str[i];
		if (r == '_') {
			continue;
		}
		if (!gb_char_is_digit(r)) {
			break;
		}
		i64 v = r - '0';
		value *= 10.0;
		value += v;
	}

	if (str[i] == '.') {
		f64 pow10 = 10.0;
		i++;
		for (; i < string.len; i++) {
			Rune r = cast(Rune)str[i];
			if (r == '_') {
				continue;
			}
			if (!gb_char_is_digit(r)) {
				break;
			}
			value += (r-'0')/pow10;
			pow10 *= 10.0;
		}
	}

	f64 frac = 0;
	f64 scale = 1.0;
	if ((str[i] == 'e') || (str[i] == 'E')) {
		i++;

		if (str[i] == '-') {
			frac = 1;
			i++;
		} else if (str[i] == '+') {
			i++;
		}

		u32 exp;
		for (exp = 0; gb_char_is_digit(str[i]); i++) {
			exp = exp * 10 + (str[i]-'0');
		}
		if (exp > 308) exp = 308;

		while (exp >= 50) { scale *= 1e50; exp -= 50; }
		while (exp >=  8) { scale *= 1e8;  exp -=  8; }
		while (exp >   0) { scale *= 10.0; exp -=  1; }
	}

	f64 result = sign * (frac ? (value / scale) : (value * scale));
	return exact_value_float(result);
}


ExactValue exact_value_from_basic_literal(Token token) {
	switch (token.kind) {
	case Token_String:  return exact_value_string(token.string);
	case Token_Integer: return exact_value_integer_from_string(token.string);
	case Token_Float:   return exact_value_float_from_string(token.string);
	case Token_Rune: {
		Rune r = GB_RUNE_INVALID;
		gb_utf8_decode(token.string.text, token.string.len, &r);
		// gb_printf("%.*s rune: %d\n", LIT(token.string), r);
		return exact_value_integer(r);
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
			return exact_value_integer(i);
		}
	} break;

	case ExactValue_Pointer:
		return exact_value_integer(cast(i64)cast(intptr)v.value_pointer);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_to_float(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_float(cast(i64)v.value_integer);
	case ExactValue_Float:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}


ExactValue exact_unary_operator_value(TokenKind op, ExactValue v, i32 precision) {
	switch (op) {
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
			i = ~v.value_integer;
			break;
		default:
			goto failure;
		}

		// NOTE(bill): unsigned integers will be negative and will need to be
		// limited to the types precision
		// IMPORTANT NOTE(bill): Max precision is 64 bits as that's how integers are stored
		if (0 < precision && precision < 64) {
			i &= ~((~0ll)<<precision);
		}

		return exact_value_integer(i);
	} break;

	case Token_Not: {
		switch (v.kind) {
		case ExactValue_Invalid: return v;
		case ExactValue_Bool:
			return exact_value_bool(!v.value_bool);
		}
	} break;
	}

failure:
	GB_PANIC("Invalid unary operation, %.*s", LIT(token_strings[op]));

	ExactValue error_value = {0};
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
			*x = exact_value_float(cast(f64)x->value_integer);
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
ExactValue exact_binary_operator_value(TokenKind op, ExactValue x, ExactValue y) {
	match_exact_values(&x, &y);

	switch (x.kind) {
	case ExactValue_Invalid:
		return x;

	case ExactValue_Bool:
		switch (op) {
		case Token_CmpAnd: return exact_value_bool(x.value_bool && y.value_bool);
		case Token_CmpOr:  return exact_value_bool(x.value_bool || y.value_bool);
		case Token_And:    return exact_value_bool(x.value_bool & y.value_bool);
		case Token_Or:     return exact_value_bool(x.value_bool | y.value_bool);
		default: goto error;
		}
		break;

	case ExactValue_Integer: {
		i64 a = x.value_integer;
		i64 b = y.value_integer;
		i64 c = 0;
		switch (op) {
		case Token_Add:    c = a + b;  break;
		case Token_Sub:    c = a - b;  break;
		case Token_Mul:    c = a * b;  break;
		case Token_Quo:    return exact_value_float(fmod(cast(f64)a, cast(f64)b));
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

		return exact_value_integer(c);
	} break;

	case ExactValue_Float: {
		f64 a = x.value_float;
		f64 b = y.value_float;
		switch (op) {
		case Token_Add: return exact_value_float(a + b);
		case Token_Sub: return exact_value_float(a - b);
		case Token_Mul: return exact_value_float(a * b);
		case Token_Quo: return exact_value_float(a / b);
		default: goto error;
		}
	} break;
	}

error:
	;		// MSVC accepts this??? apparently you cannot declare variables immediately after labels...
	ExactValue error_value = {0};
	// gb_printf_err("Invalid binary operation: %s\n", token_kind_to_string(op));
	return error_value;
}

gb_inline ExactValue exact_value_add(ExactValue x, ExactValue y) { return exact_binary_operator_value(Token_Add, x, y); }
gb_inline ExactValue exact_value_sub(ExactValue x, ExactValue y) { return exact_binary_operator_value(Token_Sub, x, y); }
gb_inline ExactValue exact_value_mul(ExactValue x, ExactValue y) { return exact_binary_operator_value(Token_Mul, x, y); }
gb_inline ExactValue exact_value_quo(ExactValue x, ExactValue y) { return exact_binary_operator_value(Token_Quo, x, y); }
gb_inline ExactValue exact_value_shift(TokenKind op, ExactValue x, ExactValue y) { return exact_binary_operator_value(op, x, y); }


i32 cmp_f64(f64 a, f64 b) {
	return (a > b) - (a < b);
}

bool compare_exact_values(TokenKind op, ExactValue x, ExactValue y) {
	match_exact_values(&x, &y);

	switch (x.kind) {
	case ExactValue_Invalid:
		return false;

	case ExactValue_Bool:
		switch (op) {
		case Token_CmpEq: return x.value_bool == y.value_bool;
		case Token_NotEq: return x.value_bool != y.value_bool;
		}
		break;

	case ExactValue_Integer: {
		i64 a = x.value_integer;
		i64 b = y.value_integer;
		switch (op) {
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
		switch (op) {
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
		switch (op) {
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
