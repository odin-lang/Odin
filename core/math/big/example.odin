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

print_timings :: proc() {
	fmt.printf("Timings:\n");
	for v, i in Timings {
		if v.c > 0 {
			avg   := time.Duration(f64(v.t) / f64(v.c));

			avg_s: string;
			switch {
			case avg < time.Microsecond:
				avg_s = fmt.tprintf("%v ns", time.duration_nanoseconds(avg));
			case avg < time.Millisecond:
				avg_s = fmt.tprintf("%v µs", time.duration_microseconds(avg));
			case:
				avg_s = fmt.tprintf("%v ms", time.duration_milliseconds(avg));
			}

			total_s: string;
			switch {
			case v.t < time.Microsecond:
				total_s = fmt.tprintf("%v ns", time.duration_nanoseconds(v.t));
			case v.t < time.Millisecond:
				total_s = fmt.tprintf("%v µs", time.duration_microseconds(v.t));
			case:
				total_s = fmt.tprintf("%v ms", time.duration_milliseconds(v.t));
			}

			fmt.printf("\t%v: %s (avg), %s (total, %v calls)\n", i, avg_s, total_s, v.c);
		}
	}
}

Category :: enum {
	itoa,
	atoi,
	factorial,
	factorial_bin,
	choose,
	lsb,
	ctz,
};
Event :: struct {
	t: time.Duration,
	c: int,
}
Timings := [Category]Event{};

print :: proc(name: string, a: ^Int, base := i8(10), print_name := false, newline := true, print_extra_info := false) {
	s := time.tick_now();
	as, err := itoa(a, base);
	Timings[.itoa].t += time.tick_since(s); Timings[.itoa].c += 1;

	defer delete(as);
	cb, _ := count_bits(a);
	if print_name {
		fmt.printf("%v ", name);
	}
	if print_extra_info {
		fmt.printf("(base: %v, bits used: %v): %v", base, cb, as);
	} else {
		fmt.printf("%v", as);
	}
	if err != nil {
		fmt.printf("%v (error: %v | %v)", name, err, a);
	}
	if newline {
		fmt.println();
	}
}

demo :: proc() {
	err: Error;
	as: string;
	defer delete(as);

	a, b, c, d, e, f := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(a, b, c, d, e, f);

	factorial(a, 128); // Untimed warmup.

	N :: 128;

	s := time.tick_now();
	err = factorial(a, N);
	Timings[.factorial].t += time.tick_since(s); Timings[.factorial].c += 1;

	if err != nil {
		fmt.printf("factorial(%v) returned %v\n", N, err);
	}

	s = time.tick_now();
	as, err = itoa(a, 16);
	Timings[.itoa].t += time.tick_since(s); Timings[.itoa].c += 1;
	if err != nil {
		fmt.printf("itoa(factorial(%v), 16) returned %v\n", N, err);
	}

	fmt.printf("factorial(%v): %v (first 10 hex digits)\n", N, as[:10]);
}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

	// print_configation();
	demo();
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