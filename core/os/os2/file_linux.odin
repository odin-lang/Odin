//+private
package os2

import "base:runtime"
import "core:io"
import "core:time"
import "core:sys/unix"

INVALID_HANDLE :: -1

_O_RDONLY    :: 0o00000000
_O_WRONLY    :: 0o00000001
_O_RDWR      :: 0o00000002
_O_CREAT     :: 0o00000100
_O_EXCL      :: 0o00000200
_O_NOCTTY    :: 0o00000400
_O_TRUNC     :: 0o00001000
_O_APPEND    :: 0o00002000
_O_NONBLOCK  :: 0o00004000
_O_LARGEFILE :: 0o00100000
_O_DIRECTORY :: 0o00200000
_O_NOFOLLOW  :: 0o00400000
_O_SYNC      :: 0o04010000
_O_CLOEXEC   :: 0o02000000
_O_PATH      :: 0o10000000

_AT_FDCWD :: -100

_CSTRING_NAME_HEAP_THRESHOLD :: 512

_File :: struct {
	name: string,
	fd: int,
	allocator: runtime.Allocator,
}

_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (f: ^File, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	// Just default to using O_NOCTTY because needing to open a controlling
	// terminal would be incredibly rare. This has no effect on files while
	// allowing us to open serial devices.
	flags_i: int = _O_NOCTTY
	switch flags & O_RDONLY|O_WRONLY|O_RDWR {
	case O_RDONLY: flags_i = _O_RDONLY
	case O_WRONLY: flags_i = _O_WRONLY
	case O_RDWR:   flags_i = _O_RDWR
	}

	if .Append        in flags { flags_i |= _O_APPEND  }
	if .Create        in flags { flags_i |= _O_CREAT   }
	if .Excl          in flags { flags_i |= _O_EXCL    }
	if .Sync          in flags { flags_i |= _O_SYNC    }
	if .Trunc         in flags { flags_i |= _O_TRUNC   }
	if .Close_On_Exec in flags { flags_i |= _O_CLOEXEC }

	fd := unix.sys_open(name_cstr, flags_i, uint(perm))
	if fd < 0 {
		return nil, _get_platform_error(fd)
	}

	return _new_file(uintptr(fd), name), nil
}

_new_file :: proc(fd: uintptr, _: string) -> ^File {
	file := new(File, file_allocator())
	file.impl.fd = int(fd)
	file.impl.allocator = file_allocator()
	file.impl.name = _get_full_path(file.impl.fd, file.impl.allocator)
	file.stream = {
		data = file,
		procedure = _file_stream_proc,
	}
	return file
}

_destroy :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}
	delete(f.impl.name, f.impl.allocator)
	free(f, f.impl.allocator)
	return nil
}


_close :: proc(f: ^File) -> Error {
	if f != nil {
		res := unix.sys_close(f.impl.fd)
		_destroy(f)
		return _ok_or_error(res)
	}
	return nil
}

_fd :: proc(f: ^File) -> uintptr {
	if f == nil {
		return ~uintptr(0)
	}
	return uintptr(f.impl.fd)
}

_name :: proc(f: ^File) -> string {
	return f.impl.name if f != nil else ""
}

_seek :: proc(f: ^File, offset: i64, whence: io.Seek_From) -> (ret: i64, err: Error) {
	res := unix.sys_lseek(f.impl.fd, offset, int(whence))
	if res < 0 {
		return -1, _get_platform_error(int(res))
	}
	return res, nil
}

_read :: proc(f: ^File, p: []byte) -> (i64, Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n := unix.sys_read(f.impl.fd, &p[0], len(p))
	if n < 0 {
		return -1, _get_platform_error(n)
	}
	return i64(n), nil
}

_read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: i64, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := unix.sys_pread(f.impl.fd, &b[0], len(b), offset)
		if m < 0 {
			return -1, _get_platform_error(m)
		}
		n += i64(m)
		b = b[m:]
		offset += i64(m)
	}
	return
}

_write :: proc(f: ^File, p: []byte) -> (i64, Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n := unix.sys_write(f.impl.fd, &p[0], uint(len(p)))
	if n < 0 {
		return -1, _get_platform_error(n)
	}
	return i64(n), nil
}

_write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: i64, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := unix.sys_pwrite(f.impl.fd, &b[0], len(b), offset)
		if m < 0 {
			return -1, _get_platform_error(m)
		}
		n += i64(m)
		b = b[m:]
		offset += i64(m)
	}
	return
}

_file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	s: _Stat = ---
	res := unix.sys_fstat(f.impl.fd, &s)
	if res < 0 {
		return -1, _get_platform_error(res)
	}
	return s.size, nil
}

_sync :: proc(f: ^File) -> Error {
	return _ok_or_error(unix.sys_fsync(f.impl.fd))
}

