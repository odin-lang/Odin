package utf8string

import "core:unicode/utf8"
import "base:runtime"
import "base:builtin"

String :: struct {
	contents:   string,
	rune_count: int,

	// cached information
	non_ascii:  int, // index to non-ascii code points
	width:      int, // 0 if ascii
	byte_pos:   int,
	rune_pos:   int,
}

@(private)
_len :: builtin.len // helper procedure

init :: proc(s: ^String, contents: string) -> ^String {
	s.contents = contents
	s.byte_pos = 0
	s.rune_pos = 0

	for i in 0..<_len(contents) {
		if contents[i] >= utf8.RUNE_SELF {
			s.rune_count = utf8.rune_count_in_string(contents)
			_, s.width = utf8.decode_rune_in_string(contents)
			s.non_ascii = i
			return s
		}
	}

	s.rune_count = _len(contents)
	s.width = 0
	s.non_ascii = _len(contents)
	return s
}

to_string :: proc(s: ^String) -> string {
	return s.contents
}

len :: proc(s: ^String) -> int {
	return s.rune_count
}


is_ascii :: proc(s: ^String) -> bool {
	return s.width == 0
}

at :: proc(s: ^String, i: int, loc := #caller_location) -> (r: rune) {
	runtime.bounds_check_error_loc(loc, i, s.rune_count)

	if i < s.non_ascii {
		return rune(s.contents[i])
	}

	switch i {
	case 0:
		r, s.width = utf8.decode_rune_in_string(s.contents)
		s.rune_pos = 0
		s.byte_pos = 0
		return

	case s.rune_count-1:
		r, s.width = utf8.decode_last_rune(s.contents)
		s.rune_pos = i
		s.byte_pos = _len(s.contents) - s.width
		return

	case s.rune_pos-1:
		r, s.width = utf8.decode_rune_in_string(s.contents[0:s.byte_pos])
		s.rune_pos = i
		s.byte_pos -= s.width
		return

	case s.rune_pos+1:
		s.rune_pos = i
		s.byte_pos += s.width
		fallthrough
	case s.rune_pos:
		r, s.width = utf8.decode_rune_in_string(s.contents[s.byte_pos:])
		return
	}

	// Linear scan
	scan_forward := true
	if i < s.rune_pos {
		if i < (s.rune_pos-s.non_ascii)/2 {
			s.byte_pos, s.rune_pos = s.non_ascii, s.non_ascii
		} else {
			scan_forward = false
		}
	} else if i-s.rune_pos < (s.rune_count-s.rune_pos)/2 {
		// scan_forward = true
	} else {
		s.byte_pos, s.rune_pos = _len(s.contents), s.rune_count
		scan_forward = false
	}

	if scan_forward {
		for {
			r, s.width = utf8.decode_rune_in_string(s.contents[s.byte_pos:])
			if s.rune_pos == i {
				return
			}
			s.rune_pos += 1
			s.byte_pos += s.width

		}
	} else {
		for {
			r, s.width = utf8.decode_last_rune_in_string(s.contents[:s.byte_pos])
			s.rune_pos -= 1
			s.byte_pos -= s.width
			if s.rune_pos == i {
				return
			}
		}
	}
}

slice :: proc(s: ^String, i, j: int, loc := #caller_location) -> string {
	runtime.slice_expr_error_lo_hi_loc(loc, i, j, s.rune_count)

	if j < s.non_ascii {
		return s.contents[i:j]
	}

	if i == j {
		return ""
	}

	lo, hi: int
	if i < s.non_ascii {
		lo = i
	} else if i == s.rune_count {
		lo = _len(s.contents)
	} else {
		at(s, i, loc)
		lo = s.byte_pos
	}

	if j == s.rune_count {
		hi = _len(s.contents)
	} else {
		at(s, j, loc)
		hi = s.byte_pos
	}

	return s.contents[lo:hi]
}
