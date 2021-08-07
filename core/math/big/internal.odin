//+ignore
package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	==========================    Low-level routines    ==========================

	IMPORTANT: `internal_*` procedures make certain assumptions about their input.

	The public functions that call them are expected to satisfy their sanity check requirements.
	This allows `internal_*` call `internal_*` without paying this overhead multiple times.

	Where errors can occur, they are of course still checked and returned as appropriate.

	When importing `math:core/big` to implement an involved algorithm of your own, you are welcome
	to use these procedures instead of their public counterparts.

	Most inputs and outputs are expected to be passed an initialized `Int`, for example.
	Exceptions include `quotient` and `remainder`, which are allowed to be `nil` when the calling code doesn't need them.

	Check the comments above each `internal_*` implementation to see what constraints it expects to have met.

	TODO: Handle +/- Infinity and NaN.
*/

import "core:mem"
import "core:intrinsics"

/*
	Low-level addition, unsigned. Handbook of Applied Cryptography, algorithm 14.7.

	Assumptions:
		`dest`, `a` and `b` != `nil` and have been initalized.
*/
internal_int_add_unsigned :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	dest := dest; x := a; y := b;

	old_used, min_used, max_used, i: int;

	if x.used < y.used {
		x, y = y, x;
		assert(x.used >= y.used);
	}

	min_used = y.used;
	max_used = x.used;
	old_used = dest.used;

	if err = grow(dest, max(max_used + 1, _DEFAULT_DIGIT_COUNT), false, allocator); err != nil { return err; }
	dest.used = max_used + 1;
	/*
		All parameters have been initialized.
	*/

	/* Zero the carry */
	carry := DIGIT(0);

	#no_bounds_check for i = 0; i < min_used; i += 1 {
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
		#no_bounds_check for ; i < max_used; i += 1 {
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

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used);
	/*
		Adjust dest.used based on leading zeroes.
	*/
	return clamp(dest);
}
internal_add_unsigned :: proc { internal_int_add_unsigned, };

/*
	Low-level addition, signed. Handbook of Applied Cryptography, algorithm 14.7.

	Assumptions:
		`dest`, `a` and `b` != `nil` and have been initalized.
*/
internal_int_add_signed :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	x := a; y := b;
	/*
		Handle both negative or both positive.
	*/
	if x.sign == y.sign {
		dest.sign = x.sign;
		return #force_inline internal_int_add_unsigned(dest, x, y, allocator);
	}

	/*
		One positive, the other negative.
		Subtract the one with the greater magnitude from the other.
		The result gets the sign of the one with the greater magnitude.
	*/
	if c, _ := #force_inline cmp_mag(a, b); c == -1 {
		x, y = y, x;
	}

	dest.sign = x.sign;
	return #force_inline internal_int_sub_unsigned(dest, x, y, allocator);
}
internal_add_signed :: proc { internal_int_add_signed, };

/*
	Low-level addition Int+DIGIT, signed. Handbook of Applied Cryptography, algorithm 14.7.

	Assumptions:
		`dest` and `a` != `nil` and have been initalized.
		`dest` is large enough (a.used + 1) to fit result.
*/
internal_int_add_digit :: proc(dest, a: ^Int, digit: DIGIT) -> (err: Error) {
	/*
		Fast paths for destination and input Int being the same.
	*/
	if dest == a {
		/*
			Fast path for dest.digit[0] + digit fits in dest.digit[0] without overflow.
		*/
		if dest.sign == .Zero_or_Positive && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit;
			dest.used += 1;
			return clamp(dest);
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if a.sign == .Negative && (dest.digit[0] > digit) {
			dest.digit[0] -= digit;
			dest.used += 1;
			return clamp(dest);
		}
	}

	/*
		If `a` is negative and `|a|` >= `digit`, call `dest = |a| - digit`
	*/
	if a.sign == .Negative && (a.used > 1 || a.digit[0] >= digit) {
		/*
			Temporarily fix `a`'s sign.
		*/
		a.sign = .Zero_or_Positive;
		/*
			dest = |a| - digit
		*/
		if err =  #force_inline internal_int_add_digit(dest, a, digit); err != nil {
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
	if a.sign == .Zero_or_Positive {
		/*
			Add digits, use `carry`.
		*/
		i: int;
		carry := digit;
		#no_bounds_check for i = 0; i < a.used; i += 1 {
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

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used);

	/*
		Adjust dest.used based on leading zeroes.
	*/
	return clamp(dest);	
}
internal_add :: proc { internal_int_add_signed, internal_int_add_digit, };

/*
	Low-level subtraction, dest = number - decrease. Assumes |number| > |decrease|.
	Handbook of Applied Cryptography, algorithm 14.9.

	Assumptions:
		`dest`, `number` and `decrease` != `nil` and have been initalized.
*/
internal_int_sub_unsigned :: proc(dest, number, decrease: ^Int, allocator := context.allocator) -> (err: Error) {
	dest := dest; x := number; y := decrease;
	old_used := dest.used;
	min_used := y.used;
	max_used := x.used;
	i: int;

	if err = grow(dest, max(max_used, _DEFAULT_DIGIT_COUNT), false, allocator); err != nil { return err; }
	dest.used = max_used;
	/*
		All parameters have been initialized.
	*/

	borrow := DIGIT(0);

	#no_bounds_check for i = 0; i < min_used; i += 1 {
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
	#no_bounds_check for ; i < max_used; i += 1 {
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

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used);

	/*
		Adjust dest.used based on leading zeroes.
	*/
	return clamp(dest);
}
internal_sub_unsigned :: proc { internal_int_sub_unsigned, };

/*
	Low-level subtraction, signed. Handbook of Applied Cryptography, algorithm 14.9.
	dest = number - decrease. Assumes |number| > |decrease|.

	Assumptions:
		`dest`, `number` and `decrease` != `nil` and have been initalized.
*/
internal_int_sub_signed :: proc(dest, number, decrease: ^Int, allocator := context.allocator) -> (err: Error) {
	number := number; decrease := decrease;
	if number.sign != decrease.sign {
		/*
			Subtract a negative from a positive, OR subtract a positive from a negative.
			In either case, ADD their magnitudes and use the sign of the first number.
		*/
		dest.sign = number.sign;
		return #force_inline internal_int_add_unsigned(dest, number, decrease, allocator);
	}

	/*
		Subtract a positive from a positive, OR negative from a negative.
		First, take the difference between their magnitudes, then...
	*/
	if c, _ := #force_inline cmp_mag(number, decrease); c == -1 {
		/*
			The second has a larger magnitude.
			The result has the *opposite* sign from the first number.
		*/
		dest.sign = .Negative if number.sign == .Zero_or_Positive else .Zero_or_Positive;
		number, decrease = decrease, number;
	} else {
		/*
			The first has a larger or equal magnitude.
			Copy the sign from the first.
		*/
		dest.sign = number.sign;
	}
	return #force_inline internal_int_sub_unsigned(dest, number, decrease, allocator);
}

