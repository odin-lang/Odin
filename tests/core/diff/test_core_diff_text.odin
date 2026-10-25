package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:unicode"
import "core:unicode/utf8"

/*
	Harness
*/

// Lines split with `core:strings`, independently of `core:diff`'s tokeniser.
split_lines :: proc(s: string, allocator := context.temp_allocator) -> []string {
	lines := strings.split_after(s, "\n", allocator)
	if len(lines) > 0 && lines[len(lines) - 1] == "" {
		return lines[:len(lines) - 1]
	}
	return lines
}

/*
	Applies `flags` to one line the long way: an independent version of what `diff_text` must treat as equal.
	Case folding uses `strings.to_lower`, which agrees with simple folding on ASCII.
*/
normalize_line :: proc(line: string, flags: diff.Text_Flags, allocator := context.temp_allocator) -> string {
	body, newline := line, ""
	if strings.has_suffix(body, "\n") {
		body, newline = body[:len(body) - 1], "\n"
		if .Ignore_CR in flags && strings.has_suffix(body, "\r") {
			body = body[:len(body) - 1]
		}
	}
	if flags & {.Ignore_Trailing_Space, .Ignore_All_Space} != {} {
		body = strings.trim_right_proc(body, unicode.is_space)
	}
	if .Ignore_All_Space in flags {
		b := strings.builder_make(allocator)
		for r in body {
			if !unicode.is_space(r) {
				strings.write_rune(&b, r)
			}
		}
		body = strings.to_string(b)
	}
	if .Ignore_Case in flags {
		body = strings.to_lower(body, allocator)
	}
	return strings.concatenate({body, newline}, allocator)
}

// `diff_text` must give exactly the bits of a generic diff of the lines, normalised the long way.
check_text_matches_lines :: proc(t: ^testing.T, a, b: string, flags: diff.Text_Flags, opts := diff.Options{}, loc := #caller_location) -> bool {
	d := must(diff.diff_text(a, b, context.allocator, context.allocator, flags = flags, opts = opts))
	defer diff.text_diff_destroy(d, context.allocator)

	lines_a := split_lines(a)
	lines_b := split_lines(b)
	for &line in lines_a {
		line = normalize_line(line, flags)
	}
	for &line in lines_b {
		line = normalize_line(line, flags)
	}

	expected := must(diff.diff(lines_a, lines_b, context.allocator, context.allocator, opts = opts))
	defer diff.changes_destroy(expected, context.allocator)
	testing.expectf(t, slice.equal(d.changes.bits, expected.bits), "%v: diff_text differs from diffing the lines (a = %q, b = %q)", flags, a, b, loc = loc) or_return
	return check_spans(t, d, flags == {}, loc)
}

/*
	Spans cover the text in whole tokens: the `.Equal` and `.Delete` spans rebuild `a`, and when nothing is ignored
	the `.Equal` and `.Insert` spans rebuild `b`.
*/
check_spans :: proc(t: ^testing.T, d: diff.Text_Diff, exact: bool, loc := #caller_location) -> bool {
	rebuilt_a := strings.builder_make(context.temp_allocator)
	rebuilt_b := strings.builder_make(context.temp_allocator)
	spans := 0

	it := diff.span_iterator_make(d)
	for s in diff.span_iterate(&it) {
		testing.expectf(t, len(s.text) > 0, "span %d is empty", spans, loc = loc) or_return
		switch s.op {
		case .Equal:
			strings.write_string(&rebuilt_a, s.text)
			strings.write_string(&rebuilt_b, s.text)
		case .Delete:
			strings.write_string(&rebuilt_a, s.text)
		case .Insert:
			strings.write_string(&rebuilt_b, s.text)
		}
		spans += 1
	}
	testing.expect_value(t, spans, diff.edit_count(d.changes), loc = loc) or_return
	testing.expectf(t, strings.to_string(rebuilt_a) == d.a, "spans rebuild a as %q, not %q", strings.to_string(rebuilt_a), d.a, loc = loc) or_return
	if exact {
		testing.expectf(t, strings.to_string(rebuilt_b) == d.b, "spans rebuild b as %q, not %q", strings.to_string(rebuilt_b), d.b, loc = loc) or_return
	}
	return true
}

collect_spans :: proc(d: diff.Text_Diff) -> [dynamic]diff.Span {
	spans: [dynamic]diff.Span
	it := diff.span_iterator_make(d)
	for s in diff.span_iterate(&it) {
		append(&spans, s)
	}
	return spans
}

expect_text_stats :: proc(t: ^testing.T, a, b: string, token: diff.Token, flags: diff.Text_Flags, expected: diff.Stats, loc := #caller_location) {
	d := must(diff.diff_text(a, b, context.allocator, context.allocator, token = token, flags = flags))
	defer diff.text_diff_destroy(d, context.allocator)
	testing.expectf(t, diff.stats(d.changes) == expected, "%v %v: %q against %q gave %v, expected %v", token, flags, a, b, diff.stats(d.changes), expected, loc = loc)
}

