package tar

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:io"
import "core:os"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Formats: v7, ustar and pax, as specified by POSIX.1-2024 (IEEE Std 1003.1-2024), `pax`:
		https://pubs.opengroup.org/onlinepubs/9799919799/utilities/pax.html

	GNU tar's format and its sparse files, as described in the GNU tar manual:
		https://www.gnu.org/software/tar/manual/html_node/Standard.html and
		https://www.gnu.org/software/tar/manual/html_node/Sparse-Formats.html
*/

BLOCK_SIZE         :: 512
RECORD_SIZE        :: 20 * BLOCK_SIZE
WRITE_CHUNK_SIZE   :: 64 * 1024
USTAR_NAME_MAX     :: 100
USTAR_PREFIX_MAX   :: 155
USTAR_OWNER_MAX    :: 32
USTAR_SIZE_MAX     :: 0o777_7777_7777
USTAR_ID_MAX       :: 0o777_7777
BUFFER_SIZE        :: 64 * 1024
HEAD_SIZE          :: 1024
HEADER_RECORD_MAX  :: 1 << 20
MEMBER_SIZE_MAX    :: max(i64) - BLOCK_SIZE
GNU_MAGIC          :: "ustar  \x00"
GNU_LONG_NAME      :: "././@LongLink"
GNU_BASE256_8_MAX  :: 1 << 56 - 1
SPARSE_IN_HEADER   :: 4
SPARSE_IN_BLOCK    :: 21
ZERO_CHUNK_SIZE    :: 8 * 1024

Error     :: archive.Error
Tar_Error :: archive.Tar_Error

Header_Format :: enum u8 {
	V7,
	Ustar,
	GNU,
	Star,
}

Write_Format :: enum u8 {
	Pax,
	Ustar,
	GNU,
}

Sparse_Region :: struct {
	offset: i64,
	size:   i64,
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
	long_name:    [dynamic]u8,
	long_link:    [dynamic]u8,
	has_long:     bit_set[Long_Kind],
	label:        [dynamic]u8,
	has_label:    bool,
	sparse:       bool,
	sparse_map:   [dynamic]Sparse_Region,
	sparse_index: int,
	sparse_pos:   i64,
	data_size:    i64,
	current:      archive.File_Info,
	has_current:  bool,
	unsupported:  Error,
	broken:       Error,
	pending:      Error,
	fail_path:    [dynamic]u8,
}

Long_Kind :: enum u8 {
	Name,
	Link,
}

Pax_Sparse :: struct {
	major:      string,
	minor:      string,
	name:       string,
	size:       string,
	numblocks:  string,
	sparse_map: string,
	has_map:    bool,
	has_pairs:  bool,
	has_keys:   bool,
}

Entry_Data :: union {
	[]u8,
	io.Reader,
}

Writer_Options :: struct {
	compression:   archive.Method,
	level:         Maybe(int),
	format:        Write_Format,
	deterministic: bool,
	options:       compress.Options,
}

Writer :: struct {
	allocator:  runtime.Allocator,
	options:    Writer_Options,
	stream:     io.Stream,
	out:        io.Stream,
	file:       ^os.File,
	path:       string,
	deflate:    deflate.Deflate_Writer,
	bzip2:      bzip2.Writer,
	lz4:        lz4.Frame_Writer,
	block:      [BLOCK_SIZE]u8,
	records:    [dynamic]u8,
	name:       [dynamic]u8,
	walk_name:  [dynamic]u8,
	chunk:      []u8,
	written:    i64,
	count:      i64,
	archive_in: i64,
	err:        Error,
	committed:  bool,
	active:     bool,
}

Pending_Entry :: struct {
	name:      string,
	type:      archive.Entry_Type,
	typeflag:  u8,
	size:      i64,
	next:      i64,
	long_name: bool,
	long_link: bool,
}

Walked_Entry :: struct {
	name: string,
	info: os.File_Info,
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
