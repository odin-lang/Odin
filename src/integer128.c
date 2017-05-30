typedef struct u128 {u64 lo; u64 hi;} u128;
typedef struct i128 {u64 lo; i64 hi;} i128;

#define BIT128_U64_HIGHBIT 0x8000000000000000ul
#define BIT128_U64_BITS62  0x7ffffffffffffffful
#define BIT128_U64_ALLBITS 0xfffffffffffffffful

static u128 const U128_ZERO = {0, 0};
static u128 const U128_ONE  = {1, 0};
static i128 const I128_ZERO = {0, 0};
static i128 const I128_ONE  = {1, 0};
static u128 const U128_NEG_ONE = {BIT128_U64_ALLBITS, BIT128_U64_ALLBITS};
static i128 const I128_NEG_ONE = {BIT128_U64_ALLBITS, BIT128_U64_ALLBITS};

u128 u128_lo_hi      (u64 lo, u64 hi);
u128 u128_from_u32   (u32 u);
u128 u128_from_u64   (u64 u);
u128 u128_from_i64   (i64 u);
u128 u128_from_f32   (f32 f);
u128 u128_from_f64   (f64 f);
u128 u128_from_string(String string);

i128 i128_lo_hi      (u64 lo, i64 hi);
i128 i128_from_u32   (u32 u);
i128 i128_from_u64   (u64 u);
i128 i128_from_i64   (i64 u);
i128 i128_from_f32   (f32 f);
i128 i128_from_f64   (f64 f);
i128 i128_from_string(String string);

u64 u128_to_u64(u128 a);
i64 u128_to_i64(u128 a);
f64 u128_to_f64(u128 a);

u64 i128_to_u64(i128 a);
i64 i128_to_i64(i128 a);
f64 i128_to_f64(i128 a);

String u128_to_string(u128 a, char *buf, isize len);
String i128_to_string(i128 a, char *buf, isize len);

i32  u128_cmp    (u128 a, u128 b);
bool u128_eq     (u128 a, u128 b);
bool u128_ne     (u128 a, u128 b);
bool u128_lt     (u128 a, u128 b);
bool u128_gt     (u128 a, u128 b);
bool u128_le     (u128 a, u128 b);
bool u128_ge     (u128 a, u128 b);
u128 u128_add    (u128 a, u128 b);
u128 u128_not    (u128 a);
u128 u128_neg    (u128 a);
u128 u128_sub    (u128 a, u128 b);
u128 u128_and    (u128 a, u128 b);
u128 u128_or     (u128 a, u128 b);
u128 u128_xor    (u128 a, u128 b);
u128 u128_and_not(u128 a, u128 b);
u128 u128_shl    (u128 a, u32 n);
u128 u128_shr    (u128 a, u32 n);
u128 u128_mul    (u128 a, u128 b);
void u128_divide (u128 num, u128 den, u128 *quo, u128 *rem);
u128 u128_quo    (u128 a, u128 b);
u128 u128_mod    (u128 a, u128 b);

i128 i128_abs    (i128 a);
i32  i128_cmp    (i128 a, i128 b);
bool i128_eq     (i128 a, i128 b);
bool i128_ne     (i128 a, i128 b);
bool i128_lt     (i128 a, i128 b);
bool i128_gt     (i128 a, i128 b);
bool i128_le     (i128 a, i128 b);
bool i128_ge     (i128 a, i128 b);
i128 i128_add    (i128 a, i128 b);
i128 i128_not    (i128 a);
i128 i128_neg    (i128 a);
i128 i128_sub    (i128 a, i128 b);
i128 i128_and    (i128 a, i128 b);
i128 i128_or     (i128 a, i128 b);
i128 i128_xor    (i128 a, i128 b);
i128 i128_and_not(i128 a, i128 b);
i128 i128_shl    (i128 a, u32 n);
i128 i128_shr    (i128 a, u32 n);
i128 i128_mul    (i128 a, i128 b);
void i128_divide (i128 num, i128 den, i128 *quo, i128 *rem);
i128 i128_quo    (i128 a, i128 b);
i128 i128_mod    (i128 a, i128 b);


////////////////////////////////////////////////////////////////


