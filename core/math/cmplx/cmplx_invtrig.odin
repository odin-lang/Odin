package math_cmplx

import "base:builtin"
import "core:math"

// The original C code, the long comment, and the constants
// below are from http://netlib.sandia.gov/cephes/c9x-complex/clog.c.
// The go code is a simplified version of the original C.
//
// Cephes Math Library Release 2.8:  June, 2000
// Copyright 1984, 1987, 1989, 1992, 2000 by Stephen L. Moshier
//
// The readme file at http://netlib.sandia.gov/cephes/ says:
//    Some software in this archive may be from the book _Methods and
// Programs for Mathematical Functions_ (Prentice-Hall or Simon & Schuster
// International, 1989) or from the Cephes Mathematical Library, a
// commercial product. In either event, it is copyrighted by the author.
// What you see here may be used freely but it comes with no support or
// guarantee.
//
//   The two known misprints in the book are repaired here in the
// source listings for the gamma function and the incomplete beta
// integral.
//
//   Stephen L. Moshier
//   moshier@na-net.ornl.gov

acos :: proc{
	acos_complex32,
	acos_complex64,
	acos_complex128,
}
acosh :: proc{
	acosh_complex32,
	acosh_complex64,
	acosh_complex128,
}

asin :: proc{
	asin_complex32,
	asin_complex64,
	asin_complex128,
}
asinh :: proc{
	asinh_complex32,
	asinh_complex64,
	asinh_complex128,
}

atan :: proc{
	atan_complex32,
	atan_complex64,
	atan_complex128,
}

atanh :: proc{
	atanh_complex32,
	atanh_complex64,
	atanh_complex128,
}


acos_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(acos_complex128(complex128(x)))
}
acos_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(acos_complex128(complex128(x)))
}
acos_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	re, im := real(x), imag(x)
	if math.is_inf(re, 0) || math.is_nan(re) || math.is_inf(im, 0) || math.is_nan(im) {
		w := asin(x)
		return complex(math.PI/2 - real(w), -imag(w))
	}
	_, cr, ci := _asin_core_f64(abs(re), abs(im))
	if math.sign_bit(re) {
		cr = math.PI - cr
	}
	return complex(cr, -math.copy_sign(ci, im))
}


acosh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(acosh_complex128(complex128(x)))
}
acosh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(acosh_complex128(complex128(x)))
}
acosh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	if x == 0 {
		return complex(0, math.copy_sign(math.PI/2, imag(x)))
	}
	if math.is_nan(imag(x)) && !math.is_inf(real(x), 0) {
		return complex(imag(x), imag(x))
	}
	w := acos(x)
	return complex(abs(imag(w)), math.copy_sign(real(w), imag(x)))
}

asin_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(asin_complex128(complex128(x)))
}
asin_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(asin_complex128(complex128(x)))
}
asin_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	switch re, im := real(x), imag(x); {
	case im == 0 && abs(re) <= 1:
		return complex(math.asin(re), im)
	case re == 0 && abs(im) <= 1:
		return complex(re, math.asinh(im))
	case math.is_nan(im):
		switch {
		case re == 0:
			return complex(re, math.nan_f64())
		case math.is_inf(re, 0):
			return complex(math.nan_f64(), re)
		case:
			return nan_complex128()
		}
	case math.is_inf(im, 0):
		switch {
		case math.is_nan(re):
			return x
		case math.is_inf(re, 0):
			return complex(math.copy_sign(math.PI/4, re), im)
		case:
			return complex(math.copy_sign(0, re), im)
		}
	case math.is_inf(re, 0):
		return complex(math.copy_sign(math.PI/2, re), math.copy_sign(re, im))
	}
	ar, _, ai := _asin_core_f64(abs(real(x)), abs(imag(x)))
	return complex(math.copy_sign(ar, real(x)), math.copy_sign(ai, imag(x)))
}

asinh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(asinh_complex128(complex128(x)))
}
asinh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(asinh_complex128(complex128(x)))
}
asinh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	switch re, im := real(x), imag(x); {
	case im == 0 && abs(re) <= 1:
		return complex(math.asinh(re), im)
	case re == 0 && abs(im) <= 1:
		return complex(re, math.asin(im))
	case math.is_inf(re, 0):
		switch {
		case math.is_inf(im, 0):
			return complex(re, math.copy_sign(math.PI/4, im))
		case math.is_nan(im):
			return x
		case:
			return complex(re, math.copy_sign(0.0, im))
		}
	case math.is_nan(re):
		switch {
		case im == 0:
			return x
		case math.is_inf(im, 0):
			return complex(im, re)
		case:
			return nan_complex128()
		}
	case math.is_inf(im, 0):
		return complex(math.copy_sign(im, re), math.copy_sign(math.PI/2, im))
	}
	ar, _, ai := _asin_core_f64(abs(imag(x)), abs(real(x)))
	return complex(math.copy_sign(ai, real(x)), math.copy_sign(ar, imag(x)))
}


