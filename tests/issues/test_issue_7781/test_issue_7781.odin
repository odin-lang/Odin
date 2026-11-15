package test_issue_7781

import "core:testing"

// A shift amount wider than the shifted operand was narrowed to the operand's type before being tested against
// its bit width, so `u8(1) << u64(256)` shifted by 0 and gave 1 instead of 0.

@(test)
test_wide_shift_amount :: proc(t: ^testing.T) {
	n := u64(256)
	testing.expect_value(t, u8(1) << n, 0)
	testing.expect_value(t, u8(0x80) >> n, 0)
	testing.expect_value(t, i8(-128) >> n, -1)

	n = 257
	testing.expect_value(t, u8(1) << n, 0)
	testing.expect_value(t, i8(-128) >> n, -1)

	n = 1 << 32
	testing.expect_value(t, u32(1) << n, 0)
	testing.expect_value(t, i32(-8) >> n, -1)

	n = 7
	testing.expect_value(t, u8(1) << n, 0x80)
	testing.expect_value(t, i8(-128) >> n, -1)
	testing.expect_value(t, u8(0x80) >> n, 1)
}

@(test)
test_wide_shift_amount_assign :: proc(t: ^testing.T) {
	n := u64(1) << 32
	a := u32(1)
	a <<= n
	testing.expect_value(t, a, 0)
	b := i16(-4)
	b >>= n
	testing.expect_value(t, b, -1)

	m := u64(3)
	c := u32(1)
	c <<= m
	testing.expect_value(t, c, 8)
}

@(test)
test_wide_shift_amount_endian :: proc(t: ^testing.T) {
	n := u64be(1) << 32
	testing.expect_value(t, u8(1) << n, 0)
	testing.expect_value(t, u32be(1) << n, 0)
	testing.expect_value(t, u32le(0x80) >> n, 0)

	m := u64(3)
	testing.expect_value(t, u32be(1) << m, 8)
	testing.expect_value(t, u8(1) << u64be(m), 8)
}
