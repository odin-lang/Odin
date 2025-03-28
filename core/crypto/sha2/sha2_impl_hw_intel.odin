#+build amd64
package sha2

// Based on the public domain code by Jeffrey Walton, though
// realistically, there only is one sensible way to write this
// and Intel's whitepaper covers it.
//
// See: https://github.com/noloader/SHA-Intrinsics

import "base:intrinsics"
import "core:simd"
import "core:simd/x86"
import "core:sys/info"

@(private = "file")
MASK :: x86.__m128i{0x0405060700010203, 0x0c0d0e0f08090a0b}

@(private = "file")
K_0 :: simd.u64x2{0x71374491428a2f98, 0xe9b5dba5b5c0fbcf}
@(private = "file")
K_1 :: simd.u64x2{0x59f111f13956c25b, 0xab1c5ed5923f82a4}
@(private = "file")
K_2 :: simd.u64x2{0x12835b01d807aa98, 0x550c7dc3243185be}
@(private = "file")
K_3 :: simd.u64x2{0x80deb1fe72be5d74, 0xc19bf1749bdc06a7}
@(private = "file")
K_4 :: simd.u64x2{0xefbe4786e49b69c1, 0x240ca1cc0fc19dc6}
@(private = "file")
K_5 :: simd.u64x2{0x4a7484aa2de92c6f, 0x76f988da5cb0a9dc}
@(private = "file")
K_6 :: simd.u64x2{0xa831c66d983e5152, 0xbf597fc7b00327c8}
@(private = "file")
K_7 :: simd.u64x2{0xd5a79147c6e00bf3, 0x1429296706ca6351}
@(private = "file")
K_8 :: simd.u64x2{0x2e1b213827b70a85, 0x53380d134d2c6dfc}
@(private = "file")
K_9 :: simd.u64x2{0x766a0abb650a7354, 0x92722c8581c2c92e}
@(private = "file")
K_10 :: simd.u64x2{0xa81a664ba2bfe8a1, 0xc76c51a3c24b8b70}
@(private = "file")
K_11 :: simd.u64x2{0xd6990624d192e819, 0x106aa070f40e3585}
@(private = "file")
K_12 :: simd.u64x2{0x1e376c0819a4c116, 0x34b0bcb52748774c}
@(private = "file")
K_13 :: simd.u64x2{0x4ed8aa4a391c0cb3, 0x682e6ff35b9cca4f}
@(private = "file")
K_14 :: simd.u64x2{0x78a5636f748f82ee, 0x8cc7020884c87814}
@(private = "file")
K_15 :: simd.u64x2{0xa4506ceb90befffa, 0xc67178f2bef9a3f7}


// is_hardware_accelerated_256 returns true iff hardware accelerated
// SHA-224/SHA-256 is supported.
is_hardware_accelerated_256 :: proc "contextless" () -> bool {
	features, ok := info.cpu_features.?
	if !ok {
		return false
	}

	req_features :: info.CPU_Features{
		.sse2,
		.ssse3,
		.sse41,
		.sha,
	}
	return features >= req_features
}

