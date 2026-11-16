#+build amd64
package archive_zip

import "base:intrinsics"
import "core:archive"
import "core:crypto"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:crypto/aes"
import "core:simd"

@(private = "file")
VAES_FEATURES :: aes_hw.TARGET_FEATURES + ",avx,avx2,vaes,-slow-unaligned-mem-32"

@(private)
_has_vaes :: #force_inline proc "contextless" () -> bool {
	return archive._has_vaes()
}

@(private = "file", default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.x86.aesni.aesenc.256")
	_aesenc_256 :: proc(a, b: simd.i64x4) -> simd.i64x4 ---
	@(link_name = "llvm.x86.aesni.aesenclast.256")
	_aesenclast_256 :: proc(a, b: simd.i64x4) -> simd.i64x4 ---
}

@(private, enable_target_feature = VAES_FEATURES)
_ctr_xor_vaes :: proc "contextless" (ctx: ^aes_hw.Context, ctr: u64, p: [^]u8, n: int) -> u64 {
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		return _ctr_xor_vaes_rounds(ctx, ctr, p, n, _aes.ROUNDS_128)
	case _aes.ROUNDS_192:
		return _ctr_xor_vaes_rounds(ctx, ctr, p, n, _aes.ROUNDS_192)
	case _aes.ROUNDS_256:
		return _ctr_xor_vaes_rounds(ctx, ctr, p, n, _aes.ROUNDS_256)
	}
	return ctr
}

@(private = "file", enable_target_feature = VAES_FEATURES)
_ctr_xor_vaes_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, ctr: u64, p: [^]u8, n: int, $ROUNDS: int) -> u64 {
	WIDE :: AES_VAES_STRIDE / 2
	ctr := ctr
	p   := p
	n   := n
	blks: [WIDE]simd.i64x4 = ---
	for n >= AES_VAES_STRIDE {
		k0 := _round_key_256(ctx, 0)
		#unroll for j in 0 ..< WIDE {
			pair   := transmute(simd.i64x4)simd.u64x4{ctr + u64(2 * j) + 1, 0, ctr + u64(2 * j) + 2, 0}
			blks[j] = simd.bit_xor(pair, k0)
		}
		ctr += AES_VAES_STRIDE
		#unroll for r in 1 ..< ROUNDS {
			k := _round_key_256(ctx, r)
			#unroll for j in 0 ..< WIDE {
				blks[j] = _aesenc_256(blks[j], k)
			}
		}
		last := _round_key_256(ctx, ROUNDS)
		#unroll for j in 0 ..< WIDE {
			blks[j] = _aesenclast_256(blks[j], last)
		}
		#unroll for j in 0 ..< WIDE {
			q := (^simd.i64x4)(&p[j * 2 * aes.BLOCK_SIZE])
			intrinsics.unaligned_store(q, simd.bit_xor(blks[j], intrinsics.unaligned_load(q)))
		}
		p = p[AES_VAES_STRIDE * aes.BLOCK_SIZE:]
		n -= AES_VAES_STRIDE
	}
	crypto.zero_explicit(&blks, size_of(blks))
	return ctr
}

@(private = "file", enable_target_feature = VAES_FEATURES)
_round_key_256 :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, r: int) -> simd.i64x4 {
	k := intrinsics.unaligned_load((^simd.i64x2)(&ctx._sk_exp_enc[r]))
	return simd.shuffle(k, k, 0, 1, 0, 1)
}
