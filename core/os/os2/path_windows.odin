//+private
package os2

import win32 "core:sys/windows"

_Path_Separator      :: '\\'
_Path_List_Separator :: ';'

_is_path_separator :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

_mkdir :: proc(name: string, perm: File_Mode) -> Error {
	return nil
}

_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	// TODO(bill): _mkdir_all for windows
	return nil
}

_remove_all :: proc(path: string) -> Error {
	// TODO(bill): _remove_all for windows
	return nil
}

_getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
	return "", nil
}

_setwd :: proc(dir: string) -> (err: Error) {
	return nil
}


can_use_long_paths: bool

@(init)
init_long_path_support :: proc() {
	// TODO(bill): init_long_path_support
	// ADD THIS SHIT
	// registry_path := win32.L(`Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled`)
	can_use_long_paths = false
}


_fix_long_path_slice :: proc(path: string) -> []u16 {
	return win32.utf8_to_utf16(_fix_long_path_internal(path))
}

_fix_long_path :: proc(path: string) -> win32.wstring {
	return win32.utf8_to_wstring(_fix_long_path_internal(path))
}


_fix_long_path_internal :: proc(path: string) -> string {
	if can_use_long_paths {
		return path
	}

	// When using win32 to create a directory, the path
	// cannot be too long that you cannot append an 8.3
	// file name, because MAX_PATH is 260, 260-12 = 248
	if len(path) < 248 {
		return path
	}

	// UNC paths do not need to be modified
	if len(path) >= 2 && path[:2] == `\\` {
		return path
	}

	if !_is_abs(path) { // relative path
		return path
	}

	PREFIX :: `\\?`
	path_buf := make([]byte, len(PREFIX)+len(path)+1, context.temp_allocator)
	copy(path_buf, PREFIX)
	n := len(path)
	r, w := 0, len(PREFIX)
	for r < n {
		switch {
		case is_path_separator(path[r]):
			r += 1
		case path[r] == '.' && (r+1 == n || is_path_separator(path[r+1])):
			// \.\
			r += 1
		case r+1 < n && path[r] == '.' && path[r+1] == '.' && (r+2 == n || is_path_separator(path[r+2])):
			// Skip \..\ paths
			return path
		case:
			path_buf[w] = '\\'
			w += 1
			for r < n && !is_path_separator(path[r]) {
				path_buf[w] = path[r]
				r += 1
				w += 1
			}
		}
	}

	// Root directories require a trailing \
	if w == len(`\\?\c:`) {
		path_buf[w] = '\\'
		w += 1
	}

	return string(path_buf[:w])

}
