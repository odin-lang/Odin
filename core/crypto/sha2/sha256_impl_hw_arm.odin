#+build arm64,arm32
package sha2

// Based on the public domain code by Jeffrey Walton, though
// realistically, there only is one sensible way to write this.
//
// See: https://github.com/noloader/SHA-Intrinsics

import "base:intrinsics"
import "core:simd"
import "core:simd/arm"
import "core:sys/info"

// is_hardware_accelerated_256 returns true if and only if (⟺) hardware
// accelerated SHA-224/SHA-256 is supported.
is_hardware_accelerated_256 :: proc "contextless" () -> bool {
	req_features :: info.CPU_Features{
		.asimd,
		.sha256,
	}
	return info.cpu_features() >= req_features
}

@(private = "file")
K_0 :: simd.u32x4{0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5}
@(private = "file")
K_1 :: simd.u32x4{0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5}
@(private = "file")
K_2 :: simd.u32x4{0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3}
@(private = "file")
K_3 :: simd.u32x4{0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174}
@(private = "file")
K_4 :: simd.u32x4{0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC}
@(private = "file")
K_5 :: simd.u32x4{0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA}
@(private = "file")
K_6 :: simd.u32x4{0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7}
@(private = "file")
K_7 :: simd.u32x4{0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967}
@(private = "file")
K_8 :: simd.u32x4{0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13}
@(private = "file")
K_9 :: simd.u32x4{0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85}
@(private = "file")
K_10 :: simd.u32x4{0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3}
@(private = "file")
K_11 :: simd.u32x4{0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070}
@(private = "file")
K_12 :: simd.u32x4{0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5}
@(private = "file")
K_13 :: simd.u32x4{0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3}
@(private = "file")
K_14 :: simd.u32x4{0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208}
@(private = "file")
K_15 :: simd.u32x4{0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2}

