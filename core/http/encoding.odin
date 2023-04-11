package http
import "core:strings"

// NOTE: This file may want to move to "core:encoding/octet" (?)

// Decodes Octet Encoded string
decode_octet :: proc(s: string, allocator := context.allocator) -> (str: string, ok: bool) {
	sb := strings.builder_make_len_cap(0, len(s) / 2, allocator)
	last_write := 0
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if c != '%' {
			continue
		} else {
			strings.write_string(&sb, s[last_write:i])
			last_write = i + 3
			remaining_chars := len(s) - i
			if remaining_chars >= 2 {
				char, ok := _decode_octet(s[i + 1:1])
				if !ok {
					strings.builder_destroy(&sb)
					return "", false
				}
				strings.write_byte(&sb, char)
			}
		}
	}
	strings.write_string(&sb, s[last_write:len(s)])

	return strings.to_string(sb), true
}
// Encode per [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986)
encode_uri :: proc(s: string, allocator := context.allocator) -> string {
	encoded := strings.builder_make_len_cap(0, len(s), allocator)
	last_write := 0
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if is_alpha(c) || is_digit(c) || (c == '-' || c == '_' || c == '.' || c == '~') {
			continue
		} else {
			strings.write_string(&encoded, s[last_write:i])
			last_write = i + 1
			_encode_octet(&encoded, c)
		}
	}
	strings.write_string(&encoded, s[last_write:len(s)])

	return strings.to_string(encoded)
}

// Test for `[0..=9]`
is_digit :: proc(c: u8) -> bool {
	return '0' <= c && c <= '9'
}
// Test for `[a..=z|A..=Z]`
is_alpha :: proc(c: u8) -> bool {
	is_lower := 'a' <= c && c <= 'z'
	is_upper := 'A' <= c && c <= 'Z'
	return is_lower || is_upper
}
// Appends 3 bytes to sb: `%XX`
_encode_octet :: proc(sb: ^strings.Builder, c: u8) {
	strings.write_byte(sb, '%')
	h1, _ := hex_char(c >> 4) // Shift & mask; cannot fail on u8
	h2, _ := hex_char(c & 0xF)
	strings.write_byte(sb, h1)
	strings.write_byte(sb, h2)
}
// Expects the `len(s)==2`, the two characters in the octet. Do *not* include the `%`
_decode_octet :: proc(s: string) -> (char: u8, ok: bool) {
	assert(len(s) == 2)
	d1, d1ok := hex_digit(s[0])
	d2, d2ok := hex_digit(s[1])
	if !(d1ok && d2ok) {
		return 0, false
	}
	char = d1 << 4 | d2
	return char, true
}
// Convert a Number `0..=15` to a Char `[0..=9|A..=F]`
hex_char :: proc(n: u8) -> (char: u8, ok: bool = true) {
	if 0 <= n && n <= 9 {
		char = u8('0' + n)
	} else if 10 <= n && n <= 15 {
		char = u8('A' + n - 10)
	} else {
		ok = false
	}
	return
}
// Convert a Hex Char `[0..=9|a..=f|A..=F]` into a Number: `0..=15`
hex_digit :: proc(c: u8) -> (n: u8, ok: bool = true) {
	if '0' <= c && c <= '9' {
		n = u8(c - '0')
	} else if 'a' <= c && c <= 'f' {
		n = u8(c - 'a' + 10)
	} else if 'A' <= c && c <= 'F' {
		n = u8(c - 'A' + 10)
	} else {
		ok = false
	}
	return
}
