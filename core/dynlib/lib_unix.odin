//+build linux, darwin, freebsd, openbsd, netbsd
//+private
package dynlib

import "core:os"

_load_library :: proc(path: string, global_symbols := false) -> (Library, bool) {
	flags := os.RTLD_NOW
	if global_symbols {
		flags |= os.RTLD_GLOBAL
	}
	lib := os.dlopen(path, flags)
	return Library(lib), lib != nil
}

_unload_library :: proc(library: Library) -> bool {
	return os.dlclose(rawptr(library))
}

_symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) {
	ptr = os.dlsym(rawptr(library), symbol)
	found = ptr != nil
	return
}

_last_error :: proc() -> string {
	err := os.dlerror()
	return "unknown" if err == "" else err
}