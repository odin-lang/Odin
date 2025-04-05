#include <math.h>
#include <stdlib.h>

gb_global BlockingMutex hash_exact_value_mutex;

struct Ast;
struct HashKey;
struct Type;
struct Entity;
gb_internal bool are_types_identical(Type *x, Type *y);

struct Complex128 {
	f64 real, imag;
};
struct Quaternion256 {
	f64 imag, jmag, kmag, real;
};

enum ExactValueKind {
	ExactValue_Invalid    = 0,

	ExactValue_Bool       = 1,
	ExactValue_String     = 2,
	ExactValue_Integer    = 3,
	ExactValue_Float      = 4,
	ExactValue_Complex    = 5,
	ExactValue_Quaternion = 6,
	ExactValue_Pointer    = 7,
	ExactValue_Compound   = 8,
	ExactValue_Procedure  = 9,
	ExactValue_Typeid     = 10,

	ExactValue_Count,
};

struct ExactValue {
	ExactValueKind kind;
	union {
		bool           value_bool;
		String         value_string;
		BigInt         value_integer;
		f64            value_float;
		i64            value_pointer; // NOTE(bill): This must be an integer and not a pointer
		Complex128    *value_complex;
		Quaternion256 *value_quaternion;
		Ast *          value_compound;
		Ast *          value_procedure;
		Type *         value_typeid;
	};
};

gb_global ExactValue const empty_exact_value = {};

gb_internal uintptr hash_exact_value(ExactValue v) {
	mutex_lock(&hash_exact_value_mutex);
	defer (mutex_unlock(&hash_exact_value_mutex));

	uintptr res = 0;
	
	switch (v.kind) {
	case ExactValue_Invalid:
		return 0;
	case ExactValue_Bool:
		res = gb_fnv32a(&v.value_bool, gb_size_of(v.value_bool));
		break;
	case ExactValue_String:
		res = gb_fnv32a(v.value_string.text, v.value_string.len);
		break;
	case ExactValue_Integer:
		{
			u32 key = gb_fnv32a(v.value_integer.dp, gb_size_of(*v.value_integer.dp) * v.value_integer.used);
			u8 last = (u8)v.value_integer.sign;
			res = (key ^ last) * 0x01000193;
			break;
		}
	case ExactValue_Float:
		res = gb_fnv32a(&v.value_float, gb_size_of(v.value_float));
		break;
	case ExactValue_Pointer:
		res = ptr_map_hash_key(v.value_pointer);
		break;
	case ExactValue_Complex:
		res = gb_fnv32a(v.value_complex, gb_size_of(Complex128));
		break;
	case ExactValue_Quaternion:
		res = gb_fnv32a(v.value_quaternion, gb_size_of(Quaternion256));
		break;
	case ExactValue_Compound:
		res = ptr_map_hash_key(v.value_compound);
		break;
	case ExactValue_Procedure:
		res = ptr_map_hash_key(v.value_procedure);
		break;
	case ExactValue_Typeid:
		res = ptr_map_hash_key(v.value_typeid);
		break;
	default:
		res = gb_fnv32a(&v, gb_size_of(ExactValue));
	}
	return res & 0x7fffffff;
}


gb_internal ExactValue exact_value_compound(Ast *node) {
	ExactValue result = {ExactValue_Compound};
	result.value_compound = node;
	return result;
}

gb_internal ExactValue exact_value_bool(bool b) {
	ExactValue result = {ExactValue_Bool};
	result.value_bool = (b != 0);
	return result;
}

gb_internal ExactValue exact_value_string(String string) {
	ExactValue result = {ExactValue_String};
	result.value_string = string;
	return result;
}

gb_internal ExactValue exact_value_i64(i64 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = {0};
	big_int_from_i64(&result.value_integer, i);
	return result;
}

gb_internal ExactValue exact_value_u64(u64 i) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = {0};
	big_int_from_u64(&result.value_integer, i);
	return result;
}

gb_internal ExactValue exact_value_float(f64 f) {
	ExactValue result = {ExactValue_Float};
	result.value_float = f;
	return result;
}

gb_internal ExactValue exact_value_complex(f64 real, f64 imag) {
	ExactValue result = {ExactValue_Complex};
	result.value_complex = gb_alloc_item(permanent_allocator(), Complex128);
	result.value_complex->real = real;
	result.value_complex->imag = imag;
	return result;
}

