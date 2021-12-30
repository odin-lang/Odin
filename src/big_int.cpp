#include "libtommath/tommath.h"

#if 0
void *MP_MALLOC(size_t size) {
	return malloc(size);
}
void *MP_REALLOC(void *mem, size_t oldsize, size_t newsize) {
	return realloc(mem, newsize);
}
void *MP_CALLOC(size_t nmemb, size_t size) {
	return calloc(nmemb, size);
}
void MP_FREE(void *mem, size_t size) {
	free(mem);
}
#else

void *MP_MALLOC(size_t size) {
	return gb_alloc(permanent_allocator(), cast(isize)size);
}
void *MP_REALLOC(void *mem, size_t oldsize, size_t newsize) {
	return gb_resize(permanent_allocator(), mem, cast(isize)oldsize, cast(isize)newsize);
}
void *MP_CALLOC(size_t nmemb, size_t size) {
	size_t total = nmemb*size;
	return gb_alloc(permanent_allocator(), cast(isize)total);
}
void MP_FREE(void *mem, size_t size) {
	// DO NOTHING
}
#endif


#ifndef MAX_BIG_INT_SHIFT
#define MAX_BIG_INT_SHIFT 1024
#endif

typedef mp_int BigInt;

void big_int_from_u64(BigInt *dst, u64 x);
void big_int_from_i64(BigInt *dst, i64 x);
void big_int_init    (BigInt *dst, BigInt const *src);
void big_int_from_string(BigInt *dst, String const &s);

void big_int_dealloc(BigInt *dst) {
	mp_clear(dst);
}

BigInt big_int_make(BigInt const *b, bool abs=false);
BigInt big_int_make_abs(BigInt const *b);
BigInt big_int_make_u64(u64 x);
BigInt big_int_make_i64(i64 x);

u64    big_int_to_u64   (BigInt const *x);
i64    big_int_to_i64   (BigInt const *x);
f64    big_int_to_f64   (BigInt const *x);
String big_int_to_string(gbAllocator allocator, BigInt const *x, u64 base = 10);

void big_int_add    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_sub    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_shl    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_shr    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_mul    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_mul_u64(BigInt *dst, BigInt const *x, u64 y);

void big_int_quo_rem(BigInt const *x, BigInt const *y, BigInt *q, BigInt *r);
void big_int_quo    (BigInt *z, BigInt const *x, BigInt const *y);
void big_int_rem    (BigInt *z, BigInt const *x, BigInt const *y);

void big_int_and    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_and_not(BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_xor    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_or     (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_not    (BigInt *dst, BigInt const *x, u64 bit_count, bool is_signed);


void big_int_add_eq(BigInt *dst, BigInt const *x);
void big_int_sub_eq(BigInt *dst, BigInt const *x);
void big_int_shl_eq(BigInt *dst, BigInt const *x);
void big_int_shr_eq(BigInt *dst, BigInt const *x);
void big_int_mul_eq(BigInt *dst, BigInt const *x);

void big_int_quo_eq(BigInt *dst, BigInt const *x);
void big_int_rem_eq(BigInt *dst, BigInt const *x);

bool big_int_is_neg(BigInt const *x);


void big_int_add_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_add(dst, &res, x);
}
void big_int_sub_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_sub(dst, &res, x);
}
void big_int_shl_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_shl(dst, &res, x);
}
void big_int_shr_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_shr(dst, &res, x);
}
void big_int_mul_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_mul(dst, &res, x);
}
void big_int_quo_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_quo(dst, &res, x);
}
void big_int_rem_eq(BigInt *dst, BigInt const *x) {
	BigInt res = {};
	big_int_init(&res, dst);
	big_int_rem(dst, &res, x);
}



i64 big_int_sign(BigInt const *x) {
	if (mp_iszero(x)) {
		return 0;
	}
	return x->sign == MP_ZPOS ? +1 : -1;
}


