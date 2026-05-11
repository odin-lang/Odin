package test_wycheproof

import "core:encoding/hex"
import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"

import "core:crypto/hash"
import "core:crypto/ecdh"
import "core:crypto/ecdsa"
import "core:crypto/ed25519"

import "../common"

@(test)
test_eddsa_ed25519 :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	fn, _ := os.join_path([]string{BASE_PATH, "ed25519_test.json"}, context.allocator)

	log.debug("eddsa/ed25519: starting")

	test_vectors: Test_Vectors(Eddsa_Test_Group)
	if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", fn) {
		return
	}

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, i in test_vectors.test_groups {
		mem.free_all() // Probably don't need this, but be safe.
		pk_bytes := common.hexbytes_decode(test_group.public_key.pk)

		pk: ed25519.Public_Key
		pk_ok := ed25519.public_key_set_bytes(&pk, pk_bytes)
		if !testing.expectf(t, pk_ok, "eddsa/ed25519/%d: invalid public key: %s", i, test_group.public_key.pk) {
			num_failed += len(test_group.tests)
			continue
		}

		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"eddsa/ed25519/%d: %s: %+v",
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("eddsa/ed25519/%d: %+v", test_vector.tc_id, test_vector.flags)
			}

			msg := common.hexbytes_decode(test_vector.msg)
			sig := common.hexbytes_decode(test_vector.sig)

			verify_ok := ed25519.verify(&pk, msg, sig)
			if !testing.expectf(
                t,
				result_check(test_vector.result, verify_ok),
				"eddsa/ed25519/%d: verify failed: expected %s actual %v",
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
		"eddsa/ed25519: ran %d, passed %d, failed %d, skipped %d",
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)
}

@(test)
test_ecdsa :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("ecdsa: starting")

	files := []string {
		"ecdsa_secp256r1_sha256_test.json",
		"ecdsa_secp256r1_sha512_test.json",
		"ecdsa_secp384r1_sha384_test.json",
	}

	for f in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Ecdsa_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		testing.expectf(t, test_ecdsa_impl(t, &test_vectors), "ecdsa failed")
	}
}

