/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

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

	We pass the custom allocator to procedures by default using the pattern `context.allocator = allocator`.
	This way we don't have to add `, allocator` at the end of each call.

	TODO: Handle +/- Infinity and NaN.
*/

package math_big

import "core:mem"
import "base:intrinsics"
import rnd "core:math/rand"
import "base:builtin"

/*
	Low-level addition, unsigned. Handbook of Applied Cryptography, algorithm 14.7.

	Assumptions:
		`dest`, `a` and `b` != `nil` and have been initalized.
*/
internal_int_add_unsigned :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	dest := dest; x := a; y := b
	context.allocator = allocator

	old_used, min_used, max_used, i: int

	if x.used < y.used {
		x, y = y, x
	}

	min_used = y.used
	max_used = x.used
	old_used = dest.used

	internal_grow(dest, max(max_used + 1, _DEFAULT_DIGIT_COUNT)) or_return
	dest.used = max_used + 1
	/*
		All parameters have been initialized.
	*/

	/* Zero the carry */
	carry := DIGIT(0)

	#no_bounds_check for i = 0; i < min_used; i += 1 {
		/*
			Compute the sum one _DIGIT at a time.
			dest[i] = a[i] + b[i] + carry;
		*/
		dest.digit[i] = x.digit[i] + y.digit[i] + carry

		/*
			Compute carry
		*/
		carry = dest.digit[i] >> _DIGIT_BITS
		/*
			Mask away carry from result digit.
		*/
		dest.digit[i] &= _MASK
	}

	if min_used != max_used {
		/*
			Now copy higher words, if any, in A+B.
			If A or B has more digits, add those in.
		*/
		#no_bounds_check for ; i < max_used; i += 1 {
			dest.digit[i] = x.digit[i] + carry
			/*
				Compute carry
			*/
			carry = dest.digit[i] >> _DIGIT_BITS
			/*
				Mask away carry from result digit.
			*/
			dest.digit[i] &= _MASK
		}
	}
	/*
		Add remaining carry.
	*/
	dest.digit[i] = carry

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used)
	/*
		Adjust dest.used based on leading zeroes.
	*/
	return internal_clamp(dest)
}
internal_add_unsigned :: proc { internal_int_add_unsigned, }

/*
	Low-level addition, signed. Handbook of Applied Cryptography, algorithm 14.7.

	Assumptions:
		`dest`, `a` and `b` != `nil` and have been initalized.
*/
internal_int_add_signed :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	x := a; y := b
	context.allocator = allocator
	/*
		Handle both negative or both positive.
	*/
	if x.sign == y.sign {
		dest.sign = x.sign
		return #force_inline internal_int_add_unsigned(dest, x, y)
	}

	/*
		One positive, the other negative.
		Subtract the one with the greater magnitude from the other.
		The result gets the sign of the one with the greater magnitude.
	*/
	if #force_inline internal_lt_abs(a, b) {
		x, y = y, x
	}

	dest.sign = x.sign
	return #force_inline internal_int_sub_unsigned(dest, x, y)
}
internal_add_signed :: proc { internal_int_add_signed, }

/*
	Low-level addition Int+DIGIT, signed. Handbook of Applied Cryptography, algorithm 14.7.

	Assumptions:
		`dest` and `a` != `nil` and have been initalized.
		`dest` is large enough (a.used + 1) to fit result.
*/
internal_int_add_digit :: proc(dest, a: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	internal_grow(dest, a.used + 1) or_return
	/*
		Fast paths for destination and input Int being the same.
	*/
	if dest == a {
		/*
			Fast path for dest.digit[0] + digit fits in dest.digit[0] without overflow.
		*/
		if dest.sign == .Zero_or_Positive && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit
			dest.used += 1
			return internal_clamp(dest)
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if a.sign == .Negative && (dest.digit[0] > digit) {
			dest.digit[0] -= digit
			dest.used += 1
			return internal_clamp(dest)
		}
	}

	/*
		If `a` is negative and `|a|` >= `digit`, call `dest = |a| - digit`
	*/
	if a.sign == .Negative && (a.used > 1 || a.digit[0] >= digit) {
		/*
			Temporarily fix `a`'s sign.
		*/
		a.sign = .Zero_or_Positive
		/*
			dest = |a| - digit
		*/
		if err = #force_inline internal_int_add_digit(dest, a, digit); err != nil {
			/*
				Restore a's sign.
			*/
			a.sign = .Negative
			return err
		}
		/*
			Restore sign and set `dest` sign.
		*/
		a.sign    = .Negative
		dest.sign = .Negative

		return internal_clamp(dest)
	}

	/*
		Remember the currently used number of digits in `dest`.
	*/
	old_used := dest.used

	/*
		If `a` is positive
	*/
	if a.sign == .Zero_or_Positive {
		/*
			Add digits, use `carry`.
		*/
		i: int
		carry := digit
		#no_bounds_check for i = 0; i < a.used; i += 1 {
			dest.digit[i] = a.digit[i] + carry
			carry = dest.digit[i] >> _DIGIT_BITS
			dest.digit[i] &= _MASK
		}
		/*
			Set final carry.
		*/
		dest.digit[i] = carry
		/*
			Set `dest` size.
		*/
		dest.used = a.used + 1
	} else {
		/*
			`a` was negative and |a| < digit.
		*/
		dest.used = 1
		/*
			The result is a single DIGIT.
		*/
		dest.digit[0] = digit - a.digit[0] if a.used == 1 else digit
	}
	/*
		Sign is always positive.
	*/
	dest.sign = .Zero_or_Positive

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used)

	/*
		Adjust dest.used based on leading zeroes.
	*/
	return internal_clamp(dest)	
}
internal_add :: proc { internal_int_add_signed, internal_int_add_digit, }


internal_int_incr :: proc(dest: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline internal_add(dest, dest, 1)
}
internal_incr :: proc { internal_int_incr, }

/*
	Low-level subtraction, dest = number - decrease. Assumes |number| > |decrease|.
	Handbook of Applied Cryptography, algorithm 14.9.

	Assumptions:
		`dest`, `number` and `decrease` != `nil` and have been initalized.
*/
internal_int_sub_unsigned :: proc(dest, number, decrease: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	dest := dest; x := number; y := decrease
	old_used := dest.used
	min_used := y.used
	max_used := x.used
	i: int

	grow(dest, max(max_used, _DEFAULT_DIGIT_COUNT)) or_return
	dest.used = max_used
	/*
		All parameters have been initialized.
	*/

	borrow := DIGIT(0)

	#no_bounds_check for i = 0; i < min_used; i += 1 {
		dest.digit[i] = (x.digit[i] - y.digit[i] - borrow)
		/*
			borrow = carry bit of dest[i]
			Note this saves performing an AND operation since if a carry does occur,
			it will propagate all the way to the MSB.
			As a result a single shift is enough to get the carry.
		*/
		borrow = dest.digit[i] >> ((size_of(DIGIT) * 8) - 1)
		/*
			Clear borrow from dest[i].
		*/
		dest.digit[i] &= _MASK
	}

	/*
		Now copy higher words if any, e.g. if A has more digits than B
	*/
	#no_bounds_check for ; i < max_used; i += 1 {
		dest.digit[i] = x.digit[i] - borrow
		/*
			borrow = carry bit of dest[i]
			Note this saves performing an AND operation since if a carry does occur,
			it will propagate all the way to the MSB.
			As a result a single shift is enough to get the carry.
		*/
		borrow = dest.digit[i] >> ((size_of(DIGIT) * 8) - 1)
		/*
			Clear borrow from dest[i].
		*/
		dest.digit[i] &= _MASK
	}

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used)

	/*
		Adjust dest.used based on leading zeroes.
	*/
	return internal_clamp(dest)
}
internal_sub_unsigned :: proc { internal_int_sub_unsigned, }

/*
	Low-level subtraction, signed. Handbook of Applied Cryptography, algorithm 14.9.
	dest = number - decrease. Assumes |number| > |decrease|.

	Assumptions:
		`dest`, `number` and `decrease` != `nil` and have been initalized.
*/
internal_int_sub_signed :: proc(dest, number, decrease: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	number := number; decrease := decrease
	if number.sign != decrease.sign {
		/*
			Subtract a negative from a positive, OR subtract a positive from a negative.
			In either case, ADD their magnitudes and use the sign of the first number.
		*/
		dest.sign = number.sign
		return #force_inline internal_int_add_unsigned(dest, number, decrease)
	}

	/*
		Subtract a positive from a positive, OR negative from a negative.
		First, take the difference between their magnitudes, then...
	*/
	if #force_inline internal_lt_abs(number, decrease) {
		/*
			The second has a larger magnitude.
			The result has the *opposite* sign from the first number.
		*/
		dest.sign = .Negative if number.sign == .Zero_or_Positive else .Zero_or_Positive
		number, decrease = decrease, number
	} else {
		/*
			The first has a larger or equal magnitude.
			Copy the sign from the first.
		*/
		dest.sign = number.sign
	}
	return #force_inline internal_int_sub_unsigned(dest, number, decrease)
}

