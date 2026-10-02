// Copyright 2012 The Go Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google LLC nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/*
`scrypt` password-based key derivation function.

`scrypt` is designed to be memory-hard, making it expensive to attack with
custom hardware, and is defined in Colin Percival's paper "Stronger Key
Derivation via Sequential Memory-Hard Functions".

This is a port of `golang.org/x/crypto/scrypt`.

See:
- [[ https://www.tarsnap.com/scrypt/scrypt.pdf ]]
- [[ https://www.rfc-editor.org/rfc/rfc7914 ]]
*/
package scrypt

import "core:crypto/hash"
import "core:crypto/pbkdf2"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// derive derives a key from the password, salt, and cost parameters, and
// writes it to the dst buffer.  The dst buffer can be of any non-negative
// length.
//
// N is a CPU/memory cost parameter, which must be a power of two greater
// than 1.  r and p must satisfy r * p < 2³⁰.  If the parameters do not
// satisfy the limits, the procedure will panic.
//
// For example, a derived key suitable for use with AES-256 (which requires
// a 32-byte key) can be generated with:
//
//	key: [32]byte
//	scrypt.derive([]byte("some password"), salt, 32768, 8, 1, key[:])
//
// The recommended parameters for interactive logins as of 2017 are
// N = 32768, r = 8, and p = 1.  The parameters N, r, and p should be
// increased as memory latency and CPU parallelism increase; consider
// setting N to the highest power of 2 that can be derived within 100
// milliseconds.  Remember to use a good random salt.
//
// The working memory that `scrypt` requires (128 * r * N bytes, in addition
// to the `64 * r` bytes of scratch space) is allocated with the specified
// allocator.  Returns a memory allocation error if the allocation fails.
//
// If sanitize is true (the default), the working memory will be zeroed
// before being released.  Disabling this can be worthwhile when N * r is
// large, at the cost of leaving potentially sensitive data in memory.
@(require_results)
derive :: proc(
	password:  []byte,
	salt:      []byte,
	N, r, p:   int,
	dst:       []byte,
	sanitize  := true,
	allocator := context.allocator,
) -> mem.Allocator_Error #no_bounds_check {
	ensure(N > 1 && (N & (N - 1)) == 0, "crypto/scrypt: N must be > 1 and a power of 2")
	ensure(r > 0 && p > 0, "crypto/scrypt: r and p must be > 0")

	max_int := max(int)
	ensure(
		u64(r) * u64(p) < 1 << 30 &&
		r <= max_int / 128 / p &&
		r <= max_int / 256 &&
		N <= max_int / 128 / r,
		"crypto/scrypt: parameters are too large",
	)

	xy := make([]u32, 64 * r, allocator) or_return
	defer {
		if sanitize {
			mem.zero_explicit(raw_data(xy), len(xy) * size_of(u32))
		}
		delete(xy, allocator)
	}

	v := make([]u32, 32 * N * r, allocator) or_return
	defer {
		if sanitize {
			mem.zero_explicit(raw_data(v), len(v) * size_of(u32))
		}
		delete(v, allocator)
	}

	b := make([]byte, p * 128 * r, allocator) or_return
	defer {
		if sanitize {
			mem.zero_explicit(raw_data(b), len(b))
		}
		delete(b, allocator)
	}

	pbkdf2.derive(hash.Algorithm.SHA256, password, salt, 1, b)

	for i in 0 ..< p {
		smix(b[i * 128 * r:], r, N, v, xy)
	}

	pbkdf2.derive(hash.Algorithm.SHA256, password, b, 1, dst)

	return nil
}

// block_copy copies n numbers from src into dst.
@(private)
block_copy :: proc "contextless" (dst, src: []u32, n: int) #no_bounds_check {
	copy(dst[:n], src[:n])
}

// block_xor XORs numbers from dst with n numbers from src.
@(private)
block_xor :: proc "contextless" (dst, src: []u32, n: int) #no_bounds_check {
	for i in 0 ..< n {
		dst[i] ~= src[i]
	}
}

// salsa_xor applies Salsa20/8 to the XOR of 16 numbers from tmp and in_,
// and puts the result into both tmp and out.
@(private)
salsa_xor :: proc "contextless" (tmp: ^[16]u32, in_, out: []u32) #no_bounds_check {
	w0 := tmp[0] ~ in_[0];   w1 := tmp[1] ~ in_[1]
	w2 := tmp[2] ~ in_[2];   w3 := tmp[3] ~ in_[3]
	w4 := tmp[4] ~ in_[4];   w5 := tmp[5] ~ in_[5]
	w6 := tmp[6] ~ in_[6];   w7 := tmp[7] ~ in_[7]
	w8 := tmp[8] ~ in_[8];   w9 := tmp[9] ~ in_[9]
	w10 := tmp[10] ~ in_[10]; w11 := tmp[11] ~ in_[11]
	w12 := tmp[12] ~ in_[12]; w13 := tmp[13] ~ in_[13]
	w14 := tmp[14] ~ in_[14]; w15 := tmp[15] ~ in_[15]

	x0, x1, x2, x3 := w0, w1, w2, w3
	x4, x5, x6, x7 := w4, w5, w6, w7
	x8, x9, x10, x11 := w8, w9, w10, w11
	x12, x13, x14, x15 := w12, w13, w14, w15

	for _ in 0 ..< 4 {
		x4 ~= bits.rotate_left32(x0 + x12, 7)
		x8 ~= bits.rotate_left32(x4 + x0, 9)
		x12 ~= bits.rotate_left32(x8 + x4, 13)
		x0 ~= bits.rotate_left32(x12 + x8, 18)

		x9 ~= bits.rotate_left32(x5 + x1, 7)
		x13 ~= bits.rotate_left32(x9 + x5, 9)
		x1 ~= bits.rotate_left32(x13 + x9, 13)
		x5 ~= bits.rotate_left32(x1 + x13, 18)

		x14 ~= bits.rotate_left32(x10 + x6, 7)
		x2 ~= bits.rotate_left32(x14 + x10, 9)
		x6 ~= bits.rotate_left32(x2 + x14, 13)
		x10 ~= bits.rotate_left32(x6 + x2, 18)

		x3 ~= bits.rotate_left32(x15 + x11, 7)
		x7 ~= bits.rotate_left32(x3 + x15, 9)
		x11 ~= bits.rotate_left32(x7 + x3, 13)
		x15 ~= bits.rotate_left32(x11 + x7, 18)

		x1 ~= bits.rotate_left32(x0 + x3, 7)
		x2 ~= bits.rotate_left32(x1 + x0, 9)
		x3 ~= bits.rotate_left32(x2 + x1, 13)
		x0 ~= bits.rotate_left32(x3 + x2, 18)

		x6 ~= bits.rotate_left32(x5 + x4, 7)
		x7 ~= bits.rotate_left32(x6 + x5, 9)
		x4 ~= bits.rotate_left32(x7 + x6, 13)
		x5 ~= bits.rotate_left32(x4 + x7, 18)

		x11 ~= bits.rotate_left32(x10 + x9, 7)
		x8 ~= bits.rotate_left32(x11 + x10, 9)
		x9 ~= bits.rotate_left32(x8 + x11, 13)
		x10 ~= bits.rotate_left32(x9 + x8, 18)

		x12 ~= bits.rotate_left32(x15 + x14, 7)
		x13 ~= bits.rotate_left32(x12 + x15, 9)
		x14 ~= bits.rotate_left32(x13 + x12, 13)
		x15 ~= bits.rotate_left32(x14 + x13, 18)
	}
	x0 += w0; x1 += w1; x2 += w2; x3 += w3
	x4 += w4; x5 += w5; x6 += w6; x7 += w7
	x8 += w8; x9 += w9; x10 += w10; x11 += w11
	x12 += w12; x13 += w13; x14 += w14; x15 += w15

	out[0] = x0;   tmp[0] = x0
	out[1] = x1;   tmp[1] = x1
	out[2] = x2;   tmp[2] = x2
	out[3] = x3;   tmp[3] = x3
	out[4] = x4;   tmp[4] = x4
	out[5] = x5;   tmp[5] = x5
	out[6] = x6;   tmp[6] = x6
	out[7] = x7;   tmp[7] = x7
	out[8] = x8;   tmp[8] = x8
	out[9] = x9;   tmp[9] = x9
	out[10] = x10; tmp[10] = x10
	out[11] = x11; tmp[11] = x11
	out[12] = x12; tmp[12] = x12
	out[13] = x13; tmp[13] = x13
	out[14] = x14; tmp[14] = x14
	out[15] = x15; tmp[15] = x15
}

