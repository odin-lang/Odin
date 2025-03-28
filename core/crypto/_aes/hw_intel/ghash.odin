// Copyright (c) 2017 Thomas Pornin <pornin@bolet.org>
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

#+build amd64
package aes_hw_intel

import "base:intrinsics"
import "core:crypto/_aes"
import "core:simd/x86"

@(private = "file")
GHASH_STRIDE_HW :: 4
@(private = "file")
GHASH_STRIDE_BYTES_HW :: GHASH_STRIDE_HW * _aes.GHASH_BLOCK_SIZE

// GHASH is defined over elements of GF(2^128) with "full little-endian"
// representation: leftmost byte is least significant, and, within each
// byte, leftmost _bit_ is least significant. The natural ordering in
// x86 is "mixed little-endian": bytes are ordered from least to most
// significant, but bits within a byte are in most-to-least significant
// order. Going to full little-endian representation would require
// reversing bits within each byte, which is doable but expensive.
//
// Instead, we go to full big-endian representation, by swapping bytes
// around, which is done with a single _mm_shuffle_epi8() opcode (it
// comes with SSSE3; all CPU that offer pclmulqdq also have SSSE3). We
// can use a full big-endian representation because in a carryless
// multiplication, we have a nice bit reversal property:
//
// rev_128(x) * rev_128(y) = rev_255(x * y)
//
// So by using full big-endian, we still get the right result, except
// that it is right-shifted by 1 bit. The left-shift is relatively
// inexpensive, and it can be mutualised.
//
// Since SSE2 opcodes do not have facilities for shifting full 128-bit
// values with bit precision, we have to break down values into 64-bit
// chunks. We number chunks from 0 to 3 in left to right order.

@(private = "file")
_BYTESWAP_INDEX: x86.__m128i : { 0x08090a0b0c0d0e0f, 0x0001020304050607 }

@(private = "file", require_results, enable_target_feature = "sse2,ssse3")
byteswap :: #force_inline proc "contextless" (x: x86.__m128i) -> x86.__m128i {
	return x86._mm_shuffle_epi8(x, _BYTESWAP_INDEX)
}

// From a 128-bit value kw, compute kx as the XOR of the two 64-bit
// halves of kw (into the right half of kx; left half is unspecified),
// and return kx.
@(private = "file", require_results, enable_target_feature = "sse2")
bk :: #force_inline proc "contextless" (kw: x86.__m128i) -> x86.__m128i {
	return x86._mm_xor_si128(kw, x86._mm_shuffle_epi32(kw, 0x0e))
}

// Combine two 64-bit values (k0:k1) into a 128-bit (kw) value and
// the XOR of the two values (kx), and return (kw, kx).
@(private = "file", enable_target_feature = "sse2")
pbk :: #force_inline proc "contextless" (k0, k1: x86.__m128i) -> (x86.__m128i, x86.__m128i) {
	kw := x86._mm_unpacklo_epi64(k1, k0)
	kx := x86._mm_xor_si128(k0, k1)
	return kw, kx
}

// Left-shift by 1 bit a 256-bit value (in four 64-bit words).
@(private = "file", require_results, enable_target_feature = "sse2")
sl_256 :: #force_inline proc "contextless" (x0, x1, x2, x3: x86.__m128i) -> (x86.__m128i, x86.__m128i, x86.__m128i, x86.__m128i) {
	x0, x1, x2, x3 := x0, x1, x2, x3

	x0 = x86._mm_or_si128(x86._mm_slli_epi64(x0, 1), x86._mm_srli_epi64(x1, 63))
	x1 = x86._mm_or_si128(x86._mm_slli_epi64(x1, 1), x86._mm_srli_epi64(x2, 63))
	x2 = x86._mm_or_si128(x86._mm_slli_epi64(x2, 1), x86._mm_srli_epi64(x3, 63))
	x3 = x86._mm_slli_epi64(x3, 1)

	return x0, x1, x2, x3
}

