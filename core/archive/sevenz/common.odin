/*
Reads, writes and updates 7z archives, as described by `DOC/7zFormat.txt` in Igor Pavlov's
public domain [LZMA SDK](https://www.7-zip.org/sdk.html).

`open` reads an archive from a path, a byte slice or a seekable `io.Stream`, also behind the stub
of a self-extracting executable (MZ, ELF or Mach-O) when the archive starts in its first
`SFX_SEARCH_MAX` bytes; `update`, `remove_entry` and `rename_entry` keep the stub. `create` starts
a new archive at a path or on a seekable `io.Stream`, `write_entry` adds a member from a byte
slice or an `io.Reader`, `write_directory` adds a whole tree, and `commit` finishes the
archive. `update` appends members to an existing archive in place, and `write_anti_item` marks
a path as deleted; at a path, `remove_entry` and `rename_entry` rewrite it, re-encoding a solid
folder that loses only some of its members. `close` releases a reader or a writer. A crash
during an update at a path leaves the last committed archive. At a path, readers take a shared
lock and writers an exclusive one, except on wasi.

Members are read through an iterator: `iterator_create` walks them in storage order, which
decodes each solid folder only once, `iterate` gives each one's `archive.File_Info`, and
`extract_current` unpacks it to an `io.Writer`, or `open_current` streams it through an
`io.Reader`. `find` looks a member up by path for `extract` or `open_member`, and
`core:archive`'s `extract_all` unpacks a whole archive below a directory. Extraction checks each
member's CRC-32.

The methods are Copy, LZMA, LZMA2 (the writer's default), PPMd, Deflate, Deflate64 and bzip2,
and the filters Delta, BCJ (x86, PowerPC, IA-64, ARM, ARM Thumb, SPARC, ARM64 and RISC-V),
BCJ2, Swap2 and Swap4. The writer picks a filter from the data unless told otherwise, and can
pack members into solid folders, capped by size and member count and ordered by name or
extension. Encryption is 7-Zip's AES-256, which also covers the header unless
`unencrypted_header` is set; `archive.Read_Options` takes the password and caps the key
derivations per reader. Written headers are compressed unless `plain_header` is set.

Reading and writing take an optional progress callback, for a UI's progress bar, which can also
cancel. A deterministic mode writes reproducible archives.

Not supported: writing new self-extracting archives, reading or writing multi-volume archives,
and methods beyond those above, such as the Zstandard and LZ4 of 7-Zip's forks. On js, only byte
slices and streams work.
*/
package archive_sevenz

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:io"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Format: `DOC/7zFormat.txt` and `DOC/Methods.txt` in Igor Pavlov's public domain LZMA SDK:
		https://www.7-zip.org/sdk.html
*/

Error        :: archive.Error
SevenZ_Error :: archive.SevenZ_Error

