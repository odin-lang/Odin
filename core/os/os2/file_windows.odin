//+private
package os2

import "core:io"
import "core:time"
import "core:runtime"
import "core:strings"
import win32 "core:sys/windows"

INVALID_HANDLE :: ~uintptr(0)

_file_allocator :: proc() -> runtime.Allocator {
	return heap_allocator()
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
}

_get_platform_error :: proc() -> Error {
	err := i32(win32.GetLastError())
	if err != 0 {
		return Platform_Error{err}
	}
	return nil
}

_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (^File, Error) {
	return nil, nil
}

_new_file :: proc(handle: uintptr, name: string) -> ^File {
	if handle == INVALID_HANDLE {
		return nil
	}
	context.allocator = _file_allocator()
	f := new(File)
	f.impl.fd = rawptr(fd)
	f.impl.name = strings.clone(name, context.allocator)
	f.impl.wname = win32.utf8_to_wstring(name, context.allocator)

	kind := _File_Kind.File
	if m: u32; win32.GetConsoleMode(win32.HANDLE(fd), &m) {
		kind = .Console
	}
	if win32.GetFileType(win32.HANDLE(fd)) == win32.FILE_TYPE_PIPE {
		kind = .Pipe
	}
	f.impl.kind = kind

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

	context.allocator = _file_allocator()
	free(f.impl.wname)
	delete(f.impl.name)
	free(f)
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

_seek :: proc(f: ^File, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	if f == nil {
		return
	}
	w: u32
	switch whence {
	case .Start:   w = win32.FILE_BEGIN
	case .Current: w = win32.FILE_CURRENT
	case .End:     w = win32.FILE_END
	}
	hi := i32(offset>>32)
	lo := i32(offset)
	ft := win32.GetFileType(win32.HANDLE(fd))
	if ft == win32.FILE_TYPE_PIPE {
		return 0, .Invalid_File
	}

	dw_ptr := win32.SetFilePointer(win32.HANDLE(fd), lo, &hi, w)
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		return 0, _get_platform_error()
	}
	return i64(hi)<<32 + i64(dw_ptr), nil
}

_read :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	return
}

_read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	return
}

_read_from :: proc(f: ^File, r: io.Reader) -> (n: i64, err: Error) {
	return
}

_write :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	return
}

_write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	return
}

_write_to :: proc(f: ^File, w: io.Writer) -> (n: i64, err: Error) {
	return
}

_file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	if f == nil {
		return
	}
	length: win32.LARGE_INTEGER
	if !win32.GetFileSizeEx(win32.HANDLE(fd), &length) {
		err = _get_platform_error()
	}
	n = i64(length)
	return
}


_sync :: proc(f: ^File) -> Error {
	return nil
}

_flush :: proc(f: ^File) -> Error {
	return nil
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	if f == nil {
		return nil
	}
	curr_off := seek(f, 0, .Current) or_return
	defer seek(f, curr_off, .Start)
	seek(f, size, .Start) or_return
	if !win32.SetEndOfFile(win32.HANDLE(fd)) {
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
	return nil
}

_read_link :: proc(name: string) -> (string, Error) {
	return "", nil
}


_chdir :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}
	if win32.SetCurrentDirectoryW(f.impl.wname) {
		return nil
	}
	return _get_platform_error()
}

_chmod :: proc(f: ^File, mode: File_Mode) -> Error {
	return nil
}

_chown :: proc(f: ^File, uid, gid: int) -> Error {
	return nil
}


_lchown :: proc(name: string, uid, gid: int) -> Error {
	return nil
}


_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
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
