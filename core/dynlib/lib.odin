package dynlib

import "core:intrinsics"
import "core:reflect"
import "core:runtime"
_ :: intrinsics
_ :: reflect
_ :: runtime

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

/*
Scans a dynamic library for symbols matching a struct's members, assigning found procedure pointers to the corresponding entry.
Optionally takes a symbol prefix added to the struct's member name to construct the symbol looked up in the library.
Optionally also takes the struct member to assign the library handle to, `__handle` by default.

This allows using one struct to hold library handles and symbol pointers for more than 1 dynamic library.

Returns:
* `-1, false` if the library could not be loaded.
* The number of symbols assigned on success. `ok` = true if `count` > 0

See doc.odin for an example.
*/
initialize_symbols :: proc(symbol_table: ^$T, library_name: string, symbol_prefix := "", handle_field_name := "__handle") -> (count: int, ok: bool) where intrinsics.type_is_struct(T) {
	assert(symbol_table != nil)
	handle: Library

	if handle, ok = load_library(library_name); !ok {
		return -1, false
	}

	// `symbol_table` must be a struct because of the where clause, so this can't fail.
	ti := runtime.type_info_base(type_info_of(T))
	s, _ := ti.variant.(runtime.Type_Info_Struct)

	// Buffer to concatenate the prefix + symbol name.
	prefixed_symbol_buf: [2048]u8 = ---

	sym_ptr: rawptr
	for field_name, i in s.names {
		// Calculate address of struct member
		field_ptr := rawptr(uintptr(rawptr(symbol_table)) + uintptr(s.offsets[i]))

		// If we've come across the struct member for the handle, store it and continue scanning for other symbols.
		if field_name == handle_field_name {
			(^Library)(field_ptr)^ = handle
			continue
		}

		// We're not the library handle, so the field needs to be a pointer type, be it a procedure pointer or an exported global.
		if !(reflect.is_procedure(s.types[i]) || reflect.is_pointer(s.types[i])) {
			continue
		}

		// Let's look up or construct the symbol name to find in the library
		prefixed_name: string

		// Do we have a symbol override tag?
		if override, tag_ok := reflect.struct_tag_lookup(reflect.Struct_Tag(s.tags[i]), "dynlib"); tag_ok {
			prefixed_name = string(override)
		}

		// No valid symbol override tag found, fall back to `<symbol_prefix>name`.
		if len(prefixed_name) == 0 {
			offset := copy(prefixed_symbol_buf[:], symbol_prefix)
			copy(prefixed_symbol_buf[offset:], field_name)
			prefixed_name = string(prefixed_symbol_buf[:len(symbol_prefix) + len(field_name)])
		}

		// Assign procedure (or global) pointer if found.
		if sym_ptr, ok = symbol_address(handle, prefixed_name); ok {
			(^rawptr)(field_ptr)^ = sym_ptr
			count += 1
		}
	}
	return count, count > 0
}