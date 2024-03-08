/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	=============================    Private procedures    =============================

	Private procedures used by the above low-level routines follow.

	Don't call these yourself unless you really know what you're doing.
	They include implementations that are optimimal for certain ranges of input only.

	These aren't exported for the same reasons.
*/


package math_big

import "base:intrinsics"
import "core:mem"

/*
	Multiplies |a| * |b| and only computes upto digs digits of result.
	HAC pp. 595, Algorithm 14.12  Modified so you can control how
	many digits of output are created.
*/
_private_int_mul :: proc(dest, a, b: ^Int, digits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Can we use the fast multiplier?
	*/
	if digits < _WARRAY && min(a.used, b.used) < _MAX_COMBA {
		return #force_inline _private_int_mul_comba(dest, a, b, digits)
	}

	/*
		Set up temporary output `Int`, which we'll swap for `dest` when done.
	*/

	t := &Int{}

	internal_grow(t, max(digits, _DEFAULT_DIGIT_COUNT)) or_return
	t.used = digits

	/*
		Compute the digits of the product directly.
	*/
	pa := a.used
	for ix := 0; ix < pa; ix += 1 {
		/*
			Limit ourselves to `digits` DIGITs of output.
		*/
		pb    := min(b.used, digits - ix)
		carry := _WORD(0)
		iy    := 0

		/*
			Compute the column of the output and propagate the carry.
		*/
		#no_bounds_check for iy = 0; iy < pb; iy += 1 {
			/*
				Compute the column as a _WORD.
			*/
			column := _WORD(t.digit[ix + iy]) + _WORD(a.digit[ix]) * _WORD(b.digit[iy]) + carry

			/*
				The new column is the lower part of the result.
			*/
			t.digit[ix + iy] = DIGIT(column & _WORD(_MASK))

			/*
				Get the carry word from the result.
			*/
			carry = column >> _DIGIT_BITS
		}
		/*
			Set carry if it is placed below digits
		*/
		if ix + iy < digits {
			t.digit[ix + pb] = DIGIT(carry)
		}
	}

	internal_swap(dest, t)
	internal_destroy(t)
	return internal_clamp(dest)
}


/*
	Multiplication using the Toom-Cook 3-way algorithm.

	Much more complicated than Karatsuba but has a lower asymptotic running time of O(N**1.464).
	This algorithm is only particularly useful on VERY large inputs.
	(We're talking 1000s of digits here...).

	This file contains code from J. Arndt's book  "Matters Computational"
	and the accompanying FXT-library with permission of the author.

	Setup from:
		Chung, Jaewook, and M. Anwar Hasan. "Asymmetric squaring formulae."
		18th IEEE Symposium on Computer Arithmetic (ARITH'07). IEEE, 2007.

	The interpolation from above needed one temporary variable more than the interpolation here:

		Bodrato, Marco, and Alberto Zanoni. "What about Toom-Cook matrices optimality."
		Centro Vito Volterra Universita di Roma Tor Vergata (2006)
*/
_private_int_mul_toom :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	S1, S2, T1, a0, a1, a2, b0, b1, b2 := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(S1, S2, T1, a0, a1, a2, b0, b1, b2)

	/*
		Init temps.
	*/
	internal_init_multi(S1, S2, T1)             or_return

	/*
		B
	*/
	B := min(a.used, b.used) / 3

	/*
		a = a2 * x^2 + a1 * x + a0;
	*/
	internal_grow(a0, B)                        or_return
	internal_grow(a1, B)                        or_return
	internal_grow(a2, a.used - 2 * B)           or_return

	a0.used, a1.used = B, B
	a2.used = a.used - 2 * B

	internal_copy_digits(a0, a, a0.used)        or_return
	internal_copy_digits(a1, a, a1.used, B)     or_return
	internal_copy_digits(a2, a, a2.used, 2 * B) or_return

	internal_clamp(a0)
	internal_clamp(a1)
	internal_clamp(a2)

	/*
		b = b2 * x^2 + b1 * x + b0;
	*/
	internal_grow(b0, B)                        or_return
	internal_grow(b1, B)                        or_return
	internal_grow(b2, b.used - 2 * B)           or_return

	b0.used, b1.used = B, B
	b2.used = b.used - 2 * B

	internal_copy_digits(b0, b, b0.used)        or_return
	internal_copy_digits(b1, b, b1.used, B)     or_return
	internal_copy_digits(b2, b, b2.used, 2 * B) or_return

	internal_clamp(b0)
	internal_clamp(b1)
	internal_clamp(b2)


	/*
		\\ S1 = (a2+a1+a0) * (b2+b1+b0);
	*/
	internal_add(T1, a2, a1)                    or_return /*   T1 = a2 + a1; */
	internal_add(S2, T1, a0)                    or_return /*   S2 = T1 + a0; */
	internal_add(dest, b2, b1)                  or_return /* dest = b2 + b1; */
	internal_add(S1, dest, b0)                  or_return /*   S1 =  c + b0; */
	internal_mul(S1, S1, S2)                    or_return /*   S1 = S1 * S2; */

	/*
		\\S2 = (4*a2+2*a1+a0) * (4*b2+2*b1+b0);
	*/
	internal_add(T1, T1, a2)                    or_return /*   T1 = T1 + a2; */
	internal_int_shl1(T1, T1)                   or_return /*   T1 = T1 << 1; */
	internal_add(T1, T1, a0)                    or_return /*   T1 = T1 + a0; */
	internal_add(dest, dest, b2)                or_return /*    c =  c + b2; */
	internal_int_shl1(dest, dest)               or_return /*    c =  c << 1; */
	internal_add(dest, dest, b0)                or_return /*    c =  c + b0; */
	internal_mul(S2, T1, dest)                  or_return /*   S2 = T1 *  c; */

	/*
		\\S3 = (a2-a1+a0) * (b2-b1+b0);
	*/
	internal_sub(a1, a2, a1)                    or_return /*   a1 = a2 - a1; */
	internal_add(a1, a1, a0)                    or_return /*   a1 = a1 + a0; */
	internal_sub(b1, b2, b1)                    or_return /*   b1 = b2 - b1; */
	internal_add(b1, b1, b0)                    or_return /*   b1 = b1 + b0; */
	internal_mul(a1, a1, b1)                    or_return /*   a1 = a1 * b1; */
	internal_mul(b1, a2, b2)                    or_return /*   b1 = a2 * b2; */

	/*
		\\S2 = (S2 - S3) / 3;
	*/
	internal_sub(S2, S2, a1)                    or_return /*   S2 = S2 - a1; */
	_private_int_div_3(S2, S2)                  or_return /*   S2 = S2 / 3; \\ this is an exact division  */
	internal_sub(a1, S1, a1)                    or_return /*   a1 = S1 - a1; */
	internal_int_shr1(a1, a1)                   or_return /*   a1 = a1 >> 1; */
	internal_mul(a0, a0, b0)                    or_return /*   a0 = a0 * b0; */
	internal_sub(S1, S1, a0)                    or_return /*   S1 = S1 - a0; */
	internal_sub(S2, S2, S1)                    or_return /*   S2 = S2 - S1; */
	internal_int_shr1(S2, S2)                   or_return /*   S2 = S2 >> 1; */
	internal_sub(S1, S1, a1)                    or_return /*   S1 = S1 - a1; */
	internal_sub(S1, S1, b1)                    or_return /*   S1 = S1 - b1; */
	internal_int_shl1(T1, b1)                   or_return /*   T1 = b1 << 1; */
	internal_sub(S2, S2, T1)                    or_return /*   S2 = S2 - T1; */
	internal_sub(a1, a1, S2)                    or_return /*   a1 = a1 - S2; */

	/*
		P = b1*x^4+ S2*x^3+ S1*x^2+ a1*x + a0;
	*/
	_private_int_shl_leg(b1, 4 * B)             or_return
	_private_int_shl_leg(S2, 3 * B)             or_return
	internal_add(b1, b1, S2)                    or_return
	_private_int_shl_leg(S1, 2 * B)             or_return
	internal_add(b1, b1, S1)                    or_return
	_private_int_shl_leg(a1, 1 * B)             or_return
	internal_add(b1, b1, a1)                    or_return
	internal_add(dest, b1, a0)                  or_return

	/*
		a * b - P
	*/
	return nil
}

/*
	product = |a| * |b| using Karatsuba Multiplication using three half size multiplications.

	Let `B` represent the radix [e.g. 2**_DIGIT_BITS] and let `n` represent
	half of the number of digits in the min(a,b)

	`a` = `a1` * `B`**`n` + `a0`
	`b` = `b`1 * `B`**`n` + `b0`

	Then, a * b => 1b1 * B**2n + ((a1 + a0)(b1 + b0) - (a0b0 + a1b1)) * B + a0b0

	Note that a1b1 and a0b0 are used twice and only need to be computed once.
	So in total three half size (half # of digit) multiplications are performed,
		a0b0, a1b1 and (a1+b1)(a0+b0)

	Note that a multiplication of half the digits requires 1/4th the number of
	single precision multiplications, so in total after one call 25% of the
	single precision multiplications are saved.

	Note also that the call to `internal_mul` can end up back in this function
	if the a0, a1, b0, or b1 are above the threshold.

	This is known as divide-and-conquer and leads to the famous O(N**lg(3)) or O(N**1.584)
	work which is asymptopically lower than the standard O(N**2) that the
	baseline/comba methods use. Generally though, the overhead of this method doesn't pay off
	until a certain size is reached, of around 80 used DIGITs.
*/
_private_int_mul_karatsuba :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	x0, x1, y0, y1, t1, x0y0, x1y1 := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(x0, x1, y0, y1, t1, x0y0, x1y1)

	/*
		min # of digits, divided by two.
	*/
	B := min(a.used, b.used) >> 1

	/*
		Init all the temps.
	*/
	internal_grow(x0, B)          or_return
	internal_grow(x1, a.used - B) or_return
	internal_grow(y0, B)          or_return
	internal_grow(y1, b.used - B) or_return
	internal_grow(t1, B * 2)      or_return
	internal_grow(x0y0, B * 2)    or_return
	internal_grow(x1y1, B * 2)    or_return

	/*
		Now shift the digits.
	*/
	x0.used, y0.used = B, B
	x1.used = a.used - B
	y1.used = b.used - B

	/*
		We copy the digits directly instead of using higher level functions
		since we also need to shift the digits.
	*/
	internal_copy_digits(x0, a, x0.used)
	internal_copy_digits(y0, b, y0.used)
	internal_copy_digits(x1, a, x1.used, B)
	internal_copy_digits(y1, b, y1.used, B)

	/*
		Only need to clamp the lower words since by definition the
		upper words x1/y1 must have a known number of digits.
	*/
	clamp(x0)
	clamp(y0)

	/*
		Now calc the products x0y0 and x1y1,
		after this x0 is no longer required, free temp [x0==t2]!
	*/
	internal_mul(x0y0, x0, y0)      or_return /* x0y0 = x0*y0 */
	internal_mul(x1y1, x1, y1)      or_return /* x1y1 = x1*y1 */
	internal_add(t1,   x1, x0)      or_return /* now calc x1+x0 and */
	internal_add(x0,   y1, y0)      or_return /* t2 = y1 + y0 */
	internal_mul(t1,   t1, x0)      or_return /* t1 = (x1 + x0) * (y1 + y0) */

	/*
		Add x0y0.
	*/
	internal_add(x0, x0y0, x1y1)    or_return /* t2 = x0y0 + x1y1 */
	internal_sub(t1,   t1,   x0)    or_return /* t1 = (x1+x0)*(y1+y0) - (x1y1 + x0y0) */

	/*
		shift by B.
	*/
	_private_int_shl_leg(t1, B)       or_return /* t1 = (x0y0 + x1y1 - (x1-x0)*(y1-y0))<<B */
	_private_int_shl_leg(x1y1, B * 2) or_return /* x1y1 = x1y1 << 2*B */

	internal_add(t1, x0y0, t1)      or_return /* t1 = x0y0 + t1 */
	internal_add(dest, t1, x1y1)    or_return /* t1 = x0y0 + t1 + x1y1 */

	return nil
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
_private_int_mul_comba :: proc(dest, a, b: ^Int, digits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Set up array.
	*/
	W: [_WARRAY]DIGIT = ---

	/*
		Grow the destination as required.
	*/
	internal_grow(dest, digits) or_return

	/*
		Number of output digits to produce.
	*/
	pa := min(digits, a.used + b.used)

	/*
		Clear the carry
	*/
	_W := _WORD(0)

	ix: int
	for ix = 0; ix < pa; ix += 1 {
		tx, ty, iy, iz: int

		/*
			Get offsets into the two bignums.
		*/
		ty = min(b.used - 1, ix)
		tx = ix - ty

		/*
			This is the number of times the loop will iterate, essentially.
			while (tx++ < a->used && ty-- >= 0) { ... }
		*/
		 
		iy = min(a.used - tx, ty + 1)

		/*
			Execute loop.
		*/
		#no_bounds_check for iz = 0; iz < iy; iz += 1 {
			_W += _WORD(a.digit[tx + iz]) * _WORD(b.digit[ty - iz])
		}

		/*
			Store term.
		*/
		W[ix] = DIGIT(_W) & _MASK

		/*
			Make next carry.
		*/
		_W = _W >> _WORD(_DIGIT_BITS)
	}

	/*
		Setup dest.
	*/
	old_used := dest.used
	dest.used = pa

	/*
		Now extract the previous digit [below the carry].
	*/
	copy_slice(dest.digit[0:], W[:pa])	

	/*
		Clear unused digits [that existed in the old copy of dest].
	*/
	internal_zero_unused(dest, old_used)

	/*
		Adjust dest.used based on leading zeroes.
	*/

	return internal_clamp(dest)
}

