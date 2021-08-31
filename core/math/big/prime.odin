package math_big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains prime finding operations.
*/

/*
	Determines if an Integer is divisible by one of the _PRIME_TABLE primes.
	Returns true if it is, false if not. 
*/
int_prime_is_divisible :: proc(a: ^Int, allocator := context.allocator) -> (res: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	for prime in _private_prime_table {
		rem := #force_inline int_mod_digit(a, prime) or_return
		if rem == 0 {
			return true, nil
		}
	}
	/*
		Default to not divisible.
	*/
	return false, nil
}

/*
	Computes xR**-1 == x (mod N) via Montgomery Reduction.
*/
internal_int_montgomery_reduce :: proc(x, n: ^Int, rho: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	/*
		Can the fast reduction [comba] method be used?
		Note that unlike in mul, you're safely allowed *less* than the available columns [255 per default],
		since carries are fixed up in the inner loop.
	*/
	digs := (n.used * 2) + 1
	if digs < _WARRAY && x.used <= _WARRAY && n.used < _MAX_COMBA {
		return _private_montgomery_reduce_comba(x, n, rho)
	}

	/*
		Grow the input as required
	*/
	internal_grow(x, digs)                                           or_return
	x.used = digs

	for ix := 0; ix < n.used; ix += 1 {
		/*
			`mu = ai * rho mod b`
			The value of rho must be precalculated via `int_montgomery_setup()`,
			such that it equals -1/n0 mod b this allows the following inner loop
			to reduce the input one digit at a time.
		*/

		mu := DIGIT((_WORD(x.digit[ix]) * _WORD(rho)) & _WORD(_MASK))

		/*
			a = a + mu * m * b**i
			Multiply and add in place.
		*/
		u  := DIGIT(0)
		iy := int(0)
		for ; iy < n.used; iy += 1 {
			/*
				Compute product and sum.
			*/
			r := (_WORD(mu) * _WORD(n.digit[iy]) + _WORD(u) + _WORD(x.digit[ix + iy]))

			/*
				Get carry.
			*/
			u = DIGIT(r >> _DIGIT_BITS)

			/*
				Fix digit.
			*/
			x.digit[ix + iy] = DIGIT(r & _WORD(_MASK))
		}

		/*
			At this point the ix'th digit of x should be zero.
			Propagate carries upwards as required.
		*/
		for u != 0 {
			x.digit[ix + iy] += u
			u = x.digit[ix + iy] >> _DIGIT_BITS
			x.digit[ix + iy] &= _MASK
			iy += 1
		}
	}

	/*
		At this point the n.used'th least significant digits of x are all zero,
		which means we can shift x to the right by n.used digits and the
		residue is unchanged.

		x = x/b**n.used.
	*/
	internal_clamp(x)
	internal_shr_digit(x, n.used)

	/*
		if x >= n then x = x - n
	*/
	if internal_cmp_mag(x, n) != -1 {
		return internal_sub(x, x, n)
	}

	return nil
}

int_montgomery_reduce :: proc(x, n: ^Int, rho: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x, n)
	context.allocator = allocator

	internal_clear_if_uninitialized(x, n) or_return

	return #force_inline internal_int_montgomery_reduce(x, n, rho)
}

/*
	Shifts with subtractions when the result is greater than b.

	The method is slightly modified to shift B unconditionally upto just under
	the leading bit of b.  This saves alot of multiple precision shifting.
*/
internal_int_montgomery_calc_normalization :: proc(a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	/*
		How many bits of last digit does b use.
	*/
	bits := internal_count_bits(b) % _DIGIT_BITS

	if b.used > 1 {
		power := ((b.used - 1) * _DIGIT_BITS) + bits - 1
		internal_int_power_of_two(a, power)                          or_return
	} else {
		internal_one(a)
		bits = 1
	}

	/*
		Now compute C = A * B mod b.
	*/
	for x := bits - 1; x < _DIGIT_BITS; x += 1 {
		internal_int_shl1(a, a)                                      or_return
		if internal_cmp_mag(a, b) != -1 {
			internal_sub(a, a, b)                                    or_return
		}
	}
	return nil
}