/*
	Low-level subtraction, signed. Handbook of Applied Cryptography, algorithm 14.9.
	dest = number - decrease. Assumes |number| > |decrease|.

	Assumptions:
		`dest`, `number` != `nil` and have been initalized.
		`dest` is large enough (number.used + 1) to fit result.
*/
internal_int_sub_digit :: proc(dest, number: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	internal_grow(dest, number.used + 1) or_return

	dest := dest; digit := digit
	/*
		All parameters have been initialized.

		Fast paths for destination and input Int being the same.
	*/
	if dest == number {
		/*
			Fast path for `dest` is negative and unsigned addition doesn't overflow the lowest digit.
		*/
		if dest.sign == .Negative && (dest.digit[0] + digit < _DIGIT_MAX) {
			dest.digit[0] += digit
			return nil
		}
		/*
			Can be subtracted from dest.digit[0] without underflow.
		*/
		if number.sign == .Zero_or_Positive && (dest.digit[0] > digit) {
			dest.digit[0] -= digit
			return nil
		}
	}

	/*
		If `a` is negative, just do an unsigned addition (with fudged signs).
	*/
	if number.sign == .Negative {
		t := number
		t.sign = .Zero_or_Positive

		err =  #force_inline internal_int_add_digit(dest, t, digit)
		dest.sign = .Negative

		internal_clamp(dest)
		return err
	}

	old_used := dest.used

	/*
		if `a`<= digit, simply fix the single digit.
	*/
	if number.used == 1 && (number.digit[0] <= digit) || number.used == 0 {
		dest.digit[0] = digit - number.digit[0] if number.used == 1 else digit
		dest.sign = .Negative
		dest.used = 1
	} else {
		dest.sign = .Zero_or_Positive
		dest.used = number.used

		/*
			Subtract with carry.
		*/
		carry := digit

		#no_bounds_check for i := 0; i < number.used; i += 1 {
			dest.digit[i] = number.digit[i] - carry
			carry = dest.digit[i] >> (_DIGIT_TYPE_BITS - 1)
			dest.digit[i] &= _MASK
		}
	}

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used)

	/*
		Adjust dest.used based on leading zeroes.
	*/
	return internal_clamp(dest)
}

internal_sub :: proc { internal_int_sub_signed, internal_int_sub_digit, }

internal_int_decr :: proc(dest: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline internal_sub(dest, dest, 1)
}
internal_decr :: proc { internal_int_decr, }

/*
	dest = src  / 2
	dest = src >> 1

	Assumes `dest` and `src` not to be `nil` and have been initialized.
	We make no allocations here.
*/
internal_int_shr1 :: proc(dest, src: ^Int) -> (err: Error) {
	old_used  := dest.used; dest.used = src.used
	/*
		Carry
	*/
	fwd_carry := DIGIT(0)

	#no_bounds_check for x := dest.used - 1; x >= 0; x -= 1 {
		/*
			Get the carry for the next iteration.
		*/
		src_digit := src.digit[x]
		carry     := src_digit & 1
		/*
			Shift the current digit, add in carry and store.
		*/
		dest.digit[x] = (src_digit >> 1) | (fwd_carry << (_DIGIT_BITS - 1))
		/*
			Forward carry to next iteration.
		*/
		fwd_carry = carry
	}

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used)

	/*
		Adjust dest.used based on leading zeroes.
	*/
	dest.sign = src.sign
	return internal_clamp(dest)	
}

/*
	dest = src  * 2
	dest = src << 1
*/
internal_int_shl1 :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	internal_copy(dest, src) or_return
	/*
		Grow `dest` to accommodate the additional bits.
	*/
	digits_needed := dest.used + 1
	internal_grow(dest, digits_needed) or_return
	dest.used = digits_needed

	mask  := (DIGIT(1) << uint(1)) - DIGIT(1)
	shift := DIGIT(_DIGIT_BITS - 1)
	carry := DIGIT(0)

	#no_bounds_check for x:= 0; x < dest.used; x+= 1 {		
		fwd_carry := (dest.digit[x] >> shift) & mask
		dest.digit[x] = (dest.digit[x] << uint(1) | carry) & _MASK
		carry = fwd_carry
	}
	/*
		Use final carry.
	*/
	if carry != 0 {
		dest.digit[dest.used] = carry
		dest.used += 1
	}
	return internal_clamp(dest)
}

/*
	Multiply bigint `a` with int `d` and put the result in `dest`.
 	Like `internal_int_mul_digit` but with an integer as the small input.
*/
internal_int_mul_integer :: proc(dest, a: ^Int, b: $T, allocator := context.allocator) -> (err: Error)
where intrinsics.type_is_integer(T), T != DIGIT {
	context.allocator = allocator

	t := &Int{}
	defer internal_destroy(t)

	/*
		DIGIT might be smaller than a long, which excludes the use of `internal_int_mul_digit` here.
	*/
	internal_set(t, b) or_return
	internal_mul(dest, a, t) or_return
	return
}

/*
	Multiply by a DIGIT.
*/
internal_int_mul_digit :: proc(dest, src: ^Int, multiplier: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	assert_if_nil(dest, src)

	if multiplier == 0 {
		return internal_zero(dest)
	}
	if multiplier == 1 {
		return internal_copy(dest, src)
	}

	/*
		Power of two?
	*/
	if multiplier == 2 {
		return #force_inline internal_int_shl1(dest, src)
	}
	if #force_inline platform_int_is_power_of_two(int(multiplier)) {
		ix := internal_log(multiplier, 2) or_return
		return internal_shl(dest, src, ix)
	}

	/*
		Ensure `dest` is big enough to hold `src` * `multiplier`.
	*/
	grow(dest, max(src.used + 1, _DEFAULT_DIGIT_COUNT)) or_return

	/*
		Save the original used count.
	*/
	old_used := dest.used
	/*
		Set the sign.
	*/
	dest.sign = src.sign
	/*
		Set up carry.
	*/
	carry := _WORD(0)
	/*
		Compute columns.
	*/
	ix := 0
	#no_bounds_check for ; ix < src.used; ix += 1 {
		/*
			Compute product and carry sum for this term
		*/
		product := carry + _WORD(src.digit[ix]) * _WORD(multiplier)
		/*
			Mask off higher bits to get a single DIGIT.
		*/
		dest.digit[ix] = DIGIT(product & _WORD(_MASK))
		/*
			Send carry into next iteration
		*/
		carry = product >> _DIGIT_BITS
	}

	/*
		Store final carry [if any] and increment used.
	*/
	dest.digit[ix] = DIGIT(carry)
	dest.used = src.used + 1

	/*
		Zero remainder.
	*/
	internal_zero_unused(dest, old_used)

	return internal_clamp(dest)
}

/*
	High level multiplication (handles sign).
*/
internal_int_mul :: proc(dest, src, multiplier: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	/*
		Early out for `multiplier` is zero; Set `dest` to zero.
	*/
	if multiplier.used == 0 || src.used == 0 { return internal_zero(dest) }

	neg := src.sign != multiplier.sign

	if src == multiplier {
		/*
			Do we need to square?
		*/
		if src.used >= SQR_TOOM_CUTOFF {
			/*
				Use Toom-Cook?
			*/
			err = #force_inline _private_int_sqr_toom(dest, src)
		} else if src.used >= SQR_KARATSUBA_CUTOFF {
			/*
				Karatsuba?
			*/
			err = #force_inline _private_int_sqr_karatsuba(dest, src)
		} else if ((src.used * 2) + 1) < _WARRAY && src.used < (_MAX_COMBA / 2) {
			/*
				Fast comba?
			*/
			err = #force_inline _private_int_sqr_comba(dest, src)
		} else {
			err = #force_inline _private_int_sqr(dest, src)
		}
	} else {
		/*
			Can we use the balance method? Check sizes.
			* The smaller one needs to be larger than the Karatsuba cut-off.
			* The bigger one needs to be at least about one `_MUL_KARATSUBA_CUTOFF` bigger
			* to make some sense, but it depends on architecture, OS, position of the stars... so YMMV.
			* Using it to cut the input into slices small enough for _mul_comba
			* was actually slower on the author's machine, but YMMV.
		*/

		min_used := min(src.used, multiplier.used)
		max_used := max(src.used, multiplier.used)
		digits   := src.used + multiplier.used + 1

		if min_used >= MUL_KARATSUBA_CUTOFF && (max_used / 2) >= MUL_KARATSUBA_CUTOFF && max_used >= (2 * min_used) {
			/*
				Not much effect was observed below a ratio of 1:2, but again: YMMV.
			*/
			err = _private_int_mul_balance(dest, src, multiplier)
		} else if min_used >= MUL_TOOM_CUTOFF {
			/*
				Toom path commented out until it no longer fails Factorial 10k or 100k,
				as reveaved in the long test.
			*/
			err = #force_inline _private_int_mul_toom(dest, src, multiplier)
		} else if min_used >= MUL_KARATSUBA_CUTOFF {
			err = #force_inline _private_int_mul_karatsuba(dest, src, multiplier)
		} else if digits < _WARRAY && min_used <= _MAX_COMBA {
			/*
				Can we use the fast multiplier?
				* The fast multiplier can be used if the output will
				* have less than MP_WARRAY digits and the number of
				* digits won't affect carry propagation
			*/
			err = #force_inline _private_int_mul_comba(dest, src, multiplier, digits)
		} else {
			err = #force_inline _private_int_mul(dest, src, multiplier, digits)
		}
	}

	dest.sign = .Negative if dest.used > 0 && neg else .Zero_or_Positive
	return err
}

internal_mul :: proc { internal_int_mul, internal_int_mul_digit, internal_int_mul_integer }

internal_sqr :: proc (dest, src: ^Int, allocator := context.allocator) -> (res: Error) {
	/*
		We call `internal_mul` and not e.g. `_private_int_sqr` because the former
		will dispatch to the optimal implementation depending on the source.
	*/
	return #force_inline internal_mul(dest, src, src, allocator)
}

/*
	divmod.
	Both the quotient and remainder are optional and may be passed a nil.
	`numerator` and `denominator` are expected not to be `nil` and have been initialized.
*/
internal_int_divmod :: proc(quotient, remainder, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if denominator.used == 0 { return .Division_by_Zero }
	/*
		If numerator < denominator then quotient = 0, remainder = numerator.
	*/
	if #force_inline internal_lt_abs(numerator, denominator) {
		if remainder != nil {
			internal_copy(remainder, numerator) or_return
		}
		if quotient != nil {
			internal_zero(quotient)
		}
		return nil
	}

	if (denominator.used > 2 * MUL_KARATSUBA_CUTOFF) && (denominator.used <= (numerator.used / 3) * 2) {
		assert(denominator.used >= 160 && numerator.used >= 240, "MUL_KARATSUBA_CUTOFF global not properly set.")
		err = _private_int_div_recursive(quotient, remainder, numerator, denominator)
	} else {
		when true {
			err = #force_inline _private_int_div_school(quotient, remainder, numerator, denominator)
		} else {
			/*
				NOTE(Jeroen): We no longer need or use `_private_int_div_small`.
				We'll keep it around for a bit until we're reasonably certain div_school is bug free.
			*/
			err = _private_int_div_small(quotient, remainder, numerator, denominator)
		}
	}
	return
}