gb_internal ExactValue exact_value_quaternion(f64 real, f64 imag, f64 jmag, f64 kmag) {
	ExactValue result = {ExactValue_Quaternion};
	result.value_quaternion = gb_alloc_item(permanent_allocator(), Quaternion256);
	result.value_quaternion->real = real;
	result.value_quaternion->imag = imag;
	result.value_quaternion->jmag = jmag;
	result.value_quaternion->kmag = kmag;
	return result;
}

gb_internal ExactValue exact_value_pointer(i64 ptr) {
	ExactValue result = {ExactValue_Pointer};
	result.value_pointer = ptr;
	return result;
}

gb_internal ExactValue exact_value_procedure(Ast *node) {
	ExactValue result = {ExactValue_Procedure};
	result.value_procedure = node;
	return result;
}


gb_internal ExactValue exact_value_typeid(Type *type) {
	ExactValue result = {ExactValue_Typeid};
	result.value_typeid = type;
	return result;
}


gb_internal ExactValue exact_value_integer_from_string(String const &string) {
	ExactValue result = {ExactValue_Integer};
	result.value_integer = {0};
	bool success;
	big_int_from_string(&result.value_integer, string, &success);
	if (!success) {
		result = {ExactValue_Invalid};
	}
	return result;
}



gb_internal f64 float_from_string(String const &string, bool *success = nullptr) {
	if (string.len < 128) {
		char buf[128] = {};
		isize n = 0;
		for (isize i = 0; i < string.len; i++) {
			u8 c = string.text[i];
			if (c == '_') {
				continue;
			}
			if (c == 'E') { c = 'e'; }
			buf[n++] = cast(char)c;
		}
		buf[n] = 0;

		char *end_ptr;
		f64 f = strtod(buf, &end_ptr);
		if (success != nullptr) {
			*success = *end_ptr == '\0';
		}
		return f;
	} else {
		TEMPORARY_ALLOCATOR_GUARD();
		char *buf = gb_alloc_array(temporary_allocator(), char, string.len+1);
		isize n = 0;
		for (isize i = 0; i < string.len; i++) {
			u8 c = string.text[i];
			if (c == '_') {
				continue;
			}
			if (c == 'E') { c = 'e'; }
			buf[n++] = cast(char)c;
		}
		buf[n] = 0;

		char *end_ptr;
		f64 f = strtod(buf, &end_ptr);
		if (success != nullptr) {
			*success = *end_ptr == '\0';
		}
		return f;
	}
/*
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
*/
}

