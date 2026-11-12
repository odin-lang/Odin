/*
Differences between two sequences: which tokens of `a` were deleted and which tokens of `b` were inserted.

Diffs slices of any comparable type, slices of any type with your own equality and hash, and text by lines,
words, or runes. Read the result as edits, hunks, or substrings. Write it as a unified diff, in colour if
wanted, with the changed parts of lines highlighted.


## The Result

A diff is a `Changes`: one bit per token of `a` (deleted or not) and per token of `b` (inserted or not).
Its size is `changes_size(n, m)` words, known before diffing. Everything else reads from it without allocating:

	edit_iterate     `Edit`s: runs of equal, deleted, and inserted tokens
	hunk_iterate     `Hunk`s: groups of changes with equal tokens around them
	span_iterate     the same runs as substrings of a `Text_Diff`
	unified_iterate  the lines of a unified diff of a line diff
	write_unified    a unified diff, written to an `io.Writer`
	stats            the number of equal, deleted, and inserted tokens


## Algorithms

	.Myers               Myers' O(ND) diff with git's cost cap. Close to minimal. The default.
	.Minimal             Myers without the cap. Always minimal. Slow on very different inputs.
	.Histogram           git's histogram diff. Anchors on the rarest tokens, keeping moved blocks whole.
	                     Not minimal.
	.Ratcliff_Obershelp  The longest common block first, then each side of it. Not minimal. Tokens occurring
	                     in `b` more than 64 times (e.g. `}` or blank lines) extend blocks but never start
	                     them. Hands over to Myers past a budget of work.

`Options.max_cost` caps Myers in edits, wherever Myers runs. For `.Ratcliff_Obershelp`, it is also the
budget in steps per token. 0 means the default.

Flags:

	.Prune             Before diffing, set aside the common prefix and suffix, tokens absent from the other
	                   side, and runs of very frequent tokens. Often much faster.
	.Compact           After diffing, slide each group of changes to where git puts it: beside a change on
	                   the other side, otherwise as far down as it goes. With `.Histogram`, merged groups
	                   are diffed again.
	.Indent_Heuristic  With `.Compact`, slide each group to where the indentation and blank lines around it
	                   read best. Line diffs of text only. Anything else is an assertion failure.

These match git exactly:

	.Myers     + .Prune, .Compact, and .Indent_Heuristic  git diff
	.Minimal   + .Prune, .Compact, and .Indent_Heuristic  git diff --minimal
	.Histogram + .Compact and .Indent_Heuristic           git diff --histogram

Without `.Indent_Heuristic`, each matches git with `--no-indent-heuristic`.


## Memory

Nothing allocates behind your back. There are two ways in:

- The `*_buffer` procedures (`diff_buffer`, `diff_by_buffer`, `diff_interned_buffer`, and `diff_text_buffer`)
  never allocate. Pass `Changes` made from `changes_size` words, and scratch of `scratch_size`,
  `scratch_size_interned`, or `scratch_size_text` bytes at any alignment.
- The allocating procedures (`diff`, `diff_by`, `diff_interned`, and `diff_text`) take two allocators with no
  defaults. `allocator` gives the result for you to free. `transient_allocator` gives scratch that is freed
  before they return.

The result is allocated first and the scratch last. The scratch is freed first. Heap allocators never leak.
An allocator that frees in reverse order can be passed as both. A bump arena cannot free the scratch: it
stays until the arena is reset. Use separate arenas for the two lifetimes, or a `*_buffer` procedure with
scratch from a temporary region (see the examples).

Writers take `scratch: []byte`, not an allocator. Only `.Words` emphasis needs scratch:
`emphasis_scratch_size` bytes.

`unified` and `write_unified_to_builder` make room for their output by `Sizing`:

	.Exact  The default. Writes the diff twice and allocates exactly once. Suits any allocator.
	.Grow   Writes the diff once into growing memory. Close to twice as fast. Suits the heap and allocators
	        that resize their last allocation in place (e.g. `core:mem`'s and `core:mem/virtual`'s `Arena`).


## Limits

`a` and `b` together must have fewer than `max(i32)` tokens. Each text must be shorter than `max(i32)` bytes.
Going past either is an assertion failure.


## Examples

Example:
	package main

	import "core:diff"
	import "core:os"
	import "core:terminal"

	main :: proc() {
		old := "one\ntwo\nthree\n"
		new := "one\n2\nthree\nfour\n"

		d, err := diff.diff_text(old, new, context.allocator, context.allocator)
		if err != nil {
			return
		}
		defer diff.text_diff_destroy(d, context.allocator)

		style := diff.STYLE_NONE
		if terminal.color_enabled {
			style = diff.STYLE_ANSI
		}
		_ = diff.write_unified(os.to_stream(os.stdout), d, "old.txt", "new.txt", style = style, emphasis = .Prefix_Suffix)
	}

Output:
	--- old.txt
	+++ new.txt
	@@ -1,3 +1,4 @@
	 one
	-two
	+2
	 three
	+four


Example:
	// Any comparable type, read back as edits
	a := []int{1, 2, 3, 4, 5}
	b := []int{1, 3, 4, 6, 5}

	c, err := diff.diff(a, b, context.allocator, context.allocator, opts = {algorithm = .Histogram})
	if err != nil {
		return
	}
	defer diff.changes_destroy(c, context.allocator)

	it := diff.edit_iterator_make(c)
	for e in diff.edit_iterate(&it) {
		switch e.op {
		case .Equal:  fmt.println("keep  ", a[e.a_lo:e.a_hi])
		case .Delete: fmt.println("delete", a[e.a_lo:e.a_hi])
		case .Insert: fmt.println("insert", b[e.b_lo:e.b_hi])
		}
	}

Output:
	keep   [1]
	delete [2]
	keep   [3, 4]
	insert [6]
	keep   [5]


Example:
	// Your own equality: equal tokens must hash the same
	equal_fold :: proc(x, y: string, _: rawptr) -> bool {
		return strings.equal_fold(x, y)
	}
	hash_fold :: proc(x: string, _: rawptr) -> u64 {
		h := u64(0xcbf29ce484222325)
		for r in x {
			h = (h ~ u64(unicode.to_lower(r))) * 0x100000001b3
		}
		return h
	}

	a := []string{"Hello", "World"}
	b := []string{"hello", "there", "world"}
	c, err := diff.diff_by(a, b, equal_fold, hash_fold, nil, context.allocator, context.allocator)
	if err != nil {
		return
	}
	defer diff.changes_destroy(c, context.allocator)
	fmt.println(diff.stats(c))

Output:
	Stats{equal = 2, deleted = 0, inserted = 1}


Example:
	// Words, rendered inline
	d, err := diff.diff_text("the quick brown fox", "the slow brown fox", context.allocator, context.allocator, token = .Word)
	if err != nil {
		return
	}
	defer diff.text_diff_destroy(d, context.allocator)

	it := diff.span_iterator_make(d)
	for s in diff.span_iterate(&it) {
		switch s.op {
		case .Equal:  fmt.print(s.text)
		case .Delete: fmt.printf("[-%s-]", s.text)
		case .Insert: fmt.printf("{{+%s+}}", s.text)
		}
	}

Output:
	the [-quick-]{+slow+} brown fox


Example:
	// One arena: the result first, then the scratch in a temporary region
	arena: vmem.Arena
	_ = vmem.arena_init_growing(&arena)
	defer vmem.arena_destroy(&arena)
	arena_allocator := vmem.arena_allocator(&arena)

	n := diff.token_count(old, .Line)
	m := diff.token_count(new, .Line)
	bits, _ := make([]u64, diff.changes_size(n, m), arena_allocator)

	temp := vmem.arena_temp_begin(&arena)
	scratch, _ := make([]byte, diff.scratch_size_text(n, m), arena_allocator)
	d := diff.diff_text_buffer(old, new, diff.changes_from_buffer(n, m, bits), scratch)
	vmem.arena_temp_end(temp)

	// `d` stays valid until the arena is destroyed
*/
package diff
