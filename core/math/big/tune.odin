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
import "core:time"

Category :: enum {
	itoa,
	atoi,
	factorial,
	factorial_bin,
	choose,
	lsb,
	ctz,
	sqr,
	bitfield_extract,
	rm_trials,
};

Event :: struct {
	ticks:  time.Duration,
	count:  int,
	cycles: u64,
}
Timings := [Category]Event{};

print_timings :: proc() {
	duration :: proc(d: time.Duration) -> (res: string) {
		switch {
		case d < time.Microsecond:
			return fmt.tprintf("%v ns", time.duration_nanoseconds(d));
		case d < time.Millisecond:
			return fmt.tprintf("%v µs", time.duration_microseconds(d));
		case:
			return fmt.tprintf("%v ms", time.duration_milliseconds(d));
		}
	}

	for v in Timings {
		if v.count > 0 {
			fmt.println("\nTimings:");
			break;
		}
	}

	for v, i in Timings {
		if v.count > 0 {
			avg_ticks  := time.Duration(f64(v.ticks) / f64(v.count));
			avg_cycles := f64(v.cycles) / f64(v.count);

			fmt.printf("\t%v: %s / %v cycles (avg), %s / %v cycles (total, %v calls)\n", i, duration(avg_ticks), avg_cycles, duration(v.ticks), v.cycles, v.count);
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