/*
	Low-level subtraction, signed. Handbook of Applied Cryptography, algorithm 14.9.
	dest = number - decrease. Assumes |number| > |decrease|.

	Assumptions:
		`dest`, `number` != `nil` and have been initalized.
		`dest` is large enough (number.used + 1) to fit result.
*/
internal_int_sub_digit :: proc(dest, number: ^Int, digit: DIGIT) -> (err: Error) {
	dest := dest; digit := digit;
	/*
		All parameters have been initialized.

		Fast paths for destination and input Int being the same.
	*/
	if dest == number {
		/*
			Fast path for `dest` is negative and unsigned addition doesn't overflow the lowest digit.
		*/
		if dest.sign == .Negative && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit;
			return nil;
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if number.sign == .Zero_or_Positive && (dest.digit[0] > digit) {
			dest.digit[0] -= digit;
			return nil;
		}
	}

	/*
		If `a` is negative, just do an unsigned addition (with fudged signs).
	*/
	if number.sign == .Negative {
		t := number;
		t.sign = .Zero_or_Positive;

		err =  #force_inline internal_int_add_digit(dest, t, digit);
		dest.sign = .Negative;

		clamp(dest);
		return err;
	}

	old_used := dest.used;

	/*
		if `a`<= digit, simply fix the single digit.
	*/
	if number.used == 1 && (number.digit[0] <= digit) || number.used == 0 {
		dest.digit[0] = digit - number.digit[0] if number.used == 1 else digit;
		dest.sign = .Negative;
		dest.used = 1;
	} else {
		dest.sign = .Zero_or_Positive;
		dest.used = number.used;

		/*
			Subtract with carry.
		*/
		carry := digit;

		#no_bounds_check for i := 0; i < number.used; i += 1 {
			dest.digit[i] = number.digit[i] - carry;
			carry = dest.digit[i] >> (_DIGIT_TYPE_BITS - 1);
			dest.digit[i] &= _MASK;
		}
	}

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used);

	/*
		Adjust dest.used based on leading zeroes.
	*/
	return clamp(dest);
}

internal_sub :: proc { internal_int_sub_signed, internal_int_sub_digit, };

/*
	dest = src  / 2
	dest = src >> 1
*/
internal_int_shr1 :: proc(dest, src: ^Int) -> (err: Error) {
	old_used  := dest.used; dest.used = src.used;
	/*
		Carry
	*/
	fwd_carry := DIGIT(0);

	#no_bounds_check for x := dest.used - 1; x >= 0; x -= 1 {
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

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used);

	/*
		Adjust dest.used based on leading zeroes.
	*/
	dest.sign = src.sign;
	return clamp(dest);	
}

/*
	dest = src  * 2
	dest = src << 1
*/
internal_int_shl1 :: proc(dest, src: ^Int) -> (err: Error) {
	if err = copy(dest, src); err != nil { return err; }
	/*
		Grow `dest` to accommodate the additional bits.
	*/
	digits_needed := dest.used + 1;
	if err = grow(dest, digits_needed); err != nil { return err; }
	dest.used = digits_needed;

	mask  := (DIGIT(1) << uint(1)) - DIGIT(1);
	shift := DIGIT(_DIGIT_BITS - 1);
	carry := DIGIT(0);

	#no_bounds_check for x:= 0; x < dest.used; x+= 1 {		
		fwd_carry := (dest.digit[x] >> shift) & mask;
		dest.digit[x] = (dest.digit[x] << uint(1) | carry) & _MASK;
		carry = fwd_carry;
	}
	/*
		Use final carry.
	*/
	if carry != 0 {
		dest.digit[dest.used] = carry;
		dest.used += 1;
	}
	return clamp(dest);
}

/*
	Multiply by a DIGIT.
*/
internal_int_mul_digit :: proc(dest, src: ^Int, multiplier: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert(dest != nil && src != nil);

	if multiplier == 0 {
		return zero(dest);
	}
	if multiplier == 1 {
		return copy(dest, src);
	}

	/*
		Power of two?
	*/
	if multiplier == 2 {
		return #force_inline internal_int_shl1(dest, src);
	}
	if is_power_of_two(int(multiplier)) {
		ix: int;
		if ix, err = log(multiplier, 2); err != nil { return err; }
		return shl(dest, src, ix);
	}

	/*
		Ensure `dest` is big enough to hold `src` * `multiplier`.
	*/
	if err = grow(dest, max(src.used + 1, _DEFAULT_DIGIT_COUNT), false, allocator); err != nil { return err; }

	/*
		Save the original used count.
	*/
	old_used := dest.used;
	/*
		Set the sign.
	*/
	dest.sign = src.sign;
	/*
		Set up carry.
	*/
	carry := _WORD(0);
	/*
		Compute columns.
	*/
	ix := 0;
	for ; ix < src.used; ix += 1 {
		/*
			Compute product and carry sum for this term
		*/
		product := carry + _WORD(src.digit[ix]) * _WORD(multiplier);
		/*
			Mask off higher bits to get a single DIGIT.
		*/
		dest.digit[ix] = DIGIT(product & _WORD(_MASK));
		/*
			Send carry into next iteration
		*/
		carry = product >> _DIGIT_BITS;
	}

	/*
		Store final carry [if any] and increment used.
	*/
	dest.digit[ix] = DIGIT(carry);
	dest.used = src.used + 1;

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used);

	return clamp(dest);
}

/*
	High level multiplication (handles sign).
*/
internal_int_mul :: proc(dest, src, multiplier: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Early out for `multiplier` is zero; Set `dest` to zero.
	*/
	if multiplier.used == 0 || src.used == 0 { return zero(dest); }

	if src == multiplier {
		/*
			Do we need to square?
		*/
		if        false && src.used >= SQR_TOOM_CUTOFF {
			/* Use Toom-Cook? */
			// err = s_mp_sqr_toom(a, c);
		} else if false && src.used >= SQR_KARATSUBA_CUTOFF {
			/* Karatsuba? */
			// err = s_mp_sqr_karatsuba(a, c);
		} else if false && ((src.used * 2) + 1) < _WARRAY &&
		                   src.used < (_MAX_COMBA / 2) {
			/* Fast comba? */
			// err = s_mp_sqr_comba(a, c);
		} else {
			err = _private_int_sqr(dest, src);
		}
	} else {
		/*
			Can we use the balance method? Check sizes.
			* The smaller one needs to be larger than the Karatsuba cut-off.
			* The bigger one needs to be at least about one `_MUL_KARATSUBA_CUTOFF` bigger
			* to make some sense, but it depends on architecture, OS, position of the
			* stars... so YMMV.
			* Using it to cut the input into slices small enough for _mul_comba
			* was actually slower on the author's machine, but YMMV.
		*/

		min_used := min(src.used, multiplier.used);
		max_used := max(src.used, multiplier.used);
		digits   := src.used + multiplier.used + 1;

		if        false &&  min_used     >= MUL_KARATSUBA_CUTOFF &&
						    max_used / 2 >= MUL_KARATSUBA_CUTOFF &&
			/*
				Not much effect was observed below a ratio of 1:2, but again: YMMV.
			*/
							max_used     >= 2 * min_used {
			// err = s_mp_mul_balance(a,b,c);
		} else if false && min_used >= MUL_TOOM_CUTOFF {
			// err = s_mp_mul_toom(a, b, c);
		} else if false && min_used >= MUL_KARATSUBA_CUTOFF {
			// err = s_mp_mul_karatsuba(a, b, c);
		} else if digits < _WARRAY && min_used <= _MAX_COMBA {
			/*
				Can we use the fast multiplier?
				* The fast multiplier can be used if the output will
				* have less than MP_WARRAY digits and the number of
				* digits won't affect carry propagation
			*/
			err = _private_int_mul_comba(dest, src, multiplier, digits);
		} else {
			err = _private_int_mul(dest, src, multiplier, digits);
		}
	}
	neg := src.sign != multiplier.sign;
	dest.sign = .Negative if dest.used > 0 && neg else .Zero_or_Positive;
	return err;
}

