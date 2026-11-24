#+private
package os

import "core:sys/linux"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	fds: [2]linux.Fd
	errno := linux.pipe2(&fds, {.CLOEXEC})
	if errno != .NONE {
		return nil, nil,_get_platform_error(errno)
	}
	rf, r_err := _new_file(uintptr(fds[0]), "", file_allocator())
	if r_err != nil {
		linux.close(fds[0])
		linux.close(fds[1])
		return nil, nil, r_err
	}
	wf, w_err := _new_file(uintptr(fds[1]), "", file_allocator())
	if w_err != nil {
		close(rf)
		linux.close(fds[1])
		return nil, nil, w_err
	}
	return rf, wf, nil
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