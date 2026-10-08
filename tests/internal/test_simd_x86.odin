#+build amd64
package test_internal

import "base:intrinsics"
import "core:math"
import "core:simd"
import x86 "core:simd/x86"
import "core:sys/info"
import "core:testing"

// These wrappers used LLVM intrinsics that LLVM has since removed, so they failed to link.

@(test)
simd_x86_removed_intrinsics :: proc(t: ^testing.T) {
	required :: info.CPU_Features{.sse2, .ssse3, .sse41, .adx}
	if !(info.cpu_features() >= required) {
		return
	}
	simd_x86_removed_intrinsics_sse(t)
}

@(private="file", enable_target_feature="sse,sse2,ssse3,sse4.1,adx")
simd_x86_removed_intrinsics_sse :: proc(t: ^testing.T) {
	f4 :: proc "contextless" (v: x86.__m128) -> [4]f32 { return transmute([4]f32)v }
	d2 :: proc "contextless" (v: x86.__m128d) -> [2]f64 { return transmute([2]f64)v }

	a := x86.__m128{1, 2, 3, 4}
	b := x86.__m128{10, 20, 30, 40}
	testing.expect_value(t, f4(x86._mm_add_ss(a, b)), [4]f32{11, 2, 3, 4})
	testing.expect_value(t, f4(x86._mm_sub_ss(a, b)), [4]f32{-9, 2, 3, 4})
	testing.expect_value(t, f4(x86._mm_mul_ss(a, b)), [4]f32{10, 2, 3, 4})
	testing.expect_value(t, f4(x86._mm_div_ss(b, a)), [4]f32{10, 20, 30, 40})
	testing.expect_value(t, f4(x86._mm_sqrt_ss(x86.__m128{16, -1, 9, 4})), [4]f32{4, -1, 9, 4})
	testing.expect_value(t, f4(x86._mm_cvtsi32_ss(a, -7)), [4]f32{-7, 2, 3, 4})
	testing.expect_value(t, f4(x86._mm_cvtsi64_ss(a, 1 << 40)), [4]f32{1 << 40, 2, 3, 4})
	testing.expect_value(t, f4(x86._mm_cvtepi32_ps(transmute(x86.__m128i)simd.i32x4{-1, 0, 16777217, max(i32)})), [4]f32{-1, 0, 16777216, 2147483648})

	sq := f4(x86._mm_sqrt_ps(x86.__m128{16, 4, -1, 0}))
	testing.expect_value(t, sq[0], 4)
	testing.expect_value(t, sq[1], 2)
	testing.expect(t, math.is_nan(sq[2]))
	testing.expect_value(t, sq[3], 0)

	testing.expect_value(t, d2(x86._mm_sqrt_sd(x86.__m128d{1, 7}, x86.__m128d{9, 100})), [2]f64{3, 7})
	sqd := d2(x86._mm_sqrt_pd(x86.__m128d{4, -1}))
	testing.expect_value(t, sqd[0], 2)
	testing.expect(t, math.is_nan(sqd[1]))
	testing.expect_value(t, d2(x86._mm_cvtps_pd(x86.__m128{1.5, -2, 3, 4})), [2]f64{1.5, -2})

	buf: [17]u8
	x86._mm_storeu_pd((^f64)(&buf[1]), x86.__m128d{1.25, -8})
	testing.expect_value(t, intrinsics.unaligned_load((^[2]f64)(&buf[1])), [2]f64{1.25, -8})

	testing.expect_value(t, d2(x86._mm_blend_pd(x86.__m128d{1, 2}, x86.__m128d{3, 4}, 0b10)), [2]f64{1, 4})
	testing.expect_value(t, d2(x86._mm_blend_pd(x86.__m128d{1, 2}, x86.__m128d{3, 4}, 0b01)), [2]f64{3, 2})
	testing.expect_value(t, f4(x86._mm_blend_ps(a, b, 0b0101)), [4]f32{10, 2, 30, 4})
	testing.expect_value(t, f4(x86._mm_blend_ps(a, b, 0b1010)), [4]f32{1, 20, 3, 40})

	// Signed and unsigned comparisons must differ on the same bits.
	b8 :: proc "contextless" (v: x86.__m128i) -> [4]u8 { a := transmute([16]u8)v; return {a[0], a[1], a[2], a[3]} }
	x8 := transmute(x86.__m128i)[16]u8{0x80, 0x7f, 0xff, 0x00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	y8 := transmute(x86.__m128i)[16]u8{0x7f, 0x80, 0x01, 0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	testing.expect_value(t, b8(x86._mm_max_epi8(x8, y8)), [4]u8{0x7f, 0x7f, 0x01, 0x00})
	testing.expect_value(t, b8(x86._mm_min_epi8(x8, y8)), [4]u8{0x80, 0x80, 0xff, 0xff})
	testing.expect_value(t, b8(x86._mm_max_epu8(x8, y8)), [4]u8{0x80, 0x80, 0xff, 0xff})
	testing.expect_value(t, b8(x86._mm_min_epu8(x8, y8)), [4]u8{0x7f, 0x7f, 0x01, 0x00})

	w8 :: proc "contextless" (v: x86.__m128i) -> [8]u16 { return transmute([8]u16)v }
	x16 := transmute(x86.__m128i)[8]u16{0x8000, 0x7fff, 0xffff, 0, 5, 0, 0, 0}
	y16 := transmute(x86.__m128i)[8]u16{0x7fff, 0x8000, 0x0001, 0xffff, 6, 0, 0, 0}
	testing.expect_value(t, w8(x86._mm_max_epi16(x16, y16)), [8]u16{0x7fff, 0x7fff, 0x0001, 0, 6, 0, 0, 0})
	testing.expect_value(t, w8(x86._mm_min_epi16(x16, y16)), [8]u16{0x8000, 0x8000, 0xffff, 0xffff, 5, 0, 0, 0})
	testing.expect_value(t, w8(x86._mm_max_epu16(x16, y16)), [8]u16{0x8000, 0x8000, 0xffff, 0xffff, 6, 0, 0, 0})
	testing.expect_value(t, w8(x86._mm_min_epu16(x16, y16)), [8]u16{0x7fff, 0x7fff, 0x0001, 0, 5, 0, 0, 0})

	d4 :: proc "contextless" (v: x86.__m128i) -> [4]u32 { return transmute([4]u32)v }
	x32 := transmute(x86.__m128i)[4]u32{0x8000_0000, 0x7fff_ffff, 0xffff_ffff, 0}
	y32 := transmute(x86.__m128i)[4]u32{0x7fff_ffff, 0x8000_0000, 0x0000_0001, 0xffff_ffff}
	testing.expect_value(t, d4(x86._mm_max_epi32(x32, y32)), [4]u32{0x7fff_ffff, 0x7fff_ffff, 1, 0})
	testing.expect_value(t, d4(x86._mm_min_epi32(x32, y32)), [4]u32{0x8000_0000, 0x8000_0000, 0xffff_ffff, 0xffff_ffff})
	testing.expect_value(t, d4(x86._mm_max_epu32(x32, y32)), [4]u32{0x8000_0000, 0x8000_0000, 0xffff_ffff, 0xffff_ffff})
	testing.expect_value(t, d4(x86._mm_min_epu32(x32, y32)), [4]u32{0x7fff_ffff, 0x7fff_ffff, 1, 0})

	// abs of the minimum value wraps to itself.
	testing.expect_value(t, b8(x86._mm_abs_epi8(x8)), [4]u8{0x80, 0x7f, 0x01, 0x00})
	testing.expect_value(t, w8(x86._mm_abs_epi16(x16)), [8]u16{0x8000, 0x7fff, 0x0001, 0, 5, 0, 0, 0})
	testing.expect_value(t, d4(x86._mm_abs_epi32(x32)), [4]u32{0x8000_0000, 0x7fff_ffff, 1, 0})

	// Only the low 32 bits of each 64-bit lane are multiplied.
	testing.expect_value(t, transmute([2]u64)x86._mm_mul_epu32(transmute(x86.__m128i)[4]u32{0xffff_ffff, 123, 2, 456}, transmute(x86.__m128i)[4]u32{0xffff_ffff, 7, 3, 9}), [2]u64{0xffff_fffe_0000_0001, 6})
	testing.expect_value(t, transmute([2]i64)x86._mm_mul_epi32(transmute(x86.__m128i)[4]i32{-1, 123, -2, 456}, transmute(x86.__m128i)[4]i32{-3, 7, max(i32), 9}), [2]i64{3, -2 * i64(max(i32))})

	out32: u32
	testing.expect_value(t, x86._addcarryx_u32(1, max(u32), 0, &out32), 1)
	testing.expect_value(t, out32, 0)
	out64: u64
	testing.expect_value(t, x86._addcarryx_u64(1, 5, 6, &out64), 0)
	testing.expect_value(t, out64, 12)
}

// These declared their intrinsics with the wrong types, which LLVM rejected.

@(test)
simd_x86_intrinsic_signatures :: proc(t: ^testing.T) {
	simd_x86_intrinsic_signatures_sse2(t)
}

@(private="file", enable_target_feature="sse,sse2")
simd_x86_intrinsic_signatures_sse2 :: proc(t: ^testing.T) {
	testing.expect_value(t, transmute([4]f32)x86._mm_cvtsd_ss(x86.__m128{1, 2, 3, 4}, x86.__m128d{0.1, 9}), [4]f32{0.1, 2, 3, 4})
	testing.expect_value(t, transmute([4]f32)x86._mm_cvtsd_ss(x86.__m128{1, 2, 3, 4}, x86.__m128d{-1e300, 9}), [4]f32{math.NEG_INF_F32, 2, 3, 4})
	testing.expect_value(t, transmute([2]f64)x86._mm_cvtss_sd(x86.__m128d{1, 2}, x86.__m128{1.5, 7, 8, 9}), [2]f64{1.5, 2})

	data: [64]u8
	x86._mm_prefetch(&data, x86._MM_HINT_T0)
	x86._mm_prefetch(&data, x86._MM_HINT_ET0)

	aux: u32 = 0xdead_beef
	tsc := x86.__rdtscp(&aux)
	testing.expect(t, tsc != 0)
	// aux is written from IA32_TSC_AUX, which the OS sets to the CPU number.
	testing.expect(t, aux != 0xdead_beef)
}

// These did not compile.

@(test)
simd_x86_avx_wrappers :: proc(t: ^testing.T) {
	if .avx not_in info.cpu_features() {
		return
	}
	simd_x86_avx_wrappers_avx(t)
}

@(private="file", enable_target_feature="sse,sse2,avx")
simd_x86_avx_wrappers_avx :: proc(t: ^testing.T) {
	a := x86.__m256d{1.5, -1.5, 2.5, -2.5}
	b := x86.__m256d{10, 20, 30, 40}
	testing.expect_value(t, transmute([4]f64)x86._mm256_round_pd(a, x86._MM_FROUND_TO_NEG_INF), [4]f64{1, -2, 2, -3})
	testing.expect_value(t, transmute([4]f64)x86._mm256_blend_pd(a, b, 0b0110), [4]f64{1.5, 20, 30, -2.5})
	testing.expect_value(t, transmute([4]f64)x86._mm256_permute2f128_pd(a, b, 0x21), [4]f64{2.5, -2.5, 10, 20})
	testing.expect_value(t, transmute([2]f64)x86._mm_permute_pd(x86.__m128d{1, 2}, 0b01), [2]f64{2, 1})
	testing.expect_value(t, transmute([4]f32)x86._mm_permute_ps(x86.__m128{1, 2, 3, 4}, 0x1b), [4]f32{4, 3, 2, 1})

	f := x86.__m256{1, 2, 3, 4, 5, 6, 7, 8}
	testing.expect_value(t, transmute([8]f32)x86._mm256_dp_ps(f, f, 0xf1), [8]f32{30, 0, 0, 0, 174, 0, 0, 0})
}

// x86 intrinsics with no portable form run as their own instruction. The expected values come
// from the LLVM backend.

@(private="file")
bits :: proc(v: x86.__m128i) -> [2]u64 {
	return transmute([2]u64)v
}

@(test, enable_target_feature="sse2,sse4.1,aes,pclmul")
simd_x86_vector_intrinsics :: proc(t: ^testing.T) {
	a := transmute(x86.__m128i)[2]u64{0x0123456789abcdef, 0x80007fff0001ff80}
	b := transmute(x86.__m128i)[2]u64{0xfedcba9876543210, 0x0000000280017f05}

	testing.expect_value(t, bits(x86._mm_aesenc_si128(a, b)),            [2]u64{0x4a7b11779f5178b6, 0x67427eb7845ed7f7})
	testing.expect_value(t, bits(x86._mm_aesdeclast_si128(a, b)),        [2]u64{0xac8e3a927f5d5971, 0xf2327d7fba0f173f})
	testing.expect_value(t, bits(x86._mm_aeskeygenassist_si128(a, 0x1b)), [2]u64{0x857c26757c266e85, 0x16cd63c9cd63d216})
	testing.expect_value(t, bits(x86._mm_clmulepi64_si128(a, b, 0x10)),  [2]u64{0xe819c54fd9fddf53, 0x2d7292f})
	testing.expect_value(t, bits(x86._mm_srli_epi64(a, 7)),              [2]u64{0x2468acf13579b, 0x10000fffe0003ff})
	// a count past the element width clears it
	testing.expect_value(t, bits(x86._mm_slli_epi64(a, 70)),             [2]u64{0, 0})
}

@(test, enable_target_feature="sse2,sse4.1")
simd_x86_scalar_intrinsics :: proc(t: ^testing.T) {
	a := transmute(x86.__m128i)[2]u64{0x0123456789abcdef, 0x80007fff0001ff80}
	b := transmute(x86.__m128i)[2]u64{0xfedcba9876543210, 0x0000000280017f05}
	testing.expect_value(t, x86._mm_movemask_epi8(a), 37647)
	testing.expect_value(t, x86._mm_testz_si128(a, b), 0)
	testing.expect_value(t, x86._mm_testc_si128(a, a), 1)

	// an unordered comparison is neither equal nor less
	nan := transmute(f64)u64(0x7ff8000000000000)
	x := x86.__m128d{nan, 0}
	y := x86.__m128d{1, 0}
	testing.expect_value(t, x86._mm_comieq_sd(x, y), 0)
	testing.expect_value(t, x86._mm_comineq_sd(x, y), 1)
	testing.expect_value(t, x86._mm_comilt_sd(y, x), 0)
	testing.expect_value(t, x86._mm_ucomige_sd(y, y), 1)

	testing.expect_value(t, x86._mm_cvtsd_si32(x86.__m128d{2.5, 0}), 2)
	testing.expect_value(t, x86._mm_cvttsd_si32(x86.__m128d{-2.7, 0}), -2)
}
