// The round function's intrinsic calls are based on:
// https://github.com/LostInCompilation/HashMe/blob/main/src/SHA512_Hardware.cpp
//
//     The zlib License
//
//     Copyright (C) 2024 Marc Schöndorf
//
// This software is provided 'as-is', without any express or implied warranty. In
// no event will the authors be held liable for any damages arising from the use of
// this software.
//
// Permission is granted to anyone to use this software for any purpose, including
// commercial applications, and to alter it and redistribute it freely, subject to
// the following restrictions:
//
// 1.  The origin of this software must not be misrepresented; you must not claim
//     that you wrote the original software. If you use this software in a product,
//     an acknowledgment in the product documentation would be appreciated but is
//     not required.
//
// 2.  Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
// 3.  This notice may not be removed or altered from any source distribution.

#+build arm64
package sha2

import "base:intrinsics"
import "core:simd"
import "core:simd/arm"
import "core:sys/info"

// is_hardware_accelerated_512 returns true if and only if (⟺) hardware
// accelerated SHA-384, SHA-512, and SHA-512/256 are supported.
is_hardware_accelerated_512 :: proc "contextless" () -> bool {
	req_features :: info.CPU_Features{
		.asimd,
		.sha512,
		.sha3, // XXX: LLVM groups these under `sha3`.
	}
	return info.cpu_features() >= req_features
}

@(private = "file")
K_0 :: simd.u64x2{0x428a2f98d728ae22, 0x7137449123ef65cd}
@(private = "file")
K_1 :: simd.u64x2{0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc}
@(private = "file")
K_2 :: simd.u64x2{0x3956c25bf348b538, 0x59f111f1b605d019}
@(private = "file")
K_3 :: simd.u64x2{0x923f82a4af194f9b, 0xab1c5ed5da6d8118}
@(private = "file")
K_4 :: simd.u64x2{0xd807aa98a3030242, 0x12835b0145706fbe}
@(private = "file")
K_5 :: simd.u64x2{0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2}
@(private = "file")
K_6 :: simd.u64x2{0x72be5d74f27b896f, 0x80deb1fe3b1696b1}
@(private = "file")
K_7 :: simd.u64x2{0x9bdc06a725c71235, 0xc19bf174cf692694}
@(private = "file")
K_8 :: simd.u64x2{0xe49b69c19ef14ad2, 0xefbe4786384f25e3}
@(private = "file")
K_9 :: simd.u64x2{0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65}
@(private = "file")
K_10 :: simd.u64x2{0x2de92c6f592b0275, 0x4a7484aa6ea6e483}
@(private = "file")
K_11 :: simd.u64x2{0x5cb0a9dcbd41fbd4, 0x76f988da831153b5}
@(private = "file")
K_12 :: simd.u64x2{0x983e5152ee66dfab, 0xa831c66d2db43210}
@(private = "file")
K_13 :: simd.u64x2{0xb00327c898fb213f, 0xbf597fc7beef0ee4}
@(private = "file")
K_14 :: simd.u64x2{0xc6e00bf33da88fc2, 0xd5a79147930aa725}
@(private = "file")
K_15 :: simd.u64x2{0x06ca6351e003826f, 0x142929670a0e6e70}
@(private = "file")
K_16 :: simd.u64x2{0x27b70a8546d22ffc, 0x2e1b21385c26c926}
@(private = "file")
K_17 :: simd.u64x2{0x4d2c6dfc5ac42aed, 0x53380d139d95b3df}
@(private = "file")
K_18 :: simd.u64x2{0x650a73548baf63de, 0x766a0abb3c77b2a8}
@(private = "file")
K_19 :: simd.u64x2{0x81c2c92e47edaee6, 0x92722c851482353b}
@(private = "file")
K_20 :: simd.u64x2{0xa2bfe8a14cf10364, 0xa81a664bbc423001}
@(private = "file")
K_21 :: simd.u64x2{0xc24b8b70d0f89791, 0xc76c51a30654be30}
@(private = "file")
K_22 :: simd.u64x2{0xd192e819d6ef5218, 0xd69906245565a910}
@(private = "file")
K_23 :: simd.u64x2{0xf40e35855771202a, 0x106aa07032bbd1b8}
@(private = "file")
K_24 :: simd.u64x2{0x19a4c116b8d2d0c8, 0x1e376c085141ab53}
@(private = "file")
K_25 :: simd.u64x2{0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8}
@(private = "file")
K_26 :: simd.u64x2{0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb}
@(private = "file")
K_27 :: simd.u64x2{0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3}
@(private = "file")
K_28 :: simd.u64x2{0x748f82ee5defb2fc, 0x78a5636f43172f60}
@(private = "file")
K_29 :: simd.u64x2{0x84c87814a1f0ab72, 0x8cc702081a6439ec}
@(private = "file")
K_30 :: simd.u64x2{0x90befffa23631e28, 0xa4506cebde82bde9}
@(private = "file")
K_31 :: simd.u64x2{0xbef9a3f7b2c67915, 0xc67178f2e372532b}
@(private = "file")
K_32 :: simd.u64x2{0xca273eceea26619c, 0xd186b8c721c0c207}
@(private = "file")
K_33 :: simd.u64x2{0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178}
@(private = "file")
K_34 :: simd.u64x2{0x06f067aa72176fba, 0x0a637dc5a2c898a6}
@(private = "file")
K_35 :: simd.u64x2{0x113f9804bef90dae, 0x1b710b35131c471b}
@(private = "file")
K_36 :: simd.u64x2{0x28db77f523047d84, 0x32caab7b40c72493}
@(private = "file")
K_37 :: simd.u64x2{0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c}
@(private = "file")
K_38 :: simd.u64x2{0x4cc5d4becb3e42b6, 0x597f299cfc657e2a}
@(private = "file")
K_39 :: simd.u64x2{0x5fcb6fab3ad6faec, 0x6c44198c4a475817}

