package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains logical operations like `and`, `or` and `xor`.
*/

/*
	The `and`, `or` and `xor` binops differ in two lines only.
	We could handle those with a switch, but that adds overhead.
*/

/*
	2's complement `and`, returns `dest = a & b;`
*/
and :: proc(dest, a, b: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(b); err != .None {
		return err;
	}
	used := max(a.used, b.used) + 1;
	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != .None {
		return err;
	}

	neg_a, _ := is_neg(a);
	neg_b, _ := is_neg(b);
	neg      := neg_a && neg_b;

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1);

	for i := 0; i < used; i += 1 {
		x, y: DIGIT;

		/*
			Convert to 2's complement if negative.
		*/
		if neg_a {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK);
			x = ac & _MASK;
			ac >>= _DIGIT_BITS;
		} else {
			x = 0 if i >= a.used else a.digit[i];
		}

		/*
			Convert to 2's complement if negative.
		*/
		if neg_b {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK);
			y = bc & _MASK;
			bc >>= _DIGIT_BITS;
		} else {
			y = 0 if i >= b.used else b.digit[i];
		}

		dest.digit[i] = x & y;

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
	return clamp(dest);
}

/*
	2's complement `or`, returns `dest = a | b;`
*/
or :: proc(dest, a, b: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(b); err != .None {
		return err;
	}
	used := max(a.used, b.used) + 1;
	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != .None {
		return err;
	}

	neg_a, _ := is_neg(a);
	neg_b, _ := is_neg(b);
	neg      := neg_a || neg_b;

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1);

	for i := 0; i < used; i += 1 {
		x, y: DIGIT;

		/*
			Convert to 2's complement if negative.
		*/
		if neg_a {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK);
			x = ac & _MASK;
			ac >>= _DIGIT_BITS;
		} else {
			x = 0 if i >= a.used else a.digit[i];
		}

		/*
			Convert to 2's complement if negative.
		*/
		if neg_b {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK);
			y = bc & _MASK;
			bc >>= _DIGIT_BITS;
		} else {
			y = 0 if i >= b.used else b.digit[i];
		}

		dest.digit[i] = x | y;

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
	return clamp(dest);
}

/*
	2's complement `xor`, returns `dest = a ~ b;`
*/
xor :: proc(dest, a, b: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(b); err != .None {
		return err;
	}
	used := max(a.used, b.used) + 1;
	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != .None {
		return err;
	}

	neg_a, _ := is_neg(a);
	neg_b, _ := is_neg(b);
	neg      := neg_a != neg_b;

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1);

	for i := 0; i < used; i += 1 {
		x, y: DIGIT;

		/*
			Convert to 2's complement if negative.
		*/
		if neg_a {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK);
			x = ac & _MASK;
			ac >>= _DIGIT_BITS;
		} else {
			x = 0 if i >= a.used else a.digit[i];
		}

		/*
			Convert to 2's complement if negative.
		*/
		if neg_b {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK);
			y = bc & _MASK;
			bc >>= _DIGIT_BITS;
		} else {
			y = 0 if i >= b.used else b.digit[i];
		}

		dest.digit[i] = x ~ y;

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
	return clamp(dest);
}

/*
	dest = ~src
*/
int_complement :: proc(dest, src: ^Int) -> (err: Error) {
	/*
		Check that src and dest are usable.
	*/
	if err = clear_if_uninitialized(src); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}

	/*
		Temporarily fix sign.
	*/
	old_sign := src.sign;
	z, _ := is_zero(src);

	src.sign = .Negative if (src.sign == .Zero_or_Positive || z) else .Zero_or_Positive;

	err = sub(dest, src, 1);
	/*
		Restore sign.
	*/
	src.sign = old_sign;

	return err;
}
complement :: proc { int_complement, };