test_ecdsa_impl :: proc(t: ^testing.T, test_vectors: ^Test_Vectors(Ecdsa_Test_Group)) -> bool {
	curve_str := test_vectors.test_groups[0].public_key.curve
	hash_str := test_vectors.test_groups[0].sha

	curve_alg: ecdsa.Curve
	switch curve_str {
	case "secp256r1":
		curve_alg = .SECP256R1
	case "secp384r1":
		curve_alg = .SECP384R1
	case:
		log.errorf("ecdsa: unsupported curve: %s", curve_str)
	}

	hash_alg: hash.Algorithm
	switch hash_str {
	case "SHA-256":
		hash_alg = .SHA256
	case "SHA-384":
		hash_alg = .SHA384
	case "SHA-512":
		hash_alg = .SHA512
	case:
		log.errorf("ecdsa: unsupported hash: %s", hash_str)
	}

	log.debugf("ecdsa/%s/%s: starting", curve_str, hash_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group, i in test_vectors.test_groups {
		pk_bytes := common.hexbytes_decode(test_group.public_key.uncompressed)

		pk: ecdsa.Public_Key
		pk_ok := ecdsa.public_key_set_bytes(&pk, curve_alg, pk_bytes)
		if !testing.expectf(t, pk_ok, "ecdsa/%s/%s/%d: invalid public key: %s", curve_str, hash_str, i, test_group.public_key.uncompressed) {
			num_failed += len(test_group.tests)
			continue
		}

		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf(
					"ecda/%s/%s/%d: %s: %+v",
					curve_str,
					hash_str,
					test_vector.tc_id,
					comment,
					test_vector.flags,
				)
			} else {
				log.debugf("ecdsa/%s/%s/%d: %+v", curve_str, hash_str, test_vector.tc_id, test_vector.flags)
			}

			msg := common.hexbytes_decode(test_vector.msg)
			sig := common.hexbytes_decode(test_vector.sig)

			verify_ok := ecdsa.verify_asn1(&pk, hash_alg, msg, sig)
			if !testing.expectf(
				t,
				result_check(test_vector.result, verify_ok),
				"ecdsa/%s/%s/%d: verify failed: expected %s actual %v",
				curve_str,
				hash_str,
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
		"ecdsa/%s/%s: ran %d, passed %d, failed %d, skipped %d",
		curve_str,
		hash_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}

@(test)
test_ecdh :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	PREFIX_TEST_ECDH :: "ecdh_"
	SUFFIX_TEST_ECPOINT :: "_ecpoint"

	files := []string {
		"ecdh_secp256r1_ecpoint_test.json",
		"ecdh_secp384r1_ecpoint_test.json",
		"x25519_test.json",
		"x448_test.json",
	}

	log.debug("ecdh: starting")

	for f in files {
		mem.free_all() // Probably don't need this, but be safe.

		fn, _ := os.join_path([]string{BASE_PATH, f}, context.allocator)

		test_vectors: Test_Vectors(Ecdh_Test_Group)
		if !testing.expectf(t, load(&test_vectors, fn), "Unable to load {}", f) {
			continue
		}

		alg_str := strings.trim_suffix(f, SUFFIX_TEST_JSON)
		alg_str = strings.trim_suffix(alg_str, SUFFIX_TEST_ECPOINT)
		alg_str = strings.trim_prefix(alg_str, PREFIX_TEST_ECDH)
		testing.expectf(t, test_ecdh_impl(&test_vectors, alg_str), "alg {} failed", alg_str)
	}
}

test_ecdh_impl :: proc(
	test_vectors: ^Test_Vectors(Ecdh_Test_Group),
	alg_str: string,
) -> bool {
	ALG_P256 :: "secp256r1"
	ALG_P384 :: "secp384r1"
	ALG_X25519 :: "x25519"
	ALG_X448 :: "x448"

	// XDH exceptions
	FLAG_PUBLIC_KEY_TOO_LONG :: "PublicKeyTooLong"
	FLAG_ZERO_SHARED_SECRET :: "ZeroSharedSecret"

	// ECDH exceptions
	FLAG_COMPRESSED_POINT :: "CompressedPoint"
	FLAG_INVALID_CURVE :: "InvalidCurveAttack"
	FLAG_INVALID_ENCODING :: "InvalidEncoding"

	log.debugf("ecdh/%s: starting", alg_str)

	num_ran, num_passed, num_failed, num_skipped: int
	for &test_group in test_vectors.test_groups {
		for &test_vector in test_group.tests {
			num_ran += 1

			if comment := test_vector.comment; comment != "" {
				log.debugf("ecdh/%s/%d: %s: %+v", alg_str, test_vector.tc_id, comment, test_vector.flags)
			} else {
				log.debugf("ecdh/%s/%d: %+v", alg_str, test_vector.tc_id, test_vector.flags)
			}

			raw_pub := common.hexbytes_decode(test_vector.public)
			raw_priv := common.hexbytes_decode(test_vector.private)

			curve: ecdh.Curve
			priv_key: ecdh.Private_Key
			pub_key: ecdh.Public_Key

			is_nist, is_xdh: bool
			switch alg_str {
			case ALG_P256:
				curve = .SECP256R1
				// Ugh, ASN.1 :(
				l := len(raw_priv)
				if l == 33 {
					if raw_priv[0] == 0 {
						raw_priv = raw_priv[1:]
					}
				} else if l < 32 {
					// left-pad.odin
					tmp := make([]byte, 32)
					copy(tmp[32-l:], raw_priv)
					raw_priv = tmp
				}
				is_nist = true
			case ALG_P384:
				curve = .SECP384R1
				// Ugh, ASN.1 :(
				l := len(raw_priv)
				if l == 49 {
					if raw_priv[0] == 0 {
						raw_priv = raw_priv[1:]
					}
				} else if l < 48 {
					// left-pad.odin
					tmp := make([]byte, 48)
					copy(tmp[48-l:], raw_priv)
					raw_priv = tmp
				}
				is_nist = true
			case ALG_X25519:
				curve = .X25519
				is_xdh = true
			case ALG_X448:
				curve = .X448
				is_xdh = true
			case:
				log.errorf("ecdh: unsupported algorithm: %s", alg_str)
				return false
			}

			if ok := ecdh.private_key_set_bytes(&priv_key, curve, raw_priv); !ok {
				log.errorf(
					"ecdh/%s/%d: failed to deserialize private_key: %s %d %x",
					alg_str,
					test_vector.tc_id,
					test_vector.private,
					len(raw_priv),
					raw_priv,
				)
				num_failed += 1
				continue
			}

			if ok := ecdh.public_key_set_bytes(&pub_key, curve, raw_pub); !ok {
				if is_nist {
					if slice.contains(test_vector.flags, FLAG_COMPRESSED_POINT) {
						num_passed += 1
						continue
					}
					if slice.contains(test_vector.flags, FLAG_INVALID_CURVE) {
						num_passed += 1
						continue
					}
					if slice.contains(test_vector.flags, FLAG_INVALID_ENCODING) {
						num_passed += 1
						continue
					}
				}
				if slice.contains(test_vector.flags, FLAG_PUBLIC_KEY_TOO_LONG) {
					num_passed += 1
					continue
				}

				log.errorf(
					"ecdh/%s/%d: failed to deserialize public_key: %s",
					alg_str,
					test_vector.tc_id,
					test_vector.public,
				)
				num_failed += 1
				continue
			}

			shared := make([]byte, ecdh.SHARED_SECRET_SIZES[curve])

			ok := ecdh.ecdh(&priv_key, &pub_key, shared)
			if !ok {
				if is_xdh && slice.contains(test_vector.flags, FLAG_ZERO_SHARED_SECRET) {
					num_passed += 1
					continue
				}
				// unused: x := transmute(string)(hex.encode(shared))
				log.errorf(
					"ecdh/%s/%d: ecdh failed",
					alg_str,
					test_vector.tc_id,
				)
				num_failed += 1
				continue
			}

			ok = common.hexbytes_compare(test_vector.shared, shared)
			// "acceptable" results are fine from here because we have
			// checked for the all-zero shared secret XDH case already.
			if !result_check(test_vector.result, ok, false) {
				x := transmute(string)(hex.encode(shared))
				log.errorf(
					"ecdh/%s/%d: shared: expected %s actual %s",
					alg_str,
					test_vector.tc_id,
					test_vector.shared,
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
		"ecdh/%s: ran %d, passed %d, failed %d, skipped %d",
		alg_str,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)

	return num_failed == 0
}
