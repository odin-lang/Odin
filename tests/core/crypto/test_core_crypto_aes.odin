package test_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:log"
import "core:testing"

import "core:crypto/aes"
import "core:crypto/sha2"

@(test)
test_aes :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	impls := supported_aes_impls()

	for impl in impls {
		test_aes_ecb(t, impl)
		test_aes_ctr(t, impl)
	}
}

supported_aes_impls :: proc() -> [dynamic]aes.Implementation {
	impls := make([dynamic]aes.Implementation, 0, 2, context.temp_allocator)
	append(&impls, aes.Implementation.Portable)
	if aes.is_hardware_accelerated() {
		append(&impls, aes.Implementation.Hardware)
	}

	return impls
}

test_aes_ecb :: proc(t: ^testing.T, impl: aes.Implementation) {
	log.debugf("Testing AES-ECB/%v", impl)

	test_vectors := []struct {
		key: string,
		plaintext: string,
		ciphertext: string,
	} {
		// http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf
		{
			"2b7e151628aed2a6abf7158809cf4f3c",
			"6bc1bee22e409f96e93d7e117393172a",
			"3ad77bb40d7a3660a89ecaf32466ef97",
		},
		{
			"2b7e151628aed2a6abf7158809cf4f3c",
			"ae2d8a571e03ac9c9eb76fac45af8e51",
			"f5d3d58503b9699de785895a96fdbaaf",
		},
		{
			"2b7e151628aed2a6abf7158809cf4f3c",
			"30c81c46a35ce411e5fbc1191a0a52ef",
			"43b1cd7f598ece23881b00e3ed030688",
		},
		{
			"2b7e151628aed2a6abf7158809cf4f3c",
			"f69f2445df4f9b17ad2b417be66c3710",
			"7b0c785e27e8ad3f8223207104725dd4",
		},
		{
			"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
			"6bc1bee22e409f96e93d7e117393172a",
			"bd334f1d6e45f25ff712a214571fa5cc",
		},
		{
			"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
			"ae2d8a571e03ac9c9eb76fac45af8e51",
			"974104846d0ad3ad7734ecb3ecee4eef",
		},
		{
			"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
			"30c81c46a35ce411e5fbc1191a0a52ef",
			"ef7afd2270e2e60adce0ba2face6444e",
		},
		{
			"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
			"f69f2445df4f9b17ad2b417be66c3710",
			"9a4b41ba738d6c72fb16691603c18e0e",
		},
		{
			"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
			"6bc1bee22e409f96e93d7e117393172a",
			"f3eed1bdb5d2a03c064b5a7e3db181f8",
		},
		{
			"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
			"ae2d8a571e03ac9c9eb76fac45af8e51",
			"591ccb10d410ed26dc5ba74a31362870",
		},
		{
			"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
			"30c81c46a35ce411e5fbc1191a0a52ef",
			"b6ed21b99ca6f4f9f153e7b1beafed1d",
		},
		{
			"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
			"f69f2445df4f9b17ad2b417be66c3710",
			"23304b7a39f9f3ff067d8d8f9e24ecc7",
		},
	}
	for v, _ in test_vectors {
		key, _ := hex.decode(transmute([]byte)(v.key), context.temp_allocator)
		plaintext, _ := hex.decode(transmute([]byte)(v.plaintext), context.temp_allocator)
		ciphertext, _ := hex.decode(transmute([]byte)(v.ciphertext), context.temp_allocator)

		ctx: aes.Context_ECB
		dst: [aes.BLOCK_SIZE]byte
		aes.init_ecb(&ctx, key, impl)

		aes.encrypt_ecb(&ctx, dst[:], plaintext)
		dst_str := string(hex.encode(dst[:], context.temp_allocator))
		testing.expectf(
			t,
			dst_str == v.ciphertext,
			"AES-ECB/%v: Expected: %s for encrypt(%s, %s), but got %s instead",
			impl,
			v.ciphertext,
			v.key,
			v.plaintext,
			dst_str,
		)

		aes.decrypt_ecb(&ctx, dst[:], ciphertext)
		dst_str = string(hex.encode(dst[:], context.temp_allocator))
		testing.expectf(
			t,
			dst_str == v.plaintext,
			"AES-ECB/%v: Expected: %s for decrypt(%s, %s), but got %s instead",
			impl,
			v.plaintext,
			v.key,
			v.ciphertext,
			dst_str,
		)
	}
}

