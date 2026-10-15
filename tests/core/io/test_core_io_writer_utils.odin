package test_core_io

// Test procedures like io.write_escaped_rune etc.

import "core:io"
import "core:strings"
import "core:testing"
import "core:log"
import "core:strconv"

T :: ^testing.T

test_runes :: [?]rune {
	'a','¡','ÿ','あ','φ','♥','\'','"','\t','\x00','\u0300','\u1ab0','\x01','\\',' ','\u202f',
}

expected_quoted :: "'a'  '¡'  'ÿ'  'あ'  'φ'  '♥'  '\\''  '\"'  '\\t'  '\\x00'  '\\u0300'  '\\u1ab0'  '\\x01'  '\\\\'  ' '  '\\u202f'  "

@(test)
test_io_write_escaped_rune_single_quote :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	for r in test_runes {
		io.write_escaped_rune(writer, r, '\'')
		io.write_string(writer, "  ")
	}

	log.infof("%v", strings.to_string(sb))
	// a  ¡  ÿ  \u3042  \u03c6  \u2665  \'  "  \t  \x00
	//          ?       ?       ?

	testing.expect_value(t, strings.to_string(sb), "a  ¡  ÿ  あ  φ  ♥  \\'  \"  \\t  \\x00  \\u0300  \\u1ab0  \\x01  \\\\     \\u202f  ")
}

@(test)
test_io_write_escaped_rune_double_quote :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	for r in test_runes {
		io.write_escaped_rune(writer, r, '"')
		io.write_string(writer, "  ")
	}

	log.infof("%v", strings.to_string(sb))
	// a  ¡  ÿ  \u3042  \u03c6  \u2665  '  \"  \t  \x00
	//          ?       ?       ?

	testing.expect_value(t, strings.to_string(sb), "a  ¡  ÿ  あ  φ  ♥  '  \\\"  \\t  \\x00  \\u0300  \\u1ab0  \\x01  \\\\     \\u202f  ")
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

	log.infof("%v", strings.to_string(sb))
	// 'a'  '¡'  'ÿ'  '\u3042'  '\u03c6'  '\u2665'  '\''  '"'  '\t'  '\x00'
	//                 ?         ?         ?

	testing.expect_value(t, strings.to_string(sb), expected_quoted)
}

@(test)
test_io_write_quoted_string16_replacement_characters :: proc(t: T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	writer := strings.to_writer(&sb)

	// Unpaired surrogates decode as REPLACEMENT_CHAR, just like a literal \ufffd.
	units := []u16{0xd800, 'A', 0xdc00, 0xfffd}
	io.write_quoted_string16(writer, transmute(string16)units)

	testing.expect_value(t, strings.to_string(sb), "\"\ufffdA\ufffd\ufffd\"")
}

@(test)
test_strconv_quote_rune :: proc(t: T) {
	buf: [150]byte
	b := buf[:]
	tmp: string

	for r in test_runes {
		tmp = strconv.quote_rune(b, r)
		b = b[len(tmp):]
		copy(b, "  "); b = b[2:]
	}

	s := transmute(string)buf[:cast(uintptr)raw_data(b) - cast(uintptr)raw_data(buf[:])]
	
	log.infof("%v", s)

	// 'a'  '¡'  'ÿ'  'あ'  'φ'  '♥'  '''  '"'  '\t'  '\x0'
	//                                 ?               ?

	testing.expect_value(t, s, expected_quoted)
}
