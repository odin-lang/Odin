/*
package ed25519 implements the Ed25519 EdDSA signature algorithm.

See:
- [[ https://datatracker.ietf.org/doc/html/rfc8032 ]]
- [[ https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-5.pdf ]]
- [[ https://eprint.iacr.org/2020/1244.pdf ]]
*/
package ed25519

import "core:crypto"
import grp "core:crypto/_edwards25519"
import "core:crypto/sha2"
import "core:mem"

// PRIVATE_KEY_SIZE is the byte-encoded private key size.
PRIVATE_KEY_SIZE :: 32
// PUBLIC_KEY_SIZE is the byte-encoded public key size.
PUBLIC_KEY_SIZE :: 32
// SIGNATURE_SIZE is the byte-encoded signature size.
SIGNATURE_SIZE :: 64

@(private)
HDIGEST2_SIZE :: 32

// Private_Key is an Ed25519 private key.
Private_Key :: struct {
	// WARNING: All of the members are to be treated as internal (ie:
	// the Private_Key structure is intended to be opaque).  There are
	// subtle vulnerabilities that can be introduced if the internal
	// values are allowed to be altered.
	//
	// See: https://github.com/MystenLabs/ed25519-unsafe-libs
	_b:              [PRIVATE_KEY_SIZE]byte,
	_s:              grp.Scalar,
	_hdigest2:       [HDIGEST2_SIZE]byte,
	_pub_key:        Public_Key,
	_is_initialized: bool,
}

// Public_Key is an Ed25519 public key.
Public_Key :: struct {
	// WARNING: All of the members are to be treated as internal (ie:
	// the Public_Key structure is intended to be opaque).
	_b:              [PUBLIC_KEY_SIZE]byte,
	_neg_A:          grp.Group_Element,
	_is_valid:       bool,
	_is_initialized: bool,
}

// private_key_set_bytes decodes a byte-encoded private key, and returns
// true iff the operation was successful.
private_key_set_bytes :: proc(priv_key: ^Private_Key, b: []byte) -> bool {
	if len(b) != PRIVATE_KEY_SIZE {
		return false
	}

	// Derive the private key.
	ctx: sha2.Context_512 = ---
	h_bytes: [sha2.DIGEST_SIZE_512]byte = ---
	sha2.init_512(&ctx)
	sha2.update(&ctx, b)
	sha2.final(&ctx, h_bytes[:])

	copy(priv_key._b[:], b)
	copy(priv_key._hdigest2[:], h_bytes[32:])
	grp.sc_set_bytes_rfc8032(&priv_key._s, h_bytes[:32])

	// Derive the corresponding public key.
	A: grp.Group_Element = ---
	grp.ge_scalarmult_basepoint(&A, &priv_key._s)
	grp.ge_bytes(&A, priv_key._pub_key._b[:])
	grp.ge_negate(&priv_key._pub_key._neg_A, &A)
	priv_key._pub_key._is_valid = !grp.ge_is_small_order(&A)
	priv_key._pub_key._is_initialized = true

	priv_key._is_initialized = true

	return true
}

// private_key_bytes sets dst to byte-encoding of priv_key.
private_key_bytes :: proc(priv_key: ^Private_Key, dst: []byte) {
	ensure(priv_key._is_initialized, "crypto/ed25519: uninitialized private key")
	ensure(len(dst) == PRIVATE_KEY_SIZE, "crypto/ed25519: invalid destination size")

	copy(dst, priv_key._b[:])
}

// private_key_clear clears priv_key to the uninitialized state.
private_key_clear :: proc "contextless" (priv_key: ^Private_Key) {
	mem.zero_explicit(priv_key, size_of(Private_Key))
}

