package unicode

import "base:runtime"

/*
The maximum valid Unicode code point, `U+10FFFF`.
*/
MAX_RUNE :: '\U0010ffff'

/*
`U+FFFD`, the replacement character, which stands in for a code point that is
invalid or unrecognised.
*/
REPLACEMENT_CHAR :: '\ufffd'

/*
The highest code point in the ASCII range, `U+007F` (DEL).
*/
MAX_ASCII :: '\u007f'

/*
The highest code point in the Latin-1 range, `U+00FF`.
*/
MAX_LATIN1 :: '\u00ff'

/*
`U+200B`, the zero width space. It has no width, but it is still counted as
whitespace by [[is_space]].
*/
ZERO_WIDTH_SPACE :: '\u200B'

/*
`U+200C`, the zero width non-joiner. It suppresses the ligature or joining
form that would otherwise form between the characters on either side of it.
*/
ZERO_WIDTH_NON_JOINER :: '\u200C'

/*
`U+200D`, the zero width joiner. It requests the ligature or joining form
between the characters on either side of it.
*/
ZERO_WIDTH_JOINER :: '\u200D'

/*
`U+2060`, the word joiner. Marks a position at which a line break is not
permitted.
*/
WORD_JOINER :: '\u2060'

@(require_results)
binary_search :: proc(c: $T, table: []T, length, stride: int, loc := #caller_location) -> int #no_bounds_check {
	runtime.bounds_check_error_loc(loc, length*stride-1, len(table))
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

/*
Converts the rune `r` to lower case, using the Unicode simple lower case mapping.

The mapping is one rune to one rune: a character whose full case folding expands
to several runes is never expanded here. `U+0130` (I with dot above), for
example, maps to `U+0069` (i) rather than to a two rune sequence.

Inputs:
- r: The rune to convert.

Returns:
The lower case equivalent of `r`, or `r` itself when no lower case mapping exists.

Example:

	import "core:fmt"
	import "core:unicode"

	to_lower_example :: proc() {
		fmt.println(unicode.to_lower('A'))     // 'a'
		fmt.println(unicode.to_lower('Z'))     // 'z'
		fmt.println(unicode.to_lower('\u00C9')) // e with acute
		fmt.println(unicode.to_lower('1'))     // '1'
	}

Output:

	a
	z
	é
	1

*/
@(require_results)
to_lower :: proc(r: rune) -> rune #no_bounds_check {
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
/*
Converts the rune `r` to upper case, using the Unicode simple upper case mapping.

As with [[to_lower]], the mapping is one rune to one rune, so a character whose
full case folding expands to several runes is never expanded here.

Inputs:
- r: The rune to convert.

Returns:
The upper case equivalent of `r`, or `r` itself when no upper case mapping exists.

Example:

	import "core:fmt"
	import "core:unicode"

	to_upper_example :: proc() {
		fmt.println(unicode.to_upper('a'))     // 'A'
		fmt.println(unicode.to_upper('z'))     // 'Z'
		fmt.println(unicode.to_upper('\u00E9')) // E with acute
		fmt.println(unicode.to_upper('1'))     // '1'
	}

Output:

	A
	Z
	É
	1

*/
@(require_results)
to_upper :: proc(r: rune) -> rune #no_bounds_check {
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
to_title :: proc(r: rune) -> rune #no_bounds_check {
	c := i32(r)
	p := binary_search(c, to_upper_singlets[:], len(to_title_singlets)/2, 2)
	if p >= 0 && c == to_upper_singlets[p] {
		return rune(c + to_title_singlets[p+1] - 500)
	}
	return rune(c)
}


/*
Returns whether the rune `r` is a lower case letter.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is in the Unicode general category Ll, `false` otherwise.

Example:

	import "core:fmt"
	import "core:unicode"

	is_lower_example :: proc() {
		fmt.println(unicode.is_lower('a'))       // true
		fmt.println(unicode.is_lower('A'))       // false
		fmt.println(unicode.is_lower('\u00E0')) // true, a with grave
		fmt.println(unicode.is_lower('1'))       // false
	}

Output:

	true
	false
	true
	false

*/
@(require_results)
is_lower :: proc(r: rune) -> bool #no_bounds_check {
	if r <= MAX_ASCII {
		return u32(r)-'a' < 26
	}
	return in_range(r, ll_ranges) || in_range(r, other_lowercase_ranges)
}

