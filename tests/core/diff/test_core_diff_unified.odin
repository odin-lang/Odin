package test_core_diff

import "core:diff"
import "core:io"
import "core:math/rand"
import "core:mem"
import "core:strconv"
import "core:strings"
import "core:testing"

/*
	Harness
*/

// Parses "start[,count]".
parse_range :: proc(s: string) -> (lo, count: int, ok: bool) {
	start_text, _, count_text := strings.partition(s, ",")
	start := strconv.parse_int(start_text, 10) or_return
	count = 1
	if count_text != "" {
		count = strconv.parse_int(count_text, 10) or_return
	}
	// An empty range starts at the line before it
	lo = count == 0 ? start : start - 1
	return lo, count, true
}

/*
	Applies a unified diff to `a` the simple way, checking as it goes that every context and deleted line
	matches `a`, that the hunk headers agree with the lines under them, and that hunks are in order.
*/
apply_unified :: proc(t: ^testing.T, a, patch: string, loc := #caller_location) -> (b: string, ok: bool) {
	if patch == "" {
		return a, true
	}
	lines_a := split_lines(a)
	p := split_lines(patch)
	testing.expectf(t, len(p) >= 2 && strings.has_prefix(p[0], "--- ") && strings.has_prefix(p[1], "+++ "), "bad file headers in %q", patch, loc = loc) or_return

	out := strings.builder_make(context.temp_allocator)
	out_lines := 0
	ai := 0
	k := 2
	for k < len(p) {
		header := strings.trim_suffix(p[k], "\n")
		testing.expectf(t, strings.has_prefix(header, "@@ -") && strings.has_suffix(header, " @@"), "bad hunk header %q", header, loc = loc) or_return
		ranges := header[len("@@ -"):len(header) - len(" @@")]
		a_text, _, b_text := strings.partition(ranges, " +")
		a_lo, a_count, a_ok := parse_range(a_text)
		b_lo, b_count, b_ok := parse_range(b_text)
		testing.expectf(t, a_ok && b_ok, "bad ranges in %q", header, loc = loc) or_return
		testing.expectf(t, a_lo >= ai, "hunk %q goes back to line %d", header, ai, loc = loc) or_return

		for ai < a_lo {
			strings.write_string(&out, lines_a[ai])
			ai += 1
			out_lines += 1
		}
		testing.expectf(t, out_lines == b_lo, "hunk %q starts at b line %d, not %d", header, out_lines, b_lo, loc = loc) or_return

		k += 1
		seen_a, seen_b := 0, 0
		for k < len(p) && !strings.has_prefix(p[k], "@@") {
			line := p[k]
			body := line[1:]
			if k + 1 < len(p) && strings.has_prefix(p[k + 1], "\\ No newline at end of file") {
				body = strings.trim_suffix(body, "\n")
				k += 1
			}
			switch line[0] {
			case ' ', '-':
				testing.expectf(t, ai < len(lines_a) && lines_a[ai] == body, "line %q does not match a[%d]", line, ai, loc = loc) or_return
				if line[0] == ' ' {
					strings.write_string(&out, body)
					out_lines += 1
					seen_b += 1
				}
				ai += 1
				seen_a += 1
			case '+':
				strings.write_string(&out, body)
				out_lines += 1
				seen_b += 1
			case:
				testing.expectf(t, false, "bad patch line %q", line, loc = loc) or_return
			}
			k += 1
		}
		testing.expectf(t, seen_a == a_count && seen_b == b_count, "hunk %q holds %d and %d lines", header, seen_a, seen_b, loc = loc) or_return
	}
	for ai < len(lines_a) {
		strings.write_string(&out, lines_a[ai])
		ai += 1
	}
	return strings.to_string(out), true
}

