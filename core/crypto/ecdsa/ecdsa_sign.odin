package ecdsa

import "base:runtime"
import "core:crypto"
import "core:crypto/hash"
import secec "core:crypto/_weierstrass"

// sign_asn1 returns the signature by priv_key over msg hased using hash_algo
// using the signing procedure as specified in SEC 1, Version 2.0, Section
// 4.1.3.  ASN.1 DER requires minimal encoding, and the format is clunky
// and variable-length so for simplicity we allocate the signature.
//
// The signature format is ASN1. `SEQUECE `{ r INTEGER, s INTEGER }`.
@(require_results)
sign_asn1 :: proc(priv_key: ^Private_Key, hash_algo: hash.Algorithm, msg: []byte, allocator: runtime.Allocator, deterministic := !crypto.HAS_RAND_BYTES) -> ([]byte, bool) {
	ensure(hash_algo != .Invalid, "crypto/edsa: invalid hash algorithm")
	ensure(priv_key._curve != .Invalid, "crypto/edsa: invalid curve")

	if !deterministic && !crypto.HAS_RAND_BYTES {
		return nil, false
	}

	#partial switch priv_key._curve {
	case .SECP256R1:
		SC_SZ :: secec.SC_SIZE_P256R1
		RAW_SIG_SZ :: 2 * SC_SZ
		r, s: secec.Scalar_p256r1 = ---, ---
		sk := &priv_key._impl.(secec.Scalar_p256r1)
		sign_internal(sk, &r, &s, hash_algo, msg, deterministic)

		return generate_asn1_sig(&r, &s, allocator), true
	case .SECP384R1:
		SC_SZ :: secec.SC_SIZE_P384R1
		RAW_SIG_SZ :: 2 * SC_SZ
		r, s: secec.Scalar_p384r1 = ---, ---
		sk := &priv_key._impl.(secec.Scalar_p384r1)
		sign_internal(sk, &r, &s, hash_algo, msg, deterministic)

		return generate_asn1_sig(&r, &s, allocator), true
	}

	return nil, false
}

// sign_raw writes the signature by priv_key over msg hased using hash_algo
// to sig, using the signing procedure as specified in SEC 1, Version 2.0,
// Section 4.1.3.
//
// The signature format is `r | s`.
@(require_results)
sign_raw :: proc(priv_key: ^Private_Key, hash_algo: hash.Algorithm, msg, sig: []byte, deterministic := !crypto.HAS_RAND_BYTES) -> bool {
	ensure(hash_algo != .Invalid, "crypto/edsa: invalid hash algorithm")
	ensure(priv_key._curve != .Invalid, "crypto/edsa: invalid curve")
	ensure(len(sig) == RAW_SIGNATURE_SIZES[priv_key._curve], "crypto/ecdsa: invalid destination size")

	if !deterministic && !crypto.HAS_RAND_BYTES {
		return false
	}

	#partial switch priv_key._curve {
	case .SECP256R1:
		SC_SZ :: secec.SC_SIZE_P256R1
		r, s: secec.Scalar_p256r1 = ---, ---
		sk := &priv_key._impl.(secec.Scalar_p256r1)
		sign_internal(sk, &r, &s, hash_algo, msg, deterministic)

		r_bytes, s_bytes := sig[:SC_SZ], sig[SC_SZ:]
		secec.sc_bytes(r_bytes, &r)
		secec.sc_bytes(s_bytes, &s)
	case .SECP384R1:
		SC_SZ :: secec.SC_SIZE_P384R1
		r, s: secec.Scalar_p384r1 = ---, ---
		sk := &priv_key._impl.(secec.Scalar_p384r1)
		sign_internal(sk, &r, &s, hash_algo, msg, deterministic)

		r_bytes, s_bytes := sig[:SC_SZ], sig[SC_SZ:]
		secec.sc_bytes(r_bytes, &r)
		secec.sc_bytes(s_bytes, &s)
	case:
		panic("crypto/ecdsa: invalid curve")
	}

	return true
}

