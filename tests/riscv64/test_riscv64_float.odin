package test_riscv64

import "base:intrinsics"
import "core:math/rand"
import "core:testing"

@(test)
float_f16_to_wider_exhaustive :: proc(t: ^testing.T) {
	for h in 0..=0xffff {
		x := transmute(f16)u16(h)
		want := ref_f16_to_f64(u16(h))
		got64 := f64(x)
		got32 := f32(x)
		if want != want {
			testing.expectf(t, got64 != got64 && got32 != got32, "f16 %4x: got %x, %x, want NaN", h, transmute(u64)got64, transmute(u32)got32)
			continue
		}
		testing.expectf(t, transmute(u64)got64 == transmute(u64)want, "f64(f16 %4x) = %x, want %x", h, transmute(u64)got64, transmute(u64)want)
		testing.expectf(t, transmute(u32)got32 == transmute(u32)f32(want), "f32(f16 %4x) = %x, want %x", h, transmute(u32)got32, transmute(u32)f32(want))
		testing.expectf(t, transmute(u16)f16(got32) == u16(h), "f16(f32(f16 %4x)) = %4x", h, transmute(u16)f16(got32))
	}
}

@(test)
float_narrow_to_f16 :: proc(t: ^testing.T) {
	rand.reset(0x0f16)
	edges := [?]u64{
		0x3ff0_0200_0000_0000, 0x3ff0_0200_0000_0001, 0x3ff0_0600_0000_0000, 0x3ff0_0200_0010_0000,
		0x40ef_fe00_0000_0000, 0x40ef_fc00_0000_0000, 0x40ef_fdff_ffff_ffff, 0x3e70_0000_0000_0000,
		0x3e60_0000_0000_0000, 0x3e60_0000_0000_0001, 0x3e78_0000_0000_0000, 0x3f0f_f800_0000_0000,
		0x8000_0000_0000_0000, 0x7ff0_0000_0000_0000, 0x0000_0000_0000_0001, 0xc0ef_fe00_0000_0000,
	}
	for i in 0..<200_000 {
		bits: u64
		if i < len(edges) {
			bits = edges[i]
		} else {
			exp := 1023 - 30 + rand.uint64() % 50
			bits = (rand.uint64() & (1 << 63)) | exp << 52 | (rand.uint64() & (1 << 52 - 1))
			if i % 3 == 0 {
				bits = (bits &~ (1 << 42 - 1)) | 1 << 41
			}
		}
		x := transmute(f64)bits
		want := ref_f64_to_f16(bits)
		got := transmute(u16)f16(x)
		testing.expectf(t, got == want, "f16(f64 %16x) = %4x, want %4x", bits, got, want)

		y := f32(x)
		want32 := ref_f64_to_f16(transmute(u64)f64(y))
		got32 := transmute(u16)f16(y)
		testing.expectf(t, got32 == want32, "f16(f32 %8x) = %4x, want %4x", transmute(u32)y, got32, want32)
	}
}

@(test)
float_moves_keep_nan_payloads :: proc(t: ^testing.T) {
	Pair :: struct {
		a: f32,
		b: f64,
	}
	pass_c :: #force_no_inline proc "c" (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9: f32, d0, d1, d2, d3, d4, d5, d6, d7, d8: f64, p: Pair) -> (f32, f64) {
		return a9, d8
	}
	pass_odin :: #force_no_inline proc(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9: f32, d0, d1, d2, d3, d4, d5, d6, d7, d8: f64, p: Pair) -> (Pair, f32) {
		return p, a9
	}
	singles := [?]u32{0x7fa0_0001, 0xffbf_ffff, 0x7f80_0001, 0x7fc1_2345, 0xff80_0000, 0x0000_0001}
	doubles := [?]u64{0x7ff4_0000_0000_0001, 0xfff7_ffff_ffff_ffff, 0x7ff8_1234_5678_9abc, 0x0000_0000_0000_0001}
	for s in singles {
		for d in doubles {
			x, y := transmute(f32)s, transmute(f64)d
			p := Pair{x, y}

			rx, ry := pass_c(0, 0, 0, 0, 0, 0, 0, 0, 0, x, 0, 0, 0, 0, 0, 0, 0, 0, y, p)
			testing.expectf(t, transmute(u32)rx == s && transmute(u64)ry == d, "c: %8x %16x -> %8x %16x", s, d, transmute(u32)rx, transmute(u64)ry)

			rp, rx2 := pass_odin(0, 0, 0, 0, 0, 0, 0, 0, 0, x, 0, 0, 0, 0, 0, 0, 0, 0, y, p)
			testing.expectf(t, transmute(u32)rp.a == s && transmute(u64)rp.b == d && transmute(u32)rx2 == s, "odin: %8x %16x -> %8x %16x %8x", s, d, transmute(u32)rp.a, transmute(u64)rp.b, transmute(u32)rx2)

			boxed: any = x
			testing.expectf(t, transmute(u32)(boxed.(f32)) == s, "any: %8x -> %8x", s, transmute(u32)(boxed.(f32)))

			arr := [3]f32{x, x, x}
			copy_arr := arr
			testing.expectf(t, transmute(u32)copy_arr[2] == s, "array copy: %8x -> %8x", s, transmute(u32)copy_arr[2])

			pick := x if s & 1 == 1 else transmute(f32)s
			testing.expectf(t, transmute(u32)pick == s, "select: %8x -> %8x", s, transmute(u32)pick)
		}
	}
}

