struct BigInt {
	union {
		u64  word;
		u64 *words;
	} d;
	i32 len;
	b32 neg;
};


BigInt const BIG_INT_ZERO = {{0}, 0, false};
BigInt const BIG_INT_ONE = {{1}, 1, false};
BigInt const BIG_INT_NEG_ONE = {{1}, 1, true};


gb_global Arena global_big_int_arena = {0};

#if defined(GB_COMPILER_MSVC) && defined(GB_ARCH_64_BIT)
// URL(bill): https://stackoverflow.com/questions/8453146/128-bit-division-intrinsic-in-visual-c/8456388#8456388
u8 udiv128_data[] = {
	0x48, 0x89, 0xD0, // mov rax,rdx
	0x48, 0x89, 0xCA, // mov rdx,rcx
	0x49, 0xF7, 0xF0, // div r8
	0x49, 0x89, 0x11, // mov [r9],rdx
	0xC3              // ret
};
u64 (__fastcall *unsafe_udiv128)(u64 numhi, u64 numlo, u64 den, u64* rem) = (u64 (__fastcall *)(u64, u64, u64, u64*))&udiv128_data[0];
#endif

void global_big_int_init(void) {
	arena_init(&global_big_int_arena, heap_allocator());

#if defined(GB_COMPILER_MSVC) && defined(GB_ARCH_64_BIT)
	DWORD dummy;
	VirtualProtect(udiv128_data, sizeof(udiv128_data), PAGE_EXECUTE_READWRITE, &dummy);
#endif
}

// IMPORTANT NOTE LEAK(bill): This entire BigInt library leaks memory like there is no tomorrow
// However, this isn't really a problem as the vast majority of BigInt operations will not use
// more than 1 word.
// I could track how much this does leaks because I use an arena_allocator but I doubt I will require
// it any time soon
gb_inline gbAllocator big_int_allocator(void) {
	return arena_allocator(&global_big_int_arena);
}

void big_int_alloc(BigInt *dst, isize word_len, isize word_cap) {
	GB_ASSERT_MSG(word_len <= word_cap, "%td %td", word_len, word_cap);
	if (word_cap < dst->len) {
		dst->len = cast(i32)word_len;
	} else {
		dst->len = cast(i32)word_len;
		dst->d.words = gb_alloc_array(big_int_allocator(), u64, word_cap);
	}
}

void big_int_from_u64(BigInt *dst, u64 x);
void big_int_from_i64(BigInt *dst, i64 x);
void big_int_init    (BigInt *dst, BigInt const *src);
void big_int_from_string(BigInt *dst, String const &s);

void big_int_dealloc(BigInt *dst) {
	if (dst->len > 1) {
		gb_free(big_int_allocator(), dst->d.words);
	}
	zero_item(dst);
}

BigInt big_int_make(BigInt const *b, bool abs=false);
BigInt big_int_make_abs(BigInt const *b);
BigInt big_int_make_u64(u64 x);
BigInt big_int_make_i64(i64 x);

u64    big_int_to_u64   (BigInt const *x);
i64    big_int_to_i64   (BigInt const *x);
f64    big_int_to_f64   (BigInt const *x);
String big_int_to_string(gbAllocator allocator, BigInt const *x, u64 base = 10);

gb_inline u64 const *big_int_ptr(BigInt const *b) {
	if (b->len <= 1) {
		return &b->d.word;
	}
	return b->d.words;
}
gb_inline u64 *big_int_ptr(BigInt *b) {
	if (b->len <= 1) {
		return &b->d.word;
	}
	return b->d.words;
}

void big_int_add    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_sub    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_shl    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_shr    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_mul    (BigInt *dst, BigInt const *x, BigInt const *y);
void big_int_mul_u64(BigInt *dst, BigInt const *x, u64 y);

void big_int_quo_rem(BigInt const *x, BigInt const *y, BigInt *q, BigInt *r);
void big_int_quo    (BigInt *z, BigInt const *x, BigInt const *y);
void big_int_rem    (BigInt *z, BigInt const *x, BigInt const *y);

void big_int_euclidean_div(BigInt *z, BigInt const *x, BigInt const *y);
void big_int_euclidean_mod(BigInt *z, BigInt const *x, BigInt const *y);

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



void big_int_normalize(BigInt *dst) {
	if (dst->len == 1 && dst->d.word == 0) {
		dst->len = 0;
		return;
	}
	u64 const *words = big_int_ptr(dst);

	i32 count_minus_one = -1;
	for (i32 i = 0; i < dst->len; i++) {
		u64 word = words[i];
		if (word != 0) {
			count_minus_one = i;
		}
	}

	if (count_minus_one < 0) {
		dst->neg = false;
		if (words[0] == 0) {
			dst->len = 0;
			return;
		}
	}
	dst->len = count_minus_one+1;
	if (count_minus_one == 0) {
		dst->d.word = words[0];
	}
}

i64 big_int_sign(BigInt const *x) {
	if (x->len == 0) {
		return 0;
	}
	return x->neg ? -1 : +1;
}


