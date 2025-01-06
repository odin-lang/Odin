package test_core_text_regex

import "core:fmt"
import "core:io"
import "core:log"
import "core:reflect"
import "core:strings"
import "core:testing"
import "core:text/regex"
import "core:text/regex/common"
import "core:text/regex/parser"
import "core:text/regex/tokenizer"


check_expression_with_flags :: proc(t: ^testing.T, pattern: string, flags: regex.Flags, haystack: string, needles: ..string, loc := #caller_location) {
	rex, parse_err := regex.create(pattern, flags)
	if !testing.expect_value(t, parse_err, nil, loc = loc) {
		log.infof("Failed test's flags were: %v", flags, location = loc)
		return
	}
	defer regex.destroy(rex)

	capture, success := regex.match(rex, haystack)
	defer regex.destroy(capture)

	if len(needles) > 0 {
		testing.expect(t, success, "match failed", loc = loc)
	}

	matches_aligned := testing.expectf(t, len(needles) == len(capture.groups),
		"expected %i match groups, got %i (flags: %w)",
		len(needles), len(capture.groups), flags, loc = loc)

	if matches_aligned {
		for needle, i in needles {
			if !testing.expectf(t, capture.groups[i] == needle,
				"match group %i was %q, expected %q (flags: %w)",
				i, capture.groups[i], needle, flags, loc = loc) {
			}
		}
	} else {
		log.infof("match groups were: %v", capture.groups, location = loc)
	}

	for pos, g in capture.pos {
		pos_str := haystack[pos[0]:pos[1]]
		if !testing.expectf(t, pos_str == capture.groups[g], "position string %v %q does not correspond to group string %q", pos, pos_str, capture.groups[g]) {
			break
		}
	}
}

check_expression :: proc(t: ^testing.T, pattern, haystack: string, needles: ..string, extra_flags := regex.Flags{}, loc := #caller_location) {
	check_expression_with_flags(t, pattern, { .Global } + extra_flags,
		haystack, ..needles, loc = loc)
	check_expression_with_flags(t, pattern, { .Global, .No_Optimization } + extra_flags,
		haystack, ..needles, loc = loc)
	check_expression_with_flags(t, pattern, { .Global, .Unicode } + extra_flags,
		haystack, ..needles, loc = loc)
	check_expression_with_flags(t, pattern, { .Global, .Unicode, .No_Optimization } + extra_flags,
		haystack, ..needles, loc = loc)
}

expect_error :: proc(t: ^testing.T, pattern: string, expected_error: typeid, flags := regex.Flags{}, loc := #caller_location) {
	rex, err := regex.create(pattern, flags)
	regex.destroy(rex)

	variant := reflect.get_union_variant(err)
	variant_ti := reflect.union_variant_type_info(variant)
	expected_ti := type_info_of(expected_error)

	testing.expect_value(t, variant_ti, expected_ti, loc = loc)
}


@test
test_concatenation :: proc(t: ^testing.T) {
	check_expression(t, "abc", "abc", "abc")
}

@test
test_rune_class :: proc(t: ^testing.T) {
	EXPR :: "[abc]"
	check_expression(t, EXPR, "a", "a")
	check_expression(t, EXPR, "b", "b")
	check_expression(t, EXPR, "c", "c")
}

@test
test_rune_ranges :: proc(t: ^testing.T) {
	EXPR :: "0x[0-9A-Fa-f]+"
	check_expression(t, EXPR, "0x0065c816", "0x0065c816")
}

@test
test_rune_range_terminal_dash :: proc(t: ^testing.T) {
	{
		EXPR :: "[a-]"
		check_expression(t, EXPR, "a", "a")
		check_expression(t, EXPR, "-", "-")
	}
	{
		EXPR :: "[-a]"
		check_expression(t, EXPR, "a", "a")
		check_expression(t, EXPR, "-", "-")
	}
	{
		EXPR :: "[-a-]"
		check_expression(t, EXPR, "a", "a")
		check_expression(t, EXPR, "-", "-")
	}
	{
		EXPR :: "[-]"
		check_expression(t, EXPR, "-", "-")
	}
	{
		EXPR :: "[--]"
		check_expression(t, EXPR, "-", "-")
	}
	{
		EXPR :: "[---]"
		check_expression(t, EXPR, "-", "-")
	}
}

@test
test_rune_range_escaping_class :: proc(t: ^testing.T) {
	{
		EXPR :: `[\]a\[\.]`
		check_expression(t, EXPR, "a", "a")
		check_expression(t, EXPR, "[", "[")
		check_expression(t, EXPR, "]", "]")
		check_expression(t, EXPR, ".", ".")
		check_expression(t, EXPR, "b")
	}
	{
		EXPR :: `a[\\]b`
		check_expression(t, EXPR, `a\b`, `a\b`)
	}
}

