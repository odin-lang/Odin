/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains prime finding operations.
*/
package math_big

import rnd "core:math/rand";

/*
	Determines if an Integer is divisible by one of the _PRIME_TABLE primes.
	Returns true if it is, false if not. 
*/
internal_int_prime_is_divisible :: proc(a: ^Int, allocator := context.allocator) -> (res: bool, err: Error) {
	assert_if_nil(a);
	context.allocator = allocator;

	internal_clear_if_uninitialized(a) or_return;

	for prime in _private_prime_table {
		rem := #force_inline int_mod_digit(a, prime) or_return;
		if rem == 0 {
			return true, nil;
		}
	}
	/*
		Default to not divisible.
	*/
	return false, nil;
}

/*
	This is a shell function that calls either the normal or Montgomery exptmod functions.
	Originally the call to the Montgomery code was embedded in the normal function but that
	wasted alot of stack space for nothing (since 99% of the time the Montgomery code would be called).

	Computes res == G**X mod P.
	Assumes `res`, `G`, `X` and `P` to not be `nil` and for `G`, `X` and `P` to have been initialized.
*/
internal_int_exponent_mod :: proc(res, G, X, P: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator;

	dr: int;

	/*
		Modulus P must be positive.
	*/
	if internal_is_negative(P) { return .Invalid_Argument; }

	/*
		If exponent X is negative we have to recurse.
	*/
	if internal_is_negative(X) {
		tmpG, tmpX := &Int{}, &Int{};
		defer internal_destroy(tmpG, tmpX);

		internal_init_multi(tmpG, tmpX) or_return;

		/*
			First compute 1/G mod P.
		*/
		internal_invmod(tmpG, G, P) or_return;

		/*
			now get |X|.
		*/
		internal_abs(tmpX, X) or_return;

		/*
			And now compute (1/G)**|X| instead of G**X [X < 0].
		*/
		return internal_int_exponent_mod(res, tmpG, tmpX, P);
	}

	/*
		Modified diminished radix reduction.
	*/
	can_reduce_2k_l := _private_int_reduce_is_2k_l(P) or_return;
	if can_reduce_2k_l {
		return _private_int_exponent_mod(res, G, X, P, 1);
	}

	/*
		Is it a DR modulus? default to no.
	*/
	dr = 1 if _private_dr_is_modulus(P) else 0;

	/*
		If not, is it a unrestricted DR modulus?
	*/
	if dr == 0 {
		reduce_is_2k := _private_int_reduce_is_2k(P) or_return;
		dr = 2 if reduce_is_2k else 0;
	}

	/*
		If the modulus is odd or dr != 0 use the montgomery method.
	*/
	if internal_int_is_odd(P) || dr != 0 {
		return _private_int_exponent_mod(res, G, X, P, dr);
	}

	/*
		Otherwise use the generic Barrett reduction technique.
	*/
	return _private_int_exponent_mod(res, G, X, P, 0);
}

/*
	Kronecker symbol (a|p)
	Straightforward implementation of algorithm 1.4.10 in
	Henri Cohen: "A Course in Computational Algebraic Number Theory"

	@book{cohen2013course,
		title={A course in computational algebraic number theory},
		author={Cohen, Henri},
		volume={138},
		year={2013},
		publisher={Springer Science \& Business Media}
	}

	Assumes `a` and `p` to not be `nil` and to have been initialized.
*/
internal_int_kronecker :: proc(a, p: ^Int, allocator := context.allocator) -> (kronecker: int, err: Error) {
	context.allocator = allocator;

	a1, p1, r := &Int{}, &Int{}, &Int{};
	defer internal_destroy(a1, p1, r);

	table := []int{0, 1, 0, -1, 0, -1, 0, 1};

	if internal_int_is_zero(p) {
		if a.used == 1 && a.digit[0] == 1 {
			return 1, nil;
		} else {
			return 0, nil;
		}
	}

	if internal_is_even(a) && internal_is_even(p) {
		return 0, nil;
	}

	internal_copy(a1, a) or_return;
	internal_copy(p1, p) or_return;

	v := internal_count_lsb(p1) or_return;
	internal_shr(p1, p1, v) or_return;

	k := 1 if v & 1 == 0 else table[a.digit[0] & 7];

	if internal_is_negative(p1) {
		p1.sign = .Zero_or_Positive;
		if internal_is_negative(a1) {
			k = -k;
		}
	}

	internal_zero(r) or_return;

	for {
		if internal_is_zero(a1) {
			if internal_eq(p1, 1) {
				return k, nil;
			} else {
				return 0, nil;
			}
		}

		v = internal_count_lsb(a1) or_return;
		internal_shr(a1, a1, v) or_return;

		if v & 1 == 1 {
			k = k * table[p1.digit[0] & 7];
		}

		if internal_is_negative(a1) {
			/*
				Compute k = (-1)^((a1)*(p1-1)/4) * k.
				a1.digit[0] + 1 cannot overflow because the MSB
				of the DIGIT type is not set by definition.
			 */
			if a1.digit[0] + 1 & p1.digit[0] & 2 != 0 {
				k = -k;
			}
		} else {
			/*
				Compute k = (-1)^((a1-1)*(p1-1)/4) * k.
			*/
			if a1.digit[0] & p1.digit[0] & 2 != 0 {
				k = -k;
			}
		}

		internal_copy(r, a1) or_return;
		r.sign = .Zero_or_Positive;

		internal_mod(a1, p1, r) or_return;
		internal_copy(p1, r)    or_return;
	}
	return;
}

