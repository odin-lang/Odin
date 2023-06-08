package os2

import "core:io"

to_stream :: proc(f: ^File) -> (s: io.Stream) {
	s.data = f
	s.procedure = _file_stream_proc
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


@(private)
_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^File)(stream_data)
	ferr: Error
	i: int
	switch mode {
	case .Read:
		i, ferr = read(f, p)
		n = i64(i)
		err = error_to_io_error(ferr)
		return
	case .Read_At:
		i, ferr = read_at(f, p, offset)
		n = i64(i)
		err = error_to_io_error(ferr)
		return
	case .Write:
		i, ferr = write(f, p)
		n = i64(i)
		err = error_to_io_error(ferr)
		return
	case .Write_At:
		i, ferr = write_at(f, p, offset)
		n = i64(i)
		err = error_to_io_error(ferr)
		return
	case .Seek:
		n, ferr = seek(f, offset, Seek_From(whence))
		err = error_to_io_error(ferr)
		return
	case .Size:
		n, ferr = file_size(f)
		err = error_to_io_error(ferr)
		return
	case .Flush:
		ferr = flush(f)
		err = error_to_io_error(ferr)
		return
	case .Close:
		ferr = close(f)
		err = error_to_io_error(ferr)
		return
	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Flush, .Close, .Query})
	case .Destroy:
		return 0, .Empty
	}
	return 0, .Empty
}

