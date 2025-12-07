#+build amd64
package runtime

import "base:intrinsics"

#assert(ODIN_ENDIAN == .Little)

@(private = "file")
u32x8 :: #simd[8]u32
@(private = "file")
u32x4 :: #simd[4]u32

@(private = "file")
S0: u32x8 : {
	CHACHA_SIGMA_0, CHACHA_SIGMA_0, CHACHA_SIGMA_0, CHACHA_SIGMA_0,
	CHACHA_SIGMA_0, CHACHA_SIGMA_0, CHACHA_SIGMA_0, CHACHA_SIGMA_0,
}
@(private = "file")
S1: u32x8 : {
	CHACHA_SIGMA_1, CHACHA_SIGMA_1, CHACHA_SIGMA_1, CHACHA_SIGMA_1,
	CHACHA_SIGMA_1, CHACHA_SIGMA_1, CHACHA_SIGMA_1, CHACHA_SIGMA_1,
}
@(private = "file")
S2: u32x8 : {
	CHACHA_SIGMA_2, CHACHA_SIGMA_2, CHACHA_SIGMA_2, CHACHA_SIGMA_2,
	CHACHA_SIGMA_2, CHACHA_SIGMA_2, CHACHA_SIGMA_2, CHACHA_SIGMA_2,
}
@(private = "file")
S3: u32x8 : {
	CHACHA_SIGMA_3, CHACHA_SIGMA_3, CHACHA_SIGMA_3, CHACHA_SIGMA_3,
	CHACHA_SIGMA_3, CHACHA_SIGMA_3, CHACHA_SIGMA_3, CHACHA_SIGMA_3,
}

@(private = "file")
_ROT_7L: u32x8 : {7, 7, 7, 7, 7, 7, 7, 7}
@(private = "file")
_ROT_7R: u32x8 : {25, 25, 25, 25, 25, 25, 25, 25}
@(private = "file")
_ROT_12L: u32x8 : {12, 12, 12, 12, 12, 12, 12, 12}
@(private = "file")
_ROT_12R: u32x8 : {20, 20, 20, 20, 20, 20, 20, 20}
@(private = "file")
_ROT_8L: u32x8 : {8, 8, 8, 8, 8, 8, 8, 8}
@(private = "file")
_ROT_8R: u32x8 : {24, 24, 24, 24, 24, 24, 24, 24}
@(private = "file")
_ROT_16: u32x8 : {16, 16, 16, 16, 16, 16, 16, 16}
@(private = "file")
_CTR_INC_8: u32x8 : {8, 8, 8, 8, 8, 8, 8, 8}

// To the best of my knowledge this is only really useful on
// modern x86-64 as most ARM silicon is missing support for SVE2.

