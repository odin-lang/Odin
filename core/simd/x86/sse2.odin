//+build i386, amd64
package simd_x86

import "base:intrinsics"
import "core:simd"

@(enable_target_feature="sse2")
_mm_pause :: #force_inline proc "c" () {
	pause()
}
@(enable_target_feature="sse2")
_mm_clflush :: #force_inline proc "c" (p: rawptr) {
	clflush(p)
}
@(enable_target_feature="sse2")
_mm_lfence :: #force_inline proc "c" () {
	lfence()
}
@(enable_target_feature="sse2")
_mm_mfence :: #force_inline proc "c" () {
	mfence()
}

@(require_results, enable_target_feature="sse2")
_mm_add_epi8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_add_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_add_epi32 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse2")
_mm_add_epi64 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return simd.add(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_adds_epi8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_adds_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_adds_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(u8x16)a, transmute(u8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_adds_epu16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(u16x8)a, transmute(u16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_avg_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pavgb(transmute(u8x16)a, transmute(u8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_avg_epu16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pavgw(transmute(u16x8)a, transmute(u16x8)b)
}

@(require_results, enable_target_feature="sse2")
_mm_madd_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pmaddwd(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_max_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pmaxsw(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_max_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pmaxub(transmute(u8x16)a, transmute(u8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_min_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pminsw(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_min_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pminub(transmute(u8x16)a, transmute(u8x16)b)
}


@(require_results, enable_target_feature="sse2")
_mm_mulhi_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmulhw(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_mulhi_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmulhuw(transmute(u16x8)a, transmute(u16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_mullo_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.mul(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_mul_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmuludq(transmute(u32x4)a, transmute(u32x4)b)
}
@(require_results, enable_target_feature="sse2")
_mm_sad_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)psadbw(transmute(u8x16)a, transmute(u8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_sub_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_sub_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_sub_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse2")
_mm_sub_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.sub(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_subs_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_subs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_subs_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(u8x16)a, transmute(u8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_subs_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(u16x8)a, transmute(u16x8)b)
}



@(private)
@(require_results, enable_target_feature="sse2")
_mm_slli_si128_impl :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	shift :: IMM8 & 0xff

	return transmute(__m128i)simd.shuffle(
		transmute(i8x16)a,
		i8x16(0),
		0  when shift > 15 else (16 - shift + 0),
		1  when shift > 15 else (16 - shift + 1),
		2  when shift > 15 else (16 - shift + 2),
		3  when shift > 15 else (16 - shift + 3),
		4  when shift > 15 else (16 - shift + 4),
		5  when shift > 15 else (16 - shift + 5),
		6  when shift > 15 else (16 - shift + 6),
		7  when shift > 15 else (16 - shift + 7),
		8  when shift > 15 else (16 - shift + 8),
		9  when shift > 15 else (16 - shift + 9),
		10 when shift > 15 else (16 - shift + 10),
		11 when shift > 15 else (16 - shift + 11),
		12 when shift > 15 else (16 - shift + 12),
		13 when shift > 15 else (16 - shift + 13),
		14 when shift > 15 else (16 - shift + 14),
		15 when shift > 15 else (16 - shift + 15),
	)
}

@(private)
@(require_results, enable_target_feature="sse2")
_mm_srli_si128_impl :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	shift :: IMM8
	return transmute(__m128i)simd.shuffle(
		transmute(i8x16)a,
		i8x16(0),
		0  + 16 when shift > 15 else (shift + 0),
		1  + 16 when shift > 15 else (shift + 1),
		2  + 16 when shift > 15 else (shift + 2),
		3  + 16 when shift > 15 else (shift + 3),
		4  + 16 when shift > 15 else (shift + 4),
		5  + 16 when shift > 15 else (shift + 5),
		6  + 16 when shift > 15 else (shift + 6),
		7  + 16 when shift > 15 else (shift + 7),
		8  + 16 when shift > 15 else (shift + 8),
		9  + 16 when shift > 15 else (shift + 9),
		10 + 16 when shift > 15 else (shift + 10),
		11 + 16 when shift > 15 else (shift + 11),
		12 + 16 when shift > 15 else (shift + 12),
		13 + 16 when shift > 15 else (shift + 13),
		14 + 16 when shift > 15 else (shift + 14),
		15 + 16 when shift > 15 else (shift + 15),
	)
}


@(require_results, enable_target_feature="sse2")
_mm_slli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_slli_si128_impl(a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_bslli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_slli_si128_impl(a, IMM8)
}


@(require_results, enable_target_feature="sse2")
_mm_bsrli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_srli_si128_impl(a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_slli_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)pslliw(transmute(i16x8)a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_sll_epi16 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psllw(transmute(i16x8)a, transmute(i16x8)count)
}
@(require_results, enable_target_feature="sse2")
_mm_slli_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psllid(transmute(i32x4)a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_sll_epi32 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)pslld(transmute(i32x4)a, transmute(i32x4)count)
}
@(require_results, enable_target_feature="sse2")
_mm_slli_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)pslliq(transmute(i64x2)a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_sll_epi64 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return psllq(a, count)
}
@(require_results, enable_target_feature="sse2")
_mm_srai_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psraiw(transmute(i16x8)a. IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_sra_epi16 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psraw(transmute(i16x8)a, transmute(i16x8)count)
}
@(require_results, enable_target_feature="sse2")
_mm_srai_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psraid(transmute(i32x4)a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_sra_epi32 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrad(transmute(i32x4)a, transmute(i32x4)count)
}


@(require_results, enable_target_feature="sse2")
_mm_srli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_srli_si128_impl(a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_srli_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psrliw(transmute(i16x8)a. IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_srl_epi16 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrlw(transmute(i16x8)a, transmute(i16x8)count)
}
@(require_results, enable_target_feature="sse2")
_mm_srli_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psrlid(transmute(i32x4)a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_srl_epi32 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrld(transmute(i32x4)a, transmute(i32x4)count)
}
@(require_results, enable_target_feature="sse2")
_mm_srli_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psrliq(transmute(i64x2)a, IMM8)
}
@(require_results, enable_target_feature="sse2")
_mm_srl_epi64 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return psrlq(a, count)
}


@(require_results, enable_target_feature="sse2")
_mm_and_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_and(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_andnot_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_and_not(b, a)
}
@(require_results, enable_target_feature="sse2")
_mm_or_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_or(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_xor_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_xor(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmplt_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmplt_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_cmplt_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(i32x4)a, transmute(i32x4)b)
}


@(require_results, enable_target_feature="sse2")
_mm_cvtepi32_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	v := transmute(i32x4)a
	return cast(__m128d)simd.shuffle(v, v, 0, 1)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtsi32_sd :: #force_inline proc "c" (a: __m128d, b: i32) -> __m128d {
	return simd.replace(a, 0, f64(b))
}
@(require_results, enable_target_feature="sse2")
_mm_cvtepi32_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return cvtdq2ps(transmute(i32x4)a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtps_epi32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)cvtps2dq(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtsi32_si128 :: #force_inline proc "c" (a: i32) -> __m128i {
	return transmute(__m128i)i32x4{a, 0, 0, 0}
}
@(require_results, enable_target_feature="sse2")
_mm_cvtsi128_si32 :: #force_inline proc "c" (a: __m128i) -> i32 {
	return simd.extract(transmute(i32x4)a, 0)
}



@(require_results, enable_target_feature="sse2")
_mm_set_epi64x :: #force_inline proc "c" (e1, e0: i64) -> __m128i {
	return i64x2{e0, e1}
}
@(require_results, enable_target_feature="sse2")
_mm_set_epi32 :: #force_inline proc "c" (e3, e2, e1, e0: i32) -> __m128i {
	return transmute(__m128i)i32x4{e0, e1, e2, e3}
}
@(require_results, enable_target_feature="sse2")
_mm_set_epi16 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i16) -> __m128i {
	return transmute(__m128i)i16x8{e0, e1, e2, e3, e4, e5, e6, e7}
}
@(require_results, enable_target_feature="sse2")
_mm_set_epi8 :: #force_inline proc "c" (e15, e14, e13, e12, e11, e10, e9, e8, e7, e6, e5, e4, e3, e2, e1, e0: i8) -> __m128i {
	return transmute(__m128i)i8x16{e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15}
}
@(require_results, enable_target_feature="sse2")
_mm_set1_epi64x :: #force_inline proc "c" (a: i64) -> __m128i {
	return _mm_set_epi64x(a, a)
}
@(require_results, enable_target_feature="sse2")
_mm_set1_epi32 :: #force_inline proc "c" (a: i32) -> __m128i {
	return _mm_set_epi32(a, a, a, a)
}
@(require_results, enable_target_feature="sse2")
_mm_set1_epi16 :: #force_inline proc "c" (a: i16) -> __m128i {
	return _mm_set_epi16(a, a, a, a, a, a, a, a)
}
@(require_results, enable_target_feature="sse2")
_mm_set1_epi8 :: #force_inline proc "c" (a: i8) -> __m128i {
	return _mm_set_epi8(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a)
}
@(require_results, enable_target_feature="sse2")
_mm_setr_epi32 :: #force_inline proc "c" (e3, e2, e1, e0: i32) -> __m128i {
	return _mm_set_epi32(e0, e1, e2, e3)
}
@(require_results, enable_target_feature="sse2")
_mm_setr_epi16 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i16) -> __m128i {
	return _mm_set_epi16(e0, e1, e2, e3, e4, e5, e6, e7)
}
@(require_results, enable_target_feature="sse2")
_mm_setr_epi8 :: #force_inline proc "c" (e15, e14, e13, e12, e11, e10, e9, e8, e7, e6, e5, e4, e3, e2, e1, e0: i8) -> __m128i {
	return _mm_set_epi8(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15)
}
@(require_results, enable_target_feature="sse2")
_mm_setzero_si128 :: #force_inline proc "c" () -> __m128i {
	return _mm_set1_epi64x(0)
}


