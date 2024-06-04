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

	impls := make([dynamic]aes.Implementation, 0, 2)
	defer delete(impls)
	append(&impls, aes.Implementation.Portable)
	if aes.is_hardware_accelerated() {
		append(&impls, aes.Implementation.Hardware)
	}

	for impl in impls {
		test_aes_ecb(t, impl)
		test_aes_ctr(t, impl)
		test_aes_gcm(t, impl)
	}
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
	nonce: [aes.CTR_IV_SIZE]byte
	aes.init_ctr(&ctx, key[:], nonce[:], impl)

	h_ctx: sha2.Context_512
	sha2.init_512_256(&h_ctx)

	for i := 1; i < 2048; i = i + 1 {
		aes.keystream_bytes_ctr(&ctx, tmp[:i])
		sha2.update(&h_ctx, tmp[:i])
	}

	digest: [32]byte
	sha2.final(&h_ctx, digest[:])
	digest_str := string(hex.encode(digest[:], context.temp_allocator))

	expected_digest_str := "d4445343afeb9d1237f95b10d00358aed4c1d7d57c9fe480cd0afb5e2ffd448c"
	testing.expectf(
		t,
		expected_digest_str == digest_str,
		"AES-CTR/%v: Expected %s for keystream digest, but got %s instead",
		impl,
		expected_digest_str,
		digest_str,
	)
}

