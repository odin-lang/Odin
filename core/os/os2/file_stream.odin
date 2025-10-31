package os2

import "core:io"

// Converts a file `f` into an `io.Stream`
to_stream :: proc(f: ^File) -> (s: io.Stream) {
	if f != nil {
		assert(f.stream.procedure != nil)
		s = f.stream
	}
	return
}

/*
	This is an alias of `to_stream` which converts a file `f` to an `io.Stream`.
	It can be useful to indicate what the stream is meant to be used for as a writer,
	even if it has no logical difference.
*/
to_writer :: to_stream

/*
	This is an alias of `to_stream` which converts a file `f` to an `io.Stream`.
	It can be useful to indicate what the stream is meant to be used for as a reader,
	even if it has no logical difference.
*/
to_reader :: to_stream
