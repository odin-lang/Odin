// Arbitrary precision integers and rationals.
package math_big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add`, `sub`, `mul`, `div`, ...
*/

import "base:intrinsics"

/*
	===========================
		User-level routines    
	===========================
*/

/*
	High-level addition. Handles sign.
*/
int_add :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, a, b) or_return
	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_add_signed(dest, a, b)
}

/*
	Adds the unsigned `DIGIT` immediate to an `Int`,
	such that the `DIGIT` doesn't have to be turned into an `Int` first.

	dest = a + digit;
*/
int_add_digit :: proc(dest, a: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return
	/*
		Grow destination as required.
	*/
	grow(dest, a.used + 1) or_return

	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_add_digit(dest, a, digit)
}

/*
	High-level subtraction, dest = number - decrease. Handles signs.
*/
int_sub :: proc(dest, number, decrease: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, number, decrease)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, number, decrease) or_return
	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_sub_signed(dest, number, decrease)
}

/*
	Adds the unsigned `DIGIT` immediate to an `Int`,
	such that the `DIGIT` doesn't have to be turned into an `Int` first.

	dest = a - digit;
*/
int_sub_digit :: proc(dest, a: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return
	/*
		Grow destination as required.
	*/
	grow(dest, a.used + 1) or_return

	/*
		All parameters have been initialized.
	*/
	return #force_inline internal_int_sub_digit(dest, a, digit)
}

/*
	dest = src  / 2
	dest = src >> 1
*/
int_halve :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, src)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, src) or_return
	/*
		Grow destination as required.
	*/
	if dest != src { grow(dest, src.used + 1) or_return }

	return #force_inline internal_int_shr1(dest, src)
}
halve :: proc { int_halve, }
shr1  :: halve

/*
	dest = src  * 2
	dest = src << 1
*/
int_double :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, src)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, src) or_return
	/*
		Grow destination as required.
	*/
	if dest != src { grow(dest, src.used + 1) or_return }

	return #force_inline internal_int_shl1(dest, src)
}
double :: proc { int_double, }
shl1   :: double

/*
	Multiply by a DIGIT.
*/
int_mul_digit :: proc(dest, src: ^Int, multiplier: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, src)
	context.allocator = allocator

	internal_clear_if_uninitialized(src, dest) or_return

	return #force_inline internal_int_mul_digit(dest, src, multiplier)
}

/*
	High level multiplication (handles sign).
*/
int_mul :: proc(dest, src, multiplier: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, src, multiplier)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, src, multiplier) or_return

	return #force_inline internal_int_mul(dest, src, multiplier)
}

mul :: proc { 
	int_mul, 
	int_mul_digit, 
	rat_mul_rat,
	rat_mul_int,
	int_mul_rat,
}

int_sqr :: proc(dest, src: ^Int) -> (err: Error) { return mul(dest, src, src) }
rat_sqr :: proc(dest, src: ^Rat) -> (err: Error) { return mul(dest, src, src) }
sqr :: proc { int_sqr, rat_sqr }


/*
	divmod.
	Both the quotient and remainder are optional and may be passed a nil.
*/
int_divmod :: proc(quotient, remainder, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Early out if neither of the results is wanted.
	*/
	if quotient == nil && remainder == nil { return nil }
	internal_clear_if_uninitialized(numerator, denominator) or_return

	return #force_inline internal_divmod(quotient, remainder, numerator, denominator)
}

int_divmod_digit :: proc(quotient, numerator: ^Int, denominator: DIGIT, allocator := context.allocator) -> (remainder: DIGIT, err: Error) {
	assert_if_nil(quotient, numerator)
	context.allocator = allocator

	internal_clear_if_uninitialized(numerator) or_return

	return #force_inline internal_divmod(quotient, numerator, denominator)
}
divmod :: proc{ int_divmod, int_divmod_digit, }

int_div :: proc(quotient, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(quotient, numerator, denominator)
	context.allocator = allocator

	internal_clear_if_uninitialized(numerator, denominator) or_return

	return #force_inline internal_divmod(quotient, nil, numerator, denominator)
}

int_div_digit :: proc(quotient, numerator: ^Int, denominator: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(quotient, numerator)
	context.allocator = allocator

	internal_clear_if_uninitialized(numerator) or_return

	_ = #force_inline internal_divmod(quotient, numerator, denominator) or_return
	return
}
div :: proc { 
	int_div, 
	int_div_digit, 
	rat_div_rat,
	rat_div_int,
	int_div_rat,
}

/*
	remainder = numerator % denominator.
	0 <= remainder < denominator if denominator > 0
	denominator < remainder <= 0 if denominator < 0
*/
int_mod :: proc(remainder, numerator, denominator: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(remainder, numerator, denominator)
	context.allocator = allocator

	internal_clear_if_uninitialized(numerator, denominator) or_return

	return #force_inline internal_int_mod(remainder, numerator, denominator)
}

int_mod_digit :: proc(numerator: ^Int, denominator: DIGIT, allocator := context.allocator) -> (remainder: DIGIT, err: Error) {
	return #force_inline internal_divmod(nil, numerator, denominator, allocator)
}

mod :: proc { int_mod, int_mod_digit, }

/*
	remainder = (number + addend) % modulus.
*/
int_addmod :: proc(remainder, number, addend, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(remainder, number, addend)
	context.allocator = allocator

	internal_clear_if_uninitialized(number, addend, modulus) or_return

	return #force_inline internal_addmod(remainder, number, addend, modulus)
}
addmod :: proc { int_addmod, }

/*
	remainder = (number - decrease) % modulus.
*/
int_submod :: proc(remainder, number, decrease, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(remainder, number, decrease)
	context.allocator = allocator

	internal_clear_if_uninitialized(number, decrease, modulus) or_return

	return #force_inline internal_submod(remainder, number, decrease, modulus)
}
submod :: proc { int_submod, }

/*
	remainder = (number * multiplicand) % modulus.
*/
int_mulmod :: proc(remainder, number, multiplicand, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(remainder, number, multiplicand)
	context.allocator = allocator

	internal_clear_if_uninitialized(number, multiplicand, modulus) or_return

	return #force_inline internal_mulmod(remainder, number, multiplicand, modulus)
}
mulmod :: proc { int_mulmod, }

/*
	remainder = (number * number) % modulus.
*/
int_sqrmod :: proc(remainder, number, modulus: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(remainder, number, modulus)
	context.allocator = allocator

	internal_clear_if_uninitialized(number, modulus) or_return

	return #force_inline internal_sqrmod(remainder, number, modulus)
}
sqrmod :: proc { int_sqrmod, }


int_factorial :: proc(res: ^Int, n: int, allocator := context.allocator) -> (err: Error) {
	if n < 0 || n > FACTORIAL_MAX_N { return .Invalid_Argument }
	assert_if_nil(res)

	return #force_inline internal_int_factorial(res, n, allocator)
}
factorial :: proc { int_factorial, }


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
int_choose_digit :: proc(res: ^Int, n, k: int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(res)
	context.allocator = allocator

	if n < 0 || n > FACTORIAL_MAX_N { return .Invalid_Argument }
	if k > n { return internal_zero(res) }

	/*
		res = n! / (k! * (n - k)!)
	*/
	n_fac, k_fac, n_minus_k_fac := &Int{}, &Int{}, &Int{}
	defer internal_destroy(n_fac, k_fac, n_minus_k_fac)

	#force_inline internal_int_factorial(n_minus_k_fac, n - k) or_return
	#force_inline internal_int_factorial(k_fac, k)             or_return
	#force_inline internal_mul(k_fac, k_fac, n_minus_k_fac)    or_return

	#force_inline internal_int_factorial(n_fac, n)             or_return
	#force_inline internal_div(res, n_fac, k_fac)              or_return

	return
}
choose :: proc { int_choose_digit, }

/*
	Function computing both GCD and (if target isn't `nil`) also LCM.
*/
int_gcd_lcm :: proc(res_gcd, res_lcm, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	if res_gcd == nil && res_lcm == nil { return nil }
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return
	return #force_inline internal_int_gcd_lcm(res_gcd, res_lcm, a, b)
}
gcd_lcm :: proc { int_gcd_lcm, }

/*
	Greatest Common Divisor.
*/
int_gcd :: proc(res, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline int_gcd_lcm(res, nil, a, b, allocator)
}
gcd :: proc { int_gcd, }

/*
	Least Common Multiple.
*/
int_lcm :: proc(res, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	return #force_inline int_gcd_lcm(nil, res, a, b, allocator)
}
lcm :: proc { int_lcm, }

/*
	remainder = numerator % (1 << bits)
*/
int_mod_bits :: proc(remainder, numerator: ^Int, bits: int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(remainder, numerator)
	context.allocator = allocator

	internal_clear_if_uninitialized(remainder, numerator) or_return
	if bits < 0 { return .Invalid_Argument }

	return #force_inline internal_int_mod_bits(remainder, numerator, bits)
}

mod_bits :: proc { int_mod_bits, }


/*
	Logs and roots and such.
*/
int_log :: proc(a: ^Int, base: DIGIT, allocator := context.allocator) -> (res: int, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_int_log(a, base)
}

digit_log :: proc(a: DIGIT, base: DIGIT) -> (log: int, err: Error) {
	return #force_inline internal_digit_log(a, base)
}
log :: proc { int_log, digit_log, }

ilog2 :: proc(value: $T) -> (log2: T) {
	return (size_of(T) * 8) - intrinsics.count_leading_zeros(value)
}

/*
	Calculate `dest = base^power` using a square-multiply algorithm.
*/
int_pow :: proc(dest, base: ^Int, power: int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, base)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, base) or_return

	return #force_inline internal_int_pow(dest, base, power)
}

/*
	Calculate `dest = base^power` using a square-multiply algorithm.
*/
int_pow_int :: proc(dest: ^Int, base, power: int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest)

	return #force_inline internal_pow(dest, base, power, allocator)
}

pow :: proc { int_pow, int_pow_int, small_pow, }
exp :: pow

small_pow :: proc(base: _WORD, exponent: _WORD) -> (result: _WORD) {
	return #force_inline internal_small_pow(base, exponent)
}

/*
	This function is less generic than `root_n`, simpler and faster.
*/
int_sqrt :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dest, src)
	context.allocator = allocator

	internal_clear_if_uninitialized(dest, src) or_return

	return #force_inline internal_int_sqrt(dest, src)
}
sqrt :: proc { int_sqrt, }


/*
	Find the nth root of an Integer.
	Result found such that `(dest)**n <= src` and `(dest+1)**n > src`

	This algorithm uses Newton's approximation `x[i+1] = x[i] - f(x[i])/f'(x[i])`,
	which will find the root in `log(n)` time where each step involves a fair bit.
