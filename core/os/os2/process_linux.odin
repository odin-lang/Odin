//+private
package os2

import "core:time"
import "core:runtime"
import "core:strings"
import "core:sys/unix"

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

Attribute_Bits :: enum {
	Search_Path,
	Replace_Process,
}

Process_Attributes_OS_Specific :: struct {
	flags: bit_set[Attribute_Bits],
}

_process_find :: proc(pid: int) -> (^Process, Error) {
	return nil, nil
}

_process_get_state :: proc(p: Process) -> (Process_State, Error) {
	return Process_State{}, nil
}

_process_get_attributes :: proc(p: Process) -> (Process_Attributes, Error) {
	return Process_Attributes{}, nil
}

_process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (Process, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	child: Process

	if name[0] != '/' && .Search_Path in attr.sys.flags {
		unimplemented()
	}
	path := strings.clone_to_cstring(name)

	// args and environment need to be a list of cstrings
	// that are terminated by a nil pointer
	cargs := make([]cstring, len(argv) + 2, context.temp_allocator)
	// The first argument is a copy of the program name.
	cargs[0] = path
	for i := 0; i < len(argv); i += 1 {
		cargs[i + 1] = strings.clone_to_cstring(argv[i], context.temp_allocator)
	}

	// Use current process's environment if attributes not provided
	env: [^]cstring
	if attr == nil {
		// take this process's current environment
		env = raw_data(export_cstring_environment(context.temp_allocator))
	} else {
		if (len(attr.files) == 0) {
			// TODO: handle attr.files for "popen" style behavior
			unimplemented()
		}

		cenv := make([]cstring, len(attr.env) + 1, context.temp_allocator)
		// The first argument is a copy of the program name.
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
	//           b. set up popen style file operations
	//           c. execve
	//       5. restore signal handlers
	//
	res: int
	if attr == nil || .Replace_Process not_in attr.sys.flags {
		res = unix.sys_fork()
	}

	if res == 0 {
		// in child process now (or replacing original)
		if res = unix.sys_execve(path, &cargs[0], env); res < 0 {
			print_error(_get_platform_error(res), string(path))
			panic("sys_execve failed to replace process")
		}
	}

	if res < 0 {
		return child, _get_platform_error(res)
	}
	// still in parent process
	child.pid = res

	return child, nil
}

_process_release :: proc(p: ^Process) -> Error {
	return nil
}

_process_kill :: proc(p: ^Process) -> Error {
	res := unix.sys_kill(p.pid, unix.SIGKILL)
	return _ok_or_error(res)
}

_process_signal :: proc(sig: Signal, h: Signal_Handler) -> Error {
	return nil
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
