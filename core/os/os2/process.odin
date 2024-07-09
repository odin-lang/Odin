package os2

import "core:sync"
import "core:time"
import "base:runtime"
import "core:strings"

/*
	Arguments to the current process.

	See `get_args()` for description of the slice.
*/
args := get_args()

/*
	Obtain the process argument array from the OS.

	Slice, containing arguments to the current process. Each element of the
	slice contains a single argument. The first element of the slice would
	typically is the path to the currently running executable.
*/
get_args :: proc() -> []string {
	args := make([]string, len(runtime.args__), allocator = context.allocator)
	for rt_arg, i in runtime.args__ {
		args[i] = cast(string) rt_arg
	}
	return args[:]
}

/*
	Exit the current process.
*/
exit :: proc "contextless" (code: int) -> ! {
	_exit(code)
}

/*
	Obtain the UID of the current process.

	**Note(windows)**: Windows doesn't follow the posix permissions model, so
	the function simply returns -1.
*/
get_uid :: proc() -> int {
	return _get_uid()
}

/*
	Obtain the effective UID of the current process.

	The effective UID is typically the same as the UID of the process. In case
	the process was run by a user with elevated permissions, the process may
	lower the privilege to perform some tasks without privilege. In these cases
	the real UID of the process and the effective UID are different.
	
	**Note(windows)**: Windows doesn't follow the posix permissions model, so
	the function simply returns -1.
*/
get_euid :: proc() -> int {
	return _get_euid()
}

/*
	Obtain the GID of the current process.
	
	**Note(windows)**: Windows doesn't follow the posix permissions model, so
	the function simply returns -1.
*/
get_gid :: proc() -> int {
	return _get_gid()
}

/*
	Obtain the effective GID of the current process.
	
	The effective GID is typically the same as the GID of the process. In case
	the process was run by a user with elevated permissions, the process may
	lower the privilege to perform some tasks without privilege. In these cases
	the real GID of the process and the effective GID are different.

	**Note(windows)**: Windows doesn't follow the posix permissions model, so
	the function simply returns -1.
*/
get_egid :: proc() -> int {
	return _get_egid()
}

/*
	Obtain the ID of the current process.
*/
get_pid :: proc() -> int {
	return _get_pid()
}

/*
	Obtain the ID of the parent process.

	**Note(windows)**: Windows does not mantain strong relationships between
	parent and child processes. This function returns the ID of the process
	that has created the current process. In case the parent has died, the ID
	returned by this function can identify a non-existent or a different
	process.
*/
get_ppid :: proc() -> int {
	return _get_ppid()
}


Process :: struct {
	pid:          int,
	handle:       uintptr,
	is_done:      b32,
	signal_mutex: sync.RW_Mutex,
}


Process_Attributes :: struct {
	dir: string,
	env: []string,
	files: []^File,
	sys: ^Process_Attributes_OS_Specific,
}

Process_Attributes_OS_Specific :: struct{}

Process_Error :: enum {
	None,
}

Process_State :: struct {
	pid:         int,
	exit_code:   int,
	exited:      bool,
	success:     bool,
	system_time: time.Duration,
	user_time:   time.Duration,
	sys:         rawptr,
}

Signal :: #type proc()

Kill:      Signal = nil
Interrupt: Signal = nil


find_process :: proc(pid: int) -> (^Process, Process_Error) {
	return nil, .None
}


process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (^Process, Process_Error) {
	return nil, .None
}

process_release :: proc(p: ^Process) -> Process_Error {
	return .None
}

process_kill :: proc(p: ^Process) -> Process_Error {
	return .None
}

process_signal :: proc(p: ^Process, sig: Signal) -> Process_Error {
	return .None
}

process_wait :: proc(p: ^Process) -> (Process_State, Process_Error) {
	return {}, .None
}




