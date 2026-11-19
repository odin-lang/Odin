package test_core_compress

import "core:compress"
import "core:os"
import "core:strings"
import "core:testing"

TEST_SUITE_PATH_TAR :: ODIN_ROOT + "tests/core/assets/TAR/"

@(test)
test_which :: proc(t: ^testing.T) {
	Case :: struct {
		file:   string,
		format: compress.Stream_Format,
	}
	cases := [?]Case{
		{"gnu-posix.tar.gz",   .Gzip},
		{"gnu-posix.tar.bz2",  .BZip2},
		{"gnu-posix.tar.xz",   .XZ},
		{"gnu-posix.tar.lzma", .LZMA_Alone},
		{"gnu-posix.tar",      .Unknown},
		{"bsd-mac.tar.bz2",    .BZip2},
		{"bsd-mac.tar.xz",     .XZ},
		{"bsd-win.tar.gz",     .Gzip},
	}
	for c in cases {
		path := strings.concatenate({TEST_SUITE_PATH_TAR, c.file}, context.temp_allocator)
		data, err := os.read_entire_file(path, context.allocator)
		testing.expectf(t, err == nil, "%s: %v", c.file, err)
		defer delete(data)
		testing.expectf(t, compress.which(data) == c.format, "%s: %v, want %v", c.file, compress.which(data), c.format)
	}

	testing.expect_value(t, compress.which({0x78, 0x9c, 0x03, 0x00}), compress.Stream_Format.Zlib)
	testing.expect_value(t, compress.which({0x78, 0x9d}), compress.Stream_Format.Unknown)
	testing.expect_value(t, compress.which({0x04, 0x22, 0x4d, 0x18, 0x64}), compress.Stream_Format.LZ4_Frame)
	testing.expect_value(t, compress.which({0x1f, 0x8b}), compress.Stream_Format.Unknown)
	testing.expect_value(t, compress.which({}), compress.Stream_Format.Unknown)
	lzma_header := [13]u8{0x5d, 0x00, 0x00, 0x80, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
	testing.expect_value(t, compress.which(lzma_header[:]), compress.Stream_Format.LZMA_Alone)
	odd_dictionary := [13]u8{0x5d, 0x01, 0x00, 0x80, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
	testing.expect_value(t, compress.which(odd_dictionary[:]), compress.Stream_Format.Unknown)
	zero_dictionary := [13]u8{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00}
	testing.expect_value(t, compress.which(zero_dictionary[:]), compress.Stream_Format.Unknown)
	small_dictionary := [13]u8{0x5d, 0x00, 0x08, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
	testing.expect_value(t, compress.which(small_dictionary[:]), compress.Stream_Format.Unknown)
	big_size := [13]u8{0x5d, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00}
	testing.expect_value(t, compress.which(big_size[:]), compress.Stream_Format.Unknown)
}
