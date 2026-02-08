#+build !freestanding
#+build !js
package encoding_ini

import "base:runtime"
import os "core:os/os2"

load_map_from_path :: proc(path: string, allocator: runtime.Allocator, options := DEFAULT_OPTIONS) -> (m: Map, err: runtime.Allocator_Error, ok: bool) {
	data, data_err := os.read_entire_file(path, allocator)
	defer delete(data, allocator)
	if data_err != nil {
		return
	}
	m, err = load_map_from_string(string(data), allocator, options)
	ok = err == nil
	defer if !ok {
		delete_map(m)
	}
	return
}
