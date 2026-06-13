// Constant time Big Integers
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

import "base:intrinsics"
import "core:crypto"
import subtle "core:crypto/_subtle"
import "core:slice"

/*
	TODO(yawning): Check that the following are applied as necessary:
	- #no_bounds_check
*/

// Integers 'i31'
// --------------
//
// The 'i31' functions implement computations on big integers using
// an internal representation as an array of 32-bit integers. For
// an array `x`:
//  -- x[0] encodes the array length and the "announced bit length"
//     of the integer: namely, if the announced bit length is k,
//     then x[0] = ((k / 31) << 5) + (k % 31).
//  -- x[1], x[2]... contain the value in little-endian order, 31
//     bits per word (x[1] contains the least significant 31 bits).
//     The upper bit of each word is 0.
//
// Multiplications rely on the elementary 32x32->64 multiplication.
//
// The announced bit length specifies the number of bits that are
// significant in the subsequent 32-bit words. Unused bits in the
// last (most significant) word are set to 0; subsequent words are
// uninitialized and need not exist at all.
//
// The execution time and memory access patterns of all computations
// depend on the announced bit length, but not on the actual word
// values. For modular integers, the announced bit length of any integer
// modulo `n` is equal to the actual bit length of `n`; thus, computations
// on modular integers are "constant-time" (only the modulus length may leak).

I31_MASK :: 0x7fff_ffff

// Compute the bit length of a 32-bit integer.
// Returned value is between 0 and 32 (inclusive).
@(require_results)
_u32_bit_length :: proc "contextless" (x: u32) -> (length: u32) {
	x := x
	k := subtle.neq(x, 0)
	c := subtle.gt(x, 0xFFFF); x = subtle.csel(x, x >> 16, c); k += c << 4
	c  = subtle.gt(x, 0x00FF); x = subtle.csel(x, x >>  8, c); k += c << 3
	c  = subtle.gt(x, 0x000F); x = subtle.csel(x, x >>  4, c); k += c << 2
	c  = subtle.gt(x, 0x0003); x = subtle.csel(x, x >>  2, c); k += c << 1
	k += subtle.gt(x, 0x0001)
	return k
}

// Multiply two 31-bit integers, with a 62-bit result. This default
// implementation assumes that the basic multiplication operator
// yields constant-time code.
//
// The mul31_lo() returns only the low 31 bits of the product.
//
// Note/Odin:
// The original BearSSL code provides alternative implemenetations
// of these routines gated behind `BR_CT_MUL31`, however that macro
// is only useful on Intel 80386/80486, VIA Nano 2000, and ARM7T/ARM9T.
@(require_results)
_mul31 :: #force_inline proc "contextless" (x, y: u32) -> (res: u64) {
	return u64(x) * u64(y)
}

@(private="file", require_results)
_mul31_lo :: #force_inline proc "contextless" (x, y: u32) -> (res: u32) {
	return (x * y) & I31_MASK
}

// Wrapper for `div_rem`; the remainder is returned, and the quotient is
// discarded.
@(private="file", require_results)
_rem_u32 :: #force_inline proc "contextless" (hi: u32, lo: u32, d: u32) -> (res: u32) {
	_, rem := _div_rem_u32(hi, lo, d)
	return rem
}

// Wrapper for `div_rem`; the quotient is returned, and the remainder is
// discarded.
@(private="file", require_results)
_div_u32 :: #force_inline proc "contextless" (hi: u32, lo: u32, d: u32) -> (quo: u32) {
	q, _ := _div_rem_u32(hi, lo, d)
	return q
}

