package test_internal

import "core:testing"

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
small_bump :: proc(x: ^int) -> int {
	x^ += 100
	return x^
}

@(test)
multi_assign_blank_large :: proc(t: ^testing.T) {
	a, b := large(1), large(2)
	a, _ = b, large_bump(&b)
	testing.expect_value(t, large_tagged(a), 2)
	testing.expect_value(t, large_tagged(b), 102)

	c := large(3)
	_, a = large_bump(&c), c
	testing.expect_value(t, large_tagged(a), 103)
	testing.expect_value(t, large_tagged(c), 103)

	d := large(4)
	_, a, _ = large(0), d, large_bump(&d)
	testing.expect_value(t, large_tagged(a), 4)
	testing.expect_value(t, large_tagged(d), 104)
}

@(test)
multi_assign_blank_map_target :: proc(t: ^testing.T) {
	m := make(map[int]Large)
	defer delete(m)
	b := large(5)
	m[0], _ = b, large_bump(&b)
	testing.expect_value(t, large_tagged(m[0]), 5)
	testing.expect_value(t, large_tagged(b), 105)

	n := make(map[int]int)
	defer delete(n)
	x := 6
	n[0], _ = x, small_bump(&x)
	testing.expect_value(t, n[0], 6)
	testing.expect_value(t, x, 106)
}
