// Procedures and constants to support text-encoding in the `UTF-16` character encoding.
package utf16

import "core:unicode/utf8"

REPLACEMENT_CHAR :: '\ufffd'
MAX_RUNE         :: '\U0010ffff'

_surr1           :: 0xd800
_surr2           :: 0xdc00
_surr3           :: 0xe000
_surr_self       :: 0x10000


is_surrogate :: proc(r: rune) -> bool {
	return _surr1 <= r && r < _surr3
}

decode_surrogate_pair :: proc(r1, r2: rune) -> rune {
	if _surr1 <= r1 && r1 < _surr2 && _surr2 <= r2 && r2 < _surr3 {
		return (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self
	}
	return REPLACEMENT_CHAR
}


encode_surrogate_pair :: proc(c: rune) -> (r1, r2: rune) {
	r := c
	if r < _surr_self || r > MAX_RUNE {
		return REPLACEMENT_CHAR, REPLACEMENT_CHAR
	}
	r -= _surr_self
	return _surr1 + (r>>10)&0x3ff, _surr2 + r&0x3ff
}

encode :: proc(d: []u16, s: []rune) -> int {
	n, m := 0, len(d)
	loop: for r in s {
		switch r {
		case 0..<_surr1, _surr3 ..< _surr_self:
			if m+1 < n { break loop }
			d[n] = u16(r)
			n += 1

		case _surr_self ..= MAX_RUNE:
			if m+2 < n { break loop }
			r1, r2 := encode_surrogate_pair(r)
			d[n]    = u16(r1)
			d[n+1]  = u16(r2)
			n += 2

		case:
			if m+1 < n { break loop }
			d[n] = u16(REPLACEMENT_CHAR)
			n += 1
		}
	}
	return n
}


encode_string :: proc(d: []u16, s: string) -> int {
	n, m := 0, len(d)
	loop: for r in s {
		switch r {
		case 0..<_surr1, _surr3 ..< _surr_self:
			if m+1 < n { break loop }
			d[n] = u16(r)
			n += 1

		case _surr_self ..= MAX_RUNE:
			if m+2 < n { break loop }
			r1, r2 := encode_surrogate_pair(r)
			d[n]    = u16(r1)
			d[n+1]  = u16(r2)
			n += 2

		case:
			if m+1 < n { break loop }
			d[n] = u16(REPLACEMENT_CHAR)
			n += 1
		}
	}
	return n
}

decode :: proc(d: []rune, s: []u16) -> (n: int) {
	for i := 0; i < len(s); i += 1 {
		if n >= len(d) {
			return
		}
		
		r := rune(REPLACEMENT_CHAR)
		
		switch c := s[i]; {
		case c < _surr1, _surr3 <= c:
			r = rune(c)
		case _surr1 <= c && c < _surr2 && i+1 < len(s) && 
			_surr2 <= s[i+1] && s[i+1] < _surr3:
			r = decode_surrogate_pair(rune(c), rune(s[i+1]))
			i += 1
		}
		d[n] = r
		
		n += 1
	}
	return
}

decode_rune_in_string :: proc(s: string16) -> (r: rune, width: int) {
	r = rune(REPLACEMENT_CHAR)
	n := len(s)
	if n < 1 {
		return
	}
	width = 1


	switch c := s[0]; {
	case c < _surr1, _surr3 <= c:
		r = rune(c)
	case _surr1 <= c && c < _surr2 && 1 < len(s) &&
		_surr2 <= s[1] && s[1] < _surr3:
		r = decode_surrogate_pair(rune(c), rune(s[1]))
		width += 1
	}
	return
}

string_to_runes :: proc "odin" (s: string16, allocator := context.allocator) -> (runes: []rune) {
	n := rune_count(s)

	runes = make([]rune, n, allocator)
	i := 0
	for r in s {
		runes[i] = r
		i += 1
	}
	return
}


rune_count :: proc{
	rune_count_in_string,
	rune_count_in_slice,
}
rune_count_in_string :: proc(s: string16) -> (n: int) {
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if _surr1 <= c && c < _surr2 && i+1 < len(s) &&
			_surr2 <= s[i+1] && s[i+1] < _surr3 {
			i += 1
		}
		n += 1
	}
	return
}


rune_count_in_slice :: proc(s: []u16) -> (n: int) {
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if _surr1 <= c && c < _surr2 && i+1 < len(s) && 
			_surr2 <= s[i+1] && s[i+1] < _surr3 {
			i += 1
		}
		n += 1
	}
	return
}


decode_to_utf8 :: proc(d: []byte, s: []u16) -> (n: int) {
	for i := 0; i < len(s); i += 1 {
		if n >= len(d) {
			return
		}
		r := rune(REPLACEMENT_CHAR)
		
		switch c := s[i]; {
		case c < _surr1, _surr3 <= c:
			r = rune(c)
		case _surr1 <= c && c < _surr2 && i+1 < len(s) && 
			_surr2 <= s[i+1] && s[i+1] < _surr3:
			r = decode_surrogate_pair(rune(c), rune(s[i+1]))
			i += 1
		}
		
		b, w := utf8.encode_rune(rune(r))
		n += copy(d[n:], b[:w])
	}
	return
}
