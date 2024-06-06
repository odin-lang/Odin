package math_cmplx

import "core:math"
import "core:math/bits"

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
	// csin(z) = -i csinh(iz).
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    DEC       -10,+10      8400       5.3e-17     1.3e-17
	//    IEEE      -10,+10     30000       3.8e-16     1.0e-16
	// Also tested by csin(casin(z)) = z.

	switch re, im := real(x), imag(x); {
	case im == 0 && (math.is_inf(re, 0) || math.is_nan(re)):
		return complex(math.nan_f64(), im)
	case math.is_inf(im, 0):
		switch {
		case re == 0:
			return x
		case math.is_inf(re, 0) || math.is_nan(re):
			return complex(math.nan_f64(), im)
		}
	case re == 0 && math.is_nan(im):
		return x
	}
	s, c := math.sincos(real(x))
	sh, ch := _sinhcosh_f64(imag(x))
	return complex(s*ch, c*sh)
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
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    DEC       -10,+10      8400       4.5e-17     1.3e-17
	//    IEEE      -10,+10     30000       3.8e-16     1.0e-16

	switch re, im := real(x), imag(x); {
	case im == 0 && (math.is_inf(re, 0) || math.is_nan(re)):
		return complex(math.nan_f64(), -im*math.copy_sign(0, re))
	case math.is_inf(im, 0):
		switch {
		case re == 0:
			return complex(math.inf_f64(1), -re*math.copy_sign(0, im))
		case math.is_inf(re, 0) || math.is_nan(re):
			return complex(math.inf_f64(1), math.nan_f64())
		}
	case re == 0 && math.is_nan(im):
		return complex(math.nan_f64(), 0)
	}
	s, c := math.sincos(real(x))
	sh, ch := _sinhcosh_f64(imag(x))
	return complex(c*ch, -s*sh)
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
	s, c := math.sincos(imag(x))
	sh, ch := _sinhcosh_f64(real(x))
	return complex(c*sh, s*ch)
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
	s, c := math.sincos(imag(x))
	sh, ch := _sinhcosh_f64(real(x))
	return complex(c*ch, s*sh)
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
	//           sin 2x  +  i sinh 2y
	//     w  =  --------------------.
	//            cos 2x  +  cosh 2y
	//
	// On the real axis the denominator is zero at odd multiples
	// of PI/2. The denominator is evaluated by its Taylor
	// series near these points.
	//
	// ctan(z) = -i ctanh(iz).
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    DEC       -10,+10      5200       7.1e-17     1.6e-17
	//    IEEE      -10,+10     30000       7.2e-16     1.2e-16
	// Also tested by ctan * ccot = 1 and catan(ctan(z))  =  z.

	switch re, im := real(x), imag(x); {
	case math.is_inf(im, 0):
		switch {
		case math.is_inf(re, 0) || math.is_nan(re):
			return complex(math.copy_sign(0, re), math.copy_sign(1, im))
		}
		return complex(math.copy_sign(0, math.sin(2*re)), math.copy_sign(1, im))
	case re == 0 && math.is_nan(im):
		return x
	}
	d := math.cos(2*real(x)) + math.cosh(2*imag(x))
	if abs(d) < 0.25 {
		d = _tan_series_f64(x)
	}
	if d == 0 {
		return inf_complex128()
	}
	return complex(math.sin(2*real(x))/d, math.sinh(2*imag(x))/d)
}

tanh_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	switch re, im := real(x), imag(x); {
	case math.is_inf(re, 0):
		switch {
		case math.is_inf(im, 0) || math.is_nan(im):
			return complex(math.copy_sign(1, re), math.copy_sign(0, im))
		}
		return complex(math.copy_sign(1, re), math.copy_sign(0, math.sin(2*im)))
	case im == 0 && math.is_nan(re):
		return x
	}
	d := math.cosh(2*real(x)) + math.cos(2*imag(x))
	if d == 0 {
		return inf_complex128()
	}
	return complex(math.sinh(2*real(x))/d, math.sin(2*imag(x))/d)
}

cot_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	d := math.cosh(2*imag(x)) - math.cos(2*real(x))
	if abs(d) < 0.25 {
		d = _tan_series_f64(x)
	}
	if d == 0 {
		return inf_complex128()
	}
	return complex(math.sin(2*real(x))/d, -math.sinh(2*imag(x))/d)
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


// taylor series of cosh(2y) - cos(2x)
@(private)
_tan_series_f64 :: proc "contextless" (z: complex128) -> f64 {
	MACH_EPSILON :: 1.0 / (1 << 53)

	x := abs(2 * real(z))
	y := abs(2 * imag(z))
	x = _reduce_pi_f64(x)
	x, y = x * x, y * y
	x2, y2 := 1.0, 1.0
	f, rn, d := 1.0, 0.0, 0.0

	for {
		rn += 1
		f *= rn
		rn += 1
		f *= rn
		x2 *= x
		y2 *= y
		t := y2 + x2
		t /= f
		d += t

		rn += 1
		f *= rn
		rn += 1
		f *= rn
		x2 *= x
		y2 *= y
		t = y2 - x2
		t /= f
		d += t
		if !(abs(t/d) > MACH_EPSILON) { // don't use <=, because of floating point nonsense and NaN
			break
		}
	}
	return d
}

