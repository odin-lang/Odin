/*
Reads archives of any registered format through one API, and extracts them safely.

Each format is its own package, `core:archive/zip`, `core:archive/sevenz` or `core:archive/tar`,
and registers itself here when imported. Writing and format-specific details go through those
packages.

Reading:
- `open` detects the format and opens an archive from a path, a byte slice or a seekable
  `io.Stream`, self-extracting zip and 7z archives included
- `iterator_create` and `iterate` list members in storage order; `find` looks one up by path
- Members are extracted to an `io.Writer` or streamed through an `io.Reader`
- `File_Info` describes a member the same way in every format

Extracting:
- `extract_all` and `extract_current_to_dir` write members below a directory; paths that escape
  it or cross a symlink are refused
- `extract_many` extracts members chosen by path to files, buffers or writers, in one pass
- `Extract_Options` caps the total size and the compression ratio
- On js only byte slices and streams are supported; the path procs are left out
*/
package archive

import "base:runtime"
import "core:compress"
import "core:io"
import "core:time"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

// An archive format; `which` detects the registered ones
Format :: enum u8 {
	Unknown,
	Tar,
	Zip,
	SevenZ,
}

// What kind of file system object a member is
Entry_Type :: enum u8 {
	Unknown,          // A type this package doesn't know
	Regular,
	Directory,
	Symlink,
	Hard_Link,
	Named_Pipe,
	Character_Device,
	Block_Device,
	Anti,             // A 7z anti-item: marks the path as deleted
}

// A compression method, named the same across formats
Method :: enum u16 {
	Unknown,   // Not listed here, see `File_Info.method_id`; in writer options, the format's default
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
	PPMd_H,    // PPMd variant H, as 7z uses it
	PPMd_I,    // PPMd variant I, revision 1, as zip uses it
	LZ4,
}

// A 7z filter applied before compression: delta, a branch converter (BCJ) or a byte swap
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

// The filters a member's data passes through
Filters :: bit_set[Filter; u16]

// Identifies a member for `extract` and `open_member`; take it from `File_Info.handle` or `find`
Handle :: struct {
	index:      int,
	generation: u32,
}

// A member's metadata, as `iterate` and `find` return it and `write_entry` takes it
File_Info :: struct {
	path:              string,      // In UTF-8, without a leading `./` or trailing `/`
	raw_path:          []u8,        // The path's bytes as stored, e.g. zip's CP437 or 7z's UTF-16
	link_target:       string,      // Set by tar; `read_link` reads a link's target in any format
	comment:           string,      // The member's comment (zip)

	type:              Entry_Type,
	size:              i64,         // Uncompressed size; writers take -1 for a reader of unknown size
	compressed_size:   i64,         // Stored size, -1 if unknown: compressed tar, solid 7z
	method:            Method,
	method_id:         u64,         // The format's own method: zip's method number, 7z's coder ID
	filters:           Filters,     // 7z filters applied before compression
	encrypted:         bool,
	supported:         bool,        // `false` if the method, encryption or entry type can't be read
	extended_metadata: bool,        // Has extra fields, pax records or a comment
	crc32:             Maybe(u32),  // The data's CRC-32, if the archive stores one

	unix_mode:         u32,         // Unix type and permission bits, see `UNIX_*`
	dos_attributes:    u32,         // DOS attribute bits, see `DOS_*`
	uid:               i64,
	gid:               i64,
	user:              string,
	group:             string,
	device:            [2]u32,      // A device node's major and minor numbers (tar)

	modification_time: time.Time,
	creation_time:     time.Time,   // Zero if not stored
	access_time:       time.Time,   // Zero if not stored

	handle:            Handle,      // Identifies the member for `extract` and `open_member`
}

// An archive's summary, from `info`
Archive_Info :: struct {
	format:       Format,
	member_count: int,     // -1 for tar until the end has been read
	comment:      string,  // The archive comment (zip) or volume label (tar)
	compression:  Method,  // tar's compression, or the method all 7z folders share, else `.Unknown`
}

// An archive of any registered format, from `open`
Archive :: struct {
	format:    Format,
	state:     rawptr,
	file:      io.Stream,  // The file `open_from_path` opened as a stream; `close` closes it
	allocator: runtime.Allocator,
}

// Walks an `Archive`'s members, from `iterator_create`
Iterator :: struct {
	archive: ^Archive,
	state:   rawptr,
	err:     Error,
}

// How to read members
Read_Options :: struct {
	password:            string,  // For encrypted members, and at 7z's open for an encrypted header
	max_key_derivations: int,     // 7z: caps a hostile archive's AES key derivations; 0 means 16
}