u64 bit128__digit_value(Rune r) {
	if ('0' <= r && r <= '9') {
		return r - '0';
	} else if ('a' <= r && r <= 'f') {
		return r - 'a' + 10;
	} else if ('A' <= r && r <= 'F') {
		return r - 'A' + 10;
	}
	return 16; // NOTE(bill): Larger than highest possible
}

u128 u128_lo_hi(u64 lo, u64 hi) { return (u128){lo, hi}; }
u128 u128_from_u32(u32 u)       { return u128_lo_hi(cast(u64)u, 0); }
u128 u128_from_u64(u64 u)       { return u128_lo_hi(cast(u64)u, 0); }
u128 u128_from_i64(i64 u)       { return u128_lo_hi(cast(u64)u, u < 0 ? -1 : 0); }
u128 u128_from_f32(f32 f)       { return u128_lo_hi(cast(u64)f, 0); }
u128 u128_from_f64(f64 f)       { return u128_lo_hi(cast(u64)f, 0); }
u128 u128_from_string(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	u64 base = 10;
	bool has_prefix = false;
	if (string.len > 2 && string.text[0] == '0') {
		switch (string.text[1]) {
		case 'b': base = 2;  has_prefix = true; break;
		case 'o': base = 8;  has_prefix = true; break;
		case 'd': base = 10; has_prefix = true; break;
		case 'z': base = 12; has_prefix = true; break;
		case 'x': base = 16; has_prefix = true; break;
		}
	}

	u8 *text = string.text;
	isize len = string.len;
	if (has_prefix) {
		text += 2;
		len -= 2;
	}

	u128 base_ = u128_from_u64(base);

	u128 result = {0};
	for (isize i = 0; i < len; i++) {
		Rune r = cast(Rune)text[i];
		if (r == '_') {
			continue;
		}
		u64 v = bit128__digit_value(r);
		if (v >= base) {
			break;
		}
		result = u128_mul(result, base_);
		result = u128_add(result, u128_from_u64(v));
	}
	return result;
}


i128 i128_lo_hi(u64 lo, i64 hi) {
	i128 i;
	i.lo = lo;
	i.hi = hi;
	return i;
}
i128 i128_from_u32(u32 u)       { return i128_lo_hi(cast(u64)u, 0); }
i128 i128_from_u64(u64 u)       { return i128_lo_hi(cast(u64)u, 0); }
i128 i128_from_i64(i64 u)       { return i128_lo_hi(cast(u64)u, u < 0 ? -1 : 0); }
i128 i128_from_f32(f32 f)       { return i128_lo_hi(cast(u64)f, 0); }
i128 i128_from_f64(f64 f)       { return i128_lo_hi(cast(u64)f, 0); }
i128 i128_from_string(String string) {
	// TODO(bill): Allow for numbers with underscores in them
	u64 base = 10;
	bool has_prefix = false;
	if (string.len > 2 && string.text[0] == '0') {
		switch (string.text[1]) {
		case 'b': base = 2;  has_prefix = true; break;
		case 'o': base = 8;  has_prefix = true; break;
		case 'd': base = 10; has_prefix = true; break;
		case 'z': base = 12; has_prefix = true; break;
		case 'x': base = 16; has_prefix = true; break;
		}
	}

	u8 *text = string.text;
	isize len = string.len;
	if (has_prefix) {
		text += 2;
		len -= 2;
	}

	i128 base_ = i128_from_u64(base);

	i128 result = {0};
	for (isize i = 0; i < len; i++) {
		Rune r = cast(Rune)text[i];
		if (r == '_') {
			continue;
		}
		u64 v = bit128__digit_value(r);
		if (v >= base) {
			break;
		}
		result = i128_mul(result, base_);
		result = i128_add(result, i128_from_u64(v));
	}

	return result;
}



u64 u128_to_u64(u128 a) {
	return (a.lo&BIT128_U64_BITS62) | (a.hi&BIT128_U64_HIGHBIT);
}
i64 u128_to_i64(u128 a) {
	return a.lo;
}
f64 u128_to_f64(u128 a) {
	if (a.hi >= 0) {
		return (cast(f64)a.hi * 18446744073709551616.0) + cast(f64)a.lo;
	}
	i64 h = cast(i64)a.hi;
	u64 l = a.lo;
	h = ~h;
	l = ~l;
	l += 1;
	if (l == 0) {
		h += 1;
	}

	return -((cast(f64)h * 18446744073709551616.0) + cast(f64)l);
}

