//+build i386, amd64
package test_core_simd_util

import simd_util "core:simd/util"
import "core:testing"

@test
test_index_byte_sanity :: proc(t: ^testing.T) {
	// We must be able to find the byte at the correct index.
	for n in 1..<256 {
		data := make([]u8, n)
		defer delete(data)
		for i in 0..<n-1 {
			data[i] = '-'
		}

		// Find it at the end.
		data[n-1] = 'o'
		if !testing.expect_value(t, simd_util.index_byte(data, 'o'), n-1) {
			return
		}
		if !testing.expect_value(t, simd_util.last_index_byte(data, 'o'), n-1) {
			return
		}
		data[n-1] = '-'

		// Find it in the middle.
		data[n/2] = 'o'
		if !testing.expect_value(t, simd_util.index_byte(data, 'o'), n/2) {
			return
		}
		if !testing.expect_value(t, simd_util.last_index_byte(data, 'o'), n/2) {
			return
		}
		data[n/2] = '-'

		// Find it at the start.
		data[0] = 'o'
		if !testing.expect_value(t, simd_util.index_byte(data, 'o'), 0) {
			return
		}
		if !testing.expect_value(t, simd_util.last_index_byte(data, 'o'), 0) {
			return
		}
	}
}

@test
test_index_byte_empty :: proc(t: ^testing.T) {
	a: [1]u8
	testing.expect_value(t, simd_util.index_byte(a[0:0], 'o'), -1)
	testing.expect_value(t, simd_util.last_index_byte(a[0:0], 'o'), -1)
}

@test
test_index_byte_multiple_hits :: proc(t: ^testing.T) {
	for n in 5..<256 {
		data := make([]u8, n)
		defer delete(data)
		for i in 0..<n-1 {
			data[i] = '-'
		}

		data[n-1] = 'o'
		data[n-3] = 'o'
		data[n-5] = 'o'

		// Find the first one.
		if !testing.expect_value(t, simd_util.index_byte(data, 'o'), n-5) {
			return
		}

		// Find the last one.
		if !testing.expect_value(t, simd_util.last_index_byte(data, 'o'), n-1) {
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
		for i in 0..<n-1 {
			data[i] = '-'
		}

		// Positive hit.
		data[n-1] = 0
		if !testing.expect_value(t, simd_util.index_byte(data[:n], 0), n-1) {
			return
		}
		if !testing.expect_value(t, simd_util.last_index_byte(data[:n], 0), n-1) {
			return
		}

		// Test for false positives.
		data[n-1] = '-'
		if !testing.expect_value(t, simd_util.index_byte(data[:n], 0), -1) {
			return
		}
		if !testing.expect_value(t, simd_util.last_index_byte(data[:n], 0), -1) {
			return
		}
	}
}
