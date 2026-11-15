package math_cmplx

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

sin_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(sin_complex128(complex128(x)))
}
sin_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(sin_complex128(complex128(x)))
}
sin_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	// Complex circular sine
	//
	// DESCRIPTION:
	//
	// If
	//     z = x + iy,
	//
	// then
	//
	//     w = sin x  cosh y  +  i cos x sinh y.
	//
	// It is computed as csin(z) = -i csinh(iz), the identity C99 Annex G
	// defines csin by, so it shares csinh's special values.
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    IEEE      -10,+10     30000       4.1e-16     1.0e-16

	w := sinh_complex128(complex(-imag(x), real(x)))
	return complex(imag(w), -real(w))
}

cos_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(cos_complex128(complex128(x)))
}
cos_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(cos_complex128(complex128(x)))
}
cos_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	// Complex circular cosine
	//
	// DESCRIPTION:
	//
	// If
	//     z = x + iy,
	//
	// then
	//
	//     w = cos x  cosh y  -  i sin x sinh y.
	//
	// It is computed as ccos(z) = ccosh(iz), the identity C99 Annex G
	// defines ccos by, so it shares ccosh's special values.
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    IEEE      -10,+10     30000       3.7e-16     1.1e-16

	return cosh_complex128(complex(-imag(x), real(x)))
}

sinh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(sinh_complex128(complex128(x)))
}
sinh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(sinh_complex128(complex128(x)))
}
sinh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	// Complex hyperbolic sine
	//
	// DESCRIPTION:
	//
	// csinh z = (cexp(z) - cexp(-z))/2
	//         = sinh x * cos y  +  i cosh x * sin y .
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    IEEE      -10,+10     30000       3.1e-16     8.2e-17

	switch re, im := real(x), imag(x); {
	case re == 0 && (math.is_inf(im, 0) || math.is_nan(im)):
		return complex(re, math.nan_f64())
	case math.is_inf(re, 0):
		switch {
		case im == 0:
			return complex(re, im)
		case math.is_inf(im, 0) || math.is_nan(im):
			return complex(re, math.nan_f64())
		}
	case im == 0 && math.is_nan(re):
		return complex(math.nan_f64(), im)
	}
	if imag(x) == 0 {
		return complex(math.sinh(real(x)), imag(x))
	}
	s, c := math.sincos(imag(x))
	if abs(real(x)) > 709 {
		h := math.exp(0.5 * abs(real(x)))
		v := 0.5 * h
		return complex(math.copy_sign(1, real(x)) * ((v*c)*h), (v*s)*h)
	}
	sh, ch := _sinhcosh_f64(real(x))
	return complex(c*sh, s*ch)
}

cosh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(cosh_complex128(complex128(x)))
}
cosh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(cosh_complex128(complex128(x)))
}
cosh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	// Complex hyperbolic cosine
	//
	// DESCRIPTION:
	//
	// ccosh(z) = cosh x  cos y + i sinh x sin y .
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    IEEE      -10,+10     30000       2.9e-16     8.1e-17

	switch re, im := real(x), imag(x); {
	case re == 0 && (math.is_inf(im, 0) || math.is_nan(im)):
		return complex(math.nan_f64(), re*math.copy_sign(0, im))
	case math.is_inf(re, 0):
		switch {
		case im == 0:
			return complex(math.inf_f64(1), im*math.copy_sign(0, re))
		case math.is_inf(im, 0) || math.is_nan(im):
			return complex(math.inf_f64(1), math.nan_f64())
		}
	case im == 0 && math.is_nan(re):
		return complex(math.nan_f64(), im)
	}
	if imag(x) == 0 {
		return complex(math.cosh(real(x)), imag(x) * math.copy_sign(1, real(x)))
	}
	s, c := math.sincos(imag(x))
	if abs(real(x)) > 709 {
		h := math.exp(0.5 * abs(real(x)))
		v := 0.5 * h
		return complex((v*c)*h, math.copy_sign(1, real(x)) * ((v*s)*h))
	}
	sh, ch := _sinhcosh_f64(real(x))
	return complex(c*ch, s*sh)
}