// Constant-time division. The dividend `hi:lo` is divided by the divisor `d`;
// the quotient and remainder are returned.
//
// If `hi == d`, then the quotient does not fit on 32 bits; returned value is thus truncated.
// If `hi > d`, returned values are indeterminate.
@(require_results)
_div_rem_u32 :: proc "contextless" (hi: u32, lo: u32, d: u32) -> (quo: u32, rem: u32) {
	/* TODO: optimize this */
	hi := hi
	lo := lo
	ch := subtle.eq(hi, d)
	hi = subtle.csel(hi, 0, ch)
	for k := uint(31); k > 0; k -= 1 {
		j   := 32 - k
		w   := (hi << j) | (lo >> k)
		ctl := subtle.ge(w, d) | (hi >> k)
		hi2 := (w - d) >> j
		lo2 := lo - (d << k)
		hi   = subtle.csel(hi, hi2, ctl)
		lo   = subtle.csel(lo, lo2, ctl)
		quo |= ctl << k
	}
	cf := subtle.ge(lo, d) | hi
	quo |= cf
	rem = subtle.csel(lo, lo - d, cf)
	return
}

// Test whether an integer `x` is zero.
@(optimization_mode="none", require_results)
i31_is_zero :: proc "contextless" (x: []u32) -> (res: u32) {
	z: u32

	for u := (x[0] + 31) >> 5; u > 0; u -= 1 {
		z |= x[u]
	}
	return ~(z | -z) >> 31
}

// Add `b` to `a` if `ctl` is `1`.
// If `0`, `a` is left alone but the `carry` will still be computed.
@(require_results)
i31_add :: proc "contextless" (a: []u32, b: []u32, ctl: u32) -> (carry: u32) {
	words := uint(a[0] + 63) >> 5
	for u in 1..<words {
		aw   := a[u]
		bw   := b[u]
		naw  := aw + bw + carry
		carry = naw >> 31
		a[u] = subtle.csel(aw, naw & I31_MASK, ctl)
	}
	return
}

// Subtract `b` from `a` and return the `carry` (`0` or `1`).
// If `ctl` is `0`, then `a` is unmodified, but the carry is still computed
// and returned.
//
// The slices `a` and `b` MUST have the same announced bit length (in subscript `0`)
//
// `a` and `b` MAY be the same array, but partial overlap is not allowed.
@(require_results)
i31_sub :: proc "contextless" (a: []u32, b: []u32, ctl: u32) -> (carry: u32) {
	words := uint(a[0] + 63) >> 5
	for u in 1..<words {
		aw   := a[u]
		bw   := b[u]
		naw  := aw - bw - carry
		carry = naw >> 31
		a[u] = subtle.csel(aw, naw & I31_MASK, ctl)
	}
	return
}

// Compute the ENCODED actual bit length of an integer `x`.
// The argument `x` should point to the first (least significant)
// value word of the integer.
//
// The upper bit of each value word MUST be `0`.
//
// Returned value is `((k / 31) << 5) + (k % 31)` if the bit length is `k`.
//
// CT: value or length of `x` does not leak.
@(require_results)
i31_bit_length :: proc "contextless" (x: []u32) -> (res: u32) {
	tw, twk: u32

	xlen := len(x)
	for xlen > 0 {
		xlen -= 1
		c := subtle.eq(tw, 0)
		w := x[xlen]

		tw   = subtle.csel(tw, w, c)
		twk  = subtle.csel(twk, u32(xlen), c)
	}
	return (twk << 5) + _u32_bit_length(tw)
}

// Decode an integer from its big-endian unsigned representation. The
// "true" bit length of the integer is computed and set in the encoded
// announced bit length (`x[0]`), but all words of `x` corresponding to
// the full slice of source bytes.
//
// `x` needs to have a minimum length of: `1 + ((len(src) * 8) + 31) / 31`
//
// CT: value or length of `x` does not leak.
i31_decode :: proc "contextless" (x: []u32, src: []byte) {
	u := len(src) - 1
	v := 1
	acc     := u32(0)
	acc_len := uint(0)
	for u >= 0 {
		b       := u32(src[u])
		acc     |= b << acc_len
		acc_len += 8
		if acc_len >= 31 {
			x[v] = acc & I31_MASK
			acc_len -= 31
			acc = b >> (8 - acc_len)
			v += 1
		}
		u -= 1
	}
	if acc_len != 0 {
		x[v] = acc
		v += 1
	}
	x[0] = i31_bit_length(x[1:])
}

