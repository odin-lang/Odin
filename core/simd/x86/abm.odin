//+build i386, amd64
package simd_x86

import "core:intrinsics"

_lzcnt_u32 :: #force_inline proc "c" (x: u32) -> u32 {
	return intrinsics.count_leading_zeros(x)
}
_popcnt32 :: #force_inline proc "c" (x: u32) -> i32 {
	return i32(intrinsics.count_ones(x))
}

when ODIN_ARCH == .amd64 {
	_lzcnt_u64 :: #force_inline proc "c" (x: u64) -> u64 {
		return intrinsics.count_leading_zeros(x)
	}
	_popcnt64 :: #force_inline proc "c" (x: u64) -> i32 {
		return i32(intrinsics.count_ones(x))
	}
}