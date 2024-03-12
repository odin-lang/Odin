package test_core_crypto

/*
	Copyright 2021 zhibog
	Made available under the BSD-3 license.

	List of contributors:
		zhibog, dotbmp:  Initial implementation.
		Jeroen van Rijn: Test runner setup.

	Tests for the various algorithms within the crypto library.
	Where possible, the official test vectors are used to validate the implementation.
*/

import "core:encoding/hex"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:testing"

import "core:crypto"
import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"

import "core:crypto/shake"
import "core:crypto/x25519"

TEST_count := 0
TEST_fail := 0

when ODIN_TEST {
	expect :: testing.expect
	log :: testing.log
} else {
	expect :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}

	test_rand_bytes(&t)

	test_hash(&t)
	test_mac(&t)

	test_chacha20(&t)
	test_chacha20poly1305(&t)
	test_shake(&t)
	test_x25519(&t)

	bench_crypto(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

_PLAINTEXT_SUNSCREEN_STR := "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

@(test)
test_chacha20 :: proc(t: ^testing.T) {
	log(t, "Testing (X)ChaCha20")

	// Test cases taken from RFC 8439, and draft-irtf-cfrg-xchacha-03
	plaintext := transmute([]byte)(_PLAINTEXT_SUNSCREEN_STR)

	key := [chacha20.KEY_SIZE]byte {
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
		0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
		0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
		0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
	}

	nonce := [chacha20.NONCE_SIZE]byte {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4a,
		0x00, 0x00, 0x00, 0x00,
	}

	ciphertext := [114]byte {
		0x6e, 0x2e, 0x35, 0x9a, 0x25, 0x68, 0xf9, 0x80,
		0x41, 0xba, 0x07, 0x28, 0xdd, 0x0d, 0x69, 0x81,
		0xe9, 0x7e, 0x7a, 0xec, 0x1d, 0x43, 0x60, 0xc2,
		0x0a, 0x27, 0xaf, 0xcc, 0xfd, 0x9f, 0xae, 0x0b,
		0xf9, 0x1b, 0x65, 0xc5, 0x52, 0x47, 0x33, 0xab,
		0x8f, 0x59, 0x3d, 0xab, 0xcd, 0x62, 0xb3, 0x57,
		0x16, 0x39, 0xd6, 0x24, 0xe6, 0x51, 0x52, 0xab,
		0x8f, 0x53, 0x0c, 0x35, 0x9f, 0x08, 0x61, 0xd8,
		0x07, 0xca, 0x0d, 0xbf, 0x50, 0x0d, 0x6a, 0x61,
		0x56, 0xa3, 0x8e, 0x08, 0x8a, 0x22, 0xb6, 0x5e,
		0x52, 0xbc, 0x51, 0x4d, 0x16, 0xcc, 0xf8, 0x06,
		0x81, 0x8c, 0xe9, 0x1a, 0xb7, 0x79, 0x37, 0x36,
		0x5a, 0xf9, 0x0b, 0xbf, 0x74, 0xa3, 0x5b, 0xe6,
		0xb4, 0x0b, 0x8e, 0xed, 0xf2, 0x78, 0x5e, 0x42,
		0x87, 0x4d,
	}
	ciphertext_str := string(hex.encode(ciphertext[:], context.temp_allocator))

	derived_ciphertext: [114]byte
	ctx: chacha20.Context = ---
	chacha20.init(&ctx, key[:], nonce[:])
	chacha20.seek(&ctx, 1) // The test vectors start the counter at 1.
	chacha20.xor_bytes(&ctx, derived_ciphertext[:], plaintext[:])

	derived_ciphertext_str := string(hex.encode(derived_ciphertext[:], context.temp_allocator))
	expect(
		t,
		derived_ciphertext_str == ciphertext_str,
		fmt.tprintf(
			"Expected %s for xor_bytes(plaintext_str), but got %s instead",
			ciphertext_str,
			derived_ciphertext_str,
		),
	)

	xkey := [chacha20.KEY_SIZE]byte {
		0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
		0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
		0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
		0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
	}

	xnonce := [chacha20.XNONCE_SIZE]byte {
		0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
		0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
		0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
	}

	xciphertext := [114]byte {
		0xbd, 0x6d, 0x17, 0x9d, 0x3e, 0x83, 0xd4, 0x3b,
		0x95, 0x76, 0x57, 0x94, 0x93, 0xc0, 0xe9, 0x39,
		0x57, 0x2a, 0x17, 0x00, 0x25, 0x2b, 0xfa, 0xcc,
		0xbe, 0xd2, 0x90, 0x2c, 0x21, 0x39, 0x6c, 0xbb,
		0x73, 0x1c, 0x7f, 0x1b, 0x0b, 0x4a, 0xa6, 0x44,
		0x0b, 0xf3, 0xa8, 0x2f, 0x4e, 0xda, 0x7e, 0x39,
		0xae, 0x64, 0xc6, 0x70, 0x8c, 0x54, 0xc2, 0x16,
		0xcb, 0x96, 0xb7, 0x2e, 0x12, 0x13, 0xb4, 0x52,
		0x2f, 0x8c, 0x9b, 0xa4, 0x0d, 0xb5, 0xd9, 0x45,
		0xb1, 0x1b, 0x69, 0xb9, 0x82, 0xc1, 0xbb, 0x9e,
		0x3f, 0x3f, 0xac, 0x2b, 0xc3, 0x69, 0x48, 0x8f,
		0x76, 0xb2, 0x38, 0x35, 0x65, 0xd3, 0xff, 0xf9,
		0x21, 0xf9, 0x66, 0x4c, 0x97, 0x63, 0x7d, 0xa9,
		0x76, 0x88, 0x12, 0xf6, 0x15, 0xc6, 0x8b, 0x13,
		0xb5, 0x2e,
	}
	xciphertext_str := string(hex.encode(xciphertext[:], context.temp_allocator))

	chacha20.init(&ctx, xkey[:], xnonce[:])
	chacha20.seek(&ctx, 1)
	chacha20.xor_bytes(&ctx, derived_ciphertext[:], plaintext[:])

	derived_ciphertext_str = string(hex.encode(derived_ciphertext[:], context.temp_allocator))
	expect(
		t,
		derived_ciphertext_str == xciphertext_str,
		fmt.tprintf(
			"Expected %s for xor_bytes(plaintext_str), but got %s instead",
			xciphertext_str,
			derived_ciphertext_str,
		),
	)
}

@(test)
test_chacha20poly1305 :: proc(t: ^testing.T) {
	log(t, "Testing chacha20poly1205")

	plaintext := transmute([]byte)(_PLAINTEXT_SUNSCREEN_STR)

	aad := [12]byte {
		0x50, 0x51, 0x52, 0x53, 0xc0, 0xc1, 0xc2, 0xc3,
		0xc4, 0xc5, 0xc6, 0xc7,
	}

	key := [chacha20poly1305.KEY_SIZE]byte {
		0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
		0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
		0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
		0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
	}

	nonce := [chacha20poly1305.NONCE_SIZE]byte {
		0x07, 0x00, 0x00, 0x00, 0x40, 0x41, 0x42, 0x43,
		0x44, 0x45, 0x46, 0x47,
	}

	ciphertext := [114]byte {
		0xd3, 0x1a, 0x8d, 0x34, 0x64, 0x8e, 0x60, 0xdb,
		0x7b, 0x86, 0xaf, 0xbc, 0x53, 0xef, 0x7e, 0xc2,
		0xa4, 0xad, 0xed, 0x51, 0x29, 0x6e, 0x08, 0xfe,
		0xa9, 0xe2, 0xb5, 0xa7, 0x36, 0xee, 0x62, 0xd6,
		0x3d, 0xbe, 0xa4, 0x5e, 0x8c, 0xa9, 0x67, 0x12,
		0x82, 0xfa, 0xfb, 0x69, 0xda, 0x92, 0x72, 0x8b,
		0x1a, 0x71, 0xde, 0x0a, 0x9e, 0x06, 0x0b, 0x29,
		0x05, 0xd6, 0xa5, 0xb6, 0x7e, 0xcd, 0x3b, 0x36,
		0x92, 0xdd, 0xbd, 0x7f, 0x2d, 0x77, 0x8b, 0x8c,
		0x98, 0x03, 0xae, 0xe3, 0x28, 0x09, 0x1b, 0x58,
		0xfa, 0xb3, 0x24, 0xe4, 0xfa, 0xd6, 0x75, 0x94,
		0x55, 0x85, 0x80, 0x8b, 0x48, 0x31, 0xd7, 0xbc,
		0x3f, 0xf4, 0xde, 0xf0, 0x8e, 0x4b, 0x7a, 0x9d,
		0xe5, 0x76, 0xd2, 0x65, 0x86, 0xce, 0xc6, 0x4b,
		0x61, 0x16,
	}
	ciphertext_str := string(hex.encode(ciphertext[:], context.temp_allocator))

	tag := [chacha20poly1305.TAG_SIZE]byte {
		0x1a, 0xe1, 0x0b, 0x59, 0x4f, 0x09, 0xe2, 0x6a,
		0x7e, 0x90, 0x2e, 0xcb, 0xd0, 0x60, 0x06, 0x91,
	}
	tag_str := string(hex.encode(tag[:], context.temp_allocator))

	derived_tag: [chacha20poly1305.TAG_SIZE]byte
	derived_ciphertext: [114]byte

	chacha20poly1305.encrypt(
		derived_ciphertext[:],
		derived_tag[:],
		key[:],
		nonce[:],
		aad[:],
		plaintext,
	)

	derived_ciphertext_str := string(hex.encode(derived_ciphertext[:], context.temp_allocator))
	expect(
		t,
		derived_ciphertext_str == ciphertext_str,
		fmt.tprintf(
			"Expected ciphertext %s for encrypt(aad, plaintext), but got %s instead",
			ciphertext_str,
			derived_ciphertext_str,
		),
	)

	derived_tag_str := string(hex.encode(derived_tag[:], context.temp_allocator))
	expect(
		t,
		derived_tag_str == tag_str,
		fmt.tprintf(
			"Expected tag %s for encrypt(aad, plaintext), but got %s instead",
			tag_str,
			derived_tag_str,
		),
	)

	derived_plaintext: [114]byte
	ok := chacha20poly1305.decrypt(
		derived_plaintext[:],
		tag[:],
		key[:],
		nonce[:],
		aad[:],
		ciphertext[:],
	)
	derived_plaintext_str := string(derived_plaintext[:])
	expect(t, ok, "Expected true for decrypt(tag, aad, ciphertext)")
	expect(
		t,
		derived_plaintext_str == _PLAINTEXT_SUNSCREEN_STR,
		fmt.tprintf(
			"Expected plaintext %s for decrypt(tag, aad, ciphertext), but got %s instead",
			_PLAINTEXT_SUNSCREEN_STR,
			derived_plaintext_str,
		),
	)

	derived_ciphertext[0] ~= 0xa5
	ok = chacha20poly1305.decrypt(
		derived_plaintext[:],
		tag[:],
		key[:],
		nonce[:],
		aad[:],
		derived_ciphertext[:],
	)
	expect(t, !ok, "Expected false for decrypt(tag, aad, corrupted_ciphertext)")

	aad[0] ~= 0xa5
	ok = chacha20poly1305.decrypt(
		derived_plaintext[:],
		tag[:],
		key[:],
		nonce[:],
		aad[:],
		ciphertext[:],
	)
	expect(t, !ok, "Expected false for decrypt(tag, corrupted_aad, ciphertext)")
}

TestECDH :: struct {
	scalar:  string,
	point:   string,
	product: string,
}

@(test)
test_x25519 :: proc(t: ^testing.T) {
	log(t, "Testing X25519")

	// Local copy of this so that the base point doesn't need to be exported.
	_BASE_POINT: [32]byte =  {
		9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	}

	test_vectors := [?]TestECDH {
		// Test vectors from RFC 7748
		{
			"a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
			"e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
			"c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
		},
		{
			"4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
			"e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
			"95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
		},
	}
	for v, _ in test_vectors {
		scalar, _ := hex.decode(transmute([]byte)(v.scalar), context.temp_allocator)
		point, _ := hex.decode(transmute([]byte)(v.point), context.temp_allocator)

		derived_point: [x25519.POINT_SIZE]byte
		x25519.scalarmult(derived_point[:], scalar[:], point[:])
		derived_point_str := string(hex.encode(derived_point[:], context.temp_allocator))

		expect(
			t,
			derived_point_str == v.product,
			fmt.tprintf(
				"Expected %s for %s * %s, but got %s instead",
				v.product,
				v.scalar,
				v.point,
				derived_point_str,
			),
		)

		// Abuse the test vectors to sanity-check the scalar-basepoint multiply.
		p1, p2: [x25519.POINT_SIZE]byte
		x25519.scalarmult_basepoint(p1[:], scalar[:])
		x25519.scalarmult(p2[:], scalar[:], _BASE_POINT[:])
		p1_str := string(hex.encode(p1[:], context.temp_allocator))
		p2_str := string(hex.encode(p2[:], context.temp_allocator))
		expect(
			t,
			p1_str == p2_str,
			fmt.tprintf(
				"Expected %s for %s * basepoint, but got %s instead",
				p2_str,
				v.scalar,
				p1_str,
			),
		)
	}

	// TODO/tests: Run the wycheproof test vectors, once I figure out
	// how to work with JSON.
}

@(test)
test_rand_bytes :: proc(t: ^testing.T) {
	log(t, "Testing rand_bytes")

	if ODIN_OS != .Linux {
		log(t, "rand_bytes not supported - skipping")
		return
	}

	allocator := context.allocator

	buf := make([]byte, 1 << 25, allocator)
	defer delete(buf)

	// Testing a CSPRNG for correctness is incredibly involved and
	// beyond the scope of an implementation that offloads
	// responsibility for correctness to the OS.
	//
	// Just attempt to randomize a sufficiently large buffer, where
	// sufficiently large is:
	//  * Larger than the maximum getentropy request size (256 bytes).
	//  * Larger than the maximum getrandom request size (2^25 - 1 bytes).
	//
	// While theoretically non-deterministic, if this fails, chances
	// are the CSPRNG is busted.
	seems_ok := false
	for i := 0; i < 256; i = i + 1 {
		mem.zero_explicit(raw_data(buf), len(buf))
		crypto.rand_bytes(buf)

		if buf[0] != 0 && buf[len(buf) - 1] != 0 {
			seems_ok = true
			break
		}
	}

	expect(
		t,
		seems_ok,
		"Expected to randomize the head and tail of the buffer within a handful of attempts",
	)
}

TestXOF :: struct {
	sec_strength: int,
	output:       string,
	str:          string,
}

@(test)
test_shake :: proc(t: ^testing.T) {
	test_vectors := [?]TestXOF {
		// SHAKE128
		{
			128,
			"7f9c2ba4e88f827d616045507605853e",
			"",
		},
		{
			128,
			"f4202e3c5852f9182a0430fd8144f0a7",
			"The quick brown fox jumps over the lazy dog",
		},
		{
			128,
			"853f4538be0db9621a6cea659a06c110",
			"The quick brown fox jumps over the lazy dof",
		},

		// SHAKE256
		{
			256,
			"46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762f",
			"",
		},
		{
			256,
			"2f671343d9b2e1604dc9dcf0753e5fe15c7c64a0d283cbbf722d411a0e36f6ca",
			"The quick brown fox jumps over the lazy dog",
		},
		{
			256,
			"46b1ebb2e142c38b9ac9081bef72877fe4723959640fa57119b366ce6899d401",
			"The quick brown fox jumps over the lazy dof",
		},
	}
	for v in test_vectors {
		dst := make([]byte, len(v.output)/2, context.temp_allocator)

		data := transmute([]byte)(v.str)

		ctx: shake.Context
		switch v.sec_strength {
		case 128:
			shake.init_128(&ctx)
		case 256:
			shake.init_256(&ctx)
		}

		shake.write(&ctx, data)
		shake.read(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		expect(
			t,
			dst_str == v.output,
			fmt.tprintf(
				"SHAKE%d: Expected: %s for input of %s, but got %s instead",
				v.sec_strength,
				v.output,
				v.str,
				dst_str,
			),
		)
	}
}