@(require_results, enable_target_feature="sse2")
_mm_loadl_epi64 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	return _mm_set_epi64x(0, intrinsics.unaligned_load((^i64)(mem_addr)))
}
@(require_results, enable_target_feature="sse2")
_mm_load_si128 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	return mem_addr^
}
@(require_results, enable_target_feature="sse2")
_mm_loadu_si128 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	dst := _mm_undefined_si128()
	intrinsics.mem_copy_non_overlapping(&dst, mem_addr, size_of(__m128i))
	return dst
}
@(enable_target_feature="sse2")
_mm_maskmoveu_si128 :: #force_inline proc "c" (a, mask: __m128i, mem_addr: rawptr) {
	maskmovdqu(transmute(i8x16)a, transmute(i8x16)mask, mem_addr)
}
@(enable_target_feature="sse2")
_mm_store_si128 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	mem_addr^ = a
}
@(enable_target_feature="sse2")
_mm_storeu_si128 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	storeudq(mem_addr, a)
}
@(enable_target_feature="sse2")
_mm_storel_epi64 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	a := a
	intrinsics.mem_copy_non_overlapping(mem_addr, &a, 8)
}
@(enable_target_feature="sse2")
_mm_stream_si128 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	intrinsics.non_temporal_store(mem_addr, a)
}
@(enable_target_feature="sse2")
_mm_stream_si32 :: #force_inline proc "c" (mem_addr: ^i32, a: i32) {
	intrinsics.non_temporal_store(mem_addr, a)
}
@(require_results, enable_target_feature="sse2")
_mm_move_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	zero := _mm_setzero_si128()
	return simd.shuffle(a, zero, 0, 2)
}




