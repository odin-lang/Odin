package test_issues

import "core:testing"

// Tests issue #1730 https://github.com/odin-lang/Odin/issues/1730
@(test)
test_issue_1730 :: proc(t: ^testing.T) {
	ll := [4]int{1, 2, 3, 4}
	for l, i in ll.yz {
		testing.expect(t, i <= 1)
		if i == 0 {
			testing.expect_value(t, l, 2)
		} else if i == 1 {
			testing.expect_value(t, l, 3)
		}
	}

	out: [4]int
	out.yz = ll.yz
	testing.expect_value(t, out, [4]int{0, 2, 3, 0})
}
