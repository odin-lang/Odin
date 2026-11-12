package test_core_math_fixed

import "base:intrinsics"
import "core:math/fixed"
import "core:testing"

@test
test_floor_ceil_round_8 :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $B: typeid, $FW: uint) {
		s := i32(1) << FW
		for c in 0..<256 {
			x := fixed.Fixed(B, FW){B(c)}
			v := i32(x.i)
			f := (v - v %% s) / s
			want_ceil  := f + i32(v %% s != 0)
			want_round := f + i32(2 * (v %% s) >= s)
			testing.expectf(t, i32(fixed.floor(x)) == f, "Fixed(%v, %v) floor(%v) = %v, want %v", typeid_of(B), FW, v, fixed.floor(x), f)
			testing.expectf(t, i32(fixed.ceil(x)) == want_ceil, "Fixed(%v, %v) ceil(%v) = %v, want %v", typeid_of(B), FW, v, fixed.ceil(x), want_ceil)
			testing.expectf(t, i32(fixed.round(x)) == want_round, "Fixed(%v, %v) round(%v) = %v, want %v", typeid_of(B), FW, v, fixed.round(x), want_round)
		}
	}
	check(t, i8, 0)
	check(t, i8, 1)
	check(t, i8, 2)
	check(t, i8, 4)
	check(t, i8, 7)
	check(t, u8, 0)
	check(t, u8, 1)
	check(t, u8, 4)
	check(t, u8, 7)
	check(t, u8, 8)
}

@test
test_floor_ceil_round_limits :: proc(t: ^testing.T) {
	ONE_AND_A_HALF :: 3 << 15
	x := fixed.Fixed16_16{ONE_AND_A_HALF}
	testing.expect_value(t, fixed.floor(x), 1)
	testing.expect_value(t, fixed.ceil(x),  2)
	testing.expect_value(t, fixed.round(x), 2)

	x = fixed.Fixed16_16{-ONE_AND_A_HALF}
	testing.expect_value(t, fixed.floor(x), -2)
	testing.expect_value(t, fixed.ceil(x),  -1)
	testing.expect_value(t, fixed.round(x), -1)

	x = fixed.Fixed16_16{-(1 << 16)}
	testing.expect_value(t, fixed.floor(x), -1)
	testing.expect_value(t, fixed.ceil(x),  -1)
	testing.expect_value(t, fixed.round(x), -1)

	x = fixed.Fixed16_16{max(i32)}
	testing.expect_value(t, fixed.floor(x), 32767)
	testing.expect_value(t, fixed.ceil(x),  32768)
	testing.expect_value(t, fixed.round(x), 32768)

	x = fixed.Fixed16_16{min(i32)}
	testing.expect_value(t, fixed.floor(x), -32768)
	testing.expect_value(t, fixed.ceil(x),  -32768)
	testing.expect_value(t, fixed.round(x), -32768)

	y := fixed.Fixed(i64, 63){max(i64)}
	testing.expect_value(t, fixed.floor(y), 0)
	testing.expect_value(t, fixed.ceil(y),  1)
	testing.expect_value(t, fixed.round(y), 1)

	z := fixed.Fixed(u128, 128){max(u128)}
	testing.expect_value(t, fixed.floor(z), 0)
	testing.expect_value(t, fixed.ceil(z),  1)
	testing.expect_value(t, fixed.round(z), 1)
}

@test
test_write_long :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, x: $T/fixed.Fixed($B, $FW), want: string, loc := #caller_location) {
		s := fixed.to_string(x, context.temp_allocator)
		testing.expectf(t, s == want, "Fixed(%v, %v)(%v) = %q, want %q", typeid_of(B), FW, x.i, s, want, loc = loc)
	}
	check(t, fixed.Fixed(u64, 64){max(u64)}, "0.9999999999999999999457898913757247782996273599565029144287109375")
	check(t, fixed.Fixed(i64, 40){min(i64) + 1}, "-8388607.9999999999990905052982270717620849609375")
	check(t, fixed.Fixed(i64, 40){-1}, "-0.0000000000009094947017729282379150390625")
	check(t, fixed.Fixed(u128, 128){1}, "0.00000000000000000000000000000000000000293873587705571876992184134305561419454666389193021880377187926569604314863681793212890625")
	check(t, fixed.Fixed(u128, 125){max(u128)}, "7.99999999999999999999999999999999999997649011298355424984062526925555508644362668886455824956982496587443165481090545654296875")
	check(t, fixed.Fixed(u128, 0){max(u128)}, "340282366920938463463374607431768211455")
	check(t, fixed.Fixed(i128, 64){min(i128)}, "-9223372036854775808")
	check(t, fixed.Fixed(i128, 127){min(i128)}, "-1")
	check(t, fixed.Fixed(i8, 7){min(i8)}, "-1")
	check(t, fixed.Fixed(i8, 0){min(i8)}, "-128")
}

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
