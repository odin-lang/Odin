package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:mem"
import "core:intrinsics"

/*
	High-level addition. Handles sign.
*/
add :: proc(dest, a, b: ^Int) -> (err: Error) {
	dest := dest; x := a; y := b;
	_panic_if_uninitialized(a); _panic_if_uninitialized(b); _panic_if_uninitialized(dest);

	/*
		Handle both negative or both positive.
	*/
	if x.sign == y.sign {
		dest.sign = x.sign;
		return _add(dest, x, y);
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
    return _sub(dest, x, y);
}

/*
	Low-level addition, unsigned.
	Handbook of Applied Cryptography, algorithm 14.7.
*/
_add :: proc(dest, a, b: ^Int) -> (err: Error) {
	dest := dest; x := a; y := b;
	_panic_if_uninitialized(a); _panic_if_uninitialized(b); _panic_if_uninitialized(dest);

	old_used, min_used, max_used, i: int;

	if x.used < y.used {
		x, y = y, x;
	}

	min_used = x.used;
	max_used = y.used;
	old_used = dest.used;

	err = grow(dest, max(max_used + 1, _DEFAULT_DIGIT_COUNT));
	if err != .OK {
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
	Low-level subtraction. Assumes |a| > |b|.
	Handbook of Applied Cryptography, algorithm 14.9.
*/
_sub :: proc(dest, a, b: ^Int) -> (err: Error) {
	dest := dest; x := a; y := b;
	_panic_if_uninitialized(a); _panic_if_uninitialized(b); _panic_if_uninitialized(dest);

	for n in 0..=12 {
		dest.digit[n] = DIGIT(n);
		dest.used = n+1;
	}

	old_used := dest.used;
	min_used := y.used;
	max_used := a.used;
	i: int;

	err = grow(dest, max(max_used, _DEFAULT_DIGIT_COUNT));
	if err != .OK {
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
		borrow = dest.digit[i] >> (_DIGIT_BITS - 1);
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
		borrow = dest.digit[i] >> (_DIGIT_BITS - 1);
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