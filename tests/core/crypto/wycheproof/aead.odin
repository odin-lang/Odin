package test_wycheproof

import "core:encoding/hex"
import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "core:testing"

import chacha_simd128 "core:crypto/_chacha20/simd128"
import chacha_simd256 "core:crypto/_chacha20/simd256"
import "core:crypto/aegis"
import "core:crypto/aes"
import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"

import "../common"

supported_aegis_impls :: proc() -> [dynamic]aes.Implementation {
	impls := make([dynamic]aes.Implementation, 0, 2, context.temp_allocator)
	append(&impls, aes.Implementation.Portable)
	if aegis.is_hardware_accelerated() {
		append(&impls, aes.Implementation.Hardware)
	}

	return impls
}

@(test)
test_aead_aegis :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	files := []string {
		"aegis128L_test.json",
		"aegis256_test.json",
	}

	log.debug("aead/aegis: starting")

	for f in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Aead_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		for impl in supported_aegis_impls() {
			testing.expectf(t, test_aead_aegis_impl(&test_vectors, impl), "impl {} failed", impl)
		}
	}
}

test_aead_aegis_impl :: proc(
	test_vectors: ^Test_Vectors(Aead_Test_Group),
	impl: aes.Implementation,
) -> bool {
	log.debug("aead/aegis/%v: starting", impl)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"aead/aegis/%v/%d: %s: %+v",
					impl,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("aead/aegis/%v/%d: %+v",
					impl,
					test_vector.tc_id,
					test_vector.flags,
				)
			}

			key := common.hexbytes_decode(test_vector.key)
			iv := common.hexbytes_decode(test_vector.iv)
			aad := common.hexbytes_decode(test_vector.aad)
			msg := common.hexbytes_decode(test_vector.msg)
			ct := common.hexbytes_decode(test_vector.ct)
			tag := common.hexbytes_decode(test_vector.tag)

			if len(iv) == 0 {
				log.infof(
					"aead/aegis/%v/%d: skipped, invalid IVs panic",
					impl,
					test_vector.tc_id,
				)
				num_skipped += 1
				continue
			}

			ctx: aegis.Context
			aegis.init(&ctx, key, impl)

			if result_is_valid(test_vector.result) {
				ct_ := make([]byte, len(ct))
				tag_ := make([]byte, len(tag))
				aegis.seal(&ctx, ct_, tag_, iv, aad, msg)

				ok := common.hexbytes_compare(test_vector.ct, ct_)
				if !result_check(test_vector.result, ok) {
					x := transmute(string)(hex.encode(ct_))
					log.errorf(
						"aead/aegis/%v/%d: ciphertext: expected %s actual %s",
						impl,
						test_vector.tc_id,
						test_vector.ct,
						x,
					)
					num_failed += 1
					continue
				}

				ok = common.hexbytes_compare(test_vector.tag, tag_)
				if !result_check(test_vector.result, ok) {
					x := transmute(string)(hex.encode(tag_))
					log.errorf(
						"aead/aegis/%v/%d: tag: expected %s actual %s",
						impl,
						test_vector.tc_id,
						test_vector.tag,
						x,
					)
					num_failed += 1
					continue
				}
			}

			msg_ := make([]byte, len(msg))
			ok := aegis.open(&ctx, msg_, iv, aad, ct, tag)
			if !result_check(test_vector.result, ok) {
				log.errorf("aead/aegis/%v/%d: decrypt failed", impl, test_vector.tc_id)
				num_failed += 1
				continue
			}

			if ok && !common.hexbytes_compare(test_vector.msg, msg_) {
				x := transmute(string)(hex.encode(msg_))
				log.errorf(
					"aead/aegis/%v/%d: decrypt msg: expected %s actual %s",
					impl,
					test_vector.tc_id,
					test_vector.msg,
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
		"aead/aegis: ran %d, passed %d, failed %d, skipped %d",
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

supported_aes_impls :: proc() -> [dynamic]aes.Implementation {
	impls := make([dynamic]aes.Implementation, 0, 2)
	append(&impls, aes.Implementation.Portable)
	if aes.is_hardware_accelerated() {
		append(&impls, aes.Implementation.Hardware)
	}

	return impls
}

@(test)
test_aead_aes_gcm :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	fn, _ := os.join_path([]string{BASE_PATH, "aes_gcm_test.json"}, context.allocator)

	log.debug("aead/aes-gcm: starting")

	test_vectors: Test_Vectors(Aead_Test_Group)
	if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", fn) {
		return
	}

	for impl in supported_aes_impls() {
		testing.expectf(t, test_aead_aes_gcm_impl(&test_vectors, impl), "impl {} failed", impl)
	}
}

