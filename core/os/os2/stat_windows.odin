#+private
package os2

import "base:runtime"
import "core:time"
import "core:strings"
import win32 "core:sys/windows"

_fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	if f == nil || (^File_Impl)(f.impl).fd == nil {
		return
	}

	path := _cleanpath_from_handle(f, allocator) or_return

	h := _handle(f)
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE, win32.FILE_TYPE_CHAR:
		fi = File_Info {
			fullpath = path,
			name = basename(path),
			type = file_type(h),
		}
		return
	}

	return _file_info_from_get_file_information_by_handle(path, h, allocator)
}

_stat :: proc(name: string, allocator: runtime.Allocator) -> (File_Info, Error) {
	return internal_stat(name, win32.FILE_FLAG_BACKUP_SEMANTICS, allocator)
}

_lstat :: proc(name: string, allocator: runtime.Allocator) -> (File_Info, Error) {
	return internal_stat(name, win32.FILE_FLAG_BACKUP_SEMANTICS|win32.FILE_FLAG_OPEN_REPARSE_POINT, allocator)
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}

full_path_from_name :: proc(name: string, allocator: runtime.Allocator) -> (path: string, err: Error) {
	name := name
	if name == "" {
		name = "."
	}

	TEMP_ALLOCATOR_GUARD()

	p := win32_utf8_to_utf16(name, temp_allocator()) or_return

	n := win32.GetFullPathNameW(raw_data(p), 0, nil, nil)
	if n == 0 {
		return "", _get_platform_error()
	}
	buf := make([]u16, n+1, temp_allocator())
	n = win32.GetFullPathNameW(raw_data(p), u32(len(buf)), raw_data(buf), nil)
	if n == 0 {
		return "", _get_platform_error()
	}
	return win32_utf16_to_utf8(buf[:n], allocator)
}

internal_stat :: proc(name: string, create_file_attributes: u32, allocator: runtime.Allocator) -> (fi: File_Info, e: Error) {
	if len(name) == 0 {
		return {}, .Not_Exist
	}
	TEMP_ALLOCATOR_GUARD()

	wname := _fix_long_path(name, temp_allocator()) or_return
	fa: win32.WIN32_FILE_ATTRIBUTE_DATA
	ok := win32.GetFileAttributesExW(wname, win32.GetFileExInfoStandard, &fa)
	if ok && fa.dwFileAttributes & win32.FILE_ATTRIBUTE_REPARSE_POINT == 0 {
		// Not a symlink
		fi = _file_info_from_win32_file_attribute_data(&fa, name, allocator) or_return
		if fi.type == .Undetermined {
			fi.type = _file_type_from_create_file(wname, create_file_attributes)
		}
		return
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

		fi = _file_info_from_win32_find_data(&fd, name, allocator) or_return
		if fi.type == .Undetermined {
			fi.type = _file_type_from_create_file(wname, create_file_attributes)
		}
		return
	}

	h := win32.CreateFileW(wname, 0, 0, nil, win32.OPEN_EXISTING, create_file_attributes, nil)
	if h == win32.INVALID_HANDLE_VALUE {
		e = _get_platform_error()
		return
	}
	defer win32.CloseHandle(h)
	return _file_info_from_get_file_information_by_handle(name, h, allocator)
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

_cleanpath_from_handle :: proc(f: ^File, allocator: runtime.Allocator) -> (string, Error) {
	if f == nil {
		return "", nil
	}
	h := _handle(f)

	n := win32.GetFinalPathNameByHandleW(h, nil, 0, 0)
	if n == 0 {
		return "", _get_platform_error()
	}

	TEMP_ALLOCATOR_GUARD()

	buf := make([]u16, max(n, 260)+1, temp_allocator())
	n = win32.GetFinalPathNameByHandleW(h, raw_data(buf), u32(len(buf)), 0)
	return _cleanpath_from_buf(buf[:n], allocator)
}

_cleanpath_from_handle_u16 :: proc(f: ^File) -> ([]u16, Error) {
	if f  == nil {
		return nil, nil
	}
	h := _handle(f)

	n := win32.GetFinalPathNameByHandleW(h, nil, 0, 0)
	if n == 0 {
		return nil, _get_platform_error()
	}

	TEMP_ALLOCATOR_GUARD()

	buf := make([]u16, max(n, 260)+1, temp_allocator())
	n = win32.GetFinalPathNameByHandleW(h, raw_data(buf), u32(len(buf)), 0)
	return _cleanpath_strip_prefix(buf[:n]), nil
}

_cleanpath_from_buf :: proc(buf: []u16, allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	buf := buf
	buf = _cleanpath_strip_prefix(buf)
	return win32_utf16_to_utf8(buf, allocator)
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

file_type :: proc(h: win32.HANDLE) -> File_Type {
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE: return .Named_Pipe
	case win32.FILE_TYPE_CHAR: return .Character_Device
	case win32.FILE_TYPE_DISK: return .Regular
	}
	return .Undetermined
}

_file_type_from_create_file :: proc(wname: win32.wstring, create_file_attributes: u32) -> File_Type {
	h := win32.CreateFileW(wname, 0, 0, nil, win32.OPEN_EXISTING, create_file_attributes, nil)
	if h == win32.INVALID_HANDLE_VALUE {
		return .Undetermined
	}
	defer win32.CloseHandle(h)
	return file_type(h)
}

_file_type_mode_from_file_attributes :: proc(file_attributes: win32.DWORD, h: win32.HANDLE, ReparseTag: win32.DWORD) -> (type: File_Type, mode: int) {
	if file_attributes & win32.FILE_ATTRIBUTE_READONLY != 0 {
		mode |= 0o444
	} else {
		mode |= 0o666
	}

	is_sym := false
	if file_attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT == 0 {
		is_sym = false
	} else {
		is_sym = ReparseTag == win32.IO_REPARSE_TAG_SYMLINK || ReparseTag == win32.IO_REPARSE_TAG_MOUNT_POINT
	}

	if is_sym {
		type = .Symlink
	} else if file_attributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
		type = .Directory
		mode |= 0o111
	} else if h != nil {
		type = file_type(h)
	}
	return
}

