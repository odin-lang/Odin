//+private
package os2

import win32 "core:sys/windows"
import "base:runtime"

_Path_Separator        :: '\\'
_Path_Separator_String :: "\\"
_Path_List_Separator   :: ';'

_is_path_separator :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

_mkdir :: proc(name: string, perm: int) -> Error {
	if !win32.CreateDirectoryW(_fix_long_path(name) or_return, nil) {
		return _get_platform_error()
	}
	return nil
}

_mkdir_all :: proc(path: string, perm: int) -> Error {
	fix_root_directory :: proc(p: string) -> (s: string, allocated: bool, err: runtime.Allocator_Error) {
		if len(p) == len(`\\?\c:`) {
			if is_path_separator(p[0]) && is_path_separator(p[1]) && p[2] == '?' && is_path_separator(p[3]) && p[5] == ':' {
				s = concatenate({p, `\`}, file_allocator()) or_return
				allocated = true
				return
			}
		}
		return p, false, nil
	}

	TEMP_ALLOCATOR_GUARD()

	dir_stat, err := stat(path, temp_allocator())
	if err == nil {
		if dir_stat.type == .Directory {
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
			delete(new_path, file_allocator())
		}
		mkdir_all(new_path, perm) or_return
	}

	err = mkdir(path, perm)
	if err != nil {
		new_dir_stat, err1 := lstat(path, temp_allocator())
		if err1 == nil && new_dir_stat.type == .Directory {
			return nil
		}
		return err
	}
	return nil
}

_remove_all :: proc(path: string) -> Error {
	if path == "" {
		return nil
	}


	err := remove(path)
	if err == nil || err == .Not_Exist {
		return nil
	}

	TEMP_ALLOCATOR_GUARD()
	dir, serr := stat_do_not_follow_links(path, temp_allocator())
	if serr != nil {
		if serr == .Not_Exist || serr == .Invalid_Dir {
			return nil
		}
		return serr
	}
	if dir.type != .Directory {
		return err
	}

	err = nil
	remove_contents: {
		f: ^File
		f, err = open(path)
		if err != nil {
			if err == .Not_Exist {
				return nil
			}
			return err
		}

		files, read_err := read_all_directory(f, temp_allocator())
		for file in files {
			err1 := remove_all(file.fullpath)
			if err == nil {
				err = err1
			}
		}
		close(f)

		if read_err == .EOF {
			break remove_contents
		}

		if err == nil {
			err = read_err
		}
		if len(files) == 0 {
			break remove_contents
		}
	}

	err1 := remove(path)
	if err1 == nil || err1 == .Not_Exist {
		return nil
	}

	if ODIN_OS == .Windows && err1 == .Permission_Denied {
		if fi, err2 := stat(path, temp_allocator()); err2 == nil {
			if err2 = chmod(path, 0o200|fi.mode); err2 == nil {
				err1 = remove(path)
			}
		}
	}
	if err == nil {
		err = err1
	}
	return err
}

@private cwd_lock: win32.SRWLOCK // zero is initialized

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	win32.AcquireSRWLockExclusive(&cwd_lock)

	TEMP_ALLOCATOR_GUARD()

	sz_utf16 := win32.GetCurrentDirectoryW(0, nil)
	dir_buf_wstr := make([]u16, sz_utf16, temp_allocator()) or_return

	sz_utf16 = win32.GetCurrentDirectoryW(win32.DWORD(len(dir_buf_wstr)), raw_data(dir_buf_wstr))
	assert(int(sz_utf16)+1 == len(dir_buf_wstr)) // the second time, it _excludes_ the NUL.

	win32.ReleaseSRWLockExclusive(&cwd_lock)

	return win32_utf16_to_utf8(dir_buf_wstr, allocator)
}

_set_working_directory :: proc(dir: string) -> (err: Error) {
	TEMP_ALLOCATOR_GUARD()
	wstr := win32_utf8_to_wstring(dir, temp_allocator()) or_return

	win32.AcquireSRWLockExclusive(&cwd_lock)

	if !win32.SetCurrentDirectoryW(wstr) {
		err = _get_platform_error()
	}

	win32.ReleaseSRWLockExclusive(&cwd_lock)

	return
}

can_use_long_paths: bool

@(init)
init_long_path_support :: proc() {
	// TODO(bill): init_long_path_support
	// ADD THIS SHIT
	// registry_path := win32.L(`Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled`)
	can_use_long_paths = false
}

@(require_results)
_fix_long_path_slice :: proc(path: string) -> ([]u16, runtime.Allocator_Error) {
	return win32_utf8_to_utf16(_fix_long_path_internal(path), temp_allocator())
}

@(require_results)
_fix_long_path :: proc(path: string) -> (win32.wstring, runtime.Allocator_Error) {
	return win32_utf8_to_wstring(_fix_long_path_internal(path), temp_allocator())
}

@(require_results)
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

	TEMP_ALLOCATOR_GUARD()

	PREFIX :: `\\?`
	path_buf := make([]byte, len(PREFIX)+len(path)+1, temp_allocator())
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
