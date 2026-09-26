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

import "core:bytes"
import "core:crypto"
import subtle "core:crypto/_subtle"
import "core:encoding/endian"

// Minimum size for a RSA modulus (in bits).
//
// Note: 1024-bits is arguably insufficient as of this writing, with
// 2048-bits being a more sensible value, however 1024-bits is likely
// still in frequent enough use.
//
// Note: CA signed TLS certificates have a strict requirement of a modulus
// size that is at least 2048-bits [[ https://cabforum.org/working-groups/server/baseline-requirements/documents/]].
MODULUS_MIN_SIZE :: 1024

// Maximum size for a RSA modulus (in bits).
//
// This value MUST be a multiple of 64. This value MUST NOT exceed 47666
// (some computations in RSA key generation rely on the factor size being
// no more than 23833 bits). RSA key sizes beyond 3072 bits don't make a
// lot of sense anyway.
MODULUS_MAX_SIZE :: 4096

// Maxmimum size for a RSA public exponent (in bits).
//
// Note: This implementation supports arbitrary size exponents, however
// limit it to something sensible (some implementations are known to
// choke on exponents >= 2^32), with the most common choice being
// `65537`.
EXPONENT_MAX_SIZE :: 32

// Maximum size for a RSA factor (in bits). This is for RSA private-key
// operations. Default is to support factors up to a bit more than half
// the maximum modulus size.
//
// This value MUST be a multiple of 32.
FACTOR_MAX_SIZE :: (MODULUS_MAX_SIZE + 64) >> 1

// Default size for a RSA key (in bits).
DEFAULT_MODULUS_SIZE :: 2048

// RSA public exponent used for key generation.  This MUST be a prime
// number greater than 2.
@(private)
PUBLIC_EXPONENT :: 65537

#assert(EXPONENT_MAX_SIZE <= 32)

// Private_Key is a RSA private key.
Private_Key :: struct {
	_pub_key: Public_Key,
	_d: Modulus, // Private exponent has the same size as n.
	_p: Factor,
	_q: Factor,

	// CRT coefficients.
	_dp: Factor, // d % (p - 1)
	_dq: Factor, // d % (q - 1)
	_iq: Factor, // q^(-1) mod p

	_is_initialized: bool,
}

// Public_Key is a RSA public key.
Public_Key :: struct {
	_n: Modulus,
	_e: u32,
	_is_initialized: bool,
}

// private_key_generate uses the system entropy source to generate a new
// Private_Key.  The key size is specified in bits, and must be a multiple
// of 8.
@(require_results)
private_key_generate :: proc(priv_key: ^Private_Key, key_size := DEFAULT_MODULUS_SIZE) -> bool {
	if !crypto.HAS_RAND_BYTES {
		return false
	}
	if key_size < MODULUS_MIN_SIZE || key_size > MODULUS_MAX_SIZE {
		return false
	}
	if key_size % 8 != 0 {
		return false
	}

	private_key_clear(priv_key)
	defer if !priv_key._is_initialized {
		private_key_clear(priv_key)
	}

	for {
		// The only way this can fail is if we get extremely unlucky
		// and we fail to derive `iq` (1/d mod p).
		if keygen_inner(priv_key, key_size) == 1 {
			break
		}
	}
	priv_key._is_initialized = true
	priv_key._pub_key._is_initialized = true

	// Self-test the key.
	priv_key._is_initialized = pkcs1_sig_selftest(priv_key)

	return priv_key._is_initialized
}

// private_key_n copies the private key's public modulus to dst if dst is
// non-nil and of sufficient size, and returns the number of bytes
// copied/would be copied (ie: calling with `dst = nil` gets the required
// size).
@(require_results)
private_key_n :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return public_key_n(&priv_key._pub_key, dst)
}

// private_key_e returns the private key's public exponent as a u32.
@(require_results)
private_key_e :: proc(priv_key: ^Private_Key) -> u32 {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return public_key_e(&priv_key._pub_key)
}

// private_key_d copies the private key's private exponent `d` to dst if
// dst is non-nil and of sufficient size, and returns the number of bytes
// copied/would be copied (ie: calling with `dst = nil` gets the required
// size).
//
// Note: The data returned MUST be kept confidential.
@(require_results)
private_key_d :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return modulus_copyout(&priv_key._d, dst)
}

// private_key_p copies the private key's first prime factor `p` to dst
// if dst is non-nil and of sufficient size, and returns the number of
// bytes copied/would be copied (ie: calling with `dst = nil` gets the
// required size).
//
// Note: The data returned MUST be kept confidential.
@(require_results)
private_key_p :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return factor_copyout(&priv_key._p, dst)
}

