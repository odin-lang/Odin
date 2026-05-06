package test_wycheproof

import "core:encoding/hex"
import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"

import "core:crypto/hkdf"
import "core:crypto/pbkdf2"

import "../common"

@(test)
test_hkdf :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("hkdf: starting")

	files := []string {
		"hkdf_sha1_test.json",
		"hkdf_sha256_test.json",
		"hkdf_sha384_test.json",
		"hkdf_sha512_test.json",
	}

	for f in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Hkdf_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_hkdf_impl(&test_vectors), "hkdf failed")
	}
}

test_hkdf_impl :: proc(test_vectors: ^Test_Vectors(Hkdf_Test_Group)) -> bool {
	PREFIX_HKDF :: "HKDF-"
	FLAG_SIZE_TOO_LARGE :: "SizeTooLarge"

	alg_str := strings.trim_prefix(test_vectors.algorithm, PREFIX_HKDF)
	alg, ok := hash_name_to_algorithm(alg_str)
	if !ok {
		return false
	}
	alg_str = strings.to_lower(alg_str)

	log.debugf("hkdf/%s: starting", alg_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"hkdf/%s/%d: %s: %+v",
					alg_str,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("hkdf/%s/%d: %+v", alg_str, test_vector.tc_id, test_vector.flags)
			}

			ikm := common.hexbytes_decode(test_vector.ikm)
			salt := common.hexbytes_decode(test_vector.salt)
			info := common.hexbytes_decode(test_vector.info)

			if slice.contains(test_vector.flags, FLAG_SIZE_TOO_LARGE) {
				log.infof(
					"hkdf/%s/%d: skipped, oversized outputs panic",
					alg_str,
					test_vector.tc_id,
				)
				num_skipped += 1
				continue
			}

			okm_ := make([]byte, test_vector.size)
			hkdf.extract_and_expand(alg, salt, ikm, info, okm_)

			ok = common.hexbytes_compare(test_vector.okm, okm_)
			if !result_check(test_vector.result, ok) {
				x := transmute(string)(hex.encode(okm_))
				log.errorf(
					"hkdf/%s/%d: shared: expected %s actual %s",
					alg_str,
					test_vector.tc_id,
					test_vector.okm,
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
		"hkdf/%s: ran %d, passed %d, failed %d, skipped %d",
		alg_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

@(test)
test_pbkdf2 :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("pbkdf2: starting")

	files := []string {
		"pbkdf2_hmacsha1_test.json",
		"pbkdf2_hmacsha224_test.json",
		"pbkdf2_hmacsha256_test.json",
		"pbkdf2_hmacsha384_test.json",
		"pbkdf2_hmacsha512_test.json",
	}

	for f in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Pbkdf_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_pbkdf2_impl(&test_vectors), "pbkdf2 failed")
	}
}

test_pbkdf2_impl :: proc(
	test_vectors: ^Test_Vectors(Pbkdf_Test_Group),
) -> bool {
	PREFIX_PBKDF_HMAC :: "PBKDF2-HMAC"
	FLAG_LARGE_ITERATION_COUNT :: "LargeIterationCount"

	alg_str := strings.trim_prefix(test_vectors.algorithm, PREFIX_PBKDF_HMAC)
	alg, ok := hash_name_to_algorithm(alg_str)
	if !ok {
		return false
	}
	alg_str = strings.to_lower(alg_str)

	log.debugf("pbkdf2/hmac-%s: starting", alg_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"pbkdf2/hmac-%s/%d: %s: %+v",
					alg_str,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("pbkdf2/hmac-%s/%d: %+v", alg_str, test_vector.tc_id, test_vector.flags)
			}

			if slice.contains(test_vector.flags, FLAG_LARGE_ITERATION_COUNT) {
				log.infof(
					"pbkdf2/hmac-%s/%d: skipped, takes fucking forever",
					alg_str,
					test_vector.tc_id,
				)
				num_skipped += 1
				continue
			}

			password := common.hexbytes_decode(test_vector.password)
			salt := common.hexbytes_decode(test_vector.salt)

			dk_ := make([]byte, test_vector.dk_len)
			pbkdf2.derive(alg, password, salt, test_vector.iteration_count, dk_)

			ok = common.hexbytes_compare(test_vector.dk, dk_)
			if !result_check(test_vector.result, ok) {
				x := transmute(string)(hex.encode(dk_))
				log.errorf(
					"pbkdf2/hmac-%s/%d: shared: expected %s actual %s",
					alg_str,
					test_vector.tc_id,
					test_vector.dk,
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
		"pbkdf2/%s: ran %d, passed %d, failed %d, skipped %d",
		alg_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}
