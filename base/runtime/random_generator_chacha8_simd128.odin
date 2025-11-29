#+build !i386
package runtime

import "base:intrinsics"

@(private = "file")
u32x4 :: #simd[4]u32

@(private = "file")
S0: u32x4 : {CHACHA_SIGMA_0, CHACHA_SIGMA_0, CHACHA_SIGMA_0, CHACHA_SIGMA_0}
@(private = "file")
S1: u32x4 : {CHACHA_SIGMA_1, CHACHA_SIGMA_1, CHACHA_SIGMA_1, CHACHA_SIGMA_1}
@(private = "file")
S2: u32x4 : {CHACHA_SIGMA_2, CHACHA_SIGMA_2, CHACHA_SIGMA_2, CHACHA_SIGMA_2}
@(private = "file")
S3: u32x4 : {CHACHA_SIGMA_3, CHACHA_SIGMA_3, CHACHA_SIGMA_3, CHACHA_SIGMA_3}

@(private = "file")
_ROT_7L: u32x4 : {7, 7, 7, 7}
@(private = "file")
_ROT_7R: u32x4 : {25, 25, 25, 25}
@(private = "file")
_ROT_12L: u32x4 : {12, 12, 12, 12}
@(private = "file")
_ROT_12R: u32x4 : {20, 20, 20, 20}
@(private = "file")
_ROT_8L: u32x4 : {8, 8, 8, 8}
@(private = "file")
_ROT_8R: u32x4 : {24, 24, 24, 24}
@(private = "file")
_ROT_16: u32x4 : {16, 16, 16, 16}
@(private = "file")
_CTR_INC_4: u32x4 : {4, 4, 4, 4}
@(private = "file")
_CTR_INC_8: u32x4 : {8, 8, 8, 8}

when ODIN_ENDIAN == .Big {
	@(private = "file")
	_byteswap_u32x4 :: #force_inline proc "contextless" (v: u32x4) -> u32x4 {
		u8x16 :: #simd[16]u8
		return(
			transmute(u32x4)simd.shuffle(
				transmute(u8x16)v,
				transmute(u8x16)v,
				3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12,
			)
		)
	}
}

