package utf8

RUNE_ERROR :: '\ufffd';
RUNE_SELF  :: 0x80;
RUNE_BOM   :: 0xfeff;
RUNE_EOF   :: ~rune(0);
MAX_RUNE   :: '\U0010ffff';
UTF_MAX    :: 4;

SURROGATE_MIN :: 0xd800;
SURROGATE_MAX :: 0xdfff;

T1 :: 0b0000_0000;
TX :: 0b1000_0000;
T2 :: 0b1100_0000;
T3 :: 0b1110_0000;
T4 :: 0b1111_0000;
T5 :: 0b1111_1000;

MASKX :: 0b0011_1111;
MASK2 :: 0b0001_1111;
MASK3 :: 0b0000_1111;
MASK4 :: 0b0000_0111;

RUNE1_MAX :: 1<<7 - 1;
RUNE2_MAX :: 1<<11 - 1;
RUNE3_MAX :: 1<<16 - 1;

// The default lowest and highest continuation byte.
LOCB :: 0b1000_0000;
HICB :: 0b1011_1111;

Accept_Range :: struct {lo, hi: u8};

accept_ranges := [5]Accept_Range{
	{0x80, 0xbf},
	{0xa0, 0xbf},
	{0x80, 0x9f},
	{0x90, 0xbf},
	{0x80, 0x8f},
};

accept_sizes := [256]u8{
	0x00..0x7f = 0xf0,
	0x80..0xc1 = 0xf1,
	0xc2..0xdf = 0x02,
	0xe0       = 0x13,
	0xe1..0xec = 0x03,
	0xed       = 0x23,
	0xee..0xef = 0x03,
	0xf0       = 0x34,
	0xf1..0xf3 = 0x04,
	0xf4       = 0x44,
	0xf5..0xff = 0xf1,
};

