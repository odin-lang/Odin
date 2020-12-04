package strings

import "core:mem"
import "core:unicode/utf8"
import "core:strconv"
import "core:io"

Builder_Flush_Proc :: #type proc(b: ^Builder) -> (do_reset: bool);

Builder :: struct {
	buf: [dynamic]byte,
}

make_builder_none :: proc(allocator := context.allocator) -> Builder {
	return Builder{buf=make([dynamic]byte, allocator)};
}

make_builder_len :: proc(len: int, allocator := context.allocator) -> Builder {
	return Builder{buf=make([dynamic]byte, len, allocator)};
}

make_builder_len_cap :: proc(len, cap: int, allocator := context.allocator) -> Builder {
	return Builder{buf=make([dynamic]byte, len, cap, allocator)};
}

make_builder :: proc{
	make_builder_none,
	make_builder_len,
	make_builder_len_cap,
};

init_builder_none :: proc(b: ^Builder, allocator := context.allocator) {
	b.buf = make([dynamic]byte, allocator);
}

init_builder_len :: proc(b: ^Builder, len: int, allocator := context.allocator) {
	b.buf = make([dynamic]byte, len, allocator);
}

init_builder_len_cap :: proc(b: ^Builder, len, cap: int, allocator := context.allocator) {
	b.buf = make([dynamic]byte, len, cap, allocator);
}

init_builder :: proc{
	init_builder_none,
	init_builder_len,
	init_builder_len_cap,
};

@(private)
_builder_stream_vtable := &io.Stream_VTable{
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		b := (^Builder)(s.stream_data);
		n = write_bytes(b, p);
		if len(b.buf) == cap(b.buf) {
			err = .EOF;
		}
		return;
	},
	impl_write_byte = proc(s: io.Stream, c: byte) -> io.Error {
		b := (^Builder)(s.stream_data);
		_ = write_byte(b, c);
		if len(b.buf) == cap(b.buf) {
			return .EOF;
		}
		return nil;
	},
	impl_size = proc(s: io.Stream) -> i64 {
		b := (^Builder)(s.stream_data);
		return i64(len(b.buf));
	},
	impl_destroy = proc(s: io.Stream) -> io.Error {
		b := (^Builder)(s.stream_data);
		delete(b.buf);
		return .None;
	},
};

to_stream :: proc(b: ^Builder) -> io.Stream {
	return io.Stream{stream_vtable=_builder_stream_vtable, stream_data=b};
}
to_writer :: proc(b: ^Builder) -> io.Writer {
	w, _ := io.to_writer(to_stream(b));
	return w;
}




destroy_builder :: proc(b: ^Builder) {
	delete(b.buf);
	clear(&b.buf);
}

grow_builder :: proc(b: ^Builder, cap: int) {
	reserve(&b.buf, cap);
}

reset_builder :: proc(b: ^Builder) {
	clear(&b.buf);
}


builder_from_slice :: proc(backing: []byte) -> Builder {
	s := transmute(mem.Raw_Slice)backing;
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = mem.nil_allocator(),
	};
	return Builder{
		buf = transmute([dynamic]byte)d,
	};
}
to_string :: proc(b: Builder) -> string {
	return string(b.buf[:]);
}

builder_len :: proc(b: Builder) -> int {
	return len(b.buf);
}
builder_cap :: proc(b: Builder) -> int {
	return cap(b.buf);
}
builder_space :: proc(b: Builder) -> int {
	return max(cap(b.buf), len(b.buf), 0);
}

write_byte :: proc(b: ^Builder, x: byte) -> (n: int) {
	if builder_space(b^) > 0 {
		append(&b.buf, x);
		n += 1;
	}
	return;
}

write_bytes :: proc(b: ^Builder, x: []byte) -> (n: int) {
	x := x;
	for len(x) != 0 {
		space := builder_space(b^);
		if space == 0 {
			break; // No need to append
		}
		i := min(space, len(x));
		n += i;
		append(&b.buf, ..x[:i]);
		if len(x) <= i {
			break; // No more data to append
		}
		x = x[i:];
	}
	return;
}

