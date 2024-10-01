#+build amd64
package aes

import "base:intrinsics"
import "core:crypto/_aes"
import "core:math/bits"
import "core:mem"
import "core:simd/x86"

@(private)
CTR_STRIDE_HW :: 4
@(private)
CTR_STRIDE_BYTES_HW :: CTR_STRIDE_HW * BLOCK_SIZE

@(private, enable_target_feature = "sse2,aes")
ctr_blocks_hw :: proc(ctx: ^Context_CTR, dst, src: []byte, nr_blocks: int) #no_bounds_check {
	hw_ctx := ctx._impl.(Context_Impl_Hardware)

	sks: [15]x86.__m128i = ---
	for i in 0 ..= hw_ctx._num_rounds {
		sks[i] = intrinsics.unaligned_load((^x86.__m128i)(&hw_ctx._sk_exp_enc[i]))
	}

	hw_inc_ctr := #force_inline proc "contextless" (hi, lo: u64) -> (x86.__m128i, u64, u64) {
		ret := x86.__m128i{
			i64(intrinsics.byte_swap(hi)),
			i64(intrinsics.byte_swap(lo)),
		}

		hi, lo := hi, lo
		carry: u64

		lo, carry = bits.add_u64(lo, 1, 0)
		hi, _ = bits.add_u64(hi, 0, carry)
		return ret, hi, lo
	}

	// The latency of AESENC depends on mfg and microarchitecture:
	// - 7 -> up to Broadwell
	// - 4 -> AMD and Skylake - Cascade Lake
	// - 3 -> Ice Lake and newer
	//
	// This implementation does 4 blocks at once, since performance
	// should be "adequate" across most CPUs.

	src, dst := src, dst
	nr_blocks := nr_blocks
	ctr_hi, ctr_lo := ctx._ctr_hi, ctx._ctr_lo

	blks: [CTR_STRIDE_HW]x86.__m128i = ---
	for nr_blocks >= CTR_STRIDE_HW {
		#unroll for i in 0..< CTR_STRIDE_HW {
			blks[i], ctr_hi, ctr_lo = hw_inc_ctr(ctr_hi, ctr_lo)
		}

		#unroll for i in 0 ..< CTR_STRIDE_HW {
			blks[i] = x86._mm_xor_si128(blks[i], sks[0])
		}
		#unroll for i in 1 ..= 9 {
			#unroll for j in 0 ..< CTR_STRIDE_HW {
				blks[j] = x86._mm_aesenc_si128(blks[j], sks[i])
			}
		}
		switch hw_ctx._num_rounds {
		case _aes.ROUNDS_128:
			#unroll for i in 0 ..< CTR_STRIDE_HW {
				blks[i] = x86._mm_aesenclast_si128(blks[i], sks[10])
			}
		case _aes.ROUNDS_192:
			#unroll for i in 10 ..= 11 {
				#unroll for j in 0 ..< CTR_STRIDE_HW {
					blks[j] = x86._mm_aesenc_si128(blks[j], sks[i])
				}
			}
			#unroll for i in 0 ..< CTR_STRIDE_HW {
				blks[i] = x86._mm_aesenclast_si128(blks[i], sks[12])
			}
		case _aes.ROUNDS_256:
			#unroll for i in 10 ..= 13 {
				#unroll for j in 0 ..< CTR_STRIDE_HW {
					blks[j] = x86._mm_aesenc_si128(blks[j], sks[i])
				}
			}
			#unroll for i in 0 ..< CTR_STRIDE_HW {
				blks[i] = x86._mm_aesenclast_si128(blks[i], sks[14])
			}
		}

		xor_blocks_hw(dst, src, blks[:])

		if src != nil {
			src = src[CTR_STRIDE_BYTES_HW:]
		}
		dst = dst[CTR_STRIDE_BYTES_HW:]
		nr_blocks -= CTR_STRIDE_HW
	}

	// Handle the remainder.
	for nr_blocks > 0 {
		blks[0], ctr_hi, ctr_lo = hw_inc_ctr(ctr_hi, ctr_lo)

		blks[0] = x86._mm_xor_si128(blks[0], sks[0])
		#unroll for i in 1 ..= 9 {
			blks[0] = x86._mm_aesenc_si128(blks[0], sks[i])
		}
		switch hw_ctx._num_rounds {
		case _aes.ROUNDS_128:
			blks[0] = x86._mm_aesenclast_si128(blks[0], sks[10])
		case _aes.ROUNDS_192:
			#unroll for i in 10 ..= 11 {
				blks[0] = x86._mm_aesenc_si128(blks[0], sks[i])
			}
			blks[0] = x86._mm_aesenclast_si128(blks[0], sks[12])
		case _aes.ROUNDS_256:
			#unroll for i in 10 ..= 13 {
				blks[0] = x86._mm_aesenc_si128(blks[0], sks[i])
			}
			blks[0] = x86._mm_aesenclast_si128(blks[0], sks[14])
		}

		xor_blocks_hw(dst, src, blks[:1])

		if src != nil {
			src = src[BLOCK_SIZE:]
		}
		dst = dst[BLOCK_SIZE:]
		nr_blocks -= 1
	}

	// Write back the counter.
	ctx._ctr_hi, ctx._ctr_lo = ctr_hi, ctr_lo

	mem.zero_explicit(&blks, size_of(blks))
	mem.zero_explicit(&sks, size_of(sks))
}

@(private, enable_target_feature = "sse2")
xor_blocks_hw :: proc(dst, src: []byte, blocks: []x86.__m128i) {
	#no_bounds_check {
		if src != nil {
				for i in 0 ..< len(blocks) {
					off := i * BLOCK_SIZE
					tmp := intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[off:])))
					blocks[i] = x86._mm_xor_si128(blocks[i], tmp)
				}
		}
		for i in 0 ..< len(blocks) {
			intrinsics.unaligned_store((^x86.__m128i)(raw_data(dst[i * BLOCK_SIZE:])), blocks[i])
		}
	}
}