// Decode an integer from its big-endian unsigned representation.
// The integer MUST be lower than `m`; the (encoded) announced bit length
// written in `x` will be equal to that of `m`. All bytes from the
// `src` slice are read.
//
// Returned value is `1` if the decode value fits within the modulus, `0`
// otherwise. In the latter case, the `x` buffer will be set to `0` (but
// still with the announced bit length of `m`).
//
// CT: value or length of `x` does not leak. Memory access pattern depends
// only `src`'s length and the announced bit length of `m`. Whether `x` fits or
// not does not leak either.
@(require_results)
i31_decode_mod :: proc "contextless" (x: []u32, src: []byte, m: []u32) -> (res: u32) {
	// Two-pass algorithm: in the first pass, we determine whether the
	// value fits; in the second pass, we do the actual write.
	//
	// During the first pass, `res` contains the comparison result so far:
	// 0x00000000   value is equal to the modulus
	// 0x00000001   value is greater than the modulus
	// 0xFFFFFFFF   value is lower than the modulus
	//
	// Since we iterate starting with the least significant bytes (at
	// the end of `src`), each new comparison overrides the previous
	// except when the comparison yields 0 (equal).
	//
	// During the second pass, `res` is either 0xFFFFFFFF (value fits) 0x00000000 (value does not fit).
	// We must iterate over all bytes of the source, _and_ possibly
	// some extra virtual bytes (with value 0) so as to cover the
	// complete modulus as well. We also add 4 such extra bytes beyond
	// the modulus length because it then guarantees that no accumulated
	// partial word remains to be processed.
	_len := uint(len(src))
	mlen := uint((m[0] + 31) >> 5)
	tlen := uint(mlen << 2)
	if tlen < _len {
		tlen = _len
	}
	tlen += 4

	for pass in 0..<2 {
		v       := uint(1)
		acc     := u32(0)
		acc_len := u32(0)

		for u in uint(0)..<tlen {
			b: u32 = ---

			if u < _len {
				b = u32(src[_len - 1 - u])
			} else {
				b = 0
			}

			acc     |= (b << acc_len)
			acc_len += 8
			if acc_len >= 31 {
				xw := acc & I31_MASK
				acc_len -= 31

				acc = b >> (8 - acc_len)
				if v <= mlen {
					if pass == 1 {
						x[v] = res & xw
					} else {
						cc := u32(subtle.cmp(xw, m[v]))
						res = subtle.csel(cc, res, subtle.eq(cc, 0))
					}
				} else {
					if pass == 0 {
						res = subtle.csel(1, res, subtle.eq(xw, 0))
					}
				}
				v += 1
			}
		}

		// When we reach this point at the end of the first pass:
		// r is either 0, 1 or -1; we want to set r to 0 if it
		// is equal to 0 or 1, and leave it to -1 otherwise.
		//
		// When we reach this point at the end of the second pass:
		// r is either 0 or -1; we want to leave that value
		// untouched. This is a subcase of the previous.
		res >>= 1
		res |= (res << 1)
	}

	x[0] = m[0]

	return res & 1
}

// Zeroize integer `x`. The announced bit length is set to the provided value,
// and the corresponding words are set to 0. The ENCODED bit length is expected
//here.
i31_zero :: proc "contextless" (x: []u32, bit_len: u32) {
	x[0] = bit_len
	intrinsics.mem_zero(raw_data(x[1:]), ((bit_len + 31) >> 5) * size_of(u32))
}

// Make a random integer of the provided size. The size is encoded.
// The header word is untouched.
i31_mkrand :: proc(x: []u32, bit_len: u32) {
	num_words := (bit_len + 31) >> 5
	x_ := slice.reinterpret([]byte, x)
	crypto.rand_bytes(x_[4:4 + num_words * size_of(u32)])
	for u in 1..<num_words {
		x[u] &= I31_MASK
	}
	m := bit_len & 31
	if m == 0 {
		x[num_words] &= I31_MASK
	} else {
		x[num_words] &= I31_MASK >> (31 - m)
	}
}

