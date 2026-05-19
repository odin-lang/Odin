#+private
package _mlkem

import "core:crypto"
import "core:crypto/shake"

@(require_results)
pack_pk :: proc "contextless" (r: []byte, pk: ^Polyvec, seed: []byte, k: int) -> bool {
	pk_len := polyvec_byte_size(k)
	switch {
	case pk_len == 0:
		return false
	case len(seed) != SYMBYTES || len(r) != pk_len + SYMBYTES:
		return false
	}

	polyvec_tobytes(r[:pk_len], pk, k)
	copy(r[pk_len:], seed)

	return true
}

@(require_results)
unpack_pk :: proc "contextless" (pk: ^Polyvec, seed, packedpk: []byte) -> bool {
	pk_len := len(packedpk) - SYMBYTES
	k: int
	switch {
	case pk_len == POLYVECBYTES_512:
		k = K_512
	case pk_len == POLYVECBYTES_768:
		k = K_768
	case pk_len == POLYVECBYTES_1024:
		k = K_1024
	case len(packedpk) - pk_len != SYMBYTES:
		return false
	case len(seed) != SYMBYTES:
		return false
	}
	if k == 0 {
		return false
	}

	ok := polyvec_frombytes(pk, packedpk[:pk_len], k)
	copy(seed, packedpk[pk_len:])

	return ok
}

@(require_results)
pack_sk :: proc "contextless" (r: []byte, sk: ^Polyvec, k: int) -> bool {
	r_len := len(r)
	if r_len == 0 || r_len != polyvec_byte_size(k) {
		return false
	}

	polyvec_tobytes(r, sk, k)

	return true
}

@(require_results)
unpack_sk :: proc "contextless" (sk: ^Polyvec, packedsk: []byte) -> bool {
	k: int
	switch len(packedsk) {
	case POLYVECBYTES_512:
		k = K_512
	case POLYVECBYTES_768:
		k = K_768
	case POLYVECBYTES_1024:
		k = K_1024
	case:
		return false
	}
	if k == 0 {
		return false
	}

	return polyvec_frombytes(sk, packedsk, k)
}

@(require_results)
pack_ciphertext :: proc "contextless" (r: []byte, b: ^Polyvec, v: ^Poly, k: int) -> bool {
	b_len := polyvec_compressed_byte_size(k)
	if len(r) != b_len + poly_compressed_bytes(k) {
		return false
	}

	polyvec_compress(r[:b_len], b, k)
	poly_compress(r[b_len:], v)

	return true
}

@(require_results)
unpack_ciphertext :: proc "contextless" (b: ^Polyvec, v: ^Poly, c: []byte) -> int {
	b_len: int
	k: int
	switch len(c) {
	case INDCPA_BYTES_512:
		b_len = POLYVECCOMPRESSEDBYTES_512
		k = K_512
	case INDCPA_BYTES_768:
		b_len = POLYVECCOMPRESSEDBYTES_768
		k = K_768
	case INDCPA_BYTES_1024:
		b_len = POLYVECCOMPRESSEDBYTES_1024
		k = K_1024
	case:
		return 0
	}

	polyvec_decompress(b, c[:b_len], k)
	poly_decompress(v, c[b_len:])

	return k
}

@(require_results)
rej_uniform :: proc "contextless" (r: []i16, buf: []byte) -> int {
	r_len, b_len := len(r), len(buf)

	ctr, pos: int
	for ctr < r_len && pos + 3 <= b_len {
		val0 := (u16(buf[pos+0] >> 0) | (u16(buf[pos+1]) << 8)) & 0xFFF
		val1 := (u16(buf[pos+1] >> 4) | (u16(buf[pos+2]) << 4)) & 0xFFF
		pos += 3

		if val0 < Q {
			r[ctr] = i16(val0)
			ctr += 1
		}
		if(ctr < r_len && val1 < Q) {
			r[ctr] = i16(val1)
			ctr += 1
		}
	}

	return ctr
}

gen_matrix :: proc(a: []Polyvec, seed: []byte, transposed: bool, k: int) {
	GEN_MATRIX_NBLOCKS :: ((12*N/8*(1 << 12)/Q + XOF_BLOCKBYTES)/XOF_BLOCKBYTES)

	buf: [GEN_MATRIX_NBLOCKS*XOF_BLOCKBYTES]byte = ---
	ctx: shake.Context = ---
	ctr: int

	defer shake.reset(&ctx)
	defer crypto.zero_explicit(&buf, size_of(buf))

	for i in 0..<k {
		for j in 0..<k {
			switch transposed {
			case true:
				xof_absorb(&ctx, seed, byte(i), byte(j))
			case false:
				xof_absorb(&ctx, seed, byte(j), byte(i))
			}

			shake.read(&ctx, buf[:])
			ctr = rej_uniform(a[i].vec[j].coeffs[:], buf[:])

			b := buf[:XOF_BLOCKBYTES]
			for ctr < N {
				shake.read(&ctx, b)
				ctr += rej_uniform(a[i].vec[j].coeffs[ctr:], b)
			}
		}
	}
}

K_PKE_Decryption_Key :: struct {
	pv: Polyvec,
	k: int,
}

K_PKE_Encryption_Key :: struct {
	pv: Polyvec,
	p: [SYMBYTES]byte,
	k: int,
}

