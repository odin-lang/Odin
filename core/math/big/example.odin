//+ignore
/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/
package math_big


import "core:fmt"
import "core:mem"

print_configation :: proc() {
	fmt.printf(
`
Configuration:
	_DIGIT_BITS                           %v
	_SMALL_MEMORY                         %v
	_MIN_DIGIT_COUNT                      %v
	_MAX_DIGIT_COUNT                      %v
	_DEFAULT_DIGIT_COUNT                  %v
	_MAX_COMBA                            %v
	_WARRAY                               %v
	_TAB_SIZE                             %v
	_MAX_WIN_SIZE                         %v
	MATH_BIG_USE_FROBENIUS_TEST           %v
Runtime tunable:
	MUL_KARATSUBA_CUTOFF                  %v
	SQR_KARATSUBA_CUTOFF                  %v
	MUL_TOOM_CUTOFF                       %v
	SQR_TOOM_CUTOFF                       %v
	MAX_ITERATIONS_ROOT_N                 %v
	FACTORIAL_MAX_N                       %v
	FACTORIAL_BINARY_SPLIT_CUTOFF         %v
	FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS %v
	USE_MILLER_RABIN_ONLY                 %v

`, _DIGIT_BITS,
_LOW_MEMORY,
_MIN_DIGIT_COUNT,
_MAX_DIGIT_COUNT,
_DEFAULT_DIGIT_COUNT,
_MAX_COMBA,
_WARRAY,
_TAB_SIZE,
_MAX_WIN_SIZE,
MATH_BIG_USE_FROBENIUS_TEST,

MUL_KARATSUBA_CUTOFF,
SQR_KARATSUBA_CUTOFF,
MUL_TOOM_CUTOFF,
SQR_TOOM_CUTOFF,
MAX_ITERATIONS_ROOT_N,
FACTORIAL_MAX_N,
FACTORIAL_BINARY_SPLIT_CUTOFF,
FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS,
USE_MILLER_RABIN_ONLY,
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

// printf :: fmt.printf;

demo :: proc() {
	a, b, c, d, e, f, res := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f, res);

	err:  Error;
	lucas: bool;
	prime: bool;

	// USE_MILLER_RABIN_ONLY = true;

	// set(a, "3317044064679887385961979"); // Composite: 17 × 1709 × 1366183751 × 83570142193
	set(a, "359334085968622831041960188598043661065388726959079837"); // 6th Bell prime
	trials := number_of_rabin_miller_trials(internal_count_bits(a));
	{
		SCOPED_TIMING(.is_prime);
		prime, err = internal_int_is_prime(a, trials);
	}
	print("Candidate prime: ", a, 10, true, true, true);
	fmt.printf("%v Miller-Rabin trials needed.\n", trials);

	// lucas, err = internal_int_prime_strong_lucas_selfridge(a);
	fmt.printf("Lucas-Selfridge: %v, Prime: %v, Error: %v\n", lucas, prime, err);
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