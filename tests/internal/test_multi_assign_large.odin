package test_internal

import "core:testing"

// A multiple assignment reads every value before it writes any, also when a value is too large to be
// stored as a first-class aggregate and is copied through memory instead.

@(private="file")
Large :: struct {
	values: [64]u32,
	tag:    u8,
}

@(private="file")
large :: proc(tag: u8) -> (l: Large) {
	for &v, i in l.values {
		v = u32(tag)*1000 + u32(i)
	}
	l.tag = tag
	return
}

@(private="file")
large_tagged :: proc(l: Large) -> u8 {
	for v, i in l.values {
		if v != u32(l.tag)*1000 + u32(i) {
			return 0
		}
	}
	return l.tag
}

@(private="file")
large_bump :: proc(l: ^Large) -> u8 {
	l^ = large(l.tag + 100)
	return l.tag
}

@(private="file")
large_next :: proc(l: Large) -> (Large, bool) {
	return large(l.tag + 1), true
}

@(test)
multi_assign_large_swap :: proc(t: ^testing.T) {
	a, b := large(1), large(2)
	a, b = b, a
	testing.expect_value(t, large_tagged(a), 2)
	testing.expect_value(t, large_tagged(b), 1)

	pa, pb := &a, &b
	pa^, pb^ = pb^, pa^
	testing.expect_value(t, large_tagged(a), 1)
	testing.expect_value(t, large_tagged(b), 2)

	c := large(3)
	a, b, c = b, c, a
	testing.expect_value(t, large_tagged(a), 2)
	testing.expect_value(t, large_tagged(b), 3)
	testing.expect_value(t, large_tagged(c), 1)

	array := [3]Large{large(4), large(5), large(6)}
	array[0], array[2] = array[2], array[0]
	testing.expect_value(t, large_tagged(array[0]), 6)
	testing.expect_value(t, large_tagged(array[1]), 5)
	testing.expect_value(t, large_tagged(array[2]), 4)
}

@(test)
multi_assign_large_reads_before_later_values :: proc(t: ^testing.T) {
	x := large(7)
	a: Large
	tag: u8
	a, tag = x, large_bump(&x)
	testing.expect_value(t, large_tagged(a), 7)
	testing.expect_value(t, tag, 107)
	testing.expect_value(t, large_tagged(x), 107)
}

@(test)
multi_assign_large_multiple_results :: proc(t: ^testing.T) {
	x := large(8)
	ok: bool
	x, ok = large_next(x)
	testing.expect_value(t, large_tagged(x), 9)
	testing.expect(t, ok)

	y := large(10)
	_, x = x, y
	testing.expect_value(t, large_tagged(x), 10)
}

@(test)
multi_assign_large_other_targets :: proc(t: ^testing.T) {
	m := make(map[int]Large)
	defer delete(m)
	m[0] = large(11)
	x := large(12)
	m[0], x = x, m[0]
	testing.expect_value(t, large_tagged(m[0]), 12)
	testing.expect_value(t, large_tagged(x), 11)

	u: union {Large}
	u = large(13)
	u, x = x, u.(Large)
	testing.expect_value(t, large_tagged(u.(Large)), 11)
	testing.expect_value(t, large_tagged(x), 13)

	s: #soa[2]Large
	s[0], s[1] = large(14), large(15)
	s[0], s[1] = s[1], s[0]
	testing.expect_value(t, large_tagged(s[0]), 15)
	testing.expect_value(t, large_tagged(s[1]), 14)
}

@(private="file")
Large_Distinct :: distinct Large

@(test)
multi_assign_large_value_kinds :: proc(t: ^testing.T) {
	a, b := large(16), large(17)
	a, b = large(18), large(19)
	testing.expect_value(t, large_tagged(a), 18)
	testing.expect_value(t, large_tagged(b), 19)

	pick := large_tagged(a) == 18
	a, b = pick ? b : a, a
	testing.expect_value(t, large_tagged(a), 19)
	testing.expect_value(t, large_tagged(b), 18)

	a, b = Large{values = b.values, tag = b.tag}, a
	testing.expect_value(t, large_tagged(a), 18)
	testing.expect_value(t, large_tagged(b), 19)

	d := Large_Distinct(large(20))
	a, d = Large(d), Large_Distinct(a)
	testing.expect_value(t, large_tagged(a), 20)
	testing.expect_value(t, large_tagged(Large(d)), 18)

	m := make(map[int]Large)
	defer delete(m)
	m[0] = large(21)
	ok: bool
	a, ok = m[0]
	testing.expect_value(t, large_tagged(a), 21)
	testing.expect(t, ok)
	a, b = m[1] or_else b, a
	testing.expect_value(t, large_tagged(a), 19)
	testing.expect_value(t, large_tagged(b), 21)

	maybe: Maybe(Large) = large(22)
	a, ok = maybe.?
	testing.expect_value(t, large_tagged(a), 22)
	testing.expect(t, ok)

	u: union {Large, int} = large(23)
	a, ok = u.(Large)
	testing.expect_value(t, large_tagged(a), 23)
	testing.expect(t, ok)

	backing := [2]Large{large(24), large(25)}
	s := backing[:]
	s[0], s[1] = s[1], s[0]
	testing.expect_value(t, large_tagged(s[0]), 25)
	testing.expect_value(t, large_tagged(s[1]), 24)
}

@(private="file")
large_bump_if :: proc(l: ^Large, bump: bool) -> bool {
	if bump {
		l^ = large(l.tag + 100)
	}
	return bump
}

@(test)
multi_assign_large_reads_before_later_branches :: proc(t: ^testing.T) {
	x := large(26)
	a, b: Large
	a, b = x, large_bump_if(&x, true) ? x : large(0)
	testing.expect_value(t, large_tagged(a), 26)
	testing.expect_value(t, large_tagged(b), 126)
}

@(private="file")
Settings :: struct {
	names:  [4][8][64]u8,
	counts: [4]int,
	count:  int,
}

@(test)
multi_assign_large_restores_backups :: proc(t: ^testing.T) {
	s := new(Settings)
	defer free(s)
	s.names[1][2][3] = 'x'
	s.counts[1] = 5
	s.count = 2

	names, counts, count := s.names, s.counts, s.count
	s.names, s.counts, s.count = {}, {}, 0
	s.names, s.counts, s.count = names, counts, count
	testing.expect_value(t, s.names[1][2][3], 'x')
	testing.expect_value(t, s.counts[1], 5)
	testing.expect_value(t, s.count, 2)
}
