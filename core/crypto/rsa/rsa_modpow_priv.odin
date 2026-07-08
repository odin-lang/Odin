package rsa

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

import "core:crypto"
import bigint "core:crypto/_bigint"
import "core:slice"

@(private, require_results)
private_modpow :: proc(x: []byte, sk: ^Private_Key) -> u32 {
	U :: (2 + ((FACTOR_MAX_SIZE + 30) / 31))
	TLEN :: (4 * U) // TLEN is counted in 64-bit words

	ensure(sk._is_initialized, "crypto/rsa: uninitialized private key")

	// Compute the actual lengths of p and q, in bytes.
	// These lengths are not considered secret (we cannot really hide
	// them anyway in constant-time code).
	//
	// Note/yawning: The factors should already be the correct size,
	// with leading `0x00`s stripped.
	p := factor_bytes(&sk._p)
	plen := len(p)
	for  plen > 0 && p[0] == 0 {
		p = p[1:]
		plen -= 1
	}
	q := factor_bytes(&sk._q)
	qlen := len(q)
	for qlen > 0 && q[0] == 0 {
		q = q[1:]
		qlen -= 1
	}

	// Compute the maximum factor length, in 31-bit words.
	z := max(plen, qlen) << 3
	fwlen := 1
	for z > 0 {
		z -= 31
		fwlen += 1
	}

	// Convert size to 62-bit words.
	fwlen = (fwlen + 1) >> 1

	// We need to fit at least 6 values in the stack buffer.
	if 6 * fwlen > TLEN {
		return 0
	}

	// Compute signature length (in bytes).
	xlen := modulus_len(&sk._pub_key._n)

	tmp_: [TLEN]u64 // WARNING: This must be zeroed out.
	defer crypto.zero_explicit(&tmp_, size_of(tmp_))
	tmp := tmp_[:]

	// Decode q.
	mq := slice.reinterpret([]u32, tmp)
	bigint.i31_decode(mq, q)

	// Decode p.
	t1 := slice.reinterpret([]u32, tmp[fwlen:])
	bigint.i31_decode(t1, p)

	// Upstream recomputes the public modulus n, but we can just
	// decode it as our key representation stores all PKCS#1
	// private key values,
	t2 := slice.reinterpret([]u32, tmp[2*fwlen:])
	bigint.i31_decode(t2, modulus_bytes(&sk._pub_key._n))

	// We encode the modulus into bytes, to perform the comparison
	// with bytes. We know that the product length, in bytes, is
	// exactly xlen.
	// The comparison actually computes the carry when subtracting
	// the modulus from the source value; that carry must be 1 for
	// a value in the correct range. We keep it in r, which is our
	// accumulator for the error code.
	m_buf := slice.reinterpret([]byte, tmp[4*fwlen:])
	bigint.i31_encode(m_buf[:xlen], t2)
	u := xlen
	r: u32
	for u > 0 {
		u -= 1
		wn := u32(m_buf[u])
		wx := u32(x[u])
		r = ((wx - (wn + r)) >> 8) & 1
	}

	// Move the decoded p to another temporary buffer.
	mp := t2
	copy(mp, t1[:2*fwlen])

	// Compute s2 = x^dq mod q.
	q0i := bigint.i31_ninv31(mq[1])
	s2 := t1
	bigint.i31_decode_reduce(s2, x, mq)
	r &= bigint.i62_modpow_opt(s2, factor_bytes(&sk._dq), mq, q0i, tmp[3*fwlen:])

	// Compute s1 = x^dp mod p.
	p0i := bigint.i31_ninv31(mp[1])
	s1 := slice.reinterpret([]u32, tmp[3*fwlen:])
	bigint.i31_decode_reduce(s1, x, mp)
	r &= bigint.i62_modpow_opt(s1, factor_bytes(&sk._dp), mp, p0i, tmp[4*fwlen:])

	// Compute:
	//   h = (s1 - s2)*(1/q) mod p
	// s1 is an integer modulo p, but s2 is modulo q. PKCS#1 is
	// unclear about whether p may be lower than q (some existing,
	// widely deployed implementations of RSA don't tolerate p < q),
	// but we want to support that occurrence, so we need to use the
	// reduction function.
	//
	// Since we use br_i31_decode_reduce() for iq (purportedly, the
	// inverse of q modulo p), we also tolerate improperly large
	// values for this parameter.
	t1 = slice.reinterpret([]u32, tmp[4*fwlen:])
	t2 = slice.reinterpret([]u32, tmp[5*fwlen:])
	bigint.i31_reduce(t2, s2, mp)
	_ = bigint.i31_add(s1, mp, bigint.i31_sub(s1, t2, 1))
	bigint.i31_to_monty(s1, mp)
	bigint.i31_decode_reduce(t1, factor_bytes(&sk._iq), mp)
	bigint.i31_montymul(t2, s1, t1, mp, p0i)

	// h is now in t2. We compute the final result:
	//   s = s2 + q*h
	// All these operations are non-modular.
	//
	// We need mq, s2 and t2. We use the t3 buffer as destination.
	// The buffers mp, s1 and t1 are no longer needed, so we can
	// reuse them for t3. Moreover, the first step of the computation
	// is to copy s2 into t3, after which s2 is not needed. Right
	// now, mq is in slot 0, s2 is in slot 1, and t2 is in slot 5.
	// Therefore, we have ample room for t3 by simply using s2.
	t3 := s2
	bigint.i31_mulacc(t3, mq, t2)

	// Encode the result. Since we already checked the value of xlen,
	// we can just use it right away.
	bigint.i31_encode(x, t3)

	// The only error conditions remaining at that point are invalid
	// values for p and q (even integers).
	return p0i & q0i & r
}
