#+private
package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lzma"
import legacy "core:compress/pkzip-legacy"
import "core:compress/ppmd"
import "core:compress/xz"
import "core:crypto/aes"
import "core:crypto/hmac"
import "core:io"

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

WRITE_CHUNK_SIZE  :: 256 * 1024
ZIP16_MAX         :: 0xFFFF
ZIP32_MAX         :: 0xFFFF_FFFF
ZIP64_LOCAL_LIMIT :: 0xF000_0000
MADE_BY_VERSION   :: 63

AES_VERSION        :: 2
AES_STRENGTH       :: 3
AES_SALT_SIZE      :: aes.KEY_SIZE_256 / 2
AES_OVERHEAD       :: AES_SALT_SIZE + AES_VERIFIER_SIZE + AES_MAC_SIZE
AES_VERSION_NEEDED :: 51
AES_CTR_IV         :: [aes.CTR_IV_SIZE]u8{0 = 1}

ZIPCRYPTO_HEADER_SIZE :: 12
AES_EXTRA_SIZE        :: 7
AES_VERIFIER_SIZE     :: 2
AES_MAC_SIZE          :: 10
AES_ITERATIONS        :: 1000

CIPHER_BUFFER_SIZE :: 64 * 1024
DOS_EPOCH          :: 315_532_800
LZMA_SDK_VERSION   :: [2]u8{19, 0}
NTFS_EPOCH_DELTA   :: 116_444_736_000_000_000

ENCRYPTED_FLAGS :: Flags{.Encrypted, .Strong_Encryption, .Masked_Headers}

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
	records_offset: i64,
	central_offset: i64,
	central_size:   i64,
	entry_count:    i64,
	zip64:          bool,
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
	end:             i64,
}

Name_Index :: struct {
	path:     string,
	position: int,
}

Member_Span :: struct {
	offset: i64,
	index:  int,
}

Store :: struct {
	data:   []u8,
	stream: io.Stream,
	size:   i64,
	memory: bool,
}

Member_Mode :: enum u8 {
	Store,
	Inflate,
	BZip2,
	PPMd,
	LZMA,
	XZ,
	Legacy,
}

Read_Progress :: struct {
	reader:      ^Reader,
	index:       int,
	head:        i64,
	data_offset: i64,
	next:        i64,
}

Section :: struct {
	store:  ^Store,
	offset: i64,
	end:    i64,
	cipher: ^Cipher,
}

Member :: struct {
	reader:    ^Reader,
	allocator: runtime.Allocator,
	mode:      Member_Mode,
	section:   Section,
	input:     []u8,
	ctx:       compress.Context,
	inflate:   deflate.Reader,
	bzip2:     bzip2.Reader,
	ppmd:      ppmd.Reader,
	lzma:      lzma.Reader,
	xz:        xz.Reader,
	legacy:    legacy.Reader,
	progress:  Read_Progress,
	cipher:    Cipher,
	size:      i64,
	produced:  i64,
	crc:       u32,
	expected:  Maybe(u32),
	err:       Error,
	active:    bool,
	owned:     bool,
}

Check_Writer :: struct {
	w:     io.Writer,
	crc:   u32,
	count: i64,
	limit: i64,
	over:  bool,
}

Writer_Mode :: enum u8 {
	Stream,
	Create_Path,
	Update_Stream,
	Update_Path,
}

Update_Slot :: struct {
	central:   int,
	record:    int,
	header:    i64,
	data_end:  i64,
	raw_name:  []u8,
	name:      string,
	next:      int,
	old:       bool,
	renamed:   bool,
	removed:   bool,
	directory: bool,
}

Pending_Entry :: struct {
	name:          []u8,
	comment:       string,
	link_target:   string,
	type:          archive.Entry_Type,
	method:        Method,
	level:         int,
	flags:         Flags,
	utf8:          bool,
	external:      u32,
	dos_time:      u16,
	dos_date:      u16,
	unix_time:     i32,
	has_unix_time: bool,
	ntfs:          [3]u64,
	has_ntfs:      bool,
	uid:           i64,
	gid:           i64,
	has_owner:     bool,
	crc:           u32,
	size:          i64,
	compressed:    i64,
	header:        i64,
	offset:        i64,
	local_zip64:   bool,
	final:         bool,
	password:      string,
}

Member_Sink :: struct {
	writer: ^Writer,
	cipher: ^Cipher,
	count:  i64,
}

Source :: struct {
	data:       []u8,
	reader:     io.Reader,
	position:   int,
	start:      i64,
	rewindable: bool,
}

Encoder :: struct {
	method:  Method,
	w:       io.Writer,
	deflate: deflate.Writer,
	bzip2:   bzip2.Writer,
	lzma:    lzma.Writer,
	ppmd:    ppmd.Writer,
	xz:      xz.Writer,
}

Cipher_Kind :: enum u8 {
	None,
	ZipCrypto,
	AES,
}

Cipher :: struct {
	kind:    Cipher_Kind,
	keyed:   bool,
	done:    bool,
	result:  Error,
	keys:    [3]u32,
	ctr:     aes.Context_CTR,
	mac:     hmac.Context,
	tag:     i64,
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
