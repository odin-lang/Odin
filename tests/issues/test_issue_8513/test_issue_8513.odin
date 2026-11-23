package test_issue_8513

import "core:simd"
import "core:testing"

@(test)
test_shuffle_wider_than_operands :: proc(t: ^testing.T) {
	a := simd.i32x4{10, 11, 12, 13}
	b := simd.i32x4{20, 21, 22, 23}

	broadcast := simd.shuffle(a, a, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3)
	testing.expect_value(t, transmute([16]i32)broadcast, [16]i32{10, 11, 12, 13, 10, 11, 12, 13, 10, 11, 12, 13, 10, 11, 12, 13})

	mixed := simd.shuffle(a, b, 7, 0, 6, 1, 5, 2, 4, 3, 3, 4, 2, 5, 1, 6, 0, 7)
	testing.expect_value(t, transmute([16]i32)mixed, [16]i32{23, 10, 22, 11, 21, 12, 20, 13, 13, 20, 12, 21, 11, 22, 10, 23})

	q := simd.i64x2{-1, 2}
	pairs := simd.shuffle(q, q, 0, 1, 0, 1, 0, 1, 0, 1)
	testing.expect_value(t, transmute([8]i64)pairs, [8]i64{-1, 2, -1, 2, -1, 2, -1, 2})

	bytes := simd.u8x16{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
	wide := simd.shuffle(bytes, bytes,
		15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
		15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
		15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
		15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
	)
	got := transmute([64]u8)wide
	for i in 0 ..< 64 {
		testing.expect_value(t, got[i], u8(15 - i % 16))
	}
}