@(require_results, enable_target_feature="sse2")
_mm_packs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)packsswb(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_packs_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)packssdw(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse2")
_mm_packus_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)packuswb(transmute(i16x8)a, transmute(i16x8)b)
}
@(require_results, enable_target_feature="sse2")
_mm_extract_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> i32 {
	return i32(simd.extract(transmute(u16x8)a, IMM8))
}
@(require_results, enable_target_feature="sse2")
_mm_insert_epi16 :: #force_inline proc "c" (a: __m128i, i: i32, $IMM8: u32) -> __m128i {
	return i32(simd.replace(transmute(u16x8)a, IMM8, i16(i)))
}
@(require_results, enable_target_feature="sse2")
_mm_movemask_epi8 :: #force_inline proc "c" (a: __m128i) -> i32 {
	return pmovmskb(transmute(i8x16)a)
}
@(require_results, enable_target_feature="sse2")
_mm_shuffle_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	v := transmute(i32x4)a
	return transmute(__m128i)simd.shuffle(
		v,
		v,
		IMM8 & 0b11,
		(IMM8 >> 2) & 0b11,
		(IMM8 >> 4) & 0b11,
		(IMM8 >> 6) & 0b11,
	)
}
@(require_results, enable_target_feature="sse2")
_mm_shufflehi_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	v := transmute(i16x8)a
	return transmute(__m128i)simd.shuffle(
		v,
		v,
		0,
		1,
		2,
		3,
		(IMM8 & 0b11) + 4,
		((IMM8 >> 2) & 0b11) + 4,
		((IMM8 >> 4) & 0b11) + 4,
		((IMM8 >> 6) & 0b11) + 4,
	)
}
@(require_results, enable_target_feature="sse2")
_mm_shufflelo_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	v := transmute(i16x8)a
	return transmute(__m128i)simd.shuffle(
		v,
		v,
		IMM8 & 0b11,
		(IMM8 >> 2) & 0b11,
		(IMM8 >> 4) & 0b11,
		(IMM8 >> 6) & 0b11,
		4,
		5,
		6,
		7,
	)
}
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
	        transmute(i8x16)a,
	        transmute(i8x16)b,
        	8, 24, 9, 25, 10, 26, 11, 27, 12, 28, 13, 29, 14, 30, 15, 31,
	)
}
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(transmute(i16x8)a, transmute(i16x8)b, 4, 12, 5, 13, 6, 14, 7, 15)
}
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(transmute(i32x4)a, transmute(i32x4)b, 2, 6, 3, 7)
}
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.shuffle(a, b, 1, 3)
}
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
	        transmute(i8x16)a,
	        transmute(i8x16)b,
        	0, 16, 1, 17, 2, 18, 3, 19, 4, 20, 5, 21, 6, 22, 7, 23,
	)
}
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(transmute(i16x8)a, transmute(i16x8)b, 0, 8, 1, 9, 2, 10, 3, 11)
}
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(transmute(i32x4)a, transmute(i32x4)b, 0, 4, 1, 5)
}
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.shuffle(a, b, 0, 2)
}




