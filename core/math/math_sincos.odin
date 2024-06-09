package math

import "core:math/bits"

// The original C code, the long comment, and the constants
// below were from http://netlib.sandia.gov/cephes/cmath/sin.c,
// available from http://www.netlib.org/cephes/cmath.tgz.
// The go code is a simplified version of the original C.
//
//      sin.c
//
//      Circular sine
//
// SYNOPSIS:
//
// double x, y, sin();
// y = sin( x );
//
// DESCRIPTION:
//
// Range reduction is into intervals of pi/4.  The reduction error is nearly
// eliminated by contriving an extended precision modular arithmetic.
//
// Two polynomial approximating functions are employed.
// Between 0 and pi/4 the sine is approximated by
//      x  +  x**3 P(x**2).
// Between pi/4 and pi/2 the cosine is represented as
//      1  -  x**2 Q(x**2).
//
// ACCURACY:
//
//                      Relative error:
// arithmetic   domain      # trials      peak         rms
//    DEC       0, 10       150000       3.0e-17     7.8e-18
//    IEEE -1.07e9,+1.07e9  130000       2.1e-16     5.4e-17
//
// Partial loss of accuracy begins to occur at x = 2**30 = 1.074e9.  The loss
// is not gradual, but jumps suddenly to about 1 part in 10e7.  Results may
// be meaningless for x > 2**49 = 5.6e14.
//
//      cos.c
//
//      Circular cosine
//
// SYNOPSIS:
//
// double x, y, cos();
// y = cos( x );
//
// DESCRIPTION:
//
// Range reduction is into intervals of pi/4.  The reduction error is nearly
// eliminated by contriving an extended precision modular arithmetic.
//
// Two polynomial approximating functions are employed.
// Between 0 and pi/4 the cosine is approximated by
//      1  -  x**2 Q(x**2).
// Between pi/4 and pi/2 the sine is represented as
//      x  +  x**3 P(x**2).
//
// ACCURACY:
//
//                      Relative error:
// arithmetic   domain      # trials      peak         rms
//    IEEE -1.07e9,+1.07e9  130000       2.1e-16     5.4e-17
//    DEC        0,+1.07e9   17000       3.0e-17     7.2e-18
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

sincos :: proc{
	sincos_f16, sincos_f16le, sincos_f16be,
	sincos_f32, sincos_f32le, sincos_f32be,
	sincos_f64, sincos_f64le, sincos_f64be,
}

sincos_f16 :: proc "contextless" (x: f16) -> (sin, cos: f16) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f16(s), f16(c)
}
sincos_f16le :: proc "contextless" (x: f16le) -> (sin, cos: f16le) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f16le(s), f16le(c)
}
sincos_f16be :: proc "contextless" (x: f16be) -> (sin, cos: f16be) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f16be(s), f16be(c)
}

sincos_f32 :: proc "contextless" (x: f32) -> (sin, cos: f32) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f32(s), f32(c)
}
sincos_f32le :: proc "contextless" (x: f32le) -> (sin, cos: f32le) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f32le(s), f32le(c)
}
sincos_f32be :: proc "contextless" (x: f32be) -> (sin, cos: f32be) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f32be(s), f32be(c)
}

sincos_f64le :: proc "contextless" (x: f64le) -> (sin, cos: f64le) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f64le(s), f64le(c)
}
sincos_f64be :: proc "contextless" (x: f64be) -> (sin, cos: f64be) #no_bounds_check {
	s, c := sincos_f64(f64(x))
	return f64be(s), f64be(c)
}

sincos_f64 :: proc "contextless" (x: f64) -> (sin, cos: f64) #no_bounds_check {
	x := x

	PI4A :: 0h3fe921fb40000000 // 7.85398125648498535156e-1  PI/4 split into three parts
	PI4B :: 0h3e64442d00000000 // 3.77489470793079817668e-8
	PI4C :: 0h3ce8469898cc5170 // 2.69515142907905952645e-15

	// special cases
	switch {
	case x == 0:
		return x, 1 // return ±0.0, 1.0
	case is_nan(x) || is_inf(x, 0):
		return nan_f64(), nan_f64()
	}

	// make argument positive
	sin_sign, cos_sign := false, false
	if x < 0 {
		x = -x
		sin_sign = true
	}

	j: u64
	y, z: f64
	if x >= REDUCE_THRESHOLD {
		j, z = _trig_reduce_f64(x)
	} else {
		j = u64(x * (4 / PI)) // integer part of x/(PI/4), as integer for tests on the phase angle
		y = f64(j)           // integer part of x/(PI/4), as float

		if j&1 == 1 { // map zeros to origin
			j += 1
			y += 1
		}
		j &= 7                               // octant modulo TAU radians (360 degrees)
		z = ((x - y*PI4A) - y*PI4B) - y*PI4C // Extended precision modular arithmetic
	}
	if j > 3 { // reflect in x axis
		j -= 4
		sin_sign, cos_sign = !sin_sign, !cos_sign
	}
	if j > 1 {
		cos_sign = !cos_sign
	}

	zz := z * z

	cos = 1.0 - 0.5*zz + zz*zz*((((((_cos[0]*zz)+_cos[1])*zz+_cos[2])*zz+_cos[3])*zz+_cos[4])*zz+_cos[5])
	sin = z + z*zz*((((((_sin[0]*zz)+_sin[1])*zz+_sin[2])*zz+_sin[3])*zz+_sin[4])*zz+_sin[5])

	if j == 1 || j == 2 {
		sin, cos = cos, sin
	}
	if cos_sign {
		cos = -cos
	}
	if sin_sign {
		sin = -sin
	}
	return
}

