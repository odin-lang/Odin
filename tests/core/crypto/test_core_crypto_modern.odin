package test_core_crypto

import "core:testing"
import "core:fmt"
import "core:time"

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

	bench_x25519(t)
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
