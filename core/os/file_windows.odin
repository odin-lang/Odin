package os

import win32 "core:sys/windows"
import "base:intrinsics"
import "base:runtime"
import "core:unicode/utf16"

@(require_results)
is_path_separator :: proc(c: byte) -> bool {
	return c == '/' || c == '\\'
}

@(require_results)
open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Error) {
	if len(path) == 0 {
		return INVALID_HANDLE, General_Error.Not_Exist
	}

	access: u32
	switch mode & (O_RDONLY|O_WRONLY|O_RDWR) {
	case O_RDONLY: access = win32.FILE_GENERIC_READ
	case O_WRONLY: access = win32.FILE_GENERIC_WRITE
	case O_RDWR:   access = win32.FILE_GENERIC_READ | win32.FILE_GENERIC_WRITE
	}

	if mode&O_CREATE != 0 {
		access |= win32.FILE_GENERIC_WRITE
	}
	if mode&O_APPEND != 0 {
		access &~= win32.FILE_GENERIC_WRITE
		access |=  win32.FILE_APPEND_DATA
	}

	share_mode := win32.FILE_SHARE_READ|win32.FILE_SHARE_WRITE
	sa: ^win32.SECURITY_ATTRIBUTES = nil
	sa_inherit := win32.SECURITY_ATTRIBUTES{nLength = size_of(win32.SECURITY_ATTRIBUTES), bInheritHandle = true}
	if mode&O_CLOEXEC == 0 {
		sa = &sa_inherit
	}

	create_mode: u32
	switch {
	case mode&(O_CREATE|O_EXCL) == (O_CREATE | O_EXCL):
		create_mode = win32.CREATE_NEW
	case mode&(O_CREATE|O_TRUNC) == (O_CREATE | O_TRUNC):
		create_mode = win32.CREATE_ALWAYS
	case mode&O_CREATE == O_CREATE:
		create_mode = win32.OPEN_ALWAYS
	case mode&O_TRUNC == O_TRUNC:
		create_mode = win32.TRUNCATE_EXISTING
	case:
		create_mode = win32.OPEN_EXISTING
	}
	wide_path := win32.utf8_to_wstring(path)
	handle := Handle(win32.CreateFileW(wide_path, access, share_mode, sa, create_mode, win32.FILE_ATTRIBUTE_NORMAL|win32.FILE_FLAG_BACKUP_SEMANTICS, nil))
	if handle != INVALID_HANDLE {
		return handle, nil
	}

	return INVALID_HANDLE, get_last_error()
}

close :: proc(fd: Handle) -> Error {
	if !win32.CloseHandle(win32.HANDLE(fd)) {
		return get_last_error()
	}
	return nil
}

flush :: proc(fd: Handle) -> (err: Error) {
	if !win32.FlushFileBuffers(win32.HANDLE(fd)) {
		err = get_last_error()
	}
	return
}



write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	single_write_length: win32.DWORD
	total_write: i64
	length := i64(len(data))

	for total_write < length {
		remaining := length - total_write
		to_write := win32.DWORD(min(i32(remaining), MAX_RW))

		e := win32.WriteFile(win32.HANDLE(fd), &data[total_write], to_write, &single_write_length, nil)
		if single_write_length <= 0 || !e {
			return int(total_write), get_last_error()
		}
		total_write += i64(single_write_length)
	}
	return int(total_write), nil
}

