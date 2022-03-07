//+private
package os2

import "core:strings"
import "core:sys/unix"
import "core:path/filepath"

_Path_Separator      :: '/'
_Path_List_Separator :: ':'

DIRECTORY_FLAGS :: __O_RDONLY|__O_NONBLOCK|__O_DIRECTORY|__O_LARGEFILE|__O_CLOEXEC

_is_path_separator :: proc(c: byte) -> bool {
	return c == '/'
}

_mkdir :: proc(path: string, perm: File_Mode) -> Error {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	//TODO file_mode
	return _ok_or_error(unix.sys_mkdir(path_cstr))
}

_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	_mkdir_all_stat :: proc(path: string, s: ^OS_Stat, perm: File_Mode) -> Error {
		if len(path) == 0 {
			return nil
		}
	
		path := path[len(path)-1] == '/' ? path[:len(path)-1] : path
		dir, _ := filepath.split(path)

		if len(dir) == 0 {
			return _mkdir(path, perm)
		}

		dir_cstr := strings.clone_to_cstring(dir, context.temp_allocator)
		errno := int(unix.get_errno(unix.sys_stat(dir_cstr, s)))
		switch errno {
		case 0:
			if !S_ISDIR(s.mode) {
				return .Exist
			}
			return _mkdir(path, perm)
		case ENOENT:
			_mkdir_all_stat(dir, s, perm) or_return
			return _mkdir(path, perm)
		case:
			return _get_platform_error(errno)
		}
		unreachable()
	}
	// OS_Stat is fat. Make one and re-use it.
	s: OS_Stat = ---
	return _mkdir_all_stat(path, &s, perm)
}

dirent64 :: struct {
	d_ino: u64,
	d_off: u64,
	d_reclen: u16,
	d_type: u8,
	d_name: [1]u8,
}

DT_UNKNOWN :: 0
DT_FIFO :: 1
DT_CHR :: 2
DT_DIR :: 4
DT_BLK :: 6
DT_REG :: 8
DT_LNK :: 10
DT_SOCK :: 12
DT_WHT :: 14

_remove_all :: proc(path: string) -> Error {
	_remove_all_dir :: proc(dfd: Handle) -> Error {
		n := 64
		buf := make([]u8, n)
		defer delete(buf)

		loop: for {
			res := unix.sys_getdents64(int(dfd), &buf[0], n)
			switch res {
			case -22:         //-EINVAL
				n *= 2
				buf = make([]u8, n)
				continue loop
			case -4096..<0:
				return _get_platform_error(res)
			case 0:
				break loop
			}

			d: ^dirent64

			for i := 0; i < res; i += int(d.d_reclen) {
				description: string
				d = (^dirent64)(rawptr(&buf[i]))
				d_name_cstr := cstring(&d.d_name[0])

				buf_len := uintptr(d.d_reclen) - offset_of(d.d_name)

				/* check for current directory (.) */
				#no_bounds_check if buf_len > 1 && d.d_name[0] == '.' && d.d_name[1] == 0 {
					continue
				}

				/* check for parent directory (..) */
				#no_bounds_check if buf_len > 2 && d.d_name[0] == '.' && d.d_name[1] == '.' && d.d_name[2] == 0 {
					continue
				}

				res: int

				switch d.d_type {
				case DT_DIR:
					handle_i := unix.sys_openat(int(dfd), d_name_cstr, DIRECTORY_FLAGS)
					if handle_i < 0 {
						return _get_platform_error(handle_i)
					}
					defer unix.sys_close(handle_i)
					_remove_all_dir(Handle(handle_i)) or_return
					res = unix.sys_unlinkat(int(dfd), d_name_cstr, int(unix.AT_REMOVEDIR))
				case:
					res = unix.sys_unlinkat(int(dfd), d_name_cstr) 
				}

				if res < 0 {
					return _get_platform_error(res)
				}
			}
		}
		return nil
	}

	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	handle_i := unix.sys_open(cstr, DIRECTORY_FLAGS)
	switch handle_i {
	case -ENOTDIR:
		return _ok_or_error(unix.sys_unlink(cstr))
	case -4096..<0:
		return _get_platform_error(handle_i)
	}

	fd := Handle(handle_i)
	defer close(fd)
	_remove_all_dir(fd) or_return
	return _ok_or_error(unix.sys_rmdir(cstr))
}

_getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	// NOTE(jason): Avoiding libc, so just use 4096 directly
	PATH_MAX :: 4096
	buf := make([dynamic]u8, PATH_MAX, allocator)
	for {
		#no_bounds_check res := unix.sys_getcwd(&buf[0], uint(len(buf)))

		if res >= 0 {
			return strings.string_from_nul_terminated_ptr(&buf[0], len(buf)), nil
		}
		if res != -ERANGE {
			return "", _get_platform_error(res)
		}
		resize(&buf, len(buf)+PATH_MAX)
	}
	unreachable()
}

_setwd :: proc(dir: string) -> (err: Error) {
	dir_cstr := strings.clone_to_cstring(dir, context.temp_allocator)
	return _ok_or_error(unix.sys_chdir(dir_cstr))
}
