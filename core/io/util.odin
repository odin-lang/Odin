package io

import "core:strconv"
import "core:unicode/utf8"
import "core:unicode/utf16"

read_ptr :: proc(r: Reader, p: rawptr, byte_size: int, n_read: ^int = nil) -> (n: int, err: Error) {
	return read(r, ([^]byte)(p)[:byte_size], n_read)
}

read_slice :: proc(r: Reader, slice: $S/[]$T, n_read: ^int = nil) -> (n: int, err: Error) {
	size := len(slice)*size_of(T)
	return read_ptr(r, raw_data(slice), size, n_read)
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

write_slice :: proc(w: Writer, slice: $S/[]$T, n_written: ^int = nil) -> (n: int, err: Error) {
	size := len(slice)*size_of(T)
	return write_ptr(w, raw_data(slice), size, n_written)
}


write_u64 :: proc(w: Writer, i: u64, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [64]byte
	s := strconv.write_bits(buf[:], i, base, false, 64, strconv.digits, nil)
	return write_string(w, s, n_written)
}
write_i64 :: proc(w: Writer, i: i64, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [65]byte
	s := strconv.write_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
	return write_string(w, s, n_written)
}

write_uint :: proc(w: Writer, i: uint, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	return write_u64(w, u64(i), base, n_written)
}
write_int :: proc(w: Writer, i: int, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	return write_i64(w, i64(i), base, n_written)
}

write_u128 :: proc(w: Writer, i: u128, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [128]byte
	s := strconv.write_bits_128(buf[:], i, base, false, 128, strconv.digits, nil)
	return write_string(w, s, n_written)
}
write_i128 :: proc(w: Writer, i: i128, base: int = 10, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [129]byte
	s := strconv.write_bits_128(buf[:], u128(i), base, true, 128, strconv.digits, nil)
	return write_string(w, s, n_written)
}
write_f16 :: proc(w: Writer, val: f16, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [386]byte

	str := strconv.write_float(buf[1:], f64(val), 'f', 2*size_of(val), 8*size_of(val))
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

	str := strconv.write_float(buf[1:], f64(val), 'f', 2*size_of(val), 8*size_of(val))
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

	str := strconv.write_float(buf[1:], val, 'f', 2*size_of(val), 8*size_of(val))
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




/*
Writes rune `r` to the Writer `w` as UTF-8, optionally enclosed in single quotes.

**Inputs:**
- `w`:            The Writer to write to.
- `r`:            The rune to write.
- `write_quote`:  If true (the default), writes the rune as a quoted rune literal; otherwise writes it unquoted.
- `n_written`:    Optional pointer to a counter to which the number of bytes written is added.

**Returns:**
- `n`:            The number of bytes written.
- `err`:          An error encountered while writing, or `nil` on success.

**Remarks:**

When `write_quote` is `true`, the output is escaped and quoted as a rune literal.

When `write_quote` is `false`, the rune is written unquoted and neither single nor double quotes are escaped.

If the Writer writes only part of the output before returning an error, `n` reports the number of bytes written.
*/
write_encoded_rune :: proc(w: Writer, r: rune, write_quote := true, n_written: ^int = nil) -> (n: int, err: Error) {
	if write_quote {
		return write_quoted_rune(w, r, n_written = n_written)
	} else {
		// COMPAT: Originally, this procedure would never escape the quote character.
		//         It does now when `write_quote` is true (that was arguably a bug),
		//         but for compatibility, we still don't escape the quote in this branch.
		return write_encoded_and_escaped_rune(w, r, 0, n_written = n_written)
	}
}

/*
Writes rune `r` to the Writer `w` as UTF-8, escaping it as needed and escaping `quote` when it occurs.

**Inputs:**
- `w`:          The Writer to write to.
- `r`:          The rune to write.
- `quote`:      An enclosing quote character to escape; pass `0` to disable quote-character escaping.
- `html_safe`:  If `true`, also escapes `<`, `>` and `&` using hexadecimal escapes (`\x##`).
- `n_written`:  Optional pointer to a counter to which the number of bytes written is added.

**Returns:**
- `n`:          The number of bytes written.
- `err`:        An error encountered while writing, or `nil` on success.

**Remarks:**

The rune is not surrounded by quotes. For quoted output, use `write_quoted_rune` or `write_quoted_string`.

If the Writer writes only part of the output before returning an error, `n` reports the number of bytes written.
*/
write_escaped_rune :: proc(w: Writer, r: rune, quote: byte, html_safe := false, n_written: ^int = nil) -> (n: int, err: Error) {
	options: strconv.Rune_Escaping_Options
	if html_safe {
		options |= { .html_safe }
	}
	return write_encoded_and_escaped_rune(w, r, quote, options, n_written)
}

/*
Writes rune `r` to the Writer `w` as UTF-8, escaping it as needed and escaping `quote` when it occurs.

**Inputs:**
- `w`:          The Writer to write to.
- `r`:          The rune to write.
- `quote`:      An enclosing quote character to escape; pass `0` to disable quote-character escaping.
- `options`:    Controls how the rune is escaped.
- `n_written`:  Optional pointer to a counter to which the number of bytes written is added.

**Returns:**
- `n`:          The number of bytes written.
- `err`:        An error encountered while writing, or `nil` on success.

**Remarks:**

The rune is not surrounded by quotes. Use `write_quoted_rune` or `write_quoted_string` to produce quoted output.

If the Writer writes only part of the output before returning an error, `n` reports the number of bytes written.
*/
write_encoded_and_escaped_rune :: proc(w: Writer, r: rune, quote: byte, options: strconv.Rune_Escaping_Options = nil, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [strconv.ESCAPED_RUNE_MAX_NEEDED_BYTES]byte
	str, encode_and_escape_rune_ok := strconv.encode_and_escape_rune(buf[:], r, quote, options)
	assert(encode_and_escape_rune_ok == true)
	return write_string(w, str, n_written)
}

/*
Writes `str` to the Writer `w`, enclosed in `quote` characters, escaping runes as needed.

**Inputs:**
- `w`:          The Writer to write to.
- `str`:        The string to quote and write.
- `quote`:      The enclosing quote character (double quote by default).
- `n_written`:  Optional pointer to a counter to which the number of bytes written is added.
- `options`:    Controls how runes in the string are escaped.

**Returns:**
- `n`:          The number of bytes written.
- `err`:        An error encountered while writing, or `nil` on success.

**Remarks:**

With the default double quote and escaping options, the output is quoted and escaped as an Odin string literal.

Invalid UTF-8 bytes in `str` are written as hexadecimal byte escapes. If the Writer writes only part of the
output before returning an error, `n` reports the number of bytes written.
*/
write_quoted_string :: proc(w: Writer, str: string, quote: byte = '"', n_written: ^int = nil, options: strconv.Rune_Escaping_Options = nil) -> (n: int, err: Error) {
	defer if n_written != nil {
		n_written^ += n
	}

	write_byte(w, quote, &n) or_return

	s := str

	for len(s) > 0 {
		r := cast(rune)s[0]
		width := 1
		if r < utf8.RUNE_SELF {
			// r contains the entire UTF-8 codepoint already.
		} else {
			// Multi-byte codepoint. Must decode.
			r, width = utf8.decode_rune_in_string(s)
			assert(width > 0)
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			// Indicates UTF-8 encoding error.
			// Encode the byte exactly as it was found in the input string: `\x##`
			write_string(w, `\x`, &n)                     or_return
			write_byte(w, strconv.digits[s[0] >> 4], &n)  or_return
			write_byte(w, strconv.digits[s[0] & 0xf], &n) or_return
		} else {
			encoded_rune_buf: [strconv.ESCAPED_RUNE_MAX_NEEDED_BYTES]byte
			encoded_rune, encode_rune_ok := strconv.encode_and_escape_rune(encoded_rune_buf[:], r, quote, options = options)
			assert(encode_rune_ok == true)
			write_string(w, encoded_rune, &n) or_return
		}
		// Advance input cursor to the next codepoint.
		s = s[width:]
	}

	write_byte(w, quote, &n) or_return

	return
}

/*
Writes `str` to the Writer `w`, enclosed in `quote` characters, escaping runes as needed.

**NOTE:** The UTF-16 input string is encoded as UTF-8 in the output.

**Inputs:**
- `w`:          The Writer to write to.
- `str`:        The UTF-16 string to quote and write.
- `quote`:      The enclosing quote character (double quote by default).
- `n_written`:  Optional pointer to a counter to which the number of bytes written is added.
- `options`:    Controls how runes in the string are escaped.

**Returns:**
- `n`:          The number of UTF-8 bytes written.
- `err`:        An error encountered while writing, or `nil` on success.

**Remarks:**

With the default double quote and escaping options, the output is quoted and escaped as an Odin string literal.

Unpaired UTF-16 surrogates are encoded as the Unicode replacement character. If the Writer writes only part
of the output before returning an error, `n` reports the number of bytes written.
*/
write_quoted_string16 :: proc(w: Writer, str: string16, quote: byte = '"', n_written: ^int = nil, options: strconv.Rune_Escaping_Options = nil) -> (n: int, err: Error) {
	defer if n_written != nil {
		n_written^ += n
	}

	write_byte(w, quote, &n) or_return

	s := str

	for len(s) > 0 {
		r, width := utf16.decode_rune_in_string(s)
		assert(width > 0)
		if width == 1 && r == utf8.RUNE_ERROR {
			// TODO: It's not obvious that this works the same way as the UTF-8 version.
			//       Add some test coverage for this!
			write_string(w, `\x`, &n)                     or_return
			write_byte(w, strconv.digits[s[0] >> 4], &n)  or_return
			write_byte(w, strconv.digits[s[0] & 0xf], &n) or_return
		} else {
			encoded_rune_buf: [strconv.ESCAPED_RUNE_MAX_NEEDED_BYTES]byte
			encoded_rune, encode_rune_ok := strconv.encode_and_escape_rune(encoded_rune_buf[:], r, quote, options = options)
			assert(encode_rune_ok == true)
			write_string(w, encoded_rune, &n) or_return
		}

		s = s[width:]
	}

	write_byte(w, quote, &n) or_return

	return
}

/*
Writes rune `r` to the Writer `w` as a quoted rune literal, escaping it as needed.

**Inputs:**
- `w`:          The Writer to write to.
- `r`:          The rune to quote and write.
- `options`:    Controls how the rune is escaped.
- `n_written`:  Optional pointer to a counter to which the number of bytes written is added.

**Returns:**
- `n`:          The number of bytes written.
- `err`:        An error encountered while writing, or `nil` on success.

**Remarks:**

The result is enclosed in single quotes. If the Writer writes only part of the output before returning an
error, `n` reports the number of bytes written.
*/
write_quoted_rune :: proc(w: Writer, r: rune, options: strconv.Rune_Escaping_Options = nil, n_written: ^int = nil) -> (n: int, err: Error) {
	buf: [strconv.QUOTED_RUNE_MAX_NEEDED_BYTES]byte
	str, quote_rune_ok := strconv.quote_rune(buf[:], r, options)
	assert(quote_rune_ok == true)
	return write_string(w, str, n_written)
}




Tee_Reader :: struct {
	r: Reader,
	w: Writer,
}

@(private)
_tee_reader_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
	t := (^Tee_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		n, err = _i64_err(read(t.r, p))
		if n > 0 {
			if wn, werr := write(t.w, p[:n]); werr != nil {
				return i64(wn), werr
			}
		}
		return
	case .Query:
		return query_utility({.Read, .Query})
	}
	return 0, .Unsupported
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
	r.data = t
	r.procedure = _tee_reader_proc
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
_limited_reader_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
	l := (^Limited_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if len(p) == 0 {
			return 0, nil
		}
		if l.n <= 0 {
			return 0, .EOF
		}
		p := p
		if i64(len(p)) > l.n {
			p = p[0:l.n]
		}
		n, err = _i64_err(read(l.r, p))
		l.n -= i64(n)
		return
	case .Query:
		return query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

limited_reader_init :: proc(l: ^Limited_Reader, r: Reader, n: i64) -> Reader {
	l.r = r
	l.n = n
	return limited_reader_to_reader(l)
}

limited_reader_to_reader :: proc(l: ^Limited_Reader) -> (r: Reader) {
	r.procedure = _limited_reader_proc
	r.data = l
	return
}

// Section_Reader implements read, seek, and read_at on a section of an underlying Reader_At
Section_Reader :: struct {
	r: Reader_At,
	base:  i64,
	off:   i64,
	limit: i64,
}

section_reader_init :: proc(s: ^Section_Reader, r: Reader_At, off: i64, n: i64) -> Reader {
	s.r = r
	s.base = off
	s.off = off
	s.limit = off + n
	return section_reader_to_stream(s)
}
section_reader_to_stream :: proc(s: ^Section_Reader) -> (out: Stream) {
	out.data = s
	out.procedure = _section_reader_proc
	return
}

@(private)
_section_reader_proc :: proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
	s := (^Section_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if len(p) == 0 {
			return 0, nil
		}
		if s.off >= s.limit {
			return 0, .EOF
		}
		p := p
		if max := s.limit - s.off; i64(len(p)) > max {
			p = p[0:max]
		}
		n, err = _i64_err(read_at(s.r, p, s.off))
		s.off += i64(n)
		return
	case .Read_At:
		if len(p) == 0 {
			return 0, nil
		}
		p, off := p, offset

		if off < 0 || off >= s.limit - s.base {
			return 0, .EOF
		}
		off += s.base
		if max := s.limit - off; i64(len(p)) > max {
			p = p[0:max]
			n, err = _i64_err(read_at(s.r, p, off))
			if err == nil {
				err = .EOF
			}
			return
		}
		return _i64_err(read_at(s.r, p, off))

	case .Seek:
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
	case .Size:
		n = s.limit - s.base
		return
	case .Query:
		return query_utility({.Read, .Read_At, .Seek, .Size, .Query})
	}
	return 0, nil

}
