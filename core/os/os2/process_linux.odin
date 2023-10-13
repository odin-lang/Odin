//+private
package os2

import "core:c"
import "core:fmt"
import "core:time"
import "core:runtime"
import "core:strings"
import "core:strconv"
import "core:sys/unix"
import "core:path/filepath"

_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__), heap_allocator())
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}

_exit :: proc "contextless" (code: int) -> ! {
	unix.sys_exit_group(code)
}

_get_uid :: proc() -> int {
	return unix.sys_getuid()
}

_get_euid :: proc() -> int {
	return unix.sys_geteuid()
}

_get_gid :: proc() -> int {
	return unix.sys_getgid()
}

_get_egid :: proc() -> int {
	return unix.sys_getegid()
}

_get_pid :: proc() -> int {
	return unix.sys_getpid()
}

_get_ppid :: proc() -> int {
	return unix.sys_getppid()
}

Process_Attributes_OS_Specific :: struct {}

_process_find :: proc(pid: int) -> (Process, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	pid_path := fmt.ctprintf("/proc/%d", pid)

	p: Process
	dir_fd: int

	switch dir_fd = unix.sys_open(pid_path, _OPENDIR_FLAGS); dir_fd {
	case 0:
		unix.sys_close(dir_fd)
		p.pid = pid
		return p, nil
	case -unix.ENOTDIR:
		return p, .Invalid_Dir
	case -unix.ENOENT:
		return p, .Not_Exist
	}
	return p, _get_platform_error(dir_fd)
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

	// TODO
	//dir_fd := transmute(int)(unix.AT_FDCWD)
	dir_fd := -100
	if attr != nil && attr.dir != "" {
		if dir_fd = unix.sys_open("/", _OPENDIR_FLAGS); dir_fd < 0 {
			return child, _get_platform_error(dir_fd)
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
			if unix.sys_faccessat(dir_fd, executable, unix.F_OK) == 0 {
				found = true
				break
			}
		}
		if !found {
			// check in dir to match windows behavior
			executable = fmt.ctprintf("./%s", name)
			if unix.sys_faccessat(dir_fd, executable, unix.F_OK) != 0 {
				return child, .Not_Exist
			}
		}
	} else {
		executable = strings.clone_to_cstring(name, context.temp_allocator)
	}

	if unix.sys_faccessat(dir_fd, executable, unix.F_OK | unix.X_OK) != 0 {
		return child, .Permission_Denied
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
	stdin_fds: [2]i32
	stdout_fds: [2]i32
	stderr_fds: [2]i32
	if attr != nil && attr.stdin != nil {
		if res := unix.sys_pipe2(&stdin_fds[0], 0); res < 0 {
			return child, _get_platform_error(res)
		}
	}
	if attr != nil && attr.stdout != nil {
		if res := unix.sys_pipe2(&stdout_fds[0], 0); res < 0 {
			return child, _get_platform_error(res)
		}
	}
	if attr != nil && attr.stderr != nil {
		if res := unix.sys_pipe2(&stderr_fds[0], 0); res < 0 {
			return child, _get_platform_error(res)
		}
	}

	res: int
	if res = unix.sys_fork(); res < 0 {
		return child, _get_platform_error(res)
	}

	if res == 0 {
		// in child process now
		if attr != nil && attr.stdin != nil {
			if unix.sys_close(int(stdin_fds[1])) < 0 { unix.sys_exit(1) }
			if unix.sys_dup2(int(stdin_fds[0]), 0) < 0 { unix.sys_exit(1) }
			if unix.sys_close(int(stdin_fds[0])) < 0 { unix.sys_exit(1) }
		}
		if attr != nil && attr.stdout != nil {
			if unix.sys_close(int(stdout_fds[0])) < 0 { unix.sys_exit(1) }
			if unix.sys_dup2(int(stdout_fds[1]), 1) < 0 { unix.sys_exit(1) }
			if unix.sys_close(int(stdout_fds[1])) < 0 { unix.sys_exit(1) }
		}
		if attr != nil && attr.stderr != nil {
			if unix.sys_close(int(stderr_fds[0])) < 0 { unix.sys_exit(1) }
			if unix.sys_dup2(int(stderr_fds[1]), 2) < 0 { unix.sys_exit(1) }
			if unix.sys_close(int(stderr_fds[1])) < 0 { unix.sys_exit(1) }
		}

		if res = unix.sys_execveat(dir_fd, executable, &cargs[0], env, 0); res < 0 {
			print_error(_get_platform_error(res), string(executable))
			panic("sys_execve failed to replace process")
		}
		unreachable()
	}

	// in parent process
	if attr != nil && attr.stdin != nil {
		unix.sys_close(int(stdin_fds[0]))
		_construct_file(attr.stdin, uintptr(stdin_fds[1]))
	}
	if attr != nil && attr.stdout != nil {
		unix.sys_close(int(stdout_fds[1]))
		_construct_file(attr.stdout, uintptr(stdout_fds[0]))
	}
	if attr != nil && attr.stderr != nil {
		unix.sys_close(int(stderr_fds[1]))
		_construct_file(attr.stderr, uintptr(stderr_fds[0]))
	}

	child.pid = res
	return child, nil
}

_process_release :: proc(p: ^Process) -> Error {
	// TODO
	return nil
}

_process_kill :: proc(p: ^Process) -> Error {
	res := unix.sys_kill(p.pid, unix.SIGKILL)
	return _ok_or_error(res)
}

_process_signal :: proc(sig: Signal, h: Signal_Handler) -> Error {
	signo: int
	switch sig {
	case .Abort:                    signo = unix.SIGABRT
	case .Floating_Point_Exception: signo = unix.SIGFPE
	case .Illegal_Instruction:      signo = unix.SIGILL
	case .Interrupt:                signo = unix.SIGINT
	case .Segmentation_Fault:       signo = unix.SIGSEGV
	case .Termination:              signo = unix.SIGTERM
	}

	sigact: unix.Sigaction
	switch v in h {
	case Signal_Handler_Special:
		switch v {
		case .Default:
			sigact.sa_special = unix.SIG_DFL
		case .Ignore:
			sigact.sa_special = unix.SIG_IGN
		}
	case Signal_Handler_Proc:
		sigact.sa_handler = v
	}

	return _ok_or_error(unix.sys_rt_sigaction(signo, &sigact, nil))
}

_process_wait :: proc(p: ^Process, t: time.Duration) -> (state: Process_State, err: Error) {
	state.pid = p.pid

	//options: int = unix.WEXITED
	options: int
	big_if: if t == 0 {
		options |= unix.WNOHANG
	} else if t != time.MAX_DURATION {
		ts: unix.timespec = {
			tv_sec = c.long(t / time.Second),
			tv_nsec = c.long(t % time.Second),
		}

		@static has_pidfd_open: bool = true

		// sys_pidfd_open is fairly new, so don't error out on ENOSYS
		pid_fd: int 
		if has_pidfd_open {
			pid_fd = unix.sys_pidfd_open(p.pid, 0)
			if pid_fd < 0 && pid_fd != -unix.ENOSYS {
				return state, _get_platform_error(pid_fd)
			}
		}

		if has_pidfd_open && pid_fd != -unix.ENOSYS {
			defer unix.sys_close(pid_fd)
			pollfd: unix.Pollfd = {
				fd = i32(pid_fd),
				events = unix.POLLIN,
			}
			for {
				res := unix.sys_ppoll(&pollfd, 1, &ts, nil)
				if res == -unix.EINTR {
					continue
				}
				if res < 0 {
					return state, _get_platform_error(res)
				}
				if res == 0 {
					return _process_get_state(p^)
				}
				break
			}
		} else {
			has_pidfd_open = false
			mask: unix.sigset_t = 1 << (unix.SIGCHLD - 1)
			org_mask : unix.sigset_t
			res := unix.sys_rt_sigprocmask(.SIG_BLOCK, &mask, &org_mask)
			if res < 0 {
				return state, _get_platform_error(res)
			}
			defer unix.sys_rt_sigprocmask(.SIG_SETMASK, &org_mask, nil)

			// In case there was a signal handler on SIGCHLD, avoid race
			// condition by checking wait first.
			options |= unix.WNOHANG
			info: unix.Siginfo
			res = unix.sys_waitid(.P_PID, p.pid, &info, options | unix.WNOWAIT | unix.WEXITED, nil)
			if res == 0 && info.si_code != 0 {
				break big_if
			}

			loop: for {
				switch res = unix.sys_rt_sigtimedwait(&mask, &info, &ts); res {
				case -unix.EAGAIN: // timeout
					return _process_get_state(p^)
				case -unix.EINVAL:
					return state, _get_platform_error(res)
				case -unix.EINTR:
					continue
				case:
					if info.si_pid == i32(p.pid) {
						break loop
					}
				}
			}
		}
	}

	state = _process_get_state(p^) or_return

	status: i32
	res: int
	for {
		res = unix.sys_wait4(p.pid, &status, options, nil)
		if res == -unix.EINTR {
			continue
		}
		if res < 0 {
			return state, _get_platform_error(res)
		}
		break
	}

	if res == 0 {
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