void big_int_from_u64(BigInt *dst, u64 x) {
	if (x == 0) {
		dst->len = 0;
		dst->neg = false;
	} else {
		dst->len = 1;
		dst->d.word = x;
		dst->neg = false;
	}
}
void big_int_from_i64(BigInt *dst, i64 x) {
	if (x >= 0) {
		big_int_from_u64(dst, cast(u64)x);
		return;
	} else {
		dst->len = 1;
		dst->d.word = (cast(u64)(-(x+1ll))) + 1ull;
		dst->neg = true;
	}

}
void big_int_init(BigInt *dst, BigInt const *src) {
	if (dst == src) {
		return;
	}
	if (src->len == 0) {
		big_int_from_u64(dst, 0);
		return;
	} else if (src->len == 1) {
		dst->len = 1;
		dst->d.word = src->d.word;
		dst->neg = src->neg;
		return;
	}


	dst->neg = src->neg;
	big_int_alloc(dst, src->len, src->len);
	u64 const *s = big_int_ptr(src);
	gb_memmove(dst->d.words, s, gb_size_of(u64)*dst->len);
	big_int_normalize(dst);
}

BigInt big_int_make(BigInt const *b, bool abs) {
	BigInt i = {};
	big_int_init(&i, b);
	if (abs) i.neg = false;
	return i;
}
BigInt big_int_make_abs(BigInt const *b) {
	return big_int_make(b, true);
}
BigInt big_int_alias_abs(BigInt const *b) {
	BigInt x = *b;
	x.neg = false;
	return x;
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
	big_int_init(dst, &BIG_INT_ZERO);

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
	big_int_normalize(dst);
}



u64 big_int_to_u64(BigInt const *x) {
	GB_ASSERT(!x->neg);
	switch (x->len) {
	case 0: return 0;
	case 1: return x->d.word;
	}
	GB_PANIC("BigInt too big for u64");
	return 0;
}

i64 big_int_to_i64(BigInt const *x) {
	switch (x->len) {
	case 0:
		return 0;
	case 1:
		if (x->neg) {
			if (x->d.word <= 9223372036854775808ull) { // 2^63 - 1
				return (-cast(i64)(x->d.word-1ull)) - 1ll;
			} else {
				GB_PANIC("BigInt too big for i64");
			}
		} else {
			return cast(i64)x->d.word;
		}
		break;
	}

	GB_PANIC("BigInt too big for i64");
	return 0;
}

f64 big_int_to_f64(BigInt const *x) {
	switch (x->len) {
	case 0:
		return 0.0;
	case 1:
		if (x->neg) {
			i64 i = big_int_to_i64(x);
			return cast(f64)i;
		} else {
			u64 u = big_int_to_u64(x);
			return cast(f64)u;
		}
	}


	u64 const *words = big_int_ptr(x);
	f64 base = pow(2.0, gb_size_of(u64));
	// TODO(bill): clean up this code and make it more accurate
	f64 res = 0;
	for (isize i = x->len-1; i >= 0; i--) {
		res *= base;
		u64 w = words[i];
		res += cast(f64)w;
	}
	return res;
}

bool bi__alias(BigInt const *dst, BigInt const *src) {
	if (dst == src) {
		return true;
	}
	if (dst->len > 1 && src->len > 1) {
		return dst->d.words == src->d.words;
	}
	return false;
}


void big_int_neg(BigInt *dst, BigInt const *x) {
	big_int_init(dst, x);
	dst->neg = !dst->neg;
	big_int_normalize(dst);
}


int big_int_cmp(BigInt const *x, BigInt const *y) {
	if (x == y) {
		return 0;
	} else if (x->neg && !y->neg) {
		return -1;
	} else if (!x->neg && y->neg) {
		return +1;
	} else if (x->len > y->len) {
		return x->neg ? -1 : +1;
	} else if (y->len > x->len) {
		return x->neg ? +1 : -1;
	} else if (x->len == 0) {
		return 0;
	}

	u64 const *xd = big_int_ptr(x);
	u64 const *yd = big_int_ptr(y);

	for (i32 i = x->len; i >= 0; i--) {
		u64 a = xd[i];
		u64 b = yd[i];

		if (a > b) {
			return x->neg ? -1 : +1;
		}
		if (a < b) {
			return x->neg ? +1 : -1;
		}
	}

	return 0;
}

int big_int_cmp_zero(BigInt const *x) {
	if (x->len == 0) {
		return 0;
	}
	return x->neg ? -1 : +1;
}

bool big_int_is_zero(BigInt const *x) {
	if (x->len == 0) {
		return true;
	}
	return false;
}




