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
