//+private
package os2

import "core:io"
import "core:mem"
import "core:sync"
import "core:runtime"
import "core:strings"
import "core:time"
import "core:unicode/utf16"
import win32 "core:sys/windows"

INVALID_HANDLE :: ~uintptr(0)

S_IWRITE :: 0o200
_ERROR_BAD_NETPATH :: 53
MAX_RW :: 1<<30

_file_allocator :: proc() -> runtime.Allocator {
	return heap_allocator()
}

_temp_allocator :: proc() -> runtime.Allocator {
	// TODO(bill): make this not depend on the context allocator
	return context.temp_allocator
}


_File_Kind :: enum u8 {
	File,
	Console,
	Pipe,
}

_File :: struct {
	fd:   rawptr,
	name: string,
	wname: win32.wstring,
	kind: _File_Kind,

	stream: io.Stream,

	allocator: runtime.Allocator,

	rw_mutex: sync.RW_Mutex, // read write calls
	p_mutex:  sync.Mutex, // pread pwrite calls
}

_handle :: proc(f: ^File) -> win32.HANDLE {
	return win32.HANDLE(_fd(f))
}

_open_internal :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (handle: uintptr, err: Error) {
	if len(name) == 0 {
		err = .Not_Exist
		return
	}

	path := _fix_long_path(name)
	access: u32
	switch flags & {.Read, .Write} {
	case {.Read}:         access = win32.FILE_GENERIC_READ
	case {.Write}:        access = win32.FILE_GENERIC_WRITE
	case {.Read, .Write}: access = win32.FILE_GENERIC_READ | win32.FILE_GENERIC_WRITE
	}

	if .Create in flags {
		access |= win32.FILE_GENERIC_WRITE
	}
	if .Append in flags {
		access &~= win32.FILE_GENERIC_WRITE
		access |= win32.FILE_APPEND_DATA
	}
	share_mode := u32(win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE)
	sa: ^win32.SECURITY_ATTRIBUTES
	if .Close_On_Exec not_in flags {
		sa = &win32.SECURITY_ATTRIBUTES{}
		sa.nLength = size_of(win32.SECURITY_ATTRIBUTES)
		sa.bInheritHandle = true
	}

	create_mode: u32 = win32.OPEN_EXISTING
	switch {
	case flags & {.Create, .Excl} == {.Create, .Excl}:
		create_mode = win32.CREATE_NEW
	case flags & {.Create, .Trunc} == {.Create, .Trunc}:
		create_mode = win32.CREATE_ALWAYS
	case flags & {.Create} == {.Create}:
		create_mode = win32.OPEN_ALWAYS
	case flags & {.Trunc} == {.Trunc}:
		create_mode = win32.TRUNCATE_EXISTING
	}

	attrs: u32 = win32.FILE_ATTRIBUTE_NORMAL
	if perm & S_IWRITE == 0 {
		attrs = win32.FILE_ATTRIBUTE_READONLY
		if create_mode == win32.CREATE_ALWAYS {
			// NOTE(bill): Open has just asked to create a file in read-only mode.
			// If the file already exists, to make it akin to a *nix open call,
			// the call preserves the existing permissions.
			h := win32.CreateFileW(path, access, share_mode, sa, win32.TRUNCATE_EXISTING, win32.FILE_ATTRIBUTE_NORMAL, nil)
			if h == win32.INVALID_HANDLE {
				switch e := win32.GetLastError(); e {
				case win32.ERROR_FILE_NOT_FOUND, _ERROR_BAD_NETPATH, win32.ERROR_PATH_NOT_FOUND:
					// file does not exist, create the file
				case 0:
					return uintptr(h), nil
				case:
					return 0, Platform_Error(e)
				}
			}
		}
	}
	h := win32.CreateFileW(path, access, share_mode, sa, create_mode, attrs, nil)
	if h == win32.INVALID_HANDLE {
		return 0, _get_platform_error()
	}
	return uintptr(h), nil
}


_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (f: ^File, err: Error) {
	flags := flags if flags != nil else {.Read}
	handle := _open_internal(name, flags + {.Close_On_Exec}, perm) or_return
	return _new_file(handle, name), nil
}