test_aes_gcm :: proc(t: ^testing.T, impl: aes.Implementation) {
	log.debugf("Testing AES-GCM/%v", impl)

	// NIST did a reorg of their site, so the source of the test vectors
	// is only available from an archive.  The commented out tests are
	// for non-96-bit IVs which our implementation does not support.
	//
	// https://csrc.nist.rip/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-revised-spec.pdf
	test_vectors := []struct {
		key: string,
		iv: string,
		aad: string,
		plaintext: string,
		ciphertext: string,
		tag: string,
	} {
		{
			"00000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"",
			"",
			"58e2fccefa7e3061367f1d57a4e7455a",
		},
		{
			"00000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"00000000000000000000000000000000",
			"0388dace60b6a392f328c2b971b2fe78",
			"ab6e47d42cec13bdf53a67b21257bddf",
		},
		{
			"feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
			"42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985",
			"4d5c2af327cd64a62cf35abd2ba6fab4",
		},
		{
			"feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091",
			"5bc94fbc3221a5db94fae95ae7121a47",
		},
		/*
			{
				"feffe9928665731c6d6a8f9467308308",
				"cafebabefacedbad",
				"feedfacedeadbeeffeedfacedeadbeefabaddad2",
				"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
				"61353b4c2806934a777ff51fa22a4755699b2a714fcdc6f83766e5f97b6c742373806900e49f24b22b097544d4896b424989b5e1ebac0f07c23f4598",
				"3612d2e79e3b0785561be14aaca2fccb",
			},
			{
				"feffe9928665731c6d6a8f9467308308",
				"9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b",
				"feedfacedeadbeeffeedfacedeadbeefabaddad2",
				"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
				"8ce24998625615b603a033aca13fb894be9112a5c3a211a8ba262a3cca7e2ca701e4a9a4fba43c90ccdcb281d48c7c6fd62875d2aca417034c34aee5",
				"619cc5aefffe0bfa462af43c1699d050",
			},
		*/
		{
			"000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"",
			"",
			"cd33b28ac773f74ba00ed1f312572435",
		},
		{
			"000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"00000000000000000000000000000000",
			"98e7247c07f0fe411c267e4384b0f600",
			"2ff58d80033927ab8ef4d4587514f0fb",
		},
		{
			"feffe9928665731c6d6a8f9467308308feffe9928665731c",
			"cafebabefacedbaddecaf888",
			"",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
			"3980ca0b3c00e841eb06fac4872a2757859e1ceaa6efd984628593b40ca1e19c7d773d00c144c525ac619d18c84a3f4718e2448b2fe324d9ccda2710acade256",
			"9924a7c8587336bfb118024db8674a14",
		},
		{
			"feffe9928665731c6d6a8f9467308308feffe9928665731c",
			"cafebabefacedbaddecaf888",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"3980ca0b3c00e841eb06fac4872a2757859e1ceaa6efd984628593b40ca1e19c7d773d00c144c525ac619d18c84a3f4718e2448b2fe324d9ccda2710",
			"2519498e80f1478f37ba55bd6d27618c",
		},
		/*
			{
				"feffe9928665731c6d6a8f9467308308feffe9928665731c",
				"cafebabefacedbad",
				"feedfacedeadbeeffeedfacedeadbeefabaddad2",
				"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
				"0f10f599ae14a154ed24b36e25324db8c566632ef2bbb34f8347280fc4507057fddc29df9a471f75c66541d4d4dad1c9e93a19a58e8b473fa0f062f7",
				"65dcc57fcf623a24094fcca40d3533f8",
			},
			{
				"feffe9928665731c6d6a8f9467308308feffe9928665731c",
				"9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b",
				"feedfacedeadbeeffeedfacedeadbeefabaddad2",
				"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
				"d27e88681ce3243c4830165a8fdcf9ff1de9a1d8e6b447ef6ef7b79828666e4581e79012af34ddd9e2f037589b292db3e67c036745fa22e7e9b7373b",
				"dcf566ff291c25bbb8568fc3d376a6d9",
			},
		*/
		{
			"0000000000000000000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"",
			"",
			"530f8afbc74536b9a963b4f1c4cb738b",
		},
		{
			"0000000000000000000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"00000000000000000000000000000000",
			"cea7403d4d606b6e074ec5d3baf39d18",
			"d0d1c8a799996bf0265b98b5d48ab919",
		},
		{
			"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
			"522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662898015ad",
			"b094dac5d93471bdec1a502270e3cc6c",
		},
		{
			"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662",
			"76fc6ece0f4e1768cddf8853bb2d551b",
		},
		/*
			{
				"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
				"cafebabefacedbad",
				"feedfacedeadbeeffeedfacedeadbeefabaddad2",
				"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
				"c3762df1ca787d32ae47c13bf19844cbaf1ae14d0b976afac52ff7d79bba9de0feb582d33934a4f0954cc2363bc73f7862ac430e64abe499f47c9b1f",
				"3a337dbf46a792c45e454913fe2ea8f2",
			},
			{
				"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
				"9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b",
				"feedfacedeadbeeffeedfacedeadbeefabaddad2",
				"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
				"5a8def2f0c9e53f1f75d7853659e2a20eeb2b22aafde6419a058ab4f6f746bf40fc0c3b780f244452da3ebf1c5d82cdea2418997200ef82e44ae7e3f",
				"a44a8266ee1c8eb0c8b5d4cf5ae9f19a",
			},
		*/
	}
	for v, _ in test_vectors {
		key, _ := hex.decode(transmute([]byte)(v.key), context.temp_allocator)
		iv, _ := hex.decode(transmute([]byte)(v.iv), context.temp_allocator)
		aad, _ := hex.decode(transmute([]byte)(v.aad), context.temp_allocator)
		plaintext, _ := hex.decode(transmute([]byte)(v.plaintext), context.temp_allocator)
		ciphertext, _ := hex.decode(transmute([]byte)(v.ciphertext), context.temp_allocator)
		tag, _ := hex.decode(transmute([]byte)(v.tag), context.temp_allocator)

		tag_ := make([]byte, len(tag), context.temp_allocator)
		dst := make([]byte, len(ciphertext), context.temp_allocator)

		ctx: aes.Context_GCM
		aes.init_gcm(&ctx, key, impl)

		aes.seal_gcm(&ctx, dst, tag_, iv, aad, plaintext)
		dst_str := string(hex.encode(dst[:], context.temp_allocator))
		tag_str := string(hex.encode(tag_[:], context.temp_allocator))

		testing.expectf(
			t,
			dst_str == v.ciphertext && tag_str == v.tag,
			"AES-GCM/%v: Expected: (%s, %s) for seal(%s, %s, %s, %s), but got (%s, %s) instead",
			impl,
			v.ciphertext,
			v.tag,
			v.key,
			v.iv,
			v.aad,
			v.plaintext,
			dst_str,
			tag_str,
		)

		ok := aes.open_gcm(&ctx, dst, iv, aad, ciphertext, tag)
		dst_str = string(hex.encode(dst[:], context.temp_allocator))

		testing.expectf(
			t,
			ok && dst_str == v.plaintext,
			"AES-GCM/%v: Expected: (%s, true) for open(%s, %s, %s, %s, %s), but got (%s, %v) instead",
			impl,
			v.plaintext,
			v.key,
			v.iv,
			v.aad,
			v.ciphertext,
			v.tag,
			dst_str,
			ok,
		)
	}
}
