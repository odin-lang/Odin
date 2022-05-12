package os2

import "core:runtime"

create_temp :: proc(dir, pattern: string) -> (^File, Error) {
	return _create_temp(dir, pattern)
}

mkdir_temp :: proc(dir, pattern: string, allocator: runtime.Allocator) -> (string, Error) {
	return _mkdir_temp(dir, pattern, allocator)
}

temp_dir :: proc(allocator: runtime.Allocator) -> string {
	return _temp_dir(allocator)
}