/*
	Multiplies |a| * |b| and does not compute the lower digs digits
	[meant to get the higher part of the product]
*/
_private_int_mul_high :: proc(dest, a, b: ^Int, digits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Can we use the fast multiplier?
	*/
	if a.used + b.used + 1 < _WARRAY && min(a.used, b.used) < _MAX_COMBA {
		return _private_int_mul_high_comba(dest, a, b, digits)
	}

	internal_grow(dest, a.used + b.used + 1) or_return
	dest.used = a.used + b.used + 1

	pa := a.used
	pb := b.used
	for ix := 0; ix < pa; ix += 1 {
		carry := DIGIT(0)

		for iy := digits - ix; iy < pb; iy += 1 {
			/*
				Calculate the double precision result.
			*/
			r := _WORD(dest.digit[ix + iy]) + _WORD(a.digit[ix]) * _WORD(b.digit[iy]) + _WORD(carry)

			/*
				Get the lower part.
			*/
			dest.digit[ix + iy] = DIGIT(r & _WORD(_MASK))

			/*
				Carry the carry.
			*/
			carry = DIGIT(r >> _WORD(_DIGIT_BITS))
		}
		dest.digit[ix + pb] = carry
	}
	return internal_clamp(dest)
}

/*
	This is a modified version of `_private_int_mul_comba` that only produces output digits *above* `digits`.
	See the comments for `_private_int_mul_comba` to see how it works.

	This is used in the Barrett reduction since for one of the multiplications
	only the higher digits were needed.  This essentially halves the work.

	Based on Algorithm 14.12 on pp.595 of HAC.
*/
_private_int_mul_high_comba :: proc(dest, a, b: ^Int, digits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	W: [_WARRAY]DIGIT = ---
	_W: _WORD = 0

	/*
		Number of output digits to produce. Grow the destination as required.
	*/
	pa := a.used + b.used
	internal_grow(dest, pa) or_return

	ix: int
	for ix = digits; ix < pa; ix += 1 {
		/*
			Get offsets into the two bignums.
		*/
		ty := min(b.used - 1, ix)
		tx := ix - ty

		/*
			This is the number of times the loop will iterrate, essentially it's
			while (tx++ < a->used && ty-- >= 0) { ... }
		*/
		iy := min(a.used - tx, ty + 1)

		/*
			Execute loop.
		*/
		for iz := 0; iz < iy; iz += 1 {
			_W += _WORD(a.digit[tx + iz]) * _WORD(b.digit[ty - iz])
		}

		/*
			Store term.
		*/
		W[ix] = DIGIT(_W) & DIGIT(_MASK)

		/*
			Make next carry.
		*/
		_W = _W >> _WORD(_DIGIT_BITS)
	}

	/*
		Setup dest
	*/
	old_used := dest.used
	dest.used = pa

	for ix = digits; ix < pa; ix += 1 {
		/*
			Now extract the previous digit [below the carry].
		*/
		dest.digit[ix] = W[ix]
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

/*
	Single-digit multiplication with the smaller number as the single-digit.
*/
_private_int_mul_balance :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	a, b := a, b

	a0, tmp, r := &Int{}, &Int{}, &Int{}
	defer internal_destroy(a0, tmp, r)

	b_size   := min(a.used, b.used)
	n_blocks := max(a.used, b.used) / b_size

	internal_grow(a0, b_size + 2) or_return
	internal_init_multi(tmp, r)   or_return

	/*
		Make sure that `a` is the larger one.
	*/
	if a.used < b.used {
		a, b = b, a
	}
	assert(a.used >= b.used)

	i, j := 0, 0
	for ; i < n_blocks; i += 1 {
		/*
			Cut a slice off of `a`.
		*/

		a0.used = b_size
		internal_copy_digits(a0, a, a0.used, j)
		j += a0.used
		internal_clamp(a0)

		/*
			Multiply with `b`.
		*/
		internal_mul(tmp, a0, b)                                     or_return

		/*
			Shift `tmp` to the correct position.
		*/
		_private_int_shl_leg(tmp, b_size * i)                          or_return

		/*
			Add to output. No carry needed.
		*/
		internal_add(r, r, tmp)                                      or_return
	}

	/*
		The left-overs; there are always left-overs.
	*/
	if j < a.used {
		a0.used = a.used - j
		internal_copy_digits(a0, a, a0.used, j)
		j += a0.used
		internal_clamp(a0)

		internal_mul(tmp, a0, b)                                     or_return
		_private_int_shl_leg(tmp, b_size * i)                          or_return
		internal_add(r, r, tmp)                                      or_return
	}

	internal_swap(dest, r)
	return
}

/*
	Low level squaring, b = a*a, HAC pp.596-597, Algorithm 14.16
	Assumes `dest` and `src` to not be `nil`, and `src` to have been initialized.
*/
_private_int_sqr :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	pa := src.used

	t := &Int{}; ix, iy: int
	/*
		Grow `t` to maximum needed size, or `_DEFAULT_DIGIT_COUNT`, whichever is bigger.
	*/
	internal_grow(t, max((2 * pa) + 1, _DEFAULT_DIGIT_COUNT)) or_return
	t.used = (2 * pa) + 1

	#no_bounds_check for ix = 0; ix < pa; ix += 1 {
		carry := DIGIT(0)
		/*
			First calculate the digit at 2*ix; calculate double precision result.
		*/
		r := _WORD(t.digit[ix+ix]) + (_WORD(src.digit[ix]) * _WORD(src.digit[ix]))

		/*
			Store lower part in result.
		*/
		t.digit[ix+ix] = DIGIT(r & _WORD(_MASK))
		/*
			Get the carry.
		*/
		carry = DIGIT(r >> _DIGIT_BITS)

		#no_bounds_check for iy = ix + 1; iy < pa; iy += 1 {
			/*
				First calculate the product.
			*/
			r = _WORD(src.digit[ix]) * _WORD(src.digit[iy])

			/* Now calculate the double precision result. Nóte we use
			 * addition instead of *2 since it's easier to optimize
			 */
			r = _WORD(t.digit[ix+iy]) + r + r + _WORD(carry)

			/*
				Store lower part.
			*/
			t.digit[ix+iy] = DIGIT(r & _WORD(_MASK))

			/*
				Get carry.
			*/
			carry = DIGIT(r >> _DIGIT_BITS)
		}
		/*
			Propagate upwards.
		*/
		#no_bounds_check for carry != 0 {
			r     = _WORD(t.digit[ix+iy]) + _WORD(carry)
			t.digit[ix+iy] = DIGIT(r & _WORD(_MASK))
			carry = DIGIT(r >> _WORD(_DIGIT_BITS))
			iy += 1
		}
	}

	err = internal_clamp(t)
	internal_swap(dest, t)
	internal_destroy(t)
	return err
}

/*
	The jist of squaring...
	You do like mult except the offset of the tmpx [one that starts closer to zero] can't equal the offset of tmpy.
	So basically you set up iy like before then you min it with (ty-tx) so that it never happens.
	You double all those you add in the inner loop. After that loop you do the squares and add them in.

	Assumes `dest` and `src` not to be `nil` and `src` to have been initialized.	
*/
_private_int_sqr_comba :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	W: [_WARRAY]DIGIT = ---

	/*
		Grow the destination as required.
	*/
	pa := uint(src.used) + uint(src.used)
	internal_grow(dest, int(pa)) or_return

	/*
		Number of output digits to produce.
	*/
	W1 := _WORD(0)
	_W  : _WORD = ---
	ix := uint(0)

	#no_bounds_check for ; ix < pa; ix += 1 {
		/*
			Clear counter.
		*/
		_W = {}

		/*
			Get offsets into the two bignums.
		*/
		ty := min(uint(src.used) - 1, ix)
		tx := ix - ty

		/*
			This is the number of times the loop will iterate,
			essentially while (tx++ < a->used && ty-- >= 0) { ... }
		*/
		iy := min(uint(src.used) - tx, ty + 1)

		/*
			Now for squaring, tx can never equal ty.
			We halve the distance since they approach at a rate of 2x,
			and we have to round because odd cases need to be executed.
		*/
		iy = min(iy, ((ty - tx) + 1) >> 1 )

		/*
			Execute loop.
		*/
		#no_bounds_check for iz := uint(0); iz < iy; iz += 1 {
			_W += _WORD(src.digit[tx + iz]) * _WORD(src.digit[ty - iz])
		}

		/*
			Double the inner product and add carry.
		*/
		_W = _W + _W + W1

		/*
			Even columns have the square term in them.
		*/
		if ix & 1 == 0 {
			_W += _WORD(src.digit[ix >> 1]) * _WORD(src.digit[ix >> 1])
		}

		/*
			Store it.
		*/
		W[ix] = DIGIT(_W & _WORD(_MASK))

		/*
			Make next carry.
		*/
		W1 = _W >> _DIGIT_BITS
	}

	/*
		Setup dest.
	*/
	old_used := dest.used
	dest.used = src.used + src.used

	#no_bounds_check for ix = 0; ix < pa; ix += 1 {
		dest.digit[ix] = W[ix] & _MASK
	}

	/*
		Clear unused digits [that existed in the old copy of dest].
	*/
	internal_zero_unused(dest, old_used)

	return internal_clamp(dest)
}

