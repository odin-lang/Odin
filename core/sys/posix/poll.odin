package posix

import "base:intrinsics"

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// poll.h - definitions for the poll() function

foreign lib {
	/*
	For each pointer in fds, poll() shall examine the given descriptor for the events.
	poll will identify on which descriptors writes or reads can be done.

	Returns: -1 (setting errno) on failure, 0 on timeout, the amount of fds that have been changed on success.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/poll.html ]]
	*/
	poll :: proc(fds: [^]pollfd, nfds: nfds_t, timeout: c.int) -> c.int ---
}

nfds_t :: c.uint

Poll_Event_Bits :: enum c.short {
	// Data other than high-priority data may be read without blocking.
	IN     = log2(POLLIN),
	// Normal data may be read without blocking.
	RDNORM = log2(POLLRDNORM),
	// Priority data may be read without blocking.
	RDBAND = log2(POLLRDBAND),
	// High priority data may be read without blocking.
	PRI    = log2(POLLPRI),

	// Normal data may be written without blocking.
	OUT    = log2(POLLOUT),
	// Equivalent to POLLOUT.
	WRNORM = log2(POLLWRNORM),
	// Priority data may be written.
	WRBAND = log2(POLLWRBAND),

	// An error has occurred (revents only).
	ERR  = log2(POLLERR),
	// Device hsa been disconnected (revents only).
	HUP  = log2(POLLHUP),
	// Invalid fd member (revents only).
	NVAL = log2(POLLNVAL),
}
Poll_Event :: bit_set[Poll_Event_Bits; c.short]

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	pollfd :: struct {
		fd:      FD,         /* [PSX] the following descriptor being polled */
		events:  Poll_Event, /* [PSX] the input event flags */
		revents: Poll_Event, /* [PSX] the output event flags */
	}

	POLLIN     :: 0x0001
	POLLRDNORM :: 0x0040
	POLLRDBAND :: 0x0080
	POLLPRI    :: 0x0002
	POLLOUT    :: 0x0004
	POLLWRNORM :: POLLOUT
	POLLWRBAND :: 0x0100

	POLLERR    :: 0x0008
	POLLHUP    :: 0x0010
	POLLNVAL   :: 0x0020

} else {
	#panic("posix is unimplemented for the current target")
}

