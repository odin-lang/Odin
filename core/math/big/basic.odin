package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add`, `sub`, `div`, ...
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
	if err = clear_if_uninitialized(a); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(b); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}
	/*
		All parameters have been initialized.
		We can now safely ignore errors from comparison routines.
	*/

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
	if c, _ := cmp_mag(a, b); c == -1 {
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
	if err = clear_if_uninitialized(a); err != .None {
		return err;
	}
	/*
		Grow destination as required.
	*/
	if dest != a {
		if err = grow(dest, a.used + 1); err != .None {
			return err;
		}
	}
	/*
		All parameters have been initialized.
		We can now safely ignore errors from comparison routines.
	*/

	/*
		Fast paths for destination and input Int being the same.
	*/
	if dest == a {
		/*
			Fast path for dest.digit[0] + digit fits in dest.digit[0] without overflow.
		*/
		if p, _ := is_pos(dest); p && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit;
			return .None;
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if n, _ := is_neg(a); n && (dest.digit[0] > digit) {
			dest.digit[0] -= digit;
			return .None;
		}
	}

	/*
		If `a` is negative and `|a|` >= `digit`, call `dest = |a| - digit`
	*/
	if n, _ := is_neg(a); n && (a.used > 1 || a.digit[0] >= digit) {
		/*
			Temporarily fix `a`'s sign.
		*/
		a.sign = .Zero_or_Positive;
		/*
			dest = |a| - digit
		*/
		if err = sub(dest, a, digit); err != .None {
			/*
				Restore a's sign.
			*/
			a.sign = .Negative;
			return err;
		}
		/*
			Restore sign and set `dest` sign.
		*/
		a.sign    = .Negative;
		dest.sign = .Negative;

		return clamp(dest);
	}

	/*
		Remember the currently used number of digits in `dest`.
	*/
	old_used := dest.used;

	/*
		If `a` is positive
	*/
	if p, _ := is_pos(a); p {
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
	return clamp(dest);
}

/*
	High-level subtraction, dest = number - decrease. Handles signs.
*/
int_sub :: proc(dest, number, decrease: ^Int) -> (err: Error) {
	dest := dest; x := number; y := decrease;
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(x); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(y); err != .None {
		return err;
	}
	/*
		All parameters have been initialized.
		We can now safely ignore errors from comparison routines.
	*/

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
	if c, _ := cmp_mag(x, y); c == -1 {
		/*
			The second has a larger magnitude.
			The result has the *opposite* sign from the first number.
		*/
		if p, _ := is_pos(x); p {
			dest.sign = .Negative;
		} else {
			dest.sign = .Zero_or_Positive;
		}
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
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}
	/*
		Grow destination as required.
	*/
	if dest != a {
		if err = grow(dest, a.used + 1); err != .None {
			return err;
		}
	}
	/*
		All parameters have been initialized.
		We can now safely ignore errors from comparison routines.
	*/

	/*
		Fast paths for destination and input Int being the same.
	*/
	if dest == a {
		/*
			Fast path for `dest` is negative and unsigned addition doesn't overflow the lowest digit.
		*/
		if n, _ := is_neg(dest); n && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit;
			return .None;
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if p, _ := is_pos(a); p && (dest.digit[0] > digit) {
			dest.digit[0] -= digit;
			return .None;
		}
	}

	/*
		If `a` is negative, just do an unsigned addition (with fudged signs).
	*/
	if n, _ := is_neg(a); n {
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
	z, _ := is_zero(a);

	if a.used == 1 && (a.digit[0] <= digit) || z {
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
	return clamp(dest);
}


/*
	dest = src  / 2
	dest = src >> 1
*/
int_halve :: proc(dest, src: ^Int) -> (err: Error) {
	dest := dest; src := src;
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}
	/*
		Grow destination as required.
	*/
	if dest != src {
		if err = grow(dest, src.used); err != .None {
			return err;
		}
	}

	old_used  := dest.used;
	dest.used  = src.used;

	/*
		Carry
	*/
	fwd_carry := DIGIT(0);

	for x := dest.used; x >= 0; x -= 1 {
		/*
			Get the carry for the next iteration.
		*/
		src_digit := src.digit[x];
		carry     := src_digit & 1;
		/*
			Shift the current digit, add in carry and store.
		*/
		dest.digit[x] = (src_digit >> 1) | (fwd_carry << (_DIGIT_BITS - 1));
		/*
			Forward carry to next iteration.
		*/
		fwd_carry = carry;
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
	dest.sign = src.sign;
	return clamp(dest);
}
halve :: proc { int_halve, };
shr1  :: halve;

/*
	dest = src  * 2
	dest = src << 1
*/
int_double :: proc(dest, src: ^Int) -> (err: Error) {
	dest := dest; src := src;
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}
	/*
		Grow destination as required.
	*/
	if dest != src {
		if err = grow(dest, src.used + 1); err != .None {
			return err;
		}
	}

	old_used  := dest.used;
	dest.used  = src.used + 1;

	/*
		Forward carry
	*/
	carry := DIGIT(0);
	for x := 0; x < src.used; x += 1 {
		/*
			Get what will be the *next* carry bit from the MSB of the current digit.
		*/
		src_digit := src.digit[x];
		fwd_carry := src_digit >> (_DIGIT_BITS - 1);

		/*
			Now shift up this digit, add in the carry [from the previous]
		*/
		dest.digit[x] = (src_digit << 1 | carry) & _MASK;

		/*
			Update carry
		*/
		carry = fwd_carry;
	}
	/*
		New leading digit?
	*/
	if carry != 0 {
		/*
			Add a MSB which is always 1 at this point.
		*/
		dest.digit[dest.used] = 1;
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
	dest.sign = src.sign;
	return clamp(dest);
}
double :: proc { int_double, };
shl1   :: double;

/*
	remainder = numerator % (1 << bits)
*/
int_mod_bits :: proc(remainder, numerator: ^Int, bits: int) -> (err: Error) {
	remainder := remainder; numerator := numerator;
	if err = clear_if_uninitialized(remainder); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(numerator); err != .None {
		return err;
	}

	if bits  < 0 { return .Invalid_Argument; }
	if bits == 0 { return zero(remainder); }

	/*
		If the modulus is larger than the value, return the value.
	*/
	err = copy(remainder, numerator);
	if bits >= (numerator.used * _DIGIT_BITS) || err != .None {
		return;
	}

	/*
		Zero digits above the last digit of the modulus.
	*/
	zero_count := (bits / _DIGIT_BITS) + 0 if (bits % _DIGIT_BITS == 0) else 1;
	/*
		Zero remainder.
	*/
	if zero_count > 0 {
		mem.zero_slice(remainder.digit[zero_count:]);
	}

	/*
		Clear the digit that is not completely outside/inside the modulus.
	*/
	remainder.digit[bits / _DIGIT_BITS] &= DIGIT(1 << DIGIT(bits % _DIGIT_BITS)) - DIGIT(1);
	return clamp(remainder);
}
mod_bits :: proc { int_mod_bits, };

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
	if err = clear_if_uninitialized(x); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(y); err != .None {
		return err;
	}

	old_used, min_used, max_used, i: int;

	if x.used < y.used {
		x, y = y, x;
	}

	min_used = x.used;
	max_used = y.used;
	old_used = dest.used;

	if err = grow(dest, max(max_used + 1, _DEFAULT_DIGIT_COUNT)); err != .None {
		return err;
	}
	dest.used = max_used + 1;
	/*
		All parameters have been initialized.
	*/

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
	return clamp(dest);
}

/*
	Low-level subtraction, dest = number - decrease. Assumes |number| > |decrease|.
	Handbook of Applied Cryptography, algorithm 14.9.
*/
_int_sub :: proc(dest, number, decrease: ^Int) -> (err: Error) {
	dest := dest; x := number; y := decrease;
	if err = clear_if_uninitialized(x); err != .None {
		return err;
	}
	if err = clear_if_uninitialized(y); err != .None {
		return err;
	}

	old_used := dest.used;
	min_used := y.used;
	max_used := x.used;
	i: int;

	if err = grow(dest, max(max_used, _DEFAULT_DIGIT_COUNT)); err != .None {
		return err;
	}
	dest.used = max_used;
	/*
		All parameters have been initialized.
	*/

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
	return clamp(dest);
}