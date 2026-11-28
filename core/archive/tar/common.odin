/*
Reads and writes tar archives: v7, ustar and pax as specified by POSIX.1-2024, and GNU tar's.

`open` reads an archive from a path, a byte slice or any `io.Stream`; one that can't seek, such
as a pipe, is read in a single forward pass. gzip, bzip2, LZ4 (frame), LZMA (`.lzma`) and XZ
compression are detected from the content. `create` starts a new archive at a path or on any
`io.Stream`, as pax (the default), ustar or GNU, compressed with gzip, bzip2, LZ4, LZMA or XZ,
or not at all. `write_entry` adds a member from a byte slice or an `io.Reader`, reading one of
unknown size into memory first, `write_directory` adds a whole tree, and `commit` finishes the
archive. `close` releases a reader or a writer.

Members are read through an iterator: `iterator_create` walks them in storage order, `iterate`
gives each one's `archive.File_Info`, and `extract_current` unpacks it to an `io.Writer`, or
`open_current` streams it through an `io.Reader`. `find` looks a member up by path for
`extract` or `open_member`, and `core:archive`'s `extract_all` unpacks a whole archive below a
directory. The reader has one position, shared by its iterators, `find`, `extract` and
`open_member`.

Reading takes v7, ustar, GNU and star headers, pax global and local records, GNU long names
and link targets, and GNU and pax sparse files, whose holes read as zeros. Members can be
regular files, directories, symlinks, hard links, devices and named pipes.

Writing takes an optional progress callback, for a UI's progress bar, which can also cancel;
reading a compressed archive reports its decoder's progress the same way. A deterministic mode
writes reproducible archives.

Not supported: updating an archive in place, GNU multi-volume archives, writing sparse members,
and encryption, which tar doesn't have. On js, only byte slices and streams work.
*/
package archive_tar

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/xz"
import "core:io"

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

BLOCK_SIZE        :: 512
// The most bytes of pax records, long names and sparse maps one member may carry
HEADER_RECORD_MAX :: 1 << 20

Error     :: archive.Error
Tar_Error :: archive.Tar_Error

// A header's layout, told by its magic
Header_Format :: enum u8 {
	V7,     // No magic: Unix V7
	Ustar,  // POSIX ustar, which pax extends
	GNU,    // GNU tar's
	Star,   // Schily's star, with a shorter path prefix
}

// The header layout a writer produces
Write_Format :: enum u8 {
	Pax,    // Ustar, with pax records for what ustar can't hold
	Ustar,  // Plain ustar; what it can't hold is an error
	GNU,    // GNU tar's, with long paths as extra members
}

// A member's raw header, from `current_entry`; walk its pax records with `next_record`
Entry :: struct {
	block:          [BLOCK_SIZE]u8,  // The header block as stored
	format:         Header_Format,   // The block's layout, told by its magic
	typeflag:       u8,              // The type flag, as in `block[156]`
	global_records: []u8,            // The pax global records stored just before the member
	local_records:  []u8,            // The member's own pax records
}

// Reads a tar archive, from `open`
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
	file:         io.Stream,

	head:         [HEAD_SIZE]u8,
	prefix:       Prefix_Stream,
	ctx:          compress.Context,
	inflate:      deflate.Reader,
	bzip2_reader: bzip2.Reader,
	lz4_reader:   lz4.Frame_Reader,
	lzma_reader:  lzma.Reader,
	xz_reader:    xz.Reader,

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

	header:       Entry,
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

// A regular file's data, for `write_entry`
Entry_Data :: union {
	[]u8,
	io.Reader,
}

// A writer's settings; `compression` is Store, Deflate (gzip), BZip2, LZ4, LZMA or XZ
Writer_Options :: struct {
	compression:   archive.Method,    // The whole archive's; `.Unknown` for Store
	level:         Maybe(int),        // `nil` for the method's default; else in its range
	format:        Write_Format,
	deterministic: bool,              // Reproducible: zero owners and times, sorted `write_directory`
	no_sync:       bool,
	options:       compress.Options,  // Limits and progress callback for the encoders
}

// Writes a tar archive, from `create`
Writer :: struct {
	allocator:  runtime.Allocator,
	options:    Writer_Options,
	stream:     io.Stream,
	out:        io.Stream,
	disk:       archive.Disk,
	deflate:    deflate.Writer,
	bzip2:      bzip2.Writer,
	lz4:        lz4.Frame_Writer,
	lzma:       lzma.Writer,
	xz:         xz.Writer,
	block:      [BLOCK_SIZE]u8,
	records:    [dynamic]u8,
	name:       [dynamic]u8,
	chunk:      []u8,
	written:    i64,
	count:      i64,
	archive_in: i64,
	err:        Error,
	committed:  bool,
	active:     bool,
}

// Walks a `Reader`'s members, from `iterator_create`
Iterator :: struct {
	reader:   ^Reader,
	err:      Error,
	err_path: [dynamic]u8,
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