/*
Returns whether the rune `r` is an upper case letter.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is in the Unicode general category Lu, `false` otherwise.

Example:

	import "core:fmt"
	import "core:unicode"

	is_upper_example :: proc() {
		fmt.println(unicode.is_upper('A'))       // true
		fmt.println(unicode.is_upper('a'))       // false
		fmt.println(unicode.is_upper('\u00C9')) // true, E with acute
		fmt.println(unicode.is_upper('1'))       // false
	}

Output:

	true
	false
	true
	false

*/
@(require_results)
is_upper :: proc(r: rune) -> bool #no_bounds_check {
	if r <= MAX_ASCII {
		return u32(r)-'A' < 26
	}
	return in_range(r, lu_ranges) || in_range(r, other_uppercase_ranges)
}

/*
Returns whether the rune `r` is a letter.

This is an alias for [[is_letter]] and behaves identically to it.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is in the Unicode general category Ll, Lm, Lo, Lt or Lu, and
`false` otherwise.
*/
is_alpha :: is_letter

/*
Return true if the rune `r` is a letter. Being a letter means that the rune has
the Unicode general category property of L. In practice, the character will have
a general category property of Ll, Lm, Lo, Lt, or Lu.

Inputs:
- r: The rune which will be check for having the property of being a letter.

Returns:
`true` when the rune `r` is a letter. `false` will be returned in all other cases.
*/
@(require_results)
is_letter :: proc(r: rune) -> bool #no_bounds_check {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pLmask != 0
	}
	if is_upper(r) || is_lower(r) {
		return true
	}

	ll_lu := in_range(r, ll_ranges) || in_range(r, lu_ranges) 	

	return ll_lu || in_range(r, lo_ranges) || in_range(r, lt_ranges) || in_range(r, lm_ranges) 
}

@(require_results)
is_title :: proc(r: rune) -> bool {
	return is_upper(r) && is_lower(r)
}

/*
Returns true if the rune `r` is in the General Category Nd

Inputs:
- r: The run to check if it is in the general category Nd.

Returns:
`true` if the rune is in the general category Nd and `false` otherwise

*/
is_decimal :: proc(r: rune) -> bool {
	return in_range(r, nd_ranges)
}

/*
This function determincs if a rune is a digit. To be a digit the 
charage either has a Numeric_Type of Digit or Decimal. 

Inputs:
- r: The rune to check if it is a digit.

Returns:
`true` if the rune `r` is a digit, `false` in all other cases

*/
@(require_results)
is_digit :: proc(r: rune) -> bool {
	if r <= MAX_LATIN1 {
		return ('0' <= r && r <= '9') || r == 0x00B9 || (r >= 0x00B2 && r <= 0x0B3)
	}

	if in_range(r, nd_ranges) {
		return true
	}
	
	if in_range(r, extra_digits_ranges) {
		return true
	}

	return false
}


/*
Returns whether the rune `r` is whitespace.

This is an alias for [[is_space]] and behaves identically to it.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is whitespace, and `false` otherwise.
*/
is_white_space :: is_space
/*
Returns whether the rune `r` is whitespace.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a space, tab, or other separator defined by Unicode, and
`false` otherwise. Note that the zero width space [[ZERO_WIDTH_SPACE]] and
[[WORD_JOINER]] are handled differently: the former counts as whitespace,
while the latter does not.
*/
@(require_results)
is_space :: proc(r: rune) -> bool #no_bounds_check {
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