_new_file :: proc(handle: uintptr, name: string) -> ^File {
	if handle == INVALID_HANDLE {
		return nil
	}
	f := new(File, _file_allocator())

	f.impl.allocator = _file_allocator()
	f.impl.fd = rawptr(handle)
	f.impl.name = strings.clone(name, f.impl.allocator)
	f.impl.wname = win32.utf8_to_wstring(name, f.impl.allocator)

	handle := _handle(f)
	kind := _File_Kind.File
	if m: u32; win32.GetConsoleMode(handle, &m) {
		kind = .Console
	}
	if win32.GetFileType(handle) == win32.FILE_TYPE_PIPE {
		kind = .Pipe
	}
	f.impl.kind = kind

	f.impl.stream = {
		data = f,
		procedure = _file_stream_proc,
	}

	return f
}

_fd :: proc(f: ^File) -> uintptr {
	if f == nil {
		return INVALID_HANDLE
	}
	return uintptr(f.impl.fd)
}

_destroy :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}

	a := f.impl.allocator
	free(f.impl.wname, a)
	delete(f.impl.name, a)
	free(f, a)
	return nil
}


_close :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}
	if !win32.CloseHandle(win32.HANDLE(f.impl.fd)) {
		return .Closed
	}
	return _destroy(f)
}

_name :: proc(f: ^File) -> string {
	return f.impl.name if f != nil else ""
}

_seek :: proc(f: ^File, offset: i64, whence: io.Seek_From) -> (ret: i64, err: Error) {
	handle := _handle(f)
	if handle == win32.INVALID_HANDLE {
		return 0, .Invalid_File
	}
	if f.impl.kind == .Pipe {
		return 0, .Invalid_File
	}

	sync.guard(&f.impl.rw_mutex)

	w: u32
	switch whence {
	case .Start:   w = win32.FILE_BEGIN
	case .Current: w = win32.FILE_CURRENT
	case .End:     w = win32.FILE_END
	}
	hi := i32(offset>>32)
	lo := i32(offset)

	dw_ptr := win32.SetFilePointer(handle, lo, &hi, w)
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		return 0, _get_platform_error()
	}
	return i64(hi)<<32 + i64(dw_ptr), nil
}

_read :: proc(f: ^File, p: []byte) -> (n: i64, err: Error) {
	read_console :: proc(handle: win32.HANDLE, b: []byte) -> (n: int, err: Error) {
		if len(b) == 0 {
			return 0, nil
		}

		// TODO(bill): should this be moved to `_File` instead?
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
				err = _get_platform_error()
			}

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

	handle := _handle(f)

	single_read_length: win32.DWORD
	total_read: int
	length := len(p)

	sync.shared_guard(&f.impl.rw_mutex) // multiple readers

	if sync.guard(&f.impl.p_mutex) {
		to_read := min(win32.DWORD(length), MAX_RW)
		ok: win32.BOOL
		if f.impl.kind == .Console {
			n, err := read_console(handle, p[total_read:][:to_read])
			total_read += n
			if err != nil {
				return i64(total_read), err
			}
		} else {
			ok = win32.ReadFile(handle, &p[total_read], to_read, &single_read_length, nil)
		}

		if single_read_length > 0 && ok {
			total_read += int(single_read_length)
		} else {
			err = _get_platform_error()
		}
	}

	return i64(total_read), err
}

_read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: i64, err: Error) {
	pread :: proc(f: ^File, data: []byte, offset: i64) -> (n: i64, err: Error) {
		buf := data
		if len(buf) > MAX_RW {
			buf = buf[:MAX_RW]

		}
		curr_offset := seek(f, offset, .Current) or_return
		defer seek(f, curr_offset, .Start)

		o := win32.OVERLAPPED{
			OffsetHigh = u32(offset>>32),
			Offset = u32(offset),
		}

		// TODO(bill): Determine the correct behaviour for consoles

		h := _handle(f)
		done: win32.DWORD
		if !win32.ReadFile(h, raw_data(buf), u32(len(buf)), &done, &o) {
			err = _get_platform_error()
			done = 0
		}
		n = i64(done)
		return
	}

	sync.guard(&f.impl.p_mutex)

	p, offset := p, offset
	for len(p) > 0 {
		m := pread(f, p, offset) or_return
		n += m
		p = p[m:]
		offset += i64(m)
	}
	return
}

