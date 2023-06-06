package math

// The original C code and the long comment below are
// from FreeBSD's /usr/src/lib/msun/src/s_erf.c and
// came with this notice. 
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
// double erf(double x)
// double erfc(double x)
//                           x
//                    2      |\
//     erf(x)  =  ---------  | exp(-t*t)dt
//                 sqrt(pi) \|
//                           0
//
//     erfc(x) =  1-erf(x)
//  Note that
//              erf(-x) = -erf(x)
//              erfc(-x) = 2 - erfc(x)
//
// Method:
//      1. For |x| in [0, 0.84375]
//          erf(x)  = x + x*R(x**2)
//          erfc(x) = 1 - erf(x)           if x in [-.84375,0.25]
//                  = 0.5 + ((0.5-x)-x*R)  if x in [0.25,0.84375]
//         where R = P/Q where P is an odd poly of degree 8 and
//         Q is an odd poly of degree 10.
//                                               -57.90
//                      | R - (erf(x)-x)/x | <= 2
//
//
//         Remark. The formula is derived by noting
//          erf(x) = (2/sqrt(pi))*(x - x**3/3 + x**5/10 - x**7/42 + ....)
//         and that
//          2/sqrt(pi) = 1.128379167095512573896158903121545171688
//         is close to one. The interval is chosen because the fix
//         point of erf(x) is near 0.6174 (i.e., erf(x)=x when x is
//         near 0.6174), and by some experiment, 0.84375 is chosen to
//         guarantee the error is less than one ulp for erf.
//
//      2. For |x| in [0.84375,1.25], let s = |x| - 1, and
//         c = 0.84506291151 rounded to single (24 bits)
//              erf(x)  = sign(x) * (c  + P1(s)/Q1(s))
//              erfc(x) = (1-c)  - P1(s)/Q1(s) if x > 0
//                        1+(c+P1(s)/Q1(s))    if x < 0
//              |P1/Q1 - (erf(|x|)-c)| <= 2**-59.06
//         Remark: here we use the taylor series expansion at x=1.
//              erf(1+s) = erf(1) + s*Poly(s)
//                       = 0.845.. + P1(s)/Q1(s)
//         That is, we use rational approximation to approximate
//                      erf(1+s) - (c = (single)0.84506291151)
//         Note that |P1/Q1|< 0.078 for x in [0.84375,1.25]
//         where
//              P1(s) = degree 6 poly in s
//              Q1(s) = degree 6 poly in s
//
//      3. For x in [1.25,1/0.35(~2.857143)],
//              erfc(x) = (1/x)*exp(-x*x-0.5625+R1/S1)
//              erf(x)  = 1 - erfc(x)
//         where
//              R1(z) = degree 7 poly in z, (z=1/x**2)
//              S1(z) = degree 8 poly in z
//
//      4. For x in [1/0.35,28]
//              erfc(x) = (1/x)*exp(-x*x-0.5625+R2/S2) if x > 0
//                      = 2.0 - (1/x)*exp(-x*x-0.5625+R2/S2) if -6<x<0
//                      = 2.0 - tiny            (if x <= -6)
//              erf(x)  = sign(x)*(1.0 - erfc(x)) if x < 6, else
//              erf(x)  = sign(x)*(1.0 - tiny)
//         where
//              R2(z) = degree 6 poly in z, (z=1/x**2)
//              S2(z) = degree 7 poly in z
//
//      Note1:
//         To compute exp(-x*x-0.5625+R/S), let s be a single
//         precision number and s := x; then
//              -x*x = -s*s + (s-x)*(s+x)
//              exp(-x*x-0.5626+R/S) =
//                      exp(-s*s-0.5625)*exp((s-x)*(s+x)+R/S);
//      Note2:
//         Here 4 and 5 make use of the asymptotic series
//                        exp(-x*x)
//              erfc(x) ~ ---------- * ( 1 + Poly(1/x**2) )
//                        x*sqrt(pi)
//         We use rational approximation to approximate
//              g(s)=f(1/x**2) = log(erfc(x)*x) - x*x + 0.5625
//         Here is the error bound for R1/S1 and R2/S2
//              |R1/S1 - f(x)|  < 2**(-62.57)
//              |R2/S2 - f(x)|  < 2**(-61.52)
//
//      5. For inf > x >= 28
//              erf(x)  = sign(x) *(1 - tiny)  (raise inexact)
//              erfc(x) = tiny*tiny (raise underflow) if x > 0
//                      = 2 - tiny if x<0
//
//      7. Special case:
//              erf(0)  = 0, erf(inf)  = 1, erf(-inf) = -1,
//              erfc(0) = 1, erfc(inf) = 0, erfc(-inf) = 2,
//              erfc/erf(NaN) is NaN