_file_info_from_win32_file_attribute_data :: proc(d: ^win32.WIN32_FILE_ATTRIBUTE_DATA, name: string, allocator: runtime.Allocator) -> (fi: File_Info, e: Error) {
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)
	type, mode := _file_type_mode_from_file_attributes(d.dwFileAttributes, nil, 0)
	fi.type = type
	fi.mode |= mode
	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))
	fi.fullpath, e = full_path_from_name(name, allocator)
	fi.name = basename(fi.fullpath)
	return
}

_file_info_from_win32_find_data :: proc(d: ^win32.WIN32_FIND_DATAW, name: string, allocator: runtime.Allocator) -> (fi: File_Info, e: Error) {
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow)
	type, mode := _file_type_mode_from_file_attributes(d.dwFileAttributes, nil, 0)
	fi.type = type
	fi.mode |= mode
	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime))
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime))
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime))
	fi.fullpath, e = full_path_from_name(name, allocator)
	fi.name = basename(fi.fullpath)
	return
}

_file_info_from_get_file_information_by_handle :: proc(path: string, h: win32.HANDLE, allocator: runtime.Allocator) -> (File_Info, Error) {
	d: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(h, &d) {
		return {}, _get_platform_error()

	}

	ti: win32.FILE_ATTRIBUTE_TAG_INFO
	if !win32.GetFileInformationByHandleEx(h, .FileAttributeTagInfo, &ti, size_of(ti)) {
		err := win32.GetLastError()
		if err != win32.ERROR_INVALID_PARAMETER {
			return {}, Platform_Error(err)
		}
		// Indicate this is a symlink on FAT file systems
		ti.ReparseTag = 0
	}
	fi: File_Info
	fi.fullpath = path
	fi.name = basename(path)
	fi.inode = u128(u64(d.nFileIndexHigh)<<32 + u64(d.nFileIndexLow))
	fi.size  = i64(d.nFileSizeHigh)<<32  + i64(d.nFileSizeLow)
	type, mode := _file_type_mode_from_file_attributes(d.dwFileAttributes, h, 0)
	fi.type = type
	fi.mode |= mode
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