/*
	The tokens of `s` split the long way, decoding rune by rune and classing each with `core:unicode`,
	independently of the tokeniser's ASCII fast paths. Invalid UTF-8 decodes as one rune per byte.
*/
reference_tokens :: proc(s: string, token: diff.Token, allocator := context.temp_allocator) -> []string {
	Class :: enum {Other, Word, Space}
	class_of :: proc(r: rune) -> Class {
		switch {
		case r == '_' || unicode.is_letter(r) || unicode.is_digit(r):
			return .Word
		case unicode.is_space(r):
			return .Space
		}
		return .Other
	}

	tokens := make([dynamic]string, allocator)
	start := 0
	prev  := Class.Other
	for pos := 0; pos < len(s); /**/ {
		r, width := utf8.decode_rune_in_string(s[pos:])
		class := class_of(r)
		if pos > start && (token == .Rune || class == .Other || class != prev) {
			append(&tokens, s[start:pos])
			start = pos
		}
		prev = class
		pos += width
	}
	if start < len(s) {
		append(&tokens, s[start:])
	}
	return tokens[:]
}

// Interns the tokens of both sides, for comparing against `lcs_length`.
intern_tokens :: proc(a, b: []string, allocator := context.temp_allocator) -> (x, y: []i32) {
	ids := make(map[string]i32, allocator)
	x = make([]i32, len(a), allocator)
	y = make([]i32, len(b), allocator)
	for token, k in a {
		x[k] = ids[token] or_else i32(len(ids))
		ids[token] = x[k]
	}
	for token, k in b {
		y[k] = ids[token] or_else i32(len(ids))
		ids[token] = y[k]
	}
	return
}

// ASCII and not, words, spaces and punctuation, and invalid UTF-8, including a sequence cut short.
@(rodata)
TOKEN_PIECES := [?]string{
	"a", "Z", "_", "7", "foo", ",", "(", " ", "  ", "\t", "\r", "\n",
	"é", "ж", "日", "€", "😀", "\u00a0", "\u2003", "\u0085", "\xff", "\x80", "\xe2\x82",
}

random_pieces :: proc(count: int, allocator := context.temp_allocator) -> string {
	b := strings.builder_make(allocator)
	for _ in 0..<count {
		strings.write_string(&b, TOKEN_PIECES[rand.int_max(len(TOKEN_PIECES))])
	}
	return strings.to_string(b)
}

@(rodata)
LINE_PIECES := [?]string{"a", "A", "b", "bB", "foo", " ", "  ", "\t", "\r", "x y"}

// Random lines of pieces that differ only in case and whitespace, so the flags have plenty to ignore.
random_text :: proc(lines: int, allocator := context.temp_allocator) -> string {
	b := strings.builder_make(allocator)
	for k in 0..<lines {
		for _ in 0..<rand.int_max(4) {
			strings.write_string(&b, LINE_PIECES[rand.int_max(len(LINE_PIECES))])
		}
		if k < lines - 1 || rand.int_max(2) == 0 {
			strings.write_byte(&b, '\n')
		}
	}
	return strings.to_string(b)
}

// Replaces, inserts and removes whole lines.
mutate_lines :: proc(s: string, edits: int, allocator := context.temp_allocator) -> string {
	lines := make([dynamic]string, context.temp_allocator)
	append(&lines, ..split_lines(s))
	for _ in 0..<edits {
		switch rand.int_max(3) {
		case 0:
			inject_at(&lines, rand.int_max(len(lines) + 1), random_text(1, allocator))
		case 1:
			if len(lines) > 0 {
				ordered_remove(&lines, rand.int_max(len(lines)))
			}
		case 2:
			if len(lines) > 0 {
				lines[rand.int_max(len(lines))] = random_text(1, allocator)
			}
		}
	}
	// Every line but the last needs its "\n" back, wherever it moved to
	b := strings.builder_make(allocator)
	for line, k in lines {
		strings.write_string(&b, line)
		if k < len(lines) - 1 && !strings.has_suffix(line, "\n") {
			strings.write_byte(&b, '\n')
		}
	}
	return strings.to_string(b)
}

@(rodata)
ALL_FLAG_SETS := [?]diff.Text_Flags{
	{},
	{.Ignore_CR},
	{.Ignore_Trailing_Space},
	{.Ignore_All_Space},
	{.Ignore_Case},
	{.Ignore_CR, .Ignore_Case},
	{.Ignore_Trailing_Space, .Ignore_Case},
	{.Ignore_CR, .Ignore_Trailing_Space, .Ignore_All_Space, .Ignore_Case},
}


