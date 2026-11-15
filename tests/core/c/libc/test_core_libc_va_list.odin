package test_core_libc

import "base:intrinsics"
import "core:c/libc"
import "core:testing"

@(private="file")
format :: proc "c" (buf: []u8, fmt: cstring, #c_vararg args: ..any) -> libc.int {
	list: libc.va_list
	libc.va_start(&list, args)
	defer libc.va_end(&list)
	return libc.vsnprintf(raw_data(buf), libc.size_t(len(buf)), fmt, &list)
}

@(private="file")
scan :: proc "c" (s, fmt: cstring, #c_vararg args: ..any) -> libc.int {
	list: libc.va_list
	libc.va_start(&list, args)
	defer libc.va_end(&list)
	return libc.vsscanf(s, fmt, &list)
}

@(test)
test_vsnprintf :: proc(t: ^testing.T) {
	buf: [64]u8
	n := format(buf[:], "%d %s %.3f %c", i32(42), cstring("str"), f64(3.14159), i32('Z'))
	testing.expect_value(t, n, 14)
	testing.expect_value(t, string(buf[:int(n)]), "42 str 3.142 Z")
}

@(test)
test_vsscanf :: proc(t: ^testing.T) {
	a: i32
	b: f64
	n := scan("17 2.5", "%d %lf", &a, &b)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, a, 17)
	testing.expect_value(t, b, 2.5)
}
