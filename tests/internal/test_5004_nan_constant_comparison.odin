package test_internal

import "core:testing"

@(test)
compare_constant_nans_f32 :: proc(t: ^testing.T) {
	NaN  :: f32(0h7fc0_0000)
	NaN2 :: f32(0h7fc0_0001)

	testing.expect_value(t, NaN == NaN,  false)
	testing.expect_value(t, NaN == NaN2, false)
	testing.expect_value(t, NaN != NaN,  false)
	testing.expect_value(t, NaN != NaN2, false)
	testing.expect_value(t, NaN <  NaN,  false)
	testing.expect_value(t, NaN <= NaN,  false)
	testing.expect_value(t, NaN >  NaN,  false)
	testing.expect_value(t, NaN >= NaN,  false)
}

@(test)
compare_constant_nans_f64 :: proc(t: ^testing.T) {
	NaN  :: f64(0h7fff_0000_0000_0000)
	NaN2 :: f64(0h7fff_0000_0000_0001)

	testing.expect_value(t, NaN == NaN,  false)
	testing.expect_value(t, NaN == NaN2, false)
	testing.expect_value(t, NaN != NaN,  false)
	testing.expect_value(t, NaN != NaN2, false)
	testing.expect_value(t, NaN <  NaN,  false)
	testing.expect_value(t, NaN <= NaN,  false)
	testing.expect_value(t, NaN >  NaN,  false)
	testing.expect_value(t, NaN >= NaN,  false)
}