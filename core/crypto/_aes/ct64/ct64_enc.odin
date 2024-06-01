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

add_round_key :: proc "contextless" (q: ^[8]u64, sk: []u64) #no_bounds_check {
	if len(sk) < 8 {
		intrinsics.trap()
	}

	q[0] ~= sk[0]
	q[1] ~= sk[1]
	q[2] ~= sk[2]
	q[3] ~= sk[3]
	q[4] ~= sk[4]
	q[5] ~= sk[5]
	q[6] ~= sk[6]
	q[7] ~= sk[7]
}

shift_rows :: proc "contextless" (q: ^[8]u64) {
	for x, i in q {
		q[i] =
			(x & 0x000000000000FFFF) |
			((x & 0x00000000FFF00000) >> 4) |
			((x & 0x00000000000F0000) << 12) |
			((x & 0x0000FF0000000000) >> 8) |
			((x & 0x000000FF00000000) << 8) |
			((x & 0xF000000000000000) >> 12) |
			((x & 0x0FFF000000000000) << 4)
	}
}

mix_columns :: proc "contextless" (q: ^[8]u64) {
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

	q[0] = q7 ~ r7 ~ r0 ~ rotr32(q0 ~ r0)
	q[1] = q0 ~ r0 ~ q7 ~ r7 ~ r1 ~ rotr32(q1 ~ r1)
	q[2] = q1 ~ r1 ~ r2 ~ rotr32(q2 ~ r2)
	q[3] = q2 ~ r2 ~ q7 ~ r7 ~ r3 ~ rotr32(q3 ~ r3)
	q[4] = q3 ~ r3 ~ q7 ~ r7 ~ r4 ~ rotr32(q4 ~ r4)
	q[5] = q4 ~ r4 ~ r5 ~ rotr32(q5 ~ r5)
	q[6] = q5 ~ r5 ~ r6 ~ rotr32(q6 ~ r6)
	q[7] = q6 ~ r6 ~ r7 ~ rotr32(q7 ~ r7)
}

@(private)
_encrypt :: proc "contextless" (q: ^[8]u64, skey: []u64, num_rounds: int) {
	add_round_key(q, skey)
	for u in 1 ..< num_rounds {
		sub_bytes(q)
		shift_rows(q)
		mix_columns(q)
		add_round_key(q, skey[u << 3:])
	}
	sub_bytes(q)
	shift_rows(q)
	add_round_key(q, skey[num_rounds << 3:])
}
