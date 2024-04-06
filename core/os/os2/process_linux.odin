//+private
package os2

import "base:runtime"

import "core:fmt"
import "core:mem"
import "core:time"
import "core:strings"
import "core:strconv"
import "core:sys/linux"
import "core:path/filepath"

_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__), heap_allocator())
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}

_exit :: proc "contextless" (code: int) -> ! {
	linux.exit_group(i32(code))
}

_get_uid :: proc() -> int {
	return int(linux.getuid())
}

_get_euid :: proc() -> int {
	return int(linux.geteuid())
}

_get_gid :: proc() -> int {
	return int(linux.getgid())
}

_get_egid :: proc() -> int {
	return int(linux.getegid())
}

_get_pid :: proc() -> int {
	return int(linux.getpid())
}

_get_ppid :: proc() -> int {
	return int(linux.getppid())
}

Process_Attributes_OS_Specific :: struct {}

_process_find :: proc(pid: int) -> (Process, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	pid_path := fmt.ctprintf("/proc/%d", pid)

	p: Process
	dir_fd: linux.Fd
	errno: linux.Errno

	#partial switch dir_fd, errno = linux.open(pid_path, _OPENDIR_FLAGS); errno {
	case .NONE:
		linux.close(dir_fd)
		p.pid = pid
		return p, nil
	case .ENOTDIR:
		return p, .Invalid_Dir
	case .ENOENT:
		return p, .Not_Exist
	}
	return p, _get_platform_error(errno)
}

_process_get_state :: proc(p: Process) -> (state: Process_State, err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	stat_name := fmt.ctprintf("/proc/%d/stat", p.pid)
	stat_buf: []u8
	stat_buf, err = _read_entire_pseudo_file(stat_name, context.temp_allocator)

	if err != nil {
		return
	}

	idx := strings.last_index_byte(string(stat_buf), ')')
	stats := string(stat_buf[idx + 2:])

	// utime and stime are the 12 and 13th items, respectively
	// skip the first 11 items here.
	for i := 0; i < 11; i += 1 {
		stats = stats[strings.index_byte(stats, ' ') + 1:]
	}

	idx = strings.index_byte(stats, ' ')
	utime_str := stats[:idx]

	stats = stats[idx + 1:]
	stime_str := stats[:strings.index_byte(stats, ' ')]

	utime, _ := strconv.parse_int(utime_str, 10)
	stime, _ := strconv.parse_int(stime_str, 10)

	// NOTE: Assuming HZ of 100, 1 jiffy == 10 ms
	state.user_time = time.Duration(utime) * 10 * time.Millisecond
	state.system_time = time.Duration(stime) * 10 * time.Millisecond

	return
}

