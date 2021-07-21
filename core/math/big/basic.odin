package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add` and `sub`.
*/

import "core:mem"
import "core:intrinsics"

/*
	===========================
		User-level routines    
	===========================
*/

/*
	High-level addition. Handles sign.
*/
int_add :: proc(dest, a, b: ^Int) -> (err: Error) {
	dest := dest; x := a; y := b;
	if dest == nil || a == nil || b == nil {
		return .Nil_Pointer_Passed;
	} else if !is_initialized(a) || !is_initialized(b) {
		return .Int_Not_Initialized;
	}

	/*
		Handle both negative or both positive.
	*/
	if x.sign == y.sign {
		dest.sign = x.sign;
		return _int_add(dest, x, y);
	}

	/*
		One positive, the other negative.
		Subtract the one with the greater magnitude from the other.
		The result gets the sign of the one with the greater magnitude.
	*/
	if cmp_mag(x, y) == .Less_Than {
		x, y = y, x;
	}

	dest.sign = x.sign;
	return _int_sub(dest, x, y);
}

/*
	Adds the unsigned `DIGIT` immediate to an `Int`,
	such that the `DIGIT` doesn't have to be turned into an `Int` first.

	dest = a + digit;
*/
int_add_digit :: proc(dest, a: ^Int, digit: DIGIT) -> (err: Error) {
	dest := dest; digit := digit;
	if dest == nil || a == nil {
		return .Nil_Pointer_Passed;
	} else if !is_initialized(a) {
		return .Int_Not_Initialized;
	}
	/*
		Fast paths for destination and input Int being the same.
	*/
	if dest == a {
		/*
			Fast path for dest.digit[0] + digit fits in dest.digit[0] without overflow.
		*/
		if is_pos(dest) && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit;
			return .OK;
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if is_neg(a) && (dest.digit[0] > digit) {
			dest.digit[0] -= digit;
			return .OK;
		}
	}

	/*
		Grow destination as required.
	*/
	if err = grow(dest, a.used + 1); err != .OK {
		return err;
	}

	/*
		If `a` is negative and `|a|` >= `digit`, call `dest = |a| - digit`
	*/
	if is_neg(a) && (a.used > 1 || a.digit[0] >= digit) {
		/*
			Temporarily fix `a`'s sign.
		*/
		t := a;
		t.sign = .Zero_or_Positive;
		/*
			dest = |a| - digit
		*/
		err = sub(dest, t, digit);
		/*
			Restore sign and set `dest` sign.
		*/
		dest.sign = .Negative;
		clamp(dest);

		return err;
	}

	/*
		Remember the currently used number of digits in `dest`.
	*/
	old_used := dest.used;

	/*
		If `a` is positive
	*/
	if is_pos(a) {
		/*
			Add digits, use `carry`.
		*/
		i: int;
		carry := digit;
		for i = 0; i < a.used; i += 1 {
			dest.digit[i] = a.digit[i] + carry;
			carry = dest.digit[i] >> _DIGIT_BITS;
			dest.digit[i] &= _MASK;
		}
		/*
			Set final carry.
		*/
		dest.digit[i] = carry;
		/*
			Set `dest` size.
		*/
		dest.used = a.used + 1;
	} else {
		/*
			`a` was negative and |a| < digit.
		*/
		dest.used = 1;
		/*
			The result is a single DIGIT.
		*/
		dest.digit[0] = digit - a.digit[0] if a.used == 1 else digit;
	}
	/*
		Sign is always positive.
	*/
	dest.sign = .Zero_or_Positive;

	zero_count := old_used - dest.used;
	/*
		Zero remainder.
	*/
	if zero_count > 0 {
		mem.zero_slice(dest.digit[dest.used:][:zero_count]);
	}
	/*
		Adjust dest.used based on leading zeroes.
	*/
	clamp(dest);

	return .OK;
}

/*
	High-level subtraction, dest = number - decrease. Handles signs.
*/
int_sub :: proc(dest, number, decrease: ^Int) -> (err: Error) {
	dest := dest; x := number; y := decrease;
	if dest == nil || number == nil || decrease == nil {
		return .Nil_Pointer_Passed;
	} else if !(is_initialized(number) && is_initialized(decrease)) {
		return .Int_Not_Initialized;
	}

	if x.sign != y.sign {
		/*
			Subtract a negative from a positive, OR subtract a positive from a negative.
			In either case, ADD their magnitudes and use the sign of the first number.
		*/
		dest.sign = x.sign;
		return _int_add(dest, x, y);
	}

	/*
		Subtract a positive from a positive, OR negative from a negative.
		First, take the difference between their magnitudes, then...
	*/
	if cmp_mag(x, y) == .Less_Than {
		/*
			The second has a larger magnitude.
			The result has the *opposite* sign from the first number.
		*/
		dest.sign = .Negative if is_pos(x) else .Zero_or_Positive;
		x, y = y, x;
	} else {
		/*
			The first has a larger or equal magnitude.
			Copy the sign from the first.
		*/
		dest.sign = x.sign;
	}
	return _int_sub(dest, x, y);
}

/*
	Adds the unsigned `DIGIT` immediate to an `Int`,
	such that the `DIGIT` doesn't have to be turned into an `Int` first.

	dest = a - digit;
*/
int_sub_digit :: proc(dest, a: ^Int, digit: DIGIT) -> (err: Error) {
	dest := dest; digit := digit;
	if dest == nil || a == nil {
		return .Nil_Pointer_Passed;
	} else if !is_initialized(a) {
		return .Int_Not_Initialized;
	}

	/*
		Fast paths for destination and input Int being the same.
	*/
	if dest == a {
		/*
			Fast path for `dest` is negative and unsigned addition doesn't overflow the lowest digit.
		*/
		if is_neg(dest) && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit;
			return .OK;
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if is_pos(a) && (dest.digit[0] > digit) {
			dest.digit[0] -= digit;
			return .OK;
		}
	}

	/*
		Grow destination as required.
	*/
	err = grow(dest, a.used + 1);
	if err != .OK {
		return err;
	}

	/*
		If `a` is negative, just do an unsigned addition (with fudged signs).
	*/
	if is_neg(a) {
		t := a;
		t.sign = .Zero_or_Positive;

		err = add(dest, t, digit);
		dest.sign = .Negative;

		clamp(dest);
		return err;
	}

	old_used := dest.used;

	/*
		if `a`<= digit, simply fix the single digit.
	*/
	if a.used == 1 && (a.digit[0] <= digit || is_zero(a)) {
		dest.digit[0] = digit - a.digit[0] if a.used == 1 else digit;
		dest.sign = .Negative;
		dest.used = 1;
	} else {
		dest.sign = .Zero_or_Positive;
		dest.used = a.used;

		/*
			Subtract with carry.
		*/
		carry := digit;

		for i := 0; i < a.used; i += 1 {
			dest.digit[i] = a.digit[i] - carry;
			carry := dest.digit[i] >> ((size_of(DIGIT) * 8) - 1);
			dest.digit[i] &= _MASK;
		}
   	}

	zero_count := old_used - dest.used;
	/*
		Zero remainder.
	*/
	if zero_count > 0 {
		mem.zero_slice(dest.digit[dest.used:][:zero_count]);
	}
	/*
		Adjust dest.used based on leading zeroes.
	*/
	clamp(dest);

	return .OK;
}

/*
	==========================
		Low-level routines    
	==========================
*/

/*
	Low-level addition, unsigned.
	Handbook of Applied Cryptography, algorithm 14.7.
*/
_int_add :: proc(dest, a, b: ^Int) -> (err: Error) {
	dest := dest; x := a; y := b;
	if dest == nil || a == nil || b == nil {
		return .Nil_Pointer_Passed;
	} else if !is_initialized(a) || !is_initialized(b) {
		return .Int_Not_Initialized;
	}

	old_used, min_used, max_used, i: int;

	if x.used < y.used {
		x, y = y, x;
	}

	min_used = x.used;
	max_used = y.used;
	old_used = dest.used;

	if err = grow(dest, max(max_used + 1, _DEFAULT_DIGIT_COUNT)); err != .OK {
		return err;
	}
	dest.used = max_used + 1;

	/* Zero the carry */
	carry := DIGIT(0);

	for i = 0; i < min_used; i += 1 {
		/*
			Compute the sum one _DIGIT at a time.
			dest[i] = a[i] + b[i] + carry;
		*/
		dest.digit[i] = x.digit[i] + y.digit[i] + carry;

		/*
			Compute carry
		*/
		carry = dest.digit[i] >> _DIGIT_BITS;
		/*
			Mask away carry from result digit.
		*/
		dest.digit[i] &= _MASK;
	}

	if min_used != max_used {
		/*
			Now copy higher words, if any, in A+B.
			If A or B has more digits, add those in.
		*/
		for ; i < max_used; i += 1 {
			dest.digit[i] = x.digit[i] + carry;
			/*
				Compute carry
			*/
			carry = dest.digit[i] >> _DIGIT_BITS;
			/*
				Mask away carry from result digit.
			*/
			dest.digit[i] &= _MASK;
		}
	}
	/*
		Add remaining carry.
	*/
	dest.digit[i] = carry;

	zero_count := old_used - dest.used;
	/*
		Zero remainder.
	*/
	if zero_count > 0 {
		mem.zero_slice(dest.digit[dest.used:][:zero_count]);
	}
	/*
		Adjust dest.used based on leading zeroes.
	*/
	clamp(dest);

	return .OK;
}

/*
	Low-level subtraction, dest = number - decrease. Assumes |number| > |decrease|.
	Handbook of Applied Cryptography, algorithm 14.9.
*/
_int_sub :: proc(dest, number, decrease: ^Int) -> (err: Error) {
	dest := dest; x := number; y := decrease;
	if dest == nil || number == nil || decrease == nil {
		return .Nil_Pointer_Passed;
	} else if !is_initialized(number) || !is_initialized(decrease) {
		return .Int_Not_Initialized;
	}

	old_used := dest.used;
	min_used := y.used;
	max_used := x.used;
	i: int;

	if err = grow(dest, max(max_used, _DEFAULT_DIGIT_COUNT)); err != .OK {
		return err;
	}
	dest.used = max_used;

	borrow := DIGIT(0);

	for i = 0; i < min_used; i += 1 {
		dest.digit[i] = (x.digit[i] - y.digit[i] - borrow);
		/*
			borrow = carry bit of dest[i]
			Note this saves performing an AND operation since if a carry does occur,
			it will propagate all the way to the MSB.
			As a result a single shift is enough to get the carry.
		*/
		borrow = dest.digit[i] >> ((size_of(DIGIT) * 8) - 1);
		/*
			Clear borrow from dest[i].
		*/
		dest.digit[i] &= _MASK;
	}

	/*
		Now copy higher words if any, e.g. if A has more digits than B
	*/
	for ; i < max_used; i += 1 {
		dest.digit[i] = x.digit[i] - borrow;
		/*
			borrow = carry bit of dest[i]
			Note this saves performing an AND operation since if a carry does occur,
			it will propagate all the way to the MSB.
			As a result a single shift is enough to get the carry.
		*/
		borrow = dest.digit[i] >> ((size_of(DIGIT) * 8) - 1);
		/*
			Clear borrow from dest[i].
		*/
		dest.digit[i] &= _MASK;
	}

	zero_count := old_used - dest.used;
	/*
		Zero remainder.
	*/
	if zero_count > 0 {
		mem.zero_slice(dest.digit[dest.used:][:zero_count]);
	}
	/*
		Adjust dest.used based on leading zeroes.
	*/
	clamp(dest);
	return .OK;
}