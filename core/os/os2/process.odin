package os2

import "base:runtime"

import "core:time"

/*
In procedures that explicitly state this as one of the allowed values,
specifies an infinite timeout.
*/
TIMEOUT_INFINITE :: time.MIN_DURATION // Note(flysand): Any negative duration will be treated as infinity

/*
Arguments to the current process.
*/
args := get_args()

@(private="file")
get_args :: proc() -> []string {
	result := make([]string, len(runtime.args__), heap_allocator())
	for rt_arg, i in runtime.args__ {
		result[i] = string(rt_arg)
	}
	return result
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
@(require_results)
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
@(require_results)
get_euid :: proc() -> int {
	return _get_euid()
}

/*
Obtain the GID of the current process.

**Note(windows)**: Windows doesn't follow the posix permissions model, so
the function simply returns -1.
*/
@(require_results)
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
@(require_results)
get_egid :: proc() -> int {
	return _get_egid()
}

/*
Obtain the ID of the current process.
*/
@(require_results)
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
@(require_results)
get_ppid :: proc() -> int {
	return _get_ppid()
}

/*
Obtain ID's of all processes running in the system.
*/
@(require_results)
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
	Working_Dir,
}

ALL_INFO :: Process_Info_Fields{.Executable_Path, .PPid, .Priority, .Command_Line, .Command_Args, .Environment, .Username, .Working_Dir}

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
	working_dir: string,
}

/*
Obtain information about a process.

This procedure obtains an information, specified by `selection` parameter of
a process given by `pid`.

Use `free_process_info` to free the memory allocated by this procedure. The
`free_process_info` procedure needs to be called, even if this procedure
returned an error, as some of the fields may have been allocated.

**Note**: The resulting information may or may contain the fields specified
by the `selection` parameter. Always check whether the returned
`Process_Info` struct has the required fields before checking the error code
returned by this procedure.
*/
@(require_results)
process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (Process_Info, Error) {
	return _process_info_by_pid(pid, selection, allocator)
}

/*
Obtain information about a process.

This procedure obtains information, specified by `selection` parameter
about a process that has been opened by the application, specified in
the `process` parameter.

Use `free_process_info` to free the memory allocated by this procedure. The
`free_process_info` procedure needs to be called, even if this procedure
returned an error, as some of the fields may have been allocated.

**Note**: The resulting information may or may contain the fields specified
by the `selection` parameter. Always check whether the returned
`Process_Info` struct has the required fields before checking the error code
returned by this procedure.
*/
@(require_results)
process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (Process_Info, Error) {
	return _process_info_by_handle(process, selection, allocator)
}

/*
Obtain information about the current process.

This procedure obtains the information, specified by `selection` parameter
about the currently running process.

Use `free_process_info` to free the memory allocated by this procedure. The
`free_process_info` procedure needs to be called, even if this procedure
returned an error, as some of the fields may have been allocated.

**Note**: The resulting information may or may contain the fields specified
by the `selection` parameter. Always check whether the returned
`Process_Info` struct has the required fields before checking the error code
returned by this procedure.
*/
@(require_results)
current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (Process_Info, Error) {
	return _current_process_info(selection, allocator)
}

/*
Obtain information about the specified process.
*/
process_info :: proc {
	process_info_by_pid,
	process_info_by_handle,
	current_process_info,
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
	for a in pi.command_args {
		delete(a, allocator)
	}
	delete(pi.command_args, allocator)
	for s in pi.environment {
		delete(s, allocator)
	}
	delete(pi.environment, allocator)
	delete(pi.working_dir, allocator)
	delete(pi.username, allocator)
}

/*
Represents a process handle.

When a process dies, the OS is free to re-use the pid of that process. The
`Process` struct represents a handle to the process that will refer to a
specific process, even after it has died.

**Note(linux)**: The `handle` will be referring to pidfd.
*/
Process :: struct {
	pid: int,
	handle: uintptr,
}

Process_Open_Flags :: bit_set[Process_Open_Flag]
Process_Open_Flag :: enum {
	// Request for reading from the virtual memory of another process.
	Mem_Read,
	// Request for writing to the virtual memory of another process.
	Mem_Write,
}

/*
Open a process handle using it's pid.

This procedure obtains a process handle of a process specified by `pid`.
This procedure can be subject to race conditions. See the description of
`Process`.

Use `process_close()` function to close the process handle.
*/
@(require_results)
process_open :: proc(pid: int, flags := Process_Open_Flags {}) -> (Process, Error) {
	return _process_open(pid, flags)
}


/*
OS-specific process attributes.
*/
Process_Attributes :: struct {
	sys_attr: _Sys_Process_Attributes,
}

/*
	The description of how a process should be created.
*/
Process_Desc :: struct {
	// OS-specific attributes.
	sys_attr: Process_Attributes,

	// The working directory of the process. If the string has length 0, the
	// working directory is assumed to be the current working directory of the
	// current process.
	working_dir: string,
	// The command to run. Each element of the slice is a separate argument to
	// the process. The first element of the slice would be the executable.
	command: []string,
	// A slice of strings, each having the format `KEY=VALUE` representing the
	// full environment that the child process will receive.
	// In case this slice is `nil`, the current process' environment is used.
	// NOTE(laytan): maybe should be `Maybe([]string)` so you can do `nil` == current env, empty == empty/no env.
	env: []string,
	// The `stderr` handle to give to the child process. It can be either a file
	// or a writeable end of a pipe. Passing `nil` will shut down the process'
	// stderr output.
	stderr: ^File,
	// The `stdout` handle to give to the child process. It can be either a file
	// or a writeabe end of a pipe. Passing a `nil` will shut down the process'
	// stdout output.
	stdout: ^File,
	// The `stdin` handle to give to the child process. It can either be a file
	// or a readable end of a pipe. Passing a `nil` will shut down the process'
	// input.
	stdin: ^File,
}

