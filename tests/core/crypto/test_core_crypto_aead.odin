package test_core_crypto

import "base:runtime"
import "core:crypto/aead"
import "core:encoding/hex"
import "core:testing"

@(test)
test_aead :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	aes_impls := make([dynamic]aead.Implementation, context.temp_allocator)
	for impl in supported_aes_impls() {
		append(&aes_impls, impl)
	}
	chacha_impls := make([dynamic]aead.Implementation, context.temp_allocator)
	for impl in supported_chacha_impls() {
		append(&chacha_impls, impl)
	}
	impls := [aead.Algorithm][dynamic]aead.Implementation{
		.Invalid           = nil,
		.AES_GCM_128       = aes_impls,
		.AES_GCM_192       = aes_impls,
		.AES_GCM_256       = aes_impls,
		.CHACHA20POLY1305  = chacha_impls,
		.XCHACHA20POLY1305 = chacha_impls,
	}

	test_vectors := []struct{
		algo: aead.Algorithm,
		key: string,
		iv: string,
		aad: string,
		plaintext: string,
		ciphertext: string,
		tag: string,
	} {
		// AES-GCM
		// - https://csrc.nist.rip/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-revised-spec.pdf
		//
		// Note: NIST did a reorg of their site, so the source of the test vectors
		// is only available from an archive.
		{
			.AES_GCM_128,
			"00000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"",
			"",
			"58e2fccefa7e3061367f1d57a4e7455a",
		},
		{
			.AES_GCM_128,
			"00000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"00000000000000000000000000000000",
			"0388dace60b6a392f328c2b971b2fe78",
			"ab6e47d42cec13bdf53a67b21257bddf",
		},
		{
			.AES_GCM_128,
			"feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
			"42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985",
			"4d5c2af327cd64a62cf35abd2ba6fab4",
		},
		{
			.AES_GCM_128,
			"feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091",
			"5bc94fbc3221a5db94fae95ae7121a47",
		},
		{
			.AES_GCM_128,
			"feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbad",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"61353b4c2806934a777ff51fa22a4755699b2a714fcdc6f83766e5f97b6c742373806900e49f24b22b097544d4896b424989b5e1ebac0f07c23f4598",
			"3612d2e79e3b0785561be14aaca2fccb",
		},
		{
			.AES_GCM_128,
			"feffe9928665731c6d6a8f9467308308",
			"9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"8ce24998625615b603a033aca13fb894be9112a5c3a211a8ba262a3cca7e2ca701e4a9a4fba43c90ccdcb281d48c7c6fd62875d2aca417034c34aee5",
			"619cc5aefffe0bfa462af43c1699d050",
		},
		{
			.AES_GCM_192,
			"000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"",
			"",
			"cd33b28ac773f74ba00ed1f312572435",
		},
		{
			.AES_GCM_192,
			"000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"00000000000000000000000000000000",
			"98e7247c07f0fe411c267e4384b0f600",
			"2ff58d80033927ab8ef4d4587514f0fb",
		},
		{
			.AES_GCM_192,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c",
			"cafebabefacedbaddecaf888",
			"",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
			"3980ca0b3c00e841eb06fac4872a2757859e1ceaa6efd984628593b40ca1e19c7d773d00c144c525ac619d18c84a3f4718e2448b2fe324d9ccda2710acade256",
			"9924a7c8587336bfb118024db8674a14",
		},
		{
			.AES_GCM_192,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c",
			"cafebabefacedbaddecaf888",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"3980ca0b3c00e841eb06fac4872a2757859e1ceaa6efd984628593b40ca1e19c7d773d00c144c525ac619d18c84a3f4718e2448b2fe324d9ccda2710",
			"2519498e80f1478f37ba55bd6d27618c",
		},
		{
			.AES_GCM_192,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c",
			"cafebabefacedbad",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"0f10f599ae14a154ed24b36e25324db8c566632ef2bbb34f8347280fc4507057fddc29df9a471f75c66541d4d4dad1c9e93a19a58e8b473fa0f062f7",
			"65dcc57fcf623a24094fcca40d3533f8",
		},
		{
			.AES_GCM_192,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c",
			"9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"d27e88681ce3243c4830165a8fdcf9ff1de9a1d8e6b447ef6ef7b79828666e4581e79012af34ddd9e2f037589b292db3e67c036745fa22e7e9b7373b",
			"dcf566ff291c25bbb8568fc3d376a6d9",
		},
		{
			.AES_GCM_256,
			"0000000000000000000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"",
			"",
			"530f8afbc74536b9a963b4f1c4cb738b",
		},
		{
			.AES_GCM_256,
			"0000000000000000000000000000000000000000000000000000000000000000",
			"000000000000000000000000",
			"",
			"00000000000000000000000000000000",
			"cea7403d4d606b6e074ec5d3baf39d18",
			"d0d1c8a799996bf0265b98b5d48ab919",
		},
		{
			.AES_GCM_256,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
			"522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662898015ad",
			"b094dac5d93471bdec1a502270e3cc6c",
		},
		{
			.AES_GCM_256,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbaddecaf888",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662",
			"76fc6ece0f4e1768cddf8853bb2d551b",
		},
		{
			.AES_GCM_256,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
			"cafebabefacedbad",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"c3762df1ca787d32ae47c13bf19844cbaf1ae14d0b976afac52ff7d79bba9de0feb582d33934a4f0954cc2363bc73f7862ac430e64abe499f47c9b1f",
			"3a337dbf46a792c45e454913fe2ea8f2",
		},
		{
			.AES_GCM_256,
			"feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
			"9313225df88406e555909c5aff5269aa6a7a9538534f7da1e4c303d2a318a728c3c0c95156809539fcf0e2429a6b525416aedbf5a0de6a57a637b39b",
			"feedfacedeadbeeffeedfacedeadbeefabaddad2",
			"d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39",
			"5a8def2f0c9e53f1f75d7853659e2a20eeb2b22aafde6419a058ab4f6f746bf40fc0c3b780f244452da3ebf1c5d82cdea2418997200ef82e44ae7e3f",
			"a44a8266ee1c8eb0c8b5d4cf5ae9f19a",
		},
		// Chacha20-Poly1305
		// https://www.rfc-editor.org/rfc/rfc8439
		{
			.CHACHA20POLY1305,
			"808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f",
			"070000004041424344454647",
			"50515253c0c1c2c3c4c5c6c7",
			string(hex.encode(transmute([]byte)(_PLAINTEXT_SUNSCREEN_STR), context.temp_allocator)),
			"d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b3692ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4b7a9de576d26586cec64b6116",
			"1ae10b594f09e26a7e902ecbd0600691",
		},
		// XChaCha20-Poly1305-IETF
		// - https://datatracker.ietf.org/doc/html/draft-arciszewski-xchacha-03
		{
			.XCHACHA20POLY1305,
			"808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f",
			"404142434445464748494a4b4c4d4e4f5051525354555657",
			"50515253c0c1c2c3c4c5c6c7",
			"4c616469657320616e642047656e746c656d656e206f662074686520636c617373206f66202739393a204966204920636f756c64206f6666657220796f75206f6e6c79206f6e652074697020666f7220746865206675747572652c2073756e73637265656e20776f756c642062652069742e",
			"bd6d179d3e83d43b9576579493c0e939572a1700252bfaccbed2902c21396cbb731c7f1b0b4aa6440bf3a82f4eda7e39ae64c6708c54c216cb96b72e1213b4522f8c9ba40db5d945b11b69b982c1bb9e3f3fac2bc369488f76b2383565d3fff921f9664c97637da9768812f615c68b13b52e",
			"c0875924c1c7987947deafd8780acf49",
		},
	}
	for v, _ in test_vectors {
		algo_name := aead.ALGORITHM_NAMES[v.algo]

		key, _ := hex.decode(transmute([]byte)(v.key), context.temp_allocator)
		iv, _ := hex.decode(transmute([]byte)(v.iv), context.temp_allocator)
		aad, _ := hex.decode(transmute([]byte)(v.aad), context.temp_allocator)
		plaintext, _ := hex.decode(transmute([]byte)(v.plaintext), context.temp_allocator)
		ciphertext, _ := hex.decode(transmute([]byte)(v.ciphertext), context.temp_allocator)
		tag, _ := hex.decode(transmute([]byte)(v.tag), context.temp_allocator)

		tag_ := make([]byte, len(tag), context.temp_allocator)
		dst := make([]byte, len(ciphertext), context.temp_allocator)

		ctx: aead.Context
		for impl in impls[v.algo] {
			aead.init(&ctx, v.algo, key, impl)

			aead.seal(&ctx, dst, tag_, iv, aad, plaintext)
			dst_str := string(hex.encode(dst, context.temp_allocator))
			tag_str := string(hex.encode(tag_, context.temp_allocator))
			testing.expectf(
				t,
				dst_str == v.ciphertext && tag_str == v.tag,
				"%s/%v: Expected: (%s, %s) for seal_ctx(%s, %s, %s, %s), but got (%s, %s) instead",
				algo_name,
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

			aead.seal(v.algo, dst, tag_, key, iv, aad, plaintext, impl)
			dst_str = string(hex.encode(dst, context.temp_allocator))
			tag_str = string(hex.encode(tag_, context.temp_allocator))
			testing.expectf(
				t,
				dst_str == v.ciphertext && tag_str == v.tag,
				"%s/%v: Expected: (%s, %s) for seal_oneshot(%s, %s, %s, %s), but got (%s, %s) instead",
				algo_name,
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

			ok := aead.open(&ctx, dst, iv, aad, ciphertext, tag)
			dst_str = string(hex.encode(dst, context.temp_allocator))
			testing.expectf(
				t,
				ok && dst_str == v.plaintext,
				"%s/%v: Expected: (%s, true) for open_ctx(%s, %s, %s, %s, %s), but got (%s, %v) instead",
				algo_name,
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

			ok = aead.open(v.algo, dst, key, iv, aad, ciphertext, tag, impl)
			dst_str = string(hex.encode(dst, context.temp_allocator))
			testing.expectf(
				t,
				ok && dst_str == v.plaintext,
				"%s/%v: Expected: (%s, true) for open_oneshot(%s, %s, %s, %s, %s), but got (%s, %v) instead",
				algo_name,
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

			tag_[0] ~= 0xa5
			ok = aead.open(&ctx, dst, iv, aad, ciphertext, tag_)
			testing.expectf(t, !ok, "%s/%v: Expected false for open(bad_tag, aad, ciphertext)", algo_name, impl)

			if len(dst) > 0 {
				copy(dst, ciphertext[:])
				dst[0] ~= 0xa5
				ok = aead.open(&ctx, dst, iv, aad, dst, tag)
				testing.expectf(t, !ok, "%s/%v: Expected false for open(tag, aad, bad_ciphertext)", algo_name, impl)
			}

			if len(aad) > 0 {
				aad_ := make([]byte, len(aad), context.temp_allocator)
				copy(aad_, aad)
				aad_[0] ~= 0xa5
				ok = aead.open(&ctx, dst, iv, aad_, ciphertext, tag)
				testing.expectf(t, !ok, "%s/%v: Expected false for open(tag, bad_aad, ciphertext)", algo_name, impl)
			}
		}
	}
}
