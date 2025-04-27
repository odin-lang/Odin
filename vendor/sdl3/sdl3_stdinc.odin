package sdl3

import "base:builtin"
import "base:intrinsics"
import "core:c"

#assert(size_of(c.int) == size_of(b32))
#assert(size_of(c.int) == size_of(rune))


SIZE_MAX :: 1<<(8*size_of(uint)) - 1

@(require_results)
FOURCC :: #force_inline proc "contextless" (#any_int A, B, C, D: u8) -> u32 {
	return u32(A)<<0 | u32(B)<<8 | u32(C)<<16 | u32(D)<<24
}


Sint8 :: i8
Uint8 :: u8

Sint16 :: i16
Uint16 :: u16

Sint32 :: i32
Uint32 :: u32

Sint64 :: i64
Uint64 :: u64

wchar_t :: c.wchar_t

/**
 * SDL times are signed, 64-bit integers representing nanoseconds since the
 * Unix epoch (Jan 1, 1970).
 *
 * They can be converted between POSIX time_t values with SDL_NS_TO_SECONDS()
 * and SDL_SECONDS_TO_NS(), and between Windows FILETIME values with
 * SDL_TimeToWindows() and SDL_TimeFromWindows().
 *
 * \since This macro is available since SDL 3.2.0.
 *
 * \sa SDL_MAX_SINT64
 * \sa SDL_MIN_SINT64
 */
Time :: distinct i64

FLT_EPSILON :: 1.1920928955078125e-07 /* 0x0.000002p0 */


INIT_INTERFACE :: proc "contextless" (iface: ^$T) {
	zerop(iface)
	iface.version = size_of(iface^)
}

stack_alloc :: intrinsics.alloca


malloc_func  :: #type proc "c" (size: uint) -> rawptr
calloc_func  :: #type proc "c" (nmemb: uint, size: uint) -> rawptr
realloc_func :: #type proc "c" (mem: rawptr, size: uint) -> rawptr
free_func    :: #type proc "c" (mem: rawptr)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	@(require_results)
	malloc  :: proc(size: uint) -> rawptr ---

	@(require_results)
	calloc  :: proc(nmemb: uint, size: uint) -> rawptr ---

	@(require_results)
	realloc :: proc(mem: rawptr, size: uint) -> rawptr ---

	free    :: proc(mem: rawptr) ---

	GetOriginalMemoryFunctions :: proc(malloc_func:  ^malloc_func,
	                                   calloc_func:  ^calloc_func,
	                                   realloc_func: ^realloc_func,
	                                   free_func:    ^free_func) ---

	GetMemoryFunctions :: proc(malloc_func:  ^malloc_func,
	                           calloc_func:  ^calloc_func,
	                           realloc_func: ^realloc_func,
	                           free_func:    ^free_func) ---

	SetMemoryFunctions :: proc(malloc_func:  malloc_func,
	                           calloc_func:  calloc_func,
	                           realloc_func: realloc_func,
	                           free_func:    free_func) ---

	@(require_results)
	aligned_alloc :: proc(alignment: uint, size: uint) -> rawptr ---
	aligned_free :: proc(mem: rawptr) ---

	@(require_results)
	GetNumAllocations :: proc() -> c.int ---

}

Environment :: struct {}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	@(require_results)
	GetEnvironment           :: proc() -> ^Environment ---
	@(require_results)
	CreateEnvironment        :: proc(populated: bool) -> ^Environment ---
	@(require_results)
	GetEnvironmentVariable   :: proc(env: ^Environment, name: cstring) -> cstring ---
	@(require_results)
	GetEnvironmentVariables  :: proc(env: ^Environment) -> [^]cstring ---
	SetEnvironmentVariable   :: proc(env: ^Environment, name, value: cstring, overwrite: bool) -> bool ---
	UnsetEnvironmentVariable :: proc(env: ^Environment, name: cstring) -> bool ---
	DestroyEnvironment       :: proc(env: ^Environment) ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	@(require_results)
	getenv           :: proc(name: cstring) -> cstring  ---
	@(require_results)
	getenv_unsafe    :: proc(name: cstring) -> cstring  ---
	setenv_unsafe    :: proc(name, value: cstring, overwrite: b32) -> c.int ---
	unsetenv_unsafe  :: proc(name: cstring) -> c.int ---

}

