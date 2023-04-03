//+build js
//+private
package dynlib

_load_library :: proc(path: string, global_symbols := false) -> (Library, bool) {
	return
}

_unload_library :: proc(library: Library) -> bool {
	return
}

_symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) {
	return
}
