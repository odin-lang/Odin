package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

log_n :: proc(a: ^Int, base: int) -> (log: int, err: Error) {
	assert_initialized(a);
	if is_neg(a) || is_zero(a) || base < 2 || DIGIT(base) > _DIGIT_MAX {
		return -1, .Invalid_Input;
	}

	if is_power_of_two(base) {
		return _log_power_of_two(a, base), .OK;
	}

   // if (MP_HAS(S_MP_LOG_D) && (a->used == 1)) {
   //    *c = s_mp_log_d((mp_digit)base, a->dp[0]);
   //    return MP_OKAY;
   // }

   // if (MP_HAS(S_MP_LOG)) {
   //    return s_mp_log(a, (mp_digit)base, c);
   // }

	return -1, .Unimplemented;
}

/*
	Returns the log2 of an `Int`, provided `base` is a power of two.
	Don't call it if it isn't.
*/
_log_power_of_two :: proc(a: ^Int, base: int) -> (log: int) {
	base := base;
	y: int;
	for y = 0; base & 1 == 0; {
		y += 1;
		base >>= 1;
	}
	return (count_bits(a) - 1) / y;
}
