package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/lz4"
import "core:hash/xxhash"
import "core:log"
import "core:testing"
import "core:time"

LZ4_LIMITS_SIZE :: 1 << 20

@(test)
lz4_expected_size_is_a_limit :: proc(t: ^testing.T) {
	data := make([]byte, LZ4_LIMITS_SIZE)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, lz4.compress_frame(&packed, data, .Level_1, lz4.Frame_Options{flags = {.Independent_Blocks}}), nil)

	for kind in Stream_Kind {
		for expected in ([]int{len(data), 100}) {
			input := packed[:]
			output: [dynamic]byte
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			err := lz4.decompress_frame(&ctx, expected)
			compress.destroy_context(&ctx)

			if expected == len(data) {
				testing.expectf(t, err == nil, "%v: %v", kind, err)
				testing.expectf(t, len(output) == len(data), "%v: %v bytes", kind, len(output))
				testing.expectf(t, cap(output) == len(data), "%v: capacity %v for an exact size", kind, cap(output))
			} else {
				testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v: %v", kind, err)
				testing.expectf(t, cap(output) <= expected, "%v: capacity %v for a limit of %v", kind, cap(output), expected)
			}
		}
	}

	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lz4.decompress_frame(&output, LZ4_VECTOR_LEGACY, 10), compress.Error(compress.General_Error.Output_Too_Short))
	testing.expectf(t, cap(output) <= 10, "legacy: capacity %v", cap(output))
}

@(test)
lz4_max_output_size :: proc(t: ^testing.T) {
	data := make([]byte, LZ4_LIMITS_SIZE)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, lz4.compress_frame(&packed, data, .Level_1, lz4.Frame_Options{flags = {.Independent_Blocks}}), nil)

	for limit in ([]int{64 * 1024, len(data)}) {
		output: [dynamic]byte
		defer delete(output)
		err := lz4.decompress_frame(&output, packed[:], max_output_size = limit)
		if limit == len(data) {
			testing.expectf(t, err == nil, "%v", err)
			testing.expectf(t, len(output) == len(data), "%v bytes", len(output))
		} else {
			testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v", err)
			testing.expectf(t, cap(output) <= limit, "capacity %v for a maximum of %v", cap(output), limit)
		}
	}

	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lz4.decompress_frame(&output, packed[:], 2 * len(data), len(data)), compress.Error(compress.General_Error.Output_Too_Short))
	testing.expect_value(t, cap(output), 0)
}

@(test)
lz4_content_size_is_a_limit :: proc(t: ^testing.T) {
	header := [?]byte{0x04, 0x22, 0x4d, 0x18, 0x68, 0x70, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	size := u64(compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
	for i in 0..<8 {
		header[6 + i] = u8(size >> (8 * uint(i)))
	}
	header[14] = u8(xxhash.XXH32(header[4:14]) >> 8)
	{
		output: [dynamic]byte
		defer delete(output)
		testing.expect_value(t, lz4.decompress_frame(&output, header[:]), compress.Error(compress.LZ4_Error.Content_Size_Mismatch))
		testing.expectf(t, cap(output) <= 255 * len(header), "capacity %v for a %v byte frame", cap(output), len(header))
	}

	data := make([]byte, LZ4_LIMITS_SIZE)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, lz4.compress_frame(&packed, data, .Level_1, lz4.Frame_Options{flags = {.Independent_Blocks, .Content_Size}}), nil)
	for i in 0..<8 {
		packed[6 + i] = 0
	}
	packed[6] = 100
	packed[14] = u8(xxhash.XXH32(packed[4:14]) >> 8)
	{
		output: [dynamic]byte
		defer delete(output)
		testing.expect_value(t, lz4.decompress_frame(&output, packed[:]), compress.Error(compress.LZ4_Error.Content_Size_Mismatch))
		testing.expectf(t, cap(output) <= 100, "capacity %v for a content size of 100", cap(output))
	}
}

@(test)
lz4_block_allocation_bound :: proc(t: ^testing.T) {
	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lz4.decompress_block(&output, []byte{0x10, 'x'}, compress.COMPRESS_OUTPUT_ALLOCATE_MAX), nil)
	testing.expect_value(t, len(output), 1)
	testing.expectf(t, cap(output) <= 255 * 2, "capacity %v for a 2 byte block", cap(output))
}

@(test)
lz4_growth_overshoot :: proc(t: ^testing.T) {
	data := make([]byte, 40 << 20)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, lz4.compress_frame(&packed, data, .Level_1, lz4.Frame_Options{flags = {.Independent_Blocks}}), nil)

	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lz4.decompress_frame(&output, packed[:]), nil)
	testing.expect_value(t, len(output), len(data))
	testing.expectf(t, cap(output) - len(output) <= 16 << 20, "capacity %v for %v bytes", cap(output), len(output))
}

@(test)
lz4_floods :: proc(t: ^testing.T) {
	FLOOD_SIZE :: 256 * 1024
	Flood :: enum {
		Frames,
		Skippable_Frames,
		Blocks,
	}
	for flood in Flood {
		packed: [dynamic]byte
		defer delete(packed)
		want := 0
		switch flood {
		case .Frames:
			for len(packed) < FLOOD_SIZE {
				lz4_test_frame_header(&packed)
				append(&packed, 2, 0, 0, 0, 0x10, 'x', 0, 0, 0, 0)
				want += 1
			}
		case .Skippable_Frames:
			lz4_test_frame_header(&packed)
			append(&packed, 0, 0, 0, 0)
			for len(packed) < FLOOD_SIZE {
				append(&packed, 0x50, 0x2a, 0x4d, 0x18, 0, 0, 0, 0)
			}
		case .Blocks:
			lz4_test_frame_header(&packed)
			for len(packed) < FLOOD_SIZE {
				append(&packed, 1, 0, 0, 0, 0x00)
			}
			append(&packed, 0, 0, 0, 0)
		}

		output: [dynamic]byte
		defer delete(output)
		start   := time.tick_now()
		err     := lz4.decompress_frame(&output, packed[:])
		elapsed := time.tick_since(start)
		testing.expectf(t, err == nil, "%v: %v", flood, err)
		testing.expectf(t, len(output) == want, "%v: %v bytes", flood, len(output))
		testing.expectf(t, cap(output) <= 8 << 20, "%v: capacity %v", flood, cap(output))
		log.infof("%v flood: %v bytes in %v", flood, len(packed), elapsed)
	}
}

lz4_test_frame_header :: proc(out: ^[dynamic]byte) {
	append(out, 0x04, 0x22, 0x4d, 0x18, 0x60, 0x70)
	append(out, u8(xxhash.XXH32(out[len(out) - 2:]) >> 8))
}