@test
test_negated_rune_class :: proc(t: ^testing.T) {
	EXPR :: "[^ac-d]"
	check_expression(t, EXPR, "a")
	check_expression(t, EXPR, "b", "b")
	check_expression(t, EXPR, "e", "e")
	check_expression(t, EXPR, "c")
	check_expression(t, EXPR, "d")
}

@test
test_shorthand_classes :: proc(t: ^testing.T) {
	EXPR_P :: `\d\w\s`
	check_expression(t, EXPR_P, "1a ", "1a ")
	check_expression(t, EXPR_P, "a!1")
	EXPR_N :: `\D\W\S`
	check_expression(t, EXPR_N, "a!1", "a!1")
	check_expression(t, EXPR_N, "1a ")
}

@test
test_shorthand_classes_in_classes :: proc(t: ^testing.T) {
	EXPR_P :: `[\d][\w][\s]`
	check_expression(t, EXPR_P, "1a ", "1a ")
	check_expression(t, EXPR_P, "a!1")
	EXPR_NP :: `[^\d][^\w][^\s]`
	check_expression(t, EXPR_NP, "a!1", "a!1")
	check_expression(t, EXPR_NP, "1a ")
	EXPR_N :: `[\D][\W][\S]`
	check_expression(t, EXPR_N, "a!1", "a!1")
	check_expression(t, EXPR_N, "1a ")
	EXPR_NN :: `[^\D][^\W][^\S]`
	check_expression(t, EXPR_NN, "1a ", "1a ")
	check_expression(t, EXPR_NN, "a!1")
}

@test
test_mixed_shorthand_class :: proc(t: ^testing.T) {
	EXPR_P :: `[\d\s]+`
	check_expression(t, EXPR_P, "0123456789 98", "0123456789 98")
	check_expression(t, EXPR_P, "!@#$%^&*()_()")
	EXPR_NP :: `[^\d\s]+`
	check_expression(t, EXPR_NP, "!@#$%^&*()_()", "!@#$%^&*()_()")
	check_expression(t, EXPR_NP, "0123456789 98")
}

@test
test_wildcard :: proc(t: ^testing.T) {
	EXPR :: "."
	check_expression(t, EXPR, "a", "a")
	check_expression(t, EXPR, ".", ".")
}

@test
test_alternation :: proc(t: ^testing.T) {
	EXPR :: "aa|bb|cc"
	check_expression(t, EXPR, "aa", "aa")
	check_expression(t, EXPR, "bb", "bb")
	check_expression(t, EXPR, "cc", "cc")
}

@test
test_optional :: proc(t: ^testing.T) {
	EXPR :: "a?a?a?aaa"
	check_expression(t, EXPR, "aaa", "aaa")
}

@test
test_repeat_zero :: proc(t: ^testing.T) {
	EXPR :: "a*b"
	check_expression(t, EXPR, "aaab", "aaab")
}

@test
test_repeat_one :: proc(t: ^testing.T) {
	EXPR :: "a+b"
	check_expression(t, EXPR, "aaab", "aaab")
}

@test
test_greedy :: proc(t: ^testing.T) {
	HTML :: "<html></html>"

	check_expression(t, "<.+>", HTML, HTML)
	check_expression(t, "<.*>", HTML, HTML)

	check_expression(t, "aaa?", "aaa", "aaa")
}

@test
test_non_greedy :: proc(t: ^testing.T) {
	HTML :: "<html></html>"

	check_expression(t, "<.+?>", HTML, "<html>")
	check_expression(t, "<.*?>", HTML, "<html>")

	// NOTE: make a comment about optional non-greedy capture groups
	check_expression(t, "aaa??", "aaa", "aa")
}

@test
test_groups :: proc(t: ^testing.T) {
	check_expression(t, "a(b)",   "ab", /*|*/ "ab",  "b")
	check_expression(t, "(a)b",   "ab", /*|*/ "ab",  "a")
	check_expression(t, "(a)(b)", "ab", /*|*/ "ab",  "a",  "b")

	check_expression(t, "(a(b))", "ab", /*|*/ "ab", "ab",  "b")
	check_expression(t, "((ab))", "ab", /*|*/ "ab", "ab", "ab")
	check_expression(t, "((a)b)", "ab", /*|*/ "ab", "ab",  "a")

	check_expression(t, "(ab)+",   "ababababab", /*|*/ "ababababab", "ab")
	check_expression(t, "((ab)+)", "ababababab", /*|*/ "ababababab", "ababababab", "ab")
}

@test
test_class_group_repeat :: proc(t: ^testing.T) {
	EXPR_1 :: "([0-9]:?)+"
	EXPR_2 :: "([0-9]+:?)+"
	check_expression(t, EXPR_1, "123:456:789", "123:456:789", "9")
	check_expression(t, EXPR_2, "123:456:789", "123:456:789", "789")
}

