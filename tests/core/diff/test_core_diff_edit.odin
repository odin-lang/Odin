package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:slice"
import "core:testing"

/*
	Harness
*/

collect_edits :: proc(c: diff.Changes) -> [dynamic]diff.Edit {
	edits: [dynamic]diff.Edit
	it := diff.edit_iterator_make(c)
	for e in diff.edit_iterate(&it) {
		append(&edits, e)
	}
	return edits
}

collect_hunks :: proc(c: diff.Changes, context_len: int) -> [dynamic]diff.Hunk {
	hunks: [dynamic]diff.Hunk
	it := diff.hunk_iterator_make(c, context_len)
	for h in diff.hunk_iterate(&it) {
		append(&hunks, h)
	}
	return hunks
}

/*
	Checks the edits of a valid diff of `a` and `b`:
	- they cover both sides in order, with no gaps, overlaps or empty runs
	- a `.Delete` has an empty `b` range, an `.Insert` an empty `a` range, and an `.Equal` the same length on both sides
	- `.Equal` runs hold equal tokens, and the tokens of `.Delete` and `.Insert` runs are marked
	- neighbours never share an op, and an `.Insert` is never followed by a `.Delete`
	- `b` can be rebuilt from `a` and the edits
	- `edit_count`, `edits_fill` and `edits_make` agree with the iterator
*/
check_edits :: proc(t: ^testing.T, a, b: []i32, c: diff.Changes, loc := #caller_location) -> bool {
	edits := collect_edits(c)
	defer delete(edits)

	rebuilt: [dynamic]i32
	defer delete(rebuilt)

	i, j := 0, 0
	for e, n in edits {
		testing.expectf(t, e.a_lo == i && e.b_lo == j, "edit %d %v does not start at a[%d], b[%d]", n, e, i, j, loc = loc) or_return
		testing.expectf(t, e.a_hi > e.a_lo || e.b_hi > e.b_lo, "edit %d %v is empty", n, e, loc = loc) or_return

		switch e.op {
		case .Equal:
			testing.expectf(t, e.a_hi - e.a_lo == e.b_hi - e.b_lo, "edit %d %v has sides of different lengths", n, e, loc = loc) or_return
			for k in 0..<e.a_hi - e.a_lo {
				testing.expectf(t, a[e.a_lo + k] == b[e.b_lo + k], "edit %d %v holds unequal tokens", n, e, loc = loc) or_return
			}
			append(&rebuilt, ..a[e.a_lo:e.a_hi])
		case .Delete:
			testing.expectf(t, e.b_lo == e.b_hi, "edit %d %v deletes from b", n, e, loc = loc) or_return
			for k in e.a_lo..<e.a_hi {
				testing.expectf(t, diff.is_deleted(c, k), "edit %d %v covers a kept a[%d]", n, e, k, loc = loc) or_return
			}
		case .Insert:
			testing.expectf(t, e.a_lo == e.a_hi, "edit %d %v inserts into a", n, e, loc = loc) or_return
			for k in e.b_lo..<e.b_hi {
				testing.expectf(t, diff.is_inserted(c, k), "edit %d %v covers a kept b[%d]", n, e, k, loc = loc) or_return
			}
			append(&rebuilt, ..b[e.b_lo:e.b_hi])
		}

		if n > 0 {
			prev := edits[n-1]
			testing.expectf(t, prev.op != e.op, "edits %d and %d are both %v", n-1, n, e.op, loc = loc) or_return
			testing.expectf(t, !(prev.op == .Insert && e.op == .Delete), "edit %d is a .Delete after an .Insert", n, loc = loc) or_return
		}
		i, j = e.a_hi, e.b_hi
	}
	testing.expectf(t, i == len(a) && j == len(b), "edits end at a[%d], b[%d], not a[%d], b[%d]", i, j, len(a), len(b), loc = loc) or_return
	testing.expect(t, slice.equal(rebuilt[:], b), "b could not be rebuilt from the edits", loc = loc) or_return

	testing.expect_value(t, diff.edit_count(c), len(edits), loc = loc) or_return

	buf := make([]diff.Edit, len(edits))
	defer delete(buf)
	testing.expect(t, slice.equal(diff.edits_fill(c, buf), edits[:]), "edits_fill disagrees with the iterator", loc = loc) or_return

	made := must(diff.edits_make(c, context.allocator))
	defer delete(made)
	testing.expect(t, slice.equal(made, edits[:]), "edits_make disagrees with the iterator", loc = loc) or_return
	return true
}

