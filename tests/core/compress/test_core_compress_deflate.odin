package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:hash"
import "core:math/rand"
import "core:testing"

Deflate_Format :: enum {
	Raw,
	ZLIB,
	GZIP,
}

DEFLATE_TEST_LEVELS :: [?]deflate.Deflate_Level{.Stored, .Level_1, .Level_2, .Level_5, .Level_6, .Level_9, .Level_10}
DEFLATE_TEST_TRAILER :: [5]byte{'O', 'd', 'i', 'n', '!'}

deflate_test_pack :: proc(format: Deflate_Format, input: []byte, output: ^[dynamic]byte, level: deflate.Deflate_Level) -> compress.Error {
	switch format {
	case .Raw:  return deflate.deflate_raw(output, input, level)
	case .ZLIB: return deflate.deflate_zlib(output, input, level)
	case .GZIP: return deflate.deflate_gzip(output, input, level)
	}
	return nil
}

deflate_test_unpack :: proc(format: Deflate_Format, ctx: ^compress.Context) -> compress.Error {
	switch format {
	case .Raw:  return deflate.inflate_raw(ctx)
	case .ZLIB: return deflate.inflate_zlib(ctx)
	case .GZIP: return deflate.inflate_gzip(ctx)
	}
	return nil
}

deflate_test_round_trip :: proc(t: ^testing.T, name: string, data: []byte) {
	for format in Deflate_Format {
		for level in DEFLATE_TEST_LEVELS {
			packed: [dynamic]byte
			defer delete(packed)
			err := deflate_test_pack(format, data, &packed, level)
			testing.expectf(t, err == nil, "%v, %v, %v: deflate returned %v", name, format, level, err)
			if err != nil {
				continue
			}
			trailer := DEFLATE_TEST_TRAILER
			append(&packed, ..trailer[:])

			for kind in Stream_Kind {
				input := packed[:]
				br: bytes.Reader
				tr: Trickle_Reader
				output: [dynamic]byte
				defer delete(output)
				ctx := stream_test_context(kind, &input, &br, &tr, &output)
				defer compress.destroy_context(&ctx)

				unpack_err := deflate_test_unpack(format, &ctx)
				testing.expectf(t, unpack_err == nil, "%v, %v, %v, %v: inflate returned %v", name, format, level, kind, unpack_err)
				testing.expectf(t, bytes.equal(output[:], data), "%v, %v, %v, %v: output differs", name, format, level, kind)

				rest: [5]byte
				rest_err := compress.read_slice(&ctx, rest[:])
				testing.expectf(t, rest_err == nil && rest == DEFLATE_TEST_TRAILER, "%v, %v, %v, %v: bytes after the stream were %v, %v", name, format, level, kind, rest, rest_err)
			}
		}
	}
}

@(test)
compress_deflate_round_trip_small :: proc(t: ^testing.T) {
	deflate_test_round_trip(t, "empty", nil)
	deflate_test_round_trip(t, "hellope", transmute([]byte)context_test_data)
}

@(test)
compress_deflate_round_trip_random :: proc(t: ^testing.T) {
	data := stream_test_data()
	defer delete(data)
	deflate_test_round_trip(t, "random", data[:70_000])
}

@(test)
compress_deflate_round_trip_matches :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	deflate_test_round_trip(t, "matches", data)
}

@(test)
compress_deflate_output_too_short :: proc(t: ^testing.T) {
	s := new(deflate.Deflate)
	defer free(s)
	input  := transmute([]byte)context_test_data
	output := make([]byte, deflate.deflate_bound(len(input)) - 1)
	defer delete(output)

	_, err := deflate.deflate_raw(s, output, input)
	testing.expect_value(t, err, compress.Error(compress.General_Error.Output_Too_Short))
}

@(test)
compress_gzip_multiple_members :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	first  := data[:12_345]
	second := data[12_345:100_000]

	packed: [dynamic]byte
	defer delete(packed)
	for part, i in ([][]byte{first, nil, second}) {
		member: [dynamic]byte
		defer delete(member)
		err := deflate.deflate_gzip(&member, part, .Level_1 if i == 0 else .Level_9)
		testing.expectf(t, err == nil, "member %v: deflate_gzip returned %v", i, err)
		append(&packed, ..member[:])
	}
	trailer := DEFLATE_TEST_TRAILER
	append(&packed, ..trailer[:])

	for kind in Stream_Kind {
		input := packed[:]
		br: bytes.Reader
		tr: Trickle_Reader
		output: [dynamic]byte
		defer delete(output)
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		defer compress.destroy_context(&ctx)

		err := deflate.inflate_gzip(&ctx)
		testing.expectf(t, err == nil, "%v: inflate_gzip returned %v", kind, err)
		testing.expectf(t, bytes.equal(output[:], data[:100_000]), "%v: output differs", kind)

		rest: [5]byte
		rest_err := compress.read_slice(&ctx, rest[:])
		testing.expectf(t, rest_err == nil && rest == DEFLATE_TEST_TRAILER, "%v: bytes after the stream were %v, %v", kind, rest, rest_err)
	}
}

@(test)
compress_gzip_bad_trailer :: proc(t: ^testing.T) {
	input := transmute([]byte)context_test_data

	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.deflate_gzip(&packed, input), nil)
	raw := packed[:]

	Corruption :: struct {
		offset: int,
		want:   compress.Error,
	}
	for c in ([]Corruption{
		{len(raw) - 8, compress.GZIP_Error.Payload_CRC_Invalid},
		{len(raw) - 4, compress.GZIP_Error.Payload_Length_Invalid},
		{0,            compress.GZIP_Error.Invalid_GZIP_Signature},
	}) {
		raw[c.offset] ~= 0x55
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, raw)
		testing.expectf(t, err == c.want, "corrupt byte %v: inflate_gzip returned %v, expected %v", c.offset, err, c.want)
		raw[c.offset] ~= 0x55
	}
}