/*
	Karatsuba squaring, computes `dest` = `src` * `src` using three half-size squarings.
 
 	See comments of `_private_int_mul_karatsuba` for details.
 	It is essentially the same algorithm but merely tuned to perform recursive squarings.
*/
_private_int_sqr_karatsuba :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	x0, x1, t1, t2, x0x0, x1x1 := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(x0, x1, t1, t2, x0x0, x1x1)

	/*
		Min # of digits, divided by two.
	*/
	B := src.used >> 1

	/*
		Init temps.
	*/
	internal_grow(x0,   B) or_return
	internal_grow(x1,   src.used - B) or_return
	internal_grow(t1,   src.used * 2) or_return
	internal_grow(t2,   src.used * 2) or_return
	internal_grow(x0x0, B * 2       ) or_return
	internal_grow(x1x1, (src.used - B) * 2) or_return

	/*
		Now shift the digits.
	*/
	x0.used = B
	x1.used = src.used - B

	#force_inline internal_copy_digits(x0, src, x0.used)
	#force_inline mem.copy_non_overlapping(&x1.digit[0], &src.digit[B], size_of(DIGIT) * x1.used)
	#force_inline internal_clamp(x0)

	/*
		Now calc the products x0*x0 and x1*x1.
	*/
	internal_sqr(x0x0, x0) or_return
	internal_sqr(x1x1, x1) or_return

	/*
		Now calc (x1+x0)^2
	*/
	internal_add(t1, x0, x1) or_return
	internal_sqr(t1, t1) or_return

	/*
		Add x0y0
	*/
	internal_add(t2, x0x0, x1x1) or_return
	internal_sub(t1, t1, t2) or_return

	/*
		Shift by B.
	*/
	_private_int_shl_leg(t1, B) or_return
	_private_int_shl_leg(x1x1, B * 2) or_return
	internal_add(t1, t1, x0x0) or_return
	internal_add(dest, t1, x1x1) or_return

	return #force_inline internal_clamp(dest)
}

/*
	Squaring using Toom-Cook 3-way algorithm.

	Setup and interpolation from algorithm SQR_3 in Chung, Jaewook, and M. Anwar Hasan. "Asymmetric squaring formulae."
	  18th IEEE Symposium on Computer Arithmetic (ARITH'07). IEEE, 2007.
*/
_private_int_sqr_toom :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	S0, a0, a1, a2 := &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(S0, a0, a1, a2)

	/*
		Init temps.
	*/
	internal_zero(S0) or_return

	/*
		B
	*/
	B := src.used / 3

	/*
		a = a2 * x^2 + a1 * x + a0;
	*/
	internal_grow(a0, B) or_return
	internal_grow(a1, B) or_return
	internal_grow(a2, src.used - (2 * B)) or_return

	a0.used = B
	a1.used = B
	a2.used = src.used - 2 * B

	#force_inline mem.copy_non_overlapping(&a0.digit[0], &src.digit[    0], size_of(DIGIT) * a0.used)
	#force_inline mem.copy_non_overlapping(&a1.digit[0], &src.digit[    B], size_of(DIGIT) * a1.used)
	#force_inline mem.copy_non_overlapping(&a2.digit[0], &src.digit[2 * B], size_of(DIGIT) * a2.used)

	internal_clamp(a0)
	internal_clamp(a1)
	internal_clamp(a2)

	/** S0 = a0^2;  */
	internal_sqr(S0, a0) or_return

	/** \\S1 = (a2 + a1 + a0)^2 */
	/** \\S2 = (a2 - a1 + a0)^2  */
	/** \\S1 = a0 + a2; */
	/** a0 = a0 + a2; */
	internal_add(a0, a0, a2) or_return
	/** \\S2 = S1 - a1; */
	/** b = a0 - a1; */
	internal_sub(dest, a0, a1) or_return
	/** \\S1 = S1 + a1; */
	/** a0 = a0 + a1; */
	internal_add(a0, a0, a1) or_return
	/** \\S1 = S1^2;  */
	/** a0 = a0^2; */
	internal_sqr(a0, a0) or_return
	/** \\S2 = S2^2;  */
	/** b = b^2; */
	internal_sqr(dest, dest) or_return
	/** \\ S3 = 2 * a1 * a2  */
	/** \\S3 = a1 * a2;  */
	/** a1 = a1 * a2; */
	internal_mul(a1, a1, a2) or_return
	/** \\S3 = S3 << 1;  */
	/** a1 = a1 << 1; */
	internal_shl(a1, a1, 1) or_return
	/** \\S4 = a2^2;  */
	/** a2 = a2^2; */
	internal_sqr(a2, a2) or_return
	/** \\ tmp = (S1 + S2)/2  */
	/** \\tmp = S1 + S2; */
	/** b = a0 + b; */
	internal_add(dest, a0, dest) or_return
	/** \\tmp = tmp >> 1; */
	/** b = b >> 1; */
	internal_shr(dest, dest, 1) or_return
	/** \\ S1 = S1 - tmp - S3  */
	/** \\S1 = S1 - tmp; */
	/** a0 = a0 - b; */
	internal_sub(a0, a0, dest) or_return
	/** \\S1 = S1 - S3;  */
	/** a0 = a0 - a1; */
	internal_sub(a0, a0, a1) or_return
	/** \\S2 = tmp - S4 -S0  */
	/** \\S2 = tmp - S4;  */
	/** b = b - a2; */
	internal_sub(dest, dest, a2) or_return
	/** \\S2 = S2 - S0;  */
	/** b = b - S0; */
	internal_sub(dest, dest, S0) or_return
	/** \\P = S4*x^4 + S3*x^3 + S2*x^2 + S1*x + S0; */
	/** P = a2*x^4 + a1*x^3 + b*x^2 + a0*x + S0; */
	_private_int_shl_leg(  a2, 4 * B) or_return
	_private_int_shl_leg(  a1, 3 * B) or_return
	_private_int_shl_leg(dest, 2 * B) or_return
	_private_int_shl_leg(  a0, 1 * B) or_return

	internal_add(a2, a2, a1) or_return
	internal_add(dest, dest, a2) or_return
	internal_add(dest, dest, a0) or_return
	internal_add(dest, dest, S0) or_return
	/** a^2 - P  */

	return #force_inline internal_clamp(dest)
}

/*
	Divide by three (based on routine from MPI and the GMP manual).
*/
_private_int_div_3 :: proc(quotient, numerator: ^Int, allocator := context.allocator) -> (remainder: DIGIT, err: Error) {
	context.allocator = allocator

	/*
		b = 2^_DIGIT_BITS / 3
	*/
 	b := _WORD(1) << _WORD(_DIGIT_BITS) / _WORD(3)

	q := &Int{}
	internal_grow(q, numerator.used) or_return
	q.used = numerator.used
	q.sign = numerator.sign

	w, t: _WORD
	#no_bounds_check for ix := numerator.used; ix >= 0; ix -= 1 {
		w = (w << _WORD(_DIGIT_BITS)) | _WORD(numerator.digit[ix])
		if w >= 3 {
			/*
				Multiply w by [1/3].
			*/
			t = (w * b) >> _WORD(_DIGIT_BITS)

			/*
				Now subtract 3 * [w/3] from w, to get the remainder.
			*/
			w -= t+t+t

			/*
				Fixup the remainder as required since the optimization is not exact.
			*/
			for w >= 3 {
				t += 1
				w -= 3
			}
		} else {
			t = 0
		}
		q.digit[ix] = DIGIT(t)
	}
	remainder = DIGIT(w)

	/*
		[optional] store the quotient.
	*/
	if quotient != nil {
		err = clamp(q)
 		internal_swap(q, quotient)
 	}
	internal_destroy(q)
	return remainder, nil
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
_private_int_div_school :: proc(quotient, remainder, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	error_if_immutable(quotient, remainder) or_return

	q, x, y, t1, t2 := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(q, x, y, t1, t2)

	internal_grow(q, numerator.used + 2) or_return
	q.used = numerator.used + 2

	internal_init_multi(t1, t2) or_return
	internal_copy(x, numerator) or_return
	internal_copy(y, denominator) or_return

	/*
		Fix the sign.
	*/
	neg   := numerator.sign != denominator.sign
	x.sign = .Zero_or_Positive
	y.sign = .Zero_or_Positive

	/*
		Normalize both x and y, ensure that y >= b/2, [b == 2**MP_DIGIT_BIT]
	*/
	norm := internal_count_bits(y) % _DIGIT_BITS

	if norm < _DIGIT_BITS - 1 {
		norm = (_DIGIT_BITS - 1) - norm
		internal_shl(x, x, norm) or_return
		internal_shl(y, y, norm) or_return
	} else {
		norm = 0
	}

	/*
		Note: HAC does 0 based, so if used==5 then it's 0,1,2,3,4, i.e. use 4
	*/
	n := x.used - 1
	t := y.used - 1

	/*
		while (x >= y*b**n-t) do { q[n-t] += 1; x -= y*b**{n-t} }
		y = y*b**{n-t}
	*/

	_private_int_shl_leg(y, n - t) or_return

	gte := internal_gte(x, y)
	for gte {
		q.digit[n - t] += 1
		internal_sub(x, x, y) or_return
		gte = internal_gte(x, y)
	}

	/*
		Reset y by shifting it back down.
	*/
	_private_int_shr_leg(y, n - t)

	/*
		Step 3. for i from n down to (t + 1).
	*/
	#no_bounds_check for i := n; i >= (t + 1); i -= 1 {
		if i > x.used { continue }

		/*
			step 3.1 if xi == yt then set q{i-t-1} to b-1, otherwise set q{i-t-1} to (xi*b + x{i-1})/yt
		*/
		if x.digit[i] == y.digit[t] {
			q.digit[(i - t) - 1] = 1 << (_DIGIT_BITS - 1)
		} else {

			tmp := _WORD(x.digit[i]) << _DIGIT_BITS
			tmp |= _WORD(x.digit[i - 1])
			tmp /= _WORD(y.digit[t])
			if tmp > _WORD(_MASK) {
				tmp = _WORD(_MASK)
			}
			q.digit[(i - t) - 1] = DIGIT(tmp & _WORD(_MASK))
		}

		/* while (q{i-t-1} * (yt * b + y{t-1})) >
					xi * b**2 + xi-1 * b + xi-2

			do q{i-t-1} -= 1;
		*/

		iter := 0

		q.digit[(i - t) - 1] = (q.digit[(i - t) - 1] + 1) & _MASK
		#no_bounds_check for {
			q.digit[(i - t) - 1] = (q.digit[(i - t) - 1] - 1) & _MASK

			/*
				Find left hand.
			*/
			internal_zero(t1)
			t1.digit[0] = ((t - 1) < 0) ? 0 : y.digit[t - 1]
			t1.digit[1] = y.digit[t]
			t1.used = 2
			internal_mul(t1, t1, q.digit[(i - t) - 1]) or_return

			/*
				Find right hand.
			*/
			t2.digit[0] = ((i - 2) < 0) ? 0 : x.digit[i - 2]
			t2.digit[1] = x.digit[i - 1] /* i >= 1 always holds */
			t2.digit[2] = x.digit[i]
			t2.used = 3

			if internal_lte(t1, t2) {
				break
			}
			iter += 1; if iter > 100 {
				return .Max_Iterations_Reached
			}
		}

		/*
			Step 3.3 x = x - q{i-t-1} * y * b**{i-t-1}
		*/
		int_mul_digit(t1, y, q.digit[(i - t) - 1]) or_return
		_private_int_shl_leg(t1, (i - t) - 1) or_return
		internal_sub(x, x, t1) or_return

		/*
			if x < 0 then { x = x + y*b**{i-t-1}; q{i-t-1} -= 1; }
		*/
		if x.sign == .Negative {
			internal_copy(t1, y) or_return
			_private_int_shl_leg(t1, (i - t) - 1) or_return
			internal_add(x, x, t1) or_return

			q.digit[(i - t) - 1] = (q.digit[(i - t) - 1] - 1) & _MASK
		}
	}

	/*
		Now q is the quotient and x is the remainder, [which we have to normalize]
		Get sign before writing to c.
	*/
	z, _ := is_zero(x)
	x.sign = .Zero_or_Positive if z else numerator.sign

	if quotient != nil {
		internal_clamp(q)
		internal_swap(q, quotient)
		quotient.sign = .Negative if neg else .Zero_or_Positive
	}

	if remainder != nil {
		internal_shr(x, x, norm) or_return
		internal_swap(x, remainder)
	}

	return nil
}

