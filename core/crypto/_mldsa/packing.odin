package _mldsa

import "base:intrinsics"
import "core:crypto"

@(require_results)
pack_pk :: proc "contextless" (pk_bytes: []byte, pub_key: ^Public_Key) -> bool {
	if len(pk_bytes) != public_key_size(pub_key.params) {
		return false
	}

	seed_bytes, t1_bytes := pk_bytes[:SEEDBYTES], pk_bytes[SEEDBYTES:]

	copy(seed_bytes, pub_key.rho[:])

	for i in 0..<pub_key.params.k {
		polyt1_pack(t1_bytes[i*POLYT1_PACKEDBYTES:], &pub_key.t1.vec[i])
	}

	return true
}

@(require_results)
unpack_pk :: proc(pub_key: ^Public_Key, pk_bytes: []byte, params: ^Params) -> bool {
	if len(pk_bytes) != public_key_size(params) {
		return false
	}

	seed_bytes, t1_bytes := pk_bytes[:SEEDBYTES], pk_bytes[SEEDBYTES:]

	pub_key.params = params

	copy(pub_key.rho[:], seed_bytes)

	for i in 0..<params.k {
		polyt1_unpack(&pub_key.t1.vec[i], t1_bytes[i*POLYT1_PACKEDBYTES:])
	}

	shake256(pub_key.mu[:], pk_bytes)

	return true
}

set_pk :: proc(dst, src: ^Public_Key) {
	dst.params = src.params

	polyvec_copy(&dst.t1, &src.t1, src.params)
	copy(dst.rho[:], src.rho[:])
	copy(dst.mu[:], src.mu[:])
}

clear_pk :: proc "contextless" (pub_key: ^Public_Key) {
	crypto.zero_explicit(pub_key, size_of(Public_Key))
}

@(require_results)
pack_sk :: proc "contextless" (sk_bytes: []byte, priv_key: ^Private_Key) -> bool {
	params := priv_key.params
	if len(sk_bytes) != private_key_size(params) {
		return false
	}

	sk_bytes := sk_bytes
	polyeta_len := polyeta_packedbytes(params)

	copy(sk_bytes, priv_key.rho[:])
	sk_bytes = sk_bytes[SEEDBYTES:]

	copy(sk_bytes, priv_key.key[:])
	sk_bytes = sk_bytes[SEEDBYTES:]

	copy(sk_bytes, priv_key.tr[:])
	sk_bytes = sk_bytes[TRBYTES:]

	for i in 0..<params.l {
		polyeta_pack(sk_bytes[i*polyeta_len:], &priv_key.s1.vec[i], params)
	}
	sk_bytes = sk_bytes[polyeta_len*params.l:]

	for i in 0..<params.k {
		polyeta_pack(sk_bytes[i*polyeta_len:], &priv_key.s2.vec[i], params)
	}
	sk_bytes = sk_bytes[polyeta_len*params.k:]

	for i in 0..<params.k {
		polyt1_pack(sk_bytes[i*POLYT1_PACKEDBYTES:], &priv_key.t0.vec[i])
	}

	return true
}

set_sk :: proc(dst, src: ^Private_Key) {
	dst.params = src.params

	copy(dst.rho[:], src.rho[:])
	copy(dst.tr[:], src.tr[:])
	copy(dst.key[:], src.key[:])
	polyvec_copy(&dst.t0, &src.t0, src.params)
	polyvec_copy(&dst.s1, &src.s1, src.params)
	polyvec_copy(&dst.s2, &src.s2, src.params)

	set_pk(&dst.pub_key, &src.pub_key)

	copy(dst.seed[:], src.seed[:])
}

clear_sk :: proc "contextless" (priv_key: ^Private_Key) {
	crypto.zero_explicit(priv_key, size_of(Private_Key))
}

@(private,require_results)
pack_sig :: proc "contextless" (sig_bytes: []byte, sig: ^Signature) -> bool {
	if len(sig_bytes) != signature_size(sig.params) {
		return false
	}

	sig_bytes := sig_bytes
	polyz_len := polyz_packedbytes(sig.params)

	copy(sig_bytes, sig.c[:sig.params.ctild_bytes])
	sig_bytes = sig_bytes[sig.params.ctild_bytes:]

	for i in 0..<sig.params.l {
		polyz_pack(sig_bytes[i*polyz_len:], &sig.z.vec[i], sig.params)
	}
	sig_bytes = sig_bytes[sig.params.l*polyz_len:]

	intrinsics.mem_zero(raw_data(sig_bytes), len(sig_bytes))

	k: int
	for i in 0..<sig.params.k {
		for j in 0..<N {
			if sig.h.vec[i].coeffs[j] != 0 {
				sig_bytes[k] = byte(j)
				k += 1
			}
		}

		sig_bytes[sig.params.omega + i] = byte(k)
	}

	return true
}

@(private,require_results)
unpack_sig :: proc "contextless" (sig: ^Signature, sig_bytes: []byte, params: ^Params) -> bool {
	if len(sig_bytes) != signature_size(params) {
		return false
	}

	intrinsics.mem_zero(sig, size_of(Signature))

	sig_bytes := sig_bytes
	polyz_len := polyz_packedbytes(params)
	omega := params.omega

	copy(sig.c[:], sig_bytes[:params.ctild_bytes])
	sig_bytes = sig_bytes[params.ctild_bytes:]

	for i in 0..<params.l {
		polyz_unpack(&sig.z.vec[i], sig_bytes[i*polyz_len:], params)
	}
	sig_bytes = sig_bytes[params.l*polyz_len:]

	// Decode h
	k: int
	for i in 0..<params.k {
		if sig_bytes[omega + i] < byte(k) || sig_bytes[omega + i] > byte(omega) {
			return false
		}

		for j := k; j < int(sig_bytes[omega + i]); j += 1 {
			// Coefficients are ordered for strong unforgeability
			if j > k && sig_bytes[j] <= sig_bytes[j-1] {
				return false
			}
			sig.h.vec[i].coeffs[sig_bytes[j]] = 1
		}

		k = int(sig_bytes[omega + i])
	}

	// Extra indices are zero for strong unforgeability
	for j := k; j < omega; j += 1 {
		if sig_bytes[j] != 0 {
			return false
		}
	}

	sig.params = params

	return true
}

@(private,require_results)
public_key_size :: #force_inline proc "contextless" (params: ^Params) -> int {
	return SEEDBYTES + params.k * POLYT1_PACKEDBYTES
}

@(private,require_results)
private_key_size :: #force_inline proc "contextless" (params: ^Params) -> int {
	return 2*SEEDBYTES + TRBYTES + (params.l + params.k) * polyeta_packedbytes(params) + params.k * POLYT0_PACKEDBYTES
}

@(private,require_results)
signature_size :: #force_inline proc "contextless" (params: ^Params) -> int {
	return params.ctild_bytes + params.l * polyz_packedbytes(params) + polyvech_packedbytes(params)
}
