#+build !freestanding
#+build !js
#+build !orca
package fmt

import "base:runtime"
import "core:os"
import "core:io"
import "core:bufio"

// NOTE(Jeroen): The other option is to deprecate `fprint*` and make it an alias for `wprint*`, using File.stream directly.

// Formats using the default print settings and writes to ^os.File.
fprint :: proc(f: ^os.File, args: ..any, sep := " ", flush := true) -> (bytes_written: int) {
	buf: [1024]byte
	b: bufio.Writer

	bufio.writer_init_with_buf(&b, os.to_stream(f), buf[:])
	w := bufio.writer_to_writer(&b)
	return wprint(w, ..args, sep=sep, flush=flush)
}

// Formats using the default print settings and writes to ^os.File.
fprintln :: proc(f: ^os.File, args: ..any, sep := " ", flush := true) -> (bytes_written: int) {
	buf: [1024]byte
	b: bufio.Writer

	bufio.writer_init_with_buf(&b, os.to_stream(f), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintln(w, ..args, sep=sep, flush=flush)
}

// Formats according to the specified format string and writes to ^os.File.
fprintf :: proc(f: ^os.File, fmt: string, args: ..any, flush := true, newline := false) -> (bytes_written: int) {
	buf: [1024]byte
	b: bufio.Writer

	bufio.writer_init_with_buf(&b, os.to_stream(f), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprintf(w, fmt, ..args, flush=flush, newline=newline)
}

// Formats according to the specified format string and writes to ^os.File, followed by a newline.
fprintfln :: proc(f: ^os.File, fmt: string, args: ..any, flush := true) -> (bytes_written: int) {
	return fprintf(f, fmt, ..args, flush=flush, newline=true)
}

// Writes a ^runtime.Type_Info value to a ^os.File.
fprint_type :: proc(f: ^os.File, info: ^runtime.Type_Info, flush := true) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer

	bufio.writer_init_with_buf(&b, os.to_stream(f), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_type(w, info, flush=flush)
}

// Writes a typeid value to a ^os.File.
fprint_typeid :: proc(f: ^os.File, id: typeid, flush := true) -> (n: int, err: io.Error) {
	buf: [1024]byte
	b: bufio.Writer

	bufio.writer_init_with_buf(&b, os.to_stream(f), buf[:])

	w := bufio.writer_to_writer(&b)
	return wprint_typeid(w, id, flush=flush)
}

// Formats using the default print settings and writes to os.stdout.
print     :: proc(args: ..any, sep := " ",  flush := true) -> (bytes_written: int) { return fprint(os.stdout, ..args, sep=sep, flush=flush) }

// Formats using the default print settings and writes to os.stdout.
println   :: proc(args: ..any, sep := " ",  flush := true) -> (bytes_written: int) { return fprintln(os.stdout, ..args, sep=sep, flush=flush) }

// Formats according to the specified format string and writes to os.stdout.
printf    :: proc(fmt: string, args: ..any, flush := true) -> (bytes_written: int) { return fprintf(os.stdout, fmt, ..args, flush=flush) }

// Formats according to the specified format string and writes to os.stdout, followed by a newline.
printfln  :: proc(fmt: string, args: ..any, flush := true) -> (bytes_written: int) { return fprintf(os.stdout, fmt, ..args, flush=flush, newline=true) }

// Formats using the default print settings and writes to os.stderr.
eprint    :: proc(args: ..any, sep := " ",  flush := true) -> (bytes_written: int) { return fprint(os.stderr, ..args, sep=sep, flush=flush) }

// Formats using the default print settings and writes to os.stderr.
eprintln  :: proc(args: ..any, sep := " ",  flush := true) -> (bytes_written: int) { return fprintln(os.stderr, ..args, sep=sep, flush=flush) }

// Formats according to the specified format string and writes to os.stderr.
eprintf   :: proc(fmt: string, args: ..any, flush := true) -> (bytes_written: int) { return fprintf(os.stderr, fmt, ..args, flush=flush) }

// Formats according to the specified format string and writes to os.stderr, followed by a newline.
eprintfln :: proc(fmt: string, args: ..any, flush := true) -> (bytes_written: int) { return fprintf(os.stderr, fmt, ..args, flush=flush, newline=true) }