/*
	Single digit division (based on routine from MPI).
	The quotient is optional and may be passed a nil.
*/
internal_int_divmod_digit :: proc(quotient, numerator: ^Int, denominator: DIGIT, allocator := context.allocator) -> (remainder: DIGIT, err: Error) {
	context.allocator = allocator

	/*
		Cannot divide by zero.
	*/
	if denominator == 0 { return 0, .Division_by_Zero }

	/*
		Quick outs.
	*/
	if denominator == 1 || numerator.used == 0 {
		if quotient != nil {
			return 0, internal_copy(quotient, numerator)
		}
		return 0, err
	}
	/*
		Power of two?
	*/
	if denominator == 2 {
		if numerator.used > 0 && numerator.digit[0] & 1 != 0 {
			// Remainder is 1 if numerator is odd.
			remainder = 1
		}
		if quotient == nil {
			return remainder, nil
		}
		return remainder, internal_shr(quotient, numerator, 1)
	}

	ix: int
	if platform_int_is_power_of_two(int(denominator)) {
		ix = 1
		for ix < _DIGIT_BITS && denominator != (1 << uint(ix)) {
			ix += 1
		}
		remainder = numerator.digit[0] & ((1 << uint(ix)) - 1)
		if quotient == nil {
			return remainder, nil
		}

		return remainder, internal_shr(quotient, numerator, int(ix))
	}

	/*
		Three?
	*/
	if denominator == 3 {
		return _private_int_div_3(quotient, numerator)
	}

	/*
		No easy answer [c'est la vie].  Just division.
	*/
	q := &Int{}

	internal_grow(q, numerator.used) or_return

	q.used = numerator.used
	q.sign = numerator.sign

	w := _WORD(0)

	for ix = numerator.used - 1; ix >= 0; ix -= 1 {
		t := DIGIT(0)
		w = (w << _WORD(_DIGIT_BITS) | _WORD(numerator.digit[ix]))
		if w >= _WORD(denominator) {
			t = DIGIT(w / _WORD(denominator))
			w -= _WORD(t) * _WORD(denominator)
		}
		q.digit[ix] = t
	}
	remainder = DIGIT(w)

	if quotient != nil {
		internal_clamp(q)
		internal_swap(q, quotient)
	}
	internal_destroy(q)
	return remainder, nil
}

internal_divmod :: proc { internal_int_divmod, internal_int_divmod_digit, }

/*
	Asssumes quotient, numerator and denominator to have been initialized and not to be nil.
*/
internal_int_div :: proc(quotient, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline internal_int_divmod(quotient, nil, numerator, denominator, allocator)
}
internal_div :: proc { internal_int_div, }

/*
	remainder = numerator % denominator.
	0 <= remainder < denominator if denominator > 0
	denominator < remainder <= 0 if denominator < 0

	Asssumes quotient, numerator and denominator to have been initialized and not to be nil.
*/
internal_int_mod :: proc(remainder, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	#force_inline internal_int_divmod(nil, remainder, numerator, denominator, allocator) or_return

	if remainder.used == 0 || denominator.sign == remainder.sign { return nil }

	return #force_inline internal_add(remainder, remainder, denominator, allocator)
}

internal_int_mod_digit :: proc(numerator: ^Int, denominator: DIGIT, allocator := context.allocator) -> (remainder: DIGIT, err: Error) {
	return internal_int_divmod_digit(nil, numerator, denominator, allocator)
}

internal_mod :: proc{ internal_int_mod, internal_int_mod_digit, }

/*
	remainder = (number + addend) % modulus.
*/
internal_int_addmod :: proc(remainder, number, addend, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	#force_inline internal_add(remainder, number, addend, allocator) or_return
	return #force_inline internal_mod(remainder, remainder, modulus, allocator)
}
internal_addmod :: proc { internal_int_addmod, }

/*
	remainder = (number - decrease) % modulus.
*/
internal_int_submod :: proc(remainder, number, decrease, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	#force_inline internal_sub(remainder, number, decrease, allocator) or_return
	return #force_inline internal_mod(remainder, remainder, modulus, allocator)
}
internal_submod :: proc { internal_int_submod, }

/*
	remainder = (number * multiplicand) % modulus.
*/
internal_int_mulmod :: proc(remainder, number, multiplicand, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	#force_inline internal_mul(remainder, number, multiplicand, allocator) or_return
	return #force_inline internal_mod(remainder, remainder, modulus, allocator)
}
internal_mulmod :: proc { internal_int_mulmod, }

/*
	remainder = (number * number) % modulus.
*/
internal_int_sqrmod :: proc(remainder, number, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	#force_inline internal_sqr(remainder, number, allocator) or_return
	return #force_inline internal_mod(remainder, remainder, modulus, allocator)
}
internal_sqrmod :: proc { internal_int_sqrmod, }



/*
	TODO: Use Sterling's Approximation to estimate log2(N!) to size the result.
	This way we'll have to reallocate less, possibly not at all.
*/
internal_int_factorial :: proc(res: ^Int, n: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if n >= FACTORIAL_BINARY_SPLIT_CUTOFF {
		return _private_int_factorial_binary_split(res, n)
	}

	i := len(_factorial_table)
	if n < i {
		return #force_inline internal_set(res, _factorial_table[n])
	}

	#force_inline internal_set(res, _factorial_table[i - 1]) or_return
	for {
		if err = #force_inline internal_mul(res, res, DIGIT(i)); err != nil || i == n {
			return err
		}
		i += 1
	}

	return nil
}

/*
	Returns GCD, LCM or both.

	Assumes `a` and `b` to have been initialized.
	`res_gcd` and `res_lcm` can be nil or ^Int depending on which results are desired.
*/
internal_int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	if res_gcd == nil && res_lcm == nil { return nil }

	return #force_inline _private_int_gcd_lcm(res_gcd, res_lcm, a, b, allocator)
}

internal_int_gcd :: proc(res_gcd, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline _private_int_gcd_lcm(res_gcd, nil, a, b, allocator)
}

internal_int_lcm :: proc(res_lcm, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline _private_int_gcd_lcm(nil, res_lcm, a, b, allocator)
}

/*
	remainder = numerator % (1 << bits)

	Assumes `remainder` and `numerator` both not to be `nil` and `bits` to be >= 0.
*/
internal_int_mod_bits :: proc(remainder, numerator: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	/*
		Everything is divisible by 1 << 0 == 1, so this returns 0.
	*/
	if bits == 0 { return internal_zero(remainder) }

	/*
		If the modulus is larger than the value, return the value.
	*/
	internal_copy(remainder, numerator) or_return
	if bits >= (numerator.used * _DIGIT_BITS) {
		return
	}

	/*
		Zero digits above the last digit of the modulus.
	*/
	zero_count := (bits / _DIGIT_BITS)
	zero_count += 0 if (bits % _DIGIT_BITS == 0) else 1

	/*
		Zero remainder. Special case, can't use `internal_zero_unused`.
	*/
	if zero_count > 0 {
		mem.zero_slice(remainder.digit[zero_count:])
	}

	/*
		Clear the digit that is not completely outside/inside the modulus.
	*/
	remainder.digit[bits / _DIGIT_BITS] &= DIGIT(1 << DIGIT(bits % _DIGIT_BITS)) - DIGIT(1)
	return internal_clamp(remainder)
}

/*
	=============================    Low-level helpers    =============================


	`internal_*` helpers don't return an `Error` like their public counterparts do,
	because they expect not to be passed `nil` or uninitialized inputs.

	This makes them more suitable for `internal_*` functions and some of the
	public ones that have already satisfied these constraints.
*/

/*
	This procedure returns the allocated capacity of an Int.
	Assumes `a` not to be `nil`.
*/
internal_int_allocated_cap :: #force_inline proc(a: ^Int) -> (cap: int) {
	raw := transmute(mem.Raw_Dynamic_Array)a.digit
	return raw.cap
}

/*
	This procedure will return `true` if the `Int` is initialized, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_initialized :: #force_inline proc(a: ^Int) -> (initialized: bool) {
	return internal_int_allocated_cap(a) >= _MIN_DIGIT_COUNT
}
internal_is_initialized :: proc { internal_int_is_initialized, }

/*
	This procedure will return `true` if the `Int` is zero, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_zero :: #force_inline proc(a: ^Int) -> (zero: bool) {
	return a.used == 0
}
internal_is_zero :: proc { 
	internal_rat_is_zero,
	internal_int_is_zero,
}

/*
	This procedure will return `true` if the `Int` is positive, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_positive :: #force_inline proc(a: ^Int) -> (positive: bool) {
	return a.sign == .Zero_or_Positive
}
internal_is_positive :: proc { internal_int_is_positive, }

/*
	This procedure will return `true` if the `Int` is negative, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_negative :: #force_inline proc(a: ^Int) -> (negative: bool) {
	return a.sign == .Negative
}
internal_is_negative :: proc { internal_int_is_negative, }

/*
	This procedure will return `true` if the `Int` is even, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_even :: #force_inline proc(a: ^Int) -> (even: bool) {
	if internal_is_zero(a) { return true }

	/*
		`a.used` > 0 here, because the above handled `is_zero`.
		We don't need to explicitly test it.
	*/
	return a.digit[0] & 1 == 0
}
internal_is_even :: proc { internal_int_is_even, }

/*
	This procedure will return `true` if the `Int` is even, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_odd :: #force_inline proc(a: ^Int) -> (odd: bool) {
	return !internal_int_is_even(a)
}
internal_is_odd :: proc { internal_int_is_odd, }


/*
	This procedure will return `true` if the `Int` is a power of two, `false` if not.
	Assumes `a` not to be `nil`.
*/
internal_int_is_power_of_two :: #force_inline proc(a: ^Int) -> (power_of_two: bool) {
	/*
		Early out for Int == 0.
	*/
	if #force_inline internal_is_zero(a) { return true }

	/*
		For an `Int` to be a power of two, its bottom limb has to be a power of two.
	*/
	if ! #force_inline platform_int_is_power_of_two(int(a.digit[a.used - 1])) { return false }

	/*
		We've established that the bottom limb is a power of two.
		If it's the only limb, that makes the entire Int a power of two.
	*/
	if a.used == 1 { return true }

	/*
		For an `Int` to be a power of two, all limbs except the top one have to be zero.
	*/
	for i := 1; i < a.used && a.digit[i - 1] != 0; i += 1 { return false }

	return true
}
internal_is_power_of_two :: proc { internal_int_is_power_of_two, }

