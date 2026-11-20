package test_core_math_cmplx

import "core:math"
import "core:math/cmplx"
import "core:testing"

@(private="file")
expect_conj_table :: proc(t: ^testing.T, name: string, f: proc "contextless" (complex128) -> complex128, cases: []Special, loc := #caller_location) {
	signs := [2]f64{1, -1}
	for c in cases {
		for sy in signs {
			z := complex(c.x, sy*c.y)
			want := complex(real(c.want), sy*imag(c.want))
			got := f(z)
			testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "%s(%v) = %v, want %v", name, z, got, want, loc = loc)
		}
	}
}

@test
test_is_inf_is_nan :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	parts := []f64{0, 1, -2.5, inf, -inf, nan}

	for re in parts {
		for im in parts {
			z := complex(re, im)
			want_inf := math.is_inf(re) || math.is_inf(im)
			want_nan := !want_inf && (math.is_nan(re) || math.is_nan(im))

			testing.expectf(t, cmplx.is_inf(z) == want_inf, "is_inf(%v) = %v, want %v", z, cmplx.is_inf(z), want_inf)
			testing.expectf(t, cmplx.is_nan(z) == want_nan, "is_nan(%v) = %v, want %v", z, cmplx.is_nan(z), want_nan)

			z64 := complex64(z)
			testing.expectf(t, cmplx.is_inf(z64) == want_inf, "is_inf(complex64(%v)) = %v, want %v", z, cmplx.is_inf(z64), want_inf)
			testing.expectf(t, cmplx.is_nan(z64) == want_nan, "is_nan(complex64(%v)) = %v, want %v", z, cmplx.is_nan(z64), want_nan)

			z32 := complex32(z)
			testing.expectf(t, cmplx.is_inf(z32) == want_inf, "is_inf(complex32(%v)) = %v, want %v", z, cmplx.is_inf(z32), want_inf)
			testing.expectf(t, cmplx.is_nan(z32) == want_nan, "is_nan(complex32(%v)) = %v, want %v", z, cmplx.is_nan(z32), want_nan)
		}
	}
}

@test
test_nan_inf_constructors :: proc(t: ^testing.T) {
	n128 := cmplx.nan_complex128()
	testing.expectf(t, math.is_nan(real(n128)) && math.is_nan(imag(n128)), "nan_complex128() = %v", n128)
	n64 := cmplx.nan_complex64()
	testing.expectf(t, math.is_nan(real(n64)) && math.is_nan(imag(n64)), "nan_complex64() = %v", n64)
	n32 := cmplx.nan_complex32()
	testing.expectf(t, math.is_nan(real(n32)) && math.is_nan(imag(n32)), "nan_complex32() = %v", n32)

	inf128 := cmplx.inf_complex128()
	testing.expectf(t, math.is_inf(real(inf128), 1) && math.is_inf(imag(inf128), 1), "inf_complex128() = %v", inf128)
	inf64 := cmplx.inf_complex64()
	testing.expectf(t, math.is_inf(real(inf64), 1) && math.is_inf(imag(inf64), 1), "inf_complex64() = %v", inf64)
	inf32 := cmplx.inf_complex32()
	testing.expectf(t, math.is_inf(real(inf32), 1) && math.is_inf(imag(inf32), 1), "inf_complex32() = %v", inf32)

	testing.expect(t, cmplx.is_nan(n128) && !cmplx.is_inf(n128))
	testing.expect(t, cmplx.is_inf(inf128) && !cmplx.is_nan(inf128))
}

