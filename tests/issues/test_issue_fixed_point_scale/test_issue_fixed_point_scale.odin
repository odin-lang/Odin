// A signed fixed-point scale must be less than the bit width, which LLVM requires.
package test_issues

import "base:intrinsics"

main :: proc() {
	a, b: i32 = 3, 2
	c, d: i64 = 3, 2
	e, f: u64 = 3, 2

	// these 4 are errors
	_ = intrinsics.fixed_point_mul(a, b, 32)
	_ = intrinsics.fixed_point_div(c, d, 64)
	_ = intrinsics.fixed_point_mul_sat(c, d, 64)
	_ = intrinsics.fixed_point_div_sat(a, b, 32)

	// these are valid
	_ = intrinsics.fixed_point_mul(a, b, 31)
	_ = intrinsics.fixed_point_div(c, d, 63)
	_ = intrinsics.fixed_point_mul(e, f, 64)
	_ = intrinsics.fixed_point_div_sat(e, f, 64)
}
