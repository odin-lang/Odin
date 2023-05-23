//+private
package os2

import "core:runtime"
import "core:strings"
import "core:sys/unix"

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

_find_process :: proc(pid: int) -> (^Process, Error) {
	return nil, nil
}

Process_Attributes_OS_Specific :: struct {
	search_path: bool // not implemented
	replace_current_process: bool
}

_process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (Process, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	p: Process

	// TODO: search PATH if not in current directory and not an
	//       absolute path? Maybe make that an option in attributes.
	path := strings.clone_to_cstring(name)

	// args and environment need to be a list of cstrings
	// that are terminated by a nil pointer
	cargs := make([]cstring, len(argv) + 2, context.temp_allocator)
	// The first argument is a copy of the program name.
	cargs[0] = path
	for i := 0; i < len(argv); i += 1 {
		cargs[i + 1] = strings.clone_to_cstring(argv[i], context.temp_allocator)
	}

	// Use current processes environment if attributes not provided
	env: [^]cstring
	if attr == nil {
		// take this processes current environment
		env = raw_data(export_cstring_environment(context.temp_allocator))
	} else {
		// TODO: handle attr.files for "popen" style behavior

		cenv := make([]cstring, len(attr.env) + 1, context.temp_allocator)
		// The first argument is a copy of the program name.
		for i := 0; i < len(argv); i += 1 {
			cenv[i] = strings.clone_to_cstring(attr.env[i], context.temp_allocator)
		}
		env = &cenv[0]
	}

	res: int
	if attr == nil || !attr.sys.replace_current_process {
		res = unix.sys_fork()
	}

	if res < 0 {
		return p, _get_platform_error(res)
	}
	if res == 0 {
		// in child process now (or replacing original)
		if res = unix.sys_execve(path, &cargs[0], env); res < 0 {
			// TODO: add print_error
			exit(1)
		}
	}
	// still in parent process
	p.pid = res

	return p, nil
}

_process_release :: proc(p: ^Process) -> Error {
	return nil
}

_process_kill :: proc(p: ^Process) -> Error {
	return nil
}

_process_signal :: proc(p: ^Process, sig: Signal) -> Error {
	return nil
}

_process_wait :: proc(p: ^Process) -> (Process_State, Error) {
	return {}, nil
}
