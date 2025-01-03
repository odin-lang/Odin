#+build js
#+private
package dynlib

import "base:runtime"

_LIBRARY_FILE_EXTENSION :: ""

_load_library :: proc(path: string, global_symbols: bool, allocator: runtime.Allocator) -> (Library, bool) {
	return nil, false
}

_unload_library :: proc(library: Library) -> bool {
	return false
}

_symbol_address :: proc(library: Library, symbol: string, allocator: runtime.Allocator) -> (ptr: rawptr, found: bool) {
	return nil, false
}

_last_error :: proc() -> string {
	return ""
}
