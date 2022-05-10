package os2

import "core:io"

file_to_stream :: proc(f: ^File) -> (s: io.Stream) {
	s.stream_data = f
	s.stream_vtable = _file_stream_vtable
	return
}

@(private)
error_to_io_error :: proc(ferr: Error) -> io.Error {
	if ferr == nil {
		return .None
	}
	return ferr.(io.Error) or_else .Unknown
}


@(private)
_file_stream_vtable := &io.Stream_VTable{
	impl_read = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		f := (^File)(s.stream_data)
		ferr: Error
		n, ferr = read(f, p)
		err = error_to_io_error(ferr)
		return
	},
	impl_read_at = proc(s: io.Stream, p: []byte, offset: i64) -> (n: int, err: io.Error) {
		f := (^File)(s.stream_data)
		ferr: Error
		n, ferr = read_at(f, p, offset)
		err = error_to_io_error(ferr)
		return
	},
	impl_write_to = proc(s: io.Stream, w: io.Writer) -> (n: i64, err: io.Error) {
		f := (^File)(s.stream_data)
		ferr: Error
		n, ferr = write_to(f, w)
		err = error_to_io_error(ferr)
		return
	},
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		f := (^File)(s.stream_data)
		ferr: Error
		n, ferr = write(f, p)
		err = error_to_io_error(ferr)
		return
	},
	impl_write_at = proc(s: io.Stream, p: []byte, offset: i64) -> (n: int, err: io.Error) {
		f := (^File)(s.stream_data)
		ferr: Error
		n, ferr = write_at(f, p, offset)
		err = error_to_io_error(ferr)
		return
	},
	impl_read_from = proc(s: io.Stream, r: io.Reader) -> (n: i64, err: io.Error) {
		f := (^File)(s.stream_data)
		ferr: Error
		n, ferr = read_from(f, r)
		err = error_to_io_error(ferr)
		return
	},
	impl_seek = proc(s: io.Stream, offset: i64, whence: io.Seek_From) -> (i64, io.Error) {
		f := (^File)(s.stream_data)
		n, ferr := seek(f, offset, Seek_From(whence))
		err := error_to_io_error(ferr)
		return n, err
	},
	impl_size = proc(s: io.Stream) -> i64 {
		f := (^File)(s.stream_data)
		sz, _ := file_size(f)
		return sz
	},
	impl_flush = proc(s: io.Stream) -> io.Error {
		f := (^File)(s.stream_data)
		ferr := flush(f)
		return error_to_io_error(ferr)
	},
	impl_close = proc(s: io.Stream) -> io.Error {
		f := (^File)(s.stream_data)
		ferr := close(f)
		return error_to_io_error(ferr)
	},
}
