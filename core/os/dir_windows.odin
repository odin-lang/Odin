#+private
package os

import "base:runtime"
import "core:time"
import win32 "core:sys/windows"

@(private="file")
find_data_to_file_info :: proc(base_path: string, wbase_path: []u16, d: ^win32.WIN32_FIND_DATAW, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	// Ignore "." and ".."
	if d.cFileName[0] == '.' && d.cFileName[1] == 0 {
		return
	}
	if d.cFileName[0] == '.' && d.cFileName[1] == '.' && d.cFileName[2] == 0 {
		return
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	filename := win32_wstring_to_utf8(cstring16(raw_data(d.cFileName[:])), temp_allocator) or_else ""

	pieces: []string
	if len(base_path) > 0 && is_path_separator(base_path[len(base_path) - 1]) {
		pieces = {base_path, filename}
	} else {
		pieces = {base_path, Path_Separator_String, filename}
	}
	path := concatenate(pieces, allocator) or_return

	name_len := 0
	for name_len < len(d.cFileName) && d.cFileName[name_len] != 0 {
		name_len += 1
	}
	separator := 0
	if len(wbase_path) > 0 && !_is_path_separator_u16(wbase_path[len(wbase_path) - 1]) {
		separator = 1
	}
	wpath := make([]u16, len(wbase_path) + separator + name_len + 1, temp_allocator) or_return
	copy(wpath, wbase_path)
	if separator == 1 {
		wpath[len(wbase_path)] = '\\'
	}
	copy(wpath[len(wbase_path) + separator:], d.cFileName[:name_len])

	handle := win32.CreateFileW(
		cstring16(raw_data(wpath)),
		win32.FILE_GENERIC_READ,
		win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_ATTRIBUTE_NORMAL | win32.FILE_FLAG_BACKUP_SEMANTICS,
		nil,
	)
	if handle == win32.INVALID_HANDLE_VALUE {
		handle = nil
	}
	defer win32.CloseHandle(handle)

	fi.fullpath = path
	fi.name = basename(path)
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.type, fi.mode = _file_type_mode_from_file_attributes(d.dwFileAttributes, handle, d.dwReserved0)

	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))

	if file_id_info: win32.FILE_ID_INFO; handle != nil && win32.GetFileInformationByHandleEx(handle, .FileIdInfo, &file_id_info, size_of(file_id_info)) {
		#assert(size_of(fi.inode) == size_of(file_id_info.FileId))
		#assert(size_of(fi.inode) == 16)
		runtime.mem_copy_non_overlapping(&fi.inode, &file_id_info.FileId, 16)
		fi.device = file_id_info.VolumeSerialNumber
	}

	return
}

@(private="file", require_results)
search_directory_wide :: proc(path: string, wide: []u16, allocator: runtime.Allocator) -> (dir: []u16, err: Error) {
	if _is_verbatim_path_u16(wide) {
		return _verbatim_path_wide(path, wide, allocator)
	}

	fixed := _fix_long_path_wide(path, wide, allocator) or_return
	if raw_data(fixed) != raw_data(wide) {
		return fixed, nil
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	spec := make([]u16, len(wide) + 3, temp_allocator) or_return
	copy(spec, wide)
	spec[len(wide)] = '\\'
	spec[len(wide) + 1] = '*'
	full := _full_path_wide(spec[:len(wide) + 2], temp_allocator) or_return
	if len(full) > 0 && full[len(full) - 1] == '*' {
		full = full[:len(full) - 1]
	}
	dir = _extended_path_wide(full, allocator) or_return
	return
}

Read_Directory_Iterator_Impl :: struct {
	find_data:     win32.WIN32_FIND_DATAW,
	find_handle:   win32.HANDLE,
	path:          string,
	wpath:         []u16,
	prev_fi:       File_Info,
	no_more_files: bool,
}


@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	for !it.impl.no_more_files {
		err: Error
		file_info_delete(it.impl.prev_fi, file_allocator())
		it.impl.prev_fi = {}

		fi, err = find_data_to_file_info(it.impl.path, it.impl.wpath, &it.impl.find_data, file_allocator())
		if err != nil {
			read_directory_iterator_set_error(it, it.impl.path, err)
			return
		}

		if fi.name != "" {
			it.impl.prev_fi = fi
			ok = true
			index = it.index
			it.index += 1
		}

		if !win32.FindNextFileW(it.impl.find_handle, &it.impl.find_data) {
			e := _get_platform_error()
			if pe, _ := is_platform_error(e); pe != i32(win32.ERROR_NO_MORE_FILES) {
				read_directory_iterator_set_error(it, it.impl.path, e)
			}
			it.impl.no_more_files = true
		}
		if ok {
			return
		}
	}
	return
}

_read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File) {
	it.impl.no_more_files = false

	if f == nil || f.impl == nil {
		read_directory_iterator_set_error(it, "", .Invalid_File)
		return
	}

	it.f = f
	impl := (^File_Impl)(f.impl)

	// NOTE: Allow calling `init` to target a new directory with the same iterator - reset idx.
	if it.impl.find_handle != nil {
		if it.impl.find_handle != win32.INVALID_HANDLE_VALUE {
			win32.FindClose(it.impl.find_handle)
		}
		it.impl.find_handle = nil
	}
	if it.impl.path != "" {
		delete(it.impl.path, file_allocator())
		it.impl.path = ""
	}
	delete(it.impl.wpath, file_allocator())
	it.impl.wpath = nil

	info: win32.BY_HANDLE_FILE_INFORMATION
	if impl.wname == nil || !win32.GetFileInformationByHandle(win32.HANDLE(impl.fd), &info) || info.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY == 0 {
		read_directory_iterator_set_error(it, impl.name, .Invalid_Dir)
		return
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	wide := ([^]u16)(impl.wname)[:len(impl.wname)]
	full, full_err := _full_path_wide(wide, temp_allocator)
	if full_err != nil {
		read_directory_iterator_set_error(it, impl.name, full_err)
		return
	}

	wpath, wpath_err := search_directory_wide(impl.name, wide, file_allocator())
	if wpath_err != nil {
		read_directory_iterator_set_error(it, impl.name, wpath_err)
		return
	}
	it.impl.wpath = wpath

	search_len := len(wpath)
	if search_len == 0 || !_is_path_separator_u16(wpath[search_len-1]) {
		search_len += 1
	}
	wpath_search := make([]u16, search_len+2, temp_allocator)
	copy(wpath_search, wpath)
	wpath_search[search_len-1] = '\\'
	wpath_search[search_len+0] = '*'
	wpath_search[search_len+1] = 0

	it.impl.find_handle = win32.FindFirstFileW(cstring16(raw_data(wpath_search)), &it.impl.find_data)
	if it.impl.find_handle == win32.INVALID_HANDLE_VALUE {
		read_directory_iterator_set_error(it, impl.name, _get_platform_error())
		return
	}
	defer if it.err.err != nil {
		win32.FindClose(it.impl.find_handle)
		it.impl.find_handle = nil
	}

	err: Error
	it.impl.path, err = win32_utf16_to_utf8(full, file_allocator())
	if err != nil {
		read_directory_iterator_set_error(it, impl.name, err)
	}

	return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	file_info_delete(it.impl.prev_fi, file_allocator())
	it.impl.prev_fi = {}

	delete(it.impl.path, file_allocator())
	it.impl.path = ""

	delete(it.impl.wpath, file_allocator())
	it.impl.wpath = nil

	if it.impl.find_handle != nil && it.impl.find_handle != win32.INVALID_HANDLE_VALUE {
		win32.FindClose(it.impl.find_handle)
	}
	it.impl.find_handle = nil
}
