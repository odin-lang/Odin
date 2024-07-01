/*
 * SPDX-FileCopyrightText: (c) 2024 Feoramund
 * SPDX-License-Identifier: BSD-3-Clause
 */


//
// NOTE(Feoramund): This is my UCG library, adapted for use within the Odin compiler.
// Most of the comments have been let alone and may not strictly apply anymore.
//
// 1. The UCG allocator interface was replaced by gbAllocator.
// 2. The UCG UTF-8 decoder was replaced with the one already in the compiler.
// 3. Non-essential code was stripped.
// 4. Some types were changed for compatibility.
//


/* This is the data that is allocated when an allocator is passed to
 * ucg_decode_grapheme_clusters. */
typedef struct {
	i32 byte_index;
	i32 rune_index;
	i32 width;
} ucg_grapheme;


/* #include "ucg.h" */
#include "ucg_tables.h"

#define UCG_TABLE_LEN(t) (sizeof(t) / sizeof(int32_t))

#define ZERO_WIDTH_SPACE      0x200B
#define ZERO_WIDTH_NON_JOINER 0x200C
#define ZERO_WIDTH_JOINER     0x200D
#define WORD_JOINER           0x2060

int ucg_binary_search(int32_t value, const int32_t* table, int length, int stride) {
	GB_ASSERT(table != NULL);
	GB_ASSERT(length > 0);
	GB_ASSERT(stride > 0);

	int n = length;
	int t = 0;
	for (/**/; n > 1; /**/) {
		int m = n / 2;
		int p = t + m * stride;
		if (value >= table[p]) {
			t = p;
			n = n - m;
		} else {
			n = m;
		}
	}
	if (n != 0 && value >= table[t]) {
		return t;
	}
	return -1;
}

//
// The procedures below are accurate as of Unicode 15.1.0.
//

bool ucg_is_control(int32_t r) {
	if (r <= 0x1F || (0x7F <= r && r <= 0x9F)) {
		return true;
	}
	return false;
}

// Emoji_Modifier
bool ucg_is_emoji_modifier(int32_t r) {
	return 0x1F3FB <= r && r <= 0x1F3FF;
}

// Regional_Indicator
bool ucg_is_regional_indicator(int32_t r) {
	return 0x1F1E6 <= r && r <= 0x1F1FF;
}

// General_Category=Enclosing_Mark
bool ucg_is_enclosing_mark(int32_t r) {
	switch (r) {
	case 0x0488:
	case 0x0489:
	case 0x1ABE:
		return true;
	}

	if (0x20DD <= r && r <= 0x20E0) { return true; }
	if (0x20E2 <= r && r <= 0x20E4) { return true; }
	if (0xA670 <= r && r <= 0xA672) { return true; }

	return false;
}

// Prepended_Concatenation_Mark
bool ucg_is_prepended_concatenation_mark(int32_t r) {
	switch (r) {
	case 0x006DD:
	case 0x0070F:
	case 0x008E2:
	case 0x110BD:
	case 0x110CD:
		return true;
	}

	if (0x00600 <= r && r <= 0x00605) { return true; }
	if (0x00890 <= r && r <= 0x00891) { return true; }

	return false;
}

// General_Category=Spacing_Mark
bool ucg_is_spacing_mark(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_spacing_mark_ranges, UCG_TABLE_LEN(ucg_spacing_mark_ranges)/2, 2);
	if (p >= 0 && ucg_spacing_mark_ranges[p] <= r && r <= ucg_spacing_mark_ranges[p+1]) {
		return true;
	}
	return false;
}

// General_Category=Nonspacing_Mark
bool ucg_is_nonspacing_mark(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_nonspacing_mark_ranges, UCG_TABLE_LEN(ucg_nonspacing_mark_ranges)/2, 2);
	if (p >= 0 && ucg_nonspacing_mark_ranges[p] <= r && r <= ucg_nonspacing_mark_ranges[p+1]) {
		return true;
	}
	return false;
}

// Extended_Pictographic
bool ucg_is_emoji_extended_pictographic(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_emoji_extended_pictographic_ranges, UCG_TABLE_LEN(ucg_emoji_extended_pictographic_ranges)/2, 2);
	if (p >= 0 && ucg_emoji_extended_pictographic_ranges[p] <= r && r <= ucg_emoji_extended_pictographic_ranges[p+1]) {
		return true;
	}
	return false;
}

