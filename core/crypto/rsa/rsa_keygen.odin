package rsa

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

import bigint "core:crypto/_bigint"
import subtle "core:crypto/_subtle"
import "core:slice"

// This is the big-endian unsigned representation of the product of
// all small primes from 13 to 1481.
@(private="file", rodata)
SMALL_PRIMES := []byte{
	0x2E, 0xAB, 0x92, 0xD1, 0x8B, 0x12, 0x47, 0x31, 0x54, 0x0A,
	0x99, 0x5D, 0x25, 0x5E, 0xE2, 0x14, 0x96, 0x29, 0x1E, 0xB7,
	0x78, 0x70, 0xCC, 0x1F, 0xA5, 0xAB, 0x8D, 0x72, 0x11, 0x37,
	0xFB, 0xD8, 0x1E, 0x3F, 0x5B, 0x34, 0x30, 0x17, 0x8B, 0xE5,
	0x26, 0x28, 0x23, 0xA1, 0x8A, 0xA4, 0x29, 0xEA, 0xFD, 0x9E,
	0x39, 0x60, 0x8A, 0xF3, 0xB5, 0xA6, 0xEB, 0x3F, 0x02, 0xB6,
	0x16, 0xC3, 0x96, 0x9D, 0x38, 0xB0, 0x7D, 0x82, 0x87, 0x0C,
	0xF7, 0xBE, 0x24, 0xE5, 0x5F, 0x41, 0x04, 0x79, 0x76, 0x40,
	0xE7, 0x00, 0x22, 0x7E, 0xB5, 0x85, 0x7F, 0x8D, 0x01, 0x50,
	0xE9, 0xD3, 0x29, 0x42, 0x08, 0xB3, 0x51, 0x40, 0x7B, 0xD7,
	0x8D, 0xCC, 0x10, 0x01, 0x64, 0x59, 0x28, 0xB6, 0x53, 0xF3,
	0x50, 0x4E, 0xB1, 0xF2, 0x58, 0xCD, 0x6E, 0xF5, 0x56, 0x3E,
	0x66, 0x2F, 0xD7, 0x07, 0x7F, 0x52, 0x4C, 0x13, 0x24, 0xDC,
	0x8E, 0x8D, 0xCC, 0xED, 0x77, 0xC4, 0x21, 0xD2, 0xFD, 0x08,
	0xEA, 0xD7, 0xC0, 0x5C, 0x13, 0x82, 0x81, 0x31, 0x2F, 0x2B,
	0x08, 0xE4, 0x80, 0x04, 0x7A, 0x0C, 0x8A, 0x3C, 0xDC, 0x22,
	0xE4, 0x5A, 0x7A, 0xB0, 0x12, 0x5E, 0x4A, 0x76, 0x94, 0x77,
	0xC2, 0x0E, 0x92, 0xBA, 0x8A, 0xA0, 0x1F, 0x14, 0x51, 0x1E,
	0x66, 0x6C, 0x38, 0x03, 0x6C, 0xC7, 0x4A, 0x4B, 0x70, 0x80,
	0xAF, 0xCA, 0x84, 0x51, 0xD8, 0xD2, 0x26, 0x49, 0xF5, 0xA8,
	0x5E, 0x35, 0x4B, 0xAC, 0xCE, 0x29, 0x92, 0x33, 0xB7, 0xA2,
	0x69, 0x7D, 0x0C, 0xE0, 0x9C, 0xDB, 0x04, 0xD6, 0xB4, 0xBC,
	0x39, 0xD7, 0x7F, 0x9E, 0x9D, 0x78, 0x38, 0x7F, 0x51, 0x54,
	0x50, 0x8B, 0x9E, 0x9C, 0x03, 0x6C, 0xF5, 0x9D, 0x2C, 0x74,
	0x57, 0xF0, 0x27, 0x2A, 0xC3, 0x47, 0xCA, 0xB9, 0xD7, 0x5C,
	0xFF, 0xC2, 0xAC, 0x65, 0x4E, 0xBD,
}

// Perform trial division on a candidate prime. This computes
// y = SMALL_PRIMES mod x, then tries to compute y/y mod x. The
// br_i31_moddiv() function will report an error if y is not invertible
// modulo x. Returned value is 1 on success (none of the small primes
// divides x), 0 on error (a non-trivial GCD is obtained).
//
// This function assumes that x is odd.
@(private="file", require_results)
trial_divisions :: proc "contextless" (x, t: []u32) -> u32 {
	y := t
	t_ := t[1+((x[0] + 31) >> 5):]
	x0i := bigint.i31_ninv31(x[1])
	bigint.i31_decode_reduce(y, SMALL_PRIMES, x)
	return bigint.i31_moddiv(y, y, x, x0i, t_)
}

