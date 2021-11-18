//+build js
package fmt

import "core:io"

foreign import "odin_env"

@(private="file")
foreign odin_env {
	write :: proc "c" (fd: u32, p: []byte) ---
}

@(private="file")
write_vtable := &io.Stream_VTable{
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		fd := u32(uintptr(s.stream_data))
		write(fd, p)
		return len(p), nil
	},	
}

@(private="file")
stdout := io.Writer{
	stream = {
		stream_vtable = write_vtable,
		stream_data = rawptr(uintptr(1)),
	},
}
@(private="file")
stderr := io.Writer{
	stream = {
		stream_vtable = write_vtable,
		stream_data = rawptr(uintptr(2)),
	},
}

// print* procedures return the number of bytes written
print   :: proc(args: ..any, sep := " ") -> int { return wprint(w=stdout, args=args, sep=sep) }
println :: proc(args: ..any, sep := " ") -> int { return wprintln(w=stdout, args=args, sep=sep) }
printf  :: proc(fmt: string, args: ..any) -> int { return wprintf(stdout, fmt, ..args) }

eprint   :: proc(args: ..any, sep := " ") -> int { return wprint(w=stderr, args=args, sep=sep) }
eprintln :: proc(args: ..any, sep := " ") -> int { return wprintln(w=stderr, args=args, sep=sep) }
eprintf  :: proc(fmt: string, args: ..any) -> int { return wprintf(stderr, fmt, ..args) }