internal_mul :: proc { internal_int_mul, internal_int_mul_digit, };

/*
	divmod.
	Both the quotient and remainder are optional and may be passed a nil.
*/
internal_int_divmod :: proc(quotient, remainder, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {

	if denominator.used == 0 { return .Division_by_Zero; }
	/*
		If numerator < denominator then quotient = 0, remainder = numerator.
	*/
	c: int;
	if c, err = #force_inline cmp_mag(numerator, denominator); c == -1 {
		if remainder != nil {
			if err = copy(remainder, numerator, false, allocator); err != nil { return err; }
		}
		if quotient != nil {
			zero(quotient);
		}
		return nil;
	}

	if false && (denominator.used > 2 * MUL_KARATSUBA_CUTOFF) && (denominator.used <= (numerator.used/3) * 2) {
		// err = _int_div_recursive(quotient, remainder, numerator, denominator);
	} else {
		when true {
			err = #force_inline _private_int_div_school(quotient, remainder, numerator, denominator);
		} else {
			/*
				NOTE(Jeroen): We no longer need or use `_private_int_div_small`.
				We'll keep it around for a bit until we're reasonably certain div_school is bug free.
			*/
			err = _private_int_div_small(quotient, remainder, numerator, denominator);
		}
	}
	return;
}

/*
	Single digit division (based on routine from MPI).
	The quotient is optional and may be passed a nil.
*/
internal_int_divmod_digit :: proc(quotient, numerator: ^Int, denominator: DIGIT) -> (remainder: DIGIT, err: Error) {
	/*
		Cannot divide by zero.
	*/
	if denominator == 0 { return 0, .Division_by_Zero; }

	/*
		Quick outs.
	*/
	if denominator == 1 || numerator.used == 0 {
		if quotient != nil {
			return 0, copy(quotient, numerator);
		}
		return 0, err;
	}
	/*
		Power of two?
	*/
	if denominator == 2 {
		if numerator.used > 0 && numerator.digit[0] & 1 != 0 {
			// Remainder is 1 if numerator is odd.
			remainder = 1;
		}
		if quotient == nil {
			return remainder, nil;
		}
		return remainder, shr(quotient, numerator, 1);
	}

	ix: int;
	if is_power_of_two(int(denominator)) {
		ix = 1;
		for ix < _DIGIT_BITS && denominator != (1 << uint(ix)) {
			ix += 1;
		}
		remainder = numerator.digit[0] & ((1 << uint(ix)) - 1);
		if quotient == nil {
			return remainder, nil;
		}

		return remainder, shr(quotient, numerator, int(ix));
	}

	/*
		Three?
	*/
	if denominator == 3 {
		return _private_int_div_3(quotient, numerator);
	}

	/*
		No easy answer [c'est la vie].  Just division.
	*/
	q := &Int{};

	if err = grow(q, numerator.used); err != nil { return 0, err; }

	q.used = numerator.used;
	q.sign = numerator.sign;

	w := _WORD(0);

	for ix = numerator.used - 1; ix >= 0; ix -= 1 {
		t := DIGIT(0);
		w = (w << _WORD(_DIGIT_BITS) | _WORD(numerator.digit[ix]));
		if w >= _WORD(denominator) {
			t = DIGIT(w / _WORD(denominator));
			w -= _WORD(t) * _WORD(denominator);
		}
		q.digit[ix] = t;
	}
	remainder = DIGIT(w);

	if quotient != nil {
		clamp(q);
		swap(q, quotient);
	}
	destroy(q);
	return remainder, nil;
}

internal_divmod :: proc { internal_int_divmod, internal_int_divmod_digit, };

/*
	Asssumes quotient, numerator and denominator to have been initialized and not to be nil.
*/
internal_int_div :: proc(quotient, numerator, denominator: ^Int) -> (err: Error) {
	return #force_inline internal_int_divmod(quotient, nil, numerator, denominator);
}
internal_div :: proc { internal_int_div, };

/*
	remainder = numerator % denominator.
	0 <= remainder < denominator if denominator > 0
	denominator < remainder <= 0 if denominator < 0

	Asssumes quotient, numerator and denominator to have been initialized and not to be nil.
*/
internal_int_mod :: proc(remainder, numerator, denominator: ^Int) -> (err: Error) {
	if err = #force_inline internal_int_divmod(nil, remainder, numerator, denominator); err != nil { return err; }

	if remainder.used == 0 || denominator.sign == remainder.sign { return nil; }

	return #force_inline internal_add(remainder, remainder, numerator);
}
internal_mod :: proc{ internal_int_mod, };

/*
	remainder = (number + addend) % modulus.
*/
internal_int_addmod :: proc(remainder, number, addend, modulus: ^Int) -> (err: Error) {
	if err = #force_inline internal_add(remainder, number, addend); err != nil { return err; }
	return #force_inline internal_mod(remainder, remainder, modulus);
}
internal_addmod :: proc { internal_int_addmod, };

/*
	remainder = (number - decrease) % modulus.
*/
internal_int_submod :: proc(remainder, number, decrease, modulus: ^Int) -> (err: Error) {
	if err = #force_inline internal_sub(remainder, number, decrease); err != nil { return err; }
	return #force_inline internal_mod(remainder, remainder, modulus);
}
internal_submod :: proc { internal_int_submod, };

/*
	remainder = (number * multiplicand) % modulus.
*/
internal_int_mulmod :: proc(remainder, number, multiplicand, modulus: ^Int) -> (err: Error) {
	if err = #force_inline internal_mul(remainder, number, multiplicand); err != nil { return err; }
	return #force_inline internal_mod(remainder, remainder, modulus);
}
internal_mulmod :: proc { internal_int_mulmod, };

/*
	remainder = (number * number) % modulus.
*/
internal_int_sqrmod :: proc(remainder, number, modulus: ^Int) -> (err: Error) {
	if err = #force_inline internal_mul(remainder, number, number); err != nil { return err; }
	return #force_inline internal_mod(remainder, remainder, modulus);
}
internal_sqrmod :: proc { internal_int_sqrmod, };



/*
	TODO: Use Sterling's Approximation to estimate log2(N!) to size the result.
	This way we'll have to reallocate less, possibly not at all.
*/
internal_int_factorial :: proc(res: ^Int, n: int) -> (err: Error) {
	if n >= FACTORIAL_BINARY_SPLIT_CUTOFF {
		return #force_inline _private_int_factorial_binary_split(res, n);
	}

	i := len(_factorial_table);
	if n < i {
		return #force_inline set(res, _factorial_table[n]);
	}

	if err = #force_inline set(res, _factorial_table[i - 1]); err != nil { return err; }
	for {
		if err = #force_inline internal_mul(res, res, DIGIT(i)); err != nil || i == n { return err; }
		i += 1;
	}

	return nil;
}

/*
	Returns GCD, LCM or both.

	Assumes `a` and `b` to have been initialized.
	`res_gcd` and `res_lcm` can be nil or ^Int depending on which results are desired.
*/
internal_int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int) -> (err: Error) {
	if res_gcd == nil && res_lcm == nil { return nil; }

	return #force_inline _private_int_gcd_lcm(res_gcd, res_lcm, a, b);
}

