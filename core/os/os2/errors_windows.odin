//+private
package os2

import win32 "core:sys/windows"

_error_string :: proc(errno: i32) -> string {
	e := win32.DWORD(errno)
	if e == 0 {
		return ""
	}
	// TODO(bill): _error_string for windows
	// FormatMessageW
	return ""
}
