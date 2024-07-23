package os2

import "base:runtime"

read_directory :: proc(f: ^File, n: int, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	return _read_directory(f, n, allocator)
}

read_all_directory :: proc(f: ^File, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	return read_directory(f, -1, allocator)
}

read_directory_by_path :: proc(path: string, n: int, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	f := open(path) or_return
	defer close(f)
	return read_directory(f, n, allocator)
}

read_all_directory_by_path :: proc(path: string, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	return read_directory_by_path(path, -1, allocator)
}