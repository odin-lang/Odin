package time

import "base:runtime"
import "base:intrinsics"

Tick :: struct {
	_nsec: i64, // relative amount
}
tick_now :: proc "contextless" () -> Tick {
	return _tick_now()
}

tick_diff :: proc "contextless" (start, end: Tick) -> Duration {
	d := end._nsec - start._nsec
	return Duration(d)
}

tick_lap_time :: proc "contextless" (prev: ^Tick) -> Duration {
	d: Duration
	t := tick_now()
	if prev._nsec != 0 {
		d = tick_diff(prev^, t)
	}
	prev^ = t
	return d
}

tick_since :: proc "contextless" (start: Tick) -> Duration {
	return tick_diff(start, tick_now())
}


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

has_invariant_tsc :: proc "contextless" () -> bool {
	when ODIN_ARCH == .amd64 {
		return x86_has_invariant_tsc()
	}

	return false
}

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

/*
	Benchmark helpers
*/

Benchmark_Error :: enum {
	Okay = 0,
	Allocation_Error,
}

Benchmark_Options :: struct {
	setup:     #type proc(options: ^Benchmark_Options, allocator: runtime.Allocator) -> (err: Benchmark_Error),
	bench:     #type proc(options: ^Benchmark_Options, allocator: runtime.Allocator) -> (err: Benchmark_Error),
	teardown:  #type proc(options: ^Benchmark_Options, allocator: runtime.Allocator) -> (err: Benchmark_Error),

	rounds:    int,
	bytes:     int,
	input:     []u8,

	count:     int,
	processed: int,
	output:    []u8, // Unused for hash benchmarks
	hash:      u128,

	/*
		Performance
	*/
	duration:             Duration,
	rounds_per_second:    f64,
	megabytes_per_second: f64,
}

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
