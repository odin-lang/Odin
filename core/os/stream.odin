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
	os_err: Errno
	switch mode {
	case .Close:
		close(fd)
	case .Flush:
		when ODIN_OS == .Windows {
			flush(fd)
		} else {
			// TOOD(bill): other operating systems
		}
	case .Read:
		n_int, os_err = read(fd, p)
		n = i64(n_int)
		if n == 0 && os_err == 0 {
			err = .EOF
		}

	case .Read_At:
		when !(ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku) {
			n_int, os_err = read_at(fd, p, offset)
			n = i64(n_int)
			if n == 0 && os_err == 0 {
				err = .EOF
			}
		}
	case .Write:
		n_int, os_err = write(fd, p)
		n = i64(n_int)
		if n == 0 && os_err == 0 {
			err = .EOF
		}
	case .Write_At:
		when !(ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku) {
			n_int, os_err = write_at(fd, p, offset)
			n = i64(n_int)
			if n == 0 && os_err == 0 {
				err = .EOF
			}
		}
	case .Seek:
		n, os_err = seek(fd, offset, int(whence))
	case .Size:
		n, os_err = file_size(fd)
	case .Destroy:
		err = .Empty
	case .Query:
		when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku {
			return io.query_utility({.Close, .Flush, .Read, .Write, .Seek, .Size, .Query})
		} else {
			return io.query_utility({.Close, .Flush, .Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Query})
		}
	}

	if err == nil && os_err != 0 {
		when ODIN_OS == .Windows {
			if os_err == ERROR_HANDLE_EOF {
				return n, .EOF
			}
		}
		err = .Unknown
	}
	return
}