u64 i128_to_u64(i128 a) {
	return (a.lo&BIT128_U64_BITS62) | (a.hi&BIT128_U64_HIGHBIT);
}
i64 i128_to_i64(i128 a) {
	return cast(i64)a.lo;
}
f64 i128_to_f64(i128 a) {
	if (a.hi >= 0) {
		return (cast(f64)a.hi * 18446744073709551616.0) + cast(f64)a.lo;
	}
	i64 h = a.hi;
	u64 l = a.lo;
	h = ~h;
	l = ~l;
	l += 1;
	if (l == 0) {
		h += 1;
	}

	return -((cast(f64)h * 18446744073709551616.0) + cast(f64)l);
}


String u128_to_string(u128 a, char *out_buf, isize out_buf_len) {
	char buf[200] = {0};
	isize i = 0;

	if (u128_ne(a, U128_ZERO)) {
		u128 base = u128_from_u64(10);
		while (u128_gt(a, U128_ZERO)) {
			i64 digit = u128_to_i64(u128_mod(a, base));
			buf[i++] = gb__num_to_char_table[digit];
			a = u128_quo(a, base);
		}
	} else {
		buf[i++] = '0';
	}

	gb_reverse(buf, i, 1);

	isize len = gb_min(i, out_buf_len);
	gb_memcopy(out_buf, &buf[0], len);
	return make_string(cast(u8 *)out_buf, len);
}
String i128_to_string(i128 a, char *out_buf, isize out_buf_len) {
	char buf[200] = {0};
	isize i = 0;
	bool negative = false;
	if (i128_lt(a, I128_ZERO)) {
		negative = true;
		a = i128_neg(a);
	}

	if (i128_ne(a, I128_ZERO)) {
		i128 base = i128_from_u64(10);
		while (i128_gt(a, I128_ZERO)) {
			i64 digit = i128_to_i64(i128_mod(a, base));
			buf[i++] = gb__num_to_char_table[digit];
			a = i128_quo(a, base);
		}
	} else {
		buf[i++] = '0';
	}

	if (negative) {
		buf[i++] = '-';
	}

	GB_ASSERT(i > 0);
	for (isize j = 0; j < i/2; j++) {
		char tmp = buf[j];
		buf[j] = buf[i-1-j];
		buf[i-1-j] = tmp;
	}

	isize len = gb_min(i, out_buf_len);
	gb_memcopy(out_buf, &buf[0], len);
	return make_string(cast(u8 *)out_buf, len);
}



////////////////////////////////////////////////////////////////

i32 u128_cmp(u128 a, u128 b) {
	if (a.hi == b.hi && b.lo == b.lo) {
		return 0;
	}
	if (a.hi == b.hi) {
		return a.lo < b.lo ? -1 : +1;
	}
	return a.hi < b.hi ? -1 : +1;
}

bool u128_eq(u128 a, u128 b) { return a.hi == b.hi && a.lo == b.lo; }
bool u128_ne(u128 a, u128 b) { return !u128_eq(a, b); }
bool u128_lt(u128 a, u128 b) { return a.hi == b.hi ? a.lo < b.lo : a.hi < b.hi; }
bool u128_gt(u128 a, u128 b) { return a.hi == b.hi ? a.lo > b.lo : a.hi > b.hi; }
bool u128_le(u128 a, u128 b) { return !u128_gt(a, b); }
bool u128_ge(u128 a, u128 b) { return !u128_lt(a, b); }

u128 u128_add(u128 a, u128 b) {
	u128 old_a = a;
	a.lo += b.lo;
	a.hi += b.hi;
	if (a.lo < old_a.lo) {
		a.hi += 1;
	}
	return a;
}
u128 u128_not(u128 a) { return u128_lo_hi(~a.lo, ~a.hi); }

