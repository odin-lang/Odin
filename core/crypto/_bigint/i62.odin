package _bigint

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

import "base:intrinsics"
import "core:math/bits"
import subtle "core:crypto/_subtle"
import "core:slice"

@(private="file")
I62_MASK :: 0x3fff_ffff_ffff_ffff

// Compute x*y+v1+v2. Operands are 64-bit, and result is 128-bit, with
// high word in "hi" and low word in "lo".
@(private="file", require_results)
_fma1 :: #force_inline proc "contextless" (x, y, v1, v2: u64) -> (hi, lo: u64) {
	hi, lo = bits.mul_u64(x, y)

	carry: u64
	lo, carry = bits.add_u64(lo, v1, 0)
	hi += carry

	lo, carry = bits.add_u64(lo, v2, 0)
	hi += carry

	return
}

// Compute x1*y1+x2*y2+v1+v2. Operands are 64-bit, and result is 128-bit,
// with high word in "hi" and low word in "lo".
//
// Callers should ensure that the two inner products, and the v1 and v2
// operands, are multiple of 4 (this is not used by this specific definition
// but may help other implementations).
@(private="file", require_results)
_fma2 :: #force_inline proc "contextless" (x1, y1, x2, y2, v1, v2: u64) -> (hi, lo: u64) {
	hi_1, lo_1 := bits.mul_u64(x1, y1)
	hi_2, lo_2 := bits.mul_u64(x2, y2)

	carry: u64
	lo, carry = bits.add_u64(lo_1, lo_2, 0)
	hi, _ = bits.add_u64(hi_1, hi_2, carry)

	lo, carry = bits.add_u64(lo, v1, 0)
	hi += carry

	lo, carry = bits.add_u64(lo, v2, 0)
	hi += carry

	return
}

@(private="file", require_results)
_mul62_lo :: #force_inline proc "contextless" (x, y: u64) -> u64 {
	return (x * y) & I62_MASK
}

// Subtract b from a, and return the final carry. If 'ctl32' is 0, then
// a[] is kept unmodified, but the final carry is still computed and
// returned.
@(private="file", require_results)
_i62_sub :: proc "contextless" (a, b: []u64, num: int, ctl32: u32) -> u32 {
	cc: u64

	ctl := -ctl32
	mask := u64(ctl) | (u64(ctl) << 32)
	for u in 0..<num {
		aw := a[u]
		bw := b[u]
		dw := aw - bw - cc
		cc = dw >> 63
		dw &= I62_MASK
		a[u] = aw ~ (mask & (dw ~ aw))
	}

	return u32(cc)
}

// Montgomery multiplication, over arrays of 62-bit values. The
// destination array (d) must be distinct from the other operands
// (x, y and m). All arrays are in little-endian format (least
// significant word comes first) over 'num' words.
@(private="file")
_i62_montymul :: proc "contextless" (d, x, y, m: []u64, num: int, m0i: u64) {
	dh: u64

	num4 := 1 + u64((num - 1) & ~int(3))
	intrinsics.mem_zero(raw_data(d), num * size_of(u64))
	for u in 0..<num {
		xu := x[u] << 2
		f := _mul62_lo(d[0] + _mul62_lo(x[u], y[0]), m0i) << 2

		hi, lo := _fma2(xu, y[0], f, m[0], d[0] << 2, 0)
		r := hi

		v: int
		for v = 1; v < int(num4); v += 4 {
			hi, lo = _fma2(xu, y[v + 0], f, m[v + 0], d[v + 0] << 2, r << 2)
			r = hi + (r >> 62)
			d[v - 1] = lo >> 2
			hi, lo = _fma2(xu, y[v + 1], f, m[v + 1], d[v + 1] << 2, r << 2)
			r = hi + (r >> 62)
			d[v + 0] = lo >> 2
			hi, lo = _fma2(xu, y[v + 2], f, m[v + 2], d[v + 2] << 2, r << 2)
			r = hi + (r >> 62)
			d[v + 1] = lo >> 2
			hi, lo = _fma2(xu, y[v + 3], f, m[v + 3], d[v + 3] << 2, r << 2)
			r = hi + (r >> 62)
			d[v + 2] = lo >> 2
		}
		for ; v < num; v += 1 {
			hi, lo = _fma2(xu, y[v], f, m[v], d[v] << 2, r << 2)
			r = hi + (r >> 62)
			d[v - 1] = lo >> 2
		}

		zh := dh + r
		d[num - 1] = zh & I62_MASK
		dh = zh >> 62
	}
	_ = _i62_sub(d, m, num, u32(dh) | subtle.not(_i62_sub(d, m, num, 0)))
}

