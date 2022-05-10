//+private
package os2

import win32 "core:sys/windows"

_create_temp :: proc(dir, pattern: string) -> (^File, Error) {
	return nil, nil
}

_mkdir_temp :: proc(dir, pattern: string, allocator := context.allocator) -> (string, Error) {
	return "", nil
}

_temp_dir :: proc(allocator := context.allocator) -> string {
	b := make([dynamic]u16, u32(win32.MAX_PATH), context.temp_allocator)
	for {
		n := win32.GetTempPathW(u32(len(b)), raw_data(b))
		if n > u32(len(b)) {
			resize(&b, int(n))
			continue
		}
		if n == 3 && b[1] == ':' && b[2] == '\\' {

		} else if n > 0 && b[n-1] == '\\' {
			n -= 1
		}
		return win32.utf16_to_utf8(b[:n], allocator)
	}
}
