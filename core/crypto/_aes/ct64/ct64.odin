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

package aes_ct64

// Bitsliced AES for 64-bit general purpose (integer) registers.  Each
// invocation will process up to 4 blocks at a time.  This implementation
// is derived from the BearSSL ct64 code, and distributed under a 1-clause
// BSD license with permission from the original author.
//
// WARNING: "hic sunt dracones"
//
// This package also deliberately exposes enough internals to be able to
// function as a replacement for `AESENC` and `AESDEC` from AES-NI, to
// allow the implementation of non-AES primitives that use the AES round
// function such as AEGIS and Deoxys-II.  This should ONLY be done when
// implementing something other than AES itself.

sub_bytes :: proc "contextless" (q: ^[8]u64) {
	// This S-box implementation is a straightforward translation of
	// the circuit described by Boyar and Peralta in "A new
	// combinational logic minimization technique with applications
	// to cryptology" (https://eprint.iacr.org/2009/191.pdf).
	//
	// Note that variables x* (input) and s* (output) are numbered
	// in "reverse" order (x0 is the high bit, x7 is the low bit).

	x0 := q[7]
	x1 := q[6]
	x2 := q[5]
	x3 := q[4]
	x4 := q[3]
	x5 := q[2]
	x6 := q[1]
	x7 := q[0]

	// Top linear transformation.
	y14 := x3 ~ x5
	y13 := x0 ~ x6
	y9 := x0 ~ x3
	y8 := x0 ~ x5
	t0 := x1 ~ x2
	y1 := t0 ~ x7
	y4 := y1 ~ x3
	y12 := y13 ~ y14
	y2 := y1 ~ x0
	y5 := y1 ~ x6
	y3 := y5 ~ y8
	t1 := x4 ~ y12
	y15 := t1 ~ x5
	y20 := t1 ~ x1
	y6 := y15 ~ x7
	y10 := y15 ~ t0
	y11 := y20 ~ y9
	y7 := x7 ~ y11
	y17 := y10 ~ y11
	y19 := y10 ~ y8
	y16 := t0 ~ y11
	y21 := y13 ~ y16
	y18 := x0 ~ y16

	// Non-linear section.
	t2 := y12 & y15
	t3 := y3 & y6
	t4 := t3 ~ t2
	t5 := y4 & x7
	t6 := t5 ~ t2
	t7 := y13 & y16
	t8 := y5 & y1
	t9 := t8 ~ t7
	t10 := y2 & y7
	t11 := t10 ~ t7
	t12 := y9 & y11
	t13 := y14 & y17
	t14 := t13 ~ t12
	t15 := y8 & y10
	t16 := t15 ~ t12
	t17 := t4 ~ t14
	t18 := t6 ~ t16
	t19 := t9 ~ t14
	t20 := t11 ~ t16
	t21 := t17 ~ y20
	t22 := t18 ~ y19
	t23 := t19 ~ y21
	t24 := t20 ~ y18

	t25 := t21 ~ t22
	t26 := t21 & t23
	t27 := t24 ~ t26
	t28 := t25 & t27
	t29 := t28 ~ t22
	t30 := t23 ~ t24
	t31 := t22 ~ t26
	t32 := t31 & t30
	t33 := t32 ~ t24
	t34 := t23 ~ t33
	t35 := t27 ~ t33
	t36 := t24 & t35
	t37 := t36 ~ t34
	t38 := t27 ~ t36
	t39 := t29 & t38
	t40 := t25 ~ t39

	t41 := t40 ~ t37
	t42 := t29 ~ t33
	t43 := t29 ~ t40
	t44 := t33 ~ t37
	t45 := t42 ~ t41
	z0 := t44 & y15
	z1 := t37 & y6
	z2 := t33 & x7
	z3 := t43 & y16
	z4 := t40 & y1
	z5 := t29 & y7
	z6 := t42 & y11
	z7 := t45 & y17
	z8 := t41 & y10
	z9 := t44 & y12
	z10 := t37 & y3
	z11 := t33 & y4
	z12 := t43 & y13
	z13 := t40 & y5
	z14 := t29 & y2
	z15 := t42 & y9
	z16 := t45 & y14
	z17 := t41 & y8

	// Bottom linear transformation.
	t46 := z15 ~ z16
	t47 := z10 ~ z11
	t48 := z5 ~ z13
	t49 := z9 ~ z10
	t50 := z2 ~ z12
	t51 := z2 ~ z5
	t52 := z7 ~ z8
	t53 := z0 ~ z3
	t54 := z6 ~ z7
	t55 := z16 ~ z17
	t56 := z12 ~ t48
	t57 := t50 ~ t53
	t58 := z4 ~ t46
	t59 := z3 ~ t54
	t60 := t46 ~ t57
	t61 := z14 ~ t57
	t62 := t52 ~ t58
	t63 := t49 ~ t58
	t64 := z4 ~ t59
	t65 := t61 ~ t62
	t66 := z1 ~ t63
	s0 := t59 ~ t63
	s6 := t56 ~ ~t62
	s7 := t48 ~ ~t60
	t67 := t64 ~ t65
	s3 := t53 ~ t66
	s4 := t51 ~ t66
	s5 := t47 ~ t65
	s1 := t64 ~ ~s3
	s2 := t55 ~ ~t67

	q[7] = s0
	q[6] = s1
	q[5] = s2
	q[4] = s3
	q[3] = s4
	q[2] = s5
	q[1] = s6
	q[0] = s7
}

