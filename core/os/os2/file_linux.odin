//+private
package os2

import "core:io"
import "core:time"
import "core:strings"
import "core:sys/unix"


_std_handle :: proc(kind: Std_Handle_Kind) -> Handle {
	return Handle(kind)
}

__O_RDONLY    :: 0o0
__O_WRONLY    :: 0o1
__O_RDWR      :: 0o2
__O_CREAT     :: 0o100
__O_EXCL      :: 0o200
__O_TRUNC     :: 0o1000
__O_APPEND    :: 0o2000
__O_NONBLOCK  :: 0o4000
__O_LARGEFILE :: 0o100000
__O_DIRECTORY :: 0o200000
__O_SYNC      :: 0o4010000
__O_CLOEXEC   :: 0o2000000

_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (Handle, Error) {
	cstr := strings.clone_to_cstring(name, context.temp_allocator)

	flags_i: int
	switch flags & O_RDONLY|O_WRONLY|O_RDWR {
	case O_RDONLY: flags_i = __O_RDONLY
	case O_WRONLY: flags_i = __O_WRONLY
	case O_RDWR:   flags_i = __O_RDWR
	}

	flags_i |= (__O_APPEND * int(.Append in flags))
	flags_i |= (__O_CREAT * int(.Create in flags))
	flags_i |= (__O_EXCL * int(.Excl in flags))
	flags_i |= (__O_SYNC * int(.Sync in flags))
	flags_i |= (__O_TRUNC * int(.Trunc in flags))
	flags_i |= (__O_CLOEXEC * int(.Close_On_Exec in flags))

	handle_i := unix.sys_open(cstr, flags_i, int(perm))
	if handle_i < 0 {
		return INVALID_HANDLE, _get_platform_error(handle_i)
	}

	return Handle(handle_i), nil
}

_close :: proc(fd: Handle) -> Error {
	res := unix.sys_close(int(fd))
	return _ok_or_error(res)
}

_name :: proc(fd: Handle, allocator := context.allocator) -> string {
	//TODO
	return ""
}

_seek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	res := unix.sys_lseek(int(fd), offset, int(whence))
	if res < 0 {
		return -1, _get_platform_error(int(res))
	}
	return res, nil
}

_read :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n = unix.sys_read(int(fd), &p[0], len(p))
	if n < 0 {
		return -1, _get_platform_error(int(unix.get_errno(n)))
	}
	return n, nil
}

_read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := unix.sys_pread(int(fd), &b[0], len(b), offset)
		if m < 0 {
			return -1, _get_platform_error(m)
		}
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

_read_from :: proc(fd: Handle, r: io.Reader) -> (n: i64, err: Error) {
	//TODO
	return
}

_write :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n = unix.sys_write(int(fd), &p[0], uint(len(p)))
	if n < 0 {
		return -1, _get_platform_error(n)
	}
	return int(n), nil
}

_write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	b, offset := p, offset
	for len(b) > 0 {
		m := unix.sys_pwrite(int(fd), &b[0], len(b), offset)
		if m < 0 {
			return -1, _get_platform_error(m)
		}
		n += m
		b = b[m:]
		offset += i64(m)
	}
	return
}

_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
	//TODO
	return
}

_file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
	s: OS_Stat = ---
	res := unix.sys_fstat(int(fd), &s)
	if res < 0 {
		return -1, _get_platform_error(res)
	}
	return s.size, nil
}

_sync :: proc(fd: Handle) -> Error {
	return _ok_or_error(unix.sys_fsync(int(fd)))
}

_flush :: proc(fd: Handle) -> Error {
	return _ok_or_error(unix.sys_fsync(int(fd)))
}

_truncate :: proc(fd: Handle, size: i64) -> Error {
	return _ok_or_error(unix.sys_ftruncate(int(fd), size))
}

_remove :: proc(name: string) -> Error {
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)

	handle_i := unix.sys_open(name_cstr, int(File_Flags.Read))
	if handle_i < 0 {
		return _get_platform_error(handle_i)
	}
	defer unix.sys_close(handle_i)

	/* TODO: THIS WILL NOT WORK */
	if _is_dir(Handle(handle_i)) {
		return _ok_or_error(unix.sys_rmdir(name_cstr))
	}
	return _ok_or_error(unix.sys_unlink(name_cstr))
}

_rename :: proc(old_name, new_name: string) -> Error {
	old_name_cstr := strings.clone_to_cstring(old_name, context.temp_allocator)
	new_name_cstr := strings.clone_to_cstring(new_name, context.temp_allocator)
	return _ok_or_error(unix.sys_rename(old_name_cstr, new_name_cstr))
}

_link :: proc(old_name, new_name: string) -> Error {
	old_name_cstr := strings.clone_to_cstring(old_name, context.temp_allocator)
	new_name_cstr := strings.clone_to_cstring(new_name, context.temp_allocator)
	return _ok_or_error(unix.sys_link(old_name_cstr, new_name_cstr))
}

_symlink :: proc(old_name, new_name: string) -> Error {
	old_name_cstr := strings.clone_to_cstring(old_name, context.temp_allocator)
	new_name_cstr := strings.clone_to_cstring(new_name, context.temp_allocator)
	return _ok_or_error(unix.sys_symlink(old_name_cstr, new_name_cstr))
}

_read_link :: proc(name: string, allocator := context.allocator) -> (string, Error) {
	name_cstr := strings.clone_to_cstring(name)
	defer delete(name_cstr)

	bufsz : uint = 256
	buf := make([]byte, bufsz, allocator)
	for {
		rc := unix.sys_readlink(name_cstr, &(buf[0]), bufsz)
		if rc < 0 {
			delete(buf)
			return "", _get_platform_error(int(unix.get_errno(rc)))
		} else if rc == int(bufsz) {
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz, allocator)
		} else {
			return strings.string_from_ptr(&buf[0], rc), nil
		}
	}
}

_unlink :: proc(name: string) -> Error {
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)
	return _ok_or_error(unix.sys_unlink(name_cstr))
}

_chdir :: proc(fd: Handle) -> Error {
	return _ok_or_error(unix.sys_fchdir(int(fd)))
}

_chmod :: proc(fd: Handle, mode: File_Mode) -> Error {
	return _ok_or_error(unix.sys_fchmod(int(fd), int(mode)))
}

_chown :: proc(fd: Handle, uid, gid: int) -> Error {
	return _ok_or_error(unix.sys_fchown(int(fd), uid, gid))
}

_lchown :: proc(name: string, uid, gid: int) -> Error {
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)
	return _ok_or_error(unix.sys_lchown(name_cstr, uid, gid))
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	//TODO
	return nil
}

_exists :: proc(name: string) -> bool {
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)
	return unix.sys_access(name_cstr, F_OK) == 0
}

_is_file :: proc(fd: Handle) -> bool {
	s: OS_Stat
	res := unix.sys_fstat(int(fd), &s)
	if res < 0 { // error
		return false
	}
	return S_ISREG(s.mode)
}

_is_dir :: proc(fd: Handle) -> bool {
	s: OS_Stat
	res := unix.sys_fstat(int(fd), &s)
	if res < 0 { // error
		return false
	}
	return S_ISDIR(s.mode)
}
