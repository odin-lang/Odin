package mlkem

import "core:crypto"
import "core:crypto/_mlkem"

// Parameters are the supported ML-KEM parameter sets.
Parameters :: enum {
	Invalid,
	ML_KEM_512,
	ML_KEM_768,
	ML_KEM_1024,
}

// DECAPSULATION_KEY_SEED_SIZE is the size of a Decapsulation key in bytes.
DECAPSULATION_KEY_SEED_SIZE :: 64 // (d, z) in NIST terms.

// DECAPSULATION_KEY_EXPANDED_SIZES are the per-parameter sizes of the
// decapsulation key in bytes.
DECAPSULATION_KEY_EXPANDED_SIZES := [Parameters]int {
	.Invalid = 0,
	.ML_KEM_512 = _mlkem.DECAPSKEYBYTES_512,   // 1632-bytes
	.ML_KEM_768 = _mlkem.DECAPSKEYBYTES_768,   // 2400-bytes
	.ML_KEM_1024 = _mlkem.DECAPSKEYBYTES_1024, // 3168-bytes
}

// ENCAPSULATION_KEY_SIZES are the per-parameter sizes of the encapsulation
// key in bytes.
ENCAPSULATION_KEY_SIZES := [Parameters]int {
	.Invalid = 0,
	.ML_KEM_512 = _mlkem.ENCAPSKEYBYTES_512,   // 800-bytes
	.ML_KEM_768 = _mlkem.ENCAPSKEYBYTES_768,   // 1184-bytes
	.ML_KEM_1024 = _mlkem.ENCAPSKEYBYTES_1024, // 1568-bytes
}

// CIPHERTEXT_SIZES are the per-parameter set sizes of the ciphertext
// in bytes.
CIPHERTEXT_SIZES := [Parameters]int {
	.Invalid = 0,
	.ML_KEM_512 = _mlkem.CIPHERTEXTBYTES_512,    // 768-bytes
	.ML_KEM_768 = _mlkem.CIPHERTEXTBYTES_768,    // 1088-bytes
	.ML_KEM_1024 = _mlkem.CIPHERTEXTBYTES_1024,  // 1568-bytes
}

// SHARED_SECRET_SIZE is the size of the final shared secret in bytes.
SHARED_SECRET_SIZE :: 32

// Decapsulation_Key is a ML-KEM decapsulation (aka "private") key.
// This implementation opts to include the encapsulation (aka "public")
// key as well for cases where the decapsulation key is reused (eg: HPKE
// with X-Wing).
Decapsulation_Key :: _mlkem.Decapsulation_Key

// Encapsulation_Key is a ML-KEM encapsulation (aka "public") key.
Encapsulation_Key :: _mlkem.Encapsulation_Key

// decapsulation_key_generate uses the system entropy source to generate
// a decapsulation key.  This will only fail if and only if (⟺) the system
// entropy source is missing or broken.
@(require_results)
decapsulation_key_generate :: proc(dk: ^Decapsulation_Key, params: Parameters) -> bool {
	decapsulation_key_clear(dk)

	if !crypto.HAS_RAND_BYTES {
		return false
	}

	k := params_to_k(params)
	if k == 0 {
		panic("crypto/mlkem: invalid parameter set")
	}

	seed: [DECAPSULATION_KEY_SEED_SIZE]byte = ---
	defer crypto.zero_explicit(&seed, size_of(seed))

	crypto.rand_bytes(seed[:])
	_mlkem.kem_keygen_internal(dk, seed[:], k)

	return true
}

// decapsulation_key_set_bytes decodes a byte-encoded decapsulation key
// in (d, z) "seed" format, and returns true if and only if (⟺) the
// operation was successful.
@(require_results)
decapsulation_key_set_bytes :: proc(dk: ^Decapsulation_Key, params: Parameters, seed: []byte) -> bool {
	k := params_to_k(params)
	if k == 0 {
		return false
	}
	if len(seed) != DECAPSULATION_KEY_SEED_SIZE {
		return false
	}

	_mlkem.kem_keygen_internal(dk, seed, k)

	return true
}

// decapsulation_key_bytes sets dst to byte-encoding of dk in the (d, z)
// "seed" format.
decapsulation_key_bytes :: proc(dk: ^Decapsulation_Key, dst: []byte) {
	ensure(dk.pke_dk.k != 0, "crypto/mlkem: uninitialized Decapsulation_Key")
	ensure(len(dst) == DECAPSULATION_KEY_SEED_SIZE, "crypto/mlkem: invalid destination size")

	copy(dst, dk.seed[:])
}

// decapsulation_key_expanded_bytes sets dst to the  byte-encoding of dk.
// in the expanded FIPS 203 format.  This primarily exists for export
// purposes.
decapsulation_key_expanded_bytes :: proc(dk: ^Decapsulation_Key, dst: []byte) {
	dk_len: int
	switch dk.pke_dk.k {
	case _mlkem.K_512:
		dk_len = DECAPSULATION_KEY_EXPANDED_SIZES[.ML_KEM_512]
	case _mlkem.K_768:
		dk_len = DECAPSULATION_KEY_EXPANDED_SIZES[.ML_KEM_768]
	case _mlkem.K_1024:
		dk_len = DECAPSULATION_KEY_EXPANDED_SIZES[.ML_KEM_1024]
	case:
		panic("crypto/mlkem: uninitialized Decapsulation_Key")
	}
	ensure(len(dst) == dk_len, "crypto/mlkem: invalid destination size")

	_mlkem.decapsulation_key_expanded_bytes(dk, dst)
}