@(require_results, enable_target_feature="sse2")
_mm_add_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, _mm_cvtsd_f64(a) + _mm_cvtsd_f64(b))
}
@(require_results, enable_target_feature="sse2")
_mm_add_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.add(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_div_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, _mm_cvtsd_f64(a) / _mm_cvtsd_f64(b))
}
@(require_results, enable_target_feature="sse2")
_mm_div_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.div(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_max_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return maxsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_max_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return maxpd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_min_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return minsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_min_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return minpd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_mul_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, _mm_cvtsd_f64(a) * _mm_cvtsd_f64(b))
}
@(require_results, enable_target_feature="sse2")
_mm_mul_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.mul(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_sqrt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, _mm_cvtsd_f64(sqrtsd(b)))
}
@(require_results, enable_target_feature="sse2")
_mm_sqrt_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.sqrt(a)
}
@(require_results, enable_target_feature="sse2")
_mm_sub_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, _mm_cvtsd_f64(a) - _mm_cvtsd_f64(b))
}
@(require_results, enable_target_feature="sse2")
_mm_sub_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.sub(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_and_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)_mm_and_si128(transmute(__m128i)a, transmute(__m128i)b)
}
@(require_results, enable_target_feature="sse2")
_mm_andnot_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)_mm_andnot_si128(transmute(__m128i)a, transmute(__m128i)b)
}
@(require_results, enable_target_feature="sse2")
_mm_or_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)_mm_or_si128(transmute(__m128i)a, transmute(__m128i)b)
}
@(require_results, enable_target_feature="sse2")
_mm_xor_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)_mm_xor_si128(transmute(__m128i)a, transmute(__m128i)b)
}




