package test_core_diff

import "base:runtime"
import "core:diff"
import "core:math/rand"
import "core:slice"
import "core:testing"

/*
	Harness
*/

/*
	Unwraps the result of an allocating procedure, failing on any allocation error.
	The tests allocate from `context.allocator`, which the test runner tracks, meaning any leak fails the test.
*/
must :: proc(value: $T, err: runtime.Allocator_Error, loc := #caller_location) -> T {
	assert(err == nil, "allocation failed", loc)
	return value
}

// Length of the longest common subsequence, by dynamic programming over two rows of `len(b)+1` ints each.
lcs_length :: proc(a, b: []i32, rows: []int = nil) -> int {
	if rows == nil {
		owned := make([]int, 2*(len(b) + 1))
		defer delete(owned)
		return lcs_length(a, b, owned)
	}

	prev := rows[:len(b) + 1]
	curr := rows[len(b) + 1:][:len(b) + 1]
	for &x in prev {
		x = 0
	}
	curr[0] = 0

	for x in a {
		for y, j in b {
			if x == y {
				curr[j+1] = prev[j] + 1
			} else {
				curr[j+1] = max(prev[j+1], curr[j])
			}
		}
		prev, curr = curr, prev
	}
	return prev[len(b)]
}

// The cost of a minimal diff of `a` and `b`: tokens deleted plus tokens inserted.
minimal_cost :: proc(a, b: []i32, rows: []int = nil) -> int {
	return len(a) + len(b) - 2*lcs_length(a, b, rows)
}

cost :: proc(c: diff.Changes) -> int {
	s := diff.stats(c)
	return s.deleted + s.inserted
}

/*
	Checks that `c` is a valid diff of `a` and `b`: the tokens left unmarked on each side are the same sequence,
	so `b` can be rebuilt from `a`, and no bit past the end of either side is set.
*/
check_valid :: proc(t: ^testing.T, a, b: []i32, c: diff.Changes, loc := #caller_location) -> bool {
	if !testing.expect(t, c.n == len(a) && c.m == len(b), "changes sized for different inputs", loc = loc) {
		return false
	}
	if !testing.expect(t, len(c.bits) == diff.changes_size(c.n, c.m), "changes have the wrong number of words", loc = loc) {
		return false
	}

	i, j := 0, 0
	for {
		for i < len(a) && diff.is_deleted(c, i) {
			i += 1
		}
		for j < len(b) && diff.is_inserted(c, j) {
			j += 1
		}
		if i == len(a) || j == len(b) {
			break
		}
		if a[i] != b[j] {
			testing.expectf(t, false, "kept a[%d] = %d does not match kept b[%d] = %d (a = %v, b = %v)", i, a[i], j, b[j], a, b, loc = loc)
			return false
		}
		i += 1
		j += 1
	}
	if i != len(a) || j != len(b) {
		testing.expectf(t, false, "kept tokens left over: a[%d:], b[%d:] (a = %v, b = %v)", i, j, a, b, loc = loc)
		return false
	}

	a_words := (c.n + 63) / 64
	b_words := (c.m + 63) / 64
	for k in c.n..<a_words*64 {
		if c.bits[k >> 6] & (u64(1) << uint(k & 63)) != 0 {
			testing.expectf(t, false, "padding bit %d set on the a side", k, loc = loc)
			return false
		}
	}
	for k in c.m..<b_words*64 {
		bit := a_words*64 + k
		if c.bits[bit >> 6] & (u64(1) << uint(bit & 63)) != 0 {
			testing.expectf(t, false, "padding bit %d set on the b side", k, loc = loc)
			return false
		}
	}
	return true
}

@(require_results)
id_count_of :: proc(a, b: []i32) -> (count: int) {
	for x in a {
		count = max(count, int(x) + 1)
	}
	for x in b {
		count = max(count, int(x) + 1)
	}
	return
}

// Diffs with scratch of exactly the size asked for.
@(require_results)
diff_exact :: proc(a, b: []i32, opts := diff.Options{}) -> diff.Changes {
	id_count := id_count_of(a, b)
	c := must(diff.changes_make(len(a), len(b), context.allocator))

	scratch := make([]byte, diff.scratch_size_interned(len(a), len(b), id_count, opts))
	defer delete(scratch)

	diff.diff_interned_buffer(a, b, id_count, c, scratch, opts)
	return c
}