write_rune_builder :: proc(b: ^Builder, r: rune) -> (int, io.Error) {
	return io.write_rune(to_writer(b), r);
}


write_quoted_rune_builder :: proc(b: ^Builder, r: rune) -> (n: int) {
	return write_quoted_rune(to_writer(b), r);
}

@(private)
_write_byte :: proc(w: io.Writer, c: byte) -> int {
	err := io.write_byte(w, c);
	return 1 if err == nil else 0;
}


write_quoted_rune :: proc(w: io.Writer, r: rune) -> (n: int) {
	quote := byte('\'');
	n += _write_byte(w, quote);
	buf, width := utf8.encode_rune(r);
	if width == 1 && r == utf8.RUNE_ERROR {
		n += _write_byte(w, '\\');
		n += _write_byte(w, 'x');
		n += _write_byte(w, DIGITS_LOWER[buf[0]>>4]);
		n += _write_byte(w, DIGITS_LOWER[buf[0]&0xf]);
	} else {
		n += write_escaped_rune(w, r, quote);
	}
	n += _write_byte(w, quote);
	return;
}


write_string :: proc{
	write_string_builder,
	write_string_writer,
};

write_string_builder :: proc(b: ^Builder, s: string) -> (n: int) {
	return write_string_writer(to_writer(b), s);
}

write_string_writer :: proc(w: io.Writer, s: string) -> (n: int) {
	n, _ = io.write(w, transmute([]byte)s);
	return;
}




pop_byte :: proc(b: ^Builder) -> (r: byte) {
	if len(b.buf) == 0 {
		return 0;
	}
	r = b.buf[len(b.buf)-1];
	d := cast(^mem.Raw_Dynamic_Array)&b.buf;
	d.len = max(d.len-1, 0);
	return;
}

pop_rune :: proc(b: ^Builder) -> (r: rune, width: int) {
	r, width = utf8.decode_last_rune(b.buf[:]);
	d := cast(^mem.Raw_Dynamic_Array)&b.buf;
	d.len = max(d.len-width, 0);
	return;
}


@(private, static)
DIGITS_LOWER := "0123456789abcdefx";

write_quoted_string :: proc{
	write_quoted_string_builder,
	write_quoted_string_writer,
};

write_quoted_string_builder :: proc(b: ^Builder, str: string, quote: byte = '"') -> (n: int) {
	return write_quoted_string_writer(to_writer(b), str, quote);
}

write_quoted_string_writer :: proc(w: io.Writer, str: string, quote: byte = '"') -> (n: int) {
	n += _write_byte(w, quote);
	for width, s := 0, str; len(s) > 0; s = s[width:] {
		r := rune(s[0]);
		width = 1;
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s);
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			n += _write_byte(w, '\\');
			n += _write_byte(w, 'x');
			n += _write_byte(w, DIGITS_LOWER[s[0]>>4]);
			n += _write_byte(w, DIGITS_LOWER[s[0]&0xf]);
			continue;
		}

		n += write_escaped_rune(w, r, quote);

	}
	n += _write_byte(w, quote);
	return;
}

write_encoded_rune :: proc{
	write_encoded_rune_builder,
	write_encoded_rune_writer,
};

write_encoded_rune_builder :: proc(b: ^Builder, r: rune, write_quote := true) -> (n: int) {
	return write_encoded_rune_writer(to_writer(b), r, write_quote);

}
write_encoded_rune_writer :: proc(w: io.Writer, r: rune, write_quote := true) -> (n: int) {
	if write_quote {
		n += _write_byte(w, '\'');
	}
	switch r {
	case '\a': n += write_string(w, `\a"`);
	case '\b': n += write_string(w, `\b"`);
	case '\e': n += write_string(w, `\e"`);
	case '\f': n += write_string(w, `\f"`);
	case '\n': n += write_string(w, `\n"`);
	case '\r': n += write_string(w, `\r"`);
	case '\t': n += write_string(w, `\t"`);
	case '\v': n += write_string(w, `\v"`);
	case:
		if r < 32 {
			n += write_string(w, `\x`);
			buf: [2]byte;
			s := strconv.append_bits(buf[:], u64(r), 16, true, 64, strconv.digits, nil);
			switch len(s) {
			case 0: n += write_string(w, "00");
			case 1: n += _write_byte(w, '0');
			case 2: n += write_string(w, s);
			}
		} else {
			rn, _ := io.write_rune(w, r);
			n += rn;
		}

	}
	if write_quote {
		n += _write_byte(w, '\'');
	}
	return;
}