atan_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(atan_complex128(complex128(x)))
}
atan_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(atan_complex128(complex128(x)))
}
atan_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	// Complex circular arc tangent
	//
	// DESCRIPTION:
	//
	// If
	//     z = x + iy,
	//
	// then
	//
	//     Re w  =  1/2 atan2(2x, 1 - x^2 - y^2),
	//
	//                     x^2 + (y + 1)^2
	//     Im w  =  1/4 ln ---------------.
	//                     x^2 + (y - 1)^2
	//
	// atan2 gives the principal value, so Re w lies in [-PI/2, PI/2].
	// 1 - y^2 is evaluated as (1 - |y|)(1 + |y|), and Im w as
	// 1/4 log1p(4|y| / (x^2 + (1 - |y|)^2)) with the sign of y, which
	// avoids cancellation when |y| is near 1 and when y is small.
	// When |x| or |y| exceeds 2^500, Re w is PI/2 with the sign of x
	// and Im w is y/|z|^2, scaled so that |z|^2 does not overflow.
	// For |y| = 1 and |x| below 2^-500, where x^2 would underflow,
	// Im w is (ln 2 - ln|x|)/2 with the sign of y.
	//
	// It is computed as catan(z) = -i catanh(iz), the identity C99 Annex G
	// defines catan by, so it shares catanh's special values.
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    IEEE      -10,+10     30000       1.9e-16     6.1e-17

	w := atanh_complex128(complex(-imag(x), real(x)))
	return complex(imag(w), -real(w))
}

atanh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(atanh_complex128(complex128(x)))
}
atanh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(atanh_complex128(complex128(x)))
}
atanh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	LARGE :: f64(1 << 500)
	TINY  :: 1.0 / (1 << 500)

	re, im := real(x), imag(x)
	ax, ay := abs(re), abs(im)
	rr, ri: f64
	switch {
	case math.is_inf(ax, 0) || math.is_inf(ay, 0):
		rr = 0
		ri = math.PI/2
		if math.is_nan(ay) {
			ri = ay
		}
	case math.is_nan(ax) || math.is_nan(ay):
		if ax == 0 {
			rr, ri = 0, ay
		} else {
			rr, ri = math.nan_f64(), math.nan_f64()
		}
	case ax > LARGE || ay > LARGE:
		p := max(ax, ay)
		q := min(ax, ay) / p
		rr = ((ax/p) / (1 + q*q)) / p
		ri = math.PI/2
	case:
		if ax == 1 && ay < TINY {
			rr = 0.5 * (math.LN2 - math.ln(ay))
		} else {
			d := (1 - ax)*(1 - ax) + ay*ay
			rr = 0.25 * math.log1p(4*ax/d)
		}
		ri = 0.5 * math.atan2(2*ay, (1 - ax)*(1 + ax) - ay*ay)
	}
	return complex(math.copy_sign(rr, re), math.copy_sign(ri, im))
}


@(private="file")
_asin_core_f64 :: proc "contextless" (x, y: f64) -> (asin_re, acos_re, im: f64) {
	A_CROSS   :: 1.5
	B_CROSS   :: 0.6417
	LARGE     :: f64(1 << 500)
	NEAR_ZERO :: 1.0 / (1 << 27)
	TINY      :: 1.0 / (1 << 511)

	if x > LARGE || y > LARGE {
		return math.atan2(x, y), math.atan2(y, x), math.LN2 + _ln_abs_f64(x, y)
	}
	if x < NEAR_ZERO && y < NEAR_ZERO {
		return x, math.PI/2 - x, y
	}

	xp1 := x + 1
	xm1 := x - 1
	r := math.hypot(xp1, y)
	s := math.hypot(xm1, y)
	a := 0.5 * (r + s)
	b := x / a
	y2 := y * y

	if x < 1 && y < TINY {
		im = y / math.sqrt((1 - x)*(1 + x))
	} else if a <= A_CROSS {
		t: f64
		if x < 1 {
			t = y2/(r + xp1) + y2/(s + (1 - x))
		} else {
			t = y2/(r + xp1) + (s + xm1)
		}
		im = math.log1p(0.5*t + math.sqrt(t*(a + 1)*0.5))
	} else {
		im = math.ln(a + math.sqrt(a*a - 1))
	}

	if b <= B_CROSS {
		asin_re = math.asin(b)
		acos_re = math.acos(b)
	} else {
		apx := a + x
		d: f64
		if x <= 1 {
			d = math.sqrt(0.5 * apx * (y2/(r + xp1) + (s + (1 - x))))
		} else {
			d = y * math.sqrt(0.5 * (apx/(r + xp1) + apx/(s + xm1)))
		}
		asin_re = math.atan2(x, d)
		acos_re = math.atan2(d, x)
	}
	return
}