@(test)
float_int_conversions :: proc(t: ^testing.T) {
	to_i32 := [?]struct{x: f64, want: i32}{
		{2.9, 2}, {-2.9, -2}, {2147483647.9, 2147483647}, {-2147483648.9, -2147483648},
	}
	for c in to_i32 {
		x := c.x
		testing.expectf(t, i32(x) == c.want, "i32(%v) = %v", x, i32(x))
	}
	to_i64 := [?]struct{x: f64, want: i64}{
		{-2.9, -2}, {9223372036854774784.0, 9223372036854774784}, {-9223372036854775808.0, -9223372036854775808},
	}
	for c in to_i64 {
		x := c.x
		testing.expectf(t, i64(x) == c.want, "i64(%v) = %v", x, i64(x))
	}
	to_u64 := [?]struct{x: f64, want: u64}{
		{2.9, 2}, {9223372036854775808.0, 9223372036854775808}, {18446744073709549568.0, 18446744073709549568},
	}
	for c in to_u64 {
		x := c.x
		testing.expectf(t, u64(x) == c.want, "u64(%v) = %v", x, u64(x))
	}
	to_u32 := [?]struct{x: f32, want: u32}{
		{4294967040.0, 4294967040}, {2147483648.0, 2147483648}, {0.75, 0},
	}
	for c in to_u32 {
		x := c.x
		testing.expectf(t, u32(x) == c.want, "u32(%v) = %v", x, u32(x))
	}

	U64_To_Float :: struct {
		x:   u64,
		f64: f64,
		f32: f32,
	}
	from_u64 := [?]U64_To_Float{
		{0xffff_ffff_ffff_ffff, 0h43f0000000000000, 0h5f800000},
		{0x8000_0000_0000_0401, 0h43e0000000000001, 0h5f000000},
		{0x8000_0080_0000_0000, 0h43e0000010000000, 0h5f000000},
		{0x8000_0180_0000_0000, 0h43e0000030000000, 0h5f000002},
		{0x0000_0000_ffff_ffff, 0h41efffffffe00000, 0h4f800000},
		{0x0000_0000_0100_0001, 0h4170000010000000, 0h4b800000},
		{0x0000_0000_0100_0003, 0h4170000030000000, 0h4b800002},
	}
	for c in from_u64 {
		x := c.x
		testing.expectf(t, transmute(u64)f64(x) == transmute(u64)c.f64, "f64(u64 %x) = %x", x, transmute(u64)f64(x))
		testing.expectf(t, transmute(u32)f32(x) == transmute(u32)c.f32, "f32(u64 %x) = %x", x, transmute(u32)f32(x))
		if x <= 0xffff_ffff {
			w := u32(x)
			testing.expectf(t, transmute(u32)f32(w) == transmute(u32)c.f32, "f32(u32 %x) = %x", w, transmute(u32)f32(w))
		}
	}
}

@(test)
float_fused_and_sqrt :: proc(t: ^testing.T) {
	d := [?]f64{0h3ff0000000000001, 0hbff0000000000002, 0h4000000000000000}
	s := [?]f32{0h3f800001, 0hbf800002, 0h40000000}
	testing.expect_value(t, transmute(u64)intrinsics.fused_mul_add(d[0], d[0], d[1]), u64(0x3970_0000_0000_0000))
	testing.expect_value(t, transmute(u32)intrinsics.fused_mul_add(s[0], s[0], s[1]), u32(0x2880_0000))
	testing.expect_value(t, transmute(u64)intrinsics.sqrt(d[2]), u64(0x3ff6_a09e_667f_3bcd))
	testing.expect_value(t, transmute(u32)intrinsics.sqrt(s[2]), u32(0x3fb5_04f3))
}

ref_f16_to_f64 :: proc(h: u16) -> f64 {
	exp := int(h >> 10) & 0x1f
	mant := u64(h & 0x3ff)
	mag: f64
	switch exp {
	case 0:
		mag = f64(mant) * 0h3e70000000000000
	case 0x1f:
		mag = transmute(f64)u64(0x7ff0_0000_0000_0000 | (0x8_0000_0000_0000 if mant != 0 else 0))
	case:
		mag = f64(1024 + mant) * transmute(f64)(u64(exp - 25 + 1023) << 52)
	}
	return -mag if h & 0x8000 != 0 else mag
}

ref_f64_to_f16 :: proc(bits: u64) -> u16 {
	sign := u16(bits >> 48) & 0x8000
	exp := int(bits >> 52) & 0x7ff
	mant := bits & (1 << 52 - 1)
	if exp == 0x7ff {
		return sign | (0x7e00 if mant != 0 else 0x7c00)
	}
	if exp == 0 && mant == 0 {
		return sign
	}
	full := mant | (1 << 52) if exp != 0 else mant
	e := exp - 1023 if exp != 0 else -1022
	shift := 42 if e >= -14 else 28 - e
	if shift > 62 {
		return sign
	}
	q := full >> uint(shift)
	rem := full & (u64(1) << uint(shift) - 1)
	half := u64(1) << uint(shift - 1)
	if rem > half || (rem == half && q & 1 == 1) {
		q += 1
	}
	if e < -14 {
		return sign | u16(q)
	}
	if q == 2048 {
		q = 1024
		e += 1
	}
	if e > 15 {
		return sign | 0x7c00
	}
	return sign | u16(e + 15) << 10 | u16(q - 1024)
}