_write :: proc(f: ^File, p: []byte) -> (n: i64, err: Error) {
	if len(p) == 0 {
		return
	}

	single_write_length: win32.DWORD
	total_write: i64
	length := i64(len(p))

	handle := _handle(f)

	sync.guard(&f.impl.rw_mutex)
	for total_write < length {
		remaining := length - total_write
		to_write := win32.DWORD(min(i32(remaining), MAX_RW))

		e := win32.WriteFile(handle, &p[total_write], to_write, &single_write_length, nil)
		if single_write_length <= 0 || !e {
			n = i64(total_write)
			err = _get_platform_error()
			return
		}
		total_write += i64(single_write_length)
	}
	return i64(total_write), nil
}

_write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: i64, err: Error) {
	pwrite :: proc(f: ^File, data: []byte, offset: i64) -> (n: i64, err: Error) {
		buf := data
		if len(buf) > MAX_RW {
			buf = buf[:MAX_RW]

		}
		curr_offset := seek(f, offset, .Current) or_return
		defer seek(f, curr_offset, .Start)

		o := win32.OVERLAPPED{
			OffsetHigh = u32(offset>>32),
			Offset = u32(offset),
		}

		h := _handle(f)
		done: win32.DWORD
		if !win32.WriteFile(h, raw_data(buf), u32(len(buf)), &done, &o) {
			err = _get_platform_error()
			done = 0
		}
		n = i64(done)
		return
	}

	sync.guard(&f.impl.p_mutex)
	p, offset := p, offset
	for len(p) > 0 {
		m := pwrite(f, p, offset) or_return
		n += m
		p = p[m:]
		offset += i64(m)
	}
	return
}

_file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	length: win32.LARGE_INTEGER
	handle := _handle(f)
	if !win32.GetFileSizeEx(handle, &length) {
		err = _get_platform_error()
	}
	n = i64(length)
	return
}


_sync :: proc(f: ^File) -> Error {
	return _flush(f)
}

_flush :: proc(f: ^File) -> Error {
	handle := _handle(f)
	if !win32.FlushFileBuffers(handle) {
		return _get_platform_error()
	}
	return nil
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	if f == nil {
		return nil
	}
	curr_off := seek(f, 0, .Current) or_return
	defer seek(f, curr_off, .Start)
	seek(f, size, .Start) or_return
	handle := _handle(f)
	if !win32.SetEndOfFile(handle) {
		return _get_platform_error()
	}
	return nil
}

_remove :: proc(name: string) -> Error {
	p := _fix_long_path(name)
	err, err1: Error
	if !win32.DeleteFileW(p) {
		err = _get_platform_error()
	}
	if err == nil {
		return nil
	}
	if !win32.RemoveDirectoryW(p) {
		err1 = _get_platform_error()
	}
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
					err = nil
					if !win32.DeleteFileW(p) {
						err = _get_platform_error()
					}
				}
			}
		}
	}

	return err
}

_rename :: proc(old_path, new_path: string) -> Error {
	from := _fix_long_path(old_path)
	to := _fix_long_path(new_path)
	if win32.MoveFileExW(from, to, win32.MOVEFILE_REPLACE_EXISTING) {
		return nil
	}
	return _get_platform_error()

}


_link :: proc(old_name, new_name: string) -> Error {
	o := _fix_long_path(old_name)
	n := _fix_long_path(new_name)
	if win32.CreateHardLinkW(n, o, nil) {
		return nil
	}
	return _get_platform_error()
}

_symlink :: proc(old_name, new_name: string) -> Error {
	return .Unsupported
}

_open_sym_link :: proc(p: [^]u16) -> (handle: win32.HANDLE, err: Error) {
	attrs := u32(win32.FILE_FLAG_BACKUP_SEMANTICS)
	attrs |= win32.FILE_FLAG_OPEN_REPARSE_POINT
	handle = win32.CreateFileW(p, 0, 0, nil, win32.OPEN_EXISTING, attrs, nil)
	if handle == win32.INVALID_HANDLE {
		return nil, _get_platform_error()
	}
	return

}

