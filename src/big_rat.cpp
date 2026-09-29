// An exact rational value: num/den with den > 0, kept in lowest terms.
struct BigRat {
	mp_int num; // signed
	mp_int den; // > 0
};

// Reduce num/den to lowest terms with den > 0 (0 becomes 0/1).
gb_internal void big_rat_normalize(mp_int *num, mp_int *den) {
	if (mp_iszero(num)) {
		mp_set_u64(den, 1);
		return;
	}
	if (big_int_is_neg(den)) {
		mp_neg(num, num);
		mp_neg(den, den);
	}
	mp_int g;   mp_init(&g);   defer (mp_clear(&g));
	mp_int one; mp_init(&one); defer (mp_clear(&one)); mp_set_u64(&one, 1);
	mp_gcd(num, den, &g);
	if (!mp_iszero(&g) && mp_cmp(&g, &one) != MP_EQ) {
		mp_int q, r; mp_init(&q); mp_init(&r); defer (mp_clear(&q)); defer (mp_clear(&r));
		mp_div(num, &g, &q, &r); mp_copy(&q, num);
		mp_div(den, &g, &q, &r); mp_copy(&q, den);
	}
}

gb_internal bool big_rat_from_decimal_string(String const &s, mp_int *num, mp_int *den) {
	TEMPORARY_ALLOCATOR_GUARD();
	char *digits = gb_alloc_array(temporary_allocator(), char, s.len + 2);
	isize dlen = 0;

	isize i = 0;
	bool neg = false;
	if (i < s.len && (s[i] == '+' || s[i] == '-')) {
		neg = s[i] == '-';
		i += 1;
	}

	i64 frac_digits = 0;
	bool seen_dot = false;
	for (; i < s.len; i++) {
		u8 c = s[i];
		if (c == '_') {
			continue;
		}
		if (c == '.') {
			if (seen_dot) return false;
			seen_dot = true;
			continue;
		}
		if (c == 'e' || c == 'E') {
			break;
		}
		if (!gb_char_is_digit(cast(char)c)) return false;
		digits[dlen++] = cast(char)c;
		if (seen_dot) frac_digits += 1;
	}
	if (dlen == 0) {
		digits[dlen++] = '0';
	}
	digits[dlen] = 0;

	i64 exp = 0;
	bool exp_neg = false;
	if (i < s.len && (s[i] == 'e' || s[i] == 'E')) {
		i += 1;
		if (i < s.len && (s[i] == '+' || s[i] == '-')) {
			exp_neg = s[i] == '-';
			i += 1;
		}
		isize exp_digits = 0;
		for (; i < s.len; i++) {
			u8 c = s[i];
			if (c == '_') continue;
			if (!gb_char_is_digit(cast(char)c)) return false;
			exp = exp*10 + cast(i64)(c - '0');
			exp_digits += 1;
		}
		if (exp_digits == 0) return false;
	}

	i64 signed_exp = exp_neg ? -exp : exp;
	i64 net = signed_exp - frac_digits; // value = mantissa * 10^net

	mp_init(num);
	mp_init(den);
	mp_read_radix(num, digits, 10);
	mp_set_u64(den, 1);

	if (net != 0) {
		mp_int ten; mp_init(&ten); defer (mp_clear(&ten)); mp_set_u64(&ten, 10);
		mp_int p;   mp_init(&p);   defer (mp_clear(&p));
		mp_expt_n(&ten, cast(int)(net < 0 ? -net : net), &p);
		if (net > 0) {
			mp_mul(num, &p, num);
		} else {
			mp_copy(&p, den);
		}
	}
	if (neg) {
		mp_neg(num, num);
	}
	return true;
}

