package libc

// 7.16 Variable arguments

import "base:intrinsics"

import "core:c"

@(private="file")
@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.va_start") _va_start :: proc(arglist: ^i8) ---
	@(link_name="llvm.va_end")   _va_end   :: proc(arglist: ^i8) ---
	@(link_name="llvm.va_copy")  _va_copy  :: proc(dst, src: ^i8) ---
}

va_list :: c.va_list

va_start :: #force_inline proc(ap: ^va_list, _: any) {
	_va_start(cast(^i8)ap)
}

va_end :: #force_inline proc(ap: ^va_list) {
	_va_end(cast(^i8)ap)
}

va_copy :: #force_inline proc(dst, src: ^va_list) {
	_va_copy(cast(^i8)dst, cast(^i8)src)
}

// We cannot provide va_arg as there is no way to create "C" style procedures
// in Odin which take variable arguments the C way. The #c_vararg attribute only
// exists for foreign imports. That being said, being able to copy a va_list,
// as well as start and end one is necessary in some functions, the va_list
// taking functions in libc as an example.
