package test_core_compress

import "base:runtime"
import "core:bytes"
import "core:compress"
import "core:compress/xz"
import "core:encoding/endian"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:math/rand"
import "core:os"
import "core:testing"

Xz_Index_Stream_Row :: struct {
	name:                string,
	stream:              int,
	blocks:              int,
	offset:              i64,
	uncompressed_offset: i64,
	size:                i64,
	uncompressed_size:   i64,
	check:               u8,
	padding:             i64,
}

Xz_Index_Block_Row :: struct {
	name:                string,
	stream:              int,
	block:               int,
	offset:              i64,
	uncompressed_offset: i64,
	total:               i64,
	uncompressed_size:   i64,
}

Xz_Index_Hostile :: struct {
	label:     string,
	craft:     Xz_Craft,
	prefix:    int,
	index_err: compress.Error,
	any_error: bool,
	block_err: compress.Error,
}

XZ_INDEX_MULTI :: [?]string{
	"7z.text.blocks.xz",
	"concat-padding.xz",
	"concat.xz",
	"text.block-list.xz",
	"text.blocks-16k.xz",
	"text.threads.xz",
	"x86.block-filters.xz",
}

XZ_INDEX_STREAMS :: [?]Xz_Index_Stream_Row{
	{"7z.arm.bcj.xz",                       1, 1, 0, 0, 39920, 131072, 1, 0},
	{"7z.arm64.bcj.xz",                     1, 1, 0, 0, 32620, 131072, 1, 0},
	{"7z.armthumb.bcj.xz",                  1, 1, 0, 0, 62932, 131072, 1, 0},
	{"7z.binary.riscv.xz",                  1, 1, 0, 0, 11464, 100000, 1, 0},
	{"7z.empty.xz",                         1, 1, 0, 0, 52, 0, 1, 0},
	{"7z.pcm16.delta-4.xz",                 1, 1, 0, 0, 49536, 65536, 1, 0},
	{"7z.random.xz",                        1, 1, 0, 0, 100064, 100000, 1, 0},
	{"7z.riscv.bcj.xz",                     1, 1, 0, 0, 57508, 131072, 1, 0},
	{"7z.text.blocks.xz",                   1, 5, 0, 0, 22896, 80000, 1, 0},
	{"7z.text.mx9.xz",                      1, 1, 0, 0, 19496, 80000, 1, 0},
	{"7z.text.xz",                          1, 1, 0, 0, 19484, 80000, 1, 0},
	{"7z.x86.bcj.xz",                       1, 1, 0, 0, 14376, 131072, 1, 0},
	{"arm.bcj.xz",                          1, 1, 0, 0, 39960, 131072, 4, 0},
	{"arm64.bcj-start.xz",                  1, 1, 0, 0, 32576, 131072, 4, 0},
	{"arm64.bcj.xz",                        1, 1, 0, 0, 32568, 131072, 4, 0},
	{"arm64.lc0-lp2-pb0.xz",                1, 1, 0, 0, 35264, 131072, 4, 0},
	{"armthumb.bcj.xz",                     1, 1, 0, 0, 63000, 131072, 4, 0},
	{"binary.bcj-arm.xz",                   1, 1, 0, 0, 11680, 100000, 4, 0},
	{"binary.bcj-armthumb.xz",              1, 1, 0, 0, 11640, 100000, 4, 0},
	{"binary.bcj-ia64.xz",                  1, 1, 0, 0, 11640, 100000, 4, 0},
	{"binary.bcj-powerpc.xz",               1, 1, 0, 0, 15148, 100000, 4, 0},
	{"binary.bcj-riscv.xz",                 1, 1, 0, 0, 11640, 100000, 4, 0},
	{"binary.bcj-sparc.xz",                 1, 1, 0, 0, 12124, 100000, 4, 0},
	{"concat-padding.xz",                   1, 1, 0, 0, 19536, 80000, 4, 8},
	{"concat-padding.xz",                   2, 0, 19544, 80000, 32, 0, 4, 0},
	{"concat-padding.xz",                   3, 1, 19576, 80000, 292, 250, 10, 4},
	{"concat.xz",                           1, 1, 0, 0, 19536, 80000, 4, 0},
	{"concat.xz",                           2, 1, 19536, 80000, 292, 250, 10, 0},
	{"empty.xz",                            1, 0, 0, 0, 32, 0, 4, 0},
	{"one.xz",                              1, 1, 0, 0, 68, 1, 4, 0},
	{"pcm16.delta-2.xz",                    1, 1, 0, 0, 64136, 65536, 4, 0},
	{"pcm16.delta-4.xz",                    1, 1, 0, 0, 49276, 65536, 4, 0},
	{"random.xz",                           1, 1, 0, 0, 100072, 100000, 4, 0},
	{"rgba.delta-256.xz",                   1, 1, 0, 0, 488, 65536, 4, 0},
	{"rgba.delta-4.xz",                     1, 1, 0, 0, 232, 65536, 4, 0},
	{"riscv.bcj-start.xz",                  1, 1, 0, 0, 57516, 131072, 4, 0},
	{"riscv.bcj.xz",                        1, 1, 0, 0, 57496, 131072, 4, 0},
	{"same.xz",                             1, 1, 0, 0, 140, 32768, 4, 0},
	{"text.block-list.xz",                  1, 3, 0, 0, 20700, 80000, 4, 0},
	{"text.blocks-16k.xz",                  1, 5, 0, 0, 22996, 80000, 4, 0},
	{"text.check-crc32.xz",                 1, 1, 0, 0, 19532, 80000, 1, 0},
	{"text.check-crc64.xz",                 1, 1, 0, 0, 19536, 80000, 4, 0},
	{"text.check-none.xz",                  1, 1, 0, 0, 19528, 80000, 0, 0},
	{"text.check-sha256.xz",                1, 1, 0, 0, 19560, 80000, 10, 0},
	{"text.delta-1.xz",                     1, 1, 0, 0, 22376, 80000, 4, 0},
	{"text.dict-1536m.xz",                  1, 1, 0, 0, 19536, 80000, 4, 0},
	{"text.dict-4k.xz",                     1, 1, 0, 0, 21624, 80000, 4, 0},
	{"text.dict-max.xz",                    1, 1, 0, 0, 19536, 80000, 4, 0},
	{"text.fast-hc4.xz",                    1, 1, 0, 0, 21812, 80000, 4, 0},
	{"text.lc4-lp0-pb0.xz",                 1, 1, 0, 0, 19492, 80000, 4, 0},
	{"text.pb4.xz",                         1, 1, 0, 0, 19640, 80000, 4, 0},
	{"text.preset-0.xz",                    1, 1, 0, 0, 23324, 80000, 4, 0},
	{"text.preset-1.xz",                    1, 1, 0, 0, 22120, 80000, 4, 0},
	{"text.preset-9.xz",                    1, 1, 0, 0, 19536, 80000, 4, 0},
	{"text.preset-9e.xz",                   1, 1, 0, 0, 19584, 80000, 4, 0},
	{"text.threads.xz",                     1, 5, 0, 0, 22996, 80000, 4, 0},
	{"x86.bcj-start.xz",                    1, 1, 0, 0, 14436, 131072, 4, 0},
	{"x86.bcj.xz",                          1, 1, 0, 0, 14432, 131072, 4, 0},
	{"x86.block-filters.xz",                1, 4, 0, 0, 19220, 131072, 4, 0},
	{"x86.chain-4.xz",                      1, 1, 0, 0, 28796, 131072, 4, 0},
	{"xz-utils/good-0-empty.xz",            1, 0, 0, 0, 32, 0, 1, 0},
	{"xz-utils/good-0cat-empty.xz",         1, 0, 0, 0, 32, 0, 1, 0},
	{"xz-utils/good-0cat-empty.xz",         2, 0, 32, 0, 32, 0, 1, 0},
	{"xz-utils/good-0catpad-empty.xz",      1, 0, 0, 0, 32, 0, 1, 4},
	{"xz-utils/good-0catpad-empty.xz",      2, 0, 36, 0, 32, 0, 1, 0},
	{"xz-utils/good-0pad-empty.xz",         1, 0, 0, 0, 32, 0, 1, 4},
	{"xz-utils/good-1-3delta-lzma2.xz",     1, 1, 0, 0, 528, 457, 4, 0},
	{"xz-utils/good-1-arm64-lzma2-1.xz",    1, 1, 0, 0, 512, 8576, 1, 0},
	{"xz-utils/good-1-arm64-lzma2-2.xz",    1, 1, 0, 0, 488, 8576, 1, 0},
	{"xz-utils/good-1-block_header-1.xz",   1, 1, 0, 0, 72, 13, 1, 0},
	{"xz-utils/good-1-block_header-2.xz",   1, 1, 0, 0, 68, 13, 1, 0},
	{"xz-utils/good-1-block_header-3.xz",   1, 1, 0, 0, 68, 13, 1, 0},
	{"xz-utils/good-1-check-crc32.xz",      1, 1, 0, 0, 68, 13, 1, 0},
	{"xz-utils/good-1-check-crc64.xz",      1, 1, 0, 0, 72, 13, 4, 0},
	{"xz-utils/good-1-check-none.xz",       1, 1, 0, 0, 64, 13, 0, 0},
	{"xz-utils/good-1-check-sha256.xz",     1, 1, 0, 0, 96, 13, 10, 0},
	{"xz-utils/good-1-delta-lzma2.tiff.xz", 1, 1, 0, 0, 51316, 929138, 1, 0},
	{"xz-utils/good-1-empty-bcj-lzma2.xz",  1, 1, 0, 0, 52, 0, 1, 0},
	{"xz-utils/good-1-lzma2-1.xz",          1, 1, 0, 0, 424, 457, 1, 0},
	{"xz-utils/good-1-lzma2-2.xz",          1, 1, 0, 0, 424, 457, 1, 0},
	{"xz-utils/good-1-lzma2-3.xz",          1, 1, 0, 0, 408, 457, 1, 0},
	{"xz-utils/good-1-lzma2-4.xz",          1, 1, 0, 0, 464, 457, 4, 0},
	{"xz-utils/good-1-lzma2-5.xz",          1, 1, 0, 0, 52, 0, 1, 0},
	{"xz-utils/good-2-lzma2.xz",            1, 2, 0, 0, 92, 13, 1, 0},
	{"xz-utils/unsupported-check.xz",       1, 1, 0, 0, 68, 13, 2, 0},
}

