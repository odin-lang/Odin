#include <math.h>
#include <stdlib.h>

struct Ast;
struct HashKey;
struct Type;
struct Entity;
gb_internal bool are_types_identical(Type *x, Type *y);

// NOTE(bill): Defined after ExactValue below, since their components are now exact values
// (each a Float=f64 or Rational=big_rat) so complex/quaternion constant folding stays exact.
struct ExactComplex;
struct ExactQuaternion;

enum ExactValueKind {
	ExactValue_Invalid     = 0,

	ExactValue_Bool        = 1,
	ExactValue_String      = 2,
	ExactValue_Integer     = 3,
	ExactValue_Float       = 4,
	ExactValue_Complex     = 5,
	ExactValue_Quaternion  = 6,
	ExactValue_Pointer     = 7,
	ExactValue_Compound    = 8,
	ExactValue_Procedure   = 9,
	ExactValue_Typeid      = 10,
	ExactValue_String16    = 11,
	ExactValue_AsmTemplate = 12,
	ExactValue_Variant     = 13,
	ExactValue_Rational    = 14, // exact num/den for untyped float constants

	ExactValue_Count,
};

gb_global char const *exact_value_kind_string[ExactValue_Count] = {
	"Invalid",

	"Bool",
	"String",
	"Integer",
	"Float",
	"Complex",
	"Quaternion",
	"Pointer",
	"Compound",
	"Procedure",
	"Typeid",
	"String16",
	"AsmTemplate",
	"Variant",
	"Rational",
};

struct ExactValue {
	ExactValueKind kind;
	union {
		bool             value_bool;
		String           value_string;
		BigInt           value_integer;
		f64              value_float;
		BigRat *         value_rational;
		i64              value_pointer; // NOTE(bill): This must be an integer and not a pointer
		ExactComplex    *value_complex;
		ExactQuaternion *value_quaternion;
		Ast *            value_compound;
		Ast *            value_procedure;
		Type *           value_typeid;
		String16         value_string16;
		Ast *            value_asm_template;
		Ast *            value_variant;
	};
	Type *variant_type;
};

// Complex/quaternion components are exact numeric values (Integer/Rational/Float), so their constant
// arithmetic keeps full precision until the value is rounded to a concrete type.
struct ExactComplex {
	ExactValue real, imag;
};
struct ExactQuaternion {
	ExactValue imag, jmag, kmag, real;
};

gb_global ExactValue const empty_exact_value = {};

