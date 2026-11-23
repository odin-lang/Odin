#+build arm64,arm32
package sha1

// Based on the public domain code by Jeffrey Walton, though
// realistically, there only is one sensible way to write this.
//
// See: https://github.com/noloader/SHA-Intrinsics

import "base:intrinsics"
import "core:simd"
import "core:simd/arm"
import "core:sys/info"

// is_hardware_accelerated returns true if and only if (⟺) hardware
// accelerated SHA-1 is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	req_features :: info.CPU_Features{
		.asimd,
		.sha1,
	}
	return info.cpu_features() >= req_features
}

@(private = "file")
K_0 :: simd.u32x4{0x5A827999, 0x5A827999, 0x5A827999, 0x5A827999}
@(private = "file")
K_1 :: simd.u32x4{0x6ED9EBA1, 0x6ED9EBA1, 0x6ED9EBA1, 0x6ED9EBA1}
@(private = "file")
K_2 :: simd.u32x4{0x8F1BBCDC, 0x8F1BBCDC, 0x8F1BBCDC, 0x8F1BBCDC}
@(private = "file")
K_3 :: simd.u32x4{0xCA62C1D6, 0xCA62C1D6, 0xCA62C1D6, 0xCA62C1D6}

@(private, enable_target_feature = "neon,sha2")
sha1_transf_hw :: proc "contextless" (ctx: ^Context, data: []byte) #no_bounds_check {
	abcd := intrinsics.unaligned_load((^simd.u32x4)(&ctx.state[0]))
	e_0 := ctx.state[4]

	data := data
	for len(data) >= BLOCK_SIZE {
		abcd_save, e_0_save := abcd, e_0

		msg_0 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data)))
		msg_1 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data[16:])))
		msg_2 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data[32:])))
		msg_3 := intrinsics.unaligned_load((^simd.u32x4)(raw_data(data[48:])))

		when ODIN_ENDIAN == .Little {
			msg_0 = byteswap_u32x4(msg_0)
			msg_1 = byteswap_u32x4(msg_1)
			msg_2 = byteswap_u32x4(msg_2)
			msg_3 = byteswap_u32x4(msg_3)
		}

		tmp_0 := simd.add(msg_0, K_0)
		tmp_1 := simd.add(msg_1, K_0)

		e_1 := arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1cq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_2, K_0)
		msg_0 = arm.vsha1su0q_u32(msg_0, msg_1, msg_2)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1cq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_3, K_0)
		msg_0 = arm.vsha1su1q_u32(msg_0, msg_3)
		msg_1 = arm.vsha1su0q_u32(msg_1, msg_2, msg_3)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1cq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_0, K_0)
		msg_1 = arm.vsha1su1q_u32(msg_1, msg_0)
		msg_2 = arm.vsha1su0q_u32(msg_2, msg_3, msg_0)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1cq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_1, K_1)
		msg_2 = arm.vsha1su1q_u32(msg_2, msg_1)
		msg_3 = arm.vsha1su0q_u32(msg_3, msg_0, msg_1)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1cq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_2, K_1)
		msg_3 = arm.vsha1su1q_u32(msg_3, msg_2)
		msg_0 = arm.vsha1su0q_u32(msg_0, msg_1, msg_2)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_3, K_1)
		msg_0 = arm.vsha1su1q_u32(msg_0, msg_3)
		msg_1 = arm.vsha1su0q_u32(msg_1, msg_2, msg_3)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_0, K_1)
		msg_1 = arm.vsha1su1q_u32(msg_1, msg_0)
		msg_2 = arm.vsha1su0q_u32(msg_2, msg_3, msg_0)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_1, K_1)
		msg_2 = arm.vsha1su1q_u32(msg_2, msg_1)
		msg_3 = arm.vsha1su0q_u32(msg_3, msg_0, msg_1)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_2, K_2)
		msg_3 = arm.vsha1su1q_u32(msg_3, msg_2)
		msg_0 = arm.vsha1su0q_u32(msg_0, msg_1, msg_2)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_3, K_2)
		msg_0 = arm.vsha1su1q_u32(msg_0, msg_3)
		msg_1 = arm.vsha1su0q_u32(msg_1, msg_2, msg_3)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1mq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_0, K_2)
		msg_1 = arm.vsha1su1q_u32(msg_1, msg_0)
		msg_2 = arm.vsha1su0q_u32(msg_2, msg_3, msg_0)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1mq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_1, K_2)
		msg_2 = arm.vsha1su1q_u32(msg_2, msg_1)
		msg_3 = arm.vsha1su0q_u32(msg_3, msg_0, msg_1)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1mq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_2, K_2)
		msg_3 = arm.vsha1su1q_u32(msg_3, msg_2)
		msg_0 = arm.vsha1su0q_u32(msg_0, msg_1, msg_2)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1mq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_3, K_3)
		msg_0 = arm.vsha1su1q_u32(msg_0, msg_3)
		msg_1 = arm.vsha1su0q_u32(msg_1, msg_2, msg_3)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1mq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_0, K_3)
		msg_1 = arm.vsha1su1q_u32(msg_1, msg_0)
		msg_2 = arm.vsha1su0q_u32(msg_2, msg_3, msg_0)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_1, K_3)
		msg_2 = arm.vsha1su1q_u32(msg_2, msg_1)
		msg_3 = arm.vsha1su0q_u32(msg_3, msg_0, msg_1)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_0, tmp_0)
		tmp_0 = simd.add(msg_2, K_3)
		msg_3 = arm.vsha1su1q_u32(msg_3, msg_2)
		msg_0 = arm.vsha1su0q_u32(msg_0, msg_1, msg_2)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_1, tmp_1)
		tmp_1 = simd.add(msg_3, K_3)
		msg_0 = arm.vsha1su1q_u32(msg_0, msg_3)

		e_1 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_0, tmp_0)

		e_0 = arm.vsha1h_u32(arm.vgetq_lane_u32(abcd, 0))
		abcd = arm.vsha1pq_u32(abcd, e_1, tmp_1)

		e_0 += e_0_save
		abcd = simd.add(abcd_save, abcd)

		data = data[BLOCK_SIZE:]
	}

	intrinsics.unaligned_store((^simd.u32x4)(&ctx.state[0]), abcd)
	ctx.state[4] = e_0
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
