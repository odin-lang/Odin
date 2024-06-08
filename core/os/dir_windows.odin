package os

import win32 "core:sys/windows"
import "core:strings"
import "base:runtime"

read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Errno) {
	find_data_to_file_info :: proc(base_path: string, d: ^win32.WIN32_FIND_DATAW) -> (fi: File_Info) {
		// Ignore "." and ".."
		if d.cFileName[0] == '.' && d.cFileName[1] == 0 {
			return
		}
		if d.cFileName[0] == '.' && d.cFileName[1] == '.' && d.cFileName[2] == 0 {
			return
		}
		path := strings.concatenate({base_path, `\`, win32.utf16_to_utf8(d.cFileName[:]) or_else ""})
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
			fi.mode |= File_Mode_Sym_Link
		} else {
			if d.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
				fi.mode |= 0o111 | File_Mode_Dir
			}

			// fi.mode |= file_type_mode(h);
		}

		windows_set_file_info_times(&fi, d)

		fi.is_dir = fi.mode & File_Mode_Dir != 0
		return
	}

	if fd == 0 {
		return nil, ERROR_INVALID_HANDLE
	}

	context.allocator = allocator

	h := win32.HANDLE(fd)

	dir_fi, _ := file_info_from_get_file_information_by_handle("", h)
	if !dir_fi.is_dir {
		return nil, ERROR_FILE_IS_NOT_DIR
	}

	n := n
	size := n
	if n <= 0 {
		n = -1
		size = 100
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	wpath: []u16
	wpath, err = cleanpath_from_handle_u16(fd, context.temp_allocator)
	if len(wpath) == 0 || err != ERROR_NONE {
		return
	}

	dfi := make([dynamic]File_Info, 0, size)

	wpath_search := make([]u16, len(wpath)+3, context.temp_allocator)
	copy(wpath_search, wpath)
	wpath_search[len(wpath)+0] = '\\'
	wpath_search[len(wpath)+1] = '*'
	wpath_search[len(wpath)+2] = 0

	path := cleanpath_from_buf(wpath)
	defer delete(path)

	find_data := &win32.WIN32_FIND_DATAW{}
	find_handle := win32.FindFirstFileW(raw_data(wpath_search), find_data)
	if find_handle == win32.INVALID_HANDLE_VALUE {
		err = Errno(win32.GetLastError())
		return dfi[:], err
	}
	defer win32.FindClose(find_handle)
	for n != 0 {
		fi: File_Info
		fi = find_data_to_file_info(path, find_data)
		if fi.name != "" {
			append(&dfi, fi)
			n -= 1
		}

		if !win32.FindNextFileW(find_handle, find_data) {
			e := Errno(win32.GetLastError())
			if e == ERROR_NO_MORE_FILES {
				break
			}
			return dfi[:], e
		}
	}

	return dfi[:], ERROR_NONE
}
