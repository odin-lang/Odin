package test_core_diff

import "core:diff"
import "core:fmt"
import "core:math/rand"
import "core:slice"
import "core:strings"
import "core:testing"

/*
	Harness
*/

// Code-like lines: nested braces, blank lines, lines of only whitespace, and lines that repeat.
code_block :: proc(sb: ^strings.Builder, depth: int) {
	for _ in 0..<1 + rand.int_max(4) {
		switch rand.int_max(6) {
		case 0:
			strings.write_byte(sb, '\n')
		case 1, 2:
			for _ in 0..<depth {
				strings.write_byte(sb, '\t')
			}
			fmt.sbprintf(sb, "x%d();\n", rand.int_max(4))
		case 3:
			if depth < 3 {
				for _ in 0..<depth {
					strings.write_byte(sb, '\t')
				}
				fmt.sbprintf(sb, "if (c%d) {{\n", rand.int_max(3))
				code_block(sb, depth + 1)
				for _ in 0..<depth {
					strings.write_byte(sb, '\t')
				}
				strings.write_string(sb, "}\n")
			}
		case 4:
			strings.write_string(sb, "  return;\n")
		case 5:
			strings.write_string(sb, "    \n")
		}
	}
}

code_function :: proc() -> string {
	sb := strings.builder_make(context.temp_allocator)
	strings.write_string(&sb, "func() {\n")
	code_block(&sb, 1)
	strings.write_string(&sb, "}\n\n")
	return strings.to_string(sb)
}

// Two texts of whole functions, the second with some inserted, removed or repeated.
code_pair :: proc() -> (a, b: string) {
	functions := make([dynamic]string, context.temp_allocator)
	for _ in 0..<3 + rand.int_max(8) {
		append(&functions, code_function())
	}
	a = strings.concatenate(functions[:], context.temp_allocator)

	for _ in 0..<1 + rand.int_max(3) {
		switch rand.int_max(3) {
		case 0:
			inject_at(&functions, rand.int_max(len(functions) + 1), code_function())
		case 1:
			if len(functions) > 1 {
				ordered_remove(&functions, rand.int_max(len(functions)))
			}
		case 2:
			i := rand.int_max(len(functions))
			inject_at(&functions, i, functions[i])
		}
	}
	b = strings.concatenate(functions[:], context.temp_allocator)
	return
}

// The heuristic only slides groups. The cost must stay as it was without `.Compact`, except where Histogram diffs merged groups again.
check_indent_keeps_cost :: proc(t: ^testing.T, a, b: string, algorithm: diff.Algorithm, loc := #caller_location) -> bool {
	plain := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = {algorithm = algorithm}))
	defer diff.text_diff_destroy(plain, context.allocator)
	d := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = {algorithm = algorithm, flags = {.Compact, .Indent_Heuristic}}))
	defer diff.text_diff_destroy(d, context.allocator)

	check_spans(t, d, true, loc) or_return
	if algorithm == .Histogram {
		return testing.expectf(t, cost(d.changes) <= cost(plain.changes), "Histogram: the heuristic grew the diff from %d to %d", cost(plain.changes), cost(d.changes), loc = loc)
	}
	return testing.expectf(t, cost(d.changes) == cost(plain.changes), "%v: the heuristic changed the cost from %d to %d", algorithm, cost(plain.changes), cost(d.changes), loc = loc)
}

// Adding `.Indent_Heuristic` to `opts` must change nothing.
check_indent_changes_nothing :: proc(t: ^testing.T, a, b: string, opts: diff.Options, loc := #caller_location) -> bool {
	plain := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = opts))
	defer diff.text_diff_destroy(plain, context.allocator)
	d := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = {algorithm = opts.algorithm, flags = opts.flags + {.Indent_Heuristic}}))
	defer diff.text_diff_destroy(d, context.allocator)
	return testing.expectf(t, slice.equal(d.changes.bits, plain.changes.bits), "%v: the heuristic moved a group (a = %q, b = %q)", opts, a, b, loc = loc)
}


/*
	Tests
*/

@(test)
test_indent_keeps_cost :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<100 {
		a, b := code_pair()
		for algorithm in diff.Algorithm {
			if !check_indent_keeps_cost(t, a, b, algorithm) {
				return
			}
		}
	}
}

