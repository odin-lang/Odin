package io

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

Tee_Reader :: struct {
	r: Reader,
	w: Writer,
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
};

// tee_reader_init returns a Reader that writes to 'w' what it reads from 'r'
// All reads from 'r' performed through it are matched with a corresponding write to 'w'
// There is no internal buffering done
// The write must complete before th read completes
// Any error encountered whilst writing is reported as a 'read' error
// tee_reader_init must call io.destroy when done with
tee_reader_init :: proc(t: ^Tee_Reader, r: Reader, w: Writer, allocator := context.allocator) -> Reader {
	t.r, t.w = r, w;
	return tee_reader_to_reader(t);
}

tee_reader_to_reader :: proc(t: ^Tee_Reader) -> (r: Reader) {
	r.stream_data = t;
	r.stream_vtable = _tee_reader_vtable;
	return;
}


// A Limited_Reader reads from r but limits the amount of data returned to just n bytes.
// Each call to read updates n to reflect the new amount remaining.
// read returns EOF when n <= 0 or when the underlying r returns EOF.
Limited_Reader :: struct {
	r: Reader, // underlying reader
	n: i64,    // max_bytes
}

@(private)
_limited_reader_vtable := &Stream_VTable{
	impl_read = proc(s: Stream, p: []byte) -> (n: int, err: Error) {
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

limited_reader_init :: proc(l: ^Limited_Reader, r: Reader, n: i64) -> Reader {
	l.r = r;
	l.n = n;
	return limited_reader_to_reader(l);
}

limited_reader_to_reader :: proc(l: ^Limited_Reader) -> (r: Reader) {
	r.stream_vtable = _limited_reader_vtable;
	r.stream_data = l;
	return;
}

// Section_Reader implements read, seek, and read_at on a section of an underlying Reader_At
Section_Reader :: struct {
	r: Reader_At,
	base:  i64,
	off:   i64,
	limit: i64,
}

section_reader_init :: proc(s: ^Section_Reader, r: Reader_At, off: i64, n: i64) {
	s.r = r;
	s.off = off;
	s.limit = off + n;
	return;
}
section_reader_to_stream :: proc(s: ^Section_Reader) -> (out: Stream) {
	out.stream_data = s;
	out.stream_vtable = _section_reader_vtable;
	return;
}

@(private)
_section_reader_vtable := &Stream_VTable{
	impl_read = proc(stream: Stream, p: []byte) -> (n: int, err: Error) {
		s := (^Section_Reader)(stream.stream_data);
		if s.off >= s.limit {
			return 0, .EOF;
		}
		p := p;
		if max := s.limit - s.off; i64(len(p)) > max {
			p = p[0:max];
		}
		n, err = read_at(s.r, p, s.off);
		s.off += i64(n);
		return;
	},
	impl_read_at = proc(stream: Stream, p: []byte, off: i64) -> (n: int, err: Error) {
		s := (^Section_Reader)(stream.stream_data);
		p, off := p, off;

		if off < 0 || off >= s.limit - s.base {
			return 0, .EOF;
		}
		off += s.base;
		if max := s.limit - off; i64(len(p)) > max {
			p = p[0:max];
			n, err = read_at(s.r, p, off);
			if err == nil {
				err = .EOF;
			}
			return;
		}
		return read_at(s.r, p, off);
	},
	impl_seek = proc(stream: Stream, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
		s := (^Section_Reader)(stream.stream_data);

		offset := offset;
		switch whence {
		case:
			return 0, .Invalid_Whence;
		case .Start:
			offset += s.base;
		case .Current:
			offset += s.off;
		case .End:
			offset += s.limit;
		}
		if offset < s.base {
			return 0, .Invalid_Offset;
		}
		s.off = offset;
		n = offset - s.base;
		return;
	},
	impl_size = proc(stream: Stream) -> i64 {
		s := (^Section_Reader)(stream.stream_data);
		return s.limit - s.base;
	},
};

