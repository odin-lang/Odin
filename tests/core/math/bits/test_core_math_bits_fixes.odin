package test_core_math_bits

import "core:math/bits"
import "core:testing"

@test
test_div_u32 :: proc(t: ^testing.T) {
	ys := []u32{1, 2, 3, 7, 10, 255, 256, 65535, 65536, 1<<31 - 1, 1<<31, 1<<31 + 1, max(u32) - 1, max(u32)}
	los := []u32{0, 1, 2, 12345, 1<<31, max(u32) - 1, max(u32)}
	for y in ys {
		for hi in ([]u32{0, 1, y / 2, y - 1}) {
			if hi >= y {
				continue
			}
			for lo in los {
				n := u64(hi) << 32 | u64(lo)
				q, r := bits.div_u32(hi, lo, y)
				testing.expectf(t, u64(q) == n / u64(y) && u64(r) == n % u64(y), "div_u32(%v, %v, %v): expected %v, %v, got %v, %v", hi, lo, y, n / u64(y), n % u64(y), q, r)

				uq, ur := bits.div_uint(uint(hi), uint(lo), uint(y))
				when size_of(uint) == size_of(u32) {
					testing.expectf(t, uq == uint(q) && ur == uint(r), "div_uint(%v, %v, %v): expected %v, %v, got %v, %v", hi, lo, y, q, r, uq, ur)
				} else {
					n128 := u128(hi) << 64 | u128(lo)
					testing.expectf(t, u128(uq) == n128 / u128(y) && u128(ur) == n128 % u128(y), "div_uint(%v, %v, %v): expected %v, %v, got %v, %v", hi, lo, y, n128 / u128(y), n128 % u128(y), uq, ur)
				}
			}
		}
	}
}

@test
test_bitfield_extract_signed :: proc(t: ^testing.T) {
	for c in 0..<256 {
		x := i8(c)
		for offset in uint(0)..=9 {
			for n in uint(0)..=9 {
				field := (i32(x) >> offset) & (1<<n - 1)
				if n > 0 && (field >> (n - 1)) & 1 != 0 {
					field -= 1 << n
				}
				got := bits.bitfield_extract(x, offset, n)
				testing.expectf(t, got == i8(field), "bitfield_extract(i8(%v), %v, %v): expected %v, got %v", x, offset, n, i8(field), got)
			}
		}
	}

	testing.expect_value(t, bits.bitfield_extract(i16(-1), 2, 15), -1)
	testing.expect_value(t, bits.bitfield_extract(min(i32), 31, 1), -1)
	testing.expect_value(t, bits.bitfield_extract(min(i64), 1, 64), min(i64) >> 1)
	testing.expect_value(t, bits.bitfield_extract(i128(-12345), 3, 200), i128(-12345) >> 3)
	testing.expect_value(t, bits.bitfield_extract(min(int), 8*size_of(int) + 6, 5), -1)
	testing.expect_value(t, bits.bitfield_extract(max(int), 8*size_of(int) - 3, 8), 3)
}
