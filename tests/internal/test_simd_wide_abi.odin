package test_internal

import "core:simd"
import "core:testing"

// Vectors wider than 16 bytes are returned split across xmm0-xmm3 (ymm with AVX), or through a hidden
// pointer when even that is not enough, and passed in memory.

@(private="file")
wide_two :: proc "contextless" (a, b: simd.u32x8) -> (simd.u32x8, simd.u32x8) {
	return a + b, a - b
}

@(private="file")
wide_one :: proc "contextless" (a: simd.u32x8) -> simd.u32x8 {
	return a * 3
}

@(private="file")
wide_f32x16 :: proc "contextless" (a: #simd[16]f32, x: f32, b: #simd[16]f32) -> #simd[16]f32 {
	return a * b + x
}

@(private="file")
wide_u32x32 :: proc "contextless" (a: #simd[32]u32, n: u32) -> #simd[32]u32 {
	return a * n
}

@(private="file")
Wide_Struct :: struct {
	v: #simd[4]f64,
}

@(private="file")
wide_struct :: proc "contextless" (s: Wide_Struct) -> Wide_Struct {
	return {s.v * 2}
}

@(test)
simd_wide_returns :: proc(t: ^testing.T) {
	a := simd.u32x8{1, 2, 3, 4, 5, 6, 7, 8}
	x, y := wide_two(a, a*2)
	testing.expect(t, simd.reduce_and(simd.lanes_eq(x, a*3)) != 0)
	testing.expect(t, simd.reduce_and(simd.lanes_eq(y, simd.u32x8(0) - a)) != 0)
	testing.expect_value(t, simd.extract(wide_one(a), 7), 24)

	f: #simd[16]f32
	for i in 0..<16 {
		f = simd.replace(f, i, f32(i))
	}
	r := wide_f32x16(f, 0.5, f)
	testing.expect_value(t, simd.extract(r, 0), 0.5)
	testing.expect_value(t, simd.extract(r, 15), 225.5)

	w: #simd[32]u32
	for i in 0..<32 {
		w = simd.replace(w, i, u32(i))
	}
	wr := wide_u32x32(w, 3)
	testing.expect_value(t, simd.extract(wr, 1), 3)
	testing.expect_value(t, simd.extract(wr, 31), 93)

	s := wide_struct({{1, 2, 3, 4}})
	testing.expect_value(t, simd.extract(s.v, 3), 8)
}