void big_int_add(BigInt *dst, BigInt const *x, BigInt const *y) {
	if (x->len == 0) {
		big_int_init(dst, y);
		return;
	}
	if (y->len == 0) {
		big_int_init(dst, x);
		return;
	}

	if (x->neg == y->neg) {
		dst->neg = x->neg;

		u64 const *x_words = big_int_ptr(x);
		u64 const *y_words = big_int_ptr(y);
		u64 overflow = cast(u64)add_overflow_u64(x_words[0], y_words[0], &dst->d.word);
		if (overflow == 0 && x->len == 1 && y->len == 1) {
			dst->len = 1;
			big_int_normalize(dst);
			return;
		}

		u64 first_word = dst->d.word;
		big_int_alloc(dst, 0, gb_max(x->len, y->len)+1);
		dst->d.words[0] = first_word;

		i32 i = 1;
		for (;;) {
			u64 v = overflow;
			overflow = 0;

			bool found_word = false;
			if (i < x->len) {
				found_word = true;
				overflow += add_overflow_u64(v, x_words[i], &v);
			}
			if (i < y->len) {
				found_word = true;
				overflow += add_overflow_u64(v, y_words[i], &v);
			}

			dst->d.words[i] = v;
			i += 1;

			if (!found_word) {
				dst->len = i;
				big_int_normalize(dst);
				return;
			}
		}
	} else {
		BigInt const *pos = nullptr;
		BigInt const *neg = nullptr;
		if (x->neg) {
			neg = x;
			pos = y;
		} else {
			GB_ASSERT(y->neg);
			pos = x;
			neg = y;
		}

		BigInt neg_abs = {};
		big_int_neg(&neg_abs, neg);
		BigInt const *bigger  = nullptr;
		BigInt const *smaller = nullptr;

		int cmp = big_int_cmp(pos, &neg_abs);
		dst->neg = cmp < 0;
		switch (cmp) {
		case 0:
			big_int_from_u64(dst, 0);
			return;
		case -1:
			bigger  = &neg_abs;
			smaller = pos;
			break;
		case +1:
			bigger  = pos;
			smaller = &neg_abs;
			break;
		default:
			GB_PANIC("Invalid big_int_cmp value");
			return;
		}

		u64 const *bigger_words  = big_int_ptr(bigger);
		u64 const *smaller_words = big_int_ptr(smaller);
		u64 overflow = cast(u64)sub_overflow_u64(bigger_words[0], smaller_words[0], &dst->d.word);
		if (overflow == 0 && bigger->len == 1 && smaller->len == 1) {
			dst->len = 1;
			big_int_normalize(dst);
			return;
		}

		u64 first_word = dst->d.word;
		big_int_alloc(dst, 0, bigger->len);
		dst->d.words[0] = first_word;

		i32 i = 0;
		while (i < bigger->len) {
			u64 v = bigger_words[i];
			u64 prev_overflow = overflow;
			overflow = 0;

			bool found_word = false;
			if (i < smaller->len) {
				found_word = true;
				overflow += sub_overflow_u64(v, smaller_words[i], &v);
			}
			if (sub_overflow_u64(v, prev_overflow, &v)) {
				found_word = true;
				overflow += 1;
			} else {
				// IMPORTANT TODO(bill): Is this mathematics correct here?
				v += overflow;
			}
			dst->d.words[i] = v;
			i += 1;

			if (!found_word) {
				break;
			}
		}

		GB_ASSERT(overflow == 0);
		dst->len = i;
		big_int_normalize(dst);
		return;
	}
}


void big_int_sub(BigInt *dst, BigInt const *x, BigInt const *y) {
	BigInt neg_y = {};
	big_int_neg(&neg_y, y);
	big_int_add(dst, x, &neg_y);
	big_int_normalize(dst);
	return;
}


void big_int_shl(BigInt *dst, BigInt const *x, BigInt const *y) {
	GB_ASSERT(!y->neg);

	if (x->len == 0) {
		big_int_from_u64(dst, 0);
		return;
	}

	if (x->len == 1 && x->d.word == 0) {
		big_int_from_u64(dst, 0);
		return;
	}

	if (y->len == 0) {
		big_int_init(dst, x);
		return;
	}

	if (y->len == 0) {
		big_int_from_u64(dst, 0);
		return;
	}

	if (y->len != 1) {
		GB_PANIC("SHL value greater than 64 bits!");
	}

	u64 const *xd = big_int_ptr(x);
	u64 shift_amount = big_int_to_u64(y);
	if (x->len == 1 && shift_amount < 64) {
		dst->d.word = xd[0] << shift_amount;
		if (dst->d.word > xd[0]) {
			dst->len = 1;
			dst->neg = x->neg;
			big_int_normalize(dst);
			return;
		}
	}

	u64 word_shift_len = shift_amount / 64;
	u64 remaining_shift_len = shift_amount % 64;

	big_int_alloc(dst, cast(i32)word_shift_len, x->len + word_shift_len + 1);
	GB_ASSERT((x->len + word_shift_len + 1) > 1);

	u64 carry = 0;
	for (i32 i = 0; i < x->len; i++) {
		u64 word = xd[i];
		dst->d.words[dst->len] = carry | (word << remaining_shift_len);
		dst->len += 1;
		if (remaining_shift_len > 0) {
			carry = word >> (64 - remaining_shift_len);
		} else {
			carry = 0;
		}
	}
	big_int_normalize(dst);
}

