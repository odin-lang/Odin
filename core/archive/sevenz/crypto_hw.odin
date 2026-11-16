#+build amd64, arm64, arm32
package archive_sevenz

import "base:intrinsics"
import "core:crypto"
import "core:crypto/_aes"
import "core:crypto/_aes/ct64"
import aes_hw "core:crypto/_aes/hw"
import "core:crypto/aes"
import "core:simd"

@(private)
_cbc_decrypt :: proc(ctx: ^aes.Context_ECB, iv: ^[aes.BLOCK_SIZE]u8, data: []u8) {
	ensure(ctx._is_initialized)
	switch &impl in ctx._impl {
	case ct64.Context:
		_cbc_decrypt_ct64(&impl, iv, data)
	case aes_hw.Context:
		_cbc_decrypt_hw(&impl, iv, data)
	}
}

@(private)
_cbc_encrypt :: proc(ctx: ^aes.Context_ECB, iv: ^[aes.BLOCK_SIZE]u8, dst, src: []u8) {
	ensure(ctx._is_initialized)
	ensure(len(dst) >= len(src) &~ (aes.BLOCK_SIZE - 1))
	switch &impl in ctx._impl {
	case ct64.Context:
		_cbc_encrypt_ct64(&impl, iv, dst, src)
	case aes_hw.Context:
		_cbc_encrypt_hw(&impl, iv, dst, src)
	}
}

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
_cbc_decrypt_hw :: proc(ctx: ^aes_hw.Context, iv: ^[aes.BLOCK_SIZE]u8, data: []u8) {
	p     := raw_data(data)
	n     := len(data) / aes.BLOCK_SIZE
	chain := intrinsics.unaligned_load((^simd.u8x16)(iv))
	when ODIN_ARCH == .amd64 {
		if _has_vaes() && n >= AES_VAES_STRIDE {
			wide := n &~ (AES_VAES_STRIDE - 1)
			chain = _cbc_decrypt_vaes(ctx, chain, p, wide)
			p = p[wide * aes.BLOCK_SIZE:]
			n -= wide
		}
	}
	switch ctx._num_rounds {
	case _aes.ROUNDS_128:
		chain = _cbc_decrypt_hw_rounds(ctx, chain, p, n, _aes.ROUNDS_128)
	case _aes.ROUNDS_192:
		chain = _cbc_decrypt_hw_rounds(ctx, chain, p, n, _aes.ROUNDS_192)
	case _aes.ROUNDS_256:
		chain = _cbc_decrypt_hw_rounds(ctx, chain, p, n, _aes.ROUNDS_256)
	case:
		panic("archive/sevenz: invalid AES round count")
	}
	intrinsics.unaligned_store((^simd.u8x16)(iv), chain)
}

