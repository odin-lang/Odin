package test_core_math_fixed

import "base:intrinsics"
import "core:math/fixed"
import "core:testing"

@test
test_mul_div_8 :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $B: typeid, $FW: uint) {
		LO :: i32(min(B))
		HI :: i32(max(B))
		for a in 0..<256 {
			for b in 0..<256 {
				x := fixed.Fixed(B, FW){B(a)}
				y := fixed.Fixed(B, FW){B(b)}
				u, v := i32(x.i), i32(y.i)
				m := (u * v) >> FW
				testing.expectf(t, i32(fixed.mul(x, y).i) == i32(B(m)), "Fixed(%v, %v) mul(%v, %v) = %v, want %v", typeid_of(B), FW, u, v, fixed.mul(x, y).i, B(m))
				testing.expectf(t, i32(fixed.mul_sat(x, y).i) == clamp(m, LO, HI), "Fixed(%v, %v) mul_sat(%v, %v) = %v, want %v", typeid_of(B), FW, u, v, fixed.mul_sat(x, y).i, clamp(m, LO, HI))
				if v == 0 {
					continue
				}
				n := u << FW
				d := (n - n %% v) / v
				testing.expectf(t, i32(fixed.div(x, y).i) == i32(B(d)), "Fixed(%v, %v) div(%v, %v) = %v, want %v", typeid_of(B), FW, u, v, fixed.div(x, y).i, B(d))
				testing.expectf(t, i32(fixed.div_sat(x, y).i) == clamp(d, LO, HI), "Fixed(%v, %v) div_sat(%v, %v) = %v, want %v", typeid_of(B), FW, u, v, fixed.div_sat(x, y).i, clamp(d, LO, HI))
			}
		}
	}
	check(t, i8, 0)
	check(t, i8, 1)
	check(t, i8, 4)
	check(t, i8, 7)
	check(t, u8, 0)
	check(t, u8, 1)
	check(t, u8, 4)
	check(t, u8, 8)
}

@test
test_mul_div_wide :: proc(t: ^testing.T) {
	testing.expect_value(t, intrinsics.fixed_point_div_sat(i32(1 << 29), i32(3 << 28), 31), 1431655765)
	testing.expect_value(t, intrinsics.fixed_point_div_sat(u32(max(u32) - 3), u32(1 << 31), 32), max(u32))
	testing.expect_value(t, intrinsics.fixed_point_mul_sat(u64(5 << 61), u64(566489329403328680), 61), 2832446647016643400)

	testing.expect_value(t, intrinsics.fixed_point_div(i128(3) << 64, i128(5) << 63, 64), 22136092888451461939)
	testing.expect_value(t, intrinsics.fixed_point_div(-(i128(7) << 64), i128(3) << 64, 64), -43042402838655620438)
	testing.expect_value(t, intrinsics.fixed_point_div_sat(min(i128), i128(-1), 64), max(i128))
	testing.expect_value(t, intrinsics.fixed_point_div(u128(3) << 64, u128(5) << 63, 64), 22136092888451461939)
	testing.expect_value(t, intrinsics.fixed_point_mul(i128(-3) << 63, i128(5) << 63, 64), -(i128(15) << 62))

	testing.expect_value(t, intrinsics.fixed_point_mul(i64(-7), i64(3), 0), -21)
	testing.expect_value(t, intrinsics.fixed_point_div(i64(-7), i64(2), 0), -4)
	testing.expect_value(t, intrinsics.fixed_point_mul_sat(max(i64), i64(2), 0), max(i64))
	testing.expect_value(t, intrinsics.fixed_point_div_sat(u64(7), u64(2), 0), 3)
}
