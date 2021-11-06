package test_core_crypto

import "core:testing"
import "core:fmt"
import "core:time"

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
bench_modern :: proc(t: ^testing.T) {
	fmt.println("Starting benchmarks:")

	bench_poly1305(t)
	bench_x25519(t)
}

_setup_poly1305 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	assert(options != nil)

	options.input = make([]u8, options.bytes, allocator)
	return nil if len(options.input) == options.bytes else .Allocation_Error
}

_teardown_poly1305 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	assert(options != nil)

	delete(options.input)
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

bench_poly1305 :: proc(t: ^testing.T) {
	name    := "Poly1305 64 zero bytes"
	options := &time.Benchmark_Options{
		rounds   = 1_000,
		bytes    = 64,
		setup    = _setup_poly1305,
		bench    = _benchmark_poly1305,
		teardown = _teardown_poly1305,
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
