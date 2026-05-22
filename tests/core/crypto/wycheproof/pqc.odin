package test_wycheproof

import "core:encoding/hex"
import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "core:testing"

import "core:crypto/_mlkem"
import "core:crypto/mlkem"

import "core:crypto/_mldsa"
import "core:crypto/mldsa"

import "../common"

@(test)
test_mlkem :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("mlkem: starting")

	files_keygen := []string {
		"mlkem_512_keygen_seed_test.json",
		"mlkem_768_keygen_seed_test.json",
		"mlkem_1024_keygen_seed_test.json",
	}
	for f in files_keygen {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Kem_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_mlkem_keygen(t, &test_vectors), "ML-KEM KeyGen failed")
	}

	files_encaps := []string {
		"mlkem_512_encaps_test.json",
		"mlkem_768_encaps_test.json",
		"mlkem_1024_encaps_test.json",
	}
	for f in files_encaps {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Kem_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_mlkem_encaps(t, &test_vectors), "ML-KEM Encaps failed")
	}

	files_decaps := []string {
		"mlkem_512_test.json",
		"mlkem_768_test.json",
		"mlkem_1024_test.json",
	}
	for f in files_decaps {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Kem_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_mlkem_decaps(t, &test_vectors), "ML-KEM Decaps failed")
	}
}

