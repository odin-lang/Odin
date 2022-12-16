package io

import "core:strconv"
import "core:unicode/utf8"

read_ptr :: proc(r: Reader, p: rawptr, byte_size: int, n_read: ^int = nil) -> (n: int, err: Error) {
	return read(r, ([^]byte)(p)[:byte_size], n_read)
}

write_ptr :: proc(w: Writer, p: rawptr, byte_size: int, n_written: ^int = nil) -> (n: int, err: Error) {
	return write(w, ([^]byte)(p)[:byte_size], n_written)
}

read_ptr_at :: proc(r: Reader_At, p: rawptr, byte_size: int, offset: i64, n_read: ^int = nil) -> (n: int, err: Error) {
	return read_at(r, ([^]byte)(p)[:byte_size], offset, n_read)
}

write_ptr_at :: proc(w: Writer_At, p: rawptr, byte_size: int, offset: i64, n_written: ^int = nil) -> (n: int, err: Error) {
	return write_at(w, ([^]byte)(p)[:byte_size], offset, n_written)
}

write_u64 :: proc(w: Writer, i: u64, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [32]byte
	s := strconv.append_bits(buf[:], i, base, false, 64, strconv.digits, nil)
	return write_string(w, s, n_written)
}
write_i64 :: proc(w: Writer, i: i64, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [32]byte
	s := strconv.append_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
	return write_string(w, s, n_written)
}

write_uint :: proc(w: Writer, i: uint, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	return write_u64(w, u64(i), base, n_written)
}
write_int :: proc(w: Writer, i: int, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	return write_i64(w, i64(i), base, n_written)
}

write_u128 :: proc(w: Writer, i: u128, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [32]byte
	s := strconv.append_bits_128(buf[:], i, base, false, 128, strconv.digits, nil)
	return write_string(w, s, n_written)
}
write_i128 :: proc(w: Writer, i: i128, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [32]byte
	s := strconv.append_bits_128(buf[:], u128(i), base, true, 128, strconv.digits, nil)
	return write_string(w, s, n_written)
}
write_f16 :: proc(w: Writer, val: f16, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [386]byte

	str := strconv.append_float(buf[1:], f64(val), 'f', 2*size_of(val), 8*size_of(val))
	s := buf[:len(str)+1]
	if s[1] == '+' || s[1] == '-' {
		s = s[1:]
	} else {
		s[0] = '+'
	}
	if s[0] == '+' {
		s = s[1:]
	}

	return write_string(w, string(s), n_written)
}
write_f32 :: proc(w: Writer, val: f32, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [386]byte

	str := strconv.append_float(buf[1:], f64(val), 'f', 2*size_of(val), 8*size_of(val))
	s := buf[:len(str)+1]
	if s[1] == '+' || s[1] == '-' {
		s = s[1:]
	} else {
		s[0] = '+'
	}
	if s[0] == '+' {
		s = s[1:]
	}

	return write_string(w, string(s), n_written)
}	
write_f64 :: proc(w: Writer, val: f64, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [386]byte

	str := strconv.append_float(buf[1:], val, 'f', 2*size_of(val), 8*size_of(val))
	s := buf[:len(str)+1]
	if s[1] == '+' || s[1] == '-' {
		s = s[1:]
	} else {
		s[0] = '+'
	}
	if s[0] == '+' {
		s = s[1:]
	}

	return write_string(w, string(s), n_written)
}	




@(private="file")
DIGITS_LOWER := "0123456789abcdefx"

n_wrapper :: proc(n: int, err: Error, bytes_processed: ^int) -> Error {
	bytes_processed^ += n
	return err
}


write_encoded_rune :: proc(w: Writer, r: rune, write_quote := true, n_written: ^int = nil) -> (n: int, err: Error) {
	defer if n_written != nil {
		n_written^ += n
	}
	if write_quote {
		write_byte(w, '\'', &n) or_return
	}
	switch r {
	case '\a': write_string(w, `\a`, &n) or_return
	case '\b': write_string(w, `\b`, &n) or_return
	case '\e': write_string(w, `\e`, &n) or_return
	case '\f': write_string(w, `\f`, &n) or_return
	case '\n': write_string(w, `\n`, &n) or_return
	case '\r': write_string(w, `\r`, &n) or_return
	case '\t': write_string(w, `\t`, &n) or_return
	case '\v': write_string(w, `\v`, &n) or_return
	case:
		if r < 32 {
			write_string(w, `\x`, &n) or_return
			
			buf: [2]byte
			s := strconv.append_bits(buf[:], u64(r), 16, true, 64, strconv.digits, nil)
			switch len(s) {
			case 0: write_string(w, "00", &n) or_return
			case 1: write_byte(w, '0',    &n) or_return
			case 2: write_string(w, s,    &n) or_return
			}
		} else {
			write_rune(w, r, &n) or_return
		}

	}
	if write_quote {
		write_byte(w, '\'', &n) or_return
	}
	return
}

