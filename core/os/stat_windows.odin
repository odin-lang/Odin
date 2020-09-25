package os

import "core:time"
import win32 "core:sys/windows"
import "core:runtime"
import "core:strings"

stat :: proc(fd: Handle) -> (File_Info, Errno) {
	if fd == 0 {
		return {}, ERROR_INVALID_HANDLE;
	}
	path, err := cleanpath_from_handle(fd);
	if err != ERROR_NONE {
		return {}, err;
	}

	h := win32.HANDLE(fd);
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE, win32.FILE_TYPE_CHAR:
		fi: File_Info;
		fi.fullpath = path;
		fi.name = basename(path);
		fi.mode |= file_type_mode(h);
		return fi, ERROR_NONE;
	}

	return stat_from_file_information(path, h);
}


@(private)
cleanpath_strip_prefix :: proc(buf: []u16) -> []u16 {
	buf := buf;
	N := 0;
	for c, i in buf {
		if c == 0 { break; }
		N = i+1;
	}
	buf = buf[:N];

	if len(buf) >= 4 {
		if buf[0] == '\\'
		&& buf[1] == '\\'
		&& buf[2] == '?'
		&& buf[3] == '\\' {
			buf = buf[4:];
		}
	}
	return buf;
}

@(private)
cleanpath_from_handle :: proc(fd: Handle) -> (string, Errno) {
	if fd == 0 {
		return "", ERROR_INVALID_HANDLE;
	}
	h := win32.HANDLE(fd);

	MAX_PATH := win32.DWORD(260) + 1;
	buf: []u16;
	for {
		buf = make([]u16, MAX_PATH, context.temp_allocator);
		err := win32.GetFinalPathNameByHandleW(h, raw_data(buf), MAX_PATH, 0);
		switch Errno(err) {
		case ERROR_PATH_NOT_FOUND, ERROR_INVALID_PARAMETER:
			return "", Errno(err);
		case ERROR_NOT_ENOUGH_MEMORY:
			MAX_PATH = MAX_PATH*2 + 1;
			continue;
		}
		break;
	}
	return cleanpath_from_buf(buf), ERROR_NONE;
}
@(private)
cleanpath_from_handle_u16 :: proc(fd: Handle) -> ([]u16, Errno) {
	if fd == 0 {
		return nil, ERROR_INVALID_HANDLE;
	}
	h := win32.HANDLE(fd);

	MAX_PATH := win32.DWORD(260) + 1;
	buf: []u16;
	for {
		buf = make([]u16, MAX_PATH, context.temp_allocator);
		err := win32.GetFinalPathNameByHandleW(h, raw_data(buf), MAX_PATH, 0);
		switch Errno(err) {
		case ERROR_PATH_NOT_FOUND, ERROR_INVALID_PARAMETER:
			return nil, Errno(err);
		case ERROR_NOT_ENOUGH_MEMORY:
			MAX_PATH = MAX_PATH*2 + 1;
			continue;
		}
		break;
	}
	return cleanpath_strip_prefix(buf), ERROR_NONE;
}
@(private)
cleanpath_from_buf :: proc(buf: []u16) -> string {
	buf := buf;
	buf = cleanpath_strip_prefix(buf);
	return win32.utf16_to_utf8(buf, context.allocator);
}

@(private)
basename :: proc(name: string) -> (base: string) {
	name := name;
	if len(name) > 3 && name[:3] == `\\?` {
		name = name[3:];
	}

	if len(name) == 2 && name[1] == ':' {
		return ".";
	} else if len(name) > 2 && name[1] == ':' {
		name = name[2:];
	}
	i := len(name)-1;

	for ; i > 0 && (name[i] == '/' || name[i] == '\\'); i -= 1 {
		name = name[:i];
	}
	for i -= 1; i >= 0; i -= 1 {
		if name[i] == '/' || name[i] == '\\' {
			name = name[i+1:];
			break;
		}
	}
	return name;
}

@(private)
file_type_mode :: proc(h: win32.HANDLE) -> File_Mode {
	switch win32.GetFileType(h) {
	case win32.FILE_TYPE_PIPE:
		return File_Mode_Named_Pipe;
	case win32.FILE_TYPE_CHAR:
		return File_Mode_Device | File_Mode_Char_Device;
	}
	return 0;
}

@(private)
stat_from_file_information :: proc(path: string, h: win32.HANDLE) -> (File_Info, Errno) {
	d: win32.BY_HANDLE_FILE_INFORMATION;
	if !win32.GetFileInformationByHandle(h, &d) {
		err := Errno(win32.GetLastError());
		return {}, err;

	}

	ti: win32.FILE_ATTRIBUTE_TAG_INFO;
	if !win32.GetFileInformationByHandleEx(h, .FileAttributeTagInfo, &ti, size_of(ti)) {
		err := win32.GetLastError();
		if err != u32(ERROR_INVALID_PARAMETER) {
			return {}, Errno(err);
		}
		// Indicate this is a symlink on FAT file systems
		ti.ReparseTag = 0;
	}

	fi: File_Info;

	fi.fullpath = path;
	fi.name = basename(path);
	fi.size = i64(d.nFileSizeHigh)<<32 + i64(d.nFileSizeLow);

	if ti.FileAttributes & win32.FILE_ATTRIBUTE_READONLY != 0 {
		fi.mode |= 0o444;
	} else {
		fi.mode |= 0o666;
	}

	is_sym := false;
	if ti.FileAttributes & win32.FILE_ATTRIBUTE_REPARSE_Point == 0 {
		is_sym = false;
	} else {
		is_sym = ti.ReparseTag == win32.IO_REPARSE_TAG_SYMLINK || ti.ReparseTag == win32.IO_REPARSE_TAG_MOUNT_POINT;
	}

	if is_sym {
		fi.mode |= File_Mode_Sym_Link;
	} else {
		if ti.FileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
			fi.mode |= 0o111 | File_Mode_Dir;
		}

		fi.mode |= file_type_mode(h);
	}

	fi.creation_time     = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftCreationTime));
	fi.modification_time = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastWriteTime));
	fi.access_time       = time.unix(0, win32.FILETIME_as_unix_nanoseconds(d.ftLastAccessTime));

	fi.is_dir = fi.mode & File_Mode_Dir != 0;

	return fi, ERROR_NONE;
}
