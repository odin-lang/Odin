package test_core_math

import "base:intrinsics"
import "core:math"
import "core:testing"

@(private="file")
same :: proc(got, want: $T) -> bool where intrinsics.type_is_float(T) {
	if math.is_nan(want) {
		return math.is_nan(got)
	}
	return got == want && math.sign_bit(got) == math.sign_bit(want)
}

@(private="file")
within_ulps :: proc(got, want: $T, max_ulps: i64 = 2) -> bool where intrinsics.type_is_float(T) {
	if math.is_nan(want) || math.is_inf(want) || want == 0 {
		return same(got, want)
	}
	if math.is_nan(got) || math.is_inf(got) || math.sign_bit(got) != math.sign_bit(want) {
		return false
	}
	when size_of(T) == 2 {
		g, w := i64(transmute(u16)abs(got)), i64(transmute(u16)abs(want))
	} else when size_of(T) == 4 {
		g, w := i64(transmute(u32)abs(got)), i64(transmute(u32)abs(want))
	} else {
		g, w := i64(transmute(u64)abs(got)), i64(transmute(u64)abs(want))
	}
	return abs(g - w) <= max_ulps
}

@(private="file")
Binary_Case :: struct {
	x, y, want: f64,
}

@test
test_mod_exact :: proc(t: ^testing.T) {
	cases := [?]Binary_Case{
		{1e17, 3, 1},
		{1e308, 1e-308, 3.498445546245627e-309},
		{-7, 3, -1},
		{7, -3, 1},
		{-7, -3, -1},
		{5.5, 2, 1.5},
		{-6, 3, -0.0},
		{6, -3, 0},
		{3, 1e308, 3},
		{math.F64_MAX, 3, 2},
		{math.F64_MAX, 1e-300, 2.589523889680434e-302},
		{math.F64_MAX, 5e-324, 0},
		{2.5e-323, 1.5e-323, 1e-323},
		{1, 1.5e-323, 5e-324},
		{math.F64_MIN, 1.5e-323, 5e-324},
		{-math.F64_MIN, 7e-310, -5.5073858507208e-310},
		{1e-310, 7e-311, 3e-311},
	}
	for c in cases {
		got := math.mod(c.x, c.y)
		testing.expectf(t, same(got, c.want), "mod(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_mod_specials :: proc(t: ^testing.T) {
	inf, ninf, nan := math.INF_F64, math.NEG_INF_F64, math.QNAN_F64
	cases := [?]Binary_Case{
		{0, 3, 0},
		{-0.0, 3, -0.0},
		{0, inf, 0},
		{-0.0, ninf, -0.0},
		{5, inf, 5},
		{-5, inf, -5},
		{5, ninf, 5},
		{inf, 3, nan},
		{ninf, 3, nan},
		{inf, inf, nan},
		{3, 0, nan},
		{3, -0.0, nan},
		{0, 0, nan},
		{nan, 3, nan},
		{3, nan, nan},
		{nan, inf, nan},
		{inf, nan, nan},
	}
	for c in cases {
		got := math.mod(c.x, c.y)
		testing.expectf(t, same(got, c.want), "mod(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_mod_narrow :: proc(t: ^testing.T) {
	testing.expect(t, same(math.mod(f32(1e10), 3), f32(1)))
	testing.expect(t, same(math.mod(f32(-1e10), 3), f32(-1)))
	testing.expect(t, same(math.mod(f32(3.4028234663852886e38), 3), f32(0)))
	testing.expect(t, same(math.mod(f32le(1e10), 3), f32le(1)))
	testing.expect(t, same(math.mod(f16(65504), 3), f16(2)))
	testing.expect(t, same(math.mod(f16(1000), 7), f16(6)))
	testing.expect(t, same(math.mod(f16(-6), 3), f16(-0.0)))
	testing.expect(t, same(math.mod(f16be(1000), 7), f16be(6)))
	testing.expect(t, same(math.mod(f64be(1e17), 3), f64be(1)))
}

@test
test_remainder_exact :: proc(t: ^testing.T) {
	cases := [?]Binary_Case{
		{5, 2, 1},
		{3, 2, -1},
		{-5, 2, -1},
		{7, 2, -1},
		{1, 2, 1},
		{-1, 2, -1},
		{6, 3, 0},
		{-6, 3, -0.0},
		{1e17, 3, 1},
		{3, 1e308, 3},
		{math.F64_MAX, 3, -1},
		{math.F64_MAX, 5.992310449541053e307, -9.9792015476736e291},
		{math.F64_MAX, 1e308, -2.0230686513768431e307},
		{-math.F64_MAX, 1e308, 2.0230686513768431e307},
		{1e308, 1e-308, 3.498445546245627e-309},
		{2.5e-323, 1e-323, 5e-324},
		{3.5e-323, 1e-323, -5e-324},
		{math.F64_MIN, 1.5e-323, 5e-324},
	}
	for c in cases {
		got := math.remainder(c.x, c.y)
		testing.expectf(t, same(got, c.want), "remainder(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_remainder_specials :: proc(t: ^testing.T) {
	inf, ninf, nan := math.INF_F64, math.NEG_INF_F64, math.QNAN_F64
	cases := [?]Binary_Case{
		{0, 3, 0},
		{-0.0, 3, -0.0},
		{-0.0, -3, -0.0},
		{0, inf, 0},
		{-0.0, ninf, -0.0},
		{5, inf, 5},
		{-5, ninf, -5},
		{inf, 3, nan},
		{ninf, 3, nan},
		{inf, inf, nan},
		{3, 0, nan},
		{3, -0.0, nan},
		{0, 0, nan},
		{nan, 3, nan},
		{3, nan, nan},
		{nan, inf, nan},
	}
	for c in cases {
		got := math.remainder(c.x, c.y)
		testing.expectf(t, same(got, c.want), "remainder(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_remainder_narrow :: proc(t: ^testing.T) {
	testing.expect(t, same(math.remainder(f32(5), 2), f32(1)))
	testing.expect(t, same(math.remainder(f32(1e10), 3), f32(1)))
	testing.expect(t, same(math.remainder(f32(-6), 3), f32(-0.0)))
	testing.expect(t, same(math.remainder(f32(3.4028234663852886e38), 3), f32(0)))
	testing.expect(t, same(math.remainder(f32be(3), 2), f32be(-1)))
	testing.expect(t, same(math.remainder(f16(65504), 3), f16(-1)))
	testing.expect(t, same(math.remainder(f16(1000), 7), f16(-1)))
	testing.expect(t, same(math.remainder(f16le(5), 2), f16le(1)))
	testing.expect(t, same(math.remainder(f64le(1e17), 3), f64le(1)))
	testing.expect(t, same(math.remainder(f64be(5), 2), f64be(1)))
}

@test
test_wrap_stays_below_y :: proc(t: ^testing.T) {
	testing.expect(t, same(math.wrap(f64(-1e-20), math.TAU), f64(0)))
	testing.expect(t, same(math.wrap(f32(-1e-10), f32(math.TAU)), f32(0)))
	testing.expect(t, same(math.wrap(f64(-3), 2), f64(1)))
	testing.expect(t, same(math.wrap(f64(1e17), 3), f64(1)))
	testing.expect(t, same(math.wrap(f64(7.5), 2), f64(1.5)))
	testing.expect(t, within_ulps(math.wrap(f64(-6), math.TAU), f64(0.28318530717958623)))
}

@test
test_angle_diff_near_zero :: proc(t: ^testing.T) {
	d64 := math.angle_diff(f64(1e-20), 0)
	testing.expectf(t, abs(d64) < 1e-15, "angle_diff(1e-20, 0) = %v, want about 0", d64)
	d32 := math.angle_diff(f32(1e-10), 0)
	testing.expectf(t, abs(d32) < 1e-6, "angle_diff(f32(1e-10), 0) = %v, want about 0", d32)
	l64 := math.angle_lerp(f64(1e-20), 0, 0.5)
	testing.expectf(t, abs(l64) < 1e-15, "angle_lerp(1e-20, 0, 0.5) = %v, want about 0", l64)
	l32 := math.angle_lerp(f32(1e-10), 0, 0.5)
	testing.expectf(t, abs(l32) < 1e-6, "angle_lerp(f32(1e-10), 0, 0.5) = %v, want about 0", l32)
	testing.expect(t, within_ulps(math.angle_diff(f64(3), -3), f64(0.28318530717958623)))
}
