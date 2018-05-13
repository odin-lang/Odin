#include <math.h>

// TODO(bill): Big numbers
// IMPORTANT TODO(bill): This needs to be completely fixed!!!!!!!!

struct AstNode;
struct HashKey;
struct Type;
struct Entity;
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
	ExactValue_Compound,  // TODO(bill): Is this good enough?
	ExactValue_Procedure, // TODO(bill): Is this good enough?
	ExactValue_Entity,    // TODO(bill): Is this good enough?

	ExactValue_Count,
};

struct ExactValue {
	ExactValueKind kind;
	union {
		bool          value_bool;
		String        value_string;
		i64           value_integer; // NOTE(bill): This must be an integer and not a pointer
		f64           value_float;
		i64           value_pointer;
		Complex128    value_complex;
		AstNode *     value_compound;
		AstNode *     value_procedure;
		Entity *      value_entity;
	};
};

gb_global ExactValue const empty_exact_value = {};

HashKey hash_exact_value(ExactValue v) {
	HashKey empty = {};
	switch (v.kind) {
	case ExactValue_Invalid:
		return empty;
	case ExactValue_Bool:
		return hash_integer(u64(v.value_bool));
	case ExactValue_String:
		return hash_string(v.value_string);
	case ExactValue_Integer:
		return hash_integer(u64(v.value_integer));
	case ExactValue_Float:
		return hash_f64(v.value_float);
	case ExactValue_Pointer:
		return hash_integer(v.value_pointer);
	case ExactValue_Complex:
		return hashing_proc(&v.value_complex, gb_size_of(Complex128));

	case ExactValue_Compound:
		return hash_pointer(v.value_compound);
	case ExactValue_Procedure:
		return hash_pointer(v.value_procedure);
	case ExactValue_Entity:
		return hash_pointer(v.value_entity);
	}
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
	result.value_integer = i;
	return result;
}

ExactValue exact_value_u64(u64 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = i64(i);
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

ExactValue exact_value_procedure(AstNode *node) {
	ExactValue result = {ExactValue_Procedure};
	result.value_procedure = node;
	return result;
}

ExactValue exact_value_entity(Entity *entity) {
	ExactValue result = {ExactValue_Entity};
	result.value_entity = entity;
	return result;
}


ExactValue exact_value_integer_from_string(String string) {
	u64 u = u64_from_string(string);
	return exact_value_u64(u);
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
	if (string.len > 2 && string[0] == '0' && string[1] == 'h') {

		isize digit_count = 0;
		for (isize i = 2; i < string.len; i++) {
			if (string[i] != '_') {
				digit_count += 1;
			}
		}
		u64 u = u64_from_string(string);
		if (digit_count == 8) {
			u32 x = cast(u32)u;
			f32 f = bit_cast<f32>(x);
			return exact_value_float(cast(f64)f);
		} else if (digit_count == 16) {
			f64 f = bit_cast<f64>(u);
			return exact_value_float(f);
		} else {
			GB_PANIC("Invalid hexadecimal float, expected 8 or 16 digits, got %td", digit_count);
		}
	}

	f64 f = float_from_string(string);
	return exact_value_float(f);
}


ExactValue exact_value_from_basic_literal(Token token) {
	switch (token.kind) {
	case Token_String:  return exact_value_string(token.string);
	case Token_Integer: return exact_value_integer_from_string(token.string);
	case Token_Float:   return exact_value_float_from_string(token.string);
	case Token_Imag: {
		String str = token.string;
		Rune last_rune = cast(Rune)str[str.len-1];
		str.len--; // Ignore the 'i|j|k'
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
		i64 i = cast(i64)v.value_float;
		f64 f = cast(f64)i;
		if (f == v.value_float) {
			return exact_value_i64(i);
		}
		break;
	}

	case ExactValue_Pointer:
		return exact_value_i64(cast(i64)cast(intptr)v.value_pointer);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_to_float(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_float(cast(f64)v.value_integer);
	case ExactValue_Float:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

ExactValue exact_value_to_complex(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_complex(cast(f64)v.value_integer, 0);
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
		GB_PANIC("Expected an integer or float type for 'exact_value_make_imag'");
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
		break;
	}

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
		break;
	}

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
		i = i & unsigned_integer_maxs[precision/8];
		// if (0 < precision && precision < 64) {
		// 	i = i & ~(-1ll << precision);
		// }

		return exact_value_i64(i);
	}

	case Token_Not: {
		switch (v.kind) {
		case ExactValue_Invalid: return v;
		case ExactValue_Bool:
			return exact_value_bool(!v.value_bool);
		}
		break;
	}
	}

failure:
	GB_PANIC("Invalid unary operation, %.*s", LIT(token_strings[op]));

	ExactValue error_value = {};
	return error_value;
}

// NOTE(bill): Make sure things are evaluated in correct order
i32 exact_value_order(ExactValue const &v) {
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
			*x = exact_value_float(cast(f64)x->value_integer);
			return;
		case ExactValue_Complex:
			*x = exact_value_complex(cast(f64)x->value_integer, 0);
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
		i64 a = x.value_integer;
		i64 b = y.value_integer;
		i64 c = 0ll;
		switch (op) {
		case Token_Add:    c = a + b;                        break;
		case Token_Sub:    c = a - b;                        break;
		case Token_Mul:    c = a * b;                        break;
		case Token_Quo:    return exact_value_float(fmod(cast(f64)a, cast(f64)b));
		case Token_QuoEq:  c = a / b;                        break; // NOTE(bill): Integer division
		case Token_Mod:    c = a % b;                        break;
		case Token_ModMod: c = ((a % b) + b) % b;            break;
		case Token_And:    c = a & b;                        break;
		case Token_Or:     c = a | b;                        break;
		case Token_Xor:    c = a ^ b;                        break;
		case Token_AndNot: c = a & (~b);                     break;
		case Token_Shl:    c = a << b;                       break;
		case Token_Shr:    c = a >> b;                       break;
		default: goto error;
		}

		return exact_value_i64(c);
		break;
	}

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
		break;
	}

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
			break;
		}
		default: goto error;
		}
		return exact_value_complex(real, imag);
		break;
	}

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
		break;
	}
	}

error:; // NOTE(bill): MSVC accepts this??? apparently you cannot declare variables immediately after labels...
	return empty_exact_value;
}

gb_inline ExactValue exact_value_add(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Add, x, y);
}
gb_inline ExactValue exact_value_sub(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Sub, x, y);
}
gb_inline ExactValue exact_value_mul(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Mul, x, y);
}
gb_inline ExactValue exact_value_quo(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Quo, x, y);
}
gb_inline ExactValue exact_value_shift(TokenKind op, ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(op, x, y);
}


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
		break;
	}

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
		break;
	}

	case ExactValue_Complex: {
		f64 a = x.value_complex.real;
		f64 b = x.value_complex.imag;
		f64 c = y.value_complex.real;
		f64 d = y.value_complex.imag;
		switch (op) {
		case Token_CmpEq: return cmp_f64(a, c) == 0 && cmp_f64(b, d) == 0;
		case Token_NotEq: return cmp_f64(a, c) != 0 || cmp_f64(b, d) != 0;
		}
		break;
	}

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
		break;
	}
	}

	GB_PANIC("Invalid comparison");
	return false;
}