@test
test_non_capture_group :: proc(t: ^testing.T) {
	EXPR :: "(?:a|b)c"
	check_expression(t, EXPR, "ac", "ac")
	check_expression(t, EXPR, "bc", "bc")
	check_expression(t, EXPR, "cc")
}

@test
test_optional_capture_group :: proc(t: ^testing.T) {
	EXPR :: "^(blue|straw)?berry"
	check_expression(t, EXPR, "berry", "berry")
	check_expression(t, EXPR, "blueberry", "blueberry", "blue")
	check_expression(t, EXPR, "strawberry", "strawberry", "straw")
	check_expression(t, EXPR, "cranberry")
}

@test
test_max_capture_groups :: proc(t: ^testing.T) {
	sb_pattern := strings.builder_make()
	sb_haystack := strings.builder_make()
	expected_captures: [dynamic]string
	defer {
		strings.builder_destroy(&sb_pattern)
		strings.builder_destroy(&sb_haystack)
		delete(expected_captures)
	}

	w_pattern := strings.to_writer(&sb_pattern)
	w_haystack := strings.to_writer(&sb_haystack)

	// The full expression capture, capture 0:
	for i in 1..<common.MAX_CAPTURE_GROUPS {
		io.write_int(w_pattern, i)
	}
	append(&expected_captures, fmt.tprint(strings.to_string(sb_pattern)))
	strings.builder_reset(&sb_pattern)

	// The individual captures:
	for i in 1..<common.MAX_CAPTURE_GROUPS {
		io.write_byte(w_pattern, '(')
		io.write_int(w_pattern, i)
		io.write_byte(w_pattern, ')')

		io.write_int(w_haystack, i)

		append(&expected_captures, fmt.tprint(i))
	}

	pattern := strings.to_string(sb_pattern)
	haystack := strings.to_string(sb_haystack)

	rex, err := regex.create(pattern)
	defer regex.destroy(rex)
	if !testing.expect_value(t, err, nil) {
		return
	}

	capture, ok := regex.match(rex, haystack)
	defer regex.destroy(capture)
	if !testing.expectf(t, ok, "expected %q to match %q", pattern, haystack) {
		return
	}

	if !testing.expect_value(t, len(capture.groups), common.MAX_CAPTURE_GROUPS) {
		return
	}

	for g, i in capture.groups {
		testing.expect_value(t, g, expected_captures[i])
	}
}

@test
test_repetition :: proc(t: ^testing.T) {
	{
		EXPR :: "^a{3}$"
		check_expression(t, EXPR, "aaa", "aaa")
		check_expression(t, EXPR, "aaaa")
	}
	{
		EXPR :: "^a{3,5}$"
		check_expression(t, EXPR, "aaa", "aaa")
		check_expression(t, EXPR, "aaaa", "aaaa")
		check_expression(t, EXPR, "aaaaa", "aaaaa")
		check_expression(t, EXPR, "aaaaaa")
	}
	{
		EXPR :: "^(?:meow){2}$"
		check_expression(t, EXPR, "meow")
		check_expression(t, EXPR, "meowmeow", "meowmeow")
		check_expression(t, EXPR, "meowmeowmeow")
	}
	{
		EXPR :: "a{2,}"
		check_expression(t, EXPR, "a")
		check_expression(t, EXPR, "aa", "aa")
		check_expression(t, EXPR, "aaa", "aaa")
	}
	{
		EXPR :: "a{,2}"
		check_expression(t, EXPR, "a", "a")
		check_expression(t, EXPR, "aa", "aa")
		check_expression(t, EXPR, "aaa", "aa")
	}
	{
		EXPR :: "^a{3,3}$"
		check_expression(t, EXPR, "aa")
		check_expression(t, EXPR, "aaa", "aaa")
		check_expression(t, EXPR, "aaaa")
	}
	{
		EXPR :: "a{0,}"
		check_expression(t, EXPR, "aaa", "aaa")
	}
}

@test
test_repeated_groups :: proc(t: ^testing.T) {
	{
		EXPR :: "(ab){3}"
		check_expression(t, EXPR, "ababab", "ababab", "ab")
	}
	{
		EXPR :: "((?:ab){3})"
		check_expression(t, EXPR, "ababab", "ababab", "ababab")
	}
}

@test
test_escaped_newline :: proc(t: ^testing.T) {
	EXPR :: `\n[\n]`
	check_expression(t, EXPR, "\n\n", "\n\n")
}

@test
test_anchors :: proc(t: ^testing.T) {
	{
		EXPR :: "^ab"
		check_expression(t, EXPR, "ab", "ab")
		check_expression(t, EXPR, "aab")
	}
	{
		EXPR :: "ab$"
		check_expression(t, EXPR, "ab", "ab")
		check_expression(t, EXPR, "aab", "ab")
	}
	{
		EXPR :: "^ab$"
		check_expression(t, EXPR, "ab", "ab")
		check_expression(t, EXPR, "aab")
	}
}

