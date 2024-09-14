#+build amd64
package aes

import "base:intrinsics"
import "core:crypto"
import "core:crypto/_aes"
import "core:crypto/_aes/hw_intel"
import "core:encoding/endian"
import "core:mem"
import "core:simd/x86"

@(private)
gcm_seal_hw :: proc(ctx: ^Context_Impl_Hardware, dst, tag, iv, aad, plaintext: []byte) {
	h: [_aes.GHASH_KEY_SIZE]byte
	j0: [_aes.GHASH_BLOCK_SIZE]byte
	j0_enc: [_aes.GHASH_BLOCK_SIZE]byte
	s: [_aes.GHASH_TAG_SIZE]byte
	init_ghash_hw(ctx, &h, &j0, &j0_enc, iv)

	// Note: Our GHASH implementation handles appending padding.
	hw_intel.ghash(s[:], h[:], aad)
	gctr_hw(ctx, dst, &s, plaintext, &h, &j0, true)
	final_ghash_hw(&s, &h, &j0_enc, len(aad), len(plaintext))
	copy(tag, s[:])

	mem.zero_explicit(&h, len(h))
	mem.zero_explicit(&j0, len(j0))
	mem.zero_explicit(&j0_enc, len(j0_enc))
}

@(private)
gcm_open_hw :: proc(ctx: ^Context_Impl_Hardware, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	h: [_aes.GHASH_KEY_SIZE]byte
	j0: [_aes.GHASH_BLOCK_SIZE]byte
	j0_enc: [_aes.GHASH_BLOCK_SIZE]byte
	s: [_aes.GHASH_TAG_SIZE]byte
	init_ghash_hw(ctx, &h, &j0, &j0_enc, iv)

	hw_intel.ghash(s[:], h[:], aad)
	gctr_hw(ctx, dst, &s, ciphertext, &h, &j0, false)
	final_ghash_hw(&s, &h, &j0_enc, len(aad), len(ciphertext))

	ok := crypto.compare_constant_time(s[:], tag) == 1
	if !ok {
		mem.zero_explicit(raw_data(dst), len(dst))
	}

	mem.zero_explicit(&h, len(h))
	mem.zero_explicit(&j0, len(j0))
	mem.zero_explicit(&j0_enc, len(j0_enc))
	mem.zero_explicit(&s, len(s))

	return ok
}

@(private = "file")
init_ghash_hw :: proc(
	ctx: ^Context_Impl_Hardware,
	h: ^[_aes.GHASH_KEY_SIZE]byte,
	j0: ^[_aes.GHASH_BLOCK_SIZE]byte,
	j0_enc: ^[_aes.GHASH_BLOCK_SIZE]byte,
	iv: []byte,
) {
	// 1. Let H = CIPH(k, 0^128)
	encrypt_block_hw(ctx, h[:], h[:])

	// Define a block, J0, as follows:
	if l := len(iv); l == GCM_IV_SIZE {
		// if len(IV) = 96, then let J0 = IV || 0^31 || 1
		copy(j0[:], iv)
		j0[_aes.GHASH_BLOCK_SIZE - 1] = 1
	} else {
		// If len(IV) != 96, then let s = 128 ceil(len(IV)/128) - len(IV),
		// and let J0 = GHASHH(IV || 0^(s+64) || ceil(len(IV))^64).
		hw_intel.ghash(j0[:], h[:], iv)

		tmp: [_aes.GHASH_BLOCK_SIZE]byte
		endian.unchecked_put_u64be(tmp[8:], u64(l) * 8)
		hw_intel.ghash(j0[:], h[:], tmp[:])
	}

	// ECB encrypt j0, so that we can just XOR with the tag.
	encrypt_block_hw(ctx, j0_enc[:], j0[:])
}

@(private = "file", enable_target_feature = "sse2")
final_ghash_hw :: proc(
	s: ^[_aes.GHASH_BLOCK_SIZE]byte,
	h: ^[_aes.GHASH_KEY_SIZE]byte,
	j0: ^[_aes.GHASH_BLOCK_SIZE]byte,
	a_len: int,
	t_len: int,
) {
	blk: [_aes.GHASH_BLOCK_SIZE]byte
	endian.unchecked_put_u64be(blk[0:], u64(a_len) * 8)
	endian.unchecked_put_u64be(blk[8:], u64(t_len) * 8)

	hw_intel.ghash(s[:], h[:], blk[:])
	j0_vec := intrinsics.unaligned_load((^x86.__m128i)(j0))
	s_vec := intrinsics.unaligned_load((^x86.__m128i)(s))
	s_vec = x86._mm_xor_si128(s_vec, j0_vec)
	intrinsics.unaligned_store((^x86.__m128i)(s), s_vec)
}

