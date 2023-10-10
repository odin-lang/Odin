//+private
package os2

import "core:fmt"
import "core:time"
import "core:runtime"
import "core:strings"
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

_process_get_state :: proc(p: Process) -> (Process_State, Error) {
	// TODO
	return Process_State{}, nil
}

_process_start :: proc(name: string, argv: []string, flags: Process_Flags, attr: ^Process_Attributes) -> (Process, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	child: Process

	// Check if pipes are wanted but attr is nil (so no place for pipe ^File)
	if attr == nil && flags & {.Pipe_Stdin, .Pipe_Stdout, .Pipe_Stderr} != nil {
		return child, .Unsupported
	}

	dir_fd := transmute(int)(unix.AT_FDCWD)
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
		for dir in path_dirs {
			executable = fmt.ctprintf("%s/%s", dir, name)
			if unix.sys_faccessat(dir_fd, executable, unix.F_OK) == 0 {
				break
			}
		}

		return child, .Not_Exist
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
	stderr_r, stderr_w: ^File
	if .Pipe_Stdin in flags {
		if res := unix.sys_pipe2(&stdin_fds[0], 0); res < 0 {
			return child, _get_platform_error(res)
		}
	}
	if .Pipe_Stdout in flags {
		if res := unix.sys_pipe2(&stdout_fds[0], 0); res < 0 {
			return child, _get_platform_error(res)
		}
	}
	if .Pipe_Stderr in flags {
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
		if .Pipe_Stdin in flags {
			if unix.sys_close(int(stdin_fds[1])) < 0 { unix.sys_exit(1) }
			if unix.sys_dup2(int(stdin_fds[0]), 0) < 0 { unix.sys_exit(1) }
			if unix.sys_close(int(stdin_fds[0])) < 0 { unix.sys_exit(1) }
		}
		if .Pipe_Stdout in flags {
			if unix.sys_close(int(stdin_fds[0])) < 0 { unix.sys_exit(1) }
			if unix.sys_dup2(int(stdin_fds[1]), 1) < 0 { unix.sys_exit(1) }
			if unix.sys_close(int(stdin_fds[1])) < 0 { unix.sys_exit(1) }
		}
		if .Pipe_Stderr in flags {
			if unix.sys_close(int(stdin_fds[0])) < 0 { unix.sys_exit(1) }
			if unix.sys_dup2(int(stdin_fds[1]), 2) < 0 { unix.sys_exit(1) }
			if unix.sys_close(int(stdin_fds[1])) < 0 { unix.sys_exit(1) }
		}

		if res = unix.sys_execveat(dir_fd, executable, &cargs[0], env, 0); res < 0 {
			print_error(_get_platform_error(res), string(executable))
			panic("sys_execve failed to replace process")
		}
		unreachable()
	}

	// in parent process
	if .Pipe_Stdin in flags {
		unix.sys_close(int(stdin_fds[0]))
		attr.stdin = _new_file(uintptr(stdin_fds[1]))
	}
	if .Pipe_Stdout in flags {
		unix.sys_close(int(stdout_fds[1]))
		attr.stdout = _new_file(uintptr(stdout_fds[0]))
	}
	if .Pipe_Stderr in flags {
		unix.sys_close(int(stderr_fds[1]))
		attr.stderr = _new_file(uintptr(stderr_fds[0]))
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
	case .Abort:                    signo = 1 << unix.SIGABRT
	case .Floating_Point_Exception: signo = 1 << unix.SIGFPE
	case .Illegal_Instruction:      signo = 1 << unix.SIGILL
	case .Interrupt:                signo = 1 << unix.SIGINT
	case .Segmentation_Fault:       signo = 1 << unix.SIGSEGV
	case .Termination:              signo = 1 << unix.SIGTERM
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

_process_wait :: proc(p: ^Process, t: time.Duration) -> (Process_State, Error) {
	state: Process_State = {
		pid = p.pid,
	}

	rusage: unix.Rusage
	status: i32
	res: int

	switch t {
	case time.MAX_DURATION:
		res = unix.sys_wait4(p.pid, &status, unix.WEXITED, &rusage)
	case 0:
		res = unix.sys_wait4(p.pid, &status, unix.WNOHANG | unix.WEXITED, &rusage)
		if res == 0 { // nothing to report
			return state, nil
		}
	case:
		// TODO:
		// unix.sys_pidfd_open
		// if !ENOSYS
		//   unix.sys_poll
		// else
		//   block SIGCHLD
		//   unix.sys_rt_sigtimedwait
		//   unblock SIGCHLD
		unimplemented("timed wait not yet implemented")
	}

	if res < 0 {
		return state, _get_platform_error(res)
	}

	state.exited = true

	signo := status & 0x7f

	// normal exit
	if signo == 0 {
		state.exit_code = int((status >> 8) & 0xff)
		state.success = state.exit_code == 0
	}

	// signaled
	if (status & 0xffff) - 1 < 0xff {
		// for now, success = false and exit_code = 0
	}

	// TODO: rusage gives us times of all children, not the specifically
	//       waited on child. Need to parse /proc/<pid>/stat for that.
	state.user_time = time.Duration(rusage.ru_utime.tv_usec) * time.Microsecond
	state.user_time += time.Duration(rusage.ru_utime.tv_sec) * time.Second
	state.system_time = time.Duration(rusage.ru_stime.tv_usec) * time.Microsecond
	state.system_time += time.Duration(rusage.ru_stime.tv_sec) * time.Second

	return state, nil
}
