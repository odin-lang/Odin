#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:sys/posix"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

_mkdir :: proc(name: string, perm: int) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	cname := clone_to_cstring(name, temp_allocator) or_return
	if posix.mkdir(cname, transmute(posix.mode_t)posix._mode_t(perm)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_mkdir_all :: proc(path: string, perm: int) -> Error {
	if path == "" {
		return .Invalid_Path
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	if exists(path) {
		return .Exist
	}

	clean_path := clean_path(path, temp_allocator) or_return
	return internal_mkdir_all(clean_path, perm)

	internal_mkdir_all :: proc(path: string, perm: int) -> Error {
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

_remove_all :: proc(path: string) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	cpath := clone_to_cstring(path, temp_allocator) or_return

	dir := posix.opendir(cpath)
	if dir == nil {
		return _get_platform_error()
	}
	defer posix.closedir(dir)

	for {
		posix.set_errno(.NONE)
		entry := posix.readdir(dir)
		if entry == nil {
			if errno := posix.errno(); errno != .NONE {
				return _get_platform_error()
			} else {
				break
			}
		}

		cname := cstring(raw_data(entry.d_name[:]))
		if cname == "." || cname == ".." {
			continue
		}

		fullpath, _ := concatenate({path, "/", string(cname), "\x00"}, temp_allocator)
		if entry.d_type == .DIR {
			_remove_all(fullpath[:len(fullpath)-1]) or_return
		} else {
			if posix.unlink(cstring(raw_data(fullpath))) != .OK {
				return _get_platform_error()
			}
		}
	}

	if posix.rmdir(cpath) != .OK {
		return _get_platform_error()
	}
	return nil
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
		return "", Platform_Error(posix.errno())
	}
	defer posix.free(path_ptr)

	path_str := clone_string(string(path_ptr), allocator) or_return
	return path_str, nil
}
