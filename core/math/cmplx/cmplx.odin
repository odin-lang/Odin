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

abs  :: builtin.abs
conj :: builtin.conj
real :: builtin.real
imag :: builtin.imag
jmag :: builtin.jmag
kmag :: builtin.kmag


sin :: proc{
	sin_complex128,
}
cos :: proc{
	cos_complex128,
}
tan :: proc{
	tan_complex128,
}
cot :: proc{
	cot_complex128,
}


sinh :: proc{
	sinh_complex128,
}
cosh :: proc{
	cosh_complex128,
}
tanh :: proc{
	tanh_complex128,
}



// sqrt returns the square root of x.
// The result r is chosen so that real(r) ≥ 0 and imag(r) has the same sign as imag(x).
sqrt :: proc{
	sqrt_complex32,
	sqrt_complex64,
	sqrt_complex128,
}
ln :: proc{
	ln_complex32,
	ln_complex64,
	ln_complex128,
}
log10 :: proc{
	log10_complex32,
	log10_complex64,
	log10_complex128,
}

exp :: proc{
	exp_complex32,
	exp_complex64,
	exp_complex128,
}

pow :: proc{
	pow_complex32,
	pow_complex64,
	pow_complex128,
}

phase :: proc{
	phase_complex32,
	phase_complex64,
	phase_complex128,
}

polar :: proc{
	polar_complex32,
	polar_complex64,
	polar_complex128,
}

is_inf :: proc{
	is_inf_complex32,
	is_inf_complex64,
	is_inf_complex128,
}

is_nan :: proc{
	is_nan_complex32,
	is_nan_complex64,
	is_nan_complex128,
}



// sqrt_complex32 returns the square root of x.
// The result r is chosen so that real(r) ≥ 0 and imag(r) has the same sign as imag(x).
sqrt_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(sqrt_complex128(complex128(x)))
}

// sqrt_complex64 returns the square root of x.
// The result r is chosen so that real(r) ≥ 0 and imag(r) has the same sign as imag(x).
sqrt_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex64(sqrt_complex128(complex128(x)))
}


// sqrt_complex128 returns the square root of x.
// The result r is chosen so that real(r) ≥ 0 and imag(r) has the same sign as imag(x).
sqrt_complex128 :: proc "contextless" (x: complex128) -> complex128 {
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

	// Complex square root
	//
	// DESCRIPTION:
	//
	// If z = x + iy,  r = |z|, then
	//
	//                       1/2
	// Re w  =  [ (r + x)/2 ]   ,
	//
	//                       1/2
	// Im w  =  [ (r - x)/2 ]   .
	//
	// Cancellation error in r-x or r+x is avoided by using the
	// identity  2 Re w Im w  =  y.
	//
	// Note that -w is also a square root of z. The root chosen
	// is always in the right half plane and Im w has the same sign as y.
	//
	// ACCURACY:
	//
	//                      Relative error:
	// arithmetic   domain     # trials      peak         rms
	//    DEC       -10,+10     25000       3.2e-17     9.6e-18
	//    IEEE      -10,+10   1,000,000     2.9e-16     6.1e-17

	if imag(x) == 0 {
		// Ensure that imag(r) has the same sign as imag(x) for imag(x) == signed zero.
		if real(x) == 0 {
			return complex(0, imag(x))
		}
		if real(x) < 0 {
			return complex(0, math.copy_sign(math.sqrt(-real(x)), imag(x)))
		}
		return complex(math.sqrt(real(x)), imag(x))
	} else if math.is_inf(imag(x), 0) {
		return complex(math.inf_f64(1.0), imag(x))
	}
	if real(x) == 0 {
		if imag(x) < 0 {
			r := math.sqrt(-0.5 * imag(x))
			return complex(r, -r)
		}
		r := math.sqrt(0.5 * imag(x))
		return complex(r, r)
	}
	a := real(x)
	b := imag(x)
	scale: f64
	// Rescale to avoid internal overflow or underflow.
	if abs(a) > 4 || abs(b) > 4 {
		a *= 0.25
		b *= 0.25
		scale = 2
	} else {
		a *= 1.8014398509481984e16 // 2**54
		b *= 1.8014398509481984e16
		scale = 7.450580596923828125e-9 // 2**-27
	}
	r := math.hypot(a, b)
	t: f64
	if a > 0 {
		t = math.sqrt(0.5*r + 0.5*a)
		r = scale * abs((0.5*b)/t)
		t *= scale
	} else {
		r = math.sqrt(0.5*r - 0.5*a)
		t = scale * abs((0.5*b)/r)
		r *= scale
	}
	if b < 0 {
		return complex(t, -r)
	}
	return complex(t, r)
}

