package io

import "core:runtime"
import "core:strconv"

write_u64 :: proc(w: Writer, i: u64, base: int = 10) -> (n: int, err: Error) {
	buf: [32]byte;
	s := strconv.append_bits(buf[:], u64(i), base, false, 64, strconv.digits, nil);
	return write_string(w, s);
}
write_i64 :: proc(w: Writer, i: i64, base: int = 10) -> (n: int, err: Error) {
	buf: [32]byte;
	s := strconv.append_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil);
	return write_string(w, s);
}

write_uint :: proc(w: Writer, i: uint, base: int = 10) -> (n: int, err: Error) {
	return write_u64(w, u64(i), base);
}
write_int :: proc(w: Writer, i: int, base: int = 10) -> (n: int, err: Error) {
	return write_i64(w, i64(i), base);
}

@(private)
Tee_Reader :: struct {
	r: Reader,
	w: Writer,
	allocator: runtime.Allocator,
}

@(private)
_tee_reader_vtable := &Stream_VTable{
	impl_read = proc(s: Stream, p: []byte) -> (n: int, err: Error) {
		t := (^Tee_Reader)(s.stream_data);
		n, err = read(t.r, p);
		if n > 0 {
			if wn, werr := write(t.w, p[:n]); werr != nil {
				return wn, werr;
			}
		}
		return;
	},
	impl_destroy = proc(s: Stream) -> Error {
		t := (^Tee_Reader)(s.stream_data);
		allocator := t.allocator;
		free(t, allocator);
		return .None;
	},
};

// tee_reader
// tee_reader must call io.destroy when done with
tee_reader :: proc(r: Reader, w: Writer, allocator := context.allocator) -> (out: Reader) {
	t := new(Tee_Reader, allocator);
	t.r, t.w = r, w;
	t.allocator = allocator;

	out.stream_data = t;
	out.stream_vtable = _tee_reader_vtable;
	return;
}


// A Limited_Reader reads from r but limits the amount of
// data returned to just n bytes. Each call to read
// updates n to reflect the new amount remaining.
// read returns EOF when n <= 0 or when the underlying r returns EOF.
Limited_Reader :: struct {
	r: Reader, // underlying reader
	n: i64,    // max_bytes
}

@(private)
_limited_reader_vtable := &Stream_VTable{
	impl_read = proc(using s: Stream, p: []byte) -> (n: int, err: Error) {
		l := (^Limited_Reader)(s.stream_data);
		if l.n <= 0 {
			return 0, .EOF;
		}
		p := p;
		if i64(len(p)) > l.n {
			p = p[0:l.n];
		}
		n, err = read(l.r, p);
		l.n -= i64(n);
		return;
	},
};

new_limited_reader :: proc(r: Reader, n: i64) -> ^Limited_Reader {
	l := new(Limited_Reader);
	l.r = r;
	l.n = n;
	return l;
}

limited_reader_to_reader :: proc(l: ^Limited_Reader) -> (r: Reader) {
	r.stream_vtable = _limited_reader_vtable;
	r.stream_data = l;
	return;
}

@(private="package")
inline_limited_reader :: proc(l: ^Limited_Reader, r: Reader, n: i64) -> Reader {
	l.r = r;
	l.n = n;
	return limited_reader_to_reader(l);
}