/*
	remainder = numerator % (1 << bits)

	Assumes `remainder` and `numerator` both not to be `nil` and `bits` to be >= 0.
*/
internal_int_mod_bits :: proc(remainder, numerator: ^Int, bits: int) -> (err: Error) {
	/*
		Everything is divisible by 1 << 0 == 1, so this returns 0.
	*/
	if bits == 0 { return zero(remainder); }

	/*
		If the modulus is larger than the value, return the value.
	*/
	err = copy(remainder, numerator);
	if bits >= (numerator.used * _DIGIT_BITS) || err != nil {
		return;
	}

	/*
		Zero digits above the last digit of the modulus.
	*/
	zero_count := (bits / _DIGIT_BITS);
	zero_count += 0 if (bits % _DIGIT_BITS == 0) else 1;

	/*
		Zero remainder. Special case, can't use `zero_unused`.
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

/*
	=============================    Low-level helpers    =============================


	`internal_*` helpers don't return an `Error` like their public counterparts do,
	because they expect not to be passed `nil` or uninitialized inputs.

	This makes them more suitable for `internal_*` functions and some of the
	public ones that have already satisfied these constraints.
*/

/*
	This procedure will return `true` if the `Int` is initialized, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_initialized :: #force_inline proc(a: ^Int) -> (initialized: bool) {
	raw := transmute(mem.Raw_Dynamic_Array)a.digit;
	return raw.cap >= _MIN_DIGIT_COUNT;
}
internal_is_initialized :: proc { internal_int_is_initialized, };

/*
	This procedure will return `true` if the `Int` is zero, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_zero :: #force_inline proc(a: ^Int) -> (zero: bool) {
	return a.used == 0;
}
internal_is_zero :: proc { internal_int_is_zero, };

/*
	This procedure will return `true` if the `Int` is positive, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_positive :: #force_inline proc(a: ^Int) -> (positive: bool) {
	return a.sign == .Zero_or_Positive;
}
internal_is_positive :: proc { internal_int_is_positive, };

/*
	This procedure will return `true` if the `Int` is negative, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_negative :: #force_inline proc(a: ^Int) -> (negative: bool) {
	return a.sign == .Negative;
}
internal_is_negative :: proc { internal_int_is_negative, };

/*
	This procedure will return `true` if the `Int` is even, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_even :: #force_inline proc(a: ^Int) -> (even: bool) {
	if internal_is_zero(a) { return true; }

	/*
		`a.used` > 0 here, because the above handled `is_zero`.
		We don't need to explicitly test it.
	*/
	return a.digit[0] & 1 == 0;
}
internal_is_even :: proc { internal_int_is_even, };

/*
	This procedure will return `true` if the `Int` is even, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_odd :: #force_inline proc(a: ^Int) -> (odd: bool) {
	return !internal_int_is_even(a);
}
internal_is_odd :: proc { internal_int_is_odd, };


/*
	This procedure will return `true` if the `Int` is a power of two, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_power_of_two :: #force_inline proc(a: ^Int) -> (power_of_two: bool) {
	/*
		Early out for Int == 0.
	*/
	if #force_inline internal_is_zero(a) { return true; }

	/*
		For an `Int` to be a power of two, its bottom limb has to be a power of two.
	*/
	if ! #force_inline platform_int_is_power_of_two(int(a.digit[a.used - 1])) { return false; }

	/*
		We've established that the bottom limb is a power of two.
		If it's the only limb, that makes the entire Int a power of two.
	*/
	if a.used == 1 { return true; }

	/*
		For an `Int` to be a power of two, all limbs except the top one have to be zero.
	*/
	for i := 1; i < a.used && a.digit[i - 1] != 0; i += 1 { return false; }

	return true;
}
internal_is_power_of_two :: proc { internal_int_is_power_of_two, };

/*
	Compare two `Int`s, signed.
	Returns -1 if `a` < `b`, 0 if `a` == `b` and 1 if `b` > `a`.

	Expects `a` and `b` both to be valid `Int`s, i.e. initialized and not `nil`.
*/
internal_int_compare :: #force_inline proc(a, b: ^Int) -> (comparison: int) {
	a_is_negative := #force_inline internal_is_negative(a);

	/*
		Compare based on sign.
	*/
	if a.sign != b.sign { return -1 if a_is_negative else +1; }

	/*
		If `a` is negative, compare in the opposite direction */
	if a_is_negative { return #force_inline internal_compare_magnitude(b, a); }

	return #force_inline internal_compare_magnitude(a, b);
}
internal_compare :: proc { internal_int_compare, internal_int_compare_digit, };
internal_cmp :: internal_compare;

/*
	Compare an `Int` to an unsigned number upto the size of the backing type.

	Returns -1 if `a` < `b`, 0 if `a` == `b` and 1 if `b` > `a`.

	Expects `a` and `b` both to be valid `Int`s, i.e. initialized and not `nil`.
*/
internal_int_compare_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (comparison: int) {
	/*
		Compare based on sign.
	*/

	if #force_inline internal_is_negative(a) { return -1; }

	/*
		Compare based on magnitude.
	*/
	if a.used > 1 { return +1; }

	/*
		Compare the only digit in `a` to `b`.
	*/
	switch {
	case a.digit[0] < b:
		return -1;
	case a.digit[0] == b:
		return  0;
	case a.digit[0] > b:
		return +1;
	case:
		/*
			Unreachable.
			Just here because Odin complains about a missing return value at the bottom of the proc otherwise.
		*/
		return;
	}
}
internal_compare_digit :: proc { internal_int_compare_digit, };
internal_cmp_digit :: internal_compare_digit;

/*
	Compare the magnitude of two `Int`s, unsigned.
*/
internal_int_compare_magnitude :: #force_inline proc(a, b: ^Int) -> (comparison: int) {
	/*
		Compare based on used digits.
	*/
	if a.used != b.used {
		if a.used > b.used {
			return +1;
		}
		return -1;
	}

	/*
		Same number of used digits, compare based on their value.
	*/
	#no_bounds_check for n := a.used - 1; n >= 0; n -= 1 {
		if a.digit[n] != b.digit[n] {
			if a.digit[n] > b.digit[n] {
				return +1;
			}
			return -1;
		}
	}

   	return 0;
}
internal_compare_magnitude :: proc { internal_int_compare_magnitude, };
internal_cmp_mag :: internal_compare_magnitude;


internal_int_zero_unused :: #force_inline proc(dest: ^Int, old_used := -1) {
	/*
		If we don't pass the number of previously used DIGITs, we zero all remaining ones.
	*/
	zero_count: int;
	if old_used == -1 {
		zero_count = len(dest.digit) - dest.used;
	} else {
		zero_count = old_used - dest.used;
	}

	/*
		Zero remainder.
	*/
	if zero_count > 0 && dest.used < len(dest.digit) {
		mem.zero_slice(dest.digit[dest.used:][:zero_count]);
	}
}

internal_zero_unused :: proc { internal_int_zero_unused, };


/*
	==========================    End of low-level routines   ==========================

	=============================    Private procedures    =============================

	Private procedures used by the above low-level routines follow.

	Don't call these yourself unless you really know what you're doing.
	They include implementations that are optimimal for certain ranges of input only.

	These aren't exported for the same reasons.
*/


