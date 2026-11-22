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

@(private="file")
Signed_Backing :: distinct i16

@(private="file")
Unsigned_Backing :: distinct u16

@(private="file")
Signed_Enum :: enum Signed_Backing {
	NEGATIVE = -1,
	POSITIVE = 1,
}

@(private="file")
Unsigned_Enum :: enum Unsigned_Backing {
	SMALL_VALUE = 1,
	BIG_VALUE   = 0xFFFF, // negative if interpreted as i16
}

// An enum's signedness comes from its backing type, also when that type is `distinct`.
// It used to be read from the wrong field of the backing type, and changed from one build to the next.
@test
test_distinct_backing_signedness :: proc(t: ^testing.T) {
	test_proc :: proc(lhs: $T, rhs: T) -> bool {
		return lhs > rhs
	}

	testing.expect_value(t, test_proc(Signed_Enum.NEGATIVE, Signed_Enum.POSITIVE),         false)
	testing.expect_value(t, test_proc(Unsigned_Enum.SMALL_VALUE, Unsigned_Enum.BIG_VALUE), false)

	negative, big := Signed_Enum.NEGATIVE, Unsigned_Enum.BIG_VALUE
	testing.expect_value(t, i32(negative), -1)
	testing.expect_value(t, i32(big),      0xFFFF)
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