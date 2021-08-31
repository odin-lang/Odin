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

/*
	int dr;

	/* modulus P must be positive */
	if (mp_isneg(P)) {
		return MP_VAL;
	}

	/* if exponent X is negative we have to recurse */
	if (mp_isneg(X)) {
		mp_int tmpG, tmpX;
		mp_err err;

		if (!MP_HAS(MP_INVMOD)) {
			return MP_VAL;
		}

		if ((err = mp_init_multi(&tmpG, &tmpX, NULL)) != MP_OKAY) {
			return err;
		}

		/* first compute 1/G mod P */
		if ((err = mp_invmod(G, P, &tmpG)) != MP_OKAY) {
			goto LBL_ERR;
		}

		/* now get |X| */
		if ((err = mp_abs(X, &tmpX)) != MP_OKAY) {
			goto LBL_ERR;
		}

		/* and now compute (1/G)**|X| instead of G**X [X < 0] */
		err = mp_exptmod(&tmpG, &tmpX, P, Y);
LBL_ERR:
		mp_clear_multi(&tmpG, &tmpX, NULL);
		return err;
	}

	/* modified diminished radix reduction */
	if (MP_HAS(MP_REDUCE_IS_2K_L) && MP_HAS(MP_REDUCE_2K_L) && MP_HAS(S_MP_EXPTMOD) &&
		 mp_reduce_is_2k_l(P)) {
		return s_mp_exptmod(G, X, P, Y, 1);
	}

	/* is it a DR modulus? default to no */
	dr = (MP_HAS(MP_DR_IS_MODULUS) && mp_dr_is_modulus(P)) ? 1 : 0;

	/* if not, is it a unrestricted DR modulus? */
	if (MP_HAS(MP_REDUCE_IS_2K) && (dr == 0)) {
		dr = (mp_reduce_is_2k(P)) ? 2 : 0;
	}

	/* if the modulus is odd or dr != 0 use the montgomery method */
	if (MP_HAS(S_MP_EXPTMOD_FAST) && (mp_isodd(P) || (dr != 0))) {
		return s_mp_exptmod_fast(G, X, P, Y, dr);
	}

	/* otherwise use the generic Barrett reduction technique */
	if (MP_HAS(S_MP_EXPTMOD)) {
		return s_mp_exptmod(G, X, P, Y, 0);
	}

	/* no exptmod for evens */
	return MP_VAL;

	*/
	return nil;
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