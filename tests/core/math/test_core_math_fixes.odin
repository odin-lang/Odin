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
