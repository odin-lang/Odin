package test_internal

import "core:testing"

@(private="file")
P :: struct {
	x: f32,
	y: u8,
}

@(private="file")
global := #soa[]P{{1, 2}, {3, 4}}

@(private="file", rodata)
table := #soa[]P{0 = {5, 6}, 2 = {7, 8}}

// Large enough for the columns of what it is a slice of to be staggered
@(private="file")
big := #soa[]P{1023 = {9, 10}}

@(private="file")
sum :: proc(s: #soa[]P) -> (total: f32) {
	for v in s {
		total += v.x
	}
	return
}

// An #soa slice literal is a slice of an #soa array of its elements, as a slice literal is of an array
@(test)
test_soa_slice_literals :: proc(t: ^testing.T) {
	a := #soa[]P{{1, 2}, {3, 4}, {5, 6}}
	testing.expect_value(t, typeid_of(type_of(a)), typeid_of(#soa[]P))
	testing.expect_value(t, len(a), 3)
	testing.expect_value(t, a[2], P{5, 6})

	n := f32(7)
	b := #soa[]P{0 = {n, 1}, 3 = {n + 1, 2}}
	testing.expect_value(t, len(b), 4)
	testing.expect_value(t, b[0], P{7, 1})
	testing.expect_value(t, b[2], P{})
	testing.expect_value(t, b[3], P{8, 2})

	empty := #soa[]P{}
	testing.expect_value(t, typeid_of(type_of(empty)), typeid_of(#soa[]P))
	testing.expect_value(t, len(empty), 0)

	testing.expect_value(t, len(global), 2)
	testing.expect_value(t, global[1], P{3, 4})
	testing.expect_value(t, len(table), 3)
	testing.expect_value(t, table[2], P{7, 8})

	testing.expect_value(t, len(big), 1024)
	testing.expect_value(t, big[1023], P{9, 10})
	testing.expect_value(t, big.y[1023], 10)

	m := #soa[]P{1023 = {n, 3}}
	testing.expect_value(t, m[1023], P{7, 3})
	testing.expect_value(t, m.x[0], 0)

	l := #soa[][2]f32{{1, 2}, {3, 4}}
	testing.expect_value(t, l[1], [2]f32{3, 4})

	testing.expect_value(t, sum(#soa[]P{{1, 0}, {2, 0}}), 3)
}

@(private="file")
FIXED :: #soa[3]P{{1, 2}, {3, 4}, {5, 6}}

@(private="file")
INDEXED :: #soa[4]P{2 = {5, 6}}

@(private="file")
SLICE :: #soa[]P{{7, 8}, {9, 10}}

@(private="file")
LANES :: #soa[2][3]f32{{1, 2, 3}, {4, 5, 6}}

// Indexing an #soa constant with a constant index gives a constant element, as indexing an array constant does
@(test)
test_soa_constant_index :: proc(t: ^testing.T) {
	ELEM :: FIXED[1]
	testing.expect_value(t, ELEM, P{3, 4})
	testing.expect_value(t, FIXED[2], P{5, 6})
	testing.expect_value(t, FIXED[0].y, 2)
	testing.expect_value(t, INDEXED[2], P{5, 6})
	testing.expect_value(t, SLICE[1], P{9, 10})
	testing.expect_value(t, LANES[1], [3]f32{4, 5, 6})
	testing.expect_value(t, LANES[1][2], 6)
}
