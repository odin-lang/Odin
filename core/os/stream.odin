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
        for {
            // NOTE(flysand): Unix-likes sometimes can not restart syscalls on
            // their own in case an interrupt comes. In such cases we need to
            // manually restart the syscall if EINTR is returned.
    		os_err = close(fd)
            when ODIN_OS == .Linux || ODIN_OS == .OpenBSD || ODIN_OS == .FreeBSD {
                if os_err == EINTR {
                    continue
                } else if os_err != ERROR_NONE {
                    err = .Unknown
                }
            }
        }
        break
	case .Flush:
		when ODIN_OS == .Windows {
			os_err = flush(fd)
		} else {
			// TOOD(bill): other operating systems
		}
	case .Read:
        when ODIN_OS == .Windows {
            n_int, os_err = read(fd, p)
            n = i64(n_int)
        } else {
            for true {
        		n_int, os_err = read(fd, p)
        		n = i64(n_int)
                if os_err == EINTR {
                    continue
                } else if os_err != ERROR_NONE {
                    err = .Unknown
                }
                break
            }
        }
        if err == .None && n < cast(i64)len(p) {
            err = .Short_Buffer
        }
	case .Read_At:
        when ODIN_OS == .Linux || ODIN_OS == .Darwin {
            for true {
                n_int, os_err = read_at(fd, p, offset)
                n = i64(n_int)
                if os_err == EINTR {
                    continue
                } else if os_err != ERROR_NONE {
                    err = .Unknown
                }
                break
            }
        } else when !(ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD) {
			n_int, os_err = read_at(fd, p, offset)
			n = i64(n_int)
		} else {
            err = .Empty
        }
        if err == .None && n < cast(i64)len(p) {
            err = .Short_Buffer
        }
	case .Write:
        when ODIN_OS == .Windows {
    		n_int, os_err = write(fd, p)
    		n = i64(n_int)
        } else {
            for true {
                n_int, os_err = write(fd, p)
                n = i64(n_int)
                if os_err == EINTR {
                    continue
                } else if os_err != ERROR_NONE {
                    err = .Unknown
                }
                break
            }
        }
	case .Write_At:
        when ODIN_OS == .Linux || ODIN_OS == .Darwin {
            for true {
                n_int, os_err = write_at(fd, p, offset)
                n = i64(n_int)
                if os_err == EINTR {
                    continue
                } else if os_err != ERROR_NONE {
                    err = .Unknown
                }
                break
            }
        } else when !(ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD) {
			n_int, os_err = write_at(fd, p, offset)
			n = i64(n_int)
		} else {
            err = .Empty
        }
	case .Seek:
		n, os_err = seek(fd, offset, int(whence))
        when ODIN_OS != .Windows {
            if os_err == EINVAL {
                // NOTE(flysand): Not sure if it should be Invalid_Whence
                // or Invlaid_Offset
                err = .Invalid_Whence
            }
        }
	case .Size:
        if ODIN_OS == .Windows {
    		n, os_err = file_size(fd)
        } else {
            // NOTE(flysand): Ironically, we actually don't care about the size
            // of the file, but we care about the size of the stream. `stat`
            // on std handles returns `64`, which is not what we want. What
            // we want is it's size only if the file is seekable, otherwise
            // return 0
            if fd >= 0 && fd <= 2 {
                n, os_err = 0, 0
            } else {
                n, os_err = file_size(fd)
            }
        }
	case .Destroy:
		err = .Empty
	case .Query:
		when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {
			return io.query_utility({.Close, .Flush, .Read, .Write, .Seek, .Size, .Query})
		} else {
			return io.query_utility({.Close, .Flush, .Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Query})
		}
	}
	if err == nil && os_err != 0 {
		err = .Unknown
	}
	return
}