@test
test_grouped_anchors :: proc(t: ^testing.T) {
	{
		EXPR :: "^a|b"
		check_expression(t, EXPR, "ab", "a")
		check_expression(t, EXPR, "ba", "b")
	}
	{
		EXPR :: "b|c$"
		check_expression(t, EXPR, "ac", "c")
		check_expression(t, EXPR, "cb", "b")
	}
	{
		EXPR :: "^hellope$|world"
		check_expression(t, EXPR, "hellope", "hellope")
		check_expression(t, EXPR, "hellope world", "world")
	}
}

@test
test_empty_alternation :: proc(t: ^testing.T) {
	{
		EXPR :: "(?:a|)b"
		check_expression(t, EXPR, "ab", "ab")
		check_expression(t, EXPR, "b", "b")
	}
	{
		EXPR :: "(?:|a)b"
		check_expression(t, EXPR, "ab", "ab")
		check_expression(t, EXPR, "b", "b")
	}
	{
		EXPR :: "|b"
		check_expression(t, EXPR, "b", "")
		check_expression(t, EXPR, "", "")
	}
	{
		EXPR :: "a|"
		check_expression(t, EXPR, "a", "a")
		check_expression(t, EXPR, "", "")
	}
	{
		EXPR :: "|"
		check_expression(t, EXPR, "a", "")
		check_expression(t, EXPR, "", "")
	}
}

@test
test_empty_class :: proc(t: ^testing.T) {
	EXPR :: "a[]b"
	check_expression(t, EXPR, "ab", "ab")
}

@test
test_dot_in_class :: proc(t: ^testing.T) {
	EXPR :: `[a\..]`
	check_expression(t, EXPR, "a", "a")
	check_expression(t, EXPR, ".", ".")
	check_expression(t, EXPR, "b")
}


@test
test_word_boundaries :: proc(t: ^testing.T) {
	STR :: "This is an island."
	{
		EXPR :: `\bis\b`
		check_expression(t, EXPR, STR, "is")
	}
	{
		EXPR :: `\bis\w+`
		check_expression(t, EXPR, STR, "island")
	}
	{
		EXPR :: `\w+is\b`
		check_expression(t, EXPR, STR, "This")
	}
	{
		EXPR :: `\b\w\w\b`
		check_expression(t, EXPR, STR, "is")
	}
}

@test
test_pos_index_explicitly :: proc(t: ^testing.T) {
	STR :: "This is an island."
	EXPR :: `\bis\b`

	rex, err := regex.create(EXPR, { .Global })
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer regex.destroy(rex)

	capture, success := regex.match(rex, STR)
	if !testing.expect(t, success) {
		return
	}
	defer regex.destroy(capture)

	if !testing.expect_value(t, len(capture.pos), 1) {
		return
	}
	testing.expect_value(t, capture.pos[0][0], 5)
	testing.expect_value(t, capture.pos[0][1], 7)
}

@test
test_non_word_boundaries :: proc(t: ^testing.T) {
	{
		EXPR :: `.\B.`
		check_expression(t, EXPR, "ab", "ab")
		check_expression(t, EXPR, "  ", "  ")
		check_expression(t, EXPR, "a ")
		check_expression(t, EXPR, " b")
	}
	{
		EXPR :: `\B.\B`
		check_expression(t, EXPR, "a")
		check_expression(t, EXPR, "abc", "b")
	}
	{
		EXPR :: `\B.+`
		check_expression(t, EXPR, "abc", "bc")
	}
	{
		EXPR :: `.+\B`
		check_expression(t, EXPR, "abc", "ab")
	}
}

@test
test_empty_patterns :: proc(t: ^testing.T) {
	{
		EXPR :: ""
		check_expression(t, EXPR, "abc", "")
	}
	{
		EXPR :: "^$"
		check_expression(t, EXPR, "", "")
		check_expression(t, EXPR, "a")
	}
}

@test
test_unanchored :: proc(t: ^testing.T) {
	EXPR :: "ab"
	check_expression(t, EXPR, "cab", "ab")
}

@test
test_affixes :: proc(t: ^testing.T) {
	// This test is for the optimizer.
	EXPR :: "^(?:samples|ample|sample)$"
	check_expression(t, EXPR, "sample", "sample")
	check_expression(t, EXPR, "samples", "samples")
	check_expression(t, EXPR, "ample", "ample")
	check_expression(t, EXPR, "amples")
}

