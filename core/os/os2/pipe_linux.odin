//+private
package os2

import "core:sys/unix"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	fds: [2]i32
	res := unix.sys_pipe2(&fds[0], 0)
	if res < 0 {
		return nil, nil,_get_platform_error(res)
	}

	r = _new_file(uintptr(fds[0]))
	w = _new_file(uintptr(fds[1]))
	return
}

