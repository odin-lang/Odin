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

@(private="file")
splitmix64 :: proc(state: ^u64) -> u64 {
	state^ += 0x9e3779b97f4a7c15
	z := state^
	z = (z ~ (z >> 30)) * 0xbf58476d1ce4e5b9
	z = (z ~ (z >> 27)) * 0x94d049bb133111eb
	return z ~ (z >> 31)
}

@(private="file")
wide_mul_u64 :: proc(x, y: u64) -> (hi, lo: u64) {
	M :: 1<<32 - 1
	x0, x1 := x & M, x >> 32
	y0, y1 := y & M, y >> 32
	p00 := x0 * y0
	p01 := x0 * y1
	p10 := x1 * y0
	p11 := x1 * y1
	mid := (p00 >> 32) + (p01 & M) + (p10 & M)
	lo = (mid << 32) | (p00 & M)
	hi = p11 + (p01 >> 32) + (p10 >> 32) + (mid >> 32)
	return
}

@(private="file")
EDGES_U32 := []u32{0, 1, 2, 3, 0xffff, 0x1_0000, 0x1234_5678, 0x7fff_ffff, 0x8000_0000, 0x8000_0001, 0xdead_beef, max(u32) - 1, max(u32)}

@(private="file")
EDGES_U64 := []u64{0, 1, 2, 3, 0xffff_ffff, 0x1_0000_0000, 0x1_0000_0001, 0x0123_4567_89ab_cdef, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0x8000_0000_0000_0001, 0x8000_0000_ffff_ffff, 0xdead_beef_cafe_babe, max(u64) - 1, max(u64)}

@test
test_add_sub_u32 :: proc(t: ^testing.T) {
	for x in EDGES_U32 {
		for y in EDGES_U32 {
			for c in u32(0)..=1 {
				s := u64(x) + u64(y) + u64(c)
				sum, carry := bits.add_u32(x, y, c)
				testing.expectf(t, sum == u32(s) && carry == u32(s >> 32), "add_u32(%x, %x, %v): expected %x, %v, got %x, %v", x, y, c, u32(s), s >> 32, sum, carry)

				d := i64(x) - i64(y) - i64(c)
				diff, borrow := bits.sub_u32(x, y, c)
				testing.expectf(t, diff == u32(d) && borrow == u32(d < 0), "sub_u32(%x, %x, %v): expected %x, %v, got %x, %v", x, y, c, u32(d), d < 0, diff, borrow)

				when size_of(uint) == size_of(u32) {
					usum, ucarry := bits.add_uint(uint(x), uint(y), uint(c))
					testing.expectf(t, usum == uint(sum) && ucarry == uint(carry), "add_uint(%x, %x, %v): got %x, %v", x, y, c, usum, ucarry)
					udiff, uborrow := bits.sub_uint(uint(x), uint(y), uint(c))
					testing.expectf(t, udiff == uint(diff) && uborrow == uint(borrow), "sub_uint(%x, %x, %v): got %x, %v", x, y, c, udiff, uborrow)
				}
			}
		}
	}
}

@test
test_add_sub_u64 :: proc(t: ^testing.T) {
	M :: 1<<32 - 1
	for x in EDGES_U64 {
		for y in EDGES_U64 {
			for c in u64(0)..=1 {
				lo := (x & M) + (y & M) + c
				hi := (x >> 32) + (y >> 32) + (lo >> 32)
				want_sum, want_carry := (hi << 32) | (lo & M), hi >> 32
				sum, carry := bits.add_u64(x, y, c)
				testing.expectf(t, sum == want_sum && carry == want_carry, "add_u64(%x, %x, %v): expected %x, %v, got %x, %v", x, y, c, want_sum, want_carry, sum, carry)

				dlo := i64(x & M) - i64(y & M) - i64(c)
				lo_borrow := i64(dlo < 0)
				dhi := i64(x >> 32) - i64(y >> 32) - lo_borrow
				want_diff := (u64(dhi) & M) << 32 | (u64(dlo + lo_borrow << 32) & M)
				want_borrow := u64(dhi < 0)
				diff, borrow := bits.sub_u64(x, y, c)
				testing.expectf(t, diff == want_diff && borrow == want_borrow, "sub_u64(%x, %x, %v): expected %x, %v, got %x, %v", x, y, c, want_diff, want_borrow, diff, borrow)

				when size_of(uint) == size_of(u64) {
					usum, ucarry := bits.add_uint(uint(x), uint(y), uint(c))
					testing.expectf(t, usum == uint(sum) && ucarry == uint(carry), "add_uint(%x, %x, %v): got %x, %v", x, y, c, usum, ucarry)
					udiff, uborrow := bits.sub_uint(uint(x), uint(y), uint(c))
					testing.expectf(t, udiff == uint(diff) && uborrow == uint(borrow), "sub_uint(%x, %x, %v): got %x, %v", x, y, c, udiff, uborrow)
				}
			}
		}
	}
}

