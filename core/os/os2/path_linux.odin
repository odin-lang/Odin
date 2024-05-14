//+private
package os2

import "core:strconv"
import "base:runtime"
import "core:sys/unix"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_S_IFMT   :: 0o170000 // Type of file mask
_S_IFIFO  :: 0o010000 // Named pipe (fifo)
_S_IFCHR  :: 0o020000 // Character special
_S_IFDIR  :: 0o040000 // Directory
_S_IFBLK  :: 0o060000 // Block special
_S_IFREG  :: 0o100000 // Regular
_S_IFLNK  :: 0o120000 // Symbolic link
_S_IFSOCK :: 0o140000 // Socket

_OPENDIR_FLAGS :: _O_RDONLY|_O_NONBLOCK|_O_DIRECTORY|_O_LARGEFILE|_O_CLOEXEC

_is_path_separator :: proc(c: byte) -> bool {
	return c == '/'
}

_mkdir :: proc(path: string, perm: File_Mode) -> Error {
	// NOTE: These modes would require sys_mknod, however, that would require
	//       additional arguments to this function.
	if perm & (File_Mode_Named_Pipe | File_Mode_Device | File_Mode_Char_Device | File_Mode_Sym_Link) != 0 {
		return .Invalid_Argument
	}

	TEMP_ALLOCATOR_GUARD()
	path_cstr := temp_cstring(path) or_return
	return _ok_or_error(unix.sys_mkdir(path_cstr, uint(perm & 0o777)))
}

_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	_mkdirat :: proc(dfd: int, path: []u8, perm: int, has_created: ^bool) -> Error {
		if len(path) == 0 {
			return _ok_or_error(unix.sys_close(dfd))
		}
		i: int
		for /**/; i < len(path) - 1 && path[i] != '/'; i += 1 {}
		path[i] = 0
		new_dfd := unix.sys_openat(dfd, cstring(&path[0]), _OPENDIR_FLAGS)
		switch new_dfd {
		case -ENOENT:
			if res := unix.sys_mkdirat(dfd, cstring(&path[0]), uint(perm)); res < 0 {
				return _get_platform_error(res)
			}
			has_created^ = true
			if new_dfd = unix.sys_openat(dfd, cstring(&path[0]), _OPENDIR_FLAGS); new_dfd < 0 {
				return _get_platform_error(new_dfd)
			}
			fallthrough
		case 0:
			if res := unix.sys_close(dfd); res < 0 {
				return _get_platform_error(res)
			}
			// skip consecutive '/'
			for i += 1; i < len(path) && path[i] == '/'; i += 1 {}
			return _mkdirat(new_dfd, path[i:], perm, has_created)
		case:
			return _get_platform_error(new_dfd)
		}
		unreachable()
	}

	if perm & (File_Mode_Named_Pipe | File_Mode_Device | File_Mode_Char_Device | File_Mode_Sym_Link) != 0 {
		return .Invalid_Argument
	}

	TEMP_ALLOCATOR_GUARD()

	// need something we can edit, and use to generate cstrings
	allocated: bool
	path_bytes: []u8
	if len(path) > _CSTRING_NAME_HEAP_THRESHOLD {
		allocated = true
		path_bytes = make([]u8, len(path) + 1)
	} else {
		path_bytes = make([]u8, len(path) + 1, temp_allocator())
	}

	// NULL terminate the byte slice to make it a valid cstring
	copy(path_bytes, path)
	path_bytes[len(path)] = 0

	dfd: int
	if path_bytes[0] == '/' {
		dfd = unix.sys_open("/", _OPENDIR_FLAGS)
		path_bytes = path_bytes[1:]
	} else {
		dfd = unix.sys_open(".", _OPENDIR_FLAGS)
	}
	if dfd < 0 {
		return _get_platform_error(dfd)
	}
	
	has_created: bool
	_mkdirat(dfd, path_bytes, int(perm & 0o777), &has_created) or_return
	if has_created {
		return nil
	}
	return .Exist
	//return has_created ? nil : .Exist
}

dirent64 :: struct {
	d_ino: u64,
	d_off: u64,
	d_reclen: u16,
	d_type: u8,
	d_name: [1]u8,
}

_remove_all :: proc(path: string) -> Error {
	DT_DIR :: 4

	_remove_all_dir :: proc(dfd: int) -> Error {
		n := 64
		buf := make([]u8, n)
		defer delete(buf)

		loop: for {
			getdents_res := unix.sys_getdents64(dfd, &buf[0], n)
			switch getdents_res {
			case -EINVAL:
				delete(buf)
				n *= 2
				buf = make([]u8, n)
				continue loop
			case -4096..<0:
				return _get_platform_error(getdents_res)
			case 0:
				break loop
			}

			d: ^dirent64

			for i := 0; i < getdents_res; i += int(d.d_reclen) {
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

				unlink_res: int

				switch d.d_type {
				case DT_DIR:
					new_dfd := unix.sys_openat(dfd, d_name_cstr, _OPENDIR_FLAGS)
					if new_dfd < 0 {
						return _get_platform_error(new_dfd)
					}
					defer unix.sys_close(new_dfd)
					_remove_all_dir(new_dfd) or_return
					unlink_res = unix.sys_unlinkat(dfd, d_name_cstr, int(unix.AT_REMOVEDIR))
				case:
					unlink_res = unix.sys_unlinkat(dfd, d_name_cstr) 
				}

				if unlink_res < 0 {
					return _get_platform_error(unlink_res)
				}
			}
		}
		return nil
	}

	TEMP_ALLOCATOR_GUARD()
	path_cstr := temp_cstring(path) or_return

	fd := unix.sys_open(path_cstr, _OPENDIR_FLAGS)
	switch fd {
	case -ENOTDIR:
		return _ok_or_error(unix.sys_unlink(path_cstr))
	case -4096..<0:
		return _get_platform_error(fd)
	}

	defer unix.sys_close(fd)
	_remove_all_dir(fd) or_return
	return _ok_or_error(unix.sys_rmdir(path_cstr))
}

_getwd :: proc(allocator: runtime.Allocator) -> (string, Error) {
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	// NOTE(jason): Avoiding libc, so just use 4096 directly
	PATH_MAX :: 4096
	buf := make([dynamic]u8, PATH_MAX, allocator)
	for {
		#no_bounds_check res := unix.sys_getcwd(&buf[0], uint(len(buf)))

		if res >= 0 {
			return string_from_null_terminated_bytes(buf[:]), nil
		}
		if res != -ERANGE {
			return "", _get_platform_error(res)
		}
		resize(&buf, len(buf)+PATH_MAX)
	}
	unreachable()
}

_setwd :: proc(dir: string) -> Error {
	dir_cstr := temp_cstring(dir) or_return
	return _ok_or_error(unix.sys_chdir(dir_cstr))
}

_get_full_path :: proc(fd: int, allocator: runtime.Allocator) -> string {
	PROC_FD_PATH :: "/proc/self/fd/"

	buf: [32]u8
	copy(buf[:], PROC_FD_PATH)

	strconv.itoa(buf[len(PROC_FD_PATH):], fd)

	fullpath: string
	err: Error
	if fullpath, err = _read_link_cstr(cstring(&buf[0]), allocator); err != nil || fullpath[0] != '/' {
		return ""
	}
	return fullpath
}

