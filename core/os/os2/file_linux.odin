//+private
package os2

import "core:io"
import "core:time"
import "core:sys/unix"


_get_platform_error :: proc(res: int) -> Error {
	errno := unix.get_errno(res)
	return Platform_Error{i32(errno)}
}

_ok_or_error :: proc(res: int) -> Error {
	return res >= 0 ? nil : _get_platform_error(res)
}

_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (Handle, Error) {
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := Handle(unix.sys_open(cstr, int(flags), int(perm)))
	if handle < 0 {
		return Handle(-1), _get_platform_error(int(handle))
	}
	return handle, nil
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
	n = unix.sys_read(fd, &data[0], c.size_t(len(data)))
	if n < 0 {
		return -1, unix.get_errno(n)
	}
	return bytes_read, nil
}

_read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}
	
	curr_offset, err := _seek(fd, 0, .Current)
	if err != nil {
		return 0, err
	}
	defer _seek(fd, curr_offset, .Start)
	_seek(fd, offset, .Start)

	b := p
	for len(b) > 0 {
		m := _read(fd, b) or_return
		n += m
		b = b[m:]
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
	n = unix.sys_write(fd, &p[0], uint(len(p)))
	if n < 0 {
		return -1, _get_platform_error(n)
	}
	return int(n), nil
}

_write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}
	
	curr_offset, err := _seek(fd, 0, .Current)
	if err != nil {
		return 0, err
	}
	defer _seek(fd, curr_offset, .Start)
	_seek(fd, offset, .Start)

	b := p
	for len(b) > 0 {
		m := _write(fd, b) or_return
		n += m
		b = b[m:]
	}
	return
}

_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
	//TODO
	return
}

_file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
	s, err := _fstat(fd) or_return
	if err != nil {
		return 0, err
	}
	return max(s.size, 0), nil
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
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	if _is_dir(name) {
		return _ok_or_error(unix.sys_rmdir(path_cstr))
	}
	return _ok_or_error(unix.sys_unlink(path_cstr))
}

_rename :: proc(old_path, new_path: string) -> Error {
	old_path_cstr := strings.clone_to_cstring(old_path, context.temp_allocator)
	new_path_cstr := strings.clone_to_cstring(new_path, context.temp_allocator)
	return _ok_or_error(unix.sys_rename(old_path_cstr, new_path_cstr))
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
	path_cstr := strings.clone_to_cstring(path)
	defer delete(path_cstr)

	bufsz : uint = 256
	buf := make([]byte, bufsz, allocator)
	for {
		rc := unix.sys_readlink(path_cstr, &(buf[0]), bufsz)
		if rc < 0 {
			delete(buf)
			return "", unix.get_errno(rc)
		} else if rc == int(bufsz) {
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz, allocator)
		} else {
			return strings.string_from_ptr(&buf[0], rc), nil
		}
	}
}

_unlink :: proc(path: string) -> Error {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _ok_or_error(unix.sys_unlink(path_cstr))
}

_chdir :: proc(fd: Handle) -> Error {
	return _ok_or_error(unix.sys_fchdir(int(fd)))
}

_chmod :: proc(fd: Handle, mode: File_Mode) -> Error {
	//TODO
	return nil
}

_chown :: proc(fd: Handle, uid, gid: int) -> Error {
	//TODO
	return nil
}

_lchown :: proc(name: string, uid, gid: int) -> Error {
	//TODO
	return nil
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	//TODO
	return nil
}

_exists :: proc(path: string) -> bool {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return unix.sys_access(path_cstr, F_OK) == 0
}

_is_file :: proc(fd: Handle) -> bool {
	s: OS_Stat
	res := unix.sys_fstat(int(fd), rawptr(&s))
	if res < 0 { // error
		return false
	}
	return S_ISREG(s.mode)
}

_is_dir :: proc(fd: Handle) -> bool {
	s: OS_Stat
	res := unix.sys_fstat(int(fd), rawptr(&s))
	if res < 0 { // error
		return false
	}
	return S_ISDIR(s.mode)
}
