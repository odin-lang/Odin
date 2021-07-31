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
import "core:time"
// import rnd "core:math/rand"

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

Category :: enum {
	itoa,
	atoi,
	factorial,
};
Event :: struct {
	t: time.Duration,
	c: int,
}
Timings := [Category]Event{};

print :: proc(name: string, a: ^Int, base := i8(10), print_extra_info := false, print_name := false) {
	s := time.tick_now();
	as, err := itoa(a, base);
	Timings[.itoa].t += time.tick_since(s); Timings[.itoa].c += 1;

	defer delete(as);
	cb, _ := count_bits(a);
	if print_name {
		fmt.printf("%v ", name);
	}
	if print_extra_info {
		fmt.printf("(base: %v, bits used: %v): %v\n", base, cb, as);
	} else {
		fmt.printf("%v\n", as);
	}
	if err != .None {
		fmt.printf("%v (error: %v | %v)\n", name, err, a);
	}
}

demo :: proc() {
	err: Error;
	destination, source, quotient, remainder, numerator, denominator := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(destination, source, quotient, remainder, numerator, denominator);

	a :=  "4d2";
	b := "1538";

	if err = atoi(destination, a, 16); err != .None {
		fmt.printf("atoi(a) returned %v\n", err);
		return;
	}
	if err = atoi(source, b, 16); err != .None {
		fmt.printf("atoi(b) returned %v\n", err);
		return;
	}
	if err = add(destination, destination, source); err != .None {
		fmt.printf("add(a, b) returned %v\n", err);
		return;
	}
}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	// print_configation();
	demo();

	fmt.printf("\nTimings:\n");
	for v, i in Timings {
		if v.c > 0 {
			avg   := time.duration_milliseconds(time.Duration(f64(v.t) / f64(v.c)));
			total := time.duration_milliseconds(time.Duration(v.t));
			fmt.printf("%v: %.3f ms (avg), %.3f ms (total, %v calls)\n", i, avg, total, v.c);
		}
	}

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