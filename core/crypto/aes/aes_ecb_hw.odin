#+build amd64,arm64,arm32
package aes

import "base:intrinsics"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:simd"


@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
encrypt_block_hw :: proc(ctx: ^Context_Impl_Hardware, dst, src: []byte) {
	blk := intrinsics.unaligned_load((^simd.u8x16)(raw_data(src)))

	blk = simd.bit_xor(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[0])))
	#unroll for i in 1 ..= 9 {
		blk = aes_hw.aesenc(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[i])))
	}
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		blk = aes_hw.aesenclast(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[10])))
	case _aes.ROUNDS_192:
		#unroll for i in 10 ..= 11 {
			blk = aes_hw.aesenc(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[i])))
		}
		blk = aes_hw.aesenclast(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[12])))
	case _aes.ROUNDS_256:
		#unroll for i in 10 ..= 13 {
			blk = aes_hw.aesenc(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[i])))
		}
		blk = aes_hw.aesenclast(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[14])))
	}

	intrinsics.unaligned_store((^simd.u8x16)(raw_data(dst)), blk)
}

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
decrypt_block_hw :: proc(ctx: ^Context_Impl_Hardware, dst, src: []byte) {
	blk := intrinsics.unaligned_load((^simd.u8x16)(raw_data(src)))

	blk = simd.bit_xor(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[0])))
	#unroll for i in 1 ..= 9 {
		blk = aes_hw.aesdec(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[i])))
	}
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		blk = aes_hw.aesdeclast(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[10])))
	case _aes.ROUNDS_192:
		#unroll for i in 10 ..= 11 {
			blk = aes_hw.aesdec(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[i])))
		}
		blk = aes_hw.aesdeclast(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[12])))
	case _aes.ROUNDS_256:
		#unroll for i in 10 ..= 13 {
			blk = aes_hw.aesdec(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[i])))
		}
		blk = aes_hw.aesdeclast(blk, intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[14])))
	}

	intrinsics.unaligned_store((^simd.u8x16)(raw_data(dst)), blk)
}
