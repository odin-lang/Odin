package benchmark_bytes

import "core:bytes"
import "core:fmt"
import "core:log"
import "core:testing"
import "core:strings"
import "core:text/table"
import "core:time"

RUNS_PER_SIZE :: 2500

sizes := [?]int {
	15, 16, 17,
	31, 32, 33,
	63, 64, 65,
	128,
	256,
	512,
	1024,
	4096,
	1024 * 1024,
	// 1024 * 1024 * 1024,
}

// These are the normal, unoptimized algorithms.

plain_index_byte :: proc "contextless" (s: []u8, c: byte) -> (res: int) #no_bounds_check {
	for i := 0; i < len(s); i += 1 {
		if s[i] == c {
			return i
		}
	}
	return -1
}

plain_last_index_byte :: proc "contextless" (s: []u8, c: byte) -> (res: int) #no_bounds_check {
	for i := len(s)-1; i >= 0; i -= 1 {
		if s[i] == c {
			return i
		}
	}
	return -1
}

run_trial_size :: proc(p: proc "contextless" ([]u8, byte) -> int, size: int, idx: int, runs: int) -> (timing: time.Duration) {
	data := make([]u8, size)
	defer delete(data)

	for i in 0..<size {
		data[i] = u8('0' + i % 10)
	}
	data[idx] = 'z'

	accumulator: int

	for _ in 0..<runs {
		start := time.now()
		accumulator += p(data, 'z')
		done := time.since(start)
		timing += done
	}

	timing /= time.Duration(runs)

	log.debug(accumulator)
	return
}

bench_table :: proc(algo_name: string, forward: bool, plain: proc "contextless" ([]u8, byte) -> int, simd: proc "contextless" ([]u8, byte) -> int) {
	string_buffer := strings.builder_make()
	defer strings.builder_destroy(&string_buffer)

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	// table.caption(&tbl, "index_byte benchmark")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Iterations", "Scalar", "SIMD", "SIMD Relative (%)", "SIMD Relative (x)")

	for size in sizes {
		needle_index := size - 1 if forward else 0

		plain_timing := run_trial_size(plain, size, needle_index, RUNS_PER_SIZE)
		simd_timing  := run_trial_size(simd,  size, needle_index, RUNS_PER_SIZE)

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
benchmark_index_byte :: proc(t: ^testing.T) {
	bench_table("index_byte",      true,  plain_index_byte,      bytes.index_byte)
	// bench_table("last_index_byte", false, plain_last_index_byte, bytes.last_index_byte)
}

/*
@test
benchmark_simd_index_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(bytes.index_byte, size, size - 1, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
		timing = run_trial_size(bytes.last_index_byte, size, 0, HOT, HOT)
		report = fmt.tprintf("%s\n (last) +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}
*/