// Where an extracted target goes: a file path, a byte buffer or a writer
Target_Destination :: union {
	string,
	^[dynamic]u8,
	io.Writer,
}

// A member for `extract_many` to extract, and where to
Target :: struct {
	path:  string,              // The member's path, ignoring a leading `./` or trailing `/`
	to:    Target_Destination,
	found: bool,                // Set once a member matched
}

// How to extract members
Extract_Options :: struct {
	overwrite:      bool,    // Replace existing files
	last_wins:      bool,    // Extract every member with a target's path, so the last one wins
	max_total_size: i64,     // The most bytes to extract in all, 0 for no limit
	max_ratio:      int,     // The most a member may expand over its compressed size, 0 for no limit
	password:       string,  // For encrypted members
}

// Extracts targets in one pass over an archive, from `extract_iterator_create`
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

// Extracts members into a directory, from `extractor_create`
Extractor :: struct {
	options:   Extract_Options,
	path:      [dynamic]u8,
	root:      int,
	total:     i64,
	checked:   [dynamic]u8,
	allocator: runtime.Allocator,
}

// Errors any format can return
General_Error :: enum u32 {
	None,
	Unknown_Format,         // No registered format recognizes the data
	Not_Seekable,           // The stream can't seek or report its size
	Unsupported_Method,     // A compression, filter or encryption method this package can't handle
	Unsupported_Entry,      // An entry type the format or the operation can't handle
	Encrypted,              // The member is encrypted and no password was given
	Wrong_Password,         // The password check failed
	Authentication_Failed,  // The decrypted data failed its MAC check
	Unsafe_Path,            // The path is absolute, uses `..`, crosses a symlink or isn't valid here
	Not_Found,              // No member has the path, or the handle is stale
	Exists,                 // The path is already taken
	Skipped_Entry_Type,     // Extraction skipped a member of a type it doesn't extract
	Incompatible_Options,   // An option is out of range, or options conflict
	No_Current_Member,      // The iterator isn't on a member
	Limit_Exceeded,         // A size, ratio, link-target or key-derivation limit was hit
	Busy,                   // Another process holds the archive's lock
}

// tar errors
Tar_Error :: enum u32 {
	None,
	Invalid_Checksum,           // A header block's checksum doesn't match
	Invalid_Number,             // A numeric header field can't be parsed
	Invalid_Size,               // A member's size is negative or too large
	Truncated,                  // The archive ends inside a header or a member's data
	Invalid_Pax_Record,         // A pax extended header record is malformed
	Header_Too_Large,           // Long names or pax records exceed `HEADER_RECORD_MAX`
	Unsupported_GNU_Extension,  // A GNU multi-volume member, or sparse keys of an unknown version
	Invalid_Name,               // An empty name, or a NUL in a name or link target
	Size_Mismatch,              // A writer's reader didn't produce `File_Info.size` bytes
	Invalid_Sparse_Map,         // A sparse member's map is malformed
}

// zip errors
Zip_Error :: enum u32 {
	None,
	End_Not_Found,              // No end of central directory record
	Invalid_End,                // The end of central directory record is malformed
	Invalid_Zip64_End,          // The zip64 end record or its locator is malformed
	Invalid_Central_Directory,  // The central directory is malformed or its count is wrong
	Invalid_Local_Header,       // A local file header is malformed
	Invalid_Extra_Field,        // An extra field is malformed
	Split_Archive,              // The archive spans several disks
	CRC_Mismatch,               // The extracted data's CRC-32 doesn't match
	Size_Mismatch,              // A packed or unpacked size doesn't match the header or `File_Info.size`
	Truncated,                  // The archive ends inside a record or a member's data
	Invalid_Name,               // A name that can't be written
	Field_Too_Long,             // A name, comment or extra field is too long
	Too_Large,                  // A member outgrew 4 GiB without a zip64 local header
	Overlapping_Member,         // A member's data overlaps another member or the central directory
	Local_Header_Mismatch,      // A local header disagrees with its central directory entry
	Unsupported_Password,       // A password AES-256 writing can't use: not ASCII, or over 99 bytes
}

