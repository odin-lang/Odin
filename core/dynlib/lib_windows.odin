//+build windows
//+private
package dynlib

import win32 "core:sys/windows"
import "core:strings"
import "base:runtime"
import "core:reflect"

_load_library :: proc(path: string, global_symbols := false) -> (Library, bool) {
	// NOTE(bill): 'global_symbols' is here only for consistency with POSIX which has RTLD_GLOBAL

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	wide_path := win32.utf8_to_wstring(path, context.temp_allocator)
	handle := cast(Library)win32.LoadLibraryW(wide_path)
	return handle, handle != nil
}

_unload_library :: proc(library: Library) -> bool {
	ok := win32.FreeLibrary(cast(win32.HMODULE)library)
	return bool(ok)
}

_symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	c_str := strings.clone_to_cstring(symbol, context.temp_allocator)
	ptr = win32.GetProcAddress(cast(win32.HMODULE)library, c_str)
	found = ptr != nil
	return
}

_last_error :: proc() -> string {
	err := win32.System_Error(win32.GetLastError())
	err_msg := reflect.enum_string(err)
	return "unknown" if err_msg == "" else err_msg
}
