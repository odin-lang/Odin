// Clang passes a vector argument as itself on wasm: its lanes as separate arguments without `simd128`, and `v128` with it.
// Odin passed one wider than 8 bytes by pointer, and C read the pointer as the first lane.
//
// Being an ABI guarantee, must be cross-checked against a c compiler.
// Both sides are built without `simd128` and with it, see run.sh.
package test_issue_wasm_c_vectors

import "core:fmt"
import "core:os"

V2f :: #simd[2]f32
V4f :: #simd[4]f32
V8f :: #simd[8]f32

foreign import lib "../build/test_issue_wasm_c_vectors_c.o"

@(default_calling_convention="c")
foreign lib {
	c_take_v2f   :: proc(a: V2f, d: f64) -> i32 ---
	c_take_v4f   :: proc(a: V4f, d: f64, b: V4f) -> i32 ---
	c_take_v8f   :: proc(a: V8f, k: i32) -> i32 ---
	c_ret_v4f    :: proc(base: f32) -> V4f ---
	c_ret_v8f    :: proc(base: f32) -> V8f ---
	c_calls_odin :: proc() -> i32 ---
}

lanes :: proc "contextless" (v: $V, base: f32) -> bool {
	for x, i in transmute([size_of(V)/4]f32)v {
		if x != base + f32(i) {
			return false
		}
	}
	return true
}

make_vec :: proc "contextless" ($V: typeid, base: f32) -> V {
	a: [size_of(V)/4]f32
	for &x, i in a {
		x = base + f32(i)
	}
	return transmute(V)a
}

@(export)
odin_take_v4f :: proc "c" (a: V4f, d: f64, b: V4f) -> i32 {
	return i32(lanes(a, 1) && lanes(b, 11) && d == 2.5)
}

@(export)
odin_ret_v4f :: proc "c" (base: f32) -> V4f {
	return make_vec(V4f, base)
}

failures := 0

expect :: proc(ok: bool, what: string) {
	if !ok {
		fmt.eprintln("failed:", what)
		failures += 1
	}
}

main :: proc() {
	expect(c_take_v2f(make_vec(V2f, 1), 1.5) == 1, "c_take_v2f")
	expect(c_take_v4f(make_vec(V4f, 1), 2.5, make_vec(V4f, 11)) == 1, "c_take_v4f")
	expect(c_take_v8f(make_vec(V8f, 21), 7) == 1, "c_take_v8f")
	expect(lanes(c_ret_v4f(41), 41), "c_ret_v4f")
	expect(lanes(c_ret_v8f(51), 51), "c_ret_v8f")
	expect(c_calls_odin() == 1, "c_calls_odin")
	os.exit(failures)
}
