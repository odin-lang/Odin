package test_core_text_scanner

import "base:runtime"
import "core:fmt"
import "core:testing"
import "core:text/scanner"

Test_Context :: struct {
	t: ^testing.T,
	expected_fail_locations: []int,
	checking_errors: bool,
	loc: runtime.Source_Code_Location,
}

string_of_token :: proc(token: rune) -> string {
	switch token {
	case scanner.EOF: return "EOF"
	case scanner.Ident: return "Ident"
	case scanner.Int: return "Int"
	case scanner.Float: return "Float"
	case scanner.Char: return "Char"
	case scanner.String: return "String"
	case scanner.Raw_String: return "Raw_String"
	case scanner.Comment: return "Comment"
	case: return fmt.tprintf("%c", token)
	}
}

scanner_testing_error :: proc(s: ^scanner.Scanner, msg: string) {
	tc := cast(^Test_Context)context.user_ptr
	p := s.pos
	if !scanner.position_is_valid(p) {
		p = scanner.position(s)
	}

	if scanner.position_is_valid(p) {
		testing.expectf(tc.t, false, "[core:text/scanner] `%s`(%d:%d): %s\n", p.filename, p.line, p.column, msg, loc=tc.loc)
	} else {
		testing.expectf(tc.t, false, "[core:text/scanner] `%s`: %s\n", p.filename, msg, loc=tc.loc)
	}
}

check_expected_error :: proc(s: ^scanner.Scanner, msg: string) {
	tc := cast(^Test_Context)context.user_ptr

	p := s.pos
	if !scanner.position_is_valid(p) {
		p = scanner.position(s)
	}

	if !scanner.position_is_valid(p) {
		testing.expectf(tc.t, false, "invalid scanner position for %s",
			p.filename, loc=tc.loc)
		return
	}

	if tc.checking_errors {
		error_index :=  s.error_count-1 
		expected_locations_number := len(tc.expected_fail_locations)
		if expected_locations_number <= error_index {
			testing.expectf(tc.t, expected_locations_number > error_index,
				"more errors than expected: %s(%d:%d): %s",
				p.filename, p.line, p.column, msg, loc=tc.loc)
			return
		}
		expected_location := tc.expected_fail_locations[error_index]
		testing.expectf(tc.t, p.offset == expected_location,
			"incorrect location of error; expected %d, got %d; msg: %s(%d:%d): %s",
			expected_location, p.offset, p.filename, p.line, p.column, msg, loc=tc.loc)
	}
}

// Should be used separetly for the cases where `text` is correct and where
// it is not. To select a mode set the `should_fail` parameter.
test_scanner :: proc(
	t: ^testing.T,
	text: string,
	flags := scanner.Odin_Like_Tokens,
	expected_tokens := []rune{},
	expected_words := []string{},
	expected_fail_locations := []int{},
	should_fail := false,
	loc := #caller_location,
) {
	scratch := runtime.default_temp_allocator_temp_begin()
	defer runtime.default_temp_allocator_temp_end(scratch)

	tc: Test_Context
	expected_token_number := -1

	checking_tokens := len(expected_tokens) != 0
	checking_words 	:= len(expected_words) != 0
	checking_errors := len(expected_fail_locations) != 0

	source_name: string
	if text == "" || len(text) > 85 {
		source_name = loc.procedure
	} else {
		source_name = text
	}

	if checking_tokens && checking_words {
		testing.expectf(t, len(expected_tokens) == len(expected_words),
			"`%s`: `expected_tokens` and `expected_words` should be of the same length",
			source_name, loc=loc)
	}
	if checking_tokens {
		expected_token_number = len(expected_tokens)
	} else if checking_words {
		expected_token_number = len(expected_words)
	}

	counting_tokens := expected_token_number != -1

	tc.t = t
	tc.expected_fail_locations = expected_fail_locations
	tc.checking_errors = checking_errors
	tc.loc = loc
	context.user_ptr = &tc

	if !should_fail {
		assert(!checking_errors, "test_scanner does not accept non-empty `expected_fail_locations` with `should_fail = false`", loc)
	}

	s: scanner.Scanner
	scanner.init(&s, text, source_name)
	s.flags = flags
	s.error = scanner_testing_error

	if !should_fail {
		s.error = scanner_testing_error
	} else {
		s.error = check_expected_error
	}

	token_counter := 0
	for token := scanner.scan(&s); token != scanner.EOF; token = scanner.scan(&s) {
		
		if counting_tokens {
			if ok := token_counter < expected_token_number; !ok {
				testing.expectf(t, false, "`%s`: more tokens than expected(%d)",
					source_name, expected_token_number, loc=loc)
				break
			}
			if checking_tokens {
				expected_token := expected_tokens[token_counter]
				testing.expectf(t, token == expected_token,  "`%s`(%d:%d): expected token `%s`, got `%s`",
					source_name, s.pos.line, s.pos.column, string_of_token(expected_token), string_of_token(token), loc=loc)
			}
			if checking_words {
				token_word := scanner.token_text(&s)
				expected_word := expected_words[token_counter]
				testing.expectf(t, token_word == expected_word,  "`%s`(%d:%d): expected word `%s`, got `%s`",
					source_name, s.pos.line, s.pos.column, expected_word, token_word, loc=loc)
			}
		}

		token_counter += 1
	}

	if counting_tokens {
		testing.expectf(t, token_counter == expected_token_number,
			"`%s`: fewer tokens than expected; expected %d, got %d",
			source_name, expected_token_number, token_counter, loc=loc)
	}
	
	if !should_fail {
		testing.expectf(t, s.error_count == 0, "`%s`: unexpected scanning errors", source_name, loc=loc)
	} else {
		testing.expect(t, s.error_count > 0, "`%s`: case did not fail", source_name, loc=loc)
		if checking_errors {
			testing.expectf(t, s.error_count == len(expected_fail_locations),
				"`%s`: case failed incorrect number of times; expected: %d, got %d",
				source_name, len(expected_fail_locations), s.error_count, loc=loc)
		}
	}
}

@test
numbers :: proc(t: ^testing.T) {
	test_scanner(
		t = t,
		text = "0x1.2, 0h1.2",
		expected_fail_locations = {0, 7},
		should_fail = true,
	)
}

@test 
range_operator :: proc(t: ^testing.T) {
	test_scanner(
		t = t,
		text = "0x00..=0xff",
		expected_tokens = {scanner.Int, '.', '.', '=', scanner.Int},
		expected_words = {"0x00", ".", ".", "=", "0xff"},
	)
}

@test
escape_sequences :: proc(t: ^testing.T) {
	test_scanner(
		t = t,
		text = `"\0""\11""\u""\u123""\U1ff1234"`,
		expected_fail_locations = {0,4,9,13,20},
		should_fail = true,
	)

	test_scanner(
		t = t,
		text = `"\a\b\e\f\n\r\t\v\\\"\'\567\x1f\u1f34\U1ff1234e"`,
	)
}
