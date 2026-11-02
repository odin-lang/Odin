package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
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
