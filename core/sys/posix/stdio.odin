#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// stdio.h - standard buffered input/output

foreign lib {
	/*
	Generates a string that, when used as a pathname,
	refers to the current controlling terminal for the current process.

	If s is nil, the returned string might be static and overwritten by subsequent calls or other factors.
	If s is not nil, s is assumed len(s) >= L_ctermid.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ctermid.html ]]
	*/
	ctermid :: proc(s: [^]byte) -> cstring ---

	/*
	Equivalent to fprintf but output is written to the file descriptor.

	Return: number of bytes written, negative (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dprintf.html ]]
	*/
	dprintf :: proc(fildse: FD, format: cstring, #c_vararg args: ..any) -> c.int ---

	/*
	Associate a stream with a file descriptor.

	Returns: nil (setting errno) on failure, the stream on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdopen.html ]]
	*/
	fdopen :: proc(fildes: FD, mode: cstring) -> ^FILE ---

	/*
	Map a stream pointer to a file descriptor.

	Returns: the file descriptor or -1 (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fileno.html ]]
	*/
	fileno :: proc(stream: ^FILE) -> FD ---

	/*
	Locks a file.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/flockfile.html ]]
	*/
	flockfile :: proc(file: ^FILE) ---

	/*
	Tries to lock a file.
	
	Returns: 0 if it could be locked, non-zero if it couldn't

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/flockfile.html ]]
	*/
	ftrylockfile :: proc(file: ^FILE) -> c.int ---

	/*
	Unlocks a file.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/flockfile.html ]]
	*/
	funlockfile :: proc(file: ^FILE) ---

	/*
	Open a memory buffer stream.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fmemopen.html ]]
	*/
	fmemopen :: proc(buf: [^]byte, size: c.size_t, mode: cstring) -> ^FILE ---

	/*
	Reposition a file-position indicator in a stream.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fseeko.html ]]
	*/
	fseeko :: proc(stream: ^FILE, offset: off_t, whence: Whence) -> result ---

	/*
	Return the file offset in a stream.

	Returns: the current file offset, -1 (setting errno) on error

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ftello.html ]]
	*/
	ftello :: proc(^FILE) -> off_t ---

	/*
	Open a dynamic memory buffer stream.

	Returns: nil (setting errno) on failure, the stream on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/open_memstream.html ]]
	*/
	open_memstream :: proc(bufp: ^[^]byte, sizep: ^c.size_t) -> ^FILE ---

	/*
	Read a delimited record from the stream.

	Returns: the number of bytes written or -1 on failure/EOF

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getdelim.html ]]
	*/
	getdelim :: proc(lineptr: ^cstring, n: ^c.size_t, delimiter: c.int, stream: ^FILE) -> c.ssize_t ---

	/*
	Read a line delimited record from the stream.

	Returns: the number of bytes written or -1 on failure/EOF

	Example:
		fp := posix.fopen(#file, "r")
		if fp == nil {
			posix.exit(1)
		}

		line: cstring
		length: uint
		for {
			read := posix.getline(&line, &length, fp)
			if read == -1 do break
			posix.printf("Retrieved line of length %zu :\n", read)
			posix.printf("%s", line)
		}
		if posix.ferror(fp) != 0 {
			/* handle error */
		}
		posix.free(rawptr(line))
		posix.fclose(fp)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getdelim.html ]]
	*/
	getline :: proc(lineptr: ^cstring, n: ^c.size_t, stream: ^FILE) -> c.ssize_t ---

	/*
	Equivalent to rename but relative directories are resolved from their respective fds.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/renameat.html ]]
	*/
	renameat :: proc(oldfd: FD, old: cstring, newfd: FD, new: cstring) -> result ---
}

when ODIN_OS == .Darwin {

	L_ctermid :: 1024
	L_tmpnam  :: 1024

	P_tmpdir :: "/var/tmp/"

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	L_ctermid :: 1024
	L_tmpnam  :: 1024

	P_tmpdir :: "/tmp/"

} else when ODIN_OS == .Linux {

	L_ctermid :: 20 // 20 on musl, 9 on glibc
	L_tmpnam  :: 20

	P_tmpdir :: "/tmp/"

}
