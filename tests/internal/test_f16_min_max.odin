package test_internal

import "core:math"
import "core:testing"

// f16 is computed through f32; the picks must keep the f16 operand's own bits.
@(test)
f16_min_max_clamp_sqrt :: proc(t: ^testing.T) {
	nan := transmute(f16)u16(0x7e00)
	a, b: f16 = -1.5, 3.25
	testing.expect_value(t, min(a, b), -1.5)
	testing.expect_value(t, max(a, b), 3.25)
	testing.expect_value(t, min(nan, b), 3.25) // a NaN operand gives the other one
	testing.expect_value(t, transmute(u16)max(-0.0, f16(0)), 0x0000)
	testing.expect_value(t, clamp(a, f16(0), f16(1)), 0)
	testing.expect_value(t, math.sqrt(f16(2)), f16(1.4140625))
	// the product is rounded to f16 before the add
	testing.expect_value(t, transmute(u16)math.fmuladd(f16(3.14), f16(3.14), f16(0.1)), 0x48fc)
}
