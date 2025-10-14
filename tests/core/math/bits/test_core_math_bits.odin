package test_core_math_bits

import "core:math/bits"
import "core:math/rand"
import "core:testing"

@test
test_log2 :: proc(t: ^testing.T) {
	dumb_log2 :: proc(x: $T) -> (res: T) {
		N :: T(size_of(T) * 8)

		if x == 0 {
			return max(T)
		}

		for k := N - 1; k > 0; k -= 1 {
			bit_pos := T(k)
			if (x >> bit_pos) & 1 == 1 {
				return bit_pos
			}
		}
		return
	}

	testing.expect_value(t, bits.log2(  u8(0)), max(u8))
	testing.expect_value(t, bits.log2( u16(0)), max(u16))
	testing.expect_value(t, bits.log2( u32(0)), max(u32))
	testing.expect_value(t, bits.log2( u64(0)), max(u64))
	testing.expect_value(t, bits.log2(uint(0)), max(uint))

	for x in u8(0)..<max(u8) {
		l1 := bits.log2(x)
		l2 := dumb_log2(x)
		testing.expectf(t, l1 == l2, "bits.log({0}): {1}, dumb_log2({0}): {2}", x, l1, l2)
	}

	for x in u16(0)..<max(u16) {
		l1 := bits.log2(x)
		l2 := dumb_log2(x)
		testing.expectf(t, l1 == l2, "bits.log({0}): {1}, dumb_log2({0}): {2}", x, l1, l2)
	}

	// Takes too long to run this with 32+ integers, and if it works with u8 and u16, it'll work with u32, u64, etc. as well.
}

@test
test_rotate :: proc(t: ^testing.T) {
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 0), 0b0000_1101)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 1), 0b0001_1010)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 2), 0b0011_0100)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 3), 0b0110_1000)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 4), 0b1101_0000)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 5), 0b1010_0001)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 6), 0b0100_0011)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, 7), 0b1000_0110)

	{
		// 8 single bit rotations should result in the original number
		r := u8(0b1101)
		for _ in 1..=8 {
			r = bits.rotate_left8(r, 1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// 16 single bit rotations should result in the original number
		r := u16(0b1101)
		for _ in 1..=16 {
			r = bits.rotate_left16(r, 1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// 32 single bit rotations should result in the original number
		r := u32(0b1101)
		for _ in 1..=32 {
			r = bits.rotate_left32(r, 1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// 64 single bit rotations should result in the original number
		r := u64(0b1101)
		for _ in 1..=64 {
			r = bits.rotate_left64(r, 1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// `size_of(uint) * 8` single bit rotations should result in the original number
		r := uint(0b1101)
		for _ in 1..=(size_of(uint) * 8) {
			r = bits.rotate_left(r, 1)
		}
		testing.expect_value(t, r, 0b1101)
	}

	// rotate right = rotate left by negative amount

	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -0), 0b0000_1101)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -1), 0b1000_0110)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -2), 0b0100_0011)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -3), 0b1010_0001)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -4), 0b1101_0000)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -5), 0b0110_1000)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -6), 0b0011_0100)
	testing.expect_value(t, bits.rotate_left8(0b0000_1101, -7), 0b0001_1010)

	{
		// 8 single bit rotations should result in the original number
		r := u8(0b1101)
		for _ in 1..=8 {
			r = bits.rotate_left8(r, -1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// 16 single bit rotations should result in the original number
		r := u16(0b1101)
		for _ in 1..=16 {
			r = bits.rotate_left16(r, -1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// 32 single bit rotations should result in the original number
		r := u32(0b1101)
		for _ in 1..=32 {
			r = bits.rotate_left32(r, -1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// 64 single bit rotations should result in the original number
		r := u64(0b1101)
		for _ in 1..=64 {
			r = bits.rotate_left64(r, -1)
		}
		testing.expect_value(t, r, 0b1101)
	}
	{
		// `size_of(uint) * 8` single bit rotations should result in the original number
		r := uint(0b1101)
		for _ in 1..=(size_of(uint) * 8) {
			r = bits.rotate_left(r, -1)
		}
		testing.expect_value(t, r, 0b1101)
	}
}

@test
test_insert_extract :: proc(t: ^testing.T) {
	// replace 1..=8 bits in a random 64-bit number at all possible offsets
	// extract them again, and compare to the original insert
	for pattern_to_insert in u64(1)..<255 {
		base       := rand.uint64()
		bit_count  := uint(bits.len(pattern_to_insert))
		max_offset := uint(64) - bit_count
		for offset in uint(0)..<max_offset {
			replaced  := bits.bitfield_insert(base, pattern_to_insert, offset, bit_count)
			extracted := bits.bitfield_extract(replaced, offset, bit_count)

			testing.expect_value(t, extracted, pattern_to_insert)

			// Test that the original number and the replaced number
			// are the same, except for the replaced bits
			mask := ~(u64(1<<bit_count - 1) << offset)
			testing.expect_value(t, base & mask, replaced & mask)
		}
	}
}