// Tests issue #7493 https://github.com/odin-lang/Odin/issues/7493
package test_issues

import "core:testing"

@(test)
test_issue_7493 :: proc(t: ^testing.T) {
	U :: bit_field u32be {
		high: u32be | 16,
		low:  u32be | 16,
	}
	u := U{high = 0x1234, low = 0x5678}
	testing.expect_value(t, u.high, 0x1234)
	testing.expect_value(t, u.low, 0x5678)

	S :: bit_field u32be {
		a: i32be | 16,
		b: i32be | 16,
	}
	s := S{a = -2, b = 0x1234}
	testing.expect_value(t, s.a, -2)
	testing.expect_value(t, s.b, 0x1234)
}
