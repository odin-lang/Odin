//+private
package os2

import "core:runtime"
import win32 "core:sys/windows"

_create_temp :: proc(dir, pattern: string) -> (^File, Error) {
	return nil, nil
}

_mkdir_temp :: proc(dir, pattern: string, allocator: runtime.Allocator) -> (string, Error) {
	return "", nil
}

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	n := win32.GetTempPathW(0, nil)
	if n == 0 {
		return "", nil
	}
	b := make([]u16, max(win32.MAX_PATH, n), _temp_allocator())
	n = win32.GetTempPathW(u32(len(b)), raw_data(b))

	if n == 3 && b[1] == ':' && b[2] == '\\' {

	} else if n > 0 && b[n-1] == '\\' {
		n -= 1
	}
	return win32.utf16_to_utf8(b[:n], allocator)
}
