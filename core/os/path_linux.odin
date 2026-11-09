#+private
package os

import "base:runtime"

import "core:strconv"
import "core:sys/linux"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_OPENDIR_FLAGS : linux.Open_Flags : {.NONBLOCK, .DIRECTORY, .LARGEFILE, .CLOEXEC}

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

_mkdir :: proc(path: string, perm: Permissions) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	path_cstr := clone_to_cstring(path, temp_allocator) or_return
	return _get_platform_error(linux.mkdir(path_cstr, transmute(linux.Mode)transmute(u32)perm))
}

_mkdir_all :: proc(path: string, perm: Permissions) -> Error {
	mkdirat :: proc(dfd: linux.Fd, path: []u8, perm: Permissions, has_created: ^bool) -> Error {
		i: int
		for ; i < len(path) - 1 && path[i] != '/'; i += 1 {}
		if i == 0 {
			return _get_platform_error(linux.close(dfd))
		}
		path[i] = 0
		new_dfd, errno := linux.openat(dfd, cstring(&path[0]), _OPENDIR_FLAGS)
		#partial switch errno {
		case .ENOENT:
			if errno = linux.mkdirat(dfd, cstring(&path[0]), transmute(linux.Mode)transmute(u32)perm); errno != .NONE {
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
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	// need something we can edit, and use to generate cstrings
	path_bytes := make([]u8, len(path) + 1, temp_allocator)

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

_Remove_All_Dir :: linux.Fd

@(private="file")
_REMOVE_ALL_OPEN_FLAGS :: linux.Open_Flags{.NONBLOCK, .DIRECTORY, .LARGEFILE, .CLOEXEC, .NOFOLLOW}

_remove_all_root :: proc(path: string, allocator: runtime.Allocator) -> (parent: _Remove_All_Dir, name: []u8, err: Error) {
	root := path
	for len(root) > 1 && root[len(root)-1] == '/' {
		root = root[:len(root)-1]
	}
	croot := clone_to_cstring(root, allocator) or_return
	return linux.AT_FDCWD, ([^]u8)(croot)[:len(root)], nil
}

_remove_all_open :: proc(parent: _Remove_All_Dir, name: []u8) -> (dir: _Remove_All_Dir, is_dir: bool, err: Error) {
	cname := cstring(raw_data(name))
	fd, errno := linux.openat(parent, cname, _REMOVE_ALL_OPEN_FLAGS)
	if errno == .NONE {
		return fd, true, nil
	}
	if errno == .ENOENT {
		return -1, false, .Not_Exist
	}
	st: linux.Stat
	if stat_errno := linux.fstatat(parent, cname, &st, {.SYMLINK_NOFOLLOW}); stat_errno != .NONE {
		return -1, false, _get_platform_error(stat_errno)
	}
	if !linux.S_ISDIR(st.mode) {
		return -1, false, _get_platform_error(linux.unlinkat(parent, cname, {}))
	}
	if linux.unlinkat(parent, cname, {.REMOVEDIR}) == .NONE {
		return -1, false, nil
	}
	return -1, false, _get_platform_error(errno)
}

_remove_all_read :: proc(dir: _Remove_All_Dir, names: ^[dynamic]u8, entries: ^[dynamic]_Remove_All_Entry) -> Error {
	if _, errno := linux.lseek(dir, 0, .SET); errno != .NONE {
		return _get_platform_error(errno)
	}
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	buf := make([]u8, 8192, temp_allocator) or_return
	for {
		n, errno := linux.getdents(dir, buf)
		if errno == .EINVAL {
			buf = make([]u8, 2 * len(buf), temp_allocator) or_return
			continue
		}
		if errno != .NONE {
			return _get_platform_error(errno)
		}
		if n == 0 {
			return nil
		}
		offset: int
		for d in linux.dirent_iterate_buf(buf[:n], &offset) {
			name := linux.dirent_name(d)
			if name == "." || name == ".." {
				continue
			}
			kind := _Remove_All_Kind.Other
			if d.type == .DIR || d.type == .UNKNOWN {
				kind = .Directory
			}
			_remove_all_add(names, entries, transmute([]u8)name, kind) or_return
		}
	}
}

_remove_all_unlink :: proc(parent: _Remove_All_Dir, name: []u8, kind: _Remove_All_Kind) -> Error {
	flags: linux.FD_Flags
	if kind == .Directory {
		flags = {.REMOVEDIR}
	}
	return _get_platform_error(linux.unlinkat(parent, cstring(raw_data(name)), flags))
}

_remove_all_close :: proc(dir: _Remove_All_Dir) {
	linux.close(dir)
}

_get_working_directory :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	// NOTE(jason): Avoiding libc, so just use 4096 directly
	PATH_MAX :: 4096
	buf := make([dynamic]u8, PATH_MAX, allocator) or_return
	for {
		#no_bounds_check n, errno := linux.getcwd(buf[:])
		if errno == .NONE {
			return string(buf[:n-1]), nil
		}
		if errno != .ERANGE {
			return "", _get_platform_error(errno)
		}
		resize(&buf, len(buf)+PATH_MAX) or_return
	}
	unreachable()
}

_set_working_directory :: proc(dir: string) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	dir_cstr := clone_to_cstring(dir, temp_allocator) or_return
	return _get_platform_error(linux.chdir(dir_cstr))
}

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	buf := make([dynamic]byte, 1024, temp_allocator) or_return
	for {
		n, errno := linux.readlink("/proc/self/exe", buf[:])
		if errno != .NONE {
			err = _get_platform_error(errno)
			return
		}

		if n < len(buf) {
			return clone_string(string(buf[:n]), allocator)
		}

		resize(&buf, len(buf)*2) or_return
	}
}

_get_full_path :: proc(fd: linux.Fd, allocator: runtime.Allocator) -> (fullpath: string, err: Error) {
	PROC_FD_PATH :: "/proc/self/fd/"

	buf: [32]u8
	copy(buf[:], PROC_FD_PATH)

	strconv.write_int(buf[len(PROC_FD_PATH):], i64(fd), 10)

	if fullpath, err = _read_link_cstr(cstring(&buf[0]), allocator); err != nil || fullpath[0] != '/' {
		delete(fullpath, allocator)
		fullpath = ""
	}
	return
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	rel := path
	if rel == "" {
		rel = "."
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	fd, errno := linux.open(clone_to_cstring(path, temp_allocator) or_return, {})
	if errno != nil {
		err = _get_platform_error(errno)
		return
	}
	defer linux.close(fd)

	return _get_full_path(fd, allocator)
}
