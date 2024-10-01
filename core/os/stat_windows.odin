package os

import "core:time"
import "base:runtime"
import win32 "core:sys/windows"

@(private, require_results)
full_path_from_name :: proc(name: string, allocator := context.allocator) -> (path: string, err: Errno) {
	context.allocator = allocator
	
	name := name
	if name == "" {
		name = "."
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)
	p := win32.utf8_to_utf16(name, context.temp_allocator)
	buf := make([dynamic]u16, 100)
	defer delete(buf)
	for {
		n := win32.GetFullPathNameW(raw_data(p), u32(len(buf)), raw_data(buf), nil)
		if n == 0 {
			return "", get_last_error()
		}
		if n <= u32(len(buf)) {
			return win32.utf16_to_utf8(buf[:n], allocator) or_else "", nil
		}
		resize(&buf, len(buf)*2)
	}

	return
}

@(private, require_results)
_stat :: proc(name: string, create_file_attributes: u32, allocator := context.allocator) -> (fi: File_Info, e: Errno) {
	if len(name) == 0 {
		return {}, ERROR_PATH_NOT_FOUND
	}

	context.allocator = allocator

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	wname := win32.utf8_to_wstring(fix_long_path(name), context.temp_allocator)
	fa: win32.WIN32_FILE_ATTRIBUTE_DATA
	ok := win32.GetFileAttributesExW(wname, win32.GetFileExInfoStandard, &fa)
	if ok && fa.dwFileAttributes & win32.FILE_ATTRIBUTE_REPARSE_POINT == 0 {
		// Not a symlink
		return file_info_from_win32_file_attribute_data(&fa, name)
	}

	err := 0 if ok else win32.GetLastError()

	if err == win32.ERROR_SHARING_VIOLATION {
		fd: win32.WIN32_FIND_DATAW
		sh := win32.FindFirstFileW(wname, &fd)
		if sh == win32.INVALID_HANDLE_VALUE {
			e = get_last_error()
			return
		}
		win32.FindClose(sh)

		return file_info_from_win32_find_data(&fd, name)
	}

	h := win32.CreateFileW(wname, 0, 0, nil, win32.OPEN_EXISTING, create_file_attributes, nil)
	if h == win32.INVALID_HANDLE_VALUE {
		e = get_last_error()
		return
	}
	defer win32.CloseHandle(h)
	return file_info_from_get_file_information_by_handle(name, h)
}


@(require_results)
lstat :: proc(name: string, allocator := context.allocator) -> (File_Info, Errno) {
	attrs := win32.FILE_FLAG_BACKUP_SEMANTICS
	attrs |= win32.FILE_FLAG_OPEN_REPARSE_POINT
	return _stat(name, attrs, allocator)
}

@(require_results)
stat :: proc(name: string, allocator := context.allocator) -> (File_Info, Errno) {
	attrs := win32.FILE_FLAG_BACKUP_SEMANTICS
	return _stat(name, attrs, allocator)
}

@(require_results)
fstat :: proc(fd: Handle, allocator := context.allocator) -> (fi: File_Info, err: Errno) {
	if fd == 0 {
		err = ERROR_INVALID_HANDLE
	}
	context.allocator = allocator

	path := cleanpath_from_handle(fd) or_return
	defer if err != nil {
		delete(path)
	}

	h := win32.HANDLE(fd)
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE, win32.FILE_TYPE_CHAR:
		fi.name = basename(path)
		fi.mode |= file_type_mode(h)
		err = nil
	case:
		fi  = file_info_from_get_file_information_by_handle(path, h) or_return
	}
	fi.fullpath = path
	return
}


@(private, require_results)
cleanpath_strip_prefix :: proc(buf: []u16) -> []u16 {
	buf := buf
	N := 0
	for c, i in buf {
		if c == 0 { break }
		N = i+1
	}
	buf = buf[:N]

	if len(buf) >= 4 && buf[0] == '\\' && buf[1] == '\\' && buf[2] == '?' && buf[3] == '\\' {
		buf = buf[4:]

		/*
			NOTE(Jeroen): Properly handle UNC paths.
			We need to turn `\\?\UNC\synology.local` into `\\synology.local`.
		*/
		if len(buf) >= 3 && buf[0] == 'U' && buf[1] == 'N' && buf[2] == 'C' {
			buf = buf[2:]
			buf[0] = '\\'
		}
	}
	return buf
}

