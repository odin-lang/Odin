package benchmark_runtime

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:testing"
import "core:strings"
import "core:text/table"
import "core:time"

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
	1024 * 1024,
}

// These are the normal, unoptimized algorithms.

plain_memory_equal :: proc "contextless" (x, y: rawptr, n: int) -> bool {
	switch {
	case n == 0: return true
	case x == y: return true
	}
	a, b := ([^]byte)(x), ([^]byte)(y)
	length := uint(n)

	for i := uint(0); i < length; i += 1 {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

plain_memory_compare :: proc "contextless" (a, b: rawptr, n: int) -> int #no_bounds_check {
	switch {
	case a == b:   return 0
	case a == nil: return -1
	case b == nil: return +1
	}

	x := uintptr(a)
	y := uintptr(b)
	n := uintptr(n)

	SU :: size_of(uintptr)
	fast := n/SU + 1
	offset := (fast-1)*SU
	curr_block := uintptr(0)
	if n < SU {
		fast = 0
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^
		vb := (^uintptr)(y + curr_block * size_of(uintptr))^
		if va ~ vb != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^
				b := (^byte)(y+pos)^
				if a ~ b != 0 {
					return -1 if (int(a) - int(b)) < 0 else +1
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^
		b := (^byte)(y+offset)^
		if a ~ b != 0 {
			return -1 if (int(a) - int(b)) < 0 else +1
		}
	}

	return 0
}

plain_memory_compare_zero :: proc "contextless" (a: rawptr, n: int) -> int #no_bounds_check {
	x := uintptr(a)
	n := uintptr(n)

	SU :: size_of(uintptr)
	fast := n/SU + 1
	offset := (fast-1)*SU
	curr_block := uintptr(0)
	if n < SU {
		fast = 0
	}

	for /**/; curr_block < fast; curr_block += 1 {
		va := (^uintptr)(x + curr_block * size_of(uintptr))^
		if va ~ 0 != 0 {
			for pos := curr_block*SU; pos < n; pos += 1 {
				a := (^byte)(x+pos)^
				if a ~ 0 != 0 {
					return -1 if int(a) < 0 else +1
				}
			}
		}
	}

	for /**/; offset < n; offset += 1 {
		a := (^byte)(x+offset)^
		if a ~ 0 != 0 {
			return -1 if int(a) < 0 else +1
		}
	}

	return 0
}

run_trial_size_cmp :: proc(p: proc "contextless" (rawptr, rawptr, int) -> $R, size: int, idx: int, runs: int, loc := #caller_location) -> (timing: time.Duration) {
	left  := make([]u8, size)
	right := make([]u8, size)
	defer {
		delete(left)
		delete(right)
	}

	right[idx] = 0x01

	accumulator: int

	watch: time.Stopwatch

	time.stopwatch_start(&watch)
	for _ in 0..<runs {
		result := p(&left[0], &right[0], size)
		when R == bool {
			assert(result == false, loc = loc)
			accumulator += 1
		} else when R == int {
			assert(result == -1, loc = loc)
			accumulator += result
		}
	}
	time.stopwatch_stop(&watch)
	timing = time.stopwatch_duration(watch)

	log.debug(accumulator)
	return
}

run_trial_size_zero :: proc(p: proc "contextless" (rawptr, int) -> int, size: int, idx: int, runs: int, loc := #caller_location) -> (timing: time.Duration) {
	data := make([]u8, size)
	defer delete(data)

	data[idx] = 0x01

	accumulator: int

	watch: time.Stopwatch

	time.stopwatch_start(&watch)
	for _ in 0..<runs {
		result := p(&data[0], size)
		assert(result == 1, loc = loc)
		accumulator += result
	}
	time.stopwatch_stop(&watch)
	timing = time.stopwatch_duration(watch)

	log.debug(accumulator)
	return
}

run_trial_size :: proc {
	run_trial_size_cmp,
	run_trial_size_zero,
}


bench_table :: proc(algo_name: string, plain, simd: $P) {
	string_buffer := strings.builder_make()
	defer strings.builder_destroy(&string_buffer)

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Iterations", "Scalar", "SIMD", "SIMD Relative (%)", "SIMD Relative (x)")

	for size in sizes {
		// Place the non-zero byte somewhere in the middle.
		needle_index := size / 2

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
benchmark_memory_procs :: proc(t: ^testing.T) {
	bench_table("memory_equal", plain_memory_equal, runtime.memory_equal)
	bench_table("memory_compare", plain_memory_compare, runtime.memory_compare)
	bench_table("memory_compare_zero", plain_memory_compare_zero, runtime.memory_compare_zero)
}