// The options every pair is checked under: exact, default cap, caps small enough to be hit at once, and the other algorithms.
@(rodata)
PAIR_OPTIONS := [?]diff.Options{
	{algorithm = .Minimal},
	{algorithm = .Minimal, max_cost = 1}, // `.Minimal` ignores the cap
	{algorithm = .Myers},
	{algorithm = .Myers, max_cost = 1},
	{algorithm = .Myers, max_cost = 3},
	{algorithm = .Histogram},
	{algorithm = .Histogram, max_cost = 1}, // for its fallback to Myers
	{algorithm = .Ratcliff_Obershelp},
	{algorithm = .Ratcliff_Obershelp, max_cost = 1}, // a budget so small that Myers takes over
	{algorithm = .Myers,              flags = {.Prune}},
	{algorithm = .Minimal,            flags = {.Prune}},
	{algorithm = .Histogram,          flags = {.Prune}},
	{algorithm = .Ratcliff_Obershelp, flags = {.Prune}},
	{algorithm = .Myers,              flags = {.Compact}}, // sliding changes never changes how many there are
	{algorithm = .Minimal,            flags = {.Compact}},
	{algorithm = .Histogram,          flags = {.Compact}},
	{algorithm = .Myers,              flags = {.Prune, .Compact}},

	// Combinations git has no equivalent for
	{algorithm = .Histogram,          flags = {.Compact}, max_cost = 1}, // merged groups are diffed again under the cap
	{algorithm = .Histogram,          flags = {.Prune, .Compact}},
	{algorithm = .Ratcliff_Obershelp, flags = {.Compact}},
	{algorithm = .Ratcliff_Obershelp, flags = {.Prune, .Compact}},
}

/*
	Whether the diff must be minimal. `.Myers` with its default cap is minimal as long as the search never reaches
	256 edits, where the cap and the snake heuristic start: true for any minimal diff of up to 2*256 tokens.
	`.Prune` keeps `.Minimal` minimal, but can set aside tokens `.Myers` would have matched.
	The other algorithms are never promised to be minimal.
*/
must_be_minimal :: proc(opts: diff.Options, expected: int) -> bool {
	switch opts.algorithm {
	case .Minimal:
		return true

	case .Myers:
		return opts.max_cost == 0       &&
		       .Prune not_in opts.flags &&
		       expected <= 2*256

	case .Histogram, .Ratcliff_Obershelp:
		return false
	}
	return false
}

// Checks the cost of a valid diff: minimal where it must be, never below minimal.
check_cost :: proc(t: ^testing.T, a, b: []i32, c: diff.Changes, opts: diff.Options, expected: int, loc := #caller_location) -> bool {
	if must_be_minimal(opts, expected) {
		return testing.expectf(t, cost(c) == expected, "%v: cost %d, expected %d (a = %v, b = %v)", opts, cost(c), expected, a, b, loc = loc)
	}
	return testing.expectf(t, cost(c) >= expected, "%v: cost %d below minimal %d (a = %v, b = %v)", opts, cost(c), expected, a, b, loc = loc)
}

// Checks one pair under every option set in `PAIR_OPTIONS`.
check_pair :: proc(t: ^testing.T, a, b: []i32, loc := #caller_location) -> bool {
	expected := minimal_cost(a, b)
	for opts in PAIR_OPTIONS {
		c := diff_exact(a, b, opts)
		defer diff.changes_destroy(c, context.allocator)
		check_valid(t, a, b, c, loc) or_return
		check_cost(t, a, b, c, opts, expected, loc) or_return
	}
	return true
}

// Writes the base-`base` digits of `code` into `out`.
decode :: proc(code, base: int, out: []i32) {
	code := code
	for &x in out {
		x = i32(code % base)
		code /= base
	}
}

// Every pair of sequences over `alphabet` symbols, each up to `max_len` long.
check_exhaustive :: proc(t: ^testing.T, alphabet, max_len: int, opts := diff.Options{algorithm = .Minimal}) {
	a_buf := make([]i32, max_len)
	defer delete(a_buf)
	b_buf := make([]i32, max_len)
	defer delete(b_buf)

	bits    := make([]u64, diff.changes_size(max_len, max_len))
	defer delete(bits)
	scratch := make([]byte, diff.scratch_size_interned(max_len, max_len, alphabet, opts))
	defer delete(scratch)
	rows    := make([]int, 2*(max_len + 1))
	defer delete(rows)

	for len_a in 0..=max_len {
		for code_a in 0..<count_of(alphabet, len_a) {
			a := a_buf[:len_a]
			decode(code_a, alphabet, a)
			for len_b in 0..=max_len {
				for code_b in 0..<count_of(alphabet, len_b) {
					b := b_buf[:len_b]
					decode(code_b, alphabet, b)

					c := diff.changes_from_buffer(len_a, len_b, bits)
					diff.diff_interned_buffer(a, b, alphabet, c, scratch[:diff.scratch_size_interned(len_a, len_b, alphabet, opts)], opts)
					if !check_valid(t, a, b, c) {
						return
					}
					if !check_cost(t, a, b, c, opts, minimal_cost(a, b, rows)) {
						return
					}
				}
			}
		}
	}
}

