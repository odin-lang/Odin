#+private
package archive

import "base:runtime"
import "core:io"
import "core:os"
import "core:strings"
import win32 "core:sys/windows"

_os_lock_open :: proc(path: string, kind: Lock_Kind, create: bool, allocator: runtime.Allocator) -> (f: ^os.File, err: Error) {
	wide := _wide_path(path, allocator) or_return
	defer free(rawptr(wide), allocator)
	access      := win32.GENERIC_READ
	share       := win32.FILE_SHARE_READ
	disposition := win32.OPEN_EXISTING
	if kind == .Exclusive {
		access |= win32.GENERIC_WRITE
		share   = 0
		if create {
			disposition = win32.OPEN_ALWAYS
		}
	}
	h := win32.CreateFileW(wide, access, share, nil, disposition, win32.FILE_ATTRIBUTE_NORMAL, nil)
	if h == win32.INVALID_HANDLE_VALUE {
		return nil, _windows_error(win32.GetLastError())
	}
	f = os.new_file(uintptr(h), path)
	if f == nil {
		win32.CloseHandle(h)
		return nil, runtime.Allocator_Error.Out_Of_Memory
	}
	return f, nil
}

_replace :: proc(from, to: string, write_through: bool, allocator: runtime.Allocator) -> (err: Error) {
	wide_from := _wide_path(from, allocator) or_return
	defer free(rawptr(wide_from), allocator)
	wide_to := _wide_path(to, allocator) or_return
	defer free(rawptr(wide_to), allocator)
	flags := win32.DWORD(win32.MOVEFILE_REPLACE_EXISTING)
	if write_through {
		flags |= win32.MOVEFILE_WRITE_THROUGH
	}
	if !win32.MoveFileExW(wide_from, wide_to, flags) {
		return _windows_error(win32.GetLastError())
	}
	return nil
}

_wide_path :: proc(path: string, allocator: runtime.Allocator) -> (wide: win32.wstring, err: Error) {
	full, full_err := os.get_absolute_path(path, allocator)
	if full_err != nil {
		return nil, full_err
	}
	defer delete(full, allocator)
	b := strings.builder_make(0, len(full) + 8, allocator) or_return
	defer strings.builder_destroy(&b)
	separator :: proc(c: u8) -> bool {
		return c == '\\' || c == '/'
	}
	switch {
	case len(full) < 248:
		strings.write_string(&b, full)
	case len(full) >= 4 && separator(full[0]) && separator(full[1]) && (full[2] == '?' || full[2] == '.') && separator(full[3]):
		strings.write_string(&b, full)
	case len(full) >= 2 && separator(full[0]) && separator(full[1]):
		strings.write_string(&b, `\\?\UNC\`)
		strings.write_string(&b, full[2:])
	case:
		strings.write_string(&b, `\\?\`)
		strings.write_string(&b, full)
	}
	buf := b.buf[:]
	for &c in buf {
		if c == '/' {
			c = '\\'
		}
	}
	wide = win32.utf8_to_wstring(string(buf), allocator)
	if wide == nil {
		return nil, runtime.Allocator_Error.Out_Of_Memory
	}
	return wide, nil
}

_windows_error :: proc(code: win32.DWORD) -> Error {
	switch code {
	case win32.ERROR_SHARING_VIOLATION, win32.ERROR_LOCK_VIOLATION:
		return General_Error.Busy
	case win32.ERROR_FILE_NOT_FOUND, win32.ERROR_PATH_NOT_FOUND:
		return os.Error(os.General_Error.Not_Exist)
	case win32.ERROR_ACCESS_DENIED:
		return os.Error(io.Error.Permission_Denied)
	case win32.ERROR_FILE_EXISTS, win32.ERROR_ALREADY_EXISTS:
		return os.Error(os.General_Error.Exist)
	}
	return os.Error(os.Platform_Error(code))
}
