#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	// NOTE: iconv is in a different library
	foreign import lib "system:iconv"
} else {
	foreign import lib "system:c"
}

// iconv.h - codeset conversion facility

iconv_t :: distinct rawptr

foreign lib {
	/*
	Convert the sequence of characters from one codeset, in the array specified by inbuf,
	into a sequence of corresponding characters in another codeset, in the array specified by outbuf.

	Returns: -1 (setting errno) on failure, the number of non-identical conversions performed on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/iconv.html ]]
	*/
	iconv :: proc(
		cd:          iconv_t,
		inbuf:       ^[^]byte,
		inbytesleft: ^c.size_t,
		outbuf:      ^[^]byte,
		outbyteslen: ^c.size_t,
	) -> c.size_t ---

	/*
	Deallocates the conversion descriptor cd and all other associated resources allocated by iconv_open().

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/iconv_close.html ]]
	*/
	iconv_close :: proc(cd: iconv_t) -> result ---

	/*
	Returns a conversion descriptor that describes a conversion from the codeset specified by the
	string pointed to by the fromcode argument to the codeset specified by the string pointed to by
	the tocode argument.

	Returns: -1 (setting errno) on failure, a conversion descriptor on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/iconv_open.html ]]
	*/
	iconv_open :: proc(tocode: cstring, fromcode: cstring) -> iconv_t ---
}
