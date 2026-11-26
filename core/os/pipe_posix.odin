#+private
#+build darwin, netbsd, freebsd, openbsd
package os

import "core:sys/posix"
import "core:strings"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	fds: [2]posix.FD
	if posix.pipe(&fds) != .OK {
		err = _get_platform_error()
		return
	}
	if posix.fcntl(fds[0], .SETFD, i32(posix.FD_CLOEXEC)) == -1 {
		err = _get_platform_error()
		posix.close(fds[0])
		posix.close(fds[1])
		return
	}
	if posix.fcntl(fds[1], .SETFD, i32(posix.FD_CLOEXEC)) == -1 {
		err = _get_platform_error()
		posix.close(fds[0])
		posix.close(fds[1])
		return
	}

	rf, r_err := _pipe_new_file(fds[0])
	if r_err != nil {
		posix.close(fds[0])
		posix.close(fds[1])
		return nil, nil, r_err
	}
	wf, w_err := _pipe_new_file(fds[1])
	if w_err != nil {
		close(rf)
		posix.close(fds[1])
		return nil, nil, w_err
	}
	return rf, wf, nil
}

@(private="file")
_pipe_new_file :: proc(fd: posix.FD) -> (f: ^File, err: Error) {
	name := strings.builder_make(file_allocator()) or_return
	defer if err != nil { strings.builder_destroy(&name) }

	// TODO(laytan): is this on all the posix targets?
	strings.write_string(&name, "/dev/fd/") or_return
	strings.write_int(&name, int(fd)) or_return
	cname := strings.to_cstring(&name) or_return

	f = __new_file(fd, file_allocator()) or_return
	impl := (^File_Impl)(f.impl)
	impl.name  = strings.to_string(name)
	impl.cname = cname
	return
}

@(require_results)
_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	if r == nil || r.impl == nil {
		return false, nil
	}
	fd := __fd(r)
	poll_fds := []posix.pollfd {
		posix.pollfd {
			fd = fd,
			events = {.IN, .HUP},
		},
	}
	n := posix.poll(raw_data(poll_fds), u32(len(poll_fds)), 0)
	for n < 0 && posix.errno() == .EINTR {
		n = posix.poll(raw_data(poll_fds), u32(len(poll_fds)), 0)
	}
	if n < 0 {
		return false, _get_platform_error()
	} else if n != 1 {
		return false, nil
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
