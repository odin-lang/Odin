package _mlkem

import "core:crypto"
import subtle "core:crypto/_subtle"

// This implementation is derived from the PQ-CRYSTALS reference
// implementation [[ https://github.com/pq-crystals/kyber ]],
// primarily for licensing reasons.  Arguably mlkem-native is
// a more "up to date" codebase, but the changes to the
// ref code is minor and they slapped an attribution-required
// license on something that was originally CC-0/Apache 2.0.

// "Private Key"
Decapsulation_Key :: struct {
	pke_dk: K_PKE_Decryption_Key,
	ek: Encapsulation_Key,
	seed: [SYMBYTES*2]byte, // (d, z)
}

// "Public Key"
Encapsulation_Key :: struct {
	pke_ek: K_PKE_Encryption_Key,
	raw_bytes: [INDCPA_PUBLICKEYBYTES_MAX]byte,
	h: [SYMBYTES]byte,
}

decapsulation_key_expanded_bytes :: proc(
	dk: ^Decapsulation_Key,
	dst: []byte,
) {
	sk := &dk.pke_dk
	pv_len := polyvec_byte_size(sk.k)
	ek_len := pv_len + SYMBYTES

	ek_bytes := dk.ek.raw_bytes[:ek_len]

	dst := dst
	_ = pack_sk(dst[:pv_len], &sk.pv, sk.k)

	dst = dst[pv_len:]
	copy(dst, ek_bytes)
	dst = dst[ek_len:]
	hash_h(dst[:SYMBYTES], ek_bytes)
	dst = dst[SYMBYTES:]
	copy(dst, dk.seed[SYMBYTES:])
}

@(require_results)
encapsulation_key_set_bytes :: proc(
	ek: ^Encapsulation_Key,
	k: int,
	b: []byte,
) -> bool {
	k_len: int
	switch k {
	case K_512:
		k_len = ENCAPSKEYBYTES_512
	case K_768:
		k_len = ENCAPSKEYBYTES_768
	case K_1024:
		k_len = ENCAPSKEYBYTES_1024
	case:
		return false
	}
	if len(b) != k_len {
		return false
	}

	pke_ek := &ek.pke_ek
	ok := unpack_pk(&pke_ek.pv, pke_ek.p[:], b)
	pke_ek.k = k
	copy(ek.raw_bytes[:k_len], b)
	hash_h(ek.h[:], b)

	// FIPS 203 unlike Kyber requires canonical encoding of
	// encapsulation keys (Section 7,2), which is checked in
	// unpack_pk.

	if !ok {
		crypto.zero_explicit(ek, size_of(Encapsulation_Key))
	}

	return ok
}

encapsulation_key_set_decaps :: proc(ek: ^Encapsulation_Key, dk: ^Decapsulation_Key) {
	dk_ek := &dk.ek.pke_ek
	ensure(dk_ek.k == K_512 || dk_ek.k == K_768 || dk_ek.k == K_1024, "crypto/mlkem: invalid decaps k")

	k_pke_encryption_key_set(&ek.pke_ek, dk_ek)
	copy(ek.raw_bytes[:], dk.ek.raw_bytes[:])
	copy(ek.h[:], dk.ek.h[:])
}

// NIST's version of this also returns an encapsulation key, but our
// internal representation includes it as part of the decapsulation key
// in a more traditional "keypair" approach.
kem_keygen_internal :: proc(
	dk: ^Decapsulation_Key,
	seed: []byte, // (d, z)
	k: int,
) {
	ensure(len(seed) == 2 * SYMBYTES, "crypto/mlkem: invalid seed")

	dk_ek := &dk.ek
	d, z := seed[:SYMBYTES], seed[SYMBYTES:]

	k_pke_keygen(&dk_ek.pke_ek, &dk.pke_dk, d, k)

	ek_len := polyvec_byte_size(k) + SYMBYTES
	ek_bytes := dk_ek.raw_bytes[:ek_len]
	ensure(
		pack_pk(ek_bytes, &dk_ek.pke_ek.pv, dk_ek.pke_ek.p[:], k),
		"crypto/mlkem: failed to pack K-PKE ek",
	)
	hash_h(dk_ek.h[:], ek_bytes)
	copy(dk.seed[:SYMBYTES], d)
	copy(dk.seed[SYMBYTES:], z)
}

// The `_internal` "de-randomized" versions of ML-KEM.Encaps and
// ML-KEM.Decaps are only ever to be called by the actual non-interal
// implementation or test cases.

kem_encaps_internal :: proc(
	shared_secret: []byte,
	ciphertext: []byte,
	ek: ^Encapsulation_Key,
	randomness: []byte,
) {
	ensure(len(shared_secret) == SYMBYTES, "crypto/mlkem: invalid K")
	ensure(len(randomness) == SYMBYTES, "crypto/mlkem: invalid m")
	ensure(
		len(ciphertext) == ct_len_for_k(ek.pke_ek.k),
		"crypto/mlkem: invalid ciphertext length",
	)

	buf: [2*SYMBYTES]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	hash_g(buf[:], randomness, ek.h[:])

	// Can't fail, ciphertext length is valid.
	_ = k_pke_encrypt(ciphertext, &ek.pke_ek, randomness, buf[SYMBYTES:])

	copy(shared_secret, buf[:SYMBYTES])
}

kem_decaps_internal :: proc(
	shared_secret: []byte,
	dk: ^Decapsulation_Key,
	ciphertext: []byte,
) {
	ct_len := ct_len_for_k(dk.pke_dk.k)
	ensure(
		len(ciphertext) == ct_len,
		"crypto/mlkem: invalid ciphertext length",
	)

	m_: [SYMBYTES]byte
	defer crypto.zero_explicit(&m_, size_of(m_))

	// Can't fail, ciphertext length is valid.
	_ = k_pke_decrypt(m_[:], &dk.pke_dk, ciphertext)

	buf: [2*SYMBYTES]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	ek := &dk.ek
	hash_g(buf[:], m_[:], ek.h[:])

	rkprf(shared_secret, dk.seed[SYMBYTES:], ciphertext)

	ct_buf: [CIPHERTEXTBYTES_MAX]byte = ---
	defer crypto.zero_explicit(&ct_buf, size_of(ct_buf))
	ct_ := ct_buf[:ct_len]
	_ = k_pke_encrypt(ct_, &ek.pke_ek, m_[:], buf[SYMBYTES:])

	ok := crypto.compare_constant_time(ciphertext, ct_)
	subtle.cmov_bytes(shared_secret, buf[:SYMBYTES], ok)
}

@(private="file")
ct_len_for_k :: proc(k: int) -> int {
	switch k {
	case K_512:
		return CIPHERTEXTBYTES_512
	case K_768:
		return CIPHERTEXTBYTES_768
	case K_1024:
		return CIPHERTEXTBYTES_1024
	case:
		panic("crypto/mlkem: invalid k for ciphertext length")
	}
}
