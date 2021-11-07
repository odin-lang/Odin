//+build !freestanding !js
package fmt

import "core:runtime"
import "core:os"
import "core:io"

fprint :: proc(fd: os.Handle, args: ..any, sep := " ") -> int {
	w := io.to_writer(os.stream_from_handle(fd))
	return wprint(w=w, args=args, sep=sep)
}

fprintln :: proc(fd: os.Handle, args: ..any, sep := " ") -> int {
	w := io.to_writer(os.stream_from_handle(fd))
	return wprintln(w=w, args=args, sep=sep)
}
fprintf :: proc(fd: os.Handle, fmt: string, args: ..any) -> int {
	w := io.to_writer(os.stream_from_handle(fd))
	return wprintf(w, fmt, ..args)
}
fprint_type :: proc(fd: os.Handle, info: ^runtime.Type_Info) -> (n: int, err: io.Error) {
	w := io.to_writer(os.stream_from_handle(fd))
	return wprint_type(w, info)
}
fprint_typeid :: proc(fd: os.Handle, id: typeid) -> (n: int, err: io.Error) {
	w := io.to_writer(os.stream_from_handle(fd))
	return wprint_typeid(w, id)
}

// print* procedures return the number of bytes written
print   :: proc(args: ..any, sep := " ") -> int { return fprint(fd=os.stdout, args=args, sep=sep) }
println :: proc(args: ..any, sep := " ") -> int { return fprintln(fd=os.stdout, args=args, sep=sep) }
printf  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stdout, fmt, ..args) }

eprint   :: proc(args: ..any, sep := " ") -> int { return fprint(fd=os.stderr, args=args, sep=sep) }
eprintln :: proc(args: ..any, sep := " ") -> int { return fprintln(fd=os.stderr, args=args, sep=sep) }
eprintf  :: proc(fmt: string, args: ..any) -> int { return fprintf(os.stderr, fmt, ..args) }
