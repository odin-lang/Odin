package test_issues

import "core:testing"

// A boolean is true when its payload is non-zero, which is what `if`, `!` and `&&` test for.
// `==`, `!=` and `switch` compared the payload against 1 instead, so a boolean decoded from
// bytes -- transmuted, read through a pointer, or returned by a foreign procedure -- was true
// under `if` yet matched neither arm of its own switch.

@(test)
bool_comparison_uses_truthiness :: proc(t: ^testing.T) {
	two: u8 = 2
	one: u8 = 1
	nil_: u8 = 0

	b := transmute(bool)two
	c := transmute(bool)one
	f := transmute(bool)nil_

	testing.expect(t, b, "a non-zero payload is true")

	testing.expect_value(t, b == true,  true)
	testing.expect_value(t, b != true,  false)
	testing.expect_value(t, b == false, false)
	testing.expect_value(t, b != false, true)

	// both operands are normalised, not just the literal one
	testing.expect_value(t, b == c, true)
	testing.expect_value(t, b != c, false)
	testing.expect_value(t, b == f, false)
	testing.expect_value(t, b != f, true)

	arm := 2
	switch b {
	case true:  arm = 1
	case false: arm = 0
	}
	testing.expect_value(t, arm, 1)

	// the wider boolean types share the path
	two16: u16 = 2
	two32: u32 = 2
	two64: u64 = 2
	testing.expect_value(t, transmute(b8)two    == true, true)
	testing.expect_value(t, transmute(b16)two16 == true, true)
	testing.expect_value(t, transmute(b32)two32 == true, true)
	testing.expect_value(t, transmute(b64)two64 == true, true)

	// the normal 0/1 payloads keep behaving
	yes := true
	no  := false
	testing.expect_value(t, yes == true,  true)
	testing.expect_value(t, yes == false, false)
	testing.expect_value(t, no  == false, true)
	testing.expect_value(t, yes == no,    false)
	testing.expect_value(t, yes != no,    true)
}
