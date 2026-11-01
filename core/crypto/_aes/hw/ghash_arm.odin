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

#+build arm64
package aes_hw

import "base:intrinsics"
import "core:crypto/_aes"
import "core:simd"
import "core:simd/arm"

@(private = "file")
GHASH_STRIDE_HW :: 8
@(private = "file")
GHASH_STRIDE_BYTES_HW :: GHASH_STRIDE_HW * _aes.GHASH_BLOCK_SIZE

// This uses the same full big-endian representation as ghash_intel.odin
// (see the comment there), with each 128-bit value held in a u64x2 where
// lane 0 is the least significant 64 bits.
//
// The reduction is different. Instead of left-shifting every product by
// 1 bit and then reducing it with shifts, we left-shift the key by 1 bit
// once up front, so the products come out already aligned, and reduce
// each 256-bit product with 2 PMULLs. This is the usual way of doing it
// on ARMv8, where PMULL is cheap.
//
// There are 32 vector registers, so we do 8 blocks at a time instead of 4.

@(private = "file")
_REDUCE_CONSTANT: simd.u64x2 : { 0xc200000000000000, 0 }

@(private = "file", require_results, enable_target_feature = "neon")
byteswap :: #force_inline proc "contextless" (x: simd.u64x2) -> simd.u64x2 {
	b := transmute(simd.u8x16)x
	b = simd.swizzle(b, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
	return transmute(simd.u64x2)b
}

@(private = "file", require_results, enable_target_feature = "neon")
load :: #force_inline proc "contextless" (src: []byte) -> simd.u64x2 {
	return byteswap(intrinsics.unaligned_load((^simd.u64x2)(raw_data(src))))
}

// From a 128-bit value kw, compute kx as the XOR of the two 64-bit
// halves of kw (into the right half of kx; left half is unspecified),
// and return kx.
@(private = "file", require_results, enable_target_feature = "neon")
bk :: #force_inline proc "contextless" (kw: simd.u64x2) -> simd.u64x2 {
	return simd.bit_xor(kw, simd.shuffle(kw, kw, 1, 0))
}

// Left-shift the key by 1 bit, and reduce the bit that gets shifted out
// of the top. Doing this to the key once saves having to shift every
// product, like sl_256 does in ghash_intel.odin.
@(private = "file", require_results, enable_target_feature = "neon")
twist :: #force_inline proc "contextless" (h: simd.u64x2) -> simd.u64x2 {
	carry := simd.shr(h, 63)
	t := simd.bit_or(simd.shl(h, 1), simd.shuffle(carry, carry, 1, 0))
	mask := simd.sub(simd.u64x2{}, simd.shuffle(carry, carry, 1, 1))
	return simd.bit_xor(t, simd.bit_and(mask, simd.u64x2{0, 0xc200000000000000}))
}

// Same as _mm_clmulepi64_si128(a, b, 0x00).
@(private = "file", require_results, enable_target_feature = "neon,aes")
clmul_lo :: #force_inline proc "contextless" (a, b: simd.u64x2) -> simd.u64x2 {
	return transmute(simd.u64x2)arm.vmull_p64(simd.extract(a, 0), simd.extract(b, 0))
}

// Same as _mm_clmulepi64_si128(a, b, 0x11).
@(private = "file", require_results, enable_target_feature = "neon,aes")
clmul_hi :: #force_inline proc "contextless" (a, b: simd.u64x2) -> simd.u64x2 {
	return transmute(simd.u64x2)arm.vmull_high_p64(a, b)
}

// Do the 3 carryless multiplies for a * k (Karatsuba), without reducing.
// The results for several blocks can be XORed together and then reduced
// once.
@(private = "file", require_results, enable_target_feature = "neon,aes")
products :: #force_inline proc "contextless" (a, k, kx: simd.u64x2) -> (lo, mid, hi: simd.u64x2) {
	lo = clmul_lo(a, k)
	mid = clmul_lo(bk(a), kx)
	hi = clmul_hi(a, k)
	return
}

