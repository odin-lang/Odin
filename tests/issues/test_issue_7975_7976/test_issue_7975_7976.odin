// Tests issues #7975 https://github.com/odin-lang/Odin/issues/7975 and #7976 https://github.com/odin-lang/Odin/issues/7976
// Constant arguments to `min`, `max` and `clamp` are unified into a single type, as non-constant ones are
package test_issue_7975_7976

import "core:testing"

@(test)
test_constant_min_max_clamp :: proc(t: ^testing.T) {
	a := min(1, 2.5)
	b := max(3, 1.5)
	c := clamp(3, 0.5, 2)
	d := min("b", "string_literal")

	testing.expect_value(t, typeid_of(type_of(a)), f64)
	testing.expect_value(t, typeid_of(type_of(b)), f64)
	testing.expect_value(t, typeid_of(type_of(c)), f64)
	testing.expect_value(t, a, 1.0)
	testing.expect_value(t, b, 3.0)
	testing.expect_value(t, c, 2.0)
	testing.expect_value(t, d, "b")
}
