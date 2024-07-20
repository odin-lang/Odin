/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file exports procedures for use with the test.py test suite.
*/
package test_core_math_big

/*
	TODO: Write tests for `internal_*` and test reusing parameters with the public implementations.
*/

import "base:runtime"
import "core:strings"
import "core:math/big"

PyRes :: struct {
	res: cstring,
	err: big.Error,
}

print_to_buffer :: proc(val: ^big.Int) -> cstring {
	context = runtime.default_context()
	r, _ := big.int_itoa_cstring(val, 16, context.allocator)
	return r
}

@export test_initialize_constants :: proc "c" () -> (res: u64) {
	context = runtime.default_context()
	_  = big.initialize_constants()

	return u64(big._DIGIT_NAILS)
}

@export test_error_string :: proc "c" (err: big.Error) -> (res: cstring) {
	context = runtime.default_context()
	es := big.Error_String
	return strings.clone_to_cstring(es[err], context.allocator)
}

@export test_add :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	aa, bb, sum := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.internal_destroy(aa, bb, sum)

	if err = big.atoi(aa, string(a), 16); err != nil { return PyRes{res=":add:atoi(a):", err=err} }
	if err = big.atoi(bb, string(b), 16); err != nil { return PyRes{res=":add:atoi(b):", err=err} }
	if bb.used == 1 {
		if err = #force_inline big.internal_add(sum, aa, bb.digit[0]); err != nil { return PyRes{res=":add:add(sum,a,b):", err=err} }	
	} else {
		if err = #force_inline big.internal_add(sum, aa, bb); err != nil { return PyRes{res=":add:add(sum,a,b):", err=err} }
	}

	r := print_to_buffer(sum)

	return PyRes{res = r, err = nil}
}

@export test_sub :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	aa, bb, sum := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.internal_destroy(aa, bb, sum)

	if err = big.atoi(aa, string(a), 16); err != nil { return PyRes{res=":sub:atoi(a):", err=err} }
	if err = big.atoi(bb, string(b), 16); err != nil { return PyRes{res=":sub:atoi(b):", err=err} }
	if bb.used == 1 {
		if err = #force_inline big.internal_sub(sum, aa, bb.digit[0]); err != nil { return PyRes{res=":sub:sub(sum,a,b):", err=err} }
	} else {
		if err = #force_inline big.internal_sub(sum, aa, bb); err != nil { return PyRes{res=":sub:sub(sum,a,b):", err=err} }
	}

	r := print_to_buffer(sum)
	if err != nil { return PyRes{res=":sub:itoa(sum):", err=err} }
	return PyRes{res = r, err = nil}
}

@export test_mul :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	aa, bb, product := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.internal_destroy(aa, bb, product)

	if err = big.atoi(aa, string(a), 16); err != nil { return PyRes{res=":mul:atoi(a):", err=err} }
	if err = big.atoi(bb, string(b), 16); err != nil { return PyRes{res=":mul:atoi(b):", err=err} }
	if err = #force_inline big.internal_mul(product, aa, bb); err != nil { return PyRes{res=":mul:mul(product,a,b):", err=err} }

	r := print_to_buffer(product)
	return PyRes{res = r, err = nil}
}

@export test_sqr :: proc "c" (a: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	aa, square := &big.Int{}, &big.Int{}
	defer big.internal_destroy(aa, square)

	if err = big.atoi(aa, string(a), 16); err != nil { return PyRes{res=":sqr:atoi(a):", err=err} }
	if err = #force_inline big.internal_sqr(square, aa); err != nil { return PyRes{res=":sqr:sqr(square,a):", err=err} }

	r := print_to_buffer(square)
	return PyRes{res = r, err = nil}
}

/*
	NOTE(Jeroen): For simplicity, we don't return the quotient and the remainder, just the quotient.
*/
@export test_div :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	aa, bb, quotient := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.internal_destroy(aa, bb, quotient)

	if err = big.atoi(aa, string(a), 16); err != nil { return PyRes{res=":div:atoi(a):", err=err} }
	if err = big.atoi(bb, string(b), 16); err != nil { return PyRes{res=":div:atoi(b):", err=err} }
	if err = #force_inline big.internal_div(quotient, aa, bb); err != nil { return PyRes{res=":div:div(quotient,a,b):", err=err} }

	r := print_to_buffer(quotient)
	return PyRes{res = r, err = nil}
}

/*
	res = log(a, base)
*/
@export test_log :: proc "c" (a: cstring, base := big.DIGIT(2)) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error
	l: int

	aa := &big.Int{}
	defer big.internal_destroy(aa)

	if err = big.atoi(aa, string(a), 16); err != nil { return PyRes{res=":log:atoi(a):", err=err} }
	if l, err = #force_inline big.internal_log(aa, base); err != nil { return PyRes{res=":log:log(a, base):", err=err} }

	#force_inline big.internal_zero(aa)
	aa.digit[0] = big.DIGIT(l)  & big._MASK
	aa.digit[1] = big.DIGIT(l) >> big._DIGIT_BITS
	aa.used = 2
	big.clamp(aa)

	r := print_to_buffer(aa)
	return PyRes{res = r, err = nil}
}

