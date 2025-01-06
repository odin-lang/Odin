package time

import "base:runtime"
import "base:intrinsics"

/*
Type representing monotonic time, useful for measuring durations.
*/
Tick :: struct {
	_nsec: i64, // relative amount
}

/*
Obtain the current tick.
*/
tick_now :: proc "contextless" () -> Tick {
	return _tick_now()
}

/*
Obtain the difference between ticks.
*/
tick_diff :: proc "contextless" (start, end: Tick) -> Duration {
	d := end._nsec - start._nsec
	return Duration(d)
}

/*
Incrementally obtain durations since last tick.

This procedure returns the duration between the current tick and the tick
stored in `prev` pointer, and then stores the current tick in location,
specified by `prev`. If the prev pointer contains an zero-initialized tick,
then the returned duration is 0.

This procedure is meant to be used in a loop, or in other scenarios, where one
might want to obtain time between multiple ticks at specific points.
*/
tick_lap_time :: proc "contextless" (prev: ^Tick) -> Duration {
	d: Duration
	t := tick_now()
	if prev._nsec != 0 {
		d = tick_diff(prev^, t)
	}
	prev^ = t
	return d
}

/*
Obtain the duration since last tick.
*/
tick_since :: proc "contextless" (start: Tick) -> Duration {
	return tick_diff(start, tick_now())
}

/*
Capture the duration the code in the current scope takes to execute.
*/
@(deferred_in_out=_tick_duration_end)
SCOPED_TICK_DURATION :: proc "contextless" (d: ^Duration) -> Tick {
	return tick_now()
}

_tick_duration_end :: proc "contextless" (d: ^Duration, t: Tick) {
	d^ = tick_since(t)
}

when ODIN_ARCH == .amd64 {
	@(private)
	x86_has_invariant_tsc :: proc "contextless" () -> bool {
		eax, _, _, _ := intrinsics.x86_cpuid(0x80_000_000, 0)

		// Is this processor *really* ancient?
		if eax < 0x80_000_007 {
			return false
		}

		// check if the invariant TSC bit is set
		_, _, _, edx := intrinsics.x86_cpuid(0x80_000_007, 0)
		return (edx & (1 << 8)) != 0
	}
}

when ODIN_OS != .Darwin && ODIN_OS != .Linux && ODIN_OS != .FreeBSD {
	_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
		return 0, false
	}
}

/*
Check if the CPU has invariant TSC.

This procedure checks if the CPU contains an invariant TSC (Time stamp counter).
Invariant TSC is a feature of modern processors that allows them to run their
TSC at a fixed frequency, independent of ACPI state, and CPU frequency.
*/
has_invariant_tsc :: proc "contextless" () -> bool {
	when ODIN_ARCH == .amd64 {
		return x86_has_invariant_tsc()
	}

	return false
}

/*
Obtain the CPU's TSC frequency, in hertz.

This procedure tries to obtain the CPU's TSC frequency in hertz. If the CPU
doesn't have an invariant TSC, this procedure returns with an error. Otherwise
an attempt is made to fetch the TSC frequency from the OS. If this fails,
the frequency is obtained by sleeping for the specified amount of time and
dividing the readings from TSC by the duration of the sleep.

The duration of sleep can be controlled by `fallback_sleep` parameter.
*/
tsc_frequency :: proc "contextless" (fallback_sleep := 2 * Second) -> (u64, bool) {
	if !has_invariant_tsc() {
		return 0, false
	}

	hz, ok := _get_tsc_frequency()
	if !ok {
		// fallback to approximate TSC
		tsc_begin := intrinsics.read_cycle_counter()
		tick_begin := tick_now()

		sleep(fallback_sleep)

		tsc_end := intrinsics.read_cycle_counter()
		tick_end := tick_now()

		time_diff := u128(duration_nanoseconds(tick_diff(tick_begin, tick_end)))
		hz = u64((u128(tsc_end - tsc_begin) * 1_000_000_000) / time_diff)
	}

	return hz, true
}

// Benchmark helpers

/*
Errors returned by the `benchmark()` procedure.
*/
Benchmark_Error :: enum {
	Okay = 0,
	Allocation_Error,
}

/*
Options for benchmarking.
*/
Benchmark_Options :: struct {
	// The initialization procedure. `benchmark()` will call this before taking measurements.
	setup:     #type proc(options: ^Benchmark_Options, allocator: runtime.Allocator) -> (err: Benchmark_Error),
	// The procedure to benchmark.
	bench:     #type proc(options: ^Benchmark_Options, allocator: runtime.Allocator) -> (err: Benchmark_Error),
	// The deinitialization procedure.
	teardown:  #type proc(options: ^Benchmark_Options, allocator: runtime.Allocator) -> (err: Benchmark_Error),
	// Field to be used by `bench()` procedure for any purpose.
	rounds:    int,
	// Field to be used by `bench()` procedure for any purpose.
	bytes:     int,
	// Field to be used by `bench()` procedure for any purpose.
	input:     []u8,
	// `bench()` writes to specify the count of elements processed.
	count:     int,
	// `bench()` writes to specify the number of bytes processed.
	processed: int,
	// `bench()` can write the output slice here.
	output:    []u8, // Unused for hash benchmarks
	// `bench()` can write the output hash here.
	hash:      u128,
	// `benchmark()` procedure will output the duration of benchmark
	duration:             Duration,
	// `benchmark()` procedure will output the average count of elements
	// processed per second, using the `count` field of this struct.
	rounds_per_second:    f64,
	// `benchmark()` procedure will output the average number of megabytes
	// processed per second, using the `processed` field of this struct.
	megabytes_per_second: f64,
}

/*
Benchmark a procedure.

This procedure produces a benchmark. The procedure specified in the `bench`
field of the `options` parameter will be benchmarked. The following metrics
can be obtained:

- Run time of the procedure
- Number of elements per second processed on average
- Number of bytes per second this processed on average

In order to obtain these metrics, the `bench()` procedure writes to `options`
struct the number of elements or bytes it has processed.
*/
benchmark :: proc(options: ^Benchmark_Options, allocator := context.allocator) -> (err: Benchmark_Error) {
	assert(options != nil)
	assert(options.bench != nil)

	if options.setup != nil {
		options->setup(allocator) or_return
	}

	diff: Duration
	{
		SCOPED_TICK_DURATION(&diff)
		options->bench(allocator) or_return
	}
	options.duration = diff

	times_per_second            := f64(Second) / f64(diff)
	options.rounds_per_second    = times_per_second * f64(options.count)
	options.megabytes_per_second = f64(options.processed) / f64(1024 * 1024) * times_per_second

	if options.teardown != nil {
		options->teardown(allocator) or_return
	}
	return
}
