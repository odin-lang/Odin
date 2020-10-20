package os

import win32 "core:sys/windows"
import "intrinsics"

is_path_separator :: proc(c: byte) -> bool {
	return c == '/' || c == '\\';
}

open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Errno) {
	if len(path) == 0 {
		return INVALID_HANDLE, ERROR_FILE_NOT_FOUND;
	}

	access: u32;
	switch mode & (O_RDONLY|O_WRONLY|O_RDWR) {
	case O_RDONLY: access = win32.FILE_GENERIC_READ;
	case O_WRONLY: access = win32.FILE_GENERIC_WRITE;
	case O_RDWR:   access = win32.FILE_GENERIC_READ | win32.FILE_GENERIC_WRITE;
	}

	if mode&O_APPEND != 0 {
		access &~= win32.FILE_GENERIC_WRITE;
		access |=  win32.FILE_APPEND_DATA;
	}
	if mode&O_CREATE != 0 {
		access |= win32.FILE_GENERIC_WRITE;
	}

	share_mode := u32(win32.FILE_SHARE_READ|win32.FILE_SHARE_WRITE);
	sa: ^win32.SECURITY_ATTRIBUTES = nil;
	sa_inherit := win32.SECURITY_ATTRIBUTES{nLength = size_of(win32.SECURITY_ATTRIBUTES), bInheritHandle = true};
	if mode&O_CLOEXEC == 0 {
		sa = &sa_inherit;
	}

	create_mode: u32;
	switch {
	case mode&(O_CREATE|O_EXCL) == (O_CREATE | O_EXCL):
		create_mode = win32.CREATE_NEW;
	case mode&(O_CREATE|O_TRUNC) == (O_CREATE | O_TRUNC):
		create_mode = win32.CREATE_ALWAYS;
	case mode&O_CREATE == O_CREATE:
		create_mode = win32.OPEN_ALWAYS;
	case mode&O_TRUNC == O_TRUNC:
		create_mode = win32.TRUNCATE_EXISTING;
	case:
		create_mode = win32.OPEN_EXISTING;
	}
	wide_path := win32.utf8_to_wstring(path);
	handle := Handle(win32.CreateFileW(auto_cast wide_path, access, share_mode, sa, create_mode, win32.FILE_ATTRIBUTE_NORMAL|win32.FILE_FLAG_BACKUP_SEMANTICS, nil));
	if handle != INVALID_HANDLE {
		return handle, ERROR_NONE;
	}

	err := Errno(win32.GetLastError());
	return INVALID_HANDLE, err;
}

close :: proc(fd: Handle) -> Errno {
	if !win32.CloseHandle(win32.HANDLE(fd)) {
		return Errno(win32.GetLastError());
	}
	return ERROR_NONE;
}

flush :: proc(fd: Handle) -> (err: Errno) {
	if !win32.FlushFileBuffers(win32.HANDLE(fd)) {
		err = Errno(win32.GetLastError());
	}
	return;
}



write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE;
	}

	single_write_length: win32.DWORD;
	total_write: i64;
	length := i64(len(data));

	for total_write < length {
		remaining := length - total_write;
		to_write := win32.DWORD(min(i32(remaining), MAX_RW));

		e := win32.WriteFile(win32.HANDLE(fd), &data[total_write], to_write, &single_write_length, nil);
		if single_write_length <= 0 || !e {
			err := Errno(win32.GetLastError());
			return int(total_write), err;
		}
		total_write += i64(single_write_length);
	}
	return int(total_write), ERROR_NONE;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE;
	}

	single_read_length: win32.DWORD;
	total_read: i64;
	length := i64(len(data));

	for total_read < length {
		remaining := length - total_read;
		to_read := win32.DWORD(min(u32(remaining), MAX_RW));

		e := win32.ReadFile(win32.HANDLE(fd), &data[total_read], to_read, &single_read_length, nil);
		if single_read_length <= 0 || !e {
			err := Errno(win32.GetLastError());
			return int(total_read), err;
		}
		total_read += i64(single_read_length);
	}
	return int(total_read), ERROR_NONE;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	w: u32;
	switch whence {
	case 0: w = win32.FILE_BEGIN;
	case 1: w = win32.FILE_CURRENT;
	case 2: w = win32.FILE_END;
	}
	hi := i32(offset>>32);
	lo := i32(offset);
	ft := win32.GetFileType(win32.HANDLE(fd));
	if ft == win32.FILE_TYPE_PIPE {
		return 0, ERROR_FILE_IS_PIPE;
	}

	dw_ptr := win32.SetFilePointer(win32.HANDLE(fd), lo, &hi, w);
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		err := Errno(win32.GetLastError());
		return 0, err;
	}
	return i64(hi)<<32 + i64(dw_ptr), ERROR_NONE;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	length: win32.LARGE_INTEGER;
	err: Errno;
	if !win32.GetFileSizeEx(win32.HANDLE(fd), &length) {
		err = Errno(win32.GetLastError());
	}
	return i64(length), err;
}