XZ_INDEX_BLOCKS :: [?]Xz_Index_Block_Row{
	{"7z.arm.bcj.xz",                       1, 1, 12, 0, 39884, 131072},
	{"7z.arm64.bcj.xz",                     1, 1, 12, 0, 32584, 131072},
	{"7z.armthumb.bcj.xz",                  1, 1, 12, 0, 62896, 131072},
	{"7z.binary.riscv.xz",                  1, 1, 12, 0, 11428, 100000},
	{"7z.empty.xz",                         1, 1, 12, 0, 20, 0},
	{"7z.pcm16.delta-4.xz",                 1, 1, 12, 0, 49500, 65536},
	{"7z.random.xz",                        1, 1, 12, 0, 100028, 100000},
	{"7z.riscv.bcj.xz",                     1, 1, 12, 0, 57472, 131072},
	{"7z.text.blocks.xz",                   1, 1, 12, 0, 4632, 16384},
	{"7z.text.blocks.xz",                   1, 2, 4644, 16384, 4620, 16384},
	{"7z.text.blocks.xz",                   1, 3, 9264, 32768, 4720, 16384},
	{"7z.text.blocks.xz",                   1, 4, 13984, 49152, 4696, 16384},
	{"7z.text.blocks.xz",                   1, 5, 18680, 65536, 4172, 14464},
	{"7z.text.mx9.xz",                      1, 1, 12, 0, 19460, 80000},
	{"7z.text.xz",                          1, 1, 12, 0, 19448, 80000},
	{"7z.x86.bcj.xz",                       1, 1, 12, 0, 14340, 131072},
	{"arm.bcj.xz",                          1, 1, 12, 0, 39924, 131072},
	{"arm64.bcj-start.xz",                  1, 1, 12, 0, 32540, 131072},
	{"arm64.bcj.xz",                        1, 1, 12, 0, 32532, 131072},
	{"arm64.lc0-lp2-pb0.xz",                1, 1, 12, 0, 35228, 131072},
	{"armthumb.bcj.xz",                     1, 1, 12, 0, 62964, 131072},
	{"binary.bcj-arm.xz",                   1, 1, 12, 0, 11644, 100000},
	{"binary.bcj-armthumb.xz",              1, 1, 12, 0, 11604, 100000},
	{"binary.bcj-ia64.xz",                  1, 1, 12, 0, 11604, 100000},
	{"binary.bcj-powerpc.xz",               1, 1, 12, 0, 15112, 100000},
	{"binary.bcj-riscv.xz",                 1, 1, 12, 0, 11604, 100000},
	{"binary.bcj-sparc.xz",                 1, 1, 12, 0, 12088, 100000},
	{"concat-padding.xz",                   1, 1, 12, 0, 19500, 80000},
	{"concat-padding.xz",                   3, 2, 19588, 80000, 256, 250},
	{"concat.xz",                           1, 1, 12, 0, 19500, 80000},
	{"concat.xz",                           2, 2, 19548, 80000, 256, 250},
	{"one.xz",                              1, 1, 12, 0, 36, 1},
	{"pcm16.delta-2.xz",                    1, 1, 12, 0, 64100, 65536},
	{"pcm16.delta-4.xz",                    1, 1, 12, 0, 49240, 65536},
	{"random.xz",                           1, 1, 12, 0, 100036, 100000},
	{"rgba.delta-256.xz",                   1, 1, 12, 0, 452, 65536},
	{"rgba.delta-4.xz",                     1, 1, 12, 0, 196, 65536},
	{"riscv.bcj-start.xz",                  1, 1, 12, 0, 57480, 131072},
	{"riscv.bcj.xz",                        1, 1, 12, 0, 57460, 131072},
	{"same.xz",                             1, 1, 12, 0, 104, 32768},
	{"text.block-list.xz",                  1, 1, 12, 0, 580, 1024},
	{"text.block-list.xz",                  1, 2, 592, 1024, 3140, 10240},
	{"text.block-list.xz",                  1, 3, 3732, 11264, 16936, 68736},
	{"text.blocks-16k.xz",                  1, 1, 12, 0, 4652, 16384},
	{"text.blocks-16k.xz",                  1, 2, 4664, 16384, 4640, 16384},
	{"text.blocks-16k.xz",                  1, 3, 9304, 32768, 4748, 16384},
	{"text.blocks-16k.xz",                  1, 4, 14052, 49152, 4720, 16384},
	{"text.blocks-16k.xz",                  1, 5, 18772, 65536, 4180, 14464},
	{"text.check-crc32.xz",                 1, 1, 12, 0, 19496, 80000},
	{"text.check-crc64.xz",                 1, 1, 12, 0, 19500, 80000},
	{"text.check-none.xz",                  1, 1, 12, 0, 19492, 80000},
	{"text.check-sha256.xz",                1, 1, 12, 0, 19524, 80000},
	{"text.delta-1.xz",                     1, 1, 12, 0, 22340, 80000},
	{"text.dict-1536m.xz",                  1, 1, 12, 0, 19500, 80000},
	{"text.dict-4k.xz",                     1, 1, 12, 0, 21588, 80000},
	{"text.dict-max.xz",                    1, 1, 12, 0, 19500, 80000},
	{"text.fast-hc4.xz",                    1, 1, 12, 0, 21776, 80000},
	{"text.lc4-lp0-pb0.xz",                 1, 1, 12, 0, 19456, 80000},
	{"text.pb4.xz",                         1, 1, 12, 0, 19604, 80000},
	{"text.preset-0.xz",                    1, 1, 12, 0, 23288, 80000},
	{"text.preset-1.xz",                    1, 1, 12, 0, 22084, 80000},
	{"text.preset-9.xz",                    1, 1, 12, 0, 19500, 80000},
	{"text.preset-9e.xz",                   1, 1, 12, 0, 19548, 80000},
	{"text.threads.xz",                     1, 1, 12, 0, 4652, 16384},
	{"text.threads.xz",                     1, 2, 4664, 16384, 4640, 16384},
	{"text.threads.xz",                     1, 3, 9304, 32768, 4748, 16384},
	{"text.threads.xz",                     1, 4, 14052, 49152, 4720, 16384},
	{"text.threads.xz",                     1, 5, 18772, 65536, 4180, 14464},
	{"x86.bcj-start.xz",                    1, 1, 12, 0, 14400, 131072},
	{"x86.bcj.xz",                          1, 1, 12, 0, 14396, 131072},
	{"x86.block-filters.xz",                1, 1, 12, 0, 4164, 32768},
	{"x86.block-filters.xz",                1, 2, 4176, 32768, 6852, 32768},
	{"x86.block-filters.xz",                1, 3, 11028, 65536, 4204, 32768},
	{"x86.block-filters.xz",                1, 4, 15232, 98304, 3948, 32768},
	{"x86.chain-4.xz",                      1, 1, 12, 0, 28760, 131072},
	{"xz-utils/good-1-3delta-lzma2.xz",     1, 1, 12, 0, 492, 457},
	{"xz-utils/good-1-arm64-lzma2-1.xz",    1, 1, 12, 0, 476, 8576},
	{"xz-utils/good-1-arm64-lzma2-2.xz",    1, 1, 12, 0, 452, 8576},
	{"xz-utils/good-1-block_header-1.xz",   1, 1, 12, 0, 40, 13},
	{"xz-utils/good-1-block_header-2.xz",   1, 1, 12, 0, 36, 13},
	{"xz-utils/good-1-block_header-3.xz",   1, 1, 12, 0, 36, 13},
	{"xz-utils/good-1-check-crc32.xz",      1, 1, 12, 0, 36, 13},
	{"xz-utils/good-1-check-crc64.xz",      1, 1, 12, 0, 40, 13},
	{"xz-utils/good-1-check-none.xz",       1, 1, 12, 0, 32, 13},
	{"xz-utils/good-1-check-sha256.xz",     1, 1, 12, 0, 64, 13},
	{"xz-utils/good-1-delta-lzma2.tiff.xz", 1, 1, 12, 0, 51280, 929138},
	{"xz-utils/good-1-empty-bcj-lzma2.xz",  1, 1, 12, 0, 20, 0},
	{"xz-utils/good-1-lzma2-1.xz",          1, 1, 12, 0, 388, 457},
	{"xz-utils/good-1-lzma2-2.xz",          1, 1, 12, 0, 388, 457},
	{"xz-utils/good-1-lzma2-3.xz",          1, 1, 12, 0, 372, 457},
	{"xz-utils/good-1-lzma2-4.xz",          1, 1, 12, 0, 428, 457},
	{"xz-utils/good-1-lzma2-5.xz",          1, 1, 12, 0, 20, 0},
	{"xz-utils/good-2-lzma2.xz",            1, 1, 12, 0, 28, 6},
	{"xz-utils/good-2-lzma2.xz",            1, 2, 40, 6, 28, 7},
	{"xz-utils/unsupported-check.xz",       1, 1, 12, 0, 36, 13},
}

