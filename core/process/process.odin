package process

import "core:time"
import "core:io"

TIMEOUT_INFINITE :: time.MAX_DURATION

Error :: enum {
	None,
	Not_Found,
	Not_Executable,
	// TODO;
}

/*
	Process handle.
*/
Process :: struct {
	_os_handle: u64,
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

	This procedure opens a process handle given an executable specified by
	the `path` argument. The process referred by the handle is created in
	**suspended** mode. To run the suspended process call the `start()`
	procedure.

	This function emulates the behavior of the shell for relative paths. First
	it will look whether the path relative to the current working directory
	exists, then, if the path didn't exist, it will check each path in the
	$PATH environment variable. In case the process wasn't found, the .Not_Found
	error is returned.

	If `bind_streams` is set, the streams (stdout, stderr, stdin) of the created
	process are bound to the streams of the current process.
*/
open :: proc(
	path: string,
	argv: []string,
	envp: []string,
	bind_streams := false,
	allocator := context.temp_allocator,
) -> (Process, Error) {
	return {}, .None
}

/*
	Close a terminated or running process.

	This procedure should be called for any process for which `open()` returned
	successfully.
*/
close :: proc(process: Process) {

}

/*
	Run a suspended process.
*/
start :: proc(process: Process) -> (Error) {
	return .None
}

/*
	Suspend a running process.
*/
suspend :: proc(process: Process) {
	
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

/*
	Returns process's the stream of a running process.

	- In case Stdin is specified:
		Returns writeable stream, such that if the data is written to it, the
		data will be sent to `stdin` stream of the process.
	- In case stdout or stderr is specified.
		Returns readable stream, such that if the data is read from the process,
		it will return the data sent by the process to the corresponding stream.
*/
get_stream :: proc(process: Process, $stream: Stream_Selector) -> (io.Stream, bool) {
	return {}, false
}