// Grapheme_Extend
bool ucg_is_grapheme_extend(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_grapheme_extend_ranges, UCG_TABLE_LEN(ucg_grapheme_extend_ranges)/2, 2);
	if (p >= 0 && ucg_grapheme_extend_ranges[p] <= r && r <= ucg_grapheme_extend_ranges[p+1]) {
		return true;
	}
	return false;
}


// Hangul_Syllable_Type=Leading_Jamo
bool ucg_is_hangul_syllable_leading(int32_t r) {
	return (0x1100 <= r && r <= 0x115F) || (0xA960 <= r && r <= 0xA97C);
}

// Hangul_Syllable_Type=Vowel_Jamo
bool ucg_is_hangul_syllable_vowel(int32_t r) {
	return (0x1160 <= r && r <= 0x11A7) || (0xD7B0 <= r && r <= 0xD7C6);
}

// Hangul_Syllable_Type=Trailing_Jamo
bool ucg_is_hangul_syllable_trailing(int32_t r) {
	return (0x11A8 <= r && r <= 0x11FF) || (0xD7CB <= r && r <= 0xD7FB);
}

// Hangul_Syllable_Type=LV_Syllable
bool ucg_is_hangul_syllable_lv(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_hangul_syllable_lv_singlets, UCG_TABLE_LEN(ucg_hangul_syllable_lv_singlets), 1);
	if (p >= 0 && r == ucg_hangul_syllable_lv_singlets[p]) {
		return true;
	}
	return false;
}

// Hangul_Syllable_Type=LVT_Syllable
bool ucg_is_hangul_syllable_lvt(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_hangul_syllable_lvt_ranges, UCG_TABLE_LEN(ucg_hangul_syllable_lvt_ranges)/2, 2);
	if (p >= 0 && ucg_hangul_syllable_lvt_ranges[p] <= r && r <= ucg_hangul_syllable_lvt_ranges[p+1]) {
		return true;
	}
	return false;
}


// Indic_Syllabic_Category=Consonant_Preceding_Repha
bool ucg_is_indic_consonant_preceding_repha(int32_t r) {
	switch (r) {
	case 0x00D4E:
	case 0x11941:
	case 0x11D46:
	case 0x11F02:
		return true;
	}
	return false;
}

// Indic_Syllabic_Category=Consonant_Prefixed
bool ucg_is_indic_consonant_prefixed(int32_t r) {
	switch (r) {
	case 0x1193F:
	case 0x11A3A:
		return true;
	}

	if (0x111C2 <= r && r <= 0x111C3) { return true; }
	if (0x11A84 <= r && r <= 0x11A89) { return true; }

	return false;
}

// Indic_Conjunct_Break=Linker
bool ucg_is_indic_conjunct_break_linker(int32_t r) {
	switch (r) {
	case 0x094D:
	case 0x09CD:
	case 0x0ACD:
	case 0x0B4D:
	case 0x0C4D:
	case 0x0D4D:
		return true;
	}
	return false;
}

// Indic_Conjunct_Break=Consonant
bool ucg_is_indic_conjunct_break_consonant(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_indic_conjunct_break_consonant_ranges, UCG_TABLE_LEN(ucg_indic_conjunct_break_consonant_ranges)/2, 2);
	if (p >= 0 && ucg_indic_conjunct_break_consonant_ranges[p] <= r && r <= ucg_indic_conjunct_break_consonant_ranges[p+1]) {
		return true;
	}
	return false;
}

// Indic_Conjunct_Break=Extend
bool ucg_is_indic_conjunct_break_extend(int32_t r) {
	intptr_t p = ucg_binary_search(r, ucg_indic_conjunct_break_extend_ranges, UCG_TABLE_LEN(ucg_indic_conjunct_break_extend_ranges)/2, 2);
	if (p >= 0 && ucg_indic_conjunct_break_extend_ranges[p] <= r && r <= ucg_indic_conjunct_break_extend_ranges[p+1]) {
		return true;
	}
	return false;
}


/*
```
Indic_Syllabic_Category = Consonant_Preceding_Repha, or
Indic_Syllabic_Category = Consonant_Prefixed, or
Prepended_Concatenation_Mark = Yes
```
*/
bool ucg_is_gcb_prepend_class(int32_t r) {
	return ucg_is_indic_consonant_preceding_repha(r) || ucg_is_indic_consonant_prefixed(r) || ucg_is_prepended_concatenation_mark(r);
}