// Right-shift an integer. The shift amount must be lower than 31 bits.
i31_rshift :: proc "contextless" (x: []u32, shift_amount: i32) {
	_len := uint(x[0] + 31) >> 5
	if _len == 0 {
		return
	}

	count := uint(shift_amount)

	r := x[1] >> count
	for u in 2..= _len {
		w := u32(x[u])

		x[u - 1] = ((w << (31 - count)) | r) & I31_MASK
		r = w >> count
	}
	x[_len] = r
}

// Reduce integer `a` modulo `m`. The result is written to `x`,
// and its announced bit length is set to be equal to that of `m`.
//
// `x` MUST be distinct from `a` and `m`.
//
// CT: only announced bit lengths leak, not values of `x`, `a` or `m`.
i31_reduce :: proc "contextless" (x: []u32, a: []u32, m: []u32) {
	m_bitlen := m[0]
	mlen := uint(m_bitlen + 31) >> 5

	x[0] = m_bitlen
	if m_bitlen == 0 {
		return
	}

	// If the source is shorter, then simply copy all words from a[]
	// and zero out the upper words.
	a_bitlen := a[0]
	alen := uint(a_bitlen + 31) >> 5
	if a_bitlen < m_bitlen {
		copy(x[1:], a[1:][:alen])
		for u in alen..<mlen {
			x[u + 1] = 0
		}
		return
	}

	// The source length is at least equal to that of the modulus.
	// We must thus copy N-1 words, and input the remaining words one
	// by one.
	copy(x[1:], a[2 + (alen - mlen):][:mlen - 1])
	x[mlen] = 0
	for u := 1 + alen - mlen; u > 0; u -= 1 {
		i31_muladd_small(x, a[u], m)
	}
}

// Decode an integer from its big-endian unsigned representation, and
// reduce it modulo the provided modulus `m`. The announced bit length
// of the result is set to be equal to that of the modulus.
//
// `x` MUST be distinct from `m`.
i31_decode_reduce :: proc "contextless" (x: []u32, src: []byte, m: []u32) {
	// Get the encoded bit length.
	m_ebitlen := m[0]

	// Special case for an invalid (null) modulus.
	if m_ebitlen == 0 {
		x[0] = 0
		return
	}

	 // Clear the destination.
	i31_zero(x, m_ebitlen)

	// First decode directly as many bytes as possible.
	// This requires computing the actual bit length.
	m_rbitlen := m_ebitlen >> 5
	m_rbitlen  = (m_ebitlen & 31) + (m_rbitlen << 5) - m_rbitlen

	mblen := uint(m_rbitlen + 7) >> 3
	k     := mblen - 1
	_len  := uint(len(src))

	if k >= _len {
		i31_decode(x, src)
		x[0] = m_ebitlen
		return
	}

	i31_decode(x, src[:k])
	x[0] = m_ebitlen

	// Input remaining bytes, using 31-bit words.
	acc     := u32(0)
	acc_len := uint(0)

	for {
		v := u32(src[k])

		if acc_len >= 23 {
			acc_len -= 23
			acc <<= (8 - acc_len)
			acc |= v >> acc_len
			i31_muladd_small(x, acc, m)
			acc = v & (0xFF >> (8 - acc_len))
		} else {
			acc = (acc << 8) | v
			acc_len += 8
		}

		if k += 1; k >= _len {
			break
		}
	}

	// We may have some bits accumulated. We then perform a shift to
	// be able to inject these bits as a full 31-bit word.
	if acc_len != 0 {
		acc = (acc | (x[1] << acc_len)) & I31_MASK
		i31_rshift(x, i32(31 - acc_len))
		i31_muladd_small(x, acc, m)
	}
}

