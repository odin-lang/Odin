package test_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:mem"
import "core:testing"
import "core:crypto/hash"
import "core:crypto/hmac"
import "core:crypto/poly1305"
import "core:crypto/siphash"

@(test)
test_hmac :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Test cases pulled out of RFC 6234, note that HMAC is a generic
	// construct so as long as the underlying hash is correct and all
	// the code paths are covered the implementation is "fine", so
	// this only exercises SHA256.

	test_keys := [?]string {
		"\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b",
		"Jefe",
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa",
		"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19",
		"\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c\x0c",
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa",
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa",
	}

	test_msgs := [?]string {
		"Hi There",
		"what do ya want for nothing?",
		"\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd\xdd",
		"\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd\xcd",
		"Test With Truncation",
		"Test Using Larger Than Block-Size Key - Hash Key First",
		"This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.",
	}

	tags_sha256 := [?]string {
		"b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
		"5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
		"773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe",
		"82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b",
		"a3b6167473100ee06e0c796c2955552b",
		"60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
		"9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2",
	}

	algo := hash.Algorithm.SHA256

	tag: [64]byte // 512-bits is enough for every digest for now.
	for k, i in test_keys {
		algo_name := hash.ALGORITHM_NAMES[algo]
		dst := tag[:hash.DIGEST_SIZES[algo]]

		key := transmute([]byte)(k)
		msg := transmute([]byte)(test_msgs[i])

		ctx: hmac.Context
		hmac.init(&ctx, algo, key)
		hmac.update(&ctx, msg)
		hmac.final(&ctx, dst)

		// For simplicity crypto/hmac does not support truncation, but
		// test it by truncating the tag down as appropriate based on
		// the expected value.
		expected_str := tags_sha256[i]
		tag_len := len(expected_str) / 2

		key_str := string(hex.encode(key, context.temp_allocator))
		msg_str := string(hex.encode(msg, context.temp_allocator))
		dst_str := string(hex.encode(dst[:tag_len], context.temp_allocator))

		testing.expectf(
			t,
			dst_str == expected_str,
			"%s/incremental: Expected: %s for input of %s - %s, but got %s instead",
			algo_name,
			tags_sha256[i],
			key_str,
			msg_str,
			dst_str,
		)

		hmac.sum(algo, dst, msg, key)
		oneshot_str := string(hex.encode(dst[:tag_len], context.temp_allocator))

		testing.expectf(
			t,
			oneshot_str == expected_str,
			"%s/oneshot: Expected: %s for input of %s - %s, but got %s instead",
			algo_name,
			tags_sha256[i],
			key_str,
			msg_str,
			oneshot_str,
		)
	}
}

@(test)
test_poly1305 :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Test cases taken from poly1305-donna.
	key := [poly1305.KEY_SIZE]byte {
		0xee, 0xa6, 0xa7, 0x25, 0x1c, 0x1e, 0x72, 0x91,
		0x6d, 0x11, 0xc2, 0xcb, 0x21, 0x4d, 0x3c, 0x25,
		0x25, 0x39, 0x12, 0x1d, 0x8e, 0x23, 0x4e, 0x65,
		0x2d, 0x65, 0x1f, 0xa4, 0xc8, 0xcf, 0xf8, 0x80,
	}

	msg := [131]byte {
		0x8e, 0x99, 0x3b, 0x9f, 0x48, 0x68, 0x12, 0x73,
		0xc2, 0x96, 0x50, 0xba, 0x32, 0xfc, 0x76, 0xce,
		0x48, 0x33, 0x2e, 0xa7, 0x16, 0x4d, 0x96, 0xa4,
		0x47, 0x6f, 0xb8, 0xc5, 0x31, 0xa1, 0x18, 0x6a,
		0xc0, 0xdf, 0xc1, 0x7c, 0x98, 0xdc, 0xe8, 0x7b,
		0x4d, 0xa7, 0xf0, 0x11, 0xec, 0x48, 0xc9, 0x72,
		0x71, 0xd2, 0xc2, 0x0f, 0x9b, 0x92, 0x8f, 0xe2,
		0x27, 0x0d, 0x6f, 0xb8, 0x63, 0xd5, 0x17, 0x38,
		0xb4, 0x8e, 0xee, 0xe3, 0x14, 0xa7, 0xcc, 0x8a,
		0xb9, 0x32, 0x16, 0x45, 0x48, 0xe5, 0x26, 0xae,
		0x90, 0x22, 0x43, 0x68, 0x51, 0x7a, 0xcf, 0xea,
		0xbd, 0x6b, 0xb3, 0x73, 0x2b, 0xc0, 0xe9, 0xda,
		0x99, 0x83, 0x2b, 0x61, 0xca, 0x01, 0xb6, 0xde,
		0x56, 0x24, 0x4a, 0x9e, 0x88, 0xd5, 0xf9, 0xb3,
		0x79, 0x73, 0xf6, 0x22, 0xa4, 0x3d, 0x14, 0xa6,
		0x59, 0x9b, 0x1f, 0x65, 0x4c, 0xb4, 0x5a, 0x74,
		0xe3, 0x55, 0xa5,
	}

	tag := [poly1305.TAG_SIZE]byte {
		0xf3, 0xff, 0xc7, 0x70, 0x3f, 0x94, 0x00, 0xe5,
		0x2a, 0x7d, 0xfb, 0x4b, 0x3d, 0x33, 0x05, 0xd9,
	}
	tag_str := string(hex.encode(tag[:], context.temp_allocator))

	// Verify - oneshot + compare
	ok := poly1305.verify(tag[:], msg[:], key[:])
	testing.expect(t, ok, "oneshot verify call failed")

	// Sum - oneshot
	derived_tag: [poly1305.TAG_SIZE]byte
	poly1305.sum(derived_tag[:], msg[:], key[:])
	derived_tag_str := string(hex.encode(derived_tag[:], context.temp_allocator))
	testing.expectf(
		t,
		derived_tag_str == tag_str,
		"Expected %s for sum(msg, key), but got %s instead",
		tag_str, derived_tag_str,
	)

	// Incremental
	mem.zero(&derived_tag, size_of(derived_tag))
	ctx: poly1305.Context = ---
	poly1305.init(&ctx, key[:])
	read_lengths := [11]int{32, 64, 16, 8, 4, 2, 1, 1, 1, 1, 1}
	off := 0
	for read_length in read_lengths {
		to_read := msg[off:off + read_length]
		poly1305.update(&ctx, to_read)
		off = off + read_length
	}
	poly1305.final(&ctx, derived_tag[:])
	derived_tag_str = string(hex.encode(derived_tag[:], context.temp_allocator))
	testing.expectf(
		t,
		derived_tag_str == tag_str,
		"Expected %s for init/update/final - incremental, but got %s instead",
		tag_str, derived_tag_str,
	)
}

