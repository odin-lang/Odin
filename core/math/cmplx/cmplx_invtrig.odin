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
	//          1       (    2x     )
	// Re w  =  - arctan(-----------)  +  k PI
	//          2       (     2    2)
	//                  (1 - x  - y )
	//
	//               ( 2         2)
	//          1    (x  +  (y+1) )
	// Im w  =  - log(------------)
	//          4    ( 2         2)
	//               (x  +  (y-1) )
	//
	// Where k is an arbitrary integer.
	//
	// catan(z) = -i catanh(iz).
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    DEC       -10,+10      5900       1.3e-16     7.8e-18
	//    IEEE      -10,+10     30000       2.3e-15     8.5e-17
	// The check catan( ctan(z) )  =  z, with |x| and |y| < PI/2,
	// had peak relative error 1.5e-16, rms relative error
	// 2.9e-17.  See also clog().

	switch re, im := real(x), imag(x); {
	case im == 0:
		return complex(math.atan(re), im)
	case re == 0 && abs(im) <= 1:
		return complex(re, math.atanh(im))
	case math.is_inf(im, 0) || math.is_inf(re, 0):
		if math.is_nan(re) {
			return complex(math.nan_f64(), math.copy_sign(0, im))
		}
		return complex(math.copy_sign(math.PI/2, re), math.copy_sign(0, im))
	case math.is_nan(re) || math.is_nan(im):
		return nan_complex128()
	}
	x2 := real(x) * real(x)
	a := 1 - x2 - imag(x)*imag(x)
	if a == 0 {
		return nan_complex128()
	}
	t := 0.5 * math.atan2(2*real(x), a)
	w := _reduce_pi_f64(t)

	t = imag(x) - 1
	b := x2 + t*t
	if b == 0 {
		return nan_complex128()
	}
	t = imag(x) + 1
	c := (x2 + t*t) / b
	return complex(w, 0.25*math.ln(c))
}

atanh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(atanh_complex64(complex64(x)))
}
atanh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	z := complex(-imag(x), real(x)) // z = i * x
	z = atan(z)
	return complex(imag(z), -real(z)) // z = -i * z
}
atanh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	z := complex(-imag(x), real(x)) // z = i * x
	z = atan(z)
	return complex(imag(z), -real(z)) // z = -i * z
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
