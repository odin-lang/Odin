package strings

import "core:mem"
import "core:unicode/utf8"
import "core:strconv"

Builder_Flush_Proc :: #type proc(b: ^Builder) -> (do_reset: bool);

Builder :: struct {
	buf: [dynamic]byte,

	// The custom flush procedure allows for the ability to flush the buffer, i.e. write to file
	flush_proc: Builder_Flush_Proc,
	flush_data: rawptr,
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

flush_builder :: proc(b: ^Builder) -> (was_reset: bool) {
	if b.flush_proc != nil {
		was_reset = b.flush_proc(b);
		if was_reset {
			reset_builder(b);

		}
	}
	return;
}

flush_builder_check_space :: proc(b: ^Builder, required: int) -> (was_reset: bool) {
	if n := max(cap(b.buf) - len(b.buf), 0); n < required {
		was_reset = flush_builder(b);
	}
	return;
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
	flush_builder_check_space(b, 1);
	if builder_space(b^) > 0 {
		append(&b.buf, x);
		n += 1;
	}
	return;
}

write_bytes :: proc(b: ^Builder, x: []byte) -> (n: int) {
	x := x;
	for len(x) != 0 {
		flush_builder_check_space(b, len(x));
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

write_rune :: proc(b: ^Builder, r: rune) -> int {
	if r < utf8.RUNE_SELF {
		return write_byte(b, byte(r));
	}

	s, n := utf8.encode_rune(r);
	write_bytes(b, s[:n]);
	return n;
}

write_quoted_rune :: proc(b: ^Builder, r: rune) -> (n: int) {
	quote := byte('\'');
	n += write_byte(b, quote);
	buf, width := utf8.encode_rune(r);
	if width == 1 && r == utf8.RUNE_ERROR {
		n += write_byte(b, '\\');
		n += write_byte(b, 'x');
		n += write_byte(b, DIGITS_LOWER[buf[0]>>4]);
		n += write_byte(b, DIGITS_LOWER[buf[0]&0xf]);
	} else {
		n += write_escaped_rune(b, r, quote);
	}
	n += write_byte(b, quote);
	return;
}

write_string :: proc(b: ^Builder, s: string) -> (n: int) {
	return write_bytes(b, transmute([]byte)s);
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

write_quoted_string :: proc(b: ^Builder, str: string, quote: byte = '"') -> (n: int) {
	n += write_byte(b, quote);
	for width, s := 0, str; len(s) > 0; s = s[width:] {
		r := rune(s[0]);
		width = 1;
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s);
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			n += write_byte(b, '\\');
			n += write_byte(b, 'x');
			n += write_byte(b, DIGITS_LOWER[s[0]>>4]);
			n += write_byte(b, DIGITS_LOWER[s[0]&0xf]);
			continue;
		}

		n += write_escaped_rune(b, r, quote);

	}
	n += write_byte(b, quote);
	return;
}


write_encoded_rune :: proc(b: ^Builder, r: rune, write_quote := true) -> (n: int) {
	if write_quote {
		n += write_byte(b, '\'');
	}
	switch r {
	case '\a': n += write_string(b, `\a"`);
	case '\b': n += write_string(b, `\b"`);
	case '\e': n += write_string(b, `\e"`);
	case '\f': n += write_string(b, `\f"`);
	case '\n': n += write_string(b, `\n"`);
	case '\r': n += write_string(b, `\r"`);
	case '\t': n += write_string(b, `\t"`);
	case '\v': n += write_string(b, `\v"`);
	case:
		if r < 32 {
			n += write_string(b, `\x`);
			buf: [2]byte;
			s := strconv.append_bits(buf[:], u64(r), 16, true, 64, strconv.digits, nil);
			switch len(s) {
			case 0: n += write_string(b, "00");
			case 1: n += write_byte(b, '0');
			case 2: n += write_string(b, s);
			}
		} else {
			n += write_rune(b, r);
		}

	}
	if write_quote {
		n += write_byte(b, '\'');
	}
	return;
}


write_escaped_rune :: proc(b: ^Builder, r: rune, quote: byte, html_safe := false) -> (n: int) {
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
			n += write_byte(b, '\\');
			n += write_byte(b, 'u');
			for s := 12; s >= 0; s -= 4 {
				n += write_byte(b, DIGITS_LOWER[r>>uint(s) & 0xf]);
			}
			return;
		}
	}

	if r == rune(quote) || r == '\\' {
		n += write_byte(b, '\\');
		n += write_byte(b, byte(r));
		return;
	} else if is_printable(r) {
		n += write_encoded_rune(b, r, false);
		return;
	}
	switch r {
	case '\a': n += write_string(b, `\a`);
	case '\b': n += write_string(b, `\b`);
	case '\e': n += write_string(b, `\e`);
	case '\f': n += write_string(b, `\f`);
	case '\n': n += write_string(b, `\n`);
	case '\r': n += write_string(b, `\r`);
	case '\t': n += write_string(b, `\t`);
	case '\v': n += write_string(b, `\v`);
	case:
		switch c := r; {
		case c < ' ':
			n += write_byte(b, '\\');
			n += write_byte(b, 'x');
			n += write_byte(b, DIGITS_LOWER[byte(c)>>4]);
			n += write_byte(b, DIGITS_LOWER[byte(c)&0xf]);

		case c > utf8.MAX_RUNE:
			c = 0xfffd;
			fallthrough;
		case c < 0x10000:
			n += write_byte(b, '\\');
			n += write_byte(b, 'u');
			for s := 12; s >= 0; s -= 4 {
				n += write_byte(b, DIGITS_LOWER[c>>uint(s) & 0xf]);
			}
		case:
			n += write_byte(b, '\\');
			n += write_byte(b, 'U');
			for s := 28; s >= 0; s -= 4 {
				n += write_byte(b, DIGITS_LOWER[c>>uint(s) & 0xf]);
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