@(private, require_results)
cleanpath_from_handle :: proc(fd: Handle) -> (s: string, err: Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)
	buf := cleanpath_from_handle_u16(fd, context.temp_allocator) or_return
	return win32.utf16_to_utf8(buf, context.allocator)
}
@(private, require_results)
cleanpath_from_handle_u16 :: proc(fd: Handle, allocator: runtime.Allocator) -> ([]u16, Errno) {
	if fd == 0 {
		return nil, ERROR_INVALID_HANDLE
	}
	h := win32.HANDLE(fd)

	n := win32.GetFinalPathNameByHandleW(h, nil, 0, 0)
	if n == 0 {
		return nil, get_last_error()
	}
	buf := make([]u16, max(n, win32.DWORD(260))+1, allocator)
	buf_len := win32.GetFinalPathNameByHandleW(h, raw_data(buf), n, 0)
	return buf[:buf_len], nil
}
@(private, require_results)
cleanpath_from_buf :: proc(buf: []u16) -> string {
	buf := buf
	buf = cleanpath_strip_prefix(buf)
	return win32.utf16_to_utf8(buf, context.allocator) or_else ""
}

@(private, require_results)
basename :: proc(name: string) -> (base: string) {
	name := name
	if len(name) > 3 && name[:3] == `\\?` {
		name = name[3:]
	}

	if len(name) == 2 && name[1] == ':' {
		return "."
	} else if len(name) > 2 && name[1] == ':' {
		name = name[2:]
	}
	i := len(name)-1

	for ; i > 0 && (name[i] == '/' || name[i] == '\\'); i -= 1 {
		name = name[:i]
	}
	for i -= 1; i >= 0; i -= 1 {
		if name[i] == '/' || name[i] == '\\' {
			name = name[i+1:]
			break
		}
	}
	return name
}

@(private, require_results)
file_type_mode :: proc(h: win32.HANDLE) -> File_Mode {
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE:
		return File_Mode_Named_Pipe
	case win32.FILE_TYPE_CHAR:
		return File_Mode_Device | File_Mode_Char_Device
	}
	return 0
}


@(private, require_results)
file_mode_from_file_attributes :: proc(FileAttributes: win32.DWORD, h: win32.HANDLE, ReparseTag: win32.DWORD) -> (mode: File_Mode) {
	if FileAttributes & win32.FILE_ATTRIBUTE_READONLY != 0 {
		mode |= 0o444
	} else {
		mode |= 0o666
	}

	is_sym := false
	if FileAttributes & win32.FILE_ATTRIBUTE_REPARSE_POINT == 0 {
		is_sym = false
	} else {
		is_sym = ReparseTag == win32.IO_REPARSE_TAG_SYMLINK || ReparseTag == win32.IO_REPARSE_TAG_MOUNT_POINT
	}

	if is_sym {
		mode |= File_Mode_Sym_Link
	} else {
		if FileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
			mode |= 0o111 | File_Mode_Dir
		}

		if h != nil {
			mode |= file_type_mode(h)
		}
	}

	return
}

@(private)
windows_set_file_info_times :: proc(fi: ^File_Info, d: ^$T) {
	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))
}

@(private, require_results)
file_info_from_win32_file_attribute_data :: proc(d: ^win32.WIN32_FILE_ATTRIBUTE_DATA, name: string) -> (fi: File_Info, e: Errno) {
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.mode |= file_mode_from_file_attributes(d.dwFileAttributes, nil, 0)
	fi.is_dir = fi.mode & File_Mode_Dir != 0

	windows_set_file_info_times(&fi, d)

	fi.fullpath, e = full_path_from_name(name)
	fi.name = basename(fi.fullpath)

	return
}

@(private, require_results)
file_info_from_win32_find_data :: proc(d: ^win32.WIN32_FIND_DATAW, name: string) -> (fi: File_Info, e: Errno) {
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.mode |= file_mode_from_file_attributes(d.dwFileAttributes, nil, 0)
	fi.is_dir = fi.mode & File_Mode_Dir != 0

	windows_set_file_info_times(&fi, d)

	fi.fullpath, e = full_path_from_name(name)
	fi.name = basename(fi.fullpath)

	return
}

@(private, require_results)
file_info_from_get_file_information_by_handle :: proc(path: string, h: win32.HANDLE) -> (File_Info, Errno) {
	d: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(h, &d) {
		err := get_last_error()
		return {}, err

	}

	ti: win32.FILE_ATTRIBUTE_TAG_INFO
	if !win32.GetFileInformationByHandleEx(h, .FileAttributeTagInfo, &ti, size_of(ti)) {
		err := get_last_error()
		if err != ERROR_INVALID_PARAMETER {
			return {}, err
		}
		// Indicate this is a symlink on FAT file systems
		ti.ReparseTag = 0
	}

	fi: File_Info

	fi.fullpath = path
	fi.name = basename(path)
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.mode |= file_mode_from_file_attributes(ti.FileAttributes, h, ti.ReparseTag)
	fi.is_dir = fi.mode & File_Mode_Dir != 0

	windows_set_file_info_times(&fi, &d)

	return fi, nil
}
