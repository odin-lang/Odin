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
		} else {
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

@test
test_init_from_f64 :: proc(t: ^testing.T) {
	Case :: struct($B: typeid) {
		val: f64,
		raw: B,
		ok:  bool,
	}
	check :: proc(t: ^testing.T, $B: typeid, $W: uint, cases: []Case(B)) {
		for c in cases {
			x: fixed.Fixed(B, W)
			ok := fixed.init_from_f64(&x, c.val)
			testing.expectf(t, x.i == c.raw && ok == c.ok, "Fixed(%v, %v) from %v: expected %v (%v), got %v (%v)", typeid_of(B), W, c.val, c.raw, c.ok, x.i, ok)
		}
	}

	INF :: 0h7ff0_0000_0000_0000
	NAN :: 0h7ff8_0000_0000_0000

	check(t, i8, 4, {
		{0,       0,    true},
		{1.5,     24,   true},
		{-1.5,    -24,  true},
		{1.99,    31,   true},
		{-1.99,   -31,  true},
		{0.03,    0,    true},
		{7.9375,  127,  true},
		{-8,      -128, true},
		{8,       127,  false},
		{-8.0625, -128, false},
		{1000,    127,  false},
		{-1e300,  -128, false},
		{INF,     127,  false},
		{-INF,    -128, false},
		{NAN,     0,    false},
	})
	check(t, u8, 4, {
		{15.9375, 255, true},
		{-0.03,   0,   true},
		{16,      255, false},
		{-0.0625, 0,   false},
		{NAN,     0,   false},
	})
	check(t, i64, 32, {
		{2147483647.5, 0x7fff_ffff_8000_0000, true},
		{-2147483648,  min(i64),              true},
		{2147483648,   max(i64),              false},
		{1e10,         max(i64),              false},
	})
	check(t, i128, 64, {
		{-9223372036854775808, min(i128), true},
		{9223372036854775808,  max(i128), false},
	})
	check(t, u128, 0, {
		{170141183460469231731687303715884105728, 170141183460469231731687303715884105728, true},
		{340282366920938463463374607431768211456, max(u128),                               false},
	})
	check(t, i32be, 16, {
		{1.5,    98304,     true},
		{-32769, min(i32be), false},
	})

	for c in 0..<256 {
		x := transmute(fixed.Fixed(i8, 4))i8(c)
		y: fixed.Fixed(i8, 4)
		ok := fixed.init_from_f64(&y, fixed.to_f64(x))
		testing.expectf(t, ok && x == y, "Fixed(i8, 4) round trip of %v: got %v (%v)", x.i, y.i, ok)

		ux := transmute(fixed.Fixed(u8, 4))u8(c)
		uy: fixed.Fixed(u8, 4)
		ok = fixed.init_from_f64(&uy, fixed.to_f64(ux))
		testing.expectf(t, ok && ux == uy, "Fixed(u8, 4) round trip of %v: got %v (%v)", ux.i, uy.i, ok)
	}
}
