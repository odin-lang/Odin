package os2

import "base:runtime"

import "core:sys/freebsd"
import "core:sys/posix"

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	req := []freebsd.MIB_Identifier{.CTL_KERN, .KERN_PROC, .KERN_PROC_PATHNAME, freebsd.MIB_Identifier(-1)}

	size: uint
	if ret := freebsd.sysctl(req, nil, &size, nil, 0); ret != .NONE {
		err = _get_platform_error(posix.Errno(ret))
		return
	}
	assert(size > 0)

	buf := make([]byte, size, allocator) or_return
	defer if err != nil { delete(buf, allocator) }

	assert(uint(len(buf)) == size)

	if ret := freebsd.sysctl(req, raw_data(buf), &size, nil, 0); ret != .NONE {
		err = _get_platform_error(posix.Errno(ret))
		return
	}

	return string(buf[:size-1]), nil
}