_normalize_link_path :: proc(p: []u16, allocator: runtime.Allocator) -> (str: string, err: Error) {
	has_prefix :: proc(p: []u16, str: string) -> bool {
		if len(p) < len(str) {
			return false
		}
		// assume ascii
		for i in 0..<len(str) {
			if p[i] != u16(str[i]) {
				return false
			}
		}
		return true
	}
	has_unc_prefix :: proc(p: []u16) -> bool {
		return has_prefix(p, `\??\`)
	}

	if !has_unc_prefix(p) {
		return win32.utf16_to_utf8(p, allocator)
	}

	ws := p[4:]
	switch {
	case len(ws) >= 2 && ws[1] == ':':
		return win32.utf16_to_utf8(ws, allocator)
	case has_prefix(ws, `UNC\`):
		ws[3] = '\\' // override data in buffer
		return win32.utf16_to_utf8(ws[3:], allocator)
	}


	handle := _open_sym_link(raw_data(p)) or_return
	defer win32.CloseHandle(handle)

	n := win32.GetFinalPathNameByHandleW(handle, nil, 0, win32.VOLUME_NAME_DOS)
	if n == 0 {
		return "", _get_platform_error()
	}
	buf := make([]u16, n+1, _temp_allocator())
	n = win32.GetFinalPathNameByHandleW(handle, raw_data(buf), u32(len(buf)), win32.VOLUME_NAME_DOS)
	if n == 0 {
		return "", _get_platform_error()
	}

	ws = buf[:n]
	if has_unc_prefix(ws) {
		ws = ws[4:]
		if len(ws) > 3 && has_prefix(ws, `UNC`) {
			ws[2] = '\\'
			return win32.utf16_to_utf8(ws[2:], allocator)
		}
		return win32.utf16_to_utf8(ws, allocator)
	}
	return "", .Invalid_Path
}

_read_link :: proc(name: string, allocator: runtime.Allocator) -> (s: string, err: Error) {
	MAXIMUM_REPARSE_DATA_BUFFER_SIZE :: 16 * 1024

	@thread_local
	rdb_buf: [MAXIMUM_REPARSE_DATA_BUFFER_SIZE]byte

	p := _fix_long_path(name)
	handle := _open_sym_link(p) or_return
	defer win32.CloseHandle(handle)

	bytes_returned: u32
	if !win32.DeviceIoControl(handle, win32.FSCTL_GET_REPARSE_POINT, nil, 0, &rdb_buf[0], len(rdb_buf)-1, &bytes_returned, nil) {
		err = _get_platform_error()
		return
	}
	mem.zero_slice(rdb_buf[:min(bytes_returned+1, len(rdb_buf))])


	rdb := (^win32.REPARSE_DATA_BUFFER)(&rdb_buf[0])
	switch rdb.ReparseTag {
	case win32.IO_REPARSE_TAG_SYMLINK:
		rb := (^win32.SYMBOLIC_LINK_REPARSE_BUFFER)(&rdb.rest)
		pb := win32.wstring(&rb.PathBuffer)
		pb[rb.SubstituteNameOffset+rb.SubstituteNameLength] = 0
		p := pb[rb.SubstituteNameOffset:][:rb.SubstituteNameLength]
		if rb.Flags & win32.SYMLINK_FLAG_RELATIVE != 0 {
			return win32.utf16_to_utf8(p, allocator)
		}
		return _normalize_link_path(p, allocator)

	case win32.IO_REPARSE_TAG_MOUNT_POINT:
		rb := (^win32.MOUNT_POINT_REPARSE_BUFFER)(&rdb.rest)
		pb := win32.wstring(&rb.PathBuffer)
		pb[rb.SubstituteNameOffset+rb.SubstituteNameLength] = 0
		p := pb[rb.SubstituteNameOffset:][:rb.SubstituteNameLength]
		return _normalize_link_path(p, allocator)
	}
	// Path wasn't a symlink/junction but another reparse point kind
	return "", nil
}


_fchdir :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}
	if !win32.SetCurrentDirectoryW(f.impl.wname) {
		return _get_platform_error()
	}
	return nil
}

_fchmod :: proc(f: ^File, mode: File_Mode) -> Error {
	if f == nil {
		return nil
	}
	d: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(_handle(f), &d) {
		return _get_platform_error()
	}
	attrs := d.dwFileAttributes
	if mode & S_IWRITE != 0 {
		attrs &~= win32.FILE_ATTRIBUTE_READONLY
	} else {
		attrs |= win32.FILE_ATTRIBUTE_READONLY
	}

	info: win32.FILE_BASIC_INFO
	info.FileAttributes = attrs
	if !win32.SetFileInformationByHandle(_handle(f), .FileBasicInfo, &info, size_of(d)) {
		return _get_platform_error()
	}
	return nil
}

_fchown :: proc(f: ^File, uid, gid: int) -> Error {
	return .Unsupported
}

_chdir :: proc(name: string) -> Error {
	p := _fix_long_path(name)
	if !win32.SetCurrentDirectoryW(p) {
		return _get_platform_error()
	}
	return nil
}

_chmod :: proc(name: string, mode: File_Mode) -> Error {
	f := open(name, {.Write}) or_return
	defer close(f)
	return _fchmod(f, mode)
}

_chown :: proc(name: string, uid, gid: int) -> Error {
	return .Unsupported
}

_lchown :: proc(name: string, uid, gid: int) -> Error {
	return .Unsupported
}


_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	f := open(name, {.Write}) or_return
	defer close(f)
	return _fchtimes(f, atime, mtime)
}
_fchtimes :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	if f == nil {
		return nil
	}
	d: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(_handle(f), &d) {
		return _get_platform_error()
	}

	to_windows_time :: #force_inline proc(t: time.Time) -> win32.LARGE_INTEGER {
		// a 64-bit value representing the number of 100-nanosecond intervals since January 1, 1601 (UTC)
		return win32.LARGE_INTEGER(time.time_to_unix_nano(t) * 100 + 116444736000000000)
	}

	atime, mtime := atime, mtime
	if time.time_to_unix_nano(atime) < time.time_to_unix_nano(mtime) {
		atime = mtime
	}

	info: win32.FILE_BASIC_INFO
	info.LastAccessTime = to_windows_time(atime)
	info.LastWriteTime  = to_windows_time(mtime)
	if !win32.SetFileInformationByHandle(_handle(f), .FileBasicInfo, &info, size_of(d)) {
		return _get_platform_error()
	}
	return nil
}



_exists :: proc(path: string) -> bool {
	wpath := _fix_long_path(path)
	attribs := win32.GetFileAttributesW(wpath)
	return i32(attribs) != win32.INVALID_FILE_ATTRIBUTES
}

_is_file :: proc(path: string) -> bool {
	wpath := _fix_long_path(path)
	attribs := win32.GetFileAttributesW(wpath)
	if i32(attribs) != win32.INVALID_FILE_ATTRIBUTES {
		return attribs & win32.FILE_ATTRIBUTE_DIRECTORY == 0
	}
	return false
}

_is_dir :: proc(path: string) -> bool {
	wpath := _fix_long_path(path)
	attribs := win32.GetFileAttributesW(wpath)
	if i32(attribs) != win32.INVALID_FILE_ATTRIBUTES {
		return attribs & win32.FILE_ATTRIBUTE_DIRECTORY != 0
	}
	return false
}


@(private="package")
_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^File)(stream_data)
	ferr: Error
	i: int
	switch mode {
	case .Read:
		n, ferr = _read(f, p)
		err = error_to_io_error(ferr)
		return
	case .Read_At:
		n, ferr = _read_at(f, p, offset)
		err = error_to_io_error(ferr)
		return
	case .Write:
		n, ferr = _write(f, p)
		err = error_to_io_error(ferr)
		return
	case .Write_At:
		n, ferr = _write_at(f, p, offset)
		err = error_to_io_error(ferr)
		return
	case .Seek:
		n, ferr = _seek(f, offset, whence)
		err = error_to_io_error(ferr)
		return
	case .Size:
		n, ferr = _file_size(f)
		err = error_to_io_error(ferr)
		return
	case .Flush:
		ferr = _flush(f)
		err = error_to_io_error(ferr)
		return
	case .Close:
		ferr = _close(f)
		err = error_to_io_error(ferr)
		return
	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Flush, .Close, .Query})
	case .Destroy:
		return 0, .Empty
	}
	return 0, .Empty
}

