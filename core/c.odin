CHAR_BIT :: 8;

c_bool   :: #alias bool;
c_char   :: #alias u8;
c_byte   :: #alias u8;
c_schar  :: #alias i8;
c_uchar  :: #alias u8;
c_short  :: #alias i16;
c_ushort :: #alias u16;
c_int    :: #alias i32;
c_uint   :: #alias u32;

when ODIN_OS == "windows" || size_of(rawptr) == 4 {
	c_long :: #alias i32;
} else {
	c_long :: #alias i64;
}

when ODIN_OS == "windows" || size_of(rawptr) == 4 {
	c_ulong :: #alias u32;
} else {
	c_ulong :: #alias u64;
}

c_longlong       :: #alias i64;
c_ulonglong      :: #alias u64;
c_float          :: #alias f32;
c_double         :: #alias f64;
c_complex_float  :: #alias complex64;
c_complex_double :: #alias complex128;

_ :: compile_assert(size_of(uintptr) == size_of(int));

c_size_t    :: #alias uint;
c_ssize_t   :: #alias int;
c_ptrdiff_t :: #alias int;
c_uintptr_t :: #alias uintptr;
c_intptr_t  :: #alias int;
