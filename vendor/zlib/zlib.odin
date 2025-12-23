// Bindings for [[ libz ; https://zlib.net ]] ZLIB compression library.
package vendor_zlib

import "core:c"

when ODIN_OS == .Windows {
	foreign import zlib "libz.lib"
} else when ODIN_OS == .Linux {
	foreign import zlib "system:z"
} else {
	foreign import zlib "system:z"
}

VERSION         :: "1.2.12"
VERNUM          :: 0x12c0
VER_MAJOR       :: 1
VER_MINOR       :: 2
VER_REVISION    :: 12
VER_SUBREVISION :: 0

voidp           :: rawptr
voidpf          :: rawptr
voidpc          :: rawptr
Byte            :: c.uchar
Bytef           :: c.uchar
uInt            :: c.uint
uIntf           :: c.uint
uLong           :: c.ulong
uLongf          :: c.ulong
size_t          :: c.size_t
off_t           :: c.long
off64_t         :: i64
crc_t           :: u32

alloc_func      :: proc "c" (opaque: voidp, items: uInt, size: uInt) -> voidpf
free_func       :: proc "c" (opaque: voidp, address: voidpf)

in_func         :: proc "c" (rawptr, [^][^]c.uchar) -> c.uint
out_func        :: proc "c" (rawptr, [^]c.uchar, c.uint) -> c.int

gzFile_s :: struct {
	have: c.uint,
	next: [^]c.uchar,
	pos:  off64_t,
}

gzFile :: ^gzFile_s

z_stream_s :: struct {
	next_in:   ^Bytef,
	avail_in:  uInt,
	total_in:  uLong,
	next_out:  ^Bytef,
	avail_out: uInt,
	total_out: uLong,
	msg:       [^]c.char,
	state:     rawptr,
	zalloc:    alloc_func,
	zfree:     free_func,
	opaque:    voidpf,
	data_type: c.int,
	adler:     uLong,
	reserved:  uLong,
}

z_stream  :: z_stream_s
z_streamp :: ^z_stream

gz_header_s :: struct {
	text:      c.int,
	time:      uLong,
	xflags:    c.int,
	os:        c.int,
	extra:     [^]Bytef,
	extra_len: uInt,
	extra_max: uInt,
	name:      [^]Bytef,
	name_max:  uInt,
	comment:   [^]Bytef,
	comm_max:  uInt,
	hcrc:      c.int,
	done:      c.int,
}

gz_header  :: gz_header_s
gz_headerp :: ^gz_header

// Allowed flush values; see deflate() and inflate() below for details
NO_FLUSH             :: 0
PARTIAL_FLUSH        :: 1
SYNC_FLUSH           :: 2
FULL_FLUSH           :: 3
FINISH               :: 4
BLOCK                :: 5
TREES                :: 6

// Return codes for the compression/decompression functions. Negative values are
// errors, positive values are used for special but normal events.
OK                   :: 0
STREAM_END           :: 1
NEED_DICT            :: 2
ERRNO                :: -1
STREAM_ERROR         :: -2
DATA_ERROR           :: -3
MEM_ERROR            :: -4
BUF_ERROR            :: -5
VERSION_ERROR        :: -6

// compression levels
NO_COMPRESSION       :: 0
BEST_SPEED           :: 1
BEST_COMPRESSION     :: 9
DEFAULT_COMPRESSION  :: -1

// compression strategy; see deflateInit2() below for details
FILTERED             :: 1
HUFFMAN_ONLY         :: 2
RLE                  :: 3
FIXED                :: 4
DEFAULT_STRATEGY     :: 0

// Possible values of the data_type field for deflate()
BINARY               :: 0
TEXT                 :: 1
ASCII                :: TEXT // for compatibility with 1.2.2 and earlier
UNKNOWN              :: 2

// The deflate compression method (the only one supported in this version)
DEFLATED             :: 8

NULL                 :: 0 // for initializing zalloc, zfree, opaque

version              :: Version // for compatibility with versions < 1.0.2

