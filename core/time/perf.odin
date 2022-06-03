package time

import "core:runtime"

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