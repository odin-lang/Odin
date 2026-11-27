/*
Reads, writes and updates ZIP archives, as specified by version 6.3.10 (November 2022) of
[PKWARE's APPNOTE.TXT](https://pkware.cachefly.net/webdocs/APPNOTE/APPNOTE-6.3.10.TXT).

`open` reads an archive from a path, a byte slice or a seekable `io.Stream`, self-extracting
ones included. `create` starts a new archive at a path or on an `io.Stream`, `write_entry` adds
a member from a byte slice or an `io.Reader`, `write_directory` adds a whole tree, and `commit`
finishes the archive. `update` appends members to an existing archive in place; at a path,
`remove_entry` and `rename_entry` rewrite it. `close` releases a reader or a writer. A crash
during an update at a path leaves the last committed archive, or the one before. At a path,
readers take a shared lock and writers an exclusive one, except on wasi.

Members are read through an iterator: `iterator_create` walks them in storage order, `iterate`
gives each one's `archive.File_Info`, and `extract_current` unpacks it to an `io.Writer`, or
`open_current` streams it through an `io.Reader`. `find` looks a member up by path for
`extract` or `open_member`, and `core:archive`'s `extract_all` unpacks a whole archive below a
directory. Extraction checks each member's CRC-32, and several threads can read one archive at
once.

Reading decodes Store, Shrink, Reduce, Implode, Deflate, Deflate64, bzip2, LZMA, PPMd and XZ.
Writing encodes Store, Deflate, Deflate64, bzip2, LZMA, PPMd and XZ, and falls back to Store
when compressing doesn't pay. Reading decrypts ZipCrypto and WinZip AES (AE-1 and AE-2, with
128, 192 or 256-bit keys), with the password from `archive.Read_Options`, and checks the MAC;
writing encrypts with WinZip AES-256 (AE-2).

ZIP64 and data descriptors are used where needed. Names are read as UTF-8, Info-ZIP Unicode or
code page 437, and written as UTF-8. Unix and DOS attributes, symlinks, NTFS and Unix
timestamps, and comments are read and written; DOS times are taken as local time.

Reading and writing take an optional progress callback, for a UI's progress bar, which can also
cancel. A deterministic mode writes reproducible archives.

Planned: copy-on-write updates, safe alongside concurrent readers.

Not supported: archives split over several disks, PKWARE's strong encryption and masked
headers, and methods beyond those above, such as Zstandard. Shrink, Reduce, Implode and
ZipCrypto are read but never written. On js, only byte slices and streams work.
*/
package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:io"
import "core:time/datetime"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Format: PKWARE's APPNOTE.TXT, version 6.3.10:
		https://pkware.cachefly.net/webdocs/APPNOTE/APPNOTE-6.3.10.TXT
*/

Error     :: archive.Error
Zip_Error :: archive.Zip_Error