test_aes_ctr :: proc(t: ^testing.T, impl: aes.Implementation) {
	log.debugf("Testing AES-CTR/%v", impl)

	test_vectors := []struct {
		key: string,
		iv: string,
		plaintext: string,
		ciphertext: string,
	} {
		// http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf
		{
			"2b7e151628aed2a6abf7158809cf4f3c",
			"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
			"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710",
			"874d6191b620e3261bef6864990db6ce9806f66b7970fdff8617187bb9fffdff5ae4df3edbd5d35e5b4f09020db03eab1e031dda2fbe03d1792170a0f3009cee",
		},
		{
			"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
			"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
			"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710",
			"1abc932417521ca24f2b0459fe7e6e0b090339ec0aa6faefd5ccc2c6f4ce8e941e36b26bd1ebc670d1bd1d665620abf74f78a7f6d29809585a97daec58c6b050",
		},
		{
			"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
			"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
			"6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52eff69f2445df4f9b17ad2b417be66c3710",
			"601ec313775789a5b7a7f504bbf3d228f443e3ca4d62b59aca84e990cacaf5c52b0930daa23de94ce87017ba2d84988ddfc9c58db67aada613c2dd08457941a6",
		},
	}
	for v, _ in test_vectors {
		key, _ := hex.decode(transmute([]byte)(v.key), context.temp_allocator)
		iv, _ := hex.decode(transmute([]byte)(v.iv), context.temp_allocator)
		plaintext, _ := hex.decode(transmute([]byte)(v.plaintext), context.temp_allocator)
		ciphertext, _ := hex.decode(transmute([]byte)(v.ciphertext), context.temp_allocator)

		dst := make([]byte, len(ciphertext), context.temp_allocator)

		ctx: aes.Context_CTR
		aes.init_ctr(&ctx, key, iv, impl)

		aes.xor_bytes_ctr(&ctx, dst, plaintext)

		dst_str := string(hex.encode(dst[:], context.temp_allocator))
		testing.expectf(
			t,
			dst_str == v.ciphertext,
			"AES-CTR/%v: Expected: %s for encrypt(%s, %s, %s), but got %s instead",
			impl,
			v.ciphertext,
			v.key,
			v.iv,
			v.plaintext,
			dst_str,
		)
	}

	// Incrementally read 1, 2, 3, ..., 2048 bytes of keystream, and
	// compare the SHA-512/256 digest with a known value.  Results
	// and testcase taken from a known good implementation.

	tmp := make([]byte, 2048, context.temp_allocator)

	ctx: aes.Context_CTR
	key: [aes.KEY_SIZE_256]byte
	iv: [aes.CTR_IV_SIZE]byte
	aes.init_ctr(&ctx, key[:], iv[:], impl)

	h_ctx: sha2.Context_512
	sha2.init_512_256(&h_ctx)

	for i := 1; i <= 2048; i = i + 1 {
		aes.keystream_bytes_ctr(&ctx, tmp[:i])
		sha2.update(&h_ctx, tmp[:i])
	}

	digest: [32]byte
	sha2.final(&h_ctx, digest[:])
	digest_str := string(hex.encode(digest[:], context.temp_allocator))

	expected_digest_str := "b5ba4e7d6e3d1ff2bb54387fc1528573a6b351610ce7bcc80b00da089f4b1bf0"
	testing.expectf(
		t,
		expected_digest_str == digest_str,
		"AES-CTR/%v: Expected %s for keystream digest, but got %s instead",
		impl,
		expected_digest_str,
		digest_str,
	)
}