/*
	Miller-Rabin test of "a" to the base of "b" as described in HAC pp. 139 Algorithm 4.24.

	Sets result to `false` if definitely composite or `true` if probably prime.
	Randomly the chance of error is no more than 1/4 and often very much lower.

	Assumes `a` and `b` not to be `nil` and to have been initialized.
*/
internal_int_prime_miller_rabin :: proc(a, b: ^Int, allocator := context.allocator) -> (probably_prime: bool, err: Error) {
	context.allocator = allocator;

	n1, y, r := &Int{}, &Int{}, &Int{};
	defer internal_destroy(n1, y, r);

	/*
		Ensure `b` > 1.
	*/
	if internal_lte(b, 1) { return false, nil; }

	/*
		Get `n1` = `a` - 1.
	*/
	internal_copy(n1, a) or_return;
	internal_sub(n1, n1, 1) or_return;

	/*
		Set `2`**`s` * `r` = `n1`
	*/
	internal_copy(r, n1) or_return;

	/*
		Count the number of least significant bits which are zero.
	*/
	s := internal_count_lsb(r) or_return;

	/*
		Now divide `n` - 1 by `2`**`s`.
	*/
	internal_shr(r, r, s) or_return;

	/*
		Compute `y` = `b`**`r` mod `a`.
	*/
	internal_int_exponent_mod(y, b, r, a) or_return;

	/*
		If `y` != 1 and `y` != `n1` do.
	*/
	if !internal_eq(y, 1) && !internal_eq(y, n1) {
		j := 1;

		/*
			While `j` <= `s` - 1 and `y` != `n1`.
		*/
		for j <= (s - 1) && !internal_eq(y, n1) {
			internal_sqrmod(y, y, a) or_return;

			/*
				If `y` == 1 then composite.
			*/
			if internal_eq(y, 1) {
				return false, nil;
			}

			j += 1;
		}

		/*
			If `y` != `n1` then composite.
		*/
		if !internal_eq(y, n1) {
			return false, nil;
		}
	}

	/*
		Probably prime now.
	*/
	return true, nil;
}