// decapsulation_key_encaps_bytes sets dst to the byte-encoding of the
// encasulation key corresponding to dk.
decapsulation_key_encaps_bytes :: proc(dk: ^Decapsulation_Key, dst: []byte) {
	encapsulation_key_bytes(&dk.ek, dst)
}

// decapsulation_key_clear clears dk to the uninitialized state.
decapsulation_key_clear :: proc(dk: ^Decapsulation_Key) {
	crypto.zero_explicit(dk, size_of(Decapsulation_Key))
}

// encapsulation_key_set_bytes decodes a byte-encoded encapsulation key,
// and returns true if and only if (⟺) the operation was successful.
@(require_results)
encapsulation_key_set_bytes :: proc(ek: ^Encapsulation_Key, params: Parameters, b: []byte) -> bool {
	k := params_to_k(params)
	if k == 0 {
		return false
	}
	if len(b) != ENCAPSULATION_KEY_SIZES[params] {
		return false
	}

	return _mlkem.encapsulation_key_set_bytes(ek, k, b)
}

// encapsulation_key_set_decaps sets ek to the encapsulation key corresponding
// to dk.
encapsulation_key_set_decaps :: proc(ek: ^Encapsulation_Key, dk: ^Decapsulation_Key) {
	ensure(dk.pke_dk.k != 0, "crypto/mlkem: uninitialized Decapsulation_Key")
	_mlkem.encapsulation_key_set_decaps(ek, dk)
}

// encapsulation_key_encaps_bytes sets dst to the byte-encoding of ek.
encapsulation_key_bytes :: proc(ek: ^Encapsulation_Key, dst: []byte) {
	ensure(ek.pke_ek.k != 0, "crypto/mlkem: uninitialized Encapsulation_Key")

	k_len: int
	switch ek.pke_ek.k {
	case _mlkem.K_512:
		k_len = ENCAPSULATION_KEY_SIZES[.ML_KEM_512]
	case _mlkem.K_768:
		k_len = ENCAPSULATION_KEY_SIZES[.ML_KEM_768]
	case _mlkem.K_1024:
		k_len = ENCAPSULATION_KEY_SIZES[.ML_KEM_1024]
	case:
		panic("crypto/mlkem: invalid destination size")
	}

	copy(dst, ek.raw_bytes[:k_len])
}

// encapsulation_key_clear clears ek to the uninitialized state.
encapsulation_key_clear :: proc(ek: ^Encapsulation_Key) {
	crypto.zero_explicit(ek, size_of(Encapsulation_Key))
}

// encaps_raw_ek_bytes uses the byte encoded encapsulation key to generate
// a shared secret and an associated ciphertext.  This routine will fail
// if the system entropy source is unavailable, or of the encapsulation key
// is invalid.
@(require_results)
encaps_ek_raw_bytes :: proc(params: Parameters, raw_ek, shared_secret, ciphertext: []byte) -> bool {
	ek: Encapsulation_Key = ---
	if !encapsulation_key_set_bytes(&ek, params, raw_ek) {
		return false
	}
	defer encapsulation_key_clear(&ek)

	return encaps_ek(&ek, shared_secret, ciphertext)
}

// encaps_ek uses the encapsulation key to generate a shared secret and an
// associated ciphertext.  This routine will fail if the system entropy source
// is unavailable.
@(require_results)
encaps_ek :: proc(ek: ^Encapsulation_Key, shared_secret, ciphertext: []byte) -> bool {
	ensure(len(shared_secret) == SHARED_SECRET_SIZE, "crypto/mlkem: invalid shared_seret size")

	if !crypto.HAS_RAND_BYTES {
		return false
	}

	m: [_mlkem.SYMBYTES]byte = ---
	defer crypto.zero_explicit(&m, size_of(m))

	crypto.rand_bytes(m[:])
	_mlkem.kem_encaps_internal(shared_secret, ciphertext, ek, m[:])

	return true
}

encaps :: proc {
	encaps_ek,
	encaps_ek_raw_bytes,
}

// decaps uses the decapsulation key to generate a shared secret from a
// ciphertext.  Due to ML-KEM's implicit rejection mechanism, this function
// will only return false if and only if (⟺) the lengths of the inputs
// are invalid or the decapsulation key is uninitialized.
//
// This routine returning true does not guarantee that the shared secret
// matches that generated by the peer.
@(require_results)
decaps :: proc(dk: ^Decapsulation_Key, ciphertext, shared_secret: []byte) -> bool {
	ensure(len(shared_secret) == SHARED_SECRET_SIZE, "crypto/mlkem: invalid shared_seret size")

	ct_len: int
	switch dk.pke_dk.k {
	case _mlkem.K_512:
		ct_len = CIPHERTEXT_SIZES[.ML_KEM_512]
	case _mlkem.K_768:
		ct_len = CIPHERTEXT_SIZES[.ML_KEM_768]
	case _mlkem.K_1024:
		ct_len = CIPHERTEXT_SIZES[.ML_KEM_1024]
	case:
		return false
	}
	if len(ciphertext) != ct_len {
		return false
	}

	_mlkem.kem_decaps_internal(shared_secret, dk, ciphertext)

	return true
}

@(private="file")
params_to_k :: #force_inline proc "contextless" (params: Parameters) -> int {
	#partial switch params {
	case .ML_KEM_512:
		return _mlkem.K_512
	case .ML_KEM_768:
		return _mlkem.K_768
	case .ML_KEM_1024:
		return _mlkem.K_1024
	}

	return 0
}
