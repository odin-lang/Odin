#+build !freestanding
#+build !js
package encoding_ini

import "base:runtime"
import "core:os"

load_map_from_path :: proc(path: string, allocator: runtime.Allocator, options := DEFAULT_OPTIONS) -> (m: Map, err: os.Error) {
	data := os.read_entire_file(path, allocator) or_return
	defer delete(data, allocator)
	m = load_map_from_string(string(data), allocator, options) or_return
	return
}
