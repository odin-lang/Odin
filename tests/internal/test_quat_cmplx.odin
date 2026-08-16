package test_internal

import "core:testing"

// Constant folding of complex and quaternion values, against the answer the backend
// produces. Every constant case is paired with the same expression on variables: the
// folded answer and the runtime answer are the same contract, and where they diverged
// the folded one was always the wrong side.

@(test)
constant_complex_comparison :: proc(t: ^testing.T) {
	A :: complex128(2+3i)

	testing.expect_value(t, A == complex128(2+3i), true)
	testing.expect_value(t, A != complex128(2+3i), false)
	testing.expect_value(t, A == complex128(9+3i), false)
	testing.expect_value(t, A == complex128(2+9i), false)
	testing.expect_value(t, A != complex128(2+9i), true)

	// promotion of an untyped operand, both orders
	R :: complex128(5+0i)
	testing.expect_value(t, R == 5,   true)
	testing.expect_value(t, 5 == R,   true)
	testing.expect_value(t, R == 5.0, true)
	testing.expect_value(t, R != 5,   false)
	testing.expect_value(t, R == 6,   false)

	// every width
	testing.expect_value(t, complex32(2+3i)  == complex32(2+3i),  true)
	testing.expect_value(t, complex64(2+3i)  == complex64(2+3i),  true)
	testing.expect_value(t, complex128(2+3i) == complex128(2+3i), true)
	testing.expect_value(t, complex32(2+3i)  == complex32(2+4i),  false)

	testing.expect_value(t, complex128(0) == complex128(-0.0), true)
}

@(test)
variable_complex_comparison :: proc(t: ^testing.T) {
	A := complex128(2+3i)

	testing.expect_value(t, A == complex128(2+3i), true)
	testing.expect_value(t, A != complex128(2+3i), false)
	testing.expect_value(t, A == complex128(9+3i), false)
	testing.expect_value(t, A == complex128(2+9i), false)
	testing.expect_value(t, A != complex128(2+9i), true)

	R := complex128(5+0i)
	testing.expect_value(t, R == 5,   true)
	testing.expect_value(t, 5 == R,   true)
	testing.expect_value(t, R == 5.0, true)
	testing.expect_value(t, R != 5,   false)
	testing.expect_value(t, R == 6,   false)

	c32  := complex32(2+3i)
	c64  := complex64(2+3i)
	c128 := complex128(2+3i)
	testing.expect_value(t, c32  == complex32(2+3i),  true)
	testing.expect_value(t, c64  == complex64(2+3i),  true)
	testing.expect_value(t, c128 == complex128(2+3i), true)
	testing.expect_value(t, c32  == complex32(2+4i),  false)

	z := complex128(0)
	testing.expect_value(t, z == complex128(-0.0), true)
}

@(test)
constant_quaternion_comparison :: proc(t: ^testing.T) {
	A :: quaternion256(1+2i+3j+4k)

	testing.expect_value(t, A == quaternion256(1+2i+3j+4k), true)
	testing.expect_value(t, A != quaternion256(1+2i+3j+4k), false)

	// each lane on its own, so a compare that ignores one cannot pass
	testing.expect_value(t, A == quaternion256(9+2i+3j+4k), false)
	testing.expect_value(t, A == quaternion256(1+9i+3j+4k), false)
	testing.expect_value(t, A == quaternion256(1+2i+9j+4k), false)
	testing.expect_value(t, A == quaternion256(1+2i+3j+9k), false)
	testing.expect_value(t, A != quaternion256(1+2i+3j+9k), true)

	I :: quaternion256(0+1i+0j+0k)
	J :: quaternion256(0+0i+1j+0k)
	K :: quaternion256(0+0i+0j+1k)
	testing.expect_value(t, I == J, false)
	testing.expect_value(t, J == K, false)
	testing.expect_value(t, I == I, true)

	// promotion from integer, float and complex, both orders
	R :: quaternion256(5+0i+0j+0k)
	testing.expect_value(t, R == 5,   true)
	testing.expect_value(t, 5 == R,   true)
	testing.expect_value(t, R == 5.0, true)
	testing.expect_value(t, R != 5,   false)
	testing.expect_value(t, quaternion256(2+3i+0j+0k) == 2+3i, true)
	testing.expect_value(t, quaternion256(2+3i+0j+0k) == 2+4i, false)

	// every width
	testing.expect_value(t, quaternion64(1+2i+3j+4k)  == quaternion64(1+2i+3j+4k),  true)
	testing.expect_value(t, quaternion128(1+2i+3j+4k) == quaternion128(1+2i+3j+4k), true)
	testing.expect_value(t, quaternion256(1+2i+3j+4k) == quaternion256(1+2i+3j+4k), true)
	testing.expect_value(t, quaternion64(1+2i+3j+4k)  == quaternion64(1+2i+3j+9k),  false)

	testing.expect_value(t, quaternion256(0) == quaternion256(-0.0), true)
}

