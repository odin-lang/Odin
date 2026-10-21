package test_core_strconv

import "core:strconv"
import "core:testing"

@(test)
test_quote_rune :: proc(t: ^testing.T) {
	Case :: struct {
		r: rune,
		want: string,
	}
	cases := [?]Case {
		{'a', "'a'"},
		{'¡', "'¡'"},
		{'ÿ', "'ÿ'"},
		{'あ', "'あ'"},
		{'φ', "'φ'"},
		{'♥', "'♥'"},
		{'😀', "'😀'"},
		{'\'', "'\\''"},
		{'\\', "'\\\\'"},
		{'"', "'\"'"},
		{'\a', "'\\a'"},
		{'\b', "'\\b'"},
		{'\e', "'\\e'"},
		{'\f', "'\\f'"},
		{'\n', "'\\n'"},
		{'\r', "'\\r'"},
		{'\t', "'\\t'"},
		{'\v', "'\\v'"},
		{'\x00', "'\\x00'"},
		{'\x01', "'\\x01'"},
		{'\x0f', "'\\x0f'"},
		{'\x1f', "'\\x1f'"},
		{' ', "' '"},
		{'\u0301', "'\u0301'"},
		{'\u00a0', "'\\u00a0'"},
		{'\u00ad', "'\\u00ad'"},
		{'\x7f', "'\\u007f'"},
		{'\u200b', "'\\u200b'"},
		{'\u2028', "'\\u2028'"},
		{'\u202f', "'\\u202f'"},
		{'\U0001d173', "'\\U0001d173'"},
		{'\ufffd', "'�'"},
		{rune(0x110000), "'\\ufffd'"},
	}
	for c in cases {
		// Every buffer size must produce a bounded prefix, including sizes that
		// truncate a UTF-8 rune or an escape sequence.
		for capacity in 0..=len(c.want) {
			guarded: [16]byte
			for i in 0..<len(guarded) {
				guarded[i] = 0xcc
			}
			got := strconv.quote_rune(guarded[1:1+capacity], c.r)
			testing.expectf(t, got == c.want[:capacity],
				"quote_rune(%U), capacity %d: expected %q, got %q",
				c.r, capacity, c.want[:capacity], got)
			testing.expect_value(t, guarded[0], 0xcc)
			testing.expect_value(t, guarded[1+capacity], 0xcc)
		}
	}

	buf: [16]byte
	testing.expect_value(t, strconv.quote_rune(nil, 'a'), "")
	testing.expect_value(t, strconv.quote_rune(buf[:], rune(-1)), "")
}
