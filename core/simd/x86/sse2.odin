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
	x := transmute(simd.i8x16)a
	y := transmute(simd.i8x16)b
	return transmute(__m128i)simd.add(x, y)
}
_mm_add_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i16x8)a
	y := transmute(simd.i16x8)b
	return transmute(__m128i)simd.add(x, y)
}
_mm_add_epi32 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i32x4)a
	y := transmute(simd.i32x4)b
	return transmute(__m128i)simd.add(x, y)
}
_mm_add_epi64 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i64x2)a
	y := transmute(simd.i64x2)b
	return transmute(__m128i)simd.add(x, y)
}
_mm_adds_epi8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i8x16)a
	y := transmute(simd.i8x16)b
	return transmute(__m128i)simd.add_sat(x, y)
}
_mm_adds_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i16x8)a
	y := transmute(simd.i16x8)b
	return transmute(__m128i)simd.add_sat(x, y)
}
_mm_adds_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.u8x16)a
	y := transmute(simd.u8x16)b
	return transmute(__m128i)simd.add_sat(x, y)
}
_mm_adds_epu16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.u16x8)a
	y := transmute(simd.u16x8)b
	return transmute(__m128i)simd.add_sat(x, y)
}
_mm_avg_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.u8x16)a
	y := transmute(simd.u8x16)b
	return transmute(__m128i)pavgb(x, y)
}
_mm_avg_epu16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.u16x8)a
	y := transmute(simd.u16x8)b
	return transmute(__m128i)pavgw(x, y)
}

_mm_madd_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i16x8)a
	y := transmute(simd.i16x8)b
	return transmute(__m128i)pmaddwd(x, y)
}
_mm_max_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i16x8)a
	y := transmute(simd.i16x8)b
	return transmute(__m128i)pmaxsw(x, y)
}
_mm_max_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.u8x16)a
	y := transmute(simd.u8x16)b
	return transmute(__m128i)pmaxub(x, y)
}
_mm_min_epi16 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.i16x8)a
	y := transmute(simd.i16x8)b
	return transmute(__m128i)pminsw(x, y)
}
_mm_min_epu8 :: #force_inline proc "c" (a, b: __m128i)  -> __m128i {
	x := transmute(simd.u8x16)a
	y := transmute(simd.u8x16)b
	return transmute(__m128i)pminub(x, y)
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
	pavgb      :: proc(a, b: simd.u8x16) -> simd.u8x16 ---
	@(link_name="llvm.x86.sse2.pavg.w")
	pavgw      :: proc(a, b: simd.u16x8) -> simd.u16x8 ---
	@(link_name="llvm.x86.sse2.pmadd.wd")
	pmaddwd    :: proc(a, b: simd.i16x8) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.pmaxs.w")
	pmaxsw     :: proc(a, b: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.pmaxu.b")
	pmaxub     :: proc(a, b: simd.u8x16) -> simd.u8x16 ---
	@(link_name="llvm.x86.sse2.pmins.w")
	pminsw     :: proc(a, b: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.pminu.b")
	pminub     :: proc(a, b: simd.u8x16) -> simd.u8x16 ---
	@(link_name="llvm.x86.sse2.pmulh.w")
	pmulhw     :: proc(a, b: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.pmulhu.w")
	pmulhuw    :: proc(a, b: simd.u16x8) -> simd.u16x8 ---
	@(link_name="llvm.x86.sse2.pmulu.dq")
	pmuludq    :: proc(a, b: simd.u32x4) -> simd.u64x2 ---
	@(link_name="llvm.x86.sse2.psad.bw")
	psadbw     :: proc(a, b: simd.u8x16) -> simd.u64x2 ---
	@(link_name="llvm.x86.sse2.pslli.w")
	pslliw     :: proc(a: simd.i16x8, #const imm8: u32) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psll.w")
	psllw      :: proc(a: simd.i16x8, count: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.pslli.d")
	psllid     :: proc(a: simd.i32x4, #const imm8: u32) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psll.d")
	pslld      :: proc(a: simd.i32x4, count: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.pslli.q")
	pslliq     :: proc(a: simd.i64x2, #const imm8: u32) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse2.psll.q")
	psllq      :: proc(a: simd.i64x2, count: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse2.psrai.w")
	psraiw     :: proc(a: simd.i16x8, #const imm8: u32) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psra.w")
	psraw      :: proc(a: simd.i16x8, count: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psrai.d")
	psraid     :: proc(a: simd.i32x4, #const imm8: u32) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psra.d")
	psrad      :: proc(a: simd.i32x4, count: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psrli.w")
	psrliw     :: proc(a: simd.i16x8, #const imm8: u32) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psrl.w")
	psrlw      :: proc(a: simd.i16x8, count: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psrli.d")
	psrlid     :: proc(a: simd.i32x4, #const imm8: u32) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psrl.d")
	psrld      :: proc(a: simd.i32x4, count: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psrli.q")
	psrliq     :: proc(a: simd.i64x2, #const imm8: u32) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse2.psrl.q")
	psrlq      :: proc(a: simd.i64x2, count: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse2.cvtdq2ps")
	cvtdq2ps   :: proc(a: simd.i32x4) -> __m128 ---
	@(link_name="llvm.x86.sse2.cvtps2dq")
	cvtps2dq   :: proc(a: __m128) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.maskmov.dqu")
	maskmovdqu :: proc(a: simd.i8x16, mask: simd.i8x16, mem_addr: rawptr) ---
	@(link_name="llvm.x86.sse2.packsswb.128")
	packsswb   :: proc(a: simd.i16x8, b: simd.i16x8) -> simd.i8x16 ---
	@(link_name="llvm.x86.sse2.packssdw.128")
	packssdw   :: proc(a: simd.i32x4, b: simd.i32x4) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.packuswb.128")
	packuswb   :: proc(a: simd.i16x8, b: simd.i16x8) -> simd.u8x16 ---
	@(link_name="llvm.x86.sse2.pmovmskb.128")
	pmovmskb   :: proc(a: simd.i8x16) -> i32 ---
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
	cvtpd2dq   :: proc(a: __m128d) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.cvtsd2si")
	cvtsd2si   :: proc(a: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.cvtsd2ss")
	cvtsd2ss   :: proc(a: __m128, b: __m128d) -> __m128 ---
	@(link_name="llvm.x86.sse2.cvtss2sd")
	cvtss2sd   :: proc(a: __m128d, b: __m128) -> __m128d ---
	@(link_name="llvm.x86.sse2.cvttpd2dq")
	cvttpd2dq  :: proc(a: __m128d) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.cvttsd2si")
	cvttsd2si  :: proc(a: __m128d) -> i32 ---
	@(link_name="llvm.x86.sse2.cvttps2dq")
	cvttps2dq  :: proc(a: __m128) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.storeu.dq")
	storeudq   :: proc(mem_addr: rawptr, a: __m128i) ---
	@(link_name="llvm.x86.sse2.storeu.pd")
	storeupd   :: proc(mem_addr: rawptr, a: __m128d) ---
}
