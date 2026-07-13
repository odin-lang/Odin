package rsa

// Copyright (c) 2018 Thomas Pornin <pornin@bolet.org>
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

import "core:crypto"
import bigint "core:crypto/_bigint"
import subtle "core:crypto/_subtle"
import "core:slice"

// Swap two buffers in RAM. They must be disjoint.
@(private="file")
bufswap_u32 :: proc "contextless" (b1, b2: []u32) {
	l := len(b1)

	for u in 0..<l {
		b1[u], b2[u] = b2[u], b1[u]
	}
}

@(private, require_results)
keygen_inner :: proc(sk: ^Private_Key, key_size: int) -> u32 {
	// We need temporary values for at least 7 integers of the same size
	// as a factor (including header word); more space helps with performance
	// (in modular exponentiations), but we much prefer to remain under
	// 2 kilobytes in total, to save stack space. The macro TEMPS below
	// exceeds 512 (which is a count in 32-bit words) when MODULUS_MAX_SIZE
	// is greater than 4464 (default value is 4096, so the 2-kB limit is
	// maintained unless MODULUS_MAX_SIZE was modified).
	TEMPS :: max(512, ((((7 * ((((MODULUS_MAX_SIZE + 1) >> 1) + 61) / 31))) + 1) >> 1) << 1)

	assert(key_size >= MODULUS_MIN_SIZE && key_size <= MODULUS_MAX_SIZE)

	t64: [TEMPS >> 1]u64
	t32 := slice.reinterpret([]u32, t64[:])
	defer crypto.zero_explicit(&t64, size_of(t64))

	esize_p := u32(key_size + 1) >> 1
	esize_q := u32(key_size) - esize_p
	sk._p.v_len = int((esize_p + 7) >> 3)
	sk._q.v_len = int((esize_q + 7) >> 3)
	sk._dp.v_len = sk._p.v_len
	sk._dq.v_len = sk._q.v_len
	sk._iq.v_len = sk._p.v_len

	pk := &sk._pub_key
	pk._n.v_len = (key_size + 7) >> 3
	pk._e = PUBLIC_EXPONENT

	sk._d.v_len = pk._n.v_len // Private exponent length is that of the modulus.

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

	// Since we use a prime exponent, when searching for candidate primes,
	// checking if `GCD(e, prime - 1) = 1` is a simple matter of euclidian
	// division.
	for {
		bigint.i62_mkprime(p, esize_p, PUBLIC_EXPONENT, t)
		p[1] -= 1
		if bigint.i31_rem(p, PUBLIC_EXPONENT) != 0 {
			p[1] += 1
			break
		}
	}

	for {
		bigint.i62_mkprime(q, esize_q, PUBLIC_EXPONENT, t)
		q[1] -= 1
		if bigint.i31_rem(q, PUBLIC_EXPONENT) != 0 {
			q[1] += 1
			break
		}
	}

	// If p and q have the same size, then it is possible that q > p
	// (when the target modulus size is odd, we generate p with a
	// greater bit length than q). If q > p, we want to swap p and q
	// for two reasons:
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
		bufswap_u32(p[:1+plen], q)
	}

	sk_p, sk_q := factor_bytes(&sk._p), factor_bytes(&sk._q)
	bigint.i31_encode(sk_p, p)
	bigint.i31_encode(sk_q, q)
	// The odds of this happening are infinitesimally small, however
	// checking for it is cheap.
	if crypto.compare_constant_time(sk_p, sk_q) == 1 {
		return 0
	}

	// Compute the public modulus too.
	bigint.i31_zero(t, p[0])
	bigint.i31_mulacc(t, p, q)
	bigint.i31_encode(modulus_bytes(&pk._n), t)

	// Compute the private exponent.
	//
	// Computing p - 1 and q - 1 this way is safe as p and q
	// are guaranteed to be odd, thus the LSB will always be
	// set.
	p[1], q[1] = p[1] - 1, q[1] - 1 // p = p - 1, q = q - 1
	if compute_privexp(sk, p, q, pk._e, t) != 1 {
		return 0
	}

	// Compute `d % (p - 1)`.
	d_mod := t[:1+plen]
	bigint.i31_decode_reduce(d_mod, modulus_bytes(&sk._d), p)
	bigint.i31_encode(factor_bytes(&sk._dp), d_mod)

	// Compute `d % (q - 1)`.
	bigint.i31_decode_reduce(d_mod, modulus_bytes(&sk._d), q)
	bigint.i31_encode(factor_bytes(&sk._dq), d_mod)

	// Compute `q^(-1) mod p`.
	p[1], q[1] = p[1] + 1, q[1] + 1 // Restore p, q.
	return compute_qinv(sk, p, q, plen, t)
}

