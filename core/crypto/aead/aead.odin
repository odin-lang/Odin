package aead

// seal_oneshot encrypts the plaintext and authenticates the aad and ciphertext,
// with the provided algorithm, key, and iv, stores the output in dst and tag.
//
// dst and plaintext MUST alias exactly or not at all.
seal_oneshot :: proc(algo: Algorithm, dst, tag, key, iv, aad, plaintext: []byte, impl: Implementation = nil) {
	ctx: Context
	init(&ctx, algo, key, impl)
	defer reset(&ctx)
	seal_ctx(&ctx, dst, tag, iv, aad, plaintext)
}

// open authenticates the aad and ciphertext, and decrypts the ciphertext,
// with the provided algorithm, key, iv, and tag, and stores the output in dst,
// returning true iff the authentication was successful.  If authentication
// fails, the destination buffer will be zeroed.
//
// dst and ciphertext MUST alias exactly or not at all.
@(require_results)
open_oneshot :: proc(algo: Algorithm, dst, key, iv, aad, ciphertext, tag: []byte, impl: Implementation = nil) -> bool {
	ctx: Context
	init(&ctx, algo, key, impl)
	defer reset(&ctx)
	return open_ctx(&ctx, dst, iv, aad, ciphertext, tag)
}

seal :: proc {
	seal_ctx,
	seal_oneshot,
}

open :: proc {
	open_ctx,
	open_oneshot,
}
