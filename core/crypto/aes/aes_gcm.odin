package aes

import "core:crypto"
import "core:crypto/_aes"
import "core:crypto/_aes/ct64"
import "core:encoding/endian"
import "core:mem"

// GCM_NONCE_SIZE is the size of the GCM nonce in bytes.
GCM_NONCE_SIZE :: 12
// GCM_TAG_SIZE is the size of a GCM tag in bytes.
GCM_TAG_SIZE :: _aes.GHASH_TAG_SIZE

@(private)
GCM_A_MAX :: max(u64) / 8 // 2^64 - 1 bits -> bytes
@(private)
GCM_P_MAX :: 0xfffffffe0 // 2^39 - 256 bits -> bytes

// Context_GCM is a keyed AES-GCM instance.
Context_GCM :: struct {
	_impl:           Context_Impl,
	_is_initialized: bool,
}

// init_gcm initializes a Context_GCM with the provided key.
init_gcm :: proc(ctx: ^Context_GCM, key: []byte, impl := Implementation.Hardware) {
	init_impl(&ctx._impl, key, impl)
	ctx._is_initialized = true
}

// seal_gcm encrypts the plaintext and authenticates the aad and ciphertext,
// with the provided Context_GCM and nonce, stores the output in dst and tag.
//
// dst and plaintext MUST alias exactly or not at all.
seal_gcm :: proc(ctx: ^Context_GCM, dst, tag, nonce, aad, plaintext: []byte) {
	assert(ctx._is_initialized)

	gcm_validate_common_slice_sizes(tag, nonce, aad, plaintext)
	if len(dst) != len(plaintext) {
		panic("crypto/aes: invalid destination ciphertext size")
	}

	if impl, is_hw := ctx._impl.(Context_Impl_Hardware); is_hw {
		gcm_seal_hw(&impl, dst, tag, nonce, aad, plaintext)
		return
	}

	h: [_aes.GHASH_KEY_SIZE]byte
	j0: [_aes.GHASH_BLOCK_SIZE]byte
	s: [_aes.GHASH_TAG_SIZE]byte
	init_ghash_ct64(ctx, &h, &j0, nonce)

	// Note: Our GHASH implementation handles appending padding.
	ct64.ghash(s[:], h[:], aad)
	gctr_ct64(ctx, dst, &s, plaintext, &h, nonce, true)
	final_ghash_ct64(&s, &h, &j0, len(aad), len(plaintext))
	copy(tag, s[:])

	mem.zero_explicit(&h, len(h))
	mem.zero_explicit(&j0, len(j0))
}

// open_gcm authenticates the aad and ciphertext, and decrypts the ciphertext,
// with the provided Context_GCM, nonce, and tag, and stores the output in dst,
// returning true iff the authentication was successful.  If authentication
// fails, the destination buffer will be zeroed.
//
// dst and plaintext MUST alias exactly or not at all.
open_gcm :: proc(ctx: ^Context_GCM, dst, nonce, aad, ciphertext, tag: []byte) -> bool {
	assert(ctx._is_initialized)

	gcm_validate_common_slice_sizes(tag, nonce, aad, ciphertext)
	if len(dst) != len(ciphertext) {
		panic("crypto/aes: invalid destination plaintext size")
	}

	if impl, is_hw := ctx._impl.(Context_Impl_Hardware); is_hw {
		return gcm_open_hw(&impl, dst, nonce, aad, ciphertext, tag)
	}

	h: [_aes.GHASH_KEY_SIZE]byte
	j0: [_aes.GHASH_BLOCK_SIZE]byte
	s: [_aes.GHASH_TAG_SIZE]byte
	init_ghash_ct64(ctx, &h, &j0, nonce)

	ct64.ghash(s[:], h[:], aad)
	gctr_ct64(ctx, dst, &s, ciphertext, &h, nonce, false)
	final_ghash_ct64(&s, &h, &j0, len(aad), len(ciphertext))

	ok := crypto.compare_constant_time(s[:], tag) == 1
	if !ok {
		mem.zero_explicit(raw_data(dst), len(dst))
	}

	mem.zero_explicit(&h, len(h))
	mem.zero_explicit(&j0, len(j0))
	mem.zero_explicit(&s, len(s))

	return ok
}

// reset_ctr sanitizes the Context_GCM.  The Context_GCM must be
// re-initialized to be used again.
reset_gcm :: proc "contextless" (ctx: ^Context_GCM) {
	reset_impl(&ctx._impl)
	ctx._is_initialized = false
}

