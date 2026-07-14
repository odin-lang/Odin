package test_core_math_fixed

import "core:math"
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
			expected = -8.0

		} else if c > 128 {
			i := i8(-8)
			i += (raw & 0b0111_0000) >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		}
		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(i8, 4)(%v, %v) to equal %.5f, got %.5f", c, raw, expected, fixed.to_f64(fv))
	}
}

// check floor over every raw value of the signed 8-bit 4.4 fixed type,
// using math.floor on the exact float64 value as the reference.
@test
test_fixed_4_4_signed_floor_exhaustive :: proc(t: ^testing.T) {
	Fixed :: fixed.Fixed(i8, 4)

	for c in 0..<256 {
		raw := i8(c)
		fv  := transmute(Fixed)raw

		expected := i8(math.floor(f32(raw) / 16.0))
		testing.expectf(t, fixed.floor(fv) == expected, "Expected floor(Fixed(i8, 4)(%v)) to equal %v, got %v", raw, expected, fixed.floor(fv))
	}
}

@test
test_fixed_16_16_signed_floor :: proc(t: ^testing.T) {
	Fixed :: fixed.Fixed16_16
	test_cases := [?]struct{value: f64, expected: i32}{
		{-32768.0, -32768},
		{-2.5, -3},
		{-2.0, -2},
		{-1.3, -2},
		{-1.5, -2},
		{-1.0, -1},
		{-0.5, -1},
		{ 0.0,  0},
		{ 0.5,  0},
		{ 1.0,  1},
		{ 1.3,  1},
		{ 1.5,  1},
		{ 2.5,  2},
	}
	for c in test_cases {
		x: Fixed
		fixed.init_from_f64(&x, c.value)
		testing.expectf(t, fixed.floor(x) == c.expected, "Expected floor(%v) to equal %v, got %v", c.value, c.expected, fixed.floor(x))
	}
}

// test roundtrip f64 -> Fixed16_16 -> f64 using init_from_f64 and to_f64,
// test values MUST be exact in both types for proper roundtrip
@test
test_fixed_16_16_signed_roundtrip_from_f64 :: proc(t: ^testing.T) {
	Fixed :: fixed.Fixed16_16
	ULP   :: 0.0000152587890625 // 2^-16

	test_cases := [?]f64 {
		-2.5,
		-2.0,
		-1.125,
		-1.0,
		-0.75,
		 0.0,
		 -0.0,           // signed zero should not turn to garbage?
		 0.5,
		 1.0,
		 1.5,
		 2.25,
		 -32767.25,
		 -32768.0,      // roundtrips cause i32(32768) << 16 wraps to min(i32) and -min == min is true
		 32767.0,
		 32767.9765625,

		 // ULP test cases
		 ULP,           
		-ULP,           
		 1.0 - ULP,     // all fraction bits set
		 1.0 + ULP,     // integer bit | lowest fraction bit
		-1.0 + ULP,
		-1.0 - ULP,
		 32768.0 - ULP, // max(Fixed16_16), raw is max(i32)
		-32768.0 + ULP, // raw = min(i32) + 1
	}
	for c in test_cases {
		x: Fixed
		fixed.init_from_f64(&x, c)
		testing.expectf(t, fixed.to_f64(x) == c, "Expected f64 %v to roundtrip through Fixed16_16, got %v", c, fixed.to_f64(x))
	}
}


// every Fixed4_4 value is exact in f64,
// so Fixed4_4 -> to_f64 -> init_from_f64 -> Fixed4_4 must be identity
@test
test_fixed_4_4_signed_roundtrip_exhaustive :: proc(t: ^testing.T) {
	Fixed :: fixed.Fixed4_4

	for c in 0..<256 {
		raw := i8(c)
		fv  := transmute(Fixed)raw

		back: Fixed
		fixed.init_from_f64(&back, fixed.to_f64(fv))
		testing.expectf(t, back.i == raw, "Expected raw %v to roundtrip through %v, got %v", raw, fixed.to_f64(fv), back.i)
	}
}

// same for unsigned backing 
@test
test_fixed_8_8_unsigned_roundtrip_exhaustive :: proc(t: ^testing.T) {
	Fixed :: fixed.Fixed(u8, 8)

	for c in 0..<256 {
		raw := u8(c)
		fv  := transmute(Fixed)raw

		back: Fixed
		fixed.init_from_f64(&back, fixed.to_f64(fv))
		testing.expectf(t, back.i == raw, "Expected raw %v to roundtrip through %v, got %v", raw, fixed.to_f64(fv), back.i)
	}
}