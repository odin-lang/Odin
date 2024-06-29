package unicode

MAX_RUNE         :: '\U00010fff' // Maximum valid unicode code point
REPLACEMENT_CHAR :: '\ufffd'     // Represented an invalid code point
MAX_ASCII        :: '\u007f'     // Maximum ASCII value
MAX_LATIN1       :: '\u00ff'     // Maximum Latin-1 value

ZERO_WIDTH_SPACE      :: '\u200B'
ZERO_WIDTH_NON_JOINER :: '\u200C'
ZERO_WIDTH_JOINER     :: '\u200D'
WORD_JOINER           :: '\u2060'

@(require_results)
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

@(require_results)
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
@(require_results)
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
@(require_results)
to_title :: proc(r: rune) -> rune {
	c := i32(r)
	p := binary_search(c, to_upper_singlets[:], len(to_title_singlets)/2, 2)
	if p >= 0 && c == to_upper_singlets[p] {
		return rune(c + to_title_singlets[p+1] - 500)
	}
	return rune(c)
}


@(require_results)
is_lower :: proc(r: rune) -> bool {
	if r <= MAX_ASCII {
		return u32(r)-'a' < 26
	}
	c := i32(r)
	p := binary_search(c, to_upper_ranges[:], len(to_upper_ranges)/3, 3)
	if p >= 0 && to_upper_ranges[p] <= c && c <= to_upper_ranges[p+1] {
		return true
	}
	p = binary_search(c, to_upper_singlets[:], len(to_upper_singlets)/2, 2)
	if p >= 0 && c == to_upper_singlets[p] {
		return true
	}
	return false
}

@(require_results)
is_upper :: proc(r: rune) -> bool {
	if r <= MAX_ASCII {
		return u32(r)-'A' < 26
	}
	c := i32(r)
	p := binary_search(c, to_lower_ranges[:], len(to_lower_ranges)/3, 3)
	if p >= 0 && to_lower_ranges[p] <= c && c <= to_lower_ranges[p+1] {
		return true
	}
	p = binary_search(c, to_lower_singlets[:], len(to_lower_singlets)/2, 2)
	if p >= 0 && c == to_lower_singlets[p] {
		return true
	}
	return false
}

is_alpha :: is_letter
@(require_results)
is_letter :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pLmask != 0
	}
	if is_upper(r) || is_lower(r) {
		return true
	}

	c := i32(r)
	p := binary_search(c, alpha_ranges[:], len(alpha_ranges)/2, 2)
	if p >= 0 && alpha_ranges[p] <= c && c <= alpha_ranges[p+1] {
		return true
	}
	p = binary_search(c, alpha_singlets[:], len(alpha_singlets), 1)
	if p >= 0 && c == alpha_singlets[p] {
		return true
	}
	return false
}

@(require_results)
is_title :: proc(r: rune) -> bool {
	return is_upper(r) && is_lower(r)
}

@(require_results)
is_digit :: proc(r: rune) -> bool {
	if r <= MAX_LATIN1 {
		return '0' <= r && r <= '9'
	}
	return false
}


is_white_space :: is_space
@(require_results)
is_space :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		switch r {
		case '\t', '\n', '\v', '\f', '\r', ' ', 0x85, 0xa0:
			return true
		}
		return false
	}
	c := i32(r)
	p := binary_search(c, space_ranges[:], len(space_ranges)/2, 2)
	if p >= 0 && space_ranges[p] <= c && c <= space_ranges[p+1] {
		return true
	}
	return false
}

@(require_results)
is_combining :: proc(r: rune) -> bool {
	c := i32(r)

	return c >= 0x0300 && (c <= 0x036f ||
	      (c >= 0x1ab0 && c <= 0x1aff) ||
	      (c >= 0x1dc0 && c <= 0x1dff) ||
	      (c >= 0x20d0 && c <= 0x20ff) ||
	      (c >= 0xfe20 && c <= 0xfe2f))
}



@(require_results)
is_graphic :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pg != 0
	}
	return false
}

@(require_results)
is_print :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pp != 0
	}
	return false
}

@(require_results)
is_control :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pC != 0
	}
	return false
}

@(require_results)
is_number :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pN != 0
	}
	return false
}

