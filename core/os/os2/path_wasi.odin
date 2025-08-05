#+private
package os2

import "base:runtime"

import "core:sync"
import "core:sys/wasm/wasi"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

_mkdir :: proc(name: string, perm: int) -> Error {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return .Invalid_Path
	}

	return _get_platform_error(wasi.path_create_directory(dir_fd, relative))
}

_mkdir_all :: proc(path: string, perm: int) -> Error {
	if path == "" {
		return .Invalid_Path
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	if exists(path) {
		return .Exist
	}

	clean_path := clean_path(path, temp_allocator)
	return internal_mkdir_all(clean_path)

	internal_mkdir_all :: proc(path: string) -> Error {
		dir, file := split_path(path)
		if file != path && dir != "/" {
			if len(dir) > 1 && dir[len(dir) - 1] == '/' {
				dir = dir[:len(dir) - 1]
			}
			internal_mkdir_all(dir) or_return
		}

		err := _mkdir(path, 0)
		if err == .Exist { err = nil }
		return err
	}
}

_remove_all :: proc(path: string) -> (err: Error) {
	//  PERF: this works, but wastes a bunch of memory using the read_directory_iterator API
	// and using open instead of wasi fds directly.
	{
		dir := open(path) or_return
		defer close(dir)

		iter := read_directory_iterator_create(dir)
		defer read_directory_iterator_destroy(&iter)

		for fi in read_directory_iterator(&iter) {
			_ = read_directory_iterator_error(&iter) or_break

			if fi.type == .Directory {
				_remove_all(fi.fullpath) or_return
			} else {
				remove(fi.fullpath) or_return
			}
		}

		_ = read_directory_iterator_error(&iter) or_return
	}

	return remove(path)
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
