package test_internal

import "base:intrinsics"
import "core:testing"

@(private="file")
runtime_value :: #force_no_inline proc(v: $T) -> T { return v }

@(private="file")
floor_div_ref :: proc(x, y: $T) -> T {
	q := x / y
	if x % y != 0 && ((x < 0) != (y < 0)) {
		q -= 1
	}
	return q
}

@(test)
floor_div_i8_exhaustive :: proc(t: ^testing.T) {
	for i in -128..=127 {
		for j in -128..=127 {
			if j == 0 { continue }
			x, y := runtime_value(i8(i)), runtime_value(i8(j))
			got  := intrinsics.floor_div(x, y)
			want := i8(floor_div_ref(i32(i), i32(j))) // min(i8)/-1 wraps like `/`
			if got != want {
				testing.expectf(t, false, "floor_div(%v, %v) == %v, want %v", x, y, got, want)
				return
			}
		}
	}
}

@(test)
floor_div_const_divisors :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $T: typeid, $D: T, loc := #caller_location) {
		y := runtime_value(D)
		d := abs(i128(D))
		lo, hi := i128(min(T)), i128(max(T))

		vals: [dynamic]i128
		defer delete(vals)
		for base in ([3]i128{lo, 0, hi}) {
			for k in i128(-2048)..=2048 {
				append(&vals, base + k)
			}
		}
		for j in ([3]i128{0, 1, d - 1}) {
			n := hi - (hi - j) %% d
			append(&vals, n, n - d, -n, -n - 1, -n + d)
		}
		s := u64(0x9e37_79b9_7f4a_7c15)
		for _ in 0..<2048 {
			s = s*6364136223846793005 + 1442695040888963407
			append(&vals, i128(T(s)))
		}

		for v in vals {
			if v < lo || v > hi { continue }
			x := T(v)
			got, want := intrinsics.floor_div(x, D), floor_div_ref(x, y)
			if got != want {
				testing.expectf(t, false, "%v: floor_div(%v, %v) == %v, want %v", typeid_of(T), x, D, got, want, loc = loc)
				return
			}
		}
	}

	// round-up, round-down, register sized shifts, powers of two, and the divisors of 2^(n-1)+-1
	check(t, i8, 1)
	check(t, i8, 3)
	check(t, i8, 7)
	check(t, i8, 16)
	check(t, i8, 100)
	check(t, i8, 127)
	check(t, i8, -3)
	check(t, i8, -16)
	check(t, i8, -127)

	check(t, i16, 3)
	check(t, i16, 10)
	check(t, i16, 1024)
	check(t, i16, max(i16))
	check(t, i16, -10)
	check(t, i16, min(i16))

	check(t, i32, 3)
	check(t, i32, 7)
	check(t, i32, 100)
	check(t, i32, 86400)
	check(t, i32, 1 << 20)
	check(t, i32, max(i32))
	check(t, i32, -5)
	check(t, i32, -(1 << 20))
	check(t, i32, min(i32))

	check(t, i64, 3)
	check(t, i64, 5)
	check(t, i64, 6)
	check(t, i64, 7)
	check(t, i64, 100)
	check(t, i64, 86400)
	check(t, i64, 1 << 40)
	check(t, i64, max(i64) - 1)
	check(t, i64, max(i64))
	check(t, i64, -3)
	check(t, i64, -7)
	check(t, i64, -86400)
	check(t, i64, -(1 << 40))
	check(t, i64, -max(i64))
	check(t, i64, min(i64))
}

@(test)
floor_div_min_by_minus_one :: proc(t: ^testing.T) {
	// wraps like `/`
	testing.expect_value(t, intrinsics.floor_div(runtime_value(min(i8)),  runtime_value(i8(-1))),  min(i8))
	testing.expect_value(t, intrinsics.floor_div(runtime_value(min(i32)), runtime_value(i32(-1))), min(i32))
	testing.expect_value(t, intrinsics.floor_div(runtime_value(min(i64)), runtime_value(i64(-1))), min(i64))
	testing.expect_value(t, intrinsics.floor_div(runtime_value(min(i64)), -1), min(i64))
}

@(test)
floor_div_wide_and_unsigned :: proc(t: ^testing.T) {
	BIG :: i128(1) << 100
	testing.expect_value(t, intrinsics.floor_div(runtime_value(-BIG - 1), runtime_value(BIG)), -2)
	testing.expect_value(t, intrinsics.floor_div(runtime_value(BIG + 3), runtime_value(i128(-7))), floor_div_ref(BIG + 3, -7))
	testing.expect_value(t, intrinsics.floor_div(runtime_value(i128(-7)), 2), -4)

	// unsigned is plain `/`
	testing.expect_value(t, intrinsics.floor_div(runtime_value(max(u64)), runtime_value(u64(7))), max(u64) / 7)
	testing.expect_value(t, intrinsics.floor_div(runtime_value(u8(200)), 3), 66)
}

@(test)
floor_div_const_fold :: proc(t: ^testing.T) {
	#assert(intrinsics.floor_div(-7, 2) == -4)
	#assert(intrinsics.floor_div(7, -2) == -4)
	#assert(intrinsics.floor_div(-7, -2) == 3)
	#assert(intrinsics.floor_div(-6, 3) == -2)
	#assert(intrinsics.floor_div(i8(-128), i8(3)) == -43)
	#assert(intrinsics.floor_div(u8(255), u8(16)) == 15)
	#assert(intrinsics.floor_div(min(i64), 86400) == -106751991167301)

	// folding agrees with the runtime lowering
	X :: i64(-1234567890123)
	testing.expect_value(t, intrinsics.floor_div(X, 86400), intrinsics.floor_div(runtime_value(X), runtime_value(i64(86400))))
	testing.expect_value(t, intrinsics.floor_div(X, -7),    intrinsics.floor_div(runtime_value(X), runtime_value(i64(-7))))
}
