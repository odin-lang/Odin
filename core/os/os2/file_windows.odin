//+private
package os2

import "core:io"
import "core:time"
import "core:unicode/utf16"
import win32 "core:sys/windows"

_get_platform_error :: proc() -> Error {
	// TODO(bill): map some of these errors correctly
	err := win32.GetLastError()
	if err == 0 {
		return nil
	}
	return Platform_Error{i32(err)}
}

_ok_or_error :: proc(ok: win32.BOOL) -> Error {
	return nil if ok else _get_platform_error()
}

_std_handle :: proc(kind: Std_Handle_Kind) -> Handle {
	get_handle :: proc(h: win32.DWORD) -> Handle {
		fd := win32.GetStdHandle(h)
		when size_of(uintptr) == 8 {
			win32.SetHandleInformation(fd, win32.HANDLE_FLAG_INHERIT, 0)
		}
		return Handle(fd)
	}

	switch kind {
	case .stdin:  return get_handle(win32.STD_INPUT_HANDLE)
	case .stdout: return get_handle(win32.STD_OUTPUT_HANDLE)
	case .stderr: return get_handle(win32.STD_ERROR_HANDLE)
	}
	unreachable()
}

_opendir :: proc(path: string) -> (handle: Handle, err: Error) {
	return INVALID_HANDLE, .Invalid_Argument
}


_open :: proc(path: string, flags: File_Flags, perm: File_Mode) -> (handle: Handle, err: Error) {
	handle = INVALID_HANDLE
	if len(path) == 0 {
		err = .Not_Exist
		return
	}
	access: u32
	switch flags & O_RDONLY|O_WRONLY|O_RDWR {
	case O_RDONLY: access = win32.FILE_GENERIC_READ
	case O_WRONLY: access = win32.FILE_GENERIC_WRITE
	case O_RDWR:   access = win32.FILE_GENERIC_READ | win32.FILE_GENERIC_WRITE
	}

	if .Append in flags {
		access &~= win32.FILE_GENERIC_WRITE
		access |=  win32.FILE_APPEND_DATA
	}
	if .Create in flags {
		access |= win32.FILE_GENERIC_WRITE
	}

	share_mode := win32.FILE_SHARE_READ|win32.FILE_SHARE_WRITE
	sa: ^win32.SECURITY_ATTRIBUTES = nil
	sa_inherit := win32.SECURITY_ATTRIBUTES{nLength = size_of(win32.SECURITY_ATTRIBUTES), bInheritHandle = true}
	if .Close_On_Exec in flags {
		sa = &sa_inherit
	}

	create_mode: u32
	switch {
	case flags&(O_CREATE|O_EXCL) == (O_CREATE | O_EXCL):
		create_mode = win32.CREATE_NEW
	case flags&(O_CREATE|O_TRUNC) == (O_CREATE | O_TRUNC):
		create_mode = win32.CREATE_ALWAYS
	case flags&O_CREATE == O_CREATE:
		create_mode = win32.OPEN_ALWAYS
	case flags&O_TRUNC == O_TRUNC:
		create_mode = win32.TRUNCATE_EXISTING
	case:
		create_mode = win32.OPEN_EXISTING
	}
	wide_path := win32.utf8_to_wstring(path)
	handle = Handle(win32.CreateFileW(wide_path, access, share_mode, sa, create_mode, win32.FILE_ATTRIBUTE_NORMAL|win32.FILE_FLAG_BACKUP_SEMANTICS, nil))
	if handle == INVALID_HANDLE {
		err = _get_platform_error()
	}
	return
}

_close :: proc(fd: Handle) -> Error {
	if fd == 0 {
		return .Invalid_Argument
	}
	hnd := win32.HANDLE(fd)

	file_info: win32.BY_HANDLE_FILE_INFORMATION
	_ok_or_error(win32.GetFileInformationByHandle(hnd, &file_info)) or_return

	if file_info.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
		return nil
	}

	return _ok_or_error(win32.CloseHandle(hnd))
}

