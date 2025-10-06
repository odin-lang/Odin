#+feature dynamic-literals
package test_core_hash

import "core:hash"
import "core:testing"
import "base:intrinsics"

/*
	Built-in `#hash`es:
		#hash("murmur32"),
		#hash("murmur64"),
	};
*/

V32 :: struct{s: string, h: u32}
V64 :: struct{s: string, h: u64}

@test
test_adler32_vectors :: proc(t: ^testing.T) {
	vectors :: []V32{
		{""             , 0x00000001},
		{"a"            , 0x00620062},
		{"abc"          , 0x024d0127},
		{"Hello"        , 0x058c01f5},
		{"world"        , 0x06a60229},
		{"Hello, world!", 0x205e048a},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		adler := hash.adler32(b)
		testing.expectf(t, adler == vector.h, "\n\t[ADLER-32(%v)] Expected: 0x%08x, got: 0x%08x", vector.s, vector.h, adler)
	}

	testing.expect_value(t, #hash(vectors[0].s, "adler32"), int(vectors[0].h))
	testing.expect_value(t, #hash(vectors[1].s, "adler32"), int(vectors[1].h))
	testing.expect_value(t, #hash(vectors[2].s, "adler32"), int(vectors[2].h))
	testing.expect_value(t, #hash(vectors[3].s, "adler32"), int(vectors[3].h))
	testing.expect_value(t, #hash(vectors[4].s, "adler32"), int(vectors[4].h))
	testing.expect_value(t, #hash(vectors[5].s, "adler32"), int(vectors[5].h))
}

@test
test_djb2_vectors :: proc(t: ^testing.T) {
	vectors :: []V32{
		{""             , 5381}, // Initial seed
		{"a"            , 0x0002b606},
		{"abc"          , 0x0b885c8b},
		{"Hello"        , 0x0d4f2079},
		{"world"        , 0x10a7356d},
		{"Hello, world!", 0xe18796ae},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		djb2 := hash.djb2(b)
		testing.expectf(t, djb2 == vector.h, "\n\t[DJB-2(%v)] Expected: 0x%08x, got: 0x%08x", vector.s, vector.h, djb2)
	}
}

@test
test_fnv32_vectors :: proc(t: ^testing.T) {
	vectors :: []V32{
		{""             , 0x811c9dc5},
		{"a"            , 0x050c5d7e},
		{"abc"          , 0x439c2f4b},
		{"Hello"        , 0x3726bd47},
		{"world"        , 0x9b8e862f},
		{"Hello, world!", 0xe84ead66},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		fnv := hash.fnv32_no_a(b)
		testing.expectf(t, fnv == vector.h, "\n\t[FNV-32(%v)] Expected: 0x%08x, got: 0x%08x", vector.s, vector.h, fnv)
	}

	testing.expect_value(t, #hash(vectors[0].s, "fnv32"), int(vectors[0].h))
	testing.expect_value(t, #hash(vectors[1].s, "fnv32"), int(vectors[1].h))
	testing.expect_value(t, #hash(vectors[2].s, "fnv32"), int(vectors[2].h))
	testing.expect_value(t, #hash(vectors[3].s, "fnv32"), int(vectors[3].h))
	testing.expect_value(t, #hash(vectors[4].s, "fnv32"), int(vectors[4].h))
	testing.expect_value(t, #hash(vectors[5].s, "fnv32"), int(vectors[5].h))
}

@test
test_fnv64_vectors :: proc(t: ^testing.T) {
	vectors :: []V64{
		{""             , 0xcbf29ce484222325},
		{"a"            , 0xaf63bd4c8601b7be},
		{"abc"          , 0xd8dcca186bafadcb},
		{"Hello"        , 0xfa365282a44c0ba7},
		{"world"        , 0x3ec0cf0cc4a6540f},
		{"Hello, world!", 0x6519bd6389aaa166},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		fnv := hash.fnv64_no_a(b)
		testing.expectf(t, fnv == vector.h, "\n\t[FNV-64(%v)] Expected: 0x%16x, got: 0x%16x", vector.s, vector.h, fnv)
	}

	testing.expect_value(t, i128(#hash(vectors[0].s, "fnv64")), i128(vectors[0].h))
	testing.expect_value(t, i128(#hash(vectors[1].s, "fnv64")), i128(vectors[1].h))
	testing.expect_value(t, i128(#hash(vectors[2].s, "fnv64")), i128(vectors[2].h))
	testing.expect_value(t, i128(#hash(vectors[3].s, "fnv64")), i128(vectors[3].h))
	testing.expect_value(t, i128(#hash(vectors[4].s, "fnv64")), i128(vectors[4].h))
	testing.expect_value(t, i128(#hash(vectors[5].s, "fnv64")), i128(vectors[5].h))
}

@test
test_fnv32a_vectors :: proc(t: ^testing.T) {
	vectors :: []V32{
		{""             , 0x811c9dc5},
		{"a"            , 0xe40c292c},
		{"abc"          , 0x1a47e90b},
		{"Hello"        , 0xf55c314b},
		{"world"        , 0x37a3e893},
		{"Hello, world!", 0xed90f094},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		fnv := hash.fnv32a(b)
		testing.expectf(t, fnv == vector.h, "\n\t[FNV-32a(%v)] Expected: 0x%08x, got: 0x%08x", vector.s, vector.h, fnv)
	}

	testing.expect_value(t, #hash(vectors[0].s, "fnv32a"), int(vectors[0].h))
	testing.expect_value(t, #hash(vectors[1].s, "fnv32a"), int(vectors[1].h))
	testing.expect_value(t, #hash(vectors[2].s, "fnv32a"), int(vectors[2].h))
	testing.expect_value(t, #hash(vectors[3].s, "fnv32a"), int(vectors[3].h))
	testing.expect_value(t, #hash(vectors[4].s, "fnv32a"), int(vectors[4].h))
	testing.expect_value(t, #hash(vectors[5].s, "fnv32a"), int(vectors[5].h))
}

@test
test_fnv64a_vectors :: proc(t: ^testing.T) {
	vectors :: []V64{
		{""             , 0xcbf29ce484222325},
		{"a"            , 0xaf63dc4c8601ec8c},
		{"abc"          , 0xe71fa2190541574b},
		{"Hello"        , 0x63f0bfacf2c00f6b},
		{"world"        , 0x4f59ff5e730c8af3},
		{"Hello, world!", 0x38d1334144987bf4},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		fnv := hash.fnv64a(b)
		testing.expectf(t, fnv == vector.h, "\n\t[FNV-64a(%v)] Expected: 0x%16x, got: 0x%16x", vector.s, vector.h, fnv)
	}

	testing.expect_value(t, i128(#hash(vectors[0].s, "fnv64a")), i128(vectors[0].h))
	testing.expect_value(t, i128(#hash(vectors[1].s, "fnv64a")), i128(vectors[1].h))
	testing.expect_value(t, i128(#hash(vectors[2].s, "fnv64a")), i128(vectors[2].h))
	testing.expect_value(t, i128(#hash(vectors[3].s, "fnv64a")), i128(vectors[3].h))
	testing.expect_value(t, i128(#hash(vectors[4].s, "fnv64a")), i128(vectors[4].h))
	testing.expect_value(t, i128(#hash(vectors[5].s, "fnv64a")), i128(vectors[5].h))
}

@test
test_crc32_vectors :: proc(t: ^testing.T) {
	vectors :: []V32{
		{""             , 0x00000000},
		{"a"            , 0xe8b7be43},
		{"abc"          , 0x352441c2},
		{"Hello"        , 0xf7d18982},
		{"world"        , 0x3a771143},
		{"Hello, world!", 0xebe6c6e6},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		crc := hash.crc32(b)
		testing.expectf(t, crc == vector.h, "\n\t[CRC-32(%v)] Expected: 0x%08x, got: 0x%08x", vector.s, vector.h, crc)
	}

	testing.expect_value(t, #hash(vectors[0].s, "crc32"), int(vectors[0].h))
	testing.expect_value(t, #hash(vectors[1].s, "crc32"), int(vectors[1].h))
	testing.expect_value(t, #hash(vectors[2].s, "crc32"), int(vectors[2].h))
	testing.expect_value(t, #hash(vectors[3].s, "crc32"), int(vectors[3].h))
	testing.expect_value(t, #hash(vectors[4].s, "crc32"), int(vectors[4].h))
	testing.expect_value(t, #hash(vectors[5].s, "crc32"), int(vectors[5].h))
}

@test
test_crc64_vectors :: proc(t: ^testing.T) {
	vectors := map[string][4]u64 {
		"123456789" = {
			0x6c40df5f0b497347, // ECMA-182,
			0x995dc9bbdf1939fa, // XZ
			0x46a5a9388a5beffe, // ISO 3306
			0xb90956c775a41001, // ISO 3306, input and output inverted
		},
		"This is a test of the emergency broadcast system." = {
			0x344fe1d09c983d13, // ECMA-182
			0x27db187fc15bbc72, // XZ
			0x187184d744afc49e, // ISO 3306
			0xe7fcf1006b503b61, // ISO 3306, input and output inverted
		},
	}
	defer delete(vectors)

	for vector, expected in vectors {
		b := transmute([]u8)vector
		ecma := hash.crc64_ecma_182(b)
		xz   := hash.crc64_xz(b)
		iso  := hash.crc64_iso_3306(b)
		iso2 := hash.crc64_iso_3306_inverse(b)

		testing.expectf(t, ecma == expected[0], "[ CRC-64 ECMA    ] Expected: %016x, got: %016x", expected[0], ecma)
		testing.expectf(t, xz   == expected[1], "[ CRC-64 XZ      ] Expected: %016x, got: %016x", expected[1], xz)
		testing.expectf(t, iso  == expected[2], "[ CRC-64 ISO 3306] Expected: %016x, got: %016x", expected[2], iso)
		testing.expectf(t, iso2 == expected[3], "[~CRC-64 ISO 3306] Expected: %016x, got: %016x", expected[3], iso2)
	}
}

@test
test_murmur32_vectors :: proc(t: ^testing.T) {
	vectors :: []V32{
		{""             , 0xebb6c228},
		{"a"            , 0x7fa09ea6},
		{"abc"          , 0xc84a62dd},
		{"Hello"        , 0xec73fdbe},
		{"world"        , 0xd7f8a5f2},
		{"Hello, world!", 0x24884cba},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		murmur := hash.murmur32(b)
		testing.expectf(t, murmur == vector.h, "\n\t[MURMUR-32(%v)] Expected: 0x%08x, got: 0x%08x", vector.s, vector.h, murmur)
	}

	testing.expect_value(t, #hash(vectors[0].s, "murmur32"), int(vectors[0].h))
	testing.expect_value(t, #hash(vectors[1].s, "murmur32"), int(vectors[1].h))
	testing.expect_value(t, #hash(vectors[2].s, "murmur32"), int(vectors[2].h))
	testing.expect_value(t, #hash(vectors[3].s, "murmur32"), int(vectors[3].h))
	testing.expect_value(t, #hash(vectors[4].s, "murmur32"), int(vectors[4].h))
	testing.expect_value(t, #hash(vectors[5].s, "murmur32"), int(vectors[5].h))
}

@test
test_murmur64_vectors :: proc(t: ^testing.T) {
	vectors :: []V64{
		{""             , 0x8397626cd6895052},
		{"a"            , 0xe96b6245652273ae},
		{"abc"          , 0xa9316c8740c81414},
		{"Hello"        , 0x89cc3a85a7045a4f},
		{"world"        , 0xf030e222b1f740f6},
		{"Hello, world!", 0x710583fa7f802a84},
	}

	for vector in vectors {
		b := transmute([]u8)vector.s
		murmur := hash.murmur64a(b)
		testing.expectf(t, murmur == vector.h, "\n\t[MURMUR-64(%v)] Expected: 0x%16x, got: 0x%16x", vector.s, vector.h, murmur)
	}

	testing.expect_value(t, i128(#hash(vectors[0].s, "murmur64")), i128(vectors[0].h))
	testing.expect_value(t, i128(#hash(vectors[1].s, "murmur64")), i128(vectors[1].h))
	testing.expect_value(t, i128(#hash(vectors[2].s, "murmur64")), i128(vectors[2].h))
	testing.expect_value(t, i128(#hash(vectors[3].s, "murmur64")), i128(vectors[3].h))
	testing.expect_value(t, i128(#hash(vectors[4].s, "murmur64")), i128(vectors[4].h))
	testing.expect_value(t, i128(#hash(vectors[5].s, "murmur64")), i128(vectors[5].h))
}