/*
	Direct implementation of algorithms 1.8 "RecursiveDivRem" and 1.9 "UnbalancedDivision" from:

		Brent, Richard P., and Paul Zimmermann. "Modern computer arithmetic"
		Vol. 18. Cambridge University Press, 2010
		Available online at https://arxiv.org/pdf/1004.4710

	pages 19ff. in the above online document.
*/
_private_div_recursion :: proc(quotient, remainder, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	A1, A2, B1, B0, Q1, Q0, R1, R0, t := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(A1, A2, B1, B0, Q1, Q0, R1, R0, t)

	m := a.used - b.used
	k := m / 2

	if m < MUL_KARATSUBA_CUTOFF {
		return _private_int_div_school(quotient, remainder, a, b)
	}

	internal_init_multi(A1, A2, B1, B0, Q1, Q0, R1, R0, t) or_return

	/*
		`B1` = `b` / `beta`^`k`, `B0` = `b` % `beta`^`k`
	*/
	internal_shrmod(B1, B0, b, k * _DIGIT_BITS) or_return

	/*
		(Q1, R1) =  RecursiveDivRem(A / beta^(2k), B1)
	*/
	internal_shrmod(A1, t, a, 2 * k * _DIGIT_BITS) or_return
	_private_div_recursion(Q1, R1, A1, B1) or_return

	/*
		A1 = (R1 * beta^(2k)) + (A % beta^(2k)) - (Q1 * B0 * beta^k)
	*/
	_private_int_shl_leg(R1, 2 * k) or_return
	internal_add(A1, R1, t) or_return
	internal_mul(t, Q1, B0) or_return

	/*
		While A1 < 0 do Q1 = Q1 - 1, A1 = A1 + (beta^k * B)
	*/
	if internal_lt(A1, 0) {
		internal_shl(t, b, k * _DIGIT_BITS) or_return

		for {
			internal_decr(Q1) or_return
			internal_add(A1, A1, t) or_return
			if internal_gte(A1, 0) { break }
		}
	}

	/*
		(Q0, R0) =  RecursiveDivRem(A1 / beta^(k), B1)
	*/
	internal_shrmod(A1, t, A1, k * _DIGIT_BITS) or_return
	_private_div_recursion(Q0, R0, A1, B1) or_return

	/*
		A2 = (R0*beta^k) +  (A1 % beta^k) - (Q0*B0)
	*/
	_private_int_shl_leg(R0, k) or_return
	internal_add(A2, R0, t) or_return
	internal_mul(t, Q0, B0) or_return
	internal_sub(A2, A2, t) or_return

	/*
		While A2 < 0 do Q0 = Q0 - 1, A2 = A2 + B.
	*/
	for internal_is_negative(A2) { // internal_lt(A2, 0) {
		internal_decr(Q0) or_return
		internal_add(A2, A2, b) or_return
	}

	/*
		Return q = (Q1*beta^k) + Q0, r = A2.
	*/
	_private_int_shl_leg(Q1, k) or_return
	internal_add(quotient, Q1, Q0) or_return

	return internal_copy(remainder, A2)
}

_private_int_div_recursive :: proc(quotient, remainder, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	A, B, Q, Q1, R, A_div, A_mod := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(A, B, Q, Q1, R, A_div, A_mod)

	internal_init_multi(A, B, Q, Q1, R, A_div, A_mod) or_return

	/*
		Most significant bit of a limb.
		Assumes  _DIGIT_MAX < (sizeof(DIGIT) * sizeof(u8)).
	*/
	msb := (_DIGIT_MAX + DIGIT(1)) >> 1
	sigma := 0
	msb_b := b.digit[b.used - 1]
	for msb_b < msb {
		sigma += 1
		msb_b <<= 1
	}

	/*
		Use that sigma to normalize B.
	*/
	internal_shl(B, b, sigma) or_return
	internal_shl(A, a, sigma) or_return

	/*
		Fix the sign.
	*/
	neg := a.sign != b.sign
	A.sign = .Zero_or_Positive; B.sign = .Zero_or_Positive

	/*
		If the magnitude of "A" is not more more than twice that of "B" we can work
		on them directly, otherwise we need to work at "A" in chunks.
	*/
	n := B.used
	m := A.used - B.used

	/*
		Q = 0. We already ensured that when we called `internal_init_multi`.
	*/
	for m > n {
		/*
			(q, r) = RecursiveDivRem(A / (beta^(m-n)), B)
		*/
		j := (m - n) * _DIGIT_BITS
		internal_shrmod(A_div, A_mod, A, j) or_return
		_private_div_recursion(Q1, R, A_div, B) or_return

		/*
			Q = (Q*beta!(n)) + q
		*/
		internal_shl(Q, Q, n * _DIGIT_BITS) or_return
		internal_add(Q, Q, Q1) or_return

		/*
			A = (r * beta^(m-n)) + (A % beta^(m-n))
		*/
		internal_shl(R, R, (m - n) * _DIGIT_BITS) or_return
		internal_add(A, R, A_mod) or_return

		/*
			m = m - n
		*/
		m -= n
	}

	/*
		(q, r) = RecursiveDivRem(A, B)
	*/
	_private_div_recursion(Q1, R, A, B) or_return

	/*
		Q = (Q * beta^m) + q, R = r
	*/
	internal_shl(Q, Q, m * _DIGIT_BITS) or_return
	internal_add(Q, Q, Q1) or_return

	/*
		Get sign before writing to dest.
	*/
	R.sign = .Zero_or_Positive if internal_is_zero(Q) else a.sign

	if quotient != nil {
		swap(quotient, Q)
		quotient.sign = .Negative if neg else .Zero_or_Positive
	}
	if remainder != nil {
		/*
			De-normalize the remainder.
		*/
		internal_shrmod(R, nil, R, sigma) or_return
		swap(remainder, R)
	}
	return nil
}

/*
	Slower bit-bang division... also smaller.
*/
@(deprecated="Use `_int_div_school`, it's 3.5x faster.")
_private_int_div_small :: proc(quotient, remainder, numerator, denominator: ^Int) -> (err: Error) {

	ta, tb, tq, q := &Int{}, &Int{}, &Int{}, &Int{}

	defer internal_destroy(ta, tb, tq, q)

	for {
		internal_one(tq) or_return

		num_bits, _ := count_bits(numerator)
		den_bits, _ := count_bits(denominator)
		n := num_bits - den_bits

		abs(ta, numerator)   or_return
		abs(tb, denominator) or_return
		shl(tb, tb, n)       or_return
		shl(tq, tq, n)       or_return

		for n >= 0 {
			if internal_gte(ta, tb) {
				// ta -= tb
				sub(ta, ta, tb) or_return
				//  q += tq
				add( q, q,  tq) or_return
			}
			shr1(tb, tb) or_return
			shr1(tq, tq) or_return

			n -= 1
		}

		/*
			Now q == quotient and ta == remainder.
		*/
		neg := numerator.sign != denominator.sign
		if quotient != nil {
			swap(quotient, q)
			z, _ := is_zero(quotient)
			quotient.sign = .Negative if neg && !z else .Zero_or_Positive
		}
		if remainder != nil {
			swap(remainder, ta)
			z, _ := is_zero(numerator)
			remainder.sign = .Zero_or_Positive if z else numerator.sign
		}

		break
	}
	return err
}



/*
	Binary split factorial algo due to: http://www.luschny.de/math/factorial/binarysplitfact.html
*/
_private_int_factorial_binary_split :: proc(res: ^Int, n: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	inner, outer, start, stop, temp := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(inner, outer, start, stop, temp)

	internal_one(inner, false)                                       or_return
	internal_one(outer, false)                                       or_return

	bits_used := ilog2(n)

	for i := bits_used; i >= 0; i -= 1 {
		start := (n >> (uint(i) + 1)) + 1 | 1
		stop  := (n >> uint(i)) + 1 | 1
		_private_int_recursive_product(temp, start, stop, 0)         or_return
		internal_mul(inner, inner, temp)                             or_return
		internal_mul(outer, outer, inner)                            or_return
	}
	shift := n - intrinsics.count_ones(n)

	return internal_shl(res, outer, int(shift))
}

