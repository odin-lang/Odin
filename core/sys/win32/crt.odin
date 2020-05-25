package win32

import "core:strings";

foreign {
	_wgetcwd :: proc(buffer: LPCWSTR, buf_len: int) ->  ^LPCWSTR ---
}
_get_cwd_wide :: _wgetcwd;

get_cwd :: proc(allocator := context.temp_allocator) -> string {
	buffer := make([]u16, MAX_PATH_WIDE, allocator);
	_get_cwd_wide(LPCWSTR(&buffer[0]), MAX_PATH_WIDE);
	file := utf16_to_utf8(buffer[:], allocator);
	return strings.trim_right_null(file);
}
