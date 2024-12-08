#+build i386, amd64
package simd_x86

import "base:intrinsics"
import "core:simd"
_ :: simd

@(require_results, enable_target_feature="ssse3")
_mm_abs_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)pabsb128(transmute(i8x16)a)
}
@(require_results, enable_target_feature="ssse3")
_mm_abs_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)pabsw128(transmute(i16x8)a)
}
@(require_results, enable_target_feature="ssse3")
_mm_abs_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)pabsd128(transmute(i32x4)a)
}
@(require_results, enable_target_feature="ssse3")
_mm_shuffle_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pshufb128(transmute(u8x16)a, transmute(u8x16)b)
}
@(require_results, enable_target_feature="sse2,ssse3")
_mm_alignr_epi8 :: #force_inline proc "c" (a, b: __m128i, $IMM8: u32) -> __m128i {
	shift :: IMM8

	// If palignr is shifting the pair of vectors more than the size of two
	// lanes, emit zero.
	if shift > 32 {
		return _mm_set1_epi8(0)
	}
	a, b := a, b
	if shift > 16 {
		a, b = _mm_set1_epi8(0), a
	}

	return transmute(__m128i)simd.shuffle(
		transmute(i8x16)b,
		transmute(i8x16)a,
		0  when shift > 32 else shift - 16 + 0  when shift > 16 else shift + 0,
		1  when shift > 32 else shift - 16 + 1  when shift > 16 else shift + 1,
		2  when shift > 32 else shift - 16 + 2  when shift > 16 else shift + 2,
		3  when shift > 32 else shift - 16 + 3  when shift > 16 else shift + 3,
		4  when shift > 32 else shift - 16 + 4  when shift > 16 else shift + 4,
		5  when shift > 32 else shift - 16 + 5  when shift > 16 else shift + 5,
		6  when shift > 32 else shift - 16 + 6  when shift > 16 else shift + 6,
		7  when shift > 32 else shift - 16 + 7  when shift > 16 else shift + 7,
		8  when shift > 32 else shift - 16 + 8  when shift > 16 else shift + 8,
		9  when shift > 32 else shift - 16 + 9  when shift > 16 else shift + 9,
		10 when shift > 32 else shift - 16 + 10 when shift > 16 else shift + 10,
		11 when shift > 32 else shift - 16 + 11 when shift > 16 else shift + 11,
		12 when shift > 32 else shift - 16 + 12 when shift > 16 else shift + 12,
		13 when shift > 32 else shift - 16 + 13 when shift > 16 else shift + 13,
		14 when shift > 32 else shift - 16 + 14 when shift > 16 else shift + 14,
		15 when shift > 32 else shift - 16 + 15 when shift > 16 else shift + 15,
	)
}


@(require_results, enable_target_feature="ssse3")
_mm_hadd_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)phaddw128(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_hadds_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)phaddsw128(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_hadd_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)phaddd128(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_hsub_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)phsubw128(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_hsubs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)phsubsw128(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_hsub_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)phsubd128(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_maddubs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmaddubsw128(transmute(u8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_mulhrs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmulhrsw128(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_sign_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)psignb128(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_sign_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)psignw128(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="ssse3")
_mm_sign_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)psignd128(transmute(i32x4)a, transmute(i32x4)b)
}



@(private, default_calling_convention="none")
foreign _ {
	@(link_name = "llvm.x86.ssse3.pabs.b.128")
	pabsb128     :: proc(a: i8x16) -> u8x16 ---
	@(link_name = "llvm.x86.ssse3.pabs.w.128")
	pabsw128     :: proc(a: i16x8) -> u16x8 ---
	@(link_name = "llvm.x86.ssse3.pabs.d.128")
	pabsd128     :: proc(a: i32x4) -> u32x4 ---
	@(link_name = "llvm.x86.ssse3.pshuf.b.128")
	pshufb128    :: proc(a, b: u8x16) -> u8x16 ---
	@(link_name = "llvm.x86.ssse3.phadd.w.128")
	phaddw128    :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.phadd.sw.128")
	phaddsw128   :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.phadd.d.128")
	phaddd128    :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name = "llvm.x86.ssse3.phsub.w.128")
	phsubw128    :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.phsub.sw.128")
	phsubsw128   :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.phsub.d.128")
	phsubd128    :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name = "llvm.x86.ssse3.pmadd.ub.sw.128")
	pmaddubsw128 :: proc(a: u8x16, b: i8x16) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.pmul.hr.sw.128")
	pmulhrsw128  :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.psign.b.128")
	psignb128    :: proc(a, b: i8x16) -> i8x16 ---
	@(link_name = "llvm.x86.ssse3.psign.w.128")
	psignw128    :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name = "llvm.x86.ssse3.psign.d.128")
	psignd128    :: proc(a, b: i32x4) -> i32x4 ---
}