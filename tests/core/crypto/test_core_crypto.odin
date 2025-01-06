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
import "core:mem"
import "core:testing"
import "base:runtime"
import "core:log"

import "core:crypto"
import chacha_simd128 "core:crypto/_chacha20/simd128"
import chacha_simd256 "core:crypto/_chacha20/simd256"
import "core:crypto/chacha20"
import "core:crypto/sha2"

@(private)
_PLAINTEXT_SUNSCREEN_STR := "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

@(test)
test_chacha20 :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	impls := supported_chacha_impls()

	for impl in impls {
		test_chacha20_stream(t, impl)
	}
}

supported_chacha_impls :: proc() -> [dynamic]chacha20.Implementation {
	impls := make([dynamic]chacha20.Implementation, 0, 3, context.temp_allocator)
	append(&impls, chacha20.Implementation.Portable)
	if chacha_simd128.is_performant() {
		append(&impls, chacha20.Implementation.Simd128)
	}
	if chacha_simd256.is_performant() {
		append(&impls, chacha20.Implementation.Simd256)
	}

	return impls
}

test_chacha20_stream :: proc(t: ^testing.T, impl: chacha20.Implementation) {
	// Test cases taken from RFC 8439, and draft-irtf-cfrg-xchacha-03
	plaintext := transmute([]byte)(_PLAINTEXT_SUNSCREEN_STR)

	key := [chacha20.KEY_SIZE]byte {
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
		0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
		0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
		0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
	}

	iv := [chacha20.IV_SIZE]byte {
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
	chacha20.init(&ctx, key[:], iv[:], impl)
	chacha20.seek(&ctx, 1) // The test vectors start the counter at 1.
	chacha20.xor_bytes(&ctx, derived_ciphertext[:], plaintext[:])

	derived_ciphertext_str := string(hex.encode(derived_ciphertext[:], context.temp_allocator))
	testing.expectf(
		t,
		derived_ciphertext_str == ciphertext_str,
		"chacha20/%v: Expected %s for xor_bytes(plaintext_str), but got %s instead",
		impl,
		ciphertext_str,
		derived_ciphertext_str,
	)

	xkey := [chacha20.KEY_SIZE]byte {
		0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
		0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
		0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
		0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
	}

	xiv := [chacha20.XIV_SIZE]byte {
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

	chacha20.init(&ctx, xkey[:], xiv[:], impl)
	chacha20.seek(&ctx, 1)
	chacha20.xor_bytes(&ctx, derived_ciphertext[:], plaintext[:])

	derived_ciphertext_str = string(hex.encode(derived_ciphertext[:], context.temp_allocator))
	testing.expectf(
		t,
		derived_ciphertext_str == xciphertext_str,
		"chacha20/%v: Expected %s for xor_bytes(plaintext_str), but got %s instead",
		impl,
		xciphertext_str,
		derived_ciphertext_str,
	)

	// Incrementally read 1, 2, 3, ..., 2048 bytes of keystream, and
	// compare the SHA-512/256 digest with a known value.  Results
	// and testcase taken from a known good implementation by the
	// same author as the Odin test case.

	tmp := make([]byte, 2048, context.temp_allocator)

	mem.zero(&key, size_of(key))
	mem.zero(&iv, size_of(iv))
	chacha20.init(&ctx, key[:], iv[:], impl)

	h_ctx: sha2.Context_512
	sha2.init_512_256(&h_ctx)

	for i := 1; i <= 2048; i = i + 1 {
		chacha20.keystream_bytes(&ctx, tmp[:i])
		sha2.update(&h_ctx, tmp[:i])
	}

	digest: [32]byte
	sha2.final(&h_ctx, digest[:])
	digest_str := string(hex.encode(digest[:], context.temp_allocator))

	expected_digest_str := "cfd6e949225b854fe04946491e6935ff05ff983d1554bc885bca0ec8082dd5b8"
	testing.expectf(
		t,
		expected_digest_str == digest_str,
		"chacha20/%v: Expected %s for keystream digest, but got %s instead",
		impl,
		expected_digest_str,
		digest_str,
	)
}

@(test)
test_rand_bytes :: proc(t: ^testing.T) {
	if !crypto.HAS_RAND_BYTES {
		log.info("rand_bytes not supported - skipping")
		return
	}

	buf := make([]byte, 1 << 25, context.allocator)
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
	testing.expect(t, seems_ok, "Expected to randomize the head and tail of the buffer within a handful of attempts")
}
