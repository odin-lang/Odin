//+private
package os2

import win32 "core:sys/windows"
import "base:runtime"
import "core:strings"

_Path_Separator      :: '\\'
_Path_List_Separator :: ';'

_is_path_separator :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

_mkdir :: proc(name: string, perm: File_Mode) -> Error {
	if !win32.CreateDirectoryW(_fix_long_path(name), nil) {
		return _get_platform_error()
	}
	return nil
}

_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	fix_root_directory :: proc(p: string) -> (s: string, allocated: bool, err: runtime.Allocator_Error) {
		if len(p) == len(`\\?\c:`) {
			if is_path_separator(p[0]) && is_path_separator(p[1]) && p[2] == '?' && is_path_separator(p[3]) && p[5] == ':' {
				s = strings.concatenate({p, `\`}, _file_allocator()) or_return
				allocated = true
				return
			}
		}
		return p, false, nil
	}

	_TEMP_ALLOCATOR_GUARD()

	dir, err := stat(path, _temp_allocator())
	if err == nil {
		if dir.is_directory {
			return nil
		}
		return .Exist
	}

	i := len(path)
	for i > 0 && is_path_separator(path[i-1]) {
		i -= 1
	}

	j := i
	for j > 0 && !is_path_separator(path[j-1]) {
		j -= 1
	}

	if j > 1 {
		new_path, allocated := fix_root_directory(path[:j-1]) or_return
		defer if allocated {
			delete(new_path, _file_allocator())
		}
		mkdir_all(new_path, perm) or_return
	}

	err = mkdir(path, perm)
	if err != nil {
		dir1, err1 := lstat(path, _temp_allocator())
		if err1 == nil && dir1.is_directory {
			return nil
		}
		return err
	}
	return nil
}

_remove_all :: proc(path: string) -> Error {
	// TODO(bill): _remove_all for windows
	return nil
}

_getwd :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	// TODO(bill)
	return "", nil
}

_setwd :: proc(dir: string) -> (err: Error) {
	// TODO(bill)
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

	_TEMP_ALLOCATOR_GUARD()

	PREFIX :: `\\?`
	path_buf := make([]byte, len(PREFIX)+len(path)+1, _temp_allocator())
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
