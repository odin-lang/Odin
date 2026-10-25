package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:testing"

/*
	Harness
*/

/*
	`.Compact` handles `b`'s side last. After it, a group of insertions that could still slide down must have a
	partner: deletions between the same two kept tokens. Otherwise it would have slid down as far as it goes.
*/
check_settled :: proc(t: ^testing.T, a, b: []i32, c: diff.Changes, opts: diff.Options, loc := #caller_location) -> bool {
	i, j := 0, 0
	for {
		a_end := i
		for a_end < len(a) && diff.is_deleted(c, a_end) {
			a_end += 1
		}
		b_end := j
		for b_end < len(b) && diff.is_inserted(c, b_end) {
			b_end += 1
		}
		can_slide := j < b_end && b_end < len(b) && b[j] == b[b_end]
		testing.expectf(t, !can_slide || i < a_end, "%v: b[%d:%d] could slide down, with no deletions beside it (a = %v, b = %v)", opts, j, b_end, a, b, loc = loc) or_return

		if a_end == len(a) || b_end == len(b) {
			return true
		}
		i, j = a_end + 1, b_end + 1
	}
}


/*
	Tests
*/

@(test)
test_compact_exhaustive :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 7, {algorithm = .Minimal,   flags = {.Compact}})
	check_exhaustive(t, 2, 7, {algorithm = .Histogram, flags = {.Compact}})
}

// Histogram is left out. Diffing merged groups again can leave them anywhere.
@(test)
test_compact_settles_groups :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<300 {
		alphabet := 1 + rand.int_max(5)
		a := random_sequence(rand.int_max(200), alphabet)
		defer delete(a)
		b := mutate(a, rand.int_max(40), alphabet)
		defer delete(b)
		for algorithm in ([?]diff.Algorithm{.Myers, .Minimal, .Ratcliff_Obershelp}) {
			for flags in ([?]diff.Option_Flags{{.Compact}, {.Prune, .Compact}}) {
				opts := diff.Options{algorithm = algorithm, flags = flags}
				c := diff_exact(a, b, opts)
				defer diff.changes_destroy(c, context.allocator)
				if !check_valid(t, a, b, c) || !check_settled(t, a, b, c, opts) {
					return
				}
			}
		}
	}
}

// A group that can slide is left as far down as it goes.
@(test)
test_compact_slides_down :: proc(t: ^testing.T) {
	for algorithm in diff.Algorithm {
		// Inserting `2 3` after `1 2 3` could be at either copy: it goes to the last
		{
			a := []i32{1, 2, 3}
			b := []i32{1, 2, 3, 2, 3}
			c := diff_exact(a, b, {algorithm = algorithm, flags = {.Compact}})
			defer diff.changes_destroy(c, context.allocator)
			testing.expectf(t, diff.is_inserted(c, 3) && diff.is_inserted(c, 4) && !diff.is_inserted(c, 1), "%v: the insertion did not slide down", algorithm)
		}

		// Deleting one of two `2`s deletes the second
		{
			a := []i32{1, 2, 2, 3}
			b := []i32{1, 2, 3}
			c := diff_exact(a, b, {algorithm = algorithm, flags = {.Compact}})
			defer diff.changes_destroy(c, context.allocator)
			testing.expectf(t, diff.is_deleted(c, 2) && !diff.is_deleted(c, 1), "%v: the deletion did not slide down", algorithm)
		}
	}
}

// Sliding never changes how many tokens change, except where Histogram diffs merged groups again.
@(test)
test_compact_keeps_cost :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<200 {
		alphabet := 1 + rand.int_max(6)
		a := random_sequence(rand.int_max(150), alphabet)
		defer delete(a)
		b := mutate(a, rand.int_max(30), alphabet)
		defer delete(b)
		for algorithm in diff.Algorithm {
			plain := diff_exact(a, b, {algorithm = algorithm})
			defer diff.changes_destroy(plain, context.allocator)
			compacted := diff_exact(a, b, {algorithm = algorithm, flags = {.Compact}})
			defer diff.changes_destroy(compacted, context.allocator)

			if algorithm == .Histogram {
				testing.expectf(t, cost(compacted) <= cost(plain), "Histogram: compacting grew the diff from %d to %d", cost(plain), cost(compacted))
			} else {
				testing.expectf(t, cost(compacted) == cost(plain), "%v: compacting changed the cost from %d to %d", algorithm, cost(plain), cost(compacted))
			}
		}
	}
}

@(test)
test_compact_text :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	for _ in 0..<100 {
		a := random_text(rand.int_max(80))
		b := mutate_lines(a, rand.int_max(20))
		if !check_text_matches_lines(t, a, b, {}, {flags = {.Prune, .Compact}}) {
			return
		}
		if !check_unified(t, a, b, 3) {
			return
		}
	}
}
