#+private
#+build openbsd
package os2

import "base:runtime"

import "core:sys/posix"

_posix_absolute_path :: proc(fd: posix.FD, name: string, allocator: runtime.Allocator) -> (path: cstring, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	cname := clone_to_cstring(name, temp_allocator)

	buf: [posix.PATH_MAX]byte
	path = posix.realpath(cname, raw_data(buf[:]))
	if path == nil {
		err = _get_platform_error()
		return
	}

	return clone_to_cstring(string(path), allocator)
}
