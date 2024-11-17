#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// sys/uio.h - definitions for vector I/O operations

foreign libc {
	/*
	Equivalent to read() but takes a vector of inputs.

	iovcnt can be 0..=IOV_MAX in length.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/readv.html ]]
	*/
	readv  :: proc(fildes: FD, iov: [^]iovec, iovcnt: c.int) -> c.ssize_t ---

	/*
	Equivalent to write() but takes a vector of inputs.

	iovcnt can be 0..=IOV_MAX in length.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/readv.html ]]
	*/
	writev :: proc(fildes: FD, iov: [^]iovec, iovcnt: c.int) -> c.ssize_t ---
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	iovec :: struct {
		iov_base: rawptr,   /* [PSX] base address of I/O memory region */
		iov_len:  c.size_t, /* [PSX] size of the region iov_base points to */
	}

}