/*
	Recursive product used by binary split factorial algorithm.
*/
_private_int_recursive_product :: proc(res: ^Int, start, stop: int, level := int(0), allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	t1, t2 := &Int{}, &Int{}
	defer internal_destroy(t1, t2)

	if level > FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS {
		return .Max_Iterations_Reached
	}

	num_factors := (stop - start) >> 1
	if num_factors == 2 {
		internal_set(t1, start, false)                               or_return
		when true {
			internal_grow(t2, t1.used + 1, false)                    or_return
			internal_add(t2, t1, 2)                                  or_return
		} else {
			internal_add(t2, t1, 2)                                  or_return
		}
		return internal_mul(res, t1, t2)
	}

	if num_factors > 1 {
		mid := (start + num_factors) | 1
		_private_int_recursive_product(t1, start,  mid, level + 1)   or_return
		_private_int_recursive_product(t2,   mid, stop, level + 1)   or_return
		return internal_mul(res, t1, t2)
	}

	if num_factors == 1 {
		return #force_inline internal_set(res, start, true)
	}

	return #force_inline internal_one(res, true)
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
_private_int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if res_gcd == nil && res_lcm == nil {
		return nil
	}

	/*
		We need a temporary because `res_gcd` is allowed to be `nil`.
	*/
	if a.used == 0 && b.used == 0 {
		/*
			GCD(0, 0) and LCM(0, 0) are both 0.
		*/
		if res_gcd != nil {
			internal_zero(res_gcd) or_return
		}
		if res_lcm != nil {
			internal_zero(res_lcm) or_return
		}
		return nil
	} else if a.used == 0 {
		/*
			We can early out with GCD = B and LCM = 0
		*/
		if res_gcd != nil {
			internal_abs(res_gcd, b) or_return
		}
		if res_lcm != nil {
			internal_zero(res_lcm) or_return
		}
		return nil
	} else if b.used == 0 {
		/*
			We can early out with GCD = A and LCM = 0
		*/
		if res_gcd != nil {
			internal_abs(res_gcd, a) or_return
		}
		if res_lcm != nil {
			internal_zero(res_lcm) or_return
		}
		return nil
	}

	temp_gcd_res := &Int{}
	defer internal_destroy(temp_gcd_res)

	/*
		If neither `a` or `b` was zero, we need to compute `gcd`.
 		Get copies of `a` and `b` we can modify.
 	*/
	u, v := &Int{}, &Int{}
	defer internal_destroy(u, v)
	internal_copy(u, a) or_return
	internal_copy(v, b) or_return

 	/*
 		Must be positive for the remainder of the algorithm.
 	*/
	u.sign = .Zero_or_Positive; v.sign = .Zero_or_Positive

 	/*
 		B1.  Find the common power of two for `u` and `v`.
 	*/
 	u_lsb, _ := internal_count_lsb(u)
 	v_lsb, _ := internal_count_lsb(v)
 	k        := min(u_lsb, v_lsb)

	if k > 0 {
		/*
			Divide the power of two out.
		*/
		internal_shr(u, u, k) or_return
		internal_shr(v, v, k) or_return
	}

	/*
		Divide any remaining factors of two out.
	*/
	if u_lsb != k {
		internal_shr(u, u, u_lsb - k) or_return
	}
	if v_lsb != k {
		internal_shr(v, v, v_lsb - k) or_return
	}

	for v.used != 0 {
		/*
			Make sure `v` is the largest.
		*/
		if internal_gt(u, v) {
			/*
				Swap `u` and `v` to make sure `v` is >= `u`.
			*/
			internal_swap(u, v)
		}

		/*
			Subtract smallest from largest.
		*/
		internal_sub(v, v, u) or_return

		/*
			Divide out all factors of two.
		*/
		b, _ := internal_count_lsb(v)
		internal_shr(v, v, b) or_return
	}

 	/*
 		Multiply by 2**k which we divided out at the beginning.
 	*/
 	internal_shl(temp_gcd_res, u, k) or_return
 	temp_gcd_res.sign = .Zero_or_Positive

	/*
		We've computed `gcd`, either the long way, or because one of the inputs was zero.
		If we don't want `lcm`, we're done.
	*/
	if res_lcm == nil {
		internal_swap(temp_gcd_res, res_gcd)
		return nil
	}

	/*
		Computes least common multiple as `|a*b|/gcd(a,b)`
		Divide the smallest by the GCD.
	*/
	if internal_lt_abs(a, b) {
		/*
			Store quotient in `t2` such that `t2 * b` is the LCM.
		*/
		internal_div(res_lcm, a, temp_gcd_res) or_return
		err = internal_mul(res_lcm, res_lcm, b)
	} else {
		/*
			Store quotient in `t2` such that `t2 * a` is the LCM.
		*/
		internal_div(res_lcm, b, temp_gcd_res) or_return
		err = internal_mul(res_lcm, res_lcm, a)
	}

	if res_gcd != nil {
		internal_swap(temp_gcd_res, res_gcd)
	}

	/*
		Fix the sign to positive and return.
	*/
	res_lcm.sign = .Zero_or_Positive
	return err
}

/*
	Internal implementation of log.
	Assumes `a` not to be `nil` and to have been initialized.
*/
_private_int_log :: proc(a: ^Int, base: DIGIT, allocator := context.allocator) -> (res: int, err: Error) {
	bracket_low, bracket_high, bracket_mid, t, bi_base := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(bracket_low, bracket_high, bracket_mid, t, bi_base)

	ic := #force_inline internal_cmp(a, base)
	if ic == -1 || ic == 0 {
		return 1 if ic == 0 else 0, nil
	}
	defer if err != nil {
		res = -1
	}

	internal_set(bi_base, base, true, allocator)       or_return
	internal_clear(bracket_mid, false, allocator)      or_return
	internal_clear(t, false, allocator)                or_return
	internal_one(bracket_low, false, allocator)        or_return
	internal_set(bracket_high, base, false, allocator) or_return

	low := 0; high := 1

	/*
		A kind of Giant-step/baby-step algorithm.
		Idea shamelessly stolen from https://programmingpraxis.com/2010/05/07/integer-logarithms/2/
		The effect is asymptotic, hence needs benchmarks to test if the Giant-step should be skipped
		for small n.
	*/

	for {
		/*
			Iterate until `a` is bracketed between low + high.
		*/
		if #force_inline internal_gte(bracket_high, a) { break }

		low = high
		#force_inline internal_copy(bracket_low, bracket_high) or_return
		high <<= 1
		#force_inline internal_sqr(bracket_high, bracket_high) or_return
	}

	for (high - low) > 1 {
		mid := (high + low) >> 1

		#force_inline internal_pow(t, bi_base, mid - low) or_return

		#force_inline internal_mul(bracket_mid, bracket_low, t) or_return

		mc := #force_inline internal_cmp(a, bracket_mid)
		switch mc {
		case -1:
			high = mid
			internal_swap(bracket_mid, bracket_high)
		case  0:
			return mid, nil
		case  1:
			low = mid
			internal_swap(bracket_mid, bracket_low)
		}
	}

	fc := #force_inline internal_cmp(bracket_high, a)
	res = high if fc == 0 else low

	return
}

/*
	Computes xR**-1 == x (mod N) via Montgomery Reduction.
	This is an optimized implementation of `internal_montgomery_reduce`
	which uses the comba method to quickly calculate the columns of the reduction.
	Based on Algorithm 14.32 on pp.601 of HAC.
*/
_private_montgomery_reduce_comba :: proc(x, n: ^Int, rho: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	W: [_WARRAY]_WORD = ---

	if x.used > _WARRAY { return .Invalid_Argument }

	/*
		Get old used count.
	*/
	old_used := x.used

	/*
		Grow `x` as required.
	*/
	internal_grow(x, n.used + 1)                                     or_return

	/*
		First we have to get the digits of the input into an array of double precision words W[...]
		Copy the digits of `x` into W[0..`x.used` - 1]
	*/
	ix: int
	for ix = 0; ix < x.used; ix += 1 {
		W[ix] = _WORD(x.digit[ix])
	}

	/*
		Zero the high words of W[a->used..m->used*2].
	*/
	zero_upper := (n.used * 2) + 1
	if ix < zero_upper {
		for ix = x.used; ix < zero_upper; ix += 1 {
			W[ix] = {}
		}
	}

	/*
		Now we proceed to zero successive digits from the least significant upwards.
	*/
	for ix = 0; ix < n.used; ix += 1 {
		/*
			`mu = ai * m' mod b`

			We avoid a double precision multiplication (which isn't required)
			by casting the value down to a DIGIT.  Note this requires
			that W[ix-1] have the carry cleared (see after the inner loop)
		*/
		mu := ((W[ix] & _WORD(_MASK)) * _WORD(rho)) & _WORD(_MASK)

		/*
			`a = a + mu * m * b**i`
		
			This is computed in place and on the fly.  The multiplication
		 	by b**i is handled by offseting which columns the results
		 	are added to.
		
			Note the comba method normally doesn't handle carries in the
			inner loop In this case we fix the carry from the previous
			column since the Montgomery reduction requires digits of the
			result (so far) [see above] to work.

			This is	handled by fixing up one carry after the inner loop.
			The carry fixups are done in order so after these loops the
			first m->used words of W[] have the carries fixed.
		*/
		for iy := 0; iy < n.used; iy += 1 {
			W[ix + iy] += mu * _WORD(n.digit[iy])
		}

		/*
			Now fix carry for next digit, W[ix+1].
		*/
		W[ix + 1] += (W[ix] >> _DIGIT_BITS)
	}

	/*
		Now we have to propagate the carries and shift the words downward
		[all those least significant digits we zeroed].
	*/

	for ; ix < n.used * 2; ix += 1 {
		W[ix + 1] += (W[ix] >> _DIGIT_BITS)
	}

	/* copy out, A = A/b**n
	 *
	 * The result is A/b**n but instead of converting from an
	 * array of mp_word to mp_digit than calling mp_rshd
	 * we just copy them in the right order
	 */

	for ix = 0; ix < (n.used + 1); ix += 1 {
		x.digit[ix] = DIGIT(W[n.used + ix] & _WORD(_MASK))
	}

	/*
		Set the max used.
	*/
	x.used = n.used + 1

	/*
		Zero old_used digits, if the input a was larger than m->used+1 we'll have to clear the digits.
	*/
	internal_zero_unused(x, old_used)
	internal_clamp(x)

	/*
		if A >= m then A = A - m
	*/
	if internal_gte_abs(x, n) {
		return internal_sub(x, x, n)
	}
	return nil
}

/*
	Computes xR**-1 == x (mod N) via Montgomery Reduction.
	Assumes `x` and `n` not to be nil.
*/
_private_int_montgomery_reduce :: proc(x, n: ^Int, rho: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	/*
		Can the fast reduction [comba] method be used?
		Note that unlike in mul, you're safely allowed *less* than the available columns [255 per default],
		since carries are fixed up in the inner loop.
	*/
	internal_clear_if_uninitialized(x, n) or_return

	digs := (n.used * 2) + 1
	if digs < _WARRAY && x.used <= _WARRAY && n.used < _MAX_COMBA {
		return _private_montgomery_reduce_comba(x, n, rho)
	}

	/*
		Grow the input as required
	*/
	internal_grow(x, digs)                                           or_return
	x.used = digs

	for ix := 0; ix < n.used; ix += 1 {
		/*
			`mu = ai * rho mod b`
			The value of rho must be precalculated via `int_montgomery_setup()`,
			such that it equals -1/n0 mod b this allows the following inner loop
			to reduce the input one digit at a time.
		*/

		mu := DIGIT((_WORD(x.digit[ix]) * _WORD(rho)) & _WORD(_MASK))

		/*
			a = a + mu * m * b**i
			Multiply and add in place.
		*/
		u  := DIGIT(0)
		iy := int(0)
		for ; iy < n.used; iy += 1 {
			/*
				Compute product and sum.
			*/
			r := (_WORD(mu) * _WORD(n.digit[iy]) + _WORD(u) + _WORD(x.digit[ix + iy]))

			/*
				Get carry.
			*/
			u = DIGIT(r >> _DIGIT_BITS)

			/*
				Fix digit.
			*/
			x.digit[ix + iy] = DIGIT(r & _WORD(_MASK))
		}

		/*
			At this point the ix'th digit of x should be zero.
			Propagate carries upwards as required.
		*/
		for u != 0 {
			x.digit[ix + iy] += u
			u = x.digit[ix + iy] >> _DIGIT_BITS
			x.digit[ix + iy] &= _MASK
			iy += 1
		}
	}

	/*
		At this point the n.used'th least significant digits of x are all zero,
		which means we can shift x to the right by n.used digits and the
		residue is unchanged.

		x = x/b**n.used.
	*/
	internal_clamp(x)
	_private_int_shr_leg(x, n.used)

	/*
		if x >= n then x = x - n
	*/
	if internal_gte_abs(x, n) {
		return internal_sub(x, x, n)
	}

	return nil
}

