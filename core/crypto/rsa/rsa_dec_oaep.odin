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
import subtle "core:crypto/_subtle"
import "core:crypto/hash"

// decrypt_oaep returns the plaintext and true if and only if (⟺) it
// successfully decrypts the ciphertext with OAEP parameterized by
// label, hash_algo, and mgf1_algo, and writes the plaintext into dst.
// If mgf1_algo is unspecified, hash_algo will be used.
//
// Note: dst MUST be large enough to contain the plaintext.
@(require_results)
decrypt_oaep :: proc(
	priv_key: ^Private_Key,
	hash_algo: hash.Algorithm,
	ciphertext: []byte,
	dst: []byte,
	label: []byte = nil,
	mgf1_algo := hash.Algorithm.Invalid,
) -> (plaintext: []byte, ok: bool) {
	if !priv_key._is_initialized {
		return
	}
	ct_len := len(ciphertext)
	if ct_len != modulus_len(&priv_key._pub_key._n) {
		return
	}
	if hash_algo == .Invalid {
		return
	}
	mgf1_algo_ := mgf1_algo
	if mgf1_algo == .Invalid {
		mgf1_algo_ = hash_algo
	}

	tmp: [MODULUS_MAX_SIZE >> 3]byte
	pt_buf := tmp[:ct_len]
	defer crypto.zero_explicit(raw_data(pt_buf), ct_len)

	copy(pt_buf, ciphertext)
	r := private_modpow(pt_buf, priv_key)
	r_, l := oaep_dec_unpad(hash_algo, mgf1_algo_, label, pt_buf)

	// Conditional branches are ok as we are past the padding
	// verification.
	if ok = r & r_ == 1; ok {
		if l <= len(dst) {
			copy(dst, pt_buf[:l])
			plaintext = dst[:l]
		} else {
			ok = false
		}
	}

	return
}

// oaep_max_plaintext_size returns the maximum supported plaintext size
// for a given key, with OAEP parameterized by hash_algo and mgf1_algo.
// If mgf1_algo is unspecified, hash_algo will be used.
@(require_results)
oaep_max_plaintext_size :: proc(
	k: ^$T,
	hash_algo: hash.Algorithm,
	mgf1_algo := hash.Algorithm.Invalid,
) -> int where T == Private_Key || T == Public_Key {
	if !k._is_initialized {
		return 0
	}
	if hash_algo == .Invalid {
		return 0
	}
	mgf1_algo_ := mgf1_algo
	if mgf1_algo == .Invalid {
		mgf1_algo_ = hash_algo
	}

	overhead := 2 + hash.DIGEST_SIZES[hash_algo] + hash.DIGEST_SIZES[mgf1_algo_]

	pub_key: ^Public_Key
	when T == Private_Key {
		pub_keyk = &k._pub_key
	} else {
		pub_key = k
	}
	return modulus_len(&k._n) - overhead
}

@(private="file")
xor_hash_data :: proc(hash_algo: hash.Algorithm, dst: []byte, src: []byte) {
	tmp: [hash.MAX_DIGEST_SIZE]byte = ---
	hash_len := hash.DIGEST_SIZES[hash_algo]
	digest := tmp[:hash_len]
	defer crypto.zero_explicit(raw_data(digest), hash_len)

	hash.hash_bytes_to_buffer(hash_algo, src, digest)
	for v, u in digest {
		dst[u] ~= v
	}
}

@(private="file")
oaep_dec_unpad :: proc(
	hash_algo: hash.Algorithm,
	mgf1_algo: hash.Algorithm,
	label: []byte,
	data: []byte,
) -> (u32, int) {
	hash_len := hash.DIGEST_SIZES[hash_algo]
	k := len(data)
	buf := data

	// There must be room for the padding.
	if k < (hash_len << 1) + 2 {
		return 0, 0
	}

	// Unmask the seed, then the DB value.
	seed, db := buf[1:1+hash_len], buf[1+hash_len:]
	mgf1_xor(seed, mgf1_algo, db)
	mgf1_xor(db, mgf1_algo, seed)

	// Hash the label and XOR it with the value in the array; if
	// they are equal then these should yield only zeros.
	xor_hash_data(hash_algo, db, label)

	// At that point, if the padding was correct, when we should
	// have: 0x00 || seed || 0x00 ... 0x00 0x01 || M
	// Padding is valid as long as:
	//  - There is at least hlen+1 leading bytes of value 0x00.
	//  - There is at least one non-zero byte.
	//  - The first (leftmost) non-zero byte has value 0x01.
	//
	// Ultimately, we may leak the resulting message length, i.e.
	// the position of the byte of value 0x01, but we must take care
	// to do so only if the number of zero bytes has been verified
	// to be at least hlen+1.
	//
	// The loop below counts the number of bytes of value 0x00, and
	// checks that the next byte has value 0x01, in constant-time.
	//
	//  - If the initial byte (before the seed) is not 0x00, then
	//    r and s are set to 0, and stay there.
	//  - Value r is 1 until the first non-zero byte is reached
	//    (after the seed); it switches to 0 at that point.
	//  - Value s is set to 1 if and only if the data encountered
	//    at the time of the transition of r from 1 to 0 has value
	//    exactly 0x01.
	//  - Value zlen counts the number of leading bytes of value zero
	//    (after the seed).
	r := u32(subtle.eq(buf[0], 0))
	s, zlen: u32
	for u in hash_len + 1..<k {
		w := u32(buf[u])

		// nz == 1 only for the first non-zero byte.
		nz := r & ((w + 0xFF) >> 8)
		s |= nz & subtle.eq(w, 0x01)
		r &= subtle.not(nz)
		zlen += r
	}

	// Padding is correct only if s == 1, _and_ zlen >= hlen.
	s &= subtle.ge(zlen, u32(hash_len))

	// At that point, padding was verified, and we are now allowed
	// to make conditional jumps.
	if s != 0 {
		plen := 2 + hash_len + int(zlen)
		k -= plen
		copy(buf[:k], buf[plen:])
	}
	return s, k
}