@test
test_phase :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		x:    complex128,
		want: f64,
	}
	cases := []Case{
		{complex(0, 0), 0},
		{complex(0, neg_zero), neg_zero},
		{complex(neg_zero, 0), math.PI},
		{complex(neg_zero, neg_zero), -math.PI},
		{complex(1, 0), 0},
		{complex(1, neg_zero), neg_zero},
		{complex(-1, 0), math.PI},
		{complex(-1, neg_zero), -math.PI},
		{complex(0, 1), math.PI/2},
		{complex(neg_zero, 1), math.PI/2},
		{complex(0, -1), -math.PI/2},
		{complex(neg_zero, -1), -math.PI/2},
		{complex(1, 1), math.PI/4},
		{complex(-1, 1), 3*math.PI/4},
		{complex(-1, -1), -3*math.PI/4},
		{complex(1, -1), -math.PI/4},
		{complex(inf, 0), 0},
		{complex(inf, 1), 0},
		{complex(inf, -1), neg_zero},
		{complex(-inf, 0), math.PI},
		{complex(-inf, neg_zero), -math.PI},
		{complex(-inf, 1), math.PI},
		{complex(-inf, -1), -math.PI},
		{complex(1, inf), math.PI/2},
		{complex(1, -inf), -math.PI/2},
		{complex(inf, inf), math.PI/4},
		{complex(-inf, inf), 3*math.PI/4},
		{complex(-inf, -inf), -3*math.PI/4},
		{complex(inf, -inf), -math.PI/4},
		{complex(nan, 1), nan},
		{complex(1, nan), nan},
	}
	for c in cases {
		got := cmplx.phase(c.x)
		testing.expectf(t, close(got, c.want), "phase(%v) = %v, want %v", c.x, got, c.want)
		got64 := cmplx.phase(complex64(c.x))
		testing.expectf(t, close(got64, f32(c.want)), "phase(complex64(%v)) = %v, want %v", c.x, got64, f32(c.want))
		got32 := cmplx.phase(complex32(c.x))
		testing.expectf(t, close(got32, f16(c.want)), "phase(complex32(%v)) = %v, want %v", c.x, got32, f16(c.want))
	}
}

