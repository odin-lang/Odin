//+ignore
package big

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

print :: proc(name: string, a: ^Int, base := i8(16)) {
	as, err := itoa(a, base);
	defer delete(as);

	if err == .OK {
		fmt.printf("%v (base: %v, bits used: %v): %v\n", name, base, count_bits(a), as);
	} else {
		fmt.printf("%v (error: %v): %v\n", name, err, a);
	}
}

demo :: proc() {
	a, b, c := &Int{}, &Int{}, &Int{};
	err: Error;

	defer destroy(a);
	defer destroy(b);
	defer destroy(c);

	err = set(a, 512);
	err = init(b, a);
	err = init(c, -4);

	print("a", a, 2);
	print("b", b, 2);
	print("c", c, 2);

	fmt.println("=== a = a & b ===");
	err = and(a, a, b);
	fmt.printf("a &= b error: %v\n", err);

	print("a", a, 2);
	print("b", b, 10);

	fmt.println("\n\n=== b = abs(c) ===");
	c.sign = .Negative;
	abs(b, c); // copy c to b.

	print("b", b);
	print("c", c);

	fmt.println("\n\n=== Set a to (1 << 120) - 1 ===");
	if err = power_of_two(a, 120); err != .OK {
		fmt.printf("Error %v while setting a to 1 << 120.\n", err);
	}
	if err = sub(a, a, 1); err != .OK {
		fmt.printf("Error %v while subtracting 1 from a\n", err);	
	}
	print("a", a, 16);
	fmt.println("Expected a to be:        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
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
	if len(ta.bad_free_array) > 0 {
		fmt.println("Bad frees:");
		for v in ta.bad_free_array {
			fmt.println(v);
		}
	}
}