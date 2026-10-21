package test_core_unicode

import "core:testing"
import "core:unicode"

@(test)
test_is_print :: proc(t: ^testing.T) {
	Case :: struct {
		r: rune,
		printable: bool,
	}
	cases := [?]Case {
		{'a', true},
		{' ', true},
		{'¡', true},
		{'ÿ', true},
		{'あ', true},
		{'φ', true},
		{'♥', true},
		{'😀', true},
		{'\u0301', true}, // Nonspacing mark.
		{'\u0903', true}, // Spacing combining mark.
		{'\u0488', true}, // Enclosing mark.
		{'\ufffd', true},
		{'\x00', false},
		{'\t', false},
		{'\x7f', false},
		{'\u0085', false},
		{'\u00a0', false},
		{'\u00ad', false},
		{'\u2003', false},
		{'\u200b', false},
		{'\u2028', false},
		{'\u2029', false},
		{'\u202f', false},
		{'\u0378', false}, // Unassigned.
		{'\ue000', false}, // Private use.
		{'\U0001d173', false}, // Non-BMP format character.
		{rune(0xd800), false},
		{unicode.MAX_RUNE, false},
		{rune(0x110000), false},
		{rune(-1), false},
		{rune(-65471), false}, // Truncates to U+0041 when cast to u16.
	}
	for c in cases {
		testing.expectf(t, unicode.is_print(c.r) == c.printable,
			"is_print(%U): expected %v", c.r, c.printable)
	}

	// Preserve the existing Latin-1 classification.
	for r: rune = 0; r <= unicode.MAX_LATIN1; r += 1 {
		want := (' ' <= r && r <= '~') || (0xa1 <= r && r != 0xad)
		testing.expect_value(t, unicode.is_print(r), want)
	}
}