CompareCallback   :: #type proc "c" (a, b: rawptr) -> c.int
CompareCallback_r :: #type proc "c" (userdata: rawptr, a, b: rawptr) -> c.int

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	qsort   :: proc(base: rawptr, nmemb: uint,  size:  uint, compare: CompareCallback) ---
	bsearch :: proc(key: rawptr,  base: rawptr, nmemb: uint, size: uint, compare: CompareCallback) -> rawptr ---

	qsort_r   :: proc(base: rawptr, nmemb: uint,  size: uint,  compare: CompareCallback_r, userdata: rawptr) ---
	bsearch_r :: proc(key:  rawptr, base: rawptr, nmemb: uint, size: uint, compare: CompareCallback_r, userdata: rawptr) -> rawptr ---
}


abs   :: builtin.abs
min   :: builtin.min
max   :: builtin.max
clamp :: builtin.clamp


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	isalpha  :: proc(x: rune) -> b32 ---
	isalnum  :: proc(x: rune) -> b32 ---
	isblank  :: proc(x: rune) -> b32 ---
	iscntrl  :: proc(x: rune) -> b32 ---
	isdigit  :: proc(x: rune) -> b32 ---
	isxdigit :: proc(x: rune) -> b32 ---
	ispunct  :: proc(x: rune) -> b32 ---
	isspace  :: proc(x: rune) -> b32 ---
	isupper  :: proc(x: rune) -> b32 ---
	islower  :: proc(x: rune) -> b32 ---
	isprint  :: proc(x: rune) -> b32 ---
	isgraph  :: proc(x: rune) -> b32 ---

	toupper :: proc(x: rune) -> rune ---
	tolower :: proc(x: rune) -> rune ---

	crc16      :: proc(crc: Uint16, data: rawptr, len: uint)  -> Uint16 ---
	crc32      :: proc(crc: Uint32, data: rawptr, len: uint)  -> Uint32 ---
	murmur3_32 :: proc(data: rawptr, len: uint, seed: Uint32) -> Uint32 ---
}

copyp :: #force_inline proc "contextless" (dst, src: ^$T) -> ^T {
	return (^T)(memcpy(dst, src, size_of(T)))
}

zerop :: #force_inline proc "contextless" (x: ^$T) {
	memset(x, 0, size_of(T))
}