u128 u128_neg(u128 a) {
	return u128_add(u128_not(a), u128_from_u64(1));
}
u128 u128_sub(u128 a, u128 b) {
	return u128_add(a, u128_neg(b));
}
u128 u128_and(u128 a, u128 b) { return u128_lo_hi(a.lo&b.lo, a.hi&b.hi); }
u128 u128_or (u128 a, u128 b) { return u128_lo_hi(a.lo|b.lo, a.hi|b.hi); }
u128 u128_xor(u128 a, u128 b) { return u128_lo_hi(a.lo^b.lo, a.hi^b.hi); }
u128 u128_and_not(u128 a, u128 b) { return u128_lo_hi(a.lo&(~b.lo), a.hi&(~b.hi)); }


u128 u128_shl(u128 a, u32 n) {
	if (n >= 128) {
		return u128_lo_hi(0, 0);
	}

	if (n >= 64) {
		n -= 64;
		a.hi = a.lo;
		a.lo = 0;
	}

	if (n != 0) {
		u64 mask = ~(BIT128_U64_ALLBITS >> n);

		a.hi <<= n;
		a.hi |= (a.lo&mask) >> (64 - n);
		a.lo <<= n;
	}
	return a;
}

u128 u128_shr(u128 a, u32 n) {
	if (n >= 128) {
		return u128_lo_hi(0, 0);
	}

	if (n >= 64) {
		n -= 64;
		a.lo = a.hi;
		a.hi = 0;
	}

	if (n != 0) {
		u64 mask = ~(BIT128_U64_ALLBITS << n);
		a.lo >>= n;
		a.lo |= (a.hi&mask) << (64 - n);
		a.hi >>= n;
	}
	return a;
}


u128 u128_mul(u128 a, u128 b) {
	if (a.lo == 0 && a.hi == 0) {
		return u128_from_u64(0);
	} else if (b.lo == 0 && b.hi == 0) {
		return u128_from_u64(0);
	}
	if (u128_eq(a, U128_ONE)) {
		return b;
	}
	if (u128_eq(b, U128_ONE)) {
		return a;
	}

	u128 res = {0};
	u128 t = b;
	for (u32 i = 0; i < 128; i++) {
		if ((t.lo&1) != 0) {
			res = u128_add(res, u128_shl(a, i));
		}

		t = u128_shr(t, 1);
	}

	return res;
}

void u128_divide(u128 num, u128 den, u128 *quo, u128 *rem) {
	if (u128_eq(den, U128_ZERO)) {
		if (quo) *quo = u128_from_u64(num.lo/den.lo);
		if (rem) *rem = U128_ZERO;
	} else {
		u128 n = num;
		u128 d = den;
		u128 x = U128_ONE;
		u128 r = U128_ZERO;

		while (u128_ge(n, d) && ((u128_shr(d, 128-1).lo&1) == 0)) {
			x = u128_shl(x, 1);
			d = u128_shl(d, 1);
		}

		while (u128_ne(x, U128_ZERO)) {
			if (u128_ge(n, d)) {
				n = u128_sub(n, d);
				r = u128_or(r, x);
			}

			x = u128_shr(x, 1);
			d = u128_shr(d, 1);
		}

		if (quo) *quo = r;
		if (rem) *rem = n;
	}
}

u128 u128_quo(u128 a, u128 b) {
	u128 res = {0};
	u128_divide(a, b, &res, NULL);
	return res;
}
u128 u128_mod(u128 a, u128 b) {
	u128 res = {0};
	u128_divide(a, b, NULL, &res);
	return res;
}

////////////////////////////////////////////////////////////////

i128 i128_abs(i128 a) {
	if ((a.hi&BIT128_U64_HIGHBIT) != 0) {
		return i128_neg(a);
	}
	return a;
}

i32 i128_cmp(i128 a, i128 b) {
	if (a.hi == b.hi && b.lo == b.lo) {
		return 0;
	}
	if (a.hi == b.hi) {
		return a.lo < b.lo ? -1 : +1;
	}
	return a.hi < b.hi ? -1 : +1;
}

bool i128_eq(i128 a, i128 b) { return a.hi == b.hi && a.lo == b.lo; }
bool i128_ne(i128 a, i128 b) { return !i128_eq(a, b); }
bool i128_lt(i128 a, i128 b) { return a.hi == b.hi ? a.lo < b.lo : a.hi < b.hi; }
bool i128_gt(i128 a, i128 b) { return a.hi == b.hi ? a.lo > b.lo : a.hi > b.hi; }
bool i128_le(i128 a, i128 b) { return a.hi == b.hi ? a.lo <= b.lo : a.hi <= b.hi; }
bool i128_ge(i128 a, i128 b) { return a.hi == b.hi ? a.lo >= b.lo : a.hi >= b.hi; }