ln_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(ln_complex64(complex64(x)))
}
ln_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return complex(math.ln(abs(x)), phase(x))
}
ln_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	return complex(math.ln(abs(x)), phase(x))
}


exp_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(exp_complex64(complex64(x)))
}
exp_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	switch re, im := real(x), imag(x); {
	case math.is_inf(re, 0):
		switch {
		case re > 0 && im == 0:
			return x
		case math.is_inf(im, 0) || math.is_nan(im):
			if re < 0 {
				return complex(0, math.copy_sign(0, im))
			} else {
				return complex(math.inf_f64(1.0), math.nan_f64())
			}
		}
	case math.is_nan(re):
		if im == 0 {
			return complex(math.nan_f32(), im)
		}
	}
	r := math.exp(real(x))
	s, c := math.sincos(imag(x))
	return complex(r*c, r*s)
}
exp_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	switch re, im := real(x), imag(x); {
	case math.is_inf(re, 0):
		switch {
		case re > 0 && im == 0:
			return x
		case math.is_inf(im, 0) || math.is_nan(im):
			if re < 0 {
				return complex(0, math.copy_sign(0, im))
			} else {
				return complex(math.inf_f64(1.0), math.nan_f64())
			}
		}
	case math.is_nan(re):
		if im == 0 {
			return complex(math.nan_f64(), im)
		}
	}
	r := math.exp(real(x))
	s, c := math.sincos(imag(x))
	return complex(r*c, r*s)
}


pow_complex32 :: proc "contextless" (x, y: complex32) -> complex32 {
	return complex32(pow_complex64(complex64(x), complex64(y)))
}
pow_complex64 :: proc "contextless" (x, y: complex64) -> complex64 {
	if x == 0 { // Guaranteed also true for x == -0.
		if is_nan(y) {
			return nan_complex64()
		}
		r, i := real(y), imag(y)
		switch {
		case r == 0:
			return 1
		case r < 0:
			if i == 0 {
				return complex(math.inf_f32(1), 0)
			}
			return inf_complex64()
		case r > 0:
			return 0
		}
		unreachable()
	}
	modulus := abs(x)
	if modulus == 0 {
		return complex(0, 0)
	}
	r := math.pow(modulus, real(y))
	arg := phase(x)
	theta := real(y) * arg
	if imag(y) != 0 {
		r *= math.exp(-imag(y) * arg)
		theta += imag(y) * math.ln(modulus)
	}
	s, c := math.sincos(theta)
	return complex(r*c, r*s)
}
pow_complex128 :: proc "contextless" (x, y: complex128) -> complex128 {
	if x == 0 { // Guaranteed also true for x == -0.
		if is_nan(y) {
			return nan_complex128()
		}
		r, i := real(y), imag(y)
		switch {
		case r == 0:
			return 1
		case r < 0:
			if i == 0 {
				return complex(math.inf_f64(1), 0)
			}
			return inf_complex128()
		case r > 0:
			return 0
		}
		unreachable()
	}
	modulus := abs(x)
	if modulus == 0 {
		return complex(0, 0)
	}
	r := math.pow(modulus, real(y))
	arg := phase(x)
	theta := real(y) * arg
	if imag(y) != 0 {
		r *= math.exp(-imag(y) * arg)
		theta += imag(y) * math.ln(modulus)
	}
	s, c := math.sincos(theta)
	return complex(r*c, r*s)
}



