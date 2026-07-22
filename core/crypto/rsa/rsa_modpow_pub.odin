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

import bigint "core:crypto/_bigint"
import "core:encoding/endian"
import "core:slice"

@(private, require_results)
public_modpow :: proc(x: []byte, pk: ^Public_Key) -> u32 {
	TLEN :: (2 * (2 + ((MODULUS_MAX_SIZE + 30) / 31)))

	ensure(pk._is_initialized, "crypto/rsa: uninitialized public key")

	// Get the actual length of the modulus, and see if it fits within
	// our stack buffer. We also check that the length of x[] is valid.
	//
	// Note/yawning: The modulus should already be the correct size,
	// with leading `0x00`s stripped.
	n := modulus_bytes(&pk._n)
	nlen := modulus_len(&pk._n)
	for nlen > 0 && n[0] == 0 {
		n = n[1:]
		nlen -= 1
	}
	if nlen == 0 || nlen > (MODULUS_MAX_SIZE >> 3) || len(x) != nlen {
		return 0
	}
	z := nlen << 3
	fwlen := 1
	for z > 0 {
		z -= 31
		fwlen += 1
	}
	// Convert fwlen to a count in 62-bit words.
	fwlen = (fwlen + 1) >> 1

	// The modulus gets decoded into m[].
	// The value to exponentiate goes into a[].
	tmp: [TLEN]u64 // WARNING: This must be zeroed out.
	m := slice.reinterpret([]u32, tmp[:fwlen])
	a := slice.reinterpret([]u32, tmp[fwlen:2*fwlen])

	// Decode the modulus.
	bigint.i31_decode(m, n)
	m0i := bigint.i31_ninv31(m[1])

	// Note: if m[] is even, then m0i == 0. Otherwise, m0i must be
	// an odd integer.
	r := m0i & 1

	// Decode x[] into a[]; we also check that its value is proper.
	r &= bigint.i31_decode_mod(a, x, m)

	// Compute the modular exponentiation.
	e_: [EXPONENT_MAX_SIZE >> 3]byte
	e_off: int
	endian.unchecked_put_u32be(e_[:], pk._e)
	if e_[0] == 0 {
		// `e = 65537` is the most common and sensible value, so this
		// is the most sensible value.
		e_off = 1
	}
	bigint.i62_modpow_opt(a, e_[e_off:], m, m0i, tmp[2*fwlen:])

	// Encode the result.
	bigint.i31_encode(x, a)
	return r
}
