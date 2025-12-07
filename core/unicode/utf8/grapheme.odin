package utf8

import "core:unicode"

ZERO_WIDTH_JOINER                 :: unicode.ZERO_WIDTH_JOINER
is_control                        :: unicode.is_control
is_hangul_syllable_leading        :: unicode.is_hangul_syllable_leading
is_hangul_syllable_vowel          :: unicode.is_hangul_syllable_vowel
is_hangul_syllable_trailing       :: unicode.is_hangul_syllable_trailing
is_hangul_syllable_lv             :: unicode.is_hangul_syllable_lv
is_hangul_syllable_lvt            :: unicode.is_hangul_syllable_lvt
is_indic_conjunct_break_extend    :: unicode.is_indic_conjunct_break_extend
is_indic_conjunct_break_linker    :: unicode.is_indic_conjunct_break_linker
is_indic_conjunct_break_consonant :: unicode.is_indic_conjunct_break_consonant
is_gcb_extend_class               :: unicode.is_gcb_extend_class
is_spacing_mark                   :: unicode.is_spacing_mark
is_gcb_prepend_class              :: unicode.is_gcb_prepend_class
is_emoji_extended_pictographic    :: unicode.is_emoji_extended_pictographic
is_regional_indicator             :: unicode.is_regional_indicator
normalized_east_asian_width       :: unicode.normalized_east_asian_width


Grapheme :: struct {
	byte_index: int,
	rune_index: int,
	width:      int,
}


Grapheme_Cluster_Sequence :: enum {
	None,
	Indic,
	Emoji,
	Regional,
}

Grapheme_Iterator :: struct {
	str:            string,
	curr_offset:    int,

	grapheme_count: int, // The number of graphemes in the string
	rune_count:     int, // The number of runes in the string
	width:          int, // The widrth of the string in number of monospace cells

	last_rune:                  rune,
	last_rune_breaks_forward:   bool,

	last_width:                 int,
	last_grapheme_count:        int,

	bypass_next_rune:           bool,

	regional_indicator_counter: int,

	current_sequence:           Grapheme_Cluster_Sequence,
	continue_sequence:          bool,
}


/*
Count the individual graphemes in a UTF-8 string.

Inputs:
- str: The input string.

Returns:
- graphemes: The number of graphemes in the string.
- runes: The number of runes in the string.
- width: The width of the string in number of monospace cells.
*/
@(require_results)
grapheme_count :: proc(str: string) -> (graphemes, runes, width: int) {
	it := decode_grapheme_iterator_make(str)
	for _, _ in decode_grapheme_iterate(&it) {/**/}
	graphemes, runes, width = it.grapheme_count, it.rune_count, it.width
	return
}

/*
Decode the individual graphemes in a UTF-8 string.

*Allocates Using Provided Allocator*

Inputs:
- str: The input string.
- track_graphemes: Whether or not to allocate and return `graphemes` with extra data about each grapheme.
- allocator: (default: context.allocator)

Returns:
- graphemes: Extra data about each grapheme.
- grapheme_count: The number of graphemes in the string.
- rune_count: The number of runes in the string.
- width: The width of the string in number of monospace cells.
*/
@(require_results)
decode_grapheme_clusters :: proc(
	str: string,
	track_graphemes := true,
	allocator       := context.allocator,
) -> (
	graphemes:      [dynamic]Grapheme,
	grapheme_count: int,
	rune_count:     int,
	width:          int,
) {
	context.allocator = allocator

	it := decode_grapheme_iterator_make(str)
	for _, grapheme in decode_grapheme_iterate(&it) {
		if track_graphemes {
			append(&graphemes, grapheme)
		}
	}

	grapheme_count = it.grapheme_count
	rune_count     = it.rune_count
	width          = it.width
	return
}

@(require_results)
decode_grapheme_iterator_make :: proc(str: string) -> (it: Grapheme_Iterator) {
	it.str = str
	return
}

