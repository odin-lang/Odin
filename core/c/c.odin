package c

import "core:os"

CHAR_BIT :: 8;

c_bool   :: bool;
c_char   :: u8;
c_byte   :: u8;
c_schar  :: i8;
c_uchar  :: u8;
c_short  :: i16;
c_ushort :: u16;
c_int    :: i32;
c_uint   :: u32;

c_long  :: (os.OS == "windows" || size_of(rawptr) == 4) ? i32 : i64;
c_ulong :: (os.OS == "windows" || size_of(rawptr) == 4) ? u32 : u64;

c_longlong       :: i64;
c_ulonglong      :: u64;
c_float          :: f32;
c_double         :: f64;
c_complex_float  :: complex64;
c_complex_double :: complex128;

#assert(size_of(uintptr) == size_of(int));

c_size_t    :: uint;
c_ssize_t   :: int;
c_ptrdiff_t :: int;
c_uintptr_t :: uintptr;
c_intptr_t  :: int;
