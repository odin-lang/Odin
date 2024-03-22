package process

import "core:time"
import "core:os"

TIMEOUT_INFINITE :: time.MAX_DURATION

Open_Error :: enum {
	None,
	Not_Found,
	Not_Executable,
	// TODO;
}

/*
	Process handle.

	Changing any of the values in this struct will not affect the running
	process.
*/
Process :: struct {
	_os_handle: u64,
	stdout: os.Handle,
	stderr: os.Handle,
	stdin:  os.Handle,
}

/*
	Type for values describing how a given stream of the child process shall
	be mapped.

	* `None`: The stream will be bound to an equivalent of /dev/null.
	* `Pipe`: A pipe will be created for that stream, which one can obtain later
		and use it to pipe the output to a different process or file.
	* `Stdout`: Special value available for `stderr` stream: binds it with
		stdout.
	
	Additionally in the Process_Desc struct, aside from stream bindings from
	this enum, the corresponding streams accept os.Handle directly, in order
	to support piping from one command to another.
*/
Stream_Binding :: enum {
	None,
	Pipe,
	Stdout,
}

/*
	Description of how the process shall be created.
*/
Process_Desc :: struct {
	// Specifies either an argv array or a command to be run in a default shell
	// for the current OS.
	// In case the command is specified as `[]string`,
	// each element of the slice refers to an element of the resulting argv
	// array, and the first element specifies the executable to run.
	// The first element of the slice will be searched in the current working
	// directory and any of the paths specified by $PATH variable according to
	// the environment of the parent process. On windows the paths having
	// .exe or .bat suffix will be searched for as well.
	// In case the command is specified as `string`, the whole string will be
	// passed as a single argument into shell (`/bin/sh -c` on linux and
	// `cmd.exe /C` on windows).
	command: union { string, []string },
	// Specifies the environment to run the process at.
	// Each element of the slice specifies a string of the form `KEY=VALUE`.
	// If the duplicate entries are found within the slce, the last one is taken.
	environment: []string,
	// Specifies the binding for te stdout stream. See `Stream_Binding`.
	stdout: union { os.Handle, Stream_Binding },
	// Specifies the binding for te stderr stream. See `Stream_Binding`.
	stderr: union { os.Handle, Stream_Binding },
	// Specifies the binding for te stdin stream. See `Stream_Binding`.
	stdin: union { os.Handle, Stream_Binding },
}

/*
	Result of waiting on a process handle.

	* `Timeout`: returned, when a wait timeout is reached.
	* `Exited`: returned, when a process exits via a call to exit() function.
	Indicates a normal termination of a process.
	* `Signaled`: returned, when a process terminates due to receiving a
	signal, or an exception. Indicates an abnormal termination of a process.
*/
Wait_Status :: enum {
	Timeout,
	Exited,
	Signaled,
}

/*
	The selector stream of a process.
*/
Stream_Selector :: enum {
	Stdout,
	Stderr,
	Stdin,
}

/*
	Creates a process handle.

	This procedure opens a process handle given a description of the process
	specified by the `desc` argument.
	
	The process referred by the handle is created in
	**suspended** mode. To run the suspended process call the `start()`
	procedure.

	If `bind_streams` is set, the streams (stdout, stderr, stdin) of the created
	process are bound to the streams of the current process.
*/
open :: proc(desc: Process_Desc, allocator := context.allocator) -> (Process, Open_Error) {
	return {}, .None
}

/*
	Close a terminated or running process.

	This procedure should be called for any process for which `open()` returned
	successfully.
*/
close :: proc(process: Process) -> (ok: bool) {
	return false
}

/*
	Run a suspended process.
*/
start :: proc(process: Process) -> (ok: bool) {
	return false
}

/*
	Suspend a running process.
*/
suspend :: proc(process: Process) -> (ok: bool) {
	return false
}

/*
	Terminate a running process.
*/
terminate :: proc(process: Process) -> (ok: bool) {
	return false
}

/*
	Wait for termination on a running process, or until the timeout expires.

	If `TIMEOUT_INFINITE` is specified, then the wait is indefinite.

	This function returns the status of a wait, and a code. In case the process
	was terminated normally (via a call to `exit()`, returns the exit code).
	Otherwise, if it is terminated due to an exception or a signal, the signal
	or exception number is returned (respectively).
*/
wait :: proc(process: Process, timeout: time.Duration) -> (i64, Wait_Status) {
	return 0, .Timeout
}
