//+ignore
package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:fmt"
import "core:mem"

print_int :: proc(a: ^Int, print_raw := false) -> string {
	if print_raw {
		return fmt.tprintf("%v", a);
	}
	sign := "-" if a.sign == .Negative else "";
	if a.used <= 2 {
		v := _WORD(a.digit[1]) << _DIGIT_BITS + _WORD(a.digit[0]);
		return fmt.tprintf("%v%v", sign, v);
	} else {
		return fmt.tprintf("[%2d/%2d] %v%v", a.used, a.allocated, sign, a.digit[:a.used]);
	}
}

demo :: proc() {
	a, b, c: ^Int;
	err:  Error;

	a, err = init(21);
	defer destroy(a);
	fmt.printf("a: %v, err: %v\n\n", print_int(a), err);

	b, err = init(21);
	defer destroy(b);

	fmt.printf("b: %v, err: %v\n\n", print_int(b), err);

	c, err = init();
	defer destroy(c);
	fmt.printf("c: %v\n", print_int(c, true));

	fmt.println("=== Add ===");
	err = add(c, a, DIGIT(42));
	// err = add(c, a, b);
	fmt.printf("Error: %v\n", err);
	fmt.printf("a: %v\n", print_int(a));
	fmt.printf("b: %v\n", print_int(b));
	fmt.printf("c: %v\n", print_int(c));
}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	fmt.printf("_DIGIT_BITS: %v\n_MIN_DIGIT_COUNT: %v\n_MAX_DIGIT_COUNT: %v\n_DEFAULT_DIGIT_COUNT: %v\n\n", _DIGIT_BITS, _MIN_DIGIT_COUNT, _MAX_DIGIT_COUNT, _DEFAULT_DIGIT_COUNT);

	demo();

	if len(ta.allocation_map) > 0 {
		for _, v in ta.allocation_map {
			fmt.printf("Leaked %v bytes @ %v\n", v.size, v.location);
		}
	}
}