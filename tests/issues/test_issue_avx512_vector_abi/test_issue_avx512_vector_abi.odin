// With AVX-512 enabled through -target-features on a microarch without it (the
// default x86-64-v2), LLVM didn't turn on `evex512`, so 512-bit vectors were
// passed and returned as two ymm halves while C uses one zmm register.
//
// Being an ABI guarantee, must be cross-checked against a c compiler.
// Built with -target-features:avx512f, see run.sh.
package test_issues

import "core:testing"

V16u32 :: #simd[16]u32
V8f64  :: #simd[8]f64
V32u32 :: #simd[32]u32

foreign import lib "build/test_issue_avx512_vector_abi_c.o"

@(default_calling_convention="c")
foreign lib {
	c_make_v16u32      :: proc(k: u32) -> V16u32 ---
	c_make_v8f64       :: proc(k: f64) -> V8f64 ---
	c_make_v32u32      :: proc(k: u32) -> V32u32 ---
	c_sum_odin_vectors :: proc(k: u32) -> u64 ---
}

@(export)
odin_make_v16u32 :: proc "c" (k: u32) -> V16u32 {
	a: [16]u32
	for &x, i in a { x = k + u32(i) }
	return transmute(V16u32)a
}

@(export)
odin_make_v8f64 :: proc "c" (k: f64) -> V8f64 {
	a: [8]f64
	for &x, i in a { x = k * f64(i) }
	return transmute(V8f64)a
}

@(export)
odin_make_v32u32 :: proc "c" (k: u32) -> V32u32 {
	a: [32]u32
	for &x, i in a { x = k + u32(i) }
	return transmute(V32u32)a
}

@(test)
test_c_returns_vectors :: proc(t: ^testing.T) {
	testing.expect_value(t, transmute([16]u32)c_make_v16u32(100), transmute([16]u32)odin_make_v16u32(100))
	testing.expect_value(t, transmute([8]f64)c_make_v8f64(1.5),   transmute([8]f64)odin_make_v8f64(1.5))
	testing.expect_value(t, transmute([32]u32)c_make_v32u32(7),   transmute([32]u32)odin_make_v32u32(7))
}

@(test)
test_odin_returns_vectors_to_c :: proc(t: ^testing.T) {
	k: u32 = 9
	want: u64
	for x in transmute([16]u32)odin_make_v16u32(k)      { want = want*31 + u64(x) }
	for x in transmute([8]f64)odin_make_v8f64(f64(k))   { want = want*31 + u64(x) }
	for x in transmute([32]u32)odin_make_v32u32(k)      { want = want*31 + u64(x) }
	testing.expect_value(t, c_sum_odin_vectors(k), want)
}
