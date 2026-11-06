package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:log"
import "core:testing"
import "core:time"

INFLATE_TEST_SIZE :: 1 << 20

@(test)
inflate_expected_size_is_a_limit :: proc(t: ^testing.T) {
	data := make([]byte, INFLATE_TEST_SIZE)
	defer delete(data)

	for format in Deflate_Format {
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate_test_pack(format, data, &packed, .Level_6), nil)

		for kind in Stream_Kind {
			for expected in ([]int{len(data), 100}) {
				input := packed[:]
				output: [dynamic]byte
				defer delete(output)
				br: bytes.Reader
				tr: Trickle_Reader
				ctx := stream_test_context(kind, &input, &br, &tr, &output)
				err := inflate_test_unpack(format, &ctx, expected)
				compress.destroy_context(&ctx)

				if expected == len(data) {
					testing.expectf(t, err == nil, "%v %v: %v", format, kind, err)
					testing.expectf(t, len(output) == len(data), "%v %v: %v bytes", format, kind, len(output))
					if kind == .Memory {
						testing.expectf(t, cap(output) == len(data), "%v %v: capacity %v for an exact size", format, kind, cap(output))
					}
				} else {
					testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v %v: %v", format, kind, err)
					testing.expectf(t, cap(output) <= expected, "%v %v: capacity %v for a limit of %v", format, kind, cap(output), expected)
				}
			}
		}
	}
}

@(test)
inflate_max_output_size :: proc(t: ^testing.T) {
	data := make([]byte, INFLATE_TEST_SIZE)
	defer delete(data)

	for format in Deflate_Format {
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate_test_pack(format, data, &packed, .Level_6), nil)

		for limit in ([]int{64 * 1024, len(data)}) {
			output: [dynamic]byte
			defer delete(output)
			err := inflate_test_unpack_bytes(format, &output, packed[:], -1, limit)
			if limit == len(data) {
				testing.expectf(t, err == nil, "%v: %v", format, err)
				testing.expectf(t, len(output) == len(data), "%v: %v bytes", format, len(output))
			} else {
				testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v: %v", format, err)
				testing.expectf(t, cap(output) <= limit, "%v: capacity %v for a maximum of %v", format, cap(output), limit)
			}
		}

		{
			output: [dynamic]byte
			defer delete(output)
			err := inflate_test_unpack_bytes(format, &output, packed[:], 2 * len(data), len(data))
			if format == .GZIP {
				testing.expectf(t, err == compress.General_Error.Output_Exceeds_COMPRESS_OUTPUT_ALLOCATE_MAX, "%v: %v", format, err)
			} else {
				testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v: %v", format, err)
			}
			testing.expectf(t, cap(output) == 0, "%v: capacity %v", format, cap(output))
		}
	}
}

@(test)
inflate_gzip_size_hint :: proc(t: ^testing.T) {
	data := make([]byte, INFLATE_TEST_SIZE)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.deflate_gzip(&packed, data), nil)

	{
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, packed[:])
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(output), len(data))
		testing.expect_value(t, cap(output), len(data))
	}

	size := len(packed) - 4
	packed[size], packed[size + 1], packed[size + 2], packed[size + 3] = 100, 0, 0, 0
	{
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, packed[:])
		testing.expect_value(t, err, compress.GZIP_Error.Payload_Length_Invalid)
	}
	{
		output: [dynamic]byte
		defer delete(output)
		err := deflate.inflate_gzip(&output, packed[:], max_output_size = 64 * 1024)
		testing.expect_value(t, err, compress.General_Error.Output_Too_Short)
		testing.expectf(t, cap(output) <= 64 * 1024, "capacity %v", cap(output))
	}
}

@(test)
inflate_growth_overshoot :: proc(t: ^testing.T) {
	data := make([]byte, 40 << 20)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.deflate_raw(&packed, data, .Level_1), nil)

	output: [dynamic]byte
	defer delete(output)
	err := deflate.inflate_raw(&output, packed[:])
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(output), len(data))
	testing.expectf(t, cap(output) - len(output) <= 16 << 20, "capacity %v for %v bytes", cap(output), len(output))
}