@(private)
gcm_validate_common_slice_sizes :: proc(tag, nonce, aad, text: []byte) {
	if len(tag) != GCM_TAG_SIZE {
		panic("crypto/aes: invalid GCM tag size")
	}

	// The specification supports nonces in the range [1, 2^64) bits
	// however per NIST SP 800-38D 5.2.1.1:
	//
	// > For IVs, it is recommended that implementations restrict support
	// > to the length of 96 bits, to promote interoperability, efficiency,
	// > and simplicity of design.
	if len(nonce) != GCM_NONCE_SIZE {
		panic("crypto/aes: invalid GCM nonce size")
	}

	if aad_len := u64(len(aad)); aad_len > GCM_A_MAX {
		panic("crypto/aes: oversized GCM aad")
	}
	if text_len := u64(len(text)); text_len > GCM_P_MAX {
		panic("crypto/aes: oversized GCM src data")
	}
}

@(private = "file")
init_ghash_ct64 :: proc(
	ctx: ^Context_GCM,
	h: ^[_aes.GHASH_KEY_SIZE]byte,
	j0: ^[_aes.GHASH_BLOCK_SIZE]byte,
	nonce: []byte,
) {
	impl := &ctx._impl.(ct64.Context)

	// 1. Let H = CIPH(k, 0^128)
	ct64.encrypt_block(impl, h[:], h[:])

	// ECB encrypt j0, so that we can just XOR with the tag.  In theory
	// this could be processed along with the final GCTR block, to
	// potentially save a call to AES-ECB, but... just use AES-NI.
	copy(j0[:], nonce)
	j0[_aes.GHASH_BLOCK_SIZE - 1] = 1
	ct64.encrypt_block(impl, j0[:], j0[:])
}

@(private = "file")
final_ghash_ct64 :: proc(
	s: ^[_aes.GHASH_BLOCK_SIZE]byte,
	h: ^[_aes.GHASH_KEY_SIZE]byte,
	j0: ^[_aes.GHASH_BLOCK_SIZE]byte,
	a_len: int,
	t_len: int,
) {
	blk: [_aes.GHASH_BLOCK_SIZE]byte
	endian.unchecked_put_u64be(blk[0:], u64(a_len) * 8)
	endian.unchecked_put_u64be(blk[8:], u64(t_len) * 8)

	ct64.ghash(s[:], h[:], blk[:])
	for i in 0 ..< len(s) {
		s[i] ~= j0[i]
	}
}

@(private = "file")
gctr_ct64 :: proc(
	ctx: ^Context_GCM,
	dst: []byte,
	s: ^[_aes.GHASH_BLOCK_SIZE]byte,
	src: []byte,
	h: ^[_aes.GHASH_KEY_SIZE]byte,
	nonce: []byte,
	is_seal: bool,
) {
	ct64_inc_ctr32 := #force_inline proc "contextless" (dst: []byte, ctr: u32) -> u32 {
		endian.unchecked_put_u32be(dst[12:], ctr)
		return ctr + 1
	}

	// 2. Define a block J_0 as follows:
	//    if len(IV) = 96, then let J0 = IV || 0^31 || 1
	//
	// Note: We only support 96 bit IVs.
	tmp, tmp2: [ct64.STRIDE][BLOCK_SIZE]byte = ---, ---
	ctrs, blks: [ct64.STRIDE][]byte = ---, ---
	ctr: u32 = 2
	for i in 0 ..< ct64.STRIDE {
		// Setup scratch space for the keystream.
		blks[i] = tmp2[i][:]

		// Pre-copy the IV to all the counter blocks.
		ctrs[i] = tmp[i][:]
		copy(ctrs[i], nonce)
	}

	// We stitch the GCTR and GHASH operations together, so that only
	// one pass over the ciphertext is required.

	impl := &ctx._impl.(ct64.Context)
	src, dst := src, dst

	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks > 0 {
		n := min(ct64.STRIDE, nr_blocks)
		l := n * BLOCK_SIZE

		if !is_seal {
			ct64.ghash(s[:], h[:], src[:l])
		}

		// The keystream is written to a separate buffer, as we will
		// reuse the first 96-bits of each counter.
		for i in 0 ..< n {
			ctr = ct64_inc_ctr32(ctrs[i], ctr)
		}
		ct64.encrypt_blocks(impl, blks[:n], ctrs[:n])

		xor_blocks(dst, src, blks[:n])

		if is_seal {
			ct64.ghash(s[:], h[:], dst[:l])
		}

		src = src[l:]
		dst = dst[l:]
		nr_blocks -= n
	}
	if l := len(src); l > 0 {
		if !is_seal {
			ct64.ghash(s[:], h[:], src[:l])
		}

		ct64_inc_ctr32(ctrs[0], ctr)
		ct64.encrypt_block(impl, ctrs[0], ctrs[0])

		for i in 0 ..< l {
			dst[i] = src[i] ~ ctrs[0][i]
		}

		if is_seal {
			ct64.ghash(s[:], h[:], dst[:l])
		}
	}

	mem.zero_explicit(&tmp, size_of(tmp))
	mem.zero_explicit(&tmp2, size_of(tmp2))
}
