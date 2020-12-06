package bufio

import "core:io"

// Read_Writer stores pointers to a Reader and a Writer
Read_Writer :: struct {
	r: ^Reader,
	w: ^Writer,
}


read_writer_init :: proc(rw: ^Read_Writer, r: ^Reader, w: ^Writer) {
	rw.r, rw.w = r, w;
}

read_writer_to_stream :: proc(rw: ^Read_Writer) -> (s: io.Stream) {
	s.stream_data = rw;
	s.stream_vtable = _read_writer_vtable;
	return;
}

@(private)
_read_writer_vtable := &io.Stream_VTable{
	impl_read = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		b := (^Read_Writer)(s.stream_data).r;
		return reader_read(b, p);
	},
	impl_read_byte = proc(s: io.Stream) -> (c: byte, err: io.Error) {
		b := (^Read_Writer)(s.stream_data).r;
		return reader_read_byte(b);
	},
	impl_unread_byte = proc(s: io.Stream) -> io.Error {
		b := (^Read_Writer)(s.stream_data).r;
		return reader_unread_byte(b);
	},
	impl_read_rune = proc(s: io.Stream) -> (r: rune, size: int, err: io.Error) {
		b := (^Read_Writer)(s.stream_data).r;
		return reader_read_rune(b);
	},
	impl_unread_rune = proc(s: io.Stream) -> io.Error {
		b := (^Read_Writer)(s.stream_data).r;
		return reader_unread_rune(b);
	},
	impl_write_to = proc(s: io.Stream, w: io.Writer) -> (n: i64, err: io.Error) {
		b := (^Read_Writer)(s.stream_data).r;
		return reader_write_to(b, w);
	},
	impl_flush = proc(s: io.Stream)  -> io.Error {
		b := (^Read_Writer)(s.stream_data).w;
		return writer_flush(b);
	},
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		b := (^Read_Writer)(s.stream_data).w;
		return writer_write(b, p);
	},
	impl_write_byte = proc(s: io.Stream, c: byte) -> io.Error {
		b := (^Read_Writer)(s.stream_data).w;
		return writer_write_byte(b, c);
	},
	impl_write_rune = proc(s: io.Stream, r: rune) -> (int, io.Error) {
		b := (^Read_Writer)(s.stream_data).w;
		return writer_write_rune(b, r);
	},
	impl_read_from = proc(s: io.Stream, r: io.Reader) -> (n: i64, err: io.Error) {
		b := (^Read_Writer)(s.stream_data).w;
		return writer_read_from(b, r);
	},
};
