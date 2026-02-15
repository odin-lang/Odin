package ecdsa

import "core:crypto/hash"
import secec "core:crypto/_weierstrass"

@(require_results)
verify_asn1 :: proc(pub_key: ^Public_Key, hash_algo: hash.Algorithm, msg, sig: []byte) -> bool {
	r_bytes, s_bytes, ok := parse_asn1_sig(sig)
	if !ok {
		return false
	}

	return verify_raw(pub_key, hash_algo, msg, r_bytes, s_bytes)
}

@(require_results)
verify_raw :: proc(pub_key: ^Public_Key, hash_algo: hash.Algorithm, msg, sig_r, sig_s: []byte) -> bool {
	if hash_algo == .Invalid {
		return false
	}
	if pub_key._curve == .Invalid {
		return false
	}

	h_bytes: [hash.MAX_DIGEST_SIZE]byte = ---
	h := h_bytes[:hash.DIGEST_SIZES[hash_algo]]
	h_ctx: hash.Context
	hash.init(&h_ctx, hash_algo)
	hash.update(&h_ctx, msg)
	hash.final(&h_ctx, h)

	r_bytes := strip_leading_zeroes(sig_r)
	s_bytes := strip_leading_zeroes(sig_s)

	#partial switch pub_key._curve {
	case .SECP256R1:
		pk := &pub_key._impl.(secec.Point_p256r1)
		return verify_internal(pk, r_bytes, s_bytes, h)
	case .SECP384R1:
		pk := &pub_key._impl.(secec.Point_p384r1)
		return verify_internal(pk, r_bytes, s_bytes, h)
	}

	return false
}

@(private,require_results)
verify_internal :: proc(pub_key: ^$T, sig_r, sig_s, sig_e: []byte) -> bool {
	when T == secec.Point_p256r1 {
		r, s, e, v: secec.Scalar_p256r1 = ---, ---, ---, ---
		u1, u2, s_inv: secec.Scalar_p256r1 = ---, ---, ---
		SC_SZ :: secec.SC_SIZE_P256R1
	} else when T == secec.Point_p384r1 {
		r, s, e, v: secec.Scalar_p384r1 = ---, ---, ---, ---
		u1, u2, s_inv: secec.Scalar_p384r1 = ---, ---, ---
		SC_SZ :: secec.SC_SIZE_P384R1
	} else {
		return false
	}

	if did_reduce := secec.sc_set_bytes(&r, sig_r); did_reduce {
		return false
	}
	if did_reduce := secec.sc_set_bytes(&s, sig_s); did_reduce {
		return false
	}
	if secec.sc_is_zero(&r) == 1 || secec.sc_is_zero(&s) == 1 {
		return false
	}
	e_bytes := sig_e
	if len(sig_e) > SC_SZ {
		e_bytes = e_bytes[:SC_SZ]
	}
	_ = secec.sc_set_bytes(&e, e_bytes)

	secec.sc_inv(&s_inv, &s)
	secec.sc_mul(&u1, &e, &s_inv)
	secec.sc_mul(&u2, &r, &s_inv)

	r_pt: T = ---
	secec.pt_double_scalar_mul_generator_vartime(&r_pt, pub_key, &u1, &u2)
	if secec.pt_is_identity(&r_pt) == 1 {
		return false
	}

	r_x: [SC_SZ]byte = ---
	_ = secec.pt_bytes(r_x[:], nil, &r_pt)
	_ = secec.sc_set_bytes(&v, r_x[:])

	return secec.sc_equal(&r, &v) == 1
}

@(private,require_results)
strip_leading_zeroes :: proc(b: []byte) -> []byte {
	nz: int
	for v in b {
		if v != 0 {
			break
		}
		nz += 1
	}
	return b[nz:]
}
