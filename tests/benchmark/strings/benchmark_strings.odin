package benchmark_strings

import "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:testing"
import "core:strings"
import "core:text/table"
import "core:time"
import "core:unicode/utf8"

RUNS_PER_SIZE :: 2500

sizes := [?]int {
	7, 8, 9,
	15, 16, 17,
	31, 32, 33,
	63, 64, 65,
	95, 96, 97,
	128,
	256,
	512,
	1024,
	4096,
}

// These are the normal, unoptimized algorithms.

plain_prefix_length :: proc "contextless" (a, b: string) -> (n: int) {
	_len := min(len(a), len(b))

	// Scan for matches including partial codepoints.
	#no_bounds_check for n < _len && a[n] == b[n] {
		n += 1
	}

	// Now scan to ignore partial codepoints.
	if n > 0 {
		s := a[:n]
		n = 0
		for {
			r0, w := utf8.decode_rune(s[n:])
			if r0 != utf8.RUNE_ERROR {
				n += w
			} else {
				break
			}
		}
	}
	return
}

run_trial_size_prefix :: proc(p: proc "contextless" (string, string) -> $R, suffix: string, size: int, idx: int, runs: int, loc := #caller_location) -> (timing: time.Duration) {
	left  := make([]u8, size)
	right := make([]u8, size)
	defer {
		delete(left)
		delete(right)
	}

	if len(suffix) > 0 {
		copy(left [idx:], suffix)
		copy(right[idx:], suffix)

	} else {
		right[idx] = 'A'
	}

	accumulator: int

	watch: time.Stopwatch

	time.stopwatch_start(&watch)
	for _ in 0..<runs {
		result := p(string(left[:size]), string(right[:size]))
		accumulator += result
	}
	time.stopwatch_stop(&watch)
	timing = time.stopwatch_duration(watch)

	log.debug(accumulator)
	return
}

run_trial_size :: proc {
	run_trial_size_prefix,
}

bench_table_size :: proc(algo_name: string, plain, simd: $P, suffix := "") {
	string_buffer := strings.builder_make()
	defer strings.builder_destroy(&string_buffer)

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Iterations", "Scalar", "SIMD", "SIMD Relative (%)", "SIMD Relative (x)")

	for size in sizes {
		// Place the non-zero byte somewhere in the middle.
		needle_index := size / 2

		plain_timing := run_trial_size(plain, suffix, size, needle_index, RUNS_PER_SIZE)
		simd_timing  := run_trial_size(simd,  suffix, size, needle_index, RUNS_PER_SIZE)

		_plain := fmt.tprintf("%8M",  plain_timing)
		_simd  := fmt.tprintf("%8M",  simd_timing)
		_relp  := fmt.tprintf("%.3f %%", f64(simd_timing) / f64(plain_timing) * 100.0)
		_relx  := fmt.tprintf("%.3f x",  1 / (f64(simd_timing) / f64(plain_timing)))

		table.aligned_row_of_values(
			&tbl,
			.Right,
			algo_name,
			size, RUNS_PER_SIZE, _plain, _simd, _relp, _relx)
	}

	builder_writer := strings.to_writer(&string_buffer)

	fmt.sbprintln(&string_buffer)
	table.write_plain_table(builder_writer, &tbl)

	my_table_string := strings.to_string(string_buffer)
	log.info(my_table_string)
}

@test
benchmark_memory_procs :: proc(t: ^testing.T) {
	bench_table_size("prefix_length ascii",   plain_prefix_length, strings.prefix_length)
	bench_table_size("prefix_length unicode", plain_prefix_length, strings.prefix_length, "🦉")
}