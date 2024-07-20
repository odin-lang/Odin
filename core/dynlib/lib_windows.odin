//+build windows
//+private
package dynlib

import win32 "core:sys/windows"
import "core:strings"
import "core:reflect"

_load_library :: proc(path: string, global_symbols := false, allocator := context.temp_allocator) -> (Library, bool) {
	// NOTE(bill): 'global_symbols' is here only for consistency with POSIX which has RTLD_GLOBAL
	wide_path := win32.utf8_to_wstring(path, allocator)
	defer free(wide_path, allocator)
	handle := cast(Library)win32.LoadLibraryW(wide_path)
	return handle, handle != nil
}

_unload_library :: proc(library: Library) -> bool {
	ok := win32.FreeLibrary(cast(win32.HMODULE)library)
	return bool(ok)
}

_symbol_address :: proc(library: Library, symbol: string, allocator := context.temp_allocator) -> (ptr: rawptr, found: bool) {
	c_str := strings.clone_to_cstring(symbol, allocator)
	defer delete(c_str, allocator)
	ptr = win32.GetProcAddress(cast(win32.HMODULE)library, c_str)
	found = ptr != nil
	return
}

_last_error :: proc() -> string {
	err := win32.System_Error(win32.GetLastError())
	err_msg := reflect.enum_string(err)
	return "unknown" if err_msg == "" else err_msg
}