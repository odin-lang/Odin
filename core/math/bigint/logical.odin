package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains logical operations like `and`, `or` and `xor`.
*/

import "core:fmt"

@private
Operator :: enum u8 {
	And = 1,
	Or  = 2,
	Xor = 3,
}

/*
	2's complement `and`, returns `dest = a & b;`
*/

_binary_op :: proc(dest, a, b: ^Int, op: Operator) -> (err: Error) {
	assert_initialized(dest); assert_initialized(a); assert_initialized(b);

	used := max(a.used, b.used) + 1;
	neg: bool;

	switch(op) {
	case .And:
		neg  = is_neg(a) && is_neg(b);
	case .Or:
		neg  = is_neg(a) || is_neg(b);
	case .Xor:
		neg  = is_neg(a) != is_neg(b);
	case:
		return .Invalid_Input;
	}

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1);

	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != .OK {
		return err;
	}

	for i := 0; i < used; i += 1 {
		x, y: DIGIT;

		/*
			Convert to 2's complement if negative.
		*/
		if is_neg(a) {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK);
			x = ac & _MASK;
			ac >>= _DIGIT_BITS;
		} else {
			x = 0 if i >= a.used else a.digit[i];
		}

		/*
			Convert to 2's complement if negative.
		*/
		if is_neg(a) {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK);
			y = bc & _MASK;
			bc >>= _DIGIT_BITS;
		} else {
			y = 0 if i >= b.used else b.digit[i];
		}

		switch(op) {
		case .And:
			dest.digit[i] = x & y;
		case .Or:
			dest.digit[i] = x | y;
		case .Xor:
			dest.digit[i] = x ~ y;
		}

		/*
			Convert to to sign-magnitude if negative.
		*/
		if neg {
			cc += ~dest.digit[i] & _MASK;
			dest.digit[i] = cc & _MASK;
			cc >>= _DIGIT_BITS;
		}
	}

	dest.used = used;
	dest.sign = .Negative if neg else .Zero_or_Positive;
	clamp(dest);
	return .OK;
}

and :: proc(dest, a, b: ^Int) -> (err: Error) {
	return _binary_op(dest, a, b, .And);
}

or  :: proc(dest, a, b: ^Int) -> (err: Error) {
	return _binary_op(dest, a, b, .Or);
}

xor :: proc(dest, a, b: ^Int) -> (err: Error) {
	return _binary_op(dest, a, b, .Xor);
}