/*
Returns whether the rune `r` is a combining character.

These are characters that combine with the preceding character to form a
single grapheme, such as the accents used to build letters like `é` from `e`.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a combining character, `false` otherwise.
*/
@(require_results)
is_combining :: proc(r: rune) -> bool {
	c := i32(r)

	return c >= 0x0300 && (c <= 0x036f ||
	      (c >= 0x1ab0 && c <= 0x1aff) ||
	      (c >= 0x1dc0 && c <= 0x1dff) ||
	      (c >= 0x20d0 && c <= 0x20ff) ||
	      (c >= 0xfe20 && c <= 0xfe2f))
}



/*
Returns whether the rune `r` is a graphic character, meaning it has a visible
shape.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a letter, number, punctuation mark, symbol, or a character
that takes up space, and `false` otherwise. Control characters are not
graphic, but the space character `U+0020` is.
*/
@(require_results)
is_graphic :: proc(r: rune) -> bool {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pg != 0
	}

	if is_letter(r) || is_number(r) || is_punct(r) || is_symbol(r) || in_range(r, zs_ranges) {
		return true
	}

	if  in_range(r, mc_ranges) || in_range(r, me_ranges) || in_range(r, mn_ranges) {
		return true
	}

	return false
}

/*
Returns whether the rune `r` is a printable ASCII or Latin-1 character.

This currently only covers `U+0000` to `U+00FF`: every rune above Latin-1 is
reported as not printable, including characters such as CJK ideographs which
are plainly printable. Use [[is_graphic]] for a check that covers the whole
Unicode range.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is printable and at most `U+00FF`, `false` otherwise.

Example:

	import "core:fmt"
	import "core:unicode"

	is_print_example :: proc() {
		fmt.println(unicode.is_print('a'))     // true
		fmt.println(unicode.is_print('\u00E9')) // true
		fmt.println(unicode.is_print('\u4E00')) // false, above Latin-1
	}

Output:

	true
	true
	false

*/
@(require_results)
is_print :: proc(r: rune) -> bool #no_bounds_check {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pp != 0
	}
	return false
}

/*
Returns whether the rune `r` is a control character, meaning it is not a
printable character.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a control character, `false` otherwise.
*/
@(require_results)
is_control :: proc(r: rune) -> bool #no_bounds_check {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pC != 0
	}
	return false
}

/*
Checks to see if the rune `r` is a number. This means the rune is a member
of the general category Nd, Nl, or No.

Inputs:
r: The rune to check if it is number.

Returns:
`true` if the ruen belongs to the general category Nd, Nl, or No. `false`
is return in all other cases.

*/
@(require_results)
is_number :: proc(r: rune) -> bool #no_bounds_check {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pN != 0
	}

	return in_range(r, nd_ranges) || in_range(r, nl_ranges) || in_range(r, no_ranges)
}

/*
Returns whether the rune `r` is punctuation.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is in a Unicode punctuation category (Pc, Pd, Ps, Pe, Pi, Pf
or Po), and `false` otherwise.
*/
@(require_results)
is_punct :: proc(r: rune) -> bool #no_bounds_check {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pP != 0
	}

	if in_range(r, pc_ranges) || in_range(r, pd_ranges) || in_range(r, pe_ranges) {
		return true
	}
	
	if in_range(r, pf_ranges) || in_range(r, pi_ranges) || in_range(r, po_ranges) {
		return true
	}

	return in_range(r, ps_ranges)
}

/*
Returns whether the rune `r` is a symbol, as distinct from a letter, number or
punctuation mark.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is in a Unicode symbol category (Sm, Sc, Sk or So), and `false`
otherwise.
*/
@(require_results)
is_symbol :: proc(r: rune) -> bool #no_bounds_check {
	if u32(r) <= MAX_LATIN1 {
		return char_properties[u8(r)]&pS != 0
	}

	s := in_range(r, sc_ranges) || in_range(r, sm_ranges) 
	
	if s || in_range(r, so_ranges) || in_range(r, sk_ranges) {
		return true
	}

	return false
}

//
// The procedures below are accurate as of Unicode 15.1.0.
//