@test
test_anchored_capture_until_end :: proc(t: ^testing.T) {
	// This test is for the optimizer.
	{
		EXPR :: `^hellope.*$`
		check_expression(t, EXPR, "hellope world", "hellope world")
		check_expression(t, EXPR, "hellope", "hellope")
		check_expression(t, EXPR, "hellope !", "hellope !")
	}
	{
		EXPR :: `^hellope.+$`
		check_expression(t, EXPR, "hellope world", "hellope world")
		check_expression(t, EXPR, "hellope")
		check_expression(t, EXPR, "hellope !", "hellope !")
	}
	{
		EXPR :: `^(aa|bb|cc.+$).*$`
		check_expression(t, EXPR, "aa", "aa", "aa")
		check_expression(t, EXPR, "bb", "bb", "bb")
		check_expression(t, EXPR, "bbaa", "bbaa", "bb")
		check_expression(t, EXPR, "cc")
		check_expression(t, EXPR, "ccc", "ccc", "ccc")
		check_expression(t, EXPR, "cccc", "cccc", "cccc")
	}
	// This makes sure that the `.*$` / `.*$` optimization doesn't cause
	// any issues if someone does something strange like putting it in the
	// middle of an expression.
	{
		EXPR :: `^(a(b.*$)c).*$`
		check_expression(t, EXPR, "a")
		check_expression(t, EXPR, "ab")
		check_expression(t, EXPR, "abc")
	}
	{
		EXPR :: `^(a(b.*$)?c).*$`
		check_expression(t, EXPR, "a")
		check_expression(t, EXPR, "ab")
		check_expression(t, EXPR, "abc")
		check_expression(t, EXPR, "ac", "ac", "ac")
		check_expression(t, EXPR, "acc", "acc", "ac")
	}
}

@test
test_unicode_explicitly :: proc(t: ^testing.T) {
	{
		EXPR :: "^....!$"
		check_expression_with_flags(t, EXPR, { .Unicode },
			"こにちは!", "こにちは!")
		check_expression_with_flags(t, EXPR, { .Unicode, .No_Optimization },
			"こにちは!", "こにちは!")
	}
	{
		EXPR :: "こにちは!"
		check_expression_with_flags(t, EXPR, { .Global, .Unicode },
			"Hello こにちは!", "こにちは!")
		check_expression_with_flags(t, EXPR, { .Global, .Unicode, .No_Optimization },
			"Hello こにちは!", "こにちは!")
	}
}

@test
test_no_capture_match :: proc(t: ^testing.T) {
	EXPR :: "^abc$"

	rex, err := regex.create(EXPR, { .No_Capture })
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer regex.destroy(rex)

	_, matched := regex.match(rex, "abc")
	testing.expect(t, matched)
}

@test
test_comments :: proc(t: ^testing.T) {
	EXPR :: `^[abc]# This is a comment.
[def]# This is another comment.
\#$# This is a comment following an escaped '#'.`
	check_expression(t, EXPR, "ad#", "ad#")
}

@test
test_ignore_whitespace :: proc(t: ^testing.T) {
	EXPR :: "\f" + `
\ H    e     l   # Note that the first space on this line is escaped, thus it is not ignored.
	l
o    p     e [ ]   w   o  rld (?: [ ]) ! # Spaces in classes are fine, too.
` + "\r"

	check_expression(t, EXPR, " Hellope world !", " Hellope world !", extra_flags = { .Ignore_Whitespace })
}

@test
test_case_insensitive :: proc(t: ^testing.T) {
	EXPR :: `hElLoPe [w!][o-P]+rLd!`
	check_expression(t, EXPR, "HeLlOpE WoRlD!", "HeLlOpE WoRlD!", extra_flags = { .Case_Insensitive })
}

@test
test_multiline :: proc(t: ^testing.T) {
	{
		EXPR :: `^hellope$world$`
		check_expression(t, EXPR, "\nhellope\nworld\n", "\nhellope\nworld\n", extra_flags = { .Multiline })
		check_expression(t, EXPR, "hellope\nworld", "hellope\nworld", extra_flags = { .Multiline })
		check_expression(t, EXPR, "hellope\rworld", "hellope\rworld", extra_flags = { .Multiline })
		check_expression(t, EXPR, "hellope\r\nworld", "hellope\r\nworld", extra_flags = { .Multiline })
	}
	{
		EXPR :: `^?.$`
		check_expression(t, EXPR, "\nh", "\nh", extra_flags = { .Multiline })
		check_expression(t, EXPR, "h", "h", extra_flags = { .Multiline })
	}
	{
		EXPR :: `^$`
		check_expression(t, EXPR, "\n", "\n", extra_flags = { .Multiline })
		check_expression(t, EXPR, "", "", extra_flags = { .Multiline })
	}
	{
		EXPR :: `$`
		check_expression(t, EXPR, "\n", "\n", extra_flags = { .Multiline })
		check_expression(t, EXPR, "", "", extra_flags = { .Multiline })
	}
}

