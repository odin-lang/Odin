//+ignore
package math_big

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

int_to_byte :: proc(v: ^Int) {
	err: Error;
	size: int;
	print("v: ", v);
	fmt.println();

	t := &Int{};
	defer destroy(t);

	if size, err = int_to_bytes_size(v); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b1 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_big(v, b1);
	int_from_bytes_big(t, b1);
	fmt.printf("big: %v | err: %v\n", b1, err);

	int_from_bytes_big(t, b1);
	if internal_cmp_mag(t, v) != 0 {
		print("\tError parsing t: ", t);
	}

	if size, err = int_to_bytes_size(v); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b2 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_big_python(v, b2);
	fmt.printf("big python: %v | err: %v\n", b2, err);

	if err == nil {
		int_from_bytes_big_python(t, b2);
		if internal_cmp_mag(t, v) != 0 {
			print("\tError parsing t: ", t);
		}
	}

	if size, err = int_to_bytes_size(v, true); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b3 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_big(v, b3, true);
	fmt.printf("big signed: %v | err: %v\n", b3, err);

	int_from_bytes_big(t, b3, true);
	if internal_cmp(t, v) != 0 {
		print("\tError parsing t: ", t);
	}

	if size, err = int_to_bytes_size(v, true); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b4 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_big_python(v, b4, true);
	fmt.printf("big signed python: %v | err: %v\n", b4, err);

	int_from_bytes_big_python(t, b4, true);
	if internal_cmp(t, v) != 0 {
		print("\tError parsing t: ", t);
	}
}

int_to_byte_little :: proc(v: ^Int) {
	err: Error;
	size: int;
	print("v: ", v);
	fmt.println();

	t := &Int{};
	defer destroy(t);

	if size, err = int_to_bytes_size(v); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b1 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_little(v, b1);
	fmt.printf("little: %v | err: %v\n", b1, err);

	int_from_bytes_little(t, b1);
	if internal_cmp_mag(t, v) != 0 {
		print("\tError parsing t: ", t);
	}

	if size, err = int_to_bytes_size(v); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b2 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_little_python(v, b2);
	fmt.printf("little python: %v | err: %v\n", b2, err);

	if err == nil {
		int_from_bytes_little_python(t, b2);
		if internal_cmp_mag(t, v) != 0 {
			print("\tError parsing t: ", t);
		}
	}

	if size, err = int_to_bytes_size(v, true); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b3 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_little(v, b3, true);
	fmt.printf("little signed: %v | err: %v\n", b3, err);

	int_from_bytes_little(t, b3, true);
	if internal_cmp(t, v) != 0 {
		print("\tError parsing t: ", t);
	}

	if size, err = int_to_bytes_size(v, true); err != nil {
		fmt.printf("int_to_bytes_size returned: %v\n", err);
		return;
	}
	b4 := make([]u8, size, context.temp_allocator);
	err = int_to_bytes_little_python(v, b4, true);
	fmt.printf("little signed python: %v | err: %v\n", b4, err);

	int_from_bytes_little_python(t, b4, true);
	if internal_cmp(t, v) != 0 {
		print("\tError parsing t: ", t);
	}
}

demo :: proc() {
	a, b, c, d, e, f := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f);

	atoi(a, "615037959146039477924633848896619112832171971562900618409305032006863881436080", 10);
	print("a: ", a, 10, true, true, true);
	atoi(b, "378271691190525325893712245607881659587045836991909505715443874842659307597325888631898626653926188084180707310543535657996185416604973577488563643125766400", 10);
	print("b: ", b, 10, true, true, true);

	factorial(c, 10_000);

	// 120CCAA2076ADF69F75A97695E6C1C2A4E6F377DF92226E43B
	cs, _ := itoa(c, 16);
	defer delete(cs);

	print("c: ", c, 10, true, true, true);
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