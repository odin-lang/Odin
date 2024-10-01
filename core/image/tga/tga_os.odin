#+build !js
package tga

import "core:os"
import "core:bytes"

save :: proc{save_to_buffer, save_to_file}

save_to_file :: proc(output: string, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	out := &bytes.Buffer{}
	defer bytes.buffer_destroy(out)

	save_to_buffer(out, img, options) or_return
	write_ok := os.write_entire_file(output, out.buf[:])

	return nil if write_ok else .Unable_To_Write_File
}

load :: proc{load_from_file, load_from_bytes, load_from_context}

load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	data, ok := os.read_entire_file(filename)
	defer delete(data)

	if ok {
		return load_from_bytes(data, options)
	} else {
		return nil, .Unable_To_Read_File
	}
}