/*
	Compare two `Int`s, signed.
	Returns -1 if `a` < `b`, 0 if `a` == `b` and 1 if `b` > `a`.

	Expects `a` and `b` both to be valid `Int`s, i.e. initialized and not `nil`.
*/
internal_int_compare :: #force_inline proc(a, b: ^Int) -> (comparison: int) {
	assert_if_nil(a, b)
	a_is_negative := #force_inline internal_is_negative(a)

	/*
		Compare based on sign.
	*/
	if a.sign != b.sign { return -1 if a_is_negative else +1 }

	/*
		If `a` is negative, compare in the opposite direction */
	if a_is_negative { return #force_inline internal_compare_magnitude(b, a) }

	return #force_inline internal_compare_magnitude(a, b)
}
internal_compare :: proc { internal_int_compare, internal_int_compare_digit, }
internal_cmp :: internal_compare

/*
	Compare an `Int` to an unsigned number upto `DIGIT & _MASK`.
	Returns -1 if `a` < `b`, 0 if `a` == `b` and 1 if `b` > `a`.

	Expects: `a` and `b` both to be valid `Int`s, i.e. initialized and not `nil`.
*/
internal_int_compare_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (comparison: int) {
	assert_if_nil(a)
	a_is_negative := #force_inline internal_is_negative(a)

	switch {
	/*
		Compare based on sign first.
	*/
	case a_is_negative:     return -1
	/*
		Then compare on magnitude.
	*/
	case a.used > 1:        return +1
	/*
		We have only one digit. Compare it against `b`.
	*/
	case a.digit[0] < b:    return -1
	case a.digit[0] == b:   return  0
	case a.digit[0] > b:    return +1
	/*
		Unreachable.
		Just here because Odin complains about a missing return value at the bottom of the proc otherwise.
	*/
	case:                   return
	}
}
internal_compare_digit :: proc { internal_int_compare_digit, }
internal_cmp_digit :: internal_compare_digit

/*
	Compare the magnitude of two `Int`s, unsigned.
*/
internal_int_compare_magnitude :: #force_inline proc(a, b: ^Int) -> (comparison: int) {
	assert_if_nil(a, b)

	// Compare based on used digits.
	if a.used != b.used {
		return +1 if a.used > b.used else -1
	}

	// Same number of used digits, compare based on their value.
	#no_bounds_check for n := a.used - 1; n >= 0; n -= 1 {
		if a.digit[n] != b.digit[n] {
			return +1 if a.digit[n] > b.digit[n] else -1
		}
	}
	return 0
}
internal_compare_magnitude :: proc { internal_int_compare_magnitude, }
internal_cmp_mag :: internal_compare_magnitude


/*
	bool := a < b
*/
internal_int_less_than :: #force_inline proc(a, b: ^Int) -> (less_than: bool) {
	return internal_cmp(a, b) == -1
}

/*
	bool := a < b
*/
internal_int_less_than_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (less_than: bool) {
	return internal_cmp_digit(a, b) == -1
}

/*
	bool := |a| < |b|
    Compares the magnitudes only, ignores the sign.
*/
internal_int_less_than_abs :: #force_inline proc(a, b: ^Int) -> (less_than: bool) {
	return internal_cmp_mag(a, b) == -1
}

internal_less_than :: proc {
	internal_int_less_than,
	internal_int_less_than_digit,
}
internal_lt :: internal_less_than

internal_less_than_abs :: proc {
	internal_int_less_than_abs,
}
internal_lt_abs :: internal_less_than_abs


/*
	bool := a <= b
*/
internal_int_less_than_or_equal :: #force_inline proc(a, b: ^Int) -> (less_than_or_equal: bool) {
	return internal_cmp(a, b) <= 0
}

/*
	bool := a <= b
*/
internal_int_less_than_or_equal_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (less_than_or_equal: bool) {
	return internal_cmp_digit(a, b) <= 0
}

/*
	bool := |a| <= |b|
    Compares the magnitudes only, ignores the sign.
*/
internal_int_less_than_or_equal_abs :: #force_inline proc(a, b: ^Int) -> (less_than_or_equal: bool) {
	return internal_cmp_mag(a, b) <= 0
}

internal_less_than_or_equal :: proc {
	internal_int_less_than_or_equal,
	internal_int_less_than_or_equal_digit,
}
internal_lte :: internal_less_than_or_equal

internal_less_than_or_equal_abs :: proc {
	internal_int_less_than_or_equal_abs,
}
internal_lte_abs :: internal_less_than_or_equal_abs


/*
	bool := a == b
*/
internal_int_equals :: #force_inline proc(a, b: ^Int) -> (equals: bool) {
	return internal_cmp(a, b) == 0
}

/*
	bool := a == b
*/
internal_int_equals_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (equals: bool) {
	return internal_cmp_digit(a, b) == 0
}

/*
	bool := |a| == |b|
    Compares the magnitudes only, ignores the sign.
*/
internal_int_equals_abs :: #force_inline proc(a, b: ^Int) -> (equals: bool) {
	return internal_cmp_mag(a, b) == 0
}

internal_equals :: proc {
	internal_int_equals,
	internal_int_equals_digit,
}
internal_eq :: internal_equals

internal_equals_abs :: proc {
	internal_int_equals_abs,
}
internal_eq_abs :: internal_equals_abs


/*
	bool := a >= b
*/
internal_int_greater_than_or_equal :: #force_inline proc(a, b: ^Int) -> (greater_than_or_equal: bool) {
	return internal_cmp(a, b) >= 0
}

/*
	bool := a >= b
*/
internal_int_greater_than_or_equal_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (greater_than_or_equal: bool) {
	return internal_cmp_digit(a, b) >= 0
}

/*
	bool := |a| >= |b|
    Compares the magnitudes only, ignores the sign.
*/
internal_int_greater_than_or_equal_abs :: #force_inline proc(a, b: ^Int) -> (greater_than_or_equal: bool) {
	return internal_cmp_mag(a, b) >= 0
}

internal_greater_than_or_equal :: proc {
	internal_int_greater_than_or_equal,
	internal_int_greater_than_or_equal_digit,
}
internal_gte :: internal_greater_than_or_equal

internal_greater_than_or_equal_abs :: proc {
	internal_int_greater_than_or_equal_abs,
}
internal_gte_abs :: internal_greater_than_or_equal_abs


/*
	bool := a > b
*/
internal_int_greater_than :: #force_inline proc(a, b: ^Int) -> (greater_than: bool) {
	return internal_cmp(a, b) == 1
}

/*
	bool := a > b
*/
internal_int_greater_than_digit :: #force_inline proc(a: ^Int, b: DIGIT) -> (greater_than: bool) {
	return internal_cmp_digit(a, b) == 1
}

/*
	bool := |a| > |b|
    Compares the magnitudes only, ignores the sign.
*/
internal_int_greater_than_abs :: #force_inline proc(a, b: ^Int) -> (greater_than: bool) {
	return internal_cmp_mag(a, b) == 1
}

internal_greater_than :: proc {
	internal_int_greater_than,
	internal_int_greater_than_digit,
}
internal_gt :: internal_greater_than

internal_greater_than_abs :: proc {
	internal_int_greater_than_abs,
}
internal_gt_abs :: internal_greater_than_abs


/*
	Check if remainders are possible squares - fast exclude non-squares.

	Returns `true` if `a` is a square, `false` if not.
	Assumes `a` not to be `nil` and to have been initialized.
*/
internal_int_is_square :: proc(a: ^Int, allocator := context.allocator) -> (square: bool, err: Error) {
	context.allocator = allocator

	/*
		Default to Non-square :)
	*/
	square = false

	if internal_is_negative(a)                                       { return }
	if internal_is_zero(a)                                           { return }

	/*
		First check mod 128 (suppose that _DIGIT_BITS is at least 7).
	*/
	if _private_int_rem_128[127 & a.digit[0]] == 1                   { return }

	/*
		Next check mod 105 (3*5*7).
	*/
	c: DIGIT
	c, err = internal_mod(a, 105)
	if _private_int_rem_105[c] == 1                                  { return }

	t := &Int{}
	defer destroy(t)

	set(t, 11 * 13 * 17 * 19 * 23 * 29 * 31) or_return
	internal_mod(t, a, t) or_return

	r: u64
	r, err = internal_int_get(t, u64)

	/*
		Check for other prime modules, note it's not an ERROR but we must
		free "t" so the easiest way is to goto LBL_ERR.  We know that err
		is already equal to MP_OKAY from the mp_mod call
	*/
	if (1 << (r % 11) &      0x5C4) != 0                             { return }
	if (1 << (r % 13) &      0x9E4) != 0                             { return }
	if (1 << (r % 17) &     0x5CE8) != 0                             { return }
	if (1 << (r % 19) &    0x4F50C) != 0                             { return }
	if (1 << (r % 23) &   0x7ACCA0) != 0                             { return }
	if (1 << (r % 29) &  0xC2EDD0C) != 0                             { return }
	if (1 << (r % 31) & 0x6DE2B848) != 0                             { return }

	/*
		Final check - is sqr(sqrt(arg)) == arg?
	*/
	sqrt(t, a) or_return
	sqr(t, t)  or_return

	square = internal_eq_abs(t, a)

	return
}

/*
	=========================    Logs, powers and roots    ============================
*/

