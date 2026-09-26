package test_wycheproof

import "core:log"
import "core:testing"

// Covered:
// - crypto/aegis
//   - aegis128L_test.json
//   - aegis256_test.json
// - crypto/aes
//   - aes_gcm_test.json
// - crypto/chacha20poly1305
//   - chacha20_poly1305_test.json
//   - xchacha20_poly1305_test.json
// - crypto/ed25519
//   - ed25519_test.json
// - crypto/hkdf
//   - hkdf_sha1_test.json
//   - hkdf_sha256_test.json
//   - hkdf_sha384_test.json
//   - hkdf_sha512_test.json
// - crypto/hmac (Note: We do not implement SHA-512/224)
//   - hmac_sha1_test.json
//   - hmac_sha224_test.json
//   - hmac_sha256_test.json
//   - hmac_sha3_224_test.json
//   - hmac_sha3_256_test.json
//   - hmac_sha3_384_test.json
//   - hmac_sha3_512_test.json
//   - hmac_sha384_test.json
//   - hmac_sha512_224_test.json
//   - hmac_sha512_256_test.json
//   - hmac_sha512_test.json
//   - hmac_sm3_test.json
// - crypto/kmac
//   - kmac128_no_customization_test.json
//   - kmac256_no_customization_test.json
// - crypto/mlkem
//   - mlkem_512_keygen_seed_test.json
//   - mlkem_512_encaps_test.json
//   - mlkem_512_test.json
//   - mlkem_768_keygen_seed_test.json
//   - mlkem_768_encaps_test.json
//   - mlkem_768_test.json
//   - mlkem_1024_keygen_seed_test.json
//   - mlkem_1024_encaps_test.json
//   - mlkem_1024_test.json
// - crypto/pbkdf2
//   - pbkdf2_hmacsha1_test.json
//   - pbkdf2_hmacsha224_test.json
//   - pbkdf2_hmacsha256_test.json
//   - pbkdf2_hmacsha384_test.json
//   - pbkdf2_hmacsha512_test.json
// - crypto/rsa
//   - rsa_pkcs1_1024_sig_gen_test.json
//   - rsa_pkcs1_1536_sig_gen_test.json
//   - rsa_pkcs1_2048_sig_gen_test.json
//   - rsa_pkcs1_3072_sig_gen_test.json
//   - rsa_pkcs1_4096_sig_gen_test.json
//   - rsa_pss_2048_sha1_mgf1_20_test.json
//   - rsa_pss_2048_sha256_mgf1_0_test.json
//   - rsa_pss_2048_sha256_mgf1_32_test.json
//   - rsa_pss_2048_sha256_mgf1sha1_20_test.json
//   - rsa_pss_2048_sha384_mgf1_48_test.json
//   - rsa_pss_2048_sha512_256_mgf1_32_test.json
//   - rsa_pss_3072_sha256_mgf1_32_test.json
//   - rsa_pss_4096_sha256_mgf1_32_test.json
//   - rsa_pss_4096_sha384_mgf1_48_test.json
//   - rsa_pss_4096_sha512_mgf1_32_test.json
//   - rsa_pss_4096_sha512_mgf1_64_test.json
//   - rsa_pss_misc_test.json
//   - rsa_oaep_2048_sha1_mgf1sha1_test.json
//   - rsa_oaep_2048_sha224_mgf1sha1_test.json
//   - rsa_oaep_2048_sha224_mgf1sha224_test.json
//   - rsa_oaep_2048_sha256_mgf1sha1_test.json
//   - rsa_oaep_2048_sha256_mgf1sha256_test.json
//   - rsa_oaep_2048_sha384_mgf1sha1_test.json
//   - rsa_oaep_2048_sha384_mgf1sha384_test.json
//   - rsa_oaep_2048_sha512_224_mgf1sha1_test.json
//   - rsa_oaep_2048_sha512_mgf1sha1_test.json
//   - rsa_oaep_2048_sha512_mgf1sha512_test.json
//   - rsa_oaep_3072_sha256_mgf1sha1_test.json
//   - rsa_oaep_3072_sha256_mgf1sha256_test.json
//   - rsa_oaep_3072_sha512_256_mgf1sha1_test.json
//   - rsa_oaep_3072_sha512_256_mgf1sha512_256_test.json
//   - rsa_oaep_3072_sha512_mgf1sha1_test.json
//   - rsa_oaep_3072_sha512_mgf1sha512_test.json
//   - rsa_oaep_4096_sha256_mgf1sha1_test.json
//   - rsa_oaep_4096_sha256_mgf1sha256_test.json
//   - rsa_oaep_4096_sha512_mgf1sha1_test.json
//   - rsa_oaep_4096_sha512_mgf1sha512_test.json
//   - rsa_oaep_misc_test.json
// - crypto/siphash
//   - siphash_1_3_test.json
//   - siphash_2_4_test.json
//   - siphash_4_8_test.json
// - crypto/x25519
//   - x25519_test.json
// - crypto/x448
//   - x448_test.json
// - crypto/_weierstrass
//   - ecdh_secp256r1_ecpoint_test.json
//   - ecdh_secp384r1_ecpoint_test.json
//   - ecdsa_secp256r1_sha256_test.json
//   - ecdsa_secp256r1_sha512_test.json
//   - ecdsa_secp384r1_sha384_test.json
//
// Not covered (not in wycheproof):
// - crypto/blake2b
// - crypto/blake2s
// - crypto/legacy/keccak
// - crypto/legacy/md5
// - crypto/tuplehash

ARENA_SIZE :: 8 * 1024 * 1024 // There is no kill like overkill.

BASE_PATH :: ODIN_ROOT + "tests/core/assets/Wycheproof"
SUFFIX_TEST_JSON :: "_test.json"

@(test)
print_test_vector_path :: proc(t: ^testing.T) {
	log.infof("wycheproof path: %s", BASE_PATH)
}
