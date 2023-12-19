package unicode

MAX_RUNE         :: '\U00010fff' // Maximum valid unicode code point
REPLACEMENT_CHAR :: '\ufffd'     // Represented an invalid code point
MAX_ASCII        :: '\u007f'     // Maximum ASCII value
MAX_LATIN1       :: '\u00ff'     // Maximum Latin-1 value

binary_search :: proc(c: i32, table: []i32, length, stride: int) -> int {
	n := length
	t := 0
	for n > 1 {
		m := n / 2
		p := t + m*stride
		if c >= table[p] {
			t = p
			n = n-m
		} else {
			n = m
		}
	}
	if n != 0 && c >= table[t] {
		return t
	}
	return -1
}

to_lower :: proc(r: rune) -> rune {
	c := i32(r)
	p := binary_search(c, to_lower_ranges[:], len(to_lower_ranges)/3, 3)
	if p >= 0 && to_lower_ranges[p] <= c && c <= to_lower_ranges[p+1] {
		return rune(c + to_lower_ranges[p+2] - 500)
	}
	p = binary_search(c, to_lower_singlets[:], len(to_lower_singlets)/2, 2)
	if p >= 0 && c == to_lower_singlets[p] {
		return rune(c + to_lower_singlets[p+1] - 500)
	}
	return rune(c)
}
to_upper :: proc(r: rune) -> rune {
	c := i32(r)
	p := binary_search(c, to_upper_ranges[:], len(to_upper_ranges)/3, 3)
	if p >= 0 && to_upper_ranges[p] <= c && c <= to_upper_ranges[p+1] {
		return rune(c + to_upper_ranges[p+2] - 500)
	}
	p = binary_search(c, to_upper_singlets[:], len(to_upper_singlets)/2, 2)
	if p >= 0 && c == to_upper_singlets[p] {
		return rune(c + to_upper_singlets[p+1] - 500)
	}
	return rune(c)
}
to_title :: proc(r: rune) -> rune {
	c := i32(r)
	p := binary_search(c, to_upper_singlets[:], len(to_title_singlets)/2, 2)
	if p >= 0 && c == to_upper_singlets[p] {
		return rune(c + to_title_singlets[p+1] - 500)
	}
	return rune(c)
}

is_lower :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return cat == .Ll
	}
	return false
}

is_upper :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return cat == .Lu
	}
	return false
}

is_title :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return cat == .Lt
	}
	return false
}

is_alpha :: is_letter
is_letter :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return false ||
			cat == .Lu ||
			cat == .Ll ||
			cat == .Lt ||
			cat == .Lm ||
			cat == .Lo
	}
	return false
}

is_digit :: proc(r: rune) -> bool {
	if r <= MAX_LATIN1 {
		return '0' <= r && r <= '9'
	}
	return false
}


is_white_space :: is_space
is_space :: proc(r: rune) -> bool {
	if r <= RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		// Note: Tab, CR and LF are control characters, so we handle them
		// specially. This might be a bit of a dodgy logic.
		return cat == .Zs || r == '\t' || r == '\r' || r == '\n'
	}
	return false
}

is_combining :: proc(r: rune) -> bool {
	c := i32(r)

	return c >= 0x0300 && (c <= 0x036f ||
          (c >= 0x1ab0 && c <= 0x1aff) ||
          (c >= 0x1dc0 && c <= 0x1dff) ||
          (c >= 0x20d0 && c <= 0x20ff) ||
          (c >= 0xfe20 && c <= 0xfe2f))
}


is_graphic :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return true &&
			!(.Cc <= cat && cat <= .Cn) &&
			!(.Zl <= cat && cat <= .Zs)
	}
	return false
}

is_print :: proc(r: rune) -> bool {
	if r == ' ' {
		return true
	}
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return true &&
			!(.Cc <= cat && cat <= .Cn) &&
			!(.Zl <= cat && cat <= .Zs)
	}
	return false
}

is_control :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return cat == .Cc
	}
	return false
}

is_number :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return cat == .Nd
	}
	return false
}

is_punct :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return .Pc <= cat && cat <= .Po
	}
	return false
}

is_symbol :: proc(r: rune) -> bool {
	if r < RUNE_LIMIT {
		block := r >> LOG2_BLOCK_SIZE
		index := r & (BLOCK_SIZE-1)
		cat := blocks[indices[block]][index]
		return .Sm <= cat && cat <= .So
	}
	return false
}