@test
test_optional_inside_optional :: proc(t: ^testing.T) {
	EXPR :: `(?:a?)?`
	check_expression(t, EXPR, "a", "a")
	check_expression(t, EXPR, "", "")
}



@test
test_error_bad_repetitions :: proc(t: ^testing.T) {
	expect_error(t, "a{-1,2}", parser.Invalid_Repetition)
	expect_error(t, "a{2,1}",  parser.Invalid_Repetition)
	expect_error(t, "a{bc}",   parser.Invalid_Repetition)
	expect_error(t, "a{,-3}",  parser.Invalid_Repetition)
	expect_error(t, "a{d,}",   parser.Invalid_Repetition)
	expect_error(t, "a{}",     parser.Invalid_Repetition)
	expect_error(t, "a{0,0}",  parser.Invalid_Repetition)
	expect_error(t, "a{,0}",   parser.Invalid_Repetition)
	expect_error(t, "a{,}",    parser.Invalid_Repetition)

	// Unclosed braces
	expect_error(t, "a{",    parser.Unexpected_EOF)
	expect_error(t, "a{",    parser.Unexpected_EOF)
	expect_error(t, "a{1,2", parser.Unexpected_EOF)
	expect_error(t, "a{0,",  parser.Unexpected_EOF)
	expect_error(t, "a{,3",  parser.Unexpected_EOF)
	expect_error(t, "a{,",   parser.Unexpected_EOF)
}

@test
test_error_invalid_unicode_in_pattern :: proc(t: ^testing.T) {
	expect_error(t, "\xC0", parser.Invalid_Unicode)
}

@test
test_error_invalid_unicode_in_string :: proc(t: ^testing.T) {
	EXPR :: "^...$"
	// NOTE: Matching on invalid Unicode is currently safe.
	// If `utf8.decode_rune` ever changes, this test may fail.
	check_expression(t, EXPR, "\xC0\xFF\xFE", "\xC0\xFF\xFE")
}

@test
test_error_too_many_capture_groups :: proc(t: ^testing.T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	w := strings.to_writer(&sb)

	for i in 1..<common.MAX_CAPTURE_GROUPS+1 {
		io.write_byte(w, '(')
		io.write_int(w, i)
		io.write_byte(w, ')')
	}

	pattern := strings.to_string(sb)
	expect_error(t, pattern, parser.Too_Many_Capture_Groups)
}

@test
test_error_unclosed_paren :: proc(t: ^testing.T) {
	expect_error(t, "(Hellope", parser.Expected_Token)
}

