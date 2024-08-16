package test_core_runtime

import "base:intrinsics"
import "core:mem"
import "base:runtime"
import "core:slice"
import "core:testing"

// Tests that having space for the allocation, but not for the allocation and alignment
// is handled correctly.
@(test)
test_temp_allocator_alignment_boundary :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)

	_, _ = mem.alloc(int(runtime.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE)-120)
	_, err := mem.alloc(112, 32)
	testing.expect(t, err == nil)
}

// Tests that big allocations with big alignments are handled correctly.
@(test)
test_temp_allocator_big_alloc_and_alignment :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)

	mappy: map[[8]int]int
	err := reserve(&mappy, 50000)
	testing.expect(t, err == nil)
}

@(test)
test_temp_allocator_returns_correct_size :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)

	bytes, err := mem.alloc_bytes(10, 16)
	testing.expect(t, err == nil)
	testing.expect(t, len(bytes) == 10)
}

@(private)
SIMD_SCAN_WIDTH :: 8 * size_of(uintptr)

@(test)
test_memory_equal :: proc(t: ^testing.T) {
	data: [2 * SIMD_SCAN_WIDTH]u8
	cmp: [2 * SIMD_SCAN_WIDTH]u8

	slice.fill(data[:], 0xAA)
	slice.fill(cmp[:], 0xAA)

	INDEX_MAX :: SIMD_SCAN_WIDTH - 1

	for offset in 0..<INDEX_MAX {
		for idx in 0..<INDEX_MAX {
			subdata := data[offset:]
			subcmp := cmp[offset:]

			if !testing.expect_value(t, runtime.memory_equal(&data[0], &cmp[0], len(data)), true) {
				return
			}

			subcmp[idx] = 0x55
			if !testing.expect_value(t, runtime.memory_equal(&data[0], &cmp[0], len(data)), false) {
				return
			}
			subcmp[idx] = 0xAA
		}
	}
}

@(test)
test_memory_compare :: proc(t: ^testing.T) {
	data: [2 * SIMD_SCAN_WIDTH]u8
	cmp: [2 * SIMD_SCAN_WIDTH]u8

	INDEX_MAX :: SIMD_SCAN_WIDTH - 1

	for offset in 0..<INDEX_MAX {
		for idx in 0..<INDEX_MAX {
			subdata := data[offset:]
			subcmp := cmp[offset:]

			if !testing.expect_value(t, runtime.memory_compare(&data[0], &cmp[0], len(data)), 0) {
				return
			}

			subdata[idx] = 0x7F
			subcmp[idx] = 0xFF
			if !testing.expect_value(t, runtime.memory_compare(&data[0], &cmp[0], len(data)), -1) {
				return
			}

			subdata[idx] = 0xFF
			subcmp[idx] = 0x7F
			if !testing.expect_value(t, runtime.memory_compare(&data[0], &cmp[0], len(data)), 1) {
				return
			}

			subdata[idx] = 0
			subcmp[idx] = 0
		}
	}
}

@(test)
test_memory_compare_zero :: proc(t: ^testing.T) {
	data: [2 * SIMD_SCAN_WIDTH]u8

	INDEX_MAX :: SIMD_SCAN_WIDTH - 1

	for offset in 0..<INDEX_MAX {
		for idx in 0..<INDEX_MAX {
			sub := data[offset:]

			if !testing.expect_value(t, runtime.memory_compare_zero(&data[0], len(data)), 0) {
				return
			}
			sub[idx] = 0xFF
			if !testing.expect_value(t, runtime.memory_compare_zero(&data[0], len(data)), 1) {
				return
			}
			sub[idx] = 0
		}
	}
}