/*
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
bool ucg_is_gcb_extend_class(int32_t r) {
	return ucg_is_grapheme_extend(r) || ucg_is_emoji_modifier(r);
}

// Return values:
//
// - 2 if East_Asian_Width=F or W, or
// - 0 if non-printable / zero-width, or
// - 1 in all other cases.
//
int ucg_normalized_east_asian_width(int32_t r) {
	if (ucg_is_control(r)) {
		return 0;
	} else if (r <= 0x10FF) {
		// Easy early out for low runes.
		return 1;
	}

	switch (r) {
	// This is a different interpretation of the BOM which occurs in the middle of text.
	case 0xFEFF: /* ZERO_WIDTH_NO_BREAK_SPACE */
	case ZERO_WIDTH_SPACE:
	case ZERO_WIDTH_NON_JOINER:
	case ZERO_WIDTH_JOINER:
	case WORD_JOINER:
		return 0;
	}

	intptr_t p = ucg_binary_search(r, ucg_normalized_east_asian_width_ranges, UCG_TABLE_LEN(ucg_normalized_east_asian_width_ranges)/3, 3);
	if (p >= 0 && ucg_normalized_east_asian_width_ranges[p] <= r && r <= ucg_normalized_east_asian_width_ranges[p+1]) {
		return (int)ucg_normalized_east_asian_width_ranges[p+2];
	}
	return 1;
}

//
// End of Unicode 15.1.0 block.
//

enum grapheme_cluster_sequence {
	None,
	Indic,
	Emoji,
	Regional,
};

typedef struct {
	ucg_grapheme* graphemes;
	i32 rune_count;
	i32 grapheme_count;
	i32 width;

	int32_t last_rune;
	bool last_rune_breaks_forward;

	i32 last_width;
	i32 last_grapheme_count;

	bool bypass_next_rune;

	int regional_indicator_counter;

	enum grapheme_cluster_sequence current_sequence;
	bool continue_sequence;
} ucg_decoder_state;


void _ucg_decode_grapheme_clusters_deferred_step(
	gbAllocator allocator,
	ucg_decoder_state* state,
	i32 byte_index,
	int32_t this_rune
) {
	// "Break at the start and end of text, unless the text is empty."
	//
	// GB1: sot  ÷  Any
	// GB2: Any  ÷  eot
	if (state->rune_count == 0 && state->grapheme_count == 0) {
		state->grapheme_count += 1;
	}

	if (state->grapheme_count > state->last_grapheme_count) {
		state->width += ucg_normalized_east_asian_width(this_rune);

		/* if (allocator != NULL) { */
			state->graphemes = (ucg_grapheme*)gb_resize(allocator,
				state->graphemes,
				sizeof(ucg_grapheme) * (state->grapheme_count),
				sizeof(ucg_grapheme) * (1 + state->grapheme_count));

			ucg_grapheme append = {
				byte_index,
				state->rune_count,
				state->width - state->last_width,
			};

			state->graphemes[state->grapheme_count - 1] = append;
		/* } */

		state->last_grapheme_count = state->grapheme_count;
		state->last_width = state->width;
	}

	state->last_rune = this_rune;
	state->rune_count += 1;

	if (!state->continue_sequence) {
		state->current_sequence = None;
		state->regional_indicator_counter = 0;
	}
	state->continue_sequence = false;
}