int_montgomery_calc_normalization :: proc(a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	return #force_inline internal_int_montgomery_calc_normalization(a, b)
}

/*
	Sets up the Montgomery reduction stuff.
*/
internal_int_montgomery_setup :: proc(n: ^Int) -> (rho: DIGIT, err: Error) {
	/*
		Fast inversion mod 2**k
		Based on the fact that:

		XA = 1 (mod 2**n) => (X(2-XA)) A = 1 (mod 2**2n)
		                  =>  2*X*A - X*X*A*A = 1
		                  =>  2*(1) - (1)     = 1
	*/
	b := n.digit[0]
	if b & 1 == 0 { return 0, .Invalid_Argument }

	x := (((b + 2) & 4) << 1) + b /* here x*a==1 mod 2**4 */
	x *= 2 - (b * x)              /* here x*a==1 mod 2**8 */
	x *= 2 - (b * x)              /* here x*a==1 mod 2**16 */
	when _WORD_TYPE_BITS == 64 {
		x *= 2 - (b * x)              /* here x*a==1 mod 2**32 */
		x *= 2 - (b * x)              /* here x*a==1 mod 2**64 */
	}

	/*
		rho = -1/m mod b
	*/
	rho = DIGIT(((_WORD(1) << _WORD(_DIGIT_BITS)) - _WORD(x)) & _WORD(_MASK))
	return rho, nil
}

int_montgomery_setup :: proc(n: ^Int, allocator := context.allocator) -> (rho: DIGIT, err: Error) {
	assert_if_nil(n)
	internal_clear_if_uninitialized(n, allocator) or_return

	return #force_inline internal_int_montgomery_setup(n)
}

/*
	Returns the number of Rabin-Miller trials needed for a given bit size.
*/
number_of_rabin_miller_trials :: proc(bit_size: int) -> (number_of_trials: int) {
	switch {
	case bit_size <=    80:
		return - 1		/* Use deterministic algorithm for size <= 80 bits */
	case bit_size >=    81 && bit_size <     96:
		return 37		/* max. error = 2^(-96)  */
	case bit_size >=    96 && bit_size <    128:
		return 32		/* max. error = 2^(-96)  */
	case bit_size >=   128 && bit_size <    160:
		return 40		/* max. error = 2^(-112) */
	case bit_size >=   160 && bit_size <    256:
		return 35		/* max. error = 2^(-112) */
	case bit_size >=   256 && bit_size <    384:
		return 27		/* max. error = 2^(-128) */
	case bit_size >=   384 && bit_size <    512:
		return 16		/* max. error = 2^(-128) */
	case bit_size >=   512 && bit_size <    768:
		return 18		/* max. error = 2^(-160) */
	case bit_size >=   768 && bit_size <    896:
		return 11		/* max. error = 2^(-160) */
	case bit_size >=   896 && bit_size <  1_024:
		return 10		/* max. error = 2^(-160) */
	case bit_size >= 1_024 && bit_size <  1_536:
		return 12		/* max. error = 2^(-192) */
	case bit_size >= 1_536 && bit_size <  2_048:
		return  8		/* max. error = 2^(-192) */
	case bit_size >= 2_048 && bit_size <  3_072:
		return  6		/* max. error = 2^(-192) */
	case bit_size >= 3_072 && bit_size <  4_096:
		return  4		/* max. error = 2^(-192) */
	case bit_size >= 4_096 && bit_size <  5_120:
		return  5		/* max. error = 2^(-256) */
	case bit_size >= 5_120 && bit_size <  6_144:
		return  4		/* max. error = 2^(-256) */
	case bit_size >= 6_144 && bit_size <  8_192:
		return  4		/* max. error = 2^(-256) */
	case bit_size >= 8_192 && bit_size <  9_216:
		return  3		/* max. error = 2^(-256) */
	case bit_size >= 9_216 && bit_size < 10_240:
		return  3		/* max. error = 2^(-256) */
	case:
		return  2		/* For keysizes bigger than 10_240 use always at least 2 Rounds */
	}
}