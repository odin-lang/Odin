//+build js
package fmt

import "core:io"

foreign import "odin_env"

@(private="file")
foreign odin_env {
	write :: proc "contextless" (fd: u32, p: []byte) ---
}

@(private="file")
write_vtable := io.Stream_VTable{
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		fd := u32(uintptr(s.stream_data))
		write(fd, p)
		return len(p), nil
	},	
}

@(private="file")
stdout := io.Writer{
	stream = {
		stream_vtable = &write_vtable,
		stream_data = rawptr(uintptr(1)),
	},
}
@(private="file")
stderr := io.Writer{
	stream = {
		stream_vtable = &write_vtable,
		stream_data = rawptr(uintptr(2)),
	},
}

// print formats using the default print settings and writes to stdout
print   :: proc(args: ..any, sep := " ") -> int { return wprint(w=stdout, args=args, sep=sep) }
// println formats using the default print settings and writes to stdout
println :: proc(args: ..any, sep := " ") -> int { return wprintln(w=stdout, args=args, sep=sep) }
// printf formats according to the specififed format string and writes to stdout
printf  :: proc(fmt: string, args: ..any) -> int { return wprintf(stdout, fmt, ..args) }

// eprint formats using the default print settings and writes to stderr
eprint   :: proc(args: ..any, sep := " ") -> int { return wprint(w=stderr, args=args, sep=sep) }
// eprintln formats using the default print settings and writes to stderr
eprintln :: proc(args: ..any, sep := " ") -> int { return wprintln(w=stderr, args=args, sep=sep) }
// eprintf formats according to the specififed format string and writes to stderr
eprintf  :: proc(fmt: string, args: ..any) -> int { return wprintf(stderr, fmt, ..args) }