/*
	Shifts with subtractions when the result is greater than b.

	The method is slightly modified to shift B unconditionally upto just under
	the leading bit of b.  This saves alot of multiple precision shifting.

	Assumes `a` and `b` not to be `nil`.
*/
_private_int_montgomery_calc_normalization :: proc(a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	/*
		How many bits of last digit does b use.
	*/
	internal_clear_if_uninitialized(a, b) or_return

	bits := internal_count_bits(b) % _DIGIT_BITS

	if b.used > 1 {
		power := ((b.used - 1) * _DIGIT_BITS) + bits - 1
		internal_int_power_of_two(a, power)                          or_return
	} else {
		internal_one(a)                                              or_return
		bits = 1
	}

	/*
		Now compute C = A * B mod b.
	*/
	for x := bits - 1; x < _DIGIT_BITS; x += 1 {
		internal_int_shl1(a, a)                                      or_return
		if internal_gte_abs(a, b) {
			internal_sub(a, a, b)                                    or_return
		}
	}
	return nil
}

/*
	Sets up the Montgomery reduction stuff.
*/
_private_int_montgomery_setup :: proc(n: ^Int, allocator := context.allocator) -> (rho: DIGIT, err: Error) {
	/*
		Fast inversion mod 2**k
		Based on the fact that:

		XA = 1 (mod 2**n) => (X(2-XA)) A = 1 (mod 2**2n)
		                  =>  2*X*A - X*X*A*A = 1
		                  =>  2*(1) - (1)     = 1
	*/
	internal_clear_if_uninitialized(n, allocator) or_return

	b := n.digit[0]
	if b & 1 == 0 { return 0, .Invalid_Argument }

	x := (((b + 2) & 4) << 1) + b /* here x*a==1 mod 2**4 */
	x *= 2 - (b * x)              /* here x*a==1 mod 2**8 */
	x *= 2 - (b * x)              /* here x*a==1 mod 2**16 */

	when _DIGIT_TYPE_BITS == 64 {
		x *= 2 - (b * x)              /* here x*a==1 mod 2**32 */
		x *= 2 - (b * x)              /* here x*a==1 mod 2**64 */
	}

	/*
		rho = -1/m mod b
	*/
	rho = DIGIT(((_WORD(1) << _WORD(_DIGIT_BITS)) - _WORD(x)) & _WORD(_MASK))
	return rho, nil
}

/*
	Reduces `x` mod `m`, assumes 0 < x < m**2, mu is precomputed via reduce_setup.
	From HAC pp.604 Algorithm 14.42

	Assumes `x`, `m` and `mu` all not to be `nil` and have been initialized.
*/
_private_int_reduce :: proc(x, m, mu: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	q := &Int{}
	defer internal_destroy(q)
	um := m.used

	/*
		q = x
	*/
	internal_copy(q, x)                                              or_return

	/*
		q1 = x / b**(k-1)
	*/
	_private_int_shr_leg(q, um - 1)

	/*
		According to HAC this optimization is ok.
	*/
	if DIGIT(um) > DIGIT(1) << (_DIGIT_BITS - 1) {
		internal_mul(q, q, mu)                                       or_return
	} else {
		_private_int_mul_high(q, q, mu, um)                          or_return
	}

	/*
		q3 = q2 / b**(k+1)
	*/
	_private_int_shr_leg(q, um + 1)

	/*
		x = x mod b**(k+1), quick (no division)
	*/
	internal_int_mod_bits(x, x, _DIGIT_BITS * (um + 1))              or_return

	/*
		q = q * m mod b**(k+1), quick (no division)
	*/
	_private_int_mul(q, q, m, um + 1)                                or_return

	/*
		x = x - q
	*/
	internal_sub(x, x, q)                                            or_return

	/*
		If x < 0, add b**(k+1) to it.
	*/
	if internal_is_negative(x) {
		internal_set(q, 1)                                           or_return
		_private_int_shl_leg(q, um + 1)                                or_return
		internal_add(x, x, q)                                        or_return
	}

	/*
		Back off if it's too big.
	*/
	for internal_gte(x, m) {
		internal_sub(x, x, m)                                        or_return
	}

	return nil
}

/*
	Reduces `a` modulo `n`, where `n` is of the form 2**p - d.
*/
_private_int_reduce_2k :: proc(a, n: ^Int, d: DIGIT, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	q := &Int{}
	defer internal_destroy(q)

	internal_zero(q)                                                 or_return

	p := internal_count_bits(n)

	for {
		/*
			q = a/2**p, a = a mod 2**p
		*/
		internal_shrmod(q, a, a, p)                                  or_return

		if d != 1 {
			/*
				q = q * d
			*/
			internal_mul(q, q, d)                                    or_return
		}

		/*
			a = a + q
		*/
		internal_add(a, a, q)                                        or_return
		if internal_lt_abs(a, n)                                     { break }
		internal_sub(a, a, n)                                        or_return
	}

	return nil
}

/*
	Reduces `a` modulo `n` where `n` is of the form 2**p - d
	This differs from reduce_2k since "d" can be larger than a single digit.
*/
_private_int_reduce_2k_l :: proc(a, n, d: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	q := &Int{}
	defer internal_destroy(q)

	internal_zero(q)                                                 or_return

	p := internal_count_bits(n)

	for {
		/*
			q = a/2**p, a = a mod 2**p
		*/
		internal_shrmod(q, a, a, p)                                  or_return

		/*
			q = q * d
		*/
		internal_mul(q, q, d)                                        or_return

		/*
			a = a + q
		*/
		internal_add(a, a, q)                                        or_return
		if internal_lt_abs(a, n)                                     { break }
		internal_sub(a, a, n)                                        or_return
	}

	return nil
}

/*
	Determines if `internal_int_reduce_2k` can be used.
	Asssumes `a` not to be `nil` and to have been initialized.
*/
_private_int_reduce_is_2k :: proc(a: ^Int) -> (reducible: bool, err: Error) {
	assert_if_nil(a)

	if internal_is_zero(a) {
		return false, nil
	} else if a.used == 1 {
		return true, nil
	} else if a.used  > 1 {
		iy := internal_count_bits(a)
		iw := 1
		iz := DIGIT(1)

		/*
			Test every bit from the second digit up, must be 1.
		*/
		for ix := _DIGIT_BITS; ix < iy; ix += 1 {
			if a.digit[iw] & iz == 0 {
				return false, nil
			}

			iz <<= 1
			if iz > _DIGIT_MAX {
				iw += 1
				iz  = 1
			}
		}
		return true, nil
	} else {
		return true, nil
	}
}

/*
	Determines if `internal_int_reduce_2k_l` can be used.
	Asssumes `a` not to be `nil` and to have been initialized.
*/
_private_int_reduce_is_2k_l :: proc(a: ^Int) -> (reducible: bool, err: Error) {
	assert_if_nil(a)

	if internal_int_is_zero(a) {
		return false, nil
	} else if a.used == 1 {
		return true, nil
	} else if a.used  > 1 {
		/*
			If more than half of the digits are -1 we're sold.
		*/
		ix := 0
		iy := 0

		for ; ix < a.used; ix += 1 {
			if a.digit[ix] == _DIGIT_MAX {
				iy += 1
			}
		}
		return iy >= (a.used / 2), nil
	} else {
		return false, nil
	}
}

/*
	Determines the setup value.
	Assumes `a` is not `nil`.
*/
_private_int_reduce_2k_setup :: proc(a: ^Int, allocator := context.allocator) -> (d: DIGIT, err: Error) {
	context.allocator = allocator

	tmp := &Int{}
	defer internal_destroy(tmp)
	internal_zero(tmp)                                               or_return

	internal_int_power_of_two(tmp, internal_count_bits(a))           or_return
	internal_sub(tmp, tmp, a)                                        or_return

	return tmp.digit[0], nil
}

/*
	Determines the setup value.
	Assumes `mu` and `P` are not `nil`.

	d := (1 << a.bits) - a;
*/
_private_int_reduce_2k_setup_l :: proc(mu, P: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	tmp := &Int{}
	defer internal_destroy(tmp)
	internal_zero(tmp)                                               or_return

	internal_int_power_of_two(tmp, internal_count_bits(P))           or_return
	internal_sub(mu, tmp, P)                                         or_return

	return nil
}

/*
	Pre-calculate the value required for Barrett reduction.
	For a given modulus "P" it calulates the value required in "mu"
	Assumes `mu` and `P` are not `nil`.
*/
_private_int_reduce_setup :: proc(mu, P: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	internal_int_power_of_two(mu, P.used * 2 * _DIGIT_BITS)           or_return
	return internal_int_div(mu, mu, P)
}

/*
	Determines the setup value.
	Assumes `a` to not be `nil` and to have been initialized.
*/
_private_int_dr_setup :: proc(a: ^Int) -> (d: DIGIT) {
	/*
		The casts are required if _DIGIT_BITS is one less than
		the number of bits in a DIGIT [e.g. _DIGIT_BITS==31].
	*/
	return DIGIT((1 << _DIGIT_BITS) - a.digit[0])
}

/*
	Determines if a number is a valid DR modulus.
	Assumes `a` to not be `nil` and to have been initialized.
*/
_private_dr_is_modulus :: proc(a: ^Int) -> (res: bool) {
	/*
		Must be at least two digits.
	*/
	if a.used < 2 { return false }

	/*
		Must be of the form b**k - a [a <= b] so all but the first digit must be equal to -1 (mod b).
	*/
	for ix := 1; ix < a.used; ix += 1 {
		if a.digit[ix] != _MASK {
			return false
		}
	}
	return true
}

/*
	Reduce "x" in place modulo "n" using the Diminished Radix algorithm.
	Based on algorithm from the paper

		"Generating Efficient Primes for Discrete Log Cryptosystems"
					Chae Hoon Lim, Pil Joong Lee,
			POSTECH Information Research Laboratories

	The modulus must be of a special format [see manual].
	Has been modified to use algorithm 7.10 from the LTM book instead

	Input x must be in the range 0 <= x <= (n-1)**2
	Assumes `x` and `n` to not be `nil` and to have been initialized.
*/
_private_int_dr_reduce :: proc(x, n: ^Int, k: DIGIT, allocator := context.allocator) -> (err: Error) {
	/*
		m = digits in modulus.
	*/
	m := n.used

	/*
		Ensure that "x" has at least 2m digits.
	*/
	internal_grow(x, m + m)                                          or_return

	/*
		Top of loop, this is where the code resumes if another reduction pass is required.
	*/
	for {
		i: int
		mu := DIGIT(0)

		/*
			Compute (x mod B**m) + k * [x/B**m] inline and inplace.
		*/
		for i = 0; i < m; i += 1 {
			r         := _WORD(x.digit[i + m]) * _WORD(k) + _WORD(x.digit[i] + mu)
			x.digit[i] = DIGIT(r & _WORD(_MASK))
			mu         = DIGIT(r >> _WORD(_DIGIT_BITS))
		}

		/*
			Set final carry.
		*/
		x.digit[i] = mu

		/*
			Zero words above m.
		*/
		mem.zero_slice(x.digit[m + 1:][:x.used - m])

		/*
			Clamp, sub and return.
		*/
		internal_clamp(x)                                            or_return

		/*
			If x >= n then subtract and reduce again.
			Each successive "recursion" makes the input smaller and smaller.
		*/
		if internal_lt_abs(x, n) { break }

		internal_sub(x, x, n)                                        or_return
	}
	return nil
}