// The line numbers and text the iterator gives must match the lines of `a` and `b`.
check_unified_lines :: proc(t: ^testing.T, d: diff.Text_Diff, context_len: int, loc := #caller_location) -> bool {
	lines_a := split_lines(d.a)
	lines_b := split_lines(d.b)
	it := diff.unified_iterator_make(d, context_len)
	for line in diff.unified_iterate(&it) {
		if line.a_line > 0 {
			testing.expectf(t, strings.trim_suffix(lines_a[line.a_line - 1], "\n") == line.text, "%v is not a line %d", line, line.a_line, loc = loc) or_return
		}
		if line.b_line > 0 && line.kind == .Insert {
			testing.expectf(t, strings.trim_suffix(lines_b[line.b_line - 1], "\n") == line.text, "%v is not b line %d", line, line.b_line, loc = loc) or_return
		}
		switch line.kind {
		case .Equal:
			testing.expectf(t, line.a_line > 0 && line.b_line > 0, "%v lacks a line number", line, loc = loc) or_return
		case .Delete:
			testing.expectf(t, line.a_line > 0 && line.b_line == 0, "%v has the wrong line numbers", line, loc = loc) or_return
		case .Insert:
			testing.expectf(t, line.a_line == 0 && line.b_line > 0, "%v has the wrong line numbers", line, loc = loc) or_return
		case .Hunk_Header, .No_Newline:
			testing.expectf(t, line.a_line == 0 && line.b_line == 0 && line.text == "", "%v should carry no line", line, loc = loc) or_return
		}
	}
	return true
}

// Every way of producing the output must agree, and applying it to `a` must give `b`.
check_unified :: proc(t: ^testing.T, a, b: string, context_len: int, flags := diff.Text_Flags{}, loc := #caller_location) -> bool {
	d := must(diff.diff_text(a, b, context.allocator, context.allocator, flags = flags))
	defer diff.text_diff_destroy(d, context.allocator)

	s := must(diff.unified(d, context.allocator, context_len = context_len))
	defer delete(s)
	testing.expect_value(t, diff.unified_size(d, context_len = context_len), len(s), loc = loc) or_return

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	testing.expect_value(t, diff.write_unified_to_builder(&sb, d, context_len = context_len), nil, loc = loc) or_return
	testing.expect_value(t, strings.to_string(sb), s, loc = loc) or_return
	testing.expect_value(t, cap(sb.buf), len(s), loc = loc) or_return

	// Growing as it writes gives the same, fitted to it
	grown := must(diff.unified(d, context.allocator, context_len = context_len, sizing = .Grow))
	defer delete(grown)
	testing.expect_value(t, grown, s, loc = loc) or_return

	grown_sb := strings.builder_make()
	defer strings.builder_destroy(&grown_sb)
	testing.expect_value(t, diff.write_unified_to_builder(&grown_sb, d, context_len = context_len, sizing = .Grow), nil, loc = loc) or_return
	testing.expect_value(t, strings.to_string(grown_sb), s, loc = loc) or_return

	check_unified_lines(t, d, context_len, loc) or_return

	rebuilt := apply_unified(t, a, s, loc) or_return
	if flags == {} {
		testing.expectf(t, rebuilt == b, "patch rebuilt %q, not %q, from:\n%s", rebuilt, b, s, loc = loc) or_return
	} else {
		testing.expectf(t, len(split_lines(rebuilt)) == len(split_lines(b)), "patch rebuilt %q, which does not line up with %q", rebuilt, b, loc = loc) or_return
	}
	return true
}

