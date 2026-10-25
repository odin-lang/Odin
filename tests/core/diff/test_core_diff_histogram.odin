package test_core_diff

import "core:diff"
import "core:math/rand"
import "core:slice"
import "core:strings"
import "core:testing"

/*
	Harness
*/

// Histogram must give exactly what Myers with `.Prune` gives under the same cap.
check_histogram_falls_back :: proc(t: ^testing.T, a, b: []i32, loc := #caller_location) -> bool {
	for max_cost in ([?]int{0, 1, 3}) {
		histogram := diff_exact(a, b, {algorithm = .Histogram, max_cost = max_cost})
		defer diff.changes_destroy(histogram, context.allocator)
		myers := diff_exact(a, b, {algorithm = .Myers, flags = {.Prune}, max_cost = max_cost})
		defer diff.changes_destroy(myers, context.allocator)

		check_valid(t, a, b, histogram, loc) or_return
		testing.expectf(t, slice.equal(histogram.bits, myers.bits), "max_cost %d: the fallback differs from Myers with .Prune (a = %v, b = %v)", max_cost, a, b, loc = loc) or_return
	}
	return true
}


/*
	Tests
*/

@(test)
test_histogram_exhaustive :: proc(t: ^testing.T) {
	check_exhaustive(t, 2, 7, {algorithm = .Histogram})
	check_exhaustive(t, 3, 5, {algorithm = .Histogram})
	check_exhaustive(t, 4, 4, {algorithm = .Histogram})
}

/*
	When every token in common occurs more than 64 times in `a`, Histogram has no anchor. It falls back to Myers
	with `.Prune`, under the same cap.
*/
@(test)
test_histogram_fallback :: proc(t: ^testing.T) {
	{
		a := make([dynamic]i32)
		defer delete(a)
		b := make([dynamic]i32)
		defer delete(b)

		// No common prefix or suffix, and only 0s and 1s, 70 of each, in common
		append(&a, 7)
		append(&b, 8)
		for i in 0..<70 {
			append(&a, 0)
			append(&a, 1)
			append(&b, i32(1 - (i & 1)))
			append(&b, i32(i & 1))
		}
		append(&a, 9)
		check_histogram_falls_back(t, a[:], b[:])
	}

	// Two frequent tokens, among tokens found on one side only. `.Prune` sets those aside.
	rand.reset(t.seed)
	for _ in 0..<20 {
		a := frequent_and_unique(300 + rand.int_max(300), 2, 1_000, 3)
		defer delete(a)
		b := frequent_and_unique(300 + rand.int_max(300), 2, 100_000, 3)
		defer delete(b)
		if !(slice.count(a, 0) > 64 && slice.count(a, 1) > 64) {
			continue
		}
		if !check_histogram_falls_back(t, a, b) {
			return
		}
	}
}

/*
	Histogram only anchors on tokens occurring 65 times or fewer in `a`. Here every token in common occurs more often,
	but one, found once on each side. It is the only anchor. It is always kept.
*/
@(test)
test_histogram_one_anchor :: proc(t: ^testing.T) {
	RARE :: 1_000_000

	rand.reset(t.seed)
	for _ in 0..<50 {
		frequent := 1 + rand.int_max(3)
		x := frequent_and_unique(150*frequent + rand.int_max(200), frequent, 1_000, 3 + rand.int_max(4))
		defer delete(x)
		y := frequent_and_unique(rand.int_max(300), frequent, 100_000, 2 + rand.int_max(4))
		defer delete(y)

		too_rare := false
		for f in 0..<i32(frequent) {
			if slice.count(x, f) <= 65 {
				too_rare = true
			}
		}
		if too_rare {
			continue
		}

		i := rand.int_max(len(x) + 1)
		j := rand.int_max(len(y) + 1)
		a := slice.concatenate([][]i32{x[:i], {RARE}, x[i:]})
		defer delete(a)
		b := slice.concatenate([][]i32{y[:j], {RARE}, y[j:]})
		defer delete(b)

		for flags in ([?]diff.Option_Flags{{}, {.Compact}}) {
			c := diff_exact(a, b, {algorithm = .Histogram, flags = flags})
			defer diff.changes_destroy(c, context.allocator)
			if !testing.expectf(t, !diff.is_deleted(c, i) && !diff.is_inserted(c, j), "%v: the only anchor is not kept (a = %v, b = %v)", flags, a, b) {
				return
			}
		}
	}
}

// Histogram anchors on what is unique: here the moved function, which Myers pairs up by its braces instead.
@(test)
test_histogram_anchors :: proc(t: ^testing.T) {
	a := strings.join({
		"int frobnitz(int foo)",
		"{",
		"    return foo;",
		"}",
		"",
		"int fact(int n)",
		"{",
		"    return n;",
		"}",
		"",
	}, "\n", context.temp_allocator)
	b := strings.join({
		"int fib(int n)",
		"{",
		"    return n;",
		"}",
		"",
		"int frobnitz(int foo)",
		"{",
		"    return foo;",
		"}",
		"",
	}, "\n", context.temp_allocator)

	d := must(diff.diff_text(a, b, context.allocator, context.allocator, opts = {algorithm = .Histogram}))
	defer diff.text_diff_destroy(d, context.allocator)
	s := must(diff.unified(d, context.temp_allocator))
	testing.expectf(t, s ==
		"--- a\n" +
		"+++ b\n" +
		"@@ -1,9 +1,9 @@\n" +
		"+int fib(int n)\n" +
		"+{\n" +
		"+    return n;\n" +
		"+}\n" +
		"+\n" +
		" int frobnitz(int foo)\n" +
		" {\n" +
		"     return foo;\n" +
		" }\n" +
		"-\n" +
		"-int fact(int n)\n" +
		"-{\n" +
		"-    return n;\n" +
		"-}\n",
		"got:\n%s", s)

	// Myers, as in git, keeps the braces and rewrites both functions around them
	myers := must(diff.diff_text(a, b, context.allocator, context.allocator))
	defer diff.text_diff_destroy(myers, context.allocator)
	testing.expect(t, !diff.is_deleted(d.changes, 0), "Histogram did not keep the moved function")
	testing.expect(t, diff.is_deleted(myers.changes, 0), "Myers kept the moved function, meaning this test no longer shows anything")
}