_process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (Process, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	child: Process

	dir_fd : linux.Fd = -100
	errno: linux.Errno
	if attr != nil && attr.dir != "" {
		if dir_fd, errno = linux.open("/", _OPENDIR_FLAGS); errno != .NONE {
			return child, _get_platform_error(errno)
		}
	}

	// search PATH if just a plain name is provided
	executable: cstring
	if !strings.contains_rune(name, '/') {
		path_env := get_env("PATH", context.temp_allocator)
		path_dirs := filepath.split_list(path_env, context.temp_allocator)
		found: bool
		for dir in path_dirs {
			executable = fmt.ctprintf("%s/%s", dir, name)
			if not_found, errno := linux.faccessat(dir_fd, executable, linux.F_OK); errno == .NONE && !not_found {
				found = true
				break
			}
		}
		if !found {
			// check in dir to match windows behavior
			executable = fmt.ctprintf("./%s", name)
			if not_found, errno := linux.faccessat(dir_fd, executable, linux.F_OK); errno != .NONE || not_found {
				return child, .Not_Exist
			}
		}
	} else {
		executable = strings.clone_to_cstring(name, context.temp_allocator)
	}

	not_exec: bool
	if not_exec, errno = linux.faccessat(dir_fd, executable, linux.F_OK | linux.X_OK); errno != .NONE || not_exec {
		return child, errno == .NONE ? .Permission_Denied : _get_platform_error(errno)
	}

	// args and environment need to be a list of cstrings
	// that are terminated by a nil pointer.
	// The first argument is a copy of the executable name.
	cargs := make([]cstring, len(argv) + 2, context.temp_allocator)
	cargs[0] = executable
	for i := 0; i < len(argv); i += 1 {
		cargs[i + 1] = strings.clone_to_cstring(argv[i], context.temp_allocator)
	}

	// Use current process's environment if attributes not provided
	env: [^]cstring
	if attr == nil {
		// take this process's current environment
		env = raw_data(export_cstring_environment(context.temp_allocator))
	} else {
		cenv := make([]cstring, len(attr.env) + 1, context.temp_allocator)
		for i := 0; i < len(argv); i += 1 {
			cenv[i] = strings.clone_to_cstring(attr.env[i], context.temp_allocator)
		}
		env = &cenv[0]
	}

	// TODO: This is the traditional textbook implementation with fork.
	//       A more efficient implementation with vfork:
	//
	//       1. retrieve signal handlers
	//       2. block all signals
	//       3. allocate some stack space
	//       4. vfork (waits for child exit or execve); In child:
	//           a. set child signal handlers
	//           b. set up any necessary pipes
	//           c. execve
	//       5. restore signal handlers
	//
	stdin_fds: [2]linux.Fd
	stdout_fds: [2]linux.Fd
	stderr_fds: [2]linux.Fd
	if attr != nil && attr.stdin != nil {
		if errno := linux.pipe2(&stdin_fds, nil); errno != .NONE {
			return child, _get_platform_error(errno)
		}
	}
	if attr != nil && attr.stdout != nil {
		if errno := linux.pipe2(&stdout_fds, nil); errno != .NONE {
			return child, _get_platform_error(errno)
		}
	}
	if attr != nil && attr.stderr != nil {
		if errno := linux.pipe2(&stderr_fds, nil); errno != .NONE {
			return child, _get_platform_error(errno)
		}
	}

	pid: linux.Pid
	if pid, errno = linux.fork(); errno != .NONE {
		return child, _get_platform_error(errno)
	}

	if pid == 0 {
		// in child process now
		if attr != nil && attr.stdin != nil {
			if linux.close(stdin_fds[1]) != .NONE { linux.exit(1) }
			if _, errno := linux.dup2(stdin_fds[0], 0); errno != .NONE { linux.exit(1) }
			if linux.close(stdin_fds[0]) != .NONE { linux.exit(1) }
		}
		if attr != nil && attr.stdout != nil {
			if linux.close(stdout_fds[0]) != .NONE { linux.exit(1) }
			if _, errno := linux.dup2(stdout_fds[1], 1); errno != .NONE { linux.exit(1) }
			if linux.close(stdout_fds[1]) != .NONE { linux.exit(1) }
		}
		if attr != nil && attr.stderr != nil {
			if linux.close(stderr_fds[0]) != .NONE { linux.exit(1) }
			if _, errno := linux.dup2(stderr_fds[1], 2); errno != .NONE { linux.exit(1) }
			if linux.close(stderr_fds[1]) != .NONE { linux.exit(1) }
		}

		// TODO: missing flags parameter?
		if errno = linux.execveat(dir_fd, executable, &cargs[0], env); errno != .NONE {
			print_error(_get_platform_error(errno), string(executable))
			panic("execve failed to replace process")
		}
		unreachable()
	}

	// in parent process
	if attr != nil && attr.stdin != nil {
		linux.close(stdin_fds[0])
		_construct_file(attr.stdin, uintptr(stdin_fds[1]))
	}
	if attr != nil && attr.stdout != nil {
		linux.close(stdout_fds[1])
		_construct_file(attr.stdout, uintptr(stdout_fds[0]))
	}
	if attr != nil && attr.stderr != nil {
		linux.close(stderr_fds[1])
		_construct_file(attr.stderr, uintptr(stderr_fds[0]))
	}

	child.pid = int(pid)
	return child, nil
}

_process_release :: proc(p: ^Process) -> Error {
	// TODO
	return nil
}

_process_kill :: proc(p: ^Process) -> Error {
	res := linux.kill(linux.Pid(p.pid), .SIGKILL)
	return _get_platform_error(res)
}