@(private = "file", enable_target_feature = aes_hw.TARGET_FEATURES)
_cbc_decrypt_hw_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, chain: simd.u8x16, p: [^]u8, n: int, $ROUNDS: int) -> simd.u8x16 {
	sks: [ROUNDS + 1]simd.u8x16 = ---
	#unroll for r in 0 ..= ROUNDS {
		sks[r] = intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_dec[r]))
	}
	chain := chain
	p     := p
	n     := n
	blks: [AES_CBC_STRIDE]simd.u8x16 = ---
	for n >= AES_CBC_STRIDE {
		#unroll for j in 0 ..< AES_CBC_STRIDE {
			blks[j] = simd.bit_xor(intrinsics.unaligned_load((^simd.u8x16)(&p[j * aes.BLOCK_SIZE])), sks[0])
		}
		#unroll for r in 1 ..< ROUNDS {
			#unroll for j in 0 ..< AES_CBC_STRIDE {
				blks[j] = aes_hw.aesdec(blks[j], sks[r])
			}
		}
		#unroll for j in 0 ..< AES_CBC_STRIDE {
			blks[j] = aes_hw.aesdeclast(blks[j], sks[ROUNDS])
		}
		next := intrinsics.unaligned_load((^simd.u8x16)(&p[(AES_CBC_STRIDE - 1) * aes.BLOCK_SIZE]))
		#unroll for k in 1 ..< AES_CBC_STRIDE {
			j    := AES_CBC_STRIDE - k
			prev := intrinsics.unaligned_load((^simd.u8x16)(&p[(j - 1) * aes.BLOCK_SIZE]))
			intrinsics.unaligned_store((^simd.u8x16)(&p[j * aes.BLOCK_SIZE]), simd.bit_xor(blks[j], prev))
		}
		intrinsics.unaligned_store((^simd.u8x16)(p), simd.bit_xor(blks[0], chain))
		chain = next
		p = p[AES_CBC_STRIDE * aes.BLOCK_SIZE:]
		n -= AES_CBC_STRIDE
	}
	for n > 0 {
		cipher := intrinsics.unaligned_load((^simd.u8x16)(p))
		blk    := simd.bit_xor(cipher, sks[0])
		#unroll for r in 1 ..< ROUNDS {
			blk = aes_hw.aesdec(blk, sks[r])
		}
		blk = aes_hw.aesdeclast(blk, sks[ROUNDS])
		intrinsics.unaligned_store((^simd.u8x16)(p), simd.bit_xor(blk, chain))
		chain = cipher
		p = p[aes.BLOCK_SIZE:]
		n -= 1
	}
	crypto.zero_explicit(&blks, size_of(blks))
	crypto.zero_explicit(&sks, size_of(sks))
	return chain
}

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
_cbc_encrypt_hw :: proc(ctx: ^aes_hw.Context, iv: ^[aes.BLOCK_SIZE]u8, dst, src: []u8) {
	n     := len(src) / aes.BLOCK_SIZE
	chain := intrinsics.unaligned_load((^simd.u8x16)(iv))
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 {
		chain = _cbc_encrypt_arm(ctx, chain, raw_data(dst), raw_data(src), n)
	} else {
		switch ctx._num_rounds {
		case _aes.ROUNDS_128:
			chain = _cbc_encrypt_hw_rounds(ctx, chain, raw_data(dst), raw_data(src), n, _aes.ROUNDS_128)
		case _aes.ROUNDS_192:
			chain = _cbc_encrypt_hw_rounds(ctx, chain, raw_data(dst), raw_data(src), n, _aes.ROUNDS_192)
		case _aes.ROUNDS_256:
			chain = _cbc_encrypt_hw_rounds(ctx, chain, raw_data(dst), raw_data(src), n, _aes.ROUNDS_256)
		case:
			panic("archive/sevenz: invalid AES round count")
		}
	}
	intrinsics.unaligned_store((^simd.u8x16)(iv), chain)
}

@(private = "file", enable_target_feature = aes_hw.TARGET_FEATURES)
_cbc_encrypt_hw_rounds :: #force_inline proc "contextless" (ctx: ^aes_hw.Context, chain: simd.u8x16, dst, src: [^]u8, n: int, $ROUNDS: int) -> simd.u8x16 {
	sks: [ROUNDS + 1]simd.u8x16 = ---
	#unroll for r in 0 ..= ROUNDS {
		sks[r] = intrinsics.unaligned_load((^simd.u8x16)(&ctx._sk_exp_enc[r]))
	}
	chain := chain
	if n > 0 {
		blk := simd.bit_xor(chain, simd.bit_xor(intrinsics.unaligned_load((^simd.u8x16)(src)), sks[0]))
		for i in 0 ..< n - 1 {
			#unroll for r in 1 ..< ROUNDS {
				blk = aes_hw.aesenc(blk, sks[r])
			}
			white := simd.bit_xor(intrinsics.unaligned_load((^simd.u8x16)(&src[(i + 1) * aes.BLOCK_SIZE])), sks[0])
			blk    = aes_hw.aesenclast(blk, simd.bit_xor(sks[ROUNDS], white))
			intrinsics.unaligned_store((^simd.u8x16)(&dst[i * aes.BLOCK_SIZE]), simd.bit_xor(blk, white))
		}
		#unroll for r in 1 ..< ROUNDS {
			blk = aes_hw.aesenc(blk, sks[r])
		}
		chain = aes_hw.aesenclast(blk, sks[ROUNDS])
		intrinsics.unaligned_store((^simd.u8x16)(&dst[(n - 1) * aes.BLOCK_SIZE]), chain)
	}
	crypto.zero_explicit(&sks, size_of(sks))
	return chain
}
