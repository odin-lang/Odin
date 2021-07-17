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

demo :: proc() {
	a,  b,  c: ^Int;
	as, bs, cs: string;
	err:  Error;

	a, err = init(512);
	defer destroy(a);
	as, err = itoa(a, 10);
	fmt.printf("a: %v, err: %v\n\n", as, err);
	delete(as);

	b, err = init(42);
	defer destroy(b);
	bs, err = itoa(b, 10);
	fmt.printf("b: %v, err: %v\n\n", bs, err);
	delete(bs);

	c, err = init();
	defer destroy(c);
	cs, err = itoa(c, 10);
	fmt.printf("c: %v\n", cs);
	delete(cs);

	fmt.println("=== Add ===");
	err = sub(c, a, b);

	fmt.printf("Error: %v\n", err);
	as, err = itoa(a, 10);
	bs, err = itoa(b, 10);
	cs, err = itoa(c, 10);
	fmt.printf("a: %v, bits: %v\n", as, count_bits(a));
	fmt.printf("b: %v, bits: %v\n", bs, count_bits(b));
	fmt.printf("c: %v, bits: %v\n", cs, count_bits(c));
	delete(as); delete(bs); delete(cs);

	fmt.println("log2:", log_n(a, 8));
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