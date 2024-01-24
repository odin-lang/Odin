package blake2b

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the vanilla BLAKE2b hashing algorithm.
*/

import "../_blake2"

DIGEST_SIZE :: 64

Context :: _blake2.Blake2b_Context

init :: proc(ctx: ^Context) {
	cfg: _blake2.Blake2_Config
	cfg.size = _blake2.BLAKE2B_SIZE
	_blake2.init(ctx, &cfg)
}

update :: proc(ctx: ^Context, data: []byte) {
	_blake2.update(ctx, data)
}

final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	_blake2.final(ctx, hash, finalize_clone)
}

clone :: proc(ctx, other: ^Context) {
	_blake2.clone(ctx, other)
}

reset :: proc(ctx: ^Context) {
	_blake2.reset(ctx)
}
