package dynlib

import "core:sys/win32"
import "core:strings"

load_library :: proc(path: string, global_symbols := false) -> (Library, bool) {
	// NOTE(bill): 'global_symbols' is here only for consistency with POSIX which has RTLD_GLOBAL

	wide_path := win32.utf8_to_wstring(path, context.temp_allocator);
	handle := cast(Library)win32.load_library_w(wide_path);
	return handle, handle != nil;
}

unload_library :: proc(library: Library) -> bool {
	ok := win32.free_library(cast(win32.Hmodule)library);
	return bool(ok);
}

symbol_address :: proc(library: Library, symbol: string) -> (ptr: rawptr, found: bool) {
	c_str := strings.clone_to_cstring(symbol, context.temp_allocator);
	ptr = win32.get_proc_address(cast(win32.Hmodule)library, c_str);
	found = ptr != nil;
	return;
}