@(require_results, enable_target_feature="sse2")
_mm_cmpeq_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 0)
}
@(require_results, enable_target_feature="sse2")
_mm_cmplt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 1)
}
@(require_results, enable_target_feature="sse2")
_mm_cmple_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 2)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(_mm_cmplt_sd(b, a), 1, simd.extract(a, 1))
}
@(require_results, enable_target_feature="sse2")
_mm_cmpge_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(_mm_cmple_sd(b, a), 1, simd.extract(a, 1))
}
@(require_results, enable_target_feature="sse2")
_mm_cmpord_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 7)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpunord_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 3)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpneq_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 4)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpnlt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 5)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpnle_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmpsd(a, b, 6)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpngt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(_mm_cmpnlt_sd(b, a), 1, simd.extract(a, 1))
}
@(require_results, enable_target_feature="sse2")
_mm_cmpnge_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(_mm_cmpnle_sd(b, a), 1, simd.extract(a, 1))
}
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 0)
}
@(require_results, enable_target_feature="sse2")
_mm_cmplt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 1)
}
@(require_results, enable_target_feature="sse2")
_mm_cmple_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 2)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return _mm_cmplt_pd(b, a)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpge_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return _mm_cmple_pd(b, a)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpord_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 7)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpunord_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 3)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpneq_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 4)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpnlt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 5)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpnle_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return cmppd(a, b, 6)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpngt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return _mm_cmpnlt_pd(b, a)
}
@(require_results, enable_target_feature="sse2")
_mm_cmpnge_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return _mm_cmpnle_pd(b, a)
}
@(require_results, enable_target_feature="sse2")
_mm_comieq_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return comieqsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_comilt_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return comiltsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_comile_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return comilesd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_comigt_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return comigtsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_comige_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return comigesd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_comineq_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return comineqsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_ucomieq_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return ucomieqsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_ucomilt_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return ucomiltsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_ucomile_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return ucomilesd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_ucomigt_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return ucomigtsd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_ucomige_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return ucomigesd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_ucomineq_sd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return ucomineqsd(a, b)
}





@(require_results, enable_target_feature="sse2")
_mm_cvtpd_ps :: #force_inline proc "c" (a: __m128d) -> __m128 {
	return cvtpd2ps(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtps_pd :: #force_inline proc "c" (a: __m128) -> __m128d {
	return cvtps2pd(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtpd_epi32 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)cvtpd2dq(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtsd_si32 :: #force_inline proc "c" (a: __m128d) -> i32 {
	return cvtsd2si(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtsd_ss :: #force_inline proc "c" (a, b: __m128d) -> __m128 {
	return cvtsd2ss(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtsd_f64 :: #force_inline proc "c" (a: __m128d) -> f64 {
	return simd.extract(a, 0)
}
@(require_results, enable_target_feature="sse2")
_mm_cvtss_sd :: #force_inline proc "c" (a, b: __m128) -> __m128d {
	return cvtss2sd(a, b)
}
@(require_results, enable_target_feature="sse2")
_mm_cvttpd_epi32 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)cvttpd2dq(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvttsd_si32 :: #force_inline proc "c" (a: __m128d) -> i32 {
	return cvttsd2si(a)
}
@(require_results, enable_target_feature="sse2")
_mm_cvttps_epi32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)cvttps2dq(a)
}
@(require_results, enable_target_feature="sse2")
_mm_set_sd :: #force_inline proc "c" (a: f64) -> __m128d {
	return _mm_set_pd(0.0, a)
}
@(require_results, enable_target_feature="sse2")
_mm_set1_pd :: #force_inline proc "c" (a: f64) -> __m128d {
	return _mm_set_pd(a, a)
}
@(require_results, enable_target_feature="sse2")
_mm_set_pd1 :: #force_inline proc "c" (a: f64) -> __m128d {
	return _mm_set_pd(a, a)
}
@(require_results, enable_target_feature="sse2")
_mm_set_pd :: #force_inline proc "c" (a: f64, b: f64) -> __m128d {
	return __m128d{b, a}
}
@(require_results, enable_target_feature="sse2")
_mm_setr_pd :: #force_inline proc "c" (a: f64, b: f64) -> __m128d {
	return _mm_set_pd(b, a)
}
@(require_results, enable_target_feature="sse2")
_mm_setzero_pd :: #force_inline proc "c" () -> __m128d {
	return _mm_set_pd(0.0, 0.0)
}
@(require_results, enable_target_feature="sse2")
_mm_movemask_pd :: #force_inline proc "c" (a: __m128d) -> i32 {
	return movmskpd(a)
}
@(require_results, enable_target_feature="sse2")
_mm_load_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return (^__m128d)(mem_addr)^
}
@(require_results, enable_target_feature="sse2")
_mm_load_sd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return _mm_setr_pd(mem_addr^, 0.)
}
@(require_results, enable_target_feature="sse2")
_mm_loadh_pd :: #force_inline proc "c" (a: __m128d, mem_addr: ^f64) -> __m128d {
	return _mm_setr_pd(simd.extract(a, 0), mem_addr^)
}
@(require_results, enable_target_feature="sse2")
_mm_loadl_pd :: #force_inline proc "c" (a: __m128d, mem_addr: ^f64) -> __m128d {
	return _mm_setr_pd(mem_addr^, simd.extract(a, 1))
}
@(enable_target_feature="sse2")
_mm_stream_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	intrinsics.non_temporal_store((^__m128d)(mem_addr), a)
}
@(enable_target_feature="sse2")
_mm_store_sd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	mem_addr^ = simd.extract(a, 0)
}
@(enable_target_feature="sse2")
_mm_store_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	(^__m128d)(mem_addr)^ = a
}
@(enable_target_feature="sse2")
_mm_storeu_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	storeupd(mem_addr, a)
}
@(enable_target_feature="sse2")
_mm_store1_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	(^__m128d)(mem_addr)^ = simd.shuffle(a, a, 0, 0)
}
@(enable_target_feature="sse2")
_mm_store_pd1 :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	(^__m128d)(mem_addr)^ = simd.shuffle(a, a, 0, 0)
}
@(enable_target_feature="sse2")
_mm_storer_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	(^__m128d)(mem_addr)^ = simd.shuffle(a, a, 1, 0)
}
@(enable_target_feature="sse2")
_mm_storeh_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	mem_addr^ = simd.extract(a, 1)
}
@(enable_target_feature="sse2")
_mm_storel_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	mem_addr^ = simd.extract(a, 0)
}
@(require_results, enable_target_feature="sse2")
_mm_load1_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	d := mem_addr^
	return _mm_setr_pd(d, d)
}
@(require_results, enable_target_feature="sse2")
_mm_load_pd1 :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return _mm_load1_pd(mem_addr)
}
@(require_results, enable_target_feature="sse2")
_mm_loadr_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	a := _mm_load_pd(mem_addr)
	return simd.shuffle(a, a, 1, 0)
}
@(require_results, enable_target_feature="sse2")
_mm_loadu_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	dst := _mm_undefined_pd()
	intrinsics.mem_copy_non_overlapping(&dst, mem_addr, size_of(__m128d))
	return dst
}
@(require_results, enable_target_feature="sse2")
_mm_shuffle_pd :: #force_inline proc "c" (a, b: __m128d, $MASK: u32) -> __m128d {
	return simd.shuffle(a, b, MASK&0b1, ((MASK>>1)&0b1) + 2)
}
@(require_results, enable_target_feature="sse2")
_mm_move_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return _mm_setr_pd(simd.extract(b, 0), simd.extract(a, 1))
}