// private_key_q copies the private key's second prime factor `q` to dst
// if dst is non-nil and of sufficient size, and returns the number of
// bytes copied/would be copied (ie: calling with `dst = nil` gets the
// required size).
//
// Note: The data returned MUST be kept confidential.
@(require_results)
private_key_q :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return factor_copyout(&priv_key._q, dst)
}

// private_key_dp copies the private key's first reduced exponent
// `d % (p-1)` to dst if dst is non-nil and of sufficient size, and
// returns the number of bytes copied/would be copied (ie: calling with
//`dst = nil` gets the required size).
//
// Note: The data returned MUST be kept confidential.
@(require_results)
private_key_dp :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return factor_copyout(&priv_key._dp, dst)
}

// private_key_dq copies the private key's second reduced exponent
// `d % (q-1)` to dst if dst is non-nil and of sufficient size, and
// returns the number of bytes copied/would be copied (ie: calling with
//`dst = nil` gets the required size).
//
// Note: The data returned MUST be kept confidential.
@(require_results)
private_key_dq :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return factor_copyout(&priv_key._dq, dst)
}

// private_key_iq copies the private key's CRT coefficient `iq` to dst if
// dst is non-nil and of sufficient size, and returns the number of bytes
// copied/would be copied (ie: calling with`dst = nil` gets the required
// size).
//
// Note: The data returned MUST be kept confidential.
@(require_results)
private_key_iq :: proc(priv_key: ^Private_Key, dst: []byte) -> (n_len: int) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return factor_copyout(&priv_key._iq, dst)
}

// private_key_size returns the size of the private key's public modulus
// in bytes.  All ciphertexts and signatures will also be this size.
@(require_results)
private_key_size :: proc(priv_key: ^Private_Key) -> int {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")

	return priv_key._pub_key._n.v_len
}

// private_key_set_bytes sets a private key from byte-encoded components,
// and returns true if and only if (⟺) the operation was successful.
//
// Note: All values are mandatory, and match the values included in the
// PKCS private key format.
//
// WARNING: This routine validates that it is possible to sign/verify with
// the deserialized values, however d is not checked at all, nor is the
// primality of p and q.
@(require_results)
private_key_set_bytes :: proc(
	priv_key: ^Private_Key,
	n: []byte,
	e: []byte,
	d: []byte,
	p: []byte,
	q: []byte,
	dp: []byte,
	dq: []byte,
	iq: []byte,
) -> bool {
	private_key_clear(priv_key)
	defer if !priv_key._is_initialized {
		private_key_clear(priv_key)
	}

	if !public_key_set_bytes(&priv_key._pub_key, n, e) {
		return false
	}

	if !modulus_set_bytes(&priv_key._d, d) {
		return false
	}
	if !factor_set_bytes(&priv_key._p, p) {
		return false
	}
	if !factor_set_bytes(&priv_key._q, q) {
		return false
	}
	if !factor_set_bytes(&priv_key._dp, dp) {
		return false
	}
	if !factor_set_bytes(&priv_key._dq, dq) {
		return false
	}
	if !factor_set_bytes(&priv_key._iq, iq) {
		return false
	}

	priv_key._is_initialized = true

	// Test the key.
	//
	// Note: This DOES NOT check that p/q are prime and if d is
	// consistent (as it is not used by our implementation).
	priv_key._is_initialized = pkcs1_sig_selftest(priv_key)

	return priv_key._is_initialized
}

// private_key_set sets priv_key to src.
private_key_set :: proc(priv_key, src: ^Private_Key) {
	if src == nil || !src._is_initialized {
		private_key_clear(priv_key)
		return
	}

	public_key_set(&priv_key._pub_key, &src._pub_key)
	modulus_set(&priv_key._d, &src._d)
	factor_set(&priv_key._p, &src._p)
	factor_set(&priv_key._q, &src._q)
	factor_set(&priv_key._dp, &src._dp)
	factor_set(&priv_key._dq, &src._dq)
	factor_set(&priv_key._iq, &src._iq)

	priv_key._is_initialized = true
}