/*
	Computes res == G**X mod P.
	Assumes `res`, `G`, `X` and `P` to not be `nil` and for `G`, `X` and `P` to have been initialized.
*/
_private_int_exponent_mod :: proc(res, G, X, P: ^Int, redmode: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	M := [_TAB_SIZE]Int{}
	winsize: uint

	/*
		Use a pointer to the reduction algorithm.
		This allows us to use one of many reduction algorithms without modding the guts of the code with if statements everywhere.
	*/
	redux: #type proc(x, m, mu: ^Int, allocator := context.allocator) -> (err: Error)

	defer {
		internal_destroy(&M[1])
		for x := 1 << (winsize - 1); x < (1 << winsize); x += 1 {
			internal_destroy(&M[x])
		}
	}

	/*
		Find window size.
	*/
	x := internal_count_bits(X)
	switch {
	case x <= 7:
		winsize = 2
	case x <= 36:
		winsize = 3
	case x <= 140:
		winsize = 4
	case x <= 450:
		winsize = 5
	case x <= 1303:
		winsize = 6
	case x <= 3529:
		winsize = 7
	case:
		winsize = 8
	}

	winsize = min(_MAX_WIN_SIZE, winsize) if _MAX_WIN_SIZE > 0 else winsize

	/*
		Init M array.
		Init first cell.
	*/
	internal_zero(&M[1])                                             or_return

	/*
		Now init the second half of the array.
	*/
	for x = 1 << (winsize - 1); x < (1 << winsize); x += 1 {
		internal_zero(&M[x])                                         or_return
	}

	/*
		Create `mu`, used for Barrett reduction.
	*/
	mu := &Int{}
	defer internal_destroy(mu)
	internal_zero(mu)                                                or_return

	if redmode == 0 {
		_private_int_reduce_setup(mu, P)                             or_return
		redux = _private_int_reduce
	} else {
		_private_int_reduce_2k_setup_l(mu, P)                        or_return
		redux = _private_int_reduce_2k_l
	}

	/*
		Create M table.

		The M table contains powers of the base, e.g. M[x] = G**x mod P.
		The first half of the table is not computed, though, except for M[0] and M[1].
	*/
	internal_int_mod(&M[1], G, P)                                    or_return

	/*
		Compute the value at M[1<<(winsize-1)] by squaring M[1] (winsize-1) times.

		TODO: This can probably be replaced by computing the power and using `pow` to raise to it
		instead of repeated squaring.
	*/
	slot := 1 << (winsize - 1)
	internal_copy(&M[slot], &M[1])                                   or_return

	for x = 0; x < int(winsize - 1); x += 1 {
		/*
			Square it.
		*/
		internal_sqr(&M[slot], &M[slot])                             or_return

		/*
			Reduce modulo P
		*/
		redux(&M[slot], P, mu)                                       or_return
	}

	/*
		Create upper table, that is M[x] = M[x-1] * M[1] (mod P)
		for x = (2**(winsize - 1) + 1) to (2**winsize - 1)
	*/
	for x = slot + 1; x < (1 << winsize); x += 1 {
		internal_mul(&M[x], &M[x - 1], &M[1])                        or_return
		redux(&M[x], P, mu)                                          or_return
	}

	/*
		Setup result.
	*/
	internal_one(res)                                                or_return

	/*
		Set initial mode and bit cnt.
	*/
	mode   := 0
	bitcnt := 1
	buf    := DIGIT(0)
	digidx := X.used - 1
	bitcpy := uint(0)
	bitbuf := DIGIT(0)

	for {
		/*
			Grab next digit as required.
		*/
		bitcnt -= 1
		if bitcnt == 0 {
			/*
				If digidx == -1 we are out of digits.
			*/
			if digidx == -1 { break }

			/*
				Read next digit and reset the bitcnt.
			*/
			buf    = X.digit[digidx]
			digidx -= 1
			bitcnt = _DIGIT_BITS
		}

		/*
			Grab the next msb from the exponent.
		*/
		y := buf >> (_DIGIT_BITS - 1) & 1
		buf <<= 1

		/*
			If the bit is zero and mode == 0 then we ignore it.
			These represent the leading zero bits before the first 1 bit
			in the exponent.  Technically this opt is not required but it
			does lower the # of trivial squaring/reductions used.
		*/
		if mode == 0 && y == 0 {
			continue
		}

		/*
			If the bit is zero and mode == 1 then we square.
		*/
		if mode == 1 && y == 0 {
			internal_sqr(res, res)                                   or_return
			redux(res, P, mu)                                        or_return
			continue
		}

		/*
			Else we add it to the window.
		*/
		bitcpy += 1
		bitbuf |= (y << (winsize - bitcpy))
		mode    = 2

		if (bitcpy == winsize) {
			/*
				Window is filled so square as required and multiply.
				Square first.
			*/
			for x = 0; x < int(winsize); x += 1 {
				internal_sqr(res, res)                               or_return
				redux(res, P, mu)                                    or_return
			}

			/*
				Then multiply.
			*/
			internal_mul(res, res, &M[bitbuf])                       or_return
			redux(res, P, mu)                                        or_return

			/*
				Empty window and reset.
			*/
			bitcpy = 0
			bitbuf = 0
			mode   = 1
		}
	}

	/*
		If bits remain then square/multiply.
	*/
	if mode == 2 && bitcpy > 0 {
		/*
			Square then multiply if the bit is set.
		*/
		for x = 0; x < int(bitcpy); x += 1 {
			internal_sqr(res, res)                                   or_return
			redux(res, P, mu)                                        or_return

			bitbuf <<= 1
			if ((bitbuf & (1 << winsize)) != 0) {
				/*
					Then multiply.
				*/
				internal_mul(res, res, &M[1])                        or_return
				redux(res, P, mu)                                    or_return
			}
		}
	}
	return err
}

/*
	Computes Y == G**X mod P, HAC pp.616, Algorithm 14.85

	Uses a left-to-right `k`-ary sliding window to compute the modular exponentiation.
	The value of `k` changes based on the size of the exponent.

	Uses Montgomery or Diminished Radix reduction [whichever appropriate]

	Assumes `res`, `G`, `X` and `P` to not be `nil` and for `G`, `X` and `P` to have been initialized.
*/
_private_int_exponent_mod_fast :: proc(res, G, X, P: ^Int, redmode: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	M := [_TAB_SIZE]Int{}
	winsize: uint

	/*
		Use a pointer to the reduction algorithm.
		This allows us to use one of many reduction algorithms without modding the guts of the code with if statements everywhere.
	*/
	redux: #type proc(x, n: ^Int, rho: DIGIT, allocator := context.allocator) -> (err: Error)

	defer {
		internal_destroy(&M[1])
		for x := 1 << (winsize - 1); x < (1 << winsize); x += 1 {
			internal_destroy(&M[x])
		}
	}

	/*
		Find window size.
	*/
	x := internal_count_bits(X)
	switch {
	case x <= 7:
		winsize = 2
	case x <= 36:
		winsize = 3
	case x <= 140:
		winsize = 4
	case x <= 450:
		winsize = 5
	case x <= 1303:
		winsize = 6
	case x <= 3529:
		winsize = 7
	case:
		winsize = 8
	}

	winsize = min(_MAX_WIN_SIZE, winsize) if _MAX_WIN_SIZE > 0 else winsize

	/*
		Init M array
		Init first cell.
	*/
	cap := internal_int_allocated_cap(P)
	internal_grow(&M[1], cap)                                        or_return

	/*
		Now init the second half of the array.
	*/
	for x = 1 << (winsize - 1); x < (1 << winsize); x += 1 {
		internal_grow(&M[x], cap)                                    or_return
	}

	/*
		Determine and setup reduction code.
	*/
	rho: DIGIT

	if redmode == 0 {
		/*
			Now setup Montgomery.
		*/
		rho = _private_int_montgomery_setup(P)                       or_return

		/*
			Automatically pick the comba one if available (saves quite a few calls/ifs).
		*/
		if ((P.used * 2) + 1) < _WARRAY && P.used < _MAX_COMBA {
			redux = _private_montgomery_reduce_comba
		} else {
			/*
				Use slower baseline Montgomery method.
			*/
			redux = _private_int_montgomery_reduce
		}
	} else if redmode == 1 {
		/*
			Setup DR reduction for moduli of the form B**k - b.
		*/
		rho = _private_int_dr_setup(P)
		redux = _private_int_dr_reduce
	} else {
		/*
			Setup DR reduction for moduli of the form 2**k - b.
		*/
		rho = _private_int_reduce_2k_setup(P)                        or_return
		redux = _private_int_reduce_2k
	}

	/*
		Setup result.
	*/
	internal_grow(res, cap)                                          or_return

	/*
		Create M table
		The first half of the table is not computed, though, except for M[0] and M[1]
	*/

	if redmode == 0 {
		/*
			Now we need R mod m.
		*/
		_private_int_montgomery_calc_normalization(res, P)           or_return

		/*
			Now set M[1] to G * R mod m.
		*/
		internal_mulmod(&M[1], G, res, P)                            or_return
	} else {
		internal_one(res)                                            or_return
		internal_mod(&M[1], G, P)                                    or_return
	}

	/*
		Compute the value at M[1<<(winsize-1)] by squaring M[1] (winsize-1) times.
	*/
	slot := 1 << (winsize - 1)
	internal_copy(&M[slot], &M[1])                                   or_return

	for x = 0; x < int(winsize - 1); x += 1 {
		internal_sqr(&M[slot], &M[slot])                             or_return
		redux(&M[slot], P, rho)                                      or_return
	}

	/*
		Create upper table.
	*/
	for x = (1 << (winsize - 1)) + 1; x < (1 << winsize); x += 1 {
		internal_mul(&M[x], &M[x - 1], &M[1])                        or_return
		redux(&M[x], P, rho)                                         or_return
	}

	/*
		Set initial mode and bit cnt.
	*/
	mode   := 0
	bitcnt := 1
	buf    := DIGIT(0)
	digidx := X.used - 1
	bitcpy := 0
	bitbuf := DIGIT(0)

	for {
		/*
			Grab next digit as required.
		*/
		bitcnt -= 1
		if bitcnt == 0 {
			/*
				If digidx == -1 we are out of digits so break.
			*/
			if digidx == -1 { break }

			/*
				Read next digit and reset the bitcnt.
			*/
			buf    = X.digit[digidx]
			digidx -= 1
			bitcnt = _DIGIT_BITS
		}

		/*
			Grab the next msb from the exponent.
		*/
		y := (buf >> (_DIGIT_BITS - 1)) & 1
		buf <<= 1

		/*
			If the bit is zero and mode == 0 then we ignore it.
			These represent the leading zero bits before the first 1 bit in the exponent.
			Technically this opt is not required but it does lower the # of trivial squaring/reductions used.
		*/
		if mode == 0 && y == 0 { continue }

		/*
			If the bit is zero and mode == 1 then we square.
		*/
		if mode == 1 && y == 0 {
			internal_sqr(res, res)                                   or_return
			redux(res, P, rho)                                       or_return
			continue
		}

		/*
			Else we add it to the window.
		*/
		bitcpy += 1
		bitbuf |= (y << (winsize - uint(bitcpy)))
		mode    = 2

		if bitcpy == int(winsize) {
			/*
				Window is filled so square as required and multiply
				Square first.
			*/
			for x = 0; x < int(winsize); x += 1 {
				internal_sqr(res, res)                               or_return
				redux(res, P, rho)                                   or_return
			}

			/*
				Then multiply.
			*/
			internal_mul(res, res, &M[bitbuf])                       or_return
			redux(res, P, rho)                                       or_return

			/*
				Empty window and reset.
			*/
			bitcpy = 0
			bitbuf = 0
			mode   = 1
		}
	}

	/*
		If bits remain then square/multiply.
	*/
	if mode == 2 && bitcpy > 0 {
		/*
			Square then multiply if the bit is set.
		*/
		for x = 0; x < bitcpy; x += 1 {
			internal_sqr(res, res)                                   or_return
			redux(res, P, rho)                                       or_return

			/*
				Get next bit of the window.
			*/
			bitbuf <<= 1
			if bitbuf & (1 << winsize) != 0 {
				/*
					Then multiply.
				*/
				internal_mul(res, res, &M[1])                        or_return
				redux(res, P, rho)                                   or_return
			}
		}
	}

	if redmode == 0 {
		/*
			Fixup result if Montgomery reduction is used.
			Recall that any value in a Montgomery system is actually multiplied by R mod n.
			So we have to reduce one more time to cancel out the factor of R.
		*/
		redux(res, P, rho)                                           or_return
	}

	return nil
}

