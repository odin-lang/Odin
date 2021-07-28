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

@export test_add_two :: proc "c" (a, b: cstring, radix := int(10)) -> (res: PyRes) {
	context = runtime.default_context();
	err: Error;

	aa, bb, sum := &Int{}, &Int{}, &Int{};
	defer destroy(aa, bb, sum);

	if err = atoi(aa, string(a), i8(radix)); err != .None { return PyRes{res=":add_two:atoi(a):", err=err}; }
	if err = atoi(bb, string(b), i8(radix)); err != .None { return PyRes{res=":add_two:atoi(b):", err=err}; }
	if err = add(sum, aa, bb);               err != .None { return PyRes{res=":add_two:add(sum,a,b):", err=err}; }

	r: cstring;
	r, err = int_itoa_cstring(sum, i8(radix), context.temp_allocator);
	if err != .None { return PyRes{res=":add_two:itoa(sum):", err=err}; }
	return PyRes{res = r, err = .None};
}