@(test)
compress_gzip_header_crc :: proc(t: ^testing.T) {
	packed := [?]byte{
		0x1f, 0x8b, 0x08, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x07, 0x00, 0x4f, 0x64, 0x03, 0x00,
		0x78, 0x79, 0x7a, 0x6e, 0x61, 0x6d, 0x65, 0x2e, 0x74, 0x78, 0x74, 0x00, 0x48, 0x65, 0x6c, 0x6c,
		0x6f, 0x70, 0x65, 0x21, 0x00, 0x1f, 0x1c, 0xf3, 0x48, 0xcd, 0xc9, 0xc9, 0x2f, 0x48, 0xd5, 0x51,
		0x70, 0xf3, 0x70, 0x0e, 0x72, 0x56, 0x04, 0x00, 0x11, 0x81, 0x1d, 0xe1, 0x0f, 0x00, 0x00, 0x00,
	}
	expected := "Hellope, FHCRC!"

	for kind in Stream_Kind {
		input := packed[:]
		br: bytes.Reader
		tr: Trickle_Reader
		output: [dynamic]byte
		defer delete(output)
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		defer compress.destroy_context(&ctx)

		err := deflate.inflate_gzip(&ctx)
		testing.expectf(t, err == nil, "%v: inflate_gzip returned %v", kind, err)
		testing.expectf(t, string(output[:]) == expected, "%v: output was %q", kind, string(output[:]))
	}

	for offset in ([]int{4, 9, 12, 17, 22, 30, 37, 38}) {
		packed[offset] ~= 0x55
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, packed[:])
		testing.expectf(t, err == compress.GZIP_Error.Header_CRC_Invalid, "corrupt byte %v: inflate_gzip returned %v", offset, err)
		packed[offset] ~= 0x55
	}

	unchecked: [dynamic]byte
	defer delete(unchecked)
	append(&unchecked, ..packed[:37])
	append(&unchecked, ..packed[39:])
	unchecked[3] &~= 0x02
	for offset in ([]int{4, 12, 17, 22, 30}) {
		unchecked[offset] ~= 0x55
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, unchecked[:])
		testing.expectf(t, err == nil, "unchecked, corrupt byte %v: inflate_gzip returned %v", offset, err)
		testing.expectf(t, string(output[:]) == expected, "unchecked, corrupt byte %v: output was %q", offset, string(output[:]))
		unchecked[offset] ~= 0x55
	}
}

@(test)
compress_gzip_header_max_extra :: proc(t: ^testing.T) {
	match_data := stream_match_data()
	defer delete(match_data)
	data := match_data[:10_000]

	body: [dynamic]byte
	defer delete(body)
	testing.expect_value(t, deflate.deflate_raw(&body, data), nil)

	for checked in ([]bool{false, true}) {
		packed: [dynamic]byte
		defer delete(packed)
		flags: u8 = 0x04 | 0x08 | (0x02 if checked else 0)
		append(&packed, 0x1f, 0x8b, 0x08, flags, 0, 0, 0, 0, 0, 0xff)
		append(&packed, 0xff, 0xff, 'O', 'd', 0xfb, 0xff)
		for i in 0..<65531 {
			append(&packed, byte(i * 7))
		}
		append(&packed, ..transmute([]byte)string("big-extra.bin\x00"))
		if checked {
			crc := hash.crc32(packed[:])
			append(&packed, byte(crc), byte(crc >> 8))
		}
		append(&packed, ..body[:])
		crc  := hash.crc32(data)
		size := u32(len(data))
		append(&packed, byte(crc), byte(crc >> 8), byte(crc >> 16), byte(crc >> 24))
		append(&packed, byte(size), byte(size >> 8), byte(size >> 16), byte(size >> 24))

		for kind in Stream_Kind {
			input := packed[:]
			br: bytes.Reader
			tr: Trickle_Reader
			output: [dynamic]byte
			defer delete(output)
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			defer compress.destroy_context(&ctx)

			err := deflate.inflate_gzip(&ctx)
			testing.expectf(t, err == nil, "checked %v, %v: inflate_gzip returned %v", checked, kind, err)
			testing.expectf(t, bytes.equal(output[:], data), "checked %v, %v: output differs", checked, kind)
		}

		packed[40_000] ~= 0x55
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, packed[:])
		want := compress.Error(compress.GZIP_Error.Header_CRC_Invalid) if checked else nil
		testing.expectf(t, err == want, "checked %v, corrupt extra: inflate_gzip returned %v", checked, err)
	}
}

@(test)
compress_deflate_round_trip_mixed :: proc(t: ^testing.T) {
	words := [?]string{"deflate ", "odin ", "huffman ", "window ", "match ", "literal ", "block "}
	data: [dynamic]byte
	defer delete(data)

	for len(data) < 300_000 {
		switch (len(data) / 23_000) % 4 {
		case 0:
			append(&data, words[rand.int_max(len(words))])
		case 1:
			append(&data, u8(rand.uint32()))
		case 2:
			r := rand.uint32()
			append(&data, u8(r), u8(r >> 8), 'x', 'y', 'z', u8(r >> 16))
		case 3:
			append(&data, u8(len(data) / 97))
		}
	}
	deflate_test_round_trip(t, "mixed", data[:])
}
