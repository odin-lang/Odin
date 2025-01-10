#+build linux, windows, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "base:intrinsics"

import "core:c"
import "core:c/libc"

when ODIN_OS == .Windows {
	foreign import lib "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// signal.h - signals

foreign lib {
	/*
	Set a signal handler.

	func can either be:
	- `auto_cast posix.SIG_DFL` setting the default handler for that specific signal
	- `auto_cast posix.SIG_IGN` causing the specific signal to be ignored
	- a custom signal handler

	Returns: SIG_ERR (setting errno), the last value of func on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/signal.html ]]
	*/
	signal :: proc(sig: Signal, func: proc "c" (Signal)) -> proc "c" (Signal) ---

	/*
	Raises a signal, calling its handler and then returning.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/raise.html ]]
	*/
	raise :: proc(sig: Signal) -> result ---
}

Signal :: enum c.int {
	NONE,

	// LIBC:

	// Process abort signal.
	SIGABRT   = SIGABRT,
	// Erronous arithemtic operation.
	SIGFPE    = SIGFPE,
	// Illegal instruction.
	SIGILL    = SIGILL,
	// Terminal interrupt signal.
	SIGINT    = SIGINT,
	// Invalid memory reference.
	SIGSEGV   = SIGSEGV,
	// Termination signal.
	SIGTERM   = SIGTERM,

	// POSIX:

	// Process abort signal.
	SIGALRM   = SIGALRM,
	// Access to an undefined portion of a memory object.
	SIGBUS    = SIGBUS,
	// Child process terminated, stopped, or continued.
	SIGCHLD   = SIGCHLD,
	// Continue execution, if stopped.
	SIGCONT   = SIGCONT,
	// Hangup.
	SIGHUP    = SIGHUP,
	// Kill (cannot be caught or ignored).
	SIGKILL   = SIGKILL,
	// Write on a pipe with no one to read it.
	SIGPIPE   = SIGPIPE,
	// Terminal quit signal.
	SIGQUIT   = SIGQUIT,
	// Stop executing (cannot be caught or ignored).
	SIGSTOP   = SIGSTOP,
	// Terminal stop process.
	SIGTSTP   = SIGTSTP,
	// Background process attempting read.
	SIGTTIN   = SIGTTIN,
	// Background process attempting write.
	SIGTTOU   = SIGTTOU,
	// User-defined signal 1.
	SIGUSR1   = SIGUSR1,
	// User-defined signal 2.
	SIGUSR2   = SIGUSR2,
	// Pollable event.
	SIGPOLL   = SIGPOLL,
	// Profiling timer expired.
	SIGPROF   = SIGPROF,
	// Bad system call.
	SIGSYS    = SIGSYS,
	// Trace/breakpoint trap.
	SIGTRAP   = SIGTRAP,
	// High bandwidth data is available at a socket.
	SIGURG    = SIGURG,
	// Virtual timer expired.
	SIGVTALRM = SIGVTALRM,
	// CPU time limit exceeded.
	SIGXCPU   = SIGXCPU,
	// File size limit exceeded.
	SIGXFSZ   = SIGXFSZ,
}

// Request for default signal handling.
SIG_DFL :: libc.SIG_DFL
// Return value from signal() in case of error.
SIG_ERR :: libc.SIG_ERR
// Request that signal be ignored.
SIG_IGN :: libc.SIG_IGN

SIGABRT :: libc.SIGABRT
SIGFPE  :: libc.SIGFPE
SIGILL  :: libc.SIGILL
SIGINT  :: libc.SIGINT
SIGSEGV :: libc.SIGSEGV
SIGTERM :: libc.SIGTERM

when ODIN_OS == .Windows {
	SIGALRM   :: -1
	SIGBUS    :: -1
	SIGCHLD   :: -1
	SIGCONT   :: -1
	SIGHUP    :: -1
	SIGKILL   :: -1
	SIGPIPE   :: -1
	SIGQUIT   :: -1
	SIGSTOP   :: -1
	SIGTSTP   :: -1
	SIGTTIN   :: -1
	SIGTTOU   :: -1
	SIGUSR1   :: -1
	SIGUSR2   :: -1
	SIGPOLL   :: -1
	SIGPROF   :: -1
	SIGSYS    :: -1
	SIGTRAP   :: -1
	SIGURG    :: -1
	SIGVTALRM :: -1
	SIGXCPU   :: -1
	SIGXFSZ   :: -1
}