// private_key_equal returns true if and only if (⟺) priv_key is equal to other.
@(require_results)
private_key_equal :: proc(priv_key, other: ^Private_Key) -> bool {
	ensure(priv_key._is_initialized && other._is_initialized, "crypto/rsa: uninitialized private key")

	pk_eq := public_key_equal(&priv_key._pub_key, &other._pub_key)

	eq := crypto.compare_constant_time(modulus_bytes(&priv_key._d), modulus_bytes(&other._d))
	eq &= crypto.compare_constant_time(factor_bytes(&priv_key._p), factor_bytes(&other._p))
	eq &= crypto.compare_constant_time(factor_bytes(&priv_key._q), factor_bytes(&other._q))
	eq &= crypto.compare_constant_time(factor_bytes(&priv_key._dp), factor_bytes(&other._dp))
	eq &= crypto.compare_constant_time(factor_bytes(&priv_key._dq), factor_bytes(&other._dq))
	eq &= crypto.compare_constant_time(factor_bytes(&priv_key._iq), factor_bytes(&other._iq))

	return pk_eq & (eq == 1)
}

// private_key_clear clears priv_key to the uninitialized state.
private_key_clear :: proc "contextless" (priv_key: ^Private_Key) {
	crypto.zero_explicit(priv_key, size_of(Private_Key))
}

// public_key_n copies the public key's modulus `n` to dst if dst is
// non-nil and of sufficient size, and returns the number of bytes
// copied/would be copied (ie: calling with `dst = nil` gets the
// required size).
@(require_results)
public_key_n :: proc(pub_key: ^Public_Key, dst: []byte) -> (n_len: int) {
	ensure(pub_key._is_initialized, "crypto/rsa: uninitialized public key")

	return modulus_copyout(&pub_key._n, dst)
}

// public_key_e returns the public key's exponent `e` as a u32.
@(require_results)
public_key_e :: proc(pub_key: ^Public_Key) -> u32 {
	ensure(pub_key._is_initialized, "crypto/rsa: uninitialized public key")

	return pub_key._e
}

// public_key_size returns the size of the public key's modulus in bytes.
// All ciphertexts and signatures will also be this size.
@(require_results)
public_key_size :: proc(pub_key: ^Public_Key) -> int {
	ensure(pub_key._is_initialized, "crypto/rsa: uninitialized public key")

	return pub_key._n.v_len
}

// public_key_set_bytes sets a public key from byte-encoded components,
// and returns true if and only if (⟺) the operation was successful.
@(require_results)
public_key_set_bytes :: proc(pub_key: ^Public_Key, n, e: []byte) -> bool {
	public_key_clear(pub_key)
	defer if !pub_key._is_initialized {
		public_key_clear(pub_key)
	}

	ok := modulus_set_bytes(&pub_key._n, n)
	if !ok {
		return false
	}
	if modulus_len(&pub_key._n) < MODULUS_MIN_SIZE >> 3 {
		return false
	}
	if !modulus_is_odd(&pub_key._n) {
		return false
	}

	e_ := bytes.trim_left(e, []byte{0x00})
	e_len := len(e_)
	if e_len > EXPONENT_MAX_SIZE >> 3 {
		return false
	}
	e_buf: [4]byte
	copy(e_buf[4 - e_len:], e)
	e_u32 := endian.unchecked_get_u32be(e_buf[:])
	if e_u32 < 3 || e_u32 & 1 == 0 {
		return false
	}
	pub_key._e = e_u32

	pub_key._is_initialized = true

	return true
}

// public_key_set sets pub_key to src.
public_key_set :: proc(pub_key, src: ^Public_Key) {
	if src == nil || !src._is_initialized {
		public_key_clear(pub_key)
		return
	}

	modulus_set(&pub_key._n, &src._n)
	pub_key._e = src._e
	pub_key._is_initialized = true
}

// public_key_set_priv sets pub_key to the public component of priv_key.
public_key_set_priv :: proc(pub_key: ^Public_Key, priv_key: ^Private_Key) {
	ensure(priv_key._is_initialized, "crypto/rsa: uninitialized private key")
	pub_key^ = priv_key._pub_key
}

// public_key_equal returns true if and only if (⟺) pub_key is equal to other.
public_key_equal :: proc(pub_key, other: ^Public_Key) -> bool {
	ensure(pub_key._is_initialized && other._is_initialized, "crypto/rsa: uninitialized public key")

	eq := crypto.compare_constant_time(modulus_bytes(&pub_key._n), modulus_bytes(&other._n))
	eq &= int(subtle.eq(pub_key._e, other._e))

	return eq == 1
}

// public_key_clear clears pub_key to the uninitialized state.
public_key_clear :: proc "contextless" (pub_key: ^Public_Key) {
	crypto.zero_explicit(pub_key, size_of(Public_Key))
}

// size returns the size of the key's public modulus in bytes.
// All ciphertexts and signatures will also be this size.
size :: proc "contextless" (key: ^$T) -> int where T == Private_Key || T == Private_Key {
	when T == Private_Key {
		return private_key_size(key)
	} else {
		return public_key_size(key)
	}
}
