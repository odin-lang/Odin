package os2

import "base:runtime"

create_temp_file :: proc(dir, pattern: string) -> (^File, Error) {
	return _create_temp(dir, pattern)
}

mkdir_temp :: make_directory_temp
make_directory_temp :: proc(dir, pattern: string, allocator: runtime.Allocator) -> (string, Error) {
	return _mkdir_temp(dir, pattern, allocator)
}

temp_dir :: temp_directory
temp_directory :: proc(allocator: runtime.Allocator) -> (string, Error) {
	return _temp_dir(allocator)
}