int ucg_decode_grapheme_clusters(
	gbAllocator allocator,
	const uint8_t* str,
	int str_len,

	ucg_grapheme** out_graphemes,
	i32* out_rune_count,
	i32* out_grapheme_count,
	i32* out_width
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
	// Please see the references for more information.
	//
	//
	// [1]: https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
	// [2]: https://www.unicode.org/reports/tr29/#Default_Grapheme_Cluster_Table
	// [3]: https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundary_Rules
	// [4]: https://www.unicode.org/reports/tr29/#Conformance

	// Additionally, this procedure takes into account Standard Annex #11,
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

	ucg_decoder_state state = {0};

#define UCG_DEFERRED_DECODE_STEP() (_ucg_decode_grapheme_clusters_deferred_step(allocator, &state, byte_index, this_rune))

	for (i32 byte_index = 0, bytes_advanced = 0; byte_index < str_len; byte_index += bytes_advanced) {
		int32_t this_rune = GB_RUNE_INVALID;
		bytes_advanced = (i32)(utf8_decode(str+byte_index, str_len-byte_index, &this_rune));
		if (this_rune == GB_RUNE_INVALID || bytes_advanced == 0) {
			// There was a Unicode parsing error; bail out.
			if (out_graphemes != NULL)      { *out_graphemes = state.graphemes; }
			if (out_rune_count != NULL)     { *out_rune_count = state.rune_count; }
			if (out_grapheme_count != NULL) { *out_grapheme_count = state.grapheme_count; }
			if (out_width != NULL)          { *out_width = state.width; }

			// Return an error code.
			return -1;
		}

		// "Do not break between a CR and LF. Otherwise, break before and after controls."
		//
		// GB3:                 CR   ×   LF
		// GB4: (Control | CR | LF)  ÷
		// GB5:                      ÷  (Control | CR | LF)
		if (this_rune == '\n' && state.last_rune == '\r') {
			state.last_rune_breaks_forward = false;
			state.bypass_next_rune = false;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		if (ucg_is_control(this_rune)) {
			state.grapheme_count += 1;
			state.last_rune_breaks_forward = true;
			state.bypass_next_rune = true;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// (This check is for rules that work forwards, instead of backwards.)
		if (state.bypass_next_rune) {
			if (state.last_rune_breaks_forward) {
				state.grapheme_count += 1;
				state.last_rune_breaks_forward = false;
			}

			state.bypass_next_rune = false;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// (Optimization 1: Prevent low runes from proceeding further.)
		//
		//  * 0xA9 and 0xAE are in the Extended_Pictographic range,
		//    which is checked later in GB11.
		if (this_rune != 0xA9 && this_rune != 0xAE && this_rune <= 0x2FF) {
			state.grapheme_count += 1;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// (Optimization 2: Check if the rune is in the Hangul space before getting specific.)
		if (0x1100 <= this_rune && this_rune <= 0xD7FB) {
			// "Do not break Hangul syllable sequences."
			//
			// GB6:        L   ×  (L | V | LV | LVT)
			// GB7:  (LV | V)  ×  (V | T)
			// GB8: (LVT | T)  ×   T
			if (ucg_is_hangul_syllable_leading(this_rune) ||
			    ucg_is_hangul_syllable_lv(this_rune)      ||
			    ucg_is_hangul_syllable_lvt(this_rune))
			{
				if (!ucg_is_hangul_syllable_leading(state.last_rune)) {
					state.grapheme_count += 1;
				}
				UCG_DEFERRED_DECODE_STEP(); continue;
			}

			if (ucg_is_hangul_syllable_vowel(this_rune)) {
				if (ucg_is_hangul_syllable_leading(state.last_rune) ||
				    ucg_is_hangul_syllable_vowel(state.last_rune)   ||
				    ucg_is_hangul_syllable_lv(state.last_rune))
				{
					UCG_DEFERRED_DECODE_STEP(); continue;
				}
				state.grapheme_count += 1;
				UCG_DEFERRED_DECODE_STEP(); continue;
			}

			if (ucg_is_hangul_syllable_trailing(this_rune)) {
				if (ucg_is_hangul_syllable_trailing(state.last_rune) ||
				    ucg_is_hangul_syllable_lvt(state.last_rune)      ||
				    ucg_is_hangul_syllable_lv(state.last_rune)       ||
				    ucg_is_hangul_syllable_vowel(state.last_rune))
				{
					UCG_DEFERRED_DECODE_STEP(); continue;
				}
				state.grapheme_count += 1;
				UCG_DEFERRED_DECODE_STEP(); continue;
			}
		}

		// "Do not break before extending characters or ZWJ."
		//
		// GB9:         × (Extend | ZWJ)
		if (this_rune == ZERO_WIDTH_JOINER) {
			state.continue_sequence = true;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		if (ucg_is_gcb_extend_class(this_rune)) {
			// (Support for GB9c.)
			if (state.current_sequence == Indic) {
				if (ucg_is_indic_conjunct_break_extend(this_rune)          && (
				    ucg_is_indic_conjunct_break_linker(state.last_rune)    ||
				    ucg_is_indic_conjunct_break_consonant(state.last_rune)    ))
				{
					state.continue_sequence = true;
					UCG_DEFERRED_DECODE_STEP(); continue;
				}

				if (ucg_is_indic_conjunct_break_linker(this_rune)          && (
				    ucg_is_indic_conjunct_break_linker(state.last_rune)    ||
				    ucg_is_indic_conjunct_break_extend(state.last_rune)    ||
				    ucg_is_indic_conjunct_break_consonant(state.last_rune)    ))
				{
					state.continue_sequence = true;
					UCG_DEFERRED_DECODE_STEP(); continue;
				}

				UCG_DEFERRED_DECODE_STEP(); continue;
			}

			// (Support for GB11.)
			if (state.current_sequence == Emoji                     && (
			    ucg_is_gcb_extend_class(state.last_rune)            ||
			    ucg_is_emoji_extended_pictographic(state.last_rune)    ))
			{
				state.continue_sequence = true;
			}

			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// _The GB9a and GB9b rules only apply to extended grapheme clusters:_
		// "Do not break before SpacingMarks, or after Prepend characters."
		//
		// GB9a:          ×  SpacingMark
		// GB9b: Prepend  ×
		if (ucg_is_spacing_mark(this_rune)) {
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		if (ucg_is_gcb_prepend_class(this_rune)) {
			state.grapheme_count += 1;
			state.bypass_next_rune = true;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// _The GB9c rule only applies to extended grapheme clusters:_
		// "Do not break within certain combinations with Indic_Conjunct_Break (InCB)=Linker."
		//
		// GB9c: \p{InCB=Consonant} [ \p{InCB=Extend} \p{InCB=Linker} ]* \p{InCB=Linker} [ \p{InCB=Extend} \p{InCB=Linker} ]*  ×  \p{InCB=Consonant}
		if (ucg_is_indic_conjunct_break_consonant(this_rune)) {
			if (state.current_sequence == Indic) {
				if (state.last_rune == ZERO_WIDTH_JOINER            ||
				    ucg_is_indic_conjunct_break_linker(state.last_rune))
				{
					state.continue_sequence = true;
				} else {
					state.grapheme_count += 1;
				}
			} else {
				state.grapheme_count += 1;
				state.current_sequence = Indic;
				state.continue_sequence = true;
			}
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		if (ucg_is_indic_conjunct_break_extend(this_rune)) {
			if (state.current_sequence == Indic) {
				if (ucg_is_indic_conjunct_break_consonant(state.last_rune) ||
				    ucg_is_indic_conjunct_break_linker(state.last_rune))
				{
					state.continue_sequence = true;
				} else {
					state.grapheme_count += 1;
				}
			}
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		if (ucg_is_indic_conjunct_break_linker(this_rune)) {
			if (state.current_sequence == Indic) {
				if (ucg_is_indic_conjunct_break_extend(state.last_rune) ||
				    ucg_is_indic_conjunct_break_linker(state.last_rune))
				{
					state.continue_sequence = true;
				} else {
					state.grapheme_count += 1;
				}
			}
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		//
		// (Curiously, there is no GB10.)
		//

		// "Do not break within emoji modifier sequences or emoji zwj sequences."
		//
		// GB11: \p{Extended_Pictographic} Extend* ZWJ  ×  \p{Extended_Pictographic}
		if (ucg_is_emoji_extended_pictographic(this_rune)) {
			if (state.current_sequence != Emoji || state.last_rune != ZERO_WIDTH_JOINER) {
				state.grapheme_count += 1;
			}
			state.current_sequence = Emoji;
			state.continue_sequence = true;
			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// "Do not break within emoji flag sequences.
		//  That is, do not break between regional indicator (RI) symbols
		//  if there is an odd number of RI characters before the break point."
		//
		// GB12:   sot (RI RI)* RI  ×  RI
		// GB13: [^RI] (RI RI)* RI  ×  RI
		if (ucg_is_regional_indicator(this_rune)) {
			if ((state.regional_indicator_counter & 1) == 0) {
				state.grapheme_count += 1;
			}

			state.current_sequence = Regional;
			state.continue_sequence = true;
			state.regional_indicator_counter += 1;

			UCG_DEFERRED_DECODE_STEP(); continue;
		}

		// "Otherwise, break everywhere."
		//
		// GB999: Any ÷ Any
		state.grapheme_count += 1;
		UCG_DEFERRED_DECODE_STEP();
	}

#undef UCG_DEFERRED_DECODE_STEP

	if (out_graphemes != NULL)      { *out_graphemes = state.graphemes; }
	if (out_rune_count != NULL)     { *out_rune_count = state.rune_count; }
	if (out_grapheme_count != NULL) { *out_grapheme_count = state.grapheme_count; }
	if (out_width != NULL)          { *out_width = state.width; }

	return 0;
}

#undef UCG_TABLE_LEN
#undef ZERO_WIDTH_SPACE
#undef ZERO_WIDTH_NON_JOINER
#undef ZERO_WIDTH_JOINER
#undef WORD_JOINER
