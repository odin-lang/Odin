package os2

import "base:runtime"

import "core:path/filepath"

Path_Separator        :: _Path_Separator        // OS-Specific
Path_Separator_String :: _Path_Separator_String // OS-Specific
Path_List_Separator   :: _Path_List_Separator   // OS-Specific

@(require_results)
is_path_separator :: proc(c: byte) -> bool {
	return _is_path_separator(c)
}

mkdir :: make_directory

make_directory :: proc(name: string, perm: int = 0o755) -> Error {
	return _mkdir(name, perm)
}

mkdir_all :: make_directory_all

make_directory_all :: proc(path: string, perm: int = 0o755) -> Error {
	return _mkdir_all(path, perm)
}

remove_all :: proc(path: string) -> Error {
	return _remove_all(path)
}

getwd :: get_working_directory

@(require_results)
get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _get_working_directory(allocator)
}

setwd :: set_working_directory

set_working_directory :: proc(dir: string) -> (err: Error) {
	return _set_working_directory(dir)
}

get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	return _get_executable_path(allocator)
}

get_executable_directory :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	path = _get_executable_path(allocator) or_return
	path, _ = filepath.split(path)
	return
}
