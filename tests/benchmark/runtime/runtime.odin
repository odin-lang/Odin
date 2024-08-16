package benchmark_runtime

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:testing"
import "core:time"


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


sizes := [?]int {
	15, 16, 17,
	31, 32, 33,
	63, 64, 65,
	256,
	512,
	1024,
	1024 * 1024,
	1024 * 1024 * 1024,
}

run_trial_size :: proc(p: proc "contextless" (rawptr, int) -> int, size: int, warmup: int, runs: int) -> (timing: time.Duration) {
	data := make([]u8, size)
	defer delete(data)
	data[size - 1] = 1

	accumulator: int

	for _ in 0..<warmup {
		accumulator += p(&data[0], size)
	}

	for _ in 0..<runs {
		start := time.tick_now()
		accumulator += p(&data[0], size)
		done := time.tick_since(start)
		timing += done
	}

	timing /= time.Duration(runs)

	log.debug(accumulator)
	return
}

run_trial_size_compare :: proc(p: proc "contextless" (rawptr, rawptr, int) -> bool, size: int, warmup: int, runs: int) -> (timing: time.Duration) {
	data_a := make([]u8, size)
	data_b := make([]u8, size)
	defer {
		delete(data_a)
		delete(data_b)
	}
	data_a[size - 1] = 1
	data_b[size - 1] = 2

	accumulator: int

	for _ in 0..<warmup {
		val := p(&data_a[0], &data_b[0], size)
		if !val {
			accumulator += 1
		}
	}

	for _ in 0..<runs {
		start := time.tick_now()
		val := p(&data_a[0], &data_b[0], size)
		done := time.tick_since(start)
		if !val {
			accumulator += 1
		}
		timing += done
	}

	timing /= time.Duration(runs)

	log.debug(accumulator)
	return
}

run_trial_size_compare_int :: proc(p: proc "contextless" (rawptr, rawptr, int) -> int, size: int, warmup: int, runs: int) -> (timing: time.Duration) {
	data_a := make([]u8, size)
	data_b := make([]u8, size)
	defer {
		delete(data_a)
		delete(data_b)
	}
	data_a[size - 1] = 1
	data_b[size - 1] = 2

	accumulator: int

	for _ in 0..<warmup {
		accumulator += p(&data_a[0], &data_b[0], size)
	}

	for _ in 0..<runs {
		start := time.tick_now()
		accumulator += p(&data_a[0], &data_b[0], size)
		done := time.tick_since(start)
		timing += done
	}

	timing /= time.Duration(runs)

	log.debug(accumulator)
	return
}

HOT :: 3

/* Memory Equal */

@test
benchmark_plain_memory_equal_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare(plain_memory_equal, size, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_plain_memory_equal_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare(plain_memory_equal, size, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_memory_equal_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare(runtime.memory_equal, size, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_memory_equal_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare(runtime.memory_equal, size, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

/* Memory Compare */

@test
benchmark_plain_memory_compare_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare_int(plain_memory_compare, size, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_plain_memory_compare_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare_int(plain_memory_compare, size, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_memory_compare_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare_int(runtime.memory_compare, size, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_memory_compare_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size_compare_int(runtime.memory_compare, size, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

/* Memory Compare Zero */

@test
benchmark_plain_memory_compare_zero_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(plain_memory_compare_zero, size, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_plain_memory_compare_zero_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(plain_memory_compare_zero, size, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_memory_compare_zero_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(runtime.memory_compare_zero, size, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_memory_compare_zero_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(runtime.memory_compare_zero, size, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}
