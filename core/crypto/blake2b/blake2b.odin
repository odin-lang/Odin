/*
package blake2b implements the BLAKE2b hash algorithm.

See:
- [[ https://datatracker.ietf.org/doc/html/rfc7693 ]]
- [[ https://www.blake2.net ]]
*/
package blake2b

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

import "../_blake2"

// DIGEST_SIZE is the BLAKE2b digest size in bytes.
DIGEST_SIZE :: 64

// BLOCK_SIZE is the BLAKE2b block size in bytes.
BLOCK_SIZE :: _blake2.BLAKE2B_BLOCK_SIZE

// Context is a BLAKE2b instance.
Context :: _blake2.Blake2b_Context

// init initializes a Context with the default BLAKE2b config.
init :: proc(ctx: ^Context) {
	cfg: _blake2.Blake2_Config
	cfg.size = _blake2.BLAKE2B_SIZE
	_blake2.init(ctx, &cfg)
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	_blake2.update(ctx, data)
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	_blake2.final(ctx, hash, finalize_clone)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	_blake2.clone(ctx, other)
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	_blake2.reset(ctx)
}
