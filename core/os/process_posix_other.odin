#+private
#+build netbsd, openbsd, freebsd
package os

import "base:runtime"

import "core:sys/posix"

_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	err = .Unsupported
	return
}

_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	err = .Unsupported
	return
}

_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	process.pid = pid
	err = .Unsupported
	return
}

_process_handle_still_valid :: proc(p: Process) -> Error {
	return nil
}

_process_state_update_times :: proc(p: Process, state: ^Process_State) {
	return
}

_process_spawn :: proc(desc: Process_Desc, exe: cstring, argv, envp: [^]cstring, cwd: cstring) -> (pid: posix.pid_t, err: Error) {
	READ  :: 0
	WRITE :: 1

	pipe: [2]posix.FD
	if posix.pipe(&pipe) != .OK {
		err = _get_platform_error()
		return
	}
	defer posix.close(pipe[READ])

	if posix.fcntl(pipe[READ], .SETFD, i32(posix.FD_CLOEXEC)) == -1 {
		posix.close(pipe[WRITE])
		err = _get_platform_error()
		return
	}
	if posix.fcntl(pipe[WRITE], .SETFD, i32(posix.FD_CLOEXEC)) == -1 {
		posix.close(pipe[WRITE])
		err = _get_platform_error()
		return
	}

	pid = posix.fork()
	switch pid {
	case -1:
		posix.close(pipe[WRITE])
		err = _get_platform_error()
		return

	case 0:
		abort :: proc(parent_fd: posix.FD) -> ! {
			#assert(len(posix.Errno) < max(u8))
			errno := u8(posix.errno())
			posix.write(parent_fd, &errno, 1)
			posix.exit(126)
		}

		null := posix.open("/dev/null", {.RDWR})
		if null == -1 { abort(pipe[WRITE]) }

		stderr := (^File_Impl)(desc.stderr.impl).fd if desc.stderr != nil else null
		stdout := (^File_Impl)(desc.stdout.impl).fd if desc.stdout != nil else null
		stdin  := (^File_Impl)(desc.stdin.impl).fd  if desc.stdin  != nil else null

		if posix.dup2(stderr, posix.STDERR_FILENO) == -1 { abort(pipe[WRITE]) }
		if posix.dup2(stdout, posix.STDOUT_FILENO) == -1 { abort(pipe[WRITE]) }
		if posix.dup2(stdin,  posix.STDIN_FILENO ) == -1 { abort(pipe[WRITE]) }

		if cwd != nil {
			if posix.chdir(cwd) != .OK { abort(pipe[WRITE]) }
		}

		res := posix.execve(exe, argv, envp)
		assert(res == -1)
		abort(pipe[WRITE])

	case:
		posix.close(pipe[WRITE])

		errno: posix.Errno
		for {
			errno_byte: u8
			switch posix.read(pipe[READ], &errno_byte, 1) {
			case  1:
				errno = posix.Errno(errno_byte)
			case -1:
				errno = posix.errno()
				if errno == .EINTR {
					continue
				} else {
					// If the read failed, something weird happened. Do not return the read
					// error so the user knows to wait on it.
					errno = nil
				}
			}
			break
		}

		if errno != nil {
			// We can assume it trapped here.

			for {
				info: posix.siginfo_t
				wpid := posix.waitid(.P_PID, posix.id_t(pid), &info, {.EXITED})
				if wpid == -1 && posix.errno() == .EINTR {
					continue
				}
				break
			}

			return 0, errno
		}

		return pid, nil
	}
}
