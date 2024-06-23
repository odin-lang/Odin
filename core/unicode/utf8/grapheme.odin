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
	width: int,
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
	_, graphemes, runes, width = decode_grapheme_clusters(str, false)
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
	// The following procedure implements text segmentation by breaking on
	// Grapheme Cluster Boundaries[1], using the values[2] and rules[3] from
	// the Unicode® Standard Annex #29, entitled:
	//
	// UNICODE TEXT SEGMENTATION
	//
	// Version:  Unicode 15.1.0
	// Date:     2023-08-16
	// Revision: 43
	//
	// This procedure is conformant[4] to UAX29-C1-1, otherwise known as the
	// extended, non-legacy ruleset.
	//
	// Please see the references below for more information.
	//
	//
	// NOTE(Feoramund): This procedure has not been highly optimized.
	// A couple opportunities were taken to bypass repeated checking when a
	// rune is outside of certain codepoint ranges, but little else has been
	// done. Standard switches, conditionals, and binary search are used to
	// see if a rune fits into a certain category.
	//
	// I did find that only one prior rune of state was necessary to build an
	// algorithm that successfully passes all 4,835 test cases provided with
	// this implementation from the Unicode organization's website.
	//
	// My initial implementation tracked explicit breaks and counted them once
	// the string iteration had terminated. I've found this current
	// implementation to be far simpler and need no allocations (unless the
	// caller wants position data).
	//
	// Most rules work backwards instead of forwards which has helped keep this
	// simple, despite its length and verbosity.
	//
	//
	// The implementation has been left verbose and in the order described by
	// the specification, to enable better readability and future upkeep.
	//
	// Some possible optimizations might include:
	//
	// - saving the type of `last_rune` instead of the exact rune.
	// - reordering rules.
	// - combining tables.
	//
	//
	// [1]: https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
	// [2]: https://www.unicode.org/reports/tr29/#Default_Grapheme_Cluster_Table
	// [3]: https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundary_Rules
	// [4]: https://www.unicode.org/reports/tr29/#Conformance

	// Additionally, this procedure now takes into account Standard Annex #11,
	// in order to estimate how visually wide the string will appear on a
	// monospaced display. This can only ever be a rough guess, as this tends
	// to be an implementation detail relating to which fonts are being used,
	// how codepoints are interpreted and drawn, if codepoint sequences are
	// interpreted correctly, and et cetera.
	//
	// For example, a program may not properly interpret an emoji modifier
	// sequence and print the component glyphs instead of one whole glyph.
	//
	// See here for more information: https://www.unicode.org/reports/tr11/
	//
	// NOTE: There is no explicit mention of what to do with zero-width spaces
	// as far as grapheme cluster segmentation goes, therefore this
	// implementation may count and return graphemes with a `width` of zero.
	//
	// Treat them as any other space.

	Grapheme_Cluster_Sequence :: enum {
		None,
		Indic,
		Emoji,
		Regional,
	}

	context.allocator = allocator

	last_rune: rune
	last_rune_breaks_forward: bool

	last_width: int
	last_grapheme_count: int

	bypass_next_rune: bool

	regional_indicator_counter: int

	current_sequence: Grapheme_Cluster_Sequence
	continue_sequence: bool

	for this_rune, byte_index in str {
		defer {
			// "Break at the start and end of text, unless the text is empty."
			//
			// GB1: sot  ÷  Any
			// GB2: Any  ÷  eot
			if rune_count == 0 && grapheme_count == 0 {
				grapheme_count += 1
			}

			if grapheme_count > last_grapheme_count {
				width += normalized_east_asian_width(this_rune)
				if track_graphemes {
					append(&graphemes, Grapheme{
						byte_index,
						rune_count,
						width - last_width,
					})
				}
				last_grapheme_count = grapheme_count
				last_width = width
			}

			last_rune = this_rune
			rune_count += 1

			if !continue_sequence {
				current_sequence = .None
				regional_indicator_counter = 0
			}
			continue_sequence = false
		}

		// "Do not break between a CR and LF. Otherwise, break before and after controls."
		//
		// GB3:                 CR   ×   LF
		// GB4: (Control | CR | LF)  ÷
		// GB5:                      ÷  (Control | CR | LF)
		if this_rune == '\n' && last_rune == '\r' {
			last_rune_breaks_forward = false
			bypass_next_rune = false
			continue
		}

		if is_control(this_rune) {
			grapheme_count += 1
			last_rune_breaks_forward = true
			bypass_next_rune = true
			continue
		}

		// (This check is for rules that work forwards, instead of backwards.)
		if bypass_next_rune {
			if last_rune_breaks_forward {
				grapheme_count += 1
				last_rune_breaks_forward = false
			}

			bypass_next_rune = false
			continue
		}

		// (Optimization 1: Prevent low runes from proceeding further.)
		//
		//  * 0xA9 and 0xAE are in the Extended_Pictographic range,
		//    which is checked later in GB11.
		if this_rune != 0xA9 && this_rune != 0xAE && this_rune <= 0x2FF {
			grapheme_count += 1
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
			   is_hangul_syllable_lvt(this_rune)
			{
				if !is_hangul_syllable_leading(last_rune) {
					grapheme_count += 1
				}
				continue
			}

			if is_hangul_syllable_vowel(this_rune) {
				if is_hangul_syllable_leading(last_rune) ||
				   is_hangul_syllable_vowel(last_rune)   ||
				   is_hangul_syllable_lv(last_rune)
				{
					continue
				}
				grapheme_count += 1
				continue
			}

			if is_hangul_syllable_trailing(this_rune) {
				if is_hangul_syllable_trailing(last_rune) ||
				   is_hangul_syllable_lvt(last_rune)      ||
				   is_hangul_syllable_lv(last_rune)       ||
				   is_hangul_syllable_vowel(last_rune)
				{
					continue
				}
				grapheme_count += 1
				continue
			}
		}

		// "Do not break before extending characters or ZWJ."
		//
		// GB9:         × (Extend | ZWJ)
		if this_rune == ZERO_WIDTH_JOINER {
			continue_sequence = true
			continue
		}

		if is_gcb_extend_class(this_rune) {
			// (Support for GB9c.)
			if current_sequence == .Indic {
				if is_indic_conjunct_break_extend(this_rune)    && (
				   is_indic_conjunct_break_linker(last_rune)    ||
				   is_indic_conjunct_break_consonant(last_rune)    )
				{
					continue_sequence = true
					continue
				}

				if is_indic_conjunct_break_linker(this_rune)    && (
				   is_indic_conjunct_break_linker(last_rune)    ||
				   is_indic_conjunct_break_extend(last_rune)    ||
				   is_indic_conjunct_break_consonant(last_rune)    )
				{
					continue_sequence = true
					continue
				}

				continue
			}

			// (Support for GB11.)
			if current_sequence == .Emoji                && (
			   is_gcb_extend_class(last_rune)            ||
			   is_emoji_extended_pictographic(last_rune)    )
			{
				continue_sequence = true
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
			grapheme_count += 1
			bypass_next_rune = true
			continue
		}

		// _The GB9c rule only applies to extended grapheme clusters:_
		// "Do not break within certain combinations with Indic_Conjunct_Break (InCB)=Linker."
		//
		// GB9c: \p{InCB=Consonant} [ \p{InCB=Extend} \p{InCB=Linker} ]* \p{InCB=Linker} [ \p{InCB=Extend} \p{InCB=Linker} ]*  ×  \p{InCB=Consonant}
		if is_indic_conjunct_break_consonant(this_rune) {
			if current_sequence == .Indic {
				if last_rune == ZERO_WIDTH_JOINER            ||
				   is_indic_conjunct_break_linker(last_rune)
				{
					continue_sequence = true
				} else {
					grapheme_count += 1
				}
			} else {
				grapheme_count += 1
				current_sequence = .Indic
				continue_sequence = true
			}
			continue
		}

		if is_indic_conjunct_break_extend(this_rune) {
			if current_sequence == .Indic {
				if is_indic_conjunct_break_consonant(last_rune) ||
				   is_indic_conjunct_break_linker(last_rune)
				{
					continue_sequence = true
				} else {
					grapheme_count += 1
				}
			}
			continue
		}

		if is_indic_conjunct_break_linker(this_rune) {
			if current_sequence == .Indic {
				if is_indic_conjunct_break_extend(last_rune) ||
				   is_indic_conjunct_break_linker(last_rune)
				{
					continue_sequence = true
				} else {
					grapheme_count += 1
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
			if current_sequence != .Emoji || last_rune != ZERO_WIDTH_JOINER {
				grapheme_count += 1
			}
			current_sequence = .Emoji
			continue_sequence = true
			continue
		}

		// "Do not break within emoji flag sequences.
		//  That is, do not break between regional indicator (RI) symbols
		//  if there is an odd number of RI characters before the break point."
		//
		// GB12:   sot (RI RI)* RI  ×  RI
		// GB13: [^RI] (RI RI)* RI  ×  RI
		if is_regional_indicator(this_rune) {
			if regional_indicator_counter & 1 == 0 {
				grapheme_count += 1
			}

			current_sequence = .Regional
			continue_sequence = true
			regional_indicator_counter += 1

			continue
		}

		// "Otherwise, break everywhere."
		//
		// GB999: Any ÷ Any
		grapheme_count += 1
	}

	return
}
