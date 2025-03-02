#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/time.h - time types

foreign lib {
	/*
	Store the current value of timer into value.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getitimer.html ]]
	*/
	@(link_name=LGETITIMER)
	getitimer :: proc(which: ITimer, value: ^itimerval) -> result ---

	/*
	Set the timer to the value given, and store the previous value in ovalue if it is not nil.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getitimer.html ]]
	*/
	@(link_name=LSETITIMER)
	setitimer :: proc(which: ITimer, value: ^itimerval, ovalue: ^itimerval) -> result ---

	/*
	Obtains the current time.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/gettimeofday.html ]]
	*/
	@(link_name=LGETTIMEOFDAY)
	gettimeofday :: proc(tp: ^timeval, tzp: rawptr = nil) -> result ---

	/*
	Sets the access and modification times of the file at the given path.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/utimes.html ]]
	*/
	@(link_name=LUTIMES)
	utimes :: proc(path: cstring, times: ^[2]timeval) -> result ---	
}

ITimer :: enum c.int {
	// Decrements in real time.
	REAL    = ITIMER_REAL,
	// Decrements in process virtual time, only when the process is executing.
	VIRTUAL = ITIMER_VIRTUAL,
	// Decrements both in process virtual time and when the system is running on 
	// behalf of the process.
	PROF    = ITIMER_PROF,
}

when ODIN_OS == .NetBSD {
	@(private) LGETITIMER    :: "__getitimer50"
	@(private) LSETITIMER    :: "__setitimer50"
	@(private) LGETTIMEOFDAY :: "__gettimeofday50"
	@(private) LUTIMES       :: "__utimes50"
} else {
	@(private) LGETITIMER    :: "getitimer"
	@(private) LSETITIMER    :: "setitimer"
	@(private) LGETTIMEOFDAY :: "gettimeofday"
	@(private) LUTIMES       :: "utimes"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	itimerval :: struct {
		it_interval: timeval, /* [PSX] timer interval */
		it_value:    timeval, /* [PSX] current value */
	}

	ITIMER_REAL    :: 0
	ITIMER_VIRTUAL :: 1
	ITIMER_PROF    :: 2

} else when ODIN_OS == .Haiku {

	itimerval :: struct {
		it_interval: timeval, /* [PSX] timer interval */
		it_value:    timeval, /* [PSX] current value */
	}

	ITIMER_REAL    :: 1
	ITIMER_VIRTUAL :: 2
	ITIMER_PROF    :: 3

}
