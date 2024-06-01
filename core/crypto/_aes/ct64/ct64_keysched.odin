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
import "core:crypto/_aes"
import "core:encoding/endian"
import "core:mem"

@(private, require_results)
sub_word :: proc "contextless" (x: u32) -> u32 {
	q := [8]u64{u64(x), 0, 0, 0, 0, 0, 0, 0}

	orthogonalize(&q)
	sub_bytes(&q)
	orthogonalize(&q)
	ret := u32(q[0])

	mem.zero_explicit(&q[0], size_of(u64))

	return ret
}

@(private, require_results)
keysched :: proc(comp_skey: []u64, key: []byte) -> int {
	num_rounds, key_len := 0, len(key)
	switch key_len {
	case _aes.KEY_SIZE_128:
		num_rounds = _aes.ROUNDS_128
	case _aes.KEY_SIZE_192:
		num_rounds = _aes.ROUNDS_192
	case _aes.KEY_SIZE_256:
		num_rounds = _aes.ROUNDS_256
	case:
		panic("crypto/aes: invalid AES key size")
	}

	skey: [60]u32 = ---
	nk, nkf := key_len >> 2, (num_rounds + 1) << 2
	for i in 0 ..< nk {
		skey[i] = endian.unchecked_get_u32le(key[i << 2:])
	}
	tmp := skey[(key_len >> 2) - 1]
	for i, j, k := nk, 0, 0; i < nkf; i += 1 {
		if j == 0 {
			tmp = (tmp << 24) | (tmp >> 8)
			tmp = sub_word(tmp) ~ u32(_aes.RCON[k])
		} else if nk > 6 && j == 4 {
			tmp = sub_word(tmp)
		}
		tmp ~= skey[i - nk]
		skey[i] = tmp
		if j += 1; j == nk {
			j = 0
			k += 1
		}
	}

	q: [8]u64 = ---
	for i, j := 0, 0; i < nkf; i, j = i + 4, j + 2 {
		q[0], q[4] = interleave_in(skey[i:])
		q[1] = q[0]
		q[2] = q[0]
		q[3] = q[0]
		q[5] = q[4]
		q[6] = q[4]
		q[7] = q[4]
		orthogonalize(&q)
		comp_skey[j + 0] =
			(q[0] & 0x1111111111111111) |
			(q[1] & 0x2222222222222222) |
			(q[2] & 0x4444444444444444) |
			(q[3] & 0x8888888888888888)
		comp_skey[j + 1] =
			(q[4] & 0x1111111111111111) |
			(q[5] & 0x2222222222222222) |
			(q[6] & 0x4444444444444444) |
			(q[7] & 0x8888888888888888)
	}

	mem.zero_explicit(&skey, size_of(skey))
	mem.zero_explicit(&q, size_of(q))

	return num_rounds
}

@(private)
skey_expand :: proc "contextless" (skey, comp_skey: []u64, num_rounds: int) {
	n := (num_rounds + 1) << 1
	for u, v := 0, 0; u < n; u, v = u + 1, v + 4 {
		x0 := comp_skey[u]
		x1, x2, x3 := x0, x0, x0
		x0 &= 0x1111111111111111
		x1 &= 0x2222222222222222
		x2 &= 0x4444444444444444
		x3 &= 0x8888888888888888
		x1 >>= 1
		x2 >>= 2
		x3 >>= 3
		skey[v + 0] = (x0 << 4) - x0
		skey[v + 1] = (x1 << 4) - x1
		skey[v + 2] = (x2 << 4) - x2
		skey[v + 3] = (x3 << 4) - x3
	}
}

orthogonalize_roundkey :: proc "contextless" (qq: []u64, key: []byte) {
	if len(qq) < 8 || len(key) != 16 {
		intrinsics.trap()
	}

	skey: [4]u32 = ---
	skey[0] = endian.unchecked_get_u32le(key[0:])
	skey[1] = endian.unchecked_get_u32le(key[4:])
	skey[2] = endian.unchecked_get_u32le(key[8:])
	skey[3] = endian.unchecked_get_u32le(key[12:])

	q: [8]u64 = ---
	q[0], q[4] = interleave_in(skey[:])
	q[1] = q[0]
	q[2] = q[0]
	q[3] = q[0]
	q[5] = q[4]
	q[6] = q[4]
	q[7] = q[4]
	orthogonalize(&q)

	comp_skey: [2]u64 = ---
	comp_skey[0] =
		(q[0] & 0x1111111111111111) |
		(q[1] & 0x2222222222222222) |
		(q[2] & 0x4444444444444444) |
		(q[3] & 0x8888888888888888)
	comp_skey[1] =
		(q[4] & 0x1111111111111111) |
		(q[5] & 0x2222222222222222) |
		(q[6] & 0x4444444444444444) |
		(q[7] & 0x8888888888888888)

	for x, u in comp_skey {
		x0 := x
		x1, x2, x3 := x0, x0, x0
		x0 &= 0x1111111111111111
		x1 &= 0x2222222222222222
		x2 &= 0x4444444444444444
		x3 &= 0x8888888888888888
		x1 >>= 1
		x2 >>= 2
		x3 >>= 3
		qq[u * 4 + 0] = (x0 << 4) - x0
		qq[u * 4 + 1] = (x1 << 4) - x1
		qq[u * 4 + 2] = (x2 << 4) - x2
		qq[u * 4 + 3] = (x3 << 4) - x3
	}

	mem.zero_explicit(&skey, size_of(skey))
	mem.zero_explicit(&q, size_of(q))
	mem.zero_explicit(&comp_skey, size_of(comp_skey))
}