@(private="file", require_results)
read_console :: proc(handle: win32.HANDLE, b: []byte) -> (n: int, err: Error) {
	if len(b) == 0 {
		return 0, nil
	}
	
	BUF_SIZE :: 386
	buf16: [BUF_SIZE]u16
	buf8: [4*BUF_SIZE]u8

	for n < len(b) && err == nil {
		min_read := max(len(b)/4, 1 if len(b) > 0 else 0)
		max_read := u32(min(BUF_SIZE, min_read))
		if max_read == 0 {
			break
		}
		
		single_read_length: u32
		ok := win32.ReadConsoleW(handle, &buf16[0], max_read, &single_read_length, nil)
		if !ok {
			err = get_last_error()
		}

		buf8_len := utf16.decode_to_utf8(buf8[:], buf16[:single_read_length])
		src := buf8[:buf8_len]

		ctrl_z := false
		for i := 0; i < len(src) && n < len(b); i += 1 {
			x := src[i]
			if x == 0x1a { // ctrl-z
				ctrl_z = true
				break
			}
			b[n] = x
			n += 1
		}
		if ctrl_z || single_read_length < max_read {
			break
		}

		// NOTE(bill): if the last two values were a newline, then it is expected that
		// this is the end of the input
		if n >= 2 && single_read_length == max_read && string(b[n-2:n]) == "\r\n" {
			break
		}

	}
	
	return
}

read :: proc(fd: Handle, data: []byte) -> (total_read: int, err: Error) {
	if len(data) == 0 {
		return 0, nil
	}
	
	handle := win32.HANDLE(fd)
	
	m: u32
	is_console := win32.GetConsoleMode(handle, &m)
	length := len(data)

	// NOTE(Jeroen): `length` can't be casted to win32.DWORD here because it'll overflow if > 4 GiB and return 0 if exactly that.
	to_read := min(i64(length), MAX_RW)

	if is_console {
		total_read, err = read_console(handle, data[total_read:][:to_read])
		if err != nil {
			return total_read, err
		}
	} else {
		// NOTE(Jeroen): So we cast it here *after* we've ensured that `to_read` is at most MAX_RW (1 GiB)
		bytes_read: win32.DWORD
		if e := win32.ReadFile(handle, &data[total_read], win32.DWORD(to_read), &bytes_read, nil); e {
			// Successful read can mean two things, including EOF, see:
			// https://learn.microsoft.com/en-us/windows/win32/fileio/testing-for-the-end-of-a-file
			if bytes_read == 0 {
				return 0, .EOF
			} else {
				return int(bytes_read), nil
			}
		} else {
			return 0, get_last_error()
		}
	}
	return total_read, nil
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	w: u32
	switch whence {
	case 0: w = win32.FILE_BEGIN
	case 1: w = win32.FILE_CURRENT
	case 2: w = win32.FILE_END
	case:
		return 0, .Invalid_Whence
	}
	hi := i32(offset>>32)
	lo := i32(offset)
	ft := win32.GetFileType(win32.HANDLE(fd))
	if ft == win32.FILE_TYPE_PIPE {
		return 0, .File_Is_Pipe
	}

	dw_ptr := win32.SetFilePointer(win32.HANDLE(fd), lo, &hi, w)
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		err := get_last_error()
		return 0, err
	}
	return i64(hi)<<32 + i64(dw_ptr), nil
}

@(require_results)
file_size :: proc(fd: Handle) -> (i64, Error) {
	length: win32.LARGE_INTEGER
	err: Error
	if !win32.GetFileSizeEx(win32.HANDLE(fd), &length) {
		err = get_last_error()
	}
	return i64(length), err
}


@(private)
MAX_RW :: 1<<30

@(private)
pread :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	curr_off := seek(fd, 0, 1) or_return
	defer seek(fd, curr_off, 0)

	buf := data
	if len(buf) > MAX_RW {
		buf = buf[:MAX_RW]
	}

	o := win32.OVERLAPPED{
		OffsetHigh = u32(offset>>32),
		Offset = u32(offset),
	}

	// TODO(bill): Determine the correct behaviour for consoles

	h := win32.HANDLE(fd)
	done: win32.DWORD
	e: Error
	if !win32.ReadFile(h, raw_data(buf), u32(len(buf)), &done, &o) {
		e = get_last_error()
		done = 0
	}
	return int(done), e
}
@(private)
pwrite :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	curr_off := seek(fd, 0, 1) or_return
	defer seek(fd, curr_off, 0)

	buf := data
	if len(buf) > MAX_RW {
		buf = buf[:MAX_RW]
	}

	o := win32.OVERLAPPED{
		OffsetHigh = u32(offset>>32),
		Offset = u32(offset),
	}

	h := win32.HANDLE(fd)
	done: win32.DWORD
	e: Error
	if !win32.WriteFile(h, raw_data(buf), u32(len(buf)), &done, &o) {
		e = get_last_error()
		done = 0
	}
	return int(done), e
}

