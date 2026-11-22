// With AVX, x86-64 SysV passes a 32-byte vector in a YMM register, bare or as the only member of a struct.
// A wider one goes to memory and takes no register, and is returned in YMM0 and YMM1.
// Odin passed every vector wider than 16 bytes in memory whatever the target features.
//
// Being an ABI guarantee, must be cross-checked against a c compiler.
// Both sides are built with AVX2, see run.sh.
package test_issues

import "core:testing"

V8f  :: #simd[8]f32
V16f :: #simd[16]f32
W8f  :: struct { v: V8f }
D2   :: struct { x, y: f64 }

foreign import lib "../build/test_issue_sysv_wide_vectors_c.o"

@(default_calling_convention="c")
foreign lib {
	c_take_ymm     :: proc(a, b, c, d: V8f, s: D2, e: f64) -> i32 ---
	c_take_nine    :: proc(a, b, c, d, e, f, g, h, i: V8f) -> i32 ---
	c_take_wrapped :: proc(a: W8f, d: f64) -> i32 ---
	c_take_v16     :: proc(a: V16f, d: f64) -> i32 ---
	c_ret_v8f      :: proc(base: f32) -> V8f ---
	c_ret_w8f      :: proc(base: f32) -> W8f ---
	c_ret_v16f     :: proc(base: f32) -> V16f ---
	c_calls_odin   :: proc() -> i32 ---
}

@(private="file")
lanes :: proc "contextless" (v: $V, base: f32) -> bool {
	for x, i in transmute([size_of(V)/4]f32)v {
		if x != base + f32(i) {
			return false
		}
	}
	return true
}

@(private="file")
make_vec :: proc "contextless" ($V: typeid, base: f32) -> V {
	a: [size_of(V)/4]f32
	for &x, i in a {
		x = base + f32(i)
	}
	return transmute(V)a
}

@(export)
odin_take_ymm :: proc "c" (a, b, c, d: V8f, s: D2, e: f64) -> i32 {
	return i32(lanes(a, 1) && lanes(b, 11) && lanes(c, 21) && lanes(d, 31) && s == {1.5, 2.5} && e == 3.5)
}

@(export)
odin_take_wrapped :: proc "c" (a: W8f, d: f64) -> i32 {
	return i32(lanes(a.v, 1) && d == 4.5)
}

@(export) odin_ret_v8f  :: proc "c" (base: f32) -> V8f  { return make_vec(V8f, base) }
@(export) odin_ret_w8f  :: proc "c" (base: f32) -> W8f  { return {make_vec(V8f, base)} }
@(export) odin_ret_v16f :: proc "c" (base: f32) -> V16f { return make_vec(V16f, base) }

@(test)
test_sysv_wide_vectors :: proc(t: ^testing.T) {
	v :: proc "contextless" (base: f32) -> V8f { return make_vec(V8f, base) }
	z := v(0)

	testing.expect_value(t, c_take_ymm(v(1), v(11), v(21), v(31), {1.5, 2.5}, 3.5), 1)
	testing.expect_value(t, c_take_nine(z, z, z, z, z, z, z, v(71), v(81)), 1)
	testing.expect_value(t, c_take_wrapped({v(1)}, 4.5), 1)
	testing.expect_value(t, c_take_v16(make_vec(V16f, 1), 5.5), 1)
	testing.expect(t, lanes(c_ret_v8f(21), 21))
	testing.expect(t, lanes(c_ret_w8f(31).v, 31))
	testing.expect(t, lanes(c_ret_v16f(41), 41))
	testing.expect_value(t, c_calls_odin(), 0)
}
