#+build !freestanding
#+build !js
package encoding_xml

import os "core:os/os2"

// Load an XML file
load_from_file :: proc(filename: string, options := DEFAULT_OPTIONS, error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	context.allocator = allocator
	options := options

	data, data_err := os.read_entire_file(filename, allocator)
	if data_err != nil { return {}, .File_Error }

	options.flags += { .Input_May_Be_Modified }

	return parse_bytes(data, options, filename, error_handler, allocator)
}
