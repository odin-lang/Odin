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