@test
test_mul :: proc(t: ^testing.T) {
	for x in EDGES_U32 {
		for y in EDGES_U32 {
			p := u64(x) * u64(y)
			hi, lo := bits.mul_u32(x, y)
			testing.expectf(t, hi == u32(p >> 32) && lo == u32(p), "mul_u32(%x, %x): expected %x, %x, got %x, %x", x, y, u32(p >> 32), u32(p), hi, lo)
			when size_of(uint) == size_of(u32) {
				uhi, ulo := bits.mul_uint(uint(x), uint(y))
				testing.expectf(t, uhi == uint(hi) && ulo == uint(lo), "mul_uint(%x, %x): got %x, %x", x, y, uhi, ulo)
			}
		}
	}

	state := u64(0x6d756c)
	xs := make([dynamic]u64, context.temp_allocator)
	append(&xs, ..EDGES_U64)
	for _ in 0..<64 {
		append(&xs, splitmix64(&state) >> (splitmix64(&state) & 63))
	}
	for x in xs {
		for y in xs {
			want_hi, want_lo := wide_mul_u64(x, y)
			hi, lo := bits.mul_u64(x, y)
			testing.expectf(t, hi == want_hi && lo == want_lo, "mul_u64(%x, %x): expected %x, %x, got %x, %x", x, y, want_hi, want_lo, hi, lo)
			when size_of(uint) == size_of(u64) {
				uhi, ulo := bits.mul_uint(uint(x), uint(y))
				testing.expectf(t, uhi == uint(hi) && ulo == uint(lo), "mul_uint(%x, %x): got %x, %x", x, y, uhi, ulo)
			}
		}
	}
}

@test
test_div_u64 :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, hi, lo, y: u64) {
		q, r := bits.div_u64(hi, lo, y)
		ph, pl := wide_mul_u64(q, y)
		sl := pl + r
		sh := ph + u64(sl < pl)
		testing.expectf(t, r < y && sh == hi && sl == lo, "div_u64(%x, %x, %x): got %x, %x", hi, lo, y, q, r)
		when size_of(uint) == size_of(u64) {
			uq, ur := bits.div_uint(uint(hi), uint(lo), uint(y))
			testing.expectf(t, uq == uint(q) && ur == uint(r), "div_uint(%x, %x, %x): got %x, %x", hi, lo, y, uq, ur)
		}
	}

	for y in EDGES_U64 {
		if y == 0 {
			continue
		}
		for hi in ([]u64{0, 1, y / 2, y - 1}) {
			if hi >= y {
				continue
			}
			for lo in EDGES_U64 {
				check(t, hi, lo, y)
			}
		}
	}

	state := u64(0x646976)
	for _ in 0..<100_000 {
		y := splitmix64(&state) >> (splitmix64(&state) & 63)
		if y == 0 {
			continue
		}
		hi := splitmix64(&state) % y
		lo := splitmix64(&state)
		if splitmix64(&state) & 3 == 0 {
			hi = y - 1
		}
		check(t, hi, lo, y)
	}
}

@test
test_len :: proc(t: ^testing.T) {
	bit_length :: proc(x: u64) -> int {
		x, n := x, 0
		for x != 0 {
			x >>= 1
			n += 1
		}
		return n
	}

	for x in 0..=int(max(u8)) {
		testing.expectf(t, bits.len_u8(u8(x)) == bit_length(u64(x)), "len_u8(%v): got %v", x, bits.len_u8(u8(x)))
	}
	for x in 0..=int(max(u16)) {
		testing.expectf(t, bits.len_u16(u16(x)) == bit_length(u64(x)), "len_u16(%v): got %v", x, bits.len_u16(u16(x)))
	}

	values := make([dynamic]u64, context.temp_allocator)
	append(&values, 0, max(u64))
	for k in uint(0)..<64 {
		append(&values, 1 << k, 1 << k - 1, 1 << k | 1, max(u64) >> k)
	}
	for x in values {
		want := bit_length(x)
		testing.expectf(t, bits.len_u64(x) == want, "len_u64(%x): got %v", x, bits.len_u64(x))
		if x <= u64(max(u32)) {
			testing.expectf(t, bits.len_u32(u32(x)) == want, "len_u32(%x): got %v", x, bits.len_u32(u32(x)))
		}
		if x <= u64(max(uint)) {
			testing.expectf(t, bits.len_uint(uint(x)) == want, "len_uint(%x): got %v", x, bits.len_uint(uint(x)))
		}
	}
}

