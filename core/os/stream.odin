package os

import "core:io"

stream_from_handle :: proc(fd: Handle) -> io.Stream {
	s: io.Stream;
	s.stream_data = rawptr(uintptr(fd));
	s.stream_vtable = _file_stream_vtable;
	return s;
}


@(private)
_file_stream_vtable := &io.Stream_VTable{
	impl_read = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		os_err: Errno;
		n, os_err = read(fd, p);
		return;
	},
	impl_read_at = proc(s: io.Stream, p: []byte, offset: i64) -> (n: int, err: io.Error) {
		when ODIN_OS == "windows" {
			fd := Handle(uintptr(s.stream_data));
			os_err: Errno;
			n, os_err = read_at(fd, p, offset);
		}
		return;
	},
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		os_err: Errno;
		n, os_err = write(fd, p);
		return;
	},
	impl_write_at = proc(s: io.Stream, p: []byte, offset: i64) -> (n: int, err: io.Error) {
		when ODIN_OS == "windows" {
			fd := Handle(uintptr(s.stream_data));
			os_err: Errno;
			n, os_err = write_at(fd, p, offset);
			_ = os_err;
		}
		return;
	},
	impl_seek = proc(s: io.Stream, offset: i64, whence: io.Seek_From) -> (i64, io.Error) {
		fd := Handle(uintptr(s.stream_data));
		n, os_err := seek(fd, offset, int(whence));
		_ = os_err;
		return n, nil;
	},
	impl_size = proc(s: io.Stream) -> i64 {
		fd := Handle(uintptr(s.stream_data));
		sz, _ := file_size(fd);
		return sz;
	},
	impl_flush = proc(s: io.Stream) -> io.Error {
		when ODIN_OS == "windows" {
			fd := Handle(uintptr(s.stream_data));
			flush(fd);
		} else {
			// TOOD(bill): other operating systems
		}
		return nil;
	},
	impl_close = proc(s: io.Stream) -> io.Error {
		fd := Handle(uintptr(s.stream_data));
		close(fd);
		return nil;
	},
};