// Perform reduction in GF(2^128).
@(private = "file", require_results, enable_target_feature = "sse2")
reduce_f128 :: #force_inline proc "contextless" (x0, x1, x2, x3: x86.__m128i) -> (x86.__m128i, x86.__m128i) {
	x0, x1, x2 := x0, x1, x2

	x1 = x86._mm_xor_si128(
		x1,
		x86._mm_xor_si128(
			x86._mm_xor_si128(
				x3,
				x86._mm_srli_epi64(x3, 1)),
			x86._mm_xor_si128(
				x86._mm_srli_epi64(x3, 2),
				x86._mm_srli_epi64(x3, 7))))
	x2 = x86._mm_xor_si128(
		x86._mm_xor_si128(
			x2,
			x86._mm_slli_epi64(x3, 63)),
		x86._mm_xor_si128(
			x86._mm_slli_epi64(x3, 62),
			x86._mm_slli_epi64(x3, 57)))
	x0 = x86._mm_xor_si128(
		x0,
		x86._mm_xor_si128(
			x86._mm_xor_si128(
				x2,
				x86._mm_srli_epi64(x2, 1)),
			x86._mm_xor_si128(
				x86._mm_srli_epi64(x2, 2),
				x86._mm_srli_epi64(x2, 7))))
	x1 = x86._mm_xor_si128(
		x86._mm_xor_si128(
			x1,
			x86._mm_slli_epi64(x2, 63)),
		x86._mm_xor_si128(
			x86._mm_slli_epi64(x2, 62),
			x86._mm_slli_epi64(x2, 57)))

	return x0, x1
}

// Square value kw in GF(2^128) into (dw,dx).
@(private = "file", require_results, enable_target_feature = "sse2,pclmul")
square_f128 :: #force_inline proc "contextless" (kw: x86.__m128i) -> (x86.__m128i, x86.__m128i) {
	z1 := x86._mm_clmulepi64_si128(kw, kw, 0x11)
	z3 := x86._mm_clmulepi64_si128(kw, kw, 0x00)
	z0 := x86._mm_shuffle_epi32(z1, 0x0E)
	z2 := x86._mm_shuffle_epi32(z3, 0x0E)
	z0, z1, z2, z3 = sl_256(z0, z1, z2, z3)
	z0, z1 = reduce_f128(z0, z1, z2, z3)
	return pbk(z0, z1)
}

