package test_core_math_fixed

import "base:intrinsics"
import "core:math/fixed"
import "core:testing"

@test
test_fixed_4_4_unsigned :: proc(t: ^testing.T) {
	I_SHIFT :: 4
	F_MASK  :: 15
	F_ULP   :: 0.0625
	Fixed   :: fixed.Fixed(u8, 4)

	for c in 0..<256 {
		raw := u8(c)
		fv  := transmute(Fixed)raw

		i := raw >> I_SHIFT
		f := raw &  F_MASK
		expected := f64(i) + F_ULP * f64(f)

		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(u8, 4)(%v) to equal %.5f, got %.5f", raw, expected, fixed.to_f64(fv))
	}
}

@test
test_fixed_4_4_signed :: proc(t: ^testing.T) {
	I_SHIFT :: 4
	F_MASK  :: 15
	F_ULP   :: 0.0625
	Fixed   :: fixed.Fixed(i8, 4)

	for c in 0..<256 {
		raw := i8(c)
		fv  := transmute(Fixed)raw

		f := raw & F_MASK
		expected: f64
		if c < 128 {
			i := raw >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		} else if c == 128 {
			expected = 8.0

		} else if c > 128 {
			i := i8(-8)
			i += (raw & 0b0111_0000) >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		}
		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(i8, 4)(%v, %v) to equal %.5f, got %.5f", c, raw, expected, fixed.to_f64(fv))
	}
}
// 64-bit division with a large scale needs a 128-bit dividend
@test
test_fixed_point_div_64 :: proc(t: ^testing.T) {
	floor_div :: proc(x, y: i64, scale: uint, sat: bool) -> i64 {
		n := i128(x) << scale
		q := n / i128(y)
		if r := n % i128(y); r != 0 && (r < 0) != (y < 0) {
			q -= 1
		}
		if sat {
			q = clamp(q, i128(min(i64)), i128(max(i64)))
		}
		return i64(q)
	}
	udiv :: proc(x, y: u64, scale: uint, sat: bool) -> u64 {
		q := (u128(x) << scale) / u128(y)
		if sat {
			q = min(q, u128(max(u64)))
		}
		return u64(q)
	}

	values := []i64{1, -1, 3, -7, 1<<40, -(1<<40), 123456789, -987654321, max(i64), min(i64)+1}
	for x in values {
		for y in values {
			testing.expect_value(t, intrinsics.fixed_point_div(x, y, 62),     floor_div(x, y, 62, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(x, y, 62), floor_div(x, y, 62, true))
			testing.expect_value(t, intrinsics.fixed_point_div(x, y, 32),     floor_div(x, y, 32, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(x, y, 32), floor_div(x, y, 32, true))

			ux, uy := u64(x), u64(y)
			testing.expect_value(t, intrinsics.fixed_point_div(ux, uy, 64),     udiv(ux, uy, 64, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(ux, uy, 64), udiv(ux, uy, 64, true))
			testing.expect_value(t, intrinsics.fixed_point_div(ux, uy, 32),     udiv(ux, uy, 32, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(ux, uy, 32), udiv(ux, uy, 32, true))
		}
	}
}