// Conversion back from Montgomery representation.
@(private="file")
_i62_frommonty :: proc "contextless" (x, m: []u64, num: int, m0i: u64) {
	for _ in 0..<num {
		cc: u64
		f := _mul62_lo(x[0], m0i) << 2
		for v in 0..<num {
			hi, lo := _fma1(f, m[v], x[v] << 2, cc)
			cc = hi << 2
			if (v != 0) {
				x[v - 1] = lo >> 2
			}
		}
		x[num - 1] = cc >> 2
	}
	_ = _i62_sub(x, m, num, subtle.not(_i62_sub(x, m, num, 0)))
}

// Variant of i31_modpow_opt() that internally uses 64x64->128
// multiplications. It expects the same parameters as i31_modpow_opt(),
// except that the temporaries should be 64-bit integers, not 32-bit
// integers.
i62_modpow_opt :: proc "contextless" (x31: []u32, e: []byte, m31: []u32, m0i31: u32, tmp: []u64) -> u32 {
	twlen := len(tmp)

	// Get modulus size, in words.
	mw31num := int((m31[0] + 31) >> 5)
	mw62num := int((mw31num + 1) >> 1)

	// In order to apply this function, we must have enough room to
	// copy the operand and modulus into the temporary array, along
	// with at least two temporaries. If there is not enough room,
	// switch to br_i31_modpow(). We also use br_i31_modpow() if the
	// modulus length is not at least four words (94 bits or more).
	if mw31num < 4 || mw62num << 2 > twlen {
		// We assume here that we can split an aligned uint64_t
		// into two properly aligned uint32_t. Since both types
		// are supposed to have an exact width with no padding,
		// then this property must hold.

		txlen := mw31num + 1
		if twlen < txlen {
			return 0
		}

		tmp_as_u32s := slice.reinterpret([]u32, tmp)
		t1, t2 := tmp_as_u32s[:txlen], tmp_as_u32s[txlen:]

		i31_modpow(x31, e, m31, m0i31, t1, t2)

		return 1
	}

	// Convert x to Montgomery representation: this means that
	// we replace x with x*2^z mod m, where z is the smallest multiple
	// of the word size such that 2^z >= m. We want to reuse the 31-bit
	// functions here (for constant-time operation), but we need z
	// for a 62-bit word size.
	for _ in 0..<mw62num {
		i31_muladd_small(x31, 0, m31)
		i31_muladd_small(x31, 0, m31)
	}

	// Assemble operands into arrays of 62-bit words. Note that
	// all the arrays of 62-bit words that we will handle here
	// are without any leading size word.
	//
	// We also adjust tmp and twlen to account for the words used
	// for these extra arrays.
	m := tmp[:mw62num]
	x := tmp[mw62num:mw62num*2]
	tmp_ := tmp[mw62num << 1:]
	twlen -= mw62num << 1
	for u := 0; u < mw31num; u += 2 {
		v := u >> 1
		if u + 1 == mw31num {
			m[v] = u64(m31[u + 1])
			x[v] = u64(x31[u + 1])
		} else {
			m[v] = u64(m31[u + 1]) + (u64(m31[u + 2]) << 31)
			x[v] = u64(x31[u + 1]) + (u64(x31[u + 2]) << 31)
		}
	}

	// Compute window size. We support windows up to 5 bits; for a
	// window of size k bits, we need 2^k+1 temporaries (for k = 1,
	// we use special code that uses only 2 temporaries).
	win_len: int
	for win_len = 5; win_len > 1; win_len -= 1 {
		if (1 << uint(win_len) + 1) * mw62num <= twlen {
			break
		}
	}

	t1 := tmp_[:mw62num]
	t2 := tmp_[mw62num:]

	// Compute m0i, which is equal to -(1/m0) mod 2^62. We were
	// provided with m0i31, which already fulfills this property
	// modulo 2^31; the single expression below is then sufficient.
	m0i := u64(m0i31)
	m0i = _mul62_lo(m0i, 2 + _mul62_lo(m0i, m[0]))

	// Compute window contents. If the window has size one bit only,
	// then t2 is set to x; otherwise, t2[0] is left untouched, and
	// t2[k] is set to x^k (for k >= 1).
	if win_len == 1 {
		copy(t2, x)
	} else {
		copy(t2[mw62num:], x)

		base := t2[mw62num:]
		for u := 2; u < 1 << uint(win_len); u += 1 {
			_i62_montymul(base[mw62num:], base, x, m, mw62num, m0i)
			base = base[mw62num:]
		}
	}

	// Set x to 1, in Montgomery representation. We again use the
	// 31-bit code.
	i31_zero(x31, m31[0])
	x31[(m31[0] + 31) >> 5] = 1
	i31_muladd_small(x31, 0, m31)
	if mw31num & 1 != 0 {
		i31_muladd_small(x31, 0, m31)
	}
	for u := 0; u < mw31num; u+= 2 {
		v := u >> 1
		if u + 1 == mw31num {
			x[v] = u64(x31[u + 1])
		} else {
			x[v] = u64(x31[u + 1]) + (u64(x31[u + 2]) << 31)
		}
	}

	e_, e_len := e, len(e)
	// We process bits from most to least significant. At each
	// loop iteration, we have acc_len bits in acc.
	acc: u32
	acc_len: uint
	for acc_len > 0 || e_len > 0 {
		// Get the next bits.
		k := uint(win_len)
		if acc_len < uint(win_len) {
			if e_len > 0 {
				acc = (acc << 8) | u32(e_[0])
				e_ = e_[1:]
				e_len -= 1
				acc_len += 8
			} else {
				k = acc_len
			}
		}
		bits := (acc >> (acc_len - k)) & ((u32(1) << k) - 1)
		acc_len -= k

		// We could get exactly k bits. Compute k squarings.
		for _ in 0..<k {
			_i62_montymul(t1, x, x, m, mw62num, m0i)
			copy(x, t1)
		}

		// Window lookup: we want to set t2 to the window
		// lookup value, assuming the bits are non-zero. If
		// the window length is 1 bit only, then t2 is
		// already set; otherwise, we do a constant-time lookup.
		if win_len > 1 {
			intrinsics.mem_zero(raw_data(t2), mw62num * size_of(u64))

			base := t2[mw62num:]
			for u := u32(1); u < u32(1) << k; u += 1 {
				mask := -u64(subtle.eq(u, bits))
				for v in 0..<mw62num {
					t2[v] |= mask & base[v]
				}
				base = base[mw62num:]
			}
		}

		// Multiply with the looked-up value. We keep the product
		// only if the exponent bits are not all-zero.
		_i62_montymul(t1, x, t2, m, mw62num, m0i)
		mask1 := -u64(subtle.eq(bits, 0))
		mask2 := ~mask1
		for u in 0..<mw62num {
			x[u] = (mask1 & x[u]) | (mask2 & t1[u])
		}
	}

	// Convert back from Montgomery representation.
	_i62_frommonty(x, m, mw62num, m0i)

	// Convert result into 31-bit words.
	for u := 0; u < mw31num; u += 2 {
		zw := u64(x[u >> 1])
		x31[u + 1] = u32(zw) & I31_MASK
		if u + 1 < mw31num {
			x31[u + 2] = u32(zw >> 31)
		}
	}

	return 1
}

// Wrapper for i62_modpow_opt() that uses the same type as
// i31_modpow_opt(); however, it requires its 'tmp' argument to the
// 64-bit aligned.
i62_modpow_opt_as_i31 :: proc "contextless" (x31: []u32, e: []byte, m31: []u32, m0i31: u32, tmp: []u32) -> u32 {
	// As documented, this function expects the 'tmp' argument to be
	// 64-bit aligned. This is OK since this function is internal (it
	// is not part of BearSSL's public API).
	ensure_contextless(uintptr(raw_data(tmp)) & 7 == 0)
	ensure_contextless(len(tmp) & 1 == 0) // Length MUST be even.

	tmp_as_u64s := slice.reinterpret([]u64, tmp)

	return i62_modpow_opt(x31, e, m31, m0i31, tmp_as_u64s)
}
