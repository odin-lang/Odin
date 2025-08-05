package dynlib

import "base:intrinsics"
import "core:reflect"
import "base:runtime"
_ :: intrinsics
_ :: reflect
_ :: runtime

/*
A handle to a dynamically loaded library.
*/
Library :: distinct rawptr

/*
The file extension for dynamic libraries on the target OS.
*/
LIBRARY_FILE_EXTENSION :: _LIBRARY_FILE_EXTENSION

/*
Loads a dynamic library from the filesystem. The paramater `global_symbols` makes the symbols in the loaded
library available to resolve references in subsequently loaded libraries.

The parameter `global_symbols` is only used for the platforms `linux`, `darwin`, `freebsd` and `openbsd`.
On `windows` this paramater is ignored.

The underlying behaviour is platform specific.
On `linux`, `darwin`, `freebsd` and `openbsd` refer to `dlopen`.
On `windows` refer to `LoadLibraryW`. Also temporarily needs an allocator to convert a string.

Example:
	import "core:dynlib"
	import "core:fmt"

	load_my_library :: proc() {
		LIBRARY_PATH :: "my_library.dll"
		library, ok := dynlib.load_library(LIBRARY_PATH)
		if ! ok {
			fmt.eprintln(dynlib.last_error())
			return
		}
		fmt.println("The library %q was successfully loaded", LIBRARY_PATH)
	}
*/
load_library :: proc(path: string, global_symbols := false, allocator := context.temp_allocator) -> (library: Library, did_load: bool) {
	return _load_library(path, global_symbols, allocator)
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
			fmt.eprintln(dynlib.last_error())
			return
		}
		did_unload := dynlib.unload_library(library)
		if ! did_unload {
			fmt.eprintln(dynlib.last_error())
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
On `windows` refer to `GetProcAddress`. Also temporarily needs an allocator to convert a string.

Example:
	import "core:dynlib"
	import "core:fmt"

	find_a_in_my_library :: proc() {
		LIBRARY_PATH :: "my_library.dll"
		library, ok := dynlib.load_library(LIBRARY_PATH)
		if ! ok {
			fmt.eprintln(dynlib.last_error())
			return
		}

		a, found_a := dynlib.symbol_address(library, "a")
		if found_a {
			fmt.printf("The symbol %q was found at the address %v", "a", a)
		} else {
			fmt.eprintln(dynlib.last_error())
		}
	}
*/
symbol_address :: proc(library: Library, symbol: string, allocator := context.temp_allocator) -> (ptr: rawptr, found: bool) #optional_ok {
	return _symbol_address(library, symbol, allocator)
}

/*
Scans a dynamic library for symbols matching a struct's members, assigning found procedure pointers to the corresponding entry.
Optionally takes a symbol prefix added to the struct's member name to construct the symbol looked up in the library.
Optionally also takes the struct member to assign the library handle to, `__handle` by default.

This allows using one struct to hold library handles and symbol pointers for more than 1 dynamic library.

Loading the same library twice unloads the previous incarnation, allowing for straightforward hot reload support.

Returns:
* `-1, false` if the library could not be loaded.
* The number of symbols assigned on success. `ok` = true if `count` > 0

See doc.odin for an example.
*/
initialize_symbols :: proc(
	symbol_table: ^$T, library_path: string,
	symbol_prefix := "", handle_field_name := "__handle",
) -> (count: int = -1, ok: bool = false) where intrinsics.type_is_struct(T) {
	assert(symbol_table != nil)

	// First, (re)load the library.
	handle: Library
	for field in reflect.struct_fields_zipped(T) {
		if field.name == handle_field_name {
			field_ptr := rawptr(uintptr(symbol_table) + field.offset)

			// We appear to be hot reloading. Unload previous incarnation of the library.
			if old_handle := (^Library)(field_ptr)^; old_handle != nil {
				unload_library(old_handle) or_return
			}

			handle = load_library(library_path) or_return
			(^Library)(field_ptr)^ = handle
			break
		}
	}

	// No field for it in the struct.
	if handle == nil {
		handle = load_library(library_path) or_return
	}

	// Buffer to concatenate the prefix + symbol name.
	prefixed_symbol_buf: [2048]u8 = ---

	count = 0
	for field in reflect.struct_fields_zipped(T) {
		// If we're not the library handle, the field needs to be a pointer type, be it a procedure pointer or an exported global.
		if field.name == handle_field_name || !(reflect.is_procedure(field.type) || reflect.is_pointer(field.type)) {
			continue
		}

		// Calculate address of struct member
		field_ptr := rawptr(uintptr(symbol_table) + field.offset)

		// Let's look up or construct the symbol name to find in the library
		prefixed_name: string

		// Do we have a symbol override tag?
		if override, tag_ok := reflect.struct_tag_lookup(field.tag, "dynlib"); tag_ok {
			prefixed_name = override
		}

		// No valid symbol override tag found, fall back to `<symbol_prefix>name`.
		if len(prefixed_name) == 0 {
			offset := copy(prefixed_symbol_buf[:], symbol_prefix)
			copy(prefixed_symbol_buf[offset:], field.name)
			prefixed_name = string(prefixed_symbol_buf[:len(symbol_prefix) + len(field.name)])
		}

		// Assign procedure (or global) pointer if found.
		sym_ptr := symbol_address(handle, prefixed_name) or_continue
		(^rawptr)(field_ptr)^ = sym_ptr
		count += 1
	}
	return count, count > 0
}

// Returns an error message for the last failed procedure call.
last_error :: proc() -> string {
	return _last_error()
}
