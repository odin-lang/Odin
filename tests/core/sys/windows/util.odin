#+build windows
package test_core_sys_windows

import "base:intrinsics"
import "core:testing"
import win32 "core:sys/windows"

UTF16_Vector :: struct {
	wstr: win32.wstring,
	ustr: string,
}

utf16_vectors := []UTF16_Vector{
	{
		intrinsics.constant_utf16_cstring("Hellope, World!"),
		"Hellope, World!",
	},
	{
		intrinsics.constant_utf16_cstring("Hellope\x00, World!"),
		"Hellope",
	},
}

@(test)
utf16_to_utf8_buf_test :: proc(t: ^testing.T) {
	for test in utf16_vectors {
		buf := make([]u8, len(test.ustr))
		defer delete(buf)

		res := win32.utf16_to_utf8_buf(buf[:], test.wstr[:len(test.ustr)])
		testing.expect_value(t, res, test.ustr)
	}
}