// Multiply `x` by 2^31 and then add integer `z`, modulo `m`.
// This function assumes that `x` and `m` have the same announced bit
// length, the announced bit length of `m` matches its true bit length.
//
// `x` and `m` MUST be distinct arrays.
// `z` MUST fit in 31 bits (upper bit set to 0).
//
// CT: only the common announced bit length of `x` and `m` leaks, not
// the values of `x`, `z` or `m`.
i31_muladd_small :: proc "contextless" (x: []u32, z: u32, m: []u32) {
	// We can test on the modulus bit length since we accept to leak
	// that length.
	m_bitlen := m[0]
	if m_bitlen == 0 {
		return
	}
	hi: u32
	if m_bitlen <= 31 {
		hi  = x[1] >> 1
		lo := (x[1] << 31) | z
		x[1] = _rem_u32(hi, lo, m[1])
		return
	}
	mlen := uint(m_bitlen + 31) >> 5
	mblr := uint(m_bitlen) & 31

	// Principle: we estimate the quotient (x*2^31+z)/m by
	// doing a 64/32 division with the high words.
	//
	// Let:
	//    w = 2^31
	//    a = (w*a0 + a1) * w^N + a2
	//    b = b0 * w^N + b2
	//  such that:
	//    0 <= a0 < w
	//    0 <= a1 < w
	//    0 <= a2 < w^N
	//    w/2 <= b0 < w
	//    0 <= b2 < w^N
	//    a < w*b
	// I.e. the two top words of a are a0:a1, the top word of b is
	// b0, we ensured that b0 is "full" (high bit set), and a is
	// such that the quotient q = a/b fits on one word (0 <= q < w).
	//
	// If a = b*q + r (with 0 <= r < q), we can estimate q by
	// doing an Euclidean division on the top words:
	//    a0*w+a1 = b0*u + v  (with 0 <= v < b0)
	// Then the following holds:
	//    0 <= u <= w
	//    u-2 <= q <= u
	hi = x[mlen]
	a0, a1, b0: u32
	if mblr == 0 {
		a0 = x[mlen]
		intrinsics.mem_copy(raw_data(x[2:]), raw_data(x[1:]), (mlen - 1) * size_of(u32))
		x[1] = z
		a1 = x[mlen]
		b0 = m[mlen]
	} else {
		a0 = ((x[mlen] << (31 - mblr)) | (x[mlen - 1] >> mblr)) & I31_MASK
		intrinsics.mem_copy(raw_data(x[2:]), raw_data(x[1:]), (mlen - 1) * size_of(u32))
		x[1] = z
		a1 = ((x[mlen] << (31 - mblr)) | (x[mlen - 1] >> mblr)) & I31_MASK
		b0 = ((m[mlen] << (31 - mblr)) | (m[mlen - 1] >> mblr)) & I31_MASK
	}

	// We estimate a divisor q. If the quotient returned by div()
	// is g:
	// -- If a0 == b0 then g == 0; we want q = 0x7FFFFFFF.
	// -- Otherwise:
	//    -- if g == 0 then we set q = 0;
	//    -- otherwise, we set q = g - 1.
	// The properties described above then ensure that the true
	// quotient is q-1, q or q+1.
	//
	// Take care that a0, a1 and b0 are 31-bit words, not 32-bit. We
	// must adjust the parameters to br_div() accordingly.
	g := _div_u32(a0 >> 1, a1 | (a0 << 31), b0)
	q := subtle.csel(subtle.csel(g - 1, 0, subtle.eq(g, 0)), I31_MASK, subtle.eq(a0, b0))

	// We subtract q*m from x (with the extra high word of value 'hi').
	// Since q may be off by 1 (in either direction), we may have to
	// add or subtract m afterwards.
	//
	// The 'tb' flag will be true (1) at the end of the loop if the
	// result is greater than or equal to the modulus (not counting
	// 'hi' or the carry).
	cc := u32(0)
	tb := u32(1)
	for u in 1..= mlen {
		mw  := m[u]
		zl  := _mul31(mw, q) + u64(cc)
		cc   = u32(zl >> 31)
		zw  := u32(zl) & I31_MASK
		xw  := x[u]
		nxw := xw - zw
		cc  += nxw >> 31
		nxw &= I31_MASK
		x[u] = nxw
		tb   = subtle.csel(subtle.gt(nxw, mw), tb, subtle.eq(nxw, mw))
	}

	// If we underestimated q, then either cc < hi (one extra bit
	// beyond the top array word), or cc == hi and tb is true (no
	// extra bit, but the result is not lower than the modulus). In
	// these cases we must subtract m once.
	//
	// Otherwise, we may have overestimated, which will show as
	// cc > hi (thus a negative result). Correction is adding m once.
	over  := subtle.gt(cc, hi)
	under := ~over & (tb | subtle.lt(cc, hi))
	_ = i31_add(x, m, over)
	_ = i31_sub(x, m, under)
}

