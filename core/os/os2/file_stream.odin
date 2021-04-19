package os2

import "core:io"

file_to_stream :: proc(fd: Handle) -> (s: io.Stream) {
	s.stream_data = rawptr(uintptr(fd));
	s.stream_vtable = _file_stream_vtable;
	return;
}

@(private)
error_to_io_error :: proc(ferr: Error) -> io.Error {
	#partial switch ferr {
	case .None:           return .None;
	case .EOF:            return .EOF;
	case .Unexpected_EOF: return .Unexpected_EOF;
	case .Short_Write:    return .Short_Write;
	case .Invalid_Write:  return .Invalid_Write;
	case .Short_Buffer:   return .Short_Buffer;
	case .No_Progress:    return .No_Progress;
	case .Invalid_Whence: return .Invalid_Whence;
	case .Invalid_Offset: return .Invalid_Offset;
	case .Invalid_Unread: return .Invalid_Unread;
	case .Negative_Read:  return .Negative_Read;
	case .Negative_Write: return .Negative_Write;
	case .Negative_Count: return .Negative_Count;
	case .Buffer_Full:    return .Buffer_Full;
	}
	return .Unknown;
}


@(private)
_file_stream_vtable := &io.Stream_VTable{
	impl_read = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		ferr: Error;
		n, ferr = read(fd, p);
		err = error_to_io_error(ferr);
		return;
	},
	impl_read_at = proc(s: io.Stream, p: []byte, offset: i64) -> (n: int, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		ferr: Error;
		n, ferr = read_at(fd, p, offset);
		err = error_to_io_error(ferr);
		return;
	},
	impl_write_to = proc(s: io.Stream, w: io.Writer) -> (n: i64, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		ferr: Error;
		n, ferr = write_to(fd, w);
		err = error_to_io_error(ferr);
		return;
	},
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		ferr: Error;
		n, ferr = write(fd, p);
		err = error_to_io_error(ferr);
		return;
	},
	impl_write_at = proc(s: io.Stream, p: []byte, offset: i64) -> (n: int, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		ferr: Error;
		n, ferr = write_at(fd, p, offset);
		err = error_to_io_error(ferr);
		return;
	},
	impl_read_from = proc(s: io.Stream, r: io.Reader) -> (n: i64, err: io.Error) {
		fd := Handle(uintptr(s.stream_data));
		ferr: Error;
		n, ferr = read_from(fd, r);
		err = error_to_io_error(ferr);
		return;
	},
	impl_seek = proc(s: io.Stream, offset: i64, whence: io.Seek_From) -> (i64, io.Error) {
		fd := Handle(uintptr(s.stream_data));
		n, ferr := seek(fd, offset, Seek_From(whence));
		err := error_to_io_error(ferr);
		return n, err;
	},
	impl_size = proc(s: io.Stream) -> i64 {
		fd := Handle(uintptr(s.stream_data));
		sz, _ := file_size(fd);
		return sz;
	},
	impl_flush = proc(s: io.Stream) -> io.Error {
		fd := Handle(uintptr(s.stream_data));
		ferr := flush(fd);
		return error_to_io_error(ferr);
	},
	impl_close = proc(s: io.Stream) -> io.Error {
		fd := Handle(uintptr(s.stream_data));
		ferr := close(fd);
		return error_to_io_error(ferr);
	},
};