/*
	dest = base^power
*/
@export test_pow :: proc "c" (base: cstring, power := int(2)) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	dest, bb := &big.Int{}, &big.Int{}
	defer big.internal_destroy(dest, bb)

	if err = big.atoi(bb, string(base), 16); err != nil { return PyRes{res=":pow:atoi(base):", err=err} }
	if err = #force_inline big.internal_pow(dest, bb, power); err != nil { return PyRes{res=":pow:pow(dest, base, power):", err=err} }

	r := print_to_buffer(dest)
	return PyRes{res = r, err = nil}
}

/*
	dest = sqrt(src)
*/
@export test_sqrt :: proc "c" (source: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":sqrt:atoi(src):", err=err} }
	if err = #force_inline big.internal_sqrt(src, src); err != nil { return PyRes{res=":sqrt:sqrt(src):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = root_n(src, power)
*/
@export test_root_n :: proc "c" (source: cstring, power: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":root_n:atoi(src):", err=err} }
	if err = #force_inline big.internal_root_n(src, src, power); err != nil { return PyRes{res=":root_n:root_n(src):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = shr_digit(src, digits)
*/
@export test_shr_leg :: proc "c" (source: cstring, digits: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":shr_digit:atoi(src):", err=err} }
	if err = #force_inline big._private_int_shr_leg(src, digits); err != nil { return PyRes{res=":shr_digit:shr_digit(src):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = shl_digit(src, digits)
*/
@export test_shl_leg :: proc "c" (source: cstring, digits: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":shl_digit:atoi(src):", err=err} }
	if err = #force_inline big._private_int_shl_leg(src, digits); err != nil { return PyRes{res=":shl_digit:shr_digit(src):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = shr(src, bits)
*/
@export test_shr :: proc "c" (source: cstring, bits: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":shr:atoi(src):", err=err} }
	if err = #force_inline big.internal_shr(src, src, bits); err != nil { return PyRes{res=":shr:shr(src, bits):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = shr_signed(src, bits)
*/
@export test_shr_signed :: proc "c" (source: cstring, bits: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":shr_signed:atoi(src):", err=err} }
	if err = #force_inline big.internal_shr_signed(src, src, bits); err != nil { return PyRes{res=":shr_signed:shr_signed(src, bits):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = shl(src, bits)
*/
@export test_shl :: proc "c" (source: cstring, bits: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	src := &big.Int{}
	defer big.internal_destroy(src)

	if err = big.atoi(src, string(source), 16); err != nil { return PyRes{res=":shl:atoi(src):", err=err} }
	if err = #force_inline big.internal_shl(src, src, bits); err != nil { return PyRes{res=":shl:shl(src, bits):", err=err} }

	r := print_to_buffer(src)
	return PyRes{res = r, err = nil}
}

/*
	dest = factorial(n)
*/
@export test_factorial :: proc "c" (n: int) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	dest := &big.Int{}
	defer big.internal_destroy(dest)

	if err = #force_inline big.internal_int_factorial(dest, n); err != nil { return PyRes{res=":factorial:factorial(n):", err=err} }

	r := print_to_buffer(dest)
	return PyRes{res = r, err = nil}
}

/*
	dest = gcd(a, b)
*/
@export test_gcd :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	ai, bi, dest := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.internal_destroy(ai, bi, dest)

	if err = big.atoi(ai, string(a), 16); err != nil { return PyRes{res=":gcd:atoi(a):", err=err} }
	if err = big.atoi(bi, string(b), 16); err != nil { return PyRes{res=":gcd:atoi(b):", err=err} }
	if err = #force_inline big.internal_int_gcd_lcm(dest, nil, ai, bi); err != nil { return PyRes{res=":gcd:gcd(a, b):", err=err} }

	r := print_to_buffer(dest)
	return PyRes{res = r, err = nil}
}

/*
	dest = lcm(a, b)
*/
@export test_lcm :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err: big.Error

	ai, bi, dest := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.internal_destroy(ai, bi, dest)

	if err = big.atoi(ai, string(a), 16); err != nil { return PyRes{res=":lcm:atoi(a):", err=err} }
	if err = big.atoi(bi, string(b), 16); err != nil { return PyRes{res=":lcm:atoi(b):", err=err} }
	if err = #force_inline big.internal_int_gcd_lcm(nil, dest, ai, bi); err != nil { return PyRes{res=":lcm:lcm(a, b):", err=err} }

	r := print_to_buffer(dest)
	return PyRes{res = r, err = nil}
}

/*
	dest = lcm(a, b)
*/
@export test_is_square :: proc "c" (a: cstring) -> (res: PyRes) {
	context = runtime.default_context()
	err:    big.Error
	square: bool

	ai := &big.Int{}
	defer big.internal_destroy(ai)

	if err = big.atoi(ai, string(a), 16); err != nil { return PyRes{res=":is_square:atoi(a):", err=err} }
	if square, err = #force_inline big.internal_int_is_square(ai); err != nil { return PyRes{res=":is_square:is_square(a):", err=err} }

	if square {
		return PyRes{"True", nil}
	}
	return PyRes{"False", nil}
}