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
same_complex :: proc(got, want: $T) -> bool where intrinsics.type_is_complex(T) {
	return same(real(got), real(want)) && same(imag(got), imag(want))
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
close_complex :: proc(got, want: $T) -> bool where intrinsics.type_is_complex(T) {
	return close(real(got), real(want)) && close(imag(got), imag(want))
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

@test
test_log10 :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		x, want: complex128,
	}
	cases := []Case{
		{10, 1},
		{complex(0, 100), complex(2, math.PI/(2*math.LN10))},
		{-1, complex(0, math.PI/math.LN10)},
		{complex(0, 0), complex(-inf, 0)},
		{complex(0, neg_zero), complex(-inf, neg_zero)},
		{complex(neg_zero, 0), complex(-inf, math.PI/math.LN10)},
		{complex(neg_zero, neg_zero), complex(-inf, -math.PI/math.LN10)},
	}
	for c in cases {
		got128 := cmplx.log10(c.x)
		testing.expectf(t, close_complex(got128, c.want), "log10(%v) = %v, want %v", c.x, got128, c.want)
		got64 := cmplx.log10(complex64(c.x))
		testing.expectf(t, close_complex(got64, complex64(c.want)), "log10(complex64(%v)) = %v, want %v", c.x, got64, complex64(c.want))
		got32 := cmplx.log10(complex32(c.x))
		testing.expectf(t, close_complex(got32, complex32(c.want)), "log10(complex32(%v)) = %v, want %v", c.x, got32, complex32(c.want))
	}
}

@test
test_rect_group :: proc(t: ^testing.T) {
	zs := []complex128{complex(3, 4), complex(-5, 12), complex(-8, -15), complex(7, -24)}
	for z in zs {
		r, θ := cmplx.polar(z)
		w: complex128 = cmplx.rect(r, θ)
		testing.expectf(t, close_complex(w, z), "rect(polar(%v)) = %v", z, w)

		r64, θ64 := cmplx.polar(complex64(z))
		w64: complex64 = cmplx.rect(r64, θ64)
		testing.expectf(t, close_complex(w64, complex64(z)), "rect(polar(complex64(%v))) = %v", z, w64)

		r32, θ32 := cmplx.polar(complex32(z))
		w32: complex32 = cmplx.rect(r32, θ32)
		testing.expectf(t, close_complex(w32, complex32(z)), "rect(polar(complex32(%v))) = %v", z, w32)
	}
}

@test
test_trig_groups :: proc(t: ^testing.T) {
	Fn :: struct {
		name: string,
		c128: proc "contextless" (complex128) -> complex128,
		c64:  proc "contextless" (complex64) -> complex64,
		c32:  proc "contextless" (complex32) -> complex32,
	}
	fns := []Fn{
		{"sin", cmplx.sin, cmplx.sin, cmplx.sin},
		{"cos", cmplx.cos, cmplx.cos, cmplx.cos},
		{"tan", cmplx.tan, cmplx.tan, cmplx.tan},
		{"cot", cmplx.cot, cmplx.cot, cmplx.cot},
		{"sinh", cmplx.sinh, cmplx.sinh, cmplx.sinh},
		{"cosh", cmplx.cosh, cmplx.cosh, cmplx.cosh},
		{"tanh", cmplx.tanh, cmplx.tanh, cmplx.tanh},
	}
	zs := []complex128{complex(0.5, -0.25), complex(-1.25, 2), complex(0.75, 1.5)}
	for f in fns {
		for z in zs {
			z64 := complex64(z)
			got64, want64 := f.c64(z64), complex64(f.c128(complex128(z64)))
			testing.expectf(t, same_complex(got64, want64), "%s(complex64(%v)) = %v, want %v", f.name, z, got64, want64)

			z32 := complex32(z)
			got32, want32 := f.c32(z32), complex32(f.c128(complex128(z32)))
			testing.expectf(t, same_complex(got32, want32), "%s(complex32(%v)) = %v, want %v", f.name, z, got32, want32)
		}
	}
}

@test
test_pow_zero_base_nan_exponent :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	xs := []complex128{complex(0, 0), complex(neg_zero, 0), complex(0, neg_zero), complex(neg_zero, neg_zero)}
	ys := []complex128{complex(nan, inf), complex(nan, -inf)}
	want := complex(nan, nan)
	for x in xs {
		for y in ys {
			got128 := cmplx.pow(x, y)
			testing.expectf(t, same_complex(got128, want), "pow(%v, %v) = %v, want NaN", x, y, got128)
			got64 := cmplx.pow(complex64(x), complex64(y))
			testing.expectf(t, same_complex(got64, complex64(want)), "pow(complex64(%v), complex64(%v)) = %v, want NaN", x, y, got64)
			got32 := cmplx.pow(complex32(x), complex32(y))
			testing.expectf(t, same_complex(got32, complex32(want)), "pow(complex32(%v), complex32(%v)) = %v, want NaN", x, y, got32)
		}
	}
}

@test
test_pow_real_result :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()

	Case :: struct {
		x, y, want: complex128,
	}
	cases := []Case{
		{2, 3, 8},
		{1e200, 2, complex(inf, 0)},
		// Deliberate: an infinite real base gives a real result; pow(Inf, 0) = 1 as in FreeBSD's cpow.
		// glibc's cexp(y*clog(x)) gives NaN or (Inf, NaN) here, from 0*Inf inside its complex multiply.
		{complex(inf, 0), 2, complex(inf, 0)},
		{complex(inf, 0), 0.5, complex(inf, 0)},
		{complex(inf, 0), 0, 1},
		// As in C, not Python: pow(NaN, 0) and rect(0, Inf) are NaN.
		{complex(nan, 0), 0, complex(nan, nan)},
	}
	for c in cases {
		got := cmplx.pow(c.x, c.y)
		testing.expectf(t, same_complex(got, c.want), "pow(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}

	got64 := cmplx.pow(complex64(1e-30), complex64(-2))
	want64 := complex(math.inf_f32(1), math.copy_sign(f32(0), -1))
	testing.expectf(t, same_complex(got64, want64), "pow(complex64(1e-30), -2) = %v, want %v", got64, want64)
}

@test
test_rect_real_result :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		r, θ: f64,
		want: complex128,
	}
	cases := []Case{
		// Deliberate: rect(Inf, 0) = (Inf, +0), not Inf*cis(0) = (Inf, NaN); sin(0) is an exact zero.
		{inf, 0, complex(inf, 0)},
		{-inf, 0, complex(-inf, neg_zero)},
		{inf, neg_zero, complex(inf, neg_zero)},
		// As in C, not Python: pow(NaN, 0) and rect(0, Inf) are NaN.
		{0, inf, complex(nan, nan)},
		{0, -inf, complex(nan, nan)},
		{0, nan, complex(nan, nan)},
	}
	for c in cases {
		got128 := cmplx.rect(c.r, c.θ)
		testing.expectf(t, same_complex(got128, c.want), "rect(%v, %v) = %v, want %v", c.r, c.θ, got128, c.want)
		got64 := cmplx.rect(f32(c.r), f32(c.θ))
		testing.expectf(t, same_complex(got64, complex64(c.want)), "rect(f32(%v), f32(%v)) = %v, want %v", c.r, c.θ, got64, complex64(c.want))
		got32 := cmplx.rect(f16(c.r), f16(c.θ))
		testing.expectf(t, same_complex(got32, complex32(c.want)), "rect(f16(%v), f16(%v)) = %v, want %v", c.r, c.θ, got32, complex32(c.want))
	}
}
