CHAR_BIT :: 8;

c_bool           :: bool;

c_char           :: u8;

c_schar          :: i8;
c_uchar          :: i8;

c_short          :: i16;
c_ushort         :: i16;

c_int            :: i32;
c_uint           :: u32;

c_long  :: ODIN_OS == "windows" ?
	i32 :
	(size_of(int) == 4) ?
		i32 :
		i64;

c_ulong :: ODIN_OS == "windows" ?
	u32 :
	(size_of(int) == 4) ?
		u32 :
		u64;

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