gb_internal uintptr hash_exact_value(ExactValue v) {
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
	case ExactValue_String16:
		res = gb_fnv32a(v.value_string.text, v.value_string.len*gb_size_of(u16));
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
	case ExactValue_Rational:
		{
			BigInt const &n = v.value_rational->num;
			BigInt const &d = v.value_rational->den;
			u32 kn = gb_fnv32a(n.dp, gb_size_of(*n.dp) * n.used);
			u32 kd = gb_fnv32a(d.dp, gb_size_of(*d.dp) * d.used);
			res = ((kn ^ (u8)n.sign) * 0x01000193) ^ kd;
			break;
		}
	case ExactValue_Pointer:
		res = ptr_map_hash_key(v.value_pointer);
		break;
	case ExactValue_Complex:
		res = hash_exact_value(v.value_complex->real) ^
		      (hash_exact_value(v.value_complex->imag) * 0x01000193);
		break;
	case ExactValue_Quaternion:
		res = hash_exact_value(v.value_quaternion->real) ^
		      (hash_exact_value(v.value_quaternion->imag) * 0x01000193) ^
		      (hash_exact_value(v.value_quaternion->jmag) * 0x01000193) ^
		      (hash_exact_value(v.value_quaternion->kmag) * 0x01000193);
		break;
	case ExactValue_Compound:
		res = ptr_map_hash_key(v.value_compound);
		break;
	case ExactValue_Procedure:
		res = ptr_map_hash_key(v.value_procedure);
		break;
	case ExactValue_AsmTemplate:
		res = ptr_map_hash_key(v.value_asm_template);
		break;
	case ExactValue_Typeid:
		res = ptr_map_hash_key(v.value_typeid);
		break;
	case ExactValue_Variant:
		res = ptr_map_hash_key(v.value_variant);
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
gb_internal ExactValue exact_value_string16(String16 string) {
	ExactValue result = {ExactValue_String16};
	result.value_string16 = string;
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

// Make an exact-rational value from num/den (copied and reduced to lowest terms, den > 0).
gb_internal ExactValue exact_value_rational_from_ints(mp_int const *num, mp_int const *den) {
	BigRat *br = permanent_alloc_item<BigRat>();
	mp_init(&br->num);
	mp_init(&br->den);
	mp_copy(num, &br->num);
	mp_copy(den, &br->den);
	big_rat_normalize(&br->num, &br->den);

	ExactValue result = {ExactValue_Rational};
	result.value_rational = br;
	return result;
}

gb_internal ExactValue exact_value_rational_from_integer(BigInt const *i) {
	mp_int one; mp_init(&one); defer (mp_clear(&one)); mp_set_u64(&one, 1);
	return exact_value_rational_from_ints(i, &one);
}

gb_internal ExactValue exact_value_rational_arith_result(mp_int const *num, mp_int const *den) {
	ExactValue r = exact_value_rational_from_ints(num, den); // normalizes (GCD reduce)
	if (big_rat_components_too_large(&r.value_rational->num, &r.value_rational->den)) {
		return exact_value_float(big_rat_to_f64(&r.value_rational->num, &r.value_rational->den));
	}
	return r;
}

gb_internal ExactValue exact_value_as_rational_if_integer(ExactValue v) {
	if (v.kind == ExactValue_Integer) {
		return exact_value_rational_from_integer(&v.value_integer);
	}
	return v;
}

// Exact-component constructors: each component is a numeric ExactValue (Integer/Rational/Float).
gb_internal ExactValue exact_value_complex_ev(ExactValue real, ExactValue imag) {
	ExactValue result = {ExactValue_Complex};
	result.value_complex = permanent_alloc_item<ExactComplex>();
	result.value_complex->real = real;
	result.value_complex->imag = imag;
	return result;
}
gb_internal ExactValue exact_value_quaternion_ev(ExactValue real, ExactValue imag, ExactValue jmag, ExactValue kmag) {
	ExactValue result = {ExactValue_Quaternion};
	result.value_quaternion = permanent_alloc_item<ExactQuaternion>();
	result.value_quaternion->real = real;
	result.value_quaternion->imag = imag;
	result.value_quaternion->jmag = jmag;
	result.value_quaternion->kmag = kmag;
	return result;
}

gb_internal ExactValue exact_value_complex(f64 real, f64 imag) {
	return exact_value_complex_ev(exact_value_float(real), exact_value_float(imag));
}

gb_internal ExactValue exact_value_quaternion(f64 real, f64 imag, f64 jmag, f64 kmag) {
	return exact_value_quaternion_ev(exact_value_float(real), exact_value_float(imag), exact_value_float(jmag), exact_value_float(kmag));
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

gb_internal ExactValue exact_value_variant(Ast *node) {
	ExactValue result = {ExactValue_Variant};
	result.value_variant = node;
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
			// GB_PANIC("Invalid hexadecimal float, expected 4, 8, or 16 digits, got %td", digit_count);
			// NOTE(bill): This should be caught by the tokenizer, so just pretend it's an f64
			f64 f = bit_cast<f64>(u);
			return exact_value_float(f);
		}
	}

	if (!string_contains_char(string, '.') && !string_contains_char(string, '-')) {
		// NOTE(bill): treat as integer
		return exact_value_integer_from_string(string);
	}

	// A finite base-10 floating-point literal is kept as an EXACT rational so that constant folding is
	// exact and only rounds once, when the constant is finally given a concrete type (see
	// `exact_value_to_float` and `check_representable_as_constant`). This mirrors Go's `go/constant`,
	// where small values are held as `big.Rat`. The `0h...` hexadecimal-float path above keeps its
	// exact bit pattern as an `f64`; that is also the side channel for the +/-Inf and NaN values that a
	// rational cannot represent.
	mp_int num, den;
	if (big_rat_from_decimal_string(string, &num, &den)) {
		// A zero-valued literal stays an f64 so that signed zero survives: a rational 0/1 has no sign,
		// but `-0.0` (unary minus applied to this `0.0`) must keep its sign bit.
		bool is_zero = mp_iszero(&num);
		if (is_zero) {
			mp_clear(&num);
			mp_clear(&den);
			return exact_value_float(0.0);
		}
		ExactValue r = exact_value_rational_from_ints(&num, &den);
		mp_clear(&num);
		mp_clear(&den);
		return r;
	}
	return {ExactValue_Invalid};
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
		// Parse the magnitude with the same exact (rational) path as an ordinary float literal so the
		// imaginary component keeps full precision rather than being pre-rounded to f64.
		ExactValue imag = exact_value_float_from_string(str);
		ExactValue zero = exact_value_i64(0);

		switch (last_rune) {
		case 'i': return exact_value_complex_ev(zero, imag);
		case 'j': return exact_value_quaternion_ev(zero, zero, imag, zero);
		case 'k': return exact_value_quaternion_ev(zero, zero, zero, imag);
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
		f64 const min = cast(f64)I64_MIN; // -2^63
		f64 const max = -min;             // 2^63, one past I64_MAX
		// NOTE: the conversion below is undefined outside of this range, NaN included
		if (!(v.value_float >= min && v.value_float < max)) {
			break;
		}
		i64 i = cast(i64)v.value_float;
		f64 f = cast(f64)i;
		if (f == v.value_float) {
			return exact_value_i64(i);
		}
		break;
	}

	case ExactValue_Pointer:
		return exact_value_i64(cast(i64)cast(intptr)v.value_pointer);

	case ExactValue_Rational:
		// NOTE(bill): Only an exact integer (den == 1 after reduction) converts to an integer
		if (mp_cmp_d(&v.value_rational->den, 1) == MP_EQ) {
			ExactValue r = {ExactValue_Integer};
			r.value_integer = {0};
			mp_init(&r.value_integer);
			mp_copy(&v.value_rational->num, &r.value_integer);
			return r;
		}
		break;
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
	case ExactValue_Rational:
		return exact_value_float(big_rat_to_f64(&v.value_rational->num, &v.value_rational->den));
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_to_complex(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Rational:
		return exact_value_complex_ev(v, exact_value_i64(0)); // keep the real component exact
	case ExactValue_Complex:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}
gb_internal ExactValue exact_value_to_quaternion(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Rational:
		return exact_value_quaternion_ev(v, exact_value_i64(0), exact_value_i64(0), exact_value_i64(0));
	case ExactValue_Complex:
		return exact_value_quaternion_ev(v.value_complex->real, v.value_complex->imag, exact_value_i64(0), exact_value_i64(0));
	case ExactValue_Quaternion:
		return v;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_real(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Rational:
		return v;
	case ExactValue_Complex:
		return v.value_complex->real;
	case ExactValue_Quaternion:
		return v.value_quaternion->real;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_imag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Rational:
		return exact_value_i64(0);
	case ExactValue_Complex:
		return v.value_complex->imag;
	case ExactValue_Quaternion:
		return v.value_quaternion->imag;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_jmag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Rational:
	case ExactValue_Complex:
		return exact_value_i64(0);
	case ExactValue_Quaternion:
		return v.value_quaternion->jmag;
	}
	ExactValue r = {ExactValue_Invalid};
	return r;
}

gb_internal ExactValue exact_value_kmag(ExactValue v) {
	switch (v.kind) {
	case ExactValue_Integer:
	case ExactValue_Float:
	case ExactValue_Rational:
	case ExactValue_Complex:
		return exact_value_i64(0);
	case ExactValue_Quaternion:
		return v.value_quaternion->kmag;
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
		case ExactValue_Rational:
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
		case ExactValue_Rational: {
			mp_int n; mp_init(&n); defer (mp_clear(&n));
			big_int_neg(&n, &v.value_rational->num);
			return exact_value_rational_from_ints(&n, &v.value_rational->den);
		}
		case ExactValue_Complex: {
			ExactValue re = exact_unary_operator_value(Token_Sub, v.value_complex->real, precision, is_unsigned);
			ExactValue im = exact_unary_operator_value(Token_Sub, v.value_complex->imag, precision, is_unsigned);
			return exact_value_complex_ev(re, im);
		}
		case ExactValue_Quaternion: {
			ExactValue re = exact_unary_operator_value(Token_Sub, v.value_quaternion->real, precision, is_unsigned);
			ExactValue im = exact_unary_operator_value(Token_Sub, v.value_quaternion->imag, precision, is_unsigned);
			ExactValue jm = exact_unary_operator_value(Token_Sub, v.value_quaternion->jmag, precision, is_unsigned);
			ExactValue km = exact_unary_operator_value(Token_Sub, v.value_quaternion->kmag, precision, is_unsigned);
			return exact_value_quaternion_ev(re, im, jm, km);
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
	case ExactValue_Variant:
		return 0;
	case ExactValue_Bool:
	case ExactValue_String:
	case ExactValue_String16:
		return 1;
	case ExactValue_Integer:
		return 2;
	case ExactValue_Rational: // exact; between integer and (lossy) float
		return 3;
	case ExactValue_Float:
		return 4;
	case ExactValue_Complex:
		return 5;
	case ExactValue_Quaternion:
		return 6;
	case ExactValue_Pointer:
		return 7;
	case ExactValue_Procedure:
		return 8;

	default:
		GB_PANIC("How'd you get here? Invalid Value.kind %d", v.kind);
		return -1;
	}
}

gb_internal void match_exact_values_variant(ExactValue *x, ExactValue *y);

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
	case ExactValue_String16:
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
		case ExactValue_Rational:
			// Promote the integer to an exact rational so folding stays exact.
			*x = exact_value_rational_from_integer(&x->value_integer);
			return;
		case ExactValue_Float:
			// TODO(bill): Is this good enough?
			*x = exact_value_float(big_int_to_f64(&x->value_integer));
			return;
		case ExactValue_Complex:
			*x = exact_value_to_complex(*x);    // keep the integer component exact
			return;
		case ExactValue_Quaternion:
			*x = exact_value_to_quaternion(*x); // keep the integer component exact
			return;
		}
		break;

	case ExactValue_Rational:
		switch (y->kind) {
		case ExactValue_Rational:
			return;
		case ExactValue_Float:
			*x = exact_value_to_float(*x);
			return;
		case ExactValue_Complex:
			*x = exact_value_to_complex(*x);
			return;
		case ExactValue_Quaternion:
			*x = exact_value_to_quaternion(*x);
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

	case ExactValue_Variant:
		match_exact_values_variant(x, y);
		return;
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
		case Token_ModMod: big_int_mod_mod(&c, a, b); break;
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

	case ExactValue_Rational: {
		// Exact rational arithmetic: a/b (op) c/d, result reduced to lowest terms.
		mp_int const *an = &x.value_rational->num, *ad = &x.value_rational->den;
		mp_int const *bn = &y.value_rational->num, *bd = &y.value_rational->den;
		mp_int nn, nd, t1, t2;
		mp_init(&nn); mp_init(&nd); mp_init(&t1); mp_init(&t2);
		defer (mp_clear(&nn)); defer (mp_clear(&nd)); defer (mp_clear(&t1)); defer (mp_clear(&t2));
		switch (op) {
		case Token_Add: // (an*bd + bn*ad) / (ad*bd)
			big_int_mul(&t1, an, bd); big_int_mul(&t2, bn, ad); big_int_add(&nn, &t1, &t2); big_int_mul(&nd, ad, bd); break;
		case Token_Sub:
			big_int_mul(&t1, an, bd); big_int_mul(&t2, bn, ad); big_int_sub(&nn, &t1, &t2); big_int_mul(&nd, ad, bd); break;
		case Token_Mul:
			big_int_mul(&nn, an, bn); big_int_mul(&nd, ad, bd); break;
		case Token_Quo: // (an/ad) / (bn/bd) = (an*bd) / (ad*bn)
			big_int_mul(&nn, an, bd); big_int_mul(&nd, ad, bn); break;
		default: goto error;
		}
		return exact_value_rational_arith_result(&nn, &nd);
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
		// Exact per-component arithmetic (each component is an Integer/Rational/Float ExactValue).
		#define EV_MUL(p, q) exact_binary_operator_value(Token_Mul, (p), (q))
		#define EV_ADD(p, q) exact_binary_operator_value(Token_Add, (p), (q))
		#define EV_SUB(p, q) exact_binary_operator_value(Token_Sub, (p), (q))
		#define EV_QUO(p, q) exact_binary_operator_value(Token_Quo, exact_value_as_rational_if_integer(p), exact_value_as_rational_if_integer(q))
		y = exact_value_to_complex(y);
		ExactValue a = x.value_complex->real;
		ExactValue b = x.value_complex->imag;
		ExactValue c = y.value_complex->real;
		ExactValue d = y.value_complex->imag;
		ExactValue real = {};
		ExactValue imag = {};
		switch (op) {
		case Token_Add:
			real = EV_ADD(a, c);
			imag = EV_ADD(b, d);
			break;
		case Token_Sub:
			real = EV_SUB(a, c);
			imag = EV_SUB(b, d);
			break;
		case Token_Mul:
			real = EV_SUB(EV_MUL(a, c), EV_MUL(b, d)); // a*c - b*d
			imag = EV_ADD(EV_MUL(b, c), EV_MUL(a, d)); // b*c + a*d
			break;
		case Token_Quo: {
			ExactValue s = EV_ADD(EV_MUL(c, c), EV_MUL(d, d));   // c*c + d*d
			real = EV_QUO(EV_ADD(EV_MUL(a, c), EV_MUL(b, d)), s); // (a*c + b*d)/s
			imag = EV_QUO(EV_SUB(EV_MUL(b, c), EV_MUL(a, d)), s); // (b*c - a*d)/s
			break;
		}
		default: goto error;
		}
		return exact_value_complex_ev(real, imag);
		#undef EV_MUL
		#undef EV_ADD
		#undef EV_SUB
		#undef EV_QUO
	}

	case ExactValue_Quaternion: {
		#define EV_MUL(p, q) exact_binary_operator_value(Token_Mul, (p), (q))
		#define EV_ADD(p, q) exact_binary_operator_value(Token_Add, (p), (q))
		#define EV_SUB(p, q) exact_binary_operator_value(Token_Sub, (p), (q))
		#define EV_QUO(p, q) exact_binary_operator_value(Token_Quo, exact_value_as_rational_if_integer(p), exact_value_as_rational_if_integer(q))
		#define EV_NEG(p)    exact_unary_operator_value(Token_Sub, (p), 0, false)
		y = exact_value_to_quaternion(y);
		ExactValue xr = x.value_quaternion->real;
		ExactValue xi = x.value_quaternion->imag;
		ExactValue xj = x.value_quaternion->jmag;
		ExactValue xk = x.value_quaternion->kmag;
		ExactValue yr = y.value_quaternion->real;
		ExactValue yi = y.value_quaternion->imag;
		ExactValue yj = y.value_quaternion->jmag;
		ExactValue yk = y.value_quaternion->kmag;

		ExactValue real = {};
		ExactValue imag = {};
		ExactValue jmag = {};
		ExactValue kmag = {};

		switch (op) {
		case Token_Add:
			real = EV_ADD(xr, yr); imag = EV_ADD(xi, yi); jmag = EV_ADD(xj, yj); kmag = EV_ADD(xk, yk);
			break;
		case Token_Sub:
			real = EV_SUB(xr, yr); imag = EV_SUB(xi, yi); jmag = EV_SUB(xj, yj); kmag = EV_SUB(xk, yk);
			break;
		case Token_Mul:
			// Hamilton product (matches the previous f64 formulas term-for-term).
			imag = EV_SUB(EV_ADD(EV_ADD(EV_MUL(xr, yi), EV_MUL(xi, yr)), EV_MUL(xj, yk)), EV_MUL(xk, yj));
			jmag = EV_ADD(EV_ADD(EV_SUB(EV_MUL(xr, yj), EV_MUL(xi, yk)), EV_MUL(xj, yr)), EV_MUL(xk, yi));
			kmag = EV_ADD(EV_SUB(EV_ADD(EV_MUL(xr, yk), EV_MUL(xi, yj)), EV_MUL(xj, yi)), EV_MUL(xk, yr));
			real = EV_SUB(EV_SUB(EV_SUB(EV_MUL(xr, yr), EV_MUL(xi, yi)), EV_MUL(xj, yj)), EV_MUL(xk, yk));
			break;
		case Token_Quo: {
			// q1 / q2 = q1 * conj(q2) / |q2|^2
			ExactValue nyi = EV_NEG(yi), nyj = EV_NEG(yj), nyk = EV_NEG(yk);
			ExactValue mag2 = EV_ADD(EV_ADD(EV_ADD(EV_MUL(yr, yr), EV_MUL(yi, yi)), EV_MUL(yj, yj)), EV_MUL(yk, yk));
			imag = EV_SUB(EV_ADD(EV_ADD(EV_MUL(xr, nyi), EV_MUL(xi, yr)), EV_MUL(xj, nyk)), EV_MUL(xk, nyj));
			jmag = EV_ADD(EV_ADD(EV_SUB(EV_MUL(xr, nyj), EV_MUL(xi, nyk)), EV_MUL(xj, yr)), EV_MUL(xk, nyi));
			kmag = EV_ADD(EV_SUB(EV_ADD(EV_MUL(xr, nyk), EV_MUL(xi, nyj)), EV_MUL(xj, nyi)), EV_MUL(xk, yr));
			real = EV_SUB(EV_SUB(EV_SUB(EV_MUL(xr, yr), EV_MUL(xi, nyi)), EV_MUL(xj, nyj)), EV_MUL(xk, nyk));
			imag = EV_QUO(imag, mag2);
			jmag = EV_QUO(jmag, mag2);
			kmag = EV_QUO(kmag, mag2);
			real = EV_QUO(real, mag2);
			break;
		}
		default: goto error;
		}
		return exact_value_quaternion_ev(real, imag, jmag, kmag);
		#undef EV_MUL
		#undef EV_ADD
		#undef EV_SUB
		#undef EV_QUO
		#undef EV_NEG
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
	}
	case ExactValue_String16: {
		if (op != Token_Add) goto error;

		// NOTE(bill): How do you minimize this over allocation?
		String16 sx = x.value_string16;
		String16 sy = y.value_string16;
		isize len = sx.len+sy.len;
		u16 *data = gb_alloc_array(permanent_allocator(), u16, len);
		gb_memmove(data,        sx.text, sx.len*gb_size_of(u16));
		gb_memmove(data+sx.len, sy.text, sy.len*gb_size_of(u16));
		return exact_value_string16(make_string16(data, len));
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

gb_internal bool compare_exact_values_compound_lit(TokenKind op, ExactValue x, ExactValue y);
gb_internal bool compare_exact_values_variant(TokenKind op, ExactValue x, ExactValue y);

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

	case ExactValue_Rational: {
		// a/b (op) c/d with b,d > 0  <=>  a*d (op) c*b
		mp_int lhs, rhs; mp_init(&lhs); mp_init(&rhs); defer (mp_clear(&lhs)); defer (mp_clear(&rhs));
		big_int_mul(&lhs, &x.value_rational->num, &y.value_rational->den);
		big_int_mul(&rhs, &y.value_rational->num, &x.value_rational->den);
		i32 cmp = big_int_cmp(&lhs, &rhs);
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
			return op == Token_NotEq;
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
		// Compare component-wise using exact comparisons (each component is a numeric ExactValue).
		ExactComplex a = *x.value_complex;
		ExactComplex b = *y.value_complex;
		bool real_eq = compare_exact_values(Token_CmpEq, a.real, b.real);
		bool imag_eq = compare_exact_values(Token_CmpEq, a.imag, b.imag);
		switch (op) {
		case Token_CmpEq: return real_eq && imag_eq;
		case Token_NotEq: return !real_eq || !imag_eq;
		}
		break;
	}

	case ExactValue_Quaternion: {
		ExactQuaternion a = *x.value_quaternion;
		ExactQuaternion b = *y.value_quaternion;
		bool real_eq = compare_exact_values(Token_CmpEq, a.real, b.real);
		bool imag_eq = compare_exact_values(Token_CmpEq, a.imag, b.imag);
		bool jmag_eq = compare_exact_values(Token_CmpEq, a.jmag, b.jmag);
		bool kmag_eq = compare_exact_values(Token_CmpEq, a.kmag, b.kmag);
		switch (op) {
		case Token_CmpEq: return real_eq && imag_eq && jmag_eq && kmag_eq;
		case Token_NotEq: return !real_eq || !imag_eq || !jmag_eq || !kmag_eq;
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
	case ExactValue_String16: {
		String16 a = x.value_string16;
		String16 b = y.value_string16;
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
		case Token_CmpEq: return x.value_procedure == y.value_procedure;
		case Token_NotEq: return x.value_procedure != y.value_procedure;
		}
		break;

	case ExactValue_Compound:
		if (op != Token_CmpEq && op != Token_NotEq) {
			return false;
		}

		if (x.kind != y.kind) {
			return false;
		}
		return compare_exact_values_compound_lit(op, x, y);

	case ExactValue_Variant:
		if (op != Token_CmpEq && op != Token_NotEq) {
			return false;
		}

		if (x.kind != y.kind) {
			return op == Token_NotEq;
		}
		return compare_exact_values_variant(op, x, y);
	}

	GB_PANIC("Invalid comparison: %d", x.kind);
	return false;
}

gb_internal Entity *strip_entity_wrapping(Ast *expr);
gb_internal Entity *strip_entity_wrapping(Entity *e);

gb_internal gbString write_expr_to_string(gbString str, Ast *node, bool shorthand);

gb_internal gbString write_exact_value_to_string(gbString str, ExactValue const &v, isize string_limit);

gb_internal gbString write_exact_complex_component_to_string(gbString str, ExactValue comp, isize string_limit) {
	f64 f = exact_value_to_f64(comp);

	// The float formatter cannot render a magnitude at or beyond 2**63 (it prints 2**63's digits on a
	// loop), and that also catches Inf/NaN since the range test below is false for them. For an exact
	// integer/rational component that large, print its exact form (digits, or `num.0/den`) instead.
	static f64 const LIMIT = 9223372036854775808.0; // 2**63
	bool formatter_safe = (f >= -LIMIT) && (f <= LIMIT);
	if (!formatter_safe && (comp.kind == ExactValue_Integer || comp.kind == ExactValue_Rational)) {
		return write_exact_value_to_string(str, comp, string_limit);
	}
	return gb_string_append_fmt(str, "%.17g", f);
}

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
	case ExactValue_String16: {
		String s = quote_to_ascii(heap_allocator(), v.value_string16);
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
	// NOTE(tf2spi): %.17g is specific enough to canonically serialize f64
	case ExactValue_Float:
		return gb_string_append_fmt(str, "%.17g", v.value_float);
	case ExactValue_Rational:
		// Integer-valued (den == 1, e.g. an overflowing literal like `1.0e400`) prints its exact decimal,
		// so a diagnostic shows the real magnitude rather than an f64 that has rounded to +Inf.
		if (mp_cmp_d(&v.value_rational->den, 1) == MP_EQ) {
			String s = big_int_to_string(heap_allocator(), &v.value_rational->num);
			str = gb_string_append_length(str, s.text, s.len);
			gb_free(heap_allocator(), s.text);
			return str;
		}
		// Non-integer: print the exact fraction as `<num>.0/<den>` (e.g. `1.0/3`). The `.0` on the
		// numerator marks it as a decimal division, so it reads as the float `1.0/3` rather than the
		// integer division `1/3` (which would be 0), and it round-trips as valid Odin source.
		{
			String ns = big_int_to_string(heap_allocator(), &v.value_rational->num);
			String ds = big_int_to_string(heap_allocator(), &v.value_rational->den);
			str = gb_string_append_length(str, ns.text, ns.len);
			str = gb_string_append_fmt(str, ".0/");
			str = gb_string_append_length(str, ds.text, ds.len);
			gb_free(heap_allocator(), ns.text);
			gb_free(heap_allocator(), ds.text);
			return str;
		}
	case ExactValue_Complex:
		str = write_exact_complex_component_to_string(str, v.value_complex->real, string_limit);
		str = gb_string_append_fmt(str, "+");
		str = write_exact_complex_component_to_string(str, v.value_complex->imag, string_limit);
		return gb_string_append_fmt(str, "i");
	case ExactValue_Quaternion:
		str = write_exact_complex_component_to_string(str, v.value_quaternion->real, string_limit);
		str = gb_string_append_fmt(str, "+");
		str = write_exact_complex_component_to_string(str, v.value_quaternion->imag, string_limit);
		str = gb_string_append_fmt(str, "i+");
		str = write_exact_complex_component_to_string(str, v.value_quaternion->jmag, string_limit);
		str = gb_string_append_fmt(str, "j+");
		str = write_exact_complex_component_to_string(str, v.value_quaternion->kmag, string_limit);
		return gb_string_append_fmt(str, "k");

	case ExactValue_Pointer:
		return str;
	case ExactValue_Compound:
		return write_expr_to_string(str, v.value_compound, false);
	case ExactValue_Procedure:
		return write_expr_to_string(str, v.value_procedure, false);
	case ExactValue_Variant:
		return write_expr_to_string(str, v.value_variant, false);
	}
	return str;
};

gb_internal gbString exact_value_to_string(ExactValue const &v, isize string_limit=36) {
	return write_exact_value_to_string(gb_string_make(heap_allocator(), ""), v, string_limit);
}