/*
	Multiplies |a| * |b| and only computes upto digs digits of result.
	HAC pp. 595, Algorithm 14.12  Modified so you can control how
	many digits of output are created.
*/
_private_int_mul :: proc(dest, a, b: ^Int, digits: int) -> (err: Error) {
	/*
		Can we use the fast multiplier?
	*/
	if digits < _WARRAY && min(a.used, b.used) < _MAX_COMBA {
		return _private_int_mul_comba(dest, a, b, digits);
	}

	/*
		Set up temporary output `Int`, which we'll swap for `dest` when done.
	*/

	t := &Int{};

	if err = grow(t, max(digits, _DEFAULT_DIGIT_COUNT)); err != nil { return err; }
	t.used = digits;

	/*
		Compute the digits of the product directly.
	*/
	pa := a.used;
	for ix := 0; ix < pa; ix += 1 {
		/*
			Limit ourselves to `digits` DIGITs of output.
		*/
		pb    := min(b.used, digits - ix);
		carry := _WORD(0);
		iy    := 0;

		/*
			Compute the column of the output and propagate the carry.
		*/
		#no_bounds_check for iy = 0; iy < pb; iy += 1 {
			/*
				Compute the column as a _WORD.
			*/
			column := _WORD(t.digit[ix + iy]) + _WORD(a.digit[ix]) * _WORD(b.digit[iy]) + carry;

			/*
				The new column is the lower part of the result.
			*/
			t.digit[ix + iy] = DIGIT(column & _WORD(_MASK));

			/*
				Get the carry word from the result.
			*/
			carry = column >> _DIGIT_BITS;
		}
		/*
			Set carry if it is placed below digits
		*/
		if ix + iy < digits {
			t.digit[ix + pb] = DIGIT(carry);
		}
	}

	swap(dest, t);
	destroy(t);
	return clamp(dest);
}

/*
	Fast (comba) multiplier

	This is the fast column-array [comba] multiplier.  It is
	designed to compute the columns of the product first
	then handle the carries afterwards.  This has the effect
	of making the nested loops that compute the columns very
	simple and schedulable on super-scalar processors.

	This has been modified to produce a variable number of
	digits of output so if say only a half-product is required
	you don't have to compute the upper half (a feature
	required for fast Barrett reduction).

	Based on Algorithm 14.12 on pp.595 of HAC.
*/
_private_int_mul_comba :: proc(dest, a, b: ^Int, digits: int) -> (err: Error) {
	/*
		Set up array.
	*/
	W: [_WARRAY]DIGIT = ---;

	/*
		Grow the destination as required.
	*/
	if err = grow(dest, digits); err != nil { return err; }

	/*
		Number of output digits to produce.
	*/
	pa := min(digits, a.used + b.used);

	/*
		Clear the carry
	*/
	_W := _WORD(0);

	ix: int;
	for ix = 0; ix < pa; ix += 1 {
		tx, ty, iy, iz: int;

		/*
			Get offsets into the two bignums.
		*/
		ty = min(b.used - 1, ix);
		tx = ix - ty;

		/*
			This is the number of times the loop will iterate, essentially.
			while (tx++ < a->used && ty-- >= 0) { ... }
		*/
		 
		iy = min(a.used - tx, ty + 1);

		/*
			Execute loop.
		*/
		#no_bounds_check for iz = 0; iz < iy; iz += 1 {
			_W += _WORD(a.digit[tx + iz]) * _WORD(b.digit[ty - iz]);
		}

		/*
			Store term.
		*/
		W[ix] = DIGIT(_W) & _MASK;

		/*
			Make next carry.
		*/
		_W = _W >> _WORD(_DIGIT_BITS);
	}

	/*
		Setup dest.
	*/
	old_used := dest.used;
	dest.used = pa;

	/*
		Now extract the previous digit [below the carry].
	*/
	copy_slice(dest.digit[0:], W[:pa]);	

	/*
		Clear unused digits [that existed in the old copy of dest].
	*/
	zero_unused(dest, old_used);

	/*
		Adjust dest.used based on leading zeroes.
	*/

	return clamp(dest);
}

/*
	Low level squaring, b = a*a, HAC pp.596-597, Algorithm 14.16
*/
_private_int_sqr :: proc(dest, src: ^Int) -> (err: Error) {
	pa := src.used;

	t := &Int{}; ix, iy: int;
	/*
		Grow `t` to maximum needed size, or `_DEFAULT_DIGIT_COUNT`, whichever is bigger.
	*/
	if err = grow(t, max((2 * pa) + 1, _DEFAULT_DIGIT_COUNT)); err != nil { return err; }
	t.used = (2 * pa) + 1;

	#no_bounds_check for ix = 0; ix < pa; ix += 1 {
		carry := DIGIT(0);
		/*
			First calculate the digit at 2*ix; calculate double precision result.
		*/
		r := _WORD(t.digit[ix+ix]) + (_WORD(src.digit[ix]) * _WORD(src.digit[ix]));

		/*
			Store lower part in result.
		*/
		t.digit[ix+ix] = DIGIT(r & _WORD(_MASK));
		/*
			Get the carry.
		*/
		carry = DIGIT(r >> _DIGIT_BITS);

		#no_bounds_check for iy = ix + 1; iy < pa; iy += 1 {
			/*
				First calculate the product.
			*/
			r = _WORD(src.digit[ix]) * _WORD(src.digit[iy]);

			/* Now calculate the double precision result. Nóte we use
			 * addition instead of *2 since it's easier to optimize
			 */
			r = _WORD(t.digit[ix+iy]) + r + r + _WORD(carry);

			/*
				Store lower part.
			*/
			t.digit[ix+iy] = DIGIT(r & _WORD(_MASK));

			/*
				Get carry.
			*/
			carry = DIGIT(r >> _DIGIT_BITS);
		}
		/*
			Propagate upwards.
		*/
		#no_bounds_check for carry != 0 {
			r     = _WORD(t.digit[ix+iy]) + _WORD(carry);
			t.digit[ix+iy] = DIGIT(r & _WORD(_MASK));
			carry = DIGIT(r >> _WORD(_DIGIT_BITS));
			iy += 1;
		}
	}

	err = clamp(t);
	swap(dest, t);
	destroy(t);
	return err;
}

/*
	Divide by three (based on routine from MPI and the GMP manual).
*/
_private_int_div_3 :: proc(quotient, numerator: ^Int) -> (remainder: DIGIT, err: Error) {
	/*
		b = 2^_DIGIT_BITS / 3
	*/
 	b := _WORD(1) << _WORD(_DIGIT_BITS) / _WORD(3);

	q := &Int{};
	if err = grow(q, numerator.used); err != nil { return 0, err; }
	q.used = numerator.used;
	q.sign = numerator.sign;

	w, t: _WORD;
	#no_bounds_check for ix := numerator.used; ix >= 0; ix -= 1 {
		w = (w << _WORD(_DIGIT_BITS)) | _WORD(numerator.digit[ix]);
		if w >= 3 {
			/*
				Multiply w by [1/3].
			*/
			t = (w * b) >> _WORD(_DIGIT_BITS);

			/*
				Now subtract 3 * [w/3] from w, to get the remainder.
			*/
			w -= t+t+t;

			/*
				Fixup the remainder as required since the optimization is not exact.
			*/
			for w >= 3 {
				t += 1;
				w -= 3;
			}
		} else {
			t = 0;
		}
		q.digit[ix] = DIGIT(t);
	}
	remainder = DIGIT(w);

	/*
		[optional] store the quotient.
	*/
	if quotient != nil {
		err = clamp(q);
 		swap(q, quotient);
 	}
	destroy(q);
	return remainder, nil;
}

