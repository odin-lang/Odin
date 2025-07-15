#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System"
} else {
	foreign import lib "system:c"
}

// string.h - string operations

// NOTE: most of the symbols in this header are not useful in Odin and have been left out.

foreign lib {
	/*
	Map the error number to a locale-dependent error message string and put it in the buffer.

	Returns: ERANGE if the buffer is not big enough

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/strerror_r.html ]]
	*/
	strerror_r :: proc(errnum: Errno, strerrbuf: [^]byte, buflen: c.size_t) -> Errno ---

	/*
	Map the signal number to an implementation-defined string.

	Returns: a string that may be invalidated by subsequent calls

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/strsignal.html ]]
	*/
	strsignal :: proc(sig: Signal) -> cstring ---
}