*/
int_root_n :: proc(dest, src: ^Int, n: int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Fast path for n == 2.
	*/
	if n == 2 { return sqrt(dest, src) }

	assert_if_nil(dest, src)
	/*
		Initialize dest + src if needed.
	*/
	internal_clear_if_uninitialized(dest, src) or_return

	return #force_inline internal_int_root_n(dest, src, n)
}
root_n :: proc { int_root_n, }

/*
	Comparison routines.
*/

int_is_initialized :: proc(a: ^Int) -> bool {
	if a == nil { return false }

	return #force_inline internal_int_is_initialized(a)
}

int_is_zero :: proc(a: ^Int, allocator := context.allocator) -> (zero: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_is_zero(a), nil
}

int_is_positive :: proc(a: ^Int, allocator := context.allocator) -> (positive: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_is_positive(a), nil
}

int_is_negative :: proc(a: ^Int, allocator := context.allocator) -> (negative: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_is_negative(a), nil
}

int_is_even :: proc(a: ^Int, allocator := context.allocator) -> (even: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_is_even(a), nil
}

int_is_odd :: proc(a: ^Int, allocator := context.allocator) -> (odd: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_is_odd(a), nil
}

platform_int_is_power_of_two :: #force_inline proc(a: int) -> bool {
	return ((a) != 0) && (((a) & ((a) - 1)) == 0)
}