tan_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(tan_complex128(complex128(x)))
}
tan_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(tan_complex128(complex128(x)))
}
tan_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	// Complex circular tangent
	//
	// DESCRIPTION:
	//
	// If
	//     z = x + iy,
	//
	// then
	//
	//           sin x cos x  +  i sinh y cosh y
	//     w  =  -------------------------------.
	//                cos^2 x  +  sinh^2 y
	//
	// This is Kahan's form of (sin 2x + i sinh 2y)/(cos 2x + cosh 2y).
	// It needs no doubled arguments, which can overflow, and it avoids
	// Inf/Inf once cosh 2y overflows. The denominator is zero only at
	// the poles, odd multiples of PI/2 on the real axis.
	//
	// It is computed as ctan(z) = -i ctanh(iz), the identity C99 Annex G
	// defines ctan by, so it shares ctanh's special values.
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    IEEE      -10,+10     30000       5.4e-16     1.3e-16

	w := tanh_complex128(complex(-imag(x), real(x)))
	return complex(imag(w), -real(w))
}

tanh_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(tanh_complex128(complex128(x)))
}
tanh_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(tanh_complex128(complex128(x)))
}
tanh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	re, im := real(x), imag(x)
	if math.is_inf(re, 0) {
		if math.is_inf(im, 0) || math.is_nan(im) {
			return complex(math.copy_sign(1, re), math.copy_sign(0, im))
		}
	} else if math.is_nan(re) || math.is_inf(im, 0) || math.is_nan(im) {
		if im == 0 {
			return x
		}
		return complex(math.nan_f64(), math.nan_f64())
	}
	s, c := math.sincos(im)
	if abs(re) > 22 {
		e := math.exp(-2 * abs(re))
		return complex(math.copy_sign(1, re), 4*s*c*e)
	}
	sh, ch := _sinhcosh_f64(re)
	d := sh*sh + c*c
	return complex(sh*ch/d, s*c/d)
}

cot_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(cot_complex128(complex128(x)))
}
cot_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(cot_complex128(complex128(x)))
}
cot_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	w := _coth_f64(complex(-imag(x), real(x)))
	return complex(-imag(w), real(w))
}


@(private="file")
_coth_f64 :: proc "contextless" (x: complex128) -> complex128 {
	NEAR_ZERO :: 1.0 / (1 << 27)

	re, im := real(x), imag(x)
	if math.is_inf(re, 0) {
		if math.is_inf(im, 0) || math.is_nan(im) {
			return complex(math.copy_sign(1, re), math.copy_sign(0, -im))
		}
	} else if math.is_nan(re) || math.is_inf(im, 0) || math.is_nan(im) {
		if im == 0 {
			return complex(re, -im)
		}
		return complex(math.nan_f64(), math.nan_f64())
	}
	p := max(abs(re), abs(im))
	if p < NEAR_ZERO {
		if p == 0 {
			return inf_complex128()
		}
		a, b := re/p, im/p
		d := p * (a*a + b*b)
		return complex(a/d, -b/d)
	}
	s, c := math.sincos(im)
	if abs(re) > 22 {
		e := math.exp(-2 * abs(re))
		return complex(math.copy_sign(1, re), -4*s*c*e)
	}
	sh, ch := _sinhcosh_f64(re)
	d := sh*sh + s*s
	return complex(sh*ch/d, -s*c/d)
}

@(private="file")
_sinhcosh_f64 :: proc "contextless" (x: f64) -> (sh, ch: f64) {
	if abs(x) <= 0.5 {
		return math.sinh(x), math.cosh(x)
	}
	e := math.exp(x)
	ei := 0.5 / e
	e *= 0.5
	return e - ei, e + ei
}