void big_int_shr(BigInt *dst, BigInt const *x, BigInt const *y) {
	GB_ASSERT(!y->neg);

	if (x->len == 0) {
		big_int_from_u64(dst, 0);
		return;
	}
	if (x->len == 1 && x->d.word == 0) {
		big_int_from_u64(dst, 0);
		return;
	}

	if (y->len == 0) {
		big_int_init(dst, x);
		return;
	}

	if (y->len != 1) {
		GB_PANIC("SHR value greater than 64 bits!");
	}

	u64 const *xd = big_int_ptr(x);
	u64 shift_amount = big_int_to_u64(y);

	if (x->len == 1) {
		dst->d.word = xd[0] >> shift_amount;
		dst->len = 1;
		dst->neg = x->neg;
		big_int_normalize(dst);
		return;
	}

	u64 word_shift_len = shift_amount / 64ull;
	u64 remaining_shift_len = shift_amount % 64ull;

	if (word_shift_len >= x->len) {
		big_int_from_u64(dst, 0);
		return;
	}

	i32 len = cast(i32)(x->len - word_shift_len);
	i32 cap = gb_max(len, dst->len);
	big_int_alloc(dst, len, cap);
	GB_ASSERT(dst->len >= 1);

	u64 carry = 0;
	for (i32 src_idx = x->len - 1; src_idx >= 0; src_idx--) {
		u64 v = xd[src_idx];
		u64 dst_idx = src_idx - word_shift_len;

		dst->d.words[dst_idx] = carry | (v >> remaining_shift_len);

		carry = v << (64ull - remaining_shift_len);
	}
	big_int_normalize(dst);
}

void big_int_mul_u64(BigInt *dst, BigInt const *x, u64 y) {
	BigInt v64 = {};
	big_int_from_u64(&v64, 64);

	big_int_from_u64(dst, 0);

	u64 const *xd = big_int_ptr(x);
	for (i32 i = x->len-1; i >= 0; i--) {
		BigInt shifted = {};
		big_int_shl(&shifted, dst, &v64);

		u64 result_u64 = 0;
		u64 carry_u64 = 0;
		mul_overflow_u64(y, xd[i], &result_u64, &carry_u64);

		BigInt result;
		BigInt carry;
		BigInt carry_shifted;
		big_int_from_u64(&result, result_u64);
		big_int_from_u64(&carry,  carry_u64);
		big_int_shl(&carry_shifted, &carry, &v64);

		BigInt tmp;
		big_int_add(&tmp, &shifted, &carry_shifted);
		big_int_add(dst, &tmp, &result);
	}
	big_int_normalize(dst);
}


void big_int_mul(BigInt *z, BigInt const *x, BigInt const *y) {
	if (x->len == 0 || y->len == 0) {
		return big_int_from_u64(z, 0);
	}
	u64 const *xd = big_int_ptr(x);
	u64 const *yd = big_int_ptr(y);

	u64 carry = 0;
	mul_overflow_u64(xd[0], yd[0], &z->d.word, &carry);
	if (carry == 0 && x->len == 1 && y->len == 1) {
		z->neg = (x->neg != y->neg);
		z->len = 1;
		big_int_normalize(z);
		return;
	}

	big_int_from_u64(z, 0);
	i32 len = x->len+y->len;
	big_int_alloc(z, len, len);
	u64 *zd = big_int_ptr(z);

	for (i32 i = 0; i < y->len; i++) {
		u64 d = yd[i];
		if (d != 0) {
			u64 *z = zd+i;
			i32 n = x->len;
			u64 c = 0;
			for (i32 j = 0; j < n; j++) {
				u64 z1 = 0;
				u64 z00 = 0;
				mul_overflow_u64(xd[j], d, &z00, &z1);
				u64 z0 = z00 + z[j];
				if (z0 < z00) {
					z1 += 1;
				}
				z[j] = z0 + c;
				c = 0;
				if (z[j] < z0) {
					c = 1;
				}
				c += z1;
			}

			zd[n+i] = c;
		}
	}

	z->neg = (x->neg != y->neg);
	big_int_normalize(z);
}


u64 leading_zeros_u64(u64 x) {
#if defined(GB_COMPILER_MSVC)
	return __lzcnt64(x);
#else
	return cast(u64)__builtin_clzll(cast(unsigned long long)x);
#endif
}