orthogonalize :: proc "contextless" (q: ^[8]u64) {
	CL2 :: 0x5555555555555555
	CH2 :: 0xAAAAAAAAAAAAAAAA
	q[0], q[1] = (q[0] & CL2) | ((q[1] & CL2) << 1), ((q[0] & CH2) >> 1) | (q[1] & CH2)
	q[2], q[3] = (q[2] & CL2) | ((q[3] & CL2) << 1), ((q[2] & CH2) >> 1) | (q[3] & CH2)
	q[4], q[5] = (q[4] & CL2) | ((q[5] & CL2) << 1), ((q[4] & CH2) >> 1) | (q[5] & CH2)
	q[6], q[7] = (q[6] & CL2) | ((q[7] & CL2) << 1), ((q[6] & CH2) >> 1) | (q[7] & CH2)

	CL4 :: 0x3333333333333333
	CH4 :: 0xCCCCCCCCCCCCCCCC
	q[0], q[2] = (q[0] & CL4) | ((q[2] & CL4) << 2), ((q[0] & CH4) >> 2) | (q[2] & CH4)
	q[1], q[3] = (q[1] & CL4) | ((q[3] & CL4) << 2), ((q[1] & CH4) >> 2) | (q[3] & CH4)
	q[4], q[6] = (q[4] & CL4) | ((q[6] & CL4) << 2), ((q[4] & CH4) >> 2) | (q[6] & CH4)
	q[5], q[7] = (q[5] & CL4) | ((q[7] & CL4) << 2), ((q[5] & CH4) >> 2) | (q[7] & CH4)

	CL8 :: 0x0F0F0F0F0F0F0F0F
	CH8 :: 0xF0F0F0F0F0F0F0F0
	q[0], q[4] = (q[0] & CL8) | ((q[4] & CL8) << 4), ((q[0] & CH8) >> 4) | (q[4] & CH8)
	q[1], q[5] = (q[1] & CL8) | ((q[5] & CL8) << 4), ((q[1] & CH8) >> 4) | (q[5] & CH8)
	q[2], q[6] = (q[2] & CL8) | ((q[6] & CL8) << 4), ((q[2] & CH8) >> 4) | (q[6] & CH8)
	q[3], q[7] = (q[3] & CL8) | ((q[7] & CL8) << 4), ((q[3] & CH8) >> 4) | (q[7] & CH8)
}

@(require_results)
interleave_in :: proc "contextless" (w0, w1, w2, w3: u32) -> (q0, q1: u64) #no_bounds_check {
	x0, x1, x2, x3 := u64(w0), u64(w1), u64(w2), u64(w3)
	x0 |= (x0 << 16)
	x1 |= (x1 << 16)
	x2 |= (x2 << 16)
	x3 |= (x3 << 16)
	x0 &= 0x0000FFFF0000FFFF
	x1 &= 0x0000FFFF0000FFFF
	x2 &= 0x0000FFFF0000FFFF
	x3 &= 0x0000FFFF0000FFFF
	x0 |= (x0 << 8)
	x1 |= (x1 << 8)
	x2 |= (x2 << 8)
	x3 |= (x3 << 8)
	x0 &= 0x00FF00FF00FF00FF
	x1 &= 0x00FF00FF00FF00FF
	x2 &= 0x00FF00FF00FF00FF
	x3 &= 0x00FF00FF00FF00FF
	q0 = x0 | (x2 << 8)
	q1 = x1 | (x3 << 8)
	return
}

@(require_results)
interleave_out :: proc "contextless" (q0, q1: u64) -> (w0, w1, w2, w3: u32) {
	x0 := q0 & 0x00FF00FF00FF00FF
	x1 := q1 & 0x00FF00FF00FF00FF
	x2 := (q0 >> 8) & 0x00FF00FF00FF00FF
	x3 := (q1 >> 8) & 0x00FF00FF00FF00FF
	x0 |= (x0 >> 8)
	x1 |= (x1 >> 8)
	x2 |= (x2 >> 8)
	x3 |= (x3 >> 8)
	x0 &= 0x0000FFFF0000FFFF
	x1 &= 0x0000FFFF0000FFFF
	x2 &= 0x0000FFFF0000FFFF
	x3 &= 0x0000FFFF0000FFFF
	w0 = u32(x0) | u32(x0 >> 16)
	w1 = u32(x1) | u32(x1 >> 16)
	w2 = u32(x2) | u32(x2 >> 16)
	w3 = u32(x3) | u32(x3 >> 16)
	return
}

@(private)
rotr32 :: #force_inline proc "contextless" (x: u64) -> u64 {
	return (x << 32) | (x >> 32)
}
