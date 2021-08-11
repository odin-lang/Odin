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

demo :: proc() {
	a, b, c, d, e, f := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f);

	err: Error;

	foo := "2291194942392555914538479778530519876003906024854260006581638127590953";
	if err = atoi(a, foo, 10); err != nil { return; }
	// print("a: ", a, 10, true, true, true);

	byte_length, _ := int_to_bytes_size(a);

	fmt.printf("byte_length(a): %v\n", byte_length);

	buf := make([]u8, byte_length);
	defer delete(buf);

	err = int_to_bytes_big(a, buf);

	python_big := []u8{
		 84, 252,  50,  97,  27,  81,  11, 101,  58,  96, 138, 175,  65, 202, 109,
		142, 106, 146, 117,  32, 200, 113,  36, 214, 188, 157, 242, 158,  41,
	};

	if mem.compare(python_big, buf) == 0 {
		fmt.printf("int_to_bytes_big: pass\n");
	} else {
		fmt.printf("int_to_bytes_big: fail | %v\n", buf);
	}
	python_little := []u8{
		 41, 158, 242, 157, 188, 214,  36, 113, 200,  32, 117, 146, 106, 142, 109,
		202,  65, 175, 138,  96,  58, 101,  11,  81,  27,  97,  50, 252,  84,
	};

	err = int_to_bytes_little(a, buf);
	if mem.compare(python_little, buf) == 0 {
		fmt.printf("int_to_bytes_little: pass\n");
	} else {
		fmt.printf("int_to_bytes_little: fail | %v\n", buf);
	}

	_ = neg(b, a);

	python_little_neg := []u8{
		215,  97,  13,  98,  67,  41, 219, 142,  55, 223, 138, 109, 149, 113, 146,
		 53, 190,  80, 117, 159, 197, 154, 244, 174, 228, 158, 205,   3, 171,
	};

	byte_length, _ = int_to_bytes_size_python(b, true);

	fmt.printf("byte_length(a): %v\n", byte_length);

	buf2 := make([]u8, byte_length);
	defer delete(buf2);

	err = int_to_bytes_little_python(b, buf, true);
	if mem.compare(python_little_neg, buf) == 0 {
		fmt.printf("int_to_bytes_little: pass\n");
	} else {
		fmt.printf("int_to_bytes_little: %v | %v\n", err, buf);
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