void bi__divWW(u64 u1, u64 u0, u64 y, u64 *q, u64 *r) {
#if defined(GB_COMPILER_MSVC) && defined(GB_ARCH_64_BIT)
	*q = unsafe_udiv128(u1, u0, y, r);
#else
	// NOTE(bill): q = (u1<<64 + u0 - r)/y
	// Hacker's Delight page 152
	if (u1 >= y) {
		*q = ~cast(u64)0ull;
		*r = ~cast(u64)0ull;
		return;
	}


	u64 s = leading_zeros_u64(y);
	y <<= s;

	static u64 const B = 1ull<<32ull;
	static u64 const M = B-1ull;

	u64 vn1  = y >> 32ull;
	u64 vn0  = y & M;
	u64 un32 = (u1<<s) | (u0>>(64ull-s));
	u64 un10 = u0 << s;
	u64 un1  = un10 >> 32ull;
	u64 un0  = un10 & M;
	u64 q1   = un32 / vn1;
	u64 rhat = un32 - (q1*vn1);

	while ((q1 >= B) || ((q1*vn0) > (B*rhat+un1))) {
		q1 -= 1;
		rhat += vn1;
		if (rhat >= B) {
			break;
		}
	}

	u64 un21 = (un32*B) + un1 - (q1*y);
	u64 q0 = un21 / vn1;
	rhat = un21 - (q0*vn1);

	while ((q0 >= B) || ((q0*vn0) > (B*rhat+un0))) {
		q0 -= 1;
		rhat += vn1;
		if (rhat >= B) {
			break;
		}
	}

	*q = q1*B + q0;
	*r = (un21*B + un0 - q0*y) >> s;
#endif
}


void bi__divWVW(BigInt *z, u64 xn, BigInt const *x, u64 y, u64 *r_) {
	GB_ASSERT(x->len >= z->len);
	u64 r = xn;
	u64 const *xd = big_int_ptr(x);
	u64 *zd = big_int_ptr(z);
	for (i32 i = z->len-1; i >= 0; i--) {
		u64 u1 = r;
		u64 u0 = xd[i];
		bi__divWW(r, xd[i], y, &zd[i], &r);
	}
	if (r_) *r_ = r;
}

void bi__divW(BigInt const *x, u64 y, BigInt *q_, u64 *r_) {
	BigInt q = {};
	u64 r = 0;
	i32 m = x->len;
	if (y == 0) {
		GB_PANIC("division by zero");
	} else if (y == 1) {
		q = *x;
	} else if (m == 0) {
		// okay
	} else {
		big_int_alloc(&q, m, m);
		bi__divWVW(&q, 0, x, y, &r);
		big_int_normalize(&q);
	}
	if (q_) *q_ = q;
	if (r_) *r_ = r;
}

u64 shlVU(BigInt *z, BigInt const *x, u64 s) {
	u64 c = 0;
	i32 n = z->len;

	u64 const *xd = big_int_ptr(x);
	u64 *zd = big_int_ptr(z);

	if (n > 0) {
		u64 s1 = 64 - s;
		u64 w1 = xd[n-1];
		c = w1 >> s1;
		for (i32 i = n-1; i > 0; i--) {
			u64 w = w1;
			w1 = xd[i-1];
			zd[i] = (w<<s) | (w1>>s1);
		}
		zd[0] = w1 << s;
	}
	return c;
}

u64 mulAddVWW(BigInt *z, BigInt const *x, u64 y, u64 r) {
	u64 c = r;
	u64 const *xd = big_int_ptr(x);
	u64 *zd = big_int_ptr(z);

	for (i32 i = 0; i < z->len; i++) {
		u64 a, b;
		mul_overflow_u64(xd[i], y, &a, &b);
		zd[i] = b + c;
		if (zd[i] < b) {
			a += 1;
		}
		c = a;
	}
	return c;
}

bool bi__greater_than(u64 x1, u64 x2, u64 y1, u64 y2) {
	return x1 > y1 || (x1 == x2 && x2 > y2);
}

void bi__div_large(BigInt const *a, BigInt const *b, BigInt *q, BigInt *r) {
	i32 n = b->len;
	i32 m = a->len - n;

	BigInt u = *a;
	BigInt v = *b;

	big_int_alloc(q, m+1, m+1);

	BigInt qhatv = {{cast(u64)n+1ull}, 1, false};

	big_int_alloc(&u, a->len+1, a->len+1);

	u64 *ud = big_int_ptr(&u);
	u64 *vd = big_int_ptr(&v);

	u64 shift = leading_zeros_u64(vd[n-1]);
	if (shift > 0) {
		BigInt v1 = {{cast(u64)n}, 1, false};
		shlVU(&v1, &v, shift);
		v = v1;
		vd = big_int_ptr(&v);
	}

	BigInt uu = u;
	uu.len = a->len;
	ud[a->len] = shlVU(&uu, a, shift);
}

