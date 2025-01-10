#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/wait.h - declarations for waiting

foreign lib {
	/*
	Obtains status information pertaining to one of the caller's child processes.

	Returns: -1 (setting errno) on failure or signal on calling process, the pid of the process that caused the return otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/wait.html ]]
	*/
	wait :: proc(stat_loc: ^c.int) -> pid_t ---

	/*
	Obtains status information pertaining to the given pid specifier.

	If pid is -1, status is requested for any child process.
	If pid is greater than 0, it specifies the process ID of a single child process.
	If pid is 0, it specifies any child process whose process group ID is equal to that of the call.
	If pid is < -1, status is requested for any child whose process group ID is the absolute value of pid.

	Returns: -1 (setting errno) on failure or signal on calling process, 0 if NOHANG and status is not available, the pid of the process that caused the return otherwise

	Example:
		// The following example demonstrates the use of waitpid(), fork(), and the macros used to
		// interpret the status value returned by waitpid() (and wait()). The code segment creates a
		// child process which does some unspecified work. Meanwhile the parent loops performing calls
		// to waitpid() to monitor the status of the child. The loop terminates when child termination
		// is detected.

		child_pid := posix.fork(); switch child_pid {
		case -1: // `fork` failed.
			panic("fork failed")

		case 0:  // This is the child.

			// Do some work...

		case:
			for {
				status: i32
				wpid := posix.waitpid(child_pid, &status, { .UNTRACED, .CONTINUED })
				if wpid == -1 {
					panic("waitpid failure")
				}

				switch {
				case posix.WIFEXITED(status):
					fmt.printfln("child exited, status=%v", posix.WEXITSTATUS(status))
				case posix.WIFSIGNALED(status):
					fmt.printfln("child killed (signal %v)", posix.WTERMSIG(status))
				case posix.WIFSTOPPED(status):
					fmt.printfln("child stopped (signal %v", posix.WSTOPSIG(status))
				case posix.WIFCONTINUED(status):
					fmt.println("child continued")
				case:
					// Should never happen.
					fmt.println("unexpected status (%x)", status)
				}

				if posix.WIFEXITED(status) || posix.WIFSIGNALED(status) {
					break
				}
			}
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/wait.html ]]
	*/
	waitpid :: proc(pid: pid_t, stat_loc: ^c.int, options: Wait_Flags) -> pid_t ---

	/*
	Obtains status information pertaining to the given idtype_t and id specifier.

	Returns: 0 if WNOHANG and no status available, 0 if child changed state, -1 (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/waitid.html ]]
	*/
	waitid :: proc(idtype: idtype_t, id: id_t, infop: ^siginfo_t, options: Wait_Flags) -> c.int ---
}

// If terminated normally.
WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
	return _WIFEXITED(x)
}

// If WIFEXITED is true, returns the exit status.
WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
	return _WEXITSTATUS(x)
}

// If terminated due to an uncaught signal.
WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
	return _WIFSIGNALED(x)
}

// If WIFSIGNALED is true, returns the signal.
WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
	return _WTERMSIG(x)
}

// If status was returned for a child process that is currently stopped.
WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
	return _WIFSTOPPED(x)
}

// If WIFSTOPPED, the signal that caused the child process to stop.
WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
	return _WSTOPSIG(x)
}

// If status was returned for a child process that has continued from a job control stop.
WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
	return _WIFCONTINUED(x)
}

idtype_t :: enum c.int {
	// Wait for any children and `id` is ignored.
	P_ALL  = _P_ALL,
	// Wait for any child wiith a process group ID equal to `id`.
	P_PID  = _P_PID,
	// Wait for any child with a process group ID equal to `id`.
	P_PGID = _P_PGID,
}

Wait_Flag_Bits :: enum c.int {
	// Report the status of any continued child process specified by pid whose status has not been
	// reported since it continued from a job control stop.
	CONTINUED = log2(WCONTINUED),
	// Don't suspend execution of the calling thread if status is not immediately available for one
	// of the child processes specified by pid.
	NOHANG    = log2(WNOHANG),
	// The status of any child process specified by pid that are stopped, and whose status has not
	// yet been reported since they stopped, shall also be reported to the requesting process.
	UNTRACED  = log2(WUNTRACED),

	// Following are only available on `waitid`, not `waitpid`.

	// Wait for processes that have exited.
	EXITED  = log2(WEXITED),
	// Keep the process whose status is returned in a waitable state, so it may be waited on again.
	NOWAIT  = log2(WNOWAIT),
	// Children that have stopped upon receipt of a signal, and whose status either hasn't been reported
	// or has been reported but that report was called with NOWAIT.
	STOPPED = log2(WSTOPPED),
}
Wait_Flags :: bit_set[Wait_Flag_Bits; c.int]

