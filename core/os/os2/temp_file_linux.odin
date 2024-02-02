//+private
package os2

import "base:runtime"


_create_temp :: proc(dir, pattern: string) -> (^File, Error) {
	//TODO
	return nil, nil
}

_mkdir_temp :: proc(dir, pattern: string, allocator: runtime.Allocator) -> (string, Error) {
	//TODO
	return "", nil
}

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, Error) {
	//TODO
	return "", nil
}