int_is_power_of_two :: proc(a: ^Int, allocator := context.allocator) -> (res: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_is_power_of_two(a), nil
}

/*
	Compare two `Int`s, signed.
*/
int_compare :: proc(a, b: ^Int, allocator := context.allocator) -> (comparison: int, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	return #force_inline internal_cmp(a, b), nil
}
int_cmp :: int_compare

/*
	Compare an `Int` to an unsigned number upto the size of the backing type.
*/
int_compare_digit :: proc(a: ^Int, b: DIGIT, allocator := context.allocator) -> (comparison: int, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_cmp_digit(a, b), nil
}
int_cmp_digit :: int_compare_digit

/*
	Compare the magnitude of two `Int`s, unsigned.
*/
int_compare_magnitude :: proc(a, b: ^Int, allocator := context.allocator) -> (res: int, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	return #force_inline internal_cmp_mag(a, b), nil
}
int_cmp_mag :: int_compare_magnitude


/*
	bool := a < b
*/
int_less_than :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (less_than: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp(a, b)

	return c == -1, err
}

/*
	bool := a < b
*/
int_less_than_digit :: #force_inline proc(a: ^Int, b: DIGIT, allocator := context.allocator) -> (less_than: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	c: int
	c, err = cmp(a, b)

	return c == -1, err
}