test_mlkem_keygen :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Kem_Test_Group)) -> bool {
	params_str := test_vectors.test_groups[0].parameter_set
	params := mlkem_parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: KeyGen starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/KeyGen/%d/%d: %s: %+v",
					params_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/KeyGen/%d/%d: %+v", params_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			seed := common.hexbytes_decode(test_vector.seed)

			dk: mlkem.Decapsulation_Key
			if !testing.expectf(
				t,
				mlkem.decapsulation_key_set_bytes(&dk, params, seed),
				"%s/KeyGen/%d/%d: failed to set decapsulation key from seed: %s",
				params_str,
				tg_id,
				test_vector.tc_id,
				test_vector.seed,
			) {
				num_failed += 1
				continue
			}

			ek_bytes := make([]byte, mlkem.ENCAPSULATION_KEY_SIZES[params])
			mlkem.decapsulation_key_encaps_bytes(&dk, ek_bytes)

			ok := common.hexbytes_compare(test_vector.ek, ek_bytes)
			if !result_check(test_vector.result, ok) {
				x := transmute(string)(hex.encode(ek_bytes))
				log.errorf(
					"%s/KeyGen/%d/%d: ek: expected %s actual %s",
					params_str,
					tg_id,
					test_vector.tc_id,
					test_vector.ek,
					x,
				)
				num_failed += 1
				continue
			}

			dk_bytes := make([]byte, mlkem.DECAPSULATION_KEY_EXPANDED_SIZES[params])
			mlkem.decapsulation_key_expanded_bytes(&dk, dk_bytes)

			ok = common.hexbytes_compare(test_vector.dk, dk_bytes)
			if !result_check(test_vector.result, ok) {
				x := transmute(string)(hex.encode(dk_bytes))
				log.errorf(
					"%s/KeyGen/%d/%d: dk: expected %s actual %s",
					tg_id,
					params_str,
					test_vector.tc_id,
					test_vector.dk,
					x,
				)
				num_failed += 1
				continue
			}

			seed_bytes: [mlkem.DECAPSULATION_KEY_SEED_SIZE]byte
			mlkem.decapsulation_key_bytes(&dk, seed_bytes[:])

			ok = common.hexbytes_compare(test_vector.seed, seed_bytes[:])
			if !result_check(test_vector.result, ok) {
				x := transmute(string)(hex.encode(seed_bytes[:]))
				log.errorf(
					"%s/KeyGen/%d/%d: seed: expected %s actual %s",
					tg_id,
					params_str,
					test_vector.tc_id,
					test_vector.seed,
					x,
				)
				num_failed += 1
				continue
			}

			num_passed += 1
		}
	}

	assert(num_ran == test_vectors.number_of_tests)
	assert(num_passed + num_failed + num_skipped == num_ran)

	log.infof(
		"%s/KeyGen: ran %d, passed %d, failed %d, skipped %d",
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

test_mlkem_encaps :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Kem_Test_Group)) -> bool {
	params_str := test_vectors.test_groups[0].parameter_set
	params := mlkem_parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: Encaps starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/Encaps/%d/%d: %s: %+v",
					params_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/Encaps/%d/%d: %+v", params_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			ek: mlkem.Encapsulation_Key
			ok := mlkem.encapsulation_key_set_bytes(
				&ek,
				params,
				common.hexbytes_decode(test_vector.ek),
			)

			// The current corpus can only fail if the encapsulation key
			// is malformed in some way.
			if !result_check(test_vector.result, ok) {
				log.errorf(
					"%s/Encaps/%d/%d: unexpected set encapsulation key from bytes: %s (%v != %v)",
					params_str,
					tg_id,
					test_vector.tc_id,
					test_vector.ek,
					test_vector.result,
					ok,
				)
				num_failed += 1
				continue
			}
			if !ok {
				num_passed += 1
				continue
			}

			shared_secret: [mlkem.SHARED_SECRET_SIZE]byte
			ciphertext := make([]byte, mlkem.CIPHERTEXT_SIZES[params])

			_mlkem.kem_encaps_internal(
				shared_secret[:],
				ciphertext,
				&ek,
				common.hexbytes_decode(test_vector.m),
			)

			ok = common.hexbytes_compare(test_vector.c, ciphertext)
			if !ok {
				x := transmute(string)(hex.encode(ciphertext))
				log.errorf(
					"%s/Encaps/%d/%d: ciphertext: expected: %s actual: %s",
					params_str,
					tg_id,
					test_vector.tc_id,
					test_vector.c,
					x,
				)
				num_failed += 1
				continue
			}

			ok = common.hexbytes_compare(test_vector.k, shared_secret[:])
			if !ok {
				x := transmute(string)(hex.encode(shared_secret[:]))
				log.errorf(
					"%s/Encaps/%d/%d: shared_secret: expected: %s actual: %s",
					params_str,
					tg_id,
					test_vector.tc_id,
					test_vector.k,
					x,
				)
				num_failed += 1
				continue
			}

			num_passed += 1
		}
	}

	assert(num_ran == test_vectors.number_of_tests)
	assert(num_passed + num_failed + num_skipped == num_ran)

	log.infof(
		"%s/Encaps: ran %d, passed %d, failed %d, skipped %d",
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

test_mlkem_decaps :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Kem_Test_Group)) -> bool {
	params_str := test_vectors.test_groups[0].parameter_set
	params := mlkem_parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: Decaps starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/Decaps/%d/%d: %s: %+v",
					params_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/Decaps/%d/%d: %+v", params_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			// We do not have an API for decaps with raw seed.
			seed := common.hexbytes_decode(test_vector.seed)
			switch len(seed) {
			case mlkem.DECAPSULATION_KEY_SEED_SIZE:
			case:
				if testing.expectf(
					t,
					result_is_invalid(test_vector.result),
					"%s/Decaps/%d/%d: test vector expects success with invalid seed",
					params_str,
					tg_id,
					test_vector.tc_id,
				) {
					num_passed += 1
				} else {
					num_failed += 1
				}
				continue
			}

			dk: mlkem.Decapsulation_Key
			if !testing.expectf(
				t,
				mlkem.decapsulation_key_set_bytes(&dk, params, seed),
				"%s/Decaps/%d/%d: failed to set decapsulation key from seed",
				params_str,
				tg_id,
				test_vector.tc_id,
				test_vector.seed,
			) {
				num_failed *= 1
				continue
			}

			shared_secret: [mlkem.SHARED_SECRET_SIZE]byte

			ok := mlkem.decaps(
				&dk,
				common.hexbytes_decode(test_vector.c),
				shared_secret[:],
			)
			if !result_check(test_vector.result, ok) {
				log.errorf(
					"%s/Decaps/%d/%d: unexpected decapsulation failure",
					params_str,
					tg_id,
					test_vector.tc_id,
				)
				num_failed += 1
				continue
			}
			if !ok {
				num_passed += 1
				continue
			}

			ok = common.hexbytes_compare(test_vector.k, shared_secret[:])
			if !ok {
				x := transmute(string)(hex.encode(shared_secret[:]))
				log.errorf(
					"%s/Decaps/%d/%d: shared_secret: expected: %s actual: %s",
					params_str,
					tg_id,
					test_vector.tc_id,
					test_vector.k,
					x,
				)
				num_failed += 1
				continue
			}

			num_passed += 1
		}
	}

	assert(num_ran == test_vectors.number_of_tests)
	assert(num_passed + num_failed + num_skipped == num_ran)

	log.infof(
		"%s/Decaps: ran %d, passed %d, failed %d, skipped %d",
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

@(require_results,private="file")
mlkem_parameter_set_to_params :: proc(s: string) -> mlkem.Parameters {
	switch s {
	case "ML-KEM-512":
		return .ML_KEM_512
	case "ML-KEM-768":
		return .ML_KEM_768
	case "ML-KEM-1024":
		return .ML_KEM_1024
	case:
		return .Invalid
	}
}

@(test)
test_mldsa :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("mldsa: starting")

	files_sign := []string {
		"mldsa_44_sign_seed_test.json",
		"mldsa_65_sign_seed_test.json",
		"mldsa_87_sign_seed_test.json",
	}
	for f in files_sign {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Mldsa_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_mldsa_sign(t, &test_vectors), "ML-DSA Sign failed")
	}

	files_verify := []string {
		"mldsa_44_verify_test.json",
		"mldsa_65_verify_test.json",
		"mldsa_87_verify_test.json",
	}
	for f in files_verify {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Mldsa_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_mldsa_verify(t, &test_vectors), "ML-DSA Verify failed")
	}
}