zeroa :: #force_inline proc "contextless" (x: []$T) {
	memset(raw_data(x), 0, uint(size_of(T)*len(x)))
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	memcpy  :: proc(dst, src: rawptr, len: uint)      -> rawptr ---
	memmove :: proc(dst, src: rawptr, len: uint)      -> rawptr ---
	memset  :: proc(dst: rawptr, c: c.int, len: uint) -> rawptr ---
	@(require_results)
	memcmp  :: proc(s1, s2: rawptr, len: c.int) -> c.int ---
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	wcslen      :: proc(wstr: [^]wchar_t)                                -> uint ---
	wcsnlen     :: proc(wstr: [^]wchar_t, maxlen: uint)                  -> uint       ---
	wcslcpy     :: proc(dst, src: [^]wchar_t, maxlen: uint)              -> uint       ---
	wcslcat     :: proc(dst, src: [^]wchar_t, maxlen: uint)              -> uint       ---
	wcsdup      :: proc(wstr: [^]wchar_t)                                -> [^]wchar_t ---
	wcsstr      :: proc(haystack, needle: [^]wchar_t)                    -> [^]wchar_t ---
	wcsnstr     :: proc(haystack, needle: [^]wchar_t, maxlen: uint)      -> [^]wchar_t ---
	wcscmp      :: proc(str1, str2: [^]wchar_t)                          -> int        ---
	wcsncmp     :: proc(str1, str2: [^]wchar_t, maxlen: uint)            -> int        ---
	wcscasecmp  :: proc(str1, str2: [^]wchar_t)                          -> int        ---
	wcsncasecmp :: proc(str1, str2: [^]wchar_t, maxlen: uint)            -> int        ---
	wcstol      :: proc(str: [^]wchar_t, endp: ^[^]wchar_t, base: c.int) -> c.long     ---
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	strlen       :: proc(str: cstring)                                    -> uint       ---
	strnlen      :: proc(str: cstring, maxlen: uint)                      -> uint       ---
	strlcpy      :: proc(dst: [^]u8, src: cstring, maxlen: uint)          -> uint       ---
	utf8strlcpy  :: proc(dst: [^]u8, src: cstring, dst_bytes: uint)       -> uint       ---
	strlcat      :: proc(dst: [^]u8, src: cstring, maxlen: uint)          -> uint       ---
	strdup       :: proc(str: cstring)                                    -> [^]u8      ---
	strndup      :: proc(str: cstring, maxlen: uint)                      -> [^]u8      ---
	strrev       :: proc(str: [^]u8)                                      -> [^]u8      ---
	strupr       :: proc(str: [^]u8) -> [^]u8 ---
	strlwr       :: proc(str: [^]u8) -> [^]u8 ---
	strchr       :: proc(str: cstring, c: rune) -> [^]u8 ---
	strrchr      :: proc(str: cstring, c: rune) -> [^]u8 ---
	strstr       :: proc(haystack: cstring, needle: cstring) -> [^]u8 ---
	strnstr      :: proc(haystack: cstring, needle: cstring, maxlen: uint) -> [^]u8 ---
	strcasestr   :: proc(haystack: cstring, needle: cstring) -> [^]u8 ---
	strtok_r     :: proc(str: [^]u8, delim: cstring, saveptr: ^[^]u8) -> [^]u8 ---
	utf8strlen   :: proc(str: cstring) -> uint ---
	utf8strnlen  :: proc(str: cstring, bytes: uint) -> uint ---

	itoa         :: proc(value: c.int,       str: [^]u8, radix: c.int) -> [^]u8 ---
	uitoa        :: proc(value: c.uint,      str: [^]u8, radix: c.int) -> [^]u8 ---
	ltoa         :: proc(value: c.long,      str: [^]u8, radix: c.int) -> [^]u8 ---
	ultoa        :: proc(value: c.ulong,     str: [^]u8, radix: c.int) -> [^]u8 ---
	lltoa        :: proc(value: c.longlong,  str: [^]u8, radix: c.int) -> [^]u8 ---
	ulltoa       :: proc(value: c.ulonglong, str: [^]u8, radix: c.int) -> [^]u8 ---
	atoi         :: proc(str: cstring) -> c.int ---
	atof         :: proc(str: cstring) -> f64 ---

	strtol       :: proc(str: cstring, endp: ^[^]u8, base: c.int) -> c.long ---
	strtoul      :: proc(str: cstring, endp: ^[^]u8, base: c.int) -> c.ulong ---
	strtoll      :: proc(str: cstring, endp: ^[^]u8, base: c.int) -> c.longlong ---
	strtoull     :: proc(str: cstring, endp: ^[^]u8, base: c.int) -> c.ulonglong ---
	strtod       :: proc(str: cstring, endp: ^[^]u8) -> f64 ---
	strcmp       :: proc(str1, str2: cstring) -> c.int ---
	strncmp      :: proc(str1, str2: cstring, maxlen: uint) -> c.int ---
	strcasecmp   :: proc(str1, str2: cstring) -> c.int ---
	strncasecmp  :: proc(str1, str2: cstring, maxlen: uint) -> c.int ---
	strpbrk      :: proc(str: cstring, breakset: cstring) -> [^]u8 ---
	StepUTF8     :: proc(pstr: ^cstring, pslen: ^uint) -> Uint32 ---
	StepBackUTF8 :: proc(start: cstring, pstr: ^cstring) -> Uint32 ---
	UCS4ToUTF8   :: proc(codepoint: rune, dst: [^]u8) -> [^]u8 ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	sscanf       :: proc(text: cstring, fmt: cstring, #c_vararg args: ..any)                  -> c.int ---
	vsscanf      :: proc(text: cstring, fmt: cstring, ap: c.va_list)                          -> c.int ---
	snprintf     :: proc(text: [^]u8,      maxlen: uint, fmt: cstring, #c_vararg args: ..any) -> c.int ---
	swprintf     :: proc(text: [^]wchar_t, maxlen: uint, fmt: cstring, #c_vararg args: ..any) -> c.int ---
	vsnprintf    :: proc(text: [^]u8,      maxlen: uint, fmt: cstring, ap: c.va_list)         -> c.int ---
	vswprintf    :: proc(text: [^]wchar_t, maxlen: uint, fmt: cstring, ap: c.va_list)         -> c.int ---
	asprintf     :: proc(strp: ^[^]u8, fmt: cstring, #c_vararg args: ..any)                   -> c.int ---
	vasprintf    :: proc(strp: ^[^]u8, fmt: cstring, ap: c.va_list)                           -> c.int ---
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	srand        :: proc(seed: Uint64)                        ---
	rand         :: proc(n: Sint32) -> Sint32                 ---
	randf        :: proc() -> f32                             ---
	rand_bits    :: proc() -> Uint32                          ---
	rand_r       :: proc(state: ^Uint64, n: Sint32) -> Sint32 ---
	randf_r      :: proc(state: ^Uint64) -> f32               ---
	rand_bits_r  :: proc(state: ^Uint64) -> Uint32            ---
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	acos         :: proc(x: f64)           -> f64    ---
	acosf        :: proc(x: f32)           -> f32    ---
	asin         :: proc(x: f64)           -> f64    ---
	asinf        :: proc(x: f32)           -> f32    ---
	atan         :: proc(x: f64)           -> f64    ---
	atanf        :: proc(x: f32)           -> f32    ---
	atan2        :: proc(y: f64, x: f64)   -> f64    ---
	atan2f       :: proc(y: f32, x: f32)   -> f32    ---
	ceil         :: proc(x: f64)           -> f64    ---
	ceilf        :: proc(x: f32)           -> f32    ---
	copysign     :: proc(x: f64, y: f64)   -> f64    ---
	copysignf    :: proc(x: f32, y: f32)   -> f32    ---
	cos          :: proc(x: f64)           -> f64    ---
	cosf         :: proc(x: f32)           -> f32    ---
	exp          :: proc(x: f64)           -> f64    ---
	expf         :: proc(x: f32)           -> f32    ---
	fabs         :: proc(x: f64)           -> f64    ---
	fabsf        :: proc(x: f32)           -> f32    ---
	floor        :: proc(x: f64)           -> f64    ---
	floorf       :: proc(x: f32)           -> f32    ---
	trunc        :: proc(x: f64)           -> f64    ---
	truncf       :: proc(x: f32)           -> f32    ---
	fmod         :: proc(x: f64, y: f64)   -> f64    ---
	fmodf        :: proc(x: f32, y: f32)   -> f32    ---
	isinf        :: proc(x: f64)           -> c.int  ---
	isinff       :: proc(x: f32)           -> c.int  ---
	isnan        :: proc(x: f64)           -> c.int  ---
	isnanf       :: proc(x: f32)           -> c.int  ---
	log          :: proc(x: f64)           -> f64    ---
	logf         :: proc(x: f32)           -> f32    ---
	log10        :: proc(x: f64)           -> f64    ---
	log10f       :: proc(x: f32)           -> f32    ---
	modf         :: proc(x: f64, y: ^f64)  -> f64    ---
	modff        :: proc(x: f32, y: ^f32)  -> f32    ---
	pow          :: proc(x: f64, y: f64)   -> f64    ---
	powf         :: proc(x: f32, y: f32)   -> f32    ---
	round        :: proc(x: f64)           -> f64    ---
	roundf       :: proc(x: f32)           -> f32    ---
	lround       :: proc(x: f64)           -> c.long ---
	lroundf      :: proc(x: f32)           -> c.long ---
	scalbn       :: proc(x: f64, n: c.int) -> f64    ---
	scalbnf      :: proc(x: f32, n: c.int) -> f32    ---
	sin          :: proc(x: f64)           -> f64    ---
	sinf         :: proc(x: f32)           -> f32    ---
	sqrt         :: proc(x: f64)           -> f64    ---
	sqrtf        :: proc(x: f32)           -> f32    ---
	tan          :: proc(x: f64)           -> f64    ---
	tanf         :: proc(x: f32)           -> f32    ---
}

iconv_data_t :: struct{}
iconv_t :: ^iconv_data_t


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	iconv_open   :: proc(tocode: cstring) -> iconv_t ---
	iconv_close  :: proc(cd: iconv_t)     -> c.int ---
	iconv        :: proc(cd: iconv_t, inbuf: ^cstring, inbytesleft: ^uint, outbuf: ^[^]u8, outbytesleft: ^uint) -> uint    ---
	iconv_string :: proc(tocode: cstring, fromcode: cstring, inbuf: cstring, inbytesleft: uint)                 -> [^]byte ---
}

ICONV_ERROR  :: transmute(uint)int(-1)  /**< Generic error. Check SDL_GetError()? */
ICONV_E2BIG  :: transmute(uint)int(-2)  /**< Output buffer was too small. */
ICONV_EILSEQ :: transmute(uint)int(-3)  /**< Invalid input sequence was encountered. */
ICONV_EINVAL :: transmute(uint)int(-4)  /**< Incomplete input sequence was encountered. */


@(require_results)
iconv_utf8_locale :: #force_inline proc "c" (S: cstring) -> [^]byte {
	return iconv_string("", "UTF-8", S, strlen(S)+1)
}

@(require_results)
iconv_utf8_ucs2 :: #force_inline proc "c" (S: cstring) -> [^]Uint16 {
	return cast([^]Uint16)iconv_string("UCS-2", "UTF-8", S, strlen(S)+1)
}

