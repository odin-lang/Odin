package libc

// 7.16 Variable arguments

import "base:intrinsics"

va_list :: intrinsics.va_list

va_start :: intrinsics.va_start
va_end   :: intrinsics.va_end
va_copy  :: intrinsics.va_copy


// We cannot provide va_arg as there is no way to create "C" style procedures
// in Odin which take variable arguments the C way. The #c_vararg attribute only
// exists for foreign imports. That being said, being able to copy a va_list,
// as well as start and end one is necessary in some functions, the va_list
// taking functions in libc as an example.
