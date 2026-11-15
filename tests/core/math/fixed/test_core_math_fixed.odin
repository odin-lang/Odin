package test_core_math_fixed

import "base:intrinsics"
import "core:math/fixed"
import "core:strconv"
import "core:testing"

@test
test_fixed_4_4_unsigned :: proc(t: ^testing.T) {
	I_SHIFT :: 4
	F_MASK  :: 15
	F_ULP   :: 0.0625
	Fixed   :: fixed.Fixed(u8, 4)

	for c in 0..<256 {
		raw := u8(c)
		fv  := transmute(Fixed)raw

		i := raw >> I_SHIFT
		f := raw &  F_MASK
		expected := f64(i) + F_ULP * f64(f)

		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(u8, 4)(%v) to equal %.5f, got %.5f", raw, expected, fixed.to_f64(fv))
	}
}

@test
test_fixed_4_4_signed :: proc(t: ^testing.T) {
	I_SHIFT :: 4
	F_MASK  :: 15
	F_ULP   :: 0.0625
	Fixed   :: fixed.Fixed(i8, 4)

	for c in 0..<256 {
		raw := i8(c)
		fv  := transmute(Fixed)raw

		f := raw & F_MASK
		expected: f64
		if c < 128 {
			i := raw >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		} else {
			i := i8(-8)
			i += (raw & 0b0111_0000) >> I_SHIFT
			expected = f64(i) + F_ULP * f64(f)
		}
		testing.expectf(t, fixed.to_f64(fv) == expected, "Expected Fixed(i8, 4)(%v, %v) to equal %.5f, got %.5f", c, raw, expected, fixed.to_f64(fv))
	}
}
// 64-bit division with a large scale needs a 128-bit dividend
@test
test_fixed_point_div_64 :: proc(t: ^testing.T) {
	floor_div :: proc(x, y: i64, scale: uint, sat: bool) -> i64 {
		n := i128(x) << scale
		q := n / i128(y)
		if r := n % i128(y); r != 0 && (r < 0) != (y < 0) {
			q -= 1
		}
		if sat {
			q = clamp(q, i128(min(i64)), i128(max(i64)))
		}
		return i64(q)
	}
	udiv :: proc(x, y: u64, scale: uint, sat: bool) -> u64 {
		q := (u128(x) << scale) / u128(y)
		if sat {
			q = min(q, u128(max(u64)))
		}
		return u64(q)
	}

	values := []i64{1, -1, 3, -7, 1<<40, -(1<<40), 123456789, -987654321, max(i64), min(i64)+1}
	for x in values {
		for y in values {
			testing.expect_value(t, intrinsics.fixed_point_div(x, y, 62),     floor_div(x, y, 62, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(x, y, 62), floor_div(x, y, 62, true))
			testing.expect_value(t, intrinsics.fixed_point_div(x, y, 32),     floor_div(x, y, 32, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(x, y, 32), floor_div(x, y, 32, true))

			ux, uy := u64(x), u64(y)
			testing.expect_value(t, intrinsics.fixed_point_div(ux, uy, 64),     udiv(ux, uy, 64, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(ux, uy, 64), udiv(ux, uy, 64, true))
			testing.expect_value(t, intrinsics.fixed_point_div(ux, uy, 32),     udiv(ux, uy, 32, false))
			testing.expect_value(t, intrinsics.fixed_point_div_sat(ux, uy, 32), udiv(ux, uy, 32, true))
		}
	}
}

@test
test_init_from_f64 :: proc(t: ^testing.T) {
	Case :: struct($B: typeid) {
		val: f64,
		raw: B,
		ok:  bool,
	}
	check :: proc(t: ^testing.T, $B: typeid, $W: uint, cases: []Case(B)) {
		for c in cases {
			x: fixed.Fixed(B, W)
			ok := fixed.init_from_f64(&x, c.val)
			testing.expectf(t, x.i == c.raw && ok == c.ok, "Fixed(%v, %v) from %v: expected %v (%v), got %v (%v)", typeid_of(B), W, c.val, c.raw, c.ok, x.i, ok)
		}
	}

	INF :: 0h7ff0_0000_0000_0000
	NAN :: 0h7ff8_0000_0000_0000

	check(t, i8, 4, {
		{0,       0,    true},
		{1.5,     24,   true},
		{-1.5,    -24,  true},
		{1.99,    31,   true},
		{-1.99,   -31,  true},
		{0.03,    0,    true},
		{7.9375,  127,  true},
		{-8,      -128, true},
		{8,       127,  false},
		{-8.0625, -128, false},
		{1000,    127,  false},
		{-1e300,  -128, false},
		{INF,     127,  false},
		{-INF,    -128, false},
		{NAN,     0,    false},
	})
	check(t, u8, 4, {
		{15.9375, 255, true},
		{-0.03,   0,   true},
		{16,      255, false},
		{-0.0625, 0,   false},
		{NAN,     0,   false},
	})
	check(t, i64, 32, {
		{2147483647.5, 0x7fff_ffff_8000_0000, true},
		{-2147483648,  min(i64),              true},
		{2147483648,   max(i64),              false},
		{1e10,         max(i64),              false},
	})
	check(t, i128, 64, {
		{-9223372036854775808, min(i128), true},
		{9223372036854775808,  max(i128), false},
	})
	check(t, u128, 0, {
		{170141183460469231731687303715884105728, 170141183460469231731687303715884105728, true},
		{340282366920938463463374607431768211456, max(u128),                               false},
	})
	check(t, i32be, 16, {
		{1.5,    98304,     true},
		{-32769, min(i32be), false},
	})

	for c in 0..<256 {
		x := transmute(fixed.Fixed(i8, 4))i8(c)
		y: fixed.Fixed(i8, 4)
		ok := fixed.init_from_f64(&y, fixed.to_f64(x))
		testing.expectf(t, ok && x == y, "Fixed(i8, 4) round trip of %v: got %v (%v)", x.i, y.i, ok)

		ux := transmute(fixed.Fixed(u8, 4))u8(c)
		uy: fixed.Fixed(u8, 4)
		ok = fixed.init_from_f64(&uy, fixed.to_f64(ux))
		testing.expectf(t, ok && ux == uy, "Fixed(u8, 4) round trip of %v: got %v (%v)", ux.i, uy.i, ok)
	}
}

@test
test_init_from_parts_8 :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $B: typeid, $W: uint) {
		for i in 0..<256 {
			for f in 0..<256 {
				x: fixed.Fixed(B, W)
				fixed.init_from_parts(&x, B(i), B(f))
				want := B(i32(B(i)) * (1 << W) + (i32(B(f)) & (1<<W - 1)))
				testing.expectf(t, x.i == want, "Fixed(%v, %v) from parts %v, %v: expected %v, got %v", typeid_of(B), W, B(i), B(f), want, x.i)
			}
		}
	}
	check(t, i8, 0)
	check(t, i8, 1)
	check(t, i8, 2)
	check(t, i8, 3)
	check(t, i8, 4)
	check(t, i8, 5)
	check(t, i8, 6)
	check(t, i8, 7)
	check(t, u8, 0)
	check(t, u8, 1)
	check(t, u8, 2)
	check(t, u8, 3)
	check(t, u8, 4)
	check(t, u8, 5)
	check(t, u8, 6)
	check(t, u8, 7)
	check(t, u8, 8)
}

@test
test_to_f64_wide :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $B: typeid, $W: uint, raw: B, want: f64, loc := #caller_location) {
		x := fixed.Fixed(B, W){raw}
		testing.expectf(t, fixed.to_f64(x) == want, "Fixed(%v, %v)(%v): expected %v, got %v", typeid_of(B), W, raw, want, fixed.to_f64(x), loc = loc)
	}
	check(t, i64, 0, max(i64), 1<<63)
	check(t, i64, 0, min(i64), -(1<<63))
	check(t, i64, 0, 1<<53 + 1, 1<<53)
	check(t, i64, 0, 1<<53 + 3, 1<<53 + 4)
	check(t, i64, 0, -(1<<53 + 1), -(1<<53))
	check(t, i64, 32, max(i64), 1<<31)
	check(t, i64, 32, 1, 1.0 / (1<<32))
	check(t, i64, 63, -1, -1.0 / (1<<63))
	check(t, u64, 0, max(u64), 1<<64)
	check(t, u64, 0, 1<<63 + 1<<10, 1<<63)
	check(t, u64, 0, 1<<63 + 1<<10 + 1, 1<<63 + 1<<11)
	check(t, u64, 64, max(u64), 1)
	check(t, u64, 64, 1<<63, 0.5)
	check(t, i128, 0, 1<<100 + 1<<47, 1<<100)
	check(t, i128, 0, 1<<100 + 1<<47 + 1, 1<<100 + 1<<48)
	check(t, i128, 0, 1<<100 + 3<<47, 1<<100 + 1<<49)
	check(t, i128, 0, -(1<<100 + 1<<47 + 1), -(1<<100 + 1<<48))
	check(t, i128, 64, max(i128), 1<<63)
	check(t, i128, 64, min(i128), -(1<<63))
	check(t, i128, 127, min(i128), -1)
	check(t, u128, 0, max(u128), 1<<128)
	check(t, u128, 0, 1<<127 + 1<<74 + 1, 1<<127 + 1<<75)
	check(t, u128, 64, 1, 1.0 / (1<<64))
	check(t, u128, 128, max(u128), 1)
}

