package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add`, `sub`, `mul`, `div`, ...
*/

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
	if n < 0 || n > FACTORIAL_MAX_N { return .Invalid_Argument; }
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
	if n < 0 || n > FACTORIAL_MAX_N { return .Invalid_Argument; }

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

	return #force_inline internal_int_gcd_lcm(res_gcd, res_lcm, a, b);
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
	remainder = numerator % (1 << bits)
*/
int_mod_bits :: proc(remainder, numerator: ^Int, bits: int) -> (err: Error) {
	if remainder == nil || numerator == nil { return .Invalid_Pointer; }
	if err = clear_if_uninitialized(remainder, numerator); err != nil { return err; }
	if bits  < 0 { return .Invalid_Argument; }

	return #force_inline internal_int_mod_bits(remainder, numerator, bits);
}

mod_bits :: proc { int_mod_bits, };