@(require_results)
iconv_utf8_ucs4 :: #force_inline proc "c" (S: cstring) -> [^]rune {
	return cast([^]rune)iconv_string("UCS-4", "UTF-8", S, strlen(S)+1)
}

@(require_results)
iconv_wchar_utf8 :: #force_inline proc "c" (S: [^]wchar_t) -> [^]byte {
	return iconv_string("UTF-8", "WCHAR_T", cstring(([^]u8)(S)), (wcslen(S)+1)*size_of(wchar_t))
}


@(require_results)
size_mul_check_overflow_ptr :: #force_inline proc "c" (a, b: uint, ret: ^uint) -> bool {
	if a != 0 && b > SIZE_MAX / a {
		return false
	}
	ret^ = a * b
	return true
}
@(require_results)
size_mul_check_overflow :: #force_inline proc "c" (a, b: uint, ret: ^uint) -> (uint, bool) {
	return a * b, !(a != 0 && b > SIZE_MAX / a)
}


@(require_results)
size_add_check_overflow_ptr :: #force_inline proc "c" (a, b: uint, ret: ^uint) -> bool {
	if b > SIZE_MAX - a {
		return false
	}
	ret^ = a + b
	return true
}
@(require_results)
size_add_check_overflow :: #force_inline proc "c" (a, b: uint) -> (uint, bool) {
	return a + b, !(b > SIZE_MAX - a)
}


FunctionPointer :: #type proc "c" ()