/*
	Returns log_base(a).
	Assumes `a` to not be `nil` and have been iniialized.
*/
internal_int_log :: proc(a: ^Int, base: DIGIT) -> (res: int, err: Error) {
	if base < 2 || DIGIT(base) > _DIGIT_MAX { return -1, .Invalid_Argument }

	if internal_is_negative(a) { return -1, .Math_Domain_Error }
	if internal_is_zero(a)     { return -1, .Math_Domain_Error }

	/*
		Fast path for bases that are a power of two.
	*/
	if platform_int_is_power_of_two(int(base)) { return _private_log_power_of_two(a, base) }

	/*
		Fast path for `Int`s that fit within a single `DIGIT`.
	*/
	if a.used == 1 { return internal_log(a.digit[0], DIGIT(base)) }

	return _private_int_log(a, base)

}

/*
	Returns log_base(a), where `a` is a DIGIT.
*/
internal_digit_log :: proc(a: DIGIT, base: DIGIT) -> (log: int, err: Error) {
	/*
		If the number is smaller than the base, it fits within a fraction.
		Therefore, we return 0.
	*/
	if a  < base { return 0, nil }

	/*
		If a number equals the base, the log is 1.
	*/
	if a == base { return 1, nil }

	N := _WORD(a)
	bracket_low  := _WORD(1)
	bracket_high := _WORD(base)
	high := 1
	low  := 0

	for bracket_high < N {
		low = high
		bracket_low = bracket_high
		high <<= 1
		bracket_high *= bracket_high
	}

	for high - low > 1 {
		mid := (low + high) >> 1
		bracket_mid := bracket_low * #force_inline internal_small_pow(_WORD(base), _WORD(mid - low))

		if N < bracket_mid {
			high = mid
			bracket_high = bracket_mid
		}
		if N > bracket_mid {
			low = mid
			bracket_low = bracket_mid
		}
		if N == bracket_mid {
			return mid, nil
		}
	}

	if bracket_high == N {
		return high, nil
	} else {
		return low, nil
	}
}
internal_log :: proc { internal_int_log, internal_digit_log, }

/*
	Calculate dest = base^power using a square-multiply algorithm.
	Assumes `dest` and `base` not to be `nil` and to have been initialized.
*/
internal_int_pow :: proc(dest, base: ^Int, power: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	power := power
	/*
		Early outs.
	*/
	if #force_inline internal_is_zero(base) {
		/*
			A zero base is a special case.
		*/
		if power  < 0 {
			internal_zero(dest) or_return
			return .Math_Domain_Error
		}
		if power == 0 { return  internal_one(dest) }
		if power  > 0 { return internal_zero(dest) }

	}
	if power < 0 {
		/*
			Fraction, so we'll return zero.
		*/
		return internal_zero(dest)
	}
	switch(power) {
	case 0:
		/*
			Any base to the power zero is one.
		*/
		return #force_inline internal_one(dest)
	case 1:
		/*
			Any base to the power one is itself.
		*/
		return copy(dest, base)
	case 2:
		return #force_inline internal_sqr(dest, base)
	}

	g := &Int{}
	internal_copy(g, base) or_return

	/*
		Set initial result.
	*/
	internal_one(dest) or_return

	defer internal_destroy(g)

	for power > 0 {
		/*
			If the bit is set, multiply.
		*/
		if power & 1 != 0 {
			internal_mul(dest, g, dest) or_return
		}
		/*
			Square.
		*/
		if power > 1 {
			internal_sqr(g, g) or_return
		}

		/* shift to next bit */
		power >>= 1
	}

	return
}

/*
	Calculate `dest = base^power`.
	Assumes `dest` not to be `nil` and to have been initialized.
*/
internal_int_pow_int :: proc(dest: ^Int, base, power: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	base_t := &Int{}
	defer internal_destroy(base_t)

	internal_set(base_t, base) or_return

	return #force_inline internal_int_pow(dest, base_t, power)
}

internal_pow :: proc { internal_int_pow, internal_int_pow_int, }
internal_exp :: pow

/*

*/
internal_small_pow :: proc(base: _WORD, exponent: _WORD) -> (result: _WORD) {
	exponent := exponent; base := base
	result = _WORD(1)

	for exponent != 0 {
		if exponent & 1 == 1 {
			result *= base
		}
		exponent >>= 1
		base *= base
	}
	return result
}

/*
	This function is less generic than `root_n`, simpler and faster.
	Assumes `dest` and `src` not to be `nil` and to have been initialized.
*/
internal_int_sqrt :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Must be positive.
	*/
	if #force_inline internal_is_negative(src)  { return .Invalid_Argument }

	/*
		Easy out. If src is zero, so is dest.
	*/
	if #force_inline internal_is_zero(src)      { return internal_zero(dest) }

	/*
		Set up temporaries.
	*/
	x, y, t1, t2 := &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(x, y, t1, t2)

	count := #force_inline internal_count_bits(src)

	a, b := count >> 1, count & 1
	internal_int_power_of_two(x, a+b, allocator) or_return

	for {
		/*
			y = (x + n // x) // 2
		*/
		internal_div(t1, src, x) or_return
		internal_add(t2, t1, x)  or_return
		internal_shr(y, t2, 1)   or_return

		if internal_gte(y, x) {
			internal_swap(dest, x)
			return nil
		}
		internal_swap(x, y)
	}

	internal_swap(dest, x)
	return err
}
internal_sqrt :: proc { internal_int_sqrt, }


/*
	Find the nth root of an Integer.
	Result found such that `(dest)**n <= src` and `(dest+1)**n > src`

	This algorithm uses Newton's approximation `x[i+1] = x[i] - f(x[i])/f'(x[i])`,
	which will find the root in `log(n)` time where each step involves a fair bit.

	Assumes `dest` and `src` not to be `nil` and have been initialized.
*/
internal_int_root_n :: proc(dest, src: ^Int, n: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Fast path for n == 2
	*/
	if n == 2 { return #force_inline internal_sqrt(dest, src) }

	if n < 0 || n > int(_DIGIT_MAX) { return .Invalid_Argument }

	if n & 1 == 0 && #force_inline internal_is_negative(src) { return .Invalid_Argument }

	/*
		Set up temporaries.
	*/
	t1, t2, t3, a := &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(t1, t2, t3)

	/*
		If `src` is negative fudge the sign but keep track.
	*/
	a.sign  = .Zero_or_Positive
	a.used  = src.used
	a.digit = src.digit

	/*
		If "n" is larger than INT_MAX it is also larger than
		log_2(src) because the bit-length of the "src" is measured
		with an int and hence the root is always < 2 (two).
	*/
	if n > max(int) / 2 {
		err = set(dest, 1)
		dest.sign = a.sign
		return err
	}

	/*
		Compute seed: 2^(log_2(src)/n + 2)
	*/
	ilog2 := internal_count_bits(src)

	/*
		"src" is smaller than max(int), we can cast safely.
	*/
	if ilog2 < n {
		err = internal_one(dest)
		dest.sign = a.sign
		return err
	}

	ilog2 /= n
	if ilog2 == 0 {
		err = internal_one(dest)
		dest.sign = a.sign
		return err
	}

	/*
		Start value must be larger than root.
	*/
	ilog2 += 2
	internal_int_power_of_two(t2, ilog2) or_return

	c: int
	iterations := 0
	for {
		/* t1 = t2 */
		internal_copy(t1, t2) or_return

		/* t2 = t1 - ((t1**b - a) / (b * t1**(b-1))) */

		/* t3 = t1**(b-1) */
		internal_pow(t3, t1, n-1) or_return

		/* numerator */
		/* t2 = t1**b */
		internal_mul(t2, t1, t3) or_return

		/* t2 = t1**b - a */
		internal_sub(t2, t2, a) or_return

		/* denominator */
		/* t3 = t1**(b-1) * b  */
		internal_mul(t3, t3, DIGIT(n)) or_return

		/* t3 = (t1**b - a)/(b * t1**(b-1)) */
		internal_div(t3, t2, t3) or_return
		internal_sub(t2, t1, t3) or_return

		/*
			 Number of rounds is at most log_2(root). If it is more it
			 got stuck, so break out of the loop and do the rest manually.
		*/
		if ilog2 -= 1; ilog2 == 0 { break }
		if internal_eq(t1, t2)    { break }

		iterations += 1
		if iterations == MAX_ITERATIONS_ROOT_N {
			return .Max_Iterations_Reached
		}
	}

	/*						Result can be off by a few so check.					*/
	/* Loop beneath can overshoot by one if found root is smaller than actual root. */

	iterations = 0
	for {
		internal_pow(t2, t1, n) or_return

		c = internal_cmp(t2, a)
		if c == 0 {
			swap(dest, t1)
			return nil
		} else if c == -1 {
			internal_add(t1, t1, DIGIT(1)) or_return
		} else {
			break
		}

		iterations += 1
		if iterations == MAX_ITERATIONS_ROOT_N {
			return .Max_Iterations_Reached
		}
	}

	iterations = 0
	/*
		Correct overshoot from above or from recurrence.
		*/
	for {
		internal_pow(t2, t1, n) or_return
	
		if internal_lt(t2, a) { break }
		
		internal_sub(t1, t1, DIGIT(1)) or_return

		iterations += 1
		if iterations == MAX_ITERATIONS_ROOT_N {
			return .Max_Iterations_Reached
		}
	}

	/*
		Set the result.
	*/
	internal_swap(dest, t1)

	/*
		Set the sign of the result.
	*/
	dest.sign = src.sign

	return err
}
internal_root_n :: proc { internal_int_root_n, }

/*
	Other internal helpers
*/

/*
	Deallocates the backing memory of one or more `Int`s.
	Asssumes none of the `integers` to be a `nil`.
*/
internal_int_destroy :: proc(integers: ..^Int) {
	integers := integers

	for &a in integers {
		if internal_int_allocated_cap(a) > 0 {
			mem.zero_slice(a.digit[:])
			free(&a.digit[0])
		}
		a = &Int{}
	}
}
internal_destroy :: proc{ 
	internal_int_destroy, 
	internal_rat_destroy, 
}

/*
	Helpers to set an `Int` to a specific value.
*/
internal_int_set_from_integer :: proc(dest: ^Int, src: $T, minimize := false, allocator := context.allocator) -> (err: Error)
	where intrinsics.type_is_integer(T) {
	context.allocator = allocator

	internal_error_if_immutable(dest) or_return
	/*
		Most internal procs asssume an Int to have already been initialize,
		but as this is one of the procs that initializes, we have to check the following.
	*/
	internal_clear_if_uninitialized_single(dest) or_return

	dest.flags = {} // We're not -Inf, Inf, NaN or Immutable.

	dest.used  = 0
	dest.sign = .Negative if src < 0 else .Zero_or_Positive

	temp := src

	is_maximally_negative := src == min(T)
	if is_maximally_negative {
		/*
			Prevent overflow on abs()
		*/
		temp += 1
	}
	temp = -temp if temp < 0 else temp

	#no_bounds_check for temp != 0 {
		dest.digit[dest.used] = DIGIT(temp) & _MASK
		dest.used += 1
		temp >>= _DIGIT_BITS
	}

	if is_maximally_negative {
		return internal_sub(dest, dest, 1)
	}
	internal_zero_unused(dest)
	return nil
}

