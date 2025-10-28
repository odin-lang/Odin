#+build !freestanding
#+build !js
#+build !orca
package fmt

import    "base:runtime"
import os "core:os/os2"
import    "core:io"
import    "core:bufio"

// NOTE(Jeroen): The other option is to deprecate `fprint*` and make it an alias for `wprint*`, using File.stream directly.

// fprint formats using the default print settings and writes to fd
fprint :: proc(f: ^os.File, args: ..any, sep := " ", flush := true) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, f.stream, buf[:])
	w := bufio.writer_to_writer(&b)
	return wprint(w, ..args, sep=sep, flush=flush)
}

// fprintln formats using the default print settings and writes to fd
fprintln :: proc(f: ^os.File, args: ..any, sep := " ", flush := true) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, f.stream, buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintln(w, ..args, sep=sep, flush=flush)
}
// fprintf formats according to the specified format string and writes to fd
fprintf :: proc(f: ^os.File, fmt: string, args: ..any, flush := true, newline := false) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, f.stream, buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintf(w, fmt, ..args, flush=flush, newline=newline)
}
// fprintfln formats according to the specified format string and writes to fd, followed by a newline.
fprintfln :: proc(f: ^os.File, fmt: string, args: ..any, flush := true) -> int {
	return fprintf(f, fmt, ..args, flush=flush, newline=true)
}
fprint_type :: proc(f: ^os.File, info: ^runtime.Type_Info, flush := true) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, f.stream, buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_type(w, info, flush=flush)
}
fprint_typeid :: proc(f: ^os.File, id: typeid, flush := true) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, f.stream, buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_typeid(w, id, flush=flush)
}

// print formats using the default print settings and writes to os.stdout
print    :: proc(args: ..any, sep := " ", flush := true) -> int { return fprint(os.stdout, ..args, sep=sep, flush=flush) }
// println formats using the default print settings and writes to os.stdout
println  :: proc(args: ..any, sep := " ", flush := true) -> int { return fprintln(os.stdout, ..args, sep=sep, flush=flush) }
// printf formats according to the specified format string and writes to os.stdout
printf   :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(os.stdout, fmt, ..args, flush=flush) }
// printfln formats according to the specified format string and writes to os.stdout, followed by a newline.
printfln :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(os.stdout, fmt, ..args, flush=flush, newline=true) }

// eprint formats using the default print settings and writes to os.stderr
eprint    :: proc(args: ..any, sep := " ", flush := true) -> int { return fprint(os.stderr, ..args, sep=sep, flush=flush) }
// eprintln formats using the default print settings and writes to os.stderr
eprintln  :: proc(args: ..any, sep := " ", flush := true) -> int { return fprintln(os.stderr, ..args, sep=sep, flush=flush) }
// eprintf formats according to the specified format string and writes to os.stderr
eprintf   :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(os.stderr, fmt, ..args, flush=flush) }
// eprintfln formats according to the specified format string and writes to os.stderr, followed by a newline.
eprintfln :: proc(fmt: string, args: ..any, flush := true) -> int { return fprintf(os.stderr, fmt, ..args, flush=flush, newline=true) }
