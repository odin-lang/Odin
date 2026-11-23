#+build amd64
package sha1

// Based on the public domain code by Jeffrey Walton, though
// realistically, there only is one sensible way to write this
// and Intel's whitepaper covers it.
//
// See: https://github.com/noloader/SHA-Intrinsics

import "base:intrinsics"
import "core:simd/x86"
import "core:sys/info"

@(private = "file")
MASK :: x86.__m128i{0x08090a0b0c0d0e0f, 0x0001020304050607}

// is_hardware_accelerated returns true if and only if (⟺) hardware accelerated
// SHA-1 is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	req_features :: info.CPU_Features{
		.sse2,
		.ssse3,
		.sse41,
		.sha,
	}
	return info.cpu_features() >= req_features
}

@(private, enable_target_feature="sse2,ssse3,sse4.1,sha")
sha1_transf_hw :: proc "contextless" (ctx: ^Context, data: []byte) #no_bounds_check {
	abcd := intrinsics.unaligned_load((^x86.__m128i)(&ctx.state[0]))
	e_0 := x86._mm_set_epi32(i32(ctx.state[4]), 0, 0, 0)
	abcd = x86._mm_shuffle_epi32(abcd, 0x1b)

	data := data
	for len(data) >= BLOCK_SIZE {
		abcd_save, e_0_save := abcd, e_0

		msg_0 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data)))
		msg_0 = x86._mm_shuffle_epi8(msg_0, MASK)
		e_0 = x86._mm_add_epi32(e_0, msg_0)
		e_1 := abcd
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 0)

		msg_1 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data[16:])))
		msg_1 = x86._mm_shuffle_epi8(msg_1, MASK)
		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_1)
		e_0 = abcd
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 0)
		msg_0 = x86._mm_sha1msg1_epu32(msg_0, msg_1)

		msg_2 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data[32:])))
		msg_2 = x86._mm_shuffle_epi8(msg_2, MASK)
		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_2)
		e_1 = abcd
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 0)
		msg_1 = x86._mm_sha1msg1_epu32(msg_1, msg_2)
		msg_0 = x86._mm_xor_si128(msg_0, msg_2)

		msg_3 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data[48:])))
		msg_3 = x86._mm_shuffle_epi8(msg_3, MASK)
		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_3)
		e_0 = abcd
		msg_0 = x86._mm_sha1msg2_epu32(msg_0, msg_3)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 0)
		msg_2 = x86._mm_sha1msg1_epu32(msg_2, msg_3)
		msg_1 = x86._mm_xor_si128(msg_1, msg_3)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_0)
		e_1 = abcd
		msg_1 = x86._mm_sha1msg2_epu32(msg_1, msg_0)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 0)
		msg_3 = x86._mm_sha1msg1_epu32(msg_3, msg_0)
		msg_2 = x86._mm_xor_si128(msg_2, msg_0)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_1)
		e_0 = abcd
		msg_2 = x86._mm_sha1msg2_epu32(msg_2, msg_1)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 1)
		msg_0 = x86._mm_sha1msg1_epu32(msg_0, msg_1)
		msg_3 = x86._mm_xor_si128(msg_3, msg_1)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_2)
		e_1 = abcd
		msg_3 = x86._mm_sha1msg2_epu32(msg_3, msg_2)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 1)
		msg_1 = x86._mm_sha1msg1_epu32(msg_1, msg_2)
		msg_0 = x86._mm_xor_si128(msg_0, msg_2)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_3)
		e_0 = abcd
		msg_0 = x86._mm_sha1msg2_epu32(msg_0, msg_3)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 1)
		msg_2 = x86._mm_sha1msg1_epu32(msg_2, msg_3)
		msg_1 = x86._mm_xor_si128(msg_1, msg_3)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_0)
		e_1 = abcd
		msg_1 = x86._mm_sha1msg2_epu32(msg_1, msg_0)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 1)
		msg_3 = x86._mm_sha1msg1_epu32(msg_3, msg_0)
		msg_2 = x86._mm_xor_si128(msg_2, msg_0)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_1)
		e_0 = abcd
		msg_2 = x86._mm_sha1msg2_epu32(msg_2, msg_1)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 1)
		msg_0 = x86._mm_sha1msg1_epu32(msg_0, msg_1)
		msg_3 = x86._mm_xor_si128(msg_3, msg_1)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_2)
		e_1 = abcd
		msg_3 = x86._mm_sha1msg2_epu32(msg_3, msg_2)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 2)
		msg_1 = x86._mm_sha1msg1_epu32(msg_1, msg_2)
		msg_0 = x86._mm_xor_si128(msg_0, msg_2)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_3)
		e_0 = abcd
		msg_0 = x86._mm_sha1msg2_epu32(msg_0, msg_3)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 2)
		msg_2 = x86._mm_sha1msg1_epu32(msg_2, msg_3)
		msg_1 = x86._mm_xor_si128(msg_1, msg_3)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_0)
		e_1 = abcd
		msg_1 = x86._mm_sha1msg2_epu32(msg_1, msg_0)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 2)
		msg_3 = x86._mm_sha1msg1_epu32(msg_3, msg_0)
		msg_2 = x86._mm_xor_si128(msg_2, msg_0)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_1)
		e_0 = abcd
		msg_2 = x86._mm_sha1msg2_epu32(msg_2, msg_1)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 2)
		msg_0 = x86._mm_sha1msg1_epu32(msg_0, msg_1)
		msg_3 = x86._mm_xor_si128(msg_3, msg_1)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_2)
		e_1 = abcd
		msg_3 = x86._mm_sha1msg2_epu32(msg_3, msg_2)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 2)
		msg_1 = x86._mm_sha1msg1_epu32(msg_1, msg_2)
		msg_0 = x86._mm_xor_si128(msg_0, msg_2)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_3)
		e_0 = abcd
		msg_0 = x86._mm_sha1msg2_epu32(msg_0, msg_3)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 3)
		msg_2 = x86._mm_sha1msg1_epu32(msg_2, msg_3)
		msg_1 = x86._mm_xor_si128(msg_1, msg_3)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_0)
		e_1 = abcd
		msg_1 = x86._mm_sha1msg2_epu32(msg_1, msg_0)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 3)
		msg_3 = x86._mm_sha1msg1_epu32(msg_3, msg_0)
		msg_2 = x86._mm_xor_si128(msg_2, msg_0)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_1)
		e_0 = abcd
		msg_2 = x86._mm_sha1msg2_epu32(msg_2, msg_1)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 3)
		msg_3 = x86._mm_xor_si128(msg_3, msg_1)

		e_0 = x86._mm_sha1nexte_epu32(e_0, msg_2)
		e_1 = abcd
		msg_3 = x86._mm_sha1msg2_epu32(msg_3, msg_2)
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_0, 3)

		e_1 = x86._mm_sha1nexte_epu32(e_1, msg_3)
		e_0 = abcd
		abcd = x86._mm_sha1rnds4_epu32(abcd, e_1, 3)

		e_0 = x86._mm_sha1nexte_epu32(e_0, e_0_save)
		abcd = x86._mm_add_epi32(abcd, abcd_save)

		data = data[BLOCK_SIZE:]
	}

	abcd = x86._mm_shuffle_epi32(abcd, 0x1b)
	intrinsics.unaligned_store((^x86.__m128i)(&ctx.state[0]), abcd)
	ctx.state[4] = u32(x86._mm_extract_epi32(e_0, 3))
}