// Hunks worked out from the edit list rather than the bits.
reference_hunks :: proc(c: diff.Changes, context_len: int) -> [dynamic]diff.Hunk {
	edits := collect_edits(c)
	defer delete(edits)

	// Each change is a `.Delete`, an `.Insert`, or a `.Delete` then an `.Insert`
	changes: [dynamic]diff.Hunk
	defer delete(changes)
	for e in edits {
		if e.op == .Equal {
			continue
		}
		if len(changes) > 0 && changes[len(changes)-1].a_hi == e.a_lo && changes[len(changes)-1].b_hi == e.b_lo {
			last := &changes[len(changes)-1]
			last.a_hi, last.b_hi = e.a_hi, e.b_hi
		} else {
			append(&changes, diff.Hunk{e.a_lo, e.a_hi, e.b_lo, e.b_hi})
		}
	}

	hunks: [dynamic]diff.Hunk
	for ch, k in changes {
		gap_before := k == 0 ? ch.a_lo : ch.a_lo - changes[k-1].a_hi
		gap_after  := k == len(changes)-1 ? c.n - ch.a_hi : changes[k+1].a_lo - ch.a_hi
		if k == 0 || gap_before > 2*context_len {
			lead := min(context_len, gap_before)
			append(&hunks, diff.Hunk{ch.a_lo - lead, 0, ch.b_lo - lead, 0})
		}
		trail := min(context_len, gap_after)
		h := &hunks[len(hunks)-1]
		h.a_hi, h.b_hi = ch.a_hi + trail, ch.b_hi + trail
	}
	return hunks
}

/*
	Checks the hunks of a valid diff against `reference_hunks`, and that iterating the edits of each hunk
	gives its context, at most `context_len` tokens on each end, around at least one change.
*/
check_hunks :: proc(t: ^testing.T, c: diff.Changes, context_len: int, loc := #caller_location) -> bool {
	hunks := collect_hunks(c, context_len)
	defer delete(hunks)
	expected := reference_hunks(c, context_len)
	defer delete(expected)
	testing.expectf(t, slice.equal(hunks[:], expected[:]), "context %d: hunks %v, expected %v", context_len, hunks, expected, loc = loc) or_return

	for h in hunks {
		edits: [dynamic]diff.Edit
		defer delete(edits)
		it := diff.edit_iterator_make_hunk(c, h)
		for e in diff.edit_iterate(&it) {
			append(&edits, e)
		}

		testing.expectf(t, len(edits) > 0, "hunk %v has no edits", h, loc = loc) or_return
		first, last := edits[0], edits[len(edits)-1]
		testing.expectf(t, first.a_lo == h.a_lo && first.b_lo == h.b_lo, "hunk %v starts with %v", h, first, loc = loc) or_return
		testing.expectf(t, last.a_hi == h.a_hi && last.b_hi == h.b_hi, "hunk %v ends with %v", h, last, loc = loc) or_return
		if first.op == .Equal {
			testing.expectf(t, first.a_hi - first.a_lo <= context_len, "hunk %v leads with %v", h, first, loc = loc) or_return
		}
		if last.op == .Equal {
			testing.expectf(t, last.a_hi - last.a_lo <= context_len, "hunk %v trails with %v", h, last, loc = loc) or_return
		}
		testing.expectf(t, len(edits) > 1 || first.op != .Equal, "hunk %v holds no change", h, loc = loc) or_return
	}
	return true
}

@(rodata)
HUNK_CONTEXTS := [?]int{0, 1, 2, 3, 5}

check_views :: proc(t: ^testing.T, a, b: []i32, opts := diff.Options{}, loc := #caller_location) -> bool {
	c := diff_exact(a, b, opts)
	defer diff.changes_destroy(c, context.allocator)
	check_valid(t, a, b, c, loc) or_return
	check_edits(t, a, b, c, loc) or_return
	for context_len in HUNK_CONTEXTS {
		check_hunks(t, c, context_len, loc) or_return
	}
	return true
}

// `a` is `0..<n`, and `b` is `a` with each position in `replaced` swapped for a token found nowhere else.
replaced :: proc(n: int, positions: []int) -> (a, b: []i32) {
	a = make([]i32, n)
	b = make([]i32, n)
	for i in 0..<n {
		a[i] = i32(i)
		b[i] = i32(i)
	}
	for p, k in positions {
		b[p] = i32(n + k)
	}
	return
}

expect_hunks :: proc(t: ^testing.T, a, b: []i32, context_len: int, expected: []diff.Hunk, loc := #caller_location) {
	c := diff_exact(a, b)
	defer diff.changes_destroy(c, context.allocator)
	hunks := collect_hunks(c, context_len)
	defer delete(hunks)
	testing.expectf(t, slice.equal(hunks[:], expected), "context %d: hunks %v, expected %v", context_len, hunks, expected, loc = loc)
}


/*
	Tests
*/

