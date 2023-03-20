//+build js
//+private
package dynlib

_load_library :: proc(path: string, global_symbols := false) -> (Library, bool) {
	panic("core:dynlib not supported by JS target")
}

_unload_library :: proc(library: Library) -> bool {
	panic("core:dynlib not supported by JS target")
}

_symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) {
	panic("core:dynlib not supported by JS target")
}
