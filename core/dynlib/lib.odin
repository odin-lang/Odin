package dynlib

import "base:intrinsics"
import "core:mem"
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
`path` is copied with `allocator` first; if that runs out of memory, `did_load` is false and
`last_error` does not describe it.

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
`symbol` is copied with `allocator` first; if that runs out of memory, `found` is false and
`last_error` does not describe it.

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

A reload loads the new library first and then unloads the previous incarnation, allowing for
straightforward hot reload support. Symbols that only the previous incarnation provided are set to
`nil`. Reloading the same path has to unload the previous incarnation before loading it again.

Returns:
* `-1, false` if the library could not be loaded, including when that runs out of memory. The
  struct and the previous incarnation are left untouched, unless the same path was being
  reloaded: then its symbols and the handle are `nil`.
* The number of symbols assigned on success. `ok` = true if `count` > 0

See doc.odin for an example.
*/
initialize_symbols :: proc(
	symbol_table: ^$T, library_path: string,
	symbol_prefix := "", handle_field_name := "__handle",
) -> (count: int = -1, ok: bool = false) where intrinsics.type_is_struct(T) {
	assert(symbol_table != nil)

	handle_ptr: ^Library
	for field in reflect.struct_fields_zipped(T) {
		if field.name == handle_field_name {
			handle_ptr = (^Library)(uintptr(symbol_table) + field.offset)
			break
		}
	}
	old_handle: Library
	if handle_ptr != nil {
		old_handle = handle_ptr^
	}

	// First, (re)load the library.
	handle := load_library(library_path) or_return

	if old_handle != nil && handle == old_handle {
		unload_library(handle)
		bind_symbols(symbol_table, T, nil, old_handle, symbol_prefix, handle_field_name)
		unload_library(old_handle)
		handle_ptr^ = nil
		old_handle = nil
		handle = load_library(library_path) or_return
	}

	count = bind_symbols(symbol_table, T, handle, old_handle, symbol_prefix, handle_field_name)

	// We appear to be hot reloading. Unload previous incarnation of the library.
	if old_handle != nil {
		unload_library(old_handle)
	}

	if handle_ptr != nil {
		handle_ptr^ = handle
	}

	// No field for it in the struct.
	if handle_ptr == nil && count == 0 {
		unload_library(handle)
	}
	return count, count > 0
}

// Returns an error message for the last failed procedure call.
last_error :: proc() -> string {
	return _last_error()
}

@(private)
bind_symbols :: proc(symbol_table: rawptr, T: typeid, library, previous: Library, symbol_prefix, handle_field_name: string) -> (count: int) {
	// Buffer to concatenate the prefix + symbol name.
	prefixed_symbol_buf: [2048]u8 = ---

	cstring_buf: [len(prefixed_symbol_buf) + 1]u8 = ---
	cstring_arena: mem.Arena
	mem.arena_init(&cstring_arena, cstring_buf[:])
	cstring_allocator := mem.arena_allocator(&cstring_arena)

	for field in reflect.struct_fields_zipped(T) {
		// If we're not the library handle, the field needs to be a pointer type, be it a procedure pointer or an exported global.
		if field.name == handle_field_name || !(reflect.is_procedure(field.type) || reflect.is_pointer(field.type)) {
			continue
		}

		// Calculate address of struct member
		field_ptr := (^rawptr)(uintptr(symbol_table) + field.offset)

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

		symbol_allocator := context.temp_allocator
		if len(prefixed_name) < len(cstring_buf) {
			free_all(cstring_allocator)
			symbol_allocator = cstring_allocator
		}

		// Assign procedure (or global) pointer if found.
		if library != nil {
			if sym_ptr, found := symbol_address(library, prefixed_name, symbol_allocator); found {
				field_ptr^ = sym_ptr
				count += 1
				continue
			}
		}

		if previous != nil && field_ptr^ != nil {
			free_all(cstring_allocator)
			if old_ptr, old_found := symbol_address(previous, prefixed_name, symbol_allocator); old_found && old_ptr == field_ptr^ {
				field_ptr^ = nil
			}
		}
	}
	return
}