_name :: proc(fd: Handle, allocator := context.allocator) -> string {
	FILE_NAME_NORMALIZED :: 0x0
	handle := win32.HANDLE(fd)
	buf_len := win32.GetFinalPathNameByHandleW(handle, nil, 0, FILE_NAME_NORMALIZED)
	if buf_len == 0 {
		return ""
	}
	buf := make([]u16, buf_len, context.temp_allocator)
	n := win32.GetFinalPathNameByHandleW(handle, raw_data(buf), buf_len, FILE_NAME_NORMALIZED)
	return win32.utf16_to_utf8(buf[:n], allocator)
}

_seek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	new_offset: win32.LARGE_INTEGER
	move_method: win32.DWORD
	switch whence {
	case .Start:   move_method = win32.FILE_BEGIN
	case .Current: move_method = win32.FILE_CURRENT
	case .End:     move_method = win32.FILE_END
	}
	ok := win32.SetFilePointerEx(win32.HANDLE(fd), win32.LARGE_INTEGER(offset), &new_offset, move_method)
	ret = i64(new_offset)
	if !ok {
		err = .Invalid_Whence
	}
	return
}

MAX_RW :: 1<<30

@(private="file")
_read_console :: proc(handle: win32.HANDLE, b: []byte) -> (n: int, err: Error) {
	if len(b) == 0 {
		return 0, nil
	}

	BUF_SIZE :: 386
	buf16: [BUF_SIZE]u16
	buf8: [4*BUF_SIZE]u8

	for n < len(b) && err == nil {
		max_read := u32(min(BUF_SIZE, len(b)/4))

		single_read_length: u32
		err = _ok_or_error(win32.ReadConsoleW(handle, &buf16[0], max_read, &single_read_length, nil))

		buf8_len := utf16.decode_to_utf8(buf8[:], buf16[:single_read_length])
		src := buf8[:buf8_len]

		ctrl_z := false
		for i := 0; i < len(src) && n+i < len(b); i += 1 {
			x := src[i]
			if x == 0x1a { // ctrl-z
				ctrl_z = true
				break
			}
			b[n] = x
			n += 1
		}
		if ctrl_z || single_read_length < len(buf16) {
			break
		}
	}

	return
}

_read :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	if len(p) == 0 {
		return 0, nil
	}

	handle := win32.HANDLE(fd)

	m: u32
	is_console := win32.GetConsoleMode(handle, &m)

	single_read_length: win32.DWORD
	total_read: int
	length := len(p)

	to_read := min(win32.DWORD(length), MAX_RW)

	e: win32.BOOL
	if is_console {
		n, err := _read_console(handle, p[total_read:][:to_read])
		total_read += n
		if err != nil {
			return int(total_read), err
		}
	} else {
		e = win32.ReadFile(handle, &p[total_read], to_read, &single_read_length, nil)
	}
	if single_read_length <= 0 || !e {
		return int(total_read), _get_platform_error()
	}
	total_read += int(single_read_length)

	return int(total_read), nil
}


_read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := _pread(fd, b, offset) or_return
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

_read_from :: proc(fd: Handle, r: io.Reader) -> (n: i64, err: Error) {
	return
}



_pread :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	buf := data
	if len(buf) > MAX_RW {
		buf = buf[:MAX_RW]

	}
	curr_offset := seek(fd, offset, .Current) or_return
	defer seek(fd, curr_offset, .Start)

	o := win32.OVERLAPPED{
		OffsetHigh = u32(offset>>32),
		Offset = u32(offset),
	}

	// TODO(bill): Determine the correct behaviour for consoles

	h := win32.HANDLE(fd)
	done: win32.DWORD
	_ok_or_error(win32.ReadFile(h, raw_data(buf), u32(len(buf)), &done, &o)) or_return
	return int(done), nil
}

_pwrite :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	buf := data
	if len(buf) > MAX_RW {
		buf = buf[:MAX_RW]

	}
	curr_offset := seek(fd, offset, .Current) or_return
	defer seek(fd, curr_offset, .Start)

	o := win32.OVERLAPPED{
		OffsetHigh = u32(offset>>32),
		Offset = u32(offset),
	}

	h := win32.HANDLE(fd)
	done: win32.DWORD
	_ok_or_error(win32.WriteFile(h, raw_data(buf), u32(len(buf)), &done, &o)) or_return
	return int(done), nil
}

