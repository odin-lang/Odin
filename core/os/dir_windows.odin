#+private
package os

import "base:runtime"
import "core:slice"
import "core:time"
import win32 "core:sys/windows"

@(private="file")
find_data_fullpath :: proc(base_path: string, d: ^win32.WIN32_FIND_DATAW, allocator: runtime.Allocator) -> (path, name: string, err: Error) {
	wname_len := i32(slice.linear_search(d.cFileName[:], 0) or_else len(d.cFileName))
	wname := cstring16(raw_data(d.cFileName[:]))

	name_len := win32.WideCharToMultiByte(win32.CP_UTF8, win32.WC_ERR_INVALID_CHARS, wname, wname_len, nil, 0, nil, nil)
	if name_len == 0 {
		return "", "", _get_platform_error()
	}

	path_buf := make([]byte, len(base_path)+1+int(name_len), allocator) or_return
	copy(path_buf, base_path)
	path_buf[len(base_path)] = '\\'

	name_buf := path_buf[len(base_path)+1:]
	written := win32.WideCharToMultiByte(win32.CP_UTF8, win32.WC_ERR_INVALID_CHARS, wname, wname_len, raw_data(name_buf), name_len, nil, nil)
	if written == 0 {
		delete(path_buf, allocator)
		return "", "", _get_platform_error()
	}

	path = string(path_buf)
	name = string(name_buf[:written])
	return
}

@(private="file")
find_data_to_file_info :: proc(base_path: string, d: ^win32.WIN32_FIND_DATAW, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	// Ignore "." and ".."
	if d.cFileName[0] == '.' && d.cFileName[1] == 0 {
		return
	}
	if d.cFileName[0] == '.' && d.cFileName[1] == '.' && d.cFileName[2] == 0 {
		return
	}

	path, name := find_data_fullpath(base_path, d, allocator) or_return
	fi.fullpath = path
	fi.name = name
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.type, fi.mode = _file_type_mode_from_file_attributes(d.dwFileAttributes, nil, d.dwReserved0)
	if fi.type == .Undetermined { fi.type = .Regular }

	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))

	return
}

Read_Directory_Iterator_Impl :: struct {
	find_data:     win32.WIN32_FIND_DATAW,
	find_handle:   win32.HANDLE,
	path:          string,
	prev_fi:       File_Info,
	no_more_files: bool,
}


@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	for !it.impl.no_more_files {
		err: Error
		file_info_delete(it.impl.prev_fi, file_allocator())
		it.impl.prev_fi = {}

		fi, err = find_data_to_file_info(it.impl.path, &it.impl.find_data, file_allocator())
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
		win32.FindClose(it.impl.find_handle)
	}
	it.impl.find_handle = nil
	if it.impl.path != "" {
		delete(it.impl.path, file_allocator())
		it.impl.path = ""
	}

	file_info: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(_handle(f), &file_info) {
		read_directory_iterator_set_error(it, impl.name, _get_platform_error())
		return
	}
	if file_info.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY == 0 {
		read_directory_iterator_set_error(it, impl.name, .Invalid_Dir)
		return
	}

	wpath := string16(impl.wname)
	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	wpath_search := make([]u16, len(wpath)+3, temp_allocator)
	copy(wpath_search, wpath)
	wpath_search[len(wpath)+0] = '\\'
	wpath_search[len(wpath)+1] = '*'
	wpath_search[len(wpath)+2] = 0

	it.impl.find_handle = win32.FindFirstFileExW(
		cstring16(raw_data(wpath_search)),
		.FindExInfoBasic,
		&it.impl.find_data,
		.FindExSearchNameMatch,
		nil,
		win32.FIND_FIRST_EX_LARGE_FETCH,
	)
	if it.impl.find_handle == win32.INVALID_HANDLE_VALUE {
		it.impl.find_handle = win32.FindFirstFileW(cstring16(raw_data(wpath_search)), &it.impl.find_data)
	}
	if it.impl.find_handle == win32.INVALID_HANDLE_VALUE {
		it.impl.find_handle = nil
		read_directory_iterator_set_error(it, impl.name, _get_platform_error())
		return
	}
	defer if it.err.err != nil {
		win32.FindClose(it.impl.find_handle)
		it.impl.find_handle = nil
	}

	err: Error
	it.impl.path, err = get_absolute_path(impl.name, file_allocator())
	if err != nil {
		read_directory_iterator_set_error(it, impl.name, err)
	}

	return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	file_info_delete(it.impl.prev_fi, file_allocator())
	delete(it.impl.path, file_allocator())
	if it.impl.find_handle != nil {
		win32.FindClose(it.impl.find_handle)
	}
	it.impl.find_handle = nil
}