@(private)
MAX_RW :: 1<<30;

@(private)
pread :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	buf := data;
	if len(buf) > MAX_RW {
		buf = buf[:MAX_RW];

	}
	curr_offset, e := seek(fd, offset, 1);
	if e != 0 {
		return 0, e;
	}
	defer seek(fd, curr_offset, 0);

	o := win32.OVERLAPPED{
		OffsetHigh = u32(offset>>32),
		Offset = u32(offset),
	};

	h := win32.HANDLE(fd);
	done: win32.DWORD;
	if !win32.ReadFile(h, raw_data(buf), u32(len(buf)), &done, &o) {
		e = Errno(win32.GetLastError());
		done = 0;
	}
	return int(done), e;
}
@(private)
pwrite :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	buf := data;
	if len(buf) > MAX_RW {
		buf = buf[:MAX_RW];

	}
	curr_offset, e := seek(fd, offset, 1);
	if e != 0 {
		return 0, e;
	}
	defer seek(fd, curr_offset, 0);

	o := win32.OVERLAPPED{
		OffsetHigh = u32(offset>>32),
		Offset = u32(offset),
	};

	h := win32.HANDLE(fd);
	done: win32.DWORD;
	if !win32.WriteFile(h, raw_data(buf), u32(len(buf)), &done, &o) {
		e = Errno(win32.GetLastError());
		done = 0;
	}
	return int(done), e;
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Errno) {
	if offset < 0 {
		return 0, ERROR_NEGATIVE_OFFSET;
	}

	b, offset := data, offset;
	for len(b) > 0 {
		m, e := pread(fd, b, offset);
		if e != 0 {
			err = e;
			break;
		}
		n += m;
		b = b[m:];
		offset += i64(m);
	}
	return;
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Errno) {
	if offset < 0 {
		return 0, ERROR_NEGATIVE_OFFSET;
	}

	b, offset := data, offset;
	for len(b) > 0 {
		m, e := pwrite(fd, b, offset);
		if e != 0 {
			err = e;
			break;
		}
		n += m;
		b = b[m:];
		offset += i64(m);
	}
	return;
}



// NOTE(bill): Uses startup to initialize it
stdin  := get_std_handle(uint(win32.STD_INPUT_HANDLE));
stdout := get_std_handle(uint(win32.STD_OUTPUT_HANDLE));
stderr := get_std_handle(uint(win32.STD_ERROR_HANDLE));


get_std_handle :: proc "contextless" (h: uint) -> Handle {
	fd := win32.GetStdHandle(win32.DWORD(h));
	when size_of(uintptr) == 8 {
		win32.SetHandleInformation(fd, win32.HANDLE_FLAG_INHERIT, 0);
	}
	return Handle(fd);
}


exists :: proc(path: string) -> bool {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	attribs := win32.GetFileAttributesW(wpath);

	return i32(attribs) != win32.INVALID_FILE_ATTRIBUTES;
}

is_file :: proc(path: string) -> bool {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	attribs := win32.GetFileAttributesW(wpath);

	if i32(attribs) != win32.INVALID_FILE_ATTRIBUTES {
		return attribs & win32.FILE_ATTRIBUTE_DIRECTORY == win32.FILE_ATTRIBUTE_DIRECTORY;
	}
	return false;
}

is_dir :: proc(path: string) -> bool {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	attribs := win32.GetFileAttributesW(wpath);

	if i32(attribs) != win32.INVALID_FILE_ATTRIBUTES {
		return attribs & win32.FILE_ATTRIBUTE_DIRECTORY != win32.FILE_ATTRIBUTE_DIRECTORY;
	}
	return false;
}

// NOTE(tetra): GetCurrentDirectory is not thread safe with SetCurrentDirectory and GetFullPathName
@private cwd_lock := win32.SRWLOCK{}; // zero is initialized

get_current_directory :: proc(allocator := context.allocator) -> string {
	win32.AcquireSRWLockExclusive(&cwd_lock);

	sz_utf16 := win32.GetCurrentDirectoryW(0, nil);
	dir_buf_wstr := make([]u16, sz_utf16, context.temp_allocator); // the first time, it _includes_ the NUL.

	sz_utf16 = win32.GetCurrentDirectoryW(win32.DWORD(len(dir_buf_wstr)), raw_data(dir_buf_wstr));
	assert(int(sz_utf16)+1 == len(dir_buf_wstr)); // the second time, it _excludes_ the NUL.

	win32.ReleaseSRWLockExclusive(&cwd_lock);

	return win32.utf16_to_utf8(dir_buf_wstr, allocator);
}

set_current_directory :: proc(path: string) -> (err: Errno) {
	wstr := win32.utf8_to_wstring(path);

	win32.AcquireSRWLockExclusive(&cwd_lock);

	if !win32.SetCurrentDirectoryW(wstr) {
		err = Errno(win32.GetLastError());
	}

	win32.ReleaseSRWLockExclusive(&cwd_lock);

	return;
}