/*
	With every line indented the same and none blank, each position the heuristic weighs scores the same. Ties go to
	the lowest, where `.Compact` alone leaves a group. Unique first and last lines keep groups off the ends of the
	text, where positions score worse.
*/
@(test)
test_indent_uniform :: proc(t: ^testing.T) {
	@(require_results)
	uniform_text :: proc(tokens: []i32, indent: string) -> string {
		sb := strings.builder_make(context.temp_allocator)
		fmt.sbprintf(&sb, "%sfirst\n", indent)
		for x in tokens {
			fmt.sbprintf(&sb, "%s%c\n", indent, 'a' + rune(x))
		}
		fmt.sbprintf(&sb, "%slast\n", indent)
		return strings.to_string(sb)
	}


	rand.reset(t.seed)
	for _ in 0..<200 {
		indent   := rand.choice([]string{"", "\t", "    "})
		alphabet := 1 + rand.int_max(4)
		x := random_sequence(rand.int_max(60), alphabet)
		defer delete(x)
		y := mutate(x, rand.int_max(15), alphabet)
		defer delete(y)
		a := uniform_text(x, indent)
		b := uniform_text(y, indent)

		for algorithm in diff.Algorithm {
			for flags in ([?]diff.Option_Flags{{.Compact}, {.Prune, .Compact}}) {
				if !check_indent_changes_nothing(t, a, b, {algorithm = algorithm, flags = flags}) {
					return
				}
			}
		}
	}
}

/*
	A pair where git's indent heuristic changes the output. The expected text is what
	`git diff --no-index` gives, which is Myers with `.Prune`, `.Compact` and `.Indent_Heuristic`.
*/
@(test)
test_indent_matches_git :: proc(t: ^testing.T) {
	a := "func() {\n\treturn;\n\n\tx1();\n}\n\nfunc() {\n\treturn;\n\n\tx2();\n}\n\nfunc() {\n\n    \n    \n    \n}\n\nfunc() {\n\tx3();\n\tx1();\n}\n\nfunc() {\n\treturn;\n\n}\n\n"
	b := "func() {\n\treturn;\n\n\tx2();\n}\n\nfunc() {\n\tx3();\n\tx1();\n}\n\nfunc() {\n\treturn;\n\n}\n\n"

	d := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = {flags = {.Prune, .Compact, .Indent_Heuristic}}))
	defer diff.text_diff_destroy(d, context.allocator)
	s := must(diff.unified(d, context.temp_allocator))
	expected :=
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,20 +1,7 @@\n" +
		"-func() {\n" +
		"-\treturn;\n" +
		"-\n" +
		"-\tx1();\n" +
		"-}\n" +
		"-\n" +
		" func() {\n" +
		" \treturn;\n" +
		" \n" +
		" \tx2();\n" +
		"-}\n" +
		"-\n" +
		"-func() {\n" +
		"-\n" +
		"-    \n" +
		"-    \n" +
		"-    \n" +
		" }\n" +
		" \n" +
		" func() {\n"
	testing.expectf(t, s == expected, "got:\n%s\nexpected:\n%s", s, expected)

	// Without the heuristic the deletions sit lower down
	plain := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = {flags = {.Prune, .Compact}}))
	defer diff.text_diff_destroy(plain, context.allocator)
	testing.expect(t, must(diff.unified(plain, context.temp_allocator)) != expected, "the heuristic made no difference, meaning this test shows nothing")
}

// Scratch of exactly `scratch_size_text` bytes, counting the indents, must work at every alignment.
@(test)
test_indent_scratch_alignment :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a, b := code_pair()
	opts := diff.Options{flags = {.Prune, .Compact, .Indent_Heuristic}}
	n, m := diff.token_count(a, .Line), diff.token_count(b, .Line)
	size := diff.scratch_size_text(n, m, opts)
	buf  := make([]byte, size + 16)
	defer delete(buf)

	expected := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = opts))
	defer diff.text_diff_destroy(expected, context.allocator)
	for offset in 0..<16 {
		c := must(diff.changes_make(n, m, context.allocator))
		defer diff.changes_destroy(c, context.allocator)
		d := diff.diff_text_buffer(a, b, c, buf[offset:][:size], opts = opts)
		testing.expectf(t, slice.equal(d.changes.bits, expected.changes.bits), "offset %d differs", offset)
	}
}