@(private)
chacha8rand_refill_simd128 :: proc(r: ^Default_Random_State) {
	// Initialize the base state.
	k: [^]u32 = (^u32)(raw_data(r._buf[RNG_OUTPUT_PER_ITER:]))
	when ODIN_ENDIAN == .Little {
		s4_ := k[0]
		s5_ := k[1]
		s6_ := k[2]
		s7_ := k[3]
		s8_ := k[4]
		s9_ := k[5]
		s10_ := k[6]
		s11_ := k[7]
	} else {
		s4_ := intrinsics.byte_swap(k[0])
		s5_ := intrinsics.byte_swap(k[1])
		s6_ := intrinsics.byte_swap(k[2])
		s7_ := intrinsics.byte_swap(k[3])
		s8_ := intrinsics.byte_swap(k[4])
		s9_ := intrinsics.byte_swap(k[5])
		s10_ := intrinsics.byte_swap(k[6])
		s11_ := intrinicss.byte_swap(k[7])
	}

	// 4-lane ChaCha8.
	s4 := u32x4{s4_, s4_, s4_, s4_}
	s5 := u32x4{s5_, s5_, s5_, s5_}
	s6 := u32x4{s6_, s6_, s6_, s6_}
	s7 := u32x4{s7_, s7_, s7_, s7_}
	s8 := u32x4{s8_, s8_, s8_, s8_}
	s9 := u32x4{s9_, s9_, s9_, s9_}
	s10 := u32x4{s10_, s10_, s10_, s10_}
	s11 := u32x4{s11_, s11_, s11_, s11_}
	s12 := u32x4{0, 1, 2, 3}
	s13, s14, s15: u32x4

	dst: [^]u32x4 = (^u32x4)(raw_data(r._buf[:]))

	quarter_round := #force_inline proc "contextless" (a, b, c, d: u32x4) -> (u32x4, u32x4, u32x4, u32x4) {
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

	// 8 blocks at a time.
	//
	// Note:
	// This uses a ton of registers so it is only worth it on targets
	// that have something like 32 128-bit registers.  This is currently
	// all ARMv8 targets, and RISC-V Zvl128b (`V` application profile)
	// targets.
	//
	// While our current definition of `.arm32` is 32-bit ARMv8, this
	// may change in the future (ARMv7 is still relevant), and things
	// like Cortex-A8/A9 does "pretend" 128-bit SIMD 64-bits at a time
	// thus needs bemchmarking.
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		for _ in 0..<2 {
			x0_0, x1_0, x2_0, x3_0 := S0, S1, S2, S3
			x4_0, x5_0, x6_0, x7_0 := s4, s5, s6, s7
			x8_0, x9_0, x10_0, x11_0 := s8, s9, s10, s11
			x12_0, x13_0, x14_0, x15_0 := s12, s13, s14, s15

			x0_1, x1_1, x2_1, x3_1 := S0, S1, S2, S3
			x4_1, x5_1, x6_1, x7_1 := s4, s5, s6, s7
			x8_1, x9_1, x10_1, x11_1 := s8, s9, s10, s11
			x12_1 := intrinsics.simd_add(s12, _CTR_INC_4)
			x13_1, x14_1, x15_1 := s13, s14, s15

			for i := CHACHA_ROUNDS; i > 0; i = i - 2 {
				x0_0, x4_0, x8_0, x12_0 = quarter_round(x0_0, x4_0, x8_0, x12_0)
				x0_1, x4_1, x8_1, x12_1 = quarter_round(x0_1, x4_1, x8_1, x12_1)
				x1_0, x5_0, x9_0, x13_0 = quarter_round(x1_0, x5_0, x9_0, x13_0)
				x1_1, x5_1, x9_1, x13_1 = quarter_round(x1_1, x5_1, x9_1, x13_1)
				x2_0, x6_0, x10_0, x14_0 = quarter_round(x2_0, x6_0, x10_0, x14_0)
				x2_1, x6_1, x10_1, x14_1 = quarter_round(x2_1, x6_1, x10_1, x14_1)
				x3_0, x7_0, x11_0, x15_0 = quarter_round(x3_0, x7_0, x11_0, x15_0)
				x3_1, x7_1, x11_1, x15_1 = quarter_round(x3_1, x7_1, x11_1, x15_1)

				x0_0, x5_0, x10_0, x15_0 = quarter_round(x0_0, x5_0, x10_0, x15_0)
				x0_1, x5_1, x10_1, x15_1 = quarter_round(x0_1, x5_1, x10_1, x15_1)
				x1_0, x6_0, x11_0, x12_0 = quarter_round(x1_0, x6_0, x11_0, x12_0)
				x1_1, x6_1, x11_1, x12_1 = quarter_round(x1_1, x6_1, x11_1, x12_1)
				x2_0, x7_0, x8_0, x13_0 = quarter_round(x2_0, x7_0, x8_0, x13_0)
				x2_1, x7_1, x8_1, x13_1 = quarter_round(x2_1, x7_1, x8_1, x13_1)
				x3_0, x4_0, x9_0, x14_0 = quarter_round(x3_0, x4_0, x9_0, x14_0)
				x3_1, x4_1, x9_1, x14_1 = quarter_round(x3_1, x4_1, x9_1, x14_1)
			}

			when ODIN_ENDIAN == .Little {
				intrinsics.unaligned_store((^u32x4)(dst[0:]), x0_0)
				intrinsics.unaligned_store((^u32x4)(dst[1:]), x1_0)
				intrinsics.unaligned_store((^u32x4)(dst[2:]), x2_0)
				intrinsics.unaligned_store((^u32x4)(dst[3:]), x3_0)
				intrinsics.unaligned_store((^u32x4)(dst[4:]), intrinsics.simd_add(x4_0, s4))
				intrinsics.unaligned_store((^u32x4)(dst[5:]), intrinsics.simd_add(x5_0, s5))
				intrinsics.unaligned_store((^u32x4)(dst[6:]), intrinsics.simd_add(x6_0, s6))
				intrinsics.unaligned_store((^u32x4)(dst[7:]), intrinsics.simd_add(x7_0, s7))
				intrinsics.unaligned_store((^u32x4)(dst[8:]), intrinsics.simd_add(x8_0, s8))
				intrinsics.unaligned_store((^u32x4)(dst[9:]), intrinsics.simd_add(x9_0, s9))
				intrinsics.unaligned_store((^u32x4)(dst[10:]), intrinsics.simd_add(x10_0, s10))
				intrinsics.unaligned_store((^u32x4)(dst[11:]), intrinsics.simd_add(x11_0, s11))
				intrinsics.unaligned_store((^u32x4)(dst[12:]), x12_0)
				intrinsics.unaligned_store((^u32x4)(dst[13:]), intrinsics.simd_add(x13_0, s13))
				intrinsics.unaligned_store((^u32x4)(dst[14:]), intrinsics.simd_add(x14_0, s14))
				intrinsics.unaligned_store((^u32x4)(dst[15:]), intrinsics.simd_add(x15_0, s15))

				intrinsics.unaligned_store((^u32x4)(dst[16:]), x0_1)
				intrinsics.unaligned_store((^u32x4)(dst[17:]), x1_1)
				intrinsics.unaligned_store((^u32x4)(dst[18:]), x2_1)
				intrinsics.unaligned_store((^u32x4)(dst[19:]), x3_1)
				intrinsics.unaligned_store((^u32x4)(dst[20:]), intrinsics.simd_add(x4_1, s4))
				intrinsics.unaligned_store((^u32x4)(dst[21:]), intrinsics.simd_add(x5_1, s5))
				intrinsics.unaligned_store((^u32x4)(dst[22:]), intrinsics.simd_add(x6_1, s6))
				intrinsics.unaligned_store((^u32x4)(dst[23:]), intrinsics.simd_add(x7_1, s7))
				intrinsics.unaligned_store((^u32x4)(dst[24:]), intrinsics.simd_add(x8_1, s8))
				intrinsics.unaligned_store((^u32x4)(dst[25:]), intrinsics.simd_add(x9_1, s9))
				intrinsics.unaligned_store((^u32x4)(dst[26:]), intrinsics.simd_add(x10_1, s10))
				intrinsics.unaligned_store((^u32x4)(dst[27:]), intrinsics.simd_add(x11_1, s11))
				intrinsics.unaligned_store((^u32x4)(dst[28:]), x12_1)
				intrinsics.unaligned_store((^u32x4)(dst[29:]), intrinsics.simd_add(x13_1, s13))
				intrinsics.unaligned_store((^u32x4)(dst[30:]), intrinsics.simd_add(x14_1, s14))
				intrinsics.unaligned_store((^u32x4)(dst[31:]), intrinsics.simd_add(x15_1, s15))
			} else {
				intrinsics.unaligned_store((^u32x4)(dst[0:]), _byteswap_u32x4(x0_0))
				intrinsics.unaligned_store((^u32x4)(dst[1:]), _byteswap_u32x4(x1_0))
				intrinsics.unaligned_store((^u32x4)(dst[2:]), _byteswap_u32x4(x2_0))
				intrinsics.unaligned_store((^u32x4)(dst[3:]), _byteswap_u32x4(x3_0))
				intrinsics.unaligned_store((^u32x4)(dst[4:]), _byteswap_u32x4(intrinsics.simd_add(x4_0, s4)))
				intrinsics.unaligned_store((^u32x4)(dst[5:]), _byteswap_u32x4(intrinsics.simd_add(x5_0, s5)))
				intrinsics.unaligned_store((^u32x4)(dst[6:]), _byteswap_u32x4(intrinsics.simd_add(x6_0, s6)))
				intrinsics.unaligned_store((^u32x4)(dst[7:]), _byteswap_u32x4(intrinsics.simd_add(x7_0, s7)))
				intrinsics.unaligned_store((^u32x4)(dst[8:]), _byteswap_u32x4(intrinsics.simd_add(x8_0, s8)))
				intrinsics.unaligned_store((^u32x4)(dst[9:]), _byteswap_u32x4(intrinsics.simd_add(x9_0, s9)))
				intrinsics.unaligned_store((^u32x4)(dst[10:]), _byteswap_u32x4(intrinsics.simd_add(x10_0, s10)))
				intrinsics.unaligned_store((^u32x4)(dst[11:]), _byteswap_u32x4(intrinsics.simd_add(x11_0, s11)))
				intrinsics.unaligned_store((^u32x4)(dst[12:]), _byteswap_u32x4(x12_0))
				intrinsics.unaligned_store((^u32x4)(dst[13:]), _byteswap_u32x4(intrinsics.simd_add(x13_0, s13)))
				intrinsics.unaligned_store((^u32x4)(dst[14:]), _byteswap_u32x4(intrinsics.simd_add(x14_0, s14)))
				intrinsics.unaligned_store((^u32x4)(dst[15:]), _byteswap_u32x4(intrinsics.simd_add(x15_0, s15)))

				intrinsics.unaligned_store((^u32x4)(dst[16:]), _byteswap_u32x4(x0_1))
				intrinsics.unaligned_store((^u32x4)(dst[17:]), _byteswap_u32x4(x1_1))
				intrinsics.unaligned_store((^u32x4)(dst[18:]), _byteswap_u32x4(x2_1))
				intrinsics.unaligned_store((^u32x4)(dst[19:]), _byteswap_u32x4(x3_1))
				intrinsics.unaligned_store((^u32x4)(dst[20:]), _byteswap_u32x4(intrinsics.simd_add(x4_1, s4)))
				intrinsics.unaligned_store((^u32x4)(dst[21:]), _byteswap_u32x4(intrinsics.simd_add(x5_1, s5)))
				intrinsics.unaligned_store((^u32x4)(dst[22:]), _byteswap_u32x4(intrinsics.simd_add(x6_1, s6)))
				intrinsics.unaligned_store((^u32x4)(dst[23:]), _byteswap_u32x4(intrinsics.simd_add(x7_1, s7)))
				intrinsics.unaligned_store((^u32x4)(dst[24:]), _byteswap_u32x4(intrinsics.simd_add(x8_1, s8)))
				intrinsics.unaligned_store((^u32x4)(dst[25:]), _byteswap_u32x4(intrinsics.simd_add(x9_1, s9)))
				intrinsics.unaligned_store((^u32x4)(dst[26:]), _byteswap_u32x4(intrinsics.simd_add(x10_1, s10)))
				intrinsics.unaligned_store((^u32x4)(dst[27:]), _byteswap_u32x4(intrinsics.simd_add(x11_1, s11)))
				intrinsics.unaligned_store((^u32x4)(dst[28:]), _byteswap_u32x4(x12_1))
				intrinsics.unaligned_store((^u32x4)(dst[29:]), _byteswap_u32x4(intrinsics.simd_add(x13_1, s13)))
				intrinsics.unaligned_store((^u32x4)(dst[30:]), _byteswap_u32x4(intrinsics.simd_add(x14_1, s14)))
				intrinsics.unaligned_store((^u32x4)(dst[31:]), _byteswap_u32x4(intrinsics.simd_add(x15_1, s15)))
			}

			s12 = intrinsics.simd_add(s12, _CTR_INC_8)

			dst = dst[32:]
		}
	} else {
		for _ in 0..<4 {
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

			when ODIN_ENDIAN == .Little {
				intrinsics.unaligned_store((^u32x4)(dst[0:]), x0)
				intrinsics.unaligned_store((^u32x4)(dst[1:]), x1)
				intrinsics.unaligned_store((^u32x4)(dst[2:]), x2)
				intrinsics.unaligned_store((^u32x4)(dst[3:]), x3)
				intrinsics.unaligned_store((^u32x4)(dst[4:]), intrinsics.simd_add(x4, s4))
				intrinsics.unaligned_store((^u32x4)(dst[5:]), intrinsics.simd_add(x5, s5))
				intrinsics.unaligned_store((^u32x4)(dst[6:]), intrinsics.simd_add(x6, s6))
				intrinsics.unaligned_store((^u32x4)(dst[7:]), intrinsics.simd_add(x7, s7))
				intrinsics.unaligned_store((^u32x4)(dst[8:]), intrinsics.simd_add(x8, s8))
				intrinsics.unaligned_store((^u32x4)(dst[9:]), intrinsics.simd_add(x9, s9))
				intrinsics.unaligned_store((^u32x4)(dst[10:]), intrinsics.simd_add(x10, s10))
				intrinsics.unaligned_store((^u32x4)(dst[11:]), intrinsics.simd_add(x11, s11))
				intrinsics.unaligned_store((^u32x4)(dst[12:]), x12)
				intrinsics.unaligned_store((^u32x4)(dst[13:]), intrinsics.simd_add(x13, s13))
				intrinsics.unaligned_store((^u32x4)(dst[14:]), intrinsics.simd_add(x14, s14))
				intrinsics.unaligned_store((^u32x4)(dst[15:]), intrinsics.simd_add(x15, s15))
			} else {
				intrinsics.unaligned_store((^u32x4)(dst[0:]), _byteswap_u32x4(x0))
				intrinsics.unaligned_store((^u32x4)(dst[1:]), _byteswap_u32x4(x1))
				intrinsics.unaligned_store((^u32x4)(dst[2:]), _byteswap_u32x4(x2))
				intrinsics.unaligned_store((^u32x4)(dst[3:]), _byteswap_u32x4(x3))
				intrinsics.unaligned_store((^u32x4)(dst[4:]), _byteswap_u32x4(intrinsics.simd_add(x4, s4)))
				intrinsics.unaligned_store((^u32x4)(dst[5:]), _byteswap_u32x4(intrinsics.simd_add(x5, s5)))
				intrinsics.unaligned_store((^u32x4)(dst[6:]), _byteswap_u32x4(intrinsics.simd_add(x6, s6)))
				intrinsics.unaligned_store((^u32x4)(dst[7:]), _byteswap_u32x4(intrinsics.simd_add(x7, s7)))
				intrinsics.unaligned_store((^u32x4)(dst[8:]), _byteswap_u32x4(intrinsics.simd_add(x8, s8)))
				intrinsics.unaligned_store((^u32x4)(dst[9:]), _byteswap_u32x4(intrinsics.simd_add(x9, s9)))
				intrinsics.unaligned_store((^u32x4)(dst[10:]), _byteswap_u32x4(intrinsics.simd_add(x10, s10)))
				intrinsics.unaligned_store((^u32x4)(dst[11:]), _byteswap_u32x4(intrinsics.simd_add(x11, s11)))
				intrinsics.unaligned_store((^u32x4)(dst[12:]), _byteswap_u32x4(x12))
				intrinsics.unaligned_store((^u32x4)(dst[13:]), _byteswap_u32x4(intrinsics.simd_add(x13, s13)))
				intrinsics.unaligned_store((^u32x4)(dst[14:]), _byteswap_u32x4(intrinsics.simd_add(x14, s14)))
				intrinsics.unaligned_store((^u32x4)(dst[15:]), _byteswap_u32x4(intrinsics.simd_add(x15, s15)))
			}

			s12 = intrinsics.simd_add(s12, _CTR_INC_4)

			dst = dst[16:]
		}
	}
}
