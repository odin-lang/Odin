package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/resource.h - definitions XSI resource operations

foreign lib {
	/*
	Gets the nice value of the process, process group or user given.

	Note that a nice value can be -1, so checking for an error would mean clearing errno, doing the
	call and then checking that this returns -1 and it has an errno.

	Returns: -1 (setting errno) on failure, the value otherwise

	Example:
		pid := posix.getpid()
		posix.set_errno(.NONE)
		prio := posix.getpriority(.PROCESS, pid)
		if err := posix.errno(); prio == -1 && err != .NONE {
			// Handle error...
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpriority.html ]]
	*/
	getpriority :: proc(which: Which_Prio, who: id_t) -> c.int ---

	/*
	Sets the nice value of the process, process group or user given.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpriority.html ]]
	*/
	setpriority :: proc(which: Which_Prio, who: id_t, value: c.int) -> result ---

	/*
	Get a resource limit.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getrlimit.html ]]
	*/
	getrlimit :: proc(resource: Resource, rlp: ^rlimit) -> result ---

	/*
	Set a resource limit.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getrlimit.html ]]
	*/
	setrlimit :: proc(resource: Resource, rlp: ^rlimit) -> result ---

	/*
	Get resource usage.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getrusage.html ]]
	*/
	@(link_name=LGETRUSAGE)
	getrusage :: proc(who: Which_Usage, rusage: ^rusage) -> result ---
}

Which_Prio :: enum c.int {
	PROCESS = PRIO_PROCESS,
	PGRP    = PRIO_PGRP,
	USER    = PRIO_USER,
}

Which_Usage :: enum c.int {
	SELF     = RUSAGE_SELF,
	CHILDREN = RUSAGE_CHILDREN,
}

Resource :: enum c.int {
	// Maximum byte size of a core file that may be created by a process.
	CORE   = RLIMIT_CORE,
	// Maximum amount of CPU time, in seconds, used by a process.
	CPU    = RLIMIT_CPU,
	// Maximum size of data segment of the process, in bytes.
	DATA   = RLIMIT_DATA,
	// Maximum size of a file, in bytes, that may be created by a process.
	FSIZE  = RLIMIT_FSIZE,
	// A number one greater than the maximum value that the system may assign to a newly-created descriptor.
	NOFILE = RLIMIT_NOFILE,
	// The maximum size of the initial thread's stack, in bytes.
	STACK  = RLIMIT_STACK,
	// Maximum size of total available memory of the process, in bytes.
	AS     = RLIMIT_AS,
}

when ODIN_OS == .NetBSD {
	@(private) LGETRUSAGE :: "__getrusage50"
} else {
	@(private) LGETRUSAGE :: "getrusage"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	PRIO_PROCESS :: 0
	PRIO_PGRP    :: 1
	PRIO_USER    :: 2

	rlim_t :: distinct c.uint64_t

	RLIM_INFINITY  :: ~rlim_t(0) when ODIN_OS == .Linux else (rlim_t(1) << 63) - 1
	RLIM_SAVED_MAX :: RLIM_INFINITY
	RLIM_SAVED_CUR :: RLIM_INFINITY

	RUSAGE_SELF     :: 0
	RUSAGE_CHILDREN :: -1

	rlimit :: struct {
		rlim_cur: rlim_t, /* [PSX] the current (soft) limit */
		rlim_max: rlim_t, /* [PSX] the hard limit */
	}

	rusage :: struct {
		ru_utime: timeval, /* [PSX] user time used */
		ru_stime: timeval, /* [PSX] system time used */

		// Informational aliases for source compatibility with programs
		// that need more information than that provided by standards,
		// and which do not mind being OS-dependent.

		ru_maxrss:   c.long, /* max resident set size (PL) */
		ru_ixrss:    c.long, /* integral shared memory size (NU) */
		ru_idrss:    c.long, /* integral unshared data (NU) */
		ru_isrss:    c.long, /* integral unshared stack (NU) */
		ru_minflt:   c.long, /* page reclaims (NU) */
		ru_majflt:   c.long, /* page faults (NU) */
		ru_nswap:    c.long, /* swaps (NU) */
		ru_inblock:  c.long, /* block input operations (atomic) */
		ru_outblock: c.long, /* block output operations (atomic) */
		ru_msgsnd:   c.long, /* messages sent (atomic) */
		ru_msgrcv:   c.long, /* messages received (atomic) */
		ru_nsignals: c.long, /* signals received (atomic) */
		ru_nvcsw:    c.long, /* voluntary context switches (atomic) */
		ru_nivcsw:   c.long, /* involuntary " */
	}

	RLIMIT_CORE   :: 4
	RLIMIT_CPU    :: 0
	RLIMIT_DATA   :: 2
	RLIMIT_FSIZE  :: 1
	RLIMIT_NOFILE :: 7 when ODIN_OS == .Linux else 8
	RLIMIT_STACK  :: 3

	when ODIN_OS == .Linux {
		RLIMIT_AS :: 9
	} else when ODIN_OS == .Darwin || ODIN_OS == .OpenBSD {
		RLIMIT_AS :: 5
	} else {
		RLIMIT_AS :: 10
	}

} else {
	#panic("posix is unimplemented for the current target")
}
