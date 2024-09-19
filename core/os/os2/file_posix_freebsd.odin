#+private
package os2

import "base:runtime"

import "core:c"
import "core:sys/posix"

_posix_absolute_path :: proc(fd: posix.FD, name: string, allocator: runtime.Allocator) -> (path: cstring, err: Error) {
	// NOTE(Feoramund): The situation isn't ideal, but this was the best way I
	// could find to implement this. There are a couple outstanding bug reports
	// regarding the desire to retrieve an absolute path from a handle, but to
	// my knowledge, there hasn't been any work done on it.
	//
	// https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=198570
	//
	// This may be unreliable, according to a comment from 2023.

	KInfo_File :: struct {
		structsize: c.int,
		type:       c.int,
		fd:         c.int,
		ref_count:  c.int,
		flags:      c.int,
		pad0:       c.int,
		offset:     i64,

		// NOTE(Feoramund): This field represents a complicated union that I am
		// avoiding implementing for now. I only need the path data below.
		_union: [336]byte,

		path: [posix.PATH_MAX]c.char,
	}

	F_KINFO :: 22

	kinfo: KInfo_File
	kinfo.structsize = size_of(KInfo_File)

	res := posix.fcntl(fd, posix.FCNTL_Cmd(F_KINFO), &kinfo)
	if res == -1 {
		err = _get_platform_error()
		return
	}

	return clone_to_cstring(string(cstring(&kinfo.path[0])), allocator)
}
