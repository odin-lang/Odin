package test_core_simd

import "core:simd"
import "core:testing"

@(test)
test_lanes_shift :: proc(t: ^testing.T) {
	check_lanes_shift(t, #simd[2]u8)
	check_lanes_shift(t, #simd[4]i16)
	check_lanes_shift(t, #simd[8]u32)
	check_lanes_shift(t, #simd[16]i8)
	check_lanes_shift(t, #simd[32]u16)
	check_lanes_shift(t, #simd[64]u8)
	check_lanes_shift(t, #simd[2]i64)
	check_lanes_shift(t, #simd[4]f32)
	check_lanes_shift(t, #simd[8]f32)
	check_lanes_shift(t, #simd[16]f32)
	check_lanes_shift(t, #simd[64]f32)
	check_lanes_shift(t, #simd[2]f64)
	check_lanes_shift(t, #simd[8]f64)
}

@(test)
test_lanes_shift_bool_and_pointer :: proc(t: ^testing.T) {
	b := #simd[4]bool{true, true, true, true}
	testing.expect_value(t, simd.to_array(simd.lanes_shift_left(b, 1)),  [4]bool{true, true, true, false})
	testing.expect_value(t, simd.to_array(simd.lanes_shift_right(b, 3)), [4]bool{false, false, false, true})

	x: int
	p := #simd[2]rawptr{&x, &x}
	testing.expect_value(t, simd.to_array(simd.lanes_shift_left(p, 1)),  [2]rawptr{&x, nil})
	testing.expect_value(t, simd.to_array(simd.lanes_shift_right(p, 1)), [2]rawptr{nil, &x})
}

@(test)
test_scan_add_exact :: proc(t: ^testing.T) {
	check_scan_add_exact(t, #simd[2]i32)
	check_scan_add_exact(t, #simd[4]i32)
	check_scan_add_exact(t, #simd[8]i32)
	check_scan_add_exact(t, #simd[16]i32)
	check_scan_add_exact(t, #simd[32]i32)
	check_scan_add_exact(t, #simd[64]i32)
	check_scan_add_exact(t, #simd[16]u8)
	check_scan_add_exact(t, #simd[64]u8)
	check_scan_add_exact(t, #simd[8]i16)
	check_scan_add_exact(t, #simd[32]u16)
	check_scan_add_exact(t, #simd[4]u64)
	check_scan_add_exact(t, #simd[8]i64)
	check_scan_add_exact(t, #simd[2]f32)
	check_scan_add_exact(t, #simd[8]f32)
	check_scan_add_exact(t, #simd[64]f32)
	check_scan_add_exact(t, #simd[4]f64)
	check_scan_add_exact(t, #simd[32]f64)
}

@(test)
test_scan_add_float_order :: proc(t: ^testing.T) {
	check_scan_add_order(t, #simd[2]f32)
	check_scan_add_order(t, #simd[4]f32)
	check_scan_add_order(t, #simd[8]f32)
	check_scan_add_order(t, #simd[16]f32)
	check_scan_add_order(t, #simd[32]f32)
	check_scan_add_order(t, #simd[64]f32)
	check_scan_add_order(t, #simd[2]f64)
	check_scan_add_order(t, #simd[8]f64)
	check_scan_add_order(t, #simd[64]f64)

	// A running total gives 1 in lane 3.
	v := #simd[4]f32{1e8, 1, -1e8, 1}
	testing.expect_value(t, simd.to_array(simd.scan_add(v)), [4]f32{1e8, 1e8, 0, 0})
}

check_lanes_shift :: proc(t: ^testing.T, $V: typeid/#simd[$N]$E, loc := #caller_location) {
	a: [N]E
	for i in 0..<N {
		a[i] = E(i+1)
	}
	v := simd.from_array(a)

	check_offset(t, v, 0,    loc)
	check_offset(t, v, 1,    loc)
	check_offset(t, v, N/2,  loc)
	check_offset(t, v, N-1,  loc)
	check_offset(t, v, N,    loc)
	check_offset(t, v, N+3,  loc)
	check_offset(t, v, 1000, loc)
}

check_offset :: proc(t: ^testing.T, v: $V/#simd[$N]$E, $OFFSET: int, loc := #caller_location) {
	a := simd.to_array(v)

	want_left:  [N]E
	want_right: [N]E
	for i in 0..<N {
		if i+OFFSET < N {
			want_left[i] = a[i+OFFSET]
		}
		if i >= OFFSET {
			want_right[i] = a[i-OFFSET]
		}
	}

	left  := simd.to_array(simd.lanes_shift_left(v, OFFSET))
	right := simd.to_array(simd.lanes_shift_right(v, OFFSET))
	testing.expectf(t, left  == want_left,  "lanes_shift_left(%v, %d) = %v, want %v",  a, OFFSET, left,  want_left,  loc=loc)
	testing.expectf(t, right == want_right, "lanes_shift_right(%v, %d) = %v, want %v", a, OFFSET, right, want_right, loc=loc)
}

// Whole numbers: exact in any order. The integer sums wrap.
check_scan_add_exact :: proc(t: ^testing.T, $V: typeid/#simd[$N]$E, loc := #caller_location) {
	a: [N]E
	for i in 0..<N {
		a[i] = E((i*37 + 11) % 101) - 50
	}

	inclusive: [N]E
	exclusive: [N]E
	sum: E
	for i in 0..<N {
		exclusive[i] = sum
		sum += a[i]
		inclusive[i] = sum
	}

	v := simd.from_array(a)
	got_inclusive := simd.to_array(simd.scan_add(v))
	got_exclusive := simd.to_array(simd.scan_add(simd.lanes_shift_right(v, 1)))
	testing.expectf(t, got_inclusive == inclusive, "scan_add(%v) = %v, want %v", a, got_inclusive, inclusive, loc=loc)
	testing.expectf(t, got_exclusive == exclusive, "exclusive scan_add(%v) = %v, want %v", a, got_exclusive, exclusive, loc=loc)
}

// Fractions that round: the result must follow the documented order.
check_scan_add_order :: proc(t: ^testing.T, $V: typeid/#simd[$N]$E, loc := #caller_location) {
	a: [N]E
	for i in 0..<N {
		a[i] = E((i*7919) % 1000) / 7 - 70
	}

	want := a
	for shift := 1; shift < N; shift *= 2 {
		prev := want
		for i in shift..<N {
			want[i] = prev[i] + prev[i-shift]
		}
	}

	got := simd.to_array(simd.scan_add(simd.from_array(a)))
	testing.expectf(t, got == want, "scan_add(%v) = %v, want %v", a, got, want, loc=loc)
}
