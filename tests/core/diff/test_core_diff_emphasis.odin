package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:strings"
import "core:testing"

/*
	Harness
*/

// Brackets instead of escape codes: no colour for whole lines, "[" ... "]" around the emphasised part.
MARKERS :: diff.Style{
	delete_emphasis = "[",
	insert_emphasis = "[",
	reset           = "]",
}

// Diffs with emphasis, giving `.Words` exactly the scratch it asks for.
emphasised :: proc(a, b: string, emphasis: diff.Emphasis, style := MARKERS, context_len := diff.DEFAULT_CONTEXT_LEN, allocator := context.temp_allocator) -> string {
	d := must(diff.diff_text(a, b, context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	scratch := make([]byte, diff.emphasis_scratch_size(d, emphasis), allocator)
	return must(diff.unified(d, allocator, context_len = context_len, style = style, emphasis = emphasis, scratch = scratch))
}

expect_emphasis :: proc(t: ^testing.T, a, b: string, emphasis: diff.Emphasis, expected: string, style := MARKERS, loc := #caller_location) {
	s := emphasised(a, b, emphasis, style)
	testing.expectf(t, s == expected, "%v: got:\n%s\nexpected:\n%s", emphasis, s, expected, loc = loc)
}

/*
	Emphasis only adds markers: taking them out must give the plain output, and every way
	of writing the output must agree on its size.
*/
check_emphasis :: proc(t: ^testing.T, a, b: string, emphasis: diff.Emphasis, context_len: int, loc := #caller_location) -> bool {
	d := must(diff.diff_text(a, b, context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	scratch := make([]byte, diff.emphasis_scratch_size(d, emphasis), context.temp_allocator)
	marked  := must(diff.unified(d, context.temp_allocator, context_len = context_len, style = MARKERS, emphasis = emphasis, scratch = scratch))
	plain   := must(diff.unified(d, context.temp_allocator, context_len = context_len))

	size := diff.unified_size(d, context_len = context_len, style = MARKERS, emphasis = emphasis, scratch = scratch)
	testing.expect_value(t, size, len(marked), loc = loc) or_return

	grown := must(diff.unified(d, context.temp_allocator, context_len = context_len, style = MARKERS, emphasis = emphasis, scratch = scratch, sizing = .Grow))
	testing.expect_value(t, grown, marked, loc = loc) or_return

	stripped, _ := strings.remove_all(marked, "[", context.temp_allocator)
	stripped, _  = strings.remove_all(stripped, "]", context.temp_allocator)
	return testing.expectf(t, stripped == plain, "%v: without its markers:\n%s\nis not:\n%s", emphasis, stripped, plain, loc = loc)
}


/*
	Tests
*/

@(test)
test_emphasis_prefix_suffix :: proc(t: ^testing.T) {
	expect_emphasis(t, "x\nhello world\ny\n", "x\nhello there\ny\n", .Prefix_Suffix,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,3 +1,3 @@\n" +
		" x\n" +
		"-hello [world]\n" +
		"+hello [there]\n" +
		" y\n")

	// Something inserted in the middle of a line: only the new part is marked
	expect_emphasis(t, "abc\n", "abXc\n", .Prefix_Suffix,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-abc\n" +
		"+ab[X]c\n")

	// Pairs need as many lines on each side
	expect_emphasis(t, "ab\ncd\n", "aX\n", .Prefix_Suffix,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,2 +1 @@\n" +
		"-ab\n" +
		"-cd\n" +
		"+aX\n")

	// Nothing in common, nothing marked
	expect_emphasis(t, "abc\n", "xyz\n", .Prefix_Suffix,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-abc\n" +
		"+xyz\n")
}

// A common prefix or suffix never splits a rune.
@(test)
test_emphasis_runes :: proc(t: ^testing.T) {
	expect_emphasis(t, "naïve\n", "naive\n", .Prefix_Suffix,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-na[ï]ve\n" +
		"+na[i]ve\n")

	// "é" and "è" share their first byte, which is not a rune of its own
	expect_emphasis(t, "aé\n", "aè\n", .Prefix_Suffix,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-a[é]\n" +
		"+a[è]\n")
}

@(test)
test_emphasis_words :: proc(t: ^testing.T) {
	expect_emphasis(t, "the quick brown fox\n", "the slow brown fox\n", .Words,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-the [quick] brown fox\n" +
		"+the [slow] brown fox\n")

	// Words are diffed across the whole block, whatever the line counts
	expect_emphasis(t, "foo bar\nbaz qux\n", "foo BAR\nbaz qux quux\n", .Words,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,2 +1,2 @@\n" +
		"-foo [bar]\n" +
		"-baz qux\n" +
		"+foo [BAR]\n" +
		"+baz qux[ quux]\n")

	// A changed word of whitespace can hold a line break, which is never shown
	expect_emphasis(t, "one two\n", "one\ntwo\n", .Words,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1,2 @@\n" +
		"-one[ ]two\n" +
		"+one\n" +
		"+two\n")

	// Nothing in common, nothing marked
	expect_emphasis(t, "abc\n", "xyz\n", .Words,
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-abc\n" +
		"+xyz\n")
}

@(test)
test_emphasis_ansi :: proc(t: ^testing.T) {
	expect_emphasis(t, "hello world!\n", "hello there!\n", .Prefix_Suffix, style = diff.STYLE_ANSI, expected =
		"\x1b[1m--- a\x1b[0m\n" +
		"\x1b[1m+++ b\x1b[0m\n" +
		"\x1b[36m@@ -1 +1 @@\x1b[0m\n" +
		"\x1b[31m-hello \x1b[31;7mworld\x1b[0m\x1b[31m!\x1b[0m\n" +
		"\x1b[32m+hello \x1b[32;7mthere\x1b[0m\x1b[32m!\x1b[0m\n")
}

// Without emphasis colours there is nothing to show, meaning no scratch is needed either.
@(test)
test_emphasis_without_colours :: proc(t: ^testing.T) {
	d := must(diff.diff_text("the quick fox\n", "the slow fox\n", context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	plain := must(diff.unified(d, context.allocator))
	defer delete(plain)
	for emphasis in diff.Emphasis {
		s := must(diff.unified(d, context.allocator, emphasis = emphasis))
		defer delete(s)
		testing.expectf(t, s == plain, "%v without colours changed the output", emphasis)
	}
}

@(test)
test_emphasis_scratch_size :: proc(t: ^testing.T) {
	d := must(diff.diff_text("same\nthe quick fox\nsame\nab\n", "same\nthe slow fox\nsame\nxy\nzz\n", context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	testing.expect_value(t, diff.emphasis_scratch_size(d, .None), 0)
	testing.expect_value(t, diff.emphasis_scratch_size(d, .Prefix_Suffix), 0)

	// Exactly the size asked for, at every alignment
	size := diff.emphasis_scratch_size(d, .Words)
	testing.expect(t, size > 0, "a diff with changes asked for no scratch")
	buf := make([]byte, size + 16)
	defer delete(buf)

	expected := emphasised(d.a, d.b, .Words)
	for offset in 0..<16 {
		s := must(diff.unified(d, context.temp_allocator, style = MARKERS, emphasis = .Words, scratch = buf[offset:][:size]))
		testing.expectf(t, s == expected, "offset %d gave:\n%s", offset, s)
	}

	// Only insertions, or no changes at all: nothing to diff words of
	only_inserts := must(diff.diff_text("a\n", "a\nb\n", context.allocator, context.allocator))
	defer diff.text_diff_destroy(only_inserts, context.allocator)
	testing.expect_value(t, diff.emphasis_scratch_size(only_inserts, .Words), 0)
}

@(test)
test_emphasis_random :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<150 {
		a := random_text(rand.int_max(60))
		b := mutate_lines(a, rand.int_max(15))
		for emphasis in ([?]diff.Emphasis{.Prefix_Suffix, .Words}) {
			for context_len in ([?]int{0, 3}) {
				if !check_emphasis(t, a, b, emphasis, context_len) {
					return
				}
			}
		}
	}
}
