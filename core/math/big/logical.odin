package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains logical operations like `and`, `or` and `xor`.
*/

import "core:mem"

/*
	The `and`, `or` and `xor` binops differ in two lines only.
	We could handle those with a switch, but that adds overhead.

	TODO: Implement versions that take a DIGIT immediate.
*/

/*
	2's complement `and`, returns `dest = a & b;`
*/
int_and :: proc(dest, a, b: ^Int) -> (err: Error) {
	assert_if_nil(dest, a, b);
	if err = clear_if_uninitialized(a, b); err != nil { return err; }

	used := max(a.used, b.used) + 1;
	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != nil { return err; }

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
and :: proc { int_add, };

/*
	2's complement `or`, returns `dest = a | b;`
*/
int_or :: proc(dest, a, b: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a, b); err != nil { return err; }
	used := max(a.used, b.used) + 1;
	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != nil { return err; }

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
or :: proc { int_or, };

/*
	2's complement `xor`, returns `dest = a ~ b;`
*/
int_xor :: proc(dest, a, b: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a, b); err != nil { return err; }

	used := max(a.used, b.used) + 1;
	/*
		Grow the destination to accomodate the result.
	*/
	if err = grow(dest, used); err != nil { return err; }

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
xor :: proc { int_xor, };

/*
	dest = ~src
*/
int_complement :: proc(dest, src: ^Int) -> (err: Error) {
	/*
		Check that src is usable. Dest will get checked by `sub`.
	*/
	if err = clear_if_uninitialized(src); err != nil { return err; }

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

/*
	quotient, remainder := numerator >> bits;
	`remainder` is allowed to be passed a `nil`, in which case `mod` won't be computed.
*/
int_shrmod :: proc(quotient, remainder, numerator: ^Int, bits: int) -> (err: Error) {
	bits := bits;
	if err = clear_if_uninitialized(quotient, numerator);  err != nil { return err; }

	if bits < 0 { return .Invalid_Argument; }

	if err = copy(quotient, numerator); err != nil { return err; }

	/*
		Shift right by a certain bit count (store quotient and optional remainder.)
	   `numerator` should not be used after this.
	*/
	if remainder != nil {
		if err = mod_bits(remainder, numerator, bits); err != nil { return err; }
	}

	/*
		Shift by as many digits in the bit count.
	*/
	if bits >= _DIGIT_BITS {
		if err = shr_digit(quotient, bits / _DIGIT_BITS); err != nil { return err; }
	}

	/*
		Shift any bit count < _DIGIT_BITS.
	*/
	bits %= _DIGIT_BITS;
	if bits != 0 {
		mask  := DIGIT(1 << uint(bits)) - 1;
		shift := DIGIT(_DIGIT_BITS - bits);
		carry := DIGIT(0);

		for x := quotient.used - 1; x >= 0; x -= 1 {
			/*
				Get the lower bits of this word in a temp.
			*/
			fwd_carry := quotient.digit[x] & mask;

			/*
				Shift the current word and mix in the carry bits from the previous word.
			*/
	        quotient.digit[x] = (quotient.digit[x] >> uint(bits)) | (carry << shift);

	        /*
	        	Update carry from forward carry.
	        */
	        carry = fwd_carry;
		}

	}
	return clamp(numerator);
}
shrmod :: proc { int_shrmod, };

int_shr :: proc(dest, source: ^Int, bits: int) -> (err: Error) {
	return shrmod(dest, nil, source, bits);
}
shr :: proc { int_shr, };

/*
	Shift right by `digits` * _DIGIT_BITS bits.
*/
int_shr_digit :: proc(quotient: ^Int, digits: int) -> (err: Error) {
	/*
		Check that `quotient` is usable.
	*/
	if err = clear_if_uninitialized(quotient); err != nil { return err; }

	if digits <= 0 { return nil; }

	/*
		If digits > used simply zero and return.
	*/
	if digits > quotient.used {
		return zero(quotient);
	}

   	/*
		Much like `int_shl_digit`, this is implemented using a sliding window,
		except the window goes the other way around.

		b-2 | b-1 | b0 | b1 | b2 | ... | bb |   ---->
		            /\                   |      ---->
		             \-------------------/      ---->
    */

	for x := 0; x < (quotient.used - digits); x += 1 {
    	quotient.digit[x] = quotient.digit[x + digits];
	}
	quotient.used -= digits;
	zero_unused(quotient);
	return clamp(quotient);
}
shr_digit :: proc { int_shr_digit, };

/*
	Shift right by a certain bit count with sign extension.
*/
int_shr_signed :: proc(dest, src: ^Int, bits: int) -> (err: Error) {
	if err = clear_if_uninitialized(src);	err != nil { return err; }
	if err = clear_if_uninitialized(dest);	err != nil { return err; }

	if src.sign == .Zero_or_Positive {
		return shr(dest, src, bits);
	}
	if err = add(dest, src, DIGIT(1));		err != nil { return err; }

	if err = shr(dest, dest, bits);			err != nil { return err; }
	return sub(dest, src, DIGIT(1));
}

shr_signed :: proc { int_shr_signed, };

/*
	Shift left by a certain bit count.
*/
int_shl :: proc(dest, src: ^Int, bits: int) -> (err: Error) {
	bits := bits;
	if err = clear_if_uninitialized(src, dest);  err != nil { return err; }

	if bits < 0 {
		return .Invalid_Argument;
	}

	if err = copy(dest, src); err != nil { return err; }

	/*
		Grow `dest` to accommodate the additional bits.
	*/
	digits_needed := dest.used + (bits / _DIGIT_BITS) + 1;
	if err = grow(dest, digits_needed); err != nil { return err; }
	dest.used = digits_needed;
	/*
		Shift by as many digits in the bit count as we have.
	*/
	if bits >= _DIGIT_BITS {
		if err = shl_digit(dest, bits / _DIGIT_BITS); err != nil { return err; }
	}

	/*
		Shift any remaining bit count < _DIGIT_BITS
	*/
	bits %= _DIGIT_BITS;
	if bits != 0 {
		mask  := (DIGIT(1) << uint(bits)) - DIGIT(1);
		shift := DIGIT(_DIGIT_BITS - bits);
		carry := DIGIT(0);

		for x:= 0; x < dest.used; x+= 1 {		
			fwd_carry := (dest.digit[x] >> shift) & mask;
			dest.digit[x] = (dest.digit[x] << uint(bits) | carry) & _MASK;
			carry = fwd_carry;
		}

		/*
			Use final carry.
		*/
		if carry != 0 {
			dest.digit[dest.used] = carry;
			dest.used += 1;
		}
	}
	return clamp(dest);
}
shl :: proc { int_shl, };


/*
	Shift left by `digits` * _DIGIT_BITS bits.
*/
int_shl_digit :: proc(quotient: ^Int, digits: int) -> (err: Error) {
	/*
		Check that `quotient` is usable.
	*/
	if err = clear_if_uninitialized(quotient); err != nil { return err; }

	if digits <= 0 { return nil; }

	/*
		No need to shift a zero.
	*/
	z: bool;
	if z, err = is_zero(quotient); z || err != nil { return err; }

	/*
		Resize `quotient` to accomodate extra digits.
	*/
	if err = grow(quotient, quotient.used + digits); err != nil { return err; }

	/*
		Increment the used by the shift amount then copy upwards.
	*/

	/*
		Much like `int_shr_digit`, this is implemented using a sliding window,
		except the window goes the other way around.
    */
    for x := quotient.used; x > 0; x -= 1 {
    	quotient.digit[x+digits-1] = quotient.digit[x-1];
    }

   	quotient.used += digits;
    mem.zero_slice(quotient.digit[:digits]);
    return nil;
}
shl_digit :: proc { int_shl_digit, };