write_escaped_rune :: proc(w: Writer, r: rune, quote: byte, html_safe := false, n_written: ^int = nil) -> (n: int, err: Error) {
	is_printable :: proc(r: rune) -> bool {
		if r <= 0xff {
			switch r {
			case 0x20..=0x7e:
				return true
			case 0xa1..=0xff: // ¡ through ÿ except for the soft hyphen
				return r != 0xad //
			}
		}

		// TODO(bill): A proper unicode library will be needed!
		return false
	}
	defer if n_written != nil {
		n_written^ += n
	}
	
	if html_safe {
		switch r {
		case '<', '>', '&':
			write_byte(w, '\\', &n) or_return
			write_byte(w, 'u', &n)  or_return
			for s := 12; s >= 0; s -= 4 {
				write_byte(w, DIGITS_LOWER[r>>uint(s) & 0xf], &n) or_return
			}
			return
		}
	}

	if r == rune(quote) || r == '\\' {
		write_byte(w, '\\', &n)    or_return
		write_byte(w, byte(r), &n) or_return
		return
	} else if is_printable(r) {
		write_encoded_rune(w, r, false, &n) or_return
		return
	}
	switch r {
	case '\a': write_string(w, `\a`, &n) or_return
	case '\b': write_string(w, `\b`, &n) or_return
	case '\e': write_string(w, `\e`, &n) or_return
	case '\f': write_string(w, `\f`, &n) or_return
	case '\n': write_string(w, `\n`, &n) or_return
	case '\r': write_string(w, `\r`, &n) or_return
	case '\t': write_string(w, `\t`, &n) or_return
	case '\v': write_string(w, `\v`, &n) or_return
	case:
		switch c := r; {
		case c < ' ':
			write_byte(w, '\\', &n)                      or_return
			write_byte(w, 'x', &n)                       or_return
			write_byte(w, DIGITS_LOWER[byte(c)>>4], &n)  or_return
			write_byte(w, DIGITS_LOWER[byte(c)&0xf], &n) or_return

		case c > utf8.MAX_RUNE:
			c = 0xfffd
			fallthrough
		case c < 0x10000:
			write_byte(w, '\\', &n) or_return
			write_byte(w, 'u', &n)  or_return
			for s := 12; s >= 0; s -= 4 {
				write_byte(w, DIGITS_LOWER[c>>uint(s) & 0xf], &n) or_return
			}
		case:
			write_byte(w, '\\', &n) or_return
			write_byte(w, 'U', &n)  or_return
			for s := 28; s >= 0; s -= 4 {
				write_byte(w, DIGITS_LOWER[c>>uint(s) & 0xf], &n) or_return
			}
		}
	}
	return
}

write_quoted_string :: proc(w: Writer, str: string, quote: byte = '"', n_written: ^int = nil) -> (n: int, err: Error) {
	defer if n_written != nil {
		n_written^ += n
	}
	write_byte(w, quote, &n) or_return
	for width, s := 0, str; len(s) > 0; s = s[width:] {
		r := rune(s[0])
		width = 1
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s)
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			write_byte(w, '\\', &n)                   or_return
			write_byte(w, 'x', &n)                    or_return
			write_byte(w, DIGITS_LOWER[s[0]>>4], &n)  or_return
			write_byte(w, DIGITS_LOWER[s[0]&0xf], &n) or_return
			continue
		}

		n_wrapper(write_escaped_rune(w, r, quote), &n) or_return

	}
	write_byte(w, quote, &n) or_return
	return
}