internal_set :: proc { internal_int_set_from_integer, internal_int_copy, int_atoi }

internal_copy_digits :: #force_inline proc(dest, src: ^Int, digits: int, offset := int(0)) -> (err: Error) {
	#force_inline internal_error_if_immutable(dest) or_return

	/*
		If dest == src, do nothing
	*/
	return #force_inline _private_copy_digits(dest, src, digits, offset)
}

/*
	Copy one `Int` to another.
*/
internal_int_copy :: proc(dest, src: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		If dest == src, do nothing
	*/
	if (dest == src) { return nil }

	internal_error_if_immutable(dest) or_return

	/*
		Grow `dest` to fit `src`.
		If `dest` is not yet initialized, it will be using `allocator`.
	*/
	needed := src.used if minimize else max(src.used, _DEFAULT_DIGIT_COUNT)

	internal_grow(dest, needed, minimize) or_return

	/*
		Copy everything over and zero high digits.
	*/
	internal_copy_digits(dest, src, src.used)

	dest.used  = src.used
	dest.sign  = src.sign
	dest.flags = src.flags &~ {.Immutable}

	internal_zero_unused(dest)
	return nil
}
internal_copy :: proc { internal_int_copy, }

/*
	In normal code, you can also write `a, b = b, a`.
	However, that only swaps within the current scope.
	This helper swaps completely.
*/
internal_int_swap :: #force_inline proc(a, b: ^Int) {
	a.used,  b.used  = b.used,  a.used
	a.sign,  b.sign  = b.sign,  a.sign
	a.digit, b.digit = b.digit, a.digit
}
internal_swap :: proc { 
	internal_int_swap, 
	internal_rat_swap,
}

/*
	Set `dest` to |`src`|.
*/
internal_int_abs :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		If `dest == src`, just fix `dest`'s sign.
	*/
	if (dest == src) {
		dest.sign = .Zero_or_Positive
		return nil
	}

	/*
		Copy `src` to `dest`
	*/
	internal_copy(dest, src) or_return

	/*
		Fix sign.
	*/
	dest.sign = .Zero_or_Positive
	return nil
}

internal_platform_abs :: proc(n: $T) -> T where intrinsics.type_is_integer(T) {
	return n if n >= 0 else -n
}
internal_abs :: proc{ internal_int_abs, internal_platform_abs, }

/*
	Set `dest` to `-src`.
*/
internal_int_neg :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		If `dest == src`, just fix `dest`'s sign.
	*/
	sign := Sign.Negative
	if #force_inline internal_is_zero(src) || #force_inline internal_is_negative(src) {
		sign = .Zero_or_Positive
	}
	if dest == src {
		dest.sign = sign
		return nil
	}
	/*
		Copy `src` to `dest`
	*/
	internal_copy(dest, src) or_return

	/*
		Fix sign.
	*/
	dest.sign = sign
	return nil
}
internal_neg :: proc { internal_int_neg, }

/*
	hac 14.61, pp608.
*/
internal_int_inverse_modulo :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	/*
		For all n in N and n > 0, n = 0 mod 1.
	*/
	if internal_is_positive(a) && internal_eq(b, 1) { return internal_zero(dest)	}

	/*
		`b` cannot be negative and b has to be > 1
	*/
	if internal_is_negative(b) || !internal_gt(b, 1) { return .Invalid_Argument }

	/*
		If the modulus is odd we can use a faster routine instead.
	*/
	if internal_is_odd(b) { return _private_inverse_modulo_odd(dest, a, b) }

	return _private_inverse_modulo(dest, a, b)
}
internal_int_invmod :: internal_int_inverse_modulo
internal_invmod :: proc{ internal_int_inverse_modulo, }

/*
	Helpers to extract values from the `Int`.
	Offset is zero indexed.
*/
internal_int_bitfield_extract_bool :: proc(a: ^Int, offset: int) -> (val: bool, err: Error) {
	limb := offset / _DIGIT_BITS
	if limb < 0 || limb >= a.used  { return false, .Invalid_Argument }
	i := _WORD(1 << _WORD((offset % _DIGIT_BITS)))
	return bool(_WORD(a.digit[limb]) & i), nil
}

internal_int_bitfield_extract_single :: proc(a: ^Int, offset: int) -> (bit: _WORD, err: Error) {
	limb := offset / _DIGIT_BITS
	if limb < 0 || limb >= a.used  { return 0, .Invalid_Argument }
	i := _WORD(1 << _WORD((offset % _DIGIT_BITS)))
	return 1 if ((_WORD(a.digit[limb]) & i) != 0) else 0, nil
}

internal_int_bitfield_extract :: proc(a: ^Int, offset, count: int) -> (res: _WORD, err: Error) #no_bounds_check {
	/*
		Early out for single bit.
	*/
	if count == 1 {
		limb := offset / _DIGIT_BITS
		if limb < 0 || limb >= a.used  { return 0, .Invalid_Argument }
		i := _WORD(1 << _WORD((offset % _DIGIT_BITS)))
		return 1 if ((_WORD(a.digit[limb]) & i) != 0) else 0, nil
	}

	if count > _WORD_BITS || count < 1 { return 0, .Invalid_Argument }

	/*
		There are 3 possible cases.
		-	[offset:][:count] covers 1 DIGIT,
				e.g. offset:  0, count:  60 = bits 0..59
		-	[offset:][:count] covers 2 DIGITS,
				e.g. offset:  5, count:  60 = bits 5..59, 0..4
				e.g. offset:  0, count: 120 = bits 0..59, 60..119
		-	[offset:][:count] covers 3 DIGITS,
				e.g. offset: 40, count: 100 = bits 40..59, 0..59, 0..19
				e.g. offset: 40, count: 120 = bits 40..59, 0..59, 0..39
	*/

	limb        := offset / _DIGIT_BITS
	bits_left   := count
	bits_offset := offset % _DIGIT_BITS

	num_bits    := min(bits_left, _DIGIT_BITS - bits_offset)

	shift       := offset % _DIGIT_BITS
	mask        := (_WORD(1) << uint(num_bits)) - 1
	res          = (_WORD(a.digit[limb]) >> uint(shift)) & mask

	bits_left -= num_bits
	if bits_left == 0 { return res, nil }

	res_shift := num_bits
	num_bits   = min(bits_left, _DIGIT_BITS)
	mask       = (1 << uint(num_bits)) - 1

	res |= (_WORD(a.digit[limb + 1]) & mask) << uint(res_shift)

	bits_left -= num_bits
	if bits_left == 0 { return res, nil }

	mask     = (1 << uint(bits_left)) - 1
	res_shift += _DIGIT_BITS

	res |= (_WORD(a.digit[limb + 2]) & mask) << uint(res_shift)

	return res, nil
}

/*
	Helpers to (un)set a bit in an Int.
	Offset is zero indexed.
*/
internal_int_bitfield_set_single :: proc(a: ^Int, offset: int) -> (err: Error) {
	limb := offset / _DIGIT_BITS
	if limb < 0 || limb >= a.used  { return .Invalid_Argument }
	i := DIGIT(1 << uint((offset % _DIGIT_BITS)))
	a.digit[limb] |= i
	return
}

internal_int_bitfield_unset_single :: proc(a: ^Int, offset: int) -> (err: Error) {
	limb := offset / _DIGIT_BITS
	if limb < 0 || limb >= a.used  { return .Invalid_Argument }
	i := DIGIT(1 << uint((offset % _DIGIT_BITS)))
	a.digit[limb] &= _MASK - i
	return
}

internal_int_bitfield_toggle_single :: proc(a: ^Int, offset: int) -> (err: Error) {
	limb := offset / _DIGIT_BITS
	if limb < 0 || limb >= a.used  { return .Invalid_Argument }
	i := DIGIT(1 << uint((offset % _DIGIT_BITS)))
	a.digit[limb] ~= i
	return
}

/*
	Resize backing store.
	We don't need to pass the allocator, because the storage itself stores it.

	Assumes `a` not to be `nil`, and to have already been initialized.
*/
internal_int_shrink :: proc(a: ^Int) -> (err: Error) {
	needed := max(_MIN_DIGIT_COUNT, a.used)

	if a.used != needed { return internal_grow(a, needed, true) }
	return nil
}
internal_shrink :: proc { internal_int_shrink, }

internal_int_grow :: proc(a: ^Int, digits: int, allow_shrink := false, allocator := context.allocator) -> (err: Error) {
	/*
		We need at least _MIN_DIGIT_COUNT or a.used digits, whichever is bigger.
		The caller is asking for `digits`. Let's be accomodating.
	*/
	cap := internal_int_allocated_cap(a)

	needed := max(_MIN_DIGIT_COUNT, a.used, digits)
	if !allow_shrink {
		needed = max(needed, cap)
	}

	/*
		If not yet initialized, initialize the `digit` backing with the allocator we were passed.
	*/
	if cap == 0 {
		a.digit = make([dynamic]DIGIT, needed, allocator)
	} else if cap < needed {
		/*
			`[dynamic]DIGIT` already knows what allocator was used for it, so resize will do the right thing.
		*/
		resize(&a.digit, needed)
	} else if cap > needed {
		/*
			Same applies to builtin.shrink here as resize above
		*/
		builtin.shrink(&a.digit, needed)
	}
	/*
		Let's see if the allocation/resize worked as expected.
	*/
	if len(a.digit) != needed {
		return .Out_Of_Memory
	}
	return nil
}
internal_grow :: proc { internal_int_grow, }

