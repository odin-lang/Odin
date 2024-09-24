#+build !js
package math

import "base:intrinsics"

@(default_calling_convention="none", private="file")
foreign _ {
	@(link_name="llvm.sin.f16", require_results)
	_sin_f16 :: proc(θ: f16) -> f16 ---
	@(link_name="llvm.sin.f32", require_results)
	_sin_f32 :: proc(θ: f32) -> f32 ---
	@(link_name="llvm.sin.f64", require_results)
	_sin_f64 :: proc(θ: f64) -> f64 ---

	@(link_name="llvm.cos.f16", require_results)
	_cos_f16 :: proc(θ: f16) -> f16 ---
	@(link_name="llvm.cos.f32", require_results)
	_cos_f32 :: proc(θ: f32) -> f32 ---
	@(link_name="llvm.cos.f64", require_results)
	_cos_f64 :: proc(θ: f64) -> f64 ---

	@(link_name="llvm.pow.f16", require_results)
	_pow_f16 :: proc(x, power: f16) -> f16 ---
	@(link_name="llvm.pow.f32", require_results)
	_pow_f32 :: proc(x, power: f32) -> f32 ---
	@(link_name="llvm.pow.f64", require_results)
	_pow_f64 :: proc(x, power: f64) -> f64 ---

	@(link_name="llvm.fmuladd.f16", require_results)
	_fmuladd_f16 :: proc(a, b, c: f16) -> f16 ---
	@(link_name="llvm.fmuladd.f32", require_results)
	_fmuladd_f32 :: proc(a, b, c: f32) -> f32 ---
	@(link_name="llvm.fmuladd.f64", require_results)
	_fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---

	@(link_name="llvm.exp.f16", require_results)
	_exp_f16 :: proc(x: f16) -> f16 ---
	@(link_name="llvm.exp.f32", require_results)
	_exp_f32 :: proc(x: f32) -> f32 ---
	@(link_name="llvm.exp.f64", require_results)
	_exp_f64 :: proc(x: f64) -> f64 ---
}

@(require_results)
sin_f16 :: proc "contextless" (θ: f16) -> f16 {
	return _sin_f16(θ)
}
@(require_results)
sin_f32 :: proc "contextless" (θ: f32) -> f32 {
	return _sin_f32(θ)
}
@(require_results)
sin_f64 :: proc "contextless" (θ: f64) -> f64 {
	return _sin_f64(θ)
}

@(require_results)
cos_f16 :: proc "contextless" (θ: f16) -> f16 {
	return _cos_f16(θ)
}
@(require_results)
cos_f32 :: proc "contextless" (θ: f32) -> f32 {
	return _cos_f32(θ)
}
@(require_results)
cos_f64 :: proc "contextless" (θ: f64) -> f64 {
	return _cos_f64(θ)
}

@(require_results)
pow_f16 :: proc "contextless" (x, power: f16) -> f16 {
	return _pow_f16(x, power)
}
@(require_results)
pow_f32 :: proc "contextless" (x, power: f32) -> f32 {
	return _pow_f32(x, power)
}
@(require_results)
pow_f64 :: proc "contextless" (x, power: f64) -> f64 {
	return _pow_f64(x, power)
}

@(require_results)
fmuladd_f16 :: proc "contextless" (a, b, c: f16) -> f16 {
	return _fmuladd_f16(a, b, c)
}
@(require_results)
fmuladd_f32 :: proc "contextless" (a, b, c: f32) -> f32 {
	return _fmuladd_f32(a, b, c)
}
@(require_results)
fmuladd_f64 :: proc "contextless" (a, b, c: f64) -> f64 {
	return _fmuladd_f64(a, b, c)
}

@(require_results)
exp_f16 :: proc "contextless" (x: f16) -> f16 {
	return _exp_f16(x)
}
@(require_results)
exp_f32 :: proc "contextless" (x: f32) -> f32 {
	return _exp_f32(x)
}
@(require_results)
exp_f64 :: proc "contextless" (x: f64) -> f64 {
	return _exp_f64(x)
}


@(require_results)
sqrt_f16 :: proc "contextless" (x: f16) -> f16 {
	return intrinsics.sqrt(x)
}
@(require_results)
sqrt_f32 :: proc "contextless" (x: f32) -> f32 {
	return intrinsics.sqrt(x)
}
@(require_results)
sqrt_f64 :: proc "contextless" (x: f64) -> f64 {
	return intrinsics.sqrt(x)
}