encode_rune :: proc(c: rune) -> ([4]u8, int) {
	r := c;

	buf: [4]u8;
	i := u32(r);
	mask :: u8(0x3f);
	if i <= 1<<7-1 {
		buf[0] = u8(r);
		return buf, 1;
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | u8(r>>6);
		buf[1] = 0x80 | u8(r) & mask;
		return buf, 2;
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (0xd800 <= i && i <= 0xdfff) {
		r = 0xfffd;
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | u8(r>>12);
		buf[1] = 0x80 | u8(r>>6) & mask;
		buf[2] = 0x80 | u8(r)    & mask;
		return buf, 3;
	}

	buf[0] = 0xf0 | u8(r>>18);
	buf[1] = 0x80 | u8(r>>12) & mask;
	buf[2] = 0x80 | u8(r>>6)  & mask;
	buf[3] = 0x80 | u8(r)     & mask;
	return buf, 4;
}

decode_rune_in_string :: inline proc(s: string) -> (rune, int) do return decode_rune(transmute([]u8)s);
decode_rune :: proc(s: []u8) -> (rune, int) {
	n := len(s);
	if n < 1 {
		return RUNE_ERROR, 0;
	}
	s0 := s[0];
	x := accept_sizes[s0];
	if x >= 0xF0 {
		mask := rune(x) << 31 >> 31; // NOTE(bill): Create 0x0000 or 0xffff.
		return rune(s[0])&~mask | RUNE_ERROR&mask, 1;
	}
	sz := x & 7;
	accept := accept_ranges[x>>4];
	if n < int(sz) {
		return RUNE_ERROR, 1;
	}
	b1 := s[1];
	if b1 < accept.lo || accept.hi < b1 {
		return RUNE_ERROR, 1;
	}
	if sz == 2 {
		return rune(s0&MASK2)<<6 | rune(b1&MASKX), 2;
	}
	b2 := s[2];
	if b2 < LOCB || HICB < b2 {
		return RUNE_ERROR, 1;
	}
	if sz == 3 {
		return rune(s0&MASK3)<<12 | rune(b1&MASKX)<<6 | rune(b2&MASKX), 3;
	}
	b3 := s[3];
	if b3 < LOCB || HICB < b3 {
		return RUNE_ERROR, 1;
	}
	return rune(s0&MASK4)<<18 | rune(b1&MASKX)<<12 | rune(b2&MASKX)<<6 | rune(b3&MASKX), 4;
}



decode_last_rune_in_string :: inline proc(s: string) -> (rune, int) do return decode_last_rune(transmute([]u8)s);
decode_last_rune :: proc(s: []u8) -> (rune, int) {
	r: rune;
	size: int;
	start, end, limit: int;

	end = len(s);
	if end == 0 {
		return RUNE_ERROR, 0;
	}
	start = end-1;
	r = rune(s[start]);
	if r < RUNE_SELF {
		return r, 1;
	}


	limit = max(end - UTF_MAX, 0);

	for start-=1; start >= limit; start-=1 {
		if rune_start(s[start]) do break;
	}

	start = max(start, 0);
	r, size = decode_rune(s[start:end]);
	if start+size != end {
		return RUNE_ERROR, 1;
	}
	return r, size;
}

rune_at_pos :: proc(s: string, pos: int) -> rune {
	if pos < 0 {
		return RUNE_ERROR;
	}

	i := 0;
	for r in s {
		if i == pos {
			return r;
		}
		i += 1;
	}
	return RUNE_ERROR;
}

rune_string_at_pos :: proc(s: string, pos: int) -> string {
	if pos < 0 {
		return "";
	}

	i := 0;
	for c, offset in s {
		if i == pos {
			w := rune_size(c);
			return s[offset:][:w];
		}
		i += 1;
	}
	return "";
}

rune_at :: proc(s: string, byte_index: int) -> rune {
	r, _ := decode_rune_in_string(s[byte_index:]);
	return r;
}

// Returns the byte position of rune at position pos in s with an optional start byte position.
// Returns -1 if it runs out of the string.
rune_offset :: proc(s: string, pos: int, start: int = 0) -> int {
	if pos < 0 {
		return -1;
	}

	i := 0;
	for _, offset in s[start:] {
		if i == pos {
			return offset+start;
		}
		i += 1;
	}
	return -1;
}

valid_rune :: proc(r: rune) -> bool {
	if r < 0 {
		return false;
	} else if SURROGATE_MIN <= r && r <= SURROGATE_MAX {
		return false;
	} else if r > MAX_RUNE {
		return false;
	}
	return true;
}

valid_string :: proc(s: string) -> bool {
	n := len(s);
	for i := 0; i < n; {
		si := s[i];
		if si < RUNE_SELF { // ascii
			i += 1;
			continue;
		}
		x := accept_sizes[si];
		if x == 0xf1 {
			return false;
		}
		size := int(x & 7);
		if i+size > n {
			return false;
		}
		ar := accept_ranges[x>>4];
		if b := s[i+1]; b < ar.lo || ar.hi < b {
			return false;
		} else if size == 2 {
			// Okay
		} else if c := s[i+2]; c < 0x80 || 0xbf < c {
			return false;
		} else if size == 3 {
			// Okay
		} else if d := s[i+3]; b < 0x80 || 0xbf < d {
			return false;
		}
		i += size;
	}
	return true;
}

rune_start :: inline proc(b: u8) -> bool do return b&0xc0 != 0x80;

rune_count_in_string :: inline proc(s: string) -> int do return rune_count(transmute([]u8)s);
rune_count :: proc(s: []u8) -> int {
	count := 0;
	n := len(s);

	for i := 0; i < n; {
		defer count += 1;
		si := s[i];
		if si < RUNE_SELF { // ascii
			i += 1;
			continue;
		}
		x := accept_sizes[si];
		if x == 0xf1 {
			i += 1;
			continue;
		}
		size := int(x & 7);
		if i+size > n {
			i += 1;
			continue;
		}
		ar := accept_ranges[x>>4];
		if b := s[i+1]; b < ar.lo || ar.hi < b {
			size = 1;
		} else if size == 2 {
			// Okay
		} else if c := s[i+2]; c < 0x80 || 0xbf < c {
			size = 1;
		} else if size == 3 {
			// Okay
		} else if d := s[i+3]; d < 0x80 || 0xbf < d {
			size = 1;
		}
		i += size;
	}
	return count;
}


rune_size :: proc(r: rune) -> int {
	switch {
	case r < 0:          return -1;
	case r <= 1<<7  - 1: return 1;
	case r <= 1<<11 - 1: return 2;
	case SURROGATE_MIN <= r && r <= SURROGATE_MAX: return -1;
	case r <= 1<<16 - 1: return 3;
	case r <= MAX_RUNE:  return 4;
	}
	return -1;
}
