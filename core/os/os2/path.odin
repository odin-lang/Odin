package os2

import "base:runtime"

import "core:path/filepath"

Path_Separator        :: _Path_Separator        // OS-Specific
Path_Separator_String :: _Path_Separator_String // OS-Specific
Path_List_Separator   :: _Path_List_Separator   // OS-Specific

#assert(_Path_Separator <= rune(0x7F), "The system-specific path separator rune is expected to be within the 7-bit ASCII character set.")

/*
Return true if `c` is a character used to separate paths into directory and
file hierarchies on the current system.
*/
@(require_results)
is_path_separator :: proc(c: byte) -> bool {
	return _is_path_separator(c)
}

mkdir :: make_directory

/*
Make a new directory.

If `path` is relative, it will be relative to the process's current working directory.
*/
make_directory :: proc(name: string, perm: int = 0o755) -> Error {
	return _mkdir(name, perm)
}

mkdir_all :: make_directory_all

/*
Make a new directory, creating new intervening directories when needed.

If `path` is relative, it will be relative to the process's current working directory.
*/
make_directory_all :: proc(path: string, perm: int = 0o755) -> Error {
	return _mkdir_all(path, perm)
}

/*
Delete `path` and all files and directories inside of `path` if it is a directory.

If `path` is relative, it will be relative to the process's current working directory.
*/
remove_all :: proc(path: string) -> Error {
	return _remove_all(path)
}

getwd :: get_working_directory

/*
Get the working directory of the current process.

*Allocates Using Provided Allocator*
*/
@(require_results)
get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _get_working_directory(allocator)
}

setwd :: set_working_directory

/*
Change the working directory of the current process.

*Allocates Using Provided Allocator*
*/
set_working_directory :: proc(dir: string) -> (err: Error) {
	return _set_working_directory(dir)
}

/*
Get the path for the currently running executable.

*Allocates Using Provided Allocator*
*/
get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	return _get_executable_path(allocator)
}

/*
Get the directory for the currently running executable.

*Allocates Using Provided Allocator*
*/
get_executable_directory :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	path = _get_executable_path(allocator) or_return
	path, _ = filepath.split(path)
	return
}
