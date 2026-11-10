#+private
package os

import "base:runtime"
import "core:strings"
import win32 "core:sys/windows"

_Path_Separator        :: '\\'
_Path_Separator_String :: "\\"
_Path_List_Separator   :: ';'

_is_path_separator :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

_mkdir :: proc(name: string, perm: Permissions) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	if !win32.CreateDirectoryW(_fix_long_path(name, temp_allocator) or_return, nil) {
		return _get_platform_error()
	}
	return nil
}

_mkdir_all :: proc(path: string, perm: Permissions) -> Error {
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

	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	dir_stat, err := stat(path, temp_allocator)
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
		new_dir_stat, err1 := lstat(path, temp_allocator)
		if err1 == nil && new_dir_stat.type == .Directory {
			return nil
		}
		return err
	}
	return nil
}

_Remove_All_Dir :: []u16

// The only UTF-8 to UTF-16 conversion in remove_all; the walk stays in UTF-16 so names that are not valid UTF-16, which NTFS allows, are still removed.
_remove_all_root :: proc(path: string, allocator: runtime.Allocator) -> (parent: _Remove_All_Dir, name: []u8, err: Error) {
	wide := win32_utf8_to_utf16(path, allocator) or_return
	if len(wide) == 0 {
		return nil, nil, .Invalid_Path
	}

	full: []u16
	n := win32.GetFullPathNameW(cstring16(raw_data(wide)), 0, nil, nil)
	for {
		if n == 0 {
			return nil, nil, _get_platform_error()
		}
		full = make([]u16, n, allocator) or_return
		n = win32.GetFullPathNameW(cstring16(raw_data(wide)), n, cstring16(raw_data(full)), nil)
		if n != 0 && int(n) < len(full) {
			break
		}
	}
	full = full[:n]
	for len(full) > 1 && _remove_all_is_separator(full[len(full)-1]) && full[len(full)-2] != ':' {
		full = full[:len(full)-1]
	}

	is_device := len(full) >= 4 && _remove_all_is_separator(full[0]) && _remove_all_is_separator(full[1]) && (full[2] == '?' || full[2] == '.') && _remove_all_is_separator(full[3])
	if !is_device {
		is_unc := len(full) >= 2 && _remove_all_is_separator(full[0]) && _remove_all_is_separator(full[1])
		prefix := [8]u16{'\\', '\\', '?', '\\', 'U', 'N', 'C', '\\'}
		prefix_len := 8 if is_unc else 4
		rest := full[2:] if is_unc else full
		extended := make([]u16, prefix_len + len(rest), allocator) or_return
		copy(extended, prefix[:prefix_len])
		copy(extended[prefix_len:], rest)
		full = extended
	}
	return nil, ([^]u8)(raw_data(full))[:len(full) * size_of(u16)], nil
}

_remove_all_open :: proc(parent: _Remove_All_Dir, name: []u8) -> (dir: _Remove_All_Dir, is_dir: bool, err: Error) {
	path := _remove_all_join(parent, name, file_allocator()) or_return
	defer if !is_dir {
		delete(path, file_allocator())
	}
	wpath := cstring16(raw_data(path))
	handle := win32.CreateFileW(
		wpath,
		win32.FILE_READ_ATTRIBUTES,
		win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_FLAG_BACKUP_SEMANTICS | win32.FILE_FLAG_OPEN_REPARSE_POINT,
		nil,
	)
	if handle == win32.INVALID_HANDLE_VALUE {
		err = _get_platform_error()
		if err != .Not_Exist && _remove_wstring(wpath) == nil {
			err = nil
		}
		return
	}

	info: win32.FILE_ATTRIBUTE_TAG_INFO
	info_ok := win32.GetFileInformationByHandleEx(handle, .FileAttributeTagInfo, &info, size_of(info))
	if !info_ok {
		err = _get_platform_error()
	}
	win32.CloseHandle(handle)
	if !info_ok {
		return
	}

	if !_remove_all_is_directory(info.FileAttributes, info.ReparseTag) {
		err = _remove_wstring(wpath)
		return
	}
	return path, true, nil
}