void big_int_from_u64(BigInt *dst, u64 x) {
	mp_init_u64(dst, x);
}
void big_int_from_i64(BigInt *dst, i64 x) {
	mp_init_i64(dst, x);

}
void big_int_init(BigInt *dst, BigInt const *src) {
	if (dst == src) {
		return;
	}
	mp_init_copy(dst, src);
}

BigInt big_int_make(BigInt const *b, bool abs) {
	BigInt i = {};
	big_int_init(&i, b);
	if (abs) mp_abs(&i, &i);
	return i;
}
BigInt big_int_make_abs(BigInt const *b) {
	return big_int_make(b, true);
}


BigInt big_int_make_u64(u64 x) {
	BigInt i = {};
	big_int_from_u64(&i, x);
	return i;
}
BigInt big_int_make_i64(i64 x) {
	BigInt i = {};
	big_int_from_i64(&i, x);
	return i;
}


void big_int_from_string(BigInt *dst, String const &s) {
	u64 base = 10;
	bool has_prefix = false;
	if (s.len > 2 && s[0] == '0') {
		switch (s[1]) {
		case 'b': base = 2;  has_prefix = true; break;
		case 'o': base = 8;  has_prefix = true; break;
		case 'd': base = 10; has_prefix = true; break;
		case 'z': base = 12; has_prefix = true; break;
		case 'x': base = 16; has_prefix = true; break;
		case 'h': base = 16; has_prefix = true; break;
		}
	}

	u8 *text = s.text;
	isize len = s.len;
	if (has_prefix) {
		text += 2;
		len -= 2;
	}

	BigInt b = {};
	big_int_from_u64(&b, base);
	mp_zero(dst);

	isize i = 0;
	for (; i < len; i++) {
		Rune r = cast(Rune)text[i];
		if (r == '_') {
			continue;
		}
		u64 v = u64_digit_value(r);
		if (v >= base) {
			break;
		}
		BigInt val = big_int_make_u64(v);
		big_int_mul_eq(dst, &b);
		big_int_add_eq(dst, &val);
	}
	if (i < len && (text[i] == 'e' || text[i] == 'E')) {
		i += 1;
		GB_ASSERT(base == 10);
		GB_ASSERT(text[i] != '-');
		if (text[i] == '+') {
			i += 1;
		}
		u64 exp = 0;
		for (; i < len; i++) {
			char r = cast(char)text[i];
			if (r == '_') {
				continue;
			}
			u64 v = 0;
			if (gb_char_is_digit(r)) {
				v = u64_digit_value(r);
			} else {
				break;
			}
			exp *= 10;
			exp += v;
		}
		for (u64 x = 0; x < exp; x++) {
			big_int_mul_eq(dst, &b);
		}
	}
}



u64 big_int_to_u64(BigInt const *x) {
	GB_ASSERT(x->sign == 0);
	return mp_get_u64(x);
}

i64 big_int_to_i64(BigInt const *x) {
	return mp_get_i64(x);
}

f64 big_int_to_f64(BigInt const *x) {
	return mp_get_double(x);
}


void big_int_neg(BigInt *dst, BigInt const *x) {
	mp_neg(x, dst);
}


int big_int_cmp(BigInt const *x, BigInt const *y) {
	return mp_cmp(x, y);
}

int big_int_cmp_zero(BigInt const *x) {
	if (mp_iszero(x)) {
		return 0;
	}
	return x->sign ? -1 : +1;
}

bool big_int_is_zero(BigInt const *x) {
	return mp_iszero(x);
}




void big_int_add(BigInt *dst, BigInt const *x, BigInt const *y) {
	mp_add(x, y, dst);
}


void big_int_sub(BigInt *dst, BigInt const *x, BigInt const *y) {
	mp_sub(x, y, dst);
}


void big_int_shl(BigInt *dst, BigInt const *x, BigInt const *y) {
	u32 yy = mp_get_u32(y);
	mp_mul_2d(x, yy, dst);
}

