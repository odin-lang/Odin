#+build arm64, arm32
package archive_sevenz

import "base:intrinsics"
import "core:crypto"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:crypto/aes"
import "core:simd"
import "core:simd/arm"

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
_cbc_encrypt_arm :: proc(ctx: ^aes_hw.Context, chain: simd.u8x16, dst, src: [^]u8, n: int) -> simd.u8x16 {
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		return _cbc_encrypt_arm_rounds(ctx, chain, dst, src, n, _aes.ROUNDS_128)
	case _aes.ROUNDS_192:
		return _cbc_encrypt_arm_rounds(ctx, chain, dst, src, n, _aes.ROUNDS_192)
	case _aes.ROUNDS_256:
		return _cbc_encrypt_arm_rounds(ctx, chain, dst, src, n, _aes.ROUNDS_256)
	}
	panic("archive/sevenz: invalid AES round count")
}

@(private = "file", enable_target_feature = aes_hw.TARGET_FEATURES)
_cbc_encrypt_arm_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, chain: simd.u8x16, dst, src: [^]u8, n: int, $ROUNDS: int) -> simd.u8x16 {
	sks: [ROUNDS + 1]simd.u8x16 = ---
	#unroll for r in 0 ..= ROUNDS {
		sks[r] = intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[r]))
	}
	fold  := simd.bit_xor(sks[ROUNDS], sks[0])
	mask  := sks[0]
	state := chain
	for i in 0 ..< n {
		key  := simd.bit_xor(intrinsics.unaligned_load((^simd.u8x16)(&src[i * aes.BLOCK_SIZE])), mask)
		state = arm.vaesmcq_u8(arm.vaeseq_u8(state, key))
		#unroll for r in 1 ..< ROUNDS - 1 {
			state = arm.vaesmcq_u8(arm.vaeseq_u8(state, sks[r]))
		}
		state = arm.vaeseq_u8(state, sks[ROUNDS - 1])
		intrinsics.unaligned_store((^simd.u8x16)(&dst[i * aes.BLOCK_SIZE]), simd.bit_xor(state, sks[ROUNDS]))
		mask = fold
	}
	result := chain
	if n > 0 {
		result = simd.bit_xor(state, sks[ROUNDS])
	}
	crypto.zero_explicit(&sks, size_of(sks))
	return result
}
