package os2

import "base:intrinsics"
import "base:runtime"
import "core:io"

// A subset of the io.Stream_Mode with added File specific modes
File_Stream_Mode :: enum {
	Close,
	Flush,
	Read,
	Read_At,
	Write,
	Write_At,
	Seek,
	Size,
	Destroy,
	Query, // query what modes are available on `io.Stream`

	Fstat, // File specific (not available on io.Stream)
}
#assert(intrinsics.type_is_superset_of(File_Stream_Mode, io.Stream_Mode))

// Superset interface of io.Stream_Proc with the added `runtime.Allocator` parameter needed for the Fstat mode
File_Stream_Proc :: #type proc(
	stream_data: rawptr,
	mode:        File_Stream_Mode,
	p:           []byte,
	offset:      i64,
	whence:      io.Seek_From,
	allocator:   runtime.Allocator,
) -> (n: i64, err: Error)

File_Stream :: struct {
	procedure: File_Stream_Proc,
	data:      rawptr,
}


// Converts a file `f` into an `io.Stream`
to_stream :: proc(f: ^File) -> (s: io.Stream) {
	if f != nil {
		assert(f.stream.procedure != nil)
		s = {
			file_io_stream_proc,
			f,
		}
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


@(private="package")
file_io_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^File)(stream_data)

	file_stream_mode := transmute(File_Stream_Mode)mode

	ferr: Error
	n, ferr = f.stream.procedure(f, file_stream_mode, p, offset, whence, runtime.nil_allocator())
	err = error_to_io_error(ferr)
	return
}

@(private="package")
file_stream_fstat_utility :: proc(f: ^File_Impl, p: []byte, allocator: runtime.Allocator) -> (err: Error) {
	fi: File_Info
	if len(p) >= size_of(fi) {
		fi, err = _fstat(&f.file, allocator)
		runtime.mem_copy_non_overlapping(raw_data(p), &fi, size_of(fi))
	} else {
		err = .Short_Buffer
	}
	return
}