// sign writes the signature by priv_key over msg to sig.
sign :: proc(priv_key: ^Private_Key, msg, sig: []byte) {
	ensure(priv_key._is_initialized, "crypto/ed25519: uninitialized private key")
	ensure(len(sig) == SIGNATURE_SIZE, "crypto/ed25519: invalid destination size")

	// 1. Compute the hash of the private key d, H(d) = (h_0, h_1, ..., h_2b-1)
	// using SHA-512 for Ed25519.  H(d) may be precomputed.
	//
	// 2. Using the second half of the digest hdigest2 = hb || ... || h2b-1,
	// define:
	//
	// 2.1 For Ed25519, r = SHA-512(hdigest2 || M); Interpret r as a
	// 64-octet little-endian integer.
	ctx: sha2.Context_512 = ---
	digest_bytes: [sha2.DIGEST_SIZE_512]byte = ---
	sha2.init_512(&ctx)
	sha2.update(&ctx, priv_key._hdigest2[:])
	sha2.update(&ctx, msg)
	sha2.final(&ctx, digest_bytes[:])

	r: grp.Scalar = ---
	grp.sc_set_bytes_wide(&r, &digest_bytes)

	// 3. Compute the point [r]G. The octet string R is the encoding of
	// the point [r]G.
	R: grp.Group_Element = ---
	R_bytes := sig[:32]
	grp.ge_scalarmult_basepoint(&R, &r)
	grp.ge_bytes(&R, R_bytes)

	// 4. Derive s from H(d) as in the key pair generation algorithm.
	// Use octet strings R, Q, and M to define:
	//
	// 4.1 For Ed25519, digest = SHA-512(R || Q || M).
	// Interpret digest as a little-endian integer.
	sha2.init_512(&ctx)
	sha2.update(&ctx, R_bytes)
	sha2.update(&ctx, priv_key._pub_key._b[:]) // Q in NIST terminology.
	sha2.update(&ctx, msg)
	sha2.final(&ctx, digest_bytes[:])

	sc: grp.Scalar = --- // `digest` in NIST terminology.
	grp.sc_set_bytes_wide(&sc, &digest_bytes)

	// 5. Compute S = (r + digest × s) mod n. The octet string S is the
	// encoding of the resultant integer.
	grp.sc_mul(&sc, &sc, &priv_key._s)
	grp.sc_add(&sc, &sc, &r)

	// 6. Form the signature as the concatenation of the octet strings
	// R and S.
	grp.sc_bytes(sig[32:], &sc)

	grp.sc_clear(&r)
}

// public_key_set_bytes decodes a byte-encoded public key, and returns
// true iff the operation was successful.
public_key_set_bytes :: proc "contextless" (pub_key: ^Public_Key, b: []byte) -> bool {
	if len(b) != PUBLIC_KEY_SIZE {
		return false
	}

	A: grp.Group_Element = ---
	if !grp.ge_set_bytes(&A, b) {
		return false
	}

	copy(pub_key._b[:], b)
	grp.ge_negate(&pub_key._neg_A, &A)
	pub_key._is_valid = !grp.ge_is_small_order(&A)
	pub_key._is_initialized = true

	return true
}

// public_key_set_priv sets pub_key to the public component of priv_key.
public_key_set_priv :: proc(pub_key: ^Public_Key, priv_key: ^Private_Key) {
	ensure(priv_key._is_initialized, "crypto/ed25519: uninitialized public key")

	src := &priv_key._pub_key
	copy(pub_key._b[:], src._b[:])
	grp.ge_set(&pub_key._neg_A, &src._neg_A)
	pub_key._is_valid = src._is_valid
	pub_key._is_initialized = src._is_initialized
}

// public_key_bytes sets dst to byte-encoding of pub_key.
public_key_bytes :: proc(pub_key: ^Public_Key, dst: []byte) {
	ensure(pub_key._is_initialized, "crypto/ed25519: uninitialized public key")
	ensure(len(dst) == PUBLIC_KEY_SIZE, "crypto/ed25519: invalid destination size")

	copy(dst, pub_key._b[:])
}

// public_key_equal returns true iff pub_key is equal to other.
public_key_equal :: proc(pub_key, other: ^Public_Key) -> bool {
	ensure(pub_key._is_initialized && other._is_initialized, "crypto/ed25519: uninitialized public key")

	return crypto.compare_constant_time(pub_key._b[:], other._b[:]) == 1
}