// writer append a quoted rune into the byte buffer, return the written size
write_quoted_rune :: proc(w: Writer, r: rune) -> (n: int) {
	_write_byte :: #force_inline proc(w: Writer, c: byte) -> int {
		err := write_byte(w, c)
		return 1 if err == nil else 0
	}

	quote := byte('\'')
	n += _write_byte(w, quote)
	buf, width := utf8.encode_rune(r)
	if width == 1 && r == utf8.RUNE_ERROR {
		n += _write_byte(w, '\\')
		n += _write_byte(w, 'x')
		n += _write_byte(w, DIGITS_LOWER[buf[0]>>4])
		n += _write_byte(w, DIGITS_LOWER[buf[0]&0xf])
	} else {
		i, _ := write_escaped_rune(w, r, quote)
		n += i
	}
	n += _write_byte(w, quote)
	return
}




Tee_Reader :: struct {
	r: Reader,
	w: Writer,
}

@(private)
_tee_reader_vtable := &Stream_VTable{
	impl_read = proc(s: Stream, p: []byte) -> (n: int, err: Error) {
		t := (^Tee_Reader)(s.stream_data)
		n, err = read(t.r, p)
		if n > 0 {
			if wn, werr := write(t.w, p[:n]); werr != nil {
				return wn, werr
			}
		}
		return
	},
}

// tee_reader_init returns a Reader that writes to 'w' what it reads from 'r'
// All reads from 'r' performed through it are matched with a corresponding write to 'w'
// There is no internal buffering done
// The write must complete before th read completes
// Any error encountered whilst writing is reported as a 'read' error
// tee_reader_init must call io.destroy when done with
tee_reader_init :: proc(t: ^Tee_Reader, r: Reader, w: Writer, allocator := context.allocator) -> Reader {
	t.r, t.w = r, w
	return tee_reader_to_reader(t)
}

tee_reader_to_reader :: proc(t: ^Tee_Reader) -> (r: Reader) {
	r.stream_data = t
	r.stream_vtable = _tee_reader_vtable
	return
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
		l := (^Limited_Reader)(s.stream_data)
		if l.n <= 0 {
			return 0, .EOF
		}
		p := p
		if i64(len(p)) > l.n {
			p = p[0:l.n]
		}
		n, err = read(l.r, p)
		l.n -= i64(n)
		return
	},
}

limited_reader_init :: proc(l: ^Limited_Reader, r: Reader, n: i64) -> Reader {
	l.r = r
	l.n = n
	return limited_reader_to_reader(l)
}

limited_reader_to_reader :: proc(l: ^Limited_Reader) -> (r: Reader) {
	r.stream_vtable = _limited_reader_vtable
	r.stream_data = l
	return
}

// Section_Reader implements read, seek, and read_at on a section of an underlying Reader_At
Section_Reader :: struct {
	r: Reader_At,
	base:  i64,
	off:   i64,
	limit: i64,
}

section_reader_init :: proc(s: ^Section_Reader, r: Reader_At, off: i64, n: i64) {
	s.r = r
	s.off = off
	s.limit = off + n
	return
}
section_reader_to_stream :: proc(s: ^Section_Reader) -> (out: Stream) {
	out.stream_data = s
	out.stream_vtable = _section_reader_vtable
	return
}

@(private)
_section_reader_vtable := &Stream_VTable{
	impl_read = proc(stream: Stream, p: []byte) -> (n: int, err: Error) {
		s := (^Section_Reader)(stream.stream_data)
		if s.off >= s.limit {
			return 0, .EOF
		}
		p := p
		if max := s.limit - s.off; i64(len(p)) > max {
			p = p[0:max]
		}
		n, err = read_at(s.r, p, s.off)
		s.off += i64(n)
		return
	},
	impl_read_at = proc(stream: Stream, p: []byte, off: i64) -> (n: int, err: Error) {
		s := (^Section_Reader)(stream.stream_data)
		p, off := p, off

		if off < 0 || off >= s.limit - s.base {
			return 0, .EOF
		}
		off += s.base
		if max := s.limit - off; i64(len(p)) > max {
			p = p[0:max]
			n, err = read_at(s.r, p, off)
			if err == nil {
				err = .EOF
			}
			return
		}
		return read_at(s.r, p, off)
	},
	impl_seek = proc(stream: Stream, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
		s := (^Section_Reader)(stream.stream_data)

		offset := offset
		switch whence {
		case:
			return 0, .Invalid_Whence
		case .Start:
			offset += s.base
		case .Current:
			offset += s.off
		case .End:
			offset += s.limit
		}
		if offset < s.base {
			return 0, .Invalid_Offset
		}
		s.off = offset
		n = offset - s.base
		return
	},
	impl_size = proc(stream: Stream) -> i64 {
		s := (^Section_Reader)(stream.stream_data)
		return s.limit - s.base
	},
}

