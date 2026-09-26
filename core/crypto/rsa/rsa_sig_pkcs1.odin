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

import "core:bytes"
import "core:crypto"
import "core:crypto/hash"

// PKCS1_HASH_OIDS maps common hash algorithms to the OIDs for
// use with PKCS#1 signatures.
@(rodata)
PKCS1_HASH_OIDS := #partial [hash.Algorithm][]byte {
	// WARNING: Legacy verification ONLY.
	.Insecure_SHA1 = []byte{
		0x05, 0x2B, 0x0E, 0x03, 0x02, 0x1A,
	},
	.SHA224 = []byte{
		0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04,
	},
	.SHA256 = []byte{
		0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01,
	},
	.SHA384 = []byte{
		0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x02,
	},
	.SHA512 = []byte{
		0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03,
	},
	.SHA512_256 = []byte{
		0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x06,
	},
}

@(private="file", rodata)
PKCS1_SELFTEST_DIGEST_SHA256 := []byte{
	0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
	0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
	0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20,
}

// verify_pkcs1 returns true if and only if (⟺) sig is a valid PKCS#1
// signature by pub_key over msg, hased using hash_algo.  If pre_hashed
// is set to true, it is assumed that msg is already hashed.
@(require_results)
verify_pkcs1 :: proc(pub_key: ^Public_Key, hash_algo: hash.Algorithm, msg, sig: []byte, is_prehashed := false) -> bool {
	if !pub_key._is_initialized {
		return false
	}
	if len(sig) != modulus_len(&pub_key._n) {
		return false
	}

	// Lookup the OID.
	oid := PKCS1_HASH_OIDS[hash_algo]
	if oid == nil {
		return false
	}
	hash_len := hash.DIGEST_SIZES[hash_algo]

	// Compute the message hash.
	msg_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
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

	// PKCS #1 V2.2 (RFC 8017) 8.2.2 specifies this as computing
	// and comparing the padded hash, with unpadding and extracting
	// the hash being an alternative.  Upstream BearSSL implements
	// the latter, which is not a problem if done correctly (which
	// it does), however we will opt to go for implementing this
	// as specified as it is more robust against implementation
	// errors.

	// Compute the expected hash.
	sig_buf, padded_hash_buf: [MODULUS_MAX_SIZE >> 3]byte = ---, ---
	if len(sig) > len(sig_buf) {
		return false
	}
	padded_hash_ := padded_hash_buf[:len(sig)]
	if pkcs1_sig_pad(oid, msg_hash, padded_hash_) != 1 {
		return false
	}

	// Compute the signature's padded hash.
	sig_ := sig_buf[:len(sig)]
	copy(sig_, sig)
	if public_modpow(sig_, pub_key) != 1 {
		return false
	}

	return bytes.equal(sig_, padded_hash_)
}

// sign_pkcs1 returns true if and only if (⟺) it successfully writes
// the PKCS#1 signature by priv_key over msg, hashed using hash_algo.
// If pre_hashed is set to true, it is assumed that msg is already hashed.
@(require_results)
sign_pkcs1 :: proc(priv_key: ^Private_Key, hash_algo: hash.Algorithm, msg, sig: []byte, is_prehashed := false) -> bool {
	if !priv_key._is_initialized {
		return false
	}
	if len(sig) != modulus_len(&priv_key._pub_key._n) {
		return false
	}

	// Lookup the OID.
	oid := PKCS1_HASH_OIDS[hash_algo]
	if oid == nil {
		return false
	}

	// Compute the message hash.
	msg_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
	msg_hash: []byte
	switch is_prehashed {
	case true:
		if len(msg) != hash.DIGEST_SIZES[hash_algo] {
			return false
		}
		msg_hash = msg
	case false:
		msg_hash = hash.hash_bytes_to_buffer(hash_algo, msg, msg_hash_buf[:])
	}

	if pkcs1_sig_pad(oid, msg_hash, sig) != 1 {
		return false
	}

	return private_modpow(sig, priv_key) == 1
}

@(private="file", require_results)
pkcs1_sig_pad :: proc "contextless" (hash_oid, hash, x: []byte) -> u32 {
	// Padded hash value has format:
	//  00 01 FF .. FF 00 30 x1 30 x2 06 x3 OID 05 00 04 x4 HASH
	//
	// with the following rules:
	//
	//  -- Total length is equal to the modulus length (unsigned
	//     encoding).
	//
	//  -- There must be at least eight bytes of value 0xFF.
	//
	//  -- x4 is equal to the hash length (hash_len).
	//
	//  -- x3 is equal to the encoded OID value length (hash_oid[0]).
	//
	//  -- x2 = x3 + 4.
	//
	//  -- x1 = x2 + x4 + 4 = x3 + x4 + 8.
	//
	// Note: the "05 00" is optional (signatures with and without
	// that sequence exist in practice), but notes in PKCS#1 seem to
	// indicate that the presence of that sequence (specifically,
	// an ASN.1 NULL value for the hash parameters) may be slightly
	// more "standard" than the opposite.
	xlen, hash_len := len(x), len(hash)

	// Note/yawning: The hash OID is mandatory, as is the "05 00".
	x3 := hash_oid[0]

	// Check that there is enough room for all the elements,
	// including at least eight bytes of value 0xFF.
	if xlen < int(x3) + hash_len + 21 {
		return 0
	}
	x[0] = 0x00
	x[1] = 0x01
	u := xlen - int(x3) - hash_len - 11
	for i in 2..< u {
		x[i] = 0xff
	}
	x[u] = 0x00
	x[u + 1] = 0x30
	x[u + 2] = x3 + byte(hash_len) + 8
	x[u + 3] = 0x30
	x[u + 4] = x3 + 4
	x[u + 5] = 0x06
	copy(x[u+6:], hash_oid)
	u += int(x3) + 7
	x[u] = 0x05
	u += 1
	x[u] = 0x00
	u += 1
	x[u] = 0x04
	u += 1
	x[u] = byte(hash_len)
	u += 1
	copy(x[u:], hash)

	return 1
}

@(private)
pkcs1_sig_selftest :: proc(priv_key: ^Private_Key) -> bool {
	sig_buf: [MODULUS_MAX_SIZE >> 3]byte = ---
	defer crypto.zero_explicit(&sig_buf, size_of(sig_buf))

	sig := sig_buf[:private_key_size(priv_key)]
	if !sign_pkcs1(priv_key, .SHA256, PKCS1_SELFTEST_DIGEST_SHA256, sig, true) {
		return false
	}

	return verify_pkcs1(&priv_key._pub_key, .SHA256, PKCS1_SELFTEST_DIGEST_SHA256, sig, true)
}
