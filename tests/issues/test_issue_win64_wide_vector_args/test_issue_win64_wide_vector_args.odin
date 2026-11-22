// Win64 passes a vector wider than 16 bytes by reference, one pointer per vector, whatever the target features.
// Without AVX, LLVM split `#simd[8]f32` into halves and passed each by reference, and C read the wrong memory.
//
// Being an ABI guarantee, must be cross-checked against a c compiler.
// The C side is built with AVX2 (clang without AVX splits the vector too, MSVC never does).
// The Odin side is built without it, see run.bat.
package test_issues

import "core:sys/info"
import "core:testing"

V8f :: #simd[8]f32

foreign import lib "../build/test_issue_win64_wide_vector_args_c.o"

@(default_calling_convention="c")
foreign lib {
	c_take_m256  :: proc(a: V8f, d: f64, b: V8f, k: i64) -> i32 ---
	c_take_five  :: proc(a, b, c, d, e: V8f) -> i32 ---
	c_calls_odin :: proc() -> i32 ---
}

@(private="file")
lanes :: proc "contextless" (v: V8f, base: f32) -> bool {
	for x, i in transmute([8]f32)v {
		if x != base + f32(i) {
			return false
		}
	}
	return true
}

@(private="file")
make_v8f :: proc "contextless" (base: f32) -> (v: V8f) {
	a: [8]f32
	for &x, i in a {
		x = base + f32(i)
	}
	return transmute(V8f)a
}

@(export)
odin_take_m256 :: proc "c" (a: V8f, d: f64, b: V8f, k: i64) -> i32 {
	return i32(lanes(a, 1) && lanes(b, 11) && d == 5.5 && k == 77)
}

@(test)
test_win64_wide_vector_args :: proc(t: ^testing.T) {
	if .avx2 not_in info.cpu_features() {
		return // the C side runs AVX2 instructions
	}
	zero := make_v8f(0)
	testing.expect_value(t, c_take_m256(make_v8f(1), 5.5, make_v8f(11), 77), 1)
	testing.expect_value(t, c_take_five(zero, zero, zero, zero, make_v8f(41)), 1)
	testing.expect_value(t, c_calls_odin(), 1)
}
