//+build !freestanding
//+build !js
package fmt

import "base:runtime"
import "core:os"
import "core:io"
import "core:bufio"

// fprint formats using the default print settings and writes to fd
fprint :: proc(fd: os.Handle, args: ..any, sep := " ", flush := true) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])
	w := bufio.writer_to_writer(&b)
	return wprint(w, ..args, sep=sep, flush=flush)
}

// fprintln formats using the default print settings and writes to fd
fprintln :: proc(fd: os.Handle, args: ..any, sep := " ", flush := true) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintln(w, ..args, sep=sep, flush=flush)
}
// fprintf formats according to the specified format string and writes to fd
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any, flush := true, newline := false) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintf(w, fmt, ..args, flush=flush, newline=newline)
}
// fprintfln formats according to the specified format string and writes to fd, followed by a newline.
fprintfln :: proc(fd: os.Handle, fmt: string, args: ..any, flush := true) -> int {
	return fprintf(fd, fmt, ..args, flush=flush, newline=true)
}
fprint_type :: proc(fd: os.Handle, info: ^runtime.Type_Info, flush := true) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_type(w, info, flush=flush)
}
fprint_typeid :: proc(fd: os.Handle, id: typeid, flush := true) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

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
