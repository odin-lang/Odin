package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:slice"
import "core:testing"

/*
	Harness: the documented steps of `.Prune`, for inputs where its rule for frequent tokens sets nothing aside.
	The git fixtures check that rule.
*/

/*
	`.Prune` must give what its steps give, done the long way: set aside the common prefix and suffix, then every
	token absent from the other side, and diff what is left with the same algorithm.
*/
check_prune_steps :: proc(t: ^testing.T, a, b: []i32, algorithm: diff.Algorithm, loc := #caller_location) -> bool {
	n, m := len(a), len(b)

	prefix := 0
	for prefix < min(n, m) && a[prefix] == b[prefix] {
		prefix += 1
	}
	suffix := 0
	for suffix < min(n, m) - prefix && a[n-1-suffix] == b[m-1-suffix] {
		suffix += 1
	}

	deleted  := make([]bool, n, context.temp_allocator)
	inserted := make([]bool, m, context.temp_allocator)
	kept_a   := make([dynamic]i32, context.temp_allocator)
	kept_b   := make([dynamic]i32, context.temp_allocator)
	index_a  := make([dynamic]int, context.temp_allocator)
	index_b  := make([dynamic]int, context.temp_allocator)
	for i in prefix..<n - suffix {
		if slice.contains(b, a[i]) {
			append(&kept_a, a[i])
			append(&index_a, i)
		} else {
			deleted[i] = true
		}
	}
	for j in prefix..<m - suffix {
		if slice.contains(a, b[j]) {
			append(&kept_b, b[j])
			append(&index_b, j)
		} else {
			inserted[j] = true
		}
	}

	kept := diff_exact(kept_a[:], kept_b[:], {algorithm = algorithm})
	defer diff.changes_destroy(kept, context.allocator)
	for i, k in index_a {
		deleted[i] = diff.is_deleted(kept, k)
	}
	for j, k in index_b {
		inserted[j] = diff.is_inserted(kept, k)
	}

	c := diff_exact(a, b, {algorithm = algorithm, flags = {.Prune}})
	defer diff.changes_destroy(c, context.allocator)
	for i in 0..<n {
		testing.expectf(t, diff.is_deleted(c, i) == deleted[i], "%v: a[%d] deleted %v, expected %v (a = %v, b = %v)", algorithm, i, diff.is_deleted(c, i), deleted[i], a, b, loc = loc) or_return
	}
	for j in 0..<m {
		testing.expectf(t, diff.is_inserted(c, j) == inserted[j], "%v: b[%d] inserted %v, expected %v (a = %v, b = %v)", algorithm, j, diff.is_inserted(c, j), inserted[j], a, b, loc = loc) or_return
	}
	return true
}

// A few frequent tokens, and tokens found nowhere else among them.
frequent_and_unique :: proc(length, frequent: int, unique_from: i32, unique_chance: int) -> []i32 {
	s := make([]i32, length)
	next_unique := unique_from
	for &x in s {
		if rand.int_max(unique_chance) == 0 {
			x = next_unique
			next_unique += 1
		} else {
			x = i32(rand.int_max(frequent))
		}
	}
	return s
}


/*
	Tests
*/

/*
	With no frequent tokens, `.Prune` only sets aside the common ends and the tokens with no match. Here each token
	occurs at most 3 times, and each side has at least 16. The limit for a frequent token is then 8 or more.
*/
@(test)
test_prune_without_frequent :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<200 {
		// Each of `length/2` tokens 3 times, shuffled, and the first `length` of them
		length := 24 + rand.int_max(200)
		pool   := make([]i32, 3*(length/2))
		defer delete(pool)
		for &x, k in pool {
			x = i32(k / 3)
		}
		rand.shuffle(pool)
		a := pool[:length]

		// Tokens removed, moved, or replaced by new ones found nowhere else
		b := make([dynamic]i32, 0, length)
		defer delete(b)
		append(&b, ..a)
		next := i32(10_000)
		for _ in 0..<rand.int_max(length/4) {
			k := rand.int_max(len(b))
			switch rand.int_max(4) {
			case 0:
				ordered_remove(&b, k)
			case 1:
				x := b[k]
				ordered_remove(&b, k)
				inject_at(&b, rand.int_max(len(b) + 1), x)
			case 2:
				b[k] = next
				next += 1
			case 3:
				inject_at(&b, k, next)
				next += 1
			}
		}

		for algorithm in diff.Algorithm {
			if !check_prune_steps(t, a, b[:], algorithm) {
				return
			}
		}
	}
}

/*
	A frequent token is only set aside among tokens with no match. With every token found on both sides, `.Prune`
	sets aside only the common ends, however frequent the tokens.
*/
@(test)
test_prune_all_matched :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<200 {
		alphabet := 1 + rand.int_max(4)
		a := random_sequence(50 + rand.int_max(400), alphabet)
		defer delete(a)
		b := mutate(a, rand.int_max(60), alphabet)
		defer delete(b)

		all_matched := true
		for x in i32(0)..<i32(alphabet) {
			if slice.contains(a, x) != slice.contains(b, x) {
				all_matched = false
			}
		}
		if !all_matched {
			continue
		}

		for algorithm in diff.Algorithm {
			if !check_prune_steps(t, a, b, algorithm) {
				return
			}
		}
	}
}

// `.Prune` only sets aside tokens with no match when the diff must be minimal.
@(test)
test_prune_minimal_exhaustive :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 7, {algorithm = .Minimal, flags = {.Prune}})
	check_exhaustive(t, 3, 5, {algorithm = .Minimal, flags = {.Prune}})
	check_exhaustive(t, 2, 7, {algorithm = .Myers,   flags = {.Prune}})
}

@(test)
test_prune_edges :: proc(t: ^testing.T) {
	x := []i32{1, 2, 3}
	y := []i32{4, 5}
	check_pair(t, nil, nil)
	check_pair(t, x, x)
	check_pair(t, x, y)

	// Nothing in common: everything is set aside before the algorithm even runs
	c := diff_exact(x, y, {flags = {.Prune}})
	defer diff.changes_destroy(c, context.allocator)
	testing.expect_value(t, diff.stats(c), diff.Stats{deleted = 3, inserted = 2})
}

@(test)
test_prune_text :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<100 {
		a := random_text(rand.int_max(80))
		b := mutate_lines(a, rand.int_max(20))
		if !check_text_matches_lines(t, a, b, {}, {flags = {.Prune}}) {
			return
		}
		if !check_text_matches_lines(t, a, b, {.Ignore_All_Space}, {algorithm = .Histogram, flags = {.Prune}}) {
			return
		}
	}
}