when ODIN_OS == .Darwin {

	id_t :: distinct c.uint

	WCONTINUED :: 0x00000010
	WNOHANG    :: 0x00000001
	WUNTRACED  :: 0x00000002

	WEXITED  :: 0x00000004
	WNOWAIT  :: 0x00000020
	WSTOPPED :: 0x00000008

	_P_ALL  :: 0
	_P_PID  :: 1
	_P_PGID :: 2

	@(private)
	_WSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x & 0o177
	}

	@(private)
	_WSTOPPED :: 0o177

	@(private)
	_WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == 0
	}

	@(private)
	_WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x >> 8
	}

	@(private)
	_WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) != _WSTOPPED && _WSTATUS(x) != 0
	}

	@(private)
	_WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(_WSTATUS(x))
	}

	@(private)
	_WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == _WSTOPPED && WSTOPSIG(x) != .SIGCONT
	}

	@(private)
	_WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(x >> 8)
	}

	@(private)
	_WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == _WSTOPPED && WSTOPSIG(x) == .SIGCONT
	}

} else when ODIN_OS == .FreeBSD {

	id_t :: distinct c.int64_t

	WCONTINUED :: 4
	WNOHANG    :: 1
	WUNTRACED  :: 2

	WEXITED  :: 16
	WNOWAIT  :: 8
	WSTOPPED :: 2

	_P_ALL  :: 7
	_P_PID  :: 0
	_P_PGID :: 2

	@(private)
	_WSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x & 0o177
	}

	@(private)
	_WSTOPPED :: 0o177

	@(private)
	_WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == 0
	}

	@(private)
	_WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x >> 8
	}

	@(private)
	_WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) != _WSTOPPED && _WSTATUS(x) != 0 && x != c.int(Signal.SIGCONT)
	}

	@(private)
	_WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(_WSTATUS(x))
	}

	@(private)
	_WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == _WSTOPPED
	}

	@(private)
	_WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(x >> 8)
	}

	@(private)
	_WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return x == c.int(Signal.SIGCONT)
	}
} else when ODIN_OS == .NetBSD {

	id_t :: distinct c.uint32_t

	WCONTINUED :: 0x00000010
	WNOHANG    :: 0x00000001
	WUNTRACED  :: 0x00000002

	WEXITED  :: 0x00000020
	WNOWAIT  :: 0x00010000
	WSTOPPED :: 0x00000002

	_P_ALL  :: 0
	_P_PID  :: 1
	_P_PGID :: 2

	@(private)
	_WSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x & 0o177
	}

	@(private)
	_WSTOPPED :: 0o177

	@(private)
	_WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == 0
	}

	@(private)
	_WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return c.int((c.uint(x) >> 8) & 0xff)
	}

	@(private)
	_WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return !WIFSTOPPED(x) && !WIFCONTINUED(x) && !WIFEXITED(x)
	}

	@(private)
	_WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(_WSTATUS(x))
	}

	@(private)
	_WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == _WSTOPPED && !WIFCONTINUED(x)
	}

	@(private)
	_WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(c.int((c.uint(x) >> 8) & 0xff))
	}

	@(private)
	_WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return x == 0xffff
	}

} else when ODIN_OS == .OpenBSD {

	id_t :: distinct c.uint32_t

	WCONTINUED :: 0x00000010
	WNOHANG    :: 0x00000001
	WUNTRACED  :: 0x00000002

	WEXITED  :: 0x00000020
	WNOWAIT  :: 0x00010000
	WSTOPPED :: 0x00000002

	_P_ALL  :: 0
	_P_PID  :: 2
	_P_PGID :: 1

	@(private)
	_WSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x & 0o177
	}

	@(private)
	_WSTOPPED :: 0o177
	@(private)
	_WCONTINUED :: 0o177777

	@(private)
	_WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) == 0
	}

	@(private)
	_WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return (x >> 8) & 0x000000ff
	}

	@(private)
	_WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WSTATUS(x) != _WSTOPPED && _WSTATUS(x) != 0
	}

	@(private)
	_WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(_WSTATUS(x))
	}

	@(private)
	_WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return (x & 0xff) == _WSTOPPED
	}

	@(private)
	_WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal((x >> 8) & 0xff)
	}

	@(private)
	_WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return (x & _WCONTINUED) == _WCONTINUED
	}

} else when ODIN_OS == .Linux {

	id_t :: distinct c.uint

	WCONTINUED :: 8
	WNOHANG    :: 1
	WUNTRACED  :: 2

	WEXITED  :: 4
	WNOWAIT  :: 0x1000000
	WSTOPPED :: 2

	_P_ALL  :: 0
	_P_PID  :: 1
	_P_PGID :: 2

	@(private)
	_WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return _WTERMSIG(x) == nil
	}

	@(private)
	_WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return (x & 0xff00) >> 8
	}

	@(private)
	_WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return (x & 0xffff) - 1 < 0xff
	}

	@(private)
	_WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(x & 0x7f)
	}

	@(private)
	_WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return ((x & 0xffff) * 0x10001) >> 8 > 0x7f00
	}

	@(private)
	_WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal(_WEXITSTATUS(x))
	}

	@(private)
	_WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return x == 0xffff
	}

} else when ODIN_OS == .Haiku {

	id_t :: distinct c.int32_t

	WCONTINUED :: 0x04
	WNOHANG    :: 0x01
	WUNTRACED  :: 0x02

	WEXITED  :: 0x08
	WNOWAIT  :: 0x20
	WSTOPPED :: 0x10

	_P_ALL  :: 0
	_P_PID  :: 1
	_P_PGID :: 2

	@(private)
	_WIFEXITED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return (x & ~(c.int)(0xff)) == 0
	}

	@(private)
	_WEXITSTATUS :: #force_inline proc "contextless" (x: c.int) -> c.int {
		return x & 0xff
	}

	@(private)
	_WIFSIGNALED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return ((x >> 8) & 0xff) != 0
	}

	@(private)
	_WTERMSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal((x >> 8) & 0xff)
	}

	@(private)
	_WIFSTOPPED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return ((x >> 16) & 0xff) != 0
	}

	@(private)
	_WSTOPSIG :: #force_inline proc "contextless" (x: c.int) -> Signal {
		return Signal((x >> 16) & 0xff)
	}

	@(private)
	_WIFCONTINUED :: #force_inline proc "contextless" (x: c.int) -> bool {
		return (x & 0x20000) != 0
	}

}