count_of :: proc(alphabet, length: int) -> int {
	n := 1
	for _ in 0..<length {
		n *= alphabet
	}
	return n
}

random_sequence :: proc(length, alphabet: int) -> []i32 {
	s := make([]i32, length)
	for &x in s {
		x = i32(rand.int_max(alphabet))
	}
	return s
}

// Applies `edits` random insertions, deletions and replacements to `base`.
mutate :: proc(base: []i32, edits, alphabet: int) -> []i32 {
	out := make([dynamic]i32, 0, len(base) + edits)
	append(&out, ..base)
	for _ in 0..<edits {
		switch rand.int_max(3) {
		case 0:
			inject_at(&out, rand.int_max(len(out) + 1), i32(rand.int_max(alphabet)))
		case 1:
			if len(out) > 0 {
				ordered_remove(&out, rand.int_max(len(out)))
			}
		case 2:
			if len(out) > 0 {
				out[rand.int_max(len(out))] = i32(rand.int_max(alphabet))
			}
		}
	}
	defer delete(out)
	return slice.clone(out[:])
}


/*
	Tests
*/

@(test)
test_empty_and_identical :: proc(t: ^testing.T) {
	x := []i32{1, 2, 3, 4}
	y := []i32{5, 6, 7}

	check_pair(t, nil, nil)
	check_pair(t, nil, x)
	check_pair(t, x, nil)
	check_pair(t, x, x)
	check_pair(t, x, y)

	c := diff_exact(x, x)
	defer diff.changes_destroy(c, context.allocator)
	testing.expect_value(t, diff.stats(c), diff.Stats{equal = 4})

	c_disjoint := diff_exact(x, y)
	defer diff.changes_destroy(c_disjoint, context.allocator)
	testing.expect_value(t, diff.stats(c_disjoint), diff.Stats{deleted = 4, inserted = 3})
}

// The example from Myers' paper: "ABCABBA" against "CBABAC" has a minimal diff of 5.
@(test)
test_myers_paper_example :: proc(t: ^testing.T) {
	A, B, C :: 0, 1, 2
	a := []i32{A, B, C, A, B, B, A}
	b := []i32{C, B, A, B, A, C}

	check_pair(t, a, b)
	check_pair(t, b, a)

	c := diff_exact(a, b, {algorithm = .Minimal})
	defer diff.changes_destroy(c, context.allocator)
	testing.expect_value(t, cost(c), 5)
}

@(test)
test_minimal_exhaustive_binary :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 8)
}

@(test)
test_minimal_exhaustive_ternary :: proc(t: ^testing.T) {
	check_exhaustive(t, 3, 5)
}

// Small diffs never reach the default cap, so `.Myers` must still be minimal.
@(test)
test_myers_exhaustive_binary :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 7, {algorithm = .Myers})
}

// Caps this small are hit on almost every split.
@(test)
test_cost_cap_exhaustive :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 7, {algorithm = .Myers, max_cost = 1})
	check_exhaustive(t, 3, 4, {algorithm = .Myers, max_cost = 2})
}

/*
	Long inputs with many sparse edits. Past 65k tokens the default cap rises to 512, which leaves room
	for the snake heuristic after 256 edits; a cap of 64 is hit instead.
*/
@(test)
test_cost_cap_heuristics :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for edits in ([?]int{800, 1600}) {
		a := random_sequence(40_000, 100_000)
		defer delete(a)
		b := mutate(a, edits, 100_000)
		defer delete(b)

		// Too big for `minimal_cost`; `.Minimal` is checked against it everywhere else
		minimal := diff_exact(a, b, {algorithm = .Minimal})
		defer diff.changes_destroy(minimal, context.allocator)
		check_valid(t, a, b, minimal)
		expected := cost(minimal)

		for opts in ([?]diff.Options{{algorithm = .Myers}, {algorithm = .Myers, max_cost = 64}}) {
			c := diff_exact(a, b, opts)
			defer diff.changes_destroy(c, context.allocator)
			check_valid(t, a, b, c)
			check_cost(t, a, b, c, opts, expected)
		}
	}
}

// Nothing in common, far past the cap: without it this would take O((n+m)^2) time.
@(test)
test_cost_cap_disjoint :: proc(t: ^testing.T) {
	a := make([]i32, 20_000)
	defer delete(a)
	b := make([]i32, 20_000)
	defer delete(b)
	for i in 0..<len(a) {
		a[i] = 0
		b[i] = 1
	}

	c := diff_exact(a, b, {algorithm = .Myers})
	defer diff.changes_destroy(c, context.allocator)
	check_valid(t, a, b, c)
	testing.expect_value(t, cost(c), 40_000)
}

