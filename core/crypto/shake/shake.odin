/*
package shake implements the SHAKE XOF algorithm family.

The SHA3 hash algorithm can be found in the crypto/sha3.

See:
- https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.202.pdf
*/
package shake

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

import "../_sha3"

// Context is a SHAKE128 or SHAKE256 instance.
Context :: distinct _sha3.Context

// init_128 initializes a Context for SHAKE128.
init_128 :: proc(ctx: ^Context) {
	ctx.mdlen = 128 / 8
	_init(ctx)
}

// init_256 initializes a Context for SHAKE256.
init_256 :: proc(ctx: ^Context) {
	ctx.mdlen = 256 / 8
	_init(ctx)
}

@(private)
_init :: proc(ctx: ^Context) {
	_sha3.init(transmute(^_sha3.Context)(ctx))
}

// write writes more data into the SHAKE instance.  This MUST not be called
// after any reads have been done, and attempts to do so will panic.
write :: proc(ctx: ^Context, data: []byte) {
	_sha3.update(transmute(^_sha3.Context)(ctx), data)
}

// read reads output from the SHAKE instance.  There is no practical upper
// limit to the amount of data that can be read from SHAKE.  After read has
// been called one or more times, further calls to write will panic.
read :: proc(ctx: ^Context, dst: []byte) {
	ctx_ := transmute(^_sha3.Context)(ctx)
	if !ctx.is_finalized {
		_sha3.shake_xof(ctx_)
	}

	_sha3.shake_out(ctx_, dst)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	_sha3.clone(transmute(^_sha3.Context)(ctx), transmute(^_sha3.Context)(other))
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	_sha3.reset(transmute(^_sha3.Context)(ctx))
}
