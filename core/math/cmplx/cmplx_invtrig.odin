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
	return complex32(acos_complex64(complex64(x)))
}
acos_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	w := asin(x)
	return complex(math.PI/2 - real(w), -imag(w))
}
acos_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	w := asin(x)
	return complex(math.PI/2 - real(w), -imag(w))
}


acosh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(acosh_complex64(complex64(x)))
}
acosh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	if x == 0 {
		return complex(0, math.copy_sign(math.PI/2, imag(x)))
	}
	w := acos(x)
	if imag(w) <= 0 {
		return complex(-imag(w), real(w))
	}
	return complex(imag(w), -real(w))
}
acosh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	if x == 0 {
		return complex(0, math.copy_sign(math.PI/2, imag(x)))
	}
	w := acos(x)
	if imag(w) <= 0 {
		return complex(-imag(w), real(w))
	}
	return complex(imag(w), -real(w))
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
	ct := complex(-imag(x), real(x)) // i * x
	xx := x * x
	x1 := complex(1-real(xx), -imag(xx)) // 1 - x*x
	x2 := sqrt(x1)                       // x2 = sqrt(1 - x*x)
	w  := ln(ct + x2)
	return complex(imag(w), -real(w)) // -i * w
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
	xx := x * x
	x1 := complex(1+real(xx), imag(xx)) // 1 + x*x
	return ln(x + sqrt(x1))            // log(x + sqrt(1 + x*x))
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