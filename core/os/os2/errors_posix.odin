#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "core:sys/posix"

_Platform_Error :: posix.Errno

_error_string :: proc(errno: i32) -> string {
	return string(posix.strerror(posix.Errno(errno)))
}

_get_platform_error_from_errno :: proc() -> Error {
	return _get_platform_error_existing(posix.errno())
}

_get_platform_error_existing :: proc(errno: posix.Errno) -> Error {
	#partial switch errno {
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
	case .ENOSYS:
		return .Unsupported
	case:
		return Platform_Error(errno)
	}
}

_get_platform_error :: proc{
	_get_platform_error_existing,
	_get_platform_error_from_errno,
}