@(default_calling_convention="c")
foreign zlib {
	// becase zlib.zlibVersion would be silly to write
	@(link_prefix="zlib")
	Version              :: proc() -> cstring ---

	deflate              :: proc(strm: z_streamp, flush: c.int) -> c.int ---
	deflateEnd           :: proc(strm: z_streamp) -> c.int ---
	inflate              :: proc(strm: z_streamp, flush: c.int) -> c.int ---
	inflateEnd           :: proc(strm: z_streamp) -> c.int ---
	deflateSetDictionary :: proc(strm: z_streamp, dictionary: [^]Bytef, dictLength: uInt) -> c.int ---
	deflateGetDictionary :: proc(strm: z_streamp, dictionary: [^]Bytef, dictLength: ^uInt) -> c.int ---
	deflateCopy          :: proc(dest, source: z_streamp) -> c.int ---
	deflateReset         :: proc(strm: z_streamp) -> c.int ---
	deflateParams        :: proc(strm: z_streamp, level, strategy: c.int) -> c.int ---
	deflateTune          :: proc(strm: z_streamp, good_length, max_lazy, nice_length, max_chain: c.int) -> c.int ---
	deflateBound         :: proc(strm: z_streamp, sourceLen: uLong) -> uLong ---
	deflatePending       :: proc(strm: z_streamp, pending: [^]c.uint, bits: [^]c.int) -> c.int ---
	deflatePrime         :: proc(strm: z_streamp, bits, value: c.int) -> c.int ---
	deflateSetHeader     :: proc(strm: z_streamp, head: gz_headerp) -> c.int ---
	inflateSetDictionary :: proc(strm: z_streamp, dictionary: [^]Bytef, dictLength: uInt) -> c.int ---
	inflateGetDictionary :: proc(strm: z_streamp, dictionary: [^]Bytef, dictLength: ^uInt) -> c.int ---
	inflateSync          :: proc(strm: z_streamp) -> c.int ---
	inflateCopy          :: proc(dest, source: z_streamp) -> c.int ---
	inflateReset         :: proc(strm: z_streamp) -> c.int ---
	inflateReset2        :: proc(strm: z_streamp, windowBits: c.int) -> c.int ---
	inflatePrime         :: proc(strm: z_streamp, bits, value: c.int) -> c.int ---
	inflateMark          :: proc(strm: z_streamp) -> c.long ---
	inflateGetHeader     :: proc(strm: z_streamp, head: gz_headerp) -> c.int ---
	inflateBack          :: proc(strm: z_streamp, _in: in_func, in_desc: rawptr, out: out_func, out_desc: rawptr) -> c.int ---
	inflateBackEnd       :: proc(strm: z_streamp) -> c.int ---
	zlibCompileFlags     :: proc() -> uLong ---
	compress             :: proc(dest: [^]Bytef, destLen: ^uLongf, source: [^]Bytef, sourceLen: uLong) -> c.int ---
	compress2            :: proc(dest: [^]Bytef, destLen: ^uLongf, source: [^]Bytef, sourceLen: uLong, level: c.int) -> c.int ---
	compressBound        :: proc(sourceLen: uLong) -> uLong ---
	uncompress           :: proc(dest: [^]Bytef, destLen: ^uLongf, source: [^]Bytef, sourceLen: uLong) -> c.int ---
	uncompress2          :: proc(dest: [^]Bytef, destLen: ^uLongf, source: [^]Bytef, sourceLen: ^uLong) -> c.int ---
	gzdopen              :: proc(fd: c.int, mode: cstring) -> gzFile ---
	gzbuffer             :: proc(file: gzFile, size: c.uint) -> c.int ---
	gzsetparams          :: proc(file: gzFile, level, strategy: c.int) -> c.int ---
	gzread               :: proc(file: gzFile, buf: voidp, len: c.uint) -> c.int ---
	gzfread              :: proc(buf: voidp, size, nitems: size_t, file: gzFile) -> size_t ---
	gzwrite              :: proc(file: gzFile, buf: voidpc, len: c.uint) -> c.int ---
	gzfwrite             :: proc(buf: voidpc, size, nitems: size_t, file: gzFile) -> size_t ---
	gzprintf             :: proc(file: gzFile, format: cstring, #c_vararg args: ..any) -> c.int ---
	gzputs               :: proc(file: gzFile, s: cstring) -> c.int ---
	gzgets               :: proc(file: gzFile, buf: [^]c.char, len: c.int) -> [^]c.char ---
	gzputc               :: proc(file: gzFile, ch: c.int) -> c.int ---
	gzgetc_              :: proc(file: gzFile) -> c.int --- // backwards compat, not the same as gzget
	gzungetc             :: proc(ch: c.int, file: gzFile) -> c.int ---
	gzflush              :: proc(file: gzFile, flush: c.int) -> c.int ---
	gzrewind             :: proc(file: gzFile) -> c.int ---
	gzeof                :: proc(file: gzFile) -> c.int ---
	gzdirect             :: proc(file: gzFile) -> c.int ---
	gzclose              :: proc(file: gzFile) -> c.int ---
	gzclose_r            :: proc(file: gzFile) -> c.int ---
	gzclose_w            :: proc(file: gzFile) -> c.int ---
	gzerror              :: proc(file: gzFile, errnum: ^c.int) -> cstring ---
	gzclearerr           :: proc(file: gzFile) ---
	adler32              :: proc(adler: uLong, buf: [^]Bytef, len: uInt) -> uLong ---
	adler32_z            :: proc(adler: uLong, buf: [^]Bytef, len: size_t) -> uLong ---
	crc32                :: proc(crc: uLong, buf: [^]Bytef, len: uInt) -> uLong ---
	crc32_z              :: proc(crc: uLong, buf: [^]Bytef, len: size_t) -> uLong ---
	crc32_combine_op     :: proc(crc1, crc2, op: uLong) -> uLong ---
	gzopen64             :: proc(cstring, cstring) -> gzFile ---
	gzseek64             :: proc(gzFile, off64_t, c.int) -> off64_t ---
	gztell64             :: proc(gzFile) -> off64_t ---
	gzoffset64           :: proc(gzFile) -> off64_t ---
	adler32_combine64    :: proc(uLong, uLong, off64_t) -> uLong ---
	crc32_combine64      :: proc(uLong, uLong, off64_t) -> uLong ---
	crc32_combine_gen64  :: proc(off64_t) -> uLong ---
	adler32_combine      :: proc(uLong, uLong, off_t) -> uLong ---
	crc32_combine        :: proc(uLong, uLong, off_t) -> uLong ---
	crc32_combine_gen    :: proc(off_t) -> uLong ---
	zError               :: proc(c.int) -> cstring ---
	inflateSyncPoint     :: proc(z_streamp) -> c.int ---
	get_crc_table        :: proc() -> [^]crc_t ---
	inflateUndermine     :: proc(z_streamp, c.int) -> c.int ---
	inflateValidate      :: proc(z_streamp, c.int) -> c.int ---
	inflateCodesUsed     :: proc(z_streamp) -> c.ulong ---
	inflateResetKeep     :: proc(z_streamp) -> c.int ---
	deflateResetKeep     :: proc(z_streamp) -> c.int ---
}

// Make these private since we create wrappers below passing in version and size
// of the stream structure like zlib.h does
@(private)
@(default_calling_convention="c")
foreign zlib {
	deflateInit_         :: proc(strm: z_streamp, level: c.int, version: cstring, stream_size: c.int) -> c.int ---
	inflateInit_         :: proc(strm: z_streamp, level: c.int, version: cstring, stream_size: c.int) -> c.int ---
	deflateInit2_        :: proc(strm: z_streamp, level, method, windowBits, memLevel, strategy: c.int, version: cstring, stream_size: c.int) -> c.int ---
	inflateInit2_        :: proc(strm: z_streamp, windowBits: c.int, version: cstring, stream_size: c.int) -> c.int ---
	inflateBackInit_     :: proc(strm: z_streamp, windowBits: c.int, window: [^]c.uchar, version: cstring, stream_size: c.int) -> c.int ---

	// see below for explanation
	@(link_name="gzgetc")
	gzgetc_unique        :: proc(file: gzFile) -> c.int ---
}

deflateInit :: #force_inline proc "c" (strm: z_streamp, level: c.int) -> c.int {
	return deflateInit_(strm, level, VERSION, c.int(size_of(z_stream)))
}