/*
Unicode property: `Emoji_Modifier`.

Returns whether the rune `r` is an emoji modifier, used to recolour the
preceding emoji skin tone.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is an emoji modifier, `false` otherwise.
*/
@(require_results)
is_emoji_modifier :: proc(r: rune) -> bool {
	return 0x1F3FB <= r && r <= 0x1F3FF
}

/*
Unicode property: `Regional_Indicator`.

Returns whether the rune `r` is a regional indicator symbol, the letters used
to build flag emoji.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a regional indicator symbol, `false` otherwise.
*/
@(require_results)
is_regional_indicator :: proc(r: rune) -> bool {
	return 0x1F1E6 <= r && r <= 0x1F1FF
}

/*
Unicode property: `General_Category=Enclosing_Mark`.

Returns whether the rune `r` is an enclosing mark, which combines with the
preceding characters to enclose them in a single glyph, as with the parentheses
in some scripts.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is an enclosing mark, `false` otherwise.
*/
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

/*
Unicode property: `Prepended_Concatenation_Mark`.

Returns whether the rune `r` is a prepended concatenation mark, which joins to
the following characters to form a single glyph.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a prepended concatenation mark, `false` otherwise.
*/
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

/*
Unicode property: `General_Category=Spacing_Mark`.

Returns whether the rune `r` is a spacing mark, a character that combines with
the preceding character but still occupies space of its own.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a spacing mark, `false` otherwise.
*/
@(require_results)
is_spacing_mark :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, spacing_mark_ranges[:], len(spacing_mark_ranges)/2, 2)
	if p >= 0 && spacing_mark_ranges[p] <= c && c <= spacing_mark_ranges[p+1] {
		return true
	}
	return false
}

/*
Unicode property: `General_Category=Nonspacing_Mark`.

Returns whether the rune `r` is a nonspacing mark, a character that combines
with the preceding character without occupying space of its own, such as most
combining accents.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a nonspacing mark, `false` otherwise.
*/
@(require_results)
is_nonspacing_mark :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, nonspacing_mark_ranges[:], len(nonspacing_mark_ranges)/2, 2)
	if p >= 0 && nonspacing_mark_ranges[p] <= c && c <= nonspacing_mark_ranges[p+1] {
		return true
	}
	return false
}

/*
Unicode property: `Extended_Pictographic`.

Returns whether the rune `r` is an extended pictographic character, meaning it
should be treated as an emoji or ideograph when rendering text.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is an extended pictographic character, `false` otherwise.
*/
@(require_results)
is_emoji_extended_pictographic :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, emoji_extended_pictographic_ranges[:], len(emoji_extended_pictographic_ranges)/2, 2)
	if p >= 0 && emoji_extended_pictographic_ranges[p] <= c && c <= emoji_extended_pictographic_ranges[p+1] {
		return true
	}
	return false
}

/*
Unicode property: `Grapheme_Extend`.

Returns whether the rune `r` extends the preceding character in a grapheme
cluster, meaning it combines with it rather than starting a new character.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` extends a grapheme cluster, `false` otherwise.
*/
@(require_results)
is_grapheme_extend :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, grapheme_extend_ranges[:], len(grapheme_extend_ranges)/2, 2)
	if p >= 0 && grapheme_extend_ranges[p] <= c && c <= grapheme_extend_ranges[p+1] {
		return true
	}
	return false
}


/*
Unicode property: `Hangul_Syllable_Type=Leading_Jamo`.

Returns whether the rune `r` is a leading Hangul jamo, the first consonant of a
Hangul syllable.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a leading Hangul jamo, `false` otherwise.
*/
@(require_results)
is_hangul_syllable_leading :: proc(r: rune) -> bool {
	return 0x1100 <= r && r <= 0x115F || 0xA960 <= r && r <= 0xA97C
}

/*
Unicode property: `Hangul_Syllable_Type=Vowel_Jamo`.

Returns whether the rune `r` is a vowel Hangul jamo, the second component of a
Hangul syllable.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a vowel Hangul jamo, `false` otherwise.
*/
@(require_results)
is_hangul_syllable_vowel :: proc(r: rune) -> bool {
	return 0x1160 <= r && r <= 0x11A7 || 0xD7B0 <= r && r <= 0xD7C6
}

