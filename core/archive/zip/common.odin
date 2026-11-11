/*
Reads ZIP archives, as specified by [PKWARE's APPNOTE.TXT, version 6.3.10, November 2022](https://pkware.cachefly.net/webdocs/APPNOTE/APPNOTE-6.3.10.TXT).

- Opens archives from a path, a byte slice or a seekable `io.Stream`
- Lists members through `core:archive`'s shared iterator, and finds them by path
- Extracts one or more files
- Supported compression methods: Store, Shrink, Reduce, Implode, Deflate, Deflate64, bzip2, LZMA and PPMd; XZ planned
- ZIP64, data descriptors and self-extracting archives
- UTF-8, Info-ZIP Unicode and code page 437 names
- Unix and DOS attributes, symlinks, NTFS and Unix timestamps
- CRC-32 checked on extraction
- Safe to read from several threads at once
- WinZip AES and ZipCrypto decryption (planned)
- Split and spanned archives (planned)
- Streaming extraction for every method (planned)
- Opt-in progress callback (planned)
- Writing (planned)
- Copy-on-write updates, safe alongside concurrent readers (planned)
*/
package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/deflate"
import "core:io"
import "core:os"

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

// Record signatures, with their sections in APPNOTE v6.3.10.
Signature :: enum u32le {
	Local         = 0x04034b50, // 4.3.7:   local file header
	Central       = 0x02014b50, // 4.3.12:  central directory file header
	End           = 0x06054b50, // 4.3.16:  end of central directory record
	Zip64_End     = 0x06064b50, // 4.3.14:  zip64 end of central directory record
	Zip64_Locator = 0x07064b50, // 4.3.15:  zip64 end of central directory locator
	Descriptor    = 0x08074b50, // 4.3.9.3: data descriptor; 8.5.3: spanning signature
	Spanned       = 0x30304b50, // 8.5.4:   temporary spanning marker
}

END_SEARCH_MAX  :: size_of(End_Record) + 0xFFFF + size_of(Zip64_Locator)
COPY_CHUNK_SIZE :: 64 * 1024

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

ENCRYPTED_FLAGS :: Flags{.Encrypted, .Strong_Encryption, .Masked_Headers}

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

NTFS_EPOCH_DELTA :: 116_444_736_000_000_000

// As described in APPNOTE v6.3.10, section 4.3.7: local file header.
Local_Header :: struct #packed {
	signature:          Signature,
	version_needed:     u16le,
	flags:              Flags,
	method:             Method,
	dos_time:           u16le,
	dos_date:           u16le,
	crc32:              u32le,
	compressed_size:    u32le,
	uncompressed_size:  u32le,
	name_length:        u16le,
	extra_length:       u16le,
}
#assert(size_of(Local_Header) == 30)

// As described in APPNOTE v6.3.10, section 4.3.12: central directory file header.
Central_Header :: struct #packed {
	signature:           Signature,
	made_by_version:     u8,
	made_by_host:        Host,
	version_needed:      u16le,
	flags:               Flags,
	method:              Method,
	dos_time:            u16le,
	dos_date:            u16le,
	crc32:               u32le,
	compressed_size:     u32le,
	uncompressed_size:   u32le,
	name_length:         u16le,
	extra_length:        u16le,
	comment_length:      u16le,
	start_disk:          u16le,
	internal_attributes: u16le,
	external_attributes: u32le,
	local_header_offset: u32le,
}
#assert(size_of(Central_Header) == 46)

// As described in APPNOTE v6.3.10, section 4.3.16: end of central directory record.
End_Record :: struct #packed {
	signature:         Signature,
	disk:              u16le,
	central_disk:      u16le,
	entries_this_disk: u16le,
	entries_total:     u16le,
	central_size:      u32le,
	central_offset:    u32le,
	comment_length:    u16le,
}
#assert(size_of(End_Record) == 22)

// As described in APPNOTE v6.3.10, section 4.3.14: zip64 end of central directory record, version 1 (4.3.14.2), without its extensible data sector.
Zip64_End_Record :: struct #packed {
	signature:         Signature,
	record_size:       u64le,
	made_by_version:   u8,
	made_by_host:      Host,
	version_needed:    u16le,
	disk:              u32le,
	central_disk:      u32le,
	entries_this_disk: u64le,
	entries_total:     u64le,
	central_size:      u64le,
	central_offset:    u64le,
}
#assert(size_of(Zip64_End_Record) == 56)

// As described in APPNOTE v6.3.10, section 4.3.15: zip64 end of central directory locator.
Zip64_Locator :: struct #packed {
	signature:   Signature,
	disk:        u32le,
	end_offset:  u64le,
	total_disks: u32le,
}
#assert(size_of(Zip64_Locator) == 20)

Directory_End :: struct {
	end_offset:     i64,
	central_offset: i64,
	central_size:   i64,
	entry_count:    i64,
	zip64:          bool,
}

Entry :: struct {
	central:       Central_Header,
	local:         Local_Header,
	has_local:     bool,
	name:          []u8,
	central_extra: []u8,
	local_extra:   []u8,
	comment:       []u8,
	header_offset: i64,
	data_offset:   i64,
}

Record :: struct {
	central:         int,
	local_offset:    i64,
	compressed_size: i64,
	size:            i64,
	path:            int,
	path_length:     int,
	comment:         int,
	comment_length:  int,
}

Name_Index :: struct {
	path:  string,
	index: int,
}

Store :: struct {
	data:   []u8,
	stream: io.Stream,
	size:   i64,
	memory: bool,
}

Reader :: struct {
	allocator:   runtime.Allocator,
	options:     compress.Options,
	store:       Store,
	file:        ^os.File,
	directory:   []u8,
	owns_dir:    bool,
	records:     []Record,
	names:       []u8,
	index:       []Name_Index,
	comment:     string,
	raw_comment: []u8,
	base:        i64,
	zip64:       bool,
	generation:  u32,
}

Member_Mode :: enum u8 {
	Store,
	Inflate,
	Buffer,
}

Section :: struct {
	store:  ^Store,
	offset: i64,
	end:    i64,
}

Member :: struct {
	reader:    ^Reader,
	allocator: runtime.Allocator,
	mode:      Member_Mode,
	section:   Section,
	input:     []u8,
	ctx:       compress.Context,
	inflate:   deflate.Inflate_Reader,
	buffer:    [dynamic]u8,
	pos:       int,
	size:      i64,
	produced:  i64,
	crc:       u32,
	expected:  Maybe(u32),
	err:       Error,
	active:    bool,
	owned:     bool,
}

Iterator :: struct {
	reader:     ^Reader,
	index:      int,
	entry:      Entry,
	local_buf:  [dynamic]u8,
	member:     Member,
	err:        Error,
	err_path:   [dynamic]u8,
}

Check_Writer :: struct {
	w:     io.Writer,
	crc:   u32,
	count: i64,
}

@(rodata)
CP437_HIGH := [128]u16{
	0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7, 0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
	0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9, 0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A7, 0x0192,
	0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA, 0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
	0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556, 0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
	0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F, 0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
	0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B, 0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
	0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4, 0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
	0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248, 0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0,
}
