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

print_configation :: proc() {
	fmt.printf(
`Configuration:
	DIGIT_BITS           %v
	MIN_DIGIT_COUNT      %v
	MAX_DIGIT_COUNT      %v
	EFAULT_DIGIT_COUNT   %v
	MAX_COMBA            %v
	WARRAY               %v
	MUL_KARATSUBA_CUTOFF %v
	SQR_KARATSUBA_CUTOFF %v
	MUL_TOOM_CUTOFF      %v
	SQR_TOOM_CUTOFF      %v
`, _DIGIT_BITS,
_MIN_DIGIT_COUNT,
_MAX_DIGIT_COUNT,
_DEFAULT_DIGIT_COUNT,
_MAX_COMBA,
_WARRAY,
_MUL_KARATSUBA_CUTOFF,
_SQR_KARATSUBA_CUTOFF,
_MUL_TOOM_CUTOFF,
_SQR_TOOM_CUTOFF,
);

	fmt.println();
}

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

	a, err = init(512);
	defer destroy(a);
	fmt.printf("a: %v, err: %v\n\n", print_int(a), err);

	b, err = init(42);
	defer destroy(b);

	fmt.printf("b: %v, err: %v\n\n", print_int(b), err);

	c, err = init();
	defer destroy(c);
	fmt.printf("c: %v\n", print_int(c, true));

	fmt.println("=== Add ===");
	err = sub(c, a, b);
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

	// print_configation();
	demo();

	if len(ta.allocation_map) > 0 {
		for _, v in ta.allocation_map {
			fmt.printf("Leaked %v bytes @ %v\n", v.size, v.location);
		}
	}
}