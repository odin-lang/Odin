#+build !freestanding
#+build !js
package mem_virtual

import os "core:os/os2"

map_file :: proc{
	map_file_from_path,
	map_file_from_file,
}

map_file_from_path :: proc(filename: string, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	f, err := os.open(filename, os.O_RDWR)
	if err != nil {
		return nil, .Open_Failure
	}
	defer os.close(f)
	return map_file_from_file(f, flags)
}

map_file_from_file :: proc(f: ^os.File, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	size, os_err := os.file_size(f)
	if os_err != nil {
		return nil, .Stat_Failure
	}
	if size < 0 {
		return nil, .Negative_Size
	}
	if size != i64(int(size)) {
		return nil, .Too_Large_Size
	}
	fd := os.fd(f)
	return _map_file(fd, size, flags)
}

unmap_file :: proc(data: []byte) {
	if raw_data(data) != nil {
		_unmap_file(data)
	}
}