@(test)
test_siphash_2_4 :: proc(t: ^testing.T) {
	// Test vectors from
	// https://github.com/veorq/SipHash/blob/master/vectors.h
	test_vectors := [?]u64 {
		0x726fdb47dd0e0e31, 0x74f839c593dc67fd, 0x0d6c8009d9a94f5a, 0x85676696d7fb7e2d,
		0xcf2794e0277187b7, 0x18765564cd99a68d, 0xcbc9466e58fee3ce, 0xab0200f58b01d137,
		0x93f5f5799a932462, 0x9e0082df0ba9e4b0, 0x7a5dbbc594ddb9f3, 0xf4b32f46226bada7,
		0x751e8fbc860ee5fb, 0x14ea5627c0843d90, 0xf723ca908e7af2ee, 0xa129ca6149be45e5,
		0x3f2acc7f57c29bdb, 0x699ae9f52cbe4794, 0x4bc1b3f0968dd39c, 0xbb6dc91da77961bd,
		0xbed65cf21aa2ee98, 0xd0f2cbb02e3b67c7, 0x93536795e3a33e88, 0xa80c038ccd5ccec8,
		0xb8ad50c6f649af94, 0xbce192de8a85b8ea, 0x17d835b85bbb15f3, 0x2f2e6163076bcfad,
		0xde4daaaca71dc9a5, 0xa6a2506687956571, 0xad87a3535c49ef28, 0x32d892fad841c342,
		0x7127512f72f27cce, 0xa7f32346f95978e3, 0x12e0b01abb051238, 0x15e034d40fa197ae,
		0x314dffbe0815a3b4, 0x027990f029623981, 0xcadcd4e59ef40c4d, 0x9abfd8766a33735c,
		0x0e3ea96b5304a7d0, 0xad0c42d6fc585992, 0x187306c89bc215a9, 0xd4a60abcf3792b95,
		0xf935451de4f21df2, 0xa9538f0419755787, 0xdb9acddff56ca510, 0xd06c98cd5c0975eb,
		0xe612a3cb9ecba951, 0xc766e62cfcadaf96, 0xee64435a9752fe72, 0xa192d576b245165a,
		0x0a8787bf8ecb74b2, 0x81b3e73d20b49b6f, 0x7fa8220ba3b2ecea, 0x245731c13ca42499,
		0xb78dbfaf3a8d83bd, 0xea1ad565322a1a0b, 0x60e61c23a3795013, 0x6606d7e446282b93,
		0x6ca4ecb15c5f91e1, 0x9f626da15c9625f3, 0xe51b38608ef25f57, 0x958a324ceb064572,
	}

	key: [16]byte
	for i in 0 ..< 16 {
		key[i] = byte(i)
	}

	for i in 0 ..< len(test_vectors) {
		data := make([]byte, i)
		defer delete(data)
		for j in 0 ..< i {
			data[j] = byte(j)
		}

		vector := test_vectors[i]
		computed := siphash.sum_2_4(data[:], key[:])

		testing.expectf(
			t,
			computed == vector,
			"Expected: 0x%x for input of %v, but got 0x%x instead",
			vector,
			data,
			computed,
		)
	}
}
