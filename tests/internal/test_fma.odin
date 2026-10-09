package test_internal

import "base:intrinsics"
import "core:testing"

// fused_mul_add rounds once, in hardware with the fma target feature and through libc's fma
// otherwise. Matrix products fuse their multiply-adds only when the target has fma.

@(test)
fma_rounds_once :: proc(t: ^testing.T) {
	x, y, z := f32(0.1), f32(3.3), f32(-0.33)
	a, b, c := f64(0.1), f64(3.3), f64(-0.33)
	testing.expect_value(t, transmute(u32)intrinsics.fused_mul_add(x, y, z), 0xb25eb852)
	testing.expect_value(t, transmute(u64)intrinsics.fused_mul_add(a, b, c), 0xbc7147ae147ae148)

	v := #simd[4]f64{0.1, 0.7, 1.0/3.0, 3.3}
	r := transmute([4]u64)intrinsics.fused_mul_add(v, v, -v)
	testing.expect_value(t, r, [4]u64{0xbfb70a3d70a3d70b, 0xbfcae147ae147ae2, 0xbfcc71c71c71c71c, 0x401e5c28f5c28f5b})
}

@(test)
fma_matrix_product :: proc(t: ^testing.T) {
	m := matrix[3, 3]f64{0.1, 0.2, 0.3, 1.1, 1.2, 1.3, 2.1, 2.2, 2.3}
	p := m*m
	// (0.1*0.1 + 0.2*1.1) + 0.3*2.1, rounded after every step or fused.
	// Every arm64 CPU has a fused multiply-add, so arm64 always fuses.
	when ODIN_ARCH == .arm64 || intrinsics.has_target_feature("fma") {
		testing.expect_value(t, transmute(u64)p[0, 0], 0x3feb851eb851eb85)
	} else {
		testing.expect_value(t, transmute(u64)p[0, 0], 0x3feb851eb851eb86)
	}
}
