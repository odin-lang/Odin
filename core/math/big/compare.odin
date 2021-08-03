package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains various comparison routines.
*/

import "core:intrinsics"
import "core:mem"

int_is_initialized :: proc(a: ^Int) -> bool {
	if a == nil {
		return false;
	}
	raw := transmute(mem.Raw_Dynamic_Array)a.digit;
	return raw.cap >= _MIN_DIGIT_COUNT;
}

int_is_zero :: proc(a: ^Int) -> (res: bool, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return false, err;
	}
	return a.used == 0, nil;
}

int_is_positive :: proc(a: ^Int) -> (res: bool, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return false, err;
	}
	return a.sign == .Zero_or_Positive, nil;
}

int_is_negative :: proc(a: ^Int) -> (res: bool, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return false, err;
	}
	return a.sign == .Negative, nil;
}

int_is_even :: proc(a: ^Int) -> (res: bool, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return false, err;
	}

	res, err = is_zero(a);
	if err != nil {
		return false, err;
	} else if res == true {
		return true, nil;
	}

	res = false;
	if a.used > 0 && a.digit[0] & 1 == 0 {
		res = true;
	}
	return res, nil;
}

int_is_odd :: proc(a: ^Int) -> (res: bool, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return false, err;
	}

	res, err = is_even(a);
	return !res, err;
}

platform_int_is_power_of_two :: proc(a: int) -> bool {
	return ((a) != 0) && (((a) & ((a) - 1)) == 0);
}

int_is_power_of_two :: proc(a: ^Int) -> (res: bool, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return false, err;
	}

	/*
		Early out for Int == 0.
	*/
	if a.used == 0 {
		return false, nil;
	}

	/*
		For an `Int` to be a power of two, its top limb has to be a power of two.
	*/
	if !platform_int_is_power_of_two(int(a.digit[a.used - 1])) {
		return false, nil;
	}

	/*
		That was the only limb, so it's a power of two.
	*/
	if a.used == 1 {
		return true, nil;
	}

	/*
		For an Int to be a power of two, all limbs except the top one have to be zero.
	*/
	for i := 1; i < a.used; i += 1 {
		if a.digit[i - 1] != 0 {
			return false, nil;
		}
	}
	return true, nil;
}

/*
	Compare two `Int`s, signed.
*/
int_compare :: proc(a, b: ^Int) -> (res: int, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return 0, err;
	}
	if err = clear_if_uninitialized(b); err != nil {
		return 0, err;
	}

	neg: bool;
	if neg, err = is_negative(a); err != nil {
		return 0, err;
	}

	/* Compare based on sign */
	if a.sign != b.sign {
		res = -1 if neg else +1;
		return res, nil;
	}

	/* If negative, compare in the opposite direction */
	if neg {
		return cmp_mag(b, a);
	}
	return cmp_mag(a, b);
}

/*
	Compare an `Int` to an unsigned number upto the size of the backing type.
*/
int_compare_digit :: proc(a: ^Int, u: DIGIT) -> (res: int, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return 0, err;
	}

	/* Compare based on sign */
	neg: bool;
	if neg, err = is_neg(a); err != nil {
		return 0, err;
	}
	if neg {
		return -1, nil;
	}

	/* Compare based on magnitude */
	if a.used > 1 {
		return +1, nil;
	}

	/* Compare the only digit in `a` to `u`. */
	if a.digit[0] != u {
		if a.digit[0] > u {
			return +1, nil;
		}
		return -1, nil;
	}

	return 0, nil;
}

/*
	Compare the magnitude of two `Int`s, unsigned.
*/
int_compare_magnitude :: proc(a, b: ^Int) -> (res: int, err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return 0, err;
	}
	if err = clear_if_uninitialized(b); err != nil {
		return 0, err;
	}

	/* Compare based on used digits */
	if a.used != b.used {
		if a.used > b.used {
			return +1, nil;
		}
		return -1, nil;
	}

	/* Same number of used digits, compare based on their value */
	for n := a.used - 1; n >= 0; n -= 1 {
		if a.digit[n] != b.digit[n] {
			if a.digit[n] > b.digit[n] {
				return +1, nil;
			}
			return -1, nil;
		}
	}

   	return 0, nil;
}