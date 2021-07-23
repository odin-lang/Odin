package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

int_log :: proc(a: ^Int, base: DIGIT) -> (res: int, err: Error) {
	if base < 2 || DIGIT(base) > _DIGIT_MAX {
		return -1, .Invalid_Argument;
	}

	if err = clear_if_uninitialized(a); err != .None {
		return -1, err;
	}
	if n, _ := is_neg(a); n {
		return -1, .Invalid_Argument;
	}
	if z, _ := is_zero(a); z {
		return -1, .Invalid_Argument;
	}

	/*
		Fast path for bases that are a power of two.
	*/
	if is_power_of_two(int(base)) {
		return _log_power_of_two(a, base);
	}

	/*
		Fast path for `Int`s that fit within a single `DIGIT`.
	*/
	if a.used == 1 {
		return log(a.digit[0], DIGIT(base));
	}

    // if (MP_HAS(S_MP_LOG)) {
    //    return s_mp_log(a, (mp_digit)base, c);
    // }

	return -1, .Unimplemented;
}

log :: proc { int_log, int_log_digit, };

/*
	Calculate c = a**b  using a square-multiply algorithm.
*/
int_pow :: proc(dest, base: ^Int, power: int) -> (err: Error) {
	if err = clear_if_uninitialized(dest); err != .None { return err; }
	if err = clear_if_uninitialized(base); err != .None { return err; }

// 	if ((err = mp_init_copy(&g, a)) != MP_OKAY) {
// 		return err;
// 	}

// 	/* set initial result */
// 	mp_set(c, 1uL);

// 	while (b > 0) {
// 		/* if the bit is set multiply */
// 		if ((b & 1) != 0) {
// 			if ((err = mp_mul(c, &g, c)) != MP_OKAY) {
// 				goto LBL_ERR;
// 			}
// 		}

// 		/* square */
// 		if (b > 1) {
// 			if ((err = mp_sqr(&g, &g)) != MP_OKAY) {
// 				goto LBL_ERR;
// 			}
// 		}

// 		/* shift to next bit */
// 		b >>= 1;
// 	}

// LBL_ERR:
// 	mp_clear(&g);
// 	return err;
	return err;
}


pow :: proc { int_pow, };

/*
	Returns the log2 of an `Int`, provided `base` is a power of two.
	Don't call it if it isn't.
*/
_log_power_of_two :: proc(a: ^Int, base: DIGIT) -> (log: int, err: Error) {
	base := base;
	y: int;
	for y = 0; base & 1 == 0; {
		y += 1;
		base >>= 1;
	}
	log, err = count_bits(a);
	return (log - 1) / y, err;
}

/*

*/
small_pow :: proc(base: _WORD, exponent: _WORD) -> (result: _WORD) {
	exponent := exponent; base := base;
   	result = _WORD(1);

   	for exponent != 0 {
   		if exponent & 1 == 1 {
   			result *= base;
   		}
   		exponent >>= 1;
   		base *= base;
   	}
   	return result;
}

int_log_digit :: proc(a: DIGIT, base: DIGIT) -> (log: int, err: Error) {
	/*
		If the number is smaller than the base, it fits within a fraction.
		Therefore, we return 0.
	*/
	if a < base {
		return 0, .None;
	}

	/*
		If a number equals the base, the log is 1.
	*/
	if a == base {
		return 1, .None;
	}

	N := _WORD(a);
	bracket_low  := _WORD(1);
	bracket_high := _WORD(base);
	high := 1;
	low  := 0;

	for bracket_high < N {
		low = high;
		bracket_low = bracket_high;
		high <<= 1;
		bracket_high *= bracket_high;
	}

	for high - low > 1 {
		mid := (low + high) >> 1;
		bracket_mid := bracket_low * small_pow(_WORD(base), _WORD(mid - low));

		if N < bracket_mid {
			high = mid;
			bracket_high = bracket_mid;
		}
		if N > bracket_mid {
			low = mid;
			bracket_low = bracket_mid;
		}
		if N == bracket_mid {
			return mid, .None;
		}
   	}

   	if bracket_high == N {
   		return high, .None;
   	} else {
   		return low, .None;
   	}
}