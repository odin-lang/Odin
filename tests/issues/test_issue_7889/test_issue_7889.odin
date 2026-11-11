package test_issue_7889

import "core:testing"

// Indexing a swizzle, or taking a selector of one, asked the backend for the swizzle's pointer, which it does
// not have, and crashed the compiler. An index now reads from a copy of the swizzle, as it is never assignable,
// while a selector maps onto the swizzled variable so that it can still be assigned through.

@(test)
test_index_swizzle :: proc(t: ^testing.T) {
	m := matrix[2, 2]f32{
		1, 2,
		3, 4,
	}
	arr := [2]int{0, 1}
	testing.expect_value(t, m[arr.yx[0], arr.xx[1]], 3)

	a := [4]int{10, 11, 12, 13}
	i := 2
	p := &a
	testing.expect_value(t, a.wzyx[0], 13)
	testing.expect_value(t, a.wzyx[i], 11)
	testing.expect_value(t, p.zx[1], 10)
	testing.expect_value(t, swizzle(a, 3, 2, 1)[1], 12)

	b := [6]int{0, 1, 2, 3, 4, 5}
	testing.expect_value(t, swizzle(b, 5, 4, 3, 2, 1)[1], 4)

	nested := [2][2]int{{1, 2}, {3, 4}}
	testing.expect_value(t, nested.yx[0][1], 4)
}

@(test)
test_swizzle_of_swizzle :: proc(t: ^testing.T) {
	c := [3]int{0, 1, 2}
	testing.expect_value(t, c.zyx.x, 2)
	testing.expect_value(t, c.zyx.yx, [2]int{1, 2})
	c.zyx.x = 7
	testing.expect_value(t, c, [3]int{0, 1, 7})
	c.zyx.xy = {8, 9}
	testing.expect_value(t, c, [3]int{0, 9, 8})

	b := [6]int{0, 1, 2, 3, 4, 5}
	testing.expect_value(t, swizzle(b, 5, 4, 3).y, 4)
	testing.expect_value(t, swizzle(b, 5, 4, 3).zx, [2]int{3, 5})
	swizzle(b, 5, 4, 3).x = 50
	testing.expect_value(t, b[5], 50)
}

@(test)
test_soa_swizzle :: proc(t: ^testing.T) {
	s := #soa[2][3]int{}
	s[1] = {0, 1, 2}
	testing.expect_value(t, s[1].zyx[0], 2)
	testing.expect_value(t, s[1].zyx.x, 2)
	testing.expect_value(t, s[1].zyx.yx, [2]int{1, 2})
	s[1].zyx.x = 7
	testing.expect_value(t, s[1], [3]int{0, 1, 7})
	s[1].zyx.xy = {8, 9}
	testing.expect_value(t, s[1], [3]int{0, 9, 8})
}
