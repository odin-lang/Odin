// Tests issue #7587 https://github.com/odin-lang/Odin/issues/7587
package test_issues

import "core:testing"

@(test)
test_issue_7587 :: proc(t: ^testing.T) {
	v := [4]f32{1, 2, 3, 4}
	p := &v

	w := p.wzyx
	testing.expect_value(t, w, [4]f32{4, 3, 2, 1})

	p.wzyx = {1, 2, 3, 4}
	testing.expect_value(t, v, [4]f32{4, 3, 2, 1})
}
