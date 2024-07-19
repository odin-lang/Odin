//+build amd64
package aes

import "base:intrinsics"
import "core:crypto/_aes"
import "core:simd/x86"

@(private, enable_target_feature = "sse2,aes")
encrypt_block_hw :: proc(ctx: ^Context_Impl_Hardware, dst, src: []byte) {
	blk := intrinsics.unaligned_load((^x86.__m128i)(raw_data(src)))

	blk = x86._mm_xor_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[0])))
	#unroll for i in 1 ..= 9 {
		blk = x86._mm_aesenc_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[i])))
	}
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		blk = x86._mm_aesenclast_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[10])))
	case _aes.ROUNDS_192:
		#unroll for i in 10 ..= 11 {
			blk = x86._mm_aesenc_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[i])))
		}
		blk = x86._mm_aesenclast_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[12])))
	case _aes.ROUNDS_256:
		#unroll for i in 10 ..= 13 {
			blk = x86._mm_aesenc_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[i])))
		}
		blk = x86._mm_aesenclast_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[14])))
	}

	intrinsics.unaligned_store((^x86.__m128i)(raw_data(dst)), blk)
}

@(private, enable_target_feature = "sse2,aes")
decrypt_block_hw :: proc(ctx: ^Context_Impl_Hardware, dst, src: []byte) {
	blk := intrinsics.unaligned_load((^x86.__m128i)(raw_data(src)))

	blk = x86._mm_xor_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[0])))
	#unroll for i in 1 ..= 9 {
		blk = x86._mm_aesdec_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[i])))
	}
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		blk = x86._mm_aesdeclast_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[10])))
	case _aes.ROUNDS_192:
		#unroll for i in 10 ..= 11 {
			blk = x86._mm_aesdec_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[i])))
		}
		blk = x86._mm_aesdeclast_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[12])))
	case _aes.ROUNDS_256:
		#unroll for i in 10 ..= 13 {
			blk = x86._mm_aesdec_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[i])))
		}
		blk = x86._mm_aesdeclast_si128(blk, intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_dec[14])))
	}

	intrinsics.unaligned_store((^x86.__m128i)(raw_data(dst)), blk)
}