// Entry names are stored as raw UTF-16 code units; converting them to UTF-8 would lose unpaired surrogates.
_remove_all_read :: proc(dir: _Remove_All_Dir, names: ^[dynamic]u8, entries: ^[dynamic]_Remove_All_Entry) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	star := u16('*')
	search := _remove_all_join(dir, ([^]u8)(&star)[:size_of(star)], temp_allocator) or_return
	find_data: win32.WIN32_FIND_DATAW
	find_handle := win32.FindFirstFileW(cstring16(raw_data(search)), &find_data)
	if find_handle == win32.INVALID_HANDLE_VALUE {
		return _get_platform_error()
	}
	defer win32.FindClose(find_handle)

	for {
		units := find_data.cFileName[:]
		n := 0
		for n < len(units) && units[n] != 0 {
			n += 1
		}
		is_dot     := n == 1 && units[0] == '.'
		is_dot_dot := n == 2 && units[0] == '.' && units[1] == '.'
		if !is_dot && !is_dot_dot {
			kind := _Remove_All_Kind.Other
			if _remove_all_is_directory(find_data.dwFileAttributes, find_data.dwReserved0) {
				kind = .Directory
			}
			_remove_all_add(names, entries, ([^]u8)(raw_data(units))[:n * size_of(u16)], kind) or_return
		}
		if !win32.FindNextFileW(find_handle, &find_data) {
			next_err := _get_platform_error()
			if pe, _ := is_platform_error(next_err); pe == i32(win32.ERROR_NO_MORE_FILES) {
				return nil
			}
			return next_err
		}
	}
}

_remove_all_unlink :: proc(parent: _Remove_All_Dir, name: []u8, _: _Remove_All_Kind) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	path := _remove_all_join(parent, name, temp_allocator) or_return
	return _remove_wstring(cstring16(raw_data(path)))
}

_remove_all_close :: proc(dir: _Remove_All_Dir) {
	delete(dir, file_allocator())
}

@(private="file")
_remove_all_is_directory :: proc(attributes, reparse_tag: u32) -> bool {
	if attributes & win32.FILE_ATTRIBUTE_DIRECTORY == 0 {
		return false
	}
	return attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT == 0 || !win32.IsReparseTagNameSurrogate(reparse_tag)
}

@(private="file")
_remove_all_is_separator :: proc(c: u16) -> bool {
	return c == '\\' || c == '/'
}

@(private="file")
// `name` holds UTF-16 code units as bytes and may be unaligned, so it is copied bytewise; the result is NUL-terminated past its length.
_remove_all_join :: proc(parent: []u16, name: []u8, allocator: runtime.Allocator) -> (path: []u16, err: runtime.Allocator_Error) {
	separator := 0
	if len(parent) > 0 && !_remove_all_is_separator(parent[len(parent)-1]) {
		separator = 1
	}
	units := len(name) / size_of(u16)
	path = make([]u16, len(parent) + separator + units + 1, allocator) or_return
	copy(path, parent)
	if separator == 1 {
		path[len(parent)] = '\\'
	}
	runtime.mem_copy_non_overlapping(raw_data(path[len(parent) + separator:]), raw_data(name), units * size_of(u16))
	return path[:len(path) - 1], nil
}

@private cwd_lock: win32.SRWLOCK // zero is initialized

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	win32.AcquireSRWLockExclusive(&cwd_lock)

	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	sz_utf16 := win32.GetCurrentDirectoryW(0, nil)
	dir_buf_wstr := make([]u16, sz_utf16, temp_allocator) or_return

	sz_utf16 = win32.GetCurrentDirectoryW(win32.DWORD(len(dir_buf_wstr)), raw_data(dir_buf_wstr))
	assert(int(sz_utf16)+1 == len(dir_buf_wstr)) // the second time, it _excludes_ the NUL.

	win32.ReleaseSRWLockExclusive(&cwd_lock)

	return win32_utf16_to_utf8(dir_buf_wstr, allocator)
}

