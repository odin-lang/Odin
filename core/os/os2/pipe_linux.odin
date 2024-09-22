#+private
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

@(require_results)
_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	if r == nil || r.impl == nil {
		return false, nil
	}
	fd := linux.Fd((^File_Impl)(r.impl).fd)
	poll_fds := []linux.Poll_Fd {
		linux.Poll_Fd {
			fd = fd,
			events = {.IN, .HUP},
		},
	}
	n, errno := linux.poll(poll_fds, 0)
	if n != 1 || errno != nil {
		return false, _get_platform_error(errno)
	}
	pipe_events := poll_fds[0].revents
	if pipe_events >= {.IN} {
		return true, nil
	}
	if pipe_events >= {.HUP} {
		return false, .Broken_Pipe
	}
	return false, nil
}