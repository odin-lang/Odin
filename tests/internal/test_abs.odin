package test_internal

import "core:testing"

@(private="file")
not_const :: proc(v: $T) -> T { return v }

@(test)
abs_f16_const :: proc(t: ^testing.T) {
	// Constant f16
	testing.expect_value(t, abs(f16(0.)), 0.)
	testing.expect_value(t, abs(f16(-0.)), 0.)
	testing.expect_value(t, abs(f16(-1.)), 1.)
	testing.expect_value(t, abs(min(f16)), max(f16))
	testing.expect_value(t, abs(max(f16)), max(f16))
	testing.expect_value(t, abs(f16(-.12)), .12)

	// Constant f16le
	testing.expect_value(t, abs(f16le(0.)), 0.)
	testing.expect_value(t, abs(f16le(-0.)), 0.)
	testing.expect_value(t, abs(f16le(-1.)), 1.)
	testing.expect_value(t, abs(min(f16le)), max(f16le))
	testing.expect_value(t, abs(max(f16le)), max(f16le))
	testing.expect_value(t, abs(f16le(-.12)), .12)

	// Constant f16be
	testing.expect_value(t, abs(f16be(0.)), 0.)
	testing.expect_value(t, abs(f16be(-0.)), 0.)
	testing.expect_value(t, abs(f16be(-1.)), 1.)
	testing.expect_value(t, abs(min(f16be)), max(f16be))
	testing.expect_value(t, abs(max(f16be)), max(f16be))
	testing.expect_value(t, abs(f16be(-.12)), .12)
}

