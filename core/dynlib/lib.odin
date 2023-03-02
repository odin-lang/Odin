package dynlib

/*
A handle to a dynamically loaded library.
*/
Library :: distinct rawptr

/*
Loads a dynamic library from the filesystem. The paramater `global_symbols` makes the symbols in the loaded
library available to resolve references in subsequently loaded libraries.

The paramater `global_symbols` is only used for the platforms `linux`, `darwin`, `freebsd` and `openbsd`.
On `windows` this paramater is ignored.

The underlying behaviour is platform specific.  
On `linux`, `darwin`, `freebsd` and `openbsd` refer to `dlopen`.  
On `windows` refer to `LoadLibraryW`.

**Implicit Allocators**  
`context.temp_allocator`

Example:
	import "core:dynlib"
	import "core:fmt"

	load_my_library :: proc() {
		LIBRARY_PATH :: "my_library.dll"
		library, ok := dynlib.load_library(LIBRARY_PATH)
		if ! ok {
			return
		}
		fmt.println("The library %q was successfully loaded", LIBRARY_PATH)
	}
*/
load_library :: proc(path: string, global_symbols := false) -> (library: Library, did_load: bool) {
	return _load_library(path, global_symbols)
}

/*
Unloads a dynamic library.

The underlying behaviour is platform specific.  
On `linux`, `darwin`, `freebsd` and `openbsd` refer to `dlclose`.  
On `windows` refer to `FreeLibrary`.

Example:
	import "core:dynlib"
	import "core:fmt"

	load_then_unload_my_library :: proc() {
		LIBRARY_PATH :: "my_library.dll"
		library, ok := dynlib.load_library(LIBRARY_PATH)
		if ! ok {
			return
		}
		did_unload := dynlib.unload_library(library)
		if ! did_unload {
			return
		}
		fmt.println("The library %q was successfully unloaded", LIBRARY_PATH)
	}
*/
unload_library :: proc(library: Library) -> (did_unload: bool) {
	return _unload_library(library)
}

/*
Loads the address of a procedure/variable from a dynamic library.

The underlying behaviour is platform specific.  
On `linux`, `darwin`, `freebsd` and `openbsd` refer to `dlsym`.  
On `windows` refer to `GetProcAddress`.

**Implicit Allocators**  
`context.temp_allocator`

Example:
	import "core:dynlib"
	import "core:fmt"

	find_a_in_my_library :: proc() {
		LIBRARY_PATH :: "my_library.dll"
		library, ok := dynlib.load_library(LIBRARY_PATH)
		if ! ok {
			return
		}

		a, found_a := dynlib.symbol_address(library, "a")
		if found_a do fmt.printf("The symbol %q was found at the address %v", "a", a)
	}
*/
symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) #optional_ok {
	return _symbol_address(library, symbol)
}