void big_int_shr(BigInt *dst, BigInt const *x, BigInt const *y) {
	u32 yy = mp_get_u32(y);
	BigInt d = {};
	mp_div_2d(x, yy, dst, &d);
	big_int_dealloc(&d);
}

void big_int_mul_u64(BigInt *dst, BigInt const *x, u64 y) {
	BigInt d = {};
	big_int_from_u64(&d, y);
	mp_mul(x, &d, dst);
	big_int_dealloc(&d);
}


void big_int_mul(BigInt *dst, BigInt const *x, BigInt const *y) {
	mp_mul(x, y, dst);
}


u64 leading_zeros_u64(u64 x) {
#if defined(GB_COMPILER_MSVC)
	#if defined(GB_ARCH_64_BIT) && !defined(GB_CPU_ARM)
		return __lzcnt64(x);
	#else
		u64 y, n;

		n = 0;
		y = x;
	L:
		if (x < 0) {
			return n;
		}
		if (y == 0) {
			return 64-n;
		}
		n++;
		x <<= 1;
		y >>= 1;
		goto L;
	#endif
#else
	return cast(u64)__builtin_clzll(cast(unsigned long long)x);
#endif
}


// `big_int_quo_rem` sets z to the quotient x/y and r to the remainder x%y
// and returns the pair (z, r) for y != 0.
// if y == 0, a division-by-zero run-time panic occurs.
//
// q = x/y with the result truncated to zero
// r = x - y*q
void big_int_quo_rem(BigInt const *x, BigInt const *y, BigInt *q_, BigInt *r_) {
	mp_div(x, y, q_, r_);
}

void big_int_quo(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt r = {};
	big_int_quo_rem(x, y, z, &r);
	big_int_dealloc(&r);
}

void big_int_rem(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt q = {};
	big_int_quo_rem(x, y, &q, z);
	big_int_dealloc(&q);
}

void big_int_euclidean_mod(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt y0 = {};
	big_int_init(&y0, y);

	BigInt q = {};
	big_int_quo_rem(x, y, &q, z);
	if (z->sign) {
		if (y0.sign) {
			big_int_sub(z, z, &y0);
		} else {
			big_int_add(z, z, &y0);
		}
	}
}



void big_int_and(BigInt *dst, BigInt const *x, BigInt const *y) {
	mp_and(x, y, dst);
}

void big_int_and_not(BigInt *dst, BigInt const *x, BigInt const *y) {
	if (mp_iszero(x)) {
		big_int_init(dst, y);
		return;
	}
	if (mp_iszero(y)) {
		big_int_init(dst, x);
		return;
	}

	if (x->sign == y->sign) {
		if (x->sign) {
			// (-x) &~ (-y) == ~(x-1) &~ ~(y-1) == ~(x-1) & (y-1) == (y-1) &~ (x-1)
			BigInt x1 = big_int_make_abs(x);
			BigInt y1 = big_int_make_abs(y);
			mp_decr(&x1);
			mp_decr(&y1);

			BigInt ny1 = {};
			mp_complement(&y1, &ny1);
			mp_and(&x1, &ny1, dst);

			big_int_dealloc(&x1);
			big_int_dealloc(&y1);
			big_int_dealloc(&ny1);
			return;
		}

		BigInt ny = {};
		mp_complement(y, &ny);
		mp_and(x, &ny, dst);

		big_int_dealloc(&ny);
		return;
	}

	if (x->sign) {
		// (-x) &~ y == ~(x-1) &~ y == ~(x-1) & ~y == ~((x-1) | y) == -(((x-1) | y) + 1)
		BigInt x1 = big_int_make_abs(x);
		BigInt y1 = big_int_make_abs(y);
		mp_decr(&x1);

		BigInt z1 = {};
		big_int_or(&z1, &x1, &y1);
		mp_add_d(&z1, 1, dst);

		big_int_dealloc(&x1);
		big_int_dealloc(&y1);
		big_int_dealloc(&z1);
		return;
	}

	// x &~ (-y) == x &~ ~(y-1) == x & (y-1)
	BigInt x1 = big_int_make_abs(x);
	BigInt y1 = big_int_make_abs(y);
	mp_decr(&y1);
	big_int_and(dst, &x1, &y1);

	big_int_dealloc(&x1);
	big_int_dealloc(&y1);
	return;
}

