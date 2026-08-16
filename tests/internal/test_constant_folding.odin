package test_internal

import "core:testing"

// Constant folding against the answer the backend produces. A folded constant that is merely
// wrong still compiles, so a harness comparing accept/reject sees agreement 
// Every case here pairs a constant with the same expression on variables for that reason.
//
// `a &~ b` is `a & ~b`. `big_int_and_not` had three independent faults: `0 &~ y` returned `y`,
// the both-negative branch used its operands the wrong way round, and the negative-left branch
// dropped the sign of its result.

@(test)
and_not_constant_folding_matches_runtime :: proc(t: ^testing.T) {
	// the zero short-circuit: 0 &~ anything is 0
	{
		a, b := 0, 3
		testing.expect_value(t, 0 &~ 3, a &~ b)
		testing.expect_value(t, 0 &~ 3, 0)
	}
	{
		a, b := 0, -3
		testing.expect_value(t, 0 &~ -3, a &~ b)
		testing.expect_value(t, 0 &~ -3, 0)
	}

	// negative left operand: the result must stay negative
	{
		a, b := -7, 3
		testing.expect_value(t, -7 &~ 3, a &~ b)
		testing.expect_value(t, -7 &~ 3, -8)
	}
	{
		a, b := -255, 5
		testing.expect_value(t, -255 &~ 5, a &~ b)
		testing.expect_value(t, -255 &~ 5, -256)
	}

	// both negative
	{
		a, b := -7, -3
		testing.expect_value(t, -7 &~ -3, a &~ b)
		testing.expect_value(t, -7 &~ -3, 0)
	}
	{
		a, b := -3, -7
		testing.expect_value(t, -3 &~ -7, a &~ b)
		testing.expect_value(t, -3 &~ -7, 4)
	}

	// the cases that were already correct, so a fix cannot regress them
	{
		a, b := 7, 3
		testing.expect_value(t, 7 &~ 3, a &~ b)
		testing.expect_value(t, 7 &~ 3, 4)
	}
	{
		a, b := 7, -3
		testing.expect_value(t, 7 &~ -3, a &~ b)
		testing.expect_value(t, 7 &~ -3, 2)
	}
	{
		a, b := 7, 0
		testing.expect_value(t, 7 &~ 0, a &~ b)
		testing.expect_value(t, 7 &~ 0, 7)
	}
}

@(test)
and_not_constant_folding_every_width :: proc(t: ^testing.T) {
	// the zero-left shape reaches unsigned types too
	{
		a, b := u8(0), u8(1)
		testing.expect_value(t, u8(0) &~ u8(1), a &~ b)
		testing.expect_value(t, u8(0) &~ u8(1), u8(0))
	}
	{
		a, b := u64(0), u64(255)
		testing.expect_value(t, u64(0) &~ u64(255), a &~ b)
		testing.expect_value(t, u64(0) &~ u64(255), u64(0))
	}

	// signed, at the extremes of each width
	{
		a, b := i8(-128), i8(1)
		testing.expect_value(t, i8(-128) &~ i8(1), a &~ b)
		testing.expect_value(t, i8(-128) &~ i8(1), i8(-128))
	}
	{
		a, b := i8(-128), i8(127)
		testing.expect_value(t, i8(-128) &~ i8(127), a &~ b)
		testing.expect_value(t, i8(-128) &~ i8(127), i8(-128))
	}
	{
		a, b := i8(-7), i8(-128)
		testing.expect_value(t, i8(-7) &~ i8(-128), a &~ b)
		testing.expect_value(t, i8(-7) &~ i8(-128), i8(121))
	}
	{
		a, b := i16(-7), i16(3)
		testing.expect_value(t, i16(-7) &~ i16(3), a &~ b)
		testing.expect_value(t, i16(-7) &~ i16(3), i16(-8))
	}
	{
		a, b := i32(-255), i32(5)
		testing.expect_value(t, i32(-255) &~ i32(5), a &~ b)
		testing.expect_value(t, i32(-255) &~ i32(5), i32(-256))
	}
	{
		a, b := i64(-7), i64(-3)
		testing.expect_value(t, i64(-7) &~ i64(-3), a &~ b)
		testing.expect_value(t, i64(-7) &~ i64(-3), i64(0))
	}
}

// `&~` was the only operator found divergent; the rest of the bitwise family shares the sign
// handling and must stay agreeing.

@(test)
bitwise_constant_folding_matches_runtime :: proc(t: ^testing.T) {
	{
		a, b := -7, 3
		testing.expect_value(t, -7 & 3, a & b)
		testing.expect_value(t, -7 | 3, a | b)
		testing.expect_value(t, -7 ~ 3, a ~ b)
	}
	{
		a, b := -7, -3
		testing.expect_value(t, -7 & -3, a & b)
		testing.expect_value(t, -7 | -3, a | b)
		testing.expect_value(t, -7 ~ -3, a ~ b)
	}
	{
		a, b := 0, -3
		testing.expect_value(t, 0 & -3, a & b)
		testing.expect_value(t, 0 | -3, a | b)
		testing.expect_value(t, 0 ~ -3, a ~ b)
	}
}
