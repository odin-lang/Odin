package math

// The original C code, the long comment, and the constants
// below are from http://netlib.sandia.gov/cephes/cprob/gamma.c.
//
//      tgamma.c
//
//      Gamma function
//
// SYNOPSIS:
//
// double x, y, tgamma();
// extern int signgam;
//
// y = tgamma( x );
//
// DESCRIPTION:
//
// Returns gamma function of the argument. The result is
// correctly signed, and the sign (+1 or -1) is also
// returned in a global (extern) variable named signgam.
// This variable is also filled in by the logarithmic gamma
// function lgamma().
//
// Arguments |x| <= 34 are reduced by recurrence and the function
// approximated by a rational function of degree 6/7 in the
// interval (2,3).  Large arguments are handled by Stirling's
// formula. Large negative arguments are made positive using
// a reflection formula.
//
// ACCURACY:
//
//                      Relative error:
// arithmetic   domain     # trials      peak         rms
//    DEC      -34, 34      10000       1.3e-16     2.5e-17
//    IEEE    -170,-33      20000       2.3e-15     3.3e-16
//    IEEE     -33,  33     20000       9.4e-16     2.2e-16
//    IEEE      33, 171.6   20000       2.3e-15     3.2e-16
//
// Error for arguments outside the test range will be larger
// owing to error amplification by the exponential function.
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

// Gamma function computed by Stirling's formula.
// The pair of results must be multiplied together to get the actual answer.
// The multiplication is left to the caller so that, if careful, the caller can avoid
// infinity for 172 <= x <= 180.
// The polynomial is valid for 33 <= x <= 172; larger values are only used
// in reciprocal and produce denormalized floats. The lower precision there
// masks any imprecision in the polynomial.
@(private="file", require_results)
stirling :: proc "contextless" (x: f64) -> (f64, f64) {
	@(static, rodata) gamS := [?]f64{
		+7.87311395793093628397e-04,
		-2.29549961613378126380e-04,
		-2.68132617805781232825e-03,
		+3.47222221605458667310e-03,
		+8.33333333333482257126e-02,
	}
	
	if x > 200 {
		return inf_f64(1), 1
	}
	SQRT_TWO_PI :: 0h40040d931ff62706 // 2.506628274631000502417
	MAX_STIRLING :: 143.01608
	w := 1 / x
	w = 1 + w*((((gamS[0]*w+gamS[1])*w+gamS[2])*w+gamS[3])*w+gamS[4])
	y1 := exp(x)
	y2 := 1.0
	if x > MAX_STIRLING { // avoid pow() overflow
		v := pow(x, 0.5*x-0.25)
		y1, y2 = v, v/y1
	} else {
		y1 = pow(x, x-0.5) / y1
	}
	return y1, SQRT_TWO_PI * w * y2
}

@(require_results)
gamma_f64 :: proc "contextless" (x: f64) -> f64 {
	is_neg_int :: proc "contextless" (x: f64) -> bool {
		if x < 0 {
			_, xf := modf(x)
			return xf == 0
		}
		return false
	}
	
	@(static, rodata) gamP := [?]f64{
		1.60119522476751861407e-04,
		1.19135147006586384913e-03,
		1.04213797561761569935e-02,
		4.76367800457137231464e-02,
		2.07448227648435975150e-01,
		4.94214826801497100753e-01,
		9.99999999999999996796e-01,
	}
	@(static, rodata) gamQ := [?]f64{
		-2.31581873324120129819e-05,
		+5.39605580493303397842e-04,
		-4.45641913851797240494e-03,
		+1.18139785222060435552e-02,
		+3.58236398605498653373e-02,
		-2.34591795718243348568e-01,
		+7.14304917030273074085e-02,
		+1.00000000000000000320e+00,
	}

	
	EULER :: 0.57721566490153286060651209008240243104215933593992 // A001620
	
	switch {
	case is_neg_int(x) || is_inf(x, -1) || is_nan(x):
		return nan_f64()
	case is_inf(x, 1):
		return inf_f64(1)
	case x == 0:
		if sign_bit(x) {
			return inf_f64(-1)
		}
		return inf_f64(1)
	}
	
	x := x
	q := abs(x)
	p := floor(q)
	if q > 33 {
		if x >= 0 {
			y1, y2 := stirling(x)
			return y1 * y2
		}
		// Note: x is negative but (checked above) not a negative integer,
		// so x must be small enough to be in range for conversion to i64.
		// If |x| were >= 2⁶³ it would have to be an integer.
		signgam := 1
		if ip := i64(p); ip&1 == 0 {
			signgam = -1
		}
		z := q - p
		if z > 0.5 {
			p = p + 1
			z = q - p
		}
		z = q * sin(PI*z)
		if z == 0 {
			return inf_f64(signgam)
		}
		sq1, sq2 := stirling(q)
		absz := abs(z)
		d := absz * sq1 * sq2
		if is_inf(d, 0) {
			z = PI / absz / sq1 / sq2
		} else {
			z = PI / d
		}
		return f64(signgam) * z
	}

	// Reduce argument
	z := 1.0
	for x >= 3 {
		x = x - 1
		z = z * x
	}
	for x < 0 {
		if x > -1e-09 {
			if x == 0 {
				return inf_f64(1)
			}
			return z / ((1 + EULER*x) * x)
		}
		z = z / x
		x = x + 1
	}
	for x < 2 {
		if x < 1e-09 {
			if x == 0 {
				return inf_f64(1)
			}
			return z / ((1 + EULER*x) * x)
		}
		z = z / x
		x = x + 1
	}

	if x == 2 {
		return z
	}

	x = x - 2
	p = (((((x*gamP[0]+gamP[1])*x+gamP[2])*x+gamP[3])*x+gamP[4])*x+gamP[5])*x + gamP[6]
	q = ((((((x*gamQ[0]+gamQ[1])*x+gamQ[2])*x+gamQ[3])*x+gamQ[4])*x+gamQ[5])*x+gamQ[6])*x + gamQ[7]
	return z * p / q
}


@(require_results) gamma_f16   :: proc "contextless" (x: f16)   -> f16   { return f16(gamma_f64(f64(x))) }
@(require_results) gamma_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(gamma_f64(f64(x))) }
@(require_results) gamma_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(gamma_f64(f64(x))) }
@(require_results) gamma_f32   :: proc "contextless" (x: f32)   -> f32   { return f32(gamma_f64(f64(x))) }
@(require_results) gamma_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(gamma_f64(f64(x))) }
@(require_results) gamma_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(gamma_f64(f64(x))) }
@(require_results) gamma_f64le :: proc "contextless" (x: f64le) -> f64le { return f64le(gamma_f64(f64(x))) }
@(require_results) gamma_f64be :: proc "contextless" (x: f64be) -> f64be { return f64be(gamma_f64(f64(x))) }

gamma :: proc{
	gamma_f16, gamma_f16le, gamma_f16be,
	gamma_f32, gamma_f32le, gamma_f32be,
	gamma_f64, gamma_f64le, gamma_f64be,
}