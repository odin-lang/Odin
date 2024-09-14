#+build i386, amd64
package simd_x86

import "base:intrinsics"
import "core:simd"

// _MM_SHUFFLE(z, y, x, w) -> (z<<6 | y<<4 | x<<2 | w)
_MM_SHUFFLE :: intrinsics.simd_x86__MM_SHUFFLE

_MM_HINT_T0  :: 3
_MM_HINT_T1  :: 2
_MM_HINT_T2  :: 1
_MM_HINT_NTA :: 0
_MM_HINT_ET0 :: 7
_MM_HINT_ET1 :: 6


_MM_EXCEPT_INVALID    :: 0x0001
_MM_EXCEPT_DENORM     :: 0x0002
_MM_EXCEPT_DIV_ZERO   :: 0x0004
_MM_EXCEPT_OVERFLOW   :: 0x0008
_MM_EXCEPT_UNDERFLOW  :: 0x0010
_MM_EXCEPT_INEXACT    :: 0x0020
_MM_EXCEPT_MASK       :: 0x003f

_MM_MASK_INVALID      :: 0x0080
_MM_MASK_DENORM       :: 0x0100
_MM_MASK_DIV_ZERO     :: 0x0200
_MM_MASK_OVERFLOW     :: 0x0400
_MM_MASK_UNDERFLOW    :: 0x0800
_MM_MASK_INEXACT      :: 0x1000
_MM_MASK_MASK         :: 0x1f80

_MM_ROUND_NEAREST     :: 0x0000
_MM_ROUND_DOWN        :: 0x2000
_MM_ROUND_UP          :: 0x4000
_MM_ROUND_TOWARD_ZERO :: 0x6000

_MM_ROUND_MASK        :: 0x6000

_MM_FLUSH_ZERO_MASK   :: 0x8000
_MM_FLUSH_ZERO_ON     :: 0x8000
_MM_FLUSH_ZERO_OFF    :: 0x0000


@(require_results, enable_target_feature="sse")
_mm_add_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return addss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_add_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.add(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_sub_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return subss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_sub_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.sub(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_mul_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return mulss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_mul_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.mul(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_div_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return divss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_div_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.div(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_sqrt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return sqrtss(a)
}
@(require_results, enable_target_feature="sse")
_mm_sqrt_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return sqrtps(a)
}

@(require_results, enable_target_feature="sse")
_mm_rcp_ss :: #force_inline proc "c" (a: __m128) -> __m128 {
	return rcpss(a)
}
@(require_results, enable_target_feature="sse")
_mm_rcp_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return rcpps(a)
}

@(require_results, enable_target_feature="sse")
_mm_rsqrt_ss :: #force_inline proc "c" (a: __m128) -> __m128 {
	return rsqrtss(a)
}
@(require_results, enable_target_feature="sse")
_mm_rsqrt_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return rsqrtps(a)
}

@(require_results, enable_target_feature="sse")
_mm_min_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return minss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_min_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return minps(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_max_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return maxss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_max_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return maxps(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_and_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_and(transmute(__m128i)a, transmute(__m128i)b)
}
@(require_results, enable_target_feature="sse")
_mm_andnot_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_and_not(transmute(__m128i)a, transmute(__m128i)b)
}
@(require_results, enable_target_feature="sse")
_mm_or_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_or(transmute(__m128i)a, transmute(__m128i)b)
}
@(require_results, enable_target_feature="sse")
_mm_xor_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_xor(transmute(__m128i)a, transmute(__m128i)b)
}


@(require_results, enable_target_feature="sse")
_mm_cmpeq_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 0)
}
@(require_results, enable_target_feature="sse")
_mm_cmplt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 1)
}
@(require_results, enable_target_feature="sse")
_mm_cmple_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 2)
}
@(require_results, enable_target_feature="sse")
_mm_cmpgt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, cmpss(b, a, 1), 4, 1, 2, 3)
}
@(require_results, enable_target_feature="sse")
_mm_cmpge_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, cmpss(b, a, 2), 4, 1, 2, 3)
}
@(require_results, enable_target_feature="sse")
_mm_cmpneq_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 4)
}
@(require_results, enable_target_feature="sse")
_mm_cmpnlt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 5)
}
@(require_results, enable_target_feature="sse")
_mm_cmpnle_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 6)
}
@(require_results, enable_target_feature="sse")
_mm_cmpngt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, cmpss(b, a, 5), 4, 1, 2, 3)
}
@(require_results, enable_target_feature="sse")
_mm_cmpnge_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, cmpss(b, a, 6), 4, 1, 2, 3)
}
@(require_results, enable_target_feature="sse")
_mm_cmpord_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 7)
}
@(require_results, enable_target_feature="sse")
_mm_cmpunord_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpss(a, b, 3)
}


