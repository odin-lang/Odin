package math

// The original C code and the long comment below are
// from FreeBSD's /usr/src/lib/msun/src/e_lgamma_r.c and
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
// __ieee754_lgamma_r(x, signgamp)
// Reentrant version of the logarithm of the Gamma function
// with user provided pointer for the sign of Gamma(x).
//
// Method:
//   1. Argument Reduction for 0 < x <= 8
//      Since gamma(1+s)=s*gamma(s), for x in [0,8], we may
//      reduce x to a number in [1.5,2.5] by
//              lgamma(1+s) = log(s) + lgamma(s)
//      for example,
//              lgamma(7.3) = log(6.3) + lgamma(6.3)
//                          = log(6.3*5.3) + lgamma(5.3)
//                          = log(6.3*5.3*4.3*3.3*2.3) + lgamma(2.3)
//   2. Polynomial approximation of lgamma around its
//      minimum (ymin=1.461632144968362245) to maintain monotonicity.
//      On [ymin-0.23, ymin+0.27] (i.e., [1.23164,1.73163]), use
//              Let z = x-ymin;
//              lgamma(x) = -1.214862905358496078218 + z**2*poly(z)
//              poly(z) is a 14 degree polynomial.
//   2. Rational approximation in the primary interval [2,3]
//      We use the following approximation:
//              s = x-2.0;
//              lgamma(x) = 0.5*s + s*P(s)/Q(s)
//      with accuracy
//              |P/Q - (lgamma(x)-0.5s)| < 2**-61.71
//      Our algorithms are based on the following observation
//
//                             zeta(2)-1    2    zeta(3)-1    3
// lgamma(2+s) = s*(1-Euler) + --------- * s  -  --------- * s  + ...
//                                 2                 3
//
//      where Euler = 0.5772156649... is the Euler constant, which
//      is very close to 0.5.
//
//   3. For x>=8, we have
//      lgamma(x)~(x-0.5)log(x)-x+0.5*log(2pi)+1/(12x)-1/(360x**3)+....
//      (better formula:
//         lgamma(x)~(x-0.5)*(log(x)-1)-.5*(log(2pi)-1) + ...)
//      Let z = 1/x, then we approximation
//              f(z) = lgamma(x) - (x-0.5)(log(x)-1)
//      by
//                                  3       5             11
//              w = w0 + w1*z + w2*z  + w3*z  + ... + w6*z
//      where
//              |w - f(z)| < 2**-58.74
//
//   4. For negative x, since (G is gamma function)
//              -x*G(-x)*G(x) = pi/sin(pi*x),
//      we have
//              G(x) = pi/(sin(pi*x)*(-x)*G(-x))
//      since G(-x) is positive, sign(G(x)) = sign(sin(pi*x)) for x<0
//      Hence, for x<0, signgam = sign(sin(pi*x)) and
//              lgamma(x) = log(|Gamma(x)|)
//                        = log(pi/(|x*sin(pi*x)|)) - lgamma(-x);
//      Note: one should avoid computing pi*(-x) directly in the
//            computation of sin(pi*(-x)).
//
//   5. Special Cases
//              lgamma(2+s) ~ s*(1-Euler) for tiny s
//              lgamma(1)=lgamma(2)=0
//              lgamma(x) ~ -log(x) for tiny x
//              lgamma(0) = lgamma(inf) = inf
//              lgamma(-integer) = +-inf
//
//