@(test)
inflate_stored_block_limit :: proc(t: ^testing.T) {
	data := make([]byte, 1000)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.deflate_raw(&packed, data, .Stored), nil)

	for kind in Stream_Kind {
		input := packed[:]
		output: [dynamic]byte
		defer delete(output)
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		err := deflate.inflate_raw(&ctx, 10)
		compress.destroy_context(&ctx)
		testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v: %v", kind, err)
		testing.expectf(t, cap(output) <= 10, "%v: capacity %v", kind, cap(output))
	}
}

@(test)
inflate_empty_block_floods :: proc(t: ^testing.T) {
	when ODIN_ARCH == .riscv64 {
		log.infof("Skipped on riscv64")
		return
	}
	FLOOD_SIZE :: 256 * 1024
	Flood :: enum {
		Stored,
		Fixed,
		Dynamic,
	}
	for flood in Flood {
		packed: [dynamic]byte
		defer delete(packed)
		w := Fixed_Writer{out = &packed}
		for len(packed) < FLOOD_SIZE {
			inflate_test_empty_block(&w, flood == .Stored, flood == .Dynamic, false)
		}
		inflate_test_empty_block(&w, flood == .Stored, flood == .Dynamic, true)
		if w.count > 0 {
			append(&packed, u8(w.bits))
		}

		output: [dynamic]byte
		defer delete(output)
		start   := time.tick_now()
		err     := deflate.inflate_raw(&output, packed[:])
		elapsed := time.tick_since(start)
		testing.expectf(t, err == nil, "%v: %v", flood, err)
		testing.expectf(t, len(output) == 0, "%v: %v bytes", flood, len(output))
		log.infof("%v empty blocks: %v bytes in %v", flood, len(packed), elapsed)
	}
}

inflate_test_unpack :: proc(format: Deflate_Format, ctx: ^compress.Context, expected: int) -> compress.Error {
	switch format {
	case .Raw:  return deflate.inflate_raw(ctx, expected)
	case .ZLIB: return deflate.inflate_zlib(ctx, expected)
	case .GZIP: return deflate.inflate_gzip(ctx, expected)
	}
	return nil
}

inflate_test_unpack_bytes :: proc(format: Deflate_Format, output: ^[dynamic]byte, input: []byte, expected, limit: int) -> compress.Error {
	switch format {
	case .Raw:  return deflate.inflate_raw(output, input, expected, limit)
	case .ZLIB: return deflate.inflate_zlib(output, input, expected, limit)
	case .GZIP: return deflate.inflate_gzip(output, input, expected, limit)
	}
	return nil
}

inflate_test_empty_block :: proc(w: ^Fixed_Writer, stored, huffman, last: bool) {
	fixed_put(w, 1 if last else 0, 1)
	switch {
	case stored:
		fixed_put(w, 0, 2)
		if w.count > 0 {
			fixed_put(w, 0, 8 - w.count)
		}
		fixed_put(w, 0, 16)
		fixed_put(w, 0xffff, 16)
	case huffman:
		fixed_put(w, 2, 2)
		fixed_put(w, 0, 5)
		fixed_put(w, 0, 5)
		fixed_put(w, 18 - 4, 4)
		precode_order := [19]int{16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}
		precode: [19]u32
		precode[18] = 1
		precode[1]  = 2
		precode[0]  = 2
		for i in 0..<18 {
			fixed_put(w, precode[precode_order[i]], 3)
		}
		fixed_put_code(w, 0, 1)
		fixed_put(w, 138 - 11, 7)
		fixed_put_code(w, 0, 1)
		fixed_put(w, 118 - 11, 7)
		fixed_put_code(w, 0b11, 2)
		fixed_put_code(w, 0b10, 2)
		fixed_put_code(w, 0, 1)
	case:
		fixed_put(w, 1, 2)
		fixed_put_code(w, 0, 7)
	}
}
