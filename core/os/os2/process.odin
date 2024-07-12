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

/*
	Obtain ID's of all processes running in the system.
*/
process_list :: proc(allocator: runtime.Allocator) -> ([]int, Error) {
	return _process_list(allocator)
}

/*
	Bit set specifying which fields of the `Process_Info` struct need to be
	obtained by the `process_info()` procedure. Each bit corresponds to a
	field in the `Process_Info` struct.
*/
Process_Info_Fields :: bit_set[Process_Info_Field]
Process_Info_Field :: enum {
	Executable_Path,
	PPid,
	Priority,
	Command_Line,
	Command_Args,
	Environment,
	Username,
	CWD,
}

/*
	Contains information about the process as obtained by the `process_info()`
	procedure.
*/
Process_Info :: struct {
	// The information about a process the struct contains. `pid` is always
	// stored, no matter what.
	fields: Process_Info_Fields,
	// The ID of the process.
	pid: int,
	// The ID of the parent process.
	ppid: int,
	// The process priority.
	priority: int,
	// The path to the executable, which the process runs.
	executable_path: string,
	// The command line supplied to the process.
	command_line: string,
	// The arguments supplied to the process.
	command_args: []string,
	// The environment of the process.
	environment: []string,
	// The username of the user who started the process.
	username: string,
	// The current working directory of the process.
	cwd: string,
}

/*
	Obtain information about a process.

	This procedure obtains an information, specified by `selection` parameter of
	a process given by `pid`.
	
	Use `free_process_info` to free the memory allocated by this function. In
	case the function returns an error all temporary allocations would be freed
	and as such, calling `free_process_info()` is not needed.

	**Note**: The resulting information may or may not contain the
	selected fields. Please check the `fields` field of the `Process_Info`
	struct to see if the struct contains the desired fields **before** checking
	the error code returned by this function.
*/
process_info :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (Process_Info, Error) {
	return _process_info(pid, selection, allocator)
}

/*
	Obtain information about the current process.

	This procedure obtains the information, specified by `selection` parameter
	about the currently running process.

	Use `free_process_info` to free the memory allocated by this function. In
	case this function returns an error, all temporary allocations would be
	freed and as such calling `free_process_info()` is not needed.

	**Note**: The resulting `Process_Info` may or may not contain the selected
	fields. Check the `fields` field of the `Process_Info` struct to see, if the
	struct contains the selected fields **before** checking the error code
	returned by this function.
*/
current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (Process_Info, Error) {
	return _current_process_info(selection, allocator)
}

/*
	Free the information about the process.

	This procedure frees the memory occupied by process info using the provided
	allocator. The allocator needs to be the same allocator that was supplied
	to the `process_info` function.
*/
free_process_info :: proc(pi: Process_Info, allocator: runtime.Allocator) {
	delete(pi.executable_path, allocator)
	delete(pi.command_line, allocator)
	delete(pi.command_args, allocator)
	for s in pi.environment {
		delete(s, allocator)
	}
	delete(pi.environment, allocator)
	delete(pi.cwd, allocator)
}

// Process_Attributes :: struct {
// 	dir: string,
// 	env: []string,
// 	files: []^File,
// 	sys: ^Process_Attributes_OS_Specific,
// }

// Process_Attributes_OS_Specific :: struct{}

// Process_Error :: enum {
// 	None,
// }

// Process_State :: struct {
// 	pid:         int,
// 	exit_code:   int,
// 	exited:      bool,
// 	success:     bool,
// 	system_time: time.Duration,
// 	user_time:   time.Duration,
// 	sys:         rawptr,
// }

// Signal :: #type proc()

// Kill:      Signal = nil
// Interrupt: Signal = nil


// find_process :: proc(pid: int) -> (^Process, Process_Error) {
// 	return nil, .None
// }


// process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (^Process, Process_Error) {
// 	return nil, .None
// }

// process_release :: proc(p: ^Process) -> Process_Error {
// 	return .None
// }

// process_kill :: proc(p: ^Process) -> Process_Error {
// 	return .None
// }

// process_signal :: proc(p: ^Process, sig: Signal) -> Process_Error {
// 	return .None
// }

// process_wait :: proc(p: ^Process) -> (Process_State, Process_Error) {
// 	return {}, .None
// }