erf :: proc{
	erf_f16,
	erf_f16le,
	erf_f16be,
	erf_f32,
	erf_f32le,
	erf_f32be,
	erf_f64,
}

@(require_results) erf_f16   :: proc "contextless" (x: f16)   -> f16   { return f16(erf_f64(f64(x))) }
@(require_results) erf_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(erf_f64(f64(x))) }
@(require_results) erf_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(erf_f64(f64(x))) }
@(require_results) erf_f32   :: proc "contextless" (x: f32)   -> f32   { return f32(erf_f64(f64(x))) }
@(require_results) erf_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(erf_f64(f64(x))) }
@(require_results) erf_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(erf_f64(f64(x))) }

@(require_results)
erf_f64 :: proc "contextless" (x: f64) -> f64 {
	erx :: 0h3FEB0AC160000000
	// Coefficients for approximation to  erf in [0, 0.84375]
	efx  :: 0h3FC06EBA8214DB69
	efx8 :: 0h3FF06EBA8214DB69
	pp0  :: 0h3FC06EBA8214DB68
	pp1  :: 0hBFD4CD7D691CB913
	pp2  :: 0hBF9D2A51DBD7194F
	pp3  :: 0hBF77A291236668E4
	pp4  :: 0hBEF8EAD6120016AC
	qq1  :: 0h3FD97779CDDADC09
	qq2  :: 0h3FB0A54C5536CEBA
	qq3  :: 0h3F74D022C4D36B0F
	qq4  :: 0h3F215DC9221C1A10
	qq5  :: 0hBED09C4342A26120
	// Coefficients for approximation to  erf  in [0.84375, 1.25]
	pa0 :: 0hBF6359B8BEF77538
	pa1 :: 0h3FDA8D00AD92B34D
	pa2 :: 0hBFD7D240FBB8C3F1
	pa3 :: 0h3FD45FCA805120E4
	pa4 :: 0hBFBC63983D3E28EC
	pa5 :: 0h3FA22A36599795EB
	pa6 :: 0hBF61BF380A96073F
	qa1 :: 0h3FBB3E6618EEE323
	qa2 :: 0h3FE14AF092EB6F33
	qa3 :: 0h3FB2635CD99FE9A7
	qa4 :: 0h3FC02660E763351F
	qa5 :: 0h3F8BEDC26B51DD1C
	qa6 :: 0h3F888B545735151D
	// Coefficients for approximation to  erfc in [1.25, 1/0.35]
	ra0 :: 0hBF843412600D6435
	ra1 :: 0hBFE63416E4BA7360
	ra2 :: 0hC0251E0441B0E726
	ra3 :: 0hC04F300AE4CBA38D
	ra4 :: 0hC0644CB184282266
	ra5 :: 0hC067135CEBCCABB2
	ra6 :: 0hC054526557E4D2F2
	ra7 :: 0hC023A0EFC69AC25C
	sa1 :: 0h4033A6B9BD707687
	sa2 :: 0h4061350C526AE721
	sa3 :: 0h407B290DD58A1A71
	sa4 :: 0h40842B1921EC2868
	sa5 :: 0h407AD02157700314
	sa6 :: 0h405B28A3EE48AE2C
	sa7 :: 0h401A47EF8E484A93
	sa8 :: 0hBFAEEFF2EE749A62
	// Coefficients for approximation to  erfc in [1/.35, 28]
	rb0 :: 0hBF84341239E86F4A
	rb1 :: 0hBFE993BA70C285DE
	rb2 :: 0hC031C209555F995A
	rb3 :: 0hC064145D43C5ED98
	rb4 :: 0hC083EC881375F228
	rb5 :: 0hC09004616A2E5992
	rb6 :: 0hC07E384E9BDC383F
	sb1 :: 0h403E568B261D5190
	sb2 :: 0h40745CAE221B9F0A
	sb3 :: 0h409802EB189D5118
	sb4 :: 0h40A8FFB7688C246A
	sb5 :: 0h40A3F219CEDF3BE6
	sb6 :: 0h407DA874E79FE763
	sb7 :: 0hC03670E242712D62
	
	
	VERY_TINY :: 0h0080000000000000
	SMALL     :: 1.0 / (1 << 28)        // 2**-28

	// special cases
	switch {
	case is_nan(x):
		return nan_f64()
	case is_inf(x, 1):
		return 1
	case is_inf(x, -1):
		return -1
	}
	x := x
	sign := false
	if x < 0 {
		x = -x
		sign = true
	}
	if x < 0.84375 { // |x| < 0.84375
		temp: f64
		if x < SMALL { // |x| < 2**-28
			if x < VERY_TINY {
				temp = 0.125 * (8.0*x + efx8*x) // avoid underflow
			} else {
				temp = x + efx*x
			}
		} else {
			z := x * x
			r := pp0 + z*(pp1+z*(pp2+z*(pp3+z*pp4)))
			s := 1 + z*(qq1+z*(qq2+z*(qq3+z*(qq4+z*qq5))))
			y := r / s
			temp = x + x*y
		}
		if sign {
			return -temp
		}
		return temp
	}
	if x < 1.25 { // 0.84375 <= |x| < 1.25
		s := x - 1
		P := pa0 + s*(pa1+s*(pa2+s*(pa3+s*(pa4+s*(pa5+s*pa6)))))
		Q := 1 + s*(qa1+s*(qa2+s*(qa3+s*(qa4+s*(qa5+s*qa6)))))
		if sign {
			return -erx - P/Q
		}
		return erx + P/Q
	}
	if x >= 6 { // inf > |x| >= 6
		if sign {
			return -1
		}
		return 1
	}
	s := 1 / (x * x)
	R, S: f64
	if x < 1/0.35 { // |x| < 1 / 0.35  ~ 2.857143
		R = ra0 + s*(ra1+s*(ra2+s*(ra3+s*(ra4+s*(ra5+s*(ra6+s*ra7))))))
		S = 1 + s*(sa1+s*(sa2+s*(sa3+s*(sa4+s*(sa5+s*(sa6+s*(sa7+s*sa8)))))))
	} else { // |x| >= 1 / 0.35  ~ 2.857143
		R = rb0 + s*(rb1+s*(rb2+s*(rb3+s*(rb4+s*(rb5+s*rb6)))))
		S = 1 + s*(sb1+s*(sb2+s*(sb3+s*(sb4+s*(sb5+s*(sb6+s*sb7))))))
	}
	z := transmute(f64)(0xffffffff00000000 & transmute(u64)x) // pseudo-single (20-bit) precision x
	r := exp(-z*z-0.5625) * exp((z-x)*(z+x)+R/S)
	if sign {
		return r/x - 1
	}
	return 1 - r/x
}


