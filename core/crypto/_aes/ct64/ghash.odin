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

@(private = "file")
bmul64 :: proc "contextless" (x, y: u64) -> u64 {
	x0 := x & 0x1111111111111111
	x1 := x & 0x2222222222222222
	x2 := x & 0x4444444444444444
	x3 := x & 0x8888888888888888
	y0 := y & 0x1111111111111111
	y1 := y & 0x2222222222222222
	y2 := y & 0x4444444444444444
	y3 := y & 0x8888888888888888
	z0 := (x0 * y0) ~ (x1 * y3) ~ (x2 * y2) ~ (x3 * y1)
	z1 := (x0 * y1) ~ (x1 * y0) ~ (x2 * y3) ~ (x3 * y2)
	z2 := (x0 * y2) ~ (x1 * y1) ~ (x2 * y0) ~ (x3 * y3)
	z3 := (x0 * y3) ~ (x1 * y2) ~ (x2 * y1) ~ (x3 * y0)
	z0 &= 0x1111111111111111
	z1 &= 0x2222222222222222
	z2 &= 0x4444444444444444
	z3 &= 0x8888888888888888
	return z0 | z1 | z2 | z3
}

@(private = "file")
rev64 :: proc "contextless" (x: u64) -> u64 {
	x := x
	x = ((x & 0x5555555555555555) << 1) | ((x >> 1) & 0x5555555555555555)
	x = ((x & 0x3333333333333333) << 2) | ((x >> 2) & 0x3333333333333333)
	x = ((x & 0x0F0F0F0F0F0F0F0F) << 4) | ((x >> 4) & 0x0F0F0F0F0F0F0F0F)
	x = ((x & 0x00FF00FF00FF00FF) << 8) | ((x >> 8) & 0x00FF00FF00FF00FF)
	x = ((x & 0x0000FFFF0000FFFF) << 16) | ((x >> 16) & 0x0000FFFF0000FFFF)
	return (x << 32) | (x >> 32)
}

// ghash calculates the GHASH of data, with the key `key`, and input `dst`
// and `data`, and stores the resulting digest in `dst`.
//
// Note: `dst` is both an input and an output, to support easy implementation
// of GCM.
ghash :: proc "contextless" (dst, key, data: []byte) {
	if len(dst) != _aes.GHASH_BLOCK_SIZE || len(key) != _aes.GHASH_BLOCK_SIZE {
		intrinsics.trap()
	}

	buf := data
	l := len(buf)

	y1 := endian.unchecked_get_u64be(dst[0:])
	y0 := endian.unchecked_get_u64be(dst[8:])
	h1 := endian.unchecked_get_u64be(key[0:])
	h0 := endian.unchecked_get_u64be(key[8:])
	h0r := rev64(h0)
	h1r := rev64(h1)
	h2 := h0 ~ h1
	h2r := h0r ~ h1r

	src: []byte
	for l > 0 {
		if l >= _aes.GHASH_BLOCK_SIZE {
			src = buf
			buf = buf[_aes.GHASH_BLOCK_SIZE:]
			l -= _aes.GHASH_BLOCK_SIZE
		} else {
			tmp: [_aes.GHASH_BLOCK_SIZE]byte
			copy(tmp[:], buf)
			src = tmp[:]
			l = 0
		}
		y1 ~= endian.unchecked_get_u64be(src)
		y0 ~= endian.unchecked_get_u64be(src[8:])

		y0r := rev64(y0)
		y1r := rev64(y1)
		y2 := y0 ~ y1
		y2r := y0r ~ y1r

		z0 := bmul64(y0, h0)
		z1 := bmul64(y1, h1)
		z2 := bmul64(y2, h2)
		z0h := bmul64(y0r, h0r)
		z1h := bmul64(y1r, h1r)
		z2h := bmul64(y2r, h2r)
		z2 ~= z0 ~ z1
		z2h ~= z0h ~ z1h
		z0h = rev64(z0h) >> 1
		z1h = rev64(z1h) >> 1
		z2h = rev64(z2h) >> 1

		v0 := z0
		v1 := z0h ~ z2
		v2 := z1 ~ z2h
		v3 := z1h

		v3 = (v3 << 1) | (v2 >> 63)
		v2 = (v2 << 1) | (v1 >> 63)
		v1 = (v1 << 1) | (v0 >> 63)
		v0 = (v0 << 1)

		v2 ~= v0 ~ (v0 >> 1) ~ (v0 >> 2) ~ (v0 >> 7)
		v1 ~= (v0 << 63) ~ (v0 << 62) ~ (v0 << 57)
		v3 ~= v1 ~ (v1 >> 1) ~ (v1 >> 2) ~ (v1 >> 7)
		v2 ~= (v1 << 63) ~ (v1 << 62) ~ (v1 << 57)

		y0 = v2
		y1 = v3
	}

	endian.unchecked_put_u64be(dst[0:], y1)
	endian.unchecked_put_u64be(dst[8:], y0)
}
