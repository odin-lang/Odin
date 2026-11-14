package archive_sevenz

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/filters"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:crypto/aes"
import "core:io"
import "core:os"
import "core:sync"

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
AES_KEY_SIZE          :: 32
AES_SALT_MAX          :: 16
AES_IV_MAX            :: 16
AES_POWER_MAX         :: 24
AES_POWER_RAW         :: 0x3F
KEY_CACHE_SIZE        :: 4

VERSION_MINOR         :: 4
SNIFF_SIZE            :: 1 << 14
CODER_PROPERTIES_MAX  :: 5
WRITER_CODERS_MAX     :: 4
BCJ2_PACK_STREAMS     :: 4
AES_POWER_DEFAULT     :: 19
AES_PROPERTIES_MAX    :: 2 + AES_SALT_MAX + AES_IV_MAX
CIPHER_BUFFER_SIZE    :: 64 * 1024
SOLID_SIZE_MIN        :: i64(1) << 24
SOLID_SIZE_MAX        :: i64(1) << 32
SOLID_SIZE_LZMA2_MAX  :: i64(1) << 34
LZMA2_CHUNK_MIN       :: i64(1) << 20
LZMA2_CHUNK_MAX       :: i64(1) << 28
ESCAPE_BASE           :: 0xEF00
ESCAPE_FIRST          :: 0xEF80
ESCAPE_LAST           :: 0xEFFF

HEADER_LZMA_OPTIONS :: lzma.Options{
	lc           = 3,
	lp           = 0,
	pb           = 2,
	dict_size    = 1 << 20,
	nice_len     = 273,
	match_finder = .BT2,
}

BCJ2_LZMA_OPTIONS :: lzma.Options{
	lc           = 0,
	lp           = 2,
	pb           = 2,
	dict_size    = 1 << 20,
	nice_len     = 128,
	match_finder = .BT4,
}

SORT_EXTENSIONS := [?]string{
	"7z", "xz", "lzma", "ace", "arc", "arj", "bz", "tbz", "bz2", "tbz2", "cab", "deb", "gz", "tgz", "ha", "lha", "lzh", "lzo", "lzx", "pak", "rar", "rpm", "sit", "zoo",
	"zip", "jar", "ear", "war", "msi",
	"3gp", "avi", "mov", "mpeg", "mpg", "mpe", "wmv",
	"aac", "ape", "fla", "flac", "la", "mp3", "m4a", "mp4", "ofr", "ogg", "pac", "ra", "rm", "rka", "shn", "swa", "tta", "wv", "wma", "wav",
	"swf",
	"chm", "hxi", "hxs",
	"gif", "jpeg", "jpg", "jp2", "png", "tiff", "bmp", "ico", "psd", "psp",
	"awg", "ps", "eps", "cgm", "dxf", "svg", "vrml", "wmf", "emf", "ai", "md",
	"cad", "dwg", "pps", "key", "sxi",
	"max", "3ds",
	"iso", "bin", "nrg", "mdf", "img", "pdi", "tar", "cpio", "xpi",
	"vfd", "vhd", "vud", "vmc", "vsv",
	"vmdk", "dsk", "nvram", "vmem", "vmsd", "vmsn", "vmss", "vmtm",
	"inl", "inc", "idl", "acf", "asa",
	"h", "hpp", "hxx", "c", "cpp", "cxx", "m", "mm", "go", "swift",
	"rc", "java", "cs", "rs", "pas", "bas", "vb", "cls", "ctl", "frm", "dlg", "def",
	"f77", "f", "f90", "f95",
	"asm", "s",
	"sql", "manifest", "dep",
	"mak", "clw", "csproj", "vcproj", "sln", "dsp", "dsw",
	"class",
	"bat", "cmd", "bash", "sh",
	"xml", "xsd", "xsl", "xslt", "hxk", "hxc", "htm", "html", "xhtml", "xht", "mht", "mhtml", "htw", "asp", "aspx", "css", "cgi", "jsp", "shtml",
	"awk", "sed", "hta", "js", "json", "php", "php3", "php4", "php5", "phptml", "pl", "pm", "py", "pyo", "rb", "tcl", "ts", "vbs",
	"text", "txt", "tex", "ans", "asc", "srt", "reg", "ini", "doc", "docx", "mcw", "dot", "rtf", "hlp", "xls", "xlr", "xlt", "xlw", "ppt", "pdf",
	"sxc", "sxd", "sxi", "sxg", "sxw", "stc", "sti", "stw", "stm", "odt", "ott", "odg", "otg", "odp", "otp", "ods", "ots", "odf",
	"abw", "afp", "cwk", "lwp", "wpd", "wps", "wpt", "wrf", "wri",
	"abf", "afm", "bdf", "fon", "mgf", "otf", "pcf", "pfa", "snf", "ttf",
	"dbf", "mdb", "nsf", "ntf", "wdb", "db", "fdb", "gdb",
	"exe", "dll", "ocx", "vbx", "sfx", "sys", "tlb", "awx", "com", "obj", "lib", "out", "o", "so",
	"pdb", "pch", "idb", "ncb", "opt",
}

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
	password:     string,
	keys:         Key_Cache,
}

