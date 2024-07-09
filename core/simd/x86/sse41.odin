//+build i386, amd64
package simd_x86

import "core:simd"

// SSE4 rounding constants
_MM_FROUND_TO_NEAREST_INT :: 0x00
_MM_FROUND_TO_NEG_INF     :: 0x01
_MM_FROUND_TO_POS_INF     :: 0x02
_MM_FROUND_TO_ZERO        :: 0x03
_MM_FROUND_CUR_DIRECTION  :: 0x04
_MM_FROUND_RAISE_EXC      :: 0x00
_MM_FROUND_NO_EXC         :: 0x08
_MM_FROUND_NINT           :: 0x00
_MM_FROUND_FLOOR          :: _MM_FROUND_RAISE_EXC | _MM_FROUND_TO_NEG_INF
_MM_FROUND_CEIL           :: _MM_FROUND_RAISE_EXC | _MM_FROUND_TO_POS_INF
_MM_FROUND_TRUNC          :: _MM_FROUND_RAISE_EXC | _MM_FROUND_TO_ZERO
_MM_FROUND_RINT           :: _MM_FROUND_RAISE_EXC | _MM_FROUND_CUR_DIRECTION
_MM_FROUND_NEARBYINT      :: _MM_FROUND_NO_EXC | _MM_FROUND_CUR_DIRECTION



