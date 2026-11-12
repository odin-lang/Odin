package archive

import "base:runtime"
import "core:compress"
import "core:io"
import "core:os"
import "core:time"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

Format :: enum u8 {
	Unknown,
	Tar,
	Zip,
	SevenZ,
}

Entry_Type :: enum u8 {
	Unknown,
	Regular,
	Directory,
	Symlink,
	Hard_Link,
	Named_Pipe,
	Character_Device,
	Block_Device,
	Anti,
}

Method :: enum u16 {
	Unknown,
	Store,
	Shrink,
	Reduce,
	Implode,
	Deflate,
	Deflate64,
	BZip2,
	LZMA,
	LZMA2,
	XZ,
	PPMd_H,
	PPMd_I,
	LZ4,
}

Filter :: enum u8 {
	Delta,
	BCJ_X86,
	BCJ_PPC,
	BCJ_IA64,
	BCJ_ARM,
	BCJ_ARMT,
	BCJ_SPARC,
	BCJ_ARM64,
	BCJ_RISCV,
	BCJ2,
	Swap2,
	Swap4,
}

Filters :: bit_set[Filter; u16]

Handle :: struct {
	index:      int,
	generation: u32,
}

File_Info :: struct {
	path:              string,
	raw_path:          []u8,
	link_target:       string,
	comment:           string,

	type:              Entry_Type,
	size:              i64,
	compressed_size:   i64,
	method:            Method,
	method_id:         u64,
	filters:           Filters,
	encrypted:         bool,
	supported:         bool,
	extended_metadata: bool,
	crc32:             Maybe(u32),

	unix_mode:         u32,
	dos_attributes:    u32,
	uid:               i64,
	gid:               i64,
	user:              string,
	group:             string,
	device:            [2]u32,

	modification_time: time.Time,
	creation_time:     time.Time,
	access_time:       time.Time,

	handle:            Handle,
}

Archive_Info :: struct {
	format:       Format,
	member_count: int,
	comment:      string,
	compression:  Method,
}

Archive :: struct {
	format:    Format,
	state:     rawptr,
	file:      ^os.File,
	allocator: runtime.Allocator,
}

Iterator :: struct {
	archive: ^Archive,
	state:   rawptr,
	err:     Error,
}

Format_Procs :: struct {
	detect:           proc(head: []u8) -> bool,
	open_bytes:       proc(a: ^Archive, data: []u8, options: compress.Options) -> Error,
	open_stream:      proc(a: ^Archive, s: io.Stream, options: compress.Options) -> Error,
	close:            proc(a: ^Archive),
	info:             proc(a: ^Archive) -> Archive_Info,
	iterator_create:  proc(it: ^Iterator) -> Error,
	iterator_destroy: proc(it: ^Iterator),
	iterate:          proc(it: ^Iterator) -> (fi: File_Info, index: int, ok: bool),
	iterator_error:   proc(it: ^Iterator) -> (path: string, err: Error),
	extract_current:  proc(it: ^Iterator, w: io.Writer, options: Read_Options) -> Error,
	open_current:     proc(it: ^Iterator, options: Read_Options) -> (r: io.Reader, err: Error),
	read_link:        proc(it: ^Iterator, allocator: runtime.Allocator) -> (target: string, err: Error),
	find:             proc(a: ^Archive, path: string) -> (fi: File_Info, handle: Handle, ok: bool, err: Error),
	extract:          proc(a: ^Archive, handle: Handle, w: io.Writer, options: Read_Options) -> Error,
	open_member:      proc(a: ^Archive, handle: Handle, options: Read_Options) -> (r: io.Reader, err: Error),
}

Read_Options :: struct {
	password: string,
}

Target_Destination :: union {
	string,
	^[dynamic]u8,
	io.Writer,
}

Target :: struct {
	path:  string,
	to:    Target_Destination,
	found: bool,
}

Extract_Options :: struct {
	overwrite:      bool,
	last_wins:      bool,
	max_total_size: i64,
	max_ratio:      int,
	password:       string,
}

Extract_Iterator :: struct {
	archive:   ^Archive,
	it:        Iterator,
	targets:   []Target,
	options:   Extract_Options,
	found:     int,
	total:     i64,
	done:      bool,
	err:       Error,
	err_path:  [dynamic]u8,
	last_err:  Error,
	last_path: [dynamic]u8,
	allocator: runtime.Allocator,
}

Extractor :: struct {
	options:   Extract_Options,
	path:      [dynamic]u8,
	root:      int,
	total:     i64,
	checked:   [dynamic]u8,
	allocator: runtime.Allocator,
}

General_Error :: enum u32 {
	None,
	Unknown_Format,
	Not_Seekable,
	Unsupported_Method,
	Unsupported_Entry,
	Encrypted,
	Wrong_Password,
	Authentication_Failed,
	Unsafe_Path,
	Not_Found,
	Exists,
	Skipped_Entry_Type,
	Incompatible_Options,
	No_Current_Member,
	Limit_Exceeded,
}

Tar_Error :: enum u32 {
	None,
	Invalid_Checksum,
	Invalid_Number,
	Invalid_Size,
	Truncated,
	Invalid_Pax_Record,
	Header_Too_Large,
	Unsupported_GNU_Extension,
	Invalid_Name,
	Size_Mismatch,
}

Zip_Error :: enum u32 {
	None,
	End_Not_Found,
	Invalid_End,
	Invalid_Zip64_End,
	Invalid_Central_Directory,
	Invalid_Local_Header,
	Invalid_Extra_Field,
	Split_Archive,
	CRC_Mismatch,
	Size_Mismatch,
	Truncated,
	Invalid_Name,
	Field_Too_Long,
	Too_Large,
	Overlapping_Member,
	Local_Header_Mismatch,
}

Error :: union #shared_nil {
	General_Error,
	Tar_Error,
	Zip_Error,
	compress.Error,
	io.Error,
	os.Error,
	runtime.Allocator_Error,
}

DETECT_HEAD_SIZE :: 1024

UNIX_TYPE_MASK        :: 0o170000
UNIX_NAMED_PIPE       :: 0o010000
UNIX_CHARACTER_DEVICE :: 0o020000
UNIX_DIRECTORY        :: 0o040000
UNIX_BLOCK_DEVICE     :: 0o060000
UNIX_REGULAR          :: 0o100000
UNIX_SYMLINK          :: 0o120000
UNIX_PERMISSION_MASK  :: 0o7777

DOS_READ_ONLY :: 0x01
DOS_DIRECTORY :: 0x10
DOS_ARCHIVE   :: 0x20

@(private)
_procs: [Format]Format_Procs

@(private)
_registered: [Format]bool

@(private)
_detect_order := [?]Format{.SevenZ, .Zip, .Tar}
