package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add`, `sub`, `mul`, `div`, ...
*/

import "core:mem"

/*
	===========================
		User-level routines    
	===========================
*/

/*
	High-level addition. Handles sign.
*/
int_add :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	if dest == nil || a == nil || b == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(dest, a, b); err != nil { return err; }
	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_add_signed(dest, a, b, allocator);
}

/*
	Adds the unsigned `DIGIT` immediate to an `Int`,
	such that the `DIGIT` doesn't have to be turned into an `Int` first.

	dest = a + digit;
*/
int_add_digit :: proc(dest, a: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error) {
	if dest == nil || a == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return err; }
	/*
		Grow destination as required.
	*/
	if err = grow(dest, a.used + 1, false, allocator); err != nil { return err; }

	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_add_digit(dest, a, digit);
}

/*
	High-level subtraction, dest = number - decrease. Handles signs.
*/
int_sub :: proc(dest, number, decrease: ^Int, allocator := context.allocator) -> (err: Error) {
	if dest == nil || number == nil || decrease == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(dest, number, decrease); err != nil { return err; }
	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_sub_signed(dest, number, decrease, allocator);
}

/*
	Adds the unsigned `DIGIT` immediate to an `Int`,
	such that the `DIGIT` doesn't have to be turned into an `Int` first.

	dest = a - digit;
*/
int_sub_digit :: proc(dest, a: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error) {
	if dest == nil || a == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return err; }
	/*
		Grow destination as required.
	*/
	if err = grow(dest, a.used + 1, false, allocator); err != nil { return err; }

	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_sub_digit(dest, a, digit);
}

/*
	dest = src  / 2
	dest = src >> 1
*/
int_halve :: proc(dest, src: ^Int) -> (err: Error) {
	if dest == nil || src == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(dest, src); err != nil { return err; }
	/*
		Grow destination as required.
	*/
	if dest != src { if err = grow(dest, src.used + 1); err != nil { return err; } }

	return #force_inline internal_int_shr1(dest, src);
}
halve :: proc { int_halve, };
shr1  :: halve;

/*
	dest = src  * 2
	dest = src << 1
*/
int_double :: proc(dest, src: ^Int) -> (err: Error) {
	if dest == nil || src == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(dest, src); err != nil { return err; }
	/*
		Grow destination as required.
	*/
	if dest != src { if err = grow(dest, src.used + 1); err != nil { return err; } }

	return #force_inline internal_int_shl1(dest, src);
}
double :: proc { int_double, };
shl1   :: double;

/*
	Multiply by a DIGIT.
*/
int_mul_digit :: proc(dest, src: ^Int, multiplier: DIGIT, allocator := context.allocator) -> (err: Error) {
	if dest == nil || src == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(src, dest); err != nil { return err; }

	return #force_inline internal_int_mul_digit(dest, src, multiplier, allocator);
}

/*
	High level multiplication (handles sign).
*/
int_mul :: proc(dest, src, multiplier: ^Int, allocator := context.allocator) -> (err: Error) {
	if dest == nil || src == nil || multiplier == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(dest, src, multiplier); err != nil { return err; }

	return #force_inline internal_int_mul(dest, src, multiplier, allocator);
}

mul :: proc { int_mul, int_mul_digit, };

sqr :: proc(dest, src: ^Int) -> (err: Error) { return mul(dest, src, src); }

/*
	divmod.
	Both the quotient and remainder are optional and may be passed a nil.
*/
int_divmod :: proc(quotient, remainder, numerator, denominator: ^Int) -> (err: Error) {
	/*
		Early out if neither of the results is wanted.
	*/
	if quotient == nil && remainder == nil { return nil; }
	if err = clear_if_uninitialized(numerator, denominator); err != nil { return err; }

	return #force_inline internal_divmod(quotient, remainder, numerator, denominator);
}

int_divmod_digit :: proc(quotient, numerator: ^Int, denominator: DIGIT) -> (remainder: DIGIT, err: Error) {
	if quotient == nil { return 0, .Invalid_Pointer; };
	if err = clear_if_uninitialized(numerator); err != nil { return 0, err; }

	return #force_inline internal_divmod(quotient, numerator, denominator);
}
divmod :: proc{ int_divmod, int_divmod_digit, };

int_div :: proc(quotient, numerator, denominator: ^Int) -> (err: Error) {
	if quotient == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(numerator, denominator); err != nil { return err; }

	return #force_inline internal_divmod(quotient, nil, numerator, denominator);
}

int_div_digit :: proc(quotient, numerator: ^Int, denominator: DIGIT) -> (err: Error) {
	if quotient == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(numerator); err != nil { return err; }

	remainder: DIGIT;
	remainder, err = #force_inline internal_divmod(quotient, numerator, denominator);
	return err;
}
div :: proc { int_div, int_div_digit, };

/*
	remainder = numerator % denominator.
	0 <= remainder < denominator if denominator > 0
	denominator < remainder <= 0 if denominator < 0
*/
int_mod :: proc(remainder, numerator, denominator: ^Int) -> (err: Error) {
	if remainder == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(numerator, denominator); err != nil { return err; }

	return #force_inline internal_int_mod(remainder, numerator, denominator);
}

int_mod_digit :: proc(numerator: ^Int, denominator: DIGIT) -> (remainder: DIGIT, err: Error) {
	return #force_inline internal_divmod(nil, numerator, denominator);
}

mod :: proc { int_mod, int_mod_digit, };

/*
	remainder = (number + addend) % modulus.
*/
int_addmod :: proc(remainder, number, addend, modulus: ^Int) -> (err: Error) {
	if remainder == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(number, addend, modulus); err != nil { return err; }

	return #force_inline internal_addmod(remainder, number, addend, modulus);
}
addmod :: proc { int_addmod, };

/*
	remainder = (number - decrease) % modulus.
*/
int_submod :: proc(remainder, number, decrease, modulus: ^Int) -> (err: Error) {
	if remainder == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(number, decrease, modulus); err != nil { return err; }

	return #force_inline internal_submod(remainder, number, decrease, modulus);
}
submod :: proc { int_submod, };

/*
	remainder = (number * multiplicand) % modulus.
*/
int_mulmod :: proc(remainder, number, multiplicand, modulus: ^Int) -> (err: Error) {
	if remainder == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(number, multiplicand, modulus); err != nil { return err; }

	return #force_inline internal_mulmod(remainder, number, multiplicand, modulus);
}
mulmod :: proc { int_mulmod, };

/*
	remainder = (number * number) % modulus.
*/
int_sqrmod :: proc(remainder, number, modulus: ^Int) -> (err: Error) {
	if remainder == nil { return .Invalid_Pointer; };
	if err = clear_if_uninitialized(number, modulus); err != nil { return err; }

	return #force_inline internal_sqrmod(remainder, number, modulus);
}
sqrmod :: proc { int_sqrmod, };


int_factorial :: proc(res: ^Int, n: int) -> (err: Error) {
	if n < 0 || n > _FACTORIAL_MAX_N { return .Invalid_Argument; }
	if res == nil { return .Invalid_Pointer; }

	return #force_inline internal_int_factorial(res, n);
}
factorial :: proc { int_factorial, };


/*
	Number of ways to choose `k` items from `n` items.
	Also known as the binomial coefficient.

	TODO: Speed up.

	Could be done faster by reusing code from factorial and reusing the common "prefix" results for n!, k! and n-k!
	We know that n >= k, otherwise we early out with res = 0.

	So:
		n-k, keep result
		n, start from previous result
		k, start from previous result

*/
int_choose_digit :: proc(res: ^Int, n, k: int) -> (err: Error) {
	if res == nil  { return .Invalid_Pointer; }
	if n < 0 || n > _FACTORIAL_MAX_N { return .Invalid_Argument; }

	if k > n { return zero(res); }

	/*
		res = n! / (k! * (n - k)!)
	*/
	n_fac, k_fac, n_minus_k_fac := &Int{}, &Int{}, &Int{};
	defer destroy(n_fac, k_fac, n_minus_k_fac);

	if err = #force_inline internal_int_factorial(n_minus_k_fac, n - k);  err != nil { return err; }
	if err = #force_inline internal_int_factorial(k_fac, k);              err != nil { return err; }
	if err = #force_inline internal_mul(k_fac, k_fac, n_minus_k_fac);     err != nil { return err; }

	if err = #force_inline internal_int_factorial(n_fac, n);              err != nil { return err; }
	if err = #force_inline internal_div(res, n_fac, k_fac);               err != nil { return err; }

	return err;	
}
choose :: proc { int_choose_digit, };


/*
	Low level squaring, b = a*a, HAC pp.596-597, Algorithm 14.16
*/
_int_sqr :: proc(dest, src: ^Int) -> (err: Error) {
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
_int_div_3 :: proc(quotient, numerator: ^Int) -> (remainder: DIGIT, err: Error) {
	/*
		b = 2**MP_DIGIT_BIT / 3
	*/
 	b := _WORD(1) << _WORD(_DIGIT_BITS) / _WORD(3);

	q := &Int{};
	if err = grow(q, numerator.used); err != nil { return 0, err; }
	q.used = numerator.used;
	q.sign = numerator.sign;

	w, t: _WORD;
	for ix := numerator.used; ix >= 0; ix -= 1 {
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
_int_div_school :: proc(quotient, remainder, numerator, denominator: ^Int) -> (err: Error) {
	if err = error_if_immutable(quotient, remainder); err != nil { return err; }
	if err = clear_if_uninitialized(quotient, numerator, denominator); err != nil { return err; }

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
	for i := n; i >= (t + 1); i -= 1 {
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
		for {
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
_int_div_small :: proc(quotient, remainder, numerator, denominator: ^Int) -> (err: Error) {

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
	Function computing both GCD and (if target isn't `nil`) also LCM.
*/
int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int) -> (err: Error) {
	if res_gcd == nil && res_lcm == nil { return nil; }
	if err = clear_if_uninitialized(res_gcd, res_lcm, a, b); err != nil { return err; }

	az, _ := is_zero(a); bz, _ := is_zero(b);
	if az && bz {
		if res_gcd != nil {
			if err = zero(res_gcd); err != nil { return err; }
		}
		if res_lcm != nil {
			if err = zero(res_lcm); err != nil { return err; }
		}
		return nil;
	}
	else if az {
		if res_gcd != nil {
			if err = abs(res_gcd, b); err != nil { return err; }
		}
		if res_lcm != nil {
			if err = zero(res_lcm);   err != nil { return err; }
		}
		return nil;
	}
	else if bz {
		if res_gcd != nil {
			if err = abs(res_gcd, a); err != nil { return err; }
		}
		if res_lcm != nil {
			if err = zero(res_lcm);   err != nil { return err; }
		}
		return nil;
	}

	return #force_inline _int_gcd_lcm(res_gcd, res_lcm, a, b);
}
gcd_lcm :: proc { int_gcd_lcm, };

/*
	Greatest Common Divisor.
*/
int_gcd :: proc(res, a, b: ^Int) -> (err: Error) {
	return #force_inline int_gcd_lcm(res, nil, a, b);
}
gcd :: proc { int_gcd, };

/*
	Least Common Multiple.
*/
int_lcm :: proc(res, a, b: ^Int) -> (err: Error) {
	return #force_inline int_gcd_lcm(nil, res, a, b);
}
lcm :: proc { int_lcm, };

/*
	Internal function computing both GCD using the binary method,
	and, if target isn't `nil`, also LCM.
	Expects the arguments to have been initialized.
*/
_int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int) -> (err: Error) {
	/*
		If both `a` and `b` are zero, return zero.
		If either `a` or `b`, return the other one.

		The `gcd` and `lcm` wrappers have already done this test,
		but `gcd_lcm` wouldn't have, so we still need to perform it.

		If neither result is wanted, we have nothing to do.
	*/
	if res_gcd == nil && res_lcm == nil { return nil; }

	/*
		We need a temporary because `res_gcd` is allowed to be `nil`.
	*/
	az, _ := is_zero(a); bz, _ := is_zero(b);
	if az && bz {
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
	} else if az {
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
	} else if bz {
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
		if err = sub(v, v, u); err != nil { return err; }

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
		if err = div(res_lcm, a, temp_gcd_res); err != nil { return err; }
		err = mul(res_lcm, res_lcm, b);
	} else {
		/*
			Store quotient in `t2` such that `t2 * a` is the LCM.
		*/
		if err = div(res_lcm, a, temp_gcd_res); err != nil { return err; }
		err = mul(res_lcm, res_lcm, b);
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
	remainder = numerator % (1 << bits)
*/
int_mod_bits :: proc(remainder, numerator: ^Int, bits: int) -> (err: Error) {
	if err = clear_if_uninitialized(remainder); err != nil { return err; }
	if err = clear_if_uninitialized(numerator); err != nil { return err; }

	if bits  < 0 { return .Invalid_Argument; }
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
mod_bits :: proc { int_mod_bits, };


