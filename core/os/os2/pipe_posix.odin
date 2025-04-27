#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

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
		return
	}
	if posix.fcntl(fds[1], .SETFD, i32(posix.FD_CLOEXEC)) == -1 {
		err = _get_platform_error()
		return
	}

	r = __new_file(fds[0], file_allocator())
	ri := (^File_Impl)(r.impl)

	rname := strings.builder_make(file_allocator())
	// TODO(laytan): is this on all the posix targets?
	strings.write_string(&rname, "/dev/fd/")
	strings.write_int(&rname, int(fds[0]))
	ri.name  = strings.to_string(rname)
	ri.cname = strings.to_cstring(&rname) or_return

	w = __new_file(fds[1], file_allocator())
	wi := (^File_Impl)(w.impl)
	
	wname := strings.builder_make(file_allocator())
	// TODO(laytan): is this on all the posix targets?
	strings.write_string(&wname, "/dev/fd/")
	strings.write_int(&wname, int(fds[1]))
	wi.name  = strings.to_string(wname)
	wi.cname = strings.to_cstring(&wname) or_return

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
