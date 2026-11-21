#+build i386, amd64
package simd_x86

// Perform a carry-less multiplication of two 64-bit integers, selected from `a` and `b` according to `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_clmulepi64_si128)
@(require_results, enable_target_feature="pclmul")
_mm_clmulepi64_si128 :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return llvm_pclmulqdq(a, b, cast(u8)IMM8)
}

// Carry-less multiplication of one quadword of `a` by one quadword of `b`, stores the 128-bit result in `dst`.
// The immediate `imm8` is used to determine which quadwords of `a` and `b` should be used.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_clmulepi64_epi128)
@(require_results, enable_target_feature="vpclmulqdq")
_mm256_clmulepi64_epi128 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return llvm_pclmulqdq_256(a, b, cast(u8)IMM8)
}

// Carry-less multiplication of one quadword of `a` by one quadword of `b`, stores the 128-bit result in `dst`.
// The immediate `imm8` is used to determine which quadwords of `a` and `b` should be used.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_clmulepi64_epi128)
@(require_results, enable_target_feature="vpclmulqdq,avx512f")
_mm512_clmulepi64_epi128 :: #force_inline proc "c" (a, b: __m512i, $IMM8: i32) -> __m512i where 0 <= IMM8, IMM8 < 256 {
	return llvm_pclmulqdq_512(a, b, cast(u8)IMM8)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.pclmulqdq")     llvm_pclmulqdq     :: proc(a, b: __m128i, imm8: u8) -> __m128i ---
	@(link_name="llvm.x86.pclmulqdq.256") llvm_pclmulqdq_256 :: proc(a, b: __m256i, imm8: u8) -> __m256i ---
	@(link_name="llvm.x86.pclmulqdq.512") llvm_pclmulqdq_512 :: proc(a, b: __m512i, imm8: u8) -> __m512i ---
}
