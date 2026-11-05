package test_issue_7822

import "core:testing"

// Indexing a '#load'ed slice constant with a constant index read a single byte at that index, whatever the
// element type. Elements over 32 bytes crashed the compiler and smaller ones had the wrong value. Elements
// wider than a byte are now read from the loaded data, and the index is bounds checked against the element count.

B :: struct {
	b: [33]u8,
}

DATA :: #load("bytes.dat", []B)

@(test)
test_load_struct_index :: proc(t: ^testing.T) {
	first  := DATA[0]
	second := #load("bytes.dat", []B)[1]
	testing.expect_value(t, first.b[0],   0)
	testing.expect_value(t, first.b[32],  32)
	testing.expect_value(t, second.b[0],  33)
	testing.expect_value(t, second.b[32], 65)
}

@(test)
test_load_integer_index :: proc(t: ^testing.T) {
	WORDS :: #load("bytes.dat", []u32le)
	testing.expect_value(t, WORDS[1], 0x07060504)
	testing.expect_value(t, WORDS[15], 0x3f3e3d3c)

	#assert(#load("bytes.dat")[3] == 3)
}
