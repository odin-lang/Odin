package test_core_bytes

import "core:bytes"
import "core:slice"
import "core:testing"

@private SIMD_SCAN_WIDTH :: 8 * size_of(uintptr)

@test
test_index_byte_sanity :: proc(t: ^testing.T) {
	// We must be able to find the byte at the correct index.
	data := make([]u8, 2 * SIMD_SCAN_WIDTH)
	defer delete(data)
	slice.fill(data, '-')

	INDEX_MAX :: SIMD_SCAN_WIDTH - 1

	for offset in 0..<INDEX_MAX {
		for idx in 0..<INDEX_MAX {
			sub := data[offset:]
			sub[idx] = 'o'
			if !testing.expect_value(t, bytes.index_byte(sub, 'o'), idx) {
				return
			}
			if !testing.expect_value(t, bytes.last_index_byte(sub, 'o'), idx) {
				return
			}
			sub[idx] = '-'
		}
	}
}

@test
test_index_byte_empty :: proc(t: ^testing.T) {
	a: [1]u8
	testing.expect_value(t, bytes.index_byte(a[0:0], 'o'), -1)
	testing.expect_value(t, bytes.last_index_byte(a[0:0], 'o'), -1)
}

@test
test_index_byte_multiple_hits :: proc(t: ^testing.T) {
	for n in 5..<256 {
		data := make([]u8, n)
		defer delete(data)
		slice.fill(data, '-')

		data[n-1] = 'o'
		data[n-3] = 'o'
		data[n-5] = 'o'

		// Find the first one.
		if !testing.expect_value(t, bytes.index_byte(data, 'o'), n-5) {
			return
		}

		// Find the last one.
		if !testing.expect_value(t, bytes.last_index_byte(data, 'o'), n-1) {
			return
		}
	}
}

@test
test_index_byte_zero :: proc(t: ^testing.T) {
	// This test protects against false positives in uninitialized memory.
	for n in 1..<256 {
		data := make([]u8, n + 64)
		defer delete(data)
		slice.fill(data, '-')

		// Positive hit.
		data[n-1] = 0
		if !testing.expect_value(t, bytes.index_byte(data[:n], 0), n-1) {
			return
		}
		if !testing.expect_value(t, bytes.last_index_byte(data[:n], 0), n-1) {
			return
		}

		// Test for false positives.
		data[n-1] = '-'
		if !testing.expect_value(t, bytes.index_byte(data[:n], 0), -1) {
			return
		}
		if !testing.expect_value(t, bytes.last_index_byte(data[:n], 0), -1) {
			return
		}
	}
}
