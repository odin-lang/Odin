package test_internal

import "core:testing"

@test
test_comparisons_5408 :: proc(t: ^testing.T) {
	// See: https://github.com/odin-lang/Odin/pull/5408
	test_proc :: proc(lhs: $T, rhs: T) -> bool {
		return lhs > rhs
	}

	Test_Enum :: enum u32 {
		SMALL_VALUE = 0xFF,
		BIG_VALUE   = 0xFF00_0000, // negative if interpreted as i32
	}

	testing.expect_value(t, test_proc(Test_Enum.SMALL_VALUE, Test_Enum.BIG_VALUE), false)
	testing.expect_value(t, test_proc(Test_Enum(0xF), Test_Enum.BIG_VALUE),        false)
	testing.expect_value(t, test_proc(Test_Enum(0xF), Test_Enum(0xF000_0000)),     false)
	testing.expect_value(t, test_proc(Test_Enum.SMALL_VALUE, max(Test_Enum)),      false)
	testing.expect_value(t, test_proc(Test_Enum(0xF), max(Test_Enum)),             false)
}

test_signedness :: proc(t: ^testing.T) {
	{
		a, b := i16(32767), i16(0)
		testing.expect_value(t, a > b, true)
	}

	{
		a, b := u16(65535), u16(0)
		testing.expect_value(t, a > b, true)
	}
}