test_aead_aes_gcm_impl :: proc(
	test_vectors: ^Test_Vectors(Aead_Test_Group),
	impl: aes.Implementation,
) -> bool {
	log.debug("aead/aes-gcm/%v: starting", impl)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"aead/aes-gcm/%v/%d: %s: %+v",
					impl,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("aead/aes-gcm/%v/%d: %+v",
					impl,
					test_vector.tc_id,
					test_vector.flags,
				)
			}

			key := common.hexbytes_decode(test_vector.key)
			iv := common.hexbytes_decode(test_vector.iv)
			aad := common.hexbytes_decode(test_vector.aad)
			msg := common.hexbytes_decode(test_vector.msg)
			ct := common.hexbytes_decode(test_vector.ct)
			tag := common.hexbytes_decode(test_vector.tag)

			if len(iv) == 0 {
				log.infof(
					"aead/aes-gcm/%v/%d: skipped, invalid IVs panic",
					impl,
					test_vector.tc_id,
				)
				num_skipped += 1
				continue
			}

			ctx: aes.Context_GCM
			aes.init_gcm(&ctx, key, impl)

			if result_is_valid(test_vector.result) {
				ct_ := make([]byte, len(ct))
				tag_ := make([]byte, len(tag))
				aes.seal_gcm(&ctx, ct_, tag_, iv, aad, msg)

				ok := common.hexbytes_compare(test_vector.ct, ct_)
				if !result_check(test_vector.result, ok) {
					x := transmute(string)(hex.encode(ct_))
					log.errorf(
						"aead/aes-gcm/%v/%d: ciphertext: expected %s actual %s",
						impl,
						test_vector.tc_id,
						test_vector.ct,
						x,
					)
					num_failed += 1
					continue
				}

				ok = common.hexbytes_compare(test_vector.tag, tag_)
				if !result_check(test_vector.result, ok) {
					x := transmute(string)(hex.encode(tag_))
					log.errorf(
						"aead/aes-gcm/%v/%d: tag: expected %s actual %s",
						impl,
						test_vector.tc_id,
						test_vector.tag,
						x,
					)
					num_failed += 1
					continue
				}
			}

			msg_ := make([]byte, len(msg))
			ok := aes.open_gcm(&ctx, msg_, iv, aad, ct, tag)
			if !result_check(test_vector.result, ok) {
				log.errorf("aead/aes-gcm/%v/%d: decrypt failed", impl, test_vector.tc_id)
				num_failed += 1
				continue
			}

			if ok && !common.hexbytes_compare(test_vector.msg, msg_) {
				x := transmute(string)(hex.encode(msg_))
				log.errorf(
					"aead/aes-gcm/%v/%d: decrypt msg: expected %s actual %s",
					impl,
					test_vector.tc_id,
					test_vector.msg,
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
		"aead/aes-gcm: ran %d, passed %d, failed %d, skipped %d",
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

supported_chacha_impls :: proc() -> [dynamic]chacha20.Implementation {
	impls := make([dynamic]chacha20.Implementation, 0, 3)
	append(&impls, chacha20.Implementation.Portable)
	if chacha_simd128.is_performant() {
		append(&impls, chacha20.Implementation.Simd128)
	}
	if chacha_simd256.is_performant() {
		append(&impls, chacha20.Implementation.Simd256)
	}

	return impls
}

@(test)
test_aead_chacha20_poly1305 :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	files := []string {
		"chacha20_poly1305_test.json",
		"xchacha20_poly1305_test.json",
	}

	log.debug("aead/(x)chacha20poly1305: starting")

	for f, i in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Aead_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		for impl in supported_chacha_impls() {
			testing.expectf(t, test_aead_chacha20_poly1305_impl(&test_vectors, i == 1, impl), "impl {} failed", impl)
		}
	}
}

