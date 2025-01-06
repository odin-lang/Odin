package mem_virtual

import "core:os"

Map_File_Error :: enum {
	None,
	Open_Failure,
	Stat_Failure,
	Negative_Size,
	Too_Large_Size,
	Map_Failure,
}

Map_File_Flag :: enum u32 {
	Read,
	Write,
}
Map_File_Flags :: distinct bit_set[Map_File_Flag; u32]

map_file :: proc{
	map_file_from_path,
	map_file_from_file_descriptor,
}

map_file_from_path :: proc(filename: string, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	fd, err := os.open(filename, os.O_RDWR)
	if err != nil {
		return nil, .Open_Failure
	}
	defer os.close(fd)

	return map_file_from_file_descriptor(uintptr(fd), flags)
}

map_file_from_file_descriptor :: proc(fd: uintptr, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	size, os_err := os.file_size(os.Handle(fd))
	if os_err != nil {
		return nil, .Stat_Failure
	}
	if size < 0 {
		return nil, .Negative_Size
	}
	if size != i64(int(size)) {
		return nil, .Too_Large_Size
	}
	return _map_file(fd, size, flags)
}
