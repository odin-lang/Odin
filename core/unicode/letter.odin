package unicode

MAX_RUNE         :: '\U00010fff'; // Maximum valid unicode code point
REPLACEMENT_CHAR :: '\ufffd';     // Represented an invalid code point
MAX_ASCII        :: '\u007f';     // Maximum ASCII value
MAX_LATIN1       :: '\u00ff';     // Maximum Latin-1 value

binary_search :: proc(c: i32, table: []i32, length, stride: int) -> int {
	n := length;
	t := 0;
	for n > 1 {
		m := n / 2;
		p := t + m*stride;
		if c >= table[p] {
			t = p;
			n = n-m;
		} else {
			n = m;
		}
	}
	if n != 0 && c >= table[t] {
		return t;
	}
	return -1;
}

to_lower :: proc(r: rune) -> rune {
	c := i32(r);
	p := binary_search(c, to_lower_ranges[:], len(to_lower_ranges)/3, 3);
	if p >= 0 && to_lower_ranges[p] <= c && c <= to_lower_ranges[p+1] {
		return rune(c + to_lower_ranges[p+2] - 500);
	}
	p = binary_search(c, to_lower_singlets[:], len(to_lower_singlets)/2, 2);
	if p >= 0 && c == to_lower_singlets[p] {
		return rune(c + to_lower_singlets[p+1] - 500);
	}
	return rune(c);
}
to_upper :: proc(r: rune) -> rune {
	c := i32(r);
	p := binary_search(c, to_upper_ranges[:], len(to_upper_ranges)/3, 3);
	if p >= 0 && to_upper_ranges[p] <= c && c <= to_upper_ranges[p+1] {
		return rune(c + to_upper_ranges[p+2] - 500);
	}
	p = binary_search(c, to_upper_singlets[:], len(to_upper_singlets)/2, 2);
	if p >= 0 && c == to_upper_singlets[p] {
		return rune(c + to_upper_singlets[p+1] - 500);
	}
	return rune(c);
}
to_title :: proc(r: rune) -> rune {
	c := i32(r);
	p := binary_search(c, to_upper_singlets[:], len(to_title_singlets)/2, 2);
	if p >= 0 && c == to_upper_singlets[p] {
		return rune(c + to_title_singlets[p+1] - 500);
	}
	return rune(c);
}


is_lower :: proc(r: rune) -> bool {
	if r <= MAX_ASCII {
		return u32(r)-'a' < 26;
	}
	c := i32(r);
	p := binary_search(c, to_upper_ranges[:], len(to_upper_ranges)/3, 3);
	if p >= 0 && to_upper_ranges[p] <= c && c <= to_upper_ranges[p+1] {
		return true;
	}
	p = binary_search(c, to_upper_singlets[:], len(to_upper_singlets)/2, 2);
	if p >= 0 && c == to_upper_singlets[p] {
		return true;
	}
	return false;
}

is_upper :: proc(r: rune) -> bool {
	if r <= MAX_ASCII {
		return u32(r)-'A' < 26;
	}
	c := i32(r);
	p := binary_search(c, to_lower_ranges[:], len(to_lower_ranges)/3, 3);
	if p >= 0 && to_lower_ranges[p] <= c && c <= to_lower_ranges[p+1] {
		return true;
	}
	p = binary_search(c, to_lower_singlets[:], len(to_lower_singlets)/2, 2);
	if p >= 0 && c == to_lower_singlets[p] {
		return true;
	}
	return false;
}

is_alpha :: is_letter;
is_letter :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pLmask != 0;
	}
	if is_upper(r) || is_lower(r) {
		return true;
	}

	c := i32(r);
	p := binary_search(c, alpha_ranges[:], len(alpha_ranges)/2, 2);
	if p >= 0 && alpha_ranges[p] <= c && c <= alpha_ranges[p+1] {
		return true;
	}
	p = binary_search(c, alpha_singlets[:], len(alpha_singlets), 1);
	if p >= 0 && c == alpha_singlets[p] {
		return true;
	}
	return false;
}

is_title :: proc(r: rune) -> bool {
	return is_upper(r) && is_lower(r);
}

is_digit :: proc(r: rune) -> bool {
	if r <= MAX_LATIN1 {
		return '0' <= r && r <= '9';
	}
	return false;
}


is_white_space :: is_space;
is_space :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		switch r {
		case '\t', '\n', '\v', '\f', '\r', ' ', 0x85, 0xa0:
			return true;
		}
		return false;
	}
	c := i32(r);
	p := binary_search(c, space_ranges[:], len(space_ranges)/2, 2);
	if p >= 0 && space_ranges[p] <= c && c <= space_ranges[p+1] {
		return true;
	}
	return false;
}

is_combining :: proc(r: rune) -> bool {
	c := i32(r);

	return c >= 0x0300 && (c <= 0x036f ||
          (c >= 0x1ab0 && c <= 0x1aff) ||
          (c >= 0x1dc0 && c <= 0x1dff) ||
          (c >= 0x20d0 && c <= 0x20ff) ||
          (c >= 0xfe20 && c <= 0xfe2f));
}



is_graphic :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pg != 0;
	}
	return false;
}

is_print :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pp != 0;
	}
	return false;
}

is_control :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pC != 0;
	}
	return false;
}

is_number :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pN != 0;
	}
	return false;
}

is_punct :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pP != 0;
	}
	return false;
}

is_symbol :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pS != 0;
	}
	return false;
}
