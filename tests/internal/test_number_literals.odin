package test_internal

import "core:testing"

// Regression tests for numeric literal parsing and constant folding:
//   * an integer literal with a large exponent (e.g. `98765e309`) is an exact arbitrary-precision
//     integer rather than being rejected,
//   * a decimal literal that overflows `f64` (e.g. `98765.0e309`) keeps that exact integer value so
//     it is not silently turned into `+Inf`,
//   * an ordinary finite decimal literal still behaves as a floating-point value, so float constant
//     arithmetic like `1.0 / 16.0` folds to `0.0625` and never to integer division.

@(test)
float_literal_arithmetic :: proc(t: ^testing.T) {
	// Trailing-dot and `.0` decimal literals must divide as floats, not integers. These are all
	// constant expressions, so they exercise the compiler's constant folding.
	testing.expect_value(t, 1.0/16.0,  0.0625)
	testing.expect_value(t, 1./16.,    0.0625)
	testing.expect_value(t, 1/16.,     0.0625)
	testing.expect_value(t, 3./2.,     1.5)
	testing.expect_value(t, 1.0e2,     100.0)
	testing.expect_value(t, 2.5 + 0.5, 3.0)

	// With exact-rational constant folding, `0.1 + 0.2` folds to exactly 0.3 (Go-style: the untyped
	// float constants are exact until rounded once to the target type). The same expression evaluated
	// at runtime on f64 variables still exhibits the usual binary floating-point rounding.
	testing.expect(t, 0.1 + 0.2 == 0.3, "exact constant folding: 0.1 + 0.2 == 0.3")
	{
		ra, rb := 0.1, 0.2
		testing.expect(t, ra + rb != 0.3, "runtime f64 arithmetic still rounds")
	}

	// Runtime values exercise the backend division path as well.
	a := 1.
	b := 16.
	testing.expect_value(t, a/b, 0.0625)

	// Signed zero must survive (a `0.0` literal is a float, not an integer `0`).
	nz := -0.0
	testing.expect_value(t, transmute(u64)nz, 0x8000_0000_0000_0000)
}

@(test)
large_integer_literals :: proc(t: ^testing.T) {
	// A large exponent denotes an exact big integer, and the three spellings of the same number all
	// fold to the same value (previously `98765e309` was an "Invalid integer literal").
	#assert(98765e309 == 987650e308)
	#assert(98765.0e309 == 98765e309)
	#assert(1e38 / 1e19 == 1e19) // exact, well beyond the range of any integer type

	// Large but representable values still behave as ordinary `f64` constants.
	testing.expect_value(t, f64(1e300), 1e300)
	testing.expect(t, 1e308 > 1e307, "ordering of large f64 constants")

	// A large-exponent integer literal that fits a wide integer type is exact.
	testing.expect(t, u128(1e38) > u128(1e37), "1e38 > 1e37 as u128")
	testing.expect_value(t, u128(1e38) / u128(1e19), u128(1e19))
}