@(require_results, enable_target_feature="sse")
_mm_cmpeq_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(a, b, 0)
}
@(require_results, enable_target_feature="sse")
_mm_cmplt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(a, b, 1)
}
@(require_results, enable_target_feature="sse")
_mm_cmple_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(a, b, 2)
}
@(require_results, enable_target_feature="sse")
_mm_cmpgt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(b, a, 1)
}
@(require_results, enable_target_feature="sse")
_mm_cmpge_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(b, a, 2)
}
@(require_results, enable_target_feature="sse")
_mm_cmpneq_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(a, b, 4)
}
@(require_results, enable_target_feature="sse")
_mm_cmpnlt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(a, b, 5)
}
@(require_results, enable_target_feature="sse")
_mm_cmpnle_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(a, b, 6)
}
@(require_results, enable_target_feature="sse")
_mm_cmpngt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(b, a, 5)
}
@(require_results, enable_target_feature="sse")
_mm_cmpnge_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(b, a, 6)
}
@(require_results, enable_target_feature="sse")
_mm_cmpord_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(b, a, 7)
}
@(require_results, enable_target_feature="sse")
_mm_cmpunord_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return cmpps(b, a, 3)
}


@(require_results, enable_target_feature="sse")
_mm_comieq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return comieq_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_comilt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return comilt_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_comile_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return comile_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_comigt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return comigt_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_comige_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return comige_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_comineq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return comineq_ss(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_ucomieq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return ucomieq_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_ucomilt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return ucomilt_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_ucomile_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return ucomile_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_ucomigt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return ucomigt_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_ucomige_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return ucomige_ss(a, b)
}
@(require_results, enable_target_feature="sse")
_mm_ucomineq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return ucomineq_ss(a, b)
}

@(require_results, enable_target_feature="sse")
_mm_cvtss_si32 :: #force_inline proc "c" (a: __m128) -> i32 {
	return cvtss2si(a)
}
_mm_cvt_ss2si :: _mm_cvtss_si32
_mm_cvttss_si32 :: _mm_cvtss_si32

@(require_results, enable_target_feature="sse")
_mm_cvtss_f32 :: #force_inline proc "c" (a: __m128) -> f32 {
	return simd.extract(a, 0)
}

@(require_results, enable_target_feature="sse")
_mm_cvtsi32_ss :: #force_inline proc "c" (a: __m128, b: i32) -> __m128 {
	return cvtsi2ss(a, b)
}
_mm_cvt_si2ss :: _mm_cvtsi32_ss


@(require_results, enable_target_feature="sse")
_mm_set_ss :: #force_inline proc "c" (a: f32) -> __m128 {
	return __m128{a, 0, 0, 0}
}
@(require_results, enable_target_feature="sse")
_mm_set1_ps :: #force_inline proc "c" (a: f32) -> __m128 {
	return __m128(a)
}
_mm_set_ps1 :: _mm_set1_ps

@(require_results, enable_target_feature="sse")
_mm_set_ps :: #force_inline proc "c" (a, b, c, d: f32) -> __m128 {
	return __m128{d, c, b, a}
}
@(require_results, enable_target_feature="sse")
_mm_setr_ps :: #force_inline proc "c" (a, b, c, d: f32) -> __m128 {
	return __m128{a, b, c, d}
}

@(require_results, enable_target_feature="sse")
_mm_setzero_ps :: #force_inline proc "c" () -> __m128 {
	return __m128{0, 0, 0, 0}
}

@(require_results, enable_target_feature="sse")
_mm_shuffle_ps :: #force_inline proc "c" (a, b: __m128, $MASK: u32) -> __m128 {
	return simd.shuffle(
		a, b,
		u32(MASK) & 0b11,
		(u32(MASK)>>2) & 0b11,
		((u32(MASK)>>4) & 0b11)+4,
		((u32(MASK)>>6) & 0b11)+4)
}


@(require_results, enable_target_feature="sse")
_mm_unpackhi_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 2, 6, 3, 7)
}
@(require_results, enable_target_feature="sse")
_mm_unpacklo_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 0, 4, 1, 5)
}

@(require_results, enable_target_feature="sse")
_mm_movehl_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 6, 7, 2, 3)
}
@(require_results, enable_target_feature="sse")
_mm_movelh_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 0, 1, 4, 5)
}

@(require_results, enable_target_feature="sse")
_mm_movemask_ps :: #force_inline proc "c" (a: __m128) -> u32 {
	return movmskps(a)
}

