#+build i386, amd64
package simd_x86

import "base:intrinsics"

@(require_results, enable_target_feature="bmi")
_andn_u32 :: #force_inline proc "c" (a, b: u32) -> u32 {
	return a &~ b
}
@(require_results, enable_target_feature="bmi")
_andn_u64 :: #force_inline proc "c" (a, b: u64) -> u64 {
	return a &~ b
}

@(require_results, enable_target_feature="bmi")
_bextr_u32 :: #force_inline proc "c" (a, start, len: u32) -> u32 {
	return bextr_u32(a, (start & 0xff) | (len << 8))
}
@(require_results, enable_target_feature="bmi")
_bextr_u64 :: #force_inline proc "c" (a: u64, start, len: u32) -> u64 {
	return bextr_u64(a, cast(u64)((start & 0xff) | (len << 8)))
}

@(require_results, enable_target_feature="bmi")
_bextr2_u32 :: #force_inline proc "c" (a, control: u32) -> u32 {
	return bextr_u32(a, control)
}
@(require_results, enable_target_feature="bmi")
_bextr2_u64 :: #force_inline proc "c" (a, control: u64) -> u64 {
	return bextr_u64(a, control)
}

@(require_results, enable_target_feature="bmi")
_blsi_u32 :: #force_inline proc "c" (a: u32) -> u32 {
	return a & -a
}
@(require_results, enable_target_feature="bmi")
_blsi_u64 :: #force_inline proc "c" (a: u64) -> u64 {
	return a & -a
}

@(require_results, enable_target_feature="bmi")
_blsmsk_u32 :: #force_inline proc "c" (a: u32) -> u32 {
	return a ~ (a-1)
}
@(require_results, enable_target_feature="bmi")
_blsmsk_u64 :: #force_inline proc "c" (a: u64) -> u64 {
	return a ~ (a-1)
}

@(require_results, enable_target_feature="bmi")
_blsr_u32 :: #force_inline proc "c" (a: u32) -> u32 {
	return a & (a-1)
}
@(require_results, enable_target_feature="bmi")
_blsr_u64 :: #force_inline proc "c" (a: u64) -> u64 {
	return a & (a-1)
}

@(require_results, enable_target_feature = "bmi")
_tzcnt_u16 :: #force_inline proc "c" (a: u16) -> u16 {
	return intrinsics.count_trailing_zeros(a)
}
@(require_results, enable_target_feature = "bmi")
_tzcnt_u32 :: #force_inline proc "c" (a: u32) -> u32 {
	return intrinsics.count_trailing_zeros(a)
}
@(require_results, enable_target_feature = "bmi")
_tzcnt_u64 :: #force_inline proc "c" (a: u64) -> u64 {
	return intrinsics.count_trailing_zeros(a)
}

@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.x86.bmi.bextr.32")
	bextr_u32 :: proc(a, control: u32) -> u32 ---
	@(link_name = "llvm.x86.bmi.bextr.64")
	bextr_u64 :: proc(a, control: u64) -> u64 ---
}
