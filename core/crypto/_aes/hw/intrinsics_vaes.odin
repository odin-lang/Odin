#+build amd64
package aes_hw

import "core:simd"
import "core:simd/x86"

VAES_TARGET_FEATURES :: TARGET_FEATURES + ",avx,avx2,vaes,-slow-unaligned-mem-32"

@(require_results, enable_target_feature = "vaes")
vaesdec :: #force_inline proc "c" (data, key: simd.u8x32) -> simd.u8x32 {
	return transmute(simd.u8x32)(x86._mm256_aesdec_epi128(transmute(x86.__m256i)(data), transmute(x86.__m256i)(key)))
}

@(require_results, enable_target_feature = "vaes")
vaesdeclast :: #force_inline proc "c" (data, key: simd.u8x32) -> simd.u8x32 {
	return transmute(simd.u8x32)(x86._mm256_aesdeclast_epi128(transmute(x86.__m256i)(data), transmute(x86.__m256i)(key)))
}

@(require_results, enable_target_feature = "vaes")
vaesenc :: #force_inline proc "c" (data, key: simd.u8x32) -> simd.u8x32 {
	return transmute(simd.u8x32)(x86._mm256_aesenc_epi128(transmute(x86.__m256i)(data), transmute(x86.__m256i)(key)))
}

@(require_results, enable_target_feature = "vaes")
vaesenclast :: #force_inline proc "c" (data, key: simd.u8x32) -> simd.u8x32 {
	return transmute(simd.u8x32)(x86._mm256_aesenclast_epi128(transmute(x86.__m256i)(data), transmute(x86.__m256i)(key)))
}

@(require_results, enable_target_feature = VAES_TARGET_FEATURES)
broadcast_round_key :: #force_inline proc "c" (key: simd.u8x16) -> simd.u8x32 {
	k := transmute(simd.u64x2)key
	return transmute(simd.u8x32)simd.shuffle(k, k, 0, 1, 0, 1)
}
