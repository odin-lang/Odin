package example

import "core:dynlib"
import "core:fmt"

Symbols :: struct {
	// `foo_` is prefixed, so we look for the symbol `foo_add`.
	add: proc "c" (int, int) -> int,
	// We use the tag here to override the symbol to look for, namely `bar_sub`.
	sub: proc "c" (int, int) -> int `dynlib:"bar_sub"`,

	// Exported global (if exporting an i32, the type must be ^i32 because the symbol is a pointer to the export.)
	// If it's not a pointer or procedure type, we'll skip the struct field.
	hellope: ^i32,

	// Handle to free library.
	// We can have more than one of these so we can match symbols for more than one DLL with one struct.
	_my_lib_handle: dynlib.Library,
}

main :: proc() {
	sym: Symbols

	LIB_PATH :: "lib." + dynlib.LIBRARY_FILE_EXTENSION

	// Load symbols from `lib.dll` into Symbols struct.
	// Each struct field is prefixed with `foo_` before lookup in the DLL's symbol table.
	// The library's Handle (to unload) will be stored in `sym._my_lib_handle`. This way you can load multiple DLLs in one struct.
	count, ok := dynlib.initialize_symbols(&sym, LIB_PATH, "foo_", "_my_lib_handle")
	defer dynlib.unload_library(sym._my_lib_handle)
	fmt.printf("(Initial DLL Load) ok: %v. %v symbols loaded from " + LIB_PATH + " (%p).\n", ok, count, sym._my_lib_handle)

	if count > 0 {
		fmt.println("42 + 42 =", sym.add(42, 42))
		fmt.println("84 - 13 =", sym.sub(84, 13))
		fmt.println("hellope =", sym.hellope^)
	}

	count, ok = dynlib.initialize_symbols(&sym, LIB_PATH, "foo_", "_my_lib_handle")
	fmt.printf("(DLL Reload) ok: %v. %v symbols loaded from " + LIB_PATH + " (%p).\n", ok, count, sym._my_lib_handle)

	if count > 0 {
		fmt.println("42 + 42 =", sym.add(42, 42))
		fmt.println("84 - 13 =", sym.sub(84, 13))
		fmt.println("hellope =", sym.hellope^)
	}
}
