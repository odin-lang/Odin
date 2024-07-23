package os2

import "base:runtime"
import "core:time"
import win32 "core:sys/windows"

@(private)
_read_directory :: proc(f: ^File, n: int, allocator: runtime.Allocator) -> (files: []File_Info, err: Error) {
	find_data_to_file_info :: proc(base_path: string, d: ^win32.WIN32_FIND_DATAW, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
		// Ignore "." and ".."
		if d.cFileName[0] == '.' && d.cFileName[1] == 0 {
			return
		}
		if d.cFileName[0] == '.' && d.cFileName[1] == '.' && d.cFileName[2] == 0 {
			return
		}
		path := concatenate({base_path, `\`, win32_utf16_to_utf8(d.cFileName[:], temp_allocator()) or_else ""}, allocator) or_return
		fi.fullpath = path
		fi.name = basename(path)
		fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

		if d.dwFileAttributes & win32.FILE_ATTRIBUTE_READONLY != 0 {
			fi.mode |= 0o444
		} else {
			fi.mode |= 0o666
		}

		is_sym := false
		if d.dwFileAttributes & win32.FILE_ATTRIBUTE_REPARSE_Point == 0 {
			is_sym = false
		} else {
			is_sym = d.dwReserved0 == win32.IO_REPARSE_TAG_SYMLINK || d.dwReserved0 == win32.IO_REPARSE_TAG_MOUNT_POINT
		}

		if is_sym {
			fi.type = .Symlink
		} else if d.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
			fi.type = .Directory
			fi.mode |= 0o111
		}

		fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
		fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
		fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))
		return
	}

	if f == nil {
		return nil, .Invalid_File
	}

	TEMP_ALLOCATOR_GUARD()

	impl := (^File_Impl)(f.impl)

	if !is_directory(impl.name) {
		return nil, .Invalid_Dir
	}

	n := n
	size := n
	if n <= 0 {
		n = -1
		size = 100
	}

	wpath: []u16
	{
		i := 0
		for impl.wname[i] != 0 {
			i += 1
		}
		wpath = impl.wname[:i]
	}


	wpath_search := make([]u16, len(wpath)+3, context.temp_allocator)
	copy(wpath_search, wpath)
	wpath_search[len(wpath)+0] = '\\'
	wpath_search[len(wpath)+1] = '*'
	wpath_search[len(wpath)+2] = 0

	find_data := &win32.WIN32_FIND_DATAW{}
	find_handle := win32.FindFirstFileW(raw_data(wpath_search), find_data)
	if find_handle == win32.INVALID_HANDLE_VALUE {
		return nil, _get_platform_error()
	}
	defer win32.FindClose(find_handle)

	path := _cleanpath_from_buf(wpath, temp_allocator()) or_return

	dfi := make([dynamic]File_Info, 0, size, allocator)
	defer if err != nil {
		for fi in dfi {
			file_info_delete(fi, allocator)
		}
		delete(dfi)
	}
	for n != 0 {
		fi: File_Info
		fi = find_data_to_file_info(path, find_data, allocator) or_return
		if fi.name != "" {
			append(&dfi, fi)
			n -= 1
		}

		if !win32.FindNextFileW(find_handle, find_data) {
			e := _get_platform_error()
			if pe, _ := is_platform_error(e); pe == i32(win32.ERROR_NO_MORE_FILES) {
				break
			}
			return dfi[:], e
		}
	}

	return dfi[:], nil
}