// Encode an integer into its big-endian unsigned representation. The
// output length in bytes is provided (parameter 'len'); if the length
// is too short then the integer is appropriately truncated; if it is
// too long then the extra bytes are set to 0.
i31_encode :: proc "contextless" (dst: []byte, x: []u32) {
	xlen := uint(x[0] + 31) >> 5
	if xlen == 0 {
		intrinsics.mem_zero(raw_data(dst[:]), len(dst) * size_of(u32))
		return
	}
	_len := uint(len(dst))
	k       := uint(1)
	acc     := u32(0)
	acc_len := uint(0)
	for _len != 0 {
		w := (k <= xlen) ? x[k] : 0
		k += 1
		if (acc_len == 0) {
			acc     = w
			acc_len = 31
		} else {
			z := acc | (w << acc_len)
			acc_len -= 1
			acc = w >> (31 - acc_len)
			if _len >= 4 {
				_len -= 4
				ptr := (^u32be)(raw_data(dst[_len:]))
				intrinsics.unaligned_store(ptr, u32be(z))
			} else {
				switch _len {
				case 3:
					dst[_len - 3] = byte(z >> 16)
					fallthrough
				case 2:
					dst[_len - 2] = byte(z >> 8)
					fallthrough
				case 1:
					dst[_len - 1] = byte(z)
				}
				return
			}
		}
	}
}

// Compute `-(1/x) % 2^31`. If `x` is even, then this function returns `0`.
i31_ninv31 :: proc "contextless" (x: u32) -> (y: u32) {
	y = 2 - x
	y *= 2 - y * x
	y *= 2 - y * x
	y *= 2 - y * x
	y *= 2 - y * x
	return subtle.csel(0, -y, x & 1) & I31_MASK
}

// Compute a modular Montgomery multiplication. `d` is filled with the
// value of `x*y/R % m` (where `R` is the Montgomery factor).
//
// The array `d` MUST be distinct from `x`, `y` and `m`[].
// `x` and `y` MUST be numerically lower than `m`.
//
// `x` and `y` MAY be the same array.
//
// The `m0i` parameter is equal to `-(1/m0) mod 2^31`, where `m0` is the least
// significant value word of `m` (this works only if `m` is an odd integer).
i31_montymul :: proc "contextless" (d: []u32, x: []u32, y: []u32, m: []u32, m0i: u32) {
	// Each outer loop iteration computes:
	// 	`d <- (d + xu*y + f*m) / 2^31`
	// We have `xu <= 2^31-1` and `f <= 2^31-1`.
	// Thus, if `d <= 2*m-1` on input, then:
	// 	`2*m-1 + 2*(2^31-1)*m <= (2^32)*m-1`
	// and the new `d` value is less than `2*m`.
	//
	// We represent `d` over 31-bit words, with an extra word `dh`,
	// which can thus be only 0 or 1.
	_len := uint((m[0] + 31) >> 5)
	len4 := _len & ~uint(3)
	i31_zero(d, m[0])
	dh := u32(0)
	for u in 0..<_len {
		// The carry for each operation fits on 32 bits:
		// 	`d[v+1] <= 2^31-1`
		// 	`xu*y[v+1] <= (2^31-1)*(2^31-1)`
		// 	`f*m[v+1] <= (2^31-1)*(2^31-1)`
		// 	`r <= 2^32-1`
		// 	`(2^31-1) + 2*(2^31-1)*(2^31-1) + (2^32-1) = 2^63 - 2^31`
		//
		// After division by `2^31`, the new `r` is then at most `2^32-1`
		//
		// Using a 32-bit carry has performance benefits on 32-bit
		// systems; however, on 64-bit architectures, we prefer to
		// keep the carry (r) in a 64-bit register, thus avoiding some
		// "clear high bits" operations.
		xu := x[u + 1]
		f  := _mul31_lo((d[1] + _mul31_lo(xu, y[1])), m0i)

		r := u64(0)
		v := uint(0)
		for ; v < len4; v += 4 {
			z := u64(d[v + 1]) + _mul31(xu, y[v + 1]) + _mul31(f, m[v + 1]) + r
			r  = z >> 31
			d[v + 0] = u32(z) & I31_MASK
			z  = u64(d[v + 2]) + _mul31(xu, y[v + 2]) + _mul31(f, m[v + 2]) + r
			r  = z >> 31
			d[v + 1] = u32(z) & I31_MASK
			z  = u64(d[v + 3]) + _mul31(xu, y[v + 3]) + _mul31(f, m[v + 3]) + r
			r  = z >> 31
			d[v + 2] = u32(z) & I31_MASK
			z  = u64(d[v + 4]) + _mul31(xu, y[v + 4]) + _mul31(f, m[v + 4]) + r
			r  = z >> 31
			d[v + 3] = u32(z) & I31_MASK
		}
		for ; v < _len; v += 1 {
			z := u64(d[v + 1]) + _mul31(xu, y[v + 1]) + _mul31(f, m[v + 1]) + r
			r  = z >> 31
			d[v] = u32(z) & I31_MASK
		}

		// Since the new `dh` can only be `0` or `1`, the addition of
		// the old dh with the carry MUST fit on 32 bits, and
		// thus can be done into dh itself.
		dh += u32(r)
		d[_len] = dh & I31_MASK
		dh >>= 31
	}

	// We must write back the bit length because it was overwritten in
	// the loop (not overwriting it would require a test in the loop,
	// which would yield bigger and slower code).
	d[0] = m[0]

	// `d` may still be greater than `m` at that point; notably, the `dh`
	// word may be non-zero.
	_ = i31_sub(d, m, subtle.neq(dh, 0) | subtle.not(i31_sub(d, m, 0)))
}

