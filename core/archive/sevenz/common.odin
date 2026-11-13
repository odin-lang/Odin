package archive_sevenz

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/filters"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:io"
import "core:os"

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

SIGNATURE             :: [6]u8{'7', 'z', 0xBC, 0xAF, 0x27, 0x1C}
SIGNATURE_HEADER_SIZE :: 32
VERSION_MAJOR         :: 0
HEADER_SIZE_MAX       :: i64(#config(SEVENZ_HEADER_SIZE_MAX, 1 << 30))
HEADER_DEPTH_MAX      :: 4
FOLDER_CODERS_MAX     :: 64
FOLDER_STREAMS_MAX    :: 64
CODER_INPUTS_MAX      :: 4
CODER_ID_SIZE_MAX     :: 8
COPY_CHUNK_SIZE       :: 64 * 1024
FILTER_BUFFER_SIZE    :: 64 * 1024
LINK_TARGET_MAX       :: 4096
NTFS_EPOCH_DELTA      :: 116_444_736_000_000_000
UNIX_EXTENSION        :: 0x8000
CODER_MEMORY          :: 1 << 16
BZIP2_MEMORY          :: 4 * 5 * 900_000
DEFLATE_MEMORY        :: 1 << 18
DEFLATE64_MEMORY      :: 1 << 19
ZERO_READS_MAX        :: 64
LZMA_BASE_PROBS       :: 1984
LZMA_LITERAL_PROBS    :: 0x300

Property_ID :: enum u8 {
	End                = 0x00,
	Header             = 0x01,
	Archive_Properties = 0x02,
	Additional_Streams = 0x03,
	Main_Streams       = 0x04,
	Files_Info         = 0x05,
	Pack_Info          = 0x06,
	Unpack_Info        = 0x07,
	Substreams_Info    = 0x08,
	Size               = 0x09,
	CRC                = 0x0A,
	Folder             = 0x0B,
	Coders_Unpack_Size = 0x0C,
	Num_Unpack_Stream  = 0x0D,
	Empty_Stream       = 0x0E,
	Empty_File         = 0x0F,
	Anti               = 0x10,
	Name               = 0x11,
	Creation_Time      = 0x12,
	Access_Time        = 0x13,
	Modification_Time  = 0x14,
	Attributes         = 0x15,
	Comment            = 0x16,
	Encoded_Header     = 0x17,
	Start_Position     = 0x18,
	Dummy              = 0x19,
}

Method_ID :: enum u64 {
	Copy      = 0x00,
	Delta     = 0x03,
	X86       = 0x04,
	PPC       = 0x05,
	IA64      = 0x06,
	ARM       = 0x07,
	ARMT      = 0x08,
	SPARC     = 0x09,
	ARM64     = 0x0A,
	RISCV     = 0x0B,
	LZMA2     = 0x21,
	Swap2     = 0x02_03_02,
	Swap4     = 0x02_03_04,
	LZMA      = 0x03_01_01,
	BCJ_X86   = 0x03_03_01_03,
	BCJ2      = 0x03_03_01_1B,
	BCJ_PPC   = 0x03_03_02_05,
	BCJ_IA64  = 0x03_03_04_01,
	BCJ_ARM   = 0x03_03_05_01,
	BCJ_ARMT  = 0x03_03_07_01,
	BCJ_SPARC = 0x03_03_08_05,
	PPMd      = 0x03_04_01,
	Deflate   = 0x04_01_08,
	Deflate64 = 0x04_01_09,
	BZip2     = 0x04_02_02,
	AES       = 0x06_F1_07_01,
}

Coder_Kind :: enum u8 {
	Unsupported,
	Copy,
	LZMA,
	LZMA2,
	PPMd,
	Deflate,
	Deflate64,
	BZip2,
	Branch,
	Delta,
	Swap2,
	Swap4,
	BCJ2,
	AES,
}

Coder :: struct {
	id:          u64,
	kind:        Coder_Kind,
	in_streams:  int,
	first_in:    int,
	properties:  []u8,
	unpack_size: i64,
}

Bind_Pair :: struct {
	in_index:  int,
	out_index: int,
}

Folder :: struct {
	first_coder:  int,
	coder_count:  int,
	first_bind:   int,
	bind_count:   int,
	first_packed: int,
	packed_count: int,
	first_pack:   int,
	unpack_coder: int,
	unpack_size:  i64,
	pack_size:    i64,
	crc:          Maybe(u32),
	stream_count: int,
	method:       archive.Method,
	method_id:    u64,
	filters:      archive.Filters,
	encrypted:    bool,
	supported:    bool,
}

Streams :: struct {
	pack_offsets: [dynamic]i64,
	pack_sizes:   [dynamic]i64,
	coders:       [dynamic]Coder,
	bind_pairs:   [dynamic]Bind_Pair,
	packed:       [dynamic]int,
	folders:      [dynamic]Folder,
	sub_sizes:    [dynamic]i64,
	sub_crcs:     [dynamic]Maybe(u32),
}

Item :: struct {
	path:              string,
	raw_path:          []u8,
	size:              i64,
	crc:               Maybe(u32),
	folder:            int,
	folder_offset:     i64,
	has_stream:        bool,
	is_directory:      bool,
	is_anti:           bool,
	attributes:        Maybe(u32),
	creation_time:     Maybe(u64),
	access_time:       Maybe(u64),
	modification_time: Maybe(u64),
	start_position:    Maybe(u64),
}

Name_Index :: struct {
	path:     string,
	position: int,
}

Store :: struct {
	data:   []u8,
	stream: io.Stream,
	size:   i64,
	memory: bool,
}

Reader :: struct {
	allocator:    runtime.Allocator,
	options:      compress.Options,
	store:        Store,
	file:         ^os.File,
	header:       []u8,
	owns_header:  bool,
	header_start: i64,
	streams:      Streams,
	items:        []Item,
	names:        []u8,
	index:        []Name_Index,
	generation:   u32,
}

Parser :: struct {
	data: []u8,
	pos:  int,
}

Section :: struct {
	decoder: ^Folder_Decoder,
	offset:  i64,
	end:     i64,
}

Node :: struct {
	decoder:     ^Folder_Decoder,
	kind:        Coder_Kind,
	id:          u64,
	size:        i64,
	produced:    i64,
	inputs:      [CODER_INPUTS_MAX]io.Stream,
	input_sizes: [CODER_INPUTS_MAX]i64,
	sections:    [CODER_INPUTS_MAX]^Section,
	slice:       []u8,
	ctx:         compress.Context,
	has_ctx:     bool,
	lzma:        lzma.Reader,
	ppmd:        ppmd.Reader,
	bzip2:       bzip2.Reader,
	inflate:     deflate.Inflate_Reader,
	branch:      filters.Branch_State,
	delta:       filters.Delta_State,
	buffer:      []u8,
	start:       int,
	ready:       int,
	end:         int,
	eof:         bool,
	output:      []u8,
	decoded:     bool,
	err:         Error,
	active:      bool,
}

Folder_Decoder :: struct {
	store:     ^Store,
	streams:   ^Streams,
	folder:    int,
	options:   compress.Options,
	allocator: runtime.Allocator,
	nodes:     []Node,
	sections:  []Section,
	root:      ^Node,
	position:  i64,
	packed_in: i64,
	crc:       u32,
	scratch:   []u8,
	err:       Error,
	fast:      bool,
	active:    bool,
}

Member :: struct {
	reader:    ^Reader,
	decoder:   ^Folder_Decoder,
	own:       Folder_Decoder,
	allocator: runtime.Allocator,
	index:     int,
	size:      i64,
	produced:  i64,
	crc:       u32,
	expected:  Maybe(u32),
	next:      i64,
	start_in:  i64,
	err:       Error,
	active:    bool,
	owned:     bool,
}

Iterator :: struct {
	reader:   ^Reader,
	index:    int,
	decoder:  Folder_Decoder,
	member:   Member,
	err:      Error,
	err_path: [dynamic]u8,
}
