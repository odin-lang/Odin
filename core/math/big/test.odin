//+ignore
package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add`, `sub`, `mul`, `div`, ...
*/

import "core:runtime"
import "core:strings"

PyRes :: struct {
	res: cstring,
	err: Error,
}

@export test_error_string :: proc "c" (err: Error) -> (res: cstring) {
	context = runtime.default_context();
	es := Error_String;
	return strings.clone_to_cstring(es[err], context.temp_allocator);
}

@export test_add :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, sum := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, sum);

	if err = atoi(aa, string(a), 16); err != .None { return PyRes{res=":add:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 16); err != .None { return PyRes{res=":add:atoi(b):", err=err}; }
	if err = add(sum, aa, bb);        err != .None { return PyRes{res=":add:add(sum,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(sum, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":add:itoa(sum):", err=err}; }
	return PyRes{res = r, err = .None};
}

@export test_sub :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, sum := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, sum);

	if err = atoi(aa, string(a), 16); err != .None { return PyRes{res=":sub:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 16); err != .None { return PyRes{res=":sub:atoi(b):", err=err}; }
	if err = sub(sum, aa, bb);        err != .None { return PyRes{res=":sub:sub(sum,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(sum, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":sub:itoa(sum):", err=err}; }
	return PyRes{res = r, err = .None};
}

@export test_mul :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, product := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, product);

	if err = atoi(aa, string(a), 16); err != .None { return PyRes{res=":mul:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 16); err != .None { return PyRes{res=":mul:atoi(b):", err=err}; }
	if err = mul(product, aa, bb);    err != .None { return PyRes{res=":mul:mul(product,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(product, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":mul:itoa(product):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	NOTE(Jeroen): For simplicity, we don't return the quotient and the remainder, just the quotient.
*/
@export test_div :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, quotient := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, quotient);

	if err = atoi(aa, string(a), 16); err != .None { return PyRes{res=":div:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 16); err != .None { return PyRes{res=":div:atoi(b):", err=err}; }
	if err = div(quotient, aa, bb);   err != .None { return PyRes{res=":div:div(quotient,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(quotient, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":div:itoa(quotient):", err=err}; }
	return PyRes{res = r, err = .None};
}


/*
	res = log(a, base)
*/
@export test_log :: proc "c" (a: cstring, base := DIGIT(2)) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;
	l: int;

	aa := &Int{};
	defer destroy(aa);

	if err = atoi(aa, string(a), 16); err != .None { return PyRes{res=":log:atoi(a):", err=err}; }
	if l, err = log(aa, base);        err != .None { return PyRes{res=":log:log(a, base):", err=err}; }

	zero(aa);
	aa.digit[0] = DIGIT(l)  & _MASK;
	aa.digit[1] = DIGIT(l) >> _DIGIT_BITS;
	aa.used = 2;
	clamp(aa);

	r: cstring;
	r, err = int_itoa_cstring(aa, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":log:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = base^power
*/
@export test_pow :: proc "c" (base: cstring, power := int(2)) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	dest, bb := &Int{}, &Int{};
	defer destroy(dest, bb);

	if err = atoi(bb, string(base), 16); err != .None { return PyRes{res=":pow:atoi(base):", err=err}; }
	if err = pow(dest, bb, power);       err != .None { return PyRes{res=":pow:pow(dest, base, power):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(dest, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":log:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = sqrt(src)
*/
@export test_sqrt :: proc "c" (source: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":sqrt:atoi(src):", err=err}; }
	if err = sqrt(src, src);                err != .None { return PyRes{res=":sqrt:sqrt(src):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":log:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = root_n(src, power)
*/
@export test_root_n :: proc "c" (source: cstring, power: int) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":root_n:atoi(src):", err=err}; }
	if err = root_n(src, src, power);       err != .None { return PyRes{res=":root_n:root_n(src):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":root_n:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = shr_digit(src, digits)
*/
@export test_shr_digit :: proc "c" (source: cstring, digits: int) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":shr_digit:atoi(src):", err=err}; }
	if err = shr_digit(src, digits);        err != .None { return PyRes{res=":shr_digit:shr_digit(src):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":shr_digit:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = shl_digit(src, digits)
*/
@export test_shl_digit :: proc "c" (source: cstring, digits: int) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":shl_digit:atoi(src):", err=err}; }
	if err = shl_digit(src, digits);        err != .None { return PyRes{res=":shl_digit:shr_digit(src):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":shl_digit:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = shr(src, bits)
*/
@export test_shr :: proc "c" (source: cstring, bits: int) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":shr:atoi(src):", err=err}; }
	if err = shr(src, src, bits);           err != .None { return PyRes{res=":shr:shr(src, bits):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":shr:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = shr_signed(src, bits)
*/
@export test_shr_signed :: proc "c" (source: cstring, bits: int) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":shr_signed:atoi(src):", err=err}; }
	if err = shr_signed(src, src, bits);    err != .None { return PyRes{res=":shr_signed:shr_signed(src, bits):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":shr_signed:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = shl(src, bits)
*/
@export test_shl :: proc "c" (source: cstring, bits: int) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	src := &Int{};
	defer destroy(src);

	if err = atoi(src, string(source), 16); err != .None { return PyRes{res=":shl:atoi(src):", err=err}; }
	if err = shl(src, src, bits);           err != .None { return PyRes{res=":shl:shl(src, bits):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(src, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":shl:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = factorial(n)
*/
@export test_factorial :: proc "c" (n: DIGIT) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	dest := &Int{};
	defer destroy(dest);

	if err = factorial(dest, n); err != .None { return PyRes{res=":factorial:factorial(n):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(dest, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":factorial:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = gcd(a, b)
*/
@export test_gcd :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	ai, bi, dest := &Int{}, &Int{}, &Int{};
	defer destroy(ai, bi, dest);

	if err = atoi(ai, string(a), 16); err != .None { return PyRes{res=":gcd:atoi(a):", err=err}; }
	if err = atoi(bi, string(b), 16); err != .None { return PyRes{res=":gcd:atoi(b):", err=err}; }
	if err = gcd(dest, ai, bi); err != .None { return PyRes{res=":gcd:gcd(a, b):", err=err}; }	

	r: cstring;
	r, err = int_itoa_cstring(dest, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":gcd:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = lcm(a, b)
*/
@export test_lcm :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	ai, bi, dest := &Int{}, &Int{}, &Int{};
	defer destroy(ai, bi, dest);

	if err = atoi(ai, string(a), 16); err != .None { return PyRes{res=":gcd:atoi(a):", err=err}; }
	if err = atoi(bi, string(b), 16); err != .None { return PyRes{res=":gcd:atoi(b):", err=err}; }
	if err = lcm(dest, ai, bi); err != .None { return PyRes{res=":lcm:lcm(a, b):", err=err}; }	

	r: cstring;
	r, err = int_itoa_cstring(dest, 16, context.temp_allocator);
	if err != .None { return PyRes{res=":lcm:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