i128 i128_add(i128 a, i128 b) {
	i128 old_a = a;
	a.lo += b.lo;
	a.hi += b.hi;
	if (a.lo < old_a.lo) {
		a.hi += 1;
	}
	return a;
}
i128 i128_not(i128 a) { return i128_lo_hi(~a.lo, ~a.hi); }

i128 i128_neg(i128 a) {
	return i128_add(i128_not(a), i128_from_u64(1));
}
i128 i128_sub(i128 a, i128 b) {
	return i128_add(a, i128_neg(b));
}
i128 i128_and(i128 a, i128 b) { return i128_lo_hi(a.lo&b.lo, a.hi&b.hi); }
i128 i128_or (i128 a, i128 b) { return i128_lo_hi(a.lo|b.lo, a.hi|b.hi); }
i128 i128_xor(i128 a, i128 b) { return i128_lo_hi(a.lo^b.lo, a.hi^b.hi); }
i128 i128_and_not(i128 a, i128 b) { return i128_lo_hi(a.lo&(~b.lo), a.hi&(~b.hi)); }


i128 i128_shl(i128 a, u32 n) {
	if (n >= 128) {
		return i128_lo_hi(0, 0);
	}

	if (n >= 64) {
		n -= 64;
		a.hi = a.lo;
		a.lo = 0;
	}

	if (n != 0) {
		u64 mask = ~(BIT128_U64_ALLBITS >> n);

		a.hi <<= n;
		a.hi |= (a.lo&mask) >> (64 - n);
		a.lo <<= n;
	}
	return a;
}

i128 i128_shr(i128 a, u32 n) {
	if (n >= 128) {
		return i128_lo_hi(0, 0);
	}

	if (n >= 64) {
		n -= 64;
		a.lo = a.hi;
		a.hi = 0;
	}

	if (n != 0) {
		u64 mask = ~(BIT128_U64_ALLBITS << n);
		a.lo >>= n;
		a.lo |= (a.hi&mask) << (64 - n);
		a.hi >>= n;
	}
	return a;
}


i128 i128_mul(i128 a, i128 b) {
	if (a.lo == 0 && a.hi == 0) {
		return i128_from_u64(0);
	} else if (b.lo == 0 && b.hi == 0) {
		return i128_from_u64(0);
	}
	if (i128_eq(a, I128_ONE)) {
		return b;
	}
	if (i128_eq(b, I128_ONE)) {
		return a;
	}

	i128 res = {0};
	i128 t = b;
	for (u32 i = 0; i < 128; i++) {
		if ((t.lo&1) != 0) {
			res = i128_add(res, i128_shl(a, i));
		}

		t = i128_shr(t, 1);
	}

	return res;
}

void i128_divide(i128 num, i128 den, i128 *quo, i128 *rem) {
	if (i128_eq(den, I128_ZERO)) {
		if (quo) *quo = i128_from_u64(num.lo/den.lo);
		if (rem) *rem = I128_ZERO;
	} else {
		i128 n = num;
		i128 d = den;
		i128 x = I128_ONE;
		i128 r = I128_ZERO;

		while (i128_ge(n, d) && ((i128_shr(d, 128-1).lo&1) == 0)) {
			x = i128_shl(x, 1);
			d = i128_shl(d, 1);
		}

		while (i128_ne(x, I128_ZERO)) {
			if (i128_ge(n, d)) {
				n = i128_sub(n, d);
				r = i128_or(r, x);
			}

			x = i128_shr(x, 1);
			d = i128_shr(d, 1);
		}

		if (quo) *quo = r;
		if (rem) *rem = n;
	}
}

i128 i128_quo(i128 a, i128 b) {
	i128 res = {0};
	i128_divide(a, b, &res, NULL);
	return res;
}
i128 i128_mod(i128 a, i128 b) {
	i128 res = {0};
	i128_divide(a, b, NULL, &res);
	return res;
}
