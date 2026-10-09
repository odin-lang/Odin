// Tests issue #4210 https://github.com/odin-lang/Odin/issues/4210
package test_issues

import "core:testing"
import "base:intrinsics"

@test
test_row_major_matrix :: proc(t: ^testing.T) {
	row_major34: #row_major matrix[3,4]int = {
		11,12,13,14,
		21,22,23,24,
		31,32,33,34,
	}
	row_major34_expected := [?]int{11,12,13,14, 21,22,23,24, 31,32,33,34}

	row_major43: #row_major matrix[4,3]int = {
		11,12,13,
		21,22,23,
		31,32,33,
		41,42,43,
	}
	row_major43_expected := [?]int{11,12,13, 21,22,23, 31,32,33, 41,42,43}

	major34_flattened := intrinsics.matrix_flatten(row_major34)
	major34_from_ptr  := intrinsics.unaligned_load((^[3 * 4]int)(&row_major34))

	for row in 0..<3 {
		for column in 0..<4 {
			idx := row * 4 + column
			testing.expect_value(t, major34_flattened[idx], row_major34_expected[idx])
			testing.expect_value(t, major34_from_ptr [idx], row_major34_expected[idx])
		}
	}

	major43_flattened := intrinsics.matrix_flatten(row_major43)
	major43_from_ptr  := intrinsics.unaligned_load((^[4 * 3]int)(&row_major43))

	for row in 0..<4 {
		for column in 0..<3 {
			idx := row * 3 + column
			testing.expect_value(t, major43_flattened[idx], row_major43_expected[idx])
			testing.expect_value(t, major43_from_ptr [idx], row_major43_expected[idx])
		}
	}
}

@test
test_row_minor_matrix :: proc(t: ^testing.T) {
	row_minor34: matrix[3,4]int = {
		11,12,13,14,
		21,22,23,24,
		31,32,33,34,
	}
	row_minor34_expected := [?]int{11,21,31, 12,22,32, 13,23,33, 14,24,34}

	row_minor43: matrix[4,3]int = {
		11,12,13,
		21,22,23,
		31,32,33,
		41,42,43,
	}
	row_minor43_expected := [?]int{11,21,31,41, 12,22,32,42, 13,23,33,43}

	minor34_flattened := intrinsics.matrix_flatten(row_minor34)
	minor34_from_ptr  := intrinsics.unaligned_load((^[3 * 4]int)(&row_minor34))

	for row in 0..<3 {
		for column in 0..<4 {
			idx := row * 4 + column
			testing.expect_value(t, minor34_flattened[idx], row_minor34_expected[idx])
			testing.expect_value(t, minor34_from_ptr [idx], row_minor34_expected[idx])
		}
	}

	minor43_flattened := intrinsics.matrix_flatten(row_minor43)
	minor43_from_ptr  := intrinsics.unaligned_load((^[4 * 3]int)(&row_minor43))

	for row in 0..<4 {
		for column in 0..<3 {
			idx := row * 3 + column
			testing.expect_value(t, minor43_flattened[idx], row_minor43_expected[idx])
			testing.expect_value(t, minor43_from_ptr [idx], row_minor43_expected[idx])
		}
	}
}