/*
	Signed Integer Division

	c*b + d == a [i.e. a/b, c=quotient, d=remainder], HAC pp.598 Algorithm 14.20

	Note that the description in HAC is horribly incomplete.
	For example, it doesn't consider the case where digits are removed from 'x' in
	the inner loop.

	It also doesn't consider the case that y has fewer than three digits, etc.
	The overall algorithm is as described as 14.20 from HAC but fixed to treat these cases.
*/
_private_int_div_school :: proc(quotient, remainder, numerator, denominator: ^Int) -> (err: Error) {
	// if err = error_if_immutable(quotient, remainder); err != nil { return err; }
	// if err = clear_if_uninitialized(quotient, numerator, denominator); err != nil { return err; }

	q, x, y, t1, t2 := &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(q, x, y, t1, t2);

	if err = grow(q, numerator.used + 2); err != nil { return err; }
	q.used = numerator.used + 2;

	if err = init_multi(t1, t2);   err != nil { return err; }
	if err = copy(x, numerator);   err != nil { return err; }
	if err = copy(y, denominator); err != nil { return err; }

	/*
		Fix the sign.
	*/
	neg   := numerator.sign != denominator.sign;
	x.sign = .Zero_or_Positive;
	y.sign = .Zero_or_Positive;

	/*
		Normalize both x and y, ensure that y >= b/2, [b == 2**MP_DIGIT_BIT]
	*/
	norm, _ := count_bits(y);
	norm %= _DIGIT_BITS;

	if norm < _DIGIT_BITS - 1 {
		norm = (_DIGIT_BITS - 1) - norm;
		if err = shl(x, x, norm); err != nil { return err; }
		if err = shl(y, y, norm); err != nil { return err; }
	} else {
		norm = 0;
	}

	/*
		Note: HAC does 0 based, so if used==5 then it's 0,1,2,3,4, i.e. use 4
	*/
	n := x.used - 1;
	t := y.used - 1;

	/*
		while (x >= y*b**n-t) do { q[n-t] += 1; x -= y*b**{n-t} }
		y = y*b**{n-t}
	*/

	if err = shl_digit(y, n - t); err != nil { return err; }

	c, _ := cmp(x, y);
	for c != -1 {
		q.digit[n - t] += 1;
		if err = sub(x, x, y); err != nil { return err; }
		c, _ = cmp(x, y);
	}

	/*
		Reset y by shifting it back down.
	*/
	shr_digit(y, n - t);

	/*
		Step 3. for i from n down to (t + 1).
	*/
	#no_bounds_check for i := n; i >= (t + 1); i -= 1 {
		if (i > x.used) { continue; }

		/*
			step 3.1 if xi == yt then set q{i-t-1} to b-1, otherwise set q{i-t-1} to (xi*b + x{i-1})/yt
		*/
		if x.digit[i] == y.digit[t] {
			q.digit[(i - t) - 1] = 1 << (_DIGIT_BITS - 1);
		} else {

			tmp := _WORD(x.digit[i]) << _DIGIT_BITS;
			tmp |= _WORD(x.digit[i - 1]);
			tmp /= _WORD(y.digit[t]);
			if tmp > _WORD(_MASK) {
				tmp = _WORD(_MASK);
			}
			q.digit[(i - t) - 1] = DIGIT(tmp & _WORD(_MASK));
		}

		/* while (q{i-t-1} * (yt * b + y{t-1})) >
					xi * b**2 + xi-1 * b + xi-2

			do q{i-t-1} -= 1;
		*/

		iter := 0;

		q.digit[(i - t) - 1] = (q.digit[(i - t) - 1] + 1) & _MASK;
		#no_bounds_check for {
			q.digit[(i - t) - 1] = (q.digit[(i - t) - 1] - 1) & _MASK;

			/*
				Find left hand.
			*/
			zero(t1);
			t1.digit[0] = ((t - 1) < 0) ? 0 : y.digit[t - 1];
			t1.digit[1] = y.digit[t];
			t1.used = 2;
			if err = mul(t1, t1, q.digit[(i - t) - 1]); err != nil { return err; }

			/*
				Find right hand.
			*/
			t2.digit[0] = ((i - 2) < 0) ? 0 : x.digit[i - 2];
			t2.digit[1] = x.digit[i - 1]; /* i >= 1 always holds */
			t2.digit[2] = x.digit[i];
			t2.used = 3;

			if t1_t2, _ := cmp_mag(t1, t2); t1_t2 != 1 {
				break;
			}
			iter += 1; if iter > 100 { return .Max_Iterations_Reached; }
		}

		/*
			Step 3.3 x = x - q{i-t-1} * y * b**{i-t-1}
		*/
		if err = int_mul_digit(t1, y, q.digit[(i - t) - 1]); err != nil { return err; }
		if err = shl_digit(t1, (i - t) - 1);       err != nil { return err; }
		if err = sub(x, x, t1); err != nil { return err; }

		/*
			if x < 0 then { x = x + y*b**{i-t-1}; q{i-t-1} -= 1; }
		*/
		if x.sign == .Negative {
			if err = copy(t1, y); err != nil { return err; }
			if err = shl_digit(t1, (i - t) - 1); err != nil { return err; }
			if err = add(x, x, t1); err != nil { return err; }

			q.digit[(i - t) - 1] = (q.digit[(i - t) - 1] - 1) & _MASK;
		}
	}

	/*
		Now q is the quotient and x is the remainder, [which we have to normalize]
		Get sign before writing to c.
	*/
	z, _ := is_zero(x);
	x.sign = .Zero_or_Positive if z else numerator.sign;

	if quotient != nil {
		clamp(q);
		swap(q, quotient);
		quotient.sign = .Negative if neg else .Zero_or_Positive;
	}

	if remainder != nil {
		if err = shr(x, x, norm); err != nil { return err; }
		swap(x, remainder);
	}

	return nil;
}

/*
	Slower bit-bang division... also smaller.
*/
@(deprecated="Use `_int_div_school`, it's 3.5x faster.")
_private_int_div_small :: proc(quotient, remainder, numerator, denominator: ^Int) -> (err: Error) {

	ta, tb, tq, q := &Int{}, &Int{}, &Int{}, &Int{};
	c: int;

	goto_end: for {
		if err = one(tq);									err != nil { break goto_end; }

		num_bits, _ := count_bits(numerator);
		den_bits, _ := count_bits(denominator);
		n := num_bits - den_bits;

		if err = abs(ta, numerator);						err != nil { break goto_end; }
		if err = abs(tb, denominator);						err != nil { break goto_end; }
		if err = shl(tb, tb, n);							err != nil { break goto_end; }
		if err = shl(tq, tq, n);							err != nil { break goto_end; }

		for n >= 0 {
			if c, _ = cmp_mag(ta, tb); c == 0 || c == 1 {
				// ta -= tb
				if err = sub(ta, ta, tb);					err != nil { break goto_end; }
				//  q += tq
				if err = add( q, q,  tq);					err != nil { break goto_end; }
			}
			if err = shr1(tb, tb);							err != nil { break goto_end; }
			if err = shr1(tq, tq);							err != nil { break goto_end; }

			n -= 1;
		}

		/*
			Now q == quotient and ta == remainder.
		*/
		neg := numerator.sign != denominator.sign;
		if quotient != nil {
			swap(quotient, q);
			z, _ := is_zero(quotient);
			quotient.sign = .Negative if neg && !z else .Zero_or_Positive;
		}
		if remainder != nil {
			swap(remainder, ta);
			z, _ := is_zero(numerator);
			remainder.sign = .Zero_or_Positive if z else numerator.sign;
		}

		break goto_end;
	}
	destroy(ta, tb, tq, q);
	return err;
}