/*
	Tests
*/

@(test)
test_token_count :: proc(t: ^testing.T) {
	Case :: struct {
		s:                  string,
		lines, words, runes: int,
	}
	cases := []Case{
		{"",                     0, 0, 0},
		{"\n",                   1, 1, 1},
		{"a",                    1, 1, 1},
		{"a\n",                  1, 2, 2},
		{"a\r\n",                1, 2, 3},
		{"a\n\n",                2, 2, 3},
		{"a\nb",                 2, 3, 3},
		{"hello, world",         1, 4, 12},
		{"foo_bar 123  baz",     1, 5, 16},
		{"héllo wörld",          1, 3, 11},
		{"aé€😀",                1, 3, 4},
		{"x\xff\xfey",           1, 4, 4},
		{"tab\tnew\r\nline\n",   2, 6, 14},
	}
	for c in cases {
		testing.expectf(t, diff.token_count(c.s, .Line) == c.lines, "%q: %d lines, expected %d", c.s, diff.token_count(c.s, .Line), c.lines)
		testing.expectf(t, diff.token_count(c.s, .Word) == c.words, "%q: %d words, expected %d", c.s, diff.token_count(c.s, .Word), c.words)
		testing.expectf(t, diff.token_count(c.s, .Rune) == c.runes, "%q: %d runes, expected %d", c.s, diff.token_count(c.s, .Rune), c.runes)
	}
}

// Words and runes must split as decoding rune by rune does, both to count them and to diff them.
@(test)
test_tokens_random :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<300 {
		a := random_pieces(rand.int_max(40))
		b := random_pieces(rand.int_max(40))
		for token in ([]diff.Token{.Word, .Rune}) {
			tokens_a := reference_tokens(a, token)
			tokens_b := reference_tokens(b, token)
			if !testing.expectf(t, diff.token_count(a, token) == len(tokens_a), "%v: %q counts %d, expected %d", token, a, diff.token_count(a, token), len(tokens_a)) {
				return
			}

			// Being minimal, the diff only comes out as small as expected with the same tokens
			d := must(diff.diff_text(a, b, context.allocator, context.allocator, token = token, opts = {algorithm = .Minimal}))
			defer diff.text_diff_destroy(d, context.allocator)
			x, y := intern_tokens(tokens_a, tokens_b)
			got, expected := cost(d.changes), len(x) + len(y) - 2*lcs_length(x, y)
			if !testing.expectf(t, got == expected, "%v: %q against %q changes %d tokens, expected %d", token, a, b, got, expected) || !check_spans(t, d, true) {
				return
			}
		}
	}
}

@(test)
test_text_lines :: proc(t: ^testing.T) {
	cases := [][2]string{
		{"", ""},
		{"", "a\n"},
		{"a\n", ""},
		{"a\nb\nc\n", "a\nb\nc\n"},
		{"a\nb\nc\n", "a\nB\nc\n"},
		{"a\nb\nc", "a\nb\nc\n"},
		{"a\r\nb\r\n", "a\nb\n"},
		{"one\ntwo\nthree\n", "zero\none\nthree\nfour"},
	}
	for c in cases {
		check_text_matches_lines(t, c[0], c[1], {})
	}
}

@(test)
test_text_random :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<150 {
		a := random_text(rand.int_max(60))
		b := mutate_lines(a, rand.int_max(15))
		for flags in ALL_FLAG_SETS {
			if !check_text_matches_lines(t, a, b, flags) {
				return
			}
		}
	}
}

