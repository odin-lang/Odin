package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:slice"
import "core:testing"

/*
	Harness
*/

// The longest common block of `a[a_lo:a_hi]` and `b[b_lo:b_hi]`, by brute force, starting earliest in `a` and then in `b`.
reference_longest_block :: proc(a, b: []i32, a_lo, a_hi, b_lo, b_hi: int) -> (i, j, k: int) {
	for x in a_lo..<a_hi {
		for y in b_lo..<b_hi {
			length := 0
			for x + length < a_hi && y + length < b_hi && a[x + length] == b[y + length] {
				length += 1
			}
			if length > k {
				i, j, k = x, y, length
			}
		}
	}
	return
}

// Ratcliff/Obershelp the plain recursive way, with no budget.
reference_ratcliff_obershelp :: proc(a, b: []i32, deleted, inserted: []bool, a_lo, a_hi, b_lo, b_hi: int) {
	i, j, k := reference_longest_block(a, b, a_lo, a_hi, b_lo, b_hi)
	if k == 0 {
		for x in a_lo..<a_hi {
			deleted[x] = true
		}
		for y in b_lo..<b_hi {
			inserted[y] = true
		}
		return
	}
	reference_ratcliff_obershelp(a, b, deleted, inserted, a_lo, i, b_lo, j)
	reference_ratcliff_obershelp(a, b, deleted, inserted, i + k, a_hi, j + k, b_hi)
}

// With a budget too big to run out, `core:diff` must mark exactly what the plain version does.
check_ratcliff_obershelp_matches_reference :: proc(t: ^testing.T, a, b: []i32, loc := #caller_location) -> bool {
	deleted  := make([]bool, len(a), context.temp_allocator)
	inserted := make([]bool, len(b), context.temp_allocator)
	reference_ratcliff_obershelp(a, b, deleted, inserted, 0, len(a), 0, len(b))

	c := diff_exact(a, b, {algorithm = .Ratcliff_Obershelp, max_cost = 1 << 30})
	defer diff.changes_destroy(c, context.allocator)
	for x in 0..<len(a) {
		testing.expectf(t, diff.is_deleted(c, x) == deleted[x], "a[%d]: deleted %v, expected %v (a = %v, b = %v)", x, diff.is_deleted(c, x), deleted[x], a, b, loc = loc) or_return
	}
	for y in 0..<len(b) {
		testing.expectf(t, diff.is_inserted(c, y) == inserted[y], "b[%d]: inserted %v, expected %v (a = %v, b = %v)", y, diff.is_inserted(c, y), inserted[y], a, b, loc = loc) or_return
	}
	return true
}

// The first block taken is the longest of all, meaning no run of equal tokens can be longer, and one is as long.
check_longest_run :: proc(t: ^testing.T, a, b: []i32, loc := #caller_location) -> bool {
	_, _, longest := reference_longest_block(a, b, 0, len(a), 0, len(b))

	c := diff_exact(a, b, {algorithm = .Ratcliff_Obershelp, max_cost = 1 << 30})
	defer diff.changes_destroy(c, context.allocator)

	run := 0
	it := diff.edit_iterator_make(c)
	for e in diff.edit_iterate(&it) {
		if e.op == .Equal {
			run = max(run, e.a_hi - e.a_lo)
		}
	}
	return testing.expectf(t, run == longest, "longest equal run %d, longest common block %d (a = %v, b = %v)", run, longest, a, b, loc = loc)
}


/*
	Tests
*/

@(test)
test_ratcliff_obershelp_matches_reference :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<300 {
		alphabet := 1 + rand.int_max(8)
		a := random_sequence(rand.int_max(60), alphabet)
		defer delete(a)
		b := mutate(a, rand.int_max(20), alphabet)
		defer delete(b)
		if !check_ratcliff_obershelp_matches_reference(t, a, b) || !check_longest_run(t, a, b) {
			return
		}
	}
	for _ in 0..<100 {
		alphabet := 1 + rand.int_max(4)
		a := random_sequence(rand.int_max(40), alphabet)
		defer delete(a)
		b := random_sequence(rand.int_max(40), alphabet)
		defer delete(b)
		if !check_ratcliff_obershelp_matches_reference(t, a, b) || !check_longest_run(t, a, b) {
			return
		}
	}
}

@(test)
test_ratcliff_obershelp_exhaustive :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 7, {algorithm = .Ratcliff_Obershelp})
	check_exhaustive(t, 3, 5, {algorithm = .Ratcliff_Obershelp})
}

