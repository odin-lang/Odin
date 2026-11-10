#+private
package os

import "base:intrinsics"
import "base:runtime"

import "core:sync"
import "core:sys/wasm/wasi"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

_mkdir :: proc(name: string, perm: Permissions) -> Error {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return .Invalid_Path
	}

	return _get_platform_error(wasi.path_create_directory(dir_fd, relative))
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
	return internal_mkdir_all(clean_path)

	internal_mkdir_all :: proc(path: string) -> Error {
		dir, file := split_path(path)
		if file != path && dir != "/" {
			if len(dir) > 1 && dir[len(dir) - 1] == '/' {
				dir = dir[:len(dir) - 1]
			}
			internal_mkdir_all(dir) or_return
		}

		err := _mkdir(path, Permissions_Default)
		if err == .Exist { err = nil }
		return err
	}
}

_Remove_All_Dir :: wasi.fd_t

@(private="file")
_REMOVE_ALL_RIGHTS :: wasi.rights_t{.FD_READDIR, .PATH_OPEN, .PATH_FILESTAT_GET, .PATH_UNLINK_FILE, .PATH_REMOVE_DIRECTORY}

_remove_all_root :: proc(path: string, _: runtime.Allocator) -> (parent: _Remove_All_Dir, name: []u8, err: Error) {
	root := path
	for len(root) > 1 && root[len(root)-1] == '/' {
		root = root[:len(root)-1]
	}
	dir_fd, relative, ok := match_preopen(root)
	if !ok {
		return 0, nil, .Invalid_Path
	}
	return dir_fd, transmute([]u8)relative, nil
}

_remove_all_open :: proc(parent: _Remove_All_Dir, name: []u8) -> (dir: _Remove_All_Dir, is_dir: bool, err: Error) {
	path := string(name)
	fd, errno := wasi.path_open(parent, {}, path, {.DIRECTORY}, _REMOVE_ALL_RIGHTS, _REMOVE_ALL_RIGHTS, {})
	if errno == .SUCCESS {
		return fd, true, nil
	}
	if errno == .NOENT {
		return 0, false, .Not_Exist
	}
	stat, stat_errno := wasi.path_filestat_get(parent, {}, path)
	if stat_errno != .SUCCESS {
		return 0, false, _get_platform_error(stat_errno)
	}
	if stat.filetype != .DIRECTORY {
		return 0, false, _get_platform_error(wasi.path_unlink_file(parent, path))
	}
	if wasi.path_remove_directory(parent, path) == .SUCCESS {
		return 0, false, nil
	}
	return 0, false, _get_platform_error(errno)
}

_remove_all_read :: proc(dir: _Remove_All_Dir, names: ^[dynamic]u8, entries: ^[dynamic]_Remove_All_Entry) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	buf := make([]byte, 4096, temp_allocator) or_return
	n: int
	for {
		read, errno := wasi.fd_readdir(dir, buf, 0)
		if errno != .SUCCESS {
			return _get_platform_error(errno)
		}
		if int(read) < len(buf) {
			n = int(read)
			break
		}
		buf = make([]byte, 2 * len(buf), temp_allocator) or_return
	}

	rest := buf[:n]
	for len(rest) >= size_of(wasi.dirent_t) {
		entry := intrinsics.unaligned_load((^wasi.dirent_t)(raw_data(rest)))
		rest = rest[size_of(wasi.dirent_t):]
		if len(rest) < int(entry.d_namlen) {
			break
		}
		name := string(rest[:entry.d_namlen])
		rest = rest[entry.d_namlen:]
		if name == "." || name == ".." {
			continue
		}
		kind := _Remove_All_Kind.Other
		if entry.d_type == .DIRECTORY || entry.d_type == .UNKNOWN {
			kind = .Directory
		}
		_remove_all_add(names, entries, transmute([]u8)name, kind) or_return
	}
	return nil
}

_remove_all_unlink :: proc(parent: _Remove_All_Dir, name: []u8, kind: _Remove_All_Kind) -> Error {
	if kind == .Directory {
		return _get_platform_error(wasi.path_remove_directory(parent, string(name)))
	}
	return _get_platform_error(wasi.path_unlink_file(parent, string(name)))
}

_remove_all_close :: proc(dir: _Remove_All_Dir) {
	wasi.fd_close(dir)
}

g_wd: string
g_wd_mutex: sync.Mutex

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	sync.guard(&g_wd_mutex)

	return clone_string(g_wd if g_wd != "" else "/", allocator)
}

_set_working_directory :: proc(dir: string) -> (err: Error) {
	sync.guard(&g_wd_mutex)

	if dir == g_wd {
		return
	}

	if g_wd != "" {
		delete(g_wd, file_allocator())
	}

	g_wd = clone_string(dir, file_allocator()) or_return
	return
}

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	if len(args) <= 0 {
		return clone_string("/", allocator)
	}

	arg := args[0]
	if len(arg) > 0 && (arg[0] == '.' || arg[0] == '/') {
		return clone_string(arg, allocator)
	}

	return concatenate({"/", arg}, allocator)
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	return "", .Unsupported
}
