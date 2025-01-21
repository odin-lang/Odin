#+private
package os2

import "base:runtime"

import "core:path/filepath"
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

	TEMP_ALLOCATOR_GUARD()

	if exists(path) {
		return .Exist
	}

	clean_path := filepath.clean(path, temp_allocator())
	return internal_mkdir_all(clean_path)

	internal_mkdir_all :: proc(path: string) -> Error {
		dir, file := filepath.split(path)
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

		iter := read_directory_iterator_create(dir) or_return
		defer read_directory_iterator_destroy(&iter)

		for fi in read_directory_iterator(&iter) {
			if fi.type == .Directory {
				_remove_all(fi.fullpath) or_return
			} else {
				remove(fi.fullpath) or_return
			}
		}
	}

	return remove(path)
}

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return ".", .Unsupported
}

_set_working_directory :: proc(dir: string) -> (err: Error) {
	err = .Unsupported
	return
}
