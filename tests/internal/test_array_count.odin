package test_internal

import "core:testing"

@(test)
array_count_from_integral_float :: proc(t: ^testing.T) {
	testing.expect_value(t, len([3.0]u8{}), 3)
	testing.expect_value(t, len([0.0]u8{}), 0)
	testing.expect_value(t, size_of([3.0]u32), 12)

	// folded constant expressions
	Halved :: 6.0 / 2.0
	Summed :: 1.5 + 1.5
	testing.expect_value(t, len([Halved]u8{}), 3)
	testing.expect_value(t, len([Summed]u8{}), 3)

	// 2^53, the largest integer an f64 holds exactly, on a zero-sized element
	testing.expect_value(t, len([9007199254740992.0]struct{}{}), 1 << 53)

	testing.expect_value(t, size_of(matrix[2.0, 3.0]f32), 24)
	testing.expect_value(t, size_of(#simd[4.0]u8), 4)

	Sparse :: [2.0]u8
	testing.expect_value(t, len(Sparse{1, 2}), 2)
}
