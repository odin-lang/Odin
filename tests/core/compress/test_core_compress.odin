package test_core_compress

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	A test suite for ZLIB, GZIP and Shoco.
*/

import "core:testing"

import "core:compress/zlib"
import "core:compress/gzip"
import "core:compress/shoco"
import "core:bytes"

@test
zlib_test :: proc(t: ^testing.T) {
	ODIN_DEMO := []u8{
		120, 156, 101, 144,  77, 110, 131,  48,  16, 133, 215, 204,  41, 158,  44,
		 69,  73,  32, 148, 182,  75,  35,  14, 208, 125,  47,  96, 185, 195, 143,
		130,  13,  50,  38,  81,  84, 101, 213,  75, 116, 215,  43, 246,   8,  53,
		 82, 126,   8, 181, 188, 152, 153, 111, 222, 147, 159, 123, 165, 247, 170,
		 98,  24, 213,  88, 162, 198, 244, 157, 243,  16, 186, 115,  44,  75, 227,
		  5,  77, 115,  72, 137, 222, 117, 122, 179, 197,  39,  69, 161, 170, 156,
		 50, 144,   5,  68, 130,   4,  49, 126, 127, 190, 191, 144,  34,  19,  57,
		 69,  74, 235, 209, 140, 173, 242, 157, 155,  54, 158, 115, 162, 168,  12,
		181, 239, 246, 108,  17, 188, 174, 242, 224,  20,  13, 199, 198, 235, 250,
		194, 166, 129,  86,   3,  99, 157, 172,  37, 230,  62,  73, 129, 151, 252,
		 70, 211,   5,  77,  31, 104, 188, 160, 113, 129, 215,  59, 205,  22,  52,
		123, 160,  83, 142, 255, 242,  89, 123,  93, 149, 200,  50, 188,  85,  54,
		252,  18, 248, 192, 238, 228, 235, 198,  86, 224, 118, 224, 176, 113, 166,
		112,  67, 106, 227, 159, 122, 215,  88,  95, 110, 196, 123, 205, 183, 224,
		 98,  53,   8, 104, 213, 234, 201, 147,   7, 248, 192,  14, 170,  29,  25,
		171,  15,  18,  59, 138, 112,  63,  23, 205, 110, 254, 136, 109,  78, 231,
		 63, 234, 138, 133, 204,
	}

	buf: bytes.Buffer
	err := zlib.inflate(ODIN_DEMO, &buf)

	testing.expect(t, err == nil, "ZLIB failed to decompress ODIN_DEMO")
	s := bytes.buffer_to_string(&buf)

	testing.expect(t, s[68] == 240 && s[69] == 159 && s[70] == 152, "ZLIB result should've contained 😃 at position 68.")
	testing.expect(t, len(s) == 438, "ZLIB result has an unexpected length.")
	bytes.buffer_destroy(&buf)
}

@test
gzip_test :: proc(t: ^testing.T) {
	// Small GZIP file with fextra, fname and fcomment present.
	TEST: []u8 = {
		0x1f, 0x8b, 0x08, 0x1c, 0xcb, 0x3b, 0x3a, 0x5a,
		0x02, 0x03, 0x07, 0x00, 0x61, 0x62, 0x03, 0x00,
		0x63, 0x64, 0x65, 0x66, 0x69, 0x6c, 0x65, 0x6e,
		0x61, 0x6d, 0x65, 0x00, 0x54, 0x68, 0x69, 0x73,
		0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x63, 0x6f,
		0x6d, 0x6d, 0x65, 0x6e, 0x74, 0x00, 0x2b, 0x48,
		0xac, 0xcc, 0xc9, 0x4f, 0x4c, 0x01, 0x00, 0x15,
		0x6a, 0x2c, 0x42, 0x07, 0x00, 0x00, 0x00,
	}

	buf: bytes.Buffer
	err := gzip.load(TEST, &buf)

	testing.expect(t, err == nil, "GZIP failed to decompress TEST")
	testing.expect(t, bytes.buffer_to_string(&buf) == "payload", "GZIP result wasn't 'payload'")

	bytes.buffer_destroy(&buf)
}

@test
shoco_test :: proc(t: ^testing.T) {

	Shoco_Tests :: []struct{
		compressed:     []u8,
		raw:            []u8,
		short_pack:     int,
		short_sentinel: int,
	}{
		{ #load("../assets/Shoco/README.md.shoco"), #load("../assets/Shoco/README.md"), 10, 1006 },
		{ #load("../assets/Shoco/LICENSE.shoco"),   #load("../assets/Shoco/LICENSE"),   25, 68   },
	}

	for v in Shoco_Tests {
		v := v
		// Compressed source files are not encoded with carriage returns but git replaces raw files lf with crlf on commit (on windows only)
		// So replace crlf with lf on windows
		v.raw, _ = bytes.replace_all(v.raw, { 0xD, 0xA }, { 0xA }, context.temp_allocator)

		expected_raw        := len(v.raw)
		expected_compressed := len(v.compressed)

		biggest_unpacked := shoco.decompress_bound(expected_compressed)
		biggest_packed   := shoco.compress_bound(expected_raw)

		buffer := make([]u8, max(biggest_packed, biggest_unpacked))
		defer delete(buffer)

		size, err := shoco.decompress(v.compressed, buffer[:])
		testing.expectf(t, err == nil, "Expected `decompress` to return `nil`, got %v", err)

		testing.expectf(t, size == expected_raw, "Decompressed %v bytes into %v. Expected to decompress into %v bytes", len(v.compressed), size, expected_raw)
		testing.expect(t, string(buffer[:size]) == string(v.raw), "Decompressed contents don't match")

		size, err = shoco.compress(string(v.raw), buffer[:])
		testing.expect(t, err == nil, "Expected `compress` to return `nil`.")

		testing.expectf(t, size == expected_compressed, "Compressed %v bytes into %v. Expected to compress into %v bytes", expected_raw, size, expected_compressed)

		size, err = shoco.decompress(v.compressed, buffer[:expected_raw - 10])
		testing.expectf(t, err == .Output_Too_Short, "Decompressing into too small a buffer returned %v, expected `.Output_Too_Short`", err)

		size, err = shoco.compress(string(v.raw), buffer[:expected_compressed - 10])
		testing.expectf(t, err == .Output_Too_Short, "Compressing into too small a buffer returned %v, expected `.Output_Too_Short`", err)

		size, err = shoco.decompress(v.compressed[:v.short_pack], buffer[:])
		testing.expectf(t, err == .Stream_Too_Short, "Insufficient data after pack returned %v, expected `.Stream_Too_Short`", err)

		size, err = shoco.decompress(v.compressed[:v.short_sentinel], buffer[:])
		testing.expectf(t, err == .Stream_Too_Short, "No more data after non-ASCII sentinel returned %v, expected `.Stream_Too_Short`", err)
	}
}
