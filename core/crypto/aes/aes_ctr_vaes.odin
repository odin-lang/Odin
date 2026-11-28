#+build amd64
package aes

import "base:intrinsics"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:simd"

@(private)
CTR_STRIDE_VAES :: 16

@(private, enable_target_feature = aes_hw.VAES_TARGET_FEATURES)
ctr_blocks_vaes :: proc "contextless" (ctx: ^Context_Impl_Hardware, dst, src: []byte, nr_blocks: int, ctr_hi, ctr_lo: u64, is_le64: bool) -> (int, u64) {
	if is_le64 {
		switch ctx._num_rounds {
		case _aes.ROUNDS_128:
			return ctr_blocks_vaes_rounds(ctx, dst, src, nr_blocks, ctr_hi, ctr_lo, true, _aes.ROUNDS_128)
		case _aes.ROUNDS_192:
			return ctr_blocks_vaes_rounds(ctx, dst, src, nr_blocks, ctr_hi, ctr_lo, true, _aes.ROUNDS_192)
		case _aes.ROUNDS_256:
			return ctr_blocks_vaes_rounds(ctx, dst, src, nr_blocks, ctr_hi, ctr_lo, true, _aes.ROUNDS_256)
		}
	} else {
		switch ctx._num_rounds {
		case _aes.ROUNDS_128:
			return ctr_blocks_vaes_rounds(ctx, dst, src, nr_blocks, ctr_hi, ctr_lo, false, _aes.ROUNDS_128)
		case _aes.ROUNDS_192:
			return ctr_blocks_vaes_rounds(ctx, dst, src, nr_blocks, ctr_hi, ctr_lo, false, _aes.ROUNDS_192)
		case _aes.ROUNDS_256:
			return ctr_blocks_vaes_rounds(ctx, dst, src, nr_blocks, ctr_hi, ctr_lo, false, _aes.ROUNDS_256)
		}
	}
	return 0, ctr_lo
}

@(private = "file", enable_target_feature = aes_hw.VAES_TARGET_FEATURES)
ctr_blocks_vaes_rounds :: #force_inline proc "contextless" (
	ctx: ^Context_Impl_Hardware,
	dst, src: []byte,
	nr_blocks: int,
	ctr_hi, ctr_lo: u64,
	$IS_LE64: bool,
	$ROUNDS: int,
) -> (int, u64) #no_bounds_check {
	WIDE :: CTR_STRIDE_VAES / 2

	dp := raw_data(dst)
	sp := raw_data(src)
	lo := ctr_lo
	done := 0

	blks: [WIDE]simd.u8x32 = ---
	for nr_blocks - done >= CTR_STRIDE_VAES {
		when !IS_LE64 {
			if lo > max(u64) - CTR_STRIDE_VAES {
				break
			}
		}

		k0 := round_key_vaes(ctx, 0)
		#unroll for j in 0 ..< WIDE {
			pair: simd.u8x32
			when IS_LE64 {
				pair = transmute(simd.u8x32)simd.u64x4{lo + u64(2 * j), ctr_hi, lo + u64(2 * j + 1), ctr_hi}
			} else {
				pair = simd.swizzle(
					transmute(simd.u8x32)simd.u64x4{ctr_hi, lo + u64(2 * j), ctr_hi, lo + u64(2 * j + 1)},
					7, 6, 5, 4, 3, 2, 1, 0,
					15, 14, 13, 12, 11, 10, 9, 8,
					23, 22, 21, 20, 19, 18, 17, 16,
					31, 30, 29, 28, 27, 26, 25, 24,
				)
			}
			blks[j] = simd.bit_xor(pair, k0)
		}
		lo += CTR_STRIDE_VAES

		#unroll for r in 1 ..< ROUNDS {
			k := round_key_vaes(ctx, r)
			#unroll for j in 0 ..< WIDE {
				blks[j] = aes_hw.vaesenc(blks[j], k)
			}
		}
		last := round_key_vaes(ctx, ROUNDS)
		#unroll for j in 0 ..< WIDE {
			blks[j] = aes_hw.vaesenclast(blks[j], last)
		}

		if sp != nil {
			#unroll for j in 0 ..< WIDE {
				blks[j] = simd.bit_xor(blks[j], intrinsics.unaligned_load((^simd.u8x32)(&sp[j * 2 * BLOCK_SIZE])))
			}
			sp = sp[CTR_STRIDE_VAES * BLOCK_SIZE:]
		}
		#unroll for j in 0 ..< WIDE {
			intrinsics.unaligned_store((^simd.u8x32)(&dp[j * 2 * BLOCK_SIZE]), blks[j])
		}
		dp = dp[CTR_STRIDE_VAES * BLOCK_SIZE:]
		done += CTR_STRIDE_VAES
	}

	zero_explicit(&blks, size_of(blks))
	return done, lo
}

@(private = "file", enable_target_feature = aes_hw.VAES_TARGET_FEATURES)
round_key_vaes :: #force_inline proc "contextless" (ctx: ^Context_Impl_Hardware, r: int) -> simd.u8x32 {
	return aes_hw.broadcast_round_key(intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[r])))
}
