package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sched.h - execution scheduling

foreign lib {
	/*
	Returns the minimum for the given scheduling policy.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_get_priority_max.html ]]
	*/
	sched_get_priority_max :: proc(policy: Sched_Policy) -> c.int ---

	/*
	Returns the maximum for the given scheduling policy.

	Returns: -1 (setting errno) on failure, the maximum on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_get_priority_max.html ]]
	*/
	sched_get_priority_min :: proc(policy: Sched_Policy) -> c.int ---

	/*
	Forces the running thread to relinquish the processor until it again becomes the head of its thread list.
	*/
	sched_yield :: proc() -> result ---

	/* NOTE: unimplemented on darwin (I think?).
	/*
	Get the scheduling params of a process, pid of 0 will return that of the current process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_getparam.html ]]
	*/
	sched_getparam :: proc(pid: pid_t, param: ^sched_param) -> result ---
	/*
	Sets the scheduling parameters of the given process, pid of 0 will set that of the current process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_setparam.html ]]
	*/
	sched_setparam :: proc(pid: pid_t, param: ^sched_param) -> result ---

	/*
	Returns the scheduling policy of a process, pid of 0 will return that of the current process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_getscheduler.html ]]
	*/
	sched_getscheduler :: proc(pid: pid_t) -> Sched_Policy ---

	/*
	Sets the scheduling policy and parameters of the process, pid 0 will be the current process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_setscheduler.html ]]
	*/
	sched_setscheduler :: proc(pid: pid_t, policy: Sched_Policy, param: ^sched_param) -> result ---

	/*
	Updates the timespec structure to contain the current execution time limit for the process.
	pid of 0 will return that of the current process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sched_rr_get_interval.html ]]
	*/
	sched_rr_get_interval :: proc(pid: pid_t, interval: ^timespec) -> result ---
	*/
}

Sched_Policy :: enum c.int {
	// Error condition of sched_getscheduler.
	ERROR    = -1,
	// First in-first out (FIFO) scheduling policy.
	FIFO     = SCHED_FIFO,
	// Round robin scheduling policy.
	RR       = SCHED_RR,
	// Another scheduling policy.
	OTHER    = SCHED_OTHER,
}

when ODIN_OS == .Darwin {

	SCHED_FIFO     :: 4
	SCHED_RR       :: 2
	// SCHED_SPORADIC :: 3 NOTE: not a thing on freebsd, netbsd and probably others, leaving it out
	SCHED_OTHER    :: 1

} else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {

	SCHED_FIFO     :: 1
	SCHED_RR       :: 3
	SCHED_OTHER    :: 2

} else when ODIN_OS == .NetBSD || ODIN_OS == .Linux {

	SCHED_OTHER    :: 0
	SCHED_FIFO     :: 1
	SCHED_RR       :: 2

} else {
	#panic("posix is unimplemented for the current target")
}