// The largest header a reader decodes, in bytes; the decoders' memory limit may lower it
HEADER_SIZE_MAX   :: i64(#config(SEVENZ_HEADER_SIZE_MAX, 1 << 30))
HEADER_DEPTH_MAX  :: 4
SFX_SEARCH_MAX    :: i64(#config(SEVENZ_SFX_SEARCH_MAX, 4 << 20))
UNIX_EXTENSION    :: 0x8000
// The largest key-derivation power read or written: 2^24 SHA-256 rounds
AES_POWER_MAX     :: 24
// The key-derivation power written when `Writer_Options.kdf_power` is 0, as 7-Zip does
AES_POWER_DEFAULT :: 19
// How many key derivations a reader allows when `Read_Options.max_key_derivations` is 0
KDF_LIMIT_DEFAULT :: 16
// An update at a path with a larger old header rewrites the archive instead of appending in place
UPDATE_SAVED_MAX  :: 64 << 20

// A member's record in the archive header, from `current_entry`
Entry :: struct {
	path:              string,       // The name, converted from UTF-16 to UTF-8
	raw_path:          []u8,         // The name's UTF-16LE bytes as stored, without the terminator
	size:              i64,          // The data's size once unpacked, in bytes
	crc:               Maybe(u32),   // The data's CRC-32, if stored
	folder:            int,          // The folder (block) holding the data, -1 without data
	folder_offset:     i64,          // Where the data starts in the folder's decoded output
	has_stream:        bool,         // `false` for a directory, an empty file or an anti-item
	is_directory:      bool,         // `true` for a directory
	is_anti:           bool,         // An anti-item: applied as an update, it deletes `path`
	attributes:        Maybe(u32),   // DOS attributes; with `UNIX_EXTENSION`, the Unix mode << 16
	creation_time:     Maybe(u64),   // Windows FILETIME, as are the other times
	access_time:       Maybe(u64),   // The last access, if stored
	modification_time: Maybe(u64),   // The last change, if stored
	start_position:    Maybe(u64),   // Read but not used
}

// Reads a 7z archive, from `open`
Reader :: struct {
	allocator:    runtime.Allocator,
	options:      compress.Options,
	store:        Store,
	base:         i64,
	file:         io.Stream,
	journal:      []archive.Range,
	header:       []u8,
	owns_header:  bool,
	header_start: i64,
	streams:      Streams,
	items:        []Entry,
	names:        []u8,
	index:        []Name_Index,
	generation:   u32,
	password:     string,
	keys:         Key_Cache,
}

// Walks a `Reader`'s members, from `iterator_create`
Iterator :: struct {
	reader:   ^Reader,
	index:    int,
	decoder:  Folder_Decoder,
	member:   Member,
}

// The filter a writer applies before compression
Filter_Choice :: enum u8 {
	Auto,       // Picked from the data; x86 code may get BCJ2. In `Entry_Options`: the writer's
	None,
	Delta,      // Byte-wise delta, over `delta_distance` bytes
	BCJ_X86,
	BCJ_PPC,
	BCJ_IA64,
	BCJ_ARM,
	BCJ_ARMT,
	BCJ_SPARC,
	BCJ_ARM64,
	BCJ_RISCV,
	BCJ2,       // x86 branch converter with four streams
	Swap2,      // Swaps the bytes of each 16-bit word
	Swap4,      // Reverses the bytes of each 32-bit word
}

// How `write_directory` orders the files in solid mode, after grouping them by filter
Solid_Order :: enum u8 {
	Name,       // By path
	Extension,  // By kind of extension, as 7-Zip does, then by path
}

// A regular file's data, for `write_entry`
Entry_Data :: union {
	[]u8,
	io.Reader,
}

// One member's settings; all but `replace` stand in for the `Writer_Options` defaults
Entry_Options :: struct {
	method:         archive.Method,          // `.Unknown` for the writer's
	level:          Maybe(int),              // `nil`: the writer's for its method, else the default
	filter:         Filter_Choice,           // `.Auto` for the writer's filter and distance
	delta_distance: int,                     // 1 to 256, for `.Delta`; 0 means 1
	lzma:           Maybe(lzma.Options),     // LZMA and LZMA2 settings in place of the level's
	ppmd:           Maybe(ppmd.Properties),  // PPMd settings in place of the level's; variant H
	password:       Maybe(string),           // `nil` for the writer's, `""` for none
	replace:        bool,
}

// A writer's settings; the methods are Store, LZMA, LZMA2, PPMd_H, BZip2, Deflate and Deflate64
Writer_Options :: struct {
	method:             archive.Method,          // `.Unknown` for LZMA2
	level:              Maybe(int),              // `nil` for the method's default; clamped
	filter:             Filter_Choice,
	delta_distance:     int,                     // 1 to 256, for `.Delta`; 0 means 1
	lzma:               Maybe(lzma.Options),     // LZMA and LZMA2 settings in place of the level's
	ppmd:               Maybe(ppmd.Properties),  // PPMd settings in place of the level's; variant H
	solid:              bool,                    // Compresses like-set members together in blocks
	solid_size:         i64,                     // A block's data limit; 0 picks one by method
	solid_files:        int,                     // A block's member limit; 0 for none
	solid_order:        Solid_Order,
	creation_time:      bool,                    // Stores creation times
	access_time:        bool,                    // Stores access times
	plain_header:       bool,                    // Leaves the header uncompressed, if not encrypted
	deterministic:      bool,                    // Reproducible: no times, sorted `write_directory`
	password:           string,                  // AES-256, members and header; not `deterministic`
	kdf_power:          int,                     // 2^`kdf_power` SHA-256 rounds per key; 0 means 19
	unencrypted_header: bool,                    // With a password, keeps the header's paths readable
	no_sync:            bool,
	options:            compress.Options,        // Limits and progress callback for the encoders
}

// Writes or updates a 7z archive, from `create` or `update`
Writer :: struct {
	allocator:     runtime.Allocator,
	options:       Writer_Options,
	stream:        io.Stream,
	disk:          archive.Disk,
	start:         i64,
	offset:        i64,
	end:           i64,
	pack_sizes:    [dynamic]i64,
	folders:       [dynamic]Out_Folder,
	files:         [dynamic]Out_File,
	names:         [dynamic]u8,
	name:          [dynamic]u8,
	header:        [dynamic]u8,
	chunk:         []u8,
	head:          []u8,
	filter_buffer: []u8,
	cipher_buffer: []u8,
	folder:        Open_Folder,
	password:      string,
	kdf_power:     int,
	salt:          [AES_SALT_MAX]u8,
	salted:        bool,
	keys:          Key_Cache,
	ciphers:       [dynamic]Out_Cipher,
	archive_in:    i64,
	err:           Error,
	committed:     bool,
	active:        bool,
	mode:          Writer_Mode,
	pack_pos:      i64,
	old:           Reader,
	old_length:    i64,
	data_start:    i64,
	saved:         []archive.Range,
	kept:          [dynamic]int,
	slots:         [dynamic]Update_Slot,
	heads:         map[string]int,
	guard:         bool,
	journaled:     bool,
	modified:      bool,
	must_rewrite:  bool,
	repacking:     bool,
}

@(private)
_read_at_full :: proc(s: io.Stream, p: []u8, offset: i64) -> (err: Error) {
	_, read_err := io.read_full_at(s, p, offset)
	if read_err == .EOF || read_err == .Unexpected_EOF {
		return SevenZ_Error.Truncated
	}
	if read_err != nil {
		return read_err
	}
	return nil
}