/*
	Binary split factorial algo due to: http://www.luschny.de/math/factorial/binarysplitfact.html
*/
_private_int_factorial_binary_split :: proc(res: ^Int, n: int) -> (err: Error) {

	inner, outer, start, stop, temp := &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(inner, outer, start, stop, temp);

	if err = set(inner, 1); err != nil { return err; }
	if err = set(outer, 1); err != nil { return err; }

	bits_used := int(_DIGIT_TYPE_BITS - intrinsics.count_leading_zeros(n));

	for i := bits_used; i >= 0; i -= 1 {
		start := (n >> (uint(i) + 1)) + 1 | 1;
		stop  := (n >> uint(i)) + 1 | 1;
		if err = _private_int_recursive_product(temp, start, stop); err != nil { return err; }
		if err = internal_mul(inner, inner, temp);                   err != nil { return err; }
		if err = internal_mul(outer, outer, inner);                  err != nil { return err; }
	}
	shift := n - intrinsics.count_ones(n);

	return shl(res, outer, int(shift));
}

/*
	Recursive product used by binary split factorial algorithm.
*/
_private_int_recursive_product :: proc(res: ^Int, start, stop: int, level := int(0)) -> (err: Error) {
	t1, t2 := &Int{}, &Int{};
	defer destroy(t1, t2);

	if level > FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS { return .Max_Iterations_Reached; }

	num_factors := (stop - start) >> 1;
	if num_factors == 2 {
		if err = set(t1, start); err != nil { return err; }
		when true {
			if err = grow(t2, t1.used + 1); err != nil { return err; }
			if err = internal_add(t2, t1, 2); err != nil { return err; }
		} else {
			if err = add(t2, t1, 2); err != nil { return err; }
		}
		return internal_mul(res, t1, t2);
	}

	if num_factors > 1 {
		mid := (start + num_factors) | 1;
		if err = _private_int_recursive_product(t1, start,  mid, level + 1); err != nil { return err; }
		if err = _private_int_recursive_product(t2,   mid, stop, level + 1); err != nil { return err; }
		return internal_mul(res, t1, t2);
	}

	if num_factors == 1 { return #force_inline set(res, start); }

	return #force_inline set(res, 1);
}

/*
	Internal function computing both GCD using the binary method,
		and, if target isn't `nil`, also LCM.

	Expects the `a` and `b` to have been initialized
		and one or both of `res_gcd` or `res_lcm` not to be `nil`.

	If both `a` and `b` are zero, return zero.
	If either `a` or `b`, return the other one.

	The `gcd` and `lcm` wrappers have already done this test,
	but `gcd_lcm` wouldn't have, so we still need to perform it.

	If neither result is wanted, we have nothing to do.
*/
_private_int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int) -> (err: Error) {
	if res_gcd == nil && res_lcm == nil { return nil; }

	/*
		We need a temporary because `res_gcd` is allowed to be `nil`.
	*/
	if a.used == 0 && b.used == 0 {
		/*
			GCD(0, 0) and LCM(0, 0) are both 0.
		*/
		if res_gcd != nil {
			if err = zero(res_gcd);	err != nil { return err; }
		}
		if res_lcm != nil {
			if err = zero(res_lcm);	err != nil { return err; }
		}
		return nil;
	} else if a.used == 0 {
		/*
			We can early out with GCD = B and LCM = 0
		*/
		if res_gcd != nil {
			if err = abs(res_gcd, b); err != nil { return err; }
		}
		if res_lcm != nil {
			if err = zero(res_lcm); err != nil { return err; }
		}
		return nil;
	} else if b.used == 0 {
		/*
			We can early out with GCD = A and LCM = 0
		*/
		if res_gcd != nil {
			if err = abs(res_gcd, a); err != nil { return err; }
		}
		if res_lcm != nil {
			if err = zero(res_lcm); err != nil { return err; }
		}
		return nil;
	}

	temp_gcd_res := &Int{};
	defer destroy(temp_gcd_res);

	/*
		If neither `a` or `b` was zero, we need to compute `gcd`.
 		Get copies of `a` and `b` we can modify.
 	*/
	u, v := &Int{}, &Int{};
	defer destroy(u, v);
	if err = copy(u, a); err != nil { return err; }
	if err = copy(v, b); err != nil { return err; }

 	/*
 		Must be positive for the remainder of the algorithm.
 	*/
	u.sign = .Zero_or_Positive; v.sign = .Zero_or_Positive;

 	/*
 		B1.  Find the common power of two for `u` and `v`.
 	*/
 	u_lsb, _ := count_lsb(u);
 	v_lsb, _ := count_lsb(v);
 	k        := min(u_lsb, v_lsb);

	if k > 0 {
		/*
			Divide the power of two out.
		*/
		if err = shr(u, u, k); err != nil { return err; }
		if err = shr(v, v, k); err != nil { return err; }
	}

	/*
		Divide any remaining factors of two out.
	*/
	if u_lsb != k {
		if err = shr(u, u, u_lsb - k); err != nil { return err; }
	}
	if v_lsb != k {
		if err = shr(v, v, v_lsb - k); err != nil { return err; }
	}

	for v.used != 0 {
		/*
			Make sure `v` is the largest.
		*/
		if c, _ := cmp_mag(u, v); c == 1 {
			/*
				Swap `u` and `v` to make sure `v` is >= `u`.
			*/
			swap(u, v);
		}

		/*
			Subtract smallest from largest.
		*/
		if err = internal_sub(v, v, u); err != nil { return err; }

		/*
			Divide out all factors of two.
		*/
		b, _ := count_lsb(v);
		if err = shr(v, v, b); err != nil { return err; }
	}

 	/*
 		Multiply by 2**k which we divided out at the beginning.
 	*/
 	if err = shl(temp_gcd_res, u, k); err != nil { return err; }
 	temp_gcd_res.sign = .Zero_or_Positive;

	/*
		We've computed `gcd`, either the long way, or because one of the inputs was zero.
		If we don't want `lcm`, we're done.
	*/
	if res_lcm == nil {
		swap(temp_gcd_res, res_gcd);
		return nil;
	}

	/*
		Computes least common multiple as `|a*b|/gcd(a,b)`
		Divide the smallest by the GCD.
	*/
	if c, _ := cmp_mag(a, b); c == -1 {
		/*
			Store quotient in `t2` such that `t2 * b` is the LCM.
		*/
		if err = internal_div(res_lcm, a, temp_gcd_res); err != nil { return err; }
		err = internal_mul(res_lcm, res_lcm, b);
	} else {
		/*
			Store quotient in `t2` such that `t2 * a` is the LCM.
		*/
		if err = internal_div(res_lcm, a, temp_gcd_res); err != nil { return err; }
		err = internal_mul(res_lcm, res_lcm, b);
	}

	if res_gcd != nil {
		swap(temp_gcd_res, res_gcd);
	}

	/*
		Fix the sign to positive and return.
	*/
	res_lcm.sign = .Zero_or_Positive;
	return err;
}

