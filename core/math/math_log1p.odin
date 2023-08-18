package math

// The original C code, the long comment, and the constants
// below are from FreeBSD's /usr/src/lib/msun/src/s_log1p.c
// and came with this notice. The go code is a simplified
// version of the original C.
//
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//
//
// double log1p(double x)
//
// Method :
//   1. Argument Reduction: find k and f such that
//                      1+x = 2**k * (1+f),
//         where  sqrt(2)/2 < 1+f < sqrt(2) .
//
//      Note. If k=0, then f=x is exact. However, if k!=0, then f
//      may not be representable exactly. In that case, a correction
//      term is need. Let u=1+x rounded. Let c = (1+x)-u, then
//      log(1+x) - log(u) ~ c/u. Thus, we proceed to compute log(u),
//      and add back the correction term c/u.
//      (Note: when x > 2**53, one can simply return log(x))
//
//   2. Approximation of log1p(f).
//      Let s = f/(2+f) ; based on log(1+f) = log(1+s) - log(1-s)
//               = 2s + 2/3 s**3 + 2/5 s**5 + .....,
//               = 2s + s*R
//      We use a special Reme algorithm on [0,0.1716] to generate
//      a polynomial of degree 14 to approximate R The maximum error
//      of this polynomial approximation is bounded by 2**-58.45. In
//      other words,
//                      2      4      6      8      10      12      14
//          R(z) ~ Lp1*s +Lp2*s +Lp3*s +Lp4*s +Lp5*s  +Lp6*s  +Lp7*s
//      (the values of Lp1 to Lp7 are listed in the program)
//      and
//          |      2          14          |     -58.45
//          | Lp1*s +...+Lp7*s    -  R(z) | <= 2
//          |                             |
//      Note that 2s = f - s*f = f - hfsq + s*hfsq, where hfsq = f*f/2.
//      In order to guarantee error in log below 1ulp, we compute log
//      by
//              log1p(f) = f - (hfsq - s*(hfsq+R)).
//
//   3. Finally, log1p(x) = k*ln2 + log1p(f).
//                        = k*ln2_hi+(f-(hfsq-(s*(hfsq+R)+k*ln2_lo)))
//      Here ln2 is split into two floating point number:
//                   ln2_hi + ln2_lo,
//      where n*ln2_hi is always exact for |n| < 2000.
//
// Special cases:
//      log1p(x) is NaN with signal if x < -1 (including -INF) ;
//      log1p(+INF) is +INF; log1p(-1) is -INF with signal;
//      log1p(NaN) is that NaN with no signal.
//
// Accuracy:
//      according to an error analysis, the error is always less than
//      1 ulp (unit in the last place).
//
// Constants:
// The hexadecimal values are the intended ones for the following
// constants. The decimal values may be used, provided that the
// compiler will convert from decimal to binary accurately enough
// to produce the hexadecimal values shown.
//
// Note: Assuming log() return accurate answer, the following
//       algorithm can be used to compute log1p(x) to within a few ULP:
//
//              u = 1+x;
//              if(u==1.0) return x ; else
//                         return log(u)*(x/(u-1.0));
//
//       See HP-15C Advanced Functions Handbook, p.193.

log1p :: proc {
	log1p_f16,
	log1p_f32,
	log1p_f64,
	log1p_f16le,
	log1p_f16be,
	log1p_f32le,
	log1p_f32be,
	log1p_f64le,
	log1p_f64be,
}
@(require_results) log1p_f16   :: proc "contextless" (x: f16)   -> f16   { return f16(log1p_f64(f64(x))) }
@(require_results) log1p_f32   :: proc "contextless" (x: f32)   -> f32   { return f32(log1p_f64(f64(x))) }
@(require_results) log1p_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(log1p_f64(f64(x))) }
@(require_results) log1p_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(log1p_f64(f64(x))) }
@(require_results) log1p_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(log1p_f64(f64(x))) }
@(require_results) log1p_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(log1p_f64(f64(x))) }
@(require_results) log1p_f64le :: proc "contextless" (x: f64le) -> f64le { return f64le(log1p_f64(f64(x))) }
@(require_results) log1p_f64be :: proc "contextless" (x: f64be) -> f64be { return f64be(log1p_f64(f64(x))) }

