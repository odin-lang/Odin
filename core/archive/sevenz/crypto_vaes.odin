#+private
#+build amd64
package archive_sevenz

import "base:intrinsics"
import "core:crypto"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:crypto/aes"
import "core:simd"

@(enable_target_feature = aes_hw.VAES_TARGET_FEATURES)
_cbc_decrypt_vaes :: proc "contextless" (ctx: ^aes_hw.Context, chain: simd.u8x16, p: [^]u8, n: int) -> simd.u8x16 {
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		return _cbc_decrypt_vaes_rounds(ctx, chain, p, n, _aes.ROUNDS_128)
	case _aes.ROUNDS_192:
		return _cbc_decrypt_vaes_rounds(ctx, chain, p, n, _aes.ROUNDS_192)
	case _aes.ROUNDS_256:
		return _cbc_decrypt_vaes_rounds(ctx, chain, p, n, _aes.ROUNDS_256)
	}
	return chain
}

@(private = "file", enable_target_feature = aes_hw.VAES_TARGET_FEATURES)
_cbc_decrypt_vaes_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, chain: simd.u8x16, p: [^]u8, n: int, $ROUNDS: int) -> simd.u8x16 {
	WIDE :: AES_VAES_STRIDE / 2
	chain := chain
	p     := p
	n     := n
	blks: [WIDE]simd.u8x32 = ---
	for n >= AES_VAES_STRIDE {
		k0 := _round_key_vaes(ctx, 0)
		#unroll for j in 0 ..< WIDE {
			blks[j] = simd.bit_xor(intrinsics.unaligned_load((^simd.u8x32)(&p[j * 2 * aes.BLOCK_SIZE])), k0)
		}
		#unroll for r in 1 ..< ROUNDS {
			k := _round_key_vaes(ctx, r)
			#unroll for j in 0 ..< WIDE {
				blks[j] = aes_hw.vaesdec(blks[j], k)
			}
		}
		last := _round_key_vaes(ctx, ROUNDS)
		#unroll for j in 0 ..< WIDE {
			blks[j] = aes_hw.vaesdeclast(blks[j], last)
		}
		next := intrinsics.unaligned_load((^simd.u8x16)(&p[(AES_VAES_STRIDE - 1) * aes.BLOCK_SIZE]))
		#unroll for k in 1 ..< WIDE {
			j    := WIDE - k
			prev := intrinsics.unaligned_load((^simd.u8x32)(&p[(j * 2 - 1) * aes.BLOCK_SIZE]))
			intrinsics.unaligned_store((^simd.u8x32)(&p[j * 2 * aes.BLOCK_SIZE]), simd.bit_xor(blks[j], prev))
		}
		first := transmute(simd.u8x32)simd.shuffle(transmute(simd.u64x2)chain, intrinsics.unaligned_load((^simd.u64x2)(p)), 0, 1, 2, 3)
		intrinsics.unaligned_store((^simd.u8x32)(p), simd.bit_xor(blks[0], first))
		chain = next
		p = p[AES_VAES_STRIDE * aes.BLOCK_SIZE:]
		n -= AES_VAES_STRIDE
	}
	crypto.zero_explicit(&blks, size_of(blks))
	return chain
}

@(private = "file", enable_target_feature = aes_hw.VAES_TARGET_FEATURES)
_round_key_vaes :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, r: int) -> simd.u8x32 {
	return aes_hw.broadcast_round_key(intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[r])))
}
