package os

import "core:io"

stream_from_handle :: proc(fd: Handle) -> io.Stream {
	s: io.Stream
	s.data = rawptr(uintptr(fd))
	s.procedure = _file_stream_proc
	return s
}


@(private)
_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	fd := Handle(uintptr(stream_data))
	n_int: int
	os_err: Error
	switch mode {
	case .Close:
		os_err = close(fd)
	case .Flush:
		os_err = flush(fd)
	case .Read:
		if len(p) == 0 {
			return 0, nil
		}
		n_int, os_err = read(fd, p)
		n = i64(n_int)
		if n == 0 && os_err == nil {
			err = .EOF
		}

	case .Read_At:
		if len(p) == 0 {
			return 0, nil
		}
		n_int, os_err = read_at(fd, p, offset)
		n = i64(n_int)
		if n == 0 && os_err == nil {
			err = .EOF
		}
	case .Write:
		if len(p) == 0 {
			return 0, nil
		}
		n_int, os_err = write(fd, p)
		n = i64(n_int)
		if n == 0 && os_err == nil {
			err = .EOF
		}
	case .Write_At:
		if len(p) == 0 {
			return 0, nil
		}
		n_int, os_err = write_at(fd, p, offset)
		n = i64(n_int)
		if n == 0 && os_err == nil {
			err = .EOF
		}
	case .Seek:
		n, os_err = seek(fd, offset, int(whence))
	case .Size:
		n, os_err = file_size(fd)
	case .Destroy:
		err = .Empty
	case .Query:
		return io.query_utility({.Close, .Flush, .Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Query})
	}

	if err == nil && os_err != nil {
		err = error_to_io_error(os_err)
	}
	if err != nil {
		n = 0
	}
	return
}