/*	
	========================    End of private procedures    =======================

	===============================  Private tables  ===============================

	Tables used by `internal_*` and `_*`.
*/

_private_prime_table := []DIGIT{
	0x0002, 0x0003, 0x0005, 0x0007, 0x000B, 0x000D, 0x0011, 0x0013,
	0x0017, 0x001D, 0x001F, 0x0025, 0x0029, 0x002B, 0x002F, 0x0035,
	0x003B, 0x003D, 0x0043, 0x0047, 0x0049, 0x004F, 0x0053, 0x0059,
	0x0061, 0x0065, 0x0067, 0x006B, 0x006D, 0x0071, 0x007F, 0x0083,
	0x0089, 0x008B, 0x0095, 0x0097, 0x009D, 0x00A3, 0x00A7, 0x00AD,
	0x00B3, 0x00B5, 0x00BF, 0x00C1, 0x00C5, 0x00C7, 0x00D3, 0x00DF,
	0x00E3, 0x00E5, 0x00E9, 0x00EF, 0x00F1, 0x00FB, 0x0101, 0x0107,
	0x010D, 0x010F, 0x0115, 0x0119, 0x011B, 0x0125, 0x0133, 0x0137,

	0x0139, 0x013D, 0x014B, 0x0151, 0x015B, 0x015D, 0x0161, 0x0167,
	0x016F, 0x0175, 0x017B, 0x017F, 0x0185, 0x018D, 0x0191, 0x0199,
	0x01A3, 0x01A5, 0x01AF, 0x01B1, 0x01B7, 0x01BB, 0x01C1, 0x01C9,
	0x01CD, 0x01CF, 0x01D3, 0x01DF, 0x01E7, 0x01EB, 0x01F3, 0x01F7,
	0x01FD, 0x0209, 0x020B, 0x021D, 0x0223, 0x022D, 0x0233, 0x0239,
	0x023B, 0x0241, 0x024B, 0x0251, 0x0257, 0x0259, 0x025F, 0x0265,
	0x0269, 0x026B, 0x0277, 0x0281, 0x0283, 0x0287, 0x028D, 0x0293,
	0x0295, 0x02A1, 0x02A5, 0x02AB, 0x02B3, 0x02BD, 0x02C5, 0x02CF,

	0x02D7, 0x02DD, 0x02E3, 0x02E7, 0x02EF, 0x02F5, 0x02F9, 0x0301,
	0x0305, 0x0313, 0x031D, 0x0329, 0x032B, 0x0335, 0x0337, 0x033B,
	0x033D, 0x0347, 0x0355, 0x0359, 0x035B, 0x035F, 0x036D, 0x0371,
	0x0373, 0x0377, 0x038B, 0x038F, 0x0397, 0x03A1, 0x03A9, 0x03AD,
	0x03B3, 0x03B9, 0x03C7, 0x03CB, 0x03D1, 0x03D7, 0x03DF, 0x03E5,
	0x03F1, 0x03F5, 0x03FB, 0x03FD, 0x0407, 0x0409, 0x040F, 0x0419,
	0x041B, 0x0425, 0x0427, 0x042D, 0x043F, 0x0443, 0x0445, 0x0449,
	0x044F, 0x0455, 0x045D, 0x0463, 0x0469, 0x047F, 0x0481, 0x048B,

	0x0493, 0x049D, 0x04A3, 0x04A9, 0x04B1, 0x04BD, 0x04C1, 0x04C7,
	0x04CD, 0x04CF, 0x04D5, 0x04E1, 0x04EB, 0x04FD, 0x04FF, 0x0503,
	0x0509, 0x050B, 0x0511, 0x0515, 0x0517, 0x051B, 0x0527, 0x0529,
	0x052F, 0x0551, 0x0557, 0x055D, 0x0565, 0x0577, 0x0581, 0x058F,
	0x0593, 0x0595, 0x0599, 0x059F, 0x05A7, 0x05AB, 0x05AD, 0x05B3,
	0x05BF, 0x05C9, 0x05CB, 0x05CF, 0x05D1, 0x05D5, 0x05DB, 0x05E7,
	0x05F3, 0x05FB, 0x0607, 0x060D, 0x0611, 0x0617, 0x061F, 0x0623,
	0x062B, 0x062F, 0x063D, 0x0641, 0x0647, 0x0649, 0x064D, 0x0653,
};

when MATH_BIG_FORCE_64_BIT || (!MATH_BIG_FORCE_32_BIT && size_of(rawptr) == 8) {
	_factorial_table := [35]_WORD{
/* f(00): */                                                     1,
/* f(01): */                                                     1,
/* f(02): */                                                     2,
/* f(03): */                                                     6,
/* f(04): */                                                    24,
/* f(05): */                                                   120,
/* f(06): */                                                   720,
/* f(07): */                                                 5_040,
/* f(08): */                                                40_320,
/* f(09): */                                               362_880,
/* f(10): */                                             3_628_800,
/* f(11): */                                            39_916_800,
/* f(12): */                                           479_001_600,
/* f(13): */                                         6_227_020_800,
/* f(14): */                                        87_178_291_200,
/* f(15): */                                     1_307_674_368_000,
/* f(16): */                                    20_922_789_888_000,
/* f(17): */                                   355_687_428_096_000,
/* f(18): */                                 6_402_373_705_728_000,
/* f(19): */                               121_645_100_408_832_000,
/* f(20): */                             2_432_902_008_176_640_000,
/* f(21): */                            51_090_942_171_709_440_000,
/* f(22): */                         1_124_000_727_777_607_680_000,
/* f(23): */                        25_852_016_738_884_976_640_000,
/* f(24): */                       620_448_401_733_239_439_360_000,
/* f(25): */                    15_511_210_043_330_985_984_000_000,
/* f(26): */                   403_291_461_126_605_635_584_000_000,
/* f(27): */                10_888_869_450_418_352_160_768_000_000,
/* f(28): */               304_888_344_611_713_860_501_504_000_000,
/* f(29): */             8_841_761_993_739_701_954_543_616_000_000,
/* f(30): */           265_252_859_812_191_058_636_308_480_000_000,
/* f(31): */         8_222_838_654_177_922_817_725_562_880_000_000,
/* f(32): */       263_130_836_933_693_530_167_218_012_160_000_000,
/* f(33): */     8_683_317_618_811_886_495_518_194_401_280_000_000,
/* f(34): */   295_232_799_039_604_140_847_618_609_643_520_000_000,
	};
} else {
	_factorial_table := [21]_WORD{
/* f(00): */                                                     1,
/* f(01): */                                                     1,
/* f(02): */                                                     2,
/* f(03): */                                                     6,
/* f(04): */                                                    24,
/* f(05): */                                                   120,
/* f(06): */                                                   720,
/* f(07): */                                                 5_040,
/* f(08): */                                                40_320,
/* f(09): */                                               362_880,
/* f(10): */                                             3_628_800,
/* f(11): */                                            39_916_800,
/* f(12): */                                           479_001_600,
/* f(13): */                                         6_227_020_800,
/* f(14): */                                        87_178_291_200,
/* f(15): */                                     1_307_674_368_000,
/* f(16): */                                    20_922_789_888_000,
/* f(17): */                                   355_687_428_096_000,
/* f(18): */                                 6_402_373_705_728_000,
/* f(19): */                               121_645_100_408_832_000,
/* f(20): */                             2_432_902_008_176_640_000,
	};
};

/*
	=========================  End of private tables  ========================
*/