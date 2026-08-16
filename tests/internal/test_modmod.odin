package test_internal

import "core:math"
import "core:testing"

// %% operator (remainder/floored modulo)
// remainder = x - y * floor(x / y)

// reference floor_mod constructed from trunc division;
// y * q may wrap, but two's complement arithmetic is mod 2^n,
// so the wrapped x - y * q still gives the remainder
@(private="file")
floor_mod :: proc(x, y: $T) -> T {
	q := x / y
	if x % y != 0 && ((x < 0) != (y < 0)) {
		q -= 1
	}
	return x - y * q
}

@(test)
modmod_i8_exhaustive :: proc(t: ^testing.T) {
	for i in -128..=127 {
		for j in -128..=127 {
			if j == 0 { continue }
			// min(T) %% -1 == 0 is tested in modmod_exception,
			// floor_mod ref itself would result in exception here
			if i == -128 && j == -1 { continue }
			x, y := i8(i), i8(j)
			got := x %% y
			want := floor_mod(x, y)
			testing.expectf(t, got == want, "%v %%%% %v == %v, want %v", x, y, got, want)
		}
	}
}

// alternative reference floor mod using f64;
// exact for i32 x and y
@(private="file")
floor_mod_via_f64 :: proc(x, y: i32) -> i32 {
	return i32(f64(x) - f64(y)*math.floor(f64(x)/f64(y)))
}

@(test)
modmod_i32 :: proc(t: ^testing.T) {
	vals: [dynamic]i32
	defer delete(vals)
	append(&vals, 0, 1, -1, 2, -2, 3, -3, max(i32), max(i32)-1, min(i32), min(i32)+1)
	for shift in u32(3)..=30 {
		p := i32(1) << shift
		append(&vals, p-1, p, p+1, -p+1, -p, -p-1)
	}
	for x in vals {
		for y in vals {
			if y == 0 { continue }
			if x == min(i32) && y == -1 { continue } // covered in modmod_exception
			got := x %% y
			testing.expectf(t, got == floor_mod(x, y),
				"%v %%%% %v == %v, want %v", x, y, got, floor_mod(x, y))
			testing.expectf(t, got == floor_mod_via_f64(x, y),
				"%v %%%% %v == %v, f64 ref %v", x, y, got, floor_mod_via_f64(x, y))
		}
	}
}

@(test)
modmod_const_divisors :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, x, got, want: $T, loc := #caller_location) {
		testing.expectf(t, got == want, "x=%v: got %v, want %v", x, got, want, loc = loc)
	}
	for i in -3000..=3000 {
		x := i32(i)
		check(t, x, x %% 7, floor_mod(x, i32(7)))
		check(t, x, x %% 1000, floor_mod(x, i32(1000)))
		check(t, x, x %% -42, floor_mod(x, i32(-42)))
		check(t, x, x %% -1, 0)
		check(t, x, x %% max(i32), floor_mod(x, max(i32)))
		check(t, x, x %% min(i32), floor_mod(x, min(i32)))
	}
	for i in -200..=200 {
		x := i64(i) * 1_000_000_007
		check(t, x, x %% 97,  floor_mod(x, i64(97)))
		check(t, x, x %% -97, floor_mod(x, i64(-97)))
	}
}

@(test)
modmod_const_fold :: proc(t: ^testing.T) {
	// must match the folded constants (arbitrary precision)
	{
		x, y: i8 = 126, 127
		testing.expect_value(t, x %% y, 126 %% 127)
		testing.expect_value(t, x %% y, i8(126))
	}
	{
		x, y := max(i32) - 1, max(i32)
		testing.expect_value(t, x %% y, (max(i32) - 1) %% max(i32))
		testing.expect_value(t, x %% y, max(i32) - 1)
	}
	{
		x, y := max(i64) - 1, max(i64)
		testing.expect_value(t, x %% y, (max(i64) - 1) %% max(i64))
		testing.expect_value(t, x %% y, max(i64) - 1)
	}
	{
		x, y := min(i32) + 1, min(i32)
		testing.expect_value(t, x %% y, (min(i32) + 1) %% min(i32))
		testing.expect_value(t, x %% y, min(i32) + 1)
	}
	// sign of remainder must match sign of divisor
	{
		x, y := -7, 3
		testing.expect_value(t, x %% y, -7 %% 3)
		testing.expect_value(t, x %% y, 2)
	}
	{
		x, y := 7, -3
		testing.expect_value(t, x %% y, 7 %% -3)
		testing.expect_value(t, x %% y, -2)
	}
	{
		x, y := -7, -3
		testing.expect_value(t, x %% y, -7 %% -3)
		testing.expect_value(t, x %% y, -1)
	}
}

@(test)
modmod_128 :: proc(t: ^testing.T) {
	BIG :: i128(1) << 100
	{
		x, y: i128 = 5, -7
		testing.expect_value(t, x %% y, -2)
		testing.expect_value(t, x %% y, floor_mod(x, y))

		x = 3
		testing.expect_value(t, x %% -BIG, 3 - BIG)
		testing.expect_value(t, x %% -BIG, floor_mod(x, -BIG))
	
		y = -BIG
		testing.expect_value(t, x %% y, 3 - BIG)

		x = BIG + 3
		testing.expect_value(t, x %% BIG, 3)
	
		x, y = max(i128) - 1, max(i128)
		testing.expect_value(t, x %% y, max(i128) - 1)
	}
	{
		x := max(u128) - 1
		testing.expect_value(t, x %% max(u128), max(u128) - 1)
	}
}

@(test)
modmod_vec :: proc(t: ^testing.T) {
	// these should vectorize
	x := [4]i32{max(i32) - 1, -7, 7, 126}
	y := [4]i32{max(i32), 3, -3, 127}
	r := x %% y
	for i in 0..<4 {
		testing.expectf(t, r[i] == floor_mod(x[i], y[i]),
			"[4]i32 idx %v: %v %%%% %v == %v, want %v", i, x[i], y[i], r[i], floor_mod(x[i], y[i]))
	}
}

// this seems to prevent folding at least at -o:minimal
@(private="file")
not_const :: #force_no_inline proc(v: $T) -> T { return v }

@(test)
modmod_exception :: proc(t: ^testing.T) {
	// spec requires this explicitly
	// min(T) %% -1 == 0
	check :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
		x, y := not_const(min(T)), not_const(T(-1))
		testing.expectf(t, x %% y == 0,  "min(%v) %%%% -1 (rt divisor) == %v, want 0", typeid_of(T), x %% y,  loc = loc)
		testing.expectf(t, x %% -1 == 0, "min(%v) %%%% -1 (const divisor) == %v, want 0", typeid_of(T), x %% -1, loc = loc)
	}
	check(t, i8)
	check(t, i16)
	check(t, i32)
	check(t, i64)
	check(t, i128)
	{
		// vector path
		x := not_const([4]i32{min(i32), 0, -7, 5})
		y := not_const([4]i32{-1, -1, -1, -1})
		testing.expect_value(t, x %% y, [4]i32{0, 0, 0, 0})
	}
}

@(test)
modmod_unsigned :: proc(t: ^testing.T) {
	// for unsigned types %% must match %
	{
		x, y: u32 = max(u32) - 1, max(u32)
		testing.expect_value(t, x %% y, max(u32) - 1)
		testing.expect_value(t, x %% y, x % y)
	}
	{
		x, y: u8 = 5, 3
		testing.expect_value(t, x %% y, 2)
		testing.expect_value(t, x %% y, x % y)
	}
}
