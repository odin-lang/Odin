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

import "base:intrinsics"
import "core:crypto"
import bigint "core:crypto/_bigint"
import subtle "core:crypto/_subtle"
import "core:crypto/hash"

// verify_pss returns true if and only if (⟺) sig is a valid PSS
// signature by pub_key over msg, hashed using hash_algo, and MGF1
// parameterized by mgf1_algo and salt_len.  If mgf1_algo is
// unspecified, hash_algo will be used.  If pre_hashed is set
// to true, it is assumed that msg is already hashed.
@(require_results)
verify_pss :: proc(
	pub_key: ^Public_Key,
	hash_algo: hash.Algorithm,
	salt_len: int,
	msg: []byte,
	sig: []byte,
	is_prehashed := false,
	mgf1_algo := hash.Algorithm.Invalid,
) -> bool {
	if !pub_key._is_initialized {
		return false
	}
	if hash_algo == .Invalid {
		return false
	}
	mgf1_algo_ := mgf1_algo
	if mgf1_algo == .Invalid {
		mgf1_algo_ = hash_algo
	}
	if len(sig) != modulus_len(&pub_key._n) {
		return false
	}

	// Compute the message hash.
	msg_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
	hash_len := hash.DIGEST_SIZES[hash_algo]
	msg_hash: []byte
	switch is_prehashed {
	case true:
		if len(msg) != hash_len {
			return false
		}
		msg_hash = msg
	case false:
		msg_hash = hash.hash_bytes_to_buffer(hash_algo, msg, msg_hash_buf[:])
	}

	sig_buf: [MODULUS_MAX_SIZE >> 3]byte = ---
	sig_ := sig_buf[:len(sig)]
	copy(sig_, sig)
	if public_modpow(sig_, pub_key) != 1 {
		return false
	}

	return pss_sig_unpad(hash_algo, mgf1_algo_, msg_hash, salt_len, pub_key, sig_) == 1
}

// sign_pss returns true if and only if (⟺) it successfully writes
// the PKCS#1 signature by priv_key over msg, hashed using hash_algo, and
// MGF1 parameterized by mgf1_algo and salt_len.  If mgf1_algo is
// unspecified, hash_algo will be used.  If pre_hashed is set to true,
// it is assumed that msg is already hashed.  A reasonable choice for
// salt_len is the digest size of hash_algo, and FIPS 140-3 mandates
// that as the maximum permissible size.
//
// This routine will fail if the system entropy source is unavailable.
@(require_results)
sign_pss :: proc(
	priv_key: ^Private_Key,
	hash_algo: hash.Algorithm,
	salt_len: int,
	msg: []byte,
	sig: []byte,
	is_prehashed := false,
	mgf1_algo := hash.Algorithm.Invalid,
) -> bool {
	if !priv_key._is_initialized {
		return false
	}
	if len(sig) != modulus_len(&priv_key._pub_key._n) {
		return false
	}
	if hash_algo == .Invalid {
		return false
	}
	mgf1_algo_ := mgf1_algo
	if mgf1_algo == .Invalid {
		mgf1_algo_ = hash_algo
	}
	if !crypto.HAS_RAND_BYTES && salt_len != 0 {
		return false
	}

	// Compute the message hash.
	msg_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
	hash_len := hash.DIGEST_SIZES[hash_algo]
	msg_hash: []byte
	switch is_prehashed {
	case true:
		if len(msg) != hash_len {
			return false
		}
		msg_hash = msg
	case false:
		msg_hash = hash.hash_bytes_to_buffer(hash_algo, msg, msg_hash_buf[:])
	}

	// Work out the exact length of n in bits.
	n := modulus_bytes(&priv_key._pub_key._n)
	assert(len(n) > 0 && n[0] != 0)
	n_bitlen := int(bigint._u32_bit_length(u32(n[0]))) + (len(n) - 1) * 8

	if pss_sig_pad(hash_algo, mgf1_algo_, msg_hash, salt_len, n_bitlen, sig) != 1 {
		return false
	}

	return private_modpow(sig, priv_key) == 1
}

