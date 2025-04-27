#+build linux, windows, linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"
import "core:c/libc"

when ODIN_OS == .Windows {
	foreign import lib {
		"system:libucrt.lib",
		"system:legacy_stdio_definitions.lib",
	}
} else when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// stdio.h - standard buffered input/output

when ODIN_OS == .Windows {
	@(private) LGETC_UNLOCKED    :: "_getc_nolock"
	@(private) LGETCHAR_UNLOCKED :: "_getchar_nolock"
	@(private) LPUTC_UNLOCKED    :: "_putc_nolock"
	@(private) LPUTCHAR_UNLOCKED :: "_putchar_nolock"
	@(private) LTEMPNAM          :: "_tempnam"
	@(private) LPOPEN            :: "_popen"
	@(private) LPCLOSE           :: "_pclose"
} else {
	@(private) LGETC_UNLOCKED    :: "getc_unlocked"
	@(private) LGETCHAR_UNLOCKED :: "getchar_unlocked"
	@(private) LPUTC_UNLOCKED    :: "putc_unlocked"
	@(private) LPUTCHAR_UNLOCKED :: "putchar_unlocked"
	@(private) LTEMPNAM          :: "tempnam"
	@(private) LPOPEN            :: "popen"
	@(private) LPCLOSE           :: "pclose"
}

foreign lib {
	/*
	Equivalent to fprintf but output is written to s, it is the user's responsibility to
	ensure there is enough space.

	Return: number of bytes written, negative (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dprintf.html ]]
	*/
	sprintf :: proc(s: [^]byte, format: cstring, #c_vararg args: ..any) -> c.int ---

	/*
	Equivalent to getc but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	@(link_name=LGETC_UNLOCKED)
	getc_unlocked :: proc(stream: ^FILE) -> c.int ---

	/*
	Equivalent to getchar but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	@(link_name=LGETCHAR_UNLOCKED)
	getchar_unlocked :: proc() -> c.int ---

	/*
	Equivalent to putc but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	@(link_name=LPUTC_UNLOCKED)
	putc_unlocked :: proc(ch: c.int, stream: ^FILE) -> c.int ---

	/*
	Equivalent to putchar but unaffected by locks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getc_unlocked.html ]]
	*/
	@(link_name=LPUTCHAR_UNLOCKED)
	putchar_unlocked :: proc(ch: c.int) -> c.int ---

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
	@(link_name=LTEMPNAM)
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
	@(link_name=LPOPEN)
	popen :: proc(command: cstring, mode: cstring) -> ^FILE ---

	/*
	Closes a pipe stream to or from a process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pclose.html ]]	
	*/
	@(link_name=LPCLOSE)
	pclose :: proc(stream: ^FILE) -> c.int ---
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
