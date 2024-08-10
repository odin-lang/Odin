package encoding_hex

import "core:io"
import "core:strings"

encode :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> []byte #no_bounds_check {
	dst := make([]byte, len(src) * 2, allocator, loc)
	for i, j := 0, 0; i < len(src); i += 1 {
		v := src[i]
		dst[j]   = HEXTABLE[v>>4]
		dst[j+1] = HEXTABLE[v&0x0f]
		j += 2
	}

	return dst
}

encode_into_writer :: proc(dst: io.Writer, src: []byte) -> io.Error {
	for v in src {
		io.write(dst, {HEXTABLE[v>>4], HEXTABLE[v&0x0f]}) or_return
	}
	return nil
}

decode :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (dst: []byte, ok: bool) #no_bounds_check {
	if len(src) % 2 == 1 {
		return
	}

	dst = make([]byte, len(src) / 2, allocator, loc)
	for i, j := 0, 1; j < len(src); j += 2 {
		p := src[j-1]
		q := src[j]

		a := hex_digit(p) or_return
		b := hex_digit(q) or_return

		dst[i] = (a << 4) | b
		i += 1
	}

	return dst, true
}

// Decodes the given sequence into one byte.
// Should be called with one byte worth of the source, eg: 0x23 -> '#'.
decode_sequence :: proc(str: string) -> (res: byte, ok: bool) {
	str := str
	if strings.has_prefix(str, "0x") || strings.has_prefix(str, "0X") {
		str = str[2:]
	}

	if len(str) != 2 {
		return 0, false
	}

	upper := hex_digit(str[0]) or_return
	lower := hex_digit(str[1]) or_return

	return upper << 4 | lower, true
}

@(private)
HEXTABLE := [16]byte {
	'0', '1', '2', '3',
	'4', '5', '6', '7',
	'8', '9', 'a', 'b',
	'c', 'd', 'e', 'f',
}

@(private)
hex_digit :: proc(char: byte) -> (u8, bool) {
	switch char {
	case '0' ..= '9': return char - '0', true
	case 'a' ..= 'f': return char - 'a' + 10, true
	case 'A' ..= 'F': return char - 'A' + 10, true
	case:             return 0, false
	}
}