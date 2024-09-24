#+build windows
package test_core_sys_windows

import "core:testing"
import win32 "core:sys/windows"
import "base:runtime"
import "core:strings"
import "core:mem"

read_from_clipboard :: proc(wnd_handle: win32.HWND, allocator: runtime.Allocator) -> (result: string, ok: win32.BOOL) {
	win32.IsClipboardFormatAvailable(win32.CF_TEXT) or_return
	
	win32.OpenClipboard(wnd_handle) or_return
	defer win32.CloseClipboard()
	
	clipboard_data := win32.GetClipboardData(win32.CF_TEXT)
	if clipboard_data != nil {
		if cstr := cstring(win32.GlobalLock(win32.HGLOBAL(clipboard_data))); cstr != nil {
			result = strings.clone_from_cstring(cstr, allocator)
		ok = true
		}
		win32.GlobalUnlock(win32.HGLOBAL(clipboard_data))
	}
	return
}

write_to_clipboard :: proc(wnd_handle: win32.HWND, text: string) -> win32.BOOL {
	win32.OpenClipboard(wnd_handle) or_return
	defer win32.CloseClipboard()
	win32.EmptyClipboard()
	
	h_mem := win32.HGLOBAL(win32.GlobalAlloc(win32.GMEM_MOVEABLE, len(text) + 1))
	if h_mem == nil {return false}
	
	cstr_dst := cast([^]u8)win32.GlobalLock(h_mem)
	defer win32.GlobalUnlock(h_mem)
	if cstr_dst == nil {return false}
	
	mem.copy(rawptr(cstr_dst), raw_data(text), len(text))
	cstr_dst[len(text)] = 0
	
	win32.SetClipboardData(win32.CF_TEXT, win32.HANDLE(h_mem))
	return true
}


@(test)
verify_win32_clipboard :: proc(t: ^testing.T) {
	ok1 := write_to_clipboard(nil, "Hello everynyan! OH MY GAH")
	testing.expect_value(t, ok1, true)
	
	clipboard_content, ok2 := read_from_clipboard(nil, context.temp_allocator)
	testing.expect_value(t, ok2, true)
	testing.expect_value(t, clipboard_content, "Hello everynyan! OH MY GAH")
}