@(private, enable_target_feature = "neon,sha2")
sha256_transf_hw :: proc "contextless" (ctx: ^Context_256, data: []byte) #no_bounds_check {
	state_0 := intrinsics.unaligned_load((^simd.u32x4)(&ctx.h[0]))
	state_1 := intrinsics.unaligned_load((^simd.u32x4)(&ctx.h[4]))

	data := data
	for len(data) >= BLOCK_SIZE_256 {
		// Save state
		abef_save, cdgh_save := state_0, state_1

		// Load message
		msg_0 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data)))
		msg_1 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data[16:])))
		msg_2 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data[32:])))
		msg_3 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data[48:])))

		// Reverse for little endian
		when ODIN_ENDIAN == .Little {
			msg_0 = byteswap_u32x4(msg_0)
			msg_1 = byteswap_u32x4(msg_1)
			msg_2 = byteswap_u32x4(msg_2)
			msg_3 = byteswap_u32x4(msg_3)
		}

		tmp_0 := simd.add(msg_0, K_0)

		// Rounds 0-3
		msg_0 = arm.vsha256su0q_u32(msg_0, msg_1)
		tmp_2 := state_0
		tmp_1 := simd.add(msg_1, K_1)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)
		msg_0 = arm.vsha256su1q_u32(msg_0, msg_2, msg_3)

		// Rounds 4-7
		msg_1 = arm.vsha256su0q_u32(msg_1, msg_2)
		tmp_2 = state_0
		tmp_0 = simd.add(msg_2, K_2)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)
		msg_1 = arm.vsha256su1q_u32(msg_1, msg_3, msg_0)

		// Rounds 8-11
		msg_2 = arm.vsha256su0q_u32(msg_2, msg_3)
		tmp_2 = state_0
		tmp_1 = simd.add(msg_3, K_3)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)
		msg_2 = arm.vsha256su1q_u32(msg_2, msg_0, msg_1)

		// Rounds 12-15
		msg_3 = arm.vsha256su0q_u32(msg_3, msg_0)
		tmp_2 = state_0
		tmp_0 = simd.add(msg_0, K_4)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)
		msg_3 = arm.vsha256su1q_u32(msg_3, msg_1, msg_2)

		// Rounds 16-19
		msg_0 = arm.vsha256su0q_u32(msg_0, msg_1)
		tmp_2 = state_0
		tmp_1 = simd.add(msg_1, K_5)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)
		msg_0 = arm.vsha256su1q_u32(msg_0, msg_2, msg_3)

		// Rounds 20-23
		msg_1 = arm.vsha256su0q_u32(msg_1, msg_2)
		tmp_2 = state_0
		tmp_0 = simd.add(msg_2, K_6)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)
		msg_1 = arm.vsha256su1q_u32(msg_1, msg_3, msg_0)

		// Rounds 24-27
		msg_2 = arm.vsha256su0q_u32(msg_2, msg_3)
		tmp_2 = state_0
		tmp_1 = simd.add(msg_3, K_7)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)
		msg_2 = arm.vsha256su1q_u32(msg_2, msg_0, msg_1)

		// Rounds 28-31
		msg_3 = arm.vsha256su0q_u32(msg_3, msg_0)
		tmp_2 = state_0
		tmp_0 = simd.add(msg_0, K_8)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)
		msg_3 = arm.vsha256su1q_u32(msg_3, msg_1, msg_2)

		// Rounds 32-35
		msg_0 = arm.vsha256su0q_u32(msg_0, msg_1)
		tmp_2 = state_0
		tmp_1 = simd.add(msg_1, K_9)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)
		msg_0 = arm.vsha256su1q_u32(msg_0, msg_2, msg_3)

		// Rounds 36-39
		msg_1 = arm.vsha256su0q_u32(msg_1, msg_2)
		tmp_2 = state_0
		tmp_0 = simd.add(msg_2, K_10)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)
		msg_1 = arm.vsha256su1q_u32(msg_1, msg_3, msg_0)

		// Rounds 40-43
		msg_2 = arm.vsha256su0q_u32(msg_2, msg_3)
		tmp_2 = state_0
		tmp_1 = simd.add(msg_3, K_11)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)
		msg_2 = arm.vsha256su1q_u32(msg_2, msg_0, msg_1)

		// Rounds 44-47
		msg_3 = arm.vsha256su0q_u32(msg_3, msg_0)
		tmp_2 = state_0
		tmp_0 = simd.add(msg_0, K_12)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)
		msg_3 = arm.vsha256su1q_u32(msg_3, msg_1, msg_2)

		// Rounds 48-51
		tmp_2 = state_0
		tmp_1 = simd.add(msg_1, K_13)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)

		// Rounds 52-55
		tmp_2 = state_0
		tmp_0 = simd.add(msg_2, K_14)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)

		// Rounds 56-59
		tmp_2 = state_0
		tmp_1 = simd.add(msg_3, K_15)
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_0)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_0)

		// Rounds 60-63
		tmp_2 = state_0
		state_0 = arm.vsha256hq_u32(state_0, state_1, tmp_1)
		state_1 = arm.vsha256h2q_u32(state_1, tmp_2, tmp_1)

		// Combine state
		state_0 = simd.add(state_0, abef_save)
		state_1 = simd.add(state_1, cdgh_save)

		data = data[BLOCK_SIZE_256:]
	}

	intrinsics.unaligned_store((^simd.u32x4)(&ctx.h[0]), state_0)
	intrinsics.unaligned_store((^simd.u32x4)(&ctx.h[4]), state_1)
}

when ODIN_ENDIAN == .Little {
	@(private = "file", enable_target_feature = "neon")
	byteswap_u32x4 :: #force_inline proc "contextless" (a: simd.u32x4) -> simd.u32x4 {
		return transmute(simd.u32x4)(
			simd.shuffle(
				transmute(simd.u8x16)(a),
				transmute(simd.u8x16)(a),
				3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12,
			)
		)
	}
}