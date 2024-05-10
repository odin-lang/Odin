//+build i386, amd64
package simd_x86

import "core:intrinsics"
import "core:simd"

@(require_results, enable_target_feature="sse3")
_mm_addsub_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return addsubps(a, b)
}
@(require_results, enable_target_feature="sse3")
_mm_addsub_pd :: #force_inline proc "c" (a: __m128d, b: __m128d) -> __m128d {
	return addsubpd(a, b)
}
@(require_results, enable_target_feature="sse3")
_mm_hadd_pd :: #force_inline proc "c" (a: __m128d, b: __m128d) -> __m128d {
	return haddpd(a, b)
}
@(require_results, enable_target_feature="sse3")
_mm_hadd_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return haddps(a, b)
}
@(require_results, enable_target_feature="sse3")
_mm_hsub_pd :: #force_inline proc "c" (a: __m128d, b: __m128d) -> __m128d {
	return hsubpd(a, b)
}
@(require_results, enable_target_feature="sse3")
_mm_hsub_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return hsubps(a, b)
}
@(require_results, enable_target_feature="sse3")
_mm_lddqu_si128 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	return transmute(__m128i)lddqu(mem_addr)
}
@(require_results, enable_target_feature="sse3")
_mm_movedup_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.shuffle(a, a, 0, 0)
}
@(require_results, enable_target_feature="sse2,sse3")
_mm_loaddup_pd :: #force_inline proc "c" (mem_addr: [^]f64) -> __m128d {
	return _mm_load1_pd(mem_addr)
}
@(require_results, enable_target_feature="sse3")
_mm_movehdup_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.shuffle(a, a, 1, 1, 3, 3)
}
@(require_results, enable_target_feature="sse3")
_mm_moveldup_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.shuffle(a, a, 0, 0, 2, 2)
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name = "llvm.x86.sse3.addsub.ps")
	addsubps :: proc(a, b: __m128) -> __m128 ---
	@(link_name = "llvm.x86.sse3.addsub.pd")
	addsubpd :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name = "llvm.x86.sse3.hadd.pd")
	haddpd :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name = "llvm.x86.sse3.hadd.ps")
	haddps :: proc(a, b: __m128) -> __m128 ---
	@(link_name = "llvm.x86.sse3.hsub.pd")
	hsubpd :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name = "llvm.x86.sse3.hsub.ps")
	hsubps :: proc(a, b: __m128) -> __m128 ---
	@(link_name = "llvm.x86.sse3.ldu.dq")
	lddqu :: proc(mem_addr: rawptr) -> i8x16 ---
}
