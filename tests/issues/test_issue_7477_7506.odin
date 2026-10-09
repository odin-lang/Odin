// Tests issues #7477 https://github.com/odin-lang/Odin/issues/7477
// and #7506 https://github.com/odin-lang/Odin/issues/7506
package test_issues

import "core:testing"

@(test)
test_issue_7477_7506 :: proc(t: ^testing.T) {
	a := [2][2]i32{{1, 2}, {3, 4}}
	testing.expect_value(t, cast([2][2]int)a, [2][2]int{{1, 2}, {3, 4}})

	b := [2][2]u64{{1, 2}, {3, 4}}
	testing.expect_value(t, cast([2][2]f64)b, [2][2]f64{{1, 2}, {3, 4}})

	// a shallower array is still broadcast to every element (#6642)
	c := [2]f32{1, 2}
	d: [2][2]f32 = c
	testing.expect_value(t, d, [2][2]f32{{1, 2}, {1, 2}})
}
