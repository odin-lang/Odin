package test_internal

import "core:testing"

// `complex` and `quaternion` took their result type from any hint they were *castable* to, which is
// the rule for a conversion the programmer writes. Used as an assignment rule it silently narrowed
// f64 to f32, produced a quaternion from a two-component builtin with w and k uninitialised, and
// left the value with no element type at all when the hint was `any` or a union -- a compiler panic
@(test)
complex_takes_its_type_from_its_arguments :: proc(t: ^testing.T) {
	a, b: f64 = 3, 4
	c, d: f32 = 3, 4

	// the element type follows the arguments, not the hint
	x: complex128 = complex(a, b)
	y: complex64  = complex(c, d)
	testing.expect_value(t, real(x), f64(3))
	testing.expect_value(t, imag(x), f64(4))
	testing.expect_value(t, real(y), f32(3))
	testing.expect_value(t, imag(y), f32(4))

	// a distinct complex of the same width still takes the hint, which core:c/libc relies on
	CD :: distinct complex128
	z: CD = complex(a, b)
	testing.expect_value(t, real(complex128(z)), f64(3))

	// an untyped constant is still context-typed
	u: complex64 = complex(1, 2)
	testing.expect_value(t, real(u), f32(1))

	q: quaternion256 = quaternion(w = a, x = b, y = a, z = b)
	testing.expect_value(t, real(q), f64(3))
	testing.expect_value(t, imag(q), f64(4))
	testing.expect_value(t, jmag(q), f64(3))
	testing.expect_value(t, kmag(q), f64(4))
}

// a hint that is not a complex type is no longer adopted, so these reach the ordinary assignment
// rule instead of the backend. `any` and a union both used to panic the compiler
@(test)
complex_into_any_and_union :: proc(t: ^testing.T) {
	U :: union { complex128 }

	a, b: f64 = 3, 4

	v: any = complex(a, b)
	if c, ok := v.(complex128); testing.expect(t, ok, "any did not hold a complex128") {
		testing.expect_value(t, real(c), f64(3))
	}

	u: U = complex(a, b)
	if c, ok := u.(complex128); testing.expect(t, ok, "union did not hold a complex128") {
		testing.expect_value(t, imag(c), f64(4))
	}
}
