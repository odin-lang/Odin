package test_core_math_fixed

import "core:math/fixed"
import "core:testing"

@test
test_fixed_4_4_unsigned :: proc(t: ^testing.T) {
	I_SHIFT :: 4
	F_MASK  :: 15
	F_ULP   :: 0.0625
	Fixed   :: fixed.Fixed(u8, 4)

	for c in 0..<256 {
		raw := u8(c)
		fv  := transmute(Fixed)raw

		i := raw >> I_SHIFT
		f := raw &  F_MASK
		expected := f64(i) + F_ULP * f64(f)

		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(u8, 4)(%v) to equal %.5f, got %.5f", raw, expected, fixed.to_f64(fv))
	}
}

@test
test_fixed_4_4_signed :: proc(t: ^testing.T) {
	I_SHIFT :: 4
	F_MASK  :: 15
	F_ULP   :: 0.0625
	Fixed   :: fixed.Fixed(i8, 4)

	for c in 0..<256 {
		raw := i8(c)
		fv  := transmute(Fixed)raw

		f := raw & F_MASK
		expected: f64
		if c < 128 {
			i := raw >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		} else if c == 128 {
			expected = 8.0

		} else if c > 128 {
			i := i8(-8)
			i += (raw & 0b0111_0000) >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		}
		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(i8, 4)(%v, %v) to equal %.5f, got %.5f", c, raw, expected, fixed.to_f64(fv))
	}
}