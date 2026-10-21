package test_core_io

import "core:fmt"
import "core:io"
import "core:strings"
import "core:testing"

@(test)
test_rune_quoting :: proc(t: ^testing.T) {
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
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	w := strings.to_writer(&b)
	buf: [16]byte
	for c in cases {
		strings.builder_reset(&b)
		n := io.write_quoted_rune(w, c.r)
		testing.expect_value(t, strings.to_string(b), c.want)
		testing.expect_value(t, n, len(c.want))

		strings.builder_reset(&b)
		n = strings.write_quoted_rune(&b, c.r)
		testing.expect_value(t, strings.to_string(b), c.want)
		testing.expect_value(t, n, len(c.want))
		testing.expect_value(t, fmt.bprintf(buf[:], "%q", c.r), c.want)

		strings.builder_reset(&b)
		total := 7
		written, err := io.write_escaped_rune(w, c.r, '\'', n_written = &total)
		escaped := c.want[1:len(c.want)-1]
		testing.expect_value(t, err, nil)
		testing.expect_value(t, strings.to_string(b), escaped)
		testing.expect_value(t, written, len(escaped))
		testing.expect_value(t, total, 7+written)
	}
}

@(test)
test_rune_escaping_modes :: proc(t: ^testing.T) {
	Case :: struct {
		r: rune,
		quote: byte,
		html_safe, for_json: bool,
		want: string,
	}
	cases := [?]Case {
		{'\'', '"', false, false, "'"},
		{'"', '"', false, false, "\\\""},
		{'\\', '"', false, false, "\\\\"},
		{'あ', '"', false, false, "あ"},
		{'<', '"', false, false, "<"},
		{'<', '"', true, false, "\\u003c"},
		{'>', '"', true, false, "\\u003e"},
		{'&', '"', true, false, "\\u0026"},
		{'<', '"', true, true, "\\u003c"},
		{'\x00', '"', false, true, "\\u0000"},
		{'\x01', '"', false, true, "\\u0001"},
		{'\a', '"', false, true, "\\u0007"},
		{'\e', '"', false, true, "\\u001b"},
		{'\v', '"', false, true, "\\u000b"},
		{'\b', '"', false, true, "\\b"},
		{'\f', '"', false, true, "\\f"},
		{'\n', '"', false, true, "\\n"},
		{'\r', '"', false, true, "\\r"},
		{'\t', '"', false, true, "\\t"},
		{'\u2028', '"', false, true, "\\u2028"},
		{'\u2029', '"', false, true, "\\u2029"},
		{'\U0001d173', '"', false, true, "\\ud834\\udd73"},
		{'😀', '"', false, true, "😀"},
	}
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	for c in cases {
		strings.builder_reset(&b)
		n, err := io.write_escaped_rune(strings.to_writer(&b), c.r, c.quote, c.html_safe, for_json = c.for_json)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, strings.to_string(b), c.want)
		testing.expect_value(t, n, len(c.want))
	}
}
