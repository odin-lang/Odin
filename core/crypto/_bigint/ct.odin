package _bigint

// Copyright (c) 2016 Thomas Pornin <pornin@bolet.org>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
//   1. Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS “AS IS” AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/* ====================================================================
 *
 * Constant-time primitives. These functions manipulate 32-bit values in
 * order to provide constant-time comparisons and multiplexers.
 *
 * Boolean values (the "ctl" bits) MUST have value 0 or 1.
 *
 * Implementation notes:
 * =====================
 *
 * The uintN_t types are unsigned and with width exactly N bits; the C
 * standard guarantees that computations are performed modulo 2^N, and
 * there can be no overflow. Negation (unary '-') works on unsigned types
 * as well.
 *
 * The intN_t types are guaranteed to have width exactly N bits, with no
 * padding bit, and using two's complement representation. Casting
 * intN_t to uintN_t really is conversion modulo 2^N. Beware that intN_t
 * types, being signed, trigger implementation-defined behaviour on
 * overflow (including raising some signal): with GCC, while modular
 * arithmetics are usually applied, the optimizer may assume that
 * overflows don't occur (unless the -fwrapv command-line option is
 * added); Clang has the additional -ftrapv option to explicitly trap on
 * integer overflow or underflow.
 *
 * Note/Odin:
 * Most of the relevant routines have been consolidated into the
 * `crypto/_subtle` package.
 */

// XXX/yawning: Unused?

/*

import subtle "core:crypto/_subtle"

I31_LO_MASK :: 0xffff
I31_HI_MASK :: 0x8000_0000

/*
 * Returns 1 if x == 0, 0 otherwise. Take care that the operand is signed.
 */
@(private, optimization_mode="none")
i32_eq0 :: proc "contextless" (x: i32) -> (res: u32) {
	q := u32(x)
	return ~(q | -q) >> 31
}

/*
 * Returns 1 if x > 0, 0 otherwise. Take care that the operand is signed.
 */
@(private, optimization_mode="none")
i32_gt0 :: proc "contextless" (x: i32) -> (res: u32) {
	/*
	 * High bit of -x is 0 if x == 0, but 1 if x > 0.
	 */
	q := u32(x)
	return (~q & -q) >> 31
}

/*
 * Returns 1 if x >= 0, 0 otherwise. Take care that the operand is signed.
 */
@(private, optimization_mode="none")
i32_ge0 :: proc "contextless" (x: i32) -> (res: u32) {
	return ~u32(x) >> 31
}

/*
 * Returns 1 if x < 0, 0 otherwise. Take care that the operand is signed.
 */
@(private, optimization_mode="none")
i32_lt0 :: proc "contextless" (x: i32) -> (res: u32) {
	return u32(x) >> 31
}

/*
 * Returns 1 if x <= 0, 0 otherwise. Take care that the operand is signed.
 */
@(private, optimization_mode="none")
i32_le0 :: proc "contextless" (x: i32) -> (res: u32) {
	/*
	 * ~-x has its high bit set if and only if -x is nonnegative (as
	 * a signed int), i.e. x is in the -(2^31-1) to 0 range. We must
	 * do an OR with x itself to account for x = -2^31.
	 */
	q := u32(x)
	return (q | ~-q) >> 31
}

/*
 * Compute the minimum of x and y.
 */
@(private, optimization_mode="none")
u32_min :: proc "contextless" (x, y: u32) -> (res: u32) {
	return subtle.csel(x, y, int(subtle.gt(x, y)))
}

// Compute the maximum of x and y.
@(private, optimization_mode="none")
u32_max :: proc "contextless" (x, y: u32) -> (res: u32) {
	return subtle.csel(y, x, int(subtle.gt(x, y)))
}

/*
 * Multiply two 32-bit integers, with a 64-bit result. This default
 * implementation assumes that the basic multiplication operator
 * yields constant-time code.
 */
@(private="file")
mul :: #force_inline proc "contextless" (x, y: u32) -> (res: u64) {
	return u64(x) * u64(y)
}

/*
Conditional copy: `src` is copied into `dst` if and only if `ctl` is 1.
`dst` and `src` may overlap completely (but not partially).
*/
ccopy :: proc "contextless" (ctl: u32, dst: [^]byte, src: [^]byte, len: uint) {
	l := len
	d := dst
	s := src
	for l > 0 {
		x := u32(s[0])
		y := u32(d[0])
		d[0] = u8(mux(ctl, x, y))
		s = s[1:]
		d = d[1:]
		l -= 1
	}
}

/*
Conditional copy: `src` is copied into `dst` if and only if `ctl` is 1.
`dst` and `src` may overlap completely (but not partially).
*/
ccopy_u32 :: #force_inline proc "contextless" (ctl: u32, dst: []u32, src: []u32) {
	for &d, i in dst {
		d = mux(ctl, src[i], d)
	}
}

*/

