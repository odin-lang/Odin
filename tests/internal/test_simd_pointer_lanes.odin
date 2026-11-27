package test_internal

import "core:simd"
import "core:testing"

@(test)
simd_pointer_lanes_pass_and_return :: proc(t: ^testing.T) {
	ret1 :: #force_no_inline proc(v: #simd[1]rawptr) -> #simd[1]rawptr { return v }
	ret2 :: #force_no_inline proc(v: #simd[2]rawptr) -> #simd[2]rawptr { return v }
	ret4 :: #force_no_inline proc(v: #simd[4]rawptr) -> #simd[4]rawptr { return v }
	ret8 :: #force_no_inline proc(v: #simd[8]rawptr) -> #simd[8]rawptr { return v }
	ret2_contextless :: #force_no_inline proc "contextless" (v: #simd[2]rawptr) -> #simd[2]rawptr { return v }
	ret2_c :: #force_no_inline proc "c" (v: #simd[2]rawptr) -> #simd[2]rawptr { return v }
	ret4_c :: #force_no_inline proc "c" (v: #simd[4]rawptr) -> #simd[4]rawptr { return v }
	pair4 :: #force_no_inline proc(n: int, v: #simd[4]rawptr) -> (int, #simd[4]rawptr) { return n + 1, v }

	cells: [8]i32
	p: [8]rawptr
	for i in 0..<8 {
		cells[i] = i32(i*7 + 1)
		p[i] = &cells[7 - i]
	}

	p1 := [1]rawptr{p[3]}
	p2 := [2]rawptr{p[0], p[1]}
	p4 := [4]rawptr{p[2], p[3], p[4], p[5]}

	testing.expect(t, simd.to_array(ret1(simd.from_array(p1))) == p1)
	testing.expect(t, simd.to_array(ret2(simd.from_array(p2))) == p2)
	testing.expect(t, simd.to_array(ret4(simd.from_array(p4))) == p4)
	testing.expect(t, simd.to_array(ret8(simd.from_array(p))) == p)
	testing.expect(t, simd.to_array(ret2_contextless(simd.from_array(p2))) == p2)
	testing.expect(t, simd.to_array(ret2_c(simd.from_array(p2))) == p2)
	testing.expect(t, simd.to_array(ret4_c(simd.from_array(p4))) == p4)

	n, v := pair4(41, simd.from_array(p4))
	testing.expect_value(t, n, 42)
	got := simd.to_array(v)
	testing.expect(t, got == p4)
	for q, i in got {
		testing.expect_value(t, (^i32)(q)^, cells[5 - i])
	}
}