gb_internal ExactValue exact_value_float_from_string(String string) {
	if (string.len > 2 && string[0] == '0' && string[1] == 'h') {

		isize digit_count = 0;
		for (isize i = 2; i < string.len; i++) {
			if (string[i] != '_') {
				digit_count += 1;
			}
		}
		u64 u = u64_from_string(string);
		if (digit_count == 4) {
			u16 x = cast(u16)u;
			f32 f = f16_to_f32(x);
			return exact_value_float(cast(f64)f);
		} else if (digit_count == 8) {
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

	if (!string_contains_char(string, '.') && !string_contains_char(string, '-')) {
		// NOTE(bill): treat as integer
		return exact_value_integer_from_string(string);
	}

	bool success;
	f64 f = float_from_string(string, &success);
	if (!success) {
		return {ExactValue_Invalid};
	}
	return exact_value_float(f);
}


gb_internal ExactValue exact_value_from_basic_literal(TokenKind kind, String const &string) {
	switch (kind) {
	case Token_String:  return exact_value_string(string);
	case Token_Integer: return exact_value_integer_from_string(string);
	case Token_Float:   return exact_value_float_from_string(string);
	case Token_Imag: {
		String str = string;
		Rune last_rune = cast(Rune)str[str.len-1];
		str.len--; // Ignore the 'i|j|k'
		f64 imag = float_from_string(str);

		switch (last_rune) {
		case 'i': return exact_value_complex(0, imag);
		case 'j': return exact_value_quaternion(0, 0, imag, 0);
		case 'k': return exact_value_quaternion(0, 0, 0, imag);
		default: GB_PANIC("Invalid imaginary basic literal");
		}
	}
	case Token_Rune: {
		Rune r = GB_RUNE_INVALID;
		if (string.len == 1) {
			r = cast(Rune)string.text[0];
		} else {
			utf8_decode(string.text, string.len, &r);
		}
		return exact_value_i64(r);
	}
	}

	ExactValue result = {ExactValue_Invalid};
	return result;
}

gb_internal ExactValue exact_value_to_integer(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Bool: {
		i64 i = 0;
		if (v.value_bool) {
			i = 1;
		}
		return exact_value_i64(i);
	}
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

gb_internal ExactValue exact_value_to_float(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_float(big_int_to_f64(&v.value_integer));
	case ExactValue_Float:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_to_complex(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_complex(big_int_to_f64(&v.value_integer), 0);
	case ExactValue_Float:
		return exact_value_complex(v.value_float, 0);
	case ExactValue_Complex:
		return v;
	// case ExactValue_Quaternion:
		// return exact_value_complex(v.value_quaternion.real, v.value_quaternion.imag);
	}
	ExactValue r = {ExactValue_Invalid};
	v.value_complex = gb_alloc_item(permanent_allocator(), Complex128);
	return r;
}
gb_internal ExactValue exact_value_to_quaternion(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
		return exact_value_quaternion(big_int_to_f64(&v.value_integer), 0, 0, 0);
	case ExactValue_Float:
		return exact_value_quaternion(v.value_float, 0, 0, 0);
	case ExactValue_Complex:
		return exact_value_quaternion(v.value_complex->real, v.value_complex->imag, 0, 0);
	case ExactValue_Quaternion:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	v.value_quaternion = gb_alloc_item(permanent_allocator(), Quaternion256);
	return r;
}

gb_internal ExactValue exact_value_real(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
		return v;
	case ExactValue_Complex:
		return exact_value_float(v.value_complex->real);
	case ExactValue_Quaternion:
		return exact_value_float(v.value_quaternion->real);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_imag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
		return exact_value_i64(0);
	case ExactValue_Complex:
		return exact_value_float(v.value_complex->imag);
	case ExactValue_Quaternion:
		return exact_value_float(v.value_quaternion->imag);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_jmag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Complex:
		return exact_value_i64(0);
	case ExactValue_Quaternion:
		return exact_value_float(v.value_quaternion->jmag);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_kmag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Complex:
		return exact_value_i64(0);
	case ExactValue_Quaternion:
		return exact_value_float(v.value_quaternion->kmag);
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

// gb_internal ExactValue exact_value_make_imag(ExactValue v) {
// 	switch (v.kind) {
// 	case ExactValue_Integer:
// 		return exact_value_complex(0, exact_value_to_float(v).value_float);
// 	case ExactValue_Float:
// 		return exact_value_complex(0, v.value_float);
// 	default:
// 		GB_PANIC("Expected an integer or float type for 'exact_value_make_imag'");
// 	}
// 	ExactValue r = {ExactValue_Invalid};
// 	return r;
// }

// gb_internal ExactValue exact_value_make_jmag(ExactValue v) {
// 	switch (v.kind) {
// 	case ExactValue_Integer:
// 		return exact_value_quaternion(0, 0, exact_value_to_float(v).value_float, 0);
// 	case ExactValue_Float:
// 		return exact_value_quaternion(0, 0, v.value_float, 0);
// 	default:
// 		GB_PANIC("Expected an integer or float type for 'exact_value_make_jmag'");
// 	}
// 	ExactValue r = {ExactValue_Invalid};
// 	return r;
// }

// gb_internal ExactValue exact_value_make_kmag(ExactValue v) {
// 	switch (v.kind) {
// 	case ExactValue_Integer:
// 		return exact_value_quaternion(0, 0, 0, exact_value_to_float(v).value_float);
// 	case ExactValue_Float:
// 		return exact_value_quaternion(0, 0, 0, v.value_float);
// 	default:
// 		GB_PANIC("Expected an integer or float type for 'exact_value_make_kmag'");
// 	}
// 	ExactValue r = {ExactValue_Invalid};
// 	return r;
// }

gb_internal i64 exact_value_to_i64(ExactValue v) {
	v = exact_value_to_integer(v);
	if (v.kind == ExactValue_Integer) {
		return big_int_to_i64(&v.value_integer);
	}
	return 0;
}
gb_internal u64 exact_value_to_u64(ExactValue v) {
	v = exact_value_to_integer(v);
	if (v.kind == ExactValue_Integer) {
		return big_int_to_u64(&v.value_integer);
	}
	return 0;
}
gb_internal f64 exact_value_to_f64(ExactValue v) {
	v = exact_value_to_float(v);
	if (v.kind == ExactValue_Float) {
		return v.value_float;
	}
	return 0.0;
}






gb_internal ExactValue exact_unary_operator_value(TokenKind op, ExactValue v, i32 precision, bool is_unsigned) {
	switch (op) {
	case Token_Add:	{
		switch (v.kind) {
		case ExactValue_Invalid:
		case ExactValue_Integer:
		case ExactValue_Float:
		case ExactValue_Complex:
		case ExactValue_Quaternion:
			return v;
		}
		break;
	}

	case Token_Sub:	{
		switch (v.kind) {
		case ExactValue_Invalid:
			return v;
		case ExactValue_Integer: {
			ExactValue i = {ExactValue_Integer};
			i.value_integer = {0};
			big_int_neg(&i.value_integer, &v.value_integer);
			return i;
		}
		case ExactValue_Float: {
			ExactValue i = v;
			i.value_float = -i.value_float;
			return i;
		}
		case ExactValue_Complex: {
			f64 real = v.value_complex->real;
			f64 imag = v.value_complex->imag;
			return exact_value_complex(-real, -imag);
		}
		case ExactValue_Quaternion: {
			f64 real = v.value_quaternion->real;
			f64 imag = v.value_quaternion->imag;
			f64 jmag = v.value_quaternion->jmag;
			f64 kmag = v.value_quaternion->kmag;
			return exact_value_quaternion(-real, -imag, -jmag, -kmag);
		}
		}
		break;
	}

	case Token_Xor: {
		switch (v.kind) {
		case ExactValue_Invalid:
			return v;
		case ExactValue_Integer: {
			GB_ASSERT(precision != 0);
			ExactValue i = {ExactValue_Integer};
			i.value_integer = {0};
			big_int_not(&i.value_integer, &v.value_integer, precision, !is_unsigned);
			return i;
		}
		default:
			goto failure;
		}
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

failure:;
	ExactValue error_value = {};
	return error_value;
}

// NOTE(bill): Make sure things are evaluated in correct order
gb_internal i32 exact_value_order(ExactValue const &v) {
	switch (v.kind) {
	case ExactValue_Invalid:
	case ExactValue_Compound:
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
	case ExactValue_Quaternion:
		return 5;
	case ExactValue_Pointer:
		return 6;
	case ExactValue_Procedure:
		return 7;

	default:
		GB_PANIC("How'd you get here? Invalid Value.kind %d", v.kind);
		return -1;
	}
}

gb_internal void match_exact_values(ExactValue *x, ExactValue *y) {
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
	case ExactValue_Quaternion:
	case ExactValue_Pointer:
	case ExactValue_Compound:
	case ExactValue_Procedure:
	case ExactValue_Typeid:
		return;

	case ExactValue_Integer:
		switch (y->kind) {
		case ExactValue_Integer:
			return;
		case ExactValue_Float:
			// TODO(bill): Is this good enough?
			*x = exact_value_float(big_int_to_f64(&x->value_integer));
			return;
		case ExactValue_Complex:
			*x = exact_value_complex(big_int_to_f64(&x->value_integer), 0);
			return;
		case ExactValue_Quaternion:
			*x = exact_value_quaternion(big_int_to_f64(&x->value_integer), 0, 0, 0);
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
		case ExactValue_Quaternion:
			*x = exact_value_to_quaternion(*x);
			return;
		}
		break;

	case ExactValue_Complex:
		switch (y->kind) {
		case ExactValue_Complex:
			return;
		case ExactValue_Quaternion:
			*x = exact_value_to_quaternion(*x);
			return;
		}
		break;
	}

	compiler_error("match_exact_values: How'd you get here? Invalid ExactValueKind %d", x->kind);
}

gb_internal ExactValue exact_binary_operator_value(TokenKind op, ExactValue x, ExactValue y) {
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
		case Token_AndNot: return exact_value_bool(x.value_bool & !y.value_bool);
		case Token_Xor:    return exact_value_bool((x.value_bool && !y.value_bool) || (!x.value_bool && y.value_bool));
		default: goto error;
		}
		break;

	case ExactValue_Integer: {
		BigInt const *a = &x.value_integer;
		BigInt const *b = &y.value_integer;
		BigInt c = {};
		switch (op) {
		case Token_Add:    big_int_add(&c, a, b); break;
		case Token_Sub:    big_int_sub(&c, a, b); break;
		case Token_Mul:    big_int_mul(&c, a, b); break;
		case Token_Quo:    return exact_value_float(fmod(big_int_to_f64(a), big_int_to_f64(b)));
		case Token_QuoEq:  big_int_quo(&c, a, b); break; // NOTE(bill): Integer division
		case Token_Mod:    big_int_rem(&c, a, b); break;
		case Token_ModMod: big_int_euclidean_mod(&c, a, b); break;
		case Token_And:    big_int_and(&c, a, b);     break;
		case Token_Or:     big_int_or(&c, a, b);      break;
		case Token_Xor:    big_int_xor(&c, a, b);     break;
		case Token_AndNot: big_int_and_not(&c, a, b); break;
		case Token_Shl:    big_int_shl(&c, a, b);     break;
		case Token_Shr:    big_int_shr(&c, a, b);     break;
		default: goto error;
		}
		ExactValue res = {ExactValue_Integer};
		res.value_integer = c;
		return res;
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
		f64 a = x.value_complex->real;
		f64 b = x.value_complex->imag;
		f64 c = y.value_complex->real;
		f64 d = y.value_complex->imag;
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

	case ExactValue_Quaternion: {
		y = exact_value_to_quaternion(y);
		f64 xr = x.value_quaternion->real;
		f64 xi = x.value_quaternion->imag;
		f64 xj = x.value_quaternion->jmag;
		f64 xk = x.value_quaternion->kmag;
		f64 yr = y.value_quaternion->real;
		f64 yi = y.value_quaternion->imag;
		f64 yj = y.value_quaternion->jmag;
		f64 yk = y.value_quaternion->kmag;


		f64 real = 0;
		f64 imag = 0;
		f64 jmag = 0;
		f64 kmag = 0;

		switch (op) {
		case Token_Add:
			real = xr + yr;
			imag = xi + yi;
			jmag = xj + yj;
			kmag = xk + yk;
			break;
		case Token_Sub:
			real = xr - yr;
			imag = xi - yi;
			jmag = xj - yj;
			kmag = xk - yk;
			break;
		case Token_Mul:
			imag = xr * yi + xi * yr + xj * yk - xk * yj;
			jmag = xr * yj - xi * yk + xj * yr + xk * yi;
			kmag = xr * yk + xi * yj - xj * yi + xk * yr;
			real = xr * yr - xi * yi - xj * yj - xk * yk;
			break;
		case Token_Quo: {
			f64 invmag2 = 1.0 / (yr*yr + yi*yi + yj*yj + yk*yk);
			imag = (xr * -yi + xi * +yr + xj * -yk - xk * -yj) * invmag2;
			jmag = (xr * -yj - xi * -yk + xj * +yr + xk * -yi) * invmag2;
			kmag = (xr * -yk + xi * -yj - xj * -yi + xk * +yr) * invmag2;
			real = (xr * +yr - xi * -yi - xj * -yj - xk * -yk) * invmag2;
			break;
		}
		default: goto error;
		}
		return exact_value_quaternion(real, imag, jmag, kmag);
		break;
	}

	case ExactValue_String: {
		if (op != Token_Add) goto error;

		// NOTE(bill): How do you minimize this over allocation?
		String sx = x.value_string;
		String sy = y.value_string;
		isize len = sx.len+sy.len;
		u8 *data = gb_alloc_array(permanent_allocator(), u8, len);
		gb_memmove(data,        sx.text, sx.len);
		gb_memmove(data+sx.len, sy.text, sy.len);
		return exact_value_string(make_string(data, len));
		break;
	}
	}

error:; // NOTE(bill): MSVC accepts this??? apparently you cannot declare variables immediately after labels...
	return empty_exact_value;
}

gb_internal gb_inline ExactValue exact_value_add(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Add, x, y);
}
gb_internal gb_inline ExactValue exact_value_sub(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Sub, x, y);
}
gb_internal gb_inline ExactValue exact_value_mul(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Mul, x, y);
}
gb_internal gb_inline ExactValue exact_value_quo(ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(Token_Quo, x, y);
}
gb_internal gb_inline ExactValue exact_value_shift(TokenKind op, ExactValue const &x, ExactValue const &y) {
	return exact_binary_operator_value(op, x, y);
}

gb_internal gb_inline ExactValue exact_value_increment_one(ExactValue const &x) {
	return exact_binary_operator_value(Token_Add, x, exact_value_i64(1));
}


gb_internal gb_inline i32 cmp_f64(f64 a, f64 b) {
	return (a > b) - (a < b);
}

gb_internal bool compare_exact_values(TokenKind op, ExactValue x, ExactValue y) {
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
		i32 cmp = big_int_cmp(&x.value_integer, &y.value_integer);
		switch (op) {
		case Token_CmpEq: return cmp == 0;
		case Token_NotEq: return cmp != 0;
		case Token_Lt:    return cmp <  0;
		case Token_LtEq:  return cmp <= 0;
		case Token_Gt:    return cmp >  0;
		case Token_GtEq:  return cmp >= 0;
		}
		break;
	}

	case ExactValue_Float: {
		f64 a = x.value_float;
		f64 b = y.value_float;
		if (isnan(a) || isnan(b)) {
			return false; // Fixes #5004
		}

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
		f64 a = x.value_complex->real;
		f64 b = x.value_complex->imag;
		f64 c = y.value_complex->real;
		f64 d = y.value_complex->imag;
		switch (op) {
		case Token_CmpEq: return cmp_f64(a, c) == 0 && cmp_f64(b, d) == 0;
		case Token_NotEq: return cmp_f64(a, c) != 0 || cmp_f64(b, d) != 0;
		}
		break;
	}

	case ExactValue_String: {
		String a = x.value_string;
		String b = y.value_string;
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

	case ExactValue_Pointer: {
		switch (op) {
		case Token_CmpEq: return x.value_pointer == y.value_pointer;
		case Token_NotEq: return x.value_pointer != y.value_pointer;
		case Token_Lt:    return x.value_pointer <  y.value_pointer;
		case Token_LtEq:  return x.value_pointer <= y.value_pointer;
		case Token_Gt:    return x.value_pointer >  y.value_pointer;
		case Token_GtEq:  return x.value_pointer >= y.value_pointer;
		}
	}

	case ExactValue_Typeid:
		switch (op) {
		case Token_CmpEq: return x.value_typeid == y.value_typeid;
		case Token_NotEq: return x.value_typeid != y.value_typeid;
		}
		break;

	case ExactValue_Procedure:
		switch (op) {
		case Token_CmpEq: return x.value_typeid == y.value_typeid;
		case Token_NotEq: return x.value_typeid != y.value_typeid;
		}
		break;
	}

	GB_PANIC("Invalid comparison");
	return false;
}

