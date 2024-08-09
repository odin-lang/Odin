//+private
package os2

import "core:strings"
import "core:strconv"
import "base:runtime"
import "core:sys/linux"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_OPENDIR_FLAGS : linux.Open_Flags : {.NONBLOCK, .DIRECTORY, .LARGEFILE, .CLOEXEC}

_is_path_separator :: proc(c: byte) -> bool {
	return c == '/'
}

_mkdir :: proc(path: string, perm: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	path_cstr := temp_cstring(path) or_return
	return _get_platform_error(linux.mkdir(path_cstr, transmute(linux.Mode)u32(perm)))
}

_mkdir_all :: proc(path: string, perm: int) -> Error {
	mkdirat :: proc(dfd: linux.Fd, path: []u8, perm: int, has_created: ^bool) -> Error {
		i: int
		for ; i < len(path) - 1 && path[i] != '/'; i += 1 {}
		if i == 0 {
			return _get_platform_error(linux.close(dfd))
		}
		path[i] = 0
		new_dfd, errno := linux.openat(dfd, cstring(&path[0]), _OPENDIR_FLAGS)
		#partial switch errno {
		case .ENOENT:
			if errno = linux.mkdirat(dfd, cstring(&path[0]), transmute(linux.Mode)u32(perm)); errno != .NONE {
				return _get_platform_error(errno)
			}
			has_created^ = true
			if new_dfd, errno = linux.openat(dfd, cstring(&path[0]), _OPENDIR_FLAGS); errno != .NONE {
				return _get_platform_error(errno)
			}
			fallthrough
		case .NONE:
			if errno = linux.close(dfd); errno != .NONE {
				return _get_platform_error(errno)
			}
			// skip consecutive '/'
			for i += 1; i < len(path) && path[i] == '/'; i += 1 {}
			return mkdirat(new_dfd, path[i:], perm, has_created)
		}
		return _get_platform_error(errno)
	}
	TEMP_ALLOCATOR_GUARD()
	// need something we can edit, and use to generate cstrings
	path_bytes := make([]u8, len(path) + 1, temp_allocator())

	// zero terminate the byte slice to make it a valid cstring
	copy(path_bytes, path)
	path_bytes[len(path)] = 0

	dfd: linux.Fd
	errno: linux.Errno
	if path_bytes[0] == '/' {
		dfd, errno = linux.open("/", _OPENDIR_FLAGS)
		path_bytes = path_bytes[1:]
	} else {
		dfd, errno = linux.open(".", _OPENDIR_FLAGS)
	}
	if errno != .NONE {
		return _get_platform_error(errno)
	}
	
	has_created: bool
	mkdirat(dfd, path_bytes, perm, &has_created) or_return
	return nil if has_created else .Exist
}

_remove_all :: proc(path: string) -> Error {
	DT_DIR :: 4

	remove_all_dir :: proc(dfd: linux.Fd) -> Error {
		n := 64
		buf := make([]u8, n)
		defer delete(buf)

		loop: for {
			buflen, errno := linux.getdents(dfd, buf[:])
			#partial switch errno {
			case .EINVAL:
				delete(buf)
				n *= 2
				buf = make([]u8, n)
				continue loop
			case .NONE:
				if buflen == 0 { break loop }
			case:
				return _get_platform_error(errno)
			}

			offset: int
			for d in linux.dirent_iterate_buf(buf[:buflen], &offset) {
				d_name_str := linux.dirent_name(d)
				d_name_cstr := strings.unsafe_string_to_cstring(d_name_str)

				/* check for current or parent directory (. or ..) */
				if d_name_str == "." || d_name_str == ".." {
					continue
				}

				#partial switch d.type {
				case .DIR:
					new_dfd: linux.Fd
					new_dfd, errno = linux.openat(dfd, d_name_cstr, _OPENDIR_FLAGS)
					if errno != .NONE {
						return _get_platform_error(errno)
					}
					defer linux.close(new_dfd)
					remove_all_dir(new_dfd) or_return
					errno = linux.unlinkat(dfd, d_name_cstr, {.REMOVEDIR})
				case:
					errno = linux.unlinkat(dfd, d_name_cstr, nil)
				}

				if errno != .NONE {
					return _get_platform_error(errno)
				}
			}
		}
		return nil
	}

	TEMP_ALLOCATOR_GUARD()
	path_cstr := temp_cstring(path) or_return

	fd, errno := linux.open(path_cstr, _OPENDIR_FLAGS)
	#partial switch errno {
	case .NONE:
		break
	case .ENOTDIR:
		return _get_platform_error(linux.unlink(path_cstr))
	case:
		return _get_platform_error(errno)
	}

	defer linux.close(fd)
	remove_all_dir(fd) or_return
	return _get_platform_error(linux.rmdir(path_cstr))
}

_get_working_directory :: proc(allocator: runtime.Allocator) -> (string, Error) {
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	// NOTE(jason): Avoiding libc, so just use 4096 directly
	PATH_MAX :: 4096
	buf := make([dynamic]u8, PATH_MAX, allocator)
	for {
		#no_bounds_check n, errno := linux.getcwd(buf[:])
		if errno == .NONE {
			return string(buf[:n-1]), nil
		}
		if errno != .ERANGE {
			return "", _get_platform_error(errno)
		}
		resize(&buf, len(buf)+PATH_MAX)
	}
	unreachable()
}

_set_working_directory :: proc(dir: string) -> Error {
	dir_cstr := temp_cstring(dir) or_return
	return _get_platform_error(linux.chdir(dir_cstr))
}

_get_full_path :: proc(fd: linux.Fd, allocator: runtime.Allocator) -> (fullpath: string, err: Error) {
	PROC_FD_PATH :: "/proc/self/fd/"

	buf: [32]u8
	copy(buf[:], PROC_FD_PATH)

	strconv.itoa(buf[len(PROC_FD_PATH):], int(fd))

	if fullpath, err = _read_link_cstr(cstring(&buf[0]), allocator); err != nil || fullpath[0] != '/' {
		delete(fullpath, allocator)
		fullpath = ""
	}
	return
}
