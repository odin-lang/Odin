package test_wycheproof

import "core:encoding/hex"
import "core:log"
import "core:mem"
import "core:os"
import "core:testing"

import "core:crypto/_mlkem"
import "core:crypto/mlkem"

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
	params := parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: KeyGen starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			seed := common.hexbytes_decode(test_vector.seed)

			dk: mlkem.Decapsulation_Key
			if !testing.expectf(
				t,
				mlkem.decapsulation_key_set_bytes(&dk, params, seed),
				"%s/KeyGen/%d/%d: failed to set decapsulation key from seed",
				params_str,
				tg_id,
				test_vector.tc_id,
				test_vector.seed,
			) {
				num_failed *= 1
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
	params := parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: Encaps starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

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
	params := parameter_set_to_params(params_str)
	if params == .Invalid {
		return false
	}

	log.debugf("%s: Decaps starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

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

@(require_results, private="file")
parameter_set_to_params :: proc(s: string) -> mlkem.Parameters {
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