@(test)
variable_quaternion_comparison :: proc(t: ^testing.T) {
	A := quaternion256(1+2i+3j+4k)

	testing.expect_value(t, A == quaternion256(1+2i+3j+4k), true)
	testing.expect_value(t, A != quaternion256(1+2i+3j+4k), false)

	testing.expect_value(t, A == quaternion256(9+2i+3j+4k), false)
	testing.expect_value(t, A == quaternion256(1+9i+3j+4k), false)
	testing.expect_value(t, A == quaternion256(1+2i+9j+4k), false)
	testing.expect_value(t, A == quaternion256(1+2i+3j+9k), false)
	testing.expect_value(t, A != quaternion256(1+2i+3j+9k), true)

	I := quaternion256(0+1i+0j+0k)
	J := quaternion256(0+0i+1j+0k)
	K := quaternion256(0+0i+0j+1k)
	testing.expect_value(t, I == J, false)
	testing.expect_value(t, J == K, false)
	testing.expect_value(t, I == I, true)

	R := quaternion256(5+0i+0j+0k)
	testing.expect_value(t, R == 5,   true)
	testing.expect_value(t, 5 == R,   true)
	testing.expect_value(t, R == 5.0, true)
	testing.expect_value(t, R != 5,   false)

	q64  := quaternion64(1+2i+3j+4k)
	q128 := quaternion128(1+2i+3j+4k)
	q256 := quaternion256(1+2i+3j+4k)
	testing.expect_value(t, q64  == quaternion64(1+2i+3j+4k),  true)
	testing.expect_value(t, q128 == quaternion128(1+2i+3j+4k), true)
	testing.expect_value(t, q256 == quaternion256(1+2i+3j+4k), true)
	testing.expect_value(t, q64  == quaternion64(1+2i+3j+9k),  false)

	z := quaternion256(0)
	testing.expect_value(t, z == quaternion256(-0.0), true)
}

@(test)
constant_complex_accessors :: proc(t: ^testing.T) {
	A :: complex128(2+3i)
	testing.expect_value(t, real(A), 2)
	testing.expect_value(t, imag(A), 3)

	testing.expect_value(t, real(complex32(2+3i)),  2)
	testing.expect_value(t, imag(complex32(2+3i)),  3)
	testing.expect_value(t, real(complex64(2+3i)),  2)
	testing.expect_value(t, imag(complex64(2+3i)),  3)

	// untyped constants
	testing.expect_value(t, real(3i), 0)
	testing.expect_value(t, imag(3i), 3)
	testing.expect_value(t, real(3),  3)
	testing.expect_value(t, imag(3),  0)
}

@(test)
variable_complex_accessors :: proc(t: ^testing.T) {
	A := complex128(2+3i)
	testing.expect_value(t, real(A), 2)
	testing.expect_value(t, imag(A), 3)

	c32 := complex32(2+3i)
	c64 := complex64(2+3i)
	testing.expect_value(t, real(c32), 2)
	testing.expect_value(t, imag(c32), 3)
	testing.expect_value(t, real(c64), 2)
	testing.expect_value(t, imag(c64), 3)
}