k_pke_encryption_key_set :: proc(dst, src: ^K_PKE_Encryption_Key) {
	k_pke_key_clear(dst)

	for i in 0..<src.k {
		copy(dst.pv.vec[i].coeffs[:], src.pv.vec[i].coeffs[:])
	}
	copy(dst.p[:], src.p[:])
	dst.k = src.k
}

k_pke_key_clear :: proc(k: $T) where T == ^K_PKE_Encryption_Key || T == ^K_PKE_Decryption_Key {
	crypto.zero_explicit(k, size_of(k^))
}

k_pke_keygen :: proc(
	ek: ^K_PKE_Encryption_Key,
	dk: ^K_PKE_Decryption_Key,
	d: []byte,
	k: int,
) {
	assert(len(d) == SYMBYTES, "crypto/mlkem: invalid K-PKE d")
	ensure(k == K_512 || k == K_768 || k == K_1024, "crypto/mlkem: invalid k")

	buf: [2*SYMBYTES]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	a_: [K_MAX]Polyvec = ---
	e: Polyvec = ---
	defer crypto.zero_explicit(&a_, size_of(Polyvec) * k)
	defer polyvec_clear(&e)

	a := a_[:k]

	copy(buf[:], d)
	buf[SYMBYTES] = byte(k)
	hash_g(buf[:], buf[:SYMBYTES+1])

	p, sigma := buf[:SYMBYTES], buf[SYMBYTES:]

	gen_matrix(a, p, false, k)

	n := byte(0)
	for i in 0..<k {
		if k != K_512 {
			poly_getnoise_eta1(&dk.pv.vec[i], sigma, n)
		} else {
			poly_getnoise_eta1_512(&dk.pv.vec[i], sigma, n)
		}
		n += 1
	}
	for i in 0..<k {
		if k != K_512 {
			poly_getnoise_eta1(&e.vec[i], sigma, n)
		} else {
			poly_getnoise_eta1_512(&e.vec[i], sigma, n)
		}
		n += 1
	}

	polyvec_ntt(&dk.pv, k)
	polyvec_ntt(&e, k)

	for i in 0..<k {
		polyvec_basemul_acc_montgomery(&ek.pv.vec[i], &a[i], &dk.pv, k)
		poly_tomont(&ek.pv.vec[i])
	}

	polyvec_add(&ek.pv, &ek.pv, &e, k)
	polyvec_reduce(&ek.pv, k)

	copy(ek.p[:], p)

	dk.k = k
	ek.k = k
}

@(require_results)
k_pke_encrypt :: proc(
	ciphertext: []byte,
	ek: ^K_PKE_Encryption_Key,
	m: []byte,
	r: []byte,
) -> bool {
	ensure(len(m) == INDCPA_MSGBYTES, "crypto/mlkem: invalid K-PKE m")
	ensure(len(r) == SYMBYTES, "crypto/mlkem: invalid K-PKE r")

	k := ek.k

	at_: [K_MAX]Polyvec = ---
	sp, ep, b: Polyvec = ---, ---, ---
	kay, epp, v: Poly = ---, ---, ---
	defer crypto.zero_explicit(&at_, size_of(Polyvec) * k)
	defer polyvec_clear(&sp, &ep, &b)
	defer poly_clear(&kay, &epp, &v)

	poly_frommsg(&kay, m)

	at := at_[:k]

	gen_matrix(at, ek.p[:], true, k)

	n := byte(0)
	for i in 0..<k {
		if k != K_512 {
			poly_getnoise_eta1(&sp.vec[i], r, n)
		} else {
			poly_getnoise_eta1_512(&sp.vec[i], r, n)
		}
		n += 1
	}
	for i in 0..<k {
		poly_getnoise_eta2(&ep.vec[i], r, n)
		n += 1
	}
	poly_getnoise_eta2(&epp, r, n)

	polyvec_ntt(&sp, k)

	for i in 0..<k {
		polyvec_basemul_acc_montgomery(&b.vec[i], &at[i], &sp, k)
	}

	polyvec_basemul_acc_montgomery(&v, &ek.pv, &sp, k)

	polyvec_invntt_tomont(&b, k)
	poly_invntt_tomont(&v)

	polyvec_add(&b, &b, &ep, k)
	poly_add(&v, &v, &epp)
	poly_add(&v, &v, &kay)
	polyvec_reduce(&b, k)
	poly_reduce(&v)

	return pack_ciphertext(ciphertext, &b, &v, k)
}

@(require_results)
k_pke_decrypt :: proc(
	plaintext: []byte,
	dk: ^K_PKE_Decryption_Key,
	c: []byte,
) -> bool {
	if len(plaintext) != INDCPA_MSGBYTES {
		return false
	}

	k := dk.k

	b: Polyvec = ---
	v, mp: Poly = ---, ---
	defer poly_clear(&v, &mp)

	if unpack_ciphertext(&b, &v, c) != k {
		return false
	}

	polyvec_ntt(&b, k)
	polyvec_basemul_acc_montgomery(&mp, &dk.pv, &b, k)
	poly_invntt_tomont(&mp)

	poly_sub(&mp, &v, &mp)
	poly_reduce(&mp)

	poly_tomsg(plaintext, &mp)

	return true
}