/*
read_at returns n: 0, err: 0 on EOF
*/
read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := data, offset
	for len(b) > 0 {
		m, e := pread(fd, b, offset)
		if e == ERROR_EOF {
			err = nil
			break
		}
		if e != nil {
			err = e
			break
		}
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := data, offset
	for len(b) > 0 {
		m := pwrite(fd, b, offset) or_return
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}



// NOTE(bill): Uses startup to initialize it
stdin  := get_std_handle(uint(win32.STD_INPUT_HANDLE))
stdout := get_std_handle(uint(win32.STD_OUTPUT_HANDLE))
stderr := get_std_handle(uint(win32.STD_ERROR_HANDLE))


@(require_results)
get_std_handle :: proc "contextless" (h: uint) -> Handle {
	fd := win32.GetStdHandle(win32.DWORD(h))
	return Handle(fd)
}


exists :: proc(path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)
	attribs := win32.GetFileAttributesW(wpath)

	return attribs != win32.INVALID_FILE_ATTRIBUTES
}

@(require_results)
is_file :: proc(path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)
	attribs := win32.GetFileAttributesW(wpath)

	if attribs != win32.INVALID_FILE_ATTRIBUTES {
		return attribs & win32.FILE_ATTRIBUTE_DIRECTORY == 0
	}
	return false
}

@(require_results)
is_dir :: proc(path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)
	attribs := win32.GetFileAttributesW(wpath)

	if attribs != win32.INVALID_FILE_ATTRIBUTES {
		return attribs & win32.FILE_ATTRIBUTE_DIRECTORY != 0
	}
	return false
}

// NOTE(tetra): GetCurrentDirectory is not thread safe with SetCurrentDirectory and GetFullPathName
@private cwd_lock := win32.SRWLOCK{} // zero is initialized

@(require_results)
get_current_directory :: proc(allocator := context.allocator) -> string {
	win32.AcquireSRWLockExclusive(&cwd_lock)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	sz_utf16 := win32.GetCurrentDirectoryW(0, nil)
	dir_buf_wstr, _ := make([]u16, sz_utf16, context.temp_allocator) // the first time, it _includes_ the NUL.

	sz_utf16 = win32.GetCurrentDirectoryW(win32.DWORD(len(dir_buf_wstr)), raw_data(dir_buf_wstr))
	assert(int(sz_utf16)+1 == len(dir_buf_wstr)) // the second time, it _excludes_ the NUL.

	win32.ReleaseSRWLockExclusive(&cwd_lock)

	return win32.utf16_to_utf8(dir_buf_wstr, allocator) or_else ""
}

set_current_directory :: proc(path: string) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wstr := win32.utf8_to_wstring(path, context.temp_allocator)

	win32.AcquireSRWLockExclusive(&cwd_lock)

	if !win32.SetCurrentDirectoryW(wstr) {
		err = get_last_error()
	}

	win32.ReleaseSRWLockExclusive(&cwd_lock)

	return
}
change_directory :: set_current_directory

make_directory :: proc(path: string, mode: u32 = 0) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	// Mode is unused on Windows, but is needed on *nix
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)

	if !win32.CreateDirectoryW(wpath, nil) {
		err = get_last_error()
	}
	return
}


remove_directory :: proc(path: string) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)

	if !win32.RemoveDirectoryW(wpath) {
		err = get_last_error()
	}
	return
}



@(private, require_results)
is_abs :: proc(path: string) -> bool {
	if len(path) > 0 && path[0] == '/' {
		return true
	}
	when ODIN_OS == .Windows {
		if len(path) > 2 {
			switch path[0] {
			case 'A'..='Z', 'a'..='z':
				return path[1] == ':' && is_path_separator(path[2])
			}
		}
	}
	return false
}