/*
	bool := |a| < |b|
    Compares the magnitudes only, ignores the sign.
*/
int_less_than_abs :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (less_than: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp_mag(a, b)

	return c == -1, err
}

less_than :: proc {
	int_less_than,
	int_less_than_digit,
}
lt :: less_than

less_than_abs :: proc {
	int_less_than_abs,
}
lt_abs :: less_than_abs


/*
	bool := a <= b
*/
int_less_than_or_equal :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (less_than_or_equal: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp(a, b)

	return c <= 0, err
}

/*
	bool := a <= b
*/
int_less_than_or_equal_digit :: #force_inline proc(a: ^Int, b: DIGIT, allocator := context.allocator) -> (less_than_or_equal: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	c: int
	c, err = cmp(a, b)

	return c <= 0, err
}

/*
	bool := |a| <= |b|
    Compares the magnitudes only, ignores the sign.
*/
int_less_than_or_equal_abs :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (less_than_or_equal: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp_mag(a, b)

	return c <= 0, err
}

less_than_or_equal :: proc {
	int_less_than_or_equal,
	int_less_than_or_equal_digit,
}
lteq :: less_than_or_equal

less_than_or_equal_abs :: proc {
	int_less_than_or_equal_abs,
}
lteq_abs :: less_than_or_equal_abs


/*
	bool := a == b
*/
int_equals :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (equals: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp(a, b)

	return c == 0, err
}

/*
	bool := a == b
*/
int_equals_digit :: #force_inline proc(a: ^Int, b: DIGIT, allocator := context.allocator) -> (equals: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	c: int
	c, err = cmp(a, b)

	return c == 0, err
}

/*
	bool := |a| == |b|
    Compares the magnitudes only, ignores the sign.
*/
int_equals_abs :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (equals: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp_mag(a, b)

	return c == 0, err
}

equals :: proc {
	int_equals,
	int_equals_digit,
}
eq :: equals

equals_abs :: proc {
	int_equals_abs,
}
eq_abs :: equals_abs


/*
	bool := a >= b
*/
int_greater_than_or_equal :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (greater_than_or_equal: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp(a, b)

	return c >= 0, err
}

/*
	bool := a >= b
*/
int_greater_than_or_equal_digit :: #force_inline proc(a: ^Int, b: DIGIT, allocator := context.allocator) -> (greater_than_or_equal: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	c: int
	c, err = cmp(a, b)

	return c >= 0, err
}

/*
	bool := |a| >= |b|
    Compares the magnitudes only, ignores the sign.
*/
int_greater_than_or_equal_abs :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (greater_than_or_equal: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp_mag(a, b)

	return c >= 0, err
}

greater_than_or_equal :: proc {
	int_greater_than_or_equal,
	int_greater_than_or_equal_digit,
}
gteq :: greater_than_or_equal

greater_than_or_equal_abs :: proc {
	int_greater_than_or_equal_abs,
}
gteq_abs :: greater_than_or_equal_abs


/*
	bool := a > b
*/
int_greater_than :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (greater_than: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp(a, b)

	return c > 0, err
}

/*
	bool := a > b
*/
int_greater_than_digit :: #force_inline proc(a: ^Int, b: DIGIT, allocator := context.allocator) -> (greater_than: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	c: int
	c, err = cmp(a, b)

	return c > 0, err
}

/*
	bool := |a| > |b|
    Compares the magnitudes only, ignores the sign.
*/
int_greater_than_abs :: #force_inline proc(a, b: ^Int, allocator := context.allocator) -> (greater_than: bool, err: Error) {
	assert_if_nil(a, b)
	context.allocator = allocator

	internal_clear_if_uninitialized(a, b) or_return

	c: int
	c, err = cmp_mag(a, b)

	return c > 0, err
}

greater_than :: proc {
	int_greater_than,
	int_greater_than_digit,
}
gt :: greater_than

greater_than_abs :: proc {
	int_greater_than_abs,
}
gt_abs :: greater_than_abs


/*
	Check if remainders are possible squares - fast exclude non-squares.

	Returns `true` if `a` is a square, `false` if not.
	Assumes `a` not to be `nil` and to have been initialized.
*/
int_is_square :: proc(a: ^Int, allocator := context.allocator) -> (square: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	return #force_inline internal_int_is_square(a)
}