void big_int_xor(BigInt *dst, BigInt const *x, BigInt const *y) {
	mp_xor(x, y, dst);
}


void big_int_or(BigInt *dst, BigInt const *x, BigInt const *y) {
	mp_or(x, y, dst);
}

void debug_print_big_int(BigInt const *x) {
	String s = big_int_to_string(temporary_allocator(), x, 10);
	gb_printf_err("[DEBUG] %.*s\n", LIT(s));
}


void big_int_not(BigInt *dst, BigInt const *x, i32 bit_count, bool is_signed) {
	GB_ASSERT(bit_count >= 0);
	if (bit_count == 0) {
		big_int_from_u64(dst, 0);
		return;
	}
	if (big_int_is_neg(x)) {
		// ~x == -x - 1
		big_int_neg(dst, x);
		mp_decr(dst);
		mp_mod_2d(dst, bit_count, dst);
		return;
	}


	BigInt pow2b = {};
	mp_2expt(&pow2b, bit_count);

	BigInt mask = {};
	mp_2expt(&mask, bit_count);
	mp_decr(&mask);

	BigInt v = {};
	mp_init_copy(&v, x);
	mp_mod_2d(&v, bit_count, &v);

	mp_xor(&v, &mask, dst);

	if (is_signed) {
		BigInt pmask = {};
		BigInt pmask_minus_one = {};
		mp_2expt(&pmask, bit_count-1);
		mp_sub_d(&pmask, 1, &pmask_minus_one);

		BigInt a = {};
		BigInt b = {};
		big_int_and(&a, dst, &pmask_minus_one);
		big_int_and(&b, dst, &pmask);
		big_int_sub(dst, &a, &b);
		big_int_dealloc(&a);
		big_int_dealloc(&b);
	}

	big_int_dealloc(&pow2b);
	big_int_dealloc(&mask);
	big_int_dealloc(&v);
}

bool big_int_is_neg(BigInt const *x) {
	if (x == nullptr) {
		return false;
	}
	return x->sign != MP_ZPOS;
}


char digit_to_char(u8 digit) {
	GB_ASSERT(digit < 16);
	if (digit <= 9) {
		return digit + '0';
	} else if (digit <= 15) {
		return digit + 'a';
	}
	return '0';
}

String big_int_to_string(gbAllocator allocator, BigInt const *x, u64 base) {
	GB_ASSERT(base <= 16);

	if (mp_iszero(x)) {
		u8 *buf = gb_alloc_array(allocator, u8, 1);
		buf[0] = '0';
		return make_string(buf, 1);
	}

	Array<char> buf = {};
	array_init(&buf, allocator, 0, 32);

	BigInt v = {};
	mp_init_copy(&v, x);

	if (v.sign) {
		array_add(&buf, '-');
		mp_abs(&v, &v);
	}

	isize first_word_idx = buf.count;

	BigInt r = {};
	BigInt b = {};
	big_int_from_u64(&b, base);

	u8 digit = 0;
	while (big_int_cmp(&v, &b) >= 0) {
		big_int_quo_rem(&v, &b, &v, &r);
		digit = cast(u8)big_int_to_u64(&r);
		array_add(&buf, digit_to_char(digit));
	}

	big_int_rem(&r, &v, &b);
	digit = cast(u8)big_int_to_u64(&r);
	array_add(&buf, digit_to_char(digit));

	big_int_dealloc(&r);
	big_int_dealloc(&b);

	for (isize i = first_word_idx; i < buf.count/2; i++) {
		isize j = buf.count + first_word_idx - i - 1;
		char tmp = buf[i];
		buf[i] = buf[j];
		buf[j] = tmp;
	}

	return make_string(cast(u8 *)buf.data, buf.count);
}