/*
	`a` is the big Int to test for primality.

	`miller_rabin_trials` can be one of the following:
		`< 0`:	For `a` up to 3_317_044_064_679_887_385_961_981, set `miller_rabin_trials` to negative to run a predetermined
				number of trials for a deterministic answer.
		`= 0`:	Run Miller-Rabin with bases 2, 3 and one random base < `a`. Non-deterministic.
		`> 0`:	Run Miller-Rabin with bases 2, 3 and `miller_rabin_trials` number of random bases. Non-deterministic.

	`miller_rabin_only`:
		`false`	Also use either Frobenius-Underwood or Lucas-Selfridge, depending on the compile-time `MATH_BIG_USE_FROBENIUS_TEST` choice.
		`true`	Run Rabin-Miller trials but skip Frobenius-Underwood / Lucas-Selfridge.

	`r` takes a pointer to an instance of `core:math/rand`'s `Rand` and may be `nil` to use the global one.

	Returns `is_prime` (bool), where:
		`false`	Definitively composite.
		`true`	Probably prime if `miller_rabin_trials` >= 0, with increasing certainty with more trials.
				Deterministically prime if `miller_rabin_trials` = 0 for `a` up to 3_317_044_064_679_887_385_961_981.

	Assumes `a` not to be `nil` and to have been initialized.
*/
internal_int_is_prime :: proc(a: ^Int, miller_rabin_trials := int(-1), miller_rabin_only := USE_MILLER_RABIN_ONLY, r: ^rnd.Rand = nil, allocator := context.allocator) -> (is_prime: bool, err: Error) {
	context.allocator = allocator;
	miller_rabin_trials := miller_rabin_trials;

	// Default to `no`.
	is_prime = false;

	b, res := &Int{}, &Int{};
	defer internal_destroy(b, res);

	// Some shortcuts
	// `N` > 3
	if a.used == 1 {
		if a.digit[0] == 0 || a.digit[0] == 1 {
			return;
		}
		if a.digit[0] == 2 {
			return true, nil;
		}
	}

	// `N` must be odd.
	if internal_is_even(a) {
		return;
	}

	// `N` is not a perfect square: floor(sqrt(`N`))^2 != `N` 
	if internal_int_is_square(a) or_return { return; }

	// Is the input equal to one of the primes in the table?
	for p in _private_prime_table {
		if internal_eq(a, p) {
			return true, nil;
		}
	}

	// First perform trial division
	if internal_int_prime_is_divisible(a) or_return { return; }

	// Run the Miller-Rabin test with base 2 for the BPSW test.
	internal_set(b, 2) or_return;
	if !internal_int_prime_miller_rabin(a, b) or_return { return; }

	// Rumours have it that Mathematica does a second M-R test with base 3.
	// Other rumours have it that their strong L-S test is slightly different.
	// It does not hurt, though, beside a bit of extra runtime.

	b.digit[0] += 1;
	if !internal_int_prime_miller_rabin(a, b) or_return { return; }

	// Both, the Frobenius-Underwood test and the the Lucas-Selfridge test are quite
	// slow so if speed is an issue, set `USE_MILLER_RABIN_ONLY` to use M-R tests with
	// bases 2, 3 and t random bases.

	if !miller_rabin_only {
		if miller_rabin_trials >= 0 {
			when MATH_BIG_USE_FROBENIUS_TEST {
				if !internal_int_prime_frobenius_underwood(a) or_return { return; }
			} else {
//				if ((err = mp_prime_strong_lucas_selfridge(a, &res)) != MP_OKAY) {
//					goto LBL_B;
//				}
//				if (!res) {
//					goto LBL_B;
//				}
			}
		}
	}

	// Run at least one Miller-Rabin test with a random base.
	// Don't replace this with `min`, because we try known deterministic bases
	//     for certain sized inputs when `miller_rabin_trials` is negative.
	if miller_rabin_trials == 0 {
		miller_rabin_trials = 1;
	}

	// Only recommended if the input range is known to be < 3_317_044_064_679_887_385_961_981
	// It uses the bases necessary for a deterministic M-R test if the input is	smaller than 3_317_044_064_679_887_385_961_981
	// The caller has to check the size.
	// TODO: can be made a bit finer grained but comparing is not free.

	if miller_rabin_trials < 0 {
		p_max := 0;

		// Sorenson, Jonathan; Webster, Jonathan (2015), "Strong Pseudoprimes to Twelve Prime Bases".

		// 0x437ae92817f9fc85b7e5 = 318_665_857_834_031_151_167_461
		atoi(b, "437ae92817f9fc85b7e5", 16) or_return;
		if internal_lt(a, b) {
			p_max = 12;
		} else {
			/* 0x2be6951adc5b22410a5fd = 3_317_044_064_679_887_385_961_981 */
			atoi(b, "2be6951adc5b22410a5fd", 16) or_return;
			if internal_lt(a, b) {
				p_max = 13;
			} else {
				return false, .Invalid_Argument;
			}
		}

		// We did bases 2 and 3  already, skip them
		for ix := 2; ix < p_max; ix += 1 {
			internal_set(b, _private_prime_table[ix]);
			if !internal_int_prime_miller_rabin(a, b) or_return { return; }
		}
	} else if miller_rabin_trials > 0 {
		// Perform `miller_rabin_trials` M-R tests with random bases between 3 and "a".
		// See Fips 186.4 p. 126ff

		// The DIGITs have a defined bit-size but the size of a.digit is a simple 'int',
		// the size of which can depend on the platform.
		size_a := internal_count_bits(a);
		mask   := (1 << uint(ilog2(size_a))) - 1;

		/*
			Assuming the General Rieman hypothesis (never thought to write that in a
			comment) the upper bound can be lowered to  2*(log a)^2.
			E. Bach, "Explicit bounds for primality testing and related problems,"
			Math. Comp. 55 (1990), 355-380.

				size_a = (size_a/10) * 7;
				len = 2 * (size_a * size_a);

			E.g.: a number of size 2^2048 would be reduced to the upper limit

				floor(2048/10)*7 = 1428
				2 * 1428^2       = 4078368

			(would have been ~4030331.9962 with floats and natural log instead)
			That number is smaller than 2^28, the default bit-size of DIGIT on 32-bit platforms.
		*/

		/*
			How many tests, you might ask? Dana Jacobsen of Math::Prime::Util fame
			does exactly 1. In words: one. Look at the end of _GMP_is_prime() in
			Math-Prime-Util-GMP-0.50/primality.c if you do not believe it.

			The function rand() goes to some length to use a cryptographically
			good PRNG. That also means that the chance to always get the same base
			in the loop is non-zero, although very low.
			-- NOTE(Jeroen): This is not yet true in Odin, but I have some ideas.

			If the BPSW test and/or the addtional Frobenious test have been
			performed instead of just the Miller-Rabin test with the bases 2 and 3,
			a single extra test should suffice, so such a very unlikely event will not do much harm.

			To preemptivly answer the dangling question: no, a witness does not	need to be prime.
		*/
		for ix := 0; ix < miller_rabin_trials; ix += 1 {

			// rand() guarantees the first digit to be non-zero
			internal_rand(b, _DIGIT_TYPE_BITS, r) or_return;

			// Reduce digit before casting because DIGIT might be bigger than
			// an unsigned int and "mask" on the other side is most probably not.
			l: int;

			fips_rand := (uint)(b.digit[0] & DIGIT(mask));
			if fips_rand > (uint)(max(int) - _DIGIT_BITS) {
				l = max(int) / _DIGIT_BITS;
			} else {
				l = (int(fips_rand) + _DIGIT_BITS) / _DIGIT_BITS;
			}

			// Unlikely.
			if (l < 0) {
				ix -= 1;
				continue;
			}
			internal_rand(b, l) or_return;

			// That number might got too big and the witness has to be smaller than "a"
			l = internal_count_bits(b);
			if l >= size_a {
				l = (l - size_a) + 1;
				internal_shr(b, b, l) or_return;
			}

			// Although the chance for b <= 3 is miniscule, try again.
			if internal_lte(b, 3) {
				ix -= 1;
				continue;
			}
			if !internal_int_prime_miller_rabin(a, b) or_return { return; }
		}
	}

	// Passed the test.
	return true, nil;
}