/*
	Clear `Int` and resize it to the default size.
	Assumes `a` not to be `nil`.
*/
internal_int_clear :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	raw := transmute(mem.Raw_Dynamic_Array)a.digit
	if raw.cap != 0 {
		mem.zero_slice(a.digit[:a.used])
	}
	a.sign = .Zero_or_Positive
	a.used = 0

	return #force_inline internal_grow(a, a.used, minimize, allocator)
}
internal_clear :: proc { internal_int_clear, }
internal_zero  :: internal_clear

/*
	Set the `Int` to 1 and optionally shrink it to the minimum backing size.
*/
internal_int_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	return internal_copy(a, INT_ONE, minimize, allocator)
}
internal_one :: proc { internal_int_one, }

/*
	Set the `Int` to -1 and optionally shrink it to the minimum backing size.
*/
internal_int_minus_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	return internal_copy(a, INT_MINUS_ONE, minimize, allocator)
}
internal_minus_one :: proc { internal_int_minus_one, }

/*
	Set the `Int` to Inf and optionally shrink it to the minimum backing size.
*/
internal_int_inf :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	return internal_copy(a, INT_INF, minimize, allocator)
}
internal_inf :: proc { internal_int_inf, }

/*
	Set the `Int` to -Inf and optionally shrink it to the minimum backing size.
*/
internal_int_minus_inf :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	return internal_copy(a, INT_MINUS_INF, minimize, allocator)
}
internal_minus_inf :: proc { internal_int_inf, }

/*
	Set the `Int` to NaN and optionally shrink it to the minimum backing size.
*/
internal_int_nan :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	return internal_copy(a, INT_NAN, minimize, allocator)
}
internal_nan :: proc { internal_int_nan, }

internal_int_power_of_two :: proc(a: ^Int, power: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if power < 0 || power > _MAX_BIT_COUNT { return .Invalid_Argument }

	/*
		Grow to accomodate the single bit.
	*/
	a.used = (power / _DIGIT_BITS) + 1
	internal_grow(a, a.used) or_return
	/*
		Zero the entirety.
	*/
	mem.zero_slice(a.digit[:])

	/*
		Set the bit.
	*/
	a.digit[power / _DIGIT_BITS] = 1 << uint((power % _DIGIT_BITS))
	return nil
}

internal_int_get_u128 :: proc(a: ^Int) -> (res: u128, err: Error) {
	return internal_int_get(a, u128)
}
internal_get_u128 :: proc { internal_int_get_u128, }

internal_int_get_i128 :: proc(a: ^Int) -> (res: i128, err: Error) {
	return internal_int_get(a, i128)
}
internal_get_i128 :: proc { internal_int_get_i128, }

internal_int_get_u64 :: proc(a: ^Int) -> (res: u64, err: Error) {
	return internal_int_get(a, u64)
}
internal_get_u64 :: proc { internal_int_get_u64, }

internal_int_get_i64 :: proc(a: ^Int) -> (res: i64, err: Error) {
	return internal_int_get(a, i64)
}
internal_get_i64 :: proc { internal_int_get_i64, }

internal_int_get_u32 :: proc(a: ^Int) -> (res: u32, err: Error) {
	return internal_int_get(a, u32)
}
internal_get_u32 :: proc { internal_int_get_u32, }

internal_int_get_i32 :: proc(a: ^Int) -> (res: i32, err: Error) {
	return internal_int_get(a, i32)
}
internal_get_i32 :: proc { internal_int_get_i32, }

internal_get_low_u32 :: proc(a: ^Int) -> u32 #no_bounds_check {
	if a == nil {
		return 0
	}
	
	if a.used == 0 {
		return 0
	}
	
	return u32(a.digit[0])
}
internal_get_low_u64 :: proc(a: ^Int) -> u64 #no_bounds_check {
	if a == nil {
		return 0
	}
	
	if a.used == 0 {
		return 0
	}
	
	v := u64(a.digit[0])
	when size_of(DIGIT) == 4 {
		if a.used > 1 {
			return u64(a.digit[1])<<32 | v
		}
	}
	return v
}

/*
	TODO: Think about using `count_bits` to check if the value could be returned completely,
	and maybe return max(T), .Integer_Overflow if not?
*/
internal_int_get :: proc(a: ^Int, $T: typeid) -> (res: T, err: Error) where intrinsics.type_is_integer(T) {
	/*
		Calculate target bit size.
	*/
	target_bit_size := int(size_of(T) * 8)
	when !intrinsics.type_is_unsigned(T) {
		if a.sign == .Zero_or_Positive {
			target_bit_size -= 1
		}
	} else {
		if a.sign == .Negative {
			return 0, .Integer_Underflow
		}
	}

	bits_used := internal_count_bits(a)

	if bits_used > target_bit_size {
		if a.sign == .Negative {
			return min(T), .Integer_Underflow
		}
		return max(T), .Integer_Overflow
	}

	for i := a.used; i > 0; i -= 1 {
		res <<= _DIGIT_BITS
		res |=  T(a.digit[i - 1])
	}

	when !intrinsics.type_is_unsigned(T) {
		/*
			Set the sign.
		*/
		if a.sign == .Negative { res = -res }
	}
	return
}
internal_get :: proc { internal_int_get, }

internal_int_get_float :: proc(a: ^Int) -> (res: f64, err: Error) {
	/*
		log2(max(f64)) is approximately 1020, or 17 legs with the 64-bit storage.
	*/
	legs :: 1020 / _DIGIT_BITS
	l   := min(a.used, legs)
	fac := f64(1 << _DIGIT_BITS)
	d   := 0.0

	#no_bounds_check for i := l; i >= 0; i -= 1 {
		d = (d * fac) + f64(a.digit[i])
	}

	res = -d if a.sign == .Negative else d
	return
}

/*
	The `and`, `or` and `xor` binops differ in two lines only.
	We could handle those with a switch, but that adds overhead.

	TODO: Implement versions that take a DIGIT immediate.
*/

/*
	2's complement `and`, returns `dest = a & b;`
*/
internal_int_and :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	used := max(a.used, b.used) + 1
	/*
		Grow the destination to accomodate the result.
	*/
	internal_grow(dest, used) or_return

	neg_a := #force_inline internal_is_negative(a)
	neg_b := #force_inline internal_is_negative(b)
	neg   := neg_a && neg_b

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1)

	#no_bounds_check for i := 0; i < used; i += 1 {
		x, y: DIGIT

		/*
			Convert to 2's complement if negative.
		*/
		if neg_a {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK)
			x = ac & _MASK
			ac >>= _DIGIT_BITS
		} else {
			x = 0 if i >= a.used else a.digit[i]
		}

		/*
			Convert to 2's complement if negative.
		*/
		if neg_b {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK)
			y = bc & _MASK
			bc >>= _DIGIT_BITS
		} else {
			y = 0 if i >= b.used else b.digit[i]
		}

		dest.digit[i] = x & y

		/*
			Convert to to sign-magnitude if negative.
		*/
		if neg {
			cc += ~dest.digit[i] & _MASK
			dest.digit[i] = cc & _MASK
			cc >>= _DIGIT_BITS
		}
	}

	dest.used = used
	dest.sign = .Negative if neg else .Zero_or_Positive
	return internal_clamp(dest)
}
internal_and :: proc { internal_int_and, }

/*
	2's complement `or`, returns `dest = a | b;`
*/
internal_int_or :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	used := max(a.used, b.used) + 1
	/*
		Grow the destination to accomodate the result.
	*/
	internal_grow(dest, used) or_return

	neg_a := #force_inline internal_is_negative(a)
	neg_b := #force_inline internal_is_negative(b)
	neg   := neg_a || neg_b

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1)

	#no_bounds_check for i := 0; i < used; i += 1 {
		x, y: DIGIT

		/*
			Convert to 2's complement if negative.
		*/
		if neg_a {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK)
			x = ac & _MASK
			ac >>= _DIGIT_BITS
		} else {
			x = 0 if i >= a.used else a.digit[i]
		}

		/*
			Convert to 2's complement if negative.
		*/
		if neg_b {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK)
			y = bc & _MASK
			bc >>= _DIGIT_BITS
		} else {
			y = 0 if i >= b.used else b.digit[i]
		}

		dest.digit[i] = x | y

		/*
			Convert to to sign-magnitude if negative.
		*/
		if neg {
			cc += ~dest.digit[i] & _MASK
			dest.digit[i] = cc & _MASK
			cc >>= _DIGIT_BITS
		}
	}

	dest.used = used
	dest.sign = .Negative if neg else .Zero_or_Positive
	return internal_clamp(dest)
}
internal_or :: proc { internal_int_or, }

/*
	2's complement `xor`, returns `dest = a ~ b;`
*/
internal_int_xor :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	used := max(a.used, b.used) + 1
	/*
		Grow the destination to accomodate the result.
	*/
	internal_grow(dest, used) or_return

	neg_a := #force_inline internal_is_negative(a)
	neg_b := #force_inline internal_is_negative(b)
	neg   := neg_a != neg_b

	ac, bc, cc := DIGIT(1), DIGIT(1), DIGIT(1)

	#no_bounds_check for i := 0; i < used; i += 1 {
		x, y: DIGIT

		/*
			Convert to 2's complement if negative.
		*/
		if neg_a {
			ac += _MASK if i >= a.used else (~a.digit[i] & _MASK)
			x = ac & _MASK
			ac >>= _DIGIT_BITS
		} else {
			x = 0 if i >= a.used else a.digit[i]
		}

		/*
			Convert to 2's complement if negative.
		*/
		if neg_b {
			bc += _MASK if i >= b.used else (~b.digit[i] & _MASK)
			y = bc & _MASK
			bc >>= _DIGIT_BITS
		} else {
			y = 0 if i >= b.used else b.digit[i]
		}

		dest.digit[i] = x ~ y

		/*
			Convert to to sign-magnitude if negative.
		*/
		if neg {
			cc += ~dest.digit[i] & _MASK
			dest.digit[i] = cc & _MASK
			cc >>= _DIGIT_BITS
		}
	}

	dest.used = used
	dest.sign = .Negative if neg else .Zero_or_Positive
	return internal_clamp(dest)
}
internal_xor :: proc { internal_int_xor, }

