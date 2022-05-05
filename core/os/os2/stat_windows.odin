//+private
package os2

import "core:time"
import "core:strings"
import win32 "core:sys/windows"

_fstat :: proc(f: ^File, allocator := context.allocator) -> (File_Info, Error) {
	if f == nil || f.impl.fd == nil {
		return {}, .Invalid_Argument
	}
	context.allocator = allocator

	path, err := _cleanpath_from_handle(f)
	if err != nil {
		return {}, err
	}

	h := win32.HANDLE(f.impl.fd)
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE, win32.FILE_TYPE_CHAR:
		fi: File_Info
		fi.fullpath = path
		fi.name = basename(path)
		fi.mode |= file_type_mode(h)
		return fi, nil
	}

	return _file_info_from_get_file_information_by_handle(path, h)
}
_stat :: proc(name: string, allocator := context.allocator) -> (File_Info, Error) {
	return internal_stat(name, win32.FILE_FLAG_BACKUP_SEMANTICS)
}
_lstat :: proc(name: string, allocator := context.allocator) -> (File_Info, Error) {
	return internal_stat(name, win32.FILE_FLAG_BACKUP_SEMANTICS|win32.FILE_FLAG_OPEN_REPARSE_POINT)
}
_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}



_stat_errno :: proc(errno: win32.DWORD) -> Error {
	return Platform_Error{i32(errno)}
}


full_path_from_name :: proc(name: string, allocator := context.allocator) -> (path: string, err: Error) {
	context.allocator = allocator
	
	name := name
	if name == "" {
		name = "."
	}
	p := win32.utf8_to_utf16(name, context.temp_allocator)
	buf := make([dynamic]u16, 100)
	for {
		n := win32.GetFullPathNameW(raw_data(p), u32(len(buf)), raw_data(buf), nil)
		if n == 0 {
			delete(buf)
			return "", _stat_errno(win32.GetLastError())
		}
		if n <= u32(len(buf)) {
			return win32.utf16_to_utf8(buf[:n]), nil
		}
		resize(&buf, len(buf)*2)
	}

	return
}


internal_stat :: proc(name: string, create_file_attributes: u32, allocator := context.allocator) -> (fi: File_Info, e: Error) {
	if len(name) == 0 {
		return {}, .Not_Exist
	}

	context.allocator = allocator


	wname := _fix_long_path(name)
	fa: win32.WIN32_FILE_ATTRIBUTE_DATA
	ok := win32.GetFileAttributesExW(wname, win32.GetFileExInfoStandard, &fa)
	if ok && fa.dwFileAttributes & win32.FILE_ATTRIBUTE_REPARSE_POINT == 0 {
		// Not a symlink
		return _file_info_from_win32_file_attribute_data(&fa, name)
	}

	err := 0 if ok else win32.GetLastError()

	if err == win32.ERROR_SHARING_VIOLATION {
		fd: win32.WIN32_FIND_DATAW
		sh := win32.FindFirstFileW(wname, &fd)
		if sh == win32.INVALID_HANDLE_VALUE {
			e = _get_platform_error()
			return
		}
		win32.FindClose(sh)

		return _file_info_from_win32_find_data(&fd, name)
	}

	h := win32.CreateFileW(wname, 0, 0, nil, win32.OPEN_EXISTING, create_file_attributes, nil)
	if h == win32.INVALID_HANDLE_VALUE {
		e = _get_platform_error()
		return
	}
	defer win32.CloseHandle(h)
	return _file_info_from_get_file_information_by_handle(name, h)
}


_cleanpath_strip_prefix :: proc(buf: []u16) -> []u16 {
	buf := buf
	N := 0
	for c, i in buf {
		if c == 0 { break }
		N = i+1
	}
	buf = buf[:N]

	if len(buf) >= 4 {
		if buf[0] == '\\' &&
		   buf[1] == '\\' &&
		   buf[2] == '?'  &&
		   buf[3] == '\\' {
			buf = buf[4:]
		}
	}
	return buf
}


_cleanpath_from_handle :: proc(f: ^File) -> (string, Error) {
	if f == nil || f.impl.fd == nil {
		return "", .Invalid_Argument
	}
	h := win32.HANDLE(f.impl.fd)

	MAX_PATH := win32.DWORD(260) + 1
	buf: []u16
	for {
		buf = make([]u16, MAX_PATH, context.temp_allocator)
		err := win32.GetFinalPathNameByHandleW(h, raw_data(buf), MAX_PATH, 0)
		switch err {
		case win32.ERROR_PATH_NOT_FOUND, win32.ERROR_INVALID_PARAMETER:
			return "", _stat_errno(err)
		case win32.ERROR_NOT_ENOUGH_MEMORY:
			MAX_PATH = MAX_PATH*2 + 1
			continue
		}
		break
	}
	return _cleanpath_from_buf(buf), nil
}