@(require_results, enable_target_feature="sse4.1")
_mm_blendv_epi8 :: #force_inline proc "c" (a, b, mask: __m128i) -> __m128i {
	return transmute(__m128i)pblendvb(transmute(i8x16)a, transmute(i8x16)b, transmute(i8x16)mask)
}
@(require_results, enable_target_feature="sse4.1")
_mm_blend_epi16 :: #force_inline proc "c" (a, b: __m128i, $IMM8: u8) -> __m128i {
	return transmute(__m128i)pblendw(transmute(i16x8)a, transmute(i16x8)b, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_blendv_pd :: #force_inline proc "c" (a, b, mask: __m128d) -> __m128d {
	return blendvpd(a, b, mask)
}
@(require_results, enable_target_feature="sse4.1")
_mm_blendv_ps :: #force_inline proc "c" (a, b, mask: __m128) -> __m128 {
	return blendvps(a, b, mask)
}
@(require_results, enable_target_feature="sse4.1")
_mm_blend_pd :: #force_inline proc "c" (a, b: __m128d, $IMM2: u8) -> __m128d {
	return blendpd(a, b, IMM2)
}
@(require_results, enable_target_feature="sse4.1")
_mm_blend_ps :: #force_inline proc "c" (a, b: __m128, $IMM4: u8) -> __m128 {
	return blendps(a, b, IMM4)
}
@(require_results, enable_target_feature="sse4.1")
_mm_extract_ps :: #force_inline proc "c" (a: __m128, $IMM8: u32) -> i32 {
	return transmute(i32)simd.extract(a, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_extract_epi8 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> i32 {
	return i32(simd.extract(transmute(u8x16)a, IMM8))
}
@(require_results, enable_target_feature="sse4.1")
_mm_extract_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: u32) -> i32 {
	return simd.extract(transmute(i32x4)a, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_insert_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: u8) -> __m128 {
	return insertps(a, b, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_insert_epi8 :: #force_inline proc "c" (a: __m128i, i: i32, $IMM8: u32) -> __m128i {
	return transmute(__m128i)simd.replace(transmute(i8x16)a, IMM8, i8(i))
}
@(require_results, enable_target_feature="sse4.1")
_mm_insert_epi32 :: #force_inline proc "c" (a: __m128i, i: i32, $IMM8: u32) -> __m128i {
	return transmute(__m128i)simd.replace(transmute(i32x4)a, IMM8, i)
}
@(require_results, enable_target_feature="sse4.1")
_mm_max_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmaxsb(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_max_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmaxuw(transmute(u16x8)a, transmute(u16x8)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_max_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmaxsd(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_max_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pmaxud(transmute(u32x4)a, transmute(u32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_min_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pminsb(transmute(i8x16)a, transmute(i8x16)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_min_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pminuw(transmute(u16x8)a, transmute(u16x8)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_min_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pminsd(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_min_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)pminud(transmute(u32x4)a, transmute(u32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_packus_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)packusdw(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cmpeq_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(a, b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi8_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(i8x16)a
	y := simd.shuffle(x, x, 0, 1, 2, 3, 4, 5, 6, 7)
	return transmute(__m128i)i16x8(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(i8x16)a
	y := simd.shuffle(x, x, 0, 1, 2, 3)
	return transmute(__m128i)i32x4(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(i8x16)a
	y := simd.shuffle(x, x, 0, 1)
	return i64x2(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi16_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(i16x8)a
	y := simd.shuffle(x, x, 0, 1, 2, 3)
	return transmute(__m128i)i32x4(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(i16x8)a
	y := simd.shuffle(x, x, 0, 1)
	return i64x2(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi32_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(i32x4)a
	y := simd.shuffle(x, x, 0, 1)
	return i64x2(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu8_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(u8x16)a
	y := simd.shuffle(x, x, 0, 1, 2, 3, 4, 5, 6, 7)
	return transmute(__m128i)i16x8(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(u8x16)a
	y := simd.shuffle(x, x, 0, 1, 2, 3)
	return transmute(__m128i)i32x4(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(u8x16)a
	y := simd.shuffle(x, x, 0, 1)
	return i64x2(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu16_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(u16x8)a
	y := simd.shuffle(x, x, 0, 1, 2, 3)
	return transmute(__m128i)i32x4(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(u16x8)a
	y := simd.shuffle(x, x, 0, 1)
	return i64x2(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu32_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	x := transmute(u32x4)a
	y := simd.shuffle(x, x, 0, 1)
	return i64x2(y)
}
@(require_results, enable_target_feature="sse4.1")
_mm_dp_pd :: #force_inline proc "c" (a, b: __m128d, $IMM8: u8) -> __m128d {
	return dppd(a, b, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_dp_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: u8) -> __m128 {
	return dpps(a, b, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_floor_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.floor(a)
}
@(require_results, enable_target_feature="sse4.1")
_mm_floor_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.floor(a)
}
@(require_results, enable_target_feature="sse4.1")
_mm_floor_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return roundsd(a, b, _MM_FROUND_FLOOR)
}
@(require_results, enable_target_feature="sse4.1")
_mm_floor_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return roundss(a, b, _MM_FROUND_FLOOR)
}
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.ceil(a)
}
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.ceil(a)
}
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return roundsd(a, b, _MM_FROUND_CEIL)
}
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return roundss(a, b, _MM_FROUND_CEIL)
}
@(require_results, enable_target_feature="sse4.1")
_mm_round_pd :: #force_inline proc "c" (a: __m128d, $ROUNDING: i32) -> __m128d {
	return roundpd(a, ROUNDING)
}
@(require_results, enable_target_feature="sse4.1")
_mm_round_ps :: #force_inline proc "c" (a: __m128, $ROUNDING: i32) -> __m128 {
	return roundps(a, ROUNDING)
}
@(require_results, enable_target_feature="sse4.1")
_mm_round_sd :: #force_inline proc "c" (a, b: __m128d, $ROUNDING: i32) -> __m128d {
	return roundsd(a, b, ROUNDING)
}
@(require_results, enable_target_feature="sse4.1")
_mm_round_ss :: #force_inline proc "c" (a, b: __m128, $ROUNDING: i32) -> __m128 {
	return roundss(a, b, ROUNDING)
}
@(require_results, enable_target_feature="sse4.1")
_mm_minpos_epu16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)phminposuw(transmute(u16x8)a)
}
@(require_results, enable_target_feature="sse4.1")
_mm_mul_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return pmuldq(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_mullo_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.mul(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sse4.1")
_mm_mpsadbw_epu8 :: #force_inline proc "c" (a, b: __m128i, $IMM8: u8) -> __m128i {
	return transmute(__m128i)mpsadbw(transmute(u8x16)a, transmute(u8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.1")
_mm_testz_si128 :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	return ptestz(a, mask)
}
@(require_results, enable_target_feature="sse4.1")
_mm_testc_si128 :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	return ptestc(a, mask)
}
@(require_results, enable_target_feature="sse4.1")
_mm_testnzc_si128 :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	return ptestnzc(a, mask)
}
@(require_results, enable_target_feature="sse4.1")
_mm_test_all_zeros :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	return _mm_testz_si128(a, mask)
}
@(require_results, enable_target_feature="sse2,sse4.1")
_mm_test_all_ones :: #force_inline proc "c" (a: __m128i) -> i32 {
	return _mm_testc_si128(a, _mm_cmpeq_epi32(a, a))
}
@(require_results, enable_target_feature="sse4.1")
_mm_test_mix_ones_zeros :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	return _mm_testnzc_si128(a, mask)
}


when ODIN_ARCH == .amd64 {
	@(require_results, enable_target_feature="sse4.1")
	_mm_extract_epi64 :: #force_inline proc "c" (a: __m128i, $IMM1: u32) -> i64 {
		return simd.extract(transmute(i64x2)a, IMM1)
	}

	@(require_results, enable_target_feature="sse4.1")
	_mm_insert_epi64 :: #force_inline proc "c" (a: __m128i, i: i64, $IMM1: u32) -> __m128i {
		return transmute(__m128i)simd.replace(transmute(i64x2)a, IMM1, i)
	}
}


@(private, default_calling_convention="none")
foreign _ {
	@(link_name = "llvm.x86.sse41.pblendvb")
	pblendvb   :: proc(a, b: i8x16, mask: i8x16) -> i8x16 ---
	@(link_name = "llvm.x86.sse41.blendvpd")
	blendvpd   :: proc(a, b, mask: __m128d) -> __m128d ---
	@(link_name = "llvm.x86.sse41.blendvps")
	blendvps   :: proc(a, b, mask: __m128) -> __m128 ---
	@(link_name = "llvm.x86.sse41.blendpd")
	blendpd    :: proc(a, b: __m128d, #const imm2: u8) -> __m128d ---
	@(link_name = "llvm.x86.sse41.blendps")
	blendps    :: proc(a, b: __m128, #const imm4: u8) -> __m128 ---
	@(link_name = "llvm.x86.sse41.pblendw")
	pblendw    :: proc(a: i16x8, b: i16x8, #const imm8: u8) -> i16x8 ---
	@(link_name = "llvm.x86.sse41.insertps")
	insertps   :: proc(a, b: __m128, #const imm8: u8) -> __m128 ---
	@(link_name = "llvm.x86.sse41.pmaxsb")
	pmaxsb     :: proc(a, b: i8x16) -> i8x16 ---
	@(link_name = "llvm.x86.sse41.pmaxuw")
	pmaxuw     :: proc(a, b: u16x8) -> u16x8 ---
	@(link_name = "llvm.x86.sse41.pmaxsd")
	pmaxsd     :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name = "llvm.x86.sse41.pmaxud")
	pmaxud     :: proc(a, b: u32x4) -> u32x4 ---
	@(link_name = "llvm.x86.sse41.pminsb")
	pminsb     :: proc(a, b: i8x16) -> i8x16 ---
	@(link_name = "llvm.x86.sse41.pminuw")
	pminuw     :: proc(a, b: u16x8) -> u16x8 ---
	@(link_name = "llvm.x86.sse41.pminsd")
	pminsd     :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name = "llvm.x86.sse41.pminud")
	pminud     :: proc(a, b: u32x4) -> u32x4 ---
	@(link_name = "llvm.x86.sse41.packusdw")
	packusdw   :: proc(a, b: i32x4) -> u16x8 ---
	@(link_name = "llvm.x86.sse41.dppd")
	dppd       :: proc(a, b: __m128d, #const imm8: u8) -> __m128d ---
	@(link_name = "llvm.x86.sse41.dpps")
	dpps       :: proc(a, b: __m128, #const imm8: u8) -> __m128 ---
	@(link_name = "llvm.x86.sse41.round.pd")
	roundpd    :: proc(a: __m128d, rounding: i32) -> __m128d ---
	@(link_name = "llvm.x86.sse41.round.ps")
	roundps    :: proc(a: __m128, rounding: i32) -> __m128 ---
	@(link_name = "llvm.x86.sse41.round.sd")
	roundsd    :: proc(a, b: __m128d, rounding: i32) -> __m128d ---
	@(link_name = "llvm.x86.sse41.round.ss")
	roundss    :: proc(a, b: __m128, rounding: i32) -> __m128 ---
	@(link_name = "llvm.x86.sse41.phminposuw")
	phminposuw :: proc(a: u16x8) -> u16x8 ---
	@(link_name = "llvm.x86.sse41.pmuldq")
	pmuldq     :: proc(a, b: i32x4) -> i64x2 ---
	@(link_name = "llvm.x86.sse41.mpsadbw")
	mpsadbw    :: proc(a, b: u8x16, #const imm8: u8) -> u16x8 ---
	@(link_name = "llvm.x86.sse41.ptestz")
	ptestz     :: proc(a, mask: i64x2) -> i32 ---
	@(link_name = "llvm.x86.sse41.ptestc")
	ptestc     :: proc(a, mask: i64x2) -> i32 ---
	@(link_name = "llvm.x86.sse41.ptestnzc")
	ptestnzc   :: proc(a, mask: i64x2) -> i32 ---
}
