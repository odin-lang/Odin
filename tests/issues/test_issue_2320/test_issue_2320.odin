package test_issue_2320

import "core:testing"

// A constant slice literal in a procedure stored its whole backing array as a single first class aggregate,
// which LLVM splits into a store per element, so a large literal took minutes to compile. The backing array
// is now copied from a constant global instead, and must still be a fresh, writable copy each time.

City :: struct {
	name: string,
	lat:  f64,
	pop:  int,
}

@(test)
test_large_slice_literal_values :: proc(t: ^testing.T) {
	cities := []City{
		{"Tokyo",     35.68, 37_400_000},
		{"Delhi",     28.70, 31_000_000},
		{"Shanghai",  31.23, 27_100_000},
		{"São Paulo", -23.55, 22_000_000},
	}
	testing.expect_value(t, len(cities), 4)
	testing.expect_value(t, cities[0].name, "Tokyo")
	testing.expect_value(t, cities[3].name, "São Paulo")
	testing.expect_value(t, cities[3].lat, -23.55)
	testing.expect_value(t, cities[2].pop, 27_100_000)
}

@(test)
test_large_slice_literal_is_fresh_copy :: proc(t: ^testing.T) {
	for i in 0..<3 {
		s := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
		testing.expect_value(t, s[0], 1)
		testing.expect_value(t, s[15], 16)
		s[0] += 100
		s[15] = i
		testing.expect_value(t, s[0], 101)
		testing.expect_value(t, s[15], i)
	}
}
