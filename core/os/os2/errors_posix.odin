//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "core:sys/posix"

_Platform_Error :: posix.Errno

_error_string :: proc(errno: i32) -> string {
	return string(posix.strerror(posix.Errno(errno)))
}

_get_platform_error :: proc() -> Error {
	#partial switch errno := posix.errno(); errno {
	case .EPERM:
		return .Permission_Denied
	case .EEXIST:
		return .Exist
	case .ENOENT:
		return .Not_Exist
	case .ETIMEDOUT:
		return .Timeout
	case .EPIPE:
		return .Broken_Pipe
	case .EBADF:
		return .Invalid_File
	case .ENOMEM:
		return .Out_Of_Memory
	case:
		return Platform_Error(errno)
	}
}
