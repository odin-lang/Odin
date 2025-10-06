#+private
package os2

import "base:runtime"
import win32 "core:sys/windows"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	n := win32.GetTempPathW(0, nil)
	if n == 0 {
		return "", nil
	}
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	b := make([]u16, max(win32.MAX_PATH, n), temp_allocator)
	n = win32.GetTempPathW(u32(len(b)), cstring16(raw_data(b)))

	if n == 3 && b[1] == ':' && b[2] == '\\' {

	} else if n > 0 && b[n-1] == '\\' {
		n -= 1
	}
	return win32_utf16_to_utf8(string16(b[:n]), allocator)
}
