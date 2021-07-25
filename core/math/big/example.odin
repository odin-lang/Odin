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
	DEFAULT_DIGIT_COUNT  %v
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
}

print :: proc(name: string, a: ^Int, base := i8(16)) {
	as, err := itoa(a, base);
	defer delete(as);
	if err == .None {
		cb, _ := count_bits(a);
		fmt.printf("%v (base: %v, bits used: %v): %v\n", name, base, cb, as);
	} else {
		fmt.printf("%v (error: %v): %v\n", name, err, a);
	}
}

demo :: proc() {
	err: Error;
	i:   int;
	destination, source, quotient, remainder, numerator, denominator := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(destination, source, quotient, remainder, numerator, denominator);

	err = set(numerator,   15625);
	err = set(denominator,     3);

	print("numerator  ", numerator,   10);
	print("denominator", denominator, 10);

	i, err = _int_div_3(quotient, numerator);

	print("quotient   ", quotient,    10);
	fmt.println("remainder  ", i);
	fmt.println("error", err);

	fmt.println(); fmt.println();

	err = set (numerator,   15625);
	err = set (denominator,     3);
	err = zero(quotient);

	print("numerator  ", numerator,   10);
	print("denominator", denominator, 10);

	err = _int_div_small(quotient, remainder, numerator, denominator);

	print("quotient   ", quotient,    10);
	print("remainder  ", remainder,   10);


}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	print_configation();
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