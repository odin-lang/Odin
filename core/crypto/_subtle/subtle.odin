/*
Various useful bit operations in constant time.
*/
package _subtle

import "base:intrinsics"

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

// Constant-time primitives. These functions manipulate integer values in
// order to provide constant-time comparisons and multiplexers.
//
// Boolean values (the "ctl" bits) MUST have value 0 or 1.
//
// Implementation notes:
// =====================
//
// The uintN_t types are unsigned and with width exactly N bits; the C
// standard guarantees that computations are performed modulo 2^N, and
// there can be no overflow. Negation (unary '-') works on unsigned types
// as well.
//
// The intN_t types are guaranteed to have width exactly N bits, with no
// padding bit, and using two's complement representation. Casting
// intN_t to uintN_t really is conversion modulo 2^N. Beware that intN_t
// types, being signed, trigger implementation-defined behaviour on
// overflow (including raising some signal): with GCC, while modular
// arithmetics are usually applied, the optimizer may assume that
// overflows don't occur (unless the -fwrapv command-line option is
// added); Clang has the additional -ftrapv option to explicitly trap on
// integer overflow or underflow.

// This code only works on a two's complement system.
#assert((-1 & 3) == 3)

// not negates a boolean which MUST be `0` or `1`
@(optimization_mode="none", require_results)
not :: proc "contextless" (ctrl: $T) -> T where intrinsics.type_is_unsigned(T) {
	return ctrl ~ 1
}

@(optimization_mode="none", require_results)
byte_eq :: proc "contextless" (a, b: byte) -> byte {
	v := a ~ b

	// v == 0 if and only if (⟺) a == b.  The subtraction will underflow, setting the
	// sign bit, which will get returned.
	return byte((u32(v)-1) >> 31)
}

@(optimization_mode="none", require_results)
u32_eq :: proc "contextless" (a, b: u32) -> u32 {
	q := a ~ b
	return ((q | -q) >> 31) ~ 1
}

@(optimization_mode="none", require_results)
u64_eq :: proc "contextless" (a, b: u64) -> u64 {
	q := a ~ b
	return ((q | -q) >> 63) ~ 1
}

// eq returns 1 if and only if (⟺) a == b, 0 otherwise.
eq :: proc {
	byte_eq,
	u32_eq,
	u64_eq,
}

@(require_results)
byte_neq :: proc "contextless" (a, b: byte) -> byte {
	return #force_inline byte_eq(a, b) ~ 1
}

@(optimization_mode="none", require_results)
u32_neq :: proc "contextless" (a, b: u32) -> u32 {
	q := a ~ b
	return (q | -q) >> 31
}

@(optimization_mode="none", require_results)
u64_neq :: proc "contextless" (a, b: u64) -> u64 {
	q := a ~ b
	return (q | -q) >> 63
}

// neq returns 1 if and only if (⟺) a != b, 0 otherwise.
neq :: proc {
	byte_neq,
	u32_neq,
	u64_neq,
}

@(optimization_mode="none", require_results)
u32_gt :: proc "contextless" (x, y: u32) -> u32 {
	/*
	 * If both x < 2^31 and y < 2^31, then y-x will have its high
	 * bit set if x > y, cleared otherwise.
	 *
	 * If either x >= 2^31 or y >= 2^31 (but not both), then the
	 * result is the high bit of x.
	 *
	 * If both x >= 2^31 and y >= 2^31, then we can virtually
	 * subtract 2^31 from both, and we are back to the first case.
	 * Since (y-2^31)-(x-2^31) = y-x, the subtraction is already
	 * fine.
	 */
	z := y - x
	return (z ~ ((x ~ y) & (x ~ z))) >> 31
}

@(optimization_mode="none", require_results)
u64_gt :: proc "contextless" (x, y: u64) -> u64 {
	z := y - x
	return (z ~ ((x ~ y) & (x ~ z))) >> 63
}