@test
test_error_unclosed_class :: proc(t: ^testing.T) {
	expect_error(t, "[helope", parser.Unexpected_EOF)
	expect_error(t, `a[\]b`,   parser.Unexpected_EOF)
	expect_error(t, `a[\b`,    parser.Unexpected_EOF)
	expect_error(t, `a[\`,     parser.Unexpected_EOF)
	expect_error(t, `a[`,      parser.Unexpected_EOF)
}

@test
test_error_invalid_unicode_in_unclosed_class :: proc(t: ^testing.T) {
	expect_error(t, "[\xC0", parser.Invalid_Unicode, { .Unicode })
}

@test
test_program_too_big :: proc(t: ^testing.T) {
	sb := strings.builder_make()
	w := strings.to_writer(&sb)
	defer strings.builder_destroy(&sb)

	// Each byte will turn into two bytes for the whole opcode and operand,
	// then the compiler will insert 5 more bytes for the Save instructions
	// and the Match.
	N :: common.MAX_PROGRAM_SIZE/2 - 2
	for _ in 0..<N {
		io.write_byte(w, 'a')
	}

	rex, err := regex.create(strings.to_string(sb))
	regex.destroy(rex)

	compile_err, _ := err.(regex.Compiler_Error)
	testing.expect_value(t, compile_err, regex.Compiler_Error.Program_Too_Big)
}

@test
test_too_many_classes :: proc(t: ^testing.T) {
	sb := strings.builder_make()
	w := strings.to_writer(&sb)
	defer strings.builder_destroy(&sb)

	N :: common.MAX_CLASSES
	for i in 0..<rune(N) {
		io.write_byte(w, '[')
		io.write_rune(w, 'a' + i)
		io.write_rune(w, 'b' + i)
		io.write_byte(w, ']')
	}

	rex, err := regex.create(strings.to_string(sb))
	regex.destroy(rex)

	compile_err, _ := err.(regex.Compiler_Error)
	testing.expect_value(t, compile_err, regex.Compiler_Error.Too_Many_Classes)
}

@test
test_empty_captures :: proc(t: ^testing.T) {
	rex, err := regex.create("(?:)()")
	regex.destroy(rex)

	parse_err, _ := err.(regex.Parser_Error)
	token_err, ok := parse_err.(parser.Expected_Token)
	if !ok {
		log.errorf("expected error Expected_Token, got %v", parse_err)
	} else {
		testing.expect_value(t, token_err.kind, tokenizer.Token_Kind.Close_Paren)
	}
}

@test
test_lone_enders :: proc(t: ^testing.T) {
	check_expression(t, `)`, ")", ")")
	check_expression(t, `]`, "]", "]")
}

@test
test_invalid_unary_tokens :: proc(t: ^testing.T) {
	expect_error(t, `*`,     parser.Invalid_Token)
	expect_error(t, `*?`,    parser.Invalid_Token)
	expect_error(t, `+`,     parser.Invalid_Token)
	expect_error(t, `+?`,    parser.Invalid_Token)
	expect_error(t, `?`,     parser.Invalid_Token)
	expect_error(t, `??`,    parser.Invalid_Token)
	expect_error(t, `{}`,    parser.Invalid_Token)
	expect_error(t, `{1,}`,  parser.Invalid_Token)
	expect_error(t, `{1,2}`, parser.Invalid_Token)
	expect_error(t, `{,2}`,  parser.Invalid_Token)

	expect_error(t, `\`, parser.Unexpected_EOF)
}

@test
test_everything_at_once :: proc(t: ^testing.T) {
	EXPR :: `# Comment up here.
	^
	a
	.
	(?:bc|ad)
	e*                # A comment.
	f+
	g*?
	h+?
	i{0,1}
	j{1,2}			#Tabbed-out comment.
	k{,3}
	l{4,}
	m?
	n??
	[0-9]
	(?:oo#)     # Another comment.
	(p)
	$
# Comment down here.
`

	check_expression(t, EXPR, "a_bceeffgghhhijjklllllmn7oo#p", "a_bceeffgghhhijjklllllmn7oo#p", "p", extra_flags = { .Ignore_Whitespace })
	check_expression(t, EXPR, "a_bcffhjkkklllln9oo#p", "a_bcffhjkkklllln9oo#p", "p", extra_flags = { .Ignore_Whitespace })
}

@test
test_creation_from_user_string :: proc(t: ^testing.T) {
	{
		USER_EXPR :: `/^hellope$/gmixun-`
		STR :: "hellope"
		rex, err := regex.create_by_user(USER_EXPR)
		defer regex.destroy(rex)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, rex.flags, regex.Flags{ .Global, .Multiline, .Case_Insensitive, .Ignore_Whitespace, .Unicode, .No_Capture, .No_Optimization })

		_, ok := regex.match(rex, STR)
		testing.expectf(t, ok, "expected user-provided RegEx %v to match %q", rex, STR)
	}
	{
		USER_EXPR :: `/\/var\/log/`
		STR :: "/var/log"
		rex, err := regex.create_by_user(USER_EXPR)
		defer regex.destroy(rex)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, rex.flags, regex.Flags{})

		capture, ok := regex.match(rex, STR)
		regex.destroy(capture)
		testing.expectf(t, ok, "expected user-provided RegEx %v to match %q", rex, STR)
	}
	{
		USER_EXPR :: `@@`
		STR :: ""
		rex, err := regex.create_by_user(USER_EXPR)
		defer regex.destroy(rex)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, rex.flags, regex.Flags{})

		capture, ok := regex.match(rex, STR)
		regex.destroy(capture)
		testing.expectf(t, ok, "expected user-provided RegEx %v to match %q", rex, STR)
	}
	{
		USER_EXPR :: `ほほ-`
		STR :: ""
		rex, err := regex.create_by_user(USER_EXPR)
		defer regex.destroy(rex)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, rex.flags, regex.Flags{ .No_Optimization })

		capture, ok := regex.match(rex, STR)
		regex.destroy(capture)
		testing.expectf(t, ok, "expected user-provided RegEx %v to match %q", rex, STR)
	}
	{
		USER_EXPR :: `ほ\ほほu`
		STR :: "ほ"
		rex, err := regex.create_by_user(USER_EXPR)
		defer regex.destroy(rex)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, rex.flags, regex.Flags{ .Unicode })

		capture, ok := regex.match(rex, STR)
		regex.destroy(capture)
		testing.expectf(t, ok, "expected user-provided RegEx %v to match %q", rex, STR)
	}
	{
		USER_EXPR :: `ふわふu`
		STR :: "わ"
		rex, err := regex.create_by_user(USER_EXPR)
		defer regex.destroy(rex)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, rex.flags, regex.Flags{ .Unicode })

		capture, ok := regex.match(rex, STR)
		regex.destroy(capture)
		testing.expectf(t, ok, "expected user-provided RegEx %v to match %q", rex, STR)
	}
	{
		USER_EXPR :: `なに`
		_, err := regex.create_by_user(USER_EXPR)
		testing.expect_value(t, err, regex.Creation_Error.Expected_Delimiter)
	}
	{
		USER_EXPR :: `\o/`
		_, err := regex.create_by_user(USER_EXPR)
		testing.expect_value(t, err, regex.Creation_Error.Bad_Delimiter)
	}
	{
		USER_EXPR :: `<=)<-<a`
		_, err := regex.create_by_user(USER_EXPR)
		testing.expect_value(t, err, regex.Creation_Error.Unknown_Flag)
	}
}



// NOTE(Feoramund): The following are patterns I found out in the wild to test
// coverage of how people might use RegEx.

@test
test_email_simple :: proc(t: ^testing.T) {
	// Source: https://stackoverflow.com/a/50343015
	EXPR :: `^[^@]+@[^@]+\.[^@]+$`
	check_expression(t, EXPR, "bill@gingerbill.org", "bill@gingerbill.org")
	check_expression(t, EXPR, "@not-an-email.com")
}

@test
test_email_absurd :: proc(t: ^testing.T) {
	// This is why you shouldn't use RegEx to parse rule-laden text.
	// Source: https://emailregex.com/
	EXPR :: `(?:[a-z0-9!#$%&'*+/=?^_` + "`" + `{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_` + "`" + `{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])`
	check_expression(t, EXPR, "bill@gingerbill.org", "bill@gingerbill.org")
	check_expression(t, EXPR, "@not-their own- typeemail.com") }

@test
test_uri_partition :: proc(t: ^testing.T) {
	// Source: https://www.rfc-editor.org/rfc/rfc3986#appendix-B
	EXPR :: `^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?`
	check_expression(t, EXPR, "https://odin-lang.org/",
		"https://odin-lang.org/",
		"https:",
		"https",
		"//odin-lang.org",
		"odin-lang.org",
		"/")
}

@test
test_ipv4 :: proc(t: ^testing.T) {
	// Source: https://www.regular-expressions.info/ip.html
	EXPR :: `\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.
	         (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.
	         (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.
	         (25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b`
	check_expression(t, EXPR, "127.0.0.1", "127.0.0.1", "127", "0", "0", "1", extra_flags = { .Ignore_Whitespace })
	check_expression(t, EXPR, "9.9.9.9", "9.9.9.9", "9", "9", "9", "9", extra_flags = { .Ignore_Whitespace })
}

@test
test_floating_point :: proc(t: ^testing.T) {
	// Source: https://www.regular-expressions.info/floatingpoint.html
	EXPR :: `[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?`
	check_expression(t, EXPR, "-3.14", "-3.14")
	check_expression(t, EXPR, "2.17", "2.17")
	check_expression(t, EXPR, "1e9", "1e9", "e9")
}

@test
test_uk_postal_code :: proc(t: ^testing.T) {
	// Source: https://www.html5pattern.com/Postal_Codes
	EXPR :: `[A-Za-z]{1,2}[0-9Rr][0-9A-Za-z]? [0-9][ABD-HJLNP-UW-Zabd-hjlnp-uw-z]{2}`
	check_expression(t, EXPR, "EC1A 1BB", "EC1A 1BB")
}

@test
test_us_phone_number :: proc(t: ^testing.T) {
	// Source: https://regexlib.com/REDetails.aspx?regexp_id=22
	EXPR :: `^[2-9]\d{2}-\d{3}-\d{4}$`
	check_expression(t, EXPR, "650-253-0001", "650-253-0001")
}

@test
test_preallocated_capture :: proc(t: ^testing.T) {
	capture := regex.preallocate_capture()
	defer regex.destroy(capture)

	for pos in capture.pos {
		testing.expect_value(t, pos, [2]int{0, 0})
	}
	for group in capture.groups {
		testing.expect_value(t, group, "")
	}

	rex, parse_err := regex.create(`f(o)ob(ar)`)
	if !testing.expect_value(t, parse_err, nil) {
		return
	}
	defer regex.destroy(rex)

	num_groups, success := regex.match_with_preallocated_capture(rex, "foobar", &capture)
	testing.expect_value(t, num_groups, 3)
	testing.expect_value(t, success, true)

	testing.expect_value(t, capture.pos[0], [2]int{0, 6})
	testing.expect_value(t, capture.pos[1], [2]int{1, 2})
	testing.expect_value(t, capture.pos[2], [2]int{4, 6})
	for pos in capture.pos[3:] {
		testing.expect_value(t, pos, [2]int{0, 0})
	}

	testing.expect_value(t, capture.groups[0], "foobar")
	testing.expect_value(t, capture.groups[1], "o")
	testing.expect_value(t, capture.groups[2], "ar")
	for groups in capture.groups[3:] {
		testing.expect_value(t, groups, "")
	}
}