@(test)
test_edits_simple :: proc(t: ^testing.T) {
	{
		c := diff_exact(nil, nil)
		defer diff.changes_destroy(c, context.allocator)
		testing.expect_value(t, diff.edit_count(c), 0)
	}
	{
		x := []i32{1, 2, 3}
		c := diff_exact(x, x)
		defer diff.changes_destroy(c, context.allocator)
		edits := collect_edits(c)
		defer delete(edits)
		testing.expect(t, slice.equal(edits[:], []diff.Edit{{.Equal, 0, 3, 0, 3}}))
	}
	{
		c := diff_exact([]i32{1, 2}, []i32{3, 4, 5})
		defer diff.changes_destroy(c, context.allocator)
		edits := collect_edits(c)
		defer delete(edits)
		testing.expect(t, slice.equal(edits[:], []diff.Edit{{.Delete, 0, 2, 0, 0}, {.Insert, 2, 2, 0, 3}}))
	}
	{
		c := diff_exact([]i32{1, 2, 3}, []i32{1, 4, 3})
		defer diff.changes_destroy(c, context.allocator)
		edits := collect_edits(c)
		defer delete(edits)
		expected := []diff.Edit{
			{.Equal,  0, 1, 0, 1},
			{.Delete, 1, 2, 1, 1},
			{.Insert, 2, 2, 1, 2},
			{.Equal,  2, 3, 2, 3},
		}
		testing.expectf(t, slice.equal(edits[:], expected), "edits %v, expected %v", edits, expected)
	}
}

@(test)
test_edits_exhaustive :: proc(t: ^testing.T) {
	a_buf: [6]i32
	b_buf: [6]i32
	for len_a in 0..=len(a_buf) {
		for code_a in 0..<count_of(2, len_a) {
			a := a_buf[:len_a]
			decode(code_a, 2, a)
			for len_b in 0..=len(b_buf) {
				for code_b in 0..<count_of(2, len_b) {
					b := b_buf[:len_b]
					decode(code_b, 2, b)
					if !check_views(t, a, b) {
						return
					}
				}
			}
		}
	}
}

@(test)
test_edits_random :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<200 {
		alphabet := 1 + rand.int_max(10)
		a := random_sequence(rand.int_max(300), alphabet)
		defer delete(a)
		b := mutate(a, rand.int_max(40), alphabet)
		defer delete(b)
		for opts in PAIR_OPTIONS {
			if !check_views(t, a, b, opts) {
				return
			}
		}
	}
}

// Long runs of every kind, across many words of bits.
@(test)
test_edits_large :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	{
		a := random_sequence(20_000, 50)
		defer delete(a)
		b := mutate(a, 50, 50)
		defer delete(b)
		check_views(t, a, b)
	}
	{
		a := make([]i32, 1_000)
		defer delete(a)
		b := make([]i32, 700)
		defer delete(b)
		for i in 0..<len(b) {
			b[i] = 1
		}
		check_views(t, a, b)
	}
}

@(test)
test_hunks_merging :: proc(t: ^testing.T) {
	// Changes 6 apart share their context of 3; 7 apart they do not
	{
		a, b := replaced(20, {3, 10})
		defer delete(a)
		defer delete(b)
		expect_hunks(t, a, b, 3, {{0, 14, 0, 14}})
		expect_hunks(t, a, b, 2, {{1, 6, 1, 6}, {8, 13, 8, 13}})
		expect_hunks(t, a, b, 0, {{3, 4, 3, 4}, {10, 11, 10, 11}})
	}
	{
		a, b := replaced(20, {3, 11})
		defer delete(a)
		defer delete(b)
		expect_hunks(t, a, b, 3, {{0, 7, 0, 7}, {8, 15, 8, 15}})
		expect_hunks(t, a, b, 4, {{0, 16, 0, 16}})
	}
}

@(test)
test_hunks_edges :: proc(t: ^testing.T) {
	{
		c := diff_exact(nil, nil)
		defer diff.changes_destroy(c, context.allocator)
		hunks := collect_hunks(c, 3)
		defer delete(hunks)
		testing.expect_value(t, len(hunks), 0)
	}
	{
		x := []i32{1, 2, 3}
		c := diff_exact(x, x)
		defer diff.changes_destroy(c, context.allocator)
		hunks := collect_hunks(c, 3)
		defer delete(hunks)
		testing.expect_value(t, len(hunks), 0)
	}

	// Changes at the very start and the very end
	{
		a, b := replaced(20, {0})
		defer delete(a)
		defer delete(b)
		expect_hunks(t, a, b, 3, {{0, 4, 0, 4}})
	}
	{
		a, b := replaced(20, {19})
		defer delete(a)
		defer delete(b)
		expect_hunks(t, a, b, 3, {{16, 20, 16, 20}})
	}

	// Only insertions at the end, and only deletions of everything
	expect_hunks(t, []i32{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, []i32{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 100}, 3, {{7, 10, 7, 11}})
	expect_hunks(t, []i32{1, 2, 3}, nil, 3, {{0, 3, 0, 0}})

	// A negative context is treated as 0
	{
		a, b := replaced(20, {3, 10})
		defer delete(a)
		defer delete(b)
		expect_hunks(t, a, b, -1, {{3, 4, 3, 4}, {10, 11, 10, 11}})
	}

	// A context too large to double is still one hunk around everything
	{
		a, b := replaced(20, {3, 10})
		defer delete(a)
		defer delete(b)
		expect_hunks(t, a, b, max(int), {{0, 20, 0, 20}})
		expect_hunks(t, a, b, max(int)/2 + 1, {{0, 20, 0, 20}})
	}
}
