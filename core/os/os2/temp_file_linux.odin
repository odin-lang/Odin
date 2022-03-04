//+private
package os2


_create_temp :: proc(dir, pattern: string) -> (Handle, Error) {
	//TODO
	return 0, nil
}

_mkdir_temp :: proc(dir, pattern: string, allocator := context.allocator) -> (string, Error) {
	//TODO
	return "", nil
}

_temp_dir :: proc(allocator := context.allocator) -> string {
	//TODO
	return ""
}
