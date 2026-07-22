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

import subtle "core:crypto/_subtle"
import "core:math/big"
import "core:slice"

// Perform trial divisions on a candidate prime.  We opt for the simple
// route and "just" compute a series of trial divisions.
//
// Returned value is 1 on success (none of the small primes
// divides x), 0 on error (a non-trivial GCD is obtained).
@(private="file", require_results)
trial_divisions :: proc "contextless" (x: []u32) -> u32 {
	for factor in big._private_prime_table {
		if factor <= 11 {
			continue
		}
		if i31_rem(x, u32(factor)) == 0 {
			return 0
		}
	}

	return 1
}

// Perform n rounds of Miller-Rabin on the candidate prime x. This
// function assumes that x = 3 mod 4.
//
// WARNING: t MUST be 64-bit aligned, and be large enough such that
// it can hold 4 encoded integers that have the same number of limbs
// as x.
//
// Returned value is 1 on success (all rounds completed successfully),
// 0 otherwise.
@(private="file", require_results)
i62_miller_rabin :: proc(x: []u32, n: int, t: []u32) -> u32 {
	// Since x = 3 mod 4, the Miller-Rabin test is simple:
	//  - get a random base a (such that 1 < a < x-1)
	//  - compute z = a^((x-1)/2) mod x
	//  - if z != 1 and z != x-1, the number x is composite
	//
	// We generate bases 'a' randomly with a size which is
	// one bit less than x, which ensures that a < x-1. It
	// is not useful to verify that a > 1 because the probability
	// that we get a value a equal to 0 or 1 is much smaller
	// than the probability of our Miller-Rabin tests not to
	// detect a composite, which is already quite smaller than the
	// probability of the hardware misbehaving and return a
	// composite integer because of some glitch (e.g. bad RAM
	// or ill-timed cosmic ray).

	// Compute (x-1)/2 (encoded).
	xm1d2 := slice.reinterpret([]byte, t)
	xm1d2_len := ((x[0] - (x[0] >> 5)) + 7) >> 3
	i31_encode(xm1d2[:xm1d2_len], x)
	cc: u32
	for u in 0..<xm1d2_len {
		w := u32(xm1d2[u])
		xm1d2[u] = byte((w >> 1) | cc)
		cc = w << 7
	}

	// We used some words of the provided buffer for (x-1)/2.
	xm1d2_len_u32 := (xm1d2_len + 3) >> 2
	t_ := t[xm1d2_len_u32:]
	tlen := len(t_)

	xlen := (x[0] + 31) >> 5
	asize := x[0] - 1 - subtle.eq0(x[0] & 31)
	x0i := i31_ninv31(x[1])
	for _ in 0..<n {
		// Generate a random base. We don't need the base to be
		// really uniform modulo x, so we just get a random
		// number which is one bit shorter than x.
		a := t_
		a[0] = x[0]
		a[xlen] = 0
		i31_mkrand(a, asize)

		// Compute a^((x-1)/2) mod x. We assume here that the
		// function will not fail (the temporary array is large
		// enough).
		t2 := t_[1 + xlen:]
		t2len := tlen - 1 - int(xlen)
		if (t2len & 1) != 0 {
			// Since the source array is 64-bit aligned and
			// has an even number of elements (TEMPS), we
			// can use the parity of the remaining length to
			// detect and adjust alignment.
			t2 = t2[1:]
			t2len -= 1
		}
		i62_modpow_opt_as_i31(a, xm1d2[:xm1d2_len], x, x0i, t2[:t2len])

		// We must obtain either 1 or x-1. Note that x is odd,
		// hence x-1 differs from x only in its low word (no
		// carry).
		eq1 := a[1] ~ 1
		eqm1 := a[1] ~ (x[1] - 1)
		for u in 2..=xlen {
			eq1 |= a[u]
			eqm1 |= a[u] ~ x[u]
		}

		if ((subtle.eq0(eq1) | subtle.eq0(eqm1)) == 0) {
			return 0
		}
	}

	return 1
}
// Create a random prime of the provided size. 'esize' is the _encoded_
// bit length. The two top bits and the two bottom bits are set to 1.
i62_mkprime :: proc(x: []u32, esize: u32, pubexp: u32, t: []u32) {
	x[0] = esize
	_len := (esize + 31) >> 5

	for {
		// Generate random bits. We force the two top bits and the
		// two bottom bits to 1.
		i31_mkrand(x, esize)
		if (esize & 31) == 0 {
			x[_len] |= 0x60000000
		} else if (esize & 31) == 1 {
			x[_len] |= 0x00000001
			x[_len - 1] |= 0x40000000
		} else {
			x[_len] |= 0x00000003 << ((esize & 31) - 2)
		}
		x[1] |= 0x00000003

		// Trial division with low primes (3, 5, 7 and 11). We
		// use the following properties:
		//
		//   2^2 = 1 mod 3
		//   2^4 = 1 mod 5
		//   2^3 = 1 mod 7
		//   2^10 = 1 mod 11
		m3, m5, m7, m11: u32
		s7, s11: uint
		for u in 0..<_len {
			w := x[1 + u]
			w3 := (w & 0xFFFF) + (w >> 16)     // max: 98302
			w5 := (w & 0xFFFF) + (w >> 16)     // max: 98302
			w7 := (w & 0x7FFF) + (w >> 15)     // max: 98302
			w11 := (w & 0xFFFFF) + (w >> 20)   // max: 1050622

			m3 += w3 << (u & 1)
			m3 = (m3 & 0xFF) + (m3 >> 8)       // max: 1025

			m5 += w5 << ((4 - u) & 3)
			m5 = (m5 & 0xFFF) + (m5 >> 12)     // max: 4479

			m7 += w7 << s7
			m7 = (m7 & 0x1FF) + (m7 >> 9)      // max: 1280
			s7 += 1
			if s7 == 3 {
				s7 = 0
			}

			m11 += w11 << s11
			s11 += 1
			if s11 == 10 {
				s11 = 0
			}
			m11 = (m11 & 0x3FF) + (m11 >> 10)  // max: 526847
		}

		m3 = (m3 & 0x3F) + (m3 >> 6)       // max: 78
		m3 = (m3 & 0x0F) + (m3 >> 4)       // max: 18
		m3 = ((m3 * 43) >> 5) & 3

		m5 = (m5 & 0xFF) + (m5 >> 8)       // max: 271
		m5 = (m5 & 0x0F) + (m5 >> 4)       // max: 31
		m5 -= 20 & -subtle.gt(m5, 19)
		m5 -= 10 & -subtle.gt(m5, 9)
		m5 -= 5 & -subtle.gt(m5, 4)

		m7 = (m7 & 0x3F) + (m7 >> 6)       // max: 82
		m7 = (m7 & 0x07) + (m7 >> 3)       // max: 16
		m7 = ((m7 * 147) >> 7) & 7

		// 2^5 = 32 = -1 mod 11.
		m11 = (m11 & 0x3FF) + (m11 >> 10)       // max: 1536
		m11 = (m11 & 0x3FF) + (m11 >> 10)       // max: 1023
		m11 = (m11 & 0x1F) + 33 - (m11 >> 5)    // max: 64
		m11 -= 44 & -subtle.gt(m11, 43)
		m11 -= 22 & -subtle.gt(m11, 21)
		m11 -= 11 & -subtle.gt(m11, 10)

		// If any of these modulo is 0, then the candidate is
		// not prime. Also, if pubexp is 3, 5, 7 or 11, and the
		// corresponding modulus is 1, then the candidate must
		// be rejected, because we need e to be invertible
		// modulo p-1. We can use simple comparisons here
		// because they won't leak information on a candidate
		// that we keep, only on one that we reject (and is thus
		// not secret).
		if m3 == 0 || m5 == 0 || m7 == 0 || m11 == 0 {
			continue
		}
		if (pubexp == 3 && m3 == 1) || (pubexp == 5 && m5 == 1) || (pubexp == 7 && m7 == 1) || (pubexp == 11 && m11 == 1) {
			continue
		}

		// More trial divisions.
		if trial_divisions(x) == 0 {
			continue
		}

		// Miller-Rabin algorithm. Since we selected a random
		// integer, not a maliciously crafted integer, we can use
		// relatively few rounds to lower the risk of a false
		// positive (i.e. declaring prime a non-prime) under
		// 2^(-80). It is not useful to lower the probability much
		// below that, since that would be substantially below
		// the probability of the hardware misbehaving. Sufficient
		// numbers of rounds are extracted from the Handbook of
		// Applied Cryptography, note 4.49 (page 149).
		//
		// Since we work on the encoded size (esize), we need to
		// compare with encoded thresholds.
		rounds: int
		switch {
		case esize < 309:
			rounds = 12
		case esize < 464:
			rounds = 9
		case esize < 670:
			rounds = 6
		case esize < 877:
			rounds = 4
		case esize < 1341:
			rounds = 3
		case:
			rounds = 2
		}

		if i62_miller_rabin(x, rounds, t) == 1 {
			return
		}
	}
}