@(require_results)
ln_f64 :: proc "contextless" (x: f64) -> f64 {
	// The original C code, the long comment, and the constants
	// below are from FreeBSD's /usr/src/lib/msun/src/e_log.c
	// and came with this notice.
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
	// __ieee754_log(x)
	// Return the logarithm of x
	//
	// Method :
	//   1. Argument Reduction: find k and f such that
	//			x = 2**k * (1+f),
	//	   where  sqrt(2)/2 < 1+f < sqrt(2) .
	//
	//   2. Approximation of log(1+f).
	//	Let s = f/(2+f) ; based on log(1+f) = log(1+s) - log(1-s)
	//		 = 2s + 2/3 s**3 + 2/5 s**5 + .....,
	//	     	 = 2s + s*R
	//      We use a special Reme algorithm on [0,0.1716] to generate
	//	a polynomial of degree 14 to approximate R.  The maximum error
	//	of this polynomial approximation is bounded by 2**-58.45. In
	//	other words,
	//		        2      4      6      8      10      12      14
	//	    R(z) ~ L1*s +L2*s +L3*s +L4*s +L5*s  +L6*s  +L7*s
	//	(the values of L1 to L7 are listed in the program) and
	//	    |      2          14          |     -58.45
	//	    | L1*s +...+L7*s    -  R(z) | <= 2
	//	    |                             |
	//	Note that 2s = f - s*f = f - hfsq + s*hfsq, where hfsq = f*f/2.
	//	In order to guarantee error in log below 1ulp, we compute log by
	//		log(1+f) = f - s*(f - R)		(if f is not too large)
	//		log(1+f) = f - (hfsq - s*(hfsq+R)).	(better accuracy)
	//
	//	3. Finally,  log(x) = k*Ln2 + log(1+f).
	//			    = k*Ln2_hi+(f-(hfsq-(s*(hfsq+R)+k*Ln2_lo)))
	//	   Here Ln2 is split into two floating point number:
	//			Ln2_hi + Ln2_lo,
	//	   where n*Ln2_hi is always exact for |n| < 2000.
	//
	// Special cases:
	//	log(x) is NaN with signal if x < 0 (including -INF) ;
	//	log(+INF) is +INF; log(0) is -INF with signal;
	//	log(NaN) is that NaN with no signal.
	//
	// Accuracy:
	//	according to an error analysis, the error is always less than
	//	1 ulp (unit in the last place).
	//
	// Constants:
	// The hexadecimal values are the intended ones for the following
	// constants. The decimal values may be used, provided that the
	// compiler will convert from decimal to binary accurately enough
	// to produce the hexadecimal values shown.
	
	LN2_HI :: 0h3fe62e42_fee00000 // 6.93147180369123816490e-01
	LN2_LO :: 0h3dea39ef_35793c76 // 1.90821492927058770002e-10
	L1     :: 0h3fe55555_55555593 // 6.666666666666735130e-01
	L2     :: 0h3fd99999_9997fa04 // 3.999999999940941908e-01
	L3     :: 0h3fd24924_94229359 // 2.857142874366239149e-01
	L4     :: 0h3fcc71c5_1d8e78af // 2.222219843214978396e-01
	L5     :: 0h3fc74664_96cb03de // 1.818357216161805012e-01
	L6     :: 0h3fc39a09_d078c69f // 1.531383769920937332e-01
	L7     :: 0h3fc2f112_df3e5244 // 1.479819860511658591e-01
	
	switch {
	case is_nan(x) || is_inf(x, 1):
		return x
	case x < 0:
		return nan_f64()
	case x == 0:
		return inf_f64(-1)
	}

	// reduce
	f1, ki := frexp(x)
	if f1 < SQRT_TWO/2 {
		f1 *= 2
		ki -= 1
	}
	f := f1 - 1
	k := f64(ki)

	// compute
	s := f / (2 + f)
	s2 := s * s
	s4 := s2 * s2
	t1 := s2 * (L1 + s4*(L3+s4*(L5+s4*L7)))
	t2 := s4 * (L2 + s4*(L4+s4*L6))
	R := t1 + t2
	hfsq := 0.5 * f * f
	return k*LN2_HI - ((hfsq - (s*(hfsq+R) + k*LN2_LO)) - f)
}

@(require_results) ln_f16   :: proc "contextless" (x: f16)   -> f16   { return #force_inline f16(ln_f64(f64(x))) }
@(require_results) ln_f32   :: proc "contextless" (x: f32)   -> f32   { return #force_inline f32(ln_f64(f64(x))) }
@(require_results) ln_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(ln_f64(f64(x))) }
@(require_results) ln_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(ln_f64(f64(x))) }
@(require_results) ln_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(ln_f64(f64(x))) }
@(require_results) ln_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(ln_f64(f64(x))) }
@(require_results) ln_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(ln_f64(f64(x))) }
@(require_results) ln_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(ln_f64(f64(x))) }
ln :: proc{
	ln_f16, ln_f16le, ln_f16be,
	ln_f32, ln_f32le, ln_f32be,
	ln_f64, ln_f64le, ln_f64be,
}