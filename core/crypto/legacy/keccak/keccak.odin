/*
package keccak implements the Keccak hash algorithm family.

During the SHA-3 standardization process, the padding scheme was changed
thus Keccac and SHA-3 produce different outputs.  Most users should use
SHA-3 and/or SHAKE instead, however the legacy algorithm is provided for
backward compatibility purposes.
*/
package keccak

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

import "../../_sha3"

// DIGEST_SIZE_224 is the Keccak-224 digest size.
DIGEST_SIZE_224 :: 28
// DIGEST_SIZE_256 is the Keccak-256 digest size.
DIGEST_SIZE_256 :: 32
// DIGEST_SIZE_384 is the Keccak-384 digest size.
DIGEST_SIZE_384 :: 48
// DIGEST_SIZE_512 is the Keccak-512 digest size.
DIGEST_SIZE_512 :: 64

// BLOCK_SIZE_224 is the Keccak-224 block size in bytes.
BLOCK_SIZE_224 :: _sha3.RATE_224
// BLOCK_SIZE_256 is the Keccak-256 block size in bytes.
BLOCK_SIZE_256 :: _sha3.RATE_256
// BLOCK_SIZE_384 is the Keccak-384 block size in bytes.
BLOCK_SIZE_384 :: _sha3.RATE_384
// BLOCK_SIZE_512 is the Keccak-512 block size in bytes.
BLOCK_SIZE_512 :: _sha3.RATE_512

// Context is a Keccak instance.
Context :: distinct _sha3.Context

// init_224 initializes a Context for Keccak-224.
init_224 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_224
	_init(ctx)
}

// init_256 initializes a Context for Keccak-256.
init_256 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_256
	_init(ctx)
}

// init_384 initializes a Context for Keccak-384.
init_384 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_384
	_init(ctx)
}

// init_512 initializes a Context for Keccak-512.
init_512 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_512
	_init(ctx)
}

@(private)
_init :: proc(ctx: ^Context) {
	ctx.dsbyte = _sha3.DS_KECCAK
	_sha3.init((^_sha3.Context)(ctx))
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	_sha3.update((^_sha3.Context)(ctx), data)
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	_sha3.final((^_sha3.Context)(ctx), hash, finalize_clone)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	_sha3.clone((^_sha3.Context)(ctx), (^_sha3.Context)(other))
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	_sha3.reset((^_sha3.Context)(ctx))
}
