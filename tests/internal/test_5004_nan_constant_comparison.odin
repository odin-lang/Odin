package test_internal

import "core:testing"

@(test)
compare_constant_nans_f32 :: proc(t: ^testing.T) {
	NaN     :: f32(0h7fc0_0000)
	NaN2    :: f32(0h7fc0_0001)
	Inf     :: f32(0h7F80_0000)
	Neg_Inf :: f32(0hFF80_0000)

	testing.expect_value(t, NaN == NaN,     false)
	testing.expect_value(t, NaN == NaN2,    false)
	testing.expect_value(t, NaN != 0,       true)
	testing.expect_value(t, NaN != 5,       true)
	testing.expect_value(t, NaN != -5,      true)
	testing.expect_value(t, NaN != NaN,     true)
	testing.expect_value(t, NaN != NaN2,    true)
	testing.expect_value(t, NaN != Inf,     true)
	testing.expect_value(t, NaN != Neg_Inf, true)
	testing.expect_value(t, NaN <  NaN,     false)
	testing.expect_value(t, NaN <= NaN,     false)
	testing.expect_value(t, NaN >  NaN,     false)
	testing.expect_value(t, NaN >= NaN,     false)
}

@(test)
compare_constant_nans_f64 :: proc(t: ^testing.T) {
	NaN     :: f64(0h7fff_0000_0000_0000)
	NaN2    :: f64(0h7fff_0000_0000_0001)
	Inf     :: f64(0h7FF0_0000_0000_0000)
	Neg_Inf :: f64(0hFFF0_0000_0000_0000)

	testing.expect_value(t, NaN == NaN,     false)
	testing.expect_value(t, NaN == NaN2,    false)
	testing.expect_value(t, NaN != 0,       true)
	testing.expect_value(t, NaN != 5,       true)
	testing.expect_value(t, NaN != -5,      true)
	testing.expect_value(t, NaN != NaN,     true)
	testing.expect_value(t, NaN != NaN2,    true)
	testing.expect_value(t, NaN != Inf,     true)
	testing.expect_value(t, NaN != Neg_Inf, true)
	testing.expect_value(t, NaN <  NaN,     false)
	testing.expect_value(t, NaN <= NaN,     false)
	testing.expect_value(t, NaN >  NaN,     false)
	testing.expect_value(t, NaN >= NaN,     false)
}
