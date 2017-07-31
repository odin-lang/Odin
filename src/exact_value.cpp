#include <math.h>

// TODO(bill): Big numbers
// IMPORTANT TODO(bill): This needs to be completely fixed!!!!!!!!

struct AstNode;
struct HashKey;
struct Type;
bool are_types_identical(Type *x, Type *y);

struct Complex128 {
	f64 real, imag;
};

enum ExactValueKind {
	ExactValue_Invalid,

	ExactValue_Bool,
	ExactValue_String,
	ExactValue_Integer,
	ExactValue_Float,
	ExactValue_Complex,
	ExactValue_Pointer,
	ExactValue_Compound, // TODO(bill): Is this good enough?
	ExactValue_Type,

	ExactValue_Count,
};

struct ExactValue {
	ExactValueKind kind;
	union {
		bool          value_bool;
		String        value_string;
		i128          value_integer; // NOTE(bill): This must be an integer and not a pointer
		f64           value_float;
		i64           value_pointer;
		Complex128    value_complex;
		AstNode *     value_compound;
		Type *        value_type;
	};
};

gb_global ExactValue const empty_exact_value = {};

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

ExactValue exact_value_i64(i64 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = i128_from_i64(i);
	return result;
}

ExactValue exact_value_i128(i128 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = i;
	return result;
}
ExactValue exact_value_u128(u128 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = u128_to_i128(i);
	return result;
}

ExactValue exact_value_float(f64 f) {
	ExactValue result = {ExactValue_Float};
	result.value_float = f;
	return result;
}

ExactValue exact_value_complex(f64 real, f64 imag) {
	ExactValue result = {ExactValue_Complex};
	result.value_complex.real = real;
	result.value_complex.imag = imag;
	return result;
}

ExactValue exact_value_pointer(i64 ptr) {
	ExactValue result = {ExactValue_Pointer};
	result.value_pointer = ptr;
	return result;
}

ExactValue exact_value_type(Type *type) {
	ExactValue result = {ExactValue_Type};
	result.value_type = type;
	return result;
}


ExactValue exact_value_integer_from_string(String string) {
	return exact_value_u128(u128_from_string(string));
}

f64 float_from_string(String string) {
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

#if 0
	if (len-i > 2 &&
	    str[i] == '0' &&
	    str[i+1] == 'h') {
		i += 2;
		u8 *text = string.text;
		isize len = string.len;
		if (has_prefix) {
			text += 2;
			len -= 2;
		}

		u64 base = 16;

		u64 result = {0};
		for (isize i = 0; i < len; i++) {
			Rune r = cast(Rune)text[i];
			if (r == '_') {
				continue;
			}
			u64 v = bit128__digit_value(r);
			if (v >= base) {
				break;
			}
			result *= base;
			result += v;
		}


		return *cast(f64 *)&result;
	}
#endif

	f64 value = 0.0;
	for (; i < len; i++) {
		Rune r = cast(Rune)str[i];
		if (r == '_') {
			continue;
		}
		i64 v = digit_value(r);
		if (v >= 10) {
			break;
		}
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
			i64 v = digit_value(r);
			if (v >= 10) {
				break;
			}
			value += v/pow10;
			pow10 *= 10.0;
		}
	}

	bool frac = false;
	f64 scale = 1.0;
	if ((str[i] == 'e') || (str[i] == 'E')) {
		i++;

		if (str[i] == '-') {
			frac = true;
			i++;
		} else if (str[i] == '+') {
			i++;
		}

		u32 exp = 0;
		for (; i < len; i++) {
			Rune r = cast(Rune)str[i];
			if (r == '_') {
				continue;
			}
			u32 d = cast(u32)digit_value(r);
			if (d >= 10) {
				break;
			}
			exp = exp * 10 + d;
		}
		if (exp > 308) exp = 308;

		while (exp >= 50) { scale *= 1e50; exp -= 50; }
		while (exp >=  8) { scale *= 1e8;  exp -=  8; }
		while (exp >   0) { scale *= 10.0; exp -=  1; }
	}

	return sign * (frac ? (value / scale) : (value * scale));
}

ExactValue exact_value_float_from_string(String string) {
	return exact_value_float(float_from_string(string));
}