@test
test_add_sub_wrap :: proc(t: ^testing.T) {
	for a in 0..<256 {
		for b in 0..<256 {
			x, y := fixed.Fixed4_4{i8(a)}, fixed.Fixed4_4{i8(b)}
			testing.expectf(t, fixed.add(x, y).i == i8(a + b), "Fixed4_4 %v + %v: got %v", x.i, y.i, fixed.add(x, y).i)
			testing.expectf(t, fixed.sub(x, y).i == i8(a - b), "Fixed4_4 %v - %v: got %v", x.i, y.i, fixed.sub(x, y).i)

			ux, uy := fixed.Fixed(u8, 4){u8(a)}, fixed.Fixed(u8, 4){u8(b)}
			testing.expectf(t, fixed.add(ux, uy).i == u8(a + b), "Fixed(u8, 4) %v + %v: got %v", ux.i, uy.i, fixed.add(ux, uy).i)
			testing.expectf(t, fixed.sub(ux, uy).i == u8(a - b), "Fixed(u8, 4) %v - %v: got %v", ux.i, uy.i, fixed.sub(ux, uy).i)
		}
	}
	testing.expect_value(t, fixed.add(fixed.Fixed16_16{max(i32)}, fixed.Fixed16_16{1}).i, min(i32))
	testing.expect_value(t, fixed.sub(fixed.Fixed16_16{min(i32)}, fixed.Fixed16_16{1}).i, max(i32))
	testing.expect_value(t, fixed.sub(fixed.Fixed(u128, 64){0}, fixed.Fixed(u128, 64){1}).i, max(u128))
}