@(require_results, enable_target_feature="sse")
_mm_load_ss :: #force_inline proc "c" (p: ^f32) -> __m128 {
	return __m128{p^, 0, 0, 0}
}
@(require_results, enable_target_feature="sse")
_mm_load1_ps :: #force_inline proc "c" (p: ^f32) -> __m128 {
	a := p^
	return __m128(a)
}
_mm_load_ps1 :: _mm_load1_ps

@(require_results, enable_target_feature="sse")
_mm_load_ps :: #force_inline proc "c" (p: [^]f32) -> __m128 {
	return (^__m128)(p)^
}

@(require_results, enable_target_feature="sse")
_mm_loadu_ps :: #force_inline proc "c" (p: [^]f32) -> __m128 {
	dst := _mm_undefined_ps()
	intrinsics.mem_copy_non_overlapping(&dst, p, size_of(__m128))
	return dst
}

@(require_results, enable_target_feature="sse")
_mm_loadr_ps :: #force_inline proc "c" (p: [^]f32) -> __m128 {
	return simd.lanes_reverse(_mm_load_ps(p))
}

@(require_results, enable_target_feature="sse")
_mm_loadu_si64 :: #force_inline proc "c" (mem_addr: rawptr) -> __m128i {
	a := intrinsics.unaligned_load((^i64)(mem_addr))
	return __m128i{a, 0}
}

@(enable_target_feature="sse")
_mm_store_ss :: #force_inline proc "c" (p: ^f32, a: __m128) {
	p^ = simd.extract(a, 0)
}

@(enable_target_feature="sse")
_mm_store1_ps :: #force_inline proc "c" (p: [^]f32, a: __m128) {
	b := simd.swizzle(a, 0, 0, 0, 0)
	(^__m128)(p)^ = b
}
_mm_store_ps1 :: _mm_store1_ps


@(enable_target_feature="sse")
_mm_store_ps :: #force_inline proc "c" (p: [^]f32, a: __m128) {
	(^__m128)(p)^ = a
}
@(enable_target_feature="sse")
_mm_storeu_ps :: #force_inline proc "c" (p: [^]f32, a: __m128) {
	b := a
	intrinsics.mem_copy_non_overlapping(p, &b, size_of(__m128))
}
@(enable_target_feature="sse")
_mm_storer_ps :: #force_inline proc "c" (p: [^]f32, a: __m128) {
	(^__m128)(p)^ = simd.lanes_reverse(a)
}


@(require_results, enable_target_feature="sse")
_mm_move_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 4, 1, 2, 3)
}

@(enable_target_feature="sse")
_mm_sfence :: #force_inline proc "c" () {
	sfence()
}

@(require_results, enable_target_feature="sse")
_mm_getcsr :: #force_inline proc "c" () -> (result: u32) {
	stmxcsr(&result)
	return result
}

@(enable_target_feature="sse")
_mm_setcsr :: #force_inline proc "c" (val: u32) {
	val := val
	ldmxcsr(&val)
}

@(require_results, enable_target_feature="sse")
_MM_GET_EXCEPTION_MASK :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_MASK_MASK
}
@(require_results, enable_target_feature="sse")
_MM_GET_EXCEPTION_STATE :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_EXCEPT_MASK
}
@(require_results, enable_target_feature="sse")
_MM_GET_FLUSH_ZERO_MODE :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_FLUSH_ZERO_MASK
}
@(require_results, enable_target_feature="sse")
_MM_GET_ROUNDING_MODE :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_ROUND_MASK
}

@(enable_target_feature="sse")
_MM_SET_EXCEPTION_MASK :: #force_inline proc "c" (x: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_MASK_MASK) | x)
}
@(enable_target_feature="sse")
_MM_SET_EXCEPTION_STATE :: #force_inline proc "c" (x: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_EXCEPT_MASK) | x)
}
@(enable_target_feature="sse")
_MM_SET_FLUSH_ZERO_MODE :: #force_inline proc "c" (x: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_FLUSH_ZERO_MASK) | x)
}
@(enable_target_feature="sse")
_MM_SET_ROUNDING_MODE :: #force_inline proc "c" (x: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_ROUND_MASK) | x)
}

@(enable_target_feature="sse")
_mm_prefetch :: #force_inline proc "c" (p: rawptr, $STRATEGY: u32) {
	prefetch(p, (STRATEGY>>2)&1, STRATEGY&3, 1)
}


@(require_results, enable_target_feature="sse")
_mm_undefined_ps :: #force_inline proc "c" () -> __m128 {
	return _mm_set1_ps(0)
}

