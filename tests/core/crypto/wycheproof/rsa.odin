package test_wycheproof

import "core:encoding/hex"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:testing"

import "core:crypto/rsa"

import "../common"

@(test)
test_rsa_pkcs1_signature :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("rsa/pkcs1/signatures: starting")

	files := []string {
		"rsa_pkcs1_1024_sig_gen_test.json",
		"rsa_pkcs1_1536_sig_gen_test.json",
		"rsa_pkcs1_2048_sig_gen_test.json",
		"rsa_pkcs1_3072_sig_gen_test.json",
		"rsa_pkcs1_4096_sig_gen_test.json",
	}
	for f in files {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Rsa_Pkcs1_Sig_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_rsa_pkcs1_sig(t, &test_vectors), "RSA PKCS1 signature failed")
	}
}

test_rsa_pkcs1_sig :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Rsa_Pkcs1_Sig_Test_Group)) -> bool {
	JWK_KTY :: "RSA"

	params_str := fmt.aprintf("RSA-%d/PKCS1/Signature", test_vectors.test_groups[0].key_size)
	log.debugf("%s: starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		hash_str := test_group.sha
		hash_alg, _ := hash_name_to_algorithm(hash_str)
		if hash_alg == .Invalid {
			log.infof("%s: unsupported hash: %s", params_str, hash_str)
			num_ran += len(test_group.tests)
			num_skipped += len(test_group.tests)
			continue
		}

		priv_key: rsa.Private_Key
		pub_key := &priv_key._pub_key

		ok, have_priv: bool
		if test_group.private_key_jwk.kty == JWK_KTY {
			ok = jwk_to_private_key(&test_group.private_key_jwk, &priv_key)
			have_priv = true
		} else {
			ok = rsa.public_key_set_bytes(
				pub_key,
				common.hexbytes_decode(test_group.private_key.modulus),
				common.hexbytes_decode(test_group.private_key.public_exponent),
			)
		}

		if !testing.expectf(t, ok, "%s/%d: invalid RSA key: %v", params_str, tg_id, test_group.private_key) {
			num_ran += len(test_group.tests)
			num_failed += len(test_group.tests)
			continue
		}

		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/%s/%d/%d: %s: %+v",
					params_str,
					hash_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/%s/%d/%d: %+v", params_str, hash_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			msg := common.hexbytes_decode(test_vector.msg)
			sig := common.hexbytes_decode(test_vector.sig)

			verify_ok := rsa.verify_pkcs1(pub_key, hash_alg, msg, sig)
			if !testing.expectf(
				t,
				result_check(test_vector.result, verify_ok, false),
				"%s/%s/%d/%d: verify failed: expected %s actual %v",
				params_str,
				hash_str,
				tg_id,
				test_vector.tc_id,
				test_vector.result,
				verify_ok,
			) {
				num_failed += 1
				continue
			}

			if have_priv && verify_ok {
				sign_ok := rsa.sign_pkcs1(&priv_key, hash_alg, msg, sig)
				if !testing.expectf(
					t,
					sign_ok,
					"%s/%s/%d/%d: sign failed",
					params_str,
					hash_str,
					tg_id,
					test_vector.tc_id,
				) {
					num_failed += 1
					continue
				}
				if !testing.expectf(
					t,
					common.hexbytes_compare(test_vector.sig, sig),
					"%s/%s/%d/%d: sign failed: expected %s actual %s",
					params_str,
					hash_str,
					tg_id,
					test_vector.tc_id,
					test_vector.sig,
					hex.encode(sig),
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
		"%s: ran %d, passed %d, failed %d, skipped %d",
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

@(test)
test_rsa_pss_signature :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("rsa/pss/signatures: starting")

	files := []string {
		"rsa_pss_2048_sha1_mgf1_20_test.json",
		"rsa_pss_2048_sha256_mgf1_0_test.json",
		"rsa_pss_2048_sha256_mgf1_32_test.json",
		"rsa_pss_2048_sha256_mgf1sha1_20_test.json",
		"rsa_pss_2048_sha384_mgf1_48_test.json",
		"rsa_pss_2048_sha512_224_mgf1_28_test.json",
		"rsa_pss_2048_sha512_256_mgf1_32_test.json",
		"rsa_pss_3072_sha256_mgf1_32_test.json",
		"rsa_pss_4096_sha256_mgf1_32_test.json",
		"rsa_pss_4096_sha384_mgf1_48_test.json",
		"rsa_pss_4096_sha512_mgf1_32_test.json",
		"rsa_pss_4096_sha512_mgf1_64_test.json",
		"rsa_pss_misc_test.json",

		// These tests include the MGF1 parameters in the public key,
		// which we do not support with our existing API.
		//
		// "rsa_pss_2048_sha1_mgf1_20_params_test.json",
		// "rsa_pss_2048_sha256_mgf1_0_params_test.json",
		// "rsa_pss_2048_sha256_mgf1_32_params_test.json",
		// "rsa_pss_2048_sha512_mgf1sha256_32_params_test.json",
		// "rsa_pss_3072_sha256_mgf1_32_params_test.json",
		// "rsa_pss_4096_sha512_mgf1_32_params_test.json",
		// "rsa_pss_4096_sha512_mgf1_64_params_test.json",
		// "rsa_pss_misc_params_test.json",
	}
	for f in files {
		mem.free_all()

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Rsa_Pss_Sig_Test_Group)
		load_ok := load(&test_vectors, fn)
		if !testing.expectf(t, load_ok, "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_rsa_pss_sig(t, &test_vectors), "RSA PSS signature failed")
	}
}

test_rsa_pss_sig :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Rsa_Pss_Sig_Test_Group)) -> bool {
	MGF1 :: "MGF1"

	params_str := fmt.aprintf("RSA-%d/PSS/Signature", test_vectors.test_groups[0].key_size)
	log.debugf("%s: starting", params_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, tg_id in test_vectors.test_groups {
		if test_group.mgf != MGF1 {
			log.infof("%s: unsupported MGF: %s", params_str, test_group.mgf)
			num_ran += len(test_group.tests)
			num_skipped += len(test_group.tests)
			continue
		}

		hash_str := test_group.sha
		hash_alg, _ := hash_name_to_algorithm(hash_str)
		if hash_alg == .Invalid {
			log.infof("%s: unsupported hash: %s", params_str, hash_str)
			num_ran += len(test_group.tests)
			num_skipped += len(test_group.tests)
			continue
		}

		mgf_hash_str := test_group.mfg_sha
		mgf_hash_alg, _ := hash_name_to_algorithm(mgf_hash_str)
		if mgf_hash_alg == .Invalid {
			log.infof("%s: unsupported MGF hash: %s", params_str, mgf_hash_str)
			num_ran += len(test_group.tests)
			num_skipped += len(test_group.tests)
			continue
		}

		hash_params_str := fmt.aprintf("%s/%s(%s)", hash_str, test_group.mgf, mgf_hash_str)

		pub_key: rsa.Public_Key
		ok := rsa.public_key_set_bytes(
			&pub_key,
			common.hexbytes_decode(test_group.public_key.modulus),
			common.hexbytes_decode(test_group.public_key.public_exponent),
		)
		if !testing.expectf(t, ok, "%s/%d: invalid RSA key: %v", params_str, tg_id, test_group.public_key) {
			num_ran += len(test_group.tests)
			num_failed += len(test_group.tests)
			continue
		}

		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"%s/%s/%d/%d: %s: %+v",
					params_str,
					hash_params_str,
					tg_id,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("%s/%s/%d/%d: %+v", params_str, hash_str, tg_id, test_vector.tc_id, test_vector.flags)
			}

			msg := common.hexbytes_decode(test_vector.msg)
			sig := common.hexbytes_decode(test_vector.sig)

			verify_ok := rsa.verify_pss(&pub_key, hash_alg, mgf_hash_alg, test_group.s_len, msg, sig)
			if !testing.expectf(
				t,
				result_check(test_vector.result, verify_ok, false),
				"%s/%s/%d/%d: verify failed: expected %s actual %v",
				params_str,
				hash_params_str,
				tg_id,
				test_vector.tc_id,
				test_vector.result,
				verify_ok,
			) {
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
		params_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

@(private = "file")
jwk_to_private_key :: proc(jwk: ^Rsa_Jwk_Private_Key, priv_key: ^rsa.Private_Key) -> bool {
	return rsa.private_key_set_bytes(
		priv_key,
		common.jwkbytes_decode(jwk.n),
		common.jwkbytes_decode(jwk.e),
		common.jwkbytes_decode(jwk.d),
		common.jwkbytes_decode(jwk.p),
		common.jwkbytes_decode(jwk.q),
		common.jwkbytes_decode(jwk.dp),
		common.jwkbytes_decode(jwk.dq),
		common.jwkbytes_decode(jwk.qi),
	)
}
