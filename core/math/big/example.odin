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
`
Configuration:
	_DIGIT_BITS                           %v
	_MIN_DIGIT_COUNT                      %v
	_MAX_DIGIT_COUNT                      %v
	_DEFAULT_DIGIT_COUNT                  %v
	_MAX_COMBA                            %v
	_WARRAY                               %v
Runtime tunable:
	MUL_KARATSUBA_CUTOFF                  %v
	SQR_KARATSUBA_CUTOFF                  %v
	MUL_TOOM_CUTOFF                       %v
	SQR_TOOM_CUTOFF                       %v
	MAX_ITERATIONS_ROOT_N                 %v
	FACTORIAL_MAX_N                       %v
	FACTORIAL_BINARY_SPLIT_CUTOFF         %v
	FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS %v

`, _DIGIT_BITS,
_MIN_DIGIT_COUNT,
_MAX_DIGIT_COUNT,
_DEFAULT_DIGIT_COUNT,
_MAX_COMBA,
_WARRAY,
MUL_KARATSUBA_CUTOFF,
SQR_KARATSUBA_CUTOFF,
MUL_TOOM_CUTOFF,
SQR_TOOM_CUTOFF,
MAX_ITERATIONS_ROOT_N,
FACTORIAL_MAX_N,
FACTORIAL_BINARY_SPLIT_CUTOFF,
FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS,
);

}

print :: proc(name: string, a: ^Int, base := i8(10), print_name := true, newline := true, print_extra_info := false) {
	assert_if_nil(a);

	as, err := itoa(a, base);
	defer delete(as);

	cb := internal_count_bits(a);
	if print_name {
		fmt.printf("%v", name);
	}
	if err != nil {
		fmt.printf("%v (error: %v | %v)", name, err, a);
	}
	fmt.printf("%v", as);
	if print_extra_info {
		fmt.printf(" (base: %v, bits: %v (digits: %v), flags: %v)", base, cb, a.used, a.flags);
	}
	if newline {
		fmt.println();
	}
}

demo :: proc() {
	a, b, c, d, e, f := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f);

	err: Error;
	bs: string;

	// if err = factorial(a, 850); err != nil { fmt.printf("factorial err: %v\n", err); return; }

	foo := "615037959146039477924633848896619112832171971562900618409305032006863881436080";
	if err = atoi(a, foo, 10); err != nil { return; }
	print("a: ", a, 10, true, true, true);
	fmt.println();

	{
		SCOPED_TIMING(.sqr);
		if err = sqr(b, a); err != nil { fmt.printf("sqr err: %v\n", err); return; }
	}
	fmt.println();
	print("b _sqr_karatsuba: ", b);
	fmt.println();

	bs, err = itoa(b, 16);
	defer delete(bs);

	if bs[:50] != "1C367982F3050A8A3C62A8A7906D165438B54B287AF3F15D36" {
		fmt.println("sqr failed");
	}
}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	demo();

	print_configation();

	print_timings();

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