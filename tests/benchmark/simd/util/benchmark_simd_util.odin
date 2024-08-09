package benchmark_simd_util

import "core:fmt"
import "core:log"
import simd_util "core:simd/util"
import "core:testing"
import "core:time"


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

sizes := [?]int {
	15, 16, 17,
	31, 32, 33,
	256,
	512,
	1024,
	1024 * 1024,
	1024 * 1024 * 1024,
}

run_trial_size :: proc(p: proc "contextless" ([]u8, byte) -> int, size: int, idx: int, warmup: int, runs: int) -> (timing: time.Duration) {
	data := make([]u8, size)
	defer delete(data)

	for i in 0..<size {
		data[i] = u8('0' + i % 10)
	}
	data[idx] = 'z'

	accumulator: int

	for _ in 0..<warmup {
		accumulator += p(data, 'z')
	}

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

HOT :: 3

@test
benchmark_plain_index_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(plain_index_byte, size, size - 1, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
		timing = run_trial_size(plain_last_index_byte, size, 0, 0, 1)
		report = fmt.tprintf("%s\n (last) +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_plain_index_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(plain_index_byte, size, size - 1, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
		timing = run_trial_size(plain_last_index_byte, size, 0, HOT, HOT)
		report = fmt.tprintf("%s\n (last) +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_index_cold :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(simd_util.index_byte, size, size - 1, 0, 1)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
		timing = run_trial_size(simd_util.last_index_byte, size, 0, 0, 1)
		report = fmt.tprintf("%s\n (last) +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}

@test
benchmark_simd_index_hot :: proc(t: ^testing.T) {
	report: string
	for size in sizes {
		timing := run_trial_size(simd_util.index_byte, size, size - 1, HOT, HOT)
		report = fmt.tprintf("%s\n        +++ % 8M | %v", report, size, timing)
		timing = run_trial_size(simd_util.last_index_byte, size, 0, HOT, HOT)
		report = fmt.tprintf("%s\n (last) +++ % 8M | %v", report, size, timing)
	}
	log.info(report)
}
