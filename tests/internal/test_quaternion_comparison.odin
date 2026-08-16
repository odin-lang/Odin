package test_internal

import "core:testing"

// Each constant case is paired with the same comparison on variables: the folded answer
// has to be the answer the backend produces.

@(test)
compare_constant_quaternions :: proc(t: ^testing.T) {
	I :: quaternion128(0+1i+0j+0k)
	J :: quaternion128(0+0i+1j+0k)
	K :: quaternion128(0+0i+0j+1k)
	R :: quaternion128(1+0i+0j+0k)

	testing.expect_value(t, R == 1,  true)
	testing.expect_value(t, 1 == R,  true)
	testing.expect_value(t, R != 1,  false)
	testing.expect_value(t, I == J,  false)
	testing.expect_value(t, J == K,  false)
	testing.expect_value(t, K == R,  false)
	testing.expect_value(t, I != J,  true)
	testing.expect_value(t, I == I,  true)

	// every lane must take part, not just the real one
	A :: quaternion128(2+3i+4j+5k)
	testing.expect_value(t, A == quaternion128(2+3i+4j+5k), true)
	testing.expect_value(t, A == quaternion128(9+3i+4j+5k), false)
	testing.expect_value(t, A == quaternion128(2+9i+4j+5k), false)
	testing.expect_value(t, A == quaternion128(2+3i+9j+5k), false)
	testing.expect_value(t, A == quaternion128(2+3i+4j+9k), false)

	// promotion of the other operand, from integer, float and complex
	testing.expect_value(t, R == 1.0, true)
	testing.expect_value(t, quaternion128(2+3i+0j+0k) == 2+3i, true)
	testing.expect_value(t, quaternion128(2+3i+0j+0k) == 2+4i, false)

	testing.expect_value(t, quaternion64(0) == 0,  true)
	testing.expect_value(t, quaternion256(0) == 0, true)
	testing.expect_value(t, quaternion128(0) == quaternion128(-0.0), true)
}

@(test)
compare_variable_quaternions :: proc(t: ^testing.T) {
	I := quaternion128(0+1i+0j+0k)
	J := quaternion128(0+0i+1j+0k)
	K := quaternion128(0+0i+0j+1k)
	R := quaternion128(1+0i+0j+0k)

	testing.expect_value(t, R == 1,  true)
	testing.expect_value(t, 1 == R,  true)
	testing.expect_value(t, R != 1,  false)
	testing.expect_value(t, I == J,  false)
	testing.expect_value(t, J == K,  false)
	testing.expect_value(t, K == R,  false)
	testing.expect_value(t, I != J,  true)
	testing.expect_value(t, I == I,  true)

	A := quaternion128(2+3i+4j+5k)
	testing.expect_value(t, A == quaternion128(2+3i+4j+5k), true)
	testing.expect_value(t, A == quaternion128(9+3i+4j+5k), false)
	testing.expect_value(t, A == quaternion128(2+9i+4j+5k), false)
	testing.expect_value(t, A == quaternion128(2+3i+9j+5k), false)
	testing.expect_value(t, A == quaternion128(2+3i+4j+9k), false)

	testing.expect_value(t, R == 1.0, true)
	testing.expect_value(t, quaternion128(2+3i+0j+0k) == 2+3i, true)
	testing.expect_value(t, quaternion128(2+3i+0j+0k) == 2+4i, false)

	q64  := quaternion64(0)
	q256 := quaternion256(0)
	testing.expect_value(t, q64  == 0, true)
	testing.expect_value(t, q256 == 0, true)
	testing.expect_value(t, quaternion128(0) == quaternion128(-0.0), true)
}

@(test)
compare_constant_quaternion_nans :: proc(t: ^testing.T) {
	NaN :: f64(0h7ff8_0000_0000_0000)
	Q   :: quaternion(w=NaN, x=0, y=0, z=0)
	L   :: quaternion(w=0, x=0, y=0, z=NaN)

	testing.expect_value(t, Q == Q, false)
	testing.expect_value(t, Q != Q, true)
	testing.expect_value(t, L == L, false)
	testing.expect_value(t, L != L, true)
	testing.expect_value(t, Q == 0, false)
	testing.expect_value(t, Q != 0, true)
}

@(test)
compare_variable_quaternion_nans :: proc(t: ^testing.T) {
	NaN := f64(0h7ff8_0000_0000_0000)
	Q   := quaternion(w=NaN, x=0, y=0, z=0)
	L   := quaternion(w=0, x=0, y=0, z=NaN)

	testing.expect_value(t, Q == Q, false)
	testing.expect_value(t, Q != Q, true)
	testing.expect_value(t, L == L, false)
	testing.expect_value(t, L != L, true)
	testing.expect_value(t, Q == 0, false)
	testing.expect_value(t, Q != 0, true)
}

@(test)
compare_constant_complex_nans :: proc(t: ^testing.T) {
	NaN :: f64(0h7ff8_0000_0000_0000)
	C   :: complex(NaN, 0)
	D   :: complex(0, NaN)

	testing.expect_value(t, C == C, false)
	testing.expect_value(t, C != C, true)
	testing.expect_value(t, D == D, false)
	testing.expect_value(t, D != D, true)
	testing.expect_value(t, C == 0, false)
	testing.expect_value(t, C != 0, true)
}

@(test)
compare_variable_complex_nans :: proc(t: ^testing.T) {
	NaN := f64(0h7ff8_0000_0000_0000)
	C   := complex(NaN, 0)
	D   := complex(0, NaN)

	testing.expect_value(t, C == C, false)
	testing.expect_value(t, C != C, true)
	testing.expect_value(t, D == D, false)
	testing.expect_value(t, D != D, true)
	testing.expect_value(t, C == 0, false)
	testing.expect_value(t, C != 0, true)
}