// _reduce_pi_f64 reduces the input argument x to the range (-PI/2, PI/2].
// x must be greater than or equal to 0. For small arguments it
// uses Cody-Waite reduction in 3 f64 parts based on:
// "Elementary Function Evaluation:  Algorithms and Implementation"
// Jean-Michel Muller, 1997.
// For very large arguments it uses Payne-Hanek range reduction based on:
// "ARGUMENT REDUCTION FOR HUGE ARGUMENTS: Good to the Last Bit"
@(private)
_reduce_pi_f64 :: proc "contextless" (x: f64) -> f64 #no_bounds_check {
	x := x

	// REDUCE_THRESHOLD is the maximum value of x where the reduction using
	// Cody-Waite reduction still gives accurate results. This threshold
	// is set by t*PIn being representable as a f64 without error
	// where t is given by t = floor(x * (1 / PI)) and PIn are the leading partial
	// terms of PI. Since the leading terms, PI1 and PI2 below, have 30 and 32
	// trailing zero bits respectively, t should have less than 30 significant bits.
	//	t < 1<<30  -> floor(x*(1/PI)+0.5) < 1<<30 -> x < (1<<30-1) * PI - 0.5
	// So, conservatively we can take x < 1<<30.
	REDUCE_THRESHOLD :: f64(1 << 30)

	if abs(x) < REDUCE_THRESHOLD {
		// Use Cody-Waite reduction in three parts.
		// PI1, PI2 and PI3 comprise an extended precision value of PI
		// such that PI ~= PI1 + PI2 + PI3. The parts are chosen so
		// that PI1 and PI2 have an approximately equal number of trailing
		// zero bits. This ensures that t*PI1 and t*PI2 are exact for
		// large integer values of t. The full precision PI3 ensures the
		// approximation of PI is accurate to 102 bits to handle cancellation
		// during subtraction.
		PI1 :: 0h400921fb40000000 // 3.141592502593994
		PI2 :: 0h3e84442d00000000 // 1.5099578831723193e-07
		PI3 :: 0h3d08469898cc5170 // 1.0780605716316238e-14

		t := x / math.PI
		t += 0.5
		t = f64(i64(t)) // i64(t) = the multiple
		return ((x - t*PI1) - t*PI2) - t*PI3
	}
	// Must apply Payne-Hanek range reduction
	MASK      :: 0x7FF
	SHIFT     :: 64 - 11 - 1
	BIAS      :: 1023
	FRAC_MASK :: 1<<SHIFT - 1

	// Extract out the integer and exponent such that,
	// x = ix * 2 ** exp.
	ix := transmute(u64)(x)
	exp := int(ix>>SHIFT&MASK) - BIAS - SHIFT
	ix &= FRAC_MASK
	ix |= 1 << SHIFT

	// bdpi is the binary digits of 1/PI as a u64 array,
	// that is, 1/PI = SUM bdpi[i]*2^(-64*i).
	// 19 64-bit digits give 1216 bits of precision
	// to handle the largest possible f64 exponent.
	@(static, rodata) bdpi := [?]u64{
		0x0000000000000000,
		0x517cc1b727220a94,
		0xfe13abe8fa9a6ee0,
		0x6db14acc9e21c820,
		0xff28b1d5ef5de2b0,
		0xdb92371d2126e970,
		0x0324977504e8c90e,
		0x7f0ef58e5894d39f,
		0x74411afa975da242,
		0x74ce38135a2fbf20,
		0x9cc8eb1cc1a99cfa,
		0x4e422fc5defc941d,
		0x8ffc4bffef02cc07,
		0xf79788c5ad05368f,
		0xb69b3f6793e584db,
		0xa7a31fb34f2ff516,
		0xba93dd63f5f2f8bd,
		0x9e839cfbc5294975,
		0x35fdafd88fc6ae84,
		0x2b0198237e3db5d5,
	}

	// Use the exponent to extract the 3 appropriate u64 digits from bdpi,
	// B ~ (z0, z1, z2), such that the product leading digit has the exponent -64.
	// Note, exp >= 50 since x >= REDUCE_THRESHOLD and exp < 971 for maximum f64.
	digit, bitshift := uint(exp+64)/64, uint(exp+64)%64
	z0 := (bdpi[digit] << bitshift) | (bdpi[digit+1] >> (64 - bitshift))
	z1 := (bdpi[digit+1] << bitshift) | (bdpi[digit+2] >> (64 - bitshift))
	z2 := (bdpi[digit+2] << bitshift) | (bdpi[digit+3] >> (64 - bitshift))

	// Multiply mantissa by the digits and extract the upper two digits (hi, lo).
	z2hi, _    := bits.mul(z2, ix)
	z1hi, z1lo := bits.mul(z1, ix)
	z0lo  := z0 * ix
	lo, c := bits.add(z1lo, z2hi, 0)
	hi, _ := bits.add(z0lo, z1hi, c)

	// Find the magnitude of the fraction.
	lz := uint(bits.leading_zeros(hi))
	e  := u64(BIAS - (lz + 1))

	// Clear implicit mantissa bit and shift into place.
	hi = (hi << (lz + 1)) | (lo >> (64 - (lz + 1)))
	hi >>= 64 - SHIFT

	// Include the exponent and convert to a float.
	hi |= e << SHIFT
	x = transmute(f64)(hi)

	// map to (-PI/2, PI/2]
	if x > 0.5 {
		x -= 1
	}
	return math.PI * x
}

