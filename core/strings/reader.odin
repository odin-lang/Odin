package strings

import "core:io"
import "core:unicode/utf8"

Reader :: struct {
	using stream: io.Stream,
	s:         string,
	i:         i64, // current reading index
	prev_rune: int, // previous reading index of rune or < 0
}

reader_reset :: proc(r: ^Reader, s: string) {
	r.stream_data = r;
	r.stream_vtable = _reader_vtable;
	r.s = s;
	r.i = 0;
	r.prev_rune = -1;
}

new_reader :: proc(s: string, allocator := context.allocator) -> ^Reader {
	r := new(Reader, allocator);
	reader_reset(r, s);
	return r;
}

@(private)
_reader_vtable := &io.Stream_VTable{
	impl_size = proc(s: io.Stream) -> i64 {
		r := (^Reader)(s.stream_data);
		return i64(len(r.s));
	},
	impl_read = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		r := (^Reader)(s.stream_data);
		if r.i >= i64(len(r.s)) {
			return 0, .EOF;
		}
		r.prev_rune = -1;
		n = copy(p, r.s[r.i:]);
		r.i += i64(n);
		return;
	},
	impl_read_at = proc(s: io.Stream, p: []byte, off: i64) -> (n: int, err: io.Error) {
		r := (^Reader)(s.stream_data);
		if off < 0 {
			return 0, .Invalid_Offset;
		}
		if off >= i64(len(r.s)) {
			return 0, .EOF;
		}
		n = copy(p, r.s[off:]);
		if n < len(p) {
			err = .EOF;
		}
		return;
	},
	impl_read_byte = proc(s: io.Stream) -> (byte, io.Error) {
		r := (^Reader)(s.stream_data);
		r.prev_rune = -1;
		if r.i >= i64(len(r.s)) {
			return 0, .EOF;
		}
		b := r.s[r.i];
		r.i += 1;
		return b, nil;
	},
	impl_unread_byte = proc(s: io.Stream) -> io.Error {
		r := (^Reader)(s.stream_data);
		if r.i <= 0 {
			return .Invalid_Unread;
		}
		r.prev_rune = -1;
		r.i -= 1;
		return nil;
	},
	impl_read_rune = proc(s: io.Stream) -> (ch: rune, size: int, err: io.Error) {
		r := (^Reader)(s.stream_data);
		if r.i >= i64(len(r.s)) {
			r.prev_rune = -1;
			return 0, 0, .EOF;
		}
		r.prev_rune = int(r.i);
		if c := r.s[r.i]; c < utf8.RUNE_SELF {
			r.i += 1;
			return rune(c), 1, nil;
		}
		ch, size = utf8.decode_rune_in_string(r.s[r.i:]);
		r.i += i64(size);
		return;
	},
	impl_unread_rune = proc(s: io.Stream) -> io.Error {
		r := (^Reader)(s.stream_data);
		if r.i <= 0 {
			return .Invalid_Unread;
		}
		if r.prev_rune < 0 {
			return .Invalid_Unread;
		}
		r.i = i64(r.prev_rune);
		r.prev_rune = -1;
		return nil;
	},
	impl_seek = proc(s: io.Stream, offset: i64, whence: io.Seek_From) -> (i64, io.Error) {
		r := (^Reader)(s.stream_data);
		r.prev_rune = -1;
		abs: i64;
		switch whence {
		case .Start:
			abs = offset;
		case .Current:
			abs = r.i + offset;
		case .End:
			abs = i64(len(r.s)) + offset;
		case:
			return 0, .Invalid_Whence;
		}

		if abs < 0 {
			return 0, .Invalid_Offset;
		}
		r.i = abs;
		return abs, nil;
	},
	impl_write_to = proc(s: io.Stream, w: io.Writer) -> (n: i64, err: io.Error) {
		r := (^Reader)(s.stream_data);
		r.prev_rune = -1;
		if r.i >= i64(len(r.s)) {
			return 0, nil;
		}
		s := r.s[r.i:];
		m: int;
		m, err = io.write_string(w, s);
		if m > len(s) {
			panic("strings.Reader.write_to: invalid io.write_string count");
		}
		r.i += i64(m);
		n = i64(m);
		if m != len(s) && err == nil {
			err = .Short_Write;
		}
		return;
	},
};
