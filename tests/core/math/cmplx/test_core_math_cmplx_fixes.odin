package test_core_math_cmplx

import "base:intrinsics"
import "core:math"
import "core:math/cmplx"
import "core:testing"

@(private)
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

@(private)
close :: proc(got, want: $T, max_ulps: i64 = 2) -> bool where intrinsics.type_is_float(T) {
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

@(private)
close_complex :: proc(got, want: $T, max_ulps: i64 = 2) -> bool where intrinsics.type_is_complex(T) {
	return close(real(got), real(want), max_ulps) && close(imag(got), imag(want), max_ulps)
}

@(private)
Special :: struct {
	x, y:        f64,
	want:        complex128,
	any_re_sign: bool,
	any_im_sign: bool,
}

@(private)
same_special :: proc(got, want: complex128, any_re_sign, any_im_sign: bool) -> bool {
	re_ok := same(abs(real(got)), abs(real(want))) if any_re_sign else same(real(got), real(want))
	im_ok := same(abs(imag(got)), abs(imag(want))) if any_im_sign else same(imag(got), imag(want))
	return re_ok && im_ok
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

	got := cmplx.rect(f64(2), math.PI/2)
	want := complex(1.2246467991473532e-16, 2)
	testing.expectf(t, close_complex(got, want), "rect(2, π/2) = %v, want %v", got, want)
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

@test
test_sqrt_imaginary_axis :: proc(t: ^testing.T) {
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)
	tiny := math.ldexp(f64(1), -1074)
	tiny_root := 1.5717277847026288e-162
	small := math.ldexp(f64(1), -1031)
	small_root := math.ldexp(f64(1), -516)

	Case :: struct {
		x, want: complex128,
	}
	cases := []Case{
		{complex(0, tiny), complex(tiny_root, tiny_root)},
		{complex(neg_zero, tiny), complex(tiny_root, tiny_root)},
		{complex(0, -tiny), complex(tiny_root, -tiny_root)},
		{complex(neg_zero, -tiny), complex(tiny_root, -tiny_root)},
		{complex(0, small), complex(small_root, small_root)},
		{complex(0, 8), complex(2, 2)},
		{complex(0, -8), complex(2, -2)},
		{complex(nan, 0), complex(nan, nan)},
		{complex(nan, neg_zero), complex(nan, nan)},
	}
	for c in cases {
		got := cmplx.sqrt(c.x)
		testing.expectf(t, same_complex(got, c.want), "sqrt(%v) = %v, want %v", c.x, got, c.want)
	}
}

@test
test_exp_overflow :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	neg_zero := math.copy_sign(f64(0), -1)

	Case :: struct {
		x, want: complex128,
	}
	cases := []Case{
		{complex(710, 0), complex(inf, 0)},
		{complex(710, neg_zero), complex(inf, neg_zero)},
		{complex(-746, 1), complex(0, 0)},
		{complex(-746, 2), complex(neg_zero, 0)},
		{complex(1, 1), complex(1.4686939399158851, 2.2873552871788423)},
		{complex(1, math.PI/2), complex(1.664467570201392e-16, math.E)},
	}
	for c in cases {
		got := cmplx.exp(c.x)
		testing.expectf(t, close_complex(got, c.want), "exp(%v) = %v, want %v", c.x, got, c.want)
	}

	got := cmplx.exp(complex(710, 0.8))
	want := complex(1.5564391422313159e308, 1.6025697525437586e308)
	testing.expectf(t, close_complex(got, want, 4), "exp(710+0.8i) = %v, want %v", got, want)

	got64 := cmplx.exp(complex64(complex(89, 0)))
	want64 := complex(math.inf_f32(1), f32(0))
	testing.expectf(t, same_complex(got64, want64), "exp(complex64(89+0i)) = %v, want %v", got64, want64)
}

