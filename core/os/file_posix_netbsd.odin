#+private
package os

import "base:runtime"

import "core:sys/posix"

_posix_absolute_path :: proc(fd: posix.FD, name: string, allocator: runtime.Allocator) -> (path: cstring, err: Error) {
	F_GETPATH :: 15

	buf: [posix.PATH_MAX]byte
	if posix.fcntl(fd, posix.FCNTL_Cmd(F_GETPATH), &buf) != 0 || buf[0] == 0 {
		return _posix_absolute_path_from_name(name, allocator)
	}

	return clone_to_cstring(string(cstring(&buf[0])), allocator)
}
