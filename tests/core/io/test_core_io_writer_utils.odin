package test_core_io

// Test procedures like io.write_escaped_rune etc.

import "core:io"
import "core:strings"
import "core:testing"
import "core:log"

T :: ^testing.T

test_runes :: [?]rune {	'a', '¡', 'ÿ', 'あ', 'φ', '♥',  '\'',  '"',  '\t',  '\x00',  '\u0300',  '\u1ab0',  '\x01', '\\',   ' ',  '\u202f' }
expected_quoted ::     "'a'  '¡'  'ÿ'  'あ'  'φ'  '♥'  '\\''  '\"'  '\\t'  '\\x00'  '\\u0300'  '\\u1ab0'  '\\x01'  '\\\\'  ' '  '\\u202f'  "
// Single-quotes must be escaped:
expected_unquoted_sq :: "a    ¡    ÿ    あ    φ    ♥    \\'    \"    \\t    \\x00    \\u0300    \\u1ab0    \\x01    \\\\         \\u202f    "
// Double-quotes must be escaped:
expected_unquoted_dq :: "a    ¡    ÿ    あ    φ    ♥    '    \\\"    \\t    \\x00    \\u0300    \\u1ab0    \\x01    \\\\         \\u202f    "
// No quotes escaped:
expected_unquoted_nq :: "a    ¡    ÿ    あ    φ    ♥    '    \"    \\t    \\x00    \\u0300    \\u1ab0    \\x01    \\\\         \\u202f    "

@(test)
test_io_write_escaped_rune_single_quote :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	for r in test_runes {
		io.write_escaped_rune(writer, r, '\'')
		io.write_string(writer, "    ")
	}

	log.debugf("%v", strings.to_string(sb))

	testing.expect_value(t, strings.to_string(sb), expected_unquoted_sq)
}

@(test)
test_io_write_escaped_rune_double_quote :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	for r in test_runes {
		io.write_escaped_rune(writer, r, '"')
		io.write_string(writer, "    ")
	}

	log.debugf("%v", strings.to_string(sb))

	testing.expect_value(t, strings.to_string(sb), expected_unquoted_dq)
}

@(test)
test_io_write_escaped_rune_no_quote :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	for r in test_runes {
		io.write_escaped_rune(writer, r, 0)
		io.write_string(writer, "    ")
	}

	log.debugf("%v", strings.to_string(sb))

	testing.expect_value(t, strings.to_string(sb), expected_unquoted_nq)
}

@(test)
test_io_write_quoted_rune :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	for r in test_runes {
		io.write_quoted_rune(writer, r)
		io.write_string(writer, "  ")
	}

	log.debugf("%v", strings.to_string(sb))

	testing.expect_value(t, strings.to_string(sb), expected_quoted)
}

@(test)
test_io_write_quoted_string16_replacement_characters :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	// Unpaired surrogates decode as REPLACEMENT_CHAR, just like a literal \ufffd.
	units := []u16 { 0xd800, 'A', 0xdc00, 0xfffd }
	io.write_quoted_string16(writer, transmute(string16)units)

	testing.expect_value(t, strings.to_string(sb), "\"\ufffdA\ufffd\ufffd\"")
}