expect_unified :: proc(t: ^testing.T, a, b, expected: string, context_len := diff.DEFAULT_CONTEXT_LEN, a_name := "a", b_name := "b", style := diff.STYLE_NONE, loc := #caller_location) {
	d := must(diff.diff_text(a, b, context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)
	s := must(diff.unified(d, context.allocator, a_name, b_name, context_len, style))
	defer delete(s)
	testing.expectf(t, s == expected, "got:\n%s\nexpected:\n%s", s, expected, loc = loc)
}


/*
	Tests
*/

@(test)
test_unified_basic :: proc(t: ^testing.T) {
	expect_unified(t, "a\nb\nc\n", "a\nB\nc\n",
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,3 +1,3 @@\n" +
		" a\n" +
		"-b\n" +
		"+B\n" +
		" c\n")

	expect_unified(t, "a\nb\nc\n", "a\nB\nc\n", context_len = 3, a_name = "old.txt", b_name = "new.txt", expected =
		"--- old.txt\n" +
		"+++ new.txt\n" +
		"@@ -1,3 +1,3 @@\n" +
		" a\n" +
		"-b\n" +
		"+B\n" +
		" c\n")

	// No changes, no output at all
	expect_unified(t, "a\nb\n", "a\nb\n", "")
	expect_unified(t, "", "", "")
}

// An empty range starts at the line before it, and a count of 1 is left out.
@(test)
test_unified_ranges :: proc(t: ^testing.T) {
	expect_unified(t, "", "x\ny\n",
		"--- a\n" +
		"+++ b\n" +
		"@@ -0,0 +1,2 @@\n" +
		"+x\n" +
		"+y\n")

	expect_unified(t, "x\n", "",
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +0,0 @@\n" +
		"-x\n")

	expect_unified(t, "a\nb\n", "a\nx\nb\n", context_len = 0, expected =
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,0 +2 @@\n" +
		"+x\n")

	expect_unified(t, "a\nx\nb\n", "a\nb\n", context_len = 0, expected =
		"--- a\n" +
		"+++ b\n" +
		"@@ -2 +1,0 @@\n" +
		"-x\n")
}

@(test)
test_unified_no_newline :: proc(t: ^testing.T) {
	expect_unified(t, "a\nb", "a\nc",
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,2 +1,2 @@\n" +
		" a\n" +
		"-b\n" +
		"\\ No newline at end of file\n" +
		"+c\n" +
		"\\ No newline at end of file\n")

	// Adding the final newline changes the line
	expect_unified(t, "a", "a\n",
		"--- a\n" +
		"+++ b\n" +
		"@@ -1 +1 @@\n" +
		"-a\n" +
		"\\ No newline at end of file\n" +
		"+a\n")

	// A context line can lack it too
	expect_unified(t, "x\ny", "z\ny",
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,2 +1,2 @@\n" +
		"-x\n" +
		"+z\n" +
		" y\n" +
		"\\ No newline at end of file\n")
}

@(test)
test_unified_hunks :: proc(t: ^testing.T) {
	a := "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n"
	b := "1\ntwo\n3\n4\n5\n6\n7\n8\nnine\n10\n"

	// Six lines apart: separate with a context of 1, one hunk with a context of 3
	expect_unified(t, a, b, context_len = 1, expected =
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,3 +1,3 @@\n" +
		" 1\n" +
		"-2\n" +
		"+two\n" +
		" 3\n" +
		"@@ -8,3 +8,3 @@\n" +
		" 8\n" +
		"-9\n" +
		"+nine\n" +
		" 10\n")

	ONE_HUNK ::
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,10 +1,10 @@\n" +
		" 1\n" +
		"-2\n" +
		"+two\n" +
		" 3\n" +
		" 4\n" +
		" 5\n" +
		" 6\n" +
		" 7\n" +
		" 8\n" +
		"-9\n" +
		"+nine\n" +
		" 10\n"
	expect_unified(t, a, b, context_len = 3, expected = ONE_HUNK)

	// All the context there is, asked for as `max(int)`
	expect_unified(t, a, b, context_len = max(int), expected = ONE_HUNK)
}

@(test)
test_unified_style :: proc(t: ^testing.T) {
	expect_unified(t, "a\nb\nc\n", "a\nB\nc\n", style = diff.STYLE_ANSI, expected =
		"\x1b[1m--- a\x1b[0m\n" +
		"\x1b[1m+++ b\x1b[0m\n" +
		"\x1b[36m@@ -1,3 +1,3 @@\x1b[0m\n" +
		" a\n" +
		"\x1b[31m-b\x1b[0m\n" +
		"\x1b[32m+B\x1b[0m\n" +
		" c\n")
}

@(test)
test_unified_builder_appends :: proc(t: ^testing.T) {
	d := must(diff.diff_text("a\n", "b\n", context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, "header\n")
	testing.expect_value(t, diff.write_unified_to_builder(&sb, d), nil)
	testing.expect_value(t, strings.to_string(sb), "header\n--- a\n+++ b\n@@ -1 +1 @@\n-a\n+b\n")

	// A fixed buffer that is too small fails rather than writing part of the diff, however it is sized
	for sizing in diff.Sizing {
		small: [8]byte
		fixed := strings.builder_from_bytes(small[:])
		testing.expectf(t, diff.write_unified_to_builder(&fixed, d, sizing = sizing) != nil, "%v: a full fixed buffer did not fail", sizing)
		testing.expectf(t, len(fixed.buf) == 0, "%v: %d bytes were left in the fixed buffer", sizing, len(fixed.buf))
	}

	// Growing appends too
	grown := strings.builder_make()
	defer strings.builder_destroy(&grown)
	strings.write_string(&grown, "header\n")
	testing.expect_value(t, diff.write_unified_to_builder(&grown, d, sizing = .Grow), nil)
	testing.expect_value(t, strings.to_string(grown), "header\n--- a\n+++ b\n@@ -1 +1 @@\n-a\n+b\n")
}

// `.Grow` fails cleanly when the allocator runs out partway, and has nothing to allocate for no changes.
@(test)
test_unified_grow :: proc(t: ^testing.T) {
	d := must(diff.diff_text("a\nb\nc\n", "a\nB\nc\n", context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	backing: [24]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	s, err := diff.unified(d, mem.arena_allocator(&arena), sizing = .Grow)
	testing.expect_value(t, err, mem.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, s, "")

	// Nothing to write allocates nothing, so an allocator that cannot free is fine
	same := must(diff.diff_text("a\n", "a\n", context.allocator, context.allocator))
	defer diff.text_diff_destroy(same, context.allocator)
	mem.arena_free_all(&arena)
	empty, empty_err := diff.unified(same, mem.arena_allocator(&arena), sizing = .Grow)
	testing.expect_value(t, empty_err, nil)
	testing.expect_value(t, empty, "")
	testing.expect_value(t, arena.offset, 0)
}

// On an allocator that resizes its last allocation in place, `.Grow` leaves exactly the output in use.
@(test)
test_unified_grow_in_place :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_text(2_000)
	b := mutate_lines(a, 200)
	d := must(diff.diff_text(a, b, context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)
	exact := must(diff.unified(d, context.allocator))
	defer delete(exact)

	backing := make([]byte, 4*len(exact) + 1024)
	defer delete(backing)
	arena: mem.Arena
	mem.arena_init(&arena, backing)

	grown := must(diff.unified(d, mem.arena_allocator(&arena), sizing = .Grow))
	testing.expect_value(t, grown, exact)
	testing.expect_value(t, arena.offset, len(exact))
}

// Takes writes until `limit` bytes are in, then fails every one after, counting them.
Failing_Writer :: struct {
	limit, written: int,
	failed:         bool,
	writes_after:   int,
}

failing_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	w := (^Failing_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		if w.failed {
			w.writes_after += 1
		}
		if w.written + len(p) > w.limit {
			w.failed = true
			return 0, .Short_Write
		}
		w.written += len(p)
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Empty
}

// A writer that fails at any byte makes `write_unified` return its error and stop writing, whatever is being written.
@(test)
test_unified_writer_error :: proc(t: ^testing.T) {
	// A changed line for emphasis, and a last line without a newline
	d := must(diff.diff_text("a\nthe quick fox\nc\nd", "a\nthe slow fox\nc\ne", context.allocator, context.allocator))
	defer diff.text_diff_destroy(d, context.allocator)

	for emphasis in diff.Emphasis {
		scratch := make([]byte, diff.emphasis_scratch_size(d, emphasis), context.temp_allocator)
		size := diff.unified_size(d, style = diff.STYLE_ANSI, emphasis = emphasis, scratch = scratch)
		for limit in 0..=size {
			fw := Failing_Writer{limit = limit}
			err := diff.write_unified({failing_stream_proc, &fw}, d, style = diff.STYLE_ANSI, emphasis = emphasis, scratch = scratch)
			if limit == size {
				testing.expectf(t, err == nil && !fw.failed, "%v: the full size failed with %v", emphasis, err)
				continue
			}
			if !testing.expectf(t, err == .Short_Write, "%v: failing after %d of %d bytes returned %v", emphasis, limit, size, err) ||
			   !testing.expectf(t, fw.writes_after == 0, "%v: failing after %d bytes, %d more writes were tried", emphasis, limit, fw.writes_after) {
				return
			}
		}
	}
}

@(test)
test_unified_random :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<150 {
		a := random_text(rand.int_max(60))
		b := mutate_lines(a, rand.int_max(15))
		for context_len in HUNK_CONTEXTS {
			if !check_unified(t, a, b, context_len) {
				return
			}
		}
		if !check_unified(t, a, b, 3, {.Ignore_All_Space, .Ignore_Case}) {
			return
		}
	}
}

@(test)
test_unified_large :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_text(5_000)
	b := mutate_lines(a, 300)
	check_unified(t, a, b, 3)
	check_unified(t, a, b, 0)
}
