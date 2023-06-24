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

_get_platform_error :: proc() -> Error {
	err := win32.GetLastError()
	if err == 0 {
		return nil
	}
	switch err {
	case win32.ERROR_ACCESS_DENIED, win32.ERROR_SHARING_VIOLATION:
		return .Permission_Denied

	case win32.ERROR_FILE_EXISTS, win32.ERROR_ALREADY_EXISTS:
		return .Exist

	case win32.ERROR_FILE_NOT_FOUND, win32.ERROR_PATH_NOT_FOUND:
		return .Not_Exist

	case win32.ERROR_NO_DATA:
		return .Closed

	case win32.ERROR_TIMEOUT, win32.WAIT_TIMEOUT:
		return .Timeout

	case win32.ERROR_NOT_SUPPORTED:
		return .Unsupported

	case win32.ERROR_HANDLE_EOF:
		return .EOF

	case win32.ERROR_INVALID_HANDLE:
		return .Invalid_File

	case
		win32.ERROR_BAD_ARGUMENTS,
		win32.ERROR_INVALID_PARAMETER,
		win32.ERROR_NOT_ENOUGH_MEMORY,
		win32.ERROR_NO_MORE_FILES,
		win32.ERROR_LOCK_VIOLATION,
		win32.ERROR_BROKEN_PIPE,
		win32.ERROR_CALL_NOT_IMPLEMENTED,
		win32.ERROR_INSUFFICIENT_BUFFER,
		win32.ERROR_INVALID_NAME,
		win32.ERROR_LOCK_FAILED,
		win32.ERROR_ENVVAR_NOT_FOUND,
		win32.ERROR_OPERATION_ABORTED,
		win32.ERROR_IO_PENDING,
		win32.ERROR_NO_UNICODE_TRANSLATION:
		// fallthrough
	}
	return Platform_Error(err)
}