@(private = "file", enable_target_feature = "sse2,sse4.1,aes")
gctr_hw :: proc(
	ctx: ^Context_Impl_Hardware,
	dst: []byte,
	s: ^[_aes.GHASH_BLOCK_SIZE]byte,
	src: []byte,
	h: ^[_aes.GHASH_KEY_SIZE]byte,
	iv: ^[_aes.GHASH_BLOCK_SIZE]byte,
	is_seal: bool,
) #no_bounds_check {
	sks: [15]x86.__m128i = ---
	for i in 0 ..= ctx._num_rounds {
		sks[i] = intrinsics.unaligned_load((^x86.__m128i)(&ctx._sk_exp_enc[i]))
	}

	// Setup the counter block
	ctr_blk := intrinsics.unaligned_load((^x86.__m128i)(iv))
	ctr := endian.unchecked_get_u32be(iv[GCM_IV_SIZE:]) + 1

	src, dst := src, dst

	// Note: Instead of doing GHASH and CTR separately, it is more
	// performant to interleave (stitch) the two operations together.
	// This results in an unreadable mess, so we opt for simplicity
	// as performance is adequate.

	blks: [CTR_STRIDE_HW]x86.__m128i = ---
	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks >= CTR_STRIDE_HW {
		if !is_seal {
			hw_intel.ghash(s[:], h[:], src[:CTR_STRIDE_BYTES_HW])
		}

		#unroll for i in 0 ..< CTR_STRIDE_HW {
			blks[i], ctr = hw_inc_ctr32(&ctr_blk, ctr)
		}

		#unroll for i in 0 ..< CTR_STRIDE_HW {
			blks[i] = x86._mm_xor_si128(blks[i], sks[0])
		}
		#unroll for i in 1 ..= 9 {
			#unroll for j in 0 ..< CTR_STRIDE_HW {
				blks[j] = x86._mm_aesenc_si128(blks[j], sks[i])
			}
		}
		switch ctx._num_rounds {
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

		if is_seal {
			hw_intel.ghash(s[:], h[:], dst[:CTR_STRIDE_BYTES_HW])
		}

		src = src[CTR_STRIDE_BYTES_HW:]
		dst = dst[CTR_STRIDE_BYTES_HW:]
		nr_blocks -= CTR_STRIDE_HW
	}

	// Handle the remainder.
	for n := len(src); n > 0; {
		l := min(n, BLOCK_SIZE)
		if !is_seal {
			hw_intel.ghash(s[:], h[:], src[:l])
		}

		blks[0], ctr = hw_inc_ctr32(&ctr_blk, ctr)

		blks[0] = x86._mm_xor_si128(blks[0], sks[0])
		#unroll for i in 1 ..= 9 {
			blks[0] = x86._mm_aesenc_si128(blks[0], sks[i])
		}
		switch ctx._num_rounds {
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

		if l == BLOCK_SIZE {
			xor_blocks_hw(dst, src, blks[:1])
		} else {
			blk: [BLOCK_SIZE]byte
			copy(blk[:], src)
			xor_blocks_hw(blk[:], blk[:], blks[:1])
			copy(dst, blk[:l])
		}
		if is_seal {
			hw_intel.ghash(s[:], h[:], dst[:l])
		}

		dst = dst[l:]
		src = src[l:]
		n -= l
	}

	mem.zero_explicit(&blks, size_of(blks))
	mem.zero_explicit(&sks, size_of(sks))
}

// BUG: Sticking this in gctr_hw (like the other implementations) crashes
// the compiler.
//
// src/check_expr.cpp(7892): Assertion Failure: `c->curr_proc_decl->entity`
@(private = "file", enable_target_feature = "sse4.1")
hw_inc_ctr32 :: #force_inline proc "contextless" (src: ^x86.__m128i, ctr: u32) -> (x86.__m128i, u32) {
	ret := x86._mm_insert_epi32(src^, i32(intrinsics.byte_swap(ctr)), 3)
	return ret, ctr + 1
}