// Members up to this size are compressed in one call; a reader of known size is read in first
ONE_SHOT_MAX :: i64(#config(ZIP_ONE_SHOT_MAX, 256 * 1024))

// Longest zip AES password 7-Zip accepts, in bytes
AES_PASSWORD_MAX :: 99

// General purpose bit flags, APPNOTE v6.3.10 section 4.4.4: bits 1 and 2 depend on the method.
Flag :: enum u16 {
	Encrypted            = 0,
	Option_1             = 1,
	Option_2             = 2,
	Data_Descriptor      = 3,
	Enhanced_Deflate     = 4,
	Patched              = 5,
	Strong_Encryption    = 6,
	UTF8                 = 11,
	Enhanced_Compression = 12,
	Masked_Headers       = 13,
	Alternate_Streams    = 14,
}
Flags :: bit_set[Flag; u16le]

// Extra field header IDs, APPNOTE v6.3.10 sections 4.5.2 and 4.6.1.
Extra_ID :: enum u16 {
	Zip64        = 0x0001, // 4.5.3
	NTFS         = 0x000a, // 4.5.5
	Timestamp    = 0x5455, // 4.6.1; Info-ZIP's extrafld.txt
	Infozip_Unix = 0x5855, // 4.6.1; Info-ZIP's extrafld.txt
	Unicode_Path = 0x7075, // 4.6.9
	Unix         = 0x7875, // 4.6.1; Info-ZIP's extrafld.txt
	AES          = 0x9901, // 4.6.1 and APPENDIX E
}

// Hosts in "version made by", APPNOTE v6.3.10 section 4.4.2.2.
Host :: enum u8 {
	MS_DOS        = 0,
	Amiga         = 1,
	OpenVMS       = 2,
	Unix          = 3,
	VM_CMS        = 4,
	Atari_ST      = 5,
	OS2_HPFS      = 6,
	Macintosh     = 7,
	Z_System      = 8,
	CPM           = 9,
	NTFS          = 10,
	MVS           = 11,
	VSE           = 12,
	Acorn_RISC    = 13,
	VFAT          = 14,
	Alternate_MVS = 15,
	BeOS          = 16,
	Tandem        = 17,
	OS400         = 18,
	Darwin        = 19,
}

// Compression methods, listed in APPNOTE v6.3.10 section 4.4.5 and described in section 5.
Method :: enum u16le {
	Store                = 0,  // 4.4.5
	Shrink               = 1,  // 5.1
	Reduce_1             = 2,  // 5.2: methods 2-5 are compression factors 1-4
	Reduce_2             = 3,  // 5.2
	Reduce_3             = 4,  // 5.2
	Reduce_4             = 5,  // 5.2
	Implode              = 6,  // 5.3
	Tokenize             = 7,  // 5.4:  reserved
	Deflate              = 8,  // 5.5
	Deflate64            = 9,  // 5.6
	DCL_Implode          = 10, // 4.4.5: PKWARE Data Compression Library Imploding
	BZip2                = 12, // 5.7
	LZMA                 = 14, // 5.8
	IBM_CMPSC            = 16, // 5.17
	IBM_TERSE            = 18, // 4.4.5
	IBM_LZ77             = 19, // 4.4.5
	Zstandard_Deprecated = 20, // 4.4.5: use method 93
	Zstandard            = 93, // 4.4.5
	MP3                  = 94, // 4.4.5
	XZ                   = 95, // 4.4.5
	JPEG                 = 96, // 4.4.5
	WavPack              = 97, // 5.9
	PPMd                 = 98, // 5.10: PPMd version I, revision 1
	AES                  = 99, // 5.11 and APPENDIX E: AE-x encryption marker
}

// A member's format details, from `current_entry`; walk the extra fields with `next_extra`
Entry :: struct {
	flags:         Flags,            // The general purpose bit flags
	method:        Method,           // The method as stored; `.AES` for a WinZip AES member
	host:          Host,             // The host system in "version made by"
	has_local:     bool,             // `false` if the local header couldn't be read or doesn't match
	name:          []u8,             // The name's bytes, as stored
	central_extra: []u8,             // The central header's extra fields
	local_extra:   []u8,             // The local header's extra fields; empty without `has_local`
	comment:       []u8,             // The comment's bytes, as stored
	header_offset: i64,              // Where the local header starts
	data_offset:   i64,              // Where the data starts, -1 without `has_local`
}

// Reads a zip archive, from `open`
Reader :: struct {
	allocator:   runtime.Allocator,
	options:     compress.Options,
	store:       Store,
	file:        io.Stream,
	directory:   []u8,
	owns_dir:    bool,
	records:     []Record,
	order:       []int,
	names:       []u8,
	index:       []Name_Index,
	comment:     string,
	raw_comment: []u8,
	base:        i64,
	dir_start:   i64,
	zip64:       bool,
	generation:  u32,
	zone:        ^datetime.TZ_Region,
}

// Walks a `Reader`'s members, from `iterator_create`
Iterator :: struct {
	reader:     ^Reader,
	position:   int,
	index:      int,
	entry:      Entry,
	local_buf:  [dynamic]u8,
	member:     Member,
}

// A regular file's data, for `write_entry`
Entry_Data :: union {
	[]u8,
	io.Reader,
}

// One member's settings; all but `replace` stand in for the `Writer_Options` defaults
Entry_Options :: struct {
	method:   archive.Method,  // `.Unknown` for the writer's
	level:    Maybe(int),      // `nil`: the writer's for its method, else the default
	password: Maybe(string),   // `nil` for the writer's, `""` for none
	replace:  bool,
}

// A writer's settings; the methods are Store, Deflate, Deflate64, BZip2, LZMA, XZ and PPMd_I
Writer_Options :: struct {
	method:        archive.Method,    // `.Unknown` for Deflate
	level:         Maybe(int),        // `nil` for the method's default; clamped
	deterministic: bool,              // Reproducible: fixed times, sorted `write_directory`
	comment:       string,            // The archive comment, at most 65535 bytes
	password:      string,            // Encrypts members with AES-256 (AE-2); not `deterministic`
	no_sync:       bool,
	options:       compress.Options,  // Limits and progress callback for the encoders
}

// Writes or updates a zip archive, from `create` or `update`
Writer :: struct {
	allocator:     runtime.Allocator,
	options:       Writer_Options,
	mode:          Writer_Mode,
	stream:        io.Stream,
	disk:          archive.Disk,
	seekable:      bool,
	offset:        i64,
	end:           i64,
	base:          i64,
	count:         i64,
	archive_in:    i64,
	central:       [dynamic]u8,
	header:        [dynamic]u8,
	name:          [dynamic]u8,
	chunk:         []u8,
	cipher_buffer: []u8,
	password:      string,
	err:           Error,
	committed:     bool,
	active:        bool,
	zone:          ^datetime.TZ_Region,
	old:           Reader,
	old_length:    i64,
	old_count:     i64,
	slots:         [dynamic]Update_Slot,
	heads:         map[string]int,
	journaled:     bool,
	modified:      bool,
	comment_set:   bool,
}

/*
Splits the next extra field off a header's extra data

Inputs:
- extra: The extra data, such as `Entry.central_extra`; advanced past the field

Returns:
- id: The field's header ID
- data: The field's data, a slice of `extra`
- ok: `false` at the end, or if the next field is cut short
*/
next_extra :: proc "contextless" (extra: ^[]u8) -> (id: Extra_ID, data: []u8, ok: bool) {
	e := extra^
	if len(e) < 4 {
		return
	}
	size := int(_u16(e, 2))
	if 4 + size > len(e) {
		return
	}
	id     = Extra_ID(_u16(e, 0))
	data   = e[4:][:size]
	extra^ = e[4 + size:]
	return id, data, true
}

@(private)
_read_at_full :: proc(s: io.Stream, p: []u8, offset: i64) -> (err: Error) {
	_, read_err := io.read_full_at(s, p, offset)
	if read_err == .EOF || read_err == .Unexpected_EOF {
		return Zip_Error.Truncated
	}
	if read_err != nil {
		return read_err
	}
	return nil
}