@(test)
test_xz_index_matches_xz :: proc(t: ^testing.T) {
	streams := XZ_INDEX_STREAMS
	blocks  := XZ_INDEX_BLOCKS
	next_block := 0
	for first := 0; first < len(streams); {
		name := streams[first].name
		last := first
		for last < len(streams) && streams[last].name == name {
			last += 1
		}
		file_streams := streams[first:last]
		first = last
		block_start := next_block
		for next_block < len(blocks) && blocks[next_block].name == name {
			next_block += 1
		}
		file_blocks := blocks[block_start:next_block]

		data, read_err := os.read_entire_file(xz_asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		defer delete(data)
		index, err := xz.read_index(data)
		defer xz.index_destroy(&index)
		if !testing.expectf(t, err == nil, "%s: %v", name, err) {
			continue
		}
		xz_index_expect_rows(t, name, &index, file_streams, file_blocks, i64(len(data)))

		f, open_err := os.open(xz_asset(name))
		if !testing.expectf(t, open_err == nil, "%s: %v", name, open_err) {
			continue
		}
		from_stream, stream_err := xz.read_index(os.to_stream(f))
		os.close(f)
		testing.expectf(t, stream_err == nil && xz_index_equal(&index, &from_stream), "%s: stream index differs (%v)", name, stream_err)
		xz.index_destroy(&from_stream)
	}
	testing.expect_value(t, next_block, len(blocks))
}

@(test)
test_xz_index_agrees_with_decode :: proc(t: ^testing.T) {
	for c in XZ_CASES {
		data, read_err := os.read_entire_file(xz_asset(c.name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", c.name, read_err) {
			continue
		}
		xz_index_expect_agreement(t, c.name, data)
		delete(data)
	}
}

@(test)
test_xz_index_random_reads :: proc(t: ^testing.T) {
	for name in XZ_INDEX_MULTI {
		data, read_err := os.read_entire_file(xz_asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		xz_index_random_reads(t, name, data, 100)
		delete(data)
	}

	g := Lz4_Test_Lcg{state = 0x787a6964}
	plain := lz4_test_lcg_text(&g, 160_000)
	defer delete(plain)
	file: [dynamic]u8
	defer delete(file)
	checks  := [?]xz.Check{.None, .CRC32, .CRC64, .SHA256}
	lengths := [?]int{20_000, 50_000, 0, 90_000}
	paddings := [?]int{4, 0, 12, 8}
	sizes   := [?]int{3_000, 7_777, 1_000, 16_384}
	offset  := 0
	for check, i in checks {
		part := plain[offset:][:lengths[i]]
		offset += lengths[i]
		options := xz.Options{check = check, block_size = sizes[i]}
		packed: [dynamic]u8
		testing.expect_value(t, xz.compress(&packed, part, .Level_1, options), nil)
		append(&file, ..packed[:])
		delete(packed)
		for _ in 0..<paddings[i] {
			append(&file, 0)
		}
	}
	index, err := xz.read_index(file[:])
	defer xz.index_destroy(&index)
	if !testing.expect_value(t, err, nil) || !testing.expect_value(t, len(index.streams), 4) {
		return
	}
	compressed := i64(0)
	for s, i in index.streams {
		testing.expect_value(t, s.check_id, u8(checks[i]))
		testing.expect_value(t, s.padding, i64(paddings[i]))
		testing.expect_value(t, s.compressed_offset, compressed)
		testing.expect_value(t, s.uncompressed_size, i64(lengths[i]))
		testing.expect_value(t, s.block_count, (lengths[i] + sizes[i] - 1) / sizes[i])
		compressed += s.compressed_size + s.padding
	}
	testing.expect_value(t, compressed, i64(len(file)))
	testing.expect_value(t, index.uncompressed_size, i64(offset))
	xz_index_random_reads(t, "encoded", file[:], 300)
}

@(test)
test_xz_find_block :: proc(t: ^testing.T) {
	empty_buf: [1]u8
	empty := empty_buf[:0]
	first  := transmute([]u8)string("abcdef")
	second := transmute([]u8)string("ghij")
	blocks := []Xz_Craft_Block{
		{plain = empty, lzma2 = {0x00}},
		{plain = first},
		{plain = empty, lzma2 = {0x00}},
		{plain = empty, lzma2 = {0x00}},
		{plain = second},
		{plain = empty, lzma2 = {0x00}},
	}
	file := xz_craft({stream_flags = {0, 1}, blocks = blocks})
	defer delete(file)
	out: [dynamic]u8
	defer delete(out)
	testing.expect_value(t, xz.decompress(&out, file[:]), nil)
	testing.expect_value(t, string(out[:]), "abcdefghij")

	index, err := xz.read_index(file[:])
	defer xz.index_destroy(&index)
	if !testing.expect_value(t, err, nil) || !testing.expect_value(t, len(index.blocks), 6) {
		return
	}
	for offset in i64(-2)..=12 {
		block, ok := xz.find_block(&index, offset)
		switch {
		case offset < 0 || offset >= 10:
			testing.expectf(t, !ok, "offset %d: found block %d", offset, block)
		case offset < 6:
			testing.expectf(t, ok && block == 1, "offset %d: block %d, %v", offset, block, ok)
		case:
			testing.expectf(t, ok && block == 4, "offset %d: block %d, %v", offset, block, ok)
		}
	}
	for i in 0..<len(index.blocks) {
		testing.expect_value(t, xz.decompress_block(&out, file[:], &index, i), nil)
		testing.expect_value(t, len(out), int(index.blocks[i].uncompressed_size))
	}
	xz_index_expect_agreement(t, "empty blocks", file[:])

	_, nil_ok := xz.find_block(nil, 0)
	testing.expect(t, !nil_ok)
	testing.expect_value(t, xz.decompress_block(&out, file[:], &index, -1), compress.Error(compress.General_Error.Incompatible_Options))
	testing.expect_value(t, xz.decompress_block(&out, file[:], &index, 6), compress.Error(compress.General_Error.Incompatible_Options))
	testing.expect_value(t, xz.decompress_block(nil, file[:], &index, 0), compress.Error(compress.General_Error.Incompatible_Options))
	testing.expect_value(t, xz.decompress_block(&out, file[:30], &index, 1), compress.Error(compress.General_Error.Stream_Too_Short))

	for name in ([?]string{"empty.xz", "7z.empty.xz", "xz-utils/good-0catpad-empty.xz"}) {
		data, read_err := os.read_entire_file(xz_asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		empty_index, empty_err := xz.read_index(data)
		testing.expectf(t, empty_err == nil && empty_index.uncompressed_size == 0, "%s: %v", name, empty_err)
		_, found := xz.find_block(&empty_index, 0)
		testing.expectf(t, !found, "%s: found a block at 0", name)
		xz.index_destroy(&empty_index)
		delete(data)
	}
}

@(test)
test_xz_decompress_block_options :: proc(t: ^testing.T) {
	INTERVAL :: 10_000
	g := Lz4_Test_Lcg{state = 0x787a4f52}
	text := lz4_test_lcg_text(&g, 120_000)
	defer delete(text)
	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, xz.compress(&packed, text, .Level_1, {block_size = 50_000}), nil)
	index, index_err := xz.read_index(packed[:])
	defer xz.index_destroy(&index)
	if !testing.expect_value(t, index_err, nil) || !testing.expect_value(t, len(index.blocks), 3) {
		return
	}
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	first: [dynamic]compress.Progress
	defer delete(first)
	need := lzma_test_probs_memory(.Lzma2)

	for b in 0..<len(index.blocks) {
		info   := index.blocks[b]
		size   := int(info.uncompressed_size)
		padded := int((info.unpadded_size + 3) &~ 3)
		want   := text[info.uncompressed_offset:][:size]
		clear(&first)
		for use_stream in ([]bool{false, true}) {
			label := fmt.tprintf("block %v, stream %v", b, use_stream)
			br: bytes.Reader
			stream := bytes.reader_init(&br, packed[:])

			{
				out: [dynamic]u8
				defer delete(out)
				err := xz_index_block(&out, packed[:], stream, use_stream, &index, b, {max_output_size = size - 1})
				testing.expectf(t, err == compress.General_Error.Output_Too_Short && cap(out) == 0, "%v, limit %v: %v, capacity %v", label, size - 1, err, cap(out))
			}

			out: [dynamic]u8
			defer delete(out)
			err := xz_index_block(&out, packed[:], stream, use_stream, &index, b, {max_output_size = size})
			testing.expectf(t, err == nil && bytes.equal(out[:], want), "%v, limit %v: %v", label, size, err)

			err = xz_index_block(&out, packed[:], stream, use_stream, &index, b, ppmd_progress_options(&log, {progress_interval = INTERVAL}))
			testing.expectf(t, err == nil && bytes.equal(out[:], want), "%v progress: %v", label, err)
			testing.expectf(t, len(log.calls) == size / INTERVAL, "%v progress: %v calls", label, len(log.calls))
			ppmd_progress_expect(t, label, log.calls[:], i64(padded), i64(size), i64(padded), i64(size))
			for c, i in log.calls {
				testing.expectf(t, c.bytes_out == i64(i + 1) * INTERVAL, "%v call %v: %v bytes out", label, i, c.bytes_out)
			}
			codec_progress_same(t, label, &first, log.calls[:])

			log.cancel_at = 2
			err = xz_index_block(&out, packed[:], stream, use_stream, &index, b, ppmd_progress_options(&log, {progress_interval = INTERVAL}))
			testing.expectf(t, err == compress.General_Error.Canceled && len(log.calls) == 2, "%v cancel: %v, %v calls", label, err, len(log.calls))
			log.cancel_at = 0

			for bad in LZMA_TEST_BAD_OPTIONS {
				err = xz_index_block(&out, packed[:], stream, use_stream, &index, b, bad)
				testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v %v: %v", label, bad, err)
			}

			memory := need + (padded if use_stream else 0)
			err = xz_index_block(&out, packed[:], stream, use_stream, &index, b, {max_memory = memory - 1})
			testing.expectf(t, err == compress.General_Error.Memory_Limit_Exceeded, "%v, memory %v: %v", label, memory - 1, err)
			err = xz_index_block(&out, packed[:], stream, use_stream, &index, b, {max_memory = memory})
			testing.expectf(t, err == nil && bytes.equal(out[:], want), "%v, memory %v: %v", label, memory, err)
		}
		free_all(context.temp_allocator)
	}
}

xz_index_block :: proc(output: ^[dynamic]u8, input: []u8, stream: io.Stream, use_stream: bool, index: ^xz.Index, block: int, options: compress.Options) -> (err: compress.Error) {
	if use_stream {
		return xz.decompress_block(output, stream, index, block, {}, options)
	}
	return xz.decompress_block(output, input, index, block, {}, options)
}

@(test)
test_xz_index_hostile :: proc(t: ^testing.T) {
	short := transmute([]u8)string("Odin xz")
	long  := transmute([]u8)string("Odin xz, random access")
	two   := []Xz_Craft_Block{{plain = short}, {plain = long}}
	sized := []Xz_Craft_Block{{plain = short, uncompressed = {mode = .Correct}}, {plain = long, uncompressed = {mode = .Correct}}}
	both  := []Xz_Craft_Block{{plain = short, compressed = {mode = .Correct}}, {plain = long, compressed = {mode = .Correct}}}
	bad_check := []Xz_Craft_Block{{plain = short}, {plain = long, check_xor = 1}}

	XZE :: compress.XZ_Error
	GE  :: compress.General_Error

	cases := [?]Xz_Index_Hostile{
		{"valid", {stream_flags = {0, 1}, blocks = two}, 0, nil, false, nil},
		{"valid, sizes in headers", {stream_flags = {0, 4}, blocks = both}, 0, nil, false, nil},
		{"valid, reserved check", {stream_flags = {0, 2}, blocks = two}, 0, nil, false, nil},
		{"valid, padding after", {stream_flags = {0, 1}, blocks = two, tail = {0, 0, 0, 0, 0, 0, 0, 0}}, 0, nil, false, nil},
		{"padding before", {stream_flags = {0, 1}, blocks = two}, 4, XZE.Invalid_Magic, false, nil},
		{"padding of 3", {stream_flags = {0, 1}, blocks = two, tail = {0, 0, 0}}, 0, XZE.Invalid_Padding, false, nil},
		{"garbage after", {stream_flags = {0, 1}, blocks = two, tail = {0, 0, 0, 1}}, 0, XZE.Invalid_Magic, false, nil},
		{"footer CRC", {stream_flags = {0, 1}, blocks = two, footer_crc_xor = 1}, 0, XZE.Header_Checksum_Failed, false, nil},
		{"footer magic", {stream_flags = {0, 1}, blocks = two, bad_footer_magic = true}, 0, XZE.Invalid_Magic, false, nil},
		{"footer flags", {stream_flags = {0, 1}, blocks = two, footer_flags = [2]u8{0, 4}}, 0, XZE.Footer_Mismatch, false, nil},
		{"footer reserved", {stream_flags = {0, 1}, blocks = two, footer_flags = [2]u8{1, 1}}, 0, XZE.Reserved_Bit_Set, false, nil},
		{"backward size + 1", {stream_flags = {0, 1}, blocks = two, backward_delta = 1}, 0, nil, true, nil},
		{"backward size past start", {stream_flags = {0, 1}, blocks = two, backward_delta = 1 << 20}, 0, XZE.Invalid_Index, false, nil},
		{"index CRC", {stream_flags = {0, 1}, blocks = two, index_crc_xor = 1}, 0, XZE.Header_Checksum_Failed, false, nil},
		{"index padding", {stream_flags = {0, 1}, blocks = two, index_padding = 1}, 0, XZE.Invalid_Index, false, nil},
		{"index count + 1", {stream_flags = {0, 1}, blocks = two, index_count_delta = 1}, 0, XZE.Invalid_Index, false, nil},
		{"index count - 1", {stream_flags = {0, 1}, blocks = two, index_count_delta = -1}, 0, XZE.Invalid_Index, false, nil},
		{"index huge count", {stream_flags = {0, 1}, blocks = two, index_count_raw = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F}}, 0, XZE.Invalid_Index, false, nil},
		{"unpadded size 4", {stream_flags = {0, 1}, blocks = two, unpadded_value = 4}, 0, XZE.Invalid_Index, false, nil},
		{"unpadded size past start", {stream_flags = {0, 1}, blocks = two, unpadded_value = 1 << 40}, 0, XZE.Invalid_Index, false, nil},
		{"header CRC", {stream_flags = {0, 1}, blocks = two, header_crc_xor = 1}, 0, XZE.Header_Checksum_Failed, false, nil},
		{"header magic", {stream_flags = {0, 1}, blocks = two, bad_magic = true}, 0, XZE.Invalid_Magic, false, nil},
		{"uncompressed sizes swapped", {stream_flags = {0, 1}, blocks = two, uncompressed_delta = 3}, 0, nil, false, XZE.Index_Mismatch},
		{"uncompressed sizes swapped, sizes in headers", {stream_flags = {0, 1}, blocks = sized, uncompressed_delta = 3}, 0, nil, false, XZE.Index_Mismatch},
		{"uncompressed sizes swapped back", {stream_flags = {0, 1}, blocks = two, uncompressed_delta = -3}, 0, nil, false, XZE.Index_Mismatch},
		{"uncompressed sizes swapped back, sizes in headers", {stream_flags = {0, 1}, blocks = sized, uncompressed_delta = -3}, 0, nil, false, XZE.Index_Mismatch},
		{"unpadded sizes swapped back by 4", {stream_flags = {0, 1}, blocks = two, unpadded_delta = -4}, 0, nil, false, XZE.Index_Mismatch},
		{"unpadded sizes swapped in padding", {stream_flags = {0, 1}, blocks = two, unpadded_delta = 1}, 0, nil, false, XZE.Index_Mismatch},
		{"unpadded sizes swapped by 4", {stream_flags = {0, 1}, blocks = two, unpadded_delta = 4}, 0, nil, false, XZE.Index_Mismatch},
		{"unpadded sizes swapped, sizes in headers", {stream_flags = {0, 4}, blocks = both, unpadded_delta = 4}, 0, nil, false, XZE.Index_Mismatch},
		{"block check", {stream_flags = {0, 1}, blocks = bad_check}, 0, nil, false, XZE.Block_Checksum_Failed},
		{"truncated", {stream_flags = {0, 1}, blocks = two, truncate = 40}, 0, nil, true, nil},
	}
	for c in cases {
		crafted := xz_craft(c.craft)
		defer delete(crafted)
		input: [dynamic]u8
		defer delete(input)
		for _ in 0..<c.prefix {
			append(&input, 0)
		}
		append(&input, ..crafted[:])

		index, err := xz.read_index(input[:])
		switch {
		case c.any_error:
			testing.expectf(t, err != nil, "%s: read the index", c.label)
		case:
			testing.expectf(t, err == c.index_err, "%s: %v, want %v", c.label, err, c.index_err)
		}
		if err == nil {
			block_err: compress.Error
			out: [dynamic]u8
			for i in 0..<len(index.blocks) {
				if block_err = xz.decompress_block(&out, input[:], &index, i); block_err != nil {
					break
				}
			}
			delete(out)
			testing.expectf(t, block_err == c.block_err, "%s: block %v, want %v", c.label, block_err, c.block_err)
		}
		xz.index_destroy(&index)
		xz_index_expect_agreement(t, c.label, input[:])

		r: bytes.Reader
		from_stream, stream_err := xz.read_index(bytes.reader_init(&r, input[:]))
		testing.expectf(t, stream_err == err, "%s: stream %v, bytes %v", c.label, stream_err, err)
		xz.index_destroy(&from_stream)

		nil_index, nil_err := xz.read_index(input[:], runtime.nil_allocator())
		_, allocation_failed := nil_err.(runtime.Allocator_Error)
		testing.expectf(t, allocation_failed || (err != nil && nil_err == err), "%s: nil allocator %v, want %v", c.label, nil_err, err)
		xz.index_destroy(&nil_index)
	}

	padded := xz_craft({stream_flags = {0, 1}, blocks = two})
	defer delete(padded)
	footer_at := len(padded) - 12
	backward  := int(endian.unchecked_get_u32le(padded[footer_at + 4:][:4]))
	index_at  := footer_at - (backward + 1) * 4
	inject_at(&padded, footer_at - 4, 0, 0, 0, 0)
	footer_at += 4
	endian.unchecked_put_u32le(padded[footer_at - 4:][:4], hash.crc32(padded[index_at:footer_at - 4]))
	endian.unchecked_put_u32le(padded[footer_at + 4:][:4], u32(backward + 1))
	endian.unchecked_put_u32le(padded[footer_at:][:4], hash.crc32(padded[footer_at + 4:][:6]))
	long_index, long_err := xz.read_index(padded[:])
	testing.expect_value(t, long_err, compress.Error(XZE.Invalid_Index))
	xz.index_destroy(&long_index)
	xz_index_expect_agreement(t, "index padding of 4", padded[:])
}

@(test)
test_xz_index_truncated_and_mutated :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0x1d8e4a07}
	plain := lz4_test_lcg_text(&g, 6_000)
	defer delete(plain)
	file: [dynamic]u8
	defer delete(file)
	for check, i in ([?]xz.Check{.CRC32, .None}) {
		packed: [dynamic]u8
		testing.expect_value(t, xz.compress(&packed, plain[i * 1000:], .Level_1, {check = check, block_size = 700}), nil)
		append(&file, ..packed[:])
		append(&file, 0, 0, 0, 0)
		delete(packed)
	}
	index, err := xz.read_index(file[:])
	if !testing.expect_value(t, err, nil) || !testing.expect(t, len(index.blocks) > 10) {
		xz.index_destroy(&index)
		return
	}
	xz.index_destroy(&index)

	for n in 0..<len(file) {
		xz_index_expect_agreement(t, "prefix", file[:n])
		xz_index_expect_agreement(t, "suffix", file[n + 1:])
	}
	mutated := make([]u8, len(file))
	defer delete(mutated)
	rounds := 300 if SLIM_TESTS else 3_000
	for round in 0..<rounds {
		copy(mutated, file[:])
		for _ in 0..<1 + round % 3 {
			at := rand.int_max(len(mutated))
			mutated[at] ~= u8(1 + rand.int_max(255))
		}
		if !xz_index_expect_agreement(t, "mutation", mutated) {
			break
		}
	}
}

