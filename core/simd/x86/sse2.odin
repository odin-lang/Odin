//+build i386, amd64
package simd_x86

import "core:simd"

_mm_pause :: #force_inline proc "c" () {
	pause()
}
_mm_clflush :: #force_inline proc "c" (p: rawptr) {
	clflush(p)
}
_mm_lfence :: #force_inline proc "c" () {
	lfence()
}
_mm_mfence :: #force_inline proc "c" () {
	mfence()
}

_mm_add_epi8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_add_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_add_epi32 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i32x4)a, transmute(i32x4)b)
}
_mm_add_epi64 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add(transmute(i64x2)a, transmute(i64x2)b)
}
_mm_adds_epi8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_adds_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_adds_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(u8x16)a, transmute(u8x16)b)
}
_mm_adds_epu16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)simd.add_sat(transmute(u16x8)a, transmute(u16x8)b)
}
_mm_avg_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pavgb(transmute(u8x16)a, transmute(u8x16)b)
}
_mm_avg_epu16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pavgw(transmute(u16x8)a, transmute(u16x8)b)
}

_mm_madd_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pmaddwd(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_max_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pmaxsw(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_max_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pmaxub(transmute(u8x16)a, transmute(u8x16)b)
}
_mm_min_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pminsw(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_min_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	return transmute(__m128i)pminub(transmute(u8x16)a, transmute(u8x16)b)
}


_mm_mulhi_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmulhw(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_mulhi_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmulhuw(transmute(u16x8)a, transmute(u16x8)b)
}
_mm_mullo_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.mul(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_mul_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmuludq(transmute(u32x4)a, transmute(u32x4)b)
}
_mm_sad_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)psadbw(transmute(u8x16)a, transmute(u8x16)b)
}
_mm_sub_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_sub_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_sub_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i32x4)a, transmute(i32x4)b)
}
_mm_sub_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(i64x2)a, transmute(i64x2)b)
}
_mm_subs_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_subs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_subs_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(u8x16)a, transmute(u8x16)b)
}
_mm_subs_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub_sat(transmute(u16x8)a, transmute(u16x8)b)
}



@(private)
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


_mm_slli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_slli_si128_impl(a, IMM8)
}
_mm_bslli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_slli_si128_impl(a, IMM8)
}


_mm_bsrli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_srli_si128_impl(a, IMM8)
}
_mm_slli_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)pslliw(transmute(i16x8)a, IMM8)
}
_mm_sll_epi16 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psllw(transmute(i16x8)a, transmute(i16x8)count)
}
_mm_slli_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psllid(transmute(i32x4)a, IMM8)
}
_mm_sll_epi32 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)pslld(transmute(i32x4)a, transmute(i32x4)count)
}
_mm_slli_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)pslliq(transmute(i64x2)a, IMM8)
}
_mm_sll_epi64 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psllq(transmute(i64x2)a, transmute(i64x2)count)
}
_mm_srai_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psraiw(transmute(i16x8)a. IMM8)
}
_mm_sra_epi16 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psraw(transmute(i16x8)a, transmute(i16x8)count)
}
_mm_srai_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psraid(transmute(i32x4)a, IMM8)
}
_mm_sra_epi32 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrad(transmute(i32x4)a, transmute(i32x4)count)
}


_mm_srli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return _mm_srli_si128_impl(a, IMM8)
}
_mm_srli_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psrliw(transmute(i16x8)a. IMM8)
}
_mm_srl_epi16 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrlw(transmute(i16x8)a, transmute(i16x8)count)
}
_mm_srli_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psrlid(transmute(i32x4)a, IMM8)
}
_mm_srl_epi32 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrld(transmute(i32x4)a, transmute(i32x4)count)
}
_mm_srli_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> __m128i {
	return transmute(__m128i)psrliq(transmute(i64x2)a, IMM8)
}
_mm_srl_epi64 :: #force_inline proc "c" (a, count: __m128i) -> __m128i {
	return transmute(__m128i)psrlq(transmute(i64x2)a, transmute(i64x2)count)
}


