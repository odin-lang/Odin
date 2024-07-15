package aes_ct64

import "base:intrinsics"
import "core:mem"

STRIDE :: 4

// Context is a keyed AES (ECB) instance.
Context :: struct {
	_sk_exp:     [120]u64,
	_num_rounds: int,
}

// init initializes a context for AES with the provided key.
init :: proc(ctx: ^Context, key: []byte) {
	skey: [30]u64 = ---

	ctx._num_rounds = keysched(skey[:], key)
	skey_expand(ctx._sk_exp[:], skey[:], ctx._num_rounds)
}

// encrypt_block sets `dst` to `AES-ECB-Encrypt(src)`.
encrypt_block :: proc(ctx: ^Context, dst, src: []byte) {
	q: [8]u64
	load_blockx1(&q, src)
	_encrypt(&q, ctx._sk_exp[:], ctx._num_rounds)
	store_blockx1(dst, &q)
}

// encrypt_block sets `dst` to `AES-ECB-Decrypt(src)`.
decrypt_block :: proc(ctx: ^Context, dst, src: []byte) {
	q: [8]u64
	load_blockx1(&q, src)
	_decrypt(&q, ctx._sk_exp[:], ctx._num_rounds)
	store_blockx1(dst, &q)
}

// encrypt_blocks sets `dst` to `AES-ECB-Encrypt(src[0], .. src[n])`.
encrypt_blocks :: proc(ctx: ^Context, dst, src: [][]byte) {
	q: [8]u64 = ---
	src, dst := src, dst

	n := len(src)
	for n > 4 {
		load_blocks(&q, src[0:4])
		_encrypt(&q, ctx._sk_exp[:], ctx._num_rounds)
		store_blocks(dst[0:4], &q)

		src = src[4:]
		dst = dst[4:]
		n -= 4
	}
	if n > 0 {
		load_blocks(&q, src)
		_encrypt(&q, ctx._sk_exp[:], ctx._num_rounds)
		store_blocks(dst, &q)
	}
}

// decrypt_blocks sets dst to `AES-ECB-Decrypt(src[0], .. src[n])`.
decrypt_blocks :: proc(ctx: ^Context, dst, src: [][]byte) {
	q: [8]u64 = ---
	src, dst := src, dst

	n := len(src)
	for n > 4 {
		load_blocks(&q, src[0:4])
		_decrypt(&q, ctx._sk_exp[:], ctx._num_rounds)
		store_blocks(dst[0:4], &q)

		src = src[4:]
		dst = dst[4:]
		n -= 4
	}
	if n > 0 {
		load_blocks(&q, src)
		_decrypt(&q, ctx._sk_exp[:], ctx._num_rounds)
		store_blocks(dst, &q)
	}
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	mem.zero_explicit(ctx, size_of(ctx))
}