/*
 * floor of positive solution of (2^16) - 1 = (a + 4) * (2 * a + 5)
 * TODO: Both values are smaller than N^(1/4), would have to use a bigint
 *       for `a` instead, but any `a` bigger than about 120 are already so rare that
 *       it is possible to ignore them and still get enough pseudoprimes.
 *       But it is still a restriction of the set of available pseudoprimes
 *       which makes this implementation less secure if used stand-alone.
 */
_FROBENIUS_UNDERWOOD_A :: 32764;

internal_int_prime_frobenius_underwood :: proc(N: ^Int, allocator := context.allocator) -> (result: bool, err: Error) {
	context.allocator = allocator;

	T1z, T2z, Np1z, sz, tz := &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer internal_destroy(T1z, T2z, Np1z, sz, tz);

	internal_init_multi(T1z, T2z, Np1z, sz, tz) or_return;

	a, ap2: int;

	frob: for a = 0; a < _FROBENIUS_UNDERWOOD_A; a += 1 {
		switch a {
		case 2, 4, 7, 8, 10, 14, 18, 23, 26, 28:
			continue frob;
		}

		internal_set(T1z, i32((a * a) - 4));
		j := internal_int_kronecker(T1z, N) or_return;

		switch j {
		case -1: break frob;
		case  0: return false, nil;
		}
	}

	// Tell it a composite and set return value accordingly.
	if a >= _FROBENIUS_UNDERWOOD_A { return false, .Max_Iterations_Reached; }

	// Composite if N and (a+4)*(2*a+5) are not coprime.
	internal_set(T1z, u32((a + 4) * ((2 * a) + 5)));
	internal_int_gcd_lcm(T1z, nil, T1z, N) or_return;

	if !(T1z.used == 1 && T1z.digit[0] == 1) {
		// Composite.
		return false, nil;
	}

	ap2 = a + 2;
	internal_add(Np1z, N, 1) or_return;

	internal_set(sz, 1) or_return;
	internal_set(tz, 2) or_return;

	for i := internal_count_bits(Np1z) - 2; i >= 0; i -= 1 {
		// temp = (sz * (a * sz + 2 * tz)) % N;
		// tz   = ((tz - sz) * (tz + sz)) % N;
		// sz   = temp;

		internal_int_shl1(T2z, tz) or_return;

		// a = 0 at about 50% of the cases (non-square and odd input)
		if a != 0 {
			internal_mul(T1z, sz, DIGIT(a)) or_return;
			internal_add(T2z, T2z, T1z) or_return;
		}

		internal_mul(T1z, T2z, sz) or_return;
		internal_sub(T2z, tz, sz) or_return;
		internal_add(sz, sz, tz) or_return;
		internal_mul(tz, sz, T2z) or_return;
		internal_mod(tz, tz, N) or_return;
		internal_mod(sz, T1z, N) or_return;

		if bit, _ := internal_int_bitfield_extract_bool(Np1z, i); bit {
			// temp = (a+2) * sz + tz
			// tz   = 2 * tz - sz
			// sz   = temp
			if a == 0 {
				internal_int_shl1(T1z, sz) or_return;
			} else {
				internal_mul(T1z, sz, DIGIT(ap2)) or_return;
			}
			internal_add(T1z, T1z, tz) or_return;
			internal_int_shl1(T2z, tz) or_return;
			internal_sub(tz, T2z, sz);
			internal_swap(sz, T1z);
		}
	}

	internal_set(T1z, u32((2 * a) + 5)) or_return;
	internal_mod(T1z, T1z, N) or_return;

	result = internal_is_zero(sz) && internal_eq(tz, T1z);

	return;
}

