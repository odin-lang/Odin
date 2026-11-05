#+build !js
package bng

import "core:os"

load :: proc{load_from_file, load_from_bytes, load_from_context}

load_from_file :: proc(filename: string, options := Default_Options, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	data, data_err := os.read_entire_file(filename, allocator)
	defer delete(data, allocator)

	if data_err == nil {
		return load_from_bytes(data, options)
	} else {
		return nil, .Unable_To_Read_File
	}
}

save :: proc{save_to_buffer, save_to_file}

save_to_file :: proc(output: string, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	out: [dynamic]byte
	defer delete(out)

	save_to_buffer(&out, img, options) or_return
	write_err := os.write_entire_file(output, out[:])

	return nil if write_err == nil else .Unable_To_Write_File
}