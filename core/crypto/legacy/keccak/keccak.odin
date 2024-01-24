package keccak

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the Keccak hashing algorithm.  Most users will probably
    want SHA-3 and/or SHAKE instead, however the padding was changed during
    the standardization process by NIST, thus the legacy Keccak algorithm
    is provided.
*/

import "../../_sha3"

DIGEST_SIZE_224 :: 28
DIGEST_SIZE_256 :: 32
DIGEST_SIZE_384 :: 48
DIGEST_SIZE_512 :: 64

Context :: distinct _sha3.Context

init_224 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_224
	_init(ctx)
}

init_256 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_256
	_init(ctx)
}

init_384 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_384
	_init(ctx)
}

init_512 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_512
	_init(ctx)
}

@(private)
_init :: proc(ctx: ^Context) {
	ctx.is_keccak = true
	_sha3.init(transmute(^_sha3.Context)(ctx))
}

update :: proc(ctx: ^Context, data: []byte) {
	_sha3.update(transmute(^_sha3.Context)(ctx), data)
}

final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	_sha3.final(transmute(^_sha3.Context)(ctx), hash, finalize_clone)
}

clone :: proc(ctx, other: ^Context) {
	_sha3.clone(transmute(^_sha3.Context)(ctx), transmute(^_sha3.Context)(other))
}

reset :: proc(ctx: ^Context) {
	_sha3.reset(transmute(^_sha3.Context)(ctx))
}