// Convert a modular integer to Montgomery representation.
//
// The integer `x` MUST be lower than `m`, but with the same announced bit length.
i31_to_monty :: proc "contextless" (x: []u32, m: []u32) {
	// uint32_t k;
	for k := (m[0] + 31) >> 5; k > 0; k -= 1 {
		i31_muladd_small(x, 0, m)
	}
}

// Convert a modular integer back from Montgomery representation.
//
// The integer `x` MUST be lower than `m`[], but with the same announced bit
// length.
//
// The `m0i` parameter is equal to `-(1/m0) mod 2^32`, where `m0` is the least
// significant value word of `m` (this works only if `m` is an odd integer).
i31_from_monty :: proc "contextless" (x: []u32, m: []u32, m0i: u32) {
	_len := uint(m[0] + 31) >> 5
	for _ in 0..<_len {
		f  := _mul31_lo(x[1], m0i)
		cc := u64(0)
		for v in 0..<_len {
			z := u64(x[v + 1]) + _mul31(f, m[v + 1]) + cc
			cc = z >> 31
			if v != 0 {
				x[v] = u32(z & I31_MASK)
			}
		}
		x[_len] = u32(cc)
	}

	// We may have to do an extra subtraction, but only if the value in `x`
	// is indeed greater than or equal to that of `m`, which is why we must
	// do two calls:
	// - First call computes the carry
	// - Second call performs the subtraction only if the carry is 0).
	_ = i31_sub(x, m, subtle.not(i31_sub(x, m, 0)))
}

