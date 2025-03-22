#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:time"
import "core:strings"

import kq "core:sys/kqueue"
import    "core:sys/posix"

_exit :: proc "contextless" (code: int) -> ! {
	posix.exit(i32(code))
}

_get_uid :: proc() -> int {
	return int(posix.getuid())
}

_get_euid :: proc() -> int {
	return int(posix.geteuid())
}

_get_gid :: proc() -> int {
	return int(posix.getgid())
}

_get_egid :: proc() -> int {
	return int(posix.getegid())
}

_get_pid :: proc() -> int {
	return int(posix.getpid())
}

_get_ppid :: proc() -> int {
	return int(posix.getppid())
}

_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(process.pid, selection, allocator)
}

_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(_get_pid(), selection, allocator)
}

_Sys_Process_Attributes :: struct {}

_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	if len(desc.command) == 0 {
		err = .Invalid_Path
		return
	}

	TEMP_ALLOCATOR_GUARD()

	// search PATH if just a plain name is provided.
	exe_builder := strings.builder_make(temp_allocator())
	exe_name    := desc.command[0]
	if strings.index_byte(exe_name, '/') < 0 {
		path_env  := get_env("PATH", temp_allocator())
		path_dirs := split_path_list(path_env, temp_allocator()) or_return

		found: bool
		for dir in path_dirs {
			strings.builder_reset(&exe_builder)
			strings.write_string(&exe_builder, dir)
			strings.write_byte(&exe_builder, '/')
			strings.write_string(&exe_builder, exe_name)

			if exe_fd := posix.open(strings.to_cstring(&exe_builder) or_return, {.CLOEXEC, .EXEC}); exe_fd == -1 {
				continue
			} else {
				posix.close(exe_fd)
				found = true
				break
			}
		}
		if !found {
			// check in cwd to match windows behavior
			strings.builder_reset(&exe_builder)
			strings.write_string(&exe_builder, desc.working_dir)
			if len(desc.working_dir) > 0 && desc.working_dir[len(desc.working_dir)-1] != '/' {
			strings.write_byte(&exe_builder, '/')
			}
			strings.write_string(&exe_builder, "./")
			strings.write_string(&exe_builder, exe_name)

			// "hello/./world" is fine right?

			if exe_fd := posix.open(strings.to_cstring(&exe_builder) or_return, {.CLOEXEC, .EXEC}); exe_fd == -1 {
				err = .Not_Exist
				return
			} else {
				posix.close(exe_fd)
			}
		}
	} else {
		strings.builder_reset(&exe_builder)
		strings.write_string(&exe_builder, exe_name)

		if exe_fd := posix.open(strings.to_cstring(&exe_builder) or_return, {.CLOEXEC, .EXEC}); exe_fd == -1 {
			err = .Not_Exist
			return
		} else {
			posix.close(exe_fd)
		}
	}

	cwd: cstring; if desc.working_dir != "" {
		cwd = temp_cstring(desc.working_dir)
	}

	cmd := make([]cstring, len(desc.command) + 1, temp_allocator())
	for part, i in desc.command {
		cmd[i] = temp_cstring(part)
	}

	env: [^]cstring
	if desc.env == nil {
		// take this process's current environment
		env = posix.environ
	} else {
		cenv := make([]cstring, len(desc.env) + 1, temp_allocator())
		for env, i in desc.env {
			cenv[i] = temp_cstring(env)
		}
		env = raw_data(cenv)
	}

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

	switch pid := posix.fork(); pid {
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

		res := posix.execve(strings.to_cstring(&exe_builder) or_return, raw_data(cmd), env)
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
				wpid := posix.waitid(.P_PID, posix.id_t(process.pid), &info, {.EXITED})
				if wpid == -1 && posix.errno() == .EINTR {
					continue
				}
				break
			}

			err = errno
			return
		}

		process, _ = _process_open(int(pid), {})
		return
	}
}

_process_wait :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	process_state.pid = process.pid

	_process_handle_still_valid(process) or_return

	// timeout >  0 = use kqueue to wait (with a timeout) on process exit
	// timeout == 0 = use waitid with WNOHANG so it returns immediately
	// timeout >  0 = use waitid without WNOHANG so it waits indefinitely
	//
	// at the end use waitid to actually reap the process and get it's status

	if timeout > 0 {
		timeout := timeout

		queue := kq.kqueue() or_return
		defer posix.close(queue)

		changelist, eventlist: [1]kq.KEvent

		changelist[0] = {
			ident  = uintptr(process.pid),
			filter = .Proc,
			flags  = { .Add },
			fflags = {
				fproc = { .Exit },
			},
		}

		for {
			start := time.tick_now()
			n, kerr := kq.kevent(queue, changelist[:], eventlist[:], &{
				tv_sec  = posix.time_t(timeout / time.Second),
				tv_nsec = i64(timeout % time.Second),
			})
			if kerr == .EINTR {
				timeout -= time.tick_since(start)
				continue
			} else if kerr != nil {
				err = kerr
				return
			} else if n == 0 {
				err = .Timeout
				_process_state_update_times(process, &process_state)
				return
			} else {
				_process_state_update_times(process, &process_state)
				break
			}
		}
	} else {
		flags := posix.Wait_Flags{.EXITED, .NOWAIT}
		if timeout == 0 {
			flags += {.NOHANG}
		}

		info: posix.siginfo_t
		for {
			wpid := posix.waitid(.P_PID, posix.id_t(process.pid), &info, flags)
			if wpid == -1 {
				if errno := posix.errno(); errno == .EINTR {
					continue
				} else {
					err = _get_platform_error()
					return
				}
			}
			break
		}

		_process_state_update_times(process, &process_state)

		if info.si_signo == nil {
			assert(timeout == 0)
			err = .Timeout
			return
		}
	}

	info: posix.siginfo_t
	for {
		wpid := posix.waitid(.P_PID, posix.id_t(process.pid), &info, {.EXITED})
		if wpid == -1 {
			if errno := posix.errno(); errno == .EINTR {
				continue
			} else {
				err = _get_platform_error()
				return
			}
		}
		break
	}

	switch info.si_code.chld {
	case:                      unreachable()
	case .CONTINUED, .STOPPED: unreachable()
	case .EXITED:
		process_state.exited    = true
		process_state.exit_code = int(info.si_status)
		process_state.success   = process_state.exit_code == 0
	case .KILLED, .DUMPED, .TRAPPED:
		process_state.exited    = true
		process_state.exit_code = int(info.si_status)
		process_state.success   = false
	}

	return
}

_process_close :: proc(process: Process) -> Error {
	return nil
}

_process_kill :: proc(process: Process) -> (err: Error) {
	_process_handle_still_valid(process) or_return

	if posix.kill(posix.pid_t(process.pid), .SIGKILL) != .OK {
		err = _get_platform_error()
	}

	return
}
