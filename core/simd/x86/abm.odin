//+build i386, amd64
package simd_x86

import "base:intrinsics"

@(require_results, enable_target_feature="lzcnt")
_lzcnt_u32 :: #force_inline proc "c" (x: u32) -> u32 {
	return intrinsics.count_leading_zeros(x)
}
@(require_results, enable_target_feature="popcnt")
_popcnt32 :: #force_inline proc "c" (x: u32) -> i32 {
	return i32(intrinsics.count_ones(x))
}

when ODIN_ARCH == .amd64 {
	@(require_results, enable_target_feature="lzcnt")
	_lzcnt_u64 :: #force_inline proc "c" (x: u64) -> u64 {
		return intrinsics.count_leading_zeros(x)
	}
	@(require_results, enable_target_feature="popcnt")
	_popcnt64 :: #force_inline proc "c" (x: u64) -> i32 {
		return i32(intrinsics.count_ones(x))
	}
}