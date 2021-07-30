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

@export test_add_two :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, sum := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, sum);

	if err = atoi(aa, string(a), 10); err != .None { return PyRes{res=":add_two:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 10); err != .None { return PyRes{res=":add_two:atoi(b):", err=err}; }
	if err = add(sum, aa, bb);        err != .None { return PyRes{res=":add_two:add(sum,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(sum, 10, context.temp_allocator);
	if err != .None { return PyRes{res=":add_two:itoa(sum):", err=err}; }
	return PyRes{res = r, err = .None};
}

@export test_sub_two :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, sum := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, sum);

	if err = atoi(aa, string(a), 10); err != .None { return PyRes{res=":sub_two:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 10); err != .None { return PyRes{res=":sub_two:atoi(b):", err=err}; }
	if err = sub(sum, aa, bb);        err != .None { return PyRes{res=":sub_two:sub(sum,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(sum, 10, context.temp_allocator);
	if err != .None { return PyRes{res=":sub_two:itoa(sum):", err=err}; }
	return PyRes{res = r, err = .None};
}

@export test_mul_two :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, product := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, product);

	if err = atoi(aa, string(a), 10); err != .None { return PyRes{res=":mul_two:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 10); err != .None { return PyRes{res=":mul_two:atoi(b):", err=err}; }
	if err = mul(product, aa, bb);    err != .None { return PyRes{res=":mul_two:mul(product,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(product, 10, context.temp_allocator);
	if err != .None { return PyRes{res=":mul_two:itoa(product):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	NOTE(Jeroen): For simplicity, we don't return the quotient and the remainder, just the quotient.
*/
@export test_div_two :: proc "c" (a, b: cstring) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, quotient := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, quotient);

	if err = atoi(aa, string(a), 10); err != .None { return PyRes{res=":div_two:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), 10); err != .None { return PyRes{res=":div_two:atoi(b):", err=err}; }
	if err = div(quotient, aa, bb);   err != .None { return PyRes{res=":div_two:div(quotient,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(quotient, 10, context.temp_allocator);
	if err != .None { return PyRes{res=":div_two:itoa(quotient):", err=err}; }
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

	if err = atoi(aa, string(a), 10); err != .None { return PyRes{res=":log:atoi(a):", err=err}; }
	if l, err = log(aa, base);        err != .None { return PyRes{res=":log:log(a, base):", err=err}; }

	zero(aa);
	aa.digit[0] = DIGIT(l)  & _MASK;
	aa.digit[1] = DIGIT(l) >> _DIGIT_BITS;
	aa.used = 2;
	clamp(aa);

	r: cstring;
	r, err = int_itoa_cstring(aa, 10, context.temp_allocator);
	if err != .None { return PyRes{res=":log:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}

/*
	dest = base^power
*/
@export test_pow :: proc "c" (base: cstring, power := int(2)) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;
	l: int;

	dest, bb := &Int{}, &Int{};
	defer destroy(dest, bb);

	if err = atoi(bb, string(base), 10); err != .None { return PyRes{res=":pow:atoi(base):", err=err}; }
	if err = pow(dest, bb, power);       err != .None { return PyRes{res=":pow:pow(dest, base, power):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(dest, 10, context.temp_allocator);
	if err != .None { return PyRes{res=":log:itoa(res):", err=err}; }
	return PyRes{res = r, err = .None};
}