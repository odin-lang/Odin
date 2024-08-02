package aead

import "core:crypto/aes"
import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"
import "core:reflect"

// Implementation is an AEAD implementation.  Most callers will not need
// to use this as the package will automatically select the most performant
// implementation available.
Implementation :: union {
	aes.Implementation,
	chacha20.Implementation,
}

// MAX_TAG_SIZE is the maximum size tag that can be returned by any of the
// Algorithms supported via this package.
MAX_TAG_SIZE :: 16

// Algorithm is the algorithm identifier associated with a given Context.
Algorithm :: enum {
	Invalid,
	AES_GCM_128,
	AES_GCM_192,
	AES_GCM_256,
	CHACHA20POLY1305,
	XCHACHA20POLY1305,
}

// ALGORITM_NAMES is the Agorithm to algorithm name string.
ALGORITHM_NAMES := [Algorithm]string {
	.Invalid           = "Invalid",
	.AES_GCM_128       = "AES-GCM-128",
	.AES_GCM_192       = "AES-GCM-192",
	.AES_GCM_256       = "AES-GCM-256",
	.CHACHA20POLY1305  = "chacha20poly1305",
	.XCHACHA20POLY1305 = "xchacha20poly1305",
}

// TAG_SIZES is the Algorithm to tag size in bytes.
TAG_SIZES := [Algorithm]int {
	.Invalid           = 0,
	.AES_GCM_128       = aes.GCM_TAG_SIZE,
	.AES_GCM_192       = aes.GCM_TAG_SIZE,
	.AES_GCM_256       = aes.GCM_TAG_SIZE,
	.CHACHA20POLY1305  = chacha20poly1305.TAG_SIZE,
	.XCHACHA20POLY1305 = chacha20poly1305.TAG_SIZE,
}

// KEY_SIZES is the Algorithm to key size in bytes.
KEY_SIZES := [Algorithm]int {
	.Invalid           = 0,
	.AES_GCM_128       = aes.KEY_SIZE_128,
	.AES_GCM_192       = aes.KEY_SIZE_192,
	.AES_GCM_256       = aes.KEY_SIZE_256,
	.CHACHA20POLY1305  = chacha20poly1305.KEY_SIZE,
	.XCHACHA20POLY1305 = chacha20poly1305.KEY_SIZE,
}

// IV_SIZES is the Algorithm to initialization vector size in bytes.
//
// Note: Some algorithms (such as AES-GCM) support variable IV sizes.
IV_SIZES := [Algorithm]int {
	.Invalid           = 0,
	.AES_GCM_128       = aes.GCM_IV_SIZE,
	.AES_GCM_192       = aes.GCM_IV_SIZE,
	.AES_GCM_256       = aes.GCM_IV_SIZE,
	.CHACHA20POLY1305  = chacha20poly1305.IV_SIZE,
	.XCHACHA20POLY1305 = chacha20poly1305.XIV_SIZE,
}

// Context is a concrete instantiation of a specific AEAD algorithm.
Context :: struct {
	_algo: Algorithm,
	_impl: union {
		aes.Context_GCM,
		chacha20poly1305.Context,
	},
}

@(private)
_IMPL_IDS := [Algorithm]typeid {
	.Invalid           = nil,
	.AES_GCM_128       = typeid_of(aes.Context_GCM),
	.AES_GCM_192       = typeid_of(aes.Context_GCM),
	.AES_GCM_256       = typeid_of(aes.Context_GCM),
	.CHACHA20POLY1305  = typeid_of(chacha20poly1305.Context),
	.XCHACHA20POLY1305 = typeid_of(chacha20poly1305.Context),
}

// init initializes a Context with a specific AEAD Algorithm.
init :: proc(ctx: ^Context, algorithm: Algorithm, key: []byte, impl: Implementation = nil) {
	if ctx._impl != nil {
		reset(ctx)
	}

	if len(key) != KEY_SIZES[algorithm] {
		panic("crypto/aead: invalid key size")
	}

	// Directly specialize the union by setting the type ID (save a copy).
	reflect.set_union_variant_typeid(
		ctx._impl,
		_IMPL_IDS[algorithm],
	)
	switch algorithm {
	case .AES_GCM_128, .AES_GCM_192, .AES_GCM_256:
		impl_ := impl != nil ? impl.(aes.Implementation) : aes.DEFAULT_IMPLEMENTATION
		aes.init_gcm(&ctx._impl.(aes.Context_GCM), key, impl_)
	case .CHACHA20POLY1305:
		impl_ := impl != nil ? impl.(chacha20.Implementation) : chacha20.DEFAULT_IMPLEMENTATION
		chacha20poly1305.init(&ctx._impl.(chacha20poly1305.Context), key, impl_)
	case .XCHACHA20POLY1305:
		impl_ := impl != nil ? impl.(chacha20.Implementation) : chacha20.DEFAULT_IMPLEMENTATION
		chacha20poly1305.init_xchacha(&ctx._impl.(chacha20poly1305.Context), key, impl_)
	case .Invalid:
		panic("crypto/aead: uninitialized algorithm")
	case:
		panic("crypto/aead: invalid algorithm")
	}

	ctx._algo = algorithm
}

// seal_ctx encrypts the plaintext and authenticates the aad and ciphertext,
// with the provided Context and iv, stores the output in dst and tag.
//
// dst and plaintext MUST alias exactly or not at all.
seal_ctx :: proc(ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) {
	switch &impl in ctx._impl {
	case aes.Context_GCM:
		aes.seal_gcm(&impl, dst, tag, iv, aad, plaintext)
	case chacha20poly1305.Context:
		chacha20poly1305.seal(&impl, dst, tag, iv, aad, plaintext)
	case:
		panic("crypto/aead: uninitialized algorithm")
	}
}

// open_ctx authenticates the aad and ciphertext, and decrypts the ciphertext,
// with the provided Context, iv, and tag, and stores the output in dst,
// returning true iff the authentication was successful.  If authentication
// fails, the destination buffer will be zeroed.
//
// dst and plaintext MUST alias exactly or not at all.
@(require_results)
open_ctx :: proc(ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	switch &impl in ctx._impl {
	case aes.Context_GCM:
		return aes.open_gcm(&impl, dst, iv, aad, ciphertext, tag)
	case chacha20poly1305.Context:
		return chacha20poly1305.open(&impl, dst, iv, aad, ciphertext, tag)
	case:
		panic("crypto/aead: uninitialized algorithm")
	}
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	switch &impl in ctx._impl {
	case aes.Context_GCM:
		aes.reset_gcm(&impl)
	case chacha20poly1305.Context:
		chacha20poly1305.reset(&impl)
	case:
		// Calling reset repeatedly is fine.
	}

	ctx._algo = .Invalid
	ctx._impl = nil
}

// algorithm returns the Algorithm used by a Context instance.
algorithm :: proc(ctx: ^Context) -> Algorithm {
	return ctx._algo
}

// iv_size returns the IV size of a Context instance in bytes.
iv_size :: proc(ctx: ^Context) -> int {
	return IV_SIZES[ctx._algo]
}

// tag_size returns the tag size of a Context instance in bytes.
tag_size :: proc(ctx: ^Context) -> int {
	return TAG_SIZES[ctx._algo]
}