_cleanpath_from_handle_u16 :: proc(f: ^File) -> ([]u16, Error) {
	if f == nil || f.impl.fd == nil {
		return nil, .Invalid_Argument
	}
	h := win32.HANDLE(f.impl.fd)

	MAX_PATH := win32.DWORD(260) + 1
	buf: []u16
	for {
		buf = make([]u16, MAX_PATH, context.temp_allocator)
		err := win32.GetFinalPathNameByHandleW(h, raw_data(buf), MAX_PATH, 0)
		switch err {
		case win32.ERROR_PATH_NOT_FOUND, win32.ERROR_INVALID_PARAMETER:
			return nil, _stat_errno(err)
		case win32.ERROR_NOT_ENOUGH_MEMORY:
			MAX_PATH = MAX_PATH*2 + 1
			continue
		}
		break
	}
	return _cleanpath_strip_prefix(buf), nil
}

_cleanpath_from_buf :: proc(buf: []u16) -> string {
	buf := buf
	buf = _cleanpath_strip_prefix(buf)
	return win32.utf16_to_utf8(buf, context.allocator)
}


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


file_type_mode :: proc(h: win32.HANDLE) -> File_Mode {
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE:
		return File_Mode_Named_Pipe
	case win32.FILE_TYPE_CHAR:
		return File_Mode_Device | File_Mode_Char_Device
	}
	return 0
}



_file_mode_from_file_attributes :: proc(FileAttributes: win32.DWORD, h: win32.HANDLE, ReparseTag: win32.DWORD) -> (mode: File_Mode) {
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


_file_info_from_win32_file_attribute_data :: proc(d: ^win32.WIN32_FILE_ATTRIBUTE_DATA, name: string) -> (fi: File_Info, e: Error) {
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.mode |= _file_mode_from_file_attributes(d.dwFileAttributes, nil, 0)
	fi.is_dir = fi.mode & File_Mode_Dir != 0

	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))

	fi.fullpath, e = full_path_from_name(name)
	fi.name = basename(fi.fullpath)

	return
}


_file_info_from_win32_find_data :: proc(d: ^win32.WIN32_FIND_DATAW, name: string) -> (fi: File_Info, e: Error) {
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.mode |= _file_mode_from_file_attributes(d.dwFileAttributes, nil, 0)
	fi.is_dir = fi.mode & File_Mode_Dir != 0

	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))

	fi.fullpath, e = full_path_from_name(name)
	fi.name = basename(fi.fullpath)

	return
}


_file_info_from_get_file_information_by_handle :: proc(path: string, h: win32.HANDLE) -> (File_Info, Error) {
	d: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(h, &d) {
		return {}, _stat_errno(win32.GetLastError())

	}

	ti: win32.FILE_ATTRIBUTE_TAG_INFO
	if !win32.GetFileInformationByHandleEx(h, .FileAttributeTagInfo, &ti, size_of(ti)) {
		err := win32.GetLastError()
		if err != win32.ERROR_INVALID_PARAMETER {
			return {}, _stat_errno(err)
		}
		// Indicate this is a symlink on FAT file systems
		ti.ReparseTag = 0
	}

	fi: File_Info

	fi.fullpath = path
	fi.name = basename(path)
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)

	fi.mode |= _file_mode_from_file_attributes(ti.FileAttributes, h, ti.ReparseTag)
	fi.is_dir = fi.mode & File_Mode_Dir != 0

	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))

	return fi, nil
}



reserved_names := [?]string{
	"CON", "PRN", "AUX", "NUL",
	"COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
	"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
}

_is_reserved_name :: proc(path: string) -> bool {
	if len(path) == 0 {
		return false
	}
	for reserved in reserved_names {
		if strings.equal_fold(path, reserved) {
			return true
		}
	}
	return false
}

_is_UNC :: proc(path: string) -> bool {
	return _volume_name_len(path) > 2
}

_volume_name_len :: proc(path: string) -> int {
	if ODIN_OS == .Windows {
		if len(path) < 2 {
			return 0
		}
		c := path[0]
		if path[1] == ':' {
			switch c {
			case 'a'..='z', 'A'..='Z':
				return 2
			}
		}

		// URL: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx
		if l := len(path); l >= 5 && _is_path_separator(path[0]) && _is_path_separator(path[1]) &&
			!_is_path_separator(path[2]) && path[2] != '.' {
			for n := 3; n < l-1; n += 1 {
				if _is_path_separator(path[n]) {
					n += 1
					if !_is_path_separator(path[n]) {
						if path[n] == '.' {
							break
						}
					}
					for ; n < l; n += 1 {
						if _is_path_separator(path[n]) {
							break
						}
					}
					return n
				}
				break
			}
		}
	}
	return 0
}


_is_abs :: proc(path: string) -> bool {
	if _is_reserved_name(path) {
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
	return is_path_separator(path[0])
}

