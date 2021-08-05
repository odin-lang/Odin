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
		if v.count > 0 {
			avg_ticks  := time.Duration(f64(v.ticks) / f64(v.count));
			avg_cycles := f64(v.cycles) / f64(v.count);

			avg_s: string;
			switch {
			case avg_ticks < time.Microsecond:
				avg_s = fmt.tprintf("%v ns / %v cycles", time.duration_nanoseconds(avg_ticks), avg_cycles);
			case avg_ticks < time.Millisecond:
				avg_s = fmt.tprintf("%v µs / %v cycles", time.duration_microseconds(avg_ticks), avg_cycles);
			case:
				avg_s = fmt.tprintf("%v ms / %v cycles", time.duration_milliseconds(avg_ticks), avg_cycles);
			}

			total_s: string;
			switch {
			case v.ticks < time.Microsecond:
				total_s = fmt.tprintf("%v ns / %v cycles", time.duration_nanoseconds(v.ticks), v.cycles);
			case v.ticks < time.Millisecond:
				total_s = fmt.tprintf("%v µs / %v cycles", time.duration_microseconds(v.ticks), v.cycles);
			case:
				total_s = fmt.tprintf("%v ms / %v cycles", time.duration_milliseconds(v.ticks), v.cycles);
			}

			fmt.printf("\t%v: %s (avg), %s (total, %v calls)\n", i, avg_s, total_s, v.count);
		}
	}
}

@(deferred_in_out=_SCOPE_END)
SCOPED_TIMING :: #force_inline proc(c: Category) -> (ticks: time.Tick, cycles: u64) {
	cycles = time.read_cycle_counter();
	ticks  = time.tick_now();
	return;
}
_SCOPE_END :: #force_inline proc(c: Category, ticks: time.Tick, cycles: u64) {
	cycles_now := time.read_cycle_counter();
	ticks_now  := time.tick_now();

	Timings[c].ticks  = time.tick_diff(ticks, ticks_now);
	Timings[c].cycles = cycles_now - cycles;
	Timings[c].count += 1;
}
SCOPED_COUNT_ADD :: #force_inline proc(c: Category, count: int) {
	Timings[c].count += count;
}

Category :: enum {
	itoa,
	atoi,
	factorial,
	factorial_bin,
	choose,
	lsb,
	ctz,
	bitfield_extract,
};

Event :: struct {
	ticks:  time.Duration,
	count:  int,
	cycles: u64,
}
Timings := [Category]Event{};

print :: proc(name: string, a: ^Int, base := i8(10), print_name := true, newline := true, print_extra_info := false) {
	as, err := itoa(a, base);

	defer delete(as);
	cb, _ := count_bits(a);
	if print_name {
		fmt.printf("%v", name);
	}
	if err != nil {
		fmt.printf("%v (error: %v | %v)", name, err, a);
	}
	fmt.printf("%v", as);
	if print_extra_info {
		fmt.printf(" (base: %v, bits used: %v, flags: %v)", base, cb, a.flags);
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

	err = factorial(a, 1224);
	count, _ := count_bits(a);

	bits :=  51;
	be1: _WORD;

	/*
		Timing loop
	*/
	{
		SCOPED_TIMING(.bitfield_extract);
		for o := 0; o < count - bits; o += 1 {
			be1, _ = int_bitfield_extract(a, o, bits);
		}
	}
	SCOPED_COUNT_ADD(.bitfield_extract, count - bits - 1);
	fmt.printf("be1: %v\n", be1);
}

main :: proc() {
	ta := mem.Tracking_Allocator{};
	mem.tracking_allocator_init(&ta, context.allocator);
	context.allocator = mem.tracking_allocator(&ta);

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