@(test)
test_random :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<300 {
		alphabet := 2 + rand.int_max(7)
		a := random_sequence(rand.int_max(121), alphabet)
		defer delete(a)
		b := random_sequence(rand.int_max(121), alphabet)
		defer delete(b)
		if !check_pair(t, a, b) {
			return
		}
	}
}

@(test)
test_random_mutations :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<300 {
		alphabet := 1 + rand.int_max(20)
		edits    := rand.int_max(30)
		a := random_sequence(rand.int_max(201), alphabet)
		defer delete(a)
		b := mutate(a, edits, alphabet)
		defer delete(b)
		if !check_pair(t, a, b) {
			return
		}

		c := diff_exact(a, b, {algorithm = .Minimal})
		defer diff.changes_destroy(c, context.allocator)
		testing.expectf(t, cost(c) <= 2*edits, "cost %d above the %d edits made", cost(c), 2*edits)
	}
}

@(test)
test_large :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	// Few changes in a long input: exercises deep splits and the stack bound
	{
		a := random_sequence(20_000, 50)
		defer delete(a)
		b := mutate(a, 50, 50)
		defer delete(b)

		c := diff_exact(a, b, {algorithm = .Minimal})
		defer diff.changes_destroy(c, context.allocator)
		check_valid(t, a, b, c)
		testing.expectf(t, cost(c) <= 100, "cost %d above the 100 edits made", cost(c))
	}

	// [0, 1, 0, 1, ...] against [1, 0, 1, 0, ...]: drop the first token, add one at the end
	{
		a := make([]i32, 10_000)
		defer delete(a)
		b := make([]i32, 10_000)
		defer delete(b)
		for i in 0..<len(a) {
			a[i] = i32(i & 1)
			b[i] = i32((i + 1) & 1)
		}

		c := diff_exact(a, b, {algorithm = .Minimal})
		defer diff.changes_destroy(c, context.allocator)
		check_valid(t, a, b, c)
		testing.expect_value(t, cost(c), 2)
	}

	// Nothing in common
	{
		a := make([]i32, 2_000)
		defer delete(a)
		b := make([]i32, 2_000)
		defer delete(b)
		for i in 0..<len(a) {
			a[i] = 0
			b[i] = 1
		}

		c := diff_exact(a, b, {algorithm = .Minimal})
		defer diff.changes_destroy(c, context.allocator)
		check_valid(t, a, b, c)
		testing.expect_value(t, cost(c), 4_000)
	}
}

// Scratch of exactly the size asked for must work at every alignment.
@(test)
test_scratch_alignment :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_sequence(300, 5)
	defer delete(a)
	b := mutate(a, 40, 5)
	defer delete(b)

	opts := diff.Options{algorithm = .Minimal}
	size := diff.scratch_size_interned(len(a), len(b), 5, opts)
	buf  := make([]byte, size + 16)
	defer delete(buf)

	expected := minimal_cost(a, b)
	for offset in 0..<16 {
		c := must(diff.changes_make(len(a), len(b), context.allocator))
		defer diff.changes_destroy(c, context.allocator)
		diff.diff_interned_buffer(a, b, 5, c, buf[offset:][:size], opts)
		check_valid(t, a, b, c)
		testing.expect_value(t, cost(c), expected)
	}
}

@(test)
test_stats_and_similarity :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a := random_sequence(500, 4)
	defer delete(a)
	b := mutate(a, 60, 4)
	defer delete(b)

	c := diff_exact(a, b)
	defer diff.changes_destroy(c, context.allocator)
	s := diff.stats(c)
	testing.expect_value(t, s.equal, len(a) - s.deleted)
	testing.expect_value(t, s.equal, len(b) - s.inserted)
	testing.expectf(t, 0 <= diff.similarity(c) && diff.similarity(c) <= 1, "similarity %v out of range", diff.similarity(c))

	empty := diff_exact(nil, nil)
	defer diff.changes_destroy(empty, context.allocator)
	testing.expect_value(t, diff.similarity(empty), 1)

	same := diff_exact(a, a)
	defer diff.changes_destroy(same, context.allocator)
	testing.expect_value(t, diff.similarity(same), 1)

	x := []i32{1, 1, 1}
	y := []i32{2, 2}
	disjoint := diff_exact(x, y)
	defer diff.changes_destroy(disjoint, context.allocator)
	testing.expect_value(t, diff.similarity(disjoint), 0)
}
