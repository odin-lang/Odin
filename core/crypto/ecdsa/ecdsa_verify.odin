package ecdsa

import "core:crypto/hash"
import secec "core:crypto/_weierstrass"

// verify_raw returns true iff sig is a valid signature by pub_key over
// msg, hased using hash_algo, per the verification procedure specifed
// in SEC 1, Version 2.0, Section 4.1.4.
//
// The signature format is `r | s`.
@(require_results)
verify_raw :: proc(pub_key: ^Public_Key, hash_algo: hash.Algorithm, msg, sig: []byte) -> bool {
	ensure(hash_algo != .Invalid, "crypto/edsa: invalid hash algorithm")
	ensure(pub_key._curve != .Invalid, "crypto/edsa: invalid curve")

	if len(sig) != RAW_SIGNATURE_SIZES[pub_key._curve] {
		return false
	}

	#partial switch pub_key._curve {
	case .SECP256R1:
		SC_SZ :: secec.SC_SIZE_P256R1
		r_bytes, s_bytes := sig[:SC_SZ], sig[SC_SZ:]
		pk := &pub_key._impl.(secec.Point_p256r1)
		return verify_internal(pk, hash_algo, r_bytes, s_bytes, msg)
	case .SECP384R1:
		SC_SZ :: secec.SC_SIZE_P384R1
		r_bytes, s_bytes := sig[:SC_SZ], sig[SC_SZ:]
		pk := &pub_key._impl.(secec.Point_p384r1)
		return verify_internal(pk, hash_algo, r_bytes, s_bytes, msg)
	}

	panic("crypto/ecdsa: invalid curve")
}

// verify_asn1 returns true iff sig is a valid signature by pub_key over
// msg, hased using hash_algo, per the verification procedure specifed
// in SEC 1, Version 2.0, Section 4.1.4.
//
// The signature format is ASN.1 `SEQUENCE { r INTEGER, s INTEGER }`.
@(require_results)
verify_asn1 :: proc(pub_key: ^Public_Key, hash_algo: hash.Algorithm, msg, sig: []byte) -> bool {
	ensure(hash_algo != .Invalid, "crypto/edsa: invalid hash algorithm")
	ensure(pub_key._curve != .Invalid, "crypto/edsa: invalid curve")

	r_bytes, s_bytes, ok := parse_asn1_sig(sig)
	if !ok {
		return false
	}

	#partial switch pub_key._curve {
	case .SECP256R1:
		pk := &pub_key._impl.(secec.Point_p256r1)
		return verify_internal(pk, hash_algo, r_bytes, s_bytes, msg)
	case .SECP384R1:
		pk := &pub_key._impl.(secec.Point_p384r1)
		return verify_internal(pk, hash_algo, r_bytes, s_bytes, msg)
	}

	panic("crypto/ecdsa: invalid curve")
}

@(private,require_results)
verify_internal :: proc(pub_key: ^$T, hash_algo: hash.Algorithm, sig_r, sig_s, msg: []byte) -> bool {
	when T == secec.Point_p256r1 {
		r, s, e, v: secec.Scalar_p256r1 = ---, ---, ---, ---
		u1, u2, s_inv: secec.Scalar_p256r1 = ---, ---, ---
		SC_SZ :: secec.SC_SIZE_P256R1
	} else when T == secec.Point_p384r1 {
		r, s, e, v: secec.Scalar_p384r1 = ---, ---, ---, ---
		u1, u2, s_inv: secec.Scalar_p384r1 = ---, ---, ---
		SC_SZ :: secec.SC_SIZE_P384R1
	} else {
		#panic("crypto/ecdsa: invalid curve")
	}

	if len(sig_r) > SC_SZ || len(sig_s) > SC_SZ {
		return false
	}

	// 1. If r and s are not both integers in the interval [1, n − 1],
	// output “invalid” and stop.

	if did_reduce := secec.sc_set_bytes(&r, sig_r); did_reduce {
		return false
	}
	if did_reduce := secec.sc_set_bytes(&s, sig_s); did_reduce {
		return false
	}
	if secec.sc_is_zero(&r) == 1 || secec.sc_is_zero(&s) == 1 {
		return false
	}

	// 2. Use the hash function established during the setup procedure
	// to compute the hash value:
	//   H = Hash(M)
	// of length hashlen octets as specified in Section 3.5. If the
	// hash function outputs “invalid”, output “invalid” and stop.

	// 3. Derive an integer e from H as follows:
	// 3.1. Convert the octet string H to a bit string H using the
	// conversion routine specified in Section 2.3.2.
	// 3.2. Set E = H if ceil(log2(n)) >= 8(hashlen), and set E equal
	// to the leftmost ceil(log2(n)) bits of H if ceil(log2(n)) <
	// 8(hashlen).
	// 3.3. Convert the bit string E to an octet string E using the
	// conversion routine specified in Section 2.3.1.
	// 3.4. Convert the octet string E to an integer e using the
	// conversion routine specified in Section 2.3.8.

	h_bytes: [hash.MAX_DIGEST_SIZE]byte = ---
	e_bytes := hash.hash_bytes_to_buffer(hash_algo, msg, h_bytes[:])
	if len(e_bytes) > SC_SZ {
		e_bytes = e_bytes[:SC_SZ]
	}
	_ = secec.sc_set_bytes(&e, e_bytes)

	// 4. Compute: u1 = e(s^−1) mod n and u2 = r(s^-1) mod n.

	secec.sc_inv(&s_inv, &s)
	secec.sc_mul(&u1, &e, &s_inv)
	secec.sc_mul(&u2, &r, &s_inv)

	// 5. Compute: R = (xR, yR) = u1 * G + u2 * QU.

	r_pt: T = ---
	secec.pt_double_scalar_mul_generator_vartime(&r_pt, pub_key, &u1, &u2)

	// If R = O, output “invalid” and stop.

	if secec.pt_is_identity(&r_pt) == 1 {
		return false
	}

	// 6. Convert the field element xR to an integer xR using the
	// conversion routine specified in Section 2.3.9.
	//
	// 7. Set v = xR mod n.

	r_x: [SC_SZ]byte = ---
	_ = secec.pt_bytes(r_x[:], nil, &r_pt)
	_ = secec.sc_set_bytes(&v, r_x[:])

	// 8. Compare v and r — if v = r, output “valid”, and if
	// v != r, output “invalid”.

	return secec.sc_equal(&r, &v) == 1
}