@(private, require_results)
fix_long_path :: proc(path: string) -> string {
	if len(path) < 248 {
		return path
	}

	if len(path) >= 2 && path[:2] == `\\` {
		return path
	}
	if !is_abs(path) {
		return path
	}

	prefix :: `\\?`

	path_buf, _ := make([]byte, len(prefix)+len(path)+len(`\`), context.temp_allocator)
	copy(path_buf, prefix)
	n := len(path)
	r, w := 0, len(prefix)
	for r < n {
		switch {
		case is_path_separator(path[r]):
			r += 1
		case path[r] == '.' && (r+1 == n || is_path_separator(path[r+1])):
			r += 1
		case r+1 < n && path[r] == '.' && path[r+1] == '.' && (r+2 == n || is_path_separator(path[r+2])):
			return path
		case:
			path_buf[w] = '\\'
			w += 1
			for ; r < n && !is_path_separator(path[r]); r += 1 {
				path_buf[w] = path[r]
				w += 1
			}
		}
	}

	if w == len(`\\?\c:`) {
		path_buf[w] = '\\'
		w += 1
	}
	return string(path_buf[:w])
}


link :: proc(old_name, new_name: string) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	n := win32.utf8_to_wstring(fix_long_path(new_name))
	o := win32.utf8_to_wstring(fix_long_path(old_name))
	return Platform_Error(win32.CreateHardLinkW(n, o, nil))
}

unlink :: proc(path: string) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wpath := win32.utf8_to_wstring(path, context.temp_allocator)

	if !win32.DeleteFileW(wpath) {
		err = get_last_error()
	}
	return
}



rename :: proc(old_path, new_path: string) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	from := win32.utf8_to_wstring(old_path, context.temp_allocator)
	to := win32.utf8_to_wstring(new_path, context.temp_allocator)

	if !win32.MoveFileExW(from, to, win32.MOVEFILE_REPLACE_EXISTING) {
		err = get_last_error()
	}
	return
}


ftruncate :: proc(fd: Handle, length: i64) -> (err: Error) {
	curr_off := seek(fd, 0, 1) or_return
	defer seek(fd, curr_off, 0)
	_= seek(fd, length, 0) or_return
	ok := win32.SetEndOfFile(win32.HANDLE(fd))
	if !ok {
		return get_last_error()
	}
	return nil
}

truncate :: proc(path: string, length: i64) -> (err: Error) {
	fd := open(path, O_WRONLY|O_CREATE, 0o666) or_return
	defer close(fd)
	return ftruncate(fd, length)
}


remove :: proc(name: string) -> Error {
	p := win32.utf8_to_wstring(fix_long_path(name))
	err, err1: win32.DWORD
	if !win32.DeleteFileW(p) {
		err = win32.GetLastError()
	}
	if err == 0 {
		return nil
	}
	if !win32.RemoveDirectoryW(p) {
		err1 = win32.GetLastError()
	}
	if err1 == 0 {
		return nil
	}

	if err != err1 {
		a := win32.GetFileAttributesW(p)
		if a == ~u32(0) {
			err = win32.GetLastError()
		} else {
			if a & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
				err = err1
			} else if a & win32.FILE_ATTRIBUTE_READONLY != 0 {
				if win32.SetFileAttributesW(p, a &~ win32.FILE_ATTRIBUTE_READONLY) {
					err = 0
					if !win32.DeleteFileW(p) {
						err = win32.GetLastError()
					}
				}
			}
		}
	}

	return Platform_Error(err)
}


@(require_results)
pipe :: proc() -> (r, w: Handle, err: Error) {
	sa: win32.SECURITY_ATTRIBUTES
	sa.nLength = size_of(win32.SECURITY_ATTRIBUTES)
	sa.bInheritHandle = true
	if !win32.CreatePipe((^win32.HANDLE)(&r), (^win32.HANDLE)(&w), &sa, 0) {
		err = get_last_error()
	}
	return
}

