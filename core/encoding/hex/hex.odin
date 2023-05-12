package hex

import "core:strings"

encode :: proc(src: []byte, allocator := context.allocator) -> []byte #no_bounds_check {
	dst := make([]byte, len(src) * 2, allocator)
    for i := 0; i < len(src); i += 1 {
		v := src[i]
        dst[i]   = HEXTABLE[v>>4]
        dst[i+1] = HEXTABLE[v&0x0f]
        i += 2
    }

	return dst
}


decode :: proc(src: []byte, allocator := context.allocator) -> (dst: []byte, ok: bool) #no_bounds_check {
	if len(src) % 2 == 1 {
		return
	}

	dst = make([]byte, len(src) / 2, allocator)
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
// Should be called with one rune worth of the source, eg: 0x23 -> '#'.
decode_sequence :: proc(str: string) -> (byte, bool) {
	no_prefix_str := strings.trim_prefix(str, "0x")
	val: byte
	for i := 0; i < len(no_prefix_str); i += 1 {
		index := (len(no_prefix_str) - 1) - i // reverse the loop.

		hd, ok := hex_digit(no_prefix_str[i])
		if !ok {
			return 0, false
		}

		val += u8(hd) << uint(4 * index)
	}

	return val, true
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

