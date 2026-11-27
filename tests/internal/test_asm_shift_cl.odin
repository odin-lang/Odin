#+build amd64
package test_internal

import "core:math/bits"
import "core:testing"

// A shift or rotate by %cl could not be written: `shr r, %cl` was rejected, and a bare `shr r` shifts by one.
// The count is now named: %cl itself, or an 8-bit operand pinned to %rcx.
// The hardware masks the count to its low 6 bits for a 64-bit operand, and to its low 5 bits otherwise.

@(rodata)
SHIFT_COUNTS := [?]u64{0, 1, 4, 7, 9, 15, 17, 31, 32, 33, 63, 64, 65, 200, 255, 0x104}

@(test)
asm_shift_by_cl_64 :: proc(t: ^testing.T) {
	shl_cl :: asm(x: u64, c: u64) -> (r: u64) [
		x -> r,
		c = %rcx,
	] {
		shl r, %cl
	}
	shr_cl :: asm(x: u64, c: u64) -> (r: u64) [
		x -> r,
		c = %rcx,
	] {
		shr r, %cl
	}
	sar_cl :: asm(x: i64, c: u64) -> (r: i64) [
		x -> r,
		c = %rcx,
	] {
		sar r, %cl
	}
	sal_cl :: asm(x: i64, c: u64) -> (r: i64) [
		x -> r,
		c = %rcx,
	] {
		sal r, %cl
	}
	rol_cl :: asm(x: u64, c: u64) -> (r: u64) [
		x -> r,
		c = %rcx,
	] {
		rol r, %cl
	}
	ror_cl :: asm(x: u64, c: u64) -> (r: u64) [
		x -> r,
		c = %rcx,
	] {
		ror r, %cl
	}

	x := u64(0x8123_4567_89ab_cdef)
	s := i64(x)

	for c in SHIFT_COUNTS {
		n := uint(c & 63)

		testing.expectf(t, shl_cl(x, c) == x << n, "shl by %d", c)
		testing.expectf(t, shr_cl(x, c) == x >> n, "shr by %d", c)
		testing.expectf(t, sar_cl(s, c) == s >> n, "sar by %d", c)
		testing.expectf(t, sal_cl(s, c) == s << n, "sal by %d", c)

		testing.expectf(t, rol_cl(x, c) == bits.rotate_left64(x,  int(n)), "rol by %d", c)
		testing.expectf(t, ror_cl(x, c) == bits.rotate_left64(x, -int(n)), "ror by %d", c)
	}
}

@(test)
asm_shift_by_cl_narrow :: proc(t: ^testing.T) {
	shl_32 :: asm(x: u32, c: u8) -> (r: u32) [
		x -> r,
		c = %cl,
	] {
		shl r, c
	}
	shr_16 :: asm(x: u16, c: u64) -> (r: u16) [
		x -> r,
		c = %rcx,
		cb: u8 = c,
	] {
		shr r, cb
	}
	sar_8 :: asm(x: i8, c: u64) -> (r: i8) [
		x -> r,
		c = %rcx,
	] {
		sar r, %cl
	}
	rol_8 :: asm(x: u8, c: u64) -> (r: u8) [
		x -> r,
		c = %rcx,
	] {
		rol r, %cl
	}
	ror_16 :: asm(x: u16, c: u64) -> (r: u16) [
		x -> r,
		c = %rcx,
	] {
		ror r, %cl
	}

	for c in SHIFT_COUNTS {
		n := uint(c & 31)

		testing.expectf(t, shl_32(0x8123_4567, u8(c)) == u32(0x8123_4567) << n, "shl by %d", c)
		testing.expectf(t, shr_16(0x8123, c)          == u16(0x8123) >> n,      "shr by %d", c)
		testing.expectf(t, sar_8(-100, c)             == i8(-100) >> n,         "sar by %d", c)

		testing.expectf(t, rol_8(0x81, c)    == bits.rotate_left8(0x81,     int(n)),  "rol by %d", c)
		testing.expectf(t, ror_16(0x8123, c) == bits.rotate_left16(0x8123, -int(n)), "ror by %d", c)
	}
}

@(test)
asm_rotate_through_carry_by_cl :: proc(t: ^testing.T) {
	rcl_set :: asm(x: u64, c: u64) -> (r: u64) [
		x -> r,
		c = %rcx,
	] {
		stc
		rcl r, %cl
	}
	rcr_clear :: asm(x: u64, c: u64) -> (r: u64) [
		x -> r,
		c = %rcx,
	] {
		clc
		rcr r, %cl
	}

	testing.expect_value(t, rcl_set(0, 0),  u64(0))
	testing.expect_value(t, rcl_set(0, 1),  u64(1))
	testing.expect_value(t, rcl_set(0, 2),  u64(2))
	testing.expect_value(t, rcl_set(0, 64), u64(0))
	testing.expect_value(t, rcl_set(0, 65), u64(1))

	testing.expect_value(t, rcr_clear(1, 0),  u64(1))
	testing.expect_value(t, rcr_clear(1, 1),  u64(0))
	testing.expect_value(t, rcr_clear(1, 2),  u64(1) << 63)
	testing.expect_value(t, rcr_clear(1, 64), u64(1))
}

@(test)
asm_double_shift_by_cl :: proc(t: ^testing.T) {
	shld_cl :: asm(a: u64, b: u64, c: u64) -> (r: u64) [
		a -> r,
		c = %rcx,
	] {
		shld r, b, %cl
	}
	shrd_cl :: asm(a: u64, b: u64, c: u64) -> (r: u64) [
		a -> r,
		c = %rcx,
		cb: u8 = c,
	] {
		shrd r, b, cb
	}

	a := u64(0x0123_4567_89ab_cdef)
	b := u64(0xfedc_ba98_7654_3210)

	for c in SHIFT_COUNTS {
		n := uint(c & 63)

		testing.expectf(t, shld_cl(a, b, c) == a << n | b >> (64 - n), "shld by %d", c)
		testing.expectf(t, shrd_cl(a, b, c) == a >> n | b << (64 - n), "shrd by %d", c)
	}
}