Cached_Key :: struct {
	password:  []u8,
	salt:      [AES_SALT_MAX]u8,
	salt_size: int,
	power:     int,
	key:       [AES_KEY_SIZE]u8,
}

Key_Cache :: struct {
	lock:      sync.Mutex,
	allocator: runtime.Allocator,
	entries:   [KEY_CACHE_SIZE]Cached_Key,
	next:      int,
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
	filter:      filters.Reader,
	bcj2:        filters.Bcj2_Reader,
	buffer:      []u8,
	start:       int,
	ready:       int,
	end:         int,
	eof:         bool,
	cipher:      aes.Context_ECB,
	iv:          [aes.BLOCK_SIZE]u8,
	keyed:       bool,
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
	keys:      ^Key_Cache,
	password:  string,
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

Filter_Choice :: enum u8 {
	Auto,
	None,
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

Solid_Order :: enum u8 {
	Name,
	Extension,
}

Entry_Data :: union {
	[]u8,
	io.Reader,
}

Entry_Options :: struct {
	method:         archive.Method,
	level:          Maybe(int),
	filter:         Filter_Choice,
	delta_distance: int,
	lzma:           Maybe(lzma.Options),
	ppmd:           Maybe(ppmd.Properties),
	password:       Maybe(string),
}

Writer_Options :: struct {
	method:             archive.Method,
	level:              Maybe(int),
	filter:             Filter_Choice,
	delta_distance:     int,
	lzma:               Maybe(lzma.Options),
	ppmd:               Maybe(ppmd.Properties),
	solid:              bool,
	solid_size:         i64,
	solid_files:        int,
	solid_order:        Solid_Order,
	creation_time:      bool,
	access_time:        bool,
	plain_header:       bool,
	deterministic:      bool,
	password:           string,
	kdf_power:          int,
	unencrypted_header: bool,
	options:            compress.Options,
}

Coder_Setup :: struct {
	method:   archive.Method,
	level:    int,
	lzma:     lzma.Options,
	ppmd:     ppmd.Properties,
	lzma_set: bool,
	ppmd_set: bool,
	filter:   Filter_Choice,
	delta:    int,
}

Filter_Pick :: struct {
	filter: Filter_Choice,
	delta:  int,
	auto:   bool,
}

Out_Coder :: struct {
	id:              Method_ID,
	in_streams:      int,
	properties:      [CODER_PROPERTIES_MAX]u8,
	properties_size: int,
	unpack_size:     i64,
}

Out_Folder :: struct {
	coders:       [WRITER_CODERS_MAX]Out_Coder,
	coder_count:  int,
	bcj2:         bool,
	encrypted:    bool,
	stream_count: int,
}

Out_Cipher :: struct {
	ivs:          [BCJ2_PACK_STREAMS][aes.BLOCK_SIZE]u8,
	unpack_sizes: [BCJ2_PACK_STREAMS]i64,
}

Pack_Cipher :: struct {
	ctx:     aes.Context_ECB,
	iv:      [aes.BLOCK_SIZE]u8,
	block:   [aes.BLOCK_SIZE]u8,
	pending: int,
	plain:   i64,
	keyed:   bool,
}

Out_File :: struct {
	size:              i64,
	crc:               u32,
	attributes:        u32,
	modification_time: u64,
	creation_time:     u64,
	access_time:       u64,
	has_stream:        bool,
	is_directory:      bool,
}

Pack_Sink :: struct {
	writer: ^Writer,
	cipher: ^Pack_Cipher,
	count:  i64,
}

Encoder :: struct {
	method:  archive.Method,
	w:       io.Writer,
	deflate: deflate.Deflate_Writer,
	bzip2:   bzip2.Writer,
	lzma:    lzma.Writer,
	ppmd:    ppmd.Writer,
	err:     Error,
}

Side_Sink :: struct {
	data: [dynamic]u8,
	err:  Error,
}

Open_Folder :: struct {
	active:    bool,
	setup:     Coder_Setup,
	folder:    Out_Folder,
	encoder:   Encoder,
	stage:     filters.Writer,
	bcj2:      filters.Bcj2_Writer,
	bcj2_in:   i64,
	call:      Side_Sink,
	jump:      Side_Sink,
	rc:        Side_Sink,
	sink:      Pack_Sink,
	unpack:    i64,
	limit:     i64,
	files:     int,
	broken:    bool,
	encrypted: bool,
	key:       [AES_KEY_SIZE]u8,
	cipher:    Pack_Cipher,
	ciphered:  Out_Cipher,
}

Source :: struct {
	data:     []u8,
	reader:   io.Reader,
	position: int,
	eof:      bool,
}

Walked_Entry :: struct {
	name:   string,
	info:   os.File_Info,
	pick:   Filter_Pick,
	stream: bool,
}

Writer :: struct {
	allocator:     runtime.Allocator,
	options:       Writer_Options,
	stream:        io.Stream,
	file:          ^os.File,
	path:          string,
	start:         i64,
	offset:        i64,
	end:           i64,
	pack_sizes:    [dynamic]i64,
	folders:       [dynamic]Out_Folder,
	files:         [dynamic]Out_File,
	names:         [dynamic]u8,
	name:          [dynamic]u8,
	walk_name:     [dynamic]u8,
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
}
