package libc

when ODIN_OS == "windows" {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == "darwin" {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// 7.21 Input/output

FILE :: struct {}

// MSVCRT compatible.
when ODIN_OS == "windows" {
	_IOFBF       :: 0x0000
	_IONBF       :: 0x0004
	_IOLBF       :: 0x0040

	BUFSIZ       :: 512

	EOF          :: int(-1)

	FOPEN_MAX    :: 20

	FILENAME_MAX :: 260

	L_tmpnam     :: 15 // "\\" + 12 + NUL

	SEEK_SET     :: 0
	SEEK_CUR     :: 1
	SEEK_END     :: 2

	TMP_MAX      :: 32767 // SHRT_MAX

	fpos_t       :: distinct i64

	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		__acrt_iob_func :: proc (index: uint) -> ^FILE ---
	}

	stdin  := __acrt_iob_func(0)
	stdout := __acrt_iob_func(1)
	stderr := __acrt_iob_func(2)
}

// GLIBC and MUSL compatible.
when ODIN_OS == "linux" {
	fpos_t        :: struct #raw_union { _: [16]char, _: longlong, _: double, }

	_IOFBF        :: 0
	_IOLBF        :: 1
	_IONBF        :: 2

	BUFSIZ        :: 1024

	EOF           :: int(-1)

	FOPEN_MAX     :: 1000

	FILENAME_MAX  :: 4096

	L_tmpnam      :: 20

	SEEK_SET      :: 0
	SEEK_CUR      :: 1
	SEEK_END      :: 2

	TMP_MAX       :: 308915776

	foreign libc {
		stderr: ^FILE
		stdin:  ^FILE
		stdout: ^FILE
	}
}

when ODIN_OS == "darwin" {
	fpos_t :: distinct i64
	
	_IOFBF        :: 0
	_IOLBF        :: 1
	_IONBF        :: 2

	BUFSIZ        :: 1024

	EOF           :: int(-1)

	FOPEN_MAX     :: 20

	FILENAME_MAX  :: 1024

	L_tmpnam      :: 1024

	SEEK_SET      :: 0
	SEEK_CUR      :: 1
	SEEK_END      :: 2

	TMP_MAX       :: 308915776

	foreign libc {
		@(link_name="__stderrp") stderr: ^FILE
		@(link_name="__stdinp")  stdin:  ^FILE
		@(link_name="__stdoutp") stdout: ^FILE
	}
}

@(default_calling_convention="c")
foreign libc {
	// 7.21.4 Operations on files
	remove    :: proc(filename: cstring) -> int ---
	rename    :: proc(old, new: cstring) -> int ---
	tmpfile   :: proc() -> ^FILE ---
	tmpnam    :: proc(s: [^]char) -> [^]char ---

	// 7.21.5 File access functions
	fclose    :: proc(stream: ^FILE) -> int ---
	fflush    :: proc(stream: ^FILE) -> int ---
	fopen     :: proc(filename, mode: cstring) -> ^FILE ---
	freopen   :: proc(filename, mode: cstring, stream: ^FILE) -> ^FILE ---
	setbuf    :: proc(stream: ^FILE, buf: [^]char) ---
	setvbuf   :: proc(stream: ^FILE, buf: [^]char, mode: int, size: size_t) -> int ---

	// 7.21.6 Formatted input/output functions
	fprintf   :: proc(stream: ^FILE, format: cstring, #c_vararg args: ..any) -> int ---
	fscanf    :: proc(stream: ^FILE, format: cstring, #c_vararg args: ..any) -> int ---
	printf    :: proc(format: cstring, #c_vararg args: ..any) -> int ---
	scanf     :: proc(format: cstring, #c_vararg args: ..any) -> int ---
	snprintf  :: proc(s: [^]char, format: cstring, #c_vararg args: ..any) -> int ---
	sscanf    :: proc(s, format: cstring, #c_vararg args: ..any) -> int ---
	vfprintf  :: proc(stream: ^FILE, format: cstring, arg: ^va_list) -> int ---
	vfscanf   :: proc(stream: ^FILE, format: cstring, arg: ^va_list) -> int ---
	vprintf   :: proc(format: cstring, arg: ^va_list) -> int ---
	vscanf    :: proc(format: cstring, arg: ^va_list) -> int ---
	vsnprintf :: proc(s: [^]char, n: size_t, format: cstring, arg: ^va_list) -> int ---
	vsprintf  :: proc(s: [^]char, format: cstring, arg: ^va_list) -> int ---
	vsscanf   :: proc(s, format: cstring, arg: ^va_list) -> int ---

	// 7.21.7 Character input/output functions
	fgetc     :: proc(stream: ^FILE) -> int ---
	fgets     :: proc(s: [^]char, n: int, stream: ^FILE) -> [^]char ---
	fputc     :: proc(s: cstring, stream: ^FILE) -> int ---
	getc      :: proc(stream: ^FILE) -> int ---
	getchar   :: proc() -> int ---
	putc      :: proc(c: int, stream: ^FILE) -> int ---
	putchar   :: proc() -> int ---
	puts      :: proc(s: cstring) -> int ---
	ungetc    :: proc(c: int, stream: ^FILE) -> int ---
	fread     :: proc(ptr: rawptr, size: size_t, nmemb: size_t, stream: ^FILE) -> size_t ---
	fwrite    :: proc(ptr: rawptr, size: size_t, nmemb: size_t, stream: ^FILE) -> size_t ---

	// 7.21.9 File positioning functions
	fgetpos   :: proc(stream: ^FILE, pos: ^fpos_t) -> int ---
	fseek     :: proc(stream: ^FILE, offset: long, whence: int) -> int ---
	fsetpos   :: proc(stream: ^FILE, pos: ^fpos_t) -> int ---
	ftell     :: proc(stream: ^FILE) -> long ---
	rewind    :: proc(stream: ^FILE) ---

	// 7.21.10 Error-handling functions
	clearerr  :: proc(stream: ^FILE) ---
	feof      :: proc(stream: ^FILE) -> int ---
	ferror    :: proc(stream: ^FILE) -> int ---
	perror    :: proc(s: cstring) ---
}