_flush :: proc(f: ^File) -> Error {
	return _ok_or_error(unix.sys_fsync(f.impl.fd))
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	return _ok_or_error(unix.sys_ftruncate(f.impl.fd, size))
}

_remove :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	fd := unix.sys_open(name_cstr, int(File_Flags.Read))
	if fd < 0 {
		return _get_platform_error(fd)
	}
	defer unix.sys_close(fd)

	if _is_dir_fd(fd) {
		return _ok_or_error(unix.sys_rmdir(name_cstr))
	}
	return _ok_or_error(unix.sys_unlink(name_cstr))
}

_rename :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	old_name_cstr := temp_cstring(old_name) or_return
	new_name_cstr := temp_cstring(new_name) or_return

	return _ok_or_error(unix.sys_rename(old_name_cstr, new_name_cstr))
}

_link :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	old_name_cstr := temp_cstring(old_name) or_return
	new_name_cstr := temp_cstring(new_name) or_return

	return _ok_or_error(unix.sys_link(old_name_cstr, new_name_cstr))
}

_symlink :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	old_name_cstr := temp_cstring(old_name) or_return
	new_name_cstr := temp_cstring(new_name) or_return

	return _ok_or_error(unix.sys_symlink(old_name_cstr, new_name_cstr))
}

_read_link_cstr :: proc(name_cstr: cstring, allocator: runtime.Allocator) -> (string, Error) {
	bufsz : uint = 256
	buf := make([]byte, bufsz, allocator)
	for {
		rc := unix.sys_readlink(name_cstr, &buf[0], bufsz)
		if rc < 0 {
			delete(buf)
			return "", _get_platform_error(rc)
		} else if rc == int(bufsz) {
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz, allocator)
		} else {
			return string(buf[:rc]), nil
		}
	}
}

_read_link :: proc(name: string, allocator: runtime.Allocator) -> (path: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _read_link_cstr(name_cstr, allocator)
}

_unlink :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _ok_or_error(unix.sys_unlink(name_cstr))
}

_chdir :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _ok_or_error(unix.sys_chdir(name_cstr))
}

_fchdir :: proc(f: ^File) -> Error {
	return _ok_or_error(unix.sys_fchdir(f.impl.fd))
}

_chmod :: proc(name: string, mode: File_Mode) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _ok_or_error(unix.sys_chmod(name_cstr, uint(mode)))
}

_fchmod :: proc(f: ^File, mode: File_Mode) -> Error {
	return _ok_or_error(unix.sys_fchmod(f.impl.fd, uint(mode)))
}

// NOTE: will throw error without super user priviledges
_chown :: proc(name: string, uid, gid: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _ok_or_error(unix.sys_chown(name_cstr, uid, gid))
}

// NOTE: will throw error without super user priviledges
_lchown :: proc(name: string, uid, gid: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _ok_or_error(unix.sys_lchown(name_cstr, uid, gid))
}

// NOTE: will throw error without super user priviledges
_fchown :: proc(f: ^File, uid, gid: int) -> Error {
	return _ok_or_error(unix.sys_fchown(f.impl.fd, uid, gid))
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	times := [2]Unix_File_Time {
		{ atime._nsec, 0 },
		{ mtime._nsec, 0 },
	}
	return _ok_or_error(unix.sys_utimensat(_AT_FDCWD, name_cstr, &times, 0))
}

_fchtimes :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	times := [2]Unix_File_Time {
		{ atime._nsec, 0 },
		{ mtime._nsec, 0 },
	}
	return _ok_or_error(unix.sys_utimensat(f.impl.fd, nil, &times, 0))
}

_exists :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	return unix.sys_access(name_cstr, F_OK) == 0
}

_is_file :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	s: _Stat
	res := unix.sys_stat(name_cstr, &s)
	if res < 0 {
		return false
	}
	return S_ISREG(s.mode)
}

_is_file_fd :: proc(fd: int) -> bool {
	s: _Stat
	res := unix.sys_fstat(fd, &s)
	if res < 0 { // error
		return false
	}
	return S_ISREG(s.mode)
}

_is_dir :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	s: _Stat
	res := unix.sys_stat(name_cstr, &s)
	if res < 0 {
		return false
	}
	return S_ISDIR(s.mode)
}

_is_dir_fd :: proc(fd: int) -> bool {
	s: _Stat
	res := unix.sys_fstat(fd, &s)
	if res < 0 { // error
		return false
	}
	return S_ISDIR(s.mode)
}

@(private="package")
_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^File)(stream_data)
	ferr: Error
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
	case .Close, .Destroy:
		ferr = _close(f)
		err = error_to_io_error(ferr)
		return
	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Flush, .Close, .Destroy, .Query})
	}
	return 0, .Empty
}

