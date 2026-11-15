package test_internal

import "core:testing"

// % operator (truncated remainder)
// remainder = x - y * trunc(x / y)

@(private="file")
trunc_mod :: proc(x, y: $T) -> T {
	return x - y*(x/y)
}

// this seems to prevent folding at least at -o:minimal
@(private="file")
not_const :: #force_no_inline proc(v: $T) -> T { return v }

@(test)
mod_i8_exhaustive :: proc(t: ^testing.T) {
	for i in -128..=127 {
		for j in -128..=127 {
			if j == 0 { continue }
			// min(T) % -1 == 0 is tested in mod_exception,
			// the trunc_mod reference itself would trap here
			if i == -128 && j == -1 { continue }
			x, y := i8(i), i8(j)
			got := x % y
			want := trunc_mod(x, y)
			testing.expectf(t, got == want, "%v %% %v == %v, want %v", x, y, got, want)
		}
	}
}

@(test)
mod_exception :: proc(t: ^testing.T) {
	// min(T) % -1 is 0, which is what the constant folder answers
	#assert(min(i8)   % i8(-1)   == 0)
	#assert(min(i16)  % i16(-1)  == 0)
	#assert(min(i32)  % i32(-1)  == 0)
	#assert(min(i64)  % i64(-1)  == 0)
	#assert(min(i128) % i128(-1) == 0)

	check :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
		x, y := not_const(min(T)), not_const(T(-1))
		testing.expectf(t, x % y == 0,  "min(%v) %% -1 (rt divisor) == %v, want 0", typeid_of(T), x % y, loc = loc)
		testing.expectf(t, x % -1 == 0, "min(%v) %% -1 (const divisor) == %v, want 0", typeid_of(T), x % -1, loc = loc)
	}
	check(t, i8)
	check(t, i16)
	check(t, i32)
	check(t, i64)
	check(t, i128)
}

@(test)
mod_exception_vec :: proc(t: ^testing.T) {
	{
		// [4]i32 emits `srem <4 x i32>`
		x := not_const([4]i32{min(i32), 0, -7, 5})
		y := not_const([4]i32{-1, -1, -1, -1})
		testing.expect_value(t, x % y, [4]i32{0, 0, 0, 0})
	}
	{
		// [16]i32 emits scalar `srem i32`, which is the other call site
		x, y: [16]i32
		for i in 0..<16 {
			x[i] = i == 0 ? min(i32) : i32(i) - 8
			y[i] = -1
		}
		testing.expect_value(t, not_const(x) % not_const(y), [16]i32{})
	}
}

@(test)
mod_assign :: proc(t: ^testing.T) {
	// %= must agree with %
	{
		x := not_const(min(i32))
		y := not_const(i32(-1))
		x %= y
		testing.expect_value(t, x, 0)
	}
	{
		x := not_const(i64(-17))
		y := not_const(i64(5))
		x %= y
		testing.expect_value(t, x, -17 % 5)
	}
}

@(test)
mod_unsigned_unchanged :: proc(t: ^testing.T) {
	// the guard is signed-only; unsigned max is all-ones and must stay a real divisor
	{
		x, y := not_const(max(u32)), not_const(max(u32))
		testing.expect_value(t, x % y, 0)
	}
	{
		x, y := not_const(u32(7)), not_const(max(u32))
		testing.expect_value(t, x % y, 7)
	}
	{
		x, y := not_const(u8(200)), not_const(u8(255))
		testing.expect_value(t, x % y, 200)
	}
}