ExactValue exact_value_from_basic_literal(Token token) {
	switch (token.kind) {
	case Token_String:  return exact_value_string(token.string);
	case Token_Integer: return exact_value_integer_from_string(token.string);
	case Token_Float:   return exact_value_float_from_string(token.string);
	case Token_Imag: {
		String str = token.string;
		Rune last_rune = cast(Rune)str[str.len-1];
		str.len--; // Ignore the `i|j|k`
		f64 imag = float_from_string(str);

		if (last_rune == 'i') {
			return exact_value_complex(0, imag);
		}
	}
	case Token_Rune: {
		Rune r = GB_RUNE_INVALID;
		gb_utf8_decode(token.string.text, token.string.len, &r);
		// gb_printf("%.*s rune: %d\n", LIT(token.string), r);
		return exact_value_i64(r);
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
		i128 i = i128_from_f64(v.value_float);
		f64 f = i128_to_f64(i);
		if (f == v.value_float) {
			return exact_value_i128(i);
		}
	} break;

	case ExactValue_Pointer:
		return exact_value_i64(cast(i64)cast(intptr)v.value_pointer);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_to_float(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_float(i128_to_f64(v.value_integer));
	case ExactValue_Float:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_to_complex(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_complex(i128_to_f64(v.value_integer), 0);
	case ExactValue_Float:
		return exact_value_complex(v.value_float, 0);
	case ExactValue_Complex:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}


ExactValue exact_value_real(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
		return v;
	case ExactValue_Complex:
		return exact_value_float(v.value_complex.real);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_imag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
		return exact_value_i64(0);
	case ExactValue_Complex:
		return exact_value_float(v.value_complex.imag);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_make_imag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_complex(0, exact_value_to_float(v).value_float);
	case ExactValue_Float:
		return exact_value_complex(0, v.value_float);
	default:
		GB_PANIC("Expected an integer or float type for `exact_value_make_imag`");
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
		case ExactValue_Complex:
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
		case ExactValue_Complex: {
			f64 real = v.value_complex.real;
			f64 imag = v.value_complex.imag;
			return exact_value_complex(-real, -imag);
		}
		}
	} break;

	case Token_Xor: {
		i128 i = I128_ZERO;
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
		if (0 < precision && precision < 128) {
			i = i & ~(I128_NEG_ONE << precision);
		}

		return exact_value_i128(i);
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
	case ExactValue_Complex:
		return 4;
	case ExactValue_Pointer:
		return 5;

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
	case ExactValue_Complex:
		return;

	case ExactValue_Integer:
		switch (y->kind) {
		case ExactValue_Integer:
			return;
		case ExactValue_Float:
			// TODO(bill): Is this good enough?
			*x = exact_value_float(i128_to_f64(x->value_integer));
			return;
		case ExactValue_Complex:
			*x = exact_value_complex(i128_to_f64(x->value_integer), 0);
			return;
		}
		break;

	case ExactValue_Float:
		switch (y->kind) {
		case ExactValue_Float:
			return;
		case ExactValue_Complex:
			*x = exact_value_to_complex(*x);
			return;
		}
		break;
	}

	compiler_error("match_exact_values: How'd you get here? Invalid ExactValueKind %d", x->kind);
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
		i128 a = x.value_integer;
		i128 b = y.value_integer;
		i128 c = I128_ZERO;
		switch (op) {
		case Token_Add:    c = a + b;                        break;
		case Token_Sub:    c = a - b;                        break;
		case Token_Mul:    c = a * b;                        break;
		case Token_Quo:    return exact_value_float(fmod(i128_to_f64(a), i128_to_f64(b)));
		case Token_QuoEq:  c = a / b;                        break; // NOTE(bill): Integer division
		case Token_Mod:    c = a % b;                        break;
		case Token_ModMod: c = ((a % b) + b) % b;            break;
		case Token_And:    c = a & b;                        break;
		case Token_Or:     c = a | b;                        break;
		case Token_Xor:    c = a ^ b;                        break;
		case Token_AndNot: c = i128_and_not(a, b);           break;
		case Token_Shl:    c = a << cast(u32)i128_to_u64(b); break;
		case Token_Shr:    c = a >> cast(u32)i128_to_u64(b); break;
		default: goto error;
		}

		return exact_value_i128(c);
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

	case ExactValue_Complex: {
		y = exact_value_to_complex(y);
		f64 a = x.value_complex.real;
		f64 b = x.value_complex.imag;
		f64 c = y.value_complex.real;
		f64 d = y.value_complex.imag;
		f64 real = 0;
		f64 imag = 0;
		switch (op) {
		case Token_Add:
			real = a + c;
			imag = b + d;
			break;
		case Token_Sub:
			real = a - c;
			imag = b - d;
			break;
		case Token_Mul:
			real = (a*c - b*d);
			imag = (b*c + a*d);
			break;
		case Token_Quo: {
			f64 s = c*c + d*d;
			real = (a*c + b*d)/s;
			imag = (b*c - a*d)/s;
		} break;
		default: goto error;
		}
		return exact_value_complex(real, imag);
	} break;

	case ExactValue_String: {
		if (op != Token_Add) goto error;

		// NOTE(bill): How do you minimize this over allocation?
		String sx = x.value_string;
		String sy = y.value_string;
		isize len = sx.len+sy.len;
		u8 *data = gb_alloc_array(heap_allocator(), u8, len);
		gb_memmove(data,        sx.text, sx.len);
		gb_memmove(data+sx.len, sy.text, sy.len);
		return exact_value_string(make_string(data, len));
	} break;
	}

error:; // NOTE(bill): MSVC accepts this??? apparently you cannot declare variables immediately after labels...
	return empty_exact_value;
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
		i128 a = x.value_integer;
		i128 b = y.value_integer;
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

	case ExactValue_Complex: {
		f64 a = x.value_complex.real;
		f64 b = x.value_complex.imag;
		f64 c = y.value_complex.real;
		f64 d = y.value_complex.imag;
		switch (op) {
		case Token_CmpEq: return cmp_f64(a, c) == 0 && cmp_f64(b, d) == 0;
		case Token_NotEq: return cmp_f64(a, c) != 0 || cmp_f64(b, d) != 0;
		}
	} break;

	case ExactValue_String: {
		String a = x.value_string;
		String b = y.value_string;
		// TODO(bill): gb_memcompare is used because the strings are UTF-8
		switch (op) {
		case Token_CmpEq: return a == b;
		case Token_NotEq: return a != b;
		case Token_Lt:    return a <  b;
		case Token_LtEq:  return a <= b;
		case Token_Gt:    return a >  b;
		case Token_GtEq:  return a >= b;
		}
	} break;

	case ExactValue_Type:
		switch (op) {
		case Token_CmpEq: return are_types_identical(x.value_type, y.value_type);
		case Token_NotEq: return !are_types_identical(x.value_type, y.value_type);
		}
		break;
	}

	GB_PANIC("Invalid comparison");
	return false;
}