xz_index_decode_all :: proc(input: []u8) -> (out: [dynamic]u8, err: compress.Error) {
	index := xz.read_index(input) or_return
	defer xz.index_destroy(&index)
	block: [dynamic]u8
	defer delete(block)
	for i in 0..<len(index.blocks) {
		xz.decompress_block(&block, input, &index, i) or_return
		append(&out, ..block[:])
	}
	return
}

xz_index_expect_agreement :: proc(t: ^testing.T, label: string, input: []u8, loc := #caller_location) -> bool {
	full: [dynamic]u8
	defer delete(full)
	full_err := xz.decompress(&full, input)
	random, random_err := xz_index_decode_all(input)
	defer delete(random)
	if !testing.expectf(t, (full_err == nil) == (random_err == nil), "%s (%d bytes): decode %v, index %v", label, len(input), full_err, random_err, loc = loc) {
		return false
	}
	if full_err == nil {
		return testing.expectf(t, string(full[:]) == string(random[:]), "%s (%d bytes): index output differs", label, len(input), loc = loc)
	}
	return true
}

xz_index_random_reads :: proc(t: ^testing.T, label: string, input: []u8, reads: int) {
	full: [dynamic]u8
	defer delete(full)
	if !testing.expectf(t, xz.decompress(&full, input) == nil, "%s: decode", label) {
		return
	}
	index, err := xz.read_index(input)
	defer xz.index_destroy(&index)
	if !testing.expectf(t, err == nil, "%s: %v", label, err) || !testing.expectf(t, len(index.blocks) > 1, "%s: %d blocks", label, len(index.blocks)) {
		return
	}
	testing.expect_value(t, index.uncompressed_size, i64(len(full)))
	r: bytes.Reader
	stream := bytes.reader_init(&r, input)

	for k in 0..<reads {
		offset := rand.int_max(len(full))
		length := 1 + rand.int_max(min(len(full) - offset, 40_000))
		got, read_err := xz_index_read_at(input, stream, k % 2 == 1, &index, offset, length)
		testing.expectf(t, read_err == nil && string(got[:]) == string(full[offset:][:length]), "%s: read %d at %d: %v", label, length, offset, read_err)
		delete(got)
	}
	for b, i in index.blocks {
		if b.uncompressed_size == 0 {
			continue
		}
		start := b.uncompressed_offset
		end   := start + b.uncompressed_size
		for at in ([?]i64{start, start + b.uncompressed_size / 2, end - 1}) {
			found, ok := xz.find_block(&index, at)
			testing.expectf(t, ok && found == i, "%s: offset %d in block %d, found %d", label, at, i, found)
		}
		if start >= 3 {
			got, read_err := xz_index_read_at(input, stream, false, &index, int(start) - 3, 6)
			testing.expectf(t, read_err == nil && string(got[:]) == string(full[start - 3:][:6]), "%s: read across block %d: %v", label, i, read_err)
			delete(got)
		}
	}
	_, past := xz.find_block(&index, i64(len(full)))
	_, before := xz.find_block(&index, -1)
	testing.expectf(t, !past && !before, "%s: found a block out of range", label)
}

