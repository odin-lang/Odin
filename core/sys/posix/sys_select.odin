#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "base:intrinsics"

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/select.h - select types

foreign lib {
	/*
	Examines the file descriptor sets to see whether some of their descriptors are ready for writing,
	or have an exceptional condition pending, respectively.

	Returns: -1 (setting errno) on failure, total amount of bits set in the bit masks otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pselect.html ]]
	*/
	@(link_name=LPSELECT)
	pselect :: proc(
		nfds:     c.int,
		readfds:  ^fd_set,
		writefds: ^fd_set,
		errorfds: ^fd_set,
		timeout:  ^timespec,
		sigmask:  ^sigset_t,
	) -> c.int ---

	/*
	Equivalent to pselect() except a more specific timeout resolution (nanoseconds), 
	does not have a signal mask, and may modify the timeout.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pselect.html ]]
	*/
	@(link_name=LSELECT)
	select :: proc(
		nfds:     c.int,
		readfds:  ^fd_set,
		writefds: ^fd_set,
		errorfds: ^fd_set,
		timeout:  ^timeval,
	) -> c.int ---
}

when ODIN_OS == .NetBSD {
	LPSELECT :: "__pselect50"
	LSELECT  :: "__select50"
} else {
	LPSELECT :: "pselect"
	LSELECT  :: "select"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	suseconds_t :: distinct (c.int32_t when ODIN_OS == .Darwin || ODIN_OS == .NetBSD else c.long)

	timeval :: struct {
		tv_sec:  time_t,      /* [PSX] seconds */
		tv_usec: suseconds_t, /* [PSX] microseconds */
	}

	// Maximum number of file descriptors in the fd_set structure.
	FD_SETSIZE :: #config(POSIX_FD_SETSIZE, 256 when ODIN_OS == .NetBSD else 1024)

	@(private)
	__NFDBITS :: size_of(c.int32_t) * 8

	// NOTE: this seems correct for FreeBSD but they do use a set backed by the long type themselves (thus the align change).
	@(private)
	ALIGN ::  align_of(c.long) when ODIN_OS == .FreeBSD || ODIN_OS == .Linux else align_of(c.int32_t)

	fd_set :: struct #align(ALIGN) {
		fds_bits: [(FD_SETSIZE / __NFDBITS) when (FD_SETSIZE % __NFDBITS) == 0 else (FD_SETSIZE / __NFDBITS) + 1]c.int32_t,
	}

	@(private)
	__check_fd_set :: #force_inline proc "contextless" (_a: FD, _b: rawptr) -> bool {
		if _a < 0 {
			set_errno(.EINVAL)
		}

		if _a >= FD_SETSIZE {
			set_errno(.EINVAL)
		}

		return true
	}

	FD_CLR :: #force_inline proc "contextless" (_fd: FD, _p: ^fd_set) {
		if __check_fd_set(_fd, _p) {
			_p.fds_bits[cast(c.ulong)_fd / __NFDBITS] &= ~cast(c.int32_t)((cast(c.ulong)1) << (cast(c.ulong)_fd % __NFDBITS))
		}
	}

	FD_ISSET :: #force_inline proc "contextless" (_fd: FD, _p: ^fd_set) -> bool {
		if __check_fd_set(_fd, _p) {
			return bool(_p.fds_bits[cast(c.ulong)_fd / __NFDBITS] & cast(c.int32_t)((cast(c.ulong)1) << (cast(c.ulong)_fd % __NFDBITS)))
		}

		return false
	}

	FD_SET :: #force_inline proc "contextless" (_fd: FD, _p: ^fd_set) {
		if __check_fd_set(_fd, _p) {
			_p.fds_bits[cast(c.ulong)_fd / __NFDBITS] |= cast(c.int32_t)((cast(c.ulong)1) << (cast(c.ulong)_fd % __NFDBITS))
		}
	}

	FD_ZERO :: #force_inline proc "contextless" (_p: ^fd_set) {
		intrinsics.mem_zero(_p, size_of(fd_set))
	}

}