@(private)
sign_internal :: proc(priv_key, sig_r, sig_s: ^$T, hash_algo: hash.Algorithm, msg: []byte, deterministic: bool) {
	when T == secec.Scalar_p256r1 {
		SC_SZ :: secec.SC_SIZE_P256R1
		FE_SZ :: secec.FE_SIZE_P256R1
		MIN_DRBG_HASH :: hash.Algorithm.SHA256
		r_pt: secec.Point_p256r1 = ---
	} else when T == secec.Scalar_p384r1 {
		SC_SZ :: secec.SC_SIZE_P384R1
		FE_SZ :: secec.FE_SIZE_P384R1
		MIN_DRBG_HASH :: hash.Algorithm.SHA384
		r_pt: secec.Point_p384r1 = ---
	} else {
		#panic("crypto/ecdsa: invalid curve")
	}

	// Note: `e` (derived from `hash`) in steps 4 and 5, is
	// unchanged throughout the process even if a different `k`
	// needs to be selected, thus, the value is derived first
	// before the rejection sampling loop.

	// 4. Use the hash function selected during the setup procedure
	// to compute the hash value:
	//   H = Hash(M)
	// of length hashlen octets as specified in Section 3.5. If the
	// hash function outputs “invalid”, output “invalid” and stop.

	// 5. Derive an integer e from H as follows:
	// 5.1. Convert the octet string H to a bit string H using the
	// conversion routine specified in Section 2.3.2.
	// 5.2. Set E = H if ceil(log2(n)) >= 8(hashlen), and set E equal
	// to the leftmost ceil(log2(n)) bits of H if ceil(log2(n)) <
	// 8(hashlen).
	// 5.3. Convert the bit string E to an octet string E using the
	// conversion routine specified in Section 2.3.1.
	// 5.4. Convert the octet string E to an integer e using the
	// conversion routine specified in Section 2.3.8.

	e: T = ---
	h_bytes: [hash.MAX_DIGEST_SIZE]byte = ---
	e_bytes := hash.hash_bytes_to_buffer(hash_algo, msg, h_bytes[:])
	if len(e_bytes) > SC_SZ {
		e_bytes = e_bytes[:SC_SZ]
	}
	if did_reduce := secec.sc_set_bytes(&e, e_bytes); did_reduce {
		// RFC 6979 wants the reduced value
		secec.sc_bytes(e_bytes, &e)
	}

	x_bytes: [SC_SZ]byte = ---
	defer crypto.zero_explicit(&x_bytes, size_of(x_bytes))
	secec.sc_bytes(x_bytes[:], priv_key)

	// While I normally will be content to let idiots compromise
	// their signing keys, past precident (eg: Sony Computer
	// Entertainment America, Inc v. Hotz) shows that "idiots"
	// are also litigatious asshats.  By default we use the hedged
	// ("with additional input") variant of RFC 6979, with the option
	// to disable the added entropy for RFC 6979 compatible deterministic
	// signatures.
	//
	// For implementation simplicity, we will use a hash function that
	// has a digest size that is greater than or equal to that of the
	// curve order.  Using a separate hash is allowed per section 3.6
	// of the RFC, and we only ever use a more secure hash.

	rng: Drbg_RFC6979 = ---
	drbg_hash := hash_algo
	if hash.DIGEST_SIZES[hash_algo] < SC_SZ {
		drbg_hash = MIN_DRBG_HASH
	}
	init_drbg_rfc6979(&rng, drbg_hash, x_bytes[:], e_bytes, deterministic)

	k: T = ---
	defer secec.sc_clear(&k)
	for {
		// 1. Select an ephemeral elliptic curve key pair (k, R) with
		// R = (xR, yR) associated with the elliptic curve domain parameters
		// T established during the setup procedure using the key pair
		// generation primitive specified in Section 3.2.1.

		if did_reduce := drbg_read_rfc6979(&rng, &k); did_reduce || secec.sc_is_zero(&k) == 1 {
			continue
		}
		secec.pt_scalar_mul_generator(&r_pt, &k)

		// 2. Convert the field element xR to an integer xR using the
		// conversion routine specified in Section 2.3.9.

		rx_bytes: [FE_SZ]byte = ---
		_ = secec.pt_bytes(rx_bytes[:], nil, &r_pt)

		// 3. Set r = xR mod n. If r = 0, or optionally r fails to meet
		// other publicly verifiable criteria (see below), return to Step 1.

		_ = secec.sc_set_bytes(sig_r, rx_bytes[:])
		if secec.sc_is_zero(sig_r) == 1 {
			// This is essentially totally untestable since the odds
			// of generating `r = 0` is astronomically unlikely.
			continue
		}

		// (Steps 4/5 done prior to loop.)

		// 6. Compute: s = k^−1 (e + r * dU) mod n.
		// If s = 0, return to Step 1.

		secec.sc_inv(&k, &k)
		secec.sc_mul(sig_s, sig_r, priv_key)
		secec.sc_add(sig_s, sig_s, &e)
		secec.sc_mul(sig_s, sig_s, &k)
		if secec.sc_is_zero(sig_s) == 0 {
			return
		}
	}
}