_mm_and_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.and(a, b)
}
_mm_andnot_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.and_not(b, a)
}
_mm_or_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.or(a, b)
}
_mm_xor_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.xor(a, b)
}
_mm_cmpeq_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_cmpeq_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_cmpeq_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(i32x4)a, transmute(i32x4)b)
}
_mm_cmpgt_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_cmpgt_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_cmpgt_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(i32x4)a, transmute(i32x4)b)
}
_mm_cmplt_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(i8x16)a, transmute(i8x16)b)
}
_mm_cmplt_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(i16x8)a, transmute(i16x8)b)
}
_mm_cmplt_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(i32x4)a, transmute(i32x4)b)
}


_mm_cvtepi32_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	v := transmute(i32x4)a
	return cast(__m128d)simd.shuffle(v, v, 0, 1)
}
_mm_cvtsi32_sd :: #force_inline proc "c" (a: __m128d, b: i32) -> __m128d {
	return simd.replace(a, 0, f64(b))
}
_mm_cvtepi32_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return cvtdq2ps(transmute(i32x4)a)
}
_mm_cvtps_epi32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)cvtps2dq(a)
}
_mm_cvtsi32_si128 :: #force_inline proc "c" (a: i32) -> __m128i {
	return transmute(__m128i)i32x4{a, 0, 0, 0}
}
_mm_cvtsi128_si32 :: #force_inline proc "c" (a: __m128i) -> i32 {
	return simd.extract(transmute(i32x4)a, 0)
}






_mm_castpd_ps :: #force_inline proc "c" (a: __m128d) -> __m128 {
	return transmute(__m128)a
}
_mm_castpd_si128 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)a
}
_mm_castps_pd :: #force_inline proc "c" (a: __m128) -> __m128d {
	return transmute(__m128d)a
}
_mm_castps_si128 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)a
}
_mm_castsi128_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	return transmute(__m128d)a
}
_mm_castsi128_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return transmute(__m128)a
}


_mm_undefined_pd :: #force_inline proc "c" () -> __m128d {
	return __m128d{0, 0}
}
_mm_undefined_si128 :: #force_inline proc "c" () -> __m128i {
	return __m128i{0, 0}
}
_mm_unpackhi_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(a, b, 1, 3)
}
_mm_unpacklo_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(a, b, 0, 2)
}


@(default_calling_convention="c")
@(private)
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
	packsswb   :: proc(a: i16x8, b: i16x8) -> i8x16 ---
	@(link_name="llvm.x86.sse2.packssdw.128")
	packssdw   :: proc(a: i32x4, b: i32x4) -> i16x8 ---
	@(link_name="llvm.x86.sse2.packuswb.128")
	packuswb   :: proc(a: i16x8, b: i16x8) -> u8x16 ---
	@(link_name="llvm.x86.sse2.pmovmskb.128")
	pmovmskb   :: proc(a: i8x16) -> i32 ---
	@(link_name="llvm.x86.sse2.max.sd")
	maxsd      :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.max.pd")
	maxpd      :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.min.sd")
	minsd      :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.min.pd")
	minpd      :: proc(a: __m128d, b: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.sqrt.sd")
	sqrtsd     :: proc(a: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.sqrt.pd")
	sqrtpd     :: proc(a: __m128d) -> __m128d ---
	@(link_name="llvm.x86.sse2.cmp.sd")
	cmpsd      :: proc(a: __m128d, b: __m128d, imm8: i8) -> __m128d ---
	@(link_name="llvm.x86.sse2.cmp.pd")
	cmppd      :: proc(a: __m128d, b: __m128d, imm8: i8) -> __m128d ---
	@(link_name="llvm.x86.sse2.comieq.sd")
	comieqsd   :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comilt.sd")
	comiltsd   :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comile.sd")
	comilesd   :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comigt.sd")
	comigtsd   :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comige.sd")
	comigesd   :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.comineq.sd")
	comineqsd  :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomieq.sd")
	ucomieqsd  :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomilt.sd")
	ucomiltsd  :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomile.sd")
	ucomilesd  :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomigt.sd")
	ucomigtsd  :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomige.sd")
	ucomigesd  :: proc(a: __m128d, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.ucomineq.sd")
	ucomineqsd :: proc(a: __m128d, b: __m128d) -> i32 ---
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
	cvtsd2ss   :: proc(a: __m128, b: __m128d) -> __m128 ---
	@(link_name="llvm.x86.sse2.cvtss2sd")
	cvtss2sd   :: proc(a: __m128d, b: __m128) -> __m128d ---
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
}