@(require_results)
is_punct :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pP != 0
	}
	return false
}

@(require_results)
is_symbol :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pS != 0
	}
	return false
}

//
// The procedures below are accurate as of Unicode 15.1.0.
//

// Emoji_Modifier
@(require_results)
is_emoji_modifier :: proc(r: rune) -> bool {
	return 0x1F3FB <= r && r <= 0x1F3FF
}

// Regional_Indicator
@(require_results)
is_regional_indicator :: proc(r: rune) -> bool {
	return 0x1F1E6 <= r && r <= 0x1F1FF
}

// General_Category=Enclosing_Mark
@(require_results)
is_enclosing_mark :: proc(r: rune) -> bool {
	switch r {
	case 0x0488,
	     0x0489,
	     0x1ABE,
	     0x20DD ..= 0x20E0,
	     0x20E2 ..= 0x20E4,
	     0xA670 ..= 0xA672:
		return true
	}

	return false
}

// Prepended_Concatenation_Mark
@(require_results)
is_prepended_concatenation_mark :: proc(r: rune) -> bool {
	switch r {
	case 0x00600 ..= 0x00605,
	     0x006DD,
	     0x0070F,
	     0x00890 ..= 0x00891,
	     0x008E2,
	     0x110BD,
	     0x110CD:
		return true
	case:
		return false
	}
}

// General_Category=Spacing_Mark
@(require_results)
is_spacing_mark :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, spacing_mark_ranges[:], len(spacing_mark_ranges)/2, 2)
	if p >= 0 && spacing_mark_ranges[p] <= c && c <= spacing_mark_ranges[p+1] {
		return true
	}
	return false
}

// General_Category=Nonspacing_Mark
@(require_results)
is_nonspacing_mark :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, nonspacing_mark_ranges[:], len(nonspacing_mark_ranges)/2, 2)
	if p >= 0 && nonspacing_mark_ranges[p] <= c && c <= nonspacing_mark_ranges[p+1] {
		return true
	}
	return false
}

// Extended_Pictographic
@(require_results)
is_emoji_extended_pictographic :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, emoji_extended_pictographic_ranges[:], len(emoji_extended_pictographic_ranges)/2, 2)
	if p >= 0 && emoji_extended_pictographic_ranges[p] <= c && c <= emoji_extended_pictographic_ranges[p+1] {
		return true
	}
	return false
}

// Grapheme_Extend
@(require_results)
is_grapheme_extend :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, grapheme_extend_ranges[:], len(grapheme_extend_ranges)/2, 2)
	if p >= 0 && grapheme_extend_ranges[p] <= c && c <= grapheme_extend_ranges[p+1] {
		return true
	}
	return false
}


// Hangul_Syllable_Type=Leading_Jamo
@(require_results)
is_hangul_syllable_leading :: proc(r: rune) -> bool {
	return 0x1100 <= r && r <= 0x115F || 0xA960 <= r && r <= 0xA97C
}

// Hangul_Syllable_Type=Vowel_Jamo
@(require_results)
is_hangul_syllable_vowel :: proc(r: rune) -> bool {
	return 0x1160 <= r && r <= 0x11A7 || 0xD7B0 <= r && r <= 0xD7C6
}

// Hangul_Syllable_Type=Trailing_Jamo
@(require_results)
is_hangul_syllable_trailing :: proc(r: rune) -> bool {
	return 0x11A8 <= r && r <= 0x11FF || 0xD7CB <= r && r <= 0xD7FB
}

// Hangul_Syllable_Type=LV_Syllable
@(require_results)
is_hangul_syllable_lv :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, hangul_syllable_lv_singlets[:], len(hangul_syllable_lv_singlets), 1)
	if p >= 0 && c == hangul_syllable_lv_singlets[p] {
		return true
	}
	return false
}

// Hangul_Syllable_Type=LVT_Syllable
@(require_results)
is_hangul_syllable_lvt :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, hangul_syllable_lvt_ranges[:], len(hangul_syllable_lvt_ranges)/2, 2)
	if p >= 0 && hangul_syllable_lvt_ranges[p] <= c && c <= hangul_syllable_lvt_ranges[p+1] {
		return true
	}
	return false
}