@(require_results)
log1p_f64 :: proc "contextless" (x: f64) -> f64 {
	SQRT2_M1      :: 0h3fda827999fcef34 // sqrt(2)-1 
	SQRT2_HALF_M1 :: 0hbfd2bec333018866 // sqrt(2)/2-1
	SMALL         :: 0h3e20000000000000 // 2**-29
	TINY          :: 0h3c90000000000000 // 2**-54
	TWO53         :: 0h4340000000000000 // 2**53
	LN2HI         :: 0h3fe62e42fee00000
	LN2LO         :: 0h3dea39ef35793c76
	LP1           :: 0h3FE5555555555593
	LP2           :: 0h3FD999999997FA04
	LP3           :: 0h3FD2492494229359
	LP4           :: 0h3FCC71C51D8E78AF
	LP5           :: 0h3FC7466496CB03DE
	LP6           :: 0h3FC39A09D078C69F
	LP7           :: 0h3FC2F112DF3E5244
	
	switch {
	case x < -1 || is_nan(x):
		return nan_f64()
	case x == -1:
		return inf_f64(-1)
	case is_inf(x, 1):
		return inf_f64(+1)
	}
	absx := abs(x)
	
	f: f64
	iu: u64
	k := 1
	if absx < SQRT2_M1 { //  |x| < sqrt(2)-1
		if absx < SMALL { // |x| < 2**-29
			if absx < TINY { // |x| < 2**-54
				return x
			}
			return x - x*x*0.5
		}
		if x > SQRT2_HALF_M1 { // sqrt(2)/2-1 < x
			// (sqrt(2)/2-1) < x < (sqrt(2)-1)
			k = 0
			f = x
			iu = 1
		}
	}
	c: f64
	if k != 0 {
		u: f64
		if absx < TWO53 { // 1<<53
			u = 1.0 + x
			iu = transmute(u64)u
			k = int((iu >> 52) - 1023)
			// correction term
			if k > 0 {
				c = 1.0 - (u - x)
			} else {
				c = x - (u - 1.0)
			}
			c /= u
		} else {
			u = x
			iu = transmute(u64)u
			k = int((iu >> 52) - 1023)
			c = 0
		}
		iu &= 0x000fffffffffffff
		if iu < 0x0006a09e667f3bcd { // mantissa of sqrt(2)
			u = transmute(f64)(iu | 0x3ff0000000000000) // normalize u
		} else {
			k += 1
			u = transmute(f64)(iu | 0x3fe0000000000000) // normalize u/2
			iu = (0x0010000000000000 - iu) >> 2
		}
		f = u - 1.0 // sqrt(2)/2 < u < sqrt(2)
	}
	hfsq := 0.5 * f * f
	s, R, z: f64
	if iu == 0 { // |f| < 2**-20
		if f == 0 {
			if k == 0 {
				return 0
			}
			c += f64(k) * LN2LO
			return f64(k)*LN2HI + c
		}
		R = hfsq * (1.0 - 0.66666666666666666*f) // avoid division
		if k == 0 {
			return f - R
		}
		return f64(k)*LN2HI - ((R - (f64(k)*LN2LO + c)) - f)
	}
	s = f / (2.0 + f)
	z = s * s
	R = z * (LP1 + z*(LP2+z*(LP3+z*(LP4+z*(LP5+z*(LP6+z*LP7))))))
	if k == 0 {
		return f - (hfsq - s*(hfsq+R))
	}
	return f64(k)*LN2HI - ((hfsq - (s*(hfsq+R) + (f64(k)*LN2LO + c))) - f)
}
