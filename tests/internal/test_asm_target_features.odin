#+build amd64
package test_internal

import "core:sys/info"
import "core:testing"

// An `asm` template is inlined into the procedure calling it, so the target features it enables must also be enabled
// by that procedure, and its operands may then be those which only those features allow, e.g. 256-bit vectors with avx

@(enable_target_feature="avx")
asm_target_features_add_ps :: asm(a, b: #simd[8]f32) -> (r: #simd[8]f32) { vaddps r, a, b }

@(test)
asm_target_features_enabled_by_caller :: proc(t: ^testing.T) {
	if .avx not_in info.cpu_features() {
		return
	}
	asm_target_features_enabled_by_caller_avx(t)
}

@(private="file", enable_target_feature="avx")
asm_target_features_enabled_by_caller_avx :: proc(t: ^testing.T) {
	r := asm_target_features_add_ps({1, 2, 3, 4, 5, 6, 7, 8}, 0.5)
	testing.expect_value(t, transmute([8]f32)r, [8]f32{1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5})
}
