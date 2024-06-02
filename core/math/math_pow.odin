package math


// pow returns x**y, the base-x exponential of y.
//
// Special cases are (in order):
//
//	pow(x, ±0) = 1 for any x
//	pow(1, y) = 1 for any y
//	pow(x, 1) = x for any x
//	pow(NaN, y) = NaN
//	pow(x, NaN) = NaN
//	pow(±0, y) = ±Inf for y an odd integer < 0
//	pow(±0, -Inf) = +Inf
//	pow(±0, +Inf) = +0
//	pow(±0, y) = +Inf for finite y < 0 and not an odd integer
//	pow(±0, y) = ±0 for y an odd integer > 0
//	pow(±0, y) = +0 for finite y > 0 and not an odd integer
//	pow(-1, ±Inf) = 1
//	pow(x, +Inf) = +Inf for |x| > 1
//	pow(x, -Inf) = +0 for |x| > 1
//	pow(x, +Inf) = +0 for |x| < 1
//	pow(x, -Inf) = +Inf for |x| < 1
//	pow(+Inf, y) = +Inf for y > 0
//	pow(+Inf, y) = +0 for y < 0
//	pow(-Inf, y) = pow(-0, -y)
//	pow(x, y) = NaN for finite x < 0 and finite non-integer y
//
// Special cases taken from FreeBSD's /usr/src/lib/msun/src/e_pow.c
// updated by IEEE Std. 754-2008 "Section 9.2.1 Special values".
@(require_results)
pow_f64 :: proc "contextless" (x, y: f64) -> f64 {
	is_odd_int :: proc "contextless" (x: f64) -> bool {
		if abs(x) >= (1<<53) {
			return false
		}

		i, f := modf(x)
		return f == 0 && (i64(i)&1 == 1)
	}

	switch {
	case y == 0 || x == 1:
		return 1.0
	case y == 1:
		return x
	case is_nan(x) || is_nan(y):
		return nan_f64()
	case x == 0:
		switch {
		case y < 0:
			if signbit(x) && is_odd_int(y) {
				return inf_f64(-1)
			}
			return inf_f64(1)
		case y > 0:
			if signbit(x) && is_odd_int(y) {
				return x
			}
			return 0.0
		}
	case is_inf(y, 0):
		switch {
		case x == -1:
			return 1.0
		case (abs(x) < 1) == is_inf(y, 1):
			return 0.0
		case:
			return inf_f64(1)
		}
	case is_inf(x, 0):
		if is_inf(x, -1) {
			// pow(-0, -y)
			return pow_f64(1.0/x, -y)
		}
		switch {
		case y < 0:
			return 0.0
		case y > 0:
			return inf_f64(1)
		}
	case y == 0.5:
		return sqrt_f64(x)
	case y == -0.5:
		return 1.0 / sqrt_f64(x)
	}

	yi, yf := modf(abs(y))
	if yf != 0 && x < 0 {
		return nan_f64()
	}
	if yi >= 1<<63 {
		// yi is a large even int that will lead to overflow (or underflow to 0)
		// for all x except -1 (x == 1 was handled earlier)
		switch {
		case x == -1:
			return 1.0
		case (abs(x) < 1) == (y > 0):
			return 0.0
		case:
			return inf_f64(1)
		}
	}

	// ans = a1 * 2**ae (= 1 for now).
	a1: f64 = 1
	ae: int = 0

	// ans *= x**yf
	if yf != 0 {
		if yf > 0.5 {
			yf -= 1
			yi += 1
		}
		a1 = exp(yf * ln(x))
	}

	// ans *= x**yi
	// by multiplying in successive squarings
	// of x according to bits of yi.
	// accumulate powers of two into exp.
	x1, xe := frexp(x)
	for i := i64(yi); i != 0; i >>= 1 {
		if xe < -1<<12 || 1<<12 < xe {
			// catch xe before it overflows the left shift below
			// Since i !=0 it has at least one bit still set, so ae will accumulate xe
			// on at least one more iteration, ae += xe is a lower bound on ae
			// the lower bound on ae exceeds the size of a f64 exp
			// so the final call to ldexp will produce under/overflow (0/Inf)
			ae += xe
			break
		}
		if i&1 == 1 {
			a1 *= x1
			ae += xe
		}
		x1 *= x1
		xe <<= 1
		if x1 < .5 {
			x1 += x1
			xe -= 1
		}
	}

	// ans = a1*2**ae
	// if y < 0 { ans = 1 / ans }
	// but in the opposite order
	if y < 0 {
		a1 = 1 / a1
		ae = -ae
	}
	return ldexp(a1, ae)
}


@(require_results) pow_f16 :: proc "contextless" (x, power: f16) -> f16 { return f16(pow_f64(f64(x), f64(power))) }
@(require_results) pow_f32 :: proc "contextless" (x, power: f32) -> f32 { return f32(pow_f64(f64(x), f64(power))) }



exp_f64 :: proc "contextless" (x: f64) -> f64 {
	LN2_HI :: 6.93147180369123816490e-01
	LN2_LO :: 1.90821492927058770002e-10
	LOG2_E :: 1.44269504088896338700e+00

	OVERFLOW  :: 7.09782712893383973096e+02
	UNDERFLOW :: -7.45133219101941108420e+02
	NEAR_ZERO  :: 1.0 / (1 << 28) // 2**-28

	// special cases
	switch {
	case is_nan(x) || is_inf(x, 1):
		return x
	case is_inf(x, -1):
		return 0
	case x > OVERFLOW:
		return inf_f64(1)
	case x < UNDERFLOW:
		return 0
	case -NEAR_ZERO < x && x < NEAR_ZERO:
		return 1 + x
	}

	// reduce; computed as r = hi - lo for extra precision.
	k: int
	switch {
	case x < 0:
		k = int(LOG2_E*x - 0.5)
	case x > 0:
		k = int(LOG2_E*x + 0.5)
	}
	hi := x - f64(k)*LN2_HI
	lo := f64(k) * LN2_LO

	P1 :: 0h3FC5555555555555 //  1.66666666666666657415e-01
	P2 :: 0hBF66C16C16BEBD93 // -2.77777777770155933842e-03
	P3 :: 0h3F11566AAF25DE2C //  6.61375632143793436117e-05
	P4 :: 0hBEBBBD41C5D26BF1 // -1.65339022054652515390e-06
	P5 :: 0h3E66376972BEA4D0 //  4.13813679705723846039e-08

	r := hi - lo
	t := r * r
	c := r - t*(P1+t*(P2+t*(P3+t*(P4+t*P5))))
	y := 1 - ((lo - (r*c)/(2-c)) - hi)
	return ldexp(y, k)
}

@(require_results) exp_f16 :: proc "contextless" (x: f16) -> f16 { return f16(exp_f64(f64(x))) }
@(require_results) exp_f32 :: proc "contextless" (x: f32) -> f32 { return f32(exp_f64(f64(x))) }