// gt returns 1 if x > y, 0 otherwise.
gt :: proc {
	u32_gt,
	u64_gt,
}

// gt returns 1 if x >= y, 0 otherwise.
@(require_results)
ge :: proc "contextless" (x, y: $T) -> T where T == u32 || T == u64 {
	return #force_inline(gt(y, x)) ~ 1
}

// lt returns 1 if x < y, 0 otherwise.
@(require_results)
lt :: proc "contextless" (x, y: $T) -> T where T == u32 || T == u64 {
	return #force_inline(gt(y, x))
}

// le returns 1 if x <= y, 0 otherwise.
@(require_results)
le :: proc "contextless" (x, y: $T) -> T where T == u32 || T == u64 {
	return #force_inline(gt(x, y)) ~ 1
}

@(require_results)
u32_cmp :: proc "contextless" (x, y: u32) -> i32 {
	return i32(#force_inline gt(x, y)) | -i32(#force_inline gt(y, x))
}

@(require_results)
u64_cmp :: proc "contextless" (x, y: u64) -> i64 {
	return i64(#force_inline gt(x, y)) | -i64(#force_inline gt(y, x))
}

// cmp returns -1, 0, or 1, depending on wheter x is lower than, equal
// to, or greater than y.
cmp :: proc {
	u32_cmp,
	u64_cmp,
}

// eq0 returns 1 if and only if (⟺) a == 0, 0 otherwise.
@(require_results)
eq0 :: proc "contextless" (a: $T) -> T where T == u32 || T == u64 {
	return #force_inline eq(a, 0)
}

// neq0 returns 1 if and only if (⟺) a != 0, 0 otherwise.
@(require_results)
neq0 :: proc "contextless" (a: $T) -> T where T == u32 || T == u64 {
	return #force_inline eq(a, 0) ~ 1
}

cmov_bytes :: proc "contextless" (dst, src: []byte, #any_int ctrl: int) {
	ensure_contextless(len(src) == len(dst), "crypto: cmov length mismatch")

	cmov_impl(dst, src, ctrl)
}

cmov_u32s :: proc "contextless" (dst, src: []u32, #any_int ctrl: int) {
	ensure_contextless(len(src) == len(dst), "crypto: cmov length mismatch")

	cmov_impl(dst, src, ctrl)
}

@(private="file", optimization_mode="none")
cmov_impl :: proc "contextless"(dst, src: []$T, ctrl: int) {
	s_len := len(src)

	c := -(T)(ctrl)
	for i in 0..<s_len {
		dst[i] ~= c & (dst[i] ~ src[i])
	}
}

// cmov copies `src` into `dst` if and only if (⟺) ctrl == 1. `dst` and
// `src` may overlap completely (but not partially).
cmov :: proc {
	cmov_bytes,
	cmov_u32s,
}

@(optimization_mode="none", require_results)
csel_i16 :: proc "contextless" (a, b: i16, #any_int ctrl: u16) -> i16 {
	c := -ctrl
	return a ~ i16(c & u16(a ~ b))
}

@(optimization_mode="none", require_results)
csel_u16 :: proc "contextless" (a, b: u16, #any_int ctrl: u16) -> u16 {
	c := -ctrl
	return a ~ (c & (a ~ b))
}

@(optimization_mode="none", require_results)
csel_u32 :: proc "contextless" (a, b: u32, #any_int ctrl: u32) -> u32 {
	c := -ctrl
	return a ~ (c & (a ~ b))
}

@(optimization_mode="none", require_results)
csel_u64 :: proc "contextless" (a, b: u64, #any_int ctrl: u64) -> u64 {
	c := -ctrl
	return a ~ (c & (a ~ b))
}

// csel returns `a` if ctl == `0`, `b` if ctl == `1`.
csel :: proc {
	csel_i16,
	csel_u16,
	csel_u32,
	csel_u64,
}
