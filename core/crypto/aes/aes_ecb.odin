package aes

import "core:crypto/_aes/ct64"

// Context_ECB is a keyed AES-ECB instance.
//
// WARNING: Using ECB mode is strongly discouraged unless it is being
// used to implement higher level constructs.
Context_ECB :: struct {
	_impl:           Context_Impl,
	_is_initialized: bool,
}

// init_ecb initializes a Context_ECB with the provided key.
init_ecb :: proc(ctx: ^Context_ECB, key: []byte, impl := DEFAULT_IMPLEMENTATION) {
	init_impl(&ctx._impl, key, impl)
	ctx._is_initialized = true
}

// encrypt_ecb encrypts the BLOCK_SIZE buffer src, and writes the result to dst.
encrypt_ecb :: proc(ctx: ^Context_ECB, dst, src: []byte) {
	ensure(ctx._is_initialized)
	ensure(len(dst) == BLOCK_SIZE, "crypto/aes: invalid dst size")
	ensure(len(dst) == BLOCK_SIZE, "crypto/aes: invalid src size")

	switch &impl in ctx._impl {
	case ct64.Context:
		ct64.encrypt_block(&impl, dst, src)
	case Context_Impl_Hardware:
		encrypt_block_hw(&impl, dst, src)
	}
}

// decrypt_ecb decrypts the BLOCK_SIZE buffer src, and writes the result to dst.
decrypt_ecb :: proc(ctx: ^Context_ECB, dst, src: []byte) {
	ensure(ctx._is_initialized)
	ensure(len(dst) == BLOCK_SIZE, "crypto/aes: invalid dst size")
	ensure(len(dst) == BLOCK_SIZE, "crypto/aes: invalid src size")

	switch &impl in ctx._impl {
	case ct64.Context:
		ct64.decrypt_block(&impl, dst, src)
	case Context_Impl_Hardware:
		decrypt_block_hw(&impl, dst, src)
	}
}

// reset_ecb sanitizes the Context_ECB.  The Context_ECB must be
// re-initialized to be used again.
reset_ecb :: proc "contextless" (ctx: ^Context_ECB) {
	reset_impl(&ctx._impl)
	ctx._is_initialized = false
}