@(private)
block_mix :: proc "contextless" (tmp: ^[16]u32, in_, out: []u32, r: int) #no_bounds_check {
	block_copy(tmp[:], in_[(2 * r - 1) * 16:], 16)
	for i := 0; i < 2 * r; i += 2 {
		salsa_xor(tmp, in_[i * 16:], out[i * 8:])
		salsa_xor(tmp, in_[i * 16 + 16:], out[i * 8 + r * 16:])
	}
}

@(private)
_integer :: proc "contextless" (b: []u32, r: int) -> u64 #no_bounds_check {
	j := (2 * r - 1) * 16
	return u64(b[j]) | u64(b[j + 1]) << 32
}

@(private)
smix :: proc "contextless" (b: []byte, r, N: int, v, xy: []u32) #no_bounds_check {
	tmp: [16]u32
	defer mem.zero_explicit(&tmp, size_of(tmp))

	R := 32 * r
	x := xy[:R]
	y := xy[R:2 * R]

	j := 0
	for i in 0 ..< R {
		x[i] = endian.unchecked_get_u32le(b[j:])
		j += 4
	}
	for i := 0; i < N; i += 2 {
		block_copy(v[i * R:], x, R)
		block_mix(&tmp, x, y, r)

		block_copy(v[(i + 1) * R:], y, R)
		block_mix(&tmp, y, x, r)
	}
	for i := 0; i < N; i += 2 {
		k := int(_integer(x, r) & u64(N - 1))
		block_xor(x, v[k * R:], R)
		block_mix(&tmp, x, y, r)

		k = int(_integer(y, r) & u64(N - 1))
		block_xor(y, v[k * R:], R)
		block_mix(&tmp, y, x, r)
	}
	j = 0
	for val in x[:R] {
		endian.unchecked_put_u32le(b[j:], val)
		j += 4
	}
}
