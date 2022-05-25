package dynlib

Library :: distinct rawptr

load_library :: proc(path: string, global_symbols := false) -> (Library, bool) {
	return _load_library(path, global_symbols)
}

unload_library :: proc(library: Library) -> bool {
	return _unload_library(library)
}

symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) {
	return _symbol_address(library, symbol)
}
