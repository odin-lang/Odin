package c_frontend_preprocess

import "core:unicode/utf8"

unquote_char :: proc(str: string, quote: byte) -> (r: rune, multiple_bytes: bool, tail_string: string, success: bool) {
	hex_to_int :: proc(c: byte) -> int {
		switch c {
		case '0'..='9': return int(c-'0')
		case 'a'..='f': return int(c-'a')+10
		case 'A'..='F': return int(c-'A')+10
		}
		return -1
	}
	w: int

	if str[0] == quote && quote == '"' {
		return
	} else if str[0] >= 0x80 {
		r, w = utf8.decode_rune_in_string(str)
		return r, true, str[w:], true
	} else if str[0] != '\\' {
		return rune(str[0]), false, str[1:], true
	}

	if len(str) <= 1 {
		return
	}
	s := str
	c := s[1]
	s = s[2:]

	switch c {
	case: r = rune(c)

	case 'a':  r = '\a'
	case 'b':  r = '\b'
	case 'e':  r = '\e'
	case 'f':  r = '\f'
	case 'n':  r = '\n'
	case 'r':  r = '\r'
	case 't':  r = '\t'
	case 'v':  r = '\v'
	case '\\': r = '\\'

	case '"':  r = '"'
	case '\'': r = '\''

	case '0'..='7':
		v := int(c-'0')
		if len(s) < 2 {
			return
		}
		for i in 0..<len(s) {
			d := int(s[i]-'0')
			if d < 0 || d > 7 {
				return
			}
			v = (v<<3) | d
		}
		s = s[2:]
		if v > 0xff {
			return
		}
		r = rune(v)

	case 'x', 'u', 'U':
		count: int
		switch c {
		case 'x': count = 2
		case 'u': count = 4
		case 'U': count = 8
		}

		if len(s) < count {
			return
		}

		for i in 0..<count {
			d := hex_to_int(s[i])
			if d < 0 {
				return
			}
			r = (r<<4) | rune(d)
		}
		s = s[count:]
		if c == 'x' {
			break
		}
		if r > utf8.MAX_RUNE {
			return
		}
		multiple_bytes = true
	}

	success = true
	tail_string = s
	return
}

unquote_string :: proc(lit: string, allocator := context.allocator) -> (res: string, allocated, success: bool) {
	contains_rune :: proc(s: string, r: rune) -> int {
		for c, offset in s {
			if c == r {
				return offset
			}
		}
		return -1
	}

	assert(len(lit) >= 2)

	s := lit
	quote := '"'

	if s == `""` {
		return "", false, true
	}

	if contains_rune(s, '\n') >= 0 {
		return s, false, false
	}

	if contains_rune(s, '\\') < 0 && contains_rune(s, quote) < 0 {
		if quote == '"' {
			return s, false, true
		}
	}
	s = s[1:len(s)-1]


	buf_len := 3*len(s) / 2
	buf := make([]byte, buf_len, allocator)
	offset := 0
	for len(s) > 0 {
		r, multiple_bytes, tail_string, ok := unquote_char(s, byte(quote))
		if !ok {
			delete(buf)
			return s, false, false
		}
		s = tail_string
		if r < 0x80 || !multiple_bytes {
			buf[offset] = byte(r)
			offset += 1
		} else {
			b, w := utf8.encode_rune(r)
			copy(buf[offset:], b[:w])
			offset += w
		}
	}

	new_string := string(buf[:offset])

	return new_string, true, true
}