change_directory :: proc(path: string) -> Errno {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	return Errno(win32.SetCurrentDirectoryW(wpath));
}

make_directory :: proc(path: string, mode: u32) -> Errno {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	return Errno(win32.CreateDirectoryW(wpath, nil));
}


remove_directory :: proc(path: string) -> Errno {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	return Errno(win32.RemoveDirectoryW(wpath));
}



@(private)
is_abs :: proc(path: string) -> bool {
	if len(path) > 0 && path[0] == '/' {
		return true;
	}
	when ODIN_OS == "windows" {
		if len(path) > 2 {
			switch path[0] {
			case 'A'..'Z', 'a'..'z':
				return path[1] == ':' && is_path_separator(path[2]);
			}
		}
	}
	return false;
}

@(private)
fix_long_path :: proc(path: string) -> string {
	if len(path) < 248 {
		return path;
	}

	if len(path) >= 2 && path[:2] == `\\` {
		return path;
	}
	if !is_abs(path) {
		return path;
	}

	prefix :: `\\?`;

	path_buf := make([]byte, len(prefix)+len(path)+len(`\`), context.temp_allocator);
	copy(path_buf, prefix);
	n := len(path);
	r, w := 0, len(prefix);
	for r < n {
		switch {
		case is_path_separator(path[r]):
			r += 1;
		case path[r] == '.' && (r+1 == n || is_path_separator(path[r+1])):
			r += 1;
		case r+1 < n && path[r] == '.' && path[r+1] == '.' && (r+2 == n || is_path_separator(path[r+2])):
			return path;
		case:
			path_buf[w] = '\\';
			w += 1;
			for ; r < n && !is_path_separator(path[r]); r += 1 {
				path_buf[w] = path[r];
				w += 1;
			}
		}
	}

	if w == len(`\\?\c:`) {
		path_buf[w] = '\\';
		w += 1;
	}
	return string(path_buf[:w]);
}


link :: proc(old_name, new_name: string) -> Errno {
	n := win32.utf8_to_wstring(fix_long_path(new_name));
	o := win32.utf8_to_wstring(fix_long_path(old_name));
	return Errno(win32.CreateHardLinkW(n, o, nil));
}

unlink :: proc(path: string) -> Errno {
	wpath := win32.utf8_to_wstring(path, context.temp_allocator);
	return Errno(win32.DeleteFileW(wpath));
}



rename :: proc(old_path, new_path: string) -> Errno {
	from := win32.utf8_to_wstring(old_path, context.temp_allocator);
	to := win32.utf8_to_wstring(new_path, context.temp_allocator);
	return Errno(win32.MoveFileExW(from, to, win32.MOVEFILE_REPLACE_EXISTING));
}


ftruncate :: proc(fd: Handle, length: i64) -> (err: Errno) {
	curr_off, e := seek(fd, 0, 1);
	if e != 0 {
		return e;
	}
	defer seek(fd, curr_off, 0);
	_, e = seek(fd, length, 0);
	if e != 0 {
		return e;
	}
	ok := win32.SetEndOfFile(win32.HANDLE(fd));
	if !ok {
		return Errno(win32.GetLastError());
	}
	return ERROR_NONE;
}

truncate :: proc(path: string, length: i64) -> (err: Errno) {
	fd: Handle;
	fd, err = open(path, O_WRONLY|O_CREATE, 0o666);
	if err != 0 {
		return;
	}
	defer close(fd);
	err = ftruncate(fd, length);
	return;
}


remove :: proc(name: string) -> Errno {
	p := win32.utf8_to_wstring(fix_long_path(name));
	err, err1: win32.DWORD;
	if !win32.DeleteFileW(p) {
		err = win32.GetLastError();
	}
	if err == 0 {
		return 0;
	}
	if !win32.RemoveDirectoryW(p) {
		err1 = win32.GetLastError();
	}
	if err1 == 0 {
		return 0;
	}

	if err != err1 {
		a := win32.GetFileAttributesW(p);
		if a == ~u32(0) {
			err = win32.GetLastError();
		} else {
			if a & win32.FILE_ATTRIBUTE_DIRECTORY != 0 {
				err = err1;
			} else if a & win32.FILE_ATTRIBUTE_READONLY != 0 {
				if win32.SetFileAttributesW(p, a &~ win32.FILE_ATTRIBUTE_READONLY) {
					err = 0;
					if !win32.DeleteFileW(p) {
						err = win32.GetLastError();
					}
				}
			}
		}
	}

	return Errno(err);
}


pipe :: proc() -> (r, w: Handle, err: Errno) {
	sa: win32.SECURITY_ATTRIBUTES;
	sa.nLength = size_of(win32.SECURITY_ATTRIBUTES);
	sa.bInheritHandle = true;
	if !win32.CreatePipe((^win32.HANDLE)(&r), (^win32.HANDLE)(&w), &sa, 0) {
		err = Errno(win32.GetLastError());
	}
	return;
}