// The longest block wins over more matches spread out: "XYZ" against six single tokens.
@(test)
test_ratcliff_obershelp_prefers_blocks :: proc(t: ^testing.T) {
	ONE, TWO, THREE, FOUR, FIVE, SIX, X, Y, Z :: 1, 2, 3, 4, 5, 6, 24, 25, 26
	A, B, C, D, E, F :: 11, 12, 13, 14, 15, 16
	a := []i32{ONE, TWO, THREE, FOUR, FIVE, SIX, X, Y, Z}
	b := []i32{X, Y, Z, ONE, A, TWO, B, THREE, C, FOUR, D, FIVE, E, SIX, F}

	ro := diff_exact(a, b, {algorithm = .Ratcliff_Obershelp})
	defer diff.changes_destroy(ro, context.allocator)
	myers := diff_exact(a, b, {algorithm = .Myers})
	defer diff.changes_destroy(myers, context.allocator)

	testing.expect_value(t, diff.stats(ro).equal, 3)
	testing.expect_value(t, diff.stats(myers).equal, 6)
}

/*
	Inputs ending in 20 of a token found nowhere else: searching those is 400 steps, far past a budget of
	`1 * (n+m)`, meaning every diff goes to Myers with the same cap. At least one must come out differently
	without the budget, or the test shows nothing.
*/
@(test)
test_ratcliff_obershelp_budget :: proc(t: ^testing.T) {
	REPEATED :: 99

	rand.reset(t.seed)
	differs := false
	for _ in 0..<50 {
		a := make([dynamic]i32)
		defer delete(a)
		b := make([dynamic]i32)
		defer delete(b)

		base := random_sequence(30, 6)
		defer delete(base)
		changed := mutate(base, 8, 6)
		defer delete(changed)
		append(&a, ..base)
		append(&b, ..changed)
		for _ in 0..<20 {
			append(&a, REPEATED)
			append(&b, REPEATED)
		}

		budgeted := diff_exact(a[:], b[:], {algorithm = .Ratcliff_Obershelp, max_cost = 1})
		defer diff.changes_destroy(budgeted, context.allocator)
		unlimited := diff_exact(a[:], b[:], {algorithm = .Ratcliff_Obershelp, max_cost = 1 << 30})
		defer diff.changes_destroy(unlimited, context.allocator)
		myers := diff_exact(a[:], b[:], {algorithm = .Myers, max_cost = 1})
		defer diff.changes_destroy(myers, context.allocator)

		// A cost too large to multiply by the tokens is no limit either, rather than an overflow
		maxed := diff_exact(a[:], b[:], {algorithm = .Ratcliff_Obershelp, max_cost = max(int)})
		defer diff.changes_destroy(maxed, context.allocator)

		if !check_valid(t, a[:], b[:], budgeted) || !testing.expect(t, slice.equal(budgeted.bits, myers.bits), "running out of budget did not hand the diff to Myers") {
			return
		}
		if !testing.expect(t, slice.equal(maxed.bits, unlimited.bits), "a cost of max(int) did not mean no limit") {
			return
		}
		differs ||= !slice.equal(unlimited.bits, myers.bits)
	}
	testing.expect(t, differs, "without a budget every result was the same, meaning this test shows nothing")
}


/*
	Frequent tokens: one occurring in `b` more than 64 times may carry a run on but never start one.
	The longest such run, ending earliest, is grown back through the equal tokens before it.
	When only frequent tokens match, the region goes to Myers.
*/

reference_frequent :: proc(b: []i32) -> map[i32]bool {
	count := make(map[i32]int, context.temp_allocator)
	for y in b {
		count[y] += 1
	}
	frequent := make(map[i32]bool, context.temp_allocator)
	for id, c in count {
		if c > 64 {
			frequent[id] = true
		}
	}
	return frequent
}

reference_ratcliff_obershelp_frequent :: proc(a, b: []i32, deleted, inserted: []bool, a_lo, a_hi, b_lo, b_hi: int, frequent: map[i32]bool, id_count: int) {
	if a_lo == a_hi || b_lo == b_hi {
		for x in a_lo..<a_hi {
			deleted[x] = true
		}
		for y in b_lo..<b_hi {
			inserted[y] = true
		}
		return
	}

	// `run[x][y]`: the length of the run ending at `a[x]` and `b[y]` that started on a token that is not frequent
	w := b_hi - b_lo + 1
	run := make([]int, (a_hi - a_lo + 1) * w, context.temp_allocator)
	at  :: proc(x, y, a_lo, b_lo, w: int) -> int { return (x - a_lo + 1)*w + (y - b_lo + 1) }
	frequent_in_common := false
	i, j, k := 0, 0, 0
	for x in a_lo..<a_hi {
		for y in b_lo..<b_hi {
			if a[x] != b[y] {
				continue
			}
			before := run[at(x - 1, y - 1, a_lo, b_lo, w)]
			if frequent[a[x]] {
				frequent_in_common = true
				if before == 0 {
					continue
				}
			}
			r := before + 1
			run[at(x, y, a_lo, b_lo, w)] = r
			if r > k {
				i, j, k = x - r + 1, y - r + 1, r
			}
		}
	}

	if k == 0 {
		if frequent_in_common {
			c := must(diff.diff_interned(a[a_lo:a_hi], b[b_lo:b_hi], id_count, context.allocator, context.allocator, opts = {algorithm = .Myers, max_cost = 1 << 30}))
			defer diff.changes_destroy(c, context.allocator)
			for x in a_lo..<a_hi {
				deleted[x] = diff.is_deleted(c, x - a_lo)
			}
			for y in b_lo..<b_hi {
				inserted[y] = diff.is_inserted(c, y - b_lo)
			}
			return
		}
		for x in a_lo..<a_hi {
			deleted[x] = true
		}
		for y in b_lo..<b_hi {
			inserted[y] = true
		}
		return
	}

	for i > a_lo && j > b_lo && a[i-1] == b[j-1] {
		i -= 1
		j -= 1
		k += 1
	}
	reference_ratcliff_obershelp_frequent(a, b, deleted, inserted, a_lo, i, b_lo, j, frequent, id_count)
	reference_ratcliff_obershelp_frequent(a, b, deleted, inserted, i + k, a_hi, j + k, b_hi, frequent, id_count)
}