@(test)
constant_quaternion_accessors :: proc(t: ^testing.T) {
	// w/x/y/z map onto real/imag/jmag/kmag, and every lane is distinct here so a
	// swapped accessor cannot pass by accident
	A :: quaternion(w=1, x=2, y=3, z=4)
	testing.expect_value(t, real(A), 1)
	testing.expect_value(t, imag(A), 2)
	testing.expect_value(t, jmag(A), 3)
	testing.expect_value(t, kmag(A), 4)

	B :: quaternion256(1+2i+3j+4k)
	testing.expect_value(t, real(B), 1)
	testing.expect_value(t, imag(B), 2)
	testing.expect_value(t, jmag(B), 3)
	testing.expect_value(t, kmag(B), 4)

	testing.expect_value(t, jmag(quaternion64(1+2i+3j+4k)),  3)
	testing.expect_value(t, kmag(quaternion64(1+2i+3j+4k)),  4)
	testing.expect_value(t, jmag(quaternion128(1+2i+3j+4k)), 3)
	testing.expect_value(t, kmag(quaternion128(1+2i+3j+4k)), 4)

	// a typed constant with empty j/k lanes
	Q :: quaternion256(3)
	testing.expect_value(t, real(Q), 3)
	testing.expect_value(t, jmag(Q), 0)
	testing.expect_value(t, kmag(Q), 0)
}

@(test)
variable_quaternion_accessors :: proc(t: ^testing.T) {
	A := quaternion(w=1, x=2, y=3, z=4)
	testing.expect_value(t, real(A), 1)
	testing.expect_value(t, imag(A), 2)
	testing.expect_value(t, jmag(A), 3)
	testing.expect_value(t, kmag(A), 4)

	q64  := quaternion64(1+2i+3j+4k)
	q128 := quaternion128(1+2i+3j+4k)
	testing.expect_value(t, jmag(q64),  3)
	testing.expect_value(t, kmag(q64),  4)
	testing.expect_value(t, jmag(q128), 3)
	testing.expect_value(t, kmag(q128), 4)

	q: quaternion256
	testing.expect_value(t, real(q), 0)
	testing.expect_value(t, jmag(q), 0)
	testing.expect_value(t, kmag(q), 0)
}

// The `j` and `k` suffixes are the only way to write an untyped quaternion constant, and
// these are the shapes `jmag`/`kmag` used to reject outright.

@(test)
untyped_constant_quaternion_accessors :: proc(t: ^testing.T) {
	testing.expect_value(t, jmag(3j), 3)
	testing.expect_value(t, kmag(3k), 3)
	testing.expect_value(t, jmag(3k), 0)
	testing.expect_value(t, kmag(3j), 0)
	testing.expect_value(t, real(3j), 0)
	testing.expect_value(t, imag(3j), 0)

	testing.expect_value(t, real(1+2i+3j+4k), 1)
	testing.expect_value(t, imag(1+2i+3j+4k), 2)
	testing.expect_value(t, jmag(1+2i+3j+4k), 3)
	testing.expect_value(t, kmag(1+2i+3j+4k), 4)

	// an untyped constant that is not a quaternion answers zero, as `imag` does
	testing.expect_value(t, jmag(3),   0)
	testing.expect_value(t, kmag(3),   0)
	testing.expect_value(t, jmag(3.5), 0)
	testing.expect_value(t, kmag(3.5), 0)
	testing.expect_value(t, jmag(3i),  0)
	testing.expect_value(t, kmag(3i),  0)
}

// the accessors answer an untyped float, so the result takes its type from the context
// rather than being pinned to f64

@(test)
accessor_results_are_untyped :: proc(t: ^testing.T) {
	J16 : f16 : jmag(3j)
	J32 : f32 : jmag(3j)
	J64 : f64 : jmag(3j)
	K16 : f16 : kmag(3k)
	K32 : f32 : kmag(3k)
	K64 : f64 : kmag(3k)
	R32 : f32 : real(2+3i)
	I32 : f32 : imag(2+3i)

	testing.expect_value(t, J16, 3)
	testing.expect_value(t, J32, 3)
	testing.expect_value(t, J64, 3)
	testing.expect_value(t, K16, 3)
	testing.expect_value(t, K32, 3)
	testing.expect_value(t, K64, 3)
	testing.expect_value(t, R32, 2)
	testing.expect_value(t, I32, 3)
}
