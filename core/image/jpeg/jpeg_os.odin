package jpeg

import os "core:os/os2"

load :: proc{load_from_file, load_from_bytes, load_from_context}

load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	data, data_err := os.read_entire_file(filename, allocator)
	defer delete(data, allocator)

	if data_err == nil {
		return load_from_bytes(data, options)
	} else {
		return nil, .Unable_To_Read_File
	}
}