@(test)
test_text_flags :: proc(t: ^testing.T) {
	// A final "\n" is never ignored
	expect_text_stats(t, "a\n", "a", .Line, {.Ignore_All_Space}, {deleted = 1, inserted = 1})
	expect_text_stats(t, "a  ", "a\n", .Line, {.Ignore_Trailing_Space}, {deleted = 1, inserted = 1})
	expect_text_stats(t, "a  ", "a", .Line, {.Ignore_Trailing_Space}, {equal = 1})

	// Only a "\r" right before the "\n"
	expect_text_stats(t, "a\r\nb\r\n", "a\nb\n", .Line, {.Ignore_CR}, {equal = 2})
	expect_text_stats(t, "a\r\nb\r\n", "a\nb\n", .Line, {}, {deleted = 2, inserted = 2})
	expect_text_stats(t, "a\rb\n", "ab\n", .Line, {.Ignore_CR}, {deleted = 1, inserted = 1})

	// Trailing against all whitespace
	expect_text_stats(t, "a b \t\n", "a b\n", .Line, {.Ignore_Trailing_Space}, {equal = 1})
	expect_text_stats(t, "a b\n", "ab\n", .Line, {.Ignore_Trailing_Space}, {deleted = 1, inserted = 1})
	expect_text_stats(t, "a b\n", "ab\n", .Line, {.Ignore_All_Space}, {equal = 1})
	expect_text_stats(t, "\t\n", "\n", .Line, {.Ignore_All_Space}, {equal = 1})

	// Simple case folding, beyond ASCII
	expect_text_stats(t, "Hello\n", "hELLO\n", .Line, {.Ignore_Case}, {equal = 1})
	expect_text_stats(t, "K\n", "k\n", .Line, {.Ignore_Case}, {equal = 1}) // Kelvin sign
	expect_text_stats(t, "ſ\n", "S\n", .Line, {.Ignore_Case}, {equal = 1}) // long s
	expect_text_stats(t, "ΣΑΣ\n", "σας\n", .Line, {.Ignore_Case}, {equal = 1}) // final sigma is a simple fold of Σ
	expect_text_stats(t, "ß\n", "ss\n", .Line, {.Ignore_Case}, {deleted = 1, inserted = 1}) // but "ss" is only a full fold of ß

	// Flags apply to words and runes too
	expect_text_stats(t, "The  quick", "the quick", .Word, {.Ignore_Case, .Ignore_All_Space}, {equal = 3})
	expect_text_stats(t, "aBc", "AbC", .Rune, {.Ignore_Case}, {equal = 3})
}

@(test)
test_text_words :: proc(t: ^testing.T) {
	d := must(diff.diff_text("the quick brown fox", "the slow brown fox", context.allocator, context.allocator, token = .Word))
	defer diff.text_diff_destroy(d, context.allocator)
	spans := collect_spans(d)
	defer delete(spans)

	expected := []diff.Span{
		{.Equal,  "the "},
		{.Delete, "quick"},
		{.Insert, "slow"},
		{.Equal,  " brown fox"},
	}
	testing.expectf(t, slice.equal(spans[:], expected), "spans %v, expected %v", spans, expected)
	check_spans(t, d, true)
}

@(test)
test_text_runes :: proc(t: ^testing.T) {
	d := must(diff.diff_text("naïve 😀 x\xff", "naive 😀 y\xff", context.allocator, context.allocator, token = .Rune))
	defer diff.text_diff_destroy(d, context.allocator)
	spans := collect_spans(d)
	defer delete(spans)

	expected := []diff.Span{
		{.Equal,  "na"},
		{.Delete, "ï"},
		{.Insert, "i"},
		{.Equal,  "ve 😀 "},
		{.Delete, "x"},
		{.Insert, "y"},
		{.Equal,  "\xff"},
	}
	testing.expectf(t, slice.equal(spans[:], expected), "spans %v, expected %v", spans, expected)
	check_spans(t, d, true)
}

@(test)
test_text_large :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_text(5_000)
	b := mutate_lines(a, 200)
	check_text_matches_lines(t, a, b, {})
	check_text_matches_lines(t, a, b, {.Ignore_All_Space, .Ignore_Case})
	check_text_matches_lines(t, a, b, {}, {algorithm = .Minimal})
}

// Scratch of exactly `scratch_size_text` bytes must work at every alignment, for every kind of token.
@(test)
test_text_scratch_alignment :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_text(200)
	b := mutate_lines(a, 30)

	for token in diff.Token {
		n, m := diff.token_count(a, token), diff.token_count(b, token)
		size := diff.scratch_size_text(n, m)
		buf  := make([]byte, size + 16)
		defer delete(buf)

		expected := must(diff.diff_text(a, b, context.allocator, context.allocator, token = token))
		defer diff.text_diff_destroy(expected, context.allocator)
		for offset in 0..<16 {
			c := must(diff.changes_make(n, m, context.allocator))
			defer diff.changes_destroy(c, context.allocator)
			d := diff.diff_text_buffer(a, b, c, buf[offset:][:size], token)
			testing.expectf(t, slice.equal(d.changes.bits, expected.changes.bits), "%v at offset %d differs", token, offset)
		}
	}
}

@(test)
test_text_allocations :: proc(t: ^testing.T) {
	result    := Counting_Allocator{backing = context.allocator}
	transient := Counting_Allocator{backing = context.allocator}

	d := must(diff.diff_text("a\nb\nc\n", "a\nc\nd\n", counting_allocator(&result), counting_allocator(&transient)))
	testing.expect_value(t, result.allocs, 1)
	testing.expect_value(t, transient.allocs, 1)
	testing.expect_value(t, transient.frees, 1)
	testing.expect_value(t, diff.stats(d.changes), diff.Stats{equal = 2, deleted = 1, inserted = 1})
	diff.text_diff_destroy(d, counting_allocator(&result))
	testing.expect_value(t, result.frees, 1)
}
