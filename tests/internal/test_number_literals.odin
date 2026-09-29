package test_internal

import "core:testing"
import "core:strconv"

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

@(test)
float_literal_f16_f32_precision :: proc(t: ^testing.T) {
	// f16/f32 constants are rounded once, directly from the exact value, so a constant-folded literal
	// matches the correctly-rounded runtime parse (rather than double-rounding via f64).
	c32 :: proc(t: ^testing.T, got: f32, lit: string) {
		want, _ := strconv.parse_f32(lit)
		testing.expectf(t, transmute(u32)got == transmute(u32)want,
			"f32 %s: got %08x, want %08x", lit, transmute(u32)got, transmute(u32)want)
	}
	c32(t, 0.1, "0.1")
	c32(t, 0.2, "0.2")
	c32(t, 0.3, "0.3")
	c32(t, f32(1.0/3.0), "0.3333333333333333")
	c32(t, 3.14159265358979323846, "3.14159265358979323846")
	c32(t, 1.1, "1.1")
	c32(t, 1e-40, "1e-40")   // subnormal f32
	c32(t, 1.5e-45, "1.5e-45")
	c32(t, 8388609.0, "8388609.0") // 2^23 + 1

	// f16 spot checks against an f64-parsed reference (53 bits is exact relative to f16's 11).
	c16 :: proc(t: ^testing.T, got: f16, lit: string) {
		w64, _ := strconv.parse_f64(lit)
		want := f16(w64)
		testing.expectf(t, transmute(u16)got == transmute(u16)want,
			"f16 %s: got %04x, want %04x", lit, transmute(u16)got, transmute(u16)want)
	}
	c16(t, 0.1, "0.1")
	c16(t, f16(1.0/3.0), "0.3333333333333333")
	c16(t, 3.14159265358979323846, "3.14159265358979323846")
	c16(t, 6e-8, "6e-8") // subnormal f16

	// f16/f32 overflow of an exact constant is rejected, not silently +Inf (compile-time #assert
	// can't test a reject, but these confirm large finite values still fold correctly).
	testing.expect_value(t, f32(1e38), strconv.parse_f32("1e38") or_else 0)
}

@(test)
float_constant_builtins :: proc(t: ^testing.T) {
	// Constant-folded builtins on decimal-float (rational) constants must not crash or mis-fold.
	// `abs` in particular used to hit an unhandled ExactValue kind.
	#assert(abs(-1.5) == 1.5)
	#assert(abs(1.5) == 1.5)
	#assert(abs(0.3 - 0.5) == 0.2)  // exact: |3/10 - 5/10| == 1/5
	#assert(min(0.1, 0.2) == 0.1)
	#assert(max(0.1, 0.2) == 0.2)
	#assert(clamp(1.5, 0.0, 1.0) == 1.0)
	testing.expect_value(t, abs(-2.5), 2.5)
	testing.expect_value(t, min(1.0/3.0, 1.0/4.0), 1.0/4.0)
}