// Convert the exact rational `a/b` (b != 0) to the nearest f64 (round-to-nearest, ties-to-even).
// NOTE(bill): Ported from core:math/big `internal_rat_to_float`.
gb_internal f64 big_rat_to_f64(mp_int const *a_in, mp_int const *b_in) {
	int const MSIZE  = 52;         // explicit mantissa bits
	int const MSIZE1 = MSIZE + 1;  // 53, incl. the implicit bit
	int const MSIZE2 = MSIZE + 2;  // 54, one guard bit
	int const EBIAS  = 1023;
	int const EMIN   = 1 - EBIAS;  // -1022

	int alen = mp_count_bits(a_in);
	if (alen == 0) {
		return big_int_is_neg(a_in) ? -0.0 : 0.0;
	}
	bool has_sign = big_int_is_neg(a_in) != big_int_is_neg(b_in);

	int exp = alen - mp_count_bits(b_in);

	mp_int a2, b2, q, r;
	mp_init(&a2); mp_init(&b2); mp_init(&q); mp_init(&r);
	defer (mp_clear(&a2)); defer (mp_clear(&b2)); defer (mp_clear(&q)); defer (mp_clear(&r));
	mp_abs(a_in, &a2);
	mp_abs(b_in, &b2);

	int shift = MSIZE2 - exp;
	if (shift > 0) {
		mp_mul_2d(&a2, shift, &a2);
	} else if (shift < 0) {
		mp_mul_2d(&b2, -shift, &b2);
	}

	mp_div(&a2, &b2, &q, &r);
	bool has_rem = !mp_iszero(&r);
	u64 mantissa = mp_get_mag_u64(&q);

	if ((mantissa >> MSIZE2) == 1) {
		if (mantissa & 1) has_rem = true;
		mantissa >>= 1;
		exp += 1;
	}
	// mantissa is now in [2^53, 2^54): 53 significant bits plus one guard bit.

	if (EMIN - MSIZE <= exp && exp <= EMIN) {
		// Denormalise: fold the bits that fall below the subnormal grid into the guard/sticky.
		unsigned sh = cast(unsigned)(EMIN - (exp - 1));
		u64 lost = mantissa & ((cast(u64)1 << sh) - 1);
		has_rem = has_rem || (lost != 0);
		mantissa >>= sh;
		exp = 2 - EBIAS;
	}

	if (mantissa & 1) {
		if (has_rem || (mantissa & 2)) { // round half to even
			mantissa += 1;
			if (mantissa >= (cast(u64)1 << MSIZE2)) {
				mantissa >>= 1;
				exp += 1;
			}
		}
	}
	mantissa >>= 1; // drop the guard bit

	f64 f = ldexp(cast(f64)mantissa, exp - MSIZE1);
	if (has_sign) {
		f = -f;
	}
	return f;
}

/*
gb_internal void big_rat_selftest(void) {
	char const *lits[] = {
		"0.1", "0.2", "0.3", "0.5", "1.5",
		"3.14159265358979323846",
		"1e10", "1e100", "1e308",
		"1.7976931348623157e308",     // ~max normal
		"2.2250738585072014e-308",    // min normal
		"5e-324",                     // smallest subnormal
		"2.5e-324", "7.5e-324",       // subnormal ties
		"1e-324", "4e-324",           // below the smallest subnormal (round to 0 / to 1 ulp)
		"9007199254740993",           // 2^53 + 1
		"98765.0e309",                // overflow -> +Inf
		"-0.1", "-2.5e-324",
		"0.1000000000000000055511151231257827021181583404541015625", // exact f64(0.1)
	};
	int total = 0, diffs = 0;
	for (isize k = 0; k < cast(isize)(gb_size_of(lits)/gb_size_of(lits[0])); k++) {
		char const *lit = lits[k];
		mp_int num, den;
		if (!big_rat_from_decimal_string(make_string_c(lit), &num, &den)) {
			gb_printf_err("  PARSE FAIL: %s\n", lit);
			continue;
		}
		f64 mine = big_rat_to_f64(&num, &den);
		mp_clear(&num); mp_clear(&den);

		char *end = nullptr;
		f64 ref = strtod(lit, &end);

		union { f64 f; u64 u; } mb, rb;
		mb.f = mine; rb.f = ref;
		bool ok = mb.u == rb.u;
		if (!ok) diffs += 1;
		total += 1;
		gb_printf("  %-56s mine=%016llx ref=%016llx %s\n",
		          lit, cast(unsigned long long)mb.u, cast(unsigned long long)rb.u, ok ? "OK" : "DIFF");
	}
	gb_printf("big_rat_selftest: %d/%d correctly rounded vs strtod (%d diffs)\n", total-diffs, total, diffs);
}

*/