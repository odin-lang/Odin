package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:intrinsics"

is_initialized :: proc(a: ^Int) -> bool {
	return a != rawptr(uintptr(0));
}

is_zero :: proc(a: ^Int) -> bool {
	return is_initialized(a) && a.used == 0;
}

is_positive :: proc(a: ^Int) -> bool {
	return is_initialized(a) && a.sign == .Zero_or_Positive;
}
is_pos :: is_positive;;

is_negative :: proc(a: ^Int) -> bool {
	return is_initialized(a) && a.sign == .Negative;
}
is_neg :: is_negative;

is_even :: proc(a: ^Int) -> bool {
	if is_initialized(a) {
		if is_zero(a) {
			return true;
		}
		if a.used > 0 && a.digit[0] & 1 == 0 {
			return true;
		}
	}
	return false;
}

is_odd :: proc(a: ^Int) -> bool {
	if is_initialized(a) {
		return !is_even(a);
	}
	return false;
}

is_power_of_two_small :: proc(a: int) -> bool {
	return ((a) != 0) && (((a) & ((a) - 1)) == 0);
}

is_power_of_two_large :: proc(a: ^Int) -> (res: bool) {
	/*
		Early out for Int == 0.
	*/
	if a.used == 0 {
		return false;
	}

	/*
		For an `Int` to be a power of two, its top limb has to be a power of two.
	*/
	if !is_power_of_two_small(int(a.digit[a.used - 1])) {
		return false;
	}

	/*
		That was the only limb, so it's a power of two.
	*/
	if a.used == 1 {
		return true;
	}

	/*
		For an Int to be a power of two, all limbs except the top one have to be zero.
	*/
	for i := 1; i < a.used; i += 1 {
		if a.digit[i - 1] != 0 {
			return false;
		}
	}
	return true;
}
is_power_of_two :: proc{is_power_of_two_small, is_power_of_two_large};

/*
	Compare two `Int`s, signed.
*/
compare :: proc(a, b: ^Int) -> Comparison_Flag {
	if !is_initialized(a) { return .Uninitialized; }
	if !is_initialized(b) { return .Uninitialized; }

	/* Compare based on sign */
	if a.sign != b.sign {
		return .Less_Than if is_negative(a) else .Greater_Than;
	}

	x, y := a, b;
	/* If negative, compare in the opposite direction */
	if is_neg(a) {
		x, y = b, a;
	}
	return cmp_mag(x, y);
}
cmp :: compare;

/*
	Compare the magnitude of two `Int`s, unsigned.
*/
compare_magnitude :: proc(a, b: ^Int) -> Comparison_Flag {
	if !is_initialized(a) { return .Uninitialized; }
	if !is_initialized(b) { return .Uninitialized; }

	/* Compare based on used digits */
	if a.used != b.used {
		return .Greater_Than if a.used > b.used else .Less_Than;
	}

	/* Same number of used digits, compare based on their value */
	for n := a.used - 1; n >= 0; n -= 1 {
		if a.digit[n] != b.digit[n] {
			return .Greater_Than if a.digit[n] > b.digit[n] else .Less_Than;
		}
	}

   	return .Equal;
}
cmp_mag :: compare_magnitude;

/*
	Compare an `Int` to an unsigned number upto the size of the backing type.
*/
compare_digit :: proc(a: ^Int, u: DIGIT) -> Comparison_Flag {
	if !is_initialized(a) { return .Uninitialized; }

	/* Compare based on sign */
	if is_neg(a) {
		return .Less_Than;
	}

	/* Compare based on magnitude */
	if a.used > 1 {
		return .Greater_Than;
	}

	/* Compare the only digit in `a` to `u`. */
	if a.digit[0] != u {
		return .Greater_Than if a.digit[0] > u else .Less_Than;
	}

	return .Equal;
}