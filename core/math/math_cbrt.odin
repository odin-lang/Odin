package math

import "base:intrinsics"

@(require_results) cbrt_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(cbrt_f16(f16(x))) }
@(require_results) cbrt_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(cbrt_f16(f16(x))) }
@(require_results) cbrt_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(cbrt_f32(f32(x))) }
@(require_results) cbrt_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(cbrt_f32(f32(x))) }
@(require_results) cbrt_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(cbrt_f64(f64(x))) }
@(require_results) cbrt_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(cbrt_f64(f64(x))) }

// cbrt returns the cube root of x.
//
// Special cases are:
//
//	cbrt(±0) = ±0
//	cbrt(±Inf) = ±Inf
//	cbrt(NaN) = NaN
cbrt :: proc{
	cbrt_f16, cbrt_f16le, cbrt_f16be,
	cbrt_f32, cbrt_f32le, cbrt_f32be,
	cbrt_f64, cbrt_f64le, cbrt_f64be,
}



@(require_results)
cbrt_f16 :: proc "contextless" (x: f16) -> f16 { return #force_inline f16(cbrt_f64(f64(x))) }
@(require_results)
cbrt_f32 :: proc "contextless" (x: f32) -> f32 { return #force_inline f32(cbrt_f64(f64(x))) }

// cbrt returns the cube root of x.
//
// Special cases are:
//
//	cbrt(±0) = ±0
//	cbrt(±Inf) = ±Inf
//	cbrt(NaN) = NaN
@(require_results)
cbrt_f64 :: proc "contextless" (x: f64) -> f64 {
	// http://www.netlib.org/fdlibm/s_cbrt.c and came with this notice.
	//
	// ====================================================
	// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
	//
	// Developed at SunSoft, a Sun Microsystems, Inc. business.
	// Permission to use, copy, modify, and distribute this
	// software is freely granted, provided that this notice
	// is preserved.
	// ====================================================

	B1              :: 715094163          // (682-0.03306235651)*2**20
	B2              :: 696219795          // (664-0.03306235651)*2**20
	SMALLEST_NORMAL :: 0h0010000000000000 // 2.22507385850720138309e-308 == 2**-1022

	C               :: 0h3FE15F15F15F15F1 // 5.42857142857142815906e-01  == 19/35
	D               :: 0hBFE691DE2532C834 // -7.05306122448979611050e-01 == -864/1225
	E               :: 0h3FF6A0EA0EA0EA0F // 1.41428571428571436819e+00  == 99/70
	F               :: 0h3FF9B6DB6DB6DB6E // 1.60714285714285720630e+00  == 45/28
	G               :: 0h3FD6DB6DB6DB6DB7 // 3.57142857142857150787e-01  == 5/14

	x := x

	switch {
	case x == 0 || is_nan(x) || is_inf(x, 0):
		return x
	}

	sign := false
	if x < 0 {
		x = -x
		sign = true
	}

	// Approximate cbrt (5-bits)
	t := transmute(f64)((transmute(u64)x)/3 + B1<<32)
	if x < SMALLEST_NORMAL {
		t = f64(1 << 54)
		t *= x
		t = transmute(f64)((transmute(u64)x)/3 + B2<<32)
	}

	// Approximate cbrt (23-bits)
	r := t * t / x
	s := C + r*t
	t *= G + F/(s+E + D/s)

	// Truncate to 22 bits, make larger than cbrt(x)
	t = transmute(f64)((transmute(u64)t)&(0xffffffffc<<28) + 1<<30)

	// Single step of Newton-Raphson iteration to 53 bits with error less than 0.667ulps
	s = t * t // t*t is exact
	r = x / s
	w := t + t
	r = (r - t) / (w + r) // r-s is exact
	t = t + t*r

	// Restore sign
	if sign {
		t = -t
	}
	return t
}