/*
Unicode property: `Hangul_Syllable_Type=Trailing_Jamo`.

Returns whether the rune `r` is a trailing Hangul jamo, the last component of a
Hangul syllable.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a trailing Hangul jamo, `false` otherwise.
*/
@(require_results)
is_hangul_syllable_trailing :: proc(r: rune) -> bool {
	return 0x11A8 <= r && r <= 0x11FF || 0xD7CB <= r && r <= 0xD7FB
}

/*
Unicode property: `Hangul_Syllable_Type=LV_Syllable`.

Returns whether the rune `r` is a Hangul syllable of type LV, which behaves as
both a leading and a trailing jamo.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is an LV Hangul syllable, `false` otherwise.
*/
@(require_results)
is_hangul_syllable_lv :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, hangul_syllable_lv_singlets[:], len(hangul_syllable_lv_singlets), 1)
	if p >= 0 && c == hangul_syllable_lv_singlets[p] {
		return true
	}
	return false
}

/*
Unicode property: `Hangul_Syllable_Type=LVT_Syllable`.

Returns whether the rune `r` is a Hangul syllable of type LVT, which behaves as
both a leading and a trailing jamo and carries a trailing consonant.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is an LVT Hangul syllable, `false` otherwise.
*/
@(require_results)
is_hangul_syllable_lvt :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, hangul_syllable_lvt_ranges[:], len(hangul_syllable_lvt_ranges)/2, 2)
	if p >= 0 && hangul_syllable_lvt_ranges[p] <= c && c <= hangul_syllable_lvt_ranges[p+1] {
		return true
	}
	return false
}


/*
Unicode property: `Indic_Syllabic_Category=Consonant_Preceding_Repha`.

Returns whether the rune `r` is an Indic consonant that takes a repha before it,
used when rendering Indic scripts.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a consonant preceding repha, `false` otherwise.
*/
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

/*
Unicode property: `Indic_Syllabic_Category=Consonant_Prefixed`.

Returns whether the rune `r` is an Indic consonant that takes a prefix before
it, used when rendering Indic scripts.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a prefixed consonant, `false` otherwise.
*/
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

/*
Unicode property: `Indic_Conjunct_Break=Linker`.

Returns whether the rune `r` is an Indic conjunct break linker, the character
that joins two consonants into a single conjunct glyph.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a conjunct break linker, `false` otherwise.
*/
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

/*
Unicode property: `Indic_Conjunct_Break=Consonant`.

Returns whether the rune `r` is an Indic conjunct break consonant, one side of
a conjunct formed around a linker.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a conjunct break consonant, `false` otherwise.
*/
@(require_results)
is_indic_conjunct_break_consonant :: proc(r: rune) -> bool #no_bounds_check {
	c := i32(r)
	p := binary_search(c, indic_conjunct_break_consonant_ranges[:], len(indic_conjunct_break_consonant_ranges)/2, 2)
	if p >= 0 && indic_conjunct_break_consonant_ranges[p] <= c && c <= indic_conjunct_break_consonant_ranges[p+1] {
		return true
	}
	return false
}

/*
Unicode property: `Indic_Conjunct_Break=Extend`.

Returns whether the rune `r` is an Indic conjunct break extender, a character
that may appear within a conjunct without breaking it.

Inputs:
- r: The rune to check.

Returns:
`true` when `r` is a conjunct break extender, `false` otherwise.
*/
@(require_results)
is_indic_conjunct_break_extend :: proc(r: rune) -> bool #no_bounds_check {
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

/*
Returns the normalized East Asian width of the rune `r`, as used when laying
out text in a terminal or other fixed-width display.

Inputs:
- r: The rune to check.

Returns:
`2` if the rune is East Asian Wide or Fullwidth, `0` if it is non-printable or
zero-width, and `1` in all other cases.
*/
@(require_results)
normalized_east_asian_width :: proc(r: rune) -> int #no_bounds_check {
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
