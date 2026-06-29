package odin_libc

import "base:runtime"

@(require, linkage="strong", link_name="__odin_libc_assert_fail")
__odin_libc_assert_fail :: proc "c" (func: cstring, file: cstring, line: i32, expr: cstring) -> ! {
	context = g_ctx
	loc := runtime.Source_Code_Location{
		file_path = string(file),
		line      = line,
		column    = 0,
		procedure = string(func),
	}
	context.assertion_failure_proc("runtime assertion", string(expr), loc)
}
