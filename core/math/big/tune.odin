/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

#+build ignore
package math_big

import "core:time"
import "base:runtime"

print_value :: proc(name: string, value: i64) {
	runtime.print_string("\t")
	runtime.print_string(name)
	runtime.print_string(": ")
	runtime.print_i64(value)
	runtime.print_string("\n")
}

print_bool :: proc(name: string, value: bool) {
	runtime.print_string("\t")
	runtime.print_string(name)
	if value {
		runtime.print_string(": true\n")
	} else {
		runtime.print_string(": false\n")
	}
}

print_configation :: proc() {
	runtime.print_string("Configuration:\n")
	print_value("_DIGIT_BITS                          ", _DIGIT_BITS)
	print_bool ("MATH_BIG_SMALL_MEMORY                ", _LOW_MEMORY)
	print_value("_MIN_DIGIT_COUNT                     ", _MIN_DIGIT_COUNT)
	print_value("_MAX_DIGIT_COUNT                     ", i64(_MAX_DIGIT_COUNT))
	print_value("_DEFAULT_DIGIT_COUNT                 ", _DEFAULT_DIGIT_COUNT)
	print_value("_MAX_COMBA                           ", _MAX_COMBA)
	print_value("_WARRAY                              ", _WARRAY)
	print_value("_TAB_SIZE                            ", _TAB_SIZE)
	print_value("_MAX_WIN_SIZE                        ", _MAX_WIN_SIZE)
	print_bool ("MATH_BIG_USE_LUCAS_SELFRIDGE_TEST    ", MATH_BIG_USE_LUCAS_SELFRIDGE_TEST)

	runtime.print_string("\nRuntime tunable:\n")
	print_value("MUL_KARATSUBA_CUTOFF                 ", i64(MUL_KARATSUBA_CUTOFF))
	print_value("SQR_KARATSUBA_CUTOFF                 ", i64(SQR_KARATSUBA_CUTOFF))
	print_value("MUL_TOOM_CUTOFF                      ", i64(MUL_TOOM_CUTOFF))
	print_value("SQR_TOOM_CUTOFF                      ", i64(SQR_TOOM_CUTOFF))
	print_value("MAX_ITERATIONS_ROOT_N                ", i64(MAX_ITERATIONS_ROOT_N))
	print_value("FACTORIAL_MAX_N                      ", i64(FACTORIAL_MAX_N))
	print_value("FACTORIAL_BINARY_SPLIT_CUTOFF        ", i64(FACTORIAL_BINARY_SPLIT_CUTOFF))
	print_value("FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS", i64(FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS))
	print_value("FACTORIAL_BINARY_SPLIT_CUTOFF        ", i64(FACTORIAL_BINARY_SPLIT_CUTOFF))
	print_bool ("USE_MILLER_RABIN_ONLY                ", USE_MILLER_RABIN_ONLY)
	print_value("MAX_ITERATIONS_RANDOM_PRIME          ", i64(MAX_ITERATIONS_RANDOM_PRIME))
}

print :: proc(name: string, a: ^Int, base := i8(10), print_name := true, newline := true, print_extra_info := false) {
	assert_if_nil(a)

	as, err := itoa(a, base)
	defer delete(as)

	cb := internal_count_bits(a)
	if print_name {
		runtime.print_string(name)
	}
	if err != nil {
		runtime.print_string("(Error: ")
		es := Error_String
		runtime.print_string(es[err])
		runtime.print_string(")")
	}
	runtime.print_string(as)
	if print_extra_info {
	 	runtime.print_string(" (base: ")
	 	runtime.print_i64(i64(base))
	 	runtime.print_string(", bits: ")
	 	runtime.print_i64(i64(cb))
	 	runtime.print_string(", digits: ")
	 	runtime.print_i64(i64(a.used))
	 	runtime.print_string(")")
	}
	if newline {
		runtime.print_string("\n")
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
	sqr,
	bitfield_extract,
	rm_trials,
	is_prime,
	random_prime,
}

Event :: struct {
	ticks:  time.Duration,
	count:  int,
	cycles: u64,
}
Timings := [Category]Event{}

print_timings :: proc() {
	// duration :: proc(d: time.Duration) -> (res: string) {
	// 	switch {
	// 	case d < time.Microsecond:
	// 		return fmt.tprintf("%v ns", time.duration_nanoseconds(d))
	// 	case d < time.Millisecond:
	// 		return fmt.tprintf("%v µs", time.duration_microseconds(d))
	// 	case:
	// 		return fmt.tprintf("%v ms", time.duration_milliseconds(d))
	// 	}
	// }

	// for v in Timings {
	// 	if v.count > 0 {
	// 		fmt.println("\nTimings:")
	// 		break
	// 	}
	// }

	// for v, i in Timings {
	// 	if v.count > 0 {
	// 		avg_ticks  := time.Duration(f64(v.ticks) / f64(v.count))
	// 		avg_cycles := f64(v.cycles) / f64(v.count)

	// 		fmt.printf("\t%v: %s / %v cycles (avg), %s / %v cycles (total, %v calls)\n", i, duration(avg_ticks), avg_cycles, duration(v.ticks), v.cycles, v.count)
	// 	}
	// }
}

@(deferred_in_out=_SCOPE_END)
SCOPED_TIMING :: #force_inline proc(c: Category) -> (ticks: time.Tick, cycles: u64) {
	cycles = time.read_cycle_counter()
	ticks  = time.tick_now()
	return
}
_SCOPE_END :: #force_inline proc(c: Category, ticks: time.Tick, cycles: u64) {
	cycles_now := time.read_cycle_counter()
	ticks_now  := time.tick_now()

	Timings[c].ticks  = time.tick_diff(ticks, ticks_now)
	Timings[c].cycles = cycles_now - cycles
	Timings[c].count += 1
}
SCOPED_COUNT_ADD :: #force_inline proc(c: Category, count: int) {
	Timings[c].count += count
}