// Indic_Syllabic_Category=Consonant_Preceding_Repha
@(require_results)
is_indic_consonant_preceding_repha :: proc(r: rune) -> bool {
	switch r {
	case 0x00D4E,
	     0x11941,
	     0x11D46,
	     0x11F02:
		return true
	case:
		return false
	}
}

// Indic_Syllabic_Category=Consonant_Prefixed
@(require_results)
is_indic_consonant_prefixed :: proc(r: rune) -> bool {
	switch r {
	case 0x111C2 ..= 0x111C3,
	     0x1193F,
	     0x11A3A,
	     0x11A84 ..= 0x11A89:
		return true
	case:
		return false
	}
}

// Indic_Conjunct_Break=Linker
@(require_results)
is_indic_conjunct_break_linker :: proc(r: rune) -> bool {
	switch r {
	case 0x094D,
	     0x09CD,
	     0x0ACD,
	     0x0B4D,
	     0x0C4D,
	     0x0D4D:
		return true
	case:
		return false
	}
}

// Indic_Conjunct_Break=Consonant
@(require_results)
is_indic_conjunct_break_consonant :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, indic_conjunct_break_consonant_ranges[:], len(indic_conjunct_break_consonant_ranges)/2, 2)
	if p >= 0 && indic_conjunct_break_consonant_ranges[p] <= c && c <= indic_conjunct_break_consonant_ranges[p+1] {
		return true
	}
	return false
}

// Indic_Conjunct_Break=Extend
@(require_results)
is_indic_conjunct_break_extend :: proc(r: rune) -> bool {
	c := i32(r)
	p := binary_search(c, indic_conjunct_break_extend_ranges[:], len(indic_conjunct_break_extend_ranges)/2, 2)
	if p >= 0 && indic_conjunct_break_extend_ranges[p] <= c && c <= indic_conjunct_break_extend_ranges[p+1] {
		return true
	}
	return false
}


/*
For grapheme text segmentation, from Unicode TR 29 Rev 43:

```
Indic_Syllabic_Category = Consonant_Preceding_Repha, or
Indic_Syllabic_Category = Consonant_Prefixed, or
Prepended_Concatenation_Mark = Yes
```
*/
@(require_results)
is_gcb_prepend_class :: proc(r: rune) -> bool {
	return is_indic_consonant_preceding_repha(r) || is_indic_consonant_prefixed(r) || is_prepended_concatenation_mark(r)
}

/*
For grapheme text segmentation, from Unicode TR 29 Rev 43:

```
Grapheme_Extend = Yes, or
Emoji_Modifier = Yes

This includes:
General_Category = Nonspacing_Mark
General_Category = Enclosing_Mark
U+200C ZERO WIDTH NON-JOINER

plus a few General_Category = Spacing_Mark needed for canonical equivalence.
```
*/
@(require_results)
is_gcb_extend_class :: proc(r: rune) -> bool {
	return is_grapheme_extend(r) || is_emoji_modifier(r)
}

// Return values:
//
// - 2 if East_Asian_Width=F or W, or
// - 0 if non-printable / zero-width, or
// - 1 in all other cases.
//
@(require_results)
normalized_east_asian_width :: proc(r: rune) -> int {
	// This is a different interpretation of the BOM which occurs in the middle of text.
	ZERO_WIDTH_NO_BREAK_SPACE :: '\uFEFF'

	if is_control(r) {
		return 0
	} else if r <= 0x10FF {
		// Easy early out for low runes.
		return 1
	}

	switch r {
	case ZERO_WIDTH_NO_BREAK_SPACE,
	     ZERO_WIDTH_SPACE,
	     ZERO_WIDTH_NON_JOINER,
	     ZERO_WIDTH_JOINER,
	     WORD_JOINER:
		return 0
	}

	c := i32(r)
	p := binary_search(c, normalized_east_asian_width_ranges[:], len(normalized_east_asian_width_ranges)/3, 3)
	if p >= 0 && normalized_east_asian_width_ranges[p] <= c && c <= normalized_east_asian_width_ranges[p+1] {
		return cast(int)normalized_east_asian_width_ranges[p+2]
	}
	return 1
}

//
// End of Unicode 15.1.0 block.
//
