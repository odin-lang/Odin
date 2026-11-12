package test_core_compress

import "base:runtime"
import "core:compress"
import "core:compress/xz"
import "core:hash"
import "core:os"
import "core:strings"
import "core:testing"

TEST_SUITE_PATH_XZ :: ODIN_ROOT + "tests/core/assets/XZ/"

Xz_Verdict :: enum u8 {
	Good,
	Bad,
	Unsupported,
	Unverified,
}

Xz_Case :: struct {
	name:    string,
	verdict: Xz_Verdict,
	size:    int,
	crc:     u32,
}

XZ_CASES :: [?]Xz_Case{
	{"7z.arm.bcj.xz",                             .Good,         131072, 0x2819a7f6},
	{"7z.arm64.bcj.xz",                           .Good,         131072, 0x793f446d},
	{"7z.armthumb.bcj.xz",                        .Good,         131072, 0x98184d55},
	{"7z.binary.riscv.xz",                        .Good,         100000, 0xdab9f4c0},
	{"7z.empty.xz",                               .Good,         0, 0x00000000},
	{"7z.pcm16.delta-4.xz",                       .Good,         65536, 0xe13dbf6a},
	{"7z.random.xz",                              .Good,         100000, 0xd4029d57},
	{"7z.riscv.bcj.xz",                           .Good,         131072, 0xd7fc9bf8},
	{"7z.text.blocks.xz",                         .Good,         80000, 0x61c54dab},
	{"7z.text.mx9.xz",                            .Good,         80000, 0x61c54dab},
	{"7z.text.xz",                                .Good,         80000, 0x61c54dab},
	{"7z.x86.bcj.xz",                             .Good,         131072, 0xccb58444},
	{"arm.bcj.xz",                                .Good,         131072, 0x2819a7f6},
	{"arm64.bcj-start.xz",                        .Good,         131072, 0x793f446d},
	{"arm64.bcj.xz",                              .Good,         131072, 0x793f446d},
	{"arm64.lc0-lp2-pb0.xz",                      .Good,         131072, 0x793f446d},
	{"armthumb.bcj.xz",                           .Good,         131072, 0x98184d55},
	{"binary.bcj-arm.xz",                         .Good,         100000, 0xdab9f4c0},
	{"binary.bcj-armthumb.xz",                    .Good,         100000, 0xdab9f4c0},
	{"binary.bcj-ia64.xz",                        .Good,         100000, 0xdab9f4c0},
	{"binary.bcj-powerpc.xz",                     .Good,         100000, 0xdab9f4c0},
	{"binary.bcj-riscv.xz",                       .Good,         100000, 0xdab9f4c0},
	{"binary.bcj-sparc.xz",                       .Good,         100000, 0xdab9f4c0},
	{"concat-padding.xz",                         .Good,         80250, 0xd7e3a992},
	{"concat.xz",                                 .Good,         80250, 0xd7e3a992},
	{"empty.xz",                                  .Good,         0, 0x00000000},
	{"one.xz",                                    .Good,         1, 0xd3d99e8b},
	{"pcm16.delta-2.xz",                          .Good,         65536, 0xe13dbf6a},
	{"pcm16.delta-4.xz",                          .Good,         65536, 0xe13dbf6a},
	{"random.xz",                                 .Good,         100000, 0xd4029d57},
	{"rgba.delta-256.xz",                         .Good,         65536, 0x70411c37},
	{"rgba.delta-4.xz",                           .Good,         65536, 0x70411c37},
	{"riscv.bcj-start.xz",                        .Good,         131072, 0xd7fc9bf8},
	{"riscv.bcj.xz",                              .Good,         131072, 0xd7fc9bf8},
	{"same.xz",                                   .Good,         32768, 0x6733dede},
	{"text.block-list.xz",                        .Good,         80000, 0x61c54dab},
	{"text.blocks-16k.xz",                        .Good,         80000, 0x61c54dab},
	{"text.check-crc32.xz",                       .Good,         80000, 0x61c54dab},
	{"text.check-crc64.xz",                       .Good,         80000, 0x61c54dab},
	{"text.check-none.xz",                        .Good,         80000, 0x61c54dab},
	{"text.check-sha256.xz",                      .Good,         80000, 0x61c54dab},
	{"text.delta-1.xz",                           .Good,         80000, 0x61c54dab},
	{"text.dict-1536m.xz",                        .Good,         80000, 0x61c54dab},
	{"text.dict-4k.xz",                           .Good,         80000, 0x61c54dab},
	{"text.dict-max.xz",                          .Good,         80000, 0x61c54dab},
	{"text.fast-hc4.xz",                          .Good,         80000, 0x61c54dab},
	{"text.lc4-lp0-pb0.xz",                       .Good,         80000, 0x61c54dab},
	{"text.pb4.xz",                               .Good,         80000, 0x61c54dab},
	{"text.preset-0.xz",                          .Good,         80000, 0x61c54dab},
	{"text.preset-1.xz",                          .Good,         80000, 0x61c54dab},
	{"text.preset-9.xz",                          .Good,         80000, 0x61c54dab},
	{"text.preset-9e.xz",                         .Good,         80000, 0x61c54dab},
	{"text.threads.xz",                           .Good,         80000, 0x61c54dab},
	{"x86.bcj-start.xz",                          .Good,         131072, 0xccb58444},
	{"x86.bcj.xz",                                .Good,         131072, 0xccb58444},
	{"x86.block-filters.xz",                      .Good,         131072, 0xccb58444},
	{"x86.chain-4.xz",                            .Good,         131072, 0xccb58444},
	{"xz-utils/bad-0-backward_size.xz",           .Bad,          0, 0x00000000},
	{"xz-utils/bad-0-empty-truncated.xz",         .Bad,          0, 0x00000000},
	{"xz-utils/bad-0-footer_magic.xz",            .Bad,          0, 0x00000000},
	{"xz-utils/bad-0-header_magic.xz",            .Bad,          0, 0x00000000},
	{"xz-utils/bad-0-nonempty_index.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-0cat-alone.xz",                .Bad,          0, 0x00000000},
	{"xz-utils/bad-0cat-header_magic.xz",         .Bad,          0, 0x00000000},
	{"xz-utils/bad-0catpad-empty.xz",             .Bad,          0, 0x00000000},
	{"xz-utils/bad-0pad-empty.xz",                .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-block_header-1.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-block_header-2.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-block_header-3.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-block_header-4.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-block_header-5.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-block_header-6.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-check-crc32-2.xz",           .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-check-crc32.xz",             .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-check-crc64.xz",             .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-check-sha256.xz",            .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-1.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-10.xz",                .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-11.xz",                .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-2.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-3.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-4.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-5.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-6.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-7.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-8.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-lzma2-9.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-stream_flags-2.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-stream_flags-3.xz",          .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-vli-1.xz",                   .Bad,          0, 0x00000000},
	{"xz-utils/bad-1-vli-2.xz",                   .Bad,          0, 0x00000000},
	{"xz-utils/bad-2-compressed_data_padding.xz", .Bad,          0, 0x00000000},
	{"xz-utils/bad-2-index-1.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-2-index-2.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-2-index-3.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-2-index-4.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-2-index-5.xz",                 .Bad,          0, 0x00000000},
	{"xz-utils/bad-3-index-uncomp-overflow.xz",   .Bad,          0, 0x00000000},
	{"xz-utils/good-0-empty.xz",                  .Good,         0, 0x00000000},
	{"xz-utils/good-0cat-empty.xz",               .Good,         0, 0x00000000},
	{"xz-utils/good-0catpad-empty.xz",            .Good,         0, 0x00000000},
	{"xz-utils/good-0pad-empty.xz",               .Good,         0, 0x00000000},
	{"xz-utils/good-1-3delta-lzma2.xz",           .Good,         457, 0xdb4847fb},
	{"xz-utils/good-1-arm64-lzma2-1.xz",          .Good,         8576, 0xd4e17ca0},
	{"xz-utils/good-1-arm64-lzma2-2.xz",          .Good,         8576, 0xd4e17ca0},
	{"xz-utils/good-1-block_header-1.xz",         .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-block_header-2.xz",         .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-block_header-3.xz",         .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-check-crc32.xz",            .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-check-crc64.xz",            .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-check-none.xz",             .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-check-sha256.xz",           .Good,         13, 0x15a2a343},
	{"xz-utils/good-1-delta-lzma2.tiff.xz",       .Good,         929138, 0xf7c66eb5},
	{"xz-utils/good-1-empty-bcj-lzma2.xz",        .Good,         0, 0x00000000},
	{"xz-utils/good-1-lzma2-1.xz",                .Good,         457, 0xdb4847fb},
	{"xz-utils/good-1-lzma2-2.xz",                .Good,         457, 0xdb4847fb},
	{"xz-utils/good-1-lzma2-3.xz",                .Good,         457, 0xdb4847fb},
	{"xz-utils/good-1-lzma2-4.xz",                .Good,         457, 0xdb4847fb},
	{"xz-utils/good-1-lzma2-5.xz",                .Good,         0, 0x00000000},
	{"xz-utils/good-2-lzma2.xz",                  .Good,         13, 0x15a2a343},
	{"xz-utils/unsupported-block_header.xz",      .Unsupported,  0, 0x00000000},
	{"xz-utils/unsupported-check.xz",             .Unverified,   13, 0x15a2a343},
	{"xz-utils/unsupported-filter_flags-1.xz",    .Unsupported,  0, 0x00000000},
	{"xz-utils/unsupported-filter_flags-2.xz",    .Unsupported,  0, 0x00000000},
	{"xz-utils/unsupported-filter_flags-3.xz",    .Unsupported,  0, 0x00000000},
}