/*
Create a new process and obtain its handle.

This procedure creates a new process, with a given command and environment
strings as parameters. Use `environ()` to inherit the environment of the
current process.

The `desc` parameter specifies the description of how the process should
be created. It contains information such as the command line, the
environment of the process, the starting directory and many other options.
Most of the fields in the struct can be set to `nil` or an empty value.

Use `process_close` to close the handle to the process. Note, that this
is not the same as terminating the process. One can terminate the process
and not close the handle, in which case the handle would be leaked. In case
the function returns an error, an invalid handle is returned.

This procedure is not thread-safe. It may alter the inheritance properties
of file handles in an unpredictable manner. In case multiple threads change
handle inheritance properties, make sure to serialize all those calls.
*/
@(require_results)
process_start :: proc(desc: Process_Desc) -> (Process, Error) {
	return _process_start(desc)
}

/*
Execute the process and capture stdout and stderr streams.

This procedure creates a new process, with a given command and environment
strings as parameters, and waits until the process finishes execution. While
the process is running, this procedure accumulates the output of its stdout
and stderr streams and returns byte slices containing the captured data from
the streams.

This procedure expects that `stdout` and `stderr` fields of the `desc` parameter
are left at default, i.e. a `nil` value. You can not capture stdout/stderr and
redirect it to a file at the same time.

This procedure does not free `stdout` and `stderr` slices before an error is
returned. Make sure to call `delete` on these slices.
*/
@(require_results)
process_exec :: proc(
	desc: Process_Desc,
	allocator: runtime.Allocator,
	loc := #caller_location,
) -> (
	state: Process_State,
	stdout: []byte,
	stderr: []byte,
	err: Error,
) {
	assert(desc.stdout == nil, "Cannot redirect stdout when it's being captured", loc)
	assert(desc.stderr == nil, "Cannot redirect stderr when it's being captured", loc)

	stdout_r, stdout_w := pipe() or_return
	defer close(stdout_r)
	stderr_r, stderr_w := pipe() or_return
	defer close(stderr_r)

	process: Process
	{
		// NOTE(flysand): Make sure the write-ends are closed, regardless
		// of the outcome. This makes read-ends readable on our side.
		defer close(stdout_w)
		defer close(stderr_w)
		desc := desc
		desc.stdout = stdout_w
		desc.stderr = stderr_w
		process = process_start(desc) or_return
	}

	{
		stdout_b: [dynamic]byte
		stdout_b.allocator = allocator

		stderr_b: [dynamic]byte
		stderr_b.allocator = allocator

		buf: [1024]u8 = ---
		
		stdout_done, stderr_done, has_data: bool
		for err == nil && (!stdout_done || !stderr_done) {
			n := 0

			if !stdout_done {
				has_data, err = pipe_has_data(stdout_r)
				if has_data {
					n, err = read(stdout_r, buf[:])
				}

				switch err {
				case nil:
					_, err = append(&stdout_b, ..buf[:n])
				case .EOF, .Broken_Pipe:
					stdout_done = true
					err = nil
				}
			}

			if err == nil && !stderr_done {
				n = 0
				has_data, err = pipe_has_data(stderr_r)
				if has_data {
					n, err = read(stderr_r, buf[:])
				}

				switch err {
				case nil:
					_, err = append(&stderr_b, ..buf[:n])
				case .EOF, .Broken_Pipe:
					stderr_done = true
					err = nil
				}
			}
		}

		stdout = stdout_b[:]
		stderr = stderr_b[:]
	}

	if err != nil {
		state, _ = process_wait(process, timeout=0)
		if !state.exited {
			_ = process_kill(process)
			state, _ = process_wait(process)
		}
		return
	}

	state, err = process_wait(process)
	return
}

/*
	The state of the process after it has finished execution.
*/
Process_State :: struct {
	// The ID of the process.
	pid: int,
	// Specifies whether the process has terminated or is still running.
	exited: bool,
	// The exit code of the process, if it has exited.
	// Will also store the number of the exception or signal that has crashed the
	// process.
	exit_code: int,
	// Specifies whether the termination of the process was successfull or not,
	// i.e. whether it has crashed or not.
	// **Note(windows)**: On windows `true` is always returned, as there is no
	// reliable way to obtain information about whether the process has crashed.
	success: bool,
	// The time the process has spend executing in kernel time.
	system_time: time.Duration,
	// The time the process has spend executing in userspace.
	user_time: time.Duration,
}

/*
Wait for a process event.

This procedure blocks the execution until the process has exited or the
timeout (if specified) has reached zero. If the timeout is `TIMEOUT_INFINITE`,
no timeout restriction is imposed and the procedure can block indefinately.

If the timeout has expired, the `General_Error.Timeout` is returned as
the error.

If an error is returned for any other reason, other than timeout, the
process state is considered undetermined.
*/
@(require_results)
process_wait :: proc(process: Process, timeout := TIMEOUT_INFINITE) -> (Process_State, Error) {
	return _process_wait(process, timeout)
}

/*
Close the handle to a process.

This procedure closes the handle associated with a process. It **does not**
terminate a process, in case it was running. In case a termination is
desired, kill the process first, wait for the process to finish,
then close the handle.
*/
@(require_results)
process_close :: proc(process: Process) -> (Error) {
	return _process_close(process)
}

/*
Terminate a process.

This procedure terminates a process, specified by it's handle, `process`.
*/
@(require_results)
process_kill :: proc(process: Process) -> (Error) {
	return _process_kill(process)
}
