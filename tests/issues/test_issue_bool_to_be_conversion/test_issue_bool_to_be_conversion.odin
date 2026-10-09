package test_issues

import "core:testing"

// Converting a boolean to a big-endian integer skipped the endian fixup that the integer source
// path performs, so the result carried a native bit pattern labelled big-endian. The checker
// folded the same conversion to the right value, so only the runtime disagreed.

@(test)
bool_to_big_endian :: proc(t: ^testing.T) {
	b:    bool = true
	f:    bool = false
	b8v:  b8   = true
	b16v: b16  = true
	b32v: b32  = true
	b64v: b64  = true
	i:    int  = 1

	testing.expect_value(t, int(i16be(b)),  1)
	testing.expect_value(t, int(u32be(b)),  1)
	testing.expect_value(t, int(u64be(b)),  1)
	testing.expect_value(t, int(u128be(b)), 1)
	testing.expect_value(t, int(i16be(f)),  0)

	testing.expect_value(t, int(i16be(b8v)),  1)
	testing.expect_value(t, int(i16be(b16v)), 1)
	testing.expect_value(t, int(i16be(b32v)), 1)
	testing.expect_value(t, int(i16be(b64v)), 1)

	// the little-endian target and the integer source were already correct
	testing.expect_value(t, int(i16le(b)), 1)
	testing.expect_value(t, int(i16be(i)), 1)

	// the bytes have to actually be big-endian, not a native pattern relabelled
	testing.expect_value(t, transmute([4]u8)u32be(b), transmute([4]u8)u32be(i))
	testing.expect_value(t, transmute([4]u8)u32be(b), [4]u8{0, 0, 0, 1})
}
