package test_internal

import "core:testing"

@(test)
test_abs_float :: proc(t: ^testing.T) {
	not_const :: proc(v: $T) -> T { return v }

	// Constant f16
	testing.expect_value(t, abs(f16(0.)), 0.)
	testing.expect_value(t, abs(f16(-0.)), 0.)
	testing.expect_value(t, abs(f16(-1.)), 1.)
	testing.expect_value(t, abs(min(f16)), max(f16))
	testing.expect_value(t, abs(max(f16)), max(f16))
	testing.expect_value(t, abs(f16(-.12345)), .12345)

	// Variable f16
	testing.expect_value(t, abs(not_const(f16(0.))), 0.)
	testing.expect_value(t, abs(not_const(f16(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f16(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f16))), max(f16))
	testing.expect_value(t, abs(not_const(max(f16))), max(f16))
	testing.expect_value(t, abs(not_const(f16(-.12345))), .12345)

	// Constant f32
	testing.expect_value(t, abs(f32(0.)), 0.)
	testing.expect_value(t, abs(f32(-0.)), 0.)
	testing.expect_value(t, abs(f32(-1.)), 1.)
	testing.expect_value(t, abs(min(f32)), max(f32))
	testing.expect_value(t, abs(max(f32)), max(f32))
	testing.expect_value(t, abs(f32(-.12345)), .12345)

	// Variable f32
	testing.expect_value(t, abs(not_const(f32(0.))), 0.)
	testing.expect_value(t, abs(not_const(f32(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f32(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f32))), max(f32))
	testing.expect_value(t, abs(not_const(max(f32))), max(f32))
	testing.expect_value(t, abs(not_const(f32(-.12345))), .12345)

	// Constant f64
	testing.expect_value(t, abs(f64(0.)), 0.)
	testing.expect_value(t, abs(f64(-0.)), 0.)
	testing.expect_value(t, abs(f64(-1.)), 1.)
	testing.expect_value(t, abs(min(f64)), max(f64))
	testing.expect_value(t, abs(max(f64)), max(f64))
	testing.expect_value(t, abs(f64(-.12345)), .12345)

	// Variable f64
	testing.expect_value(t, abs(not_const(f64(0.))), 0.)
	testing.expect_value(t, abs(not_const(f64(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f64(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f64))), max(f64))
	testing.expect_value(t, abs(not_const(max(f64))), max(f64))
	testing.expect_value(t, abs(not_const(f64(-.12345))), .12345)
}