@(enable_target_feature="sse")
_MM_TRANSPOSE4_PS :: #force_inline proc "c" (row0, row1, row2, row3: ^__m128) {
	tmp0 := _mm_unpacklo_ps(row0^, row1^)
	tmp1 := _mm_unpacklo_ps(row2^, row3^)
	tmp2 := _mm_unpackhi_ps(row0^, row1^)
	tmp3 := _mm_unpackhi_ps(row2^, row3^)

	row0^ = _mm_movelh_ps(tmp0, tmp2)
	row1^ = _mm_movelh_ps(tmp2, tmp0)
	row2^ = _mm_movelh_ps(tmp1, tmp3)
	row3^ = _mm_movelh_ps(tmp3, tmp1)
}

@(enable_target_feature="sse")
_mm_stream_ps :: #force_inline proc "c" (addr: [^]f32, a: __m128) {
	intrinsics.non_temporal_store((^__m128)(addr), a)
}

when ODIN_ARCH == .amd64 {
	@(require_results, enable_target_feature="sse")
	_mm_cvtss_si64 :: #force_inline proc "c"(a: __m128) -> i64 {
		return cvtss2si64(a)
	}
	@(require_results, enable_target_feature="sse")
	_mm_cvttss_si64 :: #force_inline proc "c"(a: __m128) -> i64 {
		return cvttss2si64(a)
	}
	@(require_results, enable_target_feature="sse")
	_mm_cvtsi64_ss :: #force_inline proc "c"(a: __m128, b: i64) -> __m128 {
		return cvtsi642ss(a, b)
	}
}


@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse.add.ss")
	addss       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.sub.ss")
	subss       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.mul.ss")
	mulss       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.div.ss")
	divss       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.sqrt.ss")
	sqrtss      :: proc(a: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.sqrt.ps")
	sqrtps      :: proc(a: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.rcp.ss")
	rcpss       :: proc(a: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.rcp.ps")
	rcpps       :: proc(a: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.rsqrt.ss")
	rsqrtss     :: proc(a: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.rsqrt.ps")
	rsqrtps     :: proc(a: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.min.ss")
	minss       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.min.ps")
	minps       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.max.ss")
	maxss       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.max.ps")
	maxps       :: proc(a, b: __m128) -> __m128 ---
	@(link_name="llvm.x86.sse.movmsk.ps")
	movmskps    :: proc(a: __m128) -> u32 ---
	@(link_name="llvm.x86.sse.cmp.ps")
	cmpps       :: proc(a, b: __m128, #const imm8: u8) -> __m128 ---
	@(link_name="llvm.x86.sse.comieq.ss")
	comieq_ss   :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.comilt.ss")
	comilt_ss   :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.comile.ss")
	comile_ss   :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.comigt.ss")
	comigt_ss   :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.comige.ss")
	comige_ss   :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.comineq.ss")
	comineq_ss  :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.ucomieq.ss")
	ucomieq_ss  :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.ucomilt.ss")
	ucomilt_ss  :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.ucomile.ss")
	ucomile_ss  :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.ucomigt.ss")
	ucomigt_ss  :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.ucomige.ss")
	ucomige_ss  :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.ucomineq.ss")
	ucomineq_ss :: proc(a, b: __m128) -> b32 ---
	@(link_name="llvm.x86.sse.cvtss2si")
	cvtss2si    :: proc(a: __m128) -> i32 ---
	@(link_name="llvm.x86.sse.cvttss2si")
	cvttss2si   :: proc(a: __m128) -> i32 ---
	@(link_name="llvm.x86.sse.cvtsi2ss")
	cvtsi2ss    :: proc(a: __m128, b: i32) -> __m128 ---
	@(link_name="llvm.x86.sse.sfence")
	sfence      :: proc() ---
	@(link_name="llvm.x86.sse.stmxcsr")
	stmxcsr     :: proc(p: rawptr) ---
	@(link_name="llvm.x86.sse.ldmxcsr")
	ldmxcsr     :: proc(p: rawptr) ---
	@(link_name="llvm.prefetch")
	prefetch    :: proc(p: rawptr, #const rw, loc, ty: u32) ---
	@(link_name="llvm.x86.sse.cmp.ss")
	cmpss       :: proc(a, b: __m128, #const imm8: u8) -> __m128 ---


	// amd64 only
	@(link_name="llvm.x86.sse.cvtss2si64")
	cvtss2si64  :: proc(a: __m128) -> i64 ---
	@(link_name="llvm.x86.sse.cvttss2si64")
	cvttss2si64 :: proc(a: __m128) -> i64 ---
	@(link_name="llvm.x86.sse.cvtsi642ss")
	cvtsi642ss  :: proc(a: __m128, b: i64) -> __m128 ---
}
