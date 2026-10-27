package libc

// 7.16 Variable arguments

import "base:intrinsics"

va_list  :: intrinsics.c_va_list

va_start :: intrinsics.c_va_start
va_end   :: intrinsics.c_va_end
va_copy  :: intrinsics.c_va_copy

// C passes a va_list by value. On x86-64 System V it is an array, which decays to a pointer
// to its first element; everywhere else the value itself is passed.
when ODIN_ARCH == .amd64 && ODIN_OS != .Windows {
	@(private) va_list_arg :: ^va_list
} else {
	@(private) va_list_arg :: va_list
}

// The va_list argument for a C function, from the pointer the v* procedures here take.
@(private)
va_list_arg_from :: #force_inline proc "contextless" (arg: ^va_list) -> va_list_arg {
	when ODIN_ARCH == .amd64 && ODIN_OS != .Windows {
		return arg
	} else {
		return arg^
	}
}


// We cannot provide va_arg as there is no way to create "C" style procedures
// in Odin which take variable arguments the C way. The #c_vararg attribute only
// exists for foreign imports. That being said, being able to copy a va_list,
// as well as start and end one is necessary in some functions, the va_list
// taking functions in libc as an example.
