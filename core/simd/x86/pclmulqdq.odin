//+build i386, amd64
package simd_x86

_mm_clmulepi64_si128 :: #force_inline proc "c" (a, b: __m128i, $IMM8: u8) -> __m128i {
	return pclmulqdq(a, b, u8(IMM8))
}

@(default_calling_convention="c")
@(private)
foreign _ {
	@(link_name="llvm.x86.pclmulqdq")
	pclmulqdq :: proc(a, round_key: __m128i, #const imm8: u8) -> __m128i ---
}