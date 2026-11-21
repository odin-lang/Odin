package test_internal

import "core:testing"

@(private="file")
Large :: struct {
	values: [64]u32,
	tag:    u8,
}

@(private="file")
Other :: struct {
	values: [24]u64,
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
other :: proc(tag: u8) -> (o: Other) {
	for &v, i in o.values {
		v = u64(tag)*1000 + u64(i)
	}
	o.tag = tag
	return
}

@(private="file")
other_tagged :: proc(o: Other) -> u8 {
	for v, i in o.values {
		if v != u64(o.tag)*1000 + u64(i) {
			return 0
		}
	}
	return o.tag
}

@(test)
multi_assign_copies_any_target_keeps_value :: proc(t: ^testing.T) {
	a, b := large(1), large(2)
	v: any
	v, a = a, b
	a, b = b, a
	c := large(3)
	a, b, c = c, a, b
	testing.expect_value(t, large_tagged((^Large)(v.data)^), 1)
	testing.expect_value(t, large_tagged(a), 3)
	testing.expect_value(t, large_tagged(b), 2)
	testing.expect_value(t, large_tagged(c), 2)
}

@(test)
multi_assign_copies_repeated_rotations :: proc(t: ^testing.T) {
	a, b, c := large(4), large(5), large(6)
	for _ in 0..<4 {
		a, b, c = b, c, a
	}
	testing.expect_value(t, large_tagged(a), 5)
	testing.expect_value(t, large_tagged(b), 6)
	testing.expect_value(t, large_tagged(c), 4)
}

@(test)
multi_assign_copies_mixed_types :: proc(t: ^testing.T) {
	a, b := large(7), large(8)
	p, q := other(9), other(10)
	a, p, b, q = b, q, a, p
	testing.expect_value(t, large_tagged(a), 8)
	testing.expect_value(t, other_tagged(p), 10)
	testing.expect_value(t, large_tagged(b), 7)
	testing.expect_value(t, other_tagged(q), 9)
}

@(test)
multi_assign_copies_fresh_values :: proc(t: ^testing.T) {
	a, b := large(11), large(12)
	a, b = large(13), a
	testing.expect_value(t, large_tagged(a), 13)
	testing.expect_value(t, large_tagged(b), 11)

	a, b = b, large(14)
	testing.expect_value(t, large_tagged(a), 11)
	testing.expect_value(t, large_tagged(b), 14)

	m := make(map[int]Large)
	defer delete(m)
	m[0] = large(15)
	m[0], a = a, m[0]
	testing.expect_value(t, large_tagged(m[0]), 11)
	testing.expect_value(t, large_tagged(a), 15)
}