_set_working_directory :: proc(dir: string) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	wstr := win32_utf8_to_wstring(dir, temp_allocator) or_return

	win32.AcquireSRWLockExclusive(&cwd_lock)

	if !win32.SetCurrentDirectoryW(wstr) {
		err = _get_platform_error()
	}

	win32.ReleaseSRWLockExclusive(&cwd_lock)

	return
}

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	buf := make([dynamic]u16, 512, temp_allocator) or_return
	for {
		ret := win32.GetModuleFileNameW(nil, raw_data(buf), win32.DWORD(len(buf)))
		if ret == 0 {
			err = _get_platform_error()
			return
		}

		if ret == win32.DWORD(len(buf)) && win32.GetLastError() == win32.ERROR_INSUFFICIENT_BUFFER {
			resize(&buf, len(buf)*2) or_return
			continue
		}

		return win32_utf16_to_utf8(buf[:ret], allocator)
	}
}


@(require_results)
_fix_long_path_slice :: proc(path: string, allocator: runtime.Allocator) -> ([]u16, runtime.Allocator_Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({allocator})
	return win32_utf8_to_utf16(_fix_long_path_internal(path, temp_allocator), allocator)
}

@(require_results)
_fix_long_path :: proc(path: string, allocator: runtime.Allocator) -> (win32.wstring, runtime.Allocator_Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({allocator})
	return win32_utf8_to_wstring(_fix_long_path_internal(path, temp_allocator), allocator)
}

@(require_results)
_fix_long_path_internal :: proc(path: string, allocator: runtime.Allocator) -> string {
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

	if !_is_absolute_path(path) { // relative path
		return path
	}

	PREFIX :: `\\?`
	path_buf := make([]byte, len(PREFIX)+len(path)+1, allocator)
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

_are_paths_identical :: strings.equal_fold

_clean_path_handle_start :: proc(path: string, buffer: []u8) -> (rooted: bool, start: int) {
	// Preserve rooted paths.
	start = _volume_name_len(path)
	if start > 0 {
		rooted = true
		if len(path) > start && _is_path_separator(path[start]) {
			// Take `C:` to `C:\`.
			start += 1
		}
		copy(buffer, path[:start])
		for n in 0..<start {
			if _is_path_separator(buffer[n]) {
				buffer[n] = _Path_Separator
			}
		}
	}
	return
}

_is_absolute_path :: proc(path: string) -> bool {
	if _is_reserved_name(path) {
		return true
	}
	if len(path) > 0 && _is_path_separator(path[0]) {
		return true
	}

	l := _volume_name_len(path)
	if l == 0 {
		return false
	}

	path := path
	path = path[l:]
	if path == "" {
		return false
	}
	return _is_path_separator(path[0])
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	rel := path
	if rel == "" {
		rel = "."
	}
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	rel_utf16 := win32.utf8_to_utf16(rel, temp_allocator)
	n := win32.GetFullPathNameW(cstring16(raw_data(rel_utf16)), 0, nil, nil)
	if n == 0 {
		return "", _get_platform_error()
	}

	buf := make([]u16, n, temp_allocator) or_return
	n = win32.GetFullPathNameW(cstring16(raw_data(rel_utf16)), u32(n), cstring16(raw_data(buf)), nil)
	if n == 0 {
		return "", _get_platform_error()
	}

	return win32.utf16_to_utf8(buf, allocator)
}

_get_relative_path_handle_start :: proc(base, target: string) -> bool {
	base_root   := base[:_volume_name_len(base)]
	target_root := target[:_volume_name_len(target)]
	return strings.equal_fold(base_root, target_root)
}

_get_common_path_len :: proc(base, target: string) -> int {
	i := 0
	end := min(len(base), len(target))
	for j in 0..=end {
		if j == end || _is_path_separator(base[j]) {
			if i < end && _is_path_separator(base[i]) && _is_path_separator(target[i]) {
				i += 1
			}
			if strings.equal_fold(base[i:j], target[i:j]) {
				i = j
			} else {
				break
			}
		}
	}
	return i
}

_split_path :: proc(path: string) -> (dir, file: string) {
	vol_len := _volume_name_len(path)

	i := len(path) - 1
	for i >= vol_len && !_is_path_separator(path[i]) {
		i -= 1
	}
	if i == vol_len {
		return path[:i+1], path[i+1:]
	} else if i > vol_len {
		return path[:i], path[i+1:]
	}
	return "", path
}