xz_index_read_at :: proc(input: []u8, stream: io.Stream, use_stream: bool, index: ^xz.Index, offset, length: int) -> (out: [dynamic]u8, err: compress.Error) {
	block: [dynamic]u8
	defer delete(block)
	pos := offset
	for pos < offset + length {
		b, ok := xz.find_block(index, i64(pos))
		if !ok {
			return out, compress.General_Error.Stream_Too_Short
		}
		if use_stream {
			xz.decompress_block(&block, stream, index, b) or_return
		} else {
			xz.decompress_block(&block, input, index, b) or_return
		}
		start := pos - int(index.blocks[b].uncompressed_offset)
		if start < 0 || start >= len(block) {
			return out, compress.XZ_Error.Index_Mismatch
		}
		n := min(len(block) - start, offset + length - pos)
		append(&out, ..block[start:][:n])
		pos += n
	}
	return
}

xz_index_expect_rows :: proc(t: ^testing.T, name: string, index: ^xz.Index, streams: []Xz_Index_Stream_Row, blocks: []Xz_Index_Block_Row, file_size: i64) {
	if !testing.expectf(t, len(index.streams) == len(streams) && len(index.blocks) == len(blocks), "%s: %d streams, %d blocks", name, len(index.streams), len(index.blocks)) {
		return
	}
	uncompressed := i64(0)
	for row, i in streams {
		s := index.streams[i]
		testing.expectf(t, s.check_id == row.check && s.compressed_offset == row.offset && s.compressed_size == row.size &&
			s.uncompressed_offset == row.uncompressed_offset && s.uncompressed_size == row.uncompressed_size &&
			s.padding == row.padding && s.block_count == row.blocks, "%s stream %d: %v, want %v", name, i, s, row)
		uncompressed += row.uncompressed_size
	}
	for row, i in blocks {
		b := index.blocks[i]
		s := index.streams[b.stream]
		testing.expectf(t, b.stream == row.stream - 1 && b.compressed_offset == row.offset && b.uncompressed_offset == row.uncompressed_offset &&
			(b.unpadded_size + 3) &~ 3 == row.total && b.uncompressed_size == row.uncompressed_size &&
			i >= s.first_block && i < s.first_block + s.block_count, "%s block %d: %v, want %v", name, i, b, row)
	}
	testing.expectf(t, index.compressed_size == file_size && index.uncompressed_size == uncompressed, "%s: sizes %d, %d", name, index.compressed_size, index.uncompressed_size)
}

xz_index_equal :: proc(a, b: ^xz.Index) -> bool {
	if len(a.streams) != len(b.streams) || len(a.blocks) != len(b.blocks) {
		return false
	}
	if a.compressed_size != b.compressed_size || a.uncompressed_size != b.uncompressed_size {
		return false
	}
	for s, i in a.streams {
		if s != b.streams[i] {
			return false
		}
	}
	for s, i in a.blocks {
		if s != b.blocks[i] {
			return false
		}
	}
	return true
}
