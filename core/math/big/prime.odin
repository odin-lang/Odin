/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains prime finding operations.
*/
package math_big

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
			if internal_cmp(p1, 1) == 0 {
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
	Returns the number of Rabin-Miller trials needed for a given bit size.
*/
number_of_rabin_miller_trials :: proc(bit_size: int) -> (number_of_trials: int) {
	switch {
	case bit_size <=    80:
		return - 1;		/* Use deterministic algorithm for size <= 80 bits */
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