@test
test_write_8 :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $B: typeid, $W: uint) {
		scale := i32(1)
		for k: uint = 0; k < W; k += 1 {
			scale *= 5
		}
		for c in 0..<256 {
			x := fixed.Fixed(B, W){B(c)}

			want: [32]byte
			n := 0
			value := i32(x.i)
			if value < 0 {
				want[n] = '-'
				n += 1
				value = -value
			}
			n += len(strconv.write_int(want[n:], i64(value >> W), 10))
			if fraction := value & (1<<W - 1); fraction != 0 {
				want[n] = '.'
				n += 1
				digits := fraction * scale
				for k := int(W); k > 0; k -= 1 {
					want[n + k - 1] = byte('0' + digits % 10)
					digits /= 10
				}
				n += int(W)
				for want[n - 1] == '0' {
					n -= 1
				}
			}

			buf: [48]byte
			got := fixed.write(buf[:], x)
			testing.expectf(t, got == string(want[:n]), "Fixed(%v, %v)(%v): expected %q, got %q", typeid_of(B), W, x.i, string(want[:n]), got)
		}
	}
	check(t, i8, 0)
	check(t, i8, 1)
	check(t, i8, 2)
	check(t, i8, 3)
	check(t, i8, 4)
	check(t, i8, 5)
	check(t, i8, 6)
	check(t, i8, 7)
	check(t, u8, 0)
	check(t, u8, 1)
	check(t, u8, 2)
	check(t, u8, 3)
	check(t, u8, 4)
	check(t, u8, 5)
	check(t, u8, 6)
	check(t, u8, 7)
	check(t, u8, 8)
}

@test
test_write_wide :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $B: typeid, $W: uint, raw: B, want: string, loc := #caller_location) {
		buf: [48]byte
		got := fixed.write(buf[:], fixed.Fixed(B, W){raw})
		testing.expectf(t, got == want, "Fixed(%v, %v)(%v): expected %q, got %q", typeid_of(B), W, raw, want, got, loc = loc)
	}
	check(t, i16,  0,   min(i16),  "-32768")
	check(t, i16,  15,  min(i16),  "-1")
	check(t, i32,  16,  min(i32),  "-32768")
	check(t, i32,  16,  -1,        "-0.0000152587890625")
	check(t, i32,  31,  min(i32),  "-1")
	check(t, i64,  0,   min(i64),  "-9223372036854775808")
	check(t, i64,  32,  min(i64),  "-2147483648")
	check(t, i64,  32,  -1,        "-0.00000000023283064365386962890625")
	check(t, u64,  32,  max(u64),  "4294967295.99999999976716935634613037109375")
	check(t, i128, 0,   min(i128), "-170141183460469231731687303715884105728")
	check(t, i128, 64,  min(i128), "-9223372036854775808")
	check(t, i128, 127, min(i128), "-1")

	s := fixed.to_string(fixed.Fixed16_16{0x1_8000})
	testing.expect_value(t, s, "1.5")
	delete(s)
}

@test
test_write_short_dst :: proc(t: ^testing.T) {
	short: [2]byte
	testing.expect_value(t, fixed.write(short[:], fixed.Fixed16_16{3 << 15}), "")
	testing.expect_value(t, short, [2]byte{})

	exact: [3]byte
	testing.expect_value(t, fixed.write(exact[:], fixed.Fixed16_16{3 << 15}), "1.5")

	testing.expect_value(t, fixed.write(nil, fixed.Fixed16_16{}), "")

	negative: [4]byte
	testing.expect_value(t, fixed.write(negative[:3], fixed.Fixed16_16{-3 << 15}), "")
	testing.expect_value(t, fixed.write(negative[:], fixed.Fixed16_16{-3 << 15}), "-1.5")
}