@(private, enable_target_feature = "neon,sha3")
sha512_transf_hw :: proc "contextless" (ctx: ^Context_512, data: []byte) #no_bounds_check {
	state_0 := intrinsics.unaligned_load((^simd.u64x2)(&ctx.h[0]))
	state_1 := intrinsics.unaligned_load((^simd.u64x2)(&ctx.h[2]))
	state_2 := intrinsics.unaligned_load((^simd.u64x2)(&ctx.h[4]))
	state_3 := intrinsics.unaligned_load((^simd.u64x2)(&ctx.h[6]))

	data := data
	for len(data) >= BLOCK_SIZE_512 {
		ab_save, cd_save, ef_save, gh_save := state_0, state_1, state_2, state_3

		// Load message
		msg_0 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data)))
		msg_1 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[16:])))
		msg_2 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[32:])))
		msg_3 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[48:])))
		msg_4 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[64:])))
		msg_5 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[80:])))
		msg_6 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[96:])))
		msg_7 := intrinsics.unaligned_load((^simd.u64x2)(raw_data(data[112:])))

		// Reverse for little endian
		when ODIN_ENDIAN == .Little {
			msg_0 = byteswap_u64x2(msg_0)
			msg_1 = byteswap_u64x2(msg_1)
			msg_2 = byteswap_u64x2(msg_2)
			msg_3 = byteswap_u64x2(msg_3)
			msg_4 = byteswap_u64x2(msg_4)
			msg_5 = byteswap_u64x2(msg_5)
			msg_6 = byteswap_u64x2(msg_6)
			msg_7 = byteswap_u64x2(msg_7)
		}

		// Rounds 0-1
		msg_k := simd.add(msg_0, K_0)
		tmp_0 := simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 := arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_0 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_0, msg_1), msg_7, simd.shuffle(msg_4, msg_5, 1, 2))

		// Rounds 2-3
		msg_k = simd.add(msg_1, K_1)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_1 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_1, msg_2), msg_0, simd.shuffle(msg_5, msg_6, 1, 2))

		// Rounds 4-5
		msg_k = simd.add(msg_2, K_2)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_2 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_2, msg_3), msg_1, simd.shuffle(msg_6, msg_7, 1, 2))

		// Rounds 6-7
		msg_k = simd.add(msg_3, K_3)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_3 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_3, msg_4), msg_2, simd.shuffle(msg_7, msg_0, 1, 2))

		// Rounds 8-9
		msg_k = simd.add(msg_4, K_4)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_4 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_4, msg_5), msg_3, simd.shuffle(msg_0, msg_1, 1, 2))

		// Rounds 10-11
		msg_k = simd.add(msg_5, K_5)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_5 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_5, msg_6), msg_4, simd.shuffle(msg_1, msg_2, 1, 2))

		// Rounds 12-13
		msg_k = simd.add(msg_6, K_6)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_6 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_6, msg_7), msg_5, simd.shuffle(msg_2, msg_3, 1, 2))

		// Rounds 14-15
		msg_k = simd.add(msg_7, K_7)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_7 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_7, msg_0), msg_6, simd.shuffle(msg_3, msg_4, 1, 2))

		// Rounds 16-17
		msg_k = simd.add(msg_0, K_8)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_0 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_0, msg_1), msg_7, simd.shuffle(msg_4, msg_5, 1, 2))

		// Rounds 18-19
		msg_k = simd.add(msg_1, K_9)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_1 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_1, msg_2), msg_0, simd.shuffle(msg_5, msg_6, 1, 2))

		// Rounds 20-21
		msg_k = simd.add(msg_2, K_10)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_2 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_2, msg_3), msg_1, simd.shuffle(msg_6, msg_7, 1, 2))

		// Rounds 22-23
		msg_k = simd.add(msg_3, K_11)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_3 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_3, msg_4), msg_2, simd.shuffle(msg_7, msg_0, 1, 2))

		// Rounds 24-25
		msg_k = simd.add(msg_4, K_12)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_4 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_4, msg_5), msg_3, simd.shuffle(msg_0, msg_1, 1, 2))

		// Rounds 26-27
		msg_k = simd.add(msg_5, K_13)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_5 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_5, msg_6), msg_4, simd.shuffle(msg_1, msg_2, 1, 2))

		// Rounds 28-29
		msg_k = simd.add(msg_6, K_14)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_6 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_6, msg_7), msg_5, simd.shuffle(msg_2, msg_3, 1, 2))

		// Rounds 30-31
		msg_k = simd.add(msg_7, K_15)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_7 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_7, msg_0), msg_6, simd.shuffle(msg_3, msg_4, 1, 2))

		// Rounds 32-33
		msg_k = simd.add(msg_0, K_16)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_0 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_0, msg_1), msg_7, simd.shuffle(msg_4, msg_5, 1, 2))

		// Rounds 34-35
		msg_k = simd.add(msg_1, K_17)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_1 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_1, msg_2), msg_0, simd.shuffle(msg_5, msg_6, 1, 2))

		// Rounds 36-37
		msg_k = simd.add(msg_2, K_18)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_2 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_2, msg_3), msg_1, simd.shuffle(msg_6, msg_7, 1, 2))

		// Rounds 38-39
		msg_k = simd.add(msg_3, K_19)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_3 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_3, msg_4), msg_2, simd.shuffle(msg_7, msg_0, 1, 2))

		// Rounds 40-41
		msg_k = simd.add(msg_4, K_20)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_4 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_4, msg_5), msg_3, simd.shuffle(msg_0, msg_1, 1, 2))

		// Rounds 42-43
		msg_k = simd.add(msg_5, K_21)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_5 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_5, msg_6), msg_4, simd.shuffle(msg_1, msg_2, 1, 2))

		// Rounds 44-45
		msg_k = simd.add(msg_6, K_22)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_6 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_6, msg_7), msg_5, simd.shuffle(msg_2, msg_3, 1, 2))

		// Rounds 46-47
		msg_k = simd.add(msg_7, K_23)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_7 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_7, msg_0), msg_6, simd.shuffle(msg_3, msg_4, 1, 2))

		// Rounds 48-49
		msg_k = simd.add(msg_0, K_24)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_0 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_0, msg_1), msg_7, simd.shuffle(msg_4, msg_5, 1, 2))

		// Rounds 50-51
		msg_k = simd.add(msg_1, K_25)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_1 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_1, msg_2), msg_0, simd.shuffle(msg_5, msg_6, 1, 2))

		// Rounds 52-53
		msg_k = simd.add(msg_2, K_26)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_2 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_2, msg_3), msg_1, simd.shuffle(msg_6, msg_7, 1, 2))

		// Rounds 54-55
		msg_k = simd.add(msg_3, K_27)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_3 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_3, msg_4), msg_2, simd.shuffle(msg_7, msg_0, 1, 2))

		// Rounds 56-57
		msg_k = simd.add(msg_4, K_28)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)
		msg_4 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_4, msg_5), msg_3, simd.shuffle(msg_0, msg_1, 1, 2))

		// Rounds 58-59
		msg_k = simd.add(msg_5, K_29)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)
		msg_5 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_5, msg_6), msg_4, simd.shuffle(msg_1, msg_2, 1, 2))

		// Rounds 60-61
		msg_k = simd.add(msg_6, K_30)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)
		msg_6 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_6, msg_7), msg_5, simd.shuffle(msg_2, msg_3, 1, 2))

		// Rounds 62-63
		msg_k = simd.add(msg_7, K_31)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)
		msg_7 = arm.vsha512su1q_u64(arm.vsha512su0q_u64(msg_7, msg_0), msg_6, simd.shuffle(msg_3, msg_4, 1, 2))

		// Rounds 64-65
		msg_k = simd.add(msg_0, K_32)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)

		// Rounds 66-67
		msg_k = simd.add(msg_1, K_33)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)

		// Rounds 68-69
		msg_k = simd.add(msg_2, K_34)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)

		// Rounds 70-71
		msg_k = simd.add(msg_3, K_35)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)

		// Rounds 72-73
		msg_k = simd.add(msg_4, K_36)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_3)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_2, state_3, 1, 2), simd.shuffle(state_1, state_2, 1, 2))
		state_3 = arm.vsha512h2q_u64(tmp_1, state_1, state_0)
		state_1 = simd.add(state_1, tmp_1)

		// Rounds 74-75
		msg_k = simd.add(msg_5, K_37)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_2)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_1, state_2, 1, 2), simd.shuffle(state_0, state_1, 1, 2))
		state_2 = arm.vsha512h2q_u64(tmp_1, state_0, state_3)
		state_0 = simd.add(state_0, tmp_1)

		// Rounds 76-77
		msg_k = simd.add(msg_6, K_38)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_1)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_0, state_1, 1, 2), simd.shuffle(state_3, state_0, 1, 2))
		state_1 = arm.vsha512h2q_u64(tmp_1, state_3, state_2)
		state_3 = simd.add(state_3, tmp_1)

		// Rounds 78-79
		msg_k = simd.add(msg_7, K_39)
		tmp_0 = simd.add(simd.shuffle(msg_k, msg_k, 1, 2), state_0)
		tmp_1 = arm.vsha512hq_u64(tmp_0, simd.shuffle(state_3, state_0, 1, 2), simd.shuffle(state_2, state_3, 1, 2))
		state_0 = arm.vsha512h2q_u64(tmp_1, state_2, state_1)
		state_2 = simd.add(state_2, tmp_1)

		// Combine state
		state_0 = simd.add(state_0, ab_save)
		state_1 = simd.add(state_1, cd_save)
		state_2 = simd.add(state_2, ef_save)
		state_3 = simd.add(state_3, gh_save)

		data = data[BLOCK_SIZE_512:]
	}

	intrinsics.unaligned_store((^simd.u64x2)(&ctx.h[0]), state_0)
	intrinsics.unaligned_store((^simd.u64x2)(&ctx.h[2]), state_1)
	intrinsics.unaligned_store((^simd.u64x2)(&ctx.h[4]), state_2)
	intrinsics.unaligned_store((^simd.u64x2)(&ctx.h[6]), state_3)
}

when ODIN_ENDIAN == .Little {
	@(private = "file", enable_target_feature = "neon")
	byteswap_u64x2 :: #force_inline proc "contextless" (a: simd.u64x2) -> simd.u64x2 {
		return transmute(simd.u64x2)(
			simd.shuffle(
				transmute(simd.u8x16)(a),
				transmute(simd.u8x16)(a),
				7, 6, 5, 4, 3, 2, 1, 0,
				15, 14, 13, 12, 11, 10, 9, 8,
			)
		)
	}
}