/*
	Returns the number of Rabin-Miller trials needed for a given bit size.
*/
number_of_rabin_miller_trials :: proc(bit_size: int) -> (number_of_trials: int) {
	switch {
	case bit_size <=    80:
		return -1;		/* Use deterministic algorithm for size <= 80 bits */
	case bit_size >=    81 && bit_size <     96:
		return 37;		/* max. error = 2^(-96)  */
	case bit_size >=    96 && bit_size <    128:
		return 32;		/* max. error = 2^(-96)  */
	case bit_size >=   128 && bit_size <    160:
		return 40;		/* max. error = 2^(-112) */
	case bit_size >=   160 && bit_size <    256:
		return 35;		/* max. error = 2^(-112) */
	case bit_size >=   256 && bit_size <    384:
		return 27;		/* max. error = 2^(-128) */
	case bit_size >=   384 && bit_size <    512:
		return 16;		/* max. error = 2^(-128) */
	case bit_size >=   512 && bit_size <    768:
		return 18;		/* max. error = 2^(-160) */
	case bit_size >=   768 && bit_size <    896:
		return 11;		/* max. error = 2^(-160) */
	case bit_size >=   896 && bit_size <  1_024:
		return 10;		/* max. error = 2^(-160) */
	case bit_size >= 1_024 && bit_size <  1_536:
		return 12;		/* max. error = 2^(-192) */
	case bit_size >= 1_536 && bit_size <  2_048:
		return  8;		/* max. error = 2^(-192) */
	case bit_size >= 2_048 && bit_size <  3_072:
		return  6;		/* max. error = 2^(-192) */
	case bit_size >= 3_072 && bit_size <  4_096:
		return  4;		/* max. error = 2^(-192) */
	case bit_size >= 4_096 && bit_size <  5_120:
		return  5;		/* max. error = 2^(-256) */
	case bit_size >= 5_120 && bit_size <  6_144:
		return  4;		/* max. error = 2^(-256) */
	case bit_size >= 6_144 && bit_size <  8_192:
		return  4;		/* max. error = 2^(-256) */
	case bit_size >= 8_192 && bit_size <  9_216:
		return  3;		/* max. error = 2^(-256) */
	case bit_size >= 9_216 && bit_size < 10_240:
		return  3;		/* max. error = 2^(-256) */
	case:
		return  2;		/* For keysizes bigger than 10_240 use always at least 2 Rounds */
	}
}