@(require_results)
lgamma_f64 :: proc "contextless" (x: f64) -> (lgamma: f64, sign: int) {
	@(require_results)
	sin_pi :: proc "contextless" (x: f64) -> f64 {
		if x < 0.25 {
			return -sin(PI * x)
		}
		x := x

		// argument reduction
		z := floor(x)
		n: int
		if z != x { // inexact
			x = mod(x, 2)
			n = int(x * 4)
		} else {
			if x >= TWO_53 { // x must be even
				x = 0
				n = 0
			} else {
				if x < TWO_52 {
					z = x + TWO_52 // exact
				}
				n = int(1 & transmute(u64)z)
				x = f64(n)
				n <<= 2
			}
		}
		switch n {
		case 0:
			x = sin(PI * x)
		case 1, 2:
			x = cos(PI * (0.5 - x))
		case 3, 4:
			x = sin(PI * (1 - x))
		case 5, 6:
			x = -cos(PI * (x - 1.5))
		case:
			x = sin(PI * (x - 2))
		}
		return -x
	}
	
	@(static, rodata) lgamA := [?]f64{
		0h3FB3C467E37DB0C8,
		0h3FD4A34CC4A60FAD,
		0h3FB13E001A5562A7,
		0h3F951322AC92547B,
		0h3F7E404FB68FEFE8,
		0h3F67ADD8CCB7926B,
		0h3F538A94116F3F5D,
		0h3F40B6C689B99C00,
		0h3F2CF2ECED10E54D,
		0h3F1C5088987DFB07,
		0h3EFA7074428CFA52,
		0h3F07858E90A45837,
	}
	@(static, rodata) lgamR := [?]f64{
		1.0,
		0h3FF645A762C4AB74,
		0h3FE71A1893D3DCDC,
		0h3FC601EDCCFBDF27,
		0h3F9317EA742ED475,
		0h3F497DDACA41A95B,
		0h3EDEBAF7A5B38140,
	}
	@(static, rodata) lgamS := [?]f64{
		0hBFB3C467E37DB0C8,
		0h3FCB848B36E20878,
		0h3FD4D98F4F139F59,
		0h3FC2BB9CBEE5F2F7,
		0h3F9B481C7E939961,
		0h3F5E26B67368F239,
		0h3F00BFECDD17E945,
	}
	@(static, rodata) lgamT := [?]f64{
		0h3FDEF72BC8EE38A2,
		0hBFC2E4278DC6C509,
		0h3FB08B4294D5419B,
		0hBFA0C9A8DF35B713,
		0h3F9266E7970AF9EC,
		0hBF851F9FBA91EC6A,
		0h3F78FCE0E370E344,
		0hBF6E2EFFB3E914D7,
		0h3F6282D32E15C915,
		0hBF56FE8EBF2D1AF1,
		0h3F4CDF0CEF61A8E9,
		0hBF41A6109C73E0EC,
		0h3F34AF6D6C0EBBF7,
		0hBF347F24ECC38C38,
		0h3F35FD3EE8C2D3F4,
	}
	@(static, rodata) lgamU := [?]f64{
		0hBFB3C467E37DB0C8,
		0h3FE4401E8B005DFF,
		0h3FF7475CD119BD6F,
		0h3FEF497644EA8450,
		0h3FCD4EAEF6010924,
		0h3F8B678BBF2BAB09,
	}
	@(static, rodata) lgamV := [?]f64{
		1.0,
		0h4003A5D7C2BD619C,
		0h40010725A42B18F5,
		0h3FE89DFBE45050AF,
		0h3FBAAE55D6537C88,
		0h3F6A5ABB57D0CF61,
	}
	@(static, rodata) lgamW := [?]f64{
		0h3FDACFE390C97D69,
		0h3FB555555555553B,
		0hBF66C16C16B02E5C,
		0h3F4A019F98CF38B6,
		0hBF4380CB8C0FE741,
		0h3F4B67BA4CDAD5D1,
		0hBF5AB89D0B9E43E4,
	}

	
	Y_MIN  :: 0h3ff762d86356be3f // 1.461632144968362245
	TWO_52 :: 0h4330000000000000 // ~4.5036e+15
	TWO_53 :: 0h4340000000000000 // ~9.0072e+15
	TWO_58 :: 0h4390000000000000 // ~2.8823e+17
	TINY   :: 0h3b90000000000000 // ~8.47033e-22
	Tc     :: 0h3FF762D86356BE3F
	Tf     :: 0hBFBF19B9BCC38A42
	Tt     :: 0hBC50C7CAA48A971F
	
	// special cases
	sign = 1
	switch {
	case is_nan(x):
		lgamma = x
		return
	case is_inf(x):
		lgamma = x
		return
	case x == 0:
		lgamma = inf_f64(1)
		return
	}

	x := x
	neg := false
	if x < 0 {
		x = -x
		neg = true
	}

	if x < TINY { // if |x| < 2**-70, return -log(|x|)
		if neg {
			sign = -1
		}
		lgamma = -ln(x)
		return
	}
	nadj: f64
	if neg {
		if x >= TWO_52 { // |x| >= 2**52, must be -integer
			lgamma = inf_f64(1)
			return
		}
		t := sin_pi(x)
		if t == 0 {
			lgamma = inf_f64(1) // -integer
			return
		}
		nadj = ln(PI / abs(t*x))
		if t < 0 {
			sign = -1
		}
	}

	switch {
	case x == 1 || x == 2: // purge off 1 and 2
		lgamma = 0
		return
	case x < 2: // use lgamma(x) = lgamma(x+1) - log(x)
		y: f64
		i: int
		if x <= 0.9 {
			lgamma = -ln(x)
			switch {
			case x >= (Y_MIN - 1 + 0.27): // 0.7316 <= x <=  0.9
				y = 1 - x
				i = 0
			case x >= (Y_MIN - 1 - 0.27): // 0.2316 <= x < 0.7316
				y = x - (Tc - 1)
				i = 1
			case: // 0 < x < 0.2316
				y = x
				i = 2
			}
		} else {
			lgamma = 0
			switch {
			case x >= (Y_MIN + 0.27): // 1.7316 <= x < 2
				y = 2 - x
				i = 0
			case x >= (Y_MIN - 0.27): // 1.2316 <= x < 1.7316
				y = x - Tc
				i = 1
			case: // 0.9 < x < 1.2316
				y = x - 1
				i = 2
			}
		}
		switch i {
		case 0:
			z := y * y
			p1 := lgamA[0] + z*(lgamA[2]+z*(lgamA[4]+z*(lgamA[6]+z*(lgamA[8]+z*lgamA[10]))))
			p2 := z * (lgamA[1] + z*(+lgamA[3]+z*(lgamA[5]+z*(lgamA[7]+z*(lgamA[9]+z*lgamA[11])))))
			p := y*p1 + p2
			lgamma += (p - 0.5*y)
		case 1:
			z := y * y
			w := z * y
			p1 := lgamT[0] + w*(lgamT[3]+w*(lgamT[6]+w*(lgamT[9]+w*lgamT[12]))) // parallel comp
			p2 := lgamT[1] + w*(lgamT[4]+w*(lgamT[7]+w*(lgamT[10]+w*lgamT[13])))
			p3 := lgamT[2] + w*(lgamT[5]+w*(lgamT[8]+w*(lgamT[11]+w*lgamT[14])))
			p := z*p1 - (Tt - w*(p2+y*p3))
			lgamma += (Tf + p)
		case 2:
			p1 := y * (lgamU[0] + y*(lgamU[1]+y*(lgamU[2]+y*(lgamU[3]+y*(lgamU[4]+y*lgamU[5])))))
			p2 := 1 + y*(lgamV[1]+y*(lgamV[2]+y*(lgamV[3]+y*(lgamV[4]+y*lgamV[5]))))
			lgamma += (-0.5*y + p1/p2)
		}
	case x < 8: // 2 <= x < 8
		i := int(x)
		y := x - f64(i)
		p := y * (lgamS[0] + y*(lgamS[1]+y*(lgamS[2]+y*(lgamS[3]+y*(lgamS[4]+y*(lgamS[5]+y*lgamS[6]))))))
		q := 1 + y*(lgamR[1]+y*(lgamR[2]+y*(lgamR[3]+y*(lgamR[4]+y*(lgamR[5]+y*lgamR[6])))))
		lgamma = 0.5*y + p/q
		z := 1.0 // lgamma(1+s) = ln(s) + lgamma(s)
		switch i {
		case 7:
			z *= (y + 6)
			fallthrough
		case 6:
			z *= (y + 5)
			fallthrough
		case 5:
			z *= (y + 4)
			fallthrough
		case 4:
			z *= (y + 3)
			fallthrough
		case 3:
			z *= (y + 2)
			lgamma += ln(z)
		}
	case x < TWO_58: // 8 <= x < 2**58
		t := ln(x)
		z := 1 / x
		y := z * z
		w := lgamW[0] + z*(lgamW[1]+y*(lgamW[2]+y*(lgamW[3]+y*(lgamW[4]+y*(lgamW[5]+y*lgamW[6])))))
		lgamma = (x-0.5)*(t-1) + w
	case: // 2**58 <= x <= Inf
		lgamma = x * (ln(x) - 1)
	}
	if neg {
		lgamma = nadj - lgamma
	}
	return
}