test_aead_chacha20_poly1305_impl :: proc(
	test_vectors: ^Test_Vectors(Aead_Test_Group),
	is_xchacha: bool,
	impl: chacha20.Implementation,
) -> bool {
	FLAG_INVALID_NONCE_SIZE :: "InvalidNonceSize"

	alg_str := is_xchacha ? "xchacha20poly1305" : "chacha20poly1305"

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"aead/%s/%v/%d: %s: %+v",
					alg_str,
					impl,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("aead/%s/%v/%d: %+v",
					alg_str,
					impl,
					test_vector.tc_id,
					test_vector.flags,
				)
			}

			key := common.hexbytes_decode(test_vector.key)
			iv := common.hexbytes_decode(test_vector.iv)
			aad := common.hexbytes_decode(test_vector.aad)
			msg := common.hexbytes_decode(test_vector.msg)
			ct := common.hexbytes_decode(test_vector.ct)
			tag := common.hexbytes_decode(test_vector.tag)

			if slice.contains(test_vector.flags, FLAG_INVALID_NONCE_SIZE) {
				log.infof(
					"aead/%s/%v/%d: skipped, invalid nonces panic",
					alg_str,
					impl,
					test_vector.tc_id,
				)
				num_skipped += 1
				continue
			}

			ctx: chacha20poly1305.Context
			switch is_xchacha {
			case true:
				chacha20poly1305.init_xchacha(&ctx, key, impl)
			case false:
				chacha20poly1305.init(&ctx, key, impl)
			}

			if result_is_valid(test_vector.result) {
				ct_ := make([]byte, len(ct))
				tag_ := make([]byte, len(tag))
				chacha20poly1305.seal(&ctx, ct_, tag_, iv, aad, msg)

				ok := common.hexbytes_compare(test_vector.ct, ct_)
				if !result_check(test_vector.result, ok) {
					x := transmute(string)(hex.encode(ct_))
					log.errorf(
						"aead/%s/%v/%d: ciphertext: expected %s actual %s",
						alg_str,
						impl,
						test_vector.tc_id,
						test_vector.ct,
						x,
					)
					num_failed += 1
					continue
				}

				ok = common.hexbytes_compare(test_vector.tag, tag_)
				if !result_check(test_vector.result, ok) {
					x := transmute(string)(hex.encode(tag_))
					log.errorf(
						"aead/%s/%v/%d: tag: expected %s actual %s",
						alg_str,
						impl,
						test_vector.tc_id,
						test_vector.tag,
						x,
					)
					num_failed += 1
					continue
				}
			}

			msg_ := make([]byte, len(msg))
			ok := chacha20poly1305.open(&ctx, msg_, iv, aad, ct, tag)
			if !result_check(test_vector.result, ok) {
				log.errorf("aead/%s/%v/%d: decrypt failed",
					alg_str,
					impl,
					test_vector.tc_id,
				)
				num_failed += 1
				continue
			}

			if ok && !common.hexbytes_compare(test_vector.msg, msg_) {
				x := transmute(string)(hex.encode(msg_))
				log.errorf(
					"aead/%s/%v/%d: decrypt msg: expected %s actual %s",
					alg_str,
					impl,
					test_vector.tc_id,
					test_vector.msg,
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
		"aead/%s/%v: ran %d, passed %d, failed %d, skipped %d",
		alg_str,
		impl,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}
