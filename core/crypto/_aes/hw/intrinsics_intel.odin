#+build amd64
package aes_hw

import "core:simd"
import "core:simd/x86"

// Intel/RISC-V semantics.

TARGET_FEATURES :: "sse,sse2,ssse3,sse4.1,aes"
HAS_GHASH :: true

@(require_results, enable_target_feature = "aes")
aesdec :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_aesdec_si128(transmute(x86.__m128i)(data), transmute(x86.__m128i)(key)))
}

@(require_results, enable_target_feature = "aes")
aesdeclast :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_aesdeclast_si128(transmute(x86.__m128i)(data), transmute(x86.__m128i)(key)))
}

@(require_results, enable_target_feature = "aes")
aesenc :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_aesenc_si128(transmute(x86.__m128i)(data), transmute(x86.__m128i)(key)))
}

@(require_results, enable_target_feature = "aes")
aesenclast :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_aesenclast_si128(transmute(x86.__m128i)(data), transmute(x86.__m128i)(key)))
}

@(require_results, enable_target_feature = "aes")
aesimc :: #force_inline proc "c" (data: simd.u8x16) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_aesimc_si128(transmute(x86.__m128i)(data)))
}

@(require_results, enable_target_feature = "aes")
aeskeygenassist :: #force_inline proc "c" (data: simd.u8x16, $IMM8: u8) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_aeskeygenassist_si128(transmute(x86.__m128i)(data), IMM8))
}

@(private, require_results, enable_target_feature = TARGET_FEATURES)
_mm_slli_si128 :: #force_inline proc "c" (a: simd.u8x16, $IMM8: u32) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_slli_si128(transmute(x86.__m128i)(a), IMM8))
}

@(private, require_results, enable_target_feature = TARGET_FEATURES)
_mm_shuffle_epi32 :: #force_inline proc "c" (a: simd.u8x16, $IMM8: u32) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_shuffle_epi32(transmute(x86.__m128i)(a), IMM8))
}

@(private, require_results, enable_target_feature = TARGET_FEATURES)
_mm_shuffle_ps :: #force_inline proc "c" (a, b: simd.u8x16, $MASK: u32) -> simd.u8x16 {
	return transmute(simd.u8x16)(x86._mm_shuffle_ps(transmute(x86.__m128)(a), transmute(x86.__m128)(b), MASK))
}
