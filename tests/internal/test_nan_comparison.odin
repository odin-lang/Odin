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

@(test)
compare_variable_nans_f32 :: proc(t: ^testing.T) {
	NaN     := f32(0h7fc0_0000)
	NaN2    := f32(0h7fc0_0001)
	Inf     := f32(0h7F80_0000)
	Neg_Inf := f32(0hFF80_0000)

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
compare_variable_nans_f64 :: proc(t: ^testing.T) {
	NaN     := f64(0h7fff_0000_0000_0000)
	NaN2    := f64(0h7fff_0000_0000_0001)
	Inf     := f64(0h7FF0_0000_0000_0000)
	Neg_Inf := f64(0hFFF0_0000_0000_0000)

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

// A complex or quaternion compares componentwise, so a NaN in any one lane makes the whole
// comparison fail. The folded form used to disagree: `cmp_f64` is `(a>b)-(a<b)`, which
// answers 0 for a NaN -- the same value it uses for "equal".

@(test)
compare_constant_nans_complex :: proc(t: ^testing.T) {
	NaN :: f64(0h7fff_0000_0000_0000)
	Re  :: complex(NaN, 0)
	Im  :: complex(0, NaN)

	testing.expect_value(t, Re == Re, false)
	testing.expect_value(t, Re != Re, true)
	testing.expect_value(t, Im == Im, false)
	testing.expect_value(t, Im != Im, true)
	testing.expect_value(t, Re == Im, false)
	testing.expect_value(t, Re == 0,  false)
	testing.expect_value(t, Re != 0,  true)
	testing.expect_value(t, 0 == Re,  false)

	testing.expect_value(t, complex(f32(0h7fc0_0000), 0) == complex(f32(0h7fc0_0000), 0), false)
	testing.expect_value(t, complex(f16(0h7e00), 0)      == complex(f16(0h7e00), 0),      false)
}

@(test)
compare_variable_nans_complex :: proc(t: ^testing.T) {
	NaN := f64(0h7fff_0000_0000_0000)
	Re  := complex(NaN, 0)
	Im  := complex(0, NaN)

	testing.expect_value(t, Re == Re, false)
	testing.expect_value(t, Re != Re, true)
	testing.expect_value(t, Im == Im, false)
	testing.expect_value(t, Im != Im, true)
	testing.expect_value(t, Re == Im, false)
	testing.expect_value(t, Re == 0,  false)
	testing.expect_value(t, Re != 0,  true)
	testing.expect_value(t, 0 == Re,  false)

	c64 := complex(f32(0h7fc0_0000), 0)
	c32 := complex(f16(0h7e00), 0)
	testing.expect_value(t, c64 == c64, false)
	testing.expect_value(t, c32 == c32, false)
}

@(test)
compare_constant_nans_quaternion :: proc(t: ^testing.T) {
	NaN :: f64(0h7fff_0000_0000_0000)

	// one per lane: real, imag, jmag, kmag
	W :: quaternion(w=NaN, x=0, y=0, z=0)
	X :: quaternion(w=0, x=NaN, y=0, z=0)
	Y :: quaternion(w=0, x=0, y=NaN, z=0)
	Z :: quaternion(w=0, x=0, y=0, z=NaN)

	testing.expect_value(t, W == W, false)
	testing.expect_value(t, X == X, false)
	testing.expect_value(t, Y == Y, false)
	testing.expect_value(t, Z == Z, false)
	testing.expect_value(t, W != W, true)
	testing.expect_value(t, X != X, true)
	testing.expect_value(t, Y != Y, true)
	testing.expect_value(t, Z != Z, true)
	testing.expect_value(t, W == 0, false)
	testing.expect_value(t, W != 0, true)
	testing.expect_value(t, 0 == Z, false)

	testing.expect_value(t, quaternion(w=f32(0h7fc0_0000), x=0, y=0, z=0) == quaternion(w=f32(0h7fc0_0000), x=0, y=0, z=0), false)
	testing.expect_value(t, quaternion(w=f16(0h7e00), x=0, y=0, z=0)      == quaternion(w=f16(0h7e00), x=0, y=0, z=0),      false)
}

@(test)
compare_variable_nans_quaternion :: proc(t: ^testing.T) {
	NaN := f64(0h7fff_0000_0000_0000)

	W := quaternion(w=NaN, x=0, y=0, z=0)
	X := quaternion(w=0, x=NaN, y=0, z=0)
	Y := quaternion(w=0, x=0, y=NaN, z=0)
	Z := quaternion(w=0, x=0, y=0, z=NaN)

	testing.expect_value(t, W == W, false)
	testing.expect_value(t, X == X, false)
	testing.expect_value(t, Y == Y, false)
	testing.expect_value(t, Z == Z, false)
	testing.expect_value(t, W != W, true)
	testing.expect_value(t, X != X, true)
	testing.expect_value(t, Y != Y, true)
	testing.expect_value(t, Z != Z, true)
	testing.expect_value(t, W == 0, false)
	testing.expect_value(t, W != 0, true)
	testing.expect_value(t, 0 == Z, false)

	q128 := quaternion(w=f32(0h7fc0_0000), x=0, y=0, z=0)
	q64  := quaternion(w=f16(0h7e00), x=0, y=0, z=0)
	testing.expect_value(t, q128 == q128, false)
	testing.expect_value(t, q64  == q64,  false)
}
