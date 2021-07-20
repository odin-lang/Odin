package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

log_n_int :: proc(a: ^Int, base: DIGIT) -> (log: int, err: Error) {
	assert_initialized(a);
	if is_neg(a) || is_zero(a) || base < 2 || DIGIT(base) > _DIGIT_MAX {
		return -1, .Invalid_Input;
	}

	/*
		Fast path for bases that are a power of two.
	*/
	if is_power_of_two(int(base)) {
		return _log_power_of_two(a, base), .OK;
	}

	/*
		Fast path for `Int`s that fit within a single `DIGIT`.
	*/
	if a.used == 1 {
		return log_n_digit(a.digit[0], DIGIT(base)), .OK;
	}

    // if (MP_HAS(S_MP_LOG)) {
    //    return s_mp_log(a, (mp_digit)base, c);
    // }

	return -1, .Unimplemented;
}

log_n :: proc{log_n_int, log_n_digit};

/*
	Returns the log2 of an `Int`, provided `base` is a power of two.
	Don't call it if it isn't.
*/
_log_power_of_two :: proc(a: ^Int, base: DIGIT) -> (log: int) {
	base := base;
	y: int;
	for y = 0; base & 1 == 0; {
		y += 1;
		base >>= 1;
	}
	return (count_bits(a) - 1) / y;
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

log_n_digit :: proc(a: DIGIT, base: DIGIT) -> (log: int) {
	/*
		If the number is smaller than the base, it fits within a fraction.
		Therefore, we return 0.
	*/
	if a < base {
		return 0;
	}

	/*
		If a number equals the base, the log is 1.
	*/
	if a == base {
		return 1;
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
			return mid;
		}
   	}

   	if bracket_high == N {
   		return high;
   	} else {
   		return low;
   	}
}