@(private, enable_target_feature="sse2,ssse3,sse4.1,sha")
sha256_transf_hw :: proc "contextless" (ctx: ^Context_256, data: []byte) #no_bounds_check {
	// Load the state
	tmp := intrinsics.unaligned_load((^x86.__m128i)(&ctx.h[0]))
	state_1 := intrinsics.unaligned_load((^x86.__m128i)(&ctx.h[4]))

	tmp = x86._mm_shuffle_epi32(tmp, 0xb1)            // CDAB
	state_1 = x86._mm_shuffle_epi32(state_1, 0x1b)    // EFGH
	state_0 := x86._mm_alignr_epi8(tmp, state_1, 8)   // ABEF
	// state_1 = x86._mm_blend_epi16(state_1, tmp, 0xf0) // CDGH
	state_1 = kludge_mm_blend_epi16_0xf0(state_1, tmp)

	data := data
	for len(data) >= BLOCK_SIZE_256 {
		state_0_save, state_1_save := state_0, state_1

		// Rounds 0-3
		msg := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data)))
		msg_0 := x86._mm_shuffle_epi8(msg, MASK)
		msg = x86._mm_add_epi32(msg_0, x86.__m128i(K_0))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		msg = x86._mm_shuffle_epi32(msg, 0xe)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)

		// Rounds 4-7
		msg_1 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data[16:])))
		msg_1 = x86._mm_shuffle_epi8(msg_1, MASK)
		msg = x86._mm_add_epi32(msg_1, x86.__m128i(K_1))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		msg = x86._mm_shuffle_epi32(msg, 0xe)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_0 = x86._mm_sha256msg1_epu32(msg_0, msg_1)

		// Rounds 8-11
		msg_2 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data[32:])))
		msg_2 = x86._mm_shuffle_epi8(msg_2, MASK)
		msg = x86._mm_add_epi32(msg_2, x86.__m128i(K_2))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		msg = x86._mm_shuffle_epi32(msg, 0xe)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_1 = x86._mm_sha256msg1_epu32(msg_1, msg_2)

		// Rounds 12-15
		msg_3 := intrinsics.unaligned_load((^x86.__m128i)(raw_data(data[48:])))
		msg_3 = x86._mm_shuffle_epi8(msg_3, MASK)
		msg = x86._mm_add_epi32(msg_3, x86.__m128i(K_3))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_3, msg_2, 4)
		msg_0 = x86._mm_add_epi32(msg_0, tmp)
		msg_0 = x86._mm_sha256msg2_epu32(msg_0, msg_3)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_2 = x86._mm_sha256msg1_epu32(msg_2, msg_3)

		// Rounds 16-19
		msg = x86._mm_add_epi32(msg_0, x86.__m128i(K_4))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_0, msg_3, 4)
		msg_1 = x86._mm_add_epi32(msg_1, tmp)
		msg_1 = x86._mm_sha256msg2_epu32(msg_1, msg_0)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_3 = x86._mm_sha256msg1_epu32(msg_3, msg_0)

		// Rounds 20-23
		msg = x86._mm_add_epi32(msg_1, x86.__m128i(K_5))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_1, msg_0, 4)
		msg_2 = x86._mm_add_epi32(msg_2, tmp)
		msg_2 = x86._mm_sha256msg2_epu32(msg_2, msg_1)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_0 = x86._mm_sha256msg1_epu32(msg_0, msg_1)

		// Rounds 24-27
		msg = x86._mm_add_epi32(msg_2, x86.__m128i(K_6))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_2, msg_1, 4)
		msg_3 = x86._mm_add_epi32(msg_3, tmp)
		msg_3 = x86._mm_sha256msg2_epu32(msg_3, msg_2)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_1 = x86._mm_sha256msg1_epu32(msg_1, msg_2)

		// Rounds 28-31
		msg = x86._mm_add_epi32(msg_3, x86.__m128i(K_7))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_3, msg_2, 4)
		msg_0 = x86._mm_add_epi32(msg_0, tmp)
		msg_0 = x86._mm_sha256msg2_epu32(msg_0, msg_3)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_2 = x86._mm_sha256msg1_epu32(msg_2, msg_3)

		// Rounds 32-35
		msg = x86._mm_add_epi32(msg_0, x86.__m128i(K_8))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_0, msg_3, 4)
		msg_1 = x86._mm_add_epi32(msg_1, tmp)
		msg_1 = x86._mm_sha256msg2_epu32(msg_1, msg_0)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_3 = x86._mm_sha256msg1_epu32(msg_3, msg_0)

		// Rounds 36-39
		msg = x86._mm_add_epi32(msg_1, x86.__m128i(K_9))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_1, msg_0, 4)
		msg_2 = x86._mm_add_epi32(msg_2, tmp)
		msg_2 = x86._mm_sha256msg2_epu32(msg_2, msg_1)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_0 = x86._mm_sha256msg1_epu32(msg_0, msg_1)

		// Rounds 40-43
		msg = x86._mm_add_epi32(msg_2, x86.__m128i(K_10))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_2, msg_1, 4)
		msg_3 = x86._mm_add_epi32(msg_3, tmp)
		msg_3 = x86._mm_sha256msg2_epu32(msg_3, msg_2)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_1 = x86._mm_sha256msg1_epu32(msg_1, msg_2)

		// Rounds 44-47
		msg = x86._mm_add_epi32(msg_3, x86.__m128i(K_11))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_3, msg_2, 4)
		msg_0 = x86._mm_add_epi32(msg_0, tmp)
		msg_0 = x86._mm_sha256msg2_epu32(msg_0, msg_3)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_2 = x86._mm_sha256msg1_epu32(msg_2, msg_3)

		// Rounds 48-51
		msg = x86._mm_add_epi32(msg_0, x86.__m128i(K_12))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_0, msg_3, 4)
		msg_1 = x86._mm_add_epi32(msg_1, tmp)
		msg_1 = x86._mm_sha256msg2_epu32(msg_1, msg_0)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)
		msg_3 = x86._mm_sha256msg1_epu32(msg_3, msg_0)

		// Rounds 52-55
		msg = x86._mm_add_epi32(msg_1, x86.__m128i(K_13))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_1, msg_0, 4)
		msg_2 = x86._mm_add_epi32(msg_2, tmp)
		msg_2 = x86._mm_sha256msg2_epu32(msg_2, msg_1)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)

		/* Rounds 56-59 */
		msg = x86._mm_add_epi32(msg_2, x86.__m128i(K_14))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		tmp = x86._mm_alignr_epi8(msg_2, msg_1, 4)
		msg_3 = x86._mm_add_epi32(msg_3, tmp)
		msg_3 = x86._mm_sha256msg2_epu32(msg_3, msg_2)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)

		// Rounds 60-63
		msg = x86._mm_add_epi32(msg_3, x86.__m128i(K_15))
		state_1 = x86._mm_sha256rnds2_epu32(state_1, state_0, msg)
		msg = x86._mm_shuffle_epi32(msg, 0x0e)
		state_0 = x86._mm_sha256rnds2_epu32(state_0, state_1, msg)

		state_0 = x86._mm_add_epi32(state_0, state_0_save)
		state_1 = x86._mm_add_epi32(state_1, state_1_save)

		data = data[BLOCK_SIZE_256:]
	}

	// Write back the updated state
	tmp = x86._mm_shuffle_epi32(state_0, 0x1b)        // FEBA
	state_1 = x86._mm_shuffle_epi32(state_1, 0xb1)    // DCHG
	// state_0 = x86._mm_blend_epi16(tmp, state_1, 0xf0) // DCBA
	state_0 = kludge_mm_blend_epi16_0xf0(tmp, state_1)
	state_1 = x86._mm_alignr_epi8(state_1, tmp, 8)    // ABEF

	intrinsics.unaligned_store((^x86.__m128i)(&ctx.h[0]), state_0)
	intrinsics.unaligned_store((^x86.__m128i)(&ctx.h[4]), state_1)
}

@(private = "file")
kludge_mm_blend_epi16_0xf0 :: #force_inline proc "contextless"(a, b: x86.__m128i) -> x86.__m128i {
	// HACK HACK HACK: LLVM got rid of `llvm.x86.sse41.pblendw`.
	a_ := simd.to_array(a)
	b_ := simd.to_array(b)
	return x86.__m128i{a_[0], b_[1]}
}
