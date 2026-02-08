#+build !freestanding
#+build !js
package encoding_hxa

import os "core:os/os2"

read_from_file :: proc(filename: string, print_error := false, allocator := context.allocator, loc := #caller_location) -> (file: File, err: Read_Error) {
	context.allocator = allocator

	data, data_err := os.read_entire_file(filename, allocator, loc)
	if data_err != nil {
		err = .Unable_To_Read_File
		delete(data, allocator)
		return
	}
	file, err = read(data, filename, print_error, allocator)
	file.backing   = data
	return
}

write_to_file :: proc(filepath: string, file: File) -> (err: Write_Error) {
	required := required_write_size(file)
	buf, alloc_err := make([]byte, required)
	if alloc_err == .Out_Of_Memory {
		return .Failed_File_Write
	}
	defer delete(buf)

	write_internal(&Writer{data = buf}, file)
	if os.write_entire_file(filepath, buf) != nil {
		err =.Failed_File_Write
	}
	return
}