@test
test_is_power_of_two :: proc(t: ^testing.T) {
	is_pot :: proc(x: i128) -> bool {
		for k in uint(0)..<127 {
			if x == 1 << k {
				return true
			}
		}
		return false
	}

	for x in 0..=int(max(u8)) {
		testing.expectf(t, bits.is_power_of_two_u8(u8(x)) == is_pot(i128(x)), "is_power_of_two_u8(%v)", x)
		testing.expectf(t, bits.is_power_of_two_i8(i8(x)) == is_pot(i128(i8(x))), "is_power_of_two_i8(%v)", i8(x))
	}
	for x in 0..=int(max(u16)) {
		testing.expectf(t, bits.is_power_of_two_u16(u16(x)) == is_pot(i128(x)), "is_power_of_two_u16(%v)", x)
		testing.expectf(t, bits.is_power_of_two_i16(i16(x)) == is_pot(i128(i16(x))), "is_power_of_two_i16(%v)", i16(x))
	}

	values := make([dynamic]u64, context.temp_allocator)
	append(&values, 0, max(u64))
	for k in uint(0)..<64 {
		p := u64(1) << k
		append(&values, p, p - 1, p + 1, -p, -p + 1, -p - 1)
	}
	for x in values {
		testing.expectf(t, bits.is_power_of_two_u64(x) == is_pot(i128(x)), "is_power_of_two_u64(%x)", x)
		testing.expectf(t, bits.is_power_of_two_i64(i64(x)) == is_pot(i128(i64(x))), "is_power_of_two_i64(%v)", i64(x))
		testing.expectf(t, bits.is_power_of_two_u32(u32(x)) == is_pot(i128(u32(x))), "is_power_of_two_u32(%x)", u32(x))
		testing.expectf(t, bits.is_power_of_two_i32(i32(x)) == is_pot(i128(i32(x))), "is_power_of_two_i32(%v)", i32(x))
		testing.expectf(t, bits.is_power_of_two_uint(uint(x)) == is_pot(i128(uint(x))), "is_power_of_two_uint(%x)", uint(x))
		testing.expectf(t, bits.is_power_of_two_int(int(x)) == is_pot(i128(int(x))), "is_power_of_two_int(%v)", int(x))
	}
}

@test
test_endian :: proc(t: ^testing.T) {
	for x in 0..=int(max(u8)) {
		b := u8(x)
		testing.expect(t, bits.to_be_u8(b) == b && bits.to_le_u8(b) == b && bits.from_be_u8(b) == b && bits.from_le_u8(b) == b)
	}

	x16 := u16(0x0102)
	testing.expect_value(t, transmute([2]u8)bits.to_be_u16(x16), [2]u8{1, 2})
	testing.expect_value(t, transmute([2]u8)bits.to_le_u16(x16), [2]u8{2, 1})
	testing.expect_value(t, bits.from_be_u16(transmute(u16)[2]u8{1, 2}), x16)
	testing.expect_value(t, bits.from_le_u16(transmute(u16)[2]u8{2, 1}), x16)

	x32 := u32(0x0102_0304)
	testing.expect_value(t, transmute([4]u8)bits.to_be_u32(x32), [4]u8{1, 2, 3, 4})
	testing.expect_value(t, transmute([4]u8)bits.to_le_u32(x32), [4]u8{4, 3, 2, 1})
	testing.expect_value(t, bits.from_be_u32(transmute(u32)[4]u8{1, 2, 3, 4}), x32)
	testing.expect_value(t, bits.from_le_u32(transmute(u32)[4]u8{4, 3, 2, 1}), x32)

	x64 := u64(0x0102_0304_0506_0708)
	testing.expect_value(t, transmute([8]u8)bits.to_be_u64(x64), [8]u8{1, 2, 3, 4, 5, 6, 7, 8})
	testing.expect_value(t, transmute([8]u8)bits.to_le_u64(x64), [8]u8{8, 7, 6, 5, 4, 3, 2, 1})
	testing.expect_value(t, bits.from_be_u64(transmute(u64)[8]u8{1, 2, 3, 4, 5, 6, 7, 8}), x64)
	testing.expect_value(t, bits.from_le_u64(transmute(u64)[8]u8{8, 7, 6, 5, 4, 3, 2, 1}), x64)

	N :: size_of(uint)
	be, le: [N]u8
	xu: uint
	for i in 0..<N {
		be[i] = u8(i + 1)
		le[N - 1 - i] = u8(i + 1)
		xu = xu << 8 | uint(i + 1)
	}
	testing.expect_value(t, transmute([N]u8)bits.to_be_uint(xu), be)
	testing.expect_value(t, transmute([N]u8)bits.to_le_uint(xu), le)
	testing.expect_value(t, bits.from_be_uint(transmute(uint)be), xu)
	testing.expect_value(t, bits.from_le_uint(transmute(uint)le), xu)
}
