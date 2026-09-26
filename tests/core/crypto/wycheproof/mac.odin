package test_wycheproof

import "core:encoding/hex"

import "core:log"
import "core:mem"
import "core:os"
import "core:testing"

import "core:crypto/hmac"
import "core:crypto/kmac"
import "core:crypto/siphash"

import "../common"

@(test)
test_mac :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("mac: starting")

	files := []string {
		"hmac_sha1_test.json",
		"hmac_sha224_test.json",
		"hmac_sha256_test.json",
		"hmac_sha3_224_test.json",
		"hmac_sha3_256_test.json",
		"hmac_sha3_384_test.json",
		"hmac_sha3_512_test.json",
		"hmac_sha384_test.json",
		// "hmac_sha512_224_test.json",
		"hmac_sha512_256_test.json",
		"hmac_sha512_test.json",
		"hmac_sm3_test.json",
		"kmac128_no_customization_test.json",
		"kmac256_no_customization_test.json",
		"siphash_1_3_test.json",
		"siphash_2_4_test.json",
		"siphash_4_8_test.json",
	}

	for f in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Mac_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_mac_impl(&test_vectors), "hkdf failed")
	}
}

test_mac_impl :: proc(test_vectors: ^Test_Vectors(Mac_Test_Group)) -> bool {
	PREFIX_HMAC :: "HMAC"
	PREFIX_KMAC :: "KMAC"

	mac_alg, hmac_alg, alg_str, ok := mac_algorithm(test_vectors.algorithm)
	if !ok {
		log.errorf("mac: unsupported algorith: %s", test_vectors.algorithm)
		return false
	}

	log.debugf("%s: starting", alg_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/%d: %s: %+v",
					alg_str,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/%d: %+v", alg_str, test_vector.tc_id, test_vector.flags)
			}

			key := common.hexbytes_decode(test_vector.key)
			msg := common.hexbytes_decode(test_vector.msg)

			tag_ := make([]byte, len(test_vector.tag) / 2)

			#partial switch mac_alg {
			case .HMAC:
				ctx: hmac.Context
				hmac.init(&ctx, hmac_alg, key)
				hmac.update(&ctx, msg)
				if l := hmac.tag_size(&ctx); l == len(tag_) {
					hmac.final(&ctx, tag_)
				} else {
					// Our hmac package does not support truncation.
					tmp := make([]byte, l)
					hmac.final(&ctx, tmp)
					copy(tag_, tmp)
				}
			case .KMAC128, .KMAC256:
				ctx: kmac.Context
				#partial switch mac_alg {
				case .KMAC128:
					kmac.init_128(&ctx, key, nil)
				case .KMAC256:
					kmac.init_256(&ctx, key, nil)
				}
				kmac.update(&ctx, msg)
				kmac.final(&ctx, tag_)
			case .SIPHASH_1_3:
				siphash.sum_1_3(msg, key, tag_)
			case .SIPHASH_2_4:
				siphash.sum_2_4(msg, key, tag_)
			case .SIPHASH_4_8:
				siphash.sum_4_8(msg, key, tag_)
			}

			ok = common.hexbytes_compare(test_vector.tag, tag_)
			if !result_check(test_vector.result, ok) {
				x := transmute(string)(hex.encode(tag_))
				log.errorf(
					"%s/%d: tag: expected %s actual %s",
					alg_str,
					test_vector.tc_id,
					test_vector.tag,
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
		"%s: ran %d, passed %d, failed %d, skipped %d",
		alg_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}
