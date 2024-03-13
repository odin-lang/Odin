package os2

import "core:io"

to_stream :: proc(f: ^File) -> (s: io.Stream) {
	if f != nil {
		assert(f.stream.procedure != nil)
		s = f.stream
	}
	return
}

to_writer :: to_stream
to_reader :: to_stream


@(private)
error_to_io_error :: proc(ferr: Error) -> io.Error {
	if ferr == nil {
		return .None
	}
	return ferr.(io.Error) or_else .Unknown
}