// Finish the Karatsuba multiply and reduce the 256-bit result. From most
// to least significant, the 64-bit words of the product are:
//
//   p3 = hi[1], p2 = hi[0] ~ m[1], p1 = lo[1] ~ m[0], p0 = lo[0]
//
// where m = mid ~ lo ~ hi. The low words (p1, p0) get folded into the
// high words (p3, p2) one at a time, with a PMULL each.
@(private = "file", require_results, enable_target_feature = "neon,aes")
reduce :: #force_inline proc "contextless" (lo, mid, hi: simd.u64x2) -> simd.u64x2 {
	m := simd.bit_xor(mid, simd.bit_xor(lo, hi))
	m = simd.bit_xor(m, simd.shuffle(lo, hi, 1, 2)) // p1, p2
	upper := simd.shuffle(m, hi, 1, 3) // p2, p3
	lower := simd.shuffle(m, lo, 0, 2) // p1, p0

	x := simd.bit_xor(lower, clmul_lo(lo, _REDUCE_CONSTANT))
	x = simd.bit_xor(simd.shuffle(x, x, 1, 0), clmul_lo(x, _REDUCE_CONSTANT))
	return simd.bit_xor(upper, x)
}

// Multiply a by the twisted key k, where kx = bk(k).
@(private = "file", require_results, enable_target_feature = "neon,aes")
mul :: #force_inline proc "contextless" (a, k, kx: simd.u64x2) -> simd.u64x2 {
	lo, mid, hi := products(a, k, kx)
	return reduce(lo, mid, hi)
}

// ghash calculates the GHASH of data, with the key `key`, and input `dst`
// and `data`, and stores the resulting digest in `dst`.
//
// Note: `dst` is both an input and an output, to support easy implementation
// of GCM.
@(enable_target_feature = "neon,aes")
ghash :: proc "contextless" (dst, key, data: []byte) #no_bounds_check {
	if len(dst) != _aes.GHASH_BLOCK_SIZE || len(key) != _aes.GHASH_BLOCK_SIZE {
		panic_contextless("aes/ghash: invalid dst or key size")
	}

	// Load key and dst (h and y), and twist the key.
	yw := load(dst)
	h1w := load(key)
	k1w := twist(h1w)
	k1x := bk(k1w)

	// Process 8 blocks at a time
	buf := data
	l := len(buf)
	if l >= GHASH_STRIDE_BYTES_HW {
		// Compute the twisted h^8 down to h^1. Block i of the stride gets
		// multiplied by kw[i] = h^(8 - i), so the whole stride only needs
		// one reduction.
		kw: [GHASH_STRIDE_HW]simd.u64x2 = ---
		kx: [GHASH_STRIDE_HW]simd.u64x2 = ---
		kw[GHASH_STRIDE_HW - 1], kx[GHASH_STRIDE_HW - 1] = k1w, k1x
		hnw := h1w
		for i := GHASH_STRIDE_HW - 2; i >= 0; i -= 1 {
			hnw = mul(hnw, k1w, k1x)
			kw[i] = twist(hnw)
		}
		#unroll for i in 0 ..< GHASH_STRIDE_HW - 1 {
			kx[i] = bk(kw[i])
		}

		for l >= GHASH_STRIDE_BYTES_HW {
			lo, mid, hi := products(simd.bit_xor(load(buf), yw), kw[0], kx[0])
			#unroll for i in 1 ..< GHASH_STRIDE_HW {
				t_lo, t_mid, t_hi := products(load(buf[i * _aes.GHASH_BLOCK_SIZE:]), kw[i], kx[i])
				lo = simd.bit_xor(lo, t_lo)
				mid = simd.bit_xor(mid, t_mid)
				hi = simd.bit_xor(hi, t_hi)
			}
			buf, l = buf[GHASH_STRIDE_BYTES_HW:], l - GHASH_STRIDE_BYTES_HW

			yw = reduce(lo, mid, hi)
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

		yw = mul(simd.bit_xor(load(src), yw), k1w, k1x)
	}

	// Write back the hash (dst, aka y)
	intrinsics.unaligned_store((^simd.u64x2)(raw_data(dst)), byteswap(yw))
}