/*
	dest = ~src
*/
internal_int_complement :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Temporarily fix sign.
	*/
	old_sign := src.sign

	neg := #force_inline internal_is_zero(src) || #force_inline internal_is_positive(src)

	src.sign = .Negative if neg else .Zero_or_Positive

	err = #force_inline internal_sub(dest, src, 1)
	/*
		Restore sign.
	*/
	src.sign = old_sign

	return err
}
internal_complement :: proc { internal_int_complement, }

/*
	quotient, remainder := numerator >> bits;
	`remainder` is allowed to be passed a `nil`, in which case `mod` won't be computed.
*/
internal_int_shrmod :: proc(quotient, remainder, numerator: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	bits := bits
	if bits < 0 { return .Invalid_Argument }

	internal_copy(quotient, numerator) or_return

	/*
		Shift right by a certain bit count (store quotient and optional remainder.)
	   `numerator` should not be used after this.
	*/
	if remainder != nil {
		internal_int_mod_bits(remainder, numerator, bits) or_return
	}

	/*
		Shift by as many digits in the bit count.
	*/
	if bits >= _DIGIT_BITS {
		_private_int_shr_leg(quotient, bits / _DIGIT_BITS) or_return
	}

	/*
		Shift any bit count < _DIGIT_BITS.
	*/
	bits %= _DIGIT_BITS
	if bits != 0 {
		mask  := DIGIT(1 << uint(bits)) - 1
		shift := DIGIT(_DIGIT_BITS - bits)
		carry := DIGIT(0)

		#no_bounds_check for x := quotient.used - 1; x >= 0; x -= 1 {
			/*
				Get the lower bits of this word in a temp.
			*/
			fwd_carry := quotient.digit[x] & mask

			/*
				Shift the current word and mix in the carry bits from the previous word.
			*/
			quotient.digit[x] = (quotient.digit[x] >> uint(bits)) | (carry << shift)

			/*
				Update carry from forward carry.
			*/
			carry = fwd_carry
		}

	}
	return internal_clamp(numerator)
}
internal_shrmod :: proc { internal_int_shrmod, }

internal_int_shr :: proc(dest, source: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	return #force_inline internal_shrmod(dest, nil, source, bits, allocator)
}
internal_shr :: proc { internal_int_shr, }

/*
	Shift right by a certain bit count with sign extension.
*/
internal_int_shr_signed :: proc(dest, src: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if src.sign == .Zero_or_Positive {
		return internal_shr(dest, src, bits)
	}
	internal_int_add_digit(dest, src, DIGIT(1)) or_return
	internal_shr(dest, dest, bits) or_return
	return internal_sub(dest, src, DIGIT(1))
}

internal_shr_signed :: proc { internal_int_shr_signed, }

/*
	Shift left by a certain bit count.
*/
internal_int_shl :: proc(dest, src: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	bits := bits

	if bits < 0 { return .Invalid_Argument }

	internal_copy(dest, src) or_return

	/*
		Grow `dest` to accommodate the additional bits.
	*/
	digits_needed := dest.used + (bits / _DIGIT_BITS) + 1
	internal_grow(dest, digits_needed) or_return
	dest.used = digits_needed
	/*
		Shift by as many digits in the bit count as we have.
	*/
	if bits >= _DIGIT_BITS {
		_private_int_shl_leg(dest, bits / _DIGIT_BITS) or_return
	}

	/*
		Shift any remaining bit count < _DIGIT_BITS
	*/
	bits %= _DIGIT_BITS
	if bits != 0 {
		mask  := (DIGIT(1) << uint(bits)) - DIGIT(1)
		shift := DIGIT(_DIGIT_BITS - bits)
		carry := DIGIT(0)

		#no_bounds_check for x:= 0; x < dest.used; x+= 1 {
			fwd_carry := (dest.digit[x] >> shift) & mask
			dest.digit[x] = (dest.digit[x] << uint(bits) | carry) & _MASK
			carry = fwd_carry
		}

		/*
			Use final carry.
		*/
		if carry != 0 {
			dest.digit[dest.used] = carry
			dest.used += 1
		}
	}
	return internal_clamp(dest)
}
internal_shl :: proc { internal_int_shl, }

/*
	Count bits in an `Int`.
	Assumes `a` not to be `nil` and to have been initialized.
*/
internal_count_bits :: proc(a: ^Int) -> (count: int) {
	/*
		Fast path for zero.
	*/
	if #force_inline internal_is_zero(a) { return {} }
	/*
		Get the number of DIGITs and use it.
	*/
	count  = (a.used - 1) * _DIGIT_BITS
	/*
		Take the last DIGIT and count the bits in it.
	*/
	clz   := int(intrinsics.count_leading_zeros(a.digit[a.used - 1]))
	count += (_DIGIT_TYPE_BITS - clz)
	return
}

/*
	Returns the number of trailing zeroes before the first one.
	Differs from regular `ctz` in that 0 returns 0.

	Assumes `a` not to be `nil` and have been initialized.
*/
internal_int_count_lsb :: proc(a: ^Int) -> (count: int, err: Error) {
	/*
		Easy out.
	*/
	if #force_inline internal_is_zero(a) { return {}, nil }

	/*
		Scan lower digits until non-zero.
	*/
	x: int
	#no_bounds_check for x = 0; x < a.used && a.digit[x] == 0; x += 1 {}

	when true {
		q := a.digit[x]
		x *= _DIGIT_BITS
		x += internal_count_lsb(q)
	} else {
		lnz := []int{
   			4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
		}

		q := a.digit[x]
		x *= _DIGIT_BITS
		if q & 1 == 0 {
			p: DIGIT
			for {
				p = q & 15
				x += lnz[p]
				q >>= 4
				if p != 0 { break }
			}
		}		
	}
	return x, nil
}

internal_platform_count_lsb :: #force_inline proc(a: $T) -> (count: int)
	where intrinsics.type_is_integer(T), intrinsics.type_is_unsigned(T) {
	return int(intrinsics.count_trailing_zeros(a)) if a > 0 else 0
}

internal_count_lsb :: proc { internal_int_count_lsb, internal_platform_count_lsb, }

internal_int_random_digit :: proc() -> (res: DIGIT) {
	when _DIGIT_BITS == 60 { // DIGIT = u64
		return DIGIT(rnd.uint64()) & _MASK
	} else when _DIGIT_BITS == 28 { // DIGIT = u32
		return DIGIT(rnd.uint32()) & _MASK
	} else {
		panic("Unsupported DIGIT size.")
	}

	return 0 // We shouldn't get here.
}

internal_int_random :: proc(dest: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	bits := bits

	if bits <= 0 { return .Invalid_Argument }

	digits := bits / _DIGIT_BITS
	bits   %= _DIGIT_BITS

	if bits > 0 {
		digits += 1
	}

	#force_inline internal_grow(dest, digits) or_return

	for i := 0; i < digits; i += 1 {
		dest.digit[i] = int_random_digit() & _MASK
	}
	if bits > 0 {
		dest.digit[digits - 1] &= ((1 << uint(bits)) - 1)
	}
	dest.used = digits
	return internal_clamp(dest)
}
internal_random :: proc { internal_int_random, }

/*
	Internal helpers.
*/
internal_assert_initialized :: proc(a: ^Int, loc := #caller_location) {
	assert(internal_is_initialized(a), "`Int` was not properly initialized.", loc)
}

internal_clear_if_uninitialized_single :: proc(arg: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if ! #force_inline internal_is_initialized(arg) {
		return #force_inline internal_grow(arg, _DEFAULT_DIGIT_COUNT)
	}
	return err
}

internal_clear_if_uninitialized_multi :: proc(args: ..^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	for i in args {
		if ! #force_inline internal_is_initialized(i) {
			e := #force_inline internal_grow(i, _DEFAULT_DIGIT_COUNT)
			if e != nil { err = e }
		}
	}
	return err
}
internal_clear_if_uninitialized :: proc {internal_clear_if_uninitialized_single, internal_clear_if_uninitialized_multi, }

internal_error_if_immutable_single :: proc(arg: ^Int) -> (err: Error) {
	if arg != nil && .Immutable in arg.flags { return .Assignment_To_Immutable }
	return nil
}

internal_error_if_immutable_multi :: proc(args: ..^Int) -> (err: Error) {
	for i in args {
		if i != nil && .Immutable in i.flags { return .Assignment_To_Immutable }
	}
	return nil
}
internal_error_if_immutable :: proc {internal_error_if_immutable_single, internal_error_if_immutable_multi, }

/*
	Allocates several `Int`s at once.
*/
internal_int_init_multi :: proc(integers: ..^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	integers := integers
	for a in integers {
		internal_clear(a) or_return
	}
	return nil
}

internal_init_multi :: proc { internal_int_init_multi, }

/*
	Trim unused digits.

	This is used to ensure that leading zero digits are trimmed and the leading "used" digit will be non-zero.
	Typically very fast.  Also fixes the sign if there are no more leading digits.
*/
internal_clamp :: proc(a: ^Int) -> (err: Error) {
	for a.used > 0 && a.digit[a.used - 1] == 0 { a.used -= 1 }

	if #force_inline internal_is_zero(a) { a.sign = .Zero_or_Positive }

	return nil
}


internal_int_zero_unused :: #force_inline proc(dest: ^Int, old_used := -1) {
	/*
		If we don't pass the number of previously used DIGITs, we zero all remaining ones.
	*/
	zero_count: int
	if old_used == -1 {
		zero_count = len(dest.digit) - dest.used
	} else {
		zero_count = old_used - dest.used
	}

	/*
		Zero remainder.
	*/
	if zero_count > 0 && dest.used < len(dest.digit) {
		mem.zero_slice(dest.digit[dest.used:][:zero_count])
	}
}
internal_zero_unused :: proc { internal_int_zero_unused, }

/*
	==========================    End of low-level routines   ==========================
*/
