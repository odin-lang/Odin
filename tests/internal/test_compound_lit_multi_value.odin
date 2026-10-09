package test_internal

import "core:testing"

// A multi-value call in a matrix or #simd literal fills as many elements as it returns,
// as it does in array and struct literals.

@(private="file")
three :: proc() -> (f32, f32, f32) { return 1, 2, 3 }

@(private="file")
two :: proc() -> (int, int) { return 7, 8 }

@(test)
matrix_literal_multi_value :: proc(t: ^testing.T) {
	m := matrix[2, 2]f32{three(), 4}
	testing.expect_value(t, m, matrix[2, 2]f32{1, 2, 3, 4})

	n := matrix[2, 2]f32{4, three()}
	testing.expect_value(t, n, matrix[2, 2]f32{4, 1, 2, 3})

	r := #row_major matrix[2, 3]f32{9, three(), 5, 6}
	testing.expect_value(t, r, #row_major matrix[2, 3]f32{9, 1, 2, 3, 5, 6})
}

@(test)
simd_literal_multi_value :: proc(t: ^testing.T) {
	a := #simd[4]int{two(), 5, 6}
	testing.expect_value(t, transmute([4]int)a, [4]int{7, 8, 5, 6})

	b := #simd[4]int{5, two(), 6}
	testing.expect_value(t, transmute([4]int)b, [4]int{5, 7, 8, 6})

	c := #simd[4]int{two(), 5}
	testing.expect_value(t, transmute([4]int)c, [4]int{7, 8, 5, 0})
}
