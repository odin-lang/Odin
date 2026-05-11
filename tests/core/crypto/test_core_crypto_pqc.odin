package test_core_crypto

import "core:bytes"
import "core:log"
import "core:testing"

import "core:crypto"
import "core:crypto/mlkem"

@(test)
test_mlkem :: proc(t: ^testing.T) {
	if !crypto.HAS_RAND_BYTES {
		log.info("rand_bytes not supported - skipping")
		return
	}

	// Test vectors are huge, and are covered by the wycheproof corpus,
	// so just test a full key exchange with all supported parameter
	// sets.
	for params in mlkem.Parameters {
		if params == .Invalid {
			continue
		}

		// Alice
		decaps_key: mlkem.Decapsulation_Key
		if !testing.expectf(
			t,
			mlkem.decapsulation_key_generate(&decaps_key, params),
			"%v: decapsulation_key_generate",
			params,
		) {
			continue
		}
		defer mlkem.decapsulation_key_clear(&decaps_key)

		ek_bytes := make([]byte, mlkem.ENCAPSULATION_KEY_SIZES[params])
		defer delete(ek_bytes)
		mlkem.decapsulation_key_encaps_bytes(&decaps_key, ek_bytes)

		// Bob
		bob_shared_secret: [mlkem.SHARED_SECRET_SIZE]byte
		ciphertext := make([]byte, mlkem.CIPHERTEXT_SIZES[params])
		defer delete(ciphertext)
		if !testing.expectf(
			t,
			mlkem.encaps(params, ek_bytes, bob_shared_secret[:], ciphertext),
			"%v: encaps",
			params,
		) {
			continue
		}

		// Alice
		alice_shared_secret: [mlkem.SHARED_SECRET_SIZE]byte
		if !testing.expectf(
			t,
			mlkem.decaps(&decaps_key, ciphertext, alice_shared_secret[:]),
			"%v: decaps",
			params,
		) {
			continue
		}

		testing.expectf(
			t,
			bytes.equal(alice_shared_secret[:], bob_shared_secret[:]),
			"%v: shared secret mismatch",
			params,
		)
	}
}
