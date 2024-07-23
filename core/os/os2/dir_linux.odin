package os2

import "base:runtime"

@(private)
_read_directory :: proc(f: ^File, n: int, allocator: runtime.Allocator) -> (files: []File_Info, err: Error) {
	return
}
