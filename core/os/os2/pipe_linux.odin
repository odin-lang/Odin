//+private
package os2

import "core:sys/linux"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	fds: [2]linux.Fd
	errno := linux.pipe2(&fds, {.CLOEXEC})
	if errno != .NONE {
		return nil, nil,_get_platform_error(errno)
	}

	r = _new_file(uintptr(fds[0])) or_return
	w = _new_file(uintptr(fds[1])) or_return

	return
}