gb_internal Entity *strip_entity_wrapping(Ast *expr);
gb_internal Entity *strip_entity_wrapping(Entity *e);

gb_internal gbString write_expr_to_string(gbString str, Ast *node, bool shorthand);

gb_internal gbString write_exact_value_to_string(gbString str, ExactValue const &v, isize string_limit=36) {
	switch (v.kind) {
	case ExactValue_Invalid:
		return str;
	case ExactValue_Bool:
		return gb_string_appendc(str, v.value_bool ? "true" : "false");
	case ExactValue_String: {
		String s = quote_to_ascii(heap_allocator(), v.value_string);
		string_limit = gb_max(string_limit, 36);
		if (s.len <= string_limit) {
			str = gb_string_append_length(str, s.text, s.len);
		} else {
			isize n = string_limit/5;
			str = gb_string_append_length(str, s.text, n);
			str = gb_string_append_fmt(str, "\"..%lld chars..\"", s.len-(2*n));
			str = gb_string_append_length(str, s.text+s.len-n, n);
		}
		gb_free(heap_allocator(), s.text);
		return str;
	}
	case ExactValue_Integer: {
		String s = big_int_to_string(heap_allocator(), &v.value_integer);
		str = gb_string_append_length(str, s.text, s.len);
		gb_free(heap_allocator(), s.text);
		return str;
	}
	case ExactValue_Float:
		return gb_string_append_fmt(str, "%f", v.value_float);
	case ExactValue_Complex:
		return gb_string_append_fmt(str, "%f+%fi", v.value_complex->real, v.value_complex->imag);
	case ExactValue_Quaternion:
		return gb_string_append_fmt(str, "%f+%fi+%fj+%fk", v.value_quaternion->real, v.value_quaternion->imag, v.value_quaternion->jmag, v.value_quaternion->kmag);

	case ExactValue_Pointer:
		return str;
	case ExactValue_Compound:
		return write_expr_to_string(str, v.value_compound, false);
	case ExactValue_Procedure:
		return write_expr_to_string(str, v.value_procedure, false);
	}
	return str;
};

gb_internal gbString exact_value_to_string(ExactValue const &v, isize string_limit=36) {
	return write_exact_value_to_string(gb_string_make(heap_allocator(), ""), v, string_limit);
}