// verify returns true iff sig is a valid signature by pub_key over msg.
//
// The optional `allow_small_order_A` parameter will make this
// implementation strictly compatible with FIPS 186-5, at the expense of
// SBS-security.  Doing so is NOT recommended, and the disallowed
// public keys all have a known discrete-log.
verify :: proc(pub_key: ^Public_Key, msg, sig: []byte, allow_small_order_A := false) -> bool {
	switch {
	case !pub_key._is_initialized:
		return false
	case len(sig) != SIGNATURE_SIZE:
		return false
	}

	// TLDR: Just use ristretto255.
	//
	// While there are two "standards" for EdDSA, existing implementations
	// diverge (sometimes dramatically).  This implementation opts for
	// "Algorithm 2" from "Taming the Many EdDSAs", which provides the
	// strongest notion of security (SUF-CMA + SBS).
	//
	// The relevant properties are:
	// - Reject non-canonical S.
	// - Reject non-canonical A/R.
	// - Reject small-order A (Extra non-standard check).
	// - Cofactored verification equation.
	//
	// There are 19 possible non-canonical group element encodings of
	// which:
	// - 2 are small order
	// - 10 are mixed order
	// - 7 are not on the curve
	//
	// While historical implementations have been lax about enforcing
	// that A/R are canonically encoded, that behavior is mandated by
	// both the RFC and FIPS specification.  No valid key generation
	// or sign implementation will ever produce non-canonically encoded
	// public keys or signatures.
	//
	// There are 8 small-order group elements, 1 which is in the
	// prime-order sub-group, and thus the probability that a properly
	// generated A is small-order is cryptographically insignificant.
	//
	// While both the RFC and FIPS standard allow for either the
	// cofactored or non-cofactored equation.  It is possible to
	// artificially produce signatures that are valid for the former
	// but not the latter.  This will NEVER occur with a valid sign
	// implementation.  The choice of the latter is to be compatible
	// with ABGLSV-Pornin, batch verification, and FROST (among other
	// things).

	s_bytes, r_bytes := sig[32:], sig[:32]

	// 1. Reject the signature if S is not in the range [0, L).
	s: grp.Scalar = ---
	if !grp.sc_set_bytes(&s, s_bytes) {
		return false
	}

	// 2. Reject the signature if the public key A is one of 8 small
	// order points.
	//
	// As this check is optional and not part of the standard, we allow
	// the caller to bypass it if desired.  Disabling the check makes
	// the scheme NOT SBS-secure.
	if !pub_key._is_valid && !allow_small_order_A {
		return false
	}

	// 3. Reject the signature if A or R are non-canonical.
	//
	// Note: All initialized public keys are guaranteed to be canonical.
	neg_R: grp.Group_Element = ---
	if !grp.ge_set_bytes(&neg_R, r_bytes) {
		return false
	}
	grp.ge_negate(&neg_R, &neg_R)

	// 4. Compute the hash SHA512(R||A||M) and reduce it mod L to get a
	// scalar h.
	ctx: sha2.Context_512 = ---
	h_bytes: [sha2.DIGEST_SIZE_512]byte = ---
	sha2.init_512(&ctx)
	sha2.update(&ctx, r_bytes)
	sha2.update(&ctx, pub_key._b[:])
	sha2.update(&ctx, msg)
	sha2.final(&ctx, h_bytes[:])

	h: grp.Scalar = ---
	grp.sc_set_bytes_wide(&h, &h_bytes)

	// 5. Accept if 8(s * G) - 8R - 8(h * A) = 0
	//
	// > first compute V = SB − R − hA and then accept if V is one of
	// > 8 small order points (or alternatively compute 8V with 3
	// > doublings and check against the neutral element)
	V: grp.Group_Element = ---
	grp.ge_double_scalarmult_basepoint_vartime(&V, &h, &pub_key._neg_A, &s)
	grp.ge_add(&V, &V, &neg_R)

	return grp.ge_is_small_order(&V)
}
