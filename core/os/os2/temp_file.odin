package os2


create_temp :: proc(dir, pattern: string) -> (^File, Error) {
	return _create_temp(dir, pattern)
}

mkdir_temp :: proc(dir, pattern: string, allocator := context.allocator) -> (string, Error) {
	return _mkdir_temp(dir, pattern)
}

temp_dir :: proc(allocator := context.allocator) -> string {
	return _temp_dir(allocator)
}