// Perform n rounds of Miller-Rabin on the candidate prime x. This
// function assumes that x = 3 mod 4.
//
// Returned value is 1 on success (all rounds completed successfully),
// 0 otherwise.
@(private="file", require_results)
miller_rabin :: proc(x: []u32, n: int, t: []u32) -> u32 {
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

	tlen := len(t)

	// Compute (x-1)/2 (encoded).
	xm1d2 := slice.reinterpret([]byte, t)
	xm1d2_len := ((x[0] - (x[0] >> 5)) + 7) >> 3
	bigint.i31_encode(xm1d2[:xm1d2_len], x)
	cc: u32
	for u in 0..<xm1d2_len {
		w := u32(xm1d2[u])
		xm1d2[u] = byte((w >> 1) | cc)
		cc = w << 7
	}

	// We used some words of the provided buffer for (x-1)/2.
	xm1d2_len_u32 := (xm1d2_len + 3) >> 2
	t_ := t[xm1d2_len_u32:]
	tlen -= int(xm1d2_len_u32)

	xlen := (x[0] + 31) >> 5
	asize := x[0] - 1 - subtle.eq0(x[0] & 31)
	x0i := bigint.i31_ninv31(x[1])
	for _ in 0..<n {
		// Generate a random base. We don't need the base to be
		// really uniform modulo x, so we just get a random
		// number which is one bit shorter than x.
		a := t_
		a[0] = x[0]
		a[xlen] = 0
		bigint.i31_mkrand(a, asize)

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
		bigint.i62_modpow_opt_as_i31(a, xm1d2[:xm1d2_len], x, x0i, t2[:t2len])

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
@(private="file")
mkprime :: proc(x: []u32, esize: u32, pubexp: u32, t: []u32) {
	x[0] = esize
	l := (esize + 31) >> 5

	for {
		// Generate random bits. We force the two top bits and the
		// two bottom bits to 1.
		bigint.i31_mkrand(x, esize)
		if (esize & 31) == 0 {
			x[l] |= 0x60000000
		} else if (esize & 31) == 1 {
			x[l] |= 0x00000001
			x[l - 1] |= 0x40000000
		} else {
			x[l] |= 0x00000003 << ((esize & 31) - 2)
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
		for u in 0..<l {
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
			if s7 += 1; s7 == 3 {
				s7 = 0
			}

			m11 += w11 << s11
			if s11 += 1; s11 == 10 {
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
		if trial_divisions(x, t) != 1 {
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

		if miller_rabin(x, rounds, t) == 1 {
			return
		}
	}
}

// Let p be a prime (p > 2^33, p = 3 mod 4). Let m = (p-1)/2, provided
// as parameter (with announced bit length equal to that of p). This
// function computes d = 1/e mod p-1 (for an odd integer e). Returned
// value is 1 on success, 0 on error (an error is reported if e is not
// invertible modulo p-1).
//
// The temporary buffer (t) must have room for at least 4 integers of
// the size of p.
@(private="file", require_results)
invert_pubexp :: proc "contextless" (d, m: []u32, e: u32, t: []u32) -> u32 {
	f := t
	t_ := t[1+((m[0] + 31) >> 5):]

	// Compute d = 1/e mod m. Since p = 3 mod 4, m is odd.
	bigint.i31_zero(d, m[0])
	d[1] = 1
	bigint.i31_zero(f, m[0])
	f[1] = e & bigint.I31_MASK
	f[2] = e >> 31
	r := bigint.i31_moddiv(d, f, m, bigint.i31_ninv31(m[1]), t_)

	// We really want d = 1/e mod p-1, with p = 2m. By the CRT,
	// the result is either the d we got, or d + m.
	//
	// Let's write e*d = 1 + k*m, for some integer k. Integers e
	// and m are odd. If d is odd, then e*d is odd, which implies
	// that k must be even; in that case, e*d = 1 + (k/2)*2m, and
	// thus d is already fine. Conversely, if d is even, then k
	// is odd, and we must add m to d in order to get the correct
	// result.
	_ = bigint.i31_add(d, m, 1 - (d[1] & 1))

	return r
}

// Swap two buffers in RAM. They must be disjoint.
@(private="file")
bufswap :: proc "contextless" (b1, b2: []$T) {
	l := len(b1)

	for u in 0..<l {
		b1[u], b2[u] = b2[u], b1[u]
	}
}

@(private, require_results)
keygen_inner :: proc(sk: ^Private_Key, key_size: int, pubexp: u32 = PUBLIC_EXPONENT) -> u32 {
	// We need temporary values for at least 7 integers of the same size
	// as a factor (including header word); more space helps with performance
	// (in modular exponentiations), but we much prefer to remain under
	// 2 kilobytes in total, to save stack space. The macro TEMPS below
	// exceeds 512 (which is a count in 32-bit words) when MODULUS_MAX_SIZE
	// is greater than 4464 (default value is 4096, so the 2-kB limit is
	// maintained unless MODULUS_MAX_SIZE was modified).
	TEMPS :: max(512, ((((7 * ((((MODULUS_MAX_SIZE + 1) >> 1) + 61) / 31))) + 1) >> 1) << 1)

	assert(key_size >= MODULUS_MIN_SIZE && key_size <= MODULUS_MAX_SIZE)
	assert(pubexp >= 3 && (pubexp & 1) == 1)

	t64: [TEMPS >> 1]u64
	t32 := slice.reinterpret([]u32, t64[:])

	esize_p := u32(key_size + 1) >> 1
	esize_q := u32(key_size) - esize_p
	sk._p.v_len = int((esize_p + 7) >> 3)
	sk._q.v_len = int((esize_q + 7) >> 3)
	sk._dp.v_len = sk._p.v_len
	sk._dq.v_len = sk._q.v_len
	sk._iq.v_len = sk._p.v_len

	pk := &sk._pub_key
	pk._n.v_len = (key_size + 7) >> 3
	pk._e = pubexp

	// We now switch to encoded sizes.
	//
	// floor((x * 16913) / (2^19)) is equal to floor(x/31) for all
	// integers x from 0 to 34966; the intermediate product fits on
	// 30 bits, thus we can use MUL31().
	esize_p += u32(bigint._mul31(esize_p, 16913) >> 19)
	esize_q += u32(bigint._mul31(esize_q, 16913) >> 19)
	plen := (esize_p + 31) >> 5
	qlen := (esize_q + 31) >> 5
	p := t32
	q := p[1 + plen:]
	t := q[1 + qlen:]
	tlen := ((size_of(t64)) / size_of(u32)) - (2 + plen + qlen)

	// When looking for primes p and q, we temporarily divide
	// candidates by 2, in order to compute the inverse of the
	// public exponent.

	for {
		mkprime(p, esize_p, pubexp, t[:tlen])
		bigint.i31_rshift(p, 1)
		if invert_pubexp(t, p, pubexp, t[1 + plen:]) == 1 {
			_= bigint.i31_add(p, p, 1)
			p[1] |= 1
			bigint.i31_encode(sk._p.v[:sk._p.v_len], p)
			bigint.i31_encode(sk._dp.v[:sk._dp.v_len], t)
			break
		}
	}

	for {
		mkprime(q, esize_q, pubexp, t[:tlen])
		bigint.i31_rshift(q, 1)
		if invert_pubexp(t, q, pubexp, t[1 + qlen:]) == 1 {
			_= bigint.i31_add(q, q, 1)
			q[1] |= 1
			bigint.i31_encode(sk._q.v[:sk._q.v_len], q)
			bigint.i31_encode(sk._dq.v[:sk._dq.v_len], t)
			break
		}
	}

	// If p and q have the same size, then it is possible that q > p
	// (when the target modulus size is odd, we generate p with a
	// greater bit length than q). If q > p, we want to swap p and q
	// (and also dp and dq) for two reasons:
	//  - The final step below (inversion of q modulo p) is easier if
	//    p > q.
	//  - While BearSSL's RSA code is perfectly happy with RSA keys such
	//    that p < q, some other implementations have restrictions and
	//    require p > q.
	//
	// Note that we can do a simple non-constant-time swap here,
	// because the only information we leak here is that we insist on
	// returning p and q such that p > q, which is not a secret.
	if esize_p == esize_q && bigint.i31_sub(p, q, 0) == 1 {
		bufswap(p[:1+plen], q)
		bufswap(sk._p.v[:], sk._q.v[:])
		bufswap(sk._dp.v[:], sk._dq.v[:])
	}

	// We have produced p, q, dp and dq. We can now compute iq = 1/d mod p.
	//
	// We ensured that p >= q, so this is just a matter of updating the
	// header word for q (and possibly adding an extra word).
	//
	// Theoretically, the call below may fail, in case we were
	// extraordinarily unlucky, and p = q. Another failure case is if
	// Miller-Rabin failed us _twice_, and p and q are non-prime and
	// have a factor is common. We report the error mostly because it
	// is cheap and we can, but in practice this never happens (or, at
	// least, it happens way less often than hardware glitches).
	q[0] = p[0]
	if plen > qlen {
		q[plen] = 0
		t = t[1:]
		tlen -= 1
	}
	bigint.i31_zero(t, p[0])
	t[1] = 1
	r := bigint.i31_moddiv(t, q, p, bigint.i31_ninv31(p[1]), t[1 + plen:])
	bigint.i31_encode(sk._iq.v[:sk._iq.v_len], t)

	// Compute the public modulus too.
	bigint.i31_zero(t, p[0])
	bigint.i31_mulacc(t, p, q)
	bigint.i31_encode(pk._n.v[:pk._n.v_len], t)

	return r
}