@test
test_sqrt :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	specials := []Special{
		{0, 0, complex(0, 0), false, false},
		{neg_zero, 0, complex(0, 0), false, false},
		{0, inf, complex(inf, inf), false, false},
		{1, inf, complex(inf, inf), false, false},
		{-1, inf, complex(inf, inf), false, false},
		{inf, inf, complex(inf, inf), false, false},
		{-inf, inf, complex(inf, inf), false, false},
		{nan, inf, complex(inf, inf), false, false},
		{0, nan, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{-inf, 0, complex(0, inf), false, false},
		{-inf, 1, complex(0, inf), false, false},
		{inf, 0, complex(inf, 0), false, false},
		{inf, 1, complex(inf, 0), false, false},
		{-inf, nan, complex(nan, inf), false, true},
		{inf, nan, complex(inf, nan), false, false},
		{nan, 0, complex(nan, nan), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	expect_conj_table(t, "sqrt", cmplx.sqrt, specials)

	Case :: struct {
		x, want: complex128,
	}
	cases := []Case{
		{complex(-4, 0), complex(0, 2)},
		{complex(-4, neg_zero), complex(0, -2)},
		{complex(4, neg_zero), complex(2, neg_zero)},
		{complex(2, 0), complex(1.4142135623730951, 0)},
		{complex(3, 4), complex(2, 1)},
		{complex(-3, 4), complex(1, 2)},
		{complex(-3, -4), complex(1, -2)},
		{complex(0.5, -2), complex(1.1317139242778693, -0.8836155308755133)},
		{complex(1, 1e-20), complex(1, 5e-21)},
		{complex(-1, 1e-20), complex(5e-21, 1)},
		{complex(1e300, 1e300), complex(1.09868411346781e150, 4.550898605622274e149)},
		{complex(1e-300, 1e-300), complex(1.09868411346781e-150, 4.5508986056222734e-151)},
		{complex(1.7e308, 1.7e308), complex(1.4325088230154573e154, 5.933645827121221e153)},
		{complex(-1.7e308, 1), complex(3.8348249442368524e-155, 1.3038404810405297e154)},
		{complex(1e-310, 3e-310), complex(1.4426152744526806e-155, 1.039778260055569e-155)},
	}
	for c in cases {
		got := cmplx.sqrt(c.x)
		testing.expectf(t, close_complex(got, c.want), "sqrt(%v) = %v, want %v", c.x, got, c.want)
	}

	got64 := cmplx.sqrt(complex64(complex(3, 4)))
	testing.expectf(t, close_complex(got64, complex64(complex(2, 1))), "sqrt(complex64(3+4i)) = %v, want 2+1i", got64)
	got32 := cmplx.sqrt(complex32(complex(-3, -4)))
	testing.expectf(t, close_complex(got32, complex32(complex(1, -2))), "sqrt(complex32(-3-4i)) = %v, want 1-2i", got32)
}

@test
test_exp_special_values :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	specials := []Special{
		{0, 0, complex(1, 0), false, false},
		{neg_zero, 0, complex(1, 0), false, false},
		{0, inf, complex(nan, nan), false, false},
		{1, inf, complex(nan, nan), false, false},
		{0, nan, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{inf, 0, complex(inf, 0), false, false},
		{-inf, 0, complex(0, 0), false, false},
		{-inf, 1, complex(0, 0), false, false},
		{-inf, 2, complex(neg_zero, 0), false, false},
		{-inf, 4, complex(neg_zero, neg_zero), false, false},
		{inf, 1, complex(inf, inf), false, false},
		{inf, 2, complex(-inf, inf), false, false},
		{inf, 4, complex(-inf, -inf), false, false},
		{-inf, inf, complex(0, 0), true, true},
		{inf, inf, complex(inf, nan), true, false},
		{-inf, nan, complex(0, 0), true, true},
		{inf, nan, complex(inf, nan), true, false},
		{nan, 0, complex(nan, 0), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	expect_conj_table(t, "exp", cmplx.exp, specials)
}

@test
test_ln_special_values :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	specials := []Special{
		{neg_zero, 0, complex(-inf, math.PI), false, false},
		{0, 0, complex(-inf, 0), false, false},
		{0, inf, complex(inf, math.PI/2), false, false},
		{1, inf, complex(inf, math.PI/2), false, false},
		{-1, inf, complex(inf, math.PI/2), false, false},
		{0, nan, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{-inf, 0, complex(inf, math.PI), false, false},
		{-inf, 1, complex(inf, math.PI), false, false},
		{inf, 0, complex(inf, 0), false, false},
		{inf, 1, complex(inf, 0), false, false},
		{-inf, inf, complex(inf, 3*math.PI/4), false, false},
		{inf, inf, complex(inf, math.PI/4), false, false},
		{-inf, nan, complex(inf, nan), false, false},
		{inf, nan, complex(inf, nan), false, false},
		{nan, 0, complex(nan, nan), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, inf, complex(inf, nan), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	expect_conj_table(t, "ln", cmplx.ln, specials)
}

@test
test_polar_rect :: proc(t: ^testing.T) {
	neg_zero := math.copy_sign(f64(0), -1)

	Polar :: struct {
		x:    complex128,
		r, θ: f64,
	}
	polars := []Polar{
		{complex(3, 4), 5, 0.9272952180016122},
		{complex(1, 1), 1.4142135623730951, math.PI/4},
		{complex(-1e-5, 2), 2.000000000025, 1.5708013267948966},
		{complex(-2, 0), 2, math.PI},
		{complex(-2, neg_zero), 2, -math.PI},
		{complex(0, -3), 3, -math.PI/2},
	}
	for c in polars {
		r, θ := cmplx.polar(c.x)
		testing.expectf(t, close(r, c.r) && close(θ, c.θ), "polar(%v) = (%v, %v), want (%v, %v)", c.x, r, θ, c.r, c.θ)
		r64, θ64 := cmplx.polar(complex64(c.x))
		testing.expectf(t, close(r64, f32(c.r)) && close(θ64, f32(c.θ)), "polar(complex64(%v)) = (%v, %v), want (%v, %v)", c.x, r64, θ64, f32(c.r), f32(c.θ))
	}

	zs := []complex128{
		complex(3, 4), complex(-3, 4), complex(-3, -4), complex(3, -4),
		complex(1e-300, 2e-300), complex(1e300, -1e299), complex(0, 2), complex(-0.5, 0),
		complex(1e-8, 1), complex(-7.25, 1e-9),
	}
	for z in zs {
		r, θ := cmplx.polar(z)
		w := cmplx.rect(r, θ)
		err := cmplx.abs(w - z) / cmplx.abs(z)
		testing.expectf(t, err <= 4*math.F64_EPSILON, "rect(polar(%v)) = %v, relative error %v", z, w, err)

		z64 := complex64(z)
		if real(z64) == 0 && imag(z64) == 0 || cmplx.is_inf(z64) {
			continue
		}
		r64, θ64 := cmplx.polar(z64)
		w64 := cmplx.rect(r64, θ64)
		err64 := cmplx.abs(w64 - z64) / cmplx.abs(z64)
		testing.expectf(t, err64 <= 4*math.F32_EPSILON, "rect(polar(complex64(%v))) = %v, relative error %v", z, w64, err64)
	}
}
