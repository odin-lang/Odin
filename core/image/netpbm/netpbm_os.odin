#+build !js
package netpbm

import "core:os"

load :: proc {
	load_from_file,
	load_from_bytes,
}


load_from_file :: proc(filename: string, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	data, ok := os.read_entire_file(filename); defer delete(data)
	if !ok {
		err = .Unable_To_Read_File
		return
	}

	return load_from_bytes(data)
}


save :: proc {
	save_to_file,
	save_to_buffer,
}

save_to_file :: proc(filename: string, img: ^Image, custom_info: Info = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	data: []byte; defer delete(data)
	data = save_to_buffer(img, custom_info) or_return

	if ok := os.write_entire_file(filename, data); !ok {
		return .Unable_To_Write_File
	}

	return Format_Error.None
}