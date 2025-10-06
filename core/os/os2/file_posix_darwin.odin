#+private
package os2

import "base:runtime"

import "core:sys/darwin"
import "core:sys/posix"

_posix_absolute_path :: proc(fd: posix.FD, name: string, allocator: runtime.Allocator) -> (path: cstring, err: Error) {
	F_GETPATH :: 50

	buf: [posix.PATH_MAX]byte
	if posix.fcntl(fd, posix.FCNTL_Cmd(F_GETPATH), &buf) != 0 {
		err = _get_platform_error()
		return
	}

	return clone_to_cstring(string(cstring(&buf[0])), allocator)
}

_copy_file_native :: proc(dst_path, src_path: string) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	csrc := clone_to_cstring(src_path, temp_allocator) or_return
	cdst := clone_to_cstring(dst_path, temp_allocator) or_return

	// Disallow directories, as specified by the generic implementation.

	stat: posix.stat_t
	if posix.stat(csrc, &stat) != .OK {
		err = _get_platform_error()
		return
	}

	if posix.S_ISDIR(stat.st_mode) {
		err = .Invalid_File
		return
	}

	ret := darwin.copyfile(csrc, cdst, nil, darwin.COPYFILE_ALL)
	if ret < 0 {
		err = _get_platform_error()
	}

	return
}
