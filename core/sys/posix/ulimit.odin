package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// ulimit.h - ulimit commands

foreign lib {
	/*
	Control process limits.

	Note that -1 is a valid return value, applications should clear errno, do this call and then
	check both -1 and the errno to determine status.

	Returns: -1 (setting errno) on failure.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ulimit.html ]]
	*/
	ulimit :: proc(i: c.int, #c_vararg arg: ..c.long) -> c.long ---
}

Ulimit_Cmd :: enum c.int {
	// Returns the file size limit of the process in units of 512-byte blocks inherited by children.
	GETFSIZE = UL_GETFSIZE,
	// Set the file size limit for output operations, taken as a long, multiplied by 512.
	SETFSIZE = UL_SETFSIZE,
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	UL_GETFSIZE :: 1
	UL_SETFSIZE :: 2

	// NOTE: I don't think OpenBSD implements this API.

} else {
	#panic("posix is unimplemented for the current target")
}
