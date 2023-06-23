//+build !freestanding !js
package fmt

import "core:runtime"
import "core:os"
import "core:io"
import "core:bufio"

// fprint formats using the default print settings and writes to fd
fprint :: proc(fd: os.Handle, args: ..any, sep := " ") -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])
	w := bufio.writer_to_writer(&b)
	return wprint(w, ..args, sep=sep)
}

// fprintln formats using the default print settings and writes to fd
fprintln :: proc(fd: os.Handle, args: ..any, sep := " ") -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintln(w, ..args, sep=sep)
}
// fprintf formats according to the specified format string and writes to fd
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any) -> int {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintf(w, fmt, ..args)
}
fprint_type :: proc(fd: os.Handle, info: ^runtime.Type_Info) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_type(w, info)
}
fprint_typeid :: proc(fd: os.Handle, id: typeid) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_typeid(w, id)
}

// print formats using the default print settings and writes to os.stdout
print   :: proc(args: ..any, sep := " ") -> int { return fprint(os.stdout, ..args, sep=sep) }
// println formats using the default print settings and writes to os.stdout
println :: proc(args: ..any, sep := " ") -> int { return fprintln(os.stdout, ..args, sep=sep) }
// printf formats according to the specified format string and writes to os.stdout
printf  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stdout, fmt, ..args) }

// eprint formats using the default print settings and writes to os.stderr
eprint   :: proc(args: ..any, sep := " ") -> int { return fprint(os.stderr, ..args, sep=sep) }
// eprintln formats using the default print settings and writes to os.stderr
eprintln :: proc(args: ..any, sep := " ") -> int { return fprintln(os.stderr, ..args, sep=sep) }
// eprintf formats according to the specified format string and writes to os.stderr
eprintf  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stderr, fmt, ..args) }
