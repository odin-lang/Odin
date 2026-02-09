#+build !js
package netpbm

import "core:os"

load :: proc {
	load_from_file,
	load_from_bytes,
}

load_from_file :: proc(filename: string, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	data, data_err := os.read_entire_file(filename, allocator); defer delete(data)
	if data_err == nil {
		return load_from_bytes(data)
	} else {
		err = .Unable_To_Read_File
		return
	}
}

save :: proc {
	save_to_file,
	save_to_buffer,
}

save_to_file :: proc(filename: string, img: ^Image, custom_info: Info = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	data: []byte; defer delete(data)
	data = save_to_buffer(img, custom_info) or_return

	if save_err := os.write_entire_file(filename, data); save_err != nil {
		return .Unable_To_Write_File
	}

	return Format_Error.None
}