@(test)
test_xz_corpus :: proc(t: ^testing.T) {
	for c in XZ_CASES {
		data, read_err := os.read_entire_file(xz_asset(c.name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", c.name, read_err) {
			continue
		}
		defer delete(data)
		xz_check_case(t, c, data, -1)
		if c.verdict == .Good || c.verdict == .Unverified {
			xz_check_case(t, c, data, c.size)
		}

		f, open_err := os.open(xz_asset(c.name))
		if !testing.expectf(t, open_err == nil, "%s: %v", c.name, open_err) {
			continue
		}
		out: [dynamic]u8
		ctx := compress.init_context_from_stream(os.to_stream(f), &out)
		err := xz.decompress_from_context(&ctx)
		compress.destroy_context(&ctx)
		os.close(f)
		xz_expect(t, c, out[:], err, "stream")
		delete(out)
	}
}

@(test)
test_xz_limits :: proc(t: ^testing.T) {
	data, read_err := os.read_entire_file(xz_asset("text.check-crc64.xz"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(data)
	out: [dynamic]u8
	defer delete(out)

	testing.expect_value(t, xz.decompress(&out, data, {}, -1, 80_000), nil)
	testing.expect_value(t, len(out), 80_000)
	testing.expect_value(t, xz.decompress(&out, data, {}, -1, 79_999), compress.Error(compress.General_Error.Output_Too_Short))
	testing.expect_value(t, xz.decompress(&out, data, {}, 80_001), compress.Error(compress.XZ_Error.Size_Mismatch))
	testing.expect_value(t, xz.decompress(&out, data, {}, 79_999), compress.Error(compress.XZ_Error.Size_Mismatch))

	threads, threads_err := os.read_entire_file(xz_asset("text.threads.xz"), context.allocator)
	if testing.expect_value(t, threads_err, nil) {
		testing.expect_value(t, xz.decompress(&out, threads, {}, -1, 40_000), compress.Error(compress.General_Error.Output_Too_Short))
		delete(threads)
	}

	check_at := xz_check_offset(data)
	if !testing.expect(t, check_at > 0, "no check found") {
		return
	}
	data[check_at] ~= 0x01
	testing.expect_value(t, xz.decompress(&out, data, {}), compress.Error(compress.XZ_Error.Block_Checksum_Failed))
	testing.expect_value(t, xz.decompress(&out, data, {.Ignore_Check}), nil)
	testing.expect_value(t, hash.crc32(out[:]), 0x61c54dab)
	data[check_at] ~= 0x01
}

@(test)
test_xz_truncated :: proc(t: ^testing.T) {
	for name in ([?]string{"one.xz", "text.check-sha256.xz", "x86.chain-4.xz"}) {
		data, read_err := os.read_entire_file(xz_asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		defer delete(data)
		out: [dynamic]u8
		defer delete(out)
		step := 1 if len(data) < 4096 else 61
		for n := 0; n < len(data); n += step {
			err := xz.decompress(&out, data[:n])
			testing.expectf(t, err != nil, "%s cut at %d: decoded", name, n)
		}
	}
}

@(test)
test_xz_validates_before_allocating :: proc(t: ^testing.T) {
	names := [?]string{
		"xz-utils/bad-1-block_header-1.xz",
		"xz-utils/bad-1-block_header-2.xz",
		"xz-utils/bad-1-block_header-3.xz",
		"xz-utils/bad-1-stream_flags-2.xz",
		"xz-utils/bad-1-vli-1.xz",
		"xz-utils/bad-1-vli-2.xz",
		"xz-utils/unsupported-block_header.xz",
		"xz-utils/unsupported-filter_flags-1.xz",
		"xz-utils/unsupported-filter_flags-2.xz",
		"xz-utils/unsupported-filter_flags-3.xz",
	}
	for name in names {
		data, read_err := os.read_entire_file(xz_asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		defer delete(data)
		out := make([dynamic]u8, runtime.nil_allocator())
		err := xz.decompress(&out, data, {}, -1, compress.COMPRESS_OUTPUT_ALLOCATE_MAX, runtime.nil_allocator())
		_, allocation_failed := err.(runtime.Allocator_Error)
		testing.expectf(t, err != nil && !allocation_failed, "%s: %v", name, err)
	}
}

xz_check_case :: proc(t: ^testing.T, c: Xz_Case, data: []u8, expected: int) {
	out: [dynamic]u8
	defer delete(out)
	err := xz.decompress(&out, data, {}, expected)
	xz_expect(t, c, out[:], err, "bytes" if expected < 0 else "known size")
}

xz_expect :: proc(t: ^testing.T, c: Xz_Case, out: []u8, err: compress.Error, label: string, loc := #caller_location) {
	switch c.verdict {
	case .Good, .Unverified:
		if testing.expectf(t, err == nil, "%s (%s): %v", c.name, label, err, loc = loc) {
			testing.expectf(t, len(out) == c.size && hash.crc32(out) == c.crc, "%s (%s): %d bytes, CRC %08x", c.name, label, len(out), hash.crc32(out), loc = loc)
		}
	case .Bad, .Unsupported:
		testing.expectf(t, err != nil, "%s (%s): decoded %d bytes", c.name, label, len(out), loc = loc)
	}
}

xz_check_offset :: proc(data: []u8) -> int {
	footer := data[len(data) - 12:]
	index  := (int(footer[4]) | int(footer[5]) << 8 | int(footer[6]) << 16 | int(footer[7]) << 24 + 1) * 4
	return len(data) - 12 - index - 8
}

xz_asset :: proc(name: string) -> string {
	return strings.concatenate({TEST_SUITE_PATH_XZ, name}, context.temp_allocator)
}

@(test)
test_xz_concatenation :: proc(t: ^testing.T) {
	empty, read_err := os.read_entire_file(xz_asset("empty.xz"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(empty)
	one, one_err := os.read_entire_file(xz_asset("one.xz"), context.allocator)
	if !testing.expect_value(t, one_err, nil) {
		return
	}
	defer delete(one)

	Case :: struct {
		parts: []string,
		pad:   int,
		tail:  []u8,
		err:   compress.Error,
		size:  int,
	}
	cases := [?]Case{
		{{"one", "one"}, 0, nil, nil, 2},
		{{"one", "empty", "one"}, 8, nil, nil, 2},
		{{"one"}, 1024, nil, nil, 1},
		{{"one"}, 3, nil, compress.XZ_Error.Invalid_Padding, -1},
		{{"one", "one"}, 5, nil, compress.XZ_Error.Invalid_Padding, -1},
		{{"one"}, 4, {0x01}, compress.XZ_Error.Data_After_End, -1},
		{{"one"}, 0, {0x5D, 0x00, 0x00, 0x80, 0x00}, compress.XZ_Error.Data_After_End, -1},
		{{"one"}, 4, {0xFD, '7', 'z'}, compress.General_Error.Stream_Too_Short, -1},
	}
	for c, i in cases {
		input: [dynamic]u8
		defer delete(input)
		for part in c.parts {
			append(&input, ..(one if part == "one" else empty))
			for _ in 0..<c.pad {
				append(&input, 0)
			}
		}
		append(&input, ..c.tail)
		out: [dynamic]u8
		err := xz.decompress(&out, input[:])
		testing.expectf(t, err == c.err, "case %d: %v, want %v", i, err, c.err)
		if c.size >= 0 {
			testing.expectf(t, len(out) == c.size, "case %d: %d bytes", i, len(out))
		}
		delete(out)
	}

	many: [dynamic]u8
	defer delete(many)
	for _ in 0..<10_000 {
		append(&many, ..empty)
	}
	for _ in 0..<(1 << 20) {
		append(&many, 0)
	}
	append(&many, ..one)
	out: [dynamic]u8
	defer delete(out)
	testing.expect_value(t, xz.decompress(&out, many[:]), nil)
	testing.expect_value(t, len(out), 1)
}