/*
	hac 14.61, pp608
*/
_private_inverse_modulo :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	x, y, u, v, A, B, C, D := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(x, y, u, v, A, B, C, D)

	// `b` cannot be negative.
	if b.sign == .Negative || internal_is_zero(b) {
		return .Invalid_Argument
	}

	// init temps.
	internal_init_multi(x, y, u, v, A, B, C, D) or_return

	// `x` = `a` % `b`, `y` = `b`
	internal_mod(x, a, b) or_return
	internal_copy(y, b) or_return

	// 2. [modified] if x,y are both even then return an error!
	if internal_is_even(x) && internal_is_even(y) {
		return .Invalid_Argument
	}

	// 3. u=x, v=y, A=1, B=0, C=0, D=1
	internal_copy(u, x) or_return
	internal_copy(v, y) or_return
	internal_one(A) or_return
	internal_one(D) or_return

	for {
		// 4.  while `u` is even do:
		for internal_is_even(u) {
			// 4.1 `u` = `u` / 2
			internal_int_shr1(u, u) or_return

			// 4.2 if `A` or `B` is odd then:
			if internal_is_odd(A) || internal_is_odd(B) {
				// `A` = (`A`+`y`) / 2, `B` = (`B`-`x`) / 2
				internal_add(A, A, y) or_return
				internal_sub(B, B, x) or_return
			}
			// `A` = `A` / 2, `B` = `B` / 2
			internal_int_shr1(A, A) or_return
			internal_int_shr1(B, B) or_return
		}

		// 5.  while `v` is even do:
		for internal_is_even(v) {
			// 5.1 `v` = `v` / 2
			internal_int_shr1(v, v) or_return

			// 5.2 if `C` or `D` is odd then:
			if internal_is_odd(C) || internal_is_odd(D) {
				// `C` = (`C`+`y`) / 2, `D` = (`D`-`x`) / 2
				internal_add(C, C, y) or_return
				internal_sub(D, D, x) or_return
			}
			// `C` = `C` / 2, `D` = `D` / 2
			internal_int_shr1(C, C) or_return
			internal_int_shr1(D, D) or_return
		}

		// 6.  if `u` >= `v` then:
		if internal_cmp(u, v) != -1 {
			// `u` = `u` - `v`, `A` = `A` - `C`, `B` = `B` - `D`
			internal_sub(u, u, v) or_return
			internal_sub(A, A, C) or_return
			internal_sub(B, B, D) or_return
		} else {
			// v - v - u, C = C - A, D = D - B
			internal_sub(v, v, u) or_return
			internal_sub(C, C, A) or_return
			internal_sub(D, D, B) or_return
		}

		// If not zero goto step 4
		if internal_is_zero(u) {
			break
		}
	}

	// Now `a` = `C`, `b` = `D`, `gcd` == `g`*`v`

	// If `v` != `1` then there is no inverse.
	if !internal_eq(v, 1) {
		return .Invalid_Argument
	}

	// If its too low.
	for internal_is_negative(C) {
		internal_add(C, C, b) or_return
	}

	// Too big.
	for internal_cmp_mag(C, b) > -1 {
		internal_sub(C, C, b) or_return
	}

	// `C` is now the inverse.
	swap(dest, C)
	return
}

/*
	Computes the modular inverse via binary extended Euclidean algorithm, that is `dest` = 1 / `a` mod `b`.

	Based on slow invmod except this is optimized for the case where `b` is odd,
	as per HAC Note 14.64 on pp. 610.
*/
_private_inverse_modulo_odd :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	x, y, u, v, B, D := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(x, y, u, v, B, D)

	sign: Sign

	/*
		2. [modified] `b` must be odd.
	*/
	if internal_is_even(b) { return .Invalid_Argument }

	/*
		Init all our temps.
	*/
	internal_init_multi(x, y, u, v, B, D) or_return

	/*
		`x` == modulus, `y` == value to invert.
	*/
	internal_copy(x, b) or_return

	/*
		We need `y` = `|a|`.
	*/
	internal_mod(y, a, b) or_return

	/*
		If one of `x`, `y` is zero return an error!
	*/
	if internal_is_zero(x) || internal_is_zero(y) { return .Invalid_Argument }

	/*
		3. `u` = `x`, `v` = `y`, `A` = 1, `B` = 0, `C` = 0, `D` = 1
	*/
	internal_copy(u, x) or_return
	internal_copy(v, y) or_return

	internal_one(D) or_return

	for {
		/*
			4.  while `u` is even do.
		*/
		for internal_is_even(u) {
			/*
				4.1 `u` = `u` / 2
			*/
			internal_int_shr1(u, u) or_return

			/*
				4.2 if `B` is odd then:
			*/
			if internal_is_odd(B) {
				/*
					`B` = (`B` - `x`) / 2
				*/
				internal_sub(B, B, x) or_return
			}

			/*
				`B` = `B` / 2
			*/
			internal_int_shr1(B, B) or_return
		}

		/*
			5.  while `v` is even do:
		*/
		for internal_is_even(v) {
			/*
				5.1 `v` = `v` / 2
			*/
			internal_int_shr1(v, v) or_return

			/*
				5.2 if `D` is odd then:
			*/
			if internal_is_odd(D) {
				/*
					`D` = (`D` - `x`) / 2
				*/
				internal_sub(D, D, x) or_return
			}
			/*
				`D` = `D` / 2
			*/
			internal_int_shr1(D, D) or_return
		}

		/*
			6.  if `u` >= `v` then:
		*/
		if internal_cmp(u, v) != -1 {
			/*
				`u` = `u` - `v`, `B` = `B` - `D`
			*/
			internal_sub(u, u, v) or_return
			internal_sub(B, B, D) or_return
		} else {
			/*
				`v` - `v` - `u`, `D` = `D` - `B`
			*/
			internal_sub(v, v, u) or_return
			internal_sub(D, D, B) or_return
		}

		/*
			If not zero goto step 4.
		*/
		if internal_is_zero(u) { break }
	}

	/*
		Now `a` = C, `b` = D, gcd == g*v
	*/

	/*
		if `v` != 1 then there is no inverse
	*/
	if internal_cmp(v, 1) != 0 {
		return .Invalid_Argument
	}

	/*
		`b` is now the inverse.
	*/
	sign = a.sign
	for internal_int_is_negative(D) {
		internal_add(D, D, b) or_return
	}

	/*
		Too big.
	*/
	for internal_gte_abs(D, b) {
		internal_sub(D, D, b) or_return
	}

	swap(dest, D)
	dest.sign = sign
	return nil
}


/*
	Returns the log2 of an `Int`.
	Assumes `a` not to be `nil` and to have been initialized.
	Also assumes `base` is a power of two.
*/
_private_log_power_of_two :: proc(a: ^Int, base: DIGIT) -> (log: int, err: Error) {
	base := base
	y: int
	for y = 0; base & 1 == 0; {
		y += 1
		base >>= 1
	}
	log = internal_count_bits(a)
	return (log - 1) / y, err
}

/*
	Copies DIGITs from `src` to `dest`.
	Assumes `src` and `dest` to not be `nil` and have been initialized.
*/
_private_copy_digits :: proc(dest, src: ^Int, digits: int, offset := int(0)) -> (err: Error) {
	digits := digits
	/*
		If dest == src, do nothing
	*/
	if dest == src {
		return nil
	}

	digits = min(digits, len(src.digit), len(dest.digit))
	mem.copy_non_overlapping(&dest.digit[0], &src.digit[offset], size_of(DIGIT) * digits)
	return nil
}


/*
	Shift left by `digits` * _DIGIT_BITS bits.
*/
_private_int_shl_leg :: proc(quotient: ^Int, digits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if digits <= 0 { return nil }

	/*
		No need to shift a zero.
	*/
	if #force_inline internal_is_zero(quotient) {
		return nil
	}

	/*
		Resize `quotient` to accomodate extra digits.
	*/
	#force_inline internal_grow(quotient, quotient.used + digits) or_return

	/*
		Increment the used by the shift amount then copy upwards.
	*/

	/*
		Much like `_private_int_shr_leg`, this is implemented using a sliding window,
		except the window goes the other way around.
	*/
	#no_bounds_check for x := quotient.used; x > 0; x -= 1 {
		quotient.digit[x+digits-1] = quotient.digit[x-1]
	}

	quotient.used += digits
	mem.zero_slice(quotient.digit[:digits])
	return nil
}

/*
	Shift right by `digits` * _DIGIT_BITS bits.
*/
_private_int_shr_leg :: proc(quotient: ^Int, digits: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if digits <= 0 { return nil }

	/*
		If digits > used simply zero and return.
	*/
	if digits > quotient.used { return internal_zero(quotient) }

	/*
		Much like `int_shl_digit`, this is implemented using a sliding window,
		except the window goes the other way around.

		b-2 | b-1 | b0 | b1 | b2 | ... | bb |   ---->
					/\                   |      ---->
					 \-------------------/      ---->
	*/

	#no_bounds_check for x := 0; x < (quotient.used - digits); x += 1 {
		quotient.digit[x] = quotient.digit[x + digits]
	}
	quotient.used -= digits
	internal_zero_unused(quotient)
	return internal_clamp(quotient)
}

/*	
	========================    End of private procedures    =======================

	===============================  Private tables  ===============================

	Tables used by `internal_*` and `_*`.
*/

_private_int_rem_128 := [?]DIGIT{
	0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
	1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
}
#assert(128 * size_of(DIGIT) == size_of(_private_int_rem_128))

_private_int_rem_105 := [?]DIGIT{
	0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
	0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1,
	0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1,
	1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1,
	0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1,
	1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1,
	1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1,
}
#assert(105 * size_of(DIGIT) == size_of(_private_int_rem_105))

_PRIME_TAB_SIZE :: 256
_private_prime_table := [_PRIME_TAB_SIZE]DIGIT{
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
}
#assert(_PRIME_TAB_SIZE * size_of(DIGIT) == size_of(_private_prime_table))

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
	}
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
	}
}

/*
	=========================  End of private tables  ========================
*/