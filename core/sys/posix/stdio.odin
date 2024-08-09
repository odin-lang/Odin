package posix

import "core:c"
import "core:c/libc"

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
	Equivalent to fprintf but output is written to s, it is the user's responsibility to
	ensure there is enough space.

	Return: number of bytes written, negative (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dprintf.html ]]
	*/
	sprintf :: proc(s: [^]byte, format: cstring, #c_vararg args: ..any) -> c.int ---

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
	Equivalent to getc but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	getc_unlocked :: proc(stream: ^FILE) -> c.int ---

	/*
	Equivalent to getchar but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	getchar_unlocked :: proc() -> c.int ---

	/*
	Equivalent to putc but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	putc_unlocked :: proc(ch: c.int, stream: ^FILE) -> c.int ---

	/*
	Equivalent to putchar but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	putchar_unlocked :: proc(ch: c.int) -> c.int ---

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
	Get a string from the stdin stream.

	It is up to the user to make sure s is big enough.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/gets.html ]]
	*/
	gets :: proc(s: [^]byte) -> cstring ---

	/*
	Create a name for a temporary file.

	Returns: an allocated cstring that needs to be freed, nil on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tempnam.html ]]
	*/
	tempnam :: proc(dir: cstring, pfx: cstring) -> cstring ---

	/*
	Executes the command specified, creating a pipe and returning a pointer to a stream that can 
	read or write from/to the pipe.

	Returns: nil (setting errno) on failure or a pointer to the stream

	Example:
		fp := posix.popen("ls *", "r")
		if fp == nil {
			/* Handle error */
		}

		path: [1024]byte
		for posix.fgets(raw_data(path[:]), len(path), fp) != nil {
			posix.printf("%s", &path)
		}

		status := posix.pclose(fp)
		if status == -1 {
			/* Error reported by pclose() */
		} else {
			/* Use functions described under wait() to inspect `status` in order
			   to determine success/failure of the command executed by popen() */
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/popen.html ]]
	*/
	popen :: proc(command: cstring, mode: cstring) -> ^FILE ---

	/*
	Closes a pipe stream to or from a process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pclose.html ]]	
	*/
	pclose :: proc(stream: ^FILE) -> c.int ---

	/*
	Equivalent to rename but relative directories are resolved from their respective fds.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/renameat.html ]]
	*/
	renameat :: proc(oldfd: FD, old: cstring, newfd: FD, new: cstring) -> result ---
}

clearerr  :: libc.clearerr
fclose    :: libc.fclose
feof      :: libc.feof
ferror    :: libc.ferror
fflush    :: libc.fflush
fgetc     :: libc.fgetc
fgetpos   :: libc.fgetpos
fgets     :: libc.fgets
fopen     :: libc.fopen
fprintf   :: libc.fprintf
fputc     :: libc.fputc
fread     :: libc.fread
freopen   :: libc.freopen
fscanf    :: libc.fscanf
fseek     :: libc.fseek
fsetpos   :: libc.fsetpos
ftell     :: libc.ftell
fwrite    :: libc.fwrite
getc      :: libc.getc
getchar   :: libc.getchar
perror    :: libc.perror
printf    :: libc.printf
putc      :: libc.puts
putchar   :: libc.putchar
puts      :: libc.puts
remove    :: libc.remove
rename    :: libc.rename
rewind    :: libc.rewind
scanf     :: libc.scanf
setbuf    :: libc.setbuf
setvbuf   :: libc.setvbuf
snprintf  :: libc.snprintf
sscanf    :: libc.sscanf
tmpfile   :: libc.tmpfile
tmpnam    :: libc.tmpnam
vfprintf  :: libc.vfprintf
vfscanf   :: libc.vfscanf
vprintf   :: libc.vprintf
vscanf    :: libc.vscanf
vsnprintf :: libc.vsnprintf
vsprintf  :: libc.vsprintf
vsscanf   :: libc.vsscanf
ungetc    :: libc.ungetc

to_stream :: libc.to_stream

Whence :: libc.Whence
FILE   :: libc.FILE
fpos_t :: libc.fpos_t

BUFSIZ :: libc.BUFSIZ

_IOFBF :: libc._IOFBF
_IOLBF :: libc._IOLBF
_IONBF :: libc._IONBF

SEEK_CUR :: libc.SEEK_CUR
SEEK_END :: libc.SEEK_END
SEEK_SET :: libc.SEEK_SET

FILENAME_MAX :: libc.FILENAME_MAX
FOPEN_MAX    :: libc.FOPEN_MAX
TMP_MAX      :: libc.TMP_MAX

EOF :: libc.EOF

stderr := libc.stderr
stdin  := libc.stdin
stdout := libc.stdout

when ODIN_OS == .Darwin {

	L_ctermid :: 1024
	L_tmpnam  :: 1024

	P_tmpdir :: "/var/tmp/"

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	L_ctermid :: 1024
	L_tmpnam  :: 1024

	P_tmpdir :: "/tmp/"

} else {
	#panic("posix is unimplemented for the current target")
}
