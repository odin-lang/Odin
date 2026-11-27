package test_internal

import "core:testing"

// `x.s op= y` behaves like `x.s = x.s op y`. Every element is read before any store,
// and a component repeated in the swizzle keeps its last occurrence.

@(test)
test_swizzle_compound_assign_repeated :: proc(t: ^testing.T) {
	a := [2]f64{1, 2}
	a.xxy += {10, 20, 30}
	testing.expect_value(t, a, [2]f64{21, 32})

	b := [4]i32{1, 2, 3, 4}
	b.wxw -= {10, 20, 30}
	testing.expect_value(t, b, [4]i32{-19, 2, 3, -26})

	c := [3]i32{1, 2, 3}
	swizzle(c, 2, 2, 0) *= {5, 7, 11}
	testing.expect_value(t, c, [3]i32{11, 2, 21})
}

@(test)
test_swizzle_compound_assign_large :: proc(t: ^testing.T) {
	// more than four indices
	a := [8]f32{1, 2, 3, 4, 5, 6, 7, 8}
	swizzle(a, 7, 6, 5, 4, 3, 2, 1, 0) += 100
	testing.expect_value(t, a, [8]f32{101, 102, 103, 104, 105, 106, 107, 108})

	b := [8]i32{1, 2, 3, 4, 5, 6, 7, 8}
	swizzle(b, 7, 6, 5, 4, 3, 2, 1, 0) -= {1, 2, 3, 4, 5, 6, 7, 8}
	testing.expect_value(t, b, [8]i32{-7, -5, -3, -1, 1, 3, 5, 7})

	// more indices than the array has elements, with repeats
	c := [2]i32{1, 2}
	swizzle(c, 0, 1, 0, 1, 0) += {10, 20, 30, 40, 50}
	testing.expect_value(t, c, [2]i32{51, 42})

	// more than four elements in the array, with repeats
	d := [6]i32{1, 2, 3, 4, 5, 6}
	swizzle(d, 5, 0, 5) *= {2, 3, 4}
	testing.expect_value(t, d, [6]i32{3, 2, 3, 4, 5, 24})
}

@(test)
test_swizzle_assign_large_self :: proc(t: ^testing.T) {
	a := [8]f32{1, 2, 3, 4, 5, 6, 7, 8}
	swizzle(a, 7, 6, 5, 4, 3, 2, 1, 0) = a
	testing.expect_value(t, a, [8]f32{8, 7, 6, 5, 4, 3, 2, 1})

	b := [6]i32{1, 2, 3, 4, 5, 6}
	swizzle(b, 1, 2, 3, 4, 5, 0) = b
	testing.expect_value(t, b, [6]i32{6, 1, 2, 3, 4, 5})
}