inflateInit :: #force_inline proc "c" (strm: z_streamp, level: c.int) -> c.int {
	return inflateInit_(strm, level, VERSION, c.int(size_of(z_stream)))
}

deflateInit2 :: #force_inline proc "c" (strm: z_streamp, level, method, windowBits, memLevel, strategy: c.int) -> c.int {
	return deflateInit2_(strm, level, method, windowBits, memLevel, strategy, VERSION, c.int(size_of(z_stream)))
}

inflateInit2 :: #force_inline proc "c" (strm: z_streamp, windowBits: c.int) -> c.int {
	return inflateInit2_(strm, windowBits, VERSION, c.int(size_of(z_stream)))
}

inflateBackInit :: #force_inline proc "c" (strm: z_streamp, windowBits: c.int, window: [^]c.uchar) -> c.int {
	return inflateBackInit_(strm, windowBits, window, VERSION, c.int(size_of(z_stream)))
}

// zlib.h redefines gzgetc with a macro and uses (gzgetc)(g) to invoke it from
// inside the same macro (preventing macro expansion), in Odin we give that a
// unique name using link_prefix then implement the body of the macro in our own
// procedure calling the unique named gzgetc instead.
gzgetc :: #force_inline proc(file: gzFile) -> c.int {
	if file.have != 0 {
		file.have -= 1
		file.pos += 1
		ch := c.int(file.next[0])
		file.next = &file.next[1]
		return ch
	}
	return gzgetc_unique(file)
}