log10_complex32 :: proc "contextless" (x: complex32) -> complex32 {
	return complex32(log10_complex64(complex64(x)))
}
log10_complex64 :: proc "contextless" (x: complex64) -> complex64 {
	return math.LN10*ln(x)
}
log10_complex128 :: proc "contextless" (x: complex128) -> complex128 {
	return math.LN10*ln(x)
}


phase_complex32 :: proc "contextless" (x:  complex32) -> f16 {
	return f16(phase_complex64(complex64(x)))
}
phase_complex64 :: proc "contextless" (x:  complex64) -> f32 {
	return math.atan2(imag(x), real(x))
}
phase_complex128 :: proc "contextless" (x:  complex128) -> f64 {
	return math.atan2(imag(x), real(x))
}


rect_complex32 :: proc "contextless" (r, θ: f16) -> complex32 {
	return complex32(rect_complex64(f32(r), f32(θ)))
}
rect_complex64 :: proc "contextless" (r, θ: f32) -> complex64 {
	s, c := math.sincos(θ)
	return complex(r*c, r*s)
}
rect_complex128 :: proc "contextless" (r, θ: f64) -> complex128 {
	s, c := math.sincos(θ)
	return complex(r*c, r*s)
}

polar_complex32 :: proc "contextless" (x: complex32) -> (r, θ: f16) {
	return abs(x), phase(x)
}
polar_complex64 :: proc "contextless" (x: complex64) -> (r, θ: f32) {
	return abs(x), phase(x)
}
polar_complex128 :: proc "contextless" (x: complex128) -> (r, θ: f64) {
	return abs(x), phase(x)
}




nan_complex32 :: proc "contextless" () -> complex32 {
	return complex(math.nan_f16(), math.nan_f16())
}
nan_complex64 :: proc "contextless" () -> complex64 {
	return complex(math.nan_f32(), math.nan_f32())
}
nan_complex128 :: proc "contextless" () -> complex128 {
	return complex(math.nan_f64(), math.nan_f64())
}


inf_complex32 :: proc "contextless" () -> complex32 {
	inf := math.inf_f16(1)
	return complex(inf, inf)
}
inf_complex64 :: proc "contextless" () -> complex64 {
	inf := math.inf_f32(1)
	return complex(inf, inf)
}
inf_complex128 :: proc "contextless" () -> complex128 {
	inf := math.inf_f64(1)
	return complex(inf, inf)
}


is_inf_complex32 :: proc "contextless" (x: complex32) -> bool {
	return math.is_inf(real(x), 0) || math.is_inf(imag(x), 0)
}
is_inf_complex64 :: proc "contextless" (x: complex64) -> bool {
	return math.is_inf(real(x), 0) || math.is_inf(imag(x), 0)
}
is_inf_complex128 :: proc "contextless" (x: complex128) -> bool {
	return math.is_inf(real(x), 0) || math.is_inf(imag(x), 0)
}


is_nan_complex32 :: proc "contextless" (x: complex32) -> bool {
	if math.is_inf(real(x), 0) || math.is_inf(imag(x), 0) {
		return false
	}
	return math.is_nan(real(x)) || math.is_nan(imag(x))
}
is_nan_complex64 :: proc "contextless" (x: complex64) -> bool {
	if math.is_inf(real(x), 0) || math.is_inf(imag(x), 0) {
		return false
	}
	return math.is_nan(real(x)) || math.is_nan(imag(x))
}
is_nan_complex128 :: proc "contextless" (x: complex128) -> bool {
	if math.is_inf(real(x), 0) || math.is_inf(imag(x), 0) {
		return false
	}
	return math.is_nan(real(x)) || math.is_nan(imag(x))
}
