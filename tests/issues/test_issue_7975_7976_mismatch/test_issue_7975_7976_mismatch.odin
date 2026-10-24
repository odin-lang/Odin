// Tests issues #7975 https://github.com/odin-lang/Odin/issues/7975 and #7976 https://github.com/odin-lang/Odin/issues/7976
// Constant arguments to `min`, `max` and `clamp` which cannot be unified into a single type must be rejected
package test_issue_7975_7976_mismatch

main :: proc() {
	_ = min(3.14, "string_literal")
	_ = max(42, "string_literal")
	_ = min('a', "b")
	_ = clamp(1.5, "string_test", 5.5)
	_ = clamp(1.5, 42, "string_test")
	_ = min(i32(1), u8(2))
	_ = max(3.5, i32(2))
	_ = clamp(i32(1), 2, u8(3))
}