// Compute a modular exponentiation.
//
// `x` MUST be an integer modulo `m` (same announced bit length, lower value).
// `m` MUST be odd.
//
// The exponent `e` is in big-endian unsigned notation.
//
// The `m0i` parameter is equal to `-(1/m0) mod 2^31`, where `m0` is the least
// significant value word of `m` (this works only if `m` is an odd integer).
//
// The `t1` and `t2` parameters must be temporary arrays, each large enough to
// accommodate an integer with the same size as `m`.
i31_modpow :: proc "contextless" (x: []u32, e: []byte, m: []u32, m0i: u32, t1: []u32, t2: []u32) {
	// `mlen` is the length of `m` expressed in `u32`'s (including the
	// "bit length" first field).
	mlen := uint((m[0] + 63) >> 5)
	elen := u32(len(e))

	// Throughout the algorithm:
	//  -- `t1` is in Montgomery representation; it contains x, x^2, x^4, x^8...
	//  -- The result is accumulated, in normal representation, in the `x` array.
	//  -- `t2` is used as destination buffer for each multiplication.
	//
	// Note that there is no need to call `i32_from_monty()`.
	copy(t1[:mlen], x[:mlen])
	i31_to_monty(t1, m)
	i31_zero(x, m[0])
	x[1] = 1
	for k := u32(0); k < (elen << 3); k += 1 {
		ctl := (e[elen - 1 - (k >> 3)] >> (k & 7)) & 1

		i31_montymul(t2, x, t1, m, m0i)

		for &d, i in x[:mlen] {
			d = subtle.csel(d, t2[i], ctl)
		}

		i31_montymul(t2, t1, t1, m, m0i)
		copy(t1[:mlen], t2[:mlen])
	}
}


// Compute a modular exponentiation.
//
// `x` MUST be an integer modulo `m` (same announced bit length, lower value).
// `m` MUST be odd.
//
// The exponent `e` is in big-endian unsigned notation.
//
// The `m0i` parameter is equal to `-(1/m0) mod 2^31`, where `m0` is the least
// significant value word of `m`[] (this works only if m[] is an odd integer).
//
// The `tmp` array is used for temporaries; it must be large enough to accommodate
// at least two temporary values with the same size as `m` (including the leading
// "bit length" word).
//
// If there is room for more temporaries, then this function may use the extra
// room for window-based optimisation, resulting in faster computations.
//
// Returned value is `true` on success, `false` on error. An error is reported if
// the provided `tmp`array is too short.
i31_modpow_opt :: proc "contextless" (x: []u32, e: []byte, m: []u32, m0i: u32, tmp: []u32) -> b32 {
	// NOTE/yawning: This is only used by the rsa_i31 code, with the key
	// generation taking a function pointer to either this routine,
	// or the i62 variant.
	//
	// If we ever need to support the i32 version, it is used extensively,
	// but non e-waste architecutures will all do the right thing with
	// the i62 version, albeit with a perforance hit on 32-bit CPUs.

	unimplemented_contextless()

	// i31_mod_pow(x, e, m, m0i, tmp[:len(m)], tmp[len(m):])
	// return true
}

// Compute `d+a*b`, result in `d`.
//
// The initial announced bit length of `d` MUST match that of `a`[].
//
// The `d` array MUST be large enough to accommodate the full result,
// plus (possibly) an extra word. The resulting announced bit length
// of `d` will be the sum of the announced bit lengths of `a` and `b`
// (therefore, it may be larger than the actual bit length of the numerical result).
//
// `a` and `b` may be the same array. `d` must be disjoint from both `a` and `b`.
i31_mulacc :: proc "contextless" (d: []u32, a: []u32, b: []u32) {
	a_len := uint((a[0] + 31) >> 5)
	b_len := uint((b[0] + 31) >> 5)

	// We want to add the two bit lengths, but these are encoded,
	// which requires some extra care.
	d_l := (a[0] & 31) + (b[0] & 31)
	d_h := (a[0] >> 5) + (b[0] >> 5)
	d[0] = (d_h << 5) + d_l + (~u32(d_l - 31) >> 31)

	for u in 0..<b_len {
		// Carry always fits on 31 bits; we want to keep it in a
		// 32-bit register on 32-bit architectures (on a 64-bit
		// architecture, cast down from 64 to 32 bits means
		// clearing the high bits, which is not free; on a 32-bit
		// architecture, the same operation really means ignoring
		// the top register, which has negative or zero cost).
		f  := b[1 + u]
		cc := u64(0)
		for v in 0..<a_len {
			z := u64(d[1 + u + v]) + _mul31(f, a[1 + v]) + cc
			cc = z >> 31
			d[1 + u + v] = u32(z) & I31_MASK
		}
		d[1 + u + a_len] = u32(cc)
	}
}