void big_int_quo_rem_unsigned(BigInt const *a, BigInt const *b, BigInt *q_, BigInt *r_) {
	if (b->len == 0) {
		GB_PANIC("division by zero");
	} else if (b->len == 1 && b->d.word == 0) {
		GB_PANIC("division by zero");
	}

	BigInt x = *a; x.neg = false;
	BigInt y = *b; y.neg = false;
	BigInt q = {};
	BigInt r = {};

	int cmp = big_int_cmp(&x, &y);

	if (cmp < 0) {
		q = BIG_INT_ZERO;
		r = x;
		goto end;
	} else if (cmp == 0) {
		q = BIG_INT_ONE;
		r = BIG_INT_ZERO;
		goto end;
	}

	if (y.len == 1) {
		if (y.d.word == 0) {
			GB_PANIC("division by zero");
		} else if (y.d.word == 1) {
			q = x;
			r = BIG_INT_ZERO;
			goto end;
		} else if (x.len == 0) {
			q = BIG_INT_ZERO;
			r = BIG_INT_ZERO;
			goto end;
		}
		u64 rr = 0;
		bi__divW(&x, y.d.word, &q, &rr);
		big_int_from_u64(&r, rr);
		goto end;
	}

	GB_PANIC("Division of a large denominator not yet supported");
	bi__div_large(&x, &y, &q, &r);

end:
	big_int_normalize(&q);
	big_int_normalize(&r);
	if (q_) *q_ = q;
	if (r_) *r_ = r;
	return;
}

// `big_int_quo_rem` sets z to the quotient x/y and r to the remainder x%y
// and returns the pair (z, r) for y != 0.
// if y == 0, a division-by-zero run-time panic occurs.
//
// q = x/y with the result truncated to zero
// r = x - y*q
void big_int_quo_rem(BigInt const *x, BigInt const *y, BigInt *q_, BigInt *r_) {
	BigInt q = {};
	BigInt r = {};

	big_int_quo_rem_unsigned(x, y, &q, &r);
	q.neg = q.len > 0 && x->neg != y->neg;
	r.neg = r.len > 0 && x->neg;

	if (q_) *q_ = q;
	if (r_) *r_ = r;
}

void big_int_quo(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt r = {};
	big_int_quo_rem_unsigned(x, y, z, &r);
	z->neg = z->len > 0 && x->neg != y->neg;
}

void big_int_rem(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt q = {};
	big_int_quo_rem_unsigned(x, y, &q, z);
	z->neg = z->len > 0 && x->neg;
}



void big_int_euclidean_div(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt r = {};
	big_int_quo_rem(x, y, z, &r);
	if (r.neg) {
		if (y->neg) {
			big_int_add(z, z, &BIG_INT_ONE);
		} else {
			big_int_sub(z, z, &BIG_INT_ONE);
		}
	}
}


void big_int_euclidean_mod(BigInt *z, BigInt const *x, BigInt const *y) {
	BigInt y0 = {};
	big_int_init(&y0, y);

	BigInt q = {};
	big_int_quo_rem(x, y, &q, z);
	if (z->neg) {
		if (y0.neg) {
			big_int_sub(z, z, &y0);
		} else {
			big_int_add(z, z, &y0);
		}
	}
}


void big_int_and(BigInt *dst, BigInt const *x, BigInt const *y) {
	if (x->len == 0 || y->len == 0) {
		big_int_from_u64(dst, 0);
		return;
	}

	if (x->neg == y->neg) {
		if (x->neg) {
			// (-x) & (-y) == ~(x-1) & ~(x-y) == ~((x-1) | (y-1)) == -(((x-1) | (y-1)) + 1)
			BigInt x1 = big_int_make_abs(x);
			BigInt y1 = big_int_make_abs(y);
			BigInt z1 = {};

			big_int_sub_eq(&x1, &BIG_INT_ONE);
			big_int_sub_eq(&y1, &BIG_INT_ONE);
			big_int_or(&z1, &x1, &y1);
			big_int_add(dst, &z1, &BIG_INT_ONE);
			dst->neg = true; // NOTE(bill): dst cannot be 0 as x and y are both negative
			big_int_normalize(dst);
			return;
		}
		u64 const *xd = big_int_ptr(x);
		u64 const *yd = big_int_ptr(y);

		if (x->len == 1 && y->len == 1) {
			dst->len = 1;
			dst->d.word = xd[0] & yd[0];
			return;
		}

		i32 len = gb_max(x->len, y->len);
		big_int_alloc(dst, len, len);
		GB_ASSERT(dst->len > 1);

		i32 i = 0;
		for (; i < x->len && i < y->len; i++) {
			dst->d.words[i] = xd[i] & yd[i];
		}
		for (; i < len; i++) {
			dst->d.words[i] = 0;
		}
		dst->neg = false;
		big_int_normalize(dst);
		return;
	}
	if (x->neg) {
		BigInt const *tmp = x;
		x = y;
		y = tmp;
		// NOTE(bill): AND is symmetric
	}


	// x & (-y) == x &~ (y-1)

	dst->neg = false;
	BigInt x1 = big_int_make_abs(x);
	BigInt y1 = big_int_make_abs(y);
	big_int_sub_eq(&y1, &BIG_INT_ONE);
	big_int_and_not(dst, &x1, &y1);
	big_int_normalize(dst);
}