@(require_results)
decode_grapheme_iterate :: proc(it: ^Grapheme_Iterator) -> (text: string, grapheme: Grapheme, ok: bool) {
	for it.curr_offset < len(it.str) {
		if ok {
			return
		}

		str := it.str[it.curr_offset:]
		this_rune, this_rune_width := decode_rune(str)
		byte_index := it.curr_offset
		it.curr_offset += this_rune_width

		defer {
			// "Break at the start and end of text, unless the text is empty."
			//
			// GB1: sot  ÷  Any
			// GB2: Any  ÷  eot
			if it.rune_count == 0 && it.grapheme_count == 0 {
				it.grapheme_count += 1
			}

			if it.grapheme_count > it.last_grapheme_count {
				it.width += normalized_east_asian_width(this_rune)
				grapheme = Grapheme{
					byte_index,
					it.rune_count,
					it.width - it.last_width,
				}
				text = it.str[byte_index:][:grapheme.width]
				ok = true


				it.last_grapheme_count = it.grapheme_count
				it.last_width = it.width
			}

			it.last_rune = this_rune
			it.rune_count += 1

			if !it.continue_sequence {
				it.current_sequence = .None
				it.regional_indicator_counter = 0
			}
			it.continue_sequence = false
		}


		// "Do not break between a CR and LF. Otherwise, break before and after controls."
		//
		// GB3:                 CR   ×   LF
		// GB4: (Control | CR | LF)  ÷
		// GB5:                      ÷  (Control | CR | LF)
		if this_rune == '\n' && it.last_rune == '\r' {
			it.last_rune_breaks_forward = false
			it.bypass_next_rune = false
			continue
		}

		if is_control(this_rune) {
			it.grapheme_count += 1
			it.last_rune_breaks_forward = true
			it.bypass_next_rune = true
			continue
		}

		// (This check is for rules that work forwards, instead of backwards.)
		if it.bypass_next_rune {
			if it.last_rune_breaks_forward {
				it.grapheme_count += 1
				it.last_rune_breaks_forward = false
			}

			it.bypass_next_rune = false
			continue
		}

		// (Optimization 1: Prevent low runes from proceeding further.)
		//
		//  * 0xA9 and 0xAE are in the Extended_Pictographic range,
		//    which is checked later in GB11.
		if this_rune != 0xA9 && this_rune != 0xAE && this_rune <= 0x2FF {
			it.grapheme_count += 1
			continue
		}

		// (Optimization 2: Check if the rune is in the Hangul space before getting specific.)
		if 0x1100 <= this_rune && this_rune <= 0xD7FB {
			// "Do not break Hangul syllable sequences."
			//
			// GB6:        L   ×  (L | V | LV | LVT)
			// GB7:  (LV | V)  ×  (V | T)
			// GB8: (LVT | T)  ×   T
			if is_hangul_syllable_leading(this_rune) ||
			   is_hangul_syllable_lv(this_rune)      ||
			   is_hangul_syllable_lvt(this_rune) {
				if !is_hangul_syllable_leading(it.last_rune) {
					it.grapheme_count += 1
				}
				continue
			}

			if is_hangul_syllable_vowel(this_rune) {
				if is_hangul_syllable_leading(it.last_rune) ||
				   is_hangul_syllable_vowel(it.last_rune)   ||
				   is_hangul_syllable_lv(it.last_rune) {
					continue
				}
				it.grapheme_count += 1
				continue
			}

			if is_hangul_syllable_trailing(this_rune) {
				if is_hangul_syllable_trailing(it.last_rune) ||
				   is_hangul_syllable_lvt(it.last_rune)      ||
				   is_hangul_syllable_lv(it.last_rune)       ||
				   is_hangul_syllable_vowel(it.last_rune) {
					continue
				}
				it.grapheme_count += 1
				continue
			}
		}

		// "Do not break before extending characters or ZWJ."
		//
		// GB9:         × (Extend | ZWJ)
		if this_rune == ZERO_WIDTH_JOINER {
			it.continue_sequence = true
			continue
		}

		if is_gcb_extend_class(this_rune) {
			// (Support for GB9c.)
			if it.current_sequence == .Indic {
				if is_indic_conjunct_break_extend(this_rune)    && (
				   is_indic_conjunct_break_linker(it.last_rune) ||
				   is_indic_conjunct_break_consonant(it.last_rune) ) {
					it.continue_sequence = true
					continue
				}

				if is_indic_conjunct_break_linker(this_rune)       && (
				   is_indic_conjunct_break_linker(it.last_rune)    ||
				   is_indic_conjunct_break_extend(it.last_rune)    ||
				   is_indic_conjunct_break_consonant(it.last_rune)    ) {
					it.continue_sequence = true
					continue
				}

				continue
			}

			// (Support for GB11.)
			if it.current_sequence == .Emoji                && (
			   is_gcb_extend_class(it.last_rune)            ||
			   is_emoji_extended_pictographic(it.last_rune)    ) {
				it.continue_sequence = true
			}

			continue
		}

		// _The GB9a and GB9b rules only apply to extended grapheme clusters:_
		// "Do not break before SpacingMarks, or after Prepend characters."
		//
		// GB9a:          ×  SpacingMark
		// GB9b: Prepend  ×
		if is_spacing_mark(this_rune) {
			continue
		}

		if is_gcb_prepend_class(this_rune) {
			it.grapheme_count += 1
			it.bypass_next_rune = true
			continue
		}

		// _The GB9c rule only applies to extended grapheme clusters:_
		// "Do not break within certain combinations with Indic_Conjunct_Break (InCB)=Linker."
		//
		// GB9c: \p{InCB=Consonant} [ \p{InCB=Extend} \p{InCB=Linker} ]* \p{InCB=Linker} [ \p{InCB=Extend} \p{InCB=Linker} ]*  ×  \p{InCB=Consonant}
		if is_indic_conjunct_break_consonant(this_rune) {
			if it.current_sequence == .Indic {
				if it.last_rune == ZERO_WIDTH_JOINER            ||
				   is_indic_conjunct_break_linker(it.last_rune) {
					it.continue_sequence = true
				} else {
					it.grapheme_count += 1
				}
			} else {
				it.grapheme_count += 1
				it.current_sequence = .Indic
				it.continue_sequence = true
			}
			continue
		}

		if is_indic_conjunct_break_extend(this_rune) {
			if it.current_sequence == .Indic {
				if is_indic_conjunct_break_consonant(it.last_rune) ||
				   is_indic_conjunct_break_linker(it.last_rune) {
					it.continue_sequence = true
				} else {
					it.grapheme_count += 1
				}
			}
			continue
		}

		if is_indic_conjunct_break_linker(this_rune) {
			if it.current_sequence == .Indic {
				if is_indic_conjunct_break_extend(it.last_rune) ||
				   is_indic_conjunct_break_linker(it.last_rune) {
					it.continue_sequence = true
				} else {
					it.grapheme_count += 1
				}
			}
			continue
		}

		//
		// (Curiously, there is no GB10.)
		//

		// "Do not break within emoji modifier sequences or emoji zwj sequences."
		//
		// GB11: \p{Extended_Pictographic} Extend* ZWJ  ×  \p{Extended_Pictographic}
		if is_emoji_extended_pictographic(this_rune) {
			if it.current_sequence != .Emoji || it.last_rune != ZERO_WIDTH_JOINER {
				it.grapheme_count += 1
			}
			it.current_sequence = .Emoji
			it.continue_sequence = true
			continue
		}

		// "Do not break within emoji flag sequences.
		//  That is, do not break between regional indicator (RI) symbols
		//  if there is an odd number of RI characters before the break point."
		//
		// GB12:   sot (RI RI)* RI  ×  RI
		// GB13: [^RI] (RI RI)* RI  ×  RI
		if is_regional_indicator(this_rune) {
			if it.regional_indicator_counter & 1 == 0 {
				it.grapheme_count += 1
			}

			it.current_sequence = .Regional
			it.continue_sequence = true
			it.regional_indicator_counter += 1

			continue
		}

		// "Otherwise, break everywhere."
		//
		// GB999: Any ÷ Any
		it.grapheme_count += 1
	}

	return
}