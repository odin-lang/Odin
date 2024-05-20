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

import "base:intrinsics"

inv_sub_bytes :: proc "contextless" (q: ^[8]u64) {
	// AES S-box is:
	//   S(x) = A(I(x)) ^ 0x63
	// where I() is inversion in GF(256), and A() is a linear
	// transform (0 is formally defined to be its own inverse).
	// Since inversion is an involution, the inverse S-box can be
	// computed from the S-box as:
	//   iS(x) = B(S(B(x ^ 0x63)) ^ 0x63)
	// where B() is the inverse of A(). Indeed, for any y in GF(256):
	//   iS(S(y)) = B(A(I(B(A(I(y)) ^ 0x63 ^ 0x63))) ^ 0x63 ^ 0x63) = y
	//
	// Note: we reuse the implementation of the forward S-box,
	// instead of duplicating it here, so that total code size is
	// lower. By merging the B() transforms into the S-box circuit
	// we could make faster CBC decryption, but CBC decryption is
	// already quite faster than CBC encryption because we can
	// process four blocks in parallel.

	q0 := ~q[0]
	q1 := ~q[1]
	q2 := q[2]
	q3 := q[3]
	q4 := q[4]
	q5 := ~q[5]
	q6 := ~q[6]
	q7 := q[7]
	q[7] = q1 ~ q4 ~ q6
	q[6] = q0 ~ q3 ~ q5
	q[5] = q7 ~ q2 ~ q4
	q[4] = q6 ~ q1 ~ q3
	q[3] = q5 ~ q0 ~ q2
	q[2] = q4 ~ q7 ~ q1
	q[1] = q3 ~ q6 ~ q0
	q[0] = q2 ~ q5 ~ q7

	sub_bytes(q)

	q0 = ~q[0]
	q1 = ~q[1]
	q2 = q[2]
	q3 = q[3]
	q4 = q[4]
	q5 = ~q[5]
	q6 = ~q[6]
	q7 = q[7]
	q[7] = q1 ~ q4 ~ q6
	q[6] = q0 ~ q3 ~ q5
	q[5] = q7 ~ q2 ~ q4
	q[4] = q6 ~ q1 ~ q3
	q[3] = q5 ~ q0 ~ q2
	q[2] = q4 ~ q7 ~ q1
	q[1] = q3 ~ q6 ~ q0
	q[0] = q2 ~ q5 ~ q7
}

inv_shift_rows :: proc "contextless" (q: ^[8]u64) {
	for x, i in q {
		q[i] =
			(x & 0x000000000000FFFF) |
			((x & 0x000000000FFF0000) << 4) |
			((x & 0x00000000F0000000) >> 12) |
			((x & 0x000000FF00000000) << 8) |
			((x & 0x0000FF0000000000) >> 8) |
			((x & 0x000F000000000000) << 12) |
			((x & 0xFFF0000000000000) >> 4)
	}
}

inv_mix_columns :: proc "contextless" (q: ^[8]u64) {
	q0 := q[0]
	q1 := q[1]
	q2 := q[2]
	q3 := q[3]
	q4 := q[4]
	q5 := q[5]
	q6 := q[6]
	q7 := q[7]
	r0 := (q0 >> 16) | (q0 << 48)
	r1 := (q1 >> 16) | (q1 << 48)
	r2 := (q2 >> 16) | (q2 << 48)
	r3 := (q3 >> 16) | (q3 << 48)
	r4 := (q4 >> 16) | (q4 << 48)
	r5 := (q5 >> 16) | (q5 << 48)
	r6 := (q6 >> 16) | (q6 << 48)
	r7 := (q7 >> 16) | (q7 << 48)

	q[0] = q5 ~ q6 ~ q7 ~ r0 ~ r5 ~ r7 ~ rotr32(q0 ~ q5 ~ q6 ~ r0 ~ r5)
	q[1] = q0 ~ q5 ~ r0 ~ r1 ~ r5 ~ r6 ~ r7 ~ rotr32(q1 ~ q5 ~ q7 ~ r1 ~ r5 ~ r6)
	q[2] = q0 ~ q1 ~ q6 ~ r1 ~ r2 ~ r6 ~ r7 ~ rotr32(q0 ~ q2 ~ q6 ~ r2 ~ r6 ~ r7)
	q[3] = q0 ~ q1 ~ q2 ~ q5 ~ q6 ~ r0 ~ r2 ~ r3 ~ r5 ~ rotr32(q0 ~ q1 ~ q3 ~ q5 ~ q6 ~ q7 ~ r0 ~ r3 ~ r5 ~ r7)
	q[4] = q1 ~ q2 ~ q3 ~ q5 ~ r1 ~ r3 ~ r4 ~ r5 ~ r6 ~ r7 ~ rotr32(q1 ~ q2 ~ q4 ~ q5 ~ q7 ~ r1 ~ r4 ~ r5 ~ r6)
	q[5] = q2 ~ q3 ~ q4 ~ q6 ~ r2 ~ r4 ~ r5 ~ r6 ~ r7 ~ rotr32(q2 ~ q3 ~ q5 ~ q6 ~ r2 ~ r5 ~ r6 ~ r7)
	q[6] = q3 ~ q4 ~ q5 ~ q7 ~ r3 ~ r5 ~ r6 ~ r7 ~ rotr32(q3 ~ q4 ~ q6 ~ q7 ~ r3 ~ r6 ~ r7)
	q[7] = q4 ~ q5 ~ q6 ~ r4 ~ r6 ~ r7 ~ rotr32(q4 ~ q5 ~ q7 ~ r4 ~ r7)
}

@(private)
_decrypt :: proc "contextless" (q: ^[8]u64, skey: []u64, num_rounds: int) {
	add_round_key(q, skey[num_rounds << 3:])
	for u := num_rounds - 1; u > 0; u -= 1 {
		inv_shift_rows(q)
		inv_sub_bytes(q)
		add_round_key(q, skey[u << 3:])
		inv_mix_columns(q)
	}
	inv_shift_rows(q)
	inv_sub_bytes(q)
	add_round_key(q, skey)
}
