package strings

import "core:mem"
import "core:unicode/utf8"
import "core:strconv"

Builder :: struct {
	buf: [dynamic]byte,
}

make_builder :: proc(allocator := context.allocator) -> Builder {
	return Builder{make([dynamic]byte)};
}

destroy_builder :: proc(b: ^Builder) {
	delete(b.buf);
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
	return transmute(Builder)d;
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

write_byte :: proc(b: ^Builder, x: byte) {
	append(&b.buf, x);
}

write_rune :: proc(b: ^Builder, r: rune) -> int {
	if r < utf8.RUNE_SELF {
		write_byte(b, byte(r));
		return 1;
	}

	s, n := utf8.encode_rune(r);
	write_bytes(b, s[:n]);
	return n;
}

write_string :: proc(b: ^Builder, s: string) {
	write_bytes(b, cast([]byte)s);
}

write_bytes :: proc(b: ^Builder, x: []byte) {
	append(&b.buf, ..x);
}


write_encoded_rune :: proc(b: ^Builder, r: rune) {
	write_byte(b, '\'');
	switch r {
	case '\a': write_string(b, "\\a");
	case '\b': write_string(b, "\\b");
	case '\e': write_string(b, "\\e");
	case '\f': write_string(b, "\\f");
	case '\n': write_string(b, "\\n");
	case '\r': write_string(b, "\\r");
	case '\t': write_string(b, "\\t");
	case '\v': write_string(b, "\\v");
	case:
		if r < 32 {
			write_string(b, "\\x");
			buf: [2]byte;
			s := strconv.append_bits(buf[:], u64(r), 16, true, 64, strconv.digits, nil);
			switch len(s) {
			case 0: write_string(b, "00");
			case 1: write_rune(b, '0');
			case 2: write_string(b, s);
			}
		} else {
			write_rune(b, r);
		}

	}
	write_byte(b, '\'');
}


write_u64 :: proc(b: ^Builder, i: u64, base: int = 10) {
	buf: [129]byte;
	s := strconv.append_bits(buf[:], u64(i), base, false, 64, strconv.digits, nil);
	write_string(b, s);
}
write_i64 :: proc(b: ^Builder, i: i64, base: int = 10) {
	buf: [129]byte;
	s := strconv.append_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil);
	write_string(b, s);
}

write_uint :: proc(b: ^Builder, i: uint, base: int = 10) {
	write_u64(b, u64(i), base);
}
write_int :: proc(b: ^Builder, i: int, base: int = 10) {
	write_i64(b, i64(i), base);
}

