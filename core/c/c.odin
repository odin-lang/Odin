package c

import builtin "base:builtin"

char           :: builtin.u8  // assuming -funsigned-char

schar          :: builtin.i8
short          :: builtin.i16
int            :: builtin.i32
long           :: builtin.i32 when (ODIN_OS == .Windows || size_of(builtin.rawptr) == 4) else builtin.i64
longlong       :: builtin.i64

uchar          :: builtin.u8
ushort         :: builtin.u16
uint           :: builtin.u32
ulong          :: builtin.u32 when (ODIN_OS == .Windows || size_of(builtin.rawptr) == 4) else builtin.u64
ulonglong      :: builtin.u64

bool           :: builtin.bool

size_t         :: builtin.uint
ssize_t        :: builtin.int
wchar_t        :: builtin.u16 when (ODIN_OS == .Windows) else builtin.u32

float          :: builtin.f32
double         :: builtin.f64
complex_float  :: builtin.complex64
complex_double :: builtin.complex128

// 7.20.1 Integer types
int8_t         :: builtin.i8
uint8_t        :: builtin.u8
int16_t        :: builtin.i16
uint16_t       :: builtin.u16
int32_t        :: builtin.i32
uint32_t       :: builtin.u32
int64_t        :: builtin.i64
uint64_t       :: builtin.u64

// These are all the same in multiple libc's for multiple architectures.
int_least8_t   :: builtin.i8
uint_least8_t  :: builtin.u8
int_least16_t  :: builtin.i16
uint_least16_t :: builtin.u16
int_least32_t  :: builtin.i32
uint_least32_t :: builtin.u32
int_least64_t  :: builtin.i64
uint_least64_t :: builtin.u64

// Same on Windows, Linux, and FreeBSD
when ODIN_ARCH == .i386 || ODIN_ARCH == .amd64 {
	int_fast8_t    :: builtin.i8
	uint_fast8_t   :: builtin.u8
	int_fast16_t   :: builtin.i32
	uint_fast16_t  :: builtin.u32
	int_fast32_t   :: builtin.i32
	uint_fast32_t  :: builtin.u32
	int_fast64_t   :: builtin.i64
	uint_fast64_t  :: builtin.u64
} else {
	int_fast8_t    :: builtin.i8
	uint_fast8_t   :: builtin.u8
	int_fast16_t   :: builtin.i16
	uint_fast16_t  :: builtin.u16
	int_fast32_t   :: builtin.i32
	uint_fast32_t  :: builtin.u32
	int_fast64_t   :: builtin.i64
	uint_fast64_t  :: builtin.u64
}

intptr_t       :: builtin.int
uintptr_t      :: builtin.uintptr
ptrdiff_t      :: distinct intptr_t

intmax_t       :: builtin.i64
uintmax_t      :: builtin.u64

// Copy C's rules for type promotion here by forcing the type on the literals.
INT8_MAX       :: int(0x7f)
INT16_MAX      :: int(0x7fff)
INT32_MAX      :: int(0x7fffffff)
INT64_MAX      :: longlong(0x7fffffffffffffff)

UINT8_MAX      :: int(0xff)
UINT16_MAX     :: int(0xffff)
UINT32_MAX     :: uint(0xffffffff)
UINT64_MAX     :: ulonglong(0xffffffffffffffff)

INT8_MIN       :: ~INT8_MAX
INT16_MIN      :: ~INT16_MAX
INT32_MIN      :: ~INT32_MAX
INT64_MIN      :: ~INT64_MAX

SIZE_MAX       :: max(size_t)

PTRDIFF_MIN    :: min(ptrdiff_t)
PTRDIFF_MAX    :: max(ptrdiff_t)

WCHAR_MIN      :: min(wchar_t)
WCHAR_MAX      :: max(wchar_t)

NULL           :: rawptr(uintptr(0))

NDEBUG         :: !ODIN_DEBUG

CHAR_BIT :: 8

// Since there are no types in C with an alignment larger than that of
// max_align_t, which cannot be larger than sizeof(long double) as any other
// exposed type wouldn't be valid C, the maximum alignment possible in a
// strictly conformant C implementation is 16 on the platforms we care about.
// The choice of 4096 bytes for storage of this type is more than enough on all
// relevant platforms.
va_list :: struct #align(16) {
	_: [4096]u8,
}

FILE :: struct {}
