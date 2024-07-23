//+private
package os2

import "core:sys/linux"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	fds: [2]linux.Fd
	errno := linux.pipe2(&fds, {.CLOEXEC})
	if errno != .NONE {
		return nil, nil,_get_platform_error(errno)
	}

	r = _new_file(uintptr(fds[0]))
	w = _new_file(uintptr(fds[1]))

	r_impl := (^File_Impl)(r.impl)
	r_impl.kind = .Pipe
	w_impl := (^File_Impl)(w.impl)
	w_impl.kind = .Pipe

	return
}