@(private, enable_target_feature = "avx,avx2")
chacha8rand_refill_simd256 :: proc(r: ^Default_Random_State) {
	// Initialize the base state.
	k: [^]u32 = (^u32)(raw_data(r._buf[RNG_OUTPUT_PER_ITER:]))
	s4_ := k[0]
	s5_ := k[1]
	s6_ := k[2]
	s7_ := k[3]
	s8_ := k[4]
	s9_ := k[5]
	s10_ := k[6]
	s11_ := k[7]

	// 8-lane ChaCha8.
	s4 := u32x8{s4_, s4_, s4_, s4_, s4_, s4_, s4_, s4_}
	s5 := u32x8{s5_, s5_, s5_, s5_, s5_, s5_, s5_, s5_}
	s6 := u32x8{s6_, s6_, s6_, s6_, s6_, s6_, s6_, s6_}
	s7 := u32x8{s7_, s7_, s7_, s7_, s7_, s7_, s7_, s7_}
	s8 := u32x8{s8_, s8_, s8_, s8_, s8_, s8_, s8_, s8_}
	s9 := u32x8{s9_, s9_, s9_, s9_, s9_, s9_, s9_, s9_}
	s10 := u32x8{s10_, s10_, s10_, s10_, s10_, s10_, s10_, s10_}
	s11 := u32x8{s11_, s11_, s11_, s11_, s11_, s11_, s11_, s11_}
	s12 := u32x8{0, 1, 2, 3, 4, 5, 6, 7}
	s13, s14, s15: u32x8

	u32x4 :: #simd[4]u32
	dst: [^]u32x4 = (^u32x4)(raw_data(r._buf[:]))

	quarter_round := #force_inline proc "contextless" (a, b, c, d: u32x8) -> (u32x8, u32x8, u32x8, u32x8) {
		a, b, c, d := a, b, c, d

		a = intrinsics.simd_add(a, b)
		d = intrinsics.simd_bit_xor(d, a)
		d = intrinsics.simd_bit_xor(intrinsics.simd_shl(d, _ROT_16), intrinsics.simd_shr(d, _ROT_16))

		c = intrinsics.simd_add(c, d)
		b = intrinsics.simd_bit_xor(b, c)
		b = intrinsics.simd_bit_xor(intrinsics.simd_shl(b, _ROT_12L), intrinsics.simd_shr(b, _ROT_12R))

		a = intrinsics.simd_add(a, b)
		d = intrinsics.simd_bit_xor(d, a)
		d = intrinsics.simd_bit_xor(intrinsics.simd_shl(d, _ROT_8L), intrinsics.simd_shr(d, _ROT_8R))

		c = intrinsics.simd_add(c, d)
		b = intrinsics.simd_bit_xor(b, c)
		b = intrinsics.simd_bit_xor(intrinsics.simd_shl(b, _ROT_7L), intrinsics.simd_shr(b, _ROT_7R))

		return a, b, c, d
	}

	for _ in 0..<2 {
		x0, x1, x2, x3 := S0, S1, S2, S3
		x4, x5, x6, x7 := s4, s5, s6, s7
		x8, x9, x10, x11 := s8, s9, s10, s11
		x12, x13, x14, x15 := s12, s13, s14, s15

		for i := CHACHA_ROUNDS; i > 0; i = i - 2 {
			x0, x4, x8, x12 = quarter_round(x0, x4, x8, x12)
			x1, x5, x9, x13 = quarter_round(x1, x5, x9, x13)
			x2, x6, x10, x14 = quarter_round(x2, x6, x10, x14)
			x3, x7, x11, x15 = quarter_round(x3, x7, x11, x15)

			x0, x5, x10, x15 = quarter_round(x0, x5, x10, x15)
			x1, x6, x11, x12 = quarter_round(x1, x6, x11, x12)
			x2, x7, x8, x13 = quarter_round(x2, x7, x8, x13)
			x3, x4, x9, x14 = quarter_round(x3, x4, x9, x14)
		}

		x4 = intrinsics.simd_add(x4, s4)
		x5 = intrinsics.simd_add(x5, s5)
		x6 = intrinsics.simd_add(x6, s6)
		x7 = intrinsics.simd_add(x7, s7)
		x8 = intrinsics.simd_add(x8, s8)
		x9 = intrinsics.simd_add(x9, s9)
		x10 = intrinsics.simd_add(x10, s10)
		x11 = intrinsics.simd_add(x11, s11)
		x13 = intrinsics.simd_add(x13, s13)
		x14 = intrinsics.simd_add(x14, s14)
		x15 = intrinsics.simd_add(x15, s15)

		// Ok, now we have x0->x15 with 8 lanes, but we need to
		// output the first 4 blocks, then the second 4 blocks.
		//
		// LLVM appears not to consider "this instruction is totally
		// awful on the given microarchitcture", which leads to
		// `VPCOMPRESSED` being generated iff AVX512 support is
		// enabled for `intrinsics.simd_masked_compress_store`.
		// On Zen 4, this leads to a 50% performance regression vs
		// the 128-bit SIMD code.
		//
		// The fake intrinsic (because LLVM doesn't appear to have
		// an amd64 specific one), doesn't generate `VEXTRACTI128`,
		// but instead does cleverness without horrible regressions.

		intrinsics.unaligned_store((^u32x4)(dst[0:]), _mm_mm256_extracti128_si256(x0, 0))
		intrinsics.unaligned_store((^u32x4)(dst[1:]), _mm_mm256_extracti128_si256(x1, 0))
		intrinsics.unaligned_store((^u32x4)(dst[2:]), _mm_mm256_extracti128_si256(x2, 0))
		intrinsics.unaligned_store((^u32x4)(dst[3:]), _mm_mm256_extracti128_si256(x3, 0))
		intrinsics.unaligned_store((^u32x4)(dst[4:]), _mm_mm256_extracti128_si256(x4, 0))
		intrinsics.unaligned_store((^u32x4)(dst[5:]), _mm_mm256_extracti128_si256(x5, 0))
		intrinsics.unaligned_store((^u32x4)(dst[6:]), _mm_mm256_extracti128_si256(x6, 0))
		intrinsics.unaligned_store((^u32x4)(dst[7:]), _mm_mm256_extracti128_si256(x7, 0))
		intrinsics.unaligned_store((^u32x4)(dst[8:]), _mm_mm256_extracti128_si256(x8, 0))
		intrinsics.unaligned_store((^u32x4)(dst[9:]), _mm_mm256_extracti128_si256(x9, 0))
		intrinsics.unaligned_store((^u32x4)(dst[10:]), _mm_mm256_extracti128_si256(x10, 0))
		intrinsics.unaligned_store((^u32x4)(dst[11:]), _mm_mm256_extracti128_si256(x11, 0))
		intrinsics.unaligned_store((^u32x4)(dst[12:]), _mm_mm256_extracti128_si256(x12, 0))
		intrinsics.unaligned_store((^u32x4)(dst[13:]), _mm_mm256_extracti128_si256(x13, 0))
		intrinsics.unaligned_store((^u32x4)(dst[14:]), _mm_mm256_extracti128_si256(x14, 0))
		intrinsics.unaligned_store((^u32x4)(dst[15:]), _mm_mm256_extracti128_si256(x15, 0))

		intrinsics.unaligned_store((^u32x4)(dst[16:]), _mm_mm256_extracti128_si256(x0, 1))
		intrinsics.unaligned_store((^u32x4)(dst[17:]), _mm_mm256_extracti128_si256(x1, 1))
		intrinsics.unaligned_store((^u32x4)(dst[18:]), _mm_mm256_extracti128_si256(x2, 1))
		intrinsics.unaligned_store((^u32x4)(dst[19:]), _mm_mm256_extracti128_si256(x3, 1))
		intrinsics.unaligned_store((^u32x4)(dst[20:]), _mm_mm256_extracti128_si256(x4, 1))
		intrinsics.unaligned_store((^u32x4)(dst[21:]), _mm_mm256_extracti128_si256(x5, 1))
		intrinsics.unaligned_store((^u32x4)(dst[22:]), _mm_mm256_extracti128_si256(x6, 1))
		intrinsics.unaligned_store((^u32x4)(dst[23:]), _mm_mm256_extracti128_si256(x7, 1))
		intrinsics.unaligned_store((^u32x4)(dst[24:]), _mm_mm256_extracti128_si256(x8, 1))
		intrinsics.unaligned_store((^u32x4)(dst[25:]), _mm_mm256_extracti128_si256(x9, 1))
		intrinsics.unaligned_store((^u32x4)(dst[26:]), _mm_mm256_extracti128_si256(x10, 1))
		intrinsics.unaligned_store((^u32x4)(dst[27:]), _mm_mm256_extracti128_si256(x11, 1))
		intrinsics.unaligned_store((^u32x4)(dst[28:]), _mm_mm256_extracti128_si256(x12, 1))
		intrinsics.unaligned_store((^u32x4)(dst[29:]), _mm_mm256_extracti128_si256(x13, 1))
		intrinsics.unaligned_store((^u32x4)(dst[30:]), _mm_mm256_extracti128_si256(x14, 1))
		intrinsics.unaligned_store((^u32x4)(dst[31:]), _mm_mm256_extracti128_si256(x15, 1))

		s12 = intrinsics.simd_add(s12, _CTR_INC_8)

		dst = dst[32:]
	}
}

@(private = "file", require_results, enable_target_feature="avx2")
_mm_mm256_extracti128_si256 :: #force_inline proc "c" (a: u32x8, $OFFSET: int) -> u32x4 {
	when OFFSET == 0 {
		return intrinsics.simd_shuffle(a, a, 0, 1, 2, 3)
	} else when OFFSET == 1 {
		return intrinsics.simd_shuffle(a, a, 4, 5, 6, 7)
	} else {
		#panic("chacha8rand: invalid offset")
	}
}
