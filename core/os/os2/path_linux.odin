//+private
package os2

import "core:strings"
import "core:sys/unix"
import "core:path/filepath"

_Path_Separator      :: '/'
_Path_List_Separator :: ':'

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
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	perm_i: int
	if perm & (File_Mode_Named_Pipe | File_Mode_Device | File_Mode_Char_Device | File_Mode_Sym_Link) != 0 {
		return .Invalid_Argument
	}

	return _ok_or_error(unix.sys_mkdir(path_cstr, int(perm & 0o777)))
}

// TODO
_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	return nil
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
					handle_i := unix.sys_openat(int(dfd), d_name_cstr, _OPENDIR_FLAGS)
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

	handle_i := unix.sys_open(cstr, _OPENDIR_FLAGS)
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

_getwd :: proc(allocator := context.allocator) -> (string, Error) {
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

_setwd :: proc(dir: string) -> Error {
	dir_cstr := strings.clone_to_cstring(dir, context.temp_allocator)
	return _ok_or_error(unix.sys_chdir(dir_cstr))
}
