//+build js
package fmt

import "core:io"

foreign import "odin_env"

@(private="file")
foreign odin_env {
	write :: proc "contextless" (fd: u32, p: []byte) ---
}

@(private="file")
write_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	if mode == .Write {
		fd := u32(uintptr(stream_data))
		write(fd, p)
		return i64(len(p)), nil
	}
	return 0, .Empty
}

@(private="file")
stdout := io.Writer{
	procedure = write_stream_proc,
	data      = rawptr(uintptr(1)),
}
@(private="file")
stderr := io.Writer{
	procedure = write_stream_proc,
	data      = rawptr(uintptr(2)),
}

// print formats using the default print settings and writes to stdout
print   :: proc(args: ..any, sep := " ", flush := true) -> int { return wprint(w=stdout, args=args, sep=sep, flush=flush) }
// println formats using the default print settings and writes to stdout
println :: proc(args: ..any, sep := " ", flush := true) -> int { return wprintln(w=stdout, args=args, sep=sep, flush=flush) }
// printf formats according to the specififed format string and writes to stdout
printf  :: proc(fmt: string, args: ..any, flush := true) -> int { return wprintf(stdout, fmt, ..args, flush=flush) }
// printfln formats according to the specified format string and writes to stdout, followed by a newline.
printfln :: proc(fmt: string, args: ..any, flush := true) -> int { return wprintf(stdout, fmt, ..args, flush=flush, newline=true) }

// eprint formats using the default print settings and writes to stderr
eprint   :: proc(args: ..any, sep := " ", flush := true) -> int { return wprint(w=stderr, args=args, sep=sep, flush=flush) }
// eprintln formats using the default print settings and writes to stderr
eprintln :: proc(args: ..any, sep := " ", flush := true) -> int { return wprintln(w=stderr, args=args, sep=sep, flush=flush) }
// eprintf formats according to the specififed format string and writes to stderr
eprintf  :: proc(fmt: string, args: ..any, flush := true) -> int { return wprintf(stderr, fmt, ..args, flush=flush) }
// eprintfln formats according to the specified format string and writes to stderr, followed by a newline.
eprintfln :: proc(fmt: string, args: ..any, flush := true) -> int { return wprintf(stdout, fmt, ..args, flush=flush, newline=true) }