_write :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	return
}

_write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := _pwrite(fd, b, offset) or_return
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
	return
}

_file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
	length: win32.LARGE_INTEGER
	err = _ok_or_error(win32.GetFileSizeEx(win32.HANDLE(fd), &length))
	return i64(length), err
}


_sync :: proc(fd: Handle) -> Error {
	return nil
}

_flush :: proc(fd: Handle) -> Error {
	return _ok_or_error(win32.FlushFileBuffers(win32.HANDLE(fd)))
}

_truncate :: proc(fd: Handle, size: i64) -> Error {
	offset := seek(fd, size, .Start) or_return
	defer seek(fd, offset, .Start)

	return _ok_or_error(win32.SetEndOfFile(win32.HANDLE(fd)))
}

_remove :: proc(name: string) -> Error {
	p := win32.utf8_to_wstring(_fix_long_path(name))

	err := _ok_or_error(win32.DeleteFileW(p))
	if err == nil {
		return nil
	}
	err1 := _ok_or_error(win32.RemoveDirectoryW(p))
	if err1 == nil {
		return nil
	}

	if err != err1 {
		a := win32.GetFileAttributesW(p)
		if a == ~u32(0) {
			err = _get_platform_error()
		} else {
			if a & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
				err = err1
			} else if a & win32.FILE_ATTRIBUTE_READONLY != 0 {
				if win32.SetFileAttributesW(p, a &~ win32.FILE_ATTRIBUTE_READONLY) {
					err = _ok_or_error(win32.DeleteFileW(p))
				}
			}
		}
	}

	return err
}

_rename :: proc(old_path, new_path: string) -> Error {
	from := win32.utf8_to_wstring(old_path, context.temp_allocator)
	to := win32.utf8_to_wstring(new_path, context.temp_allocator)
	return _ok_or_error(win32.MoveFileExW(from, to, win32.MOVEFILE_REPLACE_EXISTING))
}


_link :: proc(old_name, new_name: string) -> Error {
	n := win32.utf8_to_wstring(_fix_long_path(new_name))
	o := win32.utf8_to_wstring(_fix_long_path(old_name))
	return _ok_or_error(win32.CreateHardLinkW(n, o, nil))
}

_symlink :: proc(old_name, new_name: string) -> Error {
	return nil
}

_read_link :: proc(name: string) -> (string, Error) {
	return "", nil
}

_unlink :: proc(path: string) -> Error {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)
	return _ok_or_error(win32.DeleteFileW(wpath))
}


_chdir :: proc(fd: Handle) -> Error {
	return nil
}

_chmod :: proc(fd: Handle, mode: File_Mode) -> Error {
	return nil
}

_chown :: proc(fd: Handle, uid, gid: int) -> Error {
	return nil
}


_lchown :: proc(name: string, uid, gid: int) -> Error {
	return nil
}


_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	return nil
}


_exists :: proc(path: string) -> bool {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)
	return bool(win32.PathFileExistsW(wpath))
}

_is_file :: proc(fd: Handle) -> bool {
	hnd := win32.HANDLE(fd)

	file_info: win32.BY_HANDLE_FILE_INFORMATION
	if ok := win32.GetFileInformationByHandle(hnd, &file_info); !ok {
		return false
	}
	no_flags :: win32.FILE_ATTRIBUTE_DIRECTORY | win32.FILE_ATTRIBUTE_DEVICE
	yes_flags :: win32.FILE_ATTRIBUTE_NORMAL
	return (file_info.dwFileAttributes & no_flags == 0) && (file_info.dwFileAttributes & yes_flags != 0)
}

_is_dir :: proc(fd: Handle) -> bool {
	hnd := win32.HANDLE(fd)

	file_info: win32.BY_HANDLE_FILE_INFORMATION
	if ok := win32.GetFileInformationByHandle(hnd, &file_info); !ok {
		return false
	}
	return file_info.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0
}


