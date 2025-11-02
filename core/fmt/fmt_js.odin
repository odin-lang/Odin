#+build js
package fmt

import "core:strings"

foreign import "odin_env"

@(private="file")
foreign odin_env {
	write :: proc "contextless" (fd: u32, p: []byte) ---
}

stdout :: u32(1)
stderr :: u32(2)

@(private="file")
BUF_SIZE :: 1024

@(private="file")
// TODO: Find a way to grow this if necessary
buf: [BUF_SIZE]byte

@(private="file")
get_fd :: proc(f: any, loc := #caller_location) -> (fd: u32) {
	if _fd, _ok := f.(u32); _ok {
		fd = _fd
	}
	if fd != 1 && fd != 2 {
		panic("`fmt.fprint` variant called with invalid file descriptor for JS, only 1 (stdout) and 2 (stderr) are supported", loc)
	}
	return fd
}

// fprint formats using the default print settings and writes to fd
// flush is ignored
fprint :: proc(f: any, args: ..any, sep := " ", flush := true, loc := #caller_location) -> (n: int) {
	fd := get_fd(f)
	s := bprint(buf[:], ..args, sep=sep)
	n = len(s)
	write(fd, transmute([]byte)s)
	return n
}

// fprintln formats using the default print settings and writes to fd, followed by a newline
// flush is ignored
fprintln :: proc(f: any, args: ..any, sep := " ", flush := true, loc := #caller_location) -> (n: int) {
	fd := get_fd(f)
	s := bprintln(buf[:], ..args, sep=sep)
	n = len(s)
	write(fd, transmute([]byte)s)
	return n
}

// fprintf formats according to the specified format string and writes to fd
// flush is ignored
fprintf :: proc(f: any, fmt: string, args: ..any, flush := true, newline := false, loc := #caller_location) -> (n: int) {
	fd := get_fd(f)
	s := bprintf(buf[:], fmt, ..args, newline=newline)
	n = len(s)
	write(fd, transmute([]byte)s)
	return n
}

// fprintfln formats according to the specified format string and writes to fd, followed by a newline.
// flush is ignored
fprintfln :: proc(f: any, fmt: string, args: ..any, flush := true, loc := #caller_location) -> int {
	return fprintf(f, fmt, ..args, flush=flush, newline=true, loc=loc)
}

// print formats using the default print settings and writes to stdout
print   :: proc(args: ..any, sep := " ", flush := true) -> int { return fprint(stdout, ..args, sep=sep, flush=flush) }
// println formats using the default print settings and writes to stdout
println :: proc(args: ..any, sep := " ", flush := true) -> int { return fprintln(stdout, ..args, sep=sep, flush=flush) }
// printf formats according to the specififed format string and writes to stdout
printf  :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(stdout, fmt, ..args, flush=flush) }
// printfln formats according to the specified format string and writes to stdout, followed by a newline.
printfln :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(stdout, fmt, ..args, flush=flush, newline=true) }

// eprint formats using the default print settings and writes to stderr
eprint   :: proc(args: ..any, sep := " ", flush := true) -> int { return fprint(stderr, ..args, sep=sep, flush=flush) }
// eprintln formats using the default print settings and writes to stderr
eprintln :: proc(args: ..any, sep := " ", flush := true) -> int { return fprintln(stderr, ..args, sep=sep, flush=flush) }
// eprintf formats according to the specififed format string and writes to stderr
eprintf  :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(stderr, fmt, ..args, flush=flush) }
// eprintfln formats according to the specified format string and writes to stderr, followed by a newline.
eprintfln :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(stderr, fmt, ..args, flush=flush, newline=true) }