@(private="file")
compute_qinv :: proc "contextless" (sk: ^Private_Key, p, q: []u32, plen: u32, t: []u32) -> u32 {
	// Per Fermat's Little Theorem, `q^(-1) mod p = q^(p-2) mod p`.
	//
	// Note: p is guaranteed to be odd as it is a large prime.

	// Compute and encode `p-2`.
	p_minus_two := t[:1+plen]
	copy(p_minus_two, p[:1+plen])
	two := t[1+plen:] // Temporarily use this for 2.
	bigint.i31_zero(two, p[0])
	bigint.i31_decode(two, []byte{2})
	_ = bigint.i31_sub(p_minus_two, two, 1)
	iq := factor_bytes(&sk._iq) // Temporarily use this for p - 2.
	bigint.i31_encode(iq, p_minus_two)

	// Enforce 64-bit alignment.
	t_ := t
	if len(t_) & 1 != 0 {
		t_ = t_[1:]
	}

	m0i := bigint.i31_ninv31(p[1])
	ret := bigint.i62_modpow_opt_as_i31(q, iq, p, m0i, t)
	if ret != 0 {
		bigint.i31_encode(iq, q)
	}

	return ret
}

@(private="file")
compute_privexp :: proc "contextless" (sk: ^Private_Key, p_minus_one, q_minus_one: []u32, e: u32, tmp: []u32) -> u32 {
	// Compute phi = (p-1)*(q-1).  The mulacc function sets the announced
	// bit length of t to be the sum of the announced bit lengths of
	// p-1 and q-1, which is usually exact but may overshoot by one 1
	// bit in some cases; we readjust it to its true length.
	phi := tmp
	bigint.i31_zero(phi, p_minus_one[0])
	bigint.i31_mulacc(phi, p_minus_one, q_minus_one)
	_len := (phi[0] + 31) >> 5
	phi[0] = bigint.i31_bit_length(phi[1:1+_len])
	_len = (phi[0] + 31) >> 5

	// Divide phi by public exponent e. The final remainder r must be
	// non-zero (otherwise, the key is invalid). The quotient is k,
	// which we write over phi, since we don't need phi after that.
	r: u32
	for u := _len; u >= 1; u -= 1 {
		// Upon entry, r < e, and phi[u] < 2^31; hence,
		// hi:lo < e*2^31. Thus, the produced word k[u]
		// must be lower than 2^31, and the new remainder r
		// is lower than e.
		hi := r >> 1
		lo := (r << 31) + phi[u]
		phi[u], r = bigint.div_rem_u32(hi, lo, e)
	}
	if r == 0 {
		return 0
	}
	k := phi

	// Compute u and v such that u*e - v*r = GCD(e,r). We use
	// a binary GCD algorithm, with 6 extra integers a, b,
	// u0, u1, v0 and v1. Initial values are:
	//   a = e    u0 = 1   v0 = 0
	//   b = r    u1 = r   v1 = e-1
	// The following invariants are maintained:
	//   a = u0*e - v0*r
	//   b = u1*e - v1*r
	//   0 < a <= e
	//   0 < b <= r
	//   0 <= u0 <= r
	//   0 <= v0 <= e
	//   0 <= u1 <= r
	//   0 <= v1 <= e
	//
	// At each iteration, we reduce either a or b by one bit, and
	// adjust u0, u1, v0 and v1 to maintain the invariants:
	//  - if a is even, then a <- a/2
	//  - otherwise, if b is even, then b <- b/2
	//  - otherwise, if a > b, then a <- (a-b)/2
	//  - otherwise, if b > a, then b <- (b-a)/2
	// Algorithm stops when a = b. At that point, the common value
	// is the GCD of e and r; it must be 1 (otherwise, the private
	// key or public exponent is not valid). The (u0,v0) or (u1,v1)
	// pairs are the solution we are looking for.
	//
	// Since either a or b is reduced by at least 1 bit at each
	// iteration, 62 iterations are enough to reach the end
	// condition.
	//
	// To maintain the invariants, we must compute the same operations
	// on the u* and v* values that we do on a and b:
	//  - When a is divided by 2, u0 and v0 must be divided by 2.
	//  - When b is divided by 2, u1 and v1 must be divided by 2.
	//  - When b is subtracted from a, u1 and v1 are subtracted from
	//    u0 and v0, respectively.
	//  - When a is subtracted from b, u0 and v0 are subtracted from
	//    u1 and v1, respectively.
	//
	// However, we want to keep the u* and v* values in their proper
	// ranges. The following remarks apply:
	//
	//  - When a is divided by 2, then a is even. Therefore:
	//
	//     * If r is odd, then u0 and v0 must have the same parity;
	//       if they are both odd, then adding r to u0 and e to v0
	//       makes them both even, and the division by 2 brings them
	//       back to the proper range.
	//
	//     * If r is even, then u0 must be even; if v0 is odd, then
	//       adding r to u0 and e to v0 makes them both even, and the
	//       division by 2 brings them back to the proper range.
	//
	//    Thus, all we need to do is to look at the parity of v0,
	//    and add (r,e) to (u0,v0) when v0 is odd. In order to avoid
	//    a 32-bit overflow, we can add ((r+1)/2,(e/2)+1) after the
	//    division (r+1 does not overflow since r < e; and (e/2)+1
	//    is equal to (e+1)/2 since e is odd).
	//
	//  - When we subtract b from a, three cases may occur:
	//
	//     * u1 <= u0 and v1 <= v0: just do the subtractions
	//
	//     * u1 > u0 and v1 > v0: compute:
	//         (u0, v0) <- (u0 + r - u1, v0 + e - v1)
	//
	//     * u1 <= u0 and v1 > v0: compute:
	//         (u0, v0) <- (u0 + r - u1, v0 + e - v1)
	//
	//    The fourth case (u1 > u0 and v1 <= v0) is not possible
	//    because it would contradict "b < a" (which is the reason
	//    why we subtract b from a).
	//
	//    The tricky case is the third one: from the equations, it
	//    seems that u0 may go out of range. However, the invariants
	//    and ranges of other values imply that, in that case, the
	//    new u0 does not actually exceed the range.
	//
	//    We can thus handle the subtraction by adding (r,e) based
	//    solely on the comparison between v0 and v1.
	a, b: u32 = e, r
	u0, v0: u32 = 1, 0
	u1, v1: u32 = r, e - 1
	hr, he := (r + 1) >> 1, (e >> 1) + 1
	for _ in 0..<62 {
		oa := a & 1                  // 1 if a is odd
		ob := b & 1                  // 1 if b is odd
		agtb := subtle.gt(a, b)      // 1 if a > b
		bgta := subtle.gt(b, a)      // 1 if b > a

		sab := oa & ob & agtb        // 1 if a <- a-b
		sba := oa & ob & bgta        // 1 if b <- b-a

		// a <- a-b, u0 <- u0-u1, v0 <- v0-v1
		ctl := subtle.gt(v1, v0)
		a -= b & -sab
		u0 -= (u1 - (r & -ctl)) & -sab
		v0 -= (v1 - (e & -ctl)) & -sab

		// b <- b-a, u1 <- u1-u0 mod r, v1 <- v1-v0 mod e
		ctl = subtle.gt(v0, v1)
		b -= a & -sba
		u1 -= (u0 - (r & -ctl)) & -sba
		v1 -= (v0 - (e & -ctl)) & -sba

		da := subtle.not(oa) | sab          // 1 if a <- a/2
		db := (oa & subtle.not(ob)) | sba   // 1 if b <- b/2

		// a <- a/2, u0 <- u0/2, v0 <- v0/2
		ctl = v0 & 1
		a ~= (a ~ (a >> 1)) & -da
		u0 ~= (u0 ~ ((u0 >> 1) + (hr & -ctl))) & -da
		v0 ~= (v0 ~ ((v0 >> 1) + (he & -ctl))) & -da

		// b <- b/2, u1 <- u1/2 mod r, v1 <- v1/2 mod e
		ctl = v1 & 1
		b ~= (b ~ (b >> 1)) & -db
		u1 ~= (u1 ~ ((u1 >> 1) + (hr & -ctl))) & -db
		v1 ~= (v1 ~ ((v1 >> 1) + (he & -ctl))) & -db
	}

	// Check that the GCD is indeed 1. If not, then the key is invalid
	// (and there's no harm in leaking that piece of information).
	if (a != 1) {
		return 0
	}

	// Now we have u0*e - v0*r = 1. Let's compute the result as:
	//   d = u0 + v0*k
	// We still have k in the tmp[] array, and its announced bit
	// length is that of phi.
	m := k[1+_len:]
	m[0] = (1 << 5) + 1  // bit length is 32 bits, encoded
	m[1] = v0 & bigint.I31_MASK
	m[2] = v0 >> 31
	z := m[3:]
	bigint.i31_zero(z, k[0])
	z[1] = u0 & bigint.I31_MASK
	z[2] = u0 >> 31
	bigint.i31_mulacc(z, k, m)

	// Encode the result.
	bigint.i31_encode(modulus_bytes(&sk._d), z)

	return 1
}
