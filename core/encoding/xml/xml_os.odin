#+build !freestanding
#+build !js
package encoding_xml

import "base:runtime"
import "core:os"

// Load an XML file
load_from_file :: proc(filename: string, options := DEFAULT_OPTIONS, error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	context.allocator = allocator
	options := options

	data, data_err := os.read_entire_file(filename, allocator)
	if _, is_alloc_err := data_err.(runtime.Allocator_Error); is_alloc_err { return {}, .Allocation_Failed }
	if data_err != nil { return {}, .File_Error }

	options.flags += { .Input_May_Be_Modified }

	doc, err = parse_bytes(data, options, filename, error_handler, allocator)
	if doc == nil {
		// No document took the data over, so it's still ours to free.
		delete(data)
	} else {
		doc.input = data
	}
	return
}