test_mldsa_sign :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Mldsa_Test_Group)) -> bool {
	FLAG_INTERNAL :: "Internal"

	dummy_rnd: [_mldsa.RNDBYTES]byte

	params_str := test_vectors.algorithm
	params := mldsa_parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: Sign starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		seed := common.hexbytes_decode(test_group.private_seed)
		priv_key: mldsa.Private_Key

		tg_len := len(test_group.tests)
		if !testing.expectf(
			t,
			mldsa.private_key_set_bytes(&priv_key, params, seed),
			"%s/Sign/%d: failed to set private key from seed: %s",
			params_str,
			tg_id,
			test_group.private_seed,
		) {
			num_ran += tg_len
			num_failed += tg_len
			continue
		}

		pub_bytes := make([]byte, mldsa.PUBLIC_KEY_SIZES[params])
		mldsa.private_key_public_bytes(&priv_key, pub_bytes)

		ok := common.hexbytes_compare(test_group.public_key, pub_bytes)
		if !ok {
			x := transmute(string)(hex.encode(pub_bytes[:]))
			log.errorf(
				"%s/Sign/%d: public key: expected: %s actual: %s",
				params_str,
				tg_id,
				test_group.public_key,
				x,
			)
			num_ran += tg_len
			num_failed += tg_len
			continue
		}

		pub_key: mldsa.Public_Key
		if !testing.expectf(
			t,
			mldsa.public_key_set_bytes(&pub_key, params, pub_bytes),
			"%s/Sign/%d: failed to set public key",
			params_str,
			tg_id,
		) {
			num_ran += tg_len
			num_failed += tg_len
			continue
		}

		sig := make([]byte, mldsa.SIGNATURE_SIZES[params])
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/Sign/%d/%d: %s: %+v",
					params_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/Sign/%d/%d: %+v", params_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			ctx := common.hexbytes_decode(test_vector.ctx)
			msg := common.hexbytes_decode(test_vector.msg)

			is_external_mu := slice.contains(test_vector.flags, FLAG_INTERNAL)
			switch is_external_mu {
			case false:
				ok = mldsa.sign(
					&priv_key,
					ctx,
					msg,
					sig,
					true,
				)
			case true:
				ok = _mldsa.dsa_sign_internal(
					sig,
					msg,
					ctx,
					dummy_rnd[:],
					&priv_key,
					common.hexbytes_decode(test_vector.mu),
				)
			}
			if !result_check(test_vector.result, ok) {
				log.errorf(
					"%s/Sign/%d/%d: unexpected sign result: %v",
					params_str,
					tg_id,
					test_vector.tc_id,
					ok,
				)
				num_failed += 1
				continue
			}
			if result_is_invalid(test_vector.result) {
				num_passed += 1
				continue
			}

			ok = common.hexbytes_compare(test_vector.sig, sig)
			if !ok {
				x := transmute(string)(hex.encode(sig))
				log.errorf(
					"%s/Sign/%d/%d: sign: expected: %s actual: %s",
					params_str,
					tg_id,
					test_vector.tc_id,
					test_vector.sig,
					x,
				)
				num_failed += 1
				continue
			}

			// Might as well verify as well if we have the ctx/msg.
			if !is_external_mu {
				if !testing.expectf(
					t,
					mldsa.verify(&pub_key, ctx, msg, sig),
					"%s/Sign/%d/%d: verify failed",
					params_str,
					tg_id,
					test_vector.tc_id,
				) {
					num_failed += 1
					continue
				}
			}

			num_passed += 1
		}
	}

	assert(num_ran == test_vectors.number_of_tests)
	assert(num_passed + num_failed + num_skipped == num_ran)

	log.infof(
		"%s/Sign: ran %d, passed %d, failed %d, skipped %d",
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

test_mldsa_verify:: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Mldsa_Test_Group)) -> bool {
	params_str := test_vectors.algorithm
	params := mldsa_parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: Verify starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		tg_len := len(test_group.tests)

		pub_key_bytes := common.hexbytes_decode(test_group.public_key)
		pub_key: mldsa.Public_Key

		expected := len(pub_key_bytes) == mldsa.PUBLIC_KEY_SIZES[params]
		ok := mldsa.public_key_set_bytes(&pub_key, params, pub_key_bytes)
		if !testing.expectf(
			t,
			ok == expected,
			"%s/Verify/%d: failed to set public key",
			params_str,
			tg_id,
		) {
			num_ran += tg_len
			num_failed += tg_len
			continue
		}
		if expected == false {
			num_ran += tg_len
			num_passed += tg_len
			continue
		}

		for &test_vector in test_group.tests {
			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/Verify/%d/%d: %s: %+v",
					params_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/Verify/%d/%d: %+v", params_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			num_ran += 1

			ctx := common.hexbytes_decode(test_vector.ctx)
			msg := common.hexbytes_decode(test_vector.msg)
			sig := common.hexbytes_decode(test_vector.sig)

			ok = mldsa.verify(&pub_key, ctx, msg, sig)
			if !result_check(test_vector.result, ok) {
				log.errorf(
					"%s/Verify/%d/%d: unexpected verify result: %v",
					params_str,
					tg_id,
					test_vector.tc_id,
					ok,
				)
				num_failed += 1
				continue
			}

			num_passed += 1
		}
	}

	assert(num_ran == test_vectors.number_of_tests)
	assert(num_passed + num_failed + num_skipped == num_ran)

	log.infof(
		"%s/Verify: ran %d, passed %d, failed %d, skipped %d",
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

@(require_results,private="file")
mldsa_parameter_set_to_params :: proc(s: string) -> mldsa.Parameters {
	switch s {
	case "ML-DSA-44":
		return .ML_DSA_44
	case "ML-DSA-65":
		return .ML_DSA_65
	case "ML-DSA-87":
		return .ML_DSA_87
	case:
		return .Invalid
	}
}
