#+build i386, amd64
package simd_x86

@(require_results, enable_target_feature="pclmul")
_mm_clmulepi64_si128 :: #force_inline proc "c" (a, b: __m128i, $IMM8: u8) -> __m128i {
	return pclmulqdq(a, b, u8(IMM8))
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.pclmulqdq")
	pclmulqdq :: proc(a, round_key: __m128i, #const imm8: u8) -> __m128i ---
}