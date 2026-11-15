#+build amd64
package archive_sevenz

import "base:intrinsics"
import "core:crypto"
import "core:crypto/_aes"
import aes_hw "core:crypto/_aes/hw"
import "core:crypto/aes"
import "core:simd"
import "core:sys/info"

@(private = "file")
VAES_FEATURES :: aes_hw.TARGET_FEATURES + ",avx,avx2,vaes,-slow-unaligned-mem-32"

@(private)
_has_vaes: bool

@(init, private)
_detect_vaes :: proc "contextless" () {
	if !TEST_AES_VAES || !aes_hw.is_supported() || .avx2 not_in info.cpu_features() {
		return
	}
	max_id, _, _, _ := intrinsics.x86_cpuid(0, 0)
	if max_id < 7 {
		return
	}
	_, _, ecx7, _ := intrinsics.x86_cpuid(7, 0)
	_has_vaes = ecx7 >> 9 & 1 != 0
}

@(private = "file", default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.x86.aesni.aesdec.256")
	_aesdec_256 :: proc(a, b: simd.i64x4) -> simd.i64x4 ---
	@(link_name = "llvm.x86.aesni.aesdeclast.256")
	_aesdeclast_256 :: proc(a, b: simd.i64x4) -> simd.i64x4 ---
}

@(private, enable_target_feature = VAES_FEATURES)
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

@(private = "file", enable_target_feature = VAES_FEATURES)
_cbc_decrypt_vaes_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, chain: simd.u8x16, p: [^]u8, n: int, $ROUNDS: int) -> simd.u8x16 {
	WIDE :: AES_VAES_STRIDE / 2
	chain := transmute(simd.i64x2)chain
	p     := p
	n     := n
	blks: [WIDE]simd.i64x4 = ---
	for n >= AES_VAES_STRIDE {
		k0 := _round_key_256(ctx, 0)
		#unroll for j in 0 ..< WIDE {
			blks[j] = simd.bit_xor(intrinsics.unaligned_load((^simd.i64x4)(&p[j * 2 * aes.BLOCK_SIZE])), k0)
		}
		#unroll for r in 1 ..< ROUNDS {
			k := _round_key_256(ctx, r)
			#unroll for j in 0 ..< WIDE {
				blks[j] = _aesdec_256(blks[j], k)
			}
		}
		last := _round_key_256(ctx, ROUNDS)
		#unroll for j in 0 ..< WIDE {
			blks[j] = _aesdeclast_256(blks[j], last)
		}
		next := intrinsics.unaligned_load((^simd.i64x2)(&p[(AES_VAES_STRIDE - 1) * aes.BLOCK_SIZE]))
		#unroll for k in 1 ..< WIDE {
			j    := WIDE - k
			prev := intrinsics.unaligned_load((^simd.i64x4)(&p[(j * 2 - 1) * aes.BLOCK_SIZE]))
			intrinsics.unaligned_store((^simd.i64x4)(&p[j * 2 * aes.BLOCK_SIZE]), simd.bit_xor(blks[j], prev))
		}
		first := simd.shuffle(chain, intrinsics.unaligned_load((^simd.i64x2)(p)), 0, 1, 2, 3)
		intrinsics.unaligned_store((^simd.i64x4)(p), simd.bit_xor(blks[0], first))
		chain = next
		p = p[AES_VAES_STRIDE * aes.BLOCK_SIZE:]
		n -= AES_VAES_STRIDE
	}
	crypto.zero_explicit(&blks, size_of(blks))
	return transmute(simd.u8x16)chain
}

@(private = "file", enable_target_feature = VAES_FEATURES)
_round_key_256 :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, r: int) -> simd.i64x4 {
	k := intrinsics.unaligned_load((^simd.i64x2)(&ctx._sk_exp_dec[r]))
	return simd.shuffle(k, k, 0, 1, 0, 1)
}