@(require_results, enable_target_feature="sse2")
_mm_castpd_ps :: #force_inline proc "c" (a: __m128d) -> __m128 {
	return transmute(__m128)a
}
@(require_results, enable_target_feature="sse2")
_mm_castpd_si128 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)a
}
@(require_results, enable_target_feature="sse2")
_mm_castps_pd :: #force_inline proc "c" (a: __m128) -> __m128d {
	return transmute(__m128d)a
}
@(require_results, enable_target_feature="sse2")
_mm_castps_si128 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)a
}
@(require_results, enable_target_feature="sse2")
_mm_castsi128_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	return transmute(__m128d)a
}
@(require_results, enable_target_feature="sse2")
_mm_castsi128_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return transmute(__m128)a
}


@(require_results, enable_target_feature="sse2")
_mm_undefined_pd :: #force_inline proc "c" () -> __m128d {
	return __m128d{0, 0}
}
@(require_results, enable_target_feature="sse2")
_mm_undefined_si128 :: #force_inline proc "c" () -> __m128i {
	return __m128i{0, 0}
}
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(a, b, 1, 3)
}
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(a, b, 0, 2)
}


when ODIN_ARCH == .amd64 {
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsd_si64 :: #force_inline proc "c" (a: __m128d) -> i64 {
		return cvtsd2si64(a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsd_si64x :: #force_inline proc "c" (a: __m128d) -> i64 {
		return _mm_cvtsd_si64(a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvttsd_si64 :: #force_inline proc "c" (a: __m128d) -> i64 {
		return cvttsd2si64(a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvttsd_si64x :: #force_inline proc "c" (a: __m128d) -> i64 {
		return _mm_cvttsd_si64(a)
	}
	@(enable_target_feature="sse2")
	_mm_stream_si64 :: #force_inline proc "c" (mem_addr: ^i64, a: i64) {
		intrinsics.non_temporal_store(mem_addr, a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64_si128 :: #force_inline proc "c" (a: i64) -> __m128i {
		return _mm_set_epi64x(0, a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64x_si128 :: #force_inline proc "c" (a: i64) -> __m128i {
		return _mm_cvtsi64_si128(a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi128_si64 :: #force_inline proc "c" (a: __m128i) -> i64 {
		return simd.extract(a, 0)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi128_si64x :: #force_inline proc "c" (a: __m128i) -> i64 {
		return _mm_cvtsi128_si64(a)
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64_sd :: #force_inline proc "c" (a: __m128d, b: i64) -> __m128d {
		return simd.replace(a, 0, f64(b))
	}
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64x_sd :: #force_inline proc "c" (a: __m128d, b: i64) -> __m128d {
		return _mm_cvtsi64_sd(a, b)
	}
}


@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse2.pause")
	pause      :: proc() ---
	@(link_name="llvm.x86.sse2.clflush")
	clflush    :: proc(p: rawptr) ---
	@(link_name="llvm.x86.sse2.lfence")
	lfence     :: proc() ---
	@(link_name="llvm.x86.sse2.mfence")
	mfence     :: proc() ---
	@(link_name="llvm.x86.sse2.pavg.b")
	pavgb      :: proc(a, b: u8x16) -> u8x16 ---
	@(link_name="llvm.x86.sse2.pavg.w")
	pavgw      :: proc(a, b: u16x8) -> u16x8 ---
	@(link_name="llvm.x86.sse2.pmadd.wd")
	pmaddwd    :: proc(a, b: i16x8) -> i32x4 ---
	@(link_name="llvm.x86.sse2.pmaxs.w")
	pmaxsw     :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name="llvm.x86.sse2.pmaxu.b")
	pmaxub     :: proc(a, b: u8x16) -> u8x16 ---
	@(link_name="llvm.x86.sse2.pmins.w")
	pminsw     :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name="llvm.x86.sse2.pminu.b")
	pminub     :: proc(a, b: u8x16) -> u8x16 ---
	@(link_name="llvm.x86.sse2.pmulh.w")
	pmulhw     :: proc(a, b: i16x8) -> i16x8 ---
	@(link_name="llvm.x86.sse2.pmulhu.w")
	pmulhuw    :: proc(a, b: u16x8) -> u16x8 ---
	@(link_name="llvm.x86.sse2.pmulu.dq")
	pmuludq    :: proc(a, b: u32x4) -> u64x2 ---
	@(link_name="llvm.x86.sse2.psad.bw")
	psadbw     :: proc(a, b: u8x16) -> u64x2 ---
	@(link_name="llvm.x86.sse2.pslli.w")
	pslliw     :: proc(a: i16x8, #const imm8: u32) -> i16x8 ---
	@(link_name="llvm.x86.sse2.psll.w")
	psllw      :: proc(a: i16x8, count: i16x8) -> i16x8 ---
	@(link_name="llvm.x86.sse2.pslli.d")
	psllid     :: proc(a: i32x4, #const imm8: u32) -> i32x4 ---
	@(link_name="llvm.x86.sse2.psll.d")
	pslld      :: proc(a: i32x4, count: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sse2.pslli.q")
	pslliq     :: proc(a: i64x2, #const imm8: u32) -> i64x2 ---
	@(link_name="llvm.x86.sse2.psll.q")
	psllq      :: proc(a: i64x2, count: i64x2) -> i64x2 ---
	@(link_name="llvm.x86.sse2.psrai.w")
	psraiw     :: proc(a: i16x8, #const imm8: u32) -> i16x8 ---
	@(link_name="llvm.x86.sse2.psra.w")
	psraw      :: proc(a: i16x8, count: i16x8) -> i16x8 ---
	@(link_name="llvm.x86.sse2.psrai.d")
	psraid     :: proc(a: i32x4, #const imm8: u32) -> i32x4 ---
	@(link_name="llvm.x86.sse2.psra.d")
	psrad      :: proc(a: i32x4, count: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sse2.psrli.w")
	psrliw     :: proc(a: i16x8, #const imm8: u32) -> i16x8 ---
	@(link_name="llvm.x86.sse2.psrl.w")
	psrlw      :: proc(a: i16x8, count: i16x8) -> i16x8 ---
	@(link_name="llvm.x86.sse2.psrli.d")
	psrlid     :: proc(a: i32x4, #const imm8: u32) -> i32x4 ---
	@(link_name="llvm.x86.sse2.psrl.d")
	psrld      :: proc(a: i32x4, count: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sse2.psrli.q")
	psrliq     :: proc(a: i64x2, #const imm8: u32) -> i64x2 ---
	@(link_name="llvm.x86.sse2.psrl.q")
	psrlq      :: proc(a: i64x2, count: i64x2) -> i64x2 ---
	@(link_name="llvm.x86.sse2.cvtdq2ps")
	cvtdq2ps   :: proc(a: i32x4) -> __m128 ---
	@(link_name="llvm.x86.sse2.cvtps2dq")
	cvtps2dq   :: proc(a: __m128) -> i32x4 ---
	@(link_name="llvm.x86.sse2.maskmov.dqu")
	maskmovdqu :: proc(a: i8x16, mask: i8x16, mem_addr: rawptr) ---
	@(link_name="llvm.x86.sse2.packsswb.128")
	packsswb   :: proc(a, b: i16x8) -> i8x16 ---
	@(link_name="llvm.x86.sse2.packssdw.128")
	packssdw   :: proc(a, b: i32x4) -> i16x8 ---
	@(link_name="llvm.x86.sse2.packuswb.128")
	packuswb   :: proc(a, b: i16x8) -> u8x16 ---
	@(link_name="llvm.x86.sse2.pmovmskb.128")
	pmovmskb   :: proc(a: i8x16) -> i32 ---
	@(link_name="llvm.x86.sse2.max.sd")
	maxsd      :: proc(a, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.max.pd")
	maxpd      :: proc(a, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.min.sd")
	minsd      :: proc(a, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.min.pd")
	minpd      :: proc(a, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.sqrt.sd")
	sqrtsd     :: proc(a: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.sqrt.pd")
	sqrtpd     :: proc(a: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.cmp.sd")
	cmpsd      :: proc(a, b: __m128d, imm8: i8) -> __m128d ---
	@(link_name="llvm.x86.sse2.cmp.pd")
	cmppd      :: proc(a, b: __m128d, imm8: i8) -> __m128d ---
	@(link_name="llvm.x86.sse2.comieq.sd")
	comieqsd   :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comilt.sd")
	comiltsd   :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comile.sd")
	comilesd   :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comigt.sd")
	comigtsd   :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comige.sd")
	comigesd   :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comineq.sd")
	comineqsd  :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomieq.sd")
	ucomieqsd  :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomilt.sd")
	ucomiltsd  :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomile.sd")
	ucomilesd  :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomigt.sd")
	ucomigtsd  :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomige.sd")
	ucomigesd  :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomineq.sd")
	ucomineqsd :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.movmsk.pd")
	movmskpd   :: proc(a: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.cvtpd2ps")
	cvtpd2ps   :: proc(a: __m128d) -> __m128 ---
	@(link_name="llvm.x86.sse2.cvtps2pd")
	cvtps2pd   :: proc(a: __m128) -> __m128d ---
	@(link_name="llvm.x86.sse2.cvtpd2dq")
	cvtpd2dq   :: proc(a: __m128d) -> i32x4 ---
	@(link_name="llvm.x86.sse2.cvtsd2si")
	cvtsd2si   :: proc(a: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.cvtsd2ss")
	cvtsd2ss   :: proc(a, b: __m128d) -> __m128 ---
	@(link_name="llvm.x86.sse2.cvtss2sd")
	cvtss2sd   :: proc(a, b: __m128) -> __m128d ---
	@(link_name="llvm.x86.sse2.cvttpd2dq")
	cvttpd2dq  :: proc(a: __m128d) -> i32x4 ---
	@(link_name="llvm.x86.sse2.cvttsd2si")
	cvttsd2si  :: proc(a: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.cvttps2dq")
	cvttps2dq  :: proc(a: __m128) -> i32x4 ---
	@(link_name="llvm.x86.sse2.storeu.dq")
	storeudq   :: proc(mem_addr: rawptr, a: __m128i) ---
	@(link_name="llvm.x86.sse2.storeu.pd")
	storeupd   :: proc(mem_addr: rawptr, a: __m128d) ---

	// amd64 only
	@(link_name="llvm.x86.sse2.cvtsd2si64")
	cvtsd2si64  :: proc(a: __m128d) -> i64 ---
	@(link_name="llvm.x86.sse2.cvttsd2si64")
	cvttsd2si64 :: proc(a: __m128d) -> i64 ---
}
