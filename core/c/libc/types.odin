package libc

import "core:c"

#assert(!ODIN_NO_CRT, `"core:c/libc" cannot be imported when '-no-crt' is used`)

char           :: c.char // assuming -funsigned-char

schar          :: c.schar
short          :: c.short
int            :: c.int
long           :: c.long
longlong       :: c.longlong

uchar          :: c.uchar
ushort         :: c.ushort
uint           :: c.uint
ulong          :: c.ulong
ulonglong      :: c.ulonglong

bool           :: c.bool

size_t         :: c.size_t
ssize_t        :: c.ssize_t
wchar_t        :: c.wchar_t

float          :: c.float
double         :: c.double

int8_t         :: c.int8_t
uint8_t        :: c.uint8_t
int16_t        :: c.int16_t
uint16_t       :: c.uint16_t
int32_t        :: c.int32_t
uint32_t       :: c.uint32_t
int64_t        :: c.int64_t
uint64_t       :: c.uint64_t

int_least8_t   :: c.int_least8_t
uint_least8_t  :: c.uint_least8_t
int_least16_t  :: c.int_least16_t
uint_least16_t :: c.uint_least16_t
int_least32_t  :: c.int_least32_t
uint_least32_t :: c.uint_least32_t
int_least64_t  :: c.int_least64_t
uint_least64_t :: c.uint_least64_t

int_fast8_t    :: c.int_fast8_t
uint_fast8_t   :: c.uint_fast8_t
int_fast16_t   :: c.int_fast16_t
uint_fast16_t  :: c.uint_fast16_t
int_fast32_t   :: c.int_fast32_t
uint_fast32_t  :: c.uint_fast32_t
int_fast64_t   :: c.int_fast64_t
uint_fast64_t  :: c.uint_fast64_t

intptr_t       :: c.intptr_t
uintptr_t      :: c.uintptr_t
ptrdiff_t      :: c.ptrdiff_t

intmax_t       :: c.intmax_t
uintmax_t      :: c.uintmax_t

// Copy C's rules for type promotion here by forcing the type on the literals.
INT8_MAX       :: c.INT8_MAX
INT16_MAX      :: c.INT16_MAX
INT32_MAX      :: c.INT32_MAX
INT64_MAX      :: c.INT64_MAX

UINT8_MAX      :: c.UINT8_MAX
UINT16_MAX     :: c.UINT16_MAX
UINT32_MAX     :: c.UINT32_MAX
UINT64_MAX     :: c.UINT64_MAX

INT8_MIN       :: c.INT8_MIN
INT16_MIN      :: c.INT16_MIN
INT32_MIN      :: c.INT32_MIN
INT64_MIN      :: c.INT64_MIN

SIZE_MAX       :: c.SIZE_MAX

PTRDIFF_MIN    :: c.PTRDIFF_MIN
PTRDIFF_MAX    :: c.PTRDIFF_MAX

WCHAR_MIN      :: c.WCHAR_MIN
WCHAR_MAX      :: c.WCHAR_MAX

NULL           :: rawptr(uintptr(0))

NDEBUG         :: !ODIN_DEBUG

CHAR_BIT :: 8
