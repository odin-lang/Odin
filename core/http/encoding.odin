package http
import "core:strings"

// NOTE: This file may want to move to "core:encoding/octet" (?)
/*
Decodes a `%octet` (eg `%2A -> '*'`) string. Invalid octets (eg not hex digits) are passed through unaltered.  
[URL-Spec](https://url.spec.whatwg.org/#percent-decode)  

**Allocates returned string**

Inputs:  
- `s`: A Percent-Encoded String
- `allocator`: (defaults to context)

Returns:  
- Copy of string with all valid `%octets` decoded

Example:  

	import "core:http"
	import "core:fmt"
	example_percent_decode :: proc() {
		str := "%2A_%FQ_%9" // One valid encoded item followed by two invalid encodings
		dec := http.percent_decode(str)
		fmt.println(dec)
	}

Output:  

	*_%FQ_%9

*/
percent_decode :: proc(sb:^strings.Builder, s: string) -> (str:string,n_written:int) {
	using strings
	n_written=0
	starts_at:=len(sb.buf)
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if c != '%' {
			n_written+=write_byte(sb, c)
		} else {
			if (i + 2) < len(s) {
				high_nibble := s[i + 1]
				low_nibble := s[i + 2]
				if !is_hex_digit(high_nibble) || !is_hex_digit(low_nibble) {
					// invalid octet, write and move on
					n_written+=write_byte(sb, c)
				} else {
					value := hex_digit(high_nibble) << 4 | hex_digit(low_nibble)
					n_written+=write_byte(sb, value)

					i += 2
				}
			} else {
				// insufficient length to have an octet, write out as-is:
				n_written+=write_byte(sb, c)
			}
		}
	}
	str = string(sb.buf[starts_at:starts_at+n_written])
	return
}
// Encode per [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986)
percent_encode :: proc(s: string, allocator := context.allocator) -> string {
	encoded := strings.builder_make_len_cap(0, len(s), allocator)
	last_write := 0
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if is_alpha(c) || is_digit(c) || (c == '-' || c == '_' || c == '.' || c == '~') {
			continue
		} else {
			strings.write_string(&encoded, s[last_write:i])
			last_write = i + 1
			strings.write_byte(&encoded, '%')
			h1, _ := hex_char(c >> 4) // Shift & mask; cannot fail on u8
			h2, _ := hex_char(c & 0xF)
			strings.write_byte(&encoded, h1)
			strings.write_byte(&encoded, h2)
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
is_hex_digit :: proc(c: u8) -> bool {
	if '0' <= c && c <= '9'  || 'a' <= c && c <= 'f' || 'A' <= c && c <= 'F'{
		return true
	}
	return false
}

// Convert a Hex Char `[0..=9|a..=f|A..=F]` into a Number: `0..=15`. Failure returns 255
hex_digit :: proc(c: u8) -> (n: u8) {
	if '0' <= c && c <= '9' {
		n = u8(c - '0')
	} else if 'a' <= c && c <= 'f' {
		n = u8(c - 'a' + 10)
	} else if 'A' <= c && c <= 'F' {
		n = u8(c - 'A' + 10)
	} else {
		n = 255
	}
	return
}
hex_digit_safe :: proc(c: u8) -> (n: u8, ok: bool = true) {
	n=hex_digit(c)
	if n == 255 {
		ok = false
	}
	return
}