_process_signal :: proc(sig: Signal, h: Signal_Handler) -> Error {
	signo: linux.Signal
	switch sig {
	case .Abort:                    signo = .SIGABRT
	case .Floating_Point_Exception: signo = .SIGFPE
	case .Illegal_Instruction:      signo = .SIGILL
	case .Interrupt:                signo = .SIGINT
	case .Segmentation_Fault:       signo = .SIGSEGV
	case .Termination:              signo = .SIGTERM
	}

	// TODO: some things missing from linux.Sig_Action
	sigact: linux.Sig_Action(int)
	old: ^linux.Sig_Action(int) = nil

	switch v in h {
	case Signal_Handler_Special:
		unimplemented("Need special handlers implemented")
		//switch v {
		//case .Default:
		//	sigact.special = .SIG_DFL
		//case .Ignore:
		//	sigact.special = .SIG_IGN
		//}
	case Signal_Handler_Proc:
		sigact.handler = (linux.Sig_Handler_Fn)(v)
	}

	return _get_platform_error(linux.rt_sigaction(signo, &sigact, old))
}

_process_wait :: proc(p: ^Process, t: time.Duration) -> (state: Process_State, err: Error) {
	state.pid = p.pid

	options: linux.Wait_Options
	big_if: if t == 0 {
		options += {.WNOHANG}
	} else if t != time.MAX_DURATION {
		ts: linux.Time_Spec= {
			time_sec = uint(t / time.Second),
			time_nsec = uint(t % time.Second),
		}

		@static has_pidfd_open: bool = true

		// pidfd_open is fairly new, so don't error out on ENOSYS
		pid_fd: linux.Pid_FD
		errno: linux.Errno
		if has_pidfd_open {
			pid_fd, errno = linux.pidfd_open(linux.Pid(p.pid), nil)
			if errno != .NONE && errno != .ENOSYS {
				return state, _get_platform_error(errno)
			}
		}

		if has_pidfd_open && errno != .ENOSYS {
			defer linux.close(linux.Fd(pid_fd))
			pollfd: [1]linux.Poll_Fd = {
				{
					fd = linux.Fd(pid_fd),
					events = {.IN},
				},
			}
			for {
				errno := linux.ppoll(pollfd[:], &ts, nil)
				if errno == .EINTR {
					continue
				}
				if errno != .NONE {
					return state, _get_platform_error(errno)
				}
				else {
					return _process_get_state(p^)
				}
				break
			}
		} else {
			has_pidfd_open = false
			mask: bit_set[0..=63]
			mask += { int(linux.Signal.SIGCHLD) - 1 }

			// TODO: fix linux.Sig_Set
			org_sigset: linux.Sig_Set
			sigset: linux.Sig_Set
			mem.copy(&sigset, &mask, size_of(mask))
			errno := linux.rt_sigprocmask(.SIG_BLOCK, &sigset, &org_sigset)
			if errno != .NONE {
				return state, _get_platform_error(errno)
			}
			defer linux.rt_sigprocmask(.SIG_SETMASK, &org_sigset, nil)

			// In case there was a signal handler on SIGCHLD, avoid race
			// condition by checking wait first.
			options += {.WNOHANG}
			waitid_options := options + {.WNOWAIT, .WEXITED}
			info: linux.Sig_Info
			errno = linux.waitid(.PID, linux.Id(p.pid), &info, waitid_options, nil)
			if errno == .NONE && info.code != 0 {
				break big_if
			}

			loop: for {
				sigset: linux.Sig_Set
				mem.copy(&sigset, &mask, size_of(mask))

				_, errno = linux.rt_sigtimedwait(&sigset, &info, &ts)
				#partial switch errno {
				case .EAGAIN: // timeout
					return _process_get_state(p^)
				case .EINVAL:
					return state, _get_platform_error(errno)
				case .EINTR:
					continue
				case:
					if int(info.pid) == p.pid {
						break loop
					}
				}
			}
		}
	}

	state = _process_get_state(p^) or_return

	status: u32
	errno: linux.Errno
	for {
		_, errno = linux.wait4(linux.Pid(p.pid), &status, options, nil)
		if errno == .EINTR {
			continue
		}
		if errno != .NONE {
			return state, _get_platform_error(errno)
		}
		break
	}

	if errno == .NONE {
		return _process_get_state(p^)
	}

	state.exited = true
	p.is_done = true

	// normal exit
	if signo := status & 0x7f; signo == 0 {
		state.exit_code = int((status >> 8) & 0xff)
		state.success = state.exit_code == 0
	}

	// signaled
	if (status & 0xffff) - 1 < 0xff {
		// NOTE: for now, success = false and exit_code = 0
	}

	return
}