void big_int__and_not_abs(BigInt *dst, BigInt const *x, BigInt const *y) {
	u64 const *xd = big_int_ptr(x);
	u64 const *yd = big_int_ptr(y);

	if (x->len == 1 && y->len == 1) {
		dst->len = 1;
		dst->d.word = xd[0] & (~yd[0]);
		return;
	}

	i32 len = gb_max(x->len, y->len);
	big_int_alloc(dst, len, len);
	GB_ASSERT(dst->len > 1);

	i32 i = 0;
	for (; i < x->len && i < y->len; i++) {
		dst->d.words[i] = xd[i] & (~yd[i]);
	}
	if (i < x->len) {
		for (; i < len; i++) {
			dst->d.words[i] = xd[i];
		}
	}
	if (i < y->len) {
		for (; i < len; i++) {
			dst->d.words[i] = yd[i];
		}
	}
	big_int_normalize(dst);
}

void big_int_and_not(BigInt *dst, BigInt const *x, BigInt const *y) {
	if (x->len == 0) {
		big_int_init(dst, y);
		return;
	}
	if (y->len == 0) {
		big_int_init(dst, x);
		return;
	}

	if (x->neg == y->neg) {
		if (x->neg) {
			// (-x) &~ (-y) == ~(x-1) &~ ~(y-1) == ~(x-1) & (y-1) == (y-1) &~ (x-1)
			BigInt x1 = big_int_make_abs(x);
			BigInt y1 = big_int_make_abs(y);
			big_int_sub_eq(&x1, &BIG_INT_ONE);
			big_int_sub_eq(&y1, &BIG_INT_ONE);

			big_int__and_not_abs(dst, &y1, &x1);
			dst->neg = false;
			big_int_normalize(dst);
			return;
		}

		big_int__and_not_abs(dst, x, y);
		dst->neg = false;
		big_int_normalize(dst);
		return;
	}

	if (x->neg) {
		// (-x) &~ y == ~(x-1) &~ y == ~(x-1) & ~y == ~((x-1) | y) == -(((x-1) | y) + 1)
		BigInt x1 = big_int_make_abs(x);
		BigInt y1 = big_int_make_abs(y);
		big_int_sub_eq(&x1, &BIG_INT_ONE);

		BigInt z1 = {};
		big_int_or(&z1, &x1, &y1);
		big_int_add(dst, &z1, &BIG_INT_ONE);
		dst->neg = true;
		big_int_normalize(dst);
		return;
	}

	// x &~ (-y) == x &~ ~(y-1) == x & (y-1)
	BigInt x1 = big_int_make_abs(x);
	BigInt y1 = big_int_make_abs(y);
	big_int_sub_eq(&y1, &BIG_INT_ONE);
	big_int_and(dst, &x1, &y1);
	dst->neg = false;
	big_int_normalize(dst);
	return;
}


void big_int__xor_abs(BigInt *dst, BigInt const *x, BigInt const *y) {
	u64 const *xd = big_int_ptr(x);
	u64 const *yd = big_int_ptr(y);

	if (x->len == 1 && y->len == 1) {
		dst->len = 1;
		dst->d.word = xd[0] ^ yd[0];
		big_int_normalize(dst);
		return;
	}

	i32 len = gb_max(x->len, y->len);
	big_int_alloc(dst, len, len);
	GB_ASSERT(dst->len > 1);

	i32 i = 0;
	for (; i < x->len && i < y->len; i++) {
		dst->d.words[i] = xd[i] ^ yd[i];
	}
	for (; i < len; i++) {
		if (i < x->len) {
			dst->d.words[i] = xd[i];
		}
		if (i < y->len) {
			dst->d.words[i] = yd[i];
		}
	}
	big_int_normalize(dst);
}

void big_int_xor(BigInt *dst, BigInt const *x, BigInt const *y) {
	if (x->len == 0) {
		big_int_init(dst, y);
		return;
	} else if (y->len == 0) {
		big_int_init(dst, x);
		return;
	}

	if (x->neg == y->neg) {
		if (x->neg) {
			// (-x) ^ (-y) == ~(x-1) ^ ~(y-1) == (x-1) ^ (y-1)
			BigInt x1 = big_int_make_abs(x);
			BigInt y1 = big_int_make_abs(y);
			big_int_sub_eq(&x1, &BIG_INT_ONE);
			big_int_sub_eq(&y1, &BIG_INT_ONE);
			big_int__xor_abs(dst, &x1, &y1);
			dst->neg = false;
			return;
		}

		big_int__xor_abs(dst, x, y);
		dst->neg = false;
		return;
	}

	// x->neg != y->neg
	if (x->neg) {
		BigInt const *tmp = x;
		x = y;
		y = tmp;
	}
	dst->neg = false;
	if (y->neg) {
		// x ^ (-y) == x ^ ~(y-1) == ~(x ^ (y-1)) == -((x ^ (y-1)) + 1)
		BigInt y1 = big_int_make_abs(y);
		big_int_sub_eq(&y1, &BIG_INT_ONE);
		big_int__xor_abs(dst, x, &y1);
		big_int_add_eq(dst, &BIG_INT_ONE);
		dst->neg = true;
	}
	return;
}


