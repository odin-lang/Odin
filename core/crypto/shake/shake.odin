package shake

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the SHAKE XOF.  The SHA3 hashing algorithm can be found
    in package sha3.

    TODO:
    - This should provide an incremental squeeze interface.
    - DIGEST_SIZE is inaccurate, SHAKE-128 and SHAKE-256 are security
      strengths.
*/

import "../_sha3"

DIGEST_SIZE_128 :: 16
DIGEST_SIZE_256 :: 32

Context :: distinct _sha3.Context

init_128 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_128
	_init(ctx)
}

init_256 :: proc(ctx: ^Context) {
	ctx.mdlen = DIGEST_SIZE_256
	_init(ctx)
}

@(private)
_init :: proc(ctx: ^Context) {
	_sha3.init(transmute(^_sha3.Context)(ctx))
}

update :: proc(ctx: ^Context, data: []byte) {
	_sha3.update(transmute(^_sha3.Context)(ctx), data)
}

final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	// Rolling digest support is handled here instead of in the generic
	// _sha3 package as SHAKE is more of an XOF than a hash, so the
	// standard notion of "final", doesn't really exist when you can
	// squeeze an unlimited amount of data.
	//
	// TODO/yawning: Strongly consider getting rid of this and rigidly
	// defining SHAKE as an XOF.

	ctx := ctx
	if finalize_clone {
		tmp_ctx: Context
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer(reset(ctx))

	ctx_ := transmute(^_sha3.Context)(ctx)
	_sha3.shake_xof(ctx_)
	_sha3.shake_out(ctx_, hash[:])
}

clone :: proc(ctx, other: ^Context) {
	_sha3.clone(transmute(^_sha3.Context)(ctx), transmute(^_sha3.Context)(other))
}

reset :: proc(ctx: ^Context) {
	_sha3.reset(transmute(^_sha3.Context)(ctx))
}
