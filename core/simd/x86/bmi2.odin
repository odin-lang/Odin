#+build i386, amd64
package simd_x86

@(require_results, enable_target_feature = "bmi2")
_bzhi_u32 :: #force_inline proc "c" (a, index: u32) -> u32 {
	return bzhi_u32(a, index)
}
@(require_results, enable_target_feature = "bmi2")
_bzhi_u64 :: #force_inline proc "c" (a, index: u64) -> u64 {
	return bzhi_u64(a, index)
}

@(require_results, enable_target_feature = "bmi2")
_pdep_u32 :: #force_inline proc "c" (a, mask: u32) -> u32 {
	return pdep_u32(a, mask)
}
@(require_results, enable_target_feature = "bmi2")
_pdep_u64 :: #force_inline proc "c" (a, mask: u64) -> u64 {
	return pdep_u64(a, mask)
}

@(require_results, enable_target_feature = "bmi2")
_pext_u32 :: #force_inline proc "c" (a, mask: u32) -> u32 {
	return pext_u32(a, mask)
}
@(require_results, enable_target_feature = "bmi2")
_pext_u64 :: #force_inline proc "c" (a, mask: u64) -> u64 {
	return pext_u64(a, mask)
}


@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.x86.bmi.bzhi.32")
	bzhi_u32 :: proc(a, index: u32) -> u32 ---
	@(link_name = "llvm.x86.bmi.bzhi.64")
	bzhi_u64 :: proc(a, index: u64) -> u64 ---
	@(link_name = "llvm.x86.bmi.pdep.32")
	pdep_u32 :: proc(a, mask: u32) -> u32 ---
	@(link_name = "llvm.x86.bmi.pdep.64")
	pdep_u64 :: proc(a, mask: u64) -> u64 ---
	@(link_name = "llvm.x86.bmi.pext.32")
	pext_u32 :: proc(a, mask: u32) -> u32 ---
	@(link_name = "llvm.x86.bmi.pext.64")
	pext_u64 :: proc(a, mask: u64) -> u64 ---
}