void big_int_or(BigInt *dst, BigInt const *x, BigInt const *y) {
	if (x->len == 0) {
		big_int_init(dst, y);
		return;
	} else if (y->len == 0) {
		big_int_init(dst, x);
		return;
	}

	if (x->neg == y->neg) {
		if (x->neg) {
			// (-x) | (-y) == ~(x-1) | ~(y-1) == ~((x-1) & (y-1)) == -(((x-1) & (y-1)) + 1)
			BigInt x1 = big_int_make_abs(x);
			BigInt y1 = big_int_make_abs(y);
			big_int_sub_eq(&x1, &BIG_INT_ONE);
			big_int_sub_eq(&y1, &BIG_INT_ONE);
			big_int_and(dst, &x1, &y1);
			big_int_add_eq(dst, &BIG_INT_ONE);
			dst->neg = true;
			return;
		}

		dst->neg = x->neg;
		u64 const *xd = big_int_ptr(x);
		u64 const *yd = big_int_ptr(y);

		if (x->len == 1 && y->len == 1) {
			dst->len = 1;
			dst->d.word = xd[0] | yd[0];
			return;
		}

		i32 len = gb_max(x->len, y->len);
		big_int_alloc(dst, len, len);
		GB_ASSERT(dst->len > 1);

		for (i32 i = 0; i < len; i++) {
			u64 word = 0;
			if (i < x->len) {
				word |= xd[i];
			}
			if (i < y->len) {
				word |= yd[i];
			}

			dst->d.words[i] = word;
		}
		big_int_normalize(dst);
	}

	if (x->neg) {
		BigInt const *tmp = x;
		x = y;
		y = tmp;
	}
	dst->neg = false;
	if (y->neg) {
		// x | (-y) == x | ~(y-1) == ~((y-1) &~ x) == -(~((y-1) &~ x) + 1)
		BigInt y1 = big_int_make_abs(y);
		big_int_sub_eq(&y1, &BIG_INT_ONE);
		big_int__and_not_abs(dst, &y1, x);
		big_int_add_eq(dst, &BIG_INT_ONE);
		dst->neg = true;
	}
	return;
}


void big_int_not(BigInt *dst, BigInt const *x, u64 bit_count, bool is_signed) {
	if (bit_count == 0) {
		big_int_from_u64(dst, 0);
		return;
	}

	// TODO(bill): Is this fast enough?

	dst->neg = false;
	u64 const *xd = big_int_ptr(x);
	if (bit_count <= 64) {
		dst->len = 1;
		if (x->len == 0) {
			if (bit_count == 64) {
				dst->d.word = ~cast(u64)0ull;
			} else {
				dst->d.word = (1ull << bit_count) - 1ull;
			}
		} else if (x->len == 1) {
			dst->d.word = ~xd[0];
			if (bit_count != 64) {
				u64 mask = (1ull << bit_count) - 1ull;
				dst->d.word &= mask;
			}
		}
	} else {
		dst->len = cast(i32)((bit_count+63ull) / 64ull);
		GB_ASSERT(dst->len >= x->len);
		big_int_alloc(dst, dst->len, dst->len);
		GB_ASSERT(dst->len > 1);

		i32 i = 0;
		for (; i < x->len; i++) {
			dst->d.words[i] = ~xd[i];
		}
		for (; i < dst->len; i++) {
			dst->d.words[i] = ~cast(u64)0ull;
		}

		i32 word_idx = cast(i32)(cast(u64)dst->len - (bit_count/64ull)-1ull);
		u32 word_bit_idx = bit_count % 64;
		if (word_idx < dst->len) {
			u64 mask = (1ull << word_bit_idx) - 1ull;
			dst->d.words[word_idx] &= mask;
		}
	}

	big_int_normalize(dst);

	if (is_signed) {
		BigInt prec = big_int_make_u64(bit_count-1);
		BigInt mask = {};
		BigInt mask_minus_one = {};
		big_int_shl(&mask, &BIG_INT_ONE, &prec);
		big_int_sub(&mask_minus_one, &mask, &BIG_INT_ONE);

		BigInt a = {};
		BigInt b = {};
		big_int_and(&a, dst, &mask_minus_one);
		big_int_and(&b, dst, &mask);
		big_int_sub(dst, &a, &b);
	}
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

	if ((x->len == 0) && (x->len == 1 && x->d.word == 0)) {
		u8 *buf = gb_alloc_array(allocator, u8, 1);
		buf[0] = '0';
		return make_string(buf, 1);
	}

	Array<char> buf = {};
	array_init(&buf, allocator, 0, 32);

	BigInt v = *x;

	if (v.neg) {
		array_add(&buf, '-');
		v.neg = false;
		big_int_normalize(&v);
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


	for (isize i = first_word_idx; i < buf.count/2; i++) {
		isize j = buf.count + first_word_idx - i - 1;
		char tmp = buf[i];
		buf[i] = buf[j];
		buf[j] = tmp;
	}

	return make_string(cast(u8 *)buf.data, buf.count);
}
