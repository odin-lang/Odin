#+build !js
package qoi

import os "core:os/os2"
import    "core:bytes"

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

save :: proc{save_to_buffer, save_to_file}

save_to_file :: proc(output: string, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	out := &bytes.Buffer{}
	defer bytes.buffer_destroy(out)

	save_to_buffer(out, img, options) or_return
	write_err := os.write_entire_file(output, out.buf[:])

	return nil if write_err == nil else .Unable_To_Write_File
}