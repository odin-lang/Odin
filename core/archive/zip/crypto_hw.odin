#+build amd64, arm64, arm32
package archive_zip

import "base:intrinsics"
import "core:crypto"
import "core:crypto/_aes"
import "core:crypto/_aes/ct64"
import aes_hw "core:crypto/_aes/hw"
import "core:crypto/aes"
import "core:simd"

#assert(ODIN_ENDIAN == .Little)

@(private)
_ctr_xor :: proc(ctx: ^aes.Context_ECB, counter: ^u64, data: []u8) {
	ensure(ctx._is_initialized)
	switch &impl in ctx._impl {
	case ct64.Context:
		_ctr_xor_ct64(&impl, counter, data)
	case aes_hw.Context:
		_ctr_xor_hw(&impl, counter, data)
	}
}

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
_ctr_xor_hw :: proc(ctx: ^aes_hw.Context, counter: ^u64, data: []u8) {
	p   := raw_data(data)
	n   := len(data) / aes.BLOCK_SIZE
	ctr := counter^
	when ODIN_ARCH == .amd64 {
		if _has_vaes() && n >= AES_VAES_STRIDE {
			wide := n &~ (AES_VAES_STRIDE - 1)
			ctr = _ctr_xor_vaes(ctx, ctr, p, wide)
			p = p[wide * aes.BLOCK_SIZE:]
			n -= wide
		}
	}
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		ctr = _ctr_xor_hw_rounds(ctx, ctr, p, n, _aes.ROUNDS_128)
	case _aes.ROUNDS_192:
		ctr = _ctr_xor_hw_rounds(ctx, ctr, p, n, _aes.ROUNDS_192)
	case _aes.ROUNDS_256:
		ctr = _ctr_xor_hw_rounds(ctx, ctr, p, n, _aes.ROUNDS_256)
	case:
		panic("archive/zip: invalid AES round count")
	}
	counter^ = ctr
}

@(private = "file", enable_target_feature = aes_hw.TARGET_FEATURES)
_ctr_xor_hw_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, ctr: u64, p: [^]u8, n: int, $ROUNDS: int) -> u64 {
	sks: [ROUNDS + 1]simd.u8x16 = ---
	#unroll for r in 0 ..= ROUNDS {
		sks[r] = intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[r]))
	}
	ctr := ctr
	p   := p
	n   := n
	blks: [AES_CTR_STRIDE]simd.u8x16 = ---
	for n >= AES_CTR_STRIDE {
		#unroll for j in 0 ..< AES_CTR_STRIDE {
			blks[j] = simd.bit_xor(transmute(simd.u8x16)simd.u64x2{ctr + u64(j) + 1, 0}, sks[0])
		}
		ctr += AES_CTR_STRIDE
		#unroll for r in 1 ..< ROUNDS {
			#unroll for j in 0 ..< AES_CTR_STRIDE {
				blks[j] = aes_hw.aesenc(blks[j], sks[r])
			}
		}
		#unroll for j in 0 ..< AES_CTR_STRIDE {
			blks[j] = aes_hw.aesenclast(blks[j], sks[ROUNDS])
		}
		#unroll for j in 0 ..< AES_CTR_STRIDE {
			q := (^simd.u8x16)(&p[j * aes.BLOCK_SIZE])
			intrinsics.unaligned_store(q, simd.bit_xor(blks[j], intrinsics.unaligned_load(q)))
		}
		p = p[AES_CTR_STRIDE * aes.BLOCK_SIZE:]
		n -= AES_CTR_STRIDE
	}
	for n > 0 {
		ctr += 1
		blk := simd.bit_xor(transmute(simd.u8x16)simd.u64x2{ctr, 0}, sks[0])
		#unroll for r in 1 ..< ROUNDS {
			blk = aes_hw.aesenc(blk, sks[r])
		}
		blk = aes_hw.aesenclast(blk, sks[ROUNDS])
		q := (^simd.u8x16)(p)
		intrinsics.unaligned_store(q, simd.bit_xor(blk, intrinsics.unaligned_load(q)))
		p = p[aes.BLOCK_SIZE:]
		n -= 1
	}
	crypto.zero_explicit(&blks, size_of(blks))
	crypto.zero_explicit(&sks, size_of(sks))
	return ctr
}
