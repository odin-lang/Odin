#+build amd64,arm64,arm32
package aes

import "base:intrinsics"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:encoding/endian"
import "core:math/bits"
import "core:simd"

@(private)
CTR_STRIDE_HW :: 4
@(private)
CTR_STRIDE_BYTES_HW :: CTR_STRIDE_HW * BLOCK_SIZE

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
ctr_blocks_hw :: proc(ctx: ^Context_CTR, dst, src: []byte, nr_blocks: int) #no_bounds_check {
	hw_ctx := ctx._impl.(Context_Impl_Hardware)

	sks: [15]simd.u8x16 = ---
	for i in 0 ..= hw_ctx._num_rounds {
		sks[i] = intrinsics.unaligned_load((^simd.u8x16)(&hw_ctx._sk_exp_enc[i]))
	}

	hw_inc_ctr := #force_inline proc "contextless" (hi, lo: u64) -> (simd.u8x16, u64, u64) {
		buf: [BLOCK_SIZE]byte = ---
		endian.unchecked_put_u64be(buf[0:], hi)
		endian.unchecked_put_u64be(buf[8:], lo)
		ret := intrinsics.unaligned_load((^simd.u8x16)(&buf))

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

	blks: [CTR_STRIDE_HW]simd.u8x16 = ---
	for nr_blocks >= CTR_STRIDE_HW {
		#unroll for i in 0..< CTR_STRIDE_HW {
			blks[i], ctr_hi, ctr_lo = hw_inc_ctr(ctr_hi, ctr_lo)
		}

		#unroll for i in 0 ..< CTR_STRIDE_HW {
			blks[i] = simd.bit_xor(blks[i], sks[0])
		}
		#unroll for i in 1 ..= 9 {
			#unroll for j in 0 ..< CTR_STRIDE_HW {
				blks[j] = aes_hw.aesenc(blks[j], sks[i])
			}
		}
		switch hw_ctx._num_rounds {
		case _aes.ROUNDS_128:
			#unroll for i in 0 ..< CTR_STRIDE_HW {
				blks[i] = aes_hw.aesenclast(blks[i], sks[10])
			}
		case _aes.ROUNDS_192:
			#unroll for i in 10 ..= 11 {
				#unroll for j in 0 ..< CTR_STRIDE_HW {
					blks[j] = aes_hw.aesenc(blks[j], sks[i])
				}
			}
			#unroll for i in 0 ..< CTR_STRIDE_HW {
				blks[i] = aes_hw.aesenclast(blks[i], sks[12])
			}
		case _aes.ROUNDS_256:
			#unroll for i in 10 ..= 13 {
				#unroll for j in 0 ..< CTR_STRIDE_HW {
					blks[j] = aes_hw.aesenc(blks[j], sks[i])
				}
			}
			#unroll for i in 0 ..< CTR_STRIDE_HW {
				blks[i] = aes_hw.aesenclast(blks[i], sks[14])
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

		blks[0] = simd.bit_xor(blks[0], sks[0])
		#unroll for i in 1 ..= 9 {
			blks[0] = aes_hw.aesenc(blks[0], sks[i])
		}
		switch hw_ctx._num_rounds {
		case _aes.ROUNDS_128:
			blks[0] = aes_hw.aesenclast(blks[0], sks[10])
		case _aes.ROUNDS_192:
			#unroll for i in 10 ..= 11 {
				blks[0] = aes_hw.aesenc(blks[0], sks[i])
			}
			blks[0] = aes_hw.aesenclast(blks[0], sks[12])
		case _aes.ROUNDS_256:
			#unroll for i in 10 ..= 13 {
				blks[0] = aes_hw.aesenc(blks[0], sks[i])
			}
			blks[0] = aes_hw.aesenclast(blks[0], sks[14])
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

	zero_explicit(&blks, size_of(blks))
	zero_explicit(&sks, size_of(sks))
}

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
xor_blocks_hw :: proc(dst, src: []byte, blocks: []simd.u8x16) {
	#no_bounds_check {
		if src != nil {
				for i in 0 ..< len(blocks) {
					off := i * BLOCK_SIZE
					tmp := intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[off:])))
					blocks[i] = simd.bit_xor(blocks[i], tmp)
				}
		}
		for i in 0 ..< len(blocks) {
			intrinsics.unaligned_store((^simd.u8x16)(raw_data(dst[i * BLOCK_SIZE:])), blocks[i])
		}
	}
}