erfc :: proc{
	erfc_f16,
	erfc_f16le,
	erfc_f16be,
	erfc_f32,
	erfc_f32le,
	erfc_f32be,
	erfc_f64,
}

@(require_results) erfc_f16   :: proc "contextless" (x: f16)   -> f16   { return f16(erfc_f64(f64(x))) }
@(require_results) erfc_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(erfc_f64(f64(x))) }
@(require_results) erfc_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(erfc_f64(f64(x))) }
@(require_results) erfc_f32   :: proc "contextless" (x: f32)   -> f32   { return f32(erfc_f64(f64(x))) }
@(require_results) erfc_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(erfc_f64(f64(x))) }
@(require_results) erfc_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(erfc_f64(f64(x))) }

@(require_results)
erfc_f64 :: proc "contextless" (x: f64) -> f64 {
	erx :: 0h3FEB0AC160000000
	// Coefficients for approximation to  erf in [0, 0.84375]
	efx  :: 0h3FC06EBA8214DB69
	efx8 :: 0h3FF06EBA8214DB69
	pp0  :: 0h3FC06EBA8214DB68
	pp1  :: 0hBFD4CD7D691CB913
	pp2  :: 0hBF9D2A51DBD7194F
	pp3  :: 0hBF77A291236668E4
	pp4  :: 0hBEF8EAD6120016AC
	qq1  :: 0h3FD97779CDDADC09
	qq2  :: 0h3FB0A54C5536CEBA
	qq3  :: 0h3F74D022C4D36B0F
	qq4  :: 0h3F215DC9221C1A10
	qq5  :: 0hBED09C4342A26120
	// Coefficients for approximation to  erf  in [0.84375, 1.25]
	pa0 :: 0hBF6359B8BEF77538
	pa1 :: 0h3FDA8D00AD92B34D
	pa2 :: 0hBFD7D240FBB8C3F1
	pa3 :: 0h3FD45FCA805120E4
	pa4 :: 0hBFBC63983D3E28EC
	pa5 :: 0h3FA22A36599795EB
	pa6 :: 0hBF61BF380A96073F
	qa1 :: 0h3FBB3E6618EEE323
	qa2 :: 0h3FE14AF092EB6F33
	qa3 :: 0h3FB2635CD99FE9A7
	qa4 :: 0h3FC02660E763351F
	qa5 :: 0h3F8BEDC26B51DD1C
	qa6 :: 0h3F888B545735151D
	// Coefficients for approximation to  erfc in [1.25, 1/0.35]
	ra0 :: 0hBF843412600D6435
	ra1 :: 0hBFE63416E4BA7360
	ra2 :: 0hC0251E0441B0E726
	ra3 :: 0hC04F300AE4CBA38D
	ra4 :: 0hC0644CB184282266
	ra5 :: 0hC067135CEBCCABB2
	ra6 :: 0hC054526557E4D2F2
	ra7 :: 0hC023A0EFC69AC25C
	sa1 :: 0h4033A6B9BD707687
	sa2 :: 0h4061350C526AE721
	sa3 :: 0h407B290DD58A1A71
	sa4 :: 0h40842B1921EC2868
	sa5 :: 0h407AD02157700314
	sa6 :: 0h405B28A3EE48AE2C
	sa7 :: 0h401A47EF8E484A93
	sa8 :: 0hBFAEEFF2EE749A62
	// Coefficients for approximation to  erfc in [1/.35, 28]
	rb0 :: 0hBF84341239E86F4A
	rb1 :: 0hBFE993BA70C285DE
	rb2 :: 0hC031C209555F995A
	rb3 :: 0hC064145D43C5ED98
	rb4 :: 0hC083EC881375F228
	rb5 :: 0hC09004616A2E5992
	rb6 :: 0hC07E384E9BDC383F
	sb1 :: 0h403E568B261D5190
	sb2 :: 0h40745CAE221B9F0A
	sb3 :: 0h409802EB189D5118
	sb4 :: 0h40A8FFB7688C246A
	sb5 :: 0h40A3F219CEDF3BE6
	sb6 :: 0h407DA874E79FE763
	sb7 :: 0hC03670E242712D62
	
	TINY :: 1.0 / (1 << 56) // 2**-56
	// special cases
	switch {
	case is_nan(x):
		return nan_f64()
	case is_inf(x, 1):
		return 0
	case is_inf(x, -1):
		return 2
	}
	x := x
	sign := false
	if x < 0 {
		x = -x
		sign = true
	}
	if x < 0.84375 { // |x| < 0.84375
		temp: f64
		if x < TINY { // |x| < 2**-56
			temp = x
		} else {
			z := x * x
			r := pp0 + z*(pp1+z*(pp2+z*(pp3+z*pp4)))
			s := 1 + z*(qq1+z*(qq2+z*(qq3+z*(qq4+z*qq5))))
			y := r / s
			if x < 0.25 { // |x| < 1/4
				temp = x + x*y
			} else {
				temp = 0.5 + (x*y + (x - 0.5))
			}
		}
		if sign {
			return 1 + temp
		}
		return 1 - temp
	}
	if x < 1.25 { // 0.84375 <= |x| < 1.25
		s := x - 1
		P := pa0 + s*(pa1+s*(pa2+s*(pa3+s*(pa4+s*(pa5+s*pa6)))))
		Q := 1 + s*(qa1+s*(qa2+s*(qa3+s*(qa4+s*(qa5+s*qa6)))))
		if sign {
			return 1 + erx + P/Q
		}
		return 1 - erx - P/Q

	}
	if x < 28 { // |x| < 28
		s := 1 / (x * x)
		R, S: f64
		if x < 1/0.35 { // |x| < 1 / 0.35 ~ 2.857143
			R = ra0 + s*(ra1+s*(ra2+s*(ra3+s*(ra4+s*(ra5+s*(ra6+s*ra7))))))
			S = 1 + s*(sa1+s*(sa2+s*(sa3+s*(sa4+s*(sa5+s*(sa6+s*(sa7+s*sa8)))))))
		} else { // |x| >= 1 / 0.35 ~ 2.857143
			if sign && x > 6 {
				return 2 // x < -6
			}
			R = rb0 + s*(rb1+s*(rb2+s*(rb3+s*(rb4+s*(rb5+s*rb6)))))
			S = 1 + s*(sb1+s*(sb2+s*(sb3+s*(sb4+s*(sb5+s*(sb6+s*sb7))))))
		}
		z := transmute(f64)(0xffffffff00000000 & transmute(u64)x) // pseudo-single (20-bit) precision x
		r := exp(-z*z-0.5625) * exp((z-x)*(z+x)+R/S)
		if sign {
			return 2 - r/x
		}
		return r / x
	}
	if sign {
		return 2
	}
	return 0
}