@(test)
abs_f16_variable :: proc(t: ^testing.T) {
	// Variable f16
	testing.expect_value(t, abs(not_const(f16(0.))), 0.)
	testing.expect_value(t, abs(not_const(f16(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f16(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f16))), max(f16))
	testing.expect_value(t, abs(not_const(max(f16))), max(f16))
	testing.expect_value(t, abs(not_const(f16(-.12))), .12)

	// Variable f16le
	testing.expect_value(t, abs(not_const(f16le(0.))), 0.)
	testing.expect_value(t, abs(not_const(f16le(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f16le(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f16le))), max(f16le))
	testing.expect_value(t, abs(not_const(max(f16le))), max(f16le))
	testing.expect_value(t, abs(not_const(f16le(-.12))), .12)

	// Variable f16be
	testing.expect_value(t, abs(not_const(f16be(0.))), 0.)
	testing.expect_value(t, abs(not_const(f16be(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f16be(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f16be))), max(f16be))
	testing.expect_value(t, abs(not_const(max(f16be))), max(f16be))
	testing.expect_value(t, abs(not_const(f16be(-.12))), .12)
}

@(test)
abs_f32_const :: proc(t: ^testing.T) {
	// Constant f32
	testing.expect_value(t, abs(f32(0.)), 0.)
	testing.expect_value(t, abs(f32(-0.)), 0.)
	testing.expect_value(t, abs(f32(-1.)), 1.)
	testing.expect_value(t, abs(min(f32)), max(f32))
	testing.expect_value(t, abs(max(f32)), max(f32))
	testing.expect_value(t, abs(f32(-.12345)), .12345)

	// Constant f32le
	testing.expect_value(t, abs(f32le(0.)), 0.)
	testing.expect_value(t, abs(f32le(-0.)), 0.)
	testing.expect_value(t, abs(f32le(-1.)), 1.)
	testing.expect_value(t, abs(min(f32le)), max(f32le))
	testing.expect_value(t, abs(max(f32le)), max(f32le))
	testing.expect_value(t, abs(f32le(-.12345)), .12345)

	// Constant f32be
	testing.expect_value(t, abs(f32be(0.)), 0.)
	testing.expect_value(t, abs(f32be(-0.)), 0.)
	testing.expect_value(t, abs(f32be(-1.)), 1.)
	testing.expect_value(t, abs(min(f32be)), max(f32be))
	testing.expect_value(t, abs(max(f32be)), max(f32be))
	testing.expect_value(t, abs(f32be(-.12345)), .12345)
}

@(test)
abs_f32_variable :: proc(t: ^testing.T) {
	// Variable f32
	testing.expect_value(t, abs(not_const(f32(0.))), 0.)
	testing.expect_value(t, abs(not_const(f32(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f32(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f32))), max(f32))
	testing.expect_value(t, abs(not_const(max(f32))), max(f32))
	testing.expect_value(t, abs(not_const(f32(-.12345))), .12345)

	// Variable f32le
	testing.expect_value(t, abs(not_const(f32le(0.))), 0.)
	testing.expect_value(t, abs(not_const(f32le(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f32le(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f32le))), max(f32le))
	testing.expect_value(t, abs(not_const(max(f32le))), max(f32le))
	testing.expect_value(t, abs(not_const(f32le(-.12345))), .12345)

	// Variable f32be
	testing.expect_value(t, abs(not_const(f32be(0.))), 0.)
	testing.expect_value(t, abs(not_const(f32be(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f32be(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f32be))), max(f32be))
	testing.expect_value(t, abs(not_const(max(f32be))), max(f32be))
	testing.expect_value(t, abs(not_const(f32be(-.12345))), .12345)
}

@(test)
abs_f64_const :: proc(t: ^testing.T) {
	// Constant f64
	testing.expect_value(t, abs(f64(0.)), 0.)
	testing.expect_value(t, abs(f64(-0.)), 0.)
	testing.expect_value(t, abs(f64(-1.)), 1.)
	testing.expect_value(t, abs(min(f64)), max(f64))
	testing.expect_value(t, abs(max(f64)), max(f64))
	testing.expect_value(t, abs(f64(-.12345)), .12345)

	// Constant f64le
	testing.expect_value(t, abs(f64le(0.)), 0.)
	testing.expect_value(t, abs(f64le(-0.)), 0.)
	testing.expect_value(t, abs(f64le(-1.)), 1.)
	testing.expect_value(t, abs(min(f64le)), max(f64le))
	testing.expect_value(t, abs(max(f64le)), max(f64le))
	testing.expect_value(t, abs(f64le(-.12345)), .12345)

	// Constant f64be
	testing.expect_value(t, abs(f64be(0.)), 0.)
	testing.expect_value(t, abs(f64be(-0.)), 0.)
	testing.expect_value(t, abs(f64be(-1.)), 1.)
	testing.expect_value(t, abs(min(f64be)), max(f64be))
	testing.expect_value(t, abs(max(f64be)), max(f64be))
	testing.expect_value(t, abs(f64be(-.12345)), .12345)
}

@(test)
abs_f64_variable :: proc(t: ^testing.T) {
	// Variable f64
	testing.expect_value(t, abs(not_const(f64(0.))), 0.)
	testing.expect_value(t, abs(not_const(f64(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f64(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f64))), max(f64))
	testing.expect_value(t, abs(not_const(max(f64))), max(f64))
	testing.expect_value(t, abs(not_const(f64(-.12345))), .12345)

	// Variable f64le
	testing.expect_value(t, abs(not_const(f64le(0.))), 0.)
	testing.expect_value(t, abs(not_const(f64le(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f64le(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f64le))), max(f64le))
	testing.expect_value(t, abs(not_const(max(f64le))), max(f64le))
	testing.expect_value(t, abs(not_const(f64le(-.12345))), .12345)

	// Variable f64be
	testing.expect_value(t, abs(not_const(f64be(0.))), 0.)
	testing.expect_value(t, abs(not_const(f64be(-0.))), 0.)
	testing.expect_value(t, abs(not_const(f64be(-1.))), 1.)
	testing.expect_value(t, abs(not_const(min(f64be))), max(f64be))
	testing.expect_value(t, abs(not_const(max(f64be))), max(f64be))
	testing.expect_value(t, abs(not_const(f64be(-.12345))), .12345)
}
