package test_internal

import "core:testing"

// / operator (truncated division)

// this seems to prevent folding at least at -o:minimal
@(private="file")
no_fold :: #force_no_inline proc(v: $T) -> T { return v }

@(test)
div_exception :: proc(t: ^testing.T) {
	// min(T) / -1 wraps to min(T) like the other arithmetic operators and must not trap
	check :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
		x, y := no_fold(min(T)), no_fold(T(-1))
		testing.expectf(t, x / y == min(T),  "min(%v) / -1 (rt divisor) == %v, want %v", typeid_of(T), x / y, min(T), loc = loc)
		testing.expectf(t, x / -1 == min(T), "min(%v) / -1 (const divisor) == %v, want %v", typeid_of(T), x / -1, min(T), loc = loc)
	}
	check(t, i8)
	check(t, i16)
	check(t, i32)
	check(t, i64)
	check(t, i128)
	{
		// vector path
		x := no_fold([4]i32{min(i32), 0, -7, 5})
		y := no_fold([4]i32{-1, -1, -1, -1})
		testing.expect_value(t, x / y, [4]i32{min(i32), 0, 7, -5})
	}
}
