#+private
#+build darwin, netbsd, freebsd, openbsd
package os

import "base:runtime"

import "core:sys/posix"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

_mkdir :: proc(name: string, perm: Permissions) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	cname := clone_to_cstring(name, temp_allocator) or_return
	if posix.mkdir(cname, transmute(posix.mode_t)posix._mode_t(transmute(u32)perm)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_mkdir_all :: proc(path: string, perm: Permissions) -> Error {
	if path == "" {
		return .Invalid_Path
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	if exists(path) {
		return .Exist
	}

	clean_path := clean_path(path, temp_allocator) or_return
	return internal_mkdir_all(clean_path, perm)

	internal_mkdir_all :: proc(path: string, perm: Permissions) -> Error {
		dir, file := split_path(path)
		if file != path && dir != "/" {
			if len(dir) > 1 && dir[len(dir) - 1] == '/' {
				dir = dir[:len(dir) - 1]
			}
			internal_mkdir_all(dir, perm) or_return
		}

		err := _mkdir(path, perm)
		if err == .Exist { err = nil }
		return err
	}
}

_Remove_All_Dir :: posix.FD

@(private="file")
_REMOVE_ALL_OPEN_FLAGS :: posix.O_Flags{.DIRECTORY, .NOFOLLOW, .NONBLOCK, .CLOEXEC}

_remove_all_root :: proc(path: string, allocator: runtime.Allocator) -> (parent: _Remove_All_Dir, name: []u8, err: Error) {
	root := path
	for len(root) > 1 && root[len(root)-1] == '/' {
		root = root[:len(root)-1]
	}
	croot := clone_to_cstring(root, allocator) or_return
	return posix.AT_FDCWD, ([^]u8)(croot)[:len(root)], nil
}

_remove_all_open :: proc(parent: _Remove_All_Dir, name: []u8) -> (dir: _Remove_All_Dir, is_dir: bool, err: Error) {
	cname := cstring(raw_data(name))
	fd := posix.openat(parent, cname, _REMOVE_ALL_OPEN_FLAGS)
	if fd >= 0 {
		return fd, true, nil
	}
	open_errno := posix.errno()
	if open_errno == .ENOENT {
		return -1, false, .Not_Exist
	}
	st: posix.stat_t
	if posix.fstatat(parent, cname, &st, {.SYMLINK_NOFOLLOW}) != .OK {
		return -1, false, _get_platform_error()
	}
	if !posix.S_ISDIR(st.st_mode) {
		if posix.unlinkat(parent, cname, {}) != .OK {
			return -1, false, _get_platform_error()
		}
		return -1, false, nil
	}
	if posix.unlinkat(parent, cname, {.REMOVEDIR}) == .OK {
		return -1, false, nil
	}
	return -1, false, _get_platform_error(open_errno)
}

_remove_all_read :: proc(dir: _Remove_All_Dir, names: ^[dynamic]u8, entries: ^[dynamic]_Remove_All_Entry) -> Error {
	fd := posix.openat(dir, ".", {.DIRECTORY, .CLOEXEC})
	if fd < 0 {
		return _get_platform_error()
	}
	stream := posix.fdopendir(fd)
	if stream == nil {
		err := _get_platform_error()
		posix.close(fd)
		return err
	}
	defer posix.closedir(stream)

	for {
		posix.set_errno(.NONE)
		entry := posix.readdir(stream)
		if entry == nil {
			if posix.errno() != .NONE {
				return _get_platform_error()
			}
			return nil
		}
		name := string(cstring(raw_data(entry.d_name[:])))
		if name == "." || name == ".." {
			continue
		}
		kind := _Remove_All_Kind.Other
		if entry.d_type == .DIR || entry.d_type == .UNKNOWN {
			kind = .Directory
		}
		_remove_all_add(names, entries, transmute([]u8)name, kind) or_return
	}
}

_remove_all_unlink :: proc(parent: _Remove_All_Dir, name: []u8, kind: _Remove_All_Kind) -> Error {
	flags: posix.AT_Flags
	if kind == .Directory {
		flags = {.REMOVEDIR}
	}
	if posix.unlinkat(parent, cstring(raw_data(name)), flags) != .OK {
		return _get_platform_error()
	}
	return nil
}

_remove_all_close :: proc(dir: _Remove_All_Dir) {
	posix.close(dir)
}

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	buf: [dynamic]byte
	buf.allocator = temp_allocator
	size := uint(posix.PATH_MAX)

	cwd: cstring
	for ; cwd == nil; size *= 2 {
		resize(&buf, size)

		cwd = posix.getcwd(raw_data(buf), len(buf))
		if cwd == nil && posix.errno() != .ERANGE {
			err = _get_platform_error()
			return
		}
	}

	return clone_string(string(cwd), allocator)
}

_set_working_directory :: proc(dir: string) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	cdir := clone_to_cstring(dir, temp_allocator) or_return
	if posix.chdir(cdir) != .OK {
		err = _get_platform_error()
	}
	return
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	rel := path
	if rel == "" {
		rel = "."
	}
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	rel_cstr := clone_to_cstring(rel, temp_allocator) or_return
	path_ptr := posix.realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", _get_platform_error()
	}
	defer posix.free(path_ptr)

	path_str := clone_string(string(path_ptr), allocator) or_return
	return path_str, nil
}