// ghash calculates the GHASH of data, with the key `key`, and input `dst`
// and `data`, and stores the resulting digest in `dst`.
//
// Note: `dst` is both an input and an output, to support easy implementation
// of GCM.
@(enable_target_feature = "sse2,ssse3,pclmul")
ghash :: proc "contextless" (dst, key, data: []byte) #no_bounds_check {
	if len(dst) != _aes.GHASH_BLOCK_SIZE || len(key) != _aes.GHASH_BLOCK_SIZE {
		panic_contextless("aes/ghash: invalid dst or key size")
	}

	// Note: BearSSL opts to copy the remainder into a zero-filled
	// 64-byte buffer.  We do something slightly more simple.

	// Load key and dst (h and y).
	yw := intrinsics.unaligned_load((^x86.__m128i)(raw_data(dst)))
	h1w := intrinsics.unaligned_load((^x86.__m128i)(raw_data(key)))
	yw = byteswap(yw)
	h1w = byteswap(h1w)
	h1x := bk(h1w)

	// Process 4 blocks at a time
	buf := data
	l := len(buf)
	if l >= GHASH_STRIDE_BYTES_HW {
		// Compute h2 = h^2
		h2w, h2x := square_f128(h1w)

		// Compute h3 = h^3 = h*(h^2)
		t1 := x86._mm_clmulepi64_si128(h1w, h2w, 0x11)
		t3 := x86._mm_clmulepi64_si128(h1w, h2w, 0x00)
		t2 := x86._mm_xor_si128(
			x86._mm_clmulepi64_si128(h1x, h2x, 0x00),
			x86._mm_xor_si128(t1, t3))
		t0 := x86._mm_shuffle_epi32(t1, 0x0E)
		t1 = x86._mm_xor_si128(t1, x86._mm_shuffle_epi32(t2, 0x0E))
		t2 = x86._mm_xor_si128(t2, x86._mm_shuffle_epi32(t3, 0x0E))
		t0, t1, t2, t3 = sl_256(t0, t1, t2, t3)
		t0, t1 = reduce_f128(t0, t1, t2, t3)
		h3w, h3x := pbk(t0, t1)

		// Compute h4 = h^4 = (h^2)^2
		h4w, h4x := square_f128(h2w)

		for l >= GHASH_STRIDE_BYTES_HW {
			aw0 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(buf)))
			aw1 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(buf[16:])))
			aw2 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(buf[32:])))
			aw3 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(buf[48:])))
			aw0 = byteswap(aw0)
			aw1 = byteswap(aw1)
			aw2 = byteswap(aw2)
			aw3 = byteswap(aw3)
			buf, l = buf[GHASH_STRIDE_BYTES_HW:], l - GHASH_STRIDE_BYTES_HW

			aw0 = x86._mm_xor_si128(aw0, yw)
			ax1 := bk(aw1)
			ax2 := bk(aw2)
			ax3 := bk(aw3)
			ax0 := bk(aw0)

			t1 = x86._mm_xor_si128(
				x86._mm_xor_si128(
					x86._mm_clmulepi64_si128(aw0, h4w, 0x11),
					x86._mm_clmulepi64_si128(aw1, h3w, 0x11)),
				x86._mm_xor_si128(
					x86._mm_clmulepi64_si128(aw2, h2w, 0x11),
					x86._mm_clmulepi64_si128(aw3, h1w, 0x11)))
			t3 = x86._mm_xor_si128(
				x86._mm_xor_si128(
					x86._mm_clmulepi64_si128(aw0, h4w, 0x00),
					x86._mm_clmulepi64_si128(aw1, h3w, 0x00)),
				x86._mm_xor_si128(
					x86._mm_clmulepi64_si128(aw2, h2w, 0x00),
					x86._mm_clmulepi64_si128(aw3, h1w, 0x00)))
			t2 = x86._mm_xor_si128(
				x86._mm_xor_si128(
					x86._mm_clmulepi64_si128(ax0, h4x, 0x00),
					x86._mm_clmulepi64_si128(ax1, h3x, 0x00)),
				x86._mm_xor_si128(
					x86._mm_clmulepi64_si128(ax2, h2x, 0x00),
					x86._mm_clmulepi64_si128(ax3, h1x, 0x00)))
			t2 = x86._mm_xor_si128(t2, x86._mm_xor_si128(t1, t3))
			t0 = x86._mm_shuffle_epi32(t1, 0x0E)
			t1 = x86._mm_xor_si128(t1, x86._mm_shuffle_epi32(t2, 0x0E))
			t2 = x86._mm_xor_si128(t2, x86._mm_shuffle_epi32(t3, 0x0E))
			t0, t1, t2, t3 = sl_256(t0, t1, t2, t3)
			t0, t1 = reduce_f128(t0, t1, t2, t3)
			yw = x86._mm_unpacklo_epi64(t1, t0)
		}
	}

	// Process 1 block at a time
	for l > 0 {
		src: []byte = ---
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

		aw := intrinsics.unaligned_load((^x86.__m128i)(raw_data(src)))
		aw = byteswap(aw)

		aw = x86._mm_xor_si128(aw, yw)
		ax := bk(aw)

		t1 := x86._mm_clmulepi64_si128(aw, h1w, 0x11)
		t3 := x86._mm_clmulepi64_si128(aw, h1w, 0x00)
		t2 := x86._mm_clmulepi64_si128(ax, h1x, 0x00)
		t2 = x86._mm_xor_si128(t2, x86._mm_xor_si128(t1, t3))
		t0 := x86._mm_shuffle_epi32(t1, 0x0E)
		t1 = x86._mm_xor_si128(t1, x86._mm_shuffle_epi32(t2, 0x0E))
		t2 = x86._mm_xor_si128(t2, x86._mm_shuffle_epi32(t3, 0x0E))
		t0, t1, t2, t3 = sl_256(t0, t1, t2, t3)
		t0, t1 = reduce_f128(t0, t1, t2, t3)
		yw = x86._mm_unpacklo_epi64(t1, t0)
	}

	// Write back the hash (dst, aka y)
	yw = byteswap(yw)
	intrinsics.unaligned_store((^x86.__m128i)(raw_data(dst)), yw)
}