// sin coefficients
@(private="file")
_sin := [?]f64{
	 0h3de5d8fd1fd19ccd, //  1.58962301576546568060e-10
	 0hbe5ae5e5a9291f5d, // -2.50507477628578072866e-8
	 0h3ec71de3567d48a1, //  2.75573136213857245213e-6
	 0hbf2a01a019bfdf03, // -1.98412698295895385996e-4
	 0h3f8111111110f7d0, //  8.33333333332211858878e-3
	 0hbfc5555555555548, // -1.66666666666666307295e-1
}

// cos coefficients
@(private="file")
_cos := [?]f64{
	0hbda8fa49a0861a9b, // -1.13585365213876817300e-11,
	0h3e21ee9d7b4e3f05, //  2.08757008419747316778e-9,
	0hbe927e4f7eac4bc6, // -2.75573141792967388112e-7,
	0h3efa01a019c844f5, //  2.48015872888517045348e-5,
	0hbf56c16c16c14f91, // -1.38888888888730564116e-3,
	0h3fa555555555554b, //  4.16666666666665929218e-2,
}

// REDUCE_THRESHOLD is the maximum value of x where the reduction using Pi/4
// in 3 f64 parts still gives accurate results. This threshold
// is set by y*C being representable as a f64 without error
// where y is given by y = floor(x * (4 / Pi)) and C is the leading partial
// terms of 4/Pi. Since the leading terms (PI4A and PI4B in sin.go) have 30
// and 32 trailing zero bits, y should have less than 30 significant bits.
//
//	y < 1<<30  -> floor(x*4/Pi) < 1<<30 -> x < (1<<30 - 1) * Pi/4
//
// So, conservatively we can take x < 1<<29.
// Above this threshold Payne-Hanek range reduction must be used.
@(private="file")
REDUCE_THRESHOLD :: 1 << 29

// _trig_reduce_f64 implements Payne-Hanek range reduction by Pi/4
// for x > 0. It returns the integer part mod 8 (j) and
// the fractional part (z) of x / (Pi/4).
// The implementation is based on:
// "ARGUMENT REDUCTION FOR HUGE ARGUMENTS: Good to the Last Bit"
// K. C. Ng et al, March 24, 1992
// The simulated multi-precision calculation of x*B uses 64-bit integer arithmetic.
_trig_reduce_f64 :: proc "contextless" (x: f64) -> (j: u64, z: f64) #no_bounds_check {
	// bd_pi4 is the binary digits of 4/pi as a u64 array,
	// that is, 4/pi = Sum bd_pi4[i]*2^(-64*i)
	// 19 64-bit digits and the leading one bit give 1217 bits
	// of precision to handle the largest possible f64 exponent.
	@(static, rodata) bd_pi4 := [?]u64{
		0x0000000000000001,
		0x45f306dc9c882a53,
		0xf84eafa3ea69bb81,
		0xb6c52b3278872083,
		0xfca2c757bd778ac3,
		0x6e48dc74849ba5c0,
		0x0c925dd413a32439,
		0xfc3bd63962534e7d,
		0xd1046bea5d768909,
		0xd338e04d68befc82,
		0x7323ac7306a673e9,
		0x3908bf177bf25076,
		0x3ff12fffbc0b301f,
		0xde5e2316b414da3e,
		0xda6cfd9e4f96136e,
		0x9e8c7ecd3cbfd45a,
		0xea4f758fd7cbe2f6,
		0x7a0e73ef14a525d4,
		0xd7f6bf623f1aba10,
		0xac06608df8f6d757,
	}

	PI4 :: PI / 4
	if x < PI4 {
		return 0, x
	}

	MASK  :: 0x7FF
	SHIFT :: 64 - 11 - 1
	BIAS  :: 1023

	// Extract out the integer and exponent such that,
	// x = ix * 2 ** exp.
	ix := transmute(u64)x
	exp := int(ix>>SHIFT&MASK) - BIAS - SHIFT
	ix &~= MASK << SHIFT
	ix |= 1 << SHIFT
	// Use the exponent to extract the 3 appropriate u64 digits from bd_pi4,
	// B ~ (z0, z1, z2), such that the product leading digit has the exponent -61.
	// Note, exp >= -53 since x >= PI4 and exp < 971 for maximum f64.
	digit, bitshift := uint(exp+61)/64, uint(exp+61)%64
	z0 := (bd_pi4[digit] << bitshift) | (bd_pi4[digit+1] >> (64 - bitshift))
	z1 := (bd_pi4[digit+1] << bitshift) | (bd_pi4[digit+2] >> (64 - bitshift))
	z2 := (bd_pi4[digit+2] << bitshift) | (bd_pi4[digit+3] >> (64 - bitshift))
	// Multiply mantissa by the digits and extract the upper two digits (hi, lo).
	z2hi, _ := bits.mul(z2, ix)
	z1hi, z1lo := bits.mul(z1, ix)
	z0lo := z0 * ix
	lo, c := bits.add(z1lo, z2hi, 0)
	hi, _ := bits.add(z0lo, z1hi, c)
	// The top 3 bits are j.
	j = hi >> 61
	// Extract the fraction and find its magnitude.
	hi = hi<<3 | lo>>61
	lz := uint(bits.leading_zeros(hi))
	e := u64(BIAS - (lz + 1))
	// Clear implicit mantissa bit and shift into place.
	hi = (hi << (lz + 1)) | (lo >> (64 - (lz + 1)))
	hi >>= 64 - SHIFT
	// Include the exponent and convert to a float.
	hi |= e << SHIFT
	z = transmute(f64)hi
	// Map zeros to origin.
	if j&1 == 1 {
		j += 1
		j &= 7
		z -= 1
	}
	// Multiply the fractional part by pi/4.
	return j, z * PI4
}