@(require_results) lgamma_f16   :: proc "contextless" (x: f16)   -> (lgamma: f16, sign: int)   { r, s := lgamma_f64(f64(x)); return f16(r), s }
@(require_results) lgamma_f32   :: proc "contextless" (x: f32)   -> (lgamma: f32, sign: int)   { r, s := lgamma_f64(f64(x)); return f32(r), s }
@(require_results) lgamma_f16le :: proc "contextless" (x: f16le) -> (lgamma: f16le, sign: int) { r, s := lgamma_f64(f64(x)); return f16le(r), s }
@(require_results) lgamma_f16be :: proc "contextless" (x: f16be) -> (lgamma: f16be, sign: int) { r, s := lgamma_f64(f64(x)); return f16be(r), s }
@(require_results) lgamma_f32le :: proc "contextless" (x: f32le) -> (lgamma: f32le, sign: int) { r, s := lgamma_f64(f64(x)); return f32le(r), s }
@(require_results) lgamma_f32be :: proc "contextless" (x: f32be) -> (lgamma: f32be, sign: int) { r, s := lgamma_f64(f64(x)); return f32be(r), s }
@(require_results) lgamma_f64le :: proc "contextless" (x: f64le) -> (lgamma: f64le, sign: int) { r, s := lgamma_f64(f64(x)); return f64le(r), s }
@(require_results) lgamma_f64be :: proc "contextless" (x: f64be) -> (lgamma: f64be, sign: int) { r, s := lgamma_f64(f64(x)); return f64be(r), s }

lgamma :: proc{
	lgamma_f16, lgamma_f16le, lgamma_f16be,
	lgamma_f32, lgamma_f32le, lgamma_f32be,
	lgamma_f64, lgamma_f64le, lgamma_f64be,
}