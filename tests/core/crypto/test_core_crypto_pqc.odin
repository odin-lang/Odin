package test_core_crypto

import "core:bytes"
import "core:fmt"
import "core:log"
import "core:testing"

import "core:crypto"
import "core:crypto/mldsa"
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

@(test)
test_mldsa :: proc(t: ^testing.T) {
	TEST_MSG : string : "ML-DSA test message"
	msg_bytes := transmute([]byte)(TEST_MSG)

	// Test vectors are huge, and are covered by the wycheproof corpus,
	// so do some casual tests.
	for params in mldsa.Parameters {
		if params == .Invalid {
			continue
		}

		seed: [mldsa.PRIVATE_KEY_SEED_SIZE]byte
		fmt.bprintf(seed[:], "odin test - %v", params)

		priv_key: mldsa.Private_Key
		if !testing.expectf(
			t,
			mldsa.private_key_set_bytes(&priv_key, params, seed[:]),
			"%v: private_key_set_bytes",
			params,
		) {
			continue
		}

		sig_det_bytes := make([]byte, mldsa.SIGNATURE_SIZES[params])
		defer delete(sig_det_bytes)

		if !testing.expectf(
			t,
			mldsa.sign(&priv_key, nil, msg_bytes, sig_det_bytes, true),
			"%v: sign (deterministic)",
			params,
		) {
			continue
		}

		pub_key: mldsa.Public_Key
		mldsa.public_key_set_priv(&pub_key, &priv_key)

		if !testing.expectf(
			t,
			mldsa.verify(&pub_key, nil, msg_bytes, sig_det_bytes),
			"%v: verify (deterministic)",
			params,
		) {
			continue
		}

		if !crypto.HAS_RAND_BYTES {
			continue
		}

		sig_hedged_bytes := make([]byte, mldsa.SIGNATURE_SIZES[params])
		defer delete(sig_hedged_bytes)

		if !testing.expectf(
			t,
			mldsa.sign(&priv_key, nil, msg_bytes, sig_hedged_bytes),
			"%v: sign (hedged)",
			params,
		) {
			continue
		}

		if !testing.expectf(
			t,
			mldsa.verify(&pub_key, nil, msg_bytes, sig_hedged_bytes),
			"%v: verify (hedged)",
			params,
		) {
			continue
		}

		// False positive rate of 1/(2^256), assuming a functional
		// entropy source.
		testing.expectf(
			t,
			!bytes.equal(sig_det_bytes, sig_hedged_bytes),
			"%v: deterministic sig should not equal hedged",
			params,
		)
	}
}