// Three tokens making up a quarter each, far past 64 occurrences, and many more that are rare.
frequent_and_rare :: proc(length: int) -> []i32 {
	s := make([]i32, length)
	for &x in s {
		if rand.int_max(4) < 3 {
			x = i32(rand.int_max(3))
		} else {
			x = i32(100 + rand.int_max(300))
		}
	}
	return s
}

@(test)
test_ratcliff_obershelp_frequent_matches_reference :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	checked := 0
	for _ in 0..<40 {
		a := frequent_and_rare(260 + rand.int_max(100))
		defer delete(a)
		b := mutate(a, rand.int_max(40), 3)
		defer delete(b)

		frequent := reference_frequent(b)
		deleted  := make([]bool, len(a), context.temp_allocator)
		inserted := make([]bool, len(b), context.temp_allocator)
		reference_ratcliff_obershelp_frequent(a, b, deleted, inserted, 0, len(a), 0, len(b), frequent, id_count_of(a, b))

		c := diff_exact(a, b, {algorithm = .Ratcliff_Obershelp, max_cost = 1 << 30})
		defer diff.changes_destroy(c, context.allocator)
		if !check_valid(t, a, b, c) {
			return
		}
		for x in 0..<len(a) {
			if !testing.expectf(t, diff.is_deleted(c, x) == deleted[x], "a[%d]: deleted %v, expected %v", x, diff.is_deleted(c, x), deleted[x]) {
				return
			}
		}
		for y in 0..<len(b) {
			if !testing.expectf(t, diff.is_inserted(c, y) == inserted[y], "b[%d]: inserted %v, expected %v", y, diff.is_inserted(c, y), inserted[y]) {
				return
			}
		}
		if len(frequent) > 0 {
			checked += 1
		}
	}
	testing.expect(t, checked > 0, "no input had frequent tokens, meaning this test shows nothing")
}

// Only frequent tokens in common: the region goes to Myers rather than being all changes.
@(test)
test_ratcliff_obershelp_only_frequent :: proc(t: ^testing.T) {
	a := make([]i32, 300)
	defer delete(a)
	b := make([]i32, 300)
	defer delete(b)
	for i in 0..<300 {
		a[i] = i32(1000 + i) // all different, and found nowhere in `b`
		b[i] = i32(2000 + i)
	}
	for i := 0; i < 300; i += 3 {
		a[i] = 7 // 100 times in `b`, and the only token in common
		b[i] = 7
	}

	c := diff_exact(a, b, {algorithm = .Ratcliff_Obershelp})
	defer diff.changes_destroy(c, context.allocator)
	check_valid(t, a, b, c)
	testing.expect_value(t, diff.stats(c).equal, 100)
}

// A rare token in the wrong place must not win over a long run that is mostly frequent tokens.
@(test)
test_ratcliff_obershelp_frequent_runs_count :: proc(t: ^testing.T) {
	RARE :: 500
	a := make([dynamic]i32)
	defer delete(a)
	b := make([dynamic]i32)
	defer delete(b)

	// `a` opens with a rare token that `b` only has at its very end, then both share one long stretch
	// of frequent tokens started by another rare token. Counting runs of one rare token alone, the first
	// would win and leave nothing else to match.
	append(&a, RARE, RARE + 1)
	append(&b, RARE + 1)
	for k in 0..<300 {
		append(&a, i32(k % 3))
		append(&b, i32(k % 3))
	}
	append(&b, RARE)

	c := diff_exact(a[:], b[:], {algorithm = .Ratcliff_Obershelp})
	defer diff.changes_destroy(c, context.allocator)
	check_valid(t, a[:], b[:], c)
	testing.expect_value(t, diff.stats(c).equal, 301)
}
