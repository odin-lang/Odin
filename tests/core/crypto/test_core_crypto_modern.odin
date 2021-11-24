package test_core_crypto

import "core:testing"
import "core:fmt"
import "core:mem"
import "core:time"
import "core:crypto"

import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"
import "core:crypto/poly1305"
import "core:crypto/x25519"

_digit_value :: proc(r: rune) -> int {
	ri := int(r)
	v: int = 16
	switch r {
	case '0'..='9': v = ri-'0'
	case 'a'..='z': v = ri-'a'+10
	case 'A'..='Z': v = ri-'A'+10
	}
	return v
}

_decode_hex32 :: proc(s: string) -> [32]byte{
	b: [32]byte
	for i := 0; i < len(s); i = i + 2 {
		hi := _digit_value(rune(s[i]))
		lo := _digit_value(rune(s[i+1]))
		b[i/2] = byte(hi << 4 | lo)
	}
	return b
}

_PLAINTEXT_SUNSCREEN_STR := "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

@(test)
test_chacha20 :: proc(t: ^testing.T) {
	log(t, "Testing (X)ChaCha20")

	// Test cases taken from RFC 8439, and draft-irtf-cfrg-xchacha-03
	plaintext := transmute([]byte)(_PLAINTEXT_SUNSCREEN_STR)

	key := [chacha20.KEY_SIZE]byte{
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
		0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
		0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
		0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
	}

	nonce := [chacha20.NONCE_SIZE]byte{
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4a,
		0x00, 0x00, 0x00, 0x00,
	}

	ciphertext := [114]byte{
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
	ciphertext_str := hex_string(ciphertext[:])

	derived_ciphertext: [114]byte
	ctx: chacha20.Context = ---
	chacha20.init(&ctx, key[:], nonce[:])
	chacha20.seek(&ctx, 1) // The test vectors start the counter at 1.
	chacha20.xor_bytes(&ctx, derived_ciphertext[:], plaintext[:])

	derived_ciphertext_str := hex_string(derived_ciphertext[:])
	expect(t, derived_ciphertext_str == ciphertext_str, fmt.tprintf("Expected %s for xor_bytes(plaintext_str), but got %s instead", ciphertext_str, derived_ciphertext_str))

	xkey := [chacha20.KEY_SIZE]byte{
		0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
		0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
		0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
		0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
	}

	xnonce := [chacha20.XNONCE_SIZE]byte{
		0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
		0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
		0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
	}

	xciphertext := [114]byte{
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
	xciphertext_str := hex_string(xciphertext[:])

	chacha20.init(&ctx, xkey[:], xnonce[:])
	chacha20.seek(&ctx, 1)
	chacha20.xor_bytes(&ctx, derived_ciphertext[:], plaintext[:])

	derived_ciphertext_str = hex_string(derived_ciphertext[:])
	expect(t, derived_ciphertext_str == xciphertext_str, fmt.tprintf("Expected %s for xor_bytes(plaintext_str), but got %s instead", xciphertext_str, derived_ciphertext_str))
}

@(test)
test_poly1305 :: proc(t: ^testing.T) {
	log(t, "Testing poly1305")

	// Test cases taken from poly1305-donna.
	key := [poly1305.KEY_SIZE]byte{
		0xee,0xa6,0xa7,0x25,0x1c,0x1e,0x72,0x91,
		0x6d,0x11,0xc2,0xcb,0x21,0x4d,0x3c,0x25,
		0x25,0x39,0x12,0x1d,0x8e,0x23,0x4e,0x65,
		0x2d,0x65,0x1f,0xa4,0xc8,0xcf,0xf8,0x80,
	}

	msg := [131]byte{
		0x8e,0x99,0x3b,0x9f,0x48,0x68,0x12,0x73,
		0xc2,0x96,0x50,0xba,0x32,0xfc,0x76,0xce,
		0x48,0x33,0x2e,0xa7,0x16,0x4d,0x96,0xa4,
		0x47,0x6f,0xb8,0xc5,0x31,0xa1,0x18,0x6a,
		0xc0,0xdf,0xc1,0x7c,0x98,0xdc,0xe8,0x7b,
		0x4d,0xa7,0xf0,0x11,0xec,0x48,0xc9,0x72,
		0x71,0xd2,0xc2,0x0f,0x9b,0x92,0x8f,0xe2,
		0x27,0x0d,0x6f,0xb8,0x63,0xd5,0x17,0x38,
		0xb4,0x8e,0xee,0xe3,0x14,0xa7,0xcc,0x8a,
		0xb9,0x32,0x16,0x45,0x48,0xe5,0x26,0xae,
		0x90,0x22,0x43,0x68,0x51,0x7a,0xcf,0xea,
		0xbd,0x6b,0xb3,0x73,0x2b,0xc0,0xe9,0xda,
		0x99,0x83,0x2b,0x61,0xca,0x01,0xb6,0xde,
		0x56,0x24,0x4a,0x9e,0x88,0xd5,0xf9,0xb3,
		0x79,0x73,0xf6,0x22,0xa4,0x3d,0x14,0xa6,
		0x59,0x9b,0x1f,0x65,0x4c,0xb4,0x5a,0x74,
		0xe3,0x55,0xa5,
	}

	tag := [poly1305.TAG_SIZE]byte{
		0xf3,0xff,0xc7,0x70,0x3f,0x94,0x00,0xe5,
		0x2a,0x7d,0xfb,0x4b,0x3d,0x33,0x05,0xd9,
	}
	tag_str := hex_string(tag[:])

	// Verify - oneshot + compare
	ok := poly1305.verify(tag[:], msg[:], key[:])
	expect(t, ok, "oneshot verify call failed")

	// Sum - oneshot
	derived_tag: [poly1305.TAG_SIZE]byte
	poly1305.sum(derived_tag[:], msg[:], key[:])
	derived_tag_str := hex_string(derived_tag[:])
	expect(t, derived_tag_str == tag_str, fmt.tprintf("Expected %s for sum(msg, key), but got %s instead", tag_str, derived_tag_str))

	// Incremental
	mem.zero(&derived_tag, size_of(derived_tag))
	ctx: poly1305.Context = ---
	poly1305.init(&ctx, key[:])
	read_lengths := [11]int{32, 64, 16, 8, 4, 2, 1, 1, 1, 1, 1}
	off := 0
	for read_length in read_lengths {
		to_read := msg[off:off+read_length]
		poly1305.update(&ctx, to_read)
		off = off + read_length
	}
	poly1305.final(&ctx, derived_tag[:])
	derived_tag_str = hex_string(derived_tag[:])
	expect(t, derived_tag_str == tag_str, fmt.tprintf("Expected %s for init/update/final - incremental, but got %s instead", tag_str, derived_tag_str))
}

@(test)
test_chacha20poly1305 :: proc(t: ^testing.T) {
	log(t, "Testing chacha20poly1205")

	plaintext := transmute([]byte)(_PLAINTEXT_SUNSCREEN_STR)

	aad := [12]byte{
		0x50, 0x51, 0x52, 0x53, 0xc0, 0xc1, 0xc2, 0xc3,
		0xc4, 0xc5, 0xc6, 0xc7,
	}

	key := [chacha20poly1305.KEY_SIZE]byte{
		0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
		0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
		0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
		0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
	}

	nonce := [chacha20poly1305.NONCE_SIZE]byte{
		0x07, 0x00, 0x00, 0x00,
		0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
	}

	ciphertext := [114]byte{
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
	ciphertext_str := hex_string(ciphertext[:])

	tag := [chacha20poly1305.TAG_SIZE]byte{
		0x1a, 0xe1, 0x0b, 0x59, 0x4f, 0x09, 0xe2, 0x6a,
		0x7e, 0x90, 0x2e, 0xcb, 0xd0, 0x60, 0x06, 0x91,
	}
	tag_str := hex_string(tag[:])

	derived_tag: [chacha20poly1305.TAG_SIZE]byte
	derived_ciphertext: [114]byte

	chacha20poly1305.encrypt(derived_ciphertext[:], derived_tag[:], key[:], nonce[:], aad[:], plaintext)

	derived_ciphertext_str := hex_string(derived_ciphertext[:])
	expect(t, derived_ciphertext_str == ciphertext_str, fmt.tprintf("Expected ciphertext %s for encrypt(aad, plaintext), but got %s instead", ciphertext_str, derived_ciphertext_str))

	derived_tag_str := hex_string(derived_tag[:])
	expect(t, derived_tag_str == tag_str, fmt.tprintf("Expected tag %s for encrypt(aad, plaintext), but got %s instead", tag_str, derived_tag_str))

	derived_plaintext: [114]byte
	ok := chacha20poly1305.decrypt(derived_plaintext[:], tag[:], key[:], nonce[:], aad[:], ciphertext[:])
	derived_plaintext_str := string(derived_plaintext[:])
	expect(t, ok, "Expected true for decrypt(tag, aad, ciphertext)")
	expect(t, derived_plaintext_str == _PLAINTEXT_SUNSCREEN_STR, fmt.tprintf("Expected plaintext %s for decrypt(tag, aad, ciphertext), but got %s instead", _PLAINTEXT_SUNSCREEN_STR, derived_plaintext_str))

	derived_ciphertext[0] ~= 0xa5
	ok = chacha20poly1305.decrypt(derived_plaintext[:], tag[:], key[:], nonce[:], aad[:], derived_ciphertext[:])
	expect(t, !ok, "Expected false for decrypt(tag, aad, corrupted_ciphertext)")

	aad[0] ~= 0xa5
	ok = chacha20poly1305.decrypt(derived_plaintext[:], tag[:], key[:], nonce[:], aad[:], ciphertext[:])
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

	test_vectors := [?]TestECDH {
		// Test vectors from RFC 7748
		TestECDH{
			"a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
			"e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
			"c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
		},
		TestECDH{
			"4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
			"e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
			"95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
		},
	}
	for v, _ in test_vectors {
		scalar := _decode_hex32(v.scalar)
		point := _decode_hex32(v.point)

		derived_point: [x25519.POINT_SIZE]byte
		x25519.scalarmult(derived_point[:], scalar[:], point[:])
		derived_point_str := hex_string(derived_point[:])

		expect(t, derived_point_str == v.product, fmt.tprintf("Expected %s for %s * %s, but got %s instead", v.product, v.scalar, v.point, derived_point_str))

		// Abuse the test vectors to sanity-check the scalar-basepoint multiply.
		p1, p2: [x25519.POINT_SIZE]byte
		x25519.scalarmult_basepoint(p1[:], scalar[:])
		x25519.scalarmult(p2[:], scalar[:], x25519._BASE_POINT[:])
		p1_str, p2_str := hex_string(p1[:]), hex_string(p2[:])
		expect(t, p1_str == p2_str, fmt.tprintf("Expected %s for %s * basepoint, but got %s instead", p2_str, v.scalar, p1_str))
	}

    // TODO/tests: Run the wycheproof test vectors, once I figure out
    // how to work with JSON.
}

@(test)
test_rand_bytes :: proc(t: ^testing.T) {
	log(t, "Testing rand_bytes")

	if ODIN_OS != "linux" {
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

		if buf[0] != 0 && buf[len(buf)-1] != 0 {
			seems_ok = true
			break
		}
	}

	expect(t, seems_ok, "Expected to randomize the head and tail of the buffer within a handful of attempts")
}

@(test)
bench_modern :: proc(t: ^testing.T) {
	fmt.println("Starting benchmarks:")

	bench_chacha20(t)
	bench_poly1305(t)
	bench_chacha20poly1305(t)
	bench_x25519(t)
}

_setup_sized_buf :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	assert(options != nil)

	options.input = make([]u8, options.bytes, allocator)
	return nil if len(options.input) == options.bytes else .Allocation_Error
}

_teardown_sized_buf :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	assert(options != nil)

	delete(options.input)
	return nil
}

_benchmark_chacha20 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input
	key := [chacha20.KEY_SIZE]byte{
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	nonce := [chacha20.NONCE_SIZE]byte{
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
	}

	ctx: chacha20.Context = ---
	chacha20.init(&ctx, key[:], nonce[:])

	for _ in 0..=options.rounds {
		chacha20.xor_bytes(&ctx, buf, buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

_benchmark_poly1305 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input
	key := [poly1305.KEY_SIZE]byte{
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}

	tag: [poly1305.TAG_SIZE]byte = ---
	for _ in 0..=options.rounds {
		poly1305.sum(tag[:], buf, key[:])
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	//options.hash      = u128(h)
	return nil
}

_benchmark_chacha20poly1305 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input
	key := [chacha20.KEY_SIZE]byte{
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	nonce := [chacha20.NONCE_SIZE]byte{
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
	}

	tag: [chacha20poly1305.TAG_SIZE]byte = ---

	for _ in 0..=options.rounds {
		chacha20poly1305.encrypt(buf,tag[:], key[:], nonce[:], nil, buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

benchmark_print :: proc(name: string, options: ^time.Benchmark_Options) {
	fmt.printf("\t[%v] %v rounds, %v bytes processed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s\n",
		name,
		options.rounds,
		options.processed,
		time.duration_nanoseconds(options.duration),
		options.rounds_per_second,
		options.megabytes_per_second,
	)
}

bench_chacha20 :: proc(t: ^testing.T) {
	name    := "ChaCha20 64 bytes"
	options := &time.Benchmark_Options{
		rounds   = 1_000,
		bytes    = 64,
		setup    = _setup_sized_buf,
		bench    = _benchmark_chacha20,
		teardown = _teardown_sized_buf,
	}

	err  := time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "ChaCha20 1024 bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "ChaCha20 65536 bytes"
	options.bytes = 65536
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_poly1305 :: proc(t: ^testing.T) {
	name    := "Poly1305 64 zero bytes"
	options := &time.Benchmark_Options{
		rounds   = 1_000,
		bytes    = 64,
		setup    = _setup_sized_buf,
		bench    = _benchmark_poly1305,
		teardown = _teardown_sized_buf,
	}

	err  := time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "Poly1305 1024 zero bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_chacha20poly1305 :: proc(t: ^testing.T) {
	name    := "chacha20poly1305 64 bytes"
	options := &time.Benchmark_Options{
		rounds   = 1_000,
		bytes    = 64,
		setup    = _setup_sized_buf,
		bench    = _benchmark_chacha20poly1305,
		teardown = _teardown_sized_buf,
	}

	err  := time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "chacha20poly1305 1024 bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "chacha20poly1305 65536 bytes"
	options.bytes = 65536
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_x25519 :: proc(t: ^testing.T) {
	point := _decode_hex32("deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
	scalar := _decode_hex32("cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe")
	out: [x25519.POINT_SIZE]byte = ---

	iters :: 10000
	start := time.now()
	for i := 0; i < iters; i = i + 1 {
		x25519.scalarmult(out[:], scalar[:], point[:])
	}
	elapsed := time.since(start)

	log(t, fmt.tprintf("x25519.scalarmult: ~%f us/op", time.duration_microseconds(elapsed) / iters))
}
