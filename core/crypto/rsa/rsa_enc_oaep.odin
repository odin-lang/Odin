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
import "core:crypto/hash"

// encrypt_oaep returns true if and only if (⟺) it successfully
// encrypts the plaintext with OAEP parameterized by label, hash_algo,
// and mgf1_algo, and writes the cipherttext into dst.  If mgf1_algo is
// unspecified, hash_algo will be used.
//
// This routine will fail if the system entropy source is unavailable.
encrypt_oaep :: proc(
	pub_key: ^Public_Key,
	hash_algo: hash.Algorithm,
	plaintext: []byte,
	dst: []byte,
	label: []byte = nil,
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
	if len(dst) != modulus_len(&pub_key._n) {
		return false
	}
	if len(plaintext) > oaep_max_plaintext_size(pub_key, hash_algo, mgf1_algo_) {
		return false
	}

	if oaep_enc_pad(hash_algo, mgf1_algo_, label, dst, plaintext) != 1 {
		return false
	}

	return public_modpow(dst, pub_key) == 1
}

@(private="file")
oaep_enc_pad :: proc(
	hash_algo: hash.Algorithm,
	mgf1_algo: hash.Algorithm,
	label: []byte,
	dst: []byte,
	src: []byte,
) -> u32 {
	hash_len := hash.DIGEST_SIZES[hash_algo]
	src_len := len(src)
	k := len(dst)

	// Note: Length checks are handled by the caller.

	// Apply padding. At this point, things cannot fail.
	buf := dst

	// Assemble: DB = lHash || PS || 0x01 || M
	// We first place the source message M with copy(), so that
	// overlaps between source and destination buffers are supported.
	copy(buf[k - src_len:], src)
	hash.hash_bytes_to_buffer(hash_algo, label, buf[1+hash_len:1+hash_len << 1])
	intrinsics.mem_zero(raw_data(buf[1 + hash_len << 1:]), k - src_len - (hash_len << 1) - 2)
	buf[k - src_len - 1] = 0x01

	// Make the random seed.
	seed, db := buf[1:1+hash_len], buf[1+hash_len:]
	crypto.rand_bytes(seed)

	// Mask DB with the mask generated from the seed.
	mgf1_xor(db, mgf1_algo, seed)

	// Mask the seed with the mask generated from the masked DB.
	mgf1_xor(seed, mgf1_algo, db)

	// Padding result: EM = 0x00 || maskedSeed || maskedDB.
	buf[0] = 0x00
	return 1
}
