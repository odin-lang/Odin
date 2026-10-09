// Tests issue #6396 https://github.com/odin-lang/Odin/issues/6396
package test_issues

import "core:testing"

Issue6396_Full_Width_Field :: bit_field u32 {
	a: u32 | 32,
}

@test
test_issue_6396_full_width_bit_field_literal :: proc(t: ^testing.T) {
	f0: Issue6396_Full_Width_Field = {a = 7}
	testing.expect_value(t, f0.a, u32(7))

	f0 = {a = 3}
	testing.expect_value(t, f0.a, u32(3))

	f0 = Issue6396_Full_Width_Field{a = 11}
	testing.expect_value(t, f0.a, u32(11))

	f0.a = 12
	testing.expect_value(t, f0.a, u32(12))
}