@test
test_ln_without_abs :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)
	eps := math.ldexp(f64(1), -30)

	Case :: struct {
		x, want: complex128,
	}
	cases := []Case{
		{complex(1.7e308, 1.7e308), complex(710.07341048350827, math.PI/4)},
		{complex(1, 1e-8), complex(4.9999999999999999e-17, 1e-8)},
		{complex(0.6, 0.8), complex(2.2204460492503132e-17, 0.9272952180016123)},
		{complex(1, eps), complex(4.3368086899420177e-19, 9.3132257461547852e-10)},
		{complex(1e-310, 1e-310), complex(-713.45480523787421, math.PI/4)},
		{-1, complex(0, math.PI)},
		{complex(neg_zero, neg_zero), complex(-inf, -math.PI)},
		{complex(nan, inf), complex(inf, nan)},
	}
	for c in cases {
		got := cmplx.ln(c.x)
		testing.expectf(t, close_complex(got, c.want), "ln(%v) = %v, want %v", c.x, got, c.want)
	}
}

@test
test_sin_cos_sinh_cosh :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	sinh_cases := []Special{
		{0, 0, complex(0, 0), false, false},
		{0, inf, complex(0, nan), true, false},
		{0, nan, complex(0, nan), true, false},
		{1, inf, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{inf, 0, complex(inf, 0), false, false},
		{inf, 1, complex(inf, inf), false, false},
		{inf, 2, complex(-inf, inf), false, false},
		{inf, inf, complex(inf, nan), true, false},
		{inf, nan, complex(inf, nan), true, false},
		{nan, 0, complex(nan, 0), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	cosh_cases := []Special{
		{0, 0, complex(1, 0), false, false},
		{0, inf, complex(nan, 0), false, true},
		{0, nan, complex(nan, 0), false, true},
		{1, inf, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{inf, 0, complex(inf, 0), false, false},
		{inf, 1, complex(inf, inf), false, false},
		{inf, 2, complex(-inf, inf), false, false},
		{inf, inf, complex(inf, nan), true, false},
		{inf, nan, complex(inf, nan), false, false},
		{nan, 0, complex(nan, 0), false, true},
		{nan, 1, complex(nan, nan), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	signs := [2]f64{1, -1}
	for c in sinh_cases {
		for sx in signs {
			for sy in signs {
				z := complex(sx*c.x, sy*c.y)
				want := complex(sx*real(c.want), sy*imag(c.want))
				got := cmplx.sinh(z)
				testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "sinh(%v) = %v, want %v", z, got, want)
				got = cmplx.sin(complex(imag(z), -real(z)))
				want_sin := complex(imag(want), -real(want))
				testing.expectf(t, same_special(got, want_sin, c.any_im_sign, c.any_re_sign), "sin(%v) = %v, want %v", complex(imag(z), -real(z)), got, want_sin)
			}
		}
	}
	for c in cosh_cases {
		for sx in signs {
			for sy in signs {
				z := complex(sx*c.x, sy*c.y)
				want := complex(real(c.want), sx*sy*imag(c.want))
				got := cmplx.cosh(z)
				testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "cosh(%v) = %v, want %v", z, got, want)
				got = cmplx.cos(complex(imag(z), -real(z)))
				testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "cos(%v) = %v, want %v", complex(imag(z), -real(z)), got, want)
			}
		}
	}

	Case :: struct {
		name: string,
		f:    proc "contextless" (complex128) -> complex128,
		x:    complex128,
		want: complex128,
	}
	cases := []Case{
		{"sin", cmplx.sin, complex(0, 710), complex(0, 1.1169973830808555e308)},
		{"cos", cmplx.cos, complex(0, 710), complex(1.1169973830808555e308, neg_zero)},
		{"sinh", cmplx.sinh, complex(710.4, 0.5), complex(1.4623722367640471e308, 7.9889759402263215e307)},
		{"sinh", cmplx.sinh, complex(-710.4, -0.5), complex(-1.4623722367640471e308, -7.9889759402263215e307)},
		{"cosh", cmplx.cosh, complex(710.4, 0.5), complex(1.4623722367640471e308, 7.9889759402263215e307)},
		{"sin", cmplx.sin, complex(0, 1e-20), complex(0, 1e-20)},
		{"sinh", cmplx.sinh, complex(1e-10, 1), complex(5.4030230586813976e-11, 0.8414709848078965)},
	}
	for c in cases {
		got := c.f(c.x)
		testing.expectf(t, close_complex(got, c.want), "%s(%v) = %v, want %v", c.name, c.x, got, c.want)
	}
}

@test
test_tan_tanh_cot :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)

	tanh_cases := []Special{
		{0, 0, complex(0, 0), false, false},
		{0, inf, complex(nan, nan), false, false},
		{0, nan, complex(nan, nan), false, false},
		{1, inf, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{inf, 0, complex(1, 0), false, false},
		{inf, 1, complex(1, 0), false, false},
		{inf, 2, complex(1, neg_zero), false, false},
		{inf, inf, complex(1, 0), false, true},
		{inf, nan, complex(1, 0), false, true},
		{nan, 0, complex(nan, 0), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	signs := [2]f64{1, -1}
	for c in tanh_cases {
		for sx in signs {
			for sy in signs {
				z := complex(sx*c.x, sy*c.y)
				want := complex(sx*real(c.want), sy*imag(c.want))
				got := cmplx.tanh(z)
				testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "tanh(%v) = %v, want %v", z, got, want)

				zt := complex(imag(z), -real(z))
				want_tan := complex(imag(want), -real(want))
				got = cmplx.tan(zt)
				testing.expectf(t, same_special(got, want_tan, c.any_im_sign, c.any_re_sign), "tan(%v) = %v, want %v", zt, got, want_tan)

				if c.x == 0 && c.y == 0 {
					continue
				}
				want_cot := complex(imag(want), real(want))
				got = cmplx.cot(zt)
				testing.expectf(t, same_special(got, want_cot, c.any_im_sign, c.any_re_sign), "cot(%v) = %v, want %v", zt, got, want_cot)
			}
		}
	}

	Case :: struct {
		name: string,
		f:    proc "contextless" (complex128) -> complex128,
		x:    complex128,
		want: complex128,
	}
	cases := []Case{
		{"tan", cmplx.tan, complex(1, 400), complex(0, 1)},
		{"tanh", cmplx.tanh, complex(400, 1), complex(1, 0)},
		{"tan", cmplx.tan, complex(1.7e308, 0), complex(-0.74079573698442525, 0)},
		{"cot", cmplx.cot, complex(1e-20, 0), complex(1e20, neg_zero)},
	}
	for c in cases {
		got := c.f(c.x)
		testing.expectf(t, close_complex(got, c.want), "%s(%v) = %v, want %v", c.name, c.x, got, c.want)
	}

	got := cmplx.tanh(complex(0, math.PI/2))
	want := complex(0, 16331239353195370)
	testing.expectf(t, close_complex(got, want), "tanh(0+πi/2) = %v, want %v", got, want)

	zs := []complex128{complex(0.5, 0.25), complex(-1.25, 2), complex(3, -0.75)}
	for z in zs {
		p := cmplx.tan(z) * cmplx.cot(z)
		testing.expectf(t, cmplx.abs(p - 1) < 4*math.F64_EPSILON, "tan(%v)*cot(%v) = %v, want 1", z, z, p)
	}
}

@test
test_asin_acos_asinh_acosh :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)
	signs := [2]f64{1, -1}

	asinh_cases := []Special{
		{0, 0, complex(0, 0), false, false},
		{0, inf, complex(inf, math.PI/2), false, false},
		{1, inf, complex(inf, math.PI/2), false, false},
		{0, nan, complex(nan, nan), false, false},
		{1, nan, complex(nan, nan), false, false},
		{inf, 0, complex(inf, 0), false, false},
		{inf, 1, complex(inf, 0), false, false},
		{inf, inf, complex(inf, math.PI/4), false, false},
		{inf, nan, complex(inf, nan), false, false},
		{nan, 0, complex(nan, 0), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, inf, complex(inf, nan), true, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	for c in asinh_cases {
		for sx in signs {
			for sy in signs {
				z := complex(sx*c.x, sy*c.y)
				want := complex(sx*real(c.want), sy*imag(c.want))
				got := cmplx.asinh(z)
				testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "asinh(%v) = %v, want %v", z, got, want)

				zs := complex(imag(z), -real(z))
				want_asin := complex(imag(want), -real(want))
				got = cmplx.asin(zs)
				testing.expectf(t, same_special(got, want_asin, c.any_im_sign, c.any_re_sign), "asin(%v) = %v, want %v", zs, got, want_asin)
			}
		}
	}

	acos_cases := []Special{
		{0, 0, complex(math.PI/2, neg_zero), false, false},
		{neg_zero, 0, complex(math.PI/2, neg_zero), false, false},
		{0, nan, complex(math.PI/2, nan), false, false},
		{neg_zero, nan, complex(math.PI/2, nan), false, false},
		{0, inf, complex(math.PI/2, -inf), false, false},
		{1, inf, complex(math.PI/2, -inf), false, false},
		{-1, inf, complex(math.PI/2, -inf), false, false},
		{1, nan, complex(nan, nan), false, false},
		{-inf, 0, complex(math.PI, -inf), false, false},
		{-inf, 1, complex(math.PI, -inf), false, false},
		{inf, 0, complex(0, -inf), false, false},
		{inf, 1, complex(0, -inf), false, false},
		{-inf, inf, complex(3*math.PI/4, -inf), false, false},
		{inf, inf, complex(math.PI/4, -inf), false, false},
		{-inf, nan, complex(nan, inf), false, true},
		{inf, nan, complex(nan, inf), false, true},
		{nan, 0, complex(nan, nan), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, inf, complex(nan, -inf), false, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	acosh_cases := []Special{
		{0, 0, complex(0, math.PI/2), false, false},
		{neg_zero, 0, complex(0, math.PI/2), false, false},
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
	for c in acos_cases {
		for sy in signs {
			z := complex(c.x, sy*c.y)
			want := complex(real(c.want), sy*imag(c.want))
			got := cmplx.acos(z)
			testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "acos(%v) = %v, want %v", z, got, want)
		}
	}
	for c in acosh_cases {
		for sy in signs {
			z := complex(c.x, sy*c.y)
			want := complex(real(c.want), sy*imag(c.want))
			got := cmplx.acosh(z)
			testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "acosh(%v) = %v, want %v", z, got, want)
		}
	}

	E :: 1.0 / (1 << 30)
	Case :: struct {
		name: string,
		f:    proc "contextless" (complex128) -> complex128,
		x:    complex128,
		want: complex128,
	}
	cases := []Case{
		{"asin", cmplx.asin, complex(0, 1e10), complex(0, 23.7189981105004)},
		{"asin", cmplx.asin, complex(1e200, 1), complex(math.PI/2, 461.2101657793691)},
		{"acos", cmplx.acos, complex(1e200, 1), complex(1e-200, -461.2101657793691)},
		{"asin", cmplx.asin, complex(0, 1e4), complex(0, 9.903487555036127)},
		{"asin", cmplx.asin, complex(0.5, 1e-20), complex(0.5235987755982989, 1.1547005383792515e-20)},
		{"asinh", cmplx.asinh, complex(1e-20, 0.8), complex(1.6666666666666668e-20, 0.9272952180016123)},
		{"acosh", cmplx.acosh, complex(0.5, neg_zero), complex(0, -1.0471975511965979)},

		{"asin", cmplx.asin, complex(1 + E, 0), complex(math.PI/2, 4.315837287180596e-05)},
		{"asin", cmplx.asin, complex(1 - E, E), complex(1.5707489093762534, 1.964093789905154e-05)},
		{"asin", cmplx.asin, complex(1 + E, E), complex(1.570776685857008, 4.741741863889765e-05)},
		{"asin", cmplx.asin, complex(-1 - E, -E), complex(-1.570776685857008, -4.741741863889765e-05)},
		{"acos", cmplx.acos, complex(1 + E, 0), complex(0, -4.315837287180596e-05)},
		{"acos", cmplx.acos, complex(1 - E, E), complex(4.7417418643209126e-05, -1.964093789905154e-05)},
		{"acos", cmplx.acos, complex(-1 + E, E), complex(3.14154523617115, -1.964093789905154e-05)},
		{"acos", cmplx.acos, complex(-1 - E, -E), complex(3.1415730126519046, 4.741741863889765e-05)},
		{"asinh", cmplx.asinh, complex(0, 1 + E), complex(4.315837287180596e-05, math.PI/2)},
		{"asinh", cmplx.asinh, complex(E, 1 - E), complex(1.964093789905154e-05, 1.5707489093762534)},
		{"asinh", cmplx.asinh, complex(-E, -1 - E), complex(-4.741741863889765e-05, -1.570776685857008)},
		{"acosh", cmplx.acosh, complex(1 + E, 0), complex(4.315837287180596e-05, 0)},
		{"acosh", cmplx.acosh, complex(1 - E, E), complex(1.964093789905154e-05, 4.7417418643209126e-05)},
		{"acosh", cmplx.acosh, complex(-1 + E, -E), complex(1.964093789905154e-05, -3.14154523617115)},
		{"acosh", cmplx.acosh, complex(-1 - E, E), complex(4.741741863889765e-05, 3.1415730126519046)},

		{"asin", cmplx.asin, complex(2, 0), complex(math.PI/2, 1.3169578969248168)},
		{"asin", cmplx.asin, complex(2, neg_zero), complex(math.PI/2, -1.3169578969248168)},
		{"asin", cmplx.asin, complex(-2, 0), complex(-math.PI/2, 1.3169578969248168)},
		{"asin", cmplx.asin, complex(-2, neg_zero), complex(-math.PI/2, -1.3169578969248168)},
		{"acos", cmplx.acos, complex(2, 0), complex(0, -1.3169578969248168)},
		{"acos", cmplx.acos, complex(2, neg_zero), complex(0, 1.3169578969248168)},
		{"acos", cmplx.acos, complex(-2, 0), complex(math.PI, -1.3169578969248168)},
		{"acos", cmplx.acos, complex(-2, neg_zero), complex(math.PI, 1.3169578969248168)},
		{"asinh", cmplx.asinh, complex(0, 2), complex(1.3169578969248168, math.PI/2)},
		{"asinh", cmplx.asinh, complex(neg_zero, 2), complex(-1.3169578969248168, math.PI/2)},
		{"asinh", cmplx.asinh, complex(0, -2), complex(1.3169578969248168, -math.PI/2)},
		{"asinh", cmplx.asinh, complex(neg_zero, -2), complex(-1.3169578969248168, -math.PI/2)},
		{"acosh", cmplx.acosh, complex(0.5, 0), complex(0, 1.0471975511965979)},
		{"acosh", cmplx.acosh, complex(-2, 0), complex(1.3169578969248168, math.PI)},
		{"acosh", cmplx.acosh, complex(-2, neg_zero), complex(1.3169578969248168, -math.PI)},

		{"asin", cmplx.asin, complex(6e299, 8e299), complex(0.6435011087932844, 691.4686750787737)},
		{"acos", cmplx.acos, complex(-6e299, 8e299), complex(2.214297435588181, -691.4686750787737)},
		{"asinh", cmplx.asinh, complex(6e299, -8e299), complex(691.4686750787737, -0.9272952180016122)},
		{"acosh", cmplx.acosh, complex(-6e299, -8e299), complex(691.4686750787737, -2.214297435588181)},
	}
	for c in cases {
		got := c.f(c.x)
		testing.expectf(t, close_complex(got, c.want), "%s(%v) = %v, want %v", c.name, c.x, got, c.want)
	}
}

@test
test_atan_atanh :: proc(t: ^testing.T) {
	inf := math.inf_f64(1)
	nan := math.nan_f64()
	neg_zero := math.copy_sign(f64(0), -1)
	signs := [2]f64{1, -1}

	atanh_cases := []Special{
		{0, 0, complex(0, 0), false, false},
		{0, nan, complex(0, nan), false, false},
		{1, 0, complex(inf, 0), false, false},
		{0, inf, complex(0, math.PI/2), false, false},
		{1, inf, complex(0, math.PI/2), false, false},
		{1, nan, complex(nan, nan), false, false},
		{inf, 0, complex(0, math.PI/2), false, false},
		{inf, 1, complex(0, math.PI/2), false, false},
		{inf, inf, complex(0, math.PI/2), false, false},
		{inf, nan, complex(0, nan), false, false},
		{nan, 0, complex(nan, nan), false, false},
		{nan, 1, complex(nan, nan), false, false},
		{nan, inf, complex(0, math.PI/2), true, false},
		{nan, nan, complex(nan, nan), false, false},
	}
	for c in atanh_cases {
		for sx in signs {
			for sy in signs {
				z := complex(sx*c.x, sy*c.y)
				want := complex(sx*real(c.want), sy*imag(c.want))
				got := cmplx.atanh(z)
				testing.expectf(t, same_special(got, want, c.any_re_sign, c.any_im_sign), "atanh(%v) = %v, want %v", z, got, want)

				zs := complex(imag(z), -real(z))
				want_atan := complex(imag(want), -real(want))
				got = cmplx.atan(zs)
				testing.expectf(t, same_special(got, want_atan, c.any_im_sign, c.any_re_sign), "atan(%v) = %v, want %v", zs, got, want_atan)
			}
		}
	}

	Case :: struct {
		name: string,
		f:    proc "contextless" (complex128) -> complex128,
		x:    complex128,
		want: complex128,
	}
	cases := []Case{
		{"atan", cmplx.atan, complex(0, 2), complex(math.PI/2, 0.5493061443340549)},
		{"atan", cmplx.atan, complex(neg_zero, 2), complex(-math.PI/2, 0.5493061443340549)},
		{"atan", cmplx.atan, complex(0, -2), complex(math.PI/2, -0.5493061443340549)},
		{"atan", cmplx.atan, complex(neg_zero, -2), complex(-math.PI/2, -0.5493061443340549)},
		{"atanh", cmplx.atanh, complex(2, 0), complex(0.5493061443340549, math.PI/2)},
		{"atanh", cmplx.atanh, complex(2, neg_zero), complex(0.5493061443340549, -math.PI/2)},
		{"atanh", cmplx.atanh, complex(-2, 0), complex(-0.5493061443340549, math.PI/2)},
		{"atanh", cmplx.atanh, complex(-2, neg_zero), complex(-0.5493061443340549, -math.PI/2)},

		{"atan", cmplx.atan, complex(0.28, 0.96), complex(math.PI/4, 0.9729550745276566)},
		{"atan", cmplx.atan, complex(1e-200, 1), complex(math.PI/4, 230.60508288968455)},
		{"atan", cmplx.atan, complex(2e154, 0.5), complex(math.PI/2, 1.25e-309)},
		{"atanh", cmplx.atanh, complex(1, 1e-10), complex(11.8594990552502, 0.7853981634224483)},
		{"atanh", cmplx.atanh, complex(0.5, 0), complex(0.5493061443340549, 0)},
		{"atanh", cmplx.atanh, complex(1e-20, 1e-20), complex(1e-20, 1e-20)},

		{"atanh", cmplx.atanh, complex(0.6, 0.8), complex(0.34657359027997264, math.PI/4)},
		{"atanh", cmplx.atanh, complex(-0.6, -0.8), complex(-0.34657359027997264, -math.PI/4)},
		{"atan", cmplx.atan, complex(0.6, 0.8), complex(math.PI/4, 0.5493061443340549)},

		{"atanh", cmplx.atanh, complex(6e299, 8e299), complex(6e-301, math.PI/2)},
		{"atan", cmplx.atan, complex(-6e299, 8e299), complex(-math.PI/2, 7.999999999999999e-301)},
	}
	for c in cases {
		got := c.f(c.x)
		testing.expectf(t, close_complex(got, c.want), "%s(%v) = %v, want %v", c.name, c.x, got, c.want)
	}
}
