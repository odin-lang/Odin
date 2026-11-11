package test_core_math_cmplx

import "base:intrinsics"
import "core:math"
import "core:math/cmplx"
import "core:testing"

@(private="file")
same :: proc(got, want: $T) -> bool where intrinsics.type_is_float(T) {
	if math.is_nan(want) {
		return math.is_nan(got)
	}
	return got == want && math.sign_bit(got) == math.sign_bit(want)
}

@(private="file")
close :: proc(got, want: $T) -> bool where intrinsics.type_is_float(T) {
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
	return abs(g - w) <= 2
}

@(private="file")
expect_sinh_cosh :: proc(t: ^testing.T, x, want_sinh, want_cosh: $T, loc := #caller_location) where intrinsics.type_is_float(T) {
	s := math.sinh(x)
	testing.expectf(t, close(s, want_sinh), "sinh(%v) = %v, want %v", x, s, want_sinh, loc = loc)
	c := math.cosh(x)
	testing.expectf(t, close(c, want_cosh), "cosh(%v) = %v, want %v", x, c, want_cosh, loc = loc)
}

@test
test_abs_non_finite :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		x:    complex128,
		want: f64,
	}
	cases := []Case{
		{complex(inf, inf), inf},
		{complex(-inf, nan), inf},
		{complex(nan, inf), inf},
		{complex(nan, -inf), inf},
		{complex(0, nan), nan},
		{complex(nan, 0), nan},
		{complex(neg_zero, neg_zero), 0},
		{complex(3, -4), 5},
	}
	for c in cases {
		got128 := cmplx.abs(c.x)
		testing.expectf(t, same(got128, c.want), "abs(%v) = %v, want %v", c.x, got128, c.want)
		got64 := cmplx.abs(complex64(c.x))
		testing.expectf(t, same(got64, f32(c.want)), "abs(complex64(%v)) = %v, want %v", c.x, got64, f32(c.want))
		got32 := cmplx.abs(complex32(c.x))
		testing.expectf(t, same(got32, f16(c.want)), "abs(complex32(%v)) = %v, want %v", c.x, got32, f16(c.want))
	}

	r, θ := cmplx.polar(complex(0, nan))
	testing.expectf(t, math.is_nan(r) && math.is_nan(θ), "polar(0+NaN i) = (%v, %v), want (NaN, NaN)", r, θ)
}

@test
test_sinh_cosh :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		x, sinh, cosh: f64,
	}
	cases := []Case{
		{0, 0, 1},
		{neg_zero, neg_zero, 1},
		{inf, inf, inf},
		{-inf, -inf, inf},
		{nan, nan, nan},
		{1e-20, 1e-20, 1},
		{1e-10, 1e-10, 1},
		{0.5, 0.52109530549374738, 1.1276259652063807},
		{-0.5, -0.52109530549374738, 1.1276259652063807},
		{1, 1.1752011936438014, 1.5430806348152437},
		{21.9, 1621881641.7888238, 1621881641.7888238},
		{710.4, 1.6663642832806496e308, 1.6663642832806496e308},
		{-710.4, -1.6663642832806496e308, 1.6663642832806496e308},
	}
	for c in cases {
		expect_sinh_cosh(t, c.x, c.sinh, c.cosh)
	}

	expect_sinh_cosh(t, f32(89.4), 3.34886272e38, 3.34886272e38)
	expect_sinh_cosh(t, f16(11.09), 32864, 32864)
}

@test
test_atan2_quadrant :: proc(t: ^testing.T) {
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		y, x, want: f64,
	}
	cases := []Case{
		{-1e-300, -1e300, -math.PI},
		{1e-300, -1e300, math.PI},
		{-1, -1, -3*math.PI/4},
		{1, -1, 3*math.PI/4},
		{0, -1, math.PI},
		{neg_zero, -1, -math.PI},
	}
	for c in cases {
		got := math.atan2(c.y, c.x)
		testing.expectf(t, close(got, c.want), "atan2(%v, %v) = %v, want %v", c.y, c.x, got, c.want)
	}
}