@(private="file", require_results)
pss_sig_unpad :: proc(
	data_algo: hash.Algorithm,
	mgf1_algo: hash.Algorithm,
	digest: []byte,
	salt_len: int,
	pk: ^Public_Key,
	sig: []byte,
) -> u32 {
	hash_len := hash.DIGEST_SIZES[data_algo]
	x := sig

	// Value r will be set to a non-zero value is any test fails.
	r: u32

	// The value bit length (as an integer) must be strictly less than
	// that of the modulus.
	//
	// Note/yawning: The modulus should already be the correct size,
	// with leading `0x00`s stripped.
	n := modulus_bytes(&pk._n)
	nlen := modulus_len(&pk._n)
	u: int
	for u = 0; u < nlen; u += 1 {
		if n[u] != 0 {
			break
		}
	}
	if u == nlen {
		return 0
	}
	n_bitlen := bigint._u32_bit_length(u32(n[u])) + (u32(nlen - u - 1) << 3)
	n_bitlen -= 1
	if (n_bitlen & 7) == 0 {
		r |= u32(x[0])
		x = x[1:]
	} else {
		r |= u32(x[0] & (0xFF << (n_bitlen & 7)))
	}
	xlen := int((n_bitlen + 7) >> 3)

	// Check that the modulus is large enough for the hash value
	// length combined with the intended salt length.
	if hash_len > xlen || salt_len > xlen || (hash_len + salt_len + 2) > xlen {
		return 0
	}

	// Check value of rightmost byte.
	r |= u32(x[xlen - 1] ~ 0xBC)

	// Generate the mask and XOR it into the first bytes to reveal PS;
	// we must also mask out the leading bits.
	seed := x[xlen - hash_len - 1:]
	mgf1_xor(x[:xlen - hash_len - 1], mgf1_algo, seed[:hash_len])
	if (n_bitlen & 7) != 0 {
		x[0] &= 0xFF >> (8 - (n_bitlen & 7))
	}

	// Check that all padding bytes have the expected value.
	for u = 0; u < (xlen - hash_len - salt_len - 2); u += 1 {
		r |= u32(x[u])
	}
	r |= u32(x[xlen - hash_len - salt_len - 2] ~ 0x01)

	// Recompute H.
	salt := x[xlen - hash_len - salt_len - 1:]
	tmp: [hash.MAX_DIGEST_SIZE]byte
	h := tmp[:hash_len]
	ctx: hash.Context = ---
	hash.init(&ctx, data_algo)
	hash.update(&ctx, tmp[:8])
	hash.update(&ctx, digest)
	hash.update(&ctx, salt[:salt_len])
	hash.final(&ctx, h)

	// Check that the recomputed H value matches the one appearing
	// in the string.
	x = x[xlen - hash_len - 1:]
	r |= subtle.eq0(u32(crypto.compare_constant_time(h, x[:hash_len])))

	return subtle.eq0(r)
}

@(private="file", require_results)
pss_sig_pad :: proc(
	data_algo: hash.Algorithm,
	mgf1_algo: hash.Algorithm,
	digest: []byte,
	salt_len: int,
	n_bitlen_: int,
	sig: []byte,
) -> u32 {
	x, n_bitlen := sig, n_bitlen_
	hash_len := hash.DIGEST_SIZES[data_algo]

	// The padded string is one bit smaller than the modulus;
	// notably, if the modulus length is equal to 1 modulo 8, then
	// the padded string will be one _byte_ smaller, and the first
	// byte will be set to 0. We apply these transformations here.
	n_bitlen -= 1
	if (n_bitlen & 7) == 0 {
		x[0] = 0
		x = x[1:]
	}
	xlen := int((n_bitlen + 7) >> 3)

	// Check that the modulus is large enough for the hash value
	// length combined with the intended salt length.
	if hash_len > xlen || salt_len > xlen || (hash_len + salt_len + 2) > xlen {
		return 0
	}

	// Produce a random salt.
	salt := x[xlen - hash_len - salt_len - 1:]
	salt = salt[:salt_len]
	if salt_len != 0 {
		crypto.rand_bytes(salt)
	}

	// Compute the seed for MGF1.
	seed := x[xlen - hash_len - 1:]
	seed = seed[:hash_len]
	ctx: hash.Context = ---
	hash.init(&ctx, data_algo)
	intrinsics.mem_zero(raw_data(seed), 8)
	hash.update(&ctx, seed[:8])
	hash.update(&ctx, digest)
	hash.update(&ctx, salt)
	hash.final(&ctx, seed)

	// Prepare string PS (padded salt). The salt is already at the
	// right place.
	intrinsics.mem_zero(raw_data(x), xlen - salt_len - hash_len - 2)
	x[xlen - salt_len - hash_len - 2] = 0x01

	// Generate the mask and XOR it into PS.
	mgf1_xor(x[:xlen - hash_len - 1], mgf1_algo, seed)

	// Clear the top bits to ensure the value is lower than the
	// modulus.
	x[0] &= 0xFF >> ((u32(xlen) << 3) - u32(n_bitlen))

	// The seed (H) is already in the right place. We just set the
	// last byte.
	x[xlen - 1] = 0xBC

	return 1
}
