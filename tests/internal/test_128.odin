package test_internal

import "base:intrinsics"
import "base:runtime"
import "core:testing"

@test
test_128_runtime_division :: proc(t: ^testing.T) {
	Case :: struct {
		a, b, q, r: u128,
	}
	@static known := []Case{
		{max(u128),                          3,                                  0x55555555555555555555555555555555, 0},
		{max(u128),                          7,                                  0x24924924924924924924924924924924, 3},
		{max(u128),                          86400,                              0xc22e450672894ab6cd8efb11d33f,     0x717f},
		{max(u128),                          0xffffffffffffffff,                 0x10000000000000001,                0},
		{max(u128),                          0x10000000000000001,                0xffffffffffffffff,                 0},
		{0x80000000000000000000000000000001, 0x10000000000000001,                0x7fffffffffffffff,                 0x8000000000000002},
		{max(u128),                          0x80000000000000000000000000000003, 1,                                  0x7ffffffffffffffffffffffffffffffc},
		{0xffffffffffffffff0000000000000000, 0xffffffffffffffff,                 0x10000000000000000,                0},
		{0x80000000000000000000000000000000, 0x8000000000000001,                 0xfffffffffffffffe,                 2},
	}
	for c in known {
		r: u128
		q := runtime.udivmod128(c.a, c.b, &r)
		testing.expectf(t, q == c.q && r == c.r, "%x / %x = (%x, %x), want (%x, %x)", c.a, c.b, q, r, c.q, c.r)
	}

	vals: [dynamic]u128
	defer delete(vals)
	for k in 0..<128 {
		p := u128(1) << uint(k)
		append(&vals, p, p - 1, p + 1, ~p)
	}
	s := u64(0x9e37_79b9_7f4a_7c15)
	for _ in 0..<64 {
		s = s*6364136223846793005 + 1442695040888963407
		hi := s
		s = s*6364136223846793005 + 1442695040888963407
		append(&vals, u128(hi) << 64 | u128(s), u128(s))
	}

	// q*b + r == a with no overflow, and r < b, define the quotient and remainder
	for a in vals {
		for b in vals {
			if b == 0 { continue }
			q, r := a / b, a % b
			p, mul_over := intrinsics.overflow_mul(q, b)
			sum, add_over := intrinsics.overflow_add(p, r)
			if mul_over || add_over || sum != a || r >= b {
				testing.expectf(t, false, "%x / %x = (%x, %x)", a, b, q, r)
				return
			}

			// truncated signed division by the same bit patterns
			x, y := i128(a), i128(b)
			sq, sr := x / y, x % y
			if sq*y + sr != x                    ||
			   (sr != 0 && (sr < 0) != (x < 0)) ||
			   (y != min(i128) && abs(sr) >= abs(y)) {
				testing.expectf(t, false, "%v / %v = (%v, %v)", x, y, sq, sr)
				return
			}
		}
	}

	testing.expect_value(t, runtime_min_i128() / -1, min(i128))
	testing.expect_value(t, runtime_min_i128() % -1, 0)
}

@(private="file")
runtime_min_i128 :: #force_no_inline proc() -> i128 { return min(i128) }

@test
test_128_align :: proc(t: ^testing.T) {
	Danger_Struct :: struct {
		x: u128,
		y: u64,
	}

	list := [?]Danger_Struct{{0, 0}, {1, 0}, {2, 0}, {3, 0}}

	testing.expectf(t, list[0].x == 0, "[0].x (%v) != 0", list[0].x)
	testing.expectf(t, list[0].y == 0, "[0].y (%v) != 0", list[0].y)

	testing.expectf(t, list[1].x == 1, "[1].x (%v) != 1", list[1].x)
	testing.expectf(t, list[1].y == 0, "[1].y (%v) != 0", list[1].y)

	testing.expectf(t, list[2].x == 2, "[2].x (%v) != 2", list[2].x)
	testing.expectf(t, list[2].y == 0, "[2].y (%v) != 0", list[2].y)

	testing.expectf(t, list[3].x == 3, "[3].x (%v) != 3", list[3].x)
	testing.expectf(t, list[3].y == 0, "[3].y (%v) != 0", list[3].y)
}
