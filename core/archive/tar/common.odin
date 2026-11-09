package tar

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/deflate"
import "core:io"
import "core:os"

BLOCK_SIZE         :: 512
BUFFER_SIZE        :: 64 * 1024
HEAD_SIZE          :: 1024
HEADER_RECORD_MAX  :: 1 << 20

Error     :: archive.Error
Tar_Error :: archive.Tar_Error

Header_Format :: enum u8 {
	V7,
	Ustar,
	GNU,
	Star,
}

Header :: struct {
	block:          [BLOCK_SIZE]u8,
	format:         Header_Format,
	typeflag:       u8,
	global_records: []u8,
	local_records:  []u8,
}

Global_Key :: enum u8 {
	Path,
	Link_Path,
	User,
	Group,
	Comment,
	Size,
	Uid,
	Gid,
	Modification_Time,
	Access_Time,
	Creation_Time,
}

@(rodata)
GLOBAL_KEYS := [Global_Key]string{
	.Path              = "path",
	.Link_Path         = "linkpath",
	.User              = "uname",
	.Group             = "gname",
	.Comment           = "comment",
	.Size              = "size",
	.Uid               = "uid",
	.Gid               = "gid",
	.Modification_Time = "mtime",
	.Access_Time       = "atime",
	.Creation_Time     = "LIBARCHIVE.creationtime",
}

Source :: enum u8 {
	Memory,
	Stream,
	Gzip,
	Decoded,
}

Prefix_Stream :: struct {
	prefix: []u8,
	pos:    int,
	stream: io.Stream,
	err:    io.Error,
}

Reader :: struct {
	allocator:    runtime.Allocator,
	options:      compress.Options,
	compression:  archive.Method,
	source:       Source,

	input:        io.Stream,
	input_data:   []u8,
	input_start:  i64,
	input_size:   i64,
	seekable:     bool,
	file:         ^os.File,

	head:         [HEAD_SIZE]u8,
	prefix:       Prefix_Stream,
	ctx:          compress.Context,
	inflate:      deflate.Inflate_Reader,
	decoded:      [dynamic]u8,

	data:         []u8,
	buf:          []u8,
	pos:          int,
	end:          int,
	stream:       io.Stream,
	offset:       i64,

	index:        int,
	remaining:    i64,
	padding:      i64,
	ended:        bool,
	member_count: int,

	header:       Header,
	local_buf:    [dynamic]u8,
	global_buf:   [dynamic]u8,
	globals:      [Global_Key][dynamic]u8,
	global_set:   bit_set[Global_Key],
	gnu_sparse:   bool,
	path_buf:     [dynamic]u8,
	current:      archive.File_Info,
	has_current:  bool,
	unsupported:  Error,
	broken:       Error,
	pending:      Error,
	fail_path:    [dynamic]u8,
}

Iterator :: struct {
	reader:   ^Reader,
	err:      Error,
	err_path: [dynamic]u8,
}

@(private)
Sniffed :: enum u8 {
	Unknown,
	Plain,
	Gzip,
	BZip2,
	LZ4,
	LZMA,
	XZ,
}

@(private)
_sniff :: proc "contextless" (head: []u8) -> (sniffed: Sniffed) {
	switch compress.which(head) {
	case .Gzip:      return .Gzip
	case .BZip2:     return .BZip2
	case .LZ4_Frame: return .LZ4
	case .XZ:        return .XZ
	case .LZMA_Alone, .Zlib, .Unknown:
	}
	if len(head) >= 262 && string(head[257:262]) == "ustar" {
		return .Plain
	}
	if len(head) >= BLOCK_SIZE {
		block := head[:BLOCK_SIZE]
		if _all_zero(block) || _checksum_ok(block) {
			return .Plain
		}
	}
	if compress.which(head) == .LZMA_Alone {
		return .LZMA
	}
	return .Unknown
}

@(private)
_all_zero :: proc "contextless" (block: []u8) -> bool {
	for b in block {
		if b != 0 {
			return false
		}
	}
	return true
}

@(private)
_checksum_ok :: proc "contextless" (block: []u8) -> bool {
	stored, ok := _parse_octal(block[148:156])
	if !ok {
		return false
	}
	unsigned_sum: i64
	signed_sum:   i64
	for b, i in block[:BLOCK_SIZE] {
		c := b
		if i >= 148 && i < 156 {
			c = ' '
		}
		unsigned_sum += i64(c)
		signed_sum   += i64(i8(c))
	}
	return stored == unsigned_sum || stored == signed_sum
}

@(private)
_parse_octal :: proc "contextless" (field: []u8) -> (value: i64, ok: bool) {
	field := field
	for len(field) > 0 && (field[0] == ' ' || field[0] == 0) {
		field = field[1:]
	}
	for len(field) > 0 && (field[len(field) - 1] == ' ' || field[len(field) - 1] == 0) {
		field = field[:len(field) - 1]
	}
	for c in field {
		if c < '0' || c > '7' {
			return 0, false
		}
		if value > max(i64) >> 3 {
			return 0, false
		}
		value = value << 3 | i64(c - '0')
	}
	return value, true
}
