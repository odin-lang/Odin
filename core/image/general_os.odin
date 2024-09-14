#+build !js
package image

import "core:os"

load :: proc{
	load_from_bytes,
	load_from_file,
}


load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	data, ok := os.read_entire_file(filename, allocator)
	defer delete(data, allocator)
	if ok {
		return load_from_bytes(data, options, allocator)
	} else {
		return nil, .Unable_To_Read_File
	}
}


which :: proc{
	which_bytes,
	which_file,
}

which_file :: proc(path: string) -> Which_File_Type {
	f, err := os.open(path)
	if err != nil {
		return .Unknown
	}
	header: [128]byte
	os.read(f, header[:])
	file_type := which_bytes(header[:])
	os.close(f)
	return file_type
}