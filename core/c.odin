CHAR_BIT :: 8;

c_bool           :: bool;

c_char           :: u8;

c_schar          :: i8;
c_uchar          :: i8;

c_short          :: i16;
c_ushort         :: i16;

c_int            :: i32;
c_uint           :: u32;

when ODIN_OS == "windows" || size_of(int) == 4 {
	c_long :: i32;
} else {
	c_long :: i64;
}

when ODIN_OS == "windows" || size_of(uint) == 4 {
	c_ulong :: u32;
} else {
	c_ulong :: u64;
}

c_longlong       :: i64;
c_ulonglong      :: u64;

c_float          :: f32;
c_double         :: f64;

c_complex_float  :: complex64;
c_complex_double :: complex128;

c_size_t         :: uint;
c_ssize_t        :: int;
c_ptrdiff_t      :: int;
c_uintptr_t      :: uint;
c_intptr_t       :: int;