// 7z errors
SevenZ_Error :: enum u32 {
	None,
	Invalid_Signature,    // No 7z signature header at the start, nor behind an executable's stub
	Unsupported_Version,  // The major version isn't 0
	Header_CRC_Mismatch,  // The start or next header's CRC-32 doesn't match
	Invalid_Header,       // The header is malformed
	Header_Too_Large,     // The header exceeds `HEADER_SIZE_MAX` or the memory limit
	Header_Too_Deep,      // Encoded headers nest deeper than `HEADER_DEPTH_MAX`
	Invalid_Folder,       // A folder's coders, bindings or streams are malformed
	Truncated,            // The archive ends inside a header or packed stream
	Size_Mismatch,        // A packed or unpacked size doesn't match the header or `File_Info.size`
	CRC_Mismatch,         // The extracted data's CRC-32 doesn't match
	Invalid_Name,         // A name that can't be written
}

// Any error from this package or the format packages
Error :: union #shared_nil {
	General_Error,
	Tar_Error,
	Zip_Error,
	SevenZ_Error,
	compress.Error,
	io.Error,
	OS_Error,
	runtime.Allocator_Error,
}

// How many leading bytes `which` looks at
DETECT_HEAD_SIZE :: 1024

// The longest symlink target, in bytes, that zip and 7z read and write
LINK_TARGET_MAX :: 4096

// Unix file type and permission bits, as in `File_Info.unix_mode`
UNIX_TYPE_MASK        :: 0o170000
UNIX_NAMED_PIPE       :: 0o010000
UNIX_CHARACTER_DEVICE :: 0o020000
UNIX_DIRECTORY        :: 0o040000
UNIX_BLOCK_DEVICE     :: 0o060000
UNIX_REGULAR          :: 0o100000
UNIX_SYMLINK          :: 0o120000
UNIX_PERMISSION_MASK  :: 0o7777

// DOS attribute bits, as in `File_Info.dos_attributes`
DOS_READ_ONLY :: 0x01
DOS_DIRECTORY :: 0x10
DOS_ARCHIVE   :: 0x20

@(private)
_procs: [Format]Format_Procs

@(private)
_registered: [Format]bool

@(private)
_detect_order := [?]Format{.SevenZ, .Zip, .Tar}

@(private)
Source :: union {
	string,
	[]u8,
	io.Stream,
}

@(private)
_read_head :: proc(s: io.Stream, head: []u8) -> (n: int, err: Error) {
	start, seek_err := io.seek(s, 0, .Current)
	if seek_err != nil {
		return 0, General_Error.Not_Seekable
	}
	read_err: io.Error
	n, read_err = io.read_full(s, head)
	if n == 0 && read_err != nil && read_err != .EOF {
		return 0, read_err
	}
	if _, seek_err = io.seek(s, start, .Start); seek_err != nil {
		return 0, General_Error.Not_Seekable
	}
	return n, nil
}

@(private)
_open_detected :: proc(a: ^Archive, head: []u8, source: Source, options: compress.Options, read_options: Read_Options) -> (err: Error) {
	if format := which(head); format != .Unknown {
		return _open_as(a, format, source, options, read_options)
	}
	err = General_Error.Unknown_Format
	if _registered[.Zip] {
		if err = _open_as(a, .Zip, source, options, read_options); err == Zip_Error.End_Not_Found {
			a.format = .Unknown
			err = General_Error.Unknown_Format
		}
	}
	if err != nil && _registered[.SevenZ] {
		format := a.format
		if sevenz_err := _open_as(a, .SevenZ, source, options, read_options); sevenz_err != SevenZ_Error.Invalid_Signature {
			return sevenz_err
		}
		a.format = format
	}
	return
}

@(private)
_open_as :: proc(a: ^Archive, format: Format, source: Source, options: compress.Options, read_options: Read_Options) -> (err: Error) {
	a.format = format
	switch s in source {
	case string:    err = _procs[format].open_path(a, s, options, read_options)
	case []u8:      err = _procs[format].open_bytes(a, s, options, read_options)
	case io.Stream: err = _procs[format].open_stream(a, s, options, read_options)
	}
	return
}

@(private)
_check_limits :: proc(options: Extract_Options, total: i64, fi: File_Info) -> (err: Error) {
	if options.max_total_size <= 0 && options.max_ratio <= 0 {
		return nil
	}
	if fi.size < 0 {
		return General_Error.Limit_Exceeded
	}
	if options.max_ratio > 0 && fi.compressed_size >= 0 && fi.size > 0 && (fi.size - 1) / i64(options.max_ratio) >= fi.compressed_size {
		return General_Error.Limit_Exceeded
	}
	if options.max_total_size > 0 && fi.size > options.max_total_size - total {
		return General_Error.Limit_Exceeded
	}
	return nil
}

@(private)
_is_separator :: proc "contextless" (c: u8, windows: bool) -> bool {
	return c == '/' || (windows && c == '\\')
}