write_escaped_rune :: proc{
	write_escaped_rune_builder,
	write_escaped_rune_writer,
};

write_escaped_rune_builder :: proc(b: ^Builder, r: rune, quote: byte, html_safe := false) -> (n: int) {
	return write_escaped_rune_writer(to_writer(b), r, quote, html_safe);
}

write_escaped_rune_writer :: proc(w: io.Writer, r: rune, quote: byte, html_safe := false) -> (n: int) {
	is_printable :: proc(r: rune) -> bool {
		if r <= 0xff {
			switch r {
			case 0x20..0x7e:
				return true;
			case 0xa1..0xff: // ¡ through ÿ except for the soft hyphen
				return r != 0xad; //
			}
		}

		// TODO(bill): A proper unicode library will be needed!
		return false;
	}

	if html_safe {
		switch r {
		case '<', '>', '&':
			n += _write_byte(w, '\\');
			n += _write_byte(w, 'u');
			for s := 12; s >= 0; s -= 4 {
				n += _write_byte(w, DIGITS_LOWER[r>>uint(s) & 0xf]);
			}
			return;
		}
	}

	if r == rune(quote) || r == '\\' {
		n += _write_byte(w, '\\');
		n += _write_byte(w, byte(r));
		return;
	} else if is_printable(r) {
		n += write_encoded_rune(w, r, false);
		return;
	}
	switch r {
	case '\a': n += write_string(w, `\a`);
	case '\b': n += write_string(w, `\b`);
	case '\e': n += write_string(w, `\e`);
	case '\f': n += write_string(w, `\f`);
	case '\n': n += write_string(w, `\n`);
	case '\r': n += write_string(w, `\r`);
	case '\t': n += write_string(w, `\t`);
	case '\v': n += write_string(w, `\v`);
	case:
		switch c := r; {
		case c < ' ':
			n += _write_byte(w, '\\');
			n += _write_byte(w, 'x');
			n += _write_byte(w, DIGITS_LOWER[byte(c)>>4]);
			n += _write_byte(w, DIGITS_LOWER[byte(c)&0xf]);

		case c > utf8.MAX_RUNE:
			c = 0xfffd;
			fallthrough;
		case c < 0x10000:
			n += _write_byte(w, '\\');
			n += _write_byte(w, 'u');
			for s := 12; s >= 0; s -= 4 {
				n += _write_byte(w, DIGITS_LOWER[c>>uint(s) & 0xf]);
			}
		case:
			n += _write_byte(w, '\\');
			n += _write_byte(w, 'U');
			for s := 28; s >= 0; s -= 4 {
				n += _write_byte(w, DIGITS_LOWER[c>>uint(s) & 0xf]);
			}
		}
	}
	return;
}


write_u64 :: proc(b: ^Builder, i: u64, base: int = 10) -> (n: int) {
	buf: [32]byte;
	s := strconv.append_bits(buf[:], u64(i), base, false, 64, strconv.digits, nil);
	return write_string(b, s);
}
write_i64 :: proc(b: ^Builder, i: i64, base: int = 10) -> (n: int) {
	buf: [32]byte;
	s := strconv.append_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil);
	return write_string(b, s);
}

write_uint :: proc(b: ^Builder, i: uint, base: int = 10) -> (n: int) {
	return write_u64(b, u64(i), base);
}
write_int :: proc(b: ^Builder, i: int, base: int = 10) -> (n: int) {
	return write_i64(b, i64(i), base);
}

