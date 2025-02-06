#+build linux, darwin, freebsd, openbsd, netbsd
#+private
package dynlib

import "base:runtime"

import "core:strings"
import "core:sys/posix"

_LIBRARY_FILE_EXTENSION :: "dylib" when ODIN_OS == .Darwin else "so"

_load_library :: proc(path: string, global_symbols: bool, allocator: runtime.Allocator) -> (Library, bool) {
	flags := posix.RTLD_Flags{.NOW}
	if global_symbols {
		flags += {.GLOBAL}
	} else {
		flags += posix.RTLD_LOCAL
	}

	cpath := strings.clone_to_cstring(path, allocator)
	defer delete(cpath, allocator)

	lib := posix.dlopen(cpath, flags)
	return Library(lib), lib != nil
}

_unload_library :: proc(library: Library) -> bool {
	return posix.dlclose(posix.Symbol_Table(library)) == 0
}

_symbol_address :: proc(library: Library, symbol: string, allocator: runtime.Allocator) -> (ptr: rawptr, found: bool) {
	csymbol := strings.clone_to_cstring(symbol, allocator)
	defer delete(csymbol, allocator)

	ptr   = posix.dlsym(posix.Symbol_Table(library), csymbol)
	found = ptr != nil
	return
}

_last_error :: proc() -> string {
	err := string(posix.dlerror())
	return "unknown" if err == "" else err
}
