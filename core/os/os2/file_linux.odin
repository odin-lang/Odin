//+private
package os2

import "core:io"
import "core:time"
import "core:strings"
import "core:runtime"
import "core:sys/unix"

INVALID_HANDLE :: -1

_O_RDONLY    :: 0o0
_O_WRONLY    :: 0o1
_O_RDWR      :: 0o2
_O_CREAT     :: 0o100
_O_EXCL      :: 0o200
_O_TRUNC     :: 0o1000
_O_APPEND    :: 0o2000
_O_NONBLOCK  :: 0o4000
_O_LARGEFILE :: 0o100000
_O_DIRECTORY :: 0o200000
_O_NOFOLLOW  :: 0o400000
_O_SYNC      :: 0o4010000
_O_CLOEXEC   :: 0o2000000
_O_PATH      :: 0o10000000

_AT_FDCWD :: -100

_CSTRING_NAME_HEAP_THRESHOLD :: 512

_File :: struct {
	name: string,
	fd: int,
	allocator: runtime.Allocator,
}

_file_allocator :: proc() -> runtime.Allocator {
	return heap_allocator()
}

_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (^File, Error) {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}

	flags_i: int
	switch flags & O_RDONLY|O_WRONLY|O_RDWR {
	case O_RDONLY: flags_i = _O_RDONLY
	case O_WRONLY: flags_i = _O_WRONLY
	case O_RDWR:   flags_i = _O_RDWR
	}

	flags_i |= (_O_APPEND * int(.Append in flags))
	flags_i |= (_O_CREAT * int(.Create in flags))
	flags_i |= (_O_EXCL * int(.Excl in flags))
	flags_i |= (_O_SYNC * int(.Sync in flags))
	flags_i |= (_O_TRUNC * int(.Trunc in flags))
	flags_i |= (_O_CLOEXEC * int(.Close_On_Exec in flags))

	fd := unix.sys_open(name_cstr, flags_i, int(perm))
	if fd < 0 {
		return nil, _get_platform_error(fd)
	}

	return _new_file(uintptr(fd), name), nil
}

_new_file :: proc(fd: uintptr, _: string) -> ^File {
	file := new(File, _file_allocator())
	file.impl.fd = int(fd)
	file.impl.allocator = _file_allocator()
	file.impl.name = _get_full_path(file.impl.fd, file.impl.allocator)
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
	res := unix.sys_close(f.impl.fd)
	return _ok_or_error(res)
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

_seek :: proc(f: ^File, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	res := unix.sys_lseek(f.impl.fd, offset, int(whence))
	if res < 0 {
		return -1, _get_platform_error(int(res))
	}
	return res, nil
}

_read :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n = unix.sys_read(f.impl.fd, &p[0], len(p))
	if n < 0 {
		return -1, _get_platform_error(n)
	}
	return n, nil
}

_read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := unix.sys_pread(f.impl.fd, &b[0], len(b), offset)
		if m < 0 {
			return -1, _get_platform_error(m)
		}
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

_read_from :: proc(f: ^File, r: io.Reader) -> (n: i64, err: Error) {
	//TODO
	return
}

_write :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n = unix.sys_write(f.impl.fd, &p[0], uint(len(p)))
	if n < 0 {
		return -1, _get_platform_error(n)
	}
	return int(n), nil
}

_write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := unix.sys_pwrite(f.impl.fd, &b[0], len(b), offset)
		if m < 0 {
			return -1, _get_platform_error(m)
		}
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

_write_to :: proc(f: ^File, w: io.Writer) -> (n: i64, err: Error) {
	//TODO
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
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}

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
	old_name_cstr, old_allocated := _name_to_cstring(old_name)
	new_name_cstr, new_allocated := _name_to_cstring(new_name)
	defer if old_allocated {
		delete(old_name_cstr)
	}
	defer if new_allocated {
		delete(new_name_cstr)
	}

	return _ok_or_error(unix.sys_rename(old_name_cstr, new_name_cstr))
}

_link :: proc(old_name, new_name: string) -> Error {
	old_name_cstr, old_allocated := _name_to_cstring(old_name)
	new_name_cstr, new_allocated := _name_to_cstring(new_name)
	defer if old_allocated {
		delete(old_name_cstr)
	}
	defer if new_allocated {
		delete(new_name_cstr)
	}

	return _ok_or_error(unix.sys_link(old_name_cstr, new_name_cstr))
}

_symlink :: proc(old_name, new_name: string) -> Error {
	old_name_cstr, old_allocated := _name_to_cstring(old_name)
	new_name_cstr, new_allocated := _name_to_cstring(new_name)
	defer if old_allocated {
		delete(old_name_cstr)
	}
	defer if new_allocated {
		delete(new_name_cstr)
	}

	return _ok_or_error(unix.sys_symlink(old_name_cstr, new_name_cstr))
}

_read_link_cstr :: proc(name_cstr: cstring, allocator := context.allocator) -> (string, Error) {
	bufsz : uint = 256
	buf := make([]byte, bufsz, allocator)
	for {
		rc := unix.sys_readlink(name_cstr, &(buf[0]), bufsz)
		if rc < 0 {
			delete(buf)
			return "", _get_platform_error(rc)
		} else if rc == int(bufsz) {
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz, allocator)
		} else {
			return strings.string_from_ptr(&buf[0], rc), nil
		}
	}
}

_read_link :: proc(name: string, allocator := context.allocator) -> (string, Error) {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return _read_link_cstr(name_cstr, allocator)
}

_unlink :: proc(name: string) -> Error {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return _ok_or_error(unix.sys_unlink(name_cstr))
}

_chdir :: proc(name: string) -> Error {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return _ok_or_error(unix.sys_chdir(name_cstr))
}

_fchdir :: proc(f: ^File) -> Error {
	return _ok_or_error(unix.sys_fchdir(f.impl.fd))
}

_chmod :: proc(name: string, mode: File_Mode) -> Error {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return _ok_or_error(unix.sys_chmod(name_cstr, int(mode)))
}

_fchmod :: proc(f: ^File, mode: File_Mode) -> Error {
	return _ok_or_error(unix.sys_fchmod(f.impl.fd, int(mode)))
}

// NOTE: will throw error without super user priviledges
_chown :: proc(name: string, uid, gid: int) -> Error {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return _ok_or_error(unix.sys_chown(name_cstr, uid, gid))
}

// NOTE: will throw error without super user priviledges
_lchown :: proc(name: string, uid, gid: int) -> Error {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return _ok_or_error(unix.sys_lchown(name_cstr, uid, gid))
}

// NOTE: will throw error without super user priviledges
_fchown :: proc(f: ^File, uid, gid: int) -> Error {
	return _ok_or_error(unix.sys_fchown(f.impl.fd, uid, gid))
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
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
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
	return unix.sys_access(name_cstr, F_OK) == 0
}

_is_file :: proc(name: string) -> bool {
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
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
	name_cstr, allocated := _name_to_cstring(name)
	defer if allocated {
		delete(name_cstr)
	}
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

// Ideally we want to use the temp_allocator.  PATH_MAX on Linux is commonly
// defined as 512, however, it is well known that paths can exceed that limit.
// So, in theory you could have a path larger than the entire temp_allocator's
// buffer. Therefor, any large paths will use context.allocator.
_name_to_cstring :: proc(name: string) -> (cname: cstring, allocated: bool) {
	if len(name) > _CSTRING_NAME_HEAP_THRESHOLD {
		cname = strings.clone_to_cstring(name)
		allocated = true
		return
	}
	cname = strings.clone_to_cstring(name, context.temp_allocator)
	return
}
